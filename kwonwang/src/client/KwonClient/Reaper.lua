-- 권왕 1.9판: 초월 권법 초·혈마신수의 화면
-- 오른손에 피처럼 붉은 큰 낫 (자루는 검붉고, 날은 핏빛으로 빛나며 끝에서 피가 떨어진다), 왼손엔 붉은 손톱
-- 몸짓마다 핏빛 초승달이 남고, 오의는 하늘만 한 피의 낫, 초 오의는 붉은 달과 하늘을 가르는 낫질
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))
local Demon = require(script.Parent:WaitForChild("Demon"))

local Reaper = {}
local player = Players.LocalPlayer

local RED = Color3.fromRGB(220, 20, 40)
local BLOOD = Color3.fromRGB(150, 0, 18)
local PALE = Color3.fromRGB(255, 170, 170)
local SHAFT = Color3.fromRGB(38, 10, 14)
local WHITE = Color3.new(1, 1, 1)
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local folder = Instance.new("Folder")
folder.Name = "KwonReaper"
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
local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 1e-3 and f.Unit or Vector3.new(0, 0, -1)
end
local function part(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, shape: string?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Neon
	p.Transparency = alpha or 0
	if shape == "ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Parent = folder
	return p
end
local function fadeOut(p: BasePart, time: number, goal: { [string]: any }?)
	local g = goal or {}
	g.Transparency = 1
	tween(p, time, g)
	task.delay(time + 0.05, function()
		p:Destroy()
	end)
end
local function ground(at: Vector3): Vector3
	return Vector3.new(at.X, at.Y - 2.7, at.Z)
end

local opts: any = {}
function Reaper.init(o: any)
	opts = o or {}
end
local function shakeNear(pos: Vector3, amount: number, range: number)
	if opts.shake and near(pos, range) then
		opts.shake(amount)
	end
end

------------------------------------------------------------------------
-- 큰 낫 (오른손). 손 기준: 자루는 주먹을 꿰뚫는 Z 축, +Z 끝에 날, -Z 끝에 붉은 물미
------------------------------------------------------------------------
local function attach(p: BasePart, to: BasePart, cf: CFrame, holder: Instance, list: { Instance })
	p.Massless = true
	p.Anchored = false
	p.CFrame = to.CFrame * cf
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = p
	w.Parent = p
	p.Parent = holder
	table.insert(list, p)
end
local AXIS_Z = CFrame.Angles(0, math.rad(90), 0) -- 원기둥의 축(X)을 손의 Z로
local SHAFT_BACK, SHAFT_FRONT = 2.0, 4.6
-- 날 머리를 자루 둘레로 돌린 각도 (1.9.3판: 옆으로 뻗던 날을 90도 돌려, 치켜든 자세에서 날이 앞으로 드리우게)
local HEAD_ROLL = -90
local HEAD = CFrame.Angles(0, 0, math.rad(HEAD_ROLL))
local function buildScythe(hand: BasePart, holder: Instance, list: { Instance })
	local len = SHAFT_BACK + SHAFT_FRONT
	local mid = (SHAFT_FRONT - SHAFT_BACK) / 2
	-- 자루: 검붉은 나무, 붉은 천을 감은 띠 셋
	attach(part(Vector3.new(len, 0.34, 0.34), SHAFT, Enum.Material.Wood, 0, "cyl"), hand, CFrame.new(0, 0, mid) * AXIS_Z, holder, list)
	for _, z in ipairs({ -1.2, 1.6, 3.4 }) do
		attach(part(Vector3.new(0.32, 0.4, 0.4), BLOOD, Enum.Material.Fabric, 0, "cyl"), hand, CFrame.new(0, 0, z) * AXIS_Z, holder, list)
	end
	-- 물미: 붉게 빛나는 뾰족한 끝
	local butt = part(Vector3.new(0.3, 0.3, 0.9), RED, Enum.Material.Neon, 0)
	attach(butt, hand, CFrame.new(0, 0, -SHAFT_BACK - 0.35), holder, list)
	-- 날 머리: 검은 쇠 고리 + 붉은 눈 (빛)
	local head = part(Vector3.new(0.5, 0.55, 0.55), Color3.fromRGB(25, 20, 22), Enum.Material.Metal, 0)
	attach(head, hand, HEAD * CFrame.new(0, 0, SHAFT_FRONT), holder, list)
	local eye = part(Vector3.new(0.28, 0.28, 0.28), RED, Enum.Material.Neon, 0, "ball")
	eye.Name = "ReaperEye"
	attach(eye, hand, HEAD * CFrame.new(0, 0.3, SHAFT_FRONT), holder, list)
	local glow = Instance.new("PointLight")
	glow.Color = RED
	glow.Range = 8
	glow.Brightness = 1.2
	glow.Parent = eye
	-- 날: 자루에서 옆(-X)으로 뻗다가 자루 쪽(-Z)으로 휘어 내려간다. 날 끝으로 갈수록 가늘어진다
	local p = Vector3.new(0, 0, SHAFT_FRONT + 0.15)
	local dir = Vector3.new(-1, 0, 0)
	local n = 8
	for k = 1, n do
		local segLen = 0.85
		local width = 0.95 - (k - 1) * 0.1
		local c = p + dir * (segLen / 2)
		local cf = CFrame.lookAt(c, c + dir, Vector3.new(0, 1, 0))
		-- 등 (검붉은 쇠)과 날 (핏빛으로 빛나는 가장자리)
		attach(part(Vector3.new(width, 0.12, segLen * 1.08), Color3.fromRGB(110, 8, 20), Enum.Material.Metal, 0), hand, HEAD * cf * CFrame.new(-width * 0.15, 0, 0), holder, list)
		local edge = part(Vector3.new(0.14, 0.13, segLen * 1.1), RED, Enum.Material.Neon, 0)
		attach(edge, hand, HEAD * cf * CFrame.new(width * 0.38, 0, 0), holder, list)
		if k == n then
			edge.Name = "ReaperTip"
		end
		p += dir * segLen
		dir = (CFrame.Angles(0, math.rad(-11), 0) * CFrame.new(dir)).Position
		dir = dir.Unit
	end
	-- 머리에서 늘어진 짧은 쇠사슬
	for k = 1, 4 do
		attach(part(Vector3.new(0.22, 0.32, 0.22), Color3.fromRGB(60, 50, 55), Enum.Material.Metal, 0, "ball"), hand, HEAD * CFrame.new(0.15, -0.3 - k * 0.3, SHAFT_FRONT - 0.2), holder, list)
	end
end
-- 왼손: 붉은 손톱 셋
local function buildClaws(hand: BasePart, holder: Instance, list: { Instance })
	for i = -1, 1 do
		local c = part(Vector3.new(0.12, 0.75, 0.12), RED, Enum.Material.Neon, 0.1)
		attach(c, hand, CFrame.new(i * 0.18, -hand.Size.Y / 2 - 0.3, -0.1) * CFrame.Angles(math.rad(-20), 0, math.rad(i * 8)), holder, list)
	end
end

local tips: { [Model]: BasePart } = {}
-- 몸 하나에 낫과 손톱을 만든다 (Sakura가 부채와 같은 자리에서 부른다)
function Reaper.build(model: Model): { Instance }
	local out: { Instance } = {}
	local holder = Instance.new("Folder")
	holder.Name = "Reaper_" .. model.Name
	holder.Parent = folder
	table.insert(out, holder)
	local hand = model:FindFirstChild("RightHand")
	if hand and hand:IsA("BasePart") then
		buildScythe(hand, holder, out)
	end
	local lh = model:FindFirstChild("LeftHand")
	if lh and lh:IsA("BasePart") then
		buildClaws(lh, holder, out)
	end
	for _, p in ipairs(out) do
		if p.Name == "ReaperTip" and p:IsA("BasePart") then
			tips[model] = p
			-- 날 끝에서 피가 똑똑 떨어진다
			local a = Instance.new("Attachment")
			a.Parent = p
			local e = Instance.new("ParticleEmitter")
			e.Texture = TEX_SPARK
			e.Color = ColorSequence.new(RED, BLOOD)
			e.LightEmission = 0.4
			e.Rate = 6
			e.Lifetime = NumberRange.new(0.5, 0.9)
			e.Speed = NumberRange.new(0, 1)
			e.Acceleration = Vector3.new(0, -30, 0)
			e.Size = NumberSequence.new(0.22, 0.05)
			e.Transparency = NumberSequence.new(0, 0.4)
			e.Parent = a
		end
	end
	return out
end
function Reaper.tipOf(model: Model): Vector3?
	local p = tips[model]
	return (p and p.Parent) and p.Position or nil
end
RunService.Heartbeat:Connect(function()
	for m, p in pairs(tips) do
		if not p.Parent or not m.Parent then
			tips[m] = nil
		end
	end
end)

------------------------------------------------------------------------
-- 핏빛 초승달 (몸짓의 궤적): 몸 둘레에 기울어진 호를 조각으로 그린다
------------------------------------------------------------------------
local function crescent(center: CFrame, radius: number, from: number, to: number, thick: number, life: number, color: Color3?, segs: number?)
	local n = segs or math.clamp(math.floor(math.abs(to - from) / 12), 6, 30)
	for i = 0, n - 1 do
		local a0 = math.rad(from + (to - from) * i / n)
		local a1 = math.rad(from + (to - from) * (i + 1) / n)
		local p0 = center * Vector3.new(math.sin(a0) * radius, 0, -math.cos(a0) * radius)
		local p1 = center * Vector3.new(math.sin(a1) * radius, 0, -math.cos(a1) * radius)
		-- 가운데가 가장 두껍고 양 끝이 가늘다
		local u = (i + 0.5) / n
		local w = thick * math.sin(u * math.pi) + 0.08
		local seg = part(Vector3.new(w, 0.12, (p1 - p0).Magnitude * 1.15), (color or RED):Lerp(WHITE, (1 - math.sin(u * math.pi)) * 0.3), Enum.Material.Neon, 0.05)
		seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1, center.UpVector)
		task.delay(i * 0.006, function()
			fadeOut(seg, life, { Size = Vector3.new(w * 0.3, 0.05, seg.Size.Z) })
		end)
	end
