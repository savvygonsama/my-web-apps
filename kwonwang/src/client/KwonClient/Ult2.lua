-- 권왕 2.0판: 새 오의들의 화면
-- 각성 권법 아홉의 오의 (혈해만마 · 구룡승천 · 뇌정천망 · 천수여래 · 무영천살 · 창해만류 · 화룡천멸 · 심해강림 · 천풍만검)
-- 초·벽력신권의 뇌룡승천과 초 오의 구천뇌정 (컷씬 포함)
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))
local Demon = require(script.Parent:WaitForChild("Demon"))

local Ult2 = {}
local player = Players.LocalPlayer

local WHITE = Color3.new(1, 1, 1)
local folder = Instance.new("Folder")
folder.Name = "KwonUlt2"
folder.Parent = workspace

local opts: any = {}
function Ult2.init(o: any)
	opts = o or {}
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
local function disc(at: Vector3, d: number, color: Color3, alpha: number, mat: Enum.Material?): Part
	local p = part(Vector3.new(0.2, d, d), color, mat or Enum.Material.Neon, alpha, "cyl")
	p.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	return p
end
-- 세로 기둥 (땅에서 위로)
local function column(base: Vector3, height: number, width: number, color: Color3, alpha: number?, mat: Enum.Material?): Part
	local c = part(Vector3.new(height, width, width), color, mat or Enum.Material.Neon, alpha or 0.1, "cyl")
	c.CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	return c
end
local function styleColors(id: any): (Color3, Color3)
	local st = type(id) == "string" and Config.STYLE_BY_ID[id] or nil
	if st then
		return st.color, st.color2
	end
	return Color3.fromRGB(255, 200, 90), WHITE
end
local function shakeNear(pos: Vector3, amount: number, range: number)
	if opts.shake and near(pos, range) then
		opts.shake(amount)
	end
end
local function tintNear(pos: Vector3, color: Color3, strength: number, time: number)
	if opts.tint and near(pos, 90) then
		opts.tint(color, strength, time)
	end
end
-- 터지는 곳의 공통 마무리: 고리 셋, 불티, 흙먼지, 빛
local function blast(at: Vector3, radius: number, c: Color3, c2: Color3, power: number?)
	local k = power or 1
	local g = ground(at)
	for i = 0, 2 do
		task.delay(i * 0.07, function()
			Fx.ring(g + Vector3.new(0, 0.3, 0), i == 1 and c2 or c, 3, radius * 2.2 + i * 6, 0.7)
		end)
	end
	Fx.burst("spark", at + Vector3.new(0, 2, 0), c, math.floor(30 * k), 2 * k)
	Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(170, 155, 135), math.floor(24 * k), 2 * k)
	Fx.flash(at + Vector3.new(0, 3, 0), c, 50, 5 * k, 0.7)
	shakeNear(at, 1.2 * k, 90)
end

------------------------------------------------------------------------
-- 용 그리기: 마디 구슬이 길을 따라 늦게 따라오는 몸 + 머리의 뿔과 수염
-- path(t) → 위치 (t는 초). 머리가 앞서고 몸이 같은 길을 조금씩 늦게 간다
------------------------------------------------------------------------
type DragonLook = { body: Color3, belly: Color3, mat: Enum.Material, scale: number, seg: number, trail: Color3 }
local function dragon(look: DragonLook, path: (number) -> Vector3, dur: number, onEnd: (() -> ())?)
	local segs: { BasePart } = {}
	for k = 1, look.seg do
		local s = (2.6 - k * (1.6 / look.seg)) * look.scale
		local p = part(Vector3.new(s, s, s), k % 3 == 0 and look.belly or look.body, look.mat, k == 1 and 0 or 0.05, "ball")
		table.insert(segs, p)
	end
	local head = segs[1]
	head.Size = head.Size * 1.3
	-- 뿔 둘, 수염 둘
	local extras: { { p: BasePart, off: CFrame } } = {}
	for _, sd in ipairs({ -1, 1 }) do
		table.insert(extras, { p = part(Vector3.new(0.3, 0.3, 2.6) * look.scale, look.belly, Enum.Material.Neon, 0), off = CFrame.new(sd * 0.9 * look.scale, 1.2 * look.scale, 0.8 * look.scale) * CFrame.Angles(math.rad(-35), math.rad(sd * 18), 0) })
		table.insert(extras, { p = part(Vector3.new(0.15, 0.15, 3.2) * look.scale, look.trail, Enum.Material.Neon, 0.2), off = CFrame.new(sd * 0.7 * look.scale, -0.6 * look.scale, -1.4 * look.scale) * CFrame.Angles(math.rad(25), math.rad(sd * 30), 0) })
	end
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = head
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = head
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Color = ColorSequence.new(look.trail, look.body)
	tr.Transparency = NumberSequence.new(0.2, 1)
	tr.Lifetime = 0.45
	tr.LightEmission = 0.7
	tr.WidthScale = NumberSequence.new(1, 0)
	tr.Parent = head
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > dur then
			conn:Disconnect()
			for _, sgm in ipairs(segs) do
				fadeOut(sgm, 0.25)
			end
			for _, e in ipairs(extras) do
				fadeOut(e.p, 0.2)
			end
			if onEnd then
				onEnd()
			end
			return
		end
		for k, sgm in ipairs(segs) do
			local tk = t - (k - 1) * 0.035
			local p = path(math.max(0, tk))
			local q = path(math.max(0, tk - 0.02))
			local d = p - q
			sgm.CFrame = d.Magnitude > 1e-3 and CFrame.lookAt(p, p + d) or CFrame.new(p)
		end
		for _, e in ipairs(extras) do
			e.p.CFrame = head.CFrame * e.off
		end
	end)
end
local function lookFor(kind: string, c: Color3, c2: Color3): DragonLook
	if kind == "fireDragon" then
		return { body = Color3.fromRGB(255, 90, 20), belly = Color3.fromRGB(255, 220, 110), mat = Enum.Material.Neon, scale = 1.9, seg = 22, trail = Color3.fromRGB(255, 160, 60) }
	elseif kind == "thunderDragon" then
		return { body = Color3.fromRGB(160, 130, 255), belly = Color3.fromRGB(255, 250, 200), mat = Enum.Material.Neon, scale = 1.5, seg = 20, trail = Color3.fromRGB(230, 220, 255) }
	end
	return { body = c, belly = c2, mat = Enum.Material.Foil, scale = 1.0, seg = 16, trail = c2 }
end

