-- 권왕 3.0판: 환생 권법 넷 (윤회권 · 업화권 · 무상권 · 권왕신권) 의 몸에 두르는 것과 기술 (화면)
-- 윤회권: 등 뒤의 금빛 윤회륜 · 업화권: 두 팔의 달군 사슬과 검은 불꽃 · 무상권: 몸 둘레의 넋불과 안개 띠
-- 권왕신권: 머리 위의 금빛 관 · 붉은 망토 · 금빛 팔찌
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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
type Moving = { weld: Weld, base: CFrame, kind: string, phase: number, model: Model, k: number? }
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

function Samsara.hasGear(st: any): boolean
	return st ~= nil and (st.wheel or st.chains or st.wisps or st.crown) == true
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

-- 윤회륜 (E): 바퀴가 세워진 채 구르며 앞으로 갔다가 주인에게 되돌아온다. 지나간 땅에 금빛 바퀴 자국과 불티
function H.wheelThrow(d: any)
	local m = d.m
	local from: Vector3 = d.from
	local dir: Vector3 = flat(d.dir)
	local time = d.time or 1.2
	hideWheel(m, time + 0.1)
	if not near(from, 300) then
		return
	end
	local R = 2.8
	local w = wheelGroup(R, 0.32)
	local light = part(Vector3.new(0.2, 0.2, 0.2), GOLD, Enum.Material.Neon, 1)
	local pl = Instance.new("PointLight")
	pl.Color = GOLD
	pl.Range = 14
	pl.Brightness = 2
	pl.Parent = light
	local lastMark = 0
	local lastSound = 0
	local mid = false
	anim(time, function(u)
		local r = rootOf(m)
		local owner = r and r.Position or from
		local pos = from:Lerp(owner, u) + dir * (d.dist * math.sin(u * math.pi)) + Vector3.new(0, R - 2.5, 0)
		local cf = CFrame.fromMatrix(pos, dir, Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, -u * math.pi * 9)
		gset(w, cf)
		light.CFrame = CFrame.new(pos)
		local now = os.clock()
		if now - lastMark > 0.04 then
			lastMark = now
			local g = Vector3.new(pos.X, pos.Y - R + 0.15, pos.Z)
			local mark = part(Vector3.new(0.5, 0.12, 1.6), GOLD, Enum.Material.Neon, 0.2)
			mark.CFrame = CFrame.lookAt(g, g + dir)
			fadeOut(mark, 0.5)
			Fx.burst("spark", g, GOLD, 2, 0.8)
		end
		if now - lastSound > 0.25 then
			lastSound = now
			Fx.breakSound("whoosh", 0.4, 1.2, pos)
		end
		if not mid and u >= 0.5 then
			mid = true
			Fx.ring(pos, GOLD, 2, 16, 0.4, dir)
		end
		if u >= 1 then
			gfade(w, 0.15)
			light:Destroy()
			Fx.ring(pos, INDIGO, 1, 8, 0.3)
		end
	end)
end

-- 전생보 (R): 내달린 길에 금빛 줄, 지난 삶의 그림자 둘이 같은 길을 차례로 다시 내달려 벤다
function H.pastStep(d: any)
	local a: Vector3, b: Vector3 = d.from, d.to
	if not near(a, 300) then
		return
	end
	local m = d.m
	local dir = flat(b - a)
	streak(ground(a) + Vector3.new(0, 0.2, 0), ground(b) + Vector3.new(0, 0.2, 0), GOLD, 1.2, 0.8)
	for k = 0, 3 do
		task.delay(k * 0.04, function()
			if m and m.Parent then
				Fx.afterimage(m, k % 2 == 0 and INDIGO or GOLD, 0.45)
			end
		end)
	end
	for e = 1, d.echoes or 2 do
		task.delay((d.delay or 0.4) + (e - 1) * (d.gap or 0.3), function()
			if not (m and m.Parent) then
				return
			end
			local g = ghostOf(m, e == 1 and INDIGO or Color3.fromRGB(90, 60, 200), 0.4)
			local yaw = CFrame.lookAt(a, a + dir)
			anim(0.16, function(u)
				local p = a:Lerp(b, u)
				gset(g, yaw.Rotation + p)
				if u >= 1 then
					gfade(g, 0.35)
				end
			end)
			task.delay(0.12, function()
				-- 길을 따라 긋는 쪽빛 칼자국과 바퀴 고리
				local mid = (a + b) / 2
				local slash = part(Vector3.new(0.25, 3.2, (b - a).Magnitude), INDIGO, Enum.Material.Neon, 0.1)
				slash.CFrame = CFrame.lookAt(mid, b) * CFrame.Angles(0, 0, math.rad(e == 1 and 30 or -30))
				fadeOut(slash, 0.35, { Size = Vector3.new(0.05, 0.6, (b - a).Magnitude) })
				Fx.ring(b, GOLD, 1, 10, 0.3)
				Fx.sound("swing", 0.6, 0.8 + e * 0.15, mid)
			end)
		end)
	end
