-- 권왕 2.7판: 초·매화난무권의 새 기술 (화면). 날아가는 부채, 꽃 그림자, 하늘의 큰 부채
-- 부채는 살 (가는 대)과 그 사이의 분홍 면, 바깥의 짙은 테, 면 위의 벚꽃 무늬로 짓는다. 펼친 너비가 바뀌면 면의 너비도 다시 잰다
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Blossom = {}
local _player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "KwonBlossom"
folder.Parent = workspace

local opts: any = {}
function Blossom.init(o: any)
	opts = o or {}
end

local PINKS = { Color3.fromRGB(255, 183, 213), Color3.fromRGB(255, 160, 200), Color3.fromRGB(255, 205, 225) }
local PINK_DEEP = Color3.fromRGB(232, 84, 146)
local WHITE = Color3.new(1, 1, 1)
local WOOD = Color3.fromRGB(70, 40, 30)
local GOLD = Color3.fromRGB(240, 200, 120)

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
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
local function part(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, shape: string?): BasePart
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
-- 꽃잎 하나 (납작한 타원). 흔들리며 떨어진다
local function petal(at: Vector3, size: number, life: number, push: Vector3?)
	local p = part(Vector3.new(0.05, size * 0.75, size), PINKS[math.random(1, 3)], Enum.Material.SmoothPlastic, 0.05, "ball")
	local drift = (push or Vector3.zero) + Vector3.new(math.random() - 0.5, -0.6 - math.random() * 0.5, math.random() - 0.5) * 3
	local t0 = os.clock()
	local ph = math.random() * 6
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > life or not p.Parent then
			conn:Disconnect()
			if p.Parent then
				fadeOut(p, 0.2)
			end
			return
		end
		local pos = at + drift * t + Vector3.new(math.sin(t * 4 + ph) * 0.5, 0, math.cos(t * 3 + ph) * 0.5)
		p.CFrame = CFrame.new(pos) * CFrame.Angles(t * 3 + ph, t * 2, math.sin(t * 5) * 0.8)
	end)
end

------------------------------------------------------------------------
-- 부채 한 자루 (기준: 사북이 0, 살은 -Z 쪽으로 뻗는다, 판은 XZ 평면). span = 펼친 각도
------------------------------------------------------------------------
type Fan = { ribs: { BasePart }, panels: { BasePart }, edges: { BasePart }, prints: { { p: BasePart, rib: number, r: number } }, pivot: BasePart, n: number, R: number, R0: number }
local function makeFan(R: number, alpha: number?, glow: boolean?): Fan
	local a = alpha or 0
	local n = 13
	local fan: Fan = { ribs = {}, panels = {}, edges = {}, prints = {}, pivot = part(Vector3.new(1, 1, 1) * R * 0.07, GOLD, Enum.Material.Metal, a, "ball"), n = n, R = R, R0 = R * 0.22 }
	for i = 1, n do
		fan.ribs[i] = part(Vector3.new(R * 0.03, R * 0.022, R), WOOD, Enum.Material.Wood, a)
		if i < n then
			local col = PINKS[(i % 3) + 1]:Lerp(WHITE, (i % 2) * 0.12)
			fan.panels[i] = part(Vector3.new(1, R * 0.012, R - fan.R0), col, glow and Enum.Material.Neon or Enum.Material.SmoothPlastic, glow and math.max(a, 0.35) or a)
			fan.edges[i] = part(Vector3.new(1, R * 0.016, R * 0.06), PINK_DEEP, Enum.Material.SmoothPlastic, a)
		end
	end
	-- 면 위의 벚꽃 셋 (살 번호와 거리로 자리를 잡는다)
	for _, at in ipairs({ { 4, 0.72 }, { 7, 0.6 }, { 10, 0.78 } }) do
		for j = 0, 4 do
			local p = part(Vector3.new(R * 0.07, R * 0.014, R * 0.055), j == 0 and WHITE or PINKS[2]:Lerp(WHITE, 0.35), Enum.Material.SmoothPlastic, a, "ball")
			table.insert(fan.prints, { p = p, rib = at[1] + 0.5, r = at[2] + j * 0.001 })
		end
	end
	return fan
