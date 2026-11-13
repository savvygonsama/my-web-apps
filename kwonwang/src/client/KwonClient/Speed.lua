-- 권왕 3.22판: 극 광속권의 화면. 빛과 소리 (하늘색 · 흰색 · 금빛 줄)
-- 광속 관통 · 음속 돌파 · 유성 질주 · 광속 일섬 (초 오의) / 광침 · 지그재그 질주 · 마하 폭풍 · 유성 연쇄 (초가속)
-- 극 패시브 초가속의 컷씬과 달리는 동안의 잔상, 연타 장치 음속 충격
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Fx = require(script.Parent:WaitForChild("Fx"))
local CamGuard = require(script.Parent:WaitForChild("CamGuard"))

local Speed = {}

local folder = Instance.new("Folder")
folder.Name = "KwonSpeed"
folder.Parent = workspace

local opts: any = {}
local started = false

local CYAN = Color3.fromRGB(120, 225, 255)
local ICE = Color3.fromRGB(200, 245, 255)
local GOLD = Color3.fromRGB(255, 215, 110)
local WHITE = Color3.new(1, 1, 1)
local UP = Vector3.new(0, 1, 0)

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
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
local function ground(at: Vector3): Vector3
	return Vector3.new(at.X, at.Y - 2.7, at.Z)
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
-- 화면 빛깔
local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "KwonSpeedGrade"
grade.Parent = Lighting
local function gradeTo(time: number, sat: number, bright: number, contrast: number, tintC: Color3?)
	tween(grade, time, { Saturation = sat, Brightness = bright, Contrast = contrast, TintColor = tintC or WHITE })
end
local function gradeReset(time: number)
	gradeTo(time, 0, 0, 0, WHITE)
end

function Speed.init(o: any)
	opts = o or {}
	if started then
		return
	end
	started = true
	-- 달리는 동안의 잔상: 가속 단계가 높거나 초가속인 사람 (내 화면 근처만)
	task.spawn(function()
		local lastPos: { [Model]: Vector3 } = {}
		local flip = false
		while true do
			task.wait(0.07)
			local cam = workspace.CurrentCamera
			if cam then
				for _, pl in ipairs(Players:GetPlayers()) do
					local ch = pl.Character
					local r = ch and rootOf(ch)
					if ch and r and (r.Position - cam.CFrame.Position).Magnitude < 140 then
						local n = tonumber(ch:GetAttribute("Haste")) or 0
						local tw = ch:GetAttribute("Twilight") == true and ch:GetAttribute("Geuk") ~= nil
						local prev = lastPos[ch]
						lastPos[ch] = r.Position
						if prev and (n >= 2 or tw) then
							local sp = (r.Position - prev).Magnitude / 0.07
							if sp > 24 then
								flip = not flip
								Fx.afterimage(ch, flip and CYAN or GOLD, 0.28 + math.min(0.3, n * 0.05))
							end
						end
					end
				end
			end
		end
	end)
end

local H: { [string]: (any) -> () } = {}

-- 증기 원뿔: tip에서 뒤(dir 반대)로 벌어지는 하얀 고리들
local function vaporCone(tip: Vector3, dir: Vector3, len: number, wid: number, color: Color3?)
	for k = 1, 9 do
		local u = k / 9
		local p = tip - dir * (u * len) + Vector3.new(0, 0.5, 0)
		local ring = part(Vector3.new(0.6, 1, 1), color or WHITE, Enum.Material.Neon, 0.35, "cyl")
		ring.CFrame = safeLook(p, p + dir) * CFrame.Angles(0, math.rad(90), 0)
		local goal = wid * u + 3
		task.delay(u * 0.12, function()
			ring.Size = Vector3.new(0.6, goal * 0.5, goal * 0.5)
			tween(ring, 0.5, { Size = Vector3.new(0.5, goal * 2, goal * 2), Transparency = 1 })
		end)
		task.delay(0.8, function()
			ring:Destroy()
		end)
	end
end

