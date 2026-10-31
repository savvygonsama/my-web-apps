-- 권왕 3.4판: 초·성하신권 (화면). 오른손의 별 지팡이, 마법진, 별, 은하수, 성천궁 (남색 돔과 별자리)
-- 별은 다섯 갈래의 빛 조각 (가운데 구슬 + 뾰족한 다섯 날), 마법진은 두 겹 고리와 육망성, 둘레를 도는 글자 조각
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Star = {}
local player = Players.LocalPlayer

local INDIGO = Color3.fromRGB(60, 50, 170)
local NAVY = Color3.fromRGB(22, 24, 84)
local VIOLET = Color3.fromRGB(150, 90, 230)
local GOLD = Color3.fromRGB(255, 226, 120)
local PALE = Color3.fromRGB(255, 248, 220)
local WHITE = Color3.new(1, 1, 1)
local WOOD = Color3.fromRGB(46, 36, 70)
local BRASS = Color3.fromRGB(214, 176, 92)
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local UP = CFrame.Angles(0, 0, math.rad(90))
local AXIS_Z = CFrame.Angles(0, math.rad(90), 0) -- 원기둥의 축(X)을 Z로

local folder = Instance.new("Folder")
folder.Name = "KwonStar"
folder.Parent = workspace

local opts: any = {}
function Star.init(o: any)
	opts = o or {}
end

local function newPart(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, shape: string?): BasePart
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
	p.Material = material or Enum.Material.Neon
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
local function colors(id: any): (Color3, Color3)
	local st = type(id) == "string" and Config.STYLE_BY_ID[id] or nil
	if st then
		return st.color, st.color2
	end
	return INDIGO, GOLD
end
local function shakeNear(pos: Vector3, amount: number, range: number)
	if opts.shake and near(pos, range) then
		opts.shake(amount)
	end
end
-- 두 점을 잇는 빛줄기
local function beam(a: Vector3, b: Vector3, w: number, color: Color3, alpha: number?): BasePart
	local p = newPart(Vector3.new(w, w, math.max(0.05, (b - a).Magnitude)), color, Enum.Material.Neon, alpha or 0)
	p.CFrame = (b - a).Magnitude > 1e-3 and CFrame.lookAt((a + b) / 2, b) or CFrame.new(a)
	return p
end
local function emitter(at: Instance, tex: string, c0: Color3, c1: Color3, rate: number, size: number, life: number, speed: number): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = tex
	e.Color = ColorSequence.new(c0, c1)
	e.LightEmission = 0.8
	e.Rate = rate
	e.Lifetime = NumberRange.new(life * 0.6, life)
	e.Speed = NumberRange.new(speed * 0.3, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(size, 0)
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Parent = at
	return e
end

------------------------------------------------------------------------
-- 별 (다섯 날). 조각들을 한 틀(cf)에 맞춰 함께 움직인다
------------------------------------------------------------------------
type Shape = { list: { { p: BasePart, off: CFrame } }, alive: boolean }
local function shapePlace(sh: Shape, cf: CFrame)
	if not sh.alive then
		return
	end
	for _, it in ipairs(sh.list) do
		it.p.CFrame = cf * it.off
	end
end
local function shapeFade(sh: Shape, time: number, grow: number?)
	if not sh.alive then
		return
	end
	sh.alive = false
	for _, it in ipairs(sh.list) do
		fadeOut(it.p, time, { Size = it.p.Size * (grow or 0.2) })
	end
end
local function makeStar(s: number, color: Color3, core: Color3?, alpha: number?): Shape
	local list = {}
	local c = newPart(Vector3.new(s * 0.5, s * 0.5, s * 0.5), core or WHITE, Enum.Material.Neon, alpha or 0, "ball")
	table.insert(list, { p = c, off = CFrame.new() })
	for k = 0, 4 do
		local a = math.rad(k * 72)
		-- 날 하나: 안쪽이 넓고 바깥이 뾰족한 쐐기 둘을 등지게 붙인다
		for side = -1, 1, 2 do
			local w = newPart(Vector3.new(0.12 * s, s * 0.62, s * 0.2), color, Enum.Material.Neon, alpha or 0, "wedge")
			local off = CFrame.Angles(0, 0, a) * CFrame.new(side * s * 0.1, s * 0.46, 0) * CFrame.Angles(0, side > 0 and 0 or math.pi, 0) * CFrame.Angles(0, math.rad(90), 0)
			table.insert(list, { p = w, off = off })
		end
	end
	return { list = list, alive = true }
end

------------------------------------------------------------------------
-- 마법진: 바깥·안 고리, 육망성 (두 삼각형), 둘레의 글자 조각. 틀(cf)의 -Z가 마법진이 바라보는 쪽
------------------------------------------------------------------------
local function ringInto(list: { { p: BasePart, off: CFrame } }, R: number, n: number, w: number, color: Color3, alpha: number)
	for k = 0, n - 1 do
		local a0, a1 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
		local p0 = Vector3.new(math.cos(a0) * R, math.sin(a0) * R, 0)
		local p1 = Vector3.new(math.cos(a1) * R, math.sin(a1) * R, 0)
		local seg = newPart(Vector3.new(w, w * 0.5, (p1 - p0).Magnitude * 1.05), color, Enum.Material.Neon, alpha)
		table.insert(list, { p = seg, off = CFrame.lookAt((p0 + p1) / 2, p1, Vector3.new(0, 0, 1)) })
	end
end
local function lineInto(list: { { p: BasePart, off: CFrame } }, a: Vector3, b: Vector3, w: number, color: Color3, alpha: number)
	local seg = newPart(Vector3.new(w, w * 0.5, (b - a).Magnitude), color, Enum.Material.Neon, alpha)
	table.insert(list, { p = seg, off = CFrame.lookAt((a + b) / 2, b, Vector3.new(0, 0, 1)) })
end
type Sigil = { outer: Shape, inner: Shape, cf: CFrame, R: number, spin: number, scale: number, alive: boolean }
local sigils: { Sigil } = {}
local function sigil(cf: CFrame, R: number, c: Color3, c2: Color3, life: number, spin: number?): Sigil
	local outer: Shape = { list = {}, alive = true }
	local inner: Shape = { list = {}, alive = true }
	local w = math.clamp(R * 0.05, 0.12, 0.6)
	ringInto(outer.list, R, math.clamp(math.floor(R * 2.4), 16, 48), w, c2, 0.1)
	ringInto(outer.list, R * 0.86, math.clamp(math.floor(R * 2), 14, 40), w * 0.6, c, 0.2)
	-- 고리 사이를 도는 글자 조각
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local g = newPart(Vector3.new(R * 0.07, R * 0.07, w * 0.4), k % 3 == 0 and c2 or c, Enum.Material.Neon, 0.15)
		table.insert(outer.list, { p = g, off = CFrame.new(math.cos(a) * R * 0.93, math.sin(a) * R * 0.93, 0) * CFrame.Angles(0, 0, a + math.rad(45)) })
	end
	-- 육망성 (안쪽은 거꾸로 돈다)
	for t = 0, 1 do
		local pts = {}
		for k = 0, 2 do
			local a = (k / 3 + t / 6) * math.pi * 2 + math.pi / 2
			pts[k + 1] = Vector3.new(math.cos(a) * R * 0.8, math.sin(a) * R * 0.8, 0)
		end
		for k = 1, 3 do
			lineInto(inner.list, pts[k], pts[k % 3 + 1], w * 0.8, t == 0 and c2 or c, 0.1)
		end
	end
	ringInto(inner.list, R * 0.4, 14, w * 0.6, c2, 0.15)
	local core = newPart(Vector3.new(R * 0.18, R * 0.18, R * 0.18), WHITE, Enum.Material.Neon, 0.1, "ball")
	table.insert(inner.list, { p = core, off = CFrame.new() })
	local sg: Sigil = { outer = outer, inner = inner, cf = cf, R = R, spin = spin or 1.5, scale = 0.05, alive = true }
	table.insert(sigils, sg)
	-- 커지며 열리고, 다 쓰면 줄며 닫힌다
	local t0 = os.clock()
	task.spawn(function()
		while sg.alive and os.clock() - t0 < 0.22 do
			sg.scale = math.min(1, (os.clock() - t0) / 0.2)
			task.wait()
		end
		sg.scale = 1
	end)
	task.delay(life, function()
		if sg.alive then
			sg.alive = false
			shapeFade(outer, 0.3, 1.3)
			shapeFade(inner, 0.3, 0.3)
		end
	end)
	return sg
end
-- 마법진은 매 프레임 돈다 (크기는 열릴 때만 바뀐다: 조각을 틀 안에서 펼친다)
RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for i = #sigils, 1, -1 do
		local sg = sigils[i]
		if not sg.alive then
			table.remove(sigils, i)
		else
			local k = sg.scale
			for _, it in ipairs(sg.outer.list) do
				local o = it.off
				it.p.CFrame = sg.cf * CFrame.Angles(0, 0, t * sg.spin) * (CFrame.new(o.Position * k) * o.Rotation)
			end
			for _, it in ipairs(sg.inner.list) do
				local o = it.off
				it.p.CFrame = sg.cf * CFrame.Angles(0, 0, -t * sg.spin * 1.6) * (CFrame.new(o.Position * k) * o.Rotation)
			end
		end
	end
end)
-- 땅에 눕힌 마법진의 틀 (위를 본다)
local function floorCF(at: Vector3, y: number?): CFrame
	local g = ground(at)
	return CFrame.lookAt(g + Vector3.new(0, y or 0.25, 0), g + Vector3.new(0, 10, 0))