end
-- 그 몸짓의 호: 기울기(tilt, 0 = 수평), 시작·끝 각도
local ARCS: { [string]: { tilt: number, from: number, to: number, at: number, r: number } } = {
	["1"] = { tilt = 55, from = -100, to = 80, at = 0.42, r = 6 },
	["2"] = { tilt = -55, from = 90, to = -90, at = 0.42, r = 6 },
	["3"] = { tilt = 4, from = 0, to = 720, at = 0.2, r = 7.5 },
	["4"] = { tilt = 90, from = -60, to = 120, at = 0.5, r = 7 },
	H = { tilt = 6, from = 0, to = 720, at = 0.3, r = 9 },
	F = { tilt = 90, from = 140, to = -40, at = 0.4, r = 6.5 },
}
function Reaper.cast(styleId: any, slot: any, model: Model, dur: number)
	local st = type(styleId) == "string" and Config.STYLE_BY_ID[styleId] or nil
	if not st or not st.scythe then
		return
	end
	local arc = ARCS[tostring(slot)]
	local r = rootOf(model)
	if not arc or not r or not near(r.Position, 160) then
		return
	end
	task.delay(dur * arc.at, function()
		local rr = rootOf(model)
		if not rr then
			return
		end
		local look = flat(rr.CFrame.LookVector)
		local base = CFrame.lookAt(rr.Position + Vector3.new(0, 0.6, 0), rr.Position + Vector3.new(0, 0.6, 0) + look)
		local cf = base * CFrame.Angles(0, 0, math.rad(arc.tilt))
		local spin = math.abs(arc.to - arc.from) > 360
		crescent(cf, arc.r, arc.from, spin and arc.from + 340 or arc.to, slot == "H" and 1.4 or 1.0, spin and 0.35 or 0.28)
		if spin then
			task.delay(dur * 0.3, function()
				crescent(cf * CFrame.Angles(0, math.rad(20), 0), arc.r * 1.1, arc.from, arc.from + 340, 1.0, 0.3, PALE)
			end)
		end
		Fx.burst("spark", rr.Position + look * 3, RED, 8, 1.1)
		if slot == "H" or slot == 4 or slot == "4" then
			Fx.ring(ground(rr.Position) + look * 3 + Vector3.new(0, 0.3, 0), RED, 2, 16, 0.4)
		end
		Fx.sound("swing", 0.7, 0.75, rr.Position)
	end)
