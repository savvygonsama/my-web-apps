-- 권왕: 강호 (오픈 월드). 가운데 청운 마을, 서쪽 대나무 숲, 북쪽 흑호채, 동쪽 비류 폭포 계곡, 남쪽 들판
-- 그리고 강호 곳곳에 흩어진 일곱 사부의 자리
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
	atmo.Density = 0.24
	atmo.Haze = 1.1
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
-- 길
------------------------------------------------------------------------
-- 점 p가 어느 길에서 margin칸 안인가 (나무·대나무를 길 위에 심지 않게)
local function nearRoad(p: Vector3, margin: number): boolean
	local q = Vector3.new(p.X, 0, p.Z)
	for _, road in ipairs(Config.Roads) do
		for i = 1, #road - 1 do
			local a, b = road[i], road[i + 1]
			local ab = b - a
			local len2 = ab:Dot(ab)
			local t = len2 > 0 and math.clamp((q - a):Dot(ab) / len2, 0, 1) or 0
			if (q - (a + ab * t)).Magnitude < margin then
				return true
			end
		end
	end
	return false
end
World.nearRoad = nearRoad

local function roads()
	for k, road in ipairs(Config.Roads) do
		for i = 1, #road - 1 do
			local a, b = road[i], road[i + 1]
			local len = (b - a).Magnitude
			if len > 0.5 then
				-- 길마다 살짝 다른 높이 (겹치는 곳이 깜빡이지 않게)
				local y = -0.08 + k * 0.012
				local mid = (a + b) / 2 + Vector3.new(0, y, 0)
				part({ Name = "Road", Size = Vector3.new(18, 1, len + 18), CFrame = CFrame.lookAt(mid, mid + (b - a)), Color = Color3.fromRGB(170, 145, 105), Material = Enum.Material.Ground, Parent = folder })
			end
		end
	end
end

