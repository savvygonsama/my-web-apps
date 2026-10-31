-- 권왕 3.10판: 권왕신권의 오의 · 초 오의 (화면)
-- 패왕난무: 금빛 투기장과 금 기둥 여덟, 기둥마다 거대한 주먹이 한가운데를 내지르고 땅속 주먹이 올려친다
-- 천하제일권: 등 뒤에 하늘만 한 금빛 왕 (나의 모습)이 일어서서 한 방, 충격파 세 겹, 십자 빛기둥, 내려와 박히는 빛의 왕관
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
-- 공용: 왕관 쐐기, 금빛 폭발
------------------------------------------------------------------------
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
-- 큰 주먹 (붉은 소매에 금 팔찌). 기준은 주먹 가운데, 소매는 위(+Y)로 뻗는다. s배로 키운다
local function armGroup(s: number): Group
	local g: Group = { list = {} }
	local function add(p: BasePart, off: CFrame)
		p.Size *= s
		table.insert(g.list, { p = p, off = CFrame.new(off.Position * s) * off.Rotation })
	end
	add(part(Vector3.new(14, 12, 12), GOLD, Enum.Material.Metal, 0), CFrame.new())
	for k = 0, 3 do
		add(part(Vector3.new(3.8, 3.8, 3.8), GOLD_DEEP, Enum.Material.Metal, 0, "ball"), CFrame.new(-5.2 + k * 3.5, -6, -4.5))
	end
	add(part(Vector3.new(4, 8, 4), GOLD, Enum.Material.Metal), CFrame.new(7.5, 0, -2) * CFrame.Angles(0, 0, math.rad(-15)))
	add(part(Vector3.new(5, 15, 15), GOLD_DEEP, Enum.Material.Metal, 0, "cyl"), CFrame.new(0, 8, 0) * UP)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		add(part(Vector3.new(1.6, 1.6, 1.6), CRIMSON, Enum.Material.Neon, 0, "ball"), CFrame.new(math.cos(a) * 7.6, 8, math.sin(a) * 7.6))
	end
	add(part(Vector3.new(60, 16, 16), CRIMSON, Enum.Material.Fabric, 0, "cyl"), CFrame.new(0, 40, 0) * UP)
	for _, y in ipairs({ 12, 22 }) do
		add(part(Vector3.new(1.4, 17, 17), GOLD, Enum.Material.Metal, 0, "cyl"), CFrame.new(0, y, 0) * UP)
	end
	return g
end
-- 주먹이 dir 쪽을 향하게 (소매는 뒤로)
local function fistCF(pos: Vector3, dir: Vector3): CFrame
	return CFrame.lookAt(pos, pos + dir) * CFrame.Angles(math.rad(90), 0, 0)
end
-- 땅이 패이며 갈라지는 금빛 금
local function goldCracks(g: Vector3, n: number, len: number, life: number)
	for k = 1, n do
		local a = (k / n + math.random() * 0.08) * math.pi * 2
		local p = g + Vector3.new(0, 0.2, 0)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		for j = 1, 3 do
			local q = p + dir * (len / 3) * (0.7 + math.random() * 0.6)
			local seg = part(Vector3.new(0.5 / j + 0.2, 0.15, (q - p).Magnitude), j == 1 and PALE or GOLD, Enum.Material.Neon, 0)
			seg.CFrame = CFrame.lookAt((p + q) / 2, q)
			task.delay(life + math.random() * 0.3, function()
				fadeOut(seg, 0.4)
			end)
			p = q
			local turn = (math.random() - 0.5) * 0.9
			dir = Vector3.new(dir.X * math.cos(turn) - dir.Z * math.sin(turn), 0, dir.X * math.sin(turn) + dir.Z * math.cos(turn))
		end
	end
	-- 패인 자리의 바위 테두리
	for k = 0, 13 do
		local a = k / 14 * math.pi * 2 + math.random() * 0.2
		local p = g + Vector3.new(math.cos(a), 0, math.sin(a)) * len * 0.35
		local rock = part(Vector3.new(2.5, 1.6, 2) * (0.7 + math.random() * 0.6), Color3.fromRGB(120, 104, 86), Enum.Material.Slate, 0, "wedge")
		rock.CFrame = CFrame.lookAt(p, g) * CFrame.Angles(math.rad(-20), math.rad(180), 0)
		task.delay(life + 0.6 + math.random() * 0.4, function()
			fadeOut(rock, 0.5, { CFrame = rock.CFrame - Vector3.new(0, 1.5, 0) })
		end)
	end
