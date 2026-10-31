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
-- 3.0판: 한 바퀴 16분 그대로, 낮(6시~19시)이 10분 · 밤이 6분 (예전엔 반반 8분씩)
-- 3.2.5판: 밤은 2분으로 (어두워서 눈이 아프다). 한 바퀴 12분
local DAY_PART, NIGHT_PART = 10 * 60, 2 * 60
local DAY = DAY_PART + NIGHT_PART
local function phaseOf(hour: number): number
	local h = (hour - 6) % 24
	if h < 13 then
		return h / 13 * DAY_PART
	end
	return DAY_PART + (h - 13) / 11 * NIGHT_PART
end
local clockT0 = os.clock() - phaseOf(16.2)
local clockFrozen: number? = nil
function World.clockHour(): number
	if clockFrozen then
		return clockFrozen
	end
	local t = (os.clock() - clockT0) % DAY
	if t < DAY_PART then
		return (6 + 13 * t / DAY_PART) % 24
	end
	return (19 + 11 * (t - DAY_PART) / NIGHT_PART) % 24
end
function World.setClock(hour: number)
	hour = hour % 24
	if clockFrozen then
		clockFrozen = hour
	end
	clockT0 = os.clock() - phaseOf(hour)
	Lighting.ClockTime = hour
end
-- 3.1판 일월극변: cut 초 동안은 화면이 해와 달을 번갈아 띄우고 (서버는 시각을 건드리지 않는다), 그 뒤 dur 초 동안 세상이 황혼에 멈춘다
local twilightCut, twilightFrom, twilightUntil = 0, 0, 0
function World.twilight(cut: number, dur: number)
	local now = os.clock()
	if now >= twilightUntil then
		twilightCut = now
		twilightFrom = now + cut
	end
	twilightUntil = math.max(twilightUntil, now + cut + dur)
end
function World.twilightOn(): boolean
	return os.clock() < twilightUntil
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
	-- 낮과 밤: 한 바퀴 16분 (낮 10분 · 밤 6분). 밤에도 길이 보이게 바깥 빛을 조금 남긴다
	local baseAtmo, baseDecay, baseTint = atmo.Color, atmo.Decay, cc.TintColor
	local wasTwilight = false
	task.spawn(function()
		while true do
			local now = os.clock()
			if now < twilightUntil then
				-- 일월극변: 컷씬 동안은 낮·밤을 번갈아, 그 뒤엔 황혼에 멈춘다
				if now < twilightFrom then
					-- 컷씬: 낮과 밤이 점점 빨라지며 번갈아 (화면의 해·달과 같은 박자)
					local u = math.clamp((now - twilightCut) / math.max(0.1, twilightFrom - twilightCut), 0, 1)
					local beat = math.floor((u * u) * 12 * 1.6)
					Lighting.ClockTime = beat % 2 == 0 and 12.5 or 0.5
					task.wait(0.05)
					continue
				else
					wasTwilight = true
					Lighting.ClockTime = 18.25
					Lighting.OutdoorAmbient = Color3.fromRGB(190, 120, 150)
					Lighting.Brightness = 1.9
					atmo.Color = Color3.fromRGB(255, 165, 120)
					atmo.Decay = Color3.fromRGB(150, 70, 120)
					cc.TintColor = Color3.fromRGB(255, 214, 196)
				end
				task.wait(0.25)
				continue
			end
			if wasTwilight then
				wasTwilight = false
				atmo.Color = baseAtmo
				atmo.Decay = baseDecay
				cc.TintColor = baseTint
			end
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
-- 나무 (1.8판에 다듬음): 아래가 굵은 두 토막 줄기, 비스듬히 뻗은 가지 둘, 짙고 옅은 잎 덩이 다섯
local function tree(at: Vector3, s: number, parent: Instance, blossom: boolean?)
	local bark = Color3.fromRGB(90, 60, 40)
	local lean = rng:NextNumber(-0.08, 0.08)
	part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6 * s, 1.9 * s, 1.9 * s), CFrame = CFrame.new(at + Vector3.new(0, 3 * s, 0)) * CFrame.Angles(lean, 0, math.rad(90)), Color = bark, Material = Enum.Material.Wood, Parent = parent })
	part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5.5 * s, 1.3 * s, 1.3 * s), CFrame = CFrame.new(at + Vector3.new(0, 8 * s, lean * 4 * s)) * CFrame.Angles(lean * 2, 0, math.rad(90)), Color = bark, Material = Enum.Material.Wood, Parent = parent })
	-- 매화는 짙은 홍매와 흰 백매를 섞는다
	local leaf = blossom and (rng:NextNumber() < 0.6 and Color3.fromRGB(215, 55, 85) or Color3.fromRGB(250, 236, 240)) or Color3.fromRGB(70, 120, 60):Lerp(Color3.fromRGB(100, 150, 70), rng:NextNumber())
	local top = at + Vector3.new(0, 10 * s, 0)
	for k = 0, 1 do
		local a = rng:NextNumber(0, 6.28) + k * math.pi
		local to = top + Vector3.new(math.cos(a) * 3.5 * s, -1 * s, math.sin(a) * 3.5 * s)
		local from = at + Vector3.new(0, 7 * s, 0)
		part({ Name = "Branch", Size = Vector3.new(0.6 * s, 0.6 * s, (to - from).Magnitude), CFrame = CFrame.lookAt((from + to) / 2, to), Color = bark, Material = Enum.Material.Wood, CanCollide = false, Parent = parent })
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(4.5, 6) * s, Position = to + Vector3.new(0, 1.2 * s, 0), Color = leaf:Lerp(Color3.new(0, 0, 0), 0.12), Material = Enum.Material.LeafyGrass, CanCollide = false, Parent = parent })
	end
	for i = 1, 3 do
		part({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 0.85, 1) * (6 + i) * s,
			CFrame = CFrame.new(top + Vector3.new(rng:NextNumber(-2, 2) * s, (i - 1) * 1.8 * s, rng:NextNumber(-2, 2) * s)),
			Color = leaf:Lerp(Color3.new(1, 1, 1), (i - 1) * 0.06 + rng:NextNumber(0, 0.08)),
			Material = Enum.Material.LeafyGrass,
			CanCollide = false,
			Parent = parent,
		})
	end
end

