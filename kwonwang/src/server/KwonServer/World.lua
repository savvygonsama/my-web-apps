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


-- 낮과 밤의 시계 (테스트에서 바꾸거나 멈출 수 있다)
local DAY = 16 * 60
local clockT0 = os.clock() - (16.2 - 6) / 24 * DAY
local clockFrozen: number? = nil
function World.clockHour(): number
	if clockFrozen then
		return clockFrozen
	end
	return (6 + (os.clock() - clockT0) / DAY * 24) % 24
end
function World.setClock(hour: number)
	hour = hour % 24
	if clockFrozen then
		clockFrozen = hour
	end
	clockT0 = os.clock() - (hour - 6) / 24 * DAY
	Lighting.ClockTime = hour
end
-- 멈추면 지금 시각에 머문다. 다시 누르면 흐른다
function World.toggleClockFreeze(): boolean
	if clockFrozen then
		local h = clockFrozen
		clockFrozen = nil
		World.setClock(h)
		return false
	end
	clockFrozen = World.clockHour()
	return true
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
	bloom.Intensity = 0.8
	bloom.Size = 32
	bloom.Threshold = 1.12
	bloom.Parent = Lighting
	-- 햇살 줄기 (빛이 구름·나무 사이로 새어 든다)
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
	rays.Intensity = 0.07
	rays.Spread = 0.75
	rays.Parent = Lighting
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Name = "Mood"
	cc.Saturation = 0.1
	cc.Contrast = 0.1
	cc.TintColor = Color3.fromRGB(255, 245, 232)
	cc.Parent = Lighting
	-- 낮과 밤: 한 바퀴 16분. 밤에도 길이 보이게 바깥 빛을 조금 남긴다
	task.spawn(function()
		while true do
			local h = World.clockHour()
			Lighting.ClockTime = h
			local night = (h < 6.5 or h > 18.5) and 1 or 0
			local dusk = math.clamp(1 - math.abs(h - 18.5) / 1.5, 0, 1) + math.clamp(1 - math.abs(h - 6.5) / 1.5, 0, 1)
			local k = math.max(night, dusk * 0.6)
			Lighting.OutdoorAmbient = Color3.fromRGB(150, 140, 130):Lerp(Color3.fromRGB(95, 105, 150), k)
			Lighting.Brightness = 2.3 - k * 0.9
			task.wait(1)
		end
	end)
end

------------------------------------------------------------------------
-- 건축 (특정 나라 양식이 아닌 판타지풍: 흰 돌, 금빛 테, 빛나는 수정, 깃발)
------------------------------------------------------------------------
local ROOF = Color3.fromRGB(60, 72, 100) -- 짙은 청석 지붕
local WOOD = Color3.fromRGB(95, 65, 45)
local STONE = Color3.fromRGB(205, 198, 182) -- 밝은 돌
local STONE_DARK = Color3.fromRGB(95, 92, 98)
local GOLD = Color3.fromRGB(235, 190, 80)
local WARM = Color3.fromRGB(255, 200, 120) -- 창과 등의 따뜻한 빛
local IRON = Color3.fromRGB(45, 45, 50)

local function light(target: BasePart, color: Color3, range: number, brightness: number?)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness or 1.5
	l.Parent = target
end

local function wedge(props: { [string]: any }): WedgePart
	local w = Instance.new("WedgePart")
	w.Anchored = true
	for k, v in pairs(props) do
		if k ~= "Parent" then
			(w :: any)[k] = v
		end
	end
	w.Parent = props.Parent or folder
	return w
end

local function disc(name: string, at: Vector3, radius: number, height: number, color: Color3, material: Enum.Material, parent: Instance, collide: boolean?): Part
	return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, radius * 2, radius * 2), CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = material, CanCollide = collide ~= false, Parent = parent })
end

