-- 권왕 3.17판: 처치 연출 (킬 이펙트). 쓰러뜨린 사람이 끼운 연출이 쓰러진 자리에 터진다 (둘레 사람 모두의 화면에)
-- Config.KILL_FX의 kinds (그리는 틀)를 차례로 겹쳐 그린다. 신화 연출은 금빛 테와 번쩍임이 더 붙는다
-- 한꺼번에 너무 많이 터지지 않게: 멀면 (180칸) 안 그리고, 동시에 일곱까지만
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local KillFx = {}

local folder = Instance.new("Folder")
folder.Name = "KwonKillFx"
folder.Parent = workspace

local NEON = Enum.Material.Neon
local SMOOTH = Enum.Material.SmoothPlastic
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 210, 90)
local RAINBOW = { Color3.fromRGB(255, 90, 110), Color3.fromRGB(255, 190, 70), Color3.fromRGB(255, 245, 110), Color3.fromRGB(120, 240, 140), Color3.fromRGB(100, 190, 255), Color3.fromRGB(190, 120, 255) }
local UP = Vector3.new(0, 1, 0)
local active = 0

local function rnd(a: number, b: number): number
	return a + math.random() * (b - a)
end
local function P(size: Vector3, color: Color3, mat: Enum.Material?, alpha: number?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = mat or NEON
	p.Transparency = alpha or 0
	if shape then
		p.Shape = shape
	end
	p.Parent = folder
	return p
end
local function tw(inst: Instance, t: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local x = TweenService:Create(inst, TweenInfo.new(math.max(0.01, t), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	x:Play()
	return x
end
-- 움직이며 사라진다 (끝나면 지운다)
local function fade(p: BasePart, t: number, goal: { [string]: any }?, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local g = goal or {}
	g.Transparency = 1
	tw(p, t, g, style, dir)
	task.delay(t + 0.05, function()
		p:Destroy()
	end)
end
local function rot(): CFrame
	return CFrame.Angles(rnd(0, 6.28), rnd(0, 6.28), rnd(0, 6.28))
end
-- 바닥에 눕힌 원판 (원기둥을 눕힌다)
local function disc(at: Vector3, d: number, color: Color3, alpha: number, thick: number?): Part
	local p = P(Vector3.new(thick or 0.12, d, d), color, NEON, alpha, Enum.PartType.Cylinder)
	p.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	return p
end
-- 바닥의 고리 (조각을 둘러 세운다)
local function ringParts(at: Vector3, r: number, n: number, color: Color3, w: number, alpha: number?): { Part }
	local out = {}
	for i = 0, n - 1 do
		local a0 = i / n * math.pi * 2
		local a1 = (i + 1) / n * math.pi * 2
		local p0 = at + Vector3.new(math.cos(a0) * r, 0, math.sin(a0) * r)
		local p1 = at + Vector3.new(math.cos(a1) * r, 0, math.sin(a1) * r)
		local q = P(Vector3.new(w, w * 0.5, (p1 - p0).Magnitude + 0.05), color, NEON, alpha or 0.1)
		q.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
		table.insert(out, q)
	end
	return out
end
-- 하늘에서 a → b로 꺾이며 내리는 번개 한 줄기
local function boltLine(a: Vector3, b: Vector3, color: Color3, w: number, life: number)
	local n = 7
	local prev = a
	for i = 1, n do
		local u = i / n
		local pt = a:Lerp(b, u) + (i < n and Vector3.new(rnd(-1, 1), 0, rnd(-1, 1)) * 2.2 or Vector3.zero)
		local q = P(Vector3.new(w, w, (pt - prev).Magnitude), color, NEON, 0)
		q.CFrame = CFrame.lookAt((prev + pt) / 2, pt)
		local core = P(Vector3.new(w * 0.4, w * 0.4, (pt - prev).Magnitude), WHITE, NEON, 0)
		core.CFrame = q.CFrame
		fade(q, life)
		fade(core, life * 0.7)
		prev = pt
	end
end

------------------------------------------------------------------------
-- 그리는 틀
------------------------------------------------------------------------
type Draw = (at: Vector3, c1: Color3, c2: Color3, s: number) -> ()
local K: { [string]: Draw } = {}

-- 꽃잎이 터져 흩날린다
K.petals = function(at, c1, c2, s)
	for i = 1, 24 do
		local q = P(Vector3.new(0.55, 0.08, 0.38) * s, i % 3 == 0 and c2 or c1, SMOOTH, 0)
		q.CFrame = CFrame.new(at + Vector3.new(rnd(-1, 1), rnd(0, 2), rnd(-1, 1))) * rot()
		local dir = Vector3.new(rnd(-1, 1), 0, rnd(-1, 1)).Unit
		fade(q, rnd(1.1, 1.7), { CFrame = CFrame.new(at + dir * rnd(4, 9) * s + Vector3.new(0, rnd(2, 8) * s, 0)) * rot() }, Enum.EasingStyle.Quad)
	end
	Fx.burst("glitter", at + UP * 2, c1, 16, 1.2 * s)
end

-- 회오리: 빛 알갱이가 나선으로 돌며 오른다
K.vortex = function(at, c1, c2, s)
	local parts: { { p: Part, a: number, r: number, h: number } } = {}
	for i = 1, 30 do
		local p = P(Vector3.one * rnd(0.35, 0.7) * s, i % 2 == 0 and c1 or c2, NEON, 0.1, Enum.PartType.Ball)
		table.insert(parts, { p = p, a = i / 30 * math.pi * 6, r = rnd(1.5, 3.5) * s, h = rnd(0, 1) })
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = (os.clock() - t0) / 1.3
		for _, q in ipairs(parts) do
			local a = q.a + u * 9
			local y = (q.h * 0.3 + u) * 12 * s
			local r = q.r * (1 + u * 0.8)
			q.p.CFrame = CFrame.new(at + Vector3.new(math.cos(a) * r, y, math.sin(a) * r))
			q.p.Transparency = math.clamp(0.1 + u * u, 0, 1)
		end
		if u >= 1 then
			conn:Disconnect()
			for _, q in ipairs(parts) do
				q.p:Destroy()
			end
		end
	end)
end

-- 불기둥과 불티
K.flamePillar = function(at, c1, c2, s)
	local h = 16 * s
	local outer = P(Vector3.new(0.5, 5 * s, 5 * s), c1, NEON, 0.15, Enum.PartType.Cylinder)
	outer.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	tw(outer, 0.2, { Size = Vector3.new(h, 4.4 * s, 4.4 * s), CFrame = CFrame.new(at + UP * h / 2) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(0.25, function()
		fade(outer, 0.6, { Size = Vector3.new(h * 1.2, 0.5, 0.5), CFrame = CFrame.new(at + UP * h * 0.6) * CFrame.Angles(0, 0, math.rad(90)) })
	end)
	local core = P(Vector3.new(0.5, 2 * s, 2 * s), c2, NEON, 0, Enum.PartType.Cylinder)
	core.CFrame = outer.CFrame
	tw(core, 0.18, { Size = Vector3.new(h * 1.05, 1.8 * s, 1.8 * s), CFrame = CFrame.new(at + UP * h * 0.52) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(0.2, function()
		fade(core, 0.5)
	end)
	for _ = 1, 16 do
		local q = P(Vector3.one * rnd(0.25, 0.55) * s, math.random() < 0.5 and c1 or c2, NEON, 0, Enum.PartType.Ball)
		q.CFrame = CFrame.new(at + Vector3.new(rnd(-2, 2), rnd(0, 3), rnd(-2, 2)) * s)
		fade(q, rnd(0.8, 1.4), { CFrame = q.CFrame + Vector3.new(rnd(-3, 3), rnd(8, 16), rnd(-3, 3)) * s })
	end
	Fx.flash(at + UP * 3, c1, 40, 4, 0.5)
end

-- 불의 연꽃: 꽃잎 여덟이 바닥에서 벌어진다
K.lotus = function(at, c1, c2, s)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local base = CFrame.new(at + UP * 0.3) * CFrame.Angles(0, a, 0)
		local q = P(Vector3.new(1.6, 0.15, 3.6) * s, i % 2 == 0 and c1 or c2, NEON, 0.1)
		q.CFrame = base * CFrame.new(0, 0.5, -1) * CFrame.Angles(math.rad(80), 0, 0)
		tw(q, 0.35, { CFrame = base * CFrame.new(0, 0.8 * s, -2.2 * s) * CFrame.Angles(math.rad(25), 0, 0) }, Enum.EasingStyle.Back)
		task.delay(0.7, function()
			fade(q, 0.5, { CFrame = base * CFrame.new(0, 0.2, -3.5 * s) * CFrame.Angles(math.rad(-5), 0, 0) })
		end)
	end
	local d = disc(at + UP * 0.15, 3 * s, c2, 0.2)
	fade(d, 1.1, { Size = Vector3.new(0.1, 9 * s, 9 * s) })
end

-- 벼락 하나
K.bolt = function(at, c1, _c2, s)
	boltLine(at + Vector3.new(rnd(-3, 3), 40 * s, rnd(-3, 3)), at, c1, 0.5 * s, 0.35)
	Fx.flash(at + UP * 4, c1, 60, 7, 0.35)
	Fx.ring(at + UP * 0.3, c1, 2, 14 * s, 0.4)
	Fx.burst("spark", at + UP, c1, 24, 1.3 * s)
	Fx.sound("block", 0.6, 0.6, at)
end
-- 벼락 셋이 차례로
K.bolt3 = function(at, c1, c2, s)
	for i = 0, 2 do
		task.delay(i * 0.12, function()
			local off = i == 0 and Vector3.zero or Vector3.new(rnd(-3, 3), 0, rnd(-3, 3)) * s
			boltLine(at + off + Vector3.new(rnd(-4, 4), 45 * s, rnd(-4, 4)), at + off, i == 1 and c2 or c1, 0.55 * s, 0.4)
			Fx.flash(at + UP * 4, c1, 60, 6, 0.3)
			Fx.burst("spark", at + off + UP, c1, 14, 1.2 * s)
		end)
	end
	Fx.ring(at + UP * 0.3, c1, 2, 20 * s, 0.5)
	Fx.sound("block", 0.7, 0.5, at)
end

-- 물기둥과 물보라
K.waterSpout = function(at, c1, c2, s)
	local col = P(Vector3.new(0.5, 3 * s, 3 * s), c1, Enum.Material.Glass, 0.25, Enum.PartType.Cylinder)
	col.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	local h = 13 * s
	tw(col, 0.25, { Size = Vector3.new(h, 3.4 * s, 3.4 * s), CFrame = CFrame.new(at + UP * h / 2) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(0.35, function()
		fade(col, 0.4, { Size = Vector3.new(1, 4 * s, 4 * s), CFrame = CFrame.new(at + UP * 0.5) * CFrame.Angles(0, 0, math.rad(90)) })
	end)
	task.delay(0.3, function()
		for _ = 1, 22 do
			local q = P(Vector3.one * rnd(0.3, 0.6) * s, math.random() < 0.6 and c2 or c1, Enum.Material.Glass, 0.2, Enum.PartType.Ball)
			q.CFrame = CFrame.new(at + UP * h)
			local dir = Vector3.new(rnd(-1, 1), 0, rnd(-1, 1)).Unit
			fade(q, rnd(0.6, 1), { CFrame = CFrame.new(at + dir * rnd(4, 9) * s + UP * 0.5) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		Fx.ring(at + UP * 0.3, c2, 2, 16 * s, 0.6)
	end)
	Fx.sound("splash", 0.7, 1, at)
end

-- 물결 고리 셋
K.ripple = function(at, c1, c2, s)
	for i = 0, 2 do
		task.delay(i * 0.18, function()
			local d = disc(at + UP * (0.15 + i * 0.02), 1, i == 1 and c2 or c1, 0.35, 0.08)
			fade(d, 0.9, { Size = Vector3.new(0.08, (10 + i * 4) * s, (10 + i * 4) * s) })
		end)
	end
	Fx.burst("glitter", at + UP, c2, 12, 1 * s)
	Fx.sound("splash", 0.4, 1.4, at)
end

-- 바닥의 법진: 바퀴살과 테가 돌다가 빛기둥
K.sigil = function(at, c1, c2, s)
	local g = at + UP * 0.2
	local parts: { Part } = {}
	for _, q in ipairs(ringParts(g, 5 * s, 20, c1, 0.25 * s)) do
		table.insert(parts, q)
	end
	for _, q in ipairs(ringParts(g, 3.2 * s, 16, c2, 0.18 * s)) do
		table.insert(parts, q)
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local q = P(Vector3.new(0.2 * s, 0.1, 5 * s), c1, NEON, 0.1)
		q.CFrame = CFrame.new(g) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -2.5 * s)
		table.insert(parts, q)
	end
	local rel: { CFrame } = {}
	for i, q in ipairs(parts) do
		rel[i] = CFrame.new(g):ToObjectSpace(q.CFrame)
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = (os.clock() - t0) / 0.9
		local cf = CFrame.new(g) * CFrame.Angles(0, u * 4, 0)
		for i, q in ipairs(parts) do
			q.CFrame = cf * rel[i]
			q.Transparency = 0.1 + math.max(0, u - 0.6) * 2
		end
		if u >= 1 then
			conn:Disconnect()
			for _, q in ipairs(parts) do
				q:Destroy()
			end
		end
	end)
	task.delay(0.55, function()
		local beam = P(Vector3.new(30 * s, 2.5 * s, 2.5 * s), c2, NEON, 0.1, Enum.PartType.Cylinder)
		beam.CFrame = CFrame.new(at + UP * 15 * s) * CFrame.Angles(0, 0, math.rad(90))
		fade(beam, 0.45, { Size = Vector3.new(34 * s, 0.3, 0.3) })
		Fx.flash(at + UP * 3, c1, 50, 5, 0.4)
	end)
end

-- 엇갈린 칼자국 둘
K.slashX = function(at, c1, c2, s)
	local c = at + UP * 2.5
	for i, a in ipairs({ 40, -40 }) do
		task.delay((i - 1) * 0.08, function()
			local cf = CFrame.lookAt(c, c + Vector3.new(rnd(-1, 1), 0, rnd(-1, 1))) * CFrame.Angles(0, 0, math.rad(a))
			local q = P(Vector3.new(0.25 * s, 9 * s, 0.1), c1, NEON, 0)
			q.CFrame = cf
			local edge = P(Vector3.new(0.6 * s, 9.5 * s, 0.05), c2, SMOOTH, 0.3)
			edge.CFrame = cf * CFrame.new(0.2, 0, 0)
			q.Size = Vector3.new(0.25 * s, 0.5, 0.1)
			tw(q, 0.08, { Size = Vector3.new(0.25 * s, 9 * s, 0.1) })
			task.delay(0.25, function()
				fade(q, 0.35, { Size = Vector3.new(0.05, 11 * s, 0.05) })
				fade(edge, 0.3)
			end)
			Fx.burst("spark", c, c1, 10, 1 * s)
		end)
	end
	Fx.sound("swing", 0.6, 1.3, at)
end
-- 붉은 방울이 튄다
K.bloodDrops = function(at, c1, c2, s)
	for i = 1, 18 do
		local q = P(Vector3.one * rnd(0.25, 0.5) * s, i % 3 == 0 and c2 or c1, SMOOTH, 0, Enum.PartType.Ball)
		q.CFrame = CFrame.new(at + UP * 2)
		local dir = Vector3.new(rnd(-1, 1), 0, rnd(-1, 1)).Unit
		fade(q, rnd(0.5, 0.9), { CFrame = CFrame.new(at + dir * rnd(3, 7) * s + UP * 0.2) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	local pool = disc(at + UP * 0.1, 1, c2, 0.2, 0.06)
	fade(pool, 1.4, { Size = Vector3.new(0.06, 6 * s, 6 * s) })
end

-- 해와 달이 돌다가 부딪힌다
K.orbits = function(at, c1, c2, s)
	local sun = P(Vector3.one * 1.6 * s, c1, NEON, 0, Enum.PartType.Ball)
	local moon = P(Vector3.one * 1.3 * s, c2, NEON, 0, Enum.PartType.Ball)
	local c = at + UP * 3
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.min(1, (os.clock() - t0) / 0.8)
		local r = (1 - u) * 4.5 * s
		local a = u * 14
		sun.CFrame = CFrame.new(c + Vector3.new(math.cos(a) * r, math.sin(a * 0.5) * r * 0.3, math.sin(a) * r))
		moon.CFrame = CFrame.new(c - Vector3.new(math.cos(a) * r, math.sin(a * 0.5) * r * 0.3, math.sin(a) * r))
		if u >= 1 then
			conn:Disconnect()
			sun:Destroy()
			moon:Destroy()
			local b = P(Vector3.one * 2 * s, WHITE, NEON, 0, Enum.PartType.Ball)
			b.CFrame = CFrame.new(c)
			fade(b, 0.4, { Size = Vector3.one * 11 * s })
			Fx.ring(c, c1, 2, 18 * s, 0.4)
			Fx.ring(c + UP * 0.3, c2, 2, 14 * s, 0.4)
			Fx.flash(c, c1, 60, 7, 0.4)
			Fx.sound("heavy", 0.6, 1, c)
		end
	end)
end

-- 검은 화소로 지워진다
K.pixels = function(at, c1, c2, s)
	for i = 1, 26 do
		local col = i % 5 == 0 and c2 or (i % 2 == 0 and c1 or WHITE)
		local q = P(Vector3.one * rnd(0.4, 0.9) * s, col, col == WHITE and NEON or SMOOTH, 0)
		q.CFrame = CFrame.new(at + Vector3.new(rnd(-1.5, 1.5), rnd(0, 5), rnd(-1.5, 1.5)) * s)
		-- 돌지 않고 곧게, 툭툭 끊기듯
		local goal = q.CFrame + Vector3.new(rnd(-4, 4), rnd(1, 6), rnd(-4, 4)) * s
		task.delay(rnd(0, 0.25), function()
			fade(q, 0.4, { CFrame = goal }, Enum.EasingStyle.Linear)
		end)
	end
	local box = P(Vector3.new(4, 6, 4) * s, c1, SMOOTH, 0.05)
	box.CFrame = CFrame.new(at + UP * 3 * s)
	fade(box, 0.25, { Size = Vector3.new(0.1, 6, 0.1) * s })
	Fx.sound("shatter", 0.5, 1.8, at)
end

-- 몽실한 구름
K.clouds = function(at, c1, c2, s)
	for i = 1, 12 do
		local q = P(Vector3.one * rnd(2, 3.6) * s, i % 3 == 0 and c2 or c1, SMOOTH, 0.15, Enum.PartType.Ball)
		local a = i / 12 * math.pi * 2
		q.CFrame = CFrame.new(at + Vector3.new(math.cos(a) * 1.5, rnd(0.5, 2), math.sin(a) * 1.5) * s)
		fade(q, rnd(1.1, 1.6), { CFrame = CFrame.new(at + Vector3.new(math.cos(a) * rnd(4, 6), rnd(3, 6), math.sin(a) * rnd(4, 6)) * s), Size = q.Size * 1.6 })
	end
end

-- 별빛 고리와 오르는 별
K.stars = function(at, c1, c2, s)
	Fx.ring(at + UP * 0.4, c1, 2, 18 * s, 0.6)
	for i = 1, 16 do
		local q = P(Vector3.new(0.5, 0.5, 0.12) * s, i % 2 == 0 and c2 or WHITE, NEON, 0)
		q.CFrame = CFrame.new(at + Vector3.new(rnd(-3, 3), rnd(0.5, 2), rnd(-3, 3)) * s) * CFrame.Angles(0, rnd(0, 6), math.rad(45))
		local q2 = P(Vector3.new(0.5, 0.5, 0.12) * s, q.Color, NEON, 0)
		q2.CFrame = q.CFrame * CFrame.Angles(0, 0, math.rad(45))
		local goal = CFrame.new(q.Position + Vector3.new(rnd(-2, 2), rnd(10, 18), rnd(-2, 2)) * s)
		local life = rnd(1.2, 1.8)
		fade(q, life, { CFrame = goal * CFrame.Angles(0, 0, math.rad(45)) })
		fade(q2, life, { CFrame = goal })
	end
	Fx.burst("glitter", at + UP * 2, c2, 26, 1.4 * s)
end

-- 빛의 시계판: 눈금 열둘과 바늘 둘이 거꾸로 돌다가 깨진다
K.clock = function(at, c1, c2, s)
	local c = at + UP * 4 * s
	local face = CFrame.lookAt(c, c + Vector3.new(0, 0, 1))
	local parts: { Part } = {}
	local rim = P(Vector3.new(0.15, 7 * s, 7 * s), c1, NEON, 0.55, Enum.PartType.Cylinder)
	rim.CFrame = face * CFrame.Angles(0, math.rad(90), 0)
	table.insert(parts, rim)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local q = P(Vector3.new(0.2, i % 3 == 0 and 0.9 or 0.5, 0.2) * s, c2, NEON, 0)
		q.CFrame = face * CFrame.Angles(0, 0, a) * CFrame.new(0, 3 * s, 0)
		table.insert(parts, q)
	end
	local hour = P(Vector3.new(0.3, 2 * s, 0.25), c2, NEON, 0)
	local minute = P(Vector3.new(0.2, 3 * s, 0.25), WHITE, NEON, 0)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.min(1, (os.clock() - t0) / 0.9)
		hour.CFrame = face * CFrame.Angles(0, 0, u * 4) * CFrame.new(0, 1 * s, -0.1)
		minute.CFrame = face * CFrame.Angles(0, 0, u * 20) * CFrame.new(0, 1.5 * s, -0.12)
		if u >= 1 then
			conn:Disconnect()
			hour:Destroy()
			minute:Destroy()
			for _, q in ipairs(parts) do
				fade(q, 0.45, { CFrame = q.CFrame + Vector3.new(rnd(-3, 3), rnd(-3, 1), rnd(-3, 3)) * s })
			end
			Fx.sound("shatter", 0.6, 1.3, c)
			Fx.flash(c, c1, 40, 5, 0.3)
		end
	end)
end

-- 덩굴이 솟아 감았다가 잎으로
K.leaves = function(at, c1, c2, s)
	for v = 0, 3 do
		local a0 = v / 4 * math.pi * 2
		for i = 1, 8 do
			task.delay(i * 0.03, function()
				local a = a0 + i * 0.5
				local r = 1.6 * s
				local q = P(Vector3.new(0.35, 1.4, 0.35) * s, c1:Lerp(Color3.new(0.2, 0.35, 0.15), 0.4), SMOOTH, 0)
				q.CFrame = CFrame.new(at + Vector3.new(math.cos(a) * r, i * 0.9 * s, math.sin(a) * r)) * CFrame.Angles(rnd(-0.4, 0.4), a, rnd(-0.4, 0.4))
				task.delay(0.55, function()
					fade(q, 0.3)
				end)
			end)
		end
	end
	task.delay(0.55, function()
		for i = 1, 22 do
			local q = P(Vector3.new(0.6, 0.06, 0.35) * s, i % 2 == 0 and c1 or c2, SMOOTH, 0)
			q.CFrame = CFrame.new(at + Vector3.new(rnd(-2, 2), rnd(2, 7), rnd(-2, 2)) * s) * rot()
			fade(q, rnd(0.9, 1.4), { CFrame = CFrame.new(q.Position + Vector3.new(rnd(-6, 6), rnd(-2, 3), rnd(-6, 6)) * s) * rot() })
		end
	end)
end

-- 나비 떼
K.butterflies = function(at, c1, c2, s)
	for i = 1, 9 do
		local col = i % 2 == 0 and c1 or c2
		local l = P(Vector3.new(0.7, 0.05, 0.9) * s, col, NEON, 0.15)
		local r = P(Vector3.new(0.7, 0.05, 0.9) * s, col, NEON, 0.15)
		local start = at + Vector3.new(rnd(-1, 1), rnd(1, 2.5), rnd(-1, 1)) * s
		local dest = start + Vector3.new(rnd(-6, 6), rnd(6, 12), rnd(-6, 6)) * s
		local ph = rnd(0, 6)
		local t0 = os.clock()
		local life = rnd(1.3, 1.9)
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local u = math.min(1, (os.clock() - t0) / life)
			local pos = start:Lerp(dest, u) + Vector3.new(math.sin(u * 9 + ph), 0, math.cos(u * 7 + ph)) * s
			local flap = math.sin((os.clock() - t0) * 26 + ph) * 0.9
			local base = CFrame.lookAt(pos, pos + (dest - start).Unit)
			l.CFrame = base * CFrame.Angles(0, 0, flap) * CFrame.new(-0.35 * s, 0, 0)
			r.CFrame = base * CFrame.Angles(0, 0, -flap) * CFrame.new(0.35 * s, 0, 0)
			l.Transparency = 0.15 + u * u * 0.85
			r.Transparency = l.Transparency
			if u >= 1 then
				conn:Disconnect()
				l:Destroy()
				r:Destroy()
			end
		end)
	end
	Fx.burst("glitter", at + UP * 2, c2, 14, 1 * s)
end

-- 술독이 떨어져 깨진다
K.jar = function(at, c1, c2, s)
	local jar = P(Vector3.new(2.2, 2.6, 2.2) * s, Color3.fromRGB(120, 80, 50), SMOOTH, 0, Enum.PartType.Ball)
	jar.CFrame = CFrame.new(at + UP * 14 * s)
	tw(jar, 0.3, { CFrame = CFrame.new(at + UP * 1.2 * s) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.3, function()
		jar:Destroy()
		for _ = 1, 10 do
			local q = P(Vector3.new(rnd(0.5, 1), 0.2, rnd(0.4, 0.8)) * s, Color3.fromRGB(120, 80, 50), SMOOTH, 0)
			q.CFrame = CFrame.new(at + UP * s) * rot()
			fade(q, 0.7, { CFrame = CFrame.new(at + Vector3.new(rnd(-4, 4), 0.2, rnd(-4, 4)) * s) * rot() })
		end
		for i = 1, 16 do
			local q = P(Vector3.one * rnd(0.25, 0.45) * s, i % 2 == 0 and c1 or c2, Enum.Material.Glass, 0.2, Enum.PartType.Ball)
			q.CFrame = CFrame.new(at + UP * s)
			fade(q, rnd(0.6, 1), { CFrame = CFrame.new(at + Vector3.new(rnd(-5, 5), rnd(2, 5), rnd(-5, 5)) * s) })
		end
		local pool = disc(at + UP * 0.08, 1, c1, 0.3, 0.06)
		fade(pool, 1.3, { Size = Vector3.new(0.06, 7 * s, 7 * s) })
		Fx.sound("shatter", 0.7, 0.9, at)
	end)
end

-- 태극: 흑백 반원 둘이 돌다가 오그라든다
K.taiji = function(at, c1, c2, s)
	local g = at + UP * 0.25
	local d = 9 * s
	local parts: { { p: Part, rel: CFrame } } = {}
	local function add(p: Part, rel: CFrame)
		table.insert(parts, { p = p, rel = rel })
	end
	-- 바깥 테
	for _, q in ipairs(ringParts(g, d / 2, 24, c1, 0.25 * s)) do
		add(q, CFrame.new(g):ToObjectSpace(q.CFrame))
	end
	-- 두 반쪽 (얇은 판 둘) 과 두 점
	add(P(Vector3.new(d / 2, 0.08, d), c1, NEON, 0.3), CFrame.new(-d / 4, 0, 0))
	add(P(Vector3.new(d / 2, 0.08, d), c2, SMOOTH, 0.1), CFrame.new(d / 4, 0, 0))
	add(P(Vector3.new(0.12, d / 4, d / 4), c2, SMOOTH, 0, Enum.PartType.Cylinder), CFrame.new(0, 0.06, -d / 4) * CFrame.Angles(0, 0, math.rad(90)))
	add(P(Vector3.new(0.12, d / 4, d / 4), c1, NEON, 0, Enum.PartType.Cylinder), CFrame.new(0, 0.06, d / 4) * CFrame.Angles(0, 0, math.rad(90)))
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.min(1, (os.clock() - t0) / 1.1)
		local k = u < 0.7 and 1 or math.max(0.02, 1 - (u - 0.7) / 0.3)
		local cf = CFrame.new(g) * CFrame.Angles(0, u * 8, 0)
		for _, it in ipairs(parts) do
			local r = it.rel
			it.p.CFrame = cf * CFrame.new(r.Position * k) * r.Rotation
		end
		if u >= 1 then
			conn:Disconnect()
			for _, it in ipairs(parts) do
				it.p:Destroy()
			end
			local b = P(Vector3.one * 1.5 * s, WHITE, NEON, 0, Enum.PartType.Ball)
			b.CFrame = CFrame.new(g + UP)
			fade(b, 0.35, { Size = Vector3.one * 8 * s })
			Fx.sound("ping", 0.5, 1.2, g)
		end
	end)
end

-- 서서 도는 수레바퀴
K.wheel = function(at, c1, c2, s)
	local c = at + UP * 4.5 * s
	local face = CFrame.lookAt(c, c + Vector3.new(rnd(-1, 1), 0, rnd(-1, 1)))
	local parts: { { p: Part, rel: CFrame } } = {}
	local r = 3.6 * s
	for i = 0, 15 do
		local a0, a1 = i / 16 * math.pi * 2, (i + 1) / 16 * math.pi * 2
		local p0 = Vector3.new(math.cos(a0) * r, math.sin(a0) * r, 0)
		local p1 = Vector3.new(math.cos(a1) * r, math.sin(a1) * r, 0)
		local q = P(Vector3.new(0.3 * s, 0.3 * s, (p1 - p0).Magnitude + 0.05), c1, NEON, 0.05)
		table.insert(parts, { p = q, rel = CFrame.lookAt((p0 + p1) / 2, p1) })
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local q = P(Vector3.new(0.18 * s, r * 2, 0.18 * s), c2, NEON, 0.1)
		table.insert(parts, { p = q, rel = CFrame.Angles(0, 0, a) })
	end
	local hub = P(Vector3.one * 1.1 * s, c2, NEON, 0, Enum.PartType.Ball)
	table.insert(parts, { p = hub, rel = CFrame.new() })
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.min(1, (os.clock() - t0) / 1.0)
		local cf = face * CFrame.Angles(0, 0, u * 10) * CFrame.new(0, 0, 0)
		local k = math.min(1, u * 5)
		for _, it in ipairs(parts) do
			it.p.CFrame = cf * CFrame.new(it.rel.Position * k) * it.rel.Rotation
			it.p.Transparency = math.max(it.p.Transparency, (u - 0.75) * 4)
		end
		if u >= 1 then
			conn:Disconnect()
			for _, it in ipairs(parts) do
				fade(it.p, 0.3, { CFrame = it.p.CFrame + (it.p.Position - c).Unit * 3 * s })
			end
		end
	end)
	Fx.sound("deflect", 0.5, 0.8, c)
end

-- 거울 조각
K.shards = function(at, c1, c2, s)
	for i = 1, 18 do
		local q = P(Vector3.new(rnd(0.6, 1.4), rnd(0.8, 1.8), 0.08) * s, i % 3 == 0 and c2 or c1, Enum.Material.Glass, 0.15)
		q.Reflectance = 0.6
		q.CFrame = CFrame.new(at + Vector3.new(rnd(-1, 1), rnd(1.5, 4), rnd(-1, 1)) * s) * rot()
		fade(q, rnd(0.8, 1.3), { CFrame = CFrame.new(q.Position + Vector3.new(rnd(-6, 6), rnd(-1, 4), rnd(-6, 6)) * s) * rot() })
	end
	Fx.burst("glitter", at + UP * 2, c2, 20, 1.2 * s)
	Fx.sound("shatter", 0.7, 1.4, at)
end

-- 구멍이 열려 빨아들이고 닫힌다
K.void = function(at, c1, c2, s)
	local c = at + UP * 2.5 * s
	local hole = P(Vector3.one * 0.5, c2, SMOOTH, 0, Enum.PartType.Ball)
	hole.CFrame = CFrame.new(c)
	local rim = P(Vector3.one * 0.6, c1, NEON, 0.5, Enum.PartType.Ball)
	rim.CFrame = CFrame.new(c)
	tw(hole, 0.3, { Size = Vector3.one * 5 * s })
	tw(rim, 0.3, { Size = Vector3.one * 5.8 * s })
	for _ = 1, 18 do
		local q = P(Vector3.one * rnd(0.25, 0.5) * s, c1, NEON, 0, Enum.PartType.Ball)
		q.CFrame = CFrame.new(c + Vector3.new(rnd(-1, 1), rnd(-1, 1), rnd(-1, 1)).Unit * rnd(6, 10) * s)
		fade(q, rnd(0.4, 0.7), { CFrame = CFrame.new(c) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	task.delay(0.75, function()
		fade(hole, 0.2, { Size = Vector3.one * 0.1 })
		fade(rim, 0.2, { Size = Vector3.one * 0.1 })
		Fx.ring(c, c1, 2, 14 * s, 0.35)
		Fx.sound("heavy", 0.6, 0.6, c)
	end)
end

-- 용 한 마리가 나선으로 감아 오른다 (머리 + 몸 마디 + 꼬리)
K.dragon = function(at, c1, c2, s)
	local n = 22
	local segs: { Part } = {}
	for i = 1, n do
		local w = (i == 1 and 1.6 or 1.2 * (1 - i / n * 0.7)) * s
		local q = P(Vector3.new(w, w, w * 1.4), i == 1 and c2 or c1, NEON, 0.05, if i == 1 then nil else Enum.PartType.Ball)
		table.insert(segs, q)
	end
	-- 뿔 둘
	local horns = { P(Vector3.new(0.2, 0.2, 1.4) * s, c2, NEON, 0), P(Vector3.new(0.2, 0.2, 1.4) * s, c2, NEON, 0) }
	local t0 = os.clock()
	local function pathAt(u: number): Vector3
		local a = u * math.pi * 5
		local r = (3.2 - u * 1.2) * s
		return at + Vector3.new(math.cos(a) * r, u * 22 * s, math.sin(a) * r)
	end
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local T = (os.clock() - t0) / 1.6
		for i, q in ipairs(segs) do
			local u = math.clamp(T - i * 0.025, 0, 1)
			local p0, p1 = pathAt(u), pathAt(math.min(1, u + 0.01))
			q.CFrame = CFrame.lookAt(p0, p1 + (p1 - p0).Unit * 0.01)
			q.Transparency = math.clamp(T - 0.75, 0, 1) * 4 + (u <= 0 and 1 or 0)
		end
		local head = segs[1].CFrame
		horns[1].CFrame = head * CFrame.new(-0.5 * s, 0.6 * s, 0.6 * s) * CFrame.Angles(math.rad(-30), math.rad(-15), 0)
		horns[2].CFrame = head * CFrame.new(0.5 * s, 0.6 * s, 0.6 * s) * CFrame.Angles(math.rad(-30), math.rad(15), 0)
		horns[1].Transparency = segs[1].Transparency
		horns[2].Transparency = segs[1].Transparency
		if T >= 1.05 then
			conn:Disconnect()
			for _, q in ipairs(segs) do
				q:Destroy()
			end
			horns[1]:Destroy()
			horns[2]:Destroy()
		end
	end)
	Fx.ring(at + UP * 0.3, c1, 2, 20 * s, 0.6)
	task.delay(1.2, function()
		Fx.burst("glitter", at + UP * 20 * s, c2, 30, 1.6 * s)
		Fx.flash(at + UP * 18 * s, c2, 60, 6, 0.4)
	end)
	Fx.sound("deflect", 0.7, 0.6, at)
end

-- 운석: 하늘에서 불덩이가 떨어져 땅이 패인다
K.meteor = function(at, c1, c2, s)
	local from = at + Vector3.new(rnd(-20, 20), 60, rnd(-20, 20)) * s
	local rock = P(Vector3.one * 3 * s, Color3.fromRGB(70, 50, 40), Enum.Material.Basalt, 0, Enum.PartType.Ball)
	local glow = P(Vector3.one * 4.2 * s, c1, NEON, 0.35, Enum.PartType.Ball)
	rock.CFrame = CFrame.new(from)
	glow.CFrame = CFrame.new(from)
	tw(rock, 0.45, { CFrame = CFrame.new(at + UP) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw(glow, 0.45, { CFrame = CFrame.new(at + UP) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for i = 1, 8 do
		task.delay(i * 0.045, function()
			local tail = P(Vector3.one * (2.6 - i * 0.2) * s, i % 2 == 0 and c1 or c2, NEON, 0.2, Enum.PartType.Ball)
			tail.CFrame = CFrame.new(from:Lerp(at, (i * 0.045 / 0.45) ^ 2))
			fade(tail, 0.35)
		end)
	end
	task.delay(0.45, function()
		rock:Destroy()
		glow:Destroy()
		local crater = disc(at + UP * 0.1, 1, Color3.fromRGB(40, 30, 25), 0, 0.15)
		crater.Material = SMOOTH
		tw(crater, 0.15, { Size = Vector3.new(0.15, 9 * s, 9 * s) })
		task.delay(1.2, function()
			fade(crater, 0.6)
		end)
		for _ = 1, 14 do
			local q = P(Vector3.one * rnd(0.5, 1.1) * s, Color3.fromRGB(90, 70, 55), Enum.Material.Basalt, 0)
			q.CFrame = CFrame.new(at + UP) * rot()
			fade(q, rnd(0.6, 1), { CFrame = CFrame.new(at + Vector3.new(rnd(-8, 8), rnd(2, 6), rnd(-8, 8)) * s) * rot() })
		end
		K.flamePillar(at, c1, c2, s * 0.8)
		Fx.ring(at + UP * 0.3, c1, 3, 28 * s, 0.6)
		Fx.flash(at + UP * 4, c1, 60, 9, 0.5)
		Fx.sound("heavy", 1, 0.5, at)
	end)
end

-- 무지개 고리 여섯
K.rainbow = function(at, _c1, _c2, s)
	for i, col in ipairs(RAINBOW) do
		task.delay((i - 1) * 0.07, function()
			local d = disc(at + UP * (0.15 + i * 0.03), 1, col, 0.25, 0.1)
			fade(d, 0.9, { Size = Vector3.new(0.1, (8 + i * 2.4) * s, (8 + i * 2.4) * s) })
		end)
	end
	local arc = {}
	for i, col in ipairs(RAINBOW) do
		for k = 0, 10 do
			local a = k / 10 * math.pi
			local r = (5 + i * 0.45) * s
			local q = P(Vector3.new(0.45, 0.45, 1.6) * s, col, NEON, 0.15)
			q.CFrame = CFrame.lookAt(at + Vector3.new(math.cos(a) * r, math.sin(a) * r, 0), at + Vector3.new(math.cos(a + 0.1) * r, math.sin(a + 0.1) * r, 0))
			table.insert(arc, q)
		end
	end
	task.delay(0.6, function()
		for _, q in ipairs(arc) do
			fade(q, 0.6)
		end
	end)
end

-- 금빛 주먹 왕관: 주먹 다섯이 둘러서 위로
K.crown = function(at, c1, c2, s)
	local c = at + UP * 6 * s
	local band = ringParts(c, 2.6 * s, 18, c1, 0.4 * s, 0)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		local fist = P(Vector3.new(1, 1.2, 1) * s, c1, NEON, 0)
		fist.CFrame = CFrame.new(c + Vector3.new(math.cos(a) * 2.6, 1.2, math.sin(a) * 2.6) * s) * CFrame.Angles(0, -a, 0)
		local gem = P(Vector3.one * 0.5 * s, c2, NEON, 0, Enum.PartType.Ball)
		gem.CFrame = fist.CFrame * CFrame.new(0, 0.8 * s, 0)
		table.insert(band, fist)
		table.insert(band, gem)
	end
	for _, q in ipairs(band) do
		local cf = q.CFrame
		q.CFrame = cf - UP * 4 * s
		q.Transparency = 1
		tw(q, 0.35, { CFrame = cf, Transparency = 0 }, Enum.EasingStyle.Back)
		task.delay(0.9, function()
			fade(q, 0.4, { CFrame = cf + UP * 6 * s })
		end)
	end
	task.delay(0.35, function()
		Fx.flash(c, c1, 60, 7, 0.4)
		Fx.burst("glitter", c, c2, 24, 1.4 * s)
		Fx.sound("ping", 0.7, 0.9, c)
	end)
end

-- 빛나는 책장이 펼쳐져 날아오른다
K.pages = function(at, c1, c2, s)
	for i = 1, 14 do
		local q = P(Vector3.new(1.2, 0.04, 1.6) * s, i % 2 == 0 and c2 or WHITE, NEON, 0.1)
		q.CFrame = CFrame.new(at + UP * 2.5 * s) * CFrame.Angles(0, i * 0.45, 0)
		local a = i / 14 * math.pi * 2
		local goal = CFrame.new(at + Vector3.new(math.cos(a) * rnd(4, 7), rnd(5, 12), math.sin(a) * rnd(4, 7)) * s) * CFrame.Angles(rnd(-0.8, 0.8), a, rnd(-0.8, 0.8))
		task.delay(i * 0.03, function()
			fade(q, rnd(1.1, 1.5), { CFrame = goal })
		end)
	end
	Fx.burst("glitter", at + UP * 2, c1, 18, 1.2 * s)
end

------------------------------------------------------------------------
-- 신화: 금빛 테 둘과 번쩍임이 더 붙는다
local function mythicHalo(at: Vector3, def: any)
	Fx.ring(at + UP * 0.4, GOLD, 3, 30, 0.7)
	task.delay(0.12, function()
		Fx.ring(at + UP * 0.8, def.c1, 3, 24, 0.6)
	end)
	Fx.flash(at + UP * 4, GOLD, 60, 8, 0.6)
	Fx.burst("glitter", at + UP * 3, GOLD, 36, 1.8)
end

-- 연출 하나를 그린다. at = 쓰러진 자리 (몸 가운데), force = 거리·개수 제한 무시 (미리보기)
function KillFx.play(id: string, at: Vector3, force: boolean?)
	local def = Config.KILL_FX_BY_ID[id]
	if not def then
		return
	end
	local cam = workspace.CurrentCamera
	if not force then
		if not cam or (cam.CFrame.Position - at).Magnitude > 180 or active >= 7 then
			return
		end
	end
	active += 1
	task.delay(2, function()
		active -= 1
	end)
	local g = at - Vector3.new(0, 2.6, 0)
	local s = def.mythic and 1.3 or 1
	for _, kind in ipairs(def.kinds) do
		local fn = K[kind]
		if fn then
			local ok, err = pcall(fn, g, def.c1, def.c2, s)
			if not ok then
				warn("[권왕] 처치 연출 " .. id .. "/" .. kind .. ": " .. tostring(err))
			end
		end
	end
	if def.mythic then
		mythicHalo(g, def)
	end
end

-- 미리보기: 내 앞 8칸에서 터뜨린다
function KillFx.preview(id: string)
	local ch = game:GetService("Players").LocalPlayer.Character
	local r = ch and ch:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
		look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
		KillFx.play(id, r.Position + look * 9, true)
	end
end

KillFx.kinds = K
return KillFx