-- 용이 솟는다: 둘레(또는 내 몸)에서 땅을 뚫고 나와 나선으로 하늘로 감아 오른다
local function dragonsRise(data: any)
	local r = rootOf(data.m)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = styleColors(data.style)
	local look = lookFor(data.look or "nineDragons", c, c2)
	local n = data.n or 1
	local R = data.radius or 10
	local rise = data.rise or 1
	local g = ground(at)
	for i = 1, n do
		local a0 = (i - 1) / n * math.pi * 2
		local start = g + Vector3.new(math.cos(a0), 0, math.sin(a0)) * (n > 1 and R or 2)
		Fx.burst("dust", start + Vector3.new(0, 0.5, 0), Color3.fromRGB(160, 140, 110), 10, 1.4)
		Fx.debris(start, 3, 14)
		dragon(look, function(t: number): Vector3
			local u = t / rise
			local ang = a0 + u * math.pi * 2.2
			local rad = (n > 1 and R or 4) * (1 - 0.4 * u)
			local base = r and r.Parent and ground(r.Position) or g
			return base + Vector3.new(math.cos(ang) * rad, -3 + u * 55, math.sin(ang) * rad)
		end, rise)
	end
	Fx.ring(g + Vector3.new(0, 0.3, 0), c, 3, R * 2.6, 0.6)
	Fx.flash(at, c, 40, 4, 0.6)
	Fx.sound("heavy", 1, 0.6, at)
	shakeNear(at, 1, 70)
