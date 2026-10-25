-- 권왕 2.9판: 진 취팔선권 (취선) 의 기술 (화면). 호리병, 술의 강, 여덟 신선의 그림자
-- 호리병은 아래가 크고 위가 작은 두 구 (잘록한 허리에 끈), 좁은 목과 마개로 짓는다. 술은 보랏빛 도는 짙은 술빛
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Gourd = {}

local folder = Instance.new("Folder")
folder.Name = "KwonGourd"
folder.Parent = workspace

local opts: any = {}
function Gourd.init(o: any)
	opts = o or {}
end

local SHELL = Color3.fromRGB(196, 140, 62)
local SHELL_DARK = Color3.fromRGB(150, 98, 40)
local CORD = Color3.fromRGB(170, 30, 40)
local WINE = Color3.fromRGB(150, 60, 170)
local WINE_LIGHT = Color3.fromRGB(220, 150, 255)
local FLAME = Color3.fromRGB(255, 150, 60)
local GHOST = Color3.fromRGB(205, 170, 255)
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
local function rootOf(m: Instance?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
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
-- 호리병: cf = 병의 아래 구 가운데, 위(Y)가 목. S = 크기
------------------------------------------------------------------------
type Gourd = { parts: { BasePart }, place: (CFrame) -> () }
local function gourd(S: number): Gourd
	local low = part(Vector3.one, SHELL, Enum.Material.SmoothPlastic, 0, "ball")
	local high = part(Vector3.one, SHELL, Enum.Material.SmoothPlastic, 0, "ball")
	local waist = part(Vector3.one, CORD, Enum.Material.Fabric, 0, "cyl")
	local neck = part(Vector3.one, SHELL_DARK, Enum.Material.SmoothPlastic, 0, "cyl")
	local cork = part(Vector3.one, Color3.fromRGB(110, 70, 40), Enum.Material.Wood, 0, "cyl")
	local tassel = part(Vector3.one, CORD, Enum.Material.Fabric)
	local list = { low, high, waist, neck, cork, tassel }
	local function place(cf: CFrame)
		low.Size = Vector3.new(1.6, 1.5, 1.6) * S
		low.CFrame = cf
		high.Size = Vector3.new(1.05, 1.0, 1.05) * S
		high.CFrame = cf * CFrame.new(0, 1.15 * S, 0)
		waist.Size = Vector3.new(0.18 * S, 0.62 * S, 0.62 * S)
		waist.CFrame = cf * CFrame.new(0, 0.66 * S, 0) * UPRIGHT
		neck.Size = Vector3.new(0.5 * S, 0.36 * S, 0.36 * S)
		neck.CFrame = cf * CFrame.new(0, 1.78 * S, 0) * UPRIGHT
		cork.Size = Vector3.new(0.18 * S, 0.42 * S, 0.42 * S)
		cork.CFrame = cf * CFrame.new(0, 2.05 * S, 0) * UPRIGHT
		tassel.Size = Vector3.new(0.12, 0.7, 0.12) * S
		tassel.CFrame = cf * CFrame.new(0.3 * S, 0.3 * S, 0) * CFrame.Angles(0, 0, math.rad(12))
	end
	return { parts = list, place = place }
end
local function fadeGourd(g: Gourd, time: number)
	for _, p in ipairs(g.parts) do
		fadeOut(p, time)
	end
end
-- 술 방울이 튀어 올랐다가 떨어진다
local function splash(at: Vector3, n: number, power: number)
	for _ = 1, n do
		local d = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
		local drop = part(Vector3.one * (0.3 + math.random() * 0.35), math.random() < 0.5 and WINE or WINE_LIGHT, Enum.Material.Glass, 0.15, "ball")
		local up = power * (0.6 + math.random() * 0.6)
		local out = power * (0.3 + math.random() * 0.4)
		anim(0.7, function(u)
			local t = u * 0.7
			drop.Position = at + d * out * t + Vector3.new(0, up * t - 16 * t * t, 0)
			drop.Transparency = 0.15 + 0.85 * u
			if u >= 1 then
				drop:Destroy()
			end
		end)
	end
end

------------------------------------------------------------------------
-- 술 튐 (권법 장치): 상대 자리에서 술이 솟아 튀고, 어지러운 별이 맴돈다
------------------------------------------------------------------------
local function winePulse(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local g = ground(at) + Vector3.new(0, 0.3, 0)
	task.delay(data.delay or 0.25, function()
		local col = part(Vector3.new(0.6, 3, 3), WINE, Enum.Material.Glass, 0.2, "cyl")
		col.CFrame = CFrame.new(g + Vector3.new(0, 0.3, 0)) * UPRIGHT
		tween(col, 0.15, { Size = Vector3.new(6, 2.2, 2.2), CFrame = CFrame.new(g + Vector3.new(0, 3, 0)) * UPRIGHT })
		task.delay(0.15, function()
			fadeOut(col, 0.25, { Size = Vector3.new(7, 0.4, 0.4) })
		end)
		splash(g + Vector3.new(0, 1, 0), 10, 12)
		Fx.ring(g, WINE, 2, (data.radius or 9) * 2, 0.35)
		-- 어지러운 별 셋
		for k = 1, 3 do
			local star = part(Vector3.one * 0.5, Color3.fromRGB(255, 230, 120), Enum.Material.Neon, 0, "ball")
			anim(0.9, function(u)
				local a = k / 3 * math.pi * 2 + u * 9
				star.Position = g + Vector3.new(math.cos(a) * 1.6, 4.6, math.sin(a) * 1.6)
				star.Transparency = u
				if u >= 1 then
					star:Destroy()
				end
			end)
		end
		Fx.sound("splash", 0.6, 1.2, g)
	end)
end

------------------------------------------------------------------------
-- 취월삼보 (E): 휘청이는 세 걸음. 내려설 때마다 그림자와 술 고리, 걸음 사이를 잇는 비틀린 빛
------------------------------------------------------------------------
local function drunkZig(data: any)
	local m: Model? = data.m
	local hops: { Vector3 } = data.hops or {}
	local r = rootOf(m)
	if not r or not near(r.Position, 220) then
		return
	end
	local every = data.every or 0.18
	local prev = r.Position
	for i, h in ipairs(hops) do
		local a = prev
		task.delay(i * every, function()
			local b = Vector3.new(h.X, a.Y, h.Z)
			-- 비틀린 빛줄기 (가운데가 옆으로 휜다)
			local side = Vector3.new(-(b - a).Unit.Z, 0, (b - a).Unit.X) * ((i % 2 == 0) and 1.6 or -1.6)
			local last = a
			for k = 1, 6 do
				local u = k / 6
				local p = a:Lerp(b, u) + side * math.sin(u * math.pi) + Vector3.new(0, math.sin(u * math.pi) * 1.2, 0)
				local seg = part(Vector3.new(0.25, 0.25, (p - last).Magnitude + 0.1), k % 2 == 0 and WINE_LIGHT or WINE, Enum.Material.Neon, 0.1)
				seg.CFrame = CFrame.lookAt((p + last) / 2, p)
				fadeOut(seg, 0.4)
				last = p
			end
			if m then
				Fx.afterimage(m, GHOST, 0.4)
			end
			local g = ground(b) + Vector3.new(0, 0.3, 0)
			Fx.ring(g, WINE, 2, 13, 0.3)
			splash(g + Vector3.new(0, 0.6, 0), 6, 9)
			Fx.sound("swing", 0.8, 0.7 + i * 0.1, g)
		end)
		prev = Vector3.new(h.X, r.Position.Y, h.Z)
	end
end

------------------------------------------------------------------------
-- 주천강 (R): 손의 호리병에서 술이 쏟아져 앞으로 강이 되어 흐르고, 끝에 불이 붙는다
------------------------------------------------------------------------
local function wineRiver(data: any)
	local from: Vector3, to: Vector3 = data.from, data.to
	if not near(from, 260) then
		return
	end
	local W = data.width or 6
	local delay, dur = data.delay or 0.25, data.dur or 2
	local dir = (to - from).Unit
	local len = (to - from).Magnitude
	local gf, gt = ground(from), ground(to)
	-- 들어 올린 호리병과 쏟아지는 술줄기
	local m: Model? = data.m
	local r = rootOf(m)
	local held = gourd(0.9)
	local spout = part(Vector3.new(0.5, 0.5, 1), WINE, Enum.Material.Glass, 0.15)
	anim(delay + 0.4, function(u)
		local base = r and r.CFrame or CFrame.new(from)
		local hand = base * CFrame.new(1.4, 2.4, -1.2) * CFrame.Angles(math.rad(-50 - u * 50), 0, 0)
		held.place(hand)
		local mouth = (hand * CFrame.new(0, 2.1 * 0.9, 0)).Position
		local hitG = gf + dir * 2 + Vector3.new(0, 0.3, 0)
		spout.Size = Vector3.new(0.45, 0.45, (hitG - mouth).Magnitude)
		spout.CFrame = CFrame.lookAt((mouth + hitG) / 2, hitG)
		if u >= 1 then
			fadeGourd(held, 0.3)
			fadeOut(spout, 0.3)
		end
	end)
	-- 강: 앞으로 흘러가며 넓어지는 술빛 물길, 물길 위를 흘러가는 물결
	local river = part(Vector3.new(0.2, W, 1), WINE, Enum.Material.Glass, 0.25)
	local shine = part(Vector3.new(0.21, W * 0.4, 1), WINE_LIGHT, Enum.Material.Neon, 0.6)
	anim(delay + 0.35, function(u)
		local l = math.max(1, len * u)
		local mid = gf + dir * (l / 2) + Vector3.new(0, 0.12, 0)
		local cf = CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, 0, math.rad(90))
		river.Size = Vector3.new(0.2, W, l)
		river.CFrame = cf
		shine.Size = Vector3.new(0.22, W * 0.4, l)
		shine.CFrame = cf
	end)
	local n = math.floor(dur / 0.25)
	for k = 0, n - 1 do
		task.delay(delay + k * 0.25, function()
			local rip = part(Vector3.new(0.12, W * 0.9, 0.3), WINE_LIGHT, Enum.Material.Neon, 0.3)
			local s = gf + Vector3.new(0, 0.25, 0)
			anim(0.8, function(u)
				local p = s + dir * (len * u)
				rip.CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(0, 0, math.rad(90))
				rip.Transparency = 0.3 + 0.7 * u
				if u >= 1 then
					rip:Destroy()
				end
			end)
		end)
	end
	-- 불이 붙는다: 강을 따라 불꽃이 앞으로 번진다
	task.delay(delay + dur, function()
		for k = 0, 11 do
			task.delay(k * 0.03, function()
				local p = gf + dir * (len * (k + 0.5) / 12) + Vector3.new(0, 0.3, 0)
				local tongue = part(Vector3.new(W * 0.5, 0.6, W * 0.5), FLAME, Enum.Material.Neon, 0.1, "ball")
				tongue.Position = p
				tween(tongue, 0.3, { Size = Vector3.new(W * 0.35, 7 + math.random() * 3, W * 0.35), Position = p + Vector3.new(0, 3.5, 0) })
				task.delay(0.3, function()
					fadeOut(tongue, 0.3, { Size = Vector3.new(0.4, 9, 0.4) })
				end)
				Fx.burst("ember", p, FLAME, 4, 1)
			end)
		end
		fadeOut(river, 0.6)
		fadeOut(shine, 0.4)
		Fx.flash(gf:Lerp(gt, 0.5), FLAME, len, 4, 0.5)
		Fx.breakSound("boom", 0.9, 1.1, gf:Lerp(gt, 0.5))
		shakeNear(from, 0.8, 90)
	end)
end

------------------------------------------------------------------------
-- 팔선강림 (오의): 여덟 신선의 그림자가 둘레에 나타나 차례로 적에게 덮쳐 들고, 하늘에서 거대한 호리병이 내리꽂힌다
------------------------------------------------------------------------
-- 신선 그림자 하나: 도포 자락 (넓어지는 몸), 머리, 늘어진 소매, 손의 작은 호리병
local function immortal(at: Vector3, face: Vector3): { BasePart }
	local list = {}
	local cf = CFrame.lookAt(at, at + face)
	local function add(size: Vector3, off: CFrame, color: Color3, shape: string?)
		local p = part(size, color, Enum.Material.ForceField, 0.25, shape)
		p.CFrame = cf * off
		table.insert(list, p)
		return p
	end
	add(Vector3.new(2.4, 3.6, 1.8), CFrame.new(0, 0.2, 0), GHOST)
	add(Vector3.new(3.2, 1.4, 2.4), CFrame.new(0, -1.9, 0), GHOST)
	add(Vector3.new(1.3, 1.3, 1.3), CFrame.new(0, 2.7, 0), GHOST, "ball")
	add(Vector3.new(0.9, 2.6, 0.9), CFrame.new(1.7, 0.4, -0.3) * CFrame.Angles(math.rad(-30), 0, math.rad(20)), GHOST)
	add(Vector3.new(0.9, 2.6, 0.9), CFrame.new(-1.7, 0.4, -0.3) * CFrame.Angles(math.rad(-30), 0, math.rad(-20)), GHOST)
	local g = gourd(0.45)
	g.place(cf * CFrame.new(2.1, -0.6, -0.8))
	for _, p in ipairs(g.parts) do
		table.insert(list, p)
	end
	return list
end
local function eightImmortals(data: any)
	local at: Vector3 = data.at
	if not near(at, 320) then
		return
	end
	local spots: { Vector3 } = data.spots or {}
	local targets: { any } = data.targets or {}
	local delay, every = data.delay or 0.35, data.every or 0.18
	local g0 = ground(at)
	if opts.tint then
		opts.tint(Color3.fromRGB(200, 170, 255), 0.25, delay + every * #spots + 1.2)
	end
	Fx.ring(g0 + Vector3.new(0, 0.3, 0), WINE, 4, 30, 0.6)
	for i, s in ipairs(spots) do
		local pos = Vector3.new(s.X, at.Y, s.Z)
		local ghost = immortal(pos, (at - pos).Unit)
		for _, p in ipairs(ghost) do
			p.Transparency = 1
			tween(p, 0.2, { Transparency = 0.25 })
		end
		task.delay(delay + (i - 1) * every, function()
			local tm = targets[i]
			local tr = typeof(tm) == "Instance" and rootOf(tm) or nil
			local dest = tr and tr.Position or at
			local shift = dest - pos
			-- 덮쳐 든다: 그림자 전체가 목표로 미끄러지며 옅어진다
			for _, p in ipairs(ghost) do
				fadeOut(p, 0.3, { CFrame = p.CFrame + shift * 0.9 })
			end
			local trail = part(Vector3.new(0.4, 0.4, shift.Magnitude + 0.1), GHOST, Enum.Material.Neon, 0.3)
			trail.CFrame = CFrame.lookAt(pos + shift / 2, dest)
			fadeOut(trail, 0.3)
			task.delay(0.15, function()
				Fx.ring(ground(dest) + Vector3.new(0, 0.3, 0), WINE_LIGHT, 2, 12, 0.3)
				splash(ground(dest) + Vector3.new(0, 0.6, 0), 6, 10)
				Fx.sound("hit", 0.8, 0.8 + i * 0.05, dest)
			end)
		end)
	end
	-- 하늘의 거대한 호리병이 내리꽂힌다
	local tEnd = delay + (#spots - 1) * every + (data.finalAt or 0.45)
	local big = gourd(7)
	local top = g0 + Vector3.new(0, 70, 0)
	big.place(CFrame.new(top) * CFrame.Angles(math.pi, 0, 0))
	for _, p in ipairs(big.parts) do
		p.Transparency = 1
	end
	task.delay(tEnd - 0.5, function()
		anim(0.5, function(u)
			local e = u * u
			big.place(CFrame.new(top:Lerp(g0 + Vector3.new(0, 10, 0), e)) * CFrame.Angles(math.pi, u * 2, 0))
			for _, p in ipairs(big.parts) do
				p.Transparency = 1 - math.min(1, u * 3)
			end
		end)
	end)
	task.delay(tEnd, function()
		fadeGourd(big, 0.5)
		local R = data.finalRadius or 18
		local wave = part(Vector3.new(1.2, 4, 4), WINE, Enum.Material.Glass, 0.2, "cyl")
		wave.CFrame = CFrame.new(g0 + Vector3.new(0, 0.6, 0)) * UPRIGHT
		fadeOut(wave, 0.6, { Size = Vector3.new(0.3, R * 2.6, R * 2.6) })
		splash(g0 + Vector3.new(0, 1, 0), 26, 22)
		Fx.ring(g0 + Vector3.new(0, 0.4, 0), WINE_LIGHT, 4, R * 2.6, 0.6)
		Fx.flash(g0, WINE_LIGHT, R * 3, 5, 0.5)
		Fx.breakSound("glass", 1, 0.6, g0)
		Fx.breakSound("rock", 1, 1, g0)
		shakeNear(at, 1.8, 140)
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	winePulse = winePulse,
	drunkZig = drunkZig,
	wineRiver = wineRiver,
	eightImmortals = eightImmortals,
}
function Gourd.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil
end
function Gourd.run(data: any)
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end
-- 렌더 확인용
Gourd._gourd = gourd
Gourd._immortal = immortal
local _ = Config
return Gourd
