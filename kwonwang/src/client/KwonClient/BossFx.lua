-- 권왕 3.26판: 보스 패턴의 웅장함. 패턴이 시작될 때 보스가 기를 모아 땅이 울리고 (모이는 고리와 빛기둥),
-- 터질 때 겹겹의 충격파 · 빛기둥 · 갈라지는 땅 · 튀는 돌 · 화면 흔들림이 크게 인다. 기존 바닥 경고 표시 위에 더 얹는다
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Fx = require(script.Parent:WaitForChild("Fx"))

local BossFx = {}

local folder = Instance.new("Folder")
folder.Name = "KwonBossFx"
folder.Parent = workspace

local opts: any = {}
function BossFx.init(o: any)
	opts = o or {}
end

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal):Play()
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
end
local function distTo(pos: Vector3): number
	local cam = workspace.CurrentCamera
	return cam and (cam.CFrame.Position - pos).Magnitude or 1e9
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
local function ground(at: Vector3): Vector3
	return Vector3.new(at.X, at.Y - 2.6, at.Z)
end
local function rootOf(m: any): BasePart?
	local r = typeof(m) == "Instance" and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function shakeBy(at: Vector3, power: number)
	local d = distTo(at)
	if opts.shake and d < 320 then
		opts.shake(math.min(2.4, power * (1 - d / 360)))
	end
end

local H: { [string]: (any) -> () } = {}
local WHITE = Color3.new(1, 1, 1)

