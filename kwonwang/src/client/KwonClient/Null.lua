-- 권왕 3.8판: 공백권 (화면). 지워진 것, 있어서는 안 되는 빈칸
-- 빛깔은 검정·흰색, 가끔 번쩍이는 붉은빛과 '빠진 무늬' (자홍·검정 바둑판). 움직임은 부드럽지 않고 끊긴다 (지직)
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Fx = require(script.Parent:WaitForChild("Fx"))
local CamGuard = require(script.Parent:WaitForChild("CamGuard"))

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
-- 3.17.2판: 펼쳐진 격자 공간 (쓴 사람 모델 → 공간). 격자 공간 기술이 이 격자선을 직접 움직인다
local domainState: { [Model]: any } = {}
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
-- E 소거: 흰 선택 상자가 깜박이고 안이 검게 지워졌다가 화소로 부서진다
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
-- X 존재소거: 화면 균열이 미끄러지고 빈칸 상자들이 떨어지고 멈추고 (빛깔이 날아가고), 삑, 화소로 무너진다
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

-- 초 오의 컷씬 (쓴 사람 화면에서만): 화면이 깨진다. 카메라가 끊기듯 이리저리 튀며 나를 비추고 붉고 푸르게 어긋난 null
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
		cam.CFrame = CamGuard.frame(eye, focus + Vector3.new(0, 1.5, 0), focus) * CFrame.Angles(0, 0, (shot % 2 == 0) and 0.04 or -0.04)
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

------------------------------------------------------------------------
-- 3.16.2판 극 공백권 기술 (좌표선 · 좌표 교환 · 좌표 평면 · 무한 좌표)
------------------------------------------------------------------------
-- 격자 상자: 모서리 열둘을 크기 k배로 다시 놓는다 (굵기는 그대로)
type Cage = { list: { BasePart }, rel: { CFrame }, base: { Vector3 }, w: number }
local function cage(size: Vector3, color: Color3, w: number, parent: Instance): Cage
	local list = boxEdges(CFrame.new(), size, color, w)
	local rel: { CFrame } = {}
	local base: { Vector3 } = {}
	for i, q in ipairs(list) do
		rel[i] = q.CFrame
		base[i] = q.Size
		q.Parent = parent
	end
	return { list = list, rel = rel, base = base, w = w }
end
local function placeCage(c: Cage, cf: CFrame, k: number)
	for i, q in ipairs(c.list) do
		local r, b = c.rel[i], c.base[i]
		local function ax(v: number): number
			return v > c.w * 1.5 and math.max(0.05, v * k) or v
		end
		q.Size = Vector3.new(ax(b.X), ax(b.Y), ax(b.Z))
		q.CFrame = cf * CFrame.new(r.Position * k) * r.Rotation
	end
end
local function cageColor(c: Cage, color: Color3, alpha: number?)
	for _, q in ipairs(c.list) do
		q.Color = color
		if alpha then
			q.Transparency = alpha
		end
	end
end
-- 막대 하나를 a에서 b까지 놓는다
local function beam(p: BasePart, a: Vector3, b: Vector3, w: number)
	local d = (b - a).Magnitude
	p.Size = Vector3.new(w, w, math.max(0.05, d))
	if d > 1e-3 then
		p.CFrame = CFrame.lookAt((a + b) / 2, b)
	end
end

-- E 좌표선: 허공에 좌표축이 별 모양으로 그어지고 (눈금이 찍히고), 줄을 따라 공간이 위아래로 어긋났다가 다시 붙는다
local function coordSlash(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local delay = data.delay or 0.35
	local seamAt = data.seamAt or 0.3
	local y = ground(at).Y + 3
	local holder = Instance.new("Folder")
	holder.Name = "KwonCoordSlash"
	holder.Parent = folder
	local AXES = { "x", "y", "z", "u", "v", "w" }
	type Ln = { a: Vector3, b: Vector3, line: BasePart, up: BasePart?, dn: BasePart?, side: Vector3 }
	local lns: { Ln } = {}
	Fx.sound("ping", 0.45, 2.6, at)
	for i, s in ipairs(data.segs or {}) do
		local a = Vector3.new(s[1].X, y, s[1].Z)
		local b = Vector3.new(s[2].X, y, s[2].Z)
		local dir = (b - a).Unit
		local len = (b - a).Magnitude
		local line = part(Vector3.new(0.14, 0.14, 0.1), WHITE, Enum.Material.Neon, 0)
		line.Parent = holder
		line.CFrame = CFrame.lookAt(a, b)
		local draw = delay * 0.55
		local st = (i - 1) * delay * 0.08
		task.delay(st, function()
			tween(line, draw, { Size = Vector3.new(0.14, 0.14, len), CFrame = CFrame.lookAt((a + b) / 2, b) }, Enum.EasingStyle.Quart)
		end)
		-- 눈금 (4칸마다)
		local d = 4
		while d < len - 1 do
			local tick = part(Vector3.new(0.08, d % 8 == 0 and 1.1 or 0.6, 0.08), WHITE, Enum.Material.Neon, 1)
			tick.Parent = holder
			tick.CFrame = CFrame.new(a + dir * d)
			task.delay(st + draw * d / len, function()
				if tick.Parent then
					tick.Transparency = 0.2
				end
			end)
			d += 4
		end
		-- 축 이름 (끝에 작은 글씨)
		local tip = part(Vector3.one * 0.2, WHITE, Enum.Material.Neon, 1)
		tip.Parent = holder
		tip.CFrame = CFrame.new(b + Vector3.new(0, 1.4, 0))
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 40, 0, 26)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.Parent = tip
		local tl = Instance.new("TextLabel")
		tl.BackgroundTransparency = 1
		tl.Size = UDim2.fromScale(1, 1)
		tl.Font = Enum.Font.Code
		tl.TextScaled = true
		tl.Text = AXES[i] or "?"
		tl.TextColor3 = i % 3 == 0 and RED or WHITE
		tl.TextStrokeTransparency = 0.4
		tl.Parent = bb
		table.insert(lns, { a = a, b = b, line = line, side = Vector3.new(-dir.Z, 0, dir.X) })
	end
	-- 어긋남: 줄 위·아래로 얇은 검은 막이 생겨 서로 반대로 미끄러진다
	task.delay(delay, function()
		if not holder.Parent then
			return
		end
		shakeNear(at, 1.1, 100)
		Fx.sound("shatter", 0.55, 1.9, at)
		glitchNear(at, 50, 0.15, 0.4)
		for _, L in ipairs(lns) do
			local mid = (L.a + L.b) / 2
			local len = (L.b - L.a).Magnitude
			local base = CFrame.lookAt(mid, L.b)
			local up = part(Vector3.new(0.25, 5, len), BLACK, Enum.Material.SmoothPlastic, 0.2)
			local dn = part(Vector3.new(0.25, 5, len), BLACK, Enum.Material.SmoothPlastic, 0.2)
			up.Parent, dn.Parent = holder, holder
			up.CFrame = base * CFrame.new(0, 2.5, 0)
			dn.CFrame = base * CFrame.new(0, -2.5, 0)
			tween(up, 0.08, { CFrame = base * CFrame.new(0, 2.5, 0) + L.side * 1.4 })
			tween(dn, 0.08, { CFrame = base * CFrame.new(0, -2.5, 0) - L.side * 1.4 })
			L.up, L.dn = up, dn
			L.line.Color = RED
			tear(mid + Vector3.new(0, 1, 0), len * 0.6, 0.08)
			for k = 0, 2 do
				pixels(L.a:Lerp(L.b, 0.2 + k * 0.3), 5, 0.9)
			end
		end
	end)
	-- 다시 붙는다
	task.delay(delay + seamAt, function()
		if not holder.Parent then
			return
		end
		Fx.sound("ping", 0.6, 1.5, at)
		for _, L in ipairs(lns) do
			local mid = (L.a + L.b) / 2
			local base = CFrame.lookAt(mid, L.b)
			L.line.Color = WHITE
			if L.up and L.dn then
				tween(L.up, 0.06, { CFrame = base * CFrame.new(0, 2.5, 0) })
				tween(L.dn, 0.06, { CFrame = base * CFrame.new(0, -2.5, 0) })
			end
			pixels(mid, 6, 1)
		end
		Fx.flash(at + Vector3.new(0, 3, 0), WHITE, 40, 3, 0.25)
		task.delay(0.08, function()
			for _, q in ipairs(holder:GetChildren()) do
				if q:IsA("BasePart") then
					fadeOut(q, 0.25)
				end
			end
		end)
	end)
	task.delay(delay + seamAt + 1.5, function()
		holder:Destroy()
	end)
end

