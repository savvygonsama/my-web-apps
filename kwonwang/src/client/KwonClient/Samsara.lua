-- 권왕 3.0판: 환생 권법 넷 (윤회권 · 업화권 · 무상권 · 권왕신권) 의 몸에 두르는 것과 기술 (화면)
-- 윤회권: 등 뒤의 금빛 윤회륜 · 업화권: 두 팔의 달군 사슬과 검은 불꽃 · 무상권: 몸 둘레의 넋불과 안개 띠
-- 권왕신권: 머리 위의 금빛 관 · 붉은 망토 · 금빛 팔찌
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Samsara = {}

local folder = Instance.new("Folder")
folder.Name = "KwonSamsara"
folder.Parent = workspace

local opts: any = {}
function Samsara.init(o: any)
	opts = o or {}
end

local GOLD = Color3.fromRGB(255, 214, 110)
local GOLD_DEEP = Color3.fromRGB(220, 160, 50)
local INDIGO = Color3.fromRGB(120, 90, 255)
local WHITE = Color3.new(1, 1, 1)
local EMBER = Color3.fromRGB(255, 70, 30)
local HELL = Color3.fromRGB(200, 25, 20)
local CHAR = Color3.fromRGB(28, 10, 14)
local MIST = Color3.fromRGB(225, 232, 242)
local GHOST = Color3.fromRGB(140, 230, 255)
local CRIMSON = Color3.fromRGB(190, 25, 40)
-- 여섯 갈래 세상의 빛깔
local REALMS = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 214, 90), Color3.fromRGB(255, 80, 80), Color3.fromRGB(110, 230, 140), Color3.fromRGB(110, 170, 255), Color3.fromRGB(200, 120, 255) }
local TEX_FIRE = "rbxasset://textures/particles/fire_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
end
local function ground(at: Vector3): Vector3
	return Vector3.new(at.X, at.Y - 2.7, at.Z)
end
local function part(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, shape: string?): BasePart
	local q = Instance.new("Part")
	if shape == "ball" then
		q.Shape = Enum.PartType.Ball
	elseif shape == "cyl" then
		q.Shape = Enum.PartType.Cylinder
	end
	q.Anchored = true
	q.CanCollide = false
	q.CanQuery = false
	q.CanTouch = false
	q.CastShadow = false
	q.Size = size
	q.Color = color
	q.Material = material or Enum.Material.SmoothPlastic
	q.Transparency = alpha or 0
	q.Parent = folder
	return q
end
local function fadeOut(p: BasePart, time: number, goal: { [string]: any }?)
	local g = goal or {}
	g.Transparency = 1
	tween(p, time, g)
	task.delay(time + 0.05, function()
		p:Destroy()
	end)
end
local function shakeNear(pos: Vector3, amount: number, range: number)
	if opts.shake and near(pos, range) then
		opts.shake(amount)
	end
end
-- 프레임마다 u (0 → 1)
local function anim(life: number, fn: (number) -> ())
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / life, 0, 1)
		fn(u)
		if u >= 1 then
			conn:Disconnect()
		end
	end)
end
local function rootOf(m: any): BasePart?
	local r = typeof(m) == "Instance" and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 1e-3 and f.Unit or Vector3.new(0, 0, -1)
end
local function emitter(at: BasePart, tex: string, c0: Color3, c1: Color3, rate: number, size: number, life: number, speed: number, light: number?): ParticleEmitter
	local a = Instance.new("Attachment")
	a.Parent = at
	local e = Instance.new("ParticleEmitter")
	e.Texture = tex
	e.Color = ColorSequence.new(c0, c1)
	e.LightEmission = light or 0.6
	e.Rate = rate
	e.Lifetime = NumberRange.new(life * 0.7, life)
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.SpreadAngle = Vector2.new(20, 20)
	e.Size = NumberSequence.new(size, 0)
	e.Transparency = NumberSequence.new(0.2, 1)
	e.Parent = a
	return e
end

-- 여러 조각을 한 덩이처럼 움직인다: { 조각, 덩이 안의 자리 }
type Group = { items: { { any } } }
local function group(): Group
	return { items = {} }
end
local function gadd(g: Group, p: BasePart, off: CFrame): BasePart
	table.insert(g.items, { p, off })
	return p
end
local function gset(g: Group, cf: CFrame)
	for _, it in ipairs(g.items) do
		local p = it[1] :: BasePart
		if p.Parent then
			p.CFrame = cf * (it[2] :: CFrame)
		end
	end
end
local function gfade(g: Group, time: number)
	for _, it in ipairs(g.items) do
		local p = it[1] :: BasePart
		if p.Parent then
			fadeOut(p, time)
		end
	end
end
local function galpha(g: Group, k: number)
	for _, it in ipairs(g.items) do
		local p = it[1] :: BasePart
		if p.Parent then
			p.Transparency = math.clamp(math.max(k, p:GetAttribute("A0") or 0), 0, 1)
		end
	end
end
local function gpart(g: Group, size: Vector3, color: Color3, mat: Enum.Material?, alpha: number?, shape: string?, off: CFrame): BasePart
	local p = part(size, color, mat, alpha, shape)
	p:SetAttribute("A0", alpha or 0)
	return gadd(g, p, off)
end

------------------------------------------------------------------------
-- 윤회륜: 금빛 테 두 겹, 바퀴살 여덟, 가운데 굴대, 테 위의 여섯 구슬 (덩이의 XY 면에 선다, 굴대는 Z)
------------------------------------------------------------------------
local function wheelGroup(R: number, thick: number, alpha: number?): Group
	local g = group()
	local a0 = alpha or 0
	local n = math.max(16, math.floor(R * 7))
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * math.pi * 2
		gpart(g, Vector3.new(2 * math.pi * R / n * 1.12, thick, thick * 0.9), GOLD, Enum.Material.Metal, a0, nil, CFrame.Angles(0, 0, a) * CFrame.new(0, R, 0))
		if i % 2 == 0 then
			gpart(g, Vector3.new(2 * math.pi * R * 0.7 / n * 2.2, thick * 0.4, thick * 0.4), INDIGO, Enum.Material.Neon, a0, nil, CFrame.Angles(0, 0, a) * CFrame.new(0, R * 0.7, 0))
		end
	end
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		gpart(g, Vector3.new(thick * 0.45, R * 0.95, thick * 0.45), GOLD_DEEP, Enum.Material.Metal, a0, nil, CFrame.Angles(0, 0, a) * CFrame.new(0, R * 0.5, 0))
	end
	gpart(g, Vector3.new(thick * 1.4, R * 0.32, R * 0.32), GOLD, Enum.Material.Metal, a0, "cyl", CFrame.Angles(0, math.rad(90), 0))
	gpart(g, Vector3.new(thick * 1.6, R * 0.16, R * 0.16), INDIGO, Enum.Material.Neon, a0, "cyl", CFrame.Angles(0, math.rad(90), 0))
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local d = thick * 2.1
		gpart(g, Vector3.new(d, d, d), REALMS[k + 1], Enum.Material.Neon, a0, "ball", CFrame.Angles(0, 0, a) * CFrame.new(0, R, 0))
	end
	return g
end
-- 테 위 k번째 구슬의 덩이 안 자리
local function orbOffset(R: number, k: number): Vector3
	local a = (k - 1) / 6 * math.pi * 2
	return (CFrame.Angles(0, 0, a) * CFrame.new(0, R, 0)).Position
end

------------------------------------------------------------------------
-- 몸에 두르는 것
------------------------------------------------------------------------
type Moving = { weld: Weld, base: CFrame, kind: string, phase: number, model: Model, k: number?, parts: { BasePart }?, tw: boolean? }
local moving: { Moving } = {}
local wheelOf: { [Model]: { BasePart } } = {}

local function attach(p: BasePart, to: BasePart, cf: CFrame, holder: Instance, list: { Instance }, model: Model?, kind: string?, phase: number?, k: number?)
	p.Anchored = false
	p.Massless = true
	if kind and model then
		p.CFrame = to.CFrame * cf
		local w = Instance.new("Weld")
		w.Part0 = to
		w.Part1 = p
		w.C0 = cf
		w.Parent = p
		table.insert(moving, { weld = w, base = cf, kind = kind, phase = phase or 0, model = model, k = k })
	else
		p.CFrame = to.CFrame * cf
		local w = Instance.new("WeldConstraint")
		w.Part0 = to
		w.Part1 = p
		w.Parent = p
	end
	p.Parent = holder
	table.insert(list, p)
end
-- 굴대 하나에 붙여 함께 도는 조각들 (굴대는 Weld 로 움직이고, 조각은 굴대에 고정)
local function hubbed(hub: BasePart, items: { { any } }, holder: Instance, list: { Instance })
	for _, it in ipairs(items) do
		local p = it[1] :: BasePart
		p.Anchored = false
		p.Massless = true
		p.CFrame = hub.CFrame * (it[2] :: CFrame)
		local w = Instance.new("WeldConstraint")
		w.Part0 = hub
		w.Part1 = p
		w.Parent = p
		p.Parent = holder
		table.insert(list, p)
	end
end

local function buildWheel(model: Model, holder: Instance, list: { Instance })
	local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
	if not (torso and torso:IsA("BasePart")) then
		return
	end
	local base = CFrame.new(0, 0.55, torso.Size.Z / 2 + 0.85)
	local hub = part(Vector3.new(0.2, 0.2, 0.2), GOLD, Enum.Material.Metal, 1)
	hub.CFrame = torso.CFrame * base
	attach(hub, torso, base, holder, list, model, "spin", 0)
	local g = wheelGroup(1.9, 0.2)
	hubbed(hub, g.items, holder, list)
	local parts: { BasePart } = {}
	for _, it in ipairs(g.items) do
		table.insert(parts, it[1])
	end
	wheelOf[model] = parts
	local glow = Instance.new("PointLight")
	glow.Color = GOLD
	glow.Range = 7
	glow.Brightness = 0.8
	glow.Parent = hub
end

local function buildChains(model: Model, holder: Instance, list: { Instance })
	for _, pair in ipairs({ { "RightLowerArm", "RightHand", 1 }, { "LeftLowerArm", "LeftHand", -1 } }) do
		local arm = model:FindFirstChild(pair[1])
		if arm and arm:IsA("BasePart") then
			-- 팔뚝을 휘감은 달군 사슬 고리
			for k = 0, 6 do
				local a = k * 1.15 * pair[3]
				local link = part(Vector3.new(0.4, 0.13, 0.24), Color3.fromRGB(45, 38, 38), Enum.Material.Metal)
				attach(link, arm, CFrame.new(math.cos(a) * 0.56, -0.5 + k * 0.17, math.sin(a) * 0.56) * CFrame.Angles(0, -a, math.rad(k % 2 == 0 and 65 or -65)), holder, list)
				if k % 2 == 1 then
					local glint = part(Vector3.new(0.2, 0.06, 0.12), EMBER, Enum.Material.Neon)
					attach(glint, arm, CFrame.new(math.cos(a) * 0.62, -0.5 + k * 0.17, math.sin(a) * 0.62) * CFrame.Angles(0, -a, 0), holder, list)
				end
			end
			-- 손목에서 늘어진 사슬 셋 (흔들린다)
			for k = 1, 3 do
				local link = part(Vector3.new(0.12, 0.34, 0.22), Color3.fromRGB(55, 45, 45), Enum.Material.Metal)
				attach(link, arm, CFrame.new(0.05 * pair[3], -0.65 - k * 0.3, 0.15) * CFrame.Angles(0, k % 2 == 0 and math.rad(90) or 0, 0), holder, list, model, "dangle", k * 0.7 * pair[3], k)
			end
		end
		local hand = model:FindFirstChild(pair[2])
		if hand and hand:IsA("BasePart") then
			local fire = emitter(hand, TEX_FIRE, Color3.fromRGB(255, 70, 30), Color3.fromRGB(30, 5, 10), 22, 0.9, 0.45, 3, 0.5)
			fire.Acceleration = Vector3.new(0, 6, 0)
			fire.Name = "KarmaFire"
			table.insert(list, fire.Parent :: Instance)
			local smoke = emitter(hand, TEX_SMOKE, Color3.fromRGB(40, 15, 20), Color3.fromRGB(10, 5, 8), 6, 1.0, 0.8, 1.5, 0)
			smoke.Acceleration = Vector3.new(0, 4, 0)
			table.insert(list, smoke.Parent :: Instance)
		end
	end
end

local function buildWisps(model: Model, holder: Instance, list: { Instance })
	local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
	if not (torso and torso:IsA("BasePart")) then
		return
	end
	-- 몸 둘레를 도는 넋불 셋
	for k = 1, 3 do
		local orb = part(Vector3.new(0.5, 0.5, 0.5), GHOST, Enum.Material.Neon, 0.1, "ball")
		attach(orb, torso, CFrame.new(2.2, 0, 0), holder, list, model, "orbit", (k - 1) / 3 * math.pi * 2)
		local tail = emitter(orb, TEX_SMOKE, GHOST, MIST, 14, 0.7, 0.6, 0.5, 0.6)
		tail.SpreadAngle = Vector2.new(5, 5)
		table.insert(list, tail.Parent :: Instance)
	end
	-- 목 뒤에서 길게 흘러내리는 안개 띠
	for k = 0, 6 do
		local seg = part(Vector3.new(0.55 - k * 0.03, 0.06, 0.62), MIST:Lerp(GHOST, k / 10), Enum.Material.SmoothPlastic, 0.15 + k * 0.08)
		local base = CFrame.new(0, 0.7 - k * 0.42, torso.Size.Z / 2 + 0.3 + k * 0.32) * CFrame.Angles(math.rad(55 - k * 4), 0, 0)
		attach(seg, torso, base, holder, list, model, "scarf", k * 0.7, k)
	end
end

local function buildCrown(model: Model, holder: Instance, list: { Instance })
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		-- 머리 위에 뜬 금빛 관: 둥근 테와 여섯 뿔, 뿔 끝의 붉은 구슬, 이마의 큰 보석
		local base = CFrame.new(0, head.Size.Y / 2 + 0.55, 0)
		local hub = part(Vector3.new(0.2, 0.2, 0.2), GOLD, Enum.Material.Metal, 1)
		hub.CFrame = head.CFrame * base
		attach(hub, head, base, holder, list, model, "bob", 0)
		local items = {}
		local n = 14
		local r = math.max(head.Size.X, head.Size.Z) * 0.5 + 0.12
		for i = 0, n - 1 do
			local a = (i + 0.5) / n * math.pi * 2
			table.insert(items, { part(Vector3.new(2 * math.pi * r / n * 1.15, 0.2, 0.1), GOLD, Enum.Material.Metal), CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -r) })
		end
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			local h = k == 0 and 0.75 or 0.5
			table.insert(items, { part(Vector3.new(0.16, h, 0.1), GOLD, Enum.Material.Metal), CFrame.Angles(0, a, 0) * CFrame.new(0, h / 2, -r) * CFrame.Angles(math.rad(-12), 0, 0) })
			table.insert(items, { part(Vector3.new(0.17, 0.17, 0.17), CRIMSON, Enum.Material.Neon, 0, "ball"), CFrame.Angles(0, a, 0) * CFrame.new(0, h + 0.05, -r - 0.08) })
		end
		table.insert(items, { part(Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(255, 60, 70), Enum.Material.Neon, 0, "ball"), CFrame.new(0, 0.05, -r - 0.05) })
		hubbed(hub, items, holder, list)
		local glow = Instance.new("PointLight")
		glow.Color = GOLD
		glow.Range = 6
		glow.Brightness = 0.7
		glow.Parent = hub
	end
	local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") then
		-- 붉은 망토: 어깨에서 세 줄, 다섯 단 (아래로 갈수록 크게 흔들린다). 맨 아래 단엔 금테
		for c = -1, 1 do
			for r = 0, 4 do
				local panel = part(Vector3.new(0.66, 0.64, 0.06), r == 4 and GOLD_DEEP or CRIMSON:Lerp(Color3.fromRGB(120, 10, 20), r * 0.08), r == 4 and Enum.Material.Metal or Enum.Material.Fabric)
				local base = CFrame.new(c * 0.64, 0.75 - r * 0.62, torso.Size.Z / 2 + 0.1 + r * 0.1) * CFrame.Angles(math.rad(8 + r * 3), 0, 0)
				attach(panel, torso, base, holder, list, model, "cape", c * 0.6, r)
			end
		end
	end
	-- 손목의 금빛 팔찌와 붉은 보석
	for _, name in ipairs({ "RightLowerArm", "LeftLowerArm" }) do
		local arm = model:FindFirstChild(name)
		if arm and arm:IsA("BasePart") then
			local cuff = part(Vector3.new(0.38, 0.66, 0.66), GOLD, Enum.Material.Metal, 0, "cyl")
			attach(cuff, arm, CFrame.new(0, -0.32, 0) * CFrame.Angles(0, 0, math.rad(90)), holder, list)
			local gem = part(Vector3.new(0.2, 0.2, 0.2), CRIMSON, Enum.Material.Neon, 0, "ball")
			attach(gem, arm, CFrame.new(0, -0.32, -0.34), holder, list)
		end
	end
end

