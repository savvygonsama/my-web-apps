-- 권왕: 초월 권법 초·매화난무권의 화면 (벚꽃 부채, 흩날리는 꽃잎, 천본앵, 초 오의 만앵참월)
-- 벚꽃이 늘 앞에 서도록: 부채에서 꽃잎이 끊임없이 흘러내리고, 모든 기술이 꽃잎의 궤적을 남긴다
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Sakura = {}
local player = Players.LocalPlayer

local PINKS = {
	Color3.fromRGB(255, 168, 204),
	Color3.fromRGB(255, 196, 222),
	Color3.fromRGB(255, 224, 238),
	Color3.fromRGB(255, 140, 188),
	Color3.fromRGB(255, 246, 250),
}
local PINK = Color3.fromRGB(255, 150, 200)
local PINK_DEEP = Color3.fromRGB(240, 90, 150)
local WHITE = Color3.new(1, 1, 1)
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local folder = Instance.new("Folder")
folder.Name = "KwonSakura"
folder.Parent = workspace

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function rootOf(m: Instance?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
end
local function pinkAt(i: number?): Color3
	return PINKS[((i or math.random(1, 99)) % #PINKS) + 1]
end

-- 떠다니는 조각 (물리 없음)
local function part(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, ell: boolean?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = alpha or 0
	if ell then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	p.Parent = folder
	return p
end

------------------------------------------------------------------------
-- 꽃잎: 납작한 타원 조각이 팔랑이며 흩날린다 (한꺼번에 너무 많지 않게)
------------------------------------------------------------------------
local live = 0
local MAX_PETALS = 420
function Sakura.petals(pos: Vector3, n: number, spread: number, life: number, push: Vector3?, size: number?)
	local k = size or 1
	for _ = 1, n do
		if live >= MAX_PETALS then
			return
		end
		live += 1
		local p = part(Vector3.new(0.8, 0.07, 0.55) * k, pinkAt(), Enum.Material.SmoothPlastic, 0, true)
		local from = pos + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * spread * 0.4
		p.CFrame = CFrame.new(from) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		local drift = (push or Vector3.zero) + Vector3.new(math.random() - 0.5, math.random() * 0.6 - 0.1, math.random() - 0.5) * spread
		local l = life * (0.7 + math.random() * 0.6)
		tween(p, l, { CFrame = CFrame.new(from + drift - Vector3.new(0, l * 1.2, 0)) * CFrame.Angles(math.random() * 12, math.random() * 12, math.random() * 12), Transparency = 1 }, Enum.EasingStyle.Sine)
		task.delay(l, function()
			live -= 1
			p:Destroy()
		end)
	end
end
-- 꽃잎 입자 (가볍게 많이)
local function petalEmitter(parent: Instance, rate: number, size: number, speed: number, life: number): ParticleEmitter
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = TEX_SPARK
	pe.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, PINKS[3]), ColorSequenceKeypoint.new(0.5, PINKS[1]), ColorSequenceKeypoint.new(1, PINKS[4]) })
	pe.LightEmission = 0.4
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 0.6) })
	pe.Squash = NumberSequence.new(0.5)
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.8, 0.3), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(life * 0.7, life)
	pe.Rate = rate
	pe.Speed = NumberRange.new(speed * 0.4, speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-180, 180)
	pe.Acceleration = Vector3.new(0, -2, 0)
	pe.Drag = 1.5
	pe.Parent = parent
	return pe
end

------------------------------------------------------------------------
-- 벚꽃 부채: 손에 쥔 손잡이에서 열한 개의 살이 퍼지고, 살 사이에 분홍 부채 면, 면 위에 다섯 잎 꽃
------------------------------------------------------------------------
local fans: { [Model]: { Instance } } = {}
local function weldTo(p: BasePart, hand: BasePart, cf: CFrame)
	p.Massless = true
	p.CFrame = hand.CFrame * cf
	local w = Instance.new("WeldConstraint")
	w.Part0 = hand
	w.Part1 = p
	w.Parent = p
	p.Anchored = false
