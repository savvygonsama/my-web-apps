-- Skills (ModuleScript, ArenaServer 아래)
-- 무기 계열마다 두 개씩 있는 스킬(E, F). 피해 계산은 서버, 연출은 클라이언트가 한다.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Skills = {}

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

-- 투기장 밖으로 나가지 않게 끝점을 줄인다
local function clampToArena(ctx: any, s: any, origin: Vector3, target: Vector3): Vector3
	local center = s.arena.center
	local fromCenter = flat(target - center)
	local limit = ctx.arenaRadius - 6
	if fromCenter.Magnitude > limit then
		return center + fromCenter.Unit * limit + Vector3.new(0, origin.Y - center.Y, 0)
	end
	return target
end

local function stun(ctx: any, player: Player, e: any, duration: number)
	if e.isBoss then
		duration *= 0.4
	end
	e.stunUntil = math.max(e.stunUntil, os.clock() + duration)
	ctx.push(player, "stun", { model = e.model, duration = duration })
end

local function knock(e: any, dir: Vector3, power: number)
	if e.isBoss or not e.alive then
		return
	end
	e.root.AssemblyLinearVelocity = dir * power + Vector3.new(0, power * 0.5, 0)
end

local casters: { [string]: (any, Player, any, any, any, BasePart, Vector3, Vector3) -> () } = {}

-- 대검 · 파쇄 돌격
casters.charge = function(ctx, player, _st, s, sk, _root, origin, look)
	local target = clampToArena(ctx, s, origin, origin + look * sk.length)
	ctx.push(player, "skill", { id = "charge", origin = origin, target = target, look = look, color = ctx.color(s) })
	local hits = {}
	for _, e in ipairs(ctx.nearSegment(s, origin, target, sk.width)) do
		ctx.hitEnemy(player, s, e, s.stats.atk * sk.mult, false, origin, hits)
		local side = look:Cross(Vector3.yAxis)
		if side:Dot(flat(e.root.Position - origin)) < 0 then
			side = -side
		end
		knock(e, side, 35)
		stun(ctx, player, e, sk.stun)
	end
	ctx.sendHits(player, hits)
end

-- 대검 · 대검 투척 (갔다가 돌아온다)
casters.boomerang = function(ctx, player, _st, s, sk, _root, origin, look)
	local duration = 1.0
	ctx.push(player, "skill", { id = "boomerang", origin = origin, look = look, range = sk.range, duration = duration, color = ctx.color(s), grade = s.stats.weapon.grade })
	task.spawn(function()
		local hitOut, hitBack = {}, {}
		local steps = 20
		local far = clampToArena(ctx, s, origin, origin + look * sk.range)
		for i = 1, steps do
			task.wait(duration / steps)
			if not (s.running and ctx.isCurrent(s)) then
				return
			end
			local t = i / steps
			local pos
			local seen
			if t <= 0.5 then
				pos = origin:Lerp(far, t / 0.5)
				seen = hitOut
			else
				local r = ctx.getRoot(player)
				local home = r and r.Position or origin
				pos = far:Lerp(home, (t - 0.5) / 0.5)
				seen = hitBack
			end
			local hits = {}
			for _, e in ipairs(ctx.alive(s)) do
				if not seen[e] and (flat(e.root.Position) - flat(pos)).Magnitude <= sk.width + e.bodyRadius then
					seen[e] = true
					ctx.hitEnemy(player, s, e, s.stats.atk * sk.mult, false, pos, hits)
				end
			end
			ctx.sendHits(player, hits)
		end
	end)
end

-- 쌍검 · 표식 연격
casters.mark = function(ctx, player, _st, s, sk, root, _origin, _look)
	local best, bestDist = nil, 26
	for _, e in ipairs(ctx.alive(s)) do
		local d = (flat(e.root.Position) - flat(root.Position)).Magnitude
		if d < bestDist then
			best, bestDist = e, d
		end
	end
	if not best then
		ctx.toast(player, "가까이에 표식을 남길 적이 없어요")
		s.skillReadyAt[1] = 0
		return
	end
	if s.markTarget and s.markTarget.model then
		s.markTarget.model:SetAttribute("Mark", nil)
	end
	s.markTarget = best
	best.markStacks = 0
	best.model:SetAttribute("Mark", 0)
	ctx.push(player, "skill", { id = "mark", model = best.model, stacks = sk.stacks, color = ctx.color(s) })
end