end

------------------------------------------------------------------------
-- G 패왕난무: 발밑에 금빛 투기장, 둘레의 금 기둥 여덟. 기둥마다 거대한 주먹이 차례로 한가운데를 내지르고, 땅속 주먹이 올려친다
------------------------------------------------------------------------
local function kingArena(data: any)
	local at: Vector3 = data.at
	if not near(at, 260) then
		return
	end
	local R = data.radius or 22
	local rise = data.rise or 0.35
	local n = data.fists or 8
	local every = data.every or 0.12
	local upper = data.upper or 0.3
	local g = ground(at)
	local keep: { BasePart } = {}
	-- 투기장 바닥: 금 테, 붉은 안쪽, 관 무늬 (가운데 금 원)
	local floor = part(Vector3.new(0.2, 2, 2), CRIMSON_DARK, Enum.Material.Neon, 0.55, "cyl")
	floor.CFrame = CFrame.new(g + Vector3.new(0, 0.1, 0)) * UP
	tween(floor, rise, { Size = Vector3.new(0.2, R * 2, R * 2) })
	local rim = part(Vector3.new(0.3, 2, 2), GOLD, Enum.Material.Neon, 0.2, "cyl")
	rim.CFrame = CFrame.new(g + Vector3.new(0, 0.05, 0)) * UP
	tween(rim, rise, { Size = Vector3.new(0.3, R * 2 + 2, R * 2 + 2) })
	local mid = part(Vector3.new(0.25, 2, 2), GOLD, Enum.Material.Neon, 0.25, "cyl")
	mid.CFrame = CFrame.new(g + Vector3.new(0, 0.15, 0)) * UP
	tween(mid, rise, { Size = Vector3.new(0.25, R * 0.5, R * 0.5) })
	table.insert(keep, floor)
	table.insert(keep, rim)
	table.insert(keep, mid)
	Fx.sound("heavy", 0.7, 0.8, at)
	shakeNear(g, 1.2, 140)
	-- 금 기둥 여덟이 솟는다 (꼭대기에 붉은 보석)
	local pillars: { Vector3 } = {}
	for k = 1, n do
		local a = (k - 1) / n * math.pi * 2
		local p = g + Vector3.new(math.cos(a), 0, math.sin(a)) * R
		pillars[k] = p
		local h = 14
		local col = part(Vector3.new(h, 2.6, 2.6), GOLD_DEEP, Enum.Material.Metal, 0, "cyl")
		local cap = part(Vector3.new(1, 3.6, 3.6), GOLD, Enum.Material.Metal, 0, "cyl")
		local gem = part(Vector3.new(1.8, 1.8, 1.8), k % 2 == 0 and CRIMSON or PALE, Enum.Material.Neon, 0, "ball")
		col.CFrame = CFrame.new(p - Vector3.new(0, h / 2, 0)) * UP
		cap.CFrame = CFrame.new(p) * UP
		gem.CFrame = CFrame.new(p + Vector3.new(0, 0.8, 0))
		tween(col, rise, { CFrame = CFrame.new(p + Vector3.new(0, h / 2, 0)) * UP }, Enum.EasingStyle.Back)
		tween(cap, rise, { CFrame = CFrame.new(p + Vector3.new(0, h, 0)) * UP }, Enum.EasingStyle.Back)
		tween(gem, rise, { CFrame = CFrame.new(p + Vector3.new(0, h + 1.4, 0)) }, Enum.EasingStyle.Back)
		table.insert(keep, col)
		table.insert(keep, cap)
		table.insert(keep, gem)
		Fx.burst("dust", p, Color3.fromRGB(170, 150, 120), 4, 1.2)
	end
	-- 기둥마다 주먹이 한가운데로
	for k = 1, n do
		task.delay(rise + (k - 1) * every, function()
			local from = pillars[k] + Vector3.new(0, 5, 0)
			local to = g + Vector3.new(0, 3, 0)
			local dir = (to - from).Unit
			local arm = armGroup(0.32)
			local t0 = os.clock()
			local dur = math.max(0.08, every * 1.3)
			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function()
				local u = math.clamp((os.clock() - t0) / dur, 0, 1)
				gplace(arm, fistCF(from:Lerp(to - dir * 2, u * u), dir))
				if u >= 1 then
					conn:Disconnect()
					gfade(arm, 0.25)
					local hit = part(Vector3.new(2, 2, 2), PALE, Enum.Material.Neon, 0, "ball")
					hit.CFrame = CFrame.new(to)
					fadeOut(hit, 0.25, { Size = Vector3.new(9, 9, 9) })
					Fx.ring(g + Vector3.new(0, 0.4, 0), k % 2 == 0 and CRIMSON or GOLD, 2, 14, 0.3)
					Fx.burst("glitter", to, GOLD, 6, 1.2)
				end
			end)
			Fx.sound("hit", 0.55, 0.8 + k * 0.05, to)
			shakeNear(g, 0.6, 120)
		end)
	end
	-- 땅속에서 솟는 주먹이 올려친다
	local up = rise + n * every + upper
	task.delay(up - 0.15, function()
		goldCracks(g, 8, R * 0.5, 0.4)
		Fx.burst("dust", g, Color3.fromRGB(170, 150, 120), 12, 2)
	end)
	task.delay(up, function()
		local arm = armGroup(0.6)
		local from = g - Vector3.new(0, 10, 0)
		local to = g + Vector3.new(0, 8, 0)
		local base = CFrame.Angles(math.pi, 0, 0)
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local u = math.clamp((os.clock() - t0) / 0.14, 0, 1)
			gplace(arm, CFrame.new(from:Lerp(to, 1 - (1 - u) ^ 2)) * base)
			if u >= 1 then
				conn:Disconnect()
				task.delay(0.25, function()
					gfade(arm, 0.35)
				end)
			end
		end)
		goldBlast(at, R * 0.6)
		crownSpikes(g, R * 0.6, 10, 10)
		if opts.flash and near(g, R * 2) then
			opts.flash(GOLD, 0.2)
		end
		for _, q in ipairs(keep) do
			if q.Parent then
				fadeOut(q, 0.6)
			end
		end
	end)
	task.delay(up + 3, function()
		for _, q in ipairs(keep) do
			if q.Parent then
				q:Destroy()
			end
		end
	end)
