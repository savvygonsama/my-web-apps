-- 권왕: 싸움 판정 (서버). 사람과 적을 똑같이 '무인'으로 다룬다
-- 사람의 맞힘은 화면이 먼저 알려 주고(바로 반응하게), 서버가 거리·시간을 확인해 정한다
-- 적의 맞힘은 서버가 직접 정한다
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Combat = {}

export type Act = {
	move: any,
	slot: any,
	seq: number,
	start: number,
	dur: number,
	speed: number,
	done: { [string]: boolean }, -- "맞힘번호:대상" 한 번씩만
	swung: { [number]: boolean },
	charge: number,
	bloom: boolean,
	enemy: boolean,
}

export type Fighter = {
	model: Model,
	root: BasePart,
	hum: Humanoid,
	player: Player?,
	npc: any?, -- 적이면 적 정보
	name: string,
	hp: number,
	maxHp: number,
	posture: number,
	postureMax: number,
	chi: number,
	style: string,
	act: Act?,
	stunUntil: number,
	brokenUntil: number,
	iframeUntil: number,
	guarding: boolean,
	guardStart: number,
	counterUntil: number,
	buffs: { [string]: number },
	lastHurtAt: number,
	lastSwingAt: number,
	cds: { [string]: number },
	stacks: { flow: number, petal: number, petalAt: number, charge: number },
	dead: boolean,
	combatUntil: number,
	dmgMult: number,
	skillMult: number,
	walk: number,
	lastAttacker: Fighter?,
	dashAt: number,
	dashUsed: number,
}

Combat.fighters = {} :: { [Model]: Fighter }
Combat.projectiles = {} :: { any }
local Push: RemoteEvent
local hooks: { [string]: any } = {}

function Combat.init(push: RemoteEvent, h: { [string]: any })
	Push = push
	hooks = h
end

local function now(): number
	return os.clock()
end

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	if f.Magnitude < 1e-4 then
		return Vector3.new(0, 0, -1)
	end
	return f.Unit
end

function Combat.look(f: Fighter): Vector3
	return flat(f.root.CFrame.LookVector)
end

function Combat.styleOf(f: Fighter): any
	return Config.STYLE_BY_ID[f.style]
end

-- 비무대 위인지
function Combat.onRing(pos: Vector3): boolean
	local R = Config.RING
	return math.abs(pos.X - R.center.X) <= R.size / 2 and math.abs(pos.Z - R.center.Z) <= R.size / 2 and pos.Y > R.height - 1
end

-- 서로 때릴 수 있는 사이인지
function Combat.hostile(a: Fighter, b: Fighter): boolean
	if a == b or a.dead or b.dead then
		return false
	end
	if a.player and b.player then
		return Combat.onRing(a.root.Position) and Combat.onRing(b.root.Position)
	end
	if not a.player and not b.player then
		return false
	end
	return true
end

function Combat.register(model: Model, info: any): Fighter
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local f: Fighter = {
		model = model,
		root = root,
		hum = hum,
		player = info.player,
		npc = info.npc,
		name = info.name or model.Name,
		hp = info.hp,
		maxHp = info.hp,
		posture = 0,
		postureMax = info.postureMax or Config.POSTURE_MAX,
		chi = 0,
		style = info.style or "",
		act = nil,
		stunUntil = 0,
		brokenUntil = 0,
		iframeUntil = 0,
		guarding = false,
		guardStart = 0,
		counterUntil = 0,
		buffs = {},
		lastHurtAt = 0,
		lastSwingAt = -10,
		cds = {},
		stacks = { flow = 0, petal = 0, petalAt = 0, charge = 0 },
		dead = false,
		combatUntil = 0,
		dmgMult = info.dmgMult or 1,
		skillMult = info.skillMult or 1,
		walk = info.walk or Config.WALK_SPEED,
		lastAttacker = nil,
		dashAt = 0,
		dashUsed = 0,
	}
	Combat.fighters[model] = f
	Combat.sync(f)
	return f
end

