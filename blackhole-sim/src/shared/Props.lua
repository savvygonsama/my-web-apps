-- Props (ModuleScript, ReplicatedStorage)
-- 블랙홀이 삼키는 물체 31종의 모양. 모두 파트를 이어 붙여 코드로 만든다.
-- 각 모양은 반지름 s(= 삼키는 데 필요한 크기)에 맞춰 커진다. 바닥 가운데가 기준점이다.

local Props = {}

type MakeFn = (string, Enum.PartType?, Vector3, CFrame, Color3, Enum.Material) -> Part
type Builder = (MakeFn, number, () -> number) -> ()

local function hsv(h: number, s: number, v: number): Color3
	return Color3.fromHSV(h % 1, s, v)
end

local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder
local BLOCK = Enum.PartType.Block
local WEDGE: Enum.PartType? = nil -- 쐐기는 WedgePart가 따로라 쓰지 않는다

local M = Enum.Material
local C = Color3.fromRGB

-- 세운 원기둥 (원기둥은 X축이 길이라 Z축으로 90도 돌린다)
local UP = CFrame.Angles(0, 0, math.rad(90))

local builders: { [string]: Builder } = {}

------------------------------------------------------------------------
-- 1 공원
------------------------------------------------------------------------
builders.pebble = function(P, s, r)
	P("Stone", BALL, Vector3.new(1.6, 1.0, 1.3) * s, CFrame.new(0, 0.45 * s, 0) * CFrame.Angles(0, r() * 6, 0), C(130, 128, 125):Lerp(C(160, 150, 130), r()), M.Slate)
	P("Stone2", BALL, Vector3.new(0.8, 0.6, 0.7) * s, CFrame.new(0.6 * s, 0.25 * s, 0.3 * s), C(115, 112, 110), M.Slate)
end

builders.flower = function(P, s, r)
	local petal = hsv(r(), 0.6, 1)
	P("Stem", CYL, Vector3.new(1.4 * s, 0.12 * s, 0.12 * s), CFrame.new(0, 0.7 * s, 0) * UP, C(70, 160, 60), M.Grass)
	P("Leaf", BLOCK, Vector3.new(0.5, 0.06, 0.25) * s, CFrame.new(0.2 * s, 0.5 * s, 0) * CFrame.Angles(0, 0, math.rad(25)), C(80, 180, 70), M.Grass)
	P("Core", BALL, Vector3.new(0.35, 0.35, 0.35) * s, CFrame.new(0, 1.45 * s, 0), C(255, 220, 60), M.SmoothPlastic)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		P("Petal", BALL, Vector3.new(0.45, 0.15, 0.3) * s, CFrame.new(math.cos(a) * 0.3 * s, 1.45 * s, math.sin(a) * 0.3 * s) * CFrame.Angles(0, -a, 0), petal, M.SmoothPlastic)
	end
end

builders.ball = function(P, s, _r)
	P("Ball", BALL, Vector3.new(2, 2, 2) * s, CFrame.new(0, 1 * s, 0), C(245, 245, 245), M.SmoothPlastic)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		P("Patch", BALL, Vector3.new(0.6, 0.6, 0.6) * s, CFrame.new(math.cos(a) * 0.75 * s, 1 * s + math.sin(a * 2) * 0.3 * s, math.sin(a) * 0.75 * s), C(30, 30, 30), M.SmoothPlastic)
	end
end

builders.trashcan = function(P, s, r)
	local col = (r() < 0.5) and C(60, 140, 80) or C(70, 90, 160)
	P("Can", CYL, Vector3.new(2.4 * s, 1.6 * s, 1.6 * s), CFrame.new(0, 1.2 * s, 0) * UP, col, M.Metal)
	P("Lid", CYL, Vector3.new(0.2 * s, 1.8 * s, 1.8 * s), CFrame.new(0, 2.5 * s, 0) * UP, col:Lerp(C(0, 0, 0), 0.3), M.Metal)
	P("Handle", BLOCK, Vector3.new(0.6, 0.15, 0.15) * s, CFrame.new(0, 2.7 * s, 0), C(40, 40, 40), M.Metal)
end

builders.bench = function(P, s, _r)
	local wood = C(150, 100, 60)
	P("Seat", BLOCK, Vector3.new(4.4, 0.25, 1.2) * s, CFrame.new(0, 1.0 * s, 0), wood, M.Wood)
	P("Back", BLOCK, Vector3.new(4.4, 1.0, 0.2) * s, CFrame.new(0, 1.7 * s, 0.6 * s) * CFrame.Angles(math.rad(-10), 0, 0), wood, M.Wood)
	for _, x in ipairs({ -1.8, 1.8 }) do
		P("Leg", BLOCK, Vector3.new(0.2, 1.0, 1.2) * s, CFrame.new(x * s, 0.5 * s, 0), C(50, 50, 55), M.Metal)
	end