------------------------------------------------------------------------
-- 광속 관통 (E): 쏘아 지나간 자리에 빛의 줄이 남고 잠시 뒤 줄 전체가 터진다
------------------------------------------------------------------------
function H.lightLance(d: any)
	local a: Vector3, b: Vector3 = d.from, d.to
	if not near(a, 300) then
		return
	end
	local m = d.m
	for i = 0, 7 do
		task.delay(i * 0.03, function()
			if m and m.Parent then
				Fx.afterimage(m, i % 2 == 0 and CYAN or ICE, 0.5)
			end
		end)
	end
	local mid = Vector3.new(0, 1.2, 0)
	local outer = beamTo(a + mid, b + mid, 3.4, CYAN, 0.55)
	local core = beamTo(a + mid, b + mid, 0.7, WHITE, 0)
	Fx.breakSound("whoosh", 0.9, 1.5, a)
	Fx.burst("spark", a, ICE, 14, 1.4)
	-- 줄이 가느다랗게 숨 쉰다 (곧 터진다는 신호)
	local wait = d.delay or 0.5
	anim(wait, function(u)
		local w = 0.7 + math.sin(u * 40) * 0.3 + u * 0.6
		setBeam(core, a + mid, b + mid, w)
		outer.Transparency = 0.55 + u * 0.25
	end)
	task.delay(wait, function()
		core.Color = GOLD
		for k = 0, 8 do
			local p = a:Lerp(b, k / 8) + mid
			local boom = part(Vector3.new(2, 2, 2), k % 2 == 0 and GOLD or ICE, Enum.Material.Neon, 0.1, "ball")
			boom.Position = p
			fadeOut(boom, 0.4, { Size = Vector3.new(11, 11, 11) })
			if k % 3 == 0 then
				Fx.ring(ground(p), GOLD, 3, 16, 0.4)
			end
		end
		fadeOut(core, 0.35, { Size = Vector3.new((b - a).Magnitude, 4, 4) })
		fadeOut(outer, 0.3)
		Fx.breakSound("boom", 0.8, 1.3, b)
		shakeNear(b, 0.7, 120)
	end)
end

------------------------------------------------------------------------
-- 음속 돌파 (R): 벽을 뚫는 순간 몸 뒤로 하얀 증기 원뿔이 터진다
------------------------------------------------------------------------
function H.sonicBoom(d: any)
	local a: Vector3, b: Vector3 = d.from, d.to
	if not near(a, 300) then
		return
	end
	local m = d.m
	local dir = flat(b - a)
	for i = 0, 5 do
		task.delay(i * 0.04, function()
			if m and m.Parent then
				Fx.afterimage(m, ICE, 0.45)
			end
		end)
	end
	Fx.breakSound("whoosh", 0.9, 1.1, a)
	Fx.ring(ground(a), WHITE, 3, 20, 0.35)
	task.delay(d.coneAt or 0.3, function()
		local r = m and rootOf(m)
		local tip = r and r.Position or b
		local len, wid = d.coneLen or 22, d.coneWidth or 16
		-- 증기 원뿔: 꼭짓점에서 뒤로 벌어지는 하얀 고리들
		for k = 1, 9 do
			local u = k / 9
			local p = tip - dir * (u * len) + Vector3.new(0, 0.5, 0)
			local ring = part(Vector3.new(0.6, 1, 1), WHITE, Enum.Material.Neon, 0.35, "cyl")
			ring.CFrame = safeLook(p, p + dir) * CFrame.Angles(0, math.rad(90), 0)
			local goal = wid * u + 3
			task.delay(u * 0.12, function()
				ring.Size = Vector3.new(0.6, goal * 0.5, goal * 0.5)
				tween(ring, 0.5, { Size = Vector3.new(0.5, goal * 2, goal * 2), Transparency = 1 })
			end)
			task.delay(0.8, function()
				ring:Destroy()
			end)
		end
		local vapor = part(Vector3.new(2, 2, 2), WHITE, Enum.Material.Neon, 0.6, "ball")
		vapor.Position = tip - dir * 4
		fadeOut(vapor, 0.5, { Size = Vector3.new(wid * 2, wid * 1.4, wid * 2) })
		Fx.ring(ground(tip), CYAN, 4, 34, 0.5)
		Fx.flash(tip + Vector3.new(0, 3, 0), ICE, 30, 3, 0.3)
		Fx.breakSound("boom", 1, 0.8, tip)
		shakeNear(tip, 1.0, 140)
	end)
end

