-- 권왕 3.10판: 몽유권 (화면). 반쯤 잠든 채 꿈속을 걷는 권
-- 빛깔은 밤하늘빛 (남빛·보랏빛, 안개처럼 번진다)과 따뜻한 달빛. 꿈의 문, 울타리를 넘는 꿈양, 뒤집히는 중력, 떠다니는 섬·계단·문, 보름달과 밤 호수
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Fx = require(script.Parent:WaitForChild("Fx"))

local Dream = {}

local NIGHT = Color3.fromRGB(34, 38, 96)
local DUSK = Color3.fromRGB(120, 124, 230)
local LAVENDER = Color3.fromRGB(196, 176, 255)
local MOON = Color3.fromRGB(255, 232, 170)
local STAR = Color3.fromRGB(255, 250, 232)
local MIST = Color3.fromRGB(205, 205, 255)
local WOOL = Color3.fromRGB(246, 244, 240)
local DOORWOOD = Color3.fromRGB(72, 58, 104)
local UP = CFrame.Angles(0, 0, math.rad(90))
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local folder = Instance.new("Folder")
folder.Name = "KwonDream"
folder.Parent = workspace

local opts: any = {}
function Dream.init(o: any)
	opts = o or {}
end

local function part(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, shape: string?): Part
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
-- 별가루 (위로 천천히 떠오르며 깜박인다)
local function stardust(at: Vector3, n: number, s: number, rise: number?)
	for k = 1, n do
		local c = (k % 3 == 0) and MOON or ((k % 3 == 1) and STAR or LAVENDER)
		local q = part(Vector3.one * 0.3 * s, c, Enum.Material.Neon, 0.05, "ball")
		q.CFrame = CFrame.new(at + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2 * s)
		fadeOut(q, 0.9 + math.random() * 0.6, { CFrame = q.CFrame + Vector3.new((math.random() - 0.5) * 3 * s, (rise or 4) * (0.4 + math.random()), (math.random() - 0.5) * 3 * s) })
	end
end
-- 잠의 Z (글자 판이 떠올라 사라진다)
local function zzz(at: Vector3, s: number)
	local holder = part(Vector3.new(0.2, 0.2, 0.2), LAVENDER, Enum.Material.Neon, 1)
	holder.CFrame = CFrame.new(at)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(2.4 * s, 2.4 * s)
	bb.LightInfluence = 0
	bb.Parent = holder
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = "z Z"
	t.TextColor3 = LAVENDER
	t.Parent = bb
	tween(holder, 1.2, { CFrame = CFrame.new(at + Vector3.new(0.6, 3, 0)) })
	tween(t, 1.2, { TextTransparency = 1 })
	task.delay(1.25, function()
		holder:Destroy()
	end)
end
-- 꿈 안개 한 무더기 (낮게 번진다)
local function mist(at: Vector3, s: number, life: number)
	for k = 1, 4 do
		local m = part(Vector3.new(4, 1.4, 4) * s, (k % 2 == 0) and MIST or LAVENDER, Enum.Material.SmoothPlastic, 0.6, "ball")
		m.CFrame = CFrame.new(at + Vector3.new((math.random() - 0.5) * 3 * s, 0.4, (math.random() - 0.5) * 3 * s))
		fadeOut(m, life, { Size = m.Size * 1.8, CFrame = m.CFrame + Vector3.new(0, 0.8 * s, 0) })
	end
end
-- 초승달 (호를 따라 조각을 이어 붙인다): 조각 목록과 각 조각의 자리 (틀 기준)
local function crescentParts(R: number, thick: number, color: Color3, alpha: number?): { { p: Part, off: CFrame } }
	local out = {}
	for k = 0, 10 do
		local a = math.rad(-100 + k * 20)
		local w = thick * math.sin((k + 0.5) / 11 * math.pi) + thick * 0.12
		local seg = part(Vector3.new(w, R * 0.34, w * 0.7), color, Enum.Material.Neon, alpha or 0)
		table.insert(out, { p = seg, off = CFrame.new(math.cos(a) * R, math.sin(a) * R, 0) * CFrame.Angles(0, 0, a) })
	end
	return out
end
local function placeList(list: { { p: Part, off: CFrame } }, cf: CFrame)
	for _, it in ipairs(list) do
		if it.p.Parent then
			it.p.CFrame = cf * it.off
		end
	end
end