end

------------------------------------------------------------------------
-- 혈사슬: 낫이 사슬을 끌고 날아가 적을 낚아 끌어온다. 끌려오는 동안 사슬이 팽팽하다
------------------------------------------------------------------------
local function chainBetween(a: Vector3, b: Vector3, links: { BasePart })
	local n = #links
	for i, l in ipairs(links) do
		local p = a:Lerp(b, (i - 0.5) / n)
		l.CFrame = CFrame.lookAt(p, b) * CFrame.Angles(0, 0, (i % 2) * math.rad(90))
	end
end
local function reapHook(data: any)
	local m: Model? = data.m
	local r0 = rootOf(m)
	if not r0 then
		return
	end
	local root = r0 :: BasePart
	local targets: { Model } = data.targets or {}
	local delay = data.delay or 0.2
	local pull = data.pull or 0.3
	Fx.sound("deflect", 0.8, 0.6, root.Position)
	for _, t in ipairs(targets) do
		local tr = rootOf(t)
		if tr then
			local troot = tr :: BasePart
			local links: { BasePart } = {}
			for _ = 1, 14 do
				table.insert(links, part(Vector3.new(0.18, 0.4, 0.75), Color3.fromRGB(70, 55, 60), Enum.Material.Metal, 0))
			end
			-- 날아가는 낫 머리
			local hook = part(Vector3.new(0.4, 2.2, 1.6), RED, Enum.Material.Neon, 0)
			local t0 = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.RenderStepped:Connect(function()
				local t = os.clock() - t0
				local hand = m and m:FindFirstChild("RightHand")
				local from = (hand and hand:IsA("BasePart")) and hand.Position or root.Position
				local to = troot.Parent and troot.Position or from
				local reach = math.clamp(t / delay, 0, 1)
				local head = from:Lerp(to, reach)
				if t > delay + pull + 0.15 or not troot.Parent then
					conn:Disconnect()
					for _, l in ipairs(links) do
						fadeOut(l, 0.15)
					end
					fadeOut(hook, 0.15)
					return
				end
				chainBetween(from, head, links)
				hook.CFrame = CFrame.lookAt(head, head + (head - from).Unit) * CFrame.Angles(0, 0, t * 20)
			end)
			task.delay(delay, function()
				if troot.Parent then
					Fx.burst("spark", troot.Position, RED, 14, 1.2)
					local splat = part(Vector3.new(1, 1, 1), BLOOD, Enum.Material.Neon, 0.2, "ball")
					splat.CFrame = CFrame.new(troot.Position)
					fadeOut(splat, 0.3, { Size = Vector3.new(5, 5, 5) })
					Fx.sound("hit", 0.7, 0.8, troot.Position)
				end
			end)
		end
	end
end
-- 한 바퀴 돌며 베기 (혈사슬의 끝)
local function reapSpin(data: any)
	local r = rootOf(data.m)
	if not r then
		return
	end
	local rad = data.radius or 9
	local base = CFrame.new(r.Position + Vector3.new(0, 0.5, 0))
	crescent(base, rad * 0.8, 0, 340, 1.5, 0.35)
	crescent(base * CFrame.Angles(0, math.rad(25), 0), rad * 0.95, 0, 340, 0.9, 0.4, PALE)
	Fx.ring(ground(r.Position) + Vector3.new(0, 0.3, 0), RED, 2, rad * 2.2, 0.45)
	Fx.burst("spark", r.Position, RED, 20, 1.4)
	Fx.sound("swing", 1, 0.6, r.Position)
	shakeNear(r.Position, 0.5, 40)
end

