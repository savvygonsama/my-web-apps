-- 권왕 2.9판: 진 매화난무권 (설중매) 의 기술 (화면). 눈 속에 피는 붉은 매화
-- 매화는 둥근 꽃잎 다섯 (가운데로 오목하게 겹친다), 노란 꽃술, 흰 꽃눈으로 짓는다. 가지는 짙은 밤빛으로 꺾이며 가늘어진다
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Plum = {}

local folder = Instance.new("Folder")
folder.Name = "KwonPlum"
folder.Parent = workspace

local opts: any = {}
function Plum.init(o: any)
	opts = o or {}
end

local REDS = { Color3.fromRGB(215, 30, 60), Color3.fromRGB(190, 20, 50), Color3.fromRGB(235, 70, 95) }
local STAMEN = Color3.fromRGB(255, 214, 90)
local BARK = Color3.fromRGB(58, 34, 30)
local SNOW = Color3.fromRGB(245, 250, 255)
local WHITE = Color3.new(1, 1, 1)
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

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
-- 프레임마다 u (0 → 1)
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

------------------------------------------------------------------------
-- 매화 한 송이: cf의 위(Y)가 꽃이 보는 쪽. size = 꽃의 지름
------------------------------------------------------------------------
type Flower = { parts: { BasePart }, place: (CFrame, number) -> () }
local function flower(size: number, color: Color3?): Flower
	local list: { BasePart } = {}
	local petals: { BasePart } = {}
	local c = color or REDS[math.random(1, 3)]
	for i = 1, 5 do
		local p = part(Vector3.one, i % 2 == 0 and c or c:Lerp(WHITE, 0.08), Enum.Material.SmoothPlastic, 0, "ball")
		petals[i] = p
		table.insert(list, p)
	end
	local heart = part(Vector3.one, WHITE, Enum.Material.SmoothPlastic, 0, "ball")
	table.insert(list, heart)
	local stamens: { BasePart } = {}
	for i = 1, 6 do
		local s = part(Vector3.one * 0.1, STAMEN, Enum.Material.Neon, 0, "ball")
		stamens[i] = s
		table.insert(list, s)
	end
	local function place(cf: CFrame, k: number)
		local D = math.max(0.05, size * k)
		for i, p in ipairs(petals) do
			local a = i / 5 * math.pi * 2
			p.Size = Vector3.new(D * 0.5, D * 0.12, D * 0.5)
			-- 꽃잎은 바깥으로 놓이고 가장자리가 살짝 위로 오므라든다
			p.CFrame = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, D * 0.04, -D * 0.27) * CFrame.Angles(math.rad(14), 0, 0)
		end
		heart.Size = Vector3.new(D * 0.26, D * 0.12, D * 0.26)
		heart.CFrame = cf * CFrame.new(0, D * 0.08, 0)
		for i, s in ipairs(stamens) do
			local a = i / 6 * math.pi * 2
			s.Size = Vector3.one * math.max(0.05, D * 0.07)
			s.CFrame = cf * CFrame.new(math.cos(a) * D * 0.12, D * 0.2, math.sin(a) * D * 0.12)
		end
	end
	return { parts = list, place = place }
end
local function fadeFlower(fl: Flower, time: number)
	for _, p in ipairs(fl.parts) do
		fadeOut(p, time)
	end
end
-- 꽃잎 하나가 흩날린다 (빙글 돌며 떨어진다)
local function petalFly(at: Vector3, size: number, life: number, push: Vector3)
	local p = part(Vector3.new(size, size * 0.15, size * 0.8), REDS[math.random(1, 3)], Enum.Material.SmoothPlastic, 0, "ball")
	local spin = Vector3.new(math.random() * 6, math.random() * 6, math.random() * 6)
	local ph = math.random() * 6
	anim(life, function(u)
		local t = u * life
		local pos = at + push * t + Vector3.new(math.sin(t * 4 + ph) * 0.8, -4 * t * t, math.cos(t * 3 + ph) * 0.8)
		p.CFrame = CFrame.new(pos) * CFrame.Angles(spin.X * t, spin.Y * t, spin.Z * t)
		p.Transparency = u > 0.7 and (u - 0.7) / 0.3 or 0
		if u >= 1 then
			p:Destroy()
		end
	end)