------------------------------------------------------------------------
-- 차림: 머리 뒤를 천천히 도는 초승달, 둘레에서 깜박이는 작은 별 셋, 발밑에 번지는 꿈 안개
------------------------------------------------------------------------
function Dream.buildGear(model: Model): { Instance }
	local out: { Instance } = {}
	local holder = Instance.new("Folder")
	holder.Name = "Dream_" .. model.Name
	holder.Parent = folder
	table.insert(out, holder)
	local head = model:FindFirstChild("Head")
	local torso = model:FindFirstChild("UpperTorso")
	if not (head and head:IsA("BasePart")) or not (torso and torso:IsA("BasePart")) then
		return out
	end
	local moon = crescentParts(0.85, 0.32, MOON, 0.05)
	for _, it in ipairs(moon) do
		it.p.Parent = holder
		table.insert(out, it.p)
	end
	local stars: { Part } = {}
	for k = 1, 3 do
		local s = part(Vector3.new(0.22, 0.22, 0.22), STAR, Enum.Material.Neon, 0, "ball")
		s.Parent = holder
		table.insert(out, s)
		stars[k] = s
	end
	local foot = part(Vector3.new(2, 0.2, 2), LAVENDER, Enum.Material.SmoothPlastic, 1)
	foot.Parent = holder
	table.insert(out, foot)
	local a0 = Instance.new("Attachment")
	a0.Parent = foot
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_SMOKE
	e.Color = ColorSequence.new(LAVENDER, MIST)
	e.LightEmission = 0.3
	e.Rate = 4
	e.Lifetime = NumberRange.new(1.2, 2)
	e.Speed = NumberRange.new(0.2, 0.8)
	e.SpreadAngle = Vector2.new(180, 10)
	e.Size = NumberSequence.new(1.2, 3)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.75), NumberSequenceKeypoint.new(1, 1) })
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
		local cf = head.CFrame * CFrame.new(0.2, 0.55 + math.sin(t * 1.4) * 0.12, 0.7) * CFrame.Angles(0, 0, math.rad(-25) + math.sin(t * 0.7) * 0.15)
		placeList(moon, cf)
		for _, it in ipairs(moon) do
			it.p.LocalTransparencyModifier = hide and 1 or 0
		end
		for k, s in ipairs(stars) do
			local a = t * 0.6 + k * 2.1
			s.CFrame = torso.CFrame * CFrame.new(math.cos(a) * 1.9, 1.2 + math.sin(t + k) * 0.5, math.sin(a) * 1.9)
			s.Transparency = 0.2 + 0.6 * (0.5 + 0.5 * math.sin(t * 3 + k * 2))
			s.LocalTransparencyModifier = hide and 1 or 0
		end
		foot.CFrame = CFrame.new(torso.Position - Vector3.new(0, 2.9, 0))
		e.Enabled = not hide
	end)
	return out
end

------------------------------------------------------------------------
-- 문 (꿈의 문): 문틀 + 문짝 (경첩 둘레로 열린다) + 문 안의 달빛
------------------------------------------------------------------------
type Door = { frame: { Part }, panel: Part, light: Part, cf: CFrame, w: number, h: number, open: number }
local function makeDoor(cf: CFrame, w: number, h: number): Door
	local frame: { Part } = {}
	for _, x in ipairs({ -1, 1 }) do
		local post = part(Vector3.new(0.35, h + 0.4, 0.4), DOORWOOD, Enum.Material.Wood, 0)
		post.CFrame = cf * CFrame.new(x * (w / 2 + 0.15), 0, 0)
		table.insert(frame, post)
	end
	local top = part(Vector3.new(w + 0.8, 0.4, 0.45), DOORWOOD, Enum.Material.Wood, 0)
	top.CFrame = cf * CFrame.new(0, h / 2 + 0.2, 0)
	table.insert(frame, top)
	local light = part(Vector3.new(w, h, 0.1), MOON, Enum.Material.Neon, 0.15)
	light.CFrame = cf
	local panel = part(Vector3.new(w, h, 0.18), LAVENDER, Enum.Material.SmoothPlastic, 0)
	panel.CFrame = cf * CFrame.new(0, 0, -0.08)
	return { frame = frame, panel = panel, light = light, cf = cf, w = w, h = h, open = 0 }
end
local function setDoor(d: Door, open: number)
	d.open = open
	-- 왼쪽 경첩을 축으로 바깥쪽 (-Z)으로 열린다
	local hinge = d.cf * CFrame.new(-d.w / 2, 0, -0.08)
	d.panel.CFrame = hinge * CFrame.Angles(0, open * math.rad(105), 0) * CFrame.new(d.w / 2, 0, 0)
end
local function killDoor(d: Door, time: number)
	for _, p in ipairs(d.frame) do
		fadeOut(p, time)
	end
	fadeOut(d.panel, time)
	fadeOut(d.light, time)
