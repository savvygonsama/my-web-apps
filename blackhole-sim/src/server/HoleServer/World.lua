-- World (ModuleScript, HoleServer 아래)
-- 조명, 세계 2개(구역 11개)의 바닥과 벽, 구역 사이 문, 세계를 오가는 문, 물체 배치.
-- 세계는 x 위치로 떨어져 있고, 구역은 각 세계의 시작 지점(z = 0)에서 +z 쪽으로 차례로 이어진다.
-- 문은 모두에게 막혀 있고, 크기가 충분한 사람의 화면에서만 통과된다 (캐릭터 물리는 각자 화면이 맡는다).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Props = require(ReplicatedStorage:WaitForChild("Props"))

local World = {}

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
	p.Parent = props.Parent
	return p
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
	atmo.Density = 0.25
	atmo.Haze = 1
	atmo.Color = Color3.fromRGB(200, 210, 240)
	atmo.Decay = Color3.fromRGB(120, 110, 160)
	atmo.Parent = Lighting
end

-- 별가루 파티클 (우주 구역 하늘)
local function starDust(folder: Folder, center: Vector3, zone: any, color: Color3)
	local sky = part({ Name = "Stars", Size = Vector3.new(zone.width, 10, zone.length), Position = center + Vector3.new(0, 260, 0), Transparency = 1, CanCollide = false, CanQuery = false, Parent = folder })
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 120
	pe.Lifetime = NumberRange.new(4, 8)
	pe.Speed = NumberRange.new(0, 1)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 2), NumberSequenceKeypoint.new(1, 0) })
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	pe.Parent = sky
end

