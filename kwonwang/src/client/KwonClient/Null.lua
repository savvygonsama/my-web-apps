-- 권왕 3.8판: 공백권 (화면). 지워진 것, 있어서는 안 되는 빈칸
-- 빛깔은 검정·흰색, 가끔 번쩍이는 붉은빛과 '빠진 무늬' (자홍·검정 바둑판). 움직임은 부드럽지 않고 끊긴다 (지직)
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Fx = require(script.Parent:WaitForChild("Fx"))

local Null = {}

local BLACK = Color3.fromRGB(14, 14, 18)
local WHITE = Color3.fromRGB(240, 240, 245)
local RED = Color3.fromRGB(230, 40, 60)
local CYAN = Color3.fromRGB(60, 230, 240)
local MAGENTA = Color3.fromRGB(255, 0, 220)
local UP = CFrame.Angles(0, 0, math.rad(90))
local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "KwonNull"
folder.Parent = workspace

local opts: any = {}
function Null.init(o: any)
	opts = o or {}
end

local function part(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?): Part
	local q = Instance.new("Part")
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
-- 화소 조각: 검정·흰색·가끔 자홍의 작은 정육면체가 튄다 (돌지 않고 곧게, 끊기듯)
local function pixels(at: Vector3, n: number, s: number, spread: number?)
	for k = 1, n do
		local c = (k % 7 == 0) and MAGENTA or ((k % 2 == 0) and BLACK or WHITE)
		local q = part(Vector3.one * (0.4 + math.random() * 0.5) * s, c, c == WHITE and Enum.Material.Neon or Enum.Material.SmoothPlastic, 0)
		q.CFrame = CFrame.new(at + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2 * s)
		local d = Vector3.new(math.random() - 0.5, math.random() * 0.7, math.random() - 0.5).Unit * (spread or 6) * s * (0.5 + math.random())
		fadeOut(q, 0.5 + math.random() * 0.4, { CFrame = CFrame.new(q.Position + d) })
	end
end
-- 찢어진 화면 줄 (가로로 길고 얇은 붉은·푸른 빛줄이 잠깐)
local function tear(at: Vector3, len: number, life: number)
	for k, c in ipairs({ RED, CYAN, WHITE }) do
		local q = part(Vector3.new(len, 0.12, 0.05), c, Enum.Material.Neon, 0.1)
		q.CFrame = CFrame.lookAt(at + Vector3.new(0, (k - 2) * 0.35, 0), at + Vector3.new(0, (k - 2) * 0.35, 0) + (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector or Vector3.new(0, 0, -1))) * CFrame.new((k - 2) * 0.4, 0, 0)
		task.delay(life, function()
			q:Destroy()
		end)
	end
end
-- 상자 테두리 (모서리 열둘)
local function boxEdges(cf: CFrame, size: Vector3, color: Color3, w: number): { BasePart }
	local out: { BasePart } = {}
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	for _, sy in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local q = part(Vector3.new(size.X, w, w), color, Enum.Material.Neon, 0)
			q.CFrame = cf * CFrame.new(0, sy * hy, sz * hz)
			table.insert(out, q)
		end
		for _, sx in ipairs({ -1, 1 }) do
			local q = part(Vector3.new(w, w, size.Z), color, Enum.Material.Neon, 0)
			q.CFrame = cf * CFrame.new(sx * hx, sy * hy, 0)
			table.insert(out, q)
		end
	end
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local q = part(Vector3.new(w, size.Y, w), color, Enum.Material.Neon, 0)
			q.CFrame = cf * CFrame.new(sx * hx, 0, sz * hz)
			table.insert(out, q)
		end
	end
	return out
end
-- 빠진 무늬 상자 (작은 상자 여덟)
local function missingCube(cf: CFrame, s: number): { BasePart }
	local out: { BasePart } = {}
	for x = 0, 1 do
		for y = 0, 1 do
			for z = 0, 1 do
				local q = part(Vector3.one * s, ((x + y + z) % 2 == 0) and MAGENTA or BLACK, Enum.Material.SmoothPlastic, 0)
				q.CFrame = cf * CFrame.new((x - 0.5) * s, (y - 0.5) * s, (z - 0.5) * s)
				table.insert(out, q)
			end
		end
	end
	return out
end
local function moveCube(list: { BasePart }, cf: CFrame, s: number)
	local i = 0
	for x = 0, 1 do
		for y = 0, 1 do
			for z = 0, 1 do
				i += 1
				local q = list[i]
				if q and q.Parent then
					q.CFrame = cf * CFrame.new((x - 0.5) * s, (y - 0.5) * s, (z - 0.5) * s)
				end
			end
		end
	end
end
-- 빛깔 빼기 (가까울 때만, 내 화면에서)
local function gradeTo(cc: ColorCorrectionEffect?, time: number, goal: { [string]: any }): ColorCorrectionEffect
	local c = cc
	if not c then
		local nc = Instance.new("ColorCorrectionEffect")
		nc.Name = "KwonNullGrade"
		nc.Parent = Lighting
		c = nc
	end
	tween(c :: ColorCorrectionEffect, time, goal)
	return c :: ColorCorrectionEffect
