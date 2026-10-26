-- 권왕 3.1판: 극 권법 (극 일월신권) 의 기술과 일월극변 (화면)
-- 해: 주홍빛 심과 금빛 빛살 · 달: 푸른 흰빛 초승달 · 황혼: 노을빛 주홍과 보랏빛이 겹친다
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Fx = require(script.Parent:WaitForChild("Fx"))

local Geuk = {}

local folder = Instance.new("Folder")
folder.Name = "KwonGeuk"
folder.Parent = workspace

local opts: any = {}
function Geuk.init(o: any)
	opts = o or {}
end

local SUN = Color3.fromRGB(255, 170, 50)
local SUN_CORE = Color3.fromRGB(255, 245, 200)
local MOON = Color3.fromRGB(205, 220, 255)
local DUSK = Color3.fromRGB(255, 120, 60)
local DUSK2 = Color3.fromRGB(165, 95, 235)
local WHITE = Color3.new(1, 1, 1)
local DARK = Color3.fromRGB(20, 14, 30)

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
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
local function shakeNear(pos: Vector3, amount: number, range: number)
	if opts.shake and near(pos, range) then
		opts.shake(amount)
	end
end
local function anim(life: number, fn: (number) -> ())
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / life, 0, 1)
		fn(u)
		if u >= 1 then
			conn:Disconnect()
		end
	end)
end
local function rootOf(m: any): BasePart?
	local r = typeof(m) == "Instance" and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 1e-3 and f.Unit or Vector3.new(0, 0, -1)
end
local function safeLook(from: Vector3, to: Vector3): CFrame
	if (to - from).Magnitude < 1e-3 then
		return CFrame.new(from)
	end
	return CFrame.lookAt(from, to)
end

-- 덩이 (조각 + 덩이 안의 자리)
type Group = { items: { { any } } }
local function group(): Group
	return { items = {} }
end
local function gpart(g: Group, size: Vector3, color: Color3, mat: Enum.Material?, alpha: number?, shape: string?, off: CFrame): BasePart
	local p = part(size, color, mat, alpha, shape)
	p:SetAttribute("A0", alpha or 0)
	table.insert(g.items, { p, off })
	return p
end
local function gset(g: Group, cf: CFrame)
	for _, it in ipairs(g.items) do
		local p = it[1] :: BasePart
		if p.Parent then
			p.CFrame = cf * (it[2] :: CFrame)
		end
	end
end
local function gfade(g: Group, time: number)
	for _, it in ipairs(g.items) do
		local p = it[1] :: BasePart
		if p.Parent then
			fadeOut(p, time)
		end
	end
end
local function galpha(g: Group, k: number)
	for _, it in ipairs(g.items) do
		local p = it[1] :: BasePart
		if p.Parent then
			p.Transparency = math.clamp(math.max(k, p:GetAttribute("A0") or 0), 0, 1)
		end
	end
end

-- 해: 흰 심, 주홍 몸, 둘레의 금빛 빛살 열둘, 바깥의 흐린 빛
local function sunGroup(R: number, color: Color3?): Group
	local g = group()
	local c = color or SUN
	gpart(g, Vector3.new(R * 1.2, R * 1.2, R * 1.2), SUN_CORE, Enum.Material.Neon, 0, "ball", CFrame.new())
	gpart(g, Vector3.new(R * 2, R * 2, R * 2), c, Enum.Material.Neon, 0.15, "ball", CFrame.new())
	gpart(g, Vector3.new(R * 3, R * 3, R * 3), c, Enum.Material.Neon, 0.75, "ball", CFrame.new())
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		gpart(g, Vector3.new(R * 0.18, R * (k % 2 == 0 and 1.4 or 0.9), R * 0.18), c:Lerp(WHITE, 0.3), Enum.Material.Neon, 0.1, nil, CFrame.Angles(0, 0, a) * CFrame.new(0, R * 1.3, 0))
	end
	return g