end
-- 눈송이 한 줌이 피어오른다
local function snowPuff(at: Vector3, r: number)
	for _ = 1, 10 do
		local s = part(Vector3.one * (0.3 + math.random() * 0.4) * r / 4, SNOW, Enum.Material.Snow, 0.05, "ball")
		local d = Vector3.new(math.random() - 0.5, math.random() * 0.6, math.random() - 0.5).Unit
		s.Position = at
		fadeOut(s, 0.6 + math.random() * 0.3, { Position = at + d * r * (0.6 + math.random() * 0.5), Size = s.Size * 1.8 })
	end
	Fx.burst("glitter", at, SNOW, 8, r / 6)
end
-- 가지 한 마디 (a → b), 굵기 w. 자라는 동안 u (0 → 1)
local function branchSeg(a: Vector3, b: Vector3, w: number): (number) -> ()
	local p = part(Vector3.new(0.05, w, w), BARK, Enum.Material.Wood, 0, "cyl")
	local snowCap = part(Vector3.new(0.05, w * 0.6, w * 1.1), SNOW, Enum.Material.Snow, 0.05)
	return function(u: number)
		local e = a:Lerp(b, u)
		local len = math.max(0.05, (e - a).Magnitude)
		local mid = (a + e) / 2
		local dir = (b - a).Unit
		p.Size = Vector3.new(len, w, w)
		p.CFrame = CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, math.rad(90), 0)
		snowCap.Size = Vector3.new(w * 1.1, w * 0.35, len * 0.9)
		snowCap.CFrame = CFrame.lookAt(mid, mid + dir) * CFrame.new(0, w * 0.45, 0)
		if u >= 1 then
			task.delay(1.2, function()
				fadeOut(p, 0.5)
				fadeOut(snowCap, 0.5)
			end)
		end
	end
end