-- 패턴이 시작될 때: 보스 둘레로 큰 고리가 모여들고 빛기둥이 솟아 기를 모은다
function H.bossStart(d: any)
	local r = rootOf(d.m)
	if not r or not near(r.Position, 420) then
		return
	end
	local color: Color3 = d.color or Color3.fromRGB(255, 70, 50)
	local R = math.clamp(d.radius or 20, 10, 80)
	local t = math.max(0.3, d.time or 1)
	local g = ground(r.Position)
	-- 모여드는 고리 둘 (바깥에서 보스에게로)
	Fx.ring(g, color, R * 2.2, 3, t)
	task.delay(t * 0.25, function()
		Fx.ring(g, Color3.new(1, 1, 1), R * 1.6, 2, t * 0.7)
	end)
	-- 보스 곁에서 솟는 가는 빛기둥 (기가 모일수록 굵어진다)
	local pillar = part(Vector3.new(60, 1, 1), color, Enum.Material.Neon, 0.35, "cyl")
	pillar.CFrame = CFrame.new(g + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(pillar, t, { Size = Vector3.new(80, 4 + R * 0.12, 4 + R * 0.12), Transparency = 0.6 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(t + 0.05, function()
		pillar:Destroy()
	end)
	Fx.flash(r.Position + Vector3.new(0, 4, 0), color, 40, 2, t)
	Fx.breakSound("whoosh", 0.8, 0.55, r.Position)
	-- 땅이 낮게 울린다
	task.delay(t * 0.6, function()
		shakeBy(r.Position, 0.35)
	end)
end

-- 패턴이 터질 때
function H.bossImpact(d: any)
	local at: Vector3 = d.at
	if not near(at, 450) then
		return
	end
	local color: Color3 = d.color or Color3.fromRGB(255, 70, 50)
	local R = math.clamp(d.radius or 20, 6, 90)
	local g = ground(at)
	local kind = d.pkind or "quake"
	-- 겹겹의 충격파
	Fx.ring(g, Color3.new(1, 1, 1), 3, R * 2.4, 0.55)
	task.delay(0.07, function()
		Fx.ring(g, color, 3, R * 2.0, 0.65)
	end)
	task.delay(0.16, function()
		Fx.ring(g, color, 3, R * 1.4, 0.7)
	end)
	-- 솟는 빛기둥: 터진 자리에서 하늘로
	local col = part(Vector3.new(120, 6, 6), Color3.new(1, 1, 1), Enum.Material.Neon, 0.1, "cyl")
	col.CFrame = CFrame.new(g + Vector3.new(0, 55, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(col, 0.5, { Size = Vector3.new(120, 2, 2) })
	fadeOut(col, 0.55)
	local halo = part(Vector3.new(120, R * 0.5, R * 0.5), color, Enum.Material.Neon, 0.55, "cyl")
	halo.CFrame = col.CFrame
	fadeOut(halo, 0.7, { Size = Vector3.new(120, R * 0.9, R * 0.9) })
	-- 둥근 충격 돔
	local dome = part(Vector3.new(2, 2, 2), color, Enum.Material.Neon, 0.55, "ball")
	dome.Position = g
	fadeOut(dome, 0.55, { Size = Vector3.new(R * 1.7, R * 0.9, R * 1.7) })
	-- 갈라지는 땅: 바깥으로 뻗는 균열
	local n = kind == "rain" and 4 or 10
	for k = 1, n do
		local a = k / n * math.pi * 2 + math.random() * 0.3
		local len = R * (0.6 + math.random() * 0.5)
		local crack = part(Vector3.new(len, 0.15, 1.3), Color3.fromRGB(255, 130, 60):Lerp(color, 0.5), Enum.Material.Neon, 0.2)
		crack.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * len * 0.5, 0.2, math.sin(a) * len * 0.5)) * CFrame.Angles(0, -a, 0)
		task.delay(0.9, function()
			fadeOut(crack, 0.9)
		end)
	end
	Fx.debris(at, math.floor(10 + R * 0.5), R * 0.8)
	Fx.burst("spark", at, color, 16, 2.2)
	-- 3.47판: 그을린 땅 (천천히 식는다) · 하늘로 튀는 불티 고리
	local scorch = part(Vector3.new(0.2, R * 1.7, R * 1.7), Color3.fromRGB(30, 18, 16), Enum.Material.Slate, 0.25, "cyl")
	scorch.CFrame = CFrame.new(g + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local glow = part(Vector3.new(0.22, R * 1.3, R * 1.3), color, Enum.Material.Neon, 0.35, "cyl")
	glow.CFrame = scorch.CFrame * CFrame.new(0.02, 0, 0)
	task.delay(0.4, function()
		fadeOut(glow, 1.4)
		fadeOut(scorch, 2.2)
	end)
	for k = 1, 10 do
		local a = k / 10 * math.pi * 2
		local ember = part(Vector3.new(0.6, 0.6, 0.6), color:Lerp(WHITE, 0.3), Enum.Material.Neon, 0, "ball")
		ember.Position = g + Vector3.new(math.cos(a) * R * 0.3, 1, math.sin(a) * R * 0.3)
		fadeOut(ember, 0.7, { Position = ember.Position + Vector3.new(math.cos(a) * R * 0.5, 10 + math.random() * 8, math.sin(a) * R * 0.5), Size = Vector3.new(0.15, 0.15, 0.15) })
	end
	Fx.flash(at + Vector3.new(0, 4, 0), color, 55, 2.4, 0.4)
	Fx.breakSound("boom", 1, 0.6, at)
	shakeBy(at, 0.7 + R / 35)
end

-- 돌진할 때: 지나간 길에 먼지의 파도
function H.bossDash(d: any)
	local a: Vector3, b: Vector3 = d.from, d.to
	if not near(a, 400) then
		return
	end
	local color: Color3 = d.color or Color3.fromRGB(255, 70, 50)
	local dir = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = dir.Magnitude
	if len < 1 then
		return
	end
	dir = dir.Unit
	for k = 0, math.floor(len / 8) do
		task.delay(k * 0.035, function()
			local p = a + dir * (k * 8)
			Fx.ring(ground(p), Color3.new(1, 1, 1), 2, (d.width or 10) * 1.6, 0.4)
			Fx.debris(p, 4, 6)
		end)
	end
	local streak = part(Vector3.new(len, 1.2, 1.2), color, Enum.Material.Neon, 0.3, "cyl")
	streak.CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 2, 0), b + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(90), 0)
	streak.Size = Vector3.new(len, d.width or 10, d.width or 10)
	streak.Transparency = 0.7
	fadeOut(streak, 0.45)
	Fx.breakSound("whoosh", 1, 0.5, a)
	shakeBy(a, 0.9)
end

------------------------------------------------------------------------
-- 3.47판 보스 전용 경고 표시: 테두리 (빛 조각을 이어 또렷한 고리) · 가운데서 차오르는 바닥 · 도는 문양 · 터지기 직전 하얗게 번쩍
------------------------------------------------------------------------
local function flatDisc(at: Vector3, r: number, color: Color3, alpha: number, lift: number): BasePart
	local d = part(Vector3.new(0.2, r * 2, r * 2), color, Enum.Material.Neon, alpha, "cyl")
	d.CFrame = CFrame.new(at + Vector3.new(0, lift, 0)) * CFrame.Angles(0, 0, math.rad(90))
	return d
end
local function rimRing(g: Vector3, r: number, color: Color3, lift: number): { BasePart }
	local n = math.clamp(math.floor(r * 1.4), 14, 48)
	local out = {}
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		local p = g + Vector3.new(math.cos(a) * r, lift, math.sin(a) * r)
		local seg = part(Vector3.new(2 * math.pi * r / n + 0.15, 0.25, math.clamp(r * 0.06, 0.35, 1.2)), color, Enum.Material.Neon, 0.15, nil)
		seg.CFrame = CFrame.lookAt(p, Vector3.new(g.X, p.Y, g.Z))
		table.insert(out, seg)
	end
	return out
end
local function finish(list: { BasePart }, time: number)
	task.delay(time, function()
		for _, p in ipairs(list) do
			if p.Parent then
				p.Color = WHITE
				fadeOut(p, 0.18)
			end
		end
	end)
end
H.bossTele = function(d)
	local at, r, time = d.at, math.max(1, d.radius or 6), math.max(0.15, d.time or 1)
	if not near(at, 320) then
		return
	end
	local color: Color3 = d.color or Color3.fromRGB(255, 60, 40)
	local g = ground(at)
	local all: { BasePart } = {}
	local base = flatDisc(g, r, color, 0.86, 0.12)
	table.insert(all, base)
	for _, sgm in ipairs(rimRing(g, r, color, 0.2)) do
		table.insert(all, sgm)
	end
	local fill = flatDisc(g, 0.4, color, 0.55, 0.16)
	tween(fill, time, { Size = Vector3.new(0.2, r * 2, r * 2) }, Enum.EasingStyle.Linear)
	table.insert(all, fill)
	-- 도는 문양 (큰 원만): 안쪽 고리 위로 마름모 여섯이 천천히 돈다
	if r >= 7 then
		local tiles = {}
		for k = 1, 6 do
			local t = part(Vector3.new(r * 0.12, 0.22, r * 0.12), color:Lerp(WHITE, 0.35), Enum.Material.Neon, 0.25, nil)
			table.insert(tiles, t)
			table.insert(all, t)
		end
		local t0 = os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local t = os.clock() - t0
			if t > time or not tiles[1].Parent then
				conn:Disconnect()
				return
			end
			for k, tl in ipairs(tiles) do
				local a = k / 6 * math.pi * 2 + t * 1.6
				tl.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * r * 0.72, 0.24, math.sin(a) * r * 0.72)) * CFrame.Angles(0, -a + math.rad(45), 0)
			end
		end)
	end
	-- 큰 원: 한가운데 희미한 경고 빛기둥
	if r >= 14 then
		local col = part(Vector3.new(30, r * 0.25, r * 0.25), color, Enum.Material.Neon, 0.88, "cyl")
		col.CFrame = CFrame.new(g + Vector3.new(0, 15, 0)) * CFrame.Angles(0, 0, math.rad(90))
		tween(col, time, { Transparency = 0.7 })
		table.insert(all, col)
	end
	finish(all, time)