end
-- 달: 초승달 (가운데가 두껍고 끝이 가는 호), 덩이의 XY 면, 오목한 쪽이 +X
local function moonGroup(R: number, color: Color3?, thick: number?): Group
	local g = group()
	local c = color or MOON
	local n = 16
	for i = 0, n - 1 do
		local a0 = math.rad(-110 + 220 * i / n)
		local a1 = math.rad(-110 + 220 * (i + 1) / n)
		local p0 = Vector3.new(-math.cos(a0) * R, math.sin(a0) * R, 0)
		local p1 = Vector3.new(-math.cos(a1) * R, math.sin(a1) * R, 0)
		local u = (i + 0.5) / n
		local w = (thick or R * 0.45) * math.sin(u * math.pi) + R * 0.05
		local mid = (p0 + p1) / 2
		gpart(g, Vector3.new(w, (p1 - p0).Magnitude * 1.12, w * 0.6), c:Lerp(WHITE, (1 - math.sin(u * math.pi)) * 0.4), Enum.Material.Neon, 0.05, nil,
			CFrame.new(mid) * CFrame.Angles(0, 0, math.atan2(p1.Y - p0.Y, p1.X - p0.X) - math.pi / 2))
	end
	return g
end

local H: { [string]: (any) -> () } = {}

------------------------------------------------------------------------
-- 일월쌍륜 (E): 해의 원반과 달의 원반이 엇갈리는 활을 그리며 날아가 앞에서 만나 일식처럼 터진다
------------------------------------------------------------------------
function H.twinDiscs(d: any)
	local from: Vector3 = d.from
	if not near(from, 300) then
		return
	end
	local dir = flat(d.dir)
	local right = Vector3.new(-dir.Z, 0, dir.X)
	local time = d.time or 0.6
	local sun = sunGroup(1.6)
	local moon = moonGroup(2.4)
	local last = 0
	anim(time, function(u)
		local sp = from + dir * (d.dist * u) + right * (d.swing * math.sin(u * math.pi))
		local mp = from + dir * (d.dist * u) - right * (d.swing * math.sin(u * math.pi))
		gset(sun, CFrame.new(sp) * CFrame.Angles(0, 0, u * 14))
		gset(moon, CFrame.lookAt(mp, mp + dir) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, -u * 16))
		local now = os.clock()
		if now - last > 0.04 then
			last = now
			local a = part(Vector3.new(0.6, 0.6, 0.6), SUN, Enum.Material.Neon, 0.1, "ball")
			a.Position = sp
			fadeOut(a, 0.35, { Size = Vector3.new(0.1, 0.1, 0.1) })
			local b = part(Vector3.new(0.5, 0.5, 0.5), MOON, Enum.Material.Neon, 0.1, "ball")
			b.Position = mp
			fadeOut(b, 0.35, { Size = Vector3.new(0.1, 0.1, 0.1) })
		end
		if u >= 1 then
			gfade(sun, 0.1)
			gfade(moon, 0.1)
			local at = from + dir * d.dist
			local ecl = part(Vector3.new(3, 3, 3), DARK, Enum.Material.SmoothPlastic, 0, "ball")
			ecl.Position = at
			local ring = part(Vector3.new(4, 4, 4), SUN, Enum.Material.Neon, 0.3, "ball")
			ring.Position = at
			fadeOut(ecl, 0.5, { Size = Vector3.new(8, 8, 8) })
			fadeOut(ring, 0.4, { Size = Vector3.new(22, 22, 22) })
			Fx.blast(at, SUN, MOON, 1.6)
			Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), SUN, 2, 24, 0.4)
			Fx.breakSound("boom", 0.8, 1.0, at)
			shakeNear(at, 0.7, 120)
		end
	end)
	Fx.breakSound("whoosh", 0.6, 1.0, from)
end

------------------------------------------------------------------------
-- 일월환보 (R): 제자리에 해가 터지고, 지나간 길을 달빛이 베고, 내려선 자리에서 초승달이 둥글게 터진다
------------------------------------------------------------------------
function H.solarLunarStep(d: any)
	local a: Vector3, b: Vector3 = d.from, d.to
	if not near(a, 300) then
		return
	end
	local m = d.m
	task.delay(0.05, function()
		local s = sunGroup(2.4)
		gset(s, CFrame.new(a))
		anim(0.35, function(u)
			galpha(s, u)
			gset(s, CFrame.new(a) * CFrame.Angles(0, 0, u * 3))
			if u >= 1 then
				gfade(s, 0.05)
			end
		end)
		Fx.ring(ground(a) + Vector3.new(0, 0.3, 0), SUN, 2, 20, 0.4)
		Fx.burst("ember", a, SUN, 14, 1.4)
		Fx.breakSound("boom", 0.7, 1.1, a)
	end)
	for k = 0, 3 do
		task.delay(k * 0.04, function()
			if m and m.Parent then
				Fx.afterimage(m, k % 2 == 0 and SUN or MOON, 0.35)
			end
		end)
	end
	task.delay(0.28, function()
		local mid = (a + b) / 2
		local len = (b - a).Magnitude
		local slash = part(Vector3.new(0.3, 4.5, len), MOON, Enum.Material.Neon, 0.05)
		slash.CFrame = safeLook(mid, b) * CFrame.Angles(0, 0, math.rad(20))
		fadeOut(slash, 0.4, { Size = Vector3.new(0.05, 0.6, len) })
		Fx.sound("swing", 0.7, 0.8, mid)
	end)
	task.delay(0.45, function()
		local mg = moonGroup(6, MOON, 2)
		local base = CFrame.new(b) * CFrame.Angles(math.rad(90), 0, 0)
		anim(0.35, function(u)
			gset(mg, base * CFrame.Angles(0, 0, u * math.pi * 1.5))
			galpha(mg, u)
			if u >= 1 then
				gfade(mg, 0.05)
			end
		end)
		Fx.ring(ground(b) + Vector3.new(0, 0.3, 0), MOON, 2, 24, 0.4)
		Fx.burst("glitter", b, MOON, 16, 1.4)
		shakeNear(b, 0.6, 100)
	end)