end

-- 육도윤회 (오의): 하늘에 뜬 거대한 바퀴, 여섯 구슬이 빛기둥으로 떨어지고, 바퀴가 땅에 누워 갈며 돌다가 터진다
function H.sixRealms(d: any)
	local m = d.m
	local center: Vector3 = d.at
	local r = rootOf(m)
	local look = r and flat(r.CFrame.LookVector) or Vector3.new(0, 0, -1)
	local right = Vector3.new(-look.Z, 0, look.X)
	local rise, every, slam, grind = d.rise or 0.55, d.every or 0.22, d.slam or 2, d.grind or 1.2
	hideWheel(m, slam + grind + 0.3)
	if not near(center, 400) then
		return
	end
	local R = 13
	local w = wheelGroup(R, 1.1, 0)
	galpha(w, 1)
	local skyPos = center + Vector3.new(0, 24, 0) - look * 6
	local orbsGone: { [number]: boolean } = {}
	-- 구슬 여섯은 따로 (떨어져 나갈 때 감춘다)
	local orbIdx: { [number]: BasePart } = {}
	local n = #w.items
	for k = 1, 6 do
		orbIdx[k] = w.items[n - 6 + k][1]
	end
	if opts.tint then
		opts.tint(Color3.fromRGB(200, 185, 255), 0.25, slam + grind + 0.4)
	end
	local total = slam + grind
	local landed = false
	local light = part(Vector3.new(0.2, 0.2, 0.2), GOLD, Enum.Material.Neon, 1)
	local pl = Instance.new("PointLight")
	pl.Color = GOLD
	pl.Range = 40
	pl.Brightness = 2
	pl.Parent = light
	anim(total, function(u)
		local t = u * total
		local cf
		if t < slam - 0.3 then
			-- 떠오르며 드러나고 천천히 돈다 (세워진 채, 나를 향해)
			local k = math.clamp(t / rise, 0, 1)
			local pos = (center + Vector3.new(0, 4, 0)):Lerp(skyPos, 1 - (1 - k) ^ 2)
			cf = CFrame.fromMatrix(pos, right, Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, t * 0.8)
			galpha(w, 1 - k)
		elseif t < slam then
			-- 눕듯 기울며 땅으로 내려앉는다
			local k = (t - (slam - 0.3)) / 0.3
			local pos = skyPos:Lerp(ground(center) + Vector3.new(0, 1.2, 0), k * k)
			cf = CFrame.fromMatrix(pos, right, Vector3.new(0, 1, 0)) * CFrame.Angles(-math.rad(90) * k, 0, 0) * CFrame.Angles(0, 0, t * 0.8)
			galpha(w, 0)
		else
			if not landed then
				landed = true
				Fx.ring(ground(center) + Vector3.new(0, 0.4, 0), GOLD, 4, 60, 0.7)
				Fx.ring(ground(center) + Vector3.new(0, 0.5, 0), INDIGO, 2, 40, 0.8)
				Fx.debris(ground(center), 16, 45)
				Fx.breakSound("boom", 1, 0.7, center)
				shakeNear(center, 1.4, 160)
			end
			local spin = (t - slam) * 9
			cf = CFrame.fromMatrix(ground(center) + Vector3.new(0, 1.2, 0), right, Vector3.new(0, 1, 0)) * CFrame.Angles(-math.rad(90), 0, 0) * CFrame.Angles(0, 0, slam * 0.8 + spin)
			if math.random() < 0.6 then
				local a = math.random() * math.pi * 2
				Fx.burst("spark", ground(center) + Vector3.new(math.cos(a) * R, 1, math.sin(a) * R), GOLD, 3, 1.2)
			end
		end
		gset(w, cf)
		for k, p in pairs(orbIdx) do
			if orbsGone[k] then
				p.Transparency = 1
			end
		end
		light.CFrame = cf
		if u >= 1 then
			light:Destroy()
			gfade(w, 0.4)
			Fx.blast(ground(center) + Vector3.new(0, 2, 0), INDIGO, GOLD, 3)
			Fx.ring(ground(center) + Vector3.new(0, 0.5, 0), GOLD, 6, (d.radius or 24) * 2.6, 0.8)
			Fx.flash(center, GOLD, 80, 6, 0.8)
			shakeNear(center, 1.8, 200)
		end
	end)
	-- 여섯 구슬이 떨어져 빛기둥으로 꽂힌다
	for k = 1, 6 do
		local spot: Vector3? = d.spots and d.spots[k]
		if spot then
			task.delay(rise + (k - 1) * every, function()
				orbsGone[k] = true
				local col = REALMS[k]
				local orbFrom = CFrame.fromMatrix(skyPos, right, Vector3.new(0, 1, 0)) * orbOffset(R, k)
				local orb = part(Vector3.new(2.6, 2.6, 2.6), col, Enum.Material.Neon, 0, "ball")
				anim(0.12, function(u)
					orb.Position = orbFrom:Lerp(spot, u)
					if u >= 1 then
						orb:Destroy()
					end
				end)
				task.delay(0.12, function()
					pillar(ground(spot), col, 5, 60, 0.6)
					Fx.ring(ground(spot) + Vector3.new(0, 0.3, 0), col, 2, 18, 0.45)
					Fx.burst("glitter", spot, col, 14, 1.4)
					Fx.sound("deflect", 0.7, 0.7 + k * 0.08, spot)
					shakeNear(spot, 0.5, 100)
				end)
			end)
		end
	end
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

