-- 권왕 3.43판: 게임패스 권법 둘의 화면 (모습 · 기술 연출 다시)
--   3.55판: 기술 새로. 구미호권 E 여우구슬 · R 호혼도약 (G 구미천화는 그대로), 흑염마검장 E 흑염발도 · R 쌍마비검 · G 마왕참 (X 흑염멸천은 그대로)
--   구미호권: 등 뒤의 복슬한 여우 꼬리 (길쭉한 타원을 촘촘히 겹쳐 매끈하게, 굵다가 끝이 뾰족한 흰 꼬리 끝에 여우불).
--            강화만큼 1 → 9개. +5 여우 귀 · +10 금빛 눈 · +15 거대한 꼬리 혼령. 기술은 여우불 · 환영 분신 · 꼬리 혼령
--   흑염마검장: 손에 빚은 마검. 자루 · 코등이 · 칼날 (흑요석 몸, 날, 홈의 문자) 을 갖춘 검이 정자세에서 손에서 가슴 앞으로 곧게 선다.
--            +5부터 두 손. 강화할수록 길고 화려해지고, +15에는 칼에서 오라가 솟는다. 기술은 검은 불꽃 검기 · 땅에서 솟는 마검 · 하늘의 검
-- 꾸밈은 모두 이 화면에서만 그린다 (서버는 Style · Enh 속성만 붙인다)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Fx = require(script.Parent:WaitForChild("Fx"))
local Perf = require(script.Parent:WaitForChild("Perf"))
local Anim = require(script.Parent:WaitForChild("Anim"))

local PassArts = {}

local FOX = Color3.fromRGB(80, 170, 255)
local FOX_DEEP = Color3.fromRGB(40, 110, 230)
local FOX_PALE = Color3.fromRGB(220, 242, 255)
local FUR = Color3.fromRGB(244, 246, 252)
local FUR_ROOT = Color3.fromRGB(206, 220, 246)
local GOLD = Color3.fromRGB(255, 214, 90)
local INK = Color3.fromRGB(18, 8, 26)
local OBSIDIAN = Color3.fromRGB(28, 20, 38)
local STEEL = Color3.fromRGB(54, 44, 66)
local PURPLE = Color3.fromRGB(196, 70, 255)
local VIOLET = Color3.fromRGB(130, 40, 220)
local CRIMSON = Color3.fromRGB(255, 40, 70)
local WHITE_HOT = Color3.fromRGB(255, 225, 235)
local TEX_FIRE = "rbxasset://textures/particles/fire_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local folder = Instance.new("Folder")
folder.Name = "KwonPassArts"
folder.Parent = workspace

local opts: any = {}
function PassArts.init(o: any)
	opts = o or {}
end
local function shake(a: number)
	if opts.shake then
		pcall(opts.shake, a)
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
-- 타원체 (공 모양 조각은 크기가 한 가지로 묶여 길쭉해지지 않는다: 네모 조각에 구 모양 덧씌우기)
local function oval(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?): BasePart
	local p = part(size, color, material, alpha, nil)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = p
	return p
end
local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function pulse(inst: Instance, time: number, goal: { [string]: any })
	local tw = TweenService:Create(inst, TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), goal)
	tw:Play()
	return tw
end
local function temp(p: BasePart, life: number): BasePart
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
	if o.shape then
		e.Shape = o.shape
	end
	e.Parent = parent
	return e
end
local function light(parent: Instance, color: Color3, range: number, brightness: number): PointLight
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Parent = parent
	return l
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
-- 흑염: 검 단계 (0 한 손 · 1 홈의 문자 · 2 두 손 · 3 불꽃 자취 · 코등이 날개 · 4 핏빛 날 · 5 칼의 오라)
function PassArts.bladeTier(lv: number): number
	local l = math.clamp(math.floor(lv), 0, 15)
	return l >= 15 and 5 or (l >= 10 and 4 or (l >= 8 and 3 or (l >= 5 and 2 or (l >= 3 and 1 or 0))))
end

------------------------------------------------------------------------
-- 몸에 붙는 꾸밈 (사람마다 하나)
------------------------------------------------------------------------
type Sword = { hand: BasePart, side: number, items: { { BasePart | CFrame } }, frame: CFrame? }
type Rig = { model: Model, style: string, lv: number, parts: { BasePart }, tails: { { BasePart } }?, ghost: { { BasePart } }?, swords: { Sword }?, extra: { Instance } }
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

-- 상점 미리보기는 같은 꾸밈을 미리보기 모형 안에 (용접 없이 그 자리에 고정해) 짓는다
local buildParent: Instance = folder
local previewMode = false
local function weldTo(base: BasePart, p: BasePart, offset: CFrame): BasePart
	p.CFrame = base.CFrame * offset
	if previewMode then
		p.Anchored = true
	else
		p.Anchored = false
		local w = Instance.new("WeldConstraint")
		w.Part0 = base
		w.Part1 = p
		w.Parent = p
	end
	p.Parent = buildParent
	return p
end

-- 구미호 꼬리 ---------------------------------------------------------
local function segCount(): number
	return Perf.low and 9 or 14
end
-- 꼬리 굵기: 뿌리는 가늘고, 가운데가 복슬하게 굵고, 끝은 뾰족하다
local function tailWidth(k: number): number
	local w = 0.26 + 1.0 * math.sin(math.pi * (0.06 + 0.88 * k))
	if k > 0.74 then
		w *= 1 - 0.62 * (k - 0.74) / 0.26
	end
	return w
end
local function buildTail(rig: Rig, scale: number, ghost: boolean): { BasePart }
	local segs = {}
	local n = segCount()
	for i = 1, n do
		local k = (i - 1) / (n - 1)
		local w = tailWidth(k) * scale
		local p: BasePart
		if ghost then
			p = oval(Vector3.new(w, w * 0.94, 1.7 * scale), FOX, Enum.Material.Neon, 0.86)
		elseif k >= 0.86 then
			-- 끝: 흰빛에서 푸른 여우불로
			p = oval(Vector3.new(w, w * 0.94, 1.5 * scale), FOX_PALE:Lerp(FOX, (k - 0.86) / 0.14), Enum.Material.Neon, 0)
		else
			local col = k < 0.3 and FUR_ROOT:Lerp(FUR, k / 0.3) or FUR
			p = oval(Vector3.new(w, w * 0.94, 1.5 * scale), col, Enum.Material.SmoothPlastic, 0)
		end
		p.Parent = buildParent
		table.insert(segs, p)
		table.insert(rig.parts, p)
		if not ghost and not previewMode then
			if i == n then
				emitter(p, TEX_FIRE, cs(FOX_PALE, FOX, FOX_DEEP), ns(1.1, 0.1), 10, 0.6, 1.5, { accel = Vector3.new(0, 4, 0) })
				light(p, FOX, 8, 1.2)
			elseif i == math.floor(n * 0.55) then
				-- 복슬한 털빛 (흐릿한 흰 안개)
				emitter(p, TEX_SMOKE, cs(FUR, FOX_PALE), ns(1.3 * scale, 1.8 * scale), 4, 0.9, 0.3, { alpha = ns(0.82, 1), accel = Vector3.zero, light = 0.3 })
			end
		end
	end
	return segs
end

local function buildFox(m: Model, lv: number): Rig
	local rig: Rig = { model = m, style = "gumiho", lv = lv, parts = {}, extra = {} }
	local n = PassArts.tails(lv)
	local tails = {}
	for _ = 1, n do
		table.insert(tails, buildTail(rig, 1, false))
	end
	rig.tails = tails
	local head = bodyPart(m, "Head")
	-- +5: 여우 귀 (흰 털에 속이 푸르다)
	if head and lv >= 5 then
		for sx = -1, 1, 2 do
			local tilt = CFrame.new(0.32 * sx, head.Size.Y / 2 + 0.12, 0.05) * CFrame.Angles(0, 0, math.rad(-14 * sx))
			local ear = oval(Vector3.new(0.34, 0.62, 0.16), FUR, Enum.Material.SmoothPlastic, 0)
			table.insert(rig.parts, weldTo(head, ear, tilt))
			local inner = oval(Vector3.new(0.18, 0.42, 0.1), FOX, Enum.Material.Neon, 0.1)
			table.insert(rig.parts, weldTo(head, inner, tilt * CFrame.new(0, -0.04, -0.05)))
		end
	end
	-- +10: 금빛 눈
	if head and lv >= 10 then
		for sx = -1, 1, 2 do
			local eye = part(Vector3.new(0.16, 0.07, 0.05), GOLD, Enum.Material.Neon, 0, nil)
			table.insert(rig.parts, weldTo(head, eye, CFrame.new(0.17 * sx, 0.12, -head.Size.Z / 2 - 0.01)))
		end
	end
	-- +15: 거대한 꼬리 혼령 셋 (흐릿하게 크게)
	if lv >= 15 then
		local ghost = {}
		for _ = 1, 3 do
			table.insert(ghost, buildTail(rig, 2.3, true))
		end
		rig.ghost = ghost
	end
	-- 몸에 감도는 여우불 (단계가 오를수록 짙게)
	local torso = bodyPart(m, "UpperTorso", "Torso")
	if torso and not previewMode then
		local a = Instance.new("Attachment")
		a.Parent = torso
		table.insert(rig.extra, a)
		emitter(a, TEX_FIRE, cs(FOX_PALE, FOX), ns(0.5, 0), 1 + lv * 0.5, 0.7, 1.2, { spread = Vector2.new(180, 180), accel = Vector3.new(0, 3, 0), alpha = ns(0.55, 1) })
	end
	return rig