end
local function buildFan(model: Model, hand: BasePart, side: number): { Instance }
	local out: { Instance } = {}
	local s = 1.0
	local base = CFrame.new(0, -0.35, 0) * CFrame.Angles(0, side * math.rad(12), 0)
	-- 부채 조각은 몸 밖의 폴더에 둔다 (몸의 조각을 도는 다른 효과가 부채까지 건드리지 않게). 용접으로 손을 따라간다
	local holder = Instance.new("Folder")
	holder.Name = "Fan_" .. model.Name
	holder.Parent = folder
	table.insert(out, holder)
	local function add(size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, alpha: number?, ell: boolean?): Part
		local p = part(size * s, color, mat, alpha, ell)
		weldTo(p, hand, base * cf)
		p.Parent = holder
		table.insert(out, p)
		return p
	end
	local wood = Color3.fromRGB(70, 40, 30)
	local gold = Color3.fromRGB(240, 200, 120)
	add(Vector3.new(0.22, 0.4, 0.22), CFrame.new(0, 0.05, 0), wood, Enum.Material.Wood)
	add(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0, 0.28, 0), gold, Enum.Material.Metal, 0, true)
	local R0, R1, L = 0.5, 2.2, 2.3
	local n = 11
	local spanA = math.rad(150)
	for i = 0, n - 1 do
		local th = -spanA / 2 + spanA * i / (n - 1)
		add(Vector3.new(0.06, L, 0.05), CFrame.Angles(0, 0, th) * CFrame.new(0, -L / 2, 0), wood, Enum.Material.Wood)
		if i < n - 1 then
			local tm = th + spanA / (n - 1) / 2
			local rm = (R0 + R1) / 2
			local w = 2 * rm * math.sin(spanA / (n - 1) / 2) * 1.12
			local col = PINKS[(i % 3) + 1]:Lerp(WHITE, (i % 2) * 0.15)
			add(Vector3.new(w, R1 - R0, 0.03), CFrame.Angles(0, 0, tm) * CFrame.new(0, -rm, 0.02), col, Enum.Material.SmoothPlastic)
			-- 바깥 테 (짙은 분홍)
			add(Vector3.new(w * 1.05, 0.12, 0.04), CFrame.Angles(0, 0, tm) * CFrame.new(0, -R1, 0.02), PINK_DEEP, Enum.Material.SmoothPlastic)
		end
	end
	-- 부채 면 위의 벚꽃 세 송이 (다섯 잎 + 금빛 꽃술)
	for k, at in ipairs({ { -0.5, 1.55 }, { 0.55, 1.35 }, { 0.05, 1.9 } }) do
		local c = CFrame.Angles(0, 0, at[1]) * CFrame.new(0, -at[2], 0.06)
		for j = 0, 4 do
			local a = j / 5 * math.pi * 2
			add(Vector3.new(0.26, 0.2, 0.02), c * CFrame.Angles(0, 0, a) * CFrame.new(0, 0.13, 0), k == 2 and WHITE or PINKS[4], Enum.Material.SmoothPlastic, 0, true)
		end
		add(Vector3.new(0.09, 0.09, 0.03), c, gold, Enum.Material.Neon, 0, true)
	end
	-- 부채 끝에서 꽃잎이 끊임없이 흘러내린다
	local tip = add(Vector3.new(0.1, 0.1, 0.1), CFrame.new(0, -R1, 0), WHITE, nil, 1)
	petalEmitter(tip, 9, 0.35, 1.5, 1.6)
	local glow = Instance.new("PointLight")
	glow.Color = PINK
	glow.Range = 7
	glow.Brightness = 0.6
	glow.Parent = tip
	return out
end
local function clearFans(model: Model)
	local list = fans[model]
	if list then
		for _, p in ipairs(list) do
			p:Destroy()
		end
		fans[model] = nil
	end
end
local builtFor: { [Model]: string } = {}
local waiting: { [Model]: boolean } = {}
local tryFans: (Model) -> ()
local function refreshFans(model: Model)
	local id = model:GetAttribute("Style")
	local st = type(id) == "string" and Config.STYLE_BY_ID[id] or nil
	if not st or not st.fans then
		clearFans(model)
		builtFor[model] = nil
		return
	end
	-- 같은 권법이면 다시 만들지 않는다
	if builtFor[model] == st.id and fans[model] then
		return
	end
	clearFans(model)
	builtFor[model] = st.id
	-- 먼저 자리를 잡아 둔다 (같은 몸을 두 번 만들지 않게)
	local list: { Instance } = {}
	fans[model] = list
	for _, pair in ipairs({ { "RightHand", 1 }, { "LeftHand", -1 } }) do
		local hand = model:FindFirstChild(pair[1])
		if hand and hand:IsA("BasePart") then
			for _, p in ipairs(buildFan(model, hand, pair[2])) do
				table.insert(list, p)
			end
		end
	end
