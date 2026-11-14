-- 권왕 3.19판: 새 권법 열하나의 화면 연출
-- 철쇄금나수 (붙잡는 쇠사슬, 메치기, 던지기) · 역류반격권 (되받아치기 번쩍임, 역류) · 질풍연권 (잔상 돌진, 공중 연격, 내리꽂기)
-- 연타 장치: 서리 (빙혼) · 옥결 (천옥) · 종소리 (천종) · 거울 분신 (명경) · 용의 이빨 (초·천룡)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Arts = {}

local folder = Instance.new("Folder")
folder.Name = "KwonArts"
folder.Parent = workspace

local opts: any = {}
function Arts.init(o: any)
	opts = o or {}
end

local ICE = Color3.fromRGB(170, 225, 255)
local ICE2 = Color3.fromRGB(245, 252, 255)
local IRON = Color3.fromRGB(95, 100, 112)

local function styleOf(id: any): any
	return type(id) == "string" and Config.STYLE_BY_ID[id] or nil
end
local function colors(data: any): (Color3, Color3)
	local st = styleOf(data.style)
	return st and st.color or Color3.fromRGB(255, 230, 180), st and st.color2 or Color3.new(1, 1, 1)
end
local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
end
local function part(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, shape: string?): BasePart
	local q = Instance.new("Part")
	if shape == "ball" then
		q.Shape = Enum.PartType.Ball
	elseif shape == "cyl" then
		q.Shape = Enum.PartType.Cylinder
	elseif shape == "wedge" then
		q = Instance.new("WedgePart") :: any
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
local function rootOf(m: any): BasePart?
	local r = typeof(m) == "Instance" and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function handOf(m: Model): Vector3?
	local h = m:FindFirstChild("RightHand") or m:FindFirstChild("Right Arm") or m:FindFirstChild("RightLowerArm")
	if h and h:IsA("BasePart") then
		return h.Position
	end
	local r = rootOf(m)
	return r and (r.Position + r.CFrame.LookVector * 1.5) or nil
end
-- 땅에 눕힌 원판 (원기둥)
local function disc(at: Vector3, r: number, color: Color3, alpha: number, mat: Enum.Material?): BasePart
	local d = part(Vector3.new(0.2, r * 2, r * 2), color, mat or Enum.Material.Neon, alpha, "cyl")
	d.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	return d
