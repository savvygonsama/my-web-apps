-- 권왕 3.6판: 권왕신권의 오의 · 초 오의 (화면)
-- 패왕행차: 붉은 길과 금빛 깃발, 관과 망토를 두른 금빛 왕의 그림자 넷이 내달려 함께 내리찍는다
-- 천하제일권: 왕관의 해, 적마다 찍히는 왕의 인장, 하늘의 금빛 문에서 내려오는 붉은 소매의 거대한 팔, 충격파 세 겹, 떨어지는 해
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Fx = require(script.Parent:WaitForChild("Fx"))

local Royal = {}

local GOLD = Color3.fromRGB(255, 204, 70)
local GOLD_DEEP = Color3.fromRGB(200, 140, 30)
local CRIMSON = Color3.fromRGB(170, 20, 35)
local CRIMSON_DARK = Color3.fromRGB(100, 10, 20)
local PALE = Color3.fromRGB(255, 244, 205)
local WHITE = Color3.new(1, 1, 1)
local UP = CFrame.Angles(0, 0, math.rad(90))

local folder = Instance.new("Folder")
folder.Name = "KwonRoyal"
folder.Parent = workspace

local opts: any = {}
function Royal.init(o: any)
	opts = o or {}
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
local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function fadeOut(p: BasePart, time: number, goal: { [string]: any }?)
	local g = goal or {}
	g.Transparency = 1
	tween(p, time, g)
	task.delay(time + 0.05, function()
		p:Destroy()
	end)
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
local function shakeNear(pos: Vector3, amount: number, range: number)
	if opts.shake and near(pos, range) then
		opts.shake(amount)
	end
end

-- 몸 하나를 여러 조각으로 함께 움직인다
type Group = { list: { { p: BasePart, off: CFrame } } }
local function gplace(g: Group, cf: CFrame)
	for _, it in ipairs(g.list) do
		if it.p.Parent then
			it.p.CFrame = cf * it.off
		end
	end
end
local function gfade(g: Group, time: number)
	for _, it in ipairs(g.list) do
		if it.p.Parent then
			fadeOut(it.p, time)
		end
	end
end
-- 왕관: 금 테 + 뾰족한 금 쐐기 n개 + 붉은 보석
local function crownInto(g: Group, base: CFrame, R: number, h: number, n: number)
	table.insert(g.list, { p = part(Vector3.new(h * 0.3, R * 2.1, R * 2.1), GOLD, Enum.Material.Metal, 0, "cyl"), off = base * UP })
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		local w = part(Vector3.new(R * 0.3, h, h * 0.25), GOLD, Enum.Material.Metal, 0, "wedge")
		table.insert(g.list, { p = w, off = base * CFrame.Angles(0, a, 0) * CFrame.new(0, h * 0.55, -R) })
		local gem = part(Vector3.new(R * 0.18, R * 0.18, R * 0.18), k % 2 == 0 and CRIMSON or PALE, Enum.Material.Neon, 0, "ball")
		table.insert(g.list, { p = gem, off = base * CFrame.Angles(0, a, 0) * CFrame.new(0, h * 1.05, -R) })
	end
end
-- 금빛 왕의 그림자: 그 사람의 몸을 본떠 금빛 유리로, 머리 위에 관, 등에 붉은 망토
local function kingShade(model: Model?, alpha: number): Group
	local g: Group = { list = {} }
	local r = rootOf(model)
	if model and r then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.9 and d.Size.Magnitude < 8 and d.Parent == model then
				local q = part(d.Size, GOLD, Enum.Material.Glass, alpha, d:IsA("Part") and d.Shape == Enum.PartType.Ball and "ball" or nil)
				table.insert(g.list, { p = q, off = r.CFrame:ToObjectSpace(d.CFrame) })
			end
		end
	else
		table.insert(g.list, { p = part(Vector3.new(2, 4, 1), GOLD, Enum.Material.Glass, alpha), off = CFrame.new() })
	end
	-- 망토: 어깨에서 뒤로 넓게 늘어진다
	local cape = part(Vector3.new(2.6, 3.6, 0.15), CRIMSON, Enum.Material.Fabric, math.min(0.9, alpha + 0.1))
	table.insert(g.list, { p = cape, off = CFrame.new(0, 0, 0.7) * CFrame.Angles(math.rad(14), 0, 0) })
	crownInto(g, CFrame.new(0, 2.6, 0), 0.55, 0.6, 6)
	return g
