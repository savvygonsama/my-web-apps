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
	-- 불티 입자와 맞은 자리의 빛
	Fx.burst("spark", pos, color, count * 1.4, math.clamp(size / 1.3, 0.6, 2))
	Fx.flash(pos, color, 8 + size * 4, 1.6 + size * 0.6, 0.18)
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

-- 바닥에 퍼지는 충격파 고리 (faceDir를 주면 그 방향을 보고 선다)
-- 속이 빈 빛의 테 (조각을 둥글게 이어 붙인다) + 안쪽의 옅은 빛
function Fx.ring(pos: Vector3, color: Color3, fromD: number, toD: number, life: number, faceDir: Vector3?)
	local cf = faceDir and lookAt(pos, pos + faceDir) or CFrame.lookAt(pos, pos + Vector3.new(0, 1, 0), Vector3.new(0, 0, -1))
	-- 바닥의 큰 충격파: 흙먼지가 고리를 따라 퍼지고, 아주 크면 돌 조각이 튄다
	if not faceDir and toD >= 24 and toD > fromD then
		Fx.burst("dust", pos + Vector3.new(0, 0.5, 0), Color3.fromRGB(175, 160, 140), math.min(30, toD / 2.5), math.clamp(toD / 28, 0.8, 2.2))
		Fx.flash(pos + Vector3.new(0, 2, 0), color, toD * 0.6, 2.5, life)
		if toD >= 40 then
			Fx.debris(pos, math.min(10, math.floor(toD / 8)), math.min(26, toD * 0.35))
		end
	end
	local glow = piece(Vector3.new(0.1, fromD, fromD), color, Enum.Material.Neon, Enum.PartType.Cylinder, 0.7)
	glow.CFrame = cf * CFrame.Angles(0, math.rad(90), 0)
	tween(glow, life, { Size = Vector3.new(0.05, toD, toD), Transparency = 1 })
	Debris:AddItem(glow, life + 0.05)
	-- 작은 고리 (평타 맞힘 등)는 매끈한 빛 원반 하나 (조각을 이으면 네모가 보인다)
	if toD < 24 then
		glow.Transparency = 0.2
		return
	end
	local n = math.clamp(math.floor(toD / 1.6), 16, 40)
	local thick = math.clamp(toD * 0.02, 0.4, 1.2)
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		local dir = cf.RightVector * math.cos(a) + cf.UpVector * math.sin(a)
		local tangent = cf.RightVector * -math.sin(a) + cf.UpVector * math.cos(a)
		local function seg(d: number): CFrame
			local at = pos + dir * (d / 2)
			return CFrame.lookAt(at, at + tangent, cf.LookVector)
		end
		local p = piece(Vector3.new(thick, thick * 0.4, math.max(0.2, math.pi * fromD / n * 1.15)), color, Enum.Material.Neon, nil, 0.05)
		p.CFrame = seg(fromD)
		tween(p, life, { CFrame = seg(toD), Size = Vector3.new(thick * 0.3, thick * 0.15, math.pi * toD / n * 1.15), Transparency = 1 })
		Debris:AddItem(p, life + 0.05)
	end
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
	l.TextStrokeTransparency = 1
	l.Text = text
	l.Parent = bb
	-- 글자: 위는 밝고 아래로 진해지는 빛깔, 굵은 검은 테
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.55), color)
	grad.Parent = l
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(18, 8, 8)
	st.Thickness = math.clamp(size / 12, 1.5, 4)
	st.Parent = l
	local sc = Instance.new("UIScale")
	sc.Scale = 1.8
	sc.Parent = l
	tween(sc, 0.14, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(anchor, 0.8, { Position = pos + Vector3.new(math.random() * 2 - 1, rise or 3.5, 0) })
	task.delay(0.45, function()
		tween(l, 0.35, { TextTransparency = 1 })
		tween(st, 0.35, { Transparency = 1 })
	end)
	Debris:AddItem(anchor, 0.85)
end

-- 흙먼지
function Fx.dust(pos: Vector3, size: number)
	Fx.burst("dust", pos, Color3.fromRGB(185, 168, 140), 6 + size * 2, math.clamp(size / 2, 0.6, 2))
	for _ = 1, 3 do
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
			-- 번개 둘레의 흐린 빛무리
			local halo = piece(Vector3.new(w * 4, w * 4, len), col, Enum.Material.Neon, nil, 0.8)
			halo.CFrame = seg.CFrame
			tween(halo, 0.2, { Transparency = 1 })
			Debris:AddItem(halo, 0.22)
		end
		prev = p
	end
	-- 떨어진 자리: 불티와 번쩍임
	Fx.burst("spark", to, col, 8, 1)
	Fx.flash(to, col, 18, 4, 0.2)
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
	-- 강타는 땅까지 울린다 (흙먼지·돌 조각)
	if heavy then
		Fx.impact(pos, c, 1)
	end
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
	elseif style.fx == "basic" then
		Fx.ring(pos, c2, 1, 7 * s, 0.25, dir)
	elseif style.fx == "void" then
		-- 무극: 맞은 자리가 한 점으로 꺼졌다 터진다
		local hole = piece(Vector3.new(3, 3, 3) * s, Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.1)
		hole.Position = pos
		tween(hole, 0.15, { Size = Vector3.new(0.2, 0.2, 0.2) })
		Debris:AddItem(hole, 0.16)
		task.delay(0.15, function()
			Fx.ring(pos, c2, 0.5, 14 * s, 0.35, dir)
			Fx.ring(pos, c, 0.5, 9 * s, 0.3)
		end)
	elseif style.fx == "blood" then
		-- 혈마: 핏빛 방울이 튀고 붉은 고리
		Fx.ring(pos, c, 1, 9 * s, 0.3, dir)
		for _ = 1, heavy and 10 or 6 do
			local drop = piece(Vector3.new(0.4, 0.4, 0.4), c, Enum.Material.Neon, Enum.PartType.Ball, 0.1)
			drop.Position = pos
			tween(drop, 0.45, { Position = pos + Vector3.new(math.random() * 6 - 3, math.random() * 3 - 2, math.random() * 6 - 3) * s, Transparency = 1 })
			Debris:AddItem(drop, 0.5)
		end
	elseif style.fx == "celestial" then
		-- 천제: 금빛 십자가 번쩍
		for _, rot in ipairs({ 0, 90 }) do
			local bar = piece(Vector3.new(0.4, 6 * s, 0.4), Color3.fromRGB(255, 250, 225), Enum.Material.Neon, nil, 0)
			bar.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(rot + 45))
			tween(bar, 0.25, { Size = Vector3.new(0.05, 9 * s, 0.05), Transparency = 1 })
			Debris:AddItem(bar, 0.3)
		end
		Fx.ring(pos, c, 1, 9 * s, 0.3, dir)
	elseif style.fx == "gravity" then
		-- 파천: 맞은 자리가 아래로 짓눌린다 (보랏빛 고리가 안으로 조이고 바닥이 꺼진다)
		local dent = piece(Vector3.new(2.5, 2.5, 2.5) * s, Color3.fromRGB(10, 0, 20), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.2)
		dent.Position = pos
		tween(dent, 0.14, { Size = Vector3.new(0.3, 0.3, 0.3) })
		Debris:AddItem(dent, 0.15)
		Fx.ring(pos, c, 10 * s, 1, 0.18, dir)
		task.delay(0.12, function()
			Fx.ring(pos - Vector3.new(0, 2, 0), c2, 1, 10 * s, 0.3)
		end)
	elseif style.fx == "origin" then
		-- 태초: 맑은 빛의 결정이 맞은 자리에서 여섯 갈래로 갈라진다
		local face = lookAt(pos, pos + (dir or Vector3.new(0, 0, -1)))
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			local bar = piece(Vector3.new(0.3, 0.3, 0.3), k % 2 == 0 and Color3.fromRGB(255, 252, 240) or c2, Enum.Material.Neon, nil, 0)
			bar.CFrame = lookAt(pos, pos + face:VectorToWorldSpace(Vector3.new(math.cos(a), math.sin(a), 0)))
			tween(bar, 0.22, { Size = Vector3.new(0.08, 0.08, 6 * s), Transparency = 1, CFrame = bar.CFrame * CFrame.new(0, 0, -3 * s) })
			Debris:AddItem(bar, 0.25)
		end
		Fx.ring(pos, c2, 1, 9 * s, 0.28, dir)
	elseif style.fx == "wind" then
		-- 풍신: 바람 고리 두 겹과 날리는 잎
		Fx.ring(pos, c2, 1, 8 * s, 0.3, dir)
		Fx.ring(pos, c, 1, 12 * s, 0.4, dir)
		for _ = 1, heavy and 8 or 4 do
			local leaf = piece(Vector3.new(0.6, 0.08, 0.4), Color3.fromRGB(150, 210, 120), Enum.Material.SmoothPlastic)
			leaf.CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
			tween(leaf, 0.7, { CFrame = CFrame.new(pos + Vector3.new(math.random() * 10 - 5, math.random() * 6, math.random() * 10 - 5)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0), Transparency = 1 })
			Debris:AddItem(leaf, 0.75)
		end
	elseif style.fx == "cosmic" then
		-- 개천: 별빛이 사방으로 튀고 금빛 고리
		Fx.ring(pos, c2, 1, 10 * s, 0.3, dir)
		for _ = 1, heavy and 10 or 6 do
			local st = piece(Vector3.new(0.35, 0.35, 0.35), math.random() < 0.5 and c or Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball, 0)
			st.Position = pos
			tween(st, 0.5, { Position = pos + Vector3.new(math.random() * 8 - 4, math.random() * 6 - 1, math.random() * 8 - 4) * s, Transparency = 1 })
			Debris:AddItem(st, 0.55)
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

