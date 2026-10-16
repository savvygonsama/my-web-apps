-- 권왕: 강호 (오픈 월드). 가운데 청운 마을, 서쪽 대나무 숲, 북쪽 흑호채, 동쪽 비류 폭포 계곡
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local World = {}

local folder: Folder
local rng = Random.new(1337)

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	if p.CanCollide == false then
		p.CanQuery = false
	end
	p.Parent = props.Parent or folder
	return p
end

local function sign(target: BasePart, face: Enum.NormalId, lines: { { any } })
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0.3
	gui.Parent = target
	local list = Instance.new("UIListLayout")
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = gui
	for _, line in ipairs(lines) do
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, line[3] or 0.5)
		l.Font = Enum.Font.GothamBlack
		l.TextScaled = true
		l.TextColor3 = line[2]
		l.TextStrokeTransparency = 0.4
		l.Text = line[1]
		l.Parent = gui
	end
end

local function prompt(target: BasePart, action: string, object: string, name: string): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.Name = name
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.KeyboardKeyCode = Enum.KeyCode.T
	pp.Parent = target
	return pp
end

function World.setupLighting()
	Lighting.ClockTime = 16.2
	Lighting.Brightness = 2.3
	Lighting.Ambient = Color3.fromRGB(110, 100, 95)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 140, 130)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmo.Density = 0.32
	atmo.Haze = 1.6
	atmo.Color = Color3.fromRGB(240, 215, 190)
	atmo.Decay = Color3.fromRGB(150, 110, 90)
	atmo.Parent = Lighting
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 28
	bloom.Threshold = 1.3
	bloom.Parent = Lighting
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Name = "Mood"
	cc.Saturation = 0.1
	cc.Contrast = 0.1
	cc.TintColor = Color3.fromRGB(255, 245, 232)
	cc.Parent = Lighting
end

------------------------------------------------------------------------
-- 작은 것들 (집, 나무, 바위, 대나무)
------------------------------------------------------------------------
local ROOF = Color3.fromRGB(60, 60, 70)
local WOOD = Color3.fromRGB(120, 80, 50)
local WALL = Color3.fromRGB(230, 220, 200)

local function house(at: Vector3, w: number, d: number, rotY: number, parent: Instance)
	local cf = CFrame.new(at) * CFrame.Angles(0, rotY, 0)
	local h = 11
	part({ Name = "HouseWall", Size = Vector3.new(w, h, d), CFrame = cf * CFrame.new(0, h / 2, 0), Color = WALL, Material = Enum.Material.Plaster, Parent = parent })
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			part({ Name = "Pillar", Size = Vector3.new(1.2, h, 1.2), CFrame = cf * CFrame.new(x * (w / 2), h / 2, z * (d / 2)), Color = WOOD, Material = Enum.Material.Wood, Parent = parent })
		end
	end
	-- 기와 지붕 (양쪽 비탈 + 휘어 오른 처마)
	for _, side in ipairs({ -1, 1 }) do
		part({
			Name = "Roof",
			Size = Vector3.new(w + 5, 1, d / 2 + 3.5),
			CFrame = cf * CFrame.new(0, h + 2.4, side * (d / 4 + 0.6)) * CFrame.Angles(side * math.rad(28), 0, 0),
			Color = ROOF,
			Material = Enum.Material.Slate,
			Parent = parent,
		})
	end
	part({ Name = "Ridge", Size = Vector3.new(w + 6, 1.2, 1.4), CFrame = cf * CFrame.new(0, h + 4.6, 0), Color = Color3.fromRGB(40, 40, 48), Material = Enum.Material.Slate, Parent = parent })
	part({ Name = "Door", Size = Vector3.new(4, 7, 0.4), CFrame = cf * CFrame.new(0, 3.5, -d / 2 - 0.1), Color = Color3.fromRGB(90, 55, 35), Material = Enum.Material.Wood, Parent = parent })
	-- 붉은 등
	local lamp = part({ Name = "Lantern", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = cf * CFrame.new(2.8, 8, -d / 2 - 1), Color = Color3.fromRGB(230, 60, 40), Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 140, 90)
	light.Range = 14
	light.Brightness = 1.2
	light.Parent = lamp
end

local function tree(at: Vector3, s: number, parent: Instance, blossom: boolean?)
	part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10 * s, 1.6 * s, 1.6 * s), CFrame = CFrame.new(at + Vector3.new(0, 5 * s, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(90, 60, 40), Material = Enum.Material.Wood, Parent = parent })
	local leaf = blossom and Color3.fromRGB(255, 180, 210) or Color3.fromRGB(70, 120, 60)
	for i = 1, 3 do
		part({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 1, 1) * (6 + i) * s,
			CFrame = CFrame.new(at + Vector3.new(rng:NextNumber(-2, 2) * s, (8 + i * 1.5) * s, rng:NextNumber(-2, 2) * s)),
			Color = leaf:Lerp(Color3.new(1, 1, 1), rng:NextNumber(0, 0.15)),
			Material = Enum.Material.Grass,
			CanCollide = false,
			Parent = parent,
		})
	end
