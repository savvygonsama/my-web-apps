-- 권왕 2.7판: 만목신권의 숲 (화면). 대나무 창 · 소용돌이치는 잎 · 천 년 은행나무
-- 가시·꽃봉오리·나무 정령 대신 곧고 깨끗한 생김새로: 마디가 있는 대나무, 납작한 타원 잎, 풀결 재질의 금빛 우듬지
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Forest = {}
local _player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "KwonForest"
folder.Parent = workspace

local opts: any = {}
function Forest.init(o: any)
	opts = o or {}
end

local BAMBOO = Color3.fromRGB(104, 160, 64)
local BAMBOO2 = Color3.fromRGB(136, 182, 78)
local NODE = Color3.fromRGB(176, 196, 112)
local LEAF = Color3.fromRGB(78, 140, 56)
local LEAF2 = Color3.fromRGB(122, 180, 80)
local BARK = Color3.fromRGB(96, 74, 56)
local BARK2 = Color3.fromRGB(74, 56, 42)
local GOLD = Color3.fromRGB(240, 196, 60)
local GOLD2 = Color3.fromRGB(252, 220, 96)
local GOLD3 = Color3.fromRGB(222, 168, 40)
local EARTH = Color3.fromRGB(110, 86, 60)
local WHITE = Color3.new(1, 1, 1)

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
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
local function ground(at: Vector3): Vector3
	return Vector3.new(at.X, at.Y - 2.7, at.Z)
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
local UP = CFrame.Angles(0, 0, math.rad(90))

-- 묶음: 조각마다 (기준 위치, 크기)를 기억해 두고 한꺼번에 옮기고 키운다
type Piece = { p: BasePart, off: CFrame, size: Vector3, alpha: number }
local function addTo(list: { Piece }, size: Vector3, off: CFrame, color: Color3, mat: Enum.Material?, alpha: number?, shape: string?): BasePart
	local p = part(size, color, mat, alpha, shape)
	table.insert(list, { p = p, off = off, size = size, alpha = alpha or 0 })
	return p
end
local function placeAll(list: { Piece }, cf: CFrame, g: number?)
	local k = g or 1
	for _, pc in ipairs(list) do
		if pc.p.Parent then
			if k ~= 1 then
				pc.p.Size = pc.size * math.max(0.02, k)
				pc.p.CFrame = cf * CFrame.new(pc.off.Position * k) * pc.off.Rotation
			else
				pc.p.CFrame = cf * pc.off
			end
		end
	end
end

------------------------------------------------------------------------
-- 잎 한 장 (납작한 타원). 떨어지거나 날아가는 잎
------------------------------------------------------------------------
local function leaf(size: number, color: Color3): BasePart
	return part(Vector3.new(0.05, size * 0.4, size), color, Enum.Material.SmoothPlastic, 0, "ball")
end
-- 지는 잎: 흔들리며 내려앉는다
local function fallingLeaf(at: Vector3, color: Color3, size: number, fall: number, life: number)
	local p = leaf(size, color)
	local t0 = os.clock()
	local ph = math.random() * 6
	local spin = (math.random() - 0.5) * 6
	local drift = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 3
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > life or not p.Parent then
			conn:Disconnect()
			if p.Parent then
				fadeOut(p, 0.3)
			end
			return
		end
		local pos = at + drift * t + Vector3.new(math.sin(t * 3 + ph) * 1.2, -math.min(fall, t * fall / life * 1.3), math.cos(t * 2.6 + ph) * 0.8)
		p.CFrame = CFrame.new(pos) * CFrame.Angles(math.sin(t * 4 + ph) * 0.8, t * spin, math.cos(t * 3 + ph) * 0.6)
	end)
	return p
end