end

------------------------------------------------------------------------
-- 대일월천 (오의): 거대한 해가 내려앉아 타고, 달의 칼날이 해를 세로로 가르고, 일식으로 터진다
------------------------------------------------------------------------
function H.sunMoonFall(d: any)
	local c: Vector3 = d.at
	if not near(c, 400) then
		return
	end
	local dir = flat(d.dir)
	local fall, burn, cutAt = d.fall or 0.6, d.burn or 1.4, d.cutAt or 1.2
	local R = (d.radius or 15) * 0.55
	local sun = sunGroup(R)
	local top = c + Vector3.new(0, 70, 0) - dir * 10
	local land = ground(c) + Vector3.new(0, R * 0.6, 0)
	if opts.tint then
		opts.tint(Color3.fromRGB(255, 200, 140), 0.3, fall + burn + 0.3)
	end
	anim(fall + burn, function(u)
		local t = u * (fall + burn)
		local k = math.clamp(t / fall, 0, 1)
		local p = top:Lerp(land, k * k)
		gset(sun, CFrame.new(p) * CFrame.Angles(0, 0, t * 2))
		if k >= 1 and math.random() < 0.5 then
			local a = math.random() * math.pi * 2
			Fx.burst("ember", ground(c) + Vector3.new(math.cos(a) * R * 1.6, 1, math.sin(a) * R * 1.6), SUN, 3, 1.4)
		end
		if u >= 1 then
			gfade(sun, 0.2)
		end
	end)
	task.delay(fall, function()
		Fx.ring(ground(c) + Vector3.new(0, 0.4, 0), SUN, 4, (d.radius or 15) * 2.4, 0.6)
		Fx.debris(ground(c), 14, 40)
		Fx.breakSound("boom", 1, 0.6, c)
		shakeNear(c, 1.2, 160)
		local scorch = part(Vector3.new(0.2, 1, 1), Color3.fromRGB(255, 110, 40), Enum.Material.Neon, 0.4, "cyl")
		scorch.CFrame = CFrame.new(ground(c) + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
		tween(scorch, 0.3, { Size = Vector3.new(0.2, (d.radius or 15) * 2, (d.radius or 15) * 2) })
		task.delay(burn, function()
			fadeOut(scorch, 0.5)
		end)
	end)
	-- 달의 칼날이 하늘에서 해를 세로로 가른다
	task.delay(fall + cutAt - 0.25, function()
		local mg = moonGroup(R * 2.4, MOON, R * 0.5)
		local right = Vector3.new(-dir.Z, 0, dir.X)
		local from = c + Vector3.new(0, 60, 0)
		anim(0.25, function(u)
			local p = from:Lerp(ground(c) + Vector3.new(0, R, 0), u)
			gset(mg, CFrame.fromMatrix(p, right, Vector3.new(0, 1, 0)) * CFrame.Angles(0, math.rad(90), 0))
			if u >= 1 then
				gfade(mg, 0.3)
				Fx.flash(c, MOON, 60, 5, 0.4)
				Fx.sound("deflect", 0.9, 0.6, c)
				shakeNear(c, 0.9, 160)
			end
		end)
	end)
	task.delay(fall + burn, function()
		local ecl = part(Vector3.new(4, 4, 4), DARK, Enum.Material.SmoothPlastic, 0, "ball")
		ecl.Position = land
		local corona = part(Vector3.new(6, 6, 6), SUN_CORE, Enum.Material.Neon, 0.3, "ball")
		corona.Position = land
		fadeOut(ecl, 0.6, { Size = Vector3.new(R * 3, R * 3, R * 3) })
		fadeOut(corona, 0.5, { Size = Vector3.new(R * 6, R * 6, R * 6) })
		Fx.blast(land, SUN, MOON, 3)
		Fx.ring(ground(c) + Vector3.new(0, 0.5, 0), WHITE, 6, 70, 0.7)
		Fx.flash(c, SUN_CORE, 90, 7, 0.8)
		Fx.breakSound("boom", 1, 0.45, c)
		shakeNear(c, 1.8, 200)
	end)
end

------------------------------------------------------------------------
-- 일월개벽 (초 오의): 하늘이 어두워지며 해와 달이 떠오르고, 부딪쳐 하늘에 일식이 걸리고, 빛살이 쏟아지고, 새벽빛으로 터진다
------------------------------------------------------------------------
local eclipseSky: { [Vector3]: BasePart } = {}
function H.eclipseGenesis(d: any)
	local c: Vector3 = d.at
	if not near(c, 500) then
		return
	end
	local rise, collide, rays, finalAt = d.rise or 1, d.collide or 1.8, d.rays or 2, d.finalAt or 0.4
	local total = collide + rays + finalAt
	if opts.tint then
		opts.tint(Color3.fromRGB(120, 110, 150), 0.55, total)
	end
	local cam = workspace.CurrentCamera
	local face = cam and flat(cam.CFrame.Position - c) or Vector3.new(0, 0, 1)
	local right = Vector3.new(-face.Z, 0, face.X)
	local sky = c + Vector3.new(0, 46, 0)
	local sun = sunGroup(7)
	local moon = moonGroup(9, MOON, 4)
	anim(collide, function(u)
		local t = u * collide
		local k = math.clamp(t / rise, 0, 1)
		-- 양쪽 땅에서 떠올라 (rise) 하늘 가운데로 모인다
		local sStart, mStart = c + right * 30, c - right * 30
		local sUp, mUp = sky + right * 26, sky - right * 26
		local j = math.clamp((t - rise) / math.max(0.05, collide - rise), 0, 1)
		local sp = (k < 1 and sStart:Lerp(sUp, 1 - (1 - k) ^ 2) or sUp:Lerp(sky, j * j))
		local mp = (k < 1 and mStart:Lerp(mUp, 1 - (1 - k) ^ 2) or mUp:Lerp(sky + face * 0.5, j * j))
		gset(sun, CFrame.new(sp) * CFrame.Angles(0, 0, t))
		gset(moon, CFrame.lookAt(mp, mp + face) * CFrame.Angles(0, 0, -t * 0.6))
		if u >= 1 then
			gfade(sun, 0.2)
			gfade(moon, 0.2)
		end
	end)
	task.delay(collide, function()
		-- 일식: 검은 해, 흰 빛 테, 금빛 빛살
		local disc = part(Vector3.new(16, 16, 16), DARK, Enum.Material.SmoothPlastic, 0, "ball")
		disc.Position = sky
		local crown = part(Vector3.new(19, 19, 19), SUN_CORE, Enum.Material.Neon, 0.25, "ball")
		crown.Position = sky
		local glow = part(Vector3.new(30, 30, 30), SUN, Enum.Material.Neon, 0.75, "ball")
		glow.Position = sky
		eclipseSky[c] = disc
		Fx.flash(sky, SUN_CORE, 140, 8, 0.6)
		Fx.breakSound("boom", 1, 0.4, c)
		shakeNear(c, 1.6, 240)
		task.delay(rays + finalAt, function()
			eclipseSky[c] = nil
			fadeOut(disc, 0.6, { Size = Vector3.new(4, 4, 4) })
			fadeOut(crown, 0.3, { Size = Vector3.new(120, 120, 120) })
			fadeOut(glow, 0.5, { Size = Vector3.new(160, 160, 160) })
		end)
	end)
	task.delay(total, function()
		Fx.blast(c, SUN_CORE, SUN, 3.6)
		Fx.ring(ground(c) + Vector3.new(0, 0.5, 0), SUN_CORE, 6, (d.radius or 32) * 2.8, 0.8)
		Fx.ring(ground(c) + Vector3.new(0, 2, 0), MOON, 4, (d.radius or 32) * 2, 0.7)
		local pillar = part(Vector3.new(120, 14, 14), SUN_CORE, Enum.Material.Neon, 0.1, "cyl")
		pillar.CFrame = CFrame.new(c + Vector3.new(0, 60, 0)) * CFrame.Angles(0, 0, math.rad(90))
		fadeOut(pillar, 0.7, { Size = Vector3.new(120, 40, 40) })
		Fx.flash(c, WHITE, 140, 9, 1)
		Fx.breakSound("boom", 1, 0.35, c)
		shakeNear(c, 2.4, 260)
	end)
end
-- 일식의 빛살: 하늘의 일식에서 적에게 꽂힌다
function H.eclipseRay(d: any)
	local from: Vector3 = d.from
	for _, at in ipairs(d.ats or {}) do
		if near(at, 300) then
			local len = (at - from).Magnitude
			local beam = part(Vector3.new(0.7, 0.7, len), SUN_CORE, Enum.Material.Neon, 0.05)
			beam.CFrame = safeLook((from + at) / 2, at)
			fadeOut(beam, 0.2, { Size = Vector3.new(0.1, 0.1, len) })
			Fx.burst("spark", at, SUN, 5, 1)
			Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), SUN, 1, 8, 0.25)
		end
	end