end
-- 부채 권법일 때만 손이 생기기를 기다렸다가 만든다 (다른 몸은 기다리지 않는다)
function tryFans(model: Model)
	local id = model:GetAttribute("Style")
	local st = type(id) == "string" and Config.STYLE_BY_ID[id] or nil
	if not st or not st.fans then
		refreshFans(model)
		return
	end
	if builtFor[model] == st.id and fans[model] or waiting[model] then
		return
	end
	waiting[model] = true
	task.spawn(function()
		model:WaitForChild("RightHand", 10)
		model:WaitForChild("LeftHand", 10)
		waiting[model] = nil
		refreshFans(model)
	end)
end
local watched: { [Model]: boolean } = {}
function Sakura.watch(model: Model)
	if watched[model] then
		return
	end
	watched[model] = true
	tryFans(model)
	model:GetAttributeChangedSignal("Style"):Connect(function()
		tryFans(model)
	end)
	-- 사라지는 기술 (만앵참월 등) 동안 부채도 감춘다
	model:GetAttributeChangedSignal("Vanish"):Connect(function()
		local hide = model:GetAttribute("Vanish") == true
		for _, p in ipairs(fans[model] or {}) do
			if p:IsA("BasePart") then
				p.LocalTransparencyModifier = hide and 1 or 0
			end
		end
	end)
	model.AncestryChanged:Connect(function()
		if not model.Parent then
			clearFans(model)
			watched[model] = nil
			builtFor[model] = nil
		end
	end)
end
-- 폴더 안의 모든 몸 (사부·적)
function Sakura.watchFolder(f: Instance)
	for _, m in ipairs(f:GetChildren()) do
		if m:IsA("Model") then
			Sakura.watch(m)
		end
	end
	f.ChildAdded:Connect(function(m)
		if m:IsA("Model") then
			Sakura.watch(m)
		end
	end)
end

-- 부채를 든 사람은 걸을 때마다 발밑에 꽃잎이 흩날린다
local walkAcc = 0
RunService.Heartbeat:Connect(function(dt)
	walkAcc += dt
	if walkAcc < 0.25 then
		return
	end
	walkAcc = 0
	for model in pairs(fans) do
		local r = rootOf(model)
		if r and near(r.Position, 110) and model:GetAttribute("Vanish") ~= true then
			local v = r.AssemblyLinearVelocity
			local moving = Vector3.new(v.X, 0, v.Z).Magnitude > 3
			Sakura.petals(r.Position + Vector3.new(0, moving and -1.5 or 1, 0), moving and 4 or 1, moving and 4 or 3, moving and 1.2 or 1.8, moving and -v * 0.15 or nil)
		end
	end
end)

------------------------------------------------------------------------
-- 기술마다 꽃잎의 궤적: 부채가 지나간 반달 모양 칼자국과 그 길을 따라 흩어지는 꽃잎
------------------------------------------------------------------------
local function crescent(cf: CFrame, radius: number, color: Color3, life: number, thick: number?)
	local segs = 9
	for i = 0, segs - 1 do
		local a = -1.1 + 2.2 * i / (segs - 1)
		local pos = cf * Vector3.new(math.sin(a) * radius, 0, -math.cos(a) * radius)
		local nxt = cf * Vector3.new(math.sin(a + 0.25) * radius, 0, -math.cos(a + 0.25) * radius)
		local w = (1 - math.abs(a) / 1.2) * (thick or 0.5) + 0.05
		local p = part(Vector3.new(w, w * 0.3, (nxt - pos).Magnitude * 1.2), i % 2 == 0 and color or WHITE, Enum.Material.Neon, 0.15, true)
		p.CFrame = CFrame.lookAt(pos, nxt)
		tween(p, life, { Transparency = 1, Size = p.Size * Vector3.new(0.3, 0.3, 1.3) })
		Debris:AddItem(p, life + 0.05)
	end
