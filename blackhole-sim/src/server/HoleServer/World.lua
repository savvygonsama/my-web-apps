-- World (ModuleScript, HoleServer 아래)
-- 조명, 로비, 세계 2개(구역 15개)의 바닥과 벽, 구역 사이 문, 로비로 가는 문, 물체 배치.
-- 세계와 로비는 x 위치로 3만 칸씩 떨어져 있어서 서로 보이지 않는다.
-- 구역은 각 세계의 시작 지점(z = 0)에서 +z 쪽으로 차례로 이어진다.
-- 로블록스 파트는 한 변이 2048을 넘지 못하므로, 넓은 바닥과 벽은 2000짜리 조각으로 나눠 깐다
-- (예전에 넓은 구역 가장자리에서 떨어지던 구멍이 이것 때문이었다).
-- 구역 문은 모두에게 막혀 있고, 크기가 충분한 사람의 화면에서만 통과된다 (캐릭터 물리는 각자 화면이 맡는다).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Props = require(ReplicatedStorage:WaitForChild("Props"))

local World = {}

local LIMIT = Config.PART_LIMIT
local WALL = 40 -- 벽 두께

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
	-- 밟거나 부딪히지 않는 장식은 카메라도 무시하게 (카메라가 갑자기 확 다가오지 않게)
	if props.CanCollide == false and props.CanQuery == nil then
		p.CanQuery = false
	end
	p.Parent = props.Parent
	return p
end

-- 큰 직육면체를 2000짜리 조각으로 나눠 깐다 (Position + Size로 준 것만). 만든 조각을 모두 돌려준다
local function tiled(props: { [string]: any }): { Part }
	local size: Vector3 = props.Size
	local center: Vector3 = props.Position
	local nx = math.max(1, math.ceil(size.X / LIMIT))
	local ny = math.max(1, math.ceil(size.Y / LIMIT))
	local nz = math.max(1, math.ceil(size.Z / LIMIT))
	local piece = Vector3.new(size.X / nx, size.Y / ny, size.Z / nz)
	local list = {}
	for ix = 1, nx do
		for iy = 1, ny do
			for iz = 1, nz do
				local copy = table.clone(props)
				copy.Size = piece
				copy.Position = center + Vector3.new((ix - (nx + 1) / 2) * piece.X, (iy - (ny + 1) / 2) * piece.Y, (iz - (nz + 1) / 2) * piece.Z)
				table.insert(list, part(copy))
			end
		end
	end
	return list
end

local function signText(target: BasePart, face: Enum.NormalId, lines: { { any } })
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 8
	gui.LightInfluence = 0
	gui.Parent = target
	local y = 0
	for _, line in ipairs(lines) do
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0, y)
		l.Size = UDim2.fromScale(1, line[3])
		l.Font = Enum.Font.GothamBlack
		l.TextScaled = true
		l.TextColor3 = line[2]
		l.TextStrokeTransparency = 0.3
		l.Text = line[1]
		l.Parent = gui
		y += line[3]
	end
end

local function prompt(target: BasePart, action: string, object: string, name: string): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.Name = name
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 22
	pp.RequiresLineOfSight = false
	pp.KeyboardKeyCode = Enum.KeyCode.E
	pp.Parent = target
	return pp
end

function World.setupLighting()
	Lighting.ClockTime = 15.5
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(110, 110, 130)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 160)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 30
	bloom.Threshold = 1.2
	bloom.Parent = Lighting
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.15
	cc.Contrast = 0.08
	cc.Parent = Lighting
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmo.Density = 0.3
	atmo.Haze = 1.5
	atmo.Color = Color3.fromRGB(200, 210, 240)
	atmo.Decay = Color3.fromRGB(120, 110, 160)
	atmo.Parent = Lighting
end

-- 별가루 파티클 (우주 구역 하늘)
local function starDust(folder: Folder, center: Vector3, zone: any, color: Color3)
	local sky = part({ Name = "Stars", Size = Vector3.new(math.min(zone.width, LIMIT), 10, math.min(zone.length, LIMIT)), Position = center + Vector3.new(0, 300, 0), Transparency = 1, CanCollide = false, CanQuery = false, Parent = folder })
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 60
	pe.Lifetime = NumberRange.new(4, 8)
	pe.Speed = NumberRange.new(0, 1)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 3), NumberSequenceKeypoint.new(1, 0) })
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	pe.Parent = sky
end