end
-- 3.19.4판 화려함 도우미
-- 빛 가루를 한꺼번에 터뜨린다 (보이지 않는 점에 붙인 입자를 한 번에 뿜는다)
local function emitBurst(at: Vector3, c: Color3, n: number, speed: number, size: number, life: number)
	if not near(at, 220) then
		return
	end
	local holder = part(Vector3.new(0.2, 0.2, 0.2), c, Enum.Material.SmoothPlastic, 1)
	holder.Position = at
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(c)
	pe.LightEmission = 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new(0, 1)
	pe.Lifetime = NumberRange.new(life * 0.6, life)
	pe.Speed = NumberRange.new(speed * 0.5, speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = 3
	pe.Rate = 0
	pe.Parent = holder
	pe:Emit(n)
	task.delay(life + 0.1, function()
		holder:Destroy()
	end)
end
-- 부풀며 사라지는 빛 껍질 (안은 밝고 바깥은 옅게)
local function shell(at: Vector3, c: Color3, c2: Color3, r: number, life: number)
	local outer = part(Vector3.new(1, 1, 1), c, Enum.Material.Neon, 0.35, "ball")
	outer.Position = at
	fadeOut(outer, life, { Size = Vector3.new(r * 2, r * 2, r * 2) })
	local inner = part(Vector3.new(1, 1, 1), c2, Enum.Material.Neon, 0.05, "ball")
	inner.Position = at
	fadeOut(inner, life * 0.6, { Size = Vector3.new(r, r, r) })
end
-- 하늘로 치솟는 빛기둥 (가늘어지며)
local function column(at: Vector3, c: Color3, h: number, w: number, life: number)
	local col = part(Vector3.new(w, 1, w), c, Enum.Material.Neon, 0.1, "cyl")
	col.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	col.Size = Vector3.new(1, w, w)
	tween(col, life * 0.4, { Size = Vector3.new(h, w, w), CFrame = CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(life * 0.4, function()
		fadeOut(col, life * 0.6, { Size = Vector3.new(h * 1.1, 0.2, 0.2) })
	end)
end
local function lightAt(at: Vector3, c: Color3, range: number, life: number)
	local holder = part(Vector3.new(0.2, 0.2, 0.2), c, Enum.Material.SmoothPlastic, 1)
	holder.Position = at
	local l = Instance.new("PointLight")
	l.Color = c
	l.Range = range
	l.Brightness = 6
	l.Shadows = false
	l.Parent = holder
	tween(l, life, { Brightness = 0 })
	task.delay(life + 0.05, function()
		holder:Destroy()
	end)
end
-- 큰 한 방: 빛 껍질 · 빛 가루 · 빛 · 고리 세 겹 (크기 k)
local function boom(at: Vector3, c: Color3, c2: Color3, k: number)
	shell(at, c, c2, 6 * k, 0.45)
	emitBurst(at, c2, math.floor(20 * k), 30 * k, 0.9 * k, 0.7)
	emitBurst(at, c, math.floor(12 * k), 18 * k, 1.3 * k, 0.9)
	lightAt(at, c, 26 * k, 0.5)
	for i = 0, 2 do
		task.delay(i * 0.06, function()
			Fx.ring(at - Vector3.new(0, 1.5, 0), i == 1 and c2 or c, 1, (10 + i * 6) * k, 0.4 + i * 0.08)
		end)
	end
end
-- 땅이 꺼지는 충격 (메치기·내리꽂기)
local function crater(at: Vector3, radius: number, c: Color3, c2: Color3, power: number)
	local g = Vector3.new(at.X, at.Y - 2.4, at.Z)
	Fx.blast(g + Vector3.new(0, 1, 0), c, c2, math.clamp(radius / 8, 0.8, 2.4))
	Fx.ring(g + Vector3.new(0, 0.2, 0), c2, 1, radius * 2.2, 0.35)
	Fx.ring(g + Vector3.new(0, 0.3, 0), c, 1, radius * 1.4, 0.5)
	Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(175, 160, 140), 16, math.clamp(radius / 8, 0.8, 2))
	Fx.debris(g + Vector3.new(0, 0.5, 0), math.clamp(math.floor(radius), 5, 12), 16 * power, Color3.fromRGB(110, 100, 90))
	Fx.breakSound("boom", 0.6, 0.9, g)
	shakeNear(g, 0.5 * power, 90)
	-- 3.19.4판: 더 화려하게 (빛 껍질 · 빛 가루 · 빛, 크면 빛기둥까지)
	boom(g + Vector3.new(0, 1.2, 0), c, c2, math.clamp(radius / 9, 0.7, 2.4) * math.max(1, power * 0.7))
	if power >= 1.4 then
		column(g, c2, 30 * power, math.clamp(radius * 0.35, 2, 8), 0.7)
	end
	-- 3.19.5판: 가까이서 큰 한 방이 터지면 화면이 순간 다가선다
	if opts.fov and power >= 1.2 and near(g, 45) then
		opts.fov(-math.min(8, 3 * power), 0.3)
	end
end

-- 3.19.5판 리워크 도우미 ─────────────────────────────────────────────
-- 땅이 갈라진 금: 어두운 금 위로 빛나는 금이 바깥으로 뻗어 나간다
local function cracks(g: Vector3, R: number, n: number, glow: Color3, life: number)
	for k = 1, n do
		local a = k / n * math.pi * 2 + math.random() * 0.4
		local len = R * (0.55 + math.random() * 0.5)
		local cf = CFrame.new(g + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, a, 0)
		local dark = part(Vector3.new(0.6, 0.12, 0.2), Color3.fromRGB(35, 26, 20), Enum.Material.Slate, 0)
		dark.CFrame = cf
		tween(dark, 0.16, { Size = Vector3.new(0.6, 0.12, len), CFrame = cf * CFrame.new(0, 0, -len / 2) })
		local hot = part(Vector3.new(0.22, 0.14, 0.2), glow, Enum.Material.Neon, 0.05)
		hot.CFrame = cf
		tween(hot, 0.16, { Size = Vector3.new(0.22, 0.14, len * 0.95), CFrame = cf * CFrame.new(0, 0.01, -len / 2) })
		task.delay(life, function()
			fadeOut(dark, 0.5)
			fadeOut(hot, 0.3)
		end)
	end
end
-- 회오리: 높이마다 띠 셋이 돌며 위로 갈수록 넓어진다 (spin < 0 이면 거꾸로 돈다). follow가 있으면 그 몸을 따라간다
local function tornado(base: Vector3, R: number, H: number, c: Color3, c2: Color3, dur: number, follow: any, spin: number)
	local bands = {}
	local L = 5
	for lv = 1, L do
		for j = 1, 3 do
			local b = part(Vector3.new(0.35, 0.8 + lv * 0.12, R * 0.8), (lv + j) % 2 == 0 and c or c2, Enum.Material.Neon, 0.35)
			table.insert(bands, { p = b, lv = lv, j = j })
		end
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local el = os.clock() - t0
		local u = el / dur
		if u >= 1 then
			conn:Disconnect()
			for _, b in ipairs(bands) do
				fadeOut(b.p, 0.25)
			end
			return
		end
		local at = base
		local fr = follow and rootOf(follow)
		if fr then
			at = fr.Position - Vector3.new(0, 2.6, 0)
		end
		local grow = math.min(1, el / 0.2)
		for _, b in ipairs(bands) do
			local h = (b.lv - 0.5) / L * H * grow
			local rr = R * (0.35 + 0.65 * b.lv / L)
			local a = (el * (10 - b.lv) + b.j * 2.09 + b.lv * 0.7) * spin
			b.p.CFrame = CFrame.new(at + Vector3.new(0, h, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(rr, 0, 0)
			b.p.Transparency = 0.35 + math.max(0, u - 0.7) / 0.3 * 0.65
		end
	end)
end
-- 두 점 사이의 빛줄기 (가늘어지며 사라진다)
local function beamLine(a: Vector3, b: Vector3, w: number, c: Color3, alpha: number, life: number)
	local len = (b - a).Magnitude
	if len < 0.1 then
		return
	end
	local q = part(Vector3.new(w, w, len), c, Enum.Material.Neon, alpha)
	q.CFrame = CFrame.lookAt((a + b) / 2, b)
	fadeOut(q, life, { Size = Vector3.new(w * 0.1, w * 0.1, len) })
end
-- 초승달 바람 칼날: 조각 다섯이 활처럼 휘어 날아간다
local function crescent(at: Vector3, dir: Vector3, R: number, c: Color3, life: number, travel: number)
	local d = Vector3.new(dir.X, 0, dir.Z)
	d = d.Magnitude > 0.01 and d.Unit or Vector3.new(0, 0, -1)
	local base = CFrame.lookAt(at, at + d)
	for k = -2, 2 do
		local seg = part(Vector3.new(0.25, 0.9 - math.abs(k) * 0.15, R * 0.42), c, Enum.Material.Neon, 0.15 + math.abs(k) * 0.12)
		local cf = base * CFrame.Angles(0, k * 0.3, 0) * CFrame.new(0, 0, -R * 0.6) * CFrame.Angles(0, math.rad(90), 0)
		seg.CFrame = cf
		fadeOut(seg, life, { CFrame = cf + d * travel })
	end
end
-- 금종 (용뉴 · 어깨 · 몸통 · 띠 · 입술): 위아래로 쌓은 원기둥. place(cf)로 놓는다 (cf는 종의 한가운데)
local function makeBell(c: Color3, c2: Color3, s: number, alpha: number): ({ BasePart }, (CFrame) -> ())
	local specs = {
		{ y = 1.0, r = 0.16, h = 0.28, band = true },
		{ y = 0.84, r = 0.4, h = 0.1, band = false },
		{ y = 0.58, r = 0.46, h = 0.46, band = false },
		{ y = 0.24, r = 0.52, h = 0.26, band = true },
		{ y = 0.0, r = 0.57, h = 0.3, band = false },
		{ y = -0.2, r = 0.63, h = 0.14, band = false },
		{ y = -0.32, r = 0.7, h = 0.1, band = true },
	}
	local parts = {}
	for _, sp in ipairs(specs) do
		local q = part(Vector3.new(sp.h * s, sp.r * 2 * s, sp.r * 2 * s), sp.band and c2 or c, sp.band and Enum.Material.Neon or Enum.Material.Metal, sp.band and math.max(alpha, 0.15) or alpha, "cyl")
		table.insert(parts, q)
	end
	local function place(cf: CFrame)
		for i, sp in ipairs(specs) do
			parts[i].CFrame = cf * CFrame.new(0, sp.y * s, 0) * CFrame.Angles(0, 0, math.rad(90))
		end
	end
	return parts, place
end

------------------------------------------------------------------------
-- 철쇄금나수
------------------------------------------------------------------------
-- 손에서 적까지 쇠사슬 (고리 열둘이 늘어선다). 붙잡은 동안 따라 움직인다
local function grab(data: any)
	local m = data.m
	if typeof(m) ~= "Instance" then
		return
	end
	local c, c2 = colors(data)
	local chains = {}
	for _, t in ipairs(data.targets or {}) do
		local links = {}
		for i = 1, 12 do
			local l = part(Vector3.new(0.35, 0.35, 0.9), i % 2 == 0 and IRON or IRON:Lerp(c2, 0.25), Enum.Material.Metal, 0)
			table.insert(links, l)
		end
		-- 3.19.5판: 사슬 끝의 쇠고리가 적의 허리를 감는다
		local cuff = part(Vector3.new(0.4, 3.4, 3.4), IRON:Lerp(c2, 0.4), Enum.Material.Metal, 0, "cyl")
		table.insert(chains, { t = t, links = links, cuff = cuff })
		local r = rootOf(t)
		if r then
			Fx.spark(r.Position, c2, 1.2, 8)
			emitBurst(r.Position, c2, 10, 16, 0.5, 0.4)
		end
	end
	local mr = rootOf(m)
	Fx.sound("block", 0.5, 0.7, mr and mr.Position or nil)
	local total = (data.reel or 0.2) + (data.hold or 0.3)
	local t0 = os.clock()
	local whirl: BasePart? = nil
	if data.mode == "spin" then
		local r = rootOf(m)
		if r then
			whirl = disc(r.Position - Vector3.new(0, 2.6, 0), (data.orbit or 7) + 3, c, 0.75)
			-- 휘돌리는 동안 쇠빛 회오리가 몸을 감싼다
			tornado(r.Position - Vector3.new(0, 2.6, 0), (data.orbit or 7) + 2, 7, IRON:Lerp(c2, 0.3), c2, total, m, 1)
		end
	end
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local el = os.clock() - t0
		local from = handOf(m :: any)
		for _, ch in ipairs(chains) do
			local r = rootOf(ch.t)
			if from and r then
				local to = r.Position
				-- 끌어당기는 동안 사슬이 출렁인다
				local sag = el < (data.reel or 0.2) and 1.2 or 0.3
				for i, l in ipairs(ch.links) do
					local u = i / (#ch.links + 1)
					local p = from:Lerp(to, u) - Vector3.new(0, math.sin(u * math.pi) * sag, 0)
					local q = from:Lerp(to, u + 0.04)
					l.CFrame = CFrame.lookAt(p, q) * CFrame.Angles(0, 0, (i % 2) * math.rad(90))
				end
				ch.cuff.CFrame = CFrame.new(to) * CFrame.Angles(0, el * 8, math.rad(90))
			end
		end
		local rm = rootOf(m)
		if whirl and rm then
			whirl.CFrame = CFrame.new(rm.Position - Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, el * 12, math.rad(90))
			if math.random() < 0.3 then
				Fx.burst("dust", rm.Position - Vector3.new(0, 2.4, 0), Color3.fromRGB(190, 180, 165), 2, 1)
			end
		end
		if el > total or not m.Parent then
			conn:Disconnect()
			for _, ch in ipairs(chains) do
				for _, l in ipairs(ch.links) do
					fadeOut(l, 0.2)
				end
				fadeOut(ch.cuff, 0.2, { Size = Vector3.new(0.4, 5, 5) })
			end
			if whirl then
				fadeOut(whirl, 0.3)
			end
		end
	end)
end
local function grabMiss(data: any)
	local c, _ = colors(data)
	Fx.ring(data.at, c, 1, 6, 0.25)
	Fx.sound("swing", 0.4, 0.8, data.at)
end
local function grabSlam(data: any)
	local c, c2 = colors(data)
	local R = data.radius or 8
	crater(data.at, R, c, c2, 1.2)
	-- 3.19.5판: 메친 자리가 쩍 갈라지고 끊어진 쇠사슬 고리가 튄다
	local g = data.at - Vector3.new(0, 2.5, 0)
	cracks(g, R * 1.4, 9, Color3.fromRGB(255, 190, 120), 0.9)
	for _ = 1, 6 do
		local l = part(Vector3.new(0.4, 0.4, 1), IRON, Enum.Material.Metal, 0)
		l.CFrame = CFrame.new(g + Vector3.new(0, 1, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		local d = Vector3.new(math.random() - 0.5, 0.8 + math.random(), math.random() - 0.5) * 9
		fadeOut(l, 0.6, { CFrame = l.CFrame * CFrame.Angles(3, 2, 0) + d })
	end
	Fx.sound("block", 0.7, 0.6, data.at)
end
-- 날아가는 적 뒤에 남는 바람 줄
local function grabFly(data: any)
	local t = data.t
	local c, c2 = colors(data)
	local t0 = os.clock()
	local last: Vector3? = nil
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local r = rootOf(t)
		if not r or os.clock() - t0 > (data.dur or 0.6) then
			conn:Disconnect()
			return
		end
		local p = r.Position
		if last and (p - last).Magnitude > 1.5 then
			local seg = part(Vector3.new(0.5, 0.5, (p - last).Magnitude), c2, Enum.Material.Neon, 0.35)
			seg.CFrame = CFrame.lookAt((p + last) / 2, p)
			fadeOut(seg, 0.35, { Size = Vector3.new(0.1, 0.1, seg.Size.Z) })
			if math.random() < 0.4 then
				Fx.burst("spark", p, c, 2, 0.8)
			end
		end
		last = p
	end)
end

------------------------------------------------------------------------
-- 역류반격권 (명경권의 받아치기도)
------------------------------------------------------------------------
local function counterFlash(data: any)
	local m = data.m
	local c, c2 = colors(data)
	local r = rootOf(m)
	if not r then
		return
	end
	Fx.afterimage(m, c, 0.4)
	Fx.flash(r.Position, c2, 26, 5, 0.25)
	local look = r.CFrame.LookVector
	if data.style == "myeonggyeong" then
		-- 3.19.5판 명경: 내 앞에 거울이 번쩍 섰다가, 받은 힘을 되비추며 산산이 깨진다
		local pane = part(Vector3.new(4.6, 6.6, 0.2), c2, Enum.Material.Glass, 0.2)
		pane.Reflectance = 0.7
		pane.CFrame = CFrame.lookAt(r.Position + look * 2.2, r.Position + look * 5)
		local rim = part(Vector3.new(5, 7, 0.1), c, Enum.Material.Neon, 0.3)
		rim.CFrame = pane.CFrame * CFrame.new(0, 0, 0.12)
		task.delay(0.12, function()
			for _ = 1, 12 do
				local sh = part(Vector3.new(0.9, 1.3, 0.1), c2, Enum.Material.Glass, 0.25, "wedge")
				sh.Reflectance = 0.6
				sh.CFrame = pane.CFrame * CFrame.new((math.random() - 0.5) * 4, (math.random() - 0.5) * 6, 0) * CFrame.Angles(0, 0, math.random() * 6)
				fadeOut(sh, 0.55, { CFrame = sh.CFrame + (look * (6 + math.random() * 6) + Vector3.new(math.random() - 0.5, math.random(), math.random() - 0.5) * 6) })
			end
			beamLine(r.Position + look * 2, r.Position + look * 14, 1.6, c2, 0.1, 0.3)
			pane:Destroy()
			rim:Destroy()
		end)
		Fx.breakSound("glass", 0.8, 1.5, r.Position)
		emitBurst(r.Position + look * 2, c2, 26, 30, 0.8, 0.5)
	else
		-- 역류: 발밑에서 물기둥이 몸을 감싸 솟았다가 바깥으로 무너진다
		local feet = r.Position - Vector3.new(0, 2.6, 0)
		local col = part(Vector3.new(0.5, 6, 6), c, Enum.Material.Glass, 0.45, "cyl")
		col.CFrame = CFrame.new(feet) * CFrame.Angles(0, 0, math.rad(90))
		tween(col, 0.12, { Size = Vector3.new(9, 6, 6), CFrame = CFrame.new(feet + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, math.rad(90)) }, Enum.EasingStyle.Back)
		task.delay(0.16, function()
			fadeOut(col, 0.35, { Size = Vector3.new(2, 16, 16), CFrame = CFrame.new(feet + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
		end)
		Fx.ring(r.Position, c2, 1, 12, 0.3, look)
		Fx.ring(r.Position, c, 2, 18, 0.45)
		emitBurst(r.Position, c2, 24, 26, 0.7, 0.6)
		boom(r.Position, c, c2, 1)
	end
	Fx.sound("deflect", 0.8, 1.3, r.Position)
	if opts.flash and near(r.Position, 40) then
		opts.flash(c2, 0.25)
	end
	shakeNear(r.Position, 0.35, 60)
end
-- 둘레로 퍼지는 역류 (물결 두 겹, 물방울)
local function counterBurst(data: any)
	local c, c2 = colors(data)
	local at, R = data.at, data.radius or 14
	local g = at - Vector3.new(0, 2.5, 0)
	if data.style == "myeonggyeong" then
		-- 3.19.5판 명경: 거울 조각이 둘레로 폭풍처럼 튄다
		for k = 1, 16 do
			local a = k / 16 * math.pi * 2
			local sh = part(Vector3.new(1, 1.6, 0.12), c2, Enum.Material.Glass, 0.2, "wedge")
			sh.Reflectance = 0.6
			sh.CFrame = CFrame.new(at) * CFrame.Angles(0, a, 0) * CFrame.Angles(math.random(), 0, math.random() * 6)
			fadeOut(sh, 0.5, { CFrame = sh.CFrame + Vector3.new(math.cos(a), 0.2, math.sin(a)) * R })
		end
	else
		-- 역류: 안으로 감겨 드는 소용돌이, 그 한가운데서 물기둥이 하늘로 터진다
		tornado(g, R * 0.7, 3.5, c, c2, 0.45, nil, -1)
		task.delay(0.2, function()
			column(g, c2, 26, 3, 0.7)
			column(g, c, 20, 6, 0.6)
			emitBurst(at + Vector3.new(0, 6, 0), c2, 30, 30, 0.9, 0.9)
		end)
	end
	for k = 0, 2 do
		task.delay(k * 0.08, function()
			local w = disc(g + Vector3.new(0, 0.2 + k * 0.1, 0), 1, k == 1 and c2 or c, 0.35)
			tween(w, 0.45, { Size = Vector3.new(0.2, R * 2 * (1 - k * 0.12), R * 2 * (1 - k * 0.12)) })
			fadeOut(w, 0.6)
		end)
	end
	Fx.burst("glitter", at, c2, 20, 1.6)
	Fx.burst("spark", at, c, 16, 1.4)
	boom(at, c, c2, math.clamp(R / 10, 1, 2))
	Fx.sound("splash", 0.6, 1.2, at)
	shakeNear(at, 0.5, 80)
end

------------------------------------------------------------------------
-- 질풍연권 (천하패권의 돌진도)
------------------------------------------------------------------------
local function rushDash(data: any)
	local m = data.m
	local c, c2 = colors(data)
	local a, b = data.from, data.to
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
		return
	end
	if typeof(m) == "Instance" and m:IsA("Model") then
		Fx.afterimage(m, c, 0.35)
	end
	local len = (b - a).Magnitude
	if len > 1 then
		local streak = part(Vector3.new(1.2, 1.2, len), c2, Enum.Material.Neon, 0.25)
		streak.CFrame = CFrame.lookAt((a + b) / 2, b)
		fadeOut(streak, 0.3, { Size = Vector3.new(0.1, 0.1, len) })
		local streak2 = part(Vector3.new(2.6, 2.6, len), c, Enum.Material.Neon, 0.7)
		streak2.CFrame = streak.CFrame
		fadeOut(streak2, 0.25, { Size = Vector3.new(0.2, 0.2, len) })
	end
	Fx.ring(b, c2, 1, 9, 0.25, (b - a).Unit)
	-- 3.19.5판: 파고든 자리에서 바람 칼날이 앞으로 베어 나간다 (번갈아 기울어진다)
	crescent(b + Vector3.new(0, ((data.i or 1) % 2 == 0) and 0.6 or -0.6, 0), b - a, 7, c2, 0.3, 9)
	Fx.burst("spark", b, c, 10, 1.1)
	emitBurst(b, c2, 16, 26, 0.7, 0.5)
	lightAt(b, c, 18, 0.3)
	Fx.sound("swing", 0.6, 1.3 + (data.i or 1) * 0.05, b)
	shakeNear(b, 0.2, 50)
end
local function rushAir(data: any)
	local t = data.t
	local c, c2 = colors(data)
	local r = rootOf(t)
	if not r then
		return
	end
	local m = data.m
	if typeof(m) == "Instance" and m:IsA("Model") then
		Fx.afterimage(m, c2, 0.25)
	end
	Fx.ring(r.Position, c2, 1, 8, 0.2)
	Fx.spark(r.Position, c, 1.6, 10)
	shell(r.Position, c, c2, 4, 0.3)
	emitBurst(r.Position, c2, 14, 24, 0.6, 0.45)
	Fx.sound("hit", 0.6, 1.2 + (data.k or 1) * 0.08, r.Position)
end
local function rushSlam(data: any)
	local c, c2 = colors(data)
	crater(data.at, data.radius or 8, c, c2, 1)
	-- 3.19.5판: 내리꽂은 자리에서 바람 칼날 여덟이 바깥으로 갈라져 나간다
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		crescent(data.at - Vector3.new(0, 1.6, 0), Vector3.new(math.cos(a), 0, math.sin(a)), 5, k % 2 == 0 and c2 or c, 0.4, 12)
	end
end
local function rushBurst(data: any)
	local c, c2 = colors(data)
	local at, R = data.at, data.radius or 12
	Fx.blast(at, c, c2, math.clamp(R / 8, 1, 2.4))
	Fx.ring(at - Vector3.new(0, 2.3, 0), c2, 1, R * 2.2, 0.4)
	-- 3.19.5판: 한가운데서 하늘까지 닿는 회오리가 솟고 바람 칼날 열둘이 사방으로 베어 나간다
	tornado(at - Vector3.new(0, 2.6, 0), R * 0.7, 26, c, c2, 0.9, nil, 1)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		crescent(at - Vector3.new(0, 1, 0), Vector3.new(math.cos(a), 0, math.sin(a)), 7, k % 2 == 0 and c2 or c, 0.45, R * 1.2)
	end
	emitBurst(at + Vector3.new(0, 4, 0), c2, 40, 40, 1, 0.8)
	Fx.sound("swing", 0.9, 0.8, at)
	shakeNear(at, 0.6, 80)
end

------------------------------------------------------------------------
-- 얼음 (빙혼): 적을 얼음에 가둔다
------------------------------------------------------------------------
local function iceCage(model: Model, dur: number)
	local r = rootOf(model)
	if not r then
		return
	end
	local ok, cf, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if not ok then
		cf, size = r.CFrame, Vector3.new(4, 6, 4)
	end
	local block = part(size + Vector3.new(1.2, 1, 1.2), ICE, Enum.Material.Glass, 0.45)
	block.CFrame = cf
	local shell = part(size + Vector3.new(1.6, 1.4, 1.6), ICE2, Enum.Material.Ice, 0.75)
	shell.CFrame = cf
	block.Size = Vector3.new(0.5, 0.5, 0.5)
	tween(block, 0.15, { Size = size + Vector3.new(1.2, 1, 1.2) })
	task.delay(dur, function()
		local at = block.Position
		Fx.breakSound("glass", 0.6, 1.1, at)
		for _ = 1, 8 do
			local s = part(Vector3.new(1, 1, 1) * (0.4 + math.random() * 0.8), ICE, Enum.Material.Glass, 0.3, "wedge")
			s.CFrame = CFrame.new(at + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * size) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
			fadeOut(s, 0.5, { CFrame = s.CFrame + Vector3.new(math.random() - 0.5, 0.6, math.random() - 0.5) * 6 })
		end
		block:Destroy()
		shell:Destroy()
	end)
end

------------------------------------------------------------------------
-- 연타 장치 (네·다섯 번째 맞힐 때 상대 자리에서 터진다)
------------------------------------------------------------------------
local function pulseFrost(data: any)
	local at, R = data.at, data.radius or 9
	task.delay(data.delay or 0.25, function()
		local g = at - Vector3.new(0, 2.5, 0)
		local fr = disc(g + Vector3.new(0, 0.15, 0), 1, ICE2, 0.3, Enum.Material.Ice)
		tween(fr, 0.2, { Size = Vector3.new(0.2, R * 2, R * 2) })
		fadeOut(fr, 0.9)
		-- 얼음 가시가 사방으로 솟는다
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			local p = g + Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.55
			local spike = part(Vector3.new(1.2, 0.2, 1.2), ICE, Enum.Material.Glass, 0.25, "wedge")
			spike.CFrame = CFrame.lookAt(p, at + Vector3.new(0, 4, 0))
			tween(spike, 0.12, { Size = Vector3.new(1.2, R * 0.5, 1.6) })
			task.delay(0.5, function()
				fadeOut(spike, 0.3)
			end)
		end
		Fx.burst("glitter", at, ICE2, 14, 1.3)
		Fx.breakSound("glass", 0.5, 1.3, at)
	end)
end
local function pulseJade(data: any)
	local c, c2 = colors(data)
	local at, R = data.at, data.radius or 10
	task.delay(data.delay or 0.3, function()
		local g = at - Vector3.new(0, 2.6, 0)
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2 + math.random() * 0.4
			local p = g + Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.4
			local h = R * (0.5 + math.random() * 0.4)
			local cr = part(Vector3.new(1.4, 0.2, 1.4), c, Enum.Material.Glass, 0.15)
			cr.CFrame = CFrame.new(p) * CFrame.Angles(math.rad(math.cos(a) * 20), a, math.rad(math.sin(a) * 20))
			tween(cr, 0.12, { Size = Vector3.new(1.4, h, 1.4), CFrame = cr.CFrame * CFrame.new(0, h / 2, 0) })
			task.delay(0.45, function()
				fadeOut(cr, 0.35)
			end)
		end
		Fx.flash(at, c2, 30, 4, 0.3)
		Fx.burst("glitter", at, c2, 16, 1.3)
		Fx.breakSound("glass", 0.5, 1.6, at)
	end)
end
-- 종소리: 금빛 종이 잠깐 비치고 울림 고리가 세 겹 퍼진다
local function pulseBell(data: any)
	local c, c2 = colors(data)
	local at, R = data.at, data.radius or 12
	task.delay(data.delay or 0.2, function()
		local bell = part(Vector3.new(5, 5, 5), c, Enum.Material.Neon, 0.55, "ball")
		bell.CFrame = CFrame.new(at + Vector3.new(0, 7, 0))
		local rim = part(Vector3.new(1, 7, 7), c2, Enum.Material.Neon, 0.5, "cyl")
		rim.CFrame = CFrame.new(at + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		fadeOut(bell, 0.6, { Size = Vector3.new(8, 8, 8) })
		fadeOut(rim, 0.6, { Size = Vector3.new(1, 10, 10) })
		for k = 0, 2 do
			task.delay(k * 0.12, function()
				Fx.ring(at, k == 1 and c2 or c, 2, R * 2.4, 0.5)
			end)
		end
		Fx.sound("ping", 0.9, 0.55, at)
		shakeNear(at, 0.35, 70)
	end)
end
-- 거울 분신: 상대 앞에 거울이 서고 나의 잔상이 거울에서 튀어나와 친 뒤 거울이 깨진다
local function pulseMirror(data: any)
	local c, c2 = colors(data)
	local at = data.at
	local pane = part(Vector3.new(4, 6, 0.2), c2, Enum.Material.Glass, 0.35)
	local cam = workspace.CurrentCamera
	local face = cam and Vector3.new(cam.CFrame.Position.X, at.Y, cam.CFrame.Position.Z) or at + Vector3.new(0, 0, 1)
	pane.CFrame = CFrame.lookAt(at + Vector3.new(0, 1, 0), face + Vector3.new(0, 1, 0))
	local edge = part(Vector3.new(4.4, 6.4, 0.1), c, Enum.Material.Neon, 0.5)
	edge.CFrame = pane.CFrame * CFrame.new(0, 0, 0.12)
	task.delay(data.delay or 0.35, function()
		Fx.flash(at, c2, 26, 4, 0.25)
		Fx.burst("glitter", at, c2, 18, 1.2)
		for _ = 1, 8 do
			local sh = part(Vector3.new(0.9, 1.2, 0.1), c2, Enum.Material.Glass, 0.3, "wedge")
			sh.CFrame = pane.CFrame * CFrame.new((math.random() - 0.5) * 3, (math.random() - 0.5) * 5, 0) * CFrame.Angles(0, 0, math.random() * 6)
			fadeOut(sh, 0.5, { CFrame = sh.CFrame + Vector3.new(math.random() - 0.5, math.random() * 0.6, math.random() - 0.5) * 8 })
		end
		pane:Destroy()
		edge:Destroy()
		Fx.breakSound("glass", 0.6, 1.4, at)
	end)
end
-- 용의 이빨: 금빛 턱 두 개가 위아래에서 물어뜯는다
local function pulseDragon(data: any)
	local c, c2 = colors(data)
	local at = data.at
	local up = part(Vector3.new(5, 1, 3), c, Enum.Material.Neon, 0.25, "wedge")
	local dn = part(Vector3.new(5, 1, 3), c, Enum.Material.Neon, 0.25, "wedge")
	up.CFrame = CFrame.new(at + Vector3.new(0, 5, 0)) * CFrame.Angles(math.rad(180), 0, 0)
	dn.CFrame = CFrame.new(at - Vector3.new(0, 3, 0))
	tween(up, data.delay or 0.3, { CFrame = CFrame.new(at + Vector3.new(0, 1.2, 0)) * CFrame.Angles(math.rad(180), 0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	tween(dn, data.delay or 0.3, { CFrame = CFrame.new(at + Vector3.new(0, 0.2, 0)) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.delay(data.delay or 0.3, function()
		Fx.blast(at, c, c2, 1.2)
		Fx.burst("spark", at, c2, 14, 1.2)
		fadeOut(up, 0.25)
		fadeOut(dn, 0.25)
		Fx.breakSound("boom", 0.5, 1.2, at)
	end)
end
local PULSE: { [string]: (any) -> () } = { frost = pulseFrost, jade = pulseJade, bell = pulseBell, mirror = pulseMirror, dragonBite = pulseDragon }


------------------------------------------------------------------------
-- 3.19.1판: 새 권법 기술의 고유 모습 (예전엔 모든 권법이 같은 빛기둥·빛 원을 빛깔만 바꿔 썼다)
--   땅에서 솟는 것 (pillar): 얼음 가시 · 바위 판 · 옥 결정
--   하늘에서 꽂히는 것 (strike·drop): 얼음 기둥 · 옥 덩이 · 거울 빛 · 집채만 한 바위
--   넓게 펼쳐지는 것 (zone·cone): 옥의 숲 · 금빛 종 · 종소리 물결
------------------------------------------------------------------------
local ROCK = Color3.fromRGB(150, 115, 85)
local function groundAt(at: Vector3): Vector3
	return Vector3.new(at.X, at.Y - 2.6, at.Z)
end
-- 땅에서 솟았다가 잠시 뒤 꺼진다 (shatter = 깨진다)
local function rise(p: BasePart, toCF: CFrame, toSize: Vector3, life: number, shatter: boolean?)
	tween(p, 0.1, { CFrame = toCF, Size = toSize }, Enum.EasingStyle.Back)
	task.delay(life, function()
		if not p.Parent then
			return
		end
		if shatter then
			local at = p.Position
			for _ = 1, 5 do
				local sh = part(Vector3.new(0.6, 0.9, 0.6) * (0.6 + math.random()), p.Color, p.Material, 0.2, "wedge")
				sh.CFrame = CFrame.new(at + Vector3.new(math.random() - 0.5, math.random() * toSize.Y * 0.8 - toSize.Y * 0.4, math.random() - 0.5)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
				fadeOut(sh, 0.45, { CFrame = sh.CFrame + Vector3.new(math.random() - 0.5, 0.5, math.random() - 0.5) * 7 })
			end
			p:Destroy()
		else
			fadeOut(p, 0.35, { CFrame = p.CFrame - Vector3.new(0, toSize.Y * 0.5, 0) })
		end
	end)
end
local function pillarIce(data: any)
	local g, R = groundAt(data.at), data.radius or 5
	local h = R * 2.2
	for k = 0, 2 do
		local a = k * 2.1 + (data.i or 0)
		local off = k == 0 and Vector3.zero or Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.45
		local hh = k == 0 and h or h * 0.6
		local spike = part(Vector3.new(R * 0.5, 0.2, R * 0.5), k == 0 and ICE or ICE2, Enum.Material.Glass, 0.2)
		local tilt = CFrame.Angles(k == 0 and 0 or math.rad(12) * math.cos(a), math.rad(45), k == 0 and 0 or math.rad(12) * math.sin(a))
		spike.CFrame = CFrame.new(g + off) * tilt
		rise(spike, CFrame.new(g + off + Vector3.new(0, hh / 2, 0)) * tilt, Vector3.new(R * (k == 0 and 0.75 or 0.45), hh, R * (k == 0 and 0.75 or 0.45)), 0.55, true)
	end
	local frost = disc(g + Vector3.new(0, 0.15, 0), 1, ICE2, 0.35, Enum.Material.Ice)
	tween(frost, 0.15, { Size = Vector3.new(0.2, R * 2.4, R * 2.4) })
	fadeOut(frost, 0.9)
	Fx.burst("glitter", g + Vector3.new(0, 1.5, 0), ICE2, 8, 1)
	if (data.i or 1) % 2 == 1 then
		Fx.breakSound("glass", 0.45, 1.2 + (data.i or 1) * 0.04, g)
	end
end
local function pillarRock(data: any)
	local g, R = groundAt(data.at), data.radius or 5
	local h = R * 1.8
	local dir = typeof(data.dir) == "Vector3" and data.dir or Vector3.new(0, 0, -1)
	local slab = part(Vector3.new(R * 1.3, 0.2, R * 0.9), ROCK:Lerp(Color3.fromRGB(110, 85, 65), math.random()), Enum.Material.Slate, 0)
	local cf = CFrame.lookAt(g, g + dir) * CFrame.Angles(math.rad(-25), math.random() * 0.4 - 0.2, 0)
	slab.CFrame = cf
	rise(slab, cf * CFrame.new(0, h / 2, 0), Vector3.new(R * 1.3, h, R * 0.9), 0.6, false)
	Fx.burst("dust", g + Vector3.new(0, 0.6, 0), Color3.fromRGB(180, 160, 130), 10, R / 5)
	Fx.debris(g + Vector3.new(0, 0.6, 0), 4, 12, ROCK)
	Fx.breakSound("rock", 0.5, 0.9 + math.random() * 0.2, g)
	shakeNear(g, 0.25, 60)
end
local function crystalCluster(g: Vector3, R: number, c: Color3, c2: Color3, life: number)
	for k = 0, 3 do
		local a = k * 1.7 + math.random()
		local off = k == 0 and Vector3.zero or Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.4
		local hh = (k == 0 and 2.2 or 1.4) * R * (0.8 + math.random() * 0.3)
		local tilt = CFrame.Angles(k == 0 and 0 or math.rad(18) * math.cos(a), math.rad(45) + a, k == 0 and 0 or math.rad(18) * math.sin(a))
		local shell = part(Vector3.new(0.4, 0.2, 0.4), c, Enum.Material.Glass, 0.15)
		shell.CFrame = CFrame.new(g + off) * tilt
		local core = part(Vector3.new(0.2, 0.2, 0.2), c2, Enum.Material.Neon, 0.1)
		core.CFrame = shell.CFrame
		local w = R * (k == 0 and 0.6 or 0.4)
		rise(shell, CFrame.new(g + off) * tilt * CFrame.new(0, hh / 2, 0), Vector3.new(w, hh, w), life, true)
		rise(core, CFrame.new(g + off) * tilt * CFrame.new(0, hh / 2, 0), Vector3.new(w * 0.45, hh * 0.9, w * 0.45), life, false)
	end
end
local function pillarCrystal(data: any)
	local c, c2 = colors(data)
	local g, R = groundAt(data.at), data.radius or 5
	crystalCluster(g, R, c, c2, 0.6)
	Fx.flash(g + Vector3.new(0, 3, 0), c2, 18, 3, 0.2)
	if (data.i or 1) % 2 == 1 then
		Fx.breakSound("glass", 0.4, 1.6, g)
	end
end
-- 하늘에서 떨어져 꽂히는 것: 긴 몸이 0.14초 만에 내려와 땅에 박힌다
local function fallInto(p: BasePart, g: Vector3, len: number, then_: () -> ())
	p.CFrame = CFrame.new(g + Vector3.new(0, 40 + len / 2, 0)) * CFrame.Angles(0, math.random() * 6, 0)
	tween(p, 0.14, { CFrame = CFrame.new(g + Vector3.new(0, len / 2 - 1, 0)) * CFrame.Angles(0, math.random() * 6, 0) }, Enum.EasingStyle.Linear)
	task.delay(0.14, then_)
end
local function strikeIce(data: any)
	local g, R = groundAt(data.at), data.radius or 7
	local len = R * 3
	local col = part(Vector3.new(R * 0.8, len, R * 0.8), ICE, Enum.Material.Glass, 0.2)
	local core = part(Vector3.new(R * 0.35, len * 0.95, R * 0.35), ICE2, Enum.Material.Neon, 0.3)
	fallInto(col, g, len, function()
		core.CFrame = col.CFrame
		Fx.ring(g + Vector3.new(0, 0.3, 0), ICE2, 1, R * 2.6, 0.4)
		Fx.burst("glitter", g + Vector3.new(0, 1, 0), ICE2, 14, 1.4)
		Fx.breakSound("glass", 0.6, 0.9, g)
		shakeNear(g, 0.35, 70)
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			local sp = part(Vector3.new(R * 0.3, 0.2, R * 0.3), ICE, Enum.Material.Glass, 0.25, "wedge")
			local cf = CFrame.lookAt(g + Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.7, g + Vector3.new(0, R, 0))
			sp.CFrame = cf
			rise(sp, cf * CFrame.new(0, R * 0.5, 0), Vector3.new(R * 0.3, R, R * 0.4), 0.5, true)
		end
		task.delay(0.6, function()
			if col.Parent then
				rise(col, col.CFrame, col.Size, 0, true)
			end
			fadeOut(core, 0.2)
		end)
	end)
end
local function strikeCrystal(data: any)
	local c, c2 = colors(data)
	local g, R = groundAt(data.at), data.radius or 7
	local gem = part(Vector3.new(R * 0.9, R * 1.4, R * 0.9), c, Enum.Material.Glass, 0.15)
	fallInto(gem, g, R * 1.4, function()
		gem.CFrame = CFrame.new(g + Vector3.new(0, R * 0.6, 0)) * CFrame.Angles(math.rad(45), math.rad(45), 0)
		crystalCluster(g, R * 0.8, c, c2, 0.5)
		Fx.flash(g + Vector3.new(0, 2, 0), c2, 30, 4, 0.25)
		Fx.ring(g + Vector3.new(0, 0.3, 0), c2, 1, R * 2.4, 0.4)
		Fx.burst("glitter", g + Vector3.new(0, 1.5, 0), c2, 14, 1.3)
		Fx.breakSound("glass", 0.55, 1.4, g)
		shakeNear(g, 0.3, 60)
		rise(gem, gem.CFrame, gem.Size, 0.25, true)
	end)
end
local function strikeMirror(data: any)
	local c, c2 = colors(data)
	local g, R = groundAt(data.at), data.radius or 6
	local top = g + Vector3.new(0, 16, 0)
	local pane = part(Vector3.new(R * 0.9, R * 0.9, 0.2), c2, Enum.Material.Glass, 0.3)
	pane.Reflectance = 0.6
	pane.CFrame = CFrame.lookAt(top, g) * CFrame.Angles(0, 0, math.rad(45))
	pane.Size = Vector3.new(0.2, 0.2, 0.2)
	tween(pane, 0.1, { Size = Vector3.new(R * 0.9, R * 0.9, 0.2) })
	task.delay(0.12, function()
		local beam = part(Vector3.new(R * 0.5, 16, R * 0.5), c2, Enum.Material.Neon, 0.2)
		beam.CFrame = CFrame.new(g + Vector3.new(0, 8, 0))
		fadeOut(beam, 0.3, { Size = Vector3.new(0.1, 16, 0.1) })
		Fx.flash(g + Vector3.new(0, 2, 0), c2, 26, 4, 0.2)
		Fx.ring(g + Vector3.new(0, 0.3, 0), c, 1, R * 2.2, 0.35)
		Fx.burst("glitter", g + Vector3.new(0, 1, 0), c2, 12, 1.2)
		rise(pane, pane.CFrame, pane.Size, 0, true)
		Fx.breakSound("glass", 0.45, 1.5, g)
	end)
end
local function dropRock(data: any)
	local g, R = groundAt(data.at), data.radius or 10
	local rock = part(Vector3.new(R * 1.3, R * 1.1, R * 1.2), ROCK, Enum.Material.Rock, 0)
	local chip = part(Vector3.new(R * 0.7, R * 0.6, R * 0.8), ROCK:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Rock, 0)
	rock.CFrame = CFrame.new(g + Vector3.new(0, 60, 0)) * CFrame.Angles(0.4, 0.8, 0.2)
	chip.CFrame = rock.CFrame * CFrame.new(R * 0.5, R * 0.3, 0)
	tween(rock, 0.22, { CFrame = CFrame.new(g + Vector3.new(0, R * 0.35, 0)) * CFrame.Angles(0.9, 1.6, 0.4) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(chip, 0.22, { CFrame = CFrame.new(g + Vector3.new(R * 0.6, R * 0.3, 0)) * CFrame.Angles(1.2, 2, 0.6) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.22, function()
		crater(g + Vector3.new(0, 2.4, 0), R, ROCK, Color3.fromRGB(255, 220, 160), 1.6)
		task.delay(0.8, function()
			fadeOut(rock, 0.5, { CFrame = rock.CFrame - Vector3.new(0, R, 0) })
			fadeOut(chip, 0.5, { CFrame = chip.CFrame - Vector3.new(0, R, 0) })
		end)
	end)
end
-- 옥의 숲: 둘레 곳곳에서 결정이 자라났다가, 끝에 한꺼번에 깨진다
local function zoneCrystal(data: any)
	local c, c2 = colors(data)
	local g, R, dur = groundAt(data.at), data.radius or 20, data.dur or 2
	local floor = disc(g + Vector3.new(0, 0.12, 0), 1, c, 0.6)
	tween(floor, 0.3, { Size = Vector3.new(0.2, R * 2, R * 2) })
	fadeOut(floor, dur + 0.3)
	local n = math.floor(R * 1.2)
	for k = 1, n do
		task.delay(math.random() * dur * 0.6, function()
			local a, rr = math.random() * math.pi * 2, math.sqrt(math.random()) * R * 0.95
			crystalCluster(g + Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr), 2 + math.random() * 1.6, c, c2, dur * 0.5)
		end)
		local _ = k
	end
	Fx.flash(g + Vector3.new(0, 4, 0), c2, R * 3, 3, 0.4)
	Fx.breakSound("glass", 0.7, 1.1, g)
	shakeNear(g, 0.4, 90)
end
-- 3.19.5판 천종만향: 하늘에서 진짜 종 모양의 거대한 금종이 내려와 걸리고 옆의 당목이 0.4초마다 종을 친다.
-- 칠 때마다 종이 흔들리며 울림 고리가 퍼진다
local function zoneBell(data: any)
	local c, c2 = colors(data)
	local at, R, dur = data.at, data.radius or 20, data.dur or 2
	local s = R * 0.5
	local parts, place = makeBell(c, c2, s, 0.05)
	local top = at + Vector3.new(0, s * 1.2 + 3, 0)
	local from = top + Vector3.new(0, 50, 0)
	local log = part(Vector3.new(s * 1.3, s * 0.24, s * 0.24), Color3.fromRGB(120, 82, 52), Enum.Material.Wood, 0, "cyl")
	local cap = part(Vector3.new(s * 0.1, s * 0.27, s * 0.27), c2, Enum.Material.Neon, 0.2, "cyl")
	local lip = disc(groundAt(at) + Vector3.new(0, 0.3, 0), R * 0.6, c2, 0.4)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local el = os.clock() - t0
		if el > dur + 0.3 then
			conn:Disconnect()
			for _, q in ipairs(parts) do
				fadeOut(q, 0.5, { CFrame = q.CFrame + Vector3.new(0, 14, 0) })
			end
			fadeOut(log, 0.3)
			fadeOut(cap, 0.3)
			fadeOut(lip, 0.4)
			return
		end
		local drop = math.clamp(el / 0.25, 0, 1)
		local pos = from:Lerp(top, drop * drop)
		-- 맞을 때마다 크게 흔들렸다가 잦아든다
		local ph = math.max(0, el - 0.25) % 0.4
		local sw = el > 0.25 and math.sin(ph * 30) * 0.08 * (1 - ph / 0.4) or 0
		place(CFrame.new(pos) * CFrame.Angles(0, 0, sw))
		-- 당목: 뒤로 물러났다가 종 옆구리를 친다 (0.25초에 첫 타)
		local u = ((el - 0.05) % 0.4) / 0.4
		local d = s * 0.72 + s * 1.1 * (0.5 + 0.5 * math.cos(u * math.pi * 2 + math.pi))
		local lcf = CFrame.new(pos + Vector3.new(d + s * 0.65, -s * 0.1, 0))
		log.CFrame = lcf
		cap.CFrame = lcf * CFrame.new(-s * 0.65, 0, 0)
	end)
	local n = math.max(1, math.floor(dur / 0.2))
	for k = 0, n - 1 do
		task.delay(0.25 + k * 0.2, function()
			Fx.ring(at - Vector3.new(0, 2.3, 0), k % 2 == 0 and c2 or c, 2, R * 2.2, 0.45)
			if k % 2 == 0 then
				Fx.ring(top, c2, 2, s * 3, 0.4)
				emitBurst(top + Vector3.new(s * 0.7, 0, 0), c2, 12, 22, 0.6, 0.4)
				Fx.sound("ping", 0.7, 0.5 + (k % 4) * 0.04, at)
			end
		end)
	end
	Fx.flash(top, c2, R * 3, 4, 0.4)
	shakeNear(at, 0.5, 90)
end
-- 종소리 물결: 앞으로 부채꼴 소리 고리가 세 겹 밀려 나간다
local function coneBell(data: any)
	local m = data.m
	local c, c2 = colors(data)
	local r = rootOf(m)
	if not r then
		return
	end
	local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z).Unit
	local range = data.range or 20
	for k = 0, 2 do
		task.delay((data.delay or 0.15) + k * 0.12, function()
			local arc = part(Vector3.new(range * 0.5, 0.3, 0.6), k == 1 and c2 or c, Enum.Material.Neon, 0.3)
			local from = r.Position + look * 3
			arc.CFrame = CFrame.lookAt(from, from + look)
			tween(arc, 0.4, { CFrame = CFrame.lookAt(from + look * range, from + look * (range + 1)), Size = Vector3.new(range * 1.3, 0.3, 0.6), Transparency = 1 })
			task.delay(0.42, function()
				arc:Destroy()
			end)
		end)
	end
	Fx.ring(r.Position, c2, 2, 10, 0.3, look)
	Fx.sound("ping", 0.8, 0.45, r.Position)
	shakeNear(r.Position, 0.3, 50)
end
------------------------------------------------------------------------
-- 3.19.3판: 새 권법이 옛 권법과 같은 장치를 쓰는 기술은, 화면에서 그 권법만의 모습으로 바꿔 그린다
-- (서버 장치는 그대로, 권법 id로 골라 그린다. 옛 권법의 모습은 건드리지 않는다)
------------------------------------------------------------------------
local GOLD = Color3.fromRGB(255, 205, 90)
local JADE = Color3.fromRGB(120, 255, 220)
local CRIMSON = Color3.fromRGB(200, 40, 35)
local lineBeam = beamLine
local function noop(_data: any) end

-- ── 명경권: 분신 대신 거울이 선다. R = 적마다 거울 한 장에서 내가 튀어나와 친다 · X = 하늘과 땅이 거울 ──
local function mirrorPane(at: Vector3, face: Vector3, c: Color3, c2: Color3, h: number): (BasePart, BasePart)
	local pane = part(Vector3.new(h * 0.6, h, 0.2), c2, Enum.Material.Glass, 0.25)
	pane.Reflectance = 0.7
	pane.CFrame = CFrame.lookAt(at + Vector3.new(0, h * 0.25, 0), face + Vector3.new(0, h * 0.25, 0))
	local rim = part(Vector3.new(h * 0.66, h * 1.06, 0.1), c, Enum.Material.Neon, 0.35)
	rim.CFrame = pane.CFrame * CFrame.new(0, 0, 0.15)
	pane.Size = Vector3.new(0.2, h, 0.2)
	tween(pane, 0.15, { Size = Vector3.new(h * 0.6, h, 0.2) })
	return pane, rim
end
local function mirrorBreak(pane: BasePart, rim: BasePart)
	rise(pane, pane.CFrame, pane.Size, 0, true)
	fadeOut(rim, 0.2)
	Fx.breakSound("glass", 0.5, 1.5, pane.Position)
end
local function mirrorClones(data: any)
	local c, c2 = colors(data)
	local m = data.m
	local mr = rootOf(m)
	local big = (data.delay or 0) >= 0.5
	if big and mr then
		-- 하늘과 땅이 거울: 발밑에 넓은 거울 바닥, 머리 위에 거울 하늘
		local floor = disc(mr.Position - Vector3.new(0, 2.7, 0), 1, c2, 0.3, Enum.Material.Glass)
		floor.Reflectance = 0.8
		tween(floor, 0.4, { Size = Vector3.new(0.2, 80, 80) })
		local sky = part(Vector3.new(80, 0.2, 80), c2, Enum.Material.Glass, 0.55)
		sky.Reflectance = 0.8
		sky.CFrame = CFrame.new(mr.Position + Vector3.new(0, 30, 0))
		task.delay(3, function()
			rise(floor, floor.CFrame, floor.Size, 0, true)
			fadeOut(sky, 0.4)
			Fx.flash(mr.Position, c2, 90, 5, 0.4)
			Fx.breakSound("glass", 1, 0.8, mr.Position)
			if opts.flash and near(mr.Position, 80) then
				opts.flash(c2, 0.4)
			end
		end)
	end
	for i, t in ipairs(data.targets or {}) do
		local tr = rootOf(t)
		if tr then
			task.delay((data.delay or 0.3) * 0.5 + (i - 1) * (data.every or 0.1), function()
				local tp = tr.Position
				local from = mr and mr.Position or tp + Vector3.new(0, 0, 6)
				local dir = Vector3.new(tp.X - from.X, 0, tp.Z - from.Z)
				dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 0, -1)
				local at = tp - dir * 4
				local pane, rim = mirrorPane(at - Vector3.new(0, 2.5, 0), tp - Vector3.new(0, 2.5, 0), c, c2, big and 8 or 6)
				-- 거울에서 튀어나온 나 (반투명한 몸이 앞으로 미끄러진다)
				local ghost = part(Vector3.new(2, 5, 1), c2, Enum.Material.Glass, 0.5)
				ghost.CFrame = CFrame.lookAt(at, tp)
				tween(ghost, 0.18, { CFrame = CFrame.lookAt(tp - dir * 1.5, tp) })
				task.delay(0.22, function()
					Fx.ring(tp, c2, 1, 9, 0.25, dir)
					Fx.burst("glitter", tp, c2, 10, 1.1)
					fadeOut(ghost, 0.2)
				end)
				task.delay(big and 0.9 or 0.6, function()
					mirrorBreak(pane, rim)
				end)
			end)
		end
	end
end

-- ── 산악붕권 천붕지열: 땅이 산처럼 솟았다가 무너진다 (빛기둥 없이 바위 봉우리) ──
local function sanakLaunch(data: any)
	local at, R = data.at, data.radius or 20
	local g = groundAt(at)
	for k = 0, 13 do
		local a = k / 14 * math.pi * 2 + math.random() * 0.3
		local rr = R * (0.35 + math.random() * 0.6)
		local p = g + Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr)
		local h = 6 + math.random() * 10
		local spire = part(Vector3.new(3.5, 0.3, 3.5) * (0.8 + math.random() * 0.6), ROCK:Lerp(Color3.fromRGB(110, 80, 60), math.random()), Enum.Material.Rock, 0)
		local tilt = CFrame.Angles(math.random() * 0.5 - 0.25, a, math.random() * 0.5 - 0.25)
		spire.CFrame = CFrame.new(p) * tilt
		rise(spire, CFrame.new(p + Vector3.new(0, h / 2, 0)) * tilt, Vector3.new(spire.Size.X, h, spire.Size.Z), 0.75, false)
	end
	crater(at, R * 0.8, ROCK, Color3.fromRGB(255, 220, 160), 2)
	Fx.burst("dust", g + Vector3.new(0, 2, 0), Color3.fromRGB(180, 160, 130), 30, 2.2)
end
local function sanakCollapse(data: any)
	local at, R = data.at, data.radius or 20
	crater(at, R, ROCK, Color3.fromRGB(255, 200, 120), 2.2)
	Fx.debris(groundAt(at) + Vector3.new(0, 1, 0), 14, 30, ROCK)
end

-- ── 초·천룡파천장 ──
-- R 비룡천: 금빛 용이 나선으로 감아 오르는 기둥
local function dragonSpiral(data: any)
	local at, R = data.at, data.radius or 14
	local g = groundAt(at)
	for k = 0, 23 do
		task.delay(k * 0.015, function()
			local u = k / 23
			local a = u * math.pi * 5
			local p = g + Vector3.new(math.cos(a) * R * 0.45, u * 26, math.sin(a) * R * 0.45)
			local sc = part(Vector3.new(2.2, 1.2, 2.6) * (1.2 - u * 0.5), u < 0.95 and GOLD:Lerp(JADE, (k % 3) / 3) or JADE, Enum.Material.Neon, 0.15)
			sc.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0.4, math.cos(a)))
			fadeOut(sc, 0.6, { CFrame = sc.CFrame + Vector3.new(0, 4, 0) })
		end)
	end
	Fx.ring(g + Vector3.new(0, 0.3, 0), GOLD, 1, R * 2.2, 0.4)
	Fx.flash(g + Vector3.new(0, 6, 0), GOLD, 50, 4, 0.4)
	Fx.sound("swing", 0.8, 0.7, at)
	shakeNear(at, 0.4, 70)
end
-- G 구룡천강: 머리 위 금빛 구름 소용돌이에서 비취빛 수염의 금룡 아홉이 차례로 내리꽂힌다
local swirl: { [any]: BasePart } = {}
local function dragonsRise(data: any)
	local m = data.m
	local r = rootOf(m)
	if not r then
		return
	end
	local top = r.Position + Vector3.new(0, 32, 0)
	local vortex = disc(top, 1, GOLD, 0.3)
	tween(vortex, 0.5, { Size = Vector3.new(0.4, 46, 46) })
	local inner = disc(top - Vector3.new(0, 0.3, 0), 1, JADE, 0.4)
	tween(inner, 0.5, { Size = Vector3.new(0.4, 26, 26) })
	swirl[m] = vortex
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local el = os.clock() - t0
		if el > 3.2 or not vortex.Parent then
			conn:Disconnect()
			fadeOut(vortex, 0.4)
			fadeOut(inner, 0.4)
			return
		end
		vortex.CFrame = CFrame.new(top) * CFrame.Angles(0, el * 2, math.rad(90))
		inner.CFrame = CFrame.new(top - Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, -el * 3, math.rad(90))
	end)
	Fx.flash(top, GOLD, 80, 3, 0.5)
	Fx.sound("ping", 0.7, 0.4, r.Position)
end
local function dragonDive(data: any)
	local at = data.at
	local from = (typeof(data.from) == "Vector3" and data.from or at) + Vector3.new((math.random() - 0.5) * 20, 32, (math.random() - 0.5) * 20)
	local segs = {}
	for k = 1, 10 do
		local sg = part(Vector3.new(1, 1, 1) * (2.6 - k * 0.15), k == 1 and GOLD or GOLD:Lerp(JADE, k / 12), Enum.Material.Neon, 0.1, "ball")
		sg.Position = from
		table.insert(segs, sg)
	end
	local whiskL = part(Vector3.new(0.2, 0.2, 4), JADE, Enum.Material.Neon, 0.2)
	local whiskR = part(Vector3.new(0.2, 0.2, 4), JADE, Enum.Material.Neon, 0.2)
	local t0 = os.clock()
	local dur = 0.32
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / dur, 0, 1)
		for k, sg in ipairs(segs) do
			local uk = math.clamp(u - k * 0.04, 0, 1)
			local p = from:Lerp(at, uk) + Vector3.new(math.sin(uk * 9 + k) * 2, 0, math.cos(uk * 9 + k) * 2) * (1 - uk)
			sg.Position = p
		end
		local head = segs[1].Position
		local fwd = (at - from).Unit
		whiskL.CFrame = CFrame.lookAt(head, head - fwd) * CFrame.new(-1.2, 0.4, 2)
		whiskR.CFrame = CFrame.lookAt(head, head - fwd) * CFrame.new(1.2, 0.4, 2)
		if u >= 1 then
			conn:Disconnect()
			for _, sg in ipairs(segs) do
				fadeOut(sg, 0.3)
			end
			fadeOut(whiskL, 0.2)
			fadeOut(whiskR, 0.2)
			crater(at, data.radius or 9, GOLD, JADE, 0.8)
		end
	end)
end
local function dragonsEnd(data: any)
	local at, R = data.at, data.radius or 24
	local g = groundAt(at)
	-- 금빛 연꽃이 피며 터진다
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local petal = part(Vector3.new(3, 0.4, R * 0.5), k % 2 == 0 and GOLD or JADE, Enum.Material.Neon, 0.2)
		petal.CFrame = CFrame.new(g + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -R * 0.25) * CFrame.Angles(math.rad(-10), 0, 0)
		tween(petal, 0.35, { CFrame = CFrame.new(g + Vector3.new(0, 2, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -R * 0.4) * CFrame.Angles(math.rad(-50), 0, 0) })
		task.delay(0.4, function()
			fadeOut(petal, 0.4)
		end)
	end
	Fx.blast(at, GOLD, JADE, 2.6)
	Fx.flash(at, GOLD, R * 4, 6, 0.5)
	Fx.breakSound("boom", 1, 0.7, at)
	shakeNear(at, 1, 120)
end
-- X 천룡멸세: 산만 한 금룡이 하늘을 휘감는다 (비늘 판 서른이 큰 고리를 그리며 돈다), 내리꽂힐 때 하늘에서 발톱 자국, 마지막 숨은 금·비취 두 겹 빛줄기
local function skyDragon(data: any)
	local m = data.m
	local r = rootOf(m)
	if not r then
		return
	end
	local dur = data.dur or 4
	local plates = {}
	for k = 1, 30 do
		local sc = part(Vector3.new(4, 2.4, 5) * (1.4 - k / 40), k % 5 == 0 and JADE or GOLD, Enum.Material.Neon, 0.1)
		table.insert(plates, sc)
	end
	local head = part(Vector3.new(7, 5, 9), GOLD, Enum.Material.Neon, 0)
	local eyeL = part(Vector3.new(1, 1, 1), CRIMSON, Enum.Material.Neon, 0, "ball")
	local eyeR = part(Vector3.new(1, 1, 1), CRIMSON, Enum.Material.Neon, 0, "ball")
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local el = os.clock() - t0
		local c0 = (rootOf(m) or r).Position + Vector3.new(0, 26, 0)
		if el > dur then
			conn:Disconnect()
			for _, sc in ipairs(plates) do
				fadeOut(sc, 0.5, { CFrame = sc.CFrame + Vector3.new(0, 12, 0) })
			end
			fadeOut(head, 0.5)
			fadeOut(eyeL, 0.3)
			fadeOut(eyeR, 0.3)
			return
		end
		local grow = math.clamp(el / 0.6, 0, 1)
		for k, sc in ipairs(plates) do
			local a = el * 1.6 - k * 0.21
			local p = c0 + Vector3.new(math.cos(a) * 30 * grow, math.sin(a * 2) * 5, math.sin(a) * 30 * grow)
			sc.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a)))
		end
		local a = el * 1.6 + 0.25
		local hp = c0 + Vector3.new(math.cos(a) * 30 * grow, math.sin(a * 2) * 5, math.sin(a) * 30 * grow)
		head.CFrame = CFrame.lookAt(hp, hp + Vector3.new(-math.sin(a), 0, math.cos(a)))
		eyeL.CFrame = head.CFrame * CFrame.new(-2, 1.5, -3.5)
		eyeR.CFrame = head.CFrame * CFrame.new(2, 1.5, -3.5)
	end)
	Fx.flash(r.Position + Vector3.new(0, 20, 0), GOLD, 120, 4, 0.8)
	shakeNear(r.Position, 1.2, 140)
end
local function skyDragonStrike(data: any)
	local spots = data.at
	local list = typeof(spots) == "Vector3" and { spots } or (type(spots) == "table" and spots or {})
	for _, at in ipairs(list) do
		if typeof(at) == "Vector3" then
			if data.last then
				-- 마지막 숨: 하늘에서 앞으로 금·비취 두 겹 빛줄기
				local m = data.m
				local r = rootOf(m)
				local from = (r and r.Position or at) + Vector3.new(0, 26, 0)
				lineBeam(from, at, 14, GOLD, 0.15, 0.7)
				lineBeam(from, at, 7, JADE, 0.05, 0.6)
				crater(at, data.radius or 26, GOLD, JADE, 2.4)
				if opts.flash and near(at, 120) then
					opts.flash(GOLD, 0.5)
				end
			else
				-- 하늘에서 내리그은 발톱 자국 셋
				for k = -1, 1 do
					local a = at + Vector3.new(k * 2.5, 30, 0)
					lineBeam(a, at + Vector3.new(k * 2.5, -2, k * 1.5), 1.4, GOLD, 0.1, 0.35)
				end
				crater(at, data.radius or 12, GOLD, JADE, 1.1)
			end
		end
	end
end
-- 장풍: 비취 수염과 금빛 비늘의 뱀처럼 꿈틀대는 용 (천룡파천장의 둥근 용 몸과 다르다)
function Arts.projectile(data: any)
	local size = data.size or 4
	local dir: Vector3 = data.dir
	local head = part(Vector3.new(size * 0.8, size * 0.6, size * 1.3), GOLD, Enum.Material.Neon, 0.05)
	local horns = part(Vector3.new(size * 1.3, 0.3, 0.3), JADE, Enum.Material.Neon, 0.1)
	local segs = {}
	for k = 1, 9 do
		local sg = part(Vector3.new(size * 0.55, size * 0.4, size * 0.7) * (1 - k * 0.07), k % 2 == 0 and GOLD or GOLD:Lerp(JADE, 0.35), Enum.Material.Neon, 0.15)
		table.insert(segs, sg)
	end
	local t0 = os.clock()
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local p = data.pos + dir * data.speed * t
		head.CFrame = CFrame.lookAt(p, p + dir)
		horns.CFrame = head.CFrame * CFrame.new(0, size * 0.35, size * 0.2)
		for k, sg in ipairs(segs) do
			local back = math.max(0, t - k * 0.018)
			local q = data.pos + dir * data.speed * back + side * math.sin(back * 22 + k * 0.8) * size * 0.5 + Vector3.new(0, math.cos(back * 18 + k) * size * 0.2, 0)
			sg.CFrame = CFrame.lookAt(q, q + dir)
		end
		if math.random() < 0.3 then
			Fx.burst("glitter", p, JADE, 2, 0.8)
		end
		if t >= data.life then
			conn:Disconnect()
			Fx.ring(p, GOLD, 1, size * 3, 0.25, dir)
			fadeOut(head, 0.15)
			fadeOut(horns, 0.15)
			for _, sg in ipairs(segs) do
				fadeOut(sg, 0.2)
			end
		end
	end)
end
function Arts.ownsProjectile(data: any): boolean
	return data.style == "chocheonryong"
end

-- ── 천하패권 ──
local function overlordDash(data: any)
	local c, c2 = CRIMSON, GOLD
	local a, b = data.from, data.to
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
		return
	end
	-- 지나간 자리에 금빛 발자국 셋과 붉은 충격파
	for k = 1, 3 do
		local p = a:Lerp(b, k / 3)
		local fp = disc(groundAt(p) + Vector3.new(0, 0.15, 0), 1.4, c2, 0.2)
		fadeOut(fp, 0.8)
	end
	lineBeam(a, b, 0.6, c2, 0.3, 0.2)
	Fx.ring(b, c, 1, 12, 0.3, (b - a).Unit)
	Fx.ring(b, c2, 1, 7, 0.25, (b - a).Unit)
	Fx.breakSound("boom", 0.4, 1.3, b)
	shakeNear(b, 0.3, 60)
end
-- 붙잡을 때: 쇠사슬 대신 금빛 기운의 손아귀
local function overlordGrab(data: any)
	for _, t in ipairs(data.targets or {}) do
		local r = rootOf(t)
		if r then
			local grip = part(Vector3.new(5, 5, 5), GOLD, Enum.Material.ForceField, 0.2, "ball")
			grip.CFrame = r.CFrame
			local t0 = os.clock()
			local total = (data.reel or 0.2) + (data.hold or 0.3)
			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function()
				local rr = rootOf(t)
				if not rr or os.clock() - t0 > total then
					conn:Disconnect()
					fadeOut(grip, 0.2, { Size = Vector3.new(8, 8, 8) })
					return
				end
				grip.CFrame = rr.CFrame * CFrame.Angles(0, os.clock() * 4, 0)
			end)
			Fx.flash(r.Position, GOLD, 18, 3, 0.2)
		end
	end
end
local function overlordFly(data: any)
	local t = data.t
	local t0 = os.clock()
	local last: Vector3? = nil
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local r = rootOf(t)
		if not r or os.clock() - t0 > (data.dur or 0.6) then
			conn:Disconnect()
			return
		end
		local p = r.Position
		if last and (p - last).Magnitude > 1.5 then
			lineBeam(last, p, 1.4, CRIMSON, 0.2, 0.4)
		end
		last = p
	end)
end
local function overlordSlam(data: any)
	crater(data.at, data.radius or 10, CRIMSON, GOLD, 1.4)
end
-- G 천하무쌍권: 모을 때 머리 위에 금빛 관 모양 고리, 지를 때 붉은 거대한 주먹 그림자가 앞으로 땅을 갈며 나아간다
local function overlordCharge(data: any)
	local m = data.m
	local r = rootOf(m)
	if not r then
		return
	end
	local crown = {}
	for k = 0, 7 do
		local sp = part(Vector3.new(0.6, 2.4, 0.6), GOLD, Enum.Material.Neon, 0.1)
		table.insert(crown, sp)
		local _ = k
	end
	local t0 = os.clock()
	local dur = data.time or 1
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local rr = rootOf(m)
		local el = os.clock() - t0
		if not rr or el > dur then
			conn:Disconnect()
			for _, sp in ipairs(crown) do
				fadeOut(sp, 0.2)
			end
			return
		end
		for k, sp in ipairs(crown) do
			local a = k / #crown * math.pi * 2 + el * 2
			sp.CFrame = CFrame.new(rr.Position + Vector3.new(math.cos(a) * 3, 5 + (k % 2) * 0.8, math.sin(a) * 3))
		end
		if math.random() < 0.3 then
			Fx.ring(rr.Position - Vector3.new(0, 2.4, 0), CRIMSON, 12, 2, 0.3)
		end
	end)
	Fx.sound("ping", 0.6, 0.35, r.Position)
