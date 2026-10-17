-- 권왕: 타격감 (불꽃, 충격파, 잔상, 숫자, 권법마다 다른 빛)
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Poses = require(ReplicatedStorage:WaitForChild("Poses"))

local Fx = {}

local folder = Instance.new("Folder")
folder.Name = "KwonFx"
folder.Parent = workspace

------------------------------------------------------------------------
-- 소리 (로블록스에 들어 있는 기본 소리. 더 좋은 소리 번호가 있으면 여기만 바꾸면 된다)
------------------------------------------------------------------------
local SOUNDS = {
	swing = "rbxasset://sounds/swordlunge.wav",
	hit = "rbxasset://sounds/action_jump_land.mp3",
	heavy = "rbxasset://sounds/action_jump_land.mp3",
	block = "rbxasset://sounds/swordslash.wav",
	deflect = "rbxasset://sounds/unsheath.wav",
	ping = "rbxasset://sounds/electronicpingshort.wav",
	fall = "rbxasset://sounds/action_falling.mp3",
	jump = "rbxasset://sounds/action_jump.mp3",
	splash = "rbxasset://sounds/impact_water.mp3",
}

function Fx.sound(name: string, volume: number?, pitch: number?, at: Vector3?)
	local id = SOUNDS[name]
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.5
	s.PlaybackSpeed = pitch or 1
	if at then
		local a = Instance.new("Part")
		a.Anchored = true
		a.CanCollide = false
		a.CanQuery = false
		a.Transparency = 1
		a.Size = Vector3.new(0.2, 0.2, 0.2)
		a.Position = at
		a.Parent = folder
		s.RollOffMaxDistance = 160
		s.Parent = a
		Debris:AddItem(a, 3)
	else
		s.Parent = SoundService
		Debris:AddItem(s, 3)
	end
	s:Play()
end

------------------------------------------------------------------------
-- 기본 조각
------------------------------------------------------------------------
local function piece(size: Vector3, color: Color3, material: Enum.Material?, shape: Enum.PartType?, transparency: number?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Neon
	if shape then
		p.Shape = shape
	end
	p.Transparency = transparency or 0
	p.Parent = folder
	return p
end

-- 두 점이 같으면 방향을 정할 수 없어서 (NaN) 그냥 그 자리에 둔다
local function lookAt(from: Vector3, to: Vector3): CFrame
	if (to - from).Magnitude < 1e-3 then
		return CFrame.new(from)
	end
	return CFrame.lookAt(from, to)
end

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end

-- 터지는 빛 조각
function Fx.spark(pos: Vector3, color: Color3, size: number, count: number)
	local flash = piece(Vector3.new(1, 1, 1) * size, Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball, 0)
	flash.Position = pos
	tween(flash, 0.12, { Size = Vector3.new(1, 1, 1) * size * 2.4, Transparency = 1 })
	Debris:AddItem(flash, 0.15)
	for _ = 1, count do
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 - 0.2, math.random() - 0.5)
		if dir.Magnitude < 0.05 then
			dir = Vector3.new(0, 1, 0)
		end
		dir = dir.Unit
		local len = size * (0.6 + math.random() * 0.8)
		local shard = piece(Vector3.new(0.15 * size, 0.15 * size, len), color, Enum.Material.Neon)
		shard.CFrame = CFrame.lookAt(pos, pos + dir)
		local to = pos + dir * size * (2 + math.random() * 2.5)
		tween(shard, 0.22, { CFrame = CFrame.lookAt(to, to + dir), Size = Vector3.new(0.05, 0.05, len * 0.3), Transparency = 1 })
		Debris:AddItem(shard, 0.25)
	end
end

-- 바닥에 퍼지는 충격파 고리 (vertical이면 세워서)
function Fx.ring(pos: Vector3, color: Color3, fromD: number, toD: number, life: number, faceDir: Vector3?)
	local p = piece(Vector3.new(0.2, fromD, fromD), color, Enum.Material.Neon, Enum.PartType.Cylinder, 0.15)
	if faceDir then
		p.CFrame = lookAt(pos, pos + faceDir) * CFrame.Angles(0, math.rad(90), 0)
	else
		p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	end
	tween(p, life, { Size = Vector3.new(0.05, toD, toD), Transparency = 1 })
	Debris:AddItem(p, life + 0.05)
end