end
function Sakura.cast(styleId: any, slot: any, model: Model, dur: number)
	local st = type(styleId) == "string" and Config.STYLE_BY_ID[styleId] or nil
	if not st or not st.fans then
		return
	end
	local r = rootOf(model)
	if not r or not near(r.Position, 160) then
		return
	end
	local look = r.CFrame
	if type(slot) == "number" or slot == "H" or slot == "F" then
		-- 연타·강타: 앞쪽으로 반달 칼자국 하나 (강타는 크게), 꽃잎이 그 길을 따라
		local big = slot == "H"
		task.delay(math.min(0.12, dur * 0.35), function()
			local cf = look * CFrame.new(0, 0.6, -1) * CFrame.Angles(0, 0, (type(slot) == "number" and slot % 2 == 0) and 0.5 or -0.5)
			crescent(cf, big and 7 or 4.5, PINK, big and 0.4 or 0.28, big and 0.9 or 0.5)
			Sakura.petals((look * CFrame.new(0, 0.5, -3)).Position, big and 18 or 8, big and 8 or 5, 1.1, look.LookVector * (big and 10 or 5))
		end)
	elseif slot == "E" then
		Sakura.petals(r.Position, 30, 10, 1.6)
		for i = 0, 2 do
			task.delay(i * 0.18, function()
				crescent(r.CFrame * CFrame.Angles(0, i * 2.1, 0), 6, PINKS[i + 1], 0.35, 0.6)
			end)
		end
	elseif slot == "R" then
		Sakura.petals(r.Position, 24, 6, 1.4)
	elseif slot == "G" or slot == "X" then
		Sakura.petals(r.Position + Vector3.new(0, 2, 0), 50, 14, 2.2)
		Fx.ring(r.Position - Vector3.new(0, 2.4, 0), PINK, 2, 30, 0.7)
	end
end

------------------------------------------------------------------------
-- 천본앵 (G): 둘레가 벚꽃 칼바람의 소용돌이. 세 겹의 꽃잎 고리가 돌며 좁아지고, 끝에 한가운데로 모여 터진다
------------------------------------------------------------------------
local storms: { [any]: any } = {}
local function stormRun(data: any)
	local m = data.m
	local r = rootOf(m)
	local center0 = data.at or (r and r.Position) or Vector3.zero
	if not near(center0, 300) then
		return
	end
	local radius = data.radius or 30
	local dur = data.dur or 3.5
	local rings = {}
	local blades = {}
	-- 세 겹의 꽃잎 고리 (안쪽일수록 빠르다)
	for ring = 1, 3 do
		local list = {}
		local count = 26 - ring * 4
		for i = 1, count do
			local p = part(Vector3.new(1.6, 0.1, 1.0) * (1.25 - ring * 0.12), pinkAt(i + ring), Enum.Material.SmoothPlastic, 0, true)
			table.insert(list, { p = p, a = i / count * math.pi * 2, h = (ring - 2) * 4 + math.random() * 2, spin = math.random() * 6 })
		end
		table.insert(rings, { list = list, r = radius * (0.35 + ring * 0.2), speed = (4.2 - ring) * 1.1 })
	end
	-- 칼날 같은 빛의 꽃잎 (길고 빛난다)
	for i = 1, 10 do
		local p = part(Vector3.new(0.35, 0.12, 4.2), i % 2 == 0 and WHITE or PINK, Enum.Material.Neon, 0.2, true)
		table.insert(blades, { p = p, a = i / 10 * math.pi * 2, h = math.random() * 6 - 1 })
	end
	-- 발밑의 꽃 진과 기둥처럼 솟는 꽃잎 회오리
	local disc = part(Vector3.new(0.2, radius * 2, radius * 2), PINK, Enum.Material.Neon, 0.75)
	disc.Shape = Enum.PartType.Cylinder
	disc.CFrame = CFrame.new(center0 - Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local column = part(Vector3.new(2, 2, 2), WHITE, nil, 1)
	column.Position = center0
	local pe = petalEmitter(column, 90, 0.7, 18, 2.2)
	pe.SpreadAngle = Vector2.new(25, 25)
	pe.Acceleration = Vector3.new(0, 10, 0)
	local light = Instance.new("PointLight")
	light.Color = PINK
	light.Range = 40
	light.Brightness = 2
	light.Parent = column
	Fx.sound("ping", 0.6, 0.6, center0)
	local t0 = os.clock()
	local key = {}
	storms[m or key] = { rings = rings, blades = blades, disc = disc, column = column }
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local rr = rootOf(m)
		local c = rr and rr.Position or center0
		local shrink = 1 - math.clamp(t / dur, 0, 1) * 0.35
		for _, ring in ipairs(rings) do
			for _, e in ipairs(ring.list) do
				local a = e.a + t * ring.speed
				local pos = c + Vector3.new(math.cos(a) * ring.r * shrink, e.h + math.sin(t * 3 + e.a) * 0.8, math.sin(a) * ring.r * shrink)
				e.p.CFrame = CFrame.new(pos) * CFrame.Angles(t * 4 + e.spin, a, t * 3)
			end
		end
		for _, b in ipairs(blades) do
			local a = b.a - t * 5
			local rad = radius * 0.55 * shrink
			local pos = c + Vector3.new(math.cos(a) * rad, b.h, math.sin(a) * rad)
			b.p.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(a), 0, math.cos(a)))
		end
		disc.CFrame = CFrame.new(c - Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, t * 0.8, math.rad(90))
		column.Position = c
		if t > dur + 0.6 then
			conn:Disconnect()
		end
	end)
	task.delay(dur + 0.7, function()
		local s = storms[m or key]
		if s then
			for _, ring in ipairs(s.rings) do
				for _, e in ipairs(ring.list) do
					e.p:Destroy()
				end
			end
			for _, b in ipairs(s.blades) do
				b.p:Destroy()
			end
			s.disc:Destroy()
			s.column:Destroy()
			storms[m or key] = nil
		end
	end)
