-- 권왕 3.66판: 배틀그라운드 대기실의 권법 전시장 (엘리멘탈 아레나처럼). 대기실 남쪽 문 밖의 넓은 돌 마당
--   모든 권법 (익히지 않은 것까지) 이 한 칸씩: 권법 빛깔 마네킹 (그 권법 자세) · 권법마다 다른 상징물 · 나무 푯말 · 밟는 발판
--   누구에게나 같은 전시장 (서버가 짓는다). 잠금 표시 · 밟아서 들어가기 · 시범 동작 · 장신구는 저마다의 화면이 한다 (Gallery.lua)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local StyleHall = {}

local PER_ROW = 11 -- 3.67판: 16 → 11 (간격을 넓혀 여섯 줄)
local DX, DZ = 24, 34 -- 3.67판: 14.5 · 25 → 24 · 34
local MARGIN = 30 -- 플랫폼 가장자리 여유
local S = 1.5 -- 마네킹 키 배율
local INK = Color3.fromRGB(16, 18, 24)
local WOOD = Color3.fromRGB(120, 82, 52)

local function part(props: { [string]: any }): BasePart
	local p = Instance.new(props.Class or "Part") :: BasePart
	p.Anchored = props.Anchored ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	p.CastShadow = props.CastShadow == true
	for k, v in pairs(props) do
		if k == "Position" then
			p.CFrame = CFrame.new(v)
		elseif k ~= "Class" and k ~= "Parent" and k ~= "Anchored" and k ~= "CastShadow" then
			(p :: any)[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end
local function disc(name: string, at: Vector3, r: number, h: number, color: Color3, mat: Enum.Material, parent: Instance, alpha: number?, collide: boolean?): BasePart
	return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, r * 2, r * 2), CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = mat, Transparency = alpha or 0, CanCollide = collide == true, Parent = parent })
end
local function ball(name: string, at: Vector3, d: number, color: Color3, mat: Enum.Material, parent: Instance, alpha: number?): BasePart
	return part({ Name = name, Shape = Enum.PartType.Ball, Size = Vector3.one * d, Position = at, Color = color, Material = mat, Transparency = alpha or 0, CanCollide = false, Parent = parent })
end
-- 도는 조각 (이름이 Spin으로 시작하면 화면이 돌린다. SpinRate 속성 = 초당 바퀴)
local function spin(p: BasePart, rate: number): BasePart
	p.Name = "Spin" .. p.Name
	p:SetAttribute("SpinRate", rate)
	return p