function Combat.unregister(model: Model)
	Combat.fighters[model] = nil
end

-- 화면이 읽는 값 (모델 속성)
function Combat.sync(f: Fighter)
	local m = f.model
	m:SetAttribute("Hp", math.max(0, math.floor(f.hp + 0.5)))
	m:SetAttribute("MaxHp", f.maxHp)
	m:SetAttribute("Posture", math.floor(f.posture + 0.5))
	m:SetAttribute("PostureMax", f.postureMax)
	m:SetAttribute("Chi", math.floor(f.chi))
	m:SetAttribute("Style", f.style)
	m:SetAttribute("Guard", f.guarding)
	m:SetAttribute("Flow", f.stacks.flow)
	m:SetAttribute("Petal", f.stacks.petal)
	m:SetAttribute("Charge", f.stacks.charge)
	m:SetAttribute("Dead", f.dead)
end

function Combat.stunned(f: Fighter): boolean
	return now() < f.stunUntil or f.dead
end

-- 지금 무엇에도 밀리지 않는지 (기술의 armor, 철포삼, 금강체)
local function armored(f: Fighter): boolean
	local t = now()
	if (f.buffs.ironshirt or 0) > t then
		return true
	end
	local act = f.act
	if act and t < act.start + act.dur then
		if act.move.armor then
			return true
		end
		local style = Combat.styleOf(f)
		if style and style.armorWhileAttacking and not act.enemy then
			return true
		end
	end
	return false
end

-- 받는 피해 배율
local function defense(f: Fighter): number
	local t = now()
	local m = 1
	if (f.buffs.ironshirt or 0) > t then
		m *= 0.5
	end
	local style = Combat.styleOf(f)
	local act = f.act
	if style and style.armorWhileAttacking and act and t < act.start + act.dur then
		m *= style.armorWhileAttacking
	end
	return m
end

local function interrupt(f: Fighter)
	if f.act then
		f.act = nil
		Push:FireAllClients("interrupt", f.model)
	end
end

local function knock(f: Fighter, vel: Vector3, stun: number)
	if f.player then
		Push:FireClient(f.player, "knock", vel, stun)
	elseif f.root and f.root.Parent and not f.root.Anchored then
		f.root.AssemblyLinearVelocity = vel
	end
end

function Combat.stun(f: Fighter, dur: number)
	f.stunUntil = math.max(f.stunUntil, now() + dur)
	interrupt(f)
	f.guarding = false
end

local function addChi(f: Fighter, amount: number)
	if f.player then
		f.chi = math.clamp(f.chi + amount, 0, Config.CHI_MAX)
	end
end

local function addPosture(f: Fighter, amount: number): boolean
	f.posture += amount
	f.lastHurtAt = now()
	if f.posture >= f.postureMax then
		-- 파훼
		f.posture = f.postureMax
		f.brokenUntil = now() + Config.BREAK_STUN
		Combat.stun(f, Config.BREAK_STUN)
		Push:FireAllClients("broken", f.model, Config.BREAK_STUN)
		return true
	end
	return false
end

function Combat.kill(f: Fighter, by: Fighter?)
	if f.dead then
		return
	end
	f.dead = true
	f.hp = 0
	f.act = nil
	f.guarding = false
	Combat.sync(f)
	Push:FireAllClients("ko", f.model, by and by.model or nil)
	if hooks.onKill then
		hooks.onKill(f, by)
	end
end

-- 피해 숫자 (공격자 쪽 배율)
local function damageOf(att: Fighter, hit: any, move: any, isSkill: boolean, act: Act?): number
	local d = hit.dmg * att.dmgMult
	if isSkill then
		d *= att.skillMult
	end
	if act and act.charge > 0 and move.chargeMult then
		local style = Combat.styleOf(att)
		local k = math.clamp(act.charge / (style and style.charge or 1.5), 0, 1)
		d *= 1 + (move.chargeMult - 1) * k
	end
	return d
end

