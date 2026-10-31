-- 권왕 3.6판: 무상권 (화면). 모든 것은 지나간다: 금 간 사기, 재로 빚은 나, 시드는 꽃, 다 흐르는 모래시계, 꺼지는 촛불
-- 빛깔은 은빛 재와 차가운 푸른 넋불 둘뿐 (번쩍이는 색을 쓰지 않는다)
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Fx = require(script.Parent:WaitForChild("Fx"))

local Mujo = {}

local ASH = Color3.fromRGB(205, 210, 220)
local ASH_DARK = Color3.fromRGB(110, 114, 124)
local SOUL = Color3.fromRGB(110, 210, 255)
local SAND = Color3.fromRGB(214, 200, 168)
local WOOD = Color3.fromRGB(70, 56, 46)
local WAX = Color3.fromRGB(236, 232, 222)
local WHITE = Color3.new(1, 1, 1)
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local UP = CFrame.Angles(0, 0, math.rad(90))

local folder = Instance.new("Folder")
folder.Name = "KwonMujo"
folder.Parent = workspace

local opts: any = {}
function Mujo.init(o: any)
	opts = o or {}
end

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
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = alpha or 0
	p.Parent = folder
	return p
end
local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function fadeOut(p: BasePart, time: number, goal: { [string]: any }?)
	local g = goal or {}
	g.Transparency = 1
	tween(p, time, g)
	task.delay(time + 0.05, function()
		p:Destroy()
	end)
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
end
local function rootOf(m: Instance?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 1e-3 and f.Unit or Vector3.new(0, 0, -1)
end
local function ground(at: Vector3): Vector3
	return Vector3.new(at.X, at.Y - 2.7, at.Z)
end
local function shakeNear(pos: Vector3, amount: number, range: number)
	if opts.shake and near(pos, range) then
		opts.shake(amount)
	end
end
local function beam(a: Vector3, b: Vector3, w: number, color: Color3, alpha: number?, mat: Enum.Material?): BasePart
	local p = part(Vector3.new(w, w, math.max(0.05, (b - a).Magnitude)), color, mat or Enum.Material.Neon, alpha or 0)
	p.CFrame = (b - a).Magnitude > 1e-3 and CFrame.lookAt((a + b) / 2, b) or CFrame.new(a)
	return p
end
-- 흩날리는 재 한 줌 (조각 몇 개가 위로 떠올랐다 흩어진다)
local function ashPuff(at: Vector3, n: number, s: number, rise: number?)
	for _ = 1, n do
		local q = part(Vector3.new(0.3, 0.3, 0.3) * s * (0.6 + math.random() * 0.8), math.random() < 0.7 and ASH or ASH_DARK, Enum.Material.SmoothPlastic, 0.1)
		q.CFrame = CFrame.new(at + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2 * s) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		fadeOut(q, 0.8 + math.random() * 0.6, { CFrame = q.CFrame + Vector3.new((math.random() - 0.5) * 6 * s, (rise or 3) * (0.5 + math.random()), (math.random() - 0.5) * 6 * s) })
	end
	Fx.burst("smoke", at, ASH, math.max(2, math.floor(n / 3)), s)
end
-- 사기 조각: 흰 판이 사방으로 튄다
local function shards(at: Vector3, n: number, s: number, color: Color3?)
	for _ = 1, n do
		local q = part(Vector3.new(0.9, 0.12, 0.7) * s * (0.6 + math.random() * 0.8), color or WHITE, Enum.Material.Glass, 0.15, "wedge")
		q.CFrame = CFrame.new(at) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		local d = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit
		fadeOut(q, 0.6, { CFrame = CFrame.new(at + d * (6 + math.random() * 5) * s) * CFrame.Angles(math.random() * 9, math.random() * 9, 0) })
	end
end
-- 금 (가지를 치며 갈라지는 가는 선)
local function crackLines(origin: Vector3, n: number, len: number, life: number, color: Color3?, planeUp: Vector3?)
	local up = planeUp or Vector3.new(0, 1, 0)
	local helper = math.abs(up.Y) > 0.9 and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0)
	local axisA = up:Cross(helper).Unit
	local axisB = up:Cross(axisA).Unit
	local out: { BasePart } = {}
	for k = 1, n do
		local a = (k / n + math.random() * 0.1) * math.pi * 2
		local p = origin
		local dir = axisA * math.cos(a) + axisB * math.sin(a)
		for _ = 1, 3 do
			local seg = len / 3 * (0.7 + math.random() * 0.6)
			local q = p + dir * seg
			table.insert(out, beam(p, q, 0.12, color or SOUL, 0.05))
			p = q
			local turn = (math.random() - 0.5) * 1.1
			dir = (dir * math.cos(turn) + up:Cross(dir) * math.sin(turn)).Unit
		end
	end
	task.delay(life, function()
		for _, q in ipairs(out) do
			if q.Parent then
				fadeOut(q, 0.2)
			end
		end
	end)
	return out
