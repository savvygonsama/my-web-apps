-- 권왕 1.9판: 새 각성 권법 셋의 화면 (진 금강불괴신공 · 진 무영귀각 · 진 태허유수장)
-- 고유 장치(불괴진동 · 영각 · 역류)와 오의(만불조종 · 백귀야행 · 천하수류)를 그린다
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Awake = {}
local player = Players.LocalPlayer

local GOLD = Color3.fromRGB(255, 190, 60)
local GOLD_PALE = Color3.fromRGB(255, 245, 200)
local SHADOW = Color3.fromRGB(40, 18, 70)
local VIOLET = Color3.fromRGB(150, 90, 255)
local WATER = Color3.fromRGB(70, 200, 255)
local FOAM = Color3.fromRGB(225, 252, 255)

local folder = Instance.new("Folder")
folder.Name = "KwonAwake"
folder.Parent = workspace

local opts: any = {}
function Awake.init(o: any)
	opts = o or {}
end
local function shakeNear(pos: Vector3, amount: number, range: number)
	local cam = workspace.CurrentCamera
	if opts.shake and cam and (cam.CFrame.Position - pos).Magnitude < range then
		opts.shake(amount)
	end
end

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function rootOf(m: Instance?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
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
-- 바닥 원반 (납작한 원기둥)
local function disc(at: Vector3, d: number, color: Color3, alpha: number): Part
	local p = part(Vector3.new(0.2, d, d), color, Enum.Material.Neon, alpha, "cyl")
	p.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	return p
end
local function ground(at: Vector3): Vector3
	return Vector3.new(at.X, at.Y - 2.7, at.Z)
end
-- 모델의 그림자 허상 (모든 몸 조각을 한 빛깔로 베낀다)
local function ghostOf(model: Model, at: CFrame, color: Color3, alpha: number): { BasePart }
	local r = rootOf(model)
	local out = {}
	if not r then
		return out
	end
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.9 then
			local g = part(d.Size, color, Enum.Material.Neon, alpha)
			g.CFrame = at * r.CFrame:ToObjectSpace(d.CFrame)
			table.insert(out, g)
		end
	end
	return out
end

------------------------------------------------------------------------
-- 진 금강불괴: 불괴진동 (여덟 번 맞으면 몸에서 금빛 진동이 터진다)
------------------------------------------------------------------------
local function vajraQuake(data: any)
	local at: Vector3 = data.at
	local r = data.radius or 16
	local g = ground(at)
	-- 몸을 감싼 금빛 종이 한순간 부풀었다가 깨진다
	local bell = part(Vector3.new(6, 6, 6), GOLD, Enum.Material.ForceField, 0.1, "ball")
	bell.CFrame = CFrame.new(at)
	tween(bell, 0.18, { Size = Vector3.new(r * 1.2, r * 1.2, r * 1.2) }, Enum.EasingStyle.Back)
	task.delay(0.18, function()
		fadeOut(bell, 0.4, { Size = Vector3.new(r * 2, r * 2, r * 2) })
	end)
	for i = 0, 2 do
		task.delay(i * 0.09, function()
			Fx.ring(g + Vector3.new(0, 0.2, 0), i == 1 and GOLD_PALE or GOLD, 3, r * 2.1 + i * 4, 0.55)
		end)
	end
	-- 땅이 금빛으로 갈라진다
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2 + math.random() * 0.3
		local len = r * (0.7 + math.random() * 0.4)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local c = part(Vector3.new(0.5, 0.15, len), GOLD, Enum.Material.Neon, 0)
		c.CFrame = CFrame.lookAt(g + dir * len / 2 + Vector3.new(0, 0.15, 0), g + dir * len + Vector3.new(0, 0.15, 0))
		task.delay(0.25, function()
			fadeOut(c, 0.7)
		end)
	end
	Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(200, 175, 130), 24, 1.6)
	Fx.burst("spark", at, GOLD, 30, 1.6)
	Fx.debris(g, 6, 22, Color3.fromRGB(150, 130, 100))
	Fx.flash(at, GOLD, 40, 4, 0.5)
	Fx.sound("heavy", 1, 0.6, at)
	Fx.sound("block", 0.7, 0.5, at)
	shakeNear(at, 0.9, 50)