end
-- 문을 열었다 닫는다 (총 time 초), 열린 동안 별이 흘러나온다
local function doorBlink(d: Door, time: number, onShut: (() -> ())?)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / time, 0, 1)
		local o = u < 0.3 and (u / 0.3) or (u < 0.75 and 1 or (1 - (u - 0.75) / 0.25))
		setDoor(d, o)
		if o > 0.5 and math.random() < 0.4 then
			stardust(d.cf.Position + d.cf.LookVector * -0.5, 1, 0.8, 2)
		end
		if u >= 1 then
			conn:Disconnect()
			if onShut then
				onShut()
			end
		end
	end)
end

------------------------------------------------------------------------
-- 연타 장치 꿈의 문: 상대 등 뒤 허공에 문이 열려 빨아들였다가 쾅 닫히며 뱉어 낸다
------------------------------------------------------------------------
local function dreamDoorPulse(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local delay = data.delay or 0.6
	local cam = workspace.CurrentCamera
	local away = cam and flat(at - cam.CFrame.Position) or Vector3.new(0, 0, -1)
	local doorPos = at + away * 2.6 + Vector3.new(0, 1.2, 0)
	local d = makeDoor(CFrame.lookAt(doorPos, doorPos - away), 3.2, 5.2)
	-- 문 안으로 별이 빨려 든다
	for k = 1, 8 do
		task.delay(k * delay / 10, function()
			local from = at + Vector3.new(math.random() - 0.5, math.random() * 2 - 0.5, math.random() - 0.5) * 3
			local s = part(Vector3.new(0.3, 0.3, 0.3), k % 2 == 0 and MOON or LAVENDER, Enum.Material.Neon, 0, "ball")
			s.CFrame = CFrame.new(from)
			fadeOut(s, 0.3, { CFrame = CFrame.new(doorPos) })
		end)
	end
	doorBlink(d, delay, function()
		Fx.sound("block", 0.5, 1.4, doorPos)
		stardust(at, 12, 1.1, 5)
		zzz(at + Vector3.new(0, 2, 0), 1)
		Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), LAVENDER, 2, (data.radius or 6) * 2, 0.35)
		killDoor(d, 0.35)
	end)
end

------------------------------------------------------------------------
-- E 양 세기: 울타리를 넘어 적에게 뛰어드는 꿈양 (머리 위에 하나, 둘, 셋...)
------------------------------------------------------------------------
local COUNT = { "하나", "둘", "셋", "넷", "다섯", "여섯" }
type Sheep = { list: { { p: Part, off: CFrame } }, tag: Part }
local function makeSheep(s: number, label: string): Sheep
	local list = {}
	for k, off in ipairs({ Vector3.new(0, 0, 0), Vector3.new(0.5, 0.25, 0.4), Vector3.new(-0.5, 0.2, 0.4), Vector3.new(0.4, 0.2, -0.45), Vector3.new(-0.4, 0.3, -0.4), Vector3.new(0, 0.5, 0) }) do
		local b = part(Vector3.one * (k == 1 and 1.6 or 1.0) * s, WOOL, Enum.Material.SmoothPlastic, 0, "ball")
		table.insert(list, { p = b, off = CFrame.new(off * s) })
	end
	local head = part(Vector3.new(0.65, 0.6, 0.75) * s, Color3.fromRGB(70, 62, 78), Enum.Material.SmoothPlastic, 0, "ball")
	table.insert(list, { p = head, off = CFrame.new(0, 0.25 * s, -0.95 * s) })
	for _, x in ipairs({ -1, 1 }) do
		local ear = part(Vector3.new(0.35, 0.12, 0.2) * s, Color3.fromRGB(70, 62, 78), Enum.Material.SmoothPlastic, 0)
		table.insert(list, { p = ear, off = CFrame.new(x * 0.38 * s, 0.4 * s, -0.95 * s) })
	end
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			local leg = part(Vector3.new(0.18, 0.6, 0.18) * s, Color3.fromRGB(70, 62, 78), Enum.Material.SmoothPlastic, 0)
			table.insert(list, { p = leg, off = CFrame.new(x * 0.4 * s, -0.75 * s, z * 0.45 * s) })
		end
	end
	local tag = part(Vector3.new(0.2, 0.2, 0.2), WOOL, Enum.Material.Neon, 1)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(3, 1.4)
	bb.StudsOffset = Vector3.new(0, 1.6 * s, 0)
	bb.LightInfluence = 0
	bb.Parent = tag
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = label
	t.TextColor3 = MOON
	t.TextStrokeTransparency = 0.4
	t.TextStrokeColor3 = NIGHT
	t.Parent = bb
	return { list = list, tag = tag }
