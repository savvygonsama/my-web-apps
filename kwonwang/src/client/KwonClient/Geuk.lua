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
-- 3.1.1판 오의·초 오의 공통 조각: 화면 빛깔, 빛줄기, 고리, 바닥의 진, 꼬리, 땅의 금
------------------------------------------------------------------------
local UP = Vector3.new(0, 1, 0)
local function v3(s: number): Vector3
	return Vector3.new(s, s, s)
end
local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "KwonGeukGrade"
grade.Parent = game:GetService("Lighting")
-- 내 화면의 빛깔을 time 동안 옮긴다 (나중 부름이 앞의 것을 덮는다)
local function gradeTo(time: number, sat: number, bright: number, contrast: number, tintC: Color3?)
	tween(grade, time, { Saturation = sat, Brightness = bright, Contrast = contrast, TintColor = tintC or WHITE })
end
local function gradeReset(time: number)
	gradeTo(time, 0, 0, 0, WHITE)
end
-- a에서 b로 뻗는 빛줄기 (원기둥, 길이는 X)
local function setBeam(p: BasePart, a: Vector3, b: Vector3, w: number)
	local len = math.max(0.2, (b - a).Magnitude)
	p.Size = Vector3.new(len, w, w)
	p.CFrame = safeLook((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
end
local function beamTo(a: Vector3, b: Vector3, w: number, color: Color3, alpha: number?): BasePart
	local p = part(Vector3.new(1, w, w), color, Enum.Material.Neon, alpha, "cyl")
	setBeam(p, a, b, w)
	return p
end
-- 덩이의 XY 면에 놓인 고리 (조각 n개)
local function gHalo(g: Group, R: number, thick: number, color: Color3, n: number, alpha: number?, base: CFrame?)
	local seg = 2 * math.pi * R / n * 1.1
	for k = 0, n - 1 do
		local a = (k + 0.5) / n * math.pi * 2
		gpart(g, Vector3.new(seg, thick, thick * 0.6), color, Enum.Material.Neon, alpha, nil, (base or CFrame.new()) * CFrame.Angles(0, 0, a) * CFrame.new(0, R, 0))
	end
end
-- 바닥의 진: 바깥 고리 (눈금 열둘) 와 안쪽 고리 (육각별). 둘은 따로 돈다
local FLAT = CFrame.Angles(math.rad(90), 0, 0)
local function sigil(R: number, c1: Color3, c2: Color3): (Group, Group)
	local outer, inner = group(), group()
	gHalo(outer, R, 0.55, c1, 40, 0.1, FLAT)
	gHalo(outer, R * 0.9, 0.25, c1:Lerp(WHITE, 0.3), 40, 0.35, FLAT)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		gpart(outer, Vector3.new(0.5, R * 0.12, 0.2), c1:Lerp(WHITE, 0.35), Enum.Material.Neon, 0.1, nil, FLAT * CFrame.Angles(0, 0, a) * CFrame.new(0, R * 0.8, 0))
	end
	local r = R * 0.66
	gHalo(inner, r, 0.4, c2, 30, 0.15, FLAT)
	for k = 0, 5 do
		gpart(inner, Vector3.new(r * 1.732, 0.3, 0.15), c2:Lerp(WHITE, 0.2), Enum.Material.Neon, 0.2, nil, FLAT * CFrame.Angles(0, 0, k * math.pi / 3) * CFrame.new(0, r * 0.5, 0))
	end
	galpha(outer, 1)
	galpha(inner, 1)
	return outer, inner
end
-- 진을 life 동안 돌린다 (처음에 밝아지고, 끝에 사라진다)
local function runSigil(at: Vector3, R: number, c1: Color3, c2: Color3, life: number, speed: number?)
	local outer, inner = sigil(R, c1, c2)
	local g = ground(at) + Vector3.new(0, 0.15, 0)
	local sp = speed or 1
	anim(life, function(u)
		local t = u * life
		local k = math.min(1, t / 0.35)
		galpha(outer, 1 - k)
		galpha(inner, 1 - k)
		gset(outer, CFrame.new(g) * CFrame.Angles(0, t * 0.9 * sp * (1 + u * 2), 0))
		gset(inner, CFrame.new(g + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, -t * 1.5 * sp * (1 + u * 2), 0))
		if u >= 1 then
			gfade(outer, 0.25)
			gfade(inner, 0.25)
		end
	end)
end
local function trailDot(p: Vector3, d: number, color: Color3, life: number)
	local b = part(v3(d), color, Enum.Material.Neon, 0.3, "ball")
	b.Position = p
	fadeOut(b, life, { Size = v3(d * 0.2) })
end
-- 땅이 가운데에서 사방으로 갈라진다 (금이 차례로 자라고, 끝에서 빛이 샌다)
local function groundCracks(c: Vector3, n: number, len: number, c1: Color3, c2: Color3, life: number, leak: boolean?)
	local g0 = ground(c) + Vector3.new(0, 0.1, 0)
	for k = 1, n do
		local a = k / n * math.pi * 2 + (math.random() - 0.5) * 0.3
		local col = k % 2 == 0 and c1 or c2
		local p = g0
		for s = 1, 4 do
			a += (math.random() - 0.5) * 0.5
			local q = p + Vector3.new(math.cos(a), 0, math.sin(a)) * (len / 4) * (0.8 + math.random() * 0.4)
			local p0, w = p, 1.2 - s * 0.22
			task.delay((s - 1) * 0.04, function()
				local cr = part(Vector3.new(w, 0.14, (q - p0).Magnitude + 0.25), col, Enum.Material.Neon, 0.05)
				cr.CFrame = safeLook((p0 + q) / 2, q)
				task.delay(life, function()
					fadeOut(cr, 0.35)
				end)
			end)
			p = q
		end
		if leak then
			local tip = p
			task.delay(0.18, function()
				local lk = beamTo(tip, tip + Vector3.new(0, 18, 0), 1, col, 0.3)
				fadeOut(lk, life, { Size = Vector3.new(18, 0.15, 0.15) })
			end)
		end
	end
end
local function camFace(from: Vector3, fallback: Vector3): Vector3
	local cam = workspace.CurrentCamera
	if cam then
		local v = cam.CFrame.Position - from
		if v.Magnitude > 1e-3 then
			return v.Unit
		end
	end
	return fallback
end

------------------------------------------------------------------------
-- 대일월천 (오의, 3.1.1판 새로)
-- 등 뒤에 해와 달이 떠오른다 → 해는 불의 빛줄기로 땅을 앞뒤로 가르고, 달은 거대한 초승달 셋을 내리꽂는다
-- → 둘이 적 위에서 부딪쳐 일식이 되고 땅이 금빛·푸른빛으로 갈라진다 → 일식이 땅에 박히며 빛의 돔으로 터진다
------------------------------------------------------------------------
function H.sunMoonFall(d: any)
	local c: Vector3 = d.at
	if not near(c, 450) then
		return
	end
	local dir = flat(d.dir)
	local right = Vector3.new(-dir.Z, 0, dir.X)
	local from: Vector3 = d.from or (c - dir * 14)
	local summon, beamT, merge = d.summon or 0.7, d.beam or 1.2, d.merge or 0.5
	local slams, slamAt, slamEvery, travel = d.slams or 3, d.slamAt or 0.85, d.slamEvery or 0.36, d.travel or 0.22
	local sweep, R = d.sweep or 9, d.radius or 26
	local g0 = ground(c)
	local total = summon + beamT + merge
	local meetT = summon + beamT + merge * 0.7
	local sunHome = from - dir * 5 + right * 11 + UP * 18
	local moonHome = from - dir * 5 - right * 11 + UP * 20
	local sun = sunGroup(5.5)
	local moon = moonGroup(7.5, MOON, 3.2)
	galpha(sun, 1)
	galpha(moon, 1)
	local sunPos, moonPos = sunHome - UP * 18, moonHome - UP * 20
	if opts.tint then
		opts.tint(Color3.fromRGB(255, 215, 170), 0.3, total + 0.4)
	end
	runSigil(from, 10, SUN, MOON, total, 1.2)
	Fx.sound("ping", 0.6, 0.5, from)
	-- 해와 달: 떠오르고 → 떠 있으며 치고 → 적 위로 모여 부딪친다
	local merged = false
	anim(meetT, function(u)
		local t = u * meetT
		if t < summon then
			local k = t / summon
			local e = 1 - (1 - k) ^ 3
			sunPos = (sunHome - UP * 18):Lerp(sunHome, e)
			moonPos = (moonHome - UP * 20):Lerp(moonHome, e)
			galpha(sun, 1 - k)
			galpha(moon, 1 - k)
			if math.random() < 0.5 then
				Fx.burst("glitter", from + UP * 2, math.random() < 0.5 and SUN or MOON, 3, 1.2)
			end
		elseif t < summon + beamT then
			galpha(sun, 0)
			galpha(moon, 0)
			sunPos = sunHome + UP * math.sin(t * 3) * 0.6
			moonPos = moonHome + UP * math.cos(t * 3) * 0.6
		else
			local k = math.clamp((t - summon - beamT) / (merge * 0.7), 0, 1)
			local meet = g0 + UP * 14
			sunPos = sunHome:Lerp(meet, k * k)
			moonPos = moonHome:Lerp(meet, k * k)
			trailDot(sunPos, 4, SUN, 0.3)
			trailDot(moonPos, 4, MOON, 0.3)
		end
		local face = camFace(sunPos, -dir)
		gset(sun, CFrame.lookAt(sunPos, sunPos + face) * CFrame.Angles(0, 0, t * 2.5))
		gset(moon, CFrame.lookAt(moonPos, moonPos + face) * CFrame.Angles(0, 0, -0.4 + math.sin(t * 2) * 0.2))
		if u >= 1 and not merged then
			merged = true
			gfade(sun, 0.06)
			gfade(moon, 0.06)
		end
	end)
	-- 해의 빛줄기: 적 둘레의 땅을 앞뒤로 쓸며 태운다
	task.delay(summon, function()
		local core = part(Vector3.new(1, 2, 2), SUN_CORE, Enum.Material.Neon, 0, "cyl")
		local glow = part(Vector3.new(1, 5, 5), SUN, Enum.Material.Neon, 0.45, "cyl")
		Fx.sound("deflect", 1, 0.45, c)
		shakeNear(c, 0.8, 160)
		anim(beamT, function(u)
			local p = g0 + dir * (-sweep * math.cos(u * math.pi * 2))
			local w = 1 + math.sin(u * 70) * 0.15
			setBeam(core, sunPos, p, 2 * w)
			setBeam(glow, sunPos, p, 5.2 * w)
			if math.random() < 0.7 then
				local s = part(Vector3.new(0.2, 3.5, 3.5), Color3.fromRGB(255, 120, 40), Enum.Material.Neon, 0.15, "cyl")
				s.CFrame = CFrame.new(p + UP * 0.12) * CFrame.Angles(0, 0, math.rad(90))
				fadeOut(s, 1.6, { Size = Vector3.new(0.2, 4.5, 4.5) })
			end
			if math.random() < 0.35 then
				Fx.burst("ember", p + UP, SUN, 4, 1.6)
			end
			if math.random() < 0.15 then
				Fx.ring(p + UP * 0.3, SUN, 2, 10, 0.3)
			end
			if u >= 1 then
				fadeOut(core, 0.15)
				fadeOut(glow, 0.2)
			end
		end)
	end)
	-- 달의 초승달 셋: 하늘을 넘어 적 위에 내리꽂히고, 땅에 초승달 자국이 남는다
	for i = 1, slams do
		local t0 = slamAt + (i - 1) * slamEvery
		task.delay(t0, function()
			local yaw = (i - 1) * math.pi / 3 + math.random() * 0.3
			local mg = moonGroup(8, MOON, 3)
			local start = moonPos
			Fx.sound("swing", 0.9, 0.6, start)
			anim(travel, function(u)
				local p = start:Lerp(g0 + UP * 4, u * u) + UP * math.sin(u * math.pi) * 8
				gset(mg, CFrame.new(p) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, u * math.pi * 1.5))
				trailDot(p, 2.4, MOON, 0.3)
				if u >= 1 then
					gfade(mg, 0.12)
					local gash = moonGroup(9, MOON, 2)
					gset(gash, CFrame.new(g0 + UP * 0.2) * CFrame.Angles(0, yaw, 0) * FLAT)
					galpha(gash, 0.15)
					task.delay(math.max(0.1, total - t0 - travel), function()
						gfade(gash, 0.3)
					end)
					Fx.ring(g0 + UP * 0.4, MOON, 3, 26, 0.45)
					Fx.flash(c, MOON, 60, 5, 0.3)
					Fx.sound("deflect", 0.9, 0.7 + i * 0.08, c)
					Fx.debris(g0, 6, 26)
					shakeNear(c, 1, 160)
				end
			end)
		end)
	end
	-- 땅이 갈라진다: 둘이 모여들 때
	task.delay(summon + beamT + merge * 0.15, function()
		groundCracks(c, 14, R * 0.9, SUN, MOON, merge * 0.85 + 0.2, true)
		Fx.ring(g0 + UP * 0.5, WHITE, 50, 6, merge * 0.55)
		Fx.sound("ping", 0.5, 0.4, c)
	end)
	-- 일식: 부딪친 자리에 검은 해와 흰 테. 한순간 떠 있다가 땅으로 박힌다
	task.delay(meetT, function()
		local meet = g0 + UP * 14
		local face = camFace(meet, -dir)
		local ecl = group()
		gpart(ecl, v3(9), DARK, Enum.Material.SmoothPlastic, 0, "ball", CFrame.new())
		gHalo(ecl, 5.2, 0.7, SUN_CORE, 24, 0, nil)
		gHalo(ecl, 6.4, 0.3, SUN, 28, 0.3, nil)
		gpart(ecl, v3(16), SUN, Enum.Material.Neon, 0.82, "ball", CFrame.new())
		local flare = part(v3(1), WHITE, Enum.Material.Neon, 0, "ball")
		Fx.flash(meet, SUN_CORE, 120, 8, 0.35)
		Fx.breakSound("boom", 0.8, 0.5, c)
		Fx.ring(meet, SUN_CORE, 4, 50, 0.4, face)
		shakeNear(c, 1.4, 200)
		if opts.tint then
			opts.tint(Color3.fromRGB(150, 140, 190), 0.5, merge * 0.3 + 0.1)
		end
		local hang = math.max(0.05, total - meetT)
		anim(hang, function(u)
			local p = meet - UP * (u ^ 3) * 13
			local cf = CFrame.lookAt(p, p + face)
			gset(ecl, cf * CFrame.Angles(0, 0, u * 2))
			flare.CFrame = cf * CFrame.new(3.6, 3.6, -0.5)
			flare.Size = v3(1 + math.sin(u * math.pi) * 6)
			if u >= 1 then
				gfade(ecl, 0.1)
				flare:Destroy()
			end
		end)
	end)
	-- 일식이 땅에 박힌다: 빛의 돔, 하늘까지 닿는 기둥, 사방으로 나는 초승달 조각, 땅을 따라 뻗는 빛살
	task.delay(total, function()
		local core = part(v3(6), WHITE, Enum.Material.Neon, 0, "ball")
		core.Position = g0 + UP * 2
		fadeOut(core, 0.7, { Size = v3(R * 2.4) })
		local shell = part(v3(8), SUN, Enum.Material.Neon, 0.35, "ball")
		shell.Position = g0 + UP * 2
		fadeOut(shell, 0.9, { Size = v3(R * 3.2) })
		local outer = part(v3(8), MOON, Enum.Material.Neon, 0.6, "ball")
		outer.Position = g0 + UP * 2
		fadeOut(outer, 1.0, { Size = v3(R * 4) })
		local pillar = beamTo(g0 - UP * 2, g0 + UP * 150, 16, SUN_CORE, 0.05)
		fadeOut(pillar, 0.8, { Size = Vector3.new(pillar.Size.X, 42, 42) })
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			local out = Vector3.new(math.cos(a), 0, math.sin(a))
			local mg = moonGroup(2.6, k % 2 == 0 and MOON or SUN, 1)
			anim(0.6, function(u)
				local p = g0 + UP * (3 + math.sin(u * math.pi) * 5) + out * (4 + u * R * 1.6)
				gset(mg, CFrame.lookAt(p, p + out) * CFrame.Angles(0, math.rad(90), u * 8))
				if u >= 1 then
					gfade(mg, 0.15)
				end
			end)
		end
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2 + 0.13
			local ray = beamTo(g0 + UP * 0.3, g0 + Vector3.new(math.cos(a), 0, math.sin(a)) * R * 1.5 + UP * 0.3, 1.4, k % 2 == 0 and SUN or MOON, 0.1)
			fadeOut(ray, 0.6)
		end
		Fx.ring(g0 + UP * 0.5, SUN_CORE, 6, R * 3.2, 0.8)
		Fx.ring(g0 + UP * 1.5, SUN, 4, R * 2.4, 0.7)
		Fx.ring(g0 + UP * 3, MOON, 4, R * 1.8, 0.6)
		Fx.blast(g0 + UP * 3, SUN, MOON, 3.4)
		Fx.debris(g0, 16, 44)
		Fx.flash(c, WHITE, 150, 9, 0.9)
		if opts.flash and near(c, 120) then
			opts.flash(SUN_CORE, 0.3)
		end
		Fx.breakSound("boom", 1.2, 0.4, c)
		Fx.breakSound("rock", 1, 0.6, c)
		shakeNear(c, 2.4, 240)
	end)
end

------------------------------------------------------------------------
-- 일월개벽 (초 오의, 3.1.1판 새로)
-- 컷씬: 세상이 어두워지고, 내 등 뒤 지평선 양쪽에서 거대한 해와 달이 솟는다 (나는 둘 사이에 떠오른다)
-- → 일월윤전: 해와 달이 나를 두고 점점 빨리 돌며 번갈아 적을 친다 (해는 불기둥, 달은 초승달). 하늘빛이 따라 바뀐다
-- → 합삭: 둘이 머리 위에서 부딪쳐 거대한 일식이 걸리고 세상의 빛깔이 빠진다 (시간이 멈춘 듯)
-- → 빛살: 일식의 테에서 빛살이 쏟아진다 → 개벽: 하늘로 주먹을 내지르면 일식이 금 가고 깨지며 새벽빛으로 터진다
------------------------------------------------------------------------
local orbState: { [any]: { sun: Vector3, moon: Vector3 } } = {}
function H.eclipseGenesis(d: any)
	local C: Vector3 = d.at
	if not near(C, 600) then
		return
	end
	local look = flat(d.dir or Vector3.new(0, 0, -1))
	local right = Vector3.new(-look.Z, 0, look.X)
	local T1 = d.cut or 1.5
	local T2 = T1 + (d.orbit or 1.4)
	local T3 = T2 + (d.collide or 0.4)
	local T4 = T3 + (d.rays or 1.4)
	local T5 = T4 + (d.finalAt or 0.4)
	local OR = d.orbitR or 30
	local sky = C + UP * 40
	local gC = ground(C)
	local graded = near(C, 250)
	if graded then
		gradeTo(0.6, -0.35, -0.2, 0.15, Color3.fromRGB(200, 200, 235))
	end
	local st = { sun = C, moon = C }
	orbState[d.m] = st
	local sun = sunGroup(9)
	local moon = moonGroup(11, MOON, 4.5)
	galpha(sun, 1)
	galpha(moon, 1)
	local sunRise0 = C - look * 70 + right * 40 - UP * 25
	local sunRise1 = C - look * 70 + right * 40 + UP * 26
	local moonRise0 = C - look * 70 - right * 40 - UP * 25
	local moonRise1 = C - look * 70 - right * 40 + UP * 30
	runSigil(C, 14, SUN, MOON, T5, 1)
	Fx.sound("ping", 0.7, 0.35, C)
	Fx.breakSound("boom", 0.6, 0.3, C)
	local orbitCenter = C + UP * 22
	local function orbitAt(a: number): Vector3
		return orbitCenter + (right * math.cos(a) - look * math.sin(a)) * OR + UP * math.sin(a * 2) * 5
	end
	local function theta(t: number): number
		local k = math.clamp((t - T1) / (T2 - T1), 0, 1)
		return math.pi * 2 * (0.4 * k + 1.6 * k * k) + 0.5
	end
	local lastTrail = 0
	local hidden = false
	anim(T3, function(u)
		local t = u * T3
		local sp, mp
		if t < T1 then
			local k = t / T1
			local e = 1 - (1 - k) ^ 2
			sp = sunRise0:Lerp(sunRise1, e)
			mp = moonRise0:Lerp(moonRise1, e)
			galpha(sun, 1 - math.min(1, k * 3))
			galpha(moon, 1 - math.min(1, k * 3))
			-- 사방의 하늘에서 빛줄기가 나에게로 모여든다
			if math.random() < 0.5 then
				local a = math.random() * math.pi * 2
				local p = C + Vector3.new(math.cos(a) * 80, 20 + math.random() * 40, math.sin(a) * 80)
				local tgt = C + UP * 3
				local b = beamTo(p, p + (tgt - p).Unit * 14, 0.25, math.random() < 0.5 and SUN_CORE or MOON, 0.3)
				fadeOut(b, 0.25, { CFrame = b.CFrame + (tgt - p).Unit * 30 })
			end
			if math.random() < 0.3 then
				Fx.burst("glitter", gC + UP, SUN_CORE, 3, 1.5)
			end
		elseif t < T2 then
			local th = theta(t)
			local j = math.clamp((t - T1) / 0.35, 0, 1)
			j = j * j * (3 - 2 * j)
			sp = sunRise1:Lerp(orbitAt(th), j)
			mp = moonRise1:Lerp(orbitAt(th + math.pi), j)
			if graded then
				grade.TintColor = Color3.fromRGB(255, 215, 170):Lerp(Color3.fromRGB(170, 190, 255), (math.sin(th) + 1) / 2)
			end
		else
			local k = math.clamp((t - T2) / (T3 - T2), 0, 1)
			local th = theta(T2)
			sp = orbitAt(th):Lerp(sky, k ^ 2.2)
			mp = orbitAt(th + math.pi):Lerp(sky, k ^ 2.2)
		end
		st.sun, st.moon = sp, mp
		local face = camFace(sp, -look)
		gset(sun, CFrame.lookAt(sp, sp + face) * CFrame.Angles(0, 0, t * 2))
		gset(moon, CFrame.lookAt(mp, mp + face) * CFrame.Angles(0, 0, -0.5 + math.sin(t * 2) * 0.3))
		if t >= T1 and os.clock() - lastTrail > 0.03 then
			lastTrail = os.clock()
			trailDot(sp, 7, SUN, 0.45)
			trailDot(mp, 7, MOON, 0.45)
		end
		if u >= 1 and not hidden then
			hidden = true
			gfade(sun, 0.05)
			gfade(moon, 0.05)
		end
	end)
	-- 합삭: 머리 위의 거대한 일식
	task.delay(T3, function()
		local ecl = group()
		gpart(ecl, v3(24), DARK, Enum.Material.SmoothPlastic, 0, "ball", CFrame.new())
		gHalo(ecl, 13, 1.6, SUN_CORE, 40, 0, nil)
		gHalo(ecl, 14.6, 0.6, SUN, 44, 0.25, nil)
		for k = 0, 23 do
			local a = k / 24 * math.pi * 2
			local L = 8 + math.random() * 18
			gpart(ecl, Vector3.new(0.5 + math.random() * 0.6, L, 0.3), SUN_CORE:Lerp(SUN, math.random()), Enum.Material.Neon, 0.25 + math.random() * 0.3, nil, CFrame.Angles(0, 0, a) * CFrame.new(0, 13 + L / 2, 0))
		end
		gpart(ecl, v3(44), SUN, Enum.Material.Neon, 0.86, "ball", CFrame.new())
		local cracksG = group()
		local flare = part(v3(1), WHITE, Enum.Material.Neon, 0, "ball")
		if graded then
			gradeTo(0.25, -0.85, -0.12, 0.35, Color3.fromRGB(230, 225, 255))
		end
		local face0 = camFace(sky, -look)
		Fx.flash(sky, SUN_CORE, 200, 10, 0.5)
		Fx.ring(sky, SUN_CORE, 10, 120, 0.6, face0)
		Fx.breakSound("boom", 1.2, 0.3, C)
		Fx.sound("ping", 0.6, 0.4, C)
		shakeNear(C, 2, 300)
		local hold = T5 - T3
		local rayEnd = T4 - T3
		local cracked = false
		local lastRing = 0
		anim(hold, function(u)
			local t = u * hold
			local face = camFace(sky, -look)
			local jit = t > rayEnd and (math.random() - 0.5) * 0.9 or 0
			local cf = CFrame.lookAt(sky, sky + face) * CFrame.new(jit, jit, 0)
			local spin = CFrame.Angles(0, 0, t * 0.35)
			gset(ecl, cf * spin)
			gset(cracksG, cf * spin)
			-- 다이아몬드 고리: 테의 한 점이 크게 번쩍였다 잦아든다
			local fl = math.max(0, 1 - t / 0.5)
			flare.CFrame = cf * CFrame.new(9.5, 9.5, -0.5)
			flare.Size = v3(1 + fl * 10)
			flare.Transparency = 1 - fl
			-- 빛살 비 (장식): 일식에서 땅 여기저기로
			if t > 0.1 and t < rayEnd and math.random() < 0.45 then
				local a = math.random() * math.pi * 2
				local r = math.random() * (d.range or 55)
				local b = beamTo(sky, gC + Vector3.new(math.cos(a) * r, 0.2, math.sin(a) * r), 0.35, SUN_CORE, 0.45)
				fadeOut(b, 0.18)
			end
			if t < rayEnd and os.clock() - lastRing > 0.3 then
				lastRing = os.clock()
				Fx.ring(gC + UP * 0.4, SUN_CORE, 6, 60, 0.6)
			end
			-- 개벽 직전: 일식에 금이 간다
			if not cracked and t >= rayEnd then
				cracked = true
				for _ = 1, 8 do
					local a = math.random() * math.pi * 2
					local L = 6 + math.random() * 8
					gpart(cracksG, Vector3.new(0.45, L, 0.2), WHITE, Enum.Material.Neon, 0, nil, CFrame.Angles(0, 0, a) * CFrame.new(0, L * 0.4, -12.2))
				end
				Fx.sound("shatter", 0.8, 0.6, C)
				Fx.flash(sky, WHITE, 120, 6, 0.3)
			end
			if u >= 1 then
				gfade(ecl, 0.05)
				gfade(cracksG, 0.05)
				flare:Destroy()
			end
		end)
	end)
	-- 개벽: 일식이 깨지며 새벽빛으로 터진다
	task.delay(T5, function()
		orbState[d.m] = nil
		local R = d.radius or 40
		for k = 0, 13 do
			local a = k / 14 * math.pi * 2
			local out = right * math.cos(a) + UP * math.sin(a) + look * (math.random() - 0.5)
			local sh = part(Vector3.new(3 + math.random() * 3, 3 + math.random() * 3, 1), DARK, Enum.Material.SmoothPlastic, 0)
			sh.CFrame = CFrame.new(sky) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
			fadeOut(sh, 0.9, { CFrame = CFrame.new(sky + out * 40 - UP * 6) * CFrame.Angles(math.random() * 6, math.random() * 6, 0), Size = v3(0.5) })
		end
		local core = part(v3(10), WHITE, Enum.Material.Neon, 0, "ball")
		core.Position = sky
		fadeOut(core, 1.0, { Size = v3(180) })
		local shell = part(v3(12), SUN_CORE, Enum.Material.Neon, 0.4, "ball")
		shell.Position = sky
		fadeOut(shell, 1.3, { Size = v3(240) })
		local col = beamTo(gC - UP * 2, sky + UP * 100, 28, SUN_CORE, 0.05)
		fadeOut(col, 1.0, { Size = Vector3.new(col.Size.X, 70, 70) })
		local dome = part(v3(6), SUN, Enum.Material.Neon, 0.3, "ball")
		dome.Position = gC
		fadeOut(dome, 0.9, { Size = v3(R * 2.6) })
		Fx.ring(gC + UP * 0.5, SUN_CORE, 8, R * 3.4, 1.0)
		Fx.ring(gC + UP * 2, SUN, 6, R * 2.6, 0.9)
		Fx.ring(gC + UP * 4, MOON, 6, R * 2, 0.8)
		Fx.blast(gC + UP * 3, SUN_CORE, SUN, 4.2)
		Fx.debris(gC, 20, 50)
		Fx.flash(sky, WHITE, 260, 12, 1.4)
		if opts.flash and near(C, 200) then
			opts.flash(Color3.fromRGB(255, 240, 210), 0.5)
		end
		Fx.breakSound("boom", 1.3, 0.28, C)
		Fx.breakSound("glass", 1, 0.5, C)
		shakeNear(C, 3, 320)
		if graded then
			gradeTo(0.12, 0.25, 0.45, 0.1, Color3.fromRGB(255, 225, 185))
			task.delay(0.35, function()
				gradeReset(1.8)
			end)
		end
		-- 새벽빛 먼지가 천천히 떠오른다
		for k = 1, 8 do
			task.delay(k * 0.1, function()
				Fx.burst("glitter", gC + Vector3.new((math.random() - 0.5) * 40, 2, (math.random() - 0.5) * 40), SUN_CORE, 6, 1.6)
			end)
		end
	end)
end
-- 일월윤전의 한 박자: 도는 해는 불기둥을, 도는 달은 초승달을 적에게 꽂는다
function H.eclipseStrike(d: any)
	local st = orbState[d.m]
	local isSun = d.who == "sun"
	local src0 = st and (isSun and st.sun or st.moon)
	for _, at in ipairs(d.ats or {}) do
		if near(at, 320) then
			local src = src0 or (at + Vector3.new(0, 40, 0))
			local g = ground(at)
			if isSun then
				local b = beamTo(src, at, 2.6, SUN_CORE, 0.05)
				local gl = beamTo(src, at, 5.5, SUN, 0.5)
				fadeOut(b, 0.22, { Size = Vector3.new(b.Size.X, 0.2, 0.2) })
				fadeOut(gl, 0.3, { Size = Vector3.new(gl.Size.X, 0.4, 0.4) })
				local fire = beamTo(g, g + UP * 12, 3, Color3.fromRGB(255, 130, 50), 0.2)
				fadeOut(fire, 0.4, { Size = Vector3.new(12, 0.5, 0.5) })
				Fx.burst("ember", at, SUN, 8, 1.6)
				Fx.ring(g + UP * 0.3, SUN, 2, 14, 0.35)
				Fx.sound("heavy", 0.6, 1.1, at)
			else
				local mg = moonGroup(4.5, MOON, 1.6)
				local yaw = math.random() * math.pi * 2
				anim(0.14, function(u)
					local p = src:Lerp(at, u)
					gset(mg, CFrame.new(p) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, u * 6))
					if u >= 1 then
						gfade(mg, 0.15)
						Fx.ring(g + UP * 0.3, MOON, 2, 14, 0.35)
						Fx.burst("glitter", at, MOON, 8, 1.4)
						Fx.sound("deflect", 0.6, 1.1, at)
					end
				end)
			end
		end
	end