end

------------------------------------------------------------------------
-- 만불조종: 하늘이 갈라지고, 산만 한 금빛 손바닥이 내려와 둘레를 누른다
------------------------------------------------------------------------
local function buildPalm(size: number): Model
	local m = Instance.new("Model")
	m.Name = "BuddhaPalm"
	local skin = GOLD
	local function add(sz: Vector3, cf: CFrame, col: Color3?, mat: Enum.Material?)
		local p = part(sz, col or skin, mat or Enum.Material.Foil, 0)
		p.CFrame = cf
		p.Parent = m
		return p
	end
	local w, l, t = size, size * 1.05, size * 0.22
	-- 손바닥이 아래를 본다 (손끝은 -Z 쪽)
	local palm = add(Vector3.new(w, t, l), CFrame.new())
	m.PrimaryPart = palm
	-- 손바닥 가운데의 빛나는 문양 (만(卍) 대신 둥근 법륜)
	local wheel = add(Vector3.new(0.3, w * 0.55, w * 0.55), CFrame.new(0, -t / 2 - 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), GOLD_PALE, Enum.Material.Neon)
	wheel.Shape = Enum.PartType.Cylinder
	local fw = w / 4.6
	for i = 1, 4 do
		local x = -w / 2 + fw * 0.7 + (i - 1) * (w - fw * 1.4) / 3
		local fl = l * ({ 0.5, 0.66, 0.62, 0.5 })[i]
		add(Vector3.new(fw, t * 0.9, fl), CFrame.new(x, 0, -l / 2 - fl / 2 + fw * 0.3))
		-- 마디의 금빛 띠
		add(Vector3.new(fw * 1.04, t * 0.95, fw * 0.25), CFrame.new(x, 0, -l / 2 - fl * 0.45), GOLD_PALE, Enum.Material.Neon)
	end
	-- 엄지
	local th = add(Vector3.new(fw * 1.1, t * 0.9, l * 0.5), CFrame.new(w / 2 + fw * 0.2, 0, -l * 0.05) * CFrame.Angles(0, math.rad(-35), 0))
	th.Name = "Thumb"
	-- 손목과 소매 (위로 뻗는다)
	add(Vector3.new(w * 0.8, size * 1.6, l * 0.55), CFrame.new(0, size * 0.85, l * 0.45))
	add(Vector3.new(w * 1.05, size * 0.5, l * 0.75), CFrame.new(0, size * 1.6, l * 0.45), Color3.fromRGB(200, 70, 40), Enum.Material.Fabric)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Parent = m
		end
	end
	m.Parent = folder
	return m