------------------------------------------------------------------------
-- 혈월낙참: 앞의 땅에 새겨지는 핏빛 초승달 자국, 한 박자 뒤 터진다
------------------------------------------------------------------------
local function reapScar(data: any)
	local at: Vector3 = data.at
	local dir: Vector3 = data.dir or Vector3.new(0, 0, -1)
	local len = data.length or 22
	local width = data.width or 8
	local g = ground(at) + Vector3.new(0, 0.15, 0)
	-- 초승달: 길게 휜 호를 땅에 눕힌다
	local base = CFrame.lookAt(g, g + dir) * CFrame.new(0, 0, len * 0.35)
	local segs: { BasePart } = {}
	local n = 16
	local R = len * 0.75
	for i = 0, n - 1 do
		local u0, u1 = i / n, (i + 1) / n
		local a0 = math.rad(-40 + 80 * u0)
		local a1 = math.rad(-40 + 80 * u1)
		local p0 = base * Vector3.new(math.sin(a0) * R, 0, -math.cos(a0) * R + R * 0.7)
		local p1 = base * Vector3.new(math.sin(a1) * R, 0, -math.cos(a1) * R + R * 0.7)
		local w = width * 0.55 * math.sin((u0 + u1) / 2 * math.pi) + 0.3
		local s = part(Vector3.new(w, 0.2, (p1 - p0).Magnitude * 1.1), RED, Enum.Material.Neon, 0.1)
		s.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
		table.insert(segs, s)
	end
	-- 내리꽂힌 자리 (가운데 앞)
	Fx.ring(g + dir * 2, RED, 2, width * 2.5, 0.4)
	Fx.burst("dust", g + dir * 2 + Vector3.new(0, 0.5, 0), Color3.fromRGB(110, 60, 60), 18, 1.6)
	Fx.debris(g + dir * 2, 5, 20, Color3.fromRGB(90, 50, 50))
	Fx.sound("heavy", 1, 0.7, at)
	shakeNear(at, 1.0, 60)
	task.delay(data.burst or 0.45, function()
		-- 자국을 따라 피의 기둥이 솟는다
		for i, s in ipairs(segs) do
			if i % 2 == 1 then
				local col = part(Vector3.new(14, 1.8, 1.8), RED, Enum.Material.Neon, 0.1, "cyl")
				col.CFrame = CFrame.new(s.Position + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(90))
				fadeOut(col, 0.45, { Size = Vector3.new(18, 0.3, 0.3) })
			end
			fadeOut(s, 0.5)
		end
		Fx.burst("spark", at + Vector3.new(0, 2, 0), RED, 30, 2)
		Fx.flash(at, RED, 40, 4, 0.5)
		Fx.sound("splash", 0.8, 0.6, at)
		shakeNear(at, 0.8, 60)
	end)
end

------------------------------------------------------------------------
-- 혈마수확: 등 뒤로 하늘만 한 피의 낫이 솟아 둘레를 휩쓴다
------------------------------------------------------------------------
local function bigScythe(scale: number): Model
	local m = Instance.new("Model")
	m.Name = "BloodScythe"
	local function add(p: BasePart, cf: CFrame)
		p.CFrame = cf
		p.Parent = m
	end
	-- 원점 = 자루 아래 끝 (Y 위로 자루, 꼭대기에서 날이 -X로 뻗어 아래로 휜다)
	local h = 30 * scale
	local shaft = part(Vector3.new(h, 1.4 * scale, 1.4 * scale), Color3.fromRGB(60, 0, 10), Enum.Material.Neon, 0.25, "cyl")
	add(shaft, CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)))
	local p = Vector3.new(0, h, 0)
	local dir = Vector3.new(-1, 0.1, 0).Unit
	for k = 1, 10 do
		local segLen = 2.6 * scale
		local width = (3.2 - k * 0.26) * scale
		local c = p + dir * (segLen / 2)
		local cf = CFrame.lookAt(c, c + dir, Vector3.new(0, 0, 1))
		add(part(Vector3.new(width, 0.4 * scale, segLen * 1.1), RED, Enum.Material.Neon, 0.15), cf)
		add(part(Vector3.new(0.4 * scale, 0.45 * scale, segLen * 1.12), WHITE, Enum.Material.Neon, 0.2), cf * CFrame.new(width * 0.45, 0, 0))
		p += dir * segLen
		dir = (CFrame.Angles(0, 0, math.rad(11)) * CFrame.new(dir)).Position.Unit
	end
	m.WorldPivot = CFrame.new()
	m.Parent = folder
	return m
