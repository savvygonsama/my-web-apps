-- 권왕 3.7판: 호접몽권 (화면). 꿈처럼 고운 빛깔 (분홍·라일락·하늘·민트·레몬)
-- 등의 나비 날개, 꿈 거품, 나비 떼, 꿈의 바다 (구름·초승달·오로라·비눗방울), 하늘을 가리는 꿈나비
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Fx = require(script.Parent:WaitForChild("Fx"))

local Dream = {}

local PASTEL = {
	Color3.fromRGB(255, 170, 210), -- 분홍
	Color3.fromRGB(200, 170, 255), -- 라일락
	Color3.fromRGB(150, 210, 255), -- 하늘
	Color3.fromRGB(150, 240, 210), -- 민트
	Color3.fromRGB(255, 236, 150), -- 레몬
}
local WHITE = Color3.new(1, 1, 1)
local MOON = Color3.fromRGB(255, 244, 196)
local BODY = Color3.fromRGB(70, 56, 96)
local UP = CFrame.Angles(0, 0, math.rad(90))

local folder = Instance.new("Folder")
folder.Name = "KwonDream"
folder.Parent = workspace

local opts: any = {}
function Dream.init(o: any)
	opts = o or {}
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
local function pastel(k: number): Color3
	return PASTEL[(k - 1) % #PASTEL + 1]
end
-- 빛깔이 천천히 도는 무지갯빛 (시간 t)
local function iris(t: number): Color3
	local u = (t * 0.6) % 1 * #PASTEL
	local i = math.floor(u)
	return pastel(i + 1):Lerp(pastel(i + 2), u - i)
end
-- 반짝이 가루 (위로 조금 떠올랐다 사라진다)
local function sparkle(at: Vector3, n: number, s: number)
	for k = 1, n do
		local q = part(Vector3.new(0.35, 0.35, 0.35) * s, pastel(k), Enum.Material.Neon, 0.05, "ball")
		q.CFrame = CFrame.new(at)
		fadeOut(q, 0.6 + math.random() * 0.5, { CFrame = CFrame.new(at + Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5) * 7 * s) })
	end
end
-- 작은 별 사탕 (뾰족한 다섯 갈래를 납작한 판 둘로 흉내)
local function candy(at: Vector3, color: Color3, s: number, life: number, fall: number)
	local a = part(Vector3.new(0.9, 0.9, 0.2) * s, color, Enum.Material.Neon, 0.05)
	local b = part(Vector3.new(0.9, 0.9, 0.2) * s, color:Lerp(WHITE, 0.3), Enum.Material.Neon, 0.05)
	local cf = CFrame.new(at) * CFrame.Angles(0, math.random() * 6, 0)
	a.CFrame = cf * CFrame.Angles(0, 0, math.rad(45))
	b.CFrame = cf
	local to = CFrame.new(at - Vector3.new(0, fall, 0)) * CFrame.Angles(0, math.random() * 6, math.random() * 3)
	fadeOut(a, life, { CFrame = to * CFrame.Angles(0, 0, math.rad(45)) })
	fadeOut(b, life, { CFrame = to })
end
local function pop(at: Vector3, s: number)
	Fx.ring(at, WHITE, 1, 10 * s, 0.35, Vector3.new(0, 1, 0))
	for k = 1, 3 do
		Fx.ring(at, pastel(k), 1, (6 + k * 3) * s, 0.3 + k * 0.06)
	end
	sparkle(at, 10, s)
	for k = 1, 5 do
		candy(at + Vector3.new(math.random() - 0.5, 0.5, math.random() - 0.5) * 3 * s, pastel(k), s, 0.9, 3 * s)
	end
	Fx.sound("ping", 0.45, 1.8, at)
end