-- 표식이 다 차면 폭발 (일반 공격에서 부른다)
function Skills.onBasicHit(ctx: any, player: Player, s: any, e: any, hits: { any })
	local now = os.clock()
	local skills = Config.Skills[s.stats.weapon.typeId]
	if s.markTarget == e and e.alive then
		local sk = skills and skills[1]
		if sk and sk.id == "mark" then
			e.markStacks += 1
			e.model:SetAttribute("Mark", e.markStacks)
			if e.markStacks >= sk.stacks then
				s.markTarget = nil
				e.model:SetAttribute("Mark", nil)
				local pos = e.root.Position
				ctx.push(player, "skill", { id = "markBoom", pos = pos, color = ctx.color(s) })
				ctx.hitEnemy(player, s, e, s.stats.atk * sk.mult, true, pos, hits)
				for _, other in ipairs(ctx.alive(s)) do
					if other ~= e and (flat(other.root.Position) - flat(pos)).Magnitude <= 8 then
						ctx.hitEnemy(player, s, other, s.stats.atk * sk.splash, false, pos, hits)
					end
				end
			end
		end
	end
	if now < s.poisonUntil and e.alive then
		local sk = skills and skills[1]
		if sk and sk.id == "poison" then
			e.poisonUntil = now + sk.dotTime
			e.poisonDmg = s.stats.atk * sk.dotMult
			e.model:SetAttribute("Poison", true)
		end
	end
end

-- 쌍검 · 잔상 돌파
casters.phantom = function(ctx, player, _st, s, sk, _root, origin, look)
	local target = clampToArena(ctx, s, origin, origin + look * sk.length)
	ctx.push(player, "skill", { id = "phantom", origin = origin, target = target, look = look, color = ctx.color(s) })
	local hits = {}
	for _, e in ipairs(ctx.nearSegment(s, origin, target, sk.width)) do
		ctx.hitEnemy(player, s, e, s.stats.atk * sk.mult, false, origin, hits)
	end
	ctx.sendHits(player, hits)
	task.delay(0.5, function()
		if not (s.running and ctx.isCurrent(s)) then
			return
		end
		ctx.push(player, "skill", { id = "phantomEcho", origin = origin, target = target, color = ctx.color(s) })
		local echo = {}
		for _, e in ipairs(ctx.nearSegment(s, origin, target, sk.width)) do
			ctx.hitEnemy(player, s, e, s.stats.atk * sk.mult, true, origin, echo)
		end
		ctx.sendHits(player, echo)
	end)
end

-- 장검 · 검기 발사
casters.wave = function(ctx, player, _st, s, sk, _root, origin, look)
	ctx.push(player, "skill", { id = "wave", origin = origin, look = look, range = sk.range, speed = sk.speed, width = sk.width, color = ctx.color(s) })
	task.spawn(function()
		local seen = {}
		local traveled = 0
		local step = 0.04
		while traveled < sk.range do
			task.wait(step)
			if not (s.running and ctx.isCurrent(s)) then
				return
			end
			traveled += sk.speed * step
			local pos = origin + look * traveled
			local hits = {}
			for _, e in ipairs(ctx.alive(s)) do
				if not seen[e] and (flat(e.root.Position) - flat(pos)).Magnitude <= sk.width + e.bodyRadius then
					seen[e] = true
					ctx.hitEnemy(player, s, e, s.stats.atk * sk.mult, false, pos, hits, { pierce = true })
				end
			end
			ctx.sendHits(player, hits)
		end
	end)
end

-- 장검 · 반격 자세 (막는 건 damagePlayer에서 처리)
casters.parry = function(ctx, player, _st, s, sk, _root, _origin, _look)
	s.parryUntil = os.clock() + sk.window
	ctx.push(player, "skill", { id = "parry", window = sk.window, color = ctx.color(s) })
end

-- 막기에 성공했을 때 반격
function Skills.tryParry(ctx: any, player: Player, s: any): boolean
	if os.clock() >= s.parryUntil then
		return false
	end
	s.parryUntil = 0
	local sk = Config.Skills[3][2]
	local root = ctx.getRoot(player)
	local pos = root and root.Position or s.arena.center
	s.invulnUntil = math.max(s.invulnUntil, os.clock() + 0.6)
	ctx.push(player, "skill", { id = "parryCounter", pos = pos, radius = sk.radius, color = ctx.color(s) })
	local hits = {}
	for _, e in ipairs(ctx.alive(s)) do
		if (flat(e.root.Position) - flat(pos)).Magnitude <= sk.radius + e.bodyRadius then
			ctx.hitEnemy(player, s, e, s.stats.atk * sk.mult, true, pos, hits, { pierce = true })
			stun(ctx, player, e, 1)
		end
	end
	ctx.sendHits(player, hits)
	return true
end

-- 단검 · 맹독 칼날
casters.poison = function(ctx, player, _st, s, sk, _root, _origin, _look)
	s.poisonUntil = os.clock() + sk.duration
	ctx.push(player, "skill", { id = "poison", duration = sk.duration })
end

-- 단검 · 연막 순보
casters.smoke = function(ctx, player, _st, s, sk, root, _origin, _look)
	s.invulnUntil = math.max(s.invulnUntil, os.clock() + sk.invuln)
	s.smokeCrit = sk.mult
	ctx.push(player, "skill", { id = "smoke", pos = root.Position, duration = sk.invuln })
end

