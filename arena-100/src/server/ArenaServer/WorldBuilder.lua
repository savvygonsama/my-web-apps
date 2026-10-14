-- WorldBuilder (ModuleScript, ArenaServer 아래)
-- 조명, 로비 광장, 투기장을 만든다. 맵은 전부 코드로 짓는다.

local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))

local World = {}

local MARBLE = Color3.fromRGB(236, 230, 218)
local MARBLE_DARK = Color3.fromRGB(205, 195, 180)
local GOLD = Color3.fromRGB(222, 178, 72)
local STONE = Color3.fromRGB(92, 82, 76)
local CRIMSON = Color3.fromRGB(150, 35, 40)
local FIRE = Color3.fromRGB(255, 150, 60)
local WOOD_COLOR = Color3.fromRGB(95, 65, 40)

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local parent = props.Parent
	for k, v in pairs(props) do
		if k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end
World.part = part

-- 세로로 선 원기둥 (로블록스 원기둥은 X축이 길이라 돌려서 세운다)
local function pillar(parent: Instance, center: Vector3, height: number, diameter: number, color: Color3, material: Enum.Material): Part
	return part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material,
		Parent = parent,
	})
end

local function disc(parent: Instance, center: Vector3, thickness: number, diameter: number, color: Color3, material: Enum.Material): Part
	return pillar(parent, center, thickness, diameter, color, material)
end

local function torch(parent: Instance, pos: Vector3, size: number, range: number): (Part, Fire)
	local bowl = disc(parent, pos, 0.8 * size, 2.6 * size, Color3.fromRGB(45, 40, 38), Enum.Material.Metal)
	bowl.Name = "Brazier"
	local fire = Instance.new("Fire")
	fire.Size = 5 * size
	fire.Heat = 9
	fire.Color = FIRE
	fire.SecondaryColor = Color3.fromRGB(255, 220, 120)
	fire.Parent = bowl
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 90)
	light.Range = range
	light.Brightness = 2.2
	light.Shadows = true
	light.Parent = bowl
	return bowl, fire
end

local function surfaceText(target: BasePart, face: Enum.NormalId, ppu: number): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = ppu
	gui.LightInfluence = 0
	gui.Parent = target
	return gui
end

local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3, font: Enum.Font): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Font = font
	l.TextScaled = true
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.4
	l.Text = text
	l.Parent = parent
	return l
end