-- 3.1판 극 일월신권: 어깨 뒤에 작은 해 (오른쪽) 와 초승달 (왼쪽). 황혼에는 머리 뒤로 모여 노을빛·보랏빛으로 물든다
local function buildSunMoon(model: Model, holder: Instance, list: { Instance })
	local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
	if not (torso and torso:IsA("BasePart")) then
		return
	end
	for _, side in ipairs({ 1, -1 }) do
		local base = CFrame.new(side * 1.5, 1.5, torso.Size.Z / 2 + 0.6)
		local hub = part(Vector3.new(0.2, 0.2, 0.2), WHITE, Enum.Material.Neon, 1)
		hub.CFrame = torso.CFrame * base
		attach(hub, torso, base, holder, list, model, side == 1 and "sunorb" or "moonorb", side)
		local items = {}
		local pieces: { BasePart } = {}
		if side == 1 then
			local core = part(Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(255, 245, 200), Enum.Material.Neon, 0, "ball")
			local body = part(Vector3.new(1.05, 1.05, 1.05), Color3.fromRGB(255, 170, 50), Enum.Material.Neon, 0.25, "ball")
			table.insert(items, { core, CFrame.new() })
			table.insert(items, { body, CFrame.new() })
			table.insert(pieces, body)
			for k = 0, 7 do
				local a = k / 8 * math.pi * 2
				local ray = part(Vector3.new(0.1, 0.5, 0.1), Color3.fromRGB(255, 200, 90), Enum.Material.Neon)
				table.insert(items, { ray, CFrame.Angles(0, 0, a) * CFrame.new(0, 0.78, 0) })
				table.insert(pieces, ray)
			end
		else
			for i = 0, 6 do
				local a = math.rad(-100 + 200 * i / 6)
				local w = 0.25 * math.sin((i + 0.5) / 7 * math.pi) + 0.08
				local seg = part(Vector3.new(w, 0.32, 0.12), Color3.fromRGB(205, 220, 255), Enum.Material.Neon)
				table.insert(items, { seg, CFrame.new(-math.cos(a) * 0.6, math.sin(a) * 0.6, 0) * CFrame.Angles(0, 0, a) })
				table.insert(pieces, seg)
			end
		end
		hubbed(hub, items, holder, list)
		local glow = Instance.new("PointLight")
		glow.Color = side == 1 and Color3.fromRGB(255, 170, 60) or Color3.fromRGB(190, 210, 255)
		glow.Range = 6
		glow.Brightness = 0.8
		glow.Parent = hub
		moving[#moving].parts = pieces
	end
end

function Samsara.hasGear(st: any): boolean
	return st ~= nil and (st.wheel or st.chains or st.wisps or st.crown or st.sunMoonOrbs) == true
end
function Samsara.buildGear(model: Model, st: any): { Instance }
	local out: { Instance } = {}
	local holder = Instance.new("Folder")
	holder.Name = "Samsara_" .. model.Name
	holder.Parent = folder
	table.insert(out, holder)
	if st.wheel then
		buildWheel(model, holder, out)
	elseif st.chains then
		buildChains(model, holder, out)
	elseif st.wisps then
		buildWisps(model, holder, out)
	elseif st.crown then
		buildCrown(model, holder, out)
	elseif st.sunMoonOrbs then
		buildSunMoon(model, holder, out)
	end
	return out
end
-- 던지는 동안 등의 바퀴를 감춘다
local function hideWheel(model: Model, sec: number)
	local parts = wheelOf[model]
	if not parts then
		return
	end
	for _, p in ipairs(parts) do
		if p.Parent then
			p.LocalTransparencyModifier = 1
		end
	end
	task.delay(sec, function()
		for _, p in ipairs(parts) do
			if p.Parent and model:GetAttribute("Vanish") ~= true then
				p.LocalTransparencyModifier = 0
			end
		end
	end)
end

RunService.Heartbeat:Connect(function()
	local t = os.clock()
	local cam = workspace.CurrentCamera
	for i = #moving, 1, -1 do
		local mv = moving[i]
		if not mv.weld.Parent or not mv.model.Parent then
			table.remove(moving, i)
		else
			local r = mv.weld.Part0
			if cam and r and (cam.CFrame.Position - r.Position).Magnitude < 160 then
				local ph, k = mv.phase, mv.k or 0
				if mv.kind == "spin" then
					mv.weld.C0 = mv.base * CFrame.Angles(0, 0, t * 1.3)
				elseif mv.kind == "orbit" then
					mv.weld.C0 = CFrame.Angles(0, t * 1.8 + ph, 0) * CFrame.new(2.2, math.sin(t * 2.4 + ph) * 0.7, 0)
				elseif mv.kind == "scarf" then
					mv.weld.C0 = mv.base * CFrame.new(math.sin(t * 3 + ph) * 0.12 * k, math.sin(t * 2.2 + ph) * 0.05 * k, 0) * CFrame.Angles(math.sin(t * 2.6 + ph) * 0.06, 0, math.sin(t * 3 + ph) * 0.08)
				elseif mv.kind == "cape" then
					mv.weld.C0 = mv.base * CFrame.Angles(math.sin(t * 2.2 + ph + k * 0.5) * 0.05 * k, 0, math.sin(t * 1.7 + ph) * 0.02 * k)
				elseif mv.kind == "bob" then
					mv.weld.C0 = mv.base * CFrame.new(0, math.sin(t * 2) * 0.08, 0) * CFrame.Angles(0, t * 0.6, 0)
				elseif mv.kind == "sunorb" or mv.kind == "moonorb" then
					local tw = mv.model:GetAttribute("Twilight") == true
					local side = mv.kind == "sunorb" and 1 or -1
					if tw then
						mv.weld.C0 = CFrame.new(side * 0.55, 2.4, 0.9) * CFrame.Angles(0, 0, t * 2.5 * side)
					else
						mv.weld.C0 = mv.base * CFrame.new(0, math.sin(t * 2 + ph) * 0.15, 0) * CFrame.Angles(0, 0, t * side)
					end
					if mv.tw ~= tw and mv.parts then
						mv.tw = tw
						for _, q in ipairs(mv.parts) do
							if q.Parent then
								q.Color = tw and (side == 1 and Color3.fromRGB(255, 120, 60) or Color3.fromRGB(165, 95, 235)) or (side == 1 and Color3.fromRGB(255, 170, 50) or Color3.fromRGB(205, 220, 255))
							end
						end
					end
				elseif mv.kind == "dangle" then
					mv.weld.C0 = mv.base * CFrame.Angles(math.sin(t * 4 + ph) * 0.25, 0, math.sin(t * 3 + ph) * 0.2)
				end
			end
		end
	end
	for m, ps in pairs(wheelOf) do
		if not m.Parent or not (ps[1] and ps[1].Parent) then
			wheelOf[m] = nil
		end
	end
end)

------------------------------------------------------------------------
-- 몸의 그림자 (지난 삶·허상·잔상): 몸 조각을 그대로 본뜬 빛 조각 덩이. 뿌리 자리를 기준으로 움직인다
------------------------------------------------------------------------
local function ghostOf(model: Model, color: Color3, alpha: number, mat: Enum.Material?): (Group, CFrame)
	local g = group()
	local r = rootOf(model)
	local rootCF = r and r.CFrame or CFrame.new()
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.9 then
			gpart(g, d.Size, color, mat or Enum.Material.Neon, alpha, d:IsA("Part") and d.Shape == Enum.PartType.Ball and "ball" or nil, rootCF:ToObjectSpace(d.CFrame))
		end
	end
	return g, rootCF
end

-- 바닥에 그어지는 얇은 빛 줄
local function streak(a: Vector3, b: Vector3, color: Color3, w: number, life: number, h: number?)
	local len = (b - a).Magnitude
	if len < 0.2 then
		return
	end
	local p = part(Vector3.new(w, h or 0.15, len), color, Enum.Material.Neon, 0.1)
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
	fadeOut(p, life, { Size = Vector3.new(w * 0.2, h or 0.15, len) })
end
-- 빛기둥 (하늘에서 땅까지)
local function pillar(at: Vector3, color: Color3, d: number, h: number, life: number)
	local p = part(Vector3.new(h, d, d), color, Enum.Material.Neon, 0.15, "cyl")
	p.CFrame = CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local core = part(Vector3.new(h, d * 0.4, d * 0.4), WHITE, Enum.Material.Neon, 0.05, "cyl")
	core.CFrame = p.CFrame
	fadeOut(p, life, { Size = Vector3.new(h, d * 1.8, d * 1.8) })
	fadeOut(core, life * 0.7, { Size = Vector3.new(h, 0.1, 0.1) })
end
-- 십자로 엇갈린 칼자국 (무상)
local function slashX(at: Vector3, color: Color3, size: number, life: number)
	for k = -1, 1, 2 do
		local p = part(Vector3.new(0.18, size, 0.6), color, Enum.Material.Neon, 0.05)
		p.CFrame = CFrame.new(at) * CFrame.Angles(math.random() * 0.5, math.random() * 6, math.rad(40 * k))
		fadeOut(p, life, { Size = Vector3.new(0.05, size * 1.4, 0.2) })
	end
end
-- 금빛 주먹 덩이: 팔뚝 (뒤로 길게) · 주먹 · 마디 넷 · 붉은 소매 띠. 덩이의 -Z 쪽이 앞
local function fistGroup(s: number, alpha: number?): Group
	local g = group()
	local a0 = alpha or 0
	gpart(g, Vector3.new(4.4, 4, 4.6) * s, GOLD, Enum.Material.Metal, a0, nil, CFrame.new())
	for k = 0, 3 do
		gpart(g, Vector3.new(1.15, 1.15, 1.15) * s, GOLD:Lerp(WHITE, 0.25), Enum.Material.Metal, a0, "ball", CFrame.new((-1.5 + k) * 1.05 * s, 1.3 * s, -2.2 * s))
	end
	gpart(g, Vector3.new(1.4, 1.6, 2.4) * s, GOLD_DEEP, Enum.Material.Metal, a0, nil, CFrame.new(-2.5 * s, 0.3 * s, -0.6 * s))
	gpart(g, Vector3.new(9, 3.2, 3.2) * s, GOLD_DEEP, Enum.Material.Metal, a0, "cyl", CFrame.new(0, 0, 6.5 * s) * CFrame.Angles(0, math.rad(90), 0))
	gpart(g, Vector3.new(1.2, 4, 4) * s, CRIMSON, Enum.Material.Fabric, a0, "cyl", CFrame.new(0, 0, 3 * s) * CFrame.Angles(0, math.rad(90), 0))
	gpart(g, Vector3.new(0.5, 4.3, 4.3) * s, GOLD, Enum.Material.Neon, a0, "cyl", CFrame.new(0, 0, 2.3 * s) * CFrame.Angles(0, math.rad(90), 0))
	return g
end
-- 아래를 내리찍는 주먹의 자리: 앞(-Z)이 땅, 위(Y)가 내 앞쪽
local function downCF(p: Vector3, f: Vector3): CFrame
	local fwd = flat(f)
	return CFrame.fromMatrix(p, fwd:Cross(Vector3.new(0, 1, 0)), fwd)
end
-- 땅에 부딪는 금빛 충격 (고리 둘, 불티, 흙)
local function goldImpact(at: Vector3, s: number)
	local g = ground(at)
	Fx.ring(g + Vector3.new(0, 0.3, 0), GOLD, 2, 22 * s, 0.5)
	Fx.ring(g + Vector3.new(0, 0.4, 0), CRIMSON, 1, 14 * s, 0.6)
	Fx.burst("spark", at, GOLD, math.floor(18 * s), 1.6 * s)
	Fx.debris(g, math.floor(6 * s), 30 * s)
	Fx.flash(at, GOLD, 30 * s, 4, 0.4)
	Fx.breakSound("rock", 0.8, 0.8, at)
	shakeNear(at, 0.5 * s, 90)
end

------------------------------------------------------------------------
-- 윤회권
------------------------------------------------------------------------
local H: { [string]: (any) -> () } = {}

-- 전생의 메아리 (연타 넷마다): 쪽빛 손바닥이 옆에서 날아와 같은 자리를 다시 치고, 금빛 바퀴 무늬가 번쩍인다
function H.echoPulse(d: any)
	local at: Vector3 = d.at
	if not near(at, 250) then
		return
	end
	local side = math.random() < 0.5 and 1 or -1
	local cam = workspace.CurrentCamera
	local right = cam and flat(cam.CFrame.RightVector) or Vector3.new(1, 0, 0)
	local from = at + right * side * 7 + Vector3.new(0, 2, 0)
	local palm = group()
	gpart(palm, Vector3.new(2.4, 2.8, 0.4), INDIGO, Enum.Material.Neon, 0.35, nil, CFrame.new())
	for k = 0, 3 do
		gpart(palm, Vector3.new(0.45, 1.5, 0.35), INDIGO:Lerp(WHITE, 0.2), Enum.Material.Neon, 0.35, nil, CFrame.new((-1.5 + k) * 0.6, 2.1, 0))
	end
	gpart(palm, Vector3.new(0.5, 1.2, 0.35), INDIGO, Enum.Material.Neon, 0.35, nil, CFrame.new(side * -1.5, 0.2, 0) * CFrame.Angles(0, 0, math.rad(side * 40)))
	local delay = d.delay or 0.4
	anim(delay, function(u)
		local p = from:Lerp(at, u * u)
		gset(palm, CFrame.lookAt(p, at + Vector3.new(0, 0, 0.01)) * CFrame.Angles(0, math.rad(90 * side), 0))
		if u >= 1 then
			gfade(palm, 0.25)
		end
	end)
	task.delay(delay, function()
		local w = wheelGroup(3.2, 0.18, 0.2)
		local cf = CFrame.lookAt(at, at + right)
		anim(0.45, function(u)
			gset(w, cf * CFrame.Angles(0, 0, -u * 4))
			galpha(w, u)
		end)
		task.delay(0.47, function()
			gfade(w, 0.05)
		end)
		Fx.ring(at, INDIGO, 1, 12, 0.35)
		Fx.burst("glitter", at, GOLD, 10, 1)
		Fx.sound("deflect", 0.6, 1.3, at)
	end)
end




------------------------------------------------------------------------
-- 업화권
------------------------------------------------------------------------
-- 검은 불기둥: 검붉은 겉불, 붉은 심, 위로 솟는 불티
local function hellPillar(at: Vector3, h: number, dd: number, life: number)
	local g = ground(at)
	local outer = part(Vector3.new(0.5, dd, dd), CHAR, Enum.Material.SmoothPlastic, 0.2, "cyl")
	outer.CFrame = CFrame.new(g) * CFrame.Angles(0, 0, math.rad(90))
	local core = part(Vector3.new(0.5, dd * 0.55, dd * 0.55), EMBER, Enum.Material.Neon, 0.05, "cyl")
	core.CFrame = outer.CFrame
	tween(outer, 0.14, { Size = Vector3.new(h, dd, dd), CFrame = CFrame.new(g + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	tween(core, 0.12, { Size = Vector3.new(h * 1.05, dd * 0.55, dd * 0.55), CFrame = CFrame.new(g + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(0.15, function()
		fadeOut(outer, life, { Size = Vector3.new(h * 1.2, dd * 1.6, dd * 1.6) })
		fadeOut(core, life * 0.8, { Size = Vector3.new(h * 1.2, 0.2, 0.2) })
	end)
	Fx.burst("ember", g + Vector3.new(0, h * 0.4, 0), EMBER, 6, 1.2)
end
-- 땅의 붉은 금 (갈라짐): 가운데에서 바깥으로 꺾이며 뻗는다
local function crack(at: Vector3, len: number, angle: number, life: number)
	local p = ground(at) + Vector3.new(0, 0.12, 0)
	local a = angle
	local seg = len / 4
	for _ = 1, 4 do
		a += (math.random() - 0.5) * 0.8
		local q = p + Vector3.new(math.cos(a), 0, math.sin(a)) * seg
		local s = part(Vector3.new(0.45, 0.1, seg + 0.2), EMBER, Enum.Material.Neon, 0.05)
		s.CFrame = CFrame.lookAt((p + q) / 2, q)
		fadeOut(s, life)
		p = q
	end
end

-- 업보 (연타 다섯마다): 상대 발밑에 붉은 낙인이 찍혔다가 검은 지옥불 기둥이 솟는다
function H.karmaPulse(d: any)
	local at: Vector3 = d.at
	if not near(at, 250) then
		return
	end
	local g = ground(at) + Vector3.new(0, 0.15, 0)
	local seal = part(Vector3.new(0.12, 1, 1), HELL, Enum.Material.Neon, 0.2, "cyl")
	seal.CFrame = CFrame.new(g) * CFrame.Angles(0, 0, math.rad(90))
	tween(seal, d.delay or 0.5, { Size = Vector3.new(0.12, 9, 9) })
	for k = 0, 4 do
		crack(at, 4, k / 5 * math.pi * 2, (d.delay or 0.5) + 0.4)
	end
	task.delay(d.delay or 0.5, function()
		seal:Destroy()
		hellPillar(at, 18, 5, 0.5)
		Fx.ring(g, EMBER, 1, 14, 0.4)
		Fx.breakSound("boom", 0.6, 1.1, at)
		shakeNear(at, 0.4, 80)
	end)
end



-- 지옥불 속의 거대한 손: 손바닥 (세워진 판) · 손가락 넷 (두 마디) · 엄지. 손가락은 +Z 쪽으로 말려 주먹이 된다
local function hellHand(s: number): (Group, { { any } })
	local g = group()
	gpart(g, Vector3.new(6, 7, 2) * s, CHAR, Enum.Material.SmoothPlastic, 0, nil, CFrame.new())
	gpart(g, Vector3.new(4, 5, 2.1) * s, EMBER, Enum.Material.Neon, 0.6, nil, CFrame.new(0, 0, 0.05 * s))
	gpart(g, Vector3.new(4.4, 6, 2.4) * s, CHAR, Enum.Material.SmoothPlastic, 0, "cyl", CFrame.new(0, -6 * s, 0) * CFrame.Angles(0, 0, math.rad(90)))
	local fingers = {}
	for k = 0, 3 do
		local x = (-2.25 + k * 1.5) * s
		local L1 = (k == 1 or k == 2) and 3.6 * s or 3 * s
		local p1 = part(Vector3.new(1.3, L1, 1.4) * Vector3.new(s, 1, s), CHAR, Enum.Material.SmoothPlastic)
		local p2 = part(Vector3.new(1.2, L1 * 0.8, 1.3) * Vector3.new(s, 1, s), CHAR, Enum.Material.SmoothPlastic)
		local tip = part(Vector3.new(0.6, 0.6, 0.6) * s, EMBER, Enum.Material.Neon, 0, "ball")
		table.insert(fingers, { p1, p2, tip, x, L1 })
	end
	local thumb = part(Vector3.new(1.4, 3.2, 1.4) * s, CHAR, Enum.Material.SmoothPlastic)
	table.insert(fingers, { thumb, nil, nil, -3.6 * s, 3.2 * s, true })
	return g, fingers
end
local function setHand(g: Group, fingers: { { any } }, cf: CFrame, curl: number, s: number)
	gset(g, cf)
	for _, fg in ipairs(fingers) do
		local x, L1 = fg[4] :: number, fg[5] :: number
		if fg[6] then
			local base = cf * CFrame.new(x, -0.5 * s, 0.6 * s) * CFrame.Angles(0, 0, math.rad(40)) * CFrame.Angles(-curl * 0.9, 0, 0)
			;(fg[1] :: BasePart).CFrame = base * CFrame.new(0, L1 / 2, 0)
		else
			local b1 = cf * CFrame.new(x, 3.5 * s, 0) * CFrame.Angles(curl, 0, 0)
			;(fg[1] :: BasePart).CFrame = b1 * CFrame.new(0, L1 / 2, 0)
			local b2 = b1 * CFrame.new(0, L1, 0) * CFrame.Angles(curl * 0.9, 0, 0)
			;(fg[2] :: BasePart).CFrame = b2 * CFrame.new(0, L1 * 0.4, 0)
			;(fg[3] :: BasePart).CFrame = b2 * CFrame.new(0, L1 * 0.8, 0)
		end
	end
end


------------------------------------------------------------------------
-- 무상권
------------------------------------------------------------------------
local function mistPuff(at: Vector3, size: number, life: number)
	for k = 0, 3 do
		local p = part(Vector3.new(size, size * 0.7, size) * (0.6 + k * 0.15), MIST:Lerp(GHOST, k * 0.15), Enum.Material.SmoothPlastic, 0.45 + k * 0.1, "ball")
		p.Position = at + Vector3.new(math.random() - 0.5, math.random() * 0.6, math.random() - 0.5) * size * 0.5
		fadeOut(p, life * (0.7 + k * 0.15), { Size = p.Size * 1.8, Position = p.Position + Vector3.new(0, size * 0.3, 0) })
	end
end

-- 무상영 (연타 넷마다): 상대 뒤에 흐릿한 잔상이 나타나 엇갈려 벤다
function H.phantomPulse(d: any)
	local at: Vector3 = d.at
	if not near(at, 250) then
		return
	end
	local cam = workspace.CurrentCamera
	local back = cam and flat(at - cam.CFrame.Position) or Vector3.new(0, 0, -1)
	local behind = at + back * 2.5
	mistPuff(behind, 3, 0.5)
	task.delay(d.delay or 0.3, function()
		slashX(at, GHOST, 7, 0.3)
		mistPuff(at, 2.5, 0.4)
		Fx.ring(at, GHOST, 1, 10, 0.3)
		Fx.sound("swing", 0.6, 1.4, at)
	end)
end




------------------------------------------------------------------------
-- 권왕신권
------------------------------------------------------------------------
-- 왕의 주먹 (연타 넷마다): 하늘에서 금빛 주먹이 내리찍는다
function H.kingPulse(d: any)
	local at: Vector3 = d.at
	if not near(at, 250) then
		return
	end
	local g = fistGroup(0.55, 0.05)
	local top = at + Vector3.new(0, 26, 0)
	local delay = d.delay or 0.45
	local mark = part(Vector3.new(0.1, 1, 1), GOLD, Enum.Material.Neon, 0.4, "cyl")
	mark.CFrame = CFrame.new(ground(at) + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(mark, delay, { Size = Vector3.new(0.1, 7, 7) })
	anim(delay, function(u)
		local p = top:Lerp(at + Vector3.new(0, 2, 0), u * u)
		gset(g, downCF(p, Vector3.new(0, 0, 1)))
		if u >= 1 then
			gfade(g, 0.3)
			mark:Destroy()
			goldImpact(at, 0.6)
		end
	end)
end



-- 거대한 금빛 왕: 관 · 머리 · 가슴 · 어깨 · 두 팔 (위팔·아래팔·주먹) · 붉은 망토. 덩이의 -Z 쪽이 앞
type King = { g: Group, fists: { BasePart } }
local function kingGroup(s: number): King
	local g = group()
	gpart(g, Vector3.new(12, 6, 6) * s, GOLD, Enum.Material.Metal, 0, nil, CFrame.new(0, 10 * s, 0))
	gpart(g, Vector3.new(9, 8, 5) * s, GOLD_DEEP, Enum.Material.Metal, 0, nil, CFrame.new(0, 3.5 * s, 0))
	gpart(g, Vector3.new(4, 4, 0.6) * s, CRIMSON, Enum.Material.Neon, 0.2, nil, CFrame.new(0, 9 * s, -3.1 * s) * CFrame.Angles(0, 0, math.rad(45)))
	gpart(g, Vector3.new(5, 5, 5) * s, GOLD, Enum.Material.Metal, 0, "ball", CFrame.new(0, 16 * s, 0))
	for _, x in ipairs({ -1, 1 }) do
		gpart(g, Vector3.new(0.9, 0.5, 0.3) * s, WHITE, Enum.Material.Neon, 0, nil, CFrame.new(x * 1.1 * s, 16.4 * s, -2.4 * s))
	end
	-- 관
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		gpart(g, Vector3.new(1.9, 1.2, 0.4) * s, GOLD, Enum.Material.Metal, 0, nil, CFrame.new(0, 18.8 * s, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -2.6 * s))
		if k % 2 == 0 then
			gpart(g, Vector3.new(0.5, 2.2, 0.4) * s, GOLD, Enum.Material.Metal, 0, nil, CFrame.new(0, 20.3 * s, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -2.6 * s))
			gpart(g, Vector3.new(0.7, 0.7, 0.7) * s, CRIMSON, Enum.Material.Neon, 0, "ball", CFrame.new(0, 21.6 * s, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -2.6 * s))
		end
	end
	-- 어깨와 팔 (주먹은 따로 기억해 둔다: 내리찍을 때 감춘다)
	local fists = {}
	for _, x in ipairs({ -1, 1 }) do
		gpart(g, Vector3.new(5.5, 5.5, 5.5) * s, GOLD, Enum.Material.Metal, 0, "ball", CFrame.new(x * 7.5 * s, 12 * s, 0))
		gpart(g, Vector3.new(3.6, 8, 3.6) * s, GOLD_DEEP, Enum.Material.Metal, 0, nil, CFrame.new(x * 8.6 * s, 7.5 * s, -0.5 * s) * CFrame.Angles(math.rad(-15), 0, math.rad(x * 10)))
		gpart(g, Vector3.new(3.2, 7, 3.2) * s, GOLD, Enum.Material.Metal, 0, nil, CFrame.new(x * 9 * s, 2.5 * s, -3 * s) * CFrame.Angles(math.rad(-55), 0, 0))
		table.insert(fists, gpart(g, Vector3.new(4.6, 4.6, 4.6) * s, GOLD, Enum.Material.Metal, 0, nil, CFrame.new(x * 9 * s, 0.5 * s, -6 * s)))
	end
	-- 망토
	gpart(g, Vector3.new(14, 18, 0.6) * s, CRIMSON, Enum.Material.Fabric, 0, nil, CFrame.new(0, 4 * s, 3.4 * s) * CFrame.Angles(math.rad(10), 0, 0))
	gpart(g, Vector3.new(14.4, 1, 0.7) * s, GOLD, Enum.Material.Metal, 0, nil, CFrame.new(0, -4.8 * s, 5 * s) * CFrame.Angles(math.rad(10), 0, 0))
	return { g = g, fists = fists }
end


------------------------------------------------------------------------
-- 3.2판 환생 권법의 새 기술과 초 오의: 공통 조각
------------------------------------------------------------------------
local UP = Vector3.new(0, 1, 0)
local FLAT = CFrame.Angles(math.rad(90), 0, 0)
local SAPPHIRE = Color3.fromRGB(80, 160, 255)
local function v3(s: number): Vector3
	return Vector3.new(s, s, s)
end
local function rightOf(v: Vector3): Vector3
	return Vector3.new(-v.Z, 0, v.X)
end
local function safeLook(a: Vector3, b: Vector3): CFrame
	if (b - a).Magnitude < 1e-3 then
		return CFrame.new(a)
	end
	return CFrame.lookAt(a, b)
end
local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "KwonRebirthGrade"
grade.Parent = game:GetService("Lighting")
-- 내 화면의 빛깔을 time 동안 옮긴다 (나중 부름이 앞의 것을 덮는다)
local function gradeTo(time: number, sat: number, bright: number, contrast: number, tintC: Color3?)
	tween(grade, time, { Saturation = sat, Brightness = bright, Contrast = contrast, TintColor = tintC or WHITE })
end
local function gradeReset(time: number)
	gradeTo(time, 0, 0, 0, WHITE)
end
-- a에서 b로 뻗는 빛줄기 (원기둥, 길이는 X)
local function setBeam(p: BasePart, a: Vector3, b: Vector3, w: number)
	local len = math.max(0.2, (b - a).Magnitude)
	p.Size = Vector3.new(len, w, w)
	p.CFrame = safeLook((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
end
local function beamTo(a: Vector3, b: Vector3, w: number, color: Color3, alpha: number?, mat: Enum.Material?): BasePart
	local p = part(Vector3.new(1, w, w), color, mat or Enum.Material.Neon, alpha, "cyl")
	setBeam(p, a, b, w)
	return p
end
-- 덩이의 XY 면에 놓인 고리
local function gHalo(g: Group, R: number, thick: number, color: Color3, n: number, alpha: number?)
	local seg = 2 * math.pi * R / n * 1.1
	for k = 0, n - 1 do
		local a = (k + 0.5) / n * math.pi * 2
		gpart(g, Vector3.new(seg, thick, thick * 0.6), color, Enum.Material.Neon, alpha, nil, CFrame.Angles(0, 0, a) * CFrame.new(0, R, 0))
	end
end
local function trailDot(p: Vector3, d: number, color: Color3, life: number)
	local b = part(v3(d), color, Enum.Material.Neon, 0.3, "ball")
	b.Position = p
	fadeOut(b, life, { Size = v3(d * 0.2) })
end
local function recolor(g: Group, color: Color3, mat: Enum.Material?)
	for _, it in ipairs(g.items) do
		local p = it[1] :: BasePart
		p.Color = color
		if mat then
			p.Material = mat
		end
	end
end
local function camFace(from: Vector3, fallback: Vector3): Vector3
	local cam = workspace.CurrentCamera
	if cam then
		local v = cam.CFrame.Position - from
		if v.Magnitude > 1e-3 then
			return v.Unit
		end
	end
	return fallback
end
-- 몸을 s배로 본뜬 큰 그림자 (뿌리 자리 기준)
local function bigGhost(model: Model, s: number, color: Color3, alpha: number): Group
	local g = group()
	local r = rootOf(model)
	local rootCF = r and r.CFrame or CFrame.new()
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.9 then
			local off = rootCF:ToObjectSpace(d.CFrame)
			gpart(g, d.Size * s, color, Enum.Material.Neon, alpha, d:IsA("Part") and d.Shape == Enum.PartType.Ball and "ball" or nil, CFrame.new(off.Position * s) * off.Rotation)
		end
	end
	return g
end
-- 달군 사슬: 고리 n개 (엇갈려 놓인다). k (0~1) 만큼만 뻗어 보인다
local function chainParts(n: number): { BasePart }
	local list = {}
	for i = 1, n do
		list[i] = part(Vector3.new(0.5, 0.2, 1.1), i % 2 == 0 and Color3.fromRGB(130, 32, 22) or HELL, i % 2 == 0 and Enum.Material.Metal or Enum.Material.Neon, 0)
	end
	return list
end
local function setChain(list: { BasePart }, a: Vector3, b: Vector3, sag: number, k: number)
	local n = #list
	local dir = b - a
	for i, p in ipairs(list) do
		local u = (i - 0.5) / n
		p.Transparency = u > k and 1 or 0
		local pos = a + dir * u - UP * math.sin(u * math.pi) * sag
		p.CFrame = safeLook(pos, pos + dir) * CFrame.Angles(0, 0, (i % 2) * math.pi / 2)
	end
end
local function killList(list: { BasePart }, time: number)
	for _, p in ipairs(list) do
		if p.Parent then
			fadeOut(p, time)
		end
	end
end
-- 넋의 손아귀: 땅에서 솟아 발목을 감싸 쥐는 손가락 다섯 (원점이 땅)
local function ghostHand(): Group
	local g = group()
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		gpart(g, Vector3.new(0.7, 5, 0.7), GHOST, Enum.Material.Neon, 0.35, nil, CFrame.Angles(0, a, 0) * CFrame.new(0, 2.3, -2.4) * CFrame.Angles(math.rad(22), 0, 0))
		gpart(g, v3(0.6), WHITE, Enum.Material.Neon, 0.2, "ball", CFrame.Angles(0, a, 0) * CFrame.new(0, 4.6, -1.5))
	end
	gpart(g, Vector3.new(0.3, 5.6, 5.6), MIST, Enum.Material.SmoothPlastic, 0.6, "cyl", CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)))
	return g
end
-- 금빛 왕관: 띠 (붉은 보석 줄) 와 가시 n개 (꼭대기 마름모, 가운데 보석). 반지름을 바꿔 가며 놓을 수 있다
type CrownItem = { p: BasePart, a: number, y: number, dz: number, ex: CFrame }
local function crownNew(R0: number, n: number, hgt: number): { CrownItem }
	local items: { CrownItem } = {}
	local function add(size: Vector3, color: Color3, mat: Enum.Material, shape: string?, a: number, y: number, dz: number, ex: CFrame?)
		table.insert(items, { p = part(size, color, mat, 0, shape), a = a, y = y, dz = dz, ex = ex or CFrame.new() })
	end
	local segs = math.floor(R0 * 4)
	for i = 0, segs - 1 do
		local a = (i + 0.5) / segs * math.pi * 2
		local w = 2 * math.pi * R0 / segs * 1.1
		add(Vector3.new(w, hgt * 0.3, 1.2), GOLD, Enum.Material.Metal, nil, a, hgt * 0.15, 0)
		add(Vector3.new(w, 0.5, 1.4), GOLD_DEEP, Enum.Material.Metal, nil, a, hgt * 0.32, 0)
		if i % 2 == 0 then
			add(Vector3.new(w * 0.6, 0.7, 0.3), CRIMSON, Enum.Material.Neon, nil, a, hgt * 0.15, 0.7)
		end
	end
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		add(Vector3.new(2.4, hgt, 0.9), GOLD, Enum.Material.Metal, nil, a, hgt * 0.8, 0)
		add(Vector3.new(1.6, 1.6, 1.0), GOLD:Lerp(WHITE, 0.3), Enum.Material.Metal, nil, a, hgt * 1.3 + 0.6, 0, CFrame.Angles(0, 0, math.rad(45)))
		add(v3(1.6), k % 2 == 0 and CRIMSON or SAPPHIRE, Enum.Material.Neon, "ball", a, hgt * 0.75, 0.6)
	end
	return items
end
local function crownSet(items: { CrownItem }, cf: CFrame, R: number)
	for _, it in ipairs(items) do
		if it.p.Parent then
			it.p.CFrame = cf * CFrame.Angles(0, it.a, 0) * CFrame.new(0, it.y, -(R + it.dz)) * it.ex
		end
	end
end
local function crownFade(items: { CrownItem }, time: number)
	for _, it in ipairs(items) do
		if it.p.Parent then
			fadeOut(it.p, time)
		end
	end
end
-- 큰 터짐: 흰 심, 두 겹 껍질, 땅의 고리 셋 (빛깔 둘)
local function bigBurst(at: Vector3, R: number, c1: Color3, c2: Color3)
	local core = part(v3(6), WHITE, Enum.Material.Neon, 0, "ball")
	core.Position = at
	fadeOut(core, 0.8, { Size = v3(R * 2.4) })
	local shell = part(v3(8), c1, Enum.Material.Neon, 0.35, "ball")
	shell.Position = at
	fadeOut(shell, 1.0, { Size = v3(R * 3.2) })
	local outer = part(v3(8), c2, Enum.Material.Neon, 0.6, "ball")
	outer.Position = at
	fadeOut(outer, 1.2, { Size = v3(R * 4) })
	local g = ground(at)
	Fx.ring(g + UP * 0.5, c1, 6, R * 3.2, 0.9)
	Fx.ring(g + UP * 1.5, c2, 5, R * 2.5, 0.8)
	Fx.ring(g + UP * 3, WHITE, 4, R * 1.8, 0.6)
	Fx.blast(g + UP * 3, c1, c2, math.clamp(R / 10, 2.4, 4.4))
	Fx.debris(g, 20, 50)
	Fx.flash(at, WHITE, R * 6, 11, 1.2)
	if opts.flash and near(at, 200) then
		opts.flash(c1, 0.45)
	end
	Fx.breakSound("boom", 1.3, 0.3, at)
	Fx.breakSound("rock", 1, 0.5, at)
	shakeNear(at, 3, 320)
end

------------------------------------------------------------------------
-- 윤회권 (3.2판)
------------------------------------------------------------------------
local LIFE = { INDIGO, GOLD, REALMS[4], REALMS[6] }
-- 윤회삼륜 (E): 금빛 바퀴와 쪽빛 바퀴 둘이 부채꼴로 구르며 나갔다가 되돌아온다. 지나간 땅에 바퀴 자국, 가장 먼 곳에 바퀴 무늬
function H.rinneTriWheel(d: any)
	local from: Vector3 = d.from
	if not near(from, 300) then
		return
	end
	local look = flat(d.dir)
	local dist, time, spread, lag = d.dist or 26, d.time or 1.3, d.spread or 24, d.lag or 0.12
	hideWheel(d.m, time + lag + 0.1)
	Fx.sound("swing", 1, 0.6, from)
	local g0 = ground(from)
	for k = 1, 3 do
		local dk = CFrame.Angles(0, math.rad((k - 2) * spread), 0):VectorToWorldSpace(look)
		local axle = rightOf(dk)
		local main = k == 2
		local R = main and 3.4 or 2.6
		local col = main and GOLD or INDIGO
		local g = wheelGroup(R, main and 0.6 or 0.45)
		if not main then
			recolor(g, INDIGO, Enum.Material.Neon)
		end
		galpha(g, 1)
		local start = main and 0 or lag
		local lastP = g0 + UP * 0.12
		task.delay(start, function()
			anim(time, function(u)
				local s = dist * math.sin(u * math.pi)
				local p = g0 + UP * (R + 0.2) + dk * s
				gset(g, CFrame.lookAt(p, p + axle) * CFrame.Angles(0, 0, -s / R))
				galpha(g, main and 0 or 0.35)
				local gp = g0 + UP * 0.12 + dk * s
				if (gp - lastP).Magnitude > 1.2 then
					streak(lastP, gp, col, main and 1.4 or 1, 0.8)
					lastP = gp
					if math.random() < 0.5 then
						Fx.burst("spark", gp + UP * 0.5, col, 3, 1)
					end
				end
				if u >= 1 then
					gfade(g, 0.15)
				end
			end)
		end)
		task.delay(start + time * 0.5, function()
			local tip = g0 + dk * dist + UP * 0.2
			local seal = wheelGroup(main and 4 or 3, 0.3, 0.3)
			if not main then
				recolor(seal, INDIGO, Enum.Material.Neon)
			end
			gset(seal, CFrame.new(tip) * FLAT)
			gfade(seal, 0.6)
			Fx.ring(tip + UP * 0.2, col, 2, 14, 0.4)
			if main then
				Fx.sound("deflect", 0.8, 0.9, tip)
				shakeNear(tip, 0.5, 100)
			end
		end)
	end
	task.delay(time + lag, function()
		local r = rootOf(d.m)
		if r then
			Fx.ring(r.Position - UP * 2.6, GOLD, 2, 12, 0.35)
			Fx.burst("spark", r.Position, GOLD, 8, 1.2)
		end
	end)
end

-- 삼생보 (R): 떠난 자리에 멈춰 선 지난 세 삶이 차례로 같은 길을 다시 내달려 베고, 끝에서 나에게 모여들며 바퀴 무늬로 터진다
function H.threeLives(d: any)
	local a: Vector3, b: Vector3 = d.from, d.to
	if not near(a, 300) then
		return
	end
	local m = d.m
	local look = flat(b - a)
	local side = rightOf(look)
	local delay, gap, merge = d.delay or 0.4, d.gap or 0.16, d.merge or 1.05
	streak(ground(a) + UP * 0.15, ground(b) + UP * 0.15, GOLD, 1.6, 1.2)
	Fx.sound("swing", 1, 0.8, a)
	if typeof(m) ~= "Instance" then
		return
	end
	local ghosts = {}
	for k = 1, 3 do
		local g = ghostOf(m :: any, LIFE[k], 0.45)
		local off = side * ((k - 2) * 1.6)
		local p0 = a - look * (1 + k * 0.6) + off
		gset(g, CFrame.lookAt(p0, p0 + look))
		galpha(g, 1)
		local gh = { g = g, p = p0 }
		ghosts[k] = gh
		task.delay(0.05 * k, function()
			galpha(g, 0.45)
			Fx.burst("glitter", p0, LIFE[k], 4, 1)
		end)
		task.delay(delay + (k - 1) * gap, function()
			local q1 = b + off
			anim(0.14, function(u)
				local p = p0:Lerp(q1, u)
				gset(g, CFrame.lookAt(p, p + look))
			end)
			streak(ground(p0) + UP * 0.2, ground(q1) + UP * 0.2, LIFE[k], 1, 0.6)
			Fx.sound("swing", 0.7, 1 + k * 0.1, a)
			task.delay(0.14, function()
				gh.p = q1
				local seal = wheelGroup(2.2, 0.25, 0.2)
				recolor(seal, LIFE[k], Enum.Material.Neon)
				gset(seal, CFrame.new(ground(q1) + UP * 0.2) * FLAT)
				gfade(seal, 0.7)
				Fx.burst("spark", q1, LIFE[k], 5, 1)
			end)
		end)
	end
	task.delay(merge - 0.15, function()
		local r = rootOf(m)
		local c = r and r.Position or b
		for _, gh in ipairs(ghosts) do
			local start = gh.p
			anim(0.15, function(u)
				local p = start:Lerp(c, u * u)
				gset(gh.g, CFrame.lookAt(p, p + look))
				if u >= 1 then
					gfade(gh.g, 0.1)
				end
			end)
		end
	end)
	task.delay(merge, function()
		local r = rootOf(m)
		local c = r and r.Position or b
		local gc = ground(c) + UP * 0.25
		local seal = wheelGroup(5, 0.4, 0)
		anim(0.5, function(u)
			gset(seal, CFrame.new(gc) * CFrame.Angles(0, u * 3, 0) * FLAT)
			if u >= 1 then
				gfade(seal, 0.2)
			end
		end)
		Fx.ring(gc + UP * 0.2, GOLD, 3, 22, 0.45)
		Fx.ring(gc + UP * 0.4, INDIGO, 2, 16, 0.4)
		Fx.flash(c, GOLD, 50, 5, 0.35)
		Fx.burst("spark", c, GOLD, 14, 1.5)
		Fx.breakSound("boom", 0.8, 0.8, c)
		shakeNear(c, 0.9, 120)
	end)
end

-- 육도윤회 (오의): 하늘로 오른 큰 바퀴 → 여섯 구슬이 육각 자리에 빛기둥으로 꽂힘 → 육각별 → 바퀴가 누워 내려와 갈며 돎 → 내리박혀 터짐
function H.sixRealms(d: any)
	local c: Vector3 = d.at
	if not near(c, 400) then
		return
	end
	local from: Vector3 = d.from or c
	local look = flat(d.dir or (c - from))
	local spots = d.spots or {}
	local rise, every, fly, link, grind = d.rise or 0.55, d.every or 0.18, d.fly or 0.22, d.link or 0.35, d.grind or 1.0
	local T1 = rise + 6 * every
	local T2 = T1 + link
	local T3 = T2 + grind
	local R = 13
	local g0 = ground(c)
	local wheel = wheelGroup(R, 1.4)
	galpha(wheel, 1)
	local rootP = from + UP * 2
	local sky = from - look * 6 + UP * 32
	hideWheel(d.m, T3 + 0.3)
	if opts.tint then
		opts.tint(INDIGO, 0.3, T3 + 0.3)
	end
	local graded = near(c, 220)
	if graded then
		gradeTo(0.5, -0.2, -0.1, 0.15, Color3.fromRGB(215, 205, 255))
	end
	Fx.sound("ping", 0.6, 0.5, c)
	local wheelPos = rootP
	local landed = false
	anim(T3, function(u)
		local t = u * T3
		local spin = t * 2 + math.max(0, t - T2) ^ 2 * 8
		local cf
		if t < rise then
			local k = t / rise
			wheelPos = rootP:Lerp(sky, 1 - (1 - k) ^ 3)
			cf = CFrame.lookAt(wheelPos, wheelPos + look) * CFrame.Angles(0, 0, spin)
			galpha(wheel, 1 - k)
		elseif t < T2 then
			wheelPos = sky + UP * math.sin(t * 2) * 0.6
			cf = CFrame.lookAt(wheelPos, wheelPos + look) * CFrame.Angles(0, 0, spin)
			galpha(wheel, 0)
		else
			local k = math.clamp((t - T2) / (grind * 0.35), 0, 1)
			local e = k * k * (3 - 2 * k)
			wheelPos = sky:Lerp(g0 + UP * 1.5, e)
			cf = CFrame.lookAt(wheelPos, wheelPos + look):Lerp(CFrame.new(wheelPos) * FLAT, e) * CFrame.Angles(0, 0, spin)
			if k >= 1 then
				if not landed then
					landed = true
					Fx.breakSound("boom", 1, 0.6, c)
					Fx.ring(g0 + UP * 0.4, GOLD, R * 2, R * 2.6, 0.4)
					shakeNear(c, 1.4, 200)
				end
				if math.random() < 0.6 then
					local a = math.random() * math.pi * 2
					Fx.burst("spark", g0 + Vector3.new(math.cos(a) * R, 0.6, math.sin(a) * R), GOLD, 4, 1.4)
				end
			end
		end
		gset(wheel, cf)
		if u >= 1 then
			gfade(wheel, 0.1)
		end
	end)
	-- 여섯 구슬: 바퀴의 테에서 떨어져 나와 여섯 자리에 빛기둥으로 꽂힌다
	local pillars: { { any } } = {}
	for i = 1, 6 do
		task.delay(rise + (i - 1) * every, function()
			local col = REALMS[i]
			local orb = part(v3(2.4), col, Enum.Material.Neon, 0, "ball")
			local start = (CFrame.lookAt(wheelPos, wheelPos + look) * CFrame.new(orbOffset(R, i))).Position
			local target = spots[i] and ground(spots[i]) or g0
			Fx.sound("ping", 0.5, 0.8 + i * 0.08, start)
			anim(fly, function(u)
				local p = start:Lerp(target, u * u) + UP * math.sin(u * math.pi) * 6
				orb.Position = p
				trailDot(p, 1.6, col, 0.3)
				if u >= 1 then
					orb:Destroy()
					local pil = part(Vector3.new(40, 2.6, 2.6), col, Enum.Material.Neon, 0.25, "cyl")
					pil.CFrame = CFrame.new(target + UP * 20) * CFrame.Angles(0, 0, math.rad(90))
					local core = part(Vector3.new(40, 0.9, 0.9), WHITE, Enum.Material.Neon, 0.1, "cyl")
					core.CFrame = pil.CFrame
					pillars[i] = { pil, core, target }
					Fx.ring(target + UP * 0.3, col, 2, 16, 0.4)
					Fx.burst("spark", target + UP, col, 8, 1.3)
					shakeNear(target, 0.5, 120)
				end
			end)
		end)
	end
	-- 육각별: 기둥을 하나 건너 잇는 두 삼각형과 바깥 육각
	task.delay(T1, function()
		local lines = {}
		for i = 1, 6 do
			local p1, p2, p3 = spots[i], spots[(i % 6) + 1], spots[((i + 1) % 6) + 1]
			if p1 and p2 and p3 then
				for _, pair in ipairs({ { p2, 0.7 }, { p3, 1.2 } }) do
					local a0, a1 = ground(p1) + UP * 0.15, ground(pair[1]) + UP * 0.15
					local len = (a1 - a0).Magnitude
					local ln = part(Vector3.new(pair[2], 0.14, 0.2), REALMS[i], Enum.Material.Neon, 0.1)
					ln.CFrame = CFrame.lookAt((a0 + a1) / 2, a1)
					tween(ln, link, { Size = Vector3.new(pair[2], 0.14, len) })
					table.insert(lines, ln)
				end
			end
		end
		Fx.sound("ping", 0.7, 1.2, c)
		task.delay(link + grind, function()
			killList(lines, 0.3)
		end)
	end)
	task.delay(T3, function()
		for i, pl in pairs(pillars) do
			fadeOut(pl[1] :: BasePart, 0.5, { Size = Vector3.new(40, 7, 7) })
			fadeOut(pl[2] :: BasePart, 0.4)
			Fx.ring((pl[3] :: Vector3) + UP * 0.3, REALMS[i], 3, 20, 0.5)
		end
		bigBurst(g0 + UP * 2, (d.radius or 24) * 0.9, GOLD, INDIGO)
		if graded then
			gradeReset(1.0)
		end
	end)
end

-- 윤회전생 (초 오의)
local cycleState: { [any]: { ghosts: { any }, sky: Vector3 } } = {}
function H.rebirthCycle(d: any)
	local C: Vector3 = d.at
	if not near(C, 600) then
		return
	end
	local m = d.m
	local look = flat(d.dir or Vector3.new(0, 0, -1))
	local right = rightOf(look)
	local T1 = d.cut or 1.5
	local T2 = T1 + (d.army or 1.8)
	local T3 = T2 + (d.cage or 1.0)
	local T4 = T3 + (d.merge or 0.4)
	local cageR = d.cageR or 34
	local landT = T2 + (T3 - T2) * 0.4
	local gC = ground(C)
	local graded = near(C, 250)
	if graded then
		gradeTo(0.7, -0.3, -0.2, 0.2, Color3.fromRGB(190, 180, 255))
	end
	hideWheel(m, T4 + 0.3)
	Fx.sound("ping", 0.8, 0.3, C)
	Fx.breakSound("boom", 0.6, 0.3, C)
	local Rw = 30
	local wheel = wheelGroup(Rw, 2.6)
	galpha(wheel, 1)
	local sky = C - look * 30 + UP * 44
	local ghosts = {}
	if typeof(m) == "Instance" then
		for k = 1, 4 do
			local g = ghostOf(m :: any, LIFE[k], 0.4)
			local a = (k - 0.5) / 4 * math.pi * 2
			local home = C + (right * math.cos(a) + look * math.sin(a)) * 6
			ghosts[k] = { g = g, home = home, pos = home }
			galpha(g, 1)
		end
	end
	cycleState[m] = { ghosts = ghosts, sky = sky }
	-- 하늘에서 쪽빛 빛줄기가 내려와 바퀴가 걸린다
	local shaft = beamTo(sky + UP * 60, gC, 14, INDIGO, 0.75)
	fadeOut(shaft, T1)
	anim(T4, function(u)
		local t = u * T4
		local wheelCF
		if t < T1 then
			galpha(wheel, 1 - math.min(1, t / T1 * 2))
			wheelCF = CFrame.lookAt(sky, sky + look) * CFrame.Angles(0, 0, t * 0.3)
		elseif t < T2 then
			local k = (t - T1) / (T2 - T1)
			wheelCF = CFrame.lookAt(sky, sky + look) * CFrame.Angles(0, 0, T1 * 0.3 + (t - T1) * (1 + k * 4))
		elseif t < T3 then
			local k = math.clamp((t - T2) / (landT - T2), 0, 1)
			local e = k * k * (3 - 2 * k)
			local p = sky:Lerp(gC + UP * 2, e)
			wheelCF = CFrame.lookAt(p, p + look):Lerp(CFrame.new(p) * FLAT, e) * CFrame.Angles(0, 0, t * 5)
		else
			wheelCF = CFrame.new(gC + UP * 2) * FLAT * CFrame.Angles(0, 0, t * 9)
			galpha(wheel, (t - T3) / (T4 - T3))
		end
		gset(wheel, wheelCF)
		for k, gh in ipairs(ghosts) do
			local p
			if t < T1 then
				local kk = math.clamp((t - 0.2 * k) / 0.6, 0, 1)
				p = (gh.home - UP * 6):Lerp(gh.home, 1 - (1 - kk) ^ 2)
				galpha(gh.g, 1 - kk * 0.6)
			elseif t < T3 then
				p = gh.pos
			else
				local kk = (t - T3) / (T4 - T3)
				local r = rootOf(m)
				p = gh.pos:Lerp(r and r.Position or C, kk * kk)
			end
			gset(gh.g, CFrame.lookAt(p, p + look))
		end
		if u >= 1 then
			gfade(wheel, 0.1)
			for _, gh in ipairs(ghosts) do
				gfade(gh.g, 0.1)
			end
		end
	end)
	task.delay(T1, function()
		Fx.sound("swing", 1, 0.4, C)
		Fx.flash(sky, GOLD, 160, 7, 0.4)
		shakeNear(C, 1, 240)
	end)
	-- 바퀴가 땅에 내려앉아 둘레를 가둔다: 테에서 여섯 갈래 빛이 가운데로
	task.delay(landT, function()
		Fx.ring(gC + UP * 0.5, GOLD, cageR * 2, cageR * 2.4, 0.4)
		Fx.breakSound("boom", 1, 0.5, C)
		Fx.debris(gC, 14, 40)
		shakeNear(C, 1.8, 240)
		anim(T3 - landT, function(_u)
			if math.random() < 0.5 then
				local a = math.random() * math.pi * 2
				local q = gC + UP * 1.5 + Vector3.new(math.cos(a), 0, math.sin(a)) * cageR
				local b = beamTo(q, gC + UP * 2, 0.6, REALMS[math.random(1, 6)], 0.25)
				fadeOut(b, 0.2)
			end
		end)
	end)
	-- 다시 태어난다
	task.delay(T4, function()
		cycleState[m] = nil
		local R = d.radius or 38
		for k = 0, 23 do
			local a = k / 24 * math.pi * 2
			local spoke = beamTo(gC + UP * 0.4, gC + UP * 0.4 + Vector3.new(math.cos(a), 0, math.sin(a)) * R * 1.4, k % 2 == 0 and 1.6 or 0.8, k % 2 == 0 and GOLD or INDIGO, 0.1)
			fadeOut(spoke, 0.8)
		end
		for i = 1, 6 do
			local a = i / 6 * math.pi * 2
			pillar(gC + Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.55, REALMS[i], 6, 60, 0.8)
		end
		pillar(gC, WHITE, 18, 140, 0.9)
		bigBurst(gC + UP * 3, R, GOLD, INDIGO)
		if graded then
			gradeTo(0.1, 0.2, 0.45, 0.1, Color3.fromRGB(255, 240, 210))
			task.delay(0.35, function()
				gradeReset(1.6)
			end)
		end
	end)
end
-- 전생의 군세: 지난 삶 하나가 적에게 덮쳐 엇갈려 베고, 하늘 바퀴의 구슬이 빛줄기를 꽂는다
function H.rebirthStrike(d: any)
	local st = cycleState[d.m]
	local k = d.k or 1
	local gh = st and st.ghosts[k]
	local col = LIFE[k] or GOLD
	for i, at in ipairs(d.ats or {}) do
		if near(at, 320) then
			if gh and i == 1 then
				local from = gh.pos
				local spot = at + flat(at - (d.at or at) + Vector3.new(0.01, 0, 0)) * 2.5
				gh.pos = spot
				streak(ground(from) + UP * 0.2, ground(spot) + UP * 0.2, col, 0.8, 0.4)
				task.delay(0.12, function()
					gh.pos = gh.home
				end)
			end
			slashX(at, col, 7, 0.3)
			Fx.burst("spark", at, col, 6, 1.2)
			Fx.ring(ground(at) + UP * 0.3, col, 1, 10, 0.25)
			if st and math.random() < 0.6 then
				local b = beamTo(st.sky, at, 0.8, REALMS[math.random(1, 6)], 0.2)
				fadeOut(b, 0.18)
			end
		end
	end
	if d.at then
		Fx.sound("deflect", 0.5, 1.1, d.at)
	end
end

------------------------------------------------------------------------
-- 업화권 (3.2판)
------------------------------------------------------------------------
local function blackFlame(p: Vector3, size: number, rise: number, life: number)
	local dark = math.random() < 0.6
	local fl = part(v3(size), dark and CHAR or EMBER, dark and Enum.Material.SmoothPlastic or Enum.Material.Neon, 0.2, "ball")
	fl.Position = p
	fadeOut(fl, life, { Size = v3(size * 0.25), Position = p + UP * rise })
end
-- 업화쇄 (E): 사슬이 적 셋에게 날아가 걸리고, 검은 불이 사슬을 타고 번지며 끌어온 뒤, 발밑에서 지옥불로 터진다
function H.karmaChains(d: any)
	local m = d.m
	local r = rootOf(m)
	if not r or not near(r.Position, 300) then
		return
	end
	local hook, hold = d.hook or 0.18, d.hold or 0.42
	local targets = d.targets or {}
	local list: { any } = #targets > 0 and targets or { false }
	Fx.sound("block", 0.9, 0.6, r.Position)
	for i, tm in ipairs(list) do
		local hand = typeof(m) == "Instance" and m:FindFirstChild(i % 2 == 1 and "RightHand" or "LeftHand")
		local function src(): Vector3
			if hand and hand:IsA("BasePart") and hand.Parent then
				return hand.Position
			end
			return r.Position + UP
		end
		local function dst(): Vector3
			local tr = tm and rootOf(tm)
			return tr and tr.Position or d.to
		end
		local L = math.max(4, (dst() - src()).Magnitude)
		local links = chainParts(math.clamp(math.floor(L / 0.85), 6, 40))
		local life = hook + hold + 0.15
		anim(life, function(u)
			local t = u * life
			local a, b = src(), dst()
			local k
			if t < hook then
				k = t / hook
			elseif t < hook + hold then
				k = 1
			else
				k = 1 - (t - hook - hold) / 0.15
			end
			setChain(links, a, b, t < hook and 0.6 or 0.15, k)
			if t > hook and t < hook + hold and math.random() < 0.7 then
				blackFlame(a:Lerp(b, math.random()), 0.9, 1.6, 0.35)
			end
			if u >= 1 then
				for _, l in ipairs(links) do
					l:Destroy()
				end
			end
		end)
		task.delay(hook, function()
			local at = dst()
			Fx.burst("ember", at, EMBER, 8, 1.2)
			Fx.ring(ground(at) + UP * 0.3, HELL, 1, 8, 0.25)
			Fx.sound("block", 0.8, 0.9, at)
		end)
		task.delay(hook + hold, function()
			local at = dst()
			hellPillar(at, 14, 4, 0.5)
			for c = 1, 3 do
				crack(at, 6, c * 2.1 + math.random(), 0.8)
			end
			Fx.ring(ground(at) + UP * 0.3, EMBER, 2, 16, 0.4)
			Fx.burst("ember", at, EMBER, 12, 1.5)
			Fx.breakSound("boom", 0.8, 0.8, at)
			shakeNear(at, 0.7, 120)
		end)
	end
end

-- 겁화질주 (R): 지난 길이 용암 틈으로 갈라져 타고, 양옆으로 사슬이 휘몰아치고, 도화선처럼 불기둥 여덟이 차례로 솟아 끝에서 크게 터진다
function H.hellDash(d: any)
	local a: Vector3, b: Vector3 = d.from, d.to
	if not near(a, 300) then
		return
	end
	local burn, erupt, n, step = d.burn or 1.2, d.erupt or 1.3, d.pillars or 8, d.step or 0.06
	local look = flat(b - a)
	local right = rightOf(look)
	local ga, gb = ground(a) + UP * 0.12, ground(b) + UP * 0.12
	local segs: { BasePart } = {}
	local prev = ga
	for i = 1, 10 do
		local q = ga:Lerp(gb, i / 10) + right * ((i % 2 == 0) and 0.6 or -0.6) * (i < 10 and 1 or 0)
		local len = (q - prev).Magnitude
		local edge = part(Vector3.new(2.4, 0.1, len + 0.3), CHAR, Enum.Material.SmoothPlastic, 0.1)
		edge.CFrame = CFrame.lookAt((prev + q) / 2, q)
		local core = part(Vector3.new(0.9, 0.14, len + 0.3), EMBER, Enum.Material.Neon, 0)
		core.CFrame = edge.CFrame + UP * 0.03
		table.insert(segs, edge)
		table.insert(segs, core)
		prev = q
	end
	Fx.sound("swing", 1, 0.5, a)
	for s = -1, 1, 2 do
		local links = chainParts(22)
		anim(0.45, function(u)
			local p0 = ga + UP * 1.5 + right * s
			local p1 = ga:Lerp(gb, math.min(1, u * 1.3)) + UP * 1.5 + right * s * (3 + math.sin(u * math.pi) * 3)
			setChain(links, p0, p1, 1, 1)
			if u >= 1 then
				killList(links, 0.2)
			end
		end)
	end
	anim(burn + 0.2, function(_u)
		if math.random() < 0.7 then
			local p = ga:Lerp(gb, math.random()) + UP * 0.4
			blackFlame(p, 1.2, 2.5, 0.5)
			if math.random() < 0.3 then
				Fx.burst("ember", p, EMBER, 3, 1.2)
			end
		end
	end)
	for i = 1, n do
		task.delay(erupt + (i - 1) * step, function()
			local p = ga:Lerp(gb, i / n)
			hellPillar(p, 12 + i * 1.2, 3.4, 0.5)
			Fx.ring(p + UP * 0.2, EMBER, 1, 10, 0.3)
			Fx.sound("heavy", 0.6, 0.9 + i * 0.05, p)
		end)
	end
	task.delay(erupt + n * step + 0.1, function()
		hellPillar(gb, 30, 8, 0.7)
		for k = 1, 6 do
			crack(gb, 10, k, 1.0)
		end
		Fx.ring(gb + UP * 0.3, EMBER, 3, 26, 0.5)
		Fx.ring(gb + UP * 0.5, HELL, 2, 18, 0.5)
		Fx.blast(gb + UP * 2, EMBER, CHAR, 2)
		Fx.debris(gb, 10, 36)
		Fx.flash(b, EMBER, 80, 6, 0.5)
		Fx.breakSound("boom", 1, 0.6, b)
		shakeNear(b, 1.4, 160)
		killList(segs, 0.5)
	end)
end

-- 지옥문: 기둥 둘 (붉은 글, 뿔), 뿔 달린 들보, 붉은 눈, 문 안의 붉은 빛. 문짝 둘은 경첩 자리가 원점 (덩이의 -Z 쪽이 문 앞)
local function gateGroup(): (Group, Group, Group, number)
	local frame, doorL, doorR = group(), group(), group()
	local W, Hh = 8, 16
	for _, x in ipairs({ -1, 1 }) do
		gpart(frame, Vector3.new(2.2, Hh + 4, 2.6), CHAR, Enum.Material.SmoothPlastic, 0, nil, CFrame.new(x * (W + 1.1), (Hh + 4) / 2, 0))
		gpart(frame, Vector3.new(0.4, Hh, 0.3), EMBER, Enum.Material.Neon, 0.1, nil, CFrame.new(x * (W + 1.1), Hh / 2 + 1, -1.35))
		gpart(frame, Vector3.new(1, 5, 1), CHAR, Enum.Material.SmoothPlastic, 0, nil, CFrame.new(x * (W + 0.5), Hh + 6.5, 0) * CFrame.Angles(0, 0, -x * math.rad(25)))
		gpart(frame, v3(0.6), EMBER, Enum.Material.Neon, 0, "ball", CFrame.new(x * (W + 1.6), Hh + 8.6, 0))
	end
	gpart(frame, Vector3.new(2 * W + 6, 2.4, 3), CHAR, Enum.Material.SmoothPlastic, 0, nil, CFrame.new(0, Hh + 3, 0))
	gpart(frame, Vector3.new(2 * W + 2, 0.4, 0.3), EMBER, Enum.Material.Neon, 0.1, nil, CFrame.new(0, Hh + 3, -1.55))
	gpart(frame, v3(2.2), HELL, Enum.Material.Neon, 0, "ball", CFrame.new(0, Hh + 3, -1.4))
	gpart(frame, Vector3.new(2 * W, Hh, 0.3), HELL, Enum.Material.Neon, 0.15, nil, CFrame.new(0, Hh / 2, 0.6))
	for _, pair in ipairs({ { doorL, -1 }, { doorR, 1 } }) do
		local g, side = pair[1] :: Group, pair[2] :: number
		gpart(g, Vector3.new(W, Hh, 1), Color3.fromRGB(40, 22, 24), Enum.Material.Metal, 0, nil, CFrame.new(-side * W / 2, Hh / 2, 0))
		for k = 1, 4 do
			gpart(g, Vector3.new(W * 0.7, 0.35, 0.2), EMBER, Enum.Material.Neon, 0.1, nil, CFrame.new(-side * W / 2, Hh * k / 5, -0.55))
		end
		gpart(g, Vector3.new(0.35, Hh * 0.85, 0.2), EMBER, Enum.Material.Neon, 0.1, nil, CFrame.new(-side * W * 0.8, Hh / 2, -0.55))
		gpart(g, Vector3.new(0.3, 1.6, 1.6), GOLD_DEEP, Enum.Material.Metal, 0, "cyl", CFrame.new(-side * W * 0.85, Hh * 0.45, -0.7) * CFrame.Angles(0, math.rad(90), 0))
	end
	return frame, doorL, doorR, W
end
-- 업화지옥문 (오의)
function H.hellGate(d: any)
	local c: Vector3 = d.at
	if not near(c, 400) then
		return
	end
	local from: Vector3 = d.from or c
	local look = flat(d.dir or (c - from))
	local rise, open, drag, shut, sink = d.rise or 0.6, d.open or 0.4, d.drag or 1.0, d.shut or 0.4, d.sink or 0.5
	local T2 = rise + open
	local T3 = T2 + drag
	local T4 = T3 + shut
	local T5 = T4 + sink
	local g0 = ground(c)
	local frame, doorL, doorR, W = gateGroup()
	local toMe = -look
	local graded = near(c, 220)
	if graded then
		gradeTo(0.4, -0.25, -0.15, 0.25, Color3.fromRGB(255, 190, 180))
	end
	if opts.tint then
		opts.tint(HELL, 0.3, T5 + 0.3)
	end
	for k = 1, 8 do
		crack(c, 14, k / 8 * math.pi * 2, T5)
	end
	Fx.breakSound("rock", 1, 0.5, c)
	shakeNear(c, 1, 160)
	anim(T5, function(u)
		local t = u * T5
		local y = 0
		if t < rise then
			y = -22 * (1 - t / rise) ^ 3
		elseif t > T4 then
			y = -22 * ((t - T4) / sink) ^ 2
		end
		local ang = 0
		if t >= rise and t < T2 then
			ang = math.rad(80) * math.sqrt((t - rise) / open)
		elseif t >= T2 and t < T3 then
			ang = math.rad(80)
		elseif t >= T3 and t < T4 then
			ang = math.rad(80) * (1 - ((t - T3) / shut) ^ 3)
		end
		local p = g0 + UP * y
		local cf = CFrame.lookAt(p, p + toMe)
		if t < rise or t > T4 then
			cf = cf * CFrame.new((math.random() - 0.5) * 0.5, 0, 0)
		end
		gset(frame, cf)
		gset(doorL, cf * CFrame.new(-W, 0, 0) * CFrame.Angles(0, -ang, 0))
		gset(doorR, cf * CFrame.new(W, 0, 0) * CFrame.Angles(0, ang, 0))
		if (t < rise or t > T4) and math.random() < 0.5 then
			Fx.burst("dust", g0 + rightOf(look) * (math.random() - 0.5) * 20, Color3.fromRGB(120, 90, 80), 3, 1.6)
		end
		if u >= 1 then
			gfade(frame, 0.1)
			gfade(doorL, 0.1)
			gfade(doorR, 0.1)
		end
	end)
	task.delay(rise, function()
		Fx.breakSound("boom", 1, 0.4, c)
		Fx.flash(g0 + UP * 8, HELL, 90, 7, 0.5)
		shakeNear(c, 1.4, 200)
	end)
	-- 열린 문에서 검은 불과 붉은 빛이 쏟아진다
	task.delay(rise + open * 0.3, function()
		local glow = beamTo(g0 + UP * 8, g0 + UP * 8 + toMe * 30, 14, HELL, 0.7)
		fadeOut(glow, drag + open)
		anim(drag + open * 0.7, function(_u)
			if math.random() < 0.85 then
				local p0 = g0 + UP * (2 + math.random() * 12) + rightOf(look) * (math.random() - 0.5) * 12
				blackFlame(p0, 2 + math.random() * 2, 2, 0.6)
				local fl = part(v3(1.6), EMBER, Enum.Material.Neon, 0.3, "ball")
				fl.Position = p0
				fadeOut(fl, 0.6, { Position = p0 + toMe * (8 + math.random() * 10) + UP * 2, Size = v3(0.4) })
			end
		end)
	end)
	task.delay(T4, function()
		Fx.breakSound("boom", 1.3, 0.35, c)
		Fx.flash(g0 + UP * 8, EMBER, 120, 8, 0.4)
		Fx.ring(g0 + UP * 0.5, EMBER, 4, 30, 0.4)
		Fx.debris(g0, 14, 40)
		shakeNear(c, 2, 220)
	end)
	task.delay(T5, function()
		local R = d.radius or 20
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			hellPillar(c + Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.6, 26, 5, 0.6)
		end
		hellPillar(c, 60, 12, 0.8)
		bigBurst(g0 + UP * 3, R, EMBER, CHAR)
		if graded then
			gradeReset(1.0)
		end
	end)
end
-- 문의 사슬: 문 안에서 뻗어 끌려오는 적들에게 걸린다
function H.gateChain(d: any)
	local c: Vector3 = d.at
	if not near(c, 300) then
		return
	end
	local src = ground(c) + UP * 6
	for _, at in ipairs(d.ats or {}) do
		local links = chainParts(math.clamp(math.floor((at - src).Magnitude / 0.85), 4, 36))
		anim(0.35, function(u)
			setChain(links, src, at, 0.4, math.min(1, u * 3))
			if u >= 1 then
				killList(links, 0.1)
			end
		end)
		Fx.burst("ember", at, EMBER, 4, 1)
	end
	Fx.sound("block", 0.6, 0.7, c)
end

-- 팔열지옥 (초 오의)
function H.eightHells(d: any)
	local C: Vector3 = d.at
	if not near(C, 600) then
		return
	end
	local look = flat(d.dir or Vector3.new(0, 0, -1))
	local right = rightOf(look)
	local T1 = d.cut or 1.4
	local T2 = T1 + 8 * (d.every or 0.2)
	local T3 = T2 + (d.hands or 0.9)
	local T4 = T3 + (d.sun or 0.9)
	local ringR = d.ringR or 30
	local gC = ground(C)
	local graded = near(C, 260)
	if graded then
		gradeTo(0.6, -0.3, -0.25, 0.35, Color3.fromRGB(255, 120, 110))
	end
	if opts.tint then
		opts.tint(HELL, 0.35, T4 + 0.3)
	end
	for k = 1, 16 do
		crack(C, 34, k / 16 * math.pi * 2, T4 + 0.3)
	end
	Fx.breakSound("rock", 1.2, 0.4, C)
	shakeNear(C, 1.2, 240)
	local top = C + UP * 30
	local rot = math.atan2(look.Z, look.X)
	for i = 1, 8 do
		local a = rot + (i - 1) / 8 * math.pi * 2
		local p = gC + Vector3.new(math.cos(a), 0, math.sin(a)) * ringR
		local t0 = 0.1 + i * 0.1
		task.delay(t0, function()
			local Hh = 60
			local outer = part(Vector3.new(0.5, 7, 7), CHAR, Enum.Material.SmoothPlastic, 0.15, "cyl")
			outer.CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90))
			local core = part(Vector3.new(0.5, 3, 3), EMBER, Enum.Material.Neon, 0.05, "cyl")
			core.CFrame = outer.CFrame
			tween(outer, 0.3, { Size = Vector3.new(Hh, 7, 7), CFrame = CFrame.new(p + UP * Hh / 2) * CFrame.Angles(0, 0, math.rad(90)) })
			tween(core, 0.3, { Size = Vector3.new(Hh + 2, 3, 3), CFrame = CFrame.new(p + UP * Hh / 2) * CFrame.Angles(0, 0, math.rad(90)) })
			Fx.ring(p + UP * 0.3, EMBER, 3, 20, 0.5)
			Fx.sound("heavy", 0.7, 0.6 + i * 0.04, p)
			anim(T3 - t0, function(_u)
				if math.random() < 0.25 then
					Fx.burst("ember", p + UP * math.random() * 40, EMBER, 3, 1.5)
				end
			end)
			-- 기둥이 머리 위로 모여 검은 해가 된다
			task.delay(T3 - t0, function()
				fadeOut(outer, 0.3)
				fadeOut(core, 0.25)
				local b1 = beamTo(p + UP * 30, top, 3, EMBER, 0.1)
				fadeOut(b1, T4 - T3)
				local b2 = beamTo(p, top, 5, CHAR, 0.3, Enum.Material.SmoothPlastic)
				fadeOut(b2, T4 - T3)
			end)
		end)
	end
	-- 거대한 불의 두 손: 양옆에서 솟아 가운데를 맞잡는다
	task.delay(T2, function()
		local hands = {}
		for _, sd in ipairs({ -1, 1 }) do
			local g, fingers = hellHand(2.6)
			table.insert(hands, { g = g, f = fingers, sd = sd })
		end
		local Hd = T3 - T2
		local clapT = Hd * 0.85
		Fx.breakSound("rock", 1, 0.5, C)
		anim(Hd, function(u)
			local t = u * Hd
			for _, h in ipairs(hands) do
				local y, off, curl
				if t < 0.35 then
					local k = t / 0.35
					y, off, curl = -25 + 35 * (1 - (1 - k) ^ 2), 16, 0.2
				elseif t < clapT then
					local k = (t - 0.35) / (clapT - 0.35)
					y, off, curl = 10, 16 - 13 * k * k, 0.2 + 0.4 * k
				else
					y, off, curl = 10, 3, 0.6
				end
				local pos = gC + UP * y + right * (h.sd * off)
				local palm = -right * h.sd
				setHand(h.g, h.f, CFrame.fromMatrix(pos, UP:Cross(palm), UP, palm), curl, 2.6)
			end
			if math.random() < 0.4 then
				Fx.burst("ember", gC + right * (math.random() - 0.5) * 30 + UP * math.random() * 20, EMBER, 3, 1.5)
			end
			if u >= 1 then
				for _, h in ipairs(hands) do
					gfade(h.g, 0.2)
					for _, fg in ipairs(h.f) do
						for j = 1, 3 do
							local q = fg[j]
							if q then
								fadeOut(q :: BasePart, 0.2)
							end
						end
					end
				end
			end
		end)
		task.delay(clapT, function()
			Fx.flash(gC + UP * 10, EMBER, 160, 9, 0.4)
			Fx.ring(gC + UP * 10, EMBER, 6, 60, 0.4, look)
			Fx.ring(gC + UP * 0.5, EMBER, 4, 40, 0.5)
			Fx.breakSound("boom", 1.3, 0.4, C)
			Fx.debris(gC, 16, 44)
			shakeNear(C, 2.4, 260)
		end)
	end)
	-- 검은 해: 머리 위에서 커지다가 떨어진다
	task.delay(T3, function()
		local sun = part(v3(2), CHAR, Enum.Material.SmoothPlastic, 0, "ball")
		local corona = part(v3(3), EMBER, Enum.Material.Neon, 0.45, "ball")
		local halo = group()
		gHalo(halo, 13, 1, EMBER, 36, 0.1)
		galpha(halo, 1)
		local Sd = T4 - T3
		anim(Sd, function(u)
			local t = u * Sd
			local fall = math.clamp((t - Sd * 0.75) / (Sd * 0.25), 0, 1)
			local p = top:Lerp(gC + UP * 3, fall * fall)
			local s = 2 + 20 * math.min(1, t / (Sd * 0.7))
			sun.Size = v3(s)
			sun.Position = p
			corona.Size = v3(s * 1.25)
			corona.Position = p
			galpha(halo, 1 - math.min(1, t / (Sd * 0.5)))
			gset(halo, CFrame.lookAt(p, p + camFace(p, -look)) * CFrame.Angles(0, 0, t * 2))
			if math.random() < 0.6 then
				Fx.burst("ember", p, EMBER, 3, 1.6)
			end
			if u >= 1 then
				sun:Destroy()
				corona:Destroy()
				gfade(halo, 0.05)
			end
		end)
		Fx.sound("ping", 0.6, 0.3, C)
	end)
	task.delay(T4, function()
		local R = d.radius or 40
		local dome = part(v3(6), CHAR, Enum.Material.SmoothPlastic, 0.1, "ball")
		dome.Position = gC
		fadeOut(dome, 1.0, { Size = v3(R * 2.6) })
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			hellPillar(C + Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.55, 40, 6, 0.8)
		end
		hellPillar(C, 120, 20, 1.0)
		bigBurst(gC + UP * 3, R, EMBER, HELL)
		if graded then
			gradeTo(0.1, 0.1, 0.4, 0.2, Color3.fromRGB(255, 200, 180))
			task.delay(0.35, function()
				gradeReset(1.6)
			end)
		end
	end)
end
-- 팔열지옥의 한 기둥: 기둥 꼭대기에서 검은 불덩이가 적에게 떨어져 지옥불로 터진다
function H.hellStrike(d: any)
	local at: Vector3 = d.at
	if not near(at, 320) then
		return
	end
	local src: Vector3 = d.from or at
	local start = src + UP * 40
	local ball = part(v3(3.4), CHAR, Enum.Material.SmoothPlastic, 0, "ball")
	local core = part(v3(1.8), EMBER, Enum.Material.Neon, 0, "ball")
	anim(0.18, function(u)
		local p = start:Lerp(at, u)
		ball.Position = p
		core.Position = p
		trailDot(p, 2.2, EMBER, 0.25)
		if u >= 1 then
			ball:Destroy()
			core:Destroy()
		end
	end)
	task.delay(0.18, function()
		hellPillar(at, 26, 6, 0.6)
		for k = 1, 5 do
			crack(at, 8, k * 1.25, 0.9)
		end
		Fx.ring(ground(at) + UP * 0.3, EMBER, 2, 22, 0.4)
		Fx.burst("ember", at, EMBER, 12, 1.6)
		Fx.breakSound("boom", 0.9, 0.7, at)
		shakeNear(at, 1, 160)
	end)
end

------------------------------------------------------------------------
-- 무상권 (3.2판)
------------------------------------------------------------------------
-- 무상섬 (E): 적 다섯의 등 뒤로 차례로 나타나며 베고, 남은 잔상이 마지막에 한꺼번에 다시 베고 흩어진다
function H.phantomRush(d: any)
	local m = d.m
	local from: Vector3 = d.from
	if not near(from, 300) then
		return
	end
	local delay, every, echo = d.delay or 0.06, d.every or 0.14, d.echo or 0.3
	local targets = d.targets or {}
	mistPuff(from, 4, 0.6)
	Fx.sound("swing", 0.8, 1.3, from)
	local images = {}
	local prev = from
	for i, tm in ipairs(targets) do
		task.delay(delay + (i - 1) * every, function()
			local tr = rootOf(tm)
			if not tr then
				return
			end
			local tp = tr.Position
			local spot = tp + flat(tp - prev) * 3.2
			streak(ground(prev) + UP * 0.3, ground(spot) + UP * 0.3, GHOST, 0.5, 0.35, 0.1)
			if typeof(m) == "Instance" then
				local g = ghostOf(m :: any, GHOST, 0.55)
				gset(g, CFrame.lookAt(spot, Vector3.new(tp.X, spot.Y, tp.Z)))
				table.insert(images, { g = g, at = tp })
			end
			slashX(tp + UP * 0.5, GHOST, 7, 0.3)
			mistPuff(spot, 3, 0.5)
			Fx.burst("spark", tp, GHOST, 6, 1)
			Fx.sound("deflect", 0.6, 1.2 + i * 0.06, tp)
			prev = spot
		end)
	end
	task.delay(delay + math.max(1, #targets) * every + echo, function()
		for _, im in ipairs(images) do
			slashX(im.at + UP * 0.5, WHITE, 9, 0.35)
			slashX(im.at + UP * 0.5, GHOST, 11, 0.45)
			Fx.ring(ground(im.at) + UP * 0.3, GHOST, 1, 12, 0.3)
			gfade(im.g, 0.25)
			mistPuff(im.at, 4, 0.7)
		end
		if #images > 0 then
			Fx.sound("block", 0.8, 1.4, from)
			shakeNear(from, 0.7, 120)
		end
	end)
end

-- 허실분신 (R): 분신 다섯이 별처럼 뻗어 베고, 서로 엇갈려 오각별을 긋고, 가운데에서 내가 나타나며 별이 터진다
function H.mistStar(d: any)
	local C: Vector3 = d.at
	if not near(C, 300) then
		return
	end
	local m = d.m
	local pts = d.pts or {}
	local n = #pts
	local out, cross, back = d.out or 0.15, d.cross or 0.55, d.back or 0.95
	mistPuff(C, 6, 0.7)
	Fx.sound("swing", 1, 1.1, C)
	for k, pt in ipairs(pts) do
		local g = typeof(m) == "Instance" and ghostOf(m :: any, k % 2 == 0 and MIST or GHOST, 0.35) or nil
		local dirk = flat(pt - C)
		local q = pts[(k + 1) % n + 1]
		anim(out, function(u)
			local p = C:Lerp(pt, 1 - (1 - u) ^ 2)
			if g then
				gset(g, CFrame.lookAt(p, p + dirk) * CFrame.Angles(0, u * math.pi * 2, 0))
			end
			trailDot(p, 1.6, GHOST, 0.25)
		end)
		streak(ground(C) + UP * 0.25, ground(pt) + UP * 0.25, GHOST, 0.6, 0.5)
		task.delay(out, function()
			slashX(pt + UP * 0.5, GHOST, 6, 0.3)
			mistPuff(pt, 3, 0.4)
		end)
		task.delay(cross, function()
			local dq = flat(q - pt)
			anim(0.12, function(u)
				local p = pt:Lerp(q, u)
				if g then
					gset(g, CFrame.lookAt(p, p + dq))
				end
				trailDot(p, 1.4, WHITE, 0.25)
			end)
			local a0, a1 = ground(pt) + UP * 0.2, ground(q) + UP * 0.2
			local len = (a1 - a0).Magnitude
			local ln = part(Vector3.new(0.9, 0.14, len), GHOST, Enum.Material.Neon, 0.1)
			ln.CFrame = CFrame.lookAt((a0 + a1) / 2, a1)
			task.delay(back - cross, function()
				fadeOut(ln, 0.4, { Size = Vector3.new(3, 0.14, len) })
			end)
			Fx.sound("deflect", 0.5, 1.3, pt)
		end)
		task.delay(back - 0.12, function()
			anim(0.12, function(u)
				local p = q:Lerp(C, u * u)
				if g then
					gset(g, safeLook(p, C))
					if u >= 1 then
						gfade(g, 0.1)
					end
				end
			end)
		end)
	end
	task.delay(back, function()
		local gc = ground(C)
		Fx.ring(gc + UP * 0.3, GHOST, 3, 24, 0.45)
		Fx.ring(gc + UP * 0.5, WHITE, 2, 16, 0.35)
		for _ = 1, 5 do
			slashX(C + UP + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 6, GHOST, 8, 0.35)
		end
		mistPuff(C, 8, 0.8)
		Fx.flash(C, GHOST, 60, 5, 0.4)
		Fx.breakSound("boom", 0.7, 1.0, C)
		shakeNear(C, 0.9, 130)
	end)
end

-- 무상해 (오의): 안개 바다, 빛깔이 빠진 세상, 넋의 손, 도는 넋불 → 손뼉에 안개가 기둥으로 빨려 들었다가 사방으로 베며 흩어진다
function H.mistSea(d: any)
	local C: Vector3 = d.at
	if not near(C, 400) then
		return
	end
	local spread, hold, implode, R = d.spread or 0.4, d.hold or 1.6, d.implode or 0.35, d.radius or 28
	local gC = ground(C)
	local graded = near(C, 220)
	if graded then
		gradeTo(0.4, -0.85, -0.05, 0.2, Color3.fromRGB(225, 235, 245))
	end
	local fog = {}
	for k = 1, 26 do
		local a = k / 26 * math.pi * 2 + math.random() * 0.3
		local r = R * (0.25 + 0.75 * ((k % 3) + 1) / 3) * (0.85 + math.random() * 0.3)
		local sz = 8 + math.random() * 6
		local b = part(Vector3.new(sz, sz * 0.35, sz), MIST:Lerp(GHOST, math.random() * 0.25), Enum.Material.SmoothPlastic, 0.55, "ball")
		b.Position = gC + UP * 0.8
		tween(b, spread, { Position = gC + Vector3.new(math.cos(a) * r, 0.8, math.sin(a) * r) })
		fog[k] = b
	end
	local sea = part(Vector3.new(0.3, 2, 2), MIST, Enum.Material.SmoothPlastic, 0.6, "cyl")
	sea.CFrame = CFrame.new(gC + UP * 0.3) * CFrame.Angles(0, 0, math.rad(90))
	tween(sea, spread, { Size = Vector3.new(0.3, R * 2, R * 2) })
	Fx.sound("swing", 1, 0.4, C)
	local wisps = {}
	for k = 1, 6 do
		wisps[k] = part(v3(1.4), GHOST, Enum.Material.Neon, 0.1, "ball")
	end
	anim(spread + hold, function(u)
		local t = u * (spread + hold)
		for k, w in ipairs(wisps) do
			local a = t * 1.6 + k / 6 * math.pi * 2
			local rr = R * 0.6 + math.sin(t * 2 + k) * 4
			local p = gC + Vector3.new(math.cos(a) * rr, 2.5 + math.sin(t * 3 + k), math.sin(a) * rr)
			w.Position = p
			if math.random() < 0.5 then
				trailDot(p, 1, GHOST, 0.35)
			end
		end
		if u >= 1 then
			for _, w in ipairs(wisps) do
				fadeOut(w, 0.1)
			end
		end
	end)
	-- 넋의 손: 안개에서 솟아 적의 발목을 쥔다
	for i, tm in ipairs(d.targets or {}) do
		task.delay(spread + (i - 1) * 0.08, function()
			local tr = rootOf(tm)
			if not tr then
				return
			end
			local hand = ghostHand()
			local life = math.max(0.2, hold - (i - 1) * 0.08)
			local last = tr.Position
			anim(life, function(u)
				if tr.Parent then
					last = tr.Position
				end
				local rise = math.min(1, u * 4)
				gset(hand, CFrame.new(ground(last) + UP * (-3 + rise * 3.2)) * CFrame.Angles(0, u * 2, 0))
				if u >= 1 then
					gfade(hand, 0.15)
				end
			end)
			mistPuff(last, 3, 0.5)
			Fx.sound("deflect", 0.4, 0.6, last)
		end)
	end
	task.delay(spread + hold, function()
		for _, b in ipairs(fog) do
			tween(b, implode, { Position = gC + UP * 2, Size = Vector3.new(2, 2, 2) })
		end
		tween(sea, implode, { Size = Vector3.new(0.3, 2, 2) })
		local colm = part(Vector3.new(1, 3, 3), MIST, Enum.Material.SmoothPlastic, 0.4, "cyl")
		colm.CFrame = CFrame.new(gC + UP * 0.5) * CFrame.Angles(0, 0, math.rad(90))
		tween(colm, implode, { Size = Vector3.new(50, 9, 9), CFrame = CFrame.new(gC + UP * 25) * CFrame.Angles(0, 0, math.rad(90)) })
		Fx.sound("block", 1, 1.5, C)
		Fx.flash(C, WHITE, 50, 5, 0.2)
		task.delay(implode, function()
			for _, b in ipairs(fog) do
				b:Destroy()
			end
			sea:Destroy()
			fadeOut(colm, 0.5, { Size = Vector3.new(60, 30, 30) })
			for k = 1, 12 do
				local a = k / 12 * math.pi * 2
				local p = gC + UP * 1.5 + Vector3.new(math.cos(a), 0, math.sin(a)) * R * (0.4 + (k % 2) * 0.35)
				slashX(p, k % 2 == 0 and GHOST or WHITE, 10, 0.4)
				mistPuff(p, 4, 0.7)
			end
			Fx.ring(gC + UP * 0.5, GHOST, 6, R * 2.6, 0.7)
			Fx.ring(gC + UP * 1, WHITE, 4, R * 2, 0.6)
			Fx.blast(gC + UP * 2, GHOST, MIST, 3)
			Fx.flash(C, WHITE, 120, 8, 0.6)
			Fx.breakSound("boom", 1.1, 0.7, C)
			Fx.breakSound("glass", 0.7, 0.8, C)
			shakeNear(C, 2, 220)
			if graded then
				gradeTo(0.08, 0.2, 0.3, 0.1, WHITE)
				task.delay(0.15, function()
					gradeReset(0.8)
				end)
			end
		end)
	end)
end

-- 만상귀무 (초 오의)
function H.allReturn(d: any)
	local C: Vector3 = d.at
	if not near(C, 600) then
		return
	end
	local m = d.m
	local look = flat(d.dir or Vector3.new(0, 0, -1))
	local T1 = d.cut or 1.4
	local T2 = T1 + (d.rise or 0.6)
	local nS, sE, sT = d.sweeps or 3, d.sweepEvery or 0.5, d.sweepT or 0.25
	local T3 = T2 + nS * sE
	local T4 = T3 + (d.freeze or 0.8)
	local gC = ground(C)
	local graded = near(C, 260)
	if graded then
		gradeTo(0.8, -1, -0.1, 0.25, Color3.fromRGB(220, 230, 240))
	end
	-- 몸이 안개로 흩어진다: 몸 조각을 본뜬 안개가 위로 흩날리며 사라진다
	if typeof(m) == "Instance" then
		local g = ghostOf(m :: any, MIST, 0.2)
		local r = rootOf(m)
		local base = r and r.CFrame or CFrame.new(C)
		gset(g, base)
		for _, it in ipairs(g.items) do
			local p = it[1] :: BasePart
			local drift = Vector3.new((math.random() - 0.5) * 6, 4 + math.random() * 8, (math.random() - 0.5) * 6)
			tween(p, T1 * 0.8, { CFrame = base * (it[2] :: CFrame) + drift, Transparency = 1, Size = p.Size * 0.3 })
		end
		task.delay(T1, function()
			for _, it in ipairs(g.items) do
				local p = it[1] :: BasePart
				if p.Parent then
					p:Destroy()
				end
			end
		end)
	end
	for k = 1, 10 do
		task.delay(k * 0.1, function()
			mistPuff(C + Vector3.new((math.random() - 0.5) * 4, math.random() * 4, (math.random() - 0.5) * 4), 3, 0.8)
		end)
	end
	Fx.sound("swing", 0.8, 0.4, C)
	-- 거대한 그림자와 넋의 칼
	local S = 6
	local giant = typeof(m) == "Instance" and bigGhost(m :: any, S, GHOST, 0.55) or nil
	local blade = group()
	gpart(blade, Vector3.new(1.2, 0.5, 46), WHITE, Enum.Material.Neon, 0.1, nil, CFrame.new(0, 0, -23))
	gpart(blade, Vector3.new(3, 0.3, 48), GHOST, Enum.Material.Neon, 0.5, nil, CFrame.new(0, 0, -24))
	galpha(blade, 1)
	if giant then
		galpha(giant, 1)
	end
	local lastArc = 0
	anim(T4, function(u)
		local t = u * T4
		if giant and t >= T1 then
			local k = math.clamp((t - T1) / (T2 - T1), 0, 1)
			local e = 1 - (1 - k) ^ 2
			local base = gC + UP * (2.9 * S) - UP * (1 - e) * 40
			local sw = 0
			local sweeping = false
			if t >= T2 and t < T3 then
				local idx = math.floor((t - T2) / sE)
				local kk = ((t - T2) - idx * sE) / (sE * 0.8)
				local dirS = (idx % 2 == 0) and 1 or -1
				sw = dirS * (-1 + 2 * math.clamp(kk, 0, 1)) * math.rad(100)
				sweeping = kk <= 1
			end
			gset(giant, CFrame.lookAt(base, base + look) * CFrame.Angles(0, -sw * 0.35, 0))
			if t < T3 then
				galpha(giant, math.max(0.55, 1 - e))
			else
				galpha(giant, 0.55 + 0.45 * (t - T3) / (T4 - T3))
			end
			if sweeping then
				local dirB = CFrame.Angles(0, sw, 0):VectorToWorldSpace(look)
				local o = gC + UP * 3
				galpha(blade, 0)
				gset(blade, CFrame.lookAt(o, o + dirB))
				if os.clock() - lastArc > 0.02 then
					lastArc = os.clock()
					local b = beamTo(o + dirB * 6, o + dirB * 46, 1.5, GHOST, 0.4)
					fadeOut(b, 0.3)
				end
			else
				galpha(blade, 1)
			end
		end
		if u >= 1 then
			if giant then
				gfade(giant, 0.1)
			end
			gfade(blade, 0.1)
		end
	end)
	task.delay(T1, function()
		Fx.sound("swing", 1.2, 0.3, C)
		Fx.flash(gC + UP * 18, GHOST, 140, 6, 0.4)
		shakeNear(C, 1.2, 240)
	end)
	for k = 1, nS do
		task.delay(T2 + (k - 1) * sE + sT, function()
			Fx.sound("swing", 1.2, 0.5 + k * 0.05, C)
			Fx.ring(gC + UP * 3, GHOST, 6, 90, 0.4)
			Fx.flash(C, GHOST, 100, 5, 0.25)
			shakeNear(C, 1.6, 260)
		end)
	end
	-- 그림자가 내 자리로 흩어져 모이고, 빛깔이 돌아온다
	task.delay(T4 - 0.3, function()
		for k = 1, 16 do
			local a = k / 16 * math.pi * 2
			local p0 = gC + UP * 6 + Vector3.new(math.cos(a), 0, math.sin(a)) * 30
			local b = part(v3(3), MIST, Enum.Material.SmoothPlastic, 0.4, "ball")
			b.Position = p0
			tween(b, 0.3, { Position = gC + UP * 2, Size = v3(1) })
			task.delay(0.32, function()
				b:Destroy()
			end)
		end
	end)
	task.delay(T4, function()
		local R = d.radius or 42
		for k = 1, 10 do
			local a = k / 10 * math.pi * 2
			slashX(gC + UP * 2 + Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.45, GHOST, 14, 0.5)
		end
		mistPuff(C, 10, 1.0)
		bigBurst(gC + UP * 3, R, GHOST, MIST)
		if graded then
			gradeTo(0.06, 0.3, 0.5, 0.1, WHITE)
			task.delay(0.25, function()
				gradeReset(1.4)
			end)
		end
	end)
end
-- 시간이 멈추고 적마다 푸른 봉인: freeze 뒤에 한꺼번에 깨진다
function H.voidSeals(d: any)
	local fr = d.freeze or 0.8
	local C: Vector3 = d.at or Vector3.new()
	if near(C, 260) then
		gradeTo(0.1, -1, -0.25, 0.5, Color3.fromRGB(200, 225, 255))
	end
	Fx.sound("ping", 0.7, 0.3, C)
	for _, at in ipairs(d.ats or {}) do
		if near(at, 320) then
			local bars: { BasePart } = {}
			for k = -1, 1, 2 do
				local p = part(Vector3.new(0.4, 6, 0.4), GHOST, Enum.Material.Neon, 0.05)
				p.CFrame = CFrame.new(at + UP * 0.5) * CFrame.Angles(0, 0, math.rad(45 * k))
				table.insert(bars, p)
			end
			local ring = part(Vector3.new(0.2, 6, 6), GHOST, Enum.Material.Neon, 0.4, "cyl")
			ring.CFrame = CFrame.new(ground(at) + UP * 0.15) * CFrame.Angles(0, 0, math.rad(90))
			table.insert(bars, ring)
			task.delay(fr, function()
				for _, p in ipairs(bars) do
					fadeOut(p, 0.2, { Size = p.Size * 1.6 })
				end
				slashX(at + UP * 0.5, WHITE, 12, 0.4)
				slashX(at + UP * 0.5, GHOST, 14, 0.5)
				mistPuff(at, 5, 0.7)
				Fx.burst("glitter", at, GHOST, 10, 1.5)
				Fx.ring(ground(at) + UP * 0.3, GHOST, 2, 18, 0.4)
			end)
		end
	end
end

------------------------------------------------------------------------
-- 권왕신권 (3.2판)
------------------------------------------------------------------------
-- 왕권천타 (E): 등 뒤에 부채꼴로 나타난 금빛 주먹 여섯이 차례로 내지르고, 왕의 큰 주먹이 가운데를 꿰뚫는다
function H.kingBarrage(d: any)
	local from: Vector3 = d.from
	if not near(from, 300) then
		return
	end
	local look = flat(d.dir)
	local right = rightOf(look)
	local n, every, delay, finalAt, L = d.n or 6, d.every or 0.08, d.delay or 0.15, d.finalAt or 0.12, d.length or 28
	Fx.sound("heavy", 0.8, 0.6, from)
	for k = 1, n do
		local side = (k % 2 == 0 and 1 or -1) * math.ceil(k / 2) * 1.6
		local off = right * side
		local fist = fistGroup(0.5, 0)
		galpha(fist, 1)
		local home = from - look * 4 + off * 1.4 + UP * (3 + (math.ceil(k / 2) % 2) * 1.5)
		local wait = delay + (k - 1) * every
		anim(wait, function(u)
			gset(fist, CFrame.lookAt(home, home + look))
			galpha(fist, 1 - u)
		end)
		task.delay(wait, function()
			local a1 = from + off + look * L + UP * 1.5
			local dir = (a1 - home).Unit
			anim(0.12, function(u)
				local p = home:Lerp(a1, u)
				gset(fist, CFrame.lookAt(p, p + dir))
				trailDot(p - look * 2, 2.2, GOLD, 0.25)
				if u >= 1 then
					gfade(fist, 0.15)
				end
			end)
			streak(ground(from + off) + UP * 0.15, ground(a1) + UP * 0.15, GOLD, 0.5, 0.4)
			task.delay(0.12, function()
				Fx.ring(a1, GOLD, 1, 9, 0.25, look)
				Fx.burst("spark", a1, GOLD, 5, 1)
				Fx.sound("hit", 0.6, 1 + k * 0.06, a1)
			end)
		end)
	end
	task.delay(delay + n * every + finalAt - 0.14, function()
		local big = fistGroup(1.1, 0)
		local a0 = from - look * 6 + UP * 4
		local a1 = from + look * (L + 6) + UP * 2
		anim(0.14, function(u)
			local p = a0:Lerp(a1, u)
			gset(big, CFrame.lookAt(p, p + look))
			trailDot(p - look * 4, 5, GOLD, 0.35)
			if u >= 1 then
				gfade(big, 0.2)
			end
		end)
		for i = 1, 6 do
			task.delay(0.14 * i / 6, function()
				local p = from + look * (L + 6) * i / 6
				Fx.ring(ground(p) + UP * 0.3, GOLD, 2, 12 + i * 2, 0.35)
				Fx.ring(p + UP * 2, GOLD, 2, 10, 0.25, look)
			end)
		end
		task.delay(0.14, function()
			goldImpact(a1, 1.3)
			Fx.flash(a1, GOLD, 60, 6, 0.4)
			Fx.breakSound("boom", 1, 0.7, a1)
			shakeNear(a1, 1.2, 150)
		end)
	end)
end

-- 왕도강림 (R): 붉은 길이 깔리고 그 위로 뛰어오른다 (금빛 꼬리)
function H.kingLeap(d: any)
	local a: Vector3, b: Vector3 = d.from, d.to
	if not near(a, 300) then
		return
	end
	local land = d.land or 0.42
	local look = flat(b - a)
	local right = rightOf(look)
	local ga = ground(a) + UP * 0.1
	local L = (ground(b) - ground(a)).Magnitude
	local carpet = part(Vector3.new(4, 0.1, 0.2), CRIMSON, Enum.Material.Fabric, 0)
	local trims = { part(Vector3.new(0.35, 0.12, 0.2), GOLD, Enum.Material.Metal, 0), part(Vector3.new(0.35, 0.12, 0.2), GOLD, Enum.Material.Metal, 0) }
	anim(land, function(u)
		local len = math.max(0.2, L * u)
		local mid = ga + look * (len / 2)
		carpet.Size = Vector3.new(4, 0.1, len)
		carpet.CFrame = CFrame.lookAt(mid, mid + look)
		for i, tr in ipairs(trims) do
			local sm = mid + right * (i == 1 and 2 or -2)
			tr.Size = Vector3.new(0.35, 0.12, len)
			tr.CFrame = CFrame.lookAt(sm, sm + look)
		end
	end)
	task.delay(land + 1.2, function()
		fadeOut(carpet, 0.5)
		for _, tr in ipairs(trims) do
			fadeOut(tr, 0.5)
		end
	end)
	local r = rootOf(d.m)
	anim(land, function(_u)
		if r and r.Parent and math.random() < 0.8 then
			trailDot(r.Position, 2, GOLD, 0.35)
		end
	end)
	Fx.sound("jump", 1, 0.8, a)
	Fx.ring(ga + UP * 0.2, GOLD, 2, 12, 0.3)
end
-- 내려앉은 자리: 왕관의 가시 여덟이 솟았다가 안으로 무너지며 터진다
function H.kingLand(d: any)
	local at: Vector3 = d.at
	if not near(at, 300) then
		return
	end
	local collapse, R = d.collapse or 0.4, d.spikeR or 8
	local g = ground(at)
	goldImpact(at, 1.2)
	Fx.breakSound("boom", 1, 0.7, at)
	local spikes = {}
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local base = g + Vector3.new(math.cos(a), 0, math.sin(a)) * R
		local hgt = (k % 2 == 0) and 9 or 6
		local sp = group()
		gpart(sp, Vector3.new(2.2, hgt, 0.8), GOLD, Enum.Material.Metal, 0, nil, CFrame.new(0, hgt / 2, 0))
		gpart(sp, Vector3.new(1.2, hgt * 0.4, 0.9), GOLD:Lerp(WHITE, 0.3), Enum.Material.Metal, 0, nil, CFrame.new(0, hgt * 0.95, 0) * CFrame.Angles(0, 0, math.rad(45)))
		gpart(sp, v3(1), k % 2 == 0 and CRIMSON or SAPPHIRE, Enum.Material.Neon, 0, "ball", CFrame.new(0, hgt * 0.55, -0.5))
		table.insert(spikes, { g = sp, base = base, h = hgt })
	end
	local life = collapse + 0.15
	anim(life, function(u)
		local t = u * life
		for _, s in ipairs(spikes) do
			local rise = math.min(1, t / 0.12)
			local lean = math.clamp((t - (collapse - 0.12)) / 0.15, 0, 1)
			local cf = safeLook(s.base, s.base + flat(g - s.base)) * CFrame.new(0, -s.h * (1 - rise), 0) * CFrame.Angles(-lean * math.rad(70), 0, 0)
			gset(s.g, cf)
		end
		if u >= 1 then
			for _, s in ipairs(spikes) do
				gfade(s.g, 0.15)
			end
		end
	end)
	task.delay(collapse, function()
		local core = part(v3(4), WHITE, Enum.Material.Neon, 0, "ball")
		core.Position = g + UP * 3
		fadeOut(core, 0.4, { Size = v3(R * 3) })
		Fx.ring(g + UP * 0.3, GOLD, 3, R * 3.5, 0.45)
		Fx.ring(g + UP * 0.5, CRIMSON, 2, R * 2.5, 0.4)
		pillar(g, GOLD, 6, 30, 0.5)
		Fx.burst("spark", g + UP * 2, GOLD, 16, 1.6)
		Fx.flash(at, GOLD, 70, 6, 0.4)
		Fx.breakSound("boom", 1, 0.6, at)
		shakeNear(at, 1.4, 160)
	end)
end

-- 금빛 구름 고리: 하늘 높이 둥글게 열린다
local function goldClouds(at: Vector3, h: number, r0: number, r1: number, time: number, life: number)
	for k = 1, 12 do
		local a = k / 12 * math.pi * 2
		local cl = part(Vector3.new(14, 5, 10), Color3.fromRGB(255, 225, 150), Enum.Material.SmoothPlastic, 0.4, "ball")
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		cl.CFrame = CFrame.lookAt(at + UP * h + dir * r0, at + UP * h + dir * (r0 + 1))
		tween(cl, time, { CFrame = CFrame.lookAt(at + UP * h + dir * r1, at + UP * h + dir * (r1 + 1)) })
		task.delay(time, function()
			fadeOut(cl, life)
		end)
	end
end
-- 만인지상 (오의): 금빛 구름이 열리고 거대한 왕관이 내려와 가두고, 돌며 조이고, 보석이 빛줄기를 쏘고, 내리박혀 터진다
function H.crownCage(d: any)
	local c: Vector3 = d.at
	if not near(c, 400) then
		return
	end
	local descend, squeeze, slam = d.descend or 0.6, d.squeeze or 1.2, d.slam or 0.4
	local R0 = d.R or 14
	local total = descend + squeeze + slam
	local g0 = ground(c)
	local graded = near(c, 220)
	if graded then
		gradeTo(0.4, 0.1, 0.05, 0.15, Color3.fromRGB(255, 235, 190))
	end
	if opts.tint then
		opts.tint(GOLD, 0.25, total + 0.3)
	end
	goldClouds(g0, 60, 6, 26, descend, squeeze + slam)
	local light = beamTo(g0 + UP * 60, g0, 10, Color3.fromRGB(255, 235, 170), 0.6)
	local cr = crownNew(R0, 10, 10)
	Fx.sound("ping", 0.7, 0.5, c)
	anim(total + 0.1, function(u)
		local t = u * (total + 0.1)
		local y, R, spin
		if t < descend then
			local k = t / descend
			y, R, spin = 55 * (1 - k * k), R0, t * 1.5
		elseif t < descend + squeeze then
			local k = (t - descend) / squeeze
			y, R, spin = 0, R0 - (R0 - 6) * k * k, descend * 1.5 + (t - descend) * (2 + k * 8)
		else
			local k = math.min(1, (t - descend - squeeze) / slam)
			y, R, spin = 6 * math.sin(k * math.pi), 6, descend * 1.5 + squeeze * 6 + (t - descend - squeeze) * 10
		end
		crownSet(cr, CFrame.new(g0 + UP * y) * CFrame.Angles(0, spin, 0), R)
		if u >= 1 then
			crownFade(cr, 0.15)
		end
	end)
	task.delay(descend, function()
		Fx.breakSound("boom", 1.1, 0.5, c)
		Fx.ring(g0 + UP * 0.4, GOLD, R0 * 2, R0 * 2.8, 0.4)
		Fx.debris(g0, 14, 40)
		Fx.flash(c, GOLD, 90, 6, 0.4)
		shakeNear(c, 1.6, 200)
		fadeOut(light, 0.4)
		anim(squeeze, function(u)
			if math.random() < 0.45 then
				local a = math.random() * math.pi * 2
				local R = R0 - (R0 - 6) * u * u
				local q = g0 + UP * 7.5 + Vector3.new(math.cos(a), 0, math.sin(a)) * R
				local b = beamTo(q, g0 + UP * 2, 0.6, math.random() < 0.5 and CRIMSON or SAPPHIRE, 0.15)
				fadeOut(b, 0.15)
				Fx.burst("spark", g0 + UP * 2, GOLD, 2, 1)
			end
		end)
	end)
	task.delay(total, function()
		local R = d.radius or 22
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			pillar(g0 + Vector3.new(math.cos(a), 0, math.sin(a)) * 6, GOLD, 4, 40, 0.6)
		end
		-- 붉은 깃발 여덟이 바깥으로 펼쳐진다
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2 + 0.2
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local flag = part(Vector3.new(0.3, 7, 3), CRIMSON, Enum.Material.Fabric, 0)
			flag.CFrame = CFrame.lookAt(g0 + UP * 3.5 + dir * 4, g0 + UP * 3.5 + dir * 5)
			fadeOut(flag, 0.8, { CFrame = CFrame.lookAt(g0 + UP * 4 + dir * R, g0 + UP * 4 + dir * (R + 1)) })
		end
		bigBurst(g0 + UP * 3, R, GOLD, CRIMSON)
		if graded then
			gradeReset(1.0)
		end
	end)
end

-- 천하제일권 (초 오의)
function H.kingOfHeaven(d: any)
	local C: Vector3 = d.at
	if not near(C, 600) then
		return
	end
	local look = flat(d.dir or Vector3.new(0, 0, -1))
	local right = rightOf(look)
	local T1 = d.cut or 1.5
	local T2 = T1 + (d.rain or 1.8)
	local T3 = T2 + (d.charge or 0.8)
	local T4 = T3 + (d.punch or 0.3)
	local T5 = T4 + (d.endAt or 0.4)
	local L = d.length or 80
	local gC = ground(C)
	local graded = near(C, 260)
	if graded then
		gradeTo(0.6, 0.15, 0.05, 0.2, Color3.fromRGB(255, 230, 180))
	end
	goldClouds(gC, 80, 10, 60, T1, T5 - T1)
	local shaft = beamTo(gC + UP * 90, gC, 30, Color3.fromRGB(255, 235, 170), 0.7)
	fadeOut(shaft, T1 + 0.5)
	Fx.sound("ping", 0.8, 0.4, C)
	local s = 2.2
	local king = kingGroup(s)
	galpha(king.g, 1)
	local base = gC - look * 14 + UP * (5 * s)
	anim(T5, function(u)
		local t = u * T5
		local y = 0
		if t < T1 then
			local k = t / T1
			y = -50 * (1 - k) ^ 2
			galpha(king.g, 1 - math.min(1, k * 1.5))
		end
		local lean = 0
		if t >= T1 and t < T2 then
			lean = math.sin(t * 25) * 0.04
		elseif t >= T2 and t < T3 then
			lean = -0.15 * (t - T2) / (T3 - T2)
		elseif t >= T3 then
			lean = 0.25 * math.min(1, (t - T3) / 0.1)
		end
		local p = base + UP * y
		gset(king.g, CFrame.lookAt(p, p + look) * CFrame.Angles(-lean, 0, 0))
		if t > T4 + 0.1 then
			galpha(king.g, math.min(1, (t - T4 - 0.1) / (T5 - T4)))
		end
		if t < T1 and math.random() < 0.4 then
			Fx.burst("spark", p + right * (math.random() - 0.5) * 20 + UP * math.random() * 30, GOLD, 3, 1.5)
		end
		if u >= 1 then
			gfade(king.g, 0.1)
		end
	end)
	task.delay(T1, function()
		Fx.breakSound("boom", 1.1, 0.4, C)
		Fx.flash(base, GOLD, 160, 7, 0.4)
		shakeNear(C, 1.4, 240)
	end)
	-- 힘을 모은다: 둘레의 금빛이 왕의 오른 주먹과 내 손으로 빨려 든다
	task.delay(T2, function()
		local fist = king.fists[2]
		anim(T3 - T2, function(u)
			local fp = (fist and fist.Parent) and fist.CFrame.Position or (base + UP * 10)
			if math.random() < 0.8 then
				local a = math.random() * math.pi * 2
				local q = fp + Vector3.new(math.cos(a), (math.random() - 0.5) * 1.2, math.sin(a)) * (18 + math.random() * 10)
				local b = beamTo(q, fp, 0.4, GOLD, 0.2)
				fadeOut(b, 0.15)
			end
			if math.random() < 0.3 then
				local a = math.random() * math.pi * 2
				local p0 = gC + UP * 0.15
				local p1 = p0 + Vector3.new(math.cos(a), 0, math.sin(a)) * (6 + u * 20)
				streak(p0, p1, GOLD, 0.6, 0.4)
			end
		end)
		Fx.sound("ping", 0.8, 0.6, C)
		Fx.sound("swing", 0.9, 0.35, C)
	end)
	-- 함께 내지른다: 거대한 주먹이 80칸을 꿰뚫는다
	task.delay(T3, function()
		local big = fistGroup(3.4, 0)
		local fist = king.fists[2]
		local a0 = (fist and fist.Parent) and fist.CFrame.Position or (base + UP * 10)
		local a1 = gC + look * L + UP * 6
		local dir = (a1 - a0).Unit
		local core = beamTo(a0, a0 + dir * 0.5, 6, WHITE, 0)
		local glow = beamTo(a0, a0 + dir * 0.5, 16, GOLD, 0.4)
		local pt = T4 - T3
		local lastRing = 0
		anim(pt, function(u)
			local p = a0:Lerp(a1, u)
			gset(big, CFrame.lookAt(p, p + dir))
			setBeam(core, a0, p, 6)
			setBeam(glow, a0, p, 16)
			if u - lastRing > 0.1 then
				lastRing = u
				Fx.ring(p, GOLD, 6, 30, 0.4, dir)
			end
			if u >= 1 then
				gfade(big, 0.25)
				fadeOut(core, 0.5, { Size = Vector3.new(core.Size.X, 0.5, 0.5) })
				fadeOut(glow, 0.6, { Size = Vector3.new(glow.Size.X, 30, 30) })
			end
		end)
		streak(gC + UP * 0.2, ground(a1) + UP * 0.2, GOLD, 4, 1.0)
		Fx.flash(a0, WHITE, 160, 9, 0.4)
		Fx.breakSound("boom", 1.2, 0.4, C)
		shakeNear(C, 2.4, 300)
	end)
	-- 끝에서 왕관 모양으로 터진다
	task.delay(T5, function()
		local at = gC + look * L
		local cr = crownNew(10, 10, 12)
		anim(0.6, function(u)
			local y = -16 + 16 * math.min(1, u * 3)
			crownSet(cr, CFrame.new(at + UP * y) * CFrame.Angles(0, u * 2, 0), 10)
			if u >= 1 then
				crownFade(cr, 0.2)
			end
		end)
		pillar(at, GOLD, 20, 140, 0.9)
		bigBurst(at + UP * 3, 22, GOLD, CRIMSON)
		if graded then
			gradeTo(0.1, 0.2, 0.4, 0.1, Color3.fromRGB(255, 240, 200))
			task.delay(0.35, function()
				gradeReset(1.6)
			end)
		end
	end)
end
-- 왕의 주먹비: 하늘의 왕 쪽에서 금빛 주먹이 땅으로 내리꽂힌다
function H.kingRain(d: any)
	local at: Vector3 = d.at
	if not near(at, 320) then
		return
	end
	local from: Vector3 = d.from or (at + UP * 40)
	local fall = d.fall or 0.25
	local f = fistGroup(0.8, 0)
	local dir = (at - from).Unit
	anim(fall, function(u)
		local p = from:Lerp(at + UP * 2, u)
		gset(f, safeLook(p, p + dir))
		trailDot(p, 2.6, GOLD, 0.25)
		if u >= 1 then
			gfade(f, 0.12)
		end
	end)
	task.delay(fall, function()
		goldImpact(at, 0.9)
	end)
end

------------------------------------------------------------------------
-- 초 오의 컷씬 (쓴 사람 화면에서만, 대사 없이). 권법마다 카메라 길과 빛깔이 다르다
-- 윤회권: 앞쪽 낮은 곳에서 등 뒤 하늘의 바퀴를 올려다본다 · 업화권: 낮게 나를 돌며 솟는 불기둥을 본다
-- 무상권: 얼굴 가까이에서 흩어지는 몸을 보다가 멀리 물러선다 · 권왕신권: 앞에서 나와 등 뒤의 거대한 왕을 올려다본다
------------------------------------------------------------------------
local CUT_LOOK: { [string]: { any } } = {
	rinne = { Color3.fromRGB(40, 30, 90), GOLD, INDIGO },
	eophwa = { Color3.fromRGB(90, 10, 10), Color3.fromRGB(255, 150, 120), CHAR },
	musangkwon = { Color3.fromRGB(60, 70, 80), MIST, Color3.fromRGB(60, 110, 140) },
	kwonwangsin = { Color3.fromRGB(90, 60, 10), GOLD, CRIMSON },
}
local cutActive = false
function Samsara.superCut(model: Model, dur: number, name: string, shake: ((number) -> ())?, sid: string)
	local cam = workspace.CurrentCamera
	local r = rootOf(model)
	local player = game:GetService("Players").LocalPlayer
	if not cam or not r or cutActive or not player then
		return
	end
	cutActive = true
	local lk = CUT_LOOK[sid] or CUT_LOOK.rinne
	local g = Instance.new("ScreenGui")
	g.Name = "KwonRebirthCut"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 85
	g.Parent = player:WaitForChild("PlayerGui")
	local tintF = Instance.new("Frame")
	tintF.Size = UDim2.fromScale(1, 1)
	tintF.BackgroundColor3 = lk[1]
	tintF.BackgroundTransparency = 1
	tintF.BorderSizePixel = 0
	tintF.Parent = g
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.4, 1), NumberSequenceKeypoint.new(0.6, 1), NumberSequenceKeypoint.new(1, 0.1) })
	grad.Parent = tintF
	tween(tintF, 0.3, { BackgroundTransparency = 0.4 })
	local bars: { Frame } = {}
	for i, y in ipairs({ 0, 1 }) do
		local b = Instance.new("Frame")
		b.AnchorPoint = Vector2.new(0, y)
		b.Position = UDim2.fromScale(0, y)
		b.Size = UDim2.new(1, 0, 0, 0)
		b.BackgroundColor3 = Color3.new(0, 0, 0)
		b.BorderSizePixel = 0
		b.ZIndex = 5
		b.Parent = g
		tween(b, 0.15, { Size = UDim2.new(1, 0, 0.14, 0) })
		bars[i] = b
	end
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(1, 0.5)
	label.Position = UDim2.new(1, -30, 0.5, 0)
	label.Size = UDim2.new(0.5, 0, 0.45, 0)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.Text = "초 오의 · " .. name
	label.TextColor3 = lk[2]
	label.TextStrokeColor3 = lk[3]
	label.TextStrokeTransparency = 0.2
	label.TextTransparency = 1
	label.ZIndex = 6
	label.Parent = bars[2]
	tween(label, 0.25, { TextTransparency = 0 })
	local oldType = cam.CameraType
	local oldFov = cam.FieldOfView
	local look = flat(r.CFrame.LookVector)
	local side = Vector3.new(-look.Z, 0, look.X)
	cam.CameraType = Enum.CameraType.Scriptable
	local t0 = os.clock()
	local focus = r.Position
	local finished = false
	local function restore()
		if finished then
			return
		end
		finished = true
		RunService:UnbindFromRenderStep("KwonRebirthCut")
		cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
		cam.FieldOfView = oldFov
		cutActive = false
		local function behind()
			if r.Parent then
				local lv = flat(r.CFrame.LookVector)
				cam.CFrame = CFrame.lookAt(r.Position - lv * 24 + UP * 13, r.Position + lv * 6 + UP * 6)
			end
		end
		behind()
		task.defer(behind)
		for _, b in ipairs(bars) do
			tween(b, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
		end
		tween(tintF, 0.25, { BackgroundTransparency = 1 })
		tween(label, 0.2, { TextTransparency = 1 })
		task.delay(0.3, function()
			g:Destroy()
		end)
	end
	RunService:BindToRenderStep("KwonRebirthCut", Enum.RenderPriority.Camera.Value + 2, function(dt: number)
		if finished then
			return
		end
		if not r.Parent then
			restore()
			return
		end
		local t = os.clock() - t0
		local k = math.clamp(t / dur, 0, 1)
		focus = focus:Lerp(r.Position, math.min(1, dt * 10))
		local e = 1 - (1 - k) ^ 2
		local eye, target
		if sid == "eophwa" then
			local a = e * math.rad(200) - math.rad(30)
			eye = focus + (look * math.cos(a) + side * math.sin(a)) * (12 + e * 5) + UP * (0.8 + e * 2.5)
			target = focus + UP * (4 + e * 6)
		elseif sid == "musangkwon" then
			eye = focus + look * (3 + e * 16) + side * e * 4 + UP * (1.5 + e * 10)
			target = focus + UP * (1.5 + e * 7)
		elseif sid == "kwonwangsin" then
			eye = focus + look * (10 + e * 8) + side * (4 - e * 2) + UP * (0.5 + e * 1.5)
			target = focus - look * 14 + UP * (8 + e * 22)
		else
			eye = focus + look * (9 + e * 6) + side * math.sin(e * 0.8) * 6 + UP * (0.6 + e * 2.5)
			target = focus - look * 40 + UP * (16 + e * 20)
		end
		cam.CFrame = CFrame.lookAt(eye, target)
		cam.FieldOfView = oldFov + e * 12
		if t >= dur then
			restore()
		end
	end)
	if shake then
		task.delay(dur * 0.55, function()
			shake(0.8)
		end)
	end
	task.delay(dur + 1, restore)
end

------------------------------------------------------------------------
-- 3.1판 윤회대: 거대한 윤회륜과 구름 소용돌이가 천천히 돈다 (환생 의식 동안은 빠르게)
------------------------------------------------------------------------
type Spinner = { center: CFrame, items: { { any } }, angle: number, speed: number, axis: string }
local spinners: { [string]: Spinner } = {}
local spinBoostUntil = 0
local function findSpinner(name: string, center: CFrame, axis: string, speed: number)
	if spinners[name] then
		return
	end
	local f = workspace:FindFirstChild(name, true)
	if not f then
		return
	end
	local items = {}
	for _, d in ipairs(f:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(items, { d, center:ToObjectSpace(d.CFrame) })
		end
	end
	spinners[name] = { center = center, items = items, angle = 0, speed = speed, axis = axis }
end
local lastLook = 0
RunService.Heartbeat:Connect(function(dt: number)
	local cam = workspace.CurrentCamera
	local rd = Config.SKY_BY_ID and Config.SKY_BY_ID.rinnedae
	if not cam or not rd then
		return
	end
	if (cam.CFrame.Position - rd.at).Magnitude > 700 then
		return
	end
	if os.clock() - lastLook > 2 then
		lastLook = os.clock()
		local hub = workspace:FindFirstChild("RinneHub", true)
		if hub and hub:IsA("BasePart") then
			findSpinner("RinneWheel", CFrame.new(hub.Position), "x", 0.25)
		end
		findSpinner("RinneVortex", CFrame.new(rd.at), "y", 0.06)
	end
	local boost = os.clock() < spinBoostUntil and 14 or 1
	for _, sp in pairs(spinners) do
		sp.angle += dt * sp.speed * (sp.axis == "x" and boost or 1)
		local rot = sp.axis == "x" and CFrame.Angles(sp.angle, 0, 0) or CFrame.Angles(0, sp.angle, 0)
		local base = sp.center * rot
		for _, it in ipairs(sp.items) do
			local p = it[1] :: BasePart
			if p.Parent then
				p.CFrame = base * (it[2] :: CFrame)
			end
		end
	end
end)

-- 환생 의식: 하늘에서 빛기둥이 내려오고, 바퀴가 빠르게 돌고, 몸이 떠올라 빛으로 흩어졌다가 다시 태어난다
function Samsara.rite(d: any)
	local at: Vector3 = d.at
	local dur = d.dur or 3.4
	spinBoostUntil = os.clock() + dur
	if not near(at, 600) then
		return
	end
	local RB = Config.REBIRTH
	local col = (RB and RB.colors and RB.colors[d.n or 1]) or Color3.fromRGB(200, 180, 255)
	if opts.tint then
		opts.tint(Color3.fromRGB(220, 205, 255), 0.35, dur + 0.4)
	end
	-- 하늘에서 내려오는 빛기둥
	local top = at + Vector3.new(0, 400, 0)
	local beam = part(Vector3.new(1, 2, 2), WHITE, Enum.Material.Neon, 0.1, "cyl")
	local halo = part(Vector3.new(1, 6, 6), col, Enum.Material.Neon, 0.55, "cyl")
	anim(0.45, function(u)
		local h = 400 * u
		beam.Size = Vector3.new(h, 4, 4)
		beam.CFrame = CFrame.new(top - Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		halo.Size = Vector3.new(h, 11, 11)
		halo.CFrame = beam.CFrame
	end)
	Fx.breakSound("boom", 0.8, 0.5, at)
	-- 떠오르는 동안 빛 고리가 기둥을 타고 오르고, 빛 가루가 몸으로 빨려 든다
	for k = 0, 7 do
		task.delay(0.3 + k * 0.17, function()
			Fx.ring(at - Vector3.new(0, 3, 0) + Vector3.new(0, k * 1.2, 0), k % 2 == 0 and col or WHITE, 4, 22, 0.5)
		end)
	end
	local m = d.m
	anim(1.6, function(u)
		if math.random() < 0.6 then
			local r = rootOf(m)
			local c = r and r.Position or at
			local a = math.random() * math.pi * 2
			local from = c + Vector3.new(math.cos(a) * 14, math.random() * 10 - 3, math.sin(a) * 14)
			local mote = part(Vector3.new(0.6, 0.6, 0.6), math.random() < 0.5 and col or WHITE, Enum.Material.Neon, 0.1, "ball")
			mote.Position = from
			tween(mote, 0.4, { Position = c, Size = Vector3.new(0.1, 0.1, 0.1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.42, function()
				mote:Destroy()
			end)
		end
		if u >= 1 then
			-- 몸이 빛으로 흩어진다
			local r = rootOf(m)
			local c = r and r.Position or at
			if m and m.Parent then
				Fx.afterimage(m, WHITE, 0.5)
			end
			for _ = 1, 28 do
				local mote = part(Vector3.new(0.5, 0.5, 0.5), math.random() < 0.5 and col or WHITE, Enum.Material.Neon, 0.05, "ball")
				mote.Position = c + Vector3.new(math.random() - 0.5, math.random() * 2 - 1, math.random() - 0.5) * 2
				fadeOut(mote, 0.8, { Position = mote.Position + Vector3.new(math.random() * 16 - 8, math.random() * 14, math.random() * 16 - 8) })
			end
			Fx.burst("glitter", c, col, 30, 2)
			Fx.flash(c, col, 40, 5, 0.5)
			Fx.sound("deflect", 0.8, 0.5, c)
			shakeNear(c, 0.6, 120)
		end
	end)
	-- 다시 태어난다: 빛이 모여 번쩍, 큰 고리
	task.delay(2.4, function()
		for _ = 1, 20 do
			local a = math.random() * math.pi * 2
			local from = at + Vector3.new(math.cos(a) * 12, math.random() * 12 - 2, math.sin(a) * 12)
			local mote = part(Vector3.new(0.6, 0.6, 0.6), col, Enum.Material.Neon, 0.05, "ball")
			mote.Position = from
			tween(mote, 0.22, { Position = at, Size = Vector3.new(0.1, 0.1, 0.1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.24, function()
				mote:Destroy()
			end)
		end
		task.delay(0.24, function()
			Fx.blast(at, col, WHITE, 2.4)
			Fx.ring(at - Vector3.new(0, 3, 0), col, 6, 90, 0.9)
			Fx.ring(at - Vector3.new(0, 2.5, 0), WHITE, 4, 60, 0.7)
			Fx.flash(at, WHITE, 90, 7, 0.9)
			Fx.breakSound("boom", 1, 0.45, at)
			shakeNear(at, 1.4, 200)
			fadeOut(beam, 0.6, { Size = Vector3.new(400, 0.3, 0.3) })
			fadeOut(halo, 0.6, { Size = Vector3.new(400, 30, 30) })
		end)
	end)
end

local PULSE: { [string]: string } = { echo = "echoPulse", karma = "karmaPulse", phantom = "phantomPulse", king = "kingPulse" }
function Samsara.handles(data: any): boolean
	if data.kind == "pulse" then
		return PULSE[data.fx or ""] ~= nil
	end
	return H[data.kind] ~= nil
end
function Samsara.run(data: any)
	local fn = data.kind == "pulse" and H[PULSE[data.fx or ""] or ""] or H[data.kind]
	if fn then
		fn(data)
	end
end

return Samsara
