-- 권왕 2.7판: 진 무극신권의 먹과 붓 (화면)
-- 획은 겹쳐 찍은 먹 방울로 그린다: 붓을 누른 처음은 굵고, 끝으로 갈수록 가늘어지며, 가장자리에 먹이 튄다.
-- 먹은 잠시 뒤 금빛으로 타오르며 터진다
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Ink = {}
local _player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "KwonInk"
folder.Parent = workspace

local opts: any = {}
function Ink.init(o: any)
	opts = o or {}
end

local INK = Color3.fromRGB(14, 14, 18)
local INK2 = Color3.fromRGB(34, 32, 38)
local GOLD = Color3.fromRGB(255, 214, 120)
local GOLD2 = Color3.fromRGB(255, 244, 200)
local WOOD = Color3.fromRGB(70, 44, 30)
local UP = CFrame.Angles(0, 0, math.rad(90))

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

-- 붓의 누름: 처음 0.15까지 굵어지고, 끝으로 가며 가늘어진다 (조금 물결친다)
local function pressure(u: number, seed: number): number
	local rise = math.clamp(u / 0.15, 0, 1)
	local fall = 1 - u * 0.7
	return (0.55 + 0.45 * rise) * fall * (1 + math.sin(u * 9 + seed) * 0.08)
end
-- 땅 위의 획: points를 따라 먹 방울을 찍는다. draw 동안 차례로 나타난다. 찍힌 조각 목록을 돌려준다
local function groundStroke(points: { Vector3 }, width: number, draw: number, seed: number): { BasePart }
	local out: { BasePart } = {}
	local total = 0
	for i = 2, #points do
		total += (points[i] - points[i - 1]).Magnitude
	end
	if total <= 0 then
		return out
	end
	local step = math.max(0.4, width * 0.32)
	local n = math.max(2, math.floor(total / step))
	local seg, acc = 2, 0
	for k = 0, n do
		local dist = total * k / n
		while seg < #points and acc + (points[seg] - points[seg - 1]).Magnitude < dist do
			acc += (points[seg] - points[seg - 1]).Magnitude
			seg += 1
		end
		local a, b = points[seg - 1], points[seg]
		local L = (b - a).Magnitude
		local pos = L > 0 and a:Lerp(b, math.clamp((dist - acc) / L, 0, 1)) or a
		local u = k / n
		local d = width * pressure(u, seed)
		local p = part(Vector3.new(0.12, d, d), u < 0.5 and INK or INK:Lerp(INK2, (u - 0.5)), Enum.Material.SmoothPlastic, 1, "cyl")
		p.CFrame = CFrame.new(ground(pos) + Vector3.new(0, 0.12 + (k % 3) * 0.004, 0)) * UP
		table.insert(out, p)
		task.delay(draw * u, function()
			if p.Parent then
				p.Transparency = 0
			end
		end)
		-- 가장자리에 튄 먹
		if (k * 7 + seed) % 5 == 0 then
			local side = Vector3.new(math.cos(k * 2.3 + seed), 0, math.sin(k * 2.3 + seed)) * d * (0.65 + (k % 3) * 0.15)
			local dot = part(Vector3.new(0.1, d * 0.22, d * 0.22), INK, Enum.Material.SmoothPlastic, 1, "cyl")
			dot.CFrame = CFrame.new(ground(pos + side) + Vector3.new(0, 0.11, 0)) * UP
			table.insert(out, dot)
			task.delay(draw * u + 0.03, function()
				if dot.Parent then
					dot.Transparency = 0
				end
			end)
		end
	end
	return out