------------------------------------------------------------------------
-- 나비 (몸 + 큰 윗날개 둘 + 작은 아랫날개 둘). 날개는 몸의 앞뒤 축으로 접혔다 펴진다
------------------------------------------------------------------------
type Fly = { body: BasePart, wings: { { p: BasePart, side: number, off: CFrame } }, s: number }
local function butterfly(s: number, c1: Color3, c2: Color3, alpha: number?): Fly
	local body = part(Vector3.new(0.25, 0.25, 1.2) * s, BODY, Enum.Material.SmoothPlastic, 0)
	local wings = {}
	for _, side in ipairs({ -1, 1 }) do
		local up = part(Vector3.new(1.3, 0.06, 1.2) * s, c1, Enum.Material.Glass, alpha or 0.15, "ball")
		local lo = part(Vector3.new(0.9, 0.06, 0.8) * s, c2, Enum.Material.Glass, alpha or 0.15, "ball")
		table.insert(wings, { p = up, side = side, off = CFrame.new(side * 0.65 * s, 0, -0.25 * s) })
		table.insert(wings, { p = lo, side = side, off = CFrame.new(side * 0.5 * s, 0, 0.45 * s) })
	end
	return { body = body, wings = wings, s = s }
end
local function placeFly(f: Fly, cf: CFrame, flap: number)
	f.body.CFrame = cf
	for _, w in ipairs(f.wings) do
		-- 몸 축 (Z)으로 날개를 들어 올린다 (flap 0 = 편 날개, 1 = 위로 모은 날개)
		local hinge = cf * CFrame.Angles(0, 0, -w.side * flap * math.rad(75))
		w.p.CFrame = hinge * w.off
	end
end
local function fadeFly(f: Fly, time: number)
	fadeOut(f.body, time)
	for _, w in ipairs(f.wings) do
		fadeOut(w.p, time)
	end
end

------------------------------------------------------------------------
-- 차림: 등에 빛깔이 흐르는 나비 날개 넷 (천천히 팔랑인다), 둘레를 도는 비눗방울 셋
------------------------------------------------------------------------
function Dream.buildGear(model: Model): { Instance }
	local out: { Instance } = {}
	local holder = Instance.new("Folder")
	holder.Name = "Dream_" .. model.Name
	holder.Parent = folder
	table.insert(out, holder)
	local torso = model:FindFirstChild("UpperTorso")
	if not (torso and torso:IsA("BasePart")) then
		return out
	end
	local wings: { { p: BasePart, rim: BasePart, side: number, big: boolean } } = {}
	for _, side in ipairs({ -1, 1 }) do
		for _, big in ipairs({ true, false }) do
			local sz = big and Vector3.new(2.6, 0.08, 2.1) or Vector3.new(1.7, 0.08, 1.4)
			local p = part(sz, big and PASTEL[2] or PASTEL[4], Enum.Material.Glass, 0.3, "ball")
			local rim = part(sz * Vector3.new(1.06, 0.5, 1.06), WHITE, Enum.Material.Neon, 0.7, "ball")
			p.Parent = holder
			rim.Parent = holder
			table.insert(out, p)
			table.insert(out, rim)
			table.insert(wings, { p = p, rim = rim, side = side, big = big })
		end
	end
	local bubbles: { BasePart } = {}
	for k = 1, 3 do
		local b = part(Vector3.new(0.6, 0.6, 0.6), pastel(k + 1), Enum.Material.Glass, 0.55, "ball")
		b.Parent = holder
		table.insert(out, b)
		bubbles[k] = b
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if not holder.Parent or not torso.Parent then
			conn:Disconnect()
			return
		end
		local t = os.clock() - t0
		local hide = model:GetAttribute("Vanish") == true
		local flap = 0.25 + 0.2 * math.sin(t * 2.6)
		local back = torso.CFrame * CFrame.new(0, 0.35, torso.Size.Z / 2 + 0.12)
		for _, w in ipairs(wings) do
			-- 등에 세운 날개: 위 날개는 어깨 위로, 아래 날개는 허리 쪽으로 비스듬히
			local tilt = w.big and math.rad(30) or math.rad(-35)
			local cf = back * CFrame.Angles(0, -w.side * (math.rad(25) + flap), 0) * CFrame.Angles(0, 0, -w.side * tilt) * CFrame.new(w.side * (w.big and 1.35 or 0.9), w.big and 0.5 or -0.6, 0) * CFrame.Angles(math.rad(90), 0, 0)
			w.p.CFrame = cf
			w.rim.CFrame = cf
			w.p.Color = iris(t + (w.big and 0 or 1.5) + (w.side > 0 and 0.4 or 0))
			w.p.LocalTransparencyModifier = hide and 1 or 0
			w.rim.LocalTransparencyModifier = hide and 1 or 0
		end
		for k, b in ipairs(bubbles) do
			local a = t * 0.8 + k * 2.1
			b.CFrame = torso.CFrame * CFrame.new(math.cos(a) * 2.4, 0.5 + math.sin(t * 1.3 + k) * 0.8, math.sin(a) * 2.4)
			b.LocalTransparencyModifier = hide and 1 or 0
		end
	end)
	return out