------------------------------------------------------------------------
-- 한 번 맞히기. kind를 돌려준다: hit / block / deflect / guardbreak / clash / dodge / counter / miss
-- opt = { move, act, isSkill, unblockable, slotKey, chain }
------------------------------------------------------------------------
function Combat.applyHit(att: Fighter, tgt: Fighter, hit: any, opt: any): string
	if not Combat.hostile(att, tgt) then
		return "miss"
	end
	local t = now()
	if t < tgt.iframeUntil then
		Push:FireAllClients("hit", { a = att.model, t = tgt.model, kind = "dodge", pos = tgt.root.Position })
		return "dodge"
	end
	local move = opt.move or {}
	local toAtt = flat(att.root.Position - tgt.root.Position)
	local facing = Combat.look(tgt):Dot(toAtt)
	local pos = tgt.root.Position:Lerp(att.root.Position, 0.35) + Vector3.new(0, 1, 0)
	att.combatUntil = t + Config.COMBAT_TAG
	tgt.combatUntil = t + Config.COMBAT_TAG
	tgt.lastAttacker = att

	-- 격돌: 상대도 같은 순간 나를 향해 휘둘렀다
	if not opt.chain and not opt.proj and math.abs(tgt.lastSwingAt - t) <= Config.CLASH_WINDOW and facing > 0.5 and tgt.act and not move.aoe then
		-- 둘 다 서로 반대쪽으로 튕겨 난다
		knock(att, toAtt * 18 + Vector3.new(0, 6, 0), 0.3)
		knock(tgt, -toAtt * 18 + Vector3.new(0, 6, 0), 0.3)
		addPosture(att, 10)
		addPosture(tgt, 10)
		interrupt(att)
		interrupt(tgt)
		att.stunUntil = math.max(att.stunUntil, t + 0.3)
		tgt.stunUntil = math.max(tgt.stunUntil, t + 0.3)
		Push:FireAllClients("hit", { a = att.model, t = tgt.model, kind = "clash", pos = pos })
		return "clash"
	end

	local tStyle = Combat.styleOf(tgt)
	-- 취권: 비틀거려 저절로 피한다
	if tStyle and tStyle.dodgeChance and not opt.unblockable then
		local chance = 0
		if (tgt.buffs.sway or 0) > t then
			chance = 0.6
		elseif tgt.act or tgt.root.AssemblyLinearVelocity.Magnitude > 4 then
			chance = tStyle.dodgeChance
		end
		if chance > 0 and math.random() < chance then
			Push:FireAllClients("hit", { a = att.model, t = tgt.model, kind = "dodge", pos = pos, drunk = true })
			if (tgt.buffs.sway or 0) > t then
				-- 취보 중엔 피하면서 되받아친다
				task.defer(function()
					Combat.applyHit(tgt, att, { dmg = 6, posture = 10, stun = 0.4, kb = 10 }, { chain = true })
				end)
			end
			return "dodge"
		end
	end

	-- 태허 유수회선: 받아넘기고 되받아친다
	if t < tgt.counterUntil and not opt.unblockable and facing > -0.2 then
		tgt.counterUntil = 0
		addPosture(att, (hit.posture or 10) * Config.DEFLECT_POSTURE)
		att.stunUntil = math.max(att.stunUntil, t + Config.DEFLECT_STAGGER)
		interrupt(att)
		tgt.stacks.flow = math.min(3, tgt.stacks.flow + 1)
		Push:FireAllClients("hit", { a = att.model, t = tgt.model, kind = "deflect", pos = pos, counter = true })
		;(tgt :: any).deflectAt = now()
		local style = Combat.styleOf(tgt)
		local ch = style and style.skills.E.counterHit
		if ch then
			Push:FireAllClients("act", { m = tgt.model, style = tgt.style, pose = ch.pose, dur = 0.5, seq = -1 })
			task.delay(0.12, function()
				if not tgt.dead and not att.dead then
					Combat.applyHit(tgt, att, ch.hit, { move = { name = "되받아치기" }, isSkill = true, chain = true })
				end
			end)
		end
		Combat.sync(tgt)
		return "counter"
	end

	local postureDmg = (hit.posture or 0)
	-- 막기·흘리기 (앞에서 온 것만, 막을 수 없는 공격은 안 된다)
	if tgt.guarding and facing > 0.2 and not opt.unblockable and not opt.chain then
		local window = (tStyle and tStyle.deflect or Config.DEFLECT_WINDOW) + 0.06 -- 0.06 = 통신 늦음 여유
		if t - tgt.guardStart <= window then
			-- 흘리기 성공
			local broke = addPosture(att, postureDmg * Config.DEFLECT_POSTURE + 6)
			if not broke then
				att.stunUntil = math.max(att.stunUntil, t + Config.DEFLECT_STAGGER)
				interrupt(att)
			end
			tgt.posture = math.max(0, tgt.posture - 6)
			addChi(tgt, Config.CHI_ON_DEFLECT)
			if tStyle and tStyle.id == "taeheo" then
				tgt.stacks.flow = math.min(3, tgt.stacks.flow + 1)
			end
			Combat.sync(tgt)
			Combat.sync(att)
			Push:FireAllClients("hit", { a = att.model, t = tgt.model, kind = "deflect", pos = pos })
			;(tgt :: any).deflectAt = now()
			if hooks.onDeflect then
				hooks.onDeflect(tgt, att)
			end
			return "deflect"
		end
		-- 그냥 막기
		local d = damageOf(att, hit, move, opt.isSkill, opt.act) * Config.BLOCK_DAMAGE * (tStyle and tStyle.weakBlock or 1) * defense(tgt)
		tgt.hp -= d
		local broke = addPosture(tgt, postureDmg * Config.BLOCK_POSTURE)
		knock(tgt, -toAtt * math.min(20, (hit.kb or 0) * 0.4 + 4), 0)
		addChi(tgt, d * Config.CHI_ON_HURT)
		Combat.sync(tgt)
		Push:FireAllClients("hit", { a = att.model, t = tgt.model, kind = broke and "guardbreak" or "block", pos = pos, dmg = d })
		if tgt.hp <= 0 then
			Combat.kill(tgt, att)
		end
		return broke and "guardbreak" or "block"
	end

	-- 맞았다
	local d = damageOf(att, hit, move, opt.isSkill, opt.act) * defense(tgt)
	local crit = false
	local aStyle = Combat.styleOf(att)
	if aStyle and aStyle.backstab and facing < -0.3 then
		d *= aStyle.backstab
		crit = true
	end
	if opt.teleport then
		crit = true
	end
	local wasBroken = t < tgt.brokenUntil
	if wasBroken then
		d *= Config.BROKEN_MULT
		tgt.brokenUntil = 0
		tgt.posture = 0
		crit = true
	end
	tgt.hp -= d
	addPosture(tgt, postureDmg * 0.4)
	local heavy = (hit.kb or 0) >= 20 or (hit.stun or 0) >= 0.6 or wasBroken
	if not armored(tgt) then
		Combat.stun(tgt, hit.stun or 0.3)
		local dir = flat(tgt.root.Position - att.root.Position)
		local kb = (hit.kb or 0) * (wasBroken and 1.5 or 1)
		knock(tgt, dir * kb + Vector3.new(0, (hit.up or 0) + (kb > 25 and 12 or 0), 0), hit.stun or 0.3)
	end
	addChi(att, d * Config.CHI_ON_HIT)
	addChi(tgt, d * Config.CHI_ON_HURT)

	-- 공격한 쪽 권법 장치: 꽃잎, 전하
	local chain = false
	if aStyle and not opt.chain then
		if aStyle.id == "maehwa" then
			if t - att.stacks.petalAt > 1.2 then
				att.stacks.petal = 0
			end
			att.stacks.petal = math.min(20, att.stacks.petal + 1)
			att.stacks.petalAt = t
		elseif aStyle.id == "byeokryeok" then
			att.stacks.charge += 1
			if att.stacks.charge >= 5 then
				att.stacks.charge = 0
				chain = true
			end
		end
	end
	Combat.sync(att)
	Combat.sync(tgt)
	Push:FireAllClients("hit", {
		a = att.model,
		t = tgt.model,
		kind = "hit",
		pos = pos,
		dmg = d,
		heavy = heavy,
		crit = crit,
		style = att.style,
		strike = move.strike == true,
		broken = wasBroken,
	})
	if hooks.onHit then
		hooks.onHit(att, tgt, d, opt)
	end
	if tgt.hp <= 0 then
		Combat.kill(tgt, att)
	end
	-- 벽력: 연쇄 번개
	if chain then
		local victims = {}
		for _, other in pairs(Combat.fighters) do
			if other ~= tgt and Combat.hostile(att, other) and (other.root.Position - tgt.root.Position).Magnitude <= 16 then
				table.insert(victims, other)
			end
		end
		Push:FireAllClients("chain", { from = tgt.model, to = (function()
			local list = {}
			for _, v in ipairs(victims) do
				table.insert(list, v.model)
			end
			return list
		end)() })
		for _, v in ipairs(victims) do
			Combat.applyHit(att, v, { dmg = 9, posture = 12, stun = 1.0, kb = 4 }, { chain = true, move = { strike = true } })
		end
		if not tgt.dead then
			Combat.stun(tgt, 1.0)
		end
	end
	return "hit"