end
local function light(p: BasePart, color: Color3, range: number, br: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = br
	l.Parent = p
end
local function particles(p: BasePart, tex: string, c1: Color3, c2: Color3, size: number, rate: number, speed: number, life: number, up: number?)
	local e = Instance.new("ParticleEmitter")
	e.Texture = tex
	e.Color = ColorSequence.new(c1, c2)
	e.Size = NumberSequence.new(size, 0)
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Lifetime = NumberRange.new(life * 0.7, life)
	e.Speed = NumberRange.new(speed * 0.6, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, up or 0, 0)
	e.LightEmission = 1
	e.Rate = rate
	e.Parent = p
end
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

-- 권법마다 다른 상징물 (fx 갈래마다 모양이 다르다). at = 상징물 가운데
local EMBLEM: { [string]: (Vector3, Color3, Color3, Instance) -> () } = {}
EMBLEM.fire = function(at, c1, c2, f)
	-- 불기둥: 아래가 넓은 불꽃 셋이 겹쳐 타오른다
	for k = 0, 2 do
		local p = part({ Name = "Flame", Size = Vector3.new(4.6 - k * 1.3, 4 + k * 1.6, 4.6 - k * 1.3), CFrame = CFrame.new(at + Vector3.new(0, -2 + k * 2.2, 0)) * CFrame.Angles(0, k * 0.7, math.rad(45)), Color = k == 2 and c2 or c1, Material = Enum.Material.Neon, Transparency = 0.15 + k * 0.1, CanCollide = false, Parent = f })
		if k == 0 then
			local fire = Instance.new("Fire")
			fire.Size = 9
			fire.Heat = 14
			fire.Color = c1
			fire.SecondaryColor = c2
			fire.Parent = p
			light(p, c1, 26, 2.4)
		end
	end
end
EMBLEM.karma = EMBLEM.fire
EMBLEM.water = function(at, c1, c2, f)
	-- 물방울 구: 맑은 물 구슬과 엇갈려 도는 물결 고리 둘
	local core = ball("WaterOrb", at, 6, c2, Enum.Material.Glass, f, 0.35)
	ball("WaterCore", at, 3, c1, Enum.Material.Neon, f, 0.3)
	for k = 0, 1 do
		spin(disc("Ripple", at, 5.4 + k * 1.4, 0.3, c1, Enum.Material.Neon, f, 0.4), k == 0 and 0.4 or -0.3).CFrame = CFrame.new(at) * CFrame.Angles(k == 0 and 0.6 or -0.6, 0, math.rad(90))
	end
	particles(core, SPARK, Color3.new(1, 1, 1), c2, 0.6, 10, 3, 1.2, -2)
	light(core, c1, 24, 1.8)
end
EMBLEM.ocean = EMBLEM.water
EMBLEM.lightning = function(at, c1, c2, f)
	-- 번개 수정: 세운 마름모 수정과 둘레를 도는 번개 조각
	local cr = part({ Name = "BoltCrystal", Size = Vector3.new(3.6, 3.6, 3.6), CFrame = CFrame.new(at) * CFrame.Angles(math.rad(45), 0, math.rad(45)), Color = c2, Material = Enum.Material.Neon, Transparency = 0.1, CanCollide = false, Parent = f })
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		spin(part({ Name = "Bolt", Size = Vector3.new(0.4, 3.4, 0.4), CFrame = CFrame.new(at + Vector3.new(math.cos(a) * 5, math.sin(k) * 1.5, math.sin(a) * 5)) * CFrame.Angles(0.3 * k, a, 0.6), Color = c1, Material = Enum.Material.Neon, CanCollide = false, Parent = f }), 0)
	end
	particles(cr, SPARK, Color3.new(1, 1, 1), c1, 0.8, 18, 8, 0.5)
	light(cr, c1, 26, 2.6)
end
EMBLEM.wind = function(at, c1, c2, f)
	-- 회오리: 위로 갈수록 넓어지는 고리가 저마다 다른 빠르기로 돈다
	for k = 0, 4 do
		spin(disc("Gust", at + Vector3.new(0, -3 + k * 1.6, 0), 1.6 + k * 1.1, 0.25, k % 2 == 0 and c1 or c2, Enum.Material.Neon, f, 0.35 + k * 0.08), 1.2 - k * 0.15).CFrame = CFrame.new(at + Vector3.new(0, -3 + k * 1.6, 0)) * CFrame.Angles(0.15, 0, math.rad(90))
	end
	local top = ball("GustEye", at + Vector3.new(0, 4, 0), 1.4, c2, Enum.Material.Neon, f)
	particles(top, SMOKE, c2, c1, 2, 6, 3, 1.5, 2)
	light(top, c1, 20, 1.4)
end
EMBLEM.cloud = EMBLEM.wind
EMBLEM.mist = function(at, c1, c2, f)
	-- 안개 구름: 뭉게구름 덩이 다섯과 그 사이의 은은한 빛
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		ball("Mist", at + Vector3.new(math.cos(a) * 2.6, math.sin(a * 2) * 0.8, math.sin(a) * 2.6), 4 + (k % 2), c2, Enum.Material.SmoothPlastic, f, 0.35)
	end
	local core = ball("MistCore", at, 2.4, c1, Enum.Material.Neon, f, 0.2)
	particles(core, SMOKE, c2, c1, 3, 5, 1.5, 3, 0.5)
	light(core, c1, 22, 1.4)
end
EMBLEM.gold = function(at, c1, c2, f)
	-- 금빛 연꽃: 꽃잎 여덟이 둘러 핀 가운데 빛나는 구슬
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		part({ Name = "Petal", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.2, 3.6), CFrame = CFrame.new(at) * CFrame.Angles(0, a, 0) * CFrame.new(0, -0.6, -2.4) * CFrame.Angles(math.rad(-30), 0, 0), Color = k % 2 == 0 and c1 or c2, Material = Enum.Material.Neon, Transparency = 0.1, CanCollide = false, Parent = f })
	end
	local core = ball("LotusCore", at + Vector3.new(0, 0.8, 0), 2.6, Color3.fromRGB(255, 240, 200), Enum.Material.Neon, f)
	spin(disc("Halo", at + Vector3.new(0, 1, 0), 4.6, 0.2, c1, Enum.Material.Neon, f, 0.5), 0.25)
	particles(core, SPARK, Color3.new(1, 1, 1), c1, 0.7, 10, 3, 1.2, 2)
	light(core, c1, 26, 2.2)
