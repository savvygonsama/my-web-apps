-- 권왕 3.27판: 신 삼재권을 얻는 컷씬.
-- 팔을 몸 둘레로 여섯 번 휘두르고 (둘은 허리만 틀고, 넷은 몸째 돈다), 무릎을 높이 들었다가 발로 땅을 찍는다.
-- 찍는 순간 컷씬이 끝나고 바닥이 깨진다 (갈라지는 틈 · 솟았다 떨어지는 바닥 조각 · 가라앉은 자리).
-- 시간표는 Poses.sn_get과 같다 (전체 7.4초를 컷씬 길이에 맞춰 늘이고 줄인다)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Fx = require(script.Parent:WaitForChild("Fx"))
local Anim = require(script.Parent:WaitForChild("Anim"))
local Cutscene = require(script.Parent:WaitForChild("Cutscene"))

local Sin = {}

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "KwonSin"
folder.Parent = workspace

local opts: any = {}
function Sin.init(o: any)
	opts = o or {}
end

local SKY = Color3.fromRGB(150, 205, 255) -- 하늘
local EARTH = Color3.fromRGB(255, 190, 90) -- 땅
local HUMAN = Color3.fromRGB(255, 250, 235) -- 사람
local GOLD = Color3.fromRGB(255, 238, 170)
local TRIO = { SKY, EARTH, HUMAN }

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal):Play()
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
local function rootOf(m: any): BasePart?
	local r = typeof(m) == "Instance" and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function shake(a: number)
	if opts.shake then
		opts.shake(a)
	end
end

-- 발밑 땅의 높이·빛깔·재질 (바닥 조각을 같은 땅으로 만든다)
local function groundAt(pos: Vector3, skip: Instance?): (Vector3, Color3, Enum.Material)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ex: { Instance } = { folder }
	if skip then
		table.insert(ex, skip)
	end
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			table.insert(ex, pl.Character)
		end
	end
	local en = workspace:FindFirstChild("Enemies")
	if en then
		table.insert(ex, en)
	end
	params.FilterDescendantsInstances = ex
	local r = workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -30, 0), params)
	if r then
		local inst = r.Instance
		local col = Color3.fromRGB(120, 105, 85)
		if inst:IsA("BasePart") and not inst:IsA("Terrain") then
			col = inst.Color
		end
		local mat = r.Material
		if mat == Enum.Material.Air or mat == Enum.Material.Water then
			mat = Enum.Material.Slate
		end
		return r.Position, col, mat
	end
	return pos - Vector3.new(0, 3, 0), Color3.fromRGB(120, 105, 85), Enum.Material.Slate
end

------------------------------------------------------------------------
-- 휘두름 하나: 팔 높이에서 퍼지는 고리 + 바람 + 소리
------------------------------------------------------------------------
local function swing(m: Model, k: number, color: Color3, big: boolean)
	local r = rootOf(m)
	if not r then
		return
	end
	local c = r.Position
	local R = big and 34 or 24
	Fx.ring(c + Vector3.new(0, 0.5 + (k % 3) * 0.9, 0), color, 3, R, 0.45)
	Fx.ring(c + Vector3.new(0, -0.5, 0), HUMAN, 3, R * 0.8, 0.4)
	Fx.burst("spark", c, color, 8 + k * 2, 1.2 + k * 0.1)
	-- 팔이 베고 간 초승달 (몸 둘레를 도는 얇은 빛)
	local arc = part(Vector3.new(0.3, 5, 5), color, Enum.Material.Neon, 0.35, "cyl")
	arc.CFrame = CFrame.new(c) * CFrame.Angles(0, 0, math.rad(90))
	tween(arc, 0.35, { Size = Vector3.new(0.3, R * 0.8, R * 0.8), Transparency = 1 })
	task.delay(0.4, function()
		arc:Destroy()
	end)
	Fx.breakSound("whoosh", 0.7 + k * 0.05, 0.7 + k * 0.12, c)
	shake(0.25 + k * 0.08)
end