end
local function overlordPunch(data: any)
	local from, dir, range = data.from, data.dir, data.range or 50
	if typeof(from) ~= "Vector3" or typeof(dir) ~= "Vector3" then
		return
	end
	local fist = part(Vector3.new(9, 9, 9), CRIMSON, Enum.Material.Neon, 0.25, "ball")
	local knuck = part(Vector3.new(10, 3, 4), GOLD, Enum.Material.Neon, 0.2)
	local t0 = os.clock()
	local dur = 0.45
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / dur, 0, 1)
		local p = from + dir * range * u + Vector3.new(0, 1, 0)
		fist.CFrame = CFrame.lookAt(p, p + dir)
		knuck.CFrame = fist.CFrame * CFrame.new(0, 2, -4)
		if math.random() < 0.6 then
			local g = groundAt(p)
			local tr = part(Vector3.new(6, 0.3, 4), Color3.fromRGB(60, 35, 25), Enum.Material.Slate, 0)
			tr.CFrame = CFrame.lookAt(g + Vector3.new(0, 0.1, 0), g + dir)
			task.delay(1.2, function()
				fadeOut(tr, 0.5)
			end)
			Fx.burst("dust", g + Vector3.new(0, 1, 0), Color3.fromRGB(170, 140, 110), 4, 1.4)
		end
		if u >= 1 then
			conn:Disconnect()
			fadeOut(fist, 0.25, { Size = Vector3.new(16, 16, 16) })
			fadeOut(knuck, 0.2)
			crater(p, 16, CRIMSON, GOLD, 2.4)
		end
	end)
	Fx.breakSound("boom", 1, 0.6, from)
	shakeNear(from, 1.2, 120)
	if opts.flash and near(from, 80) then
		opts.flash(CRIMSON, 0.35)
	end
