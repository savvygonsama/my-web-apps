-- 권왕: 로벅스 꾸미기 (금룡 기운)
-- 금빛 용 한 마리가 몸을 휘감고 돈다. 가만있으면 몸을 감아 오르내리고, 달리면 뒤를 따라 날며,
-- 대시하면 금빛 꼬리를 길게 남기고, 오의를 쓰면 하늘로 솟구쳐 포효한다. 모두의 화면에 보인다
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Cosmetics = {}

local folder = Instance.new("Folder")
folder.Name = "KwonCosmetics"
folder.Parent = workspace

local GOLD = Color3.fromRGB(255, 196, 64)
local GOLD_DEEP = Color3.fromRGB(196, 128, 24)
local GOLD_LIGHT = Color3.fromRGB(255, 244, 190)
local EYE = Color3.fromRGB(255, 90, 40)

local N = 22 -- 몸 마디 수
local SPACING = 0.72 -- 마디 사이
local SHOW_DIST = 170 -- 이보다 멀면 그리지 않는다

local function piece(size: Vector3, color: Color3, material: Enum.Material, shape: Enum.PartType?, trans: number?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.Transparency = trans or 0
	p.Parent = folder
	return p
end

type Dragon = {
	model: Model,
	parts: { BasePart },
	cores: { BasePart },
	shells: { BasePart },
	fins: { [number]: BasePart },
	sizes: { number },
	pos: { Vector3 },
	head: { { p: BasePart, off: CFrame } },
	jaw: BasePart,
	jawOff: CFrame,
	whiskers: { BasePart },
	headAnchor: BasePart,
	sparkle: ParticleEmitter,
	trail: Trail,
	t: number,
	headPos: Vector3,
	burstUntil: number,
	burstStart: number,
	dashUntil: number,
	visible: boolean,
}

local active: { [Model]: Dragon } = {}

local function rootOf(m: Model): BasePart?
	local r = m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 1e-3 and f.Unit or Vector3.new(0, 0, -1)
end

local function build(model: Model): Dragon?
	local root = rootOf(model)
	if not root then
		return nil
	end
	local d: Dragon = {
		model = model,
		parts = {},
		cores = {},
		shells = {},
		fins = {},
		sizes = {},
		pos = {},
		head = {},
		jaw = nil :: any,
		jawOff = CFrame.identity,
		whiskers = {},
		headAnchor = nil :: any,
		sparkle = nil :: any,
		trail = nil :: any,
		t = math.random() * 10,
		headPos = root.Position + Vector3.new(0, 2, 3),
		burstUntil = 0,
		burstStart = 0,
		dashUntil = 0,
		visible = true,
	}
	-- 몸: 빛나는 속살 + 금박 비늘 껍질, 두 마디마다 등지느러미
	for i = 1, N do
		local k = (i - 1) / (N - 1)
		local s = 0.95 - k * 0.62
		d.sizes[i] = s
		local core = piece(Vector3.new(s, s, s), GOLD, Enum.Material.Neon, Enum.PartType.Ball, 0.05)
		local shell = piece(Vector3.new(s * 1.18, s * 1.05, SPACING * 1.35), i % 2 == 0 and GOLD_DEEP or GOLD, Enum.Material.Foil, nil, 0.25)
		table.insert(d.cores, core)
		table.insert(d.shells, shell)
		table.insert(d.parts, core)
		table.insert(d.parts, shell)
		if i % 2 == 0 and i < N - 1 then
			local fin = piece(Vector3.new(0.08, s * 0.9, s * 0.6), GOLD_LIGHT, Enum.Material.Neon, nil, 0.1)
			d.fins[i] = fin
			table.insert(d.parts, fin)
		end
		d.pos[i] = d.headPos + Vector3.new(0, 0, i * SPACING)
	end
	-- 꼬리 끝 깃
	local tailFin = piece(Vector3.new(0.06, 0.9, 0.7), GOLD_LIGHT, Enum.Material.Neon, nil, 0.05)
	d.fins[N] = tailFin
	table.insert(d.parts, tailFin)
	-- 머리: 금박 머리뼈, 주둥이, 벌어지는 턱, 뿔 둘, 갈기, 붉은 눈, 길게 휘날리는 수염 둘
	local function headPart(size: Vector3, color: Color3, mat: Enum.Material, off: CFrame, shape: Enum.PartType?, trans: number?): BasePart
		local p = piece(size, color, mat, shape, trans)
		table.insert(d.head, { p = p, off = off })
		table.insert(d.parts, p)
		return p
	end
	d.headAnchor = headPart(Vector3.new(1.05, 0.8, 1.1), GOLD, Enum.Material.Foil, CFrame.identity)
	headPart(Vector3.new(0.78, 0.5, 0.95), GOLD, Enum.Material.Foil, CFrame.new(0, -0.08, -0.85))
	headPart(Vector3.new(0.5, 0.18, 0.3), GOLD_LIGHT, Enum.Material.Neon, CFrame.new(0, 0.1, -1.28))
	d.jawOff = CFrame.new(0, -0.38, -0.7)
	d.jaw = headPart(Vector3.new(0.66, 0.16, 0.9), GOLD_DEEP, Enum.Material.Foil, d.jawOff)
	for _, x in ipairs({ -1, 1 }) do
		headPart(Vector3.new(0.12, 0.12, 1.3), GOLD_LIGHT, Enum.Material.Neon, CFrame.new(x * 0.32, 0.42, 0.55) * CFrame.Angles(math.rad(28), x * math.rad(18), 0))
		headPart(Vector3.new(0.16, 0.1, 0.06), EYE, Enum.Material.Neon, CFrame.new(x * 0.3, 0.18, -0.52))
		headPart(Vector3.new(0.06, 0.5, 0.35), GOLD_LIGHT, Enum.Material.Neon, CFrame.new(x * 0.18, 0.35, 0.35) * CFrame.Angles(math.rad(-30), 0, x * math.rad(25)))
		local w = piece(Vector3.new(0.05, 0.05, 1.6), GOLD_LIGHT, Enum.Material.Neon, nil, 0.1)
		table.insert(d.whiskers, w)
		table.insert(d.parts, w)
	end
	-- 머리의 금빛 불티와 빛, 지나간 자리의 금빛 꼬리
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.35, 0)
	a0.Parent = d.headAnchor
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.35, 0)
	a1.Parent = d.headAnchor
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = 0.35
	tr.LightEmission = 1
	tr.FaceCamera = true
	tr.Color = ColorSequence.new(GOLD_LIGHT, GOLD)
	tr.Transparency = NumberSequence.new(0.35, 1)
	tr.WidthScale = NumberSequence.new(1, 0.1)
	tr.Parent = d.headAnchor
	d.trail = tr
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(GOLD_LIGHT, GOLD)
	e.LightEmission = 1
	e.Size = NumberSequence.new(0.25, 0)
	e.Lifetime = NumberRange.new(0.5, 1)
	e.Speed = NumberRange.new(0.5, 1.5)
	e.Rate = 10
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = a0
	d.sparkle = e
	local l = Instance.new("PointLight")
	l.Color = GOLD
	l.Range = 9
	l.Brightness = 1.3
	l.Parent = d.headAnchor
	return d
