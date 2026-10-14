-- EnemyAI (ModuleScript, ArenaServer 아래)
-- 적 종류별 행동. 공격은 모두 바닥이나 몸에 미리 경고를 띄운 뒤 들어온다.
--   돌격병  다가와서 벤다
--   궁수    거리를 벌리고, 빨간 선으로 조준한 뒤 화살을 쏜다
--   방패병  느리지만 앞에서 오는 공격을 70% 막는다
--   돌진꾼  길게 빨간 길을 그린 뒤 그 길로 돌진한다
--   자폭병  빠르게 달려와 붙으면 1초 뒤 터진다
--   주술사  멀리서 내 발밑에 불길 원을 띄운다
--   암살자  주기적으로 내 등 뒤로 순간이동해 찌른다
-- 보스는 내려찍기, 돌진, 회전, 운석, 부하 소환 중 정해진 조합을 번갈아 쓴다.

local EnemyAI = {}

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function flatUnit(v: Vector3): Vector3
	local f = flat(v)
	if f.Magnitude < 0.001 then
		return Vector3.new(0, 0, -1)
	end
	return f.Unit
end

local function canAct(e: any, now: number): boolean
	return not e.busy and now >= e.stunUntil and now >= e.frozenUntil
end

local function chase(e: any, target: Vector3, now: number)
	if now >= e.nextMove then
		e.nextMove = now + 0.25
		e.hum:MoveTo(target)
	end
end

local function hold(e: any)
	e.hum:MoveTo(e.root.Position)
end

local function alive(ctx: any, s: any, e: any): boolean
	return s.running and ctx.isCurrent(s) and e.alive
end

-- 근접 공격: 빨갛게 번쩍인 뒤 0.35초 후 벤다
local function strike(ctx: any, player: Player, st: any, s: any, e: any, windup: number?)
	local now = os.clock()
	e.busy = true
	e.nextAttack = now + (e.isBoss and 1.4 or 1.6)
	hold(e)
	ctx.flash(e, Color3.fromRGB(255, 60, 60), windup or 0.35)
	task.delay(windup or 0.35, function()
		e.busy = false
		if not alive(ctx, s, e) then
			return
		end
		local root = ctx.getRoot(player)
		if root and (flat(e.root.Position) - flat(root.Position)).Magnitude <= e.reach + 2 then
			ctx.damagePlayer(player, st, s, e.dmg)
		end
	end)
end

-- 직선으로 날아가는 공격 (화살, 보스 탄). 서버가 경로를 따라 맞았는지 본다
local function projectile(ctx: any, player: Player, st: any, s: any, from: Vector3, dir: Vector3, speed: number, range: number, dmg: number, kind: string, color: Color3)
	ctx.push(player, "proj", { from = from, dir = dir, speed = speed, range = range, kind = kind, color = color })
	task.spawn(function()
		local traveled = 0
		local step = 0.05
		while traveled < range do
			task.wait(step)
			if not (s.running and ctx.isCurrent(s)) then
				return
			end
			traveled += speed * step
			local pos = from + dir * traveled
			local root = ctx.getRoot(player)
			if root and (flat(root.Position) - flat(pos)).Magnitude < 2.6 then
				ctx.damagePlayer(player, st, s, dmg)
				return
			end
		end
	end)
end

-- 돌진: 빨간 길을 그리고 그 길로 몸을 날린다
local function charge(ctx: any, player: Player, st: any, s: any, e: any, root: BasePart, width: number, dmg: number)
	local now = os.clock()
	e.busy = true
	hold(e)
	local start = e.root.Position
	local dir = flatUnit(root.Position - start)
	local length = math.min((flat(root.Position) - flat(start)).Magnitude + 10, 36)
	ctx.warnLane(s, start, dir, length, width, 0.9)
	ctx.flash(e, Color3.fromRGB(255, 150, 0), 0.9)
	task.delay(0.9, function()
		if not alive(ctx, s, e) then
			e.busy = false
			return
		end
		local hit = false
		local steps = 12
		for i = 1, steps do
			if not alive(ctx, s, e) then
				break
			end
			local p = start + dir * length * (i / steps)
			e.model:PivotTo(CFrame.lookAt(p, p + dir))
			local r = ctx.getRoot(player)
			if not hit and r and (flat(r.Position) - flat(p)).Magnitude < width * 0.6 + e.bodyRadius then
				hit = true
				ctx.damagePlayer(player, st, s, dmg)
				ctx.push(player, "knock", { dir = dir, power = 70 })
			end
			task.wait(0.035)
		end
		ctx.push(player, "dust", { pos = e.root.Position })
		e.busy = false
		e.nextAttack = os.clock() + 0.8
	end)
	e.nextSpecial = now + (e.cfg.chargeCd or 6)
end

