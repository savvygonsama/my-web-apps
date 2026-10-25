-- 권왕 2.2판: 각성 권법 아홉의 새 E·R, 진 열화 화산천붕 · 진 창해 고래강림, 초·벽력신권의 뇌신낙 · 천뢰구 · 심판의 벼락 (화면)
-- 기술마다 생김새가 겹치지 않게: 바늘, 피의 손, 용의 울음, 용머리 장력, 뇌인, 뇌전포, 금빛 종, 금강저, 그림자 분신,
-- 미끄러지는 그림자, 감아 도는 물방울, 간헐천, 불의 바퀴, 불의 고리, 화산, 물방울 감옥, 물의 창, 고래, 떠도는 회오리,
-- 하늘의 바람, 벼락이 되어 떨어지기, 구슬 번개, 조준 고리, (2.6판) 천둥별과 작은 별 여섯
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Awake3 = {}
local player = Players.LocalPlayer

local WHITE = Color3.new(1, 1, 1)
local folder = Instance.new("Folder")
folder.Name = "KwonAwake3"
folder.Parent = workspace

local opts: any = {}
function Awake3.init(o: any)
	opts = o or {}
end

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
local function part(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, shape: string?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Neon
	p.Transparency = alpha or 0
	if shape == "ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	elseif shape == "wedge" then
		local w = Instance.new("WedgePart")
		w.Anchored = true
		w.CanCollide = false
		w.CanQuery = false
		w.CanTouch = false
		w.CastShadow = false
		w.Size = size
		w.Color = color
		w.Material = material or Enum.Material.Neon
		w.Transparency = alpha or 0
		w.Parent = folder
		p:Destroy()
		return w :: any
	end
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
local function ground(at: Vector3): Vector3
	return Vector3.new(at.X, at.Y - 2.7, at.Z)
end
local function disc(at: Vector3, d: number, color: Color3, alpha: number, mat: Enum.Material?): Part
	local p = part(Vector3.new(0.2, d, d), color, mat or Enum.Material.Neon, alpha, "cyl")
	p.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	return p
end
local function column(base: Vector3, height: number, width: number, color: Color3, alpha: number?, mat: Enum.Material?): Part
	local c = part(Vector3.new(height, width, width), color, mat or Enum.Material.Neon, alpha or 0.1, "cyl")
	c.CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	return c
end
local function colors(id: any): (Color3, Color3)
	local st = type(id) == "string" and Config.STYLE_BY_ID[id] or nil
	if st then
		return st.color, st.color2
	end
	return Color3.fromRGB(255, 200, 90), WHITE
end
local function shakeNear(pos: Vector3, amount: number, range: number)
	if opts.shake and near(pos, range) then
		opts.shake(amount)
	end
end
-- 땅에 닿는 곳의 공통 마무리 (고리 둘과 불티)
local function impact(at: Vector3, radius: number, c: Color3, c2: Color3, k: number?)
	local s = k or 1
	local g = ground(at)
	Fx.ring(g + Vector3.new(0, 0.3, 0), c, 2, radius * 2.2, 0.5)
	task.delay(0.06, function()
		Fx.ring(g + Vector3.new(0, 0.3, 0), c2, 2, radius * 1.6, 0.4)
	end)
	Fx.burst("spark", at, c, math.floor(16 * s), 1.3 * s)
	shakeNear(at, 0.4 * s, 60)
end
-- 한 점에서 다른 점까지 늘어선 막대 (방향을 따라)
local function beam(a: Vector3, b: Vector3, w: number, color: Color3, alpha: number?, mat: Enum.Material?): Part
	local len = math.max(0.1, (b - a).Magnitude)
	local p = part(Vector3.new(w, w, len), color, mat, alpha)
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
	return p
end

------------------------------------------------------------------------
-- 진 혈마신수: 혈침 · 혈마수인
------------------------------------------------------------------------
local function needleShot(data: any)
	local r = rootOf(data.m)
	if not r or not near(r.Position, 200) then
		return
	end
	local c, c2 = colors(data.style)
	local delay = data.delay or 0.2
	for i, m in ipairs(data.targets or {}) do
		local tr = rootOf(m)
		if tr then
			task.delay(delay + (i - 1) * 0.04, function()
				local from = r.Position + Vector3.new(0, 1.5, 0)
				local to = tr.Position
				local n = part(Vector3.new(0.25, 0.25, 3), c, Enum.Material.Neon, 0)
				n.CFrame = CFrame.lookAt(from, to)
				tween(n, 0.12, { CFrame = CFrame.lookAt(to, to + (to - from).Unit) }, Enum.EasingStyle.Linear)
				-- 꽂힌 바늘이 몸에 붙어 맥박친다
				task.delay(0.12, function()
					if not tr.Parent then
						n:Destroy()
						return
					end
					local off = tr.CFrame:ToObjectSpace(n.CFrame)
					local glow = part(Vector3.new(1.2, 1.2, 1.2), c2, Enum.Material.Neon, 0.5, "ball")
					local t0 = os.clock()
					local conn: RBXScriptConnection
					conn = RunService.Heartbeat:Connect(function()
						if not tr.Parent or os.clock() - t0 > (data.mark or 1) then
							conn:Disconnect()
							n:Destroy()
							glow:Destroy()
							return
						end
						n.CFrame = tr.CFrame * off
						local k = 1 + math.sin((os.clock() - t0) * 18) * 0.35
						glow.Size = Vector3.new(k, k, k)
						glow.CFrame = n.CFrame
					end)
					Fx.burst("spark", to, c, 6, 0.6)
				end)
			end)
		end
	end
	Fx.sound("swing", 0.6, 1.4, r.Position)
end
local function needleBurst(data: any)
	local c, c2 = colors(data.style)
	for _, at in ipairs(data.spots or {}) do
		if near(at, 200) then
			for k = 1, 6 do
				local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit
				local s = beam(at, at + dir * 4, 0.3, k % 2 == 0 and c2 or c, 0)
				fadeOut(s, 0.3, { Size = Vector3.new(0.1, 0.1, 7) })
			end
			local b = part(Vector3.new(1, 1, 1), c, Enum.Material.Neon, 0.2, "ball")
			b.CFrame = CFrame.new(at)
			fadeOut(b, 0.35, { Size = Vector3.new(1, 1, 1) * (data.radius or 5) * 2 })
			impact(at, data.radius or 5, c, c2, 0.8)
		end
	end
	local first = (data.spots or {})[1]
	if first then
		Fx.sound("hit", 0.8, 0.6, first)
	end
end
-- 피의 손: 손바닥과 다섯 손가락 (손가락이 오므라들며 쥔다)
type Hand = { parts: { { p: BasePart, f: number, j: number } }, base: CFrame, size: number, curl: number }
local hands: { [string]: Hand } = {}
local function keyOf(v: Vector3): string
	return string.format("%d_%d_%d", math.floor(v.X), math.floor(v.Y), math.floor(v.Z))
end
local function placeHand(h: Hand)
	local s = h.size
	for _, e in ipairs(h.parts) do
		if e.f == 0 then
			e.p.CFrame = h.base * CFrame.new(0, s * 0.5, 0)
		else
			-- 손가락 e.f (1~5)의 마디 e.j (1~3): 손바닥 둘레에 둥글게 서서 안쪽으로 굽는다
			local ang = (e.f - 1) / 5 * math.pi * 2
			local root = h.base * CFrame.Angles(0, ang, 0) * CFrame.new(0, s * 1.0, -s * 0.55)
			local cf = root
			for j = 1, e.j do
				cf = cf * CFrame.Angles(math.rad(h.curl * (j == 1 and 0.6 or 1)), 0, 0) * CFrame.new(0, s * 0.5, 0)
			end
			e.p.CFrame = cf * CFrame.new(0, -s * 0.25, 0)
		end
	end
end
local function gripRise(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 10
	local g = ground(at)
	local s = R * 0.35
	local h: Hand = { parts = {}, base = CFrame.new(g - Vector3.new(0, s * 3, 0)), size = s, curl = -20 }
	local palm = part(Vector3.new(s, s * 2.2, s * 2.2), Color3.fromRGB(120, 0, 15), Enum.Material.SmoothPlastic, 0.1, "cyl")
	table.insert(h.parts, { p = palm, f = 0, j = 0 })
	for fi = 1, 5 do
		for j = 1, 3 do
			local w = s * (0.55 - j * 0.08)
			local p = part(Vector3.new(w, s * 0.55, w), j == 3 and c2 or Color3.fromRGB(150, 5, 25), j == 3 and Enum.Material.Neon or Enum.Material.SmoothPlastic, 0.05)
			table.insert(h.parts, { p = p, f = fi, j = j })
		end
	end
	local key = keyOf(at)
	hands[key] = h
	local pool = disc(g + Vector3.new(0, 0.1, 0), 1, Color3.fromRGB(120, 0, 15), 0.2, Enum.Material.Glass)
	tween(pool, 0.3, { Size = Vector3.new(0.2, R * 2.3, R * 2.3) })
	local t0 = os.clock()
	local delay = data.delay or 0.35
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if not hands[key] or t > (data.dur or 2) + 1 then
			conn:Disconnect()
			return
		end
		local rise = math.clamp(t / delay, 0, 1)
		rise = 1 - (1 - rise) ^ 3
		h.base = CFrame.new(g + Vector3.new(0, -s * 3 * (1 - rise), 0))
		placeHand(h)
		palm.CFrame = h.base * CFrame.new(0, s * 0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	end)
	task.delay(delay, function()
		h.curl = 55
		Fx.burst("spark", at, c, 20, 1.5)
		Fx.sound("heavy", 0.8, 0.7, at)
	end)
	task.delay((data.dur or 2), function()
		hands[key] = nil
		for _, e in ipairs(h.parts) do
			fadeOut(e.p, 0.4, { CFrame = e.p.CFrame * CFrame.new(0, -s * 2, 0) })
		end
		fadeOut(pool, 0.5)
	end)
end
local function gripSqueeze(data: any)
	local h = hands[keyOf(data.at)]
	local c, c2 = colors(data.style)
	if h then
		h.curl = 75
		task.delay(0.12, function()
			h.curl = 55
		end)
	end
	if near(data.at, 200) then
		Fx.burst("spark", data.at + Vector3.new(0, 2, 0), c, 14, 1.2)
		Fx.ring(ground(data.at) + Vector3.new(0, 0.3, 0), c2, 2, (data.radius or 10) * 1.6, 0.3)
		Fx.sound("hit", 0.7, 0.6 + (data.i or 1) * 0.08, data.at)
	end
end
local function gripSlam(data: any)
	local key = keyOf(data.at)
	local h = hands[key]
	local c, c2 = colors(data.style)
	if h then
		h.curl = 90
		-- 손이 쥔 채로 위로 솟았다가 땅에 내리꽂힌다
		local g = ground(data.at)
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local t = os.clock() - t0
			if not hands[key] or t > 0.4 then
				conn:Disconnect()
				return
			end
			local y = t < 0.2 and (t / 0.2) * h.size * 2 or (1 - (t - 0.2) / 0.2) * h.size * 2
			h.base = CFrame.new(g + Vector3.new(0, y, 0))
		end)
	end
	task.delay(0.4, function()
		if near(data.at, 200) then
			impact(data.at, data.radius or 10, c, c2, 1.6)
			Fx.debris(ground(data.at), 10, 30, Color3.fromRGB(90, 20, 25))
			Fx.sound("heavy", 1, 0.5, data.at)
			shakeNear(data.at, 1.2, 80)
		end
	end)
end

------------------------------------------------------------------------
-- 진 천룡파천장: 용음 · 항룡장
------------------------------------------------------------------------
local function dragonRoar(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local c, c2 = colors(data.style)
	local dir: Vector3 = data.dir or Vector3.new(0, 0, -1)
	local range = data.range or 22
	local half = math.rad((data.angle or 80) / 2)
	-- 부채꼴로 겹겹이 퍼지는 금빛 음파 (호 조각)
	for wave = 0, 3 do
		task.delay(0.18 + wave * 0.07, function()
			local segs = 9
			for k = 0, segs do
				local a = -half + (2 * half) * k / segs
				local d = (CFrame.Angles(0, a, 0) * CFrame.new(dir)).Position
				local p0 = at + d * 2
				local p1 = at + d * range
				local arc = part(Vector3.new(range * 0.18, 0.3, 1.2), wave % 2 == 0 and c or c2, Enum.Material.Neon, 0.2)
				arc.CFrame = CFrame.lookAt(p0, p0 + d) * CFrame.Angles(0, math.rad(90), 0)
				tween(arc, 0.35, { CFrame = CFrame.lookAt(p1, p1 + d) * CFrame.Angles(0, math.rad(90), 0), Size = Vector3.new(range * 0.32, 0.2, 2.5) }, Enum.EasingStyle.Quad)
				task.delay(0.25, function()
					fadeOut(arc, 0.15)
				end)
			end
		end)
	end
	-- 입 앞에 금룡의 머리 그림자가 잠깐 뜬다
	local head = part(Vector3.new(4, 3, 5), c, Enum.Material.Neon, 0.35, "wedge")
	head.CFrame = CFrame.lookAt(at + dir * 4 + Vector3.new(0, 2, 0), at + dir * 10 + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(180), 0)
	fadeOut(head, 0.5, { Size = Vector3.new(7, 5, 8) })
	Fx.flash(at + dir * 4, c, 40, 4, 0.4)
	Fx.sound("deflect", 1, 0.4, at)
	shakeNear(at, 0.8, 60)
end
local function palmWave(data: any)
	local from: Vector3 = data.from
	if not near(from, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local dir: Vector3 = data.dir or Vector3.new(0, 0, -1)
	local len = data.length or 34
	local w = data.width or 5
	task.delay(data.delay or 0.2, function()
		-- 용머리 (쐐기 둘 + 뿔 둘 + 눈)와 뒤로 늘어지는 금빛 장력
		local head = Instance.new("Model")
		head.Parent = folder
		local jawTop = part(Vector3.new(w * 1.2, w * 0.5, w * 1.4), c, Enum.Material.Neon, 0.1, "wedge")
		local jawBot = part(Vector3.new(w * 1.2, w * 0.4, w * 1.2), c2, Enum.Material.Neon, 0.2, "wedge")
		local horns = { part(Vector3.new(0.4, 0.4, w * 0.9), c2, Enum.Material.Neon, 0), part(Vector3.new(0.4, 0.4, w * 0.9), c2, Enum.Material.Neon, 0) }
		local trail = part(Vector3.new(w * 0.9, w * 0.5, 1), c, Enum.Material.Neon, 0.45)
		local t0 = os.clock()
		local time = data.time or 0.5
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local t = math.clamp((os.clock() - t0) / time, 0, 1)
			local pos = from + dir * (len * t) + Vector3.new(0, 1, 0)
			local cf = CFrame.lookAt(pos, pos + dir)
			jawTop.CFrame = cf * CFrame.new(0, w * 0.25, 0) * CFrame.Angles(0, math.rad(180), 0)
			jawBot.CFrame = cf * CFrame.new(0, -w * 0.2, 0) * CFrame.Angles(0, math.rad(180), math.rad(180))
			horns[1].CFrame = cf * CFrame.new(w * 0.35, w * 0.55, w * 0.5) * CFrame.Angles(math.rad(25), 0, 0)
			horns[2].CFrame = cf * CFrame.new(-w * 0.35, w * 0.55, w * 0.5) * CFrame.Angles(math.rad(25), 0, 0)
			local back = from + Vector3.new(0, 1, 0)
			trail.Size = Vector3.new(w * 0.9, w * 0.5, math.max(1, (pos - back).Magnitude))
			trail.CFrame = CFrame.lookAt((pos + back) / 2, pos)
			if t >= 1 then
				conn:Disconnect()
				for _, p in ipairs({ jawTop, jawBot, horns[1], horns[2] }) do
					fadeOut(p, 0.25)
				end
				fadeOut(trail, 0.4, { Size = Vector3.new(0.2, 0.2, trail.Size.Z) })
				head:Destroy()
			end
		end)
		Fx.sound("swing", 1, 0.6, from)
	end)
end
local function palmBurst(data: any)
	if near(data.at, 200) then
		local c, c2 = colors(data.style)
		local col = column(ground(data.at), 26, (data.radius or 10) * 0.8, c, 0.2)
		fadeOut(col, 0.5, { Size = Vector3.new(34, 0.5, 0.5) })
		impact(data.at, data.radius or 10, c, c2, 1.2)
		Fx.sound("heavy", 0.8, 0.8, data.at)
	end
end

------------------------------------------------------------------------
-- 진 벽력신권: 뇌인진 · 섬뢰포
------------------------------------------------------------------------
local function sigilsPlace(data: any)
	local c, c2 = colors(data.style)
	for _, at in ipairs(data.spots or {}) do
		if near(at, 200) then
			local g = ground(at) + Vector3.new(0, 0.15, 0)
			local r = (data.radius or 4) * 2
			-- 뇌인: 겹친 네모 둘 (돌아간다) + 가운데 번개 꼴
			local a = part(Vector3.new(r, 0.15, r), c, Enum.Material.Neon, 0.35)
			local b = part(Vector3.new(r * 0.75, 0.16, r * 0.75), c2, Enum.Material.Neon, 0.4)
			local core = part(Vector3.new(0.5, 3, 0.5), c2, Enum.Material.Neon, 0.1)
			core.CFrame = CFrame.new(g + Vector3.new(0, 1.5, 0))
			local t0 = os.clock()
			local dur = data.dur or 2.8
			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function()
				local t = os.clock() - t0
				if t > dur then
					conn:Disconnect()
					fadeOut(a, 0.2)
					fadeOut(b, 0.2)
					fadeOut(core, 0.2)
					return
				end
				a.CFrame = CFrame.new(g) * CFrame.Angles(0, t * 2, 0)
				b.CFrame = CFrame.new(g + Vector3.new(0, 0.02, 0)) * CFrame.Angles(0, -t * 3 + math.rad(45), 0)
				core.Transparency = 0.1 + math.abs(math.sin(t * 10)) * 0.5
			end)
			Fx.burst("spark", g + Vector3.new(0, 1, 0), c, 8, 0.8)
		end
	end
	local first = (data.spots or {})[1]
	if first then
		Fx.sound("deflect", 0.7, 1.4, first)
	end
end
local function sigilBolt(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local c, c2 = colors(data.style)
	local top = at + Vector3.new(math.random(-3, 3), 45, math.random(-3, 3))
	Fx.lightning(top, ground(at), c2, data.big and 1.2 or 0.7)
	Fx.lightning(top + Vector3.new(2, 0, 0), ground(at), c, 0.5)
	impact(at, data.radius or 4, c, c2, data.big and 1.3 or 0.8)
	Fx.flash(at, c, 30, 4, 0.25)
	Fx.sound("hit", 0.7, 1.3, at)
end
local function railCharge(data: any)
	local r = rootOf(data.m)
	if not r or not near(r.Position, 200) then
		return
	end
	local c, c2 = colors(data.style)
	local time = data.time or 0.4
	-- 앞으로 내민 주먹에 번개가 빨려 든다
	local orb = part(Vector3.new(0.5, 0.5, 0.5), c2, Enum.Material.Neon, 0, "ball")
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > time or not r.Parent then
			conn:Disconnect()
			orb:Destroy()
			return
		end
		local at = r.Position + flat(r.CFrame.LookVector) * 2.5 + Vector3.new(0, 0.6, 0)
		local k = 0.5 + 2.2 * (t / time)
		orb.Size = Vector3.new(k, k, k)
		orb.CFrame = CFrame.new(at)
		if math.random() < 0.5 then
			local d = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit * 5
			Fx.lightning(at + d, at, c, 0.25)
		end
	end)
	Fx.sound("deflect", 0.6, 1.8, r.Position)
end
local function railFire(data: any)
	local a: Vector3 = data.from
	local b: Vector3 = data.to
	if not near(a, 240) then
		return
	end
	local c, c2 = colors(data.style)
	local w = (data.width or 3) * 2
	local core = beam(a + Vector3.new(0, 0.6, 0), b + Vector3.new(0, 0.6, 0), w * 0.35, WHITE, 0)
	local glow = beam(a + Vector3.new(0, 0.6, 0), b + Vector3.new(0, 0.6, 0), w, c, 0.35)
	fadeOut(core, 0.25, { Size = Vector3.new(0.1, 0.1, core.Size.Z) })
	fadeOut(glow, 0.45, { Size = Vector3.new(w * 1.6, w * 1.6, glow.Size.Z) })
	-- 땅에 남은 지지직거리는 줄
	local scar = beam(ground(a) + Vector3.new(0, 0.12, 0), ground(b) + Vector3.new(0, 0.12, 0), 0.2, c2, 0.2)
	scar.Size = Vector3.new(w * 0.5, 0.2, scar.Size.Z)
	local dur = data.dur or 1.2
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if os.clock() - t0 > dur then
			conn:Disconnect()
			fadeOut(scar, 0.3)
			return
		end
		if math.random() < 0.35 then
			local u = math.random()
			local p = a:Lerp(b, u)
			Fx.lightning(p + Vector3.new(0, 3, 0), ground(p), c, 0.2)
		end
	end)
	for k = 0, 4 do
		task.delay(k * 0.03, function()
			Fx.ring(a:Lerp(b, k / 4), c2, 1, w * 2, 0.3, (b - a).Unit)
		end)
	end
	Fx.flash(a, c, 50, 6, 0.3)
	Fx.breakSound("boom", 0.7, 1.4, a)
	shakeNear(a, 0.9, 80)