end

builders.bush = function(P, s, r)
	local g = C(60, 140, 55):Lerp(C(90, 170, 60), r())
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		P("Leaves", BALL, Vector3.new(1.6, 1.4, 1.6) * s, CFrame.new(math.cos(a) * 0.9 * s, 0.8 * s, math.sin(a) * 0.9 * s), g, M.Grass)
	end
	P("Top", BALL, Vector3.new(1.8, 1.6, 1.8) * s, CFrame.new(0, 1.4 * s, 0), g:Lerp(C(255, 255, 255), 0.1), M.Grass)
	if r() < 0.5 then
		for i = 0, 2 do
			local a = i * 2.1
			P("Berry", BALL, Vector3.new(0.3, 0.3, 0.3) * s, CFrame.new(math.cos(a) * 1.3 * s, 1.5 * s, math.sin(a) * 1.3 * s), C(220, 40, 60), M.SmoothPlastic)
		end
	end
end

builders.tree = function(P, s, r)
	P("Trunk", CYL, Vector3.new(2.4 * s, 0.6 * s, 0.6 * s), CFrame.new(0, 1.2 * s, 0) * UP, C(110, 75, 45), M.Wood)
	local g = C(60, 150, 60):Lerp(C(120, 180, 60), r())
	P("Crown", BALL, Vector3.new(2.4, 2.2, 2.4) * s, CFrame.new(0, 3.0 * s, 0), g, M.Grass)
	P("Crown2", BALL, Vector3.new(1.6, 1.5, 1.6) * s, CFrame.new(0.5 * s, 3.8 * s, 0.2 * s), g:Lerp(C(255, 255, 255), 0.1), M.Grass)
end

------------------------------------------------------------------------
-- 2 마을
------------------------------------------------------------------------
builders.mailbox = function(P, s, _r)
	P("Post", BLOCK, Vector3.new(0.3, 2, 0.3) * s, CFrame.new(0, 1 * s, 0), C(90, 70, 50), M.Wood)
	P("Box", BLOCK, Vector3.new(0.9, 0.8, 1.6) * s, CFrame.new(0, 2.3 * s, 0), C(200, 40, 40), M.Metal)
	P("Top", CYL, Vector3.new(1.6 * s, 0.9 * s, 0.9 * s), CFrame.new(0, 2.7 * s, 0) * CFrame.Angles(0, math.rad(90), 0), C(200, 40, 40), M.Metal)
	P("Flag", BLOCK, Vector3.new(0.08, 0.6, 0.25) * s, CFrame.new(0.5 * s, 2.7 * s, 0.4 * s), C(255, 220, 40), M.SmoothPlastic)
end

builders.bicycle = function(P, s, r)
	local col = hsv(r(), 0.7, 0.9)
	for _, z in ipairs({ -0.9, 0.9 }) do
		P("Wheel", CYL, Vector3.new(0.15 * s, 1.4 * s, 1.4 * s), CFrame.new(0, 0.7 * s, z * s), C(30, 30, 30), M.Rubber)
	end
	P("Frame", BLOCK, Vector3.new(0.12, 0.12, 1.8) * s, CFrame.new(0, 1.2 * s, 0), col, M.Metal)
	P("Down", BLOCK, Vector3.new(0.12, 0.9, 0.12) * s, CFrame.new(0, 0.9 * s, -0.2 * s) * CFrame.Angles(math.rad(30), 0, 0), col, M.Metal)
	P("Seat", BLOCK, Vector3.new(0.3, 0.12, 0.5) * s, CFrame.new(0, 1.55 * s, 0.4 * s), C(30, 30, 30), M.Fabric)
	P("Bar", BLOCK, Vector3.new(0.9, 0.1, 0.1) * s, CFrame.new(0, 1.6 * s, -0.8 * s), C(60, 60, 60), M.Metal)
end