end
-- 하늘에서 한 마리가 목표에 내리꽂힌다
local function dragonDive(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = styleColors(data.style)
	local kind = data.look or "nineDragons"
	local look = lookFor(kind, c, c2)
	local from: Vector3 = data.from or at
	local side = flat(at - from)
	local sky = at + Vector3.new(0, 60, 0) - side * 30 + Vector3.new(side.Z, 0, -side.X) * ((data.i or 1) % 2 == 0 and 14 or -14)
	local dur = 0.32
	dragon(look, function(t: number): Vector3
		local u = math.clamp(t / dur, 0, 1)
		local e = u * u
		return sky:Lerp(at - Vector3.new(0, 2, 0), e) + Vector3.new(0, math.sin(u * math.pi) * 6, 0)
	end, dur + 0.12, function()
		local radius = data.radius or 8
		blast(at, radius, look.body, look.belly, 0.8)
		if kind == "thunderDragon" then
			Fx.lightning(at + Vector3.new(0, 50, 0), at, look.trail, 0.7)
		elseif kind == "fireDragon" then
			Fx.burst("ember", at + Vector3.new(0, 2, 0), look.trail, 30, 2)
		end
		Fx.sound("heavy", 0.8, 0.8, at)
	end)
end
local function dragonsEnd(data: any)
	local at: Vector3 = data.at
	local c, c2 = styleColors(data.style)
	local look = lookFor(data.look or "nineDragons", c, c2)
	local R = data.radius or 20
	local g = ground(at)
	local col = column(g, 90, R * 0.8, look.belly, 0.05)
	fadeOut(col, 0.7, { Size = Vector3.new(120, R * 1.8, R * 1.8) })
	local core = column(g, 90, R * 0.3, WHITE, 0)
	fadeOut(core, 0.4)
	blast(at, R, look.body, look.belly, 1.6)
	if data.look == "thunderDragon" then
		for _ = 1, 6 do
			local a = math.random() * math.pi * 2
			local p = at + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(3, math.floor(R))
			Fx.lightning(p + Vector3.new(0, 45, 0), p, look.trail, 0.5)
		end
	end
	Fx.sound("heavy", 1, 0.4, at)
	tintNear(at, look.body, 0.25, 0.4)
end
-- 화룡천멸: 떨어진 자리가 용암이 되어 터진다
local function lavaBurst(data: any)
	local at: Vector3 = data.at
	local R = data.radius or 18
	local g = ground(at)
	if (data.i or 1) == 1 then
		local pool = disc(g + Vector3.new(0, 0.12, 0), R * 2, Color3.fromRGB(255, 90, 20), 0.15)
		task.delay(1.6, function()
			fadeOut(pool, 0.8)
		end)
	end
	for _ = 1, 5 do
		local a = math.random() * math.pi * 2
		local p = g + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(0, math.floor(R * 0.8))
		local col = column(p, 14 + math.random() * 8, 2.6, Color3.fromRGB(255, 120, 30), 0.1)
		fadeOut(col, 0.45, { Size = Vector3.new(26, 0.4, 0.4) })
	end
	Fx.burst("ember", at + Vector3.new(0, 2, 0), Color3.fromRGB(255, 140, 50), 30, 2)
	Fx.flash(at, Color3.fromRGB(255, 110, 30), 40, 4, 0.5)
	Fx.sound("heavy", 0.7, 0.9, at)
	shakeNear(at, 0.7, 60)
end

------------------------------------------------------------------------
-- 혈해만마: 피의 바다, 솟는 손톱, 피의 소용돌이 기둥
------------------------------------------------------------------------
local BLOOD = Color3.fromRGB(150, 0, 18)
local function bloodSea(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local R = data.radius or 26
	local dur = data.dur or 3
	local g = ground(at)
	local sea = disc(g + Vector3.new(0, 0.1, 0), 2, BLOOD, 0.15, Enum.Material.Glass)
	tween(sea, 0.5, { Size = Vector3.new(0.2, R * 2.1, R * 2.1) })
	local glow = disc(g + Vector3.new(0, 0.14, 0), 2, Color3.fromRGB(230, 20, 40), 0.6)
	tween(glow, 0.5, { Size = Vector3.new(0.2, R * 1.6, R * 1.6) })
	-- 끓는 거품
	local host = part(Vector3.new(R * 1.8, 1, R * 1.8), BLOOD, Enum.Material.SmoothPlastic, 1)
	host.CFrame = CFrame.new(g + Vector3.new(0, 0.6, 0))
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(220, 20, 40), BLOOD)
	pe.Rate = 60
	pe.Lifetime = NumberRange.new(0.4, 0.8)
	pe.Speed = NumberRange.new(2, 6)
	pe.Size = NumberSequence.new(0.5, 0)
	pe.Shape = Enum.ParticleEmitterShape.Box
	pe.Parent = host
	task.delay(dur, function()
		pe.Enabled = false
		fadeOut(sea, 0.8)
		fadeOut(glow, 0.6)
		task.delay(1, function()
			host:Destroy()
		end)
	end)
	tintNear(at, Color3.fromRGB(140, 0, 20), 0.3, dur)
	Fx.sound("splash", 1, 0.5, at)
	-- 2.1판: 피의 바다에서 악마 다섯이 허리까지 솟아 바깥을 보며 손톱을 휘두른다
	local n = 5
	local spin = math.random() * math.pi * 2
	for i = 1, n do
		local ang = spin + (i / n) * math.pi * 2
		local out = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local pos = g + out * R * 0.6
		local base = CFrame.lookAt(pos, pos + out)
		local sc = 1.15 + math.random() * 0.35
		local ph = math.random() * 6
		local dm = Demon.spawn(base * CFrame.new(0, -9 * sc, 0), sc, { legs = false })
		dm.anim = function(t: number)
			local rise = math.clamp(t / 0.45, 0, 1)
			rise = 1 - (1 - rise) ^ 3
			local sink = math.clamp((t - dur) / 0.6, 0, 1)
			local y = -9 * sc + 5.8 * sc * rise - 6 * sc * sink
			dm.root = base * CFrame.new(0, y + math.sin(t * 3 + ph) * 0.3 * sc, 0) * CFrame.Angles(0, math.sin(t * 1.3 + ph) * 0.35, 0)
			dm.armR = 0.4 + 2.0 * math.max(0, math.sin(t * 4.4 + ph))
			dm.armL = 0.4 + 2.0 * math.max(0, math.sin(t * 4.4 + ph + math.pi))
		end
		task.delay(dur + 0.6, function()
			Demon.remove(dm, 0.3)
		end)
	end
	Fx.sound("deflect", 0.8, 0.35, at)
end
local function bloodClaw(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local g = ground(at)
	local yaw = math.random() * math.pi * 2
	-- 휜 손톱 셋이 피에서 솟는다
	for k = -1, 1 do
		local base = CFrame.new(g) * CFrame.Angles(0, yaw, 0) * CFrame.new(k * 1.6, 0, 0)
		for j = 0, 4 do
			local seg = part(Vector3.new(0.7 - j * 0.1, 1.8, 0.7 - j * 0.1), j == 4 and Color3.fromRGB(255, 200, 200) or Color3.fromRGB(200, 15, 35), Enum.Material.Neon, 0)
			local cf = base * CFrame.Angles(math.rad(-12 * j), 0, 0) * CFrame.new(0, 1 + j * 1.6, -j * 0.5)
			seg.CFrame = cf * CFrame.new(0, -9, 0)
			tween(seg, 0.12, { CFrame = cf }, Enum.EasingStyle.Back)
			task.delay(0.3, function()
				fadeOut(seg, 0.25, { CFrame = cf * CFrame.new(0, -4, 0) })
			end)
		end
	end
	Fx.burst("spark", at, Color3.fromRGB(230, 30, 50), 14, 1.2)
	Fx.ring(g + Vector3.new(0, 0.3, 0), Color3.fromRGB(230, 30, 50), 2, (data.radius or 7) * 2, 0.35)
	if (data.i or 1) % 2 == 0 then
		Fx.sound("hit", 0.6, 0.7, at)
	end
end
local function bloodVortex(data: any)
	local at: Vector3 = data.at
	local R = data.radius or 26
	local g = ground(at)
	-- 핏빛 소용돌이 기둥: 돌아가는 고리들이 위로 솟는다
	for k = 0, 9 do
		task.delay(k * 0.04, function()
			local ring = part(Vector3.new(0.4, R * (1.2 - k * 0.07), R * (1.2 - k * 0.07)), k % 2 == 0 and Color3.fromRGB(220, 20, 40) or BLOOD, Enum.Material.Neon, 0.25, "cyl")
			ring.CFrame = CFrame.new(g + Vector3.new(0, 1 + k * 4, 0)) * CFrame.Angles(0, 0, math.rad(90))
			fadeOut(ring, 0.6, { CFrame = ring.CFrame * CFrame.new(10, 0, 0) * CFrame.Angles(math.rad(90), 0, 0) })
		end)
	end
	local col = column(g, 80, R * 0.5, Color3.fromRGB(230, 20, 40), 0.15)
	fadeOut(col, 0.7, { Size = Vector3.new(100, R * 1.2, R * 1.2) })
	blast(at, R, Color3.fromRGB(230, 20, 40), Color3.fromRGB(255, 170, 170), 1.6)
	Fx.sound("splash", 1, 0.4, at)
end

------------------------------------------------------------------------
-- 뇌정천망: 적들을 잇는 번개 그물
------------------------------------------------------------------------
local VIOLET = Color3.fromRGB(175, 110, 255)
local nets: { [Model]: { until_: number, targets: { Model } } } = {}
local function netStart(data: any)
	local m: Model? = data.m
	if not m then
		return
	end
	nets[m :: Model] = { until_ = os.clock() + (data.dur or 2), targets = data.targets or {} }
	local r = rootOf(m)
	if r then
		tintNear(r.Position, Color3.fromRGB(90, 60, 180), 0.3, data.dur or 2)
	end
end
RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for m, net in pairs(nets) do
		if t > net.until_ or not m.Parent then
			nets[m] = nil
		elseif math.random() < 0.5 then
			-- 그물 새로 그리기 (무작위로 이어지는 번개): 나 → 적, 적 → 가까운 적
			local r = rootOf(m)
			local pts: { Vector3 } = {}
			for _, tm in ipairs(net.targets) do
				local tr = rootOf(tm)
				if tr and tm:GetAttribute("Dead") ~= true then
					table.insert(pts, tr.Position)
				end
			end
			if r and near(r.Position, 150) then
				for i, p in ipairs(pts) do
					if i <= 4 then
						Fx.lightning(r.Position + Vector3.new(0, 1, 0), p, VIOLET, 0.25)
					end
					local q = pts[i % #pts + 1]
					if q and q ~= p then
						Fx.lightning(p, q, Color3.fromRGB(220, 200, 255), 0.2)
					end
				end
			end
		end
	end
end)
local function netPulse(data: any)
	for _, tm in ipairs(data.targets or {}) do
		local tr = rootOf(tm)
		if tr then
			local b = part(Vector3.new(1, 1, 1), VIOLET, Enum.Material.Neon, 0.2, "ball")
			b.CFrame = CFrame.new(tr.Position)
			fadeOut(b, 0.25, { Size = Vector3.new(6, 6, 6) })
		end
	end
	local r = rootOf(data.m)
	if r then
		Fx.sound("deflect", 0.6, 1.4, r.Position)
	end
end
local function netEnd(data: any)
	for _, tm in ipairs(data.targets or {}) do
		local tr = rootOf(tm)
		if tr then
			local p = tr.Position
			Fx.lightning(p + Vector3.new(0, 60, 0), p, Color3.fromRGB(235, 225, 255), 0.9)
			local col = column(ground(p), 60, 3, VIOLET, 0.1)
			fadeOut(col, 0.4, { Size = Vector3.new(70, 0.4, 0.4) })
			Fx.ring(ground(p) + Vector3.new(0, 0.3, 0), VIOLET, 2, 18, 0.5)
		end
	end
	local r = rootOf(data.m)
	if r then
		Fx.flash(r.Position, VIOLET, 60, 6, 0.6)
		shakeNear(r.Position, 1.6, 90)
		Fx.sound("heavy", 1, 0.8, r.Position)
	end
	if data.m then
		nets[data.m] = nil
	end
end

------------------------------------------------------------------------
-- 천수여래: 등 뒤의 금빛 여래 (팔 여럿), 팔이 내리치는 손바닥
------------------------------------------------------------------------
local GOLD = Color3.fromRGB(255, 190, 60)
local GOLD_PALE = Color3.fromRGB(255, 245, 200)
local statues: { [Model]: Model } = {}
local function armsStart(data: any)
	local m: Model? = data.m
	local r = rootOf(m)
	if not m or not r then
		return
	end
	local dur = data.dur or 3
	local look = flat(r.CFrame.LookVector)
	local base = CFrame.lookAt(ground(r.Position) - look * 10, ground(r.Position) - look * 10 + look)
	local mdl = Instance.new("Model")
	mdl.Name = "ThousandArms"
	local function add(p: BasePart, cf: CFrame)
		p.CFrame = base * cf * CFrame.new(0, -40, 0)
		p.Parent = mdl
		tween(p, 0.6, { CFrame = base * cf }, Enum.EasingStyle.Back)
	end
	add(part(Vector3.new(12, 16, 7), GOLD, Enum.Material.Foil, 0.15), CFrame.new(0, 14, 0))
	add(part(Vector3.new(8, 8, 8), GOLD, Enum.Material.Foil, 0.15, "ball"), CFrame.new(0, 26, 0))
	add(part(Vector3.new(16, 5, 10), GOLD, Enum.Material.Foil, 0.2), CFrame.new(0, 4.5, 0))
	local halo = part(Vector3.new(0.4, 20, 20), GOLD_PALE, Enum.Material.Neon, 0.4, "cyl")
	add(halo, CFrame.new(0, 26, 4) * CFrame.Angles(0, math.rad(90), 0))
	-- 양쪽으로 부채처럼 펼친 팔 열둘
	for i = 1, 12 do
		local sd = i % 2 == 0 and 1 or -1
		local k = math.ceil(i / 2)
		local cf = CFrame.new(sd * 6, 18, 0) * CFrame.Angles(0, 0, math.rad(sd * (20 + k * 18))) * CFrame.new(0, 7, 0)
		add(part(Vector3.new(1.6, 14, 1.6), GOLD, Enum.Material.Foil, 0.2), cf)
		add(part(Vector3.new(2.6, 3, 1), GOLD_PALE, Enum.Material.Neon, 0.25), cf * CFrame.new(0, 7.5, 0))
	end
	mdl.Parent = folder
	local mm = m :: Model
	statues[mm] = mdl
	task.delay(dur, function()
		for _, p in ipairs(mdl:GetChildren()) do
			if p:IsA("BasePart") then
				fadeOut(p, 0.6)
			end
		end
		task.delay(0.7, function()
			mdl:Destroy()
		end)
		if statues[mm] == mdl then
			statues[mm] = nil
		end
	end)
	Fx.burst("glitter", r.Position + Vector3.new(0, 10, 0), GOLD, 40, 2.4)
	Fx.sound("deflect", 1, 0.4, r.Position)
	tintNear(r.Position, GOLD, 0.2, dur)
end
local function armStrike(data: any)
	local at: Vector3 = data.at
	local r = rootOf(data.m)
	local from = r and (r.Position + Vector3.new(0, 30, 0) - flat(r.CFrame.LookVector) * 10) or (at + Vector3.new(0, 40, 0))
	local g = ground(at)
	-- 금빛 손바닥 하나가 하늘에서 내리친다
	local palm = part(Vector3.new(6, 1.2, 7), GOLD, Enum.Material.Foil, 0.05)
	palm.CFrame = CFrame.new(from)
	tween(palm, 0.14, { CFrame = CFrame.new(g + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, math.random() * 6, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local beam = part(Vector3.new(1, 1, (from - g).Magnitude), GOLD_PALE, Enum.Material.Neon, 0.5)
	beam.CFrame = CFrame.lookAt((from + g) / 2, g)
	fadeOut(beam, 0.2)
	task.delay(0.14, function()
		Fx.ring(g + Vector3.new(0, 0.3, 0), GOLD, 2, (data.radius or 8) * 2.4, 0.45)
		Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(200, 175, 130), 12, 1.4)
		Fx.burst("glitter", g + Vector3.new(0, 1, 0), GOLD, 10, 1.2)
		Fx.sound("heavy", 0.7, 0.8, at)
		shakeNear(at, 0.6, 60)
		task.delay(0.25, function()
			fadeOut(palm, 0.3)
		end)
	end)
end

------------------------------------------------------------------------
-- 무영천살: 어둠, 붉은 표식, 한꺼번에 터짐, 하늘에서 그림자의 발
------------------------------------------------------------------------
local SHADOW = Color3.fromRGB(30, 12, 50)
local MARK = Color3.fromRGB(255, 40, 60)
local marks: { [Model]: { BasePart } } = {}
local function darkStart(data: any)
	local at: Vector3 = data.at
	local dur = data.dur or 2
	if near(at, 120) then
		local e = Instance.new("ColorCorrectionEffect")
		e.Name = "KwonShadowKill"
		e.Parent = Lighting
		tween(e, 0.3, { Brightness = -0.35, Contrast = 0.3, Saturation = -0.6 })
		task.delay(dur, function()
			tween(e, 0.4, { Brightness = 0, Contrast = 0, Saturation = 0 })
			task.delay(0.45, function()
				e:Destroy()
			end)
		end)
	end
	local g = ground(at)
	local fog = disc(g + Vector3.new(0, 0.1, 0), (data.radius or 36) * 2, SHADOW, 0.35, Enum.Material.SmoothPlastic)
	task.delay(dur, function()
		fadeOut(fog, 0.5)
	end)
	Fx.burst("smoke", at, SHADOW, 30, 2.4)
	Fx.sound("deflect", 0.8, 0.4, at)
end
local function killMark(data: any)
	local t: Model? = data.t
	local tr = rootOf(t)
	if not t or not tr then
		return
	end
	-- 몸 앞에 떠 있는 붉은 X 표식 (몸을 따라간다)
	local list: { BasePart } = {}
	for _, ang in ipairs({ 45, -45 }) do
		local bar = part(Vector3.new(0.4, 5, 0.4), MARK, Enum.Material.Neon, 0)
		table.insert(list, bar)
		bar:SetAttribute("Ang", ang)
	end
	local tm = t :: Model
	marks[tm] = list
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if marks[tm] ~= list or not tr.Parent then
			conn:Disconnect()
			for _, b in ipairs(list) do
				if b.Parent then
					b:Destroy()
				end
			end
			return
		end
		local cam = workspace.CurrentCamera
		local face = cam and flat(cam.CFrame.Position - tr.Position) or Vector3.new(0, 0, 1)
		local pulse = 1 + 0.15 * math.sin((os.clock() - t0) * 18)
		for _, b in ipairs(list) do
			b.Size = Vector3.new(0.4, 5 * pulse, 0.4)
			b.CFrame = CFrame.lookAt(tr.Position + face * 1.6, tr.Position + face * 3) * CFrame.Angles(0, 0, math.rad(b:GetAttribute("Ang") or 0))
		end
	end)
	Fx.sound("swing", 0.6, 1.4, tr.Position)
end
local function killBurst(data: any)
	for _, t in ipairs(data.targets or {}) do
		local list = marks[t]
		marks[t] = nil
		if list then
			for _, b in ipairs(list) do
				fadeOut(b, 0.2, { Size = Vector3.new(1.2, 10, 1.2) })
			end
		end
		local tr = rootOf(t)
		if tr then
			for _ = 1, 3 do
				local d = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit
				local s = part(Vector3.new(0.2, 0.2, 12), MARK, Enum.Material.Neon, 0)
				s.CFrame = CFrame.lookAt(tr.Position - d * 6, tr.Position + d * 6)
				fadeOut(s, 0.25, { Size = Vector3.new(0.05, 0.05, 16) })
			end
			Fx.burst("smoke", tr.Position, SHADOW, 10, 1.2)
			Fx.burst("spark", tr.Position, MARK, 14, 1.2)
		end
	end
	Fx.sound("hit", 1, 0.6)
end
local function shadowStomp(data: any)
	local at: Vector3 = data.at
	local R = data.radius or 20
	local g = ground(at)
	-- 하늘에서 내려오는 거대한 그림자의 발 (발바닥 + 발가락)
	local foot = Instance.new("Model")
	local function add(size: Vector3, cf: CFrame, shape: string?)
		local p = part(size, SHADOW, Enum.Material.Neon, 0.15, shape)
		p.CFrame = cf
		p.Parent = foot
	end
	add(Vector3.new(R * 0.9, 4, R * 1.3), CFrame.new())
	for i = -2, 2 do
		add(Vector3.new(R * 0.18, R * 0.18, R * 0.18), CFrame.new(i * R * 0.17, 0, -R * 0.72), "ball")
	end
	foot.WorldPivot = CFrame.new()
	foot.Parent = folder
	local yaw = math.random() * math.pi * 2
	local fromCF = CFrame.new(g + Vector3.new(0, 90, 0)) * CFrame.Angles(0, yaw, 0)
	local toCF = CFrame.new(g + Vector3.new(0, 2, 0)) * CFrame.Angles(0, yaw, 0)
	foot:PivotTo(fromCF)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local u = math.clamp((os.clock() - t0) / 0.3, 0, 1)
		foot:PivotTo(fromCF:Lerp(toCF, u * u))
		if u >= 1 then
			conn:Disconnect()
			blast(at, R, VIOLET, MARK, 1.5)
			Fx.sound("heavy", 1, 0.4, at)
			for _, p in ipairs(foot:GetChildren()) do
				if p:IsA("BasePart") then
					fadeOut(p, 0.6)
				end
			end
			task.delay(0.7, function()
				foot:Destroy()
			end)
		end
	end)
end

------------------------------------------------------------------------
-- 창해만류 · 심해강림
------------------------------------------------------------------------
local WATER = Color3.fromRGB(60, 180, 255)
local walls: { [string]: { BasePart } } = {}
local function keyOf(v: Vector3): string
	return string.format("%d,%d,%d", math.floor(v.X), math.floor(v.Y), math.floor(v.Z))
end
local FOAM = Color3.fromRGB(225, 250, 255)
local DEEP = Color3.fromRGB(10, 30, 80)
local function maelstrom(data: any)
	local at: Vector3 = data.at
	local R = data.radius or 24
	local dur = data.dur or 2.4
	local g = ground(at)
	local pool = disc(g + Vector3.new(0, 0.1, 0), R * 2, WATER, 0.3, Enum.Material.Glass)
	-- 도는 물살 (나선 조각들)과 둘레에서 솟는 물의 벽
	local streaks: { BasePart } = {}
	for i = 1, 14 do
		local s = part(Vector3.new(0.5, 0.3, R * 0.5), i % 2 == 0 and FOAM or WATER, Enum.Material.Neon, 0.3)
		table.insert(streaks, s)
	end
	local wall: { BasePart } = {}
	local N = 22
	for i = 1, N do
		local w = part(Vector3.new(R * 2 * math.pi / N * 1.1, 1, 1.6), WATER, Enum.Material.Glass, 0.3)
		table.insert(wall, w)
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > dur then
			conn:Disconnect()
			for _, s in ipairs(streaks) do
				fadeOut(s, 0.2)
			end
			return
		end
		for i, s in ipairs(streaks) do
			local a = i / #streaks * math.pi * 2 + t * 3
			local rad = R * (0.25 + 0.65 * ((i * 0.37 + t * 0.5) % 1))
			local p = g + Vector3.new(math.cos(a) * rad, 0.4, math.sin(a) * rad)
			s.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a)))
		end
		local h = math.min(1, t / (dur * 0.7)) * 16
		for i, w in ipairs(wall) do
			local a = i / N * math.pi * 2
			w.Size = Vector3.new(w.Size.X, math.max(1, h), 1.6)
			w.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * R, h / 2, math.sin(a) * R)) * CFrame.Angles(0, -a + math.pi / 2, 0)
		end
	end)
	task.delay(dur + 0.3, function()
		fadeOut(pool, 0.6)
	end)
	walls[keyOf(at)] = wall
	Fx.sound("splash", 1, 0.5, at)