end

local function rock(at: Vector3, s: number, parent: Instance, color: Color3?)
	part({
		Name = "Rock",
		Size = Vector3.new(rng:NextNumber(0.8, 1.3), rng:NextNumber(0.5, 0.9), rng:NextNumber(0.8, 1.3)) * s,
		CFrame = CFrame.new(at + Vector3.new(0, s * 0.3, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)),
		Color = color or Color3.fromRGB(120, 115, 110),
		Material = Enum.Material.Slate,
		Parent = parent,
	})
end

local function bamboo(at: Vector3, parent: Instance)
	local h = rng:NextNumber(22, 38)
	part({ Name = "Bamboo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 1, 1), CFrame = CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(rng:NextNumber(-0.05, 0.05), 0, math.rad(90) + rng:NextNumber(-0.05, 0.05)), Color = Color3.fromRGB(110, 160, 70):Lerp(Color3.fromRGB(170, 190, 90), rng:NextNumber()), Material = Enum.Material.SmoothPlastic, Parent = parent })
	part({ Name = "BambooLeaf", Size = Vector3.new(6, 0.3, 2.5), CFrame = CFrame.new(at + Vector3.new(1.5, h - 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0.4), Color = Color3.fromRGB(90, 150, 60), Material = Enum.Material.Grass, CanCollide = false, Parent = parent })
end

------------------------------------------------------------------------
-- 땅
------------------------------------------------------------------------
local function ground()
	-- 바탕 풀밭 (2048 넘지 않게 네 조각)
	local half = 900
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			part({ Name = "BaseGround", Size = Vector3.new(half, 6, half), Position = Vector3.new(x * half / 2, -3, z * half / 2), Color = Color3.fromRGB(105, 135, 80), Material = Enum.Material.Grass, Parent = folder })
		end
	end
	-- 지역 바닥 (조금 두껍게 깔아 겹쳐 깜빡이지 않게)
	for _, r in ipairs(Config.Regions) do
		part({ Name = "RegionGround", Size = Vector3.new(r.size.X, 1, r.size.Z), Position = r.center + Vector3.new(0, -0.35, 0), Color = r.ground, Material = r.material, Parent = folder })
	end
	-- 마을에서 각 지역으로 가는 흙길
	for _, dir in ipairs({ Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0), Vector3.new(0, 0, -1) }) do
		local len = 260
		local c = dir * (180 + len / 2 - 40)
		part({ Name = "Road", Size = dir.X ~= 0 and Vector3.new(len, 1, 18) or Vector3.new(18, 1, len), Position = c + Vector3.new(0, -0.25, 0), Color = Color3.fromRGB(170, 145, 105), Material = Enum.Material.Ground, Parent = folder })
	end
	-- 세상 끝 (보이지 않는 벽)
	for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		local size = d[1] ~= 0 and Vector3.new(40, 400, 1800) or Vector3.new(1800, 400, 40)
		part({ Name = "WorldWall", Size = size, Position = Vector3.new(d[1] * 880, 200, d[2] * 880), Transparency = 1, Parent = folder })
	end
	-- 멀리 둘러싼 산 (배경)
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		local dist = 1050 + rng:NextNumber(-60, 60)
		local h = rng:NextNumber(160, 320)
		part({
			Name = "FarMountain",
			Size = Vector3.new(rng:NextNumber(260, 420), h, rng:NextNumber(200, 300)),
			CFrame = CFrame.new(math.cos(a) * dist, h / 2 - 20, math.sin(a) * dist) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, rng:NextNumber(-0.1, 0.1)),
			Color = Color3.fromRGB(95, 110, 120):Lerp(Color3.fromRGB(140, 150, 160), rng:NextNumber()),
			Material = Enum.Material.Rock,
			CanCollide = false,
			Parent = folder,
		})
	end
end

------------------------------------------------------------------------
-- 청운 마을
------------------------------------------------------------------------
local function village(out: any)
	local f = Instance.new("Folder")
	f.Name = "Village"
	f.Parent = folder
	-- 마을 담 (낮은 돌담, 네 방향 입구)
	local R = 175
	for _, side in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		for _, seg in ipairs({ -1, 1 }) do
			local len = R - 14
			local along = seg * (14 + len / 2)
			local pos = side[1] ~= 0 and Vector3.new(side[1] * R, 2, along) or Vector3.new(along, 2, side[2] * R)
			local size = side[1] ~= 0 and Vector3.new(3, 4, len) or Vector3.new(len, 4, 3)
			part({ Name = "VillageWall", Size = size, Position = pos, Color = Color3.fromRGB(160, 150, 135), Material = Enum.Material.Cobblestone, Parent = f })
		end
	end
	-- 마을 문 (북·서·동)
	for _, g in ipairs({ { Vector3.new(0, 0, -R), 0 }, { Vector3.new(-R, 0, 0), math.rad(90) }, { Vector3.new(R, 0, 0), math.rad(90) } }) do
		local cf = CFrame.new(g[1]) * CFrame.Angles(0, g[2], 0)
		for _, x in ipairs({ -1, 1 }) do
			part({ Name = "GatePost", Size = Vector3.new(2.5, 18, 2.5), CFrame = cf * CFrame.new(x * 12, 9, 0), Color = Color3.fromRGB(170, 40, 35), Material = Enum.Material.Wood, Parent = f })
		end
		part({ Name = "GateBeam", Size = Vector3.new(32, 2, 3), CFrame = cf * CFrame.new(0, 17, 0), Color = Color3.fromRGB(50, 45, 50), Material = Enum.Material.Slate, Parent = f })
		part({ Name = "GateBeam2", Size = Vector3.new(27, 1.4, 2.4), CFrame = cf * CFrame.new(0, 14, 0), Color = Color3.fromRGB(170, 40, 35), Material = Enum.Material.Wood, Parent = f })
	end
	-- 집들 (둘레)
	local spots = {
		{ -130, -140 }, { -90, -150 }, { 90, -150 }, { 130, -140 },
		{ -145, -60 }, { -145, 40 }, { -145, 120 }, { 145, -60 }, { 145, 40 }, { 145, 120 },
		{ -100, 150 }, { -50, 155 }, { 50, 155 }, { 100, 150 },
	}
	for _, s in ipairs(spots) do
		local x, z = s[1], s[2]
		local rot = math.abs(x) > 130 and (x > 0 and math.rad(-90) or math.rad(90)) or (z > 0 and math.rad(180) or 0)
		house(Vector3.new(x, 0, z), rng:NextNumber(18, 26), rng:NextNumber(14, 18), rot, f)
	end
	-- 매화나무
	for _, s in ipairs({ { -40, -60 }, { 40, -60 }, { -110, 70 }, { 110, 70 }, { -60, 40 }, { 60, 40 } }) do
		tree(Vector3.new(s[1], 0, s[2]), 1, f, true)
	end

	-- 비무대: 돌 단, 네 기둥, 붉은 줄, 계단
	local ring = Config.RING
	local c = ring.center
	part({ Name = "RingBase", Size = Vector3.new(ring.size, ring.height, ring.size), Position = c + Vector3.new(0, ring.height / 2, 0), Color = Color3.fromRGB(150, 140, 125), Material = Enum.Material.Granite, Parent = f })
	part({ Name = "RingTop", Size = Vector3.new(ring.size - 2, 0.3, ring.size - 2), Position = c + Vector3.new(0, ring.height + 0.1, 0), Color = Color3.fromRGB(175, 60, 50), Material = Enum.Material.Fabric, Parent = f })
	part({ Name = "RingMark", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 18, 18), CFrame = CFrame.new(c + Vector3.new(0, ring.height + 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 230, 210), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
	local hs = ring.size / 2
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			part({ Name = "RingPost", Size = Vector3.new(2, 8, 2), Position = c + Vector3.new(x * (hs - 1), ring.height + 4, z * (hs - 1)), Color = Color3.fromRGB(60, 40, 30), Material = Enum.Material.Wood, Parent = f })
		end
	end
	for _, h in ipairs({ 3.5, 6 }) do
		for _, side in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 } }) do
			local size = side[1] ~= 0 and Vector3.new(0.3, 0.3, ring.size - 2) or Vector3.new(ring.size - 2, 0.3, 0.3)
			part({ Name = "RingRope", Size = size, Position = c + Vector3.new(side[1] * (hs - 1), ring.height + h, side[2] * (hs - 1)), Color = Color3.fromRGB(220, 40, 40), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
		end
	end
	for i = 1, 3 do
		part({ Name = "RingStep", Size = Vector3.new(14, i, 3), Position = c + Vector3.new(0, i / 2, -hs - 4.5 + i * 1.5 - 1.5), Color = Color3.fromRGB(140, 130, 115), Material = Enum.Material.Granite, Parent = f })
	end
	local board = part({ Name = "RingSign", Size = Vector3.new(26, 7, 1), Position = c + Vector3.new(0, ring.height + 12, hs + 1), Color = Color3.fromRGB(40, 25, 20), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(board, Enum.NormalId.Front, { { "⚔ 비무대", Color3.fromRGB(255, 220, 140), 0.6 }, { "올라선 사람끼리 겨룬다", Color3.fromRGB(255, 255, 255), 0.4 } })
	sign(board, Enum.NormalId.Back, { { "⚔ 비무대", Color3.fromRGB(255, 220, 140), 0.6 }, { "올라선 사람끼리 겨룬다", Color3.fromRGB(255, 255, 255), 0.4 } })

	-- 권법 전당: 일곱 사부의 단
	local H = Config.HALL
	part({ Name = "HallFloor", Size = Vector3.new(120, 1.2, 40), Position = H + Vector3.new(0, 0.6, -6), Color = Color3.fromRGB(120, 100, 80), Material = Enum.Material.WoodPlanks, Parent = f })
	part({ Name = "HallBack", Size = Vector3.new(120, 22, 2), Position = H + Vector3.new(0, 11, -26), Color = Color3.fromRGB(140, 40, 35), Material = Enum.Material.Wood, Parent = f })
	part({ Name = "HallRoof", Size = Vector3.new(130, 2, 46), Position = H + Vector3.new(0, 23, -6), Color = ROOF, Material = Enum.Material.Slate, Parent = f })
	local hallSign = part({ Name = "HallSign", Size = Vector3.new(40, 8, 1), Position = H + Vector3.new(0, 17, -24.5), Color = Color3.fromRGB(30, 20, 18), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(hallSign, Enum.NormalId.Front, { { "武 권법 전당", Color3.fromRGB(255, 215, 120), 0.6 }, { "일곱 권법의 사부가 기다린다", Color3.fromRGB(255, 255, 255), 0.4 } })
	out.hall = {}
	for i, style in ipairs(Config.Styles) do
		local x = (i - 4) * 15
		local ped = part({ Name = "MasterPedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 8, 8), CFrame = CFrame.new(H + Vector3.new(x, 2, -12)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(60, 50, 45), Material = Enum.Material.Marble, Parent = f })
		local orb = part({ Name = "StyleOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), Position = H + Vector3.new(x, 7.5, -12), Color = style.color, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		orb:SetAttribute("Spin", true)
		local light = Instance.new("PointLight")
		light.Color = style.color
		light.Range = 12
		light.Parent = orb
		local tag = part({ Name = "StyleSign", Size = Vector3.new(12, 4, 0.5), Position = H + Vector3.new(x, 12, -12), Color = Color3.fromRGB(25, 18, 15), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
		sign(tag, Enum.NormalId.Front, { { style.icon .. " " .. style.name, style.color, 0.55 }, { style.hanja, Color3.fromRGB(230, 220, 200), 0.45 } })
		ped:SetAttribute("Style", style.id)
		table.insert(out.hall, { prompt = prompt(ped, "권법 배우기", style.name, "Master"), style = style.id, pos = ped.Position })
	end

	-- 상점 (객잔 앞 좌판)
	local stall = part({ Name = "Shop", Size = Vector3.new(14, 4, 7), Position = Vector3.new(-75, 2, 25), Color = Color3.fromRGB(130, 85, 50), Material = Enum.Material.Wood, Parent = f })
	part({ Name = "ShopRoof", Size = Vector3.new(17, 0.8, 10), CFrame = CFrame.new(-75, 10, 25) * CFrame.Angles(math.rad(-10), 0, 0), Color = Color3.fromRGB(200, 60, 50), Material = Enum.Material.Fabric, Parent = f })
	for _, x in ipairs({ -1, 1 }) do
		part({ Name = "ShopPole", Size = Vector3.new(0.6, 9, 0.6), Position = Vector3.new(-75 + x * 7.5, 5, 28.5), Color = WOOD, Material = Enum.Material.Wood, Parent = f })
	end
	local shopSign = part({ Name = "ShopSign", Size = Vector3.new(12, 3, 0.4), Position = Vector3.new(-75, 7, 21.2), Color = Color3.fromRGB(30, 20, 18), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(shopSign, Enum.NormalId.Front, { { "🧪 만물상", Color3.fromRGB(255, 220, 140), 1 } })
	out.shop = prompt(stall, "물건 보기", "만물상", "Shop")
end

------------------------------------------------------------------------
-- 수련 자리
------------------------------------------------------------------------
local function trainingSpots(out: any)
	local f = Instance.new("Folder")
	f.Name = "Training"
	f.Parent = folder
	out.train = {}
	for i, spot in ipairs(Config.TrainingSpots) do
		local at = spot.at
		local target: BasePart
		if spot.kind == "rock" then
			rock(at + Vector3.new(4, 0, 4), 9, f)
			target = part({ Name = "LiftRock", Shape = Enum.PartType.Ball, Size = Vector3.new(4.5, 4.5, 4.5), Position = at + Vector3.new(0, 2.2, 0), Color = Color3.fromRGB(130, 125, 115), Material = Enum.Material.Slate, Parent = f })
		elseif spot.kind == "dummy" then
			target = part({ Name = "Mook", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7, 2.4, 2.4), CFrame = CFrame.new(at + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(140, 95, 55), Material = Enum.Material.Wood, Parent = f })
			for k, h in ipairs({ 5.2, 4.6, 3.0 }) do
				part({ Name = "MookArm", Size = Vector3.new(0.5, 0.5, 3), CFrame = CFrame.new(at + Vector3.new((k - 2) * 0.6, h, -1.6)) * CFrame.Angles(math.rad(k == 3 and -20 or 10), math.rad((k - 2) * 25), 0), Color = Color3.fromRGB(120, 80, 45), Material = Enum.Material.Wood, Parent = f })
			end
			part({ Name = "MookBase", Size = Vector3.new(5, 1, 5), Position = at + Vector3.new(0, 0.5, 0), Color = Color3.fromRGB(90, 60, 40), Material = Enum.Material.Wood, Parent = f })
		elseif spot.kind == "waterfall" then
			target = part({ Name = "MeditationStone", Size = Vector3.new(8, 1.2, 8), Position = at + Vector3.new(0, 0.6, 0), Color = Color3.fromRGB(110, 120, 120), Material = Enum.Material.Slate, Parent = f })
		else
			target = part({ Name = "BambooPost", Size = Vector3.new(3, 8, 3), Position = at + Vector3.new(0, 4, 0), Color = Color3.fromRGB(150, 180, 80), Material = Enum.Material.Wood, Parent = f })
			local s = part({ Name = "BambooSign", Size = Vector3.new(10, 3, 0.4), Position = at + Vector3.new(0, 10, 0), Color = Color3.fromRGB(30, 25, 18), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
			sign(s, Enum.NormalId.Front, { { "🎋 경공 수련", Color3.fromRGB(200, 255, 160), 1 } })
		end
		local info = Config.Training[spot.kind]
		table.insert(out.train, { prompt = prompt(target, "수련하기", info.icon .. " " .. info.name, "Train"), kind = spot.kind, index = i, pos = at })
	end
	-- 대나무 경공 고리 (숲 속에 한 바퀴)
	out.rings = {}
	local base = Vector3.new(-380, 0, -10)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local pos = base + Vector3.new(math.cos(a) * 70, 6 + (k % 3) * 7, math.sin(a) * 70)
		local ringModel = Instance.new("Model")
		ringModel.Name = "BambooRing" .. (k + 1)
		ringModel.Parent = f
		for s = 0, 11 do
			local b = s / 12 * math.pi * 2
			part({ Name = "RingPiece", Size = Vector3.new(1, 1.6, 1), CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(a), 0, math.cos(a))) * CFrame.new(math.cos(b) * 5, math.sin(b) * 5, 0), Color = Color3.fromRGB(170, 255, 120), Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false, Parent = ringModel })
		end
		table.insert(out.rings, pos)
	end
end

------------------------------------------------------------------------
-- 대나무 숲, 흑호채, 폭포 계곡
------------------------------------------------------------------------
local function regions()
	-- 대나무 숲
	local bf = Instance.new("Folder")
	bf.Name = "Bamboo"
	bf.Parent = folder
	local B = Config.Regions[2]
	for _ = 1, 140 do
		local x = B.center.X + rng:NextNumber(-B.size.X / 2 + 10, B.size.X / 2 - 10)
		local z = B.center.Z + rng:NextNumber(-B.size.Z / 2 + 10, B.size.Z / 2 - 10)
		-- 길과 경공 고리 자리는 비워 둔다
		local d = (Vector3.new(x, 0, z) - Vector3.new(-380, 0, -10)).Magnitude
		if math.abs(z) > 14 and (d < 55 or d > 85) then
			bamboo(Vector3.new(x, 0, z), bf)
		end
	end
	-- 흑호채: 나무 울타리, 망루, 천막
	local ff = Instance.new("Folder")
	ff.Name = "Fort"
	ff.Parent = folder
	local F = Config.Regions[3]
	local fx, fz = F.center.X, F.center.Z
	local fw, fd = 300, 340
	for _, side in ipairs({ { 1, 0 }, { -1, 0 }, { 0, -1 }, { 0, 1 } }) do
		local count = 30
		for k = 0, count - 1 do
			local along = -0.5 + (k + 0.5) / count
			local gateGap = side[2] == 1 and math.abs(along) < 0.08
			if not gateGap then
				local pos = side[1] ~= 0 and Vector3.new(fx + side[1] * fw / 2, 0, fz + along * fd) or Vector3.new(fx + along * fw, 0, fz + side[2] * fd / 2)
				local h = rng:NextNumber(11, 14)
				part({ Name = "Palisade", Size = Vector3.new(1.6, h, 1.6), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Color = Color3.fromRGB(100, 70, 45), Material = Enum.Material.Wood, Parent = ff })
				if side[1] ~= 0 then
					part({ Name = "PalisadeFill", Size = Vector3.new(1.2, 10, fd / count + 0.4), Position = pos + Vector3.new(0, 5, 0), Color = Color3.fromRGB(90, 62, 40), Material = Enum.Material.Wood, Parent = ff })
				else
					part({ Name = "PalisadeFill", Size = Vector3.new(fw / count + 0.4, 10, 1.2), Position = pos + Vector3.new(0, 5, 0), Color = Color3.fromRGB(90, 62, 40), Material = Enum.Material.Wood, Parent = ff })
				end
			end
		end
	end
	for _, c in ipairs({ { -1, 1 }, { 1, 1 }, { -1, -1 }, { 1, -1 } }) do
		local pos = Vector3.new(fx + c[1] * (fw / 2 - 6), 0, fz + c[2] * (fd / 2 - 6))
		for _, dx in ipairs({ -1, 1 }) do
			for _, dz in ipairs({ -1, 1 }) do
				part({ Name = "TowerLeg", Size = Vector3.new(1, 22, 1), Position = pos + Vector3.new(dx * 3, 11, dz * 3), Color = Color3.fromRGB(90, 62, 40), Material = Enum.Material.Wood, Parent = ff })
			end
		end
		part({ Name = "TowerDeck", Size = Vector3.new(9, 1, 9), Position = pos + Vector3.new(0, 22, 0), Color = Color3.fromRGB(110, 75, 50), Material = Enum.Material.WoodPlanks, Parent = ff })
		part({ Name = "TowerRoof", Size = Vector3.new(11, 1, 11), CFrame = CFrame.new(pos + Vector3.new(0, 28, 0)) * CFrame.Angles(0, math.rad(45), 0), Color = Color3.fromRGB(60, 45, 35), Material = Enum.Material.Wood, Parent = ff })
	end
	for _ = 1, 10 do
		local pos = Vector3.new(fx + rng:NextNumber(-110, 110), 0, fz + rng:NextNumber(-60, 140))
		part({ Name = "Tent", Size = Vector3.new(12, 8, 10), CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), math.rad(45)), Color = Color3.fromRGB(150, 130, 100), Material = Enum.Material.Fabric, Parent = ff })
	end
	-- 두목의 단 (깃발과 화톳불)
	local bossAt = Config.Regions[3].boss.at
	part({ Name = "BossFloor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 70, 70), CFrame = CFrame.new(bossAt + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(80, 60, 50), Material = Enum.Material.Cobblestone, Parent = ff })
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local p = bossAt + Vector3.new(math.cos(a) * 33, 0, math.sin(a) * 33)
		part({ Name = "BrazierPole", Size = Vector3.new(1, 6, 1), Position = p + Vector3.new(0, 3, 0), Color = Color3.fromRGB(60, 50, 45), Material = Enum.Material.Metal, Parent = ff })
		local fire = part({ Name = "Brazier", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), Position = p + Vector3.new(0, 6.8, 0), Color = Color3.fromRGB(255, 140, 50), Material = Enum.Material.Neon, CanCollide = false, Parent = ff })
		local flame = Instance.new("Fire")
		flame.Size = 6
		flame.Heat = 8
		flame.Parent = fire
	end
	local banner = part({ Name = "FortBanner", Size = Vector3.new(16, 22, 0.4), Position = bossAt + Vector3.new(0, 18, -38), Color = Color3.fromRGB(30, 25, 25), Material = Enum.Material.Fabric, CanCollide = false, Parent = ff })
	sign(banner, Enum.NormalId.Front, { { "黑虎", Color3.fromRGB(230, 60, 40), 0.7 }, { "흑호채", Color3.fromRGB(255, 220, 160), 0.3 } })
	sign(banner, Enum.NormalId.Back, { { "黑虎", Color3.fromRGB(230, 60, 40), 0.7 }, { "흑호채", Color3.fromRGB(255, 220, 160), 0.3 } })

	-- 비류 폭포 계곡: 동쪽 절벽, 폭포, 연못, 나무와 바위
	local vf = Instance.new("Folder")
	vf.Name = "Valley"
	vf.Parent = folder
	local V = Config.Regions[4]
	local cliffX = V.center.X + V.size.X / 2 - 15
	for k = -5, 5 do
		local h = rng:NextNumber(90, 140)
		part({ Name = "Cliff", Size = Vector3.new(40, h, 46), CFrame = CFrame.new(cliffX + rng:NextNumber(-6, 6), h / 2 - 5, k * 40) * CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), 0), Color = Color3.fromRGB(105, 100, 95), Material = Enum.Material.Rock, Parent = vf })
	end
	local fallX = cliffX - 22
	local fall = part({ Name = "Waterfall", Size = Vector3.new(3, 110, 30), Position = Vector3.new(fallX, 55, 0), Color = Color3.fromRGB(170, 220, 255), Material = Enum.Material.Glass, Transparency = 0.35, CanCollide = false, Parent = vf })
	local mist = Instance.new("ParticleEmitter")
	mist.Rate = 40
	mist.Lifetime = NumberRange.new(1.5, 3)
	mist.Speed = NumberRange.new(-30, -50)
	mist.SpreadAngle = Vector2.new(10, 10)
	mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6) })
	mist.Transparency = NumberSequence.new(0.6, 1)
	mist.Color = ColorSequence.new(Color3.fromRGB(230, 245, 255))
	mist.EmissionDirection = Enum.NormalId.Bottom
	mist.Parent = fall
	part({ Name = "Pond", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 90, 90), CFrame = CFrame.new(fallX - 35, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(70, 140, 180), Material = Enum.Material.Glass, Transparency = 0.25, CanCollide = false, Parent = vf })
	for _ = 1, 26 do
		local x = V.center.X + rng:NextNumber(-V.size.X / 2 + 20, V.size.X / 2 - 70)
		local z = V.center.Z + rng:NextNumber(-V.size.Z / 2 + 20, V.size.Z / 2 - 20)
		if math.abs(z) > 30 then
			tree(Vector3.new(x, 0, z), rng:NextNumber(1, 1.6), vf)
		end
	end
	for _ = 1, 30 do
		rock(Vector3.new(V.center.X + rng:NextNumber(-200, 160), 0, V.center.Z + rng:NextNumber(-200, 200)), rng:NextNumber(3, 9), vf)
	end
	-- 바깥 들판의 나무
	for _ = 1, 50 do
		local x, z = rng:NextNumber(-800, 800), rng:NextNumber(-800, 800)
		local inside = false
		for _, r in ipairs(Config.Regions) do
			if math.abs(x - r.center.X) < r.size.X / 2 + 10 and math.abs(z - r.center.Z) < r.size.Z / 2 + 10 then
				inside = true
			end
		end
		if not inside then
			tree(Vector3.new(x, 0, z), rng:NextNumber(1.2, 2), folder)
		end
	end
end

------------------------------------------------------------------------
-- 지역 이름 표지
------------------------------------------------------------------------
local function regionSigns()
	for _, r in ipairs(Config.Regions) do
		if not r.safe then
			local dir = Vector3.new(r.center.X, 0, r.center.Z).Unit
			local pos = r.center - dir * (math.max(r.size.X, r.size.Z) / 2 - 12)
			local post = part({ Name = "RegionPost", Size = Vector3.new(1.4, 10, 1.4), Position = pos + Vector3.new(14, 5, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = folder })
			local board = part({ Name = "RegionSign", Size = Vector3.new(16, 4, 0.5), CFrame = CFrame.lookAt(pos + Vector3.new(14, 10, 0), pos + Vector3.new(14, 10, 0) - dir), Color = Color3.fromRGB(35, 25, 18), Material = Enum.Material.Wood, CanCollide = false, Parent = folder })
			sign(board, Enum.NormalId.Front, { { r.name, Color3.fromRGB(255, 225, 160), 1 } })
			local _ = post
		end
	end
end

function World.build(): any
	folder = Instance.new("Folder")
	folder.Name = "Gangho"
	folder.Parent = workspace
	local old = workspace:FindFirstChild("Baseplate")
	if old then
		old:Destroy()
	end
	local out: any = {}
	ground()
	village(out)
	trainingSpots(out)
	regions()
	regionSigns()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "VillageSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Config.SPAWN - Vector3.new(0, 3.5, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder
	return out
end

return World