end

------------------------------------------------------------------------
-- 기술 시작 (사람과 적 공통). 화면들에게 동작을 알린다
------------------------------------------------------------------------
function Combat.begin(f: Fighter, move: any, slot: any, seq: number, opt: any?): Act
	local o = opt or {}
	local speed = o.speed or 1
	local act: Act = {
		move = move,
		slot = slot,
		seq = seq,
		start = now(),
		dur = move.dur / speed,
		speed = speed,
		done = {},
		swung = {},
		charge = o.charge or 0,
		bloom = o.bloom == true,
		enemy = o.enemy == true,
	}
	f.act = act
	f.guarding = false
	if move.iframes then
		f.iframeUntil = math.max(f.iframeUntil, now() + move.iframes)
	end
	Push:FireAllClients("act", {
		m = f.model,
		style = f.style,
		slot = slot,
		pose = move.pose,
		dur = act.dur,
		align = o.align,
		seq = seq,
		id = move.id,
		charge = act.charge,
		bloom = act.bloom,
		unblockable = move.unblockable,
		windup = move.windup and move.windup / speed or nil,
	})
	return act
end

-- 기술이 끝났는지
function Combat.busy(f: Fighter): boolean
	local act = f.act
	return act ~= nil and now() < act.start + act.dur
end