end
EMBLEM.king = function(at, c1, c2, f)
	-- 왕관: 금빛 띠와 뾰족한 끝 여섯, 끝마다 보석
	disc("CrownBand", at, 3, 1.4, c1, Enum.Material.Metal, f)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * 2.6, 1.8, math.sin(a) * 2.6)
		part({ Name = "CrownSpike", Size = Vector3.new(0.8, 2.6, 0.8), CFrame = CFrame.new(p) * CFrame.Angles(0, a, math.rad(-8)), Color = c1, Material = Enum.Material.Metal, CanCollide = false, Parent = f })
		ball("CrownGem", p + Vector3.new(0, 1.5, 0), 0.9, c2, Enum.Material.Neon, f)
	end
	local core = ball("CrownGlow", at + Vector3.new(0, 1, 0), 2, c2, Enum.Material.Neon, f, 0.3)
	spin(core, 0)
	light(core, c1, 24, 2)
end
EMBLEM.shadow = function(at, c1, c2, f)
	-- 그림자 구슬: 검은 구슬에서 연기가 피고 둘레를 날 셋이 돈다
	local core = ball("ShadowOrb", at, 4.6, Color3.fromRGB(14, 10, 20), Enum.Material.SmoothPlastic, f)
	ball("ShadowRim", at, 5.4, c1, Enum.Material.Neon, f, 0.75)
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		spin(part({ Name = "ShadowBlade", Size = Vector3.new(0.3, 0.8, 3.4), CFrame = CFrame.new(at + Vector3.new(math.cos(a) * 4.2, 0, math.sin(a) * 4.2)) * CFrame.Angles(0, -a, 0.4), Color = c2, Material = Enum.Material.Neon, CanCollide = false, Parent = f }), 0)
	end
	particles(core, SMOKE, c1, Color3.fromRGB(20, 10, 30), 3, 8, 2, 2, 1)
	light(core, c1, 20, 1.6)
