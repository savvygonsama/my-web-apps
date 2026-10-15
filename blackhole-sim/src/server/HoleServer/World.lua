-- World (ModuleScript, HoleServer 아래)
-- 조명, 구역 6개의 바닥과 벽, 구역 사이 문, 물체 배치.
-- 구역은 시작 지점(z = 0)에서 +z 쪽으로 차례로 이어진다.
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

-- 구역 바닥, 옆 벽, 구역 사이 문
function World.buildZones(): { BasePart }
	local folder = Instance.new("Folder")
	folder.Name = "Zones"
	folder.Parent = workspace
	local old = workspace:FindFirstChild("Baseplate")
	if old then
		old:Destroy()
	end
	local gates: { BasePart } = {}
	for i, zone in ipairs(Config.Zones) do
		local z0 = Config.zoneStart(i)
		local center = Vector3.new(0, 0, z0 + zone.length / 2)
		part({
			Name = "Ground" .. i,
			Size = Vector3.new(zone.width, 4, zone.length),
			Position = center - Vector3.new(0, 2, 0),
			Color = zone.ground,
			Material = zone.material,
			Parent = folder,
		})
		-- 구역 테두리 길
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
			-- 보이지 않는 옆 벽
			part({
				Name = "SideWall",
				Size = Vector3.new(4, 600, zone.length),
				Position = center + Vector3.new(x * (zone.width / 2 + 2), 300, 0),
				Transparency = 1,
				Parent = folder,
			})
		end
		-- 구역별 꾸밈
		if i == 3 or i == 4 then
			-- 도로: 가운데 길과 흰 선
			part({ Name = "Road", Size = Vector3.new(zone.width * 0.18, 0.15, zone.length), Position = center + Vector3.new(0, 0.08, 0), Color = Color3.fromRGB(45, 45, 50), Material = Enum.Material.Asphalt, CanCollide = false, Parent = folder })
			for k = 0, 9 do
				part({ Name = "Line", Size = Vector3.new(1.2, 0.16, zone.length / 20), Position = Vector3.new(0, 0.1, z0 + zone.length * (k + 0.5) / 10), Color = Color3.fromRGB(240, 230, 120), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
			end
		elseif i == 5 then
			-- 바다 웅덩이
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
		elseif i == 6 then
			-- 우주: 빛나는 격자와 별
			for k = -6, 6 do
				part({ Name = "Grid", Size = Vector3.new(1.5, 0.12, zone.length), Position = center + Vector3.new(k * zone.width / 13, 0.06, 0), Color = Color3.fromRGB(110, 80, 255), Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, Parent = folder })
			end
			local sky = part({ Name = "Stars", Size = Vector3.new(zone.width, 10, zone.length), Position = center + Vector3.new(0, 260, 0), Transparency = 1, CanCollide = false, CanQuery = false, Parent = folder })
			local pe = Instance.new("ParticleEmitter")
			pe.Rate = 120
			pe.Lifetime = NumberRange.new(4, 8)
			pe.Speed = NumberRange.new(0, 1)
			pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 2), NumberSequenceKeypoint.new(1, 0) })
			pe.LightEmission = 1
			pe.Color = ColorSequence.new(Color3.fromRGB(200, 210, 255), Color3.fromRGB(255, 220, 255))
			pe.Parent = sky
		end

		-- 다음 구역으로 가는 문 (마지막 구역은 끝 벽)
		local nextZone = Config.Zones[i + 1]
		local zEnd = z0 + zone.length
		if nextZone then
			local width = math.max(zone.width, nextZone.width)
			local height = 60 + nextZone.need * 2.5
			local gate = part({
				Name = "Gate",
				Size = Vector3.new(width, height, 3),
				Position = Vector3.new(0, height / 2, zEnd),
				Color = Color3.fromRGB(150, 90, 255),
				Material = Enum.Material.ForceField,
				Transparency = 0.2,
				Parent = folder,
			})
			gate:SetAttribute("Need", nextZone.need)
			gate:SetAttribute("Zone", i + 1)
			table.insert(gates, gate)
			-- 문 앞 안내판
			local board = part({
				Name = "GateSign",
				Size = Vector3.new(60, 22, 1),
				Position = Vector3.new(0, 26, zEnd - 3),
				Color = Color3.fromRGB(30, 20, 50),
				Material = Enum.Material.Slate,
				CanCollide = false,
				Parent = folder,
			})
			signText(board, Enum.NormalId.Back, {
				{ string.format("%d구역 · %s", i + 1, nextZone.name), Color3.fromRGB(230, 210, 255), 0.45 },
				{ string.format("크기 %d 이상이면 통과", nextZone.need), Color3.fromRGB(255, 220, 120), 0.45 },
			})
		else
			part({ Name = "EndWall", Size = Vector3.new(zone.width, 600, 4), Position = Vector3.new(0, 300, zEnd + 2), Transparency = 1, Parent = folder })
		end
	end
	-- 시작 쪽 벽
	part({ Name = "StartWall", Size = Vector3.new(Config.Zones[1].width, 600, 4), Position = Vector3.new(0, 300, -2), Transparency = 1, Parent = folder })

	-- 시작 지점
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HoleSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.Position = Vector3.new(0, 0.5, 22)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(120, 70, 220)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.3
	spawn.CanCollide = false
	spawn.Parent = folder
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	local title = part({ Name = "TitleSign", Size = Vector3.new(50, 14, 1), Position = Vector3.new(0, 14, 6), Color = Color3.fromRGB(20, 12, 40), Material = Enum.Material.Slate, CanCollide = false, Parent = folder })
	signText(title, Enum.NormalId.Back, {
		{ "🕳 " .. Config.GAME_TITLE, Color3.fromRGB(210, 170, 255), 0.6 },
		{ "작은 것부터 삼키고 커져라!", Color3.fromRGB(255, 255, 255), 0.4 },
	})
	return gates
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
					local p = Vector3.new(x, 0, z)
					local ok = true
					-- 시작 지점 근처는 비워 둔다
					if zi == 1 and (p - Vector3.new(0, 0, 22)).Magnitude < 22 then
						ok = false
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
