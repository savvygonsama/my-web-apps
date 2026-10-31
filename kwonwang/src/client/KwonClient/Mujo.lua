-- 권왕 3.6판: 무상권 (화면). 모든 것은 지나간다: 금 간 사기, 재로 빚은 나, 시드는 꽃, 다 흐르는 모래시계, 깨지는 거울
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
-- X 경화수월: 빛깔이 빠지고, 둘레에 거울 열둘이 솟는다. 발밑은 물처럼 비치는 바닥, 하늘엔 창백한 달과 바닥에 비친 달.
-- 거울 속 잿빛 내가 튀어나와 적을 치고 다른 거울로 돌아가기를 거듭하다, 거울마다 금이 가고 한가운데로 깨져 쏟아진다
------------------------------------------------------------------------
local GLASS = Color3.fromRGB(200, 222, 236)
type Ghost = { parts: { BasePart }, rel: { CFrame }, cf: CFrame }
type Mirror = { at: Vector3, R: number, panels: { BasePart }, extras: { BasePart }, model: Model?, cc: ColorCorrectionEffect?, done: boolean, ghosts: { Ghost } }
local mirrors: { [number]: Mirror } = {}
local function ghostOf(model: Model, cf: CFrame): Ghost
	local list = statueOf(model, cf)
	local rel: { CFrame } = {}
	for i, q in ipairs(list) do
		q.Material = Enum.Material.Glass
		q.Color = GLASS:Lerp(SOUL, math.random() * 0.3)
		q.Transparency = 1
		q.Reflectance = 0.3
		rel[i] = cf:ToObjectSpace(q.CFrame)
	end
	return { parts = list, rel = rel, cf = cf }
end
local function ghostMove(gh: Ghost, cf: CFrame)
	gh.cf = cf
	for i, q in ipairs(gh.parts) do
		if q.Parent then
			q.CFrame = cf * gh.rel[i]
		end
	end
end
local function ghostAlpha(gh: Ghost, a: number, time: number)
	for _, q in ipairs(gh.parts) do
		if q.Parent then
			tween(q, time, { Transparency = a })
		end
	end
end
local function mirrorEnd(mr: Mirror)
	if mr.done then
		return
	end
	mr.done = true
	for _, gh in ipairs(mr.ghosts) do
		for _, q in ipairs(gh.parts) do
			if q.Parent then
				fadeOut(q, 0.2)
			end
		end
	end
	for _, q in ipairs(mr.panels) do
		if q.Parent then
			fadeOut(q, 0.3)
		end
	end
	for _, q in ipairs(mr.extras) do
		if q.Parent then
			fadeOut(q, 0.6)
		end
	end
	local cc = mr.cc
	if cc then
		tween(cc, 0.9, { Saturation = 0, Brightness = 0, Contrast = 0, TintColor = WHITE })
		task.delay(1, function()
			cc:Destroy()
		end)
	end