end
local function buddhaPalm(data: any)
	local at: Vector3 = data.at
	local r = data.radius or 26
	local delay = data.delay or 1
	local g = ground(at)
	-- 하늘의 틈: 금빛 빛기둥이 둘레를 비추고, 바닥에 큰 원이 그려진다
	local mark = disc(g + Vector3.new(0, 0.1, 0), r * 2, GOLD, 0.75)
	tween(mark, delay, { Transparency = 0.45 })
	local beam = part(Vector3.new(300, r * 1.6, r * 1.6), GOLD_PALE, Enum.Material.Neon, 0.92, "cyl")
	beam.CFrame = CFrame.new(g + Vector3.new(0, 150, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(beam, delay, { Transparency = 0.7 })
	local hand = buildPalm(r * 0.95)
	local yaw = math.random() * math.pi * 2
	local fromCF = CFrame.new(g + Vector3.new(0, 170, 0)) * CFrame.Angles(0, yaw, 0)
	local toCF = CFrame.new(g + Vector3.new(0, r * 0.12, 0)) * CFrame.Angles(0, yaw, 0)
	hand:PivotTo(fromCF)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - t0) / delay, 0, 1)
		local e = k * k * k
		if hand.Parent then
			hand:PivotTo(fromCF:Lerp(toCF, e))
		end
		if k >= 1 then
			conn:Disconnect()
		end
	end)
	Fx.sound("deflect", 1, 0.35, at)
	task.delay(delay, function()
		if conn.Connected then
			conn:Disconnect()
		end
		hand:PivotTo(toCF)
		-- 땅이 눌린다
		for i = 0, 3 do
			task.delay(i * 0.07, function()
				Fx.ring(g + Vector3.new(0, 0.3, 0), i % 2 == 0 and GOLD or GOLD_PALE, r * 0.6, r * 2.4 + i * 10, 0.9)
			end)
		end
		local crater = disc(g + Vector3.new(0, 0.12, 0), r * 2.2, Color3.fromRGB(110, 80, 40), 0.2)
		crater.Material = Enum.Material.Slate
		task.delay(2.2, function()
			fadeOut(crater, 1.2)
		end)
		Fx.burst("dust", g + Vector3.new(0, 1, 0), Color3.fromRGB(205, 180, 135), 40, 3)
		Fx.burst("glitter", g + Vector3.new(0, 4, 0), GOLD, 50, 2.5)
		Fx.debris(g, 12, 40, Color3.fromRGB(140, 120, 90))
		Fx.flash(g + Vector3.new(0, 6, 0), GOLD, 60, 7, 1)
		Fx.sound("heavy", 1, 0.4, at)
		Fx.sound("fall", 0.8, 0.5, at)
		shakeNear(at, 2.4, 90)
		if opts.tint then
			local cam = workspace.CurrentCamera
			if cam and (cam.CFrame.Position - at).Magnitude < 90 then
				opts.tint(GOLD, 0.3, 0.35)
			end
		end
		-- 손바닥은 금빛 가루가 되어 흩어진다
		task.delay(0.9, function()
			for _, p in ipairs(hand:GetChildren()) do
				if p:IsA("BasePart") then
					fadeOut(p, 0.8, { Size = p.Size * 1.08 })
				end
			end
			Fx.burst("glitter", g + Vector3.new(0, r * 0.4, 0), GOLD_PALE, 40, 3)
			task.delay(0.9, function()
				hand:Destroy()
			end)
			fadeOut(beam, 0.6)
			fadeOut(mark, 0.6)
		end)
		-- 땅이 몇 번 더 울린다
		for q = 1, data.quakes or 3 do
			task.delay(q * (data.every or 0.35), function()
				Fx.ring(g + Vector3.new(0, 0.3, 0), GOLD, r * 0.4, r * (2 + q * 0.3), 0.6)
				Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(200, 175, 130), 14, 2)
				shakeNear(at, 0.8, 70)
			end)
		end
	end)
end