end

------------------------------------------------------------------------
-- 황혼의 기술
------------------------------------------------------------------------
-- 황혼 (연타 셋마다): 노을빛 해와 보랏빛 달이 함께 떨어져 겹치며 터진다
function H.duskPulse(d: any)
	local at: Vector3 = d.at
	if not near(at, 250) then
		return
	end
	local delay = d.delay or 0.3
	local s = sunGroup(1.2, DUSK)
	local mg = moonGroup(1.8, DUSK2, 0.7)
	anim(delay, function(u)
		local sp = (at + Vector3.new(6, 18, 0)):Lerp(at, u * u)
		local mp = (at + Vector3.new(-6, 18, 0)):Lerp(at, u * u)
		gset(s, CFrame.new(sp))
		gset(mg, CFrame.new(mp) * CFrame.Angles(0, 0, u * 6))
		if u >= 1 then
			gfade(s, 0.1)
			gfade(mg, 0.1)
			Fx.blast(at, DUSK, DUSK2, 1.2)
			Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), DUSK, 1, 18, 0.35)
			Fx.breakSound("boom", 0.6, 1.2, at)
		end
	end)
end

-- 황혼참 (E): 노을빛 초승달 다섯이 부채꼴로 날아갔다가 되돌아온다
function H.duskFan(d: any)
	local from: Vector3 = d.from
	if not near(from, 300) then
		return
	end
	local m = d.m
	local time = d.time or 0.7
	local moons = {}
	for i, dir in ipairs(d.dirs or {}) do
		moons[i] = { g = moonGroup(2.2, i % 2 == 0 and DUSK2 or DUSK, 0.9), dir = flat(dir) }
	end
	local last = 0
	anim(time, function(u)
		local r = rootOf(m)
		local owner = r and r.Position or from
		local base = from:Lerp(owner, u)
		local now = os.clock()
		for i, mo in ipairs(moons) do
			local p = base + mo.dir * (d.dist * math.sin(u * math.pi))
			gset(mo.g, CFrame.lookAt(p, p + mo.dir) * CFrame.Angles(math.rad(90), 0, 0) * CFrame.Angles(0, 0, -u * 20))
			if now - last > 0.05 then
				local tr = part(Vector3.new(0.5, 0.5, 0.5), i % 2 == 0 and DUSK2 or DUSK, Enum.Material.Neon, 0.15, "ball")
				tr.Position = p
				fadeOut(tr, 0.3, { Size = Vector3.new(0.1, 0.1, 0.1) })
			end
		end
		if now - last > 0.05 then
			last = now
		end
		if u >= 1 then
			for _, mo in ipairs(moons) do
				gfade(mo.g, 0.1)
			end
		end
	end)
	Fx.breakSound("whoosh", 0.8, 0.9, from)