end

-- 별이 꽂히는 자리의 작은 터짐
local function starPop(at: Vector3, c: Color3, c2: Color3, s: number)
	Fx.ring(at, c2, 1, 8 * s, 0.35, Vector3.new(0, 1, 0))
	Fx.burst("glitter", at, c2, math.floor(8 * s), s)
	Fx.burst("spark", at, WHITE, math.floor(5 * s), s * 0.8)
	local f = newPart(Vector3.new(2, 2, 2) * s, PALE, Enum.Material.Neon, 0.2, "ball")
	f.CFrame = CFrame.new(at)
	fadeOut(f, 0.25, { Size = Vector3.new(5, 5, 5) * s })
end
-- 별 하나를 from에서 to로 날린다 (돌면서, 꼬리를 끌며). 모델을 주면 따라간다
local function shootStar(from: Vector3, to: Vector3, travel: number, s: number, c: Color3, c2: Color3, follow: Model?, arc: number?, onHit: ((Vector3) -> ())?)
	local st = makeStar(s, c2, WHITE)
	local t0 = os.clock()
	local side = Vector3.new(math.random() - 0.5, 0.6, math.random() - 0.5) * (arc or 4)
	local last = from
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / travel, 0, 1)
		local goal = to
		if follow then
			local r = rootOf(follow)
			if r then
				goal = r.Position
			end
		end
		local e = u * u * (3 - 2 * u)
		local pos = from:Lerp(goal, e) + side * math.sin(u * math.pi)
		local dir = goal - pos
		if dir.Magnitude < 1e-3 then
			dir = Vector3.new(0, 0, -1)
		end
		shapePlace(st, CFrame.lookAt(pos, pos + dir.Unit) * CFrame.Angles(0, 0, u * 12))
		if (pos - last).Magnitude > 0.6 then
			local tr = beam(last, pos, 0.18 * s, c2, 0.3)
			fadeOut(tr, 0.25, { Size = Vector3.new(0.02, 0.02, tr.Size.Z) })
			last = pos
		end
		if u >= 1 then
			conn:Disconnect()
			shapeFade(st, 0.15, 1.6)
			starPop(pos, c, c2, s)
			if onHit then
				onHit(pos)
			end
		end
	end)
end

------------------------------------------------------------------------
-- 별 지팡이 (오른손). 손 기준 틀 G의 +Z가 지팡이 끝 (어깨 + 팔꿈치가 110도쯤이면 곧게 선다)
------------------------------------------------------------------------
local G = CFrame.Angles(math.rad(160), 0, 0)
local BUTT, TIP = 1.6, 4.3
local tips: { [Model]: { hand: BasePart } } = {}
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
function Star.tipOf(model: Model): Vector3?
	local t = tips[model]
	if t and t.hand.Parent then
		return (t.hand.CFrame * G * CFrame.new(0, 0, TIP + 0.75)).Position
	end
	return nil