local function groundCircle(ctx: any, player: Player, st: any, s: any, center: Vector3, radius: number, delay: number, dmg: number, fx: string)
	local floorPos = Vector3.new(center.X, s.arena.center.Y, center.Z)
	ctx.warnDisc(s, floorPos, radius, delay)
	task.delay(delay, function()
		if not (s.running and ctx.isCurrent(s)) then
			return
		end
		ctx.push(player, fx, { pos = floorPos, radius = radius })
		local r = ctx.getRoot(player)
		if r and (flat(r.Position) - flat(floorPos)).Magnitude <= radius then
			ctx.damagePlayer(player, st, s, dmg)
		end
	end)
end

------------------------------------------------------------------------
-- 종류별 행동
------------------------------------------------------------------------
local behaviors: { [string]: (any, Player, any, any, any, BasePart, number, number) -> () } = {}

behaviors.grunt = function(ctx, player, st, s, e, root, dist, now)
	if dist <= e.reach and now >= e.nextAttack then
		strike(ctx, player, st, s, e)
	else
		chase(e, root.Position, now)
	end
end

behaviors.shield = behaviors.grunt

behaviors.archer = function(ctx, player, st, s, e, root, dist, now)
	local keep = e.cfg.keep or 22
	if dist < 11 then
		chase(e, e.root.Position + flatUnit(e.root.Position - root.Position) * 12, now)
	elseif dist > keep + 8 then
		chase(e, root.Position, now)
	elseif now >= e.nextSpecial then
		e.busy = true
		e.nextSpecial = now + (e.cfg.shotCd or 2.8) * (0.8 + math.random() * 0.4)
		hold(e)
		local from = e.root.Position + Vector3.new(0, 0.5, 0)
		local dir = flatUnit(root.Position - from)
		e.model:PivotTo(CFrame.lookAt(e.root.Position, e.root.Position + dir))
		ctx.warnLane(s, from, dir, 46, 1.4, 0.6)
		task.delay(0.6, function()
			e.busy = false
			if alive(ctx, s, e) then
				projectile(ctx, player, st, s, from, dir, 65, 46, e.dmg * 1.2, "arrow", e.accent)
			end
		end)
	else
		hold(e)
	end
end

behaviors.brute = function(ctx, player, st, s, e, root, dist, now)
	if now >= e.nextSpecial and dist > 7 and dist < 34 then
		charge(ctx, player, st, s, e, root, 5, e.dmg * 1.8)
	elseif dist <= e.reach and now >= e.nextAttack then
		strike(ctx, player, st, s, e, 0.5)
	else
		chase(e, root.Position, now)
	end
end

behaviors.bomber = function(ctx, player, st, s, e, root, dist, now)
	if dist > 5 then
		chase(e, root.Position, now)
		return
	end
	-- 붙으면 1초 뒤 폭발
	e.busy = true
	hold(e)
	local radius = 8 * e.scale
	ctx.warnDisc(s, Vector3.new(e.root.Position.X, s.arena.center.Y, e.root.Position.Z), radius, 1.0)
	for i = 0, 3 do
		task.delay(i * 0.25, function()
			if e.alive then
				ctx.flash(e, Color3.new(1, 1, 1), 0.12)
			end
		end)
	end
	task.delay(1.0, function()
		if not alive(ctx, s, e) then
			return
		end
		local pos = e.root.Position
		ctx.push(player, "explode", { pos = pos, radius = radius })
		local r = ctx.getRoot(player)
		if r and (flat(r.Position) - flat(pos)).Magnitude <= radius then
			ctx.damagePlayer(player, st, s, e.dmg)
		end
		ctx.killEnemy(player, s, e, true)
	end)
end

behaviors.shaman = function(ctx, player, st, s, e, root, dist, now)
	local keep = e.cfg.keep or 24
	if dist < 12 then
		chase(e, e.root.Position + flatUnit(e.root.Position - root.Position) * 12, now)
	elseif dist > keep + 10 then
		chase(e, root.Position, now)
	elseif now >= e.nextSpecial then
		e.busy = true
		e.nextSpecial = now + (e.cfg.castCd or 4.5) * (0.85 + math.random() * 0.3)
		hold(e)
		ctx.flash(e, e.accent, 0.6)
		groundCircle(ctx, player, st, s, root.Position, 7, 1.3, e.dmg * 1.3, "flame")
		task.delay(0.6, function()
			e.busy = false
		end)
	else
		hold(e)
	end
end

behaviors.assassin = function(ctx, player, st, s, e, root, dist, now)
	if now >= e.nextSpecial and dist > 6 then
		e.nextSpecial = now + (e.cfg.blinkCd or 5)
		local look = flatUnit(root.CFrame.LookVector)
		local behind = root.Position - look * 4
		local from = e.root.Position
		e.model:PivotTo(CFrame.lookAt(behind, Vector3.new(root.Position.X, behind.Y, root.Position.Z)))
		ctx.push(player, "blink", { from = from, to = behind })
		strike(ctx, player, st, s, e, 0.45)
	elseif dist <= e.reach and now >= e.nextAttack then
		strike(ctx, player, st, s, e, 0.3)
	else
		chase(e, root.Position, now)
	end