-- R 좌표 교환: 나와 적이 흰 격자 상자에 갇히고 점선으로 이어졌다가, 자리가 맞바뀐다. 바뀐 자리의 상자가 오그라들며 터진다
local function coordSwap(data: any)
	local from: Vector3 = data.from
	if not near(from, 220) then
		return
	end
	local m: Model? = data.m
	local delay = data.delay or 0.18
	local every = data.every or 0.3
	local implode = data.implode or 0.3
	local radius = data.radius or 9
	local holder = Instance.new("Folder")
	holder.Name = "KwonCoordSwap"
	holder.Parent = folder
	local box = Vector3.new(5, 6.5, 5)
	for i, t in ipairs(data.targets or {}) do
		task.delay((i - 1) * every, function()
			local tr = rootOf(t)
			local mr = rootOf(m)
			if not tr or not holder.Parent then
				return
			end
			local A = (i == 1 or not mr) and from or mr.Position
			local B = tr.Position
			local ca = cage(box, WHITE, 0.14, holder)
			local cb = cage(box, WHITE, 0.14, holder)
			placeCage(ca, CFrame.new(A), 1)
			placeCage(cb, CFrame.new(B), 1)
			-- 두 좌표를 잇는 점선
			local dashes: { BasePart } = {}
			local n = math.max(4, math.floor((B - A).Magnitude / 2.5))
			for k = 0, n - 1, 2 do
				local q = part(Vector3.one * 0.1, WHITE, Enum.Material.Neon, 0.1)
				q.Parent = holder
				beam(q, A:Lerp(B, k / n), A:Lerp(B, (k + 1) / n), 0.1)
				table.insert(dashes, q)
			end
			Fx.sound("ping", 0.5, 2.2, B)
			task.delay(delay, function()
				if not holder.Parent then
					return
				end
				-- 맞바뀐다: 두 자리에 어긋난 잔상, 찢어진 줄
				ghostAt(m, CFrame.new(A), CYAN, 0.5, 0.15)
				ghostAt(t, CFrame.new(B), RED, 0.5, 0.15)
				tear(A + Vector3.new(0, 1, 0), 6, 0.08)
				tear(B + Vector3.new(0, 1, 0), 6, 0.08)
				pixels(A, 10, 0.9)
				pixels(B, 10, 0.9)
				for _, q in ipairs(dashes) do
					q:Destroy()
				end
				cageColor(ca, RED)
				for _, q in ipairs(cb.list) do
					fadeOut(q, 0.2)
				end
				Fx.sound("shatter", 0.45, 2.2, A)
				glitchNear(A, 50, 0.15, 0.5)
				-- 바뀐 자리 (A)의 상자가 오그라든다
				local t0 = os.clock()
				local conn: RBXScriptConnection
				conn = RunService.Heartbeat:Connect(function()
					local u = math.clamp((os.clock() - t0) / implode, 0, 1)
					placeCage(ca, CFrame.new(A) * CFrame.Angles(0, u * 1.2, 0), 1 - 0.9 * u * u)
					if u >= 1 then
						conn:Disconnect()
						for _, q in ipairs(ca.list) do
							q:Destroy()
						end
						pixels(A, 22, 1.3, 9)
						Fx.ring(ground(A) + Vector3.new(0, 0.3, 0), RED, 2, radius * 2, 0.3)
						Fx.ring(ground(A) + Vector3.new(0, 0.5, 0), WHITE, 2, radius * 1.6, 0.25)
						Fx.flash(A, WHITE, 40, 4, 0.25)
						Fx.sound("heavy", 0.6, 1.4, A)
						shakeNear(A, 1.2, 90)
					end
				end)
			end)
		end)
	end
	task.delay(#(data.targets or {}) * every + delay + implode + 1.5, function()
		holder:Destroy()
	end)
end

-- G 좌표 평면: 허리 높이에 둥근 격자 평면이 펼쳐지고 평면의 위층·아래층이 서로 반대로 미끄러진다 (방향이 매번 90도씩 돈다). 끝에 조각나 흩어진다
local function planeShear(data: any)
	local at: Vector3 = data.at
	if not near(at, 260) then
		return
	end
	local R = data.radius or 30
	local delay = data.delay or 0.45
	local shears = data.shears or 4
	local every = data.every or 0.32
	local shift = data.shift or 5
	local finalAt = data.finalAt or 0.35
	local g = ground(at)
	local c = Vector3.new(at.X, g.Y + 3.2, at.Z)
	local holder = Instance.new("Folder")
	holder.Name = "KwonPlaneShear"
	holder.Parent = folder
	type Bar = { p: BasePart, cf: CFrame, len: number, w: number }
	local upper: { Bar } = {}
	local lower: { Bar } = {}
	local function addBar(list: { Bar }, cf: CFrame, len: number, w: number, color: Color3, alpha: number)
		local p = part(Vector3.new(w, w, 0.05), color, Enum.Material.Neon, alpha)
		p.Parent = holder
		p.CFrame = cf
		table.insert(list, { p = p, cf = cf, len = len, w = w })
	end
	local GAP = 6
	local v = -R + GAP / 2
	while v < R do
		local hl = math.sqrt(math.max(0, R * R - v * v))
		if hl > 2 then
			addBar(upper, CFrame.lookAt(c + Vector3.new(0, 0.25, v), c + Vector3.new(1, 0.25, v)), hl * 2, 0.12, WHITE, 0.15)
			addBar(lower, CFrame.lookAt(c + Vector3.new(v, -0.25, 0), c + Vector3.new(v, -0.25, 1)), hl * 2, 0.12, WHITE, 0.35)
		end
		v += GAP
	end
	-- 둘레 (위층)
	local RIM = 28
	for k = 0, RIM - 1 do
		local a0, a1 = k / RIM * math.pi * 2, (k + 1) / RIM * math.pi * 2
		local p0 = c + Vector3.new(math.cos(a0) * R, 0.25, math.sin(a0) * R)
		local p1 = c + Vector3.new(math.cos(a1) * R, 0.25, math.sin(a1) * R)
		addBar(upper, CFrame.lookAt((p0 + p1) / 2, p1), (p1 - p0).Magnitude, 0.18, WHITE, 0.05)
	end
	-- 평면 (검은 유리판)
	local disc = part(Vector3.new(0.12, R * 2, R * 2), BLACK, Enum.Material.Glass, 1)
	disc.Shape = Enum.PartType.Cylinder
	disc.Parent = holder
	disc.CFrame = CFrame.new(c) * CFrame.Angles(0, 0, math.rad(90))
	tween(disc, delay, { Transparency = 0.6 })
	-- 펼쳐진다: 막대가 가운데에서 양끝으로 자란다
	for _, list in ipairs({ upper, lower }) do
		for _, b in ipairs(list) do
			tween(b.p, delay * 0.85, { Size = Vector3.new(b.w, b.w, b.len) }, Enum.EasingStyle.Quart)
		end
	end
	Fx.sound("ping", 0.6, 1.3, c)
	-- 미끄러짐
	for i = 1, shears do
		task.delay(delay + (i - 1) * every, function()
			if not holder.Parent then
				return
			end
			local a = (i - 1) * math.pi / 2
			local dir = Vector3.new(math.cos(a), 0, math.sin(a)) * shift
			for _, b in ipairs(upper) do
				tween(b.p, 0.07, { CFrame = b.cf + dir })
			end
			for _, b in ipairs(lower) do
				tween(b.p, 0.07, { CFrame = b.cf - dir })
			end
			task.delay(every * 0.55, function()
				for _, b in ipairs(upper) do
					if b.p.Parent then
						tween(b.p, every * 0.3, { CFrame = b.cf })
					end
				end
				for _, b in ipairs(lower) do
					if b.p.Parent then
						tween(b.p, every * 0.3, { CFrame = b.cf })
					end
				end
			end)
			-- 붉은 이음매가 번쩍
			local seam = part(Vector3.new(0.08, R * 2, R * 2), RED, Enum.Material.Neon, 0.55)
			seam.Shape = Enum.PartType.Cylinder
			seam.CFrame = disc.CFrame
			fadeOut(seam, 0.18)
			tear(c + dir * 0.5, R * 0.8, 0.07)
			Fx.sound("shatter", 0.4, 1.6 + i * 0.1, c)
			shakeNear(c, 0.7, 90)
		end)
	end
	-- 조각나 흩어진다
	task.delay(delay + shears * every + finalAt, function()
		if not holder.Parent then
			return
		end
		for _, list in ipairs({ upper, lower }) do
			for _, b in ipairs(list) do
				local out = flat(b.p.Position - c)
				local spin = CFrame.Angles(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
				tween(b.p, 0.5, { CFrame = (b.p.CFrame + out * R * 0.5 + Vector3.new(0, math.random() * 6, 0)) * spin, Transparency = 1 })
			end
		end
		tween(disc, 0.3, { Transparency = 1 })
		for _ = 1, 10 do
			local a, rr = math.random() * math.pi * 2, math.random() * R
			pixels(c + Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr), 6, 1.3, 8)
		end
		Fx.ring(g + Vector3.new(0, 0.5, 0), WHITE, 4, R * 2.4, 0.5)
		Fx.ring(c, RED, 4, R * 2.1, 0.4)
		Fx.flash(c, WHITE, 90, 7, 0.4)
		Fx.sound("shatter", 0.9, 1.1, c)
		Fx.sound("heavy", 0.8, 0.8, c)
		shakeNear(c, 2.2, 150)
		glitchNear(c, 120, 0.3, 0.8)
		task.delay(0.6, function()
			holder:Destroy()
		end)
	end)
	task.delay(delay + shears * every + finalAt + 3, function()
		if holder.Parent then
			holder:Destroy()
		end
	end)
end