end
local function maelstromEnd(data: any)
	local at: Vector3 = data.at
	local R = data.radius or 24
	local g = ground(at)
	local wl = walls[keyOf(at)]
	if wl then
		walls[keyOf(at)] = nil
		-- 벽이 안쪽으로 무너진다
		for _, w in ipairs(wl) do
			tween(w, 0.3, { CFrame = CFrame.new(g + Vector3.new(0, 2, 0)) * (w.CFrame - w.CFrame.Position), Size = Vector3.new(w.Size.X * 0.3, 2, 6) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.3, function()
				fadeOut(w, 0.3)
			end)
		end
	end
	task.delay(0.3, function()
		local col = column(g, 50, R * 0.5, FOAM, 0.1, Enum.Material.Glass)
		fadeOut(col, 0.6, { Size = Vector3.new(70, R * 0.2, R * 0.2) })
		blast(at, R, WATER, FOAM, 1.5)
		Fx.burst("glitter", at + Vector3.new(0, 4, 0), FOAM, 50, 2.6)
		Fx.sound("splash", 1, 0.4, at)
	end)
end
local function abyss(data: any)
	local at: Vector3 = data.at
	local R = data.radius or 24
	local dur = data.dur or 1.8
	local g = ground(at)
	local deep = disc(g + Vector3.new(0, 0.12, 0), 2, DEEP, 0.05, Enum.Material.Glass)
	tween(deep, 0.4, { Size = Vector3.new(0.2, R * 2, R * 2) })
	local rim = disc(g + Vector3.new(0, 0.16, 0), R * 2, WATER, 0.5)
	rim.Size = Vector3.new(0.2, R * 2.05, R * 2.05)
	local host = part(Vector3.new(R * 1.6, 1, R * 1.6), DEEP, Enum.Material.SmoothPlastic, 1)
	host.CFrame = CFrame.new(g + Vector3.new(0, 0.6, 0))
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(FOAM, WATER)
	pe.Rate = 50
	pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Speed = NumberRange.new(3, 7)
	pe.Size = NumberSequence.new(0.6, 0.1)
	pe.Shape = Enum.ParticleEmitterShape.Box
	pe.Parent = host
	task.delay(dur + 0.3, function()
		pe.Enabled = false
		fadeOut(deep, 0.6)
		fadeOut(rim, 0.5)
		task.delay(1.2, function()
			host:Destroy()
		end)
	end)
	tintNear(at, Color3.fromRGB(20, 50, 120), 0.35, dur)
	Fx.sound("splash", 1, 0.4, at)
end
local function abyssEnd(data: any)
	local at: Vector3 = data.at
	local R = data.radius or 24
	local g = ground(at)
	local col = column(g, 1, R * 0.9, WATER, 0.15, Enum.Material.Glass)
	tween(col, 0.25, { Size = Vector3.new(90, R * 0.9, R * 0.9), CFrame = CFrame.new(g + Vector3.new(0, 45, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(0.3, function()
		fadeOut(col, 0.7, { Size = Vector3.new(110, R * 1.3, R * 1.3) })
	end)
	local core = column(g, 90, R * 0.4, FOAM, 0.1, Enum.Material.Neon)
	fadeOut(core, 0.5)
	blast(at, R, WATER, FOAM, 1.6)
	Fx.burst("glitter", at + Vector3.new(0, 8, 0), FOAM, 60, 3)
	Fx.sound("splash", 1, 0.3, at)
end

------------------------------------------------------------------------
-- 천풍만검: 몸을 도는 바람 칼날, 사방으로 쏘아짐, 하늘까지 닿는 회오리
------------------------------------------------------------------------
local WIND = Color3.fromRGB(120, 245, 200)
local blades: { [Model]: { BasePart } } = {}
local function galeBlades(data: any)
	local m: Model? = data.m
	local r = rootOf(m)
	if not m or not r then
		return
	end
	local root = r :: BasePart
	local n = data.n or 12
	local R = data.radius or 9
	local spin = data.spin or 1.2
	local list: { BasePart } = {}
	for i = 1, n do
		local b = part(Vector3.new(0.2, 1.6, 5), i % 2 == 0 and WHITE or WIND, Enum.Material.Neon, 0.1)
		table.insert(list, b)
	end
	local mm = m :: Model
	blades[mm] = list
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > spin + 0.6 or blades[mm] ~= list or not root.Parent then
			conn:Disconnect()
			return
		end
		for i, b in ipairs(list) do
			local a = i / n * math.pi * 2 + t * 7
			local p = root.Position + Vector3.new(math.cos(a) * R, 0.5 + math.sin(t * 6 + i) * 1.2, math.sin(a) * R)
			b.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a)))
		end
	end)
	Fx.sound("swing", 1, 0.8, root.Position)
end
local function galeShoot(data: any)
	local at: Vector3 = data.at
	local range = data.range or 24
	for m, list in pairs(blades) do
		local r = rootOf(m)
		if r and (r.Position - at).Magnitude < 6 then
			blades[m] = nil
			for i, b in ipairs(list) do
				local a = i / #list * math.pi * 2
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				tween(b, 0.25, { CFrame = CFrame.lookAt(at + dir * range, at + dir * (range + 2)) })
				task.delay(0.25, function()
					fadeOut(b, 0.2)
				end)
			end
		end
	end
	Fx.ring(ground(at) + Vector3.new(0, 0.5, 0), WIND, 4, range * 2, 0.4)
	Fx.sound("swing", 1, 1.2, at)
end
local function galeTwister(data: any)
	local at: Vector3 = data.at
	local R = data.radius or 16
	local g = ground(at)
	local rings: { BasePart } = {}
	for k = 1, 12 do
		local d = R * (0.4 + k * 0.1)
		table.insert(rings, part(Vector3.new(0.5, d, d), k % 2 == 0 and WHITE or WIND, Enum.Material.Neon, 0.5, "cyl"))
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > 1.2 then
			conn:Disconnect()
			for _, rg in ipairs(rings) do
				fadeOut(rg, 0.3)
			end
			return
		end
		for k, rg in ipairs(rings) do
			local wob = Vector3.new(math.cos(t * 9 + k), 0, math.sin(t * 9 + k)) * (k * 0.25)
			rg.CFrame = CFrame.new(g + wob + Vector3.new(0, k * 4 * math.min(1, t * 4), 0)) * CFrame.Angles(0, t * 12 + k, math.rad(90))
		end
	end)
	Fx.burst("dust", g + Vector3.new(0, 1, 0), Color3.fromRGB(200, 220, 210), 30, 2.4)
	task.delay(1.1, function()
		blast(at, R, WIND, WHITE, 1.3)
	end)
	Fx.sound("swing", 1, 0.5, at)