end

------------------------------------------------------------------------
-- 진 금강불괴신공: 금강종 · 항마저
------------------------------------------------------------------------
local bells: { [Instance]: { BasePart } } = {}
local function bellDrop(data: any)
	local m = data.m
	local r = rootOf(m)
	if not r or not near(r.Position, 200) then
		return
	end
	local c, c2 = colors(data.style)
	local g = ground(r.Position)
	-- 종: 몸통 (위로 좁아지는 원기둥 셋) + 입술 고리 + 꼭지
	local list: { BasePart } = {}
	local shapes = { { 7.6, 1.2, 0 }, { 7.0, 3.2, 1.6 }, { 6.0, 2.6, 4.4 }, { 4.6, 1.6, 6.4 }, { 2.0, 1.0, 7.6 } }
	for i, sh in ipairs(shapes) do
		local p = part(Vector3.new(sh[2], sh[1], sh[1]), i == 1 and c2 or c, i == 1 and Enum.Material.Neon or Enum.Material.Metal, i == 1 and 0.1 or 0.25, "cyl")
		table.insert(list, p)
	end
	bells[m] = list
	local t0 = os.clock()
	local drop = data.delay or 0.35
	local dur = data.dur or 1.4
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > dur or not r.Parent then
			conn:Disconnect()
			bells[m] = nil
			for _, p in ipairs(list) do
				fadeOut(p, 0.35, { CFrame = p.CFrame * CFrame.new(-6, 0, 0) })
			end
			return
		end
		local k = math.clamp(t / drop, 0, 1)
		local y = 30 * (1 - k * k)
		local base = ground(r.Position) + Vector3.new(0, y, 0)
		for i, sh in ipairs(shapes) do
			list[i].CFrame = CFrame.new(base + Vector3.new(0, sh[3] + sh[2] / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		end
	end)
	task.delay(drop, function()
		Fx.debris(g, 8, 20, Color3.fromRGB(160, 140, 90))
		Fx.sound("heavy", 1, 0.6, g)
	end)
end
local function bellRing(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 10
	local g = ground(at)
	for k = 0, (data.last and 3 or 1) do
		task.delay(k * 0.06, function()
			Fx.ring(g + Vector3.new(0, 0.4 + k * 1.5, 0), k % 2 == 0 and c or c2, 2, R * 2.4 + k * 4, 0.45)
		end)
	end
	Fx.flash(at + Vector3.new(0, 3, 0), c, 40, data.last and 6 or 3, 0.35)
	Fx.sound("deflect", 1, data.last and 0.35 or 0.5, at)
	shakeNear(at, data.last and 1.2 or 0.5, 70)
end
local function vajraThrow(data: any)
	local r = rootOf(data.m)
	local from: Vector3 = data.from
	if not near(from, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local dir: Vector3 = data.dir or Vector3.new(0, 0, -1)
	local dist = data.dist or 26
	local time = data.time or 0.45
	task.delay(data.delay or 0.25, function()
		-- 금강저: 가운데 손잡이 + 양 끝의 갈퀴 (빙빙 돈다)
		local grip = part(Vector3.new(0.7, 3.6, 0.7), c, Enum.Material.Metal, 0, "cyl")
		local prongs: { BasePart } = {}
		for _ = 1, 6 do
			table.insert(prongs, part(Vector3.new(0.35, 1.8, 0.35), c2, Enum.Material.Neon, 0))
		end
		local t0 = os.clock()
		local tip = from + dir * dist
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local t = os.clock() - t0
			local pos
			if t <= time then
				pos = from + dir * (dist * (t / time))
			else
				local back = (r and r.Parent) and r.Position or from
				pos = tip:Lerp(back, math.clamp((t - time) / time, 0, 1))
			end
			pos += Vector3.new(0, 1.2, 0)
			local spin = CFrame.new(pos) * CFrame.Angles(0, t * 30, math.rad(90))
			grip.CFrame = spin
			local i = 0
			for _, sgn in ipairs({ -1, 1 }) do
				for k = 0, 2 do
					i += 1
					prongs[i].CFrame = spin * CFrame.new(sgn * 2.4, 0, 0) * CFrame.Angles(0, k * math.rad(120), 0) * CFrame.new(0, 0, 0.45) * CFrame.Angles(0, 0, math.rad(90 + sgn * 20))
				end
			end
			if math.random() < 0.5 then
				Fx.burst("spark", pos, c2, 2, 0.5)
			end
			if t > time * 2 then
				conn:Disconnect()
				grip:Destroy()
				for _, p in ipairs(prongs) do
					p:Destroy()
				end
				Fx.burst("spark", pos, c, 10, 1)
			end
		end)
		Fx.sound("swing", 1, 0.7, from)
	end)
end

------------------------------------------------------------------------
-- 진 무영귀각: 분영 · 그림자 밟기
------------------------------------------------------------------------
local DARK = Color3.fromRGB(20, 14, 30)
-- 사람 꼴 그림자 하나 (몸통·머리·팔다리)
local function shade(cf: CFrame, c: Color3): { BasePart }
	local list: { BasePart } = {}
	local function add(size: Vector3, off: CFrame)
		local p = part(size, DARK, Enum.Material.SmoothPlastic, 0.25)
		p.CFrame = cf * off
		table.insert(list, p)
	end
	add(Vector3.new(2, 2, 1), CFrame.new(0, 0.6, 0))
	add(Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 2.3, 0))
	add(Vector3.new(0.9, 2, 0.9), CFrame.new(1.5, 0.5, 0) * CFrame.Angles(0, 0, math.rad(20)))
	add(Vector3.new(0.9, 2, 0.9), CFrame.new(-1.5, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-20)))
	add(Vector3.new(0.9, 2, 0.9), CFrame.new(0.55, -1.5, 0))
	add(Vector3.new(0.9, 2, 0.9), CFrame.new(-0.55, -1.5, 0) * CFrame.Angles(math.rad(-60), 0, 0))
	-- 붉은 눈
	local e = part(Vector3.new(0.8, 0.15, 0.1), c, Enum.Material.Neon, 0)
	e.CFrame = cf * CFrame.new(0, 2.4, -0.62)
	table.insert(list, e)
	return list
end
local function moveShade(list: { BasePart }, from: CFrame, to: CFrame, time: number)
	for _, p in ipairs(list) do
		local off = from:ToObjectSpace(p.CFrame)
		tween(p, time, { CFrame = to * off }, Enum.EasingStyle.Quad)
	end
end
local clones: { [string]: { { BasePart } } } = {}
local function cloneSpawn(data: any)
	local r = rootOf(data.m)
	if not r or not near(r.Position, 200) then
		return
	end
	local c = colors(data.style)
	local list = {}
	for i, at in ipairs(data.spots or {}) do
		local cf = CFrame.lookAt(at, at + flat(r.CFrame.LookVector))
		local sh = shade(cf, c)
		for _, p in ipairs(sh) do
			p.CFrame = r.CFrame:Lerp(p.CFrame, 0.2)
			tween(p, 0.2, { CFrame = cf * cf:ToObjectSpace(p.CFrame) })
		end
		moveShade(sh, r.CFrame, cf, 0.2)
		list[i] = sh
		Fx.burst("dust", at, DARK, 10, 1)
	end
	local key = keyOf((data.spots or {})[1] or r.Position)
	clones[key] = list
	task.delay(data.dur or 1.6, function()
		for _, sh in ipairs(list) do
			for _, p in ipairs(sh) do
				fadeOut(p, 0.3)
			end
		end
		clones[key] = nil
	end)
	-- 다음 덮치기에서 찾을 수 있게 둘 다 기억
	for i, at in ipairs(data.spots or {}) do
		clones[keyOf(at) .. "#" .. i] = { list[i] }
	end
	Fx.sound("swing", 0.6, 0.6, r.Position)
end
local function cloneStrike(data: any)
	local from: Vector3 = data.from
	local to: Vector3 = data.to
	if not near(to, 200) then
		return
	end
	local c, c2 = colors(data.style)
	local key = keyOf(from) .. "#" .. tostring(data.i or 1)
	local entry = clones[key]
	local cfFrom = CFrame.lookAt(from, from + flat(to - from))
	local cfTo = CFrame.lookAt(to, to + flat(to - from))
	if entry and entry[1] then
		moveShade(entry[1], cfFrom, cfTo, 0.12)
		clones[key] = nil
		clones[keyOf(to) .. "#" .. tostring(data.i or 1)] = entry
	end
	local streak = beam(from, to, 0.5, DARK, 0.3, Enum.Material.SmoothPlastic)
	fadeOut(streak, 0.25)
	task.delay(0.12, function()
		Fx.ring(ground(to) + Vector3.new(0, 0.3, 0), c, 2, (data.radius or 6) * 2, 0.3)
		Fx.burst("spark", to, c2, 8, 0.8)
		Fx.sound("hit", 0.6, 1.1, to)
	end)
end
local function shadowSlide(data: any)
	local from: Vector3 = data.from
	local to: Vector3 = data.to
	if not near(from, 220) then
		return
	end
	local c = colors(data.style)
	local time = data.time or 0.45
	-- 땅 위를 미끄러지는 납작한 사람 그림자, 뒤로 검은 자국
	local blob = part(Vector3.new(3, 0.15, 6), DARK, Enum.Material.SmoothPlastic, 0.15)
	local eye = part(Vector3.new(1, 0.16, 0.3), c, Enum.Material.Neon, 0)
	local g0 = ground(from) + Vector3.new(0, 0.1, 0)
	local g1 = ground(to) + Vector3.new(0, 0.1, 0)
	local dir = flat(to - from)
	blob.CFrame = CFrame.lookAt(g0, g0 + dir)
	eye.CFrame = blob.CFrame * CFrame.new(0, 0.02, -2.4)
	tween(blob, time, { CFrame = CFrame.lookAt(g1, g1 + dir) }, Enum.EasingStyle.Linear)
	tween(eye, time, { CFrame = CFrame.lookAt(g1, g1 + dir) * CFrame.new(0, 0.02, -2.4) }, Enum.EasingStyle.Linear)
	local track = beam(g0, g0 + dir * 0.2, 0.1, DARK, 0.4, Enum.Material.SmoothPlastic)
	tween(track, time, { Size = Vector3.new(2.4, 0.1, (g1 - g0).Magnitude), CFrame = CFrame.lookAt((g0 + g1) / 2, g1) }, Enum.EasingStyle.Linear)
	task.delay(time + 0.6, function()
		fadeOut(blob, 0.2)
		fadeOut(eye, 0.2)
		fadeOut(track, 0.8)
	end)
	Fx.sound("swing", 0.5, 0.5, from)
