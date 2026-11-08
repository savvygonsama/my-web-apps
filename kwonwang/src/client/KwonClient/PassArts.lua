-- 권왕 3.41판: 게임패스 권법 둘의 화면
--   구미호권: 등 뒤의 여우 꼬리 (강화 단계만큼 1 → 9개), +10 금빛 눈, +15 거대한 꼬리 그림자. 기술은 푸른 여우불
--   흑염마검장: 손에 빚은 검은 불꽃 검 (+5부터 두 손). 강화할수록 길고 짙어지며 보랏빛 → 핏빛으로 타오른다. 기술은 검은 불꽃
-- 꾸밈은 모두 이 화면에서만 그린다 (서버는 Style · Enh 속성만 붙인다)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Fx = require(script.Parent:WaitForChild("Fx"))
local Perf = require(script.Parent:WaitForChild("Perf"))

local PassArts = {}

local FOX = Color3.fromRGB(90, 175, 255)
local FOX_PALE = Color3.fromRGB(225, 245, 255)
local FOX_FUR = Color3.fromRGB(238, 242, 250)
local GOLD = Color3.fromRGB(255, 214, 90)
local INK = Color3.fromRGB(18, 8, 26)
local PURPLE = Color3.fromRGB(196, 70, 255)
local CRIMSON = Color3.fromRGB(255, 40, 70)
local WHITE_HOT = Color3.fromRGB(255, 225, 235)
local TEX_FIRE = "rbxasset://textures/particles/fire_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local folder = Instance.new("Folder")
folder.Name = "KwonPassArts"
folder.Parent = workspace

local opts: any = {}
function PassArts.init(o: any)
	opts = o or {}
end
local function shake(a: number, t: number)
	if opts.shake then
		pcall(opts.shake, a, t)
	end
end

------------------------------------------------------------------------
-- 조각 만들기
------------------------------------------------------------------------
local function part(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, shape: string?): BasePart
	local p: BasePart
	if shape == "wedge" then
		p = Instance.new("WedgePart")
	else
		local q = Instance.new("Part")
		if shape == "ball" then
			q.Shape = Enum.PartType.Ball
		elseif shape == "cyl" then
			q.Shape = Enum.PartType.Cylinder
		end
		p = q
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Neon
	p.Transparency = alpha or 0
	return p
end
local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function temp(p: BasePart, life: number)
	p.Parent = folder
	Debris:AddItem(p, life + 0.1)
	return p
end
local function cs(a: Color3, b: Color3?, c: Color3?): ColorSequence
	if c then
		return ColorSequence.new({ ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.5, b :: Color3), ColorSequenceKeypoint.new(1, c) })
	end
	return ColorSequence.new(a, b or a)