-- 떠 있는 수정 (마름모꼴로 세워 빛낸다)
local function crystal(at: Vector3, size: number, color: Color3, parent: Instance): Part
	local c = part({ Name = "Crystal", Size = Vector3.new(size, size * 1.6, size), CFrame = CFrame.new(at) * CFrame.Angles(0, math.rad(45), 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), Color = color, Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
	light(c, color, size * 8, 2)
	return c
end

-- 석등: 돌 받침, 기둥, 빛나는 등 칸, 두 겹 돌 갓
local STONE_LAMP = Color3.fromRGB(170, 165, 155)
local function stoneLantern(at: Vector3, parent: Instance, lit: boolean)
	part({ Name = "LampBase", Size = Vector3.new(2.6, 0.8, 2.6), Position = at + Vector3.new(0, 0.4, 0), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = parent })
	part({ Name = "LampPillar", Size = Vector3.new(1, 4, 1), Position = at + Vector3.new(0, 2.8, 0), Color = STONE_LAMP, Material = Enum.Material.Granite, Parent = parent })
	part({ Name = "LampShelf", Size = Vector3.new(2.4, 0.4, 2.4), Position = at + Vector3.new(0, 4.9, 0), Color = STONE_LAMP, Material = Enum.Material.Granite, Parent = parent })
	local box = part({ Name = "LampLight", Size = Vector3.new(1.6, 1.5, 1.6), Position = at + Vector3.new(0, 5.85, 0), Color = WARM, Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
	part({ Name = "LampCap", Size = Vector3.new(3, 0.5, 3), Position = at + Vector3.new(0, 6.85, 0), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = parent })
	part({ Name = "LampCap2", Size = Vector3.new(1.6, 0.5, 1.6), Position = at + Vector3.new(0, 7.35, 0), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = parent })
	if lit then
		light(box, WARM, 20, 1.3)
	end
end

-- 붉은 칠 나무 (문루·종루 기둥)
local GATE_RED = Color3.fromRGB(140, 45, 38)

-- 깃발 (장대 + 천)
local function banner(at: Vector3, h: number, color: Color3, parent: Instance)
	part({ Name = "BannerPole", Size = Vector3.new(0.6, h, 0.6), Position = at + Vector3.new(0, h / 2, 0), Color = IRON, Material = Enum.Material.Metal, Parent = parent })
	part({ Name = "BannerCloth", Size = Vector3.new(3.4, h * 0.45, 0.15), Position = at + Vector3.new(1.9, h * 0.72, 0), Color = color, Material = Enum.Material.Fabric, CanCollide = false, Parent = parent })
	part({ Name = "BannerTip", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1), Position = at + Vector3.new(0, h + 0.4, 0), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = parent })
end

-- 화로 (돌 받침 + 불)
local function brazier(at: Vector3, s: number, parent: Instance)
	part({ Name = "BrazierStand", Size = Vector3.new(1.4, 4, 1.4) * s, Position = at + Vector3.new(0, 2 * s, 0), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = parent })
	local bowl = disc("BrazierBowl", at + Vector3.new(0, 4.4 * s, 0), 1.6 * s, 0.9 * s, GOLD, Enum.Material.Metal, parent)
	local fire = Instance.new("Fire")
	fire.Size = 5 * s
	fire.Heat = 7
	fire.Parent = bowl
	light(bowl, Color3.fromRGB(255, 160, 80), 18 * s, 1.6)
end

-- 맞배지붕: cf = 처마 높이의 가운데, w×d 위를 덮는다
local function roof(cf: CFrame, w: number, d: number, color: Color3, wallColor: Color3, parent: Instance): number
	local over = 1.8
	local hd = d / 2 + over
	local a = math.rad(32)
	local H = hd * math.tan(a)
	local L = hd / math.cos(a)
	local W = w + over * 2
	for _, side in ipairs({ -1, 1 }) do
		part({ Name = "Roof", Size = Vector3.new(W, 0.8, L), CFrame = cf * CFrame.new(0, H / 2, side * hd / 2) * CFrame.Angles(side * a, 0, 0), Color = color, Material = Enum.Material.Slate, Parent = parent })
	end
	for _, sx in ipairs({ -1, 1 }) do
		local x = sx * (w / 2 - 0.2)
		wedge({ Name = "Gable", Size = Vector3.new(0.6, H, hd - over), CFrame = cf * CFrame.new(x, H / 2 - 0.3, -(hd - over) / 2), Color = wallColor, Material = Enum.Material.Plaster, Parent = parent })
		wedge({ Name = "Gable", Size = Vector3.new(0.6, H, hd - over), CFrame = cf * CFrame.new(x, H / 2 - 0.3, (hd - over) / 2) * CFrame.Angles(0, math.pi, 0), Color = wallColor, Material = Enum.Material.Plaster, Parent = parent })
	end
	part({ Name = "Ridge", Size = Vector3.new(W + 0.4, 0.9, 1.2), CFrame = cf * CFrame.new(0, H + 0.25, 0), Color = color:Lerp(Color3.new(0, 0, 0), 0.3), Material = Enum.Material.Slate, Parent = parent })
	return H
end

-- 집 한 채: 돌 기단, 벽, 나무 뼈대, 빛나는 창, 지붕. 앞은 -Z (tiers = 2면 이층)
local WALLS = { Color3.fromRGB(225, 212, 188), Color3.fromRGB(210, 196, 170), Color3.fromRGB(190, 180, 168), Color3.fromRGB(220, 205, 175) }
local ROOFS = { ROOF, Color3.fromRGB(150, 75, 55), Color3.fromRGB(80, 100, 72), Color3.fromRGB(70, 66, 78) }
local function building(at: Vector3, w: number, d: number, rotY: number, parent: Instance, opt: any?)
	local o = opt or {}
	local cf = CFrame.new(at) * CFrame.Angles(0, rotY, 0)
	local h = o.h or 10
	local t = o.terrace or 1
	local wall = o.wall or WALLS[rng:NextInteger(1, #WALLS)]
	local roofColor = o.roof or ROOFS[rng:NextInteger(1, #ROOFS)]
	part({ Name = "Plinth", Size = Vector3.new(w + 2, t, d + 2), CFrame = cf * CFrame.new(0, t / 2, 0), Color = STONE_DARK, Material = Enum.Material.Cobblestone, Parent = parent })
	local base = cf * CFrame.new(0, t, 0)
	local function storey(b: CFrame, sw: number, sd: number, sh: number, withDoor: boolean)
		part({ Name = "Wall", Size = Vector3.new(sw, sh, sd), CFrame = b * CFrame.new(0, sh / 2, 0), Color = wall, Material = Enum.Material.Plaster, Parent = parent })
		-- 나무 뼈대 (모서리 기둥, 위아래 띠)
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				part({ Name = "Post", Size = Vector3.new(1, sh, 1), CFrame = b * CFrame.new(sx * sw / 2, sh / 2, sz * sd / 2), Color = WOOD, Material = Enum.Material.Wood, Parent = parent })
			end
		end
		part({ Name = "Beam", Size = Vector3.new(sw + 0.6, 0.8, sd + 0.6), CFrame = b * CFrame.new(0, sh - 0.4, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = parent })
		-- 창 (앞뒤로, 따뜻하게 빛난다)
		local nWin = math.max(1, math.floor(sw / 7))
		for i = 1, nWin do
			local x = -sw / 2 + i * sw / (nWin + 1)
			if not (withDoor and math.abs(x) < 3) then
				for _, sz in ipairs({ -1, 1 }) do
					part({ Name = "Window", Size = Vector3.new(2, 2.6, 0.2), CFrame = b * CFrame.new(x, sh * 0.58, sz * (sd / 2 + 0.05)), Color = WARM, Material = Enum.Material.Neon, Transparency = 0.25, CanCollide = false, Parent = parent })
					part({ Name = "Sill", Size = Vector3.new(2.6, 0.3, 0.5), CFrame = b * CFrame.new(x, sh * 0.58 - 1.45, sz * (sd / 2 + 0.2)), Color = WOOD, Material = Enum.Material.Wood, CanCollide = false, Parent = parent })
				end
			end
		end
		if withDoor then
			part({ Name = "Door", Size = Vector3.new(3.6, 6.4, 0.3), CFrame = b * CFrame.new(0, 3.2, -sd / 2 - 0.1), Color = WOOD, Material = Enum.Material.WoodPlanks, Parent = parent })
			part({ Name = "DoorArch", Size = Vector3.new(5, 0.9, 0.6), CFrame = b * CFrame.new(0, 6.8, -sd / 2 - 0.2), Color = STONE, Material = Enum.Material.Marble, Parent = parent })
		end
	end
	storey(base, w, d, h, true)
	local top = base * CFrame.new(0, h, 0)
	local rw, rd = w, d
	if o.tiers == 2 then
		-- 이층은 살짝 내밀어 짓는다
		local w2, d2, h2 = w + 1.2, d + 1.2, h * 0.75
		storey(top, w2, d2, h2, false)
		top = top * CFrame.new(0, h2, 0)
		rw, rd = w2, d2
	end
	roof(top, rw, rd, roofColor, wall, parent)
	-- 차양과 벽등
	if o.awning ~= false then
		local aw = part({ Name = "Awning", Size = Vector3.new(math.min(w * 0.5, 10), 0.3, 3), CFrame = base * CFrame.new(0, 7.6, -d / 2 - 1.5) * CFrame.Angles(math.rad(-18), 0, 0), Color = o.awningColor or Color3.fromRGB(150, 50, 45):Lerp(Color3.fromRGB(50, 80, 140), rng:NextNumber()), Material = Enum.Material.Fabric, CanCollide = false, Parent = parent })
		local _ = aw
	end
	local lamp = part({ Name = "WallLamp", Size = Vector3.new(0.9, 1.3, 0.9), CFrame = base * CFrame.new(w / 2 - 1.6, 6, -d / 2 - 0.8), Color = WARM, Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
	light(lamp, WARM, 14, 1.2)
	if o.sign then
		local board = part({ Name = "Signboard", Size = Vector3.new(math.min(w * 0.6, 14), 2.6, 0.4), CFrame = base * CFrame.new(0, h - 1.4, -d / 2 - 0.5), Color = Color3.fromRGB(40, 30, 25), Material = Enum.Material.Wood, CanCollide = false, Parent = parent })
		sign(board, Enum.NormalId.Front, { { o.sign, GOLD, 1 } })
	end
end
local function house(at: Vector3, w: number, d: number, rotY: number, parent: Instance)
	building(at, w, d, rotY, parent, { tiers = rng:NextNumber() < 0.4 and 2 or 1 })
end

-- 첨탑: 가늘어지는 돌 원통을 쌓고 금빛 테를 두른 뒤 꼭대기에 수정
local function spire(at: Vector3, levels: number, r0: number, glow: Color3, parent: Instance)
	disc("SpireBase", at + Vector3.new(0, 1.2, 0), r0 + 4, 2.4, STONE_DARK, Enum.Material.Granite, parent)
	local y = 2.4
	local r = r0
	for i = 1, levels do
		local h = i == 1 and 14 or 9
		disc("SpireBody", at + Vector3.new(0, y + h / 2, 0), r, h, STONE, Enum.Material.Marble, parent)
		disc("SpireRing", at + Vector3.new(0, y + h, 0), r + 0.9, 1.1, GOLD, Enum.Material.Metal, parent)
		-- 층마다 빛나는 좁은 창
		for k = 0, 3 do
			local a = k / 4 * math.pi * 2 + i * 0.4
			part({ Name = "SpireWindow", Size = Vector3.new(1.1, h * 0.45, 0.3), CFrame = CFrame.lookAt(at + Vector3.new(math.cos(a) * r, y + h * 0.55, math.sin(a) * r), at + Vector3.new(0, y + h * 0.55, 0)), Color = glow, Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
		end
		y += h + 1.1
		r *= 0.8
	end
	for k = 1, 4 do
		disc("SpireCap", at + Vector3.new(0, y + k * 1.2, 0), r * (1 - k * 0.2), 1.2, STONE, Enum.Material.Marble, parent)
	end
	crystal(at + Vector3.new(0, y + 10, 0), 3.2, glow, parent)
end

-- 큰 돌문: 두 기둥 + 위를 가로지르는 들보, 문장(빛나는 고리), 양쪽 깃발
local function monumentGate(center: Vector3, yaw: number, parent: Instance, title: string, accent: Color3)
	local cf = CFrame.new(center) * CFrame.Angles(0, yaw, 0)
	for _, sx in ipairs({ -1, 1 }) do
		local x = sx * 13
		part({ Name = "GateFoot", Size = Vector3.new(7, 3, 7), CFrame = cf * CFrame.new(x, 1.5, 0), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = parent })
		part({ Name = "GatePylon", Size = Vector3.new(5, 26, 5), CFrame = cf * CFrame.new(x, 16, 0), Color = STONE, Material = Enum.Material.Marble, Parent = parent })
		part({ Name = "GateBand", Size = Vector3.new(5.6, 0.8, 5.6), CFrame = cf * CFrame.new(x, 9, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = parent })
		part({ Name = "GateCap", Size = Vector3.new(6.4, 1.6, 6.4), CFrame = cf * CFrame.new(x, 29.8, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = parent })
		crystal((cf * CFrame.new(x, 34, 0)).Position, 2.4, accent, parent)
		-- 기둥 앞뒤로 늘어진 깃발
		for _, sz in ipairs({ -1, 1 }) do
			part({ Name = "GateBanner", Size = Vector3.new(3.6, 12, 0.15), CFrame = cf * CFrame.new(x, 19, sz * 2.6), Color = accent, Material = Enum.Material.Fabric, CanCollide = false, Parent = parent })
			part({ Name = "GateBannerTrim", Size = Vector3.new(3.8, 0.5, 0.2), CFrame = cf * CFrame.new(x, 13, sz * 2.62), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = parent })
		end
	end
	-- 문 바깥 양쪽 화로
	for _, sx in ipairs({ -1, 1 }) do
		brazier((cf * CFrame.new(sx * 20, 0, -5)).Position, 1, parent)
	end
	part({ Name = "GateLintel", Size = Vector3.new(34, 4, 5.4), CFrame = cf * CFrame.new(0, 27, 0), Color = STONE, Material = Enum.Material.Marble, Parent = parent })
	part({ Name = "GateLintelGold", Size = Vector3.new(34.4, 0.6, 5.8), CFrame = cf * CFrame.new(0, 25.1, 0), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = parent })
	-- 가운데 문장: 금빛 고리 안의 빛
	local ring = part({ Name = "GateEmblem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 7, 7), CFrame = cf * CFrame.new(0, 31.5, 0) * CFrame.Angles(0, math.rad(90), 0), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = parent })
	local _ = ring
	local core = part({ Name = "GateEmblemCore", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 4.6, 4.6), CFrame = cf * CFrame.new(0, 31.5, 0) * CFrame.Angles(0, math.rad(90), 0), Color = accent, Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
	light(core, accent, 24, 2)
	for _, sz in ipairs({ -1, 1 }) do
		local board = part({ Name = "GateTitle", Size = Vector3.new(20, 3, 0.3), CFrame = cf * CFrame.new(0, 27, sz * 2.86) * CFrame.Angles(0, sz > 0 and math.pi or 0, 0), Color = STONE, Material = Enum.Material.Marble, CanCollide = false, Transparency = 1, Parent = parent })
		sign(board, Enum.NormalId.Front, { { title, GOLD, 1 } })
	end
end

-- 원형 정자: 돌기둥, 둥근 띠, 층층이 줄어드는 둥근 지붕, 꼭대기 수정
local function pavilion(center: Vector3, r: number, n: number, h: number, roofColor: Color3, parent: Instance, glow: Color3?)
	for k = 0, n - 1 do
		local a = (k + 0.5) / n * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		part({ Name = "PavilionColumn", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 1.5, 1.5), CFrame = CFrame.new(p + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = STONE, Material = Enum.Material.Marble, Parent = parent })
		part({ Name = "ColumnCap", Size = Vector3.new(2, 0.6, 2), Position = p + Vector3.new(0, h - 0.3, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = parent })
	end
	disc("PavilionRing", center + Vector3.new(0, h + 0.7, 0), r + 1.2, 1.4, STONE, Enum.Material.Marble, parent)
	disc("PavilionGold", center + Vector3.new(0, h + 0.05, 0), r + 1.4, 0.3, GOLD, Enum.Material.Metal, parent, false)
	for k = 1, 5 do
		local rr = (r + 1.5) * math.cos(math.rad(k * 16))
		disc("PavilionDome", center + Vector3.new(0, h + 1.4 + k * 1.1, 0), rr, 1.2, roofColor, Enum.Material.Slate, parent)
	end
	crystal(center + Vector3.new(0, h + 1.4 + 5 * 1.1 + 4.5, 0), 2.2, glow or GOLD, parent)
end

------------------------------------------------------------------------
-- 작은 것들 (집, 나무, 바위, 대나무)
------------------------------------------------------------------------
local function tree(at: Vector3, s: number, parent: Instance, blossom: boolean?)
	part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10 * s, 1.6 * s, 1.6 * s), CFrame = CFrame.new(at + Vector3.new(0, 5 * s, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(90, 60, 40), Material = Enum.Material.Wood, Parent = parent })
	-- 매화는 짙은 홍매와 흰 백매를 섞는다
	local leaf = blossom and (rng:NextNumber() < 0.6 and Color3.fromRGB(215, 55, 85) or Color3.fromRGB(250, 236, 240)) or Color3.fromRGB(70, 120, 60)
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
				-- 길마다 살짝 다른 높이 (겹치는 곳이 깜빡이지 않게). 자갈 가장자리 위에 돌을 깐 가운데 길
				local y = -0.08 + k * 0.02
				local mid = (a + b) / 2 + Vector3.new(0, y, 0)
				local cf = CFrame.lookAt(mid, mid + (b - a))
				part({ Name = "RoadEdge", Size = Vector3.new(22, 1, len + 22), CFrame = cf, Color = Color3.fromRGB(150, 136, 112), Material = Enum.Material.Pebble, Parent = folder })
				part({ Name = "Road", Size = Vector3.new(14, 1, len + 14), CFrame = cf + Vector3.new(0, 0.01, 0), Color = Color3.fromRGB(188, 172, 140), Material = Enum.Material.Cobblestone, Parent = folder })
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
	-- (한 조각이 2048을 넘지 않게 여러 토막)
	local pieces = math.ceil(W * 2 / 1600)
	local seg = W * 2 / pieces
	for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		for k = 0, pieces - 1 do
			local along = -W + seg * (k + 0.5)
			local size = d[1] ~= 0 and Vector3.new(40, 400, seg) or Vector3.new(seg, 400, 40)
			local pos = d[1] ~= 0 and Vector3.new(d[1] * (W - 20), 200, along) or Vector3.new(along, 200, d[2] * (W - 20))
			part({ Name = "WorldWall", Size = size, Position = pos, Transparency = 1, Parent = folder })
		end
	end
	-- 멀리 둘러싼 산 (배경)
	for i = 0, 31 do
		local a = i / 32 * math.pi * 2
		local dist = Config.WORLD_HALF + 260 + rng:NextNumber(-60, 60)
		local h = rng:NextNumber(260, 520)
		local cap = rng:NextNumber(0.18, 0.28)
		part({
			Name = "SnowCap",
			Size = Vector3.new(160, h * cap, 130),
			CFrame = CFrame.new(math.cos(a) * dist, h - 20 - h * cap / 2 + 2, math.sin(a) * dist) * CFrame.Angles(0, -a, 0),
			Color = Color3.fromRGB(240, 244, 250),
			Material = Enum.Material.Snow,
			CanCollide = false,
			Parent = folder,
		})
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
	-- 마을 성벽 (높은 흰 돌담, 돌 갓, 성가퀴) 네 방향 입구
	local R = 175
	for _, side in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		for _, seg in ipairs({ -1, 1 }) do
			local len = R - 14
			local along = seg * (14 + len / 2)
			local alongX = side[1] == 0
			local function at(y: number, out: number): Vector3
				return alongX and Vector3.new(along, y, side[2] * (R + out)) or Vector3.new(side[1] * (R + out), y, along)
			end
			local function sz(l: number, h: number, t: number): Vector3
				return alongX and Vector3.new(l, h, t) or Vector3.new(t, h, l)
			end
			part({ Name = "VillageWall", Size = sz(len, 12, 4), Position = at(6, 0), Color = STONE, Material = Enum.Material.Cobblestone, Parent = f })
			part({ Name = "WallTrim", Size = sz(len + 0.2, 0.6, 4.6), Position = at(2, 0), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = f })
			part({ Name = "WallCap", Size = sz(len + 0.2, 0.9, 5.4), Position = at(12.45, 0), Color = Color3.fromRGB(225, 220, 205), Material = Enum.Material.Marble, Parent = f })
			local count = math.floor(len / 7)
			for k = 0, count - 1 do
				local off = -len / 2 + (k + 0.5) * (len / count)
				local pos = alongX and Vector3.new(along + off, 14, side[2] * (R + 2.2)) or Vector3.new(side[1] * (R + 2.2), 14, along + off)
				part({ Name = "Merlon", Size = sz(3, 2.4, 1.2), Position = pos, Color = STONE, Material = Enum.Material.Cobblestone, Parent = f })
			end
			-- 성벽 바깥에 드리운 깃발
			for _, off in ipairs({ -len * 0.25, len * 0.25 }) do
				local pos = alongX and Vector3.new(along + off, 7.5, side[2] * (R + 2.15)) or Vector3.new(side[1] * (R + 2.15), 7.5, along + off)
				part({ Name = "WallBanner", Size = sz(4, 9, 0.15), Position = pos, Color = Color3.fromRGB(40, 70, 140), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
				part({ Name = "WallBannerTrim", Size = sz(4.2, 0.5, 0.2), Position = pos + Vector3.new(0, 4.5, 0), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
			end
		end
	end
	-- 네 모서리 둥근 망루 (꼭대기에 수정)
	for _, cx in ipairs({ -1, 1 }) do
		for _, cz in ipairs({ -1, 1 }) do
			local c = Vector3.new(cx * R, 0, cz * R)
			disc("CornerTower", c + Vector3.new(0, 11, 0), 9, 22, STONE, Enum.Material.Cobblestone, f)
			disc("CornerTowerRing", c + Vector3.new(0, 22.4, 0), 10, 1, GOLD, Enum.Material.Metal, f)
			disc("CornerTowerTop", c + Vector3.new(0, 23.6, 0), 10.5, 1.4, Color3.fromRGB(225, 220, 205), Enum.Material.Marble, f)
			for k = 0, 9 do
				local a = k / 10 * math.pi * 2
				part({ Name = "TowerMerlon", Size = Vector3.new(2.4, 2.4, 1.2), CFrame = CFrame.lookAt(c + Vector3.new(math.cos(a) * 9.8, 25.5, math.sin(a) * 9.8), c + Vector3.new(0, 25.5, 0)), Color = STONE, Material = Enum.Material.Cobblestone, Parent = f })
			end
			crystal(c + Vector3.new(0, 31, 0), 3, Color3.fromRGB(120, 200, 255), f)
		end
	end
	-- 큰 돌문 네 개 (성벽 바깥에 선다)
	for _, g in ipairs({ { Vector3.new(0, 0, -R - 9), 0 }, { Vector3.new(0, 0, R + 9), 0 }, { Vector3.new(-R - 9, 0, 0), math.rad(90) }, { Vector3.new(R + 9, 0, 0), math.rad(90) } }) do
		monumentGate(g[1], g[2], f, "청운 마을", Color3.fromRGB(110, 190, 255))
	end
	-- 북쪽 길 양옆의 높은 첨탑 둘
	for _, sx in ipairs({ -1, 1 }) do
		spire(Vector3.new(sx * 110, 0, -95), 5, 9, Color3.fromRGB(120, 200, 255), f)
	end
	-- 마을 한가운데 분수: 둥근 못과 떠오른 큰 수정
	local fc = Vector3.new(0, 0, -62)
	disc("FountainRim", fc + Vector3.new(0, 1, 0), 11, 2, STONE, Enum.Material.Marble, f)
	disc("FountainWater", fc + Vector3.new(0, 1.9, 0), 10, 0.4, Color3.fromRGB(90, 170, 220), Enum.Material.Glass, f, false).Transparency = 0.3
	disc("FountainPillar", fc + Vector3.new(0, 4.5, 0), 1.6, 9, STONE, Enum.Material.Marble, f)
	disc("FountainGold", fc + Vector3.new(0, 9.2, 0), 2.4, 0.6, GOLD, Enum.Material.Metal, f)
	crystal(fc + Vector3.new(0, 14, 0), 4, Color3.fromRGB(120, 200, 255), f)
	local spray = part({ Name = "FountainSpray", Size = Vector3.new(2, 1, 2), Position = fc + Vector3.new(0, 9, 0), Transparency = 1, CanCollide = false, Parent = f })
	local e = Instance.new("ParticleEmitter")
	e.Rate = 40
	e.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255))
	e.Size = NumberSequence.new(0.4, 0.1)
	e.Transparency = NumberSequence.new(0.3, 1)
	e.Speed = NumberRange.new(8, 12)
	e.SpreadAngle = Vector2.new(30, 30)
	e.Acceleration = Vector3.new(0, -25, 0)
	e.Lifetime = NumberRange.new(0.8, 1.2)
	e.Parent = spray
	-- 큰길의 쇠 등기둥 (따뜻한 빛)
	for _, z in ipairs({ -160, -135, -85, -40, 20, 140, 160 }) do
		for _, sx in ipairs({ -1, 1 }) do
			local p = Vector3.new(sx * 13, 0, z)
			part({ Name = "LampPost", Size = Vector3.new(0.6, 10, 0.6), Position = p + Vector3.new(0, 5, 0), Color = IRON, Material = Enum.Material.Metal, Parent = f })
			part({ Name = "LampFoot", Size = Vector3.new(1.6, 0.8, 1.6), Position = p + Vector3.new(0, 0.4, 0), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = f })
			local lamp = part({ Name = "StreetLamp", Size = Vector3.new(1.4, 1.8, 1.4), Position = p + Vector3.new(0, 10.6, 0), Color = WARM, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			part({ Name = "LampCap", Size = Vector3.new(2, 0.5, 2), Position = p + Vector3.new(0, 11.7, 0), Color = IRON, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
			light(lamp, WARM, 18, 1.3)
		end
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
		tree(Vector3.new(s[1], 0, s[2]), 1.1, f)
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

	-- 강호 안내판: 일곱 사부가 어디 있는지 (양옆에 일곱 권법의 깃발)
	local boardAt = Vector3.new(0, 0, -110)
	for i, style in ipairs(Config.Styles) do
		local sx = i % 2 == 0 and 1 or -1
		banner(boardAt + Vector3.new(sx * (22 + math.floor((i - 1) / 2) * 5), 0, 0), 14, style.color, f)
	end
	for _, x in ipairs({ -1, 1 }) do
		part({ Name = "BoardPost", Size = Vector3.new(1.4, 16, 1.4), Position = boardAt + Vector3.new(x * 17, 8, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = f })
	end
	part({ Name = "BoardRoof", Size = Vector3.new(40, 1, 5), Position = boardAt + Vector3.new(0, 16.5, 0), Color = ROOF, Material = Enum.Material.Slate, Parent = f })
	local mboard = part({ Name = "MasterBoard", Size = Vector3.new(32, 13, 0.6), Position = boardAt + Vector3.new(0, 9, 0), Color = Color3.fromRGB(35, 25, 18), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	-- 사부의 자리는 알려 주지 않는다. 떠도는 소문만
	local lines: { { any } } = { { "강호에 떠도는 소문", Color3.fromRGB(255, 215, 120), 0.16 } }
	for _, style in ipairs(Config.Styles) do
		local m = Config.MASTERS[style.id]
		if m then
			table.insert(lines, { "· " .. m.rumor, Color3.fromRGB(235, 225, 205), 0.11 })
		end
	end
	table.insert(lines, { "찾아낸 사부만 지도에 나온다", Color3.fromRGB(200, 190, 170), 0.1 })
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
	-- 객잔: 쉬면 체력과 내공이 가득 찬다
	building(Config.INN_AT, 18, 14, math.rad(90), f, { tiers = 2, sign = "객잔", awningColor = Color3.fromRGB(150, 60, 40) })
	local innDesk = part({ Name = "InnDesk", Size = Vector3.new(3, 3.2, 6), Position = Config.INN_AT + Vector3.new(-11, 1.6, 0), Color = Color3.fromRGB(110, 75, 50), Material = Enum.Material.Wood, Parent = f })
	out.inn = prompt(innDesk, "쉬기", "객잔 · 체력·내공 채우기", "Inn")
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
		elseif spot.kind == "mabo" then
			-- 마보 참장: 세 개의 말뚝 위에서 버틴다
			part({ Name = "MaboBase", Size = Vector3.new(8, 0.8, 8), Position = at + Vector3.new(0, 0.4, 0), Color = Color3.fromRGB(110, 85, 60), Material = Enum.Material.WoodPlanks, Parent = f })
			for k = -1, 1 do
				part({ Name = "MaboPost", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.6, 1.2, 1.2), CFrame = CFrame.new(at + Vector3.new(k * 2.4, 2.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(130, 95, 60), Material = Enum.Material.Wood, Parent = f })
			end
			target = part({ Name = "MaboStake", Size = Vector3.new(1.2, 3.4, 1.2), Position = at + Vector3.new(0, 1.7, 2.6), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood, Parent = f })
		elseif spot.kind == "ironpalm" then
			-- 철사장: 화로 위의 달군 쇠모래 솥
			part({ Name = "CauldronStand", Size = Vector3.new(4.5, 2.4, 4.5), Position = at + Vector3.new(0, 1.2, 0), Color = Color3.fromRGB(70, 65, 65), Material = Enum.Material.Slate, Parent = f })
			target = part({ Name = "IronCauldron", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.2, 5, 5), CFrame = CFrame.new(at + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(55, 50, 50), Material = Enum.Material.Metal, Parent = f })
			local sand = part({ Name = "HotSand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 4.2, 4.2), CFrame = CFrame.new(at + Vector3.new(0, 4.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 120, 40), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			light(sand, Color3.fromRGB(255, 130, 60), 14, 1.6)
			local smoke = Instance.new("Smoke")
			smoke.Color = Color3.fromRGB(120, 110, 100)
			smoke.Opacity = 0.08
			smoke.RiseVelocity = 3
			smoke.Size = 1.5
			smoke.Parent = sand
		elseif spot.kind == "breathing" then
			-- 운기조식: 하늘 고리 아래의 방석, 둘레에 작은 수정
			target = part({ Name = "MeditationCushion", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 4, 4), CFrame = CFrame.new(at + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(120, 60, 140), Material = Enum.Material.Fabric, Parent = f })
			for k = 0, 2 do
				local a = k / 3 * math.pi * 2
				crystal(at + Vector3.new(math.cos(a) * 3.5, 2.2, math.sin(a) * 3.5), 0.9, Color3.fromRGB(150, 230, 255), f)
			end
		elseif spot.kind == "simma" then
			-- 심마 대련: 옛 투기장 한가운데의 검은 제단
			target = part({ Name = "SimmaAltar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 9, 9), CFrame = CFrame.new(at + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(30, 20, 35), Material = Enum.Material.Slate, Parent = f })
			for k = 0, 3 do
				local a = k / 4 * math.pi * 2 + math.rad(45)
				local p = at + Vector3.new(math.cos(a) * 5.5, 0, math.sin(a) * 5.5)
				part({ Name = "SimmaPillar", Size = Vector3.new(1, 7, 1), Position = p + Vector3.new(0, 3.5, 0), Color = Color3.fromRGB(40, 30, 45), Material = Enum.Material.Slate, Parent = f })
				crystal(p + Vector3.new(0, 8.5, 0), 1.2, Color3.fromRGB(190, 70, 255), f)
			end
			local eye = part({ Name = "SimmaEye", Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), Position = at + Vector3.new(0, 6, 0), Color = Color3.fromRGB(200, 60, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			light(eye, Color3.fromRGB(200, 60, 255), 24, 2)
		elseif spot.kind == "waterfall" then
			target = part({ Name = "MeditationStone", Size = Vector3.new(8, 1.2, 8), Position = at + Vector3.new(0, 0.6, 0), Color = Color3.fromRGB(110, 120, 120), Material = Enum.Material.Slate, Parent = f })
		else
			target = part({ Name = "BambooPost", Size = Vector3.new(3, 8, 3), Position = at + Vector3.new(0, 4, 0), Color = Color3.fromRGB(150, 180, 80), Material = Enum.Material.Wood, Parent = f })
			local s = part({ Name = "BambooSign", Size = Vector3.new(10, 3, 0.4), Position = at + Vector3.new(0, 10, 0), Color = Color3.fromRGB(30, 25, 18), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
			sign(s, Enum.NormalId.Front, { { "🎋 경공 수련", Color3.fromRGB(200, 255, 160), 1 } })
		end
		local info = Config.Training[spot.kind]
		-- 강화 수련: 같은 자리, Y키. 빠르고 까다롭지만 세 배 (싸우는 수련엔 없다)
		local hard: ProximityPrompt? = nil
		if not info.fight then
			hard = prompt(target, "강화 수련 (이류부터)", "🔥 " .. info.name, "TrainHard")
			;(hard :: ProximityPrompt).KeyboardKeyCode = Enum.KeyCode.Y
			;(hard :: ProximityPrompt).UIOffset = Vector2.new(0, 70)
		end
		local action = info.fight and "심마 불러내기" or "수련하기"
		local need = info.realm and info.realm > 1 and (" (" .. Config.Realms[info.realm].name .. "부터)") or ""
		table.insert(out.train, { prompt = prompt(target, action .. need, info.icon .. " " .. info.name, "Train"), hard = hard, kind = spot.kind, index = i, pos = at })
	end
	-- (경공 수련 고리는 없앴다)
	out.rings = {}
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
		-- 길은 비워 둔다
		if math.abs(z) > 14 and not nearRoad(Vector3.new(x, 0, z), 14) then
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
	sign(banner, Enum.NormalId.Front, { { "흑호", Color3.fromRGB(230, 60, 40), 0.7 }, { "흑호채", Color3.fromRGB(255, 220, 160), 0.3 } })
	sign(banner, Enum.NormalId.Back, { { "흑호", Color3.fromRGB(230, 60, 40), 0.7 }, { "흑호채", Color3.fromRGB(255, 220, 160), 0.3 } })

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
	-- (들판의 나무는 흩뿌리지 않는다: 길가의 가로수와 몇 군데의 작은 숲으로 - roadside)
end

------------------------------------------------------------------------
-- 일곱 사부의 자리
------------------------------------------------------------------------

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
	pavilion(c + Vector3.new(0, at.Y, 0), 10, 8, 11, Color3.fromRGB(70, 110, 150), f, color)
	-- 다리 (길이 오는 쪽으로)
	local dir = Vector3.new(1, 0, -1).Unit
	local from = c + dir * 13
	local to = c + dir * 82
	local mid = (from + to) / 2 + Vector3.new(0, at.Y - 0.4, 0)
	part({ Name = "Bridge", Size = Vector3.new(6, 0.8, (to - from).Magnitude), CFrame = CFrame.lookAt(mid, mid + dir), Color = Color3.fromRGB(130, 90, 55), Material = Enum.Material.WoodPlanks, Parent = f })
	for _, side in ipairs({ -1, 1 }) do
		local off = Vector3.new(-dir.Z, 0, dir.X) * side * 2.8
		part({ Name = "BridgeRail", Size = Vector3.new(0.4, 0.4, (to - from).Magnitude), CFrame = CFrame.lookAt(mid + off + Vector3.new(0, 2.2, 0), mid + off + Vector3.new(0, 2.2, 0) + dir), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
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
	building(base + Vector3.new(0, at.Y, -12), 44, 22, math.pi, f, { tiers = 2, h = 13, wall = STONE, roof = Color3.fromRGB(190, 150, 60), sign = "금강사", awning = false })
	spire(Vector3.new(at.X + 60, 0, at.Z - 14), 4, 7, color, f)
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
		part({ Name = "MoonGate", Size = Vector3.new(2.6, 2.6, 2), Position = gate + Vector3.new(math.cos(a) * 10, 10 + math.sin(a) * 10, 0), Color = STONE, Material = Enum.Material.Marble, Parent = f })
	end
	crystal(gate + Vector3.new(0, 23, 0), 2.6, color, f)
	pavilion(Vector3.new(at.X - 28, 0, at.Z + 4), 6, 6, 8, Color3.fromRGB(150, 80, 100), f, color)
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
	local pillar = part({ Name = "DragonPillar", Size = Vector3.new(4, 34, 4), Position = Vector3.new(at.X + 18, top + 17, at.Z), Color = STONE, Material = Enum.Material.Marble, Parent = f })
	pavilion(Vector3.new(at.X, top, at.Z), 10, 8, 11, ROOF, f, GOLD)
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

-- 풍신대: 둥근 언덕 위 돌 단, 바람을 받는 높은 깃대와 도는 바람 고리
function SITES.pungsin(r: any, at: Vector3, color: Color3, f: Instance)
	cyl("WindMound", Vector3.new(at.X, at.Y / 2, at.Z), 34, at.Y, Color3.fromRGB(110, 150, 100), Enum.Material.Grass, f)
	cyl("WindDais", Vector3.new(at.X, at.Y + 0.4, at.Z), 14, 0.8, Color3.fromRGB(205, 210, 200), Enum.Material.Marble, f)
	cyl("WindMark", Vector3.new(at.X, at.Y + 0.85, at.Z), 9, 0.1, color, Enum.Material.Neon, f, false).Transparency = 0.5
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local p = Vector3.new(at.X + math.cos(a) * 30, at.Y, at.Z + math.sin(a) * 30)
		part({ Name = "WindPole", Size = Vector3.new(1, 32, 1), Position = p + Vector3.new(0, 16, 0), Color = Color3.fromRGB(220, 220, 215), Material = Enum.Material.Marble, Parent = f })
		for j = 0, 2 do
			part({ Name = "WindRibbon", Size = Vector3.new(0.15, 1.2, 9 - j * 2), CFrame = CFrame.new(p + Vector3.new(0, 30 - j * 3, 0)) * CFrame.Angles(0, a + j * 0.4, 0) * CFrame.new(0, 0, (9 - j * 2) / 2), Color = j % 2 == 0 and color or Color3.fromRGB(245, 255, 250), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
		end
	end
	-- 하늘에 떠서 도는 바람 고리 셋
	for j = 0, 2 do
		local c = Vector3.new(at.X, at.Y + 26 + j * 9, at.Z)
		local ring = part({ Name = "WindRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 30 - j * 7, 30 - j * 7), CFrame = CFrame.new(c) * CFrame.Angles(math.rad(10 + j * 25), j, math.rad(90)), Color = color, Material = Enum.Material.Neon, Transparency = 0.55, CanCollide = false, Parent = f })
		local _ = ring
	end
	for _ = 1, 18 do
		local p = r.center + Vector3.new(rng:NextNumber(-120, 120), 0, rng:NextNumber(-120, 120))
		if (p - Vector3.new(at.X, 0, at.Z)).Magnitude > 44 and not nearRoad(p, 14) then
			rock(p, rng:NextNumber(3, 8), f, Color3.fromRGB(150, 160, 150))
		end
	end
end

-- 취선 주막: 술독과 탁자, '酒' 깃발
function SITES.chwi(r: any, at: Vector3, color: Color3, f: Instance)
	building(Vector3.new(at.X, 0, at.Z + 36), 34, 18, 0, f, { tiers = 2, sign = "취선 주막", awningColor = Color3.fromRGB(170, 60, 40) })
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
	sign(flag, Enum.NormalId.Front, { { "주막", Color3.fromRGB(255, 240, 220), 1 } })
	sign(flag, Enum.NormalId.Back, { { "주막", Color3.fromRGB(255, 240, 220), 1 } })
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
			-- 길이 들어오는 자리에 큰 돌문
			local ok2, err2 = pcall(function()
				for _, road in ipairs(Config.Roads) do
					local a, b = road[#road - 1], road[#road]
					local inside = math.abs(b.X - r.center.X) < r.size.X / 2 and math.abs(b.Z - r.center.Z) < r.size.Z / 2
					if inside then
						local dir = (b - a).Unit
						local p = a
						for k = 0, 400 do
							p = a + dir * (k * 2)
							if math.abs(p.X - r.center.X) < r.size.X / 2 - 8 and math.abs(p.Z - r.center.Z) < r.size.Z / 2 - 8 then
								break
							end
						end
						monumentGate(Vector3.new(p.X, 0, p.Z), math.atan2(-dir.X, -dir.Z), f, string.split(r.name, " (")[1], style.color)
					end
				end
			end)
			if not ok2 then
				warn("[권왕] 사부 자리 문 오류:", r.id, err2)
			end
			-- (빛기둥은 사부를 찾은 사람의 화면에만 그린다)
		end
	end
end

------------------------------------------------------------------------
-- 큰 볼거리 (멀리서도 보이는 랜드마크)
------------------------------------------------------------------------
local LANDMARK: { [string]: (at: Vector3, f: Instance) -> () } = {}

-- 거신상: 주먹을 손바닥에 모아 예를 갖춘 거대한 돌 무인
function LANDMARK.colossus(at: Vector3, f: Instance)
	local face = (Vector3.new(0, 0, 0) - at)
	face = Vector3.new(face.X, 0, face.Z).Unit
	local cf = CFrame.lookAt(at, at + face)
	local function blk(name: string, size: Vector3, off: Vector3, color: Color3?, mat: Enum.Material?, rot: CFrame?)
		part({ Name = name, Size = size, CFrame = cf * CFrame.new(off) * (rot or CFrame.identity), Color = color or Color3.fromRGB(160, 155, 145), Material = mat or Enum.Material.Granite, Parent = f })
	end
	blk("ColossusBase", Vector3.new(34, 6, 30), Vector3.new(0, 3, 0), STONE_DARK, Enum.Material.Cobblestone)
	blk("ColossusBase2", Vector3.new(26, 4, 22), Vector3.new(0, 8, 0), STONE, Enum.Material.Marble)
	for i = 1, 4 do
		blk("ColossusStep", Vector3.new(14, i * 2.5, 3), Vector3.new(0, i * 1.25, -15 - (5 - i) * 3), STONE, Enum.Material.Marble)
	end
	local y = 10
	-- 다리 (말 타듯 벌려 선 자세)
	for _, sx in ipairs({ -1, 1 }) do
		blk("ColossusLeg", Vector3.new(5.5, 20, 6), Vector3.new(sx * 6, y + 10, 0), nil, nil, CFrame.Angles(0, 0, sx * math.rad(12)))
		blk("ColossusFoot", Vector3.new(7, 2.5, 9), Vector3.new(sx * 8, y + 1.25, -1))
	end
	blk("ColossusHip", Vector3.new(16, 6, 8), Vector3.new(0, y + 21, 0))
	blk("ColossusSash", Vector3.new(16.6, 2, 8.6), Vector3.new(0, y + 23, 0), GOLD, Enum.Material.Metal)
	blk("ColossusTorso", Vector3.new(18, 18, 9), Vector3.new(0, y + 33, 0))
	blk("ColossusHead", Vector3.new(8, 9, 8), Vector3.new(0, y + 47, 0))
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "ColossusEye", Size = Vector3.new(1.4, 0.8, 0.4), CFrame = cf * CFrame.new(sx * 1.8, y + 48, -4.1), Color = Color3.fromRGB(120, 220, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		-- 어깨에서 가슴 앞으로 모은 팔
		blk("ColossusUpperArm", Vector3.new(5, 12, 5), Vector3.new(sx * 11.5, y + 36, -3), nil, nil, CFrame.Angles(math.rad(-40), 0, sx * math.rad(20)))
		blk("ColossusForearm", Vector3.new(4.5, 11, 4.5), Vector3.new(sx * 6, y + 32, -10), nil, nil, CFrame.Angles(math.rad(-90), sx * math.rad(-55), 0))
	end
	part({ Name = "ColossusFist", Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), CFrame = cf * CFrame.new(-1.2, y + 33, -14), Color = Color3.fromRGB(160, 155, 145), Material = Enum.Material.Granite, Parent = f })
	blk("ColossusPalm", Vector3.new(1.5, 7, 6), Vector3.new(2.2, y + 33, -14))
	crystal((cf * CFrame.new(0, y + 62, 0)).Position, 4, Color3.fromRGB(120, 220, 255), f)
	for _, sx in ipairs({ -1, 1 }) do
		brazier((cf * CFrame.new(sx * 15, 10, -9)).Position, 1.3, f)
	end
end

-- 하늘 고리: 공중에 선 거대한 돌 고리와 그 안에 떠 있는 수정들
function LANDMARK.skyring(at: Vector3, f: Instance)
	local face = Vector3.new(-at.X, 0, -at.Z).Unit
	local c = at + Vector3.new(0, 60, 0)
	local cf = CFrame.lookAt(c, c + face)
	local R = 30
	for k = 0, 39 do
		local a = k / 40 * math.pi * 2
		part({ Name = "SkyRingStone", Size = Vector3.new(5.4, 5.4, 4), CFrame = cf * CFrame.new(math.cos(a) * R, math.sin(a) * R, 0) * CFrame.Angles(0, 0, a), Color = k % 5 == 0 and GOLD or STONE, Material = k % 5 == 0 and Enum.Material.Metal or Enum.Material.Marble, CanCollide = false, Parent = f })
	end
	crystal(c, 6, Color3.fromRGB(150, 230, 255), f)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		crystal((cf * CFrame.new(math.cos(a) * 14, math.sin(a) * 14, 0)).Position, 2.2, Color3.fromRGB(200, 170, 255), f)
	end
	-- 땅의 둥근 돌 터와 하늘로 이어진 빛
	disc("SkyRingFloor", at + Vector3.new(0, 0.4, 0), 26, 0.8, STONE, Enum.Material.Marble, f)
	disc("SkyRingRune", at + Vector3.new(0, 0.85, 0), 18, 0.1, Color3.fromRGB(150, 230, 255), Enum.Material.Neon, f, false).Transparency = 0.5
	part({ Name = "SkyRingBeam", Size = Vector3.new(1.6, 30, 1.6), Position = at + Vector3.new(0, 15, 0), Color = Color3.fromRGB(150, 230, 255), Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, CastShadow = false, Parent = f })
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * 24, 0, math.sin(a) * 24)
		part({ Name = "SkyRingObelisk", Size = Vector3.new(2.4, 12, 2.4), Position = p + Vector3.new(0, 6, 0), Color = STONE, Material = Enum.Material.Marble, Parent = f })
		part({ Name = "ObeliskTip", Size = Vector3.new(1.2, 1.2, 1.2), CFrame = CFrame.new(p + Vector3.new(0, 12.8, 0)) * CFrame.Angles(math.rad(45), 0, math.rad(45)), Color = Color3.fromRGB(150, 230, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
end

-- 옛 투기장: 무너진 둥근 기둥 벽, 모래 바닥, 몇 개 남은 아치
function LANDMARK.colosseum(at: Vector3, f: Instance)
	disc("ArenaSand", at + Vector3.new(0, 0.3, 0), 36, 0.6, Color3.fromRGB(205, 185, 140), Enum.Material.Sand, f)
	disc("ArenaCircle", at + Vector3.new(0, 0.65, 0), 14, 0.1, Color3.fromRGB(150, 60, 50), Enum.Material.Slate, f, false)
	local n = 28
	local heights = {}
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		local h = (k % 7 == 3) and 0 or (rng:NextNumber() < 0.3 and rng:NextNumber(5, 12) or 22)
		heights[k] = h
		if h > 0 then
			local p = at + Vector3.new(math.cos(a) * 42, 0, math.sin(a) * 42)
			part({ Name = "ArenaPillar", Size = Vector3.new(4, h, 4), CFrame = CFrame.lookAt(p + Vector3.new(0, h / 2, 0), at + Vector3.new(0, h / 2, 0)), Color = Color3.fromRGB(190, 180, 160), Material = Enum.Material.Cobblestone, Parent = f })
		end
	end
	-- 온전한 기둥 둘 사이엔 아치 들보
	for k = 0, n - 1 do
		local k2 = (k + 1) % n
		if heights[k] == 22 and heights[k2] == 22 then
			local a = (k + 0.5) / n * math.pi * 2
			local p = at + Vector3.new(math.cos(a) * 42, 23, math.sin(a) * 42)
			part({ Name = "ArenaLintel", Size = Vector3.new(10, 2.4, 4.4), CFrame = CFrame.lookAt(p, at + Vector3.new(0, 23, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(180, 170, 150), Material = Enum.Material.Cobblestone, Parent = f })
		end
	end
	-- 계단식 관중석 (바깥 둘레)
	for i = 1, 3 do
		local r = 46 + i * 4
		for k = 0, 35 do
			if k % 9 ~= 0 then
				local a = k / 36 * math.pi * 2
				local p = at + Vector3.new(math.cos(a) * r, i * 1.5, math.sin(a) * r)
				part({ Name = "ArenaSeat", Size = Vector3.new(4, i * 3, 9.2), CFrame = CFrame.lookAt(p, Vector3.new(at.X, p.Y, at.Z)) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(170, 160, 140), Material = Enum.Material.Cobblestone, Parent = f })
			end
		end
	end
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + 0.4
		banner(at + Vector3.new(math.cos(a) * 34, 0, math.sin(a) * 34), 16, Color3.fromRGB(150, 40, 35), f)
	end
end

-- 수정 들판: 땅에서 솟은 거대한 수정 무리
function LANDMARK.crystals(at: Vector3, f: Instance)
	disc("CrystalGlow", at + Vector3.new(0, 0.2, 0), 70, 0.4, Color3.fromRGB(70, 60, 110), Enum.Material.Slate, f)
	for k = 1, 26 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(0, 62)
		local h = rng:NextNumber(6, 26) * (d < 20 and 1.6 or 1)
		local w = h * rng:NextNumber(0.22, 0.35)
		local p = at + Vector3.new(math.cos(a) * d, h * 0.4, math.sin(a) * d)
		local color = k % 3 == 0 and Color3.fromRGB(200, 140, 255) or Color3.fromRGB(110, 220, 255)
		local cr = part({ Name = "GiantCrystal", Size = Vector3.new(w, h, w), CFrame = CFrame.new(p) * CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber(0, 6), rng:NextNumber(-0.35, 0.35)), Color = color, Material = Enum.Material.Neon, Transparency = 0.15, Parent = f })
		if k % 4 == 0 then
			light(cr, color, 30, 1.5)
		end
	end
	crystal(at + Vector3.new(0, 48, 0), 7, Color3.fromRGB(180, 150, 255), f)
end

-- 천년 고목: 하늘을 덮는 거대한 나무와 뿌리 사이의 돌 제단
function LANDMARK.worldtree(at: Vector3, f: Instance)
	local bark = Color3.fromRGB(85, 62, 45)
	disc("TreeTrunk", at + Vector3.new(0, 40, 0), 9, 80, bark, Enum.Material.Wood, f)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * 12, 3, math.sin(a) * 12)
		part({ Name = "TreeRoot", Size = Vector3.new(4, 4, 18), CFrame = CFrame.lookAt(p, at + Vector3.new(0, 8, 0)), Color = bark, Material = Enum.Material.Wood, Parent = f })
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		local from = at + Vector3.new(0, 55 + (k % 3) * 8, 0)
		local to = from + Vector3.new(math.cos(a) * 32, 14, math.sin(a) * 32)
		part({ Name = "TreeBranch", Size = Vector3.new(3.5, 3.5, (to - from).Magnitude), CFrame = CFrame.lookAt((from + to) / 2, to), Color = bark, Material = Enum.Material.Wood, Parent = f })
		part({ Name = "TreeCanopy", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1) * rng:NextNumber(26, 36), Position = to + Vector3.new(0, 6, 0), Color = Color3.fromRGB(60, 120, 60):Lerp(Color3.fromRGB(110, 160, 80), rng:NextNumber()), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
	end
	part({ Name = "TreeCrown", Shape = Enum.PartType.Ball, Size = Vector3.new(50, 50, 50), Position = at + Vector3.new(0, 92, 0), Color = Color3.fromRGB(75, 135, 65), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
	-- 반딧불
	local glow = part({ Name = "Fireflies", Size = Vector3.new(80, 30, 80), Position = at + Vector3.new(0, 25, 0), Transparency = 1, CanCollide = false, Parent = f })
	local e = Instance.new("ParticleEmitter")
	e.Rate = 25
	e.Color = ColorSequence.new(Color3.fromRGB(230, 255, 150))
	e.LightEmission = 1
	e.Size = NumberSequence.new(0.3)
	e.Lifetime = NumberRange.new(3, 6)
	e.Speed = NumberRange.new(0.5, 2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = glow
	-- 뿌리 앞 제단
	local face = Vector3.new(-at.X, 0, -at.Z).Unit
	local altar = at + face * 18
	disc("TreeAltar", altar + Vector3.new(0, 0.8, 0), 6, 1.6, STONE, Enum.Material.Marble, f)
	crystal(altar + Vector3.new(0, 5, 0), 2.4, Color3.fromRGB(170, 255, 140), f)
end

-- 핏빛 달: 혈월곡 하늘에 걸린 붉은 달 (어디서든 보인다)
function LANDMARK.moon(at: Vector3, f: Instance)
	local moon = part({ Name = "BloodMoon", Shape = Enum.PartType.Ball, Size = Vector3.new(80, 80, 80), Position = at + Vector3.new(0, 300, 0), Color = Color3.fromRGB(200, 40, 40), Material = Enum.Material.Neon, CanCollide = false, CastShadow = false, Parent = f })
	light(moon, Color3.fromRGB(255, 60, 50), 60, 1)
end

-- 만검총: 수백 자루의 검이 꽂힌 무덤, 한가운데 하늘까지 닿는 거대한 검
function LANDMARK.swordtomb(at: Vector3, f: Instance)
	local STEEL = Color3.fromRGB(190, 195, 205)
	local RUNE = Color3.fromRGB(120, 200, 255)
	cyl("SwordMound", at + Vector3.new(0, 3, 0), 60, 6, Color3.fromRGB(110, 100, 90), Enum.Material.Ground, f)
	cyl("SwordMound2", at + Vector3.new(0, 8, 0), 38, 6, Color3.fromRGB(100, 92, 85), Enum.Material.Ground, f)
	-- 둘레에 꽂힌 검들 (기울기가 제각각)
	for _ = 1, 70 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(12, 60)
		local base = at + Vector3.new(math.cos(a) * d, d < 38 and 11 or 6, math.sin(a) * d)
		local tilt = CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber(0, 6.28), rng:NextNumber(-0.35, 0.35))
		local len = rng:NextNumber(5, 9)
		local cf = CFrame.new(base) * tilt
		part({ Name = "TombBlade", Size = Vector3.new(0.25, len, 0.9), CFrame = cf * CFrame.new(0, len / 2 - 1.5, 0), Color = STEEL, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
		part({ Name = "TombGuard", Size = Vector3.new(0.5, 0.35, 2.4), CFrame = cf * CFrame.new(0, len - 1.4, 0), Color = rng:NextNumber() < 0.2 and GOLD or IRON, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
	end
	-- 한가운데의 거대한 검 (땅에 비스듬히 박혀 있다)
	local cf = CFrame.new(at + Vector3.new(0, 11, 0)) * CFrame.Angles(math.rad(8), math.rad(30), math.rad(-6))
	part({ Name = "GiantBlade", Size = Vector3.new(2.5, 90, 11), CFrame = cf * CFrame.new(0, 38, 0), Color = STEEL, Material = Enum.Material.Metal, Parent = f })
	part({ Name = "GiantEdge", Size = Vector3.new(0.6, 88, 1.2), CFrame = cf * CFrame.new(0, 38, 5.8), Color = Color3.fromRGB(235, 240, 250), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	part({ Name = "GiantFuller", Size = Vector3.new(2.7, 70, 1.4), CFrame = cf * CFrame.new(0, 34, 0), Color = RUNE, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	part({ Name = "GiantGuard", Size = Vector3.new(5, 5, 34), CFrame = cf * CFrame.new(0, 84, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
	part({ Name = "GiantGrip", Size = Vector3.new(4, 22, 4), CFrame = cf * CFrame.new(0, 97, 0), Color = Color3.fromRGB(60, 40, 30), Material = Enum.Material.Fabric, Parent = f })
	local pommel = part({ Name = "GiantPommel", Shape = Enum.PartType.Ball, Size = Vector3.new(8, 8, 8), CFrame = cf * CFrame.new(0, 110, 0), Color = RUNE, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	light(pommel, RUNE, 60, 3)
	-- 검을 휘감은 사슬과 떠도는 빛
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		part({ Name = "SwordChain", Size = Vector3.new(0.6, 0.6, 14), CFrame = cf * CFrame.new(math.cos(a) * 7, 20 + k * 5, math.sin(a) * 7) * CFrame.Angles(0, a, 0.6), Color = IRON, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
	end
	emitter(pommel, RUNE, 12, 0.8, 3, 3)
end

-- 끊어진 하늘다리: 땅에서 하늘로 솟다가 허공에서 뚝 끊긴 돌다리. 끊긴 끝에서 조각들이 떠 있다
function LANDMARK.skybridge(at: Vector3, f: Instance)
	local dir = Vector3.new(-1, 0, -1).Unit
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local N = 34
	for i = 0, N - 1 do
		local k = i / N
		local p = at + dir * (i * 9) + Vector3.new(0, 4 + math.sin(k * math.pi * 0.62) * 150, 0)
		local q = at + dir * ((i + 1) * 9) + Vector3.new(0, 4 + math.sin((i + 1) / N * math.pi * 0.62) * 150, 0)
		local cf = CFrame.lookAt((p + q) / 2, q)
		part({ Name = "BridgeDeck", Size = Vector3.new(16, 2.5, (q - p).Magnitude + 0.4), CFrame = cf, Color = STONE, Material = Enum.Material.Marble, Parent = f })
		for _, sx in ipairs({ -1, 1 }) do
			part({ Name = "BridgeRail", Size = Vector3.new(1.2, 3, (q - p).Magnitude + 0.4), CFrame = cf * CFrame.new(sx * 7.5, 2.6, 0), Color = STONE_DARK, Material = Enum.Material.Marble, Parent = f })
		end
		if i % 6 == 0 and p.Y > 20 then
			-- 다리를 받친 높은 기둥
			part({ Name = "BridgePier", Size = Vector3.new(7, p.Y, 7), Position = Vector3.new(p.X, p.Y / 2, p.Z), Color = STONE, Material = Enum.Material.Marble, Parent = f })
			part({ Name = "BridgeLamp", Size = Vector3.new(2, 2, 2), Position = p + side * 8 + Vector3.new(0, 5, 0), Color = WARM, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		end
	end
	-- 끊긴 끝: 허공에 떠 있는 부서진 조각
	local tip = at + dir * (N * 9) + Vector3.new(0, 4 + math.sin(math.pi * 0.62) * 150, 0)
	for k = 1, 14 do
		local p = tip + dir * (k * 5) + Vector3.new(rng:NextNumber(-10, 10), rng:NextNumber(-8, 12) - k * 1.5, rng:NextNumber(-10, 10))
		local s = rng:NextNumber(3, 9)
		part({ Name = "BridgeShard", Size = Vector3.new(s, s * 0.35, s * 0.8), CFrame = CFrame.new(p) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)), Color = STONE, Material = Enum.Material.Marble, Parent = f })
	end
	local glow = part({ Name = "BridgeEndGlow", Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), Position = tip + Vector3.new(0, 4, 0), Color = Color3.fromRGB(190, 230, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	light(glow, Color3.fromRGB(190, 230, 255), 70, 3)
	emitter(glow, Color3.fromRGB(220, 240, 255), 8, 1, 2, 4)
end

-- 용의 무덤: 땅에 반쯤 묻힌 거대한 용의 뼈. 갈비뼈 사이로 길이 난다
function LANDMARK.dragonbones(at: Vector3, f: Instance)
	local BONE = Color3.fromRGB(225, 215, 190)
	local face = Vector3.new(1, 0, 0.35).Unit
	local side = Vector3.new(-face.Z, 0, face.X)
	-- 등뼈: 물결치며 이어지는 마디
	local spine = {}
	for i = 0, 30 do
		local p = at + face * (i * 6 - 90) + side * math.sin(i * 0.3) * 10 + Vector3.new(0, 10 + math.sin(i * 0.22) * 6, 0)
		table.insert(spine, p)
		part({ Name = "Vertebra", Size = Vector3.new(4.5, 5, 4.5), CFrame = CFrame.lookAt(p, p + face) * CFrame.Angles(0, 0, math.rad(45)), Color = BONE, Material = Enum.Material.Limestone, Parent = f })
		part({ Name = "SpineFin", Size = Vector3.new(1, 5 + (i % 3) * 1.5, 2.5), CFrame = CFrame.new(p + Vector3.new(0, 4, 0)), Color = BONE, Material = Enum.Material.Limestone, CanCollide = false, Parent = f })
	end
	-- 갈비뼈: 마디마다 양쪽으로 휜 두 토막
	for i = 6, 20, 2 do
		local p = spine[i]
		local len = 22 - math.abs(i - 13) * 1.2
		for _, sx in ipairs({ -1, 1 }) do
			local mid = p + side * sx * len * 0.55 + Vector3.new(0, -2, 0)
			local foot = p + side * sx * len * 0.9 + Vector3.new(0, -p.Y + 1, 0)
			part({ Name = "Rib", Size = Vector3.new(1.6, 1.6, (mid - p).Magnitude), CFrame = CFrame.lookAt((p + mid) / 2, mid), Color = BONE, Material = Enum.Material.Limestone, Parent = f })
			part({ Name = "Rib", Size = Vector3.new(1.5, 1.5, (foot - mid).Magnitude), CFrame = CFrame.lookAt((mid + foot) / 2, foot), Color = BONE, Material = Enum.Material.Limestone, Parent = f })
		end
	end
	-- 머리뼈: 길게 뻗은 주둥이, 이빨, 뿔, 빈 눈구멍의 푸른 불
	local head = spine[#spine] + face * 12
	local hcf = CFrame.lookAt(head, head + face) * CFrame.Angles(math.rad(-12), 0, 0)
	part({ Name = "Skull", Size = Vector3.new(12, 9, 14), CFrame = hcf, Color = BONE, Material = Enum.Material.Limestone, Parent = f })
	part({ Name = "Snout", Size = Vector3.new(8, 5, 16), CFrame = hcf * CFrame.new(0, -1.5, -14), Color = BONE, Material = Enum.Material.Limestone, Parent = f })
	part({ Name = "Jaw", Size = Vector3.new(7, 2.5, 18), CFrame = hcf * CFrame.new(0, -7, -10) * CFrame.Angles(math.rad(18), 0, 0), Color = BONE, Material = Enum.Material.Limestone, Parent = f })
	for k = 0, 5 do
		for _, sx in ipairs({ -1, 1 }) do
			part({ Name = "Fang", Size = Vector3.new(0.8, 2.6, 0.8), CFrame = hcf * CFrame.new(sx * 3.2, -4.6, -8 - k * 2.6), Color = Color3.fromRGB(245, 240, 225), Material = Enum.Material.Limestone, CanCollide = false, Parent = f })
		end
	end
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "Horn", Size = Vector3.new(2, 2, 18), CFrame = hcf * CFrame.new(sx * 4.5, 5, 7) * CFrame.Angles(math.rad(30), sx * math.rad(20), 0), Color = Color3.fromRGB(70, 60, 55), Material = Enum.Material.Slate, Parent = f })
		local eye = part({ Name = "SoulFire", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), CFrame = hcf * CFrame.new(sx * 3.4, 1.5, -6.6), Color = Color3.fromRGB(90, 200, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		emitter(eye, Color3.fromRGB(120, 220, 255), 10, 0.8, 2, 1.2)
	end
	-- 둘레에 떨어진 비늘 같은 돌
	for _ = 1, 16 do
		local p = at + Vector3.new(rng:NextNumber(-110, 110), 0, rng:NextNumber(-80, 80))
		rock(p, rng:NextNumber(2, 6), f, Color3.fromRGB(120, 110, 100))
	end
end

-- 불의 산: 꼭대기 분화구에서 연기와 불빛이 솟는 화산. 비탈로 용암 줄기가 흘러내린다
function LANDMARK.volcano(at: Vector3, f: Instance)
	local ROCK = Color3.fromRGB(55, 42, 38)
	local LAVA = Color3.fromRGB(255, 110, 30)
	local layers = 11
	for i = 0, layers - 1 do
		local r = 170 - i * 12.5
		cyl("VolcanoSlope", at + Vector3.new(0, 9 + i * 18, 0), r, 18.5, ROCK:Lerp(Color3.fromRGB(35, 28, 26), i / layers), Enum.Material.Basalt, f)
	end
	local top = at + Vector3.new(0, layers * 18, 0)
	local crater = cyl("Crater", top + Vector3.new(0, 0.4, 0), 30, 1, LAVA, Enum.Material.Neon, f, false)
	light(crater, LAVA, 120, 5)
	emitter(crater, Color3.fromRGB(70, 60, 60), 30, 12, 14, 6)
	local sparks = cyl("CraterSparks", top + Vector3.new(0, 1, 0), 26, 0.5, LAVA, Enum.Material.Neon, f, false)
	sparks.Transparency = 1
	emitter(sparks, LAVA, 20, 1.2, 30, 2)
	-- 흘러내리는 용암 줄기
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		for i = 0, layers - 2 do
			local r = 170 - i * 12.5
			local p = at + d * (r - 4) + Vector3.new(0, 18 + i * 18, 0)
			part({ Name = "LavaFlow", Size = Vector3.new(5 + (layers - i) * 0.5, 0.6, 14), CFrame = CFrame.lookAt(p, p + d) * CFrame.Angles(math.rad(-50), 0, 0), Color = LAVA, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		end
	end
	-- 발치의 용암 웅덩이
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * 200, 0, math.sin(a) * 200)
		disc("LavaPool", p + Vector3.new(0, 0.15, 0), rng:NextNumber(8, 16), 0.3, LAVA, Enum.Material.Neon, f, false)
	end
end

-- 사왕의 무덤: 모래 위의 계단식 거대한 무덤. 꼭대기에 금빛 머릿돌, 앞에 반쯤 묻힌 왕의 얼굴
function LANDMARK.pyramid(at: Vector3, f: Instance)
	local SAND = Color3.fromRGB(205, 175, 115)
	local n = 12
	for i = 0, n - 1 do
		local w = 200 - i * 15
		part({ Name = "TombStep", Size = Vector3.new(w, 9, w), Position = at + Vector3.new(0, 4.5 + i * 9, 0), Color = SAND:Lerp(Color3.fromRGB(170, 140, 90), (i % 2) * 0.4), Material = Enum.Material.Sandstone, Parent = f })
	end
	local cap = part({ Name = "TombCap", Size = Vector3.new(18, 14, 18), CFrame = CFrame.new(at + Vector3.new(0, n * 9 + 7, 0)) * CFrame.Angles(0, math.rad(45), 0), Color = GOLD, Material = Enum.Material.Neon, Parent = f })
	light(cap, GOLD, 90, 3)
	-- 앞 (마을 쪽) 계단과 문
	local front = Vector3.new(0, 0, -1)
	for i = 0, 10 do
		part({ Name = "TombStair", Size = Vector3.new(26, 2, 6), Position = at + front * (100 + 30 - i * 3) + Vector3.new(0, 1 + i * 2, 0), Color = SAND, Material = Enum.Material.Sandstone, Parent = f })
	end
	monumentGate(at + front * 135, 0, f, "사왕릉", GOLD)
	-- 반쯤 묻힌 왕의 얼굴
	local hp = at + front * 175 + Vector3.new(60, 0, 0)
	local hcf = CFrame.lookAt(hp + Vector3.new(0, 10, 0), hp + Vector3.new(0, 10, 0) + front) * CFrame.Angles(math.rad(-10), 0, math.rad(8))
	part({ Name = "KingFace", Size = Vector3.new(22, 26, 20), CFrame = hcf, Color = SAND, Material = Enum.Material.Sandstone, Parent = f })
	part({ Name = "KingCrown", Size = Vector3.new(24, 7, 22), CFrame = hcf * CFrame.new(0, 16, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
	for k = -2, 2 do
		part({ Name = "CrownSpike", Size = Vector3.new(2.5, 7, 2.5), CFrame = hcf * CFrame.new(k * 4.5, 22, -10), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
	end
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "KingEye", Size = Vector3.new(4, 1.6, 0.6), CFrame = hcf * CFrame.new(sx * 5, 4, -10.2), Color = Color3.fromRGB(60, 200, 190), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	part({ Name = "KingNose", Size = Vector3.new(3.5, 7, 3), CFrame = hcf * CFrame.new(0, -1, -11), Color = SAND, Material = Enum.Material.Sandstone, Parent = f })
	-- 무덤을 둘러싼 돌 기둥
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * 150, 0, math.sin(a) * 150)
		part({ Name = "TombObelisk", Size = Vector3.new(6, 46, 6), Position = p + Vector3.new(0, 23, 0), Color = SAND:Lerp(Color3.new(0, 0, 0), 0.15), Material = Enum.Material.Sandstone, Parent = f })
		part({ Name = "ObeliskTip", Size = Vector3.new(4, 4, 4), CFrame = CFrame.new(p + Vector3.new(0, 48, 0)) * CFrame.Angles(0, math.rad(45), math.rad(45)), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
	end
end

-- 천외봉: 구름바다 위로 하늘에 닿는 흰 봉우리. 둘레에 떠도는 고리와 섬, 꼭대기에서 하늘로 빛기둥. 발치에 시원자의 단
-- 천년 종루: 세 층 누각 꼭대기에 커다란 청동 종. 층마다 빛나는 창과 처마
function LANDMARK.belltower(at: Vector3, f: Instance)
	local BRONZE = Color3.fromRGB(160, 110, 60)
	part({ Name = "BellBase", Size = Vector3.new(40, 4, 40), Position = at + Vector3.new(0, 2, 0), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = f })
	part({ Name = "BellBase2", Size = Vector3.new(34, 3, 34), Position = at + Vector3.new(0, 5.5, 0), Color = STONE, Material = Enum.Material.Marble, Parent = f })
	for i = 0, 3 do
		part({ Name = "BellStep", Size = Vector3.new(14, (i + 1) * 1.75, 3), Position = at + Vector3.new(0, (i + 1) * 0.875, -21.5 - (3 - i) * 3), Color = STONE, Material = Enum.Material.Marble, Parent = f })
	end
	local y = 7
	local w = 26
	for tier = 1, 3 do
		local h = 14 - tier * 2
		part({ Name = "BellWall", Size = Vector3.new(w, h, w), Position = at + Vector3.new(0, y + h / 2, 0), Color = WALLS[1], Material = Enum.Material.Plaster, Parent = f })
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				part({ Name = "BellPillar", Size = Vector3.new(2, h, 2), Position = at + Vector3.new(sx * w / 2, y + h / 2, sz * w / 2), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
			end
		end
		for k = 0, 3 do
			local yaw = k * math.pi / 2
			local cf = CFrame.new(at + Vector3.new(0, y + h * 0.55, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, -w / 2 - 0.05)
			part({ Name = "BellWindow", Size = Vector3.new(w * 0.4, h * 0.4, 0.2), CFrame = cf, Color = WARM, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		end
		-- 처마: 사방으로 뻗은 기와 판
		local ey = y + h
		part({ Name = "BellEave", Size = Vector3.new(w + 10, 1, w + 10), Position = at + Vector3.new(0, ey + 0.5, 0), Color = ROOF, Material = Enum.Material.Slate, Parent = f })
		part({ Name = "BellEave2", Size = Vector3.new(w + 6, 1, w + 6), Position = at + Vector3.new(0, ey + 1.5, 0), Color = ROOF:Lerp(Color3.new(0, 0, 0), 0.2), Material = Enum.Material.Slate, Parent = f })
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				part({ Name = "EaveTip", Size = Vector3.new(1, 1.4, 1), CFrame = CFrame.new(at + Vector3.new(sx * (w / 2 + 5), ey + 1.3, sz * (w / 2 + 5))) * CFrame.Angles(0, 0, sx * math.rad(-30)), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
			end
		end
		y = ey + 2
		w -= 6
	end
	-- 꼭대기 종각: 기둥 넷 위 지붕, 그 아래 매달린 큰 종
	local top = at + Vector3.new(0, y, 0)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part({ Name = "BellFrame", Size = Vector3.new(1.6, 16, 1.6), Position = top + Vector3.new(sx * 6, 8, sz * 6), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
		end
	end
	part({ Name = "BellRoof", Size = Vector3.new(18, 1.2, 18), Position = top + Vector3.new(0, 16.6, 0), Color = ROOF, Material = Enum.Material.Slate, Parent = f })
	part({ Name = "BellRoof2", Size = Vector3.new(11, 2, 11), Position = top + Vector3.new(0, 18.2, 0), Color = ROOF, Material = Enum.Material.Slate, Parent = f })
	crystal(top + Vector3.new(0, 22, 0), 2.4, GOLD, f)
	disc("BellBody", top + Vector3.new(0, 8, 0), 4.4, 8, BRONZE, Enum.Material.Metal, f, false)
	part({ Name = "BellCrown", Shape = Enum.PartType.Ball, Size = Vector3.new(7.6, 7.6, 7.6), Position = top + Vector3.new(0, 12, 0), Color = BRONZE, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
	disc("BellLip", top + Vector3.new(0, 4.2, 0), 4.9, 0.8, BRONZE:Lerp(GOLD, 0.4), Enum.Material.Metal, f, false)
	disc("BellBand", top + Vector3.new(0, 9.5, 0), 4.6, 0.5, GOLD, Enum.Material.Metal, f, false)
	part({ Name = "BellStriker", Shape = Enum.PartType.Cylinder, Size = Vector3.new(9, 1.2, 1.2), Position = top + Vector3.new(0, 8, -7.5), Color = WOOD, Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	local glow = part({ Name = "BellGlow", Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), Position = top + Vector3.new(0, 6, 0), Color = WARM, Material = Enum.Material.Neon, Transparency = 0.4, CanCollide = false, Parent = f })
	light(glow, WARM, 40, 2)
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + math.pi / 4
		brazier(at + Vector3.new(math.cos(a) * 26, 0, math.sin(a) * 26), 1.2, f)
	end
end

-- 거울 호수: 하늘을 비추는 둥근 호수. 디딤돌이 가운데 섬의 정자로 이어지고, 연잎이 떠 있다
function LANDMARK.mirrorlake(at: Vector3, f: Instance)
	local R = 72
	for k = 0, 47 do
		local a = k / 48 * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * (R + 2), 0.6, math.sin(a) * (R + 2))
		part({ Name = "LakeRim", Size = Vector3.new(3.4, 1.4, R * 0.14), CFrame = CFrame.lookAt(p, at + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = STONE, Material = Enum.Material.Granite, Parent = f })
	end
	local water = disc("MirrorWater", at + Vector3.new(0, 0.55, 0), R, 0.3, Color3.fromRGB(120, 165, 205), Enum.Material.Glass, f, false)
	water.Transparency = 0.05
	water.Reflectance = 0.55
	disc("LakeBed", at + Vector3.new(0, 0.2, 0), R, 0.3, Color3.fromRGB(40, 60, 80), Enum.Material.Slate, f, false)
	-- 가운데 섬과 정자
	disc("Isle", at + Vector3.new(0, 1, 0), 14, 1.4, Color3.fromRGB(110, 150, 95), Enum.Material.Grass, f)
	pavilion(at + Vector3.new(0, 1.7, 0), 8, 8, 11, Color3.fromRGB(60, 72, 100), f, Color3.fromRGB(170, 220, 255))
	-- 남쪽 기슭에서 섬까지 디딤돌
	for i = 0, 11 do
		local d = R + 4 - i * 5.2
		if d > 14 then
			local wob = math.sin(i * 1.3) * 3
			disc("SteppingStone", at + Vector3.new(wob, 0.9, d), 2.2, 0.8, Color3.fromRGB(160, 155, 145), Enum.Material.Slate, f)
		end
	end
	-- 연잎과 연꽃
	for k = 0, 21 do
		local a = k * 2.399
		local d = 22 + (k * 13 % 45)
		local p = at + Vector3.new(math.cos(a) * d, 0.75, math.sin(a) * d)
		if math.abs(p.X - at.X) > 6 or p.Z < at.Z then
			disc("LotusPad", p, 1.6 + (k % 3) * 0.4, 0.15, Color3.fromRGB(70, 140, 70), Enum.Material.Grass, f, false)
			if k % 3 == 0 then
				part({ Name = "Lotus", Shape = Enum.PartType.Ball, Size = Vector3.new(1.1, 0.9, 1.1), Position = p + Vector3.new(0.4, 0.5, 0), Color = Color3.fromRGB(255, 160, 200), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			end
		end
	end
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2 + math.pi / 8
		local p = at + Vector3.new(math.cos(a) * (R + 10), 0, math.sin(a) * (R + 10))
		stoneLantern(p, f, k % 2 == 0)
		tree(at + Vector3.new(math.cos(a + 0.2) * (R + 22), 0, math.sin(a + 0.2) * (R + 22)), 1.6, f, k % 3 == 0)
	end
end

-- 거신의 손: 땅에서 솟은 거대한 돌손이 빛나는 구슬을 받쳐 든다. 둘레는 갈라진 바위
function LANDMARK.gianthand(at: Vector3, f: Instance)
	local ROCKC = Color3.fromRGB(150, 145, 140)
	local cf = CFrame.new(at) * CFrame.Angles(0, math.rad(30), 0)
	local function blk(name: string, size: Vector3, c: CFrame)
		part({ Name = name, Size = size, CFrame = cf * c, Color = ROCKC, Material = Enum.Material.Granite, Parent = f })
	end
	blk("HandWrist", Vector3.new(16, 30, 12), CFrame.new(0, 12, 0) * CFrame.Angles(math.rad(-8), 0, 0))
	blk("HandPalm", Vector3.new(20, 18, 10), CFrame.new(0, 34, -3) * CFrame.Angles(math.rad(-25), 0, 0))
	for i, x in ipairs({ -7.2, -2.4, 2.4, 7.2 }) do
		local len = (i == 2 or i == 3) and 12 or 10
		local base = CFrame.new(x, 44, -7) * CFrame.Angles(math.rad(-40), 0, 0)
		blk("Finger", Vector3.new(4.2, len, 4.2), base * CFrame.new(0, len / 2, 0))
		blk("FingerTip", Vector3.new(3.8, len * 0.8, 3.8), base * CFrame.new(0, len, 0) * CFrame.Angles(math.rad(-35), 0, 0) * CFrame.new(0, len * 0.4, 0))
	end
	blk("Thumb", Vector3.new(5, 12, 5), CFrame.new(-11, 32, -6) * CFrame.Angles(math.rad(-30), 0, math.rad(50)))
	local orb = part({ Name = "HandOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(11, 11, 11), Position = (cf * CFrame.new(0, 47, -14)).Position, Color = Color3.fromRGB(140, 220, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	light(orb, Color3.fromRGB(140, 220, 255), 70, 3)
	emitter(orb, Color3.fromRGB(190, 240, 255), 16, 1.6, 6, 2)
	-- 갈라진 땅: 둘레로 기울어 솟은 바위판
	for k = 0, 13 do
		local a = k / 14 * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * 26, 0, math.sin(a) * 26)
		part({ Name = "CrackSlab", Size = Vector3.new(10, 2, 7), CFrame = CFrame.lookAt(p, at) * CFrame.Angles(math.rad(-22), 0, 0) + Vector3.new(0, 1, 0), Color = Color3.fromRGB(110, 105, 100), Material = Enum.Material.Slate, Parent = f })
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		crystal(at + Vector3.new(math.cos(a) * 38, 4, math.sin(a) * 38), 2, Color3.fromRGB(140, 220, 255), f)
	end
end

-- 별똥 분화구: 솟은 바위 테 안의 검게 탄 바닥, 한가운데 금이 간 운석이 아직 빛난다
function LANDMARK.crater(at: Vector3, f: Instance)
	local R = 60
	disc("CraterFloor", at + Vector3.new(0, 0.3, 0), R, 0.4, Color3.fromRGB(45, 38, 40), Enum.Material.Basalt, f)
	for k = 0, 35 do
		local a = k / 36 * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * R, 0, math.sin(a) * R)
		local h = 6 + (k * 7 % 5)
		part({ Name = "CraterRim", Size = Vector3.new(12, h, 9), CFrame = CFrame.lookAt(p + Vector3.new(0, h / 2 - 1, 0), at + Vector3.new(0, h / 2 - 1, 0)) * CFrame.Angles(math.rad(25), 0, 0), Color = Color3.fromRGB(95, 85, 82), Material = Enum.Material.Rock, Parent = f })
	end
	local meteor = part({ Name = "Meteor", Shape = Enum.PartType.Ball, Size = Vector3.new(22, 22, 22), Position = at + Vector3.new(0, 7, 0), Color = Color3.fromRGB(40, 32, 36), Material = Enum.Material.Basalt, Parent = f })
	local _ = meteor
	for k = 0, 9 do
		local a = k * 0.63
		local d = Vector3.new(math.cos(a), math.sin(k * 1.7) * 0.6, math.sin(a)).Unit
		part({ Name = "MeteorCrack", Size = Vector3.new(0.6, 0.6, 9), CFrame = CFrame.lookAt(at + Vector3.new(0, 7, 0) + d * 10.6, at + Vector3.new(0, 7, 0) + d * 10.6 + Vector3.new(-d.Z, 0.3, d.X)), Color = Color3.fromRGB(255, 120, 60), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	local core = part({ Name = "MeteorGlow", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), Position = at + Vector3.new(0, 19, 0), Color = Color3.fromRGB(255, 140, 70), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false, Parent = f })
	light(core, Color3.fromRGB(255, 130, 60), 60, 3)
	emitter(core, Color3.fromRGB(255, 160, 80), 10, 1.2, 5, 2.5)
	for k = 0, 15 do
		local a = k * 2.2
		local d = 18 + (k * 11 % 34)
		crystal(at + Vector3.new(math.cos(a) * d, 1.6, math.sin(a) * d), 1 + (k % 3) * 0.4, k % 2 == 0 and Color3.fromRGB(255, 150, 80) or Color3.fromRGB(190, 140, 255), f)
	end
end

-- 천 개의 계단: 구름 위 떠 있는 문까지 곧게 오르는 긴 돌계단, 계단참마다 석등
function LANDMARK.thousandsteps(at: Vector3, f: Instance)
	local face = Vector3.new(-at.X, 0, -at.Z).Unit -- 마을 쪽에서 오른다
	local cf = CFrame.lookAt(at, at - face)
	local steps = 44
	for i = 0, steps - 1 do
		local y = i * 1.4
		part({ Name = "Step", Size = Vector3.new(16, 1.4, 3.2), CFrame = cf * CFrame.new(0, y + 0.7, -i * 3.2), Color = i % 11 == 10 and STONE_DARK or STONE, Material = Enum.Material.Marble, Parent = f })
		if i % 11 == 10 then
			for _, sx in ipairs({ -1, 1 }) do
				stoneLantern((cf * CFrame.new(sx * 9.5, y + 1.4, -i * 3.2)).Position, f, sx == 1)
			end
		end
	end
	-- 계단 양옆의 난간
	local L = steps * 3.2
	local H = steps * 1.4
	for _, sx in ipairs({ -1, 1 }) do
		local p0 = cf * CFrame.new(sx * 8.6, 1.5, 0)
		local p1 = cf * CFrame.new(sx * 8.6, H + 1.5, -L)
		local mid = (p0.Position + p1.Position) / 2
		part({ Name = "StepRail", Size = Vector3.new(1.2, 1.4, (p1.Position - p0.Position).Magnitude), CFrame = CFrame.lookAt(mid, p1.Position), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = f })
	end
	-- 꼭대기 단과 떠 있는 문
	local topCf = cf * CFrame.new(0, H, -L - 12)
	part({ Name = "StepTop", Size = Vector3.new(30, 2, 24), CFrame = topCf * CFrame.new(0, 0, 0), Color = STONE, Material = Enum.Material.Marble, Parent = f })
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "SkyGatePost", Size = Vector3.new(2.4, 22, 2.4), CFrame = topCf * CFrame.new(sx * 9, 13, 0), Color = Color3.fromRGB(235, 235, 245), Material = Enum.Material.Marble, Parent = f })
		crystal((topCf * CFrame.new(sx * 9, 26, 0)).Position, 1.8, Color3.fromRGB(190, 220, 255), f)
	end
	part({ Name = "SkyGateBeam", Size = Vector3.new(26, 2, 3), CFrame = topCf * CFrame.new(0, 23, 0), Color = Color3.fromRGB(235, 235, 245), Material = Enum.Material.Marble, Parent = f })
	local veil = part({ Name = "SkyGateVeil", Size = Vector3.new(15.6, 20, 0.3), CFrame = topCf * CFrame.new(0, 12, 0), Color = Color3.fromRGB(190, 220, 255), Material = Enum.Material.ForceField, Transparency = 0.2, CanCollide = false, Parent = f })
	light(veil, Color3.fromRGB(190, 220, 255), 50, 2.5)
	-- 꼭대기 둘레의 구름
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local p = (topCf * CFrame.new(math.cos(a) * 26, -4 + (k % 3) * 2, math.sin(a) * 20)).Position
		part({ Name = "StepCloud", Shape = Enum.PartType.Ball, Size = Vector3.new(14, 7, 14), Position = p, Color = Color3.fromRGB(245, 247, 252), Material = Enum.Material.SmoothPlastic, Transparency = 0.25, CanCollide = false, Parent = f })
	end
end

-- 일월대: 해와 달의 단. 동쪽엔 금빛 해의 탑, 서쪽엔 은빛 달의 탑, 가운데 반은 금빛·반은 은빛인 단 위에 권존이 선다
function LANDMARK.sunmoon(at: Vector3, f: Instance)
	local m = Config.MASTERS.ilwol
	local center = m and Vector3.new(m.at.X, 0, m.at.Z) or at
	local top = m and m.at.Y or 6
	local DARK = Color3.fromRGB(58, 52, 66)
	local SUN = Color3.fromRGB(255, 190, 70)
	local MOON = Color3.fromRGB(205, 220, 255)
	cyl("SunMoonDais", center + Vector3.new(0, top / 2, 0), 32, top, DARK, Enum.Material.Slate, f)
	cyl("SunMoonDais2", center + Vector3.new(0, top + 0.05, 0), 24, 0.1, Color3.fromRGB(30, 26, 36), Enum.Material.Marble, f, false)
	-- 둘레 띠: 동쪽 반은 해, 서쪽 반은 달
	for k = 0, 35 do
		local a = k / 36 * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * 28, top + 0.12, math.sin(a) * 28)
		part({ Name = "SunMoonRim", Size = Vector3.new(1.2, 0.2, 5.2), CFrame = CFrame.lookAt(p, center + Vector3.new(0, top + 0.12, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = math.cos(a) >= 0 and SUN or MOON, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	-- 바닥 무늬: 해 쪽 빛살, 달 쪽 초승달
	for k = 0, 7 do
		local a = math.rad(-70 + k * 20)
		local p = center + Vector3.new(math.cos(a) * 12, top + 0.15, math.sin(a) * 12)
		part({ Name = "SunInlay", Size = Vector3.new(0.6, 0.1, 7), CFrame = CFrame.lookAt(p, center + Vector3.new(0, top + 0.15, 0)), Color = SUN, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		local b = math.rad(110 + k * 20)
		local q = center + Vector3.new(math.cos(b) * 12, top + 0.15, math.sin(b) * 12)
		part({ Name = "MoonInlay", Size = Vector3.new(4, 0.1, 0.8), CFrame = CFrame.lookAt(q, center + Vector3.new(0, top + 0.15, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = MOON, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	-- 오르는 계단 (남쪽)
	for i = 0, 3 do
		part({ Name = "SunMoonStep", Size = Vector3.new(18, (i + 1) * top / 4, 4), Position = center + Vector3.new(0, (i + 1) * top / 8, 44 - i * 4), Color = DARK, Material = Enum.Material.Slate, Parent = f })
	end
	-- 해의 탑 (동쪽)
	local sunAt = center + Vector3.new(70, 0, 0)
	part({ Name = "SunTower", Size = Vector3.new(9, 64, 9), Position = sunAt + Vector3.new(0, 32, 0), Color = DARK, Material = Enum.Material.Slate, Parent = f })
	cyl("SunTowerBand", sunAt + Vector3.new(0, 62, 0), 7, 2, SUN, Enum.Material.Neon, f, false)
	local sunBall = part({ Name = "SunOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(22, 22, 22), Position = sunAt + Vector3.new(0, 80, 0), Color = SUN, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	light(sunBall, SUN, 90, 4)
	emitter(sunBall, Color3.fromRGB(255, 220, 140), 18, 2.2, 10, 1.4)
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		local p = sunAt + Vector3.new(0, 80, 0) + Vector3.new(0, math.sin(a), math.cos(a)) * 17
		part({ Name = "SunRay", Size = Vector3.new(1, 1, k % 2 == 0 and 9 or 5), CFrame = CFrame.lookAt(p, sunAt + Vector3.new(0, 80, 0)), Color = Color3.fromRGB(255, 225, 150), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	-- 달의 탑 (서쪽): 은빛 초승달
	local moonAt = center + Vector3.new(-70, 0, 0)
	part({ Name = "MoonTower", Size = Vector3.new(9, 64, 9), Position = moonAt + Vector3.new(0, 32, 0), Color = DARK, Material = Enum.Material.Slate, Parent = f })
	cyl("MoonTowerBand", moonAt + Vector3.new(0, 62, 0), 7, 2, MOON, Enum.Material.Neon, f, false)
	local mc = moonAt + Vector3.new(0, 80, 0)
	for k = 0, 17 do
		local a = math.rad(-120 + k * 13.5)
		local p = mc + Vector3.new(0, math.sin(a), math.cos(a)) * 12
		local thick = 1.2 + 3.2 * (1 - math.abs(k - 8.5) / 8.5) -- 가운데가 가장 두껍다
		part({ Name = "MoonArc", Size = Vector3.new(2.5, math.max(1.2, thick), 4.6), CFrame = CFrame.lookAt(p, mc) * CFrame.Angles(math.rad(90), 0, 0), Color = MOON, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	local moonGlow = part({ Name = "MoonGlow", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), Position = mc, Color = MOON, Material = Enum.Material.Neon, Transparency = 1, CanCollide = false, Parent = f })
	light(moonGlow, MOON, 90, 3)
	-- 두 탑을 잇는 빛줄기 (단 위 하늘에서 만난다)
	for _, from in ipairs({ sunAt, moonAt }) do
		local a0 = from + Vector3.new(0, 80, 0)
		local b0 = center + Vector3.new(0, 70, 0)
		part({ Name = "SunMoonLink", Size = Vector3.new(0.6, 0.6, (b0 - a0).Magnitude), CFrame = CFrame.lookAt((a0 + b0) / 2, b0), Color = from == sunAt and SUN or MOON, Material = Enum.Material.Neon, Transparency = 0.4, CanCollide = false, Parent = f })
	end
	local meet = part({ Name = "EclipseOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(10, 10, 10), Position = center + Vector3.new(0, 70, 0), Color = Color3.fromRGB(12, 8, 16), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
	local corona = cyl("EclipseCorona", center + Vector3.new(0, 70, 0), 7.5, 0.4, Color3.fromRGB(255, 235, 180), Enum.Material.Neon, f, false)
	corona.CFrame = CFrame.new(center + Vector3.new(0, 70, 0)) * CFrame.Angles(0, math.rad(90), 0)
	local _ = meet
	-- 단 둘레의 화로 여덟 (반은 금불, 반은 푸른 불)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2 + math.pi / 8
		local p = center + Vector3.new(math.cos(a) * 40, 0, math.sin(a) * 40)
		part({ Name = "SunMoonPost", Size = Vector3.new(2.5, 9, 2.5), Position = p + Vector3.new(0, 4.5, 0), Color = DARK, Material = Enum.Material.Slate, Parent = f })
		crystal(p + Vector3.new(0, 11, 0), 1.4, math.cos(a) >= 0 and SUN or MOON, f)
	end
end

function LANDMARK.skyspire(at: Vector3, f: Instance)
	local MARBLE = Color3.fromRGB(240, 242, 250)
	local STAR = Color3.fromRGB(150, 205, 255)
	local h = 0
	for i = 0, 13 do
		local r = 40 - i * 2.5
		local seg = 30
		cyl("SpireTier", at + Vector3.new(0, h + seg / 2, 0), r, seg, MARBLE:Lerp(Color3.fromRGB(210, 220, 245), i / 14), Enum.Material.Marble, f)
		cyl("SpireBand", at + Vector3.new(0, h + seg, 0), r + 1.2, 1.4, i % 3 == 0 and GOLD or STAR, Enum.Material.Neon, f, false)
		h += seg
	end
	local crown = part({ Name = "SpireStar", Shape = Enum.PartType.Ball, Size = Vector3.new(16, 16, 16), Position = at + Vector3.new(0, h + 10, 0), Color = Color3.fromRGB(255, 250, 230), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	light(crown, Color3.fromRGB(255, 245, 220), 120, 5)
	part({ Name = "SkyBeam", Size = Vector3.new(6, 900, 6), Position = at + Vector3.new(0, h + 460, 0), Color = Color3.fromRGB(230, 240, 255), Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, Parent = f })
	-- 봉우리를 도는 기운 고리 셋
	for j = 0, 2 do
		local c = at + Vector3.new(0, 120 + j * 110, 0)
		local rr = 90 - j * 20
		for k = 0, 31 do
			local a = k / 32 * math.pi * 2
			part({ Name = "SpireRing", Size = Vector3.new(2, 2, rr * 0.22), CFrame = CFrame.lookAt(c + Vector3.new(math.cos(a) * rr, math.sin(a * 2 + j) * 6, math.sin(a) * rr), c) * CFrame.Angles(0, math.rad(90), 0), Color = k % 4 == 0 and GOLD or STAR, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		end
	end
	-- 떠 있는 섬들
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2 + 0.2
		local d = rng:NextNumber(150, 300)
		local p = at + Vector3.new(math.cos(a) * d, rng:NextNumber(60, 220), math.sin(a) * d)
		local s = rng:NextNumber(14, 30)
		part({ Name = "IsleRock", Size = Vector3.new(s, s * 0.8, s), CFrame = CFrame.new(p - Vector3.new(0, s * 0.4, 0)) * CFrame.Angles(math.rad(180), rng:NextNumber(0, 6), 0), Color = Color3.fromRGB(150, 145, 160), Material = Enum.Material.Slate, Parent = f })
		part({ Name = "IsleTop", Size = Vector3.new(s * 1.05, 1.5, s * 1.05), Position = p, Color = Color3.fromRGB(150, 200, 140), Material = Enum.Material.Grass, Parent = f })
		crystal(p + Vector3.new(0, 4, 0), 1.6, STAR, f)
	end
	-- 시원자의 단 (남쪽 앞)
	local m = Config.MASTERS.taecho
	if m then
		local d = Vector3.new(m.at.X, 0, m.at.Z)
		cyl("OriginDais", d + Vector3.new(0, m.at.Y / 2, 0), 34, m.at.Y, MARBLE, Enum.Material.Marble, f)
		cyl("OriginRing", d + Vector3.new(0, m.at.Y + 0.06, 0), 26, 0.1, GOLD, Enum.Material.Neon, f, false).Transparency = 0.3
		cyl("OriginStar", d + Vector3.new(0, m.at.Y + 0.08, 0), 14, 0.1, STAR, Enum.Material.Neon, f, false).Transparency = 0.4
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			local p = d + Vector3.new(math.cos(a) * 30, 0, math.sin(a) * 30)
			part({ Name = "OriginPillar", Size = Vector3.new(3, 16, 3), Position = p + Vector3.new(0, m.at.Y + 8, 0), Color = MARBLE, Material = Enum.Material.Marble, Parent = f })
			crystal(p + Vector3.new(0, m.at.Y + 18, 0), 1.2, k % 2 == 0 and GOLD or STAR, f)
		end
		for i = 0, 3 do
			part({ Name = "DaisStep", Size = Vector3.new(16, (i + 1) * m.at.Y / 4, 4), Position = d + Vector3.new(0, (i + 1) * m.at.Y / 8, 38 - i * 4), Color = MARBLE, Material = Enum.Material.Marble, Parent = f })
		end
	end
end

-- 혈월곡: 붉은 바위 가시, 핏빛 수정, 두목의 단
local function lair(r: any, f: Instance)
	local c = r.center
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
		local d = rng:NextNumber(150, 175)
		local h = rng:NextNumber(30, 70)
		local p = Vector3.new(c.X + math.cos(a) * d, h / 2 - 2, c.Z + math.sin(a) * d)
		if not nearRoad(p, 20) then
			part({ Name = "LairSpire", Size = Vector3.new(rng:NextNumber(8, 14), h, rng:NextNumber(8, 14)), CFrame = CFrame.new(p) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 6), rng:NextNumber(-0.2, 0.2)), Color = Color3.fromRGB(70, 35, 38), Material = Enum.Material.Rock, Parent = f })
		end
	end
	local bossAt = r.boss.at
	disc("LairArena", bossAt + Vector3.new(0, 0.6, 0), 34, 1.2, Color3.fromRGB(60, 40, 42), Enum.Material.Slate, f)
	disc("LairRune", bossAt + Vector3.new(0, 1.25, 0), 26, 0.1, Color3.fromRGB(200, 40, 40), Enum.Material.Neon, f, false).Transparency = 0.5
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local p = bossAt + Vector3.new(math.cos(a) * 30, 0, math.sin(a) * 30)
		part({ Name = "LairPillar", Size = Vector3.new(3, 16, 3), Position = p + Vector3.new(0, 8, 0), Color = Color3.fromRGB(50, 30, 32), Material = Enum.Material.Slate, Parent = f })
		crystal(p + Vector3.new(0, 20, 0), 2.6, Color3.fromRGB(255, 50, 50), f)
		banner(p + Vector3.new(4, 0, 0), 12, Color3.fromRGB(140, 20, 25), f)
	end
	for _ = 1, 14 do
		local p = c + Vector3.new(rng:NextNumber(-150, 150), 0, rng:NextNumber(-150, 150))
		if (p - bossAt).Magnitude > 45 and not nearRoad(p, 14) then
			local h = rng:NextNumber(4, 12)
			part({ Name = "BloodCrystal", Size = Vector3.new(h * 0.3, h, h * 0.3), CFrame = CFrame.new(p + Vector3.new(0, h * 0.4, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), Color = Color3.fromRGB(220, 40, 50), Material = Enum.Material.Neon, Transparency = 0.15, Parent = f })
		end
	end
end

local function landmarks()
	for _, lm in ipairs(Config.Landmarks) do
		local builder = LANDMARK[lm.id]
		if builder then
			local f = Instance.new("Folder")
			f.Name = "Landmark_" .. lm.id
			f.Parent = folder
			local ok, err = pcall(builder, lm.at, f)
			if not ok then
				warn("[권왕] 랜드마크 오류:", lm.id, err)
			end
		end
	end
	for _, r in ipairs(Config.Regions) do
		if r.id == "lair" then
			local f = Instance.new("Folder")
			f.Name = "Lair"
			f.Parent = folder
			local ok, err = pcall(lair, r, f)
			if not ok then
				warn("[권왕] 혈월곡 오류:", err)
			end
		end
	end
end

------------------------------------------------------------------------
-- 바깥 다섯 땅 (설산, 늪, 황야, 해안, 혈교 본산)
------------------------------------------------------------------------
local function regionById(id: string): any
	for _, r in ipairs(Config.Regions) do
		if r.id == id then
			return r
		end
	end
	return nil
end

local function randIn(r: any, margin: number): Vector3
	return r.center + Vector3.new(rng:NextNumber(-r.size.X / 2 + margin, r.size.X / 2 - margin), 0, rng:NextNumber(-r.size.Z / 2 + margin, r.size.Z / 2 - margin))
end

local function clearOf(p: Vector3, r: any): boolean
	if nearRoad(p, 18) then
		return false
	end
	for _, camp in ipairs(r.camps or {}) do
		if (p - camp.at).Magnitude < 35 then
			return false
		end
	end
	if r.boss and (p - r.boss.at).Magnitude < 60 then
		return false
	end
	return true
end

-- 눈 덮인 침엽수 (층층이 줄어드는 가지)
local function pine(at: Vector3, s: number, parent: Instance, snowy: boolean)
	part({ Name = "PineTrunk", Size = Vector3.new(1.4, 8, 1.4) * s, Position = at + Vector3.new(0, 4 * s, 0), Color = Color3.fromRGB(80, 55, 40), Material = Enum.Material.Wood, Parent = parent })
	for i = 0, 3 do
		local w = (9 - i * 2) * s
		part({ Name = "PineLayer", Size = Vector3.new(w, 2.6 * s, w), CFrame = CFrame.new(at + Vector3.new(0, (5 + i * 2.6) * s, 0)) * CFrame.Angles(0, math.rad(i * 25), 0), Color = Color3.fromRGB(40, 85, 55), Material = Enum.Material.Grass, CanCollide = false, Parent = parent })
		if snowy then
			part({ Name = "PineSnow", Size = Vector3.new(w * 0.9, 0.5 * s, w * 0.9), CFrame = CFrame.new(at + Vector3.new(0, (6.4 + i * 2.6) * s, 0)) * CFrame.Angles(0, math.rad(i * 25), 0), Color = Color3.fromRGB(245, 248, 252), Material = Enum.Material.Snow, CanCollide = false, Parent = parent })
		end
	end
end

local function deadTree(at: Vector3, s: number, parent: Instance)
	part({ Name = "DeadTrunk", Size = Vector3.new(1.2, 12, 1.2) * s, CFrame = CFrame.new(at + Vector3.new(0, 6 * s, 0)) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, rng:NextNumber(-0.15, 0.15)), Color = Color3.fromRGB(60, 55, 45), Material = Enum.Material.Wood, Parent = parent })
	for k = 1, 3 do
		local a = rng:NextNumber(0, math.pi * 2)
		local from = at + Vector3.new(0, (6 + k * 2) * s, 0)
		local to = from + Vector3.new(math.cos(a) * 5 * s, 2.5 * s, math.sin(a) * 5 * s)
		part({ Name = "DeadBranch", Size = Vector3.new(0.5 * s, 0.5 * s, (to - from).Magnitude), CFrame = CFrame.lookAt((from + to) / 2, to), Color = Color3.fromRGB(60, 55, 45), Material = Enum.Material.Wood, CanCollide = false, Parent = parent })
	end
end

local OUTER: { [string]: (r: any, f: Instance) -> () } = {}

function OUTER.snow(r: any, f: Instance)
	for _ = 1, 70 do
		local p = randIn(r, 20)
		if clearOf(p, r) then
			pine(p, rng:NextNumber(1.2, 2.2), f, true)
		end
	end
	for _ = 1, 22 do
		local p = randIn(r, 20)
		if clearOf(p, r) then
			local h = rng:NextNumber(6, 18)
			part({ Name = "IceSpike", Size = Vector3.new(h * 0.3, h, h * 0.3), CFrame = CFrame.new(p + Vector3.new(0, h * 0.4, 0)) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(0, 6), rng:NextNumber(-0.25, 0.25)), Color = Color3.fromRGB(170, 220, 245), Material = Enum.Material.Glass, Transparency = 0.25, Parent = f })
		end
	end
	disc("FrozenLake", Vector3.new(r.center.X + 300, 0.3, r.center.Z + 120), 70, 0.4, Color3.fromRGB(190, 225, 245), Enum.Material.Ice, f)
	-- 빙마의 얼음 옥좌
	local b = r.boss.at
	disc("IceThrone", b + Vector3.new(0, 0.6, 0), 34, 1.2, Color3.fromRGB(200, 230, 250), Enum.Material.Ice, f)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local p = b + Vector3.new(math.cos(a) * 30, 0, math.sin(a) * 30)
		part({ Name = "IcePillar", Size = Vector3.new(3, 18, 3), CFrame = CFrame.new(p + Vector3.new(0, 9, 0)) * CFrame.Angles(0, a, 0.1), Color = Color3.fromRGB(170, 215, 245), Material = Enum.Material.Glass, Transparency = 0.2, Parent = f })
	end
	crystal(b + Vector3.new(0, 26, 0), 5, Color3.fromRGB(160, 220, 255), f)
end

function OUTER.swamp(r: any, f: Instance)
	for _ = 1, 26 do
		local p = randIn(r, 30)
		if clearOf(p, r) then
			disc("BogPool", p + Vector3.new(0, 0.35, 0), rng:NextNumber(10, 26), 0.3, Color3.fromRGB(45, 70, 50), Enum.Material.Glass, f, false).Transparency = 0.2
		end
	end
	for _ = 1, 55 do
		local p = randIn(r, 20)
		if clearOf(p, r) then
			deadTree(p, rng:NextNumber(1, 1.8), f)
		end
	end
	-- 자욱한 독안개
	for _ = 1, 8 do
		local fog = part({ Name = "SwampFog", Size = Vector3.new(120, 4, 120), Position = randIn(r, 60) + Vector3.new(0, 3, 0), Transparency = 1, CanCollide = false, Parent = f })
		local e = Instance.new("ParticleEmitter")
		e.Rate = 6
		e.Color = ColorSequence.new(Color3.fromRGB(140, 180, 110))
		e.Size = NumberSequence.new(14, 22)
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.8), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(8, 12)
		e.Speed = NumberRange.new(0.5, 1.5)
		e.Parent = fog
	end
	-- 무너진 사당 (비급 조각이 있다)
	local ruin = Vector3.new(320, 0, 1700)
	part({ Name = "RuinBase", Size = Vector3.new(26, 1.2, 26), Position = ruin + Vector3.new(0, 0.6, 0), Color = Color3.fromRGB(90, 95, 80), Material = Enum.Material.Cobblestone, Parent = f })
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + 0.6
		local h = rng:NextNumber(5, 12)
		part({ Name = "RuinPillar", Size = Vector3.new(2, h, 2), Position = ruin + Vector3.new(math.cos(a) * 10, h / 2, math.sin(a) * 10), Color = Color3.fromRGB(100, 105, 90), Material = Enum.Material.Cobblestone, Parent = f })
	end
end

function OUTER.badlands(r: any, f: Instance)
	for _ = 1, 18 do
		local p = randIn(r, 50)
		if clearOf(p, r) then
			local h = rng:NextNumber(25, 70)
			local w = rng:NextNumber(30, 60)
			part({ Name = "Mesa", Size = Vector3.new(w, h, w * rng:NextNumber(0.7, 1.3)), CFrame = CFrame.new(p + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Color = Color3.fromRGB(175, 95, 60):Lerp(Color3.fromRGB(210, 140, 90), rng:NextNumber()), Material = Enum.Material.Sand, Parent = f })
			part({ Name = "MesaTop", Size = Vector3.new(w * 1.05, 3, w * 1.05), Position = p + Vector3.new(0, h + 1.5, 0), Color = Color3.fromRGB(150, 80, 50), Material = Enum.Material.Slate, Parent = f })
		end
	end
	for _ = 1, 40 do
		local p = randIn(r, 20)
		if clearOf(p, r) then
			local h = rng:NextNumber(4, 12)
			part({ Name = "RockPillar", Size = Vector3.new(h * 0.35, h, h * 0.35), CFrame = CFrame.new(p + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), rng:NextNumber(-0.15, 0.15)), Color = Color3.fromRGB(160, 90, 55), Material = Enum.Material.Rock, Parent = f })
		end
	end
end

function OUTER.coast(r: any, f: Instance)
	-- 서쪽은 바다
	local W = Config.WORLD_HALF
	local seaX = r.center.X - r.size.X / 2 - 160
	for k = -2, 2 do
		part({ Name = "Sea", Size = Vector3.new(320, 1, 960), Position = Vector3.new(seaX, -0.4, k * 960), Color = Color3.fromRGB(40, 100, 150), Material = Enum.Material.Glass, Transparency = 0.15, CanCollide = false, Parent = f })
	end
	local _ = W
	-- 바다 쪽 벼랑
	for k = -12, 12 do
		local h = rng:NextNumber(18, 40)
		part({ Name = "SeaCliff", Size = Vector3.new(30, h, 52), CFrame = CFrame.new(r.center.X - r.size.X / 2 + 10, h / 2 - 8, k * 48) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0), Color = Color3.fromRGB(120, 115, 105), Material = Enum.Material.Rock, Parent = f })
	end
	-- 난파선
	local wreck = Vector3.new(-1880, 0, -60)
	part({ Name = "WreckHull", Size = Vector3.new(14, 8, 50), CFrame = CFrame.new(wreck + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0.4, math.rad(18)), Color = Color3.fromRGB(90, 60, 40), Material = Enum.Material.WoodPlanks, Parent = f })
	part({ Name = "WreckMast", Size = Vector3.new(1.6, 30, 1.6), CFrame = CFrame.new(wreck + Vector3.new(2, 14, 4)) * CFrame.Angles(0.2, 0, 0.5), Color = Color3.fromRGB(80, 55, 35), Material = Enum.Material.Wood, Parent = f })
	part({ Name = "WreckSail", Size = Vector3.new(0.2, 14, 16), CFrame = CFrame.new(wreck + Vector3.new(6, 18, 4)) * CFrame.Angles(0.2, 0, 0.5), Color = Color3.fromRGB(200, 190, 160), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
	for _ = 1, 30 do
		local p = randIn(r, 30)
		if clearOf(p, r) and p.X > r.center.X - r.size.X / 2 + 50 then
			rock(p, rng:NextNumber(3, 9), f, Color3.fromRGB(140, 135, 120))
		end
	end
end

function OUTER.cult(r: any, f: Instance)
	local c = r.center
	local half = 260
	-- 붉은 성벽과 정문
	for _, side in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		for _, seg in ipairs({ -1, 1 }) do
			local len = half - 16
			local along = seg * (16 + len / 2)
			local pos = side[1] ~= 0 and Vector3.new(c.X + side[1] * half, 9, c.Z + along) or Vector3.new(c.X + along, 9, c.Z + side[2] * half)
			local size = side[1] ~= 0 and Vector3.new(6, 18, len) or Vector3.new(len, 18, 6)
			part({ Name = "CultWall", Size = size, Position = pos, Color = Color3.fromRGB(70, 25, 28), Material = Enum.Material.Slate, Parent = f })
			part({ Name = "CultWallTrim", Size = size + Vector3.new(0.4, -16, 0.4), Position = pos + Vector3.new(0, 9.5, 0), Color = Color3.fromRGB(160, 30, 40), Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false, Parent = f })
		end
	end
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			spire(Vector3.new(c.X + sx * half, 0, c.Z + sz * half), 3, 7, Color3.fromRGB(255, 50, 60), f)
		end
	end
	monumentGate(Vector3.new(c.X, 0, c.Z + half + 10), 0, f, "혈교 본산", Color3.fromRGB(230, 40, 50))
	-- 혈마의 제단
	local b = r.boss.at
	disc("BloodAltar", b + Vector3.new(0, 1, 0), 38, 2, Color3.fromRGB(50, 20, 22), Enum.Material.Slate, f)
	disc("BloodRune", b + Vector3.new(0, 2.05, 0), 28, 0.1, Color3.fromRGB(220, 30, 40), Enum.Material.Neon, f, false).Transparency = 0.4
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local p = b + Vector3.new(math.cos(a) * 34, 0, math.sin(a) * 34)
		brazier(p, 1.6, f)
		banner(p + Vector3.new(3, 0, 0), 16, Color3.fromRGB(140, 15, 25), f)
	end
	for _ = 1, 20 do
		local p = randIn(r, 40)
		if clearOf(p, r) then
			local h = rng:NextNumber(5, 14)
			part({ Name = "BloodCrystal", Size = Vector3.new(h * 0.3, h, h * 0.3), CFrame = CFrame.new(p + Vector3.new(0, h * 0.4, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), Color = Color3.fromRGB(220, 40, 50), Material = Enum.Material.Neon, Transparency = 0.15, Parent = f })
		end
	end
end

-- 허공 균열: 갈라진 땅, 떠 있는 바위, 보랏빛 균열, 천마의 제단
function OUTER.rift(r: any, f: Instance)
	local c = r.center
	local VOID = Color3.fromRGB(150, 90, 255)
	-- 땅을 가르는 빛나는 균열
	for _ = 1, 14 do
		local p = randIn(r, 30)
		if clearOf(p, r) then
			local len = rng:NextNumber(30, 90)
			part({ Name = "RiftCrack", Size = Vector3.new(rng:NextNumber(1.5, 4), 0.3, len), CFrame = CFrame.new(p + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), Color = VOID, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		end
	end
	-- 하늘에 뜬 부서진 바위
	for _ = 1, 26 do
		local p = randIn(r, 20)
		local s = rng:NextNumber(6, 22)
		part({ Name = "FloatingRock", Size = Vector3.new(s, s * 0.7, s * 0.9), CFrame = CFrame.new(p + Vector3.new(0, rng:NextNumber(40, 120), 0)) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)), Color = Color3.fromRGB(60, 50, 75), Material = Enum.Material.Slate, Parent = f })
	end
	-- 보랏빛 수정 기둥
	for _ = 1, 18 do
		local p = randIn(r, 40)
		if clearOf(p, r) then
			local h = rng:NextNumber(8, 26)
			part({ Name = "VoidCrystal", Size = Vector3.new(h * 0.25, h, h * 0.25), CFrame = CFrame.new(p + Vector3.new(0, h * 0.4, 0)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)), Color = VOID, Material = Enum.Material.Neon, Transparency = 0.2, Parent = f })
		end
	end
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			spire(Vector3.new(c.X + sx * 270, 0, c.Z + sz * 270), 4, 7, VOID, f)
		end
	end
	monumentGate(Vector3.new(c.X + 360, 0, c.Z), math.rad(90), f, "허공 균열", VOID)
	-- 천마의 제단: 하늘로 열린 검은 고리
	local b = r.boss.at
	disc("RiftAltar", b + Vector3.new(0, 1, 0), 40, 2, Color3.fromRGB(30, 20, 45), Enum.Material.Slate, f)
	disc("RiftRune", b + Vector3.new(0, 2.05, 0), 30, 0.1, VOID, Enum.Material.Neon, f, false).Transparency = 0.35
	local ringC = b + Vector3.new(0, 70, 0)
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		part({ Name = "SkyRiftRing", Size = Vector3.new(4, 4, 9), CFrame = CFrame.lookAt(ringC + Vector3.new(math.cos(a) * 34, 0, math.sin(a) * 34), ringC) , Color = k % 2 == 0 and VOID or Color3.fromRGB(20, 10, 30), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	local hole = part({ Name = "SkyRiftCore", Shape = Enum.PartType.Ball, Size = Vector3.new(40, 40, 40), Position = ringC, Color = Color3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
	light(hole, VOID, 80, 3)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		brazier(b + Vector3.new(math.cos(a) * 36, 0, math.sin(a) * 36), 1.6, f)
	end
end

-- 화염산: 검은 현무암, 갈라진 용암 틈, 타 버린 나무, 연기 나는 구멍. 염제의 흑요석 제단
function OUTER.volcano(r: any, f: Instance)
	local LAVA = Color3.fromRGB(255, 110, 30)
	for _ = 1, 16 do
		local p = randIn(r, 30)
		if clearOf(p, r) then
			part({ Name = "LavaCrack", Size = Vector3.new(rng:NextNumber(1.5, 3.5), 0.3, rng:NextNumber(25, 70)), CFrame = CFrame.new(p + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), Color = LAVA, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		end
	end
	for _ = 1, 30 do
		local p = randIn(r, 20)
		if clearOf(p, r) then
			rock(p, rng:NextNumber(4, 12), f, Color3.fromRGB(45, 38, 36))
		end
	end
	for _ = 1, 20 do
		local p = randIn(r, 20)
		if clearOf(p, r) then
			deadTree(p, rng:NextNumber(1, 1.8), f)
		end
	end
	for _ = 1, 8 do
		local p = randIn(r, 40)
		if clearOf(p, r) then
			local vent = cyl("SmokeVent", p + Vector3.new(0, 1, 0), 3, 2, Color3.fromRGB(40, 32, 30), Enum.Material.Basalt, f)
			emitter(vent, Color3.fromRGB(80, 75, 75), 6, 5, 8, 4)
		end
	end
	local b = r.boss.at
	disc("ObsidianAltar", b + Vector3.new(0, 1, 0), 42, 2, Color3.fromRGB(25, 20, 28), Enum.Material.Glass, f)
	disc("FireRune", b + Vector3.new(0, 2.05, 0), 32, 0.1, LAVA, Enum.Material.Neon, f, false).Transparency = 0.35
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		brazier(b + Vector3.new(math.cos(a) * 38, 0, math.sin(a) * 38), 1.8, f)
	end
	monumentGate(Vector3.new(r.center.X - r.size.X / 2 + 30, 0, r.center.Z + 100), math.rad(90), f, "화염산", LAVA)
end

-- 사왕릉: 모래 언덕, 무너진 기둥과 벽, 반쯤 묻힌 석상. 사왕의 뜰
function OUTER.tomb(r: any, f: Instance)
	local SAND = Color3.fromRGB(210, 182, 128)
	for _ = 1, 26 do
		local p = randIn(r, 30)
		if clearOf(p, r) then
			local s = rng:NextNumber(30, 70)
			part({ Name = "Dune", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * 0.35, s * 1.4), CFrame = CFrame.new(p - Vector3.new(0, s * 0.1, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Color = SAND, Material = Enum.Material.Sand, Parent = f })
		end
	end
	for _ = 1, 26 do
		local p = randIn(r, 30)
		if clearOf(p, r) then
			local h = rng:NextNumber(6, 22)
			part({ Name = "RuinColumn", Size = Vector3.new(3.5, h, 3.5), CFrame = CFrame.new(p + Vector3.new(0, h / 2 - 1, 0)) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, rng:NextNumber(-0.12, 0.12)), Color = Color3.fromRGB(200, 175, 125), Material = Enum.Material.Sandstone, Parent = f })
			if rng:NextNumber() < 0.4 then
				part({ Name = "FallenDrum", Size = Vector3.new(3.4, 3.4, 6), CFrame = CFrame.new(p + Vector3.new(4, 1.5, 3)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Color = Color3.fromRGB(195, 170, 120), Material = Enum.Material.Sandstone, Parent = f })
			end
		end
	end
	for _ = 1, 8 do
		local p = randIn(r, 40)
		if clearOf(p, r) then
			local w = rng:NextNumber(14, 30)
			part({ Name = "RuinWall", Size = Vector3.new(w, rng:NextNumber(5, 12), 2.5), CFrame = CFrame.new(p + Vector3.new(0, 3, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Color = Color3.fromRGB(190, 165, 115), Material = Enum.Material.Sandstone, Parent = f })
		end
	end
	local b = r.boss.at
	disc("RoyalCourt", b + Vector3.new(0, 0.8, 0), 44, 1.6, Color3.fromRGB(220, 195, 140), Enum.Material.Sandstone, f)
	disc("RoyalSeal", b + Vector3.new(0, 1.65, 0), 30, 0.1, GOLD, Enum.Material.Neon, f, false).Transparency = 0.45
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local p = b + Vector3.new(math.cos(a) * 46, 0, math.sin(a) * 46)
		part({ Name = "CourtPillar", Size = Vector3.new(4, 20, 4), Position = p + Vector3.new(0, 10, 0), Color = Color3.fromRGB(215, 190, 135), Material = Enum.Material.Sandstone, Parent = f })
		part({ Name = "PillarGold", Size = Vector3.new(4.6, 1.2, 4.6), Position = p + Vector3.new(0, 20.6, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
	end
end

-- 천외봉 운해: 발밑까지 내려온 구름, 흰 대리석 폐허, 빛의 기둥과 별 수정. 천문장의 하늘 문
function OUTER.skysea(r: any, f: Instance)
	local STAR = Color3.fromRGB(150, 205, 255)
	for _ = 1, 60 do
		local p = randIn(r, 10)
		if clearOf(p, r) then
			local s = rng:NextNumber(10, 26)
			part({ Name = "CloudPuff", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * 0.5, s), Position = p + Vector3.new(0, rng:NextNumber(-1, 3), 0), Color = Color3.fromRGB(250, 252, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.2, CanCollide = false, Parent = f })
		end
	end
	for _ = 1, 22 do
		local p = randIn(r, 30)
		if clearOf(p, r) then
			local h = rng:NextNumber(10, 28)
			part({ Name = "SkyColumn", Size = Vector3.new(3.5, h, 3.5), Position = p + Vector3.new(0, h / 2, 0), Color = Color3.fromRGB(240, 242, 250), Material = Enum.Material.Marble, Parent = f })
			part({ Name = "SkyCapital", Size = Vector3.new(5, 1.4, 5), Position = p + Vector3.new(0, h + 0.7, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
		end
	end
	for _ = 1, 16 do
		local p = randIn(r, 40)
		if clearOf(p, r) then
			crystal(p + Vector3.new(0, rng:NextNumber(3, 8), 0), rng:NextNumber(1.2, 2.4), STAR, f)
		end
	end
	for _ = 1, 6 do
		local p = randIn(r, 60)
		if clearOf(p, r) then
			part({ Name = "LightPillar", Size = Vector3.new(3, 140, 3), Position = p + Vector3.new(0, 70, 0), Color = Color3.fromRGB(235, 245, 255), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false, Parent = f })
		end
	end
	local b = r.boss.at
	disc("HeavenCourt", b + Vector3.new(0, 1, 0), 46, 2, Color3.fromRGB(245, 246, 252), Enum.Material.Marble, f)
	disc("HeavenRune", b + Vector3.new(0, 2.05, 0), 34, 0.1, STAR, Enum.Material.Neon, f, false).Transparency = 0.35
	monumentGate(b + Vector3.new(0, 0, 60), 0, f, "천외봉", STAR)
end

-- 숨은 사부의 자리: 세상 끝 구석, 구름이 땅에 닿는 작은 절벽 (표지도, 지도도 없다)
local function secretSite()
	local sm = Config.SECRET_MASTER
	if not sm then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "SecretSite"
	f.Parent = folder
	local at = Vector3.new(sm.at.X, 0, sm.at.Z)
	local STAR = Color3.fromRGB(180, 215, 255)
	disc("CloudFloor", at + Vector3.new(0, 0.6, 0), 34, 1.2, Color3.fromRGB(235, 240, 250), Enum.Material.SmoothPlastic, f)
	disc("StarCircle", at + Vector3.new(0, 1.25, 0), 12, 0.1, STAR, Enum.Material.Neon, f, false).Transparency = 0.4
	-- 구름 (흰 공을 겹쳐 둥실)
	for _ = 1, 40 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(18, 60)
		local s = rng:NextNumber(8, 18)
		part({ Name = "Cloud", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * 0.6, s), Position = at + Vector3.new(math.cos(a) * d, rng:NextNumber(0, 6), math.sin(a) * d), Color = Color3.fromRGB(245, 248, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.25, CanCollide = false, Parent = f })
	end
	-- 별을 매단 고목 하나
	part({ Name = "OldTree", Size = Vector3.new(3, 22, 3), Position = at + Vector3.new(14, 11, 6), Color = Color3.fromRGB(90, 70, 55), Material = Enum.Material.Wood, Parent = f })
	for k = 1, 9 do
		crystal(at + Vector3.new(14 + rng:NextNumber(-8, 8), 18 + rng:NextNumber(0, 10), 6 + rng:NextNumber(-8, 8)), 0.8, STAR, f)
		local _ = k
	end
	-- 노인이 앉는 바위
	part({ Name = "SitRock", Size = Vector3.new(6, 1.6, 6), Position = at + Vector3.new(0, 1.2, 0), Color = Color3.fromRGB(120, 120, 130), Material = Enum.Material.Slate, Parent = f })
end

local function outerLands()
	for id, builder in pairs(OUTER) do
		local r = regionById(id)
		if r then
			local f = Instance.new("Folder")
			f.Name = "Land_" .. id
			f.Parent = folder
			local ok, err = pcall(builder, r, f)
			if not ok then
				warn("[권왕] 바깥 땅 오류:", id, err)
			end
		end
	end
end

------------------------------------------------------------------------
-- 적의 진: 모닥불, 천막, 상자 (적이 뜬금없이 서 있지 않게)
------------------------------------------------------------------------
local function camps()
	local f = Instance.new("Folder")
	f.Name = "Camps"
	f.Parent = folder
	for _, r in ipairs(Config.Regions) do
		for _, camp in ipairs(r.camps or {}) do
			local c = camp.at
			local fire = part({ Name = "Campfire", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), Position = c + Vector3.new(0, 0.8, 0), Color = Color3.fromRGB(255, 140, 50), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			local flame = Instance.new("Fire")
			flame.Size = 5
			flame.Heat = 6
			flame.Parent = fire
			light(fire, Color3.fromRGB(255, 150, 70), 20, 1.5)
			for k = 0, 5 do
				local a = k / 6 * math.pi * 2
				part({ Name = "FireStone", Size = Vector3.new(1.2, 0.8, 1.2), Position = c + Vector3.new(math.cos(a) * 2, 0.4, math.sin(a) * 2), Color = Color3.fromRGB(110, 105, 100), Material = Enum.Material.Slate, Parent = f })
			end
			for k = 0, 1 do
				local a = rng:NextNumber(0, math.pi * 2)
				local p = c + Vector3.new(math.cos(a), 0, math.sin(a)) * 14
				if not nearRoad(p, 12) then
					part({ Name = "CampTent", Size = Vector3.new(9, 6.5, 8), CFrame = CFrame.new(p + Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, a, math.rad(45)), Color = Color3.fromRGB(130, 110, 85):Lerp(Color3.fromRGB(90, 60, 50), k * 0.5), Material = Enum.Material.Fabric, Parent = f })
				end
				local q = c + Vector3.new(math.cos(a + 1.5), 0, math.sin(a + 1.5)) * 8
				part({ Name = "Crate", Size = Vector3.new(2.6, 2.6, 2.6), CFrame = CFrame.new(q + Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0), Color = Color3.fromRGB(120, 85, 50), Material = Enum.Material.WoodPlanks, Parent = f })
			end
		end
	end
end

------------------------------------------------------------------------
-- 비급 조각 (외진 곳에 숨은 빛나는 두루마리)
------------------------------------------------------------------------
local function fragments(out: any)
	local f = Instance.new("Folder")
	f.Name = "Fragments"
	f.Parent = folder
	out.fragments = {}
	for i, frag in ipairs(Config.Fragments) do
		local at = frag.at
		local stand = part({ Name = "FragmentStand", Size = Vector3.new(2.4, 2, 2.4), Position = at + Vector3.new(0, 1, 0), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = f })
		local scroll = disc("FragmentScroll", at + Vector3.new(0, 2.6, 0), 0.5, 2.2, Color3.fromRGB(255, 225, 140), Enum.Material.Neon, f, false)
		light(scroll, Color3.fromRGB(255, 220, 140), 14, 1.5)
		local e = Instance.new("ParticleEmitter")
		e.Rate = 6
		e.Color = ColorSequence.new(Color3.fromRGB(255, 230, 150))
		e.LightEmission = 1
		e.Size = NumberSequence.new(0.3, 0)
		e.Speed = NumberRange.new(1, 3)
		e.Lifetime = NumberRange.new(1, 2)
		e.Parent = scroll
		table.insert(out.fragments, prompt(stand, "줍기", "비급 조각 " .. i, "Fragment"))
	end
end

------------------------------------------------------------------------
-- 땅의 높낮이 (로블록스 지형): 세상 끝을 두른 산맥과 들판의 언덕
------------------------------------------------------------------------
local function terrainHills()
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if not terrain then
		return
	end
	local W = Config.WORLD_HALF
	local function inRegion(p: Vector3, pad: number): boolean
		for _, r in ipairs(Config.Regions) do
			if not r.noGround and math.abs(p.X - r.center.X) < r.size.X / 2 + pad and math.abs(p.Z - r.center.Z) < r.size.Z / 2 + pad then
				return true
			end
		end
		for _, lm in ipairs(Config.Landmarks) do
			if (p - lm.at).Magnitude < 120 then
				return true
			end
		end
		local sm = Config.SECRET_MASTER
		if sm and Vector3.new(p.X - sm.at.X, 0, p.Z - sm.at.Z).Magnitude < 160 + pad then
			return true
		end
		return false
	end
	-- 세상 끝 산맥 (북쪽은 눈, 동쪽은 붉은 바위, 서쪽은 바다라 낮게)
	for k = 0, 59 do
		local a = k / 60 * math.pi * 2
		local p = Vector3.new(math.cos(a) * (W - 60), 0, math.sin(a) * (W - 60))
		-- 구석의 땅 (혈교 본산, 허공 균열, 숨은 사부)으로 가는 길은 산을 비운다
		local open = inRegion(p, 200)
		for _, corner in ipairs({ Vector3.new(1750, 0, -1750), Vector3.new(-1750, 0, -1750), Config.SECRET_MASTER and Config.SECRET_MASTER.at or Vector3.zero }) do
			if Vector3.new(p.X - corner.X, 0, p.Z - corner.Z).Magnitude < 700 then
				open = true
			end
		end
		if p.X > -W + 400 and not open then
			local rad = rng:NextNumber(140, 260)
			local mat = p.Z < -W * 0.5 and Enum.Material.Snow or (p.X > W * 0.5 and Enum.Material.Sandstone or Enum.Material.Rock)
			pcall(function()
				terrain:FillBall(p - Vector3.new(0, rad * 0.35, 0), rad, mat)
			end)
		end
	end
	-- 들판의 완만한 언덕
	local made = 0
	for _ = 1, 160 do
		if made >= 45 then
			break
		end
		local p = Vector3.new(rng:NextNumber(-W + 300, W - 300), 0, rng:NextNumber(-W + 300, W - 300))
		local rad = rng:NextNumber(40, 90)
		if not inRegion(p, rad + 20) and not nearRoad(p, rad + 25) then
			made += 1
			pcall(function()
				terrain:FillBall(p - Vector3.new(0, rad * 0.7, 0), rad, Enum.Material.Grass)
			end)
		end
	end
end

------------------------------------------------------------------------
-- 지역 이름 표지
------------------------------------------------------------------------
------------------------------------------------------------------------
-- 정갈한 강호: 길가의 석등과 가로수, 지역마다 낮은 돌테두리와 길이 드는 곳의 문루
------------------------------------------------------------------------
local VILLAGE_PAD = 200 -- 마을 성벽 둘레는 마을 것으로 둔다
local function inAnyRegion(p: Vector3, pad: number): boolean
	if math.abs(p.X) < VILLAGE_PAD + pad and math.abs(p.Z) < VILLAGE_PAD + pad then
		return true
	end
	for _, r in ipairs(Config.Regions) do
		if not r.noGround and math.abs(p.X - r.center.X) < r.size.X / 2 + pad and math.abs(p.Z - r.center.Z) < r.size.Z / 2 + pad then
			return true
		end
	end
	return false
end
local function nearFeature(p: Vector3, d: number): boolean
	for _, lm in ipairs(Config.Landmarks) do
		if (Vector3.new(p.X, 0, p.Z) - Vector3.new(lm.at.X, 0, lm.at.Z)).Magnitude < 90 + d then
			return true
		end
	end
	for _, r in ipairs(Config.Regions) do
		for _, camp in ipairs(r.camps or {}) do
			if (Vector3.new(p.X, 0, p.Z) - camp.at).Magnitude < 34 + d then
				return true
			end
		end
	end
	for _, m in pairs(Config.MASTERS) do
		if (Vector3.new(p.X, 0, p.Z) - Vector3.new(m.at.X, 0, m.at.Z)).Magnitude < 50 + d then
			return true
		end
	end
	for _, fr in ipairs(Config.Fragments) do
		if (Vector3.new(p.X, 0, p.Z) - Vector3.new(fr.at.X, 0, fr.at.Z)).Magnitude < 16 + d then
			return true
		end
	end
	return false
end

-- 길가: 70칸마다 석등 (양쪽 번갈아), 길 양쪽으로 가로수
local function roadside()
	local f = Instance.new("Folder")
	f.Name = "Roadside"
	f.Parent = folder
	local lit = 0
	for _, road in ipairs(Config.Roads) do
		for i = 1, #road - 1 do
			local a, b = road[i], road[i + 1]
			local len = (b - a).Magnitude
			if len > 40 then
				local dir = (b - a).Unit
				local perp = Vector3.new(-dir.Z, 0, dir.X)
				local n = math.max(1, math.floor(len / 70))
				for j = 1, n - 1 do
					local p = a + (b - a) * (j / n)
					local side = j % 2 == 0 and 1 or -1
					local lp = p + perp * 14 * side
					if not inAnyRegion(lp, 6) and not nearFeature(lp, 0) and not nearRoad(lp, 12) then
						lit += 1
						stoneLantern(lp, f, lit % 2 == 0 and lit <= 240)
					end
					-- 가로수: 석등과 엇갈려 길 양쪽에
					for _, sd in ipairs({ -1, 1 }) do
						local tp = p + dir * 35 + perp * 27 * sd
						if (tp - a):Dot(dir) < len - 20 and not inAnyRegion(tp, 10) and not nearFeature(tp, 10) and not nearRoad(tp, 22) then
							tree(tp, 1.45, f)
						end
					end
				end
			end
		end
	end
	-- 들판의 작은 숲 (흩뿌리지 않고, 몇 군데에 모아 심는다)
	local groves = {
		Vector3.new(-760, 0, 760), Vector3.new(760, 0, -760), Vector3.new(-1300, 0, 450), Vector3.new(1250, 0, -420),
		Vector3.new(700, 0, 1200), Vector3.new(-700, 0, -1200), Vector3.new(1100, 0, 1950), Vector3.new(-1900, 0, 1300),
		Vector3.new(2300, 0, 1500), Vector3.new(-2300, 0, -900), Vector3.new(950, 0, -1500), Vector3.new(-1000, 0, 1700),
		Vector3.new(2900, 0, 400), Vector3.new(-2800, 0, 600), Vector3.new(1500, 0, 2600), Vector3.new(-2500, 0, -1800),
	}
	for gi, c in ipairs(groves) do
		if not inAnyRegion(c, 40) and not nearFeature(c, 30) and not nearRoad(c, 40) then
			local n = 6 + gi % 3
			for k = 0, n - 1 do
				local a = k / n * math.pi * 2 + gi
				local p = c + Vector3.new(math.cos(a), 0, math.sin(a)) * (12 + (k % 2) * 8)
				tree(p, 1.3 + (k % 3) * 0.2, f, gi % 4 == 0)
			end
			tree(c, 2.1, f)
			rock(c + Vector3.new(9, 0, -6), 5, f)
		end
	end
end

-- 문루: 길이 지역으로 드는 곳. 붉은 칠 나무 기둥 둘, 두 겹 들보, 기와 지붕, 이름 현판, 석등 한 쌍
local function regionGate(at: Vector3, dir: Vector3, title: string, accent: Color3, parent: Instance)
	local cf = CFrame.lookAt(at, at + dir)
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "GateStone", Size = Vector3.new(3.4, 1.4, 3.4), CFrame = cf * CFrame.new(sx * 12.5, 0.7, 0), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = parent })
		part({ Name = "GatePost", Size = Vector3.new(2, 15, 2), CFrame = cf * CFrame.new(sx * 12.5, 8.4, 0), Color = GATE_RED, Material = Enum.Material.Wood, Parent = parent })
		part({ Name = "GatePostBand", Size = Vector3.new(2.3, 0.5, 2.3), CFrame = cf * CFrame.new(sx * 12.5, 3, 0), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = parent })
		stoneLantern((cf * CFrame.new(sx * 17, 0, -5)).Position, parent, true)
	end
	part({ Name = "GateBeam", Size = Vector3.new(30, 1.8, 2.4), CFrame = cf * CFrame.new(0, 15.6, 0), Color = GATE_RED, Material = Enum.Material.Wood, Parent = parent })
	part({ Name = "GateBeam2", Size = Vector3.new(26, 1, 1.6), CFrame = cf * CFrame.new(0, 12.6, 0), Color = GATE_RED, Material = Enum.Material.Wood, Parent = parent })
	part({ Name = "GateBeamTrim", Size = Vector3.new(30.2, 0.3, 2.6), CFrame = cf * CFrame.new(0, 14.6, 0), Color = accent, Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
	for _, sz in ipairs({ -1, 1 }) do
		part({ Name = "GateRoof", Size = Vector3.new(34, 0.7, 3.4), CFrame = cf * CFrame.new(0, 17.3, sz * 1.25) * CFrame.Angles(sz * math.rad(24), 0, 0), Color = ROOF, Material = Enum.Material.Slate, Parent = parent })
	end
	part({ Name = "GateRidge", Size = Vector3.new(35, 0.8, 0.9), CFrame = cf * CFrame.new(0, 18.1, 0), Color = ROOF:Lerp(Color3.new(0, 0, 0), 0.3), Material = Enum.Material.Slate, Parent = parent })
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "GateRidgeEnd", Size = Vector3.new(1, 1.6, 1), CFrame = cf * CFrame.new(sx * 17.3, 18.6, 0) * CFrame.Angles(0, 0, sx * math.rad(-25)), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = parent })
	end
	local plate = part({ Name = "GatePlate", Size = Vector3.new(12, 2.6, 0.4), CFrame = cf * CFrame.new(0, 10.6, 0), Color = Color3.fromRGB(30, 22, 16), Material = Enum.Material.Wood, CanCollide = false, Parent = parent })
	sign(plate, Enum.NormalId.Front, { { title, Color3.fromRGB(255, 220, 140), 1 } })
	sign(plate, Enum.NormalId.Back, { { title, Color3.fromRGB(255, 220, 140), 1 } })
end

-- 지역 테두리: 둘레에 낮은 돌 턱 (길이 지나는 곳은 비우고 문루), 네 모서리에 석등
local gatedRegions: { [string]: boolean } = {}
local function regionFrames()
	local f = Instance.new("Folder")
	f.Name = "RegionFrames"
	f.Parent = folder
	local gates: { Vector3 } = {}
	for _, r in ipairs(Config.Regions) do
		if r.id ~= "village" and not r.noGround then
			local x0, x1 = r.center.X - r.size.X / 2, r.center.X + r.size.X / 2
			local z0, z1 = r.center.Z - r.size.Z / 2, r.center.Z + r.size.Z / 2
			-- 네 변: { 고정축, 값, 범위 시작, 범위 끝 }
			local edges = { { "x", x0, z0, z1 }, { "x", x1, z0, z1 }, { "z", z0, x0, x1 }, { "z", z1, x0, x1 } }
			local accent = r.ground:Lerp(Color3.new(1, 1, 1), 0.45)
			for _, e in ipairs(edges) do
				local fixed, v, lo, hi = e[1], e[2], e[3], e[4]
				local cuts: { number } = {}
				for _, road in ipairs(Config.Roads) do
					for i = 1, #road - 1 do
						local a, b = road[i], road[i + 1]
						local av = fixed == "x" and a.X or a.Z
						local bv = fixed == "x" and b.X or b.Z
						if (av - v) * (bv - v) < 0 then
							local t = (v - av) / (bv - av)
							local along = fixed == "x" and (a.Z + (b.Z - a.Z) * t) or (a.X + (b.X - a.X) * t)
							if along > lo + 4 and along < hi - 4 then
								table.insert(cuts, along)
								local pos = fixed == "x" and Vector3.new(v, 0, along) or Vector3.new(along, 0, v)
								local dupe = false
								for _, g in ipairs(gates) do
									if (g - pos).Magnitude < 60 then
										dupe = true
									end
								end
								local nearVillage = math.abs(pos.X) < VILLAGE_PAD + 40 and math.abs(pos.Z) < VILLAGE_PAD + 40
								if not dupe and not nearVillage then
									table.insert(gates, pos)
									gatedRegions[r.id] = true
									local inward = Vector3.new(r.center.X - pos.X, 0, r.center.Z - pos.Z)
									local rd = (b - a).Unit
									if rd:Dot(inward) < 0 then
										rd = -rd
									end
									pcall(regionGate, pos, rd, r.name, accent, f)
								end
							end
						end
					end
				end
				table.sort(cuts)
				-- 길이 지나는 자리(폭 30)를 비우고 돌 턱을 놓는다
				local from = lo
				local spans: { { number } } = {}
				for _, c in ipairs(cuts) do
					table.insert(spans, { from, c - 15 })
					from = c + 15
				end
				table.insert(spans, { from, hi })
				for _, sp in ipairs(spans) do
					local l = sp[2] - sp[1]
					if l > 2 then
						local mid = (sp[1] + sp[2]) / 2
						local pos = fixed == "x" and Vector3.new(v, 0.55, mid) or Vector3.new(mid, 0.55, v)
						local size = fixed == "x" and Vector3.new(1.8, 0.9, l) or Vector3.new(l, 0.9, 1.8)
						part({ Name = "RegionCurb", Size = size, Position = pos, Color = Color3.fromRGB(150, 144, 132), Material = Enum.Material.Cobblestone, Parent = f })
					end
				end
			end
			for _, cx in ipairs({ x0, x1 }) do
				for _, cz in ipairs({ z0, z1 }) do
					stoneLantern(Vector3.new(cx, 0, cz), f, false)
				end
			end
		end
	end
end

local function regionSigns()
	for _, r in ipairs(Config.Regions) do
		-- 문루가 선 지역은 문루의 현판이 이름표 (따로 팻말을 세우지 않는다)
		if r.id ~= "village" and not r.noGround and not gatedRegions[r.id] then
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
		{ "랜드마크", landmarks },
		{ "바깥 땅", outerLands },
		{ "적의 진", camps },
		{ "비급 조각", function()
			fragments(out)
		end },
		{ "숨은 자리", secretSite },
		{ "지형", terrainHills },
		{ "지역 테두리", regionFrames },
		{ "길가", roadside },
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