end
local function shadowKick(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local from: Vector3 = data.from or at
	-- 되돌아 걷어차는 검붉은 반달
	local dir = flat(from - at)
	for k = -3, 3 do
		local d = (CFrame.Angles(0, math.rad(k * 12), 0) * CFrame.new(dir)).Position
		local p = beam(at + Vector3.new(0, 1, 0), at + Vector3.new(0, 1, 0) + d * 14, 0.6, k == 0 and c2 or c, 0.2)
		fadeOut(p, 0.3, { Size = Vector3.new(0.1, 0.1, p.Size.Z * 1.4) })
	end
	Fx.flash(at, c, 40, 5, 0.3)
	Fx.sound("hit", 1, 0.6, at)
	shakeNear(at, 1, 70)
end

------------------------------------------------------------------------
-- 진 태허유수장: 회류환 · 간헐천
------------------------------------------------------------------------
local function orbitStart(data: any)
	local r = rootOf(data.m)
	if not r or not near(r.Position, 200) then
		return
	end
	local c, c2 = colors(data.style)
	local n = data.n or 3
	local R = data.radius or 8
	local dur = data.dur or 3
	local orbs: { BasePart } = {}
	local tails: { BasePart } = {}
	for i = 1, n do
		orbs[i] = part(Vector3.new(2.2, 2.2, 2.2), c2, Enum.Material.Glass, 0.25, "ball")
		tails[i] = part(Vector3.new(1.2, 1.2, 4), c, Enum.Material.Neon, 0.5)
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > dur or not r.Parent then
			conn:Disconnect()
			for i = 1, n do
				fadeOut(orbs[i], 0.2)
				fadeOut(tails[i], 0.2)
			end
			return
		end
		for i = 1, n do
			local a = t * 5 + (i / n) * math.pi * 2
			local pos = r.Position + Vector3.new(math.cos(a) * R, 0.5 + math.sin(t * 3 + i) * 0.8, math.sin(a) * R)
			local tan = Vector3.new(-math.sin(a), 0, math.cos(a))
			orbs[i].CFrame = CFrame.new(pos)
			tails[i].CFrame = CFrame.lookAt(pos - tan * 2, pos)
		end
	end)
	Fx.sound("splash", 0.7, 1.1, r.Position)
end
local function orbitBurst(data: any)
	if near(data.at, 200) then
		local c, c2 = colors(data.style)
		local g = ground(data.at)
		for k = 0, 2 do
			task.delay(k * 0.08, function()
				Fx.ring(g + Vector3.new(0, 0.4, 0), k == 1 and c2 or c, 3, (data.radius or 12) * 2 + k * 5, 0.5)
			end)
		end
		Fx.burst("spark", data.at, c2, 24, 1.6)
		Fx.sound("splash", 1, 0.7, data.at)
	end