-- 떠오르는 글자 (피해 숫자, '흘리기!' 같은 말)
function Fx.text(pos: Vector3, text: string, color: Color3, size: number, rise: number?)
	local anchor = piece(Vector3.new(0.2, 0.2, 0.2), color, Enum.Material.Neon, nil, 1)
	anchor.Position = pos
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 300, 0, 70)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 300
	bb.Parent = anchor
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextSize = size
	l.TextColor3 = color
	l.TextStrokeTransparency = 0
	l.TextStrokeColor3 = Color3.fromRGB(20, 10, 10)
	l.Text = text
	l.Parent = bb
	local sc = Instance.new("UIScale")
	sc.Scale = 1.8
	sc.Parent = l
	tween(sc, 0.14, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(anchor, 0.8, { Position = pos + Vector3.new(math.random() * 2 - 1, rise or 3.5, 0) })
	task.delay(0.45, function()
		tween(l, 0.35, { TextTransparency = 1, TextStrokeTransparency = 1 })
	end)
	Debris:AddItem(anchor, 0.85)
end

-- 흙먼지
function Fx.dust(pos: Vector3, size: number)
	for _ = 1, 5 do
		local p = piece(Vector3.new(1, 1, 1) * size * (0.6 + math.random() * 0.6), Color3.fromRGB(190, 170, 140), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.4)
		p.Position = pos + Vector3.new(math.random() * 2 - 1, 0, math.random() * 2 - 1) * size
		tween(p, 0.6, { Size = p.Size * 2.2, Position = p.Position + Vector3.new(0, size, 0), Transparency = 1 })
		Debris:AddItem(p, 0.65)
	end
end

-- 번개 (지그재그 빛줄기)
function Fx.lightning(from: Vector3, to: Vector3, color: Color3?, width: number?)
	local col = color or Color3.fromRGB(255, 245, 140)
	local w = width or 0.35
	local n = 7
	local prev = from
	for i = 1, n do
		local k = i / n
		local p = from:Lerp(to, k)
		if i < n then
			p += Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * (to - from).Magnitude * 0.12
		end
		local len = (p - prev).Magnitude
		if len > 0.05 then
			local seg = piece(Vector3.new(w, w, len), col, Enum.Material.Neon)
			seg.CFrame = lookAt((prev + p) / 2, p)
			tween(seg, 0.25, { Transparency = 1, Size = Vector3.new(w * 0.2, w * 0.2, len) })
			Debris:AddItem(seg, 0.3)
		end
		prev = p
	end
end

-- 잔상: 몸을 반투명한 그림자로 남긴다
function Fx.afterimage(model: Model, color: Color3, life: number?)
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.9 then
			local p = piece(d.Size, color, Enum.Material.Neon, nil, 0.45)
			p.CFrame = d.CFrame
			tween(p, life or 0.35, { Transparency = 1 })
			Debris:AddItem(p, (life or 0.35) + 0.05)
		end
	end
end

------------------------------------------------------------------------
-- 손발 잔상 (기술 쓰는 동안)
------------------------------------------------------------------------
local function trailOn(part: BasePart, color: Color3, color2: Color3, life: number)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.7, 0)
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.8, 0)
	a1.Parent = part
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = 0.28
	tr.LightEmission = 1
	tr.FaceCamera = true
	tr.Color = ColorSequence.new(color2, color)
	tr.Transparency = NumberSequence.new(0, 1)
	tr.WidthScale = NumberSequence.new(1.2, 0.2)
	tr.Parent = part
	task.delay(life, function()
		tr.Enabled = false
		Debris:AddItem(tr, 0.3)
		Debris:AddItem(a0, 0.3)
		Debris:AddItem(a1, 0.3)
	end)
end

function Fx.limbTrails(model: Model, pose: string, dur: number, color: Color3, color2: Color3)
	-- 무기를 든 적은 무기 날에, 맨손이면 휘두르는 손발에
	local hasWeapon = false
	for _, w in ipairs(model:GetChildren()) do
		if w.Name == "Weapon" then
			local blade = w:FindFirstChild("Blade")
			if blade and blade:IsA("BasePart") then
				trailOn(blade, color, color2, dur)
				hasWeapon = true
			end
		end
	end
	if hasWeapon then
		return
	end
	for _, name in ipairs(Poses.limbs[pose] or {}) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			trailOn(part, color, color2, dur)
		end
	end
end

------------------------------------------------------------------------
-- 권법마다 다른 빛 (맞힌 자리에)
------------------------------------------------------------------------
local function styleOf(id: any): any
	return type(id) == "string" and Config.STYLE_BY_ID[id] or nil
end