end

------------------------------------------------------------------------
-- 연타 장치 꿈 거품: 상대가 무지갯빛 거품에 갇혀 둥실 떠올랐다가 터진다
------------------------------------------------------------------------
local function dreamBubble(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local delay = data.delay or 0.6
	local b = part(Vector3.new(1, 1, 1), PASTEL[2], Enum.Material.Glass, 0.6, "ball")
	b.CFrame = CFrame.new(at)
	local shine = part(Vector3.new(0.8, 0.5, 0.2), WHITE, Enum.Material.Neon, 0.3, "ball")
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp(t / delay, 0, 1)
		local size = 6.5 * math.min(1, t / 0.15)
		local pos = at + Vector3.new(0, 3 * u + math.sin(t * 6) * 0.2, 0)
		b.Size = Vector3.new(size, size, size)
		b.CFrame = CFrame.new(pos)
		b.Color = iris(t * 2)
		shine.CFrame = CFrame.new(pos + Vector3.new(-size * 0.25, size * 0.3, -size * 0.3))
		if u >= 1 then
			conn:Disconnect()
			b:Destroy()
			shine:Destroy()
			pop(pos, 0.9)
		end
	end)
end

------------------------------------------------------------------------
-- E 몽접군무: 나비 열둘이 적에게 날아가 맴돌다 부딪친다
------------------------------------------------------------------------
local function butterflySwarm(data: any)
	local m: Model? = data.m
	local r = rootOf(m)
	if not r or not near(r.Position, 220) then
		return
	end
	local n = data.n or 12
	local targets = data.targets or {}
	local look = flat(r.CFrame.LookVector)
	local delay = data.delay or 0.15
	local every = data.every or 0.04
	local travel = data.travel or 0.5
	sparkle(r.Position + Vector3.new(0, 1, 0), 8, 1)
	Fx.sound("swing", 0.4, 1.7, r.Position)
	for i = 1, n do
		task.delay(delay + (i - 1) * every, function()
			local rr = rootOf(m)
			local from = (rr and rr.Position or r.Position) + Vector3.new(math.random() - 0.5, 1 + math.random(), math.random() - 0.5) * 2
			local tgt = #targets > 0 and targets[(i - 1) % #targets + 1] or nil
			local fly = butterfly(0.9 + math.random() * 0.4, pastel(i), pastel(i + 2))
			local side = Vector3.new(math.random() - 0.5, math.random() * 0.6, math.random() - 0.5).Unit * (4 + math.random() * 3)
			local t0 = os.clock()
			local last = from
			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function()
				local t = os.clock() - t0
				local u = math.clamp(t / travel, 0, 1)
				local tr = rootOf(tgt)
				local goal = tr and tr.Position or (from + look * 22)
				local pos = from:Lerp(goal, u * u * (3 - 2 * u)) + side * math.sin(u * math.pi) + Vector3.new(0, math.sin(t * 20) * 0.25, 0)
				local dir = (pos - last).Magnitude > 1e-3 and (pos - last).Unit or look
				placeFly(fly, CFrame.lookAt(pos, pos + dir), 0.5 + 0.5 * math.sin(t * 30))
				last = pos
				if u >= 1 then
					conn:Disconnect()
					fadeFly(fly, 0.15)
					sparkle(pos, 5, 0.7)
				end
			end)
		end)
	end
end