end
local function placeFan(fan: Fan, cf: CFrame, span: number)
	local n, R, R0 = fan.n, fan.R, fan.R0
	fan.pivot.CFrame = cf
	local function ang(i: number): number
		return (i - 1) / (n - 1) * span - span / 2
	end
	for i, rib in ipairs(fan.ribs) do
		rib.CFrame = cf * CFrame.Angles(0, ang(i), 0) * CFrame.new(0, 0, -R / 2)
	end
	local dth = span / (n - 1)
	local rm = (R + R0) / 2
	local w = math.max(0.05, 2 * rm * math.sin(dth / 2) * 1.15)
	for i, pnl in ipairs(fan.panels) do
		local th = ang(i) + dth / 2
		pnl.Size = Vector3.new(w, pnl.Size.Y, R - R0)
		pnl.CFrame = cf * CFrame.Angles(0, th, 0) * CFrame.new(0, 0, -rm)
		local e = fan.edges[i]
		e.Size = Vector3.new(math.max(0.05, 2 * R * math.sin(dth / 2) * 1.12), e.Size.Y, e.Size.Z)
		e.CFrame = cf * CFrame.Angles(0, th, 0) * CFrame.new(0, R * 0.012, -R * 0.97)
	end
	for k, pr in ipairs(fan.prints) do
		local th = ang(pr.rib)
		local j = (k - 1) % 5
		local base = cf * CFrame.Angles(0, th, 0) * CFrame.new(0, R * 0.015, -R * pr.r)
		if j == 0 then
			pr.p.CFrame = base
		else
			local a = j / 4 * math.pi * 2
			pr.p.CFrame = base * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -R * 0.045)
		end
	end
end
local function fanParts(fan: Fan): { BasePart }
	local out = { fan.pivot }
	for _, l in ipairs({ fan.ribs, fan.panels, fan.edges }) do
		for _, p in ipairs(l) do
			table.insert(out, p)
		end
	end
	for _, pr in ipairs(fan.prints) do
		table.insert(out, pr.p)
	end
	return out
end
local function dropFan(fan: Fan, time: number)
	for _, p in ipairs(fanParts(fan)) do
		if p.Parent then
			fadeOut(p, time)
		end
	end
end

------------------------------------------------------------------------
-- 선풍낙화 (E): 양옆으로 둥글게 날아갔다 되돌아오는 부채 둘
------------------------------------------------------------------------
local function fanBoomerang(data: any)
	local from: Vector3 = data.from
	if not near(from, 220) then
		return
	end
	local look = flat(data.dir or Vector3.new(0, 0, -1))
	local right = Vector3.new(-look.Z, 0, look.X)
	local D, W, T = data.dist or 24, data.width or 9, data.time or 1.0
	local fans = { makeFan(2.6), makeFan(2.6) }
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp(t / T, 0, 1)
		for i, fan in ipairs(fans) do
			local side = i == 1 and -1 or 1
			local pos = from + Vector3.new(0, 1.2, 0) + look * (D * (1 - math.cos(2 * math.pi * u)) / 2) + right * side * (W * math.sin(2 * math.pi * u))
			-- 펼친 채 빙글빙글 돈다 (조금 기울어)
			placeFan(fan, CFrame.new(pos) * CFrame.Angles(math.rad(10) * side, t * 22 * side, 0) * CFrame.new(0, 0, 1.1), math.rad(160))
			if math.random() < 0.7 then
				petal(pos + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 2, 0.6, 0.9)
			end
		end
		if u >= 1 then
			conn:Disconnect()
			for _, fan in ipairs(fans) do
				dropFan(fan, 0.15)
			end
			for _ = 1, 8 do
				petal(from + Vector3.new(0, 2, 0), 0.6, 0.8, Vector3.new(math.random() - 0.5, 0.5, math.random() - 0.5) * 6)
			end
		end
	end)
	Fx.sound("swing", 0.8, 1.3, from)
	task.delay(T * 0.5, function()
		Fx.sound("swing", 0.6, 1.5, from)
	end)