end
-- X 패천멸지: 먹구름 대신 하늘에 붉은·금빛 큰 인장이 돌고 벼락 대신 금빛 주먹 기둥이 떨어진다
local function overlordSeal(data: any)
	local m = data.m
	local r = rootOf(m)
	if not r then
		return
	end
	local R = data.radius or 40
	local top = r.Position + Vector3.new(0, 36, 0)
	local outer = disc(top, 1, CRIMSON, 0.3)
	local inner = disc(top - Vector3.new(0, 0.3, 0), 1, GOLD, 0.35)
	tween(outer, 0.5, { Size = Vector3.new(0.4, R * 2, R * 2) })
	tween(inner, 0.5, { Size = Vector3.new(0.4, R * 1.3, R * 1.3) })
	local t0 = os.clock()
	local dur = data.dur or 2.4
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local el = os.clock() - t0
		if el > dur + 0.6 then
			conn:Disconnect()
			fadeOut(outer, 0.4)
			fadeOut(inner, 0.4)
			return
		end
		outer.CFrame = CFrame.new(top) * CFrame.Angles(0, el * 0.8, math.rad(90))
		inner.CFrame = CFrame.new(top - Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, -el * 1.4, math.rad(90))
	end)
	if opts.flash and near(r.Position, 100) then
		opts.flash(CRIMSON, 0.3)
	end