end

------------------------------------------------------------------------
-- G 패왕행차
------------------------------------------------------------------------
local function banner(pos: Vector3, h: number, face: Vector3, rise: number): { BasePart }
	local list: { BasePart } = {}
	local pole = part(Vector3.new(0.5, h, 0.5), GOLD_DEEP, Enum.Material.Metal)
	local cloth = part(Vector3.new(0.12, h * 0.5, 2.6), CRIMSON, Enum.Material.Fabric)
	local trim = part(Vector3.new(0.14, 0.3, 2.7), GOLD, Enum.Material.Metal)
	local emblem = part(Vector3.new(0.16, 1.1, 1.1), GOLD, Enum.Material.Neon, 0, "cyl")
	local tip = part(Vector3.new(0.7, 0.7, 0.7), GOLD, Enum.Material.Neon, 0, "ball")
	list = { pole, cloth, trim, emblem, tip }
	local side = Vector3.new(-face.Z, 0, face.X)
	local function placeAt(y: number)
		local b = pos + Vector3.new(0, y, 0)
		pole.CFrame = CFrame.new(b + Vector3.new(0, h / 2, 0))
		local clothC = b + Vector3.new(0, h * 0.7, 0) + side * 1.4
		cloth.CFrame = CFrame.lookAt(clothC, clothC + face)
		trim.CFrame = CFrame.lookAt(clothC - Vector3.new(0, h * 0.25, 0), clothC - Vector3.new(0, h * 0.25, 0) + face)
		emblem.CFrame = CFrame.lookAt(clothC + face * 0.1, clothC + face * 5) * CFrame.Angles(0, math.rad(90), 0)
		tip.CFrame = CFrame.new(b + Vector3.new(0, h + 0.3, 0))
	end
	placeAt(-h)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / rise, 0, 1)
		placeAt(-h * (1 - u) ^ 2)
		if u >= 1 then
			conn:Disconnect()
		end
	end)
	return list
end
local function crownSpikes(at: Vector3, R: number, n: number, h: number)
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * R, 0, math.sin(a) * R)
		local w = part(Vector3.new(R * 0.35, 0.5, h * 0.3), GOLD, Enum.Material.Neon, 0.05, "wedge")
		local cf = CFrame.lookAt(p, at) * CFrame.Angles(math.rad(-90), 0, 0)
		w.CFrame = cf
		tween(w, 0.12, { Size = Vector3.new(R * 0.35, h, h * 0.3), CFrame = cf * CFrame.new(0, h / 2, 0) }, Enum.EasingStyle.Back)
		task.delay(0.35, function()
			fadeOut(w, 0.4, { Size = Vector3.new(0.2, h, 0.2) })
		end)
		local gem = part(Vector3.new(1.2, 1.2, 1.2), k % 2 == 0 and CRIMSON or PALE, Enum.Material.Neon, 0, "ball")
		gem.CFrame = CFrame.new(p + Vector3.new(0, h, 0))
		fadeOut(gem, 0.6, { Size = Vector3.new(3, 3, 3) })
	end
end
local function goldBlast(at: Vector3, R: number)
	local g = ground(at)
	local core = part(Vector3.new(3, 3, 3), WHITE, Enum.Material.Neon, 0, "ball")
	core.CFrame = CFrame.new(g + Vector3.new(0, 2, 0))
	fadeOut(core, 0.45, { Size = Vector3.new(R * 1.8, R * 1.8, R * 1.8) })
	local shell = part(Vector3.new(3, 3, 3), GOLD, Enum.Material.Neon, 0.35, "ball")
	shell.CFrame = core.CFrame
	fadeOut(shell, 0.6, { Size = Vector3.new(R * 2.4, R * 2.4, R * 2.4) })
	local col = part(Vector3.new(4, R * 0.9, R * 0.9), PALE, Enum.Material.Neon, 0.1, "cyl")
	col.CFrame = CFrame.new(g + Vector3.new(0, 2, 0)) * UP
	tween(col, 0.15, { Size = Vector3.new(80, R * 0.9, R * 0.9), CFrame = CFrame.new(g + Vector3.new(0, 40, 0)) * UP })
	task.delay(0.18, function()
		fadeOut(col, 0.5, { Size = Vector3.new(80, R * 1.8, R * 1.8) })
	end)
	for k = 0, 2 do
		task.delay(k * 0.07, function()
			Fx.ring(g + Vector3.new(0, 0.5 + k, 0), k == 1 and CRIMSON or GOLD, 4, R * 2.6 + k * 8, 0.6)
		end)
	end
	Fx.burst("glitter", g + Vector3.new(0, 3, 0), GOLD, 30, 2.2)
	Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(170, 150, 120), 20, 1.8)
	Fx.flash(g + Vector3.new(0, 4, 0), GOLD, 90, 7, 0.5)
	Fx.sound("heavy", 1, 0.5, g)
	Fx.breakSound("boom", 1, 0.55, g)
	shakeNear(g, 2.8, 170)
