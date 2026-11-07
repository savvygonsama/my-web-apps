-- 권왕 3.27판: 신 삼재권을 얻는 컷씬.
-- 팔을 몸 둘레로 여섯 번 휘두르고 (둘은 허리만 틀고, 넷은 몸째 돈다), 무릎을 높이 들었다가 발로 땅을 찍는다.
-- 찍는 순간 컷씬이 끝나고 바닥이 깨진다 (갈라지는 틈 · 솟았다 떨어지는 바닥 조각 · 가라앉은 자리).
-- 시간표는 Poses.sn_get과 같다 (전체 7.4초를 컷씬 길이에 맞춰 늘이고 줄인다)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Fx = require(script.Parent:WaitForChild("Fx"))
local Anim = require(script.Parent:WaitForChild("Anim"))
local Cutscene = require(script.Parent:WaitForChild("Cutscene"))

local Sin = {}

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "KwonSin"
folder.Parent = workspace

local opts: any = {}
function Sin.init(o: any)
	opts = o or {}
end

local SKY = Color3.fromRGB(150, 205, 255) -- 하늘
local EARTH = Color3.fromRGB(255, 190, 90) -- 땅
local HUMAN = Color3.fromRGB(255, 250, 235) -- 사람
local GOLD = Color3.fromRGB(255, 238, 170)
local TRIO = { SKY, EARTH, HUMAN }

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal):Play()
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
	q.Material = material or Enum.Material.Neon
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
local function rootOf(m: any): BasePart?
	local r = typeof(m) == "Instance" and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function shake(a: number)
	if opts.shake then
		opts.shake(a)
	end
end

-- 발밑 땅의 높이·빛깔·재질 (바닥 조각을 같은 땅으로 만든다)
local function groundAt(pos: Vector3, skip: Instance?): (Vector3, Color3, Enum.Material)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ex: { Instance } = { folder }
	if skip then
		table.insert(ex, skip)
	end
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			table.insert(ex, pl.Character)
		end
	end
	local en = workspace:FindFirstChild("Enemies")
	if en then
		table.insert(ex, en)
	end
	params.FilterDescendantsInstances = ex
	local r = workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -30, 0), params)
	if r then
		local inst = r.Instance
		local col = Color3.fromRGB(120, 105, 85)
		if inst:IsA("BasePart") and not inst:IsA("Terrain") then
			col = inst.Color
		end
		local mat = r.Material
		if mat == Enum.Material.Air or mat == Enum.Material.Water then
			mat = Enum.Material.Slate
		end
		return r.Position, col, mat
	end
	return pos - Vector3.new(0, 3, 0), Color3.fromRGB(120, 105, 85), Enum.Material.Slate
end

------------------------------------------------------------------------
-- 휘두름 하나: 팔 높이에서 퍼지는 고리 + 바람 + 소리
------------------------------------------------------------------------
local function swing(m: Model, k: number, color: Color3, big: boolean)
	local r = rootOf(m)
	if not r then
		return
	end
	local c = r.Position
	local R = big and 34 or 24
	Fx.ring(c + Vector3.new(0, 0.5 + (k % 3) * 0.9, 0), color, 3, R, 0.45)
	Fx.ring(c + Vector3.new(0, -0.5, 0), HUMAN, 3, R * 0.8, 0.4)
	Fx.burst("spark", c, color, 8 + k * 2, 1.2 + k * 0.1)
	-- 팔이 베고 간 초승달 (몸 둘레를 도는 얇은 빛)
	local arc = part(Vector3.new(0.3, 5, 5), color, Enum.Material.Neon, 0.35, "cyl")
	arc.CFrame = CFrame.new(c) * CFrame.Angles(0, 0, math.rad(90))
	tween(arc, 0.35, { Size = Vector3.new(0.3, R * 0.8, R * 0.8), Transparency = 1 })
	task.delay(0.4, function()
		arc:Destroy()
	end)
	Fx.breakSound("whoosh", 0.7 + k * 0.05, 0.7 + k * 0.12, c)
	Fx.afterimage(m, color, 0.5)
	-- 거대한 금빛 팔: 몸 둘레를 한 바퀴 크게 휩쓴다
	local hub = part(Vector3.new(0.2, 0.2, 0.2), color, Enum.Material.Neon, 1)
	hub.CFrame = CFrame.new(c + Vector3.new(0, 1 + (k % 3), 0))
	local kids: { BasePart } = {}
	for side = -1, 1, 2 do
		local arm = part(Vector3.new(R * 0.7, 3.2, 3.2), color, Enum.Material.Neon, 0.45, "cyl")
		arm.CFrame = hub.CFrame * CFrame.new(side * R * 0.38, 0, 0) * CFrame.Angles(0, 0, math.rad(0))
		local fist = part(Vector3.new(6.5, 6.5, 6.5), HUMAN, Enum.Material.Neon, 0.35, "ball")
		fist.CFrame = hub.CFrame * CFrame.new(side * R * 0.74, 0, 0)
		for _, q in ipairs({ arm, fist }) do
			q.Anchored = false
			q.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = hub
			w.Part1 = q
			w.Parent = q
			table.insert(kids, q)
		end
	end
	local t1 = os.clock()
	local spinC: RBXScriptConnection
	spinC = RunService.Heartbeat:Connect(function()
		local u = (os.clock() - t1) / 0.42
		if u >= 1 or not hub.Parent then
			spinC:Disconnect()
			return
		end
		hub.CFrame = CFrame.new(c + Vector3.new(0, 1 + (k % 3), 0)) * CFrame.Angles(0, u * math.pi * 2 * (k % 2 == 0 and 1 or -1), 0)
	end)
	task.delay(0.3, function()
		for _, q in ipairs(kids) do
			tween(q, 0.15, { Transparency = 1 })
		end
	end)
	task.delay(0.5, function()
		hub:Destroy()
		for _, q in ipairs(kids) do
			q:Destroy()
		end
	end)
	shake(0.25 + k * 0.08)
end