end
local function stormBurst(data: any)
	local at = data.at
	if not at or not near(at, 300) then
		return
	end
	local radius = data.radius or 30
	-- 고리들이 한가운데로 모여든 뒤 꽃처럼 터진다
	for _, s in pairs(storms) do
		for _, ring in ipairs(s.rings) do
			for _, e in ipairs(ring.list) do
				tween(e.p, 0.22, { CFrame = CFrame.new(at + Vector3.new(0, 1, 0)), Transparency = 0.6 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			end
		end
	end
	task.delay(0.22, function()
		Fx.blast(at, PINK, WHITE, 3)
		Fx.flash(at, PINK, 80, 5, 0.6)
		Fx.ring(at - Vector3.new(0, 2.3, 0), PINK, 4, radius * 2.4, 0.6)
		Fx.ring(at + Vector3.new(0, 1, 0), WHITE, 2, radius * 1.6, 0.45)
		Sakura.petals(at + Vector3.new(0, 2, 0), 90, radius * 1.4, 2.4)
		-- 하늘로 솟는 꽃잎 기둥
		local col = part(Vector3.new(radius * 0.7, 60, radius * 0.7), PINKS[3], Enum.Material.Neon, 0.3)
		col.Shape = Enum.PartType.Cylinder
		col.Size = Vector3.new(60, radius * 0.7, radius * 0.7)
		col.CFrame = CFrame.new(at + Vector3.new(0, 28, 0)) * CFrame.Angles(0, 0, math.rad(90))
		tween(col, 0.7, { Size = Vector3.new(70, 0.5, 0.5), Transparency = 1 })
		Debris:AddItem(col, 0.75)
	end)
end

------------------------------------------------------------------------
-- 만앵참월 (X, 초 오의)
------------------------------------------------------------------------
local cuts: { [any]: { BasePart } } = {}
local grey: ColorCorrectionEffect? = nil
local function mineOrNear(data: any, d: number): boolean
	local me = player.Character
	if data.m and data.m == me then
		return true
	end
	local r = rootOf(me)
	return r ~= nil and data.at ~= nil and (r.Position - data.at).Magnitude < d
end
local function setGrey(on: boolean, time: number)
	if not grey then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "KwonSakuraGrey"
		cc.Parent = Lighting
		grey = cc
	end
	local cc = grey :: ColorCorrectionEffect
	tween(cc, time, { Saturation = on and -1 or 0, Contrast = on and 0.25 or 0, Brightness = on and -0.06 or 0, TintColor = on and Color3.fromRGB(235, 235, 240) or WHITE })
end

-- 화면 위의 큰 글자와 칼자국 (내 화면에서만)
local function screenGui(): ScreenGui
	local pg = player:WaitForChild("PlayerGui")
	local g = Instance.new("ScreenGui")
	g.Name = "KwonSever"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 80
	g.Parent = pg
	return g
end
local function bigName(name: string, life: number)
	local g = screenGui()
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.42)
	t.Size = UDim2.fromScale(0.8, 0.16)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.Text = name
	t.TextColor3 = Color3.fromRGB(255, 236, 246)
	t.TextTransparency = 1
	t.TextStrokeColor3 = PINK_DEEP
	t.TextStrokeTransparency = 1
	t.Parent = g
	local sub = t:Clone()
	sub.Position = UDim2.fromScale(0.5, 0.53)
	sub.Size = UDim2.fromScale(0.5, 0.05)
	sub.Text = "超 · 萬櫻斬月"
	sub.Parent = g
	tween(t, 0.25, { TextTransparency = 0, TextStrokeTransparency = 0.2 })
	tween(sub, 0.35, { TextTransparency = 0.1, TextStrokeTransparency = 0.4 })
	task.delay(life, function()
		tween(t, 0.3, { TextTransparency = 1, TextStrokeTransparency = 1 })
		tween(sub, 0.3, { TextTransparency = 1, TextStrokeTransparency = 1 })
		Debris:AddItem(g, 0.35)
	end)
end
-- 화면을 비스듬히 한칼에 가르고, 두 쪽이 갈라지며 빛이 새어 나온 뒤 다시 붙는다
local function screenSplit()
	local g = screenGui()
	local angle = -26
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = g
	local function band(color: Color3, alpha: number, thick: number, z: number): Frame
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.new(0, 0, 0, thick)
		f.Rotation = angle
		f.BorderSizePixel = 0
		f.BackgroundColor3 = color
		f.BackgroundTransparency = alpha
		f.ZIndex = z
		f.Parent = holder
		local gr = Instance.new("UIGradient")
		gr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) })
		gr.Parent = f
		return f
	end
	-- 두 쪽 (위·아래): 어둡게 비치는 큰 판이 칼자국을 따라 갈라진다
	local halves: { Frame } = {}
	for _, s in ipairs({ -1, 1 }) do
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, s < 0 and 1 or 0)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.fromScale(3, 3)
		f.Rotation = angle
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.fromRGB(20, 10, 16)
		f.BackgroundTransparency = 1
		f.ZIndex = 2
		f.Parent = holder
		table.insert(halves, f)
	end
	local glow = band(Color3.fromRGB(255, 120, 180), 0.2, 26, 3)
	local core = band(WHITE, 0, 6, 4)
	-- 1) 한 줄기 칼날이 화면을 가로지른다
	tween(glow, 0.09, { Size = UDim2.new(2.6, 0, 0, 26) }, Enum.EasingStyle.Quint)
	tween(core, 0.09, { Size = UDim2.new(2.6, 0, 0, 6) }, Enum.EasingStyle.Quint)
	task.delay(0.1, function()
		-- 2) 두 쪽이 갈라지며 틈으로 빛이 새어 나온다
		local rad = math.rad(angle)
		local nx, ny = -math.sin(rad), math.cos(rad)
		for i, f in ipairs(halves) do
			local s = i == 1 and -1 or 1
			f.BackgroundTransparency = 0.82
			tween(f, 0.28, { Position = UDim2.new(0.5, nx * 46 * s, 0.5, ny * 46 * s) }, Enum.EasingStyle.Back)
		end
		tween(glow, 0.28, { Size = UDim2.new(2.6, 0, 0, 120), BackgroundTransparency = 0.35 }, Enum.EasingStyle.Back)
		tween(core, 0.28, { Size = UDim2.new(2.6, 0, 0, 40) }, Enum.EasingStyle.Back)
	end)
	task.delay(0.55, function()
		-- 3) 다시 붙으며 사라진다
		for _, f in ipairs(halves) do
			tween(f, 0.35, { Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1 })
		end
		tween(glow, 0.45, { Size = UDim2.new(2.6, 0, 0, 0), BackgroundTransparency = 1 })
		tween(core, 0.45, { Size = UDim2.new(2.6, 0, 0, 0), BackgroundTransparency = 1 })
		Debris:AddItem(g, 0.5)
	end)