end

local function destroy(d: Dragon)
	for _, p in ipairs(d.parts) do
		p:Destroy()
	end
end

local function setVisible(d: Dragon, on: boolean)
	if d.visible == on then
		return
	end
	d.visible = on
	for _, p in ipairs(d.parts) do
		p.LocalTransparencyModifier = on and 0 or 1
	end
	d.sparkle.Enabled = on
	d.trail.Enabled = on
end

-- 한 장면: 머리가 갈 곳을 정하고, 마디가 줄줄이 따라온다
local function step(d: Dragon, dt: number, camPos: Vector3?)
	local root = rootOf(d.model)
	if not root then
		return
	end
	if camPos then
		setVisible(d, (camPos - root.Position).Magnitude < SHOW_DIST)
	end
	if not d.visible then
		return
	end
	d.t += dt
	local t = d.t
	local now = os.clock()
	local p0 = root.Position
	local vel = root.AssemblyLinearVelocity
	local moving = Vector3.new(vel.X, 0, vel.Z).Magnitude > 6
	local look = flat(root.CFrame.LookVector)
	local side = Vector3.new(-look.Z, 0, look.X)
	local target: Vector3
	local follow = 7
	if now < d.burstUntil then
		-- 오의: 나선을 그리며 하늘로 솟구친다
		local k = math.clamp((now - d.burstStart) / (d.burstUntil - d.burstStart), 0, 1)
		local a = t * 5
		local r = 4.5 + k * 3
		target = p0 + Vector3.new(math.cos(a) * r, 2 + k * 14, math.sin(a) * r)
		follow = 10
	elseif moving then
		-- 달릴 때: 뒤 위쪽에서 물결치듯 따라 난다
		target = p0 - look * 3.2 + side * math.sin(t * 2.2) * 1.4 + Vector3.new(0, 2.3 + math.sin(t * 3.1) * 0.6, 0)
		follow = 9
	else
		-- 가만있을 때: 몸을 감고 천천히 오르내린다
		local a = t * 1.5
		target = p0 + Vector3.new(math.cos(a) * 2.7, 0.3 + math.sin(t * 0.7) * 1.5, math.sin(a) * 2.7)
	end
	d.headPos = d.headPos:Lerp(target, 1 - math.exp(-dt * follow))
	-- 줄 잇기: 마디마다 앞 마디와 같은 거리를 지킨다
	d.pos[1] = d.headPos
	for i = 2, N do
		local dir = d.pos[i] - d.pos[i - 1]
		local m = dir.Magnitude
		if m > SPACING then
			d.pos[i] = d.pos[i - 1] + dir / m * SPACING
		elseif m < 1e-3 then
			d.pos[i] = d.pos[i - 1] + Vector3.new(0, 0, SPACING)
		end
	end
	local parts: { BasePart } = {}
	local cfs: { CFrame } = {}
	local function put(p: BasePart, cf: CFrame)
		table.insert(parts, p)
		table.insert(cfs, cf)
	end
	for i = 1, N do
		local here = d.pos[i]
		local ahead = i == 1 and (d.pos[1] + (d.pos[1] - d.pos[2])) or d.pos[i - 1]
		local cf = (ahead - here).Magnitude > 1e-3 and CFrame.lookAt(here, ahead) or CFrame.new(here)
		-- 몸이 살짝 꿈틀거린다
		cf = cf * CFrame.Angles(0, 0, math.sin(t * 4 - i * 0.5) * 0.25)
		put(d.cores[i], cf)
		put(d.shells[i], cf)
		local fin = d.fins[i]
		if fin then
			put(fin, cf * CFrame.new(0, d.sizes[i] * 0.62, 0) * CFrame.Angles(math.rad(-20), 0, 0))
		end
	end
	-- 머리 (첫 마디보다 조금 앞에)
	local fwd = d.pos[1] - d.pos[2]
	fwd = fwd.Magnitude > 1e-3 and fwd.Unit or look
	local hcf = CFrame.lookAt(d.headPos + fwd * 0.55, d.headPos + fwd * 2)
	local roaring = now < d.burstUntil and now > d.burstUntil - 0.6
	for _, h in ipairs(d.head) do
		if h.p == d.jaw then
			local open = roaring and 0.6 or (0.12 + math.sin(t * 2) * 0.08)
			put(h.p, hcf * d.jawOff * CFrame.Angles(open, 0, 0))
		else
			put(h.p, hcf * h.off)
		end
	end
	-- 수염: 입가에서 뒤로 휘날린다
	for i, w in ipairs(d.whiskers) do
		local x = i == 1 and -1 or 1
		local from = (hcf * CFrame.new(x * 0.34, -0.12, -1.05)).Position
		local back = -fwd * 1.2 + (hcf.RightVector * x * 0.6) + Vector3.new(0, math.sin(t * 5 + i) * 0.35, 0)
		put(w, CFrame.lookAt(from + back * 0.5, from + back))
	end
	d.sparkle.Rate = now < d.dashUntil and 60 or (now < d.burstUntil and 80 or 10)
	d.trail.Lifetime = now < d.dashUntil and 0.9 or (now < d.burstUntil and 1.2 or 0.35)
	local ok = pcall(function()
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end)
	if not ok then
		for i, p in ipairs(parts) do
			p.CFrame = cfs[i]
		end
	end