------------------------------------------------------------------------
-- R 몽포: 커다란 무지갯빛 거품이 부풀어 가두고 둥실 떠올랐다가 터진다
------------------------------------------------------------------------
local function dreamTrap(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local R = data.radius or 9
	local delay = data.delay or 0.25
	local hold = data.hold or 1.2
	local g = ground(at)
	local b = part(Vector3.new(1, 1, 1), PASTEL[2], Enum.Material.Glass, 0.65, "ball")
	local inner = part(Vector3.new(1, 1, 1), WHITE, Enum.Material.Neon, 0.94, "ball")
	local shine = part(Vector3.new(2, 1.2, 0.3), WHITE, Enum.Material.Neon, 0.3, "ball")
	local t0 = os.clock()
	Fx.sound("ping", 0.5, 1.2, at)
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local grow = math.clamp(t / delay, 0, 1)
		local u = math.clamp((t - delay) / hold, 0, 1)
		local d = R * 2 * (1 - (1 - grow) ^ 3) * (1 + 0.04 * math.sin(t * 7))
		local pos = g + Vector3.new(0, R * 0.8 + u * 5 + math.sin(t * 3) * 0.3, 0)
		b.Size = Vector3.new(d, d * 0.96, d)
		b.CFrame = CFrame.new(pos)
		b.Color = iris(t * 1.5)
		inner.Size = b.Size * 0.9
		inner.CFrame = b.CFrame
		shine.CFrame = CFrame.new(pos + Vector3.new(-d * 0.22, d * 0.3, -d * 0.28)) * CFrame.Angles(0, 0.6, 0.4)
		if math.random() < 0.3 then
			sparkle(pos + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * d * 0.7, 1, 0.8)
		end
		if t >= delay + hold then
			conn:Disconnect()
			b:Destroy()
			inner:Destroy()
			shine:Destroy()
			pop(pos, 2.2)
			for k = 1, 10 do
				candy(pos + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * R, pastel(k), 1.6, 1.2, pos.Y - g.Y)
			end
			Fx.flash(pos, PASTEL[1], 40, 3, 0.3)
			Fx.sound("splash", 0.6, 1.6, pos)
			shakeNear(pos, 0.8, 90)
		end
	end)
end