------------------------------------------------------------------------
-- 설중매 (권법 장치): 발밑에서 짧은 가지 셋이 뻗고 꽃이 피었다가 터진다
------------------------------------------------------------------------
local function plumPulse(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local g = ground(at) + Vector3.new(0, 0.2, 0)
	local delay = data.delay or 0.35
	local r = data.radius or 10
	local flowers: { Flower } = {}
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2 + math.random()
		local tip = g + Vector3.new(math.cos(a) * r * 0.45, 0.4, math.sin(a) * r * 0.45)
		local grow = branchSeg(g, tip, 0.35)
		local fl = flower(2.2)
		table.insert(flowers, fl)
		anim(delay * 0.7, function(u)
			grow(u)
			fl.place(CFrame.new(tip + Vector3.new(0, 0.3, 0)), math.max(0, (u - 0.5) * 2))
		end)
	end
	task.delay(delay, function()
		for _, fl in ipairs(flowers) do
			local c = fl.parts[1].CFrame.Position
			for _ = 1, 4 do
				petalFly(c, 0.6, 0.9, Vector3.new(math.random() - 0.5, 1.5, math.random() - 0.5) * 5)
			end
			fadeFlower(fl, 0.25)
		end
		snowPuff(g + Vector3.new(0, 1, 0), r * 0.7)
		Fx.ring(g + Vector3.new(0, 0.3, 0), REDS[1], 2, r * 2, 0.4)
		Fx.breakSound("whoosh", 0.6, 1.2, g)
	end)
end

------------------------------------------------------------------------
-- 설중매 (E): 땅을 따라 매화 가지가 꺾이며 뻗고, 마디마다 꽃이 핀다. 잠시 뒤 모두 터진다
------------------------------------------------------------------------
local function plumBranch(data: any)
	local nodes: { Vector3 } = data.nodes or {}
	local from: Vector3 = data.from
	if #nodes == 0 or not near(from, 260) then
		return
	end
	local delay, step = data.delay or 0.15, data.step or 0.08
	local prev = ground(from) + Vector3.new(0, 0.3, 0)
	local flowers: { Flower } = {}
	for i, n in ipairs(nodes) do
		local pt = ground(n) + Vector3.new(0, 0.3, 0)
		local a = prev
		local w = 0.7 - i * 0.06
		task.delay(delay + (i - 1) * step, function()
			local grow = branchSeg(a, pt, w)
			local fl = flower(2.6 - i * 0.12)
			table.insert(flowers, fl)
			-- 곁가지 하나와 그 끝의 작은 꽃봉오리
			local side = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit * 2.2
			local twig = branchSeg(pt, pt + side + Vector3.new(0, 0.6, 0), 0.22)
			local bud = flower(1.0)
			table.insert(flowers, bud)
			anim(step * 2.2, function(u)
				grow(u)
				twig(u)
				fl.place(CFrame.new(pt + Vector3.new(0, 0.5, 0)) * CFrame.Angles(math.rad(-15), i, 0), math.clamp((u - 0.3) / 0.7, 0, 1))
				bud.place(CFrame.new(pt + side + Vector3.new(0, 0.9, 0)), math.clamp((u - 0.5) * 2, 0, 1))
			end)
			Fx.burst("glitter", pt + Vector3.new(0, 0.6, 0), SNOW, 4, 0.8)
		end)
		prev = pt
	end
	local tBurst = delay + (#nodes - 1) * step + (data.burstAt or 0.45)
	task.delay(tBurst, function()
		for _, fl in ipairs(flowers) do
			local c = fl.parts[1].CFrame.Position
			for _ = 1, 3 do
				petalFly(c, 0.7, 1.0, Vector3.new(math.random() - 0.5, 1.6, math.random() - 0.5) * 6)
			end
			fadeFlower(fl, 0.2)
		end
		for _, n in ipairs(nodes) do
			snowPuff(ground(n) + Vector3.new(0, 1, 0), 5)
		end
		Fx.breakSound("whoosh", 0.9, 1.0, ground(nodes[#nodes]))
		shakeNear(from, 0.5, 80)
	end)
end

------------------------------------------------------------------------
-- 한매오판 (R): 둘레 다섯 곳에 큰 매화가 천천히 돌며 피었다가 눈보라와 함께 터진다
------------------------------------------------------------------------
local function plumRing(data: any)
	local at: Vector3 = data.at
	local spots: { Vector3 } = data.spots or {}
	if not near(at, 260) then
		return
	end
	local delay, hold = data.delay or 0.3, data.hold or 0.6
	Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), SNOW, 2, 30, 0.6)
	for i, s in ipairs(spots) do
		local g = ground(s) + Vector3.new(0, 0.4, 0)
		local fl = flower(6.5, REDS[(i % 3) + 1])
		local stem = branchSeg(g - Vector3.new(0, 0.2, 0), g + Vector3.new(0, 1.4, 0), 0.6)
		anim(delay + hold, function(u)
			local t = u * (delay + hold)
			local open = math.clamp(t / delay, 0, 1)
			stem(math.min(1, open * 1.5))
			fl.place(CFrame.new(g + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, t * 1.5, 0), open * (1 + 0.06 * math.sin(t * 12)))
		end)
		task.delay(delay + hold, function()
			local c = g + Vector3.new(0, 1.6, 0)
			for _ = 1, 8 do
				petalFly(c, 1.0, 1.2, Vector3.new(math.random() - 0.5, 1.2, math.random() - 0.5) * 9)
			end
			fadeFlower(fl, 0.2)
			snowPuff(c, 8)
			Fx.ring(g, REDS[1], 2, 14, 0.4)
		end)
	end
	task.delay(delay + hold, function()
		Fx.breakSound("whoosh", 1, 0.9, at)
		shakeNear(at, 0.9, 90)
	end)
end

------------------------------------------------------------------------
-- 설중매화 (오의): 둘레에 함박눈과 붉은 꽃잎이 휘몰아치고, 땅이 하얗게 덮인다.
-- 끝에 하늘에 거대한 매화가 피어나 꽃잎이 비처럼 쏟아진다
------------------------------------------------------------------------
local function plumSnow(data: any)
	local at: Vector3 = data.at
	if not near(at, 320) then
		return
	end
	local R = data.radius or 24
	local delay, dur = data.delay or 0.3, data.dur or 2
	local g = ground(at)
	local cover = part(Vector3.new(0.2, 2, 2), SNOW, Enum.Material.Snow, 0.15, "cyl")
	cover.CFrame = CFrame.new(g + Vector3.new(0, 0.1, 0)) * UPRIGHT
	tween(cover, delay + dur * 0.6, { Size = Vector3.new(0.2, R * 2, R * 2) })
	if opts.tint then
		opts.tint(Color3.fromRGB(235, 240, 255), 0.25, delay + dur + 0.6)
	end
	-- 휘몰아치는 꽃잎 고리 (둘레를 돈다)
	local swirl: { BasePart } = {}
	for i = 1, 28 do
		swirl[i] = part(Vector3.new(0.9, 0.12, 0.7), REDS[(i % 3) + 1], Enum.Material.SmoothPlastic, 0, "ball")
	end
	anim(delay + dur, function(u)
		local t = u * (delay + dur)
		for i, p in ipairs(swirl) do
			local a = i / #swirl * math.pi * 2 + t * (2.4 + (i % 3) * 0.4)
			local r = R * (0.35 + 0.55 * ((i * 0.37) % 1))
			local y = 1 + ((i * 0.61 + t * 0.8) % 1) * 9
			p.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)) * CFrame.Angles(t * 5 + i, t * 3, i)
			p.Transparency = u > 0.9 and (u - 0.9) / 0.1 or 0
		end
		if u >= 1 then
			for _, p in ipairs(swirl) do
				p:Destroy()
			end
		end
	end)
	-- 함박눈
	local n = math.floor((delay + dur) / 0.05)
	for k = 0, n - 1 do
		task.delay(k * 0.05, function()
			for _ = 1, 3 do
				local a, r = math.random() * math.pi * 2, math.sqrt(math.random()) * R
				local top = g + Vector3.new(math.cos(a) * r, 24, math.sin(a) * r)
				local s = part(Vector3.one * (0.3 + math.random() * 0.35), SNOW, Enum.Material.Snow, 0.05, "ball")
				s.Position = top
				fadeOut(s, 1.4, { Position = top - Vector3.new(math.random() * 3 - 1.5, 23, math.random() * 3 - 1.5) })
			end
		end)
	end
	-- 하늘의 거대한 매화
	local sky = g + Vector3.new(0, 30, 0)
	local big = flower(R * 0.9, REDS[1])
	task.delay(delay + dur * 0.4, function()
		anim(dur * 0.6, function(u)
			big.place(CFrame.new(sky) * CFrame.Angles(math.rad(180), u * 1.2, 0), u)
		end)
		Fx.flash(sky, REDS[1], 60, 3, dur * 0.6)
	end)
	task.delay(delay + dur, function()
		-- 꽃잎 비
		for k = 0, 59 do
			task.delay(k * 0.012, function()
				local a, r = math.random() * math.pi * 2, math.random() * R * 0.9
				petalFly(sky + Vector3.new(math.cos(a) * r, -2, math.sin(a) * r), 1.3, 1.4, Vector3.new(math.cos(a), -6, math.sin(a)) * 3)
			end)
		end
		fadeFlower(big, 0.6)
		fadeOut(cover, 1.2)
		snowPuff(g + Vector3.new(0, 2, 0), R * 0.6)
		Fx.ring(g + Vector3.new(0, 0.4, 0), REDS[1], 4, R * 2.4, 0.6)
		Fx.ring(g + Vector3.new(0, 0.5, 0), SNOW, 2, R * 1.6, 0.5)
		Fx.flash(g, REDS[2], R * 3, 5, 0.5)
		Fx.breakSound("boom", 1, 0.9, g)
		shakeNear(at, 1.6, 140)
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	plumPulse = plumPulse,
	plumBranch = plumBranch,
	plumRing = plumRing,
	plumSnow = plumSnow,
}
function Plum.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil
end
function Plum.run(data: any)
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end
-- 렌더 확인용
Plum._flower = flower
local _ = Config
return Plum