end

------------------------------------------------------------------------
-- 초·벽력신권 구천뇌정 (초 오의): 천둥의 눈, 쏟아지는 벼락, 마지막 벼락 기둥
------------------------------------------------------------------------
local function thunderEye(data: any)
	local r = rootOf(data.m)
	if not r or not near(r.Position, 220) then
		return
	end
	local dur = data.dur or 3
	local e = Instance.new("ColorCorrectionEffect")
	e.Name = "KwonThunderEye"
	e.Parent = Lighting
	tween(e, 0.4, { Brightness = -0.2, Contrast = 0.35, Saturation = -0.3, TintColor = Color3.fromRGB(210, 200, 255) })
	task.delay(dur, function()
		tween(e, 0.5, { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = WHITE })
		task.delay(0.55, function()
			e:Destroy()
		end)
	end)
	-- 하늘의 천둥 눈: 먹구름 소용돌이 고리들 + 가운데 빛나는 눈
	local sky = r.Position + Vector3.new(0, 70, 0)
	local rings: { BasePart } = {}
	for k = 1, 6 do
		local d = 20 + k * 14
		table.insert(rings, part(Vector3.new(1.5, d, d), k % 2 == 0 and Color3.fromRGB(40, 35, 60) or Color3.fromRGB(70, 60, 100), Enum.Material.SmoothPlastic, 0.25, "cyl"))
	end
	local eye = part(Vector3.new(1, 18, 18), Color3.fromRGB(230, 220, 255), Enum.Material.Neon, 0.05, "cyl")
	local pupil = part(Vector3.new(1.2, 6, 14), VIOLET, Enum.Material.Neon, 0)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > dur then
			conn:Disconnect()
			for _, rg in ipairs(rings) do
				fadeOut(rg, 0.5)
			end
			fadeOut(eye, 0.4)
			fadeOut(pupil, 0.4)
			return
		end
		local open = math.clamp(t / 0.8, 0, 1)
		for k, rg in ipairs(rings) do
			rg.CFrame = CFrame.new(sky + Vector3.new(0, k * 1.5, 0)) * CFrame.Angles(0, t * (0.6 + k * 0.15) * (k % 2 == 0 and 1 or -1), math.rad(90))
		end
		eye.CFrame = CFrame.new(sky - Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
		eye.Size = Vector3.new(1, 18 * open, 18 * open)
		pupil.CFrame = CFrame.new(sky - Vector3.new(0, 1.5, 0))
		pupil.Size = Vector3.new(1.2, 0.2 + 1 * open, 14 * open)
		if math.random() < 0.15 then
			local a = math.random() * math.pi * 2
			Fx.lightning(sky + Vector3.new(math.cos(a) * 30, 0, math.sin(a) * 30), sky + Vector3.new(math.cos(a + 1) * 50, -10, math.sin(a + 1) * 50), Color3.fromRGB(220, 210, 255), 0.4)
		end
	end)
	Fx.sound("deflect", 1, 0.3, r.Position)