------------------------------------------------------------------------
-- G 몽중몽: 무지갯빛 구름 바다, 초승달, 오로라, 떠오르는 비눗방울, 쏟아지는 별과 달 조각. 끝에 꿈에서 깨듯 펑
------------------------------------------------------------------------
local function dreamSea(data: any)
	local at: Vector3 = data.at
	if not near(at, 260) then
		return
	end
	local R = data.radius or 26
	local delay = data.delay or 0.4
	local dur = data.dur or 3.0
	local g = ground(at)
	local parts: { BasePart } = {}
	-- 땅: 무지개 고리 (바깥에서 안으로)와 구름 덩이
	for k = 1, 5 do
		local d = R * 2 * (1 - (k - 1) * 0.16)
		local ringP = part(Vector3.new(0.2, 1, 1), pastel(k), Enum.Material.Neon, 0.72, "cyl")
		ringP.CFrame = CFrame.new(g + Vector3.new(0, 0.1 + k * 0.02, 0)) * UP
		tween(ringP, delay + 0.2, { Size = Vector3.new(0.2, d, d) })
		table.insert(parts, ringP)
	end
	for k = 1, 12 do
		local a = k / 12 * math.pi * 2
		local rr = R * (0.55 + (k % 3) * 0.15)
		local c = part(Vector3.new(1, 1, 1), pastel(k):Lerp(WHITE, 0.45), Enum.Material.SmoothPlastic, 0.15, "ball")
		local size = Vector3.new(9 + (k % 4) * 2, 3.2, 7 + (k % 3) * 2)
		c.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * rr, 0.8, math.sin(a) * rr)) * CFrame.Angles(0, a, 0)
		tween(c, delay + 0.3, { Size = size }, Enum.EasingStyle.Back)
		table.insert(parts, c)
	end
	-- 하늘: 초승달 (호를 따라 조각을 이어) 과 오로라 띠 셋
	local moonC = g + Vector3.new(0, 34, 0)
	for k = 0, 12 do
		local a = math.rad(-110 + k * 18)
		local w = 2.4 * math.sin((k + 0.5) / 13 * math.pi) + 0.5
		local seg = part(Vector3.new(w, 2.6, 0.6), MOON, Enum.Material.Neon, 1)
		seg.CFrame = CFrame.new(moonC + Vector3.new(math.cos(a) * 7, math.sin(a) * 7, 0)) * CFrame.Angles(0, 0, a)
		tween(seg, 0.6, { Transparency = 0.05 })
		table.insert(parts, seg)
	end
	local aurora: { { p: BasePart, k: number, j: number } } = {}
	for k = 1, 3 do
		for j = 0, 9 do
			local p = part(Vector3.new(6, 8, 0.2), pastel(k + 1), Enum.Material.Neon, 0.75)
			table.insert(aurora, { p = p, k = k, j = j })
			table.insert(parts, p)
		end
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		for _, it in ipairs(aurora) do
			local x = (it.j - 4.5) * 5.6
			local y = 26 + it.k * 3 + math.sin(t * 1.4 + it.j * 0.6 + it.k) * 1.6
			it.p.CFrame = CFrame.new(g + Vector3.new(x, y, -R * 0.4 + it.k * 3)) * CFrame.Angles(0, math.sin(t + it.j) * 0.2, 0)
		end
		if t > delay and t < delay + dur then
			-- 떠오르는 비눗방울
			if math.random() < 0.5 then
				local a, rr = math.random() * math.pi * 2, math.sqrt(math.random()) * R
				local bp = g + Vector3.new(math.cos(a) * rr, 1, math.sin(a) * rr)
				local bub = part(Vector3.new(1, 1, 1) * (0.8 + math.random() * 1.6), pastel(math.random(1, 5)), Enum.Material.Glass, 0.55, "ball")
				bub.CFrame = CFrame.new(bp)
				fadeOut(bub, 1.6, { CFrame = CFrame.new(bp + Vector3.new(math.random() - 0.5, 9, math.random() - 0.5)) })
			end
			-- 쏟아지는 별과 달 조각
			if math.random() < 0.55 then
				local a, rr = math.random() * math.pi * 2, math.sqrt(math.random()) * R
				candy(g + Vector3.new(math.cos(a) * rr, 18 + math.random() * 6, math.sin(a) * rr), pastel(math.random(1, 5)), 1.2, 0.8, 16)
			end
		end
		if t >= delay + dur then
			conn:Disconnect()
		end
	end)
	Fx.sound("ping", 0.6, 0.9, at)
	shakeNear(g, 0.8, 120)
	task.delay(delay + dur, function()
		-- 꿈에서 깬다: 하얀 빛이 번지고 모든 것이 반짝이로
		for _, p in ipairs(parts) do
			if p.Parent then
				fadeOut(p, 0.5, { Size = p.Size * 1.2 })
			end
		end
		local core = part(Vector3.new(4, 4, 4), WHITE, Enum.Material.Neon, 0, "ball")
		core.CFrame = CFrame.new(g + Vector3.new(0, 4, 0))
		fadeOut(core, 0.5, { Size = Vector3.new(R * 1.8, R * 1.8, R * 1.8) })
		for k = 1, 5 do
			task.delay(k * 0.05, function()
				Fx.ring(g + Vector3.new(0, 0.5 + k * 0.6, 0), pastel(k), 4, R * 2.4 + k * 6, 0.6)
			end)
		end
		for _ = 1, 6 do
			local a, rr = math.random() * math.pi * 2, math.random() * R
			sparkle(g + Vector3.new(math.cos(a) * rr, 3, math.sin(a) * rr), 6, 1.4)
		end
		Fx.flash(g + Vector3.new(0, 4, 0), PASTEL[1], 90, 6, 0.5)
		Fx.sound("shatter", 0.7, 1.6, g)
		Fx.sound("heavy", 0.8, 0.8, g)
		shakeNear(g, 2.2, 150)
	end)
end