-- 낫 · 사슬 낚아채기
casters.hook = function(ctx, player, _st, s, sk, _root, origin, look)
	local victims = {}
	local hits = {}
	local idx = 0
	for _, e in ipairs(ctx.alive(s)) do
		local off = flat(e.root.Position - origin)
		if off.Magnitude <= sk.range and off.Magnitude > 0.1 and off.Unit:Dot(look) >= sk.cone then
			idx += 1
			table.insert(victims, e.root.Position)
			if not e.isBoss then
				local side = look:Cross(Vector3.yAxis) * ((idx % 2 == 0) and 1 or -1) * (idx // 2) * 2
				local dest = origin + look * 4 + side
				e.model:PivotTo(CFrame.lookAt(Vector3.new(dest.X, e.root.Position.Y, dest.Z), Vector3.new(origin.X, e.root.Position.Y, origin.Z)))
			end
			ctx.hitEnemy(player, s, e, s.stats.atk * sk.mult, false, origin, hits)
			stun(ctx, player, e, sk.stun)
		end
	end
	ctx.push(player, "skill", { id = "hook", origin = origin, victims = victims, color = ctx.color(s) })
	ctx.sendHits(player, hits)
end

-- 낫 · 망자의 원 (틱은 battleLoop에서)
casters.zone = function(ctx, player, _st, s, sk, _root, origin, _look)
	local pos = Vector3.new(origin.X, s.arena.center.Y, origin.Z)
	table.insert(s.zones, { pos = pos, radius = sk.radius, untilT = os.clock() + sk.duration, nextTick = 0, mult = sk.tickMult, heal = sk.heal })
	ctx.push(player, "skill", { id = "zone", pos = pos, radius = sk.radius, duration = sk.duration })
end

function Skills.tickZones(ctx: any, player: Player, s: any, now: number)
	for i = #s.zones, 1, -1 do
		local z = s.zones[i]
		if now >= z.untilT then
			table.remove(s.zones, i)
		elseif now >= z.nextTick then
			z.nextTick = now + 0.5
			local hits = {}
			for _, e in ipairs(ctx.alive(s)) do
				if (flat(e.root.Position) - flat(z.pos)).Magnitude <= z.radius + e.bodyRadius then
					ctx.hitEnemy(player, s, e, s.stats.atk * z.mult, false, z.pos, hits)
				end
			end
			ctx.heal(s, s.maxHp * z.heal)
			ctx.sendHits(player, hits)
			ctx.pushBattle(player)
		end
	end
end

-- 올라운더 · 만검 강림
casters.rain = function(ctx, player, _st, s, sk, _root, _origin, _look)
	local list = ctx.alive(s)
	if #list == 0 then
		s.skillReadyAt[1] = 0
		return
	end
	local targets = {}
	for i = 1, sk.count do
		table.insert(targets, list[((i - 1) % #list) + 1])
	end
	local positions = {}
	for _, e in ipairs(targets) do
		table.insert(positions, e.root.Position + Vector3.new((math.random() - 0.5) * 2, 0, (math.random() - 0.5) * 2))
	end
	ctx.push(player, "skill", { id = "rain", positions = positions })
	for i, e in ipairs(targets) do
		task.delay(0.35 + (i - 1) * 0.07, function()
			if s.running and ctx.isCurrent(s) and e.alive then
				local hits = {}
				ctx.hitEnemy(player, s, e, s.stats.atk * sk.mult, true, positions[i], hits, { pierce = true })
				ctx.sendHits(player, hits)
			end
		end)
	end
end

-- 올라운더 · 시공 정지
casters.timestop = function(ctx, player, _st, s, sk, _root, _origin, _look)
	local untilT = os.clock() + sk.duration
	local models = {}
	for _, e in ipairs(ctx.alive(s)) do
		e.frozenUntil = untilT
		table.insert(models, e.model)
	end
	ctx.push(player, "skill", { id = "timestop", duration = sk.duration, models = models })
end

-- slot: 1(E) 또는 2(F)
function Skills.cast(ctx: any, player: Player, st: any, s: any, slot: number): boolean
	if not s.running or s.ulting then
		return false
	end
	local list = Config.Skills[s.stats.weapon.typeId]
	local sk = list and list[slot]
	if not sk then
		return false
	end
	local now = os.clock()
	if now < s.skillReadyAt[slot] then
		return false
	end
	local root = ctx.getRoot(player)
	if not root then
		return false
	end
	local fn = casters[sk.id]
	if not fn then
		return false
	end
	s.skillReadyAt[slot] = now + sk.cd
	local origin = root.Position
	local look = flatUnit(root.CFrame.LookVector)
	local ok, err = pcall(fn, ctx, player, st, s, sk, root, origin, look)
	if not ok then
		warn("[Arena] 스킬 오류:", sk.id, err)
	end
	-- 실패해서 대기 시간을 되돌린 경우(대상 없음)는 알리지 않는다
	if s.skillReadyAt[slot] > now then
		ctx.push(player, "cooldown", { slot = slot, duration = sk.cd })
		return true
	end
	return false
end

return Skills