end

------------------------------------------------------------------------
-- 차림: 머리 뒤의 이 빠진 은빛 후광 (조각 열 중 둘이 빠졌다). 빠진 자리에서 재가 조금씩 떨어진다
------------------------------------------------------------------------
function Mujo.buildGear(model: Model): { Instance }
	local out: { Instance } = {}
	local holder = Instance.new("Folder")
	holder.Name = "Mujo_" .. model.Name
	holder.Parent = folder
	table.insert(out, holder)
	local head = model:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return out
	end
	local R = 1.15
	local segs: { { p: BasePart, a: number } } = {}
	for k = 0, 9 do
		if k ~= 3 and k ~= 4 then
			local a = k / 10 * math.pi * 2
			local p = part(Vector3.new(0.14, 0.16, R * 0.6), k % 2 == 0 and ASH or Color3.fromRGB(230, 234, 242), Enum.Material.SmoothPlastic, 0)
			p.Parent = holder
			table.insert(out, p)
			table.insert(segs, { p = p, a = a })
		end
	end
	-- 떨어져 나가는 중인 조각 둘 (빠진 자리 곁을 떠돈다)
	local loose: { BasePart } = {}
	for k = 1, 2 do
		local p = part(Vector3.new(0.12, 0.14, 0.32), ASH, Enum.Material.SmoothPlastic, 0.2)
		p.Parent = holder
		table.insert(out, p)
		loose[k] = p
	end
	local glow = part(Vector3.new(0.2, 0.2, 0.2), SOUL, Enum.Material.Neon, 1)
	glow.Parent = holder
	table.insert(out, glow)
	local a0 = Instance.new("Attachment")
	a0.Parent = glow
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_SMOKE
	e.Color = ColorSequence.new(ASH, ASH_DARK)
	e.LightEmission = 0
	e.Rate = 5
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(0.2, 0.6)
	e.Acceleration = Vector3.new(0, -2.5, 0)
	e.Size = NumberSequence.new(0.25, 0.05)
	e.Transparency = NumberSequence.new(0.3, 1)
	e.Parent = a0
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if not holder.Parent or not head.Parent then
			conn:Disconnect()
			return
		end
		local t = os.clock() - t0
		local hide = model:GetAttribute("Vanish") == true
		-- 머리 뒤, 몸을 따라 약간 기울어 천천히 돈다
		local base = head.CFrame * CFrame.new(0, 0.25, 0.75) * CFrame.Angles(math.rad(-12), 0, 0)
		local spin = t * 0.35
		for _, it in ipairs(segs) do
			local a = it.a + spin
			local pos = base * Vector3.new(math.cos(a) * R, math.sin(a) * R, 0)
			it.p.CFrame = CFrame.lookAt(pos, pos + (base.RightVector * -math.sin(a) + base.UpVector * math.cos(a)), base.LookVector)
			it.p.LocalTransparencyModifier = hide and 1 or 0
		end
		for k, p in ipairs(loose) do
			local a = (3.3 + k * 0.6) / 10 * math.pi * 2 + spin
			local drift = 0.25 + 0.15 * math.sin(t * 1.3 + k)
			local pos = base * Vector3.new(math.cos(a) * (R + drift), math.sin(a) * (R + drift), 0.1 * k)
			p.CFrame = CFrame.new(pos) * CFrame.Angles(t * (0.8 + k * 0.3), t * 0.5, 0)
			p.LocalTransparencyModifier = hide and 1 or 0
		end
		local ga = 3.5 / 10 * math.pi * 2 + spin
		glow.CFrame = CFrame.new(base * Vector3.new(math.cos(ga) * R, math.sin(ga) * R, 0))
		e.Enabled = not hide
	end)
	return out
