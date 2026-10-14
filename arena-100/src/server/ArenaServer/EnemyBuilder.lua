-- EnemyBuilder (ModuleScript, ArenaServer 아래)
-- 적 12종의 생김새. 기본 인형에 투구, 방패, 활, 지팡이, 폭탄 같은 장비를 붙인다.
-- 등급마다 몸 색, 재질, 등 가시 개수, 속성 오라가 다르다. 보스는 왕관과 망토.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))
local GradeStyle = require(ReplicatedStorage:WaitForChild("GradeStyle"))

local EnemyBuilder = {}

local GOLD = Color3.fromRGB(225, 180, 70)
local IRON = Color3.fromRGB(70, 72, 80)
local WOOD = Color3.fromRGB(95, 65, 40)
local LEATHER = Color3.fromRGB(80, 55, 38)

-- 종류마다 몸 색에 섞는 색, 눈 색
local TINT = {
	grunt = { tint = Color3.fromRGB(150, 120, 100), eye = Color3.fromRGB(255, 70, 50) },
	archer = { tint = Color3.fromRGB(70, 120, 70), eye = Color3.fromRGB(180, 255, 120) },
	shield = { tint = Color3.fromRGB(110, 120, 150), eye = Color3.fromRGB(120, 200, 255) },
	brute = { tint = Color3.fromRGB(140, 60, 50), eye = Color3.fromRGB(255, 140, 30) },
	bomber = { tint = Color3.fromRGB(150, 110, 60), eye = Color3.fromRGB(255, 230, 60) },
	shaman = { tint = Color3.fromRGB(100, 60, 140), eye = Color3.fromRGB(220, 120, 255) },
	assassin = { tint = Color3.fromRGB(40, 35, 50), eye = Color3.fromRGB(255, 40, 90) },
	golem = { tint = Color3.fromRGB(120, 110, 100), eye = Color3.fromRGB(255, 170, 60) },
	ghost = { tint = Color3.fromRGB(170, 200, 230), eye = Color3.fromRGB(140, 255, 255) },
	splitter = { tint = Color3.fromRGB(90, 160, 90), eye = Color3.fromRGB(230, 255, 90) },
	priest = { tint = Color3.fromRGB(230, 220, 190), eye = Color3.fromRGB(120, 255, 160) },
	knight = { tint = Color3.fromRGB(35, 35, 45), eye = Color3.fromRGB(255, 50, 50) },
}

-- 정예 특성마다 오라 색
local ELITE_COLOR = {
	swift = Color3.fromRGB(90, 220, 255),
	giant = Color3.fromRGB(255, 170, 60),
	regen = Color3.fromRGB(110, 255, 120),
	fury = Color3.fromRGB(255, 50, 60),
}