------------------------------------------------------------------------
-- 조명: 노을빛, 네온이 번지게
------------------------------------------------------------------------
function World.setupLighting()
	pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)
	Lighting.ClockTime = 17.4
	Lighting.Brightness = 2.2
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 120, 110)
	Lighting.Ambient = Color3.fromRGB(60, 50, 50)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.7

	local function ensure(className: string, name: string): any
		local existing = Lighting:FindFirstChild(name)
		if existing then
			return existing
		end
		local inst = Instance.new(className)
		inst.Name = name
		inst.Parent = Lighting
		return inst
	end
	local atmosphere = ensure("Atmosphere", "ArenaAtmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(255, 205, 170)
	atmosphere.Decay = Color3.fromRGB(120, 80, 95)
	atmosphere.Glare = 0.4
	atmosphere.Haze = 1.4

	local bloom = ensure("BloomEffect", "ArenaBloom")
	bloom.Intensity = 0.7
	bloom.Size = 28
	bloom.Threshold = 1.1

	local cc = ensure("ColorCorrectionEffect", "ArenaColor")
	cc.Saturation = 0.12
	cc.Contrast = 0.08
	cc.TintColor = Color3.fromRGB(255, 246, 236)

	local rays = ensure("SunRaysEffect", "ArenaSunRays")
	rays.Intensity = 0.06
	rays.Spread = 0.7
end

------------------------------------------------------------------------
-- 로비
------------------------------------------------------------------------
local hallRows: { TextLabel } = {}
local lobbyFolder: Folder? = nil

-- 클라이언트가 돌리고 흔드는 장식 (각자 화면에서 부드럽게 움직인다)
local function tagSpin(p: BasePart, axis: string, speed: number)
	p:SetAttribute("Axis", axis)
	p:SetAttribute("Speed", speed)
	CollectionService:AddTag(p, "ArenaSpin")
end

local function tagBob(p: BasePart, amp: number, speed: number)
	p:SetAttribute("Amp", amp)
	p:SetAttribute("BobSpeed", speed)
	p:SetAttribute("Phase", math.random() * math.pi * 2)
	CollectionService:AddTag(p, "ArenaBob")
end

local function prompt(parent: Instance, action: string, object: string, onUse: (Player) -> ())
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp.Parent = parent
	pp.Triggered:Connect(onUse)
end

-- 톱니바퀴: 가운데 원판(고정) + 둘레 톱니(용접). 원판을 돌리면 톱니도 같이 돈다
local function gear(parent: Instance, cf: CFrame, diameter: number, color: Color3, speed: number, name: string)
	local center = part({
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.7, diameter, diameter),
		CFrame = cf,
		Color = color,
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	part({
		Name = name .. "Hub",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.9, diameter * 0.3, diameter * 0.3),
		CFrame = cf,
		Color = GOLD,
		Material = Enum.Material.Metal,
		Anchored = false,
		Massless = true,
		CanCollide = false,
		Parent = parent,
	})
	local teeth = 12
	for i = 0, teeth - 1 do
		local a = (i / teeth) * math.pi * 2
		local r = diameter / 2 + 0.3
		local tooth = part({
			Name = name .. "Tooth",
			Size = Vector3.new(0.7, 0.7, 0.9),
			CFrame = cf * CFrame.Angles(a, 0, 0) * CFrame.new(0, r, 0),
			Color = color,
			Material = Enum.Material.Metal,
			Anchored = false,
			Massless = true,
			CanCollide = false,
			Parent = parent,
		})
		local w = Instance.new("WeldConstraint")
		w.Part0 = center
		w.Part1 = tooth
		w.Parent = tooth
	end
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == name .. "Hub" and child:IsA("BasePart") and not child:FindFirstChildOfClass("WeldConstraint") then
			local w = Instance.new("WeldConstraint")
			w.Part0 = center
			w.Part1 = child
			w.Parent = child
		end
	end
	tagSpin(center, "X", speed)
	return center
end

-- 합성 용광로: 불을 뿜는 화로, 돌아가는 톱니, 빛나는 약물 탱크, 모루
local function buildForge(lobby: Instance, onUse: (Player) -> ())
	local model = Instance.new("Model")
	model.Name = "Forge"
	model.Parent = lobby
	local base = Vector3.new(28, 0, 12)
	local cf = CFrame.lookAt(base, Vector3.new(0, 0, 0))
	local IRON = Color3.fromRGB(58, 52, 52)
	local COPPER = Color3.fromRGB(190, 110, 60)

	part({ Name = "Platform", Size = Vector3.new(20, 1, 17), CFrame = cf * CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(60, 55, 52), Material = Enum.Material.Slate, Parent = model })
	part({ Name = "PlatformTrim", Size = Vector3.new(20.4, 0.3, 17.4), CFrame = cf * CFrame.new(0, 0.9, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = model })

	-- 화로 몸통
	pillar(model, (cf * CFrame.new(0, 6, 2.5)).Position, 10, 9, IRON, Enum.Material.Metal)
	for _, y in ipairs({ 2.6, 9.2 }) do
		pillar(model, (cf * CFrame.new(0, y, 2.5)).Position, 0.6, 9.5, GOLD, Enum.Material.Metal)
	end
	local lava = disc(model, (cf * CFrame.new(0, 11.05, 2.5)).Position, 0.2, 7.4, Color3.fromRGB(255, 120, 30), Enum.Material.Neon)
	lava.Name = "ForgeLava"
	local lavaFire = Instance.new("Fire")
	lavaFire.Size = 7
	lavaFire.Heat = 12
	lavaFire.Color = Color3.fromRGB(255, 120, 30)
	lavaFire.SecondaryColor = Color3.fromRGB(255, 220, 90)
	lavaFire.Parent = lava

	-- 화구: 앞쪽으로 붉게 열린 입
	local mouth = part({
		Name = "ForgeMouth",
		Size = Vector3.new(4.4, 3.4, 0.6),
		CFrame = cf * CFrame.new(0, 4.2, -2.1),
		Color = Color3.fromRGB(255, 110, 25),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	part({ Name = "MouthFrame", Size = Vector3.new(5.4, 0.5, 0.8), CFrame = cf * CFrame.new(0, 6.1, -2.1), Color = GOLD, Material = Enum.Material.Metal, Parent = model })
	local glow = Instance.new("PointLight")
	glow.Name = "ForgeGlow"
	glow.Color = Color3.fromRGB(255, 140, 50)
	glow.Range = 26
	glow.Brightness = 3
	glow.Shadows = true
	glow.Parent = mouth
	local embers = Instance.new("ParticleEmitter")
	embers.Name = "Embers"
	embers.Rate = 14
	embers.Lifetime = NumberRange.new(1, 2)
	embers.Speed = NumberRange.new(3, 6)
	embers.EmissionDirection = Enum.NormalId.Front
	embers.SpreadAngle = Vector2.new(35, 35)
	embers.Acceleration = Vector3.new(0, 4, 0)
	embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	embers.LightEmission = 1
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 220, 100), Color3.fromRGB(255, 80, 30))
	embers.Parent = mouth

	-- 굴뚝과 연기
	pillar(model, (cf * CFrame.new(2.2, 14.5, 4)).Position, 7, 2.4, IRON, Enum.Material.Metal)
	local chimneyTop = pillar(model, (cf * CFrame.new(2.2, 18.1, 4)).Position, 0.4, 2.9, GOLD, Enum.Material.Metal)
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(90, 80, 80)
	smoke.Opacity = 0.15
	smoke.RiseVelocity = 6
	smoke.Size = 3
	smoke.Parent = chimneyTop

	-- 톱니바퀴 둘
	gear(model, cf * CFrame.new(5.6, 6.2, 2.5), 6, Color3.fromRGB(150, 120, 70), 0.9, "GearBig")
	gear(model, cf * CFrame.new(5.6, 10.6, -0.6), 3.6, COPPER, -1.6, "GearSmall")

	-- 빛나는 약물 탱크와 관
	local tankPos = (cf * CFrame.new(-6.4, 4.6, 2)).Position
	local liquid = pillar(model, tankPos - Vector3.new(0, 0.6, 0), 5.4, 2.8, Color3.fromRGB(170, 90, 255), Enum.Material.Neon)
	liquid.Name = "ForgeLiquid"
	local glass = pillar(model, tankPos, 7.2, 3.4, Color3.fromRGB(200, 230, 255), Enum.Material.Glass)
	glass.Transparency = 0.55
	glass.Name = "ForgeTank"
	pillar(model, tankPos + Vector3.new(0, 3.8, 0), 0.5, 3.8, GOLD, Enum.Material.Metal)
	pillar(model, tankPos - Vector3.new(0, 3.8, 0), 0.5, 3.8, GOLD, Enum.Material.Metal)
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Rate = 6
	bubbles.Lifetime = NumberRange.new(1.2, 2)
	bubbles.Speed = NumberRange.new(1.5, 2.5)
	bubbles.EmissionDirection = Enum.NormalId.Top
	bubbles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0.1) })
	bubbles.LightEmission = 0.8
	bubbles.Color = ColorSequence.new(Color3.fromRGB(230, 200, 255))
	bubbles.Parent = liquid
	local tankLight = Instance.new("PointLight")
	tankLight.Color = Color3.fromRGB(170, 90, 255)
	tankLight.Range = 12
	tankLight.Brightness = 1.5
	tankLight.Parent = liquid
	part({
		Name = "Pipe",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3.4, 0.8, 0.8),
		CFrame = cf * CFrame.new(-3.4, 7.6, 2),
		Color = COPPER,
		Material = Enum.Material.Metal,
		Parent = model,
	})

	-- 모루와 바닥 마법진
	local anvilPos = cf * CFrame.new(0, 0, -6.2)
	part({ Name = "AnvilBase", Size = Vector3.new(1.6, 1.8, 1.6), CFrame = anvilPos * CFrame.new(0, 1.9, 0), Color = IRON, Material = Enum.Material.Metal, Parent = model })
	local anvil = part({ Name = "ForgeAnvil", Size = Vector3.new(3.8, 0.9, 1.7), CFrame = anvilPos * CFrame.new(0, 3.2, 0), Color = Color3.fromRGB(75, 75, 82), Material = Enum.Material.Metal, Parent = model })
	part({ Name = "AnvilHorn", Size = Vector3.new(1.2, 0.5, 0.5), CFrame = anvilPos * CFrame.new(2.4, 3.35, 0), Color = Color3.fromRGB(75, 75, 82), Material = Enum.Material.Metal, Parent = model })
	local ring = disc(model, (anvilPos * CFrame.new(0, 1.05, 0)).Position, 0.06, 7, GOLD, Enum.Material.Neon)
	ring.Name = "ForgeRing"
	ring.Transparency = 0.4
	ring.CanCollide = false
	prompt(anvil, "합성하기", "합성 용광로", onUse)

	-- 간판
	local sign = part({ Name = "ForgeSign", Size = Vector3.new(9, 1.8, 0.3), CFrame = cf * CFrame.new(0, 8.2, -2.4), Color = Color3.fromRGB(45, 30, 22), Material = Enum.Material.Wood, Parent = model })
	local gui = surfaceText(sign, Enum.NormalId.Front, 40)
	label(gui, "🔨 합성 용광로", UDim2.fromScale(0, 0.05), UDim2.fromScale(1, 0.9), Color3.fromRGB(255, 200, 90), Enum.Font.GothamBlack)