-- 업화탄 (E): 주먹 사이에서 검은 불덩이 셋이 피어 적을 쫓아 날아가 붉게 터진다
function H.karmaOrbs(d: any)
	local m = d.m
	local r = rootOf(m)
	if not r or not near(r.Position, 300) then
		return
	end
	local origin = r.Position + flat(r.CFrame.LookVector) * 2 + Vector3.new(0, 1, 0)
	Fx.burst("ember", origin, EMBER, 12, 1.2)
	for i = 1, #(d.points or {}) do
		task.delay((d.delay or 0.2) + (i - 1) * 0.04, function()
			local core = part(Vector3.new(1.8, 1.8, 1.8), CHAR, Enum.Material.SmoothPlastic, 0, "ball")
			local shell = part(Vector3.new(2.6, 2.6, 2.6), EMBER, Enum.Material.Neon, 0.45, "ball")
			local fire = emitter(core, TEX_FIRE, Color3.fromRGB(255, 80, 30), CHAR, 40, 1.6, 0.3, 2, 0.5)
			fire.Acceleration = Vector3.new(0, 4, 0)
			local tgt = d.targets and d.targets[i]
			local side = (i - 2) * 6
			local travel = d.travel or 0.4
			anim(travel, function(u)
				local tr = tgt and rootOf(tgt)
				local to = tr and tr.Position or d.points[i]
				local mid = (origin + to) / 2 + Vector3.new(0, 6, 0) + Vector3.new(-(to - origin).Z, 0, (to - origin).X).Unit * side * 0.3
				local p = origin:Lerp(mid, u):Lerp(mid:Lerp(to, u), u)
				core.Position = p
				shell.Position = p
				if u >= 1 then
					core:Destroy()
					shell:Destroy()
					local boom = part(Vector3.new(2, 2, 2), EMBER, Enum.Material.Neon, 0.1, "ball")
					boom.Position = to
					fadeOut(boom, 0.35, { Size = Vector3.new(12, 12, 12) })
					local soot = part(Vector3.new(3, 3, 3), CHAR, Enum.Material.SmoothPlastic, 0.3, "ball")
					soot.Position = to
					fadeOut(soot, 0.6, { Size = Vector3.new(10, 10, 10), Position = to + Vector3.new(0, 3, 0) })
					Fx.ring(ground(to) + Vector3.new(0, 0.3, 0), HELL, 1, 14, 0.4)
					Fx.burst("ember", to, EMBER, 14, 1.4)
					Fx.breakSound("boom", 0.7, 1.0, to)
					shakeNear(to, 0.4, 80)
				end
			end)
		end)
	end
end