------------------------------------------------------------------------
-- X 호접지몽: 날개폭이 하늘을 가리는 꿈나비. 날갯짓마다 무지갯빛 물결, 날개를 접어 감싸 안고 무지개 꽃으로
------------------------------------------------------------------------
type BigFly = { body: BasePart, panels: { { p: BasePart, side: number, off: CFrame, base: Color3 } } }
local function bigButterfly(S: number): BigFly
	local body = part(Vector3.new(1.4, 1.4, 12) * S / 30, BODY, Enum.Material.SmoothPlastic, 0, "ball")
	local panels = {}
	for _, side in ipairs({ -1, 1 }) do
		-- 윗날개 (큰 판 + 안쪽 빛깔 판 + 흰 테 + 점 무늬), 아랫날개
		local defs = {
			{ Vector3.new(16, 0.3, 13), CFrame.new(side * 8.5, 0, -3.5), PASTEL[2], Enum.Material.Glass, 0.25 },
			{ Vector3.new(10, 0.32, 8), CFrame.new(side * 7.5, 0.1, -3), PASTEL[1], Enum.Material.Glass, 0.3 },
			{ Vector3.new(17, 0.2, 14), CFrame.new(side * 8.5, -0.1, -3.5), WHITE, Enum.Material.Neon, 0.75 },
			{ Vector3.new(2.2, 0.34, 2.2), CFrame.new(side * 12.5, 0.2, -6), PASTEL[5], Enum.Material.Neon, 0.1 },
			{ Vector3.new(11, 0.3, 9), CFrame.new(side * 6, 0, 6), PASTEL[4], Enum.Material.Glass, 0.25 },
			{ Vector3.new(6, 0.32, 5), CFrame.new(side * 5.5, 0.1, 6.5), PASTEL[3], Enum.Material.Glass, 0.3 },
			{ Vector3.new(1.6, 0.34, 1.6), CFrame.new(side * 8, 0.2, 8.5), PASTEL[5], Enum.Material.Neon, 0.1 },
		}
		for _, d in ipairs(defs) do
			local p = part(d[1] * S / 30, d[3], d[4], d[5], "ball")
			table.insert(panels, { p = p, side = side, off = CFrame.new(d[2].Position * S / 30), base = d[3] })
		end
	end
	return { body = body, panels = panels }
end
local function placeBig(f: BigFly, cf: CFrame, flap: number, t: number)
	f.body.CFrame = cf
	for i, it in ipairs(f.panels) do
		local hinge = cf * CFrame.Angles(0, 0, -it.side * flap * math.rad(80))
		it.p.CFrame = hinge * it.off
		if it.p.Material == Enum.Material.Glass then
			it.p.Color = it.base:Lerp(iris(t + i * 0.2), 0.35)
		end
	end