end
function Star.buildGear(model: Model): { Instance }
	local out: { Instance } = {}
	local holder = Instance.new("Folder")
	holder.Name = "Staff_" .. model.Name
	holder.Parent = folder
	table.insert(out, holder)
	local hand = model:FindFirstChild("RightHand")
	if not (hand and hand:IsA("BasePart")) then
		return out
	end
	local st = Config.STYLE_BY_ID.chosengha
	local c, c2 = st and st.color or INDIGO, st and st.color2 or GOLD
	local len = BUTT + TIP
	local mid = (TIP - BUTT) / 2
	-- 자루: 짙은 보랏빛 나무, 금빛 띠 셋, 손잡이에 감은 남색 천
	attach(newPart(Vector3.new(len, 0.26, 0.26), WOOD, Enum.Material.Wood), hand, G * CFrame.new(0, 0, mid) * AXIS_Z, holder, out)
	for _, z in ipairs({ -BUTT + 0.15, 1.4, TIP - 0.5 }) do
		attach(newPart(Vector3.new(0.18, 0.32, 0.32), BRASS, Enum.Material.Metal, 0, "cyl"), hand, G * CFrame.new(0, 0, z) * AXIS_Z, holder, out)
	end
	attach(newPart(Vector3.new(1.0, 0.3, 0.3), c, Enum.Material.Fabric, 0, "cyl"), hand, G * CFrame.new(0, 0, 0.1) * AXIS_Z, holder, out)
	-- 물미: 작은 금빛 별 구슬
	attach(newPart(Vector3.new(0.34, 0.34, 0.34), c2, Enum.Material.Neon, 0, "ball"), hand, G * CFrame.new(0, 0, -BUTT - 0.1), holder, out)
	-- 머리: 별을 감싸는 초승달 고리 (금), 고리 끝의 작은 구슬 둘
	local ringR = 0.95
	for k = 0, 9 do
		local a0 = math.rad(-150 + k * 30)
		local a1 = math.rad(-150 + (k + 1) * 30)
		local p0 = Vector3.new(math.cos(a0) * ringR, 0, math.sin(a0) * ringR)
		local p1 = Vector3.new(math.cos(a1) * ringR, 0, math.sin(a1) * ringR)
		local seg = newPart(Vector3.new(0.14, 0.14, (p1 - p0).Magnitude * 1.1), BRASS, Enum.Material.Metal)
		attach(seg, hand, G * CFrame.new(0, 0, TIP + 0.75) * CFrame.lookAt((p0 + p1) / 2, p1), holder, out)
	end
	for _, a in ipairs({ -150, 150 }) do
		local r = math.rad(a)
		attach(newPart(Vector3.new(0.22, 0.22, 0.22), c2, Enum.Material.Neon, 0, "ball"), hand, G * CFrame.new(math.cos(r) * ringR, 0, TIP + 0.75 + math.sin(r) * ringR), holder, out)
	end
	-- 별 (손에 붙이지 않고 매 프레임 놓아 천천히 돈다), 둘레의 빛과 반짝이
	local starS = 1.1
	local head = makeStar(starS, c2, WHITE)
	for _, it in ipairs(head.list) do
		it.p.Parent = holder
		table.insert(out, it.p)
	end
	local glow = newPart(Vector3.new(0.2, 0.2, 0.2), WHITE, Enum.Material.Neon, 1)
	glow.Parent = holder
	table.insert(out, glow)
	local light = Instance.new("PointLight")
	light.Color = c2
	light.Range = 10
	light.Brightness = 1.4
	light.Parent = glow
	local a0 = Instance.new("Attachment")
	a0.Parent = glow
	local sp = emitter(a0, TEX_SPARK, c2, VIOLET, 5, 0.3, 0.9, 1.5)
	sp.Acceleration = Vector3.new(0, -2, 0)
	-- 끝에 매단 작은 별 장식 둘 (흔들린다)
	local charms: { Shape } = { makeStar(0.35, c2, WHITE), makeStar(0.3, VIOLET, WHITE) }
	for _, ch in ipairs(charms) do
		for _, it in ipairs(ch.list) do
			it.p.Parent = holder
			table.insert(out, it.p)
		end
	end
	tips[model] = { hand = hand }
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if not holder.Parent or not hand.Parent then
			conn:Disconnect()
			tips[model] = nil
			return
		end
		local t = os.clock() - t0
		local top = hand.CFrame * G * CFrame.new(0, 0, TIP + 0.75)
		local hide = model:GetAttribute("Vanish") == true
		shapePlace(head, top * CFrame.Angles(0, t * 1.2, 0) * CFrame.Angles(math.rad(90), 0, 0))
		glow.CFrame = top
		light.Enabled = not hide
		for i, ch in ipairs(charms) do
			local swing = math.sin(t * 2.4 + i) * 0.35
			local base = hand.CFrame * G * CFrame.new(i == 1 and 0.6 or -0.6, 0, TIP - 0.1)
			local pos = (base * CFrame.new(0, 0, 0)).Position - Vector3.new(0, 0.6, 0) + Vector3.new(swing * 0.4, 0, swing * 0.2)
			shapePlace(ch, CFrame.new(pos) * CFrame.Angles(0, t * 2 + i, 0))
		end
		for _, it in ipairs(head.list) do
			it.p.LocalTransparencyModifier = hide and 1 or 0
		end
	end)
	return out
end