end
local function kingProcession(data: any)
	local from: Vector3, to: Vector3 = data.from, data.to
	if not near(from, 260) then
		return
	end
	local dir = flat(to - from)
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local W = data.width or 9
	local unroll = data.unroll or 0.45
	local charge = data.charge or 0.75
	local leap = data.leap or 0.35
	local g0, g1 = ground(from), ground(to)
	local L = (g1 - g0).Magnitude
	-- 붉은 길 (금빛 테두리)이 앞으로 펼쳐진다
	local road = part(Vector3.new(W * 0.7, 0.2, 0.1), CRIMSON, Enum.Material.Fabric)
	local edges = { part(Vector3.new(0.4, 0.24, 0.1), GOLD, Enum.Material.Metal), part(Vector3.new(0.4, 0.24, 0.1), GOLD, Enum.Material.Metal) }
	local runner = part(Vector3.new(W * 0.25, 0.22, 0.1), CRIMSON_DARK, Enum.Material.Fabric)
	local function placeRoad(len: number)
		local mid = g0 + dir * (len / 2) + Vector3.new(0, 0.12, 0)
		road.Size = Vector3.new(W * 0.7, 0.2, math.max(0.1, len))
		road.CFrame = CFrame.lookAt(mid, mid + dir)
		runner.Size = Vector3.new(W * 0.25, 0.22, math.max(0.1, len))
		runner.CFrame = road.CFrame
		for i, e in ipairs(edges) do
			e.Size = Vector3.new(0.4, 0.24, math.max(0.1, len))
			e.CFrame = road.CFrame * CFrame.new((i == 1 and -1 or 1) * W * 0.35, 0, 0)
		end
	end
	placeRoad(0.1)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / unroll, 0, 1)
		placeRoad(L * (1 - (1 - u) ^ 2))
		if u >= 1 then
			conn:Disconnect()
		end
	end)
	-- 깃발 여덟 (양옆에 넷씩)
	local flags: { BasePart } = {}
	for k = 1, 4 do
		for s = -1, 1, 2 do
			local pos = g0 + dir * (L * k / 4.6) + side * s * (W * 0.62)
			task.delay(unroll * k / 5, function()
				for _, p in ipairs(banner(pos, 9, dir, 0.25)) do
					table.insert(flags, p)
				end
			end)
		end
	end
	Fx.sound("deflect", 0.6, 0.6, from)
	-- 금빛 왕의 그림자 넷: 두 줄 대형으로 뒤에서 내달린다
	local shades: { { g: Group, off: Vector3 } } = {}
	local offs = { side * -2.4, side * 2.4, side * -4.2 - dir * 3.5, side * 4.2 - dir * 3.5 }
	for i = 1, 4 do
		table.insert(shades, { g = kingShade(data.m, 0.35), off = offs[i] })
	end
	local start = from - dir * 5
	for _, sh in ipairs(shades) do
		gplace(sh.g, CFrame.lookAt(start + sh.off, start + sh.off + dir))
	end
	local c0 = os.clock() + unroll
	local lastDust = 0
	local conn2: RBXScriptConnection
	conn2 = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now < c0 then
			return
		end
		local t = now - c0
		local u = math.clamp(t / charge, 0, 1)
		local lu = math.clamp((t - charge) / leap, 0, 1)
		for i, sh in ipairs(shades) do
			local base = start:Lerp(to, u * u * (3 - 2 * u))
			local bob = math.abs(math.sin(t * 18 + i)) * 0.6
			local pos = base + sh.off * (1 - lu) + Vector3.new(0, bob + 10 * math.sin(lu * math.pi) - lu * 1.5, 0)
			gplace(sh.g, CFrame.lookAt(pos, pos + dir) * CFrame.Angles(-lu * 0.6, 0, 0))
		end
		if now - lastDust > 0.08 and u < 1 then
			lastDust = now
			local p = ground(start:Lerp(to, u)) + Vector3.new(0, 0.5, 0)
			Fx.burst("dust", p, Color3.fromRGB(170, 150, 120), 3, 0.9)
			Fx.burst("glitter", p + Vector3.new(0, 2, 0), GOLD, 2, 0.8)
		end
		if lu >= 1 then
			conn2:Disconnect()
			for _, sh in ipairs(shades) do
				gfade(sh.g, 0.3)
			end
			goldBlast(to, data.radius or 16)
			crownSpikes(g1, (data.radius or 16) * 0.65, 10, 9)
			task.delay(0.6, function()
				for _, p in ipairs(flags) do
					if p.Parent then
						fadeOut(p, 0.6)
					end
				end
				for _, p in ipairs({ road, runner, edges[1], edges[2] }) do
					fadeOut(p, 0.8)
				end
			end)
		end
	end)