end
local function thunderRain(data: any)
	for _, at in ipairs(data.spots or {}) do
		if near(at, 200) then
			Fx.lightning(at + Vector3.new(math.random(-8, 8), 70, math.random(-8, 8)), at, math.random() < 0.4 and Color3.fromRGB(255, 245, 170) or VIOLET, 0.5)
			Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), VIOLET, 1, (data.radius or 6) * 2, 0.3)
		end
	end
	local first = (data.spots or {})[1]
	if first and math.random() < 0.5 then
		Fx.sound("deflect", 0.4, 1.6 + math.random() * 0.4, first)
	end
end
local function thunderPillar(data: any)
	local at: Vector3 = data.at
	local R = data.radius or 24
	local g = ground(at)
	local col = column(g, 200, R * 0.7, Color3.fromRGB(230, 220, 255), 0)
	fadeOut(col, 0.6, { Size = Vector3.new(220, R * 1.6, R * 1.6) })
	local outer = column(g, 200, R * 1.2, VIOLET, 0.5)
	fadeOut(outer, 0.7)
	for _ = 1, 8 do
		local a = math.random() * math.pi * 2
		local p = at + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(4, math.floor(R))
		Fx.lightning(at + Vector3.new(0, 6, 0), p, Color3.fromRGB(255, 245, 170), 0.6)
	end
	blast(at, R, VIOLET, Color3.fromRGB(255, 245, 170), 2)
	if near(at, 120) and opts.flash then
		opts.flash(WHITE, 0.6)
	end
	Fx.sound("shatter", 0.6, 0.5, at)
	Fx.sound("heavy", 1, 0.3, at)
	shakeNear(at, 2.6, 120)