-- 유성 질주 (G): 둘레를 별 모양으로 열 번 가로지른다. 달린 길마다 빛의 선이 남고 마지막에 모든 선이 한꺼번에 번쩍인다
------------------------------------------------------------------------
function H.meteorRun(d: any)
	local C: Vector3 = d.at
	if not near(C, 400) then
		return
	end
	local m = d.m
	local V: { Vector3 } = d.pts or {}
	local every, finalAt = d.every or 0.14, d.finalAt or 0.3
	local rails: { BasePart } = {}
	local up = Vector3.new(0, 1.4, 0)
	Fx.breakSound("whoosh", 0.9, 1.6, C)
	local function seg(a: Vector3, b: Vector3, i: number)
		local col = (i % 2 == 0) and CYAN or GOLD
		local rail = beamTo(a + up, b + up, 1.5, col, 0.35)
		local core = beamTo(a + up, b + up, 0.4, WHITE, 0)
		table.insert(rails, rail)
		table.insert(rails, core)
		if m and m.Parent then
			Fx.afterimage(m, col, 0.45)
		end
		Fx.ring(ground(a), ICE, 2, 12, 0.3)
		Fx.burst("spark", b, col, 6, 1.1)
		Fx.sound("swing", 0.5, 1.3 + (i % 5) * 0.15, b)
		shakeNear(b, 0.25, 90)
		-- 땅에 그은 그을음 줄
		local scorch = part(Vector3.new((b - a).Magnitude, 0.12, 1.6), Color3.fromRGB(30, 60, 80), Enum.Material.Neon, 0.4)
		scorch.CFrame = safeLook((a + b) / 2, b) * CFrame.Angles(0, 0, 0)
		scorch.Position = Vector3.new((a.X + b.X) / 2, ground((a + b) / 2).Y + 0.15, (a.Z + b.Z) / 2)
		fadeOut(scorch, 1.1)
	end
	task.delay(0.04, function()
		seg(C, V[1], 0)
	end)
	for i = 1, #V - 1 do
		task.delay(i * every, function()
			seg(V[i], V[i + 1], i)
		end)
	end
	task.delay((#V - 1) * every + finalAt, function()
		-- 모든 선이 한꺼번에 번쩍인다
		for _, rl in ipairs(rails) do
			rl.Color = WHITE
			tween(rl, 0.18, { Size = Vector3.new(rl.Size.X, 4.5, 4.5) })
			fadeOut(rl, 0.55)
		end
		for _, v in ipairs(V) do
			local boom = part(Vector3.new(2, 2, 2), GOLD, Enum.Material.Neon, 0.15, "ball")
			boom.Position = v + up
			fadeOut(boom, 0.45, { Size = Vector3.new(10, 10, 10) })
		end
		local pillar = part(Vector3.new(120, 8, 8), WHITE, Enum.Material.Neon, 0.1, "cyl")
		pillar.CFrame = CFrame.new(ground(C) + Vector3.new(0, 55, 0)) * CFrame.Angles(0, 0, math.rad(90))
		fadeOut(pillar, 0.6, { Size = Vector3.new(120, 2, 2) })
		Fx.ring(ground(C), GOLD, 4, (d.radius or 26) * 2.2, 0.55)
		Fx.ring(ground(C), WHITE, 2, (d.radius or 26) * 1.5, 0.4)
		Fx.flash(C + Vector3.new(0, 5, 0), WHITE, 80, 4, 0.4)
		Fx.breakSound("boom", 1, 0.8, C)
		shakeNear(C, 1.2, 200)
	end)
end

------------------------------------------------------------------------
-- 광속 일섬 (초 오의): 음속 · 광속 · 초광속, 세 걸음. 걸음마다 더 길고 더 환하고 더 굵다
------------------------------------------------------------------------
function H.lightDash(d: any)
	local P: { Vector3 } = d.pts or {}
	if #P < 2 or (not near(P[1], 500) and not near(P[#P], 500)) then
		return
	end
	local m = d.m
	local T0 = (d.cut or 1) + (d.charge or 0.5)
	local gap = d.gap or 0.3
	local mid = Vector3.new(0, 1.5, 0)
	-- 출발 전: 땅에 발을 박고 빛이 발끝에 모인다
	task.delay((d.cut or 1) * 0.5, function()
		local r = m and rootOf(m)
		if r then
			Fx.ring(ground(r.Position), ICE, 14, 2, T0 - (d.cut or 1) * 0.5)
			Fx.sound("ping", 0.6, 0.8, r.Position)
		end
	end)
	local cols = { WHITE, CYAN, GOLD }
	for i = 1, #P - 1 do
		local a, b = P[i], P[i + 1]
		local dir = flat(b - a)
		local col = cols[i] or GOLD
		task.delay(T0 + (i - 1) * gap, function()
			local w = 3 + i * 2.5
			local halo = beamTo(a + mid, b + mid, w * 2.4, col, 0.7)
			local core = beamTo(a + mid, b + mid, w, WHITE, 0)
			tween(core, 0.5, { Size = Vector3.new((b - a).Magnitude, 0.4, 0.4) })
			fadeOut(halo, 0.45, { Size = Vector3.new((b - a).Magnitude, w * 6, w * 6) })
			task.delay(0.8, function()
				fadeOut(core, 0.35)
			end)
			for k = 0, 7 do
				task.delay(k * 0.025, function()
					if m and m.Parent then
						Fx.afterimage(m, k % 2 == 0 and col or ICE, 0.6)
					end
				end)
			end
			-- 출발점의 충격: 걸음마다 커진다 (소리 → 빛 → 그 너머)
			Fx.ring(ground(a), col, 4, 18 + i * 14, 0.5)
			vaporCone(a, dir, 10 + i * 6, 10 + i * 6, col)
			Fx.flash(a + Vector3.new(0, 4, 0), col, 40 + i * 20, 3, 0.25)
			Fx.breakSound("boom", 0.7 + i * 0.1, 1.2 - i * 0.2, a)
			if opts.flash then
				opts.flash(col, 0.15 + i * 0.1)
			end
			shakeNear(a, 0.5 + i * 0.3, 220)
			-- 길 위에 짧은 사선들이 뒤늦게 그어진다
			local n = math.floor((b - a).Magnitude / 5)
			local side = Vector3.new(-dir.Z, 0, dir.X)
			for q = 1, n do
				task.delay(0.08 + (q / n) * 0.2, function()
					local p = a:Lerp(b, q / n) + mid + side * (math.random() - 0.5) * (d.width or 9)
					local up = Vector3.new(0, 2 + math.random() * 3, 0)
					local ln = beamTo(p - up - dir * 2, p + up + dir * 2, 0.3, q % 2 == 0 and col or WHITE, 0)
					fadeOut(ln, 0.3)
				end)
			end
		end)
	end
	-- 끝에서 소리가 따라붙는다
	local last = P[#P]
	task.delay(T0 + (#P - 2) * gap + (d.boomAt or 0.45), function()
		local R = d.boomRadius or 36
		Fx.ring(ground(last), WHITE, 6, R * 2, 0.7)
		Fx.ring(ground(last), GOLD, 3, R * 1.5, 0.55)
		local dome = part(Vector3.new(2, 2, 2), ICE, Enum.Material.Neon, 0.55, "ball")
		dome.Position = last
		fadeOut(dome, 0.7, { Size = Vector3.new(R * 1.6, R * 1.2, R * 1.6) })
		Fx.flash(last + Vector3.new(0, 4, 0), WHITE, 90, 4, 0.5)
		Fx.breakSound("boom", 1, 0.55, last)
		shakeNear(last, 1.6, 240)
		if opts.flash then
			opts.flash(Color3.new(1, 1, 1), 0.5)
		end
	end)
end

------------------------------------------------------------------------
-- 광침 (초가속 E)
------------------------------------------------------------------------
function H.lightNeedles(d: any)
	local a: Vector3 = d.from
	if not near(a, 300) then
		return
	end
	local len = d.length or 34
	Fx.breakSound("whoosh", 0.7, 2, a)
	task.delay(d.delay or 0.12, function()
		for i, dir in ipairs(d.dirs or {}) do
			local from = a + Vector3.new(0, 1.8, 0)
			local to = from + dir * len
			local core = beamTo(from, to, 0.3, WHITE, 0)
			local glow = beamTo(from, to, 1.4, i % 2 == 0 and CYAN or GOLD, 0.6)
			fadeOut(core, 0.28, { Size = Vector3.new(len, 0.05, 0.05) })
			fadeOut(glow, 0.22)
			Fx.burst("spark", to, ICE, 3, 0.7)
		end
		Fx.ring(ground(a), CYAN, 2, 12, 0.3)
		shakeNear(a, 0.4, 100)
	end)
end

------------------------------------------------------------------------
-- 지그재그 질주 (초가속 R)
------------------------------------------------------------------------
function H.zigzagStep(d: any)
	local pts: { Vector3 } = d.pts or {}
	if #pts < 2 or not near(pts[1], 300) then
		return
	end
	local m = d.m
	local every = d.every or 0.09
	for i = 1, #pts - 1 do
		task.delay(i * every, function()
			local a, b = pts[i] + Vector3.new(0, 1.5, 0), pts[i + 1] + Vector3.new(0, 1.5, 0)
			-- 번개처럼 꺾인 줄
			local midp = (a + b) / 2 + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 4
			local l1 = beamTo(a, midp, 0.9, GOLD, 0.05)
			local l2 = beamTo(midp, b, 0.9, GOLD, 0.05)
			local c1 = beamTo(a, midp, 0.3, WHITE, 0)
			local c2 = beamTo(midp, b, 0.3, WHITE, 0)
			for _, p in ipairs({ l1, l2, c1, c2 }) do
				fadeOut(p, 0.6)
			end
			if m and m.Parent then
				Fx.afterimage(m, i % 2 == 0 and CYAN or GOLD, 0.4)
			end
			Fx.ring(ground(pts[i + 1]), GOLD, 2, 16, 0.35)
			Fx.burst("spark", pts[i + 1], ICE, 8, 1.3)
			Fx.sound("swing", 0.7, 1.2 + i * 0.12, pts[i + 1])
			shakeNear(pts[i + 1], 0.35, 100)
		end)
	end
end

-- 마하 폭풍 (초가속 G): 한 줄기 길을 네 번 왕복한다. 지날 때마다 소리의 벽이 깨진다
------------------------------------------------------------------------
function H.machStorm(d: any)
	local A: Vector3, B: Vector3 = d.from, d.to
	if not near(A, 450) and not near(B, 450) then
		return
	end
	local m = d.m
	local every = d.every or 0.28
	local M = (A + B) / 2
	local W = d.width or 14
	local up = Vector3.new(0, 1.4, 0)
	Fx.breakSound("whoosh", 0.9, 0.7, A)
	-- 길 바닥: 하얗게 달아오른 띠
	local lane = part(Vector3.new((B - A).Magnitude, 0.12, W * 1.2), ICE, Enum.Material.Neon, 0.85)
	lane.CFrame = safeLook(M, B)
	lane.Position = Vector3.new(M.X, ground(M).Y + 0.15, M.Z)
	for i = 1, (d.passes or 4) do
		local a, b = (i % 2 == 1) and A or B, (i % 2 == 1) and B or A
		local dir = flat(b - a)
		task.delay(i * every, function()
			lane.Transparency = math.max(0.35, 0.85 - i * 0.12)
			local col = (i % 2 == 0) and GOLD or CYAN
			local core = beamTo(a + up, b + up, 2.2, WHITE, 0)
			local halo = beamTo(a + up, b + up, 7, col, 0.55)
			fadeOut(core, 0.35, { Size = Vector3.new((b - a).Magnitude, 0.3, 0.3) })
			fadeOut(halo, 0.4)
			for k = 0, 7 do
				task.delay(k * 0.03, function()
					if m and m.Parent then
						Fx.afterimage(m, k % 2 == 0 and col or ICE, 0.4)
					end
				end)
			end
			-- 소리의 벽: 지나간 자리를 따라 증기 원뿔이 여러 개 터진다
			for q = 1, 4 do
				task.delay(q * 0.035, function()
					local tip = a:Lerp(b, q / 4)
					vaporCone(tip, dir, 14, W, WHITE)
				end)
			end
			Fx.ring(ground(b), col, 3, W * 2.4, 0.45)
			Fx.burst("spark", b, ICE, 10, 1.4)
			Fx.breakSound("boom", 0.6, 1.2 + i * 0.1, b)
			shakeNear(b, 0.6, 160)
		end)
	end
	task.delay((d.passes or 4) * every + (d.finalAt or 0.3), function()
		local R = d.radius or 34
		fadeOut(lane, 0.5)
		Fx.ring(ground(M), WHITE, 6, R * 2.2, 0.7)
		Fx.ring(ground(M), CYAN, 3, R * 1.6, 0.55)
		Fx.ring(ground(M), GOLD, 2, R * 1.1, 0.45)
		local dome = part(Vector3.new(2, 2, 2), WHITE, Enum.Material.Neon, 0.5, "ball")
		dome.Position = M
		fadeOut(dome, 0.7, { Size = Vector3.new(R * 1.8, R * 1.3, R * 1.8) })
		Fx.flash(M + Vector3.new(0, 5, 0), WHITE, 100, 4, 0.5)
		Fx.breakSound("boom", 1, 0.6, M)
		shakeNear(M, 1.5, 240)
		if opts.flash then
			opts.flash(Color3.new(1, 1, 1), 0.4)
		end
	end)
end

------------------------------------------------------------------------
-- 유성 연쇄 (초가속 X): 적들 사이를 튕겨 다니며 빛의 거미줄을 치고 하늘로 솟았다가 혜성처럼 내리꽂는다
------------------------------------------------------------------------
function H.ricochet(d: any)
	local C: Vector3 = d.at
	local cen: Vector3 = d.center or C
	if not near(C, 500) and not near(cen, 500) then
		return
	end
	local m = d.m
	local seq: { any } = d.seq or {}
	local cut, every, diveAt = d.cut or 1.2, d.every or 0.11, d.diveAt or 0.45
	local up = Vector3.new(0, 1.5, 0)
	local web: { BasePart } = {}
	-- 컷씬 동안 몸에 빛이 모인다
	task.delay(cut * 0.5, function()
		local r = m and rootOf(m)
		if r then
			Fx.ring(ground(r.Position), GOLD, 14, 2, cut * 0.5)
			Fx.sound("ping", 0.7, 1.4, r.Position)
		end
	end)
	local prev = C
	for j, t in ipairs(seq) do
		task.delay(cut + (j - 1) * every, function()
			local tr = rootOf(t)
			if not tr then
				return
			end
			local p = tr.Position
			local col = (j % 2 == 0) and CYAN or GOLD
			local ln = beamTo(prev + up, p + up, 0.9, col, 0.15)
			local core = beamTo(prev + up, p + up, 0.25, WHITE, 0)
			table.insert(web, ln)
			table.insert(web, core)
			if m and m.Parent then
				Fx.afterimage(m, col, 0.3)
			end
			Fx.burst("spark", p, ICE, 6, 1.2)
			Fx.flash(p + up, col, 24, 2.5, 0.15)
			Fx.sound("swing", 0.6, 1.2 + (j % 6) * 0.15, p)
			shakeNear(p, 0.3, 100)
			prev = p
		end)
	end
	local T2 = cut + math.max(1, #seq) * every
	-- 솟구친다
	task.delay(T2 + diveAt - 0.12, function()
		local hi = cen + Vector3.new(0, 34, 0)
		local trail = beamTo(prev + up, hi, 1.4, GOLD, 0.2)
		fadeOut(trail, 0.3)
		if m and m.Parent then
			Fx.afterimage(m, GOLD, 0.5)
		end
		Fx.breakSound("whoosh", 0.9, 1.6, cen)
	end)
	-- 혜성: 하늘에서 한가운데로
	task.delay(T2 + diveAt + 0.15, function()
		local hi = cen + Vector3.new(0, 70, 0)
		local comet = beamTo(hi, cen, 8, WHITE, 0)
		local halo = beamTo(hi, cen, 22, GOLD, 0.6)
		fadeOut(comet, 0.4, { Size = Vector3.new(75, 1, 1) })
		fadeOut(halo, 0.5, { Size = Vector3.new(75, 40, 40) })
		-- 거미줄이 한꺼번에 번쩍인다
		for _, wl in ipairs(web) do
			wl.Color = WHITE
			tween(wl, 0.15, { Size = Vector3.new(wl.Size.X, 4, 4) })
			fadeOut(wl, 0.5)
		end
		local R = d.radius or 44
		Fx.ring(ground(cen), WHITE, 6, R * 2.2, 0.7)
		Fx.ring(ground(cen), GOLD, 3, R * 1.6, 0.55)
		Fx.ring(ground(cen), CYAN, 2, R * 1.1, 0.45)
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			local sh = part(Vector3.new(2, 1, 6), k % 2 == 0 and GOLD or CYAN, Enum.Material.Neon, 0)
			sh.CFrame = safeLook(cen + Vector3.new(0, 2, 0), cen + Vector3.new(math.cos(a), 0.3, math.sin(a)))
			tween(sh, 0.55, { CFrame = CFrame.new(cen + Vector3.new(math.cos(a) * R, 8, math.sin(a) * R)) * CFrame.Angles(math.random(), math.random(), math.random()), Transparency = 1 })
			task.delay(0.65, function()
				sh:Destroy()
			end)
		end
		Fx.flash(cen + Vector3.new(0, 6, 0), WHITE, 110, 4, 0.6)
		Fx.breakSound("boom", 1, 0.55, cen)
		shakeNear(cen, 1.7, 260)
		if opts.flash then
			opts.flash(Color3.new(1, 1, 1), 0.55)
		end
	end)
end

------------------------------------------------------------------------
-- 연타 장치: 음속 충격 (평소: sonic · 초가속: sonicx)
------------------------------------------------------------------------
function H.sonic(d: any)
	local at: Vector3 = d.at
	if not near(at, 250) then
		return
	end
	local R = d.radius or 11
	task.delay(d.delay or 0.12, function()
		Fx.ring(ground(at), WHITE, 2, R * 2, 0.35)
		Fx.ring(ground(at) + Vector3.new(0, 1.5, 0), CYAN, 1, R * 1.4, 0.3)
		local dome = part(Vector3.new(2, 2, 2), ICE, Enum.Material.Neon, 0.6, "ball")
		dome.Position = at
		fadeOut(dome, 0.3, { Size = Vector3.new(R * 1.6, R * 0.9, R * 1.6) })
		Fx.breakSound("boom", 0.6, 1.4, at)
		shakeNear(at, 0.4, 100)
	end)
end
function H.sonicx(d: any)
	local at: Vector3 = d.at
	if not near(at, 250) then
		return
	end
	local R = d.radius or 14
	task.delay(d.delay or 0.1, function()
		Fx.ring(ground(at), GOLD, 2, R * 2.2, 0.4)
		Fx.ring(ground(at), WHITE, 1, R * 1.6, 0.3)
		Fx.ring(ground(at) + Vector3.new(0, 2, 0), CYAN, 1, R * 1.2, 0.25)
		local dome = part(Vector3.new(2, 2, 2), GOLD, Enum.Material.Neon, 0.55, "ball")
		dome.Position = at
		fadeOut(dome, 0.35, { Size = Vector3.new(R * 1.8, R * 1.1, R * 1.8) })
		Fx.burst("spark", at, GOLD, 10, 1.4)
		Fx.breakSound("boom", 0.8, 1.2, at)
		shakeNear(at, 0.6, 120)
	end)
end

local PULSE: { [string]: string } = { sonic = "sonic", sonicx = "sonicx" }
function Speed.handles(data: any): boolean
	if data.kind == "pulse" then
		return PULSE[data.fx or ""] ~= nil
	end
	return H[data.kind] ~= nil
end
function Speed.run(data: any)
	local fn = data.kind == "pulse" and H[PULSE[data.fx or ""] or ""] or H[data.kind]
	if fn then
		fn(data)
	end
end

------------------------------------------------------------------------
-- 극 패시브 · 초가속: 서버 전체 컷씬 (시간이 멎듯 느려지는 연출) + 그동안 화면 가장자리의 속도선
------------------------------------------------------------------------
local lineGui: ScreenGui? = nil
function Speed.haste(d: any)
	local m = d.m
	local r = rootOf(m)
	if not r then
		return
	end
	local mine = m == Players.LocalPlayer.Character
	local cut, dur = d.cut or 1.3, d.dur or 30
	Fx.ring(ground(r.Position), GOLD, 3, 60, cut)
	Fx.ring(ground(r.Position), CYAN, 2, 40, cut * 0.8)
	Fx.breakSound("whoosh", 1, 0.5, r.Position)
	if near(r.Position, 300) then
		-- 세상이 푸르게 가라앉았다가 (느려진 세상), 그동안 나만 또렷하다
		gradeTo(cut * 0.4, -0.1, 0.03, 0.2, Color3.fromRGB(215, 240, 255))
		task.delay(cut, function()
			if mine then
				gradeTo(0.5, 0.05, 0.02, 0.12, Color3.fromRGB(230, 245, 255))
			else
				gradeReset(0.5)
			end
		end)
		task.delay(cut + dur, function()
			gradeReset(0.8)
		end)
		shakeNear(r.Position, 0.8, 300)
	end
	if mine then
		-- 속도선: 가운데에서 바깥으로 흩어지는 가는 흰 선들 (초가속이 끝날 때까지)
		local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if pg then
			if lineGui then
				lineGui:Destroy()
			end
			local g = Instance.new("ScreenGui")
			g.Name = "KwonSpeedLines"
			g.IgnoreGuiInset = true
			g.ResetOnSpawn = false
			g.DisplayOrder = 40
			g.Parent = pg
			lineGui = g
			local alive = true
			task.delay(cut + dur, function()
				alive = false
				g:Destroy()
				if lineGui == g then
					lineGui = nil
				end
			end)
			task.spawn(function()
				task.wait(cut)
				while alive and g.Parent do
					for _ = 1, 3 do
						local a = math.random() * math.pi * 2
						local line = Instance.new("Frame")
						line.AnchorPoint = Vector2.new(0.5, 0.5)
						line.BackgroundColor3 = math.random() < 0.3 and GOLD or ICE
						line.BorderSizePixel = 0
						line.BackgroundTransparency = 0.45
						line.Rotation = math.deg(a)
						local r0 = 0.28 + math.random() * 0.1
						line.Position = UDim2.fromScale(0.5 + math.cos(a) * r0, 0.5 + math.sin(a) * r0)
						line.Size = UDim2.fromOffset(40, 2)
						line.Parent = g
						local r1 = 0.65 + math.random() * 0.2
						tween(line, 0.35, { Position = UDim2.fromScale(0.5 + math.cos(a) * r1, 0.5 + math.sin(a) * r1), Size = UDim2.fromOffset(220, 2), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
						task.delay(0.4, function()
							line:Destroy()
						end)
					end
					task.wait(0.07)
				end
			end)
		end
	end
end

------------------------------------------------------------------------
-- 초 오의 컷씬: 가로 검은 띠와 속도선, 카메라가 출발선 뒤에서 땅에 붙어 길 끝을 본다 (chrono = 유성 연쇄: 높은 곳에서 내려다본다)
------------------------------------------------------------------------
local cutActive = false
function Speed.superCut(model: Model, dur: number, name: string, shake: ((number) -> ())?, chrono: boolean?)
	local cam = workspace.CurrentCamera
	local r = rootOf(model)
	local player = Players.LocalPlayer
	if not cam or not r or cutActive or not player then
		return
	end
	cutActive = true
	local g = Instance.new("ScreenGui")
	g.Name = "KwonSpeedCut"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 85
	g.Parent = player:WaitForChild("PlayerGui")
	local tintF = Instance.new("Frame")
	tintF.Size = UDim2.fromScale(1, 1)
	tintF.BackgroundColor3 = Color3.fromRGB(10, 22, 40)
	tintF.BackgroundTransparency = 1
	tintF.BorderSizePixel = 0
	tintF.Parent = g
	tween(tintF, 0.25, { BackgroundTransparency = 0.7 })
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
	label.TextColor3 = chrono and GOLD or ICE
	label.TextStrokeColor3 = chrono and Color3.fromRGB(120, 90, 20) or Color3.fromRGB(20, 90, 140)
	label.TextStrokeTransparency = 0.2
	label.TextTransparency = 1
	label.ZIndex = 6
	label.Parent = bars[2]
	tween(label, 0.25, { TextTransparency = 0 })
	-- 속도선 (컷씬 내내 가운데에서 바깥으로)
	local running = true
	task.spawn(function()
		while running and g.Parent do
			for _ = 1, 4 do
				local a = math.random() * math.pi * 2
				local line = Instance.new("Frame")
				line.AnchorPoint = Vector2.new(0.5, 0.5)
				line.BackgroundColor3 = chrono and GOLD or ICE
				line.BorderSizePixel = 0
				line.BackgroundTransparency = 0.35
				line.Rotation = math.deg(a)
				line.Position = UDim2.fromScale(0.5 + math.cos(a) * 0.22, 0.5 + math.sin(a) * 0.22)
				line.Size = UDim2.fromOffset(30, 2)
				line.ZIndex = 4
				line.Parent = g
				tween(line, 0.3, { Position = UDim2.fromScale(0.5 + math.cos(a) * 0.8, 0.5 + math.sin(a) * 0.8), Size = UDim2.fromOffset(300, 3), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.delay(0.35, function()
					line:Destroy()
				end)
			end
			task.wait(0.05)
		end
	end)
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
		running = false
		RunService:UnbindFromRenderStep("KwonSpeedCut")
		cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
		cam.FieldOfView = oldFov
		cutActive = false
		local function behind()
			if r.Parent then
				local lk = flat(r.CFrame.LookVector)
				cam.CFrame = CFrame.lookAt(r.Position - lk * 20 + UP * 9, r.Position + lk * 6 + UP * 4)
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
	RunService:BindToRenderStep("KwonSpeedCut", Enum.RenderPriority.Camera.Value + 2, function(dt: number)
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
		if chrono then
			-- 위에서 내려다본다: 높고 멀리서, 점점 가까이
			local eye = focus - look * (18 - e * 6) + side * 5 + UP * (9 + e * 5)
			cam.CFrame = CamGuard.frame(eye, focus + look * 6 + UP * 1, focus)
			cam.FieldOfView = oldFov + e * 10
		else
			-- 출발선: 등 뒤 낮은 곳에서 길 끝을 본다. 점점 다가가며 시야가 좁아졌다가 (집중) 한 순간 활짝 열린다
			local eye = focus - look * (11 - e * 5) + side * (3 - e * 2) + UP * (1.2 + e * 0.6)
			cam.CFrame = CamGuard.frame(eye, focus + look * 40 + UP * 2, focus)
			cam.FieldOfView = oldFov - e * 10
		end
		if t >= dur then
			restore()
		end
	end)
	if shake then
		task.delay(dur * 0.7, function()
			shake(0.7)
		end)
	end
	task.delay(dur + 1, restore)
end

return Speed