------------------------------------------------------------------------
-- 연타 장치 별진: 상대 발밑에 마법진이 열리고 별이 솟았다가 내리꽂힌다
------------------------------------------------------------------------
local function starSigil(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local c, c2 = colors(data.style)
	local delay = data.delay or 0.35
	local R = (data.radius or 8) * 0.55
	sigil(floorCF(at), R, c, c2, delay + 0.2, 2.2)
	Fx.sound("ping", 0.5, 1.6, at)
	local g = ground(at)
	local st = makeStar(1.6, c2, WHITE)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp(t / delay, 0, 1)
		-- 0~0.7: 솟아올라 돈다, 0.7~1: 내리꽂힌다
		local h = u < 0.7 and 6 * math.sin(u / 0.7 * math.pi / 2) or 6 * (1 - (u - 0.7) / 0.3)
		local pos = g + Vector3.new(0, 0.5 + h, 0)
		shapePlace(st, CFrame.new(pos) * CFrame.Angles(0, t * 14, 0))
		if u >= 1 then
			conn:Disconnect()
			shapeFade(st, 0.2, 2)
			starPop(g + Vector3.new(0, 1, 0), c, c2, 1.4)
			Fx.ring(g + Vector3.new(0, 0.3, 0), c2, 2, (data.radius or 8) * 2, 0.4)
		end
	end)
end