builders.lamp = function(P, s, _r)
	P("Pole", CYL, Vector3.new(4.4 * s, 0.25 * s, 0.25 * s), CFrame.new(0, 2.2 * s, 0) * UP, C(50, 52, 60), M.Metal)
	P("Arm", BLOCK, Vector3.new(0.15, 0.15, 1.0) * s, CFrame.new(0, 4.4 * s, -0.4 * s), C(50, 52, 60), M.Metal)
	local bulb = P("Bulb", BALL, Vector3.new(0.6, 0.6, 0.6) * s, CFrame.new(0, 4.2 * s, -0.9 * s), C(255, 240, 180), M.Neon)
	local light = Instance.new("PointLight")
	light.Range = 4 * s
	light.Brightness = 1
	light.Color = C(255, 230, 170)
	light.Parent = bulb
	P("Base", CYL, Vector3.new(0.4 * s, 0.8 * s, 0.8 * s), CFrame.new(0, 0.2 * s, 0) * UP, C(40, 40, 45), M.Metal)
end

builders.car = function(P, s, r)
	local col = hsv(r(), 0.75, 0.95)
	P("Body", BLOCK, Vector3.new(1.7, 0.7, 3.6) * s, CFrame.new(0, 0.75 * s, 0), col, M.SmoothPlastic)
	P("Cabin", BLOCK, Vector3.new(1.5, 0.6, 1.8) * s, CFrame.new(0, 1.35 * s, 0.2 * s), col:Lerp(C(255, 255, 255), 0.15), M.SmoothPlastic)
	P("Glass", BLOCK, Vector3.new(1.52, 0.45, 1.6) * s, CFrame.new(0, 1.38 * s, 0.2 * s), C(120, 180, 220), M.Glass).Transparency = 0.3
	for _, x in ipairs({ -0.85, 0.85 }) do
		for _, z in ipairs({ -1.1, 1.1 }) do
			P("Wheel", CYL, Vector3.new(0.3 * s, 0.75 * s, 0.75 * s), CFrame.new(x * s, 0.38 * s, z * s), C(25, 25, 25), M.Rubber)
		end
	end
	for _, x in ipairs({ -0.55, 0.55 }) do
		P("Lamp", BLOCK, Vector3.new(0.35, 0.18, 0.05) * s, CFrame.new(x * s, 0.85 * s, -1.81 * s), C(255, 250, 200), M.Neon)
	end
end

builders.bigtree = function(P, s, r)
	P("Trunk", CYL, Vector3.new(2.6 * s, 0.7 * s, 0.7 * s), CFrame.new(0, 1.3 * s, 0) * UP, C(100, 70, 40), M.Wood)
	local pine = r() < 0.5
	if pine then
		for i = 0, 2 do
			P("Cone", BLOCK, Vector3.new(2.4 - i * 0.6, 1.0, 2.4 - i * 0.6) * s, CFrame.new(0, (2.6 + i * 0.9) * s, 0) * CFrame.Angles(0, math.rad(45 * i), 0), C(40, 110, 60), M.Grass)
		end
	else
		local g = C(70, 150, 60):Lerp(C(200, 160, 60), r() * 0.4)
		P("Crown", BALL, Vector3.new(2.6, 2.3, 2.6) * s, CFrame.new(0, 3.3 * s, 0), g, M.Grass)
		P("Crown2", BALL, Vector3.new(1.8, 1.6, 1.8) * s, CFrame.new(-0.6 * s, 3.9 * s, 0.4 * s), g:Lerp(C(255, 255, 255), 0.08), M.Grass)
	end
end

builders.hut = function(P, s, r)
	local wall = C(190, 150, 100):Lerp(C(220, 200, 160), r())
	P("Walls", BLOCK, Vector3.new(2.6, 1.6, 2.2) * s, CFrame.new(0, 0.8 * s, 0), wall, M.WoodPlanks)
	P("RoofL", BLOCK, Vector3.new(1.6, 0.15, 2.5) * s, CFrame.new(-0.62 * s, 1.95 * s, 0) * CFrame.Angles(0, 0, math.rad(35)), C(150, 60, 50), M.Slate)
	P("RoofR", BLOCK, Vector3.new(1.6, 0.15, 2.5) * s, CFrame.new(0.62 * s, 1.95 * s, 0) * CFrame.Angles(0, 0, math.rad(-35)), C(150, 60, 50), M.Slate)
	P("Door", BLOCK, Vector3.new(0.5, 0.9, 0.05) * s, CFrame.new(0, 0.45 * s, -1.11 * s), C(110, 70, 40), M.Wood)
	P("Window", BLOCK, Vector3.new(0.45, 0.4, 0.05) * s, CFrame.new(0.8 * s, 0.95 * s, -1.11 * s), C(255, 230, 150), M.Neon)
	P("Chimney", BLOCK, Vector3.new(0.3, 0.6, 0.3) * s, CFrame.new(0.7 * s, 2.3 * s, 0.5 * s), C(120, 110, 105), M.Brick)