end

local function severCut(data: any)
	local from, to = data.from, data.to
	if not from or not to or not near(to, 300) then
		return
	end
	-- 지나간 길보다 길게, 가슴 높이에 비스듬히 남는 하늘의 칼자국
	local dir = to - from
	if dir.Magnitude < 0.5 then
		dir = Vector3.new(0, 0, -1)
	end
	local mid = (from + to) / 2 + Vector3.new(0, 1.5, 0)
	local len = dir.Magnitude + 14
	local cf = CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, 0, (math.random() - 0.5) * 1.6)
	local glow = part(Vector3.new(1.6, 0.25, len), PINK, Enum.Material.Neon, 0.35, true)
	glow.CFrame = cf
	local core = part(Vector3.new(0.45, 0.12, len * 0.98), WHITE, Enum.Material.Neon, 0, true)
	core.CFrame = cf
	glow.Size = Vector3.new(1.6, 0.25, 0.5)
	core.Size = Vector3.new(0.45, 0.12, 0.5)
	tween(glow, 0.08, { Size = Vector3.new(1.6, 0.25, len) })
	tween(core, 0.08, { Size = Vector3.new(0.45, 0.12, len * 0.98) })
	local key = data.style or "x"
	cuts[key] = cuts[key] or {}
	table.insert(cuts[key], glow)
	table.insert(cuts[key], core)
	Sakura.petals(data.at or to, 14, 5, 1.2, dir.Unit * 8)
	Fx.burst("spark", data.at or to, WHITE, 8, 1)
	Fx.sound("ping", 0.4, 1.8 + (data.i or 0) * 0.05, to)
	-- 오래 남지 않게 (끝을 못 보면 스스로 사라진다)
	Debris:AddItem(glow, 6)
	Debris:AddItem(core, 6)