end

------------------------------------------------------------------------
-- 보스
------------------------------------------------------------------------
local bossMoves: { [string]: (any, Player, any, any, any, BasePart) -> () } = {}

bossMoves.slam = function(ctx, player, st, s, e, root)
	e.busy = true
	hold(e)
	ctx.flash(e, Color3.fromRGB(255, 140, 0), 1.3)
	groundCircle(ctx, player, st, s, root.Position, 12, 1.3, e.slamDmg, "slam")
	task.delay(1.3, function()
		e.busy = false
		e.nextAttack = os.clock() + 0.8
	end)
end

bossMoves.charge = function(ctx, player, st, s, e, root)
	charge(ctx, player, st, s, e, root, 8, e.slamDmg * 0.8)
end

bossMoves.spin = function(ctx, player, st, s, e, _root)
	e.busy = true
	hold(e)
	local radius = 11 * (e.scale / 1.8)
	ctx.warnDisc(s, Vector3.new(e.root.Position.X, s.arena.center.Y, e.root.Position.Z), radius, 0.8)
	ctx.flash(e, Color3.fromRGB(255, 200, 60), 0.8)
	task.delay(0.8, function()
		for _ = 1, 5 do
			if not alive(ctx, s, e) then
				break
			end
			ctx.push(player, "spin", { pos = e.root.Position, radius = radius })
			local r = ctx.getRoot(player)
			if r and (flat(r.Position) - flat(e.root.Position)).Magnitude <= radius then
				ctx.damagePlayer(player, st, s, e.dmg * 1.2)
			end
			e.model:PivotTo(e.model:GetPivot() * CFrame.Angles(0, math.rad(72), 0))
			task.wait(0.3)
		end
		e.busy = false
	end)
end

bossMoves.meteor = function(ctx, player, st, s, e, root)
	e.busy = true
	hold(e)
	ctx.flash(e, Color3.fromRGB(255, 80, 30), 0.6)
	local spots = { root.Position }
	for _ = 1, 4 do
		local a = math.random() * math.pi * 2
		local d = 5 + math.random() * 10
		table.insert(spots, root.Position + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d))
	end
	for i, p in ipairs(spots) do
		task.delay((i - 1) * 0.12, function()
			if s.running and ctx.isCurrent(s) then
				groundCircle(ctx, player, st, s, p, 6, 1.5, e.slamDmg * 0.6, "meteor")
			end
		end)
	end
	task.delay(0.6, function()
		e.busy = false
	end)
end

bossMoves.summon = function(ctx, player, st, s, e, _root)
	if ctx.aliveCount(s) >= 7 then
		return
	end
	e.busy = true
	hold(e)
	ctx.flash(e, Color3.fromRGB(180, 80, 255), 0.8)
	task.delay(0.8, function()
		e.busy = false
		if not alive(ctx, s, e) then
			return
		end
		for i = 1, 2 do
			local a = math.random() * math.pi * 2
			local pos = e.root.Position + Vector3.new(math.cos(a) * 8, 0, math.sin(a) * 8)
			ctx.push(player, "summon", { pos = Vector3.new(pos.X, s.arena.center.Y, pos.Z) })
			ctx.spawnUnit(s, i == 1 and "grunt" or "bomber", Vector3.new(pos.X, s.arena.center.Y, pos.Z))
		end
		ctx.pushBattle(player)
	end)
end

local function bossTick(ctx: any, player: Player, st: any, s: any, e: any, root: BasePart, dist: number, now: number)
	if now >= e.nextSpecial and dist < 55 then
		local list = e.patterns
		local move = list[e.patternIndex]
		e.patternIndex = (e.patternIndex % #list) + 1
		e.nextSpecial = now + 5
		local fn = bossMoves[move]
		if fn then
			fn(ctx, player, st, s, e, root)
			return
		end
	end
	if dist <= e.reach and now >= e.nextAttack then
		strike(ctx, player, st, s, e, 0.45)
	else
		chase(e, root.Position, now)
	end
end

function EnemyAI.tick(ctx: any, player: Player, st: any, s: any, e: any, root: BasePart, now: number)
	if not canAct(e, now) then
		if now < e.stunUntil or now < e.frozenUntil then
			hold(e)
		end
		return
	end
	local dist = (flat(e.root.Position) - flat(root.Position)).Magnitude
	if e.isBoss then
		bossTick(ctx, player, st, s, e, root, dist, now)
	else
		local fn = behaviors[e.kind] or behaviors.grunt
		fn(ctx, player, st, s, e, root, dist, now)
	end
end

return EnemyAI