end
local function harvest(data: any)
	local mdl: Model? = data.m
	local r0 = rootOf(mdl)
	if not r0 then
		return
	end
	local root = r0 :: BasePart
	local R = data.radius or 26
	local delay = data.delay or 0.45
	local sweeps = data.sweeps or 2
	local sweepTime = data.sweepTime or 0.55
	local scale = R / 26
	local sc = bigScythe(scale)
	local g = ground(root.Position)
	-- 땅에서 솟는다 (등 뒤)
	local look = flat(root.CFrame.LookVector)
	local yaw0 = math.atan2(-look.X, -look.Z)
	local t0 = os.clock()
	local rim = part(Vector3.new(0.2, R * 2, R * 2), BLOOD, Enum.Material.Neon, 0.6, "cyl")
	rim.CFrame = CFrame.new(g + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	Fx.sound("deflect", 1, 0.4, root.Position)
	if opts.tint and near(root.Position, 90) then
		opts.tint(Color3.fromRGB(140, 0, 20), 0.3, delay + sweeps * sweepTime)
	end
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local c = root.Parent and ground(root.Position) or g
		local cf: CFrame
		if t < delay then
			-- 등 뒤에서 땅을 뚫고 솟는다
			local u = t / delay
			cf = CFrame.new(c) * CFrame.Angles(0, yaw0, 0) * CFrame.new(0, -30 * scale * (1 - u), R * 0.3) * CFrame.Angles(math.rad(-15), 0, 0)
		else
			-- 둘레를 휩쓴다: 자루가 기울어 날이 땅을 스치듯 돈다
			local u = math.clamp((t - delay) / (sweeps * sweepTime), 0, 1)
			local yaw = yaw0 - u * sweeps * math.pi * 2
			cf = CFrame.new(c) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(62)) * CFrame.new(0, -2 * scale, 0)
		end
		sc:PivotTo(cf)
		if t > delay + sweeps * sweepTime then
			conn:Disconnect()
			-- 땅에 꽂는다
			sc:PivotTo(CFrame.new(c) * CFrame.Angles(0, yaw0, 0) * CFrame.new(0, -4 * scale, R * 0.5) * CFrame.Angles(math.rad(-25), 0, 0))
			for _, p in ipairs(sc:GetChildren()) do
				if p:IsA("BasePart") then
					fadeOut(p, 0.9)
				end
			end
			task.delay(1, function()
				sc:Destroy()
			end)
			fadeOut(rim, 0.6)
			Fx.ring(c + Vector3.new(0, 0.3, 0), RED, 4, R * 2.2, 0.6)
			Fx.burst("dust", c + Vector3.new(0, 0.5, 0), Color3.fromRGB(110, 50, 50), 30, 2.4)
			Fx.sound("heavy", 1, 0.5, c)
			shakeNear(c, 1.6, 80)
		end
	end)
	-- 휩쓸 때마다 핏빛 호
	for k = 1, sweeps do
		task.delay(delay + (k - 1) * sweepTime, function()
			if root.Parent then
				crescent(CFrame.new(root.Position + Vector3.new(0, 0.3, 0)), R * 0.85, 0, 350, 2.2, sweepTime, k % 2 == 0 and PALE or RED)
				Fx.sound("swing", 1, 0.45, root.Position)
			end
		end)
	end
end
-- 낙인이 한꺼번에 터진다 (베인 적마다 핏빛 폭발)
local function harvestBurst(data: any)
	for _, t in ipairs(data.targets or {}) do
		local tr = rootOf(t)
		if tr then
			local p = tr.Position
			local b = part(Vector3.new(1, 1, 1), RED, Enum.Material.Neon, 0.1, "ball")
			b.CFrame = CFrame.new(p)
			fadeOut(b, 0.4, { Size = Vector3.new(11, 11, 11) })
			local col = part(Vector3.new(16, 2, 2), BLOOD, Enum.Material.Neon, 0.1, "cyl")
			col.CFrame = CFrame.new(p + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.rad(90))
			fadeOut(col, 0.5, { Size = Vector3.new(22, 0.3, 0.3) })
			Fx.burst("spark", p, RED, 20, 1.6)
		end
	end
	if data.at then
		Fx.flash(data.at, RED, 60, 6, 0.7)
		shakeNear(data.at, 1.4, 80)
	end
	Fx.sound("splash", 1, 0.5, data.at)
end

------------------------------------------------------------------------
-- 혈월만겸 (초 오의): 붉은 달이 뜨고, 핏빛 초승달이 쏟아지고, 마지막에 하늘과 땅과 화면을 가른다
------------------------------------------------------------------------
local moonState: { cc: ColorCorrectionEffect?, moon: BasePart?, untilT: number } = { untilT = 0 }
-- 2.1판: 혈월의 우두머리 악마 (쓴 사람마다 하나). 낫을 머리 뒤로 치켜들고 있다가 휘두른다
type Alpha = { h: Demon.Handle, swingAt: number, swingDur: number, swingTo: number, slam: boolean }
local alphas: { [Instance]: Alpha } = {}
local RAISED = 3.5 -- 머리 뒤로 치켜든 팔
local function alphaArm(a: Alpha, t: number): number
	local u = (os.clock() - a.swingAt) / a.swingDur
	if u < 0 or u > 2.2 then
		return RAISED + math.sin(t * 2) * 0.08
	end
	if u <= 1 then
		-- 내리찍기 (빠르게)
		return RAISED + (a.swingTo - RAISED) * (u * u)
	end
	-- 다시 치켜든다 (천천히). 마지막 일격은 내리찍은 채로 머문다
	if a.slam then
		return a.swingTo
	end
	local k = (u - 1) / 1.2
	return a.swingTo + (RAISED - a.swingTo) * (1 - (1 - k) ^ 2)
end
local function alphaSwing(m: Instance?, to: number, dur: number, slam: boolean)
	local a = m and alphas[m]
	if not a then
		return
	end
	local busy = (os.clock() - a.swingAt) < a.swingDur * 2.2
	if busy and not slam then
		return
	end
	a.swingAt = os.clock()
	a.swingDur = dur
	a.swingTo = to
	a.slam = slam