------------------------------------------------------------------------
-- 땅
------------------------------------------------------------------------
local function ground()
	-- 바탕 풀밭 (2048 넘지 않게 4×4 조각)
	local W = Config.WORLD_HALF
	local n = 4
	local tile = W * 2 / n
	for i = 0, n - 1 do
		for j = 0, n - 1 do
			part({ Name = "BaseGround", Size = Vector3.new(tile, 6, tile), Position = Vector3.new(-W + tile * (i + 0.5), -3, -W + tile * (j + 0.5)), Color = Color3.fromRGB(105, 135, 80), Material = Enum.Material.Grass, Parent = folder })
		end
	end
	-- 지역 바닥 (조금 두껍게 깔아 겹쳐 깜빡이지 않게)
	for k, r in ipairs(Config.Regions) do
		if not r.noGround then
			part({ Name = "RegionGround", Size = Vector3.new(r.size.X, 1, r.size.Z), Position = r.center + Vector3.new(0, -0.35 + k * 0.01, 0), Color = r.ground, Material = r.material, Parent = folder })
		end
	end
	roads()
	-- 세상 끝 (보이지 않는 벽)
	-- (한 조각이 2048을 넘지 않게 두 토막)
	for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		for _, half in ipairs({ -1, 1 }) do
			local along = half * W / 2
			local size = d[1] ~= 0 and Vector3.new(40, 400, W) or Vector3.new(W, 400, 40)
			local pos = d[1] ~= 0 and Vector3.new(d[1] * (W - 20), 200, along) or Vector3.new(along, 200, d[2] * (W - 20))
			part({ Name = "WorldWall", Size = size, Position = pos, Transparency = 1, Parent = folder })
		end
	end
	-- 멀리 둘러싼 산 (배경)
	for i = 0, 31 do
		local a = i / 32 * math.pi * 2
		local dist = Config.WORLD_HALF + 260 + rng:NextNumber(-60, 60)
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
	-- 마을 문 (네 방향)
	for _, g in ipairs({ { Vector3.new(0, 0, -R), 0 }, { Vector3.new(0, 0, R), 0 }, { Vector3.new(-R, 0, 0), math.rad(90) }, { Vector3.new(R, 0, 0), math.rad(90) } }) do
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

	-- 강호 안내판: 일곱 사부가 어디 있는지
	local boardAt = Vector3.new(0, 0, -110)
	for _, x in ipairs({ -1, 1 }) do
		part({ Name = "BoardPost", Size = Vector3.new(1.4, 16, 1.4), Position = boardAt + Vector3.new(x * 17, 8, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = f })
	end
	part({ Name = "BoardRoof", Size = Vector3.new(40, 1, 5), Position = boardAt + Vector3.new(0, 16.5, 0), Color = ROOF, Material = Enum.Material.Slate, Parent = f })
	local mboard = part({ Name = "MasterBoard", Size = Vector3.new(32, 13, 0.6), Position = boardAt + Vector3.new(0, 9, 0), Color = Color3.fromRGB(35, 25, 18), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	local lines: { { any } } = { { "武 일곱 사부를 찾아가라", Color3.fromRGB(255, 215, 120), 0.16 } }
	for _, style in ipairs(Config.Styles) do
		local m = Config.MASTERS[style.id]
		if m then
			table.insert(lines, { string.format("%s %s — %s · %s", style.icon, style.name, m.name, m.region), style.color, 0.11 })
		end
	end
	table.insert(lines, { "지도: M  ·  권법 창에서 '길 안내'", Color3.fromRGB(230, 220, 200), 0.1 })
	sign(mboard, Enum.NormalId.Front, lines)
	sign(mboard, Enum.NormalId.Back, lines)

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
		if math.abs(z) > 14 and (d < 55 or d > 85) and not nearRoad(Vector3.new(x, 0, z), 14) then
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
		if math.abs(z) > 30 and not nearRoad(Vector3.new(x, 0, z), 16) then
			tree(Vector3.new(x, 0, z), rng:NextNumber(1, 1.6), vf)
		end
	end
	for _ = 1, 30 do
		local at = Vector3.new(V.center.X + rng:NextNumber(-200, 160), 0, V.center.Z + rng:NextNumber(-200, 200))
		if not nearRoad(at, 16) then
			rock(at, rng:NextNumber(3, 9), vf)
		end
	end
	-- 바깥 들판의 나무
	local edge = Config.WORLD_HALF - 60
	for _ = 1, 140 do
		local x, z = rng:NextNumber(-edge, edge), rng:NextNumber(-edge, edge)
		local inside = nearRoad(Vector3.new(x, 0, z), 18)
		for _, r in ipairs(Config.Regions) do
			if not r.noGround and math.abs(x - r.center.X) < r.size.X / 2 + 10 and math.abs(z - r.center.Z) < r.size.Z / 2 + 10 then
				inside = true
			end
		end
		for _, r in ipairs(Config.Regions) do
			for _, camp in ipairs(r.camps or {}) do
				if (Vector3.new(x, 0, z) - camp.at).Magnitude < 30 then
					inside = true
				end
			end
		end
		if not inside then
			tree(Vector3.new(x, 0, z), rng:NextNumber(1.2, 2), folder)
		end
	end
end

------------------------------------------------------------------------
-- 일곱 사부의 자리
------------------------------------------------------------------------
local function light(target: BasePart, color: Color3, range: number, brightness: number?)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness or 1.5
	l.Parent = target
end

local function cyl(name: string, at: Vector3, radius: number, height: number, color: Color3, material: Enum.Material, parent: Instance, collide: boolean?): Part
	return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, radius * 2, radius * 2), CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = material, CanCollide = collide ~= false, Parent = parent })
end

local function emitter(target: BasePart, color: Color3, rate: number, size: number, speed: number, life: number)
	local e = Instance.new("ParticleEmitter")
	e.Rate = rate
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new(0.2, 1)
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.Lifetime = NumberRange.new(life * 0.6, life)
	e.SpreadAngle = Vector2.new(180, 180)
	e.LightEmission = 0.6
	e.Parent = target
end

local SITES: { [string]: (r: any, at: Vector3, color: Color3, f: Instance) -> () } = {}