end

------------------------------------------------------------------------
-- 초·벽력신권: 두 팔의 뇌전 토시 (Sakura가 부채와 같은 자리에서 부른다)
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
function Ult2.buildGauntlets(model: Model): { Instance }
	local out: { Instance } = {}
	local holder = Instance.new("Folder")
	holder.Name = "Thunder_" .. model.Name
	holder.Parent = folder
	table.insert(out, holder)
	local iron = Color3.fromRGB(45, 42, 60)
	for _, name in ipairs({ "RightLowerArm", "LeftLowerArm" }) do
		local arm = model:FindFirstChild(name)
		if arm and arm:IsA("BasePart") then
			local sz = arm.Size
			-- 쇠 토시: 팔뚝을 감싼 판 + 보랏빛 띠 셋 + 손목의 빛나는 고리
			attach(part(Vector3.new(sz.X + 0.22, sz.Y * 0.8, sz.Z + 0.22), iron, Enum.Material.Metal, 0), arm, CFrame.new(0, -sz.Y * 0.05, 0), holder, out)
			for k = -1, 1 do
				attach(part(Vector3.new(sz.X + 0.3, 0.12, sz.Z + 0.3), VIOLET, Enum.Material.Neon, 0), arm, CFrame.new(0, k * sz.Y * 0.25, 0), holder, out)
			end
			local cuff = part(Vector3.new(sz.X + 0.4, 0.22, sz.Z + 0.4), Color3.fromRGB(255, 245, 170), Enum.Material.Neon, 0)
			attach(cuff, arm, CFrame.new(0, -sz.Y * 0.45, 0), holder, out)
			-- 팔뚝 위로 솟은 뿔 같은 쇠 가시
			attach(part(Vector3.new(0.18, 0.18, 0.9), iron, Enum.Material.Metal, 0), arm, CFrame.new(0, sz.Y * 0.1, sz.Z * 0.5 + 0.35) * CFrame.Angles(math.rad(-30), 0, 0), holder, out)
			local a = Instance.new("Attachment")
			a.Parent = cuff
			local e = Instance.new("ParticleEmitter")
			e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			e.Color = ColorSequence.new(Color3.fromRGB(255, 245, 170), VIOLET)
			e.LightEmission = 1
			e.Rate = 10
			e.Lifetime = NumberRange.new(0.15, 0.35)
			e.Speed = NumberRange.new(3, 7)
			e.SpreadAngle = Vector2.new(180, 180)
			e.Size = NumberSequence.new(0.35, 0)
			e.Parent = a
			local l = Instance.new("PointLight")
			l.Color = VIOLET
			l.Range = 7
			l.Brightness = 0.9
			l.Parent = cuff
		end
	end
	return out