end

local function severStill(data: any)
	if mineOrNear(data, 160) then
		setGrey(true, 0.12)
		if data.m == player.Character then
			bigName("만앵참월", (data.dur or 0.9) + 1.0)
		end
	end
	-- 멈춘 세상에서 칼자국만 숨 쉬듯 빛난다
	for _, list in pairs(cuts) do
		for _, p in ipairs(list) do
			if p.Parent then
				tween(p, 0.4, { Transparency = 0 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			end
		end
	end
	Fx.sound("ping", 0.7, 0.45, data.at)
end

local function severWind(data: any)
	local dur = data.dur or 1.3
	for _, m in ipairs(data.targets or {}) do
		local r = rootOf(m)
		if r and near(r.Position, 260) then
			-- 적마다 칼바람의 회오리: 도는 초승달 칼날 여섯, 솟구치는 꽃잎과 흰 바람
			local blades = {}
			for i = 1, 6 do
				local p = part(Vector3.new(0.3, 0.1, 3.6), i % 2 == 0 and WHITE or PINK, Enum.Material.Neon, 0.15, true)
				table.insert(blades, { p = p, a = i / 6 * math.pi * 2, h = (i % 3) * 1.4 - 1 })
			end
			local holder = part(Vector3.new(1, 1, 1), WHITE, nil, 1)
			holder.Position = r.Position
			local pe = petalEmitter(holder, 60, 0.55, 14, 1.0)
			pe.SpreadAngle = Vector2.new(30, 30)
			pe.Acceleration = Vector3.new(0, 18, 0)
			local t0 = os.clock()
			local conn
			conn = RunService.RenderStepped:Connect(function()
				local t = os.clock() - t0
				local rr = rootOf(m)
				local c = rr and rr.Position or holder.Position
				holder.Position = c
				for _, b in ipairs(blades) do
					local a = b.a + t * 9
					local rad = 3.2 + math.sin(t * 6 + b.a) * 0.6
					local pos = c + Vector3.new(math.cos(a) * rad, b.h + t * 1.2, math.sin(a) * rad)
					b.p.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(a), 0.3, math.cos(a)))
				end
				if t > dur then
					conn:Disconnect()
					for _, b in ipairs(blades) do
						b.p:Destroy()
					end
					pe.Enabled = false
					Debris:AddItem(holder, 1.2)
				end
			end)
		end
	end