end

-- 무기 전시대: 구간 1~6의 무기가 받침대 위에서 떠서 돈다
local function buildShowcase(lobby: Instance)
	local model = Instance.new("Model")
	model.Name = "Showcase"
	model.Parent = lobby
	local types = { 1, 2, 3, 4, 5, 0 }
	for i = 1, 6 do
		local section = Config.Sections[i]
		local a = math.rad(62 + (i - 1) * 11.2)
		local pos = Vector3.new(math.cos(a) * 31, 0, math.sin(a) * 31)
		local face = CFrame.lookAt(pos, Vector3.new(0, 0, 0))
		pillar(model, pos + Vector3.new(0, 0.8, 0), 0.7, 3.8, GOLD, Enum.Material.Metal)
		local column = part({ Name = "ShowColumn", Size = Vector3.new(2.6, 3.4, 2.6), CFrame = face * CFrame.new(0, 2.85, 0), Color = MARBLE, Material = Enum.Material.Marble, Parent = model })
		local top = disc(model, pos + Vector3.new(0, 4.62, 0), 0.15, 3, section.color, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = section.color
		light.Range = 10
		light.Brightness = 1.5
		light.Parent = top
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Rate = 3 + i
		sparkle.Lifetime = NumberRange.new(1, 2)
		sparkle.Speed = NumberRange.new(1, 2)
		sparkle.EmissionDirection = Enum.NormalId.Right
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
		sparkle.LightEmission = 1
		sparkle.Color = section.rainbow and WeaponBuilder.RAINBOW or ColorSequence.new(section.color)
		sparkle.Parent = top

		local anchor = part({
			Name = "ShowAnchor",
			Size = Vector3.new(0.4, 0.4, 0.4),
			CFrame = CFrame.new(pos + Vector3.new(0, 6.8, 0)),
			Transparency = 1,
			CanCollide = false,
			Parent = model,
		})
		WeaponBuilder.build(model, anchor, types[i], {
			accent = section.rainbow and Color3.fromRGB(255, 235, 160) or section.color,
			section = i,
			rarity = 5,
			scale = 0.85,
		}, CFrame.new(anchor.Position - Vector3.new(0, 2.6, 0)))
		tagSpin(anchor, "Y", 0.7)
		tagBob(anchor, 0.35, 1.4)

		local gui = surfaceText(column, Enum.NormalId.Front, 50)
		label(gui, string.format("%d구간", i), UDim2.fromScale(0, 0.08), UDim2.fromScale(1, 0.3), section.color, Enum.Font.GothamBlack)
		label(gui, section.name, UDim2.fromScale(0.05, 0.42), UDim2.fromScale(0.9, 0.22), Color3.fromRGB(70, 55, 40), Enum.Font.GothamBold)
		label(gui, string.format("%d~%d등급", section.from, section.to), UDim2.fromScale(0.05, 0.68), UDim2.fromScale(0.9, 0.18), Color3.fromRGB(110, 95, 80), Enum.Font.GothamBold)
	end
end

-- 훈련장: 허수아비 세 개와 무기 걸이
local function buildTrainingYard(lobby: Instance, onUse: (Player) -> ())
	local model = Instance.new("Model")
	model.Name = "TrainingYard"
	model.Parent = lobby
	local center = Vector3.new(-28, 0, 12)
	local cf = CFrame.lookAt(center, Vector3.new(0, 0, 0))
	disc(model, center + Vector3.new(0, 0.48, 0), 0.1, 18, Color3.fromRGB(205, 175, 120), Enum.Material.Sand)
	disc(model, center + Vector3.new(0, 0.46, 0), 0.1, 19, Color3.fromRGB(120, 85, 50), Enum.Material.Wood)
	local STRAW = Color3.fromRGB(214, 180, 105)
	local mainDummy: BasePart? = nil
	for i, x in ipairs({ -5, 0, 5 }) do
		local d = cf * CFrame.new(x, 0, (i == 2) and -1.5 or 0)
		pillar(model, (d * CFrame.new(0, 3.3, 0)).Position, 6, 0.6, WOOD_COLOR, Enum.Material.Wood)
		local body = part({ Name = "DummyBody", Size = Vector3.new(2.2, 2.6, 1.3), CFrame = d * CFrame.new(0, 4.3, 0), Color = STRAW, Material = Enum.Material.Fabric, Parent = model })
		part({ Name = "DummyHead", Shape = Enum.PartType.Ball, Size = Vector3.new(1.7, 1.7, 1.7), CFrame = d * CFrame.new(0, 6.4, 0), Color = STRAW, Material = Enum.Material.Fabric, Parent = model })
		part({ Name = "DummyArms", Size = Vector3.new(4.4, 0.5, 0.5), CFrame = d * CFrame.new(0, 5, 0), Color = WOOD_COLOR, Material = Enum.Material.Wood, Parent = model })
		part({
			Name = "DummyTarget",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.1, 1.2, 1.2),
			CFrame = d * CFrame.new(0, 4.5, -0.7) * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromRGB(220, 50, 40),
			Material = Enum.Material.Neon,
			Parent = model,
		})
		for _, y in ipairs({ 3.5, 5.1 }) do
			part({ Name = "Rope", Size = Vector3.new(2.3, 0.15, 1.4), CFrame = d * CFrame.new(0, y, 0), Color = Color3.fromRGB(120, 85, 50), Material = Enum.Material.Fabric, Parent = model })
		end
		if i == 2 then
			mainDummy = body
		end
	end
	-- 무기 걸이
	local rack = cf * CFrame.new(0, 0, 6.5)
	for _, x in ipairs({ -3.5, 3.5 }) do
		part({ Name = "RackPost", Size = Vector3.new(0.5, 4, 0.5), CFrame = rack * CFrame.new(x, 2.5, 0), Color = WOOD_COLOR, Material = Enum.Material.Wood, Parent = model })
	end
	local bar = part({ Name = "RackBar", Size = Vector3.new(7.6, 0.4, 0.4), CFrame = rack * CFrame.new(0, 4.3, 0), Color = WOOD_COLOR, Material = Enum.Material.Wood, Parent = model })
	for i, t in ipairs({ 1, 3, 5 }) do
		local holder = part({
			Name = "RackHook",
			Size = Vector3.new(0.3, 0.3, 0.3),
			CFrame = rack * CFrame.new(-2.4 + (i - 1) * 2.4, 4.3, -0.4),
			Transparency = 1,
			CanCollide = false,
			Parent = model,
		})
		WeaponBuilder.build(model, holder, t, { accent = Color3.fromRGB(190, 190, 190), section = 1, rarity = 1, scale = 0.6 }, holder.CFrame * CFrame.Angles(math.rad(180), 0, 0))
	end
	local _ = bar
	local sign = part({ Name = "TrainSign", Size = Vector3.new(7, 1.6, 0.3), CFrame = cf * CFrame.new(0, 8.6, 1), Color = Color3.fromRGB(45, 30, 22), Material = Enum.Material.Wood, Parent = model })
	part({ Name = "SignPost", Size = Vector3.new(0.4, 8.4, 0.4), CFrame = cf * CFrame.new(0, 4.2, 1.3), Color = WOOD_COLOR, Material = Enum.Material.Wood, Parent = model })
	local gui = surfaceText(sign, Enum.NormalId.Front, 40)
	label(gui, "💪 훈련장", UDim2.fromScale(0, 0.05), UDim2.fromScale(1, 0.9), Color3.fromRGB(255, 220, 140), Enum.Font.GothamBlack)
	if mainDummy then
		prompt(mainDummy, "훈련하기", "훈련장", onUse)
	end