local function weld(model: Model, base: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
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
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = base.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
	p.Parent = model
	return p
end

local function find(model: Model, name: string): BasePart?
	local p = model:FindFirstChild(name)
	if p and p:IsA("BasePart") then
		return p
	end
	return nil
end

local function particles(parent: Instance, color: Color3 | ColorSequence, rate: number, size: number, speed: number, name: string?)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = name or "Aura"
	pe.Rate = rate
	pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Speed = NumberRange.new(speed * 0.5, speed)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.SpreadAngle = Vector2.new(30, 30)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	pe.LightEmission = 0.8
	pe.Color = typeof(color) == "ColorSequence" and color or ColorSequence.new(color :: Color3)
	pe.Parent = parent
	return pe
end

-- 종류별 장비
local dressers: { [string]: (Model, number, Color3, number) -> () } = {}

dressers.grunt = function(model, s, accent, grade)
	local head = find(model, "Head")
	local hand = find(model, "RightHand")
	if head then
		weld(model, head, "Helmet", Vector3.new(1.35, 0.75, 1.35) * s, CFrame.new(0, 0.3 * s, 0), IRON, Enum.Material.Metal, Enum.PartType.Ball)
		weld(model, head, "Crest", Vector3.new(0.15, 0.5, 1.1) * s, CFrame.new(0, 0.75 * s, 0), accent, grade >= 20 and Enum.Material.Neon or Enum.Material.Metal)
	end
	if hand then
		WeaponBuilder.build(model, hand, 1, { grade = grade, accent = accent, rarity = 1, scale = 0.7 * s, lite = true })
	end
end

dressers.archer = function(model, s, accent, grade)
	local head = find(model, "Head")
	local left = find(model, "LeftHand")
	local torso = find(model, "UpperTorso")
	if head then
		weld(model, head, "Hood", Vector3.new(1.45, 1.45, 1.45) * s, CFrame.new(0, 0.12 * s, 0.12 * s), Color3.fromRGB(45, 70, 45), Enum.Material.Fabric, Enum.PartType.Ball)
	end
	if left then
		-- 활: 세로로 휜 다섯 조각 + 빛나는 시위
		local radius, segs = 1.6 * s, 5
		for i = 0, segs - 1 do
			local a0 = math.rad(-60 + 120 * i / segs)
			local a1 = math.rad(-60 + 120 * (i + 1) / segs)
			local y0, z0 = math.sin(a0) * radius, -math.cos(a0) * radius + radius - 0.6 * s
			local y1, z1 = math.sin(a1) * radius, -math.cos(a1) * radius + radius - 0.6 * s
			local len = math.sqrt((y1 - y0) ^ 2 + (z1 - z0) ^ 2) + 0.05
			local ang = math.atan2(z1 - z0, y1 - y0)
			weld(model, left, "Bow" .. i, Vector3.new(0.18 * s, len, 0.22 * s), CFrame.new(0, (y0 + y1) / 2, (z0 + z1) / 2) * CFrame.Angles(ang, 0, 0), WOOD, Enum.Material.Wood)
		end
		weld(model, left, "BowString", Vector3.new(0.05, radius * 1.7, 0.05), CFrame.new(0, 0, 0.15 * s), accent, Enum.Material.Neon)
	end
	if torso then
		weld(model, torso, "Quiver", Vector3.new(1.6 * s, 0.55 * s, 0.55 * s), CFrame.new(0.3 * s, 0.2 * s, 0.55 * s) * CFrame.Angles(0, 0, math.rad(70)), LEATHER, Enum.Material.Fabric, Enum.PartType.Cylinder)
		for i = 1, 3 do
			weld(model, torso, "Arrow" .. i, Vector3.new(0.08, 0.6, 0.08) * s, CFrame.new((-0.05 + i * 0.12) * s, 1.05 * s, 0.55 * s), accent, Enum.Material.Neon)
		end
	end
end

dressers.shield = function(model, s, accent, grade)
	local head = find(model, "Head")
	local arm = find(model, "LeftLowerArm")
	local hand = find(model, "RightHand")
	if head then
		weld(model, head, "Helm", Vector3.new(1.3, 1.25, 1.3) * s, CFrame.new(0, 0.1 * s, 0), Color3.fromRGB(150, 155, 170), Enum.Material.Metal)
		weld(model, head, "Visor", Vector3.new(1.0, 0.12, 0.1) * s, CFrame.new(0, 0.05 * s, -0.66 * s), accent, Enum.Material.Neon)
		weld(model, head, "Plume", Vector3.new(0.2, 0.9, 1.2) * s, CFrame.new(0, 0.95 * s, 0.1 * s), accent, grade >= 10 and Enum.Material.Neon or Enum.Material.Fabric)
	end
	if arm then
		local shieldPart = weld(model, arm, "Shield", Vector3.new(2.4, 3.2, 0.3) * s, CFrame.new(-0.2 * s, -0.2 * s, -0.75 * s), Color3.fromRGB(120, 125, 140), Enum.Material.Metal)
		weld(model, shieldPart, "ShieldRim", Vector3.new(2.6, 3.4, 0.2) * s, CFrame.new(0, 0, 0.08 * s), GOLD, Enum.Material.Metal)
		weld(model, shieldPart, "ShieldEmblem", Vector3.new(0.12, 1.2, 1.2) * s, CFrame.new(0, 0.2 * s, -0.18 * s) * CFrame.Angles(0, math.rad(90), 0), accent, Enum.Material.Neon, Enum.PartType.Cylinder)
	end
	if hand then
		WeaponBuilder.build(model, hand, 3, { grade = grade, accent = accent, rarity = 1, scale = 0.6 * s, lite = true })
	end
end

dressers.brute = function(model, s, accent, grade)
	local head = find(model, "Head")
	local hand = find(model, "RightHand")
	for _, side in ipairs({ "Left", "Right" }) do
		local arm = find(model, side .. "UpperArm")
		if arm then
			weld(model, arm, side .. "Pad", Vector3.new(1.4, 1.1, 1.4) * s, CFrame.new(0, 0.45 * s, 0), IRON, Enum.Material.Metal, Enum.PartType.Ball)
			weld(model, arm, side .. "Spike", Vector3.new(0.25, 0.7, 0.25) * s, CFrame.new(0, 1.1 * s, 0), accent, Enum.Material.Neon)
		end
	end
	if head then
		for _, x in ipairs({ -1, 1 }) do
			weld(model, head, "Horn", Vector3.new(0.3, 1.1, 0.3) * s, CFrame.new(0.5 * x * s, 0.6 * s, -0.1 * s) * CFrame.Angles(0, 0, math.rad(-30 * x)), Color3.fromRGB(235, 225, 200), Enum.Material.SmoothPlastic)
		end
	end
	if hand then
		-- 거대한 몽둥이
		weld(model, hand, "ClubHandle", Vector3.new(0.4, 2.6, 0.4) * s, CFrame.new(0, -0.3 * s, -1.0 * s) * CFrame.Angles(math.rad(-90), 0, 0), WOOD, Enum.Material.Wood)
		local headPart = weld(model, hand, "ClubHead", Vector3.new(1.2, 1.2, 1.2) * s, CFrame.new(0, -0.3 * s, -2.6 * s), IRON, Enum.Material.Metal, Enum.PartType.Ball)
		for i = 0, 3 do
			local a = i * math.pi / 2
			weld(model, headPart, "ClubSpike" .. i, Vector3.new(0.2, 0.6, 0.2) * s, CFrame.Angles(a, 0, 0) * CFrame.new(0, 0.7 * s, 0), accent, grade >= 20 and Enum.Material.Neon or Enum.Material.Metal)
		end
	end
end

dressers.bomber = function(model, s, accent, _grade)
	local head = find(model, "Head")
	local torso = find(model, "UpperTorso")
	if head then
		for _, x in ipairs({ -1, 1 }) do
			weld(model, head, "Goggle", Vector3.new(0.12, 0.35, 0.35) * s, CFrame.new(0.2 * x * s, 0.1 * s, -0.62 * s) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, Enum.PartType.Cylinder)
		end
	end
	if torso then
		local barrel = weld(model, torso, "Barrel", Vector3.new(1.6, 1.2, 1.2) * s, CFrame.new(0, 0.1 * s, 0.85 * s) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 70, 40), Enum.Material.Wood, Enum.PartType.Cylinder)
		for _, y in ipairs({ -0.5, 0.5 }) do
			weld(model, barrel, "Band", Vector3.new(0.15, 1.3, 1.3) * s, CFrame.new(y * s, 0, 0), IRON, Enum.Material.Metal, Enum.PartType.Cylinder)
		end
		local fuse = weld(model, torso, "Fuse", Vector3.new(0.12, 0.6, 0.12) * s, CFrame.new(0, 1.0 * s, 0.85 * s), Color3.fromRGB(255, 80, 40), Enum.Material.Neon)
		local spark = Instance.new("Sparkles")
		spark.SparkleColor = Color3.fromRGB(255, 160, 60)
		spark.Parent = fuse
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 120, 40)
		light.Range = 8
		light.Brightness = 2
		light.Parent = fuse
	end
	local _ = accent