end

------------------------------------------------------------------------
-- 3 도시
------------------------------------------------------------------------
builders.truck = function(P, s, r)
	local col = hsv(r(), 0.6, 0.85)
	P("Cab", BLOCK, Vector3.new(1.6, 1.4, 1.2) * s, CFrame.new(0, 1.1 * s, -1.3 * s), col, M.SmoothPlastic)
	P("Glass", BLOCK, Vector3.new(1.4, 0.5, 0.05) * s, CFrame.new(0, 1.45 * s, -1.91 * s), C(120, 180, 220), M.Glass)
	P("Cargo", BLOCK, Vector3.new(1.8, 1.8, 2.6) * s, CFrame.new(0, 1.3 * s, 0.6 * s), C(230, 230, 230), M.Metal)
	for _, x in ipairs({ -0.8, 0.8 }) do
		for _, z in ipairs({ -1.3, 0.3, 1.3 }) do
			P("Wheel", CYL, Vector3.new(0.3 * s, 0.7 * s, 0.7 * s), CFrame.new(x * s, 0.35 * s, z * s), C(25, 25, 25), M.Rubber)
		end
	end
end

builders.bus = function(P, s, r)
	local col = (r() < 0.5) and C(240, 190, 40) or C(70, 150, 220)
	P("Body", BLOCK, Vector3.new(1.8, 1.6, 4.0) * s, CFrame.new(0, 1.2 * s, 0), col, M.SmoothPlastic)
	for i = -3, 3 do
		for _, x in ipairs({ -0.91, 0.91 }) do
			P("Window", BLOCK, Vector3.new(0.05, 0.5, 0.42) * s, CFrame.new(x * s, 1.5 * s, i * 0.5 * s), C(150, 200, 230), M.Glass)
		end
	end
	P("Front", BLOCK, Vector3.new(1.5, 0.6, 0.05) * s, CFrame.new(0, 1.5 * s, -2.01 * s), C(150, 200, 230), M.Glass)
	for _, x in ipairs({ -0.85, 0.85 }) do
		for _, z in ipairs({ -1.4, 1.4 }) do
			P("Wheel", CYL, Vector3.new(0.3 * s, 0.75 * s, 0.75 * s), CFrame.new(x * s, 0.38 * s, z * s), C(25, 25, 25), M.Rubber)
		end
	end
end

builders.house = function(P, s, r)
	local wall = hsv(r(), 0.25, 0.95)
	P("Walls", BLOCK, Vector3.new(2.6, 1.8, 2.4) * s, CFrame.new(0, 0.9 * s, 0), wall, M.Plaster)
	local roof = hsv(r(), 0.6, 0.6)
	P("RoofL", BLOCK, Vector3.new(1.7, 0.18, 2.7) * s, CFrame.new(-0.65 * s, 2.15 * s, 0) * CFrame.Angles(0, 0, math.rad(38)), roof, M.Slate)
	P("RoofR", BLOCK, Vector3.new(1.7, 0.18, 2.7) * s, CFrame.new(0.65 * s, 2.15 * s, 0) * CFrame.Angles(0, 0, math.rad(-38)), roof, M.Slate)
	P("Door", BLOCK, Vector3.new(0.5, 0.9, 0.05) * s, CFrame.new(0, 0.45 * s, -1.21 * s), C(110, 70, 40), M.Wood)
	for _, x in ipairs({ -0.8, 0.8 }) do
		P("Window", BLOCK, Vector3.new(0.5, 0.45, 0.05) * s, CFrame.new(x * s, 1.1 * s, -1.21 * s), C(170, 210, 240), M.Glass)
	end
	P("Chimney", BLOCK, Vector3.new(0.35, 0.8, 0.35) * s, CFrame.new(-0.7 * s, 2.5 * s, 0.6 * s), C(150, 80, 70), M.Brick)
end