end
H.bossLineTele = function(d)
	local from, to, w, time = d.from, d.to, d.width or 8, math.max(0.15, d.time or 1)
	if not near(from, 320) then
		return
	end
	local color: Color3 = d.color or Color3.fromRGB(255, 60, 40)
	local a, b = ground(from), ground(to)
	local len = (b - a).Magnitude
	if len < 0.5 then
		return
	end
	local cf = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 0.15, 0), b + Vector3.new(0, 0.15, 0))
	local all: { BasePart } = {}
	local base = part(Vector3.new(w, 0.2, len), color, Enum.Material.Neon, 0.86, nil)
	base.CFrame = cf
	table.insert(all, base)
	for sx = -1, 1, 2 do
		local edge = part(Vector3.new(math.clamp(w * 0.08, 0.3, 1), 0.25, len), color, Enum.Material.Neon, 0.1, nil)
		edge.CFrame = cf * CFrame.new(sx * w / 2, 0.05, 0)
		table.insert(all, edge)
	end
	local fill = part(Vector3.new(w, 0.22, 0.3), color, Enum.Material.Neon, 0.55, nil)
	fill.CFrame = cf * CFrame.new(0, 0.03, len / 2)
	tween(fill, time, { Size = Vector3.new(w, 0.22, len), CFrame = cf * CFrame.new(0, 0.03, 0) }, Enum.EasingStyle.Linear)
	table.insert(all, fill)
	-- 쏠리는 화살표 (갈 쪽으로 흐른다)
	local n = math.clamp(math.floor(len / 10), 1, 6)
	for k = 0, n - 1 do
		local chev = part(Vector3.new(w * 0.5, 0.24, w * 0.18), color:Lerp(WHITE, 0.4), Enum.Material.Neon, 0.35, nil)
		local z0 = len / 2 - (k / n) * len
		chev.CFrame = cf * CFrame.new(0, 0.06, z0)
		tween(chev, time, { CFrame = cf * CFrame.new(0, 0.06, z0 - len / n) }, Enum.EasingStyle.Linear)
		table.insert(all, chev)
	end
	finish(all, time)