------------------------------------------------------------------------
-- 진 무영귀각: 영각 (그림자가 한 박자 뒤 같은 자리를 한 번 더 찬다)
------------------------------------------------------------------------
local function shadowEcho(data: any)
	local a: Model? = data.a
	local t: Model? = data.t
	local ar, tr = rootOf(a), rootOf(t)
	if not a or not ar or not tr then
		return
	end
	-- 상대 옆으로 비껴선 그림자 허상이 같은 발차기를 한다
	local side = (math.random() < 0.5 and -1 or 1)
	local toT = Vector3.new(tr.Position.X - ar.Position.X, 0, tr.Position.Z - ar.Position.Z)
	local dir = toT.Magnitude > 0.1 and toT.Unit or Vector3.new(0, 0, -1)
	local right = dir:Cross(Vector3.new(0, 1, 0))
	local at = tr.Position - dir * 3.2 + right * side * 2.4
	local cf = CFrame.lookAt(at, Vector3.new(tr.Position.X, at.Y, tr.Position.Z))
	local ghost = ghostOf(a :: Model, cf, SHADOW, 0.35)
	for _, g in ipairs(ghost) do
		tween(g, 0.12, { CFrame = g.CFrame + dir * 1.6 })
		task.delay(0.1, function()
			fadeOut(g, 0.3)
		end)
	end
	-- 맞은 자리에 보랏빛 발자국 같은 충격
	local hit = part(Vector3.new(1, 1, 1), VIOLET, Enum.Material.Neon, 0.2, "ball")
	hit.CFrame = CFrame.new(tr.Position)
	fadeOut(hit, 0.25, { Size = Vector3.new(6, 6, 6) })
	Fx.burst("smoke", tr.Position, SHADOW, 6, 0.8)
	Fx.burst("spark", tr.Position, VIOLET, 8, 0.9)
	Fx.sound("hit", 0.5, 0.7, tr.Position)
end

------------------------------------------------------------------------
-- 백귀야행: 그림자 여덟이 둘레의 땅에서 솟아 적들 사이를 엇갈려 가로지른다
------------------------------------------------------------------------
local function paradeStart(data: any)
	local at: Vector3 = data.at
	local r = data.radius or 24
	local dur = data.dur or 2.5
	local g = ground(at)
	-- 땅이 밤처럼 검게 물든다
	local dark = disc(g + Vector3.new(0, 0.08, 0), 2, SHADOW, 0.25)
	tween(dark, 0.4, { Size = Vector3.new(0.2, r * 2.3, r * 2.3) })
	task.delay(dur, function()
		fadeOut(dark, 0.6)
	end)
	local rim = disc(g + Vector3.new(0, 0.1, 0), r * 2.3, VIOLET, 0.6)
	rim.Size = Vector3.new(0.18, r * 2.3, r * 2.3)
	task.delay(dur, function()
		fadeOut(rim, 0.5)
	end)
	-- 검은 안개
	local fog = part(Vector3.new(r * 2, 6, r * 2), SHADOW, Enum.Material.SmoothPlastic, 1)
	fog.CFrame = CFrame.new(g + Vector3.new(0, 3, 0))
	local at0 = Instance.new("Attachment")
	at0.Parent = fog
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(SHADOW, Color3.fromRGB(80, 40, 120))
	pe.LightEmission = 0
	pe.Rate = 40
	pe.Lifetime = NumberRange.new(1, 1.8)
	pe.Speed = NumberRange.new(1, 3)
	pe.Size = NumberSequence.new(4, 9)
	pe.Transparency = NumberSequence.new(0.5, 1)
	pe.Shape = Enum.ParticleEmitterShape.Box
	pe.Parent = fog
	task.delay(dur, function()
		pe.Enabled = false
		task.delay(2, function()
			fog:Destroy()
		end)
	end)
	-- 둘레에 그림자 여덟이 솟는다 (쓴 사람의 모습을 베낀다)
	local m: Model? = data.m
	local n = data.ghosts or 8
	if m and rootOf(m) then
		for i = 1, n do
			local a = i / n * math.pi * 2
			local p = g + Vector3.new(math.cos(a), 0, math.sin(a)) * r * 0.9 + Vector3.new(0, 2.7, 0)
			local cf = CFrame.lookAt(p - Vector3.new(0, 5, 0), Vector3.new(at.X, p.Y - 5, at.Z))
			local ghost = ghostOf(m, cf, SHADOW, 0.3)
			for _, gp in ipairs(ghost) do
				tween(gp, 0.35, { CFrame = gp.CFrame + Vector3.new(0, 5, 0) }, Enum.EasingStyle.Back)
				task.delay(0.6 + i * 0.03, function()
					fadeOut(gp, 0.35)
				end)
			end
		end
	end
	Fx.sound("deflect", 0.8, 0.5, at)
	if opts.tint then
		local cam = workspace.CurrentCamera
		if cam and (cam.CFrame.Position - at).Magnitude < 80 then
			opts.tint(Color3.fromRGB(60, 20, 110), 0.35, dur)
		end
	end