end

------------------------------------------------------------------------
-- 화영보 (R): 지나간 길에 남는 꽃 그림자 셋 (내 몸을 본뜬 분홍 그림자가 부채를 휘두르고 꽃잎으로 흩어진다)
------------------------------------------------------------------------
local function ghostOf(model: Model, offset: Vector3, color: Color3): { BasePart }
	local out: { BasePart } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.9 and d.Name ~= "HumanoidRootPart" then
			local g = part(d.Size, color, Enum.Material.ForceField, 0.15, (d:IsA("Part") and d.Shape == Enum.PartType.Ball) and "ball" or nil)
			g.CFrame = d.CFrame + offset
			table.insert(out, g)
		end
	end
	return out
end
local function petalShadow(data: any)
	local m = data.m
	local r = rootOf(m)
	if not r or not near(r.Position, 220) then
		return
	end
	local look = flat(data.dir or Vector3.new(0, 0, -1))
	local spots = data.spots or {}
	local start = r.Position
	local delay, every = data.delay or 0.25, data.every or 0.14
	local R = data.radius or 7.5
	local ghosts: { { BasePart } } = {}
	-- 미끄러지는 동안 지나간 자리마다 그림자를 남긴다
	for i, at in ipairs(spots) do
		task.delay(0.05 + i * 0.05, function()
			local cur = rootOf(m)
			local ref = cur and cur.Position or start
			ghosts[i] = ghostOf(m, Vector3.new(at.X - ref.X, 0, at.Z - ref.Z), PINKS[(i % 3) + 1])
			for _ = 1, 4 do
				petal(at + Vector3.new(0, 1, 0), 0.6, 0.7)
			end
		end)
		task.delay(delay + (i - 1) * every, function()
			-- 그림자의 부채질: 둘레를 가르는 분홍 반달 칼날
			local g = ground(at)
			local side = (i % 2 == 0) and 1 or -1
			for k = 0, 8 do
				local a = (k / 8 - 0.5) * math.pi * 1.2 * side
				local dirA = CFrame.Angles(0, a, 0) * look
				local seg = part(Vector3.new(0.18, 0.5, R * 0.35), k % 2 == 0 and PINK_DEEP or PINKS[1], Enum.Material.Neon, 0.1)
				seg.CFrame = CFrame.lookAt(g + Vector3.new(0, 2.6, 0) + dirA * R * 0.75, g + Vector3.new(0, 2.6, 0) + dirA * R * 0.75 + CFrame.Angles(0, math.pi / 2, 0) * dirA)
				fadeOut(seg, 0.25, { Size = Vector3.new(0.05, 0.3, R * 0.5) })
			end
			Fx.ring(g + Vector3.new(0, 0.3, 0), PINKS[2], 2, R * 2, 0.3)
			Fx.sound("swing", 0.6, 1.4 + i * 0.1, at)
		end)
	end
	-- 모두 꽃잎으로 흩어진다
	task.delay(delay + (#spots - 1) * every + (data.burstAt or 0.45), function()
		for i, list in pairs(ghosts) do
			local at = spots[i]
			for _, g in ipairs(list) do
				fadeOut(g, 0.25)
			end
			for _ = 1, 14 do
				petal(at + Vector3.new(0, 2, 0), 0.7, 1.0, Vector3.new(math.random() - 0.5, 0.8, math.random() - 0.5) * 10)
			end
			Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), WHITE, 2, R * 2.4, 0.35)
		end
		Fx.sound("shatter", 0.6, 1.5, start)
		shakeNear(start, 0.6, 70)
	end)
end