end

------------------------------------------------------------------------
-- X 천하제일권
------------------------------------------------------------------------
type Decree = { at: Vector3, sun: Group?, sunCF: CFrame?, seals: { BasePart }, done: boolean }
local decrees: { [number]: Decree } = {}
local function sunGroup(R: number): Group
	local g: Group = { list = {} }
	table.insert(g.list, { p = part(Vector3.new(1.2, R * 2, R * 2), GOLD, Enum.Material.Neon, 0.05, "cyl"), off = CFrame.Angles(0, math.rad(90), 0) })
	table.insert(g.list, { p = part(Vector3.new(1.4, R * 1.3, R * 1.3), PALE, Enum.Material.Neon, 0, "cyl"), off = CFrame.Angles(0, math.rad(90), 0) })
	table.insert(g.list, { p = part(Vector3.new(0.6, R * 2.7, R * 2.7), GOLD, Enum.Material.Neon, 0.7, "cyl"), off = CFrame.Angles(0, math.rad(90), 0) })
	-- 위쪽의 왕관 가시 다섯과 보석
	for k = -2, 2 do
		local a = math.rad(k * 26)
		local w = part(Vector3.new(0.8, R * 0.9, R * 0.35), GOLD, Enum.Material.Neon, 0.05, "wedge")
		table.insert(g.list, { p = w, off = CFrame.Angles(0, 0, -a) * CFrame.new(0, R * 1.25, 0) * CFrame.Angles(0, math.rad(90), 0) })
		local gem = part(Vector3.new(R * 0.22, R * 0.22, R * 0.22), k % 2 == 0 and CRIMSON or PALE, Enum.Material.Neon, 0, "ball")
		table.insert(g.list, { p = gem, off = CFrame.Angles(0, 0, -a) * CFrame.new(0, R * 1.75, 0) })
	end
	return g
end
local function decreeOpen(data: any)
	local at: Vector3 = data.at
	if not near(at, 360) then
		return
	end
	local d: Decree = { at = at, sun = nil, sunCF = nil, seals = {}, done = false }
	decrees[data.id] = d
	local dir = flat(data.dir or Vector3.new(0, 0, -1))
	local sun = sunGroup(9)
	d.sun = sun
	local high = at - dir * 26 + Vector3.new(0, 52, 0)
	local low = at - dir * 26 + Vector3.new(0, 20, 0)
	local cut = data.cut or 1.5
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if d.done then
			conn:Disconnect()
			return
		end
		local u = math.clamp((os.clock() - t0) / cut, 0, 1)
		local pos = low:Lerp(high, 1 - (1 - u) ^ 3)
		-- 해는 늘 쓴 사람 쪽을 본다
		local cf = CFrame.lookAt(pos, Vector3.new(at.X, pos.Y, at.Z))
		d.sunCF = cf
		gplace(sun, cf)
	end)
	Fx.sound("deflect", 0.8, 0.5, at)
	-- 금빛 구름 테 (둘레에 떠서 천천히 돈다)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local c = part(Vector3.new(10, 3.4, 7), Color3.fromRGB(255, 226, 160), Enum.Material.SmoothPlastic, 0.4, "ball")
		c.CFrame = CFrame.new(at + Vector3.new(math.cos(a) * 46, 38, math.sin(a) * 46))
		tween(c, 4, { CFrame = CFrame.new(at + Vector3.new(math.cos(a + 0.4) * 46, 38, math.sin(a + 0.4) * 46)) }, Enum.EasingStyle.Linear)
		task.delay(4, function()
			fadeOut(c, 0.8)
		end)
	end
	task.delay(10, function()
		if not d.done then
			d.done = true
			gfade(sun, 0.5)
			for _, s in ipairs(d.seals) do
				if s.Parent then
					fadeOut(s, 0.3)
				end
			end
		end
		decrees[data.id] = nil
	end)