end
-- 한 번 가로지르기: 검은 그림자가 꼬리를 끌며 줄을 긋는다
local function paradePass(data: any)
	local from: Vector3, to: Vector3 = data.from, data.to
	local dur = data.dur or 0.25
	local body = part(Vector3.new(1.6, 4.6, 1.2), SHADOW, Enum.Material.Neon, 0.2)
	local head = part(Vector3.new(1.3, 1.3, 1.3), SHADOW, Enum.Material.Neon, 0.2, "ball")
	local look = CFrame.lookAt(from, to)
	body.CFrame = look
	head.CFrame = look * CFrame.new(0, 3, 0)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 2, 0)
	a0.Parent = body
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -2, 0)
	a1.Parent = body
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Color = ColorSequence.new(VIOLET, SHADOW)
	tr.Transparency = NumberSequence.new(0.1, 1)
	tr.Lifetime = 0.35
	tr.LightEmission = 0.6
	tr.Parent = body
	local endCF = CFrame.lookAt(to, to + (to - from))
	tween(body, dur, { CFrame = endCF }, Enum.EasingStyle.Linear)
	tween(head, dur, { CFrame = endCF * CFrame.new(0, 3, 0) }, Enum.EasingStyle.Linear)
	task.delay(dur, function()
		fadeOut(body, 0.25)
		fadeOut(head, 0.25)
	end)
	-- 가운데쯤에서 발차기 초승달
	task.delay(dur * 0.5, function()
		local mid = from:Lerp(to, 0.5)
		local slash = part(Vector3.new(0.3, 0.3, 9), VIOLET, Enum.Material.Neon, 0)
		slash.CFrame = CFrame.lookAt(mid, mid + (to - from)) * CFrame.Angles(0, 0, math.rad(math.random(-60, 60)))
		fadeOut(slash, 0.3, { Size = Vector3.new(0.1, 0.1, 13) })
		Fx.burst("spark", mid, VIOLET, 6, 0.8)
		if (data.i or 1) % 3 == 0 then
			Fx.sound("swing", 0.6, 1.2, mid)
		end
	end)
end
local function paradeEnd(data: any)
	local at: Vector3 = data.at
	local r = data.radius or 18
	local g = ground(at)
	-- 그림자들이 모여 하늘로 걷어찬다: 보랏빛 기둥과 고리
	local pillar = part(Vector3.new(80, r * 0.6, r * 0.6), VIOLET, Enum.Material.Neon, 0.1, "cyl")
	pillar.CFrame = CFrame.new(g + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90))
	fadeOut(pillar, 0.8, { Size = Vector3.new(120, r * 1.4, r * 1.4) })
	local core = part(Vector3.new(80, r * 0.25, r * 0.25), Color3.new(1, 1, 1), Enum.Material.Neon, 0, "cyl")
	core.CFrame = pillar.CFrame
	fadeOut(core, 0.5)
	for i = 0, 2 do
		task.delay(i * 0.08, function()
			Fx.ring(g + Vector3.new(0, 0.3, 0), i == 1 and Color3.new(1, 1, 1) or VIOLET, 3, r * 2.4 + i * 6, 0.7)
		end)
	end
	Fx.burst("smoke", g + Vector3.new(0, 2, 0), SHADOW, 30, 2.5)
	Fx.burst("spark", at, VIOLET, 40, 2)
	Fx.flash(at, VIOLET, 50, 5, 0.7)
	Fx.sound("heavy", 1, 0.7, at)
	shakeNear(at, 1.8, 80)
end