-- 앞쪽 상자 안의 상대들 (서버 판정용)
function Combat.query(att: Fighter, hit: any, from: Vector3?): { Fighter }
	local origin = from or att.root.Position
	local look = Combat.look(att)
	local center = hit.aoe and origin or origin + look * (hit.range * 0.55)
	local list = {}
	for _, f in pairs(Combat.fighters) do
		if Combat.hostile(att, f) then
			local dist = Vector3.new(f.root.Position.X - center.X, 0, f.root.Position.Z - center.Z).Magnitude
			local reach = hit.aoe and hit.radius or (hit.range * 0.55 + hit.radius)
			if dist <= reach + 1.5 and math.abs(f.root.Position.Y - origin.Y) < 9 then
				table.insert(list, f)
			end
		end
	end
	return list
end

-- 화면이 알려 준 맞힘이 믿을 만한지 (거리)
function Combat.plausible(att: Fighter, tgt: Fighter, hit: any): boolean
	local d = Vector3.new(tgt.root.Position.X - att.root.Position.X, 0, tgt.root.Position.Z - att.root.Position.Z).Magnitude
	local reach = hit.aoe and hit.radius or (hit.range + hit.radius)
	return d <= reach + Config.HIT_TOLERANCE + 3 and math.abs(tgt.root.Position.Y - att.root.Position.Y) < 14
end