end

------------------------------------------------------------------------
-- 연타 장치 무상인: 상대 둘레에 사기 껍질이 씌워지고 금이 번지다가, 산산이 깨져 재로 흩어진다
------------------------------------------------------------------------
local function ashCrack(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local delay = data.delay or 0.45
	local shell = part(Vector3.new(5, 6.5, 5), WHITE, Enum.Material.Glass, 0.75, "ball")
	shell.CFrame = CFrame.new(at)
	-- 금이 위아래로 번진다 (껍질 겉에 세운 금 셋)
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2 + math.random()
		local n = Vector3.new(math.cos(a), 0, math.sin(a))
		task.delay(k * 0.06, function()
			crackLines(at + n * 2.4, 3, 2.6, delay, SOUL, n)
		end)
	end
	local g = ground(at)
	crackLines(g + Vector3.new(0, 0.15, 0), 7, (data.radius or 6) * 0.9, delay + 0.1, ASH_DARK)
	Fx.sound("deflect", 0.4, 1.6, at)
	task.delay(delay, function()
		shell:Destroy()
		shards(at, 14, 1.1)
		ashPuff(at, 10, 1.2, 4)
		Fx.ring(g + Vector3.new(0, 0.3, 0), ASH, 2, (data.radius or 6) * 2, 0.4)
		Fx.sound("shatter", 0.6, 1.3, at)
	end)
end

------------------------------------------------------------------------
-- E 잔영멸: 재로 빚은 나 다섯 (몸의 생김새를 그대로 본떠 잿빛으로)
------------------------------------------------------------------------
local function statueOf(model: Model, cf: CFrame): { BasePart }
	local out: { BasePart } = {}
	local r = rootOf(model)
	if not r then
		return out
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.9 and d.Size.Magnitude < 8 and (d.Parent == model or (d.Parent and d.Parent:IsA("Accessory"))) then
			local q = part(d.Size, ASH:Lerp(ASH_DARK, math.random() * 0.25), Enum.Material.Slate, 0.05, d:IsA("Part") and d.Shape == Enum.PartType.Ball and "ball" or nil)
			q.CFrame = cf * r.CFrame:ToObjectSpace(d.CFrame)
			table.insert(out, q)
		end
	end
	return out
end
local function ashStatues(data: any)
	local from: Vector3, to: Vector3 = data.from, data.to
	if not near(from, 220) then
		return
	end
	local model: Model? = data.m
	local n = data.n or 5
	local dir = flat(to - from)
	local crumble = data.crumble or 0.45
	local step = data.step or 0.1
	-- 스친 자리의 재 띠
	for k = 0, 8 do
		task.delay(k * 0.02, function()
			ashPuff(from:Lerp(to, k / 8), 3, 0.9, 1.5)
		end)
	end
	Fx.sound("swing", 0.6, 0.7, from)
	local body = model
	if not body then
		return
	end
	for i = 1, n do
		local pos = from:Lerp(to, (i - 0.5) / n)
		local turn = (i % 2 == 0 and 1 or -1) * math.rad(25)
		local list = statueOf(body, CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, turn, 0))
		task.delay(crumble + (i - 1) * step - 0.12, function()
			crackLines(pos + Vector3.new(0, 0.5, 0), 4, 2.2, 0.14, SOUL, -dir)
		end)
		task.delay(crumble + (i - 1) * step, function()
			for _, q in ipairs(list) do
				local fall = q.CFrame - Vector3.new(0, 2.5 + math.random() * 1.5, 0) + Vector3.new((math.random() - 0.5) * 2, 0, (math.random() - 0.5) * 2)
				fadeOut(q, 0.55, { CFrame = fall * CFrame.Angles(math.random() * 2, math.random() * 2, 0), Size = q.Size * 0.5 })
			end
			ashPuff(pos, 8, 1.3, 3)
			Fx.ring(ground(pos) + Vector3.new(0, 0.3, 0), ASH, 2, (data.radius or 6) * 2, 0.35)
			Fx.sound("shatter", 0.35, 0.9 + i * 0.06, pos)
		end)
	end