function Fx.styleHit(styleId: any, pos: Vector3, heavy: boolean, dir: Vector3?)
	local style = styleOf(styleId)
	if not style then
		Fx.spark(pos, Color3.fromRGB(255, 230, 200), heavy and 2 or 1.2, heavy and 10 or 6)
		return
	end
	local s = heavy and 1.6 or 1
	local c, c2 = style.color, style.color2
	Fx.spark(pos, c, 1.3 * s, heavy and 12 or 7)
	if style.fx == "water" then
		-- 물방울과 물결
		Fx.ring(pos, c2, 1, 9 * s, 0.35, dir)
		for _ = 1, 6 do
			local drop = piece(Vector3.new(0.5, 0.5, 0.5), c2, Enum.Material.Glass, Enum.PartType.Ball, 0.2)
			drop.Position = pos
			local to = pos + Vector3.new(math.random() * 6 - 3, math.random() * 4, math.random() * 6 - 3) * s
			tween(drop, 0.4, { Position = to, Transparency = 1 })
			Debris:AddItem(drop, 0.45)
		end
	elseif style.fx == "gold" then
		-- 금빛 범종 소리 같은 둥근 빛
		local bell = piece(Vector3.new(1, 1, 1) * 3 * s, c, Enum.Material.Neon, Enum.PartType.Ball, 0.3)
		bell.Position = pos
		tween(bell, 0.3, { Size = Vector3.new(1, 1, 1) * 9 * s, Transparency = 1 })
		Debris:AddItem(bell, 0.35)
		Fx.ring(pos, c, 2, 14 * s, 0.4, dir)
	elseif style.fx == "petal" then
		for _ = 1, heavy and 14 or 8 do
			local petal = piece(Vector3.new(0.7, 0.08, 0.5), math.random() < 0.5 and c or c2, Enum.Material.SmoothPlastic)
			petal.CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
			local to = pos + Vector3.new(math.random() * 10 - 5, math.random() * 5 - 1, math.random() * 10 - 5) * s
			tween(petal, 0.9, { CFrame = CFrame.new(to) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6), Transparency = 1 })
			Debris:AddItem(petal, 0.95)
		end
	elseif style.fx == "dragon" then
		Fx.ring(pos, c, 1, 10 * s, 0.35, dir)
		Fx.ring(pos, c2, 1, 6 * s, 0.25, dir)
	elseif style.fx == "shadow" then
		for _ = 1, 6 do
			local smoke = piece(Vector3.new(1, 1, 1) * (1.5 + math.random()) * s, Color3.fromRGB(30, 15, 50), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.3)
			smoke.Position = pos + Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1)
			tween(smoke, 0.5, { Size = smoke.Size * 2.5, Transparency = 1 })
			Debris:AddItem(smoke, 0.55)
		end
		Fx.ring(pos, c, 1, 8 * s, 0.3, dir)
	elseif style.fx == "lightning" then
		for _ = 1, heavy and 4 or 2 do
			local off = Vector3.new(math.random() * 8 - 4, math.random() * 6, math.random() * 8 - 4) * s
			Fx.lightning(pos, pos + off, c, 0.3)
		end
	elseif style.fx == "drunk" then
		Fx.ring(pos, c, 1, 8 * s, 0.4, dir)
		if heavy then
			local fire = piece(Vector3.new(1, 1, 1) * 3, Color3.fromRGB(255, 120, 40), Enum.Material.Neon, Enum.PartType.Ball, 0.2)
			fire.Position = pos
			tween(fire, 0.35, { Size = Vector3.new(1, 1, 1) * 8, Transparency = 1 })
			Debris:AddItem(fire, 0.4)
		end
	end
end

------------------------------------------------------------------------
-- 장풍 (날아가는 기운)
------------------------------------------------------------------------
function Fx.projectile(data: any)
	local style = styleOf(data.style)
	local c = style and style.color or Color3.fromRGB(120, 255, 230)
	local c2 = style and style.color2 or Color3.new(1, 1, 1)
	local size = data.size or 3
	local ball = piece(Vector3.new(1, 1, 1) * size, c, Enum.Material.Neon, Enum.PartType.Ball, 0.15)
	local core = piece(Vector3.new(1, 1, 1) * size * 0.55, c2, Enum.Material.Neon, Enum.PartType.Ball, 0)
	ball.Position = data.pos
	core.Position = data.pos
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, size * 0.4, 0)
	a0.Parent = ball
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -size * 0.4, 0)
	a1.Parent = ball
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = 0.3
	tr.LightEmission = 1
	tr.Color = ColorSequence.new(c2, c)
	tr.Transparency = NumberSequence.new(0, 1)
	tr.Parent = ball
	-- 용 모양: 몸통이 따라오며 꿈틀댄다
	local tail = {}
	if style and style.fx == "dragon" then
		for i = 1, 6 do
			local seg = piece(Vector3.new(1, 1, 1) * size * (0.85 - i * 0.1), c:Lerp(c2, i / 8), Enum.Material.Neon, Enum.PartType.Ball, 0.25)
			seg.Position = data.pos
			table.insert(tail, seg)
		end
	end
	local start = os.clock()
	local dir: Vector3 = data.dir
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		local pos = data.pos + dir * data.speed * t
		ball.Position = pos
		core.Position = pos
		local side = Vector3.new(-dir.Z, 0, dir.X)
		for i, seg in ipairs(tail) do
			local back = math.max(0, t - i * 0.025)
			seg.Position = data.pos + dir * data.speed * back + side * math.sin(back * 18 + i) * size * 0.4
		end
		if t >= data.life then
			conn:Disconnect()
			Fx.spark(pos, c, size * 0.6, 6)
			for _, p in ipairs({ ball, core, table.unpack(tail) }) do
				tween(p, 0.15, { Transparency = 1 })
				Debris:AddItem(p, 0.2)
			end
		end
	end)
end

------------------------------------------------------------------------
-- 큰 연출
------------------------------------------------------------------------
-- 꽃잎 폭발 (매화 만개)
function Fx.bloom(pos: Vector3, radius: number)
	Fx.ring(pos, Color3.fromRGB(255, 150, 200), 2, radius * 2.2, 0.5)
	for _ = 1, 40 do
		local petal = piece(Vector3.new(1, 0.1, 0.7), Color3.fromRGB(255, 130 + math.random(0, 80), 190), Enum.Material.SmoothPlastic)
		petal.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		local a = math.random() * math.pi * 2
		local to = pos + Vector3.new(math.cos(a) * radius, math.random() * 8, math.sin(a) * radius)
		tween(petal, 1.1, { CFrame = CFrame.new(to) * CFrame.Angles(math.random() * 6, math.random() * 6, 0), Transparency = 1 })
		Debris:AddItem(petal, 1.15)
	end