end
-- 일식의 빛살: 하늘의 일식에서 적에게 꽂히고, 그 자리에서 빛의 가시가 솟는다
function H.eclipseRay(d: any)
	local from: Vector3 = d.from
	for _, at in ipairs(d.ats or {}) do
		if near(at, 320) then
			local core = beamTo(from, at, 1.2, WHITE, 0)
			local glow = beamTo(from, at, 3.4, SUN_CORE, 0.45)
			fadeOut(core, 0.18, { Size = Vector3.new(core.Size.X, 0.1, 0.1) })
			fadeOut(glow, 0.25, { Size = Vector3.new(glow.Size.X, 0.3, 0.3) })
			local g = ground(at)
			local spike = beamTo(g, g + UP * 9, 2.2, SUN_CORE, 0.1)
			fadeOut(spike, 0.3, { Size = Vector3.new(spike.Size.X, 0.3, 0.3) })
			Fx.burst("spark", at, SUN, 6, 1.2)
			Fx.ring(g + UP * 0.3, SUN_CORE, 1, 10, 0.25)
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

-- 노을의 해: 노을빛 몸을 보랏빛 구름 띠 넷이 가로지른다 (어느 쪽에서 봐도 가로줄)
local function duskSunGroup(R: number): Group
	local g = sunGroup(R, DUSK)
	for i, y in ipairs({ -0.55, -0.2, 0.15, 0.5 }) do
		local w = math.sqrt(math.max(0.05, 1 - y * y)) * R * 2.3
		gpart(g, Vector3.new(R * 0.09, w, w), DUSK2, Enum.Material.Neon, 0.3 + i * 0.08, "cyl", CFrame.new(0, y * R, 0) * CFrame.Angles(0, 0, math.rad(90)))
	end
	return g