------------------------------------------------------------------------
-- 진 태허유수장: 역류 (흘려 낼 때마다 둘레로 물결이 터진다)
------------------------------------------------------------------------
local function flowWave(data: any)
	local at: Vector3 = data.at
	local r = data.radius or 14
	local g = ground(at)
	for i = 0, 2 do
		task.delay(i * 0.07, function()
			Fx.ring(g + Vector3.new(0, 0.4 + i * 0.4, 0), i == 1 and FOAM or WATER, 2, r * 2 + i * 3, 0.5)
		end)
	end
	-- 물의 벽이 둥글게 솟았다가 가라앉는다
	local wall = part(Vector3.new(3, 4, 4), WATER, Enum.Material.Glass, 0.35, "cyl")
	wall.CFrame = CFrame.new(g + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	fadeOut(wall, 0.45, { Size = Vector3.new(0.5, r * 2, r * 2) })
	Fx.burst("glitter", at, FOAM, 20, 1.2)
	Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(190, 230, 255), 12, 1.2)
	Fx.sound("splash", 0.9, 1.1, at)
	shakeNear(at, 0.4, 40)
end

------------------------------------------------------------------------
-- 천하수류: 물의 용 셋이 몸을 감아 돌며 휩쓴다 (마디마다 물방울 구슬, 머리엔 뿔)
------------------------------------------------------------------------
local function waterDragons(data: any)
	local m: Model? = data.m
	local r0 = rootOf(m)
	if not r0 then
		return
	end
	local root = r0 :: BasePart
	local n = data.n or 3
	local R = data.radius or 20
	local dur = (data.dur or 2.6) + (data.delay or 0.3)
	local SEG = 14
	local dragons = {}
	for d = 1, n do
		local segs = {}
		for k = 1, SEG do
			local s = 3.4 - k * 0.16
			local p = part(Vector3.new(s, s, s), k == 1 and FOAM or WATER, k == 1 and Enum.Material.Neon or Enum.Material.Glass, k == 1 and 0.05 or 0.25, "ball")
			table.insert(segs, p)
		end
		-- 뿔 둘
		local horns = {}
		for h = -1, 1, 2 do
			local horn = part(Vector3.new(0.35, 0.35, 2.4), FOAM, Enum.Material.Neon, 0.1)
			horn:SetAttribute("Side", h)
			table.insert(horns, horn)
		end
		local trailHost = segs[1]
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 1, 0)
		a0.Parent = trailHost
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -1, 0)
		a1.Parent = trailHost
		local tr = Instance.new("Trail")
		tr.Attachment0 = a0
		tr.Attachment1 = a1
		tr.Color = ColorSequence.new(FOAM, WATER)
		tr.Transparency = NumberSequence.new(0.3, 1)
		tr.Lifetime = 0.5
		tr.LightEmission = 0.5
		tr.Parent = trailHost
		table.insert(dragons, { segs = segs, horns = horns, phase = (d - 1) / n * math.pi * 2 })
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > dur or not root.Parent then
			conn:Disconnect()
			return
		end
		local grow = math.clamp(t / 0.5, 0, 1)
		local c = root.Position
		for _, dr in ipairs(dragons) do
			-- 머리가 앞서고, 몸이 같은 길을 조금씩 늦게 따른다
			local function pos(tt: number): Vector3
				local ang = dr.phase + tt * 4.2
				local rad = (4 + (R - 4) * grow) * (0.75 + 0.25 * math.sin(tt * 2.3 + dr.phase))
				local y = 1 + 5 * math.sin(tt * 3.1 + dr.phase) + 2 * grow
				return c + Vector3.new(math.cos(ang) * rad, y, math.sin(ang) * rad)
			end
			for k, sgm in ipairs(dr.segs) do
				local p = pos(t - (k - 1) * 0.045)
				local q = pos(t - (k - 1) * 0.045 - 0.02)
				sgm.CFrame = CFrame.lookAt(p, p + (p - q))
			end
			local head = dr.segs[1]
			for _, horn in ipairs(dr.horns) do
				local side = horn:GetAttribute("Side") or 1
				horn.CFrame = head.CFrame * CFrame.new(side * 0.9, 1.1, 0.6) * CFrame.Angles(math.rad(-30), math.rad(side * 15), 0)
			end
		end
	end)
	Fx.sound("splash", 1, 0.7, root.Position)
	task.delay(dur, function()
		for _, dr in ipairs(dragons) do
			for _, sgm in ipairs(dr.segs) do
				fadeOut(sgm, 0.3)
			end
			for _, horn in ipairs(dr.horns) do
				fadeOut(horn, 0.3)
			end
		end
	end)
	-- 발밑에 소용돌이
	local g = ground(root.Position)
	local swirl = disc(g + Vector3.new(0, 0.1, 0), R * 2, WATER, 0.6)
	swirl.Material = Enum.Material.Glass
	task.delay(dur, function()
		fadeOut(swirl, 0.5)
	end)