-- 태허호: 맑은 호수 한가운데 정자, 다리로 건너간다
function SITES.taeheo(r: any, at: Vector3, color: Color3, f: Instance)
	local c = r.center
	cyl("Lake", c + Vector3.new(0, 0.3, 0), 75, 0.6, Color3.fromRGB(80, 150, 200), Enum.Material.Glass, f, false).Transparency = 0.3
	cyl("Island", c + Vector3.new(0, at.Y / 2, 0), 15, at.Y, Color3.fromRGB(150, 140, 120), Enum.Material.Cobblestone, f)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		part({ Name = "PavilionPillar", Size = Vector3.new(1.2, 11, 1.2), Position = c + Vector3.new(math.cos(a) * 10, at.Y + 5.5, math.sin(a) * 10), Color = Color3.fromRGB(170, 45, 40), Material = Enum.Material.Wood, Parent = f })
	end
	cyl("PavilionRoof", c + Vector3.new(0, at.Y + 11.5, 0), 14, 1, ROOF, Enum.Material.Slate, f)
	cyl("PavilionTop", c + Vector3.new(0, at.Y + 12.8, 0), 8, 1.6, ROOF, Enum.Material.Slate, f)
	-- 다리 (길이 오는 쪽으로)
	local dir = Vector3.new(1, 0, -1).Unit
	local from = c + dir * 13
	local to = c + dir * 82
	local mid = (from + to) / 2 + Vector3.new(0, at.Y - 0.4, 0)
	part({ Name = "Bridge", Size = Vector3.new(6, 0.8, (to - from).Magnitude), CFrame = CFrame.lookAt(mid, mid + dir), Color = Color3.fromRGB(130, 90, 55), Material = Enum.Material.WoodPlanks, Parent = f })
	for _, side in ipairs({ -1, 1 }) do
		local off = Vector3.new(-dir.Z, 0, dir.X) * side * 2.8
		part({ Name = "BridgeRail", Size = Vector3.new(0.4, 0.4, (to - from).Magnitude), CFrame = CFrame.lookAt(mid + off + Vector3.new(0, 2.2, 0), mid + off + Vector3.new(0, 2.2, 0) + dir), Color = Color3.fromRGB(170, 45, 40), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	end
	for _ = 1, 18 do
		local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(22, 70)
		cyl("LilyPad", c + Vector3.new(math.cos(a) * d, 0.62, math.sin(a) * d), rng:NextNumber(1, 2), 0.1, Color3.fromRGB(80, 150, 70), Enum.Material.Grass, f, false)
	end
	for _ = 1, 14 do
		local a = rng:NextNumber(0, math.pi * 2)
		local p = c + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(90, 135)
		if not nearRoad(p, 16) then
			tree(p, rng:NextNumber(1.1, 1.6), f)
		end
	end
end

-- 금강사: 돌 기단 위의 절, 큰 종과 향로
function SITES.geumgang(r: any, at: Vector3, color: Color3, f: Instance)
	local base = Vector3.new(at.X, 0, at.Z - 10)
	part({ Name = "TempleBase", Size = Vector3.new(80, at.Y, 56), Position = base + Vector3.new(0, at.Y / 2, 0), Color = Color3.fromRGB(165, 155, 140), Material = Enum.Material.Granite, Parent = f })
	for i = 1, 5 do
		local h = at.Y * i / 5
		part({ Name = "TempleStep", Size = Vector3.new(26, h, 3), Position = base + Vector3.new(0, h / 2, 28 + (5 - i) * 3 + 1.5), Color = Color3.fromRGB(150, 140, 125), Material = Enum.Material.Granite, Parent = f })
	end
	house(base + Vector3.new(0, at.Y, -12), 44, 22, math.pi, f)
	local bellFrame = base + Vector3.new(-28, at.Y, 12)
	for _, x in ipairs({ -1, 1 }) do
		part({ Name = "BellPost", Size = Vector3.new(1, 12, 1), Position = bellFrame + Vector3.new(x * 4, 6, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = f })
	end
	part({ Name = "BellBeam", Size = Vector3.new(10, 1, 1.2), Position = bellFrame + Vector3.new(0, 12, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = f })
	cyl("Bell", bellFrame + Vector3.new(0, 8.5, 0), 2.4, 5, Color3.fromRGB(200, 160, 70), Enum.Material.Metal, f)
	local burner = cyl("Incense", Vector3.new(at.X, at.Y + 1.5, at.Z + 10), 2, 3, Color3.fromRGB(70, 60, 50), Enum.Material.Metal, f)
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(230, 225, 215)
	smoke.Opacity = 0.12
	smoke.RiseVelocity = 3
	smoke.Size = 1
	smoke.Parent = burner
	for _, x in ipairs({ -1, 1 }) do
		local lamp = part({ Name = "StoneLantern", Size = Vector3.new(2.4, 5, 2.4), Position = Vector3.new(at.X + x * 16, at.Y + 2.5, at.Z + 14), Color = Color3.fromRGB(140, 135, 125), Material = Enum.Material.Granite, Parent = f })
		light(lamp, Color3.fromRGB(255, 200, 120), 16)
	end
	for _ = 1, 12 do
		local p = r.center + Vector3.new(rng:NextNumber(-140, 140), 0, rng:NextNumber(-140, 140))
		if (p - base).Magnitude > 60 and not nearRoad(p, 16) then
			tree(p, rng:NextNumber(1.2, 1.8), f)
		end
	end
end

-- 매화원: 꽃잎이 흩날리는 매화나무 숲과 둥근 달문
function SITES.maehwa(r: any, at: Vector3, color: Color3, f: Instance)
	local c = r.center
	tree(Vector3.new(at.X, 0, at.Z - 14), 2.6, f, true)
	for _ = 1, 42 do
		local p = c + Vector3.new(rng:NextNumber(-140, 140), 0, rng:NextNumber(-140, 140))
		if (p - Vector3.new(at.X, 0, at.Z)).Magnitude > 28 and not nearRoad(p, 14) then
			tree(p, rng:NextNumber(1.1, 1.7), f, true)
		end
	end
	-- 달문 (길이 들어오는 쪽)
	local gate = Vector3.new(c.X, 0, c.Z + 92)
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		if 10 + math.sin(a) * 10 < 3 then
			continue
		end
		part({ Name = "MoonGate", Size = Vector3.new(2.6, 2.6, 2), Position = gate + Vector3.new(math.cos(a) * 10, 10 + math.sin(a) * 10, 0), Color = Color3.fromRGB(235, 225, 215), Material = Enum.Material.Plaster, Parent = f })
	end
	-- 꽃잎 바람
	local sky = part({ Name = "PetalSky", Size = Vector3.new(120, 1, 120), Position = Vector3.new(at.X, 34, at.Z), Transparency = 1, CanCollide = false, Parent = f })
	local e = Instance.new("ParticleEmitter")
	e.Rate = 30
	e.Color = ColorSequence.new(Color3.fromRGB(255, 190, 215))
	e.Size = NumberSequence.new(0.35)
	e.Lifetime = NumberRange.new(6, 9)
	e.Speed = NumberRange.new(3, 6)
	e.Acceleration = Vector3.new(1.5, -1.2, 0.8)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.RotSpeed = NumberRange.new(-120, 120)
	e.Parent = sky
	part({ Name = "PlumPath", Size = Vector3.new(6, 0.4, 70), Position = Vector3.new(at.X, 0.25, at.Z + 45), Color = Color3.fromRGB(200, 190, 175), Material = Enum.Material.Cobblestone, Parent = f })
end

-- 천룡봉: 비탈길로 오르는 바위 봉우리, 금빛 용이 기둥을 감는다
function SITES.cheonryong(r: any, at: Vector3, color: Color3, f: Instance)
	local top = at.Y
	part({ Name = "PeakRock", Size = Vector3.new(56, top, 56), Position = Vector3.new(at.X, top / 2, at.Z), Color = Color3.fromRGB(115, 110, 105), Material = Enum.Material.Rock, Parent = f })
	local rampC = Vector3.new(at.X - 28 - 22, top / 2, at.Z)
	local ramp = Instance.new("WedgePart")
	ramp.Name = "PeakRamp"
	ramp.Anchored = true
	ramp.Size = Vector3.new(14, top, 44)
	ramp.CFrame = CFrame.lookAt(rampC, rampC - Vector3.xAxis)
	ramp.Color = Color3.fromRGB(125, 118, 110)
	ramp.Material = Enum.Material.Slate
	ramp.Parent = f
	local pillar = part({ Name = "DragonPillar", Size = Vector3.new(4, 34, 4), Position = Vector3.new(at.X + 18, top + 17, at.Z), Color = Color3.fromRGB(170, 40, 35), Material = Enum.Material.Wood, Parent = f })
	local _ = pillar
	for k = 0, 40 do
		local u = k / 40
		local a = u * math.pi * 5
		local p = Vector3.new(at.X + 18 + math.cos(a) * 4.5, top + 2 + u * 34, at.Z + math.sin(a) * 4.5)
		local ball = part({ Name = "DragonBody", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1) * (2.6 - u * 1.2), Position = p, Color = Color3.fromRGB(255, 200, 80), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		if k == 40 then
			ball.Size = Vector3.new(4, 4, 4)
			light(ball, Color3.fromRGB(255, 200, 90), 30, 2)
		end
	end
	for _ = 1, 26 do
		local p = r.center + Vector3.new(rng:NextNumber(-140, 140), 0, rng:NextNumber(-140, 140))
		if (p - Vector3.new(at.X, 0, at.Z)).Magnitude > 50 and not nearRoad(p, 16) then
			rock(p, rng:NextNumber(5, 14), f, Color3.fromRGB(110, 105, 100))
		end
	end
end

-- 무영곡: 높은 검은 절벽 사이 무너진 사당, 보랏빛 등
function SITES.muyeong(r: any, at: Vector3, color: Color3, f: Instance)
	local c = r.center
	for _, side in ipairs({ -1, 1 }) do
		for k = -3, 3 do
			local h = rng:NextNumber(60, 110)
			part({ Name = "DarkCliff", Size = Vector3.new(46, h, 30), CFrame = CFrame.new(c.X + k * 42, h / 2 - 4, c.Z + side * rng:NextNumber(70, 90)) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), Color = Color3.fromRGB(45, 42, 52), Material = Enum.Material.Rock, Parent = f })
		end
	end
	part({ Name = "ShrineBase", Size = Vector3.new(34, at.Y, 34), Position = Vector3.new(at.X, at.Y / 2, at.Z), Color = Color3.fromRGB(70, 65, 75), Material = Enum.Material.Slate, Parent = f })
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local h = rng:NextNumber(4, 14)
		part({ Name = "BrokenPillar", Size = Vector3.new(2, h, 2), CFrame = CFrame.new(at.X + math.cos(a) * 14, at.Y + h / 2, at.Z + math.sin(a) * 14) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, rng:NextNumber(-0.15, 0.15)), Color = Color3.fromRGB(90, 80, 95), Material = Enum.Material.Slate, Parent = f })
	end
	for k = 0, 5 do
		local p = Vector3.new(c.X + 80 - k * 22, 0, c.Z + (k % 2 == 0 and -14 or 14))
		part({ Name = "LanternPole", Size = Vector3.new(0.6, 7, 0.6), Position = p + Vector3.new(0, 3.5, 0), Color = Color3.fromRGB(40, 35, 45), Material = Enum.Material.Wood, Parent = f })
		local lamp = part({ Name = "ShadowLantern", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), Position = p + Vector3.new(0, 7.5, 0), Color = color, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		light(lamp, color, 18, 2)
	end
end

-- 뇌운 고원: 돌 원단과 번개 받는 쇠기둥
function SITES.byeokryeok(r: any, at: Vector3, color: Color3, f: Instance)
	cyl("ThunderRing", Vector3.new(at.X, at.Y / 2, at.Z), 24, at.Y, Color3.fromRGB(110, 110, 120), Enum.Material.Granite, f)
	cyl("ThunderMark", Vector3.new(at.X, at.Y + 0.05, at.Z), 10, 0.1, Color3.fromRGB(255, 230, 120), Enum.Material.Neon, f, false).Transparency = 0.5
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local p = Vector3.new(at.X + math.cos(a) * 40, 0, at.Z + math.sin(a) * 40)
		part({ Name = "LightningRod", Size = Vector3.new(1.4, 28, 1.4), Position = p + Vector3.new(0, 14, 0), Color = Color3.fromRGB(70, 70, 80), Material = Enum.Material.Metal, Parent = f })
		local tip = part({ Name = "RodTip", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), Position = p + Vector3.new(0, 29, 0), Color = color, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		light(tip, color, 22, 2)
		emitter(tip, Color3.fromRGB(200, 230, 255), 6, 0.5, 8, 0.25)
	end
	for _ = 1, 20 do
		local p = r.center + Vector3.new(rng:NextNumber(-140, 140), 0, rng:NextNumber(-140, 140))
		if (p - Vector3.new(at.X, 0, at.Z)).Magnitude > 50 and not nearRoad(p, 16) then
			rock(p, rng:NextNumber(4, 10), f, Color3.fromRGB(70, 68, 72))
		end
	end
end

-- 취선 주막: 술독과 탁자, '酒' 깃발
function SITES.chwi(r: any, at: Vector3, color: Color3, f: Instance)
	house(Vector3.new(at.X, 0, at.Z + 36), 34, 18, 0, f)
	for _, x in ipairs({ -16, 16 }) do
		part({ Name = "Table", Size = Vector3.new(7, 0.6, 4), Position = Vector3.new(at.X + x, 3, at.Z + 4), Color = Color3.fromRGB(120, 80, 50), Material = Enum.Material.Wood, Parent = f })
		part({ Name = "TableLeg", Size = Vector3.new(5, 2.7, 2), Position = Vector3.new(at.X + x, 1.35, at.Z + 4), Color = Color3.fromRGB(90, 60, 40), Material = Enum.Material.Wood, Parent = f })
		for _, dz in ipairs({ -3.5, 3.5 }) do
			cyl("Stool", Vector3.new(at.X + x, 0.9, at.Z + 4 + dz), 1, 1.8, Color3.fromRGB(110, 75, 45), Enum.Material.Wood, f)
		end
	end
	for k = 1, 9 do
		local p = Vector3.new(at.X + 24 + (k % 3) * 3.4, 0, at.Z + 20 + math.floor((k - 1) / 3) * 3.4)
		cyl("WineJar", p + Vector3.new(0, 1.6, 0), 1.5, 3.2, Color3.fromRGB(110, 70, 45), Enum.Material.Slate, f)
	end
	local pole = part({ Name = "FlagPole", Size = Vector3.new(0.8, 20, 0.8), Position = Vector3.new(at.X - 26, 10, at.Z + 22), Color = WOOD, Material = Enum.Material.Wood, Parent = f })
	local _ = pole
	local flag = part({ Name = "WineFlag", Size = Vector3.new(6, 9, 0.2), Position = Vector3.new(at.X - 22.6, 14, at.Z + 22), Color = Color3.fromRGB(200, 50, 40), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
	sign(flag, Enum.NormalId.Front, { { "酒", Color3.fromRGB(255, 240, 220), 1 } })
	sign(flag, Enum.NormalId.Back, { { "酒", Color3.fromRGB(255, 240, 220), 1 } })
end

local function masterSites()
	for _, r in ipairs(Config.Regions) do
		local styleId = r.master
		local style = styleId and Config.STYLE_BY_ID[styleId]
		if style then
			local f = Instance.new("Folder")
			f.Name = "Master_" .. r.id
			f.Parent = folder
			local builder = SITES[style.id]
			if builder then
				local ok, err = pcall(builder, r, r.masterAt, style.color, f)
				if not ok then
					warn("[권왕] 사부 자리 만들기 오류:", r.id, err)
				end
			end
			-- 멀리서도 보이는 빛기둥 (사부 머리 위 하늘로)
			local at = r.masterAt
			local beam = part({ Name = "MasterBeacon", Size = Vector3.new(2.4, 260, 2.4), Position = at + Vector3.new(0, 24 + 130, 0), Color = style.color, Material = Enum.Material.Neon, Transparency = 0.45, CanCollide = false, CastShadow = false, Parent = f })
			local _ = beam
		end
	end
end

------------------------------------------------------------------------
-- 지역 이름 표지
------------------------------------------------------------------------
local function regionSigns()
	for _, r in ipairs(Config.Regions) do
		if r.id ~= "village" and not r.noGround then
			local dir = Vector3.new(r.center.X, 0, r.center.Z).Unit
			local pos = r.center - dir * (math.max(r.size.X, r.size.Z) / 2 - 12)
			-- 길 옆 (길과 직각으로 비켜서)
			local side = Vector3.new(-dir.Z, 0, dir.X) * 16
			local post = part({ Name = "RegionPost", Size = Vector3.new(1.4, 10, 1.4), Position = pos + side + Vector3.new(0, 5, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = folder })
			local board = part({ Name = "RegionSign", Size = Vector3.new(20, 5, 0.5), CFrame = CFrame.lookAt(pos + side + Vector3.new(0, 11, 0), pos + side + Vector3.new(0, 11, 0) - dir), Color = Color3.fromRGB(35, 25, 18), Material = Enum.Material.Wood, CanCollide = false, Parent = folder })
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
	local out: any = { train = {}, rings = {} }
	-- 한 조각이 틀려도 나머지는 다 만든다
	for _, step in ipairs({
		{ "땅", ground },
		{ "마을", function()
			village(out)
		end },
		{ "수련터", function()
			trainingSpots(out)
		end },
		{ "지역", regions },
		{ "사부의 자리", masterSites },
		{ "표지", regionSigns },
	}) do
		local ok, err = pcall(step[2] :: any)
		if not ok then
			warn("[권왕] 맵 만들기 오류 (" .. step[1] .. "):", err)
		end
	end
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