-- 겁화보 (R): 내달린 길이 갈라져 2초 동안 검은 불로 타고, 마지막에 불기둥이 줄지어 치솟는다
function H.hellTrail(d: any)
	local a: Vector3, b: Vector3 = d.from, d.to
	if not near(a, 300) then
		return
	end
	local m = d.m
	for k = 0, 4 do
		task.delay(k * 0.04, function()
			if m and m.Parent then
				Fx.afterimage(m, k % 2 == 0 and HELL or CHAR, 0.4)
			end
		end)
	end
	local dir = flat(b - a)
	local len = (b - a).Magnitude
	local dur = d.dur or 2
	task.delay(d.delay or 0.15, function()
		-- 그을린 땅과 갈라진 붉은 금
		local scorch = part(Vector3.new(d.width * 1.6, 0.1, len), CHAR, Enum.Material.SmoothPlastic, 0.15)
		scorch.CFrame = CFrame.lookAt((ground(a) + ground(b)) / 2 + Vector3.new(0, 0.1, 0), ground(b) + Vector3.new(0, 0.1, 0))
		task.delay(dur, function()
			fadeOut(scorch, 0.6)
		end)
		local zig = {}
		for i = 0, 8 do
			local p = ground(a):Lerp(ground(b), i / 8) + Vector3.new(-dir.Z, 0, dir.X) * (i % 2 == 0 and 0.8 or -0.8) + Vector3.new(0, 0.18, 0)
			table.insert(zig, p)
		end
		for i = 1, #zig - 1 do
			local s = part(Vector3.new(0.5, 0.1, (zig[i + 1] - zig[i]).Magnitude + 0.2), EMBER, Enum.Material.Neon, 0.05)
			s.CFrame = CFrame.lookAt((zig[i] + zig[i + 1]) / 2, zig[i + 1])
			task.delay(dur, function()
				fadeOut(s, 0.4)
			end)
		end
		-- 길 위의 불꽃
		for i = 1, 6 do
			local p = ground(a):Lerp(ground(b), (i - 0.5) / 6) + Vector3.new(0, 0.5, 0)
			local base = part(Vector3.new(0.4, 0.4, 0.4), EMBER, Enum.Material.Neon, 1)
			base.Position = p
			local e = emitter(base, TEX_FIRE, Color3.fromRGB(255, 90, 30), CHAR, 30, 2.6, 0.6, 5, 0.5)
			e.Acceleration = Vector3.new(0, 8, 0)
			task.delay(dur, function()
				e.Enabled = false
				task.delay(0.7, function()
					base:Destroy()
				end)
			end)
		end
		task.delay(dur, function()
			for i = 1, 7 do
				task.delay((i - 1) * 0.04, function()
					hellPillar(a:Lerp(b, (i - 1) / 6), 16, 4.5, 0.45)
				end)
			end
			Fx.breakSound("boom", 0.9, 0.9, (a + b) / 2)
			shakeNear((a + b) / 2, 0.8, 120)
		end)
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

-- 무간지옥 (오의): 갈라진 땅, 세 겹으로 퍼져 솟는 지옥불, 땅속에서 솟은 거대한 손이 가운데를 움켜쥐고 터뜨린다
function H.avici(d: any)
	local center: Vector3 = d.at
	if not near(center, 400) then
		return
	end
	local R = d.radius or 26
	local delay, every, waves = d.delay or 0.4, d.every or 0.35, d.waves or 3
	local handAt, grab = d.handAt or 0.35, d.grab or 0.6
	if opts.tint then
		opts.tint(Color3.fromRGB(255, 120, 110), 0.3, delay + waves * every + handAt + grab + 0.4)
	end
	-- 내리친 자리에서 사방으로 갈라진다
	local g = ground(center)
	local pit = part(Vector3.new(0.1, 1, 1), CHAR, Enum.Material.SmoothPlastic, 0.1, "cyl")
	pit.CFrame = CFrame.new(g + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(pit, delay + 0.3, { Size = Vector3.new(0.1, R * 2, R * 2) })
	local glow = part(Vector3.new(0.12, 1, 1), HELL, Enum.Material.Neon, 0.55, "cyl")
	glow.CFrame = CFrame.new(g + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(glow, delay + 0.3, { Size = Vector3.new(0.12, R * 1.6, R * 1.6) })
	local life = delay + waves * every + handAt + grab + 0.3
	task.delay(life, function()
		fadeOut(pit, 0.6)
		fadeOut(glow, 0.6)
	end)
	for k = 0, 11 do
		crack(center, R * 0.9, k / 12 * math.pi * 2, life)
	end
	shakeNear(center, 0.8, 140)
	Fx.breakSound("rock", 1, 0.6, center)
	-- 세 겹 불기둥
	for w = 1, waves do
		task.delay(delay + (w - 1) * every, function()
			local rr = R * w / waves
			local n = 5 + w * 4
			for i = 0, n - 1 do
				local a = i / n * math.pi * 2 + w * 0.3
				hellPillar(center + Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr), 14 + w * 4, 3.4, 0.5)
			end
			Fx.ring(g + Vector3.new(0, 0.4, 0), EMBER, rr * 0.6, rr * 2.2, 0.4)
			Fx.breakSound("boom", 0.8, 0.8 + w * 0.1, center)
			shakeNear(center, 0.6, 140)
		end)
	end
	-- 땅속에서 솟는 거대한 손
	local T = delay + waves * every + handAt
	task.delay(T - 0.35, function()
		local s = 2.6
		local hg, fingers = hellHand(s)
		local cam = workspace.CurrentCamera
		local face = cam and flat(cam.CFrame.Position - center) or Vector3.new(0, 0, 1)
		local fire: { ParticleEmitter } = {}
		for _, it in ipairs(hg.items) do
			local p = it[1] :: BasePart
			if p.Material == Enum.Material.SmoothPlastic and #fire < 3 then
				local e = emitter(p, TEX_FIRE, Color3.fromRGB(255, 80, 30), CHAR, 40, 5, 0.6, 6, 0.5)
				e.Acceleration = Vector3.new(0, 10, 0)
				table.insert(fire, e)
			end
		end
		local base = CFrame.lookAt(g, g - face)
		anim(0.35 + grab, function(u)
			local t = u * (0.35 + grab)
			local rise = math.clamp(t / 0.35, 0, 1)
			local curl = t < 0.35 and math.rad(-8) or math.rad(-8 + 115 * math.clamp((t - 0.35) / grab, 0, 1) ^ 0.6)
			local cf = base * CFrame.new(0, -16 * s + rise * 16 * s + 3 * s, 0) * CFrame.Angles(math.rad(-8), 0, 0)
			setHand(hg, fingers, cf, curl, s)
			if u >= 1 then
				gfade(hg, 0.4)
				for _, fg in ipairs(fingers) do
					for i = 1, 3 do
						local p = fg[i]
						if p then
							fadeOut(p, 0.4)
						end
					end
				end
				for _, e in ipairs(fire) do
					e.Enabled = false
				end
				-- 움켜쥔 손 안에서 터진다
				Fx.blast(center + Vector3.new(0, 6, 0), HELL, EMBER, 3.2)
				hellPillar(center, 50, 12, 0.7)
				Fx.ring(g + Vector3.new(0, 0.5, 0), EMBER, 4, R * 2.6, 0.7)
				Fx.flash(center, EMBER, 90, 6, 0.8)
				Fx.breakSound("boom", 1, 0.6, center)
				shakeNear(center, 2, 220)
			end
		end)
		Fx.debris(g, 20, 50)
		Fx.breakSound("rock", 1, 0.5, center)
	end)
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

-- 무상영 (E): 안개가 되어 적의 등 뒤로 차례로 나타난다. 지나간 자리마다 흐릿한 잔상과 푸른 칼빛
function H.phantomBlink(d: any)
	local m = d.m
	local prev: Vector3 = d.from
	if not near(prev, 300) then
		return
	end
	mistPuff(prev, 4, 0.6)
	for i, t in ipairs(d.targets or {}) do
		task.delay((d.delay or 0.08) + (i - 1) * (d.every or 0.22), function()
			local tr = rootOf(t)
			if not tr then
				return
			end
			local to = tr.Position
			if m and m.Parent then
				local g, cf0 = ghostOf(m, MIST, 0.5, Enum.Material.SmoothPlastic)
				gset(g, cf0)
				gfade(g, 0.5)
			end
			streak(prev, to, GHOST, 0.35, 0.35, 0.35)
			slashX(to, GHOST, 8, 0.3)
			mistPuff(to, 3, 0.5)
			Fx.ring(to, GHOST, 1, 12, 0.3)
			Fx.sound("swing", 0.7, 1.2 + i * 0.1, to)
			prev = to
		end)
	end
end

-- 허상 (R): 몸이 안개로 흩어지고 둘레에 허상 셋. 허상 둘레로 안개가 빨려 들다가 허상이 안개로 터진다
function H.illusions(d: any)
	local m = d.m
	local center: Vector3 = d.at
	if not near(center, 300) then
		return
	end
	mistPuff(center, 5, 0.7)
	Fx.sound("deflect", 0.6, 0.6, center)
	local hold = d.hold or 1.2
	local ghosts: { Group } = {}
	if m and m.Parent then
		for _, spot in ipairs(d.spots or {}) do
			local g, cf0 = ghostOf(m, MIST:Lerp(GHOST, 0.3), 0.45, Enum.Material.SmoothPlastic)
			local face = flat(spot - center)
			local base = CFrame.lookAt(Vector3.new(spot.X, cf0.Position.Y, spot.Z), Vector3.new(spot.X, cf0.Position.Y, spot.Z) + face)
			table.insert(ghosts, g)
			anim(hold, function(u)
				gset(g, base * CFrame.new(0, math.sin(u * math.pi * 4) * 0.3, 0))
				if math.random() < 0.15 then
					local a = math.random() * math.pi * 2
					local from = spot + Vector3.new(math.cos(a) * 9, math.random() * 3, math.sin(a) * 9)
					local mote = part(Vector3.new(0.6, 0.6, 0.6), GHOST, Enum.Material.Neon, 0.2, "ball")
					mote.Position = from
					tween(mote, 0.35, { Position = spot, Size = Vector3.new(0.1, 0.1, 0.1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					task.delay(0.36, function()
						mote:Destroy()
					end)
				end
			end)
		end
	end
	task.delay(hold, function()
		for i, g in ipairs(ghosts) do
			gfade(g, 0.2)
			local spot = d.spots[i]
			mistPuff(spot, 6, 0.7)
			Fx.ring(spot, GHOST, 1, 20, 0.4)
			for _ = 1, 6 do
				local sh = part(Vector3.new(0.4, 1.4, 0.1), MIST, Enum.Material.Glass, 0.2)
				sh.CFrame = CFrame.new(spot) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
				fadeOut(sh, 0.5, { CFrame = sh.CFrame + Vector3.new(math.random() * 8 - 4, math.random() * 5, math.random() * 8 - 4) })
			end
		end
		Fx.breakSound("glass", 0.6, 1.3, center)
		shakeNear(center, 0.6, 100)
	end)
end

-- 제행무상 (오의): 세상이 잿빛으로 멈춘다. 일곱 그림자가 일곱 적에게 덮쳐 엇갈려 베고, 하나로 모이며 안개 물결로 터진다
function H.allPasses(d: any)
	local m = d.m
	local center: Vector3 = d.at
	if not near(center, 400) then
		return
	end
	local delay, strikes, every, converge = d.delay or 0.6, d.strikes or 3, d.every or 0.18, d.converge or 0.4
	local total = delay + strikes * every + converge
	if opts.tint then
		opts.tint(Color3.fromRGB(175, 180, 190), 0.6, total)
	end
	mistPuff(center, 6, 0.8)
	-- 발밑의 잿빛 물결
	local still = part(Vector3.new(0.1, 1, 1), MIST, Enum.Material.SmoothPlastic, 0.6, "cyl")
	still.CFrame = CFrame.new(ground(center) + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(still, delay, { Size = Vector3.new(0.1, (d.radius or 26) * 2, (d.radius or 26) * 2) })
	task.delay(total, function()
		fadeOut(still, 0.4)
	end)
	if not (m and m.Parent) then
		return
	end
	local ghosts = {}
	for i, spot in ipairs(d.spots or {}) do
		local g, cf0 = ghostOf(m, i % 2 == 0 and GHOST or MIST, 0.4, Enum.Material.Neon)
		local y = cf0.Position.Y
		local to = Vector3.new(spot.X, y, spot.Z)
		local from = Vector3.new(center.X, y, center.Z)
		local face = flat(to - from)
		table.insert(ghosts, { g = g, from = from, to = to, face = face })
		task.delay(delay * 0.6, function()
			anim(delay * 0.4, function(u)
				local p = from:Lerp(to - face * 2.5, u * u)
				gset(g, CFrame.lookAt(p, p + face))
			end)
		end)
	end
	for k = 1, strikes do
		task.delay(delay + (k - 1) * every, function()
			for _, gh in ipairs(ghosts) do
				slashX(gh.to, k % 2 == 0 and WHITE or GHOST, 8, 0.25)
				if k == 1 then
					mistPuff(gh.to, 2.5, 0.4)
				end
			end
			Fx.sound("swing", 0.8, 1 + k * 0.15, center)
			shakeNear(center, 0.4, 120)
		end)
	end
	task.delay(delay + strikes * every, function()
		for _, gh in ipairs(ghosts) do
			local from = gh.to - gh.face * 2.5
			anim(converge, function(u)
				local p = from:Lerp(gh.from, u * u)
				gset(gh.g, CFrame.lookAt(p, p + gh.face))
				if u >= 1 then
					gfade(gh.g, 0.1)
				end
			end)
		end
	end)
	task.delay(total, function()
		local g = ground(center)
		local wave = part(Vector3.new(4, 2, 2), MIST, Enum.Material.SmoothPlastic, 0.35, "cyl")
		wave.CFrame = CFrame.new(g + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		fadeOut(wave, 0.7, { Size = Vector3.new(1, (d.radius or 26) * 2.4, (d.radius or 26) * 2.4) })
		Fx.ring(g + Vector3.new(0, 0.4, 0), GHOST, 3, (d.radius or 26) * 2.4, 0.6)
		Fx.ring(g + Vector3.new(0, 2, 0), WHITE, 2, (d.radius or 26) * 1.6, 0.5)
		Fx.blast(center, GHOST, MIST, 2.4)
		Fx.flash(center, GHOST, 70, 5, 0.6)
		Fx.breakSound("glass", 0.8, 0.8, center)
		shakeNear(center, 1.6, 200)
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
		gset(g, CFrame.lookAt(p, p - Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)))
		if u >= 1 then
			gfade(g, 0.3)
			mark:Destroy()
			goldImpact(at, 0.6)
		end
	end)
end

-- 왕권 (E): 등 뒤에 집채만 한 금빛 주먹이 나타나 앞으로 곧게 내지르고, 반 박자 뒤 반대쪽 주먹이 한 번 더
function H.kingFist(d: any)
	local from: Vector3 = d.from
	if not near(from, 320) then
		return
	end
	local dir = flat(d.dir)
	local right = Vector3.new(-dir.Z, 0, dir.X)
	for k = 0, 1 do
		local side = k == 0 and 1 or -1
		task.delay((d.delay or 0.3) - 0.2 + k * (d.second or 0.35), function()
			local g = fistGroup(0.9, 0)
			local start = from - dir * 4 + right * side * 5 + Vector3.new(0, 4, 0)
			local stop = from + dir * (d.length or 30) + right * side * 1.5 + Vector3.new(0, 1, 0)
			galpha(g, 1)
			anim(0.2, function(u)
				gset(g, CFrame.lookAt(start, start + dir))
				galpha(g, 1 - u)
			end)
			task.delay(0.2, function()
				local lastRing = 0
				anim(0.18, function(u)
					local p = start:Lerp(stop, 1 - (1 - u) ^ 3)
					gset(g, CFrame.lookAt(p, p + dir))
					if u - lastRing > 0.25 then
						lastRing = u
						Fx.ring(p, GOLD, 3, 14, 0.3, dir)
					end
					if u >= 1 then
						gfade(g, 0.35)
						Fx.blast(stop, GOLD, CRIMSON, 1.6)
						Fx.breakSound("boom", 0.8, 1.0, stop)
						shakeNear(stop, 0.8, 120)
					end
				end)
				streak(ground(start) + Vector3.new(0, 0.2, 0), ground(stop) + Vector3.new(0, 0.2, 0), GOLD, 2.4, 0.5)
				Fx.breakSound("whoosh", 0.8, 0.7, from)
			end)
		end)
	end
end

-- 왕도 (R): 발밑에서 앞으로 금빛 길이 깔리고, 길을 따라 금빛 기둥이 차례로 솟는다
function H.royalRoad(d: any)
	local a: Vector3, b: Vector3 = d.from, d.to
	if not near(a, 320) then
		return
	end
	local m = d.m
	local dir = flat(b - a)
	local len = (b - a).Magnitude
	local run = d.run or 0.35
	local w = d.width or 6
	local ga = ground(a) + Vector3.new(0, 0.15, 0)
	local carpet = part(Vector3.new(w, 0.2, 0.1), GOLD, Enum.Material.Metal, 0)
	local edges = { part(Vector3.new(0.5, 0.25, 0.1), CRIMSON, Enum.Material.Fabric), part(Vector3.new(0.5, 0.25, 0.1), CRIMSON, Enum.Material.Fabric) }
	local right = Vector3.new(-dir.Z, 0, dir.X)
	anim(run, function(u)
		local L = math.max(0.1, len * u)
		local c = ga + dir * (L / 2)
		carpet.Size = Vector3.new(w, 0.2, L)
		carpet.CFrame = CFrame.lookAt(c, c + dir)
		for i, e in ipairs(edges) do
			e.Size = Vector3.new(0.5, 0.25, L)
			e.CFrame = CFrame.lookAt(c + right * (i == 1 and 1 or -1) * (w / 2 + 0.25), c + right * (i == 1 and 1 or -1) * (w / 2 + 0.25) + dir)
		end
		if m and m.Parent and math.random() < 0.5 then
			Fx.afterimage(m, GOLD, 0.35)
		end
	end)
	task.delay(run + (d.pillars or 6) * (d.step or 0.08) + 0.6, function()
		fadeOut(carpet, 0.5)
		for _, e in ipairs(edges) do
			fadeOut(e, 0.5)
		end
	end)
	for i = 1, d.pillars or 6 do
		task.delay(run + i * (d.step or 0.08), function()
			local pt = a:Lerp(b, i / (d.pillars or 6))
			pillar(ground(pt), GOLD, 4, 22, 0.5)
			Fx.ring(ground(pt) + Vector3.new(0, 0.3, 0), GOLD, 1, 12, 0.35)
			Fx.burst("spark", pt, GOLD, 8, 1.2)
			Fx.sound("deflect", 0.5, 0.8 + i * 0.06, pt)
		end)
	end
	shakeNear(a, 0.5, 100)
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
local kings: { [Model]: { king: King, base: CFrame, s: number } } = {}

-- 권왕강림 (오의): 등 뒤에서 관을 쓴 거대한 금빛 왕이 일어선다
function H.kingDescend(d: any)
	local m = d.m
	local center: Vector3 = d.at
	if not near(center, 400) then
		return
	end
	local dir = flat(d.dir)
	local s = 1.6
	local king = kingGroup(s)
	local stand = CFrame.lookAt(ground(center) - dir * 12, ground(center) - dir * 12 + dir)
	local rise = d.rise or 0.7
	local total = rise + (d.punches or 3) * (d.every or 0.45) + (d.finalAt or 0.5)
	kings[m] = { king = king, base = stand, s = s }
	if opts.tint then
		opts.tint(Color3.fromRGB(255, 230, 160), 0.3, total + 0.3)
	end
	Fx.debris(ground(center) - dir * 12, 14, 40)
	Fx.breakSound("rock", 1, 0.6, center)
	local light = part(Vector3.new(0.2, 0.2, 0.2), GOLD, Enum.Material.Neon, 1)
	local pl = Instance.new("PointLight")
	pl.Color = GOLD
	pl.Range = 50
	pl.Brightness = 2
	pl.Parent = light
	anim(total, function(u)
		local t = u * total
		local k = math.clamp(t / rise, 0, 1)
		local cf = stand * CFrame.new(0, -24 * s * (1 - k) ^ 2, 0)
		gset(king.g, cf)
		galpha(king.g, 1 - math.min(1, k * 1.5))
		light.CFrame = cf * CFrame.new(0, 12 * s, 0)
		if u >= 1 then
			light:Destroy()
		end
	end)
	shakeNear(center, 1, 160)
	-- 마지막: 두 주먹을 한꺼번에 내리꽂는다
	task.delay(total, function()
		for _, f in ipairs(king.fists) do
			f.Transparency = 1
		end
		local g = ground(center)
		for _, x in ipairs({ -1, 1 }) do
			local fg = fistGroup(1.3, 0)
			local start = (stand * CFrame.new(x * 9 * s, 14 * s, -6 * s)).Position
			local stop = g + dir * 4 + Vector3.new(-dir.Z, 0, dir.X) * x * 5 + Vector3.new(0, 3, 0)
			anim(0.2, function(u)
				local p = start:Lerp(stop, u * u)
				gset(fg, CFrame.lookAt(p, p + Vector3.new(0, -1, 0), dir))
				if u >= 1 then
					gfade(fg, 0.5)
				end
			end)
		end
		task.delay(0.2, function()
			local R = d.radius or 30
			Fx.ring(g + Vector3.new(0, 0.5, 0), GOLD, 6, R * 2.6, 0.8)
			Fx.ring(g + Vector3.new(0, 1.5, 0), CRIMSON, 4, R * 2, 0.7)
			Fx.ring(g + Vector3.new(0, 4, 0), WHITE, 2, R * 1.4, 0.5)
			Fx.blast(g + Vector3.new(0, 3, 0), GOLD, CRIMSON, 3.4)
			Fx.debris(g, 24, 60)
			Fx.flash(center, GOLD, 100, 7, 0.9)
			Fx.breakSound("boom", 1, 0.55, center)
			shakeNear(center, 2.2, 240)
			gfade(king.g, 0.7)
			kings[m] = nil
		end)
	end)
end
-- 왕이 고른 적을 내리찍는다 (그쪽 주먹이 내려왔다가 돌아간다)
function H.kingPunch(d: any)
	local k = kings[d.m]
	local at: Vector3 = d.at
	if not near(at, 400) then
		return
	end
	local s = k and k.s or 1.6
	local fistPart = k and k.king.fists[(d.side or 1) == -1 and 1 or 2]
	local start = (k and fistPart) and fistPart.Position or (at + Vector3.new(0, 30, 0))
	if fistPart then
		fistPart.Transparency = 1
	end
	local fg = fistGroup(0.95 * s / 1.6, 0)
	anim(0.16, function(u)
		local p = start:Lerp(at + Vector3.new(0, 3, 0), u * u)
		gset(fg, CFrame.lookAt(p, p + Vector3.new(0, -1, 0), flat(d.dir)))
		if u >= 1 then
			gfade(fg, 0.3)
			goldImpact(at, 1.2)
			task.delay(0.2, function()
				if fistPart and fistPart.Parent then
					fistPart.Transparency = 0
				end
			end)
		end
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