end
-- 왕의 인장: 금빛 원판 (가운데 관 무늬)이 하늘에서 떨어져 발밑에 찍힌다
local function sealOn(d: Decree, model: Model)
	local r = rootOf(model)
	if not r then
		return
	end
	local g = ground(r.Position) + Vector3.new(0, 0.15, 0)
	local disc = part(Vector3.new(0.3, 7, 7), GOLD, Enum.Material.Neon, 0.1, "cyl")
	local inner = part(Vector3.new(0.32, 4.6, 4.6), CRIMSON, Enum.Material.Neon, 0.25, "cyl")
	local top = g + Vector3.new(0, 22, 0)
	disc.CFrame = CFrame.new(top) * UP
	inner.CFrame = CFrame.new(top) * UP
	tween(disc, 0.22, { CFrame = CFrame.new(g) * UP }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(inner, 0.22, { CFrame = CFrame.new(g + Vector3.new(0, 0.02, 0)) * UP }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	table.insert(d.seals, disc)
	table.insert(d.seals, inner)
	task.delay(0.24, function()
		-- 관 무늬: 가시 다섯
		for k = -2, 2 do
			local w = part(Vector3.new(0.6, 0.12, 1.4), PALE, Enum.Material.Neon, 0)
			w.CFrame = CFrame.new(g + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, math.rad(k * 30), 0) * CFrame.new(0, 0, -1.3)
			table.insert(d.seals, w)
		end
		Fx.ring(g + Vector3.new(0, 0.2, 0), GOLD, 2, 12, 0.35)
		Fx.sound("block", 0.4, 1.4, g)
	end)
end
local function decreeSeals(data: any)
	local d = decrees[data.id]
	if not d or d.done then
		return
	end
	local list = data.targets or {}
	local span = data.span or 0.8
	for i, m in ipairs(list) do
		task.delay((i - 1) / math.max(1, #list) * span, function()
			if not d.done then
				sealOn(d, m)
			end
		end)
	end
end
-- 하늘의 금빛 문 (고리)과 붉은 소매를 두른 거대한 팔
local function gateRing(center: Vector3, R: number): { BasePart }
	local list: { BasePart } = {}
	local n = 28
	for k = 0, n - 1 do
		local a0, a1 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
		local p0 = center + Vector3.new(math.cos(a0) * R, 0, math.sin(a0) * R)
		local p1 = center + Vector3.new(math.cos(a1) * R, 0, math.sin(a1) * R)
		local seg = part(Vector3.new(1.6, 1.6, (p1 - p0).Magnitude * 1.05), GOLD, Enum.Material.Neon, 0.05)
		seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
		table.insert(list, seg)
	end
	local inner = part(Vector3.new(0.4, R * 1.9, R * 1.9), CRIMSON, Enum.Material.Neon, 0.35, "cyl")
	inner.CFrame = CFrame.new(center) * UP
	table.insert(list, inner)
	return list
end
local function armGroup(): Group
	local g: Group = { list = {} }
	-- 기준: 주먹 가운데. 소매는 위(+Y)로 길게 뻗는다
	local fist = part(Vector3.new(14, 12, 12), GOLD, Enum.Material.Metal, 0)
	table.insert(g.list, { p = fist, off = CFrame.new() })
	for k = 0, 3 do
		local kn = part(Vector3.new(3.8, 3.8, 3.8), GOLD_DEEP, Enum.Material.Metal, 0, "ball")
		table.insert(g.list, { p = kn, off = CFrame.new(-5.2 + k * 3.5, -6, -4.5) })
	end
	table.insert(g.list, { p = part(Vector3.new(4, 8, 4), GOLD, Enum.Material.Metal), off = CFrame.new(7.5, 0, -2) * CFrame.Angles(0, 0, math.rad(-15)) })
	-- 손목의 금 팔찌 (붉은 보석 줄)
	table.insert(g.list, { p = part(Vector3.new(5, 15, 15), GOLD_DEEP, Enum.Material.Metal, 0, "cyl"), off = CFrame.new(0, 8, 0) * UP })
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		table.insert(g.list, { p = part(Vector3.new(1.6, 1.6, 1.6), CRIMSON, Enum.Material.Neon, 0, "ball"), off = CFrame.new(math.cos(a) * 7.6, 8, math.sin(a) * 7.6) })
	end
	-- 붉은 소매 (금 테 둘)
	table.insert(g.list, { p = part(Vector3.new(60, 16, 16), CRIMSON, Enum.Material.Fabric, 0, "cyl"), off = CFrame.new(0, 40, 0) * UP })
	for _, y in ipairs({ 12, 22 }) do
		table.insert(g.list, { p = part(Vector3.new(1.4, 17, 17), GOLD, Enum.Material.Metal, 0, "cyl"), off = CFrame.new(0, y, 0) * UP })
	end
	return g
end
local function decreeFist(data: any)
	local d = decrees[data.id]
	local at: Vector3 = data.at
	if not near(at, 360) then
		return
	end
	local gate = data.gate or 0.5
	local fall = data.fall or 0.45
	local R = data.radius or 20
	local g = ground(at)
	local top = g + Vector3.new(0, 75, 0)
	-- 문이 열린다
	local ring = gateRing(top, 0.5)
	local holder = part(Vector3.new(1, 1, 1), GOLD, Enum.Material.Neon, 1)
	holder.CFrame = CFrame.new(top)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / gate, 0, 1)
		local rr = 0.5 + 15 * (1 - (1 - u) ^ 3)
		local n = #ring - 1
		for k = 0, n - 1 do
			local a0, a1 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
			local p0 = top + Vector3.new(math.cos(a0) * rr, 0, math.sin(a0) * rr)
			local p1 = top + Vector3.new(math.cos(a1) * rr, 0, math.sin(a1) * rr)
			local seg = ring[k + 1]
			seg.Size = Vector3.new(1.6, 1.6, (p1 - p0).Magnitude * 1.05)
			seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
		end
		ring[#ring].Size = Vector3.new(0.4, rr * 1.9, rr * 1.9)
		if u >= 1 then
			conn:Disconnect()
		end
	end)
	-- 땅에 내리찍힐 자리가 붉게 물든다
	local mark = part(Vector3.new(0.2, R * 2, R * 2), CRIMSON, Enum.Material.Neon, 0.75, "cyl")
	mark.CFrame = CFrame.new(g + Vector3.new(0, 0.12, 0)) * UP
	Fx.sound("deflect", 0.9, 0.4, top)
	-- 팔이 내려온다
	task.delay(gate, function()
		local arm = armGroup()
		local from = top + Vector3.new(0, 30, 0)
		local to = g + Vector3.new(0, 6, 0)
		local f0 = os.clock()
		local c2: RBXScriptConnection
		c2 = RunService.Heartbeat:Connect(function()
			local u = math.clamp((os.clock() - f0) / fall, 0, 1)
			local pos = from:Lerp(to, u * u)
			gplace(arm, CFrame.new(pos))
			if u >= 1 then
				c2:Disconnect()
				-- 내리찍음: 땅이 갈라지고 충격파 세 겹
				fadeOut(mark, 0.3)
				local core = part(Vector3.new(6, 6, 6), WHITE, Enum.Material.Neon, 0, "ball")
				core.CFrame = CFrame.new(g + Vector3.new(0, 2, 0))
				fadeOut(core, 0.4, { Size = Vector3.new(R * 2, R * 2, R * 2) })
				for k = 0, 9 do
					local a = k / 10 * math.pi * 2 + math.random() * 0.3
					local len = R * (0.8 + math.random() * 0.6)
					local c = part(Vector3.new(1.2, 0.3, len), Color3.fromRGB(40, 20, 15), Enum.Material.Slate, 0)
					c.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * len / 2, 0.15, math.sin(a) * len / 2)) * CFrame.Angles(0, -a + math.pi / 2, 0)
					local glow = part(Vector3.new(0.4, 0.34, len * 0.9), GOLD, Enum.Material.Neon, 0.1)
					glow.CFrame = c.CFrame
					task.delay(2.4, function()
						fadeOut(c, 0.6)
						fadeOut(glow, 0.4)
					end)
				end
				for k = 1, data.rings or 3 do
					task.delay(k * (data.ringEvery or 0.22), function()
						local R1 = R * (0.5 + k * 0.6)
						Fx.ring(g + Vector3.new(0, 0.5, 0), k % 2 == 1 and GOLD or CRIMSON, R1 * 0.6, R1 * 2.2, 0.5)
						Fx.burst("dust", g + Vector3.new(0, 0.6, 0), Color3.fromRGB(170, 150, 120), 10, 1.4 + k * 0.4)
						shakeNear(g, 1.4, 170)
					end)
				end
				Fx.burst("dust", g + Vector3.new(0, 1, 0), Color3.fromRGB(170, 150, 120), 30, 2.6)
				Fx.flash(g + Vector3.new(0, 4, 0), GOLD, 120, 8, 0.5)
				Fx.sound("heavy", 1, 0.35, g)
				Fx.breakSound("boom", 1, 0.4, g)
				shakeNear(g, 3.5, 220)
				if opts.flash and near(g, 120) then
					opts.flash(GOLD, 0.25)
				end
				-- 팔이 문으로 돌아가고 문이 닫힌다
				task.delay(0.35, function()
					local r0 = os.clock()
					local c3: RBXScriptConnection
					c3 = RunService.Heartbeat:Connect(function()
						local u2 = math.clamp((os.clock() - r0) / 0.5, 0, 1)
						gplace(arm, CFrame.new(to:Lerp(from, u2 * u2)))
						if u2 >= 1 then
							c3:Disconnect()
							gfade(arm, 0.2)
						end
					end)
					task.delay(0.5, function()
						for _, p in ipairs(ring) do
							fadeOut(p, 0.4, { Size = p.Size * 0.3 })
						end
						holder:Destroy()
					end)
				end)
			end
		end)
	end)
	-- 왕관의 해가 그 자리로 떨어지고 모든 인장이 함께 터진다
	local sunAt = data.sunAt or 0.9
	task.delay(gate + fall + sunAt - 0.35, function()
		if not d or d.done or not d.sun or not d.sunCF then
			return
		end
		d.done = true
		local sun = d.sun
		local from = (d.sunCF :: CFrame).Position
		local s0 = os.clock()
		local c4: RBXScriptConnection
		c4 = RunService.Heartbeat:Connect(function()
			local u = math.clamp((os.clock() - s0) / 0.35, 0, 1)
			local pos = from:Lerp(g + Vector3.new(0, 4, 0), u * u)
			gplace(sun, CFrame.lookAt(pos, pos + Vector3.new(0, -1, 0.001)) * CFrame.Angles(math.rad(90), 0, 0))
			if u >= 1 then
				c4:Disconnect()
				gfade(sun, 0.3)
				goldBlast(at, data.finalRadius or 30)
				crownSpikes(g, (data.finalRadius or 30) * 0.6, 12, 14)
				for _, s in ipairs(d.seals) do
					if s.Parent then
						local p = s.Position
						s.Color = WHITE
						fadeOut(s, 0.4, { Size = s.Size * 1.6 })
						if s.Size.Y > 6 then
							local col = part(Vector3.new(2, 3, 3), GOLD, Enum.Material.Neon, 0.1, "cyl")
							col.CFrame = CFrame.new(p) * UP
							tween(col, 0.15, { Size = Vector3.new(30, 3, 3), CFrame = CFrame.new(p + Vector3.new(0, 15, 0)) * UP })
							task.delay(0.18, function()
								fadeOut(col, 0.35)
							end)
						end
					end
				end
			end
		end)
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	kingProcession = kingProcession,
	decreeOpen = decreeOpen,
	decreeSeals = decreeSeals,
	decreeFist = decreeFist,
}
function Royal.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil
end
function Royal.run(data: any)
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

return Royal