builders.shop = function(P, s, r)
	P("Walls", BLOCK, Vector3.new(3.2, 1.8, 2.4) * s, CFrame.new(0, 0.9 * s, 0), C(235, 230, 220), M.Concrete)
	P("Glass", BLOCK, Vector3.new(2.6, 1.0, 0.05) * s, CFrame.new(0, 0.8 * s, -1.21 * s), C(150, 200, 230), M.Glass)
	local awn = hsv(r(), 0.7, 0.9)
	for i = 0, 5 do
		P("Awning", BLOCK, Vector3.new(0.53, 0.08, 0.7) * s, CFrame.new((-1.33 + i * 0.53) * s, 1.55 * s, -1.45 * s) * CFrame.Angles(math.rad(20), 0, 0), (i % 2 == 0) and awn or C(250, 250, 250), M.Fabric)
	end
	P("Sign", BLOCK, Vector3.new(2.0, 0.4, 0.1) * s, CFrame.new(0, 2.0 * s, -1.2 * s), awn, M.Neon)
	P("Roof", BLOCK, Vector3.new(3.3, 0.15, 2.5) * s, CFrame.new(0, 1.85 * s, 0), C(90, 90, 95), M.Concrete)
end

builders.fountain = function(P, s, _r)
	P("Pool", CYL, Vector3.new(0.5 * s, 3.6 * s, 3.6 * s), CFrame.new(0, 0.25 * s, 0) * UP, C(210, 205, 195), M.Marble)
	P("Water", CYL, Vector3.new(0.1 * s, 3.2 * s, 3.2 * s), CFrame.new(0, 0.5 * s, 0) * UP, C(80, 170, 230), M.Glass).Transparency = 0.2
	P("Column", CYL, Vector3.new(1.6 * s, 0.5 * s, 0.5 * s), CFrame.new(0, 1.1 * s, 0) * UP, C(220, 215, 205), M.Marble)
	P("Bowl", CYL, Vector3.new(0.25 * s, 1.6 * s, 1.6 * s), CFrame.new(0, 1.9 * s, 0) * UP, C(220, 215, 205), M.Marble)
	local spray = P("Spray", BALL, Vector3.new(0.8, 1.2, 0.8) * s, CFrame.new(0, 2.5 * s, 0), C(170, 220, 255), M.Glass)
	spray.Transparency = 0.4
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 20
	pe.Speed = NumberRange.new(4 * s, 6 * s)
	pe.Acceleration = Vector3.new(0, -20 * s, 0)
	pe.Lifetime = NumberRange.new(0.6, 0.9)
	pe.SpreadAngle = Vector2.new(25, 25)
	pe.Size = NumberSequence.new(0.2 * s)
	pe.Color = ColorSequence.new(C(200, 235, 255))
	pe.Transparency = NumberSequence.new(0.3)
	pe.Parent = spray
end

------------------------------------------------------------------------
-- 4 대도시
------------------------------------------------------------------------
builders.building = function(P, s, r)
	local h = 3 + r() * 2
	local col = C(170, 180, 195):Lerp(hsv(r(), 0.3, 0.8), 0.4)
	P("Tower", BLOCK, Vector3.new(1.8, h, 1.8) * s, CFrame.new(0, h / 2 * s, 0), col, M.Concrete)
	local floors = math.floor(h / 0.5)
	for f = 1, floors - 1 do
		P("Glass", BLOCK, Vector3.new(1.84, 0.22, 1.84) * s, CFrame.new(0, f * 0.5 * s, 0), C(120, 170, 220), M.Glass)
	end
	P("Roof", BLOCK, Vector3.new(1.2, 0.3, 1.2) * s, CFrame.new(0, (h + 0.15) * s, 0), C(90, 90, 100), M.Metal)
	P("Antenna", CYL, Vector3.new(0.8 * s, 0.06 * s, 0.06 * s), CFrame.new(0, (h + 0.7) * s, 0) * UP, C(200, 50, 50), M.Neon)
end

builders.tower = function(P, s, _r)
	P("Base", BLOCK, Vector3.new(1.6, 1.0, 1.6) * s, CFrame.new(0, 0.5 * s, 0), C(180, 175, 170), M.Concrete)
	P("Shaft", CYL, Vector3.new(5.5 * s, 0.6 * s, 0.6 * s), CFrame.new(0, 3.2 * s, 0) * UP, C(220, 220, 225), M.Concrete)
	P("Pod", BALL, Vector3.new(1.6, 1.2, 1.6) * s, CFrame.new(0, 4.6 * s, 0), C(230, 90, 80), M.Metal)
	P("Ring", CYL, Vector3.new(0.15 * s, 2.0 * s, 2.0 * s), CFrame.new(0, 4.6 * s, 0) * UP, C(140, 200, 255), M.Neon)
	P("Spire", CYL, Vector3.new(1.6 * s, 0.12 * s, 0.12 * s), CFrame.new(0, 6.2 * s, 0) * UP, C(240, 240, 240), M.Metal)
	P("Tip", BALL, Vector3.new(0.25, 0.25, 0.25) * s, CFrame.new(0, 7.0 * s, 0), C(255, 60, 60), M.Neon)