------------------------------------------------------------------------
-- 대나무 한 그루: 마디 있는 줄기, 비스듬히 잘린 끝, 꼭대기 가지의 잎 (아래가 0, 위로 높이 h)
------------------------------------------------------------------------
local function bamboo(h: number, d: number, seed: number): { Piece }
	local list: { Piece } = {}
	local segLen = 1.7 + (seed % 3) * 0.15
	local n = math.max(2, math.floor(h / segLen))
	segLen = h / n
	for i = 0, n - 1 do
		local y = segLen * (i + 0.5)
		local c = BAMBOO:Lerp(BAMBOO2, i / n)
		addTo(list, Vector3.new(segLen * 1.01, d, d), CFrame.new(0, y, 0) * UP, c, Enum.Material.SmoothPlastic, 0, "cyl")
		if i > 0 then
			addTo(list, Vector3.new(0.14, d * 1.14, d * 1.14), CFrame.new(0, segLen * i, 0) * UP, NODE, Enum.Material.SmoothPlastic, 0, "cyl")
		end
	end
	-- 비스듬히 잘린 끝 (창날처럼)
	addTo(list, Vector3.new(d, d * 1.8, d), CFrame.new(0, h + d * 0.9, 0) * CFrame.Angles(0, seed, 0), BAMBOO2, Enum.Material.SmoothPlastic, 0, "wedge")
	-- 위쪽 마디에서 뻗은 가는 가지 둘과 잎
	for b = 0, 1 do
		local y = h - segLen * (1.2 + b * 1.1)
		local a = seed * 1.7 + b * math.pi * 0.9
		local dir = CFrame.new(0, y, 0) * CFrame.Angles(0, a, 0) * CFrame.Angles(0, 0, math.rad(-55))
		addTo(list, Vector3.new(0.08, 1.6, 0.08), dir * CFrame.new(0, 0.8, 0), BAMBOO, Enum.Material.SmoothPlastic)
		for l = 0, 2 do
			local lcf = dir * CFrame.new(0, 1.3 + l * 0.15, 0) * CFrame.Angles(0, (l - 1) * 0.7, 0) * CFrame.Angles(math.rad(70 + l * 10), 0, 0) * CFrame.new(0, 0, -0.7)
			addTo(list, Vector3.new(0.04, 0.3, 1.5), lcf, l % 2 == 0 and LEAF or LEAF2, Enum.Material.SmoothPlastic, 0, "ball")
		end
	end
	return list
end
-- 땅을 뚫고 솟는다 (흙 조각이 튄다), 잠시 서 있다가 잎을 날리며 가라앉는다
local function riseBamboo(at: Vector3, h: number, d: number, stand: number, lean: Vector3?)
	local g = ground(at)
	local seed = math.random(1, 9)
	local list = bamboo(h, d, seed)
	local tilt = lean or Vector3.zero
	local base = CFrame.new(g) * CFrame.Angles(tilt.X, math.random() * 6, tilt.Z)
	local t0 = os.clock()
	local rise, sink = 0.11, 0.35
	placeAll(list, base * CFrame.new(0, -h, 0))
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local y
		if t < rise then
			local k = t / rise
			y = -h * (1 - k) + math.sin(k * math.pi) * 0.6
		elseif t < rise + stand then
			-- 솟은 뒤 살짝 흔들린다
			local k = t - rise
			y = 0
			placeAll(list, base * CFrame.Angles(math.sin(k * 14) * 0.03 * math.exp(-k * 3), 0, math.cos(k * 12) * 0.03 * math.exp(-k * 3)))
			return
		elseif t < rise + stand + sink then
			local k = (t - rise - stand) / sink
			y = -h * k * k
		else
			conn:Disconnect()
			for _, pc in ipairs(list) do
				pc.p:Destroy()
			end
			return
		end
		placeAll(list, base * CFrame.new(0, y, 0))
	end)
	-- 흙 고리와 튀는 흙덩이
	Fx.ring(g + Vector3.new(0, 0.25, 0), EARTH, 1, d * 6, 0.35)
	for _ = 1, 4 do
		local chunk = part(Vector3.new(0.4, 0.3, 0.4) * (0.6 + math.random()), EARTH, Enum.Material.Ground)
		chunk.CFrame = CFrame.new(g + Vector3.new(math.random() - 0.5, 0.3, math.random() - 0.5) * d)
		local out = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit * (1.5 + math.random() * 2)
		fadeOut(chunk, 0.5, { CFrame = chunk.CFrame + out + Vector3.new(0, 1.5, 0) })
	end
	-- 가라앉을 때 잎이 떨어진다
	task.delay(rise + stand, function()
		for _ = 1, 3 do
			fallingLeaf(g + Vector3.new(math.random() - 0.5, h * 0.85, math.random() - 0.5) * 1.5, math.random() < 0.5 and LEAF or LEAF2, 1.2, h * 0.7, 1.4)
		end
	end)