end
EMBLEM.void = function(at, c1, c2, f)
	-- 빈칸: 흰 테두리의 검은 정육면체와 흩어진 작은 네모 조각
	part({ Name = "NullCube", Size = Vector3.new(4, 4, 4), CFrame = CFrame.new(at) * CFrame.Angles(0.5, 0.6, 0.3), Color = Color3.fromRGB(8, 8, 10), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
	local frame = part({ Name = "NullFrame", Size = Vector3.new(4.4, 4.4, 4.4), CFrame = CFrame.new(at) * CFrame.Angles(0.5, 0.6, 0.3), Color = c2, Material = Enum.Material.ForceField, Transparency = 0.3, CanCollide = false, Parent = f })
	for k = 0, 5 do
		spin(part({ Name = "Pixel", Size = Vector3.new(0.9, 0.9, 0.9), Position = at + Vector3.new(math.cos(k) * 4.4, math.sin(k * 2) * 2, math.sin(k) * 4.4), Color = k % 2 == 0 and Color3.new(1, 1, 1) or c1, Material = Enum.Material.Neon, CanCollide = false, Parent = f }), 0)
	end
	light(frame, c2, 20, 1.4)
end
EMBLEM.subspace = EMBLEM.void
EMBLEM.blood = function(at, c1, c2, f)
	-- 핏빛 초승달: 굽은 조각을 이어 큰 초승달 낫
	for k = 0, 10 do
		local a = math.rad(-80 + k * 16)
		local w = 1.6 * math.sin(math.rad(k / 10 * 180)) + 0.3
		part({ Name = "Crescent", Size = Vector3.new(0.6, w, 1.6), CFrame = CFrame.new(at) * CFrame.Angles(0, 0, a) * CFrame.new(0, 4, 0), Color = k % 3 == 0 and c2 or c1, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	local core = ball("BloodDrop", at, 1.6, c1, Enum.Material.Neon, f)
	particles(core, SPARK, c2, c1, 0.6, 8, 2, 1.5, -4)
	light(core, c1, 22, 2)
end
EMBLEM.celestial = function(at, c1, c2, f)
	-- 하늘의 문: 빛나는 둥근 문틀과 가운데 흰빛, 위로 빛살
	spin(disc("SkyGate", at, 4.4, 0.6, c1, Enum.Material.Neon, f, 0.2), 0.15).CFrame = CFrame.new(at) * CFrame.Angles(0, 0, 0)
	local core = ball("SkyLight", at, 3.6, Color3.fromRGB(255, 250, 230), Enum.Material.Neon, f, 0.15)
	part({ Name = "SkyRay", Size = Vector3.new(0.6, 12, 0.6), Position = at + Vector3.new(0, 7, 0), Color = c2, Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, Parent = f })
	particles(core, SPARK, Color3.new(1, 1, 1), c2, 0.8, 14, 4, 1.2, 3)
	light(core, c2, 28, 2.4)
end
EMBLEM.galaxy = function(at, c1, c2, f)
	-- 은하: 빛나는 별 가운데와 기울어진 두 겹 별 고리, 둘레를 도는 작은 별
	local core = ball("StarCore", at, 2.6, Color3.fromRGB(255, 250, 230), Enum.Material.Neon, f)
	for k = 0, 1 do
		spin(disc("StarRing", at, 4 + k * 1.6, 0.2, k == 0 and c1 or c2, Enum.Material.Neon, f, 0.35), 0.3 - k * 0.5).CFrame = CFrame.new(at) * CFrame.Angles(0.5, k * 0.6, math.rad(90))
	end
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		ball("Moon", at + Vector3.new(math.cos(a) * 5.4, math.sin(a) * 1.2, math.sin(a) * 5.4), 0.9, c2, Enum.Material.Neon, f)
	end
	particles(core, SPARK, Color3.new(1, 1, 1), c1, 0.6, 12, 2, 2)
	light(core, c1, 26, 2)
end
EMBLEM.origin = EMBLEM.galaxy
EMBLEM.eclipse = function(at, c1, c2, f)
	-- 일식: 검은 해와 그 뒤의 금빛 코로나
	ball("Corona", at, 6.4, c1, Enum.Material.Neon, f, 0.35)
	spin(disc("CoronaRing", at, 4.2, 0.3, c2, Enum.Material.Neon, f, 0.2), 0.2).CFrame = CFrame.new(at) * CFrame.Angles(0, 0, 0)
	local core = ball("BlackSun", at + Vector3.new(0, 0, -0.6), 5, Color3.fromRGB(10, 8, 12), Enum.Material.SmoothPlastic, f)
	light(core, c1, 26, 2.4)
end
EMBLEM.gravity = function(at, c1, c2, f)
	-- 블랙홀: 검은 알맹이와 눕혀 도는 빛의 원반
	local core = ball("Hole", at, 3.4, Color3.fromRGB(6, 4, 10), Enum.Material.SmoothPlastic, f)
	spin(disc("Accretion", at, 5, 0.25, c1, Enum.Material.Neon, f, 0.25), 0.6)
	spin(disc("Accretion2", at, 6.4, 0.2, c2, Enum.Material.Neon, f, 0.55), -0.4)
	particles(core, SPARK, c2, c1, 0.5, 12, -5, 1)
	light(core, c1, 22, 1.8)
end
EMBLEM.time = function(at, c1, c2, f)
	-- 시계 바퀴: 세운 둥근 판 · 눈금 열둘 · 도는 바늘
	disc("ClockFace", at, 4.2, 0.4, Color3.fromRGB(30, 26, 36), Enum.Material.SmoothPlastic, f).CFrame = CFrame.new(at) * CFrame.Angles(0, math.rad(90), 0)
	disc("ClockRim", at, 4.6, 0.3, c1, Enum.Material.Neon, f, 0.1).CFrame = CFrame.new(at) * CFrame.Angles(0, math.rad(90), 0)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		part({ Name = "Tick", Size = Vector3.new(0.3, 0.9, 0.3), CFrame = CFrame.new(at + Vector3.new(math.sin(a) * 3.6, math.cos(a) * 3.6, -0.3)) * CFrame.Angles(0, 0, -a), Color = c2, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	local hand = spin(part({ Name = "Hand", Size = Vector3.new(0.4, 3.4, 0.3), CFrame = CFrame.new(at + Vector3.new(0, 1.5, -0.5)), Color = c2, Material = Enum.Material.Neon, CanCollide = false, Parent = f }), 0)
	light(hand, c1, 22, 1.8)
end
EMBLEM.rinne = function(at, c1, c2, f)
	-- 윤회륜: 바퀴살 여섯의 금빛 바퀴가 돈다
	local wheel = spin(disc("Wheel", at, 4.4, 0.6, c1, Enum.Material.Neon, f, 0.2), 0.2)
	wheel.CFrame = CFrame.new(at) * CFrame.Angles(0, math.rad(90), 0)
	for k = 0, 5 do
		local a = k / 6 * math.pi
		part({ Name = "Spoke", Size = Vector3.new(0.4, 8.4, 0.4), CFrame = CFrame.new(at + Vector3.new(0, 0, -0.4)) * CFrame.Angles(0, 0, a), Color = c2, Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	end
	light(wheel, c1, 24, 2)
end
EMBLEM.dragon = function(at, c1, c2, f)
	-- 여의주와 휘감아 오르는 용의 몸 (구슬을 나선으로 잇는다)
	local pearl = ball("Pearl", at + Vector3.new(0, 3, 0), 2.4, Color3.fromRGB(255, 245, 210), Enum.Material.Neon, f)
	for k = 0, 13 do
		local a = k / 14 * math.pi * 3.2
		local r = 3.6 - k * 0.12
		ball("DragonBody", at + Vector3.new(math.cos(a) * r, -4 + k * 0.6, math.sin(a) * r), 1.8 - k * 0.07, k % 2 == 0 and c1 or c1:Lerp(c2, 0.3), Enum.Material.Neon, f, 0.1)
	end
	particles(pearl, SPARK, Color3.new(1, 1, 1), c2, 0.6, 10, 2, 1.2, 2)
	light(pearl, c1, 26, 2.2)
end
EMBLEM.petal = function(at, c1, c2, f)
	-- 큰 꽃: 꽃잎 다섯과 가운데 꽃술, 흩날리는 꽃잎
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		part({ Name = "FlowerPetal", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 0.6, 4.4), CFrame = CFrame.new(at) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -2.6) * CFrame.Angles(math.rad(-20), 0, 0), Color = c1, Material = Enum.Material.Neon, Transparency = 0.1, CanCollide = false, Parent = f })
	end
	local core = ball("Pistil", at + Vector3.new(0, 0.3, 0), 1.8, c2, Enum.Material.Neon, f)
	particles(core, SPARK, c1, c2, 0.8, 8, 3, 2.5, -1)
	light(core, c1, 22, 1.8)
end
EMBLEM.nature = function(at, c1, c2, f)
	-- 어린 나무: 줄기와 둥근 잎 덩이 셋
	part({ Name = "Sapling", Size = Vector3.new(0.8, 6, 0.8), Position = at + Vector3.new(0, -2, 0), Color = Color3.fromRGB(110, 76, 48), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		ball("Leaf", at + Vector3.new(math.cos(a) * 1.6, 1.6 + k * 0.4, math.sin(a) * 1.6), 3.6, k == 1 and c2 or c1, Enum.Material.Grass, f)
	end
	local glow = ball("LeafGlow", at + Vector3.new(0, 2, 0), 2, c2, Enum.Material.Neon, f, 0.4)
	particles(glow, SPARK, c2, c1, 0.6, 8, 2, 2, -1)
	light(glow, c1, 20, 1.4)
end
EMBLEM.ice = function(at, c1, c2, f)
	-- 얼음 결정: 세운 얼음 기둥 다섯이 별처럼 뻗는다
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		part({ Name = "IceSpike", Size = Vector3.new(1.4, 6 - (k % 2) * 1.6, 1.4), CFrame = CFrame.new(at) * CFrame.Angles(math.cos(a) * 0.6, 0, math.sin(a) * 0.6), Color = c2, Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, Parent = f })
	end
	local core = ball("IceCore", at, 2, Color3.fromRGB(230, 250, 255), Enum.Material.Neon, f)
	particles(core, SPARK, Color3.new(1, 1, 1), c2, 0.5, 10, 2, 1.6, -1)
	light(core, c2, 22, 1.8)
end
EMBLEM.drunk = function(at, c1, c2, f)
	-- 호리병: 두 구슬을 포갠 병과 마개, 흔들리는 술 방울
	ball("GourdBottom", at + Vector3.new(0, -1.4, 0), 4.4, c1, Enum.Material.SmoothPlastic, f)
	ball("GourdTop", at + Vector3.new(0, 1.6, 0), 3, c1, Enum.Material.SmoothPlastic, f)
	part({ Name = "GourdCord", Size = Vector3.new(3.2, 0.4, 3.2), Position = at + Vector3.new(0, 0.2, 0), Color = Color3.fromRGB(190, 40, 40), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
	local cork = part({ Name = "Cork", Size = Vector3.new(0.9, 1, 0.9), Position = at + Vector3.new(0, 3.4, 0), Color = Color3.fromRGB(160, 120, 80), Material = Enum.Material.Wood, CanCollide = false, Parent = f })
	particles(cork, SPARK, c2, c1, 0.6, 6, 2, 1.5, -3)
	light(cork, c2, 18, 1.2)
end
EMBLEM.sand = function(at, c1, c2, f)
	-- 모래시계
	for _, sy in ipairs({ -1, 1 }) do
		disc("HourCap", at + Vector3.new(0, sy * 3.2, 0), 2.4, 0.5, Color3.fromRGB(110, 80, 50), Enum.Material.Wood, f)
		part({ Name = "HourGlass", Shape = Enum.PartType.Ball, Size = Vector3.new(3.4, 3, 3.4), Position = at + Vector3.new(0, sy * 1.5, 0), Color = Color3.fromRGB(220, 235, 245), Material = Enum.Material.Glass, Transparency = 0.5, CanCollide = false, Parent = f })
	end
	local sand = ball("Sand", at + Vector3.new(0, -1.8, 0), 2, c1, Enum.Material.Sand, f)
	light(sand, c1, 18, 1.2)
end
EMBLEM.duel = function(at, c1, c2, f)
	-- 맞부딪친 두 주먹 (엇갈린 두 막대와 가운데 불꽃)
	for _, k in ipairs({ -1, 1 }) do
		part({ Name = "Fist", Size = Vector3.new(1.8, 1.8, 4.4), CFrame = CFrame.new(at + Vector3.new(k * 2, 0, 0)) * CFrame.Angles(0, k * math.rad(60), 0), Color = c1, Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
	end
	local spark = ball("Clash", at, 2.4, c2, Enum.Material.Neon, f, 0.1)
	particles(spark, SPARK, Color3.new(1, 1, 1), c2, 0.8, 16, 6, 0.6)
	light(spark, c2, 22, 2)
end
EMBLEM.basic = function(at, c1, c2, f)
	-- 삼재: 하늘 · 사람 · 땅의 세 원판이 위아래로 겹쳐 돈다
	for k = 0, 2 do
		spin(disc("ThreePowers", at + Vector3.new(0, (k - 1) * 2.2, 0), 3.4 - math.abs(k - 1) * 0.8, 0.5, k == 1 and c2 or c1, Enum.Material.Neon, f, 0.2), (k - 1) * 0.4 + 0.1)
	end
	local core = ball("PowersCore", at, 1.6, Color3.fromRGB(255, 245, 220), Enum.Material.Neon, f)
	light(core, c1, 20, 1.6)
end
local function emblemFallback(at: Vector3, c1: Color3, c2: Color3, f: Instance)
	local core = ball("Orb", at, 5, c1, Enum.Material.Neon, f, 0.1)
	spin(disc("OrbRing", at, 5.6, 0.3, c2, Enum.Material.Neon, f, 0.4), 0.3).CFrame = CFrame.new(at) * CFrame.Angles(0.5, 0, math.rad(90))
	particles(core, SPARK, Color3.new(1, 1, 1), c2, 0.7, 10, 3, 1.2)
	light(core, c1, 22, 2)
end

-- 마네킹: 권법 빛깔의 R15 몸 (서버가 짓고, 몸동작 · 장신구는 저마다의 화면이)
local RIG: { { any } } = {
	{ "LowerTorso", Vector3.new(2, 0.4, 1), Vector3.new(0, -0.8, 0), "HumanoidRootPart", "Root", Vector3.new(0, -0.8, 0) },
	{ "UpperTorso", Vector3.new(2, 1.6, 1), Vector3.new(0, 0.2, 0), "LowerTorso", "Waist", Vector3.new(0, -0.6, 0) },
	{ "Head", Vector3.new(1.1, 1.1, 1.1), Vector3.new(0, 1.55, 0), "UpperTorso", "Neck", Vector3.new(0, 1.0, 0) },
	{ "RightUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(1.5, 0.4, 0), "UpperTorso", "RightShoulder", Vector3.new(1.5, 0.8, 0) },
	{ "RightLowerArm", Vector3.new(1, 0.95, 1), Vector3.new(1.5, -0.675, 0), "RightUpperArm", "RightElbow", Vector3.new(1.5, -0.2, 0) },
	{ "RightHand", Vector3.new(1, 0.3, 1), Vector3.new(1.5, -1.3, 0), "RightLowerArm", "RightWrist", Vector3.new(1.5, -1.15, 0) },
	{ "LeftUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(-1.5, 0.4, 0), "UpperTorso", "LeftShoulder", Vector3.new(-1.5, 0.8, 0) },
	{ "LeftLowerArm", Vector3.new(1, 0.95, 1), Vector3.new(-1.5, -0.675, 0), "LeftUpperArm", "LeftElbow", Vector3.new(-1.5, -0.2, 0) },
	{ "LeftHand", Vector3.new(1, 0.3, 1), Vector3.new(-1.5, -1.3, 0), "LeftLowerArm", "LeftWrist", Vector3.new(-1.5, -1.15, 0) },
	{ "RightUpperLeg", Vector3.new(1, 1.1, 1), Vector3.new(0.5, -1.55, 0), "LowerTorso", "RightHip", Vector3.new(0.5, -1.0, 0) },
	{ "RightLowerLeg", Vector3.new(1, 0.7, 1), Vector3.new(0.5, -2.45, 0), "RightUpperLeg", "RightKnee", Vector3.new(0.5, -2.1, 0) },
	{ "RightFoot", Vector3.new(1, 0.2, 1.1), Vector3.new(0.5, -2.9, -0.05), "RightLowerLeg", "RightAnkle", Vector3.new(0.5, -2.8, 0) },
	{ "LeftUpperLeg", Vector3.new(1, 1.1, 1), Vector3.new(-0.5, -1.55, 0), "LowerTorso", "LeftHip", Vector3.new(-0.5, -1.0, 0) },
	{ "LeftLowerLeg", Vector3.new(1, 0.7, 1), Vector3.new(-0.5, -2.45, 0), "LeftUpperLeg", "LeftKnee", Vector3.new(-0.5, -2.1, 0) },
	{ "LeftFoot", Vector3.new(1, 0.2, 1.1), Vector3.new(-0.5, -2.9, -0.05), "LeftLowerLeg", "LeftAnkle", Vector3.new(-0.5, -2.8, 0) },
}
local function mannequin(st: any, cf: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Doll"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1) * S
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root
	local c1, c2 = st.color, st.color2 or st.color
	local dark = c1:Lerp(Color3.new(0, 0, 0), 0.35)
	local parts: { [string]: BasePart } = { HumanoidRootPart = root }
	for _, r in ipairs(RIG) do
		local name, size, cen, parentName, jointName, joint = r[1], r[2] * S, r[3] * S, r[4], r[5], r[6] * S
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = CFrame.new(cen)
		p.Anchored = false
		p.CanCollide = false
		p.CanTouch = false
		p.Massless = true
		p.Material = Enum.Material.SmoothPlastic
		if name == "Head" then
			p.Color = c2
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Parent = p
		elseif string.find(name, "Torso") then
			p.Color = c1
		elseif string.find(name, "Hand") or string.find(name, "Foot") then
			p.Color = c2
		else
			p.Color = dark
		end
		p.Parent = model
		parts[name] = p
		local par = parts[parentName]
		local m = Instance.new("Motor6D")
		m.Name = jointName
		m.Part0 = par
		m.Part1 = p
		m.C0 = CFrame.new(joint - par.CFrame.Position)
		m.C1 = CFrame.new(joint - cen)
		m.Parent = p
	end
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = 2 * S
	hum.AutomaticScalingEnabled = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model
	model:SetAttribute("Style", st.id)
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

local function signpost(at: Vector3, st: any, parent: Instance)
	part({ Name = "SignPost", Size = Vector3.new(0.7, 6.4, 0.7), Position = at + Vector3.new(0, 3.2, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = parent })
	local board = part({ Name = "SignBoard", Size = Vector3.new(6.4, 3.4, 0.4), Position = at + Vector3.new(0, 6.2, 0), Color = Color3.fromRGB(150, 104, 66), Material = Enum.Material.Wood, Parent = parent })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front -- 북쪽 (대기실 문) 을 본다
	sg.PixelsPerStud = 60
	sg.LightInfluence = 0.2
	sg.Parent = board
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, -16, 0.6, 0)
	t.Position = UDim2.new(0, 8, 0, 6)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 246, 228)
	t.TextStrokeTransparency = 0.4
	t.Text = st.name
	t.Parent = sg
	local g = Instance.new("TextLabel")
	g.Name = "Grade"
	g.BackgroundTransparency = 1
	g.Size = UDim2.new(1, -16, 0.3, 0)
	g.Position = UDim2.new(0, 8, 0.64, 0)
	g.Font = Enum.Font.GothamBold
	g.TextScaled = true
	local grade = Config.styleGrade(st, 0)
	g.TextColor3 = Config.GRADE_COLOR[grade] or Color3.fromRGB(255, 220, 120)
	g.TextStrokeTransparency = 0.5
	g.Text = grade
	g.Parent = sg
end

-- c = 전시장 북쪽 가운데 (대기실 남쪽 문 앞) 바닥. 북쪽 (-Z) 을 본다
function StyleHall.build(c: Vector3, parent: Instance): { any }
	local f = Instance.new("Folder")
	f.Name = "StyleHall"
	f.Parent = parent
	local list = {}
	for _, st in ipairs(Config.Styles) do
		table.insert(list, st) -- 모든 권법 (숨은 것 · 게임패스 것까지)
	end
	-- 등급 낮은 것부터 (같은 등급은 처음 실린 차례)
	local order = {}
	for i, st in ipairs(list) do
		order[st] = i
	end
	table.sort(list, function(a, b)
		local ra = table.find(Config.GRADE_ORDER, Config.styleGrade(a, 0)) or 0
		local rb = table.find(Config.GRADE_ORDER, Config.styleGrade(b, 0)) or 0
		if ra ~= rb then
			return ra < rb -- 3.67판: 약한 등급부터 (문 가까운 첫 줄이 가장 약하다)
		end
		return order[a] < order[b]
	end)
	local rows = math.ceil(#list / PER_ROW)
	local W = PER_ROW * DX + MARGIN * 2
	local Dp = rows * DZ + MARGIN * 2
	-- 바닥: 어두운 돌 마당과 빛나는 테
	part({ Name = "HallFloor", Size = Vector3.new(W, 0.6, Dp), Position = c + Vector3.new(0, 0.3, Dp / 2), Color = Color3.fromRGB(56, 58, 66), Material = Enum.Material.Slate, CanCollide = true, Parent = f })
	part({ Name = "HallEdge", Size = Vector3.new(W + 1, 0.5, 0.8), Position = c + Vector3.new(0, 0.5, 0), Color = Color3.fromRGB(255, 92, 70), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	part({ Name = "HallEdge", Size = Vector3.new(W + 1, 0.5, 0.8), Position = c + Vector3.new(0, 0.5, Dp), Color = Color3.fromRGB(255, 92, 70), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
	local units = {}
	for i, st in ipairs(list) do
		local row = (i - 1) // PER_ROW
		local col = (i - 1) % PER_ROW
		local n = math.min(PER_ROW, #list - row * PER_ROW)
		local x = (col - (n - 1) / 2) * DX
		local z0 = MARGIN + 14 + row * DZ
		local at = c + Vector3.new(x, 0.6, z0)
		local u = Instance.new("Model")
		u.Name = "Unit"
		u:SetAttribute("Style", st.id)
		u.Parent = f
		local c1, c2 = st.color, st.color2 or st.color
		-- 받침대
		disc("Base", at + Vector3.new(0, 0.4, 0), 4.4, 0.8, INK, Enum.Material.SmoothPlastic, u, 0, true)
		disc("Rim", at + Vector3.new(0, 0.82, 0), 4.7, 0.2, c1, Enum.Material.Neon, u, 0.25)
		-- 상징물
		local fn = EMBLEM[st.fx or ""] or emblemFallback
		local ef = Instance.new("Folder")
		ef.Name = "Emblem"
		ef.Parent = u
		pcall(fn, at + Vector3.new(0, 17, 0), c1, c2, ef)
		-- 푯말 (앞 왼쪽)
		signpost(at + Vector3.new(-4.6, 0, -6.4), st, u)
		-- 발판 (앞)
		local padAt = at + Vector3.new(0, 0, -12)
		part({ Name = "PadEdge", Size = Vector3.new(8.8, 0.3, 8.8), Position = padAt + Vector3.new(0, 0.15, 0), Color = Color3.fromRGB(30, 32, 40), Material = Enum.Material.SmoothPlastic, CanCollide = true, Parent = u })
		local pad = part({ Name = "Pad", Size = Vector3.new(8, 0.32, 8), Position = padAt + Vector3.new(0, 0.2, 0), Color = c1, Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false, Parent = u })
		local sg = Instance.new("SurfaceGui")
		sg.Name = "PadText"
		sg.Face = Enum.NormalId.Top
		sg.PixelsPerStud = 40
		sg.LightInfluence = 0
		sg.Parent = pad
		local t = Instance.new("TextLabel")
		t.Name = "Label"
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Rotation = 180
		t.Font = Enum.Font.GothamBlack
		t.TextScaled = true
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Text = "밟으면 입장"
		t.Parent = sg
		-- 마네킹 (받침대 위, 북쪽을 본다)
		local hip = 3 * S
		pcall(mannequin, st, CFrame.lookAt(at + Vector3.new(0, 0.8 + hip, 0), at + Vector3.new(0, 0.8 + hip, -10)), u)
		table.insert(units, { id = st.id, pad = pad, padAt = padAt })
	end
	return units
end

-- 전시장의 크기 (대기실이 둘레 울타리를 넓힐 때)
function StyleHall.depth(): number
	local n = #Config.Styles
	return math.ceil(n / PER_ROW) * DZ + MARGIN * 2
end
function StyleHall.width(): number
	return PER_ROW * DX + MARGIN * 2
end

return StyleHall