end

builders.stadium = function(P, s, _r)
	P("Field", CYL, Vector3.new(0.2 * s, 3.0 * s, 3.0 * s), CFrame.new(0, 0.1 * s, 0) * UP, C(70, 160, 70), M.Grass)
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		P("Stand", BLOCK, Vector3.new(0.8, 1.0, 1.25) * s, CFrame.new(math.cos(a) * 1.7 * s, 0.5 * s, math.sin(a) * 1.7 * s) * CFrame.Angles(0, -a, 0), (i % 2 == 0) and C(230, 230, 235) or C(200, 60, 60), M.Concrete)
	end
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + 0.4
		P("Light", BLOCK, Vector3.new(0.1, 2.2, 0.1) * s, CFrame.new(math.cos(a) * 2.0 * s, 1.1 * s, math.sin(a) * 2.0 * s), C(80, 80, 90), M.Metal)
		P("Lamp", BLOCK, Vector3.new(0.4, 0.2, 0.1) * s, CFrame.new(math.cos(a) * 2.0 * s, 2.25 * s, math.sin(a) * 2.0 * s), C(255, 250, 220), M.Neon)
	end
end

builders.ferris = function(P, s, _r)
	local center = CFrame.new(0, 2.3 * s, 0)
	for _, z in ipairs({ -0.3, 0.3 }) do
		P("Leg", BLOCK, Vector3.new(0.12, 2.6, 0.12) * s, CFrame.new(-0.6 * s, 1.1 * s, z * s) * CFrame.Angles(0, 0, math.rad(-20)), C(80, 80, 90), M.Metal)
		P("Leg", BLOCK, Vector3.new(0.12, 2.6, 0.12) * s, CFrame.new(0.6 * s, 1.1 * s, z * s) * CFrame.Angles(0, 0, math.rad(20)), C(80, 80, 90), M.Metal)
	end
	P("Rim", CYL, Vector3.new(0.12 * s, 4.0 * s, 4.0 * s), center * CFrame.Angles(0, math.rad(90), 0), C(240, 240, 250), M.Metal).Transparency = 0.6
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local pos = center * CFrame.new(math.cos(a) * 1.9 * s, math.sin(a) * 1.9 * s, 0)
		P("Spoke", BLOCK, Vector3.new(0.06, 1.9, 0.06) * s, center * CFrame.Angles(0, 0, a - math.pi / 2) * CFrame.new(0, 0.95 * s, 0), C(220, 220, 230), M.Metal)
		P("Cabin", BLOCK, Vector3.new(0.4, 0.4, 0.4) * s, pos * CFrame.new(0, -0.25 * s, 0), Color3.fromHSV(i / 10, 0.7, 1), M.SmoothPlastic)
	end
end

------------------------------------------------------------------------
-- 5 바다와 산
------------------------------------------------------------------------
builders.ship = function(P, s, r)
	P("Hull", BLOCK, Vector3.new(1.4, 0.8, 3.8) * s, CFrame.new(0, 0.4 * s, 0), C(40, 50, 80), M.Metal)
	P("Bow", BLOCK, Vector3.new(1.0, 0.8, 0.8) * s, CFrame.new(0, 0.4 * s, -2.1 * s) * CFrame.Angles(0, math.rad(45), 0), C(40, 50, 80), M.Metal)
	P("Deck", BLOCK, Vector3.new(1.3, 0.1, 3.6) * s, CFrame.new(0, 0.85 * s, 0), C(180, 140, 100), M.WoodPlanks)
	P("Cabin", BLOCK, Vector3.new(1.0, 0.8, 1.2) * s, CFrame.new(0, 1.3 * s, 0.8 * s), C(240, 240, 240), M.SmoothPlastic)
	local col = (r() < 0.5) and C(220, 60, 50) or C(240, 200, 60)
	for i = 0, 1 do
		P("Funnel", CYL, Vector3.new(0.8 * s, 0.35 * s, 0.35 * s), CFrame.new(0, 2.0 * s, (0.4 + i * 0.7) * s) * UP, col, M.Metal)
	end
end

