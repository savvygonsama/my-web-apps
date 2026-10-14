-- Skills (ModuleScript, ArenaServer 아래)
-- 무기 계열마다 두 개씩 있는 스킬(E, F). 피해 계산은 서버, 연출은 클라이언트가 한다.
-- 무기 등급 20마다 스킬이 한 단계씩 강해진다 (Lv.1~5). 단계마다 피해 +15%, 그리고
--   대검 투척 1 → 2 → 3자루, 검기 1 → 3 → 5갈래, 표식 1 → 2 → 3명, 잔상 1 → 2 → 3번,
--   파쇄 돌격은 Lv.3부터 끝에서 충격파, 반격은 Lv.5에 사방으로 검기, 맹독은 Lv.5에 독안개,
--   연막은 치명타 1 → 2 → 3회, 사슬은 Lv.3부터 내려찍기, 망자의 원은 단계마다 넓고 길어진다.

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

local function rotateY(v: Vector3, deg: number): Vector3
	return (CFrame.Angles(0, math.rad(deg), 0) * v)
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

-- 단계 반영 피해
local function dmg(s: any, mult: number): number
	return s.stats.atk * mult * (1 + 0.15 * (s.skillTier - 1))
end

local function base(ctx: any, s: any, id: string): { [string]: any }
	return { id = id, color = ctx.color(s), grade = s.stats.weapon.grade, tier = s.skillTier }
end

-- 직선으로 날아가며 꿰뚫는 투사체 (검기)
local function flyingWave(ctx: any, player: Player, s: any, origin: Vector3, look: Vector3, range: number, speed: number, width: number, mult: number)
	local data = base(ctx, s, "wave")
	data.origin = origin
	data.look = look
	data.range = range
	data.speed = speed
	data.width = width
	ctx.push(player, "skill", data)
	task.spawn(function()
		local seen = {}
		local traveled = 0
		local step = 0.04
		while traveled < range do
			task.wait(step)
			if not (s.running and ctx.isCurrent(s)) then
				return
			end
			traveled += speed * step
			local pos = origin + look * traveled
			local hits = {}
			for _, e in ipairs(ctx.alive(s)) do
				if not seen[e] and (flat(e.root.Position) - flat(pos)).Magnitude <= width + e.bodyRadius then
					seen[e] = true
					ctx.hitEnemy(player, s, e, dmg(s, mult), false, pos, hits, { pierce = true })
				end
			end
			ctx.sendHits(player, hits)
		end
	end)
end

local casters: { [string]: (any, Player, any, any, any, BasePart, Vector3, Vector3) -> () } = {}

-- 대검 · 파쇄 돌격
casters.charge = function(ctx, player, _st, s, sk, _root, origin, look)
	local target = clampToArena(ctx, s, origin, origin + look * (sk.length + (s.skillTier - 1) * 2))
	local data = base(ctx, s, "charge")
	data.origin = origin
	data.target = target
	data.look = look
	ctx.push(player, "skill", data)
	local hits = {}
	for _, e in ipairs(ctx.nearSegment(s, origin, target, sk.width)) do
		ctx.hitEnemy(player, s, e, dmg(s, sk.mult), false, origin, hits)
		local side = look:Cross(Vector3.yAxis)
		if side:Dot(flat(e.root.Position - origin)) < 0 then
			side = -side
		end
		knock(e, side, 35)
		stun(ctx, player, e, sk.stun)
	end
	ctx.sendHits(player, hits)
	if s.skillTier >= 3 then
		-- 끝에서 충격파
		task.delay(0.22, function()
			if not (s.running and ctx.isCurrent(s)) then
				return
			end
			local radius = s.skillTier >= 5 and 11 or 7
			local boom = base(ctx, s, "chargeBoom")
			boom.pos = target
			boom.radius = radius
			ctx.push(player, "skill", boom)
			local h2 = {}
			for _, e in ipairs(ctx.alive(s)) do
				if (flat(e.root.Position) - flat(target)).Magnitude <= radius + e.bodyRadius then
					ctx.hitEnemy(player, s, e, dmg(s, sk.mult * 0.8), true, target, h2)
					knock(e, flatUnit(e.root.Position - target), 40)
				end
			end
			ctx.sendHits(player, h2)
		end)
	end
end