end
-- 마지막: 용 셋이 하나로 엉겨 앞으로 덮치는 거대한 물결
local function dragonWave(data: any)
	local at: Vector3 = data.at
	local from: Vector3 = data.from or at
	local dir: Vector3 = data.dir or Vector3.new(0, 0, -1)
	local r = data.radius or 18
	local g0 = ground(from)
	local g1 = ground(at)
	local wave = part(Vector3.new(r * 2.2, 3, 4), WATER, Enum.Material.Glass, 0.2)
	wave.CFrame = CFrame.lookAt(g0 + Vector3.new(0, 1.5, 0), g0 + Vector3.new(0, 1.5, 0) + dir)
	local crest = part(Vector3.new(r * 2.2, 1.2, 2), FOAM, Enum.Material.Neon, 0.1)
	crest.CFrame = wave.CFrame * CFrame.new(0, 1.8, 0)
	local endCF = CFrame.lookAt(g1 + dir * r * 0.6 + Vector3.new(0, r * 0.45, 0), g1 + dir * r * 2 + Vector3.new(0, r * 0.45, 0))
	tween(wave, 0.4, { CFrame = endCF, Size = Vector3.new(r * 2.4, r * 0.9, 6) })
	tween(crest, 0.4, { CFrame = endCF * CFrame.new(0, r * 0.47, 0), Size = Vector3.new(r * 2.4, 1.5, 3) })
	task.delay(0.4, function()
		fadeOut(wave, 0.5, { CFrame = endCF * CFrame.new(0, -r * 0.4, -4), Size = Vector3.new(r * 2.6, 1, 8) })
		fadeOut(crest, 0.4)
		for i = 0, 2 do
			task.delay(i * 0.08, function()
				Fx.ring(g1 + Vector3.new(0, 0.4, 0), i == 1 and FOAM or WATER, 4, r * 2.4 + i * 6, 0.7)
			end)
		end
		Fx.burst("glitter", g1 + Vector3.new(0, 3, 0), FOAM, 50, 2.6)
		Fx.burst("dust", g1 + Vector3.new(0, 0.5, 0), Color3.fromRGB(190, 230, 255), 30, 2.4)
		Fx.flash(g1 + Vector3.new(0, 4, 0), WATER, 50, 5, 0.7)
		Fx.sound("splash", 1, 0.6, at)
		Fx.sound("heavy", 0.8, 0.8, at)
		shakeNear(at, 1.6, 80)
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	vajraQuake = vajraQuake,
	buddhaPalm = buddhaPalm,
	shadowEcho = shadowEcho,
	paradeStart = paradeStart,
	paradePass = paradePass,
	paradeEnd = paradeEnd,
	flowWave = flowWave,
	waterDragons = waterDragons,
	dragonWave = dragonWave,
}
function Awake.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil
end
function Awake.run(data: any)
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

-- (안 쓰는 경고 막기)
local _ = player
local _c = Config

return Awake