end
local function alphaRise(m: Model, r: BasePart)
	local old = alphas[m]
	if old then
		Demon.remove(old.h, 0.2)
	end
	local look = flat(r.CFrame.LookVector)
	local back = r.Position - look * 24
	local g = ground(back)
	local base = CFrame.lookAt(g, g + look)
	local sc = 4.2
	local dm = Demon.spawn(base * CFrame.new(0, -11 * sc, 0), sc, { scythe = true, wings = true })
	local a: Alpha = { h = dm, swingAt = -100, swingDur = 0.3, swingTo = 1, slam = false }
	alphas[m] = a
	dm.armR = RAISED
	dm.anim = function(t: number)
		local rise = math.clamp(t / 1.1, 0, 1)
		rise = 1 - (1 - rise) ^ 3
		dm.root = base * CFrame.new(0, -11 * sc * (1 - rise) + math.sin(t * 1.6) * 0.35 * sc, 0) * CFrame.Angles(math.rad(-6), 0, 0)
		dm.armR = alphaArm(a, t)
		-- 왼팔은 앞으로 벌려 손톱을 세운다
		dm.armL = 1.0 + math.sin(t * 2.4) * 0.15
	end
	-- 피의 원에서 솟는다
	Fx.ring(g + Vector3.new(0, 0.3, 0), RED, 6, 50, 0.9)
	Fx.burst("spark", g + Vector3.new(0, 4, 0), RED, 40, 3)
	Fx.sound("heavy", 1, 0.35, g)
	-- 끝내 마지막 일격이 오지 않아도 사라진다
	task.delay(12, function()
		if alphas[m] == a then
			alphas[m] = nil
			Demon.remove(dm, 0.8)
		end
	end)
