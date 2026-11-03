-- 권왕 3.19판: 새 권법 열하나의 화면 연출
-- 철쇄금나수 (붙잡는 쇠사슬, 메치기, 던지기) · 역류반격권 (되받아치기 번쩍임, 역류) · 질풍연권 (잔상 돌진, 공중 연격, 내리꽂기)
-- 연타 장치: 서리 (빙혼) · 옥결 (천옥) · 종소리 (천종) · 거울 분신 (명경) · 용의 이빨 (초·천룡)
-- 극 빙혼신장의 빙결 세계 (내 둘레에 눈보라와 얼음 땅이 나를 따라다닌다)
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
		table.insert(chains, { t = t, links = links })
		local r = rootOf(t)
		if r then
			Fx.spark(r.Position, c2, 1.2, 8)
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
		end
	end
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local el = os.clock() - t0
		local from = handOf(m)
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
	crater(data.at, data.radius or 8, c, c2, 1.2)
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
	Fx.ring(r.Position, c2, 1, 12, 0.3, r.CFrame.LookVector)
	Fx.ring(r.Position, c, 2, 18, 0.45)
	Fx.burst("glitter", r.Position, c2, 14, 1.2)
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
	for k = 0, 2 do
		task.delay(k * 0.08, function()
			local w = disc(g + Vector3.new(0, 0.2 + k * 0.1, 0), 1, k == 1 and c2 or c, 0.35)
			tween(w, 0.45, { Size = Vector3.new(0.2, R * 2 * (1 - k * 0.12), R * 2 * (1 - k * 0.12)) })
			fadeOut(w, 0.6)
		end)
	end
	Fx.burst("glitter", at, c2, 20, 1.6)
	Fx.burst("spark", at, c, 16, 1.4)
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
	Fx.burst("spark", b, c, 10, 1.1)
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
	Fx.sound("hit", 0.6, 1.2 + (data.k or 1) * 0.08, r.Position)
end
local function rushSlam(data: any)
	local c, c2 = colors(data)
	crater(data.at, data.radius or 8, c, c2, 1)
end
local function rushBurst(data: any)
	local c, c2 = colors(data)
	local at, R = data.at, data.radius or 12
	Fx.blast(at, c, c2, math.clamp(R / 8, 1, 2.4))
	Fx.ring(at - Vector3.new(0, 2.3, 0), c2, 1, R * 2.2, 0.4)
	-- 바람 회오리: 도는 띠 셋
	for k = 1, 3 do
		local band = part(Vector3.new(0.4, 1.2, R * 1.4), c2, Enum.Material.Neon, 0.3)
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local u = (os.clock() - t0) / 0.6
			if u >= 1 then
				conn:Disconnect()
				band:Destroy()
				return
			end
			band.CFrame = CFrame.new(at + Vector3.new(0, k * 1.5 - 1, 0)) * CFrame.Angles(0, u * 9 + k * 2, 0) * CFrame.new(0, 0, -R * 0.4 * (0.5 + u))
			band.Transparency = 0.3 + u * 0.7
		end)
	end
	Fx.sound("swing", 0.9, 0.8, at)
	shakeNear(at, 0.6, 80)
end

------------------------------------------------------------------------
-- 얼음 (빙혼·극 빙혼): 적을 얼음에 가둔다
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
local function frostLock(data: any)
	for _, m in ipairs(data.targets or {}) do
		if typeof(m) == "Instance" and m:IsA("Model") then
			iceCage(m, data.dur or 1)
		end
	end
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
-- 거울 분신: 상대 앞에 거울이 서고, 나의 잔상이 거울에서 튀어나와 친 뒤 거울이 깨진다
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
local PULSE = { frost = pulseFrost, jade = pulseJade, bell = pulseBell, mirror = pulseMirror, dragonBite = pulseDragon }