end
-- 먹이 금빛으로 타올라 터진다: 조각들이 금빛이 되었다가 부풀며 사라지고, 몇 곳에서 금빛 기둥이 솟는다
local function ignite(parts: { BasePart }, life: number, columns: number?)
	for i, p in ipairs(parts) do
		if p.Parent then
			task.delay((i % 6) * 0.02, function()
				if not p.Parent then
					return
				end
				p.Material = Enum.Material.Neon
				tween(p, 0.12, { Color = GOLD })
				task.delay(0.12, function()
					if p.Parent then
						fadeOut(p, life, { Size = p.Size * Vector3.new(1, 1.5, 1.5), Color = GOLD2 })
					end
				end)
			end)
		end
	end
	local nc = columns or 0
	for c = 1, nc do
		local p = parts[math.max(1, math.floor(#parts * c / (nc + 1)))]
		if p and p.Parent then
			local at = p.Position
			local col = part(Vector3.new(1, 1.2, 1.2), GOLD, Enum.Material.Neon, 0.1, "cyl")
			col.CFrame = CFrame.new(at + Vector3.new(0, 0.5, 0)) * UP
			fadeOut(col, 0.45, { Size = Vector3.new(16, 0.3, 0.3), CFrame = CFrame.new(at + Vector3.new(0, 8, 0)) * UP })
		end
	end
end

------------------------------------------------------------------------
-- 일획 (E): 허공의 먹 획
------------------------------------------------------------------------
local function inkSlash(data: any)
	local from: Vector3, to: Vector3 = data.from, data.to
	if not near(from, 220) then
		return
	end
	local seed = data.seed or 1
	local delay = data.delay or 0.15
	local W = (data.width or 5) * 0.75
	local dir = (to - from)
	local L = dir.Magnitude
	dir = dir.Unit
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local blots: { BasePart } = {}
	local n = math.floor(L / 0.8)
	task.delay(delay * 0.6, function()
		for k = 0, n do
			local u = k / n
			-- 살짝 휜 획 (가운데가 앞으로 부푼다), 처음은 조금 높고 끝은 낮게
			local pos = from:Lerp(to, u) + side * math.sin(u * math.pi) * 2.2 + Vector3.new(0, 1.2 - u * 0.9, 0)
			local d = W * pressure(u, seed)
			local b = part(Vector3.new(0.35, d, d * 1.5), INK, Enum.Material.SmoothPlastic, 0, "ball")
			b.CFrame = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, 0, math.rad(8))
			b.Transparency = 1
			table.insert(blots, b)
			task.delay(u * 0.12, function()
				if b.Parent then
					b.Transparency = 0
				end
			end)
			-- 금빛 심 (획 가운데의 가는 빛)
			if k % 3 == 0 then
				local core = part(Vector3.new(0.12, d * 0.18, 1.4), GOLD, Enum.Material.Neon, 1)
				core.CFrame = CFrame.lookAt(pos, pos + dir)
				table.insert(blots, core)
				task.delay(u * 0.12 + 0.02, function()
					if core.Parent then
						core.Transparency = 0.2
					end
				end)
			end
			if k % 4 == 1 then
				local drop = part(Vector3.new(0.3, 0.3, 0.3) * (0.6 + (k % 3) * 0.3), INK, Enum.Material.SmoothPlastic, 0, "ball")
				drop.CFrame = CFrame.new(pos + side * (math.random() - 0.5) * d)
				fadeOut(drop, 0.6, { CFrame = CFrame.new(ground(pos) + side * (math.random() - 0.5) * 2) })
			end
		end
		Fx.sound("swing", 0.8, 0.7, from)
		shakeNear(from, 0.4, 60)
	end)
	-- 잠시 뒤 금빛으로 타오른다
	task.delay(delay + (data.burstAt or 0.5), function()
		ignite(blots, 0.35, 0)
		Fx.ring(ground(from:Lerp(to, 0.5)) + Vector3.new(0, 0.3, 0), GOLD, 2, L * 0.9, 0.35)
		Fx.sound("shatter", 0.6, 1.2, from)
		shakeNear(from, 0.6, 70)
	end)
end

------------------------------------------------------------------------
-- 원상 (R): 발밑의 먹 원과 솟는 먹 벽
------------------------------------------------------------------------
local function ensoPoints(at: Vector3, R: number, startA: number, span: number, n: number): { Vector3 }
	local pts = {}
	for k = 0, n do
		local a = startA + span * k / n
		-- 손으로 그린 원: 반지름이 조금씩 흔들린다
		local r = R * (1 + math.sin(a * 3 + startA) * 0.03)
		table.insert(pts, at + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
	end
	return pts
end
local function enso(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local R = data.radius or 16
	local draw = data.draw or 0.55
	local a0 = math.random() * math.pi * 2
	local parts = groundStroke(ensoPoints(at, R, a0, math.rad(335), 36), 3.4, draw, a0)
	Fx.sound("swing", 0.7, 0.55, at)
	task.delay(draw, function()
		-- 먹 벽: 원을 따라 검은 기둥이 솟는다
		local walls: { BasePart } = {}
		for k = 0, 23 do
			local a = a0 + k / 24 * math.pi * 2
			local p0 = ground(at) + Vector3.new(math.cos(a) * R, 0, math.sin(a) * R)
			local w = part(Vector3.new(0.6, 2.6, 0.6), INK, Enum.Material.SmoothPlastic, 0.15)
			w.CFrame = CFrame.new(p0 + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, -a, 0)
			tween(w, 0.2, { Size = Vector3.new(0.6, 2.6, 7 + (k % 3) * 1.5), CFrame = CFrame.new(p0 + Vector3.new(0, 3.6 + (k % 3) * 0.75, 0)) * CFrame.Angles(0, -a, 0) * CFrame.Angles(math.rad(90), 0, 0) })
			table.insert(walls, w)
		end
		shakeNear(at, 0.6, 70)
		task.delay(data.burstAt or 0.35, function()
			ignite(parts, 0.4, 6)
			ignite(walls, 0.3, 0)
			Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), GOLD, 2, R * 2.4, 0.4)
			Fx.flash(at, GOLD, 60, 4, 0.4)
			Fx.sound("shatter", 0.8, 0.9, at)
			shakeNear(at, 1.0, 90)
		end)
	end)
end

------------------------------------------------------------------------
-- 무극필 (오의): 하늘의 큰 붓, 먹의 꽃, 금빛
------------------------------------------------------------------------
type Brush = { parts: { { p: BasePart, off: CFrame } } }
local function makeBrush(S: number): Brush
	local b: Brush = { parts = {} }
	local function add(size: Vector3, off: CFrame, color: Color3, mat: Enum.Material?, shape: string?)
		local p = part(size * S, color, mat, 0, shape)
		table.insert(b.parts, { p = p, off = CFrame.new(off.Position * S) * off.Rotation })
	end
	-- 붓끝이 0, 위로 붓털 → 쇠 테 → 긴 대 → 끝의 술
	add(Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 0.3, 0), INK, Enum.Material.SmoothPlastic, "ball")
	for k = 0, 4 do
		local w = 0.7 + k * 0.28
		add(Vector3.new(w, 0.9, w), CFrame.new(0, 0.75 + k * 0.6, 0), k < 3 and INK or INK2, Enum.Material.SmoothPlastic, "ball")
	end
	add(Vector3.new(0.4, 1.9, 1.9), CFrame.new(0, 3.9, 0) * UP, GOLD, Enum.Material.Metal, "cyl")
	add(Vector3.new(10, 1.3, 1.3), CFrame.new(0, 9.0, 0) * UP, WOOD, Enum.Material.Wood, "cyl")
	add(Vector3.new(0.5, 1.6, 1.6), CFrame.new(0, 14.1, 0) * UP, GOLD, Enum.Material.Metal, "cyl")
	add(Vector3.new(0.3, 2.2, 0.3), CFrame.new(0, 15.4, 0), Color3.fromRGB(170, 30, 30), Enum.Material.Fabric)
	return b
end
local function placeBrush(b: Brush, cf: CFrame)
	for _, e in ipairs(b.parts) do
		e.p.CFrame = cf * e.off
	end
end
local function flowerStroke(center: Vector3, R: number, a0: number): { Vector3 }
	local pts = { center }
	for k = 1, 5 do
		local r = 3 + (R - 3) * k / 5
		local a = a0 + 0.75 * k / 5
		table.insert(pts, center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
	end
	return pts
end
local function inkFlower(data: any)
	local at: Vector3 = data.at
	if not near(at, 260) then
		return
	end
	local R = data.radius or 22
	local n = data.strokes or 8
	local delay, every = data.delay or 0.35, data.every or 0.16
	local rot = data.rot or 0
	local order = { 1, 5, 3, 7, 2, 6, 4, 8 }
	local all: { BasePart } = {}
	local brush = makeBrush(1.6)
	local brushAt = at + Vector3.new(0, 30, 0)
	placeBrush(brush, CFrame.new(brushAt))
	for _, e in ipairs(brush.parts) do
		e.p.Transparency = 1
		tween(e.p, delay, { Transparency = 0 })
	end
	-- 하늘이 옅은 잿빛으로 (가까운 사람만)
	local cc: ColorCorrectionEffect? = nil
	if near(at, 160) then
		local e = Instance.new("ColorCorrectionEffect")
		e.Name = "KwonInk"
		e.Parent = game:GetService("Lighting")
		tween(e, delay, { Saturation = -0.7, Contrast = 0.2 })
		cc = e
	end
	local strokeT = every * 0.85
	local tStroke = delay
	for i = 1, n do
		local a0 = rot + ((order[i] or i) - 1) / n * math.pi * 2
		local pts = flowerStroke(at, R, a0)
		task.delay(tStroke, function()
			local list = groundStroke(pts, 4.6, strokeT, a0)
			for _, p in ipairs(list) do
				table.insert(all, p)
			end
			-- 붓이 획을 따라 내리긋는다 (붓끝이 땅에 닿는다)
			local t0 = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function()
				local u = math.clamp((os.clock() - t0) / strokeT, 0, 1)
				local idx = 1 + u * (#pts - 1)
				local i0 = math.clamp(math.floor(idx), 1, #pts - 1)
				local pos = pts[i0]:Lerp(pts[i0 + 1], idx - i0)
				local tip = ground(pos) + Vector3.new(0, 0.2, 0)
				local tilt = CFrame.Angles(math.rad(-25), a0 + math.pi / 2, 0)
				placeBrush(brush, CFrame.new(tip) * tilt)
				if u >= 1 then
					conn:Disconnect()
				end
			end)
			Fx.sound("swing", 0.6, 0.6 + i * 0.03, at)
			shakeNear(at, 0.25, 60)
		end)
		tStroke += every
	end
	-- 둘레에 원을 두른다
	local ringAt = tStroke + (data.ringAt or 0.3) - every
	task.delay(ringAt - 0.25, function()
		local a1 = rot
		local list = groundStroke(ensoPoints(at, R + 1, a1, math.rad(340), 40), 3.6, 0.25, a1)
		for _, p in ipairs(list) do
			table.insert(all, p)
		end
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local u = math.clamp((os.clock() - t0) / 0.25, 0, 1)
			local a = a1 + math.rad(340) * u
			local tip = ground(at + Vector3.new(math.cos(a) * (R + 1), 0, math.sin(a) * (R + 1))) + Vector3.new(0, 0.2, 0)
			placeBrush(brush, CFrame.new(tip) * CFrame.Angles(math.rad(-30), -a, 0))
			if u >= 1 then
				conn:Disconnect()
			end
		end)
	end)
	-- 그림 전체가 금빛으로 타오르며 터진다
	task.delay(ringAt + (data.finalAt or 0.45), function()
		ignite(all, 0.5, 10)
		for _, e in ipairs(brush.parts) do
			fadeOut(e.p, 0.4, { CFrame = e.p.CFrame + Vector3.new(0, 16, 0) })
		end
		local g = ground(at)
		Fx.ring(g + Vector3.new(0, 0.3, 0), GOLD, 4, (R + 4) * 2.4, 0.6)
		task.delay(0.08, function()
			Fx.ring(g + Vector3.new(0, 0.35, 0), GOLD2, 4, (R + 4) * 2, 0.5)
		end)
		local col = part(Vector3.new(2, 8, 8), GOLD, Enum.Material.Neon, 0.05, "cyl")
		col.CFrame = CFrame.new(g + Vector3.new(0, 1, 0)) * UP
		fadeOut(col, 0.6, { Size = Vector3.new(80, 1, 1), CFrame = CFrame.new(g + Vector3.new(0, 40, 0)) * UP })
		Fx.flash(at, GOLD, 120, 9, 0.7)
		Fx.sound("shatter", 1, 0.7, at)
		Fx.sound("heavy", 1, 0.55, at)
		shakeNear(at, 2.4, 150)
		local e = cc
		if e then
			tween(e, 0.6, { Saturation = 0, Contrast = 0 })
			task.delay(0.65, function()
				e:Destroy()
			end)
		end
	end)
	task.delay(ringAt + 4, function()
		if cc and cc.Parent then
			cc:Destroy()
		end
		for _, e in ipairs(brush.parts) do
			if e.p.Parent then
				e.p:Destroy()
			end
		end
	end)
end

------------------------------------------------------------------------
-- 먹 번짐 (네 번째 일격): 상대 발밑에 먹이 사방으로 번졌다가 금빛으로 터진다
------------------------------------------------------------------------
local function inkPulse(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local R = data.radius or 10
	local parts: { BasePart } = {}
	local seed = math.random() * 6
	for k = 0, 6 do
		local a = seed + k / 7 * math.pi * 2
		local L = R * (0.55 + ((k * 5) % 4) * 0.12)
		local pts = { at, at + Vector3.new(math.cos(a) * L, 0, math.sin(a) * L) }
		for _, p in ipairs(groundStroke(pts, 2.4, 0.16, a)) do
			table.insert(parts, p)
		end
	end
	local blot = part(Vector3.new(0.13, 2, 2), INK, Enum.Material.SmoothPlastic, 0, "cyl")
	blot.CFrame = CFrame.new(ground(at) + Vector3.new(0, 0.13, 0)) * UP
	tween(blot, 0.15, { Size = Vector3.new(0.13, R * 0.9, R * 0.9) })
	table.insert(parts, blot)
	task.delay(data.delay or 0.45, function()
		ignite(parts, 0.3, 2)
		Fx.sound("shatter", 0.5, 1.4, at)
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	inkSlash = inkSlash,
	enso = enso,
	inkFlower = inkFlower,
	inkPulse = inkPulse,
}
function Ink.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil
end
function Ink.run(data: any)
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end
local _ = Config
return Ink