------------------------------------------------------------------------
-- E 별똥 화살: 지팡이 끝 앞에 선 마법진, 별이 하나씩 날아가 꽂힌다
------------------------------------------------------------------------
local function starVolley(data: any)
	local from: Vector3 = data.from
	if not near(from, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local aims = data.aims or {}
	local model: Model? = data.m
	local r = rootOf(model)
	local look = r and flat(r.CFrame.LookVector) or Vector3.new(0, 0, -1)
	local delay = data.delay or 0.18
	local every = data.every or 0.07
	local travel = data.travel or 0.28
	local origin = (model and Star.tipOf(model)) or from
	sigil(CFrame.lookAt(origin + look * 1.2, origin + look * 10), 2.6, c, c2, delay + every * #aims + 0.25, 3)
	Fx.sound("ping", 0.6, 1.3, origin)
	for i, a in ipairs(aims) do
		task.delay(delay + (i - 1) * every, function()
			local o = origin + look * 1.2 + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 1.6
			shootStar(o, a.at + Vector3.new(0, 0.5, 0), travel, 1.1, c, c2, a.m, 3)
			Fx.sound("swing", 0.35, 1.6, o)
		end)
	end
end

------------------------------------------------------------------------
-- R 성좌진: 땅의 큰 마법진, 별 일곱이 떠올라 선으로 이어지고, 별빛 기둥
------------------------------------------------------------------------
local function starSeal(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 12
	local n = data.stars or 7
	local delay = data.delay or 0.35
	local link = data.link or 0.1
	local total = delay + (n + 1) * link + 0.1
	local g = ground(at)
	sigil(floorCF(at), R, c, c2, total + 0.25, 1.2)
	local floorGlow = newPart(Vector3.new(0.2, R * 2, R * 2), NAVY, Enum.Material.Neon, 0.75, "cyl")
	floorGlow.CFrame = CFrame.new(g + Vector3.new(0, 0.12, 0)) * UP
	-- 별자리의 점: 둘레에 고르지 않게 흩어 놓는다
	local pts: { Vector3 } = {}
	local stars: { Shape } = {}
	local lines: { BasePart } = {}
	local base = math.random() * math.pi * 2
	for i = 1, n do
		local a = base + i / n * math.pi * 2 + (math.random() - 0.5) * 0.5
		local rr = R * (0.45 + math.random() * 0.4)
		pts[i] = g + Vector3.new(math.cos(a) * rr, 3 + math.random() * 3.5, math.sin(a) * rr)
	end
	for i = 1, n do
		task.delay(delay + i * link, function()
			local st = makeStar(1.3, c2, WHITE)
			shapePlace(st, CFrame.new(pts[i]))
			stars[i] = st
			Fx.burst("glitter", pts[i], c2, 5, 0.8)
			if i > 1 then
				table.insert(lines, beam(pts[i - 1], pts[i], 0.18, PALE, 0.15))
			end
			Fx.sound("ping", 0.35, 1.2 + i * 0.08, pts[i])
		end)
	end
	-- 별들은 천천히 돈다
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		for i, st in pairs(stars) do
			shapePlace(st, CFrame.new(pts[i]) * CFrame.Angles(0, t * 3 + i, 0))
		end
		if t > total + 0.4 then
			conn:Disconnect()
		end
	end)
	task.delay(delay + (n + 1) * link, function()
		table.insert(lines, beam(pts[n], pts[1], 0.18, PALE, 0.15))
	end)
	task.delay(total, function()
		-- 별자리가 번쩍이고 가운데에서 별빛 기둥이 솟는다
		for _, l in ipairs(lines) do
			l.Color = WHITE
			fadeOut(l, 0.4, { Size = Vector3.new(0.6, 0.6, l.Size.Z) })
		end
		for i, st in pairs(stars) do
			shapeFade(st, 0.35, 2.2)
			Fx.burst("spark", pts[i], c2, 6, 1)
		end
		local col = newPart(Vector3.new(2, R * 0.8, R * 0.8), c2, Enum.Material.Neon, 0.1, "cyl")
		col.CFrame = CFrame.new(g + Vector3.new(0, 1, 0)) * UP
		tween(col, 0.18, { Size = Vector3.new(60, R * 0.8, R * 0.8), CFrame = CFrame.new(g + Vector3.new(0, 30, 0)) * UP })
		task.delay(0.2, function()
			fadeOut(col, 0.5, { Size = Vector3.new(60, R * 1.6, R * 1.6) })
		end)
		local inner = newPart(Vector3.new(2, R * 0.4, R * 0.4), WHITE, Enum.Material.Neon, 0, "cyl")
		inner.CFrame = CFrame.new(g + Vector3.new(0, 1, 0)) * UP
		tween(inner, 0.15, { Size = Vector3.new(64, R * 0.4, R * 0.4), CFrame = CFrame.new(g + Vector3.new(0, 32, 0)) * UP })
		task.delay(0.2, function()
			fadeOut(inner, 0.4)
		end)
		Fx.ring(g + Vector3.new(0, 0.4, 0), c2, 4, R * 2.6, 0.5)
		Fx.flash(g + Vector3.new(0, 4, 0), c2, 50, 6, 0.4)
		Fx.sound("heavy", 0.9, 1.3, g)
		shakeNear(g, 1.2, 100)
		fadeOut(floorGlow, 0.5)
	end)
end

------------------------------------------------------------------------
-- G 은하수: 커다란 지팡이가 내리꽂히고, 보라·남색·노란 안개 속에서 별이 두 팔의 나선으로 소용돌이친다
------------------------------------------------------------------------
local function bigStaff(length: number): { BasePart }
	local parts: { BasePart } = {}
	local shaft = newPart(Vector3.new(length, 1.4, 1.4), WOOD, Enum.Material.Wood, 0, "cyl")
	table.insert(parts, shaft)
	for _ = 1, 3 do
		table.insert(parts, newPart(Vector3.new(1, 1.9, 1.9), BRASS, Enum.Material.Metal, 0, "cyl"))
	end
	return parts
end
local function placeBigStaff(parts: { BasePart }, foot: Vector3, length: number)
	-- 곧게 서서 발끝이 foot에 닿는다
	parts[1].Size = Vector3.new(length, 1.4, 1.4)
	parts[1].CFrame = CFrame.new(foot + Vector3.new(0, length / 2, 0)) * UP
	for k = 2, #parts do
		local y = ({ length * 0.08, length * 0.55, length * 0.92 })[k - 1]
		parts[k].CFrame = CFrame.new(foot + Vector3.new(0, y, 0)) * UP
	end
end
local function galaxyStaff(data: any)
	local at: Vector3 = data.at
	if not near(at, 260) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 24
	local delay = data.delay or 0.55
	local dur = data.dur or 3.2
	local g = ground(at)
	local L = 26
	-- 지팡이가 하늘에서 자라며 내려와 꽂힌다
	local parts = bigStaff(L)
	local headStar = makeStar(5, c2, WHITE)
	local headGlow = newPart(Vector3.new(1, 1, 1), WHITE, Enum.Material.Neon, 1)
	local hl = Instance.new("PointLight")
	hl.Color = c2
	hl.Range = 40
	hl.Brightness = 3
	hl.Parent = headGlow
	local t0 = os.clock()
	local sink = 4
	local landed = false
	local swirl: { { s: Shape, a: number, r: number, h: number, sp: number } } = {}
	local fogParts: { BasePart } = {}
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp(t / delay, 0, 1)
		local foot = g + Vector3.new(0, (1 - u * u) * 40 - sink * u * u, 0)
		local len = L * (0.35 + 0.65 * u)
		placeBigStaff(parts, foot, len)
		local topPos = foot + Vector3.new(0, len + 2.6, 0)
		shapePlace(headStar, CFrame.new(topPos) * CFrame.Angles(0, t * 1.5, 0))
		headGlow.CFrame = CFrame.new(topPos)
		if u >= 1 and not landed then
			landed = true
			Fx.ring(g + Vector3.new(0, 0.4, 0), c2, 4, R * 2.2, 0.6)
			Fx.ring(g + Vector3.new(0, 0.6, 0), VIOLET, 2, R * 1.4, 0.5)
			Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(120, 100, 160), 24, 1.6)
			Fx.flash(g + Vector3.new(0, 6, 0), c2, 60, 5, 0.4)
			Fx.sound("heavy", 1, 0.7, g)
			shakeNear(g, 2, 120)
			sigil(floorCF(at, 0.3), R, c, c2, dur, 0.5)
			-- 세 빛 안개: 땅을 덮는 큰 원판들에서 연기가 피어오른다
			for k, col in ipairs({ VIOLET, INDIGO, c2 }) do
				local a = newPart(Vector3.new(0.2, R * 2, R * 2), col, Enum.Material.Neon, 0.88, "cyl")
				a.CFrame = CFrame.new(g + Vector3.new(0, 0.2 + k * 0.05, 0)) * UP
				table.insert(fogParts, a)
				local holder = newPart(Vector3.new(R * 1.6, 1, R * 1.6), col, Enum.Material.Neon, 1)
				holder.CFrame = CFrame.new(g + Vector3.new(0, 1.5 + k, 0))
				table.insert(fogParts, holder)
				local e = Instance.new("ParticleEmitter")
				e.Texture = TEX_SMOKE
				e.Color = ColorSequence.new(col)
				e.LightEmission = 0.5
				e.Rate = 14
				e.Lifetime = NumberRange.new(1.5, 2.6)
				e.Speed = NumberRange.new(0.5, 2)
				e.SpreadAngle = Vector2.new(180, 30)
				e.RotSpeed = NumberRange.new(-20, 20)
				e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 9) })
				e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55), NumberSequenceKeypoint.new(1, 1) })
				e.Shape = Enum.ParticleEmitterShape.Box
				e.Parent = holder
				local sp = emitter(holder, TEX_SPARK, c2, WHITE, 10, 0.5, 1.4, 2)
				sp.Shape = Enum.ParticleEmitterShape.Box
			end
			-- 은하의 별: 두 팔의 나선 (가운데로 갈수록 빠르다)
			for arm = 0, 1 do
				for j = 1, 18 do
					local r = R * (0.12 + j / 18 * 0.85)
					local s = makeStar(0.5 + math.random() * 0.7, j % 3 == 0 and VIOLET or (j % 3 == 1 and c2 or PALE), WHITE, 0.05)
					table.insert(swirl, { s = s, a = arm * math.pi + j * 0.32 + (math.random() - 0.5) * 0.3, r = r, h = 1 + math.random() * 3.5, sp = 2.2 * (1.2 - j / 18 * 0.8) })
				end
			end
			for _ = 1, 14 do
				local s = makeStar(0.35, PALE, WHITE, 0.2)
				table.insert(swirl, { s = s, a = math.random() * math.pi * 2, r = R * (0.2 + math.random() * 0.8), h = 0.6 + math.random() * 5, sp = 1.4 })
			end
		end
		if landed then
			local tt = t - delay
			local gather = math.clamp((tt - dur + 0.35) / 0.35, 0, 1) -- 끝에 가운데로 모인다
			for _, it in ipairs(swirl) do
				local a = it.a + tt * it.sp
				local r = it.r * (1 - gather)
				local pos = g + Vector3.new(math.cos(a) * r, it.h + math.sin(tt * 2 + it.a) * 0.4 + gather * 6, math.sin(a) * r)
				shapePlace(it.s, CFrame.new(pos) * CFrame.Angles(0, tt * 4 + it.a, 0))
			end
			if tt >= dur then
				conn:Disconnect()
				for _, it in ipairs(swirl) do
					shapeFade(it.s, 0.3, 2)
				end
				for _, p in ipairs(fogParts) do
					for _, e in ipairs(p:GetChildren()) do
						if e:IsA("ParticleEmitter") then
							e.Enabled = false
						end
					end
					fadeOut(p, 1.2)
				end
				-- 은하가 터진다
				local core = newPart(Vector3.new(4, 4, 4), WHITE, Enum.Material.Neon, 0, "ball")
				core.CFrame = CFrame.new(g + Vector3.new(0, 6, 0))
				fadeOut(core, 0.5, { Size = Vector3.new(R * 1.6, R * 1.6, R * 1.6) })
				local shell = newPart(Vector3.new(4, 4, 4), VIOLET, Enum.Material.Neon, 0.3, "ball")
				shell.CFrame = core.CFrame
				fadeOut(shell, 0.7, { Size = Vector3.new(R * 2.2, R * 2.2, R * 2.2) })
				for k = 0, 2 do
					task.delay(k * 0.08, function()
						Fx.ring(g + Vector3.new(0, 0.5 + k, 0), k == 1 and VIOLET or c2, 4, R * 2.6 + k * 8, 0.6)
					end)
				end
				Fx.burst("glitter", g + Vector3.new(0, 6, 0), c2, 30, 2.4)
				Fx.flash(g + Vector3.new(0, 6, 0), c2, 90, 8, 0.6)
				Fx.sound("heavy", 1, 0.5, g)
				Fx.sound("shatter", 0.8, 1.2, g)
				shakeNear(g, 2.8, 150)
				for _, p in ipairs(parts) do
					fadeOut(p, 0.6)
				end
				shapeFade(headStar, 0.5, 3)
				fadeOut(headGlow, 0.5)
			end
		end
	end)