-- X 무한 좌표: 머리 위 한 점에서 좌표선이 뻗어 둘레의 적마다 흰 격자 상자를 씌운다.
-- 상자가 세 번 오그라들며 조이고 (붉게 번쩍), 빛깔이 뒤집힌 뒤 모든 상자가 한꺼번에 한 점으로 지워진다
local function latticePrison(data: any)
	local at: Vector3 = data.at
	if not near(at, 340) then
		return
	end
	local range = data.range or 50
	local build = data.build or 0.6
	local steps = data.steps or 3
	local every = data.every or 0.45
	local finalAt = data.finalAt or 0.5
	local g = ground(at)
	local hub = g + Vector3.new(0, 16, 0)
	local holder = Instance.new("Folder")
	holder.Name = "KwonLatticePrison"
	holder.Parent = folder
	local cc: ColorCorrectionEffect? = nil
	if near(at, range * 2.2) then
		cc = gradeTo(nil, 0.3, { Saturation = -0.6, Contrast = 0.15 })
	end
	local hubCage = cage(Vector3.one * 2.4, WHITE, 0.14, holder)
	type Item = { tr: BasePart, c: Cage, link: BasePart, size: Vector3, k: number, goal: number, last: Vector3 }
	local items: { Item } = {}
	local targets = data.targets or {}
	for i, t in ipairs(targets) do
		local tr = rootOf(t)
		if tr then
			local ext = (t :: Model):GetExtentsSize()
			local size = Vector3.new(math.clamp(ext.X, 4, 16) + 1.5, math.clamp(ext.Y, 5, 20) + 1.5, math.clamp(ext.Z, 4, 16) + 1.5)
			local c = cage(size, WHITE, 0.16, holder)
			placeCage(c, CFrame.new(tr.Position), 0.01)
			local link = part(Vector3.one * 0.1, WHITE, Enum.Material.Neon, 1)
			link.Parent = holder
			local it: Item = { tr = tr, c = c, link = link, size = size, k = 0.01, goal = 0.01, last = tr.Position }
			table.insert(items, it)
			task.delay(build * (i - 1) / math.max(1, #targets), function()
				it.goal = 1
				link.Transparency = 0.35
				Fx.sound("ping", 0.35, 2 + i * 0.05, tr.Position)
			end)
		end
	end
	Fx.sound("heavy", 0.6, 0.6, hub)
	shakeNear(g, 1.2, 200)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	local done = false
	local function finish()
		if done then
			return
		end
		done = true
		conn:Disconnect()
		gradeEnd(cc, 0.5)
		holder:Destroy()
	end
	conn = RunService.RenderStepped:Connect(function()
		local ok = pcall(function()
			local t = os.clock() - t0
			placeCage(hubCage, CFrame.new(hub) * CFrame.Angles(t * 1.5, t * 2, 0), 1)
			for _, it in ipairs(items) do
				if it.tr.Parent then
					it.last = it.tr.Position
				end
				it.k += (it.goal - it.k) * 0.3
				placeCage(it.c, CFrame.new(it.last), it.k)
				local top = it.last + Vector3.new(0, it.size.Y / 2 * it.k, 0)
				beam(it.link, hub, top, 0.1)
			end
		end)
		if not ok then
			finish()
		end
	end)
	-- 조인다
	for s = 1, steps do
		task.delay(build + (s - 1) * every, function()
			if done then
				return
			end
			for _, it in ipairs(items) do
				it.goal = 1 - s * 0.17
				cageColor(it.c, RED)
				pixels(it.last, 4, 0.8)
			end
			task.delay(0.1, function()
				for _, it in ipairs(items) do
					if it.c.list[1] and it.c.list[1].Parent then
						cageColor(it.c, WHITE)
					end
				end
			end)
			Fx.sound("ping", 0.6, 1.4 + s * 0.3, hub)
			shakeNear(g, 0.8 + s * 0.3, 160)
		end)
	end
	-- 멈춤: 빛깔이 뒤집힌다
	task.delay(build + steps * every, function()
		if done then
			return
		end
		if cc then
			gradeTo(cc, 0.08, { Saturation = -1, Contrast = 0.8, Brightness = 0.25 })
		end
		glitchNear(g, range * 2.2, finalAt, 1)
	end)
	-- 지워진다
	task.delay(build + steps * every + finalAt, function()
		if done then
			return
		end
		for _, it in ipairs(items) do
			it.goal = 0.01
			it.link.Transparency = 1
		end
		task.delay(0.12, function()
			for _, it in ipairs(items) do
				pixels(it.last, 18, 1.4, 9)
				Fx.ring(ground(it.last) + Vector3.new(0, 0.4, 0), RED, 2, 14, 0.35)
			end
			for k = 1, 3 do
				task.delay(k * 0.06, function()
					Fx.ring(g + Vector3.new(0, 0.5 + k, 0), k == 2 and RED or WHITE, 6, range * 2.2 + k * 10, 0.6)
				end)
			end
			Fx.flash(g + Vector3.new(0, 5, 0), WHITE, 150, 9, 0.6)
			Fx.sound("shatter", 1, 0.7, g)
			Fx.sound("heavy", 1, 0.45, g)
			shakeNear(g, 3.2, 220)
			if opts.flash and near(g, 120) then
				opts.flash(WHITE, 0.3)
			end
			finish()
		end)
	end)
	task.delay(build + steps * every + finalAt + 3, finish)
end

------------------------------------------------------------------------
-- 3.17.1판 극 공백권 오의 · 천공 격자: 하늘에서 흰 격자 정육면체가 짜이며 돌다가 내려꽂힌다.
-- 땅에 격자가 새겨지고 칸이 안에서 밖으로 붉게 터지며 (물결 셋), 끝에 정육면체가 수백 조각으로 흩어진다
------------------------------------------------------------------------
local function latticeDrop(data: any)
	local at: Vector3 = data.at
	if not near(at, 300) then
		return
	end
	local S = data.size or 26
	local appear = data.appear or 0.55
	local fall = data.fall or 0.3
	local waves = data.waves or 3
	local every = data.every or 0.28
	local finalAt = data.finalAt or 0.35
	local g = ground(at)
	local holder = Instance.new("Folder")
	holder.Name = "KwonLatticeDrop"
	holder.Parent = folder
	-- 정육면체: 축마다 (n+1)² 줄 (n = 3 칸)
	type Bar = { p: BasePart, rel: CFrame, len: number, w: number }
	local bars: { Bar } = {}
	local N = 3
	local h = S / 2
	for _, axis in ipairs({ "x", "y", "z" }) do
		for i = 0, N do
			for j = 0, N do
				local u, v = -h + i * S / N, -h + j * S / N
				local edge = (i == 0 or i == N) and (j == 0 or j == N)
				local w = edge and 0.55 or 0.28
				local rel: CFrame
				if axis == "x" then
					rel = CFrame.new(0, u, v)
				elseif axis == "y" then
					rel = CFrame.new(u, 0, v) * CFrame.Angles(0, 0, math.rad(90))
				else
					rel = CFrame.new(u, v, 0) * CFrame.Angles(0, math.rad(90), 0)
				end
				local p = part(Vector3.new(0.1, w, w), edge and WHITE or Color3.fromRGB(225, 225, 235), Enum.Material.Neon, edge and 0 or 0.25)
				p.Parent = holder
				table.insert(bars, { p = p, rel = rel, len = S, w = w })
			end
		end
	end
	-- 속의 검은 덩어리와 꼭짓점의 붉은 마디
	local core = part(Vector3.one * S * 0.96, BLACK, Enum.Material.SmoothPlastic, 0.55)
	core.Parent = holder
	local nodes: { { p: BasePart, rel: CFrame } } = {}
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local q = part(Vector3.one * 1.4, RED, Enum.Material.Neon, 0)
				q.Shape = Enum.PartType.Ball
				q.Parent = holder
				table.insert(nodes, { p = q, rel = CFrame.new(sx * h, sy * h, sz * h) })
			end
		end
	end
	local function place(cf: CFrame, k: number)
		for _, b in ipairs(bars) do
			b.p.Size = Vector3.new(math.max(0.05, b.len * k), b.w, b.w)
			b.p.CFrame = cf * b.rel
		end
		core.Size = Vector3.one * math.max(0.1, S * 0.96 * k)
		core.CFrame = cf
		for _, nd in ipairs(nodes) do
			nd.p.CFrame = cf * CFrame.new(nd.rel.Position * k)
		end
	end
	-- 땅의 겨냥 고리 (붉은 점선) 와 하늘에서 내리는 빛줄
	local warn = {}
	for k = 0, 23, 2 do
		local a0, a1 = k / 24 * math.pi * 2, (k + 1) / 24 * math.pi * 2
		local r = S * 0.7
		local p0 = g + Vector3.new(math.cos(a0) * r, 0.3, math.sin(a0) * r)
		local p1 = g + Vector3.new(math.cos(a1) * r, 0.3, math.sin(a1) * r)
		local q = part(Vector3.new(0.35, 0.12, (p1 - p0).Magnitude), RED, Enum.Material.Neon, 0.1)
		q.Parent = holder
		q.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
		table.insert(warn, q)
	end
	local beam = part(Vector3.new(0.4, 80, 0.4), WHITE, Enum.Material.Neon, 0.4)
	beam.Parent = holder
	beam.CFrame = CFrame.new(g + Vector3.new(0, 40, 0))
	local top = g + Vector3.new(0, 70 + h, 0)
	local landAt = g + Vector3.new(0, h - 1, 0)
	Fx.sound("deflect", 0.7, 0.5, at)
	glitchNear(g, 60, 0.2, 0.4)
	local t0 = os.clock()
	local landed = false
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t < appear then
			-- 짜인다: 한 점에서 커지며 돈다
			local u = t / appear
			local k = 1 - (1 - u) ^ 3
			place(CFrame.new(top) * CFrame.Angles(t * 1.6, t * 2.2, t * 0.8), math.max(0.02, k))
		elseif t < appear + fall then
			-- 내리꽂힌다 (돌던 것이 바로 선다)
			local u = (t - appear) / fall
			local pos = top:Lerp(landAt, u * u)
			local spin = (1 - u)
			place(CFrame.new(pos) * CFrame.Angles(appear * 1.6 * spin, appear * 2.2 * spin, appear * 0.8 * spin), 1)
		else
			conn:Disconnect()
			if not landed then
				landed = true
				place(CFrame.new(landAt), 1)
			end
		end
	end)
	-- 땅에 박힌다
	task.delay(appear + fall, function()
		if not holder.Parent then
			return
		end
		beam:Destroy()
		for _, q in ipairs(warn) do
			q:Destroy()
		end
		-- 땅에 새겨지는 격자
		local G = S * 1.6
		local cell = S / N
		local lines = math.floor(G / cell / 2)
		for i = -lines, lines do
			local a = part(Vector3.new(G, 0.1, 0.22), WHITE, Enum.Material.Neon, 0.15)
			a.Parent = holder
			a.CFrame = CFrame.new(g + Vector3.new(0, 0.18, i * cell))
			local b = part(Vector3.new(0.22, 0.1, G), WHITE, Enum.Material.Neon, 0.15)
			b.Parent = holder
			b.CFrame = CFrame.new(g + Vector3.new(i * cell, 0.18, 0))
		end
		Fx.flash(g + Vector3.new(0, 6, 0), WHITE, 120, 10, 0.5)
		Fx.ring(g + Vector3.new(0, 0.4, 0), WHITE, 6, S * 3.2, 0.6)
		Fx.ring(g + Vector3.new(0, 0.6, 0), RED, 4, S * 2.4, 0.5)
		Fx.dust(g, 8)
		Fx.sound("heavy", 1, 0.45, at)
		Fx.sound("shatter", 0.8, 0.8, at)
		shakeNear(g, 3.2, 240)
		glitchNear(g, 120, 0.3, 1)
		if opts.flash and near(g, 90) then
			opts.flash(WHITE, 0.2)
		end
		-- 칸마다 붉게: 가운데서 바깥으로 번지는 물결
		for w = 1, waves do
			task.delay(w * every, function()
				if not holder.Parent then
					return
				end
				local band = w / waves * lines
				for i = -lines, lines - 1 do
					for j = -lines, lines - 1 do
						local d = math.max(math.abs(i + 0.5), math.abs(j + 0.5))
						if math.abs(d - band) < 0.9 and (i + j + w) % 2 == 0 then
							local q = part(Vector3.new(cell - 0.6, 0.12, cell - 0.6), RED, Enum.Material.Neon, 0.25)
							q.CFrame = CFrame.new(g + Vector3.new((i + 0.5) * cell, 0.25, (j + 0.5) * cell))
							fadeOut(q, every * 0.9, { Size = Vector3.new(cell - 0.6, 3, cell - 0.6), CFrame = q.CFrame + Vector3.new(0, 1.5, 0) })
						end
					end
				end
				pixels(g + Vector3.new(0, 2, 0), 12, 1.2, S * 0.4)
				Fx.sound("ping", 0.6, 1.4 + w * 0.2, at)
				shakeNear(g, 1, 160)
			end)
		end
		-- 산산이
		task.delay(waves * every + finalAt, function()
			if not holder.Parent then
				return
			end
			local c = landAt
			for _, b in ipairs(bars) do
				local out = (b.p.Position - c)
				out = out.Magnitude > 0.1 and out.Unit or Vector3.new(0, 1, 0)
				local spin = CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3)
				tween(b.p, 0.7, { CFrame = (b.p.CFrame + out * S * 0.9 + Vector3.new(0, math.random() * S * 0.6, 0)) * spin, Transparency = 1, Size = Vector3.new(b.len * 0.3, b.w, b.w) })
			end
			for _, nd in ipairs(nodes) do
				tween(nd.p, 0.5, { CFrame = nd.p.CFrame + (nd.p.Position - c).Unit * S, Transparency = 1 })
			end
			tween(core, 0.15, { Size = Vector3.one * 0.5, Transparency = 1 })
			local ball = part(Vector3.one * 4, WHITE, Enum.Material.Neon, 0)
			ball.Shape = Enum.PartType.Ball
			ball.CFrame = CFrame.new(c)
			fadeOut(ball, 0.5, { Size = Vector3.one * S * 2.2 })
			for _ = 1, 10 do
				pixels(c + Vector3.new((math.random() - 0.5) * S, (math.random() - 0.5) * S, (math.random() - 0.5) * S), 6, 1.6, 10)
			end
			Fx.ring(g + Vector3.new(0, 0.5, 0), WHITE, 6, S * 3.6, 0.7)
			Fx.ring(g + Vector3.new(0, 1, 0), RED, 6, S * 3, 0.6)
			Fx.flash(c, WHITE, 140, 10, 0.6)
			Fx.sound("shatter", 1, 0.6, at)
			Fx.sound("heavy", 1, 0.6, at)
			shakeNear(g, 3.6, 260)
			glitchNear(g, 140, 0.4, 1.2)
			task.delay(0.8, function()
				holder:Destroy()
			end)
		end)
	end)
	task.delay(appear + fall + waves * every + finalAt + 4, function()
		if holder.Parent then
			holder:Destroy()
		end
	end)