------------------------------------------------------------------------
-- 땅이 깨진다
------------------------------------------------------------------------
local function breakGround(m: Model, at: Vector3, slam: (() -> ())?)
	local g0 = groundAt(at, m)
	local g = Vector3.new(at.X, g0.Y, at.Z)
	-- 충격: 하얗게 번쩍, 고리 세 겹, 빛기둥
	if slam then
		slam()
	end
	Fx.flash(g + Vector3.new(0, 4, 0), HUMAN, 140, 5, 0.9)
	Fx.ring(g + Vector3.new(0, 0.3, 0), HUMAN, 4, 120, 0.8)
	-- 여진: 뒤따라 두 번 더 퍼지고 땅이 울린다
	for i = 1, 3 do
		task.delay(0.45 * i, function()
			Fx.ring(g + Vector3.new(0, 0.3, 0), i == 2 and SKY or EARTH, 6, 70 + i * 22, 0.9)
			Fx.breakSound("boom", 0.7, 0.5 + i * 0.1, g)
			shake(1.6 - i * 0.35)
		end)
	end
	task.delay(0.08, function()
		Fx.ring(g + Vector3.new(0, 0.3, 0), GOLD, 4, 62, 0.8)
	end)
	task.delay(0.18, function()
		Fx.ring(g + Vector3.new(0, 0.3, 0), EARTH, 4, 44, 0.9)
	end)
	Fx.breakSound("boom", 1, 0.45, g)
	Fx.sound("deflect", 1, 0.4, g)
	shake(4)
	-- 하늘을 꿰뚫는 빛기둥 (굵은 흰 기둥 + 금빛 후광 + 하늘빛 바깥 후광)
	local col = part(Vector3.new(700, 22, 22), HUMAN, Enum.Material.Neon, 0.05, "cyl")
	col.CFrame = CFrame.new(g + Vector3.new(0, 340, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(col, 1.4, { Size = Vector3.new(700, 3, 3) })
	fadeOut(col, 1.5)
	local halo = part(Vector3.new(700, 46, 46), GOLD, Enum.Material.Neon, 0.5, "cyl")
	halo.CFrame = col.CFrame
	fadeOut(halo, 1.8, { Size = Vector3.new(700, 90, 90) })
	local halo2 = part(Vector3.new(700, 90, 90), SKY, Enum.Material.Neon, 0.75, "cyl")
	halo2.CFrame = col.CFrame
	fadeOut(halo2, 2.2, { Size = Vector3.new(700, 170, 170) })
	-- 솟는 불티
	for k = 1, 3 do
		task.delay(k * 0.12, function()
			Fx.burst("glitter", g + Vector3.new(0, 2, 0), k == 2 and SKY or GOLD, 30, 3)
		end)
	end
	Fx.burst("dust", g + Vector3.new(0, 1, 0), Color3.fromRGB(175, 160, 140), 40, 2.6)
	Fx.burst("spark", g + Vector3.new(0, 1, 0), GOLD, 40, 2.4)
	Fx.debris(g, 20, 34)

	-- 금빛 비: 하늘에서 빛 가루가 한참 쏟아진다
	for k = 1, 90 do
		task.delay(math.random() * 2.2, function()
			local a = math.random() * math.pi * 2
			local d = math.random() * 55
			local from = g + Vector3.new(math.cos(a) * d, 50 + math.random() * 30, math.sin(a) * d)
			local bit = part(Vector3.new(0.5, 1.8, 0.5), k % 3 == 0 and HUMAN or GOLD, Enum.Material.Neon, 0.1)
			bit.Position = from
			tween(bit, 1.3, { Position = Vector3.new(from.X, g.Y + 0.5, from.Z), Transparency = 0.8 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(1.35, function()
				bit:Destroy()
			end)
		end)
	end
	-- 가라앉은 자리: 어두운 원판과 금빛 테
	local pit = part(Vector3.new(0.3, 4, 4), Color3.fromRGB(14, 12, 10), Enum.Material.Slate, 0, "cyl")
	pit.CFrame = CFrame.new(g + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(pit, 0.35, { Size = Vector3.new(0.3, 34, 34) })
	task.delay(9, function()
		fadeOut(pit, 2)
	end)
	local rim = part(Vector3.new(0.35, 4, 4), GOLD, Enum.Material.Neon, 0.3, "cyl")
	rim.CFrame = CFrame.new(g + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(rim, 0.35, { Size = Vector3.new(0.35, 36, 36) })
	task.delay(0.4, function()
		tween(rim, 0.01, { Size = Vector3.new(0.35, 36, 36) })
		local hole = part(Vector3.new(0.5, 33, 33), Color3.fromRGB(8, 7, 6), Enum.Material.Slate, 0, "cyl")
		hole.CFrame = CFrame.new(g + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		task.delay(8.6, function()
			fadeOut(hole, 2)
		end)
	end)
	task.delay(5, function()
		fadeOut(rim, 4)
	end)

	-- 갈라지는 틈: 가운데에서 바깥으로 뻗는다. 어두운 틈 위에 금빛이 번득인다
	local n = 26
	for k = 1, n do
		local a = k / n * math.pi * 2 + math.random() * 0.25
		local len = 50 + math.random() * 90
		task.delay(math.random() * 0.12, function()
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local mid = g + dir * (len * 0.5 + 6) + Vector3.new(0, 0.15, 0)
			local crack = part(Vector3.new(2.2, 0.12, 0.1), Color3.fromRGB(10, 9, 8), Enum.Material.Slate, 0)
			crack.CFrame = CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, math.rad(90), 0)
			tween(crack, 0.45, { Size = Vector3.new(len, 0.12, 2.0 + math.random() * 1.4) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local glow = part(Vector3.new(2.2, 0.16, 0.1), GOLD, Enum.Material.Neon, 0.1)
			glow.CFrame = crack.CFrame + Vector3.new(0, 0.05, 0)
			tween(glow, 0.45, { Size = Vector3.new(len, 0.16, 0.55) })
			task.delay(0.5, function()
				tween(glow, 3.5, { Transparency = 1 })
			end)
			task.delay(4, function()
				glow:Destroy()
			end)
			task.delay(8 + math.random() * 1.5, function()
				fadeOut(crack, 2)
			end)
			-- 틈이 갈라진 자리에서 돌이 튄다
			if k % 2 == 0 then
				Fx.debris(g + dir * (len * 0.6), 4, 14)
			end
		end)
	end

	-- 바닥 조각: 같은 땅의 판이 솟구쳤다가 기울어져 떨어진다
	for k = 1, 46 do
		local a = math.random() * math.pi * 2
		local d = 7 + math.random() * 40
		local p0 = g + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		local gp, gc, gm = groundAt(p0, m)
		local sz = Vector3.new(2.5 + math.random() * 4.5, 1 + math.random() * 1.2, 2.5 + math.random() * 4.5)
		local slab = Instance.new("Part")
		slab.Anchored = true
		slab.CanCollide = false
		slab.CanQuery = false
		slab.CanTouch = false
		slab.CastShadow = true
		slab.Size = sz
		slab.Color = gc
		slab.Material = gm
		slab.Parent = folder
		local rest = CFrame.new(gp + Vector3.new(0, sz.Y * 0.2, 0)) * CFrame.Angles(math.rad((math.random() - 0.5) * 30), math.random() * math.pi * 2, math.rad((math.random() - 0.5) * 30))
		slab.CFrame = CFrame.new(gp) * (rest - rest.Position)
		local up = 4 + math.random() * 9 * (1 - d / 40)
		local spin = CFrame.Angles(math.rad((math.random() - 0.5) * 140), math.rad((math.random() - 0.5) * 140), math.rad((math.random() - 0.5) * 140))
		task.delay(d * 0.012, function()
			tween(slab, 0.4, { CFrame = CFrame.new(gp + Vector3.new(0, up, 0)) * spin * (rest - rest.Position) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			task.delay(0.42, function()
				tween(slab, 0.5, { CFrame = rest }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end)
			task.delay(0.95, function()
				Fx.burst("dust", gp, Color3.fromRGB(175, 160, 140), 3, 0.9)
				if k % 4 == 0 then
					Fx.breakSound("boom", 0.35, 1.3, gp)
				end
			end)
			task.delay(7 + math.random() * 2, function()
				tween(slab, 2, { CFrame = rest - Vector3.new(0, sz.Y * 1.5, 0) })
				task.delay(2.05, function()
					slab:Destroy()
				end)
			end)
		end)
	end
end

------------------------------------------------------------------------
-- 컷씬 본체
------------------------------------------------------------------------
------------------------------------------------------------------------
-- 모으는 동안 (휘두를수록 커진다): 땅의 삼재진 · 몸을 도는 세 겹의 큰 고리 · 떠오르는 바위 · 하늘로 서는 기둥 · 내리치는 벼락
------------------------------------------------------------------------
local function hubAt(cf: CFrame): BasePart
	local h = part(Vector3.new(0.2, 0.2, 0.2), Color3.new(1, 1, 1), Enum.Material.Neon, 1)
	h.CFrame = cf
	return h
end
local function weldTo(hub: BasePart, p: BasePart, off: CFrame, all: { BasePart })
	p.Anchored = false
	p.Massless = true
	p.CFrame = hub.CFrame * off
	local w = Instance.new("WeldConstraint")
	w.Part0 = hub
	w.Part1 = p
	w.Parent = p
	table.insert(all, p)
end
-- 속이 빈 고리 (hub의 XY 면, 굴대는 Z)
local function ringGroup(hub: BasePart, R: number, color: Color3, thick: number, all: { BasePart })
	local n = math.max(24, math.floor(R * 4))
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * math.pi * 2
		local seg = part(Vector3.new(2 * math.pi * R / n * 1.12, thick, thick), color, Enum.Material.Neon, 1)
		weldTo(hub, seg, CFrame.Angles(0, 0, a) * CFrame.new(0, R, 0), all)
	end
end
local function appear(all: { BasePart }, from: number, alpha: number, time: number)
	for i = from, #all do
		tween(all[i], time, { Transparency = alpha })
	end
end

local function buildUp(m: Model, stomp: number, K: number): () -> ()
	local r0 = rootOf(m)
	if not r0 then
		return function() end
	end
	local c0 = r0.Position
	local gp = groundAt(c0 - Vector3.new(0, 2, 0), m)
	local g = Vector3.new(c0.X, gp.Y + 0.2, c0.Z)
	local t0 = os.clock()
	local all: { BasePart } = {}

	-- 땅의 삼재진: 세 겹의 판과 두 삼각형 (하늘·땅·사람)과 바깥 눈금
	local circle = hubAt(CFrame.new(g))
	local cAll: { BasePart } = {}
	local discs = { { 14, SKY, 0.82 }, { 22, EARTH, 0.78 }, { 30, HUMAN, 0.74 } }
	for _, dsc in ipairs(discs) do
		local R = dsc[1] :: number
		local pad = part(Vector3.new(0.12, R * 2, R * 2), dsc[2] :: Color3, Enum.Material.Neon, 1, "cyl")
		weldTo(circle, pad, CFrame.Angles(0, 0, math.rad(90)), cAll)
		pad:SetAttribute("A", dsc[3])
	end
	for tri = 0, 1 do
		for k = 0, 2 do
			local a = (k / 3 + tri / 6) * math.pi * 2
			local b = ((k + 1) / 3 + tri / 6) * math.pi * 2
			local R = 28
			local p1 = Vector3.new(math.cos(a) * R, 0.2, math.sin(a) * R)
			local p2 = Vector3.new(math.cos(b) * R, 0.2, math.sin(b) * R)
			local bar = part(Vector3.new((p2 - p1).Magnitude, 0.2, 0.55), tri == 0 and GOLD or SKY, Enum.Material.Neon, 1)
			weldTo(circle, bar, CFrame.lookAt((p1 + p2) / 2, p2) * CFrame.Angles(0, math.rad(90), 0), cAll)
			bar:SetAttribute("A", 0.1)
		end
	end
	for k = 0, 35 do
		local a = k / 36 * math.pi * 2
		local tick = part(Vector3.new(0.4, 0.2, k % 3 == 0 and 3 or 1.6), GOLD, Enum.Material.Neon, 1)
		weldTo(circle, tick, CFrame.new(math.cos(a) * 33, 0.2, math.sin(a) * 33) * CFrame.Angles(0, -a, 0), cAll)
		tick:SetAttribute("A", 0.2)
	end
	for _, q in ipairs(cAll) do
		table.insert(all, q)
	end
	task.delay(0.3, function()
		for _, q in ipairs(cAll) do
			if q.Parent then
				tween(q, 1.2, { Transparency = (q:GetAttribute("A") :: number?) or 0.2 })
			end
		end
	end)
	Fx.ring(g, GOLD, 4, 34, 1.2)

	-- 몸을 도는 세 겹의 큰 고리 (짐벌)
	local center = c0 + Vector3.new(0, 0.5, 0)
	local gyros: { { hub: BasePart, tilt: CFrame, sp: number, born: number, all: { BasePart }, shown: boolean } } = {}
	local specs = { { 9, SKY, 1.05 * K, CFrame.Angles(math.rad(90), 0, 0), 1.6 }, { 12.5, EARTH, 2.1 * K, CFrame.Angles(math.rad(35), math.rad(60), 0), -1.9 }, { 16, HUMAN, 2.8 * K, CFrame.Angles(math.rad(-40), math.rad(-60), 0), 2.3 } }
	for _, sp in ipairs(specs) do
		local hub = hubAt(CFrame.new(center))
		local list: { BasePart } = {}
		ringGroup(hub, sp[1] :: number, sp[2] :: Color3, 0.55, list)
		ringGroup(hub, (sp[1] :: number) * 0.93, GOLD, 0.2, list)
		for _, q in ipairs(list) do
			table.insert(all, q)
		end
		table.insert(gyros, { hub = hub, tilt = sp[4] :: CFrame, sp = sp[5] :: number, born = sp[3] :: number, all = list, shown = false })
	end

	-- 떠오르는 바위
	local rocks: { { p: BasePart, base: CFrame, rest: CFrame, up: number, ph: number } } = {}
	for k = 1, 16 do
		local a = k / 16 * math.pi * 2 + math.random() * 0.3
		local d = 9 + math.random() * 14
		local p0 = g + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		local gp2, gc, gm = groundAt(p0, m)
		local sz = Vector3.new(2 + math.random() * 3.5, 1.4 + math.random() * 2, 2 + math.random() * 3.5)
		local rk = Instance.new("Part")
		rk.Anchored = true
		rk.CanCollide = false
		rk.CanQuery = false
		rk.CanTouch = false
		rk.Size = sz
		rk.Color = gc
		rk.Material = gm
		rk.CFrame = CFrame.new(gp2 + Vector3.new(0, sz.Y * 0.3, 0))
		rk.Parent = folder
		local rest = CFrame.new(gp2 + Vector3.new(0, sz.Y * 0.25, 0)) * CFrame.Angles(0, math.random() * 6.28, 0)
		table.insert(rocks, { p = rk, base = rest, rest = rest, up = 3 + math.random() * 9, ph = math.random() * 6.28 })
		Fx.burst("dust", gp2, Color3.fromRGB(175, 160, 140), 2, 0.6)
	end

	-- 하늘로 서는 기둥
	local pil = part(Vector3.new(700, 2, 2), HUMAN, Enum.Material.Neon, 0.3, "cyl")
	local pil2 = part(Vector3.new(700, 4, 4), GOLD, Enum.Material.Neon, 0.7, "cyl")
	local pilCF = CFrame.new(g + Vector3.new(0, 340, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pil.CFrame = pilCF
	pil2.CFrame = pilCF

	-- 등 뒤의 거대한 광배: 몸 뒤 하늘에 금빛 고리 둘과 열두 빛살이 천천히 돈다 (위압)
	local lookV = Vector3.new(r0.CFrame.LookVector.X, 0, r0.CFrame.LookVector.Z)
	lookV = lookV.Magnitude > 0.01 and lookV.Unit or Vector3.new(0, 0, -1)
	local haloC = c0 - lookV * 16 + Vector3.new(0, 15, 0)
	local halo = hubAt(CFrame.lookAt(haloC, haloC + lookV))
	local hAll: { BasePart } = {}
	ringGroup(halo, 24, GOLD, 0.8, hAll)
	ringGroup(halo, 20, HUMAN, 0.35, hAll)
	for k2 = 0, 11 do
		local a = k2 / 12 * math.pi * 2
		local ray = part(Vector3.new(0.35, 7, 0.35), GOLD, Enum.Material.Neon, 1)
		weldTo(halo, ray, CFrame.Angles(0, 0, a) * CFrame.new(0, 28.5, 0), hAll)
	end
	for _, q in ipairs(hAll) do
		table.insert(all, q)
	end
	task.delay(1.4 * K, function()
		for _, q in ipairs(hAll) do
			if q.Parent then
				tween(q, 0.9, { Transparency = 0.1 })
			end
		end
		Fx.sound("ping", 1, 0.4, c0)
		shake(0.6)
	end)
	-- 둘레에 솟는 돌기둥 열둘 (삼재진의 테두리). 찍는 순간 무너진다
	local pillars: { BasePart } = {}
	for k2 = 1, 12 do
		local a = k2 / 12 * math.pi * 2
		local pp = g + Vector3.new(math.cos(a) * 46, 0, math.sin(a) * 46)
		local gp3, gc3 = groundAt(pp, m)
		local h = 30 + (k2 % 3) * 8
		local pil3 = Instance.new("Part")
		pil3.Anchored = true
		pil3.CanCollide = false
		pil3.CanQuery = false
		pil3.CanTouch = false
		pil3.Size = Vector3.new(5, 0.5, 5)
		pil3.Color = gc3:Lerp(Color3.fromRGB(60, 56, 52), 0.6)
		pil3.Material = Enum.Material.Slate
		pil3.CFrame = CFrame.new(gp3)
		pil3.Parent = folder
		table.insert(pillars, pil3)
		task.delay((0.4 + k2 * 0.09) * K, function()
			tween(pil3, 0.7, { Size = Vector3.new(5, h, 5), CFrame = CFrame.new(gp3 + Vector3.new(0, h / 2, 0)) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			Fx.burst("dust", gp3, Color3.fromRGB(175, 160, 140), 6, 1.4)
			Fx.breakSound("boom", 0.35, 0.8, gp3)
			local cap = part(Vector3.new(2.6, 2.6, 2.6), TRIO[k2 % 3 + 1], Enum.Material.Neon, 0.1, "ball")
			cap.Position = gp3 + Vector3.new(0, 0.5, 0)
			tween(cap, 0.7, { Position = gp3 + Vector3.new(0, h + 2, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			table.insert(pillars, cap)
			local line = part(Vector3.new(0.5, h, 0.5), GOLD, Enum.Material.Neon, 0.2)
			line.CFrame = CFrame.new(gp3 + Vector3.new(math.cos(a) * -2.6, h / 2, math.sin(a) * -2.6))
			table.insert(pillars, line)
		end)
	end
	-- 하늘이 갈라진다: 후반에 하늘 높이 금빛 십자가 커진다
	local rift: { BasePart } = {}
	task.delay(4.4 * K, function()
		for i2 = 1, 2 do
			local bar = part(Vector3.new(500, 3, 3), i2 == 1 and GOLD or HUMAN, Enum.Material.Neon, 0.1)
			bar.CFrame = CFrame.new(g + Vector3.new(0, 210, 0)) * CFrame.Angles(0, math.rad(i2 * 90), math.rad(i2 == 1 and 0 or 0))
			bar.Size = Vector3.new(8, 3, 3)
			tween(bar, 0.9, { Size = Vector3.new(500, 5, 5) })
			table.insert(rift, bar)
		end
		Fx.sound("whoosh", 1, 0.3, c0)
		shake(0.8)
	end)

	local lastBolt = 0
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local e = os.clock() - t0
		if e > stomp + 0.05 then
			conn:Disconnect()
			return
		end
		local rr = rootOf(m)
		local ctr = (rr and rr.Position or c0) + Vector3.new(0, 0.5, 0)
		circle.CFrame = CFrame.new(g) * CFrame.Angles(0, e * (0.25 + e * 0.12), 0)
		halo.CFrame = CFrame.lookAt(haloC, haloC + lookV) * CFrame.Angles(0, 0, e * 0.5)
		-- 고리: 시간이 갈수록 빨리 돈다
		for _, gy in ipairs(gyros) do
			if e >= gy.born then
				if not gy.shown then
					gy.shown = true
					appear(gy.all, 1, 0.12, 0.5)
					Fx.sound("ping", 0.8, 0.5 + gy.born * 0.2, ctr)
					Fx.ring(ctr - Vector3.new(0, 2.5, 0), GOLD, 3, 30, 0.6)
					shake(0.4)
				end
				local sp = gy.sp * (1 + e * 0.5)
				gy.hub.CFrame = CFrame.new(ctr) * gy.tilt * CFrame.Angles(0, 0, e * sp)
			end
		end
		-- 바위: 천천히 떠올라 천천히 돈다
		local u = math.clamp(e / (stomp - 0.4), 0, 1)
		local lift = u * u * (3 - 2 * u)
		for _, rk in ipairs(rocks) do
			local y = rk.up * lift + math.sin(e * 2 + rk.ph) * 0.3 * lift
			rk.p.CFrame = CFrame.new(rk.base.Position + Vector3.new(0, y, 0)) * CFrame.Angles(e * 0.4 * lift + rk.ph, e * 0.6 * lift, 0)
		end
		-- 기둥: 휘두를수록 굵어진다
		local w = 1.5 + (e / stomp) ^ 1.6 * 24
		pil.Size = Vector3.new(700, w, w)
		pil2.Size = Vector3.new(700, w * 2.4, w * 2.4)
		pil.Transparency = 0.45 - 0.35 * (e / stomp)
		-- 후반: 하늘에서 벼락이 땅을 때린다
		if e > 3.6 * K and e - lastBolt > 0.2 then
			lastBolt = e
			local a = math.random() * math.pi * 2
			local d = 26 + math.random() * 22
			local bp = g + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
			local bolt = part(Vector3.new(260, 0.5, 0.5), Color3.fromRGB(230, 245, 255), Enum.Material.Neon, 0)
			bolt.CFrame = CFrame.new(bp + Vector3.new(0, 130, 0)) * CFrame.Angles(0, 0, math.rad(90))
			fadeOut(bolt, 0.16)
			Fx.ring(bp, SKY, 2, 12, 0.35)
			Fx.burst("spark", bp + Vector3.new(0, 1, 0), SKY, 6, 1.2)
			if math.random() < 0.5 then
				Fx.breakSound("boom", 0.4, 1.3, bp)
			end
		end
	end)

	-- 찍는 순간: 모든 것이 한꺼번에 무너진다
	return function()
		for _, rk in ipairs(rocks) do
			local p = rk.p
			tween(p, 0.28, { CFrame = rk.rest }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.3, function()
				Fx.burst("dust", rk.rest.Position, Color3.fromRGB(175, 160, 140), 4, 1.1)
			end)
			task.delay(8 + math.random() * 2, function()
				tween(p, 2, { CFrame = rk.rest - Vector3.new(0, 4, 0) })
				task.delay(2.1, function()
					p:Destroy()
				end)
			end)
		end
		for _, pl in ipairs(pillars) do
			if pl.Parent then
				tween(pl, 0.9, { Transparency = 1, Position = pl.Position - Vector3.new(0, 14, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.delay(1, function()
					pl:Destroy()
				end)
			end
		end
		for _, bar in ipairs(rift) do
			tween(bar, 0.6, { Transparency = 1 })
			task.delay(0.7, function()
				bar:Destroy()
			end)
		end
		halo:Destroy()
		pil.Size = Vector3.new(700, 3, 3)
		tween(pil, 1.4, { Transparency = 1 })
		tween(pil2, 1.8, { Transparency = 1, Size = Vector3.new(700, 80, 80) })
		for _, q in ipairs(all) do
			if q.Parent then
				tween(q, 0.6, { Transparency = 1 })
			end
		end
		task.delay(1.2, function()
			for _, q in ipairs(all) do
				q:Destroy()
			end
			pil:Destroy()
			pil2:Destroy()
			for _, gy in ipairs(gyros) do
				gy.hub:Destroy()
			end
			circle:Destroy()
		end)
	end
end

local LINES: { { number | string } } = {
	{ 1.0, "하늘을 받치고" },
	{ 2.8, "땅을 딛고" },
	{ 4.3, "사람이 휘두른다" },
	{ 5.3, "천지가 하나로" },
}

function Sin.rite(d: any)
	local m0: Model? = d.m
	local r = rootOf(m0)
	if not m0 or not r then
		return
	end
	local m = m0 :: Model
	local skill = d.skill == true
	local mine = (not skill) and (m == player.Character)
	local at: Vector3 = d.at or r.Position
	local total: number = d.total or 8.6
	local stomp: number = d.stomp or 6.1
	local cam = workspace.CurrentCamera :: Camera
	local dist = cam and (cam.CFrame.Position - at).Magnitude or 1e9
	if not mine and dist > 220 then
		return
	end
	local t0 = os.clock()
	-- 동작은 모두에게 (Poses.sn_get은 7.4초 길이의 동작이라 컷씬 길이에 맞춰 편다)
	local K = stomp / 6.1
	if not skill then
		Anim.play(m, "sn_get", stomp * (7.4 / 6.1), {})
	end

	-- 모으기: 하늘 · 땅 · 사람, 세 빛깔의 고리가 몸으로 모여든다
	if opts.tint and (mine or skill) and not skill then
		opts.tint(Color3.fromRGB(125, 135, 185), 0.42, stomp)
	end
	local slam = buildUp(m, stomp, K)
	-- 몸에서 번지는 금빛: 휘두를수록 짙어지고, 찍는 순간 하얗게 터졌다가 가라앉는다
	local aura = Instance.new("Highlight")
	aura.Adornee = m
	aura.FillColor = GOLD
	aura.OutlineColor = HUMAN
	aura.FillTransparency = 0.95
	aura.OutlineTransparency = 0.4
	aura.DepthMode = Enum.HighlightDepthMode.Occluded
	aura.Parent = folder
	tween(aura, stomp, { FillTransparency = 0.55 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(stomp, function()
		aura.FillColor = HUMAN
		aura.FillTransparency = 0.1
		tween(aura, 1.6, { FillTransparency = 1, OutlineTransparency = 1 })
		task.delay(1.7, function()
			aura:Destroy()
		end)
	end)
	for i = 0, 2 do
		task.delay(i * 0.28 * K, function()
			local rr = rootOf(m)
			if rr then
				Fx.ring(rr.Position - Vector3.new(0, 2.5, 0) + Vector3.new(0, i * 1.4, 0), TRIO[i + 1], 40, 3, 0.8)
				Fx.sound("ping", 0.7, 0.6 + i * 0.2, rr.Position)
			end
		end)
	end
	-- 휘두름 여섯: 앞의 둘은 허리만 틀고, 뒤의 넷은 몸째 돈다 (점점 커지고 빨라진다)
	local sw = { 1.05 * K, 1.4 * K, 1.75 * K, 2.1 * K, 2.8 * K, 3.35 * K, 3.85 * K, 4.3 * K, 4.7 * K }
	for i, sec in ipairs(sw) do
		task.delay(sec, function()
			swing(m, i, TRIO[(i - 1) % 3 + 1], i > 4)
		end)
	end
	-- 몸으로 빨려 드는 빛 가루 (갈수록 많이)
	local conn0: RBXScriptConnection
	conn0 = RunService.Heartbeat:Connect(function()
		local e = os.clock() - t0
		local rr = rootOf(m)
		if e > stomp or not rr then
			conn0:Disconnect()
			return
		end
		if e > 0.4 and math.random() < 0.25 + e * 0.07 then
			local a = math.random() * math.pi * 2
			local far = 12 + math.random() * 8
			local from = rr.Position + Vector3.new(math.cos(a) * far, math.random() * 10 - 4, math.sin(a) * far)
			local mote = part(Vector3.new(0.5, 0.5, 0.5), TRIO[math.random(1, 3)], Enum.Material.Neon, 0.1, "ball")
			mote.Position = from
			tween(mote, 0.45, { Position = rr.Position, Size = Vector3.new(0.1, 0.1, 0.1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.47, function()
				mote:Destroy()
			end)
		end
	end)
	-- 무릎을 들어 올릴 때 땅 위로 기운이 솟는다
	task.delay(5.3 * K, function()
		local rr = rootOf(m)
		if not rr then
			return
		end
		Fx.sound("whoosh", 1, 0.4, rr.Position)
		for i = 0, 5 do
			task.delay(i * 0.13, function()
				local r2 = rootOf(m)
				if r2 then
					Fx.ring(r2.Position - Vector3.new(0, 2.5, 0), GOLD, 26, 4, 0.5)
				end
			end)
		end
		shake(0.5)
	end)
	-- 땅을 찍는다
	task.delay(stomp, function()
		local rr = rootOf(m)
		local pos = rr and rr.Position - Vector3.new(0, 2.8, 0) or at
		breakGround(m, pos, slam)
	end)

	if not mine then
		return
	end

	----------------------------------------------------------------
	-- 내 화면: 카메라 · 검은 띠 · 글귀 (찍는 순간 컷씬이 끝난다)
	----------------------------------------------------------------
	Cutscene.active = true
	local pg = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "KwonSinRite"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 70
	gui.Parent = pg
	local function bar(top: boolean): Frame
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0, top and 0 or 1)
		f.Position = UDim2.fromScale(0, top and 0 or 1)
		f.Size = UDim2.fromScale(1, 0)
		f.Parent = gui
		return f
	end
	local top, bottom = bar(true), bar(false)
	tween(top, 0.5, { Size = UDim2.fromScale(1, 0.12) })
	tween(bottom, 0.5, { Size = UDim2.fromScale(1, 0.12) })
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.AnchorPoint = Vector2.new(0.5, 1)
	text.Position = UDim2.fromScale(0.5, 0.88)
	text.Size = UDim2.fromScale(0.8, 0.07)
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.TextColor3 = GOLD
	text.TextStrokeTransparency = 0.3
	text.TextTransparency = 1
	text.Text = ""
	text.Parent = gui
	for _, ln in ipairs(LINES) do
		task.delay(ln[1] :: number, function()
			text.Text = ln[2] :: string
			text.TextTransparency = 0.6
			tween(text, 0.25, { TextTransparency = 0 })
			task.delay(1.1, function()
				tween(text, 0.4, { TextTransparency = 1 })
			end)
		end)
	end

	local oldType = cam.CameraType
	local oldFov = cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable
	local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
	local a0 = math.atan2(look.Z, look.X)
	local ang = 0
	local last = os.clock()
	local done = false
	local conn: RBXScriptConnection
	local function finish()
		if done then
			return
		end
		done = true
		conn:Disconnect()
		tween(top, 0.4, { Size = UDim2.fromScale(1, 0) })
		tween(bottom, 0.4, { Size = UDim2.fromScale(1, 0) })
		pcall(function()
			cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
			cam.FieldOfView = oldFov
		end)
		Cutscene.active = false
		task.delay(0.6, function()
			gui:Destroy()
		end)
	end
	conn = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local dt = math.min(0.1, now - last)
		last = now
		local e = now - t0
		local rr = rootOf(m)
		if not rr or e > stomp + 1.5 then
			finish()
			return
		end
		-- 도는 빠르기: 허리만 틀 때는 느리게, 몸째 돌 때 점점 빨라진다
		local spd = 0.12
		if e > 1 then
			spd = 0.35
		end
		if e > 2.4 then
			spd = 0.35 + (e - 2.4) * 0.5
		end
		if e > 5.1 then
			spd = 0.15
		end
		ang += dt * spd
		local dd, h, fh = 24, 5, 2
		if e < 1 then
			dd = 26 - e * 4
		elseif e < 5.1 then
			local u = (e - 1) / 4.1
			dd = 22 - u * 9
			h = 4 + u * 3
		elseif e < stomp then
			local u = (e - 5.1) / (stomp - 5.1)
			dd = 13 - u * 3
			h = 7 - u * 8.5 -- 아래로 내려가 올려다본다 (치켜든 무릎과 팔)
			fh = 3 + u * 2
		else
			local u = math.min(1, (e - stomp) / 0.4)
			dd = 10 + u * 14
			h = -1.5 + u * 9
			fh = 5 - u * 3
		end
		local focus = rr.Position + Vector3.new(0, fh, 0)
		local a = a0 + math.pi + ang
		local eye = focus + Vector3.new(math.cos(a) * dd, h, math.sin(a) * dd)
		-- 몸째 돌 때는 화각을 넓히고 화면이 기울어 휘청이고, 무릎을 들 때는 좁혀 조인다
		local roll = 0
		if e < stomp then
			if e < 5.1 then
				local wide = math.clamp((e - 2.2) / 1.2, 0, 1)
				cam.FieldOfView = oldFov + 16 * wide
				roll = math.sin(e * 3) * 0.05 * wide
			else
				local u = (e - 5.1) / (stomp - 5.1)
				cam.FieldOfView = oldFov + 16 - 30 * u
			end
		end
		cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(eye, focus), 0.25) * CFrame.Angles(0, 0, roll)
	end)
	task.delay(stomp, function()
		if done then
			return
		end
		pcall(function()
			cam.FieldOfView = oldFov - 22
			tween(cam, 1.4, { FieldOfView = oldFov + 6 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end)
		if opts.flash then
			opts.flash(Color3.new(1, 1, 1), 0.7)
		end
		local big = Instance.new("TextLabel")
		big.BackgroundTransparency = 1
		big.AnchorPoint = Vector2.new(0.5, 0.5)
		big.Position = UDim2.fromScale(0.5, 0.42)
		big.Size = UDim2.fromScale(0.3, 0.12)
		big.Font = Enum.Font.GothamBlack
		big.TextScaled = true
		big.Text = "天 地 開 闢"
		big.TextColor3 = Color3.new(1, 1, 1)
		big.TextStrokeColor3 = Color3.fromRGB(255, 190, 70)
		big.TextStrokeTransparency = 0
		big.TextTransparency = 0
		big.ZIndex = 5
		big.Parent = gui
		tween(big, 1.3, { Size = UDim2.fromScale(0.62, 0.25) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.9, function()
			tween(big, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
		end)
	end)
	for i, sec in ipairs(sw) do
		task.delay(sec, function()
			if done then
				return
			end
			pcall(function()
				cam.FieldOfView += 5
				tween(cam, 0.25, { FieldOfView = cam.FieldOfView - 5 })
			end)
			if i % 3 == 0 and opts.flash then
				opts.flash(i % 2 == 0 and SKY or GOLD, 0.25)
			end
		end)
	end
	-- 안전망
	task.delay(total + 2, finish)
end

------------------------------------------------------------------------
-- 신 삼재권 기술 연출 (기존 붙잡기·충격 연출 위에 얹는다): 금빛 기둥 · 세 빛깔 고리 · 땅에 찍히는 神 도장
------------------------------------------------------------------------
local function stamp(at: Vector3, R: number)
	local g0 = groundAt(at, nil)
	local pad = part(Vector3.new(R * 1.5, 0.2, R * 1.5), GOLD, Enum.Material.Neon, 1)
	pad.CFrame = CFrame.new(Vector3.new(at.X, g0.Y + 0.25, at.Z))
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Top
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 16
	sg.AlwaysOnTop = false
	sg.LightInfluence = 0
	sg.Parent = pad
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Text = "神"
	tl.TextScaled = true
	tl.Font = Enum.Font.GothamBlack
	tl.TextColor3 = Color3.fromRGB(255, 226, 140)
	tl.TextStrokeColor3 = Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0.2
	tl.Parent = sg
	task.delay(0.9, function()
		TweenService:Create(tl, TweenInfo.new(1.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	task.delay(2.6, function()
		pad:Destroy()
	end)
end

local function impact(at: Vector3, R: number, power: number)
	local g0 = groundAt(at, nil)
	local g = Vector3.new(at.X, g0.Y, at.Z)
	Fx.ring(g + Vector3.new(0, 0.3, 0), HUMAN, 3, R * 3.2, 0.6)
	task.delay(0.07, function()
		Fx.ring(g + Vector3.new(0, 0.3, 0), GOLD, 3, R * 2.4, 0.7)
	end)
	task.delay(0.14, function()
		Fx.ring(g + Vector3.new(0, 0.3, 0), SKY, 3, R * 1.7, 0.8)
	end)
	local col = part(Vector3.new(160, R * 0.5, R * 0.5), HUMAN, Enum.Material.Neon, 0.1, "cyl")
	col.CFrame = CFrame.new(g + Vector3.new(0, 78, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(col, 0.5, { Size = Vector3.new(160, 1.5, 1.5) })
	fadeOut(col, 0.55)
	local halo = part(Vector3.new(160, R * 1.1, R * 1.1), GOLD, Enum.Material.Neon, 0.55, "cyl")
	halo.CFrame = col.CFrame
	fadeOut(halo, 0.8, { Size = Vector3.new(160, R * 2.2, R * 2.2) })
	stamp(g, R)
	for k = 1, 8 do
		local a = k / 8 * math.pi * 2 + math.random() * 0.3
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local len = R * (1.2 + math.random() * 1.2)
		local mid = g + dir * (len * 0.5) + Vector3.new(0, 0.15, 0)
		local crack = part(Vector3.new(len, 0.12, 0.9), GOLD, Enum.Material.Neon, 0.1)
		crack.CFrame = CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, math.rad(90), 0)
		task.delay(1.0, function()
			fadeOut(crack, 1.2)
		end)
	end
	Fx.debris(g, math.floor(8 + R), R * 1.6)
	Fx.burst("spark", g + Vector3.new(0, 1, 0), GOLD, 24, 2)
	Fx.flash(g + Vector3.new(0, 4, 0), HUMAN, R * 5, 3, 0.4)
	Fx.breakSound("boom", 1, 0.5, g)
	shake(0.8 + power)
end

function Sin.extra(data: any)
	local k = data.kind
	if k == "grabSlam" and typeof(data.at) == "Vector3" then
		impact(data.at, math.clamp(data.radius or 10, 6, 20), 0.9)
	elseif k == "shock" and typeof(data.at) == "Vector3" then
		impact(data.at, math.clamp(data.radius or 14, 8, 24), 1.4)
	elseif k == "grab" and type(data.targets) == "table" then
		local life = (data.reel or 0.2) + (data.hold or 0.4) + 0.3
		for _, t in ipairs(data.targets) do
			if typeof(t) == "Instance" and t:IsA("Model") then
				local hl = Instance.new("Highlight")
				hl.Adornee = t
				hl.FillColor = GOLD
				hl.OutlineColor = HUMAN
				hl.FillTransparency = 0.35
				hl.Parent = folder
				task.delay(life, function()
					hl:Destroy()
				end)
			end
		end
	elseif k == "grabFly" and typeof(data.t) == "Instance" then
		for i = 0, 4 do
			task.delay(i * 0.1, function()
				if data.t and data.t.Parent then
					Fx.afterimage(data.t :: Model, GOLD, 0.35)
				end
			end)
		end
	elseif k == "pulse" and typeof(data.at) == "Vector3" then
		Fx.ring(data.at - Vector3.new(0, 2.5, 0), GOLD, 3, (data.radius or 10) * 2.4, 0.5)
	end
end

-- 기술을 쓰는 순간: 발밑 세 빛깔 고리 + 몸의 금빛. 초 오의는 컷씬의 모든 연출 (삼재진 · 큰 고리 · 돌기둥 · 광배 · 하늘 갈라짐)을 그대로 쓴다
function Sin.cast(slot: string, model: Model, dur: number)
	local r = rootOf(model)
	if not r then
		return
	end
	if opts.shake == nil then
		return
	end
	local base = r.Position - Vector3.new(0, 2.6, 0)
	if slot == "X" then
		Sin.rite({ m = model, at = r.Position, stomp = dur * 0.824, total = dur, skill = true })
		return
	end
	local n = slot == "G" and 3 or 2
	for i = 0, n - 1 do
		task.delay(i * 0.1, function()
			Fx.ring(base, TRIO[i % 3 + 1], 4, 20 + i * 8 + (slot == "G" and 14 or 0), 0.5)
		end)
	end
	local hl = Instance.new("Highlight")
	hl.Adornee = model
	hl.FillColor = GOLD
	hl.OutlineColor = HUMAN
	hl.FillTransparency = 0.7
	hl.Parent = folder
	TweenService:Create(hl, TweenInfo.new(math.max(0.3, dur * 0.8)), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	task.delay(dur + 0.2, function()
		hl:Destroy()
	end)
	Fx.breakSound("whoosh", 0.8, 0.6, r.Position)
	shake(slot == "G" and 0.6 or 0.3)
end

-- 겹치는 순환을 피해 Fx가 부를 수 있게 달아 둔다
(Fx :: any).sinCast = Sin.cast

return Sin