end
local function ns(a: number, b: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end
local function emitter(parent: Instance, tex: string, color: ColorSequence, size: NumberSequence, rate: number, life: number, speed: number, opt: any?): ParticleEmitter
	local o = opt or {}
	local e = Instance.new("ParticleEmitter")
	e.Texture = tex
	e.Color = color
	e.Size = size
	e.Transparency = o.alpha or ns(0.2, 1)
	e.Rate = (Perf.low and 0.4 or 1) * rate
	e.Lifetime = NumberRange.new(life * 0.7, life)
	e.Speed = NumberRange.new(speed * 0.6, speed)
	e.SpreadAngle = o.spread or Vector2.new(20, 20)
	e.Acceleration = o.accel or Vector3.new(0, 4, 0)
	e.LightEmission = o.light or 1
	e.Rotation = NumberRange.new(-180, 180)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.LockedToPart = o.locked == true
	e.ZOffset = o.z or 0
	e.Parent = parent
	return e
end
local function rootOf(m: Instance?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function bodyPart(m: Model, name: string, alt: string?): BasePart?
	local p = m:FindFirstChild(name) or (alt and m:FindFirstChild(alt))
	return (p and p:IsA("BasePart")) and p or nil
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
end

------------------------------------------------------------------------
-- 강화 단계 → 모습
------------------------------------------------------------------------
-- 구미호: 꼬리 수 (+0 하나 · +5 넷 · +10 일곱 · +15 아홉)
local TAILS = { [0] = 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 7, 7, 8, 8, 9, 9 }
function PassArts.tails(lv: number): number
	return TAILS[math.clamp(math.floor(lv), 0, 15)] or 1
end
-- 흑염: 검 단계 (0 한 손 · 1 길게 · 2 두 손 · 3 불꽃 자취 · 4 핏빛 날 · 5 끝 (흰 불심, 붉은 눈))
function PassArts.bladeTier(lv: number): number
	local l = math.clamp(math.floor(lv), 0, 15)
	return l >= 15 and 5 or (l >= 10 and 4 or (l >= 8 and 3 or (l >= 5 and 2 or (l >= 3 and 1 or 0))))
end

------------------------------------------------------------------------
-- 몸에 붙는 꾸밈 (사람마다 하나)
------------------------------------------------------------------------
type Rig = { model: Model, style: string, lv: number, parts: { BasePart }, tails: { { BasePart } }?, ghost: { { BasePart } }?, extra: { Instance } }
local rigs: { [Model]: Rig } = {}

local function clearRig(m: Model)
	local r = rigs[m]
	if r then
		for _, p in ipairs(r.parts) do
			p:Destroy()
		end
		for _, x in ipairs(r.extra) do
			x:Destroy()
		end
		rigs[m] = nil
	end
end

-- 몸에 붙인 조각 (용접): 몸을 따라 움직인다
local function weldTo(base: BasePart, p: BasePart, offset: CFrame): BasePart
	p.Anchored = false
	p.CFrame = base.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
	p.Parent = folder
	return p
end

local SEG = 6
local function buildFox(m: Model, lv: number): Rig
	local rig: Rig = { model = m, style = "gumiho", lv = lv, parts = {}, extra = {} }
	local n = PassArts.tails(lv)
	local tails = {}
	for t = 1, n do
		local segs = {}
		for i = 1, SEG do
			local k = (i - 1) / (SEG - 1)
			local w = 1.0 - 0.62 * k
			local tip = i >= SEG - 1
			local p = part(Vector3.new(w, w, 1.35), tip and FOX or FOX_FUR:Lerp(FOX_PALE, k), tip and Enum.Material.Neon or Enum.Material.SmoothPlastic, tip and 0.05 or 0.08, "ball")
			p.Parent = folder
			table.insert(segs, p)
			table.insert(rig.parts, p)
			if i == SEG then
				emitter(p, TEX_FIRE, cs(FOX_PALE, FOX), ns(0.9, 0.1), 8, 0.6, 2, { accel = Vector3.new(0, 5, 0) })
			end
		end
		table.insert(tails, segs)
	end
	rig.tails = tails
	-- +10: 금빛 눈 (머리 앞에 작은 빛 두 점)
	local head = bodyPart(m, "Head")
	if head and lv >= 10 then
		for sx = -1, 1, 2 do
			local eye = part(Vector3.new(0.16, 0.08, 0.05), GOLD, Enum.Material.Neon, 0, nil)
			table.insert(rig.parts, weldTo(head, eye, CFrame.new(0.17 * sx, 0.12, -head.Size.Z / 2 - 0.01)))
		end
	end
	-- +15: 거대한 꼬리 그림자 (흐릿하게 크게)
	if lv >= 15 then
		local ghost = {}
		for t = 1, 3 do
			local segs = {}
			for i = 1, SEG do
				local k = (i - 1) / (SEG - 1)
				local w = 2.4 - 1.5 * k
				local p = part(Vector3.new(w, w, 2.6), FOX, Enum.Material.Neon, 0.82, "ball")
				p.Parent = folder
				table.insert(segs, p)
				table.insert(rig.parts, p)
			end
			table.insert(ghost, segs)
		end
		rig.ghost = ghost
	end
	-- 몸에 감도는 여우불 (단계가 오를수록 짙게)
	local torso = bodyPart(m, "UpperTorso", "Torso")
	if torso then
		local a = Instance.new("Attachment")
		a.Parent = torso
		table.insert(rig.extra, a)
		emitter(a, TEX_FIRE, cs(FOX_PALE, FOX), ns(0.6, 0), 2 + lv * 0.6, 0.8, 1.5, { spread = Vector2.new(180, 180), accel = Vector3.new(0, 3, 0), alpha = ns(0.5, 1) })
	end
	return rig
end

-- 검 하나: 손에서 팔이 뻗은 방향으로 이어지는 불꽃 날
local function blade(rig: Rig, hand: BasePart, tier: number)
	local L = ({ [0] = 3.2, 3.8, 3.9, 4.1, 4.6, 4.9 })[tier] or 3.2
	local edgeCol = tier >= 4 and CRIMSON:Lerp(PURPLE, 0.35) or PURPLE
	local down = CFrame.new(0, -hand.Size.Y / 2 - L / 2 - 0.05, 0)
	-- 몸날: 검은 불꽃 (넓적하고 얇다)
	local core = part(Vector3.new(0.12, L, 0.42), INK, Enum.Material.Neon, 0, nil)
	table.insert(rig.parts, weldTo(hand, core, down))
	-- 날끝 (쐐기)
	local tipP = part(Vector3.new(0.12, 0.7, 0.42), INK, Enum.Material.Neon, 0, "wedge")
	table.insert(rig.parts, weldTo(hand, tipP, down * CFrame.new(0, -L / 2 - 0.35, 0) * CFrame.Angles(math.pi, 0, 0)))
	-- 날의 빛 (양쪽 가장자리)
	for sz = -1, 1, 2 do
		local edge = part(Vector3.new(0.14, L, 0.06), edgeCol, Enum.Material.Neon, tier >= 1 and 0 or 0.25, nil)
		table.insert(rig.parts, weldTo(hand, edge, down * CFrame.new(0, 0, sz * 0.22)))
	end
	-- +15: 흰 불심
	if tier >= 5 then
		local heart = part(Vector3.new(0.15, L * 0.8, 0.07), WHITE_HOT, Enum.Material.Neon, 0, nil)
		table.insert(rig.parts, weldTo(hand, heart, down))
	end
	-- 검의 불꽃 (검은 연기 + 보랏빛 / 핏빛 불)
	emitter(core, TEX_SMOKE, cs(INK, Color3.fromRGB(50, 20, 60)), ns(0.9, 0.2), 10 + tier * 4, 0.55, 1.5, { accel = Vector3.new(0, 6, 0), light = 0, alpha = ns(0.35, 1) })
	emitter(core, TEX_FIRE, cs(tier >= 4 and CRIMSON or PURPLE, edgeCol, INK), ns(0.7, 0.05), 8 + tier * 4, 0.45, 2, { accel = Vector3.new(0, 7, 0) })
	-- +8: 휘두르면 불꽃 자취
	if tier >= 3 then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, L / 2, 0)
		a0.Parent = core
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -L / 2, 0)
		a1.Parent = core
		local tr = Instance.new("Trail")
		tr.Attachment0 = a0
		tr.Attachment1 = a1
		tr.Color = cs(edgeCol, INK)
		tr.Transparency = ns(0.2, 1)
		tr.LightEmission = 1
		tr.Lifetime = 0.22
		tr.MinLength = 0.05
		tr.Parent = core
	end
	-- +10: 손목의 불꽃 고리
	if tier >= 4 then
		local ring = part(Vector3.new(0.12, 1.1, 1.1), edgeCol, Enum.Material.Neon, 0.15, "cyl")
		table.insert(rig.parts, weldTo(hand, ring, CFrame.new(0, -hand.Size.Y / 2 + 0.05, 0) * CFrame.Angles(0, 0, math.pi / 2)))
	end