end
local function placeSheep(sh: Sheep, cf: CFrame)
	placeList(sh.list, cf)
	sh.tag.CFrame = cf
end
local function poofSheep(sh: Sheep, at: Vector3)
	for _, it in ipairs(sh.list) do
		fadeOut(it.p, 0.25, { Size = it.p.Size * 1.8 })
	end
	sh.tag:Destroy()
	mist(at, 0.6, 0.6)
	stardust(at, 8, 1, 3)
	zzz(at + Vector3.new(0, 1.5, 0), 0.9)
end
local function sheepCount(data: any)
	local m: Model? = data.m
	local r = rootOf(m)
	if not r or not near(r.Position, 220) then
		return
	end
	local n = data.n or 5
	local targets = data.targets or {}
	local look = flat(r.CFrame.LookVector)
	local side = Vector3.new(-look.Z, 0, look.X)
	local delay = data.delay or 0.15
	local every = data.every or 0.14
	local travel = data.travel or 0.55
	-- 허공의 울타리 (내 앞에 떠 있다)
	local fenceAt = r.Position + look * 3 + Vector3.new(0, 0.4, 0)
	local fence: { Part } = {}
	for _, x in ipairs({ -1.6, 1.6 }) do
		local post = part(Vector3.new(0.3, 2, 0.3), Color3.fromRGB(150, 116, 82), Enum.Material.Wood, 0)
		post.CFrame = CFrame.lookAt(fenceAt + side * x, fenceAt + side * x + look)
		table.insert(fence, post)
	end
	for _, y in ipairs({ -0.3, 0.5 }) do
		local rail = part(Vector3.new(3.6, 0.2, 0.15), Color3.fromRGB(176, 140, 100), Enum.Material.Wood, 0)
		rail.CFrame = CFrame.lookAt(fenceAt + Vector3.new(0, y, 0), fenceAt + Vector3.new(0, y, 0) + look)
		table.insert(fence, rail)
	end
	mist(fenceAt - Vector3.new(0, 1, 0), 0.6, 0.9)
	task.delay(delay + n * every + travel + 0.3, function()
		for _, p in ipairs(fence) do
			fadeOut(p, 0.3)
		end
	end)
	for i = 1, n do
		task.delay(delay + (i - 1) * every, function()
			local rr = rootOf(m) or r
			local start = rr.Position - look * 1.5 + Vector3.new(0, 0.5, 0)
			local tgt = #targets > 0 and targets[(i - 1) % #targets + 1] or nil
			local sh = makeSheep(0.9, COUNT[i] or tostring(i))
			Fx.sound("ping", 0.3, 1.2 + i * 0.12, start)
			local t0 = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function()
				local u = math.clamp((os.clock() - t0) / travel, 0, 1)
				local tr = rootOf(tgt)
				local goal = tr and tr.Position or (start + look * 18 + side * (i - 3) * 2)
				-- 울타리를 넘고 (첫 30%), 그다음 통통 튀며 날아간다
				local pos: Vector3
				if u < 0.3 then
					local v = u / 0.3
					pos = start:Lerp(fenceAt + look * 1.5, v) + Vector3.new(0, 3.2 * math.sin(v * math.pi), 0)
				else
					local v = (u - 0.3) / 0.7
					local base = (fenceAt + look * 1.5):Lerp(goal, v)
					pos = base + Vector3.new(0, math.abs(math.sin(v * math.pi * 2)) * 2.2, 0)
				end
				local dir = flat(goal - pos)
				placeSheep(sh, CFrame.lookAt(pos, pos + dir))
				if u >= 1 then
					conn:Disconnect()
					poofSheep(sh, pos)
				end
			end)
		end)
	end
end