------------------------------------------------------------------------
-- 장풍
------------------------------------------------------------------------
function Combat.fire(owner: Fighter, proj: any, scale: number, opt: any)
	local look = Combat.look(owner)
	local pos = owner.root.Position + look * 2.5 + Vector3.new(0, 0.8, 0)
	local p = {
		owner = owner,
		pos = pos,
		dir = look,
		speed = proj.speed,
		life = proj.life,
		radius = proj.radius * scale,
		hit = { dmg = proj.dmg * scale, posture = proj.posture * scale, stun = proj.stun, kb = proj.kb * math.sqrt(scale), range = 0, radius = proj.radius * scale },
		pierce = proj.pierce == true,
		hitSet = {},
		opt = opt,
	}
	table.insert(Combat.projectiles, p)
	Push:FireAllClients("proj", { m = owner.model, pos = pos, dir = look, speed = proj.speed, life = proj.life, size = (proj.size or 3) * scale, style = owner.style })
end

function Combat.stepProjectiles(dt: number)
	for i = #Combat.projectiles, 1, -1 do
		local p = Combat.projectiles[i]
		p.life -= dt
		local step = p.dir * p.speed * dt
		local from = p.pos
		p.pos += step
		local stop = p.life <= 0 or p.owner.dead
		if not stop then
			for _, f in pairs(Combat.fighters) do
				if not p.hitSet[f] and Combat.hostile(p.owner, f) then
					-- 지나온 선분과 거리
					local v = f.root.Position - from
					local seg = step.Magnitude > 0 and step.Unit or p.dir
					local along = math.clamp(v:Dot(seg), 0, step.Magnitude)
					local closest = from + seg * along
					local dist = Vector3.new(f.root.Position.X - closest.X, 0, f.root.Position.Z - closest.Z).Magnitude
					if dist <= p.radius + 1.5 and math.abs(f.root.Position.Y - closest.Y) < 6 then
						p.hitSet[f] = true
						Combat.applyHit(p.owner, f, p.hit, { move = p.opt.move, isSkill = p.opt.isSkill, proj = true })
						if not p.pierce then
							stop = true
							break
						end
					end
				end
			end
		end
		if stop then
			table.remove(Combat.projectiles, i)
		end
	end
end

------------------------------------------------------------------------
-- 매 순간: 균형·내공 회복, 걷는 속도 (기절·막기)
------------------------------------------------------------------------
function Combat.tick(dt: number)
	local t = now()
	for _, f in pairs(Combat.fighters) do
		if not f.dead then
			local changed = false
			if f.posture > 0 and t - f.lastHurtAt > Config.POSTURE_REGEN_DELAY and t > f.brokenUntil then
				f.posture = math.max(0, f.posture - Config.POSTURE_REGEN * dt)
				changed = true
			end
			if f.player and f.chi < Config.CHI_MAX then
				f.chi = math.min(Config.CHI_MAX, f.chi + Config.CHI_REGEN * dt * (f.skillMult or 1))
				changed = true
			end
			if f.act and t > f.act.start + f.act.dur then
				f.act = nil
			end
			local speed = f.walk
			if t < f.stunUntil then
				speed = 0
			elseif f.guarding then
				speed = f.walk * 0.4
			elseif f.act and not f.npc then
				speed = f.walk * 0.35
			elseif (f :: any).sprint then
				speed = f.walk * 1.45
			end
			if f.hum and math.abs(f.hum.WalkSpeed - speed) > 0.1 then
				f.hum.WalkSpeed = speed
			end
			if changed then
				-- 자주 바뀌는 값은 반올림해서 보낸다 (속성은 바뀔 때만 전달된다)
				f.model:SetAttribute("Posture", math.floor(f.posture + 0.5))
				f.model:SetAttribute("Chi", math.floor(f.chi))
			end
		end
	end
	Combat.stepProjectiles(dt)
end

function Combat.fighterOfPlayer(player: Player): Fighter?
	local char = player.Character
	return char and Combat.fighters[char] or nil
end

local _ = Players
return Combat