end

local function buildFlame(m: Model, lv: number): Rig
	local rig: Rig = { model = m, style = "heukyeom", lv = lv, parts = {}, extra = {} }
	local tier = PassArts.bladeTier(lv)
	local rh = bodyPart(m, "RightHand", "Right Arm")
	local lh = bodyPart(m, "LeftHand", "Left Arm")
	if rh then
		blade(rig, rh, tier)
	end
	if lh and tier >= 2 then
		blade(rig, lh, tier)
	end
	-- +10: 몸을 감싸는 검은 불꽃 · +15: 붉은 눈과 더 큰 불꽃
	local torso = bodyPart(m, "UpperTorso", "Torso")
	if torso and tier >= 4 then
		local a = Instance.new("Attachment")
		a.Parent = torso
		table.insert(rig.extra, a)
		emitter(a, TEX_SMOKE, cs(INK, Color3.fromRGB(40, 12, 50)), ns(1.6, 0.4), tier >= 5 and 18 or 10, 0.9, 2, { spread = Vector2.new(180, 180), accel = Vector3.new(0, 7, 0), light = 0, alpha = ns(0.45, 1) })
		emitter(a, TEX_FIRE, cs(tier >= 5 and CRIMSON or PURPLE, INK), ns(1.1, 0.1), tier >= 5 and 14 or 6, 0.6, 2, { spread = Vector2.new(180, 180), accel = Vector3.new(0, 8, 0) })
	end
	local head = bodyPart(m, "Head")
	if head and tier >= 5 then
		for sx = -1, 1, 2 do
			local eye = part(Vector3.new(0.16, 0.07, 0.05), CRIMSON, Enum.Material.Neon, 0, nil)
			table.insert(rig.parts, weldTo(head, eye, CFrame.new(0.17 * sx, 0.12, -head.Size.Z / 2 - 0.01)))
		end
	end
	return rig