end
local function gradeEnd(cc: ColorCorrectionEffect?, time: number)
	if cc then
		tween(cc, time, { Saturation = 0, Contrast = 0, Brightness = 0, TintColor = Color3.new(1, 1, 1) })
		task.delay(time + 0.1, function()
			cc:Destroy()
		end)
	end
end
-- 화면 잡음 (가로 줄들이 지직거리고 null 글자가 번쩍인다). 내 화면에서만
local function screenGlitch(dur: number, strength: number)
	local pg = player and player:FindFirstChild("PlayerGui")
	if not pg then
		return
	end
	local g = Instance.new("ScreenGui")
	g.Name = "KwonNullGlitch"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 86
	g.Parent = pg
	local bars: { Frame } = {}
	for k = 1, math.floor(8 * strength) do
		local b = Instance.new("Frame")
		b.BorderSizePixel = 0
		b.BackgroundColor3 = k % 3 == 0 and RED or (k % 3 == 1 and BLACK or WHITE)
		b.BackgroundTransparency = 0.3
		b.Visible = false
		b.Parent = g
		bars[k] = b
	end
	local words: { TextLabel } = {}
	for k, c in ipairs({ RED, CYAN, WHITE }) do
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(0.4, 0.16)
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Font = Enum.Font.Code
		t.TextScaled = true
		t.Text = "null"
		t.TextColor3 = c
		t.TextTransparency = 1
		t.ZIndex = 2 + k
		t.Parent = g
		words[k] = t
	end
	local t0 = os.clock()
	local nextAt = 0
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > dur then
			conn:Disconnect()
			g:Destroy()
			return
		end
		if t < nextAt then
			return
		end
		nextAt = t + 0.04 + math.random() * 0.08
		for _, b in ipairs(bars) do
			b.Visible = math.random() < 0.6
			b.Position = UDim2.fromScale(math.random() * 0.3 - 0.1, math.random())
			b.Size = UDim2.new(0.5 + math.random() * 0.8, 0, 0, 2 + math.random() * 14)
		end
		local show = math.random() < 0.35
		local cx, cy = 0.3 + math.random() * 0.4, 0.3 + math.random() * 0.4
		for k, w in ipairs(words) do
			w.TextTransparency = show and 0.1 or 1
			w.Position = UDim2.fromScale(cx + (k - 2) * 0.006, cy + (k - 2) * 0.004)
		end
	end)
end
local function glitchNear(at: Vector3, range: number, dur: number, strength: number)
	if near(at, range) then
		screenGlitch(dur, strength)
	end
end

------------------------------------------------------------------------
-- 차림: 몸 둘레의 빈칸 상자 셋. 천천히 돌다가 가끔 끊기듯 다른 자리로 튄다. 가끔 붉은 찢어진 줄
------------------------------------------------------------------------
function Null.buildGear(model: Model): { Instance }
	local out: { Instance } = {}
	local holder = Instance.new("Folder")
	holder.Name = "Null_" .. model.Name
	holder.Parent = folder
	table.insert(out, holder)
	local torso = model:FindFirstChild("UpperTorso")
	if not (torso and torso:IsA("BasePart")) then
		return out
	end
	local cubes: { { list: { BasePart }, s: number, phase: number, jump: Vector3, until_: number } } = {}
	for k = 1, 3 do
		local s = 0.32 + (k % 2) * 0.08
		local list = missingCube(CFrame.new(torso.Position), s)
		for _, q in ipairs(list) do
			q.Parent = holder
			table.insert(out, q)
		end
		table.insert(cubes, { list = list, s = s, phase = k * 2.1, jump = Vector3.zero, until_ = 0 })
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
		for _, c in ipairs(cubes) do
			-- 가끔 (지직) 엉뚱한 자리로 튀었다가 돌아온다
			if t > c.until_ and math.random() < 0.012 then
				c.jump = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 3
				c.until_ = t + 0.08 + math.random() * 0.1
			elseif t > c.until_ then
				c.jump = Vector3.zero
			end
			local a = t * 0.9 + c.phase
			local cf = torso.CFrame * CFrame.new(math.cos(a) * 2.3, 0.6 + math.sin(t * 1.1 + c.phase) * 0.7, math.sin(a) * 2.3) + c.jump
			-- 돌지 않고 각진 채로 (90도씩 끊어서 돈다)
			local step = math.floor(t * 2 + c.phase) * math.rad(90)
			moveCube(c.list, CFrame.new(cf.Position) * CFrame.Angles(step, step * 0.5, 0), c.s)
			for _, q in ipairs(c.list) do
				q.LocalTransparencyModifier = hide and 1 or 0
			end
		end
	end)
	return out
end

------------------------------------------------------------------------
-- 연타 장치 빈칸: 상대가 검은 네모 칸에 지워졌다가, 깨진 화면처럼 돌아온다
------------------------------------------------------------------------
local function voidCell(data: any)
	local at: Vector3 = data.at
	if not near(at, 200) then
		return
	end
	local delay = data.delay or 0.4
	local size = Vector3.new(5, 6.5, 5)
	local box = part(size, BLACK, Enum.Material.SmoothPlastic, 0.02)
	box.CFrame = CFrame.new(at)
	local edges = boxEdges(CFrame.new(at), size, WHITE, 0.12)
	Fx.sound("ping", 0.4, 2.2, at)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		-- 끊기듯 흔들린다
		local j = (math.random() < 0.3) and Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 0.8 or Vector3.zero
		box.CFrame = CFrame.new(at + j)
		if t >= delay then
			conn:Disconnect()
			box:Destroy()
			for _, e in ipairs(edges) do
				e:Destroy()
			end
			pixels(at, 18, 1)
			tear(at, 8, 0.12)
			Fx.ring(ground(at) + Vector3.new(0, 0.3, 0), RED, 2, (data.radius or 6) * 2, 0.3)
			Fx.sound("shatter", 0.5, 1.8, at)
		end
	end)