end

dressers.shaman = function(model, s, accent, grade)
	local head = find(model, "Head")
	local lower = find(model, "LowerTorso")
	local hand = find(model, "RightHand")
	if head then
		weld(model, head, "Hat", Vector3.new(0.9, 1.6, 0.9) * s, CFrame.new(0, 1.05 * s, 0.1 * s) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(70, 40, 100), Enum.Material.Fabric)
		weld(model, head, "HatBrim", Vector3.new(0.1, 1.9, 1.9) * s, CFrame.new(0, 0.42 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 35, 90), Enum.Material.Fabric, Enum.PartType.Cylinder)
	end
	if lower then
		weld(model, lower, "Robe", Vector3.new(2.2, 1.9, 1.9) * s, CFrame.new(0, -0.9 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(80, 45, 115), Enum.Material.Fabric, Enum.PartType.Cylinder)
	end
	if hand then
		weld(model, hand, "Staff", Vector3.new(0.25, 5, 0.25) * s, CFrame.new(0, 1.2 * s, 0), WOOD, Enum.Material.Wood)
		local orb = weld(model, hand, "Orb", Vector3.new(0.9, 0.9, 0.9) * s, CFrame.new(0, 3.9 * s, 0), accent, Enum.Material.Neon, Enum.PartType.Ball)
		local light = Instance.new("PointLight")
		light.Color = accent
		light.Range = 10
		light.Brightness = 2
		light.Parent = orb
		particles(orb, accent, 10, 0.4 * s, 2, "OrbGlow")
	end
	local _ = grade
end

dressers.assassin = function(model, s, accent, grade)
	local head = find(model, "Head")
	local torso = find(model, "UpperTorso")
	if head then
		weld(model, head, "Hood", Vector3.new(1.4, 1.4, 1.4) * s, CFrame.new(0, 0.1 * s, 0.1 * s), Color3.fromRGB(25, 22, 30), Enum.Material.Fabric, Enum.PartType.Ball)
		weld(model, head, "Mask", Vector3.new(1.1, 0.45, 0.1) * s, CFrame.new(0, -0.2 * s, -0.62 * s), Color3.fromRGB(20, 20, 24), Enum.Material.SmoothPlastic)
	end
	if torso then
		weld(model, torso, "Scarf", Vector3.new(0.5, 2.2, 0.1) * s, CFrame.new(0.3 * s, -0.2 * s, 0.6 * s) * CFrame.Angles(math.rad(20), 0, 0), Color3.fromRGB(200, 30, 60), Enum.Material.Fabric)
		particles(torso, Color3.fromRGB(60, 30, 80), 6, 0.9 * s, 1, "Shadow")
	end
	for _, side in ipairs({ "RightHand", "LeftHand" }) do
		local hand = find(model, side)
		if hand then
			WeaponBuilder.build(model, hand, 4, { grade = grade, accent = accent, rarity = 1, scale = 0.9 * s, lite = true })
		end
	end
end

dressers.golem = function(model, s, accent, grade)
	local ROCK = Color3.fromRGB(105, 98, 90)
	for _, name in ipairs({ "UpperTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }) do
		local part = find(model, name)
		if part then
			for i = 1, 2 do
				weld(model, part, "Rock", Vector3.new(0.9, 0.7, 0.8) * s, CFrame.new((i - 1.5) * 0.5 * s, 0.2 * s * i, -0.3 * s) * CFrame.Angles(math.rad(i * 30), math.rad(i * 50), 0), ROCK, Enum.Material.Slate)
			end
			weld(model, part, "Crack", Vector3.new(0.1, part.Size.Y * 0.8, 0.12), CFrame.new(0, 0, -part.Size.Z / 2 - 0.02), accent, Enum.Material.Neon)
		end
	end
	local head = find(model, "Head")
	if head then
		weld(model, head, "Brow", Vector3.new(1.5, 0.45, 0.6) * s, CFrame.new(0, 0.35 * s, -0.35 * s), ROCK, Enum.Material.Slate)
	end
	for _, side in ipairs({ "LeftHand", "RightHand" }) do
		local hand = find(model, side)
		if hand then
			weld(model, hand, "Fist", Vector3.new(1.3, 1.3, 1.3) * s, CFrame.new(0, -0.3 * s, 0), ROCK, Enum.Material.Slate, Enum.PartType.Ball)
		end
	end
	local upper = find(model, "UpperTorso")
	if upper then
		particles(upper, Color3.fromRGB(180, 160, 130), 4, 0.8 * s, 1, "Dust")
	end
	local _ = grade
end

dressers.ghost = function(model, s, accent, grade)
	local head = find(model, "Head")
	local lower = find(model, "LowerTorso")
	if head then
		weld(model, head, "Shroud", Vector3.new(1.5, 1.6, 1.5) * s, CFrame.new(0, 0.15 * s, 0.1 * s), Color3.fromRGB(200, 220, 240), Enum.Material.Glass, Enum.PartType.Ball).Transparency = 0.35
	end
	if lower then
		local tail = weld(model, lower, "Tail", Vector3.new(2.2, 2.6, 1.6) * s, CFrame.new(0, -1.3 * s, 0.1 * s), Color3.fromRGB(190, 215, 240), Enum.Material.Glass)
		tail.Transparency = 0.45
		particles(tail, accent, 10, 0.7 * s, 1.5, "Wisp")
	end
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Transparency = math.max(d.Transparency, 0.25)
		end
	end
	local hand = find(model, "RightHand")
	if hand then
		WeaponBuilder.build(model, hand, 5, { grade = grade, accent = accent, rarity = 1, scale = 0.6 * s, lite = true })
	end
end

dressers.splitter = function(model, s, accent, _grade)
	local SLIME = Color3.fromRGB(90, 200, 100)
	for _, name in ipairs({ "UpperTorso", "Head", "LowerTorso" }) do
		local part = find(model, name)
		if part then
			local blob = weld(model, part, "Blob", part.Size * 1.25, CFrame.new(), SLIME, Enum.Material.Glass, Enum.PartType.Ball)
			blob.Transparency = 0.4
		end
	end
	local upper = find(model, "UpperTorso")
	if upper then
		weld(model, upper, "Core", Vector3.new(0.7, 0.7, 0.7) * s, CFrame.new(0, 0.1 * s, 0), accent, Enum.Material.Neon, Enum.PartType.Ball)
		particles(upper, SLIME, 6, 0.4 * s, 1, "Drip").Acceleration = Vector3.new(0, -8, 0)
	end
end

dressers.priest = function(model, s, accent, _grade)
	local head = find(model, "Head")
	local lower = find(model, "LowerTorso")
	local hand = find(model, "RightHand")
	local WHITE = Color3.fromRGB(240, 235, 220)
	if head then
		weld(model, head, "Mitre", Vector3.new(0.9, 1.4, 0.6) * s, CFrame.new(0, 0.95 * s, 0), WHITE, Enum.Material.Fabric)
		weld(model, head, "MitreBand", Vector3.new(0.95, 0.15, 0.65) * s, CFrame.new(0, 0.55 * s, 0), GOLD, Enum.Material.Foil)
		for i = 0, 7 do
			local a = (i / 8) * math.pi * 2
			weld(model, head, "PriestHalo", Vector3.new(0.12, 0.12, 0.45) * s, CFrame.new(math.cos(a) * 0.8 * s, 1.9 * s, math.sin(a) * 0.8 * s) * CFrame.Angles(0, -a, 0), GOLD, Enum.Material.Neon)
		end
	end
	if lower then
		weld(model, lower, "Robe", Vector3.new(2.2, 2.0, 2.0) * s, CFrame.new(0, -0.95 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), WHITE, Enum.Material.Fabric, Enum.PartType.Cylinder)
	end
	if hand then
		weld(model, hand, "Staff", Vector3.new(0.22, 5, 0.22) * s, CFrame.new(0, 1.2 * s, 0), GOLD, Enum.Material.Foil)
		weld(model, hand, "CrossH", Vector3.new(1.2, 0.22, 0.22) * s, CFrame.new(0, 3.3 * s, 0), GOLD, Enum.Material.Foil)
		local orb = weld(model, hand, "HolyOrb", Vector3.new(0.8, 0.8, 0.8) * s, CFrame.new(0, 3.9 * s, 0), Color3.fromRGB(140, 255, 170), Enum.Material.Neon, Enum.PartType.Ball)
		particles(orb, Color3.fromRGB(140, 255, 170), 10, 0.4 * s, 2, "HolyGlow")
	end
	local _ = accent
end

dressers.knight = function(model, s, accent, grade)
	local head = find(model, "Head")
	local upper = find(model, "UpperTorso")
	local arm = find(model, "LeftLowerArm")
	local hand = find(model, "RightHand")
	local BLACK = Color3.fromRGB(30, 30, 38)
	if head then
		weld(model, head, "Helm", Vector3.new(1.35, 1.35, 1.35) * s, CFrame.new(0, 0.1 * s, 0), BLACK, Enum.Material.Metal)
		weld(model, head, "Slit", Vector3.new(1.0, 0.1, 0.08) * s, CFrame.new(0, 0.1 * s, -0.69 * s), accent, Enum.Material.Neon)
		for _, x in ipairs({ -1, 1 }) do
			weld(model, head, "HelmHorn", Vector3.new(0.22, 1.0, 0.22) * s, CFrame.new(0.55 * x * s, 0.75 * s, 0) * CFrame.Angles(0, 0, math.rad(-35 * x)), BLACK, Enum.Material.Metal)
		end
	end
	if upper then
		for _, x in ipairs({ -1, 1 }) do
			weld(model, upper, "Pauldron", Vector3.new(1.3, 0.6, 1.3) * s, CFrame.new(1.1 * x * s, 0.7 * s, 0), BLACK, Enum.Material.Metal)
		end
		weld(model, upper, "Cape", Vector3.new(upper.Size.X * 1.1, 3 * s, 0.1), CFrame.new(0, -0.8 * s, upper.Size.Z / 2 + 0.1) * CFrame.Angles(math.rad(8), 0, 0), Color3.fromRGB(90, 15, 25), Enum.Material.Fabric)
	end
	if arm then
		local sh = weld(model, arm, "Shield", Vector3.new(2.0, 2.8, 0.3) * s, CFrame.new(-0.2 * s, -0.2 * s, -0.75 * s), BLACK, Enum.Material.Metal)
		weld(model, sh, "ShieldMark", Vector3.new(0.2, 1.4, 0.1) * s, CFrame.new(0, 0, -0.18 * s), accent, Enum.Material.Neon)
	end
	if hand then
		WeaponBuilder.build(model, hand, 1, { grade = grade, accent = accent, rarity = 3, scale = 0.75 * s, lite = true })
	end
end

-- 몸 재질과 색: 등급마다 다르다
local function bodyMaterial(grade: number): Enum.Material
	if grade < 10 then
		return Enum.Material.SmoothPlastic
	elseif grade < 30 then
		return Enum.Material.Metal
	elseif grade < 50 then
		return Enum.Material.Foil
	elseif grade < 65 then
		return Enum.Material.Glass
	elseif grade < 80 then
		return Enum.Material.Neon
	elseif grade < 94 then
		return Enum.Material.ForceField
	end
	return Enum.Material.Neon
end

local function paintBody(model: Model, kind: string, style: any, isBoss: boolean)
	local t = TINT[kind] or TINT.grunt
	local body = t.tint:Lerp(style.primary, 0.55)
	if isBoss then
		body = body:Lerp(Color3.fromRGB(120, 10, 20), 0.3)
	end
	local mat = bodyMaterial(style.grade)
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Color = body
			d.Material = mat
			if d.Name == "LeftHand" or d.Name == "RightHand" or d.Name == "LeftFoot" or d.Name == "RightFoot" then
				d.Color = style.secondary:Lerp(body, 0.4)
			end
		end
	end
end

-- opts: { elite = 정예 특성 id, beyond = 초월 스테이지 }
function EnemyBuilder.dress(model: Model, kind: string, grade: number, isBoss: boolean, scale: number, opts: any?)
	local style = GradeStyle.get(grade)
	paintBody(model, kind, style, isBoss)
	local t = TINT[kind] or TINT.grunt
	local accent = isBoss and Color3.fromRGB(255, 70, 50) or style.glow

	-- 빛나는 두 눈
	local head = find(model, "Head")
	if head then
		for _, x in ipairs({ -1, 1 }) do
			weld(model, head, "Eye", Vector3.new(0.2, 0.09, 0.06) * scale, CFrame.new(0.2 * x * scale, 0.08 * scale, -head.Size.Z / 2 - 0.01), grade >= 40 and Color3.new(1, 1, 1) or t.eye:Lerp(style.glow, 0.4), Enum.Material.Neon)
		end
	end

	local dresser = dressers[kind] or dressers.grunt
	pcall(dresser, model, scale, accent, grade)

	-- 등 가시: 등급이 오를수록 늘어난다
	local upper = find(model, "UpperTorso")
	if upper then
		for i = 1, style.enemySpikes do
			local y = upper.Size.Y * (0.35 - (i - 1) * 0.16)
			local size = (0.25 + style.power * 0.35) * scale
			weld(model, upper, "BackSpike", Vector3.new(size, size * 2.2, size), CFrame.new(0, y, upper.Size.Z / 2 + size * 0.6) * CFrame.Angles(math.rad(-35), 0, 0), grade >= 30 and style.secondary or style.primary, grade >= 30 and Enum.Material.Neon or Enum.Material.Metal)
		end
	end

	-- 속성 오라
	local torso = upper or find(model, "HumanoidRootPart")
	if torso and (style.enemyAura or isBoss) then
		local color: Color3 | ColorSequence = isBoss and Color3.fromRGB(255, 50, 40) or ColorSequence.new(style.glow, style.secondary)
		if style.rainbow then
			color = GradeStyle.RAINBOW
		end
		local pe = particles(torso, color, isBoss and 20 or 3 + grade * 0.15, (0.5 + style.power * 0.8) * scale, 2.5)
		pe.Texture = style.motif.tex
		pe.Acceleration = style.motif.drift
		if style.motif.id == "shadow" or style.motif.id == "void" then
			pe.LightEmission = 0.1
		end
	end
	if grade >= 25 and head then
		local light = Instance.new("PointLight")
		light.Color = style.glow
		light.Range = 6 + style.power * 8
		light.Brightness = 0.8 + style.power
		light.Parent = head
	end

	if isBoss then
		if head then
			local top = CFrame.new(0, head.Size.Y / 2 + 0.25 * scale, 0)
			weld(model, head, "CrownBand", Vector3.new(0.3, head.Size.X * 1.05, head.Size.X * 1.05), top * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, Enum.PartType.Cylinder)
			for i = 0, 4 do
				local a = (i / 5) * math.pi * 2
				local r = head.Size.X * 0.42
				weld(model, head, "Crown" .. i, Vector3.new(0.22, 0.6, 0.22) * scale, top * CFrame.new(math.cos(a) * r, 0.4 * scale, math.sin(a) * r), GOLD, Enum.Material.Neon)
			end
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 70, 50)
			light.Range = 18
			light.Brightness = 2.2
			light.Parent = head
		end
		if upper then
			weld(model, upper, "Cape", Vector3.new(upper.Size.X * 1.2, 3.2 * scale, 0.1), CFrame.new(0, -0.9 * scale, upper.Size.Z / 2 + 0.1) * CFrame.Angles(math.rad(8), 0, 0), style.primary:Lerp(Color3.fromRGB(140, 15, 25), 0.6), Enum.Material.Fabric)
		end
	end
	local o = opts or {}
	-- 초월 스테이지: 검은 뿔 왕관과 무지개 기운
	if o.beyond and head then
		for _, x in ipairs({ -1, 1 }) do
			weld(model, head, "BeyondHorn", Vector3.new(0.25, 1.3, 0.25) * scale, CFrame.new(0.45 * x * scale, 0.9 * scale, 0.1 * scale) * CFrame.Angles(math.rad(-20), 0, math.rad(-25 * x)), Color3.fromRGB(20, 15, 30), Enum.Material.Metal)
		end
		local pe = particles(head, GradeStyle.RAINBOW, 6, 0.5 * scale, 2, "BeyondAura")
		pe.LightEmission = 1
	end
	-- 정예: 특성 색 오라와 발밑 고리
	local eliteColor = o.elite and ELITE_COLOR[o.elite]
	if eliteColor then
		local base = find(model, "HumanoidRootPart")
		if base then
			local ring = weld(model, base, "EliteRing", Vector3.new(0.15, 5 * scale, 5 * scale), CFrame.new(0, -2.8 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)), eliteColor, Enum.Material.Neon, Enum.PartType.Cylinder)
			ring.Transparency = 0.5
			local pe = particles(base, eliteColor, 14, 0.7 * scale, 3, "EliteAura")
			pe.SpreadAngle = Vector2.new(60, 60)
		end
		if head then
			local light = Instance.new("PointLight")
			light.Color = eliteColor
			light.Range = 10
			light.Brightness = 1.5
			light.Parent = head
		end
	end
end

return EnemyBuilder