end
local function overlordPillar(data: any)
	local at, R = data.at, data.radius or 8
	local g = groundAt(at)
	local col = part(Vector3.new(R * 0.9, 40, R * 0.9), GOLD, Enum.Material.Neon, 0.25)
	col.CFrame = CFrame.new(g + Vector3.new(0, 60, 0))
	tween(col, 0.12, { CFrame = CFrame.new(g + Vector3.new(0, 20, 0)) }, Enum.EasingStyle.Linear)
	task.delay(0.12, function()
		fadeOut(col, 0.3, { Size = Vector3.new(R * 1.6, 2, R * 1.6), CFrame = CFrame.new(g + Vector3.new(0, 1, 0)) })
		crater(at, data.small and R or R * 1.6, CRIMSON, GOLD, data.small and 0.6 or 2)
	end)
end
local function pulseOverlord(data: any)
	local at, R = data.at, data.radius or 14
	task.delay(data.delay or 0.4, function()
		-- 위에서 누르는 패기: 붉은 원판이 내려앉고 금빛 관 모양 가시가 둘레에 솟는다
		local g = groundAt(at)
		local press = disc(g + Vector3.new(0, 8, 0), R, CRIMSON, 0.4)
		tween(press, 0.15, { CFrame = CFrame.new(g + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
		fadeOut(press, 0.6)
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			local sp = part(Vector3.new(0.8, 0.2, 0.8), GOLD, Enum.Material.Neon, 0.1)
			local p = g + Vector3.new(math.cos(a), 0, math.sin(a)) * R
			sp.CFrame = CFrame.new(p)
			rise(sp, CFrame.new(p + Vector3.new(0, 2, 0)), Vector3.new(0.8, 4, 0.8), 0.4, false)
		end
		Fx.breakSound("boom", 0.7, 0.8, at)
		shakeNear(at, 0.5, 70)
	end)
end

-- ── 빙혼신장 한빙결 ──
local function binghonFreeze(data: any)
	-- 빙혼: 발밑에서 눈꽃 무늬가 퍼지고 적마다 얼음 꽃봉오리에 갇힌다
	local at, R = data.at, data.radius or 15
	local g = groundAt(at)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local arm = part(Vector3.new(0.8, 0.15, R), ICE2, Enum.Material.Neon, 0.3)
		arm.CFrame = CFrame.new(g + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -R / 2)
		fadeOut(arm, data.dur or 1.6)
		for j = 1, 2 do
			local br = part(Vector3.new(0.5, 0.15, R * 0.3), ICE, Enum.Material.Neon, 0.35)
			br.CFrame = CFrame.new(g + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -R * (0.35 + j * 0.2)) * CFrame.Angles(0, math.rad(j % 2 == 0 and 40 or -40), 0) * CFrame.new(0, 0, -R * 0.15)
			fadeOut(br, data.dur or 1.6)
		end
	end
	for _, t in ipairs(data.targets or {}) do
		if typeof(t) == "Instance" and t:IsA("Model") then
			iceCage(t, data.dur or 1.6)
		end
	end
	Fx.breakSound("glass", 0.6, 1.3, at)
end
local function binghonErase(data: any)
	local r = rootOf(data.t)
	if r then
		Fx.burst("glitter", r.Position, ICE2, 12, 1.2)
		Fx.breakSound("glass", 0.5, 1.4, r.Position)
	end
end

-- ── 천종신권 금종조: 하늘에서 반투명한 금종이 떨어져 몸을 덮고 덮인 동안 종이 웅웅 울린다 ──
local function bellGuard(data: any)
	local m = data.m
	local r = rootOf(m)
	if not r then
		return
	end
	local c, c2 = colors(data)
	local s = 5.8
	local parts, place = makeBell(c, c2, s, 0.45)
	local lip = part(Vector3.new(0.6, 10, 10), c2, Enum.Material.Neon, 0.4, "cyl")
	local t0 = os.clock()
	local dur = data.dur or 1.2
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local rr = rootOf(m)
		local el = os.clock() - t0
		if not rr or el > dur then
			conn:Disconnect()
			for _, q in ipairs(parts) do
				fadeOut(q, 0.3, { Size = q.Size * 1.3 })
			end
			fadeOut(lip, 0.3)
			return
		end
		local feet = rr.Position - Vector3.new(0, 2.6, 0)
		local rest = feet + Vector3.new(0, s * 0.32 + 0.1, 0)
		local u = math.clamp(el / 0.16, 0, 1)
		local pos = (rest + Vector3.new(0, 22, 0)):Lerp(rest, u * u)
		place(CFrame.new(pos) * CFrame.Angles(0, 0, el > 0.16 and math.sin(el * 34) * 0.025 or 0))
		lip.CFrame = CFrame.new(feet + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end)
	task.delay(0.16, function()
		Fx.sound("ping", 0.9, 0.5, r.Position)
		Fx.ring(r.Position - Vector3.new(0, 2.4, 0), c2, 2, 16, 0.4)
		emitBurst(r.Position, c2, 20, 24, 0.6, 0.5)
		shakeNear(r.Position, 0.4, 60)
	end)
end
local function bellWave(data: any)
	local c, c2 = colors(data)
	local at, R = data.at, data.radius or 12
	for k = 0, 2 do
		task.delay(k * 0.1, function()
			Fx.ring(at - Vector3.new(0, 2.3, 0), k == 1 and c or c2, 2, R * 2.4, 0.45)
		end)
	end
	Fx.sound("ping", 1, 0.42, at)
end

-- ── 역류반격권 회류파: 물결이 앞으로 갔다가 거꾸로 말려 돌아온다 ──
local function coneBackflow(data: any)
	local m = data.m
	local c, c2 = colors(data)
	local r = rootOf(m)
	if not r then
		return
	end
	local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z).Unit
	local range = data.range or 16
	local g = groundAt(r.Position)
	for k = 0, 4 do
		local wave = part(Vector3.new(range * 0.9, 2.2, 1.2), k % 2 == 0 and c or c2, Enum.Material.Glass, 0.3)
		local from = g + look * 2 + Vector3.new(0, 1.1, 0)
		wave.CFrame = CFrame.lookAt(from, from + look)
		task.delay((data.delay or 0.18) + k * 0.05, function()
			tween(wave, 0.25, { CFrame = CFrame.lookAt(from + look * range, from + look * (range + 1)) * CFrame.Angles(math.rad(-60), 0, 0), Size = Vector3.new(range * 1.2, 3, 1.2) })
			task.delay(0.25, function()
				-- 끝에서 말려 거꾸로 돌아온다
				tween(wave, 0.25, { CFrame = CFrame.lookAt(from + look * (range * 0.5), from + look * (range * 0.5 - 1)) * CFrame.Angles(math.rad(-120), 0, 0), Transparency = 1 })
				task.delay(0.27, function()
					wave:Destroy()
				end)
			end)
		end)
	end
	Fx.sound("splash", 0.7, 1.1, r.Position)
end

------------------------------------------------------------------------
-- 3.19.4판 기술을 쓰는 순간: 권법마다 다른 발밑 문양 · 두 손의 빛 · 몸 둘레 빛 가루. 오의 (G·X)는 몇 배로 크게
------------------------------------------------------------------------
local function handGlow(model: Model, c: Color3, c2: Color3, dur: number, big: boolean)
	for _, nm in ipairs({ "RightHand", "LeftHand" }) do
		local h = model:FindFirstChild(nm) or model:FindFirstChild(nm == "RightHand" and "Right Arm" or "Left Arm")
		if h and h:IsA("BasePart") then
			local orb = part(Vector3.new(1, 1, 1) * (big and 2.2 or 1.4), c2, Enum.Material.Neon, 0.2, "ball")
			local halo = part(Vector3.new(1, 1, 1) * (big and 3.6 or 2.4), c, Enum.Material.Neon, 0.65, "ball")
			local t0 = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.RenderStepped:Connect(function()
				if not h.Parent or os.clock() - t0 > dur then
					conn:Disconnect()
					fadeOut(orb, 0.2)
					fadeOut(halo, 0.2)
					return
				end
				orb.Position = h.Position
				halo.Position = h.Position
				halo.Size = Vector3.new(1, 1, 1) * ((big and 3.6 or 2.4) + math.sin(os.clock() * 20) * 0.3)
			end)
		end
	end
end
-- 발밑 문양: 조각 n개를 둘레에 늘어놓고 돌리다가 부풀며 사라진다
local function sigilRing(feet: Vector3, n: number, R: number, mk: (number) -> BasePart, spin: number, dur: number)
	local parts = {}
	for k = 1, n do
		table.insert(parts, mk(k))
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local el = os.clock() - t0
		local u = math.clamp(el / dur, 0, 1)
		local rr = R * (0.5 + 0.5 * math.min(1, el / 0.15)) * (1 + u * 0.3)
		for k, p in ipairs(parts) do
			local a = k / n * math.pi * 2 + el * spin
			p.CFrame = CFrame.new(feet + Vector3.new(math.cos(a) * rr, 0.3, math.sin(a) * rr)) * CFrame.Angles(0, -a, 0)
			p.Transparency = 0.15 + u * 0.85
		end
		if u >= 1 then
			conn:Disconnect()
			for _, p in ipairs(parts) do
				p:Destroy()
			end
		end
	end)
end
local SIGIL: { [string]: (Vector3, Color3, Color3, number, number) -> () } = {
	cheolsae = function(feet, c, c2, R, dur) -- 쇠사슬 고리가 발밑을 감아 돈다
		sigilRing(feet, 16, R, function(k)
			return part(Vector3.new(0.5, 0.5, 1.4), k % 2 == 0 and IRON or c2, Enum.Material.Metal, 0.1)
		end, 3, dur)
	end,
	yeokryu = function(feet, c, c2, R, dur) -- 바깥으로 갔다 안으로 되돌아오는 물결
		for k = 0, 2 do
			task.delay(k * 0.08, function()
				local w = disc(feet + Vector3.new(0, 0.2, 0), R * 1.2, k == 1 and c2 or c, 0.4)
				tween(w, dur * 0.6, { Size = Vector3.new(0.2, 1, 1), Transparency = 1 })
				task.delay(dur * 0.6, function()
					w:Destroy()
				end)
			end)
		end
	end,
	jilpung = function(feet, c, c2, R, dur) -- 발밑을 휘감아 오르는 바람 띠 셋
		for k = 1, 3 do
			local band = part(Vector3.new(0.3, 0.8, R * 1.2), k == 2 and c or c2, Enum.Material.Neon, 0.3)
			local t0 = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.RenderStepped:Connect(function()
				local u = (os.clock() - t0) / dur
				if u >= 1 then
					conn:Disconnect()
					band:Destroy()
					return
				end
				band.CFrame = CFrame.new(feet + Vector3.new(0, u * 5 + k, 0)) * CFrame.Angles(0, u * 14 + k * 2.1, 0) * CFrame.new(0, 0, -R * 0.5)
				band.Transparency = 0.3 + u * 0.7
			end)
		end
	end,
	sanak = function(feet, c, c2, R, dur) -- 발밑이 별 모양으로 갈라지고 돌 조각이 떠오른다
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			local crack = part(Vector3.new(0.4, 0.15, R), Color3.fromRGB(40, 28, 22), Enum.Material.Slate, 0)
			crack.CFrame = CFrame.new(feet + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -R / 2)
			local glow = part(Vector3.new(0.15, 0.16, R * 0.9), c2, Enum.Material.Neon, 0.2)
			glow.CFrame = crack.CFrame
			fadeOut(crack, dur + 0.4)
			fadeOut(glow, dur)
			local rock = part(Vector3.new(1, 0.8, 1) * (0.6 + math.random() * 0.8), ROCK, Enum.Material.Rock, 0)
			local rp = feet + Vector3.new(math.cos(a) * R * 0.6, 0.4, math.sin(a) * R * 0.6)
			rock.CFrame = CFrame.new(rp)
			fadeOut(rock, dur, { CFrame = CFrame.new(rp + Vector3.new(0, 4 + math.random() * 3, 0)) * CFrame.Angles(math.random() * 3, math.random() * 3, 0) })
		end
	end,
	binghon = function(feet, c, c2, R, dur) -- 여섯 갈래 눈꽃
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			local arm = part(Vector3.new(0.5, 0.15, R), ICE2, Enum.Material.Neon, 0.2)
			arm.CFrame = CFrame.new(feet + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -R / 2)
			fadeOut(arm, dur)
			for j = -1, 1, 2 do
				local br = part(Vector3.new(0.35, 0.15, R * 0.35), c, Enum.Material.Neon, 0.3)
				br.CFrame = CFrame.new(feet + Vector3.new(0, 0.21, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -R * 0.65) * CFrame.Angles(0, math.rad(45 * j), 0) * CFrame.new(0, 0, -R * 0.17)
				fadeOut(br, dur)
			end
		end
	end,
	cheonok = function(feet, c, c2, R, dur) -- 옥빛 육각 판이 떠올라 돈다
		sigilRing(feet, 6, R, function(k)
			return part(Vector3.new(R * 0.9, 0.3, 0.9), k % 2 == 0 and c or c2, Enum.Material.Glass, 0.1)
		end, 1.5, dur)
	end,
	cheonjong = function(feet, c, c2, R, dur) -- 금빛 동심원이 종소리처럼 차례로 퍼진다
		for k = 0, 3 do
			task.delay(k * 0.07, function()
				Fx.ring(feet + Vector3.new(0, 0.3, 0), k % 2 == 0 and c or c2, 1, R * (1.4 + k * 0.4), dur * 0.8)
			end)
		end
	end,
	myeonggyeong = function(feet, c, c2, R, dur) -- 거울 조각 넷이 둘레를 돈다
		sigilRing(feet + Vector3.new(0, 2, 0), 4, R * 0.8, function(_k)
			local g = part(Vector3.new(1.6, 2.6, 0.15), c2, Enum.Material.Glass, 0.2)
			g.Reflectance = 0.6
			return g
		end, 4, dur)
	end,
	chocheonryong = function(feet, c, c2, R, dur) -- 금빛 비늘이 나선으로 감아 오른다
		for k = 0, 11 do
			task.delay(k * 0.02, function()
				local a = k / 12 * math.pi * 3
				local p = feet + Vector3.new(math.cos(a) * R * 0.6, k * 0.5, math.sin(a) * R * 0.6)
				local sc = part(Vector3.new(1.4, 0.8, 1.8), k % 3 == 0 and JADE or GOLD, Enum.Material.Neon, 0.15)
				sc.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0.3, math.cos(a)))
				fadeOut(sc, dur * 0.8, { CFrame = sc.CFrame + Vector3.new(0, 3, 0) })
			end)
		end
	end,
	cheonha = function(feet, c, c2, R, dur) -- 붉은 원판 위에 금빛 관 가시가 솟는다
		local base = disc(feet + Vector3.new(0, 0.15, 0), R, CRIMSON, 0.4)
		fadeOut(base, dur)
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			local p = feet + Vector3.new(math.cos(a) * R, 0, math.sin(a) * R)
			local sp = part(Vector3.new(0.6, 0.2, 0.6), GOLD, Enum.Material.Neon, 0.1)
			sp.CFrame = CFrame.new(p)
			rise(sp, CFrame.new(p + Vector3.new(0, 1.2 + (k % 2), 0)), Vector3.new(0.6, 2.4 + (k % 2) * 2, 0.6), dur * 0.7, false)
		end
	end,
}
------------------------------------------------------------------------
-- 3.19.5판 오의 (G·X) 를 쓰는 순간: 예전엔 열 권법이 모두 같은 빛기둥 두 줄과 빛 껍질을 빛깔만 바꿔 썼다.
-- 이제 권법마다 제 모습으로 연다 (서로 겹치지 않는다)
------------------------------------------------------------------------
local function flatDir(a: number): Vector3
	return Vector3.new(math.cos(a), 0, math.sin(a))