end
local function hotGeyser(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local c, c2 = colors(data.style)
	local g = ground(at)
	local R = data.radius or 5
	-- 땅이 끓어오르다가 (0.1초) 물기둥이 솟고, 김이 퍼진다
	local boil = disc(g + Vector3.new(0, 0.1, 0), R * 1.6, c, 0.4)
	task.delay(0.1, function()
		fadeOut(boil, 0.3)
		local col = column(g, 2, R * 1.1, c2, 0.15, Enum.Material.Glass)
		tween(col, 0.15, { Size = Vector3.new(26, R * 1.1, R * 1.1), CFrame = CFrame.new(g + Vector3.new(0, 13, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
		task.delay(0.35, function()
			fadeOut(col, 0.4, { Size = Vector3.new(30, R * 0.3, R * 0.3) })
		end)
		local cap = part(Vector3.new(1, 1, 1), c2, Enum.Material.Neon, 0.3, "ball")
		cap.CFrame = CFrame.new(g + Vector3.new(0, 26, 0))
		fadeOut(cap, 0.6, { Size = Vector3.new(R * 3, R * 1.4, R * 3) })
		Fx.burst("dust", g + Vector3.new(0, 1, 0), Color3.fromRGB(235, 245, 255), 14, 1.4)
		Fx.ring(g + Vector3.new(0, 0.3, 0), c, 2, R * 2.4, 0.4)
		Fx.sound("splash", 0.8, 0.9 + (data.i or 1) * 0.05, at)
	end)
end

------------------------------------------------------------------------
-- 진 열화신권: 화륜 · 폭염륜 · 화산천붕
------------------------------------------------------------------------
local FIRE = Color3.fromRGB(255, 110, 30)
local LAVA = Color3.fromRGB(255, 70, 10)
local ROCK = Color3.fromRGB(50, 30, 25)
local function wheelRoll(data: any)
	local from: Vector3 = data.from
	if not near(from, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local dir: Vector3 = data.dir or Vector3.new(0, 0, -1)
	local dist = data.dist or 36
	local time = data.time or 0.8
	local rad = 2.6
	-- 불의 바퀴: 테 + 바큇살 넷 (구르며 돈다)
	local rim = part(Vector3.new(0.6, rad * 2, rad * 2), c, Enum.Material.Neon, 0.1, "cyl")
	local spokes: { BasePart } = {}
	for k = 1, 4 do
		spokes[k] = part(Vector3.new(0.4, rad * 1.9, 0.4), c2, Enum.Material.Neon, 0)
	end
	local right = Vector3.new(-dir.Z, 0, dir.X)
	local t0 = os.clock()
	local last = ground(from)
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = math.clamp((os.clock() - t0) / time, 0, 1)
		local g = ground(from + dir * dist * t)
		local center = g + Vector3.new(0, rad, 0)
		local roll = -(dist * t) / rad
		local base = CFrame.fromMatrix(center, right, Vector3.yAxis) * CFrame.Angles(roll, 0, 0)
		rim.CFrame = CFrame.fromMatrix(center, right, Vector3.yAxis) * CFrame.Angles(roll, 0, 0)
		for k = 1, 4 do
			spokes[k].CFrame = base * CFrame.Angles(k * math.rad(45), 0, 0)
		end
		-- 바퀴 자국에 불이 남는다
		if (g - last).Magnitude > 2 then
			local seg = beam(last + Vector3.new(0, 0.15, 0), g + Vector3.new(0, 0.15, 0), 0.3, FIRE, 0.25)
			seg.Size = Vector3.new(2.2, 0.2, seg.Size.Z + 0.3)
			task.delay(data.burn or 2, function()
				fadeOut(seg, 0.4)
			end)
			Fx.burst("ember", g + Vector3.new(0, 0.5, 0), FIRE, 3, 0.7)
			last = g
		end
		if t >= 1 then
			conn:Disconnect()
			fadeOut(rim, 0.2)
			for k = 1, 4 do
				fadeOut(spokes[k], 0.2)
			end
			Fx.burst("ember", center, c, 16, 1.2)
		end
	end)
	Fx.sound("swing", 0.8, 0.8, from)
end
local function flameRing(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 20
	local time = data.time or 0.55
	local g = ground(at)
	-- 퍼져 나가는 불의 벽 (둥글게 선 불꽃 조각들)
	local n = 28
	local flames: { BasePart } = {}
	for k = 1, n do
		flames[k] = part(Vector3.new(2.4, 3.6, 0.8), k % 2 == 0 and FIRE or c2, Enum.Material.Neon, 0.15)
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = math.clamp((os.clock() - t0) / time, 0, 1)
		local rr = 2 + (R - 2) * t
		for k = 1, n do
			local a = (k / n) * math.pi * 2
			local pos = g + Vector3.new(math.cos(a) * rr, 1.8 * (1 - t * 0.4), math.sin(a) * rr)
			flames[k].CFrame = CFrame.lookAt(pos, g + Vector3.new(0, pos.Y - g.Y, 0)) * CFrame.Angles(0, 0, math.sin(t * 20 + k) * 0.2)
			flames[k].Size = Vector3.new(2.4 + rr * 0.08, 3.6 * (1 - t * 0.5), 0.8)
		end
		if t >= 1 then
			conn:Disconnect()
			for k = 1, n do
				fadeOut(flames[k], 0.25)
			end
		end
	end)
	local scorch = disc(g + Vector3.new(0, 0.12, 0), 2, ROCK, 0.3, Enum.Material.Slate)
	tween(scorch, time, { Size = Vector3.new(0.2, R * 2, R * 2) })
	task.delay(time + 0.8, function()
		fadeOut(scorch, 0.6)
	end)
	Fx.burst("ember", g + Vector3.new(0, 1, 0), c, 30, 2)
	Fx.flash(at, c, 50, 5, 0.4)
	Fx.sound("heavy", 1, 0.8, at)
	shakeNear(at, 1.2, 80)
end
local volcanos: { [string]: { BasePart } } = {}
local function volcanoRise(data: any)
	local at: Vector3 = data.at
	if not near(at, 240) then
		return
	end
	local R = data.radius or 26
	local g = ground(at)
	-- 땅이 부풀어 오른다: 바위 원뿔 (겹친 원기둥) + 위의 용암 웅덩이 + 갈라진 금
	local list: { BasePart } = {}
	local layers = { { 14, 2.2 }, { 10, 2.4 }, { 7, 2.4 }, { 4.5, 1.8 } }
	local y = 0
	for _, L in ipairs(layers) do
		local p = part(Vector3.new(L[2], L[1], L[1]), ROCK, Enum.Material.Basalt, 0, "cyl")
		p.CFrame = CFrame.new(g + Vector3.new(0, y + L[2] / 2 - 10, 0)) * CFrame.Angles(0, 0, math.rad(90))
		tween(p, 0.5, { CFrame = CFrame.new(g + Vector3.new(0, y + L[2] / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)) }, Enum.EasingStyle.Back)
		y += L[2]
		table.insert(list, p)
	end
	local pool = part(Vector3.new(0.3, 3.6, 3.6), LAVA, Enum.Material.Neon, 0, "cyl")
	pool.CFrame = CFrame.new(g + Vector3.new(0, y + 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	table.insert(list, pool)
	for k = 1, 6 do
		local a = (k / 6) * math.pi * 2
		local crack = beam(g + Vector3.new(0, 0.12, 0), g + Vector3.new(math.cos(a) * R * 0.9, 0.12, math.sin(a) * R * 0.9), 0.1, LAVA, 0.1)
		crack.Size = Vector3.new(0.8, 0.15, crack.Size.Z)
		table.insert(list, crack)
	end
	volcanos[keyOf(at)] = list
	Fx.sound("heavy", 1, 0.4, at)
	shakeNear(at, 1, 100)
	task.delay(data.dur or 3, function()
		volcanos[keyOf(at)] = nil
		for _, p in ipairs(list) do
			fadeOut(p, 0.8, { CFrame = p.CFrame * CFrame.new(-6, 0, 0) })
		end
	end)
end
local function vent(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local g = ground(at)
	local R = data.radius or 6
	local col = column(g, 2, R, LAVA, 0.05)
	tween(col, 0.12, { Size = Vector3.new(20, R, R), CFrame = CFrame.new(g + Vector3.new(0, 10, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(0.2, function()
		fadeOut(col, 0.35, { Size = Vector3.new(24, 0.4, 0.4) })
	end)
	local pool = disc(g + Vector3.new(0, 0.12, 0), R * 1.8, LAVA, 0.2)
	task.delay(0.8, function()
		fadeOut(pool, 0.5)
	end)
	Fx.burst("ember", g + Vector3.new(0, 2, 0), FIRE, 14, 1.3)
	Fx.debris(g, 5, 25, ROCK)
	Fx.sound("hit", 0.6, 0.6, at)
end
local function eruptMain(data: any)
	local at: Vector3 = data.at
	if not near(at, 260) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 16
	local g = ground(at) + Vector3.new(0, 9, 0)
	local col = column(g, 4, R * 0.6, LAVA, 0)
	tween(col, 0.2, { Size = Vector3.new(90, R * 0.7, R * 0.7), CFrame = CFrame.new(g + Vector3.new(0, 45, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(0.5, function()
		fadeOut(col, 0.6, { Size = Vector3.new(100, R * 1.4, R * 1.4) })
	end)
	local smoke = part(Vector3.new(1, 1, 1), Color3.fromRGB(60, 50, 50), Enum.Material.SmoothPlastic, 0.3, "ball")
	smoke.CFrame = CFrame.new(g + Vector3.new(0, 80, 0))
	fadeOut(smoke, 2, { Size = Vector3.new(70, 30, 70) })
	for k = 0, 3 do
		task.delay(k * 0.07, function()
			Fx.ring(ground(at) + Vector3.new(0, 0.4, 0), k % 2 == 0 and c or c2, 4, R * 2.4 + k * 10, 0.7)
		end)
	end
	Fx.burst("ember", g + Vector3.new(0, 5, 0), FIRE, 60, 3)
	Fx.debris(ground(at), 16, 50, ROCK)
	Fx.flash(at, LAVA, 80, 8, 0.8)
	Fx.breakSound("rock", 0.8, 0.5, at)
	Fx.sound("heavy", 1, 0.35, at)
	shakeNear(at, 2.4, 120)
end
local function meteorDrop(data: any)
	local at: Vector3 = data.at
	if not near(at, 240) then
		return
	end
	local g = ground(at)
	local fall = data.fall or 0.35
	local R = data.radius or 6
	local mark = disc(g + Vector3.new(0, 0.15, 0), R * 2, LAVA, 0.6)
	local rock = part(Vector3.new(3, 3, 3), ROCK, Enum.Material.Basalt, 0, "ball")
	local glow = part(Vector3.new(3.8, 3.8, 3.8), FIRE, Enum.Material.Neon, 0.4, "ball")
	local from = g + Vector3.new(math.random(-14, 14), 70, math.random(-14, 14))
	rock.CFrame = CFrame.new(from)
	glow.CFrame = rock.CFrame
	tween(rock, fall, { CFrame = CFrame.new(g + Vector3.new(0, 1, 0)) }, Enum.EasingStyle.Linear)
	tween(glow, fall, { CFrame = CFrame.new(g + Vector3.new(0, 1, 0)) }, Enum.EasingStyle.Linear)
	local tail = beam(from, from + (from - g).Unit * 8, 1.6, FIRE, 0.35)
	tween(tail, fall, { CFrame = CFrame.lookAt(g + (from - g).Unit * 5, g) }, Enum.EasingStyle.Linear)
	task.delay(fall, function()
		rock:Destroy()
		glow:Destroy()
		tail:Destroy()
		fadeOut(mark, 0.3)
		Fx.ring(g + Vector3.new(0, 0.3, 0), FIRE, 2, R * 2.4, 0.4)
		Fx.burst("ember", g + Vector3.new(0, 1, 0), FIRE, 12, 1.2)
		Fx.debris(g, 4, 20, ROCK)
		if math.random() < 0.5 then
			Fx.sound("hit", 0.7, 0.5, at)
		end
		shakeNear(at, 0.4, 60)
	end)
end

------------------------------------------------------------------------
-- 진 창해신권: 수포옥 · 해룡창 · 고래강림
------------------------------------------------------------------------
local function bubbleTrap(data: any)
	local c, c2 = colors(data.style)
	local dur = (data.dur or 1.6) + 0.1
	task.delay(data.delay or 0.25, function()
		for _, m in ipairs(data.targets or {}) do
			local r = rootOf(m)
			if r and near(r.Position, 200) then
				local b = part(Vector3.new(1, 1, 1), c2, Enum.Material.Glass, 0.45, "ball")
				local shine = part(Vector3.new(1.2, 1.2, 0.2), WHITE, Enum.Material.Neon, 0.4, "ball")
				tween(b, 0.2, { Size = Vector3.new(8, 8, 8) }, Enum.EasingStyle.Back)
				local t0 = os.clock()
				local conn: RBXScriptConnection
				conn = RunService.Heartbeat:Connect(function()
					local t = os.clock() - t0
					if t > dur or not r.Parent then
						conn:Disconnect()
						b:Destroy()
						shine:Destroy()
						return
					end
					-- 갇힌 몸이 둥실 떠오르는 것처럼 보이게 물방울이 위로 일렁인다
					local pos = r.Position + Vector3.new(0, 0.5 + math.sin(t * 4) * 0.4, 0)
					local k = 8 + math.sin(t * 9) * 0.4
					b.Size = Vector3.new(k, k * 1.05, k)
					b.CFrame = CFrame.new(pos)
					shine.CFrame = CFrame.new(pos + Vector3.new(-2, 2, -2.5))
					if math.random() < 0.15 then
						Fx.burst("spark", pos + Vector3.new(0, 3, 0), c, 2, 0.4)
					end
				end)
			end
		end
		local first = rootOf((data.targets or {})[1])
		if first then
			Fx.sound("splash", 0.8, 1.4, first.Position)
		end
	end)
end
local function bubblePop(data: any)
	local c, c2 = colors(data.style)
	for _, at in ipairs(data.spots or {}) do
		if near(at, 200) then
			local b = part(Vector3.new(8, 8, 8), c2, Enum.Material.Glass, 0.4, "ball")
			b.CFrame = CFrame.new(at)
			fadeOut(b, 0.25, { Size = Vector3.new(14, 14, 14) })
			impact(at, data.radius or 7, c, c2, 1)
			Fx.burst("dust", at, Color3.fromRGB(220, 240, 255), 14, 1.4)
			Fx.sound("splash", 1, 1.2, at)
		end
	end
end
local function waterSpear(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local g = ground(at)
	local fall = data.fall or 0.18
	local from = g + Vector3.new(math.random(-4, 4), 50, math.random(-4, 4))
	local shaft = beam(from, from + (g - from).Unit * 9, 0.8, c2, 0.1, Enum.Material.Glass)
	local head = part(Vector3.new(1.4, 1.4, 2.6), WHITE, Enum.Material.Neon, 0, "wedge")
	local dir = (g - from).Unit
	head.CFrame = CFrame.lookAt(from + dir * 10, from + dir * 11) * CFrame.Angles(math.rad(90), 0, 0)
	tween(shaft, fall, { CFrame = CFrame.lookAt(g - dir * 4.5, g) }, Enum.EasingStyle.Linear)
	tween(head, fall, { CFrame = CFrame.lookAt(g + dir * 0.5, g + dir * 1.5) * CFrame.Angles(math.rad(90), 0, 0) }, Enum.EasingStyle.Linear)
	task.delay(fall, function()
		task.delay(0.35, function()
			fadeOut(shaft, 0.3)
			fadeOut(head, 0.3)
		end)
		Fx.ring(g + Vector3.new(0, 0.3, 0), c, 1.5, (data.radius or 4.5) * 2.2, 0.35)
		Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(210, 235, 255), 10, 1)
		Fx.sound("splash", 0.6, 1 + (data.i or 1) * 0.05, at)
	end)
end
local function whale(data: any)
	local from: Vector3 = data.from
	local to: Vector3 = data.to
	if not near(from, 260) then
		return
	end
	local c, c2 = colors(data.style)
	local delay = data.delay or 0.35
	local flight = data.flight or 1.3
	local g0 = ground(from)
	local g1 = ground(to)
	local dir = flat(to - from)
	local S = 3.2
	-- 물의 고래: 둥근 몸 (공 셋), 아래턱, 꼬리지느러미 둘, 가슴지느러미 둘, 눈
	local body: { { p: BasePart, off: CFrame } } = {}
	local function add(size: Vector3, off: CFrame, color: Color3, mat: Enum.Material?, alpha: number?, shape: string?)
		local p = part(size * S, color, mat or Enum.Material.Glass, alpha or 0.25, shape)
		table.insert(body, { p = p, off = CFrame.new(off.Position * S) * off.Rotation })
	end
	add(Vector3.new(5, 4.4, 9), CFrame.new(0, 0, 0), c, Enum.Material.Glass, 0.2, "ball")
	add(Vector3.new(4.4, 3.8, 6), CFrame.new(0, 0.2, -3.6), c, Enum.Material.Glass, 0.2, "ball")
	add(Vector3.new(3, 2.6, 5), CFrame.new(0, 0, 4.6), c, Enum.Material.Glass, 0.25, "ball")
	add(Vector3.new(4, 1.4, 6), CFrame.new(0, -1.4, -2.6), c2, Enum.Material.Glass, 0.3, "ball")
	add(Vector3.new(4.2, 0.4, 2), CFrame.new(1.8, 0.2, 7.4) * CFrame.Angles(0, math.rad(-25), math.rad(-10)), c2, Enum.Material.Neon, 0.3)
	add(Vector3.new(4.2, 0.4, 2), CFrame.new(-1.8, 0.2, 7.4) * CFrame.Angles(0, math.rad(25), math.rad(10)), c2, Enum.Material.Neon, 0.3)
	add(Vector3.new(3, 0.3, 1.4), CFrame.new(3, -0.8, -1.5) * CFrame.Angles(0, math.rad(20), math.rad(-30)), c2, Enum.Material.Neon, 0.35)
	add(Vector3.new(3, 0.3, 1.4), CFrame.new(-3, -0.8, -1.5) * CFrame.Angles(0, math.rad(-20), math.rad(30)), c2, Enum.Material.Neon, 0.35)
	add(Vector3.new(0.5, 0.5, 0.5), CFrame.new(1.9, 0.6, -5), WHITE, Enum.Material.Neon, 0, "ball")
	add(Vector3.new(0.5, 0.5, 0.5), CFrame.new(-1.9, 0.6, -5), WHITE, Enum.Material.Neon, 0, "ball")
	local hidden = CFrame.new(g0 - Vector3.new(0, 40, 0))
	for _, e in ipairs(body) do
		e.p.CFrame = hidden
	end
	-- 솟구칠 자리의 물웅덩이
	local pool = disc(g0 + Vector3.new(0, 0.1, 0), 2, c, 0.25, Enum.Material.Glass)
	tween(pool, delay, { Size = Vector3.new(0.2, 26, 26) })
	local t0 = os.clock()
	local H = 34
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0 - delay
		if t < 0 then
			return
		end
		local u = math.clamp(t / flight, 0, 1)
		-- 포물선: 앞으로 가며 솟았다 떨어진다. 머리가 가는 쪽을 본다
		local pos = g0:Lerp(g1, u) + Vector3.new(0, 4 * H * u * (1 - u) + 2, 0)
		local du = math.min(1, u + 0.02)
		local nxt = g0:Lerp(g1, du) + Vector3.new(0, 4 * H * du * (1 - du) + 2, 0)
		local look = (nxt - pos).Magnitude > 1e-3 and (nxt - pos).Unit or dir
		local cf = CFrame.lookAt(pos, pos + look) * CFrame.Angles(0, 0, math.sin(u * math.pi) * 0.3)
		for _, e in ipairs(body) do
			e.p.CFrame = cf * e.off
		end
		if math.random() < 0.5 then
			Fx.burst("dust", pos, Color3.fromRGB(220, 240, 255), 3, 1.2)
		end
		if u >= 1 then
			conn:Disconnect()
			for _, e in ipairs(body) do
				fadeOut(e.p, 0.35, { CFrame = e.p.CFrame * CFrame.new(0, -6, 0) })
			end
			fadeOut(pool, 0.4)
			-- 덮치는 물보라
			for k = 0, 3 do
				task.delay(k * 0.07, function()
					Fx.ring(g1 + Vector3.new(0, 0.4, 0), k % 2 == 0 and c or c2, 4, (data.radius or 20) * 2.2 + k * 8, 0.7)
				end)
			end
			local splash = column(g1, 4, 16, c2, 0.2, Enum.Material.Glass)
			tween(splash, 0.25, { Size = Vector3.new(30, 26, 26), CFrame = CFrame.new(g1 + Vector3.new(0, 15, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
			task.delay(0.3, function()
				fadeOut(splash, 0.5)
			end)
			Fx.burst("dust", g1 + Vector3.new(0, 2, 0), Color3.fromRGB(220, 240, 255), 50, 3)
			Fx.flash(g1, c, 80, 6, 0.6)
			Fx.sound("splash", 1, 0.4, g1)
			Fx.sound("heavy", 1, 0.4, g1)
			shakeNear(g1, 2.4, 140)
		end
	end)
	task.delay(delay, function()
		Fx.burst("dust", g0 + Vector3.new(0, 2, 0), Color3.fromRGB(220, 240, 255), 40, 2.4)
		Fx.sound("splash", 1, 0.6, g0)
		shakeNear(g0, 1.2, 100)
	end)
end

------------------------------------------------------------------------
-- 진 풍신각: 회풍 · 풍압
------------------------------------------------------------------------
type Twister = { parts: { BasePart }, at: Vector3, from: Vector3, t0: number, time: number, born: number }
local twisters: { [number]: Twister } = {}
local function twisterStart(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 5
	local tw: Twister = { parts = {}, at = at, from = at, t0 = os.clock(), time = 0.2, born = os.clock() }
	for k = 1, 7 do
		local w = R * (0.4 + k * 0.22)
		tw.parts[k] = part(Vector3.new(0.5, w, w), k % 2 == 0 and c or c2, Enum.Material.ForceField, 0.2, "cyl")
	end
	twisters[data.id] = tw
	local dur = data.dur or 3
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if not twisters[data.id] or now - tw.born > dur + 0.5 then
			conn:Disconnect()
			return
		end
		local u = math.clamp((now - tw.t0) / tw.time, 0, 1)
		local pos = tw.from:Lerp(tw.at, u)
		local g = ground(pos)
		for k, p in ipairs(tw.parts) do
			local sway = Vector3.new(math.sin(now * 6 + k) * 0.5 * k * 0.3, 0, math.cos(now * 5 + k) * 0.5 * k * 0.3)
			p.CFrame = CFrame.new(g + Vector3.new(0, k * 1.6, 0) + sway) * CFrame.Angles(0, now * 12 + k, 0) * CFrame.Angles(0, 0, math.rad(90))
		end
		if math.random() < 0.3 then
			Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(200, 200, 190), 2, 0.8)
		end
	end)
	Fx.sound("swing", 0.7, 0.5, at)
end
local function twisterMove(data: any)
	local tw = twisters[data.id]
	if tw then
		local u = math.clamp((os.clock() - tw.t0) / tw.time, 0, 1)
		tw.from = tw.from:Lerp(tw.at, u)
		tw.at = data.at
		tw.t0 = os.clock()
		tw.time = data.time or 0.2
	end
end
local function twisterEnd(data: any)
	local tw = twisters[data.id]
	twisters[data.id] = nil
	local c, c2 = colors(data.style)
	if tw then
		for k, p in ipairs(tw.parts) do
			fadeOut(p, 0.3, { Size = p.Size * 1.8, CFrame = p.CFrame * CFrame.new(k * 0.5, 0, 0) })
		end
	end
	if near(data.at, 200) then
		impact(data.at, data.radius or 8, c, c2, 1)
		Fx.sound("swing", 1, 0.8, data.at)
	end
end
local function downdraftWarn(data: any)
	local r = rootOf(data.m)
	if not r or not near(r.Position, 200) then
		return
	end
	local c = colors(data.style)
	-- 하늘에 바람이 모여드는 고리 (위에서 소용돌이친다)
	local top = r.Position + Vector3.new(0, 30, 0)
	for k = 0, 2 do
		task.delay(k * 0.1, function()
			Fx.ring(top + Vector3.new(0, k * 2, 0), c, 3, (data.radius or 15) * 2.6, data.time or 0.5)
		end)
	end
	Fx.sound("swing", 0.6, 0.4, r.Position)
end
local function downdraft(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 15
	local g = ground(at)
	-- 하늘에서 내리누르는 공기 기둥 (위에서 아래로 짧아지며 넓어진다)
	local col = column(g, 60, R * 1.4, c2, 0.6, Enum.Material.ForceField)
	tween(col, 0.2, { Size = Vector3.new(4, R * 2.2, R * 2.2), CFrame = CFrame.new(g + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.22, function()
		fadeOut(col, 0.3)
		for k = 0, 2 do
			task.delay(k * 0.06, function()
				Fx.ring(g + Vector3.new(0, 0.3, 0), k == 1 and c or c2, 2, R * 2.4 + k * 6, 0.5)
			end)
		end
		-- 땅에 눌린 자국 (풀이 눕듯 바깥으로 그어진 줄)
		for k = 1, 12 do
			local a = (k / 12) * math.pi * 2
			local line = beam(g + Vector3.new(math.cos(a) * 3, 0.15, math.sin(a) * 3), g + Vector3.new(math.cos(a) * R, 0.15, math.sin(a) * R), 0.2, c, 0.3)
			fadeOut(line, 0.6)
		end
		Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(200, 200, 190), 36, 2.4)
		Fx.sound("heavy", 1, 0.6, at)
		shakeNear(at, 1.6, 90)
	end)
end

------------------------------------------------------------------------
-- 초·벽력신권: 뇌신낙 · 천뢰구 · 심판의 벼락 (구천뇌정)
------------------------------------------------------------------------
local function diveMark(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local g = ground(at) + Vector3.new(0, 0.15, 0)
	local R = (data.radius or 8) * 2
	local ring = disc(g, R, c, 0.5)
	local cross1 = part(Vector3.new(R, 0.16, 0.5), c2, Enum.Material.Neon, 0.3)
	local cross2 = part(Vector3.new(0.5, 0.16, R), c2, Enum.Material.Neon, 0.3)
	cross1.CFrame = CFrame.new(g)
	cross2.CFrame = CFrame.new(g)
	local time = data.time or 0.45
	tween(ring, time, { Size = Vector3.new(0.2, R * 0.3, R * 0.3), Transparency = 0.1 })
	task.delay(time, function()
		ring:Destroy()
		cross1:Destroy()
		cross2:Destroy()
	end)
end
local function diveImpact(data: any)
	local at: Vector3 = data.at
	if not near(at, 240) then
		return
	end
	local c, c2 = colors(data.style)
	local g = ground(at)
	local top = (data.from or at) + Vector3.new(0, 40, 0)
	-- 몸이 벼락이 되어 떨어진 길
	Fx.lightning(top, g, WHITE, 1.4)
	Fx.lightning(top + Vector3.new(3, 0, 0), g, c, 0.9)
	Fx.lightning(top - Vector3.new(3, 0, 0), g, c2, 0.9)
	local col = column(g, 40, 3, WHITE, 0)
	fadeOut(col, 0.3, { Size = Vector3.new(40, 0.3, 0.3) })
	impact(at, data.radius or 8, c, c2, 1.6)
	Fx.flash(at, c, 70, 8, 0.4)
	Fx.debris(g, 10, 35, Color3.fromRGB(80, 75, 90))
	Fx.breakSound("rock", 0.8, 1.2, at)
	shakeNear(at, 1.8, 100)
	-- 네 갈래로 달리는 땅의 금과 번개
	local dir: Vector3 = data.dir or Vector3.new(0, 0, -1)
	local right = Vector3.new(-dir.Z, 0, dir.X)
	local L = data.length or 18
	task.delay(data.delay or 0.2, function()
		for _, d in ipairs({ dir, -dir, right, -right }) do
			local steps = 6
			for k = 1, steps do
				task.delay(k * 0.025, function()
					local a = g + d * (L * (k - 1) / steps)
					local b = g + d * (L * k / steps)
					local crack = beam(a + Vector3.new(0, 0.15, 0), b + Vector3.new(0, 0.15, 0), 0.6, c2, 0)
					fadeOut(crack, 0.6)
					if k % 2 == 0 then
						Fx.lightning(b + Vector3.new(0, 5, 0), b, c, 0.4)
					end
				end)
			end
		end
		Fx.sound("hit", 0.9, 1.4, at)
	end)
end
type Ball = { core: BasePart, shell: BasePart, pos: Vector3 }
local balls: { [number]: Ball } = {}
local function ballStart(data: any)
	local from: Vector3 = data.from
	if not near(from, 240) then
		return
	end
	local c, c2 = colors(data.style)
	local dir: Vector3 = data.dir or Vector3.new(0, 0, -1)
	local speed = data.speed or 12
	local dur = data.dur or 2.4
	local delay = data.delay or 0.4
	local core = part(Vector3.new(1, 1, 1), WHITE, Enum.Material.Neon, 0, "ball")
	local shell = part(Vector3.new(1, 1, 1), c, Enum.Material.ForceField, 0.1, "ball")
	core.CFrame = CFrame.new(from)
	shell.CFrame = CFrame.new(from)
	tween(core, delay, { Size = Vector3.new(4, 4, 4) }, Enum.EasingStyle.Back)
	tween(shell, delay, { Size = Vector3.new(9, 9, 9) }, Enum.EasingStyle.Back)
	local b: Ball = { core = core, shell = shell, pos = from }
	balls[data.id] = b
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if not balls[data.id] or t > delay + dur + 1 then
			conn:Disconnect()
			return
		end
		local mv = math.max(0, t - delay)
		b.pos = from + dir * (speed * math.min(mv, dur))
		local wob = 1 + math.sin(t * 22) * 0.08
		core.CFrame = CFrame.new(b.pos)
		shell.CFrame = CFrame.new(b.pos) * CFrame.Angles(t * 3, t * 5, 0)
		shell.Size = Vector3.new(9, 9, 9) * wob
		-- 구슬 겉을 기어 다니는 작은 번개
		if math.random() < 0.6 then
			local d = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit
			Fx.lightning(b.pos + d * 1.5, b.pos + d * 5.5, math.random() < 0.5 and c or c2, 0.25)
		end
	end)
	Fx.sound("deflect", 0.8, 0.7, from)
end
local function ballArc(data: any)
	local from: Vector3 = data.from
	if not near(from, 240) then
		return
	end
	local c, c2 = colors(data.style)
	for i, m in ipairs(data.targets or {}) do
		local r = rootOf(m)
		if r and i <= 8 then
			Fx.lightning(from, r.Position, i % 2 == 0 and c or c2, 0.45)
			Fx.burst("spark", r.Position, c2, 4, 0.5)
		end
	end
	if math.random() < 0.4 then
		Fx.sound("hit", 0.4, 1.6, from)
	end
end
local function ballBurst(data: any)
	local at: Vector3 = data.at
	for id, b in pairs(balls) do
		if (b.pos - at).Magnitude < 8 then
			balls[id] = nil
			-- 안으로 줄어들었다가 터진다
			tween(b.core, 0.12, { Size = Vector3.new(1, 1, 1) })
			tween(b.shell, 0.12, { Size = Vector3.new(2, 2, 2) })
			task.delay(0.12, function()
				b.core:Destroy()
				b.shell:Destroy()
			end)
		end
	end
	if not near(at, 260) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 18
	task.delay(0.12, function()
		local s = part(Vector3.new(2, 2, 2), c2, Enum.Material.Neon, 0.1, "ball")
		s.CFrame = CFrame.new(at)
		fadeOut(s, 0.45, { Size = Vector3.new(1, 1, 1) * R * 2 })
		for k = 1, 10 do
			local a = (k / 10) * math.pi * 2
			Fx.lightning(at, ground(at) + Vector3.new(math.cos(a) * R, 0, math.sin(a) * R), k % 2 == 0 and c or c2, 0.7)
		end
		impact(at, R, c, c2, 2)
		Fx.flash(at, c, 90, 9, 0.6)
		Fx.breakSound("glass", 0.9, 0.9, at)
		shakeNear(at, 2.2, 120)
	end)
end
-- 2.6판 뇌성강림: 고리 둘이 도는 천둥별, 떨어져 나와 둘레를 도는 작은 별 여섯, 별마다 쏘는 번개 줄기, 다시 모여 떨어지는 별
type Star = { orb: (i: number) -> Vector3, starPos: () -> Vector3, parts: { BasePart }, done: boolean }
local stars: { [number]: Star } = {}
local function starStart(data: any)
	local center: Vector3 = data.at
	if not near(center, 260) then
		return
	end
	local c, c2 = colors(data.style)
	local n = data.n or 6
	local orbit, height, spin = data.orbit or 13, data.height or 11, data.spin or 1.1
	local delay, spread, dur, converge = data.delay or 0.45, data.spread or 0.4, data.dur or 2.4, data.converge or 0.4
	local t1 = delay + spread
	local t2 = t1 + dur
	local t3 = t2 + converge
	local top = center + Vector3.new(0, height + 4, 0)
	local parts: { BasePart } = {}
	local function keep(p: BasePart): BasePart
		table.insert(parts, p)
		return p
	end
	-- 천둥별: 흰 속, 푸른 껍질, 네 갈래 빛살, 고리 둘
	local core = keep(part(Vector3.new(0.5, 0.5, 0.5), WHITE, Enum.Material.Neon, 0, "ball"))
	local shell = keep(part(Vector3.new(0.5, 0.5, 0.5), c, Enum.Material.ForceField, 0.05, "ball"))
	local spikes: { BasePart } = {}
	for k = 1, 4 do
		spikes[k] = keep(part(Vector3.new(0.5, 0.5, 0.5), k % 2 == 0 and c2 or WHITE, Enum.Material.Neon, 0.1))
	end
	local rings: { { BasePart } } = { {}, {} }
	for r = 1, 2 do
		for k = 1, 18 do
			rings[r][k] = keep(part(Vector3.new(0.35, 0.35, 2.3), r == 1 and c2 or c, Enum.Material.Neon, 0.15))
		end
	end
	local orbs: { BasePart } = {}
	local halos: { BasePart } = {}
	for i = 1, n do
		orbs[i] = keep(part(Vector3.new(2, 2, 2), c2, Enum.Material.Neon, 1, "ball"))
		halos[i] = keep(part(Vector3.new(3.6, 3.6, 3.6), c, Enum.Material.ForceField, 1, "ball"))
	end
	-- 땅에 별이 도는 자리를 그린다
	local mark = keep(disc(ground(center) + Vector3.new(0, 0.15, 0), orbit * 2, c, 1))
	tween(mark, delay, { Transparency = 0.75 })
	local t0 = os.clock()
	local function ease(x: number): number
		x = math.clamp(x, 0, 1)
		return 1 - (1 - x) * (1 - x)
	end
	local function orbitPos(i: number, t: number): Vector3
		local a = (i - 1) / n * math.pi * 2 + t * spin
		return center + Vector3.new(math.cos(a) * orbit, height, math.sin(a) * orbit)
	end
	local S: Star
	local function starPos(): Vector3
		local t = os.clock() - t0
		if t <= t3 then
			return top + Vector3.new(0, math.sin(t * 3) * 0.4, 0)
		end
		-- 떨어진다
		local k = math.clamp((t - t3) / 0.12, 0, 1)
		return top:Lerp(ground(center) + Vector3.new(0, 2, 0), k * k)
	end
	local function orb(i: number): Vector3
		local t = os.clock() - t0
		if t < delay then
			return starPos()
		elseif t < t1 then
			return starPos():Lerp(orbitPos(i, 0), ease((t - delay) / spread))
		elseif t < t2 then
			return orbitPos(i, t - t1)
		end
		return orbitPos(i, dur):Lerp(starPos(), ease((t - t2) / converge))
	end
	S = { orb = orb, starPos = starPos, parts = parts, done = false }
	stars[data.id] = S
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if S.done or t > t3 + 1.5 then
			conn:Disconnect()
			for _, p in ipairs(parts) do
				if p.Parent then
					p:Destroy()
				end
			end
			stars[data.id] = nil
			return
		end
		local grow = ease(t / math.max(0.05, delay))
		-- 별들이 떨어져 나가면 조금 작아졌다가, 다시 모이면 크게 부푼다
		local mass = t < t1 and 1 or (t < t2 and 0.7 or 0.7 + 0.6 * ease((t - t2) / converge))
		local sp = starPos()
		local pulse = 1 + math.sin(t * 18) * 0.06
		core.Size = Vector3.new(1, 1, 1) * 4 * grow * mass * pulse
		shell.Size = Vector3.new(1, 1, 1) * 8 * grow * mass
		core.CFrame = CFrame.new(sp)
		shell.CFrame = CFrame.new(sp) * CFrame.Angles(t * 2, t * 3, 0)
		for k, sk in ipairs(spikes) do
			local len = (k % 2 == 0 and 12 or 16) * grow * mass * (1 + math.sin(t * 9 + k) * 0.1)
			sk.Size = Vector3.new(0.35, 0.35, len)
			-- 세운 판 위의 여덟 갈래 빛살 (천천히 돈다)
			sk.CFrame = CFrame.new(sp) * CFrame.Angles(0, t * 0.6, 0) * CFrame.Angles((k - 1) * math.pi / 4, 0, 0)
		end
		for r = 1, 2 do
			local rad = (r == 1 and 7 or 9) * grow * mass
			local tilt = r == 1 and CFrame.Angles(math.rad(70), t * 1.5, 0) or CFrame.Angles(math.rad(-60), 0, math.rad(40) + t * -1.2)
			for k, seg in ipairs(rings[r]) do
				local a = k / #rings[r] * math.pi * 2 + t * (r == 1 and 2.5 or -2)
				seg.CFrame = CFrame.new(sp) * tilt * CFrame.new(math.cos(a) * rad, 0, math.sin(a) * rad) * CFrame.Angles(0, -a, 0)
			end
		end
		for i = 1, n do
			local op = orb(i)
			local vis = t < delay and 1 or (t > t3 and 1 or 0)
			orbs[i].Transparency = vis
			halos[i].Transparency = vis == 1 and 1 or 0.2
			orbs[i].CFrame = CFrame.new(op)
			halos[i].CFrame = CFrame.new(op) * CFrame.Angles(t * 4, t * 3, 0)
			-- 별과 작은 별 사이를 잇는 번개 줄 (가끔)
			if vis == 0 and math.random() < 0.05 then
				Fx.lightning(sp, op, math.random() < 0.5 and c or c2, 0.25)
			end
		end
	end)
	Fx.sound("deflect", 0.9, 0.6, center)
	task.delay(delay, function()
		Fx.ring(top, c2, 4, 20, 0.4)
		Fx.breakSound("whoosh", 0.6, 1.4, center)
	end)
end
local function starBeam(data: any)
	local S = stars[data.id]
	local to: Vector3 = data.to
	if not S or not near(to, 260) then
		return
	end
	local c, c2 = colors(data.style)
	local from = S.orb(data.i or 1)
	local b = beam(from, to, 0.9, WHITE, 0)
	fadeOut(b, 0.22, { Size = Vector3.new(0.1, 0.1, b.Size.Z) })
	local b2 = beam(from, to, 2.2, c, 0.55)
	fadeOut(b2, 0.3)
	Fx.lightning(from, to, c2, 0.5)
	Fx.burst("spark", to, c2, 6, 0.8)
	Fx.ring(ground(to) + Vector3.new(0, 0.3, 0), c, 1, 7, 0.3)
	if math.random() < 0.35 then
		Fx.sound("hit", 0.45, 1.7, to)
	end
end
local function starCrash(data: any)
	local at: Vector3 = data.at
	local S = stars[data.id]
	if S then
		-- 떨어지는 걸 다 보이고 정리한다
		task.delay(0.15, function()
			S.done = true
		end)
	end
	if not near(at, 280) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 20
	task.delay(0.12, function()
		local g = ground(at)
		local s = part(Vector3.new(3, 3, 3), WHITE, Enum.Material.Neon, 0, "ball")
		s.CFrame = CFrame.new(g)
		fadeOut(s, 0.5, { Size = Vector3.new(1, 1, 1) * R * 1.6 })
		local s2 = part(Vector3.new(3, 3, 3), c, Enum.Material.ForceField, 0.1, "ball")
		s2.CFrame = CFrame.new(g)
		fadeOut(s2, 0.7, { Size = Vector3.new(1, 1, 1) * R * 2.3 })
		-- 하늘로 솟는 빛기둥과 땅을 달리는 번개 열둘
		local col = column(g, 60, 6, c2, 0.1)
		fadeOut(col, 0.6, { Size = Vector3.new(60, 0.5, 0.5) })
		for k = 1, 12 do
			local a = (k / 12) * math.pi * 2
			local e = g + Vector3.new(math.cos(a) * R, 0.3, math.sin(a) * R)
			Fx.lightning(g + Vector3.new(0, 0.5, 0), e, k % 2 == 0 and c or c2, 0.8)
			task.delay(0.05 * (k % 4), function()
				Fx.lightning(e + Vector3.new(0, 16, 0), e, c2, 0.5)
			end)
		end
		impact(at, R, c, c2, 2.4)
		Fx.flash(at, c2, 110, 10, 0.7)
		Fx.breakSound("rock", 1, 0.75, at)
		Fx.sound("heavy", 1, 0.6, at)
		shakeNear(at, 2.6, 140)
	end)
end
------------------------------------------------------------------------
-- 2.6판 무극신권: 음양탄 · 태극선회 · 태극인 (흑과 백)
------------------------------------------------------------------------
local INK = Color3.fromRGB(14, 14, 20)
local function yinOrb(black: boolean, d: number): (BasePart, BasePart)
	local core = part(Vector3.new(d, d, d), black and INK or WHITE, black and Enum.Material.SmoothPlastic or Enum.Material.Neon, 0, "ball")
	local halo = part(Vector3.new(d, d, d) * 1.7, black and WHITE or INK, Enum.Material.ForceField, 0.15, "ball")
	return core, halo
end
-- 지나간 자리에 남는 작은 흑백 점
local function dot(at: Vector3, black: boolean, d: number, life: number)
	local p = part(Vector3.new(d, d, d), black and INK or WHITE, black and Enum.Material.SmoothPlastic or Enum.Material.Neon, 0.1, "ball")
	p.CFrame = CFrame.new(at)
	fadeOut(p, life, { Size = Vector3.new(0.1, 0.1, 0.1) })
end
-- 태극 문양 (판의 위가 +Y). 흰 원 위에 왼쪽 반을 검게 덮고, 위 작은 원은 검게, 아래 작은 원은 희게, 눈 둘
-- 뒤집혀도 보이도록 아래쪽에도 같은 층을 거꾸로 쌓는다 (테두리는 얇게 사이에 끼운다)
type Piece = { p: BasePart, cf: CFrame }
local function buildTaiji(R: number, rim: Color3): { Piece }
	local out: { Piece } = {}
	local UP = CFrame.Angles(0, 0, math.rad(90))
	local function both(i: number, make: () -> BasePart, x: number, z: number, rot: CFrame)
		for _, sgn in ipairs({ 1, -1 }) do
			table.insert(out, { p = make(), cf = CFrame.new(x, sgn * 0.02 * i, z) * rot })
		end
	end
	local function circle(i: number, r: number, z: number, color: Color3, mat: Enum.Material)
		both(i, function()
			return part(Vector3.new(0.3, r * 2, r * 2), color, mat, 0, "cyl")
		end, 0, z, UP)
	end
	table.insert(out, { p = part(Vector3.new(0.2, (R + 0.8) * 2, (R + 0.8) * 2), rim, Enum.Material.Neon, 0, "cyl"), cf = UP })
	circle(1, R, 0, WHITE, Enum.Material.Neon)
	local strips = 14
	for k = 1, strips do
		local x0 = -R + (k - 1) * R / strips
		local w = R / strips
		local h = 2 * math.sqrt(math.max(0, R * R - x0 * x0))
		if h > 0.2 then
			both(2, function()
				return part(Vector3.new(w + 0.05, 0.3, h), INK, Enum.Material.SmoothPlastic, 0)
			end, x0 + w / 2, 0, CFrame.identity)
		end
	end
	circle(3, R / 2, R / 2, INK, Enum.Material.SmoothPlastic)
	circle(4, R / 2, -R / 2, WHITE, Enum.Material.Neon)
	circle(5, R / 8, R / 2, WHITE, Enum.Material.Neon)
	circle(5, R / 8, -R / 2, INK, Enum.Material.SmoothPlastic)
	return out
end
local function placeTaiji(pieces: { Piece }, cf: CFrame)
	for _, pc in ipairs(pieces) do
		pc.p.CFrame = cf * pc.cf
	end
end
local function dropTaiji(pieces: { Piece }, life: number)
	for _, pc in ipairs(pieces) do
		fadeOut(pc.p, life)
	end
end

local function yyShot(data: any)
	local from: Vector3 = data.from
	if not near(from, 220) then
		return
	end
	local c = colors(data.style)
	local dir: Vector3 = flat(data.dir or Vector3.new(0, 0, -1))
	local L = data.length or 30
	local travel = data.travel or 0.45
	local delay = data.delay or 0.15
	local right = dir:Cross(Vector3.new(0, 1, 0)).Unit
	local up = Vector3.new(0, 1, 0)
	local bk, bh = yinOrb(true, 1.6)
	local wk, wh = yinOrb(false, 1.6)
	local t0 = os.clock()
	local frame = 0
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp((t - delay) / travel, 0, 1)
		local th = u * math.pi * 6 + t * 4
		local rad = 1.8 * (1 - u * 0.5)
		local axis = from + dir * (L * u)
		local off = right * math.cos(th) * rad + up * math.sin(th) * rad
		bk.CFrame, bh.CFrame = CFrame.new(axis + off), CFrame.new(axis + off)
		wk.CFrame, wh.CFrame = CFrame.new(axis - off), CFrame.new(axis - off)
		frame += 1
		if u > 0 and u < 1 and frame % 2 == 0 then
			dot(axis + off, true, 0.9, 0.35)
			dot(axis - off, false, 0.9, 0.35)
		end
		if u >= 1 then
			conn:Disconnect()
			for _, p in ipairs({ bk, bh, wk, wh }) do
				p:Destroy()
			end
			-- 부딪친다: 작은 태극이 빠르게 돌며 터지고, 흑백 고리가 안으로 조였다가 밖으로 퍼진다
			local at = axis
			local R = data.radius or 8
			local pieces = buildTaiji(2.2, c)
			local s0 = os.clock()
			local c2conn: RBXScriptConnection
			c2conn = RunService.Heartbeat:Connect(function()
				local k = os.clock() - s0
				if k > 0.5 then
					c2conn:Disconnect()
					return
				end
				placeTaiji(pieces, CFrame.lookAt(at, at - dir) * CFrame.Angles(math.rad(90), 0, 0) * CFrame.Angles(0, k * 30, 0))
			end)
			dropTaiji(pieces, 0.5)
			Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), INK, R * 2.4, 2, 0.25)
			task.delay(0.2, function()
				Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), WHITE, 2, R * 2.4, 0.4)
				Fx.ring(ground(at) + Vector3.new(0, 0.35, 0), INK, 2, R * 2, 0.45)
			end)
			Fx.burst("spark", at, WHITE, 10, 1)
			Fx.breakSound("whoosh", 0.6, 1.5, at)
			shakeNear(at, 0.5, 60)
		end
	end)
	Fx.sound("swing", 0.6, 0.7, from)
end

local function yyOrbit(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c = colors(data.style)
	local R = data.radius or 16
	local dur = data.dur or 1.1
	local delay = data.delay or 0.1
	local turns = data.turns or 1.5
	local bk, bh = yinOrb(true, 2.4)
	local wk, wh = yinOrb(false, 2.4)
	local t0 = os.clock()
	local frame = 0
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp((t - delay) / dur, 0, 1)
		local r = R * math.sin(u * math.pi)
		local a = u * turns * math.pi * 2
		local bob = Vector3.new(0, math.sin(t * 8) * 0.6, 0)
		local pb = at + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r) + bob
		local pw = at + Vector3.new(math.cos(a + math.pi) * r, 0, math.sin(a + math.pi) * r) - bob
		bk.CFrame, bh.CFrame = CFrame.new(pb), CFrame.new(pb)
		wk.CFrame, wh.CFrame = CFrame.new(pw), CFrame.new(pw)
		frame += 1
		if u > 0 and u < 1 then
			if frame % 2 == 0 then
				dot(pb, true, 1.4, 0.5)
				dot(pw, false, 1.4, 0.5)
			end
			-- 땅에 소용돌이 자국
			if frame % 3 == 0 then
				local g1 = part(Vector3.new(0.12, 1.6, 1.6), INK, Enum.Material.SmoothPlastic, 0.2, "cyl")
				g1.CFrame = CFrame.new(ground(pb) + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
				fadeOut(g1, 0.9)
				local g2 = part(Vector3.new(0.12, 1.6, 1.6), WHITE, Enum.Material.Neon, 0.2, "cyl")
				g2.CFrame = CFrame.new(ground(pw) + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
				fadeOut(g2, 0.9)
			end
		end
		if u >= 1 then
			conn:Disconnect()
			for _, p in ipairs({ bk, bh, wk, wh }) do
				p:Destroy()
			end
			-- 되돌아와 하나로: 고리가 안으로 조이고, 발밑에 태극이 번쩍인다
			Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), WHITE, R * 2, 3, 0.3)
			Fx.ring(ground(at) + Vector3.new(0, 0.35, 0), INK, R * 1.8, 3, 0.35)
			local pieces = buildTaiji(5, c)
			placeTaiji(pieces, CFrame.new(ground(at) + Vector3.new(0, 0.2, 0)))
			dropTaiji(pieces, 0.6)
			Fx.burst("spark", at, c, 12, 1)
			Fx.sound("heavy", 0.7, 1.2, at)
			shakeNear(at, 0.6, 60)
		end
	end)
	Fx.sound("swing", 0.7, 0.6, at)
end

local function taijiSeal(data: any)
	local at: Vector3 = data.at
	if not near(at, 280) then
		return
	end
	local c = colors(data.style)
	local R = data.radius or 30
	local delay, liftAt, hitAt = data.delay or 0.35, data.liftAt or 1.1, data.hitAt or 1.75
	local base = ground(at) + Vector3.new(0, 0.2, 0)
	local pieces = buildTaiji(R, c)
	for _, pc in ipairs(pieces) do
		pc.p.Transparency = 1
		tween(pc.p, delay, { Transparency = 0 })
	end
	-- 세상의 빛깔이 빠진다 (가까이 있는 사람만)
	local cc: ColorCorrectionEffect? = nil
	if near(at, 160) then
		local e = Instance.new("ColorCorrectionEffect")
		e.Name = "KwonTaiji"
		e.Parent = game:GetService("Lighting")
		tween(e, delay, { Saturation = -1, Contrast = 0.25 })
		cc = e
	end
	Fx.ring(base, WHITE, 2, R * 2.2, delay + 0.1)
	Fx.sound("deflect", 0.9, 0.5, at)
	local t0 = os.clock()
	local slammed = false
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > hitAt + 0.8 then
			conn:Disconnect()
			return
		end
		local spin
		if t < liftAt then
			spin = t * 0.9
		else
			spin = liftAt * 0.9 + (t - liftAt) * (t - liftAt) * 9
		end
		local cf
		local fall = hitAt - 0.14
		if t < liftAt then
			cf = CFrame.new(base) * CFrame.Angles(0, spin, 0)
		elseif t < fall then
			-- 떠올라 뒤집힌다
			local k = (t - liftAt) / (fall - liftAt)
			local e = 1 - (1 - k) * (1 - k)
			cf = CFrame.new(base + Vector3.new(0, 26 * e, 0)) * CFrame.Angles(math.pi * e, spin, 0)
		elseif t < hitAt then
			local k = (t - fall) / 0.14
			cf = CFrame.new(base + Vector3.new(0, 26 * (1 - k * k), 0)) * CFrame.Angles(math.pi, spin, 0)
		else
			cf = CFrame.new(base) * CFrame.Angles(math.pi, spin, 0)
		end
		placeTaiji(pieces, cf)
		-- 태극에서 흑백 기운이 솟는다
		if t > delay and t < liftAt and math.random() < 0.5 then
			local a, r = math.random() * math.pi * 2, math.sqrt(math.random()) * R
			local p0 = base + Vector3.new(math.cos(a) * r, 0.5, math.sin(a) * r)
			local black = math.random() < 0.5
			local q = part(Vector3.new(0.7, 0.7, 0.7), black and INK or WHITE, black and Enum.Material.SmoothPlastic or Enum.Material.Neon, 0.1, "ball")
			q.CFrame = CFrame.new(p0)
			fadeOut(q, 0.8, { CFrame = CFrame.new(p0 + Vector3.new(0, 7, 0)), Size = Vector3.new(0.2, 0.2, 0.2) })
		end
		if t >= hitAt and not slammed then
			slammed = true
			-- 도장이 찍힌다
			Fx.ring(base + Vector3.new(0, 0.2, 0), WHITE, R * 1.4, R * 2.6, 0.45)
			Fx.ring(base + Vector3.new(0, 0.25, 0), INK, R * 1.2, R * 2.3, 0.5)
			local col = column(base, 70, 5, WHITE, 0.05)
			fadeOut(col, 0.5, { Size = Vector3.new(70, 0.4, 0.4) })
			Fx.burst("spark", at, WHITE, 24, 2)
			Fx.flash(at, WHITE, 120, 10, 0.5)
			Fx.breakSound("boom", 1, 0.6, at)
			Fx.sound("heavy", 1, 0.5, at)
			shakeNear(at, 2.8, 150)
			local e = cc
			if e then
				-- 한순간 흑백이 뒤집혔다가 빛깔이 돌아온다
				e.Contrast = 1
				e.Brightness = 0.3
				tween(e, 0.25, { Contrast = 0.25, Brightness = 0 })
				task.delay(0.6, function()
					tween(e, 0.8, { Saturation = 0, Contrast = 0 })
					task.delay(0.85, function()
						e:Destroy()
					end)
				end)
			end
			-- 흑과 백의 물결
			task.delay(0.3, function()
				for k = 0, 2 do
					task.delay(k * 0.08, function()
						Fx.ring(base + Vector3.new(0, 0.3, 0), k % 2 == 0 and INK or WHITE, R * 0.6, (R + 6) * 2, 0.5)
					end)
				end
			end)
			dropTaiji(pieces, 0.7)
		end
	end)
	-- 기술이 끊기면 빛깔만은 꼭 돌려놓는다
	task.delay(hitAt + 3, function()
		if cc and cc.Parent then
			cc:Destroy()
		end
		for _, pc in ipairs(pieces) do
			if pc.p.Parent then
				pc.p:Destroy()
			end
		end
	end)
end

-- 심판의 벼락: 겨눈 적마다 머리 위에 돌아가는 조준 고리
local function lockOn(data: any)
	local c, c2 = colors(data.style)
	local dur = data.dur or 2.6
	for _, m in ipairs(data.targets or {}) do
		local r = rootOf(m)
		if r and near(r.Position, 220) then
			local ring = part(Vector3.new(0.2, 7, 7), c2, Enum.Material.Neon, 0.35, "cyl")
			local inner = part(Vector3.new(0.21, 4, 4), c, Enum.Material.Neon, 0.6, "cyl")
			local bars: { BasePart } = {}
			for k = 1, 4 do
				bars[k] = part(Vector3.new(0.3, 0.3, 1.8), c2, Enum.Material.Neon, 0.1)
			end
			local t0 = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function()
				local t = os.clock() - t0
				if t > dur or not r.Parent then
					conn:Disconnect()
					ring:Destroy()
					inner:Destroy()
					for _, b in ipairs(bars) do
						b:Destroy()
					end
					return
				end
				local g = ground(r.Position) + Vector3.new(0, 0.2, 0)
				ring.CFrame = CFrame.new(g) * CFrame.Angles(0, t * 2, math.rad(90))
				inner.CFrame = CFrame.new(g + Vector3.new(0, 0.01, 0)) * CFrame.Angles(0, -t * 3, math.rad(90))
				for k = 1, 4 do
					local a = t * 2 + k * math.pi / 2
					local p = g + Vector3.new(math.cos(a) * 4.3, 0, math.sin(a) * 4.3)
					bars[k].CFrame = CFrame.lookAt(p, g)
				end
			end)
		end
	end
end
local function judgeBolt(data: any)
	local at: Vector3 = data.at
	if not near(at, 240) then
		return
	end
	local c, c2 = colors(data.style)
	local g = ground(at)
	local R = data.radius or 7
	-- 하늘 끝에서 내려오는 굵은 벼락 기둥 (흰 심 + 보랏빛 겉)
	local core = column(g, 160, 1.6, WHITE, 0)
	local outer = column(g, 160, R * 0.9, c, 0.35)
	fadeOut(core, 0.25, { Size = Vector3.new(160, 0.2, 0.2) })
	fadeOut(outer, 0.4, { Size = Vector3.new(160, R * 1.6, R * 1.6) })
	Fx.lightning(g + Vector3.new(0, 120, 0), g, c2, 1)
	impact(at, R, c, c2, 1.2)
	Fx.flash(at, c2, 60, 6, 0.3)
	if (data.i or 1) % 2 == 1 then
		Fx.breakSound("boom", 0.6, 1.3, at)
	end
	shakeNear(at, 0.9, 100)
end

------------------------------------------------------------------------
-- 초·벽력신권 뇌고천무 (초 오의, 2.3판): 등 뒤 하늘의 뇌고 여덟, 칠 때마다 벼락, 마지막 뇌구
------------------------------------------------------------------------
type Drum = { body: BasePart, face: BasePart, rims: { BasePart }, sigil: { BasePart }, pulse: number }
type DrumSet = { drums: { Drum }, links: { BasePart }, core: BasePart, r: BasePart, born: number, gather: number?, spin: number }
local drumSets: { [Instance]: DrumSet } = {}
local function drumCenter(ds: DrumSet): (Vector3, Vector3, Vector3)
	local look = flat(ds.r.CFrame.LookVector)
	local right = Vector3.new(-look.Z, 0, look.X)
	return ds.r.Position - look * 7 + Vector3.new(0, 15, 0), look, right
end
local function drumPos(ds: DrumSet, i: number): (Vector3, Vector3)
	local c, look, right = drumCenter(ds)
	local n = #ds.drums
	local R = 13 * (1 - (ds.gather or 0))
	local a = (i - 1) / n * math.pi * 2 + ds.spin
	return c + (right * math.cos(a) + Vector3.yAxis * math.sin(a)) * R, look
end
local function drumRing(data: any)
	local m = data.m
	local r = rootOf(m)
	if not r or not near(r.Position, 260) then
		return
	end
	local old = drumSets[m]
	if old then
		drumSets[m] = nil
		for _, d in ipairs(old.drums) do
			d.body:Destroy()
			d.face:Destroy()
		end
	end
	local c, c2 = colors(data.style)
	local ds: DrumSet = { drums = {}, links = {}, core = part(Vector3.new(1, 1, 1), WHITE, Enum.Material.Neon, 0.1, "ball"), r = r, born = os.clock(), gather = nil, spin = 0 }
	local n = data.n or 8
	local WOOD = Color3.fromRGB(105, 35, 40)
	local GOLD = Color3.fromRGB(255, 220, 120)
	for _ = 1, n do
		local d: Drum = {
			body = part(Vector3.new(2.4, 4.6, 4.6), WOOD, Enum.Material.Wood, 0, "cyl"),
			face = part(Vector3.new(0.2, 4.2, 4.2), c2, Enum.Material.Neon, 0.35, "cyl"),
			rims = { part(Vector3.new(0.3, 4.9, 4.9), GOLD, Enum.Material.Metal, 0, "cyl"), part(Vector3.new(0.3, 4.9, 4.9), GOLD, Enum.Material.Metal, 0, "cyl") },
			sigil = { part(Vector3.new(0.1, 1.6, 0.35), c, Enum.Material.Neon, 0), part(Vector3.new(0.1, 1.6, 0.35), c, Enum.Material.Neon, 0), part(Vector3.new(0.1, 1.6, 0.35), c, Enum.Material.Neon, 0) },
			pulse = 0,
		}
		table.insert(ds.drums, d)
		table.insert(ds.links, part(Vector3.new(0.3, 0.3, 1), c, Enum.Material.Neon, 0.3))
	end
	drumSets[m] = ds
	local dur = data.dur or 5
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function(dt: number)
		local t = os.clock() - ds.born
		if drumSets[m] ~= ds or t > dur + 1.5 or not r.Parent then
			conn:Disconnect()
			if drumSets[m] == ds then
				drumSets[m] = nil
			end
			for _, d in ipairs(ds.drums) do
				for _, p in ipairs({ d.body, d.face, d.rims[1], d.rims[2], d.sigil[1], d.sigil[2], d.sigil[3] }) do
					fadeOut(p, 0.3)
				end
			end
			for _, l in ipairs(ds.links) do
				fadeOut(l, 0.3)
			end
			fadeOut(ds.core, 0.3)
			return
		end
		ds.spin += dt * (ds.gather and 6 or 0.35)
		local appear = math.clamp(t / 0.6, 0, 1)
		local cen, look = drumCenter(ds)
		ds.core.CFrame = CFrame.new(cen)
		local cs = 2 + (ds.gather or 0) * 7 + math.sin(t * 12) * 0.3
		ds.core.Size = Vector3.new(cs, cs, cs)
		for i, d in ipairs(ds.drums) do
			local pos = drumPos(ds, i)
			pos = cen:Lerp(pos, appear)
			d.pulse = math.max(0, d.pulse - dt * 5)
			local k = 1 + d.pulse * 0.35
			-- 북은 쓴 사람이 보는 쪽을 향한다 (원기둥 축 = 앞뒤)
			local cf = CFrame.lookAt(pos, pos + look) * CFrame.Angles(0, math.rad(90), 0)
			d.body.Size = Vector3.new(2.4, 4.6 * k, 4.6 * k)
			d.body.CFrame = cf
			d.face.Size = Vector3.new(0.2, 4.2 * k, 4.2 * k)
			d.face.CFrame = cf * CFrame.new(-1.25, 0, 0)
			d.face.Transparency = 0.35 - d.pulse * 0.35
			d.face.Color = d.pulse > 0.5 and WHITE or c2
			d.rims[1].CFrame = cf * CFrame.new(-1.1, 0, 0)
			d.rims[2].CFrame = cf * CFrame.new(1.1, 0, 0)
			d.rims[1].Size = Vector3.new(0.3, 4.9 * k, 4.9 * k)
			d.rims[2].Size = d.rims[1].Size
			-- 앞면의 번개 무늬 (갈지자 셋)
			for j, sp in ipairs(d.sigil) do
				sp.CFrame = cf * CFrame.new(-1.38, (j - 2) * 1.1 * k, 0) * CFrame.Angles(math.rad(j == 2 and -30 or 30), 0, 0)
			end
			-- 이웃 북을 잇는 번개 줄
			local nxt = drumPos(ds, i % #ds.drums + 1)
			nxt = cen:Lerp(nxt, appear)
			local l = ds.links[i]
			l.Size = Vector3.new(0.3, 0.3, math.max(0.2, (nxt - pos).Magnitude))
			l.CFrame = CFrame.lookAt((pos + nxt) / 2, nxt)
			l.Transparency = 0.25 + math.random() * 0.4
		end
		if math.random() < 0.15 then
			local i = math.random(1, #ds.drums)
			Fx.lightning(cen, drumPos(ds, i), c, 0.3)
		end
	end)
	Fx.sound("deflect", 1, 0.3, r.Position)
end
local function drumBeat(data: any)
	local ds = drumSets[data.m]
	local c, c2 = colors(data.style)
	local at: Vector3 = data.at
	local from = at + Vector3.new(0, 40, 0)
	if ds then
		local d = ds.drums[data.drum or 1]
		if d then
			d.pulse = 1
			from = d.face.CFrame.Position
			Fx.ring(d.face.CFrame.Position, c2, 2, 12, 0.3, flat(ds.r.CFrame.LookVector))
		end
	end
	if not near(at, 260) then
		return
	end
	local g = ground(at)
	-- 북에서 적까지 벼락, 땅에 닿는 자리에 짧은 기둥
	Fx.lightning(from, g, WHITE, 0.8)
	Fx.lightning(from, g, c, 0.5)
	local col = column(g, 14, 2, c2, 0.1)
	fadeOut(col, 0.25, { Size = Vector3.new(14, 0.3, 0.3) })
	impact(at, data.radius or 7, c, c2, 0.9)
	-- 북소리: 낮게 둥, 박자가 오를수록 조금씩 높게
	Fx.sound("heavy", 0.9, 0.45 + (data.i or 1) * 0.02, at)
	shakeNear(at, 0.5 + (data.i or 1) * 0.03, 90)
	if data.shock and ds then
		local rg = ground(ds.r.Position)
		for k = 0, 2 do
			task.delay(k * 0.05, function()
				Fx.ring(rg + Vector3.new(0, 0.4 + k, 0), k == 1 and c2 or c, 3, (data.shockRadius or 13) * 2.2 + k * 4, 0.45)
			end)
		end
		if opts.flash then
			opts.flash(Color3.fromRGB(235, 225, 255), 0.25)
		end
		Fx.breakSound("boom", 0.6, 1.1, at)
	end
end
local function drumFinale(data: any)
	local ds = drumSets[data.m]
	local c, c2 = colors(data.style)
	local at: Vector3 = data.at
	local fall = data.fall or 0.3
	local from = at + Vector3.new(0, 30, 0)
	if ds then
		-- 북이 모두 한가운데로 모이며 빠르게 돈다
		ds.gather = 0
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local u = math.clamp((os.clock() - t0) / (fall * 0.8), 0, 1)
			ds.gather = u
			for _, d in ipairs(ds.drums) do
				d.pulse = 1
			end
			if u >= 1 then
				conn:Disconnect()
			end
		end)
		from = (drumCenter(ds))
		task.delay(fall * 0.8, function()
			if drumSets[data.m] == ds then
				drumSets[data.m] = nil
			end
		end)
	end
	if not near(at, 300) then
		return
	end
	-- 뇌구가 하늘에서 땅으로 떨어진다
	local orb = part(Vector3.new(9, 9, 9), WHITE, Enum.Material.Neon, 0, "ball")
	local shell = part(Vector3.new(14, 14, 14), c, Enum.Material.ForceField, 0.1, "ball")
	orb.CFrame = CFrame.new(from)
	shell.CFrame = CFrame.new(from)
	local g = ground(at)
	task.delay(fall * 0.6, function()
		tween(orb, fall * 0.4, { CFrame = CFrame.new(g + Vector3.new(0, 2, 0)) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(shell, fall * 0.4, { CFrame = CFrame.new(g + Vector3.new(0, 2, 0)) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
	task.delay(fall, function()
		orb:Destroy()
		shell:Destroy()
		local R = data.radius or 26
		local core = column(g, 200, 5, WHITE, 0)
		local outer = column(g, 200, R * 0.8, c, 0.3)
		fadeOut(core, 0.4, { Size = Vector3.new(200, 0.4, 0.4) })
		fadeOut(outer, 0.7, { Size = Vector3.new(200, R * 1.6, R * 1.6) })
		local dome = part(Vector3.new(4, 4, 4), c2, Enum.Material.Neon, 0.2, "ball")
		dome.CFrame = CFrame.new(g)
		fadeOut(dome, 0.6, { Size = Vector3.new(R * 2.4, R * 1.4, R * 2.4) })
		for k = 0, 4 do
			task.delay(k * 0.06, function()
				Fx.ring(g + Vector3.new(0, 0.4, 0), k % 2 == 0 and c or c2, 4, R * 2.4 + k * 10, 0.8)
			end)
		end
		for k = 1, 12 do
			local a = (k / 12) * math.pi * 2
			Fx.lightning(g + Vector3.new(0, 3, 0), g + Vector3.new(math.cos(a) * R * 1.1, 0, math.sin(a) * R * 1.1), k % 2 == 0 and c or c2, 0.8)
		end
		Fx.debris(g, 16, 50, Color3.fromRGB(80, 75, 95))
		Fx.flash(at, c2, 120, 10, 0.8)
		if opts.flash then
			opts.flash(WHITE, 0.5)
		end
		Fx.breakSound("boom", 1, 0.6, at)
		Fx.sound("heavy", 1, 0.3, at)
		shakeNear(at, 3, 160)
	end)
end

------------------------------------------------------------------------
-- 만목신권 (2.4판): 씨앗·가시덤불, 거대한 꽃봉오리, 나무 정령
------------------------------------------------------------------------
local BARK = Color3.fromRGB(92, 66, 44)
local LEAF = Color3.fromRGB(80, 170, 70)
local function thornBush(at: Vector3, radius: number, c: Color3, c2: Color3, linger: number?)
	local g = ground(at)
	local hold = 0.9 + (linger or 0)
	-- 가시 여덟이 땅에서 비스듬히 솟는다
	for k = 1, 8 do
		local a = k / 8 * math.pi * 2 + math.random() * 0.4
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		local tip = g + d * radius * 0.7 + Vector3.new(0, radius * 0.9, 0)
		local thorn = beam(g + d * 0.5, g + d * 0.5 + Vector3.new(0, 0.1, 0), 0.6, BARK, 0, Enum.Material.Wood)
		tween(thorn, 0.12, { Size = Vector3.new(0.6, 0.6, (tip - g).Magnitude), CFrame = CFrame.lookAt((g + tip) / 2, tip) }, Enum.EasingStyle.Back)
		local point = part(Vector3.new(0.3, 0.3, 1.2), c2, Enum.Material.Neon, 0)
		point.CFrame = CFrame.lookAt(tip, tip + (tip - g).Unit)
		task.delay(hold, function()
			fadeOut(thorn, 0.4, { CFrame = thorn.CFrame * CFrame.new(0, 0, (tip - g).Magnitude * 0.3) })
			fadeOut(point, 0.3)
		end)
	end
	local leaves = part(Vector3.new(1, 1, 1), c, Enum.Material.Grass, 0.1, "ball")
	leaves.CFrame = CFrame.new(g + Vector3.new(0, 0.8, 0))
	tween(leaves, 0.15, { Size = Vector3.new(radius * 1.3, radius * 0.6, radius * 1.3) }, Enum.EasingStyle.Back)
	-- 덤불 위로 작은 꽃 셋
	for k = 1, 3 do
		local fl = part(Vector3.new(0.8, 0.8, 0.8), k == 2 and Color3.fromRGB(255, 240, 120) or Color3.fromRGB(255, 170, 210), Enum.Material.Neon, 0, "ball")
		fl.CFrame = CFrame.new(g + Vector3.new(math.cos(k * 2.1) * radius * 0.35, radius * 0.55, math.sin(k * 2.1) * radius * 0.35))
		task.delay(hold, function()
			fadeOut(fl, 0.3)
		end)
	end
	task.delay(hold, function()
		fadeOut(leaves, 0.4)
	end)
	Fx.burst("spark", at, c, 10, 1)
end
local function seedShot(data: any)
	local from: Vector3 = data.from
	if not near(from, 220) then
		return
	end
	local _, c2 = colors(data.style)
	task.delay(data.delay or 0.18, function()
		for i, at in ipairs(data.spots or {}) do
			local seed = part(Vector3.new(0.7, 0.7, 0.9), Color3.fromRGB(150, 110, 60), Enum.Material.Wood, 0, "ball")
			local glow = part(Vector3.new(1.1, 1.1, 1.1), c2, Enum.Material.Neon, 0.6, "ball")
			seed.CFrame = CFrame.new(from + Vector3.new(0, 1.5, 0))
			glow.CFrame = seed.CFrame
			local to = ground(at) + Vector3.new(0, 0.4, 0)
			tween(seed, 0.15 + i * 0.01, { CFrame = CFrame.new(to) }, Enum.EasingStyle.Linear)
			tween(glow, 0.15 + i * 0.01, { CFrame = CFrame.new(to) }, Enum.EasingStyle.Linear)
			task.delay((data.sprout or 0.5) - 0.02, function()
				seed:Destroy()
				glow:Destroy()
			end)
		end
		Fx.sound("swing", 0.5, 1.6, from)
	end)
end
local function thornSprout(data: any)
	local c, c2 = colors(data.style)
	for _, at in ipairs(data.spots or {}) do
		if near(at, 200) then
			thornBush(at, data.radius or 6, c, c2, data.linger)
		end
	end
	local first = (data.spots or {})[1]
	if first then
		Fx.sound("hit", 0.7, 0.8, first)
	end
end
-- 거대한 꽃봉오리: 줄기와 잎 둘이 솟고, 꽃잎 여섯이 닫혀 있다가 활짝 펴진다
local buds: { [string]: { stem: BasePart, petals: { BasePart }, core: BasePart, leaves: { BasePart }, g: Vector3, R: number } } = {}
local PETAL = Color3.fromRGB(255, 170, 210)
local function petalCF(g: Vector3, R: number, k: number, open: number): CFrame
	local a = k / 6 * math.pi * 2
	local center = g + Vector3.new(0, R * 0.9, 0)
	-- open 0 = 위로 모여 닫힘, 1 = 바깥으로 눕도록 활짝
	local tilt = math.rad(10 + 75 * open)
	return CFrame.new(center) * CFrame.Angles(0, a, 0) * CFrame.Angles(-tilt, 0, 0) * CFrame.new(0, R * 0.32, 0)
end
local function budRise(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local R = (data.radius or 16) * 0.65
	local g = ground(at)
	local key = keyOf(at)
	local stem = part(Vector3.new(R * 0.9, 1.2, 1.2), Color3.fromRGB(70, 140, 60), Enum.Material.SmoothPlastic, 0, "cyl")
	stem.CFrame = CFrame.new(g + Vector3.new(0, R * 0.45, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local leaves = {}
	for _, x in ipairs({ -1, 1 }) do
		local l = part(Vector3.new(R * 0.7, 0.2, R * 0.3), LEAF, Enum.Material.SmoothPlastic, 0, "ball")
		l.CFrame = CFrame.new(g + Vector3.new(x * R * 0.35, R * 0.25, 0)) * CFrame.Angles(0, 0, x * math.rad(-25))
		table.insert(leaves, l)
	end
	local petals = {}
	for k = 1, 6 do
		local p = part(Vector3.new(R * 0.55, R * 0.75, 0.3), k % 2 == 0 and PETAL or c2:Lerp(PETAL, 0.5), Enum.Material.SmoothPlastic, 0, "ball")
		p.CFrame = petalCF(g, R, k, 0)
		table.insert(petals, p)
	end
	local core = part(Vector3.new(R * 0.4, R * 0.4, R * 0.4), Color3.fromRGB(255, 230, 120), Enum.Material.Neon, 0, "ball")
	core.CFrame = CFrame.new(g + Vector3.new(0, R * 0.95, 0))
	buds[key] = { stem = stem, petals = petals, core = core, leaves = leaves, g = g, R = R }
	-- 땅에서 솟아오른다
	local all = { stem, core }
	for _, p in ipairs(petals) do
		table.insert(all, p)
	end
	for _, p in ipairs(leaves) do
		table.insert(all, p)
	end
	for _, p in ipairs(all) do
		local cf = p.CFrame
		p.CFrame = cf - Vector3.new(0, R * 1.4, 0)
		tween(p, (data.delay or 0.7) * 0.6, { CFrame = cf }, Enum.EasingStyle.Back)
	end
	Fx.burst("dust", g + Vector3.new(0, 0.5, 0), Color3.fromRGB(140, 120, 90), 14, 1.4)
	Fx.sound("heavy", 0.6, 0.9, at)
	local _ = c
end
local function budBloom(data: any)
	local key = keyOf(data.at)
	local b = buds[key]
	local c, c2 = colors(data.style)
	if b then
		buds[key] = nil
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local u = math.clamp((os.clock() - t0) / 0.25, 0, 1)
			for k, p in ipairs(b.petals) do
				p.CFrame = petalCF(b.g, b.R, k, 1 - (1 - u) ^ 2)
			end
			if u >= 1 then
				conn:Disconnect()
			end
		end)
		task.delay((data.sleep or 2) * 0.6, function()
			for _, p in ipairs(b.petals) do
				fadeOut(p, 0.6)
			end
			for _, p in ipairs(b.leaves) do
				fadeOut(p, 0.6)
			end
			fadeOut(b.stem, 0.6)
			fadeOut(b.core, 0.4)
		end)
	end
	if not near(data.at, 220) then
		return
	end
	-- 꽃가루 구름 (노란 빛 가루가 둘레로 퍼진다) + 잠든 적 위의 'z'
	local R = data.radius or 14
	local g = ground(data.at)
	local cloud = part(Vector3.new(2, 2, 2), Color3.fromRGB(255, 240, 150), Enum.Material.ForceField, 0.2, "ball")
	cloud.CFrame = CFrame.new(g + Vector3.new(0, 3, 0))
	fadeOut(cloud, 0.9, { Size = Vector3.new(R * 2.2, R * 0.8, R * 2.2) })
	for k = 0, 2 do
		task.delay(k * 0.08, function()
			Fx.ring(g + Vector3.new(0, 0.4, 0), k == 1 and c2 or Color3.fromRGB(255, 240, 150), 2, R * 2.2 + k * 4, 0.6)
		end)
	end
	Fx.burst("glitter", g + Vector3.new(0, 4, 0), Color3.fromRGB(255, 240, 150), 40, 2.4)
	Fx.text(g + Vector3.new(0, 10, 0), "Zzz", Color3.fromRGB(200, 220, 255), 34, 1.6)
	Fx.sound("ping", 0.8, 1.2, data.at)
	local _ = c
end
-- 나무 정령: 그루터기 다리, 줄기 몸, 옹이 얼굴의 초록 눈, 머리와 어깨의 잎 덤불, 가지 뿔, 굵은 팔과 주먹
type TPiece = { p: BasePart, limb: string, off: CFrame }
local function treantRise(data: any)
	local at: Vector3 = data.at
	if not near(at, 260) then
		return
	end
	local c, c2 = colors(data.style)
	local dir: Vector3 = data.dir or Vector3.new(0, 0, -1)
	local S = 3.6
	local g = ground(at) - dir * 14
	local face = CFrame.lookAt(g, g + dir)
	local pieces: { TPiece } = {}
	local function add(limb: string, size: Vector3, off: CFrame, color: Color3, mat: Enum.Material?, alpha: number?, shape: string?)
		local p = part(size * S, color, mat or Enum.Material.Wood, alpha or 0, shape)
		table.insert(pieces, { p = p, limb = limb, off = CFrame.new(off.Position * S) * off.Rotation })
	end
	local dark = BARK:Lerp(Color3.new(0, 0, 0), 0.25)
	for _, x in ipairs({ -1, 1 }) do
		add("B", Vector3.new(1.7, 3.2, 1.7), CFrame.new(x * 1.2, 1.5, 0) * CFrame.Angles(0, 0, x * math.rad(8)), dark)
		add("B", Vector3.new(0.6, 0.6, 2.4), CFrame.new(x * 1.8, 0.3, -0.8) * CFrame.Angles(math.rad(-20), x * math.rad(25), 0), dark)
	end
	add("B", Vector3.new(3.2, 5.2, 2.6), CFrame.new(0, 5.4, 0) * CFrame.Angles(math.rad(-6), 0, 0), BARK)
	add("B", Vector3.new(2.4, 2.2, 2.2), CFrame.new(0, 9.0, -0.3), dark)
	for _, x in ipairs({ -1, 1 }) do
		add("B", Vector3.new(0.45, 0.35, 0.12), CFrame.new(x * 0.5, 9.2, -1.42), c2, Enum.Material.Neon)
		add("B", Vector3.new(0.35, 2.6, 0.35), CFrame.new(x * 0.8, 11, 0.1) * CFrame.Angles(math.rad(-15), 0, x * math.rad(-30)), BARK)
		add("B", Vector3.new(3.2, 2.4, 3.2), CFrame.new(x * 2.4, 8.4, 0.4), LEAF:Lerp(c, 0.3), Enum.Material.Grass, 0, "ball")
	end
	add("B", Vector3.new(0.8, 0.2, 0.12), CFrame.new(0, 8.5, -1.42), Color3.fromRGB(30, 20, 15), Enum.Material.SmoothPlastic)
	add("B", Vector3.new(4.4, 3.2, 4.0), CFrame.new(0, 11.2, 0.5), LEAF, Enum.Material.Grass, 0, "ball")
	add("B", Vector3.new(1.4, 1.4, 1.4), CFrame.new(0, 5.8, -1.35), c2, Enum.Material.Neon, 0.3, "ball")
	for _, limb in ipairs({ "R", "L" }) do
		add(limb, Vector3.new(1.2, 3.2, 1.2), CFrame.new(0, -1.6, 0), BARK)
		add(limb, Vector3.new(1.1, 3.0, 1.1), CFrame.new(0, -4.4, -0.2), dark)
		add(limb, Vector3.new(2.0, 1.7, 2.0), CFrame.new(0, -6.3, -0.3), BARK)
		for k = -1, 1 do
			add(limb, Vector3.new(0.3, 1.2, 0.3), CFrame.new(k * 0.6, -7.4, -0.5) * CFrame.Angles(math.rad(20), 0, 0), dark)
		end
		add(limb, Vector3.new(1.6, 1.2, 1.6), CFrame.new(0, 0.2, 0.2), LEAF, Enum.Material.Grass, 0, "ball")
	end
	local SH = { R = Vector3.new(2.6, 7.6, 0), L = Vector3.new(-2.6, 7.6, 0) }
	local rise = data.rise or 0.9
	local sweep = data.sweep or 1.6
	local roots = data.roots or 2.4
	local dur = data.dur or 3.3
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > dur + 0.8 then
			conn:Disconnect()
			for _, pc in ipairs(pieces) do
				pc.p:Destroy()
			end
			return
		end
		-- 솟아오르기 · 가라앉기
		local up = 1 - (1 - math.clamp(t / rise, 0, 1)) ^ 3
		local down = math.clamp((t - dur) / 0.8, 0, 1)
		local y = -13 * S * (1 - up) - 13 * S * down
		-- 휩쓸기: 몸을 크게 돌린다
		local yaw = 0
		if t > sweep - 0.3 and t < sweep + 0.25 then
			local u = math.clamp((t - (sweep - 0.3)) / 0.45, 0, 1)
			yaw = -1.1 + 2.2 * u * u
		elseif t >= sweep + 0.25 then
			yaw = 1.1 * math.max(0, 1 - (t - sweep - 0.25) / 0.4)
		end
		local root = face * CFrame.new(0, y, 0) * CFrame.Angles(0, yaw, 0)
		-- 팔: 오른팔을 치켜들었다 내리치고, 휩쓸 때는 앞으로 뻗고, 뿌리 때는 두 팔을 치켜들었다 땅을 친다
		local aR, aL = 0.4, 0.4
		if t < rise - 0.18 then
			aR = 0.4 + 2.5 * math.clamp(t / (rise - 0.18), 0, 1)
		elseif t < rise then
			aR = 2.9 - 2.0 * ((t - (rise - 0.18)) / 0.18)
		elseif t < sweep - 0.3 then
			aR, aL = 0.9 + 0.7 * math.clamp((t - rise) / 0.3, 0, 1), 1.6 * math.clamp((t - rise) / 0.3, 0, 1)
		elseif t < roots - 0.35 then
			aR, aL = 1.6, 1.6
			if t > sweep + 0.25 then
				local u = math.clamp((t - sweep - 0.25) / 0.3, 0, 1)
				aR, aL = 1.6 + 1.3 * u, 1.6 + 1.3 * u
			end
		elseif t < roots then
			local u = (t - (roots - 0.35)) / 0.35
			aR, aL = 2.9 - 2.4 * u * u, 2.9 - 2.4 * u * u
		else
			aR, aL = 0.5, 0.5
		end
		local sR = root * CFrame.new(SH.R * S) * CFrame.Angles(aR, 0, 0)
		local sL = root * CFrame.new(SH.L * S) * CFrame.Angles(aL, 0, 0)
		for _, pc in ipairs(pieces) do
			local b = pc.limb == "R" and sR or (pc.limb == "L" and sL or root)
			pc.p.CFrame = b * pc.off
		end
	end)
	Fx.burst("dust", g + Vector3.new(0, 2, 0), Color3.fromRGB(120, 100, 70), 40, 3)
	Fx.debris(g, 12, 30, BARK)
	Fx.sound("heavy", 1, 0.35, g)
	shakeNear(g, 1.4, 120)
end
local function treantSlam(data: any)
	if near(data.at, 240) then
		local c, c2 = colors(data.style)
		impact(data.at, data.radius or 15, c, c2, 1.8)
		Fx.debris(ground(data.at), 14, 40, Color3.fromRGB(100, 80, 55))
		Fx.sound("heavy", 1, 0.45, data.at)
		shakeNear(data.at, 2, 120)
	end
end
local function treantSweep(data: any)
	local at: Vector3 = data.at
	if not near(at, 240) then
		return
	end
	local c, c2 = colors(data.style)
	local dir: Vector3 = data.dir or Vector3.new(0, 0, -1)
	local range = data.range or 30
	local half = math.rad((data.angle or 140) / 2)
	-- 휩쓴 자리에 흩날리는 잎 (부채꼴로)
	for k = 0, 10 do
		local a = -half + 2 * half * k / 10
		local d = (CFrame.Angles(0, a, 0) * CFrame.new(dir)).Position
		local p = at + d * range * 0.7 + Vector3.new(0, 2, 0)
		local leaf = part(Vector3.new(1.4, 0.15, 0.9), k % 2 == 0 and LEAF or c2, Enum.Material.SmoothPlastic, 0, "ball")
		leaf.CFrame = CFrame.new(at + d * 4 + Vector3.new(0, 3, 0))
		fadeOut(leaf, 0.5, { CFrame = CFrame.new(p) * CFrame.Angles(math.random() * 3, math.random() * 3, 0) })
	end
	Fx.ring(ground(at) + Vector3.new(0, 0.4, 0), c, 3, range * 2, 0.5)
	Fx.sound("swing", 1, 0.5, at)
	shakeNear(at, 1.2, 90)
end
local function treantRoots(data: any)
	local c, c2 = colors(data.style)
	for i, at in ipairs(data.spots or {}) do
		task.delay((i - 1) * 0.03, function()
			if near(at, 220) then
				local g = ground(at)
				local R = data.radius or 6
				-- 굵은 뿌리 셋이 땅을 뚫고 솟구친다
				for k = 0, 2 do
					local a = k / 3 * math.pi * 2 + math.random()
					local base = g + Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.4
					local tip = base + Vector3.new(math.cos(a) * 1.5, R * 1.6, math.sin(a) * 1.5)
					local r = beam(base, base + Vector3.new(0, 0.2, 0), 1.2, BARK, 0, Enum.Material.Wood)
					tween(r, 0.12, { Size = Vector3.new(1.2, 1.2, (tip - base).Magnitude), CFrame = CFrame.lookAt((base + tip) / 2, tip) }, Enum.EasingStyle.Back)
					task.delay(0.7, function()
						fadeOut(r, 0.4)
					end)
				end
				Fx.ring(g + Vector3.new(0, 0.3, 0), c, 2, R * 2.2, 0.4)
				Fx.debris(g, 4, 25, Color3.fromRGB(100, 80, 55))
			end
		end)
	end
	local first = (data.spots or {})[1]
	if first then
		Fx.sound("heavy", 0.8, 0.7, first)
	end
	local _ = c2
end

-- 개화의 꽃잎 회오리: 핀 꽃에서 꽃잎 수십 장이 나선으로 둘레에 휘몰아친다
local function budPetals(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 22
	local g = ground(at)
	for k = 1, 28 do
		local a0 = k / 28 * math.pi * 2
		local p = part(Vector3.new(1.4, 0.12, 0.9), k % 3 == 0 and c2 or PETAL, Enum.Material.SmoothPlastic, 0, "ball")
		local t0 = os.clock()
		local life = 0.55
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local u = math.clamp((os.clock() - t0) / life, 0, 1)
			local a = a0 + u * 3
			local r = 2 + (R - 2) * u
			p.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * r, 3 + math.sin(u * math.pi) * 4, math.sin(a) * r)) * CFrame.Angles(u * 9, a, u * 5)
			p.Transparency = u * u
			if u >= 1 then
				conn:Disconnect()
				p:Destroy()
			end
		end)
	end
	Fx.ring(g + Vector3.new(0, 0.4, 0), PETAL, 3, R * 2.2, 0.5)
	Fx.sound("swing", 0.9, 1.1, at)
	local _ = c
end
-- 목령강림의 잎 폭풍: 둘레에 큰 잎이 소용돌이치며 쏟아진다
local function leafStorm(data: any)
	local at: Vector3 = data.at
	if not near(at, 240) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 22
	local dur = data.dur or 0.8
	local g = ground(at)
	local n = 36
	for k = 1, n do
		task.delay((k / n) * dur, function()
			local a = math.random() * math.pi * 2
			local r = math.random() * R
			local top = g + Vector3.new(math.cos(a) * r, 24, math.sin(a) * r)
			local leaf = part(Vector3.new(1.8, 0.14, 1.1), k % 2 == 0 and LEAF or c, Enum.Material.SmoothPlastic, 0, "ball")
			leaf.CFrame = CFrame.new(top) * CFrame.Angles(math.random() * 3, math.random() * 3, 0)
			fadeOut(leaf, 0.6, { CFrame = CFrame.new(top - Vector3.new(math.sin(a) * 6, 23, -math.cos(a) * 6)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0) })
		end)
	end
	Fx.ring(g + Vector3.new(0, 0.4, 0), c2, 2, R * 2.2, dur)
	Fx.sound("swing", 0.8, 0.7, at)
end
-- 만목신권 생장 (네 번째 맞힘): 상대 자리의 가시덤불
local function thornPulse(data: any)
	if near(data.at, 200) then
		local c, c2 = colors(data.style)
		task.delay(data.delay or 0.3, function()
			thornBush(data.at, data.radius or 10, c, c2)
		end)
	end
end

local HANDLERS: { [string]: (any) -> () } = {
	needleShot = needleShot,
	needleBurst = needleBurst,
	gripRise = gripRise,
	gripSqueeze = gripSqueeze,
	gripSlam = gripSlam,
	dragonRoar = dragonRoar,
	palmWave = palmWave,
	palmBurst = palmBurst,
	sigilsPlace = sigilsPlace,
	sigilBolt = sigilBolt,
	railCharge = railCharge,
	railFire = railFire,
	bellDrop = bellDrop,
	bellRing = bellRing,
	vajraThrow = vajraThrow,
	cloneSpawn = cloneSpawn,
	cloneStrike = cloneStrike,
	shadowSlide = shadowSlide,
	shadowKick = shadowKick,
	orbitStart = orbitStart,
	orbitBurst = orbitBurst,
	hotGeyser = hotGeyser,
	wheelRoll = wheelRoll,
	flameRing = flameRing,
	volcanoRise = volcanoRise,
	vent = vent,
	eruptMain = eruptMain,
	meteorDrop = meteorDrop,
	bubbleTrap = bubbleTrap,
	bubblePop = bubblePop,
	waterSpear = waterSpear,
	whale = whale,
	twisterStart = twisterStart,
	twisterMove = twisterMove,
	twisterEnd = twisterEnd,
	downdraftWarn = downdraftWarn,
	downdraft = downdraft,
	diveMark = diveMark,
	diveImpact = diveImpact,
	yyShot = yyShot,
	yyOrbit = yyOrbit,
	taijiSeal = taijiSeal,
	starStart = starStart,
	starBeam = starBeam,
	starCrash = starCrash,
	ballStart = ballStart,
	ballArc = ballArc,
	ballBurst = ballBurst,
	lockOn = lockOn,
	judgeBolt = judgeBolt,
	drumRing = drumRing,
	drumBeat = drumBeat,
	drumFinale = drumFinale,
	seedShot = seedShot,
	thornSprout = thornSprout,
	budRise = budRise,
	budBloom = budBloom,
	treantRise = treantRise,
	treantSlam = treantSlam,
	treantSweep = treantSweep,
	treantRoots = treantRoots,
	thornPulse = thornPulse,
	budPetals = budPetals,
	leafStorm = leafStorm,
}
function Awake3.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil
end
function Awake3.run(data: any)
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

local _ = player
return Awake3