end

------------------------------------------------------------------------
-- X 성천궁: 남색 돔, 공중의 마법진에서 별, 메테오, 돔 표면의 별자리, 한꺼번에 폭발
------------------------------------------------------------------------
type Dome = { at: Vector3, R: number, parts: { BasePart }, dots: { Vector3 }, dotParts: { BasePart }, lines: { BasePart }, done: boolean }
local domes: { [number]: Dome } = {}
local function domePoint(g: Vector3, R: number, a: number, el: number): Vector3
	return g + Vector3.new(math.cos(a) * math.cos(el) * R, math.sin(el) * R, math.sin(a) * math.cos(el) * R)
end
local function domeEnd(d: Dome)
	if d.done then
		return
	end
	d.done = true
	for _, p in ipairs(d.parts) do
		if p.Parent then
			fadeOut(p, 0.6)
		end
	end
	for _, p in ipairs(d.dotParts) do
		if p.Parent then
			fadeOut(p, 0.3)
		end
	end
	for _, p in ipairs(d.lines) do
		if p.Parent then
			fadeOut(p, 0.3)
		end
	end
end
local function starDomeOpen(data: any)
	local at: Vector3 = data.at
	if not near(at, 320) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 34
	local cut = data.cut or 1.4
	local g = ground(at)
	local d: Dome = { at = g, R = R, parts = {}, dots = {}, dotParts = {}, lines = {}, done = false }
	domes[data.id] = d
	-- 돔: 바깥 남색 유리 + 안쪽 옅은 빛. 반은 땅에 묻힌 공
	local shell = newPart(Vector3.new(1, 1, 1), NAVY, Enum.Material.Glass, 0.45, "ball")
	shell.CFrame = CFrame.new(g)
	local glow = newPart(Vector3.new(1, 1, 1), c, Enum.Material.Neon, 0.9, "ball")
	glow.CFrame = CFrame.new(g)
	local rim = newPart(Vector3.new(0.4, 1, 1), c2, Enum.Material.Neon, 0.2, "cyl")
	rim.CFrame = CFrame.new(g + Vector3.new(0, 0.2, 0)) * UP
	table.insert(d.parts, shell)
	table.insert(d.parts, glow)
	table.insert(d.parts, rim)
	local open = cut * 0.7
	tween(shell, open, { Size = Vector3.new(R * 2, R * 2, R * 2) }, Enum.EasingStyle.Back)
	tween(glow, open, { Size = Vector3.new(R * 2 - 1, R * 2 - 1, R * 2 - 1) }, Enum.EasingStyle.Back)
	tween(rim, open, { Size = Vector3.new(0.4, R * 2 + 1, R * 2 + 1) }, Enum.EasingStyle.Back)
	-- 돔 안쪽에 박힌 별 점 (나중에 별자리가 된다)
	task.delay(open, function()
		if d.done then
			return
		end
		Fx.ring(g + Vector3.new(0, 0.5, 0), c2, R, R * 2.4, 0.6)
		Fx.sound("heavy", 0.9, 0.6, g)
		shakeNear(g, 1.6, 160)
		for k = 1, 34 do
			local a = math.random() * math.pi * 2
			local el = math.rad(15 + math.random() * 65)
			local pos = domePoint(g, R * 0.97, a, el)
			table.insert(d.dots, pos)
			local dot = newPart(Vector3.new(0.6, 0.6, 0.6), k % 4 == 0 and c2 or PALE, Enum.Material.Neon, 0.3, "ball")
			dot.CFrame = CFrame.new(pos)
			table.insert(d.dotParts, dot)
		end
	end)
	-- 쓰는 사람 발밑의 큰 마법진
	sigil(floorCF(at, 0.3), R * 0.5, c, c2, cut + (data.rain or 2.6) + (data.draw or 0.9), 0.4)
	-- 늦게 도착한 이벤트로 남지 않게
	task.delay(cut + (data.rain or 2.6) + (data.draw or 0.9) + 3, function()
		domeEnd(d)
		domes[data.id] = nil
	end)
