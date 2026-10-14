-- AuraBuilder (ModuleScript, ReplicatedStorage)
-- 상점에서 산 아우라 30종을 캐릭터에 입힌다. 서버가 입히면 모두에게 보이고,
-- 클라이언트는 미리보기로 내 화면에만 잠깐 입혀 볼 수 있다.
-- 단계가 오를수록 하나씩 쌓인다:
--   입자 → 발밑 고리(2~) → 룬 돌(3~) → 등 뒤 빛 바퀴(6~) → 두 번째 고리(6~) → 나선으로 감아 오르는 속성 조각(11~)
--   → 날개(15~) → 왕관(19~) → 바닥 육망성과 세 번째 고리(21~) → 도는 검(24~) → 날개 두 쌍(26~) → 손 궤적(27~)
-- 몇몇 단계는 고유 장식이 더 붙는다 (뇌운, 혈월, 블랙홀, 심연의 눈, 초신성 등).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local GradeStyle = require(ReplicatedStorage:WaitForChild("GradeStyle"))
local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))

local AuraBuilder = {}

local GOLD = Color3.fromRGB(225, 180, 70)
local orbit = WeaponBuilder.orbitPart

-- 아우라 단계에 맞는 등급 디자인 (속성이 같고, 단계가 높을수록 화려한 등급)
function AuraBuilder.styleFor(tier: number)
	if tier >= #Config.Auras then
		return GradeStyle.get(100)
	end
	local a = Config.Auras[tier]
	local band = (tier - 1) // 10
	return GradeStyle.get(a.motif + band * 30)
end