end

-- 반딧불과 떠다니는 등불
local function buildAmbient(lobby: Instance)
	local area = part({
		Name = "Fireflies",
		Size = Vector3.new(90, 8, 90),
		Position = Vector3.new(0, 7, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = lobby,
	})
	local flies = Instance.new("ParticleEmitter")
	flies.Rate = 22
	flies.Lifetime = NumberRange.new(4, 7)
	flies.Speed = NumberRange.new(0.2, 0.8)
	flies.SpreadAngle = Vector2.new(180, 180)
	flies.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 0.22),
		NumberSequenceKeypoint.new(0.8, 0.22),
		NumberSequenceKeypoint.new(1, 0),
	})
	flies.LightEmission = 1
	flies.Color = ColorSequence.new(Color3.fromRGB(255, 225, 140))
	flies.Parent = area

	for i = 1, 10 do
		local a = (i / 10) * math.pi * 2 + 0.3
		local r = 22 + (i % 3) * 6
		local lantern = part({
			Name = "Lantern",
			Size = Vector3.new(1.3, 1.7, 1.3),
			Position = Vector3.new(math.cos(a) * r, 15 + (i % 4) * 2, math.sin(a) * r),
			Color = Color3.fromRGB(255, 190, 110),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = lobby,
		})
		local cap = part({
			Name = "LanternCap",
			Size = Vector3.new(1.6, 0.3, 1.6),
			CFrame = lantern.CFrame * CFrame.new(0, 1, 0),
			Color = Color3.fromRGB(120, 40, 35),
			Material = Enum.Material.Fabric,
			Anchored = false,
			Massless = true,
			CanCollide = false,
			Parent = lobby,
		})
		local w = Instance.new("WeldConstraint")
		w.Part0 = lantern
		w.Part1 = cap
		w.Parent = cap
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 180, 100)
		light.Range = 12
		light.Brightness = 1.2
		light.Parent = lantern
		tagBob(lantern, 0.8, 0.6 + (i % 3) * 0.2)
	end