end
local function domeStars(data: any)
	local d = domes[data.id]
	if not d or d.done then
		return
	end
	local c, c2 = colors(data.style)
	for _, pt in ipairs(data.pts or {}) do
		local high = Vector3.new(pt.X, d.at.Y + math.min(d.R * 0.7, 18) + math.random() * 4, pt.Z) + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 6
		sigil(CFrame.lookAt(high, high - Vector3.new(0, 10, 0)), 2.4, c, c2, 0.45, 3)
		task.delay(0.08, function()
			shootStar(high - Vector3.new(0, 0.5, 0), pt, 0.18, 0.9, c, c2, nil, 1)
		end)
	end
end
local function domeMeteor(data: any)
	local d = domes[data.id]
	local at: Vector3 = data.at
	if not near(at, 320) then
		return
	end
	local c, c2 = colors(data.style)
	local fall = data.fall or 0.35
	local g = ground(at)
	local top = (d and d.at or g) + Vector3.new((math.random() - 0.5) * 20, (d and d.R or 30) * 0.95, (math.random() - 0.5) * 20)
	local rock = newPart(Vector3.new(4.5, 4.5, 4.5), Color3.fromRGB(70, 50, 60), Enum.Material.Basalt, 0, "ball")
	local core = newPart(Vector3.new(5.6, 5.6, 5.6), Color3.fromRGB(255, 150, 80), Enum.Material.Neon, 0.55, "ball")
	local a0 = Instance.new("Attachment")
	a0.Parent = rock
	local fire = Instance.new("ParticleEmitter")
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 200, 120), VIOLET)
	fire.LightEmission = 1
	fire.Rate = 60
	fire.Lifetime = NumberRange.new(0.3, 0.6)
	fire.Speed = NumberRange.new(2, 6)
	fire.Size = NumberSequence.new(3, 0)
	fire.Transparency = NumberSequence.new(0.1, 1)
	fire.Parent = a0
	sigil(floorCF(at, 0.35), (data.radius or 8), c, c2, fall + 0.2, 2)
	local t0 = os.clock()
	local last = top
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / fall, 0, 1)
		local pos = top:Lerp(g + Vector3.new(0, 1.5, 0), u * u)
		rock.CFrame = CFrame.new(pos) * CFrame.Angles(u * 6, u * 4, 0)
		core.CFrame = CFrame.new(pos)
		if (pos - last).Magnitude > 1.5 then
			local tr = beam(last, pos, 2.2, Color3.fromRGB(255, 180, 110), 0.35)
			fadeOut(tr, 0.3, { Size = Vector3.new(0.2, 0.2, tr.Size.Z) })
			last = pos
		end
		if u >= 1 then
			conn:Disconnect()
			fire.Enabled = false
			fadeOut(rock, 0.25)
			fadeOut(core, 0.25, { Size = Vector3.new(14, 14, 14) })
			Fx.ring(g + Vector3.new(0, 0.4, 0), Color3.fromRGB(255, 170, 100), 3, (data.radius or 8) * 2.4, 0.5)
			Fx.burst("ember", g + Vector3.new(0, 1, 0), Color3.fromRGB(255, 160, 90), 16, 1.4)
			Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(110, 90, 110), 12, 1.2)
			Fx.flash(g + Vector3.new(0, 3, 0), Color3.fromRGB(255, 170, 110), 40, 5, 0.3)
			Fx.sound("heavy", 0.9, 0.8, g)
			shakeNear(g, 1.4, 120)
		end
	end)
end
-- 돔 표면에 별자리를 빛으로 긋고, 다 그으면 모두 한꺼번에 터진다
local function domeDraw(data: any)
	local d = domes[data.id]
	if not d or d.done then
		return
	end
	local _, c2 = colors(data.style)
	local draw = data.draw or 0.9
	local dots = d.dots
	-- 가까운 점끼리 이어 별자리 여럿 (점 넷~여섯씩)
	local used: { [number]: boolean } = {}
	local groups: { { Vector3 } } = {}
	for _ = 1, 6 do
		local start = 0
		for i = 1, #dots do
			if not used[i] then
				start = i
				break
			end
		end
		if start == 0 then
			break
		end
		local chain = { dots[start] }
		used[start] = true
		local cur = start
		for _ = 1, 3 + math.random(0, 2) do
			local best, bestD = nil, math.huge
			for j = 1, #dots do
				if not used[j] then
					local dd = (dots[j] - dots[cur]).Magnitude
					if dd < bestD then
						best, bestD = j, dd
					end
				end
			end
			if not best then
				break
			end
			used[best] = true
			cur = best
			table.insert(chain, dots[best])
		end
		table.insert(groups, chain)
	end
	-- 선을 하나씩 늘려 긋는다
	local segs: { { a: Vector3, b: Vector3, at: number } } = {}
	local total = 0
	for _, chain in ipairs(groups) do
		total += #chain - 1
	end
	local k = 0
	for _, chain in ipairs(groups) do
		for i = 1, #chain - 1 do
			table.insert(segs, { a = chain[i], b = chain[i + 1], at = k / math.max(1, total) * draw * 0.85 })
			k += 1
		end
	end
	for _, sg in ipairs(segs) do
		task.delay(sg.at, function()
			if d.done then
				return
			end
			local ln = beam(sg.a, sg.a, 0.35, PALE, 0.05)
			table.insert(d.lines, ln)
			local t0 = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function()
				local u = math.clamp((os.clock() - t0) / 0.12, 0, 1)
				if not ln.Parent then
					conn:Disconnect()
					return
				end
				local b = sg.a:Lerp(sg.b, u)
				if (b - sg.a).Magnitude > 0.05 then
					ln.Size = Vector3.new(0.35, 0.35, (b - sg.a).Magnitude)
					ln.CFrame = CFrame.lookAt((sg.a + b) / 2, b)
				end
				if u >= 1 then
					conn:Disconnect()
				end
			end)
			Fx.sound("ping", 0.3, 1.5 + math.random() * 0.4, sg.b)
		end)
	end
	for _, p in ipairs(d.dotParts) do
		tween(p, draw, { Size = Vector3.new(1.4, 1.4, 1.4), Transparency = 0 })
	end
	task.delay(draw, function()
		if d.done then
			return
		end
		-- 별자리가 하얗게 번쩍인 뒤 돔째로 터진다
		for _, l in ipairs(d.lines) do
			l.Color = WHITE
			tween(l, 0.12, { Size = Vector3.new(1.2, 1.2, l.Size.Z) })
		end
		for _, p in ipairs(d.dotParts) do
			p.Color = WHITE
			Fx.burst("spark", p.Position, c2, 4, 1.2)
		end
		task.delay(0.12, function()
			local g = d.at
			local R = d.R
			for k2 = 0, 3 do
				task.delay(k2 * 0.07, function()
					Fx.ring(g + Vector3.new(0, 0.5 + k2 * 2, 0), k2 % 2 == 0 and c2 or VIOLET, R * 0.5, R * 3 + k2 * 10, 0.7)
				end)
			end
			local core = newPart(Vector3.new(6, 6, 6), WHITE, Enum.Material.Neon, 0, "ball")
			core.CFrame = CFrame.new(g + Vector3.new(0, R * 0.3, 0))
			fadeOut(core, 0.6, { Size = Vector3.new(R * 2.2, R * 2.2, R * 2.2) })
			-- 돔 조각이 사방으로 흩어진다
			for _ = 1, 26 do
				local a = math.random() * math.pi * 2
				local el = math.rad(10 + math.random() * 70)
				local pos = domePoint(g, R, a, el)
				local sh = newPart(Vector3.new(3 + math.random() * 4, 0.3, 3 + math.random() * 4), NAVY, Enum.Material.Glass, 0.3)
				sh.CFrame = CFrame.lookAt(pos, g) * CFrame.Angles(math.rad(90), 0, 0)
				fadeOut(sh, 0.8, { CFrame = CFrame.new(pos + (pos - g).Unit * 18) * CFrame.Angles(math.random() * 6, math.random() * 6, 0) })
			end
			Fx.burst("glitter", g + Vector3.new(0, R * 0.3, 0), c2, 40, 3)
			Fx.flash(g + Vector3.new(0, R * 0.3, 0), c2, 140, 10, 0.7)
			Fx.sound("shatter", 1, 0.8, g)
			Fx.sound("heavy", 1, 0.4, g)
			shakeNear(g, 3.4, 220)
			if opts.flash and near(g, R * 2) then
				opts.flash(WHITE, 0.25)
			end
			domeEnd(d)
		end)
	end)