------------------------------------------------------------------------
-- 땅이 깨진다
------------------------------------------------------------------------
local function breakGround(m: Model, at: Vector3)
	local g0 = groundAt(at, m)
	local g = Vector3.new(at.X, g0.Y, at.Z)
	-- 충격: 하얗게 번쩍, 고리 세 겹, 빛기둥
	Fx.flash(g + Vector3.new(0, 4, 0), HUMAN, 90, 4, 0.7)
	Fx.ring(g + Vector3.new(0, 0.3, 0), HUMAN, 4, 80, 0.7)
	task.delay(0.08, function()
		Fx.ring(g + Vector3.new(0, 0.3, 0), GOLD, 4, 62, 0.8)
	end)
	task.delay(0.18, function()
		Fx.ring(g + Vector3.new(0, 0.3, 0), EARTH, 4, 44, 0.9)
	end)
	Fx.breakSound("boom", 1, 0.45, g)
	Fx.sound("deflect", 1, 0.4, g)
	shake(2.6)
	local col = part(Vector3.new(160, 5, 5), HUMAN, Enum.Material.Neon, 0.15, "cyl")
	col.CFrame = CFrame.new(g + Vector3.new(0, 78, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(col, 0.7, { Size = Vector3.new(160, 1, 1) })
	fadeOut(col, 0.8)
	local halo = part(Vector3.new(160, 14, 14), GOLD, Enum.Material.Neon, 0.55, "cyl")
	halo.CFrame = col.CFrame
	fadeOut(halo, 1.0, { Size = Vector3.new(160, 26, 26) })
	Fx.burst("dust", g + Vector3.new(0, 1, 0), Color3.fromRGB(175, 160, 140), 40, 2.6)
	Fx.burst("spark", g + Vector3.new(0, 1, 0), GOLD, 40, 2.4)
	Fx.debris(g, 20, 34)

	-- 가라앉은 자리: 어두운 원판과 금빛 테
	local pit = part(Vector3.new(0.3, 4, 4), Color3.fromRGB(14, 12, 10), Enum.Material.Slate, 0, "cyl")
	pit.CFrame = CFrame.new(g + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(pit, 0.35, { Size = Vector3.new(0.3, 24, 24) })
	task.delay(9, function()
		fadeOut(pit, 2)
	end)
	local rim = part(Vector3.new(0.35, 4, 4), GOLD, Enum.Material.Neon, 0.3, "cyl")
	rim.CFrame = CFrame.new(g + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(rim, 0.35, { Size = Vector3.new(0.35, 26, 26) })
	task.delay(0.4, function()
		tween(rim, 0.01, { Size = Vector3.new(0.35, 26, 26) })
		local hole = part(Vector3.new(0.5, 23, 23), Color3.fromRGB(8, 7, 6), Enum.Material.Slate, 0, "cyl")
		hole.CFrame = CFrame.new(g + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		task.delay(8.6, function()
			fadeOut(hole, 2)
		end)
	end)
	task.delay(5, function()
		fadeOut(rim, 4)
	end)

	-- 갈라지는 틈: 가운데에서 바깥으로 뻗는다. 어두운 틈 위에 금빛이 번득인다
	local n = 16
	for k = 1, n do
		local a = k / n * math.pi * 2 + math.random() * 0.25
		local len = 22 + math.random() * 26
		task.delay(math.random() * 0.12, function()
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local mid = g + dir * (len * 0.5 + 6) + Vector3.new(0, 0.15, 0)
			local crack = part(Vector3.new(2.2, 0.12, 0.1), Color3.fromRGB(10, 9, 8), Enum.Material.Slate, 0)
			crack.CFrame = CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, math.rad(90), 0)
			tween(crack, 0.45, { Size = Vector3.new(len, 0.12, 2.0 + math.random() * 1.4) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local glow = part(Vector3.new(2.2, 0.16, 0.1), GOLD, Enum.Material.Neon, 0.1)
			glow.CFrame = crack.CFrame + Vector3.new(0, 0.05, 0)
			tween(glow, 0.45, { Size = Vector3.new(len, 0.16, 0.55) })
			task.delay(0.5, function()
				tween(glow, 3.5, { Transparency = 1 })
			end)
			task.delay(4, function()
				glow:Destroy()
			end)
			task.delay(8 + math.random() * 1.5, function()
				fadeOut(crack, 2)
			end)
			-- 틈이 갈라진 자리에서 돌이 튄다
			if k % 2 == 0 then
				Fx.debris(g + dir * (len * 0.6), 4, 14)
			end
		end)
	end

	-- 바닥 조각: 같은 땅의 판이 솟구쳤다가 기울어져 떨어진다
	for k = 1, 30 do
		local a = math.random() * math.pi * 2
		local d = 7 + math.random() * 24
		local p0 = g + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		local gp, gc, gm = groundAt(p0, m)
		local sz = Vector3.new(2.5 + math.random() * 4.5, 1 + math.random() * 1.2, 2.5 + math.random() * 4.5)
		local slab = Instance.new("Part")
		slab.Anchored = true
		slab.CanCollide = false
		slab.CanQuery = false
		slab.CanTouch = false
		slab.CastShadow = true
		slab.Size = sz
		slab.Color = gc
		slab.Material = gm
		slab.Parent = folder
		local rest = CFrame.new(gp + Vector3.new(0, sz.Y * 0.2, 0)) * CFrame.Angles(math.rad((math.random() - 0.5) * 30), math.random() * math.pi * 2, math.rad((math.random() - 0.5) * 30))
		slab.CFrame = CFrame.new(gp) * (rest - rest.Position)
		local up = 4 + math.random() * 9 * (1 - d / 40)
		local spin = CFrame.Angles(math.rad((math.random() - 0.5) * 140), math.rad((math.random() - 0.5) * 140), math.rad((math.random() - 0.5) * 140))
		task.delay(d * 0.012, function()
			tween(slab, 0.4, { CFrame = CFrame.new(gp + Vector3.new(0, up, 0)) * spin * (rest - rest.Position) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			task.delay(0.42, function()
				tween(slab, 0.5, { CFrame = rest }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end)
			task.delay(0.95, function()
				Fx.burst("dust", gp, Color3.fromRGB(175, 160, 140), 3, 0.9)
				if k % 4 == 0 then
					Fx.breakSound("boom", 0.35, 1.3, gp)
				end
			end)
			task.delay(7 + math.random() * 2, function()
				tween(slab, 2, { CFrame = rest - Vector3.new(0, sz.Y * 1.5, 0) })
				task.delay(2.05, function()
					slab:Destroy()
				end)
			end)
		end)
	end
end

------------------------------------------------------------------------
-- 컷씬 본체
------------------------------------------------------------------------
local LINES: { { number | string } } = {
	{ 1.0, "하늘을 받치고" },
	{ 2.8, "땅을 딛고" },
	{ 4.3, "사람이 휘두른다" },
	{ 5.3, "천지가 하나로" },
}

function Sin.rite(d: any)
	local m0: Model? = d.m
	local r = rootOf(m0)
	if not m0 or not r then
		return
	end
	local m = m0 :: Model
	local mine = (m == player.Character)
	local at: Vector3 = d.at or r.Position
	local total: number = d.total or 8.6
	local stomp: number = d.stomp or 6.1
	local cam = workspace.CurrentCamera :: Camera
	local dist = cam and (cam.CFrame.Position - at).Magnitude or 1e9
	if not mine and dist > 220 then
		return
	end
	local t0 = os.clock()
	-- 동작은 모두에게 (Poses.sn_get은 7.4초 길이의 동작이라 컷씬 길이에 맞춰 편다)
	Anim.play(m, "sn_get", stomp * (7.4 / 6.1), {})

	-- 모으기: 하늘 · 땅 · 사람, 세 빛깔의 고리가 몸으로 모여든다
	if opts.tint and mine then
		opts.tint(Color3.fromRGB(235, 225, 205), 0.3, stomp)
	end
	for i = 0, 2 do
		task.delay(i * 0.28, function()
			local rr = rootOf(m)
			if rr then
				Fx.ring(rr.Position - Vector3.new(0, 2.5, 0) + Vector3.new(0, i * 1.4, 0), TRIO[i + 1], 40, 3, 0.8)
				Fx.sound("ping", 0.7, 0.6 + i * 0.2, rr.Position)
			end
		end)
	end
	-- 휘두름 여섯: 앞의 둘은 허리만 틀고, 뒤의 넷은 몸째 돈다 (점점 커지고 빨라진다)
	local sw = { 1.05, 1.4, 1.75, 2.1, 2.8, 3.35, 3.85, 4.3, 4.7 }
	for i, sec in ipairs(sw) do
		task.delay(sec, function()
			swing(m, i, TRIO[(i - 1) % 3 + 1], i > 4)
		end)
	end
	-- 몸으로 빨려 드는 빛 가루 (갈수록 많이)
	local conn0: RBXScriptConnection
	conn0 = RunService.Heartbeat:Connect(function()
		local e = os.clock() - t0
		local rr = rootOf(m)
		if e > stomp or not rr then
			conn0:Disconnect()
			return
		end
		if e > 0.4 and math.random() < 0.25 + e * 0.07 then
			local a = math.random() * math.pi * 2
			local far = 12 + math.random() * 8
			local from = rr.Position + Vector3.new(math.cos(a) * far, math.random() * 10 - 4, math.sin(a) * far)
			local mote = part(Vector3.new(0.5, 0.5, 0.5), TRIO[math.random(1, 3)], Enum.Material.Neon, 0.1, "ball")
			mote.Position = from
			tween(mote, 0.45, { Position = rr.Position, Size = Vector3.new(0.1, 0.1, 0.1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.47, function()
				mote:Destroy()
			end)
		end
	end)
	-- 무릎을 들어 올릴 때 땅 위로 기운이 솟는다
	task.delay(5.3, function()
		local rr = rootOf(m)
		if not rr then
			return
		end
		Fx.sound("whoosh", 1, 0.4, rr.Position)
		for i = 0, 5 do
			task.delay(i * 0.13, function()
				local r2 = rootOf(m)
				if r2 then
					Fx.ring(r2.Position - Vector3.new(0, 2.5, 0), GOLD, 26, 4, 0.5)
				end
			end)
		end
		shake(0.5)
	end)
	-- 땅을 찍는다
	task.delay(stomp, function()
		local rr = rootOf(m)
		local pos = rr and rr.Position - Vector3.new(0, 2.8, 0) or at
		breakGround(m, pos)
	end)

	if not mine then
		return
	end

	----------------------------------------------------------------
	-- 내 화면: 카메라 · 검은 띠 · 글귀 (찍는 순간 컷씬이 끝난다)
	----------------------------------------------------------------
	Cutscene.active = true
	local pg = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "KwonSinRite"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 70
	gui.Parent = pg
	local function bar(top: boolean): Frame
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0, top and 0 or 1)
		f.Position = UDim2.fromScale(0, top and 0 or 1)
		f.Size = UDim2.fromScale(1, 0)
		f.Parent = gui
		return f
	end
	local top, bottom = bar(true), bar(false)
	tween(top, 0.5, { Size = UDim2.fromScale(1, 0.12) })
	tween(bottom, 0.5, { Size = UDim2.fromScale(1, 0.12) })
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.AnchorPoint = Vector2.new(0.5, 1)
	text.Position = UDim2.fromScale(0.5, 0.88)
	text.Size = UDim2.fromScale(0.8, 0.07)
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.TextColor3 = GOLD
	text.TextStrokeTransparency = 0.3
	text.TextTransparency = 1
	text.Text = ""
	text.Parent = gui
	for _, ln in ipairs(LINES) do
		task.delay(ln[1] :: number, function()
			text.Text = ln[2] :: string
			text.TextTransparency = 0.6
			tween(text, 0.25, { TextTransparency = 0 })
			task.delay(1.1, function()
				tween(text, 0.4, { TextTransparency = 1 })
			end)
		end)
	end

	local oldType = cam.CameraType
	local oldFov = cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable
	local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
	local a0 = math.atan2(look.Z, look.X)
	local ang = 0
	local last = os.clock()
	local done = false
	local conn: RBXScriptConnection
	local function finish()
		if done then
			return
		end
		done = true
		conn:Disconnect()
		tween(top, 0.4, { Size = UDim2.fromScale(1, 0) })
		tween(bottom, 0.4, { Size = UDim2.fromScale(1, 0) })
		pcall(function()
			cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
			cam.FieldOfView = oldFov
		end)
		Cutscene.active = false
		task.delay(0.6, function()
			gui:Destroy()
		end)
	end
	conn = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local dt = math.min(0.1, now - last)
		last = now
		local e = now - t0
		local rr = rootOf(m)
		if not rr or e > stomp + 0.9 then
			finish()
			return
		end
		-- 도는 빠르기: 허리만 틀 때는 느리게, 몸째 돌 때 점점 빨라진다
		local spd = 0.12
		if e > 1 then
			spd = 0.35
		end
		if e > 2.4 then
			spd = 0.35 + (e - 2.4) * 0.5
		end
		if e > 5.1 then
			spd = 0.15
		end
		ang += dt * spd
		local dd, h, fh = 24, 5, 2
		if e < 1 then
			dd = 26 - e * 4
		elseif e < 5.1 then
			local u = (e - 1) / 4.1
			dd = 22 - u * 9
			h = 4 + u * 3
		elseif e < stomp then
			local u = (e - 5.1) / (stomp - 5.1)
			dd = 13 - u * 3
			h = 7 - u * 8.5 -- 아래로 내려가 올려다본다 (치켜든 무릎과 팔)
			fh = 3 + u * 2
		else
			local u = math.min(1, (e - stomp) / 0.4)
			dd = 10 + u * 14
			h = -1.5 + u * 9
			fh = 5 - u * 3
		end
		local focus = rr.Position + Vector3.new(0, fh, 0)
		local a = a0 + math.pi + ang
		local eye = focus + Vector3.new(math.cos(a) * dd, h, math.sin(a) * dd)
		cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(eye, focus), 0.25)
	end)
	task.delay(stomp, function()
		if done then
			return
		end
		pcall(function()
			cam.FieldOfView = oldFov + 14
			tween(cam, 0.6, { FieldOfView = oldFov })
		end)
		if opts.flash then
			opts.flash(Color3.new(1, 1, 1), 0.7)
		end
	end)
	-- 안전망
	task.delay(total + 2, finish)
end

return Sin