end

------------------------------------------------------------------------
-- 황혼낙일 (황혼 G, 3.1.1판 새로)
-- 하늘 저편에서 거대한 석양이 내려와 앞의 땅에 닿는다 → 땅이 노을빛 바다가 되고 석양이 천천히 가라앉는다
-- (가라앉는 동안 노을빛 물결이 넷 퍼지고 달빛 기둥이 솟는다) → 다 잠기면 바다가 검보랏빛으로 식어 고요해진다
-- → 바다가 노을 불꽃의 왕관으로 솟구친다
------------------------------------------------------------------------
function H.sunsetSea(d: any)
	local c: Vector3 = d.at
	if not near(c, 450) then
		return
	end
	local dir = flat(d.dir or Vector3.new(0, 0, -1))
	local descend, sink, dark = d.descend or 0.7, d.sink or 1.6, d.dark or 0.3
	local R = d.radius or 24
	local g = ground(c)
	local SR = 12
	local total = descend + sink
	local sun = duskSunGroup(SR)
	local hi = g + UP * 70 + dir * 25
	local touch = g + UP * (SR * 0.95)
	local under = g - UP * (SR * 1.15)
	if opts.tint then
		opts.tint(Color3.fromRGB(255, 165, 130), 0.4, total + dark + 0.3)
	end
	-- 바다 (처음엔 보이지 않는다): 노을빛 가운데, 보랏빛 테, 흰 빛의 심
	local rim = part(Vector3.new(0.3, 1, 1), DUSK2, Enum.Material.Neon, 1, "cyl")
	rim.CFrame = CFrame.new(g + UP * 0.16) * CFrame.Angles(0, 0, math.rad(90))
	local sea = part(Vector3.new(0.32, 1, 1), DUSK, Enum.Material.Neon, 1, "cyl")
	sea.CFrame = CFrame.new(g + UP * 0.2) * CFrame.Angles(0, 0, math.rad(90))
	local glow = part(Vector3.new(0.34, 1, 1), SUN_CORE, Enum.Material.Neon, 1, "cyl")
	glow.CFrame = CFrame.new(g + UP * 0.24) * CFrame.Angles(0, 0, math.rad(90))
	-- 해기둥: 해 위로 곧게 솟은 노을빛 기둥
	local pillar = part(Vector3.new(1, 2, 2), DUSK, Enum.Material.Neon, 0.55, "cyl")
	Fx.sound("swing", 1, 0.4, c)
	anim(total, function(u)
		local t = u * total
		local p
		if t < descend then
			local k = t / descend
			p = hi:Lerp(touch, 1 - (1 - k) ^ 2)
		else
			local k = (t - descend) / sink
			p = touch:Lerp(under, k * k * (3 - 2 * k))
		end
		gset(sun, CFrame.new(p) * CFrame.Angles(0, t * 0.4, 0))
		setBeam(pillar, p + UP * SR * 0.8, p + UP * (SR + 45), 2.2 + math.sin(t * 20) * 0.3)
		if t > descend and math.random() < 0.6 then
			local a = math.random() * math.pi * 2
			Fx.burst("ember", g + Vector3.new(math.cos(a) * SR, 1, math.sin(a) * SR), DUSK, 4, 1.6)
		end
		if u >= 1 then
			gfade(sun, 0.2)
			fadeOut(pillar, 0.25)
		end
	end)
	-- 닿는 순간: 땅이 노을빛 바다가 된다
	task.delay(descend, function()
		tween(rim, 0.45, { Size = Vector3.new(0.3, R * 2.2, R * 2.2), Transparency = 0.4 })
		tween(sea, 0.35, { Size = Vector3.new(0.32, R * 2, R * 2), Transparency = 0.25 })
		tween(glow, 0.3, { Size = Vector3.new(0.34, R * 0.8, R * 0.8), Transparency = 0.35 })
		Fx.ring(g + UP * 0.4, DUSK, 4, R * 2.6, 0.6)
		Fx.debris(g, 12, 36)
		Fx.flash(c, DUSK, 90, 6, 0.5)
		Fx.breakSound("boom", 1, 0.5, c)
		shakeNear(c, 1.4, 180)
		anim(sink, function(u)
			if math.random() < 0.12 then
				Fx.ring(g + UP * 0.35, DUSK:Lerp(DUSK2, math.random()), 2, R * 2, 0.6)
			end
			if math.random() < 0.35 then
				local a = math.random() * math.pi * 2
				local r = math.random() * R
				local bub = part(v3(1), math.random() < 0.5 and DUSK or DUSK2, Enum.Material.Neon, 0.2, "ball")
				bub.Position = g + Vector3.new(math.cos(a) * r, 0.5, math.sin(a) * r)
				fadeOut(bub, 0.5, { Size = Vector3.new(3, 0.5, 3) })
			end
			glow.Size = Vector3.new(0.34, R * (0.8 - u * 0.5), R * (0.8 - u * 0.5))
		end)
		-- 노을 물결: 가라앉는 해에서 땅을 따라 가로로 퍼지는 빛의 판
		local waves = d.waves or 4
		for i = 1, waves do
			task.delay((i - 0.5) * sink / waves, function()
				local blade = part(Vector3.new(0.25, SR * 2, SR * 2), DUSK:Lerp(SUN_CORE, 0.35), Enum.Material.Neon, 0.2, "cyl")
				blade.CFrame = CFrame.new(g + UP * (1.2 + i * 0.3)) * CFrame.Angles(0, 0, math.rad(90))
				fadeOut(blade, 0.55, { Size = Vector3.new(0.1, R * 2.5, R * 2.5) })
				Fx.ring(g + UP * 1.5, DUSK, SR * 2, R * 2.6, 0.55)
				Fx.sound("swing", 0.8, 0.5 + i * 0.05, c)
				shakeNear(c, 0.7, 140)
			end)
		end
		-- 달빛 기둥: 바다 여기저기에서 보랏빛 기둥이 솟고 꼭대기에 초승달이 맺힌다
		local beams = d.beams or {}
		for i, pt in ipairs(beams) do
			task.delay((i - 0.5) * sink / math.max(1, #beams), function()
				local pg = ground(pt)
				local beam = beamTo(pg, pg + UP * 30, 3, DUSK2, 0.1)
				fadeOut(beam, 0.45, { Size = Vector3.new(beam.Size.X, 0.4, 0.4) })
				local mg = moonGroup(3, MOON, 1.2)
				local face = camFace(pg, dir)
				anim(0.4, function(u)
					local p = pg + UP * (6 + u * 26)
					gset(mg, CFrame.lookAt(p, p + Vector3.new(face.X, 0, face.Z)) * CFrame.Angles(0, 0, u * 4))
					if u >= 1 then
						gfade(mg, 0.15)
					end
				end)
				Fx.ring(pg + UP * 0.4, DUSK2, 1, 12, 0.3)
				Fx.sound("deflect", 0.5, 1.2, pg)
			end)
		end
	end)
	-- 해가 다 잠긴다: 바다가 검보랏빛으로 식고 고요해진다
	task.delay(total, function()
		local cold = DARK:Lerp(DUSK2, 0.45)
		tween(sea, dark, { Color = cold })
		tween(rim, dark, { Color = DARK })
		tween(glow, dark, { Transparency = 1 })
		if opts.tint then
			opts.tint(Color3.fromRGB(120, 90, 150), 0.5, dark)
		end
	end)
	-- 노을 불꽃의 왕관: 바다가 한꺼번에 솟구친다
	task.delay(total + dark, function()
		fadeOut(sea, 0.4)
		fadeOut(rim, 0.4)
		fadeOut(glow, 0.1)
		for k = 0, 19 do
			local a = k / 20 * math.pi * 2
			local out = Vector3.new(math.cos(a), 0, math.sin(a))
			local p = g + out * (R * 0.7)
			local h = 16 + (k % 2) * 10
			local sp = beamTo(p, p + UP * h + out * 4, 3.2, k % 2 == 0 and DUSK or DUSK2, 0.1)
			fadeOut(sp, 0.7, { Size = Vector3.new(sp.Size.X, 0.4, 0.4) })
		end
		local col = beamTo(g - UP * 2, g + UP * 130, 18, SUN_CORE, 0.05)
		fadeOut(col, 0.8, { Size = Vector3.new(col.Size.X, 50, 50) })
		local core = part(v3(6), WHITE, Enum.Material.Neon, 0, "ball")
		core.Position = g + UP * 2
		fadeOut(core, 0.7, { Size = v3(R * 2.2) })
		local shell = part(v3(8), DUSK, Enum.Material.Neon, 0.35, "ball")
		shell.Position = g + UP * 2
		fadeOut(shell, 0.9, { Size = v3(R * 3) })
		local outer = part(v3(8), DUSK2, Enum.Material.Neon, 0.6, "ball")
		outer.Position = g + UP * 2
		fadeOut(outer, 1.0, { Size = v3(R * 3.8) })
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2 + 0.2
			local out = Vector3.new(math.cos(a), 0, math.sin(a))
			local mg = moonGroup(2.8, k % 2 == 0 and DUSK2 or DUSK, 1)
			anim(0.65, function(u)
				local p = g + UP * (4 + math.sin(u * math.pi) * 9) + out * (4 + u * R * 1.7)
				gset(mg, CFrame.lookAt(p, p + out) * CFrame.Angles(0, math.rad(90), u * 9))
				if u >= 1 then
					gfade(mg, 0.15)
				end
			end)
		end
		Fx.ring(g + UP * 0.5, DUSK, 6, R * 3.2, 0.8)
		Fx.ring(g + UP * 2, DUSK2, 5, R * 2.5, 0.7)
		Fx.blast(g + UP * 3, DUSK, DUSK2, 3.4)
		Fx.debris(g, 16, 44)
		Fx.flash(c, DUSK, 150, 9, 0.9)
		if opts.flash and near(c, 120) then
			opts.flash(DUSK, 0.3)
		end
		Fx.breakSound("boom", 1.2, 0.4, c)
		Fx.breakSound("rock", 1, 0.6, c)
		shakeNear(c, 2.4, 240)
	end)
end

------------------------------------------------------------------------
-- 일월동귀 (황혼의 초 오의, 3.1.1판 새로)
-- 컷씬: 하늘이 노을로 물들고 양쪽에서 거대한 석양과 보랏빛 달이 내게로 내려온다
-- → 둘이 빨려 들며 작아져 내 오른손 (해) 과 왼손 (달) 에 맺힌다
-- → 손을 떠나 발밑 진의 테두리를 서로 반대로 내달리며 불의 원을 그리고, 앞에서 만난다
-- → 하나가 된 황혼의 구슬이 머리 위로 떠올라 커지며 둘레를 빨아들이다가, 한 점으로 줄어든다 (빛이 모두 꺼진다)
-- → 세상이 노을빛으로 하얗게 터진다
------------------------------------------------------------------------
function H.twilightCollapse(d: any)
	local C: Vector3 = d.at
	if not near(C, 600) then
		return
	end
	local look = flat(d.dir or Vector3.new(0, 0, -1))
	local right = Vector3.new(-look.Z, 0, look.X)
	local T1 = d.cut or 1.3
	local T2 = T1 + (d.gather or 0.8)
	local T3 = T2 + (d.circle or 1.2)
	local T4 = T3 + (d.fuse or 0.6)
	local T5 = T4 + (d.collapse or 0.35)
	local RR = d.rim or 26
	local gC = ground(C)
	local m = d.m
	local function hand(name: string, fallback: Vector3): Vector3
		local h = typeof(m) == "Instance" and m:FindFirstChild(name)
		if h and h:IsA("BasePart") then
			return h.Position
		end
		return fallback
	end
	local graded = near(C, 250)
	if graded then
		gradeTo(0.8, -0.2, -0.15, 0.2, Color3.fromRGB(255, 190, 170))
	end
	runSigil(C, RR, DUSK, DUSK2, T4, 1.3)
	Fx.sound("ping", 0.7, 0.3, C)
	local bigSun, bigMoon = sunGroup(11, DUSK), moonGroup(13, DUSK2, 5)
	local smallSun, smallMoon = sunGroup(1.4, DUSK), moonGroup(1.9, DUSK2, 0.8)
	galpha(bigSun, 1)
	galpha(bigMoon, 1)
	galpha(smallSun, 1)
	galpha(smallMoon, 1)
	local sunA, sunB = C + right * 34 + UP * 70 - look * 10, C + right * 15 + UP * 13
	local moonA, moonB = C - right * 34 + UP * 74 - look * 10, C - right * 15 + UP * 14
	local trail: { BasePart } = {}
	local lastTrail = 0
	local rhHold, lhHold = C + right * 2, C - right * 2
	local function rimAt(a: number): Vector3
		return gC + UP * 3 + (right * math.cos(a) + look * math.sin(a)) * RR
	end
	local hidden = false
	anim(T3, function(u)
		local t = u * T3
		if t < T1 then
			local k = t / T1
			local e = 1 - (1 - k) ^ 2
			local sp, mp = sunA:Lerp(sunB, e), moonA:Lerp(moonB, e)
			galpha(bigSun, 1 - math.min(1, k * 3))
			galpha(bigMoon, 1 - math.min(1, k * 3))
			gset(bigSun, CFrame.lookAt(sp, sp + camFace(sp, -look)) * CFrame.Angles(0, 0, t * 1.5))
			gset(bigMoon, CFrame.lookAt(mp, mp + camFace(mp, -look)) * CFrame.Angles(0, 0, -0.4))
			if math.random() < 0.3 then
				Fx.burst("ember", gC + UP, DUSK, 3, 1.5)
			end
		elseif t < T2 then
			local k = (t - T1) / (T2 - T1)
			local rh = hand("RightHand", C + right * 2 + UP)
			local lh = hand("LeftHand", C - right * 2 + UP)
			rhHold, lhHold = rh, lh
			local bp, bm = sunB:Lerp(rh, k * k), moonB:Lerp(lh, k * k)
			gset(bigSun, CFrame.lookAt(bp, bp + camFace(bp, -look)) * CFrame.Angles(0, 0, t * 3))
			gset(bigMoon, CFrame.lookAt(bm, bm + camFace(bm, -look)) * CFrame.Angles(0, 0, -0.4))
			galpha(bigSun, k)
			galpha(bigMoon, k)
			gset(smallSun, CFrame.lookAt(rh, rh + camFace(rh, -look)) * CFrame.Angles(0, 0, t * 4))
			gset(smallMoon, CFrame.lookAt(lh, lh + camFace(lh, -look)))
			galpha(smallSun, 1 - k)
			galpha(smallMoon, 1 - k)
			if math.random() < 0.6 then
				trailDot(bp, 1 + 4 * (1 - k), DUSK, 0.3)
				trailDot(bm, 1 + 4 * (1 - k), DUSK2, 0.3)
			end
		else
			if not hidden then
				hidden = true
				gfade(bigSun, 0.05)
				gfade(bigMoon, 0.05)
				Fx.sound("swing", 1, 0.5, C)
			end
			-- 해는 오른쪽에서 뒤로 돌아, 달은 왼쪽에서 뒤로 돌아 각각 4분의 3 바퀴를 돌아 앞에서 만난다
			local k = (t - T2) / (T3 - T2)
			local aS = -k * 1.5 * math.pi
			local aM = math.pi + k * 1.5 * math.pi
			local j = math.clamp(k / 0.12, 0, 1)
			local sp = rhHold:Lerp(rimAt(aS), j)
			local mp = lhHold:Lerp(rimAt(aM), j)
			gset(smallSun, CFrame.lookAt(sp, sp + camFace(sp, -look)) * CFrame.Angles(0, 0, t * 6))
			gset(smallMoon, CFrame.lookAt(mp, mp + camFace(mp, -look)) * CFrame.Angles(0, 0, t * 6))
			if os.clock() - lastTrail > 0.02 then
				lastTrail = os.clock()
				for _, q in ipairs({ { sp, DUSK }, { mp, DUSK2 } }) do
					local f = part(v3(3.2), q[2] :: Color3, Enum.Material.Neon, 0.2, "ball")
					f.Position = (q[1] :: Vector3) - UP * 1.5
					table.insert(trail, f)
					local fl = part(Vector3.new(1.2, 5, 1.2), (q[2] :: Color3):Lerp(SUN_CORE, 0.3), Enum.Material.Neon, 0.35)
					local fp = (q[1] :: Vector3) + UP * 0.5
					fl.Position = fp
					fadeOut(fl, 0.4, { Size = Vector3.new(0.2, 9, 0.2), Position = fp + UP * 3 })
				end
				if math.random() < 0.4 then
					Fx.burst("ember", sp, DUSK, 3, 1.3)
					Fx.burst("glitter", mp, DUSK2, 3, 1.3)
				end
			end
			if u >= 1 then
				gfade(smallSun, 0.05)
				gfade(smallMoon, 0.05)
			end
		end
	end)
	-- 하나가 된다: 앞에서 만난 둘이 황혼의 구슬이 되어 머리 위로 떠오르며 커지고, 둘레를 빨아들이다가 한 점으로 줄어든다
	task.delay(T3, function()
		local F = rimAt(math.pi / 2)
		local O = C + UP * 18
		local core = part(v3(1), WHITE, Enum.Material.Neon, 0, "ball")
		local inner = part(v3(1), DUSK, Enum.Material.Neon, 0.15, "ball")
		local outer = part(v3(1), DUSK2, Enum.Material.Neon, 0.5, "ball")
		local ringA, ringB = group(), group()
		gHalo(ringA, 13, 0.7, DUSK, 30, 0.1, nil)
		gHalo(ringB, 15, 0.5, DUSK2, 34, 0.2, nil)
		galpha(ringA, 1)
		galpha(ringB, 1)
		Fx.flash(F, DUSK, 120, 8, 0.4)
		Fx.breakSound("boom", 1, 0.5, C)
		shakeNear(C, 1.6, 240)
		local fuse, col = T4 - T3, T5 - T4
		anim(fuse + col, function(u)
			local t = u * (fuse + col)
			local p, s
			if t < fuse then
				local k = t / fuse
				p = F:Lerp(O, 1 - (1 - k) ^ 2)
				s = 3 + 19 * k
				galpha(ringA, 1 - k)
				galpha(ringB, 1 - k)
				if math.random() < 0.7 then
					local a = math.random() * math.pi * 2
					local q = gC + Vector3.new(math.cos(a) * RR * 1.2, 1 + math.random() * 6, math.sin(a) * RR * 1.2)
					local b = beamTo(q, p, 0.3, math.random() < 0.5 and DUSK or DUSK2, 0.3)
					fadeOut(b, 0.15)
				end
			else
				local k = (t - fuse) / col
				p = O
				s = 22 * (1 - k) ^ 3 + 0.4
				galpha(ringA, k)
				galpha(ringB, k)
			end
			core.Size = v3(s * 0.45)
			core.Position = p
			inner.Size = v3(s * 0.8)
			inner.Position = p
			outer.Size = v3(s)
			outer.Position = p
			gset(ringA, CFrame.new(p) * CFrame.Angles(t * 2.2, t * 1.4, 0))
			gset(ringB, CFrame.new(p) * CFrame.Angles(-t * 1.6, 0, t * 2.4))
			if u >= 1 then
				core:Destroy()
				inner:Destroy()
				outer:Destroy()
				gfade(ringA, 0.05)
				gfade(ringB, 0.05)
			end
		end)
	end)
	-- 줄어드는 순간: 불의 원과 모든 빛이 꺼진다
	task.delay(T4, function()
		for _, p in ipairs(trail) do
			if p.Parent then
				fadeOut(p, 0.12)
			end
		end
		if graded then
			gradeTo(0.2, -0.6, -0.4, 0.3, Color3.fromRGB(200, 170, 230))
		end
		Fx.sound("ping", 0.5, 0.35, C)
	end)
	-- 세상이 노을빛으로 하얗게 터진다
	task.delay(T5, function()
		local R = d.radius or 50
		local O = C + UP * 18
		local core = part(v3(4), WHITE, Enum.Material.Neon, 0, "ball")
		core.Position = O
		fadeOut(core, 1.0, { Size = v3(140) })
		local shell = part(v3(6), DUSK, Enum.Material.Neon, 0.35, "ball")
		shell.Position = O
		fadeOut(shell, 1.2, { Size = v3(180) })
		local shell2 = part(v3(6), DUSK2, Enum.Material.Neon, 0.55, "ball")
		shell2.Position = O
		fadeOut(shell2, 1.4, { Size = v3(220) })
		for k = 0, 15 do
			local a = k / 16 * math.pi * 2
			local out = Vector3.new(math.cos(a), 0, math.sin(a))
			local mg = moonGroup(4, k % 2 == 0 and DUSK or DUSK2, 1.4)
			anim(0.7, function(u)
				local p = O:Lerp(gC + UP * 3, u) + out * (3 + u * R * 1.3)
				gset(mg, CFrame.lookAt(p, p + out) * CFrame.Angles(0, math.rad(90), u * 10))
				if u >= 1 then
					gfade(mg, 0.15)
				end
			end)
			local ray = beamTo(gC + UP * 0.3, gC + out * R * 1.4 + UP * 0.3, 1.6, k % 2 == 0 and DUSK or DUSK2, 0.1)
			fadeOut(ray, 0.7)
		end
		local colm = beamTo(gC - UP * 2, gC + UP * 160, 24, WHITE, 0.05)
		fadeOut(colm, 1.0, { Size = Vector3.new(colm.Size.X, 60, 60) })
		Fx.ring(gC + UP * 0.5, WHITE, 8, R * 3.2, 1.0)
		Fx.ring(gC + UP * 2, DUSK, 6, R * 2.6, 0.9)
		Fx.ring(gC + UP * 4, DUSK2, 6, R * 2, 0.8)
		Fx.blast(gC + UP * 4, DUSK, DUSK2, 4.4)
		Fx.debris(gC, 24, 54)
		Fx.flash(O, WHITE, 260, 12, 1.4)
		if opts.flash and near(C, 200) then
			opts.flash(Color3.fromRGB(255, 220, 200), 0.5)
		end
		Fx.breakSound("boom", 1.3, 0.26, C)
		Fx.breakSound("glass", 1, 0.45, C)
		shakeNear(C, 3.2, 320)
		if graded then
			gradeTo(0.1, 0.2, 0.5, 0.1, Color3.fromRGB(255, 205, 170))
			task.delay(0.3, function()
				gradeReset(1.8)
			end)
		end
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

------------------------------------------------------------------------
-- 초 오의 컷씬 (쓴 사람 화면에서만, 대사 없이)
-- 일월개벽: 앞쪽 낮은 곳에서 나를 올려다보며 물러선다 (내 등 뒤 지평선에서 해와 달이 솟는다)
-- 일월동귀: 나를 가운데 두고 천천히 돌며 올라간다 (양쪽에서 석양과 달이 내려온다)
------------------------------------------------------------------------
local cutActive = false
function Geuk.superCut(model: Model, dur: number, name: string, shake: ((number) -> ())?, dusk: boolean?)
	local cam = workspace.CurrentCamera
	local r = rootOf(model)
	local player = game:GetService("Players").LocalPlayer
	if not cam or not r or cutActive or not player then
		return
	end
	cutActive = true
	local g = Instance.new("ScreenGui")
	g.Name = "KwonGeukCut"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 85
	g.Parent = player:WaitForChild("PlayerGui")
	local tintF = Instance.new("Frame")
	tintF.Size = UDim2.fromScale(1, 1)
	tintF.BackgroundColor3 = dusk and Color3.fromRGB(90, 30, 60) or Color3.fromRGB(20, 18, 50)
	tintF.BackgroundTransparency = 1
	tintF.BorderSizePixel = 0
	tintF.Parent = g
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.4, 1), NumberSequenceKeypoint.new(0.6, 1), NumberSequenceKeypoint.new(1, 0.1) })
	grad.Parent = tintF
	tween(tintF, 0.3, { BackgroundTransparency = 0.4 })
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
	label.TextColor3 = dusk and Color3.fromRGB(255, 200, 150) or SUN_CORE
	label.TextStrokeColor3 = dusk and DUSK2 or Color3.fromRGB(60, 80, 160)
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
		RunService:UnbindFromRenderStep("KwonGeukCut")
		cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
		cam.FieldOfView = oldFov
		cutActive = false
		-- 컷씬이 끝나면 카메라를 내 등 뒤 높은 곳으로 (하늘에서 벌어지는 일이 잘 보이게)
		local function behind()
			if r.Parent then
				local lk = flat(r.CFrame.LookVector)
				cam.CFrame = CFrame.lookAt(r.Position - lk * 22 + UP * 12, r.Position + lk * 4 + UP * 10)
			end
		end
		behind()
		task.defer(behind)
		for _, b in ipairs(bars) do
			tween(b, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
		end
		tween(tintF, 0.25, { BackgroundTransparency = 1 })
		tween(label, 0.2, { TextTransparency = 1 })
		task.delay(0.3, function()
			g:Destroy()
		end)
	end
	RunService:BindToRenderStep("KwonGeukCut", Enum.RenderPriority.Camera.Value + 2, function(dt: number)
		if finished then
			return
		end
		if not r.Parent then
			restore()
			return
		end
		local t = os.clock() - t0
		local k = math.clamp(t / dur, 0, 1)
		focus = focus:Lerp(r.Position, math.min(1, dt * 10))
		local e = 1 - (1 - k) ^ 2
		if dusk then
			local a = e * math.rad(150) - math.rad(40)
			local eye = focus + (look * math.cos(a) + side * math.sin(a)) * (13 + e * 5) + UP * (1.5 + e * 6)
			cam.CFrame = CFrame.lookAt(eye, focus + UP * (3 + e * 8))
		else
			local eye = focus + look * (9 + e * 6) + side * math.sin(e * 0.8) * 6 + UP * (0.6 + e * 2.5)
			cam.CFrame = CFrame.lookAt(eye, focus - look * 60 + UP * (14 + e * 14))
		end
		cam.FieldOfView = oldFov + e * 12
		if t >= dur then
			restore()
		end
	end)
	if shake then
		task.delay(dur * 0.55, function()
			shake(0.8)
		end)
	end
	task.delay(dur + 1, restore)
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
