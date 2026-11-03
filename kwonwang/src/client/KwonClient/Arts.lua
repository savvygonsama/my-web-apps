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
function Arts.handles(data: any): boolean
	if data.kind == "pulse" then
		return PULSE[data.fx or ""] ~= nil
	end
	return HANDLERS[data.kind] ~= nil
end
function Arts.run(data: any)
	local fn = data.kind == "pulse" and PULSE[data.fx or ""] or HANDLERS[data.kind]
	if fn then
		local ok, err = pcall(fn, data)
		if not ok then
			warn("[권왕] 새 권법 연출 오류:", data.kind, err)
		end
	end
end
local _ = Players
return Arts