end

-- 오의를 쓸 때: 하늘로 솟구쳐 포효
function Cosmetics.onUlt(model: Model)
	local d = active[model]
	if not d then
		return
	end
	local now = os.clock()
	d.burstStart = now
	d.burstUntil = now + 2
	task.delay(1.4, function()
		if active[model] ~= d then
			return
		end
		-- 포효: 머리에서 금빛 고리가 퍼진다
		local ring = piece(Vector3.new(0.2, 1, 1), GOLD_LIGHT, Enum.Material.Neon, Enum.PartType.Cylinder, 0.2)
		ring.CFrame = CFrame.new(d.headPos) * CFrame.Angles(0, 0, math.rad(90))
		TweenService:Create(ring, TweenInfo.new(0.6), { Size = Vector3.new(0.05, 26, 26), Transparency = 1 }):Play()
		Debris:AddItem(ring, 0.65)
		d.sparkle:Emit(40)
	end)
end

-- 대시할 때: 금빛 꼬리를 길게
function Cosmetics.onDash(model: Model)
	local d = active[model]
	if d then
		d.dashUntil = os.clock() + 0.6
		d.sparkle:Emit(15)
	end
end

-- 캐릭터에 꾸미기가 켜지고 꺼지는 것을 지켜본다
function Cosmetics.watch(model: Model)
	local function refresh()
		local want = model:GetAttribute("Cosmetic") == "goldDragon" and model.Parent ~= nil
		local d = active[model]
		if want and not d then
			local nd = build(model)
			if nd then
				active[model] = nd
			end
		elseif not want and d then
			destroy(d)
			active[model] = nil
		end
	end
	model:GetAttributeChangedSignal("Cosmetic"):Connect(refresh)
	model.AncestryChanged:Connect(function()
		if not model.Parent then
			local d = active[model]
			if d then
				destroy(d)
				active[model] = nil
			end
		end
	end)
	refresh()
end

RunService.RenderStepped:Connect(function(dt: number)
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or nil
	for _, d in pairs(active) do
		local ok = pcall(step, d, math.min(dt, 0.1), camPos)
		if not ok then
			continue
		end
	end
end)

local _ = Players
return Cosmetics