end

------------------------------------------------------------------------
-- E 소거: 흰 선택 상자가 깜박이고, 안이 검게 지워졌다가 화소로 부서진다
------------------------------------------------------------------------
local function eraseBox(data: any)
	local from: Vector3, to: Vector3 = data.from, data.to
	if not near(from, 220) then
		return
	end
	local dir = flat(to - from)
	local L = (Vector3.new(to.X, 0, to.Z) - Vector3.new(from.X, 0, from.Z)).Magnitude
	local W = data.width or 9
	local delay = data.delay or 0.35
	local mid = ground((from + to) / 2)
	local base = CFrame.lookAt(mid, mid + dir)
	-- 바닥의 점선 상자 (선택 영역)
	local dashes: { BasePart } = {}
	local function dashLine(a: Vector3, b: Vector3)
		local n = math.max(2, math.floor((b - a).Magnitude / 2))
		for k = 0, n - 1, 2 do
			local p0, p1 = a:Lerp(b, k / n), a:Lerp(b, (k + 1) / n)
			local q = part(Vector3.new(0.18, 0.08, (p1 - p0).Magnitude), WHITE, Enum.Material.Neon, 0)
			q.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
			table.insert(dashes, q)
		end
	end
	local c1 = (base * CFrame.new(-W / 2, 0.15, L / 2)).Position
	local c2 = (base * CFrame.new(W / 2, 0.15, L / 2)).Position
	local c3 = (base * CFrame.new(W / 2, 0.15, -L / 2)).Position
	local c4 = (base * CFrame.new(-W / 2, 0.15, -L / 2)).Position
	dashLine(c1, c2)
	dashLine(c2, c3)
	dashLine(c3, c4)
	dashLine(c4, c1)
	-- 깜박임 셋
	for k = 1, 3 do
		task.delay(delay * (k - 0.5) / 3, function()
			for _, q in ipairs(dashes) do
				q.Transparency = 1
			end
			task.wait(0.04)
			for _, q in ipairs(dashes) do
				q.Transparency = 0
			end
		end)
	end
	Fx.sound("block", 0.4, 2, from)
	task.delay(delay, function()
		for _, q in ipairs(dashes) do
			q:Destroy()
		end
		local H = 8
		local vol = part(Vector3.new(W, H, L), BLACK, Enum.Material.SmoothPlastic, 0.04)
		vol.CFrame = base * CFrame.new(0, H / 2, 0)
		local edges = boxEdges(vol.CFrame, vol.Size, WHITE, 0.15)
		tear((from + to) / 2 + Vector3.new(0, 2, 0), L * 0.8, 0.1)
		Fx.sound("ping", 0.6, 2.4, from)
		shakeNear(mid, 1.0, 100)
		task.delay(data.shardAt or 0.25, function()
			-- 부서진다: 상자 부피 곳곳에서 화소 조각
			for k = 0, 7 do
				pixels((base * CFrame.new((math.random() - 0.5) * W, 1 + math.random() * H, (k / 7 - 0.5) * L)).Position, 6, 1.2)
			end
			vol:Destroy()
			for _, e in ipairs(edges) do
				fadeOut(e, 0.15)
			end
			Fx.flash(mid + Vector3.new(0, 3, 0), WHITE, 40, 3, 0.2)
			Fx.sound("shatter", 0.7, 1.5, mid)
		end)
	end)
end