end

-- 꼬리를 흔든다: 허리 뒤에서 부채꼴로 솟아 끝으로 갈수록 위로 감기고, 물결이 뿌리에서 끝으로 흐른다
local function poseTails(rig: Rig, t: number)
	local base = bodyPart(rig.model, "LowerTorso", "Torso")
	if not base then
		return
	end
	local cf = base.CFrame * CFrame.new(0, -0.15, base.Size.Z / 2 + 0.05)
	local function lay(list: { { BasePart } }, scale: number, spreadDeg: number, phase: number)
		local n = #list
		for ti, segs in ipairs(list) do
			local u = n > 1 and ((ti - 1) / (n - 1) - 0.5) or 0
			local roll = math.rad(u * spreadDeg)
			local cur = cf * CFrame.Angles(0, 0, roll) * CFrame.Angles(math.rad(-16), 0, 0)
			local m = #segs
			local step = (m > 10 and 0.4 or 0.6) * scale
			for i, p in ipairs(segs) do
				local k = (i - 1) / (m - 1)
				local wave = math.sin(t * 2.3 - i * 0.45 + ti * 1.3 + phase) * math.rad(4.5) * (0.3 + k)
				cur = cur * CFrame.Angles(math.rad(-4.6 - 3 * k) + wave * 0.4, wave, 0) * CFrame.new(0, 0, step)
				p.CFrame = cur
			end
		end
	end
	if rig.tails then
		lay(rig.tails, 1, math.min(140, 30 * #rig.tails), 0)
	end
	if rig.ghost then
		lay(rig.ghost, 2.3, 110, 1.7)
	end
end

-- 흑염 마검 ----------------------------------------------------------
-- 검의 틀: 손을 기준으로 칼날이 손의 -Z (주먹을 쥔 엄지 쪽) 로 뻗는다. 팔꿈치를 굽힌 정자세에서는 위로 곧게 서고,
-- 칼끝은 조금 몸 (가슴) 쪽으로 기운다. 휘두르면 손목을 따라 돈다
local function sword(rig: Rig, hand: BasePart, tier: number, side: number)
	local L = ({ [0] = 4.0, 4.3, 4.4, 4.6, 5.0, 5.3 })[tier] or 4.0
	local W = ({ [0] = 0.56, 0.58, 0.6, 0.63, 0.68, 0.72 })[tier] or 0.56
	local edgeCol = tier >= 4 and CRIMSON:Lerp(PURPLE, 0.3) or PURPLE
	-- 검은 '검의 틀' (자루 한가운데, 칼날이 -Z) 에 맞춰 놓고, 매 장면 poseSwords가 틀을 정한다
	local sw: Sword = { hand = hand, side = side, items = {} }
	rig.swords = rig.swords or {}
	table.insert(rig.swords :: { Sword }, sw)
	local function at(z: number): CFrame
		return CFrame.new(0, 0, z)
	end
	local function put(_base: BasePart, p: BasePart, off: CFrame): BasePart
		p.Anchored = true
		p.Parent = buildParent
		table.insert(sw.items, { p, off })
		return p
	end
	local base = -0.62 -- 칼날이 시작하는 자리 (코등이 바로 위)
	-- 자루 (손을 꿰뚫어 아래로 조금 나온다) · 자루 끝
	local grip = part(Vector3.new(1.15, 0.3, 0.3), Color3.fromRGB(22, 16, 28), Enum.Material.Fabric, 0, "cyl")
	table.insert(rig.parts, put(hand, grip, at(0.05) * CFrame.Angles(0, math.rad(90), 0)))
	for k = 0, 3 do
		local wrap = part(Vector3.new(0.06, 0.33, 0.33), STEEL, Enum.Material.Metal, 0, "cyl")
		table.insert(rig.parts, put(hand, wrap, at(-0.35 + k * 0.25) * CFrame.Angles(0, math.rad(90), 0)))
	end
	local pommel = oval(Vector3.new(0.34, 0.34, 0.3), STEEL, Enum.Material.Metal, 0)
	table.insert(rig.parts, put(hand, pommel, at(0.66)))
	local pgem = oval(Vector3.new(0.16, 0.16, 0.16), edgeCol, Enum.Material.Neon, 0)
	table.insert(rig.parts, put(hand, pgem, at(0.82)))
	-- 코등이: 가로대 · 양 끝의 빛 · 가운데 보석
	local guard = part(Vector3.new(0.26, 1.5, 0.24), STEEL, Enum.Material.Metal, 0, nil)
	table.insert(rig.parts, put(hand, guard, at(base + 0.12)))
	for sy = -1, 1, 2 do
		local tip = oval(Vector3.new(0.28, 0.34, 0.28), edgeCol, Enum.Material.Neon, 0.05)
		table.insert(rig.parts, put(hand, tip, at(base + 0.12) * CFrame.new(0, 0.78 * sy, 0)))
		if tier >= 3 then
			-- 코등이 날개: 칼날 쪽으로 휜 두 갈래
			local wing = part(Vector3.new(0.14, 0.2, 0.9), STEEL, Enum.Material.Metal, 0, "wedge")
			table.insert(rig.parts, put(hand, wing, at(base - 0.25) * CFrame.new(0, 0.62 * sy, 0) * CFrame.Angles(math.rad(sy > 0 and 25 or -25), 0, 0) * CFrame.Angles(0, 0, sy > 0 and 0 or math.pi)))
		end
	end
	local gem = oval(Vector3.new(0.34, 0.36, 0.36), edgeCol, Enum.Material.Neon, 0)
	table.insert(rig.parts, put(hand, gem, at(base + 0.12)))
	-- 칼날: 흑요석 몸 · 양날의 빛 · 가운데 홈
	local mid = base - L / 2
	local core = part(Vector3.new(0.11, W, L), OBSIDIAN, Enum.Material.Metal, 0, nil)
	core.Reflectance = 0.18
	table.insert(rig.parts, put(hand, core, at(mid)))
	for sy = -1, 1, 2 do
		local edge = part(Vector3.new(0.13, 0.07, L), edgeCol, Enum.Material.Neon, tier >= 1 and 0 or 0.2, nil)
		table.insert(rig.parts, put(hand, edge, at(mid) * CFrame.new(0, sy * (W / 2 - 0.02), 0)))
	end
	-- 홈: 낮은 단계는 희미한 줄, +3부터 빛나는 문자가 줄지어 박힌다
	if tier >= 1 then
		local runes = 6
		for r = 1, runes do
			local rz = base - 0.4 - (r - 1) * (L * 0.72) / (runes - 1)
			local rune = part(Vector3.new(0.13, 0.12, 0.22), tier >= 4 and CRIMSON or PURPLE, Enum.Material.Neon, 0, nil)
			table.insert(rig.parts, put(hand, rune, at(rz) * CFrame.Angles(math.rad(r % 2 == 0 and 45 or 0), 0, 0)))
		end
	else
		local fuller = part(Vector3.new(0.12, 0.08, L * 0.75), VIOLET, Enum.Material.Neon, 0.45, nil)
		table.insert(rig.parts, put(hand, fuller, at(base - L * 0.4)))
	end
	-- 칼끝: 마름모로 뾰족하게 (빛 테두리 한 겹)
	local tipZ = base - L
	local point = part(Vector3.new(0.11, W * 0.72, W * 0.72), OBSIDIAN, Enum.Material.Metal, 0, nil)
	point.Reflectance = 0.18
	table.insert(rig.parts, put(hand, point, at(tipZ) * CFrame.Angles(math.rad(45), 0, 0)))
	local pointGlow = part(Vector3.new(0.12, W * 0.8, W * 0.8), edgeCol, Enum.Material.Neon, 0.25, nil)
	table.insert(rig.parts, put(hand, pointGlow, at(tipZ + 0.03) * CFrame.Angles(math.rad(45), 0, 0)))
	-- +5 이상: 흰 불심 (칼날 한가운데로 가는 빛줄)
	if tier >= 4 then
		local heart = part(Vector3.new(0.13, 0.05, L * 0.85), WHITE_HOT, Enum.Material.Neon, 0.1, nil)
		table.insert(rig.parts, put(hand, heart, at(base - L * 0.45)))
	end
	-- +15: 칼에서 솟는 오라 (두 겹의 빛 칼날이 숨 쉬듯 일렁이고, 불꽃이 칼을 타고 솟는다)
	if tier >= 5 then
		local aura = oval(Vector3.new(0.45, W * 2.2, L * 1.22), PURPLE, Enum.Material.Neon, 0.74)
		table.insert(rig.parts, put(hand, aura, at(mid - 0.15)))
		pulse(aura, 0.9, { Transparency = 0.86 })
		local aura2 = oval(Vector3.new(0.6, W * 3.2, L * 1.36), CRIMSON, Enum.Material.Neon, 0.86)
		table.insert(rig.parts, put(hand, aura2, at(mid - 0.25)))
		pulse(aura2, 1.3, { Transparency = 0.94 })
		if not previewMode then
			light(core, PURPLE, 14, 2.2)
			emitter(core, TEX_FIRE, cs(CRIMSON, PURPLE, INK), ns(1.8, 0.2), 28, 0.7, 3, { accel = Vector3.new(0, 10, 0), shape = Enum.ParticleEmitterShape.Box })
			emitter(core, TEX_SPARK, cs(WHITE_HOT, PURPLE), ns(0.35, 0), 14, 1.1, 4, { spread = Vector2.new(180, 180), accel = Vector3.new(0, 6, 0) })
		end
	end
	-- 칼의 불꽃 (검은 연기 + 보랏빛 · 핏빛 불), 휘두르면 자취
	if not previewMode then
		emitter(core, TEX_SMOKE, cs(INK, Color3.fromRGB(50, 20, 60)), ns(0.8, 0.2), 8 + tier * 4, 0.55, 1.4, { accel = Vector3.new(0, 6, 0), light = 0, alpha = ns(0.35, 1), shape = Enum.ParticleEmitterShape.Box })
		emitter(core, TEX_FIRE, cs(tier >= 4 and CRIMSON or PURPLE, edgeCol, INK), ns(0.6, 0.05), 6 + tier * 4, 0.45, 2, { accel = Vector3.new(0, 7, 0), shape = Enum.ParticleEmitterShape.Box })
		if tier >= 3 then
			local a0 = Instance.new("Attachment")
			a0.Position = Vector3.new(0, 0, L / 2)
			a0.Parent = core
			local a1 = Instance.new("Attachment")
			a1.Position = Vector3.new(0, 0, -L / 2)
			a1.Parent = core
			local tr = Instance.new("Trail")
			tr.Attachment0 = a0
			tr.Attachment1 = a1
			tr.Color = cs(edgeCol, INK)
			tr.Transparency = ns(0.15, 1)
			tr.LightEmission = 1
			tr.Lifetime = 0.25
			tr.MinLength = 0.05
			tr.Parent = core
		end
	end
end

local function buildFlame(m: Model, lv: number): Rig
	local rig: Rig = { model = m, style = "heukyeom", lv = lv, parts = {}, extra = {} }
	local tier = PassArts.bladeTier(lv)
	local rh = bodyPart(m, "RightHand", "Right Arm")
	local lh = bodyPart(m, "LeftHand", "Left Arm")
	if rh then
		sword(rig, rh, tier, 1)
	end
	if lh and tier >= 2 then
		sword(rig, lh, tier, -1)
	end
	local torso = bodyPart(m, "UpperTorso", "Torso")
	if torso and tier >= 4 and not previewMode then
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

-- 검의 틀: 가만히 서 있을 때 (몸짓 · 기술이 없을 때) 는 쥔 손에서 칼이 위로 곧게 서고 칼끝이 조금 가슴 쪽으로 기운다.
-- 기술 · 연타 동작 중에는 손목을 따라 (주먹을 쥔 엄지 쪽, 손의 -Z) 휘두른다. 둘 사이는 부드럽게 옮겨 간다
local function poseSwords(rig: Rig, still: boolean?)
	local m = rig.model
	local torso = bodyPart(m, "UpperTorso", "Torso")
	if not torso or not rig.swords then
		return
	end
	local acting = (not still) and Anim.playing(m) ~= nil
	local look = torso.CFrame.LookVector
	for _, sw in ipairs(rig.swords) do
		local hp = sw.hand.CFrame.Position
		local target: CFrame
		if acting then
			target = sw.hand.CFrame * CFrame.Angles(math.rad(-20), 0, 0)
		else
			-- 위 (칼끝) 는 조금 몸 쪽으로, 칼의 넓은 면은 앞을 본다
			local f = (Vector3.yAxis * math.cos(math.rad(9)) - look * math.sin(math.rad(9))).Unit -- 칼끝 방향
			local right = torso.CFrame.RightVector
			local y = (right - f * right:Dot(f)).Unit -- 칼날의 너비는 좌우로 (넓은 면이 앞뒤를 본다: 앞에서 칼날 · 문자가 보인다)
			local z = -f -- 칼날이 -Z
			target = CFrame.fromMatrix(hp, y:Cross(z), y, z)
		end
		local cf = (sw.frame and not still) and (sw.frame :: CFrame):Lerp(target, acting and 0.6 or 0.25) or target
		cf = cf - cf.Position + hp
		sw.frame = cf
		for _, it in ipairs(sw.items) do
			local p = it[1] :: BasePart
			p.CFrame = cf * (it[2] :: CFrame)
		end
	end
end

-- 상점 미리보기: 모형 (상점의 ViewportFrame 안) 에 그 권법 · 강화 단계의 꾸밈을 입힌다. 꼬리는 한 장면으로 고정
function PassArts.preview(model: Model, style: string, lv: number)
	buildParent = model
	previewMode = true
	local ok, rig = pcall(style == "gumiho" and buildFox or buildFlame, model, lv)
	if ok and rig and rig.tails then
		pcall(poseTails, rig, 0.6)
	end
	if ok and rig and rig.swords then
		local ok2, err2 = pcall(poseSwords, rig, true)
		if not ok2 then
			warn("[권왕] 상점 미리보기 (검) 오류:", err2)
		end
	end
	previewMode = false
	buildParent = folder
	if not ok then
		warn("[권왕] 상점 미리보기 오류:", rig)
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
	-- 가까운 사람은 매 장면, 먼 사람은 여섯 장면에 한 번 (멀리 있어도 꼬리 · 검이 제자리에 남지 않게)
	local frame = 0
	RunService.RenderStepped:Connect(function()
		frame += 1
		local t = os.clock()
		for m, rig in pairs(rigs) do
			if m.Parent then
				local r = rootOf(m)
				if r and (frame % 6 == 0 or near(r.Position, Perf.low and 90 or 180)) then
					if rig.tails then
						poseTails(rig, t)
					end
					if rig.swords then
						poseSwords(rig)
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------------
-- 기술 연출: 공통
------------------------------------------------------------------------
local function flameBurst(at: Vector3, c1: Color3, c2: Color3, radius: number, dark: boolean?)
	local holder = temp(part(Vector3.one * 0.2, c1, Enum.Material.Neon, 1, nil), 1.6)
	holder.Position = at
	local e = emitter(holder, TEX_FIRE, cs(c1, c2), ns(radius * 0.5, 0.2), 0, 0.6, radius * 1.4, { spread = Vector2.new(180, 180), accel = Vector3.new(0, radius, 0) })
	e:Emit(Perf.low and 12 or 30)
	if dark then
		local s = emitter(holder, TEX_SMOKE, cs(INK, Color3.fromRGB(40, 14, 54)), ns(radius * 0.6, radius * 0.2), 0, 0.9, radius, { spread = Vector2.new(180, 180), accel = Vector3.new(0, radius * 0.6, 0), light = 0, alpha = ns(0.3, 1) })
		s:Emit(Perf.low and 8 or 18)
	end
	local fl = light(holder, c1, radius * 2.2, 3)
	tween(fl, 0.6, { Brightness = 0 })
	Fx.ring(at - Vector3.new(0, 2.4, 0), c1, 1, radius * 2, 0.45)
end
-- 빛 구슬 (가운데 흰빛 + 바깥 빛무리 + 불꽃 + 빛)
local function orb(at: Vector3, core: Color3, glow: Color3, size: number, life: number): BasePart
	local o = temp(part(Vector3.one * size, core, Enum.Material.Neon, 0, "ball"), life)
	o.Position = at
	local halo = part(Vector3.one * size * 2, glow, Enum.Material.Neon, 0.72, "ball")
	halo.Position = at
	halo.Parent = o
	local w = Instance.new("WeldConstraint")
	w.Part0 = o
	w.Part1 = halo
	w.Parent = halo
	emitter(o, TEX_FIRE, cs(core, glow), ns(size * 1.3, 0.1), 40, 0.35, 1, { accel = Vector3.new(0, 2, 0) })
	light(o, glow, size * 6, 2)
	return o
end
-- 곡선으로 날아가기
local function flyCurve(p: BasePart, from: Vector3, to: Vector3, lift: number, time: number, onArrive: (() -> ())?)
	local mid = (from + to) / 2 + Vector3.new(0, lift, 0)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local u = math.clamp((os.clock() - t0) / time, 0, 1)
		local pos = (1 - u) ^ 2 * from + 2 * (1 - u) * u * mid + u ^ 2 * to
		if p.Parent then
			p.Position = pos
		end
		if u >= 1 then
			conn:Disconnect()
			if onArrive then
				onArrive()
			end
		end
	end)
end
-- 커다란 꼬리 하나 (기술용): 뿌리에서 끝까지 타원을 이어 휘어진 꼬리를 그린다
local function bigTail(root: CFrame, len: number, width: number, bend: number, color: Color3, alpha: number, life: number): { BasePart }
	local segs = {}
	local n = Perf.low and 7 or 12
	local cur = root
	for i = 1, n do
		local k = (i - 1) / (n - 1)
		local w = tailWidth(k) * width
		cur = cur * CFrame.Angles(math.rad(-bend * (0.5 + k)), 0, 0) * CFrame.new(0, 0, len / n)
		local p = temp(oval(Vector3.new(w, w, len / n * 3.2), k > 0.85 and FOX_PALE or color, Enum.Material.Neon, alpha), life)
		p.CFrame = cur
		table.insert(segs, p)
	end
	return segs
end

------------------------------------------------------------------------
-- 구미호권 기술
------------------------------------------------------------------------
local H: { [string]: { [string]: (any) -> () } } = { gumiho = {}, heukyeom = {} }

-- E 호화연무: 하늘에서 여우불이 소용돌이치며 내려와 적마다 꽂힌다
H.gumiho.strike = function(d)
	local at = d.at
	if d.small then
		-- G의 여우불 유성
		local o = orb(at + Vector3.new(0, 26, 0), FOX_PALE, FOX, 1.8, 0.45)
		flyCurve(o, o.Position, at, 0, 0.22, function()
			flameBurst(at, FOX_PALE, FOX, d.radius or 6, false)
			o:Destroy()
		end)
		return
	end
	-- 여우불이 터지며 푸른 불기둥
	flameBurst(at, FOX_PALE, FOX, d.radius or 5, false)
	local col = temp(part(Vector3.new(1, 2, 2), FOX, Enum.Material.Neon, 0.2, "cyl"), 0.6)
	col.CFrame = CFrame.new(at - Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	tween(col, 0.25, { Size = Vector3.new(14, 3, 3), CFrame = CFrame.new(at + Vector3.new(0, 4.6, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
	task.delay(0.25, function()
		tween(col, 0.3, { Transparency = 1, Size = Vector3.new(16, 0.5, 0.5) })
	end)
	Fx.sound("ping", 0.45, 1.5, at)
end
H.gumiho.pulse = function(d)
	task.delay(d.delay or 0, function()
		flameBurst(d.at, FOX_PALE, FOX, d.radius or 8, false)
		Fx.sound("ping", 0.4, 1.7, d.at)
	end)
end
-- 3.55판 구미호권 새 기술 -------------------------------------------------
-- 땅과 나란한 방향 (길이가 0이면 앞)
local function flatOr(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 0.01 and f.Unit or Vector3.new(0, 0, -1)
end
-- 둥실 떠 있는 여우불 한 점 (흩어지는 작은 불씨)
local function wisp(at: Vector3, size: number, life: number, color: Color3?)
	local p = temp(oval(Vector3.one * size, color or FOX, Enum.Material.Neon, 0.15), life)
	p.Position = at
	tween(p, life, { Transparency = 1, Size = Vector3.one * size * 0.2, Position = at + Vector3.new(0, size * 1.5, 0) })
end
-- 여우불 꽃: 가운데 흰 불심에서 꽃잎 같은 푸른 불길 아홉이 피었다가 흩어진다
local function foxBloom(at: Vector3, radius: number)
	flameBurst(at, FOX_PALE, FOX, radius, false)
	local n = Perf.low and 6 or 9
	for k = 1, n do
		local a = k / n * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0.35, math.sin(a)).Unit
		local petal = temp(oval(Vector3.new(radius * 0.35, radius * 0.35, radius * 0.9), k % 3 == 0 and FOX_PALE or FOX, Enum.Material.Neon, 0.1), 0.6)
		petal.CFrame = CFrame.lookAt(at, at + dir) * CFrame.new(0, 0, -radius * 0.3)
		tween(petal, 0.5, { CFrame = CFrame.lookAt(at, at + dir) * CFrame.new(0, 0, -radius * 1.1), Transparency = 1, Size = Vector3.new(radius * 0.12, radius * 0.12, radius * 1.4) })
	end
	local core = temp(part(Vector3.one * radius * 0.6, WHITE_HOT, Enum.Material.Neon, 0, "ball"), 0.4)
	core.Position = at
	tween(core, 0.35, { Size = Vector3.one * radius * 1.6, Transparency = 1 })
	Fx.ring(at - Vector3.new(0, 2.4, 0), FOX_PALE, 1, radius * 2.6, 0.5)
	Fx.ring(at - Vector3.new(0, 2.2, 0), FOX, 2, radius * 1.8, 0.4)
end
-- E 여우구슬: 푸른 여우구슬 둘이 엇갈리는 활을 그리며 날아가 (꼬리처럼 불씨를 끌고), 앞에서 만나 여우불 꽃으로 터진다
H.gumiho.twinDiscs = function(d)
	local from, dir = d.from, d.dir
	if not from or not dir then
		return
	end
	dir = Vector3.new(dir.X, 0, dir.Z).Unit
	local right = Vector3.new(-dir.Z, 0, dir.X)
	local dist, swing, time = d.dist or 26, d.swing or 7, math.max(0.2, d.time or 0.55)
	local beads = {}
	for _, side in ipairs({ 1, -1 }) do
		local o = orb(from + Vector3.new(0, 1.2, 0), FOX_PALE, side == 1 and FOX or FOX_DEEP, 1.5, time + 0.15)
		table.insert(beads, { o, side })
	end
	local t0 = os.clock()
	local lastWisp = 0
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp(t / time, 0, 1)
		for _, b in ipairs(beads) do
			local o, side = b[1], b[2]
			if o.Parent then
				-- 위아래로도 살짝 물결친다 (여우가 뛰듯)
				local pos = from + dir * (dist * u) + right * (side * swing * math.sin(u * math.pi)) + Vector3.new(0, 1.2 + math.sin(u * math.pi * 3) * 0.8, 0)
				o.Position = pos
			end
		end
		if t - lastWisp > (Perf.low and 0.06 or 0.03) then
			lastWisp = t
			for _, b in ipairs(beads) do
				if b[1].Parent then
					wisp(b[1].Position, 0.9, 0.35, b[2] == 1 and FOX or FOX_DEEP)
				end
			end
		end
		if u >= 1 then
			conn:Disconnect()
			local at = from + dir * dist + Vector3.new(0, 1.2, 0)
			foxBloom(at, 7)
			Fx.sound("ping", 0.7, 1.2, at)
			shake(0.35)
		end
	end)
	Fx.sound("swing", 0.55, 1.7, from)
end
-- 여우 혼령 (기술용): 몸 · 가슴 · 머리 · 주둥이 · 귀 · 다리 넷 · 꼬리 셋. 틀 (cf) 의 -Z 가 앞
local function foxSpirit(scale: number, alpha: number, life: number): { { BasePart | CFrame } }
	local k = scale
	local items: { { BasePart | CFrame } } = {}
	local function add(size: Vector3, off: CFrame, color: Color3, a: number?)
		local p = temp(oval(size * k, color, Enum.Material.Neon, a or alpha), life)
		table.insert(items, { p, CFrame.new(off.Position * k) * off.Rotation })
	end
	add(Vector3.new(1.3, 1.2, 3), CFrame.new(0, 0, 0.2), FOX)
	add(Vector3.new(1.3, 1.4, 1.5), CFrame.new(0, 0.25, -1.1), FOX_PALE)
	add(Vector3.new(1.05, 0.95, 1.15), CFrame.new(0, 0.95, -2.0), FOX_PALE)
	add(Vector3.new(0.45, 0.4, 0.95), CFrame.new(0, 0.78, -2.7), FUR)
	for sx = -1, 1, 2 do
		add(Vector3.new(0.3, 0.85, 0.22), CFrame.new(sx * 0.33, 1.6, -1.9) * CFrame.Angles(0, 0, math.rad(-sx * 14)), FOX)
		add(Vector3.new(0.14, 0.12, 0.1), CFrame.new(sx * 0.25, 1.05, -2.55), WHITE_HOT, 0)
		add(Vector3.new(0.38, 1.3, 0.42), CFrame.new(sx * 0.45, -0.75, -1.0) * CFrame.Angles(math.rad(-20), 0, 0), FOX)
		add(Vector3.new(0.38, 1.3, 0.42), CFrame.new(sx * 0.45, -0.75, 1.1) * CFrame.Angles(math.rad(25), 0, 0), FOX)
	end
	-- 꼬리 셋: 짧은 간격으로 촘촘히 겹친 타원이 위로 휘어 오른다 (굵다가 끝이 흰빛으로 뾰족)
	local nT = Perf.low and 6 or 9
	for t = -1, 1 do
		local cur = CFrame.Angles(0, math.rad(t * 30), 0) * CFrame.new(0, 0.3, 1.5) * CFrame.Angles(math.rad(-30), 0, 0)
		for i = 1, nT do
			local kk = (i - 1) / (nT - 1)
			local w = tailWidth(kk) * 0.95
			cur = cur * CFrame.Angles(math.rad(-8), 0, 0) * CFrame.new(0, 0, 0.42)
			add(Vector3.new(w, w, 1.25), cur, kk > 0.8 and FOX_PALE or FOX)
		end
	end
	return items
end
local function placeItems(items: { { BasePart | CFrame } }, cf: CFrame)
	for _, it in ipairs(items) do
		local p = it[1] :: BasePart
		if p.Parent then
			p.CFrame = cf * (it[2] :: CFrame)
		end
	end
end
local function fadeItems(items: { { BasePart | CFrame } }, time: number)
	for _, it in ipairs(items) do
		tween(it[1] :: BasePart, time, { Transparency = 1 })
	end
end
-- 여우가 할퀸 자국 셋 (사선의 흰 줄)
local function clawMarks(at: Vector3, face: Vector3, size: number)
	for k = -1, 1 do
		local cl = temp(part(Vector3.new(0.2, size, 0.2), FOX_PALE, Enum.Material.Neon, 0, nil), 0.4)
		cl.CFrame = CFrame.lookAt(at, at + face) * CFrame.new(k * size * 0.16, 0, -1) * CFrame.Angles(0, 0, math.rad(38))
		tween(cl, 0.35, { Transparency = 1, Size = Vector3.new(0.05, size * 1.3, 0.05) })
	end
end
-- R 호혼도약: 몸이 푸른 여우 혼령이 되어 적에서 적으로 활을 그리며 뛰어 할퀴고, 마지막에 하늘에서 큰 여우가 내리 덮친다
H.gumiho.ricochet = function(d)
	local r = rootOf(d.m)
	local start = d.at or (r and r.Position)
	if not start then
		return
	end
	local seq = d.seq or {}
	local cut, every = d.cut or 0.2, d.every or 0.14
	local life = cut + #seq * every + (d.diveAt or 0.3) + 0.6
	local fox = foxSpirit(1, 0.35, life)
	placeItems(fox, CFrame.lookAt(start, start + (r and r.CFrame.LookVector or Vector3.zAxis)) * CFrame.new(0, -0.6, 0))
	foxBloom(start, 3)
	local prev = start
	for i, m in ipairs(seq) do
		task.delay(cut + (i - 1) * every, function()
			local tr = rootOf(m)
			if not tr then
				return
			end
			local to = tr.Position
			local a, b = prev, to
			prev = to
			local t0 = os.clock()
			local leap = math.max(0.06, every * 0.8)
			local conn
			conn = RunService.RenderStepped:Connect(function()
				local u = math.clamp((os.clock() - t0) / leap, 0, 1)
				local pos = a:Lerp(b, u) + Vector3.new(0, math.sin(u * math.pi) * 4, 0)
				placeItems(fox, CFrame.lookAt(pos, pos + flatOr(b - a)) * CFrame.Angles(math.rad(20 - 40 * u), 0, 0))
				wisp(pos, 0.7, 0.3)
				if u >= 1 then
					conn:Disconnect()
					clawMarks(b, flatOr(b - a), 3.4)
					flameBurst(b, FOX_PALE, FOX, 3.5, false)
					Fx.sound("swing", 0.45, 1.8, b)
				end
			end)
		end)
	end
	-- 마지막: 작은 여우는 하늘로, 큰 여우 혼령이 한가운데로 내리 덮친다
	task.delay(cut + #seq * every + (d.diveAt or 0.3) - 0.25, function()
		fadeItems(fox, 0.15)
		local cen = d.center or prev
		local big = foxSpirit(3.2, 0.3, 1.1)
		local top = cen + Vector3.new(0, 30, 0)
		local t0 = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local u = math.clamp((os.clock() - t0) / 0.25, 0, 1)
			local pos = top:Lerp(cen + Vector3.new(0, 1, 0), u * u)
			placeItems(big, CFrame.lookAt(pos, pos + Vector3.new(0, -1, 0.3)) )
			if u >= 1 then
				conn:Disconnect()
				foxBloom(cen, (d.radius or 12) * 0.7)
				Fx.ring(cen - Vector3.new(0, 2.4, 0), FOX_PALE, 3, (d.radius or 12) * 2.4, 0.6)
				fadeItems(big, 0.5)
				shake(0.7)
				Fx.sound("heavy", 0.6, 1.3, cen)
			end
		end)
	end)
end
-- G 구미천화: 땅에서 거대한 꼬리 혼령 아홉이 둘레로 솟아 일렁이고, 여우불 유성이 적에게 떨어지다가, 꼬리가 한가운데로 내리치며 푸른 불이 터진다
H.gumiho.stormcloud = function(d)
	local r = rootOf(d.m)
	if not r then
		return
	end
	local center = r.Position
	local dur = d.dur or 1.8
	local R = math.min(d.radius or 26, 22)
	local tails = {}
	for i = 1, 9 do
		local a = i / 9 * math.pi * 2
		local root = CFrame.new(center + Vector3.new(math.cos(a) * R * 0.7, -2.6, math.sin(a) * R * 0.7)) * CFrame.Angles(0, -a + math.pi / 2, 0) * CFrame.Angles(math.rad(-80), 0, 0)
		table.insert(tails, { root = root, segs = bigTail(root, 16, 2.4, 3, FOX, 0.35, dur + 0.7) })
	end
	local ring = temp(part(Vector3.new(0.4, R * 2, R * 2), FOX, Enum.Material.Neon, 0.6, "cyl"), dur + 0.7)
	ring.CFrame = CFrame.new(center - Vector3.new(0, 2.7, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	-- 꼬리가 일렁인다
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > dur + 0.6 then
			conn:Disconnect()
			return
		end
		for ti, tl in ipairs(tails) do
			local cur = tl.root
			local slam = math.clamp((t - dur) / 0.25, 0, 1) -- 마지막: 한가운데로 내리친다
			for i, p in ipairs(tl.segs) do
				local k = (i - 1) / (#tl.segs - 1)
				local wave = math.sin(t * 4 - i * 0.5 + ti) * math.rad(5)
				cur = cur * CFrame.Angles(math.rad(-3 * (0.5 + k)) - slam * math.rad(7), wave, 0) * CFrame.new(0, 0, 16 / #tl.segs)
				p.CFrame = cur
			end
		end
	end)
	if opts.tint then
		pcall(opts.tint, Color3.fromRGB(60, 120, 255), 0.25, dur)
	end
	shake(0.4)
	Fx.sound("whoosh", 0.7, 0.8, center)
end
H.gumiho.zone = H.gumiho.stormcloud
H.gumiho.strikeFinal = function(d)
	local at = d.at
	flameBurst(at, FOX_PALE, FOX, (d.radius or 20) * 0.6, false)
	Fx.ring(at - Vector3.new(0, 2.4, 0), FOX_PALE, 4, (d.radius or 20) * 2.4, 0.6)
	Fx.ring(at - Vector3.new(0, 2.2, 0), FOX, 2, (d.radius or 20) * 1.7, 0.45)
	if Fx.flash then
		Fx.flash(at, FOX, 70, 5, 0.5)
	end
	shake(1)
	Fx.sound("heavy", 0.9, 1.1, at)
end

------------------------------------------------------------------------
-- 흑염마검장 기술
------------------------------------------------------------------------
-- 검은 초승달 검기: 몸날 (검은) 위에 날 (보랏빛 · 핏빛) 이 겹친 큰 호가 앞으로 퍼진다
-- 기술용 마검 한 자루: 틀 (cf) 의 +Y 쪽으로 칼끝. 칼날 (흑요석 몸 · 양날의 빛 · 홈의 문자) · 마름모 칼끝 · 코등이 · 자루.
-- 틀을 옮기면 (moveSword) 모든 조각이 함께 간다
local function skillSword(cf: CFrame, L: number, W: number, life: number): { { BasePart | CFrame } }
	local items: { { BasePart | CFrame } } = {}
	local function add(p: BasePart, off: CFrame)
		temp(p, life)
		p.CFrame = cf * off
		table.insert(items, { p, off })
	end
	local core = part(Vector3.new(W, L, 0.3 * W), OBSIDIAN, Enum.Material.Metal, 0, nil)
	core.Reflectance = 0.2
	add(core, CFrame.new(0, L / 2, 0))
	for sx = -1, 1, 2 do
		add(part(Vector3.new(0.14 * W, L, 0.34 * W), PURPLE, Enum.Material.Neon, 0, nil), CFrame.new(sx * W / 2, L / 2, 0))
	end
	for r = 1, 5 do
		add(part(Vector3.new(0.2 * W, 0.34 * W, 0.34 * W), CRIMSON, Enum.Material.Neon, 0, nil), CFrame.new(0, L * (0.15 + r * 0.13), 0) * CFrame.Angles(0, 0, r % 2 == 0 and math.rad(45) or 0))
	end
	add(part(Vector3.new(W * 0.72, W * 0.72, 0.3 * W), OBSIDIAN, Enum.Material.Metal, 0, nil), CFrame.new(0, L, 0) * CFrame.Angles(0, 0, math.rad(45)))
	add(part(Vector3.new(W * 0.8, W * 0.8, 0.32 * W), PURPLE, Enum.Material.Neon, 0.3, nil), CFrame.new(0, L - 0.03, 0) * CFrame.Angles(0, 0, math.rad(45)))
	add(part(Vector3.new(W * 2.6, 0.4 * W, 0.5 * W), STEEL, Enum.Material.Metal, 0, nil), CFrame.new(0, -0.2 * W, 0))
	add(oval(Vector3.new(0.6 * W, 0.6 * W, 0.6 * W), PURPLE, Enum.Material.Neon, 0), CFrame.new(0, -0.2 * W, 0))
	add(part(Vector3.new(0.45 * W, 1.6 * W, 0.45 * W), Color3.fromRGB(22, 16, 28), Enum.Material.Fabric, 0, nil), CFrame.new(0, -1.1 * W, 0))
	add(oval(Vector3.new(0.6 * W, 0.6 * W, 0.6 * W), STEEL, Enum.Material.Metal, 0), CFrame.new(0, -2 * W, 0))
	emitter(core, TEX_FIRE, cs(PURPLE, CRIMSON, INK), ns(0.9 * W, 0.1), 30, 0.5, 3, { accel = Vector3.new(0, 10, 0), shape = Enum.ParticleEmitterShape.Box })
	return items
end
local function moveSword(items: { { BasePart | CFrame } }, cf: CFrame, time: number, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	for _, it in ipairs(items) do
		tween(it[1] :: BasePart, time, { CFrame = cf * (it[2] :: CFrame) }, style, dir)
	end
end
local function fadeSword(items: { { BasePart | CFrame } }, time: number)
	for _, it in ipairs(items) do
		tween(it[1] :: BasePart, time, { Transparency = 1 })
	end
end
-- 땅에서 솟는 마검 (R): 칼끝부터 땅을 뚫고 솟았다가 불꽃으로 흩어진다
local function risingSword(at: Vector3, scale: number, life: number)
	local L, W = 6.5 * scale, 1.1 * scale
	local ground = at - Vector3.new(0, 2.6, 0)
	local yaw = CFrame.Angles(0, math.random() * math.pi, 0)
	local items = skillSword(CFrame.new(ground - Vector3.new(0, L, 0)) * yaw, L, W, life)
	moveSword(items, CFrame.new(ground - Vector3.new(0, L * 0.12, 0)) * yaw * CFrame.Angles(math.rad(math.random(-8, 8)), 0, math.rad(math.random(-8, 8))), 0.16, Enum.EasingStyle.Back)
	task.delay(life * 0.55, function()
		fadeSword(items, life * 0.4)
	end)
end

-- 3.55판 흑염마검장 새 기술 -----------------------------------------------
-- 마검 조각들을 한꺼번에 놓기 (틀의 +Y 가 칼끝)
local function placeSword(items: { { BasePart | CFrame } }, cf: CFrame)
	for _, it in ipairs(items) do
		local p = it[1] :: BasePart
		if p.Parent then
			p.CFrame = cf * (it[2] :: CFrame)
		end
	end
end
-- 허공에 남는 베인 자국 하나: 검은 몸 · 핏빛 날 · 흰 불심의 얇은 판이 번쩍 그어졌다가 벌어지며 사라진다
local function slashMark(at: Vector3, face: Vector3, len: number, roll: number, life: number)
	local base = CFrame.lookAt(at, at + face) * CFrame.Angles(0, 0, roll)
	local layers = {
		{ Vector3.new(len, 0.55, 0.12), INK, 0 },
		{ Vector3.new(len * 1.04, 0.28, 0.14), CRIMSON:Lerp(PURPLE, 0.4), 0 },
		{ Vector3.new(len * 0.92, 0.09, 0.16), WHITE_HOT, 0 },
	}
	for _, L in ipairs(layers) do
		local p = temp(part(Vector3.new(0.1, L[1].Y, L[1].Z), L[2], Enum.Material.Neon, L[3], nil), life + 0.1)
		p.CFrame = base
		tween(p, 0.07, { Size = L[1] }, Enum.EasingStyle.Quart)
		task.delay(life * 0.45, function()
			tween(p, life * 0.55, { Size = Vector3.new(L[1].X * 1.15, L[1].Y * 2.6, L[1].Z), Transparency = 1 })
		end)
	end
end
-- E 흑염발도: 칼을 허리에 거두고 숨을 죽였다가, 눈에 보이지 않게 앞으로 지나간다. 지나간 길에 한 박자 늦게 베인 자국이 줄줄이 터진다
H.heukyeom.lightDash = function(d)
	local pts = d.pts
	if not pts or #pts < 2 then
		return
	end
	local r = rootOf(d.m)
	local a, b = pts[1], pts[#pts]
	local dir = flatOr(b - a)
	local T0 = (d.cut or 0) + (d.charge or 0.3)
	-- 발도 자세: 허리에서 보랏빛 칼집 틈이 가늘게 빛나며 불꽃이 빨려 든다
	if r then
		local slit = temp(part(Vector3.new(0.12, 0.12, 0.2), PURPLE, Enum.Material.Neon, 0, nil), T0 + 0.05)
		slit.CFrame = r.CFrame * CFrame.new(-0.9, -0.6, 0) * CFrame.Angles(0, math.rad(90), math.rad(15))
		tween(slit, T0, { Size = Vector3.new(0.18, 0.18, 4.2) })
		local holder = temp(part(Vector3.one * 0.2, INK, Enum.Material.Neon, 1, nil), T0 + 0.3)
		holder.Position = r.Position
		local e = emitter(holder, TEX_FIRE, cs(PURPLE, INK), ns(0.9, 0.1), 40, 0.4, -7, { spread = Vector2.new(180, 180), accel = Vector3.zero })
		task.delay(T0, function()
			e.Enabled = false
		end)
		Fx.ring(r.Position - Vector3.new(0, 2.5, 0), PURPLE, 8, 1, T0)
		Fx.sound("deflect", 0.6, 0.8, r.Position)
	end
	task.delay(T0, function()
		-- 번쩍: 길을 따라 아주 가는 흰 선 하나
		local len = (b - a).Magnitude
		local mid = (a + b) / 2 + Vector3.new(0, 0.6, 0)
		local line = temp(part(Vector3.new(0.12, 0.12, len), WHITE_HOT, Enum.Material.Neon, 0, nil), 0.5)
		line.CFrame = CFrame.lookAt(mid, mid + dir)
		tween(line, 0.4, { Transparency = 1, Size = Vector3.new(0.02, 0.02, len * 1.05) })
		local dark = temp(part(Vector3.new(0.6, 1.6, len), INK, Enum.Material.Neon, 0.35, nil), 0.35)
		dark.CFrame = line.CFrame
		tween(dark, 0.3, { Transparency = 1, Size = Vector3.new(0.1, 0.3, len) })
		Fx.sound("swing", 0.9, 0.7, a)
		if opts.tint then
			pcall(opts.tint, Color3.fromRGB(30, 10, 40), 0.18, 0.12)
		end
	end)
	-- 한 박자 늦게: 길 위에 엇갈린 베인 자국이 줄줄이 그어지고 검은 불꽃이 터진다
	local boomAt = T0 + (d.gap or 0.2) + (d.boomAt or 0.3) - 0.25
	local n = Perf.low and 4 or 7
	for i = 1, n do
		task.delay(boomAt + i * 0.035, function()
			local at = a:Lerp(b, i / (n + 1)) + Vector3.new(0, 0.8, 0)
			slashMark(at, Vector3.new(-dir.Z, 0, dir.X), 7, math.rad(i % 2 == 0 and 35 or -35), 0.45)
			flameBurst(at, PURPLE, INK, 3, true)
		end)
	end
	task.delay(boomAt + n * 0.035 + 0.05, function()
		flameBurst(b, CRIMSON, INK, d.boomRadius or 7, true)
		slashMark(b + Vector3.new(0, 1, 0), dir, 10, 0, 0.5)
		slashMark(b + Vector3.new(0, 1, 0), dir, 10, math.rad(90), 0.5)
		Fx.sound("heavy", 0.7, 0.8, b)
		shake(0.45)
	end)
end
-- R 쌍마비검: 손의 마검 둘을 던진다. 검은 납작하게 누워 빙글빙글 돌며 엇갈리는 활을 그리고 (보랏빛 자국을 남기며), 앞에서 십자로 부딪쳐 터진다
H.heukyeom.twinDiscs = function(d)
	local from, dir = d.from, d.dir
	if not from or not dir then
		return
	end
	dir = Vector3.new(dir.X, 0, dir.Z).Unit
	local right = Vector3.new(-dir.Z, 0, dir.X)
	local dist, swing, time = d.dist or 28, d.swing or 8, math.max(0.2, d.time or 0.6)
	local L, W = 5.5, 0.9
	local swords = {}
	for _, side in ipairs({ 1, -1 }) do
		table.insert(swords, { skillSword(CFrame.new(from), L, W, time + 0.1), side })
	end
	local t0 = os.clock()
	local lastTrail = 0
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp(t / time, 0, 1)
		for _, sw in ipairs(swords) do
			local side = sw[2]
			local pos = from + dir * (dist * u) + right * (side * swing * math.sin(u * math.pi)) + Vector3.new(0, 1, 0)
			-- 칼 가운데를 축으로 땅과 나란히 돈다
			local cf = CFrame.new(pos) * CFrame.Angles(0, side * t * 26, 0) * CFrame.Angles(math.pi / 2, 0, 0) * CFrame.new(0, -L * 0.4, 0)
			placeSword(sw[1], cf)
			if t - lastTrail > (Perf.low and 0.05 or 0.025) then
				local tr = temp(part(Vector3.new(L * 1.4, 0.12, 0.5), side == 1 and PURPLE or CRIMSON, Enum.Material.Neon, 0.25, nil), 0.3)
				tr.CFrame = CFrame.new(pos) * CFrame.Angles(0, side * t * 26, 0)
				tween(tr, 0.28, { Transparency = 1, Size = Vector3.new(L * 1.6, 0.05, 0.2) })
			end
		end
		if t - lastTrail > (Perf.low and 0.05 or 0.025) then
			lastTrail = t
		end
		if u >= 1 then
			conn:Disconnect()
			local at = from + dir * dist + Vector3.new(0, 1, 0)
			for _, sw in ipairs(swords) do
				fadeSword(sw[1], 0.1)
			end
			slashMark(at, dir, 12, math.rad(45), 0.55)
			slashMark(at, dir, 12, math.rad(-45), 0.55)
			flameBurst(at, PURPLE, INK, 9, true)
			Fx.ring(at - Vector3.new(0, 3.4, 0), CRIMSON, 2, 22, 0.45)
			Fx.sound("heavy", 0.7, 0.9, at)
			shake(0.45)
		end
	end)
	Fx.sound("swing", 0.7, 0.8, from)
end
-- G 마왕참: 등 뒤 하늘에 검은 불꽃이 모여 집채만 한 마검이 빚어지고, 그 검을 앞으로 내리찍는다. 땅이 한 줄로 갈라지며 검은 불길이 끝까지 솟는다
local giantOf: { [Instance]: any } = setmetatable({}, { __mode = "k" }) :: any
local GL, GW = 30, 5
local function giantCF(r: BasePart, dir: Vector3, theta: number): CFrame
	-- theta 0 = 칼끝이 하늘, π/2 = 칼끝이 앞 (조금 더 내려가면 땅에 닿는다)
	local hilt = r.Position + Vector3.new(0, 5, 0) - dir * 1.5
	local up = Vector3.yAxis
	local blade = (up * math.cos(theta) + dir * math.sin(theta)).Unit
	local side = dir:Cross(up).Unit
	return CFrame.fromMatrix(hilt, side, blade)
end
H.heukyeom.charge = function(d)
	local r = rootOf(d.m)
	if not r then
		return
	end
	local time = d.time or 1
	local dir = flatOr(r.CFrame.LookVector)
	local items = skillSword(giantCF(r, dir, -0.25), GL, GW, time + 1.6)
	-- 처음엔 보이지 않다가 불꽃이 모이며 드러난다
	for _, it in ipairs(items) do
		local p = it[1] :: BasePart
		local goal = p.Transparency
		p.Transparency = 1
		tween(p, time * 0.8, { Transparency = goal })
	end
	giantOf[d.m] = { items = items, dir = dir }
	-- 둘레에서 검으로 빨려 드는 검은 불꽃과 핏빛 불씨
	local holder = temp(part(Vector3.one * 0.2, INK, Enum.Material.Neon, 1, nil), time + 0.3)
	holder.Position = r.Position + Vector3.new(0, 5 + GL * 0.5, 0)
	local e = emitter(holder, TEX_FIRE, cs(PURPLE, CRIMSON, INK), ns(2.2, 0.2), 90, 0.6, -18, { spread = Vector2.new(180, 180), accel = Vector3.zero })
	local fl = light(holder, PURPLE, 6, 1)
	tween(fl, time, { Range = 40, Brightness = 5 })
	task.delay(time, function()
		e.Enabled = false
	end)
	Fx.ring(r.Position - Vector3.new(0, 2.5, 0), PURPLE, 22, 2, time)
	Fx.ring(r.Position - Vector3.new(0, 2.4, 0), CRIMSON, 16, 1, time * 0.9)
	if opts.tint then
		pcall(opts.tint, Color3.fromRGB(40, 12, 50), 0.25, time + 0.4)
	end
	Fx.sound("deflect", 0.8, 0.55, r.Position)
end
H.heukyeom.onepunch = function(d)
	local from, range = d.from, d.range or 54
	local r = rootOf(d.m)
	if not from or not r then
		return
	end
	local dir = flatOr(d.dir or r.CFrame.LookVector)
	local g = giantOf[d.m]
	local items = g and g.items or skillSword(giantCF(r, dir, -0.25), GL, GW, 1.6)
	giantOf[d.m] = nil
	-- 내리찍기: 0.16초 동안 칼끝이 하늘에서 앞의 땅으로
	local drop = math.atan2(7.5, GL) -- 칼끝이 땅에 닿는 기울기
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local u = math.clamp((os.clock() - t0) / 0.16, 0, 1)
		local theta = -0.25 + (math.pi / 2 + drop + 0.25) * (u * u)
		if r.Parent then
			placeSword(items, giantCF(r, dir, theta))
		end
		if u >= 1 then
			conn:Disconnect()
			task.delay(0.9, function()
				fadeSword(items, 0.5)
			end)
		end
	end)
	task.delay(0.16, function()
		local g0 = from - Vector3.new(0, 2.5, 0)
		-- 땅이 한 줄로 갈라진다 (핏빛 틈 · 검은 가장자리)
		local crack = temp(part(Vector3.new(1.6, 0.25, 0.2), CRIMSON, Enum.Material.Neon, 0, nil), 1.6)
		crack.CFrame = CFrame.lookAt(g0 + dir * 2, g0 + dir * 3)
		tween(crack, 0.25, { Size = Vector3.new(1.6, 0.25, range), CFrame = CFrame.lookAt(g0 + dir * (range / 2 + 2), g0 + dir * (range / 2 + 3)) }, Enum.EasingStyle.Quart)
		task.delay(0.9, function()
			tween(crack, 0.6, { Transparency = 1 })
		end)
		for sx = -1, 1, 2 do
			local edge = temp(part(Vector3.new(0.9, 0.3, range), INK, Enum.Material.Neon, 0.1, nil), 1.6)
			edge.CFrame = CFrame.lookAt(g0 + dir * (range / 2 + 2), g0 + dir * (range / 2 + 3)) * CFrame.new(sx * 1.2, 0.02, 0)
			tween(edge, 1.4, { Transparency = 1 })
		end
		-- 틈을 따라 검은 불길이 끝까지 차례로 솟는다
		local n = Perf.low and 6 or 11
		for i = 1, n do
			task.delay(i * 0.04, function()
				local at = from + dir * (range * i / n)
				flameBurst(at, i % 3 == 0 and CRIMSON or PURPLE, INK, 5 + i * 0.2, true)
				local col = temp(part(Vector3.new(1, 2.4, 2.4), INK, Enum.Material.Neon, 0.15, "cyl"), 0.7)
				col.CFrame = CFrame.new(at - Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, 0, math.pi / 2)
				tween(col, 0.2, { Size = Vector3.new(16, 3.4, 3.4), CFrame = CFrame.new(at + Vector3.new(0, 5.6, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
				task.delay(0.2, function()
					tween(col, 0.35, { Transparency = 1, Size = Vector3.new(18, 0.4, 0.4) })
				end)
			end)
		end
		Fx.ring(from - Vector3.new(0, 2.4, 0), CRIMSON, 4, 34, 0.6)
		shake(1.1)
		if Fx.flash then
			Fx.flash(from + dir * 20, CRIMSON, 80, 5, 0.45)
		end
		Fx.sound("heavy", 1, 0.45, from)
	end)
end
-- 흑염멸천: 하늘에 검은 불의 소용돌이가 열리고, 불꽃 검이 비처럼 쏟아지다가, 마지막에 거대한 마검이 한가운데로 내리꽂힌다
H.heukyeom.stormcloud = function(d)
	local r = rootOf(d.m)
	if not r then
		return
	end
	local dur, R = d.dur or 2.4, d.radius or 40
	local sky = temp(part(Vector3.new(1, R * 1.6, R * 1.6), INK, Enum.Material.Neon, 0.3, "cyl"), dur + 1.2)
	sky.CFrame = CFrame.new(r.Position + Vector3.new(0, 36, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	local ring = temp(part(Vector3.new(1.2, R * 1.7, R * 1.7), PURPLE, Enum.Material.Neon, 0.65, "cyl"), dur + 1.2)
	ring.CFrame = sky.CFrame
	local ring2 = temp(part(Vector3.new(1.3, R * 0.8, R * 0.8), CRIMSON, Enum.Material.Neon, 0.5, "cyl"), dur + 1.2)
	ring2.CFrame = sky.CFrame
	emitter(sky, TEX_SMOKE, cs(INK, Color3.fromRGB(50, 16, 60)), ns(8, 4), 20, 1.4, 2, { spread = Vector2.new(180, 180), light = 0, alpha = ns(0.3, 1) })
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > dur + 1 or not sky.Parent then
			conn:Disconnect()
			return
		end
		ring.CFrame = sky.CFrame * CFrame.Angles(t * 0.8, 0, 0)
		ring2.CFrame = sky.CFrame * CFrame.Angles(-t * 1.4, 0, 0)
	end)
	-- 마지막의 거대한 마검이 하늘에서 칼끝을 아래로 내리꽂힌다
	task.delay(math.max(0, dur - 0.45), function()
		local center = r.Position
		local flip = CFrame.Angles(math.pi, 0, 0) -- 칼끝 (+Y) 이 아래로
		local items = skillSword(CFrame.new(center + Vector3.new(0, 70, 0)) * flip, 24, 4.2, 1.6)
		moveSword(items, CFrame.new(center + Vector3.new(0, 19, 0)) * flip, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(1, function()
			fadeSword(items, 0.5)
		end)
	end)
	task.delay(dur, function()
		tween(sky, 0.8, { Transparency = 1 })
		tween(ring, 0.8, { Transparency = 1 })
		tween(ring2, 0.8, { Transparency = 1 })
	end)
	if opts.tint then
		pcall(opts.tint, Color3.fromRGB(60, 20, 70), 0.35, dur)
	end
	shake(0.5)
end
H.heukyeom.strike = function(d)
	local at = d.at
	if d.small then
		-- 하늘에서 떨어지는 불꽃 검 (자루 · 코등이 · 칼날)
		local top = CFrame.new(at + Vector3.new(math.random(-3, 3), 32, math.random(-3, 3))) * CFrame.Angles(math.rad(-90), 0, 0)
		local land = CFrame.new(at + Vector3.new(0, 1.5, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
		local blade = temp(part(Vector3.new(0.3, 0.9, 6), OBSIDIAN, Enum.Material.Metal, 0, nil), 0.7)
		local edge = temp(part(Vector3.new(0.34, 1.05, 6.1), PURPLE, Enum.Material.Neon, 0.35, nil), 0.7)
		local guard = temp(part(Vector3.new(0.4, 2.2, 0.35), STEEL, Enum.Material.Metal, 0, nil), 0.7)
		local parts = { { blade, CFrame.new() }, { edge, CFrame.new() }, { guard, CFrame.new(0, 0, 3.1) } }
		for _, pr in ipairs(parts) do
			pr[1].CFrame = top * pr[2]
			tween(pr[1], 0.17, { CFrame = land * pr[2] }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		task.delay(0.18, function()
			flameBurst(at, PURPLE, INK, d.radius or 8, true)
			for _, pr in ipairs(parts) do
				tween(pr[1], 0.4, { Transparency = 1 })
			end
		end)
	else
		-- 마지막: 마검이 꽂히며 둘레가 불탄다
		flameBurst(at, CRIMSON, INK, (d.radius or 30) * 0.5, true)
		Fx.ring(at - Vector3.new(0, 2.4, 0), PURPLE, 4, (d.radius or 30) * 2.2, 0.7)
		Fx.ring(at - Vector3.new(0, 2.2, 0), CRIMSON, 2, (d.radius or 30) * 1.6, 0.55)
		for k = 1, 8 do
			local a = k / 8 * math.pi * 2
			task.delay(0.05 * k, function()
				risingSword(at + Vector3.new(math.cos(a) * 12, 0, math.sin(a) * 12), 0.8, 0.7)
			end)
		end
		if Fx.flash then
			Fx.flash(at, CRIMSON, 80, 5, 0.5)
		end
		shake(1.2)
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
	if not h then
		return false
	end
	-- 구미호권 G의 마지막 (작은 유성이 아닌 큰 터짐) 은 따로
	if data.style == "gumiho" and data.kind == "strike" and not data.small and data.fx == "lightning" then
		return true
	end
	return h[data.kind] ~= nil
end
function PassArts.run(data: any)
	local h = H[data.style]
	local fn = h and h[data.kind]
	if data.style == "gumiho" and data.kind == "strike" and not data.small and data.fx == "lightning" then
		fn = H.gumiho.strikeFinal
	end
	if fn then
		local ok, err = pcall(fn, data)
		if not ok then
			warn("[권왕] 게임패스 권법 연출 오류:", data.style, data.kind, err)
		end
	end
end

return PassArts