------------------------------------------------------------------------
-- 극 빙혼신장 · 빙결 세계: 내 둘레에 얼음 땅과 눈보라가 나를 따라다닌다 (Twilight가 꺼지면 녹는다)
------------------------------------------------------------------------
function Arts.frost(data: any)
	local m = data.m
	if typeof(m) ~= "Instance" then
		return
	end
	local R = data.radius or 34
	local cut, dur = data.cut or 1.4, data.dur or 30
	task.delay(cut, function()
		local r = rootOf(m)
		if not r then
			return
		end
		local floor = disc(r.Position - Vector3.new(0, 2.7, 0), 1, ICE2, 0.4, Enum.Material.Ice)
		tween(floor, 1.0, { Size = Vector3.new(0.2, R * 2, R * 2) })
		local rim = disc(r.Position - Vector3.new(0, 2.6, 0), 1, ICE, 0.55)
		tween(rim, 1.0, { Size = Vector3.new(0.2, R * 2 + 1, R * 2 + 1) })
		-- 눈보라: 위에 떠 있는 판에서 눈이 쏟아진다
		local sky = part(Vector3.new(R * 2, 0.2, R * 2), ICE2, Enum.Material.SmoothPlastic, 1)
		local snow = Instance.new("ParticleEmitter")
		snow.Color = ColorSequence.new(ICE2)
		snow.LightEmission = 0.4
		snow.Size = NumberSequence.new(0.35, 0.15)
		snow.Transparency = NumberSequence.new(0.2, 1)
		snow.Lifetime = NumberRange.new(2.5, 4)
		snow.Rate = 120
		snow.Speed = NumberRange.new(10, 16)
		snow.SpreadAngle = Vector2.new(25, 25)
		snow.Acceleration = Vector3.new(6, -6, 0)
		snow.EmissionDirection = Enum.NormalId.Bottom
		snow.Parent = sky
		Fx.flash(r.Position, ICE2, 80, 4, 0.6)
		Fx.breakSound("glass", 0.8, 0.7, r.Position)
		local t0 = os.clock()
		local lastRing = 0
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local rr = rootOf(m)
			local el = os.clock() - t0
			local over = not rr or not m.Parent or el > dur or (el > 1 and m:GetAttribute("Twilight") ~= true)
			if over then
				conn:Disconnect()
				snow.Enabled = false
				fadeOut(floor, 1.2)
				fadeOut(rim, 1.2)
				task.delay(4, function()
					sky:Destroy()
				end)
				return
			end
			local g = (rr :: BasePart).Position - Vector3.new(0, 2.7, 0)
			floor.CFrame = CFrame.new(g) * CFrame.Angles(0, 0, math.rad(90))
			rim.CFrame = CFrame.new(g + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, el * 0.3, math.rad(90))
			sky.CFrame = CFrame.new(g + Vector3.new(0, 34, 0))
			-- 1초마다 서리 고리가 바깥으로 퍼진다
			if el - lastRing > 1 then
				lastRing = el
				Fx.ring(g + Vector3.new(0, 0.4, 0), ICE, 2, R * 2, 0.8)
			end
		end)
	end)
end

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
-- 금빛 종: 내 위에 거대한 종이 비치고, 0.2초마다 울림 고리가 퍼진다
local function zoneBell(data: any)
	local c, c2 = colors(data)
	local at, R, dur = data.at, data.radius or 20, data.dur or 2
	local bell = part(Vector3.new(R * 1.1, R * 1.1, R * 1.1), c, Enum.Material.ForceField, 0.2, "ball")
	bell.CFrame = CFrame.new(at + Vector3.new(0, R * 0.25, 0))
	local lip = disc(groundAt(at) + Vector3.new(0, 0.3, 0), R * 0.6, c2, 0.4)
	bell.Size = Vector3.new(1, 1, 1)
	tween(bell, 0.3, { Size = Vector3.new(R * 1.1, R * 1.1, R * 1.1) }, Enum.EasingStyle.Back)
	local n = math.max(1, math.floor(dur / 0.2))
	for k = 0, n - 1 do
		task.delay(0.25 + k * 0.2, function()
			Fx.ring(at - Vector3.new(0, 2.3, 0), k % 2 == 0 and c2 or c, 2, R * 2.2, 0.45)
			if k % 2 == 0 then
				Fx.sound("ping", 0.6, 0.5 + (k % 4) * 0.04, at)
			end
		end)
	end
	task.delay(dur + 0.2, function()
		fadeOut(bell, 0.4, { Size = Vector3.new(R * 1.4, R * 1.4, R * 1.4) })
		fadeOut(lip, 0.4)
	end)
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
	frostLock = frostLock,
}
local function fxKind(data: any): ((any) -> ())?
	if type(data.fx) == "string" and type(data.kind) == "string" then
		return FXKIND[data.kind .. "_" .. data.fx]
	end
	return nil
end
function Arts.handles(data: any): boolean
	if data.kind == "pulse" then
		return PULSE[data.fx or ""] ~= nil
	end
	return HANDLERS[data.kind] ~= nil or fxKind(data) ~= nil
end
function Arts.run(data: any)
	local fn = data.kind == "pulse" and PULSE[data.fx or ""] or HANDLERS[data.kind] or fxKind(data)
	if fn then
		local ok, err = pcall(fn, data)
		if not ok then
			warn("[권왕] 새 권법 연출 오류:", data.kind, err)
		end
	end
end
local _ = Players
return Arts