-- 바위 (1.8판에 다듬음): 큰 돌에 작은 돌이 기대고, 윗면엔 가끔 이끼
local function rock(at: Vector3, s: number, parent: Instance, color: Color3?)
	local c = color or Color3.fromRGB(120, 115, 110)
	local main = part({
		Name = "Rock",
		Size = Vector3.new(rng:NextNumber(0.8, 1.3), rng:NextNumber(0.5, 0.9), rng:NextNumber(0.8, 1.3)) * s,
		CFrame = CFrame.new(at + Vector3.new(0, s * 0.3, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)),
		Color = c,
		Material = Enum.Material.Slate,
		Parent = parent,
	})
	part({ Name = "Rock", Size = main.Size * 0.5, CFrame = CFrame.new(at + Vector3.new(main.Size.X * 0.5, s * 0.15, rng:NextNumber(-0.3, 0.3) * s)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)), Color = c:Lerp(Color3.new(0, 0, 0), 0.1), Material = Enum.Material.Slate, Parent = parent })
	if s > 2.5 and rng:NextNumber() < 0.5 then
		part({ Name = "Moss", Size = Vector3.new(main.Size.X * 0.8, 0.25, main.Size.Z * 0.8), CFrame = main.CFrame * CFrame.new(0, main.Size.Y / 2, 0), Color = Color3.fromRGB(85, 120, 60), Material = Enum.Material.Grass, CanCollide = false, Parent = parent })
	end
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
	local n = math.ceil(W * 2 / 2000)
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
	local R = 235
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
	for _, z in ipairs({ -215, -185, -160, -135, -85, -40, 20, 140, 160, 190, 215 }) do
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
		-- 넓힌 마을의 바깥 둘레
		{ -205, -40 }, { -205, 50 }, { -205, 140 }, { 205, -40 }, { 205, 50 }, { 205, 140 },
		{ -120, 205 }, { -60, 210 }, { 60, 210 }, { 120, 205 },
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

	-- 3.3판: 비무대 자리에 배틀그라운드의 문 (메인 월드에서는 사람끼리 싸우지 않는다). 돌 단 위의 붉은 문과 빛의 막
	local ring = Config.RING
	local c = ring.center
	part({ Name = "BattleBase", Size = Vector3.new(30, 1.6, 18), Position = c + Vector3.new(0, 0.8, 0), Color = Color3.fromRGB(150, 140, 125), Material = Enum.Material.Granite, Parent = f })
	for i = 1, 2 do
		part({ Name = "BattleStep", Size = Vector3.new(16, 0.8, 3), Position = c + Vector3.new(0, 0.4 * i - 0.4 + 0.4, -10.5 - (2 - i) * 2.2), Color = Color3.fromRGB(135, 126, 112), Material = Enum.Material.Granite, Parent = f })
	end
	for _, x in ipairs({ -1, 1 }) do
		part({ Name = "BattlePost", Size = Vector3.new(2.4, 18, 2.4), Position = c + Vector3.new(x * 8, 10.6, 0), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
		part({ Name = "BattlePostFoot", Size = Vector3.new(3.4, 1.4, 3.4), Position = c + Vector3.new(x * 8, 2.3, 0), Color = Color3.fromRGB(60, 50, 40), Material = Enum.Material.Slate, Parent = f })
	end
	part({ Name = "BattleBeam", Size = Vector3.new(22, 1.8, 3), Position = c + Vector3.new(0, 20.2, 0), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
	part({ Name = "BattleBeam2", Size = Vector3.new(18, 1, 2), Position = c + Vector3.new(0, 17.4, 0), Color = Color3.fromRGB(60, 40, 30), Material = Enum.Material.Wood, Parent = f })
	local veil = part({ Name = "BattleVeil", Size = Vector3.new(13.6, 15, 0.4), Position = c + Vector3.new(0, 9.4, 0), Color = Color3.fromRGB(255, 120, 80), Material = Enum.Material.Neon, Transparency = 0.55, CanCollide = false, Parent = f })
	local glow = Instance.new("PointLight")
	glow.Range = 22
	glow.Brightness = 1.6
	glow.Color = Color3.fromRGB(255, 130, 90)
	glow.Parent = veil
	out.battle = prompt(veil, "들어가기", "⚔ 배틀그라운드 (사람끼리 겨룬다)", "BattleGate")
	out.battle.MaxActivationDistance = 16
	local board = part({ Name = "BattleSign", Size = Vector3.new(16, 5, 1), Position = c + Vector3.new(0, 24.4, 0), Color = Color3.fromRGB(40, 25, 20), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(board, Enum.NormalId.Front, { { "⚔ 배틀그라운드", Color3.fromRGB(255, 220, 140), 0.6 }, { "체력 200 · 모두 같은 힘", Color3.fromRGB(255, 255, 255), 0.4 } })
	sign(board, Enum.NormalId.Back, { { "⚔ 배틀그라운드", Color3.fromRGB(255, 220, 140), 0.6 }, { "체력 200 · 모두 같은 힘", Color3.fromRGB(255, 255, 255), 0.4 } })

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

	-- 천층탑 입구 (북서쪽 모퉁이): 층마다 좁아지는 칠층 탑, 문은 마을 가운데를 본다
	local tAt = Config.TOWER.enter
	local tcf = CFrame.lookAt(tAt, Vector3.new(0, 0, 0))
	part({ Name = "TowerPlinth", Size = Vector3.new(30, 2, 30), CFrame = tcf * CFrame.new(0, 1, 0), Color = STONE_DARK, Material = Enum.Material.Cobblestone, Parent = f })
	local y, w = 2, 22
	for i = 1, 7 do
		local h = i == 1 and 12 or 8
		part({ Name = "TowerStorey", Size = Vector3.new(w, h, w), CFrame = tcf * CFrame.new(0, y + h / 2, 0), Color = Color3.fromRGB(225, 215, 195), Material = Enum.Material.Plaster, Parent = f })
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				part({ Name = "TowerPost", Size = Vector3.new(1.2, h, 1.2), CFrame = tcf * CFrame.new(sx * w / 2, y + h / 2, sz * w / 2), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
			end
		end
		-- 층마다 빛나는 창과 내민 처마
		for k = 0, 3 do
			part({ Name = "TowerWindow", Size = Vector3.new(2.4, h * 0.45, 0.3), CFrame = tcf * CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(0, y + h * 0.55, -w / 2 - 0.1), Color = Color3.fromRGB(255, 200, 120), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		end
		part({ Name = "TowerEave", Size = Vector3.new(w + 6, 1, w + 6), CFrame = tcf * CFrame.new(0, y + h + 0.5, 0), Color = ROOF, Material = Enum.Material.Slate, Parent = f })
		part({ Name = "TowerEaveTrim", Size = Vector3.new(w + 6.4, 0.4, w + 6.4), CFrame = tcf * CFrame.new(0, y + h, 0), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
		y += h + 1
		w -= 2.4
	end
	disc("TowerFinial", tAt + Vector3.new(0, y + 4, 0), 0.6, 8, GOLD, Enum.Material.Metal, f)
	crystal(tAt + Vector3.new(0, y + 10, 0), 3, Color3.fromRGB(255, 190, 90), f)
	local tDoor = part({ Name = "TowerDoor", Size = Vector3.new(6, 9, 0.6), CFrame = tcf * CFrame.new(0, 6.5, -11.2), Color = Color3.fromRGB(60, 35, 25), Material = Enum.Material.WoodPlanks, Parent = f })
	local tBoard = part({ Name = "TowerSign", Size = Vector3.new(12, 3, 0.4), CFrame = tcf * CFrame.new(0, 12.5, -11.5), Color = Color3.fromRGB(40, 25, 20), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(tBoard, Enum.NormalId.Front, { { "🗼 천층탑", GOLD, 1 } })
	for _, sx in ipairs({ -1, 1 }) do
		brazier((tcf * CFrame.new(sx * 6, 2, -15)).Position, 1, f)
	end
	out.tower = prompt(tDoor, "탑에 오르기", "천층탑", "TowerEnter")

	-- 강호 순위표 (북동쪽 모퉁이): 세 개의 큰 판
	local bAt = Vector3.new(185, 0, -185)
	local toC = Vector3.new(-bAt.X, 0, -bAt.Z).Unit
	local side = Vector3.new(-toC.Z, 0, toC.X)
	part({ Name = "BoardPlinth", Size = Vector3.new(50, 1.2, 12), CFrame = CFrame.lookAt(bAt, bAt + toC) * CFrame.new(0, 0.6, 0), Color = STONE_DARK, Material = Enum.Material.Cobblestone, Parent = f })
	out.boards = {}
	for i, b in ipairs({ { "realm", "🏯 강호 고수", "총 능력치" }, { "pvp", "⚔ 배틀 처치", "배틀그라운드에서 쓰러뜨린 수" }, { "tower", "🗼 천층탑", "오른 가장 높은 층" } }) do
		local at = bAt + side * ((i - 2) * 16) + Vector3.new(0, 11, 0)
		local cf = CFrame.lookAt(at, at + toC)
		for _, sx in ipairs({ -1, 1 }) do
			part({ Name = "BoardPost", Size = Vector3.new(1.2, 21, 1.2), CFrame = cf * CFrame.new(sx * 7.2, -0.5, 0.4), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
		end
		part({ Name = "BoardRoof", Size = Vector3.new(17, 0.8, 3.4), CFrame = cf * CFrame.new(0, 10.3, 0.4), Color = ROOF, Material = Enum.Material.Slate, Parent = f })
		local lboard = part({ Name = "Leaderboard", Size = Vector3.new(14, 18, 0.6), CFrame = cf, Color = Color3.fromRGB(30, 22, 18), Material = Enum.Material.Wood, Parent = f })
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Board"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		gui.LightInfluence = 0.2
		gui.Parent = lboard
		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = gui
		local function row(name: string, text: string, h: number, color: Color3, order: number)
			local l = Instance.new("TextLabel")
			l.Name = name
			l.LayoutOrder = order
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromScale(1, h)
			l.Font = Enum.Font.GothamBold
			l.TextScaled = true
			l.TextColor3 = color
			l.TextStrokeTransparency = 0.5
			l.Text = text
			l.Parent = gui
		end
		row("Title", b[2], 0.1, GOLD, 0)
		row("Sub", b[3], 0.05, Color3.fromRGB(200, 190, 170), 1)
		for r = 1, 10 do
			row("Row" .. r, "", 0.085, r == 1 and Color3.fromRGB(255, 215, 90) or r <= 3 and Color3.fromRGB(230, 230, 240) or Color3.fromRGB(210, 200, 185), 1 + r)
		end
		out.boards[b[1]] = gui
	end
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
		elseif spot.kind == "geumjong" then
			-- 금종조: 나무 틀에 매단 큰 청동 종
			for _, x in ipairs({ -1, 1 }) do
				part({ Name = "BellFramePost", Size = Vector3.new(1, 11, 1), Position = at + Vector3.new(x * 4.2, 5.5, 0), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
			end
			part({ Name = "BellFrameBeam", Size = Vector3.new(10, 1, 1.2), Position = at + Vector3.new(0, 11.2, 0), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
			target = part({ Name = "BronzeBell", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4.5, 4.6, 4.6), CFrame = CFrame.new(at + Vector3.new(0, 8.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(160, 120, 60), Material = Enum.Material.Metal, Parent = f })
			disc("BellLip", at + Vector3.new(0, 5.9, 0), 2.7, 0.4, Color3.fromRGB(190, 150, 80), Enum.Material.Metal, f)
			part({ Name = "BellTop", Shape = Enum.PartType.Ball, Size = Vector3.new(3.4, 3.4, 3.4), Position = at + Vector3.new(0, 10.2, 0), Color = Color3.fromRGB(150, 110, 55), Material = Enum.Material.Metal, Parent = f })
			disc("BellMat", at + Vector3.new(0, 0.2, 0), 3.5, 0.4, Color3.fromRGB(120, 60, 50), Enum.Material.Fabric, f)
		elseif spot.kind == "cheongeun" then
			-- 천근추: 돌 받침 위의 거대한 쇳덩이와 손잡이
			part({ Name = "WeightBase", Size = Vector3.new(7, 0.8, 7), Position = at + Vector3.new(0, 0.4, 0), Color = STONE_DARK, Material = Enum.Material.Granite, Parent = f })
			target = part({ Name = "IronWeight", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.4, 5, 5), CFrame = CFrame.new(at + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(45, 45, 50), Material = Enum.Material.Metal, Parent = f })
			part({ Name = "WeightHandle", Size = Vector3.new(3.6, 0.6, 0.6), Position = at + Vector3.new(0, 5.2, 0), Color = Color3.fromRGB(80, 80, 90), Material = Enum.Material.Metal, Parent = f })
			for _, x in ipairs({ -1, 1 }) do
				part({ Name = "WeightHandlePost", Size = Vector3.new(0.6, 1.2, 0.6), Position = at + Vector3.new(x * 1.5, 4.6, 0), Color = Color3.fromRGB(80, 80, 90), Material = Enum.Material.Metal, Parent = f })
			end
			sign(part({ Name = "WeightMark", Size = Vector3.new(2.4, 1.2, 0.1), Position = at + Vector3.new(0, 2.5, -2.55), Color = Color3.fromRGB(45, 45, 50), Material = Enum.Material.Metal, CanCollide = false, Parent = f }), Enum.NormalId.Front, { { "千斤", GOLD, 1 } })
		elseif spot.kind == "jucheon" then
			-- 주천 운기: 태극 진 위의 방석, 머리 위에 도는 금빛 고리
			disc("TaegeukDisc", at + Vector3.new(0, 0.15, 0), 5, 0.3, Color3.fromRGB(240, 235, 225), Enum.Material.Marble, f)
			disc("TaegeukInner", at + Vector3.new(0, 0.2, 0), 4.2, 0.3, Color3.fromRGB(40, 35, 40), Enum.Material.Marble, f)
			target = part({ Name = "MeditationCushion", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 4, 4), CFrame = CFrame.new(at + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(200, 160, 60), Material = Enum.Material.Fabric, Parent = f })
			local ring = disc("ChiRing", at + Vector3.new(0, 8, 0), 3.4, 0.25, GOLD, Enum.Material.Neon, f, false)
			ring.Transparency = 0.3
			light(ring, GOLD, 16, 1.2)
		elseif spot.kind == "heogong" then
			-- 허공답보: 바닥에 둥근 받침, 그 위로 차례로 떠오르는 디딤돌 셋
			target = part({ Name = "StepBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 6, 6), CFrame = CFrame.new(at + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = STONE, Material = Enum.Material.Marble, Parent = f })
			for k = 1, 3 do
				local st = disc("FloatingStep", at + Vector3.new(math.cos(k * 2.1) * 3, 2 + k * 2.2, math.sin(k * 2.1) * 3), 1.4, 0.5, Color3.fromRGB(190, 200, 210), Enum.Material.Marble, f, false)
				local glow = disc("FloatingStepGlow", st.Position - Vector3.new(0, 0.3, 0), 1.5, 0.1, Color3.fromRGB(150, 220, 255), Enum.Material.Neon, f, false)
				glow.Transparency = 0.4
			end
		elseif spot.kind == "cheonsang" then
			-- 천상 수련: 구름 연꽃 받침과 떠 있는 수정
			for k = 0, 7 do
				local a = k / 8 * math.pi * 2
				part({ Name = "LotusPetal", Size = Vector3.new(2.2, 0.4, 3.4), CFrame = CFrame.new(at + Vector3.new(math.cos(a) * 3, 0.5, math.sin(a) * 3)) * CFrame.Angles(0, -a + math.pi / 2, math.rad(-20)), Color = Color3.fromRGB(255, 235, 245), Material = Enum.Material.SmoothPlastic, Parent = f })
			end
			target = part({ Name = "LotusSeat", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 4, 4), CFrame = CFrame.new(at + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(250, 250, 255), Material = Enum.Material.SmoothPlastic, Parent = f })
			crystal(at + Vector3.new(0, 9, 0), 1.8, Color3.fromRGB(150, 220, 255), f)
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
	-- 상급 수련장: 둘레의 깃발과 석등, 들어오는 문의 현판
	local dojo = Vector3.new(330, 0, -330)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2 + math.pi / 8
		banner(dojo + Vector3.new(math.cos(a) * 80, 0, math.sin(a) * 80), 14, k % 2 == 0 and Color3.fromRGB(170, 40, 35) or Color3.fromRGB(40, 70, 140), f)
		stoneLantern(dojo + Vector3.new(math.cos(a + 0.2) * 72, 0, math.sin(a + 0.2) * 72), f, true)
	end
	local toVillage = Vector3.new(-dojo.X, 0, -dojo.Z).Unit
	local gateAt = dojo + toVillage * 82
	local gcf = CFrame.lookAt(gateAt, gateAt + toVillage)
	for _, x in ipairs({ -1, 1 }) do
		part({ Name = "DojoGatePost", Size = Vector3.new(1.6, 14, 1.6), CFrame = gcf * CFrame.new(x * 8, 7, 0), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
	end
	part({ Name = "DojoGateBeam", Size = Vector3.new(20, 1.4, 2), CFrame = gcf * CFrame.new(0, 14.5, 0), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
	part({ Name = "DojoGateRoof", Size = Vector3.new(23, 1, 4), CFrame = gcf * CFrame.new(0, 15.7, 0), Color = ROOF, Material = Enum.Material.Slate, Parent = f })
	local plaque = part({ Name = "DojoPlaque", Size = Vector3.new(12, 3, 0.4), CFrame = gcf * CFrame.new(0, 12, -0.4), Color = Color3.fromRGB(30, 22, 18), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(plaque, Enum.NormalId.Front, { { "🏯 상급 수련장", GOLD, 1 } })
	sign(plaque, Enum.NormalId.Back, { { "🏯 상급 수련장", GOLD, 1 } })
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
-- 염화단: 검은 현무암 단 위의 꺼지지 않는 불. 용암 고랑이 둘레를 돌고, 흑요석 기둥마다 불꽃
function SITES.yeolhwa(r: any, at: Vector3, color: Color3, f: Instance)
	local d = Vector3.new(at.X, 0, at.Z)
	local LAVA = Color3.fromRGB(255, 110, 30)
	cyl("FireDais", d + Vector3.new(0, at.Y / 2, 0), 18, at.Y, Color3.fromRGB(50, 40, 40), Enum.Material.Basalt, f)
	cyl("FireDaisRim", d + Vector3.new(0, at.Y + 0.05, 0), 16, 0.1, LAVA, Enum.Material.Neon, f, false).Transparency = 0.4
	-- 둘레의 용암 고랑 (둥근 띠)
	for k = 0, 31 do
		local a = k / 32 * math.pi * 2
		local p = d + Vector3.new(math.cos(a) * 30, 0.25, math.sin(a) * 30)
		part({ Name = "LavaMoat", Size = Vector3.new(3.4, 0.4, 6.4), CFrame = CFrame.lookAt(p, d + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = LAVA, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	-- 흑요석 기둥 여섯과 꼭대기 불꽃
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local p = d + Vector3.new(math.cos(a) * 22, 0, math.sin(a) * 22)
		part({ Name = "ObsidianPillar", Size = Vector3.new(3, 16, 3), CFrame = CFrame.new(p + Vector3.new(0, 8, 0)) * CFrame.Angles(0, a, 0), Color = Color3.fromRGB(25, 20, 28), Material = Enum.Material.Glass, Parent = f })
		local bowl = cyl("PillarFire", p + Vector3.new(0, 16.6, 0), 1.8, 1, Color3.fromRGB(60, 50, 50), Enum.Material.Basalt, f)
		local fire = Instance.new("Fire")
		fire.Size = 7
		fire.Heat = 10
		fire.Color = LAVA
		fire.SecondaryColor = Color3.fromRGB(255, 220, 120)
		fire.Parent = bowl
		light(bowl, LAVA, 22, 2)
	end
	-- 가운데 뒤편의 큰 불 (꺼지지 않는 불)
	local core = part({ Name = "EternalFlame", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), Position = d + Vector3.new(0, at.Y + 9, -10), Color = LAVA, Material = Enum.Material.Neon, Transparency = 0.2, CanCollide = false, Parent = f })
	local big = Instance.new("Fire")
	big.Size = 14
	big.Heat = 14
	big.Color = LAVA
	big.SecondaryColor = Color3.fromRGB(255, 230, 140)
	big.Parent = core
	light(core, LAVA, 50, 3)
	emitter(core, Color3.fromRGB(255, 160, 70), 16, 1.2, 6, 2)
	-- 검은 바위와 붉은 수정
	for k = 0, 11 do
		local a = k * 2.3
		local p = d + Vector3.new(math.cos(a) * (40 + (k % 4) * 12), 0, math.sin(a) * (40 + (k % 4) * 12))
		rock(p, 4 + (k % 3) * 2, f, Color3.fromRGB(45, 38, 38))
		if k % 3 == 0 then
			crystal(p + Vector3.new(0, 4, 0), 1.4, LAVA, f)
		end
	end
end

-- 창해각: 바닷가 사당. 둥근 조수 웅덩이, 파도 무늬 기둥 여덟, 푸른 석등, 산호 바위와 조개
function SITES.changhae(r: any, at: Vector3, color: Color3, f: Instance)
	local c = r.center
	local SEA = Color3.fromRGB(50, 130, 200)
	local pool = c + Vector3.new(-70, 0, 0)
	cyl("TidePool", pool + Vector3.new(0, 0.35, 0), 42, 0.5, SEA, Enum.Material.Glass, f, false).Transparency = 0.25
	cyl("TidePoolBed", pool + Vector3.new(0, 0.1, 0), 42, 0.3, Color3.fromRGB(30, 60, 90), Enum.Material.Slate, f, false)
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		local p = pool + Vector3.new(math.cos(a) * 44, 0.8, math.sin(a) * 44)
		part({ Name = "PoolRim", Size = Vector3.new(4, 1.6, 12), CFrame = CFrame.lookAt(p, pool + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(175, 170, 150), Material = Enum.Material.Sandstone, Parent = f })
	end
	-- 사부의 단: 둥근 돌단과 파도 무늬 기둥
	local d = Vector3.new(at.X, 0, at.Z)
	cyl("ShrineDais", d + Vector3.new(0, at.Y / 2, 0), 16, at.Y, Color3.fromRGB(200, 195, 175), Enum.Material.Marble, f)
	cyl("ShrineWave", d + Vector3.new(0, at.Y + 0.06, 0), 13, 0.1, Color3.fromRGB(120, 200, 255), Enum.Material.Neon, f, false).Transparency = 0.35
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2 + math.pi / 8
		local p = d + Vector3.new(math.cos(a) * 15, 0, math.sin(a) * 15)
		part({ Name = "WavePillar", Size = Vector3.new(2.4, 14, 2.4), Position = p + Vector3.new(0, at.Y + 7, 0), Color = Color3.fromRGB(225, 225, 215), Material = Enum.Material.Marble, Parent = f })
		for j = 0, 2 do
			part({ Name = "WaveBand", Size = Vector3.new(2.7, 0.4, 2.7), CFrame = CFrame.new(p + Vector3.new(0, at.Y + 3 + j * 4, 0)) * CFrame.Angles(0, 0, math.rad(12 * (j % 2 == 0 and 1 or -1))), Color = SEA, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		end
		crystal(p + Vector3.new(0, at.Y + 16.5, 0), 1.2, Color3.fromRGB(120, 210, 255), f)
	end
	-- 지붕 없는 둥근 띠 (기둥을 잇는다)
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		local p = d + Vector3.new(math.cos(a) * 15, at.Y + 14.4, math.sin(a) * 15)
		part({ Name = "ShrineRing", Size = Vector3.new(1.2, 1, 6.2), CFrame = CFrame.lookAt(p, d + Vector3.new(0, at.Y + 14.4, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(225, 225, 215), Material = Enum.Material.Marble, Parent = f })
	end
	-- 산호 바위와 조개
	for k = 0, 13 do
		local a = k * 2.4
		local p = c + Vector3.new(math.cos(a) * (50 + k * 4), 0, math.sin(a) * (50 + k * 4))
		if (p - pool).Magnitude > 50 then
			local h = 3 + (k % 4) * 1.5
			part({ Name = "Coral", Size = Vector3.new(1.4, h, 1.4), CFrame = CFrame.new(p + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0.2 * (k % 3 - 1), k, 0.2), Color = k % 2 == 0 and Color3.fromRGB(255, 120, 110) or Color3.fromRGB(255, 180, 130), Material = Enum.Material.SmoothPlastic, Parent = f })
			part({ Name = "Shell", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 0.7, 1.4), Position = p + Vector3.new(2, 0.3, 1), Color = Color3.fromRGB(250, 235, 225), Material = Enum.Material.SmoothPlastic, Parent = f })
		end
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		stoneLantern(d + Vector3.new(math.cos(a) * 26, 0, math.sin(a) * 26), f, k % 2 == 0)
	end
end

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
		if made >= 75 then
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
local VILLAGE_PAD = 260 -- 마을 성벽 둘레는 마을 것으로 둔다
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


------------------------------------------------------------------------
-- 1.0판: 지역의 경계를 자연스럽게. 낮은 돌 턱 대신 그 땅의 생김새를 따른다
-- (풀밭은 낮은 언덕과 나무숲, 대숲은 대나무, 산적 소굴은 목책, 설산은 눈 둔덕과 전나무, 황야는 붉은 바위기둥 ...).
-- 길이 드는 곳과 군데군데 자연스러운 틈은 비워 두고, 이웃한 지역끼리는 덤불 정도로만 가른다
------------------------------------------------------------------------
local BORDER_THEME: { [string]: string } = {
	bamboo = "bamboo", fort = "fort", valley = "grass", field = "grass", windhill = "grass", lake = "grass", plum = "blossom", tavern = "fence",
	dojo = "garden", temple = "garden", lair = "crag", peak = "crag", ravine = "crag", sunmoon = "crag", cult = "cult", rift = "rift",
	snow = "snow", swamp = "swamp", badlands = "sand", tomb = "sand", coast = "coast", seashrine = "coast", volcano = "volcano",
	fireshrine = "volcano", skysea = "cloud", plateau = "rocky",
}
local RIDGE_MAT: { [string]: Enum.Material } = {
	grass = Enum.Material.Grass, bamboo = Enum.Material.Grass, blossom = Enum.Material.Grass, fence = Enum.Material.Grass, fort = Enum.Material.Mud,
	crag = Enum.Material.Slate, cult = Enum.Material.Slate, rift = Enum.Material.Slate, snow = Enum.Material.Snow, swamp = Enum.Material.Mud,
	sand = Enum.Material.Sandstone, coast = Enum.Material.Rock, volcano = Enum.Material.Basalt, rocky = Enum.Material.Rock,
}
local LEAF = Color3.fromRGB(70, 120, 60)

-- 이웃한 다른 지역 (또는 마을) 안인가
local function insideOther(p: Vector3, r: any, pad: number): boolean
	if math.abs(p.X) < VILLAGE_PAD + pad and math.abs(p.Z) < VILLAGE_PAD + pad then
		return true
	end
	for _, o in ipairs(Config.Regions) do
		if o ~= r and not o.noGround and math.abs(p.X - o.center.X) < o.size.X / 2 + pad and math.abs(p.Z - o.center.Z) < o.size.Z / 2 + pad then
			return true
		end
	end
	return false
end

local function bush(at: Vector3, s: number, color: Color3, f: Instance)
	for i = 1, 2 do
		local sz = (3.2 + i * 0.8 + rng:NextNumber(0, 1.2)) * s
		part({ Name = "Bush", Shape = Enum.PartType.Ball, Size = Vector3.one * sz, Position = at + Vector3.new(rng:NextNumber(-1.5, 1.5) * s, sz * 0.32, rng:NextNumber(-1.5, 1.5) * s),
			Color = color:Lerp(Color3.new(1, 1, 1), rng:NextNumber(0, 0.12)), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
	end
end
-- 뾰족한 바위 (기울어진 큰 돌 + 끝돌)
local function crag(at: Vector3, s: number, color: Color3, f: Instance)
	local h = rng:NextNumber(7, 14) * s
	part({ Name = "Crag", Size = Vector3.new(rng:NextNumber(3, 5) * s, h, rng:NextNumber(3, 5) * s), CFrame = CFrame.new(at + Vector3.new(0, h * 0.42, 0)) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 6), rng:NextNumber(-0.2, 0.2)),
		Color = color, Material = Enum.Material.Slate, Parent = f })
	part({ Name = "CragTip", Size = Vector3.new(2, h * 0.45, 2) * Vector3.new(s, 1, s), CFrame = CFrame.new(at + Vector3.new(rng:NextNumber(-1, 1) * s, h * 0.95, rng:NextNumber(-1, 1) * s)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)),
		Color = color:Lerp(Color3.new(0, 0, 0), 0.15), Material = Enum.Material.Slate, Parent = f })
end
-- 붉은 모래 바위기둥 (세 덩이를 어긋나게 쌓는다)
local function hoodoo(at: Vector3, s: number, f: Instance)
	local y = 0
	for i = 1, 3 do
		local w = (5.5 - i * 1.2) * s
		local h = rng:NextNumber(3, 5) * s
		part({ Name = "Hoodoo", Size = Vector3.new(w * rng:NextNumber(0.9, 1.2), h, w), CFrame = CFrame.new(at + Vector3.new(rng:NextNumber(-0.5, 0.5) * s, y + h / 2, rng:NextNumber(-0.5, 0.5) * s)) * CFrame.Angles(0, rng:NextNumber(0, 6), rng:NextNumber(-0.06, 0.06)),
			Color = Color3.fromRGB(196, 140, 90):Lerp(Color3.fromRGB(225, 180, 125), rng:NextNumber()), Material = Enum.Material.Sandstone, Parent = f })
		y += h * 0.92
	end
end
local function reeds(at: Vector3, f: Instance)
	for _ = 1, 4 do
		local h = rng:NextNumber(4, 7)
		part({ Name = "Reed", Size = Vector3.new(0.25, h, 0.25), CFrame = CFrame.new(at + Vector3.new(rng:NextNumber(-1.5, 1.5), h / 2, rng:NextNumber(-1.5, 1.5))) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, rng:NextNumber(-0.15, 0.15)),
			Color = Color3.fromRGB(120, 130, 70), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
	end
end

------------------------------------------------------------------------
-- 1.8판: 세상 끝 네 땅 (단풍산 · 석림 · 거균림 · 운무 차밭)
------------------------------------------------------------------------
-- 떨어지는 잎·포자·안개 같은 입자
local function drift(at: Vector3, size: Vector3, colors: { Color3 }, rate: number, psize: number, life: number, fall: number, f: Instance, glow: number?)
	local holder = part({ Name = "Drift", Size = size, Position = at, Transparency = 1, CanCollide = false, Parent = f })
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	local keys = {}
	for i, c in ipairs(colors) do
		table.insert(keys, ColorSequenceKeypoint.new(#colors == 1 and 0 or (i - 1) / (#colors - 1), c))
	end
	if #keys == 1 then
		table.insert(keys, ColorSequenceKeypoint.new(1, colors[1]))
	end
	pe.Color = ColorSequence.new(keys)
	pe.Size = NumberSequence.new(psize, psize * 0.6)
	pe.Squash = NumberSequence.new(0.4)
	pe.Lifetime = NumberRange.new(life * 0.7, life)
	pe.Rate = rate
	pe.Speed = NumberRange.new(0.5, 2)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0.8, -fall, 0.4)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-90, 90)
	pe.LightEmission = glow or 0.2
	pe.Shape = Enum.ParticleEmitterShape.Box
	pe.Parent = holder
end

-- 단풍나무: 굽은 줄기, 갈라진 가지, 붉고 노란 잎 덩이
local MAPLE = { Color3.fromRGB(205, 55, 35), Color3.fromRGB(235, 120, 40), Color3.fromRGB(240, 180, 60), Color3.fromRGB(180, 40, 45) }
local function mapleTree(at: Vector3, s: number, f: Instance)
	local lean = rng:NextNumber(-0.12, 0.12)
	local trunkH = 11 * s
	part({ Name = "MapleTrunk", Size = Vector3.new(1.5 * s, trunkH, 1.5 * s), CFrame = CFrame.new(at + Vector3.new(0, trunkH / 2, 0)) * CFrame.Angles(lean, rng:NextNumber(0, 6), -lean), Color = Color3.fromRGB(70, 45, 35), Material = Enum.Material.Wood, Parent = f })
	local top = at + Vector3.new(0, trunkH, 0)
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2 + rng:NextNumber(0, 1)
		local to = top + Vector3.new(math.cos(a) * 4 * s, 2.5 * s, math.sin(a) * 4 * s)
		part({ Name = "MapleBranch", Size = Vector3.new(0.6 * s, 0.6 * s, (to - top).Magnitude), CFrame = CFrame.lookAt((top + to) / 2, to), Color = Color3.fromRGB(70, 45, 35), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
		part({ Name = "MapleLeaves", Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(6, 8.5) * s, Position = to + Vector3.new(0, 1 * s, 0), Color = MAPLE[rng:NextInteger(1, #MAPLE)], Material = Enum.Material.LeafyGrass, CanCollide = false, Parent = f })
	end
	part({ Name = "MapleCrown", Shape = Enum.PartType.Ball, Size = Vector3.one * 9 * s, Position = top + Vector3.new(0, 4.5 * s, 0), Color = MAPLE[rng:NextInteger(1, #MAPLE)], Material = Enum.Material.LeafyGrass, CanCollide = false, Parent = f })
end

function OUTER.maple(r: any, f: Instance)
	for _ = 1, 60 do
		local p = randIn(r, 25)
		if clearOf(p, r) then
			mapleTree(p, rng:NextNumber(0.9, 1.5), f)
		end
	end
	-- 땅에 깔린 낙엽 (붉고 노란 얼룩)
	for _ = 1, 26 do
		local p = randIn(r, 30)
		disc("FallenLeaves", p + Vector3.new(0, 0.12, 0), rng:NextNumber(6, 14), 0.12, MAPLE[rng:NextInteger(1, #MAPLE)]:Lerp(Color3.fromRGB(120, 70, 40), 0.25), Enum.Material.LeafyGrass, f, false)
	end
	for _ = 1, 14 do
		local p = randIn(r, 30)
		if clearOf(p, r) then
			crag(p, rng:NextNumber(1, 1.8), Color3.fromRGB(120, 100, 85), f)
		end
	end
	-- 풍엽의 자리: 붉은 기둥의 정자와 돌계단, 둘레에 석등
	local b = r.boss.at
	disc("MapleDais", b + Vector3.new(0, 0.5, 0), 40, 1, Color3.fromRGB(150, 120, 95), Enum.Material.Cobblestone, f)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local q = b + Vector3.new(math.cos(a) * 44, 0, math.sin(a) * 44)
		stoneLantern(q, f, true)
	end
	building(b + Vector3.new(0, 0, -60), 26, 18, 0, f, { tiers = 2, sign = "풍엽각", h = 11, wall = Color3.fromRGB(235, 220, 200), roof = Color3.fromRGB(150, 50, 35) })
	drift(r.center + Vector3.new(0, 30, 0), Vector3.new(r.size.X * 0.9, 4, r.size.Z * 0.9), { MAPLE[1], MAPLE[2], MAPLE[3] }, 60, 0.6, 9, 1.6, f)
end

-- 석림: 겹겹이 쌓인 회색 돌기둥, 꼭대기엔 이끼와 작은 소나무
function OUTER.stoneforest(r: any, f: Instance)
	local STONE_A = Color3.fromRGB(165, 165, 158)
	for _ = 1, 75 do
		local p = randIn(r, 25)
		if clearOf(p, r) then
			local y = 0
			local w = rng:NextNumber(8, 16)
			local n = rng:NextInteger(3, 6)
			for i = 1, n do
				local h = rng:NextNumber(7, 13)
				local ww = w * (1 - i * 0.1)
				part({ Name = "KarstStone", Size = Vector3.new(ww, h, ww * rng:NextNumber(0.8, 1.1)), CFrame = CFrame.new(p + Vector3.new(rng:NextNumber(-1, 1), y + h / 2, rng:NextNumber(-1, 1))) * CFrame.Angles(rng:NextNumber(-0.05, 0.05), rng:NextNumber(0, 6), rng:NextNumber(-0.05, 0.05)),
					Color = STONE_A:Lerp(Color3.fromRGB(120, 120, 115), rng:NextNumber()), Material = Enum.Material.Limestone, Parent = f })
				y += h * 0.95
			end
			if rng:NextNumber() < 0.6 then
				part({ Name = "KarstMoss", Shape = Enum.PartType.Ball, Size = Vector3.new(w * 0.7, w * 0.35, w * 0.7), Position = p + Vector3.new(0, y + 0.5, 0), Color = Color3.fromRGB(80, 120, 60), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
			else
				pine(p + Vector3.new(0, y, 0), 0.6, f, false)
			end
		end
	end
	for _ = 1, 24 do
		local p = randIn(r, 20)
		if clearOf(p, r) then
			rock(p, rng:NextNumber(3, 7), f, Color3.fromRGB(150, 150, 142))
		end
	end
	-- 석왕의 돌 마당: 둘레에 선 일곱 돌기둥
	local b = r.boss.at
	disc("StoneCourt", b + Vector3.new(0, 0.4, 0), 42, 0.8, Color3.fromRGB(175, 172, 165), Enum.Material.Slate, f)
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2
		part({ Name = "StoneMonolith", Size = Vector3.new(5, 26, 5), CFrame = CFrame.new(b + Vector3.new(math.cos(a) * 48, 13, math.sin(a) * 48)) * CFrame.Angles(0, a, 0), Color = Color3.fromRGB(140, 140, 132), Material = Enum.Material.Limestone, Parent = f })
	end
	drift(r.center + Vector3.new(0, 8, 0), Vector3.new(r.size.X * 0.9, 6, r.size.Z * 0.9), { Color3.fromRGB(235, 235, 235) }, 40, 6, 10, -0.05, f, 0)
end

-- 거균림: 집채만 한 버섯 (줄기, 점박이 갓, 빛나는 갓 밑), 바닥의 작은 빛 버섯, 떠도는 포자
local CAPS = { Color3.fromRGB(200, 50, 60), Color3.fromRGB(150, 80, 210), Color3.fromRGB(60, 170, 170), Color3.fromRGB(230, 140, 50) }
local function bigMushroom(at: Vector3, s: number, f: Instance)
	local h = rng:NextNumber(12, 26) * s
	local cap = CAPS[rng:NextInteger(1, #CAPS)]
	local tilt = rng:NextNumber(-0.12, 0.12)
	part({ Name = "MushStem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 3 * s, 3 * s), CFrame = CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(tilt, 0, math.rad(90)), Color = Color3.fromRGB(235, 225, 205), Material = Enum.Material.SmoothPlastic, Parent = f })
	local w = rng:NextNumber(14, 22) * s
	local top = at + Vector3.new(0, h, 0)
	local capPart = part({ Name = "MushCap", Shape = Enum.PartType.Ball, Size = Vector3.new(w, w * 0.45, w), Position = top + Vector3.new(0, w * 0.12, 0), Color = cap, Material = Enum.Material.SmoothPlastic, Parent = f })
	local under = part({ Name = "MushGill", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, w * 0.8, w * 0.8), CFrame = CFrame.new(top - Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = cap:Lerp(Color3.new(1, 1, 1), 0.5), Material = Enum.Material.Neon, Transparency = 0.2, CanCollide = false, Parent = f })
	light(under, cap:Lerp(Color3.new(1, 1, 1), 0.4), w, 0.8)
	for _ = 1, 5 do
		local a, rr = rng:NextNumber(0, 6.28), rng:NextNumber(0, w * 0.35)
		part({ Name = "MushSpot", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 0.5, 1.6) * s, Position = capPart.Position + Vector3.new(math.cos(a) * rr, w * 0.2 - rr * 0.25, math.sin(a) * rr), Color = Color3.fromRGB(250, 245, 235), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
	end
end
function OUTER.mushroom(r: any, f: Instance)
	for _ = 1, 42 do
		local p = randIn(r, 30)
		if clearOf(p, r) then
			bigMushroom(p, rng:NextNumber(0.8, 1.4), f)
		end
	end
	for _ = 1, 40 do
		local p = randIn(r, 15)
		if clearOf(p, r) then
			for k = 1, 3 do
				local c = CAPS[rng:NextInteger(1, #CAPS)]
				local q = p + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
				local hh = rng:NextNumber(1, 2.5)
				part({ Name = "SmallStem", Size = Vector3.new(0.4, hh, 0.4), Position = q + Vector3.new(0, hh / 2, 0), Color = Color3.fromRGB(235, 230, 215), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
				part({ Name = "SmallCap", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 0.7, 1.6) * (0.7 + k * 0.2), Position = q + Vector3.new(0, hh, 0), Color = c, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			end
		end
	end
	-- 균왕의 자리: 버섯 고리
	local b = r.boss.at
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		bigMushroom(b + Vector3.new(math.cos(a) * 52, 0, math.sin(a) * 52), 0.7, f)
	end
	drift(r.center + Vector3.new(0, 10, 0), Vector3.new(r.size.X * 0.9, 16, r.size.Z * 0.9), { Color3.fromRGB(200, 150, 255), Color3.fromRGB(150, 255, 230) }, 70, 0.35, 8, -0.2, f, 0.8)
end

-- 운무 차밭: 고랑을 따라 늘어선 차나무 줄, 돌담 수로, 정자, 연못, 낮게 깔린 안개
function OUTER.teafield(r: any, f: Instance)
	local TEA = Color3.fromRGB(60, 120, 55)
	local x0, x1 = r.center.X - r.size.X / 2 + 30, r.center.X + r.size.X / 2 - 30
	local z = r.center.Z - r.size.Z / 2 + 30
	local row = 0
	while z < r.center.Z + r.size.Z / 2 - 30 do
		local x = x0 + (row % 2) * 16
		while x < x1 do
			local len = 34
			local mid = Vector3.new(x + len / 2, 0, z)
			if clearOf(mid, r) and clearOf(mid + Vector3.new(len / 2, 0, 0), r) and clearOf(mid - Vector3.new(len / 2, 0, 0), r) then
				part({ Name = "TeaRow", Size = Vector3.new(len, 2.4, 3.4), Position = mid + Vector3.new(0, 1.2, 0), Color = TEA:Lerp(Color3.fromRGB(110, 170, 80), rng:NextNumber() * 0.5), Material = Enum.Material.LeafyGrass, Parent = f })
				part({ Name = "TeaTop", Size = Vector3.new(len - 1, 0.6, 2.6), Position = mid + Vector3.new(0, 2.6, 0), Color = Color3.fromRGB(120, 180, 90), Material = Enum.Material.LeafyGrass, CanCollide = false, Parent = f })
			end
			x += len + 14
		end
		z += 28
		row += 1
	end
	-- 다선의 정자와 연못
	local b = r.boss.at
	disc("TeaPond", b + Vector3.new(70, 0.2, 40), 26, 0.4, Color3.fromRGB(120, 175, 190), Enum.Material.Glass, f, false).Transparency = 0.2
	disc("TeaCourt", b + Vector3.new(0, 0.4, 0), 36, 0.8, Color3.fromRGB(190, 180, 160), Enum.Material.Cobblestone, f)
	building(b + Vector3.new(-60, 0, 0), 20, 16, math.rad(90), f, { sign = "운무다원", h = 10, wall = Color3.fromRGB(240, 235, 220), roof = Color3.fromRGB(70, 110, 80) })
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + math.pi / 4
		stoneLantern(b + Vector3.new(math.cos(a) * 40, 0, math.sin(a) * 40), f, true)
	end
	drift(r.center + Vector3.new(0, 4, 0), Vector3.new(r.size.X * 0.9, 4, r.size.Z * 0.9), { Color3.fromRGB(240, 245, 240) }, 50, 8, 10, -0.03, f, 0)
end
local function cloudBank(at: Vector3, s: number, f: Instance)
	for _ = 1, 3 do
		local sz = rng:NextNumber(6, 10) * s
		part({ Name = "CloudBank", Shape = Enum.PartType.Ball, Size = Vector3.one * sz, Position = at + Vector3.new(rng:NextNumber(-4, 4) * s, sz * 0.25, rng:NextNumber(-4, 4) * s),
			Color = Color3.fromRGB(245, 247, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.15, CanCollide = false, Parent = f })
	end
end
-- 목책: 뾰족한 통나무를 촘촘히 박고 가로대 하나
local function palisade(p: Vector3, dir: Vector3, len: number, f: Instance)
	local n = math.max(2, math.floor(len / 2.2))
	for i = 0, n - 1 do
		local q = p + dir * (i * len / (n - 1))
		local h = rng:NextNumber(7, 9)
		part({ Name = "Stake", Size = Vector3.new(1.2, h, 1.2), CFrame = CFrame.new(q + Vector3.new(0, h / 2 - 0.3, 0)) * CFrame.Angles(rng:NextNumber(-0.06, 0.06), rng:NextNumber(0, 6), rng:NextNumber(-0.06, 0.06)),
			Color = Color3.fromRGB(98, 72, 50):Lerp(Color3.fromRGB(70, 52, 38), rng:NextNumber()), Material = Enum.Material.Wood, Parent = f })
	end
	local mid = p + dir * len / 2 + Vector3.new(0, 3, 0)
	part({ Name = "StakeRail", Size = Vector3.new(0.6, 0.6, len), CFrame = CFrame.lookAt(mid, mid + dir) * CFrame.new(0.7, 0, 0), Color = Color3.fromRGB(80, 60, 42), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
end
-- 나무 울타리 (기둥 + 가로대 둘)
local function railFence(p: Vector3, dir: Vector3, len: number, f: Instance)
	local n = math.max(2, math.floor(len / 6) + 1)
	for i = 0, n - 1 do
		local q = p + dir * (i * len / (n - 1))
		part({ Name = "FencePost", Size = Vector3.new(0.8, 4.2, 0.8), Position = q + Vector3.new(0, 2.1, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = f })
	end
	for _, y in ipairs({ 1.6, 3.2 }) do
		local mid = p + dir * len / 2 + Vector3.new(0, y, 0)
		part({ Name = "FenceRail", Size = Vector3.new(0.35, 0.45, len), CFrame = CFrame.lookAt(mid, mid + dir), Color = WOOD:Lerp(Color3.new(1, 1, 1), 0.1), Material = Enum.Material.Wood, Parent = f })
	end
end
-- 다듬은 생울타리 (정원·절)
local function hedge(p: Vector3, dir: Vector3, len: number, f: Instance)
	local mid = p + dir * len / 2
	part({ Name = "Hedge", Size = Vector3.new(2.8, 3.4, len), CFrame = CFrame.lookAt(mid + Vector3.new(0, 1.7, 0), mid + Vector3.new(0, 1.7, 0) + dir), Color = Color3.fromRGB(55, 100, 50), Material = Enum.Material.Grass, Parent = f })
	part({ Name = "HedgeTop", Size = Vector3.new(2.4, 0.8, math.max(1, len - 0.4)), CFrame = CFrame.lookAt(mid + Vector3.new(0, 3.6, 0), mid + Vector3.new(0, 3.6, 0) + dir), Color = Color3.fromRGB(80, 130, 65), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
end

-- 한 변의 한 토막: 덩어리(숲·바위·둔덕)와 트인 틈이 번갈아 온다
local function borderSpan(r: any, theme: string, fixed: string, v: number, lo: number, hi: number, outward: Vector3, f: Instance, terrain: Terrain?)
	local small = math.max(r.size.X, r.size.Z) <= 300
	local along = fixed == "x" and Vector3.new(0, 0, 1) or Vector3.new(1, 0, 0)
	local step = small and 24 or 21
	local x = lo + rng:NextNumber(0, 8)
	local clump = rng:NextNumber() < 0.75
	local left = clump and rng:NextNumber(40, 120) or rng:NextNumber(15, 35)
	local count = 0
	while x < hi - 3 do
		if not clump then
			-- 트인 틈 (지나다닐 수 있게)
			x += left
			clump = true
			left = rng:NextNumber(small and 50 or 60, small and 110 or 170)
			continue
		end
		local p = fixed == "x" and Vector3.new(v, 0, x) or Vector3.new(x, 0, v)
		local len = math.min(step, hi - x)
		x += step
		left -= step
		if left <= 0 then
			clump = false
			left = rng:NextNumber(18, 45)
		end
		if nearRoad(p, 20) or nearFeature(p, 4) or insideOther(p, r, -2) then
			continue
		end
		count += 1
		-- 이웃 지역과 맞닿은 변: 덤불·작은 돌만 듬성듬성
		local shared = insideOther(p + outward * 26, r, 0)
		if shared then
			if count % 2 == 0 then
				if theme == "sand" or theme == "crag" or theme == "volcano" or theme == "rocky" or theme == "cult" or theme == "rift" or theme == "coast" then
					rock(p + along * rng:NextNumber(-4, 4), rng:NextNumber(3, 5), f)
				elseif theme == "snow" then
					rock(p, rng:NextNumber(3, 5), f, Color3.fromRGB(225, 232, 242))
				elseif theme ~= "cloud" then
					bush(p + along * rng:NextNumber(-4, 4), 0.9, theme == "blossom" and Color3.fromRGB(200, 120, 140) or LEAF, f)
				end
			end
			continue
		end
		-- 바깥쪽으로 낮은 둔덕 (지형). 안쪽 비탈 위에 소품을 얹는다
		local lift = 0
		local mat = RIDGE_MAT[theme]
		local q = p + outward * rng:NextNumber(3, 9) + along * rng:NextNumber(-4, 4)
		if terrain and mat and not small then
			local rad = rng:NextNumber(15, 24)
			local c = p + outward * rad * 0.5 + along * rng:NextNumber(-3, 3)
			if not nearRoad(c, rad + 8) and not nearFeature(c, rad * 0.6) then
				local ok = pcall(function()
					(terrain :: Terrain):FillBall(c - Vector3.new(0, rad * 0.5, 0), rad, mat)
				end)
				if ok then
					local d = Vector3.new(q.X - c.X, 0, q.Z - c.Z).Magnitude
					lift = math.max(0, math.sqrt(math.max(0, rad * rad - d * d)) - rad * 0.5 - 0.6)
				end
			end
		end
		local at = q + Vector3.new(0, lift, 0)
		local roll = rng:NextNumber()
		if theme == "grass" or theme == "blossom" then
			if roll < 0.55 then
				tree(at, rng:NextNumber(1.3, 1.8), f, theme == "blossom" and roll < 0.4)
			elseif roll < 0.85 then
				bush(at, rng:NextNumber(0.9, 1.3), theme == "blossom" and Color3.fromRGB(200, 120, 140) or LEAF, f)
			else
				rock(at, rng:NextNumber(4, 7), f)
			end
		elseif theme == "bamboo" then
			for _ = 1, 3 + (count % 3) do
				bamboo(at + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4)), f)
			end
		elseif theme == "fence" then
			railFence(p, along, len - 2, f)
			if roll < 0.3 then
				tree(at + outward * 4, rng:NextNumber(1.2, 1.6), f)
			end
		elseif theme == "fort" then
			palisade(p, along, len - 1, f)
			if roll < 0.25 then
				rock(at + outward * 3, rng:NextNumber(4, 6), f, Color3.fromRGB(110, 100, 90))
			end
		elseif theme == "garden" then
			hedge(p, along, len - 3, f)
			if count % 3 == 0 then
				pine(p + outward * 5, 1.2, f, false)
			end
		elseif theme == "crag" or theme == "rocky" then
			local col = theme == "rocky" and Color3.fromRGB(140, 140, 135) or Color3.fromRGB(70, 66, 72)
			if roll < 0.6 then
				crag(at, rng:NextNumber(0.9, 1.5), col, f)
			else
				rock(at, rng:NextNumber(4, 7), f, col)
			end
		elseif theme == "cult" then
			crag(at, rng:NextNumber(0.9, 1.4), Color3.fromRGB(60, 30, 34), f)
			if count % 5 == 0 then
				banner(p - outward * 2, 12, Color3.fromRGB(150, 20, 30), f)
			end
		elseif theme == "rift" then
			crag(at, rng:NextNumber(0.9, 1.5), Color3.fromRGB(45, 32, 70), f)
			if count % 4 == 0 then
				crystal(at + Vector3.new(0, 14, 0), 2.4, Color3.fromRGB(170, 90, 255), f)
			end
		elseif theme == "snow" then
			if roll < 0.65 then
				pine(at, rng:NextNumber(1.3, 1.8), f, true)
			else
				rock(at, rng:NextNumber(4, 7), f, Color3.fromRGB(215, 225, 238))
			end
		elseif theme == "swamp" then
			if roll < 0.45 then
				deadTree(at, rng:NextNumber(1.0, 1.4), f)
			end
			reeds(at + along * 3, f)
		elseif theme == "sand" then
			if roll < 0.5 then
				hoodoo(at, rng:NextNumber(0.9, 1.4), f)
			elseif roll < 0.8 then
				rock(at, rng:NextNumber(4, 7), f, Color3.fromRGB(200, 150, 100))
			else
				deadTree(at, 0.8, f)
			end
		elseif theme == "coast" then
			if roll < 0.6 then
				rock(at, rng:NextNumber(6, 10), f, Color3.fromRGB(130, 128, 120))
			else
				pine(at, rng:NextNumber(1.2, 1.6), f, false)
			end
		elseif theme == "volcano" then
			crag(at, rng:NextNumber(0.9, 1.5), Color3.fromRGB(40, 34, 32), f)
			if count % 3 == 0 then
				local cp = p - outward * 3
				part({ Name = "LavaCrack", Size = Vector3.new(0.6, 0.2, len * 0.8), CFrame = CFrame.lookAt(cp + Vector3.new(0, 0.12, 0), cp + Vector3.new(0, 0.12, 0) + along) * CFrame.Angles(0, rng:NextNumber(-0.4, 0.4), 0),
					Color = Color3.fromRGB(255, 120, 40), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			end
		elseif theme == "cloud" then
			cloudBank(at, rng:NextNumber(1.0, 1.5), f)
		end
	end
end

-- 지역 테두리: 둘레를 그 땅에 맞는 자연스러운 경계로 (길이 지나는 곳은 비우고 문루)
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
			local edges = { { "x", x0, z0, z1, Vector3.new(-1, 0, 0) }, { "x", x1, z0, z1, Vector3.new(1, 0, 0) }, { "z", z0, x0, x1, Vector3.new(0, 0, -1) }, { "z", z1, x0, x1, Vector3.new(0, 0, 1) } }
			local theme = BORDER_THEME[r.id] or "grass"
			local terrain = workspace:FindFirstChildOfClass("Terrain")
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
				-- 길이 지나는 자리(문루 둘레 폭 48)를 비우고 자연스러운 경계를 놓는다
				local from = lo
				local spans: { { number } } = {}
				for _, c in ipairs(cuts) do
					table.insert(spans, { from, c - 24 })
					from = c + 24
				end
				table.insert(spans, { from, hi })
				for _, sp in ipairs(spans) do
					if sp[2] - sp[1] > 6 then
						borderSpan(r, theme, fixed, v, sp[1], sp[2], e[5], f, terrain)
					end
				end
			end
		end
	end
end

-- 1.5판: 초월 권법의 사부 자리. 매화원 가장 깊은 곳, 철 모르고 벚꽃이 흩날리는 언덕 (돌 단, 거대한 벚나무, 떨어지는 꽃잎)
------------------------------------------------------------------------
-- 2.4판: 새 랜드마크 여섯 (허허벌판을 채운다)
------------------------------------------------------------------------
-- 만목원: 비틀린 고목 아홉이 둥글게 서서 가지로 지붕을 이룬 숲. 가운데 이끼 덮인 돌 좌대에 목선 (만목신권의 사부)
function LANDMARK.grove(at: Vector3, f: Instance)
	local bark = Color3.fromRGB(78, 58, 42)
	local moss = Color3.fromRGB(70, 120, 55)
	disc("GroveFloor", at + Vector3.new(0, 0.15, 0), 70, 0.3, Color3.fromRGB(70, 105, 50), Enum.Material.Grass, f, false)
	for k = 0, 8 do
		local a = k / 9 * math.pi * 2
		local base = at + Vector3.new(math.cos(a) * 46, 0, math.sin(a) * 46)
		-- 휘어 오르는 줄기 세 마디, 가운데 쪽으로 기운다
		local p = base
		for j = 1, 3 do
			local nxt = p + Vector3.new(0, 14, 0) + (at - base).Unit * (4 + j * 3) + Vector3.new(math.sin(k + j) * 2, 0, math.cos(k + j) * 2)
			part({ Name = "GroveTrunk", Size = Vector3.new(6 - j, 6 - j, (nxt - p).Magnitude + 2), CFrame = CFrame.lookAt((p + nxt) / 2, nxt), Color = bark, Material = Enum.Material.Wood, Parent = f })
			p = nxt
		end
		-- 가지가 가운데로 뻗어 지붕이 된다
		local tip = at + Vector3.new(math.cos(a) * 12, 52 + (k % 3) * 3, math.sin(a) * 12)
		part({ Name = "GroveBough", Size = Vector3.new(2.6, 2.6, (tip - p).Magnitude), CFrame = CFrame.lookAt((p + tip) / 2, tip), Color = bark, Material = Enum.Material.Wood, Parent = f })
		part({ Name = "GroveLeaves", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 0.6, 1) * rng:NextNumber(24, 32), Position = p:Lerp(tip, 0.6) + Vector3.new(0, 5, 0), Color = moss:Lerp(Color3.fromRGB(120, 170, 80), rng:NextNumber()), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
		-- 뿌리 둘
		for _, s in ipairs({ -1, 1 }) do
			local rp = base + Vector3.new(math.cos(a + s * 0.5) * 9, 0.8, math.sin(a + s * 0.5) * 9)
			part({ Name = "GroveRoot", Size = Vector3.new(2.4, 2, 12), CFrame = CFrame.lookAt(rp, base + Vector3.new(0, 3, 0)), Color = bark, Material = Enum.Material.Wood, Parent = f })
		end
		-- 늘어진 덩굴
		for v = 0, 1 do
			local hang = tip:Lerp(p, 0.3 + v * 0.3)
			part({ Name = "GroveVine", Size = Vector3.new(0.3, 14, 0.3), Position = hang - Vector3.new(0, 7, 0), Color = Color3.fromRGB(60, 110, 50), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
		end
	end
	-- 가운데: 작은 못과 이끼 덮인 돌 좌대
	disc("GrovePond", at + Vector3.new(14, 0.25, 10), 8, 0.2, Color3.fromRGB(70, 140, 150), Enum.Material.Glass, f, false).Transparency = 0.2
	disc("GroveSeat", at + Vector3.new(0, 1.2, 0), 7, 2.4, Color3.fromRGB(120, 120, 110), Enum.Material.Slate, f)
	disc("GroveSeatMoss", at + Vector3.new(0, 2.45, 0), 6.4, 0.2, moss, Enum.Material.Grass, f, false)
	-- 빛나는 버섯과 반딧불
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2 + 0.2
		local mp = at + Vector3.new(math.cos(a) * rng:NextNumber(16, 34), 0, math.sin(a) * rng:NextNumber(16, 34))
		part({ Name = "GroveShroomStem", Size = Vector3.new(0.5, 1.4, 0.5), Position = mp + Vector3.new(0, 0.7, 0), Color = Color3.fromRGB(230, 225, 210), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
		local cap = part({ Name = "GroveShroom", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 0.8, 1.8), Position = mp + Vector3.new(0, 1.5, 0), Color = Color3.fromRGB(140, 255, 190), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		if k % 3 == 0 then
			light(cap, Color3.fromRGB(140, 255, 190), 10, 0.8)
		end
	end
	local flies = part({ Name = "GroveFireflies", Size = Vector3.new(90, 30, 90), Position = at + Vector3.new(0, 16, 0), Transparency = 1, CanCollide = false, Parent = f })
	emitter(flies, Color3.fromRGB(220, 255, 150), 18, 0.35, 1.5, 6)
	local board = part({ Name = "GroveSign", Size = Vector3.new(10, 2.6, 0.4), CFrame = CFrame.lookAt(at + Vector3.new(0, 4.5, 60), at + Vector3.new(0, 4.5, 90)), Color = Color3.fromRGB(60, 45, 30), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(board, Enum.NormalId.Front, { { "만목원", Color3.fromRGB(200, 255, 170), 1 } })
	part({ Name = "GroveSignPost", Size = Vector3.new(0.6, 4, 0.6), Position = at + Vector3.new(0, 2, 60), Color = bark, Material = Enum.Material.Wood, Parent = f })
end

-- 잠든 석장: 옛 싸움에서 쓰러진 거대한 돌 장수. 누운 몸통, 떨어진 투구 머리, 땅에 꽂힌 부러진 칼, 둘레의 돌 조각
function LANDMARK.fallengiant(at: Vector3, f: Instance)
	local stone = Color3.fromRGB(150, 145, 135)
	local dark = Color3.fromRGB(110, 106, 98)
	local yaw = CFrame.Angles(0, math.rad(25), 0)
	local base = CFrame.new(at) * yaw
	-- 누운 몸통과 팔다리 (반쯤 땅에 묻혔다)
	part({ Name = "GiantChest", Size = Vector3.new(26, 12, 40), CFrame = base * CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.rad(8)), Color = stone, Material = Enum.Material.Slate, Parent = f })
	part({ Name = "GiantPlate", Size = Vector3.new(22, 2, 30), CFrame = base * CFrame.new(-1, 10.5, 2) * CFrame.Angles(0, 0, math.rad(8)), Color = dark, Material = Enum.Material.Slate, Parent = f })
	for _, s in ipairs({ -1, 1 }) do
		part({ Name = "GiantArm", Size = Vector3.new(8, 7, 30), CFrame = base * CFrame.new(s * 18, 2.5, -6) * CFrame.Angles(0, s * math.rad(20), 0), Color = stone, Material = Enum.Material.Slate, Parent = f })
		part({ Name = "GiantLeg", Size = Vector3.new(9, 8, 34), CFrame = base * CFrame.new(s * 7, 2, 36) * CFrame.Angles(0, s * math.rad(6), 0), Color = dark, Material = Enum.Material.Slate, Parent = f })
	end
	-- 떨어져 굴러간 투구 머리
	local head = base * CFrame.new(-6, 7, -36)
	part({ Name = "GiantHead", Shape = Enum.PartType.Ball, Size = Vector3.new(15, 15, 15), CFrame = head, Color = stone, Material = Enum.Material.Slate, Parent = f })
	part({ Name = "GiantHelm", Size = Vector3.new(16, 6, 16), CFrame = head * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(20), 0, math.rad(-30)), Color = dark, Material = Enum.Material.Slate, Parent = f })
	for _, s in ipairs({ -1, 1 }) do
		part({ Name = "GiantEye", Size = Vector3.new(2, 1, 0.6), CFrame = head * CFrame.new(s * 3, 0, -7.4), Color = Color3.fromRGB(60, 58, 55), Material = Enum.Material.Slate, Parent = f })
	end
	-- 부러진 큰 칼 (땅에 비스듬히 꽂혔다)
	part({ Name = "GiantBlade", Size = Vector3.new(4, 46, 1.5), CFrame = base * CFrame.new(30, 18, 10) * CFrame.Angles(math.rad(15), 0, math.rad(-18)), Color = Color3.fromRGB(120, 125, 135), Material = Enum.Material.Metal, Parent = f })
	part({ Name = "GiantGuard", Size = Vector3.new(14, 2.4, 3), CFrame = base * CFrame.new(23.5, 39, 15.5) * CFrame.Angles(math.rad(15), 0, math.rad(-18)), Color = Color3.fromRGB(150, 120, 70), Material = Enum.Material.Metal, Parent = f })
	-- 둘레의 돌 조각과 풀
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		rock(at + Vector3.new(math.cos(a) * rng:NextNumber(40, 60), 0, math.sin(a) * rng:NextNumber(40, 60)), rng:NextNumber(3, 7), f, stone)
	end
end

-- 별바위 고리: 열두 선돌이 둥글게 서 있고, 가운데 돌단 위에서 별빛이 피어오른다
function LANDMARK.stonecircle(at: Vector3, f: Instance)
	local stone = Color3.fromRGB(120, 118, 130)
	local glow = Color3.fromRGB(170, 200, 255)
	disc("CircleFloor", at + Vector3.new(0, 0.2, 0), 34, 0.4, Color3.fromRGB(105, 120, 90), Enum.Material.Grass, f, false)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * 28, 0, math.sin(a) * 28)
		local h = 14 + (k % 3) * 4
		part({ Name = "Menhir", Size = Vector3.new(4.5, h, 3), CFrame = CFrame.lookAt(p + Vector3.new(0, h / 2, 0), at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad((k % 2 == 0 and 1 or -1) * 3)), Color = stone:Lerp(Color3.new(0, 0, 0), (k % 3) * 0.06), Material = Enum.Material.Slate, Parent = f })
		-- 선돌 앞의 빛나는 문양
		part({ Name = "MenhirRune", Size = Vector3.new(1.4, 1.4, 0.2), CFrame = CFrame.lookAt(p + (at - p).Unit * 1.6 + Vector3.new(0, 6, 0), at + Vector3.new(0, 6, 0)), Color = glow, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		-- 셋마다 위에 돌 들보
		if k % 3 == 0 then
			local q = at + Vector3.new(math.cos(a + math.pi / 12) * 28, 0, math.sin(a + math.pi / 12) * 28)
			part({ Name = "Lintel", Size = Vector3.new(4, 3, 9), CFrame = CFrame.lookAt(q + Vector3.new(0, h + 1.5, 0), at + Vector3.new(0, h + 1.5, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = stone, Material = Enum.Material.Slate, Parent = f })
		end
	end
	disc("CircleAltar", at + Vector3.new(0, 1, 0), 7, 2, stone, Enum.Material.Slate, f)
	disc("CircleAltarRing", at + Vector3.new(0, 2.05, 0), 5.5, 0.1, glow, Enum.Material.Neon, f, false).Transparency = 0.4
	local core = part({ Name = "CircleStar", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), Position = at + Vector3.new(0, 6, 0), Color = glow, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	light(core, glow, 30, 1.6)
	emitter(core, glow, 10, 0.5, 3, 3)
end

-- 옛 봉화대: 언덕 위 무너진 성벽 사이에 선 높은 돌탑. 꼭대기에 아직 꺼지지 않은 봉화
function LANDMARK.beacon(at: Vector3, f: Instance)
	local stone = Color3.fromRGB(140, 130, 115)
	disc("BeaconMound", at + Vector3.new(0, 1.5, 0), 32, 3, Color3.fromRGB(95, 110, 70), Enum.Material.Grass, f)
	for k = 0, 4 do
		local w = 12 - k * 1.4
		part({ Name = "BeaconTier", Size = Vector3.new(w, 8, w), Position = at + Vector3.new(0, 7 + k * 8, 0), Color = stone:Lerp(Color3.new(0, 0, 0), k * 0.04), Material = Enum.Material.Cobblestone, Parent = f })
	end
	part({ Name = "BeaconTop", Size = Vector3.new(9, 1.2, 9), Position = at + Vector3.new(0, 43.6, 0), Color = stone, Material = Enum.Material.Cobblestone, Parent = f })
	for _, c in ipairs({ Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) }) do
		part({ Name = "BeaconMerlon", Size = Vector3.new(1.6, 2.4, 1.6), Position = at + c * 3.8 + Vector3.new(0, 45.4, 0), Color = stone, Material = Enum.Material.Cobblestone, Parent = f })
	end
	brazier(at + Vector3.new(0, 44.2, 0), 2, f)
	-- 무너진 성벽 조각들
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		if k % 3 ~= 1 then
			local p = at + Vector3.new(math.cos(a) * 24, 0, math.sin(a) * 24)
			local h = rng:NextNumber(3, 9)
			part({ Name = "BeaconWall", Size = Vector3.new(12, h, 2.4), CFrame = CFrame.lookAt(p + Vector3.new(0, 3 + h / 2, 0), at + Vector3.new(0, 3 + h / 2, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = stone, Material = Enum.Material.Cobblestone, Parent = f })
		end
	end
	banner(at + Vector3.new(8, 3, 8), 10, Color3.fromRGB(170, 50, 40), f)
end

-- 버려진 마을: 들판 가운데 오래전 비워진 집 다섯, 우물, 무너진 울타리, 묵은 밭
function LANDMARK.hamlet(at: Vector3, f: Instance)
	local spots = { { -24, -14, 0 }, { 18, -20, 90 }, { -20, 18, 180 }, { 24, 16, -90 }, { 0, 32, 180 } }
	for _, s in ipairs(spots) do
		house(at + Vector3.new(s[1], 0, s[2]), 14, 11, s[3], f)
	end
	-- 우물
	cyl("WellRing", at + Vector3.new(0, 1.4, 0), 3.2, 2.8, Color3.fromRGB(130, 125, 115), Enum.Material.Cobblestone, f)
	disc("WellWater", at + Vector3.new(0, 2.5, 0), 2.6, 0.1, Color3.fromRGB(50, 80, 90), Enum.Material.Glass, f, false)
	for _, x in ipairs({ -1, 1 }) do
		part({ Name = "WellPost", Size = Vector3.new(0.6, 6, 0.6), Position = at + Vector3.new(x * 3, 3, 0), Color = Color3.fromRGB(90, 65, 40), Material = Enum.Material.Wood, Parent = f })
	end
	part({ Name = "WellRoof", Size = Vector3.new(8, 0.5, 4), CFrame = CFrame.new(at + Vector3.new(0, 6.4, 0)) * CFrame.Angles(0, 0, 0), Color = Color3.fromRGB(80, 60, 45), Material = Enum.Material.Wood, Parent = f })
	-- 묵은 밭 (이랑)과 허수아비
	for k = 0, 5 do
		part({ Name = "FieldRow", Size = Vector3.new(26, 0.8, 1.6), Position = at + Vector3.new(-50, 0.4, -10 + k * 4), Color = Color3.fromRGB(110, 85, 55), Material = Enum.Material.Ground, CanCollide = false, Parent = f })
		if k % 2 == 0 then
			for j = 0, 4 do
				part({ Name = "FieldWeed", Size = Vector3.new(0.4, 1.4, 0.4), Position = at + Vector3.new(-60 + j * 5, 1.2, -10 + k * 4), Color = Color3.fromRGB(150, 140, 70), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
			end
		end
	end
	part({ Name = "ScarecrowPost", Size = Vector3.new(0.5, 7, 0.5), Position = at + Vector3.new(-50, 3.5, 2), Color = Color3.fromRGB(100, 75, 45), Material = Enum.Material.Wood, Parent = f })
	part({ Name = "ScarecrowArms", Size = Vector3.new(6, 0.4, 0.4), Position = at + Vector3.new(-50, 5.5, 2), Color = Color3.fromRGB(100, 75, 45), Material = Enum.Material.Wood, Parent = f })
	part({ Name = "ScarecrowHat", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 3.6, 3.6), CFrame = CFrame.new(at + Vector3.new(-50, 7.3, 2)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(200, 170, 110), Material = Enum.Material.Fabric, Parent = f })
	-- 무너진 울타리
	for k = 0, 9 do
		if k % 4 ~= 2 then
			local a = k / 10 * math.pi * 2
			local p = at + Vector3.new(math.cos(a) * 46, 0, math.sin(a) * 46)
			part({ Name = "OldFence", Size = Vector3.new(0.4, 2.6, 9), CFrame = CFrame.lookAt(p + Vector3.new(0, 1.3, 0), at + Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, math.rad(90), math.rad((k % 3 - 1) * 8)), Color = Color3.fromRGB(95, 70, 45), Material = Enum.Material.Wood, Parent = f })
		end
	end
	tree(at + Vector3.new(30, 0, -36), 1.8, f)
	tree(at + Vector3.new(-36, 0, 34), 1.6, f)
end

-- 하늘 아치: 들판에 홀로 선 거대한 바위 아치. 위에서 덩굴과 작은 폭포가 흘러내린다
function LANDMARK.archway(at: Vector3, f: Instance)
	local rock2 = Color3.fromRGB(150, 115, 90)
	local n = 11
	for k = 0, n do
		local u = k / n
		local a = math.pi * u
		local p = at + Vector3.new(math.cos(a) * 34, math.sin(a) * 40, 0)
		local w = 14 - math.sin(a) * 5
		part({ Name = "ArchStone", Size = Vector3.new(w, 12, 12), CFrame = CFrame.new(p) * CFrame.Angles(0, 0, a + math.pi / 2) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0), Color = rock2:Lerp(Color3.fromRGB(110, 85, 70), rng:NextNumber()), Material = Enum.Material.Sandstone, Parent = f })
	end
	-- 꼭대기의 풀과 늘어진 덩굴
	disc("ArchTopGrass", at + Vector3.new(0, 46.5, 0), 7, 0.6, Color3.fromRGB(90, 140, 60), Enum.Material.Grass, f, false)
	for k = -3, 3 do
		part({ Name = "ArchVine", Size = Vector3.new(0.35, 10 + (k % 2) * 6, 0.35), Position = at + Vector3.new(k * 2.6, 36 - (k % 2) * 3, rng:NextNumber(-3, 3)), Color = Color3.fromRGB(70, 120, 50), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
	end
	-- 아치 아래로 흘러내리는 가는 폭포와 웅덩이
	local fall = part({ Name = "ArchFall", Size = Vector3.new(3, 30, 0.6), Position = at + Vector3.new(6, 20, 4), Color = Color3.fromRGB(170, 215, 240), Material = Enum.Material.Glass, CanCollide = false, Parent = f })
	fall.Transparency = 0.3
	emitter(fall, Color3.fromRGB(220, 240, 255), 14, 0.6, 2, 1)
	disc("ArchPool", at + Vector3.new(6, 0.25, 4), 9, 0.2, Color3.fromRGB(80, 150, 170), Enum.Material.Glass, f, false).Transparency = 0.2
	for k = 0, 5 do
		rock(at + Vector3.new(rng:NextNumber(-50, 50), 0, rng:NextNumber(-30, 30)), rng:NextNumber(3, 6), f, rock2)
	end
end

------------------------------------------------------------------------
-- 2.4판: 들판 채우기. 지역·길·랜드마크에서 떨어진 빈 땅에 작은 숲, 바위 무더기, 꽃밭, 덤불을 모아 놓는다 (늘 같은 자리)
------------------------------------------------------------------------
local function wilds()
	local f = Instance.new("Folder")
	f.Name = "Wilds"
	f.Parent = folder
	local R = Random.new(2404)
	local W = Config.WORLD_HALF
	local made = 0
	local flowers = { Color3.fromRGB(255, 220, 90), Color3.fromRGB(240, 120, 160), Color3.fromRGB(180, 140, 255), Color3.fromRGB(255, 255, 255) }
	for _ = 1, 500 do
		if made >= 120 then
			break
		end
		local c = Vector3.new(R:NextNumber(-W + 500, W - 500), 0, R:NextNumber(-W + 500, W - 500))
		if not inAnyRegion(c, 60) and not nearFeature(c, 60) and not nearRoad(c, 30) then
			made += 1
			local kind = made % 5
			if kind == 0 or kind == 1 then
				-- 작은 숲 (나무 셋~다섯, 덤불)
				local n = 3 + made % 3
				for k = 0, n - 1 do
					local a = k / n * math.pi * 2 + made
					local p = c + Vector3.new(math.cos(a), 0, math.sin(a)) * R:NextNumber(6, 16)
					if made % 7 == 0 then
						pine(p, R:NextNumber(1.1, 1.6), f, false)
					else
						tree(p, R:NextNumber(1.1, 1.7), f, made % 9 == 0)
					end
				end
				bush(c + Vector3.new(4, 0, 3), 2.4, Color3.fromRGB(70, 120, 50), f)
			elseif kind == 2 then
				-- 바위 무더기
				for k = 0, 3 do
					rock(c + Vector3.new(R:NextNumber(-8, 8), 0, R:NextNumber(-8, 8)), R:NextNumber(2.5, 6), f)
				end
				bush(c + Vector3.new(-5, 0, 5), 1.8, Color3.fromRGB(80, 115, 55), f)
			elseif kind == 3 then
				-- 꽃밭 (작은 꽃 열둘)
				local col = flowers[made % #flowers + 1]
				for k = 0, 11 do
					local p = c + Vector3.new(R:NextNumber(-9, 9), 0, R:NextNumber(-9, 9))
					part({ Name = "Flower", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 0.5, 1), Position = p + Vector3.new(0, 0.6, 0), Color = col, Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
					part({ Name = "FlowerStem", Size = Vector3.new(0.15, 0.6, 0.15), Position = p + Vector3.new(0, 0.3, 0), Color = Color3.fromRGB(70, 130, 50), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
				end
			else
				-- 덤불과 쓰러진 통나무
				for k = 0, 2 do
					bush(c + Vector3.new(R:NextNumber(-7, 7), 0, R:NextNumber(-7, 7)), R:NextNumber(1.6, 2.8), Color3.fromRGB(75, 125, 55), f)
				end
				part({ Name = "Log", Shape = Enum.PartType.Cylinder, Size = Vector3.new(9, 1.6, 1.6), CFrame = CFrame.new(c + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, R:NextNumber(0, 3), 0), Color = Color3.fromRGB(95, 70, 45), Material = Enum.Material.Wood, Parent = f })
			end
		end
	end
end

local function sakuraHill()
	local at = Config.SAKURA_HILL
	if not at then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "SakuraHill"
	f.Parent = folder
	local pink = Color3.fromRGB(255, 175, 210)
	-- 세 겹의 둥근 돌 단 (위로 갈수록 좁다)
	for i, r in ipairs({ 22, 17, 12 }) do
		disc("SakuraTerrace", at + Vector3.new(0, (i - 0.5) * 1.55, 0), r, 1.55, Color3.fromRGB(190, 180, 175):Lerp(Color3.fromRGB(230, 215, 215), i * 0.2), Enum.Material.Granite, f)
	end
	-- 오르는 돌계단 (남쪽)
	for k = 0, 5 do
		part({ Name = "SakuraStep", Size = Vector3.new(8, 0.8, 2.2), Position = at + Vector3.new(0, 0.4 + k * 0.78, 23 - k * 2.2), Color = Color3.fromRGB(200, 190, 185), Material = Enum.Material.Granite, Parent = f })
	end
	-- 거대한 벚나무: 굵은 줄기, 갈라진 가지, 분홍 꽃구름
	local base = at + Vector3.new(-6, 4.6, -6)
	part({ Name = "SakuraTrunk", Size = Vector3.new(3.4, 16, 3.4), CFrame = CFrame.new(base + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(6)), Color = Color3.fromRGB(80, 50, 45), Material = Enum.Material.Wood, Parent = f })
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		local from = base + Vector3.new(0, 13, 0)
		local to = from + Vector3.new(math.cos(a) * 9, 5 + (k % 2) * 2, math.sin(a) * 9)
		part({ Name = "SakuraBranch", Size = Vector3.new(1.4, 1.4, (to - from).Magnitude), CFrame = CFrame.lookAt((from + to) / 2, to), Color = Color3.fromRGB(85, 55, 48), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
		for j = 0, 2 do
			part({ Name = "SakuraBloom", Shape = Enum.PartType.Ball, Size = Vector3.one * (9 - j * 1.5), Position = to + Vector3.new(math.cos(a + j) * 2.5, j * 1.5 - 1, math.sin(a + j) * 2.5),
				Color = pink:Lerp(Color3.new(1, 1, 1), (j % 2) * 0.25 + (k % 2) * 0.1), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
		end
	end
	local crown = part({ Name = "SakuraCrown", Shape = Enum.PartType.Ball, Size = Vector3.one * 14, Position = base + Vector3.new(0, 21, 0), Color = pink, Material = Enum.Material.Grass, CanCollide = false, Parent = f })
	-- 꽃잎이 언덕 가득 흩날린다
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 200, 225), Color3.fromRGB(255, 150, 195))
	pe.Size = NumberSequence.new(0.5, 0.3)
	pe.Squash = NumberSequence.new(0.5)
	pe.Lifetime = NumberRange.new(5, 8)
	pe.Rate = 40
	pe.Speed = NumberRange.new(1, 3)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(1.2, -1.5, 0.6)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-120, 120)
	pe.LightEmission = 0.3
	pe.Parent = crown
	light(crown, pink, 40, 1.2)
	-- 땅에 깔린 꽃잎 (분홍 얼룩)
	for k = 0, 13 do
		local a = k / 14 * math.pi * 2
		disc("FallenPetals", at + Vector3.new(math.cos(a) * (26 + (k % 3) * 4), 0.05, math.sin(a) * (26 + (k % 3) * 4)), 3 + (k % 3), 0.1, pink:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.SmoothPlastic, f, false)
	end
	for _, sx in ipairs({ -1, 1 }) do
		stoneLantern(at + Vector3.new(sx * 6, 0, 26), f, true)
	end
end

-- 술독 마루: 초·취팔선권의 만취선이 코를 고는 나무 마루. 둘레에 술독이 산처럼 쌓이고, 하나는 엎어져 웅덩이가 졌다
local function sojuHill()
	local at = Config.SOJU_HILL
	if not at then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "SojuHill"
	f.Parent = folder
	local plank = Color3.fromRGB(120, 85, 55)
	local clay = Color3.fromRGB(125, 75, 45)
	local green = Color3.fromRGB(70, 170, 95)
	-- 두 겹의 둥근 나무 마루
	disc("SojuDeck", at + Vector3.new(0, 0.8, 0), 16, 1.6, plank, Enum.Material.WoodPlanks, f)
	disc("SojuDeck", at + Vector3.new(0, 2.4, 0), 11, 1.6, plank:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.WoodPlanks, f)
	for k = 0, 2 do
		part({ Name = "SojuStep", Size = Vector3.new(7, 0.8, 2.2), Position = at + Vector3.new(0, 0.4 + k * 1.05, 18 - k * 2.4), Color = plank, Material = Enum.Material.Wood, Parent = f })
	end
	-- 술독: 배가 불룩한 항아리 (몸통 + 어깨 + 검은 뚜껑)
	local function jar(p: Vector3, size: number, tipped: boolean?)
		local cf = CFrame.new(p + Vector3.new(0, size * 0.7, 0))
		if tipped then
			cf = CFrame.new(p + Vector3.new(0, size * 0.75, 0)) * CFrame.Angles(0, math.random() * 6, math.rad(90))
		end
		part({ Name = "SojuJar", Shape = Enum.PartType.Ball, Size = Vector3.new(size * 1.5, size * 1.5, size * 1.5), CFrame = cf, Color = clay, Material = Enum.Material.Slate, Parent = f })
		part({ Name = "SojuJarNeck", Shape = Enum.PartType.Cylinder, Size = Vector3.new(size * 0.5, size * 0.9, size * 0.9), CFrame = cf * CFrame.new(0, size * 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = clay:Lerp(Color3.new(0, 0, 0), 0.15), Material = Enum.Material.Slate, Parent = f })
		if not tipped then
			part({ Name = "SojuJarLid", Shape = Enum.PartType.Cylinder, Size = Vector3.new(size * 0.15, size * 1.0, size * 1.0), CFrame = cf * CFrame.new(0, size * 1.02, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 30, 25), Material = Enum.Material.Wood, Parent = f })
		end
	end
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2 + 0.3
		if math.abs(a - math.pi / 2) > 0.45 then -- 계단 쪽(남)은 비운다
			local r = 20 + (k % 3) * 2
			local p = at + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			jar(p, 2.2 + (k % 3) * 0.5)
			if k % 2 == 0 then
				jar(p + Vector3.new(0, 3.2 + (k % 3) * 0.7, 0), 1.6)
			end
		end
	end
	-- 엎어진 큰 술독과 웅덩이
	local tip = at + Vector3.new(-12, 3.2, -4)
	jar(tip, 2.4, true)
	disc("SojuPuddle", at + Vector3.new(-12, 3.25, 1), 3.4, 0.05, Color3.fromRGB(190, 225, 200), Enum.Material.Glass, f, false).Transparency = 0.35
	-- 낮은 술상과 초록 병 몇 개 (상표 없는 빈 병)
	part({ Name = "SojuTable", Size = Vector3.new(5, 0.5, 3), Position = at + Vector3.new(5, 4.2, -3), Color = Color3.fromRGB(90, 55, 35), Material = Enum.Material.Wood, Parent = f })
	for _, o in ipairs({ { 3.6, 0 }, { 4.6, 0.6 }, { 6.2, -0.4 } }) do
		part({ Name = "SojuBottle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 0.55, 0.55), CFrame = CFrame.new(at + Vector3.new(o[1], 5.15, -3 + o[2])) * CFrame.Angles(0, 0, math.rad(90)), Color = green, Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, Parent = f })
	end
	part({ Name = "SojuBottle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 0.55, 0.55), CFrame = CFrame.new(at + Vector3.new(3, 3.5, 4)) * CFrame.Angles(math.rad(90), 0.4, 0), Color = green, Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, Parent = f })
	-- 붉은 종이 등 (마루 네 귀퉁이, 장대에 매달아)
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + math.pi / 4
		local p = at + Vector3.new(math.cos(a) * 14, 0, math.sin(a) * 14)
		part({ Name = "SojuPole", Size = Vector3.new(0.6, 10, 0.6), Position = p + Vector3.new(0, 6.6, 0), Color = Color3.fromRGB(60, 40, 28), Material = Enum.Material.Wood, Parent = f })
		local lamp = part({ Name = "SojuLamp", Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.6, 2.2), Position = p + Vector3.new(0, 10.6, 0), Color = Color3.fromRGB(235, 70, 50), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		light(lamp, Color3.fromRGB(255, 140, 90), 22, 1.2)
	end
	local board = part({ Name = "SojuSign", Size = Vector3.new(10, 2.6, 0.4), CFrame = CFrame.lookAt(at + Vector3.new(0, 4.5, 21.5), at + Vector3.new(0, 4.5, 40)), Color = Color3.fromRGB(35, 25, 18), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(board, Enum.NormalId.Front, { { "술독 마루", Color3.fromRGB(190, 255, 200), 1 } })
	part({ Name = "SojuSignPost", Size = Vector3.new(0.6, 4, 0.6), Position = at + Vector3.new(0, 2, 21.5), Color = Color3.fromRGB(60, 40, 28), Material = Enum.Material.Wood, Parent = f })
end

-- 1.9판: 초·혈마신수의 사부 혈월선이 있는 혈월 제단 (혈교 본산 성벽 밖 북동쪽 끝, 지도에 나오지 않는다)
-- 핏빛 돌단 위, 땅에 거꾸로 꽂힌 거대한 붉은 낫과 핏빛 달 모양의 둥근 문
local function reaperAltar()
	local at = Config.REAPER_ALTAR
	if not at then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "ReaperAltar"
	f.Parent = folder
	local stone = Color3.fromRGB(45, 22, 24)
	local blood = Color3.fromRGB(200, 20, 35)
	disc("ReaperBase", at + Vector3.new(0, 0.8, 0), 22, 1.6, stone, Enum.Material.Slate, f)
	disc("ReaperBase", at + Vector3.new(0, 2.4, 0), 15, 1.6, stone:Lerp(Color3.new(0, 0, 0), 0.2), Enum.Material.Basalt, f)
	disc("ReaperRune", at + Vector3.new(0, 3.25, 0), 12, 0.1, blood, Enum.Material.Neon, f, false).Transparency = 0.35
	for k = 0, 2 do
		part({ Name = "ReaperStep", Size = Vector3.new(8, 0.8, 2.4), Position = at + Vector3.new(0, 0.4 + k * 1.05, 24 - k * 2.6), Color = stone, Material = Enum.Material.Slate, Parent = f })
	end
	-- 돌단을 두른 핏빛 돌기둥 여덟과 그 위의 불
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2 + math.pi / 8
		if math.abs(a - math.pi / 2) > 0.3 then
			local p = at + Vector3.new(math.cos(a) * 19, 0, math.sin(a) * 19)
			local h = 9 + (k % 3) * 2
			part({ Name = "ReaperPillar", Size = Vector3.new(2.4, h, 2.4), CFrame = CFrame.new(p + Vector3.new(0, h / 2 + 1.6, 0)) * CFrame.Angles(0, a, math.rad((k % 2 == 0 and 1 or -1) * 4)), Color = stone, Material = Enum.Material.Basalt, Parent = f })
			local flame = part({ Name = "ReaperFlame", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), Position = p + Vector3.new(0, h + 2.6, 0), Color = blood, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			light(flame, Color3.fromRGB(255, 60, 60), 18, 1.2)
		end
	end
	-- 거꾸로 꽂힌 거대한 붉은 낫 (자루는 하늘로, 날은 돌단에 박혔다)
	local shaftCF = CFrame.new(at + Vector3.new(-6, 14, -6)) * CFrame.Angles(math.rad(8), math.rad(35), math.rad(-6))
	part({ Name = "ReaperShaft", Size = Vector3.new(1.1, 26, 1.1), CFrame = shaftCF, Color = Color3.fromRGB(30, 12, 14), Material = Enum.Material.Wood, Parent = f })
	for k = -2, 2 do
		part({ Name = "ReaperWrap", Size = Vector3.new(1.3, 0.5, 1.3), CFrame = shaftCF * CFrame.new(0, k * 4.5, 0), Color = Color3.fromRGB(120, 15, 25), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
	end
	local head = shaftCF * CFrame.new(0, -12.5, 0)
	for k = 0, 6 do
		local seg = part({ Name = "ReaperBlade", Size = Vector3.new(0.5, 2.2 - k * 0.22, 3.4), CFrame = head * CFrame.Angles(0, 0, math.rad(-12 * k)) * CFrame.new(0, -0.6, -2.6 - k * 2.8), Color = blood, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		seg.Transparency = 0.05
	end
	-- 핏빛 달 모양의 둥근 문 (돌단 뒤)
	local gateC = at + Vector3.new(0, 15, -14)
	local n = 22
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		part({ Name = "ReaperMoon", Size = Vector3.new(2.6, 1.6, 2.2), CFrame = CFrame.new(gateC) * CFrame.Angles(0, 0, a) * CFrame.new(0, 10, 0), Color = k % 2 == 0 and Color3.fromRGB(150, 15, 25) or stone, Material = k % 2 == 0 and Enum.Material.Neon or Enum.Material.Slate, CanCollide = false, Parent = f })
	end
	local moon = part({ Name = "ReaperMoonCore", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 18, 18), CFrame = CFrame.new(gateC) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(170, 20, 30), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	moon.Transparency = 0.55
	light(moon, Color3.fromRGB(255, 50, 50), 40, 1.5)
	local board = part({ Name = "ReaperSign", Size = Vector3.new(10, 2.6, 0.4), CFrame = CFrame.lookAt(at + Vector3.new(0, 4.5, 27), at + Vector3.new(0, 4.5, 50)), Color = Color3.fromRGB(30, 12, 14), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(board, Enum.NormalId.Front, { { "혈월 제단", Color3.fromRGB(255, 120, 120), 1 } })
	part({ Name = "ReaperSignPost", Size = Vector3.new(0.6, 4, 0.6), Position = at + Vector3.new(0, 2, 27), Color = Color3.fromRGB(40, 20, 20), Material = Enum.Material.Wood, Parent = f })
end

-- 2.0판: 초·벽력신권의 사부 뇌천선이 있는 쇠기둥 봉우리 (뇌운 고원 동쪽 벼랑 끝, 지도에 나오지 않는다)
-- 바위 봉우리 위 둥근 쇠 단, 둘레에 피뢰침 쇠기둥, 가운데 높은 쇠탑 꼭대기에서 보랏빛 번개가 늘 튄다
local function thunderPeak()
	local at = Config.THUNDER_PEAK
	if not at then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "ThunderPeak"
	f.Parent = folder
	local rock = Color3.fromRGB(80, 78, 92)
	local iron = Color3.fromRGB(55, 58, 70)
	local bolt = Color3.fromRGB(170, 140, 255)
	-- 층진 바위 봉우리
	for k = 0, 2 do
		disc("PeakRock", at + Vector3.new(0, 1 + k * 2, 0), 22 - k * 5, 2.2, rock:Lerp(Color3.new(0, 0, 0), k * 0.08), Enum.Material.Slate, f)
	end
	disc("PeakPlate", at + Vector3.new(0, 6.2, 0), 9, 0.4, iron, Enum.Material.DiamondPlate, f)
	disc("PeakRune", at + Vector3.new(0, 6.45, 0), 7, 0.1, bolt, Enum.Material.Neon, f, false).Transparency = 0.4
	-- 오르는 돌계단 (남쪽)
	for k = 0, 5 do
		part({ Name = "PeakStep", Size = Vector3.new(6, 1, 2.4), Position = at + Vector3.new(0, 0.5 + k * 1.05, 23 - k * 2.4), Color = rock, Material = Enum.Material.Slate, Parent = f })
	end
	-- 피뢰침 쇠기둥 여섯 (꼭대기에 빛)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		if math.abs(a - math.pi / 2) > 0.35 then
			local p = at + Vector3.new(math.cos(a) * 15, 0, math.sin(a) * 15)
			local h = 14 + (k % 2) * 4
			part({ Name = "PeakRod", Size = Vector3.new(0.9, h, 0.9), Position = p + Vector3.new(0, 4 + h / 2, 0), Color = iron, Material = Enum.Material.Metal, Parent = f })
			local tip = part({ Name = "PeakSpark", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), Position = p + Vector3.new(0, 4.6 + h, 0), Color = bolt, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			light(tip, bolt, 16, 1.4)
		end
	end
	-- 가운데 쇠탑 (뒤쪽)
	local tower = at + Vector3.new(0, 0, -6)
	for k = 0, 3 do
		part({ Name = "PeakTower", Size = Vector3.new(2.6 - k * 0.5, 7, 2.6 - k * 0.5), Position = tower + Vector3.new(0, 9.5 + k * 7, 0), Color = iron, Material = Enum.Material.Metal, Parent = f })
	end
	local orb = part({ Name = "PeakOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(3.4, 3.4, 3.4), Position = tower + Vector3.new(0, 38, 0), Color = bolt, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	orb.Transparency = 0.1
	light(orb, bolt, 40, 2)
	local board = part({ Name = "PeakSign", Size = Vector3.new(10, 2.6, 0.4), CFrame = CFrame.lookAt(at + Vector3.new(0, 4.5, 26), at + Vector3.new(0, 4.5, 50)), Color = Color3.fromRGB(30, 28, 40), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(board, Enum.NormalId.Front, { { "쇠기둥 봉우리", Color3.fromRGB(210, 190, 255), 1 } })
	part({ Name = "PeakSignPost", Size = Vector3.new(0.6, 4, 0.6), Position = at + Vector3.new(0, 2, 26), Color = iron, Material = Enum.Material.Metal, Parent = f })
end

-- 3.4판: 초·성하신권의 사부 천성선이 선 관성대 (천상계 성운원 남쪽 끝, 지도에 나오지 않는다)
-- 두 단의 둥근 돌 관측대, 남쪽 계단, 가장자리의 별 등 여덟, 금빛 고리 셋이 엇갈린 혼천의, 떠 있는 별 수정
local function starTerrace()
	local at = Config.STAR_TERRACE
	if not at then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "StarTerrace"
	f.Parent = folder
	local stone = Color3.fromRGB(70, 66, 110)
	local stone2 = Color3.fromRGB(96, 90, 140)
	local brass = Color3.fromRGB(214, 176, 92)
	local star = Color3.fromRGB(255, 226, 120)
	local violet = Color3.fromRGB(170, 130, 255)
	disc("TerraceBase", at + Vector3.new(0, 0.7, 0), 16, 1.4, stone, Enum.Material.Slate, f)
	disc("TerraceTop", at + Vector3.new(0, 2.1, 0), 12, 1.4, stone2, Enum.Material.Marble, f)
	disc("TerraceInlay", at + Vector3.new(0, 2.82, 0), 9, 0.06, Color3.fromRGB(60, 50, 170), Enum.Material.Neon, f, false).Transparency = 0.4
	disc("TerraceInlayCore", at + Vector3.new(0, 2.84, 0), 3, 0.06, star, Enum.Material.Neon, f, false).Transparency = 0.2
	-- 남쪽 계단
	for k = 1, 3 do
		part({ Name = "TerraceStep", Size = Vector3.new(6, k * 0.95, 2.2), Position = at + Vector3.new(0, k * 0.475, 18.5 - k * 2.2), Color = stone, Material = Enum.Material.Slate, Parent = f })
	end
	-- 가장자리의 별 등 여덟
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2 + math.pi / 8
		local p = at + Vector3.new(math.cos(a) * 14.5, 1.4, math.sin(a) * 14.5)
		part({ Name = "StarLampPost", Size = Vector3.new(0.6, 5, 0.6), Position = p + Vector3.new(0, 2.5, 0), Color = brass, Material = Enum.Material.Metal, Parent = f })
		local orb = part({ Name = "StarLamp", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), Position = p + Vector3.new(0, 5.6, 0), Color = k % 2 == 0 and star or violet, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		light(orb, orb.Color, 14, 1.2)
	end
	-- 혼천의: 받침 위에 엇갈린 금빛 고리 셋, 가운데 별 구슬
	local arm = at + Vector3.new(-6, 2.8, -5)
	part({ Name = "ArmillaryStand", Size = Vector3.new(1.2, 5, 1.2), Position = arm + Vector3.new(0, 2.5, 0), Color = brass, Material = Enum.Material.Metal, Parent = f })
	local center = arm + Vector3.new(0, 9, 0)
	for ri, tilt in ipairs({ CFrame.Angles(0, 0, 0), CFrame.Angles(math.rad(90), 0, 0), CFrame.Angles(math.rad(60), math.rad(45), math.rad(30)) }) do
		local R = 4 - ri * 0.4
		for k = 0, 23 do
			local a0, a1 = k / 24 * math.pi * 2, (k + 1) / 24 * math.pi * 2
			local p0 = Vector3.new(math.cos(a0) * R, 0, math.sin(a0) * R)
			local p1 = Vector3.new(math.cos(a1) * R, 0, math.sin(a1) * R)
			part({ Name = "ArmillaryRing", Size = Vector3.new(0.25, 0.25, (p1 - p0).Magnitude * 1.08), CFrame = CFrame.new(center) * tilt * CFrame.lookAt((p0 + p1) / 2, p1), Color = brass, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
		end
	end
	local core = part({ Name = "ArmillaryStar", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), Position = center, Color = star, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	light(core, star, 24, 2)
	-- 떠 있는 별 수정
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		crystal(at + Vector3.new(math.cos(a) * 22, 9 + (k % 2) * 4, math.sin(a) * 22), 1.6, k % 2 == 0 and star or violet, f)
	end
	local board = part({ Name = "TerraceSign", Size = Vector3.new(8, 2.2, 0.4), CFrame = CFrame.lookAt(at + Vector3.new(4.5, 4, 22), at + Vector3.new(4.5, 4, 40)), Color = Color3.fromRGB(30, 28, 50), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(board, Enum.NormalId.Front, { { "관성대", star, 1 } })
	part({ Name = "TerraceSignPost", Size = Vector3.new(0.5, 3.4, 0.5), Position = at + Vector3.new(4.5, 1.7, 22), Color = brass, Material = Enum.Material.Metal, Parent = f })
end

-- 2.7판: 초·창해신권의 사부 고경선이 앉은 고래 뼈 바위 (서해 바닷가, 지도에 나오지 않는다)
-- 모래에 반쯤 묻힌 거대한 옛 고래의 머리뼈 (위가 평평해 사부가 앉는다), 앞으로 뻗은 두 턱뼈, 뒤로 이어진 등뼈와 갈비뼈 일곱 쌍,
-- 뼈 둘레의 물웅덩이와 따개비 바위, 머리뼈 위의 빛나는 진주
local function whaleRock()
	local at = Config.WHALE_ROCK
	if not at then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "WhaleRock"
	f.Parent = folder
	local bone = Color3.fromRGB(222, 214, 196)
	local bone2 = Color3.fromRGB(196, 188, 170)
	local sand = Color3.fromRGB(214, 200, 160)
	local sea = Color3.fromRGB(60, 140, 200)
	-- 모래 둔덕
	for k = 0, 2 do
		disc("WhaleSand", at + Vector3.new(0, 0.3 + k * 0.5, 4), 34 - k * 8, 0.8, sand:Lerp(Color3.new(0, 0, 0), k * 0.04), Enum.Material.Sand, f)
	end
	-- 물웅덩이 둘 (뼈 둘레)
	disc("WhalePool", at + Vector3.new(14, 0.55, -10), 7, 0.2, sea, Enum.Material.Glass, f, false).Transparency = 0.3
	disc("WhalePool", at + Vector3.new(-12, 0.55, 14), 5, 0.2, sea, Enum.Material.Glass, f, false).Transparency = 0.3
	-- 머리뼈: 둥근 덩이 위에 평평한 판 (사부가 앉는 자리)
	part({ Name = "WhaleSkull", Shape = Enum.PartType.Ball, Size = Vector3.new(12, 8, 16), Position = at + Vector3.new(0, 3.4, -6), Color = bone, Material = Enum.Material.Limestone, Parent = f })
	part({ Name = "WhaleSkullTop", Size = Vector3.new(8, 1, 9), Position = at + Vector3.new(0, 6.9, -6), Color = bone, Material = Enum.Material.Limestone, Parent = f })
	for _, x in ipairs({ -1, 1 }) do
		-- 눈구멍과 턱뼈 (앞으로 휘어 뻗는다)
		part({ Name = "WhaleEyeHole", Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2), Position = at + Vector3.new(x * 5.4, 4.2, -9), Color = Color3.fromRGB(70, 66, 60), Material = Enum.Material.Slate, CanCollide = false, Parent = f })
		local cf = CFrame.new(at + Vector3.new(x * 4.4, 1.6, -11)) * CFrame.Angles(0, x * math.rad(-8), 0)
		for j = 0, 3 do
			part({ Name = "WhaleJaw", Size = Vector3.new(1.4 - j * 0.15, 1.2 - j * 0.12, 4.4), CFrame = cf * CFrame.new(0, 0, -2.2), Color = j % 2 == 0 and bone or bone2, Material = Enum.Material.Limestone, Parent = f })
			cf = cf * CFrame.new(0, 0, -4.2) * CFrame.Angles(math.rad(4), x * math.rad(7), 0)
		end
	end
	-- 등뼈와 갈비뼈 일곱 쌍 (모래에서 솟아 둥글게 휘어 오른다)
	for i = 0, 6 do
		local z = 4 + i * 4.2
		local h = 9 - i * 0.8
		part({ Name = "WhaleSpine", Size = Vector3.new(2.2 - i * 0.15, 1.8 - i * 0.12, 3.4), Position = at + Vector3.new(0, h, z), Color = bone2, Material = Enum.Material.Limestone, CanCollide = false, Parent = f })
		part({ Name = "WhaleSpineFin", Size = Vector3.new(0.6, 1.6 - i * 0.12, 1.2), Position = at + Vector3.new(0, h + 1.5, z), Color = bone, Material = Enum.Material.Limestone, CanCollide = false, Parent = f })
		for _, x in ipairs({ -1, 1 }) do
			local w = 9 - i * 0.7
			local n = 6
			for k = 0, n - 1 do
				local a0 = (k / n) * math.pi * 0.5
				local a1 = ((k + 1) / n) * math.pi * 0.5
				local p0 = at + Vector3.new(x * w * math.cos(a0), (h - 0.6) * math.sin(a0) + 0.6, z)
				local p1 = at + Vector3.new(x * w * math.cos(a1), (h - 0.6) * math.sin(a1) + 0.6, z)
				local len = (p1 - p0).Magnitude + 0.5
				part({ Name = "WhaleRib", Size = Vector3.new(0.9 - k * 0.06, 0.9 - k * 0.06, len), CFrame = CFrame.lookAt((p0 + p1) / 2, p1), Color = k % 2 == 0 and bone or bone2, Material = Enum.Material.Limestone, CanCollide = false, Parent = f })
			end
		end
	end
	-- 따개비 바위
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.4
		local p = at + Vector3.new(math.cos(a) * 22, 0.8, math.sin(a) * 22 + 4)
		part({ Name = "BarnacleRock", Shape = Enum.PartType.Ball, Size = Vector3.new(3 + k % 3, 2.2, 3 + (k + 1) % 3), Position = p, Color = Color3.fromRGB(96, 98, 100), Material = Enum.Material.Slate, Parent = f })
		for b = 0, 3 do
			part({ Name = "Barnacle", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.5, 0.6), Position = p + Vector3.new(math.cos(b * 1.7) * 1.1, 1.0, math.sin(b * 1.7) * 1.1), Color = Color3.fromRGB(225, 222, 210), Material = Enum.Material.Slate, CanCollide = false, Parent = f })
		end
	end
	-- 머리뼈 위의 진주 (옅게 빛난다)
	local pearl = part({ Name = "WhalePearl", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), Position = at + Vector3.new(0, 8.2, -1.8), Color = Color3.fromRGB(230, 245, 255), Material = Enum.Material.Glass, CanCollide = false, Parent = f })
	light(pearl, Color3.fromRGB(140, 220, 255), 26, 1.6)
	local board = part({ Name = "WhaleSign", Size = Vector3.new(10, 2.6, 0.4), CFrame = CFrame.lookAt(at + Vector3.new(0, 3, -34), at + Vector3.new(0, 3, -60)), Color = Color3.fromRGB(110, 90, 70), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(board, Enum.NormalId.Front, { { "고래 뼈 바위", Color3.fromRGB(200, 240, 255), 1 } })
	part({ Name = "WhaleSignPost", Size = Vector3.new(0.6, 3, 0.6), Position = at + Vector3.new(0, 1.5, -34), Color = Color3.fromRGB(90, 70, 50), Material = Enum.Material.Wood, Parent = f })
end

-- 2.0판: 각성 사부 각성선인의 자리 (상급 수련장 안). 연꽃 단 위에 앉은 금빛 노인, 둘레에 진 권법들의 깃발
local function awakenAltar(out: any)
	local A = Config.AWAKEN_MASTER
	if not A then
		return
	end
	local at = A.at
	local f = Instance.new("Folder")
	f.Name = "AwakenAltar"
	f.Parent = folder
	local stone = Color3.fromRGB(170, 160, 140)
	local gold = Color3.fromRGB(255, 200, 90)
	disc("AwakenBase", at + Vector3.new(0, 0.6, 0), 14, 1.2, stone, Enum.Material.Marble, f)
	disc("AwakenRing", at + Vector3.new(0, 1.25, 0), 11, 0.1, Color3.fromRGB(255, 120, 140), Enum.Material.Neon, f, false).Transparency = 0.45
	-- 연꽃 단 (꽃잎 열둘)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		part({ Name = "AwakenPetal", Size = Vector3.new(2.2, 0.6, 3.6), CFrame = CFrame.new(at + Vector3.new(math.cos(a) * 3.4, 1.6, math.sin(a) * 3.4)) * CFrame.Angles(0, -a + math.pi / 2, math.rad(-20)), Color = Color3.fromRGB(255, 170, 190), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
	end
	-- 앉은 금빛 노인 (조각): 몸 · 머리 · 무릎 · 합장한 두 손
	local body = part({ Name = "AwakenSage", Size = Vector3.new(3, 3.4, 2), Position = at + Vector3.new(0, 3.8, 0), Color = gold, Material = Enum.Material.Foil, Parent = f })
	part({ Name = "AwakenSage", Shape = Enum.PartType.Ball, Size = Vector3.new(1.9, 1.9, 1.9), Position = at + Vector3.new(0, 6.4, 0), Color = gold, Material = Enum.Material.Foil, Parent = f })
	part({ Name = "AwakenSage", Size = Vector3.new(4.4, 1.2, 3), Position = at + Vector3.new(0, 2.3, -0.6), Color = gold, Material = Enum.Material.Foil, Parent = f })
	part({ Name = "AwakenSage", Size = Vector3.new(0.8, 1.6, 0.6), Position = at + Vector3.new(0, 4.4, -1.3), Color = gold, Material = Enum.Material.Foil, Parent = f })
	local halo = part({ Name = "AwakenHalo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 5, 5), CFrame = CFrame.new(at + Vector3.new(0, 6.6, 1.2)) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(255, 235, 170), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	halo.Transparency = 0.35
	light(halo, Color3.fromRGB(255, 220, 150), 24, 1.2)
	-- 진 권법들의 깃발 (각성 권법 빛깔로)
	local n = 0
	for _, st in ipairs(Config.Styles) do
		if st.awakenOf then
			n += 1
		end
	end
	local k = 0
	for _, st in ipairs(Config.Styles) do
		if st.awakenOf then
			local a = k / math.max(1, n) * math.pi * 2
			banner(at + Vector3.new(math.cos(a) * 12, 0, math.sin(a) * 12), 9, st.color, f)
			k += 1
		end
	end
	local board = part({ Name = "AwakenSign", Size = Vector3.new(10, 2.6, 0.4), CFrame = CFrame.lookAt(at + Vector3.new(0, 4.5, 16), at + Vector3.new(0, 4.5, 40)), Color = Color3.fromRGB(40, 28, 20), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	sign(board, Enum.NormalId.Front, { { "각성선인", Color3.fromRGB(255, 220, 140), 1 } })
	out.awaken = prompt(body, "각성", A.name, "Awaken")
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

------------------------------------------------------------------------
-- 천층탑 시련장: 하늘에 뜬 둥근 단 (사람마다 한 자리, 처음 쓸 때 짓는다). 단의 윗면 가운데를 돌려준다
------------------------------------------------------------------------
------------------------------------------------------------------------
-- 천상계 (세계 2): 높은 하늘의 섬들과 구름 다리. 땅과 섞이지 않는다
------------------------------------------------------------------------
-- 문: 빛나는 고리와 소용돌이 (prompt를 달 받침을 돌려준다)
local function portalGate(at: Vector3, yaw: number, color: Color3, parent: Instance, label: string): BasePart
	local cf = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	local n = 20
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		local p = cf * CFrame.new(math.cos(a) * 7, 8 + math.sin(a) * 7, 0)
		part({ Name = "PortalRing", Size = Vector3.new(1, 2.4, 1), CFrame = CFrame.lookAt(p.Position, (cf * CFrame.new(0, 8, 0)).Position) * CFrame.Angles(0, 0, a), Color = color, Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
	end
	local swirl = part({ Name = "PortalSwirl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 13, 13), CFrame = cf * CFrame.new(0, 8, 0) * CFrame.Angles(0, math.rad(90), 0), Color = color:Lerp(Color3.new(1, 1, 1), 0.5), Material = Enum.Material.Glass, Transparency = 0.35, CanCollide = false, Parent = parent })
	light(swirl, color, 30, 2)
	part({ Name = "PortalBase", Size = Vector3.new(18, 1, 6), CFrame = cf * CFrame.new(0, 0.5, 0), Color = STONE, Material = Enum.Material.Marble, Parent = parent })
	local pedestal = part({ Name = "PortalPedestal", Size = Vector3.new(3, 3.2, 3), CFrame = cf * CFrame.new(0, 1.6, -5), Color = STONE, Material = Enum.Material.Marble, Parent = parent })
	local board = part({ Name = "PortalSign", Size = Vector3.new(12, 2.6, 0.4), CFrame = cf * CFrame.new(0, 17.5, 0), Color = Color3.fromRGB(30, 22, 18), Material = Enum.Material.Wood, CanCollide = false, Parent = parent })
	sign(board, Enum.NormalId.Front, { { label, GOLD, 1 } })
	sign(board, Enum.NormalId.Back, { { label, GOLD, 1 } })
	return pedestal
end

local function skyWorld(out: any)
	local SKY = Config.SKY
	local f = Instance.new("Folder")
	f.Name = "SkyWorld"
	f.Parent = folder
	-- 땅 마을의 천상 문
	local vf = folder:FindFirstChild("Village") or f
	out.skyUp = prompt(portalGate(SKY.portal, math.rad(45), Color3.fromRGB(150, 220, 255), vf, "☁ 천상 문"), "천상계로 오르기", "천상 문", "SkyUp")
	local CLOUD = Color3.fromRGB(250, 250, 255)
	-- 2.9판: 섬마다 다른 몸. 테두리·밑동·매달린 것·둘레 구름·떠도는 작은 섬을 섬마다 따로 짓는다
	-- (예전엔 모든 섬이 같은 금 테두리 원판이라 그 금빛이 섬 바닥 전체를 덮었다)
	local function rgb(r: number, g: number, b: number): Color3
		return Color3.fromRGB(r, g, b)
	end
	local ROCK = Enum.Material.Rock
	local SKY_BODY: { [string]: any } = {
		skytown = { depth = 0.3, rim = "gold", under = { rgb(150, 140, 130), ROCK }, drip = "rock", cloud = { CLOUD, 0.15, 1 }, islet = "rock" },
		cloudplain = { rim = "cloud", under = "cloud", cloud = { CLOUD, 0.05, 1.5 }, islet = "cloud" },
		thunder = { depth = 0.45, blocky = true, rim = "crag", rimColor = rgb(55, 60, 78), under = { rgb(48, 50, 64), Enum.Material.Slate }, vein = rgb(120, 170, 255), drip = "spike", dripColor = rgb(40, 42, 55), cloud = { rgb(92, 96, 112), 0.2, 1.25 }, islet = "rod", ledges = 6 },
		nebula = { depth = 0.22, core = "crystal", rim = "star", rimColor = rgb(200, 150, 255), under = { rgb(70, 50, 110), Enum.Material.Glass }, drip = "crystal", dripColor = rgb(170, 120, 255), cloud = { rgb(175, 135, 235), 0.4, 1 }, islet = "crystal" },
		throne = { rim = "rail", rimColor = rgb(250, 245, 235), under = "pyramid", cloud = { CLOUD, 0.15, 1 }, islet = "dais" },
		subspace = { depth = 0.4, blocky = true, rim = "none", under = { rgb(20, 12, 34), Enum.Material.Glass }, drip = "shard", dripColor = rgb(40, 20, 70) },
		frost = { depth = 0.38, rim = "ice", under = { rgb(185, 220, 245), Enum.Material.Glacier }, drip = "icicle", dripColor = rgb(200, 235, 255), cloud = { rgb(245, 250, 255), 0.05, 1.1 }, islet = "ice", ledges = 5 },
		phoenix = { depth = 0.42, blocky = true, rim = "lava", under = { rgb(62, 30, 24), Enum.Material.Basalt }, vein = rgb(255, 110, 30), drip = "lava", dripColor = rgb(55, 26, 20), cloud = { rgb(85, 62, 56), 0.3, 1.1 }, islet = "ember", ledges = 5 },
		raidarena = { depth = 0.25, rim = "banner", rimColor = rgb(150, 40, 45), under = { rgb(125, 115, 104), Enum.Material.Granite }, drip = "rock", cloud = { CLOUD, 0.15, 1 }, islet = "rock" },
		falls = { depth = 0.36, rim = "moss", under = { rgb(92, 108, 84), ROCK }, drip = "moss", dripColor = rgb(80, 96, 72), cloud = { rgb(235, 245, 250), 0.25, 1 }, islet = "moss", ledges = 6 },
		crane = { rim = "rail", rimColor = rgb(245, 245, 240), under = "peak", cloud = { CLOUD, 0.1, 1.3 }, islet = "pine" },
		bamboo = { depth = 0.32, rim = "fence", under = { rgb(112, 86, 60), Enum.Material.Ground }, drip = "root", dripColor = rgb(96, 70, 46), cloud = { rgb(236, 246, 236), 0.3, 1 }, islet = "bamboo", ledges = 4 },
		moonlake = { depth = 0.16, rim = "silver", under = { rgb(180, 186, 204), Enum.Material.Marble }, drip = "water", cloud = { rgb(210, 222, 246), 0.25, 1 }, islet = "lotus" },
		rinnedae = { depth = 0.36, bands = true, rim = "gold", under = { rgb(196, 186, 226), Enum.Material.Marble }, drip = "crystal", dripColor = rgb(180, 150, 255), cloud = { rgb(235, 230, 255), 0.2, 1.1 }, islet = "crystal" },
		goldtemple = { depth = 0.3, bands = true, rim = "goldbell", under = { rgb(200, 168, 118), Enum.Material.Sandstone }, drip = "gold", dripColor = rgb(190, 158, 108), cloud = { rgb(255, 236, 196), 0.2, 1 }, islet = "bell" },
	}
	-- 다리가 닿는 방향 (테두리 꾸밈은 그 자리를 비운다)
	local function bridgeGaps(isl: any): { { number } }
		local gaps = {}
		for _, b in ipairs(SKY.bridges) do
			local me = SKY.islands[b[1]] == isl and 1 or (SKY.islands[b[2]] == isl and 2 or nil)
			if me then
				local other = SKY.islands[b[me == 1 and 2 or 1]]
				local d = other.at - isl.at
				local w = b.hidden and 8 or 16
				table.insert(gaps, { math.atan2(d.Z, d.X), math.asin(math.clamp((w / 2 + 4) / isl.radius, 0, 1)) })
			end
		end
		return gaps
	end
	local function inGap(gaps: { { number } }, a: number, pad: number): boolean
		for _, g in ipairs(gaps) do
			if math.abs((a - g[1] + math.pi) % (2 * math.pi) - math.pi) < g[2] + pad then
				return true
			end
		end
		return false
	end
	-- 섬 둘레를 따라 도는 띠 (조각을 이어 붙인다. 원판으로 덮으면 섬 바닥까지 덮이니까)
	local function ringBand(name: string, c: Vector3, r: number, width: number, height: number, y: number, color: Color3, mat: Enum.Material, f: Instance, gaps: { { number } }?, transp: number?)
		local n = math.max(24, math.floor(2 * math.pi * r / 7))
		for k = 0, n - 1 do
			local a = (k + 0.5) / n * math.pi * 2
			if not (gaps and inGap(gaps, a, 0)) then
				local p = c + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
				part({ Name = name, Size = Vector3.new(2 * math.pi * r / n + 0.4, height, width), CFrame = CFrame.lookAt(p, Vector3.new(c.X, p.Y, c.Z)), Color = color, Material = mat, Transparency = transp or 0, CanCollide = false, Parent = f })
			end
		end
	end
	-- 테두리를 따라 같은 간격으로 무언가를 세운다
	local function alongRim(c: Vector3, r: number, step: number, gaps: { { number } }, fn: (Vector3, number, number) -> ())
		local n = math.max(8, math.floor(2 * math.pi * r / step))
		for k = 0, n - 1 do
			local a = k / n * math.pi * 2
			if not inGap(gaps, a, 0.02) then
				fn(c + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r), a, 2 * math.pi * r / n)
			end
		end
	end

	local function skyIslandBody(isl: any, f: Instance)
		local c, R = isl.at, isl.radius
		local B = SKY_BODY[isl.id] or SKY_BODY.skytown
		local k1 = math.clamp(R / 180, 0.4, 1.3)
		local gaps = bridgeGaps(isl)
		local underCol = type(B.under) == "table" and B.under[1] or Color3.fromRGB(140, 135, 128)
		local underMat = type(B.under) == "table" and B.under[2] or ROCK
		------------------------------------------------ 밑동
		if B.under == "cloud" then
			-- 운해 평원: 바위 대신 큰 구름 둑이 들판을 받친다
			disc("SkyIslandUnder", c - Vector3.new(0, 9, 0), R * 0.92, 6, CLOUD, Enum.Material.SmoothPlastic, f)
			for k = 0, 21 do
				local a = k / 22 * math.pi * 2 + rng:NextNumber(0, 0.3)
				local rr = R * rng:NextNumber(0.2, 0.85)
				local sz = rng:NextNumber(40, 75) * k1
				part({ Name = "SkyCloudBank", Shape = Enum.PartType.Ball, Size = Vector3.new(sz, sz * 0.7, sz), Position = c + Vector3.new(math.cos(a) * rr, -16 - rng:NextNumber() * 18, math.sin(a) * rr), Color = CLOUD:Lerp(Color3.fromRGB(215, 224, 240), rng:NextNumber()), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
			end
		elseif B.under == "pyramid" then
			-- 옥좌대: 거꾸로 선 계단 피라미드 (층마다 금테), 맨 끝에 빛나는 구슬
			for i = 0, 5 do
				local w = R * 1.35 * (1 - i * 0.16)
				local y = -6 - i * 9
				local cf = CFrame.new(c + Vector3.new(0, y - 4.5, 0)) * CFrame.Angles(0, math.rad(45), 0)
				part({ Name = "ThroneUnder", Size = Vector3.new(w, 9, w), CFrame = cf, Color = Color3.fromRGB(240, 232, 212), Material = Enum.Material.Marble, CanCollide = false, Parent = f })
				part({ Name = "ThroneUnderTrim", Size = Vector3.new(w + 1.2, 1.2, w + 1.2), CFrame = cf * CFrame.new(0, -4.2, 0), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
			end
			local orb = part({ Name = "ThroneUnderOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(12, 12, 12), Position = c - Vector3.new(0, 66, 0), Color = Color3.fromRGB(255, 225, 140), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			light(orb, Color3.fromRGB(255, 220, 140), 50, 1.5)
		elseif B.under == "peak" then
			-- 청학봉: 거꾸로 선 높은 바위 봉우리. 끝이 구름 아래 멀리 내려간다
			disc("SkyIslandUnder", c - Vector3.new(0, 10, 0), R * 0.82, 8, Color3.fromRGB(150, 146, 138), ROCK, f)
			for i = 1, 8 do
				local w = R * 1.3 * (1 - i / 9)
				part({ Name = "CranePeak", Size = Vector3.new(w, 18, w * 0.9), CFrame = CFrame.new(c - Vector3.new(rng:NextNumber(-4, 4), 12 + i * 16, rng:NextNumber(-4, 4))) * CFrame.Angles(0, i * 0.7, 0),
					Color = Color3.fromRGB(150, 146, 138):Lerp(Color3.fromRGB(105, 102, 98), i / 8), Material = ROCK, CanCollide = false, Parent = f })
			end
			-- 봉우리 허리에 걸린 작은 소나무
			for k = 0, 3 do
				local a = k * math.pi / 2 + 0.4
				local y = 30 + k * 14
				local rr = R * 1.3 * (1 - (y / 16) / 9) / 2
				pine(c + Vector3.new(math.cos(a) * rr, -y + 9, math.sin(a) * rr), 0.7, f, false)
			end
		else
			-- 아래로 갈수록 좁아지는 바위 덩이 (섬마다 깊이와 결이 다르다: 뇌정봉은 각진 바위, 금운사는 금띠 두른 층)
			local depth = (B.depth or 0.3) * R
			local n = 5
			for i = 1, n do
				local rr = R * 0.82 * (1 - (i - 1) / (n + 0.8))
				local h = depth / n + 2
				local off = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * (R * 0.04 * i)
				local at = c + off + Vector3.new(0, -6 - (i - 0.5) * depth / n, 0)
				local col = underCol:Lerp(Color3.new(0, 0, 0), i * 0.035)
				if B.blocky then
					part({ Name = "SkyIslandUnder", Size = Vector3.new(rr * 1.45, h, rr * 1.45), CFrame = CFrame.new(at) * CFrame.Angles(rng:NextNumber(-0.05, 0.05), rng:NextNumber(0, 1.5), rng:NextNumber(-0.05, 0.05)), Color = col, Material = underMat, CanCollide = false, Parent = f })
				else
					disc("SkyIslandUnder", at, rr, h, col, underMat, f, false)
				end
				if B.bands then
					disc("SkyUnderBand", at + Vector3.new(0, h / 2 - 0.6, 0), rr + 1, 1.2, GOLD, Enum.Material.Metal, f, false)
				end
			end
			-- 성운원: 밑동 끝에서 커다란 수정 무리가 아래로 뻗는다
			if B.core == "crystal" then
				local tip = c - Vector3.new(0, 6 + depth, 0)
				for k = 0, 5 do
					local a = k / 6 * math.pi * 2
					local h = rng:NextNumber(40, 80) * k1
					local w = rng:NextNumber(10, 18) * k1
					local cf = CFrame.new(tip) * CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(rng:NextNumber(12, 30)), 0, 0) * CFrame.new(0, -h / 2 + 4, 0) * CFrame.Angles(0, math.rad(45), 0)
					part({ Name = "NebulaCrystal", Size = Vector3.new(w, h, w), CFrame = cf, Color = Color3.fromRGB(150, 100, 230):Lerp(Color3.fromRGB(110, 200, 255), rng:NextNumber()), Material = Enum.Material.Glass, Transparency = 0.12, CanCollide = false, Parent = f })
					part({ Name = "NebulaCrystalCore", Size = Vector3.new(w * 0.3, h * 0.8, w * 0.3), CFrame = cf, Color = Color3.fromRGB(235, 210, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
				end
				local big = part({ Name = "NebulaCrystal", Size = Vector3.new(20 * k1, 110 * k1, 20 * k1), CFrame = CFrame.new(tip - Vector3.new(0, 50 * k1, 0)) * CFrame.Angles(0, math.rad(45), 0), Color = Color3.fromRGB(170, 120, 255), Material = Enum.Material.Glass, Transparency = 0.1, CanCollide = false, Parent = f })
				light(big, Color3.fromRGB(190, 140, 255), 60, 1.2)
			end
		end
		-- 바위 결의 빛 줄기 (뇌정봉은 푸른 번개, 봉황대는 흐르는 용암)
		if B.vein then
			for k = 0, 11 do
				local a = k / 12 * math.pi * 2 + rng:NextNumber(0, 0.2)
				local rr = R * 0.75 + 0.1
				part({ Name = "SkyVein", Size = Vector3.new(0.6, rng:NextNumber(6, 9), 0.6), CFrame = CFrame.new(c + Vector3.new(math.cos(a) * rr, -10, math.sin(a) * rr)) * CFrame.Angles(0, 0, rng:NextNumber(-0.4, 0.4)), Color = B.vein, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			end
		end
		-- 둘레 아래쪽 바위 턱 (둥근 원판 모양을 깨뜨린다)
		for k = 1, B.ledges or 0 do
			local a = k / B.ledges * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
			if not inGap(gaps, a, 0.15) then
				local lr = rng:NextNumber(18, 34) * k1
				disc("SkyLedge", c + Vector3.new(math.cos(a) * (R - lr * 0.3), -7 - rng:NextNumber(0, 5), math.sin(a) * (R - lr * 0.3)), lr, rng:NextNumber(6, 10), underCol:Lerp(isl.ground, 0.25), underMat, f, false)
			end
		end
		------------------------------------------------ 테두리
		local rim = B.rim
		local rimC = B.rimColor or GOLD
		if rim == "gold" then
			ringBand("SkyIslandEdge", c, R + 0.6, 1.6, 0.8, -0.1, GOLD, Enum.Material.Metal, f)
		elseif rim == "cloud" then
			alongRim(c, R - 1, 9, gaps, function(p)
				local sz = rng:NextNumber(9, 15)
				part({ Name = "CloudRim", Shape = Enum.PartType.Ball, Size = Vector3.new(sz, sz * 0.6, sz), Position = p + Vector3.new(0, 0.6, 0), Color = CLOUD, Material = Enum.Material.SmoothPlastic, Transparency = 0.05, CanCollide = false, Parent = f })
			end)
		elseif rim == "crag" then
			alongRim(c, R - 1.5, 13, gaps, function(p, a)
				local h = rng:NextNumber(5, 16)
				local w = rng:NextNumber(3, 7)
				part({ Name = "CragTooth", Size = Vector3.new(w, h, w * 1.3), CFrame = CFrame.new(p + Vector3.new(0, h * 0.35, 0)) * CFrame.Angles(0, -a, 0) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(0.1, 0.45)), Color = rimC:Lerp(Color3.fromRGB(80, 84, 100), rng:NextNumber()), Material = Enum.Material.Slate, CanCollide = false, Parent = f })
			end)
		elseif rim == "star" then
			ringBand("StarRim", c, R + 0.2, 1, 0.3, 0.02, rimC, Enum.Material.Neon, f, nil, 0.35)
			for _ = 1, 18 do
				local a = rng:NextNumber() * math.pi * 2
				local d = R + rng:NextNumber(4, 14)
				local sz = rng:NextNumber(0.8, 2)
				part({ Name = "RimStar", Shape = Enum.PartType.Ball, Size = Vector3.new(sz, sz, sz), Position = c + Vector3.new(math.cos(a) * d, rng:NextNumber(-6, 12), math.sin(a) * d), Color = rimC:Lerp(Color3.new(1, 1, 1), 0.5), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
			end
		elseif rim == "rail" then
			-- 대리석 난간: 기둥과 가로대
			alongRim(c, R - 0.8, 10, gaps, function(p, a, seg)
				part({ Name = "RailPost", Size = Vector3.new(1.2, 4, 1.2), CFrame = CFrame.new(p + Vector3.new(0, 2, 0)) * CFrame.Angles(0, -a, 0), Color = rimC, Material = Enum.Material.Marble, CanCollide = false, Parent = f })
				part({ Name = "RailCap", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), Position = p + Vector3.new(0, 4.4, 0), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
				local tang = Vector3.new(-math.sin(a), 0, math.cos(a))
				local mid = p + tang * (seg / 2) + Vector3.new(0, 3.4, 0)
				part({ Name = "RailBar", Size = Vector3.new(0.8, 0.6, seg), CFrame = CFrame.lookAt(mid, mid + tang), Color = rimC, Material = Enum.Material.Marble, CanCollide = false, Parent = f })
			end)
		elseif rim == "ice" then
			ringBand("IceRim", c, R + 0.5, 2, 1, -0.2, Color3.fromRGB(200, 235, 255), Enum.Material.Ice, f)
			alongRim(c, R - 1, 22, gaps, function(p, a)
				local h = rng:NextNumber(6, 15)
				part({ Name = "RimIce", Size = Vector3.new(h * 0.3, h, h * 0.3), CFrame = CFrame.new(p + Vector3.new(0, h * 0.35, 0)) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, rng:NextNumber(0.15, 0.5)), Color = Color3.fromRGB(180, 225, 255), Material = Enum.Material.Ice, Transparency = 0.2, CanCollide = false, Parent = f })
			end)
		elseif rim == "lava" then
			ringBand("LavaRimRock", c, R + 1.2, 3, 1.6, -0.4, Color3.fromRGB(50, 24, 18), Enum.Material.Basalt, f)
			ringBand("LavaRim", c, R - 0.6, 0.8, 0.2, 0.05, Color3.fromRGB(255, 120, 40), Enum.Material.Neon, f, gaps, 0.15)
		elseif rim == "banner" then
			ringBand("ArenaRim", c, R + 0.5, 1.6, 1, -0.2, rimC, Enum.Material.Wood, f)
			alongRim(c, R + 1.4, 26, gaps, function(p, a)
				part({ Name = "RimBanner", Size = Vector3.new(5, 16, 0.3), CFrame = CFrame.new(p - Vector3.new(0, 8, 0)) * CFrame.Angles(0, -a + math.pi / 2, 0), Color = rimC, Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
				part({ Name = "RimBannerMark", Size = Vector3.new(2.4, 2.4, 0.35), CFrame = CFrame.new(p - Vector3.new(0, 5, 0)) * CFrame.Angles(0, -a + math.pi / 2, 0) * CFrame.Angles(0, 0, math.rad(45)), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
			end)
		elseif rim == "moss" then
			alongRim(c, R - 0.5, 8, gaps, function(p)
				local sz = rng:NextNumber(4, 7)
				part({ Name = "MossRim", Shape = Enum.PartType.Ball, Size = Vector3.new(sz, sz * 0.6, sz), Position = p, Color = Color3.fromRGB(78, 120, 60):Lerp(Color3.fromRGB(110, 140, 70), rng:NextNumber()), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
			end)
		elseif rim == "fence" then
			-- 대나무 울타리: 굵은 대 기둥과 두 줄 가로대
			alongRim(c, R - 1, 8, gaps, function(p, a, seg)
				part({ Name = "FencePost", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4.5, 0.8, 0.8), CFrame = CFrame.new(p + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(150, 170, 80), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
				local tang = Vector3.new(-math.sin(a), 0, math.cos(a))
				for _, y in ipairs({ 1.4, 3.2 }) do
					local mid = p + tang * (seg / 2) + Vector3.new(0, y, 0)
					part({ Name = "FenceRail", Shape = Enum.PartType.Cylinder, Size = Vector3.new(seg, 0.4, 0.4), CFrame = CFrame.lookAt(mid, mid + tang) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(170, 185, 96), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
				end
			end)
		elseif rim == "silver" then
			ringBand("SilverRim", c, R + 0.4, 1.2, 0.6, -0.1, Color3.fromRGB(215, 222, 236), Enum.Material.Metal, f)
		elseif rim == "goldbell" then
			ringBand("GoldRim", c, R + 0.6, 2, 0.8, -0.1, GOLD, Enum.Material.Metal, f)
			ringBand("GoldRim2", c, R + 1.6, 1, 1.6, -1.2, Color3.fromRGB(160, 50, 36), Enum.Material.Wood, f)
			alongRim(c, R + 1.4, 30, gaps, function(p)
				part({ Name = "RimBellChain", Size = Vector3.new(0.3, 4, 0.3), Position = p - Vector3.new(0, 4, 0), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
				part({ Name = "RimBell", Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.6, 2.2), Position = p - Vector3.new(0, 7, 0), Color = Color3.fromRGB(210, 170, 70), Material = Enum.Material.Metal, CanCollide = false, Parent = f })
			end)
		end
		------------------------------------------------ 밑에 매달린 것
		local drip = B.drip
		local dc = B.dripColor or Color3.fromRGB(120, 110, 100)
		if drip == "moss" or drip == "water" then
			-- 테두리에서 늘어진 덩굴 / 흘러내리는 가는 물줄기
			alongRim(c, R + 0.3, drip == "moss" and 18 or 150, gaps, function(p, a)
				if drip == "moss" then
					local h = rng:NextNumber(8, 20)
					part({ Name = "RimVine", Size = Vector3.new(0.5, h, 0.5), CFrame = CFrame.new(p + Vector3.new(math.cos(a), -h / 2, math.sin(a)) * 1), Color = Color3.fromRGB(70, 110, 55), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
				else
					local len = rng:NextNumber(25, 55)
					part({ Name = "RimWater", Size = Vector3.new(rng:NextNumber(8, 14), len, 0.6), CFrame = CFrame.new(p + Vector3.new(math.cos(a) * 1.2, -len / 2, math.sin(a) * 1.2)) * CFrame.Angles(0, -a + math.pi / 2, 0), Color = Color3.fromRGB(190, 215, 255), Material = Enum.Material.Glass, Transparency = 0.6, CanCollide = false, Parent = f })
					part({ Name = "RimWaterMist", Shape = Enum.PartType.Ball, Size = Vector3.new(16, 8, 16), Position = p + Vector3.new(math.cos(a) * 2, -len, math.sin(a) * 2), Color = Color3.fromRGB(235, 242, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.5, CanCollide = false, Parent = f })
				end
			end)
		end
		if drip and drip ~= "water" then
			local n = drip == "icicle" and 18 or (drip == "root" and 16 or 10)
			for k = 0, n - 1 do
				local a = k / n * math.pi * 2 + rng:NextNumber(0, 0.5)
				local rr = R * rng:NextNumber(0.15, 0.62)
				local h = rng:NextNumber(14, 34) * k1
				local w = rng:NextNumber(8, 16) * math.clamp(R / 180, 0.4, 1.2)
				local top = c + Vector3.new(math.cos(a) * rr, -22, math.sin(a) * rr)
				if drip == "icicle" then
					h *= 1.3
					w *= 0.4
					part({ Name = "Icicle", Size = Vector3.new(w, h, w), CFrame = CFrame.new(top - Vector3.new(0, h * 0.45, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Color = dc, Material = Enum.Material.Ice, Transparency = 0.15, CanCollide = false, Parent = f })
				elseif drip == "crystal" or drip == "shard" then
					part({ Name = "UnderCrystal", Size = Vector3.new(w * 0.6, h, w * 0.6), CFrame = CFrame.new(top - Vector3.new(0, h * 0.4, 0)) * CFrame.Angles(0, math.rad(45) + a, 0) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), 0, rng:NextNumber(-0.25, 0.25)), Color = dc, Material = Enum.Material.Glass, Transparency = 0.1, CanCollide = false, Parent = f })
					if drip == "crystal" and k % 2 == 0 then
						part({ Name = "UnderCrystalCore", Size = Vector3.new(w * 0.2, h * 0.7, w * 0.2), CFrame = CFrame.new(top - Vector3.new(0, h * 0.4, 0)) * CFrame.Angles(0, math.rad(45) + a, 0), Color = Color3.fromRGB(230, 200, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
					end
				elseif drip == "root" then
					local len = rng:NextNumber(10, 26)
					part({ Name = "UnderRoot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(len, rng:NextNumber(0.6, 1.4), rng:NextNumber(0.6, 1.4)), CFrame = CFrame.new(top + Vector3.new(0, 8, 0)) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-120, -60))) * CFrame.new(len / 2, 0, 0), Color = dc, Material = Enum.Material.Wood, CanCollide = false, Parent = f })
				else
					local rock = part({ Name = "SkyStalactite", Size = Vector3.new(w * (drip == "spike" and 0.55 or 1), h * (drip == "spike" and 1.4 or 1), w * (drip == "spike" and 0.55 or 1)), CFrame = CFrame.new(top - Vector3.new(0, h * 0.4, 0)) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 6), rng:NextNumber(-0.2, 0.2)),
						Color = dc:Lerp(dc:Lerp(Color3.new(0, 0, 0), 0.25), rng:NextNumber()), Material = drip == "lava" and Enum.Material.Basalt or (drip == "gold" and Enum.Material.Sandstone or (drip == "spike" and Enum.Material.Slate or ROCK)), CanCollide = false, Parent = f })
					if drip == "lava" then
						part({ Name = "LavaDrop", Shape = Enum.PartType.Ball, Size = Vector3.new(w * 0.35, w * 0.5, w * 0.35), Position = rock.Position - Vector3.new(0, h * 0.5, 0), Color = Color3.fromRGB(255, 120, 40), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
					elseif drip == "gold" then
						part({ Name = "GoldBand", Size = Vector3.new(w * 1.05, 1.2, w * 1.05), CFrame = rock.CFrame * CFrame.new(0, h * 0.2, 0), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
					elseif drip == "moss" then
						part({ Name = "MossCap", Size = Vector3.new(w * 1.05, 2, w * 1.05), CFrame = rock.CFrame * CFrame.new(0, h * 0.4, 0), Color = Color3.fromRGB(80, 120, 60), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
					end
				end
			end
		end
		------------------------------------------------ 둘레 구름 (아래쪽)
		if B.cloud then
			local col, tr, sc = B.cloud[1], B.cloud[2], B.cloud[3] or 1
			local n = math.max(8, math.floor(R / 14))
			for k = 0, n - 1 do
				local a = k / n * math.pi * 2 + rng:NextNumber() * 0.3
				local size = rng:NextNumber(18, 34) * sc
				part({ Name = "SkyCloud", Shape = Enum.PartType.Ball, Size = Vector3.new(size, size * 0.8, size), Position = c + Vector3.new(math.cos(a) * (R * 0.9), -9 - rng:NextNumber() * 6 * sc, math.sin(a) * (R * 0.9)), Color = col, Material = Enum.Material.SmoothPlastic, Transparency = tr, CanCollide = false, Parent = f })
			end
		end
		------------------------------------------------ 떠도는 작은 섬
		if isl.hidden or not B.islet then
			return
		end
		for k = 0, 3 do
			local a = k / 4 * math.pi * 2 + rng:NextNumber(0, 1)
			local d = R + rng:NextNumber(40, 90)
			local p = c + Vector3.new(math.cos(a) * d, rng:NextNumber(-30, 25), math.sin(a) * d)
			local w = rng:NextNumber(10, 22)
			local kind = B.islet
			if kind == "cloud" then
				for j = 0, 2 do
					local sz = w * (1 - j * 0.2)
					part({ Name = "IsletCloud", Shape = Enum.PartType.Ball, Size = Vector3.new(sz, sz * 0.6, sz), Position = p + Vector3.new((j - 1) * w * 0.5, j * 0.6, rng:NextNumber(-2, 2)), Color = CLOUD, Material = Enum.Material.SmoothPlastic, Transparency = 0.1, CanCollide = false, Parent = f })
				end
			elseif kind == "crystal" or kind == "ice" then
				local col = kind == "ice" and Color3.fromRGB(190, 230, 255) or Color3.fromRGB(190, 140, 255)
				for j = 0, 2 do
					local h = w * (1.2 - j * 0.3)
					part({ Name = kind == "ice" and "IsletIce" or "IsletCrystal", Size = Vector3.new(h * 0.4, h, h * 0.4), CFrame = CFrame.new(p + Vector3.new((j - 1) * 3, 0, rng:NextNumber(-2, 2))) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)),
						Color = col, Material = kind == "ice" and Enum.Material.Ice or Enum.Material.Glass, Transparency = 0.15, CanCollide = false, Parent = f })
				end
				if kind == "crystal" then
					part({ Name = "IsletCrystalCore", Size = Vector3.new(1, w * 0.7, 1), Position = p, Color = Color3.fromRGB(235, 210, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
				end
			elseif kind == "dais" then
				-- 금테 두른 대리석 단과 작은 기둥 (옥좌대)
				disc("IsletDais", p, w * 0.6, 2.4, Color3.fromRGB(245, 238, 220), Enum.Material.Marble, f, false)
				ringBand("IsletDaisTrim", p, w * 0.6, 0.6, 0.6, -1.4, GOLD, Enum.Material.Metal, f)
				part({ Name = "IsletDaisPillar", Size = Vector3.new(2, 10, 2), Position = p + Vector3.new(0, 6, 0), Color = Color3.fromRGB(250, 245, 235), Material = Enum.Material.Marble, CanCollide = false, Parent = f })
				brazier(p + Vector3.new(0, 11, 0), 0.9, f)
			else
				-- 바위섬 (밑은 뾰족, 위는 그 섬의 땅빛)
				local rockC = kind == "ember" and Color3.fromRGB(55, 28, 22) or (kind == "rod" and Color3.fromRGB(52, 55, 70) or (kind == "bell" and Color3.fromRGB(196, 165, 115) or Color3.fromRGB(130, 120, 110)))
				local mat = kind == "ember" and Enum.Material.Basalt or (kind == "rod" and Enum.Material.Slate or (kind == "bell" and Enum.Material.Sandstone or ROCK))
				part({ Name = "SkyIslet", Shape = Enum.PartType.Cylinder, Size = Vector3.new(w * 0.5, w, w), CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)), Color = rockC, Material = mat, CanCollide = false, Parent = f })
				part({ Name = "SkyIsletTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, w * 1.02, w * 1.02), CFrame = CFrame.new(p + Vector3.new(0, w * 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = isl.ground, Material = isl.material, CanCollide = false, Parent = f })
				part({ Name = "SkyIsletRoot", Size = Vector3.new(w * 0.5, w * 0.8, w * 0.5), CFrame = CFrame.new(p - Vector3.new(0, w * 0.5, 0)) * CFrame.Angles(0, math.rad(45), 0), Color = rockC:Lerp(Color3.new(0, 0, 0), 0.15), Material = mat, CanCollide = false, Parent = f })
				local top = p + Vector3.new(0, w * 0.25 + 0.5, 0)
				if kind == "rod" then
					-- 피뢰침: 쇠 기둥 끝에 푸른 번개 구슬
					part({ Name = "IsletRod", Size = Vector3.new(0.6, 14, 0.6), Position = top + Vector3.new(0, 7, 0), Color = Color3.fromRGB(90, 95, 110), Material = Enum.Material.Metal, CanCollide = false, Parent = f })
					part({ Name = "IsletRodTip", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), Position = top + Vector3.new(0, 14.5, 0), Color = Color3.fromRGB(140, 190, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
				elseif kind == "ember" then
					part({ Name = "IsletEmber", Size = Vector3.new(w * 0.7, 0.3, 0.8), CFrame = CFrame.new(top) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Color = Color3.fromRGB(255, 120, 40), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
				elseif kind == "moss" then
					for _ = 1, 4 do
						part({ Name = "IsletVine", Size = Vector3.new(0.4, rng:NextNumber(5, 10), 0.4), Position = p + Vector3.new(rng:NextNumber(-w, w) * 0.45, -4, rng:NextNumber(-w, w) * 0.45), Color = Color3.fromRGB(70, 110, 55), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
					end
				elseif kind == "pine" then
					pine(top, 0.6, f, false)
				elseif kind == "bamboo" then
					for j = 0, 2 do
						local h = rng:NextNumber(10, 16)
						part({ Name = "IsletBamboo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 0.7, 0.7), CFrame = CFrame.new(top + Vector3.new((j - 1) * 1.6, h / 2, rng:NextNumber(-1, 1))) * CFrame.Angles(0, 0, math.rad(90 + rng:NextNumber(-6, 6))), Color = Color3.fromRGB(110, 165, 70), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
					end
				elseif kind == "lotus" then
					part({ Name = "IsletLotus", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 2, 3), Position = top + Vector3.new(0, 0.6, 0), Color = Color3.fromRGB(250, 200, 220), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
				elseif kind == "bell" then
					part({ Name = "IsletBellChain", Size = Vector3.new(0.3, 5, 0.3), Position = p - Vector3.new(0, w * 0.9 + 2.5, 0), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
					part({ Name = "IsletBell", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 3.4, 3.4), CFrame = CFrame.new(p - Vector3.new(0, w * 0.9 + 6.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(200, 160, 70), Material = Enum.Material.Metal, CanCollide = false, Parent = f })
				end
			end
		end
	end
	-- 섬
	for _, isl in ipairs(SKY.islands) do
		local c, R = isl.at, isl.radius
		disc("SkyIsland", c - Vector3.new(0, 3, 0), R, 6, isl.ground, isl.material, f)
		skyIslandBody(isl, f)
		-- 보이지 않는 난간 (떨어지지 않게). 다리가 이어지는 자리는 비워 둔다
		local gaps: { { number } } = {}
		for bi, b in ipairs(SKY.bridges) do
			local me = SKY.islands[b[1]] == isl and 1 or (SKY.islands[b[2]] == isl and 2 or nil)
			if me then
				local other = SKY.islands[b[me == 1 and 2 or 1]]
				local d = Vector3.new(other.at.X - c.X, 0, other.at.Z - c.Z)
				local w = b.hidden and 8 or 16
				table.insert(gaps, { math.atan2(d.Z, d.X), math.asin(math.clamp((w / 2 + 3) / R, 0, 1)) })
			end
			local _ = bi
		end
		local m = math.max(32, math.floor(R / 4))
		for k = 0, m - 1 do
			local a = k / m * math.pi * 2
			local open = false
			for _, g in ipairs(gaps) do
				local diff = math.abs((a - g[1] + math.pi) % (2 * math.pi) - math.pi)
				if diff < g[2] + math.pi / m then
					open = true
				end
			end
			if not open then
				local p = c + Vector3.new(math.cos(a) * (R + 0.5), 7, math.sin(a) * (R + 0.5))
				part({ Name = "SkyWall", Size = Vector3.new(2 * math.pi * R / m + 1, 14, 1), CFrame = CFrame.lookAt(p, Vector3.new(c.X, p.Y, c.Z)), Transparency = 1, CanCollide = true, Parent = f })
			end
		end
	end
	-- 다리 (구름 빛 돌길, 양옆에 보이지 않는 난간). 숨은 다리는 거의 투명하다
	for _, b in ipairs(SKY.bridges) do
		local A, B = SKY.islands[b[1]], SKY.islands[b[2]]
		local dir = Vector3.new(B.at.X - A.at.X, 0, B.at.Z - A.at.Z)
		local from = A.at + dir.Unit * (A.radius - 4)
		local to = B.at - dir.Unit * (B.radius - 4)
		local len = (to - from).Magnitude
		local mid = (from + to) / 2
		-- 3.1판: 높이가 다른 섬 사이 (윤회대) 는 비탈진 다리
		local cf = math.abs(to.Y - from.Y) > 0.5 and CFrame.lookAt(mid, to) or CFrame.lookAt(mid, mid + dir)
		local w = b.hidden and 8 or 16
		local deck = part({ Name = b.hidden and "HiddenBridge" or "SkyBridge", Size = Vector3.new(w, 1, len), CFrame = cf * CFrame.new(0, -0.5, 0), Color = b.hidden and Color3.fromRGB(200, 230, 255) or Color3.fromRGB(240, 238, 230), Material = b.hidden and Enum.Material.Glass or Enum.Material.Marble, Transparency = b.hidden and 0.88 or 0, Parent = f })
		local _ = deck
		for _, x in ipairs({ -1, 1 }) do
			part({ Name = "BridgeWall", Size = Vector3.new(1, 10, len), CFrame = cf * CFrame.new(x * (w / 2 + 0.5), 5, 0), Transparency = 1, CanCollide = true, Parent = f })
			if not b.hidden then
				part({ Name = "BridgeCurb", Size = Vector3.new(0.8, 1, len), CFrame = cf * CFrame.new(x * (w / 2 - 0.4), 0.5, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
				for k = 1, math.floor(len / 50) do
					stoneLantern((cf * CFrame.new(x * (w / 2 + 1.5), 0, -len / 2 + k * 50)).Position, f, true)
				end
			end
		end
	end
	-- 섬마다 꾸밈
	local I = Config.SKY_BY_ID
	-- 천궁 (천상계 마을): 네 갈래 큰길, 가운데 광장과 천주탑, 객잔·상점·정자·내려가는 문, 둘레의 집들
	local town = I.skytown.at
	local TR = I.skytown.radius
	local ROAD = Color3.fromRGB(250, 246, 235)
	for k = 0, 3 do
		local a = k * math.pi / 2
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		local mid = town + d * (TR / 2 + 10)
		part({ Name = "SkyRoad", Size = Vector3.new(14, 0.3, TR - 20), CFrame = CFrame.lookAt(mid, mid + d) * CFrame.new(0, 0.1, 0), Color = ROAD, Material = Enum.Material.Marble, Parent = f })
		for j = 1, 4 do
			for _, side in ipairs({ -1, 1 }) do
				local p = town + d * (30 + j * 38) + Vector3.new(-d.Z, 0, d.X) * side * 10
				stoneLantern(p, f, true)
			end
		end
	end
	disc("SkyPlaza", town + Vector3.new(0, 0.15, 0), 30, 0.3, Color3.fromRGB(245, 230, 190), Enum.Material.Marble, f)
	disc("SkyPlazaRing", town + Vector3.new(0, 0.2, 0), 31, 0.3, GOLD, Enum.Material.Metal, f)
	spire(town, 6, 8, Color3.fromRGB(150, 220, 255), f)
	crystal(town + Vector3.new(0, 70, 0), 7, Color3.fromRGB(150, 220, 255), f)
	-- 북동: 천상 객잔 (쉬면 체력·내공이 찬다)
	local innAt = town + Vector3.new(100, 0, -100)
	building(innAt, 30, 20, math.rad(135), f, { tiers = 2, sign = "천상 객잔", h = 11, wall = Color3.fromRGB(245, 240, 230), roof = Color3.fromRGB(70, 110, 170), awningColor = Color3.fromRGB(70, 110, 170) })
	local innDesk = part({ Name = "SkyInnDesk", Size = Vector3.new(6, 3.2, 3), CFrame = CFrame.lookAt(innAt, town) * CFrame.new(0, 1.6, -15), Color = Color3.fromRGB(150, 120, 90), Material = Enum.Material.Wood, Parent = f })
	out.skyInn = prompt(innDesk, "쉬기", "천상 객잔 · 체력·내공 채우기", "SkyInn")
	-- 남동: 천상 상점 (천정으로 산다)
	local shopAt = town + Vector3.new(100, 0, 100)
	building(shopAt, 26, 18, math.rad(45), f, { sign = "천상 상점", h = 11, wall = Color3.fromRGB(245, 240, 230), roof = Color3.fromRGB(150, 90, 200), awningColor = Color3.fromRGB(150, 90, 200) })
	local stall = part({ Name = "SkyShopStall", Size = Vector3.new(10, 3.4, 4), CFrame = CFrame.lookAt(shopAt, town) * CFrame.new(0, 1.7, -14), Color = Color3.fromRGB(120, 80, 160), Material = Enum.Material.Wood, Parent = f })
	part({ Name = "SkyShopGem", Size = Vector3.new(1.4, 2.2, 1.4), CFrame = CFrame.lookAt(shopAt, town) * CFrame.new(0, 4.6, -14) * CFrame.Angles(0, math.rad(45), 0), Color = Color3.fromRGB(150, 230, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	out.skyShop = prompt(stall, "물건 보기", "천상 상점 (천정)", "SkyShop")
	-- 북서: 운류자의 정자 (기둥 넷과 지붕)
	local pav = Config.MASTERS.unryu.at - Vector3.new(0, Config.MASTERS.unryu.at.Y - town.Y, 0)
	part({ Name = "PavilionBase", Size = Vector3.new(22, 1.2, 22), Position = pav + Vector3.new(0, 0.6, 0), Color = STONE, Material = Enum.Material.Marble, Parent = f })
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part({ Name = "PavilionPost", Size = Vector3.new(1.4, 12, 1.4), Position = pav + Vector3.new(sx * 9, 7, sz * 9), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
		end
	end
	part({ Name = "PavilionRoof", Size = Vector3.new(26, 1.2, 26), Position = pav + Vector3.new(0, 13.6, 0), Color = Color3.fromRGB(70, 110, 170), Material = Enum.Material.Slate, Parent = f })
	part({ Name = "PavilionRoof2", Size = Vector3.new(16, 1.2, 16), Position = pav + Vector3.new(0, 15, 0), Color = Color3.fromRGB(80, 125, 190), Material = Enum.Material.Slate, Parent = f })
	-- 남서: 땅으로 내려가는 문
	out.skyDown = prompt(portalGate(town + Vector3.new(-100, 0, 100), math.rad(45), Color3.fromRGB(255, 220, 140), f, "⬇ 땅으로"), "땅으로 내려가기", "천궁 문", "SkyDown")
	-- 1.7판: 광장 둘레의 세 문 (천층탑 · 구름 미궁 · 천공 투기장). 받침은 광장 쪽에
	local function plazaGate(off: Vector3, color: Color3, label: string, action: string, title: string, name: string): ProximityPrompt
		local yaw = math.atan2(off.X, off.Z)
		return prompt(portalGate(town + off, yaw, color, f, label), action, title, name)
	end
	out.towerGate = plazaGate(Vector3.new(72, 0, 34), Color3.fromRGB(255, 190, 110), "🗼 천층탑", "탑에 오르기", "천층탑 문", "TowerGate")
	out.mazeGate = plazaGate(Vector3.new(72, 0, -34), Color3.fromRGB(190, 230, 255), "🌀 구름 미궁", "미궁에 들어가기", "구름 미궁 문", "MazeGate")
	out.raidGate = plazaGate(Vector3.new(-78, 0, 30), Color3.fromRGB(255, 120, 120), "⚔ 천공 투기장", "투기장으로", "천공 투기장 문", "RaidGate")
	-- 둘레의 집들 (큰길 양옆)
	for k = 0, 3 do
		local base = k * math.pi / 2
		for _, off in ipairs({ -0.38, 0.38 }) do
			local a = base + off
			local p = town + Vector3.new(math.cos(a) * 165, 0, math.sin(a) * 165)
			local yaw = math.atan2(-(town.X - p.X), -(town.Z - p.Z))
			building(p, rng:NextNumber(18, 24), rng:NextNumber(14, 18), yaw, f, { tiers = rng:NextNumber() < 0.5 and 2 or 1, wall = Color3.fromRGB(245, 240, 230), roof = Color3.fromRGB(70, 110, 170):Lerp(Color3.fromRGB(150, 90, 200), rng:NextNumber()) })
		end
	end
	-- 바깥 네 모퉁이의 첨탑
	for k = 0, 3 do
		local a = math.pi / 4 + k * math.pi / 2
		spire(town + Vector3.new(math.cos(a) * 178, 0, math.sin(a) * 178), 4, 6, Color3.fromRGB(150, 220, 255), f)
	end
	-- 운해 평원: 구름 덤불과 정자
	local cp = I.cloudplain.at
	for _ = 1, 26 do
		local a, r = rng:NextNumber() * math.pi * 2, rng:NextNumber(30, 190)
		local size = rng:NextNumber(5, 11)
		part({ Name = "CloudBush", Shape = Enum.PartType.Ball, Size = Vector3.new(size, size, size), Position = cp + Vector3.new(math.cos(a) * r, size * 0.3, math.sin(a) * r), Color = CLOUD, Material = Enum.Material.SmoothPlastic, Transparency = 0.1, CanCollide = false, Parent = f })
	end
	for _, o in ipairs({ Vector3.new(-120, 0, 40), Vector3.new(120, 0, -20) }) do
		building(cp + o, 16, 16, rng:NextNumber() * 3, f, { wall = Color3.fromRGB(240, 235, 225), roof = Color3.fromRGB(80, 130, 180) })
	end
	-- 뇌정봉: 검은 봉우리와 푸른 번개 끝
	local th = I.thunder.at
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2
		spire(th + Vector3.new(math.cos(a) * 120, 0, math.sin(a) * 120), 5, 6, Color3.fromRGB(120, 170, 255), f)
	end
	disc("ThunderArena", th + Vector3.new(100, 0.15, 0), 40, 0.3, Color3.fromRGB(110, 150, 255), Enum.Material.Neon, f, false).Transparency = 0.6
	-- 성운원: 보랏빛 수정 무리와 떠 있는 빛 구슬
	local nb = I.nebula.at
	for _ = 1, 18 do
		local a, r = rng:NextNumber() * math.pi * 2, rng:NextNumber(20, 170)
		crystal(nb + Vector3.new(math.cos(a) * r, rng:NextNumber(3, 14), math.sin(a) * r), rng:NextNumber(2, 5), Color3.fromRGB(200, 140, 255):Lerp(Color3.fromRGB(120, 220, 255), rng:NextNumber()), f)
	end
	-- 옥좌대: 금빛 계단과 옥좌, 기둥 둘레
	local tr = I.throne.at
	for k = 1, 5 do
		part({ Name = "ThroneStep", Size = Vector3.new(60 - k * 6, k * 1.2, 14), Position = tr + Vector3.new(0, k * 0.6, -110 + k * 3), Color = Color3.fromRGB(245, 230, 190), Material = Enum.Material.Marble, Parent = f })
	end
	part({ Name = "Throne", Size = Vector3.new(10, 14, 6), Position = tr + Vector3.new(0, 13, -112), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local p = tr + Vector3.new(math.cos(a) * 130, 0, math.sin(a) * 130)
		part({ Name = "ThronePillar", Size = Vector3.new(5, 34, 5), Position = p + Vector3.new(0, 17, 0), Color = Color3.fromRGB(250, 245, 235), Material = Enum.Material.Marble, Parent = f })
		brazier(p + Vector3.new(0, 34, 0), 1.2, f)
	end
	-- 금 간 허공: 검은 유리 섬, 빛나는 금, 떠 있는 정육면체
	local sb = I.subspace.at
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		part({ Name = "SpaceCrack", Size = Vector3.new(0.4, 0.2, rng:NextNumber(20, 40)), CFrame = CFrame.new(sb + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -18), Color = Color3.fromRGB(140, 255, 230), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	for _ = 1, 10 do
		local size = rng:NextNumber(1.5, 4)
		part({ Name = "SpaceCube", Size = Vector3.new(size, size, size), CFrame = CFrame.new(sb + Vector3.new(rng:NextNumber(-40, 40), rng:NextNumber(6, 22), rng:NextNumber(-40, 40))) * CFrame.Angles(rng:NextNumber() * 6, rng:NextNumber() * 6, 0), Color = Color3.fromRGB(70, 30, 140), Material = Enum.Material.Glass, Transparency = 0.3, CanCollide = false, Parent = f })
	end
	-- 1.7판 빙정궁: 얼음 첨탑과 수정 숲, 얼어붙은 궁 (빙제의 자리 앞엔 얼음 단)
	local fr = I.frost.at
	local ICE = Color3.fromRGB(170, 225, 255)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		spire(fr + Vector3.new(math.cos(a) * 135, 0, math.sin(a) * 135), 4, 5, ICE, f)
	end
	for _ = 1, 22 do
		local a, r = rng:NextNumber() * math.pi * 2, rng:NextNumber(30, 165)
		local h = rng:NextNumber(6, 18)
		part({ Name = "IceShard", Size = Vector3.new(h * 0.35, h, h * 0.35), CFrame = CFrame.new(fr + Vector3.new(math.cos(a) * r, h * 0.4, math.sin(a) * r)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber() * 6, rng:NextNumber(-0.3, 0.3)), Color = ICE:Lerp(Color3.new(1, 1, 1), rng:NextNumber() * 0.5), Material = Enum.Material.Ice, Transparency = 0.15, Parent = f })
	end
	building(fr + Vector3.new(-40, 0, 40), 34, 24, math.rad(225), f, { tiers = 2, sign = "빙정궁", h = 12, wall = Color3.fromRGB(225, 240, 255), roof = Color3.fromRGB(120, 180, 230) })
	disc("FrostDais", fr + Vector3.new(80, 0.4, -50), 26, 0.8, Color3.fromRGB(200, 235, 255), Enum.Material.Ice, f)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		crystal(fr + Vector3.new(80 + math.cos(a) * 24, 8, -50 + math.sin(a) * 24), 3, ICE, f)
	end
	-- 봉황대: 검붉은 현무암, 용암 갈라짐, 불꽃 화로, 가운데 날개 편 봉황 석상
	local ph = I.phoenix.at
	local EMBER = Color3.fromRGB(255, 120, 40)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		part({ Name = "LavaCrack", Size = Vector3.new(1.2, 0.2, rng:NextNumber(30, 70)), CFrame = CFrame.new(ph + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -rng:NextNumber(40, 90)), Color = EMBER, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local p = ph + Vector3.new(math.cos(a) * 140, 0, math.sin(a) * 140)
		part({ Name = "PhoenixPillar", Size = Vector3.new(5, 26, 5), Position = p + Vector3.new(0, 13, 0), Color = Color3.fromRGB(90, 30, 20), Material = Enum.Material.Basalt, Parent = f })
		brazier(p + Vector3.new(0, 26, 0), 1.3, f)
	end
	-- 봉황 석상: 몸통, 목과 머리, 활짝 편 두 날개(깃털 판), 길게 늘어진 꼬리깃
	local st = ph + Vector3.new(0, 0, 40)
	part({ Name = "PhoenixPlinth", Size = Vector3.new(16, 4, 16), Position = st + Vector3.new(0, 2, 0), Color = Color3.fromRGB(70, 25, 18), Material = Enum.Material.Basalt, Parent = f })
	part({ Name = "PhoenixBody", Shape = Enum.PartType.Ball, Size = Vector3.new(8, 8, 8), Position = st + Vector3.new(0, 10, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
	part({ Name = "PhoenixNeck", Size = Vector3.new(2.4, 7, 2.4), CFrame = CFrame.new(st + Vector3.new(0, 15, 2)) * CFrame.Angles(math.rad(-20), 0, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
	part({ Name = "PhoenixHead", Shape = Enum.PartType.Ball, Size = Vector3.new(3.4, 3.4, 3.4), Position = st + Vector3.new(0, 19, 3.4), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
	for _, sx in ipairs({ -1, 1 }) do
		for k = 0, 5 do
			local len = 14 - k * 1.4
			part({ Name = "PhoenixFeather", Size = Vector3.new(len, 0.6, 2.4), CFrame = CFrame.new(st + Vector3.new(sx * 4, 12, 0)) * CFrame.Angles(0, 0, sx * math.rad(20 + k * 13)) * CFrame.new(sx * len / 2, 0, -k * 0.3), Color = k % 2 == 0 and EMBER or GOLD, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		end
	end
	for k = 0, 4 do
		part({ Name = "PhoenixTail", Size = Vector3.new(1.4, 0.5, 18), CFrame = CFrame.new(st + Vector3.new(0, 7, -4)) * CFrame.Angles(math.rad(25), math.rad(-30 + k * 15), 0) * CFrame.new(0, 0, -9), Color = k % 2 == 0 and EMBER or GOLD, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	light(part({ Name = "PhoenixGlow", Size = Vector3.new(1, 1, 1), Position = st + Vector3.new(0, 14, 0), Transparency = 1, CanCollide = false, Parent = f }), EMBER, 60, 3)
	-- 천공 투기장: 둥근 결투장과 계단식 관람석, 네 기둥과 큰 징
	local ra = I.raidarena.at
	disc("RaidFloor", ra + Vector3.new(0, 0.2, 0), 100, 0.4, Color3.fromRGB(180, 170, 155), Enum.Material.Slate, f)
	disc("RaidRing", ra + Vector3.new(0, 0.3, 0), 70, 0.4, Color3.fromRGB(150, 40, 45), Enum.Material.Fabric, f, false)
	disc("RaidCore", ra + Vector3.new(0, 0.35, 0), 66, 0.4, Color3.fromRGB(195, 185, 170), Enum.Material.Slate, f, false)
	for tier = 1, 3 do
		local r = 110 + tier * 9
		local n = 40
		for k = 0, n - 1 do
			local a = k / n * math.pi * 2
			-- 다리 쪽 (남동: 성운원으로) 은 비운다
			local toBridge = math.atan2(I.nebula.at.Z - ra.Z, I.nebula.at.X - ra.X)
			if math.abs((a - toBridge + math.pi) % (2 * math.pi) - math.pi) > 0.22 then
				local p = ra + Vector3.new(math.cos(a) * r, tier * 1.5, math.sin(a) * r)
				part({ Name = "RaidSeat", Size = Vector3.new(2 * math.pi * r / n + 0.3, tier * 3, 8), CFrame = CFrame.lookAt(p, Vector3.new(ra.X, p.Y, ra.Z)), Color = STONE:Lerp(Color3.fromRGB(120, 110, 100), tier * 0.15), Material = Enum.Material.Marble, Parent = f })
			end
		end
	end
	for k = 0, 3 do
		local a = math.pi / 4 + k * math.pi / 2
		local p = ra + Vector3.new(math.cos(a) * 92, 0, math.sin(a) * 92)
		part({ Name = "RaidPillar", Size = Vector3.new(6, 40, 6), Position = p + Vector3.new(0, 20, 0), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
		brazier(p + Vector3.new(0, 40, 0), 1.6, f)
	end
	local gong = part({ Name = "RaidGong", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 14, 14), CFrame = CFrame.new(ra + Vector3.new(0, 14, -104)) * CFrame.Angles(0, math.rad(90), 0), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
	local _ = gong
	part({ Name = "RaidGongFrame", Size = Vector3.new(20, 1.4, 1.4), Position = ra + Vector3.new(0, 22, -104), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "RaidGongPost", Size = Vector3.new(1.4, 22, 1.4), Position = ra + Vector3.new(sx * 9.5, 11, -104), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
	end
	-- 1.8판 비천폭: 섬 한가운데 바위산에서 쏟아지는 폭포가 섬 끝을 넘어 구름 아래로 떨어진다
	local fa = I.falls.at
	local cliff = fa + Vector3.new(0, 0, -60)
	for i = 1, 4 do
		part({ Name = "FallsCliff", Size = Vector3.new(70 - i * 12, 14, 40 - i * 6), CFrame = CFrame.new(cliff + Vector3.new(0, i * 13 - 6, 0)) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), Color = Color3.fromRGB(110, 120, 110), Material = Enum.Material.Rock, Parent = f })
	end
	local WATER = Color3.fromRGB(150, 210, 255)
	local fallTop = cliff + Vector3.new(0, 52, 16)
	local sheet = part({ Name = "Waterfall", Size = Vector3.new(16, 52, 2), Position = fallTop - Vector3.new(0, 26, 0), Color = WATER, Material = Enum.Material.Glass, Transparency = 0.25, CanCollide = false, Parent = f })
	local foam = Instance.new("ParticleEmitter")
	foam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	foam.Color = ColorSequence.new(Color3.fromRGB(235, 248, 255), WATER)
	foam.Size = NumberSequence.new(1.2, 0.4)
	foam.Lifetime = NumberRange.new(0.8, 1.2)
	foam.Rate = 60
	foam.Speed = NumberRange.new(20, 30)
	foam.EmissionDirection = Enum.NormalId.Bottom
	foam.SpreadAngle = Vector2.new(8, 8)
	foam.Shape = Enum.ParticleEmitterShape.Box
	foam.LightEmission = 0.4
	foam.Parent = sheet
	-- 폭포가 흘러 섬 끝까지 이어지는 물길과, 섬 끝에서 아래로 떨어지는 긴 물줄기
	local edge = fa + Vector3.new(0, 0, -I.falls.radius + 2)
	part({ Name = "FallsStream", Size = Vector3.new(14, 0.4, (cliff - edge).Magnitude), Position = (cliff + edge) / 2 + Vector3.new(0, 0.25, 8), Color = WATER, Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, Parent = f })
	part({ Name = "FallsDrop", Size = Vector3.new(14, 160, 2), Position = edge + Vector3.new(0, -80, -2), Color = WATER, Material = Enum.Material.Glass, Transparency = 0.3, CanCollide = false, Parent = f })
	disc("FallsPool", cliff + Vector3.new(0, 0.3, 30), 22, 0.4, WATER, Enum.Material.Glass, f, false).Transparency = 0.2
	for _ = 1, 16 do
		local a, rr = rng:NextNumber() * math.pi * 2, rng:NextNumber(40, 150)
		tree(fa + Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr), rng:NextNumber(0.8, 1.3), f)
	end
	-- 청학봉: 흰 대리석 단과 학 둥지, 날개를 편 흰 학 석상 넷, 높은 소나무
	local cr = I.crane.at
	for i = 1, 3 do
		disc("CraneTier", cr + Vector3.new(0, i * 1.2 - 0.6, 60), 40 - i * 9, 1.2, Color3.fromRGB(245, 245, 240), Enum.Material.Marble, f)
	end
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + math.pi / 4
		local base = cr + Vector3.new(math.cos(a) * 120, 0, math.sin(a) * 120)
		part({ Name = "CranePlinth", Size = Vector3.new(8, 4, 8), Position = base + Vector3.new(0, 2, 0), Color = STONE, Material = Enum.Material.Marble, Parent = f })
		part({ Name = "CraneBody", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 4, 7), Position = base + Vector3.new(0, 8, 0), Color = Color3.fromRGB(250, 250, 250), Material = Enum.Material.Marble, Parent = f })
		part({ Name = "CraneNeck", Size = Vector3.new(0.8, 6, 0.8), CFrame = CFrame.new(base + Vector3.new(0, 12, -2.5)) * CFrame.Angles(math.rad(-15), 0, 0), Color = Color3.fromRGB(250, 250, 250), Material = Enum.Material.Marble, Parent = f })
		part({ Name = "CraneCrest", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), Position = base + Vector3.new(0, 15.2, -3.4), Color = Color3.fromRGB(220, 30, 40), Material = Enum.Material.SmoothPlastic, Parent = f })
		for _, sx in ipairs({ -1, 1 }) do
			part({ Name = "CraneWing", Size = Vector3.new(10, 0.5, 4), CFrame = CFrame.new(base + Vector3.new(sx * 6, 10, 0)) * CFrame.Angles(0, 0, sx * math.rad(25)), Color = Color3.fromRGB(245, 245, 245), Material = Enum.Material.Marble, Parent = f })
			part({ Name = "CraneWingTip", Size = Vector3.new(3, 0.55, 4.2), CFrame = CFrame.new(base + Vector3.new(sx * 11.5, 12.6, 0)) * CFrame.Angles(0, 0, sx * math.rad(25)), Color = Color3.fromRGB(30, 30, 35), Material = Enum.Material.SmoothPlastic, Parent = f })
		end
	end
	for _ = 1, 18 do
		local a, rr = rng:NextNumber() * math.pi * 2, rng:NextNumber(50, 165)
		pine(cr + Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr), rng:NextNumber(1.2, 2), f, false)
	end

	-- 2.7판 운무 죽림: 구름 속 대숲. 마디 있는 대나무 무리, 가운데를 지나는 돌길, 대나무 정자, 낮게 깔린 안개
	local bb = I.bamboo.at
	local BAMBOO_C = Color3.fromRGB(104, 160, 64)
	local function bambooStalk(p0: Vector3, h: number, d: number, lean: number, yaw: number)
		local cf = CFrame.new(p0) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(lean, 0, 0)
		part({ Name = "Bamboo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, d, d), CFrame = cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = BAMBOO_C:Lerp(Color3.fromRGB(140, 184, 80), rng:NextNumber()), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
		for k = 1, math.floor(h / 4) do
			part({ Name = "BambooNode", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, d * 1.15, d * 1.15), CFrame = cf * CFrame.new(0, k * 4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(176, 196, 112), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
		end
		for k = 0, 2 do
			local a = k * 2.1 + yaw
			part({ Name = "BambooLeaves", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 1.6, 3), CFrame = cf * CFrame.new(math.cos(a) * 2, h - 1 - k * 1.5, math.sin(a) * 2) * CFrame.Angles(0, -a, math.rad(-15)), Color = Color3.fromRGB(80, 140, 58):Lerp(Color3.fromRGB(120, 176, 80), rng:NextNumber()), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
		end
	end
	-- 돌길: 다리에서 가운데로, 가운데에서 서쪽 정자로
	local toCrane = (I.crane.at - bb) * Vector3.new(1, 0, 1)
	toCrane = toCrane.Unit
	for k = 0, 16 do
		local p = bb + toCrane * (170 - k * 10)
		part({ Name = "BambooPath", Size = Vector3.new(7, 0.3, 5), CFrame = CFrame.lookAt(p, p + toCrane) * CFrame.new(rng:NextNumber(-0.6, 0.6), 0.1, 0) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0), Color = Color3.fromRGB(150, 150, 140), Material = Enum.Material.Slate, Parent = f })
	end
	for _ = 1, 46 do
		local a, rr = rng:NextNumber() * math.pi * 2, rng:NextNumber(36, 168)
		local p = bb + Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr)
		-- 길과 가운데 빈터는 비워 둔다
		local along = (p - bb):Dot(toCrane)
		local off = ((p - bb) - toCrane * along).Magnitude
		if not (along > 0 and off < 10) then
			for _ = 1, rng:NextInteger(3, 6) do
				bambooStalk(p + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)), rng:NextNumber(18, 32), rng:NextNumber(0.8, 1.3), rng:NextNumber(-0.08, 0.08), rng:NextNumber(0, 6))
			end
		end
	end
	-- 대나무 정자 (가운데 서쪽)
	local pv = bb + Vector3.new(-70, 0, 0)
	part({ Name = "BambooDeck", Size = Vector3.new(20, 1, 20), Position = pv + Vector3.new(0, 0.5, 0), Color = Color3.fromRGB(170, 150, 100), Material = Enum.Material.Wood, Parent = f })
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part({ Name = "BambooPost", Shape = Enum.PartType.Cylinder, Size = Vector3.new(11, 1.1, 1.1), CFrame = CFrame.new(pv + Vector3.new(sx * 8.5, 6.5, sz * 8.5)) * CFrame.Angles(0, 0, math.rad(90)), Color = BAMBOO_C, Material = Enum.Material.SmoothPlastic, Parent = f })
		end
	end
	part({ Name = "BambooRoof", Size = Vector3.new(24, 1.2, 24), Position = pv + Vector3.new(0, 12.4, 0), Color = Color3.fromRGB(180, 160, 100), Material = Enum.Material.Fabric, Parent = f })
	part({ Name = "BambooRoof2", Size = Vector3.new(14, 1.2, 14), Position = pv + Vector3.new(0, 13.8, 0), Color = Color3.fromRGB(160, 140, 90), Material = Enum.Material.Fabric, Parent = f })
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local p = bb + Vector3.new(math.cos(a) * rng:NextNumber(40, 150), 1.2, math.sin(a) * rng:NextNumber(40, 150))
		part({ Name = "BambooMist", Shape = Enum.PartType.Ball, Size = Vector3.new(rng:NextNumber(30, 50), 3, rng:NextNumber(30, 50)), Position = p, Color = Color3.fromRGB(245, 248, 250), Material = Enum.Material.SmoothPlastic, Transparency = 0.6, CanCollide = false, Parent = f })
	end

	-- 2.7판 월광 호수: 섬 북쪽의 넓은 호수, 호수에 비친 달, 한가운데 작은 섬의 흰 팔각정과 그리로 가는 돌다리, 연잎과 연꽃, 하늘의 큰 달
	local ml = I.moonlake.at
	local lakeC = ml + Vector3.new(0, 0, 30)
	disc("MoonLake", lakeC + Vector3.new(0, 0.3, 0), 95, 0.3, Color3.fromRGB(70, 110, 170), Enum.Material.Glass, f, false).Transparency = 0.15
	disc("MoonLakeEdge", lakeC + Vector3.new(0, 0.2, 0), 99, 0.3, Color3.fromRGB(220, 226, 236), Enum.Material.Marble, f, false)
	disc("MoonReflect", lakeC + Vector3.new(20, 0.5, 30), 14, 0.1, Color3.fromRGB(235, 242, 255), Enum.Material.Neon, f, false).Transparency = 0.35
	disc("MoonIsle", lakeC + Vector3.new(0, 0.6, 0), 22, 1.2, Color3.fromRGB(226, 230, 240), Enum.Material.Marble, f)
	-- 팔각정
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		part({ Name = "MoonPavilionPost", Size = Vector3.new(1.2, 12, 1.2), Position = lakeC + Vector3.new(math.cos(a) * 12, 7.2, math.sin(a) * 12), Color = Color3.fromRGB(240, 242, 248), Material = Enum.Material.Marble, Parent = f })
	end
	disc("MoonPavilionRoof", lakeC + Vector3.new(0, 13.6, 0), 16, 1.2, Color3.fromRGB(70, 90, 140), Enum.Material.Slate, f)
	disc("MoonPavilionRoof2", lakeC + Vector3.new(0, 15, 0), 10, 1.2, Color3.fromRGB(80, 100, 155), Enum.Material.Slate, f)
	part({ Name = "MoonPavilionTop", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), Position = lakeC + Vector3.new(0, 16.5, 0), Color = Color3.fromRGB(230, 236, 255), Material = Enum.Material.Glass, Parent = f })
	-- 돌다리 (남쪽 물가에서 섬으로)
	for k = 0, 9 do
		part({ Name = "MoonBridge", Size = Vector3.new(6, 1, 8.4), Position = lakeC + Vector3.new(0, 0.8 + math.sin(k / 9 * math.pi) * 1.5, -96 + 22 + k * 7.4), Color = Color3.fromRGB(220, 224, 232), Material = Enum.Material.Marble, Parent = f })
	end
	-- 연잎과 연꽃
	for _ = 1, 30 do
		local a, rr = rng:NextNumber() * math.pi * 2, rng:NextNumber(28, 88)
		local p = lakeC + Vector3.new(math.cos(a) * rr, 0.5, math.sin(a) * rr)
		disc("LotusLeaf", p, rng:NextNumber(1.6, 3.2), 0.2, Color3.fromRGB(70, 130, 70), Enum.Material.SmoothPlastic, f, false)
		if rng:NextNumber() < 0.4 then
			part({ Name = "LotusFlower", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.0, 1.4), Position = p + Vector3.new(0.5, 0.5, 0), Color = Color3.fromRGB(250, 200, 220), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
		end
	end
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		stoneLantern(lakeC + Vector3.new(math.cos(a) * 104, 0, math.sin(a) * 104) - Vector3.new(0, 0, 0), f, true)
	end
	local moon = part({ Name = "SkyMoon", Shape = Enum.PartType.Ball, Size = Vector3.new(40, 40, 40), Position = lakeC + Vector3.new(60, 140, 120), Color = Color3.fromRGB(240, 244, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	moon.Transparency = 0.1
	light(moon, Color3.fromRGB(200, 215, 255), 60, 1.2)

	-- 2.7판 금운사: 금빛 다섯 층 탑, 넓은 돌계단, 사자 석상 둘, 큰 종이 걸린 종각, 향로
	local gt = I.goldtemple.at
	local GOLDEN = Color3.fromRGB(232, 190, 90)
	local RED_WOOD = Color3.fromRGB(150, 50, 36)
	local pagoda = gt + Vector3.new(0, 0, -150)
	disc("TempleBase", pagoda + Vector3.new(0, 1, 0), 34, 2, Color3.fromRGB(236, 226, 200), Enum.Material.Marble, f)
	for i = 0, 4 do
		local w = 30 - i * 5
		local y = 2 + i * 11
		part({ Name = "PagodaFloor", Size = Vector3.new(w, 9, w), Position = pagoda + Vector3.new(0, y + 4.5, 0), Color = RED_WOOD, Material = Enum.Material.Wood, Parent = f })
		part({ Name = "PagodaRoof", Size = Vector3.new(w + 8, 1.6, w + 8), Position = pagoda + Vector3.new(0, y + 9.8, 0), Color = GOLDEN, Material = Enum.Material.Metal, Parent = f })
		for _, cx in ipairs({ -1, 1 }) do
			for _, cz in ipairs({ -1, 1 }) do
				part({ Name = "PagodaEave", Size = Vector3.new(3, 1.2, 3), CFrame = CFrame.new(pagoda + Vector3.new(cx * (w / 2 + 4), y + 10.6, cz * (w / 2 + 4))) * CFrame.Angles(cz * math.rad(18), 0, -cx * math.rad(18)), Color = GOLDEN, Material = Enum.Material.Metal, Parent = f })
			end
		end
	end
	local spireTop = part({ Name = "PagodaSpire", Size = Vector3.new(1.6, 14, 1.6), Position = pagoda + Vector3.new(0, 64, 0), Color = GOLDEN, Material = Enum.Material.Metal, Parent = f })
	local _ = spireTop
	local jewel = part({ Name = "PagodaJewel", Shape = Enum.PartType.Ball, Size = Vector3.new(3.4, 3.4, 3.4), Position = pagoda + Vector3.new(0, 72, 0), Color = Color3.fromRGB(255, 230, 150), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	light(jewel, Color3.fromRGB(255, 220, 140), 40, 1.6)
	-- 계단 (남쪽 다리에서 탑 쪽으로)
	for k = 0, 7 do
		part({ Name = "TempleStep", Size = Vector3.new(30, 1, 4), Position = gt + Vector3.new(0, 0.5 + k * 0.6, 40 - k * 4), Color = Color3.fromRGB(230, 222, 200), Material = Enum.Material.Marble, Parent = f })
	end
	-- 사자 석상 둘 (계단 양옆)
	for _, sx in ipairs({ -1, 1 }) do
		local base = gt + Vector3.new(sx * 22, 0, 44)
		part({ Name = "LionPlinth", Size = Vector3.new(7, 4, 9), Position = base + Vector3.new(0, 2, 0), Color = Color3.fromRGB(200, 190, 170), Material = Enum.Material.Granite, Parent = f })
		part({ Name = "LionBody", Size = Vector3.new(4.5, 4, 7), Position = base + Vector3.new(0, 6, 0.5), Color = GOLDEN, Material = Enum.Material.Metal, Parent = f })
		part({ Name = "LionHead", Shape = Enum.PartType.Ball, Size = Vector3.new(4.5, 4.5, 4.5), Position = base + Vector3.new(0, 9.4, -2.6), Color = GOLDEN, Material = Enum.Material.Metal, Parent = f })
		part({ Name = "LionMane", Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 3.5), Position = base + Vector3.new(0, 9.4, -1.6), Color = Color3.fromRGB(200, 150, 60), Material = Enum.Material.Metal, Parent = f })
		part({ Name = "LionPaw", Shape = Enum.PartType.Ball, Size = Vector3.new(2, 1.6, 2), Position = base + Vector3.new(sx * -1.2, 4.6, -3.4), Color = GOLDEN, Material = Enum.Material.Metal, Parent = f })
	end
	-- 종각과 큰 종
	local bell = gt + Vector3.new(90, 0, -40)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part({ Name = "BellPost", Size = Vector3.new(1.4, 16, 1.4), Position = bell + Vector3.new(sx * 7, 8, sz * 7), Color = RED_WOOD, Material = Enum.Material.Wood, Parent = f })
		end
	end
	part({ Name = "BellRoof", Size = Vector3.new(20, 1.4, 20), Position = bell + Vector3.new(0, 16.6, 0), Color = GOLDEN, Material = Enum.Material.Metal, Parent = f })
	part({ Name = "TempleBell", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7, 6, 6), CFrame = CFrame.new(bell + Vector3.new(0, 11, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(140, 110, 70), Material = Enum.Material.Metal, Parent = f })
	part({ Name = "BellLip", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 6.6, 6.6), CFrame = CFrame.new(bell + Vector3.new(0, 7.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(160, 130, 80), Material = Enum.Material.Metal, Parent = f })
	-- 향로 (가운데)
	part({ Name = "Censer", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 4, 5), Position = gt + Vector3.new(0, 3, -10), Color = Color3.fromRGB(150, 120, 70), Material = Enum.Material.Metal, Parent = f })
	part({ Name = "CenserLeg", Size = Vector3.new(4, 2, 4), Position = gt + Vector3.new(0, 1, -10), Color = Color3.fromRGB(120, 95, 60), Material = Enum.Material.Metal, Parent = f })
	local smoke = part({ Name = "CenserGlow", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), Position = gt + Vector3.new(0, 5.4, -10), Color = Color3.fromRGB(255, 200, 120), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	light(smoke, Color3.fromRGB(255, 200, 120), 20, 1)

	-- 3.1판 윤회대: 가운데 환생 제단 (세 겹 단, 금테, 여섯 빛깔 기둥), 뒤편 (서쪽) 의 거대한 윤회륜, 둘레를 도는 구름 소용돌이
	-- 윤회륜과 구름 소용돌이는 화면이 천천히 돌린다 (RinneWheel · RinneVortex)
	local rd = I.rinnedae.at
	local RINGOLD = Color3.fromRGB(255, 214, 110)
	local INDIGO = Color3.fromRGB(120, 90, 255)
	for i = 1, 3 do
		disc("RinneAltarTier", rd + Vector3.new(0, i * 1.2 - 0.6, 0), 34 - i * 8, 1.2, Color3.fromRGB(240, 236, 250), Enum.Material.Marble, f)
		disc("RinneAltarTrim", rd + Vector3.new(0, i * 1.2 - 1.15, 0), 34 - i * 8 + 0.6, 0.3, RINGOLD, Enum.Material.Metal, f, false)
	end
	local altarTop = rd + Vector3.new(0, 3.6, 0)
	local seal = disc("RinneSeal", altarTop + Vector3.new(0, 0.05, 0), 8, 0.2, INDIGO, Enum.Material.Neon, f, false)
	seal.Transparency = 0.35
	local altar = part({ Name = "RinneAltar", Size = Vector3.new(4, 3, 4), CFrame = CFrame.new(altarTop + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, math.rad(45), 0), Color = Color3.fromRGB(235, 230, 248), Material = Enum.Material.Marble, Parent = f })
	local orb = part({ Name = "RinneOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), Position = altarTop + Vector3.new(0, 4.4, 0), Color = Color3.fromRGB(200, 180, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	light(orb, Color3.fromRGB(190, 160, 255), 30, 1.5)
	out.rinneAltar = prompt(altar, "환생하기 (길게 누르기)", "윤회대 · 환생 제단", "RinneAltar")
	out.rinneAltar.HoldDuration = 2
	-- 여섯 갈래 세상의 기둥
	local REALM_C = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 214, 90), Color3.fromRGB(255, 80, 80), Color3.fromRGB(110, 230, 140), Color3.fromRGB(110, 170, 255), Color3.fromRGB(200, 120, 255) }
	for k = 1, 6 do
		local a = (k - 1) / 6 * math.pi * 2 + math.pi / 6
		local p = rd + Vector3.new(math.cos(a) * 48, 0, math.sin(a) * 48)
		part({ Name = "RinnePillar", Size = Vector3.new(4, 22, 4), Position = p + Vector3.new(0, 11, 0), Color = Color3.fromRGB(240, 236, 250), Material = Enum.Material.Marble, Parent = f })
		part({ Name = "RinnePillarBand", Size = Vector3.new(4.4, 1, 4.4), Position = p + Vector3.new(0, 20, 0), Color = RINGOLD, Material = Enum.Material.Metal, Parent = f })
		local gem = part({ Name = "RinnePillarGem", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), Position = p + Vector3.new(0, 24, 0), Color = REALM_C[k], Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		light(gem, REALM_C[k], 16, 1)
	end
	-- 거대한 윤회륜 (서쪽, 세워져서 제단을 바라본다): 금 테 두 겹, 바퀴살 여덟, 굴대, 여섯 구슬
	local wf = Instance.new("Folder")
	wf.Name = "RinneWheel"
	wf.Parent = f
	local wc = rd + Vector3.new(-86, 34, 0)
	local hub = part({ Name = "RinneHub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 7, 7), CFrame = CFrame.new(wc), Color = RINGOLD, Material = Enum.Material.Metal, CanCollide = false, Parent = wf })
	local R = 26
	local function onWheel(name: string, size: Vector3, local_: CFrame, color: Color3, mat: Enum.Material, shape: Enum.PartType?)
		local p = part({ Name = name, Size = size, CFrame = CFrame.new(wc) * CFrame.Angles(0, math.rad(90), 0) * local_, Color = color, Material = mat, CanCollide = false, Parent = wf })
		if shape then
			p.Shape = shape
		end
		return p
	end
	local n = 40
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * math.pi * 2
		onWheel("RinneRim", Vector3.new(2 * math.pi * R / n * 1.1, 2.2, 2), CFrame.Angles(0, 0, a) * CFrame.new(0, R, 0), RINGOLD, Enum.Material.Metal)
		if i % 2 == 0 then
			onWheel("RinneInner", Vector3.new(2 * math.pi * R * 0.7 / n * 2.2, 0.9, 0.9), CFrame.Angles(0, 0, a) * CFrame.new(0, R * 0.7, 0), INDIGO, Enum.Material.Neon)
		end
	end
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		onWheel("RinneSpoke", Vector3.new(1.2, R * 0.95, 1.2), CFrame.Angles(0, 0, a) * CFrame.new(0, R * 0.5, 0), Color3.fromRGB(220, 160, 50), Enum.Material.Metal)
	end
	for k = 1, 6 do
		local a = (k - 1) / 6 * math.pi * 2
		local g = onWheel("RinneRealm", Vector3.new(4.4, 4.4, 4.4), CFrame.Angles(0, 0, a) * CFrame.new(0, R, 0), REALM_C[k], Enum.Material.Neon, Enum.PartType.Ball)
		light(g, REALM_C[k], 14, 0.8)
	end
	light(hub, RINGOLD, 60, 1.6)
	-- 바퀴를 받치는 두 기둥과 받침
	for _, z in ipairs({ -1, 1 }) do
		part({ Name = "RinneWheelPost", Size = Vector3.new(4, 36, 4), Position = rd + Vector3.new(-86, 18, z * 6), Color = Color3.fromRGB(235, 230, 248), Material = Enum.Material.Marble, Parent = f })
	end
	part({ Name = "RinneWheelBase", Size = Vector3.new(14, 2, 20), Position = rd + Vector3.new(-86, 1, 0), Color = Color3.fromRGB(225, 220, 240), Material = Enum.Material.Marble, Parent = f })
	-- 제단으로 이어지는 길 (다리 쪽, 동쪽에서)
	for k = 0, 8 do
		part({ Name = "RinnePath", Size = Vector3.new(8, 0.3, 6), Position = rd + Vector3.new(30 + k * 10, 0.15, 0), Color = Color3.fromRGB(240, 236, 250), Material = Enum.Material.Marble, Parent = f })
	end
	-- 둘레를 도는 구름 소용돌이 (세 갈래 나선)
	local vortex = Instance.new("Folder")
	vortex.Name = "RinneVortex"
	vortex.Parent = f
	for arm = 0, 2 do
		for k = 0, 13 do
			local a = arm / 3 * math.pi * 2 + k * 0.28
			local r = 150 + k * 6
			local sz = 26 - k * 0.9
			part({ Name = "RinneVortexCloud", Shape = Enum.PartType.Ball, Size = Vector3.new(sz * 1.4, sz * 0.5, sz), Position = rd + Vector3.new(math.cos(a) * r, -14 - k * 1.2, math.sin(a) * r), Color = Color3.fromRGB(240, 236, 255):Lerp(Color3.fromRGB(200, 180, 255), k / 14), Material = Enum.Material.SmoothPlastic, Transparency = 0.2 + k * 0.03, CanCollide = false, Parent = vortex })
		end
	end
end

local arenas: { [number]: Vector3 } = {}
function World.towerArena(slot: number): Vector3
	local T = Config.TOWER
	local center = T.arena + Vector3.new((slot - 1) * T.slotGap, 0, 0)
	if arenas[slot] then
		return center
	end
	local f = Instance.new("Folder")
	f.Name = "TowerArena" .. slot
	f.Parent = folder
	local R = T.radius
	disc("ArenaFloor", center - Vector3.new(0, 2, 0), R, 4, Color3.fromRGB(165, 155, 140), Enum.Material.Slate, f)
	disc("ArenaUnder", center - Vector3.new(0, 7, 0), R * 0.8, 6, STONE_DARK, Enum.Material.Granite, f)
	disc("ArenaUnder2", center - Vector3.new(0, 13, 0), R * 0.5, 6, STONE_DARK, Enum.Material.Granite, f)
	disc("ArenaRing", center + Vector3.new(0, 0.05, 0), R * 0.55, 0.2, Color3.fromRGB(200, 60, 50), Enum.Material.Fabric, f, false)
	disc("ArenaCore", center + Vector3.new(0, 0.1, 0), R * 0.5, 0.2, Color3.fromRGB(150, 140, 125), Enum.Material.Slate, f, false)
	disc("ArenaTrim", center - Vector3.new(0, 0.2, 0), R + 0.8, 0.6, GOLD, Enum.Material.Metal, f)
	-- 둘레의 낮은 난간과 여덟 기둥 (꼭대기에 불)
	local n = 24
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * (R - 1), 1.5, math.sin(a) * (R - 1))
		part({ Name = "ArenaRail", Size = Vector3.new(2 * math.pi * R / n + 0.4, 3, 1.2), CFrame = CFrame.lookAt(p, Vector3.new(center.X, p.Y, center.Z)) * CFrame.Angles(0, math.rad(90), 0), Color = STONE, Material = Enum.Material.Marble, Parent = f })
	end
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * (R + 2), 0, math.sin(a) * (R + 2))
		part({ Name = "ArenaPillar", Size = Vector3.new(3, 16, 3), Position = p + Vector3.new(0, 8, 0), Color = GATE_RED, Material = Enum.Material.Wood, Parent = f })
		brazier(p + Vector3.new(0, 16, 0), 1, f)
	end
	arenas[slot] = center
	return center
end

-- 1.7판 구름 미궁: 사람마다 한 줄. 일곱 방(둥근 구름 단)을 구름 다리로 잇고, 다리 입구마다 구름 문을 둔다
-- 돌려주는 것: { centers = 방 가운데들, gates = 다리마다 구름 문, chest = 보물방의 상자 (T) }
local mazes: { [number]: any } = {}
function World.mazeRooms(slot: number): any
	local M = Config.MAZE
	if mazes[slot] then
		return mazes[slot]
	end
	local base = M.arena + Vector3.new((slot - 1) * M.slotGap, 0, 0)
	local f = Instance.new("Folder")
	f.Name = "CloudMaze" .. slot
	f.Parent = folder
	local R = M.roomRadius
	local out = { centers = {}, gates = {}, chest = nil :: any }
	local n = #M.rooms
	for i, room in ipairs(M.rooms) do
		local c = base + Vector3.new(0, 0, (i - 1) * M.roomGap)
		out.centers[i] = c
		disc("MazeFloor", c - Vector3.new(0, 2, 0), R, 4, Color3.fromRGB(240, 242, 248), Enum.Material.Marble, f)
		disc("MazeTint", c + Vector3.new(0, 0.05, 0), R * 0.62, 0.2, room.color, Enum.Material.Neon, f, false).Transparency = 0.75
		disc("MazeTrim", c - Vector3.new(0, 0.2, 0), R + 0.8, 0.6, room.color, Enum.Material.Metal, f)
		disc("MazeUnder", c - Vector3.new(0, 8, 0), R * 0.7, 8, Color3.fromRGB(220, 225, 235), Enum.Material.SmoothPlastic, f)
		-- 아래쪽 구름 뭉치
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			local size = 14 + (k % 3) * 5
			part({ Name = "MazeCloud", Shape = Enum.PartType.Ball, Size = Vector3.new(size, size, size), Position = c + Vector3.new(math.cos(a) * R * 0.85, -9 - (k % 2) * 4, math.sin(a) * R * 0.85), Color = Color3.fromRGB(250, 250, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.15, CanCollide = false, Parent = f })
		end
		-- 보이지 않는 둘레 벽 (앞뒤 다리 자리는 비운다)
		local m = 36
		for k = 0, m - 1 do
			local a = k / m * math.pi * 2
			local dz = math.sin(a)
			local toNext = i < n and dz > 0.97
			local toPrev = i > 1 and dz < -0.97
			if not toNext and not toPrev then
				local p = c + Vector3.new(math.cos(a) * (R + 0.5), 7, math.sin(a) * (R + 0.5))
				part({ Name = "MazeWall", Size = Vector3.new(2 * math.pi * R / m + 1, 14, 1), CFrame = CFrame.lookAt(p, Vector3.new(c.X, p.Y, c.Z)), Transparency = 1, Parent = f })
			end
		end
		-- 네 귀의 빛기둥 (방의 빛깔)
		for k = 0, 3 do
			local a = math.pi / 4 + k * math.pi / 2
			local p = c + Vector3.new(math.cos(a) * (R - 3), 0, math.sin(a) * (R - 3))
			part({ Name = "MazePost", Size = Vector3.new(2, 12, 2), Position = p + Vector3.new(0, 6, 0), Color = Color3.fromRGB(245, 245, 250), Material = Enum.Material.Marble, Parent = f })
			crystal(p + Vector3.new(0, 14, 0), 2, room.color, f)
		end
		if room.kind == "treasure" then
			local chest = part({ Name = "MazeChest", Size = Vector3.new(6, 4, 4), Position = c + Vector3.new(0, 2, 0), Color = Color3.fromRGB(130, 80, 40), Material = Enum.Material.Wood, Parent = f })
			part({ Name = "MazeChestLid", Size = Vector3.new(6.4, 1.2, 4.4), Position = c + Vector3.new(0, 4.6, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = f })
			light(chest, Color3.fromRGB(255, 210, 120), 20, 1.5)
			out.chest = prompt(chest, "열기", "보물 상자", "MazeChest")
		end
		-- 다음 방으로 가는 구름 다리와 그 입구의 구름 문
		if i < n then
			local from = c + Vector3.new(0, 0, R - 2)
			local to = c + Vector3.new(0, 0, M.roomGap - R + 2)
			local len = (to - from).Magnitude
			local mid = (from + to) / 2
			part({ Name = "MazeBridge", Size = Vector3.new(12, 1, len), Position = mid - Vector3.new(0, 0.5, 0), Color = Color3.fromRGB(235, 240, 250), Material = Enum.Material.Marble, Parent = f })
			for _, x in ipairs({ -1, 1 }) do
				part({ Name = "MazeBridgeWall", Size = Vector3.new(1, 10, len), Position = mid + Vector3.new(x * 6.5, 5, 0), Transparency = 1, Parent = f })
				part({ Name = "MazeBridgeCurb", Size = Vector3.new(0.8, 1, len), Position = mid + Vector3.new(x * 5.6, 0.5, 0), Color = room.color, Material = Enum.Material.Neon, Parent = f })
			end
			local gate = part({ Name = "MazeGate", Size = Vector3.new(12, 14, 1.5), Position = c + Vector3.new(0, 7, R + 1), Color = Color3.fromRGB(230, 240, 255), Material = Enum.Material.ForceField, Transparency = 0.2, Parent = f })
			out.gates[i] = gate
		end
	end
	mazes[slot] = out
	return out
end

-- 구름 문을 닫거나 (true) 걷는다 (false)
function World.mazeGate(gate: BasePart, closed: boolean)
	gate.CanCollide = closed
	gate.Transparency = closed and 0.2 or 1
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
		{ "벚꽃 언덕", sakuraHill },
		{ "술독 마루", sojuHill },
		{ "혈월 제단", reaperAltar },
		{ "쇠기둥 봉우리", thunderPeak },
		{ "고래 뼈 바위", whaleRock },
		{ "관성대", starTerrace },
		{ "들판 채우기", wilds },
		{ "각성선인", function()
			awakenAltar(out)
		end },
		{ "천상계", function()
			skyWorld(out)
		end },
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