end

------------------------------------------------------------------------
-- R 화무십일: 땅에 커다란 잿빛 꽃 (꽃잎 여덟)이 피었다가, 안으로 오므려 쥐고, 시들어 재로 무너진다
------------------------------------------------------------------------
local function witherBloom(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local R = data.radius or 11
	local bloom = data.bloom or 0.35
	local hold = data.hold or 0.9
	local g = ground(at)
	local petals: { { p: BasePart, a: number } } = {}
	for k = 0, 7 do
		local p = part(Vector3.new(R * 0.42, 0.25, R * 0.75), ASH:Lerp(WHITE, 0.25), Enum.Material.SmoothPlastic, 0.05, "ball")
		table.insert(petals, { p = p, a = k / 8 * math.pi * 2 })
	end
	local core = part(Vector3.new(2, 2, 2), SOUL, Enum.Material.Neon, 0.1, "ball")
	core.CFrame = CFrame.new(g + Vector3.new(0, 1, 0))
	local stamens: { BasePart } = {}
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local s = part(Vector3.new(0.4, 0.4, 0.4), SOUL, Enum.Material.Neon, 0.1, "ball")
		s.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * 1.4, 2.2, math.sin(a) * 1.4))
		table.insert(stamens, s)
	end
	Fx.sound("ping", 0.4, 0.8, at)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		-- 0 → 1: 피어난다 (꽃잎이 바깥으로 눕는다). 그 뒤엔 천천히 안으로 오므린다
		local open = math.clamp(t / bloom, 0, 1)
		local grip = math.clamp((t - bloom) / hold, 0, 1)
		local tilt = math.rad(80 - open * 70 + grip * 38) -- 80도 (닫힘) → 10도 (활짝) → 48도 (쥠)
		local reach = R * 0.45 * (0.4 + 0.6 * open) * (1 - grip * 0.25)
		for _, it in ipairs(petals) do
			local cf = CFrame.new(g) * CFrame.Angles(0, it.a + t * 0.4, 0) * CFrame.new(0, 0.4, -reach * 0.6) * CFrame.Angles(tilt, 0, 0) * CFrame.new(0, 0, -reach * 0.55)
			it.p.CFrame = cf
		end
		if t > bloom + hold then
			conn:Disconnect()
		end
	end)
	-- 쥐는 동안 꽃잎 끝에서 재가 떨어진다
	for k = 1, 4 do
		task.delay(bloom + k * hold / 5, function()
			local a = math.random() * math.pi * 2
			ashPuff(g + Vector3.new(math.cos(a) * R * 0.6, 2, math.sin(a) * R * 0.6), 3, 0.8, -1)
		end)
	end
	task.delay(bloom + hold + 0.1, function()
		-- 시든다: 잿빛으로 어두워지며 처지고 무너진다
		for _, it in ipairs(petals) do
			it.p.Color = ASH_DARK
			fadeOut(it.p, 0.6, { CFrame = it.p.CFrame - Vector3.new(0, 1.5, 0), Size = it.p.Size * Vector3.new(0.6, 1, 0.5) })
			ashPuff(it.p.Position, 4, 1, 2)
		end
		for _, s in ipairs(stamens) do
			fadeOut(s, 0.3)
		end
		fadeOut(core, 0.35, { Size = Vector3.new(R, R, R) })
		Fx.ring(g + Vector3.new(0, 0.4, 0), ASH, 2, R * 2.4, 0.45)
		Fx.ring(g + Vector3.new(0, 0.6, 0), SOUL, 2, R * 1.6, 0.35)
		Fx.flash(g + Vector3.new(0, 3, 0), SOUL, 30, 3, 0.3)
		Fx.sound("heavy", 0.7, 1.2, g)
		shakeNear(g, 1.0, 90)
	end)