end

-- 석양보 (R): 노을이 되어 적들의 등 뒤로 차례로 나타나고, 지나간 노을빛 줄이 한꺼번에 터진다
function H.duskChain(d: any)
	local prev: Vector3 = d.from
	if not near(prev, 300) then
		return
	end
	local m = d.m
	local lines: { { Vector3 } } = {}
	for i, t in ipairs(d.targets or {}) do
		task.delay((d.delay or 0.08) + (i - 1) * (d.every or 0.12), function()
			local tr = rootOf(t)
			if not tr then
				return
			end
			local to = tr.Position
			if m and m.Parent then
				Fx.afterimage(m, i % 2 == 0 and DUSK2 or DUSK, 0.4)
			end
			local len = (to - prev).Magnitude
			if len > 0.3 then
				local ln = part(Vector3.new(0.5, 0.5, len), DUSK, Enum.Material.Neon, 0.1)
				ln.CFrame = safeLook((prev + to) / 2, to)
				table.insert(lines, { prev, to })
				task.delay(0.6 + (d.burstAt or 0.35), function()
					fadeOut(ln, 0.2)
				end)
			end
			Fx.burst("spark", to, DUSK, 8, 1.2)
			Fx.sound("swing", 0.7, 1 + i * 0.1, to)
			prev = to
		end)
	end
	local n = math.max(1, #(d.targets or {}))
	task.delay((d.delay or 0.08) + n * (d.every or 0.12) + (d.burstAt or 0.35), function()
		for _, ln in ipairs(lines) do
			local a, b = ln[1], ln[2]
			for k = 0, 3 do
				local p = a:Lerp(b, k / 3)
				local boom = part(Vector3.new(2, 2, 2), k % 2 == 0 and DUSK or DUSK2, Enum.Material.Neon, 0.1, "ball")
				boom.Position = p
				fadeOut(boom, 0.35, { Size = Vector3.new(9, 9, 9) })
			end
		end
		Fx.breakSound("boom", 0.9, 0.9, prev)
		shakeNear(prev, 0.9, 140)
	end)
end

-- 황혼낙일 (G): 거대한 석양이 땅으로 가라앉아 노을빛 바다가 되고, 달빛 기둥이 솟고, 바다가 솟구친다
function H.sunsetSea(d: any)
	local c: Vector3 = d.at
	if not near(c, 400) then
		return
	end
	local sink, dur, R = d.sink or 0.8, d.dur or 2, d.radius or 22
	if opts.tint then
		opts.tint(Color3.fromRGB(255, 170, 140), 0.35, sink + dur + 0.3)
	end
	local sun = sunGroup(R * 0.45, DUSK)
	local g = ground(c)
	anim(sink, function(u)
		local p = (g + Vector3.new(0, R * 1.2, 0)):Lerp(g - Vector3.new(0, R * 0.2, 0), u)
		gset(sun, CFrame.new(p))
		if u >= 1 then
			gfade(sun, 0.4)
		end
	end)
	task.delay(sink, function()
		local sea = part(Vector3.new(0.3, 1, 1), DUSK, Enum.Material.Neon, 0.35, "cyl")
		sea.CFrame = CFrame.new(g + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		tween(sea, 0.3, { Size = Vector3.new(0.3, R * 2, R * 2) })
		local deep = part(Vector3.new(0.35, 1, 1), DUSK2, Enum.Material.Neon, 0.5, "cyl")
		deep.CFrame = CFrame.new(g + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
		tween(deep, 0.4, { Size = Vector3.new(0.35, R * 1.4, R * 1.4) })
		Fx.ring(g + Vector3.new(0, 0.4, 0), DUSK, 4, R * 2.4, 0.6)
		Fx.breakSound("boom", 1, 0.55, c)
		shakeNear(c, 1.2, 160)
		anim(dur, function(u)
			if math.random() < 0.4 then
				local a = math.random() * math.pi * 2
				local r = math.random() * R
				local bub = part(Vector3.new(1, 1, 1), math.random() < 0.5 and DUSK or DUSK2, Enum.Material.Neon, 0.2, "ball")
				bub.Position = g + Vector3.new(math.cos(a) * r, 0.5, math.sin(a) * r)
				fadeOut(bub, 0.5, { Size = Vector3.new(3, 0.5, 3) })
			end
			if u >= 1 then
				fadeOut(sea, 0.4)
				fadeOut(deep, 0.4)
			end
		end)
		local beams = d.beams or {}
		for i, pt in ipairs(beams) do
			task.delay((i - 0.5) * dur / math.max(1, #beams), function()
				local pg = ground(pt)
				local beam = part(Vector3.new(30, 3, 3), MOON, Enum.Material.Neon, 0.1, "cyl")
				beam.CFrame = CFrame.new(pg + Vector3.new(0, 15, 0)) * CFrame.Angles(0, 0, math.rad(90))
				fadeOut(beam, 0.4, { Size = Vector3.new(30, 0.4, 0.4) })
				Fx.ring(pg + Vector3.new(0, 0.4, 0), MOON, 1, 10, 0.3)
				Fx.sound("deflect", 0.5, 1.2, pg)
			end)
		end
	end)
	task.delay(sink + dur, function()
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			local p = g + Vector3.new(math.cos(a) * R * 0.6, 0, math.sin(a) * R * 0.6)
			local col = part(Vector3.new(18, 4, 4), k % 2 == 0 and DUSK or DUSK2, Enum.Material.Neon, 0.1, "cyl")
			col.CFrame = CFrame.new(p + Vector3.new(0, 9, 0)) * CFrame.Angles(0, 0, math.rad(90))
			fadeOut(col, 0.5, { Size = Vector3.new(26, 8, 8) })
		end
		Fx.blast(g + Vector3.new(0, 3, 0), DUSK, DUSK2, 3)
		Fx.flash(c, DUSK, 90, 7, 0.8)
		Fx.breakSound("boom", 1, 0.45, c)
		shakeNear(c, 1.8, 200)
	end)
end

-- 일월동귀 (X): 해와 달이 양쪽에 떨어지고, 서로를 향해 굴러와 가운데에서 하나가 되어 터진다
function H.twilightCollapse(d: any)
	local c: Vector3 = d.at
	if not near(c, 500) then
		return
	end
	local fall, roll, finalAt = d.fall or 0.8, d.roll or 0.9, d.finalAt or 0.5
	if opts.tint then
		opts.tint(Color3.fromRGB(255, 160, 150), 0.45, fall + roll + finalAt + 0.4)
	end
	local sunAt, moonAt = d.sunAt, d.moonAt
	local sun = sunGroup(6, DUSK)
	local moon = moonGroup(8, DUSK2, 3.5)
	local face = flat((moonAt - sunAt))
	anim(fall + roll, function(u)
		local t = u * (fall + roll)
		local sp, mp
		if t < fall then
			local k = t / fall
			sp = (sunAt + Vector3.new(0, 80, 0)):Lerp(ground(sunAt) + Vector3.new(0, 6, 0), k * k)
			mp = (moonAt + Vector3.new(0, 80, 0)):Lerp(ground(moonAt) + Vector3.new(0, 8, 0), k * k)
		else
			local k = (t - fall) / roll
			sp = (ground(sunAt) + Vector3.new(0, 6, 0)):Lerp(ground(c) + Vector3.new(0, 6, 0), k * k)
			mp = (ground(moonAt) + Vector3.new(0, 8, 0)):Lerp(ground(c) + Vector3.new(0, 7, 0), k * k)
			if math.random() < 0.6 then
				Fx.burst("ember", ground(sp), DUSK, 3, 1.4)
				Fx.burst("glitter", ground(mp), DUSK2, 3, 1.4)
			end
		end
		gset(sun, CFrame.new(sp) * CFrame.Angles(0, 0, -t * 6))
		gset(moon, CFrame.lookAt(mp, mp + face) * CFrame.Angles(0, 0, t * 6))
		if u >= 1 then
			gfade(sun, 0.15)
			gfade(moon, 0.15)
		end
	end)
	task.delay(fall, function()
		for _, pt in ipairs({ sunAt, moonAt }) do
			Fx.ring(ground(pt) + Vector3.new(0, 0.4, 0), pt == sunAt and DUSK or DUSK2, 4, 30, 0.5)
			Fx.debris(ground(pt), 12, 40)
		end
		Fx.breakSound("boom", 1, 0.5, c)
		shakeNear(c, 1.6, 200)
	end)
	task.delay(fall + roll + finalAt, function()
		local g = ground(c)
		local core = part(Vector3.new(6, 6, 6), WHITE, Enum.Material.Neon, 0, "ball")
		core.Position = g + Vector3.new(0, 6, 0)
		fadeOut(core, 0.6, { Size = Vector3.new(70, 70, 70) })
		local shell = part(Vector3.new(8, 8, 8), DUSK, Enum.Material.Neon, 0.4, "ball")
		shell.Position = core.Position
		fadeOut(shell, 0.8, { Size = Vector3.new(110, 110, 110) })
		Fx.ring(g + Vector3.new(0, 0.5, 0), DUSK, 8, (d.radius or 50) * 2.6, 0.9)
		Fx.ring(g + Vector3.new(0, 3, 0), DUSK2, 6, (d.radius or 50) * 2, 0.8)
		Fx.blast(g + Vector3.new(0, 4, 0), DUSK, DUSK2, 4)
		Fx.flash(c, WHITE, 160, 10, 1.1)
		Fx.breakSound("boom", 1, 0.3, c)
		shakeNear(c, 2.6, 300)
	end)
end

------------------------------------------------------------------------
-- 일월극변: 서버 전체에 컷씬. 하늘에서 해와 달이 미친 듯이 번갈아 뜨다가, 둘이 겹쳐 지는 해가 되고 세상이 황혼에 멈춘다
-- (낮과 밤을 번갈아 바꾸는 것은 서버가 한다: 모두에게 같은 박자로. 화면은 하늘의 해·달과 소리·번쩍임만)
------------------------------------------------------------------------
local duskSky: BasePart? = nil
function Geuk.twilight(d: any)
	local cut, dur = d.cut or 3, d.dur or 40
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local camPos = cam.CFrame.Position
	local fwd = flat(cam.CFrame.LookVector)
	local skyAt = camPos + fwd * 380 + Vector3.new(0, 170, 0)
	local sun = sunGroup(18)
	local moon = moonGroup(26, MOON, 11)
	local beats = 12
	local t0 = os.clock()
	local lastBeat = -1
	anim(cut, function(u)
		-- 박자가 점점 빨라진다 (u²)
		local beat = math.floor((u * u) * beats * 1.6)
		local day = beat % 2 == 0
		gset(sun, CFrame.new(skyAt) * CFrame.Angles(0, 0, os.clock() - t0))
		gset(moon, CFrame.lookAt(skyAt, camPos) * CFrame.Angles(0, 0, -(os.clock() - t0)))
		galpha(sun, day and 0 or 1)
		galpha(moon, day and 1 or 0)
		if beat ~= lastBeat then
			lastBeat = beat
			Fx.sound(day and "deflect" or "block", 0.5, day and 1.4 or 0.8)
			if opts.flash then
				opts.flash(day and SUN or MOON, 0.15)
			end
			if opts.shake then
				opts.shake(0.25 + u * 0.6)
			end
		end
		if u >= 1 then
			gfade(sun, 0.4)
			gfade(moon, 0.4)
		end
	end)
	-- 해와 달이 겹친 지는 해: 황혼 동안 하늘 끝에 걸려 있다
	task.delay(cut, function()
		if duskSky then
			duskSky:Destroy()
		end
		local horizon = camPos + fwd * 420 + Vector3.new(0, 40, 0)
		local disc = part(Vector3.new(60, 60, 60), DUSK, Enum.Material.Neon, 0.1, "ball")
		disc.Position = horizon
		local veil = part(Vector3.new(90, 90, 90), DUSK2, Enum.Material.Neon, 0.7, "ball")
		veil.Position = horizon
		duskSky = disc
		if opts.flash then
			opts.flash(DUSK, 0.6)
		end
		if opts.shake then
			opts.shake(1.4)
		end
		Fx.sound("deflect", 0.9, 0.5)
		task.delay(dur, function()
			fadeOut(disc, 1.2)
			fadeOut(veil, 1.2)
			if duskSky == disc then
				duskSky = nil
			end
		end)
	end)
	-- 황혼의 주인: 몸에서 노을빛 불꽃과 보랏빛 연기가 피어오른다
	local r = rootOf(d.m)
	if r then
		local a = Instance.new("Attachment")
		a.Parent = r
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/fire_main.dds"
		e.Color = ColorSequence.new(DUSK, DUSK2)
		e.LightEmission = 0.8
		e.Rate = 30
		e.Lifetime = NumberRange.new(0.5, 0.9)
		e.Speed = NumberRange.new(3, 6)
		e.SpreadAngle = Vector2.new(25, 25)
		e.Size = NumberSequence.new(1.6, 0)
		e.Transparency = NumberSequence.new(0.2, 1)
		e.Acceleration = Vector3.new(0, 8, 0)
		e.Parent = a
		local pl = Instance.new("PointLight")
		pl.Color = DUSK
		pl.Range = 14
		pl.Brightness = 1.5
		pl.Parent = a
		task.delay(cut + dur, function()
			e.Enabled = false
			task.delay(1, function()
				a:Destroy()
			end)
		end)
	end
end

local PULSE: { [string]: string } = { dusk = "duskPulse" }
function Geuk.handles(data: any): boolean
	if data.kind == "pulse" then
		return PULSE[data.fx or ""] ~= nil
	end
	return H[data.kind] ~= nil
end
function Geuk.run(data: any)
	local fn = data.kind == "pulse" and H[PULSE[data.fx or ""] or ""] or H[data.kind]
	if fn then
		fn(data)
	end
end

return Geuk