-- 대검 · 대검 투척 (갔다가 돌아온다). Lv.3 두 자루, Lv.5 세 자루
casters.boomerang = function(ctx, player, _st, s, sk, _root, origin, look)
	local duration = 1.0
	local angles = { 0 }
	if s.skillTier >= 5 then
		angles = { -20, 0, 20 }
	elseif s.skillTier >= 3 then
		angles = { -14, 14 }
	end
	for _, ang in ipairs(angles) do
		local dir = rotateY(look, ang)
		local data = base(ctx, s, "boomerang")
		data.origin = origin
		data.look = dir
		data.range = sk.range
		data.duration = duration
		ctx.push(player, "skill", data)
		task.spawn(function()
			local hitOut, hitBack = {}, {}
			local steps = 20
			local far = clampToArena(ctx, s, origin, origin + dir * sk.range)
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
						ctx.hitEnemy(player, s, e, dmg(s, sk.mult), false, pos, hits)
					end
				end
				ctx.sendHits(player, hits)
			end
		end)
	end
end

-- 쌍검 · 표식 연격. Lv.3 두 명, Lv.5 세 명
casters.mark = function(ctx, player, _st, s, sk, root, _origin, _look)
	local list = {}
	for _, e in ipairs(ctx.alive(s)) do
		local d = (flat(e.root.Position) - flat(root.Position)).Magnitude
		if d < 28 then
			table.insert(list, { e = e, d = d })
		end
	end
	if #list == 0 then
		ctx.toast(player, "가까이에 표식을 남길 적이 없어요")
		s.skillReadyAt[1] = 0
		return
	end
	table.sort(list, function(a, b)
		return a.d < b.d
	end)
	local count = s.skillTier >= 5 and 3 or (s.skillTier >= 3 and 2 or 1)
	for i = 1, math.min(count, #list) do
		local e = list[i].e
		s.marks[e] = true
		e.markStacks = 0
		e.model:SetAttribute("Mark", 0)
		local data = base(ctx, s, "mark")
		data.model = e.model
		data.stacks = sk.stacks
		ctx.push(player, "skill", data)
	end
end

-- 일반 공격이 맞을 때: 표식 폭발, 독 묻히기
function Skills.onBasicHit(ctx: any, player: Player, s: any, e: any, hits: { any })
	local now = os.clock()
	local skills = Config.Skills[s.stats.weapon.typeId]
	if s.marks[e] and e.alive then
		local sk = skills and skills[1]
		if sk and sk.id == "mark" then
			e.markStacks += 1
			e.model:SetAttribute("Mark", e.markStacks)
			if e.markStacks >= sk.stacks then
				s.marks[e] = nil
				e.model:SetAttribute("Mark", nil)
				local pos = e.root.Position
				local data = base(ctx, s, "markBoom")
				data.pos = pos
				ctx.push(player, "skill", data)
				ctx.hitEnemy(player, s, e, dmg(s, sk.mult), true, pos, hits)
				for _, other in ipairs(ctx.alive(s)) do
					if other ~= e and (flat(other.root.Position) - flat(pos)).Magnitude <= 8 + s.skillTier then
						ctx.hitEnemy(player, s, other, dmg(s, sk.splash), false, pos, hits)
					end
				end
			end
		end
	end
	if now < s.poisonUntil and e.alive then
		local sk = skills and skills[1]
		if sk and sk.id == "poison" then
			e.poisonUntil = now + sk.dotTime
			e.poisonDmg = dmg(s, sk.dotMult * (1 + 0.25 * (s.skillTier - 1)))
			e.model:SetAttribute("Poison", true)
		end
	end
end

-- 쌍검 · 잔상 돌파. Lv.3 잔상 두 번, Lv.5 세 번
casters.phantom = function(ctx, player, _st, s, sk, _root, origin, look)
	local target = clampToArena(ctx, s, origin, origin + look * sk.length)
	local data = base(ctx, s, "phantom")
	data.origin = origin
	data.target = target
	data.look = look
	ctx.push(player, "skill", data)
	local hits = {}
	for _, e in ipairs(ctx.nearSegment(s, origin, target, sk.width)) do
		ctx.hitEnemy(player, s, e, dmg(s, sk.mult), false, origin, hits)
	end
	ctx.sendHits(player, hits)
	local echoes = s.skillTier >= 5 and 3 or (s.skillTier >= 3 and 2 or 1)
	for k = 1, echoes do
		task.delay(0.45 * k, function()
			if not (s.running and ctx.isCurrent(s)) then
				return
			end
			local echo = base(ctx, s, "phantomEcho")
			echo.origin = origin
			echo.target = target
			echo.index = k
			ctx.push(player, "skill", echo)
			local h = {}
			for _, e in ipairs(ctx.nearSegment(s, origin, target, sk.width)) do
				ctx.hitEnemy(player, s, e, dmg(s, sk.mult), true, origin, h)
			end
			ctx.sendHits(player, h)
		end)
	end
end

-- 장검 · 검기 발사. Lv.3 세 갈래, Lv.5 다섯 갈래
casters.wave = function(ctx, player, _st, s, sk, _root, origin, look)
	local angles = { 0 }
	if s.skillTier >= 5 then
		angles = { -24, -12, 0, 12, 24 }
	elseif s.skillTier >= 3 then
		angles = { -15, 0, 15 }
	end
	for _, ang in ipairs(angles) do
		flyingWave(ctx, player, s, origin, rotateY(look, ang), sk.range, sk.speed, sk.width, sk.mult)
	end
end

-- 장검 · 반격 자세 (막는 건 damagePlayer에서 처리)
casters.parry = function(ctx, player, _st, s, sk, _root, _origin, _look)
	s.parryUntil = os.clock() + sk.window
	local data = base(ctx, s, "parry")
	data.window = sk.window
	ctx.push(player, "skill", data)
end

-- 막기에 성공했을 때 반격. 단계마다 넓어지고, Lv.5는 사방으로 검기
function Skills.tryParry(ctx: any, player: Player, s: any): boolean
	if os.clock() >= s.parryUntil then
		return false
	end
	s.parryUntil = 0
	local sk = Config.Skills[3][2]
	local root = ctx.getRoot(player)
	local pos = root and root.Position or s.arena.center
	local radius = sk.radius + (s.skillTier - 1) * 2
	s.invulnUntil = math.max(s.invulnUntil, os.clock() + 0.6)
	local data = base(ctx, s, "parryCounter")
	data.pos = pos
	data.radius = radius
	ctx.push(player, "skill", data)
	local hits = {}
	for _, e in ipairs(ctx.alive(s)) do
		if (flat(e.root.Position) - flat(pos)).Magnitude <= radius + e.bodyRadius then
			ctx.hitEnemy(player, s, e, dmg(s, sk.mult), true, pos, hits, { pierce = true })
			stun(ctx, player, e, 1 + 0.25 * s.skillTier)
		end
	end
	ctx.sendHits(player, hits)
	if s.skillTier >= 5 then
		for i = 0, 7 do
			flyingWave(ctx, player, s, pos, rotateY(Vector3.new(0, 0, -1), i * 45), 30, 60, 4, 2)
		end
	end
	return true
end

-- 단계 반영 지속 피해 장판 (독안개, 망자의 원)
local function addZone(ctx: any, player: Player, s: any, pos: Vector3, radius: number, duration: number, mult: number, heal: number, kind: string)
	local floorPos = Vector3.new(pos.X, s.arena.center.Y, pos.Z)
	table.insert(s.zones, { pos = floorPos, radius = radius, untilT = os.clock() + duration, nextTick = 0, mult = mult, heal = heal })
	local data = base(ctx, s, kind)
	data.pos = floorPos
	data.radius = radius
	data.duration = duration
	ctx.push(player, "skill", data)
end

-- 단검 · 맹독 칼날. Lv.3 지속 +3초, Lv.5 가까운 적 자리에 독안개
casters.poison = function(ctx, player, _st, s, sk, root, _origin, _look)
	local duration = sk.duration + (s.skillTier >= 3 and 3 or 0)
	s.poisonUntil = os.clock() + duration
	local data = base(ctx, s, "poison")
	data.duration = duration
	ctx.push(player, "skill", data)
	if s.skillTier >= 5 then
		local best, bestD = nil, 30
		for _, e in ipairs(ctx.alive(s)) do
			local d = (flat(e.root.Position) - flat(root.Position)).Magnitude
			if d < bestD then
				best, bestD = e, d
			end
		end
		if best then
			addZone(ctx, player, s, best.root.Position, 9, 4, sk.dotMult * 2, 0, "poisonCloud")
		end
	end
end

-- 단검 · 연막 순보. 치명타 횟수 Lv.1 1회, Lv.3 2회, Lv.5 3회
casters.smoke = function(ctx, player, _st, s, sk, root, _origin, _look)
	s.invulnUntil = math.max(s.invulnUntil, os.clock() + sk.invuln)
	s.smokeCrit = sk.mult
	s.smokeCharges = s.skillTier >= 5 and 3 or (s.skillTier >= 3 and 2 or 1)
	local data = base(ctx, s, "smoke")
	data.pos = root.Position
	data.duration = sk.invuln
	ctx.push(player, "skill", data)
end

-- 낫 · 사슬 낚아채기. 단계마다 멀리, Lv.3부터 끌어온 뒤 내려찍기, Lv.5는 보스도 끌어온다
casters.hook = function(ctx, player, _st, s, sk, _root, origin, look)
	local victims = {}
	local pulled = {}
	local hits = {}
	local idx = 0
	local range = sk.range + (s.skillTier - 1) * 4
	for _, e in ipairs(ctx.alive(s)) do
		local off = flat(e.root.Position - origin)
		if off.Magnitude <= range and off.Magnitude > 0.1 and off.Unit:Dot(look) >= sk.cone then
			idx += 1
			table.insert(victims, e.root.Position)
			if not e.isBoss or s.skillTier >= 5 then
				local side = look:Cross(Vector3.yAxis) * ((idx % 2 == 0) and 1 or -1) * (idx // 2) * 2
				local dest = origin + look * 4 + side
				e.model:PivotTo(CFrame.lookAt(Vector3.new(dest.X, e.root.Position.Y, dest.Z), Vector3.new(origin.X, e.root.Position.Y, origin.Z)))
			end
			ctx.hitEnemy(player, s, e, dmg(s, sk.mult), false, origin, hits)
			stun(ctx, player, e, sk.stun)
			table.insert(pulled, e)
		end
	end
	local data = base(ctx, s, "hook")
	data.origin = origin
	data.victims = victims
	ctx.push(player, "skill", data)
	ctx.sendHits(player, hits)
	if s.skillTier >= 3 and #pulled > 0 then
		task.delay(0.35, function()
			if not (s.running and ctx.isCurrent(s)) then
				return
			end
			local slamPos = origin + look * 4
			local slam = base(ctx, s, "hookSlam")
			slam.pos = slamPos
			ctx.push(player, "skill", slam)
			local h = {}
			for _, e in ipairs(pulled) do
				ctx.hitEnemy(player, s, e, dmg(s, sk.mult * 1.5), true, origin, h)
			end
			ctx.sendHits(player, h)
		end)
	end
end

-- 낫 · 망자의 원. 단계마다 넓고 길어진다
casters.zone = function(ctx, player, _st, s, sk, _root, origin, _look)
	addZone(ctx, player, s, origin, sk.radius + (s.skillTier - 1) * 1.5, sk.duration + (s.skillTier - 1) * 0.5, sk.tickMult, sk.heal, "zone")
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
					ctx.hitEnemy(player, s, e, dmg(s, z.mult), false, z.pos, hits)
				end
			end
			if z.heal > 0 then
				ctx.heal(s, s.maxHp * z.heal)
			end
			ctx.sendHits(player, hits)
			ctx.pushBattle(player)
		end
	end
end

-- 올라운더 · 만검 강림 (Lv.5: 검 20자루)
casters.rain = function(ctx, player, _st, s, sk, _root, _origin, _look)
	local list = ctx.alive(s)
	if #list == 0 then
		s.skillReadyAt[1] = 0
		return
	end
	local count = sk.count + (s.skillTier >= 5 and 8 or 0)
	local targets = {}
	for i = 1, count do
		table.insert(targets, list[((i - 1) % #list) + 1])
	end
	local positions = {}
	for _, e in ipairs(targets) do
		table.insert(positions, e.root.Position + Vector3.new((math.random() - 0.5) * 2, 0, (math.random() - 0.5) * 2))
	end
	local data = base(ctx, s, "rain")
	data.positions = positions
	ctx.push(player, "skill", data)
	for i, e in ipairs(targets) do
		task.delay(0.35 + (i - 1) * 0.07, function()
			if s.running and ctx.isCurrent(s) and e.alive then
				local hits = {}
				ctx.hitEnemy(player, s, e, dmg(s, sk.mult), true, positions[i], hits, { pierce = true })
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
	local data = base(ctx, s, "timestop")
	data.duration = sk.duration
	data.models = models
	ctx.push(player, "skill", data)
end

-- slot: 1(E) 또는 2(F)
function Skills.cast(ctx: any, player: Player, st: any, s: any, slot: number): boolean
	if not s.running or s.ulting then
		return false
	end
	local typeId = s.stats.weapon.typeId
	local list = Config.Skills[typeId]
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
	s.skillTier = Config.skillTier(s.stats.weapon.grade, typeId)
	local cd = st.noCooldown and 0.3 or sk.cd
	s.skillReadyAt[slot] = now + cd
	local origin = root.Position
	local look = flatUnit(root.CFrame.LookVector)
	local ok, err = pcall(fn, ctx, player, st, s, sk, root, origin, look)
	if not ok then
		warn("[Arena] 스킬 오류:", sk.id, err)
	end
	-- 대상이 없어 대기 시간을 되돌린 경우는 알리지 않는다
	if s.skillReadyAt[slot] > now then
		ctx.push(player, "cooldown", { slot = slot, duration = cd, tier = s.skillTier })
		return true
	end
	return false
end

return Skills