builders.lighthouse = function(P, s, _r)
	P("Rock", BALL, Vector3.new(2.4, 1.0, 2.4) * s, CFrame.new(0, 0.3 * s, 0), C(110, 105, 100), M.Slate)
	for i = 0, 4 do
		P("Ring", CYL, Vector3.new(0.9 * s, (1.1 - i * 0.12) * s, (1.1 - i * 0.12) * s), CFrame.new(0, (1.0 + i * 0.9) * s, 0) * UP, (i % 2 == 0) and C(240, 240, 240) or C(220, 50, 50), M.SmoothPlastic)
	end
	local lamp = P("Lamp", CYL, Vector3.new(0.6 * s, 0.7 * s, 0.7 * s), CFrame.new(0, 5.6 * s, 0) * UP, C(255, 240, 160), M.Neon)
	local light = Instance.new("SpotLight")
	light.Range = 30 * s / 10
	light.Brightness = 3
	light.Face = Enum.NormalId.Front
	light.Parent = lamp
	P("Cap", BALL, Vector3.new(0.8, 0.5, 0.8) * s, CFrame.new(0, 6.0 * s, 0), C(60, 60, 70), M.Metal)
end

builders.island = function(P, s, r)
	P("Sand", CYL, Vector3.new(0.6 * s, 4.0 * s, 4.0 * s), CFrame.new(0, 0.3 * s, 0) * UP, C(235, 215, 160), M.Sand)
	P("Hill", BALL, Vector3.new(2.6, 1.2, 2.4) * s, CFrame.new(0.3 * s, 0.7 * s, 0), C(90, 160, 70), M.Grass)
	for i = 0, 2 do
		local a = i * 2.2 + r()
		local base = CFrame.new(math.cos(a) * 1.2 * s, 0.6 * s, math.sin(a) * 1.2 * s)
		P("Palm", CYL, Vector3.new(1.4 * s, 0.12 * s, 0.12 * s), base * CFrame.new(0, 0.7 * s, 0) * UP * CFrame.Angles(0, 0, math.rad(8)), C(140, 100, 60), M.Wood)
		for k = 0, 4 do
			local b = k / 5 * math.pi * 2
			P("Frond", BLOCK, Vector3.new(0.9, 0.05, 0.25) * s, base * CFrame.new(0, 1.45 * s, 0) * CFrame.Angles(0, b, math.rad(-25)) * CFrame.new(0.4 * s, 0, 0), C(60, 150, 60), M.Grass)
		end
	end
end

builders.mountain = function(P, s, r)
	P("Peak", BLOCK, Vector3.new(3.2, 3.2, 3.2) * s, CFrame.new(0, 0.6 * s, 0) * CFrame.Angles(math.rad(45), math.rad(r() * 40), math.rad(35)), C(115, 105, 100), M.Rock)
	P("Peak2", BLOCK, Vector3.new(2.2, 2.2, 2.2) * s, CFrame.new(1.1 * s, 0.4 * s, 0.6 * s) * CFrame.Angles(math.rad(40), math.rad(20), math.rad(40)), C(100, 95, 90), M.Rock)
	P("Snow", BLOCK, Vector3.new(1.1, 1.1, 1.1) * s, CFrame.new(0, 2.7 * s, 0) * CFrame.Angles(math.rad(45), 0, math.rad(35)), C(250, 250, 255), M.Snow)
	P("Grass", CYL, Vector3.new(0.2 * s, 4.0 * s, 4.0 * s), CFrame.new(0, 0.1 * s, 0) * UP, C(90, 140, 70), M.Grass)
end

------------------------------------------------------------------------
-- 6 우주
------------------------------------------------------------------------
builders.satellite = function(P, s, _r)
	local y = 1.4 * s
	P("Body", BLOCK, Vector3.new(0.9, 0.9, 1.2) * s, CFrame.new(0, y, 0), C(230, 200, 90), M.Foil)
	for _, x in ipairs({ -1, 1 }) do
		P("Panel", BLOCK, Vector3.new(1.6, 0.05, 0.8) * s, CFrame.new(x * 1.3 * s, y, 0), C(40, 60, 140), M.Glass)
		P("Arm", BLOCK, Vector3.new(0.5, 0.06, 0.06) * s, CFrame.new(x * 0.6 * s, y, 0), C(200, 200, 210), M.Metal)
	end
	P("Dish", CYL, Vector3.new(0.1 * s, 0.9 * s, 0.9 * s), CFrame.new(0, y + 0.7 * s, 0) * UP, C(240, 240, 245), M.Metal)
	P("Blink", BALL, Vector3.new(0.15, 0.15, 0.15) * s, CFrame.new(0, y - 0.5 * s, -0.6 * s), C(255, 60, 60), M.Neon)
end