end

------------------------------------------------------------------------
-- G 제행무상: 둘레 위로 커다란 모래시계가 내려선다. 모래가 흐르는 동안 재의 비, 다 흐르면 금이 가고 깨진다
------------------------------------------------------------------------
local function hourglass(data: any)
	local at: Vector3 = data.at
	if not near(at, 260) then
		return
	end
	local R = data.radius or 26
	local descend = data.descend or 0.5
	local run = data.run or 2.4
	local crack = data.crack or 0.35
	local g = ground(at)
	local H = 30 -- 모래시계 높이
	local B = 8 -- 둥근 배의 반지름
	local base = g + Vector3.new(0, 12, 0) -- 모래시계 아랫면 (머리 위에 떠 있다)
	local parts: { { p: BasePart, off: Vector3, rot: CFrame? } } = {}
	local function add(p: BasePart, off: Vector3, rot: CFrame?)
		table.insert(parts, { p = p, off = off, rot = rot })
		return p
	end
	-- 나무 틀: 위·아래 판과 기둥 셋
	add(part(Vector3.new(1.2, B * 2.6, B * 2.6), WOOD, Enum.Material.Wood, 0, "cyl"), Vector3.new(0, 0, 0), UP)
	add(part(Vector3.new(1.2, B * 2.6, B * 2.6), WOOD, Enum.Material.Wood, 0, "cyl"), Vector3.new(0, H, 0), UP)
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		add(part(Vector3.new(0.9, H, 0.9), WOOD, Enum.Material.Wood), Vector3.new(math.cos(a) * B * 1.15, H / 2, math.sin(a) * B * 1.15))
	end
	-- 유리 배 둘 (위아래로 좁아지는 둥근 조각들)
	local glass: { BasePart } = {}
	for half = 0, 1 do
		for k = 0, 5 do
			local u = (k + 0.5) / 6
			local rr = B * math.sin(math.pi * (0.12 + u * 0.88))
			local y = half == 0 and (0.6 + u * (H / 2 - 0.6)) or (H - 0.6 - u * (H / 2 - 0.6))
			local p = add(part(Vector3.new(H / 12 + 0.2, rr * 2, rr * 2), Color3.fromRGB(200, 225, 240), Enum.Material.Glass, 0.7, "cyl"), Vector3.new(0, y, 0), UP)
			table.insert(glass, p)
		end
	end
	-- 모래: 위 더미 (줄어든다) · 흐르는 줄기 · 아래 더미 (늘어난다)
	local topSand = add(part(Vector3.new(1, B * 1.6, B * 1.6), SAND, Enum.Material.Sand, 0, "cyl"), Vector3.new(0, H * 0.7, 0), UP)
	local stream = add(part(Vector3.new(0.35, H / 2, 0.35), SAND, Enum.Material.Sand, 0), Vector3.new(0, H / 4, 0))
	local pile = add(part(Vector3.new(1, 1, 1), SAND, Enum.Material.Sand, 0, "ball"), Vector3.new(0, 0.6, 0))
	local function place(origin: Vector3)
		for _, it in ipairs(parts) do
			if it.p.Parent then
				it.p.CFrame = CFrame.new(origin + it.off) * (it.rot or CFrame.new())
			end
		end
	end
	place(base + Vector3.new(0, 40, 0))
	-- 땅: 모래빛 원과 둘레의 재 비
	local floor = part(Vector3.new(0.2, 2, 2), SAND, Enum.Material.Sand, 0.55, "cyl")
	floor.CFrame = CFrame.new(g + Vector3.new(0, 0.1, 0)) * UP
	tween(floor, descend + 0.3, { Size = Vector3.new(0.2, R * 2, R * 2) })
	local rainHolder = part(Vector3.new(R * 1.6, 1, R * 1.6), ASH, Enum.Material.SmoothPlastic, 1)
	rainHolder.CFrame = CFrame.new(g + Vector3.new(0, 18, 0))
	local rain = Instance.new("ParticleEmitter")
	rain.Texture = TEX_SPARK
	rain.Shape = Enum.ParticleEmitterShape.Box
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.Color = ColorSequence.new(ASH, ASH_DARK)
	rain.LightEmission = 0.2
	rain.Rate = 70
	rain.Lifetime = NumberRange.new(1.2, 1.8)
	rain.Speed = NumberRange.new(10, 14)
	rain.Size = NumberSequence.new(0.35, 0.1)
	rain.Transparency = NumberSequence.new(0.2, 1)
	rain.Enabled = false
	rain.Parent = rainHolder
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local d = math.clamp(t / descend, 0, 1)
		local y = 40 * (1 - d) ^ 3
		place(base + Vector3.new(0, y, 0))
		local u = math.clamp((t - descend) / run, 0, 1)
		topSand.Size = Vector3.new(math.max(0.05, H * 0.36 * (1 - u)), B * 1.6 * (1 - u * 0.6), B * 1.6 * (1 - u * 0.6))
		pile.Size = Vector3.new(B * 1.8, math.max(0.5, H * 0.32 * u), B * 1.8) * Vector3.new(0.3 + 0.7 * u, 1, 0.3 + 0.7 * u)
		stream.Transparency = (u > 0 and u < 1) and 0 or 1
		rain.Enabled = t > descend and u < 1
		if t > descend + run + crack then
			conn:Disconnect()
		end
	end)
	task.delay(descend, function()
		Fx.ring(g + Vector3.new(0, 0.3, 0), SAND, 4, R * 2.2, 0.6)
		Fx.sound("heavy", 0.8, 0.6, g)
		shakeNear(g, 1.4, 140)
	end)
	-- 다 흐르면 유리에 금이 가고, 깨진다
	task.delay(descend + run, function()
		for _, gp in ipairs(glass) do
			gp.Color = Color3.fromRGB(230, 245, 255)
		end
		local mid = base + Vector3.new(0, H / 2, 0)
		for k = 0, 3 do
			local a = k / 4 * math.pi * 2
			crackLines(mid + Vector3.new(math.cos(a) * B * 0.8, (k - 1.5) * 4, math.sin(a) * B * 0.8), 3, 5, crack, WHITE, Vector3.new(math.cos(a), 0, math.sin(a)))
		end
		Fx.sound("deflect", 0.8, 0.6, mid)
	end)
	task.delay(descend + run + crack, function()
		local mid = base + Vector3.new(0, H / 2, 0)
		for _, it in ipairs(parts) do
			if it.p.Parent then
				local d = (it.p.Position - mid)
				local dir = d.Magnitude > 0.1 and d.Unit or Vector3.new(0, 1, 0)
				fadeOut(it.p, 0.7, { CFrame = it.p.CFrame + dir * 14 + Vector3.new(0, -6, 0) })
			end
		end
		shards(mid, 30, 3, Color3.fromRGB(220, 240, 255))
		-- 모래 폭풍: 겹친 고리와 흙먼지
		for k = 0, 2 do
			task.delay(k * 0.08, function()
				Fx.ring(g + Vector3.new(0, 0.5 + k * 1.5, 0), k == 1 and ASH or SAND, 4, R * 2.4 + k * 8, 0.7)
			end)
		end
		Fx.burst("dust", g + Vector3.new(0, 1, 0), SAND, 30, 2.4)
		Fx.burst("smoke", mid, ASH, 16, 3)
		Fx.flash(mid, WHITE, 90, 6, 0.5)
		Fx.sound("shatter", 1, 0.7, mid)
		Fx.sound("heavy", 1, 0.5, g)
		shakeNear(g, 2.6, 160)
		rain.Enabled = false
		fadeOut(floor, 0.8)
		task.delay(1.5, function()
			rainHolder:Destroy()
		end)
	end)