end

------------------------------------------------------------------------
-- X 천하제일권: 등 뒤에 하늘만 한 금빛 왕 (나의 모습)이 일어선다. 오른팔을 당겼다가 가장 강한 적에게 한 방.
-- 충격파 세 겹, 십자로 내달리는 빛기둥 넷, 하늘에서 내려와 박히는 빛의 왕관
------------------------------------------------------------------------
type Avatar = { body: Group, arm: Group?, done: boolean }
local avatars: { [number]: Avatar } = {}
local function avatarEnd(av: Avatar)
	if av.done then
		return
	end
	av.done = true
	gfade(av.body, 0.8)
	local arm = av.arm
	if arm then
		gfade(arm, 0.5)
	end
end
local function kingAvatar(data: any)
	local at: Vector3 = data.at
	local to: Vector3 = data.to
	if not near(at, 400) then
		return
	end
	local cut = data.cut or 1.5
	local rise = data.rise or 0.8
	local charge = data.charge or 0.6
	local punch = data.punch or 0.3
	local g = ground(at)
	local S = 9
	local dir = flat(to - at)
	local right = Vector3.new(-dir.Z, 0, dir.X)
	-- 왕: 나의 몸을 금빛 유리로 아홉 배, 머리 위에 관, 등에 붉은 망토
	local body = kingShade(data.m, 0.35)
	for _, it in ipairs(body.list) do
		it.p.Size *= S
		it.off = CFrame.new(it.off.Position * S) * it.off.Rotation
		it.p.Transparency = 1
	end
	local av: Avatar = { body = body, arm = nil, done = false }
	avatars[data.id] = av
	local base = g - dir * 16 - right * 6
	local stand = base + Vector3.new(0, 3 * S, 0)
	local face = CFrame.lookAt(stand, stand + dir)
	-- 등 뒤의 빛기둥과 금빛 바람
	local glow = part(Vector3.new(120, 26, 26), PALE, Enum.Material.Neon, 1, "cyl")
	glow.CFrame = CFrame.new(base + Vector3.new(0, 60, 0)) * UP
	tween(glow, cut * 0.6, { Transparency = 0.82 })
	Fx.ring(base + Vector3.new(0, 0.4, 0), GOLD, 4, 60, 1)
	Fx.sound("heavy", 0.8, 0.45, at)
	-- 땅에서 솟아 일어선다 (컷씬 동안부터)
	local t0 = os.clock()
	local from = cut * 0.25
	local riseT = cut * 0.75 + rise
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if av.done then
			conn:Disconnect()
			return
		end
		local t = os.clock() - t0
		local u = math.clamp((t - from) / riseT, 0, 1)
		local e = 1 - (1 - u) ^ 3
		local bob = math.sin(t * 2) * 0.6
		gplace(body, face - Vector3.new(0, (1 - e) * 4 * S, 0) + Vector3.new(0, bob, 0))
	end)
	task.delay(from, function()
		for _, it in ipairs(body.list) do
			if it.p.Parent then
				tween(it.p, riseT * 0.8, { Transparency = it.p.Material == Enum.Material.Glass and 0.35 or 0.1 })
			end
		end
		shakeNear(g, 1.5, 200)
		Fx.burst("dust", base, Color3.fromRGB(170, 150, 120), 20, 3)
	end)
	task.delay(cut, function()
		Fx.sound("heavy", 1, 0.35, at)
		for k = 0, 2 do
			task.delay(k * 0.15, function()
				Fx.ring(base + Vector3.new(0, 0.5 + k * 3, 0), k == 1 and CRIMSON or GOLD, 3, 50 + k * 16, 0.8)
			end)
		end
	end)
	-- 오른팔을 당긴다: 어깨 뒤에 거대한 주먹, 금빛이 모여든다
	local shoulder = stand + right * 1.6 * S + Vector3.new(0, 1.4 * S, 0)
	local goal = to + Vector3.new(0, 2, 0)
	local pd = (goal - shoulder).Unit
	local back = shoulder - pd * 10 + Vector3.new(0, 4, 0)
	task.delay(cut + rise, function()
		if av.done then
			return
		end
		local arm = armGroup(1)
		av.arm = arm
		gplace(arm, fistCF(back, pd))
		for _, it in ipairs(arm.list) do
			local a = it.p.Transparency
			it.p.Transparency = 1
			tween(it.p, charge * 0.5, { Transparency = a })
		end
		for k = 0, 9 do
			task.delay(k * charge / 10, function()
				local o = back + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit * 22
				local mote = part(Vector3.new(1.2, 1.2, 1.2), k % 3 == 0 and PALE or GOLD, Enum.Material.Neon, 0, "ball")
				mote.CFrame = CFrame.new(o)
				fadeOut(mote, charge * 0.4, { CFrame = CFrame.new(back), Size = Vector3.new(0.3, 0.3, 0.3) })
			end)
		end
		Fx.sound("ping", 0.9, 0.4, at)
		shakeNear(g, 0.8, 200)
	end)
	-- 한 방
	task.delay(cut + rise + charge, function()
		local arm = av.arm
		if av.done or not arm then
			return
		end
		local st = os.clock()
		local last = back
		local c2: RBXScriptConnection
		c2 = RunService.Heartbeat:Connect(function()
			local u = math.clamp((os.clock() - st) / punch, 0, 1)
			local p = back:Lerp(goal - pd * 6, u ^ 2.2)
			gplace(arm, fistCF(p, pd))
			if (p - last).Magnitude > 4 then
				local tr = part(Vector3.new(8, 8, (p - last).Magnitude), GOLD, Enum.Material.Neon, 0.5)
				tr.CFrame = CFrame.lookAt((p + last) / 2, p)
				fadeOut(tr, 0.3, { Size = Vector3.new(0.5, 0.5, tr.Size.Z) })
				last = p
			end
			if u >= 1 then
				c2:Disconnect()
			end
		end)
		Fx.sound("swing", 1, 0.4, at)
	end)
	task.delay(cut + rise + charge + punch + 0.5, function()
		local arm = av.arm
		if arm and not av.done then
			gfade(arm, 0.4)
			av.arm = nil
		end
	end)
	task.delay(cut + rise + charge + punch + 4, function()
		avatarEnd(av)
		fadeOut(glow, 0.6)
		avatars[data.id] = nil
	end)