-- 구역별 바닥 꾸밈
local function decorate(folder: Folder, zone: any, center: Vector3, z0: number, wx: number)
	local name = zone.name
	if name == "도시" or name == "대도시" or name == "과자 마을" or name == "케이크 도시" then
		-- 가운데 길과 줄무늬 (과자 세계는 초콜릿 길, 크림 선)
		local candy = zone.world == 2
		local roadCol = candy and Color3.fromRGB(110, 60, 40) or Color3.fromRGB(45, 45, 50)
		local lineCol = candy and Color3.fromRGB(255, 240, 250) or Color3.fromRGB(240, 230, 120)
		part({ Name = "Road", Size = Vector3.new(zone.width * 0.18, 0.15, zone.length), Position = center + Vector3.new(0, 0.08, 0), Color = roadCol, Material = candy and Enum.Material.SmoothPlastic or Enum.Material.Asphalt, CanCollide = false, Parent = folder })
		for k = 0, 9 do
			part({ Name = "Line", Size = Vector3.new(1.2, 0.16, zone.length / 20), Position = Vector3.new(wx, 0.1, z0 + zone.length * (k + 0.5) / 10), Color = lineCol, Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
		end
	elseif name == "바다와 산" then
		for k = 0, 5 do
			local a = k * 1.3
			part({
				Name = "Water",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.3, zone.width * 0.18, zone.width * 0.18),
				CFrame = CFrame.new(center + Vector3.new(math.cos(a) * zone.width * 0.3, 0.12, math.sin(a) * zone.length * 0.3)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(50, 120, 200),
				Material = Enum.Material.Glass,
				Transparency = 0.15,
				CanCollide = false,
				Parent = folder,
			})
		end
	elseif name == "젤리 들판" then
		-- 알록달록 젤리 웅덩이
		for k = 0, 7 do
			local a = k * 0.8
			part({
				Name = "JellyPool",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.3, 26 + k * 3, 26 + k * 3),
				CFrame = CFrame.new(center + Vector3.new(math.cos(a) * zone.width * 0.33, 0.12, math.sin(a) * zone.length * 0.33)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromHSV(k / 8, 0.45, 1),
				Material = Enum.Material.Glass,
				Transparency = 0.2,
				CanCollide = false,
				Parent = folder,
			})
		end
	elseif name == "아이스크림 산맥" then
		-- 시럽 줄무늬
		for k = -4, 4 do
			part({ Name = "Syrup", Size = Vector3.new(zone.width / 20, 0.14, zone.length), Position = center + Vector3.new(k * zone.width / 9, 0.07, 0), Color = Color3.fromHSV((k + 4) / 9, 0.35, 1), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = folder })
		end
	elseif name == "우주" or name == "사탕 우주" then
		local col = zone.world == 2 and Color3.fromRGB(255, 120, 220) or Color3.fromRGB(110, 80, 255)
		for k = -6, 6 do
			part({ Name = "Grid", Size = Vector3.new(1.5, 0.12, zone.length), Position = center + Vector3.new(k * zone.width / 13, 0.06, 0), Color = col, Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, Parent = folder })
		end
		starDust(folder, center, zone, zone.world == 2 and Color3.fromRGB(255, 200, 240) or Color3.fromRGB(200, 210, 255))
	end
end

-- 세계를 오가는 문: 세계마다 하나씩, 시작 지점 왼쪽에 있다
World.PORTAL_OFFSET = Vector3.new(-70, 0, 34)
export type Portal = { pos: Vector3, to: number }

-- 구역 바닥, 옆 벽, 구역 사이 문, 세계 문
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
		part({
			Name = "Ground" .. i,
			Size = Vector3.new(zone.width, 4, zone.length),
			Position = center - Vector3.new(0, 2, 0),
			Color = zone.ground,
			Material = zone.material,
			Parent = folder,
		})
		for _, x in ipairs({ -1, 1 }) do
			part({
				Name = "Edge",
				Size = Vector3.new(6, 0.2, zone.length),
				Position = center + Vector3.new(x * (zone.width / 2 - 3), 0.1, 0),
				Color = zone.ground:Lerp(Color3.new(1, 1, 1), 0.35),
				Material = Enum.Material.Concrete,
				CanCollide = false,
				Parent = folder,
			})
			part({
				Name = "SideWall",
				Size = Vector3.new(4, 600, zone.length),
				Position = center + Vector3.new(x * (zone.width / 2 + 2), 300, 0),
				Transparency = 1,
				Parent = folder,
			})
		end
		decorate(folder, zone, center, z0, wx)

		-- 다음 구역으로 가는 문 (그 세계 마지막 구역은 끝 벽)
		local nextZone = Config.Zones[i + 1]
		local zEnd = z0 + zone.length
		if nextZone and nextZone.world == zone.world then
			local width = math.max(zone.width, nextZone.width)
			local height = 60 + nextZone.need * 2.5
			local gate = part({
				Name = "Gate",
				Size = Vector3.new(width, height, 3),
				Position = Vector3.new(wx, height / 2, zEnd),
				Color = zone.world == 2 and Color3.fromRGB(255, 110, 200) or Color3.fromRGB(150, 90, 255),
				Material = Enum.Material.ForceField,
				Transparency = 0.2,
				Parent = folder,
			})
			gate:SetAttribute("Need", nextZone.need)
			gate:SetAttribute("Zone", i + 1)
			table.insert(gates, gate)
			local board = part({
				Name = "GateSign",
				Size = Vector3.new(60, 22, 1),
				Position = Vector3.new(wx, 26, zEnd - 3),
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
			part({ Name = "EndWall", Size = Vector3.new(zone.width, 600, 4), Position = Vector3.new(wx, 300, zEnd + 2), Transparency = 1, Parent = folder })
		end
	end

	for wi, world in ipairs(Config.Worlds) do
		local wx = world.x
		local first = Config.zonesOf(wi)[1]
		part({ Name = "StartWall", Size = Vector3.new(Config.Zones[first].width, 600, 4), Position = Vector3.new(wx, 300, -2), Transparency = 1, Parent = folder })

		-- 시작 지점 (세계 1만 진짜 SpawnLocation, 세계 2는 표시만)
		local pad: BasePart
		if wi == 1 then
			local spawn = Instance.new("SpawnLocation")
			spawn.Name = "HoleSpawn"
			spawn.Neutral = true
			spawn.Duration = 0
			pad = spawn
		else
			pad = Instance.new("Part")
			pad.Name = "WorldSpawn" .. wi
		end
		pad.Anchored = true
		pad.Size = Vector3.new(16, 1, 16)
		pad.Position = Vector3.new(wx, 0.5, 22)
		pad.Color = wi == 2 and Color3.fromRGB(255, 120, 200) or Color3.fromRGB(120, 70, 220)
		pad.Material = Enum.Material.Neon
		pad.Transparency = 0.3
		pad.CanCollide = false
		pad.Parent = folder
		local decal = pad:FindFirstChildOfClass("Decal")
		if decal then
			decal:Destroy()
		end
		local title = part({ Name = "TitleSign", Size = Vector3.new(50, 14, 1), Position = Vector3.new(wx, 14, 6), Color = Color3.fromRGB(20, 12, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
		signText(title, Enum.NormalId.Back, {
			{ wi == 1 and ("🕳 " .. Config.GAME_TITLE) or ("🍭 세계 2 · " .. world.name), wi == 1 and Color3.fromRGB(210, 170, 255) or Color3.fromRGB(255, 170, 220), 0.6 },
			{ wi == 1 and "작은 것부터 삼키고 커져라!" or "모든 게 달콤하고, 질량은 5배!", Color3.fromRGB(255, 255, 255), 0.4 },
		})

		-- 스킨 전시관: 시작 지점 뒤편 단 위에 스킨 12종이 돌고 있다 (블랙홀 모양은 화면이 그린다)
		local hall = part({ Name = "SkinHall", Size = Vector3.new(220, 4, 34), Position = Vector3.new(wx, -1.2, -24), Color = Color3.fromRGB(40, 30, 70), Material = Enum.Material.Marble, CanCollide = false, Parent = folder })
		hall:SetAttribute("World", wi)
		for k = 1, #Config.Skins do
			local x = wx + (k - (#Config.Skins + 1) / 2) * 17
			part({ Name = "SkinPedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 11, 11), CFrame = CFrame.new(x, 1.5, -24) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(70, 55, 110), Material = Enum.Material.Marble, CanCollide = false, Parent = folder })
			part({ Name = "SkinPedestalRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 11.6, 11.6), CFrame = CFrame.new(x, 2.1, -24) * CFrame.Angles(0, 0, math.rad(90)), Color = Config.Skins[k].a, Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
		end
		local hallSign = part({ Name = "SkinHallSign", Size = Vector3.new(60, 10, 1), Position = Vector3.new(wx, 34, -24), Color = Color3.fromRGB(25, 15, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
		signText(hallSign, Enum.NormalId.Back, {
			{ "🎨 스킨 전시관", Color3.fromRGB(255, 200, 255), 0.6 },
			{ "🎨 스킨 창에서 바꿀 수 있어요", Color3.fromRGB(255, 255, 255), 0.4 },
		})

		-- 다른 세계로 가는 문 (소용돌이 고리)
		local to = wi == 1 and 2 or 1
		local target = Config.Worlds[to]
		local ppos = Vector3.new(wx, 0, 0) + World.PORTAL_OFFSET
		local ringCol = to == 2 and Color3.fromRGB(255, 120, 210) or Color3.fromRGB(140, 110, 255)
		part({ Name = "PortalBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 22, 22), CFrame = CFrame.new(ppos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = ringCol, Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, Parent = folder })
		for k = 0, 15 do
			local a = k * math.pi / 8
			part({
				Name = "PortalRing",
				Size = Vector3.new(2.2, 2.2, 3.2),
				CFrame = CFrame.new(ppos + Vector3.new(math.cos(a) * 9, 10 + math.sin(a) * 9, 0)) * CFrame.Angles(0, 0, a),
				Color = k % 2 == 0 and ringCol or Color3.fromRGB(255, 255, 255),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = folder,
			})
		end
		local swirl = part({ Name = "PortalSwirl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 16, 16), CFrame = CFrame.new(ppos + Vector3.new(0, 10, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = ringCol, Material = Enum.Material.ForceField, Transparency = 0.1, CanCollide = false, Parent = folder })
		swirl:SetAttribute("Spin", true)
		local sign = part({ Name = "PortalSign", Size = Vector3.new(26, 8, 1), Position = ppos + Vector3.new(0, 23, 0), Color = Color3.fromRGB(25, 15, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
		local lock = target.needBigbang > 0 and string.format("빅뱅 %d번 하면 열림", target.needBigbang) or "언제든 갈 수 있음"
		signText(sign, Enum.NormalId.Back, {
			{ string.format("🌀 세계 %d · %s", to, target.name), Color3.fromRGB(255, 230, 255), 0.55 },
			{ lock, Color3.fromRGB(255, 220, 120), 0.45 },
		})
		signText(sign, Enum.NormalId.Front, {
			{ string.format("🌀 세계 %d · %s", to, target.name), Color3.fromRGB(255, 230, 255), 0.55 },
			{ lock, Color3.fromRGB(255, 220, 120), 0.45 },
		})
		table.insert(portals, { pos = ppos, to = to })
	end
	return gates, portals
end

export type ObjectRec = {
	model: Model,
	def: any,
	zone: number,
	pos: Vector3,
	alive: boolean,
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
			for n = 1, def.count do
				local margin = def.size * 1.3 + 6
				local pos: Vector3? = nil
				for _ = 1, 40 do
					local x = rng:NextNumber(-zone.width / 2 + margin, zone.width / 2 - margin)
					local z = rng:NextNumber(z0 + margin, z0 + zone.length - margin)
					local p = Vector3.new(wx + x, 0, z)
					local ok = true
					-- 시작 지점과 세계 문 근처는 비워 둔다
					if first then
						if (p - Vector3.new(wx, 0, 22)).Magnitude < 22 + def.size then
							ok = false
						elseif (p - (Vector3.new(wx, 0, 0) + World.PORTAL_OFFSET)).Magnitude < 16 + def.size then
							ok = false
						end
					end
					for _, other in ipairs(placed) do
						if (other.pos - p).Magnitude < (other.r + def.size) * 1.05 then
							ok = false
							break
						end
					end
					if ok then
						pos = p
						break
					end
				end
				if pos then
					local base = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
					local model = Props.build(def.id, def.size, base, zi * 100000 + n * 131 + #list)
					model.Name = def.id
					model:SetAttribute("Size", def.size)
					model:SetAttribute("Mass", def.mass)
					model:SetAttribute("Label", def.name)
					local collide = {}
					for _, d in ipairs(model:GetDescendants()) do
						if d:IsA("BasePart") then
							-- 작은 건 걸리적거리지 않게
							d.CanCollide = def.size >= 2.5
							collide[d] = d.CanCollide
						end
					end
					model.Parent = folder
					table.insert(placed, { pos = pos, r = def.size })
					table.insert(list, { model = model, def = def, zone = zi, pos = pos, alive = true, collide = collide })
				end
			end
		end
	end
	return list, folder
end

return World