------------------------------------------------------------------------
-- R 끊김: 적 넷 사이를 끊기듯 옮겨 다니며 친다. 자리마다 붉은·푸른으로 어긋난 잔상
------------------------------------------------------------------------
local function ghostAt(model: Model?, cf: CFrame, color: Color3, alpha: number, life: number)
	local r = rootOf(model)
	local body = model
	if not body or not r then
		return
	end
	for _, d in ipairs(body:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.9 then
			local q = part(d.Size, color, Enum.Material.SmoothPlastic, alpha)
			q.CFrame = cf * r.CFrame:ToObjectSpace(d.CFrame)
			task.delay(life, function()
				q:Destroy()
			end)
		end
	end
end
local function glitchBlink(data: any)
	local from: Vector3 = data.from
	if not near(from, 220) then
		return
	end
	local m: Model? = data.m
	local targets = data.targets or {}
	local delay = data.delay or 0.08
	local every = data.every or 0.13
	local r0 = rootOf(m)
	if r0 then
		ghostAt(m, r0.CFrame, BLACK, 0.2, 0.25)
	end
	for i, t in ipairs(targets) do
		task.delay(delay + (i - 1) * every, function()
			local tr = rootOf(t)
			if not tr then
				return
			end
			local look = flat(tr.Position - from)
			local cf = CFrame.lookAt(tr.Position - look * 3, tr.Position)
			ghostAt(m, cf * CFrame.new(0.35, 0, 0), RED, 0.55, 0.12)
			ghostAt(m, cf * CFrame.new(-0.35, 0, 0), CYAN, 0.55, 0.12)
			ghostAt(m, cf, BLACK, 0.1, 0.18)
			tear(tr.Position + Vector3.new(0, 1, 0), 6, 0.1)
			pixels(tr.Position, 10, 0.9)
			Fx.sound("ping", 0.4, 2 + i * 0.1, tr.Position)
		end)
	end
	glitchNear(from, 60, delay + #targets * every, 0.6)
end

------------------------------------------------------------------------
-- G 허공 격자: 빛깔이 빠지고 흰 격자의 검은 허공, 붉은 null 글자가 떠다니다 한 점으로 오그라든 뒤 흰 잡음으로
------------------------------------------------------------------------
local function voidGrid(data: any)
	local at: Vector3 = data.at
	if not near(at, 260) then
		return
	end
	local R = data.radius or 26
	local delay = data.delay or 0.35
	local dur = data.dur or 2.6
	local collapse = data.collapse or 0.35
	local g = ground(at)
	local parts: { BasePart } = {}
	local floor = part(Vector3.new(0.2, 1, 1), BLACK, Enum.Material.SmoothPlastic, 0.05)
	floor.Shape = Enum.PartType.Cylinder
	floor.CFrame = CFrame.new(g + Vector3.new(0, 0.12, 0)) * UP
	tween(floor, delay, { Size = Vector3.new(0.2, R * 2, R * 2) })
	table.insert(parts, floor)
	local n = math.floor(R / 4)
	for k = -n, n do
		local len = 2 * math.sqrt(math.max(0, R * R - (k * 4) ^ 2))
		local a = part(Vector3.new(len, 0.06, 0.14), WHITE, Enum.Material.Neon, 1)
		a.CFrame = CFrame.new(g + Vector3.new(0, 0.25, k * 4))
		local b = part(Vector3.new(0.14, 0.06, len), WHITE, Enum.Material.Neon, 1)
		b.CFrame = CFrame.new(g + Vector3.new(k * 4, 0.25, 0))
		task.delay(delay * (0.3 + math.abs(k) / n * 0.7), function()
			a.Transparency = 0.35
			b.Transparency = 0.35
		end)
		table.insert(parts, a)
		table.insert(parts, b)
	end
	-- 떠다니는 붉은 null 글자 (머리 위 판)
	local words: { { p: BasePart, a: number, r: number, h: number } } = {}
	for k = 1, 7 do
		local holder = part(Vector3.new(0.2, 0.2, 0.2), RED, Enum.Material.Neon, 1)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(7, 2.4)
		bb.AlwaysOnTop = false
		bb.LightInfluence = 0
		bb.Parent = holder
		local tl = Instance.new("TextLabel")
		tl.BackgroundTransparency = 1
		tl.Size = UDim2.fromScale(1, 1)
		tl.Font = Enum.Font.Code
		tl.TextScaled = true
		tl.Text = (k % 3 == 0) and "ERROR" or "null"
		tl.TextColor3 = RED
		tl.Parent = bb
		table.insert(words, { p = holder, a = k / 7 * math.pi * 2, r = R * (0.5 + (k % 3) * 0.15), h = 4 + (k % 4) * 2 })
		table.insert(parts, holder)
	end
	local cc: ColorCorrectionEffect? = nil
	if near(at, R * 2.5) then
		cc = gradeTo(nil, 0.3, { Saturation = -1, Contrast = 0.25, Brightness = -0.03 })
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp((t - delay) / dur, 0, 1)
		for i, w in ipairs(words) do
			local a = w.a + t * 0.6
			local r = w.r * (1 - u * 0.6)
			local jump = (math.random() < 0.08) and Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 4 or Vector3.zero
			w.p.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * r, w.h + math.sin(t * 2 + i), math.sin(a) * r) + jump)
		end
		if math.random() < 0.15 then
			local aa, rr = math.random() * math.pi * 2, math.random() * R
			tear(g + Vector3.new(math.cos(aa) * rr, 1 + math.random() * 5, math.sin(aa) * rr), 4 + math.random() * 6, 0.08)
		end
		if t >= delay + dur then
			conn:Disconnect()
		end
	end)
	Fx.sound("ping", 0.5, 0.6, at)
	-- 오그라든다: 모든 것이 가운데 한 점으로
	task.delay(delay + dur, function()
		local center = g + Vector3.new(0, 2, 0)
		for _, p in ipairs(parts) do
			if p.Parent then
				tween(p, collapse, { CFrame = CFrame.new(center) * p.CFrame.Rotation, Size = p.Size * 0.05 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end
		local dot = part(Vector3.new(2, 2, 2), BLACK, Enum.Material.SmoothPlastic, 0)
		dot.CFrame = CFrame.new(center)
		tween(dot, collapse, { Size = Vector3.new(0.3, 0.3, 0.3) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(collapse, function()
			for _, p in ipairs(parts) do
				if p.Parent then
					p:Destroy()
				end
			end
			dot:Destroy()
			-- 흰 잡음으로 터진다
			pixels(center, 40, 2.4, 9)
			local flash = part(Vector3.new(4, 4, 4), WHITE, Enum.Material.Neon, 0)
			flash.Shape = Enum.PartType.Ball
			flash.CFrame = CFrame.new(center)
			fadeOut(flash, 0.4, { Size = Vector3.new(R * 2, R * 2, R * 2) })
			Fx.ring(g + Vector3.new(0, 0.5, 0), WHITE, 4, R * 2.6, 0.5)
			Fx.ring(g + Vector3.new(0, 0.8, 0), RED, 4, R * 2.2, 0.4)
			Fx.flash(center, WHITE, 90, 7, 0.4)
			Fx.sound("shatter", 0.9, 1.2, center)
			Fx.sound("heavy", 0.8, 0.8, center)
			shakeNear(center, 2.4, 150)
			glitchNear(center, 120, 0.4, 1)
			gradeEnd(cc, 0.5)
		end)
	end)
end

------------------------------------------------------------------------
-- X 존재소거: 화면 균열이 미끄러지고, 빈칸 상자들이 떨어지고, 멈추고 (빛깔이 날아가고), 삑, 화소로 무너진다
------------------------------------------------------------------------
type NullState = { at: Vector3, range: number, cc: ColorCorrectionEffect?, done: boolean, panels: { BasePart } }
local nulls: { [number]: NullState } = {}
local function nullOpen(data: any)
	local at: Vector3 = data.at
	if not near(at, 340) then
		return
	end
	local range = data.range or 40
	local cut = data.cut or 1.4
	local rain = data.rain or 2.0
	local freeze = data.freeze or 0.5
	local g = ground(at)
	local st: NullState = { at = g, range = range, cc = nil, done = false, panels = {} }
	nulls[data.id] = st
	if near(at, range * 2.5) then
		st.cc = gradeTo(nil, 0.4, { Saturation = -0.85, Contrast = 0.2 })
	end
	-- 하늘에서 땅까지 검은 화면 균열 판들이 미끄러진다
	task.delay(cut, function()
		for k = 1, 8 do
			local a = k / 8 * math.pi * 2
			local p = part(Vector3.new(0.3, 60, 3 + (k % 3) * 2), BLACK, Enum.Material.SmoothPlastic, 0.05)
			local c0 = g + Vector3.new(math.cos(a) * range * 0.9, 30, math.sin(a) * range * 0.9)
			p.CFrame = CFrame.lookAt(c0, Vector3.new(g.X, c0.Y, g.Z))
			local edge = part(Vector3.new(0.32, 60, 0.15), RED, Enum.Material.Neon, 0.1)
			edge.CFrame = p.CFrame * CFrame.new(0, 0, p.Size.Z / 2)
			table.insert(st.panels, p)
			table.insert(st.panels, edge)
			local side = Vector3.new(-math.sin(a), 0, math.cos(a)) * 14
			tween(p, rain, { CFrame = p.CFrame + side }, Enum.EasingStyle.Linear)
			tween(edge, rain, { CFrame = edge.CFrame + side }, Enum.EasingStyle.Linear)
		end
		shakeNear(g, 1.6, 200)
		Fx.sound("heavy", 0.8, 0.5, g)
	end)
	-- 멈춤: 빛깔이 하얗게 날아간다, 삑
	task.delay(cut + rain, function()
		if st.done then
			return
		end
		if st.cc then
			gradeTo(st.cc, 0.08, { Saturation = -1, Contrast = 1, Brightness = 0.35 })
		end
		Fx.sound("ping", 1, 3, g)
		glitchNear(g, range * 2.5, freeze, 1.4)
	end)
	-- 무너진다
	task.delay(cut + rain + freeze, function()
		if st.done then
			return
		end
		st.done = true
		for _, p in ipairs(st.panels) do
			if p.Parent then
				pixels(p.Position, 6, 1.6)
				p:Destroy()
			end
		end
		for _ = 1, 14 do
			local a, rr = math.random() * math.pi * 2, math.random() * range
			pixels(g + Vector3.new(math.cos(a) * rr, 2 + math.random() * 6, math.sin(a) * rr), 8, 1.6, 8)
		end
		for k = 1, 3 do
			task.delay(k * 0.06, function()
				Fx.ring(g + Vector3.new(0, 0.5 + k, 0), k == 2 and RED or WHITE, 6, range * 2.4 + k * 10, 0.6)
			end)
		end
		Fx.flash(g + Vector3.new(0, 5, 0), WHITE, 150, 9, 0.6)
		Fx.sound("shatter", 1, 0.7, g)
		Fx.sound("heavy", 1, 0.4, g)
		shakeNear(g, 3.4, 220)
		if opts.flash and near(g, 120) then
			opts.flash(WHITE, 0.3)
		end
		gradeEnd(st.cc, 0.6)
		nulls[data.id] = nil
	end)
	task.delay(cut + rain + freeze + 4, function()
		if nulls[data.id] == st then
			nulls[data.id] = nil
			gradeEnd(st.cc, 0.3)
		end
	end)
end
local function nullCubes(data: any)
	local st = nulls[data.id]
	if not st or st.done then
		return
	end
	local fall = data.fall or 0.25
	for _, pt in ipairs(data.pts or {}) do
		local s = 1.6
		local top = pt + Vector3.new((math.random() - 0.5) * 4, 34, (math.random() - 0.5) * 4)
		local list = missingCube(CFrame.new(top), s)
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local u = math.clamp((os.clock() - t0) / fall, 0, 1)
			-- 떨어지는 것도 끊기듯 (네 칸씩 툭툭)
			local q = math.floor(u * 6) / 6
			moveCube(list, CFrame.new(top:Lerp(pt, q)), s)
			if u >= 1 then
				conn:Disconnect()
				for _, c in ipairs(list) do
					c:Destroy()
				end
				pixels(pt, 10, 1.1)
				Fx.ring(ground(pt) + Vector3.new(0, 0.3, 0), RED, 2, 10, 0.25)
			end
		end)
	end
end

-- 초 오의 컷씬 (쓴 사람 화면에서만): 화면이 깨진다. 카메라가 끊기듯 이리저리 튀며 나를 비추고, 붉고 푸르게 어긋난 null
local cutActive = false
function Null.superCut(model: Model, dur: number, name: string, shake: ((number) -> ())?)
	local cam = workspace.CurrentCamera
	local r = rootOf(model)
	if not cam or not r or cutActive or not player then
		return
	end
	cutActive = true
	screenGlitch(dur, 1.6)
	local pg = player:WaitForChild("PlayerGui")
	local g = Instance.new("ScreenGui")
	g.Name = "KwonNullCut"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 85
	g.Parent = pg
	local tint = Instance.new("Frame")
	tint.Size = UDim2.fromScale(1, 1)
	tint.BackgroundColor3 = BLACK
	tint.BackgroundTransparency = 1
	tint.BorderSizePixel = 0
	tint.Parent = g
	tween(tint, 0.2, { BackgroundTransparency = 0.45 })
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(1, 1)
	label.Position = UDim2.new(1, -30, 1, -30)
	label.Size = UDim2.new(0.5, 0, 0.1, 0)
	label.Font = Enum.Font.Code
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.Text = "초 오의 · " .. name
	label.TextColor3 = WHITE
	label.TextStrokeColor3 = RED
	label.TextStrokeTransparency = 0.2
	label.ZIndex = 5
	label.Parent = g
	local oldType = cam.CameraType
	local oldFov = cam.FieldOfView
	local look = flat(r.CFrame.LookVector)
	local side = Vector3.new(-look.Z, 0, look.X)
	cam.CameraType = Enum.CameraType.Scriptable
	local t0 = os.clock()
	local focus = r.Position
	local finished = false
	local shot = 0
	local nextCut = 0
	local function restore()
		if finished then
			return
		end
		finished = true
		RunService:UnbindFromRenderStep("KwonNullCut")
		cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
		cam.FieldOfView = oldFov
		cutActive = false
		tween(tint, 0.2, { BackgroundTransparency = 1 })
		tween(label, 0.2, { TextTransparency = 1 })
		task.delay(0.25, function()
			g:Destroy()
		end)
	end
	RunService:BindToRenderStep("KwonNullCut", Enum.RenderPriority.Camera.Value + 2, function()
		local t = os.clock() - t0
		-- 몇 장면을 끊어 붙인다 (부드럽게 움직이지 않는다)
		if t >= nextCut then
			shot += 1
			nextCut = t + 0.18 + math.random() * 0.22
		end
		local k = shot % 4
		local eye: Vector3
		if k == 0 then
			eye = focus + look * 7 + Vector3.new(0, 1.2, 0)
		elseif k == 1 then
			eye = focus + side * 8 + Vector3.new(0, 3, 0)
		elseif k == 2 then
			eye = focus + look * 3 + Vector3.new(0, 0.4, 0) - side * 2
		else
			eye = focus + look * 14 + Vector3.new(0, 9, 0)
		end
		cam.CFrame = CFrame.lookAt(eye, focus + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, (shot % 2 == 0) and 0.04 or -0.04)
		cam.FieldOfView = oldFov + (k == 2 and 20 or 4)
		if t >= dur then
			restore()
		end
	end)
	if shake then
		task.delay(dur * 0.5, function()
			shake(0.8)
		end)
	end
	task.delay(dur + 1, restore)
end

local HANDLERS: { [string]: (any) -> () } = {
	eraseBox = eraseBox,
	glitchBlink = glitchBlink,
	voidGrid = voidGrid,
	nullOpen = nullOpen,
	nullCubes = nullCubes,
}
------------------------------------------------------------------------
-- 3.16판 극 공백권 · 격자 전개 (극 패시브)
-- 한 점에서 시작해 흰 3차원 격자가 천천히 펼쳐진다 (세 축의 선이 먼저 뻗고, 가까운 선부터 차례로 켜지며 상자가 커진다).
-- 다 펼쳐지면 30초 동안 머문다: 격자 위로 빛의 물결이 바깥으로 흐르고, 가끔 몇 줄이 붉게 지직거리고, 빈칸 상자가 떠다닌다.
-- 끝나면 격자가 한 점으로 접혀 들어가 흰 잡음으로 터진다. 격자 안에 들어오면 화면의 빛깔이 빠진다
------------------------------------------------------------------------
type Line = { p: Part, axis: string, a: number, b: number, dist: number, shell: boolean, base: number }
function Null.domain(data: any)
	local at: Vector3 = data.at
	if not at or not near(at, 700) then
		return
	end
	local cut = data.cut or 1.6
	local dur = data.dur or 30
	local unfold = data.unfold or 3.6
	local H, TOP, STEP, LEVEL = data.half or 60, data.top or 72, data.step or 15, data.level or 12
	local holder = Instance.new("Folder")
	holder.Name = "KwonNullDomain"
	holder.Parent = folder
	local function mk(thick: number): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = WHITE
		p.Size = Vector3.new(thick, thick, thick)
		p.Transparency = 1
		p.Parent = holder
		return p
	end
	local xs: { number } = {}
	local v = -H
	while v <= H + 0.01 do
		table.insert(xs, v)
		v += STEP
	end
	local ys: { number } = {}
	v = 0
	while v <= TOP + 0.01 do
		table.insert(ys, v)
		v += LEVEL
	end
	local lines: { Line } = {}
	local function addLine(axis: string, a: number, b: number, dist: number, shell: boolean)
		local thick = shell and 0.24 or 0.14
		table.insert(lines, { p = mk(thick), axis = axis, a = a, b = b, dist = dist, shell = shell, base = shell and 0.12 or 0.5 })
	end
	-- x축 선 (높이 y, 깊이 z) · z축 선 (높이 y, 가로 x) · 세로 선 (가로 x, 깊이 z)
	for _, y in ipairs(ys) do
		for _, z in ipairs(xs) do
			addLine("x", y, z, math.max(math.abs(z), y * H / TOP), math.abs(z) >= H - 0.01 or y == 0 or y >= TOP - 0.01)
			addLine("z", y, z, math.max(math.abs(z), y * H / TOP), math.abs(z) >= H - 0.01 or y == 0 or y >= TOP - 0.01)
		end
	end
	for _, x in ipairs(xs) do
		for _, z in ipairs(xs) do
			addLine("y", x, z, math.max(math.abs(x), math.abs(z)), math.abs(x) >= H - 0.01 or math.abs(z) >= H - 0.01)
		end
	end
	-- 바닥: 검은 유리판 (격자와 함께 넓어진다)
	local floor = mk(0.2)
	floor.Material = Enum.Material.Glass
	floor.Color = BLACK
	-- 씨앗: 한가운데 흰 테의 검은 상자
	local seedAt = at + Vector3.new(0, 4, 0)
	local seed = boxEdges(CFrame.new(seedAt), Vector3.one * 2.4, WHITE, 0.16)
	local core = part(Vector3.one * 2, BLACK, Enum.Material.SmoothPlastic, 0)
	core.CFrame = CFrame.new(seedAt)
	-- 떠다니는 빈칸 상자
	type Drifter = { list: { BasePart }, rel: { CFrame }, base: Vector3, ph: number }
	local drifters: { Drifter } = {}
	local function place(L: Line, h: number, top: number, alphaMul: number)
		local p = L.p
		if L.axis == "y" then
			local vis = math.max(math.abs(L.a), math.abs(L.b)) <= h + 0.01 and top > 0.2
			if not vis then
				p.Transparency = 1
				return
			end
			p.Size = Vector3.new(p.Size.X, top, p.Size.Z)
			p.CFrame = CFrame.new(at + Vector3.new(L.a, top / 2, L.b))
		else
			local y, off = L.a, L.b
			local vis = math.abs(off) <= h + 0.01 and y <= top + 0.01 and h > 0.2
			if not vis then
				p.Transparency = 1
				return
			end
			if L.axis == "x" then
				p.Size = Vector3.new(h * 2, p.Size.Y, p.Size.Z)
				p.CFrame = CFrame.new(at + Vector3.new(0, y, off))
			else
				p.Size = Vector3.new(p.Size.X, p.Size.Y, h * 2)
				p.CFrame = CFrame.new(at + Vector3.new(off, y, 0))
			end
		end
		-- 펼쳐지는 앞머리에 가까운 선은 밝게, 막 켜진 선은 서서히
		local fresh = math.clamp((h - L.dist) / STEP, 0, 1)
		local front = math.clamp(1 - math.abs(h - L.dist) / (STEP * 0.8), 0, 1)
		p.Transparency = 1 - (1 - L.base) * fresh * alphaMul
		if front > 0 then
			p.Transparency = math.min(p.Transparency, 0.05 + (1 - front) * 0.6)
		end
	end
	-- 내 화면: 격자 안에 들어오면 빛깔이 빠진다
	local cc: ColorCorrectionEffect? = nil
	local inside = false
	local function gradeFor(h: number, top: number)
		local r = rootOf(player and player.Character)
		local now = false
		if r then
			local d = r.Position - at
			now = math.abs(d.X) <= h and math.abs(d.Z) <= h and d.Y > -8 and d.Y <= top + 4
		end
		if now ~= inside then
			inside = now
			if now then
				cc = gradeTo(cc, 0.6, { Saturation = -0.85, Contrast = 0.25, Brightness = 0.02, TintColor = Color3.fromRGB(236, 236, 255) })
			elseif cc then
				tween(cc, 0.6, { Saturation = 0, Contrast = 0, Brightness = 0, TintColor = Color3.new(1, 1, 1) })
			end
		end
	end
	-- 1) 컷 동안: 씨앗이 맥박치고 화면이 지직거린다
	glitchNear(at, H * 2, cut * 0.8, 0.8)
	Fx.sound("deflect", 0.8, 0.4, at)
	shakeNear(at, 1, 200)
	local t0 = os.clock()
	local tStart = t0 + cut
	local tEnd = tStart + dur
	local nextGlitch = 0
	local nextGrade = 0
	local collapsing = false
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local t = now - t0
		if now < tStart then
			local pulse = 1 + 0.25 * math.sin(t * 14)
			moveCube(seed, CFrame.new(seedAt) * CFrame.Angles(t * 2, t * 3, 0), 2.4 * pulse)
			core.CFrame = CFrame.new(seedAt) * CFrame.Angles(t * 2, t * 3, 0)
			return
		end
		local u = math.clamp((now - tStart) / unfold, 0, 1)
		local s = 1 - (1 - u) ^ 3
		local alphaMul = 1
		if now >= tEnd then
			-- 3) 접힘: 0.7초 동안 한 점으로
			if not collapsing then
				collapsing = true
				Fx.sound("shatter", 0.9, 0.6, at)
			end
			local k = math.clamp((now - tEnd) / 0.7, 0, 1)
			s = (1 - k) ^ 2
			alphaMul = 1 - k * 0.4
			if k >= 1 then
				conn:Disconnect()
				pixels(seedAt, 40, 1.6, 30)
				Fx.flash(seedAt, WHITE, 90, 8, 0.6)
				Fx.ring(at + Vector3.new(0, 0.5, 0), WHITE, 4, H * 2.4, 0.6)
				shakeNear(at, 2, 200)
				if cc then
					gradeEnd(cc, 0.6)
				end
				holder:Destroy()
				for _, q in ipairs(seed) do
					q:Destroy()
				end
				core:Destroy()
				for _, d in ipairs(drifters) do
					for _, q in ipairs(d.list) do
						q:Destroy()
					end
				end
				return
			end
		end
		local h, top = H * s, TOP * s
		-- 씨앗은 펼쳐질수록 작아져 사라진다
		local seedS = 2.4 * (1 - s)
		moveCube(seed, CFrame.new(seedAt) * CFrame.Angles(t * 2, t * 3, 0), math.max(0.05, seedS))
		core.Size = Vector3.one * math.max(0.05, 2 * (1 - s))
		core.CFrame = CFrame.new(seedAt)
		for _, L in ipairs(lines) do
			place(L, h, top, alphaMul)
		end
		floor.Size = Vector3.new(h * 2, 0.2, h * 2)
		floor.CFrame = CFrame.new(at + Vector3.new(0, 0.12, 0))
		floor.Transparency = 1 - 0.55 * s
		-- 2) 머무는 동안: 빛의 물결이 바깥으로 흐르고, 가끔 몇 줄이 붉게 지직거린다
		if u >= 1 and not collapsing then
			local wave = (t * 30) % (H * 1.4)
			for _, L in ipairs(lines) do
				local w = math.clamp(1 - math.abs(L.dist - wave) / 6, 0, 1)
				if w > 0 then
					L.p.Transparency = math.min(L.p.Transparency, 0.1 + (1 - w) * 0.5)
				end
			end
			if now >= nextGlitch then
				nextGlitch = now + 0.15 + math.random() * 0.35
				for _ = 1, 4 do
					local L = lines[math.random(1, #lines)]
					L.p.Color = RED
					task.delay(0.12, function()
						if L.p.Parent then
							L.p.Color = WHITE
						end
					end)
				end
			end
			if #drifters == 0 then
				for k = 1, 10 do
					local base = at + Vector3.new(math.random(-H + 10, H - 10), math.random(8, math.floor(TOP * 0.7)), math.random(-H + 10, H - 10))
					local sz = 2 + math.random() * 3
					local list = boxEdges(CFrame.new(base), Vector3.one * sz, k % 3 == 0 and RED or WHITE, 0.12)
					local rel: { CFrame } = {}
					for i, q in ipairs(list) do
						rel[i] = CFrame.new(base):ToObjectSpace(q.CFrame)
					end
					table.insert(drifters, { list = list, rel = rel, base = base, ph = math.random() * 6 })
				end
			end
			for _, d in ipairs(drifters) do
				local cf = CFrame.new(d.base + Vector3.new(0, math.sin(t * 0.8 + d.ph) * 3, 0)) * CFrame.Angles(t * 0.5 + d.ph, t * 0.7, 0)
				-- 테두리 상자는 통째로 옮긴다
				for i, q in ipairs(d.list) do
					q.CFrame = cf * d.rel[i]
				end
			end
		end
		if now >= nextGrade then
			nextGrade = now + 0.2
			gradeFor(h, top)
		end
	end)
	-- 펼쳐지기 시작: 세 축으로 빛이 뻗는다
	task.delay(cut, function()
		Fx.sound("shatter", 0.7, 0.35, at)
		Fx.flash(seedAt, WHITE, 70, 6, 0.4)
		pixels(seedAt, 24, 1.2, 12)
		shakeNear(at, 1.6, 220)
		glitchNear(at, H * 2, 0.5, 0.5)
	end)
end

function Null.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil or (data.kind == "pulse" and data.fx == "voidCell")
end
function Null.run(data: any)
	if data.kind == "pulse" then
		voidCell(data)
		return
	end
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

return Null