end
local function kingImpact(data: any)
	local at: Vector3 = data.at
	if not near(at, 400) then
		return
	end
	local g = ground(at)
	local R = data.radius or 20
	local rings = data.rings or 3
	local ringEvery = data.ringEvery or 0.2
	local cross = data.cross or 0.6
	local len = data.crossLen or 40
	local crownAt = data.crownAt or 0.4
	local FR = data.finalRadius or 28
	local dir = flat(data.dir or Vector3.new(0, 0, -1))
	local right = Vector3.new(-dir.Z, 0, dir.X)
	-- 맞은 자리: 하얀 빛, 금빛 폭발, 패인 땅
	goldBlast(at, R)
	goldCracks(g, 12, R * 1.4, 1.6)
	Fx.flash(g + Vector3.new(0, 6, 0), WHITE, 160, 10, 0.6)
	Fx.breakSound("boom", 1, 0.4, g)
	shakeNear(g, 3.4, 240)
	if opts.flash and near(g, R * 3) then
		opts.flash(PALE, 0.3)
	end
	-- 충격파 세 겹
	for k = 1, rings do
		task.delay(k * ringEvery, function()
			local r1 = R * (0.5 + k * 0.6)
			Fx.ring(g + Vector3.new(0, 0.6, 0), k % 2 == 0 and CRIMSON or GOLD, 5, r1 * 2, 0.5)
			Fx.ring(g + Vector3.new(0, 3, 0), PALE, 2, r1 * 1.8, 0.4)
			Fx.burst("dust", g, Color3.fromRGB(170, 150, 120), 10, 2 + k * 0.4)
			Fx.sound("heavy", 0.7, 0.6 + k * 0.1, g)
			shakeNear(g, 1.4, 200)
		end)
	end
	-- 십자로 내달리는 빛기둥 넷
	local steps = 6
	for _, d in ipairs({ dir, right, -dir, -right }) do
		local streak = part(Vector3.new(7, 0.3, 1), PALE, Enum.Material.Neon, 0.1)
		streak.CFrame = CFrame.lookAt(g + Vector3.new(0, 0.3, 0), g + Vector3.new(0, 0.3, 0) + d)
		for k = 1, steps do
			task.delay(0.2 + (k - 1) * cross / steps, function()
				local tip = g + d * (len * k / steps)
				local l = len * k / steps
				if streak.Parent then
					local mid = g + d * (l / 2) + Vector3.new(0, 0.3, 0)
					tween(streak, cross / steps, { Size = Vector3.new(7, 0.3, l), CFrame = CFrame.lookAt(mid, mid + d) })
				end
				local col = part(Vector3.new(4, 6, 6), k == steps and WHITE or GOLD, Enum.Material.Neon, 0.05, "cyl")
				col.CFrame = CFrame.new(tip) * UP
				tween(col, 0.15, { Size = Vector3.new(50, 6, 6), CFrame = CFrame.new(tip + Vector3.new(0, 25, 0)) * UP })
				task.delay(0.18, function()
					fadeOut(col, 0.35, { Size = Vector3.new(50, 0.5, 0.5) })
				end)
				Fx.burst("glitter", tip, GOLD, 4, 1.4)
			end)
		end
		task.delay(0.2 + cross + crownAt + 0.3, function()
			fadeOut(streak, 0.5)
		end)
	end
	Fx.sound("ping", 0.8, 0.5, g)
	-- 빛의 왕관이 하늘에서 내려와 박힌다
	local crown: Group = { list = {} }
	crownInto(crown, CFrame.new(), FR * 0.55, 9, 10)
	for _, it in ipairs(crown.list) do
		it.p.Material = Enum.Material.Neon
		it.p.Transparency = 1
		tween(it.p, 0.3, { Transparency = 0.15 })
	end
	local high = g + Vector3.new(0, 70, 0)
	local land = g + Vector3.new(0, 1, 0)
	local t0 = os.clock()
	local fall0 = 0.2 + cross * 0.4
	local fallT = 0.2 + cross + crownAt - fall0
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp((t - fall0) / fallT, 0, 1)
		gplace(crown, CFrame.new(high:Lerp(land, u ^ 2.5)) * CFrame.Angles(0, t * 1.2, 0))
		if u >= 1 then
			conn:Disconnect()
		end
	end)
	task.delay(0.2 + cross + crownAt, function()
		gfade(crown, 0.5)
		goldBlast(at, FR)
		crownSpikes(g, FR, 14, 18)
		for k = 0, 3 do
			task.delay(k * 0.08, function()
				Fx.ring(g + Vector3.new(0, 0.6 + k * 2, 0), k % 2 == 1 and CRIMSON or GOLD, 6, FR * 2.6 + k * 14, 0.8)
			end)
		end
		Fx.flash(g + Vector3.new(0, 8, 0), WHITE, 200, 12, 0.8)
		Fx.sound("heavy", 1, 0.3, g)
		Fx.breakSound("boom", 1, 0.35, g)
		shakeNear(g, 4, 260)
		if opts.flash and near(g, FR * 3) then
			opts.flash(WHITE, 0.4)
		end
		local av = avatars[data.id]
		if av then
			avatarEnd(av)
		end
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	kingArena = kingArena,
	kingAvatar = kingAvatar,
	kingImpact = kingImpact,
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