-- 오의 연출 (권법마다 전혀 다르게). 발밑 진 → 모으기 → 절정(dur의 85%)에 터진다
local function beam(at: Vector3, color: Color3, width: number, height: number, life: number)
	local b = piece(Vector3.new(width, 1, width), color, Enum.Material.Neon, Enum.PartType.Cylinder, 0.15)
	b.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	b.Size = Vector3.new(1, width, width)
	tween(b, 0.18, { Size = Vector3.new(height, width, width), CFrame = CFrame.new(at + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(0.18, function()
		tween(b, life, { Size = Vector3.new(height, width * 0.1, width * 0.1), Transparency = 1 })
	end)
	Debris:AddItem(b, life + 0.25)
	return b
end
local function sphere(at: Vector3, color: Color3, from: number, to: number, life: number, material: Enum.Material?, trans: number?)
	local s = piece(Vector3.new(from, from, from), color, material or Enum.Material.Neon, Enum.PartType.Ball, trans or 0.3)
	s.Position = at
	tween(s, life, { Size = Vector3.new(to, to, to), Transparency = 1 })
	Debris:AddItem(s, life + 0.05)
	return s
end
-- 돌며 솟는 조각 무리 (용, 꽃잎 회오리, 별 은하)
local function spiral(base: Vector3, n: number, dur: number, size: number, colors: { Color3 }, mat: Enum.Material, radius: number, rise: number, spin: number, shape: Enum.PartType?)
	local segs = {}
	for i = 1, n do
		local seg = piece(Vector3.new(1, 1, 1) * size * (1 - i / n * 0.5), colors[(i % #colors) + 1], mat, shape or Enum.PartType.Ball, 0.15)
		seg.Position = base
		table.insert(segs, seg)
	end
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		for i, seg in ipairs(segs) do
			local k = math.max(0, t - i * 0.035)
			local a = k * spin + i * 0.3
			local r = radius * (1 - math.min(0.6, k * 0.4))
			seg.CFrame = CFrame.new(base + Vector3.new(math.cos(a) * r, k * rise, math.sin(a) * r)) * CFrame.Angles(a, a * 0.5, 0)
		end
		if t > dur then
			conn:Disconnect()
			for _, seg in ipairs(segs) do
				tween(seg, 0.35, { Transparency = 1 })
				Debris:AddItem(seg, 0.4)
			end
		end
	end)
end

function Fx.ult(styleId: string, model: Model, dur: number)
	local style = styleOf(styleId)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not style or not root or not root:IsA("BasePart") then
		return
	end
	local base = Vector3.new(root.Position.X, root.Position.Y - 2.5, root.Position.Z)
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
	local c, c2 = style.color, style.color2
	local climax = dur * 0.85
	-- 공통: 발밑의 두 겹 진 (도는 띠)
	local circle = piece(Vector3.new(0.3, 4, 4), c, Enum.Material.Neon, Enum.PartType.Cylinder, 0.3)
	circle.CFrame = CFrame.new(base + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(circle, 0.5, { Size = Vector3.new(0.3, 36, 36) })
	local inner = piece(Vector3.new(0.35, 4, 4), c2, Enum.Material.Neon, Enum.PartType.Cylinder, 0.45)
	inner.CFrame = CFrame.new(base + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(inner, 0.6, { Size = Vector3.new(0.35, 22, 22) })
	task.delay(dur - 0.3, function()
		tween(circle, 0.3, { Transparency = 1 })
		tween(inner, 0.3, { Transparency = 1 })
	end)
	Debris:AddItem(circle, dur + 0.1)
	Debris:AddItem(inner, dur + 0.1)
	-- 모으는 동안 둘레에서 빛이 빨려 든다
	for k = 0, 9 do
		task.delay(k * dur * 0.05, function()
			local a = math.random() * math.pi * 2
			local from = base + Vector3.new(math.cos(a) * 18, math.random() * 8 + 1, math.sin(a) * 18)
			local mote = piece(Vector3.new(0.8, 0.8, 0.8), k % 2 == 0 and c or c2, Enum.Material.Neon, Enum.PartType.Ball, 0.1)
			mote.Position = from
			tween(mote, 0.4, { Position = base + Vector3.new(0, 3, 0), Size = Vector3.new(0.2, 0.2, 0.2) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Debris:AddItem(mote, 0.45)
		end)
	end
	local fx = style.fx
	if fx == "water" then
		-- 물의 돔이 솟고, 물의 용이 감아 오르다, 해일 고리가 퍼져 나간다
		local dome = piece(Vector3.new(4, 4, 4), c2, Enum.Material.Glass, Enum.PartType.Ball, 0.55)
		dome.Position = base
		tween(dome, dur * 0.6, { Size = Vector3.new(30, 18, 30) })
		task.delay(climax, function()
			tween(dome, 0.3, { Size = Vector3.new(44, 4, 44), Transparency = 1 })
		end)
		Debris:AddItem(dome, climax + 0.4)
		spiral(base, 16, climax, 3.6, { c, c2 }, Enum.Material.Glass, 10, 20, 6)
		task.delay(climax, function()
			for k = 0, 3 do
				task.delay(k * 0.08, function()
					Fx.ring(base + Vector3.new(0, 0.5 + k * 0.6, 0), k % 2 == 0 and c2 or c, 4, 50 + k * 10, 0.6)
				end)
			end
			for _ = 1, 24 do
				local a = math.random() * math.pi * 2
				local drop = piece(Vector3.new(0.8, 0.8, 0.8), c2, Enum.Material.Glass, Enum.PartType.Ball, 0.1)
				drop.Position = base + Vector3.new(0, 2, 0)
				tween(drop, 0.7, { Position = base + Vector3.new(math.cos(a) * 22, math.random() * 12, math.sin(a) * 22), Transparency = 1 })
				Debris:AddItem(drop, 0.75)
			end
		end)
	elseif fx == "gold" then
		-- 등 뒤의 금빛 후광, 둘레를 도는 경문 고리, 하늘에서 내려찍는 손바닥과 빛기둥
		local halo = piece(Vector3.new(0.4, 12, 12), c, Enum.Material.Neon, Enum.PartType.Cylinder, 0.35)
		halo.CFrame = CFrame.lookAt(base + Vector3.new(0, 6, 0) - look * 1.5, base + Vector3.new(0, 6, 0) - look * 3) * CFrame.Angles(0, math.rad(90), 0)
		tween(halo, 0.5, { Size = Vector3.new(0.4, 16, 16) })
		task.delay(dur - 0.3, function()
			tween(halo, 0.3, { Transparency = 1 })
		end)
		Debris:AddItem(halo, dur + 0.1)
		for k = 0, 2 do
			task.delay(k * 0.2, function()
				Fx.ring(base + Vector3.new(0, 2 + k * 3, 0), c2, 6, 12, 0.6)
			end)
		end
		local target = base + look * 6
		local palm = piece(Vector3.new(16, 2, 20), c, Enum.Material.Neon, nil, 0.25)
		palm.CFrame = CFrame.new(target + Vector3.new(0, 70, 0))
		local fingers = {}
		for i = -2, 2 do
			local fg = piece(Vector3.new(2.6, 1.8, 9), c2, Enum.Material.Neon, nil, 0.3)
			fg.CFrame = palm.CFrame * CFrame.new(i * 3.2, 0, -13)
			table.insert(fingers, fg)
		end
		task.delay(climax - 0.2, function()
			tween(palm, 0.2, { CFrame = CFrame.new(target + Vector3.new(0, 1, 0)) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			for i, fg in ipairs(fingers) do
				tween(fg, 0.2, { CFrame = CFrame.new(target + Vector3.new(0, 1, 0)) * CFrame.new((i - 3) * 3.2, 0, -13) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
			task.delay(0.2, function()
				beam(target, c2, 10, 120, 0.6)
				Fx.ring(target, c, 4, 64, 0.6)
				Fx.ring(target + Vector3.new(0, 1, 0), c2, 4, 40, 0.5)
				Fx.dust(target, 7)
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
	elseif fx == "petal" then
		-- 꽃잎 회오리가 몸을 감싸 솟고, 다섯 번 피었다가 마지막에 크게 만개
		spiral(base, 30, dur, 1.4, { c, c2, Color3.fromRGB(255, 240, 245) }, Enum.Material.SmoothPlastic, 9, 10, 9, Enum.PartType.Block)
		for k = 0, 3 do
			task.delay(k * dur * 0.2, function()
				Fx.bloom(base + Vector3.new(0, 1, 0), 10 + k * 2)
			end)
		end
		task.delay(climax, function()
			Fx.bloom(base + Vector3.new(0, 1, 0), 26)
			sphere(base + Vector3.new(0, 2, 0), c, 4, 30, 0.5, Enum.Material.Neon, 0.6)
		end)
	elseif fx == "dragon" then
		-- 용 한 마리가 몸을 감아 하늘로, 이어 아홉 용 기둥이 땅을 뚫는다
		spiral(base, 18, dur, 4, { c, c2 }, Enum.Material.Neon, 9, 26, 7)
		for i = 0, 8 do
			task.delay(climax - 0.3 + i * 0.05, function()
				local a = i / 9 * math.pi * 2
				local p = base + Vector3.new(math.cos(a) * 15, 0, math.sin(a) * 15)
				beam(p, i % 2 == 0 and c or c2, 4, 70, 0.5)
				Fx.ring(p + Vector3.new(0, 0.3, 0), c, 1, 10, 0.4)
			end)
		end
		task.delay(climax, function()
			Fx.ring(base + Vector3.new(0, 0.5, 0), c, 4, 56, 0.6)
			Fx.dust(base, 6)
		end)
	elseif fx == "shadow" then
		-- 검은 구가 몸을 삼키고, 여섯 그림자가 사방에서 엇갈려 지나간다
		sphere(base + Vector3.new(0, 3, 0), Color3.fromRGB(20, 10, 35), 2, 14, 0.4, Enum.Material.SmoothPlastic, 0.2)
		for k = 0, 5 do
			task.delay(0.25 + k * (climax - 0.25) / 6, function()
				local a = k / 6 * math.pi * 2
				local p = base + Vector3.new(math.cos(a) * 10, 3, math.sin(a) * 10)
				local q = base + Vector3.new(-math.cos(a) * 10, 3, -math.sin(a) * 10)
				local ghost = piece(Vector3.new(2, 5, 1), Color3.fromRGB(40, 20, 70), Enum.Material.Neon, nil, 0.3)
				ghost.CFrame = lookAt(p, q)
				tween(ghost, 0.18, { CFrame = lookAt(q, q + (q - p)) })
				streak(p, q, c, 0.6, 0.3)
				task.delay(0.18, function()
					tween(ghost, 0.2, { Transparency = 1 })
				end)
				Debris:AddItem(ghost, 0.45)
			end)
		end
		task.delay(climax, function()
			sphere(base + Vector3.new(0, 3, 0), c, 3, 30, 0.45, Enum.Material.Neon, 0.4)
			Fx.ring(base + Vector3.new(0, 0.4, 0), c, 3, 40, 0.5)
		end)
	elseif fx == "lightning" then
		-- 머리 위로 먹구름이 모이고, 벼락이 쏟아지다 마지막에 거대한 한 줄기
		local cloud = piece(Vector3.new(4, 40, 40), Color3.fromRGB(40, 40, 60), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, 0.4)
		cloud.CFrame = CFrame.new(base + Vector3.new(0, 55, 0)) * CFrame.Angles(0, 0, math.rad(90))
		tween(cloud, 0.6, { Size = Vector3.new(6, 70, 70) })
		task.delay(dur, function()
			tween(cloud, 0.4, { Transparency = 1 })
		end)
		Debris:AddItem(cloud, dur + 0.5)
		for k = 0, 11 do
			task.delay(0.4 + k * (climax - 0.4) / 12, function()
				local a = math.random() * math.pi * 2
				local p = base + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(4, 22)
				Fx.lightning(p + Vector3.new(0, 55, 0), p, c, 0.7)
				Fx.ring(p, c, 1, 9, 0.3)
			end)
		end
		task.delay(climax, function()
			local p = base + look * 6
			Fx.lightning(p + Vector3.new(0, 80, 0), p, c2, 3)
			Fx.lightning(p + Vector3.new(4, 80, 0), p, c, 2)
			beam(p, c2, 8, 90, 0.4)
			Fx.ring(p, c, 4, 50, 0.5)
		end)
	elseif fx == "drunk" then
		-- 술기운이 불길이 되어 앞으로 쏟아진다 (불덩이 줄기)
		for k = 0, 13 do
			task.delay(0.35 + k * (climax - 0.35) / 14, function()
				local from = base + Vector3.new(0, 4, 0) + look * 2
				local side = Vector3.new(-look.Z, 0, look.X) * (math.random() * 6 - 3)
				local ball = piece(Vector3.new(2, 2, 2), k % 2 == 0 and Color3.fromRGB(255, 140, 40) or c, Enum.Material.Neon, Enum.PartType.Ball, 0.1)
				ball.Position = from
				tween(ball, 0.45, { Position = from + look * 20 + side + Vector3.new(0, -2, 0), Size = Vector3.new(6, 6, 6), Transparency = 1 })
				Debris:AddItem(ball, 0.5)
			end)
		end
		task.delay(climax, function()
			Fx.ring(base + Vector3.new(0, 0.5, 0) + look * 10, Color3.fromRGB(255, 140, 40), 4, 36, 0.5)
			sphere(base + look * 12 + Vector3.new(0, 2, 0), Color3.fromRGB(255, 120, 30), 4, 22, 0.4)
		end)
	elseif fx == "basic" then
		-- 하늘·땅·사람: 세 기둥이 셋으로 서고, 한 주먹에 모여 땅이 갈라진다
		for k = 0, 2 do
			task.delay(k * 0.2, function()
				local a = k / 3 * math.pi * 2
				local p = base + Vector3.new(math.cos(a) * 9, 0, math.sin(a) * 9)
				beam(p, k == 1 and c2 or c, 3, 40, climax - k * 0.2)
			end)
		end
		task.delay(climax, function()
			for k = 0, 7 do
				local a = k / 8 * math.pi * 2
				local p = base + look * 4
				streak(p, p + Vector3.new(math.cos(a), 0, math.sin(a)) * 22, c, 1.2, 0.5)
			end
			Fx.ring(base + look * 4 + Vector3.new(0, 0.4, 0), c, 3, 40, 0.5)
			Fx.dust(base + look * 4, 6)
		end)
	elseif fx == "void" then
		-- 무극: 검은 구와 흰 구가 서로를 돌다(태극), 모든 것이 한 점으로 빨려 들었다가 터진다
		local orbs = { piece(Vector3.new(3, 3, 3), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0), piece(Vector3.new(3, 3, 3), Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball, 0) }
		follow(model, climax, orbs, function(t, cf)
			local a = t * 6
			local r = 7 - math.min(6, t * 3)
			local p = cf.Position + Vector3.new(0, 3, 0)
			return { CFrame.new(p + Vector3.new(math.cos(a) * r, math.sin(t * 3), math.sin(a) * r)), CFrame.new(p - Vector3.new(math.cos(a) * r, math.sin(t * 3), math.sin(a) * r)) }
		end)
		local hole = piece(Vector3.new(40, 40, 40), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.6)
		hole.Position = base + Vector3.new(0, 3, 0)
		tween(hole, climax, { Size = Vector3.new(1, 1, 1), Transparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Debris:AddItem(hole, climax + 0.05)
		task.delay(climax, function()
			sphere(base + Vector3.new(0, 3, 0), Color3.new(1, 1, 1), 2, 50, 0.55, Enum.Material.Neon, 0.2)
			for k = 0, 3 do
				task.delay(k * 0.07, function()
					Fx.ring(base + Vector3.new(0, 3, 0), k % 2 == 0 and c2 or c, 2, 60 - k * 8, 0.55)
				end)
			end
		end)
	elseif fx == "blood" then
		-- 혈마 강림: 하늘에 핏빛 달, 핏방울 비, 마지막에 거대한 X자 손톱
		local moon = piece(Vector3.new(16, 16, 16), Color3.fromRGB(180, 10, 25), Enum.Material.Neon, Enum.PartType.Ball, 0.2)
		moon.Position = base + Vector3.new(0, 45, 0) - look * 10
		tween(moon, 0.5, { Size = Vector3.new(26, 26, 26) })
		task.delay(dur, function()
			tween(moon, 0.4, { Transparency = 1 })
		end)
		Debris:AddItem(moon, dur + 0.5)
		for k = 0, 23 do
			task.delay(k * climax / 24, function()
				local p = base + Vector3.new(math.random() * 30 - 15, 40, math.random() * 30 - 15)
				local drop = piece(Vector3.new(0.4, 2.4, 0.4), c, Enum.Material.Neon, nil, 0.1)
				drop.Position = p
				tween(drop, 0.4, { Position = Vector3.new(p.X, base.Y + 0.5, p.Z) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				Debris:AddItem(drop, 0.42)
			end)
		end
		task.delay(climax, function()
			local center = base + look * 5 + Vector3.new(0, 4, 0)
			for _, sgn in ipairs({ 1, -1 }) do
				for i = -1, 1 do
					local bar = piece(Vector3.new(0.6, 0.6, 26), i == 0 and c2 or c, Enum.Material.Neon, nil, 0.05)
					bar.CFrame = lookAt(center, center + look) * CFrame.Angles(0, 0, sgn * math.rad(45)) * CFrame.new(i * 1.6, 0, 0) * CFrame.Angles(math.rad(90), 0, 0)
					tween(bar, 0.5, { Size = Vector3.new(0.1, 0.1, 34), Transparency = 1 })
					Debris:AddItem(bar, 0.55)
				end
			end
			Fx.ring(base + Vector3.new(0, 0.5, 0), c, 4, 46, 0.55)
		end)
	elseif fx == "cosmic" then
		-- 개천벽지: 하늘에 문이 열리고, 은하가 땅에 돌고, 별들이 쏟아지다 하늘에서 빛이 내리꽂힌다
		local gateC = base + Vector3.new(0, 60, 0)
		local gate = {}
		for k = 0, 17 do
			local p = piece(Vector3.new(3, 3, 7), k % 2 == 0 and c or c2, Enum.Material.Neon, nil, 0.1)
			table.insert(gate, p)
		end
		local start = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - start
			local r = math.min(30, 4 + t * 30)
			for k, p in ipairs(gate) do
				local a = k / #gate * math.pi * 2 + t * 1.5
				local at = gateC + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				p.CFrame = CFrame.lookAt(at, gateC)
			end
			if t > dur then
				conn:Disconnect()
				for _, p in ipairs(gate) do
					tween(p, 0.4, { Transparency = 1 })
					Debris:AddItem(p, 0.45)
				end
			end
		end)
		local core = piece(Vector3.new(4, 4, 4), Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball, 0.1)
		core.Position = gateC
		tween(core, dur * 0.6, { Size = Vector3.new(36, 36, 36), Color = c })
		task.delay(dur, function()
			tween(core, 0.4, { Transparency = 1 })
		end)
		Debris:AddItem(core, dur + 0.5)
		spiral(base + Vector3.new(0, 0.5, 0), 36, dur, 1, { c, c2, Color3.new(1, 1, 1) }, Enum.Material.Neon, 16, 0.5, 4)
		for k = 0, 9 do
			task.delay(0.45 + k * (climax - 0.45) / 10, function()
				local a = math.random() * math.pi * 2
				Fx.starfall(base + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(4, 20), styleId)
			end)
		end
		task.delay(climax, function()
			beam(base + look * 2, Color3.new(1, 1, 1), 16, 140, 0.7)
			beam(base + look * 2, c, 24, 140, 0.5)
			for k = 0, 3 do
				task.delay(k * 0.08, function()
					Fx.ring(base + Vector3.new(0, 0.5 + k, 0), k % 2 == 0 and c or c2, 4, 70 - k * 10, 0.6)
				end)
			end
			Fx.dust(base, 8)
		end)
	end
end

-- 별 하나가 떨어진다 (개천신권 장치, 낙성우, 오의)
function Fx.starfall(at: Vector3, styleId: any)
	local style = styleOf(styleId)
	local c = style and style.color or Color3.fromRGB(150, 200, 255)
	local c2 = style and style.color2 or Color3.fromRGB(255, 245, 190)
	local ground = Vector3.new(at.X, at.Y - 2, at.Z)
	local from = ground + Vector3.new(math.random() * 16 - 8, 70, math.random() * 16 - 8)
	local star = piece(Vector3.new(2.6, 2.6, 2.6), c2, Enum.Material.Neon, Enum.PartType.Ball, 0)
	star.Position = from
	local tail = piece(Vector3.new(1.2, 1.2, 14), c, Enum.Material.Neon, nil, 0.3)
	tail.CFrame = lookAt(from, ground) * CFrame.new(0, 0, 7)
	tween(star, 0.32, { Position = ground }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(tail, 0.32, { CFrame = lookAt(ground, ground + (ground - from)) * CFrame.new(0, 0, -7) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Debris:AddItem(star, 0.34)
	Debris:AddItem(tail, 0.34)
	task.delay(0.32, function()
		Fx.ring(ground + Vector3.new(0, 0.3, 0), c, 2, 26, 0.45)
		Fx.ring(ground + Vector3.new(0, 0.4, 0), c2, 1, 14, 0.35)
		Fx.spark(ground + Vector3.new(0, 1, 0), c2, 2.4, 12)
		Fx.dust(ground, 3)
		Fx.sound("heavy", 0.6, 0.8, ground)
	end)
end

-- 권법마다 다른 휘두름 무늬 (주먹이 나갈 때마다 그 권법만의 빛이 앞으로 뻗는다)
local function flourish(style: any, r: BasePart, heavy: boolean)
	local c, c2 = style.color, style.color2
	local cf = r.CFrame
	local look, right, up = cf.LookVector, cf.RightVector, Vector3.new(0, 1, 0)
	local base = r.Position + Vector3.new(0, 0.6, 0)
	local s = heavy and 1.6 or 1
	local kind = style.fx
	if kind == "water" then
		-- 물의 초승달: 물방울이 둥글게 휘어 앞으로 흐른다
		for i = -4, 4 do
			local a = i / 4 * 1.1
			local p = base + (look * math.cos(a) + right * math.sin(a)) * 4.2 * s
			local d = piece(Vector3.new(0.55, 0.55, 0.55) * s, i % 2 == 0 and c2 or c, Enum.Material.Glass, Enum.PartType.Ball, 0.15)
			d.Position = base + look * 1.5
			tween(d, 0.16, { Position = p })
			task.delay(0.16, function()
				tween(d, 0.3, { Position = p + look * 3 + Vector3.new(0, -1, 0), Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2) })
			end)
			Debris:AddItem(d, 0.5)
		end
	elseif kind == "gold" then
		-- 금강의 그림자 주먹: 금빛 큰 주먹이 겹쳐 뻗는다
		local fist = piece(Vector3.new(2.2, 2.2, 2.2) * s, c, Enum.Material.Neon, Enum.PartType.Ball, 0.35)
		fist.Position = base + look * 1.5
		tween(fist, 0.18, { Position = base + look * 6 * s, Size = Vector3.new(3.4, 3.4, 3.4) * s, Transparency = 1 })
		Debris:AddItem(fist, 0.2)
		local hex = piece(Vector3.new(0.2, 4, 4) * s, c2, Enum.Material.Neon, Enum.PartType.Cylinder, 0.4)
		hex.CFrame = lookAt(base + look * 5, base + look * 6) * CFrame.Angles(0, math.rad(90), 0)
		tween(hex, 0.25, { Size = Vector3.new(0.05, 8, 8) * s, Transparency = 1 })
		Debris:AddItem(hex, 0.3)
	elseif kind == "petal" then
		-- 매화 부채: 꽃잎이 부채꼴로 흩뿌려진다
		for _ = 1, heavy and 12 or 7 do
			local a = (math.random() - 0.5) * 1.6
			local dir = look * math.cos(a) + right * math.sin(a)
			local pt = piece(Vector3.new(0.6, 0.06, 0.45), math.random() < 0.5 and c or c2, Enum.Material.SmoothPlastic)
			pt.CFrame = CFrame.new(base + look * 1.5) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
			tween(pt, 0.45, { CFrame = CFrame.new(base + dir * (5 + math.random() * 3) * s + up * (math.random() * 2 - 0.5)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0), Transparency = 1 })
			Debris:AddItem(pt, 0.5)
		end
	elseif kind == "dragon" then
		-- 용의 몸: 굽이치는 빛 구슬이 앞으로 헤엄친다
		for i = 1, 7 do
			local seg = piece(Vector3.new(1, 1, 1) * (1.6 - i * 0.15) * s, c:Lerp(c2, i / 7), Enum.Material.Neon, Enum.PartType.Ball, 0.15)
			seg.Position = base + look * 1.5
			local p = base + look * (1.5 + i * 1.1 * s) + right * math.sin(i * 0.9) * 1.2 + up * math.cos(i * 0.9) * 0.6
			task.delay(i * 0.015, function()
				tween(seg, 0.14, { Position = p })
				task.delay(0.14, function()
					tween(seg, 0.25, { Transparency = 1, Size = seg.Size * 0.3 })
				end)
			end)
			Debris:AddItem(seg, 0.5)
		end
	elseif kind == "shadow" then
		-- 그림자 십자: 보랏빛 두 줄이 엇갈린다
		for _, sgn in ipairs({ 1, -1 }) do
			local bar = piece(Vector3.new(0.25, 0.25, 5 * s), c, Enum.Material.Neon, nil, 0.1)
			bar.CFrame = lookAt(base + look * 3.5, base + look * 4.5) * CFrame.Angles(0, 0, sgn * math.rad(45)) * CFrame.Angles(math.rad(90), 0, 0)
			tween(bar, 0.22, { Size = Vector3.new(0.05, 0.05, 7 * s), Transparency = 1 })
			Debris:AddItem(bar, 0.25)
		end
		local smoke = piece(Vector3.new(1.5, 1.5, 1.5), Color3.fromRGB(30, 15, 45), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.4)
		smoke.Position = base - look * 0.5
		tween(smoke, 0.4, { Size = Vector3.new(4, 4, 4), Transparency = 1 })
		Debris:AddItem(smoke, 0.45)
	elseif kind == "lightning" then
		-- 벼락 주먹: 주먹 끝에서 갈라지는 번개
		local tip = base + look * 2
		for _ = 1, heavy and 3 or 2 do
			Fx.lightning(tip, tip + look * (5 + math.random() * 3) * s + right * (math.random() * 4 - 2) + up * (math.random() * 2 - 1), c, 0.22)
		end
	elseif kind == "drunk" then
		-- 취기: 술 방울과 불씨가 휘청이며 퍼진다
		for _ = 1, 5 do
			local f = piece(Vector3.new(0.7, 0.7, 0.7) * s, math.random() < 0.5 and Color3.fromRGB(255, 140, 50) or c, Enum.Material.Neon, Enum.PartType.Ball, 0.2)
			f.Position = base + look * 1.5
			tween(f, 0.35, { Position = base + look * (3 + math.random() * 3) + right * (math.random() * 4 - 2) + up * math.random() * 2, Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 })
			Debris:AddItem(f, 0.4)
		end
	elseif kind == "basic" then
		-- 삼재: 바른 주먹이 공기를 꿰뚫는 세 겹 고리
		for i = 1, 3 do
			task.delay(i * 0.03, function()
				Fx.ring(base + look * (1.5 + i * 1.2), i == 2 and c2 or c, 0.5, (2 + i) * s, 0.18, look)
			end)
		end
	elseif kind == "void" then
		-- 무극: 앞이 한 점으로 빨려 들었다가 터진다
		local p0 = base + look * 4
		local hole = piece(Vector3.new(4, 4, 4) * s, Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.2)
		hole.Position = p0
		tween(hole, 0.12, { Size = Vector3.new(0.3, 0.3, 0.3) })
		task.delay(0.12, function()
			hole:Destroy()
			Fx.ring(p0, c2, 0.5, 10 * s, 0.3, look)
			Fx.ring(p0, c, 0.5, 6 * s, 0.25)
		end)
		Debris:AddItem(hole, 0.2)
	elseif kind == "celestial" then
		-- 천제: 주먹 끝으로 금빛 초승달 칼날이 그어진다
		local arc = piece(Vector3.new(5 * s, 0.12, 1.4), c, Enum.Material.Neon, nil, 0.1)
		arc.CFrame = lookAt(base + look * 3, base + look * 4) * CFrame.Angles(0, 0, math.random() * math.pi)
		tween(arc, 0.2, { Size = Vector3.new(8 * s, 0.04, 0.3), Transparency = 1 })
		Debris:AddItem(arc, 0.22)
		local glint = piece(Vector3.new(0.5, 0.5, 0.5), Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball, 0)
		glint.Position = base + look * 4.5
		tween(glint, 0.2, { Size = Vector3.new(2, 2, 2), Transparency = 1 })
		Debris:AddItem(glint, 0.22)
	elseif kind == "gravity" then
		-- 파천: 주먹이 지나간 길이 무겁게 휘어진다 (검은 띠와 보랏빛 테)
		local band = piece(Vector3.new(0.6, 0.6, 5 * s), Color3.fromRGB(15, 5, 25), Enum.Material.SmoothPlastic, nil, 0.2)
		band.CFrame = lookAt(base + look * 3, base + look * 6)
		tween(band, 0.2, { Size = Vector3.new(0.1, 0.1, 7 * s), Transparency = 1 })
		Debris:AddItem(band, 0.22)
		streak(base + look * 1.5, base + look * (5.5 * s), c, 0.35, 0.18)
		if heavy then
			Fx.ring(base + look * 4, c2, 6, 1, 0.2, look)
		end
	elseif kind == "origin" then
		-- 태초: 손끝에서 맑은 빛줄기가 곧게 뻗는다
		streak(base + look * 1.5, base + look * (7 * s), Color3.fromRGB(255, 252, 240), 0.3, 0.16)
		streak(base + look * 1.5 + up * 0.3, base + look * (6 * s), c2, 0.15, 0.2)
		if heavy then
			Fx.ring(base + look * 5, c2, 1, 10, 0.25, look)
		end
	elseif kind == "wind" then
		-- 풍신: 발끝을 따라 휘어진 바람 줄기
		for i = -1, 1, 2 do
			local w = piece(Vector3.new(0.15, 0.15, 5 * s), c2, Enum.Material.Neon, nil, 0.3)
			w.CFrame = lookAt(base + look * 2 + right * i, base + look * 6 + right * i * 2.5) * CFrame.Angles(0, 0, math.rad(30 * i))
			tween(w, 0.25, { Size = Vector3.new(0.04, 0.04, 8 * s), Transparency = 1, CFrame = w.CFrame * CFrame.new(0, 0, -2) })
			Debris:AddItem(w, 0.28)
		end
	elseif kind == "cosmic" then
		-- 개천: 주먹을 따라 나선으로 감기는 별빛
		for i = 1, 8 do
			local a = i * 0.9
			local st = piece(Vector3.new(0.45, 0.45, 0.45) * s, i % 2 == 0 and c or c2, Enum.Material.Neon, Enum.PartType.Ball, 0)
			st.Position = base + look * 1.5
			local p = base + look * (1.5 + i * 0.7 * s) + right * math.cos(a) * 1.1 + up * math.sin(a) * 1.1
			task.delay(i * 0.01, function()
				tween(st, 0.15, { Position = p })
				task.delay(0.15, function()
					tween(st, 0.25, { Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1) })
				end)
			end)
			Debris:AddItem(st, 0.45)
		end
		if heavy then
			Fx.ring(base + look * 5, c2, 1, 9, 0.25, look)
		end
	elseif kind == "blood" then
		-- 혈마: 핏빛 세 갈래 손톱 자국
		for i = -1, 1 do
			local bar = piece(Vector3.new(0.18, 0.18, 4.5 * s), i == 0 and c2 or c, Enum.Material.Neon, nil, 0.05)
			bar.CFrame = lookAt(base + look * 3.2 + right * i * 0.7, base + look * 4.2 + right * i * 0.7) * CFrame.Angles(0, 0, math.rad(60)) * CFrame.Angles(math.rad(90), 0, 0)
			tween(bar, 0.28, { Size = Vector3.new(0.04, 0.04, 6 * s), Transparency = 1 })
			Debris:AddItem(bar, 0.3)
		end
	end
end

-- 권법마다 손에 맺힌 기운 (쓰는 권법이 바뀌면 바뀐다, 각성하면 짙어진다)
local HAND_FX = {
	water = { tex = "rbxasset://textures/particles/sparkles_main.dds", speed = 1.5, life = 0.6, size = 0.35 },
	gold = { tex = "rbxasset://textures/particles/sparkles_main.dds", speed = 2, life = 0.5, size = 0.4 },
	petal = { tex = "rbxasset://textures/particles/sparkles_main.dds", speed = 2.5, life = 0.9, size = 0.3 },
	dragon = { tex = "rbxasset://textures/particles/fire_main.dds", speed = 2, life = 0.45, size = 0.5 },
	shadow = { tex = "rbxasset://textures/particles/smoke_main.dds", speed = 1, life = 0.7, size = 0.6 },
	lightning = { tex = "rbxasset://textures/particles/sparkles_main.dds", speed = 6, life = 0.15, size = 0.3 },
	drunk = { tex = "rbxasset://textures/particles/fire_main.dds", speed = 1.5, life = 0.5, size = 0.4 },
	basic = { tex = "rbxasset://textures/particles/sparkles_main.dds", speed = 1, life = 0.4, size = 0.2 },
	void = { tex = "rbxasset://textures/particles/smoke_main.dds", speed = 0.6, life = 1, size = 0.7 },
	blood = { tex = "rbxasset://textures/particles/smoke_main.dds", speed = 1.2, life = 0.6, size = 0.5 },
	cosmic = { tex = "rbxasset://textures/particles/sparkles_main.dds", speed = 2, life = 1, size = 0.35 },
	celestial = { tex = "rbxasset://textures/particles/sparkles_main.dds", speed = 1.5, life = 0.9, size = 0.4 },
	gravity = { tex = "rbxasset://textures/particles/smoke_main.dds", speed = 0.4, life = 0.6, size = 0.6 },
	origin = { tex = "rbxasset://textures/particles/sparkles_main.dds", speed = 1.2, life = 1.1, size = 0.4 },
	wind = { tex = "rbxasset://textures/particles/smoke_main.dds", speed = 4, life = 0.5, size = 0.5 },
}
function Fx.styleHands(model: Model, styleId: any, tier: number)
	for _, d in ipairs(model:GetDescendants()) do
		if d.Name == "KwonStyleHand" then
			d:Destroy()
		end
	end
	local style = styleOf(styleId)
	local h = style and HAND_FX[style.fx]
	if not style or not h then
		return
	end
	for _, side in ipairs({ "RightHand", "LeftHand", "Right Arm", "Left Arm" }) do
		local hand = model:FindFirstChild(side)
		if hand and hand:IsA("BasePart") then
			local e = Instance.new("ParticleEmitter")
			e.Name = "KwonStyleHand"
			e.Texture = h.tex
			e.Color = ColorSequence.new(style.color, style.color2)
			e.LightEmission = style.fx == "shadow" and 0 or 1
			e.Transparency = NumberSequence.new(0.3, 1)
			e.Size = NumberSequence.new(h.size * (1 + tier * 0.4), 0)
			e.Lifetime = NumberRange.new(h.life * 0.7, h.life)
			e.Speed = NumberRange.new(h.speed * 0.5, h.speed)
			e.SpreadAngle = Vector2.new(180, 180)
			e.Rate = 6 + tier * 10
			e.Parent = hand
		end
	end
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
	if style then
		flourish(style, r, heavy)
	end
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
	-- 기를 끌어올리는 순간: 몸 둘레로 빛 가루가 솟고 잠깐 밝아진다
	Fx.burst("glitter", pos, c2, 16, 1)
	Fx.flash(pos, c, 18, 2.5, 0.45)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
	local feet = pos - Vector3.new(0, 2.6, 0)
	-- 공통: 발밑 고리와 몸의 기운
	Fx.ring(feet + Vector3.new(0, 0.2, 0), c, 2, slot == "H" and 12 or 16, 0.45)
	flare(pos, c, slot == "H" and 2.5 or 3.5)
	Fx.sound("swing", 0.5, slot == "H" and 0.7 or 0.55)
	-- 각성한 기술: 금빛 (완전 각성은 흰빛) 고리가 한 겹 더, 머리 위에 覺
	local tier = tonumber(model:GetAttribute("Awaken")) or 0
	if tier >= 1 then
		local glow = tier >= 2 and Color3.fromRGB(255, 250, 235) or Color3.fromRGB(255, 210, 90)
		Fx.ring(feet + Vector3.new(0, 0.3, 0), glow, 3, slot == "H" and 18 or 24, 0.55)
		flare(pos + Vector3.new(0, 1, 0), c2, 2.5)
		Fx.text(pos + Vector3.new(0, 4.2, 0), tier >= 2 and "✦✦" or "✦", glow, 22, 0.6)
	end
	-- 각성 마무리: 땅에서 솟는 기둥과 하늘로 치솟는 고리
	if slot == "F" then
		task.delay(0.24, function()
			local column = piece(Vector3.new(4, 1, 4), c, Enum.Material.Neon, nil, 0.25)
			local at = pos + look * 4 - Vector3.new(0, 2.5, 0)
			column.Position = at
			tween(column, 0.3, { Size = Vector3.new(1.2, 34, 1.2), Position = at + Vector3.new(0, 17, 0), Transparency = 1 })
			Debris:AddItem(column, 0.35)
			for k = 0, 2 do
				task.delay(k * 0.06, function()
					Fx.ring(at + Vector3.new(0, 2 + k * 4, 0), k == 1 and c2 or c, 2, 10 - k * 2, 0.35)
				end)
			end
			Fx.dust(at, 3)
		end)
		return
	elseif slot == "J" then
		Fx.ring(pos, c, 1, 8, 0.25, look)
		return
	end
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
	elseif key == "basic:H" then
		-- 정권: 주먹 끝에서 공기가 세 겹으로 터진다
		task.delay(0.28, function()
			for k = 0, 2 do
				task.delay(k * 0.04, function()
					Fx.ring(pos + look * (3 + k * 2), k == 1 and c2 or c, 1, 7 + k * 3, 0.3, look)
				end)
			end
		end)
	elseif key == "basic:E" then
		task.delay(0.2, function()
			streak(pos - look * 6, pos + look * 3, c, 1.2, 0.3)
		end)
	elseif key == "basic:R" then
		for k = 0, 2 do
			task.delay(0.15 + k * 0.2, function()
				Fx.ring(pos + look * 3, c, 1, 8, 0.25, look)
				Fx.spark(pos + look * 3, c2, 1, 5)
			end)
		end
	elseif key == "void:H" then
		-- 무극장: 앞이 한 점으로 꺼졌다가 크게 터진다
		task.delay(0.3, function()
			local p0 = pos + look * 5
			local hole = piece(Vector3.new(8, 8, 8), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.2)
			hole.Position = p0
			tween(hole, 0.12, { Size = Vector3.new(0.4, 0.4, 0.4) })
			Debris:AddItem(hole, 0.13)
			task.delay(0.12, function()
				Fx.ring(p0, Color3.new(1, 1, 1), 1, 22, 0.4, look)
				Fx.ring(p0, c, 1, 14, 0.35)
			end)
		end)
	elseif key == "void:E" then
		-- 허공격: 손가락 끝에서 하얀 선이 멀리 꿰뚫는다
		task.delay(0.2, function()
			streak(pos + look * 2, pos + look * 32, Color3.new(1, 1, 1), 0.8, 0.4)
			streak(pos + look * 2, pos + look * 32, c, 2, 0.3)
		end)
	elseif key == "void:R" then
		-- 무극회선: 둘레의 빛이 빨려 들었다 터진다
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			local m = piece(Vector3.new(1, 1, 1), k % 2 == 0 and c or Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball, 0.1)
			m.Position = pos + Vector3.new(math.cos(a) * 14, 0, math.sin(a) * 14)
			tween(m, dur * 0.7, { Position = pos, Size = Vector3.new(0.2, 0.2, 0.2) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Debris:AddItem(m, dur * 0.7)
		end
		task.delay(dur * 0.75, function()
			Fx.ring(feet + Vector3.new(0, 0.3, 0), c, 2, 30, 0.45)
			Fx.ring(pos, Color3.new(1, 1, 1), 2, 22, 0.4)
		end)
	elseif key == "blood:H" then
		-- 혈수천강: 두 손이 내리꽂힌 자리에 피의 웅덩이와 가시
		task.delay(0.32, function()
			local at = feet + look * 4
			Fx.ring(at + Vector3.new(0, 0.3, 0), c, 2, 20, 0.45)
			for k = 0, 7 do
				local a = k / 8 * math.pi * 2
				local p = at + Vector3.new(math.cos(a) * 4, 0, math.sin(a) * 4)
				local spike = piece(Vector3.new(0.6, 0.5, 0.6), c, Enum.Material.Neon, nil, 0)
				spike.CFrame = CFrame.new(p) * CFrame.Angles(math.cos(a) * 0.4, 0, math.sin(a) * 0.4)
				tween(spike, 0.15, { Size = Vector3.new(0.6, 5, 0.6) })
				task.delay(0.2, function()
					tween(spike, 0.3, { Transparency = 1 })
				end)
				Debris:AddItem(spike, 0.55)
			end
		end)
	elseif key == "blood:E" then
		-- 혈영보: 지나간 길에 핏빛 잔상
		task.delay(0.1, function()
			streak(pos, pos + look * 24, c, 2.2, 0.45)
			Fx.afterimage(model, c, 0.5)
		end)
	elseif key == "blood:R" then
		-- 혈해: 둘레로 피의 바다가 퍼진다
		task.delay(0.28, function()
			local sea = piece(Vector3.new(0.3, 4, 4), c, Enum.Material.Neon, Enum.PartType.Cylinder, 0.3)
			sea.CFrame = CFrame.new(feet + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
			tween(sea, 0.35, { Size = Vector3.new(0.3, 28, 28) })
			task.delay(0.5, function()
				tween(sea, 0.4, { Transparency = 1 })
			end)
			Debris:AddItem(sea, 1)
			for _ = 1, 16 do
				local d = piece(Vector3.new(0.5, 0.5, 0.5), c2, Enum.Material.Neon, Enum.PartType.Ball, 0.1)
				d.Position = feet + Vector3.new(math.random() * 20 - 10, 0.5, math.random() * 20 - 10)
				tween(d, 0.5, { Position = d.Position + Vector3.new(0, math.random() * 6 + 2, 0), Transparency = 1 })
				Debris:AddItem(d, 0.55)
			end
		end)
	elseif key == "celestial:H" then
		-- 천검일섬: 하늘까지 닿는 금빛 세로 칼금
		task.delay(0.36, function()
			local at = feet + look * 6
			local slash = piece(Vector3.new(0.6, 46, 3.4), Color3.fromRGB(255, 248, 220), Enum.Material.Neon, nil, 0.05)
			slash.CFrame = CFrame.lookAt(at + Vector3.new(0, 23, 0), at + Vector3.new(0, 23, 0) + look)
			tween(slash, 0.45, { Size = Vector3.new(0.1, 64, 0.4), Transparency = 1 })
			Debris:AddItem(slash, 0.5)
			Fx.ring(at + Vector3.new(0, 0.3, 0), c, 2, 24, 0.45)
		end)
	elseif key == "king:H" then
		-- 패왕권: 앞으로 겹겹이 터지는 공기
		task.delay(0.4, function()
			for k = 1, 6 do
				task.delay(k * 0.03, function()
					Fx.ring(pos + look * (2 + k * 2.5), k % 2 == 0 and c2 or Color3.new(1, 1, 1), 1, 6 + k * 2.2, 0.35, look)
				end)
			end
			Fx.dust(feet + look * 4, 5)
		end)
	elseif key == "king:E" then
		task.delay(0.15, function()
			streak(pos - look * 4, pos + look * 24, c, 3, 0.4)
			Fx.afterimage(model, c, 0.45)
		end)
	elseif key == "king:R" then
		for k = 0, 8 do
			task.delay(0.1 + k * 0.1, function()
				local p = pos + look * 3 + Vector3.new(math.random() * 2 - 1, math.random() * 2 - 0.5, 0)
				Fx.ring(p, Color3.new(1, 1, 1), 0.5, 5, 0.15, look)
			end)
		end
	elseif key == "wind:H" then
		-- 풍인각: 초승달 바람 칼날
		task.delay(0.3, function()
			local blade = piece(Vector3.new(9, 0.2, 2.5), c2, Enum.Material.Neon, nil, 0.2)
			blade.CFrame = lookAt(pos + look * 3, pos + look * 4)
			tween(blade, 0.4, { CFrame = lookAt(pos + look * 40, pos + look * 41), Size = Vector3.new(12, 0.1, 1), Transparency = 1 })
			Debris:AddItem(blade, 0.45)
		end)
	elseif key == "wind:E" then
		task.delay(0.1, function()
			streak(pos, pos + look * 24, c2, 1.6, 0.4)
		end)
	elseif key == "cosmic:H" then
		-- 개천일도: 손날이 지나간 자리에 하늘까지 닿는 금
		task.delay(0.36, function()
			local at = feet + look * 6
			local slash = piece(Vector3.new(0.5, 40, 3), c2, Enum.Material.Neon, nil, 0.05)
			slash.CFrame = CFrame.lookAt(at + Vector3.new(0, 20, 0), at + Vector3.new(0, 20, 0) + look)
			tween(slash, 0.45, { Size = Vector3.new(0.1, 60, 0.4), Transparency = 1 })
			Debris:AddItem(slash, 0.5)
			Fx.ring(at + Vector3.new(0, 0.3, 0), c, 2, 22, 0.45)
			streak(at - look * 4, at + look * 14, c, 1.4, 0.4)
		end)
	elseif key == "cosmic:E" then
		-- 유성추: 솟을 때 별빛 꼬리, 떨어진 자리에 별이 터진다
		local trail = {}
		for i = 1, 6 do
			table.insert(trail, piece(Vector3.new(1, 1, 1) * (1.4 - i * 0.15), i % 2 == 0 and c or c2, Enum.Material.Neon, Enum.PartType.Ball, 0.1))
		end
		follow(model, dur * 0.7, trail, function(t, cf)
			local out = {}
			for i = 1, 6 do
				out[i] = CFrame.new(cf.Position + Vector3.new(0, -i * 0.8, 0) + cf.LookVector * (-i * 0.4) + Vector3.new(math.sin(t * 20 + i), 0, math.cos(t * 20 + i)) * 0.3)
			end
			return out
		end)
		task.delay(dur * 0.72, function()
			local rr = rootPart(model)
			if rr then
				Fx.starfall(rr.Position, styleId)
			end
		end)
	elseif key == "cosmic:R" then
		-- 낙성우: 별비
		for k = 0, 5 do
			task.delay(0.3 + k * 0.11, function()
				local a = math.random() * math.pi * 2
				Fx.starfall(pos + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(3, 15), styleId)
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

-- 그림자 메아리 (완전 각성): 흰 그림자가 같은 기술을 한 번 더 그려 낸다
function Fx.echo(model: Model, styleId: any, slot: any, dur: number)
	local style = styleOf(styleId)
	local c2 = style and style.color2 or Color3.new(1, 1, 1)
	Fx.text((rootPart(model) or { Position = Vector3.zero } :: any).Position + Vector3.new(0, 5.5, 0), "메아리", c2, 26, 0.8)
	for k = 0, 5 do
		task.delay(k * dur / 6, function()
			if model.Parent then
				Fx.afterimage(model, k % 2 == 0 and c2 or (style and style.color or c2), 0.4)
			end
		end)
	end
	Fx.cast(styleId, slot, model, dur)
end

-- 각성의 기운: 몸에서 빛 조각이 피어오른다 (완전 각성은 둘레에 빛 고리도)
local auras: { [Model]: { tier: number, parts: { Instance } } } = {}
function Fx.awakenAura(model: Model, tier: number, color: Color3)
	local cur = auras[model]
	if cur and cur.tier == tier then
		return
	end
	if cur then
		for _, p in ipairs(cur.parts) do
			p:Destroy()
		end
		auras[model] = nil
	end
	local r = rootPart(model)
	if tier <= 0 or not r then
		return
	end
	local parts: { Instance } = {}
	local att = Instance.new("Attachment")
	att.Name = "AwakenAura"
	att.Position = Vector3.new(0, -1, 0)
	att.Parent = r
	table.insert(parts, att)
	local e = Instance.new("ParticleEmitter")
	e.Rate = tier >= 2 and 22 or 10
	e.Color = ColorSequence.new(color, tier >= 2 and Color3.new(1, 1, 1) or color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, tier >= 2 and 0.5 or 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(2, 5)
	e.SpreadAngle = Vector2.new(40, 40)
	e.EmissionDirection = Enum.NormalId.Top
	e.Shape = Enum.ParticleEmitterShape.Cylinder
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	e.Parent = att
	table.insert(parts, e)
	auras[model] = { tier = tier, parts = parts }
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

------------------------------------------------------------------------
-- 기술 장치 연출 (서버가 알려 준다): 소용돌이, 붉은 원, 내리찍기, 기둥, 시간 멈춤 ...
------------------------------------------------------------------------
local function groundDisc(at: Vector3, radius: number, color: Color3, trans: number, h: number?): Part
	local d = piece(Vector3.new(h or 0.2, radius * 2, radius * 2), color, Enum.Material.Neon, Enum.PartType.Cylinder, trans)
	d.CFrame = CFrame.new(at.X, at.Y - 2.4, at.Z) * CFrame.Angles(0, 0, math.rad(90))
	return d
end
local function fadeAfter(p: Instance, t: number, life: number)
	task.delay(t, function()
		if p.Parent then
			tween(p, life, { Transparency = 1 })
		end
	end)
	Debris:AddItem(p, t + life + 0.05)
end

function Fx.mech(data: any)
	local style = styleOf(data.style)
	local c = data.color or (style and style.color) or Color3.fromRGB(255, 230, 180)
	local c2 = data.color and data.color:Lerp(Color3.new(1, 1, 1), 0.5) or (style and style.color2) or Color3.new(1, 1, 1)
	local kind = data.kind
	-- 기술이 땅에 닿는 곳: 빛과 불티 (장치마다 공통)
	if data.at and (kind == "zone" or kind == "drop" or kind == "strike" or kind == "pillar" or kind == "wave" or kind == "beam" or kind == "launch") then
		Fx.flash(data.at, c, (data.radius or 8) * 2.2, 3, 0.35)
		Fx.burst("spark", data.at, c, 10, math.clamp((data.radius or 8) / 8, 0.8, 1.8))
		if kind == "drop" or kind == "wave" or kind == "launch" then
			Fx.burst("dust", data.at - Vector3.new(0, 2, 0), Color3.fromRGB(175, 160, 140), 14, math.clamp((data.radius or 8) / 10, 0.8, 2))
		end
	end
	if kind == "zone" then
		local at, r, dur = data.at, data.radius, data.dur
		local disc = groundDisc(at, 1, c, 0.55)
		tween(disc, 0.25, { Size = Vector3.new(0.2, r * 2, r * 2) })
		fadeAfter(disc, dur, 0.3)
		local rim = groundDisc(at, r, c2, 0.3, 0.35)
		fadeAfter(rim, dur, 0.3)
		-- 둘레를 도는 조각 (물방울 / 핏방울 / 검은 티끌)
		local mat = data.fx == "water" and Enum.Material.Glass or Enum.Material.Neon
		local bits = {}
		for i = 1, 16 do
			local b = piece(Vector3.new(1, 1, 1) * (data.fx == "void" and 0.7 or 1), i % 2 == 0 and c or c2, mat, Enum.PartType.Ball, 0.15)
			table.insert(bits, b)
		end
		local start = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - start
			for i, b in ipairs(bits) do
				local k = (i / #bits + t * 0.35) % 1
				local rr = data.fx == "blood" and r * (0.3 + 0.7 * ((i * 0.37) % 1)) or r * (1 - k)
				local a = i * 0.9 + t * (data.fx == "blood" and 1 or 5)
				local y = data.fx == "blood" and ((t * 2 + i * 0.3) % 1) * 5 or k * 3
				b.Position = Vector3.new(at.X + math.cos(a) * rr, at.Y - 2 + y, at.Z + math.sin(a) * rr)
			end
			if t > dur then
				conn:Disconnect()
				for _, b in ipairs(bits) do
					tween(b, 0.25, { Transparency = 1 })
					Debris:AddItem(b, 0.3)
				end
			end
		end)
		Fx.ring(at - Vector3.new(0, 2.2, 0), c, 1, r * 2, 0.4)
	elseif kind == "reflect" then
		-- 물의 장막 (몸을 감싼 유리 구슬)
		local m = data.m
		local shell = piece(Vector3.new(9, 9, 9), c2, Enum.Material.Glass, Enum.PartType.Ball, 0.6)
		local band = piece(Vector3.new(0.4, 11, 11), c, Enum.Material.Neon, Enum.PartType.Cylinder, 0.4)
		follow(m, data.dur, { shell, band }, function(t, cf)
			return { CFrame.new(cf.Position), CFrame.new(cf.Position) * CFrame.Angles(t * 2, t * 3, math.rad(90)) }
		end, 0.3)
	elseif kind == "wave" then
		local at, r = data.at, data.radius
		for k = 0, 3 do
			task.delay(k * 0.07, function()
				Fx.ring(at - Vector3.new(0, 2 - k * 0.6, 0), k % 2 == 0 and c2 or c, 3, r * 2 + k * 6, 0.55)
			end)
		end
		local dome = piece(Vector3.new(6, 6, 6), c2, Enum.Material.Glass, Enum.PartType.Ball, 0.4)
		dome.Position = at
		tween(dome, 0.4, { Size = Vector3.new(r * 2, r * 0.8, r * 2), Transparency = 1 })
		Debris:AddItem(dome, 0.45)
	elseif kind == "cone" then
		local m = data.m
		local root = m and rootPart(m)
		if not root then
			return
		end
		local range, dur = data.range, data.dur or 0.4
		task.delay(data.delay or 0, function()
			if data.fx == "fire" then
				-- 불길이 앞쪽 부채꼴로 쏟아진다
				local n = math.max(6, math.floor(dur / 0.05))
				for k = 0, n - 1 do
					task.delay(k * dur / n, function()
						local r = rootPart(m)
						if not r then
							return
						end
						local look = r.CFrame.LookVector
						local side = r.CFrame.RightVector * (math.random() * 2 - 1) * math.tan(math.rad(data.angle / 2)) * range
						local from = r.Position + Vector3.new(0, 1.4, 0) + look * 1.5
						local ball = piece(Vector3.new(1.4, 1.4, 1.4), k % 3 == 0 and Color3.fromRGB(255, 230, 120) or Color3.fromRGB(255, 120, 30), Enum.Material.Neon, Enum.PartType.Ball, 0.1)
						ball.Position = from
						tween(ball, 0.4, { Position = from + look * range + side, Size = Vector3.new(5, 5, 5), Transparency = 1 })
						Debris:AddItem(ball, 0.45)
					end)
				end
			else
				-- 포효: 앞으로 퍼져 나가는 금빛 반달 고리
				for k = 0, 3 do
					task.delay(k * 0.06, function()
						local r = rootPart(m)
						if not r then
							return
						end
						local look = r.CFrame.LookVector
						Fx.ring(r.Position + look * (3 + k * range / 5), k % 2 == 0 and c or c2, 3, 8 + k * range * 0.35, 0.4, look)
					end)
				end
				Fx.dust(root.Position - Vector3.new(0, 2.5, 0), 4)
			end
		end)
	elseif kind == "telegraph" or kind == "mark" then
		-- 바닥의 원이 가운데부터 차오른다: 다 차면 떨어진다
		local at, r, time = data.at, data.radius, data.time or 1
		local rim = groundDisc(at, r, kind == "telegraph" and c or c2, 0.25, 0.3)
		local fill = groundDisc(at, 0.5, c, 0.55, 0.25)
		tween(fill, time, { Size = Vector3.new(0.25, r * 2, r * 2) }, Enum.EasingStyle.Linear)
		fadeAfter(rim, time, 0.15)
		fadeAfter(fill, time, 0.15)
	elseif kind == "lineTele" then
		-- 보스 돌진 길: 바닥에 붉은 띠가 차오른다
		local from, to, w, time = data.from, data.to, data.width or 8, data.time or 1
		local mid = (from + to) / 2
		local len = (to - from).Magnitude
		local cf = CFrame.lookAt(Vector3.new(mid.X, from.Y - 2.35, mid.Z), Vector3.new(to.X, from.Y - 2.35, to.Z))
		local rim = piece(Vector3.new(w, 0.25, len), c, Enum.Material.Neon, nil, 0.6)
		rim.CFrame = cf
		local fill = piece(Vector3.new(w, 0.3, 0.5), c, Enum.Material.Neon, nil, 0.35)
		fill.CFrame = cf * CFrame.new(0, 0, len / 2)
		tween(fill, time, { Size = Vector3.new(w, 0.3, len), CFrame = cf }, Enum.EasingStyle.Linear)
		fadeAfter(rim, time, 0.15)
		fadeAfter(fill, time, 0.15)
	elseif kind == "donut" then
		-- 보스에서 떨어진 고리: 안쪽은 안전 (보스 품으로 파고들어라)
		local at, r0, r1, time = data.at, data.inner, data.outer, data.time or 1
		local outer = groundDisc(at, r1, c, 0.55, 0.25)
		local safe = groundDisc(at, r0, Color3.fromRGB(120, 255, 160), 0.5, 0.3)
		local fill = groundDisc(at, r1, c, 0.8, 0.28)
		tween(fill, time, { Transparency = 0.3 }, Enum.EasingStyle.Linear)
		fadeAfter(outer, time, 0.15)
		fadeAfter(safe, time, 0.15)
		fadeAfter(fill, time, 0.15)
		Fx.text(at + Vector3.new(0, 3, 0), "안으로!", Color3.fromRGB(150, 255, 170), 28, 1)
	elseif kind == "drop" then
		-- 하늘에서 내리찍는 거대한 손바닥 (또는 그 권법의 빛)
		local at, r = data.at, data.radius
		local palm = piece(Vector3.new(r * 1.2, 2, r * 1.5), c, Enum.Material.Neon, nil, 0.2)
		palm.CFrame = CFrame.new(at + Vector3.new(0, 60, 0))
		tween(palm, 0.14, { CFrame = CFrame.new(at + Vector3.new(0, -1, 0)) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		fadeAfter(palm, 0.2, 0.5)
		for i = -2, 2 do
			local fg = piece(Vector3.new(r * 0.18, 1.6, r * 0.6), c2, Enum.Material.Neon, nil, 0.25)
			fg.CFrame = CFrame.new(at + Vector3.new(i * r * 0.22, 60, -r * 1.0))
			tween(fg, 0.14, { CFrame = CFrame.new(at + Vector3.new(i * r * 0.22, -1, -r * 1.0)) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			fadeAfter(fg, 0.2, 0.5)
		end
		task.delay(0.14, function()
			beam(at - Vector3.new(0, 2.4, 0), c2, r * 0.6, 100, 0.5)
			Fx.ring(at - Vector3.new(0, 2.2, 0), c, 3, r * 4, 0.6)
			Fx.ring(at - Vector3.new(0, 2.1, 0), c2, 2, r * 2.4, 0.5)
			Fx.dust(at - Vector3.new(0, 2.4, 0), 7)
			Fx.sound("heavy", 1, 0.5, at)
		end)
	elseif kind == "pillar" then
		-- 땅을 뚫고 솟는 용 기둥
		local at, r = data.at, data.radius
		local p = at - Vector3.new(0, 2.4, 0)
		beam(p, (data.i or 1) % 2 == 0 and c2 or c, r * 0.9, 50, 0.45)
		Fx.ring(p + Vector3.new(0, 0.3, 0), c, 1, r * 2.4, 0.4)
		Fx.dust(p, 3)
		for k = 1, 4 do
			local seg = piece(Vector3.new(1, 1, 1) * (2.2 - k * 0.3), c:Lerp(c2, k / 4), Enum.Material.Neon, Enum.PartType.Ball, 0.1)
			seg.Position = p
			tween(seg, 0.4, { Position = p + Vector3.new(math.cos(k * 1.6) * 2, 12 + k * 7, math.sin(k * 1.6) * 2), Transparency = 1 })
			Debris:AddItem(seg, 0.45)
		end
	elseif kind == "slash" then
		local a, t = data.m and rootPart(data.m), data.t and rootPart(data.t)
		if a and t then
			streak(a.Position, t.Position + (t.Position - a.Position).Unit * 4, c, 0.8, 0.3)
			Fx.afterimage(data.m, Color3.fromRGB(40, 20, 70), 0.35)
			Fx.ring(t.Position, c, 1, 9, 0.3)
		end
	elseif kind == "strike" then
		local at = data.at
		local ground = at - Vector3.new(0, 2.4, 0)
		if data.fx == "star" then
			Fx.starfall(at, data.style)
		elseif data.fx == "fire" then
			-- 하늘에서 떨어지는 불덩이 (화산탄)
			local ball = piece(Vector3.new(4, 4, 4), Color3.fromRGB(255, 140, 40), Enum.Material.Neon, Enum.PartType.Ball, 0)
			local from = ground + Vector3.new(math.random(-14, 14), 70, math.random(-14, 14))
			ball.Position = from
			tween(ball, 0.35, { Position = ground + Vector3.new(0, 1.5, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			streak(from, ground, Color3.fromRGB(255, 90, 20), 1.6, 0.4)
			task.delay(0.35, function()
				ball:Destroy()
				sphere(ground + Vector3.new(0, 1, 0), Color3.fromRGB(255, 120, 30), 2, (data.radius or 6) * 2.2, 0.35, Enum.Material.Neon, 0.2)
				Fx.ring(ground + Vector3.new(0, 0.3, 0), Color3.fromRGB(255, 80, 20), 1, (data.radius or 6) * 2.4, 0.4)
				Fx.dust(ground, 3)
				Fx.sound("heavy", 0.8, 0.8, at)
			end)
			Debris:AddItem(ball, 0.4)
		elseif data.fx == "ice" or data.fx == "blood" or data.fx == "sand" then
			-- 땅에서 솟는 얼음 창 / 핏빛 가시 / 모래 창
			for k = 0, 6 do
				local a = k / 7 * math.pi * 2
				local p = ground + Vector3.new(math.cos(a), 0, math.sin(a)) * (k == 0 and 0 or (data.radius or 6) * 0.55)
				local spike = piece(Vector3.new(1.4, 0.5, 1.4), k % 2 == 0 and c or c2, data.fx == "ice" and Enum.Material.Glass or (data.fx == "sand" and Enum.Material.Sandstone or Enum.Material.Neon), nil, 0.1)
				spike.CFrame = CFrame.new(p) * CFrame.Angles(math.cos(a) * 0.35, 0, math.sin(a) * 0.35)
				tween(spike, 0.12, { Size = Vector3.new(1.4, k == 0 and 11 or 7, 1.4) })
				fadeAfter(spike, 0.35, 0.35)
			end
			Fx.ring(ground + Vector3.new(0, 0.3, 0), c, 1, (data.radius or 6) * 2.2, 0.35)
			Fx.sound("heavy", 0.7, 1.1, at)
		else
			Fx.lightning(ground + Vector3.new(math.random(-6, 6), 70, math.random(-6, 6)), ground, c, data.small and 0.6 or 1.6)
			if not data.small then
				Fx.lightning(ground + Vector3.new(math.random(-6, 6), 70, math.random(-6, 6)), ground, c2, 1)
				beam(ground, c2, data.radius * 0.6, 80, 0.35)
			end
			Fx.ring(ground + Vector3.new(0, 0.3, 0), c, 1, (data.radius or 5) * 2.2, 0.3)
			Fx.sound("heavy", data.small and 0.4 or 0.8, 1.3, at)
		end
	elseif kind == "stormcloud" then
		local cloud = piece(Vector3.new(3, (data.radius or 20) * 2, (data.radius or 20) * 2), Color3.fromRGB(45, 45, 65), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, 0.45)
		follow(data.m, data.dur, { cloud }, function(t, cf)
			return { CFrame.new(cf.Position + Vector3.new(0, 50, 0)) * CFrame.Angles(t * 0.5, 0, math.rad(90)) }
		end, 0.4)
	elseif kind == "freeze" then
		-- 시간이 멈춘다: 잿빛 돔, 멈춘 적은 유리에 갇힌다
		local at, r = data.at, data.radius
		local dome = piece(Vector3.new(4, 4, 4), Color3.fromRGB(220, 220, 235), Enum.Material.Glass, Enum.PartType.Ball, 0.5)
		dome.Position = at
		tween(dome, 0.35, { Size = Vector3.new(r * 2, r * 1.2, r * 2) })
		fadeAfter(dome, data.dur * 0.7, 0.3)
		Fx.ring(at - Vector3.new(0, 2.2, 0), Color3.new(1, 1, 1), 2, r * 2, 0.5)
		for _, m in ipairs(data.targets or {}) do
			local tr = rootPart(m)
			if tr then
				local box = piece(Vector3.new(4.5, 7, 4.5), Color3.fromRGB(200, 220, 255), Enum.Material.Glass, nil, 0.45)
				box.CFrame = tr.CFrame * CFrame.new(0, 0.5, 0)
				fadeAfter(box, data.dur * 0.6, 0.2)
			end
		end
		Fx.sound("deflect", 0.8, 0.5, at)
	elseif kind == "erase" then
		local tr = data.t and rootPart(data.t)
		if tr then
			sphere(tr.Position, Color3.new(1, 1, 1), 2, 14, 0.35, Enum.Material.Neon, 0.2)
			Fx.ring(tr.Position, c, 1, 16, 0.35)
			Fx.spark(tr.Position, Color3.new(1, 1, 1), 2, 10)
		end
	elseif kind == "launch" then
		local at, r = data.at, data.radius
		for k = 0, 4 do
			task.delay(k * 0.06, function()
				Fx.ring(at - Vector3.new(0, 2 - k * 4, 0), k % 2 == 0 and c or c2, 2, r * 2 - k * 4, 0.45)
			end)
		end
		for _ = 1, 14 do
			local a = math.random() * math.pi * 2
			local p = at + Vector3.new(math.cos(a) * r * math.random(), -2, math.sin(a) * r * math.random())
			streak(p, p + Vector3.new(0, 26, 0), c2, 0.5, 0.4)
		end
	elseif kind == "beam" then
		local at, r = data.at, data.radius
		beam(at - Vector3.new(0, 2.4, 0), Color3.new(1, 1, 1), r * 0.6, 160, 0.6)
		beam(at - Vector3.new(0, 2.4, 0), c, r * 1.0, 160, 0.45)
		Fx.ring(at - Vector3.new(0, 2.2, 0), c, 4, r * 3, 0.6)
		Fx.dust(at - Vector3.new(0, 2.4, 0), 8)
	elseif kind == "moving" then
		-- 몸을 따라다니는 꽃잎 폭풍
		local bits = {}
		for i = 1, 26 do
			table.insert(bits, piece(Vector3.new(1, 0.1, 0.7), i % 3 == 0 and Color3.fromRGB(255, 240, 245) or (i % 2 == 0 and c or c2), Enum.Material.SmoothPlastic, nil, 0.05))
		end
		local r = data.radius
		follow(data.m, data.dur, bits, function(t, cf)
			local out = {}
			for i = 1, #bits do
				local a = t * 7 + i / #bits * math.pi * 2
				local rr = r * (0.4 + 0.6 * ((i * 0.53) % 1))
				out[i] = CFrame.new(cf.Position + Vector3.new(math.cos(a) * rr, math.sin(t * 4 + i) * 2.5, math.sin(a) * rr)) * CFrame.Angles(a, t * 5, 0)
			end
			return out
		end, 0.3)
	elseif kind == "trail" then
		for i, p in ipairs(data.points or {}) do
			task.delay(i * 0.05, function()
				Fx.bloom(p - Vector3.new(0, 1.5, 0), data.radius or 6)
				Fx.ring(p - Vector3.new(0, 2.2, 0), c, 1, (data.radius or 6) * 2, 0.35)
			end)
		end
	end
end

------------------------------------------------------------------------
-- 고급 연출: 모든 기술이 함께 쓰는 바탕 (불티·연기·흙먼지 입자, 터지는 빛, 튀는 돌 조각)
-- 기술 자체는 그대로, 맞는 순간·터지는 순간의 질감만 올린다
------------------------------------------------------------------------
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local TEX_FIRE = "rbxasset://textures/particles/fire_main.dds"
local BURST_KINDS: { [string]: any } = {
	-- 날카로운 불티: 빠르게 튀었다가 금방 진다
	spark = { tex = TEX_SPARK, life = { 0.18, 0.42 }, speed = { 22, 48 }, size = { 0.55, 0 }, drag = 7, light = 1, trans = { 0, 1 }, spread = 180 },
	-- 떠오르는 불씨
	ember = { tex = TEX_FIRE, life = { 0.5, 1.1 }, speed = { 4, 12 }, size = { 0.7, 0 }, drag = 2, light = 1, trans = { 0.1, 1 }, spread = 180, accel = Vector3.new(0, 10, 0) },
	-- 피어오르는 연기 (부드럽게 커지며 사라진다)
	smoke = { tex = TEX_SMOKE, life = { 0.9, 1.7 }, speed = { 3, 9 }, size = { 2, 7 }, drag = 3, light = 0, trans = { 0.45, 1 }, spread = 180, rot = 60 },
	-- 땅을 따라 퍼지는 흙먼지
	dust = { tex = TEX_SMOKE, life = { 0.7, 1.3 }, speed = { 14, 30 }, size = { 1.6, 5.5 }, drag = 5, light = 0, trans = { 0.35, 1 }, spread = 90, rot = 40 },
	-- 빛 가루 (오의의 여운)
	glitter = { tex = TEX_SPARK, life = { 0.6, 1.4 }, speed = { 6, 18 }, size = { 0.45, 0 }, drag = 3, light = 1, trans = { 0, 1 }, spread = 180, accel = Vector3.new(0, 3, 0) },
}
local burstFolder = Instance.new("Folder")
burstFolder.Name = "KwonBursts"
burstFolder.Parent = workspace
local burstPool: { [string]: { list: { ParticleEmitter }, i: number } } = {}
local function emitterFor(kind: string): ParticleEmitter?
	local def = BURST_KINDS[kind]
	if not def then
		return nil
	end
	local pool = burstPool[kind]
	if not pool then
		pool = { list = {}, i = 0 }
		for _ = 1, 6 do
			local holder = Instance.new("Part")
			holder.Anchored = true
			holder.CanCollide = false
			holder.CanQuery = false
			holder.CanTouch = false
			holder.Transparency = 1
			holder.Size = Vector3.new(0.2, 0.2, 0.2)
			holder.Parent = burstFolder
			local e = Instance.new("ParticleEmitter")
			e.Texture = def.tex
			e.Rate = 0
			e.Lifetime = NumberRange.new(def.life[1], def.life[2])
			e.Speed = NumberRange.new(def.speed[1], def.speed[2])
			e.Size = NumberSequence.new(def.size[1], def.size[2])
			e.Transparency = NumberSequence.new(def.trans[1], def.trans[2])
			e.Drag = def.drag
			e.LightEmission = def.light
			e.SpreadAngle = Vector2.new(def.spread, def.spread)
			e.Acceleration = def.accel or Vector3.zero
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(-(def.rot or 0), def.rot or 0)
			e.EmissionDirection = Enum.NormalId.Top
			e.Parent = holder
			table.insert(pool.list, e)
		end
		burstPool[kind] = pool
	end
	pool.i = pool.i % #pool.list + 1
	return pool.list[pool.i]
end
function Fx.burst(kind: string, pos: Vector3, color: Color3, n: number, scale: number?)
	local e = emitterFor(kind)
	if not e then
		return
	end
	local def = BURST_KINDS[kind]
	local k = scale or 1
	local holder = e.Parent :: BasePart
	holder.CFrame = CFrame.new(pos)
	e.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), def.light > 0 and 0.5 or 0.15))
	e.Size = NumberSequence.new(def.size[1] * k, def.size[2] * k)
	e.Speed = NumberRange.new(def.speed[1] * math.sqrt(k), def.speed[2] * math.sqrt(k))
	pcall(function()
		e:Emit(math.max(1, math.floor(n)))
	end)
end

-- 터지는 빛: 맞은 자리 둘레를 잠깐 실제로 밝힌다 (미래 조명이라 그림자까지 진다)
local flashPool: { PointLight } = {}
local flashIdx = 0
function Fx.flash(pos: Vector3, color: Color3, range: number, brightness: number, life: number)
	if #flashPool < 8 then
		local holder = Instance.new("Part")
		holder.Anchored = true
		holder.CanCollide = false
		holder.CanQuery = false
		holder.CanTouch = false
		holder.Transparency = 1
		holder.Size = Vector3.new(0.2, 0.2, 0.2)
		holder.Parent = burstFolder
		local l = Instance.new("PointLight")
		l.Brightness = 0
		l.Shadows = false
		l.Parent = holder
		table.insert(flashPool, l)
	end
	flashIdx = flashIdx % #flashPool + 1
	local l = flashPool[flashIdx]
	local holder = l.Parent :: BasePart
	holder.CFrame = CFrame.new(pos)
	l.Color = color
	l.Range = math.min(60, range)
	l.Brightness = brightness
	TweenService:Create(l, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
end

-- 튀는 돌 조각: 포물선을 그리며 날아갔다가 떨어져 사라진다
function Fx.debris(pos: Vector3, n: number, power: number, color: Color3?)
	local ground = color or Color3.fromRGB(120, 110, 100)
	for _ = 1, n do
		local s = 0.4 + math.random() * 0.9
		local chunk = piece(Vector3.new(s, s * 0.7, s * 0.9), ground:Lerp(Color3.new(0, 0, 0), math.random() * 0.3), Enum.Material.Slate, nil, 0)
		chunk.CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		local a = math.random() * math.pi * 2
		local out = Vector3.new(math.cos(a), 0, math.sin(a)) * power * (0.5 + math.random() * 0.6)
		local peak = pos + out * 0.5 + Vector3.new(0, power * (0.4 + math.random() * 0.4), 0)
		local land = pos + out + Vector3.new(0, -0.5, 0)
		local spin = CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		TweenService:Create(chunk, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(peak) * spin }):Play()
		task.delay(0.22, function()
			if chunk.Parent then
				TweenService:Create(chunk, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(land) * spin * spin }):Play()
			end
		end)
		task.delay(0.7, function()
			if chunk.Parent then
				TweenService:Create(chunk, TweenInfo.new(0.4), { Transparency = 1, Size = chunk.Size * 0.5 }):Play()
			end
		end)
		Debris:AddItem(chunk, 1.15)
	end
end

-- 큰 충격: 불티 + 빛 + (크면) 흙먼지 고리 · 돌 조각 · 연기
function Fx.impact(pos: Vector3, color: Color3, scale: number?)
	local k = scale or 1
	Fx.burst("spark", pos, color, 10 * k, math.min(2, 0.8 + k * 0.4))
	Fx.flash(pos, color, 14 + 10 * k, 3 + k, 0.25 + 0.1 * k)
	if k >= 1 then
		local g = pos - Vector3.new(0, 2.2, 0)
		Fx.burst("dust", g, Color3.fromRGB(170, 155, 135), 10 * k, k)
		Fx.debris(g, math.floor(4 + 3 * k), 10 + 6 * k)
	end
	if k >= 2 then
		Fx.burst("smoke", pos, Color3.fromRGB(90, 85, 85), 6 * k, k * 0.8)
		Fx.burst("ember", pos, color, 8 * k, 1)
	end
end

return Fx