end
local ULT_OPEN: { [string]: (Model, BasePart, Vector3, Color3, Color3, number, string) -> () } = {
	-- 철쇄금나수: 쇠사슬 세 가닥이 몸을 나선으로 감아 오르며 돌다가, 끝에 바깥으로 풀려 나간다
	cheolsae = function(m, _r, _feet, _c, c2, dur, _slot)
		local links = {}
		for j = 1, 3 do
			for k = 1, 16 do
				table.insert(links, { p = part(Vector3.new(0.45, 0.45, 1.1), k % 2 == 0 and IRON or IRON:Lerp(c2, 0.35), Enum.Material.Metal, 0), j = j, k = k })
			end
		end
		local life = math.clamp(dur * 0.7, 0.8, 1.6)
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local el = os.clock() - t0
			local u = el / life
			local rr = rootOf(m)
			if u >= 1 or not rr then
				conn:Disconnect()
				for _, l in ipairs(links) do
					fadeOut(l.p, 0.25)
				end
				return
			end
			local center = rr.Position - Vector3.new(0, 2.6, 0)
			local spread = u > 0.7 and (u - 0.7) / 0.3 or 0
			for _, l in ipairs(links) do
				local sN = l.k / 16
				local a = sN * math.pi * 3 + el * 7 + l.j * 2.09
				local rad = 3.2 + sN * 2 + spread * spread * 10
				local p = center + Vector3.new(math.cos(a) * rad, 0.5 + sN * 9 * math.min(1, el / 0.3), math.sin(a) * rad)
				l.p.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0.35, math.cos(a))) * CFrame.Angles(0, 0, (l.k % 2) * math.rad(90))
			end
		end)
		Fx.sound("block", 0.8, 0.5, _r.Position)
		Fx.burst("spark", _r.Position, c2, 16, 1.4)
	end,
	-- 역류반격권: 몸을 감싼 물의 장막, 발밑에서 거꾸로 감겨 드는 물살 (받아칠 자세 내내)
	yeokryu = function(m, r, feet, c, c2, dur, _slot)
		local life = math.clamp(dur, 0.8, 2)
		local dome = part(Vector3.new(1, 1, 1), c, Enum.Material.Glass, 0.6, "ball")
		dome.Position = r.Position
		tween(dome, 0.2, { Size = Vector3.new(11, 11, 11) }, Enum.EasingStyle.Back)
		local pool = disc(feet + Vector3.new(0, 0.15, 0), 1, c2, 0.5)
		tween(pool, 0.25, { Size = Vector3.new(0.2, 22, 22) })
		tornado(feet, 6.5, 9, c, c2, life, m, -1)
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local rr = rootOf(m)
			local el = os.clock() - t0
			if not rr or el > life then
				conn:Disconnect()
				fadeOut(dome, 0.3, { Size = Vector3.new(15, 15, 15) })
				fadeOut(pool, 0.3)
				return
			end
			dome.Position = rr.Position
			dome.Transparency = 0.6 + math.sin(el * 12) * 0.08
			pool.CFrame = CFrame.new(rr.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, -el * 4, math.rad(90))
		end)
		Fx.sound("splash", 0.8, 0.8, r.Position)
	end,
	-- 질풍연권: 몸에서 회오리가 솟고 바람 칼날 여섯이 둘레로 쏘아진다
	jilpung = function(m, r, feet, c, c2, dur, _slot)
		tornado(feet, 8, 18, c, c2, math.clamp(dur * 0.45, 0.7, 1.1), m, 1)
		for k = 0, 5 do
			crescent(r.Position - Vector3.new(0, 1, 0), flatDir(k / 6 * math.pi * 2), 6, k % 2 == 0 and c2 or c, 0.45, 18)
		end
		Fx.burst("dust", feet + Vector3.new(0, 0.5, 0), Color3.fromRGB(200, 210, 190), 16, 1.4)
		Fx.sound("swing", 1, 0.6, r.Position)
	end,
	-- 산악붕권: 발밑이 용암빛으로 갈라지고 뜯겨 나온 바위 여덟이 몸 둘레를 돌며 떠오른다 (힘을 모으는 1초)
	sanak = function(m, r, feet, _c, _c2, dur, _slot)
		cracks(feet, 22, 12, Color3.fromRGB(255, 140, 60), math.clamp(dur, 1, 2))
		local rocks = {}
		for k = 1, 8 do
			local q = part(Vector3.new(2.2, 1.8, 2) * (0.7 + math.random() * 0.7), ROCK:Lerp(Color3.fromRGB(110, 80, 60), math.random()), Enum.Material.Rock, 0)
			table.insert(rocks, { p = q, k = k, h = 3 + (k % 3) * 1.6 })
		end
		local life = 1.0
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local rr = rootOf(m)
			local el = os.clock() - t0
			if not rr or el > life then
				conn:Disconnect()
				-- 모은 바위가 땅으로 내리꽂힌다 (천붕지열이 터지는 순간)
				for _, o in ipairs(rocks) do
					fadeOut(o.p, 0.18, { CFrame = o.p.CFrame - Vector3.new(0, o.h + 2, 0) })
				end
				return
			end
			local c0 = rr.Position - Vector3.new(0, 2.6, 0)
			local up = math.min(1, el / 0.5)
			for _, o in ipairs(rocks) do
				local a = o.k / 8 * math.pi * 2 + el * 1.8
				local p = c0 + flatDir(a) * 7 + Vector3.new(0, o.h * up + math.sin(el * 6 + o.k) * 0.4, 0)
				o.p.CFrame = CFrame.new(p) * CFrame.Angles(el * 2 + o.k, el + o.k, 0)
			end
			if math.random() < 0.25 then
				Fx.burst("dust", c0 + flatDir(math.random() * 6.3) * 6, Color3.fromRGB(180, 160, 130), 3, 1)
			end
		end)
		lightAt(feet + Vector3.new(0, 1, 0), Color3.fromRGB(255, 140, 60), 30, 1)
		Fx.breakSound("rock", 0.8, 0.6, r.Position)
		shakeNear(r.Position, 0.6, 90)
	end,
	-- 빙혼신장: 머리 위에 큰 눈꽃이 펼쳐져 돌고 눈보라가 쏟아지며 발밑부터 서리가 번진다
	binghon = function(m, r, feet, c, _c2, dur, _slot)
		local top = r.Position + Vector3.new(0, 22, 0)
		local flake = {}
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			table.insert(flake, { p = part(Vector3.new(1.1, 0.3, 14), ICE2, Enum.Material.Neon, 0.15), rel = CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -7) })
			for j = 1, 2 do
				for sgn = -1, 1, 2 do
					table.insert(flake, { p = part(Vector3.new(0.7, 0.3, 4.5 - j), c, Enum.Material.Neon, 0.25), rel = CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -4 - j * 3.5) * CFrame.Angles(0, math.rad(45 * sgn), 0) * CFrame.new(0, 0, -(4.5 - j) / 2) })
				end
			end
		end
		local core = part(Vector3.new(3, 3, 3), ICE2, Enum.Material.Neon, 0.1, "ball")
		local sky = part(Vector3.new(50, 0.2, 50), ICE2, Enum.Material.SmoothPlastic, 1)
		sky.CFrame = CFrame.new(top + Vector3.new(0, 4, 0))
		local snow = Instance.new("ParticleEmitter")
		snow.Color = ColorSequence.new(ICE2)
		snow.LightEmission = 0.5
		snow.Size = NumberSequence.new(0.4, 0.15)
		snow.Transparency = NumberSequence.new(0.1, 1)
		snow.Lifetime = NumberRange.new(1.4, 2.2)
		snow.Rate = 160
		snow.Speed = NumberRange.new(14, 20)
		snow.SpreadAngle = Vector2.new(20, 20)
		snow.Acceleration = Vector3.new(8, -4, 0)
		snow.EmissionDirection = Enum.NormalId.Bottom
		snow.Parent = sky
		local frost = disc(feet + Vector3.new(0, 0.12, 0), 1, ICE2, 0.35, Enum.Material.Ice)
		tween(frost, 0.6, { Size = Vector3.new(0.2, 64, 64) })
		local life = math.clamp(dur, 1, 2.2)
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local el = os.clock() - t0
			local rr = rootOf(m)
			if el > life or not rr then
				conn:Disconnect()
				snow.Enabled = false
				for _, f in ipairs(flake) do
					rise(f.p, f.p.CFrame, f.p.Size, 0, true)
				end
				fadeOut(core, 0.3, { Size = Vector3.new(8, 8, 8) })
				fadeOut(frost, 0.8)
				task.delay(2.4, function()
					sky:Destroy()
				end)
				return
			end
			local g = math.min(1, el / 0.35)
			local cf = CFrame.new(top) * CFrame.Angles(0, el * 0.9, 0) * CFrame.new(0, 0, 0)
			for _, f in ipairs(flake) do
				local rel = f.rel
				f.p.CFrame = cf * CFrame.new(rel.Position * g) * rel.Rotation
			end
			core.CFrame = cf
		end)
		lightAt(top, ICE2, 60, life)
		Fx.breakSound("glass", 0.9, 0.7, r.Position)
		shakeNear(r.Position, 0.5, 100)
	end,
	-- 천옥신권: 발밑에 옥 연꽃이 두 겹으로 피고 둘레에 옥 벽 여섯 장이 솟아 육각 결계를 이룬다
	cheonok = function(_m, r, feet, c, c2, dur, _slot)
		local life = math.clamp(dur + 0.6, 1.2, 2.8)
		for layer = 1, 2 do
			local n = layer == 1 and 8 or 6
			for k = 0, n - 1 do
				local a = k / n * math.pi * 2 + (layer - 1) * 0.4
				local len = layer == 1 and 5 or 3.4
				local petal = part(Vector3.new(2.2, 0.3, len), layer == 1 and c or c2, Enum.Material.Glass, 0.15)
				local base = CFrame.new(feet + Vector3.new(0, 0.3 + layer * 0.15, 0)) * CFrame.Angles(0, a, 0)
				petal.CFrame = base * CFrame.new(0, 0, -len / 2)
				local tilt = math.rad(layer == 1 and -40 or -65)
				tween(petal, 0.4, { CFrame = base * CFrame.Angles(tilt, 0, 0) * CFrame.new(0, 0, -len / 2) }, Enum.EasingStyle.Back)
				task.delay(life, function()
					rise(petal, petal.CFrame, petal.Size, 0, true)
				end)
			end
		end
		local R = 15
		local ap = R * math.cos(math.rad(30))
		for k = 0, 5 do
			local a = (k + 0.5) / 6 * math.pi * 2
			local p = feet + flatDir(a) * ap
			local wall = part(Vector3.new(R, 0.2, 0.6), c, Enum.Material.Glass, 0.4)
			local cf = CFrame.lookAt(p, feet)
			wall.CFrame = cf
			rise(wall, cf * CFrame.new(0, 6, 0), Vector3.new(R, 12, 0.6), life, true)
			local rim = part(Vector3.new(R, 0.3, 0.7), c2, Enum.Material.Neon, 0.15)
			rim.CFrame = cf
			tween(rim, 0.12, { CFrame = cf * CFrame.new(0, 12, 0) }, Enum.EasingStyle.Back)
			task.delay(life, function()
				fadeOut(rim, 0.3)
			end)
		end
		lightAt(feet + Vector3.new(0, 4, 0), c, 40, life)
		Fx.breakSound("glass", 0.8, 1.2, r.Position)
		shakeNear(r.Position, 0.5, 90)
	end,
	-- 천종신권: 하늘에서 금빛 줄이 내려오고 몸에서 세로로 선 울림 고리가 앞뒤좌우로 퍼진다 (종은 기술이 건다)
	cheonjong = function(_m, r, _feet, c, c2, _dur, _slot)
		beamLine(r.Position + Vector3.new(0, 60, 0), r.Position + Vector3.new(0, 14, 0), 0.8, c2, 0.1, 0.8)
		for k = 0, 3 do
			task.delay(k * 0.08, function()
				Fx.ring(r.Position, k % 2 == 0 and c2 or c, 2, 14 + k * 4, 0.45, flatDir(k / 4 * math.pi))
			end)
		end
		Fx.sound("ping", 0.8, 0.4, r.Position)
	end,
	-- 명경권: 둘레에 거울이 솟아 회랑이 되고 거울과 거울 사이로 빛이 별 모양으로 오간다 (X는 더 크게, 열여섯 장)
	myeonggyeong = function(_m, r, feet, c, c2, dur, slot)
		local n = slot == "X" and 16 or 10
		local R = slot == "X" and 20 or 13
		local life = math.clamp(dur, 1, 3)
		local spots = {}
		for k = 0, n - 1 do
			local a = k / n * math.pi * 2
			local p = feet + flatDir(a) * R
			table.insert(spots, p + Vector3.new(0, 4, 0))
			task.delay(k * 0.03, function()
				local pane, rim = mirrorPane(p, feet, c, c2, 8)
				task.delay(life - k * 0.03, function()
					mirrorBreak(pane, rim)
				end)
			end)
		end
		for w = 0, math.floor(life / 0.18) - 1 do
			task.delay(0.35 + w * 0.18, function()
				local i = (w * 3) % n + 1
				local j = (i + math.floor(n / 3) - 1) % n + 1
				beamLine(spots[i], spots[j], 0.5, c2, 0.1, 0.25)
			end)
		end
		Fx.breakSound("glass", 0.7, 1.6, r.Position)
	end,
	-- 초·천룡파천장: 두 손에서 여의주가 떠올라 하늘에서 터진다 (G: 용의 소용돌이가 열린다 · X: 하늘이 세로로 갈라진다)
	chocheonryong = function(_m, r, _feet, _c, _c2, _dur, slot)
		local pearl = part(Vector3.new(2.4, 2.4, 2.4), JADE, Enum.Material.Neon, 0.05, "ball")
		local halo = part(Vector3.new(4, 4, 4), GOLD, Enum.Material.Neon, 0.6, "ball")
		pearl.Position = r.Position + Vector3.new(0, 3, 0)
		halo.Position = pearl.Position
		local top = r.Position + Vector3.new(0, slot == "X" and 44 or 32, 0)
		tween(pearl, 0.45, { Position = top }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(halo, 0.45, { Position = top })
		task.delay(0.45, function()
			fadeOut(pearl, 0.3, { Size = Vector3.new(10, 10, 10) })
			fadeOut(halo, 0.4, { Size = Vector3.new(24, 24, 24) })
			emitBurst(top, GOLD, 40, 40, 1.4, 0.9)
			Fx.ring(top, GOLD, 2, 40, 0.6)
			if slot == "X" then
				-- 하늘이 세로로 갈라지며 금빛이 쏟아진다 (보는 쪽을 향해 선 금빛 틈이 벌어진다)
				local cam = workspace.CurrentCamera
				local eye = cam and Vector3.new(cam.CFrame.Position.X, top.Y, cam.CFrame.Position.Z) or top + Vector3.new(0, 0, 1)
				local face = CFrame.lookAt(top + Vector3.new(0, 12, 0), eye + Vector3.new(0, 12, 0))
				local slit = part(Vector3.new(0.6, 70, 0.3), GOLD, Enum.Material.Neon, 0.05)
				slit.CFrame = face
				tween(slit, 0.5, { Size = Vector3.new(16, 70, 0.3) }, Enum.EasingStyle.Quad)
				task.delay(0.9, function()
					fadeOut(slit, 0.6, { Size = Vector3.new(26, 80, 0.3) })
				end)
				for sgn = -1, 1, 2 do
					local edge = part(Vector3.new(0.5, 74, 0.4), Color3.new(1, 1, 1), Enum.Material.Neon, 0)
					edge.CFrame = face
					tween(edge, 0.5, { CFrame = face * CFrame.new(sgn * 8, 0, -0.1) }, Enum.EasingStyle.Quad)
					task.delay(0.9, function()
						fadeOut(edge, 0.6)
					end)
				end
				lightAt(top, GOLD, 120, 1.5)
				if opts.flash and near(top, 160) then
					opts.flash(GOLD, 0.5)
				end
			end
		end)
		Fx.sound("ping", 0.8, 0.3, r.Position)
	end,
	-- 천하패권: 몸에서 붉은 불꽃 같은 패기가 타오르고 발밑이 금빛으로 짓눌려 갈라지며 먼지가 바깥으로 밀려난다
	cheonha = function(m, r, feet, _c, _c2, dur, slot)
		local big = slot == "X"
		local flames = {}
		for k = 1, big and 14 or 10 do
			table.insert(flames, { p = part(Vector3.new(1.4, 3.2, 1.4), k % 3 == 0 and GOLD or CRIMSON, Enum.Material.Neon, 0.3, "wedge"), k = k })
		end
		local life = math.clamp(dur * 0.6, 0.9, 1.8)
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local rr = rootOf(m)
			local el = os.clock() - t0
			if not rr or el > life then
				conn:Disconnect()
				for _, f in ipairs(flames) do
					fadeOut(f.p, 0.2, { CFrame = f.p.CFrame + Vector3.new(0, 5, 0) })
				end
				return
			end
			for _, f in ipairs(flames) do
				local a = f.k / #flames * math.pi * 2 + el * 1.5
				local flick = (el * 4 + f.k * 0.37) % 1
				local p = rr.Position - Vector3.new(0, 2.4, 0) + flatDir(a) * 2.4 + Vector3.new(0, flick * 6, 0)
				f.p.CFrame = CFrame.lookAt(p, p + flatDir(a)) * CFrame.Angles(0, math.rad(90), 0)
				f.p.Size = Vector3.new(1.4, 3.2 * (1 - flick * 0.6), 1.4) * (big and 1.4 or 1)
				f.p.Transparency = 0.25 + flick * 0.7
			end
		end)
		cracks(feet, big and 30 or 20, big and 14 or 10, GOLD, life + 0.4)
		local press = disc(feet + Vector3.new(0, 0.2, 0), 1, CRIMSON, 0.35)
		tween(press, 0.3, { Size = Vector3.new(0.2, big and 60 or 40, big and 60 or 40) })
		fadeOut(press, 0.8)
		Fx.burst("dust", feet + Vector3.new(0, 0.6, 0), Color3.fromRGB(170, 140, 110), 24, 2)
		Fx.breakSound("boom", 0.7, 0.5, r.Position)
		shakeNear(r.Position, big and 1.2 or 0.8, 120)
	end,
}
function Arts.ownsCast(styleId: any): boolean
	return type(styleId) == "string" and SIGIL[styleId] ~= nil