builders.asteroid = function(P, s, r)
	local col = C(110, 100, 95):Lerp(C(140, 110, 90), r())
	P("Rock", BALL, Vector3.new(2.0, 1.6, 1.8) * s, CFrame.new(0, 1.0 * s, 0), col, M.Slate)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		P("Lump", BALL, Vector3.new(0.9, 0.8, 0.9) * s, CFrame.new(math.cos(a) * 0.8 * s, (1.0 + math.sin(a * 1.7) * 0.4) * s, math.sin(a) * 0.7 * s), col:Lerp(C(0, 0, 0), 0.15), M.Slate)
	end
	P("Crater", CYL, Vector3.new(0.05 * s, 0.6 * s, 0.6 * s), CFrame.new(0, 1.0 * s, -0.88 * s) * CFrame.Angles(0, math.rad(90), 0), C(70, 65, 60), M.Slate)
end

builders.moon = function(P, s, _r)
	P("Moon", BALL, Vector3.new(2, 2, 2) * s, CFrame.new(0, 1.0 * s, 0), C(215, 215, 210), M.Slate)
	for i = 0, 6 do
		local a = i * 1.7
		local dir = Vector3.new(math.cos(a), math.sin(i * 0.9) * 0.7, math.sin(a)).Unit
		local pos = Vector3.new(0, 1.0 * s, 0) + dir * 0.98 * s
		P("Crater", CYL, Vector3.new(0.05 * s, (0.3 + (i % 3) * 0.12) * s, (0.3 + (i % 3) * 0.12) * s), CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.rad(90), 0), C(170, 170, 165), M.Slate)
	end
end

builders.planet = function(P, s, r)
	local col = hsv(r(), 0.55, 0.85)
	P("Planet", BALL, Vector3.new(2, 2, 2) * s, CFrame.new(0, 1.0 * s, 0), col, M.SmoothPlastic)
	for i = 0, 2 do
		P("Band", CYL, Vector3.new(0.2 * s, 2.02 * s, 2.02 * s), CFrame.new(0, (0.6 + i * 0.4) * s, 0) * UP, col:Lerp(C(255, 255, 255), 0.25 + i * 0.1), M.SmoothPlastic).Transparency = 0.2
	end
	if r() < 0.6 then
		P("Ring", CYL, Vector3.new(0.06 * s, 3.4 * s, 3.4 * s), CFrame.new(0, 1.0 * s, 0) * CFrame.Angles(math.rad(15), 0, math.rad(90)), C(230, 210, 170), M.Glass).Transparency = 0.25
	end
end

builders.sun = function(P, s, _r)
	local core = P("Sun", BALL, Vector3.new(2, 2, 2) * s, CFrame.new(0, 1.0 * s, 0), C(255, 190, 60), M.Neon)
	P("Corona", BALL, Vector3.new(2.3, 2.3, 2.3) * s, CFrame.new(0, 1.0 * s, 0), C(255, 120, 40), M.ForceField).Transparency = 0.3
	local light = Instance.new("PointLight")
	light.Range = 60
	light.Brightness = 3
	light.Color = C(255, 200, 120)
	light.Parent = core
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 20
	pe.Lifetime = NumberRange.new(1, 2)
	pe.Speed = NumberRange.new(0.1 * s, 0.2 * s)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2 * s), NumberSequenceKeypoint.new(1, 0) })
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(C(255, 230, 120), C(255, 100, 40))
	pe.Parent = core
end

------------------------------------------------------------------------
-- 만들기
------------------------------------------------------------------------
-- 물체 하나를 만든다. base = 바닥 기준 위치와 방향, seed = 같은 자리에는 같은 색이 나오게
function Props.build(kind: string, size: number, base: CFrame, seed: number): Model
	local model = Instance.new("Model")
	model.Name = kind
	local state = (seed % 2147483646) + 1
	local function rand(): number
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
	local first: Part? = nil
	local function P(name: string, shape: Enum.PartType?, sz: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
		local p = Instance.new("Part")
		p.Name = name
		if shape and shape ~= BLOCK then
			p.Shape = shape
		end
		p.Anchored = true
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = Vector3.new(math.max(sz.X, 0.05), math.max(sz.Y, 0.05), math.max(sz.Z, 0.05))
		p.CFrame = base * cf
		p.Color = color
		p.Material = material
		p.Parent = model
		if not first then
			first = p
		end
		return p
	end
	local fn = builders[kind] or builders.pebble
	fn(P, size, rand)
	if first then
		model.PrimaryPart = first
	end
	local _ = WEDGE
	return model
end

function Props.has(kind: string): boolean
	return builders[kind] ~= nil
end

return Props