end

function World.buildLobby(handlers: { [string]: (Player) -> () }): CFrame
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	folder.Parent = workspace
	lobbyFolder = folder

	-- 바닥 (Baseplate가 없을 때만)
	if not workspace:FindFirstChild("Baseplate") then
		part({
			Name = "Baseplate",
			Size = Vector3.new(500, 2, 500),
			Position = Vector3.new(0, -1, 0),
			Color = Color3.fromRGB(86, 118, 70),
			Material = Enum.Material.Grass,
			Parent = workspace,
		})
	end

	-- 원형 대리석 광장과 금테
	disc(folder, Vector3.new(0, 0, 0), 0.6, 98, GOLD, Enum.Material.Metal)
	disc(folder, Vector3.new(0, 0.05, 0), 0.8, 94, MARBLE, Enum.Material.Marble)
	disc(folder, Vector3.new(0, 0.46, 0), 0.04, 32, CRIMSON, Enum.Material.Slate)
	disc(folder, Vector3.new(0, 0.48, 0), 0.04, 28, MARBLE_DARK, Enum.Material.Marble)
	for i = 0, 7 do
		local a = (i / 8) * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local mid = dir * 30 + Vector3.new(0, 0.47, 0)
		part({
			Name = "Spoke",
			Size = Vector3.new(0.6, 0.04, 28),
			CFrame = CFrame.lookAt(mid, mid + dir),
			Color = GOLD,
			Material = Enum.Material.Metal,
			Parent = folder,
		})
	end

	-- 시작 지점
	local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if not spawn then
		local sp = Instance.new("SpawnLocation")
		sp.Name = "LobbySpawn"
		sp.Anchored = true
		sp.Size = Vector3.new(14, 1, 14)
		sp.Position = Vector3.new(0, 0.5, 0)
		sp.Neutral = true
		sp.Duration = 0
		sp.Parent = workspace
		spawn = sp
	end
	if spawn then
		spawn.Color = GOLD
		spawn.Material = Enum.Material.Marble
		local decal = spawn:FindFirstChildOfClass("Decal")
		if decal then
			decal:Destroy()
		end
	end

	-- 기둥 12개: 짝수는 횃불, 홀수는 구간 깃발
	local sectionIndex = 0
	for i = 0, 11 do
		local deg = 15 + i * 30
		local a = math.rad(deg)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local base = dir * 42
		part({
			Name = "ColumnBase",
			Size = Vector3.new(4.6, 1.2, 4.6),
			Position = base + Vector3.new(0, 1.05, 0),
			Color = MARBLE_DARK,
			Material = Enum.Material.Marble,
			Parent = folder,
		})
		pillar(folder, base + Vector3.new(0, 1.65 + 9, 0), 18, 2.8, MARBLE, Enum.Material.Marble)
		part({
			Name = "ColumnCap",
			Size = Vector3.new(4.6, 1.2, 4.6),
			Position = base + Vector3.new(0, 1.65 + 18 + 0.6, 0),
			Color = GOLD,
			Material = Enum.Material.Metal,
			Parent = folder,
		})
		if i % 2 == 0 then
			torch(folder, base + Vector3.new(0, 21.33, 0), 1.2, 26)
		else
			sectionIndex += 1
			local section = Config.Sections[sectionIndex]
			if section then
				local inward = -dir
				local bannerPos = base + inward * 1.7 + Vector3.new(0, 12.5, 0)
				local banner = part({
					Name = "SectionBanner",
					Size = Vector3.new(4.2, 11, 0.2),
					CFrame = CFrame.lookAt(bannerPos, bannerPos + inward),
					Color = section.color:Lerp(Color3.new(0, 0, 0), 0.3),
					Material = Enum.Material.Fabric,
					CanCollide = false,
					Parent = folder,
				})
				part({
					Name = "BannerRod",
					Size = Vector3.new(5.2, 0.3, 0.3),
					CFrame = banner.CFrame * CFrame.new(0, 5.6, 0),
					Color = GOLD,
					Material = Enum.Material.Metal,
					Parent = folder,
				})
				local gui = surfaceText(banner, Enum.NormalId.Front, 40)
				label(gui, tostring(sectionIndex), UDim2.new(0, 0, 0.06, 0), UDim2.new(1, 0, 0.22, 0), GOLD, Enum.Font.GothamBlack)
				label(gui, section.name, UDim2.new(0.05, 0, 0.34, 0), UDim2.new(0.9, 0, 0.16, 0), Color3.new(1, 1, 1), Enum.Font.GothamBlack)
				label(
					gui,
					string.format("%d ~ %d", section.from, section.to),
					UDim2.new(0.1, 0, 0.56, 0),
					UDim2.new(0.8, 0, 0.1, 0),
					Color3.fromRGB(240, 230, 210),
					Enum.Font.GothamBold
				)
				label(
					gui,
					Config.getGrade(section.to).en,
					UDim2.new(0.05, 0, 0.74, 0),
					UDim2.new(0.9, 0, 0.12, 0),
					section.color:Lerp(Color3.new(1, 1, 1), 0.5),
					Enum.Font.GothamBold
				)
			end
		end
	end

	-- 투기장 입구 문
	local gateZ = -56
	for _, x in ipairs({ -15, 15 }) do
		part({
			Name = "GatePillar",
			Size = Vector3.new(6, 30, 6),
			Position = Vector3.new(x, 15, gateZ),
			Color = STONE,
			Material = Enum.Material.Slate,
			Parent = folder,
		})
		part({
			Name = "GatePillarTrim",
			Size = Vector3.new(6.4, 1, 6.4),
			Position = Vector3.new(x, 1, gateZ),
			Color = GOLD,
			Material = Enum.Material.Metal,
			Parent = folder,
		})
		torch(folder, Vector3.new(x, 37.7, gateZ), 1.5, 34)
	end
	local beam = part({
		Name = "GateBeam",
		Size = Vector3.new(38, 7, 7),
		Position = Vector3.new(0, 33.5, gateZ),
		Color = STONE,
		Material = Enum.Material.Slate,
		Parent = folder,
	})
	for _, y in ipairs({ 30.2, 36.8 }) do
		part({
			Name = "GateTrim",
			Size = Vector3.new(38.2, 0.5, 7.2),
			Position = Vector3.new(0, y, gateZ),
			Color = GOLD,
			Material = Enum.Material.Neon,
			Parent = folder,
		})
	end
	local signGui = surfaceText(beam, Enum.NormalId.Back, 24)
	label(signGui, Config.GAME_TITLE, UDim2.new(0, 0, 0.08, 0), UDim2.new(1, 0, 0.62, 0), Color3.fromRGB(255, 205, 80), Enum.Font.GothamBlack)
	label(signGui, "투기장 입구", UDim2.new(0, 0, 0.7, 0), UDim2.new(1, 0, 0.24, 0), Color3.fromRGB(245, 235, 215), Enum.Font.GothamBold)

	local portal = part({
		Name = "GatePortal",
		Size = Vector3.new(24, 29, 0.4),
		Position = Vector3.new(0, 15, gateZ),
		Color = Color3.fromRGB(255, 90, 50),
		Material = Enum.Material.Neon,
		Transparency = 0.7,
		CanCollide = false,
		Parent = folder,
	})
	local embers = Instance.new("ParticleEmitter")
	embers.Rate = 30
	embers.Lifetime = NumberRange.new(2, 3.5)
	embers.Speed = NumberRange.new(2, 4)
	embers.EmissionDirection = Enum.NormalId.Top
	embers.SpreadAngle = Vector2.new(20, 20)
	embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	embers.LightEmission = 1
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 80, 40))
	embers.Parent = portal
	local gatePrompt = Instance.new("ProximityPrompt")
	gatePrompt.ActionText = "투기장 입장"
	gatePrompt.ObjectText = Config.GAME_TITLE
	gatePrompt.HoldDuration = 0
	gatePrompt.MaxActivationDistance = 20
	gatePrompt.RequiresLineOfSight = false
	gatePrompt.Parent = portal
	gatePrompt.Triggered:Connect(handlers.gate)

	-- 광장에서 문까지 붉은 융단
	part({
		Name = "Carpet",
		Size = Vector3.new(10, 0.1, 13),
		Position = Vector3.new(0, 0.5, -49.5),
		Color = CRIMSON,
		Material = Enum.Material.Fabric,
		Parent = folder,
	})

	-- 명예의 전당 게시판
	local boardPos = Vector3.new(24, 0, -16)
	local boardCf = CFrame.lookAt(boardPos + Vector3.new(0, 8, 0), Vector3.new(0, 8, 0))
	for _, x in ipairs({ -7.6, 7.6 }) do
		part({
			Name = "BoardPost",
			Size = Vector3.new(0.9, 14, 0.9),
			CFrame = boardCf * CFrame.new(x, -1, 0.2),
			Color = Color3.fromRGB(60, 42, 30),
			Material = Enum.Material.Wood,
			Parent = folder,
		})
	end
	local board = part({
		Name = "HallOfFame",
		Size = Vector3.new(15, 10, 0.6),
		CFrame = boardCf,
		Color = Color3.fromRGB(35, 26, 22),
		Material = Enum.Material.Wood,
		Parent = folder,
	})
	for _, spec in ipairs({
		{ Vector3.new(15.6, 0.4, 0.8), CFrame.new(0, 5.1, 0) },
		{ Vector3.new(15.6, 0.4, 0.8), CFrame.new(0, -5.1, 0) },
		{ Vector3.new(0.4, 10.6, 0.8), CFrame.new(7.6, 0, 0) },
		{ Vector3.new(0.4, 10.6, 0.8), CFrame.new(-7.6, 0, 0) },
	}) do
		part({
			Name = "BoardFrame",
			Size = spec[1],
			CFrame = boardCf * spec[2],
			Color = GOLD,
			Material = Enum.Material.Neon,
			Parent = folder,
		})
	end
	local hallGui = surfaceText(board, Enum.NormalId.Front, 40)
	label(hallGui, "🏆 명예의 전당", UDim2.new(0, 0, 0.03, 0), UDim2.new(1, 0, 0.17, 0), GOLD, Enum.Font.GothamBlack)
	label(hallGui, "이 서버 최고 기록", UDim2.new(0, 0, 0.2, 0), UDim2.new(1, 0, 0.07, 0), Color3.fromRGB(200, 185, 165), Enum.Font.GothamBold)
	hallRows = {}
	for i = 1, 5 do
		local row = label(
			hallGui,
			"",
			UDim2.new(0.06, 0, 0.29 + (i - 1) * 0.135, 0),
			UDim2.new(0.88, 0, 0.11, 0),
			Color3.fromRGB(240, 230, 210),
			Enum.Font.GothamBold
		)
		row.TextXAlignment = Enum.TextXAlignment.Left
		hallRows[i] = row
	end

	-- 동상 받침대 (동상은 buildStatue에서 올린다)
	local statueBase = Vector3.new(-24, 0, -16)
	part({ Name = "PedestalBase", Size = Vector3.new(10, 1.2, 10), Position = statueBase + Vector3.new(0, 1.05, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = folder })
	local body = part({ Name = "Pedestal", Size = Vector3.new(8.5, 5, 8.5), Position = statueBase + Vector3.new(0, 4.15, 0), Color = MARBLE, Material = Enum.Material.Marble, Parent = folder })
	part({ Name = "PedestalTop", Size = Vector3.new(10, 0.8, 10), Position = statueBase + Vector3.new(0, 7.05, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = folder })
	local plaque = surfaceText(body, Enum.NormalId.Right, 40)
	label(plaque, "CHAMPION", UDim2.new(0, 0, 0.2, 0), UDim2.new(1, 0, 0.3, 0), GOLD, Enum.Font.GothamBlack)
	label(plaque, "100등급의 끝에 선 자", UDim2.new(0, 0, 0.55, 0), UDim2.new(1, 0, 0.2, 0), Color3.fromRGB(80, 60, 40), Enum.Font.GothamBold)

	buildForge(folder, handlers.forge)
	buildShowcase(folder)
	buildTrainingYard(folder, handlers.train)
	buildAmbient(folder)

	if spawn then
		return CFrame.new(spawn.Position + Vector3.new(0, 4, 0))
	end
	return CFrame.new(0, 4, 0)
end

-- 황금 검투사 동상. 인형을 못 만들면 받침대에 거대한 검만 꽂는다
function World.buildStatue(rig: Model?)
	local folder = lobbyFolder or workspace
	local basePos = Vector3.new(-24, 7.45, -16)
	local ok, err = pcall(function()
		if not rig then
			error("인형 없음")
		end
		local statue = (rig :: Model):Clone()
		statue.Name = "ChampionStatue"
		local hum = statue:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		local root = statue:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			error("루트 없음")
		end
		statue:ScaleTo(3)
		for _, d in ipairs(statue:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = (d == root)
			end
		end
		statue:PivotTo(CFrame.lookAt(basePos + Vector3.new(0, 10, 0), Vector3.new(0, basePos.Y + 10, 0)))
		statue.Parent = folder
		-- 칼 든 오른팔을 하늘로
		local upperArm = statue:FindFirstChild("RightUpperArm")
		local shoulder = upperArm and upperArm:FindFirstChild("RightShoulder")
		if shoulder and shoulder:IsA("Motor6D") then
			shoulder.C0 = shoulder.C0 * CFrame.Angles(math.rad(150), 0, 0)
		end
		task.wait(0.2)
		local bbCf, bbSize = statue:GetBoundingBox()
		local bottom = bbCf.Position.Y - bbSize.Y / 2
		statue:PivotTo(statue:GetPivot() + Vector3.new(0, basePos.Y - bottom, 0))
		for _, d in ipairs(statue:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				if d ~= root then
					d.Color = GOLD
					d.Material = Enum.Material.Metal
					d.Reflectance = 0.15
				end
			end
		end
		local hand = statue:FindFirstChild("RightHand")
		if hand and hand:IsA("BasePart") then
			local yaw = select(2, statue:GetPivot():ToEulerAnglesYXZ())
			local grip = CFrame.new(hand.Position) * CFrame.Angles(0, yaw, 0)
			WeaponBuilder.build(statue, hand, 0, { accent = GOLD, section = 4, rarity = 5, scale = 2.4 }, grip)
		end
	end)
	if not ok then
		warn("[Arena] 동상 대신 검을 세웁니다:", err)
		local anchor = part({
			Name = "SwordAnchor",
			Size = Vector3.new(1, 1, 1),
			Position = basePos + Vector3.new(0, 0.5, 0),
			Transparency = 1,
			CanCollide = false,
			Parent = folder,
		})
		WeaponBuilder.build(folder, anchor, 1, { accent = GOLD, section = 4, rarity = 5, scale = 3 }, CFrame.new(anchor.Position + Vector3.new(0, 4, 0)))
	end
end

function World.setHallOfFame(entries: { { name: string, stage: number } })
	for i, row in ipairs(hallRows) do
		local e = entries[i]
		if e then
			local medal = (i == 1 and "🥇") or (i == 2 and "🥈") or (i == 3 and "🥉") or ("  " .. i .. ".")
			row.Text = string.format("%s  %s  ·  [%d] %s", medal, e.name, e.stage, Config.getGrade(e.stage).en)
			row.TextColor3 = Config.getSection(e.stage).color:Lerp(Color3.new(1, 1, 1), 0.3)
		else
			row.Text = ""
		end
	end
end

------------------------------------------------------------------------
-- 투기장
------------------------------------------------------------------------
export type Arena = {
	center: Vector3,
	model: Model,
	trim: { BasePart },
	banners: { BasePart },
	fires: { Fire },
}

local CROWD_COLORS = {
	Color3.fromRGB(220, 80, 70),
	Color3.fromRGB(70, 130, 220),
	Color3.fromRGB(240, 200, 80),
	Color3.fromRGB(90, 190, 110),
	Color3.fromRGB(200, 120, 220),
	Color3.fromRGB(245, 245, 245),
}

function World.buildArena(center: Vector3, radius: number, name: string): Arena
	local model = Instance.new("Model")
	model.Name = name
	local arena: Arena = { center = center, model = model, trim = {}, banners = {}, fires = {} }

	disc(model, center - Vector3.new(0, 2, 0), 4, radius * 2, Color3.fromRGB(212, 182, 128), Enum.Material.Sand)
	local ring = disc(model, center + Vector3.new(0, 0.03, 0), 0.12, 30, Color3.fromRGB(255, 200, 80), Enum.Material.Neon)
	ring.CanCollide = false
	table.insert(arena.trim, ring)
	local inner = disc(model, center + Vector3.new(0, 0.06, 0), 0.12, 27, Color3.fromRGB(120, 50, 40), Enum.Material.Slate)
	inner.CanCollide = false

	local segments = 36
	local segWidth = 2 * radius * math.sin(math.pi / segments) + 1
	for i = 1, segments do
		local a = (i / segments) * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local wallPos = center + dir * radius + Vector3.new(0, 6, 0)
		local wallCf = CFrame.lookAt(wallPos, Vector3.new(center.X, wallPos.Y, center.Z))
		part({ Name = "Wall", Size = Vector3.new(segWidth, 12, 2), CFrame = wallCf, Color = STONE, Material = Enum.Material.Cobblestone, Parent = model })
		local trim = part({
			Name = "WallTrim",
			Size = Vector3.new(segWidth, 0.5, 2.3),
			CFrame = wallCf * CFrame.new(0, 6.1, 0),
			Color = Color3.fromRGB(255, 200, 80),
			Material = Enum.Material.Neon,
			Parent = model,
		})
		table.insert(arena.trim, trim)

		if i % 6 == 3 then
			local banner = part({
				Name = "Banner",
				Size = Vector3.new(4, 8, 0.2),
				CFrame = wallCf * CFrame.new(0, 1, -1.15),
				Color = CRIMSON,
				Material = Enum.Material.Fabric,
				CanCollide = false,
				Parent = model,
			})
			table.insert(arena.banners, banner)
		end
		if i % 6 == 0 then
			local _, fire = torch(model, (wallCf * CFrame.new(0, 6.75, 0)).Position, 1, 30)
			table.insert(arena.fires, fire)
		end

		for tier = 1, 3 do
			local r = radius + 2 + tier * 5
			local h = 12 + tier * 4
			local stepPos = center + dir * r + Vector3.new(0, h / 2, 0)
			part({
				Name = "Stand",
				Size = Vector3.new(2 * r * math.sin(math.pi / segments) + 1, h, 5),
				CFrame = CFrame.lookAt(stepPos, Vector3.new(center.X, stepPos.Y, center.Z)),
				Color = Color3.fromRGB(150, 135, 115),
				Material = Enum.Material.Concrete,
				Parent = model,
			})
			if (i + tier) % 2 == 0 then
				local seatPos = center + dir * r + Vector3.new(0, h + 1.2, 0)
				part({
					Name = "Crowd",
					Size = Vector3.new(1.6, 2.4, 1.2),
					CFrame = CFrame.lookAt(seatPos, Vector3.new(center.X, seatPos.Y, center.Z)),
					Color = CROWD_COLORS[(i * tier) % #CROWD_COLORS + 1],
					CanCollide = false,
					Parent = model,
				})
			end
		end
	end

	model.Parent = workspace
	return arena
end

-- 스테이지 구간 색으로 투기장을 물들인다. 보스전은 붉은 불꽃
function World.themeArena(arena: Arena, color: Color3, isBoss: boolean)
	for _, p in ipairs(arena.trim) do
		p.Color = color
	end
	for _, b in ipairs(arena.banners) do
		b.Color = isBoss and CRIMSON or color:Lerp(Color3.new(0, 0, 0), 0.35)
	end
	for _, f in ipairs(arena.fires) do
		if isBoss then
			f.Color = Color3.fromRGB(255, 40, 60)
			f.SecondaryColor = Color3.fromRGB(120, 0, 30)
		else
			f.Color = FIRE
			f.SecondaryColor = Color3.fromRGB(255, 220, 120)
		end
	end
end

return World