end

------------------------------------------------------------------------
-- X 만등멸: 빛깔이 빠지고, 둘레에 푸른 촛불 서른여섯. 하나씩 꺼지며 넋불이 적에게, 마지막엔 어둠과 한 번의 숨
------------------------------------------------------------------------
type Candle = { body: BasePart, flame: BasePart, light: PointLight?, pos: Vector3, lit: boolean }
type Rite = { at: Vector3, R: number, candles: { Candle }, cc: ColorCorrectionEffect?, done: boolean }
local rites: { [number]: Rite } = {}
local function riteEnd(r: Rite)
	if r.done then
		return
	end
	r.done = true
	for _, c in ipairs(r.candles) do
		if c.body.Parent then
			fadeOut(c.body, 0.6, { Size = c.body.Size * Vector3.new(1, 0.2, 1), CFrame = c.body.CFrame - Vector3.new(0, c.body.Size.Y * 0.4, 0) })
		end
		if c.flame.Parent then
			fadeOut(c.flame, 0.2)
		end
	end
	local cc = r.cc
	if cc then
		tween(cc, 0.9, { Saturation = 0, Brightness = 0, Contrast = 0, TintColor = WHITE })
		task.delay(1, function()
			cc:Destroy()
		end)
	end
end
local function candleOpen(data: any)
	local at: Vector3 = data.at
	if not near(at, 320) then
		return
	end
	local R = data.radius or 38
	local n = data.candles or 36
	local cut = data.cut or 1.4
	local light = data.light or 0.4
	local out = data.out or 2.2
	local dark = data.dark or 0.5
	local g = ground(at)
	local rite: Rite = { at = g, R = R, candles = {}, cc = nil, done = false }
	rites[data.id] = rite
	-- 가까이 있으면 세상의 빛깔이 빠진다
	if near(at, R * 2.5) then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "KwonMujoGrade"
		cc.Parent = Lighting
		tween(cc, 0.5, { Saturation = -0.9, Brightness = -0.04, Contrast = 0.1 })
		rite.cc = cc
	end
	-- 촛불: 바깥 고리 (둘레의 90%), 높이가 조금씩 다르다
	for i = 1, n do
		local a = (i - 1) / n * math.pi * 2
		local pos = g + Vector3.new(math.cos(a) * R * 0.9, 0, math.sin(a) * R * 0.9)
		local h = 2 + (i % 3) * 0.6
		local body = part(Vector3.new(0.7, h, 0.7), WAX, Enum.Material.SmoothPlastic, 1)
		body.CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0))
		local flame = part(Vector3.new(0.45, 0.9, 0.45), SOUL, Enum.Material.Neon, 1, "ball")
		flame.CFrame = CFrame.new(pos + Vector3.new(0, h + 0.5, 0))
		local pl: PointLight? = nil
		if i % 4 == 0 then
			local l = Instance.new("PointLight")
			l.Color = SOUL
			l.Range = 12
			l.Brightness = 0
			l.Parent = flame
			pl = l
		end
		table.insert(rite.candles, { body = body, flame = flame, light = pl, pos = pos + Vector3.new(0, h + 0.5, 0), lit = false })
	end
	-- 차례로 켜진다 (내 앞에서부터 양쪽으로)
	for i, c in ipairs(rite.candles) do
		task.delay(cut * 0.4 + (i - 1) / n * (cut * 0.5 + light), function()
			if rite.done then
				return
			end
			tween(c.body, 0.2, { Transparency = 0 })
			tween(c.flame, 0.2, { Transparency = 0.05 })
			local l = c.light
			if l then
				tween(l, 0.3, { Brightness = 1.2 })
			end
			c.lit = true
		end)
	end
	-- 촛불이 흔들린다
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if rite.done then
			conn:Disconnect()
			return
		end
		local t = os.clock() - t0
		for i, c in ipairs(rite.candles) do
			if c.lit and c.flame.Parent then
				local w = math.sin(t * 9 + i) * 0.08
				c.flame.CFrame = CFrame.new(c.pos) * CFrame.Angles(w, 0, w * 0.7)
			end
		end
	end)
	-- 마지막 촛불이 꺼지면 어둠, 그리고 한 번의 숨
	task.delay(cut + light + out, function()
		local cc = rite.cc
		if cc then
			tween(cc, 0.25, { Brightness = -0.35, Contrast = 0.3 })
		end
		Fx.sound("fall", 0.5, 0.5, g)
	end)
	task.delay(cut + light + out + dark, function()
		if rite.done then
			return
		end
		local cc = rite.cc
		if cc then
			cc.Brightness = 0.3
		end
		-- 숨: 하얀 바람의 고리가 가운데에서 퍼지고, 모든 것이 재로
		for k = 0, 3 do
			task.delay(k * 0.07, function()
				Fx.ring(g + Vector3.new(0, 0.5 + k, 0), k % 2 == 0 and WHITE or SOUL, 4, R * 2.4 + k * 10, 0.8)
			end)
		end
		for _ = 1, 10 do
			local a, rr = math.random() * math.pi * 2, math.sqrt(math.random()) * R
			ashPuff(g + Vector3.new(math.cos(a) * rr, 2 + math.random() * 4, math.sin(a) * rr), 6, 1.6, 6)
		end
		Fx.burst("smoke", g + Vector3.new(0, 3, 0), ASH, 30, 3.5)
		Fx.flash(g + Vector3.new(0, 4, 0), WHITE, 140, 9, 0.6)
		Fx.sound("shatter", 1, 0.5, g)
		Fx.sound("heavy", 1, 0.4, g)
		shakeNear(g, 3.2, 220)
		if opts.flash and near(g, R * 2) then
			opts.flash(WHITE, 0.3)
		end
		riteEnd(rite)
	end)
	task.delay(cut + light + out + dark + 4, function()
		riteEnd(rite)
		rites[data.id] = nil
	end)