end
function Arts.cast(styleId: any, slot: any, model: Model, dur: number)
	local sig = type(styleId) == "string" and SIGIL[styleId]
	local r = rootOf(model)
	if not sig or not r or type(slot) == "number" or not near(r.Position, 200) then
		return
	end
	local style = Config.STYLE_BY_ID[styleId]
	local c, c2 = style.color, style.color2
	local ult = slot == "G" or slot == "X"
	local feet = r.Position - Vector3.new(0, 2.65, 0)
	local R = ult and (slot == "X" and 16 or 12) or (slot == "H" and 5 or 7)
	local d = math.clamp(dur, 0.5, 2.2)
	sig(feet, c, c2, R, d)
	handGlow(model, c, c2, math.min(dur, 1.6), ult)
	emitBurst(r.Position, c2, ult and 50 or 18, ult and 40 or 20, ult and 1.4 or 0.8, 0.8)
	lightAt(r.Position, c, ult and 40 or 18, 0.6)
	if ult then
		-- 3.19.5판: 오의는 권법마다 제 모습으로 연다 (같은 빛기둥·빛 껍질을 모두 같이 쓰지 않는다)
		local open = ULT_OPEN[styleId]
		if open then
			local ok, err = pcall(open, model, r, feet, c, c2, dur, slot)
			if not ok then
				warn("[권왕] 오의 연출 오류:", styleId, err)
			end
		end
		if opts.fov and model == Players.LocalPlayer.Character then
			opts.fov(slot == "X" and -10 or -7, 0.5)
		end
		if opts.flash and near(r.Position, 90) then
			opts.flash(c2, slot == "X" and 0.45 or 0.3)
		end
		shakeNear(r.Position, slot == "X" and 1.2 or 0.8, 120)
	end