end
local function moonRise(data: any)
	local r = rootOf(data.m)
	if not r or not near(r.Position, 220) then
		return
	end
	local dur = data.dur or 3.4
	moonState.untilT = math.max(moonState.untilT, os.clock() + dur)
	alphaRise(data.m, r)
	-- 하늘이 핏빛으로 (보는 사람 화면만)
	local cc = moonState.cc
	if not cc or not cc.Parent then
		local e = Instance.new("ColorCorrectionEffect")
		e.Name = "KwonBloodMoon"
		e.Parent = Lighting
		moonState.cc = e
		cc = e
	end
	local ccx = cc :: ColorCorrectionEffect
	tween(ccx, 0.5, { TintColor = Color3.fromRGB(255, 150, 150), Saturation = 0.3, Contrast = 0.25, Brightness = -0.08 })
	-- 붉은 달: 쓴 사람 뒤 하늘 높이
	local look = flat(r.CFrame.LookVector)
	local moonAt = r.Position - look * 120 + Vector3.new(0, 90, 0)
	local moon = part(Vector3.new(1, 1, 1), Color3.fromRGB(200, 20, 30), Enum.Material.Neon, 0.05, "ball")
	moon.CFrame = CFrame.new(moonAt)
	tween(moon, 0.8, { Size = Vector3.new(70, 70, 70) }, Enum.EasingStyle.Back)
	local halo = part(Vector3.new(1, 1, 1), Color3.fromRGB(255, 80, 80), Enum.Material.ForceField, 0.3, "ball")
	halo.CFrame = CFrame.new(moonAt)
	tween(halo, 1.0, { Size = Vector3.new(100, 100, 100) })
	local l = Instance.new("PointLight")
	l.Color = RED
	l.Range = 60
	l.Brightness = 2
	l.Parent = moon
	-- 발밑의 붉은 원
	local g = ground(r.Position)
	local rim = part(Vector3.new(0.2, 1, 1), BLOOD, Enum.Material.Neon, 0.4, "cyl")
	rim.CFrame = CFrame.new(g + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(rim, 0.6, { Size = Vector3.new(0.2, (data.range or 40) * 2, (data.range or 40) * 2) })
	Fx.sound("deflect", 1, 0.3, r.Position)
	task.delay(dur, function()
		fadeOut(moon, 0.8)
		fadeOut(halo, 0.6)
		fadeOut(rim, 0.6)
		task.delay(0.1, function()
			if os.clock() >= moonState.untilT - 0.05 and moonState.cc then
				local c2 = moonState.cc :: ColorCorrectionEffect
				tween(c2, 0.8, { TintColor = WHITE, Saturation = 0, Contrast = 0, Brightness = 0 })
				task.delay(0.85, function()
					if os.clock() >= moonState.untilT and moonState.cc == c2 then
						c2:Destroy()
						moonState.cc = nil
					end
				end)
			end
		end)
	end)
	moonState.moon = moon
end
-- 하늘에서 떨어지는 핏빛 초승달 하나하나
local function moonSlash(data: any)
	-- 우두머리 악마가 초승달마다 낫을 한 번씩 휘두른다 (휘두르는 중이면 건너뛴다)
	alphaSwing(data.m, 1.3, 0.22, false)
	for _, at in ipairs(data.spots or {}) do
		if near(at, 200) then
			local g = ground(at) + Vector3.new(0, 0.2, 0)
			local yaw = math.random() * math.pi * 2
			local cf = CFrame.new(at + Vector3.new(0, 1, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, math.rad(math.random(50, 90)))
			crescent(cf, (data.radius or 6) * 0.9, -70, 70, 0.9, 0.22, math.random() < 0.3 and PALE or RED, 6)
			local mark = part(Vector3.new(0.15, 3, 3), BLOOD, Enum.Material.Neon, 0.3, "cyl")
			mark.CFrame = CFrame.new(g) * CFrame.Angles(0, 0, math.rad(90))
			fadeOut(mark, 0.35, { Size = Vector3.new(0.1, 7, 7) })
		end
	end
	if math.random() < 0.4 then
		local first = (data.spots or {})[1]
		if first then
			Fx.sound("swing", 0.5, 0.9 + math.random() * 0.3, first)
		end
	end
end
-- 마지막 낫질: 달에서 땅까지 한 줄기 붉은 칼날, 화면이 비스듬히 갈라진다
local function screenCut()
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then
		return
	end
	local g = Instance.new("ScreenGui")
	g.Name = "KwonMoonCut"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 86
	g.Parent = pg
	local angle = -18
	-- 갈라지는 두 쪽 (붉게 물든 반투명 판이 서로 반대쪽으로 밀려난다)
	local halves: { Frame } = {}
	for i, sgn in ipairs({ -1, 1 }) do
		local h = Instance.new("Frame")
		h.AnchorPoint = Vector2.new(0.5, sgn < 0 and 1 or 0)
		h.Position = UDim2.fromScale(0.5, 0.5)
		h.Size = UDim2.fromScale(2.4, 1.6)
		h.Rotation = angle
		h.BackgroundColor3 = Color3.fromRGB(90, 0, 10)
		h.BackgroundTransparency = 0.55
		h.BorderSizePixel = 0
		h.Parent = g
		halves[i] = h
	end
	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromScale(0.5, 0.5)
	line.Size = UDim2.new(0, 0, 0, 6)
	line.Rotation = angle
	line.BackgroundColor3 = Color3.fromRGB(255, 230, 230)
	line.BorderSizePixel = 0
	line.ZIndex = 3
	line.Parent = g
	local glowL = Instance.new("UIStroke")
	glowL.Color = RED
	glowL.Thickness = 5
	glowL.Parent = line
	tween(line, 0.12, { Size = UDim2.new(2.2, 0, 0, 6) }, Enum.EasingStyle.Quad)
	task.delay(0.16, function()
		local rad = math.rad(angle + 90)
		local off = Vector2.new(math.cos(rad), math.sin(rad)) * 0.035
		tween(halves[1], 0.35, { Position = UDim2.fromScale(0.5 - off.X, 0.5 - off.Y), BackgroundTransparency = 1 })
		tween(halves[2], 0.35, { Position = UDim2.fromScale(0.5 + off.X, 0.5 + off.Y), BackgroundTransparency = 1 })
		tween(line, 0.4, { BackgroundTransparency = 1, Size = UDim2.new(2.2, 0, 0, 18) })
		tween(glowL, 0.4, { Transparency = 1 })
	end)
	task.delay(0.7, function()
		g:Destroy()
	end)
end
local function moonCleave(data: any)
	local at: Vector3 = data.at
	local dir: Vector3 = data.dir or Vector3.new(0, 0, -1)
	local R = data.radius or 26
	local g = ground(at)
	-- 우두머리 악마의 마지막 내리찍기: 낫이 땅에 박힌 채 잠시 머물다 사라진다
	local m = data.m
	local a = m and alphas[m]
	if a then
		alphaSwing(m, 0.55, 0.14, true)
		task.delay(1.1, function()
			if alphas[m] == a then
				alphas[m] = nil
				Demon.remove(a.h, 0.9)
			end
		end)
	end
	-- 하늘에서 땅까지 세로로 선 거대한 칼날 (얇은 판)
	local blade = part(Vector3.new(0.6, 200, R * 2.4), RED, Enum.Material.Neon, 0.05)
	blade.CFrame = CFrame.lookAt(g + Vector3.new(0, 100, 0), g + Vector3.new(0, 100, 0) + dir)
	local core = part(Vector3.new(0.3, 200, R * 2.4), WHITE, Enum.Material.Neon, 0)
	core.CFrame = blade.CFrame
	blade.Size = Vector3.new(0.6, 200, 0.5)
	core.Size = Vector3.new(0.3, 200, 0.3)
	tween(blade, 0.1, { Size = Vector3.new(0.6, 200, R * 2.4) })
	tween(core, 0.1, { Size = Vector3.new(0.3, 200, R * 2.4) })
	task.delay(0.15, function()
		fadeOut(blade, 0.5, { Size = Vector3.new(4, 200, R * 2.6) })
		fadeOut(core, 0.3)
	end)
	-- 땅이 한 줄로 갈라지고 피가 솟는다
	local scar = part(Vector3.new(1.2, 0.25, R * 2.4), RED, Enum.Material.Neon, 0)
	scar.CFrame = CFrame.lookAt(g + Vector3.new(0, 0.15, 0), g + Vector3.new(0, 0.15, 0) + dir)
	task.delay(1.2, function()
		fadeOut(scar, 1)
	end)
	for i = 0, 3 do
		task.delay(i * 0.07, function()
			Fx.ring(g + Vector3.new(0, 0.3, 0), i % 2 == 0 and RED or PALE, 4, R * 2.6 + i * 8, 0.8)
		end)
	end
	Fx.burst("spark", at + Vector3.new(0, 3, 0), RED, 60, 2.6)
	Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(110, 50, 50), 40, 3)
	Fx.debris(g, 12, 40, Color3.fromRGB(90, 40, 40))
	Fx.flash(at, RED, 60, 8, 1)
	Fx.breakSound("slash", 0.8, 0.6, at)
	Fx.sound("heavy", 1, 0.4, at)
	shakeNear(at, 2.6, 120)
	if near(at, 120) then
		screenCut()
	end
end

local HANDLERS: { [string]: (any) -> () } = {
	reapHook = reapHook,
	reapSpin = reapSpin,
	reapScar = reapScar,
	harvest = harvest,
	harvestBurst = harvestBurst,
	moonRise = moonRise,
	moonSlash = moonSlash,
	moonCleave = moonCleave,
}
function Reaper.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil
end
function Reaper.run(data: any)
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

------------------------------------------------------------------------
-- 초 오의 혈월만겸의 컷씬 (쓴 사람 화면에서만, 대사 없이): 무릎 꿇은 몸을 낮게 올려다보다가,
-- 일어서며 낫을 달로 치켜드는 순간 카메라가 뒤로 빠져 붉은 달과 함께 잡는다
------------------------------------------------------------------------
local cutActive = false
function Reaper.superCut(model: Model, dur: number, name: string, shake: ((number) -> ())?)
	local cam = workspace.CurrentCamera
	local r = rootOf(model)
	if not cam or not r or cutActive then
		return
	end
	cutActive = true
	local pg = player:WaitForChild("PlayerGui")
	local g = Instance.new("ScreenGui")
	g.Name = "KwonReaperCut"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 85
	g.Parent = pg
	-- 붉게 물드는 가장자리
	local tintF = Instance.new("Frame")
	tintF.Size = UDim2.fromScale(1, 1)
	tintF.BackgroundColor3 = Color3.fromRGB(90, 0, 12)
	tintF.BackgroundTransparency = 1
	tintF.BorderSizePixel = 0
	tintF.Parent = g
	local grad = Instance.new("UIGradient")
	grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.35, 1), NumberSequenceKeypoint.new(0.65, 1), NumberSequenceKeypoint.new(1, 0.1) })
	grad.Rotation = 90
	grad.Parent = tintF
	tween(tintF, 0.3, { BackgroundTransparency = 0.35 })
	-- 위아래 검은 띠와 이름
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
	label.TextColor3 = PALE
	label.TextStrokeColor3 = RED
	label.TextStrokeTransparency = 0.2
	label.TextTransparency = 1
	label.ZIndex = 6
	label.Parent = bars[2]
	tween(label, 0.25, { TextTransparency = 0 })
	-- 핏방울이 화면 위에서 흘러내린다
	local drops: { Frame } = {}
	for i = 1, 12 do
		local d = Instance.new("Frame")
		d.AnchorPoint = Vector2.new(0.5, 0)
		d.Position = UDim2.fromScale((i - 0.5) / 12 + (math.random() - 0.5) * 0.05, 0.1)
		d.Size = UDim2.new(0, 3 + math.random(0, 3), 0, 0)
		d.BackgroundColor3 = BLOOD
		d.BorderSizePixel = 0
		d.ZIndex = 4
		d.Parent = g
		table.insert(drops, d)
		tween(d, dur * (0.6 + math.random() * 0.4), { Size = UDim2.new(0, d.Size.X.Offset, 0.2 + math.random() * 0.35, 0) }, Enum.EasingStyle.Sine)
	end

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
		RunService:UnbindFromRenderStep("KwonReaperCut")
		cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
		cam.FieldOfView = oldFov
		cutActive = false
		-- 1.9.3판: 컷씬이 끝나면 카메라를 내 등 뒤 조금 높은 곳으로 (앞에서 터지는 기술이 잘 보이게)
		local function behind()
			if r.Parent then
				local lk = flat(r.CFrame.LookVector)
				cam.CFrame = CFrame.lookAt(r.Position - lk * 15 + Vector3.new(0, 6, 0), r.Position + lk * 6 + Vector3.new(0, 1, 0))
			end
		end
		behind()
		task.defer(behind)
	end
	RunService:BindToRenderStep("KwonReaperCut", Enum.RenderPriority.Camera.Value, function(dt: number)
		if finished then
			return
		end
		local t = os.clock() - t0
		local u = math.clamp(t / dur, 0, 1)
		if not r.Parent then
			restore()
			return
		end
		focus = focus:Lerp(r.Position, math.min(1, dt * 10))
		local e = u * u * (3 - 2 * u)
		-- 처음엔 앞쪽 낮은 곳에서 얼굴을 올려다보고, 끝으로 갈수록 뒤로 크게 빠지며 달까지 담는다
		local pos = focus + look * (5 - 15 * e) + side * (2 + 4 * e) + Vector3.new(0, -1.2 + 5 * e, 0)
		local target = focus + Vector3.new(0, 1.2 + 6 * e, 0) - look * (40 * e)
		cam.CFrame = CFrame.lookAt(pos, target)
		cam.FieldOfView = oldFov - 22 + 26 * e
		if shake and u > 0.6 then
			shake(0.1 + (u - 0.6) * 0.8)
		end
	end)
	task.delay(dur, function()
		restore()
		for _, b in ipairs(bars) do
			tween(b, 0.18, { Size = UDim2.new(1, 0, 0, 0) })
		end
		tween(label, 0.15, { TextTransparency = 1, TextStrokeTransparency = 1 })
		for _, d in ipairs(drops) do
			tween(d, 0.25, { BackgroundTransparency = 1 })
		end
		grad:Destroy()
		tintF.BackgroundColor3 = Color3.fromRGB(255, 200, 200)
		tintF.BackgroundTransparency = 0.25
		tween(tintF, 0.35, { BackgroundTransparency = 1 })
		if shake then
			shake(1.4)
		end
		task.delay(0.5, function()
			g:Destroy()
		end)
	end)
end

return Reaper