end

local function bambooLine(data: any)
	local from: Vector3 = data.from
	if not near(from, 220) then
		return
	end
	local dir = flat(data.dir or Vector3.new(0, 0, -1))
	local n = data.n or 7
	local delay, step = data.delay or 0.18, data.step or 0.06
	for i = 1, n do
		task.delay(delay + (i - 1) * step, function()
			local at = from + dir * ((data.start or 4) + (i - 1) * (data.gap or 4.2))
			-- 가운데 줄기 하나와 둘레의 가는 줄기 둘 (대숲처럼), 앞으로 갈수록 크다
			local h = 8 + i * 0.7
			riseBamboo(at, h, 1.0, data.stand or 0.9, Vector3.new(dir.Z, 0, -dir.X) * 0)
			local side = Vector3.new(-dir.Z, 0, dir.X)
			riseBamboo(at + side * 1.3 - dir * 0.4, h * 0.7, 0.7, (data.stand or 0.9) - 0.1, Vector3.new(math.rad(-6), 0, math.rad(8)))
			riseBamboo(at - side * 1.2 + dir * 0.3, h * 0.6, 0.65, (data.stand or 0.9) - 0.15, Vector3.new(math.rad(5), 0, math.rad(-9)))
			if i % 2 == 1 then
				Fx.sound("hit", 0.5, 1.4, at)
			end
			shakeNear(at, 0.15, 50)
		end)
	end
	Fx.sound("heavy", 0.6, 1.3, from)
end
-- 네 번째 일격의 죽순 (상대 발밑에서 하나)
local function bambooShoot(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	task.delay(data.delay or 0.2, function()
		riseBamboo(at, 6, 0.9, 0.45, Vector3.new(math.rad(4), 0, math.rad(-3)))
		riseBamboo(at + Vector3.new(1.2, 0, 0.6), 4, 0.6, 0.35, Vector3.new(math.rad(-6), 0, math.rad(10)))
		Fx.sound("hit", 0.6, 1.5, at)
	end)
end

------------------------------------------------------------------------
-- 천엽비수: 둘레를 감아 도는 푸른 잎, 적에게 줄지어 날아가는 잎
------------------------------------------------------------------------
type Gather = { leaves: { BasePart }, t0: number, root: BasePart, done: boolean }
-- 날아간 잎 (부서진 조각에 속성을 묻지 않도록 표로 기억한다)
local FLY: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local gathers: { [Instance]: Gather } = {}
local function orbitPos(g: Gather, i: number, n: number): CFrame
	local t = os.clock() - g.t0
	local a = i / n * math.pi * 2 + t * 5
	local r = 3.2 + (i % 3) * 0.7
	local y = -1.2 + ((i * 7) % 5) * 0.8 + math.sin(t * 3 + i) * 0.3
	local pos = g.root.Position + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
	return CFrame.lookAt(pos, pos + Vector3.new(-math.sin(a), 0.2, math.cos(a)))
end
local function leafGather(data: any)
	local m = data.m
	local r = rootOf(m)
	if not r or not near(r.Position, 220) then
		return
	end
	local old = gathers[m]
	if old then
		old.done = true
	end
	local n = 26
	local g: Gather = { leaves = {}, t0 = os.clock(), root = r, done = false }
	gathers[m] = g
	for i = 1, n do
		local p = part(Vector3.new(0.05, 0.36, 1.0), i % 3 == 0 and LEAF2 or LEAF, Enum.Material.SmoothPlastic, 1, "ball")
		tween(p, 0.2, { Transparency = 0 })
		g.leaves[i] = p
	end
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if g.done or not r.Parent or os.clock() - g.t0 > 2 then
			conn:Disconnect()
			for _, p in ipairs(g.leaves) do
				if not FLY[p] and p.Parent then
					fadeOut(p, 0.2)
				end
			end
			if gathers[m] == g then
				gathers[m] = nil
			end
			return
		end
		for i, p in ipairs(g.leaves) do
			if not FLY[p] then
				p.CFrame = orbitPos(g, i, n)
			end
		end
	end)
	Fx.ring(ground(r.Position) + Vector3.new(0, 0.3, 0), LEAF2, 2, 12, 0.4)
	Fx.sound("swing", 0.7, 1.1, r.Position)