end
local function butterflyDream(data: any)
	local at: Vector3 = data.at
	if not near(at, 340) then
		return
	end
	local dir = flat(data.dir or Vector3.new(0, 0, -1))
	local cut = data.cut or 1.4
	local rise = data.rise or 0.6
	local flaps = data.flaps or 3
	local every = data.flapEvery or 0.6
	local fold = data.fold or 0.6
	local range = data.range or 40
	local g = ground(at)
	local fly = bigButterfly(60)
	local startP = g - dir * 14 + Vector3.new(0, -6, 0)
	local hover = g - dir * 6 + Vector3.new(0, 26, 0)
	local t0 = os.clock()
	local flapped = 0
	-- 컷씬 동안 둘레에 꿈의 빛 기둥 다섯이 피어오른다
	for k = 1, 5 do
		local a = k / 5 * math.pi * 2
		local p = g + Vector3.new(math.cos(a) * range * 0.6, 0, math.sin(a) * range * 0.6)
		local col = part(Vector3.new(2, 3, 3), pastel(k), Enum.Material.Neon, 0.4, "cyl")
		col.CFrame = CFrame.new(p) * UP
		tween(col, cut * 0.6, { Size = Vector3.new(50, 3, 3), CFrame = CFrame.new(p + Vector3.new(0, 25, 0)) * UP })
		task.delay(cut + 0.2, function()
			fadeOut(col, 0.6)
		end)
	end
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local pos: Vector3
		local flap: number
		local look = CFrame.lookAt(Vector3.zero, -dir) -- 몸은 쓴 사람이 보는 쪽으로 (머리 = -Z)
		if t < cut then
			pos = startP
			flap = 1
		elseif t < cut + rise then
			local u = (t - cut) / rise
			pos = startP:Lerp(hover, 1 - (1 - u) ^ 2)
			flap = 1 - u * 0.6
		elseif t < cut + rise + flaps * every then
			local tt = t - cut - rise
			local k = math.floor(tt / every)
			local u = (tt - k * every) / every
			-- 날개를 크게 아래로 쳤다가 천천히 든다
			flap = u < 0.3 and (0.9 - u / 0.3 * 1.15) or (-0.25 + (u - 0.3) / 0.7 * 1.15)
			pos = hover + Vector3.new(0, math.sin(tt * 4) * 0.8 - (u < 0.3 and u * 3 or 0.9 - (u - 0.3) * 1.3), 0)
			if k + 1 > flapped and k < flaps then
				flapped = k + 1
				-- 날갯짓 물결: 무지개 빛깔 고리가 둘레를 휩쓴다
				for c = 1, 5 do
					task.delay(c * 0.04, function()
						Fx.ring(g + Vector3.new(0, 0.6 + c * 0.4, 0), pastel(c), 6, range * 2.2, 0.55)
					end)
				end
				for _ = 1, 8 do
					local a, rr = math.random() * math.pi * 2, math.random() * range
					sparkle(g + Vector3.new(math.cos(a) * rr, 2 + math.random() * 4, math.sin(a) * rr), 4, 1.3)
				end
				Fx.sound("swing", 0.9, 0.5, g)
				shakeNear(g, 1.4, 180)
			end
		elseif t < cut + rise + flaps * every + fold then
			local u = (t - cut - rise - flaps * every) / fold
			pos = hover:Lerp(g + Vector3.new(0, 10, 0), u * u)
			flap = 0.6 + u * 0.55 -- 날개를 위로 접어 감싸 안는다
		else
			conn:Disconnect()
			fadeOut(fly.body, 0.3)
			for _, it in ipairs(fly.panels) do
				fadeOut(it.p, 0.3, { Size = it.p.Size * 1.4 })
			end
			-- 무지개 꽃: 꽃잎 열이 활짝 피었다 흩어진다
			for k = 1, 10 do
				local a = k / 10 * math.pi * 2
				local petal = part(Vector3.new(4, 1, 8), pastel(k), Enum.Material.Neon, 0.15, "ball")
				local cf0 = CFrame.new(g + Vector3.new(0, 2, 0)) * CFrame.Angles(0, a, 0)
				petal.CFrame = cf0 * CFrame.new(0, 0, -2) * CFrame.Angles(math.rad(70), 0, 0)
				local cf1 = cf0 * CFrame.new(0, 1, -(data.finalRadius or 34) * 0.55) * CFrame.Angles(math.rad(10), 0, 0)
				tween(petal, 0.35, { CFrame = cf1, Size = Vector3.new(12, 1.4, 24) }, Enum.EasingStyle.Back)
				task.delay(0.45, function()
					fadeOut(petal, 0.6, { Size = Vector3.new(16, 0.4, 30) })
				end)
			end
			local core = part(Vector3.new(6, 6, 6), WHITE, Enum.Material.Neon, 0, "ball")
			core.CFrame = CFrame.new(g + Vector3.new(0, 4, 0))
			fadeOut(core, 0.6, { Size = Vector3.new(60, 60, 60) })
			for c = 1, 5 do
				task.delay(c * 0.06, function()
					Fx.ring(g + Vector3.new(0, 0.6 + c, 0), pastel(c), 6, (data.finalRadius or 34) * 2.6 + c * 8, 0.8)
				end)
			end
			for _ = 1, 12 do
				local a, rr = math.random() * math.pi * 2, math.random() * (data.finalRadius or 34)
				sparkle(g + Vector3.new(math.cos(a) * rr, 3 + math.random() * 6, math.sin(a) * rr), 6, 1.6)
			end
			Fx.flash(g + Vector3.new(0, 6, 0), PASTEL[1], 150, 9, 0.7)
			Fx.sound("shatter", 0.9, 1.4, g)
			Fx.sound("heavy", 1, 0.6, g)
			shakeNear(g, 3.2, 220)
			if opts.flash and near(g, 120) then
				opts.flash(PASTEL[1], 0.3)
			end
			return
		end
		placeBig(fly, CFrame.new(pos) * look.Rotation * CFrame.Angles(math.rad(-25), 0, 0), flap, t)
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	butterflySwarm = butterflySwarm,
	dreamTrap = dreamTrap,
	dreamSea = dreamSea,
	butterflyDream = butterflyDream,
}
function Dream.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil or (data.kind == "pulse" and data.fx == "dreamBubble")
end
function Dream.run(data: any)
	if data.kind == "pulse" then
		dreamBubble(data)
		return
	end
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

return Dream