end

-- 초 오의 컷씬 (쓴 사람 화면에서만): 하늘이 남색 밤이 되고 별이 하나둘 뜬다. 무릎 꿇은 나를 아래에서 올려다보다 밤하늘로
local cutActive = false
function Star.superCut(model: Model, dur: number, name: string, shake: ((number) -> ())?)
	local cam = workspace.CurrentCamera
	local r = rootOf(model)
	if not cam or not r or cutActive then
		return
	end
	cutActive = true
	local pg = player:WaitForChild("PlayerGui")
	local g = Instance.new("ScreenGui")
	g.Name = "KwonStarCut"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 85
	g.Parent = pg
	local tintF = Instance.new("Frame")
	tintF.Size = UDim2.fromScale(1, 1)
	tintF.BackgroundColor3 = Color3.fromRGB(14, 14, 60)
	tintF.BackgroundTransparency = 1
	tintF.BorderSizePixel = 0
	tintF.Parent = g
	tween(tintF, 0.3, { BackgroundTransparency = 0.45 })
	-- 화면 위쪽에 별이 하나둘 뜬다
	for k = 1, 40 do
		local s = Instance.new("Frame")
		local size = 2 + math.random() * 4
		s.Size = UDim2.fromOffset(size, size)
		s.AnchorPoint = Vector2.new(0.5, 0.5)
		s.Position = UDim2.fromScale(math.random(), 0.12 + math.random() * 0.5)
		s.BackgroundColor3 = k % 5 == 0 and GOLD or WHITE
		s.BackgroundTransparency = 1
		s.BorderSizePixel = 0
		s.ZIndex = 2
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(1, 0)
		cr.Parent = s
		s.Parent = tintF
		task.delay(math.random() * dur * 0.7, function()
			tween(s, 0.25, { BackgroundTransparency = 0.05 })
		end)
	end
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
	label.TextStrokeColor3 = Color3.fromRGB(70, 50, 170)
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
		RunService:UnbindFromRenderStep("KwonStarCut")
		cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
		cam.FieldOfView = oldFov
		cutActive = false
		for _, b in ipairs(bars) do
			tween(b, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
		end
		tween(tintF, 0.25, { BackgroundTransparency = 1 })
		for _, s in ipairs(tintF:GetChildren()) do
			if s:IsA("Frame") then
				tween(s, 0.2, { BackgroundTransparency = 1 })
			end
		end
		tween(label, 0.2, { TextTransparency = 1 })
		task.delay(0.3, function()
			g:Destroy()
		end)
	end
	RunService:BindToRenderStep("KwonStarCut", Enum.RenderPriority.Camera.Value + 2, function()
		local t = os.clock() - t0
		local k = math.clamp(t / dur, 0, 1)
		-- 앞 아래에서 나를 올려다보다가, 천천히 물러나며 위로 (밤하늘)
		local a = k * math.rad(50)
		local eye = focus + look * (7 + k * 6) * math.cos(a) + side * 6 * math.sin(a) + Vector3.new(0, 0.6 + k * 2, 0)
		local target = focus:Lerp(focus + Vector3.new(0, 40, 0) - look * 10, k * 0.8)
		cam.CFrame = CFrame.lookAt(eye, target)
		cam.FieldOfView = oldFov + k * 14
		if t >= dur then
			restore()
		end
	end)
	if shake then
		task.delay(dur * 0.6, function()
			shake(0.7)
		end)
	end
	task.delay(dur + 1, restore)
end

local HANDLERS: { [string]: (any) -> () } = {
	starVolley = starVolley,
	starSeal = starSeal,
	galaxyStaff = galaxyStaff,
	starDomeOpen = starDomeOpen,
	domeStars = domeStars,
	domeMeteor = domeMeteor,
	domeDraw = domeDraw,
}
function Star.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil or (data.kind == "pulse" and data.fx == "starSigil")
end
function Star.run(data: any)
	if data.kind == "pulse" then
		starSigil(data)
		return
	end
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

return Star