end

-- 오의 연출 (권법마다)
function Fx.ult(styleId: string, model: Model, dur: number)
	local style = styleOf(styleId)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not style or not root or not root:IsA("BasePart") then
		return
	end
	local base = Vector3.new(root.Position.X, root.Position.Y - 2.5, root.Position.Z)
	local c, c2 = style.color, style.color2
	-- 발밑 빛 원
	local circle = piece(Vector3.new(0.3, 4, 4), c, Enum.Material.Neon, Enum.PartType.Cylinder, 0.3)
	circle.CFrame = CFrame.new(base + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(circle, 0.5, { Size = Vector3.new(0.3, 34, 34) })
	task.delay(dur - 0.3, function()
		tween(circle, 0.3, { Transparency = 1 })
	end)
	Debris:AddItem(circle, dur + 0.1)
	if style.fx == "water" or style.fx == "dragon" then
		-- 몸을 휘감고 솟는 용
		local segs = {}
		for i = 1, 14 do
			local seg = piece(Vector3.new(1, 1, 1) * (4 - i * 0.18), c:Lerp(c2, i / 14), Enum.Material.Neon, Enum.PartType.Ball, 0.2)
			seg.Position = base
			table.insert(segs, seg)
		end
		local start = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - start
			for i, seg in ipairs(segs) do
				local k = math.max(0, t - i * 0.04)
				local a = k * 7
				local r = 9 - math.min(6, k * 3)
				seg.Position = base + Vector3.new(math.cos(a) * r, k * 22, math.sin(a) * r)
			end
			if t > dur then
				conn:Disconnect()
				for _, seg in ipairs(segs) do
					tween(seg, 0.3, { Transparency = 1 })
					Debris:AddItem(seg, 0.35)
				end
			end
		end)
		if style.fx == "dragon" then
			-- 아홉 줄기 기둥
			for i = 0, 8 do
				task.delay(0.6 + i * 0.05, function()
					local a = i / 9 * math.pi * 2
					local p = base + Vector3.new(math.cos(a) * 14, 0, math.sin(a) * 14)
					local pillar = piece(Vector3.new(4, 0.5, 4), c, Enum.Material.Neon, nil, 0.2)
					pillar.Position = p
					tween(pillar, 0.25, { Size = Vector3.new(3, 60, 3), Position = p + Vector3.new(0, 30, 0) })
					task.delay(0.5, function()
						tween(pillar, 0.4, { Transparency = 1 })
					end)
					Debris:AddItem(pillar, 1)
				end)
			end
		end
	elseif style.fx == "gold" then
		-- 하늘에서 내려오는 금빛 손바닥
		local look = root.CFrame.LookVector
		local target = base + Vector3.new(look.X, 0, look.Z) * 6
		local palm = piece(Vector3.new(16, 2, 20), c, Enum.Material.Neon, nil, 0.25)
		palm.CFrame = CFrame.new(target + Vector3.new(0, 70, 0))
		local fingers = {}
		for i = -2, 2 do
			local fg = piece(Vector3.new(2.6, 1.8, 9), c2, Enum.Material.Neon, nil, 0.3)
			fg.CFrame = palm.CFrame * CFrame.new(i * 3.2, 0, -13)
			table.insert(fingers, fg)
		end
		task.delay(dur * 0.45, function()
			tween(palm, 0.2, { CFrame = CFrame.new(target + Vector3.new(0, 1, 0)) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			for i, fg in ipairs(fingers) do
				tween(fg, 0.2, { CFrame = CFrame.new(target + Vector3.new(0, 1, 0)) * CFrame.new((i - 3) * 3.2, 0, -13) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
			task.delay(0.25, function()
				Fx.ring(target, c, 4, 60, 0.6)
				Fx.dust(target, 6)
				tween(palm, 0.6, { Transparency = 1 })
				for _, fg in ipairs(fingers) do
					tween(fg, 0.6, { Transparency = 1 })
				end
			end)
		end)
		Debris:AddItem(palm, dur + 1)
		for _, fg in ipairs(fingers) do
			Debris:AddItem(fg, dur + 1)
		end
	elseif style.fx == "petal" or style.fx == "drunk" then
		for k = 0, 4 do
			task.delay(k * 0.3, function()
				if style.fx == "petal" then
					Fx.bloom(base + Vector3.new(0, 1, 0), 14)
				else
					Fx.ring(base + Vector3.new(0, 1, 0), c, 3, 26, 0.5)
				end
			end)
		end
	elseif style.fx == "shadow" then
		for k = 0, 5 do
			task.delay(0.25 + k * 0.25, function()
				local a = k / 6 * math.pi * 2
				local p = base + Vector3.new(math.cos(a) * 8, 3, math.sin(a) * 8)
				local ghost = piece(Vector3.new(2, 5, 1), Color3.fromRGB(40, 20, 70), Enum.Material.Neon, nil, 0.3)
				ghost.CFrame = lookAt(p, base + Vector3.new(0, 3, 0))
				tween(ghost, 0.2, { CFrame = lookAt(base + Vector3.new(0, 3, 0), p) })
				task.delay(0.2, function()
					tween(ghost, 0.2, { Transparency = 1 })
				end)
				Debris:AddItem(ghost, 0.5)
			end)
		end
	elseif style.fx == "lightning" then
		for k = 0, 9 do
			task.delay(0.5 + k * 0.12, function()
				local a = math.random() * math.pi * 2
				local p = base + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(3, 20)
				Fx.lightning(p + Vector3.new(0, 70, 0), p, c, 0.8)
				Fx.ring(p, c, 1, 10, 0.3)
			end)
		end
	end
end

------------------------------------------------------------------------
-- 기술 쓰는 순간의 연출 (Z 강타·E·R). 오의(G)는 Fx.ult
------------------------------------------------------------------------
local function rootPart(model: Model): BasePart?
	local r = model:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end

-- 몸을 따라다니는 조각들 (dur초 동안). place(t) 가 { [Part] = CFrame } 를 돌려준다
local function follow(model: Model, dur: number, parts: { Part }, place: (number, CFrame) -> { CFrame }, fade: number?)
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		local r = rootPart(model)
		if t > dur or not r or not model.Parent then
			conn:Disconnect()
			for _, p in ipairs(parts) do
				tween(p, fade or 0.25, { Transparency = 1 })
				Debris:AddItem(p, (fade or 0.25) + 0.05)
			end
			return
		end
		local cfs = place(t, r.CFrame)
		for i, p in ipairs(parts) do
			if cfs[i] then
				p.CFrame = cfs[i]
			end
		end
	end)
end

-- 몸에서 터지는 기운 (모든 기술 공통)
local function flare(pos: Vector3, color: Color3, size: number)
	local b = piece(Vector3.new(1, 1, 1) * size, color, Enum.Material.Neon, Enum.PartType.Ball, 0.35)
	b.Position = pos
	tween(b, 0.35, { Size = Vector3.new(1, 1, 1) * size * 2.6, Transparency = 1 })
	Debris:AddItem(b, 0.4)
	for _ = 1, 8 do
		local a = math.random() * math.pi * 2
		local shard = piece(Vector3.new(0.3, 2.4, 0.3), color, Enum.Material.Neon)
		local from = pos + Vector3.new(math.cos(a) * size * 0.6, -2, math.sin(a) * size * 0.6)
		shard.Position = from
		tween(shard, 0.5, { Position = from + Vector3.new(0, 6 + math.random() * 4, 0), Size = Vector3.new(0.1, 0.6, 0.1), Transparency = 1 })
		Debris:AddItem(shard, 0.55)
	end
end

-- 앞으로 뻗는 기운의 띠 (돌진 기술의 지나간 길)
local function streak(from: Vector3, to: Vector3, color: Color3, width: number, life: number)
	if (to - from).Magnitude < 0.5 then
		return
	end
	local p = piece(Vector3.new(width, width * 0.4, (to - from).Magnitude), color, Enum.Material.Neon, nil, 0.2)
	p.CFrame = lookAt((from + to) / 2, to)
	tween(p, life, { Size = Vector3.new(width * 0.1, width * 0.05, (to - from).Magnitude), Transparency = 1 })
	Debris:AddItem(p, life + 0.05)
end

-- 휘두를 때마다 앞에 터지는 바람 (빗나가도 보인다)
function Fx.swing(styleId: any, model: Model, heavy: boolean)
	local r = rootPart(model)
	if not r then
		return
	end
	local style = styleOf(styleId)
	local c = style and style.color or Color3.fromRGB(240, 240, 255)
	local look = r.CFrame.LookVector
	local pos = r.Position + look * 3.5 + Vector3.new(0, 0.6, 0)
	Fx.ring(pos, c, 1, heavy and 9 or 5, heavy and 0.28 or 0.18, look)
	local arc = piece(Vector3.new(heavy and 5 or 3.4, 0.15, 1.2), c, Enum.Material.Neon, nil, 0.25)
	arc.CFrame = lookAt(pos, pos + look) * CFrame.Angles(0, 0, math.random() * math.pi)
	tween(arc, 0.18, { Size = Vector3.new(heavy and 9 or 6, 0.05, 0.3), Transparency = 1 })
	Debris:AddItem(arc, 0.2)
end

function Fx.cast(styleId: any, slot: any, model: Model, dur: number)
	local style = styleOf(styleId)
	local r = rootPart(model)
	if not style or not r or slot == "G" or type(slot) == "number" then
		return
	end
	local c, c2 = style.color, style.color2
	local pos = r.Position
	local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
	local feet = pos - Vector3.new(0, 2.6, 0)
	-- 공통: 발밑 고리와 몸의 기운
	Fx.ring(feet + Vector3.new(0, 0.2, 0), c, 2, slot == "H" and 12 or 16, 0.45)
	flare(pos, c, slot == "H" and 2.5 or 3.5)
	Fx.sound("swing", 0.5, slot == "H" and 0.7 or 0.55)
	local fx = style.fx
	local key = fx .. ":" .. tostring(slot)

	if key == "water:H" then
		-- 앞으로 밀려가는 물결 벽
		task.delay(0.25, function()
			for k = 0, 2 do
				task.delay(k * 0.06, function()
					Fx.ring(pos + look * (4 + k * 3), c2, 2, 12 + k * 3, 0.35, look)
				end)
			end
		end)
	elseif key == "water:E" then
		-- 몸을 감싸고 도는 물의 띠 두 줄 (받아넘기기 자세)
		local parts = {}
		for i = 1, 10 do
			table.insert(parts, piece(Vector3.new(0.9, 0.9, 0.9), i % 2 == 0 and c or c2, Enum.Material.Neon, Enum.PartType.Ball, 0.2))
		end
		follow(model, dur + 0.3, parts, function(t, cf)
			local out = {}
			for i = 1, 10 do
				local a = t * 9 + i / 10 * math.pi * 2
				local y = (i % 2 == 0) and 0.8 or -0.8
				out[i] = cf * CFrame.new(math.cos(a) * 3.4, y + math.sin(a * 2) * 0.4, math.sin(a) * 3.4)
			end
			return out
		end)
	elseif key == "water:R" then
		-- 안으로 말려드는 소용돌이
		local parts = {}
		for i = 1, 16 do
			table.insert(parts, piece(Vector3.new(1.4, 1.4, 1.4), c:Lerp(c2, i / 16), Enum.Material.Neon, Enum.PartType.Ball, 0.25))
		end
		follow(model, dur, parts, function(t, cf)
			local out = {}
			for i = 1, 16 do
				local a = t * 8 + i / 16 * math.pi * 2
				local rad = math.max(2, 14 - t * 14) + (i % 3)
				out[i] = CFrame.new(cf.Position + Vector3.new(math.cos(a) * rad, -1.5 + (i % 4) * 0.8, math.sin(a) * rad))
			end
			return out
		end)
		for k = 0, 3 do
			task.delay(k * 0.2, function()
				Fx.ring(feet + Vector3.new(0, 0.3, 0), c2, 24, 4, 0.3)
			end)
		end
	elseif key == "gold:H" then
		-- 금빛 손바닥이 앞으로 날아간다
		task.delay(0.35, function()
			local palm = piece(Vector3.new(6, 7, 0.6), c, Enum.Material.Neon, nil, 0.2)
			local from = pos + look * 2
			palm.CFrame = lookAt(from, from + look)
			tween(palm, 0.3, { CFrame = lookAt(from + look * 12, from + look * 13), Size = Vector3.new(9, 10, 0.3), Transparency = 1 })
			Debris:AddItem(palm, 0.35)
			Fx.ring(from + look * 3, c2, 3, 16, 0.4, look)
		end)
	elseif key == "gold:E" then
		-- 금빛 갑옷: 발에서 머리로 오르는 고리 셋, 몸을 감싸는 금빛 껍질
		for k = 0, 2 do
			task.delay(k * 0.1, function()
				local ring = piece(Vector3.new(0.3, 6, 6), c, Enum.Material.Neon, Enum.PartType.Cylinder, 0.2)
				ring.CFrame = CFrame.new(feet) * CFrame.Angles(0, 0, math.rad(90))
				tween(ring, 0.4, { CFrame = CFrame.new(feet + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 1 })
				Debris:AddItem(ring, 0.45)
			end)
		end
		Fx.aura(model, c, 6)
	elseif key == "gold:R" then
		-- 사자후: 앞으로 퍼지는 소리 고리와 땅을 휩쓰는 큰 충격파
		for k = 0, 4 do
			task.delay(0.15 + k * 0.08, function()
				Fx.ring(pos + look * (3 + k * 3), c, 3, 10 + k * 4, 0.35, look)
			end)
		end
		task.delay(0.2, function()
			Fx.ring(feet + Vector3.new(0, 0.3, 0), c, 4, 44, 0.6)
			Fx.ring(feet + Vector3.new(0, 0.4, 0), c2, 2, 30, 0.5)
			Fx.dust(feet, 5)
		end)
	elseif key == "petal:H" or key == "petal:R" then
		-- 지나간 길에 남는 매화빛 칼금과 꽃잎
		local lunge = slot == "R" and 22 or 14
		task.delay(0.12, function()
			streak(pos, pos + look * lunge, c, 1.6, 0.5)
			streak(pos + Vector3.new(0, 1, 0), pos + look * lunge + Vector3.new(0, 1, 0), c2, 0.7, 0.4)
			for k = 0, 5 do
				local p = pos + look * (lunge * k / 5)
				for _ = 1, 3 do
					local petal = piece(Vector3.new(0.8, 0.08, 0.6), math.random() < 0.5 and c or c2, Enum.Material.SmoothPlastic)
					petal.CFrame = CFrame.new(p) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
					tween(petal, 1, { CFrame = CFrame.new(p + Vector3.new(math.random() * 4 - 2, -2, math.random() * 4 - 2)) * CFrame.Angles(math.random() * 6, 0, math.random() * 6), Transparency = 1 })
					Debris:AddItem(petal, 1.05)
				end
			end
		end)
		if slot == "R" then
			for k = 1, 3 do
				task.delay(k * 0.07, function()
					Fx.afterimage(model, c, 0.4)
				end)
			end
		end
	elseif key == "petal:E" then
		-- 여덟 번의 번쩍임
		for k = 0, 7 do
			task.delay(0.08 + k * dur / 9, function()
				local rr = rootPart(model)
				if rr then
					local side = Vector3.new(-look.Z, 0, look.X) * (math.random() * 3 - 1.5)
					Fx.spark(rr.Position + rr.CFrame.LookVector * 3.5 + side + Vector3.new(0, math.random() * 2 - 0.5, 0), k % 2 == 0 and c or c2, 0.9, 4)
				end
			end)
		end
	elseif key == "dragon:H" or key == "dragon:E" then
		-- 두 손 앞에 모이는 용의 기운
		local orb = piece(Vector3.new(1, 1, 1), c, Enum.Material.Neon, Enum.PartType.Ball, 0.1)
		orb.Position = pos + look * 2.5
		tween(orb, dur * 0.4, { Size = Vector3.new(4, 4, 4), Transparency = 0.3 })
		task.delay(dur * 0.42, function()
			tween(orb, 0.12, { Size = Vector3.new(7, 7, 7), Transparency = 1 })
			Fx.ring(pos + look * 3, c2, 2, 14, 0.35, look)
		end)
		Debris:AddItem(orb, dur * 0.42 + 0.15)
	elseif key == "dragon:R" then
		-- 몸을 휘감으며 같이 솟구치는 용
		local parts = {}
		for i = 1, 10 do
			table.insert(parts, piece(Vector3.new(1, 1, 1) * (2.4 - i * 0.15), c:Lerp(c2, i / 10), Enum.Material.Neon, Enum.PartType.Ball, 0.2))
		end
		follow(model, dur + 0.2, parts, function(t, cf)
			local out = {}
			for i = 1, 10 do
				local k = math.max(0, t - i * 0.03)
				local a = k * 14
				out[i] = CFrame.new(cf.Position + Vector3.new(math.cos(a) * 3, -2 + k * 4 - i * 0.4, math.sin(a) * 3))
			end
			return out
		end)
		local column = piece(Vector3.new(3, 1, 3), c, Enum.Material.Neon, nil, 0.3)
		column.Position = feet
		tween(column, 0.3, { Size = Vector3.new(1.5, 40, 1.5), Position = feet + Vector3.new(0, 20, 0), Transparency = 1 })
		Debris:AddItem(column, 0.35)
	elseif key == "shadow:H" then
		for k = 1, 4 do
			task.delay(k * 0.06, function()
				Fx.afterimage(model, Color3.fromRGB(70, 40, 120), 0.45)
			end)
		end
		task.delay(0.1, function()
			streak(pos, pos + look * 12, Color3.fromRGB(60, 30, 100), 1.4, 0.45)
		end)
	elseif key == "shadow:E" then
		-- 사라지는 자리에 검은 연기
		for _ = 1, 8 do
			local smoke = piece(Vector3.new(1, 1, 1) * (2 + math.random()), Color3.fromRGB(25, 12, 45), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.2)
			smoke.Position = pos + Vector3.new(math.random() * 3 - 1.5, math.random() * 3 - 1.5, math.random() * 3 - 1.5)
			tween(smoke, 0.7, { Size = smoke.Size * 3, Transparency = 1 })
			Debris:AddItem(smoke, 0.75)
		end
	elseif key == "shadow:R" then
		-- 몸을 둘러싼 검보랏빛 회오리 고리
		local parts = {}
		for i = 1, 3 do
			table.insert(parts, piece(Vector3.new(0.25, 7 + i, 7 + i), c, Enum.Material.Neon, Enum.PartType.Cylinder, 0.35))
		end
		follow(model, dur, parts, function(t, cf)
			local out = {}
			for i = 1, 3 do
				out[i] = CFrame.new(cf.Position) * CFrame.Angles(t * 12 + i, t * 9 + i * 2, 0)
			end
			return out
		end)
	elseif key == "lightning:H" or key == "lightning:E" then
		local lunge = slot == "E" and 20 or 18
		task.delay(0.08, function()
			local prev = pos
			for k = 1, 5 do
				local side = Vector3.new(-look.Z, 0, look.X) * ((k % 2 == 0) and 2.5 or -2.5)
				local p = pos + look * (lunge * k / 5) + (slot == "E" and side or Vector3.zero)
				Fx.lightning(prev, p, c, 0.5)
				prev = p
			end
			Fx.spark(pos + look * lunge, c2, 1.6, 8)
		end)
	elseif key == "lightning:R" then
		-- 하늘을 가리키면 주변에 벼락이 내리꽂힌다
		local orb = piece(Vector3.new(1.5, 1.5, 1.5), c2, Enum.Material.Neon, Enum.PartType.Ball, 0)
		orb.Position = pos + Vector3.new(0, 4, 0)
		tween(orb, 0.3, { Size = Vector3.new(3, 3, 3), Transparency = 0.4 })
		Debris:AddItem(orb, 0.4)
		for k = 0, 5 do
			task.delay(0.3 + k * 0.07, function()
				local a = math.random() * math.pi * 2
				local p = feet + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(4, 16)
				Fx.lightning(p + Vector3.new(0, 55, 0), p, c, 0.7)
				Fx.ring(p + Vector3.new(0, 0.3, 0), c, 1, 8, 0.3)
			end)
		end
	elseif key == "drunk:H" then
		task.delay(0.25, function()
			for _ = 1, 10 do
				local drop = piece(Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(255, 160, 60), Enum.Material.Neon, Enum.PartType.Ball, 0.1)
				drop.Position = pos + look * 3
				tween(drop, 0.45, { Position = pos + look * 3 + Vector3.new(math.random() * 8 - 4, math.random() * 5, math.random() * 8 - 4), Transparency = 1 })
				Debris:AddItem(drop, 0.5)
			end
			Fx.ring(pos + look * 3, c, 2, 12, 0.35, look)
		end)
	elseif key == "drunk:E" then
		Fx.aura(model, c, 3)
	elseif key == "drunk:R" then
		-- 여덟 신선의 빛이 몸 둘레를 돈다
		local parts = {}
		for i = 1, 8 do
			table.insert(parts, piece(Vector3.new(1.3, 1.3, 1.3), i % 2 == 0 and c or c2, Enum.Material.Neon, Enum.PartType.Ball, 0.1))
		end
		follow(model, dur, parts, function(t, cf)
			local out = {}
			for i = 1, 8 do
				local a = t * 10 + i / 8 * math.pi * 2
				out[i] = CFrame.new(cf.Position + Vector3.new(math.cos(a) * 6, math.sin(t * 6 + i) * 1.5, math.sin(a) * 6))
			end
			return out
		end)
		for k = 0, 3 do
			task.delay(k * 0.25, function()
				Fx.ring(feet + Vector3.new(0, 0.3, 0), c, 3, 18, 0.35)
			end)
		end
	end
end

-- 흘리기의 빛: 흘린 손이 지나간 반원을 따라 빛이 흐르고, 물결처럼 퍼진다
function Fx.parryArc(model: Model, side: number, color: Color3)
	local r = rootPart(model)
	if not r then
		return
	end
	local cf = r.CFrame * CFrame.new(0, 0.6, 0)
	local n = 9
	for i = 0, n - 1 do
		task.delay(i * 0.018, function()
			local a0 = math.rad(-35 + i * 15) * side
			local a1 = math.rad(-35 + (i + 1) * 15) * side
			local p0 = (cf * CFrame.new(math.sin(a0) * 3.4, i * 0.06, -math.cos(a0) * 3.4)).Position
			local p1 = (cf * CFrame.new(math.sin(a1) * 3.4, (i + 1) * 0.06, -math.cos(a1) * 3.4)).Position
			local seg = piece(Vector3.new(0.5, 0.18, (p1 - p0).Magnitude + 0.3), i % 3 == 0 and Color3.new(1, 1, 1) or color, Enum.Material.Neon, nil, 0.05)
			seg.CFrame = lookAt((p0 + p1) / 2, p1)
			tween(seg, 0.35, { Size = Vector3.new(0.05, 0.05, seg.Size.Z * 1.3), Transparency = 1 })
			Debris:AddItem(seg, 0.4)
		end)
	end
	-- 흘려 보낸 쪽으로 퍼지는 물결 고리
	local out = (cf * CFrame.new(side * 3, 0, -1)).Position
	Fx.ring(out, color, 1, 9, 0.4, r.CFrame.RightVector * side)
	Fx.ring(r.Position - Vector3.new(0, 2.5, 0), color, 2, 10, 0.4)
end

-- 몸을 감싸는 은은한 기운 (철포삼, 취보처럼 오래 가는 기술)
function Fx.aura(model: Model, color: Color3, dur: number)
	local shell = piece(Vector3.new(7, 7, 7), color, Enum.Material.ForceField, Enum.PartType.Ball, 0)
	local sparks = {}
	for _ = 1, 4 do
		table.insert(sparks, piece(Vector3.new(0.5, 0.5, 0.5), color, Enum.Material.Neon, Enum.PartType.Ball, 0))
	end
	local parts = { shell, table.unpack(sparks) }
	follow(model, dur, parts, function(t, cf)
		local out = { CFrame.new(cf.Position) }
		for i = 1, 4 do
			local a = t * 4 + i / 4 * math.pi * 2
			out[i + 1] = CFrame.new(cf.Position + Vector3.new(math.cos(a) * 3, ((t * 2 + i * 0.25) % 1) * 6 - 3, math.sin(a) * 3))
		end
		return out
	end, 0.4)
end

------------------------------------------------------------------------
-- 히트스톱: 맞은 순간 둘 다 멈칫. 내 몸이면 아주 잠깐 굳힌다
------------------------------------------------------------------------
local Anim: any = nil
function Fx.bindAnim(a: any)
	Anim = a
end

function Fx.hitstop(models: { Model }, secs: number)
	local me = Players.LocalPlayer.Character
	for _, m in ipairs(models) do
		if Anim then
			Anim.freeze(m, secs)
		end
		if m == me then
			local root = m:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") and not root.Anchored then
				local vel = root.AssemblyLinearVelocity
				root.Anchored = true
				task.delay(secs, function()
					if root.Parent then
						root.Anchored = false
						root.AssemblyLinearVelocity = vel
					end
				end)
			end
		end
	end
end

return Fx