end
-- 토시를 두른 사람은 가끔 팔에서 손으로 작은 번개가 튄다
local sparkAcc = 0
RunService.Heartbeat:Connect(function(dt)
	sparkAcc += dt
	if sparkAcc < 0.35 then
		return
	end
	sparkAcc = 0
	for _, h in ipairs(folder:GetChildren()) do
		if h:IsA("Folder") and string.sub(h.Name, 1, 8) == "Thunder_" and math.random() < 0.5 then
			local cuffs = {}
			for _, p in ipairs(h:GetChildren()) do
				if p:IsA("BasePart") and p.Material == Enum.Material.Neon and p.Color.G > 0.9 then
					table.insert(cuffs, p)
				end
			end
			local c = cuffs[math.random(1, math.max(1, #cuffs))]
			if c and near(c.Position, 80) then
				Fx.lightning(c.Position, c.Position + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 4, VIOLET, 0.12)
			end
		end
	end
end)

-- 초 오의 구천뇌정의 컷씬 (쓴 사람 화면에서만, 대사 없이): 몸을 낮게 올려다보다가 하늘의 눈으로 고개를 든다
local cutActive = false
function Ult2.superCut(model: Model, dur: number, name: string, shake: ((number) -> ())?)
	local cam = workspace.CurrentCamera
	local r = rootOf(model)
	if not cam or not r or cutActive then
		return
	end
	cutActive = true
	local pg = player:WaitForChild("PlayerGui")
	local g = Instance.new("ScreenGui")
	g.Name = "KwonThunderCut"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 85
	g.Parent = pg
	local tintF = Instance.new("Frame")
	tintF.Size = UDim2.fromScale(1, 1)
	tintF.BackgroundColor3 = Color3.fromRGB(30, 20, 70)
	tintF.BackgroundTransparency = 1
	tintF.BorderSizePixel = 0
	tintF.Parent = g
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.35, 1), NumberSequenceKeypoint.new(0.65, 1), NumberSequenceKeypoint.new(1, 0.1) })
	grad.Parent = tintF
	tween(tintF, 0.3, { BackgroundTransparency = 0.35 })
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
	label.TextColor3 = Color3.fromRGB(255, 245, 170)
	label.TextStrokeColor3 = VIOLET
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
		RunService:UnbindFromRenderStep("KwonThunderCut")
		cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
		cam.FieldOfView = oldFov
		cutActive = false
		-- 컷씬이 끝나면 카메라를 내 등 뒤 조금 높은 곳으로 (앞에서 터지는 기술이 잘 보이게)
		local function behind()
			if r.Parent then
				local lk = flat(r.CFrame.LookVector)
				cam.CFrame = CFrame.lookAt(r.Position - lk * 15 + Vector3.new(0, 6, 0), r.Position + lk * 6 + Vector3.new(0, 1, 0))
			end
		end
		behind()
		task.defer(behind)
	end
	RunService:BindToRenderStep("KwonThunderCut", Enum.RenderPriority.Camera.Value, function(dt: number)
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
		-- 앞쪽 낮은 곳에서 올려다보다가, 끝으로 갈수록 하늘의 눈을 올려다본다
		local pos = focus + look * (6 - 4 * e) + side * 3 + Vector3.new(0, -1.5 + 1 * e, 0)
		local target = focus + Vector3.new(0, 2 + 60 * e, 0) - look * (2 * e)
		cam.CFrame = CFrame.lookAt(pos, target)
		cam.FieldOfView = oldFov - 18 + 30 * e
		if shake and u > 0.5 then
			shake(0.1 + (u - 0.5) * 0.8)
		end
		if math.random() < 0.08 then
			Fx.lightning(focus + Vector3.new(math.random(-20, 20), 60, math.random(-20, 20)), focus + Vector3.new(math.random(-12, 12), 0, math.random(-12, 12)), VIOLET, 0.4)
		end
	end)
	task.delay(dur, function()
		restore()
		for _, b in ipairs(bars) do
			tween(b, 0.18, { Size = UDim2.new(1, 0, 0, 0) })
		end
		tween(label, 0.15, { TextTransparency = 1, TextStrokeTransparency = 1 })
		grad:Destroy()
		tintF.BackgroundColor3 = Color3.fromRGB(240, 235, 255)
		tintF.BackgroundTransparency = 0.15
		tween(tintF, 0.35, { BackgroundTransparency = 1 })
		if shake then
			shake(1.4)
		end
		task.delay(0.5, function()
			g:Destroy()
		end)
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	dragonsRise = dragonsRise,
	dragonDive = dragonDive,
	dragonsEnd = dragonsEnd,
	lavaBurst = lavaBurst,
	bloodSea = bloodSea,
	bloodClaw = bloodClaw,
	bloodVortex = bloodVortex,
	netStart = netStart,
	netPulse = netPulse,
	netEnd = netEnd,
	armsStart = armsStart,
	armStrike = armStrike,
	darkStart = darkStart,
	killMark = killMark,
	killBurst = killBurst,
	shadowStomp = shadowStomp,
	maelstrom = maelstrom,
	maelstromEnd = maelstromEnd,
	abyss = abyss,
	abyssEnd = abyssEnd,
	galeBlades = galeBlades,
	galeShoot = galeShoot,
	galeTwister = galeTwister,
	thunderEye = thunderEye,
	thunderRain = thunderRain,
	thunderPillar = thunderPillar,
}
function Ult2.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil
end
function Ult2.run(data: any)
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

local _ = player
return Ult2