end

------------------------------------------------------------------------
-- 3.17.1판 극 공백권 초 오의 · 차원 절단
-- 컷씬 뒤 둘레에 흰 격자 하늘 (경선 열둘 · 위선 넷의 반구)이 땅에서부터 짜여 오르고 거대한 빛의 칼날 판이 공간을 가른다.
-- 가를 때마다 그 판 한쪽의 격자가 통째로 어긋난다. 멈추고 빛깔이 뒤집힌 뒤, 모든 격자가 머리 위 한 점으로 빨려 들어 하얗게 터진다
------------------------------------------------------------------------
local function dimensionCut(data: any)
	local at: Vector3 = data.at
	if not near(at, 400) then
		return
	end
	local R = data.range or 52
	local cut = data.cut or 1.6
	local build = data.build or 0.7
	local slices = data.slices or 6
	local every = data.every or 0.32
	local freeze = data.freeze or 0.45
	local rng = Random.new(data.seed or 1)
	local g = ground(at)
	local holder = Instance.new("Folder")
	holder.Name = "KwonDimensionCut"
	holder.Parent = folder
	local cc: ColorCorrectionEffect? = nil
	local done = false
	type Seg = { p: BasePart, a: Vector3, b: Vector3, w: number, off: Vector3, order: number }
	local segs: { Seg } = {}
	local function seg(a: Vector3, b: Vector3, w: number, order: number, color: Color3?)
		local p = part(Vector3.new(w, w, 0.05), color or WHITE, Enum.Material.Neon, 1)
		p.Parent = holder
		table.insert(segs, { p = p, a = a, b = b, w = w, off = Vector3.zero, order = order })
	end
	-- 반구: 경선 (땅에서 꼭대기로) · 위선 (고리)
	local function sph(lat: number, lon: number): Vector3
		return g + Vector3.new(math.cos(lat) * math.cos(lon) * R, math.sin(lat) * R * 0.75, math.cos(lat) * math.sin(lon) * R)
	end
	local LAT, LON = 6, 12
	for i = 0, LON - 1 do
		local lon = i / LON * math.pi * 2
		for k = 0, LAT - 1 do
			local l0, l1 = k / LAT * math.pi / 2, (k + 1) / LAT * math.pi / 2
			seg(sph(l0, lon), sph(l1, lon), 0.35, k)
		end
	end
	for k = 1, 4 do
		local lat = k / 5 * math.pi / 2
		for i = 0, 23 do
			local a0, a1 = i / 24 * math.pi * 2, (i + 1) / 24 * math.pi * 2
			seg(sph(lat, a0), sph(lat, a1), 0.28, k * 1.2)
		end
	end
	-- 땅의 고리
	for i = 0, 35 do
		local a0, a1 = i / 36 * math.pi * 2, (i + 1) / 36 * math.pi * 2
		seg(sph(0, a0) + Vector3.new(0, 0.2, 0), sph(0, a1) + Vector3.new(0, 0.2, 0), 0.6, 0, RED)
	end
	local function draw(k: number, alpha: number)
		for _, s in ipairs(segs) do
			local u = math.clamp(k * (LAT + 1) - s.order, 0, 1)
			if u <= 0 then
				s.p.Transparency = 1
			else
				local a, b = s.a + s.off, s.a + s.off + (s.b - s.a) * u
				s.p.Size = Vector3.new(s.w, s.w, math.max(0.05, (b - a).Magnitude))
				s.p.CFrame = CFrame.lookAt((a + b) / 2, b + (b - a).Unit * 0.001)
				s.p.Transparency = alpha
			end
		end
	end
	-- 1) 짜인다
	task.delay(cut, function()
		if done then
			return
		end
		if near(at, R * 2.2) then
			cc = gradeTo(nil, 0.4, { Saturation = -0.8, Contrast = 0.2, TintColor = Color3.fromRGB(235, 238, 255) })
		end
		Fx.sound("deflect", 0.9, 0.4, at)
		shakeNear(g, 1.6, 240)
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local u = math.clamp((os.clock() - t0) / build, 0, 1)
			draw(1 - (1 - u) ^ 2, 0.15)
			if u >= 1 or done then
				conn:Disconnect()
			end
		end)
	end)
	-- 2) 가른다: 빛의 칼날 판 (가로 판과 세로 판을 섞어서), 판 한쪽의 격자가 어긋난다
	for i = 1, slices do
		task.delay(cut + build + (i - 1) * every, function()
			if done then
				return
			end
			local vertical = i % 2 == 1
			local cf: CFrame
			local normal: Vector3
			if vertical then
				local a = rng:NextNumber(0, math.pi)
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				normal = Vector3.new(-dir.Z, 0, dir.X)
				local off = normal * rng:NextNumber(-R * 0.35, R * 0.35)
				cf = CFrame.lookAt(g + off + Vector3.new(0, R * 0.38, 0), g + off + Vector3.new(0, R * 0.38, 0) + dir)
			else
				normal = Vector3.new(0, 1, 0)
				local y = rng:NextNumber(3, R * 0.5)
				cf = CFrame.new(g + Vector3.new(0, y, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
			end
			-- 판: 처음엔 칼날 같은 선, 순간 판 전체가 하얗게 번쩍
			local plate = part(vertical and Vector3.new(0.3, R * 0.9, R * 2.2) or Vector3.new(R * 2.2, 0.3, R * 2.2), WHITE, Enum.Material.Neon, 0.05)
			plate.Parent = holder
			plate.CFrame = cf
			local edge = part(vertical and Vector3.new(0.6, 0.6, R * 2.4) or Vector3.new(R * 2.4, 0.6, 0.6), RED, Enum.Material.Neon, 0)
			edge.Parent = holder
			edge.CFrame = vertical and (CFrame.new(Vector3.new(cf.Position.X, g.Y + 0.4, cf.Position.Z)) * cf.Rotation) or cf
			fadeOut(plate, 0.22, { Size = vertical and Vector3.new(0.05, R * 0.95, R * 2.3) or Vector3.new(R * 2.3, 0.05, R * 2.3) })
			fadeOut(edge, every * 1.6)
			-- 판 한쪽의 격자가 통째로 어긋난다
			local shift = (vertical and Vector3.new(0, rng:NextNumber(-1, 1) > 0 and 2.2 or -2.2, 0) or Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)).Unit * 2.6)
			for _, s in ipairs(segs) do
				local mid = (s.a + s.b) / 2 + s.off
				if (mid - cf.Position):Dot(normal) > 0 then
					s.off += shift
				end
			end
			draw(1, 0.15)
			tear(cf.Position, R * 1.4, 0.08)
			for _ = 1, 4 do
				pixels(g + Vector3.new(rng:NextNumber(-R, R) * 0.6, rng:NextNumber(2, R * 0.5), rng:NextNumber(-R, R) * 0.6), 6, 1.4, 6)
			end
			Fx.flash(cf.Position, WHITE, 120, 8, 0.25)
			Fx.sound("shatter", 0.8, 0.8 + i * 0.12, at)
			Fx.sound("block", 0.7, 0.5 + i * 0.05, at)
			shakeNear(g, 1.4 + i * 0.25, 260)
			glitchNear(g, R * 2.2, 0.12, 0.8)
			if opts.flash and near(g, R * 1.5) then
				opts.flash(WHITE, 0.08)
			end
		end)
	end
	-- 3) 멈춤: 빛깔이 뒤집히고 격자가 붉게
	task.delay(cut + build + slices * every, function()
		if done then
			return
		end
		if cc then
			gradeTo(cc, 0.06, { Saturation = -1, Contrast = 1, Brightness = 0.3 })
		end
		for _, s in ipairs(segs) do
			s.p.Color = RED
		end
		Fx.sound("ping", 1, 3, at)
		glitchNear(g, R * 2.4, freeze, 1.4)
	end)
	-- 4) 한 점으로 빨려 들어 하얗게 터진다
	task.delay(cut + build + slices * every + freeze, function()
		if done then
			return
		end
		done = true
		local point = g + Vector3.new(0, R * 0.45, 0)
		for _, s in ipairs(segs) do
			s.p.Color = WHITE
			tween(s.p, 0.22, { CFrame = CFrame.new(point), Size = Vector3.new(0.1, 0.1, 0.1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		task.delay(0.24, function()
			holder:Destroy()
			local ball = part(Vector3.one * 3, WHITE, Enum.Material.Neon, 0)
			ball.Shape = Enum.PartType.Ball
			ball.CFrame = CFrame.new(point)
			fadeOut(ball, 0.7, { Size = Vector3.one * R * 2.4 })
			for k = 1, 3 do
				task.delay(k * 0.07, function()
					Fx.ring(g + Vector3.new(0, 0.5 + k, 0), k == 2 and RED or WHITE, 6, R * 2.6 + k * 12, 0.7)
				end)
			end
			for _ = 1, 16 do
				local a, rr = math.random() * math.pi * 2, math.random() * R
				pixels(g + Vector3.new(math.cos(a) * rr, 2 + math.random() * 8, math.sin(a) * rr), 8, 1.6, 10)
			end
			Fx.flash(point, WHITE, 160, 12, 0.7)
			Fx.sound("shatter", 1, 0.5, at)
			Fx.sound("heavy", 1, 0.35, at)
			shakeNear(g, 4, 300)
			if opts.flash and near(g, R * 2) then
				opts.flash(WHITE, 0.35)
			end
			gradeEnd(cc, 0.8)
		end)
	end)
	-- 늦어도 반드시 치운다
	task.delay(cut + build + slices * every + freeze + 4, function()
		done = true
		if holder.Parent then
			holder:Destroy()
		end
		if cc and cc.Parent then
			gradeEnd(cc, 0.3)
		end
	end)
end

-- 3.17.1판 극 공백권 초 오의 컷씬 (쓴 사람 화면에서만): 어두워지고 카메라가 낮게 천천히 돌며 나를 올려다본다.
-- 내 둘레에서 흰 격자선이 하늘로 뻗어 오르고 끝에 화면이 한 번 하얗게 끊긴다
function Null.gridCut(model: Model, dur: number, name: string, shake: ((number) -> ())?)
	local cam = workspace.CurrentCamera
	local r = rootOf(model)
	if not cam or not r or cutActive or not player then
		return
	end
	cutActive = true
	local pg = player:WaitForChild("PlayerGui")
	local g = Instance.new("ScreenGui")
	g.Name = "KwonGridCut"
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
	tween(tint, 0.3, { BackgroundTransparency = 0.35 })
	-- 위아래 검은 띠
	for _, y in ipairs({ 0, 1 }) do
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0, y)
		bar.Position = UDim2.fromScale(0, y)
		bar.Size = UDim2.new(1, 0, 0, 0)
		bar.BackgroundColor3 = Color3.new(0, 0, 0)
		bar.BorderSizePixel = 0
		bar.ZIndex = 4
		bar.Parent = g
		tween(bar, 0.3, { Size = UDim2.new(1, 0, 0.11, 0) })
	end
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 0.86, 0)
	label.Size = UDim2.new(0.7, 0, 0.09, 0)
	label.Font = Enum.Font.Code
	label.TextScaled = true
	label.Text = "초 오의 · " .. name
	label.TextColor3 = WHITE
	label.TextStrokeColor3 = RED
	label.TextStrokeTransparency = 0.3
	label.TextTransparency = 1
	label.ZIndex = 5
	label.Parent = g
	tween(label, 0.4, { TextTransparency = 0 })
	-- 내 둘레에서 하늘로 뻗는 격자선 (세로 열여섯, 가로 고리 셋)
	local focus = r.Position
	local lines = Instance.new("Folder")
	lines.Name = "KwonGridCutLines"
	lines.Parent = folder
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		local rr = 6 + (i % 2) * 3
		local base = focus + Vector3.new(math.cos(a) * rr, -2.6, math.sin(a) * rr)
		local q = part(Vector3.new(0.18, 0.1, 0.18), WHITE, Enum.Material.Neon, 0)
		q.Parent = lines
		q.CFrame = CFrame.new(base)
		task.delay(i * dur * 0.02, function()
			tween(q, dur * 0.6, { Size = Vector3.new(0.18, 60, 0.18), CFrame = CFrame.new(base + Vector3.new(0, 30, 0)) }, Enum.EasingStyle.Quart)
		end)
	end
	for k = 1, 3 do
		task.delay(dur * (0.15 + k * 0.15), function()
			for i = 0, 15 do
				local a0, a1 = i / 16 * math.pi * 2, (i + 1) / 16 * math.pi * 2
				local rr = 7.5
				local y = -2.6 + k * 6
				local p0 = focus + Vector3.new(math.cos(a0) * rr, y, math.sin(a0) * rr)
				local p1 = focus + Vector3.new(math.cos(a1) * rr, y, math.sin(a1) * rr)
				local q = part(Vector3.new(0.14, 0.14, (p1 - p0).Magnitude), k == 2 and RED or WHITE, Enum.Material.Neon, 0.1)
				q.Parent = lines
				q.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
			end
			Fx.sound("ping", 0.5, 1 + k * 0.3, focus)
		end)
	end
	local oldType = cam.CameraType
	local oldFov = cam.FieldOfView
	local look = flat(r.CFrame.LookVector)
	local a0 = math.atan2(look.Z, look.X)
	cam.CameraType = Enum.CameraType.Scriptable
	local t0 = os.clock()
	local finished = false
	local function restore()
		if finished then
			return
		end
		finished = true
		RunService:UnbindFromRenderStep("KwonGridCut")
		cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
		cam.FieldOfView = oldFov
		cutActive = false
		tween(tint, 0.15, { BackgroundTransparency = 1 })
		tween(label, 0.15, { TextTransparency = 1 })
		task.delay(0.2, function()
			g:Destroy()
		end)
		for _, q in ipairs(lines:GetChildren()) do
			if q:IsA("BasePart") then
				fadeOut(q, 0.4)
			end
		end
		task.delay(0.5, function()
			lines:Destroy()
		end)
	end
	RunService:BindToRenderStep("KwonGridCut", Enum.RenderPriority.Camera.Value + 2, function()
		local t = os.clock() - t0
		local u = math.clamp(t / dur, 0, 1)
		-- 낮게, 천천히 반 바퀴 돌며 올려다본다
		local a = a0 + u * math.pi * 0.9
		local dist = 11 - u * 3
		local eye = focus + Vector3.new(math.cos(a) * dist, -1.2 + u * 1.5, math.sin(a) * dist)
		cam.CFrame = CamGuard.frame(eye, focus + Vector3.new(0, 3 + u * 10, 0), focus)
		cam.FieldOfView = oldFov + 12 - u * 6
		if t >= dur then
			restore()
			-- 끝: 화면이 한 번 하얗게 끊긴다
			screenGlitch(0.25, 1.4)
			if shake then
				shake(1.2)
			end
		end
	end)
	task.delay(dur + 1, restore)
end

------------------------------------------------------------------------
-- 3.17.2판 극 공백권 · 격자 공간 기술: 이미 펼쳐진 격자 공간의 격자선을 직접 쥐고 움직인다
------------------------------------------------------------------------
-- 펼쳐진 격자를 잠깐 쥔다 (그동안 격자 전개는 손대지 않는다). 놓을 때 원래대로
local function grabDomain(m: Model?): any
	local ds = m and domainState[m]
	if not ds or ds.hijack then
		return nil
	end
	ds.hijack = true
	ds.saved = {}
	for i, S in ipairs(ds.segs) do
		ds.saved[i] = { cf = S.p.CFrame, size = S.p.Size, alpha = S.p.Transparency, color = S.p.Color }
	end
	return ds
end
local function releaseDomain(ds: any)
	for i, S in ipairs(ds.segs) do
		local o = ds.saved[i]
		if o and S.p.Parent then
			S.p.CFrame = o.cf
			S.p.Size = o.size
			S.p.Transparency = o.alpha
			S.p.Color = o.color
		end
	end
	ds.hijack = false
end
-- 쥔 격자를 옮긴다: fn(원래 가운데) → 새 가운데, 가로 배율, 세로 배율
local function moveDomain(ds: any, fn: (Vector3) -> (Vector3, number, number), color: Color3?, alpha: number?)
	for i, S in ipairs(ds.segs) do
		local o = ds.saved[i]
		if o and S.p.Parent and o.alpha < 0.99 then
			local c, sh, sv = fn(o.cf.Position)
			local sz = o.size
			if S.axis == "x" then
				sz = Vector3.new(math.max(0.05, sz.X * sh), sz.Y, sz.Z)
			elseif S.axis == "z" then
				sz = Vector3.new(sz.X, sz.Y, math.max(0.05, sz.Z * sh))
			else
				sz = Vector3.new(sz.X, math.max(0.05, sz.Y * sv), sz.Z)
			end
			S.p.Size = sz
			S.p.CFrame = CFrame.new(c)
			if color then
				S.p.Color = color
			end
			if alpha then
				S.p.Transparency = math.min(o.alpha, alpha)
			end
		end
	end
end
local function line(a: Vector3, b: Vector3, w: number, color: Color3, alpha: number): BasePart
	local q = part(Vector3.new(w, w, math.max(0.05, (b - a).Magnitude)), color, Enum.Material.Neon, alpha)
	q.CFrame = CFrame.lookAt((a + b) / 2, b + (b - a).Unit * 0.001)
	return q
end

-- E 격자선 베기: 적이 선 자리를 지나는 격자선 셋이 공간 끝에서 끝까지 붉게 켜졌다가 하얗게 선째 벤다
local function gridLine(data: any)
	local at: Vector3 = data.at
	if not near(at, 400) then
		return
	end
	local R = data.radius or 85
	local top = data.top or 84
	local delay = data.delay or 0.35
	local seamAt = data.seamAt or 0.25
	local ds = data.m and domainState[data.m]
	Fx.sound("ping", 0.6, 2.2, at)
	for i, t in ipairs(data.targets or {}) do
		local tr = rootOf(t)
		if tr then
			local P = tr.Position
			local d = P - at
			local hx = math.sqrt(math.max(1, R * R - d.Z * d.Z))
			local hz = math.sqrt(math.max(1, R * R - d.X * d.X))
			local ends = {
				{ Vector3.new(at.X - hx, P.Y, P.Z), Vector3.new(at.X + hx, P.Y, P.Z) },
				{ Vector3.new(P.X, P.Y, at.Z - hz), Vector3.new(P.X, P.Y, at.Z + hz) },
				{ Vector3.new(P.X, at.Y, P.Z), Vector3.new(P.X, at.Y + top, P.Z) },
			}
			task.delay((i - 1) * 0.03, function()
				for _, e in ipairs(ends) do
					-- 적 자리에서 양쪽 끝으로 뻗는다
					for _, tip in ipairs({ e[1], e[2] }) do
						local q = line(P, P, 0.22, RED, 0.05)
						local tt0 = os.clock()
						local conn: RBXScriptConnection
						conn = RunService.Heartbeat:Connect(function()
							local u = math.clamp((os.clock() - tt0) / (delay * 0.7), 0, 1)
							local b = P:Lerp(tip, 1 - (1 - u) ^ 3)
							q.Size = Vector3.new(0.22, 0.22, math.max(0.05, (b - P).Magnitude))
							if (b - P).Magnitude > 0.01 then
								q.CFrame = CFrame.lookAt((P + b) / 2, b)
							end
							if u >= 1 then
								conn:Disconnect()
							end
						end)
						task.delay(delay, function()
							q.Color = WHITE
							q.Size = Vector3.new(0.8, 0.8, q.Size.Z)
							fadeOut(q, 0.35, { Size = Vector3.new(0.05, 0.05, q.Size.Z) })
						end)
					end
				end
				-- 둘레의 펼쳐진 격자선도 붉게 지직인다
				if ds and not ds.hijack then
					local rel = P - at
					for _, S in ipairs(ds.segs) do
						local mid = S.a + (S.b - S.a) * 0.5
						if (mid - rel).Magnitude < (ds.STEP or 26) * 1.1 then
							S.p.Color = RED
							task.delay(delay + 0.3, function()
								if S.p.Parent then
									S.p.Color = WHITE
								end
							end)
						end
					end
				end
			end)
			task.delay(delay, function()
				tear(P + Vector3.new(0, 1, 0), 10, 0.1)
				pixels(P, 14, 1.2, 8)
				Fx.flash(P, WHITE, 30, 4, 0.2)
			end)
			task.delay(delay + seamAt, function()
				pixels(P, 8, 0.9)
				Fx.ring(ground(P) + Vector3.new(0, 0.3, 0), RED, 2, 12, 0.25)
			end)
		end
	end
	task.delay(delay, function()
		Fx.sound("shatter", 0.8, 1.4, at)
		shakeNear(at, 1.4, 200)
		glitchNear(at, R * 1.5, 0.12, 0.6)
	end)
end

-- R 격자 질주: 격자선을 따라 직각으로 꺾어 달린다. 지나간 선이 하얗게 타오르고 꺾인 자리마다 붉은 마디
local function gridRun(data: any)
	local from: Vector3 = data.from
	if not near(from, 400) then
		return
	end
	local m: Model? = data.m
	local delay = data.delay or 0.08
	local every = data.every or 0.14
	local prev = from
	local r0 = rootOf(m)
	if r0 then
		ghostAt(m, r0.CFrame, BLACK, 0.2, 0.25)
	end
	for i, t in ipairs(data.targets or {}) do
		task.delay(delay + (i - 1) * every, function()
			local tr = rootOf(t)
			if not tr then
				return
			end
			local P = tr.Position
			local corner = Vector3.new(P.X, prev.Y, prev.Z)
			local corner2 = Vector3.new(P.X, prev.Y, P.Z)
			for _, sg in ipairs({ { prev, corner }, { corner, corner2 }, { corner2, P } }) do
				if (sg[2] - sg[1]).Magnitude > 0.2 then
					local q = line(sg[1], sg[2], 0.55, WHITE, 0)
					fadeOut(q, 0.6, { Size = Vector3.new(0.08, 0.08, q.Size.Z) })
					local glow = line(sg[1], sg[2], 1.4, Color3.fromRGB(200, 210, 255), 0.7)
					fadeOut(glow, 0.3)
				end
			end
			for _, c in ipairs({ corner, corner2 }) do
				local nd = part(Vector3.one * 1.2, RED, Enum.Material.Neon, 0)
				nd.Shape = Enum.PartType.Ball
				nd.CFrame = CFrame.new(c)
				fadeOut(nd, 0.5, { Size = Vector3.one * 0.2 })
			end
			local look = flat(P - prev)
			local cf = CFrame.lookAt(P - look * 3, P)
			ghostAt(m, cf * CFrame.new(0.35, 0, 0), RED, 0.55, 0.12)
			ghostAt(m, cf * CFrame.new(-0.35, 0, 0), CYAN, 0.55, 0.12)
			ghostAt(m, cf, BLACK, 0.1, 0.18)
			pixels(P, 10, 0.9)
			Fx.sound("ping", 0.45, 1.8 + i * 0.12, P)
			prev = P
		end)
	end
	glitchNear(from, 80, delay + #(data.targets or {}) * every, 0.5)
end

-- G 격자 수축: 펼친 격자 전체가 한 점으로 오그라들며 붉어진다 (끌려간다), 버티다가 튕겨 펼쳐지며 터진다
local function gridCrush(data: any)
	local at: Vector3 = data.at
	if not near(at, 400) then
		return
	end
	local point: Vector3 = data.point or at
	local pull = data.pull or 1.0
	local hold = data.hold or 0.3
	local R = data.radius or 85
	local ds = grabDomain(data.m)
	Fx.sound("deflect", 0.8, 0.35, point)
	shakeNear(point, 1.2, 240)
	local core = part(Vector3.one * 1, BLACK, Enum.Material.SmoothPlastic, 0)
	core.Shape = Enum.PartType.Ball
	core.CFrame = CFrame.new(point)
	tween(core, pull, { Size = Vector3.one * 9 })
	local rim = part(Vector3.one * 1.2, RED, Enum.Material.Neon, 0.5)
	rim.Shape = Enum.PartType.Ball
	rim.CFrame = CFrame.new(point)
	tween(rim, pull, { Size = Vector3.one * 10.5 })
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if ds then
			if t < pull then
				local u = t / pull
				local k = 1 - 0.86 * (u * u * (3 - 2 * u))
				moveDomain(ds, function(c: Vector3)
					return point + (c - point) * k, k, k
				end, WHITE:Lerp(RED, u), 0.05)
			elseif t < pull + hold then
				-- 버틴다 (떨린다)
				local j = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.6
				moveDomain(ds, function(c: Vector3)
					return point + (c - point) * 0.14 + j, 0.14, 0.14
				end, RED, 0.02)
			elseif t < pull + hold + 0.3 then
				-- 튕겨 펼쳐진다 (조금 넘쳤다가 제자리)
				local u = (t - pull - hold) / 0.3
				local k = 0.14 + (1 - 0.14) * (1 + 0.15 * math.sin(u * math.pi)) * u
				moveDomain(ds, function(c: Vector3)
					return point + (c - point) * k, k, k
				end, RED:Lerp(WHITE, u), 0.1)
			else
				conn:Disconnect()
				releaseDomain(ds)
			end
		elseif t > pull + hold + 0.3 then
			conn:Disconnect()
		end
	end)
	if not ds then
		-- 격자가 안 보이는 자리: 둘레의 붉은 고리가 오그라든다
		Fx.ring(ground(point) + Vector3.new(0, 0.4, 0), RED, R * 2, 4, pull)
	end
	task.delay(pull + hold, function()
		core:Destroy()
		rim:Destroy()
		local ball = part(Vector3.one * 3, WHITE, Enum.Material.Neon, 0)
		ball.Shape = Enum.PartType.Ball
		ball.CFrame = CFrame.new(point)
		fadeOut(ball, 0.45, { Size = Vector3.one * 56 })
		Fx.ring(ground(point) + Vector3.new(0, 0.5, 0), WHITE, 4, 70, 0.5)
		Fx.ring(ground(point) + Vector3.new(0, 0.8, 0), RED, 4, 56, 0.45)
		pixels(point, 40, 1.8, 20)
		Fx.flash(point, WHITE, 120, 10, 0.5)
		Fx.sound("shatter", 1, 0.7, point)
		Fx.sound("heavy", 1, 0.5, point)
		shakeNear(point, 3, 260)
		glitchNear(point, 140, 0.3, 1)
		if opts.flash and near(point, 100) then
			opts.flash(WHITE, 0.2)
		end
	end)
	task.delay(pull + hold + 2, function()
		if ds and ds.hijack then
			releaseDomain(ds)
		end
	end)
end

-- X 공간 접기: 네 벽이 네 번에 걸쳐 안으로 접혀 들고 (흰 벽판이 쾅), 위아래로 눌려 한 점이 된 뒤 공간째 지워진다 (격자 공간 끝)
local function domainFold(data: any)
	local at: Vector3 = data.at
	if not near(at, 450) then
		return
	end
	local R = data.radius or 85
	local top = data.top or 84
	local cut = data.cut or 1.3
	local folds = data.folds or 4
	local every = data.every or 0.38
	local squash = data.squash or 0.5
	local mid = at + Vector3.new(0, top * 0.4, 0)
	task.delay(cut, function()
		local ds = grabDomain(data.m)
		local cc: ColorCorrectionEffect? = nil
		if near(at, R * 2.2) then
			cc = gradeTo(nil, 0.3, { Saturation = -0.85, Contrast = 0.25 })
		end
		local kh = 1
		local walls: { BasePart } = {}
		local function wallsAt(k: number): { CFrame }
			local r = R * k
			return {
				CFrame.new(at + Vector3.new(r, top / 2, 0)) * CFrame.Angles(0, math.rad(90), 0),
				CFrame.new(at + Vector3.new(-r, top / 2, 0)) * CFrame.Angles(0, math.rad(90), 0),
				CFrame.new(at + Vector3.new(0, top / 2, r)),
				CFrame.new(at + Vector3.new(0, top / 2, -r)),
			}
		end
		for _, cf in ipairs(wallsAt(1)) do
			local w = part(Vector3.new(R * 2, top, 0.4), WHITE, Enum.Material.Neon, 0.82)
			w.CFrame = cf
			table.insert(walls, w)
		end
		for i = 1, folds do
			task.delay((i - 1) * every, function()
				local k0 = kh
				local k1 = 1 - i / folds * 0.9
				kh = k1
				local t0 = os.clock()
				local conn: RBXScriptConnection
				conn = RunService.RenderStepped:Connect(function()
					local u = math.clamp((os.clock() - t0) / 0.14, 0, 1)
					local k = k0 + (k1 - k0) * (u * u)
					if ds then
						moveDomain(ds, function(c: Vector3)
							return Vector3.new(at.X + (c.X - at.X) * k, c.Y, at.Z + (c.Z - at.Z) * k), k, 1
						end, i % 2 == 0 and WHITE or RED, 0.05)
					end
					local cfs = wallsAt(k)
					for wi, w in ipairs(walls) do
						w.CFrame = cfs[wi]
						w.Size = Vector3.new(R * 2 * k, top, 0.4)
					end
					if u >= 1 then
						conn:Disconnect()
					end
				end)
				-- 쾅
				for _, w in ipairs(walls) do
					w.Transparency = 0.35
					tween(w, every * 0.7, { Transparency = 0.82 })
				end
				Fx.flash(mid, i % 2 == 0 and WHITE or RED, 160, 8, 0.25)
				Fx.sound("heavy", 1, 0.5 + i * 0.08, at)
				Fx.sound("shatter", 0.7, 0.7 + i * 0.1, at)
				shakeNear(at, 2 + i * 0.4, 300)
				glitchNear(at, R * 2.4, 0.12, 0.9)
				if opts.flash and near(at, R * 1.4) then
					opts.flash(WHITE, 0.08)
				end
			end)
		end
		-- 위아래로 눌려 한 점이 된다
		task.delay(folds * every, function()
			if cc then
				gradeTo(cc, 0.06, { Saturation = -1, Contrast = 1, Brightness = 0.3 })
			end
			Fx.sound("ping", 1, 3, at)
			local t0 = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.RenderStepped:Connect(function()
				local u = math.clamp((os.clock() - t0) / squash, 0, 1)
				local kv = 1 - 0.98 * u * u
				local k = kh * (1 - u * 0.95)
				if ds then
					moveDomain(ds, function(c: Vector3)
						return Vector3.new(mid.X + (c.X - at.X) * k, mid.Y + (c.Y - mid.Y) * kv, mid.Z + (c.Z - at.Z) * k), k, kv
					end, WHITE, 0)
				end
				for _, w in ipairs(walls) do
					w.Size = Vector3.new(math.max(0.1, R * 2 * k), math.max(0.1, top * kv), 0.4)
					w.CFrame = CFrame.new(mid + (w.Position - mid) * (1 - u * 0.1)) * w.CFrame.Rotation
				end
				if u >= 1 then
					conn:Disconnect()
				end
			end)
		end)
		-- 공간째 지워진다
		task.delay(folds * every + squash, function()
			for _, w in ipairs(walls) do
				w:Destroy()
			end
			if ds then
				ds.finish()
			end
			local ball = part(Vector3.one * 2, WHITE, Enum.Material.Neon, 0)
			ball.Shape = Enum.PartType.Ball
			ball.CFrame = CFrame.new(mid)
			fadeOut(ball, 0.8, { Size = Vector3.one * R * 2.4 })
			local blackBall = part(Vector3.one * 1, BLACK, Enum.Material.SmoothPlastic, 0)
			blackBall.Shape = Enum.PartType.Ball
			blackBall.CFrame = CFrame.new(mid)
			fadeOut(blackBall, 0.5, { Size = Vector3.one * R * 1.2 })
			for k = 1, 4 do
				task.delay(k * 0.07, function()
					Fx.ring(at + Vector3.new(0, 0.5 + k, 0), k % 2 == 0 and RED or WHITE, 6, R * 2.8 + k * 12, 0.8)
				end)
			end
			for _ = 1, 18 do
				local a, rr = math.random() * math.pi * 2, math.random() * R
				pixels(at + Vector3.new(math.cos(a) * rr, 2 + math.random() * top * 0.5, math.sin(a) * rr), 8, 1.8, 12)
			end
			Fx.flash(mid, WHITE, 200, 12, 0.8)
			Fx.sound("shatter", 1, 0.4, at)
			Fx.sound("heavy", 1, 0.3, at)
			shakeNear(at, 4.5, 360)
			if opts.flash and near(at, R * 2) then
				opts.flash(WHITE, 0.45)
			end
			gradeEnd(cc, 0.9)
		end)
		task.delay(folds * every + squash + 3, function()
			for _, w in ipairs(walls) do
				if w.Parent then
					w:Destroy()
				end
			end
			if cc and cc.Parent then
				gradeEnd(cc, 0.3)
			end
		end)
	end)
end

local HANDLERS: { [string]: (any) -> () } = {
	gridLine = gridLine,
	gridRun = gridRun,
	gridCrush = gridCrush,
	domainFold = domainFold,
	latticeDrop = latticeDrop,
	dimensionCut = dimensionCut,
	coordSlash = coordSlash,
	coordSwap = coordSwap,
	planeShear = planeShear,
	latticePrison = latticePrison,
	eraseBox = eraseBox,
	glitchBlink = glitchBlink,
	voidGrid = voidGrid,
	nullOpen = nullOpen,
	nullCubes = nullCubes,
}
------------------------------------------------------------------------
-- 3.16판 극 공백권 · 격자 전개 (극 패시브). 3.16.2판에서 다시 짰다
-- 네모 상자가 아니다: 둥글고 들쭉날쭉한 둘레 안에 성긴 흰 격자가 허공에 떠 있고 둘레에서는 선이 반쯤 뻗다가 허공에서 끊긴다.
-- 한가운데 한 점에서 가까운 마디부터 선이 바깥으로 자라 공간이 펼쳐진다 (4.5초). 30초 동안 머물며 빛의 물결이 바깥으로 흐르고,
-- 가끔 끊긴 선 끝이 붉게 지직거리고 빈칸 상자 몇이 떠다닌다. 끝나면 선이 가운데로 접혀 들어가 흰 잡음으로 터진다.
-- 3.16.2판 고침: 끝나도 격자가 남던 문제. 모든 조각을 한 폴더에 모으고 정리를 한 곳(finish)에서 한 번만, 늦어도 끝 시각 3초 뒤에는 반드시 지운다.
-- 쓴 사람이 쓰러지거나 사라지면 (Twilight가 꺼지면) 바로 접힌다
------------------------------------------------------------------------
type Seg = { p: BasePart, a: Vector3, b: Vector3, axis: string, d: number, len: number, frac: number, base: number, edge: boolean }
local domains: { [any]: () -> () } = {}
function Null.domain(data: any)
	local at: Vector3 = data.at
	if not at or not near(at, 800) then
		return
	end
	local cut = data.cut or 1.6
	local dur = data.dur or 30
	local unfold = data.unfold or 4.5
	local R, TOP, STEP = data.radius or 100, data.top or 84, data.step or 26
	local LEVELS: { number } = data.levels or { 6, 28, 50, 72 }
	local owner: Model? = data.m
	local key: any = owner or at
	if domains[key] then
		domains[key]()
	end
	local holder = Instance.new("Folder")
	holder.Name = "KwonNullDomain"
	holder.Parent = folder
	local rng = Random.new(math.floor(math.abs(at.X) * 7 + math.abs(at.Z) * 13) % 1000003)
	-- 마디가 공간 안인가: 둥근 몸통 (위로 갈수록 좁다) · 마디마다 둘레가 들쭉날쭉
	local bound: { [string]: number } = {}
	local function inside(x: number, y: number, z: number): boolean
		local k = x .. "," .. y .. "," .. z
		local b = bound[k]
		if not b then
			b = 0.62 + 0.38 * rng:NextNumber()
			bound[k] = b
		end
		local yy = (y - TOP * 0.45) / (TOP * 0.75)
		return (x * x + z * z) / (R * R) + yy * yy * 0.5 <= b
	end
	local segs: { Seg } = {}
	local function addSeg(a: Vector3, b: Vector3, axis: string, edge: boolean)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = WHITE
		p.Size = Vector3.one * 0.12
		p.Transparency = 1
		p.Parent = holder
		table.insert(segs, {
			p = p,
			a = a,
			b = b,
			axis = axis,
			d = math.sqrt(a.X * a.X + a.Z * a.Z + (a.Y * 1.2) ^ 2),
			len = (b - a).Magnitude,
			frac = edge and (0.3 + rng:NextNumber() * 0.35) or 1,
			base = edge and 0.8 or 0.55,
			edge = edge,
		})
	end
	local n = math.floor(R / STEP) + 1
	for li, y in ipairs(LEVELS) do
		for i = -n, n do
			for k = -n, n do
				local x, z = i * STEP, k * STEP
				if inside(x, y, z) then
					local here = Vector3.new(x, y, z)
					local nb: { { Vector3 | string } } = {
						{ Vector3.new(x + STEP, y, z), "x" },
						{ Vector3.new(x - STEP, y, z), "x" },
						{ Vector3.new(x, y, z + STEP), "z" },
						{ Vector3.new(x, y, z - STEP), "z" },
					}
					if LEVELS[li + 1] then
						table.insert(nb, { Vector3.new(x, LEVELS[li + 1], z), "y" })
					else
						table.insert(nb, { Vector3.new(x, y + (LEVELS[2] - LEVELS[1]), z), "y" })
					end
					if LEVELS[li - 1] then
						table.insert(nb, { Vector3.new(x, LEVELS[li - 1], z), "y" })
					end
					for _, e in ipairs(nb) do
						local o = e[1] :: Vector3
						local axis = e[2] :: string
						local oIn = (o.Y <= LEVELS[#LEVELS]) and inside(o.X, o.Y, o.Z)
						if not oIn then
							-- 둘레: 반쯤 뻗다가 허공에서 끊긴다 (아래로는 땅에 박히니 뻗지 않는다)
							if o.Y >= y then
								addSeg(here, o, axis, true)
							end
						elseif (o - here):Dot(Vector3.new(1, 1, 1)) > 0 and rng:NextNumber() > 0.22 then
							-- 안쪽 선 (한 쌍에 한 번만, 다섯에 하나쯤은 빠져 있다). 가운데에 가까운 마디에서 자란다
							local d0 = here.X * here.X + here.Z * here.Z + here.Y * here.Y
							local d1 = o.X * o.X + o.Z * o.Z + o.Y * o.Y
							if d0 <= d1 then
								addSeg(here, o, axis, false)
							else
								addSeg(o, here, axis, false)
							end
						end
					end
				end
			end
		end
	end
	local maxD = 0
	for _, S in ipairs(segs) do
		maxD = math.max(maxD, S.d + S.len)
	end
	-- 씨앗: 한가운데 흰 테의 검은 상자
	local seedAt = at + Vector3.new(0, 4, 0)
	local seed = cage(Vector3.one * 2.4, WHITE, 0.16, holder)
	placeCage(seed, CFrame.new(seedAt), 1)
	local core = part(Vector3.one * 2, BLACK, Enum.Material.SmoothPlastic, 0)
	core.Parent = holder
	core.CFrame = CFrame.new(seedAt)
	-- 떠다니는 빈칸 상자
	type Drifter = { list: { BasePart }, rel: { CFrame }, base: Vector3, ph: number }
	local drifters: { Drifter } = {}
	local function place(S: Seg, reach: number, alphaMul: number)
		local grow = math.clamp((reach - S.d) / S.len, 0, 1) * S.frac
		local p = S.p
		if grow <= 0.01 then
			p.Transparency = 1
			return
		end
		local L = S.len * grow
		local w = S.edge and 0.1 or 0.13
		if S.axis == "x" then
			p.Size = Vector3.new(L, w, w)
		elseif S.axis == "z" then
			p.Size = Vector3.new(w, w, L)
		else
			p.Size = Vector3.new(w, L, w)
		end
		p.CFrame = CFrame.new(at + S.a + (S.b - S.a).Unit * (L / 2))
		local alpha = 1 - (1 - S.base) * alphaMul
		if grow < S.frac - 0.01 then
			-- 자라는 중인 선 끝은 밝다
			alpha = math.min(alpha, 0.2)
		end
		p.Transparency = alpha
	end
	-- 내 화면: 격자 안에 들어오면 빛깔이 조금 빠진다 (어지럽지 않게 약하게)
	local cc: ColorCorrectionEffect? = nil
	local inside_ = false
	local function gradeFor(reachFrac: number)
		local r = rootOf(player and player.Character)
		local now = false
		if r then
			local d = r.Position - at
			now = Vector3.new(d.X, 0, d.Z).Magnitude <= R * 0.85 * reachFrac and d.Y > -8 and d.Y <= TOP * reachFrac + 6
		end
		if now ~= inside_ then
			inside_ = now
			if now then
				cc = gradeTo(cc, 0.8, { Saturation = -0.5, Contrast = 0.1, Brightness = 0.02, TintColor = Color3.fromRGB(240, 240, 255) })
			elseif cc then
				tween(cc, 0.8, { Saturation = 0, Contrast = 0, Brightness = 0, TintColor = Color3.new(1, 1, 1) })
			end
		end
	end
	-- 1) 컷 동안: 씨앗이 맥박치고 화면이 살짝 지직거린다
	glitchNear(at, 120, cut * 0.6, 0.5)
	Fx.sound("deflect", 0.8, 0.4, at)
	shakeNear(at, 1, 200)
	local t0 = os.clock()
	local tStart = t0 + cut
	local tEnd = tStart + dur
	local nextGlitch = 0
	local nextGrade = 0
	local nextWave = 0
	local collapsing = false
	local collapseFrom = 0
	local finished = false
	local conn: RBXScriptConnection? = nil
	local function finish()
		if finished then
			return
		end
		finished = true
		if conn then
			conn:Disconnect()
		end
		if domains[key] == finish then
			domains[key] = nil
		end
		if owner and domainState[owner] and domainState[owner].finish == finish then
			domainState[owner] = nil
		end
		gradeEnd(cc, 0.6)
		holder:Destroy()
	end
	domains[key] = finish
	local myState = { at = at, R = R, TOP = TOP, STEP = STEP, segs = segs, hijack = false, finish = finish }
	if owner then
		domainState[owner] = myState
	end
	local function step()
		-- 격자 공간 기술이 격자를 쥐고 있으면 그동안은 손대지 않는다
		if myState.hijack then
			return
		end
		local now = os.clock()
		local t = now - t0
		if now < tStart then
			local pulse = 1 + 0.25 * math.sin(t * 14)
			local cf = CFrame.new(seedAt) * CFrame.Angles(t * 2, t * 3, 0)
			placeCage(seed, cf, pulse)
			core.CFrame = cf
			return
		end
		-- 쓴 사람이 쓰러지거나 사라지면 바로 접힌다
		if not collapsing and now > tStart + 1.5 and now < tEnd then
			if owner and (not owner.Parent or owner:GetAttribute("Twilight") ~= true) then
				tEnd = now
			end
		end
		local u = math.clamp((now - tStart) / unfold, 0, 1)
		local s = 1 - (1 - u) ^ 3
		local alphaMul = 1
		if now >= tEnd then
			-- 3) 접힘: 1초 동안 가운데로
			if not collapsing then
				collapsing = true
				collapseFrom = s
				Fx.sound("shatter", 0.9, 0.6, at)
			end
			local k = math.clamp((now - tEnd) / 1.0, 0, 1)
			s = collapseFrom * (1 - k) ^ 2
			alphaMul = 1 - k * 0.4
			if k >= 1 then
				pixels(seedAt, 40, 1.6, 30)
				Fx.flash(seedAt, WHITE, 90, 8, 0.6)
				Fx.ring(at + Vector3.new(0, 0.5, 0), WHITE, 4, math.min(R * 2, 160), 0.6)
				shakeNear(at, 2, 200)
				finish()
				return
			end
		end
		local reach = maxD * s
		-- 씨앗은 펼쳐질수록 작아져 사라진다
		local cf = CFrame.new(seedAt) * CFrame.Angles(t * 2, t * 3, 0)
		placeCage(seed, cf, math.max(0.02, 1 - s))
		core.Size = Vector3.one * math.max(0.05, 2 * (1 - s))
		core.CFrame = cf
		-- 펼쳐지는 동안·접히는 동안에만 선을 다시 놓는다 (머무는 동안은 빛깔만)
		local settled = u >= 1 and not collapsing
		if not settled then
			for _, S in ipairs(segs) do
				place(S, reach, alphaMul)
			end
		else
			-- 2) 머무는 동안: 빛의 물결이 천천히 바깥으로 흐른다 (약하게)
			if now >= nextWave then
				nextWave = now + 0.05
				local wave = (t * 22) % (maxD * 1.3)
				for _, S in ipairs(segs) do
					local w = math.clamp(1 - math.abs(S.d - wave) / 10, 0, 1)
					S.p.Transparency = S.base - (S.base - 0.25) * w
				end
			end
			-- 가끔 끊긴 선 끝 하나가 붉게 지직거린다
			if now >= nextGlitch then
				nextGlitch = now + 0.6 + math.random() * 0.8
				local S = segs[math.random(1, #segs)]
				if S then
					S.p.Color = RED
					local tip = at + S.a + (S.b - S.a) * S.frac
					if S.edge and near(tip, 160) then
						pixels(tip, 3, 0.6, 3)
					end
					task.delay(0.15, function()
						if S.p.Parent then
							S.p.Color = WHITE
						end
					end)
				end
			end
			if #drifters == 0 then
				for k = 1, 6 do
					local a, rr = rng:NextNumber() * math.pi * 2, rng:NextNumber() * R * 0.6
					local base = at + Vector3.new(math.cos(a) * rr, 10 + rng:NextNumber() * TOP * 0.55, math.sin(a) * rr)
					local sz = 2 + rng:NextNumber() * 3
					local list = boxEdges(CFrame.new(base), Vector3.one * sz, k % 3 == 0 and RED or WHITE, 0.12)
					local rel: { CFrame } = {}
					for i, q in ipairs(list) do
						q.Parent = holder
						q.Transparency = 0.35
						rel[i] = CFrame.new(base):ToObjectSpace(q.CFrame)
					end
					table.insert(drifters, { list = list, rel = rel, base = base, ph = rng:NextNumber() * 6 })
				end
			end
			for _, d in ipairs(drifters) do
				local dcf = CFrame.new(d.base + Vector3.new(0, math.sin(t * 0.6 + d.ph) * 3, 0)) * CFrame.Angles(t * 0.4 + d.ph, t * 0.5, 0)
				for i, q in ipairs(d.list) do
					q.CFrame = dcf * d.rel[i]
				end
			end
		end
		if now >= nextGrade then
			nextGrade = now + 0.25
			gradeFor(s)
		end
	end
	conn = RunService.RenderStepped:Connect(function()
		local ok, err = pcall(step)
		if not ok then
			warn("[권왕] 격자 전개: " .. tostring(err))
			finish()
		end
	end)
	-- 늦어도 끝 시각 3초 뒤에는 반드시 지운다
	task.delay(cut + dur + 4, finish)
	-- 펼쳐지기 시작: 한 점에서 빛이 터진다
	task.delay(cut, function()
		if finished then
			return
		end
		Fx.sound("shatter", 0.7, 0.35, at)
		Fx.flash(seedAt, WHITE, 70, 6, 0.4)
		pixels(seedAt, 24, 1.2, 12)
		shakeNear(at, 1.4, 220)
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