------------------------------------------------------------------------
-- R 거꾸로 꿈: 앞의 땅이 밤하늘이 되고, 풀과 돌이 하늘로 떨어진다. 꿈이 바로 서면 쾅
------------------------------------------------------------------------
local function upsideDown(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local R = data.radius or 11
	local delay = data.delay or 0.25
	local hold = data.hold or 1.2
	local g = ground(at)
	local sky = part(Vector3.new(0.2, 1, 1), NIGHT, Enum.Material.SmoothPlastic, 0.1, "cyl")
	sky.CFrame = CFrame.new(g + Vector3.new(0, 0.12, 0)) * UP
	tween(sky, delay, { Size = Vector3.new(0.2, R * 2, R * 2) })
	local rim = part(Vector3.new(0.25, 1, 1), DUSK, Enum.Material.Neon, 0.4, "cyl")
	rim.CFrame = CFrame.new(g + Vector3.new(0, 0.1, 0)) * UP
	tween(rim, delay, { Size = Vector3.new(0.25, R * 2 + 1, R * 2 + 1) })
	-- 땅 아래 하늘의 별 (거꾸로 비친 밤하늘)
	local dots: { Part } = {}
	for k = 1, 18 do
		local a, rr = math.random() * math.pi * 2, math.sqrt(math.random()) * R * 0.9
		local d = part(Vector3.new(0.3, 0.3, 0.3), k % 4 == 0 and MOON or STAR, Enum.Material.Neon, 0.1, "ball")
		d.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * rr, 0.25, math.sin(a) * rr))
		table.insert(dots, d)
	end
	-- 풀과 작은 돌이 하늘로 떨어진다 (거꾸로)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > delay and t < delay + hold and math.random() < 0.6 then
			local a, rr = math.random() * math.pi * 2, math.sqrt(math.random()) * R
			local p = g + Vector3.new(math.cos(a) * rr, 0.4, math.sin(a) * rr)
			local bit = part(Vector3.new(0.4, 0.4, 0.4) * (0.6 + math.random()), math.random() < 0.5 and Color3.fromRGB(110, 140, 90) or Color3.fromRGB(120, 112, 104), Enum.Material.SmoothPlastic, 0)
			bit.CFrame = CFrame.new(p) * CFrame.Angles(math.random() * 3, math.random() * 3, 0)
			fadeOut(bit, 1.1, { CFrame = CFrame.new(p + Vector3.new(0, 10 + math.random() * 6, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0) })
		end
		if t >= delay + hold then
			conn:Disconnect()
		end
	end)
	Fx.sound("ping", 0.4, 0.7, at)
	task.delay(delay + hold, function()
		for _, d in ipairs(dots) do
			fadeOut(d, 0.2)
		end
		fadeOut(sky, 0.4)
		fadeOut(rim, 0.4)
		Fx.ring(g + Vector3.new(0, 0.4, 0), LAVENDER, 2, R * 2.6, 0.45)
		Fx.ring(g + Vector3.new(0, 0.6, 0), MOON, 2, R * 1.8, 0.35)
		Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(150, 140, 170), 14, 1.4)
		stardust(g + Vector3.new(0, 1, 0), 14, 1.4, 3)
		Fx.sound("heavy", 0.8, 1.0, g)
		shakeNear(g, 1.6, 100)
	end)
end

------------------------------------------------------------------------
-- G 몽중몽: 커다란 달, 떠다니는 작은 섬과 끝없는 계단과 문. 문이 여기저기서 열렸다 닫힌다. 끝에 모두 떨어지며 깬다
------------------------------------------------------------------------
local function island(at: Vector3, s: number): { Part }
	local list: { Part } = {}
	local rock = part(Vector3.new(4 * s, 3 * s, 4 * s), Color3.fromRGB(110, 100, 120), Enum.Material.Slate, 0, "ball")
	rock.CFrame = CFrame.new(at - Vector3.new(0, 1.2 * s, 0))
	table.insert(list, rock)
	local tip = part(Vector3.new(2 * s, 2.6 * s, 2 * s), Color3.fromRGB(96, 88, 108), Enum.Material.Slate, 0, "ball")
	tip.CFrame = CFrame.new(at - Vector3.new(0, 2.8 * s, 0))
	table.insert(list, tip)
	local grass = part(Vector3.new(0.4 * s, 4.2 * s, 4.2 * s), Color3.fromRGB(120, 170, 130), Enum.Material.Grass, 0, "cyl")
	grass.CFrame = CFrame.new(at) * UP
	table.insert(list, grass)
	local trunk = part(Vector3.new(0.3, 1.6, 0.3) * s, Color3.fromRGB(90, 70, 60), Enum.Material.Wood, 0)
	trunk.CFrame = CFrame.new(at + Vector3.new(0.6 * s, 0.9 * s, 0))
	table.insert(list, trunk)
	local leaf = part(Vector3.new(1.6, 1.4, 1.6) * s, Color3.fromRGB(200, 170, 240), Enum.Material.SmoothPlastic, 0, "ball")
	leaf.CFrame = CFrame.new(at + Vector3.new(0.6 * s, 2 * s, 0))
	table.insert(list, leaf)
	return list