end
H.bossDonut = function(d)
	local at, r0, r1, time = d.at, d.inner or 6, d.outer or 20, math.max(0.15, d.time or 1)
	if not near(at, 320) then
		return
	end
	local color: Color3 = d.color or Color3.fromRGB(255, 60, 40)
	local g = ground(at)
	local all: { BasePart } = {}
	table.insert(all, flatDisc(g, r1, color, 0.8, 0.12))
	local safe = flatDisc(g, r0, Color3.fromRGB(110, 255, 150), 0.6, 0.18)
	table.insert(all, safe)
	for _, sgm in ipairs(rimRing(g, r1, color, 0.2)) do
		table.insert(all, sgm)
	end
	for _, sgm in ipairs(rimRing(g, r0, Color3.fromRGB(150, 255, 180), 0.22)) do
		table.insert(all, sgm)
	end
	local fill = flatDisc(g, r1, color, 0.95, 0.15)
	tween(fill, time, { Transparency = 0.6 }, Enum.EasingStyle.Linear)
	table.insert(all, fill)
	if r0 >= 5 then
		Fx.text(g + Vector3.new(0, 4, 0), "안으로!", Color3.fromRGB(150, 255, 170), 28, time)
	end
	finish(all, time)
end

-- 3.45판 피난처 (safezone): 초록 원이 숨 쉬듯 빛나고 '여기로!'
H.safeMark = function(d)
	local g = ground(d.at)
	local r, time = d.radius or 8, d.time or 1.5
	local disc = part(Vector3.new(0.3, r * 2, r * 2), Color3.fromRGB(110, 255, 150), Enum.Material.Neon, 0.55, "cyl")
	disc.CFrame = CFrame.new(g + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local col = part(Vector3.new(14, r * 0.5, r * 0.5), Color3.fromRGB(150, 255, 180), Enum.Material.Neon, 0.75, "cyl")
	col.CFrame = CFrame.new(g + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(disc, time, { Transparency = 0.3 })
	task.delay(time, function()
		fadeOut(disc, 0.3)
		fadeOut(col, 0.3)
	end)
	Fx.text(g + Vector3.new(0, 5, 0), "여기로!", Color3.fromRGB(150, 255, 170), 30, time)
end
-- 3.45판 빛줄기 (cross · beam): 땅에서 솟는 얇은 빛의 벽이 줄을 따라 번쩍인다
H.bossBeam = function(d)
	local a, b = ground(d.from), ground(d.to)
	local len = (b - a).Magnitude
	if len < 0.5 or not near(a, 260) then
		return
	end
	local w = d.width or 7
	local color = d.color or Color3.fromRGB(255, 60, 40)
	local wall = part(Vector3.new(w * 0.5, 7, len), color, Enum.Material.Neon, 0.25, nil)
	wall.CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 3.5, 0), b + Vector3.new(0, 3.5, 0))
	local core = part(Vector3.new(w * 0.15, 9, len), Color3.new(1, 1, 1), Enum.Material.Neon, 0.1, nil)
	core.CFrame = wall.CFrame
	fadeOut(wall, 0.35, { Size = Vector3.new(0.2, 12, len) })
	fadeOut(core, 0.25, { Size = Vector3.new(0.1, 14, len) })
	Fx.ring(a + Vector3.new(0, 0.3, 0), color, 2, w * 2, 0.3)
end

-- 3.46판 회전 칼날 (orbit): 보스 둘레를 빛의 칼날이 돈다
H.bossOrbit = function(d)
	local m = d.m
	local r0 = rootOf(m)
	if not r0 or not near(r0.Position, 260) then
		return
	end
	local color = d.color or Color3.fromRGB(255, 60, 40)
	local blades = {}
	for _ = 1, d.n or 3 do
		local b = part(Vector3.new(0.6, 2.2, d.size or 4), color, Enum.Material.Neon, 0.1, nil)
		local core = part(Vector3.new(0.3, 2.6, (d.size or 4) * 0.6), Color3.new(1, 1, 1), Enum.Material.Neon, 0, nil)
		table.insert(blades, { b, core })
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local r = rootOf(m)
		if t > (d.dur or 3) or not r then
			conn:Disconnect()
			for _, bl in ipairs(blades) do
				fadeOut(bl[1], 0.2)
				fadeOut(bl[2], 0.2)
			end
			return
		end
		local c = ground(r.Position) + Vector3.new(0, 1.4, 0)
		for i, bl in ipairs(blades) do
			local a = (d.a0 or 0) + (d.speed or 2) * t + (i - 1) / #blades * math.pi * 2
			local p = c + Vector3.new(math.cos(a), 0, math.sin(a)) * (d.radius or 12)
			local cf = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))) * CFrame.Angles(0, 0, t * 12)
			bl[1].CFrame = cf
			bl[2].CFrame = cf
		end
	end)
end

function BossFx.handles(data: any): boolean
	return H[data.kind] ~= nil
end
function BossFx.run(data: any)
	local fn = H[data.kind]
	if fn then
		fn(data)
	end
end

local _ = RunService
return BossFx