-- 구역별 바닥 꾸밈 (모두 밟히지 않는 장식)
local function decorate(folder: Folder, zone: any, center: Vector3, z0: number, wx: number)
	local name = zone.name
	-- 넓은 구역은 카메라가 멀어서, 바닥 장식을 조금 더 띄워야 바닥과 겹쳐 깜빡이지 않는다
	local m = Config.decorScale(zone)
	if name == "도시" or name == "대도시" or name == "과자 마을" or name == "케이크 도시" then
		local candy = zone.world == 2
		local roadCol = candy and Color3.fromRGB(110, 60, 40) or Color3.fromRGB(45, 45, 50)
		local lineCol = candy and Color3.fromRGB(255, 240, 250) or Color3.fromRGB(240, 230, 120)
		tiled({ Name = "Road", Size = Vector3.new(zone.width * 0.18, 0.15, zone.length), Position = center + Vector3.new(0, 0.08 * m, 0), Color = roadCol, Material = candy and Enum.Material.SmoothPlastic or Enum.Material.Asphalt, CanCollide = false, Parent = folder })
		for k = 0, 9 do
			part({ Name = "Line", Size = Vector3.new(2, 0.16, zone.length / 20), Position = Vector3.new(wx, 0.1 * m, z0 + zone.length * (k + 0.5) / 10), Color = lineCol, Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
		end
	elseif name == "바다와 산" or name == "초콜릿 강" then
		local col = name == "초콜릿 강" and Color3.fromRGB(90, 45, 25) or Color3.fromRGB(50, 120, 200)
		for k = 0, 7 do
			local a = k * 1.3
			local d = math.min(LIMIT, zone.width * 0.16)
			part({
				Name = "Water",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.3, d, d),
				CFrame = CFrame.new(center + Vector3.new(math.cos(a) * zone.width * 0.3, 0.12 * m, math.sin(a) * zone.length * 0.3)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = col,
				Material = Enum.Material.Glass,
				Transparency = 0.15,
				CanCollide = false,
				Parent = folder,
			})
		end
	elseif name == "젤리 들판" then
		for k = 0, 9 do
			local a = k * 0.8
			part({
				Name = "JellyPool",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.3, 30 + k * 4, 30 + k * 4),
				CFrame = CFrame.new(center + Vector3.new(math.cos(a) * zone.width * 0.33, 0.12 * m, math.sin(a) * zone.length * 0.33)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromHSV(k / 10, 0.45, 1),
				Material = Enum.Material.Glass,
				Transparency = 0.2,
				CanCollide = false,
				Parent = folder,
			})
		end
	elseif name == "아이스크림 산맥" then
		for k = -4, 4 do
			tiled({ Name = "Syrup", Size = Vector3.new(zone.width / 20, 0.14, zone.length), Position = center + Vector3.new(k * zone.width / 9, 0.07 * m, 0), Color = Color3.fromHSV((k + 4) / 9, 0.35, 1), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = folder })
		end
	elseif zone.neon then
		-- 네온 사이버: 바닥에 빛나는 회로 격자
		local cols = { Color3.fromRGB(0, 230, 255), Color3.fromRGB(255, 40, 200), Color3.fromRGB(90, 255, 120) }
		for k = -5, 5 do
			tiled({ Name = "Circuit", Size = Vector3.new(2.5 * m, 0.12, zone.length), Position = center + Vector3.new(k * zone.width / 11, 0.06 * m, 0), Color = cols[(k + 6) % 3 + 1], Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, Parent = folder })
		end
		for k = 1, 9 do
			part({ Name = "CircuitX", Size = Vector3.new(math.min(zone.width, LIMIT), 0.12, 2.5 * m), Position = Vector3.new(wx, 0.07 * m, z0 + zone.length * k / 10), Color = cols[k % 3 + 1], Material = Enum.Material.Neon, Transparency = 0.45, CanCollide = false, Parent = folder })
		end
		if zone.need >= 140 then
			starDust(folder, center, zone, Color3.fromRGB(120, 240, 255))
		end
	elseif zone.void then
		-- 심연: 바닥의 갈라진 빛과 떠다니는 어둠 가루
		for k = 0, 11 do
			local a = k * 0.55
			local len = math.min(LIMIT, zone.length * 0.35)
			part({
				Name = "Rift",
				Size = Vector3.new(3 * m, 0.12, len),
				CFrame = CFrame.new(center + Vector3.new(math.cos(a * 1.7) * zone.width * 0.3, 0.06 * m, math.sin(a * 2.3) * zone.length * 0.3)) * CFrame.Angles(0, a, 0),
				Color = k % 2 == 0 and Color3.fromRGB(150, 60, 255) or Color3.fromRGB(40, 220, 200),
				Material = Enum.Material.Neon,
				Transparency = 0.3,
				CanCollide = false,
				Parent = folder,
			})
		end
		starDust(folder, center, zone, Color3.fromRGB(150, 90, 255))
	elseif name == "우주" or name == "사탕 우주" or name == "은하수" or name == "디저트 은하" or name == "설탕 블랙홀" then
		local col = zone.world == 2 and Color3.fromRGB(255, 120, 220) or Color3.fromRGB(110, 80, 255)
		if name == "은하수" or name == "설탕 블랙홀" then
			col = Color3.fromRGB(80, 200, 255)
		end
		for k = -6, 6 do
			tiled({ Name = "Grid", Size = Vector3.new(3, 0.12, zone.length), Position = center + Vector3.new(k * zone.width / 13, 0.06 * m, 0), Color = col, Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, Parent = folder })
		end
		starDust(folder, center, zone, zone.world == 2 and Color3.fromRGB(255, 200, 240) or Color3.fromRGB(200, 210, 255))
	end
end

-- 포털 (소용돌이 고리). to = 0이면 로비, 1·2면 세계
export type Portal = { pos: Vector3, to: number }

local function buildPortal(folder: Folder, ppos: Vector3, to: number, facing: number)
	local ringCol = to == 0 and Color3.fromRGB(120, 255, 200) or Config.Worlds[to].gate
	local rot = CFrame.Angles(0, facing, 0)
	part({ Name = "PortalBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 24, 24), CFrame = CFrame.new(ppos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = ringCol, Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, Parent = folder })
	for k = 0, 15 do
		local a = k * math.pi / 8
		part({
			Name = "PortalRing",
			Size = Vector3.new(2.2, 2.2, 3.2),
			CFrame = CFrame.new(ppos) * rot * CFrame.new(math.cos(a) * 10, 11 + math.sin(a) * 10, 0) * CFrame.Angles(0, 0, a),
			Color = k % 2 == 0 and ringCol or Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end
	local swirl = part({ Name = "PortalSwirl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 18, 18), CFrame = CFrame.new(ppos + Vector3.new(0, 11, 0)) * rot * CFrame.Angles(0, math.rad(90), 0), Color = ringCol, Material = Enum.Material.ForceField, Transparency = 0.1, CanCollide = false, Parent = folder })
	swirl:SetAttribute("Spin", true)
	local sign = part({ Name = "PortalSign", Size = Vector3.new(30, 9, 1), CFrame = CFrame.new(ppos + Vector3.new(0, 26, 0)) * rot, Color = Color3.fromRGB(25, 15, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
	local title, lock
	if to == 0 then
		title, lock = "🏠 로비", "캡슐 뽑기 · 상점 · 매일 보상"
	else
		local target = Config.Worlds[to]
		title = string.format("🌀 세계 %d · %s", to, target.name)
		if to == 1 then
			lock = "한 판의 시작"
		elseif Config.worldNeedSing(to) > 0 then
			lock = string.format("🌀 특이점 %d번 · 세계 %d에서 크기 %d", Config.worldNeedSing(to), to - 1, Config.WORLD2_RADIUS)
		else
			lock = string.format("세계 %d에서 크기 %d 넘기면", to - 1, Config.WORLD2_RADIUS)
		end
	end
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		signText(sign, face, {
			{ title, Color3.fromRGB(255, 230, 255), 0.55 },
			{ lock, Color3.fromRGB(255, 220, 120), 0.45 },
		})
	end
end

World.PORTAL_OFFSET = Vector3.new(-70, 0, 34)

-- 구역 바닥, 옆 벽, 구역 사이 문, 로비로 가는 문
function World.buildZones(): ({ BasePart }, { Portal })
	local folder = Instance.new("Folder")
	folder.Name = "Zones"
	folder.Parent = workspace
	local old = workspace:FindFirstChild("Baseplate")
	if old then
		old:Destroy()
	end
	local gates: { BasePart } = {}
	local portals: { Portal } = {}
	for i, zone in ipairs(Config.Zones) do
		local wx = Config.Worlds[zone.world].x
		local z0 = Config.zoneStart(i)
		local center = Vector3.new(wx, 0, z0 + zone.length / 2)
		tiled({
			Name = "Ground" .. i,
			Size = Vector3.new(zone.width, 4, zone.length),
			Position = center - Vector3.new(0, 2, 0),
			Color = zone.ground,
			Material = zone.material,
			Parent = folder,
		})
		for _, x in ipairs({ -1, 1 }) do
			tiled({
				Name = "Edge",
				Size = Vector3.new(8, 0.2, zone.length),
				Position = center + Vector3.new(x * (zone.width / 2 - 4), 0.1 * Config.decorScale(zone), 0),
				Color = zone.ground:Lerp(Color3.new(1, 1, 1), 0.35),
				Material = Enum.Material.Concrete,
				CanCollide = false,
				Parent = folder,
			})
			-- 보이지 않는 옆 벽 (아주 빨라도 뚫고 나가지 않게 두껍게)
			tiled({
				Name = "SideWall",
				Size = Vector3.new(WALL, 1200, zone.length),
				Position = center + Vector3.new(x * (zone.width / 2 + WALL / 2), 600, 0),
				Transparency = 1,
				Parent = folder,
			})
		end
		decorate(folder, zone, center, z0, wx)

		-- 다음 구역으로 가는 문 (그 세계 마지막 구역은 끝 벽)
		local nextZone = Config.Zones[i + 1]
		local zEnd = z0 + zone.length
		if nextZone and nextZone.world == zone.world then
			local narrow = math.min(zone.width, nextZone.width)
			local wide = math.max(zone.width, nextZone.width)
			-- 넓은 쪽 구역의 남는 가장자리는 늘 막혀 있다 (여기로 나가면 바닥 없는 곳으로 떨어졌다)
			for _, x in ipairs({ -1, 1 }) do
				local w = (wide - narrow) / 2 + WALL
				tiled({ Name = "CapWall", Size = Vector3.new(w, 1200, WALL), Position = Vector3.new(wx + x * (narrow / 2 + w / 2), 600, zEnd), Transparency = 1, Parent = folder })
			end
			local height = math.min(1800, 60 + nextZone.need * 2.5)
			for _, g in ipairs(tiled({
				Name = "Gate",
				Size = Vector3.new(narrow, height, 12),
				Position = Vector3.new(wx, height / 2, zEnd),
				Color = Config.Worlds[zone.world].gate,
				Material = Enum.Material.ForceField,
				Transparency = 0.2,
				Parent = folder,
			})) do
				g:SetAttribute("Need", nextZone.need)
				g:SetAttribute("Zone", i + 1)
				table.insert(gates, g)
			end
			local signW = math.clamp(nextZone.need * 0.8, 60, 400)
			local board = part({
				Name = "GateSign",
				Size = Vector3.new(signW, signW * 0.36, 1),
				Position = Vector3.new(wx, 8 + signW * 0.25, zEnd - 3),
				Color = Color3.fromRGB(30, 20, 50),
				Material = Enum.Material.Slate,
				CanCollide = false,
				Parent = folder,
			})
			local num = table.find(Config.zonesOf(zone.world), i + 1) or 0
			signText(board, Enum.NormalId.Back, {
				{ string.format("%d구역 · %s", num, nextZone.name), Color3.fromRGB(230, 210, 255), 0.45 },
				{ string.format("크기 %d 이상이면 통과", nextZone.need), Color3.fromRGB(255, 220, 120), 0.45 },
			})
		else
			tiled({ Name = "EndWall", Size = Vector3.new(zone.width + WALL * 2, 1200, WALL), Position = Vector3.new(wx, 600, zEnd + WALL / 2), Transparency = 1, Parent = folder })
		end
	end

	for wi, world in ipairs(Config.Worlds) do
		local wx = world.x
		local first = Config.zonesOf(wi)[1]
		tiled({ Name = "StartWall", Size = Vector3.new(Config.Zones[first].width + WALL * 2, 1200, WALL), Position = Vector3.new(wx, 600, -WALL / 2), Transparency = 1, Parent = folder })
		part({ Name = "WorldSpawn" .. wi, Size = Vector3.new(16, 1, 16), Position = Vector3.new(wx, 0.5, 22), Color = world.gate, Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false, Parent = folder })
		local title = part({ Name = "TitleSign", Size = Vector3.new(50, 14, 1), Position = Vector3.new(wx, 14, 6), Color = Color3.fromRGB(20, 12, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
		signText(title, Enum.NormalId.Back, {
			{ string.format("%s 세계 %d · %s", world.icon, wi, world.name), world.sky:Lerp(Color3.new(1, 1, 1), 0.3), 0.6 },
			{ world.tagline, Color3.fromRGB(255, 255, 255), 0.4 },
		})
		local ppos = Vector3.new(wx, 0, 0) + World.PORTAL_OFFSET
		buildPortal(folder, ppos, 0, 0)
		table.insert(portals, { pos = ppos, to = 0 })
	end
	return gates, portals
end

------------------------------------------------------------------------
-- 로비: 둥근 광장. 가운데 큰 블랙홀 조각, 북쪽에 캡슐 기계 셋, 남쪽에 스킨 전시관,
-- 서쪽·동쪽에 세계 1·2로 가는 문, 상점 가판대, 매일 보상 상자, 순위판
------------------------------------------------------------------------
export type Lobby = {
	spawn: Vector3,
	portals: { Portal },
	machines: { [string]: ProximityPrompt },
	store: ProximityPrompt,
	skins: ProximityPrompt,
	daily: ProximityPrompt,
	trial: ProximityPrompt,
	sing: ProximityPrompt,
	board: { TextLabel },
}

function World.buildLobby(): Lobby
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	folder.Parent = workspace
	local L = Vector3.new(Config.LOBBY.x, 0, Config.LOBBY.z)
	local R = Config.LOBBY.radius
	local function at(x: number, y: number, z: number): Vector3
		return L + Vector3.new(x, y, z)
	end
	-- 바닥과 무늬
	part({ Name = "LobbyFloor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, R * 2 + 20, R * 2 + 20), CFrame = CFrame.new(at(0, -3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(36, 28, 60), Material = Enum.Material.Marble, Parent = folder })
	for k, rr in ipairs({ 60, 120, R }) do
		part({ Name = "FloorRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, rr * 2 + 4, rr * 2 + 4), CFrame = CFrame.new(at(0, 0.05 + k * 0.01, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromHSV(0.75 + k * 0.05, 0.6, 1), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false, Parent = folder })
		part({ Name = "FloorInner", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.32, rr * 2 - 2, rr * 2 - 2), CFrame = CFrame.new(at(0, 0.06 + k * 0.01, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(36, 28, 60), Material = Enum.Material.Marble, CanCollide = false, Parent = folder })
	end
	-- 둘레 벽 (보이지 않음) + 빛나는 기둥
	for k = 0, 35 do
		local a = k / 36 * math.pi * 2
		local pos = at(math.cos(a) * (R + 26), 100, math.sin(a) * (R + 26))
		-- X = 둘레 방향 폭 70, Z = 가운데를 향한 두께 40 (조각끼리 겹쳐서 틈이 없다)
		part({ Name = "LobbyWall", Size = Vector3.new(70, 200, 40), CFrame = CFrame.fromMatrix(pos, Vector3.new(-math.sin(a), 0, math.cos(a)), Vector3.new(0, 1, 0)), Transparency = 1, Parent = folder })
		if k % 3 == 0 then
			part({ Name = "Pillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(26, 3, 3), CFrame = CFrame.new(at(math.cos(a) * (R + 4), 13, math.sin(a) * (R + 4))) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromHSV(k / 36, 0.5, 1), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
		end
	end
	-- 가운데 블랙홀 조각 받침 (모양은 화면이 그린다)
	local core = part({ Name = "SkinPedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 36, 36), CFrame = CFrame.new(at(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(60, 45, 100), Material = Enum.Material.Marble, CanCollide = false, Parent = folder })
	core:SetAttribute("SkinIndex", 6)
	core:SetAttribute("HoleR", 14)
	local title = part({ Name = "LobbyTitle", Size = Vector3.new(70, 16, 1), Position = at(0, 40, 0), Color = Color3.fromRGB(20, 12, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		signText(title, face, {
			{ "🕳 " .. Config.GAME_TITLE .. " 로비", Color3.fromRGB(210, 170, 255), 0.6 },
			{ "← 세계 1   ·   캡슐은 북쪽   ·   세계 2 →", Color3.fromRGB(255, 255, 255), 0.4 },
		})
	end

	-- 캡슐 기계 셋 (북쪽)
	local machines = {}
	for k, cap in ipairs(Config.Capsules) do
		local x = (k - 2) * 70
		local z = 150 - math.abs(k - 2) * 20
		local base = part({ Name = "CapsuleMachine", Size = Vector3.new(16, 8, 16), Position = at(x, 4, z), Color = Color3.fromRGB(60, 50, 90), Material = Enum.Material.Metal, CanCollide = false, Parent = folder })
		part({ Name = "MachineGlass", Shape = Enum.PartType.Ball, Size = Vector3.new(16, 16, 16), Position = at(x, 15, z), Color = cap.color, Material = Enum.Material.Glass, Transparency = 0.5, CanCollide = false, Parent = folder })
		for j = 0, 5 do
			local a = j * 1.05
			part({ Name = "Capsule", Shape = Enum.PartType.Ball, Size = Vector3.new(3.2, 3.2, 3.2), Position = at(x + math.cos(a) * 3.5, 11 + (j % 2) * 3, z + math.sin(a) * 3.5), Color = Color3.fromHSV((j / 6 + k * 0.3) % 1, 0.6, 1), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = folder })
		end
		part({ Name = "MachineTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 10, 10), CFrame = CFrame.new(at(x, 23.5, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = cap.color, Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
		local sign = part({ Name = "MachineSign", Size = Vector3.new(24, 7, 1), CFrame = CFrame.lookAt(at(x, 31, z), at(0, 31, 0)), Color = Color3.fromRGB(20, 12, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
		signText(sign, Enum.NormalId.Front, {
			{ "🥚 " .. cap.name, Color3.fromRGB(255, 255, 255), 0.55 },
			{ "💠 " .. Config.formatNumber(cap.cost) .. (cap.world == 2 and " · 세계 2" or ""), Color3.fromRGB(255, 220, 120), 0.45 },
		})
		machines[cap.id] = prompt(base, "캡슐 깨기", cap.name, "Capsule")
	end

	-- 스킨 전시관 (남쪽 둥근 줄)
	for k = 1, #Config.Skins do
		local a = math.rad(215 + (k - 1) * 10)
		local pos = at(math.cos(a) * 200, 1.5, math.sin(a) * 200)
		local ped = part({ Name = "SkinPedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 13, 13), CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(70, 55, 110), Material = Enum.Material.Marble, CanCollide = false, Parent = folder })
		ped:SetAttribute("SkinIndex", k)
		ped:SetAttribute("HoleR", 4)
		part({ Name = "PedestalRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 13.6, 13.6), CFrame = CFrame.new(pos + Vector3.new(0, 1.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Config.Skins[k].a, Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	end
	local skinSign = part({ Name = "SkinHallSign", Size = Vector3.new(40, 10, 1), CFrame = CFrame.lookAt(at(0, 22, -175), at(0, 22, 0)), Color = Color3.fromRGB(25, 15, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
	signText(skinSign, Enum.NormalId.Front, {
		{ "🎨 스킨 전시관", Color3.fromRGB(255, 200, 255), 0.6 },
		{ "스킨마다 고유 능력이 있어요", Color3.fromRGB(255, 255, 255), 0.4 },
	})
	local skinStand = part({ Name = "SkinStand", Size = Vector3.new(8, 4, 8), Position = at(0, 2, -175), Color = Color3.fromRGB(200, 90, 200), Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false, Parent = folder })

	-- 상점 가판대 (남서), 매일 보상 상자 (남동)
	local kiosk = part({ Name = "StoreKiosk", Size = Vector3.new(14, 10, 8), Position = at(-110, 5, -60), Color = Color3.fromRGB(230, 160, 40), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = folder })
	part({ Name = "KioskRoof", Size = Vector3.new(18, 1, 12), Position = at(-110, 14, -60), Color = Color3.fromRGB(255, 220, 120), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	local kioskSign = part({ Name = "KioskSign", Size = Vector3.new(18, 5, 1), CFrame = CFrame.lookAt(at(-110, 19, -60), at(0, 19, 0)), Color = Color3.fromRGB(20, 12, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
	signText(kioskSign, Enum.NormalId.Front, { { "💎 상점", Color3.fromRGB(255, 220, 120), 1 } })
	local chest = part({ Name = "DailyChest", Size = Vector3.new(10, 7, 7), Position = at(110, 3.5, -60), Color = Color3.fromRGB(150, 90, 40), Material = Enum.Material.WoodPlanks, CanCollide = false, Parent = folder })
	part({ Name = "ChestLid", Size = Vector3.new(10.4, 2, 7.4), Position = at(110, 8, -60), Color = Color3.fromRGB(255, 200, 60), Material = Enum.Material.Foil, CanCollide = false, Parent = folder })
	part({ Name = "ChestGlow", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), Position = at(110, 11, -60), Color = Color3.fromRGB(255, 230, 120), Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false, Parent = folder })
	local chestSign = part({ Name = "ChestSign", Size = Vector3.new(18, 5, 1), CFrame = CFrame.lookAt(at(110, 17, -60), at(0, 17, 0)), Color = Color3.fromRGB(20, 12, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
	signText(chestSign, Enum.NormalId.Front, { { "🎁 매일 보상", Color3.fromRGB(255, 220, 120), 1 } })

	-- 순위판 (북쪽 끝)
	local boardPart = part({ Name = "Leaderboard", Size = Vector3.new(60, 44, 2), CFrame = CFrame.lookAt(at(0, 40, 215), at(0, 40, 0)), Color = Color3.fromRGB(15, 10, 30), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 10
	gui.LightInfluence = 0
	gui.Parent = boardPart
	local head = Instance.new("TextLabel")
	head.BackgroundTransparency = 1
	head.Size = UDim2.fromScale(1, 0.14)
	head.Font = Enum.Font.GothamBlack
	head.TextScaled = true
	head.TextColor3 = Color3.fromRGB(255, 220, 120)
	head.Text = "🏆 이 서버 순위 (모은 질량)"
	head.Parent = gui
	local rows = {}
	for k = 1, 10 do
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0.04, 0.14 + (k - 1) * 0.085)
		l.Size = UDim2.fromScale(0.92, 0.08)
		l.Font = Enum.Font.GothamBold
		l.TextScaled = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = k <= 3 and Color3.fromRGB(255, 230, 150) or Color3.fromRGB(230, 225, 255)
		l.Text = ""
		l.Parent = gui
		rows[k] = l
	end

	-- 세계로 가는 문 (서쪽 1, 동쪽 2, 북서 3, 북동 4)
	local portals = {}
	for _, info in ipairs({ { -195, 0, 1, 90 }, { 195, 0, 2, 90 }, { -165, 95, 3, 60 }, { 165, 95, 4, 120 } }) do
		local ppos = at(info[1], 0, info[2])
		buildPortal(folder, ppos, info[3], math.rad(info[4]))
		table.insert(portals, { pos = ppos, to = info[3] })
	end

	-- ⚔ 시련의 문 (남서)과 🌀 특이점 제단 (남동)
	local trialStand = part({ Name = "TrialGate", Size = Vector3.new(14, 6, 14), Position = at(-70, 3, -110), Color = Color3.fromRGB(150, 30, 40), Material = Enum.Material.Basalt, CanCollide = false, Parent = folder })
	for k = 0, 1 do
		part({ Name = "TrialPillar", Size = Vector3.new(3, 26, 3), Position = at(-78 + k * 16, 13, -110), Color = Color3.fromRGB(80, 20, 30), Material = Enum.Material.Basalt, CanCollide = false, Parent = folder })
	end
	part({ Name = "TrialFlame", Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), Position = at(-70, 26, -110), Color = Color3.fromRGB(255, 70, 50), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	local trialSign = part({ Name = "TrialSign", Size = Vector3.new(22, 6, 1), CFrame = CFrame.lookAt(at(-70, 33, -110), at(0, 33, 0)), Color = Color3.fromRGB(20, 12, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
	signText(trialSign, Enum.NormalId.Front, { { "⚔ 시련의 문", Color3.fromRGB(255, 140, 120), 0.6 }, { "포식자를 삼켜라", Color3.fromRGB(255, 255, 255), 0.4 } })
	local altar = part({ Name = "SingAltar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 16, 16), CFrame = CFrame.new(at(70, 2, -110)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(30, 20, 60), Material = Enum.Material.Marble, CanCollide = false, Parent = folder })
	local orb = part({ Name = "SingOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(8, 8, 8), Position = at(70, 14, -110), Color = Color3.fromRGB(10, 5, 20), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = folder })
	part({ Name = "SingRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 14, 14), CFrame = CFrame.new(orb.Position) * CFrame.Angles(0, 0, math.rad(80)), Color = Color3.fromRGB(235, 235, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	local singSign = part({ Name = "SingSign", Size = Vector3.new(22, 6, 1), CFrame = CFrame.lookAt(at(70, 26, -110), at(0, 26, 0)), Color = Color3.fromRGB(20, 12, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
	signText(singSign, Enum.NormalId.Front, { { "🌀 특이점 제단", Color3.fromRGB(235, 235, 255), 0.6 }, { "빅뱅을 바쳐 더 큰 힘을", Color3.fromRGB(255, 255, 255), 0.4 } })

	return {
		spawn = at(0, 5, -130),
		portals = portals,
		machines = machines,
		store = prompt(kiosk, "상점 열기", "💎 상점", "Store"),
		skins = prompt(skinStand, "스킨 보기", "🎨 스킨", "Skins"),
		daily = prompt(chest, "보상 받기", "🎁 매일 보상", "Daily"),
		trial = prompt(trialStand, "시련 보기", "⚔ 시련", "Trial"),
		sing = prompt(altar, "특이점 보기", "🌀 특이점", "Sing"),
		board = rows,
	}
end

------------------------------------------------------------------------
-- ⚔ 시련장: 사방이 막힌 네모난 경기장 여러 개 (한 사람씩)
------------------------------------------------------------------------
function World.buildTrialArenas(count: number)
	local folder = Instance.new("Folder")
	folder.Name = "TrialArenas"
	folder.Parent = workspace
	local A = Config.TRIAL_ARENA
	for slot = 1, count do
		local c = Vector3.new(A.x + (slot - 1) * A.gap, 0, A.z)
		tiled({ Name = "TrialFloor", Size = Vector3.new(A.size, 4, A.size), Position = c - Vector3.new(0, 2, 0), Color = Color3.fromRGB(40, 22, 30), Material = Enum.Material.Basalt, Parent = folder })
		for k = -4, 4 do
			part({ Name = "TrialLine", Size = Vector3.new(2, 0.12, A.size), Position = c + Vector3.new(k * A.size / 9, 0.08, 0), Color = Color3.fromRGB(255, 70, 60), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false, Parent = folder })
		end
		for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local size = d[1] ~= 0 and Vector3.new(WALL, 400, A.size + WALL * 2) or Vector3.new(A.size + WALL * 2, 400, WALL)
			part({ Name = "TrialWall", Size = size, Position = c + Vector3.new(d[1] * (A.size / 2 + WALL / 2), 200, d[2] * (A.size / 2 + WALL / 2)), Transparency = 1, Parent = folder })
			local glow = d[1] ~= 0 and Vector3.new(1, 8, A.size) or Vector3.new(A.size, 8, 1)
			part({ Name = "TrialEdge", Size = glow, Position = c + Vector3.new(d[1] * A.size / 2, 4, d[2] * A.size / 2), Color = Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, Parent = folder })
		end
	end
end

export type ObjectRec = {
	model: Model,
	def: any,
	zone: number,
	pos: Vector3,
	alive: boolean,
	golden: boolean,
	collide: { [BasePart]: boolean },
}

-- 물체 배치. 같은 서버에서는 늘 같은 자리
function World.placeObjects(): ({ ObjectRec }, Folder)
	local folder = Instance.new("Folder")
	folder.Name = "Objects"
	folder.Parent = workspace
	local rng = Random.new(20261015)
	local list: { ObjectRec } = {}
	for zi, zone in ipairs(Config.Zones) do
		local z0 = Config.zoneStart(zi)
		local wx = Config.Worlds[zone.world].x
		local first = Config.zonesOf(zone.world)[1] == zi
		local placed: { { pos: Vector3, r: number } } = {}
		-- 큰 것부터 자리를 잡아야 빈자리가 남는다
		local defs = {}
		for _, def in ipairs(Config.Objects) do
			if def.zone == zi then
				table.insert(defs, def)
			end
		end
		table.sort(defs, function(a, b)
			return a.size > b.size
		end)
		for _, def in ipairs(defs) do
			local count = math.max(1, math.floor(def.count * (zone.countMult or 1) + 0.5))
			for n = 1, count do
				local margin = math.min(def.size * 1.3 + 6, zone.width * 0.3)
				local pos: Vector3? = nil
				for _ = 1, 40 do
					local x = rng:NextNumber(-zone.width / 2 + margin, zone.width / 2 - margin)
					local z = rng:NextNumber(z0 + margin, z0 + zone.length - margin)
					local p = Vector3.new(wx + x, 0, z)
					local ok = true
					-- 시작 지점과 로비 문 근처는 비워 둔다
					if first then
						if (p - Vector3.new(wx, 0, 22)).Magnitude < 22 + def.size then
							ok = false
						elseif (p - (Vector3.new(wx, 0, 0) + World.PORTAL_OFFSET)).Magnitude < 18 + def.size then
							ok = false
						end
					end
					if ok then
						for _, other in ipairs(placed) do
							if (other.pos - p).Magnitude < (other.r + def.size) * 1.05 then
								ok = false
								break
							end
						end
					end
					if ok then
						pos = p
						break
					end
				end
				if pos then
					local base = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
					local model = Props.build(def.model or def.id, def.size, base, zi * 100000 + n * 131 + #list)
					model.Name = def.id
					-- 세계 3·4 물체: 같은 모양을 그 세계 빛깔로 물들인다
					if def.tint then
						for _, d in ipairs(model:GetDescendants()) do
							if d:IsA("BasePart") then
								d.Color = d.Color:Lerp(def.tint, 0.6)
								if def.glow and d.Size.Magnitude < def.size * 0.7 then
									d.Material = Enum.Material.Neon
								end
							end
						end
					end
					model:SetAttribute("Size", def.size)
					model:SetAttribute("Mass", def.mass)
					model:SetAttribute("Label", def.name)
					-- 물체는 모두 부딪히지 않는다. 블랙홀은 땅에 난 구멍이라 물체 밑을 지나간다
					-- (예전엔 큰 물체에 걸리거나, 다시 생긴 물체가 내 자리에 나타나 몸이 끼었다)
					local collide = {}
					for _, d in ipairs(model:GetDescendants()) do
						if d:IsA("BasePart") then
							d.CanCollide = false
							d.CanTouch = false
							d.CanQuery = false
							collide[d] = false
						end
					end
					model.Parent = folder
					table.insert(placed, { pos = pos, r = def.size })
					table.insert(list, { model = model, def = def, zone = zi, pos = pos, alive = true, golden = false, collide = collide })
				end
			end
		end
	end
	return list, folder
end

return World