end

local STYLE_VIS: { [string]: { [string]: (any) -> () } } = {
	myeonggyeong = { clones = mirrorClones },
	sanak = { launch = sanakLaunch, beam = sanakCollapse },
	chocheonryong = { launch = dragonSpiral, beam = noop, dragonsRise = dragonsRise, dragonDive = dragonDive, dragonsEnd = dragonsEnd, avatar = skyDragon, avatarStrike = skyDragonStrike },
	cheonha = { rushDash = overlordDash, grab = overlordGrab, grabFly = overlordFly, grabSlam = overlordSlam, charge = overlordCharge, onepunch = overlordPunch, stormcloud = overlordSeal, strike = overlordPillar },
	binghon = { freeze = binghonFreeze, erase = binghonErase },
	cheonjong = { reflect = bellGuard, wave = bellWave },
	yeokryu = { cone = coneBackflow },
}
local function styleVis(data: any): ((any) -> ())?
	local t = type(data.style) == "string" and STYLE_VIS[data.style]
	return t and t[data.kind] or nil
end

local FXKIND: { [string]: (any) -> () } = {
	pillar_ice = pillarIce, pillar_rock = pillarRock, pillar_crystal = pillarCrystal,
	strike_ice = strikeIce, strike_crystal = strikeCrystal, strike_mirror = strikeMirror,
	drop_rock = dropRock,
	zone_crystal = zoneCrystal, zone_bell = zoneBell,
	cone_bell = coneBell,
}

local HANDLERS: { [string]: (any) -> () } = {
	grab = grab,
	grabMiss = grabMiss,
	grabSlam = grabSlam,
	grabFly = grabFly,
	counterFlash = counterFlash,
	counterBurst = counterBurst,
	rushDash = rushDash,
	rushAir = rushAir,
	rushSlam = rushSlam,
	rushBurst = rushBurst,
}
local function fxKind(data: any): ((any) -> ())?
	if type(data.fx) == "string" and type(data.kind) == "string" then
		return FXKIND[data.kind .. "_" .. data.fx]
	end
	return nil
end
local SPARKLE_KINDS = { pillar = true, strike = true, pulse = true, zone = true, drop = true, freeze = true, launch = true }
PULSE.overlord = pulseOverlord
function Arts.handles(data: any): boolean
	if data.kind == "pulse" then
		return PULSE[data.fx or ""] ~= nil
	end
	return styleVis(data) ~= nil or HANDLERS[data.kind] ~= nil or fxKind(data) ~= nil
end
function Arts.run(data: any)
	local fn = data.kind == "pulse" and PULSE[data.fx or ""] or styleVis(data) or HANDLERS[data.kind] or fxKind(data)
	if fn then
		local ok, err = pcall(fn, data)
		if not ok then
			warn("[권왕] 새 권법 연출 오류:", data.kind, err)
		end
		-- 3.19.4판: 땅에서 솟고 하늘에서 꽂히는 기술마다 빛 가루와 빛을 한 겹 더
		if SPARKLE_KINDS[data.kind] and typeof(data.at) == "Vector3" then
			local c, c2 = colors(data)
			task.delay(data.kind == "pulse" and (data.delay or 0.3) or (data.kind == "strike" and 0.15 or 0.05), function()
				emitBurst(data.at, c2, 14, 26, 0.8, 0.6)
				emitBurst(data.at, c, 8, 14, 1.2, 0.8)
				lightAt(data.at, c, 22, 0.4)
			end)
		end
	end
end
return Arts