end

-- 꼬리를 매 장면 흔든다 (허리 뒤에서 부채꼴로 솟아 끝이 휘어진다)
local function poseTails(rig: Rig, t: number)
	local m = rig.model
	local base = bodyPart(m, "LowerTorso", "Torso")
	if not base then
		return
	end
	local cf = base.CFrame * CFrame.new(0, -0.1, base.Size.Z / 2 + 0.1)
	local function lay(list: { { BasePart } }, scale: number, spreadDeg: number, phase: number)
		local n = #list
		for ti, segs in ipairs(list) do
			local u = n > 1 and ((ti - 1) / (n - 1) - 0.5) or 0
			-- 등 뒤 축 (Z) 으로 기울여 부채꼴로 펼친다
			local roll = math.rad(u * spreadDeg)
			local sway = math.sin(t * 2.2 + ti * 0.9 + phase) * 0.35
			local cur = cf * CFrame.Angles(0, sway * 0.25, roll + sway * 0.15) * CFrame.Angles(math.rad(-22), 0, 0)
			for i, p in ipairs(segs) do
				local k = (i - 1) / (#segs - 1)
				-- 뒤로 뻗다가 위로 감겨 오른다 (끝으로 갈수록 더 휘고 더 흔들린다)
				cur = cur * CFrame.Angles(math.rad(-7 - 6 * k) + sway * 0.12 * k, sway * 0.1, 0) * CFrame.new(0, 0, 0.75 * scale)
				p.CFrame = cur * CFrame.new(0, 0, 0.35 * scale)
			end
		end
	end
	if rig.tails then
		lay(rig.tails, 1, math.min(140, 30 * #rig.tails), 0)
	end
	if rig.ghost then
		lay(rig.ghost, 2.3, 120, 1.7)
	end
end

local function styleOf(m: Model): (string?, number)
	local s = m:GetAttribute("Style")
	local lv = tonumber(m:GetAttribute("Enh")) or 0
	if s == "gumiho" or s == "heukyeom" then
		return s, lv
	end
	return nil, 0
end

-- 사람들의 몸을 둘러보고 꾸밈을 맞춘다 (권법 · 강화 단계가 바뀌면 다시 짓는다)
local function sweep()
	local seen: { [Model]: boolean } = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		local m = pl.Character
		if m and m.Parent then
			local s, lv = styleOf(m)
			local r = rigs[m]
			if s and m:GetAttribute("Vanish") ~= true then
				seen[m] = true
				if not r or r.style ~= s or r.lv ~= lv then
					clearRig(m)
					local ok, rig = pcall(s == "gumiho" and buildFox or buildFlame, m, lv)
					if ok and rig then
						rigs[m] = rig
					end
				end
			end
		end
	end
	for m in pairs(rigs) do
		if not seen[m] then
			clearRig(m)
		end
	end
end

local started = false
function PassArts.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		while true do
			pcall(sweep)
			task.wait(0.5)
		end
	end)
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for m, rig in pairs(rigs) do
			if rig.tails and m.Parent then
				local r = rootOf(m)
				if r and near(r.Position, Perf.low and 90 or 180) then
					poseTails(rig, t)
				end
			end
		end
	end)
end

------------------------------------------------------------------------
-- 기술 연출
------------------------------------------------------------------------
local function fireBall(at: Vector3, color: Color3, size: number, life: number)
	local b = temp(part(Vector3.one * size, color, Enum.Material.Neon, 0.1, "ball"), life)
	b.Position = at
	tween(b, life, { Size = Vector3.one * size * 2.4, Transparency = 1 })
	return b
end
local function flameBurst(at: Vector3, c1: Color3, c2: Color3, radius: number, dark: boolean?)
	local holder = temp(part(Vector3.one * 0.2, c1, Enum.Material.Neon, 1, nil), 1.4)
	holder.Position = at
	local e = emitter(holder, TEX_FIRE, cs(c1, c2), ns(radius * 0.5, 0.2), 0, 0.6, radius * 1.4, { spread = Vector2.new(180, 180), accel = Vector3.new(0, radius, 0) })
	e:Emit(Perf.low and 12 or 28)
	if dark then
		local s = emitter(holder, TEX_SMOKE, cs(INK, Color3.fromRGB(40, 14, 54)), ns(radius * 0.6, radius * 0.2), 0, 0.9, radius, { spread = Vector2.new(180, 180), accel = Vector3.new(0, radius * 0.6, 0), light = 0, alpha = ns(0.3, 1) })
		s:Emit(Perf.low and 8 or 18)
	end
	Fx.ring(at - Vector3.new(0, 2.4, 0), c1, 1, radius * 2, 0.45)
end

-- 검은 초승달 검기 (앞으로 퍼진다)
local function crescent(from: Vector3, dir: Vector3, range: number, width: number, col: Color3, life: number)
	local n = Perf.low and 7 or 13
	local half = math.rad(width / 2)
	for i = 0, n - 1 do
		local a = -half + (2 * half) * i / (n - 1)
		local d = (CFrame.Angles(0, a, 0) * CFrame.lookAt(Vector3.zero, dir)).LookVector
		local p = temp(part(Vector3.new(1.4, 0.3, 2.6), i % 2 == 0 and INK or col, Enum.Material.Neon, 0.05, nil), life)
		p.CFrame = CFrame.lookAt(from + d * 3, from + d * 4)
		tween(p, life, { CFrame = CFrame.lookAt(from + d * range, from + d * (range + 1)), Transparency = 1, Size = Vector3.new(3, 0.2, 4.5) }, Enum.EasingStyle.Quart)
	end
end

local H: { [string]: { [string]: (any) -> () } } = { gumiho = {}, heukyeom = {} }

-- 구미호 ---------------------------------------------------------------
H.gumiho.mark = function(d)
	Fx.ring(d.at - Vector3.new(0, 2.4, 0), FOX, 1, (d.radius or 5) * 2, d.time or 0.3)
end
H.gumiho.strike = function(d)
	flameBurst(d.at, FOX_PALE, FOX, d.radius or 5, false)
	fireBall(d.at, FOX, 2.2, 0.35)
	Fx.sound("ping", 0.45, 1.5, d.at)
end
H.gumiho.pulse = function(d)
	task.delay(d.delay or 0, function()
		flameBurst(d.at, FOX_PALE, FOX, d.radius or 8, false)
		Fx.sound("ping", 0.4, 1.7, d.at)
	end)
end
H.gumiho.rushDash = function(d)
	local from, to = d.from, d.to
	if not from or not to then
		return
	end
	-- 여우 잔상: 지나간 자리에 푸른 그림자가 남아 흐려진다
	local n = Perf.low and 3 or 6
	for i = 0, n - 1 do
		local u = i / math.max(1, n - 1)
		local p = temp(part(Vector3.new(1.6, 4.4, 0.9), FOX, Enum.Material.Neon, 0.55, nil), 0.5)
		p.CFrame = CFrame.lookAt(from:Lerp(to, u), to)
		tween(p, 0.45, { Transparency = 1, Size = Vector3.new(0.4, 4.6, 0.4) })
	end
	if d.t then
		local r = rootOf(d.t)
		if r then
			flameBurst(r.Position, FOX_PALE, FOX, 4, false)
		end
	end
	Fx.sound("swing", 0.5, 1.6, to)
end
H.gumiho.zone = function(d)
	-- 구미난무: 둘레를 도는 여우불 고리와 커다란 꼬리 그림자 아홉
	local at, R, dur = d.at, d.radius or 18, d.dur or 1.6
	local orbs = {}
	local n = Perf.low and 6 or 12
	for i = 1, n do
		local o = temp(part(Vector3.one * 1.6, FOX_PALE, Enum.Material.Neon, 0.05, "ball"), dur + 0.4)
		emitter(o, TEX_FIRE, cs(FOX_PALE, FOX), ns(1.6, 0.1), 30, 0.4, 1)
		table.insert(orbs, o)
	end
	local tails = {}
	for i = 1, 9 do
		local tp = temp(part(Vector3.new(2.2, 0.6, R * 0.7), FOX, Enum.Material.Neon, 0.6, "ball"), dur + 0.4)
		table.insert(tails, tp)
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > dur then
			conn:Disconnect()
			for _, o in ipairs(orbs) do
				tween(o, 0.3, { Transparency = 1, Size = Vector3.one * 4 })
			end
			for _, tp in ipairs(tails) do
				tween(tp, 0.3, { Transparency = 1 })
			end
			flameBurst(at, FOX_PALE, FOX, R * 0.6, false)
			return
		end
		for i, o in ipairs(orbs) do
			local a = t * 5 + i / #orbs * math.pi * 2
			local rr = R * (0.45 + 0.4 * ((i % 2 == 0) and 1 or 0.6))
			o.Position = at + Vector3.new(math.cos(a) * rr, 0.5 + math.sin(t * 6 + i) * 1.2, math.sin(a) * rr)
		end
		for i, tp in ipairs(tails) do
			local a = -t * 3 + i / 9 * math.pi * 2
			tp.CFrame = CFrame.new(at + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(-25), 0, 0) * CFrame.new(0, 0, -R * 0.35)
		end
	end)
	shake(0.4, dur)
	Fx.sound("whoosh", 0.6, 0.9, at)