local function weldPart(parent: Instance, base: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = base.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
	p.Parent = parent
	return p
end

local function colorSeq(style: any): ColorSequence
	return style.rainbow and GradeStyle.RAINBOW or ColorSequence.new(style.glow, style.secondary)
end

local function particles(parent: Instance, style: any, rate: number, size: number, speed: number, name: string): ParticleEmitter
	local pe = Instance.new("ParticleEmitter")
	pe.Name = name
	pe.Texture = style.motif.tex
	pe.Rate = rate
	pe.Lifetime = NumberRange.new(0.8, 1.6)
	pe.Speed = NumberRange.new(speed * 0.4, speed)
	pe.SpreadAngle = Vector2.new(35, 35)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.Acceleration = style.motif.drift
	pe.RotSpeed = NumberRange.new(-90, 90)
	pe.Rotation = NumberRange.new(0, 360)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
	local dark = style.motif.id == "shadow" or style.motif.id == "void"
	pe.LightEmission = dark and 0.1 or 0.5
	pe.Color = colorSeq(style)
	pe.Parent = parent
	return pe
end

-- 속성마다 다른 나선 조각 모양
local function elementPiece(style: any, scale: number): (Vector3, Enum.Material, Enum.PartType?, number)
	local id = style.motif.id
	if id == "frost" or id == "crystal" then
		return Vector3.new(0.25, 0.9, 0.25) * scale, Enum.Material.Glass, nil, 3
	elseif id == "storm" then
		return Vector3.new(0.1, 0.8, 0.1) * scale, Enum.Material.Neon, nil, 6
	elseif id == "nature" then
		return Vector3.new(0.5, 0.06, 0.32) * scale, Enum.Material.Neon, nil, 2
	elseif id == "shadow" or id == "void" then
		return Vector3.new(0.6, 0.6, 0.6) * scale, Enum.Material.ForceField, Enum.PartType.Ball, 0
	elseif id == "holy" or id == "star" then
		return Vector3.new(0.32, 0.32, 0.32) * scale, Enum.Material.Neon, nil, 4
	end
	return Vector3.new(0.45, 0.45, 0.45) * scale, Enum.Material.Neon, Enum.PartType.Ball, 0
end

local function flatRing(holder: Instance, root: BasePart, diameter: number, color: Color3, speed: number, height: number, transparency: number, name: string)
	orbit(holder, root, Vector3.new(0.1, diameter, diameter), color, Enum.Material.ForceField, Enum.PartType.Cylinder, {
		name = name,
		height = height,
		speed = speed,
		flat = true,
		transparency = transparency,
	})
end

-- 날개 한 쌍: 깃털 여러 장을 몸통 뒤에 붙인다
local function wings(holder: Instance, torso: BasePart, style: any, size: number, yOff: number, spread: number, material: Enum.Material)
	for _, side in ipairs({ 1, -1 }) do
		for f = 0, 4 do
			local len = (3.0 - f * 0.42) * size
			local base = CFrame.new(0, 0.4 + yOff, torso.Size.Z / 2 + 0.3)
			local cf = base * CFrame.new(side * (0.5 + len * 0.36), 0.35 - f * 0.32, f * 0.04) * CFrame.Angles(0, 0, math.rad(side * (-spread + f * 20))) * CFrame.Angles(0, math.rad(90), 0)
			local color = (f % 2 == 0) and style.glow or style.secondary
			local feather = weldPart(holder, torso, "AuraWing", Vector3.new(0.1, len, 0.6 * size), cf, color, material)
			feather.Transparency = material == Enum.Material.ForceField and 0.1 or 0.15
		end
	end
end

-- 단계별 고유 장식
local specials: { [number]: (Instance, Model, BasePart, any) -> () } = {}

-- 뇌운: 머리 위 먹구름
specials[13] = function(holder, char, _root, style)
	local head = char:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return
	end
	for i = 1, 4 do
		local cloud = orbit(holder, head, Vector3.new(1.4, 1, 1.4), Color3.fromRGB(60, 60, 75), Enum.Material.SmoothPlastic, Enum.PartType.Ball, {
			name = "AuraCloud",
			radius = 0.8,
			height = 3,
			speed = 0.6,
			phase = i * math.pi / 2,
		})
		cloud.Transparency = 0.2
		if i == 1 then
			local pe = particles(cloud, style, 8, 0.3, 6, "CloudSpark")
			pe.EmissionDirection = Enum.NormalId.Bottom
			pe.Acceleration = Vector3.new(0, -30, 0)
		end
	end
end

-- 혈월: 등 뒤 붉은 달
specials[17] = function(holder, char, _root, _style)
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not (torso and torso:IsA("BasePart")) then
		return
	end
	local moon = weldPart(holder, torso, "AuraMoon", Vector3.new(3.4, 3.4, 3.4), CFrame.new(0, 1.6, 2.6), Color3.fromRGB(200, 20, 40), Enum.Material.Neon, Enum.PartType.Ball)
	moon.Transparency = 0.25
	weldPart(holder, torso, "AuraMoonShadow", Vector3.new(3, 3, 3), CFrame.new(0.8, 1.9, 2.0), Color3.fromRGB(20, 5, 10), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
end

-- 블랙홀: 발밑에서 삼키는 검은 구멍
local function blackHole(holder: Instance, root: BasePart, style: any, rings: number)
	local hole = orbit(holder, root, Vector3.new(0.12, 5, 5), Color3.fromRGB(5, 0, 10), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, {
		name = "AuraHole",
		height = -2.9,
		speed = 0,
		flat = true,
	})
	hole.Transparency = 0.05
	for r = 1, rings do
		flatRing(holder, root, 6 + r * 2.2, (r % 2 == 0) and style.secondary or style.glow, (r % 2 == 0) and -1.5 or 2, -2.85 + r * 0.02, 0.15, "AuraHoleRing")
	end
end
specials[18] = function(holder, _char, root, style)
	blackHole(holder, root, style, 2)
end
specials[28] = function(holder, _char, root, style)
	blackHole(holder, root, style, 3)
end

-- 심연의 눈: 등 뒤 거대한 눈
specials[25] = function(holder, char, _root, style)
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not (torso and torso:IsA("BasePart")) then
		return
	end
	local eye = weldPart(holder, torso, "AuraEye", Vector3.new(0.4, 2.6, 4.4), CFrame.new(0, 2.4, 2.6) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(235, 225, 240), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	eye.Transparency = 0.05
	weldPart(holder, torso, "AuraIris", Vector3.new(0.5, 1.7, 1.7), CFrame.new(0, 2.4, 2.45) * CFrame.Angles(0, math.rad(90), 0), style.glow, Enum.Material.Neon, Enum.PartType.Cylinder)
	weldPart(holder, torso, "AuraPupil", Vector3.new(0.55, 0.9, 0.35), CFrame.new(0, 2.4, 2.4), Color3.fromRGB(10, 0, 15), Enum.Material.SmoothPlastic)
end

-- 초신성과 무한의 근원: 머리 위의 작은 별
local function star(holder: Instance, char: Model, style: any, size: number)
	local head = char:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return
	end
	local core = orbit(holder, head, Vector3.new(size, size, size), Color3.fromRGB(255, 250, 230), Enum.Material.Neon, Enum.PartType.Ball, {
		name = "AuraStar",
		height = 3.4,
		speed = 0,
		bob = 0.3,
		bobSpeed = 2,
	})
	particles(core, style, 30, 0.5, 4, "StarFlare").SpreadAngle = Vector2.new(180, 180)
	local light = Instance.new("PointLight")
	light.Color = style.glow
	light.Range = 14
	light.Brightness = 2
	light.Parent = core
end
specials[29] = function(holder, char, _root, style)
	star(holder, char, style, 1.1)
end
specials[30] = function(holder, char, _root, style)
	star(holder, char, style, 1.4)
end

-- 이전 아우라를 지운다 (등급 오라, 산 아우라, 미리보기 모두)
function AuraBuilder.clear(char: Model, holderName: string?)
	local old = char:FindFirstChild(holderName or "ArenaAura")
	if old then
		old:Destroy()
	end
	for _, d in ipairs(char:GetDescendants()) do
		if d.Name == "RankAura" then
			d:Destroy()
		end
	end
end

-- 아우라 입히기. tier 1~30. holderName을 주면 그 이름으로 (미리보기용)
function AuraBuilder.apply(char: Model, tier: number, holderName: string?): Model?
	local root = char:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return nil
	end
	local k = math.clamp(math.floor(tier), 1, #Config.Auras)
	AuraBuilder.clear(char, holderName)
	local style = AuraBuilder.styleFor(k)
	local p = k / #Config.Auras
	local holder = Instance.new("Model")
	holder.Name = holderName or "ArenaAura"
	holder.Parent = char

	-- 1. 몸에서 피어오르는 속성 입자와 빛
	particles(root, style, 6 + k * 1.2, 0.4 + p * 0.9, 2 + p * 4, "RankAura")
	local light = Instance.new("PointLight")
	light.Name = "RankAura"
	light.Color = style.glow
	light.Range = 6 + p * 10
	light.Brightness = 0.5 + p * 1.2
	light.Parent = root

	-- 2. 발밑 고리
	if k >= 2 then
		flatRing(holder, root, 4.5 + p * 3, style.glow, 0.8, -2.85, 0.3, "AuraRing")
	end
	-- 3. 발밑을 도는 룬 돌
	if k >= 3 then
		local n = math.min(10, 2 + k // 3)
		for i = 1, n do
			orbit(holder, root, Vector3.new(0.3, 0.3, 0.3), (i % 2 == 0) and style.secondary or style.glow, Enum.Material.Neon, nil, {
				name = "AuraRune",
				radius = 2.8 + p * 1.5,
				height = -2.5,
				speed = 1.2,
				phase = i * (math.pi * 2 / n),
				tumble = 2,
				bob = 0.2,
				bobSpeed = 3,
			})
		end
	end
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	-- 6. 등 뒤 빛 바퀴와 두 번째 고리
	if k >= 6 then
		flatRing(holder, root, 7 + p * 4, style.secondary, -0.6, -2.8, 0.2, "AuraRing2")
		if torso and torso:IsA("BasePart") then
			local spokes = math.min(16, 8 + k // 3)
			local radius = 1.6 + p * 1.2
			for i = 1, spokes do
				orbit(holder, torso, Vector3.new(0.12, 0.6 + p * 0.5, 0.18), (i % 2 == 0) and GOLD:Lerp(style.glow, 0.4) or style.glow, k >= 16 and Enum.Material.Foil or Enum.Material.Neon, nil, {
					name = "AuraWheel",
					radius = radius,
					speed = 0.9,
					phase = i * (math.pi * 2 / spokes),
					useRotation = true,
					axis = "Z",
					offsetPos = Vector3.new(0, 0.9, 1.4),
				})
			end
		end
	end
	-- 11. 나선으로 감아 오르는 속성 조각
	if k >= 11 then
		local size, material, shape, tumble = elementPiece(style, 1 + p * 0.6)
		local n = 4 + (k - 11) // 3
		for i = 1, n do
			local piece = orbit(holder, root, size, (i % 2 == 0) and style.secondary or style.glow, material, shape, {
				name = "AuraHelix",
				radius = 2.4 + p,
				height = -1 + (i % 3) * 1.2,
				speed = 2.4,
				phase = i * (math.pi * 2 / n),
				tumble = tumble,
				bob = 1.6,
				bobSpeed = 1.8,
			})
			if i % 2 == 1 then
				local a0 = Instance.new("Attachment")
				a0.Position = Vector3.new(0, 0.2, 0)
				a0.Parent = piece
				local a1 = Instance.new("Attachment")
				a1.Position = Vector3.new(0, -0.2, 0)
				a1.Parent = piece
				local tr = Instance.new("Trail")
				tr.Attachment0 = a0
				tr.Attachment1 = a1
				tr.Lifetime = 0.4
				tr.LightEmission = 0.5
				tr.Color = colorSeq(style)
				tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
				tr.Parent = piece
			end
		end
	end
	-- 15. 날개 (26부터 두 쌍)
	if k >= 15 and torso and torso:IsA("BasePart") then
		local wingMat = (style.motif.id == "shadow" or style.motif.id == "void") and Enum.Material.ForceField or Enum.Material.Glass
		wings(holder, torso, style, 0.9 + p * 0.6, 0, 60, wingMat)
		if k >= 26 then
			wings(holder, torso, style, 0.6 + p * 0.4, -0.9, 20, Enum.Material.ForceField)
		end
	end
	-- 19. 머리 위 왕관
	local head = char:FindFirstChild("Head")
	if k >= 19 and head and head:IsA("BasePart") then
		for i = 1, 8 do
			orbit(holder, head, Vector3.new(0.14, 0.55 + (i % 2) * 0.3, 0.14), (i % 2 == 0) and GOLD or style.glow, (i % 2 == 0) and Enum.Material.Foil or Enum.Material.Neon, nil, {
				name = "AuraCrown",
				radius = 0.75,
				height = 1.25,
				speed = 0.5,
				phase = i * math.pi / 4,
			})
		end
	end
	-- 21. 바닥 육망성과 세 번째 고리
	if k >= 21 then
		flatRing(holder, root, 11 + p * 4, style.glow, 0.35, -2.75, 0.35, "AuraRing3")
		local r = 3.2 + p * 1.2
		local side = r * math.sqrt(3) * 1.02
		for tri = 0, 1 do
			for i = 0, 2 do
				orbit(holder, root, Vector3.new(0.1, 0.06, side), tri == 0 and style.glow or style.secondary, Enum.Material.Neon, nil, {
					name = "AuraSigil",
					radius = r * 0.5,
					height = -2.88,
					speed = tri == 0 and 0.4 or -0.4,
					phase = i * (math.pi * 2 / 3) + tri * math.pi / 3,
				})
			end
		end
	end
	-- 24. 몸 주위를 도는 검
	if k >= 24 then
		local n = (k >= 27) and 8 or 6
		for i = 1, n do
			orbit(holder, root, Vector3.new(0.12, 1.8, 0.38), (i % 2 == 0) and GOLD:Lerp(style.glow, 0.3) or style.glow, Enum.Material.Foil, nil, {
				name = "AuraSword",
				radius = 3.6 + p,
				height = 0.6,
				speed = -1.3,
				phase = i * (math.pi * 2 / n),
				bob = 0.35,
				bobSpeed = 2.2,
			})
		end
	end
	-- 27. 손 궤적
	if k >= 27 then
		for _, name in ipairs({ "RightHand", "LeftHand", "Right Arm", "Left Arm" }) do
			local hand = char:FindFirstChild(name)
			if hand and hand:IsA("BasePart") then
				local a0 = Instance.new("Attachment")
				a0.Name = "RankAura"
				a0.Position = Vector3.new(0, 0.3, 0)
				a0.Parent = hand
				local a1 = Instance.new("Attachment")
				a1.Name = "RankAura"
				a1.Position = Vector3.new(0, -0.3, 0)
				a1.Parent = hand
				local tr = Instance.new("Trail")
				tr.Name = "RankAura"
				tr.Attachment0 = a0
				tr.Attachment1 = a1
				tr.Lifetime = 0.35
				tr.LightEmission = 0.7
				tr.Color = colorSeq(style)
				tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
				tr.Parent = hand
			end
		end
	end
	local special = specials[k]
	if special then
		pcall(special, holder, char, root, style)
	end
	return holder
end

return AuraBuilder