end
-- 잎 하나가 곡선을 그리며 날아가 꽂힌다
local function flyLeaf(p: BasePart, target: BasePart, travel: number, c2: Color3)
	FLY[p] = true
	local from = p.Position
	local t0 = os.clock()
	local side = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 6 + Vector3.new(0, 3 + math.random() * 2, 0)
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local k = math.clamp((os.clock() - t0) / travel, 0, 1)
		local to = target.Parent and target.Position or from
		local ctrl = (from + to) / 2 + side
		local a = from:Lerp(ctrl, k)
		local b = ctrl:Lerp(to, k)
		local pos = a:Lerp(b, k)
		local ahead = a:Lerp(b, math.min(1, k + 0.05))
		p.CFrame = CFrame.lookAt(pos, ahead + Vector3.new(0, 1e-3, 0))
		if k >= 1 then
			conn:Disconnect()
			-- 베인 자리: 가는 빛줄기와 잎 부스러기
			local slash = part(Vector3.new(0.12, 0.12, 3.2), c2, Enum.Material.Neon, 0.1)
			slash.CFrame = CFrame.new(to) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
			fadeOut(slash, 0.18, { Size = Vector3.new(0.02, 0.02, 4.2) })
			fadeOut(p, 0.15)
		end
	end)
end
local function leafVolley(data: any)
	local m = data.m
	local g = gathers[m]
	local _, c2 = Config.STYLE_BY_ID[data.style] and Config.STYLE_BY_ID[data.style].color or WHITE, Config.STYLE_BY_ID[data.style] and Config.STYLE_BY_ID[data.style].color2 or WHITE
	local targets = {}
	for _, tm in ipairs(data.targets or {}) do
		local tr = rootOf(tm)
		if tr then
			table.insert(targets, tr)
		end
	end
	if not g or #targets == 0 then
		return
	end
	local waves = data.waves or 3
	local every = data.every or 0.12
	local travel = data.travel or 0.22
	local idx = 0
	for w = 0, waves - 1 do
		task.delay(w * every, function()
			for _, tr in ipairs(targets) do
				for _ = 1, 2 do
					idx += 1
					local p = g.leaves[((idx - 1) % #g.leaves) + 1]
					if p and not FLY[p] and p.Parent then
						flyLeaf(p, tr, travel, c2)
					else
						-- 모자라면 새 잎을 그 자리에서 띄운다
						local q = part(Vector3.new(0.05, 0.36, 1.0), LEAF2, Enum.Material.SmoothPlastic, 0, "ball")
						q.CFrame = orbitPos(g, idx, 26)
						flyLeaf(q, tr, travel, c2)
					end
				end
			end
			Fx.sound("swing", 0.5, 1.6, g.root.Position)
		end)
	end
end

------------------------------------------------------------------------
-- 신목강림: 천 년 은행나무
-- 뿌리 다섯이 땅을 움켜쥐고, 굵은 줄기가 살짝 비틀리며 솟고, 큰 가지 여섯 끝에 금빛 우듬지가 뭉게뭉게 얹힌다
------------------------------------------------------------------------
local function ginkgo(S: number): ({ Piece }, { Piece })
	local wood: { Piece } = {}
	local crown: { Piece } = {}
	-- 뿌리
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2 + 0.3
		local cf = CFrame.Angles(0, a, 0) * CFrame.new(0, 0.6 * S, -2.4 * S) * CFrame.Angles(math.rad(18), 0, 0)
		addTo(wood, Vector3.new(1.5, 1.3, 4.6) * S, cf, BARK2, Enum.Material.Wood)
		addTo(wood, Vector3.new(0.9, 0.8, 2.6) * S, CFrame.Angles(0, a, 0) * CFrame.new(0, 0.15 * S, -4.8 * S) * CFrame.Angles(math.rad(8), 0, 0), BARK2, Enum.Material.Wood)
	end
	-- 줄기: 아래가 굵고 위로 가늘며 마디마다 조금씩 기울고 비틀린다
	local cf = CFrame.new()
	local n = 6
	local segH = 3.6 * S
	for i = 0, n - 1 do
		local r = (2.5 - i * 0.2) * S
		addTo(wood, Vector3.new(segH * 1.08, r * 2, r * 2), cf * CFrame.new(0, segH / 2, 0) * UP, i % 2 == 0 and BARK or BARK:Lerp(BARK2, 0.4), Enum.Material.Wood, 0, "cyl")
		-- 껍질의 세로 골
		if i < 4 then
			for j = 0, 3 do
				local a = j / 4 * math.pi * 2 + i
				addTo(wood, Vector3.new(0.35 * S, segH * 0.9, 0.35 * S), cf * CFrame.new(math.cos(a) * r * 0.95, segH / 2, math.sin(a) * r * 0.95), BARK2, Enum.Material.Wood)
			end
		end
		cf = cf * CFrame.new(0, segH, 0) * CFrame.Angles(math.rad(i % 2 == 0 and 3 or -2), math.rad(14), math.rad(i % 2 == 0 and -2 or 3))
	end
	local topCf = cf
	-- 큰 가지 여섯: 줄기 윗부분에서 바깥 위로 뻗고, 끝에 우듬지 덩이
	local tips: { CFrame } = {}
	for b = 0, 5 do
		local hRatio = 0.55 + (b % 3) * 0.15
		local start = CFrame.new(0, n * segH * hRatio, 0) * CFrame.Angles(0, b / 6 * math.pi * 2 + 0.4, 0) * CFrame.Angles(math.rad(-60 + (b % 2) * 10), 0, 0)
		local bc = start
		for s = 0, 2 do
			local w = (1.1 - s * 0.3) * S
			local L = (4.4 - s * 0.7) * S
			addTo(wood, Vector3.new(w, L * 1.15, w), bc * CFrame.new(0, L / 2, 0), BARK, Enum.Material.Wood)
			bc = bc * CFrame.new(0, L, 0) * CFrame.Angles(math.rad(12), 0, 0)
		end
		table.insert(tips, bc)
	end
	table.insert(tips, topCf * CFrame.new(0, 2 * S, 0))
	-- 우듬지: 가지 끝마다 큰 덩이 하나와 작은 덩이 둘, 가운데 위에 큰 덩이 (풀결 재질, 금빛 셋을 섞어)
	local golds = { GOLD, GOLD2, GOLD3 }
	for i, tcf in ipairs(tips) do
		local p0 = tcf.Position
		local big = (i == #tips and 11 or 8.5) * S
		addTo(crown, Vector3.new(big, big * 0.78, big), CFrame.new(p0), golds[(i % 3) + 1], Enum.Material.Grass, 0, "ball")
		for j = 0, 1 do
			local a = i * 1.3 + j * 2.4
			local off = Vector3.new(math.cos(a), 0.3 - j * 0.5, math.sin(a)) * big * 0.42
			addTo(crown, Vector3.new(big, big * 0.8, big) * 0.62, CFrame.new(p0 + off), golds[((i + j) % 3) + 1], Enum.Material.Grass, 0, "ball")
		end
	end
	return wood, crown
end

local function treeRise(data: any)
	local at: Vector3 = data.at
	if not near(at, 320) then
		return
	end
	local g = ground(at)
	local center: Vector3 = data.center or at
	local rise, dur = data.rise or 0.8, data.dur or 2.4
	local R = data.radius or 24
	local S = 1.25
	local wood, crown = ginkgo(S)
	local dir = flat(data.dir or Vector3.new(0, 0, -1))
	local base = CFrame.lookAt(g, g + dir)
	local light = Instance.new("PointLight")
	light.Color = GOLD2
	light.Range = 40
	light.Brightness = 0
	light.Shadows = false
	light.Parent = crown[#crown].p
	tween(light, rise, { Brightness = 2 })
	local t0 = os.clock()
	local state = { done = false }
	;(Forest :: any)._trees = (Forest :: any)._trees or {}
	;(Forest :: any)._trees[data.id or 0] = { wood = wood, crown = crown, base = base, state = state, light = light }
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if state.done or t > rise + dur + 3 then
			conn:Disconnect()
			return
		end
		-- 자란다: 줄기가 먼저, 우듬지는 조금 늦게 부풀어 오른다
		local k = math.clamp(t / rise, 0, 1)
		local gw = 1 - (1 - k) ^ 3
		local kc = math.clamp((t - rise * 0.35) / (rise * 0.75), 0, 1)
		local gc = kc < 1 and (1 - (1 - kc) ^ 2) * (1 + math.sin(kc * math.pi) * 0.12) or 1
		local sway = CFrame.Angles(math.sin(t * 0.9) * 0.012, 0, math.cos(t * 0.7) * 0.012)
		placeAll(wood, base * sway, math.max(0.05, gw))
		placeAll(crown, base * sway, math.max(0.02, gc * gw))
	end)
	-- 땅이 들썩이며 갈라지는 고리, 흙과 잎
	Fx.ring(g + Vector3.new(0, 0.3, 0), EARTH, 4, 26, 0.6)
	Fx.ring(g + Vector3.new(0, 0.35, 0), GOLD, 4, 34, 0.8)
	shakeNear(at, 1.0, 120)
	Fx.sound("heavy", 1, 0.5, at)
	-- 금빛 잎 비: 우듬지 아래에서 둘레 R칸으로 쏟아진다
	task.delay(rise * 0.7, function()
		local endT = os.clock() + dur
		task.spawn(function()
			while os.clock() < endT and not state.done do
				for _ = 1, 3 do
					local a, rr = math.random() * math.pi * 2, math.sqrt(math.random()) * R
					local p = center + Vector3.new(math.cos(a) * rr, 14 + math.random() * 10, math.sin(a) * rr)
					fallingLeaf(p, ({ GOLD, GOLD2, GOLD3 })[math.random(1, 3)], 1.1 + math.random() * 0.5, 16, 1.6)
				end
				task.wait(0.06)
			end
		end)
		-- 땅에 내려앉는 금빛 (둘레를 덮는 옅은 원)
		local carpet = part(Vector3.new(0.2, 2, 2), GOLD, Enum.Material.Grass, 0.55, "cyl")
		carpet.CFrame = CFrame.new(ground(center) + Vector3.new(0, 0.12, 0)) * UP
		tween(carpet, dur * 0.6, { Size = Vector3.new(0.2, R * 2, R * 2), Transparency = 0.35 })
		task.delay(dur + 1.2, function()
			fadeOut(carpet, 0.8)
		end)
	end)
end
local function treeBurst(data: any)
	local at: Vector3 = data.at
	local trees = (Forest :: any)._trees or {}
	local tr = trees[data.id or 0]
	local center: Vector3 = data.center or at
	local R = data.radius or 28
	if tr then
		trees[data.id or 0] = nil
		-- 우듬지가 환해졌다가 잎으로 흩어진다. 줄기는 천천히 땅으로 돌아간다
		for _, pc in ipairs(tr.crown) do
			tween(pc.p, 0.18, { Color = GOLD2:Lerp(WHITE, 0.4) })
		end
		tween(tr.light, 0.18, { Brightness = 6, Range = 60 })
		task.delay(0.2, function()
			for _, pc in ipairs(tr.crown) do
				local p0 = pc.p.Position
				for _ = 1, 4 do
					local q = leaf(1.3, ({ GOLD, GOLD2, GOLD3 })[math.random(1, 3)])
					q.CFrame = CFrame.new(p0 + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * pc.p.Size.X * 0.6)
					local out = (Vector3.new(p0.X - center.X, 0, p0.Z - center.Z).Unit + Vector3.new(math.random() - 0.5, -0.3 - math.random() * 0.4, math.random() - 0.5)) * (R * (0.6 + math.random() * 0.6))
					fadeOut(q, 0.9 + math.random() * 0.4, { CFrame = q.CFrame + out, Orientation = Vector3.new(math.random() * 360, math.random() * 360, 0) })
				end
				fadeOut(pc.p, 0.35, { Size = pc.p.Size * 1.15 })
			end
			tr.state.done = true
			local t0 = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function()
				local k = (os.clock() - t0) / 1.0
				if k >= 1 then
					conn:Disconnect()
					for _, pc in ipairs(tr.wood) do
						if pc.p.Parent then
							pc.p:Destroy()
						end
					end
					return
				end
				placeAll(tr.wood, tr.base * CFrame.new(0, -18 * k * k, 0))
				for _, pc in ipairs(tr.wood) do
					pc.p.Transparency = k
				end
			end)
		end)
	end
	if not near(center, 300) then
		return
	end
	local g = ground(center)
	Fx.ring(g + Vector3.new(0, 0.3, 0), GOLD2, 4, R * 2.4, 0.6)
	task.delay(0.1, function()
		Fx.ring(g + Vector3.new(0, 0.35, 0), LEAF2, 4, R * 2.0, 0.6)
	end)
	-- 사방으로 휘몰아치는 잎 바람
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		local q = leaf(1.4, i % 2 == 0 and GOLD or GOLD2)
		local p0 = g + Vector3.new(math.cos(a) * 2, 1.5 + (i % 3), math.sin(a) * 2)
		q.CFrame = CFrame.lookAt(p0, p0 + Vector3.new(math.cos(a), 0, math.sin(a)))
		fadeOut(q, 0.7, { CFrame = CFrame.lookAt(p0 + Vector3.new(math.cos(a), 0.1, math.sin(a)) * R, p0 + Vector3.new(math.cos(a), 0, math.sin(a)) * (R + 1)) })
	end
	Fx.flash(center, GOLD2, 90, 6, 0.6)
	Fx.sound("shatter", 0.8, 0.9, center)
	shakeNear(center, 1.8, 140)
end

local HANDLERS: { [string]: (any) -> () } = {
	bambooLine = bambooLine,
	bambooShoot = bambooShoot,
	leafGather = leafGather,
	leafVolley = leafVolley,
	treeRise = treeRise,
	treeBurst = treeBurst,
}
function Forest.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil
end
function Forest.run(data: any)
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end
-- 렌더 확인용 (테스트에서만)
Forest._bamboo = bamboo
Forest._ginkgo = ginkgo
Forest._place = placeAll

return Forest