end

-- 흑염 ---------------------------------------------------------------
H.heukyeom.cone = function(d)
	local m = d.m
	local r = rootOf(m)
	if not r then
		return
	end
	task.delay(d.delay or 0, function()
		local dir = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z).Unit
		crescent(r.Position, dir, d.range or 24, d.angle or 80, PURPLE, 0.4)
		Fx.sound("swing", 0.7, 0.6, r.Position)
		shake(0.25, 0.2)
	end)
end
H.heukyeom.pillar = function(d)
	local at = d.at - Vector3.new(0, 2.6, 0)
	local R = d.radius or 5
	local col = temp(part(Vector3.new(R * 0.9, 1, R * 0.9), INK, Enum.Material.Neon, 0.05, "cyl"), 0.7)
	col.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.pi / 2)
	tween(col, 0.18, { Size = Vector3.new(16, R * 0.7, R * 0.7), CFrame = CFrame.new(at + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
	task.delay(0.2, function()
		tween(col, 0.4, { Transparency = 1, Size = Vector3.new(18, R * 0.2, R * 0.2) })
	end)
	flameBurst(d.at, PURPLE, INK, R, true)
	if (d.i or 1) == 1 then
		Fx.sound("heavy", 0.6, 0.7, at)
	end
end
H.heukyeom.charge = function(d)
	local r = rootOf(d.m)
	if not r then
		return
	end
	-- 두 검에 불꽃이 모인다
	local time = d.time or 1
	local holder = temp(part(Vector3.one * 0.2, INK, Enum.Material.Neon, 1, nil), time + 0.3)
	holder.Position = r.Position
	local e = emitter(holder, TEX_FIRE, cs(PURPLE, INK), ns(1.4, 0.1), 60, 0.5, -8, { spread = Vector2.new(180, 180), accel = Vector3.zero })
	task.delay(time, function()
		e.Enabled = false
	end)
	Fx.ring(r.Position - Vector3.new(0, 2.5, 0), PURPLE, 14, 2, time)
end
H.heukyeom.onepunch = function(d)
	-- 쌍염십자참: X자 검기 두 줄기가 앞으로 날아간다
	local from, dir, range = d.from, d.dir, d.range or 54
	if not from or not dir then
		return
	end
	local flat = Vector3.new(dir.X, 0, dir.Z).Unit
	for k = -1, 1, 2 do
		local slash = temp(part(Vector3.new(0.6, 14, 3), INK, Enum.Material.Neon, 0, nil), 0.7)
		local edge = temp(part(Vector3.new(0.7, 14.5, 0.8), CRIMSON:Lerp(PURPLE, 0.4), Enum.Material.Neon, 0, nil), 0.7)
		local function cfAt(dist: number): CFrame
			return CFrame.lookAt(from + flat * dist + Vector3.new(0, 1.5, 0), from + flat * (dist + 1) + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(45 * k))
		end
		slash.CFrame = cfAt(3)
		edge.CFrame = cfAt(3)
		tween(slash, 0.5, { CFrame = cfAt(range), Size = Vector3.new(0.6, 22, 4), Transparency = 0.6 }, Enum.EasingStyle.Quart)
		tween(edge, 0.5, { CFrame = cfAt(range), Size = Vector3.new(0.7, 22.5, 0.8), Transparency = 0.5 }, Enum.EasingStyle.Quart)
		task.delay(0.5, function()
			tween(slash, 0.2, { Transparency = 1 })
			tween(edge, 0.2, { Transparency = 1 })
		end)
	end
	for i = 1, 5 do
		task.delay(i * 0.08, function()
			flameBurst(from + flat * (range * i / 5), PURPLE, INK, 5, true)
		end)
	end
	shake(0.8, 0.4)
	if Fx.flash then
		Fx.flash(from, PURPLE, 60, 4, 0.4)
	end
	Fx.sound("heavy", 0.9, 0.5, from)
end
-- 흑염멸천: 하늘에 검은 불꽃 소용돌이, 불꽃 검이 쏟아진다
H.heukyeom.stormcloud = function(d)
	local r = rootOf(d.m)
	if not r then
		return
	end
	local dur, R = d.dur or 2.4, d.radius or 40
	local sky = temp(part(Vector3.new(1, R * 1.6, R * 1.6), INK, Enum.Material.Neon, 0.35, "cyl"), dur + 0.8)
	sky.CFrame = CFrame.new(r.Position + Vector3.new(0, 34, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	local ring = temp(part(Vector3.new(1.2, R * 1.7, R * 1.7), PURPLE, Enum.Material.Neon, 0.7, "cyl"), dur + 0.8)
	ring.CFrame = sky.CFrame
	emitter(sky, TEX_SMOKE, cs(INK, Color3.fromRGB(50, 16, 60)), ns(8, 4), 20, 1.4, 2, { spread = Vector2.new(180, 180), light = 0, alpha = ns(0.3, 1) })
	task.delay(dur, function()
		tween(sky, 0.6, { Transparency = 1 })
		tween(ring, 0.6, { Transparency = 1 })
	end)
	if opts.tint then
		pcall(opts.tint, Color3.fromRGB(60, 20, 70), 0.35, dur)
	end
	shake(0.5, dur)
end
H.heukyeom.strike = function(d)
	local at = d.at
	if d.small then
		-- 하늘에서 떨어지는 불꽃 검
		local sw = temp(part(Vector3.new(0.3, 7, 1), INK, Enum.Material.Neon, 0, nil), 0.6)
		local ed = temp(part(Vector3.new(0.34, 7.2, 0.25), PURPLE, Enum.Material.Neon, 0, nil), 0.6)
		local top = CFrame.new(at + Vector3.new(0, 30, 0))
		sw.CFrame = top
		ed.CFrame = top
		tween(sw, 0.16, { CFrame = CFrame.new(at + Vector3.new(0, 1, 0)) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(ed, 0.16, { CFrame = CFrame.new(at + Vector3.new(0, 1, 0)) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.17, function()
			flameBurst(at, PURPLE, INK, d.radius or 8, true)
			tween(sw, 0.35, { Transparency = 1 })
			tween(ed, 0.35, { Transparency = 1 })
		end)
	else
		-- 마지막: 두 검을 내리꽂아 둘레가 불탄다
		flameBurst(at, CRIMSON, INK, (d.radius or 30) * 0.5, true)
		Fx.ring(at - Vector3.new(0, 2.4, 0), PURPLE, 4, (d.radius or 30) * 2.2, 0.7)
		Fx.ring(at - Vector3.new(0, 2.2, 0), CRIMSON, 2, (d.radius or 30) * 1.6, 0.55)
		if Fx.flash then
			Fx.flash(at, CRIMSON, 80, 5, 0.5)
		end
		shake(1.2, 0.6)
		Fx.sound("heavy", 1, 0.45, at)
	end
end
H.heukyeom.pulse = function(d)
	task.delay(d.delay or 0, function()
		flameBurst(d.at, PURPLE, INK, d.radius or 10, true)
		Fx.sound("heavy", 0.5, 0.8, d.at)
	end)
end

function PassArts.handles(data: any): boolean
	local h = H[data.style]
	return h ~= nil and h[data.kind] ~= nil
end
function PassArts.run(data: any)
	local h = H[data.style]
	local fn = h and h[data.kind]
	if fn then
		local ok, err = pcall(fn, data)
		if not ok then
			warn("[권왕] 게임패스 권법 연출 오류:", data.style, data.kind, err)
		end
	end
end

return PassArts