end
local function mirrorOpen(data: any)
	local at: Vector3 = data.at
	if not near(at, 320) then
		return
	end
	local R = data.radius or 36
	local cut = data.cut or 1.4
	local rise = data.rise or 0.5
	local echo = data.echo or 1.6
	local crack = data.crack or 0.5
	local g = ground(at)
	local mr: Mirror = { at = g, R = R, panels = {}, extras = {}, model = data.m, cc = nil, done = false, ghosts = {} }
	mirrors[data.id] = mr
	if near(at, R * 2.5) then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "KwonMujoGrade"
		cc.Parent = Lighting
		tween(cc, 0.6, { Saturation = -1, Brightness = -0.06, Contrast = 0.15, TintColor = Color3.fromRGB(225, 236, 255) })
		mr.cc = cc
	end
	-- 물처럼 비치는 바닥 (컷씬 동안 천천히 번진다)
	local floor = part(Vector3.new(0.2, 4, 4), GLASS, Enum.Material.Glass, 0.55, "cyl")
	floor.Reflectance = 0.6
	floor.CFrame = CFrame.new(g + Vector3.new(0, 0.12, 0)) * UP
	tween(floor, cut + rise, { Size = Vector3.new(0.2, R * 2, R * 2) })
	table.insert(mr.extras, floor)
	-- 하늘의 달과 바닥에 비친 달 (경화수월: 거울 속 꽃, 물 속 달)
	local moonPos = g + Vector3.new(0, 46, 0) + flat(Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)) * 10
	local moon = part(Vector3.new(9, 9, 9), Color3.fromRGB(236, 242, 255), Enum.Material.Neon, 1, "ball")
	moon.CFrame = CFrame.new(moonPos)
	tween(moon, cut, { Transparency = 0.1 })
	table.insert(mr.extras, moon)
	local halo = part(Vector3.new(0.2, 18, 18), SOUL, Enum.Material.Neon, 1, "cyl")
	halo.CFrame = CFrame.lookAt(moonPos, at) * CFrame.Angles(0, math.rad(90), 0)
	tween(halo, cut, { Transparency = 0.85 })
	table.insert(mr.extras, halo)
	local water = part(Vector3.new(0.1, 8, 8), Color3.fromRGB(236, 242, 255), Enum.Material.Neon, 1, "cyl")
	water.CFrame = CFrame.new(Vector3.new(moonPos.X, g.Y + 0.2, moonPos.Z)) * UP
	tween(water, cut, { Transparency = 0.35 })
	table.insert(mr.extras, water)
	-- 물결 (컷씬 동안 바닥에 동심원)
	for k = 0, 3 do
		task.delay(k * cut / 4, function()
			Fx.ring(g + Vector3.new(0, 0.3, 0), GLASS, 0.6, R * 2, 0.9)
		end)
	end
	Fx.sound("ping", 0.5, 0.5, at)
	-- 거울 열둘이 둘레에서 솟는다 (가운데를 바라본다)
	local n = 12
	for i = 1, n do
		local a = (i - 1) / n * math.pi * 2
		local pos = g + Vector3.new(math.cos(a) * R * 0.85, 0, math.sin(a) * R * 0.85)
		local face = CFrame.lookAt(pos, Vector3.new(g.X, pos.Y, g.Z))
		local h, w = 13, 7
		local glass = part(Vector3.new(w, h, 0.3), GLASS, Enum.Material.Glass, 0.3)
		glass.Reflectance = 0.75
		local frame = part(Vector3.new(w + 1, h + 1, 0.2), ASH_DARK, Enum.Material.Slate, 0)
		local top = face * CFrame.new(0, h / 2 + 0.5, 0)
		local downCF = face * CFrame.new(0, -h / 2 - 1, 0)
		glass.CFrame = downCF
		frame.CFrame = downCF * CFrame.new(0, 0, 0.3)
		table.insert(mr.panels, glass)
		table.insert(mr.extras, frame)
		task.delay(cut + (i % 4) * rise * 0.12, function()
			if mr.done then
				return
			end
			tween(glass, rise * 0.6, { CFrame = top }, Enum.EasingStyle.Back)
			tween(frame, rise * 0.6, { CFrame = top * CFrame.new(0, 0, 0.3) }, Enum.EasingStyle.Back)
			ashPuff(pos, 3, 1, 2)
		end)
	end
	task.delay(cut, function()
		Fx.sound("heavy", 0.6, 1.4, at)
		shakeNear(g, 1.2, 160)
	end)
	-- 금이 간다: 거울마다 넋빛 금이 번진다
	task.delay(cut + rise + echo, function()
		if mr.done then
			return
		end
		for i, q in ipairs(mr.panels) do
			task.delay((i % 6) * crack * 0.08, function()
				if q.Parent then
					crackLines(q.Position, 5, 6, crack, SOUL, q.CFrame.LookVector)
					tween(q, crack * 0.5, { Transparency = 0.15 })
				end
			end)
		end
		crackLines(g + Vector3.new(0, 0.3, 0), 10, R * 0.8, crack + 0.2, SOUL)
		if water.Parent then
			crackLines(water.Position + Vector3.new(0, 0.1, 0), 5, 5, crack, WHITE)
		end
		Fx.sound("deflect", 0.8, 0.6, at)
		shakeNear(g, 0.8, 160)
	end)
	-- 깨진다: 거울 조각이 모두 한가운데로 쏟아져 들어가 터진다
	task.delay(cut + rise + echo + crack, function()
		if mr.done then
			return
		end
		local mid = g + Vector3.new(0, 4, 0)
		for _, q in ipairs(mr.panels) do
			local from = q.Position
			for _ = 1, 6 do
				local s = part(Vector3.new(1.8, 0.12, 1.4) * (0.6 + math.random() * 0.8), GLASS, Enum.Material.Glass, 0.15, "wedge")
				s.Reflectance = 0.6
				s.CFrame = CFrame.new(from + Vector3.new((math.random() - 0.5) * 6, (math.random() - 0.5) * 10, (math.random() - 0.5) * 2)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
				local land = mid + Vector3.new((math.random() - 0.5) * 3, (math.random() - 0.5) * 3, (math.random() - 0.5) * 3)
				tween(s, 0.28, { CFrame = CFrame.new(land) * CFrame.Angles(math.random() * 9, math.random() * 9, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.delay(0.3, function()
					s:Destroy()
				end)
			end
		end
		for _, q in ipairs(mr.panels) do
			q:Destroy()
		end
		table.clear(mr.panels)
		Fx.sound("shatter", 1, 0.8, at)
		task.delay(0.3, function()
			for k = 0, 3 do
				task.delay(k * 0.07, function()
					Fx.ring(g + Vector3.new(0, 0.5 + k, 0), k % 2 == 0 and WHITE or SOUL, 4, R * 2.4 + k * 10, 0.8)
				end)
			end
			shards(mid, 30, 2.2, GLASS)
			for _ = 1, 8 do
				local a, rr = math.random() * math.pi * 2, math.sqrt(math.random()) * R
				ashPuff(g + Vector3.new(math.cos(a) * rr, 2 + math.random() * 4, math.sin(a) * rr), 5, 1.5, 6)
			end
			if moon.Parent then
				shards(moon.Position, 14, 1.6, Color3.fromRGB(236, 242, 255))
				moon:Destroy()
			end
			Fx.burst("smoke", mid, ASH, 26, 3.5)
			Fx.flash(mid, WHITE, 140, 9, 0.6)
			Fx.sound("shatter", 1, 0.5, at)
			Fx.sound("heavy", 1, 0.4, at)
			shakeNear(g, 3.2, 220)
			if opts.flash and near(g, R * 2) then
				opts.flash(WHITE, 0.3)
			end
			mirrorEnd(mr)
		end)
	end)
	task.delay(cut + rise + echo + crack + 5, function()
		mirrorEnd(mr)
		mirrors[data.id] = nil
	end)
end
local function mirrorEcho(data: any)
	local mr = mirrors[data.id]
	if not mr or mr.done then
		return
	end
	local model = mr.model
	if not model then
		return
	end
	local every = data.every or 0.25
	local n = data.n or 6
	local targets = data.targets or {}
	local count = math.min(#targets, 6)
	for ti = 1, count do
		local tm: Model? = targets[ti]
		local tr = rootOf(tm)
		if tr then
			local gh = ghostOf(model, CFrame.new(mr.at))
			table.insert(mr.ghosts, gh)
			-- 칠 때마다 다른 거울에서 나온다
			for k = 1, n do
				task.delay((k - 1) * every, function()
					if mr.done or #mr.panels == 0 then
						return
					end
					local panel = mr.panels[((ti * 5 + k * 7) % #mr.panels) + 1]
					local goal = tr.Parent and tr.Position or mr.at + Vector3.new(0, 3, 0)
					local from = panel.Position - Vector3.new(0, 3, 0)
					local dir = flat(goal - from)
					local startCF = CFrame.lookAt(from, from + dir)
					ghostMove(gh, startCF)
					ghostAlpha(gh, 0.25, 0.05)
					tween(panel, 0.08, { Transparency = 0.05 })
					task.delay(0.1, function()
						if panel.Parent then
							tween(panel, 0.15, { Transparency = 0.3 })
						end
					end)
					local hitPos = goal - dir * 2.5
					local endCF = CFrame.lookAt(hitPos, hitPos + dir)
					local t0 = os.clock()
					local last = from + Vector3.new(0, 1, 0)
					local conn: RBXScriptConnection
					conn = RunService.Heartbeat:Connect(function()
						local u = math.clamp((os.clock() - t0) / (every * 0.45), 0, 1)
						local e = 1 - (1 - u) * (1 - u)
						local cf = startCF:Lerp(endCF, e)
						ghostMove(gh, cf)
						local p = cf.Position + Vector3.new(0, 1, 0)
						if (p - last).Magnitude > 1.5 then
							local trl = beam(last, p, 0.5, GLASS, 0.5, Enum.Material.Glass)
							fadeOut(trl, 0.25, { Size = Vector3.new(0.05, 0.05, trl.Size.Z) })
							last = p
						end
						if u >= 1 or mr.done then
							conn:Disconnect()
							if mr.done then
								return
							end
							shards(goal, 4, 0.7, GLASS)
							crackLines(goal, 3, 2, 0.12, SOUL, -dir)
							ghostAlpha(gh, 1, every * 0.4)
						end
					end)
					if ti == 1 then
						Fx.sound("swing", 0.45, 1.1 + k * 0.05, goal)
					end
				end)
			end
		end
	end
end

local HANDLERS: { [string]: (any) -> () } = {
	ashStatues = ashStatues,
	witherBloom = witherBloom,
	hourglass = hourglass,
	mirrorOpen = mirrorOpen,
	mirrorEcho = mirrorEcho,
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