end

local function severEnd(data: any)
	local at = data.at
	for _, m in ipairs(data.targets or {}) do
		local r = rootOf(m)
		if r and near(r.Position, 300) then
			Fx.blast(r.Position, PINK, WHITE, 2.6)
			Fx.flash(r.Position, PINK, 40, 4, 0.4)
			Sakura.petals(r.Position, 26, 12, 1.8)
		end
	end
	if at and near(at, 300) then
		Fx.ring(at - Vector3.new(0, 2.3, 0), PINK, 4, (data.radius or 22) * 2.6, 0.6)
		Fx.flash(at, WHITE, 90, 5, 0.5)
	end
	-- 하늘의 칼자국이 꽃잎으로 부서진다
	for key, list in pairs(cuts) do
		for _, p in ipairs(list) do
			if p.Parent then
				local pos = p.Position
				tween(p, 0.25, { Size = p.Size * Vector3.new(3, 3, 1.1), Transparency = 1 })
				Debris:AddItem(p, 0.3)
				Sakura.petals(pos, 8, p.Size.Z * 0.5, 1.6)
			end
		end
		cuts[key] = nil
	end
	if mineOrNear(data, 160) then
		-- 화면을 한칼에 가르고, 잿빛이 풀리며 분홍빛이 번진다
		screenSplit()
		task.delay(0.12, function()
			setGrey(false, 0.6)
		end)
	end
	Fx.sound("ping", 1, 0.35, at)
end

local function severStart(data: any)
	local r = rootOf(data.m)
	if r and near(r.Position, 300) then
		Sakura.petals(r.Position, 40, 6, 1.4)
		Fx.flash(r.Position, WHITE, 30, 3, 0.25)
	end
	-- 끝을 못 받더라도 잿빛은 스스로 풀린다
	task.delay((data.dur or 4) + 1.5, function()
		if grey and grey.Saturation < -0.1 then
			setGrey(false, 0.4)
		end
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	sakuraStorm = stormRun,
	sakuraBurst = stormBurst,
	severStart = severStart,
	severCut = severCut,
	severStill = severStill,
	severWind = severWind,
	severEnd = severEnd,
}
function Sakura.handles(kind: any): boolean
	return type(kind) == "string" and HANDLERS[kind] ~= nil
end
function Sakura.run(data: any)
	local h = HANDLERS[data.kind]
	if h then
		h(data)
	end
end

-- 초 오의를 펼칠 때 (내 화면): 화면 가장자리가 벚꽃빛으로 물들고, 꽃잎이 화면 가득 쏟아진다
function Sakura.superIntro(model: Model)
	local r = rootOf(model)
	if r then
		Sakura.petals(r.Position + Vector3.new(0, 3, 0), 60, 16, 2.4)
		Fx.sigil(r.Position - Vector3.new(0, 2.6, 0), 20, PINK, WHITE, 1.4)
	end
	local g = screenGui()
	local edge = Instance.new("Frame")
	edge.Size = UDim2.fromScale(1, 1)
	edge.BackgroundTransparency = 1
	edge.Parent = g
	local st = Instance.new("UIStroke")
	st.Color = PINK
	st.Thickness = 60
	st.Transparency = 0.2
	st.Parent = edge
	tween(st, 1.2, { Transparency = 1, Thickness = 10 })
	-- 화면 위로 흩날리는 꽃잎 (글자 대신 둥근 판)
	for i = 1, 26 do
		local p = Instance.new("Frame")
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Position = UDim2.fromScale(math.random(), -0.05)
		local s = math.random(10, 22)
		p.Size = UDim2.fromOffset(s, s * 0.65)
		p.Rotation = math.random(0, 360)
		p.BackgroundColor3 = pinkAt(i)
		p.BorderSizePixel = 0
		p.Parent = g
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(1, 0)
		cr.Parent = p
		tween(p, 1.4 + math.random(), { Position = UDim2.fromScale(math.random(), 1.05), Rotation = p.Rotation + math.random(-360, 360), BackgroundTransparency = 0.6 }, Enum.EasingStyle.Sine)
	end
	Debris:AddItem(g, 2.6)
end

return Sakura