end
local function candleOut(data: any)
	local rite = rites[data.id]
	if not rite or rite.done then
		return
	end
	local c = rite.candles[data.idx or 0]
	if not c then
		return
	end
	c.lit = false
	local from = c.pos
	fadeOut(c.flame, 0.15, { Size = Vector3.new(0.1, 0.1, 0.1) })
	local l = c.light
	if l then
		tween(l, 0.15, { Brightness = 0 })
	end
	c.body.Color = Color3.fromRGB(180, 176, 168)
	Fx.burst("smoke", from, ASH, 2, 0.6)
	-- 넋불이 적에게 날아가 몸을 깎는다
	local target = rootOf(data.to)
	local to = target and target.Position or rite.at + Vector3.new(0, 3, 0)
	local wisp = part(Vector3.new(0.7, 0.7, 0.7), SOUL, Enum.Material.Neon, 0.05, "ball")
	wisp.CFrame = CFrame.new(from)
	local t0 = os.clock()
	local last = from
	local side = Vector3.new(math.random() - 0.5, 1, math.random() - 0.5) * 4
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / 0.3, 0, 1)
		local goal = target and target.Parent and target.Position or to
		local pos = from:Lerp(goal, u * u) + side * math.sin(u * math.pi)
		wisp.CFrame = CFrame.new(pos)
		if (pos - last).Magnitude > 0.5 then
			local tr = beam(last, pos, 0.25, SOUL, 0.3)
			fadeOut(tr, 0.25, { Size = Vector3.new(0.02, 0.02, tr.Size.Z) })
			last = pos
		end
		if u >= 1 then
			conn:Disconnect()
			wisp:Destroy()
			if target then
				shards(pos, 4, 0.6, ASH)
				ashPuff(pos, 3, 0.8, 2)
			end
		end
	end)
	if (data.idx or 0) % 3 == 0 then
		Fx.sound("ping", 0.25, 0.6 + (data.idx or 0) / 40, from)
	end
end

local HANDLERS: { [string]: (any) -> () } = {
	ashStatues = ashStatues,
	witherBloom = witherBloom,
	hourglass = hourglass,
	candleOpen = candleOpen,
	candleOut = candleOut,
}
function Mujo.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil or (data.kind == "pulse" and data.fx == "ashCrack")
end
function Mujo.run(data: any)
	if data.kind == "pulse" then
		ashCrack(data)
		return
	end
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

return Mujo
