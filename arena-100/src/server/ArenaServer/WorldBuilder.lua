-- WorldBuilder (ModuleScript, ArenaServer 아래)
-- 조명, 로비 광장, 투기장을 만든다. 맵은 전부 코드로 짓는다.

local Lighting = game:GetService("Lighting")
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

function World.buildLobby(onGate: (Player) -> ()): CFrame
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
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "투기장 입장"
	prompt.ObjectText = Config.GAME_TITLE
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 20
	prompt.RequiresLineOfSight = false
	prompt.Parent = portal
	prompt.Triggered:Connect(onGate)

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
