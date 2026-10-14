-- EnemyBuilder (ModuleScript, ArenaServer 아래)
-- 적 7종의 생김새. 기본 인형에 투구, 방패, 활, 지팡이, 폭탄 같은 장비를 붙인다.
-- 구간이 오를수록 재질이 금속 → 빛 → 우주로 바뀌고 오라가 생긴다. 보스는 왕관과 망토.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))

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

dressers.grunt = function(model, s, accent, section)
	local head = find(model, "Head")
	local hand = find(model, "RightHand")
	if head then
		weld(model, head, "Helmet", Vector3.new(1.35, 0.75, 1.35) * s, CFrame.new(0, 0.3 * s, 0), IRON, Enum.Material.Metal, Enum.PartType.Ball)
		weld(model, head, "Crest", Vector3.new(0.15, 0.5, 1.1) * s, CFrame.new(0, 0.75 * s, 0), accent, section >= 3 and Enum.Material.Neon or Enum.Material.Metal)
	end
	if hand then
		WeaponBuilder.build(model, hand, 1, { accent = accent, section = math.max(1, section - 1), rarity = 1, scale = 0.7 * s })
	end
end

dressers.archer = function(model, s, accent, section)
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

dressers.shield = function(model, s, accent, section)
	local head = find(model, "Head")
	local arm = find(model, "LeftLowerArm")
	local hand = find(model, "RightHand")
	if head then
		weld(model, head, "Helm", Vector3.new(1.3, 1.25, 1.3) * s, CFrame.new(0, 0.1 * s, 0), Color3.fromRGB(150, 155, 170), Enum.Material.Metal)
		weld(model, head, "Visor", Vector3.new(1.0, 0.12, 0.1) * s, CFrame.new(0, 0.05 * s, -0.66 * s), accent, Enum.Material.Neon)
		weld(model, head, "Plume", Vector3.new(0.2, 0.9, 1.2) * s, CFrame.new(0, 0.95 * s, 0.1 * s), accent, section >= 2 and Enum.Material.Neon or Enum.Material.Fabric)
	end
	if arm then
		local shieldPart = weld(model, arm, "Shield", Vector3.new(2.4, 3.2, 0.3) * s, CFrame.new(-0.2 * s, -0.2 * s, -0.75 * s), Color3.fromRGB(120, 125, 140), Enum.Material.Metal)
		weld(model, shieldPart, "ShieldRim", Vector3.new(2.6, 3.4, 0.2) * s, CFrame.new(0, 0, 0.08 * s), GOLD, Enum.Material.Metal)
		weld(model, shieldPart, "ShieldEmblem", Vector3.new(0.12, 1.2, 1.2) * s, CFrame.new(0, 0.2 * s, -0.18 * s) * CFrame.Angles(0, math.rad(90), 0), accent, Enum.Material.Neon, Enum.PartType.Cylinder)
	end
	if hand then
		WeaponBuilder.build(model, hand, 3, { accent = accent, section = math.max(1, section - 1), rarity = 1, scale = 0.6 * s })
	end
end

dressers.brute = function(model, s, accent, section)
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
			weld(model, headPart, "ClubSpike" .. i, Vector3.new(0.2, 0.6, 0.2) * s, CFrame.Angles(a, 0, 0) * CFrame.new(0, 0.7 * s, 0), accent, section >= 3 and Enum.Material.Neon or Enum.Material.Metal)
		end
	end
end

dressers.bomber = function(model, s, accent, _section)
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

dressers.shaman = function(model, s, accent, section)
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
	local _ = section
end

dressers.assassin = function(model, s, accent, section)
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
			WeaponBuilder.build(model, hand, 4, { accent = accent, section = math.max(1, section - 1), rarity = 1, scale = 0.9 * s })
		end
	end
end

-- 몸 재질과 색
local function paintBody(model: Model, kind: string, sectionColor: Color3, sectionIndex: number, isBoss: boolean)
	local t = TINT[kind] or TINT.grunt
	local body = t.tint:Lerp(sectionColor, 0.45)
	if isBoss then
		body = body:Lerp(Color3.fromRGB(120, 10, 20), 0.35)
	end
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Color = body
			if sectionIndex >= 5 then
				d.Material = Enum.Material.ForceField
			elseif sectionIndex >= 4 then
				d.Material = Enum.Material.Neon
			elseif sectionIndex >= 2 then
				d.Material = Enum.Material.Metal
			else
				d.Material = Enum.Material.SmoothPlastic
			end
		end
	end
end

function EnemyBuilder.dress(model: Model, kind: string, sectionColor: Color3, sectionIndex: number, isBoss: boolean, scale: number, rainbow: ColorSequence?)
	paintBody(model, kind, sectionColor, sectionIndex, isBoss)
	local t = TINT[kind] or TINT.grunt
	local accent = isBoss and Color3.fromRGB(255, 70, 50) or sectionColor:Lerp(t.eye, 0.35)

	-- 빛나는 두 눈
	local head = find(model, "Head")
	if head then
		for _, x in ipairs({ -1, 1 }) do
			weld(model, head, "Eye", Vector3.new(0.2, 0.09, 0.06) * scale, CFrame.new(0.2 * x * scale, 0.08 * scale, -head.Size.Z / 2 - 0.01), sectionIndex >= 4 and Color3.new(1, 1, 1) or t.eye, Enum.Material.Neon)
		end
	end

	local dresser = dressers[kind] or dressers.grunt
	pcall(dresser, model, scale, accent, sectionIndex)

	local torso = find(model, "UpperTorso") or find(model, "HumanoidRootPart")
	if torso and (sectionIndex >= 3 or isBoss) then
		local auraColor: Color3 | ColorSequence = isBoss and Color3.fromRGB(255, 50, 40) or sectionColor
		if sectionIndex >= 6 and rainbow then
			auraColor = rainbow
		end
		particles(torso, auraColor, isBoss and 18 or 4 + sectionIndex, 0.8 * scale, 2.5)
	end

	if isBoss then
		if head then
			local top = CFrame.new(0, head.Size.Y / 2 + 0.25 * scale, 0)
			weld(model, head, "CrownBand", Vector3.new(0.3, head.Size.X * 1.05, head.Size.X * 1.05) * Vector3.new(1, 1, 1), top * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, Enum.PartType.Cylinder)
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
		local upper = find(model, "UpperTorso")
		if upper then
			weld(model, upper, "Cape", Vector3.new(upper.Size.X * 1.2, 3.2 * scale, 0.1), CFrame.new(0, -0.9 * scale, upper.Size.Z / 2 + 0.1) * CFrame.Angles(math.rad(8), 0, 0), Color3.fromRGB(140, 15, 25), Enum.Material.Fabric)
		end
	end
end

return EnemyBuilder