end
local function dreamIsles(data: any)
	local at: Vector3 = data.at
	if not near(at, 260) then
		return
	end
	local R = data.radius or 26
	local delay = data.delay or 0.4
	local dur = data.dur or 3.0
	local g = ground(at)
	local cc: ColorCorrectionEffect? = nil
	if near(at, R * 2.5) then
		local c = Instance.new("ColorCorrectionEffect")
		c.Name = "KwonDreamGrade"
		c.Parent = Lighting
		tween(c, 0.5, { TintColor = Color3.fromRGB(200, 196, 255), Brightness = -0.06, Saturation = 0.1 })
		cc = c
	end
	local things: { { list: { Part }, base: Vector3, bob: number } } = {}
	-- 큰 달 (머리 위, 한쪽으로)
	local moonC = g + Vector3.new(R * 0.4, 34, -R * 0.3)
	local moon = part(Vector3.new(1, 1, 1), MOON, Enum.Material.Neon, 0.05, "ball")
	moon.CFrame = CFrame.new(moonC)
	tween(moon, 0.6, { Size = Vector3.new(16, 16, 16) }, Enum.EasingStyle.Back)
	local halo = part(Vector3.new(1, 1, 1), MOON, Enum.Material.Neon, 0.85, "ball")
	halo.CFrame = CFrame.new(moonC)
	tween(halo, 0.8, { Size = Vector3.new(30, 30, 30) })
	-- 떠다니는 섬 여섯
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2 + 0.3
		local base = g + Vector3.new(math.cos(a) * R * 0.75, 8 + (k % 3) * 4, math.sin(a) * R * 0.75)
		table.insert(things, { list = island(base, 0.9 + (k % 2) * 0.4), base = base, bob = k })
	end
	-- 끝없는 계단 셋 (빙글 돌며 올라가다 허공에서 끊긴다)
	for k = 1, 3 do
		local a0 = k / 3 * math.pi * 2
		local c = g + Vector3.new(math.cos(a0) * R * 0.45, 0, math.sin(a0) * R * 0.45)
		local list: { Part } = {}
		for j = 0, 13 do
			local a = a0 + j * 0.42
			local st = part(Vector3.new(3, 0.5, 1.4), j % 2 == 0 and LAVENDER or Color3.fromRGB(230, 222, 250), Enum.Material.SmoothPlastic, 0.05)
			st.CFrame = CFrame.new(c + Vector3.new(math.cos(a) * 3, 1 + j * 1.1, math.sin(a) * 3)) * CFrame.Angles(0, -a, 0)
			st.Transparency = 1
			task.delay(delay + j * 0.04, function()
				tween(st, 0.2, { Transparency = 0.05 })
			end)
			table.insert(list, st)
		end
		table.insert(things, { list = list, base = c, bob = 10 + k })
	end
	-- 문 다섯 (떠다니며 가끔 열렸다 닫힌다)
	local doors: { Door } = {}
	for k = 1, 5 do
		local a = k / 5 * math.pi * 2 + 1
		local p = g + Vector3.new(math.cos(a) * R * 0.55, 4 + (k % 2) * 3, math.sin(a) * R * 0.55)
		doors[k] = makeDoor(CFrame.lookAt(p, Vector3.new(g.X, p.Y, g.Z)), 3, 5)
	end
	local t0 = os.clock()
	local nextDoor = delay
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		for _, th in ipairs(things) do
			local off = Vector3.new(0, math.sin(t * 1.2 + th.bob) * 0.6, 0)
			for _, p in ipairs(th.list) do
				if p.Parent then
					p.CFrame = p.CFrame + off * 0.03
				end
			end
		end
		if t >= nextDoor and t < delay + dur then
			nextDoor = t + 0.35
			local d = doors[math.random(1, #doors)]
			doorBlink(d, 0.5)
			Fx.sound("block", 0.25, 1.6, d.cf.Position)
		end
		if math.random() < 0.3 then
			local a, rr = math.random() * math.pi * 2, math.random() * R
			stardust(g + Vector3.new(math.cos(a) * rr, 1, math.sin(a) * rr), 1, 1, 6)
		end
		if t >= delay + dur then
			conn:Disconnect()
		end
	end)
	mist(g, 2.4, dur + delay)
	Fx.sound("ping", 0.6, 0.6, at)
	-- 깬다: 모든 것이 아래로 떨어지고 하얀 빛
	task.delay(delay + dur, function()
		local all: { Part } = { moon, halo }
		for _, th in ipairs(things) do
			for _, p in ipairs(th.list) do
				table.insert(all, p)
			end
		end
		for _, d in ipairs(doors) do
			for _, p in ipairs(d.frame) do
				table.insert(all, p)
			end
			table.insert(all, d.panel)
			table.insert(all, d.light)
		end
		for _, p in ipairs(all) do
			if p.Parent then
				fadeOut(p, 0.6, { CFrame = p.CFrame - Vector3.new(0, 18, 0) })
			end
		end
		local core = part(Vector3.new(4, 4, 4), STAR, Enum.Material.Neon, 0, "ball")
		core.CFrame = CFrame.new(g + Vector3.new(0, 4, 0))
		fadeOut(core, 0.6, { Size = Vector3.new(R * 1.8, R * 1.8, R * 1.8) })
		for k = 1, 3 do
			task.delay(k * 0.06, function()
				Fx.ring(g + Vector3.new(0, 0.5 + k, 0), k == 2 and MOON or LAVENDER, 4, R * 2.4 + k * 6, 0.6)
			end)
		end
		stardust(g + Vector3.new(0, 4, 0), 30, 2.2, 6)
		Fx.flash(g + Vector3.new(0, 4, 0), MOON, 90, 6, 0.5)
		Fx.sound("splash", 0.6, 1.4, g)
		Fx.sound("heavy", 0.8, 0.8, g)
		shakeNear(g, 2.2, 150)
		if cc then
			tween(cc, 0.6, { TintColor = Color3.new(1, 1, 1), Brightness = 0, Saturation = 0 })
			task.delay(0.7, function()
				cc:Destroy()
			end)
		end
	end)
end

------------------------------------------------------------------------
-- X 월하몽: 보름달이 떠오르고 땅이 밤 호수가 된다. 등불과 문이 떠오르고 별이 소용돌이친다. 달이 내려와 호수에 닿으면 소리 없이 하얗게
------------------------------------------------------------------------
local function moonDream(data: any)
	local at: Vector3 = data.at
	if not near(at, 340) then
		return
	end
	local dir = flat(data.dir or Vector3.new(0, 0, -1))
	local cut = data.cut or 1.4
	local rise = data.rise or 0.5
	local drift = data.drift or 2.0
	local descend = data.descend or 0.8
	local range = data.range or 40
	local g = ground(at)
	local cc: ColorCorrectionEffect? = nil
	if near(at, range * 2.5) then
		local c = Instance.new("ColorCorrectionEffect")
		c.Name = "KwonMoonGrade"
		c.Parent = Lighting
		tween(c, 0.8, { TintColor = Color3.fromRGB(170, 176, 255), Brightness = -0.12, Contrast = 0.1 })
		cc = c
	end
	local parts: { Part } = {}
	-- 하늘을 채우는 보름달 (등 뒤에서 떠오른다)
	local moonFrom = g - dir * 60 + Vector3.new(0, -20, 0)
	local moonAt = g - dir * 50 + Vector3.new(0, 55, 0)
	local moon = part(Vector3.new(56, 56, 56), MOON, Enum.Material.Neon, 0.02, "ball")
	moon.CFrame = CFrame.new(moonFrom)
	local glow = part(Vector3.new(90, 90, 90), MOON, Enum.Material.Neon, 0.9, "ball")
	glow.CFrame = CFrame.new(moonFrom)
	tween(moon, cut, { CFrame = CFrame.new(moonAt) }, Enum.EasingStyle.Sine)
	tween(glow, cut, { CFrame = CFrame.new(moonAt) }, Enum.EasingStyle.Sine)
	table.insert(parts, moon)
	table.insert(parts, glow)
	-- 밤 호수 (달이 비친다)
	local lake = part(Vector3.new(0.3, 1, 1), NIGHT, Enum.Material.Glass, 0.05, "cyl")
	lake.Reflectance = 0.5
	lake.CFrame = CFrame.new(g + Vector3.new(0, 0.15, 0)) * UP
	table.insert(parts, lake)
	local reflect = part(Vector3.new(0.32, 1, 1), MOON, Enum.Material.Neon, 0.5, "cyl")
	reflect.CFrame = CFrame.new(g - dir * range * 0.45 + Vector3.new(0, 0.2, 0)) * UP
	table.insert(parts, reflect)
	task.delay(cut, function()
		tween(lake, rise, { Size = Vector3.new(0.3, range * 2, range * 2) })
		tween(reflect, rise, { Size = Vector3.new(0.32, range * 0.5, range * 0.5) })
		Fx.ring(g + Vector3.new(0, 0.4, 0), LAVENDER, 4, range * 2.2, 0.8)
		Fx.sound("splash", 0.5, 0.7, g)
		-- 호수에 박힌 별, 떠오르는 등불, 떠다니는 문
		for k = 1, 30 do
			local a, rr = math.random() * math.pi * 2, math.sqrt(math.random()) * range * 0.95
			local s = part(Vector3.new(0.4, 0.4, 0.4), k % 5 == 0 and MOON or STAR, Enum.Material.Neon, 0.1, "ball")
			s.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * rr, 0.35, math.sin(a) * rr))
			table.insert(parts, s)
		end
		for k = 1, 10 do
			local a = k / 10 * math.pi * 2
			local p0 = g + Vector3.new(math.cos(a) * range * 0.7, 0.5, math.sin(a) * range * 0.7)
			local lantern = part(Vector3.new(1.2, 1.6, 1.2), Color3.fromRGB(255, 196, 130), Enum.Material.Neon, 0.1)
			lantern.CFrame = CFrame.new(p0)
			tween(lantern, rise + drift + descend, { CFrame = CFrame.new(p0 + Vector3.new(0, 14 + (k % 3) * 4, 0)) }, Enum.EasingStyle.Sine)
			table.insert(parts, lantern)
		end
		for k = 1, 4 do
			local a = k / 4 * math.pi * 2 + 0.4
			local p = g + Vector3.new(math.cos(a) * range * 0.45, 6, math.sin(a) * range * 0.45)
			local d = makeDoor(CFrame.lookAt(p, Vector3.new(g.X, p.Y, g.Z)), 3.4, 5.6)
			task.delay(rise + k * 0.4, function()
				doorBlink(d, 0.8)
			end)
			task.delay(rise + drift + descend, function()
				killDoor(d, 0.5)
			end)
		end
	end)
	-- 별의 소용돌이 (가운데를 감싸며 천천히 오른다)
	local spin: { Part } = {}
	for k = 1, 28 do
		local s = part(Vector3.new(0.5, 0.5, 0.5), k % 3 == 0 and MOON or (k % 3 == 1 and STAR or LAVENDER), Enum.Material.Neon, 1, "ball")
		table.insert(spin, s)
		table.insert(parts, s)
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp((t - cut - rise) / drift, 0, 1)
		if t > cut + rise and t < cut + rise + drift + descend then
			for k, s in ipairs(spin) do
				local a = t * 0.9 + k / #spin * math.pi * 2
				local rr = range * (0.25 + (k % 4) * 0.15) * (1 - u * 0.3)
				s.Transparency = 0.1
				s.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * rr, 3 + (k % 5) * 2 + u * 4, math.sin(a) * rr))
			end
			if math.random() < 0.25 then
				local a, rr = math.random() * math.pi * 2, math.random() * range
				zzz(g + Vector3.new(math.cos(a) * rr, 4 + math.random() * 4, math.sin(a) * rr), 1.2)
			end
		end
		if t >= cut + rise + drift + descend then
			conn:Disconnect()
		end
	end)
	-- 달이 내려와 호수에 닿는다
	task.delay(cut + rise + drift, function()
		tween(moon, descend, { CFrame = CFrame.new(g + Vector3.new(0, 20, 0)), Size = Vector3.new(40, 40, 40) }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		tween(glow, descend, { CFrame = CFrame.new(g + Vector3.new(0, 20, 0)) }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end)
	task.delay(cut + rise + drift + descend, function()
		-- 소리 없이 하얗게 번진다
		local bloom = part(Vector3.new(10, 10, 10), STAR, Enum.Material.Neon, 0, "ball")
		bloom.CFrame = CFrame.new(g + Vector3.new(0, 6, 0))
		fadeOut(bloom, 1.0, { Size = Vector3.new(range * 2.4, range * 2.4, range * 2.4) })
		for k = 1, 4 do
			task.delay(k * 0.1, function()
				Fx.ring(g + Vector3.new(0, 0.4, 0), k % 2 == 0 and MOON or LAVENDER, 6, range * 2.4 + k * 8, 0.9)
			end)
		end
		stardust(g + Vector3.new(0, 6, 0), 40, 2.4, 8)
		Fx.flash(g + Vector3.new(0, 6, 0), STAR, 160, 9, 0.9)
		Fx.sound("splash", 0.7, 0.6, g)
		shakeNear(g, 2.0, 220)
		if opts.flash and near(g, 120) then
			opts.flash(STAR, 0.35)
		end
		for _, p in ipairs(parts) do
			if p.Parent then
				fadeOut(p, 0.8, { CFrame = p.CFrame - Vector3.new(0, 4, 0) })
			end
		end
		if cc then
			tween(cc, 0.9, { TintColor = Color3.new(1, 1, 1), Brightness = 0, Contrast = 0 })
			task.delay(1, function()
				cc:Destroy()
			end)
		end
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	sheepCount = sheepCount,
	upsideDown = upsideDown,
	dreamIsles = dreamIsles,
	moonDream = moonDream,
}
function Dream.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil or (data.kind == "pulse" and data.fx == "dreamDoor")
end
function Dream.run(data: any)
	if data.kind == "pulse" then
		dreamDoorPulse(data)
		return
	end
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

return Dream