------------------------------------------------------------------------
-- 만화천선 (오의): 하늘의 큰 부채가 펼쳐지고, 앞의 땅을 두 번 쓸고, 접히며 꽃잎 폭풍
------------------------------------------------------------------------
local function skyFan(data: any)
	local at: Vector3 = data.at
	if not near(at, 260) then
		return
	end
	local look = flat(data.dir or Vector3.new(0, 0, -1))
	local range = data.range or 34
	local open, sweeps, sweepT = data.open or 0.6, data.sweeps or 2, data.sweepTime or 0.55
	local closeAt = data.closeAt or 0.35
	local fan = makeFan(range * 0.95, 0.05, false)
	local g = ground(at)
	local pivot = g + Vector3.new(0, 7, 0) - look * 3
	local baseYaw = math.atan2(-look.X, -look.Z)
	local t0 = os.clock()
	local tSweepEnd = open + sweeps * (sweepT + 0.05)
	local tClose = tSweepEnd + closeAt
	local done = false
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local span, yaw, h
		if t < open then
			-- 하늘에서 내려오며 펼쳐진다
			local k = t / open
			local e = 1 - (1 - k) ^ 3
			span = math.rad(10 + 140 * e)
			yaw = 0
			h = 18 - 11 * e
		elseif t < tSweepEnd then
			-- 쓸기: 홀수 번은 왼쪽에서 오른쪽으로, 짝수 번은 거꾸로 (끝에서 끝까지)
			local k = math.floor((t - open) / (sweepT + 0.05))
			local u = math.clamp(((t - open) - k * (sweepT + 0.05)) / sweepT, 0, 1)
			local e = u * u * (3 - 2 * u)
			local a = math.rad(55)
			yaw = (k % 2 == 0) and (-a + 2 * a * e) or (a - 2 * a * e)
			span = math.rad(150)
			h = 7
			if math.random() < 0.8 then
				local rr = math.random() * range
				local aa = baseYaw + yaw + (math.random() - 0.5) * span
				petal(g + Vector3.new(-math.sin(aa) * rr, 3 + math.random() * 3, -math.cos(aa) * rr), 0.9, 1.0)
			end
		elseif t < tClose then
			-- 접힌다 (탁!)
			local k = math.clamp((t - tSweepEnd) / closeAt, 0, 1)
			span = math.rad(150) * (1 - k * k)
			yaw = 0
			h = 7 + 4 * k
		else
			if not done then
				done = true
				conn:Disconnect()
				dropFan(fan, 0.3)
				-- 꽃잎 폭풍: 둘레를 휘감으며 솟는다
				local R = data.closeRadius or 26
				for i = 0, 59 do
					local a = i / 60 * math.pi * 2
					local rr = R * (0.3 + (i % 5) * 0.16)
					local p0 = g + Vector3.new(math.cos(a) * rr, 1 + (i % 4), math.sin(a) * rr)
					petal(p0, 1.0, 1.3, Vector3.new(-math.sin(a), 0.6, math.cos(a)) * 14)
				end
				Fx.ring(g + Vector3.new(0, 0.3, 0), PINK_DEEP, 4, R * 2.4, 0.6)
				task.delay(0.08, function()
					Fx.ring(g + Vector3.new(0, 0.35, 0), WHITE, 4, R * 2, 0.5)
				end)
				Fx.flash(at, PINKS[2], 90, 6, 0.6)
				Fx.sound("shatter", 1, 1.1, at)
				shakeNear(at, 1.8, 140)
			end
			return
		end
		local cf = CFrame.new(pivot.X, g.Y + h, pivot.Z) * CFrame.Angles(0, baseYaw + yaw, 0) * CFrame.Angles(math.rad(-8), 0, 0)
		placeFan(fan, cf, span)
	end)
	Fx.sound("swing", 0.9, 0.6, at)
	for k = 1, sweeps do
		task.delay(open + (k - 1) * (sweepT + 0.05), function()
			Fx.sound("swing", 1, 0.8, at)
			shakeNear(at, 0.8, 90)
		end)
	end
	task.delay(tSweepEnd + closeAt * 0.8, function()
		Fx.sound("hit", 1, 0.7, at)
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	fanBoomerang = fanBoomerang,
	petalShadow = petalShadow,
	skyFan = skyFan,
}
function Blossom.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil
end
function Blossom.run(data: any)
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end
-- 렌더 확인용
Blossom._makeFan = makeFan
Blossom._placeFan = placeFan
Blossom._fanParts = fanParts
local _ = Config
return Blossom
