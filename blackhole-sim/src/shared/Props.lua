-- Props (ModuleScript, ReplicatedStorage)
-- 블랙홀이 삼키는 물체 85종의 모양. 모두 파트를 이어 붙여 코드로 만든다.
-- 각 모양은 반지름 s(= 삼키는 데 필요한 크기)에 맞춰 커진다. 바닥 가운데가 기준점이다.
-- 자동차는 범퍼·사이드미러·휠캡, 집은 창틀·현관 계단·울타리, 빌딩은 층마다 창문 띠와 옥상 설비처럼
-- 작은 부품까지 붙여서 가까이서 봐도 그럴듯하게 만든다.

local Props = {}

type MakeFn = (string, Enum.PartType?, Vector3, CFrame, Color3, Enum.Material) -> Part
type Builder = (MakeFn, number, () -> number) -> ()

local function hsv(h: number, s: number, v: number): Color3
	return Color3.fromHSV(h % 1, s, v)
end

local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder
local BLOCK = Enum.PartType.Block

local M = Enum.Material
local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new

-- 세운 원기둥 (원기둥은 X축이 길이라 Z축으로 90도 돌린다)
local UP = CFrame.Angles(0, 0, math.rad(90))
-- 옆으로 누운 바퀴 (축이 X)
local AXLE = CFrame.new()

local GLASS = C(150, 200, 230)
local DARK = C(30, 30, 35)
local WHITE = C(245, 245, 245)

local builders: { [string]: Builder } = {}

-- 공통 부품: 바퀴 (타이어 + 휠캡)
local function wheel(P: MakeFn, pos: CFrame, d: number, w: number)
	P("Tire", CYL, V(w, d, d), pos * AXLE, C(25, 25, 28), M.Rubber)
	P("Hub", CYL, V(w * 1.05, d * 0.5, d * 0.5), pos * AXLE, C(200, 200, 210), M.Metal)
end

-- 공통 부품: 창문 (유리 + 창틀)
local function window(P: MakeFn, cf: CFrame, w: number, h: number, frame: Color3, lit: boolean?)
	P("Frame", BLOCK, V(w * 1.15, h * 1.15, 0.04), cf, frame, M.Wood)
	P("Glass", BLOCK, V(w, h, 0.06), cf, lit and C(255, 230, 160) or GLASS, lit and M.Neon or M.Glass)
	P("Bar", BLOCK, V(w * 0.08, h, 0.08), cf, frame, M.Wood)
end

------------------------------------------------------------------------
-- 1 공원
------------------------------------------------------------------------
builders.pebble = function(P, s, r)
	local col = C(130, 128, 125):Lerp(C(160, 150, 130), r())
	P("Stone", BALL, V(1.6, 1.0, 1.3) * s, CF(0, 0.45 * s, 0) * CFrame.Angles(0, r() * 6, 0), col, M.Slate)
	P("Stone2", BALL, V(0.8, 0.6, 0.7) * s, CF(0.6 * s, 0.25 * s, 0.3 * s), col:Lerp(C(0, 0, 0), 0.15), M.Slate)
	P("Moss", BALL, V(0.7, 0.2, 0.6) * s, CF(-0.2 * s, 0.85 * s, 0.1 * s), C(90, 140, 60), M.Grass)
end

builders.flower = function(P, s, r)
	local petal = hsv(r(), 0.6, 1)
	P("Stem", CYL, V(1.4 * s, 0.12 * s, 0.12 * s), CF(0, 0.7 * s, 0) * UP, C(70, 160, 60), M.Grass)
	for _, side in ipairs({ 1, -1 }) do
		P("Leaf", BALL, V(0.55, 0.08, 0.25) * s, CF(side * 0.22 * s, (0.45 + side * 0.1) * s, 0) * CFrame.Angles(0, 0, math.rad(side * 25)), C(80, 180, 70), M.Grass)
	end
	P("Core", BALL, V(0.35, 0.35, 0.35) * s, CF(0, 1.45 * s, 0), C(255, 210, 60), M.SmoothPlastic)
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		P("Petal", BALL, V(0.45, 0.14, 0.28) * s, CF(math.cos(a) * 0.3 * s, 1.45 * s, math.sin(a) * 0.3 * s) * CFrame.Angles(0, -a, math.rad(10)), petal, M.SmoothPlastic)
	end
end

builders.ball = function(P, s, r)
	local stripe = (r() < 0.5) and DARK or hsv(r(), 0.7, 0.9)
	P("Ball", BALL, V(2, 2, 2) * s, CF(0, 1 * s, 0), WHITE, M.SmoothPlastic)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local dir = V(math.cos(a), math.sin(a * 2) * 0.4, math.sin(a)).Unit
		local pos = V(0, s, 0) + dir * 0.97 * s
		P("Patch", CYL, V(0.06 * s, 0.6 * s, 0.6 * s), CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.rad(90), 0), stripe, M.SmoothPlastic)
	end
end

builders.trashcan = function(P, s, r)
	local col = (r() < 0.5) and C(60, 140, 80) or C(70, 90, 160)
	P("Can", CYL, V(2.4 * s, 1.6 * s, 1.6 * s), CF(0, 1.2 * s, 0) * UP, col, M.Metal)
	for _, y in ipairs({ 0.5, 1.2, 1.9 }) do
		P("Rib", CYL, V(0.1 * s, 1.68 * s, 1.68 * s), CF(0, y * s, 0) * UP, col:Lerp(C(0, 0, 0), 0.25), M.Metal)
	end
	P("Lid", CYL, V(0.2 * s, 1.8 * s, 1.8 * s), CF(0, 2.5 * s, 0) * UP, col:Lerp(C(0, 0, 0), 0.3), M.Metal)
	P("Handle", BLOCK, V(0.6, 0.15, 0.15) * s, CF(0, 2.7 * s, 0), C(40, 40, 40), M.Metal)
	P("Label", BLOCK, V(0.6, 0.5, 0.05) * s, CF(0, 1.3 * s, -0.8 * s), WHITE, M.SmoothPlastic)
end

builders.bench = function(P, s, _r)
	local wood = C(150, 100, 60)
	for i = 0, 2 do
		P("Slat", BLOCK, V(4.4, 0.12, 0.35) * s, CF(0, 1.0 * s, (-0.4 + i * 0.4) * s), wood:Lerp(C(0, 0, 0), i * 0.05), M.Wood)
	end
	for i = 0, 1 do
		P("Back", BLOCK, V(4.4, 0.3, 0.1) * s, CF(0, (1.5 + i * 0.45) * s, 0.65 * s) * CFrame.Angles(math.rad(-10), 0, 0), wood, M.Wood)
	end
	for _, x in ipairs({ -1.8, 1.8 }) do
		P("Leg", BLOCK, V(0.15, 1.0, 0.15) * s, CF(x * s, 0.5 * s, -0.45 * s), C(50, 50, 55), M.Metal)
		P("Leg", BLOCK, V(0.15, 1.9, 0.15) * s, CF(x * s, 0.95 * s, 0.5 * s), C(50, 50, 55), M.Metal)
		P("Arm", BLOCK, V(0.15, 0.12, 1.1) * s, CF(x * s, 1.4 * s, 0), C(50, 50, 55), M.Metal)
	end
end

builders.bush = function(P, s, r)
	local g = C(60, 140, 55):Lerp(C(90, 170, 60), r())
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		P("Leaves", BALL, V(1.5, 1.3, 1.5) * s, CF(math.cos(a) * 0.95 * s, (0.75 + (i % 2) * 0.15) * s, math.sin(a) * 0.95 * s), g:Lerp(C(0, 0, 0), (i % 3) * 0.06), M.Grass)
	end
	P("Top", BALL, V(1.8, 1.6, 1.8) * s, CF(0, 1.4 * s, 0), g:Lerp(C(255, 255, 255), 0.1), M.Grass)
	local berry = (r() < 0.5) and C(220, 40, 60) or C(250, 250, 255)
	for i = 0, 5 do
		local a = i * 1.1
		P("Berry", BALL, V(0.28, 0.28, 0.28) * s, CF(math.cos(a) * 1.35 * s, (1.0 + (i % 3) * 0.3) * s, math.sin(a) * 1.35 * s), berry, M.SmoothPlastic)
	end
end

builders.tree = function(P, s, r)
	P("Trunk", CYL, V(2.4 * s, 0.55 * s, 0.55 * s), CF(0, 1.2 * s, 0) * UP, C(110, 75, 45), M.Wood)
	for i = 0, 2 do
		local a = i * 2.1
		P("Root", BLOCK, V(0.25, 0.25, 0.8) * s, CF(math.cos(a) * 0.35 * s, 0.12 * s, math.sin(a) * 0.35 * s) * CFrame.Angles(0, -a, 0), C(100, 68, 40), M.Wood)
	end
	P("Branch", CYL, V(0.9 * s, 0.18 * s, 0.18 * s), CF(0.35 * s, 2.0 * s, 0) * CFrame.Angles(0, 0, math.rad(50)), C(110, 75, 45), M.Wood)
	local g = C(60, 150, 60):Lerp(C(120, 180, 60), r())
	P("Crown", BALL, V(2.4, 2.2, 2.4) * s, CF(0, 3.0 * s, 0), g, M.Grass)
	P("Crown2", BALL, V(1.6, 1.5, 1.6) * s, CF(0.6 * s, 3.7 * s, 0.2 * s), g:Lerp(C(255, 255, 255), 0.1), M.Grass)
	P("Crown3", BALL, V(1.4, 1.3, 1.4) * s, CF(-0.7 * s, 3.4 * s, -0.3 * s), g:Lerp(C(0, 0, 0), 0.08), M.Grass)
	if r() < 0.5 then
		for i = 0, 3 do
			local a = i * 1.6
			P("Apple", BALL, V(0.3, 0.3, 0.3) * s, CF(math.cos(a) * 1.15 * s, (2.6 + (i % 2) * 0.5) * s, math.sin(a) * 1.15 * s), C(220, 50, 40), M.SmoothPlastic)
		end
	end
end

------------------------------------------------------------------------
-- 2 마을
------------------------------------------------------------------------
builders.mailbox = function(P, s, _r)
	P("Post", BLOCK, V(0.3, 2, 0.3) * s, CF(0, 1 * s, 0), C(90, 70, 50), M.Wood)
	P("Base", BLOCK, V(0.6, 0.15, 0.6) * s, CF(0, 0.08 * s, 0), C(70, 55, 40), M.Wood)
	P("Box", BLOCK, V(0.9, 0.8, 1.6) * s, CF(0, 2.3 * s, 0), C(200, 40, 40), M.Metal)
	P("Top", CYL, V(1.6 * s, 0.9 * s, 0.9 * s), CF(0, 2.7 * s, 0) * CFrame.Angles(0, math.rad(90), 0), C(200, 40, 40), M.Metal)
	P("Door", BLOCK, V(0.8, 0.85, 0.05) * s, CF(0, 2.4 * s, -0.82 * s), C(180, 35, 35), M.Metal)
	P("Knob", BALL, V(0.12, 0.12, 0.12) * s, CF(0, 2.5 * s, -0.86 * s), C(230, 200, 80), M.Metal)
	P("FlagPole", BLOCK, V(0.06, 0.6, 0.06) * s, CF(0.5 * s, 2.6 * s, 0.4 * s), C(60, 60, 60), M.Metal)
	P("Flag", BLOCK, V(0.06, 0.25, 0.35) * s, CF(0.5 * s, 2.8 * s, 0.25 * s), C(255, 220, 40), M.SmoothPlastic)
end

builders.bicycle = function(P, s, r)
	local col = hsv(r(), 0.7, 0.9)
	for _, z in ipairs({ -0.9, 0.9 }) do
		P("Tire", CYL, V(0.12 * s, 1.4 * s, 1.4 * s), CF(0, 0.7 * s, z * s), C(30, 30, 30), M.Rubber)
		P("Rim", CYL, V(0.13 * s, 1.1 * s, 1.1 * s), CF(0, 0.7 * s, z * s), C(200, 200, 210), M.Metal).Transparency = 0.5
		P("Hub", CYL, V(0.16 * s, 0.2 * s, 0.2 * s), CF(0, 0.7 * s, z * s), C(120, 120, 130), M.Metal)
	end
	P("Top", BLOCK, V(0.1, 0.1, 1.5) * s, CF(0, 1.25 * s, 0) * CFrame.Angles(math.rad(-5), 0, 0), col, M.Metal)
	P("Down", BLOCK, V(0.1, 0.1, 1.2) * s, CF(0, 0.95 * s, -0.2 * s) * CFrame.Angles(math.rad(35), 0, 0), col, M.Metal)
	P("SeatTube", BLOCK, V(0.1, 0.8, 0.1) * s, CF(0, 1.05 * s, 0.4 * s) * CFrame.Angles(math.rad(-15), 0, 0), col, M.Metal)
	P("Chainstay", BLOCK, V(0.08, 0.08, 0.9) * s, CF(0, 0.72 * s, 0.45 * s), col, M.Metal)
	P("Fork", BLOCK, V(0.1, 0.8, 0.1) * s, CF(0, 1.05 * s, -0.8 * s) * CFrame.Angles(math.rad(15), 0, 0), col, M.Metal)
	P("Seat", BLOCK, V(0.3, 0.1, 0.5) * s, CF(0, 1.55 * s, 0.5 * s), DARK, M.Fabric)
	P("Bar", BLOCK, V(0.9, 0.08, 0.08) * s, CF(0, 1.55 * s, -0.9 * s), C(60, 60, 60), M.Metal)
	for _, x in ipairs({ -0.45, 0.45 }) do
		P("Grip", BLOCK, V(0.2, 0.1, 0.1) * s, CF(x * s, 1.55 * s, -0.9 * s), DARK, M.Rubber)
	end
	P("Chainring", CYL, V(0.08 * s, 0.4 * s, 0.4 * s), CF(0.08 * s, 0.72 * s, 0), C(150, 150, 160), M.Metal)
	P("Basket", BLOCK, V(0.6, 0.35, 0.4) * s, CF(0, 1.35 * s, -1.15 * s), C(190, 150, 90), M.Fabric)
end

builders.lamp = function(P, s, _r)
	P("Base", CYL, V(0.4 * s, 0.8 * s, 0.8 * s), CF(0, 0.2 * s, 0) * UP, C(40, 40, 45), M.Metal)
	P("Pole", CYL, V(4.4 * s, 0.22 * s, 0.22 * s), CF(0, 2.4 * s, 0) * UP, C(50, 52, 60), M.Metal)
	for _, y in ipairs({ 1.2, 3.6 }) do
		P("Collar", CYL, V(0.15 * s, 0.32 * s, 0.32 * s), CF(0, y * s, 0) * UP, C(70, 72, 80), M.Metal)
	end
	P("Arm", BLOCK, V(0.12, 0.12, 1.0) * s, CF(0, 4.5 * s, -0.4 * s), C(50, 52, 60), M.Metal)
	P("Shade", BLOCK, V(0.7, 0.2, 0.7) * s, CF(0, 4.45 * s, -0.9 * s), C(40, 40, 45), M.Metal)
	local bulb = P("Bulb", BALL, V(0.5, 0.5, 0.5) * s, CF(0, 4.2 * s, -0.9 * s), C(255, 240, 180), M.Neon)
	local light = Instance.new("PointLight")
	light.Range = 4 * s
	light.Brightness = 1
	light.Color = C(255, 230, 170)
	light.Parent = bulb
	P("Sign", BLOCK, V(0.05, 0.4, 0.8) * s, CF(0.12 * s, 2.8 * s, 0), C(40, 120, 70), M.SmoothPlastic)
end

builders.car = function(P, s, r)
	local col = hsv(r(), 0.75, 0.95)
	P("Body", BLOCK, V(1.7, 0.6, 3.6) * s, CF(0, 0.7 * s, 0), col, M.SmoothPlastic)
	P("Hood", BLOCK, V(1.66, 0.15, 1.0) * s, CF(0, 1.02 * s, -1.25 * s) * CFrame.Angles(math.rad(-4), 0, 0), col, M.SmoothPlastic)
	P("Cabin", BLOCK, V(1.5, 0.6, 1.7) * s, CF(0, 1.3 * s, 0.25 * s), col:Lerp(WHITE, 0.12), M.SmoothPlastic)
	P("Windshield", BLOCK, V(1.4, 0.55, 0.05) * s, CF(0, 1.3 * s, -0.62 * s) * CFrame.Angles(math.rad(-25), 0, 0), GLASS, M.Glass)
	P("RearGlass", BLOCK, V(1.4, 0.5, 0.05) * s, CF(0, 1.3 * s, 1.11 * s) * CFrame.Angles(math.rad(20), 0, 0), GLASS, M.Glass)
	for _, x in ipairs({ -0.76, 0.76 }) do
		P("SideGlass", BLOCK, V(0.05, 0.4, 1.4) * s, CF(x * s, 1.35 * s, 0.25 * s), GLASS, M.Glass)
		P("Mirror", BLOCK, V(0.2, 0.15, 0.1) * s, CF(x * 1.15 * s, 1.15 * s, -0.55 * s), col, M.SmoothPlastic)
		P("Handle", BLOCK, V(0.04, 0.05, 0.2) * s, CF(x * 1.13 * s, 0.9 * s, 0.1 * s), C(200, 200, 210), M.Metal)
	end
	for _, z in ipairs({ -1.82, 1.82 }) do
		P("Bumper", BLOCK, V(1.75, 0.2, 0.15) * s, CF(0, 0.45 * s, z * s), C(70, 70, 75), M.Metal)
	end
	P("Grille", BLOCK, V(0.8, 0.25, 0.05) * s, CF(0, 0.75 * s, -1.81 * s), DARK, M.Metal)
	for _, x in ipairs({ -0.85, 0.85 }) do
		for _, z in ipairs({ -1.1, 1.1 }) do
			wheel(P, CF(x * s, 0.38 * s, z * s), 0.75 * s, 0.3 * s)
		end
	end
	for _, x in ipairs({ -0.6, 0.6 }) do
		P("HeadLamp", BLOCK, V(0.35, 0.18, 0.05) * s, CF(x * s, 0.85 * s, -1.81 * s), C(255, 250, 200), M.Neon)
		P("TailLamp", BLOCK, V(0.35, 0.15, 0.05) * s, CF(x * s, 0.85 * s, 1.81 * s), C(255, 50, 50), M.Neon)
	end
	P("Plate", BLOCK, V(0.5, 0.15, 0.05) * s, CF(0, 0.55 * s, 1.86 * s), WHITE, M.SmoothPlastic)
end

builders.bigtree = function(P, s, r)
	P("Trunk", CYL, V(2.6 * s, 0.7 * s, 0.7 * s), CF(0, 1.3 * s, 0) * UP, C(100, 70, 40), M.Wood)
	for i = 0, 3 do
		local a = i * math.pi / 2 + 0.4
		P("Root", BLOCK, V(0.3, 0.3, 1.0) * s, CF(math.cos(a) * 0.45 * s, 0.15 * s, math.sin(a) * 0.45 * s) * CFrame.Angles(0, -a, math.rad(10)), C(95, 65, 38), M.Wood)
	end
	if r() < 0.5 then
		for i = 0, 3 do
			P("Cone", BLOCK, V(2.6 - i * 0.55, 0.9, 2.6 - i * 0.55) * s, CF(0, (2.4 + i * 0.8) * s, 0) * CFrame.Angles(0, math.rad(45 * i), 0), C(40, 110, 60):Lerp(C(255, 255, 255), i * 0.04), M.Grass)
		end
		P("Snow", BLOCK, V(0.6, 0.3, 0.6) * s, CF(0, 5.4 * s, 0) * CFrame.Angles(0, math.rad(45), 0), WHITE, M.Snow)
	else
		local g = C(70, 150, 60):Lerp(C(200, 160, 60), r() * 0.4)
		P("Crown", BALL, V(2.6, 2.3, 2.6) * s, CF(0, 3.3 * s, 0), g, M.Grass)
		P("Crown2", BALL, V(1.8, 1.6, 1.8) * s, CF(-0.7 * s, 3.9 * s, 0.4 * s), g:Lerp(C(255, 255, 255), 0.08), M.Grass)
		P("Crown3", BALL, V(1.7, 1.5, 1.7) * s, CF(0.8 * s, 3.8 * s, -0.3 * s), g:Lerp(C(0, 0, 0), 0.06), M.Grass)
		P("Nest", CYL, V(0.2 * s, 0.5 * s, 0.5 * s), CF(0.4 * s, 2.5 * s, 0.4 * s) * UP, C(140, 100, 60), M.Fabric)
	end
end

builders.hut = function(P, s, r)
	local wall = C(190, 150, 100):Lerp(C(220, 200, 160), r())
	P("Floor", BLOCK, V(2.9, 0.15, 2.5) * s, CF(0, 0.08 * s, 0), C(120, 90, 60), M.WoodPlanks)
	P("Walls", BLOCK, V(2.6, 1.6, 2.2) * s, CF(0, 0.95 * s, 0), wall, M.WoodPlanks)
	for _, x in ipairs({ -1.3, 1.3 }) do
		for _, z in ipairs({ -1.1, 1.1 }) do
			P("Beam", BLOCK, V(0.15, 1.7, 0.15) * s, CF(x * s, 0.95 * s, z * s), C(100, 70, 45), M.Wood)
		end
	end
	P("RoofL", BLOCK, V(1.65, 0.15, 2.6) * s, CF(-0.62 * s, 2.1 * s, 0) * CFrame.Angles(0, 0, math.rad(35)), C(150, 60, 50), M.Slate)
	P("RoofR", BLOCK, V(1.65, 0.15, 2.6) * s, CF(0.62 * s, 2.1 * s, 0) * CFrame.Angles(0, 0, math.rad(-35)), C(150, 60, 50), M.Slate)
	P("Ridge", BLOCK, V(0.2, 0.2, 2.65) * s, CF(0, 2.55 * s, 0), C(110, 45, 40), M.Slate)
	P("Door", BLOCK, V(0.5, 0.9, 0.05) * s, CF(0, 0.6 * s, -1.11 * s), C(110, 70, 40), M.Wood)
	P("Knob", BALL, V(0.08, 0.08, 0.08) * s, CF(0.15 * s, 0.6 * s, -1.15 * s), C(220, 190, 80), M.Metal)
	window(P, CF(0.8 * s, 1.05 * s, -1.12 * s), 0.4 * s, 0.35 * s, C(110, 70, 40), true)
	window(P, CF(-0.8 * s, 1.05 * s, -1.12 * s), 0.4 * s, 0.35 * s, C(110, 70, 40), false)
	P("Chimney", BLOCK, V(0.3, 0.7, 0.3) * s, CF(0.7 * s, 2.4 * s, 0.5 * s), C(120, 110, 105), M.Brick)
	P("Step", BLOCK, V(0.7, 0.12, 0.35) * s, CF(0, 0.06 * s, -1.35 * s), C(130, 130, 125), M.Slate)
	P("Woodpile", CYL, V(0.6 * s, 0.4 * s, 0.4 * s), CF(1.5 * s, 0.2 * s, 0.6 * s) * CFrame.Angles(0, math.rad(90), 0), C(140, 100, 60), M.Wood)
end

------------------------------------------------------------------------
-- 3 도시
------------------------------------------------------------------------
builders.truck = function(P, s, r)
	local col = hsv(r(), 0.6, 0.85)
	P("Chassis", BLOCK, V(1.6, 0.3, 4.0) * s, CF(0, 0.55 * s, 0), DARK, M.Metal)
	P("Cab", BLOCK, V(1.6, 1.3, 1.2) * s, CF(0, 1.3 * s, -1.4 * s), col, M.SmoothPlastic)
	P("Windshield", BLOCK, V(1.4, 0.5, 0.05) * s, CF(0, 1.65 * s, -2.01 * s), GLASS, M.Glass)
	for _, x in ipairs({ -0.81, 0.81 }) do
		P("SideGlass", BLOCK, V(0.05, 0.45, 0.6) * s, CF(x * s, 1.65 * s, -1.4 * s), GLASS, M.Glass)
		P("Mirror", BLOCK, V(0.1, 0.35, 0.1) * s, CF(x * 1.12 * s, 1.55 * s, -1.85 * s), DARK, M.Metal)
		P("Tank", CYL, V(0.6 * s, 0.35 * s, 0.35 * s), CF(x * 0.95 * s, 0.6 * s, -0.4 * s) * CFrame.Angles(0, math.rad(90), 0), C(200, 200, 210), M.Metal)
	end
	P("Grille", BLOCK, V(1.2, 0.4, 0.05) * s, CF(0, 0.9 * s, -2.01 * s), C(170, 170, 180), M.Metal)
	P("Cargo", BLOCK, V(1.8, 1.8, 2.7) * s, CF(0, 1.6 * s, 0.65 * s), C(230, 230, 230), M.Metal)
	for i = 0, 4 do
		P("Rib", BLOCK, V(1.84, 1.82, 0.06) * s, CF(0, 1.6 * s, (-0.6 + i * 0.6) * s), C(200, 200, 205), M.Metal)
	end
	P("Logo", BLOCK, V(0.05, 0.7, 1.4) * s, CF(0.92 * s, 1.7 * s, 0.6 * s), col, M.SmoothPlastic)
	for _, x in ipairs({ -0.8, 0.8 }) do
		for _, z in ipairs({ -1.4, 0.6, 1.4 }) do
			wheel(P, CF(x * s, 0.38 * s, z * s), 0.75 * s, 0.3 * s)
		end
	end
	for _, x in ipairs({ -0.55, 0.55 }) do
		P("HeadLamp", BLOCK, V(0.25, 0.18, 0.05) * s, CF(x * s, 0.95 * s, -2.02 * s), C(255, 250, 200), M.Neon)
	end
end

builders.bus = function(P, s, r)
	local col = (r() < 0.5) and C(240, 190, 40) or C(70, 150, 220)
	P("Body", BLOCK, V(1.8, 1.6, 4.2) * s, CF(0, 1.25 * s, 0), col, M.SmoothPlastic)
	P("Stripe", BLOCK, V(1.82, 0.15, 4.22) * s, CF(0, 0.85 * s, 0), WHITE, M.SmoothPlastic)
	P("Roof", BLOCK, V(1.6, 0.12, 3.8) * s, CF(0, 2.1 * s, 0), col:Lerp(WHITE, 0.3), M.SmoothPlastic)
	for i = -3, 3 do
		for _, x in ipairs({ -0.91, 0.91 }) do
			P("Window", BLOCK, V(0.05, 0.5, 0.45) * s, CF(x * s, 1.55 * s, i * 0.52 * s), GLASS, M.Glass)
		end
	end
	P("Front", BLOCK, V(1.5, 0.7, 0.05) * s, CF(0, 1.55 * s, -2.11 * s), GLASS, M.Glass)
	P("Sign", BLOCK, V(1.2, 0.2, 0.05) * s, CF(0, 2.0 * s, -2.12 * s), C(255, 160, 40), M.Neon)
	P("Door", BLOCK, V(0.05, 1.1, 0.6) * s, CF(0.91 * s, 1.05 * s, -1.4 * s), GLASS, M.Glass)
	P("Mirror", BLOCK, V(0.1, 0.3, 0.1) * s, CF(1.0 * s, 1.6 * s, -2.1 * s), DARK, M.Metal)
	for _, x in ipairs({ -0.85, 0.85 }) do
		for _, z in ipairs({ -1.4, 1.4 }) do
			wheel(P, CF(x * s, 0.38 * s, z * s), 0.75 * s, 0.3 * s)
		end
	end
	for _, x in ipairs({ -0.6, 0.6 }) do
		P("HeadLamp", BLOCK, V(0.3, 0.18, 0.05) * s, CF(x * s, 0.7 * s, -2.11 * s), C(255, 250, 200), M.Neon)
	end
end

builders.house = function(P, s, r)
	local wall = hsv(r(), 0.25, 0.95)
	local roof = hsv(r(), 0.6, 0.6)
	local trim = WHITE
	P("Base", BLOCK, V(2.8, 0.2, 2.6) * s, CF(0, 0.1 * s, 0), C(150, 145, 140), M.Concrete)
	P("Walls", BLOCK, V(2.6, 1.8, 2.4) * s, CF(0, 1.1 * s, 0), wall, M.Plaster)
	P("RoofL", BLOCK, V(1.75, 0.18, 2.75) * s, CF(-0.65 * s, 2.35 * s, 0) * CFrame.Angles(0, 0, math.rad(38)), roof, M.Slate)
	P("RoofR", BLOCK, V(1.75, 0.18, 2.75) * s, CF(0.65 * s, 2.35 * s, 0) * CFrame.Angles(0, 0, math.rad(-38)), roof, M.Slate)
	P("Gable", BLOCK, V(1.85, 1.85, 0.1) * s, CF(0, 2.0 * s, -1.15 * s) * CFrame.Angles(0, 0, math.rad(45)), wall, M.Plaster)
	P("Door", BLOCK, V(0.5, 0.95, 0.05) * s, CF(0, 0.7 * s, -1.21 * s), C(120, 70, 40), M.Wood)
	P("Knob", BALL, V(0.08, 0.08, 0.08) * s, CF(0.15 * s, 0.7 * s, -1.25 * s), C(220, 190, 80), M.Metal)
	P("Porch", BLOCK, V(0.9, 0.08, 0.5) * s, CF(0, 1.3 * s, -1.4 * s), roof, M.Slate)
	P("Step", BLOCK, V(0.8, 0.12, 0.4) * s, CF(0, 0.2 * s, -1.4 * s), C(160, 155, 150), M.Concrete)
	for _, x in ipairs({ -0.85, 0.85 }) do
		window(P, CF(x * s, 1.25 * s, -1.22 * s), 0.5 * s, 0.45 * s, trim, x > 0)
		P("Box", BLOCK, V(0.6, 0.12, 0.15) * s, CF(x * s, 0.95 * s, -1.28 * s), C(140, 90, 50), M.Wood)
		P("Flowers", BLOCK, V(0.55, 0.1, 0.12) * s, CF(x * s, 1.05 * s, -1.28 * s), hsv(r(), 0.7, 1), M.SmoothPlastic)
	end
	P("Chimney", BLOCK, V(0.35, 0.8, 0.35) * s, CF(-0.7 * s, 2.7 * s, 0.6 * s), C(150, 80, 70), M.Brick)
	for i = -3, 3 do
		P("Fence", BLOCK, V(0.08, 0.4, 0.08) * s, CF(i * 0.4 * s, 0.2 * s, 1.5 * s), WHITE, M.Wood)
	end
	P("Rail", BLOCK, V(2.6, 0.06, 0.06) * s, CF(0, 0.3 * s, 1.5 * s), WHITE, M.Wood)
end

builders.shop = function(P, s, r)
	P("Walls", BLOCK, V(3.2, 1.8, 2.4) * s, CF(0, 0.9 * s, 0), C(235, 230, 220), M.Concrete)
	P("Glass", BLOCK, V(2.6, 1.0, 0.05) * s, CF(0, 0.8 * s, -1.21 * s), GLASS, M.Glass)
	for i = 0, 2 do
		P("Mullion", BLOCK, V(0.06, 1.0, 0.08) * s, CF((-0.65 + i * 0.65) * s, 0.8 * s, -1.22 * s), C(60, 60, 65), M.Metal)
	end
	local awn = hsv(r(), 0.7, 0.9)
	for i = 0, 5 do
		P("Awning", BLOCK, V(0.53, 0.08, 0.7) * s, CF((-1.33 + i * 0.53) * s, 1.55 * s, -1.45 * s) * CFrame.Angles(math.rad(20), 0, 0), (i % 2 == 0) and awn or WHITE, M.Fabric)
	end
	P("Sign", BLOCK, V(2.0, 0.4, 0.1) * s, CF(0, 2.0 * s, -1.2 * s), awn, M.Neon)
	P("Roof", BLOCK, V(3.3, 0.15, 2.5) * s, CF(0, 1.85 * s, 0), C(90, 90, 95), M.Concrete)
	P("AC", BLOCK, V(0.6, 0.35, 0.5) * s, CF(0.9 * s, 2.1 * s, 0.4 * s), C(200, 200, 205), M.Metal)
	for _, x in ipairs({ -1.0, 1.0 }) do
		P("Plant", BALL, V(0.4, 0.5, 0.4) * s, CF(x * 1.25 * s, 0.35 * s, -1.45 * s), C(70, 150, 60), M.Grass)
		P("Pot", CYL, V(0.3 * s, 0.3 * s, 0.3 * s), CF(x * 1.25 * s, 0.15 * s, -1.45 * s) * UP, C(170, 90, 60), M.Slate)
	end
end

builders.fountain = function(P, s, _r)
	P("Pool", CYL, V(0.5 * s, 3.6 * s, 3.6 * s), CF(0, 0.25 * s, 0) * UP, C(210, 205, 195), M.Marble)
	P("Water", CYL, V(0.1 * s, 3.2 * s, 3.2 * s), CF(0, 0.5 * s, 0) * UP, C(80, 170, 230), M.Glass).Transparency = 0.2
	P("Column", CYL, V(1.6 * s, 0.5 * s, 0.5 * s), CF(0, 1.1 * s, 0) * UP, C(220, 215, 205), M.Marble)
	P("Bowl", CYL, V(0.25 * s, 1.6 * s, 1.6 * s), CF(0, 1.9 * s, 0) * UP, C(220, 215, 205), M.Marble)
	P("Bowl2", CYL, V(0.2 * s, 0.8 * s, 0.8 * s), CF(0, 2.5 * s, 0) * UP, C(220, 215, 205), M.Marble)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		P("Coin", CYL, V(0.02 * s, 0.12 * s, 0.12 * s), CF(math.cos(a) * 1.1 * s, 0.56 * s, math.sin(a) * 0.9 * s) * UP, C(230, 200, 80), M.Metal)
	end
	local spray = P("Spray", BALL, V(0.6, 1.0, 0.6) * s, CF(0, 3.0 * s, 0), C(170, 220, 255), M.Glass)
	spray.Transparency = 0.4
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 20
	pe.Speed = NumberRange.new(4 * s, 6 * s)
	pe.Acceleration = V(0, -20 * s, 0)
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
	P("Lobby", BLOCK, V(1.9, 0.5, 1.9) * s, CF(0, 0.25 * s, 0), C(60, 60, 70), M.Granite)
	P("Tower", BLOCK, V(1.8, h, 1.8) * s, CF(0, (h / 2 + 0.25) * s, 0), col, M.Concrete)
	local floors = math.floor(h / 0.5)
	for f = 1, floors - 1 do
		P("Glass", BLOCK, V(1.84, 0.22, 1.84) * s, CF(0, (f * 0.5 + 0.25) * s, 0), GLASS, M.Glass)
	end
	for _, x in ipairs({ -0.9, 0.9 }) do
		for _, z in ipairs({ -0.9, 0.9 }) do
			P("Pillar", BLOCK, V(0.12, h, 0.12) * s, CF(x * s, (h / 2 + 0.25) * s, z * s), col:Lerp(C(0, 0, 0), 0.2), M.Concrete)
		end
	end
	P("Roof", BLOCK, V(1.2, 0.3, 1.2) * s, CF(0, (h + 0.4) * s, 0), C(90, 90, 100), M.Metal)
	P("Tank", CYL, V(0.4 * s, 0.4 * s, 0.4 * s), CF(0.4 * s, (h + 0.75) * s, 0.4 * s) * UP, C(150, 150, 160), M.Metal)
	P("Helipad", CYL, V(0.05 * s, 0.9 * s, 0.9 * s), CF(-0.3 * s, (h + 0.57) * s, -0.3 * s) * UP, C(220, 220, 80), M.Neon)
	P("Antenna", CYL, V(0.9 * s, 0.05 * s, 0.05 * s), CF(0, (h + 1.0) * s, 0) * UP, C(200, 50, 50), M.Neon)
end

builders.tower = function(P, s, _r)
	P("Base", BLOCK, V(1.6, 1.0, 1.6) * s, CF(0, 0.5 * s, 0), C(180, 175, 170), M.Concrete)
	for _, x in ipairs({ -0.5, 0.5 }) do
		for _, z in ipairs({ -0.5, 0.5 }) do
			P("Leg", BLOCK, V(0.15, 2.5, 0.15) * s, CF(x * 0.6 * s, 2.0 * s, z * 0.6 * s) * CFrame.Angles(z * 0.15, 0, -x * 0.15), C(200, 200, 205), M.Metal)
		end
	end
	P("Shaft", CYL, V(5.5 * s, 0.6 * s, 0.6 * s), CF(0, 3.2 * s, 0) * UP, C(220, 220, 225), M.Concrete)
	P("Pod", BALL, V(1.6, 1.2, 1.6) * s, CF(0, 4.6 * s, 0), C(230, 90, 80), M.Metal)
	P("Deck", CYL, V(0.15 * s, 2.0 * s, 2.0 * s), CF(0, 4.6 * s, 0) * UP, C(140, 200, 255), M.Neon)
	P("Pod2", BALL, V(0.8, 0.6, 0.8) * s, CF(0, 5.6 * s, 0), C(230, 90, 80), M.Metal)
	P("Spire", CYL, V(1.6 * s, 0.12 * s, 0.12 * s), CF(0, 6.4 * s, 0) * UP, C(240, 240, 240), M.Metal)
	P("Tip", BALL, V(0.25, 0.25, 0.25) * s, CF(0, 7.2 * s, 0), C(255, 60, 60), M.Neon)
end

builders.stadium = function(P, s, _r)
	P("Field", CYL, V(0.2 * s, 3.0 * s, 3.0 * s), CF(0, 0.1 * s, 0) * UP, C(70, 160, 70), M.Grass)
	P("Line", BLOCK, V(0.04, 0.05, 2.4) * s, CF(0, 0.21 * s, 0), WHITE, M.SmoothPlastic)
	P("Circle", CYL, V(0.04 * s, 0.6 * s, 0.6 * s), CF(0, 0.21 * s, 0) * UP, WHITE, M.SmoothPlastic).Transparency = 0.3
	for _, z in ipairs({ -1.2, 1.2 }) do
		P("Goal", BLOCK, V(0.5, 0.25, 0.05) * s, CF(0, 0.33 * s, z * s), WHITE, M.Metal)
	end
	for i = 0, 19 do
		local a = i / 20 * math.pi * 2
		P("Stand", BLOCK, V(0.75, 1.0, 1.25) * s, CF(math.cos(a) * 1.75 * s, 0.5 * s, math.sin(a) * 1.75 * s) * CFrame.Angles(0, -a, math.rad(-12)), (i % 2 == 0) and C(230, 230, 235) or C(200, 60, 60), M.Concrete)
	end
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + 0.4
		P("Mast", BLOCK, V(0.1, 2.4, 0.1) * s, CF(math.cos(a) * 2.1 * s, 1.2 * s, math.sin(a) * 2.1 * s), C(80, 80, 90), M.Metal)
		P("Lamp", BLOCK, V(0.5, 0.25, 0.1) * s, CF(math.cos(a) * 2.1 * s, 2.4 * s, math.sin(a) * 2.1 * s) * CFrame.Angles(0, -a, 0), C(255, 250, 220), M.Neon)
	end
	P("Screen", BLOCK, V(1.0, 0.5, 0.06) * s, CF(0, 1.4 * s, 1.9 * s), C(60, 200, 255), M.Neon)
end

builders.ferris = function(P, s, _r)
	local center = CF(0, 2.3 * s, 0)
	for _, z in ipairs({ -0.3, 0.3 }) do
		P("Leg", BLOCK, V(0.12, 2.6, 0.12) * s, CF(-0.6 * s, 1.1 * s, z * s) * CFrame.Angles(0, 0, math.rad(-20)), C(80, 80, 90), M.Metal)
		P("Leg", BLOCK, V(0.12, 2.6, 0.12) * s, CF(0.6 * s, 1.1 * s, z * s) * CFrame.Angles(0, 0, math.rad(20)), C(80, 80, 90), M.Metal)
	end
	P("Booth", BLOCK, V(0.8, 0.5, 0.5) * s, CF(0, 0.25 * s, -0.9 * s), C(220, 60, 60), M.SmoothPlastic)
	P("Axle", CYL, V(0.8 * s, 0.25 * s, 0.25 * s), center * CFrame.Angles(0, math.rad(90), 0), C(200, 200, 210), M.Metal)
	for _, z in ipairs({ -0.2, 0.2 }) do
		P("Rim", CYL, V(0.06 * s, 4.0 * s, 4.0 * s), center * CF(0, 0, z * s) * CFrame.Angles(0, math.rad(90), 0), C(240, 240, 250), M.Metal).Transparency = 0.5
	end
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local pos = center * CF(math.cos(a) * 1.9 * s, math.sin(a) * 1.9 * s, 0)
		P("Spoke", BLOCK, V(0.05, 1.9, 0.05) * s, center * CFrame.Angles(0, 0, a - math.pi / 2) * CF(0, 0.95 * s, 0), C(220, 220, 230), M.Metal)
		P("Cabin", BLOCK, V(0.4, 0.35, 0.45) * s, pos * CF(0, -0.25 * s, 0), Color3.fromHSV(i / 12, 0.7, 1), M.SmoothPlastic)
		P("Bulb", BALL, V(0.1, 0.1, 0.1) * s, pos, C(255, 240, 180), M.Neon)
	end
end

------------------------------------------------------------------------
-- 5 바다와 산
------------------------------------------------------------------------
builders.ship = function(P, s, r)
	P("Hull", BLOCK, V(1.4, 0.8, 3.8) * s, CF(0, 0.4 * s, 0), C(40, 50, 80), M.Metal)
	P("Waterline", BLOCK, V(1.42, 0.15, 3.82) * s, CF(0, 0.12 * s, 0), C(180, 40, 40), M.Metal)
	P("Bow", BLOCK, V(1.0, 0.8, 1.0) * s, CF(0, 0.4 * s, -2.1 * s) * CFrame.Angles(0, math.rad(45), 0), C(40, 50, 80), M.Metal)
	P("Deck", BLOCK, V(1.3, 0.1, 3.6) * s, CF(0, 0.85 * s, 0), C(180, 140, 100), M.WoodPlanks)
	P("Cabin", BLOCK, V(1.0, 0.8, 1.2) * s, CF(0, 1.3 * s, 0.8 * s), WHITE, M.SmoothPlastic)
	P("Bridge", BLOCK, V(0.9, 0.4, 0.8) * s, CF(0, 1.9 * s, 0.7 * s), WHITE, M.SmoothPlastic)
	P("BridgeGlass", BLOCK, V(0.85, 0.2, 0.05) * s, CF(0, 1.95 * s, 0.29 * s), GLASS, M.Glass)
	for i = -2, 2 do
		for _, x in ipairs({ -0.51, 0.51 }) do
			P("Porthole", CYL, V(0.04 * s, 0.15 * s, 0.15 * s), CF(x * s, 1.3 * s, (0.8 + i * 0.22) * s), GLASS, M.Glass)
		end
	end
	local col = (r() < 0.5) and C(220, 60, 50) or C(240, 200, 60)
	for i = 0, 1 do
		P("Funnel", CYL, V(0.8 * s, 0.35 * s, 0.35 * s), CF(0, 2.3 * s, (0.6 + i * 0.6) * s) * UP, col, M.Metal)
		P("FunnelTop", CYL, V(0.1 * s, 0.38 * s, 0.38 * s), CF(0, 2.7 * s, (0.6 + i * 0.6) * s) * UP, DARK, M.Metal)
	end
	P("Mast", BLOCK, V(0.08, 1.2, 0.08) * s, CF(0, 1.4 * s, -1.3 * s), C(150, 150, 160), M.Metal)
	for i = 0, 2 do
		P("Crate", BLOCK, V(0.3, 0.3, 0.3) * s, CF((-0.3 + i * 0.3) * s, 1.05 * s, -0.9 * s), hsv(i * 0.3, 0.6, 0.8), M.Wood)
	end
	P("Lifeboat", BLOCK, V(0.2, 0.15, 0.5) * s, CF(0.6 * s, 1.5 * s, 1.3 * s), C(255, 140, 40), M.SmoothPlastic)
end

builders.lighthouse = function(P, s, _r)
	P("Rock", BALL, V(2.4, 1.0, 2.4) * s, CF(0, 0.3 * s, 0), C(110, 105, 100), M.Slate)
	P("Rock2", BALL, V(1.2, 0.7, 1.0) * s, CF(1.0 * s, 0.25 * s, 0.6 * s), C(95, 90, 85), M.Slate)
	P("House", BLOCK, V(0.8, 0.6, 0.6) * s, CF(0.8 * s, 0.9 * s, 0), WHITE, M.Plaster)
	P("HouseRoof", BLOCK, V(0.9, 0.12, 0.7) * s, CF(0.8 * s, 1.25 * s, 0), C(200, 50, 50), M.Slate)
	for i = 0, 4 do
		P("Ring", CYL, V(0.9 * s, (1.1 - i * 0.12) * s, (1.1 - i * 0.12) * s), CF(0, (1.0 + i * 0.9) * s, 0) * UP, (i % 2 == 0) and WHITE or C(220, 50, 50), M.SmoothPlastic)
	end
	P("Balcony", CYL, V(0.1 * s, 1.0 * s, 1.0 * s), CF(0, 5.2 * s, 0) * UP, DARK, M.Metal)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		P("Railing", BLOCK, V(0.05, 0.3, 0.05) * s, CF(math.cos(a) * 0.48 * s, 5.4 * s, math.sin(a) * 0.48 * s), DARK, M.Metal)
	end
	local lamp = P("Lamp", CYL, V(0.6 * s, 0.6 * s, 0.6 * s), CF(0, 5.6 * s, 0) * UP, C(255, 240, 160), M.Neon)
	local light = Instance.new("SpotLight")
	light.Range = 3 * s
	light.Brightness = 3
	light.Face = Enum.NormalId.Front
	light.Parent = lamp
	P("Cap", BALL, V(0.8, 0.5, 0.8) * s, CF(0, 6.0 * s, 0), C(60, 60, 70), M.Metal)
	P("Vane", BLOCK, V(0.04, 0.4, 0.04) * s, CF(0, 6.4 * s, 0), DARK, M.Metal)
end

builders.island = function(P, s, r)
	P("Sea", CYL, V(0.2 * s, 4.4 * s, 4.4 * s), CF(0, 0.1 * s, 0) * UP, C(70, 170, 210), M.Glass).Transparency = 0.2
	P("Sand", CYL, V(0.6 * s, 4.0 * s, 4.0 * s), CF(0, 0.3 * s, 0) * UP, C(235, 215, 160), M.Sand)
	P("Hill", BALL, V(2.6, 1.2, 2.4) * s, CF(0.3 * s, 0.7 * s, 0), C(90, 160, 70), M.Grass)
	P("Rock", BALL, V(0.7, 0.5, 0.6) * s, CF(-1.4 * s, 0.6 * s, 0.6 * s), C(120, 115, 110), M.Slate)
	P("Hut", BLOCK, V(0.6, 0.45, 0.6) * s, CF(-0.9 * s, 0.85 * s, -0.8 * s), C(190, 150, 100), M.WoodPlanks)
	P("HutRoof", BLOCK, V(0.75, 0.1, 0.75) * s, CF(-0.9 * s, 1.15 * s, -0.8 * s) * CFrame.Angles(0, math.rad(45), 0), C(200, 170, 90), M.Fabric)
	P("Chest", BLOCK, V(0.35, 0.25, 0.25) * s, CF(1.4 * s, 0.75 * s, -0.8 * s), C(150, 100, 50), M.Wood)
	for i = 0, 2 do
		local a = i * 2.2 + r()
		local base = CF(math.cos(a) * 1.2 * s, 0.6 * s, math.sin(a) * 1.2 * s)
		P("Palm", CYL, V(1.4 * s, 0.12 * s, 0.12 * s), base * CF(0, 0.7 * s, 0) * UP * CFrame.Angles(0, 0, math.rad(8)), C(140, 100, 60), M.Wood)
		for k = 0, 5 do
			local b = k / 6 * math.pi * 2
			P("Frond", BLOCK, V(0.9, 0.05, 0.25) * s, base * CF(0, 1.45 * s, 0) * CFrame.Angles(0, b, math.rad(-25)) * CF(0.4 * s, 0, 0), C(60, 150, 60), M.Grass)
		end
		P("Coconut", BALL, V(0.15, 0.15, 0.15) * s, base * CF(0.1 * s, 1.35 * s, 0), C(110, 80, 50), M.Wood)
	end
end

builders.mountain = function(P, s, r)
	P("Grass", CYL, V(0.2 * s, 4.0 * s, 4.0 * s), CF(0, 0.1 * s, 0) * UP, C(90, 140, 70), M.Grass)
	P("Peak", BLOCK, V(3.2, 3.2, 3.2) * s, CF(0, 0.6 * s, 0) * CFrame.Angles(math.rad(45), math.rad(r() * 40), math.rad(35)), C(115, 105, 100), M.Rock)
	P("Peak2", BLOCK, V(2.2, 2.2, 2.2) * s, CF(1.1 * s, 0.4 * s, 0.6 * s) * CFrame.Angles(math.rad(40), math.rad(20), math.rad(40)), C(100, 95, 90), M.Rock)
	P("Peak3", BLOCK, V(1.8, 1.8, 1.8) * s, CF(-1.0 * s, 0.3 * s, -0.7 * s) * CFrame.Angles(math.rad(30), math.rad(50), math.rad(45)), C(105, 98, 92), M.Rock)
	P("Snow", BLOCK, V(1.1, 1.1, 1.1) * s, CF(0, 2.7 * s, 0) * CFrame.Angles(math.rad(45), 0, math.rad(35)), C(250, 250, 255), M.Snow)
	P("Snow2", BLOCK, V(0.7, 0.7, 0.7) * s, CF(1.1 * s, 1.75 * s, 0.6 * s) * CFrame.Angles(math.rad(40), math.rad(20), math.rad(40)), C(250, 250, 255), M.Snow)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + 0.3
		P("Pine", BLOCK, V(0.3, 0.6, 0.3) * s, CF(math.cos(a) * 1.7 * s, 0.4 * s, math.sin(a) * 1.7 * s) * CFrame.Angles(0, math.rad(45), 0), C(40, 100, 50), M.Grass)
	end
	P("Cabin", BLOCK, V(0.35, 0.25, 0.3) * s, CF(1.5 * s, 0.3 * s, -1.0 * s), C(140, 90, 50), M.WoodPlanks)
end

------------------------------------------------------------------------
-- 6 우주
------------------------------------------------------------------------
builders.satellite = function(P, s, _r)
	local y = 1.4 * s
	P("Body", BLOCK, V(0.9, 0.9, 1.2) * s, CF(0, y, 0), C(230, 200, 90), M.Foil)
	P("Band", BLOCK, V(0.95, 0.15, 1.25) * s, CF(0, y, 0), C(80, 80, 90), M.Metal)
	for _, x in ipairs({ -1, 1 }) do
		P("Panel", BLOCK, V(1.6, 0.05, 0.8) * s, CF(x * 1.3 * s, y, 0), C(40, 60, 140), M.Glass)
		for k = -2, 2 do
			P("Cell", BLOCK, V(0.03, 0.06, 0.78) * s, CF((x * 1.3 + k * 0.3) * s, y, 0), C(150, 150, 170), M.Metal)
		end
		P("Arm", BLOCK, V(0.5, 0.06, 0.06) * s, CF(x * 0.6 * s, y, 0), C(200, 200, 210), M.Metal)
	end
	P("Dish", CYL, V(0.1 * s, 0.9 * s, 0.9 * s), CF(0, y + 0.7 * s, 0) * UP, C(240, 240, 245), M.Metal)
	P("Feed", BLOCK, V(0.05, 0.4, 0.05) * s, CF(0, y + 0.9 * s, 0), C(150, 150, 160), M.Metal)
	P("Thruster", CYL, V(0.25 * s, 0.25 * s, 0.25 * s), CF(0, y - 0.6 * s, 0) * UP, DARK, M.Metal)
	P("Blink", BALL, V(0.15, 0.15, 0.15) * s, CF(0, y - 0.5 * s, -0.6 * s), C(255, 60, 60), M.Neon)
end

builders.asteroid = function(P, s, r)
	local col = C(110, 100, 95):Lerp(C(140, 110, 90), r())
	P("Rock", BALL, V(2.0, 1.6, 1.8) * s, CF(0, 1.0 * s, 0), col, M.Slate)
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		P("Lump", BALL, V(0.9, 0.8, 0.9) * s, CF(math.cos(a) * 0.8 * s, (1.0 + math.sin(a * 1.7) * 0.45) * s, math.sin(a) * 0.7 * s), col:Lerp(C(0, 0, 0), 0.15), M.Slate)
	end
	for i = 0, 3 do
		local a = i * 1.5
		local dir = V(math.cos(a), math.sin(i), math.sin(a)).Unit
		local pos = V(0, s, 0) + dir * 0.9 * s
		P("Crater", CYL, V(0.05 * s, 0.4 * s, 0.4 * s), CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.rad(90), 0), C(70, 65, 60), M.Slate)
	end
	P("Ore", BLOCK, V(0.3, 0.3, 0.3) * s, CF(0.5 * s, 1.7 * s, 0.2 * s) * CFrame.Angles(0.5, 0.5, 0), C(120, 220, 255), M.Neon)
end

builders.moon = function(P, s, _r)
	P("Moon", BALL, V(2, 2, 2) * s, CF(0, 1.0 * s, 0), C(215, 215, 210), M.Slate)
	for i = 0, 9 do
		local a = i * 1.7
		local dir = V(math.cos(a), math.sin(i * 0.9) * 0.7, math.sin(a)).Unit
		local pos = V(0, 1.0 * s, 0) + dir * 0.98 * s
		local d = (0.25 + (i % 3) * 0.12) * s
		P("Crater", CYL, V(0.05 * s, d, d), CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.rad(90), 0), C(170, 170, 165), M.Slate)
	end
	P("Flag", BLOCK, V(0.02, 0.15, 0.25) * s, CF(0.1 * s, 2.1 * s, 0), C(220, 50, 50), M.Fabric)
	P("FlagPole", BLOCK, V(0.02, 0.3, 0.02) * s, CF(0, 2.05 * s, 0), C(200, 200, 200), M.Metal)
end

builders.planet = function(P, s, r)
	local col = hsv(r(), 0.55, 0.85)
	P("Planet", BALL, V(2, 2, 2) * s, CF(0, 1.0 * s, 0), col, M.SmoothPlastic)
	for i = 0, 3 do
		P("Band", CYL, V(0.15 * s, 2.02 * s, 2.02 * s), CF(0, (0.5 + i * 0.33) * s, 0) * UP, col:Lerp(WHITE, 0.2 + i * 0.08), M.SmoothPlastic).Transparency = 0.15
	end
	P("Storm", BALL, V(0.4, 0.25, 0.1) * s, CF(0.3 * s, 0.9 * s, -0.95 * s), col:Lerp(C(180, 60, 40), 0.6), M.SmoothPlastic)
	if r() < 0.6 then
		P("Ring", CYL, V(0.05 * s, 3.4 * s, 3.4 * s), CF(0, 1.0 * s, 0) * CFrame.Angles(math.rad(15), 0, math.rad(90)), C(230, 210, 170), M.Glass).Transparency = 0.25
		P("Ring2", CYL, V(0.04 * s, 3.0 * s, 3.0 * s), CF(0, 1.0 * s, 0) * CFrame.Angles(math.rad(15), 0, math.rad(90)), C(200, 170, 130), M.Glass).Transparency = 0.4
	end
	P("Moonlet", BALL, V(0.3, 0.3, 0.3) * s, CF(1.4 * s, 1.6 * s, 0.3 * s), C(200, 200, 200), M.Slate)
end

builders.sun = function(P, s, _r)
	local core = P("Sun", BALL, V(2, 2, 2) * s, CF(0, 1.0 * s, 0), C(255, 190, 60), M.Neon)
	P("Corona", BALL, V(2.3, 2.3, 2.3) * s, CF(0, 1.0 * s, 0), C(255, 120, 40), M.ForceField).Transparency = 0.3
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		P("Flare", BALL, V(0.5, 0.25, 0.25) * s, CF(math.cos(a) * 1.1 * s, (1.0 + math.sin(a * 2) * 0.4) * s, math.sin(a) * 1.1 * s), C(255, 230, 120), M.Neon)
	end
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
-- 세계 2: 과자 왕국
------------------------------------------------------------------------
local PASTEL = { C(255, 150, 190), C(150, 220, 255), C(255, 230, 130), C(180, 240, 160), C(220, 170, 255), C(255, 180, 120) }
local function pastel(r: () -> number): Color3
	return PASTEL[math.floor(r() * #PASTEL) + 1]
end

builders.gummy = function(P, s, r)
	local col = pastel(r)
	local function g(name: string, sz: Vector3, cf: CFrame)
		P(name, BALL, sz * s, cf, col, M.Glass).Transparency = 0.15
	end
	g("Body", V(1.2, 1.4, 1.0), CF(0, 0.75 * s, 0))
	g("Head", V(1.0, 0.9, 0.9), CF(0, 1.7 * s, 0))
	for _, x in ipairs({ -0.35, 0.35 }) do
		g("Ear", V(0.35, 0.35, 0.3), CF(x * s, 2.1 * s, 0))
		g("Arm", V(0.35, 0.5, 0.35), CF(x * 1.6 * s, 1.0 * s, 0))
		g("Leg", V(0.4, 0.4, 0.4), CF(x * s, 0.2 * s, 0))
	end
	P("Nose", BALL, V(0.2, 0.15, 0.15) * s, CF(0, 1.6 * s, -0.45 * s), col:Lerp(C(0, 0, 0), 0.3), M.SmoothPlastic)
end

builders.candy = function(P, s, r)
	local col = pastel(r)
	P("Candy", BALL, V(1.4, 1.0, 1.0) * s, CF(0, 0.5 * s, 0), col, M.SmoothPlastic)
	for _, x in ipairs({ -1, 1 }) do
		P("Wrap", BLOCK, V(0.5, 0.7, 0.05) * s, CF(x * 0.9 * s, 0.5 * s, 0) * CFrame.Angles(0, math.rad(90), 0), col:Lerp(WHITE, 0.4), M.Foil)
	end
	P("Stripe", BALL, V(1.42, 0.2, 1.02) * s, CF(0, 0.5 * s, 0) * CFrame.Angles(0, 0, math.rad(60)), WHITE, M.SmoothPlastic)
end

builders.lollipop = function(P, s, r)
	local col = pastel(r)
	P("Stick", CYL, V(2.0 * s, 0.12 * s, 0.12 * s), CF(0, 1.0 * s, 0) * UP, WHITE, M.SmoothPlastic)
	P("Disc", CYL, V(0.3 * s, 1.5 * s, 1.5 * s), CF(0, 2.4 * s, 0) * CFrame.Angles(0, math.rad(90), 0), col, M.SmoothPlastic)
	for i = 0, 2 do
		P("Swirl", CYL, V(0.32 * s, (1.2 - i * 0.35) * s, (1.2 - i * 0.35) * s), CF(0, 2.4 * s, 0) * CFrame.Angles(0, math.rad(90), 0), (i % 2 == 0) and WHITE or col:Lerp(C(255, 255, 255), 0.3), M.SmoothPlastic)
	end
	P("Bow", BALL, V(0.4, 0.25, 0.2) * s, CF(0, 1.55 * s, 0), C(255, 80, 120), M.Fabric)
end

builders.macaron = function(P, s, r)
	local col = pastel(r)
	P("Bottom", CYL, V(0.5 * s, 1.8 * s, 1.8 * s), CF(0, 0.25 * s, 0) * UP, col, M.SmoothPlastic)
	P("Cream", CYL, V(0.3 * s, 1.6 * s, 1.6 * s), CF(0, 0.65 * s, 0) * UP, WHITE, M.SmoothPlastic)
	P("Top", BALL, V(1.8, 0.7, 1.8) * s, CF(0, 0.95 * s, 0), col, M.SmoothPlastic)
	P("Ruffle", CYL, V(0.12 * s, 1.85 * s, 1.85 * s), CF(0, 0.52 * s, 0) * UP, col:Lerp(C(0, 0, 0), 0.1), M.Sand)
end

builders.cupcake = function(P, s, r)
	P("Cup", CYL, V(1.2 * s, 1.6 * s, 1.6 * s), CF(0, 0.6 * s, 0) * UP, C(255, 255, 255):Lerp(pastel(r), 0.5), M.Fabric)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		P("Pleat", BLOCK, V(0.06, 1.2, 0.1) * s, CF(math.cos(a) * 0.8 * s, 0.6 * s, math.sin(a) * 0.8 * s) * CFrame.Angles(0, -a, 0), C(240, 240, 240), M.Fabric)
	end
	local cream = pastel(r)
	P("Cream", BALL, V(1.9, 0.9, 1.9) * s, CF(0, 1.4 * s, 0), cream, M.SmoothPlastic)
	P("Cream2", BALL, V(1.3, 0.7, 1.3) * s, CF(0, 1.85 * s, 0), cream:Lerp(WHITE, 0.2), M.SmoothPlastic)
	P("Cherry", BALL, V(0.45, 0.45, 0.45) * s, CF(0, 2.35 * s, 0), C(220, 30, 50), M.SmoothPlastic)
	for i = 0, 7 do
		local a = i * 0.8
		P("Sprinkle", BLOCK, V(0.25, 0.06, 0.06) * s, CF(math.cos(a) * 0.6 * s, 1.75 * s, math.sin(a) * 0.6 * s) * CFrame.Angles(0, a, 0.3), PASTEL[(i % #PASTEL) + 1], M.Neon)
	end
end

builders.donut = function(P, s, r)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		P("Dough", BALL, V(1.0, 0.7, 1.0) * s, CF(math.cos(a) * 1.05 * s, 0.4 * s, math.sin(a) * 1.05 * s), C(210, 160, 100), M.SmoothPlastic)
	end
	local icing = pastel(r)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2 + 0.2
		P("Icing", BALL, V(0.95, 0.35, 0.95) * s, CF(math.cos(a) * 1.05 * s, 0.68 * s, math.sin(a) * 1.05 * s), icing, M.SmoothPlastic)
	end
	for i = 0, 9 do
		local a = i * 0.65
		P("Sprinkle", BLOCK, V(0.25, 0.06, 0.06) * s, CF(math.cos(a) * 1.05 * s, 0.86 * s, math.sin(a) * 1.05 * s) * CFrame.Angles(0, a * 2, 0), PASTEL[(i % #PASTEL) + 1], M.Neon)
	end
end

builders.cookie = function(P, s, _r)
	P("Cookie", CYL, V(0.4 * s, 2.8 * s, 2.8 * s), CF(0, 1.4 * s, 0) * CFrame.Angles(0, math.rad(90), math.rad(10)), C(210, 160, 100), M.Sand)
	for i = 0, 8 do
		local a = i * 0.9
		local rr = (0.3 + (i % 3) * 0.35) * s
		P("Chip", BALL, V(0.3, 0.3, 0.2) * s, CF(math.cos(a) * rr, 1.4 * s + math.sin(a) * rr, -0.22 * s), C(80, 50, 30), M.SmoothPlastic)
	end
	P("Stand", BLOCK, V(0.6, 0.3, 0.6) * s, CF(0, 0.15 * s, 0.2 * s), C(190, 140, 90), M.Sand)
end

builders.pudding = function(P, s, _r)
	P("Plate", CYL, V(0.15 * s, 2.6 * s, 2.6 * s), CF(0, 0.08 * s, 0) * UP, WHITE, M.SmoothPlastic)
	P("Pudding", CYL, V(1.6 * s, 1.8 * s, 1.8 * s), CF(0, 0.95 * s, 0) * UP, C(255, 220, 120), M.SmoothPlastic)
	P("Top", CYL, V(0.3 * s, 1.5 * s, 1.5 * s), CF(0, 1.85 * s, 0) * UP, C(150, 80, 30), M.SmoothPlastic)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		P("Drip", BALL, V(0.3, 0.5, 0.3) * s, CF(math.cos(a) * 0.85 * s, 1.55 * s, math.sin(a) * 0.85 * s), C(150, 80, 30), M.SmoothPlastic)
	end
	P("Cream", BALL, V(0.6, 0.4, 0.6) * s, CF(0, 2.1 * s, 0), WHITE, M.SmoothPlastic)
	P("Cherry", BALL, V(0.3, 0.3, 0.3) * s, CF(0, 2.35 * s, 0), C(220, 30, 50), M.SmoothPlastic)
end

builders.icecream = function(P, s, r)
	P("Cone", CYL, V(2.2 * s, 0.9 * s, 0.9 * s), CF(0, 1.1 * s, 0) * UP, C(220, 170, 100), M.Sand)
	for i = 0, 3 do
		P("Grid", CYL, V(0.06 * s, 0.95 * s, 0.95 * s), CF(0, (0.4 + i * 0.5) * s, 0) * UP, C(190, 140, 80), M.Sand)
	end
	for i = 0, 2 do
		P("Scoop", BALL, V(1.4, 1.2, 1.4) * s, CF(0, (2.6 + i * 0.95) * s, 0), pastel(r), M.SmoothPlastic)
	end
	P("Drip", BALL, V(0.3, 0.6, 0.3) * s, CF(0.55 * s, 2.3 * s, -0.3 * s), C(255, 200, 220), M.SmoothPlastic)
	P("Wafer", BLOCK, V(0.2, 0.9, 0.5) * s, CF(0.4 * s, 4.6 * s, 0) * CFrame.Angles(0, 0, math.rad(-20)), C(230, 190, 120), M.Sand)
	P("Cherry", BALL, V(0.35, 0.35, 0.35) * s, CF(-0.1 * s, 4.75 * s, 0), C(220, 30, 50), M.SmoothPlastic)
end

builders.cottontree = function(P, s, r)
	P("Stick", CYL, V(2.4 * s, 0.3 * s, 0.3 * s), CF(0, 1.2 * s, 0) * UP, C(250, 240, 230), M.SmoothPlastic)
	P("Stripe", CYL, V(2.4 * s, 0.32 * s, 0.32 * s), CF(0, 1.2 * s, 0) * UP, C(255, 120, 150), M.SmoothPlastic).Transparency = 0.5
	local col = pastel(r)
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		P("Floss", BALL, V(1.4, 1.3, 1.4) * s, CF(math.cos(a) * 0.9 * s, (3.1 + math.sin(a * 2) * 0.3) * s, math.sin(a) * 0.9 * s), col:Lerp(WHITE, (i % 3) * 0.15), M.Fabric)
	end
	P("Top", BALL, V(1.6, 1.4, 1.6) * s, CF(0, 3.7 * s, 0), col:Lerp(WHITE, 0.2), M.Fabric)
end

builders.gingerhouse = function(P, s, r)
	local dough = C(190, 120, 70)
	P("Walls", BLOCK, V(2.6, 1.8, 2.4) * s, CF(0, 0.9 * s, 0), dough, M.Sand)
	for _, x in ipairs({ -1.3, 1.3 }) do
		P("Icing", BLOCK, V(0.1, 1.8, 2.45) * s, CF(x * s, 0.9 * s, 0), WHITE, M.SmoothPlastic)
	end
	P("RoofL", BLOCK, V(1.75, 0.25, 2.75) * s, CF(-0.65 * s, 2.15 * s, 0) * CFrame.Angles(0, 0, math.rad(38)), C(120, 70, 40), M.Sand)
	P("RoofR", BLOCK, V(1.75, 0.25, 2.75) * s, CF(0.65 * s, 2.15 * s, 0) * CFrame.Angles(0, 0, math.rad(-38)), C(120, 70, 40), M.Sand)
	for i = -3, 3 do
		P("Snow", BALL, V(0.4, 0.25, 0.4) * s, CF(0, 2.7 * s, i * 0.37 * s), WHITE, M.SmoothPlastic)
	end
	P("Door", BLOCK, V(0.6, 1.0, 0.05) * s, CF(0, 0.5 * s, -1.21 * s), C(255, 120, 150), M.SmoothPlastic)
	for _, x in ipairs({ -0.85, 0.85 }) do
		P("Window", BLOCK, V(0.5, 0.5, 0.05) * s, CF(x * s, 1.1 * s, -1.22 * s), C(255, 240, 160), M.Neon)
		P("Gum", BALL, V(0.25, 0.25, 0.25) * s, CF(x * s, 1.55 * s, -1.25 * s), pastel(r), M.SmoothPlastic)
	end
	for i = 0, 3 do
		P("CaneL", CYL, V(1.2 * s, 0.12 * s, 0.12 * s), CF((-1.1 + i * 0.73) * s, 0.6 * s, -1.4 * s) * UP, (i % 2 == 0) and C(220, 40, 60) or WHITE, M.SmoothPlastic)
	end
end

builders.candycar = function(P, s, r)
	local col = pastel(r)
	P("Body", BLOCK, V(1.7, 0.7, 3.4) * s, CF(0, 0.75 * s, 0), col, M.SmoothPlastic)
	P("Top", BALL, V(1.5, 0.9, 1.9) * s, CF(0, 1.3 * s, 0.2 * s), WHITE, M.SmoothPlastic)
	P("Cherry", BALL, V(0.4, 0.4, 0.4) * s, CF(0, 1.85 * s, 0.2 * s), C(220, 30, 50), M.SmoothPlastic)
	for _, x in ipairs({ -0.85, 0.85 }) do
		for _, z in ipairs({ -1.1, 1.1 }) do
			P("DonutWheel", CYL, V(0.3 * s, 0.8 * s, 0.8 * s), CF(x * s, 0.4 * s, z * s), C(210, 160, 100), M.SmoothPlastic)
			P("Hole", CYL, V(0.32 * s, 0.3 * s, 0.3 * s), CF(x * s, 0.4 * s, z * s), C(255, 150, 190), M.SmoothPlastic)
		end
	end
	P("Lamp", BALL, V(0.3, 0.3, 0.2) * s, CF(0.5 * s, 0.85 * s, -1.7 * s), C(255, 240, 160), M.Neon)
	P("Lamp2", BALL, V(0.3, 0.3, 0.2) * s, CF(-0.5 * s, 0.85 * s, -1.7 * s), C(255, 240, 160), M.Neon)
end

builders.cake = function(P, s, r)
	local col = pastel(r)
	P("Plate", CYL, V(0.15 * s, 3.4 * s, 3.4 * s), CF(0, 0.08 * s, 0) * UP, WHITE, M.SmoothPlastic)
	P("Layer1", CYL, V(1.0 * s, 3.0 * s, 3.0 * s), CF(0, 0.65 * s, 0) * UP, col, M.SmoothPlastic)
	P("Cream1", CYL, V(0.15 * s, 3.05 * s, 3.05 * s), CF(0, 1.15 * s, 0) * UP, WHITE, M.SmoothPlastic)
	P("Layer2", CYL, V(0.8 * s, 2.2 * s, 2.2 * s), CF(0, 1.6 * s, 0) * UP, col:Lerp(WHITE, 0.3), M.SmoothPlastic)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		P("Strawberry", BALL, V(0.35, 0.4, 0.35) * s, CF(math.cos(a) * 0.8 * s, 2.15 * s, math.sin(a) * 0.8 * s), C(230, 40, 60), M.SmoothPlastic)
	end
	P("Candle", CYL, V(0.5 * s, 0.12 * s, 0.12 * s), CF(0, 2.3 * s, 0) * UP, C(150, 200, 255), M.SmoothPlastic)
	P("Flame", BALL, V(0.15, 0.25, 0.15) * s, CF(0, 2.65 * s, 0), C(255, 200, 80), M.Neon)
end

builders.chocofountain = function(P, s, _r)
	local choco = C(110, 60, 30)
	P("Base", CYL, V(0.4 * s, 3.2 * s, 3.2 * s), CF(0, 0.2 * s, 0) * UP, C(230, 220, 210), M.Marble)
	P("Pool", CYL, V(0.1 * s, 2.9 * s, 2.9 * s), CF(0, 0.42 * s, 0) * UP, choco, M.SmoothPlastic)
	for i = 0, 2 do
		P("Tier", CYL, V(0.2 * s, (2.0 - i * 0.6) * s, (2.0 - i * 0.6) * s), CF(0, (1.0 + i * 0.8) * s, 0) * UP, C(230, 220, 210), M.Marble)
		P("Flow", CYL, V(0.7 * s, (1.9 - i * 0.6) * s, (1.9 - i * 0.6) * s), CF(0, (0.7 + i * 0.8) * s, 0) * UP, choco, M.SmoothPlastic).Transparency = 0.2
	end
	P("Column", CYL, V(2.6 * s, 0.3 * s, 0.3 * s), CF(0, 1.5 * s, 0) * UP, C(230, 220, 210), M.Marble)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		P("Marshmallow", CYL, V(0.3 * s, 0.25 * s, 0.25 * s), CF(math.cos(a) * 1.5 * s, 0.6 * s, math.sin(a) * 1.5 * s) * UP, WHITE, M.SmoothPlastic)
	end
end

builders.weddingcake = function(P, s, _r)
	for i = 0, 4 do
		local d = (3.0 - i * 0.55) * s
		P("Tier", CYL, V(0.8 * s, d, d), CF(0, (0.4 + i * 0.85) * s, 0) * UP, WHITE, M.SmoothPlastic)
		P("Ribbon", CYL, V(0.12 * s, d * 1.01, d * 1.01), CF(0, (0.15 + i * 0.85) * s, 0) * UP, C(255, 180, 200), M.SmoothPlastic)
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2 + i
			P("Pearl", BALL, V(0.15, 0.15, 0.15) * s, CF(math.cos(a) * d * 0.5, (0.8 + i * 0.85) * s, math.sin(a) * d * 0.5), C(255, 240, 220), M.Pebble)
		end
	end
	P("Heart", BALL, V(0.5, 0.5, 0.2) * s, CF(0, 4.7 * s, 0), C(255, 80, 120), M.Neon)
end

builders.lollitower = function(P, s, r)
	P("Stick", CYL, V(5.0 * s, 0.25 * s, 0.25 * s), CF(0, 2.5 * s, 0) * UP, WHITE, M.SmoothPlastic)
	for i = 0, 5 do
		P("Stripe", CYL, V(0.3 * s, 0.27 * s, 0.27 * s), CF(0, (0.4 + i * 0.8) * s, 0) * UP, C(255, 80, 120), M.SmoothPlastic)
	end
	local col = pastel(r)
	P("Disc", CYL, V(0.4 * s, 2.4 * s, 2.4 * s), CF(0, 5.6 * s, 0) * CFrame.Angles(0, math.rad(90), 0), col, M.SmoothPlastic)
	for i = 0, 3 do
		P("Swirl", CYL, V(0.42 * s, (2.0 - i * 0.45) * s, (2.0 - i * 0.45) * s), CF(0, 5.6 * s, 0) * CFrame.Angles(0, math.rad(90), 0), (i % 2 == 0) and WHITE or col:Lerp(C(255, 255, 255), 0.4), M.SmoothPlastic)
	end
end

builders.jellycastle = function(P, s, r)
	local col = pastel(r)
	local function jelly(name: string, sz: Vector3, cf: CFrame, shape: Enum.PartType?)
		P(name, shape, sz * s, cf, col, M.Glass).Transparency = 0.2
	end
	jelly("Keep", V(2.2, 1.8, 2.2), CF(0, 0.9 * s, 0))
	for _, x in ipairs({ -1.2, 1.2 }) do
		for _, z in ipairs({ -1.2, 1.2 }) do
			P("Tower", CYL, V(2.6 * s, 0.7 * s, 0.7 * s), CF(x * s, 1.3 * s, z * s) * UP, col:Lerp(WHITE, 0.3), M.Glass).Transparency = 0.15
			P("Cap", BALL, V(0.8, 0.8, 0.8) * s, CF(x * s, 2.7 * s, z * s), C(255, 120, 180), M.SmoothPlastic)
		end
	end
	jelly("Top", V(1.2, 1.2, 1.2), CF(0, 2.3 * s, 0))
	P("Gate", BLOCK, V(0.6, 0.9, 0.05) * s, CF(0, 0.45 * s, -1.12 * s), C(120, 70, 40), M.Sand)
	P("Flag", BLOCK, V(0.05, 0.3, 0.45) * s, CF(0, 3.2 * s, 0.2 * s), C(255, 220, 60), M.Fabric)
	P("Pole", BLOCK, V(0.05, 0.6, 0.05) * s, CF(0, 3.0 * s, 0), WHITE, M.Metal)
end

builders.icemountain = function(P, s, r)
	P("Base", BALL, V(4, 2.2, 4) * s, CF(0, 0.5 * s, 0), C(210, 160, 100), M.Sand)
	for i = 0, 2 do
		P("Scoop", BALL, V(3.0 - i * 0.7, 2.0 - i * 0.4, 3.0 - i * 0.7) * s, CF(0, (1.4 + i * 1.0) * s, 0), pastel(r), M.SmoothPlastic)
	end
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		P("Drip", BALL, V(0.5, 0.9, 0.5) * s, CF(math.cos(a) * 1.3 * s, 1.2 * s, math.sin(a) * 1.3 * s), C(255, 240, 250), M.SmoothPlastic)
	end
	P("Cherry", BALL, V(0.6, 0.6, 0.6) * s, CF(0, 4.0 * s, 0), C(220, 30, 50), M.SmoothPlastic)
	P("Stem", BLOCK, V(0.06, 0.5, 0.06) * s, CF(0.1 * s, 4.45 * s, 0) * CFrame.Angles(0, 0, -0.3), C(80, 140, 60), M.Grass)
end

builders.donutplanet = function(P, s, r)
	local icing = pastel(r)
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		P("Dough", BALL, V(1.0, 0.8, 1.0) * s, CF(math.cos(a) * 1.3 * s, 1.2 * s, math.sin(a) * 1.3 * s), C(210, 160, 100), M.SmoothPlastic)
		P("Icing", BALL, V(0.95, 0.4, 0.95) * s, CF(math.cos(a) * 1.3 * s, 1.5 * s, math.sin(a) * 1.3 * s), icing, M.SmoothPlastic)
	end
	P("Moon", BALL, V(0.5, 0.5, 0.5) * s, CF(2.2 * s, 2.0 * s, 0), C(255, 240, 200), M.SmoothPlastic)
end

builders.candymoon = function(P, s, r)
	local col = pastel(r)
	P("Moon", BALL, V(2, 2, 2) * s, CF(0, 1.0 * s, 0), col, M.SmoothPlastic)
	for i = 0, 5 do
		P("Stripe", CYL, V(0.06 * s, 2.02 * s, 2.02 * s), CF(0, 1.0 * s, 0) * CFrame.Angles(i * 0.5, 0, math.rad(90)), WHITE, M.SmoothPlastic).Transparency = 0.2
	end
	for i = 0, 6 do
		local a = i * 0.9
		local dir = V(math.cos(a), math.sin(i), math.sin(a)).Unit
		P("Gem", BALL, V(0.25, 0.25, 0.25) * s, CF(V(0, s, 0) + dir * s), PASTEL[(i % #PASTEL) + 1], M.Neon)
	end
end

builders.cakestar = function(P, s, r)
	local col = pastel(r)
	P("Core", BALL, V(1.6, 1.6, 1.6) * s, CF(0, 1.0 * s, 0), col, M.SmoothPlastic)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		P("Point", BLOCK, V(0.6, 1.4, 0.6) * s, CF(0, 1.0 * s, 0) * CFrame.Angles(0, 0, a) * CF(0, 1.0 * s, 0) * CFrame.Angles(0, math.rad(45), 0), col:Lerp(WHITE, 0.3), M.SmoothPlastic)
	end
	P("Cream", BALL, V(1.0, 0.5, 1.0) * s, CF(0, 1.8 * s, 0), WHITE, M.SmoothPlastic)
	P("Glow", BALL, V(2.2, 2.2, 2.2) * s, CF(0, 1.0 * s, 0), C(255, 240, 180), M.ForceField).Transparency = 0.4
end

builders.candysun = function(P, s, _r)
	local core = P("Sun", BALL, V(2, 2, 2) * s, CF(0, 1.0 * s, 0), C(255, 150, 200), M.Neon)
	for i = 0, 5 do
		P("Swirl", CYL, V(0.08 * s, 2.05 * s, 2.05 * s), CF(0, 1.0 * s, 0) * CFrame.Angles(i * 0.52, i * 0.3, math.rad(90)), (i % 2 == 0) and WHITE or C(255, 230, 120), M.Neon).Transparency = 0.3
	end
	P("Corona", BALL, V(2.4, 2.4, 2.4) * s, CF(0, 1.0 * s, 0), C(255, 120, 200), M.ForceField).Transparency = 0.3
	local light = Instance.new("PointLight")
	light.Range = 60
	light.Brightness = 3
	light.Color = C(255, 180, 230)
	light.Parent = core
end

------------------------------------------------------------------------
-- 베타 3에서 더한 물체 26종
------------------------------------------------------------------------
-- 1 공원
builders.duck = function(P, s, r)
	local col = r() < 0.7 and C(255, 220, 60) or WHITE
	P("Body", BALL, V(1.2, 0.9, 1.6) * s, CF(0, 0.45 * s, 0), col, M.SmoothPlastic)
	P("Head", BALL, V(0.7, 0.7, 0.7) * s, CF(0, 1.05 * s, -0.55 * s), col, M.SmoothPlastic)
	P("Beak", BLOCK, V(0.35, 0.12, 0.35) * s, CF(0, 1.0 * s, -0.95 * s), C(255, 140, 30), M.SmoothPlastic)
	P("Tail", BALL, V(0.4, 0.4, 0.5) * s, CF(0, 0.75 * s, 0.75 * s), col, M.SmoothPlastic)
	for _, x in ipairs({ -0.17, 0.17 }) do
		P("Eye", BALL, V(0.12, 0.14, 0.08) * s, CF(x * s, 1.15 * s, -0.86 * s), DARK, M.SmoothPlastic)
		P("Wing", BALL, V(0.2, 0.5, 0.9) * s, CF(x * 3.4 * s, 0.55 * s, 0.05 * s), col:Lerp(C(200, 150, 40), 0.2), M.SmoothPlastic)
	end
end

builders.hydrant = function(P, s, _r)
	local red = C(220, 40, 40)
	P("Base", CYL, V(0.15, 1.0, 1.0) * s, CF(0, 0.08 * s, 0) * UP, red:Lerp(DARK, 0.3), M.Metal)
	P("Body", CYL, V(1.4, 0.75, 0.75) * s, CF(0, 0.85 * s, 0) * UP, red, M.Metal)
	P("Cap", BALL, V(0.8, 0.6, 0.8) * s, CF(0, 1.6 * s, 0), red, M.Metal)
	P("Nut", CYL, V(0.2, 0.25, 0.25) * s, CF(0, 1.9 * s, 0) * UP, C(230, 200, 60), M.Metal)
	for _, x in ipairs({ -1, 1 }) do
		P("Outlet", CYL, V(0.35, 0.35, 0.35) * s, CF(x * 0.5 * s, 1.0 * s, 0), red, M.Metal)
		P("OutletCap", CYL, V(0.08, 0.38, 0.38) * s, CF(x * 0.7 * s, 1.0 * s, 0), C(230, 200, 60), M.Metal)
	end
	P("Front", CYL, V(0.3, 0.42, 0.42) * s, CF(0, 0.95 * s, -0.45 * s) * CFrame.Angles(0, math.rad(90), 0), red, M.Metal)
end

builders.picnic = function(P, s, r)
	local wood = C(170, 120, 75):Lerp(C(140, 95, 60), r())
	P("Top", BLOCK, V(1.6, 0.12, 0.9) * s, CF(0, 0.75 * s, 0), wood, M.WoodPlanks)
	for _, z in ipairs({ -0.75, 0.75 }) do
		P("Seat", BLOCK, V(1.6, 0.1, 0.3) * s, CF(0, 0.42 * s, z * s), wood, M.WoodPlanks)
	end
	for _, x in ipairs({ -0.6, 0.6 }) do
		P("LegA", BLOCK, V(0.1, 0.9, 0.1) * s, CF(x * s, 0.4 * s, 0) * CFrame.Angles(math.rad(35), 0, 0), wood:Lerp(DARK, 0.2), M.Wood)
		P("LegB", BLOCK, V(0.1, 0.9, 0.1) * s, CF(x * s, 0.4 * s, 0) * CFrame.Angles(math.rad(-35), 0, 0), wood:Lerp(DARK, 0.2), M.Wood)
	end
	P("Cloth", BLOCK, V(0.9, 0.02, 0.7) * s, CF(0, 0.82 * s, 0), C(220, 60, 60), M.Fabric)
	P("Basket", BLOCK, V(0.35, 0.25, 0.25) * s, CF(0.3 * s, 0.95 * s, 0), C(190, 150, 90), M.Fabric)
	P("Apple", BALL, V(0.12, 0.12, 0.12) * s, CF(-0.2 * s, 0.89 * s, 0.1 * s), C(200, 30, 40), M.SmoothPlastic)
end

-- 2 마을
builders.doghouse = function(P, s, r)
	local col = hsv(r(), 0.5, 0.8)
	P("Box", BLOCK, V(1.3, 0.9, 1.4) * s, CF(0, 0.45 * s, 0), col, M.WoodPlanks)
	P("RoofL", BLOCK, V(0.85, 0.08, 1.6) * s, CF(-0.35 * s, 1.1 * s, 0) * CFrame.Angles(0, 0, math.rad(40)), C(170, 50, 40), M.WoodPlanks)
	P("RoofR", BLOCK, V(0.85, 0.08, 1.6) * s, CF(0.35 * s, 1.1 * s, 0) * CFrame.Angles(0, 0, math.rad(-40)), C(170, 50, 40), M.WoodPlanks)
	P("Gable", BLOCK, V(0.9, 0.9, 1.38) * s, CF(0, 0.95 * s, 0) * CFrame.Angles(0, 0, math.rad(45)), col, M.WoodPlanks)
	P("Door", CYL, V(0.04, 0.6, 0.6) * s, CF(0, 0.45 * s, -0.71 * s) * CFrame.Angles(0, math.rad(90), 0), DARK, M.SmoothPlastic)
	P("Sign", BLOCK, V(0.5, 0.15, 0.04) * s, CF(0, 0.85 * s, -0.72 * s), WHITE, M.Wood)
	P("Bowl", CYL, V(0.12, 0.35, 0.35) * s, CF(0.5 * s, 0.06 * s, -1 * s) * UP, C(60, 120, 220), M.SmoothPlastic)
	P("Bone", BLOCK, V(0.35, 0.06, 0.08) * s, CF(-0.4 * s, 0.03 * s, -0.95 * s), WHITE, M.SmoothPlastic)
end

builders.vending = function(P, s, r)
	local col = hsv(r(), 0.7, 0.85)
	P("Body", BLOCK, V(1.1, 2.0, 0.8) * s, CF(0, 1.0 * s, 0), col, M.Metal)
	P("Window", BLOCK, V(0.75, 1.1, 0.04) * s, CF(-0.1 * s, 1.3 * s, -0.41 * s), GLASS, M.Glass)
	for row = 0, 3 do
		for k = 0, 2 do
			P("Can", CYL, V(0.2, 0.12, 0.12) * s, CF((-0.35 + k * 0.25) * s, (0.9 + row * 0.27) * s, -0.3 * s) * UP, hsv(row * 0.2 + k * 0.1, 0.8, 1), M.SmoothPlastic)
		end
	end
	P("Panel", BLOCK, V(0.18, 0.6, 0.04) * s, CF(0.4 * s, 1.35 * s, -0.41 * s), DARK, M.SmoothPlastic)
	P("Slot", BLOCK, V(0.6, 0.18, 0.05) * s, CF(-0.1 * s, 0.35 * s, -0.41 * s), DARK, M.Metal)
	P("Light", BLOCK, V(1.0, 0.15, 0.05) * s, CF(0, 1.9 * s, -0.41 * s), WHITE, M.Neon)
end

builders.tent = function(P, s, r)
	local col = hsv(r(), 0.6, 0.9)
	P("SideL", BLOCK, V(0.06, 1.5, 2.2) * s, CF(-0.5 * s, 0.6 * s, 0) * CFrame.Angles(0, 0, math.rad(-35)), col, M.Fabric)
	P("SideR", BLOCK, V(0.06, 1.5, 2.2) * s, CF(0.5 * s, 0.6 * s, 0) * CFrame.Angles(0, 0, math.rad(35)), col, M.Fabric)
	P("Ridge", CYL, V(2.3, 0.08, 0.08) * s, CF(0, 1.22 * s, 0) * CFrame.Angles(0, math.rad(90), 0), C(120, 90, 60), M.Wood)
	P("Door", BLOCK, V(0.6, 0.8, 0.04) * s, CF(0, 0.4 * s, -1.08 * s), col:Lerp(DARK, 0.5), M.Fabric)
	P("Floor", BLOCK, V(1.8, 0.04, 2.3) * s, CF(0, 0.02 * s, 0), C(90, 90, 100), M.Fabric)
	P("Fire", BALL, V(0.25, 0.35, 0.25) * s, CF(0, 0.15 * s, -1.9 * s), C(255, 140, 40), M.Neon)
	for i = 0, 4 do
		local a = i * math.pi * 2 / 5
		P("Stone", BALL, V(0.15, 0.1, 0.15) * s, CF(math.cos(a) * 0.3 * s, 0.05 * s, -1.9 * s + math.sin(a) * 0.3 * s), C(120, 120, 120), M.Slate)
	end
	P("Log", CYL, V(0.9, 0.18, 0.18) * s, CF(0.9 * s, 0.09 * s, -1.6 * s), C(110, 75, 45), M.Wood)
end

-- 3 도시
builders.taxi = function(P, s, r)
	builders.car(P, s, r)
	P("TaxiSign", BLOCK, V(0.6, 0.22, 0.25) * s, CF(0, 1.72 * s, 0.25 * s), C(255, 210, 30), M.Neon)
	P("Stripe", BLOCK, V(1.72, 0.12, 2.4) * s, CF(0, 0.75 * s, 0), DARK, M.SmoothPlastic)
	for _, x in ipairs({ -0.86, 0.86 }) do
		for k = 0, 5 do
			P("Check", BLOCK, V(0.02, 0.06, 0.18) * s, CF(x * s, 0.75 * s, (-0.9 + k * 0.36) * s), WHITE, M.SmoothPlastic)
		end
	end
end

builders.firetruck = function(P, s, _r)
	local red = C(210, 30, 30)
	P("Body", BLOCK, V(1.8, 1.1, 3.6) * s, CF(0, 0.95 * s, 0.3 * s), red, M.SmoothPlastic)
	P("Cab", BLOCK, V(1.8, 1.3, 1.1) * s, CF(0, 1.05 * s, -1.85 * s), red, M.SmoothPlastic)
	P("Windshield", BLOCK, V(1.6, 0.55, 0.05) * s, CF(0, 1.35 * s, -2.41 * s), GLASS, M.Glass)
	P("Ladder", BLOCK, V(0.6, 0.12, 3.6) * s, CF(0, 1.62 * s, 0.4 * s), C(220, 220, 225), M.Metal)
	for k = 0, 8 do
		P("Rung", BLOCK, V(0.6, 0.14, 0.05) * s, CF(0, 1.64 * s, (-1.2 + k * 0.4) * s), C(180, 180, 190), M.Metal)
	end
	P("Siren", BLOCK, V(1.0, 0.15, 0.25) * s, CF(0, 1.77 * s, -1.85 * s), C(80, 140, 255), M.Neon)
	P("Stripe", BLOCK, V(1.82, 0.12, 4.6) * s, CF(0, 0.8 * s, -0.2 * s), WHITE, M.Neon)
	P("Hose", CYL, V(0.25, 0.6, 0.6) * s, CF(0.92 * s, 1.0 * s, 0.6 * s), C(230, 200, 60), M.Fabric)
	for _, x in ipairs({ -0.85, 0.85 }) do
		for _, z in ipairs({ -1.8, 0.2, 1.4 }) do
			wheel(P, CF(x * s, 0.4 * s, z * s), 0.8 * s, 0.3 * s)
		end
	end
end

builders.gasstation = function(P, s, r)
	local col = hsv(r(), 0.7, 0.9)
	P("Slab", BLOCK, V(3.2, 0.1, 2.2) * s, CF(0, 0.05 * s, 0), C(150, 150, 155), M.Concrete)
	P("Roof", BLOCK, V(3.2, 0.25, 2.2) * s, CF(0, 1.9 * s, 0), WHITE, M.SmoothPlastic)
	P("RoofBand", BLOCK, V(3.25, 0.15, 2.25) * s, CF(0, 1.75 * s, 0), col, M.Neon)
	for _, x in ipairs({ -1.2, 1.2 }) do
		P("Pillar", BLOCK, V(0.2, 1.7, 0.2) * s, CF(x * s, 0.95 * s, 0), WHITE, M.Metal)
	end
	for _, x in ipairs({ -0.6, 0.6 }) do
		P("Pump", BLOCK, V(0.35, 0.8, 0.25) * s, CF(x * s, 0.5 * s, 0), col, M.SmoothPlastic)
		P("Screen", BLOCK, V(0.25, 0.15, 0.03) * s, CF(x * s, 0.7 * s, -0.14 * s), C(120, 255, 150), M.Neon)
		P("Nozzle", BLOCK, V(0.06, 0.25, 0.06) * s, CF(x * s + 0.2 * s, 0.55 * s, 0), DARK, M.Rubber)
	end
	P("Shop", BLOCK, V(1.4, 1.2, 0.8) * s, CF(0.8 * s, 0.6 * s, 1.6 * s), C(230, 225, 210), M.Brick)
	P("ShopGlass", BLOCK, V(0.9, 0.5, 0.04) * s, CF(0.8 * s, 0.6 * s, 1.19 * s), GLASS, M.Glass)
	P("Sign", BLOCK, V(0.15, 1.6, 0.6) * s, CF(-1.5 * s, 2.6 * s, 1.0 * s), col, M.SmoothPlastic)
	P("SignPole", CYL, V(1.8, 0.12, 0.12) * s, CF(-1.5 * s, 0.9 * s, 1.0 * s) * UP, C(120, 120, 125), M.Metal)
end

-- 4 대도시
builders.helicopter = function(P, s, r)
	local col = hsv(r(), 0.6, 0.85)
	P("Body", BALL, V(1.4, 1.2, 2.0) * s, CF(0, 1.0 * s, 0), col, M.SmoothPlastic)
	P("Glass", BALL, V(1.1, 0.8, 0.9) * s, CF(0, 1.15 * s, -0.6 * s), GLASS, M.Glass)
	P("Tail", BLOCK, V(0.25, 0.25, 2.0) * s, CF(0, 1.15 * s, 1.8 * s), col, M.SmoothPlastic)
	P("TailFin", BLOCK, V(0.06, 0.6, 0.4) * s, CF(0, 1.4 * s, 2.75 * s), col, M.SmoothPlastic)
	P("TailRotor", BLOCK, V(0.04, 0.9, 0.1) * s, CF(0.15 * s, 1.3 * s, 2.75 * s), DARK, M.Metal)
	P("Mast", CYL, V(0.3, 0.12, 0.12) * s, CF(0, 1.75 * s, 0) * UP, DARK, M.Metal)
	P("Blade1", BLOCK, V(4.2, 0.05, 0.22) * s, CF(0, 1.9 * s, 0) * CFrame.Angles(0, math.rad(20), 0), DARK, M.Metal)
	P("Blade2", BLOCK, V(4.2, 0.05, 0.22) * s, CF(0, 1.9 * s, 0) * CFrame.Angles(0, math.rad(110), 0), DARK, M.Metal)
	for _, x in ipairs({ -0.55, 0.55 }) do
		P("Skid", BLOCK, V(0.08, 0.08, 2.0) * s, CF(x * s, 0.1 * s, 0), C(120, 120, 125), M.Metal)
		P("Strut", BLOCK, V(0.06, 0.4, 0.06) * s, CF(x * s, 0.3 * s, -0.4 * s), C(120, 120, 125), M.Metal)
		P("Strut2", BLOCK, V(0.06, 0.4, 0.06) * s, CF(x * s, 0.3 * s, 0.4 * s), C(120, 120, 125), M.Metal)
	end
end

builders.crane = function(P, s, _r)
	local yel = C(250, 190, 30)
	P("Base", BLOCK, V(1.2, 0.3, 1.2) * s, CF(0, 0.15 * s, 0), C(120, 120, 125), M.Concrete)
	for k = 0, 7 do
		P("Mast", BLOCK, V(0.4, 0.5, 0.4) * s, CF(0, (0.55 + k * 0.5) * s, 0), yel, M.Metal)
		P("Brace", BLOCK, V(0.05, 0.6, 0.05) * s, CF(0, (0.55 + k * 0.5) * s, -0.21 * s) * CFrame.Angles(0, 0, math.rad(40)), yel:Lerp(DARK, 0.3), M.Metal)
	end
	P("Jib", BLOCK, V(0.3, 0.3, 4.2) * s, CF(0, 4.4 * s, -0.9 * s), yel, M.Metal)
	P("Counter", BLOCK, V(0.6, 0.5, 0.6) * s, CF(0, 4.3 * s, 1.0 * s), C(140, 140, 145), M.Concrete)
	P("Cabin", BLOCK, V(0.5, 0.45, 0.5) * s, CF(0.35 * s, 4.0 * s, 0), WHITE, M.SmoothPlastic)
	P("Cable", BLOCK, V(0.03, 1.8, 0.03) * s, CF(0, 3.4 * s, -2.6 * s), DARK, M.Metal)
	P("Hook", BLOCK, V(0.2, 0.2, 0.2) * s, CF(0, 2.45 * s, -2.6 * s), C(200, 60, 40), M.Metal)
	P("Load", BLOCK, V(0.8, 0.3, 0.3) * s, CF(0, 2.2 * s, -2.6 * s), C(110, 80, 50), M.WoodPlanks)
	P("Beacon", BALL, V(0.15, 0.15, 0.15) * s, CF(0, 4.65 * s, -0.9 * s), C(255, 50, 50), M.Neon)
end

builders.airplane = function(P, s, r)
	local tail = hsv(r(), 0.7, 0.9)
	P("Body", CYL, V(4.2, 0.7, 0.7) * s, CF(0, 0.8 * s, 0) * CFrame.Angles(0, math.rad(90), 0), WHITE, M.SmoothPlastic)
	P("Nose", BALL, V(0.7, 0.7, 0.9) * s, CF(0, 0.8 * s, -2.1 * s), WHITE, M.SmoothPlastic)
	P("Cockpit", BLOCK, V(0.5, 0.15, 0.3) * s, CF(0, 1.0 * s, -2.15 * s) * CFrame.Angles(math.rad(-25), 0, 0), GLASS, M.Glass)
	P("Wing", BLOCK, V(4.0, 0.08, 0.8) * s, CF(0, 0.7 * s, 0), C(220, 222, 228), M.SmoothPlastic)
	P("TailWing", BLOCK, V(1.4, 0.06, 0.4) * s, CF(0, 0.9 * s, 1.9 * s), C(220, 222, 228), M.SmoothPlastic)
	P("Fin", BLOCK, V(0.06, 0.8, 0.6) * s, CF(0, 1.4 * s, 1.9 * s), tail, M.SmoothPlastic)
	P("Stripe", BLOCK, V(0.72, 0.1, 3.6) * s, CF(0, 0.75 * s, 0), tail, M.SmoothPlastic)
	for _, x in ipairs({ -1.0, 1.0 }) do
		P("Engine", CYL, V(0.6, 0.3, 0.3) * s, CF(x * s, 0.5 * s, -0.1 * s) * CFrame.Angles(0, math.rad(90), 0), C(170, 170, 180), M.Metal)
	end
	for k = 0, 8 do
		for _, x in ipairs({ -0.36, 0.36 }) do
			P("Window", BLOCK, V(0.02, 0.1, 0.1) * s, CF(x * s, 0.95 * s, (-1.4 + k * 0.3) * s), C(60, 80, 110), M.Glass)
		end
	end
	P("Gear", BLOCK, V(0.1, 0.4, 0.1) * s, CF(0, 0.25 * s, -1.6 * s), DARK, M.Metal)
	wheel(P, CF(0, 0.1 * s, -1.6 * s), 0.2 * s, 0.1 * s)
	for _, x in ipairs({ -0.4, 0.4 }) do
		wheel(P, CF(x * s, 0.12 * s, 0.2 * s), 0.25 * s, 0.12 * s)
	end
end

-- 5 바다와 산
builders.whale = function(P, s, _r)
	local col = C(60, 90, 140)
	P("Water", CYL, V(0.1, 4.0, 4.0) * s, CF(0, 0.05 * s, 0) * UP, C(60, 140, 210), M.Glass).Transparency = 0.3
	P("Body", BALL, V(1.6, 1.2, 3.4) * s, CF(0, 0.5 * s, 0), col, M.SmoothPlastic)
	P("Belly", BALL, V(1.3, 0.8, 3.0) * s, CF(0, 0.3 * s, -0.1 * s), C(220, 225, 235), M.SmoothPlastic)
	P("Tail", BLOCK, V(1.6, 0.08, 0.5) * s, CF(0, 0.6 * s, 2.0 * s) * CFrame.Angles(math.rad(-20), 0, 0), col, M.SmoothPlastic)
	for _, x in ipairs({ -0.75, 0.75 }) do
		P("Fin", BLOCK, V(0.6, 0.06, 0.3) * s, CF(x * s, 0.35 * s, -0.4 * s) * CFrame.Angles(0, 0, x * 0.5), col, M.SmoothPlastic)
		P("Eye", BALL, V(0.1, 0.12, 0.12) * s, CF(x * 0.72 * s, 0.55 * s, -1.2 * s), DARK, M.SmoothPlastic)
	end
	for i = 0, 3 do
		P("Spout", BALL, V(0.3, 0.4, 0.3) * s * (1 - i * 0.15), CF((i % 2 - 0.5) * 0.15 * s, (1.2 + i * 0.35) * s, -0.6 * s), C(220, 240, 255), M.Glass).Transparency = 0.2 + i * 0.15
	end
end

builders.volcano = function(P, s, r)
	local rock = C(90, 70, 60)
	P("Base", CYL, V(0.6, 3.6, 3.6) * s, CF(0, 0.3 * s, 0) * UP, rock, M.Basalt)
	P("Mid", CYL, V(0.7, 2.6, 2.6) * s, CF(0, 0.9 * s, 0) * UP, rock:Lerp(DARK, 0.1), M.Basalt)
	P("Upper", CYL, V(0.6, 1.7, 1.7) * s, CF(0, 1.5 * s, 0) * UP, rock:Lerp(DARK, 0.2), M.Basalt)
	P("Crater", CYL, V(0.1, 1.2, 1.2) * s, CF(0, 1.81 * s, 0) * UP, C(255, 110, 20), M.Neon)
	P("Glow", BALL, V(0.9, 0.5, 0.9) * s, CF(0, 1.95 * s, 0), C(255, 80, 20), M.Neon).Transparency = 0.3
	for i = 0, 4 do
		local a = i * 1.3 + r()
		P("Lava", BLOCK, V(0.15, 1.6, 0.25) * s, CF(math.cos(a) * 0.95 * s, 1.0 * s, math.sin(a) * 0.95 * s) * CFrame.Angles(0, -a, math.rad(35)), C(255, 90, 20), M.CrackedLava)
	end
	for i = 0, 3 do
		P("Smoke", BALL, V(0.7, 0.6, 0.7) * s * (1 + i * 0.25), CF(i * 0.15 * s, (2.3 + i * 0.5) * s, 0), C(90, 90, 95), M.SmoothPlastic).Transparency = 0.3 + i * 0.15
	end
end

-- 6 우주
builders.comet = function(P, s, _r)
	P("Head", BALL, V(1.4, 1.4, 1.4) * s, CF(0, 1.0 * s, 0), C(200, 230, 255), M.Ice)
	P("Core", BALL, V(1.0, 1.0, 1.0) * s, CF(0, 1.0 * s, 0), WHITE, M.Neon)
	for i = 1, 6 do
		P("Tail", BALL, V(1.3 - i * 0.15, 1.3 - i * 0.15, 1.2) * s, CF(0, (1.0 + i * 0.12) * s, i * 0.75 * s), C(140, 200, 255), M.Neon).Transparency = 0.2 + i * 0.12
	end
end

builders.spacestation = function(P, s, _r)
	P("Hub", CYL, V(0.8, 0.8, 0.8) * s, CF(0, 1.2 * s, 0) * UP, C(220, 222, 228), M.Metal)
	P("Ring", CYL, V(0.15, 3.0, 3.0) * s, CF(0, 1.2 * s, 0) * UP, C(200, 202, 210), M.Metal)
	P("RingHole", CYL, V(0.17, 2.6, 2.6) * s, CF(0, 1.2 * s, 0) * UP, C(20, 20, 30), M.SmoothPlastic)
	for i = 0, 3 do
		local a = i * math.pi / 2
		P("Spoke", BLOCK, V(0.12, 0.12, 1.3) * s, CF(0, 1.2 * s, 0) * CFrame.Angles(0, a, 0) * CF(0, 0, 0.75 * s), C(180, 180, 190), M.Metal)
		P("Light", BALL, V(0.15, 0.15, 0.15) * s, CF(math.cos(a) * 1.5 * s, 1.2 * s, math.sin(a) * 1.5 * s), C(120, 220, 255), M.Neon)
	end
	for _, x in ipairs({ -1, 1 }) do
		P("Panel", BLOCK, V(1.4, 0.04, 0.7) * s, CF(x * 2.3 * s, 1.2 * s, 0), C(40, 70, 160), M.Glass)
		P("Arm", BLOCK, V(0.8, 0.08, 0.08) * s, CF(x * 1.55 * s, 1.2 * s, 0), C(180, 180, 190), M.Metal)
	end
	P("Dock", CYL, V(1.0, 0.3, 0.3) * s, CF(0, 2.0 * s, 0) * UP, C(220, 222, 228), M.Metal)
	P("Leg", CYL, V(0.8, 0.2, 0.2) * s, CF(0, 0.4 * s, 0) * UP, C(120, 120, 130), M.Metal)
end

builders.galaxy = function(P, s, r)
	local a0 = r() * 6
	P("Core", BALL, V(0.7, 0.4, 0.7) * s, CF(0, 0.6 * s, 0), C(255, 240, 200), M.Neon)
	P("Disk", CYL, V(0.04, 2.2, 2.2) * s, CF(0, 0.55 * s, 0) * UP, C(120, 90, 200), M.Neon).Transparency = 0.6
	for arm = 0, 1 do
		for k = 1, 9 do
			local t = k / 9
			local a = a0 + arm * math.pi + t * 3.2
			local d = t * 1.1 * s
			P("Star", BALL, V(0.22, 0.12, 0.22) * s * (1.2 - t * 0.6), CF(math.cos(a) * d, 0.6 * s, math.sin(a) * d), C(200, 210, 255):Lerp(C(255, 150, 230), t), M.Neon)
		end
	end
end

-- 7 젤리 들판
builders.chocobar = function(P, s, _r)
	P("Wrapper", BLOCK, V(1.0, 0.25, 1.8) * s, CF(0, 0.13 * s, 0.35 * s), C(200, 40, 60), M.Foil)
	P("Label", BLOCK, V(0.8, 0.26, 0.5) * s, CF(0, 0.13 * s, 0.6 * s), C(255, 220, 90), M.SmoothPlastic)
	for i = 0, 2 do
		for j = 0, 1 do
			P("Piece", BLOCK, V(0.45, 0.2, 0.4) * s, CF((j - 0.5) * 0.48 * s, 0.12 * s, (-0.9 + i * 0.42) * s), C(110, 60, 35), M.SmoothPlastic)
		end
	end
end

builders.marshmallow = function(P, s, r)
	local col = r() < 0.5 and WHITE or C(255, 200, 220)
	P("Body", CYL, V(1.2, 1.2, 1.2) * s, CF(0, 0.6 * s, 0) * UP, col, M.SmoothPlastic)
	P("Top", CYL, V(0.05, 1.1, 1.1) * s, CF(0, 1.21 * s, 0) * UP, col:Lerp(C(240, 220, 200), 0.3), M.SmoothPlastic)
	P("Stick", CYL, V(1.6, 0.08, 0.08) * s, CF(0, 1.6 * s, 0) * UP, C(190, 150, 100), M.Wood)
	for _, x in ipairs({ -0.2, 0.2 }) do
		P("Eye", BALL, V(0.1, 0.12, 0.05) * s, CF(x * s, 0.75 * s, -0.6 * s), DARK, M.SmoothPlastic)
	end
	P("Smile", BLOCK, V(0.2, 0.04, 0.04) * s, CF(0, 0.55 * s, -0.6 * s), DARK, M.SmoothPlastic)
end

-- 8 과자 마을
builders.milk = function(P, s, r)
	local col = hsv(r(), 0.45, 1)
	P("Box", BLOCK, V(1.0, 1.6, 1.0) * s, CF(0, 0.8 * s, 0), WHITE, M.SmoothPlastic)
	P("Label", BLOCK, V(1.02, 0.6, 1.02) * s, CF(0, 0.75 * s, 0), col, M.SmoothPlastic)
	P("RoofA", BLOCK, V(0.72, 0.06, 1.0) * s, CF(-0.25 * s, 1.8 * s, 0) * CFrame.Angles(0, 0, math.rad(40)), WHITE, M.SmoothPlastic)
	P("RoofB", BLOCK, V(0.72, 0.06, 1.0) * s, CF(0.25 * s, 1.8 * s, 0) * CFrame.Angles(0, 0, math.rad(-40)), WHITE, M.SmoothPlastic)
	P("Cap", CYL, V(0.15, 0.25, 0.25) * s, CF(0.2 * s, 2.0 * s, -0.2 * s) * UP, col, M.SmoothPlastic)
	P("Straw", CYL, V(1.0, 0.08, 0.08) * s, CF(-0.2 * s, 2.3 * s, 0.2 * s) * UP, C(255, 120, 160), M.SmoothPlastic)
	for _, x in ipairs({ -0.2, 0.2 }) do
		P("Eye", BALL, V(0.1, 0.12, 0.05) * s, CF(x * s, 1.25 * s, -0.51 * s), DARK, M.SmoothPlastic)
	end
end

builders.waffle = function(P, s, _r)
	local col = C(225, 170, 90)
	P("Waffle", BLOCK, V(2.0, 0.3, 2.0) * s, CF(0, 0.15 * s, 0), col, M.Sand)
	for i = -2, 2 do
		P("GridX", BLOCK, V(2.0, 0.08, 0.08) * s, CF(0, 0.32 * s, i * 0.38 * s), col:Lerp(DARK, 0.15), M.Sand)
		P("GridZ", BLOCK, V(0.08, 0.08, 2.0) * s, CF(i * 0.38 * s, 0.32 * s, 0), col:Lerp(DARK, 0.15), M.Sand)
	end
	P("Butter", BLOCK, V(0.45, 0.2, 0.45) * s, CF(0, 0.42 * s, 0), C(255, 240, 150), M.SmoothPlastic)
	P("Syrup", CYL, V(0.04, 1.2, 1.2) * s, CF(0, 0.34 * s, 0) * UP, C(170, 90, 30), M.Glass).Transparency = 0.2
	P("Berry", BALL, V(0.25, 0.25, 0.25) * s, CF(0.6 * s, 0.45 * s, 0.5 * s), C(220, 30, 60), M.SmoothPlastic)
	P("Berry2", BALL, V(0.22, 0.22, 0.22) * s, CF(-0.5 * s, 0.44 * s, -0.6 * s), C(60, 60, 200), M.SmoothPlastic)
end

-- 9 케이크 도시
builders.jellybus = function(P, s, r)
	local col = pastel(r)
	P("Body", BLOCK, V(1.8, 1.4, 4.4) * s, CF(0, 1.05 * s, 0), col, M.Glass).Transparency = 0.15
	P("Inner", BLOCK, V(1.5, 1.1, 4.1) * s, CF(0, 1.05 * s, 0), col:Lerp(WHITE, 0.4), M.SmoothPlastic).Transparency = 0.3
	P("Roof", BLOCK, V(1.85, 0.15, 4.45) * s, CF(0, 1.8 * s, 0), WHITE, M.SmoothPlastic)
	for k = 0, 4 do
		for _, x in ipairs({ -0.91, 0.91 }) do
			P("Window", BLOCK, V(0.04, 0.45, 0.6) * s, CF(x * s, 1.3 * s, (-1.6 + k * 0.8) * s), C(255, 250, 230), M.Neon)
		end
	end
	for _, x in ipairs({ -0.85, 0.85 }) do
		for _, z in ipairs({ -1.5, 1.5 }) do
			P("GumWheel", CYL, V(0.3 * s, 0.8 * s, 0.8 * s), CF(x * s, 0.4 * s, z * s), C(60, 40, 30), M.SmoothPlastic)
		end
	end
	P("Sign", BLOCK, V(1.2, 0.3, 0.04) * s, CF(0, 1.6 * s, -2.22 * s), C(255, 230, 120), M.Neon)
end

builders.chocotower = function(P, s, _r)
	local choco = C(100, 55, 30)
	for k = 0, 4 do
		P("Floor", BLOCK, V(1.6 - k * 0.15, 0.75, 1.6 - k * 0.15) * s, CF(0, (0.38 + k * 0.75) * s, 0), choco:Lerp(C(160, 100, 60), (k % 2) * 0.4), M.SmoothPlastic)
		P("Cream", BLOCK, V(1.65 - k * 0.15, 0.08, 1.65 - k * 0.15) * s, CF(0, (0.76 + k * 0.75) * s, 0), WHITE, M.SmoothPlastic)
		for _, x in ipairs({ -0.3, 0.3 }) do
			P("Window", BLOCK, V(0.25, 0.3, 0.04) * s, CF(x * s, (0.4 + k * 0.75) * s, -(0.81 - k * 0.075) * s), C(255, 220, 140), M.Neon)
		end
	end
	P("Cherry", BALL, V(0.5, 0.5, 0.5) * s, CF(0, 4.05 * s, 0), C(220, 30, 50), M.SmoothPlastic)
	P("Stem", CYL, V(0.4, 0.05, 0.05) * s, CF(0, 4.4 * s, 0) * UP, C(80, 140, 50), M.SmoothPlastic)
end

-- 10 아이스크림 산맥
builders.parfait = function(P, s, r)
	P("Foot", CYL, V(0.1, 1.0, 1.0) * s, CF(0, 0.05 * s, 0) * UP, GLASS, M.Glass)
	P("Stem", CYL, V(0.8, 0.2, 0.2) * s, CF(0, 0.5 * s, 0) * UP, GLASS, M.Glass)
	for k = 0, 3 do
		P("Layer", CYL, V(0.45, 1.3 + k * 0.12, 1.3 + k * 0.12) * s, CF(0, (1.1 + k * 0.45) * s, 0) * UP, hsv(r() * 0.2 + k * 0.25, 0.4, 1), M.SmoothPlastic)
	end
	P("Glass", CYL, V(1.9, 1.8, 1.8) * s, CF(0, 1.75 * s, 0) * UP, GLASS, M.Glass).Transparency = 0.6
	P("Scoop", BALL, V(1.2, 1.0, 1.2) * s, CF(0, 2.9 * s, 0), C(255, 230, 240), M.SmoothPlastic)
	P("Wafer", BLOCK, V(0.15, 0.9, 0.35) * s, CF(0.35 * s, 3.3 * s, 0) * CFrame.Angles(0, 0, math.rad(-20)), C(230, 190, 120), M.Sand)
	P("Cherry", BALL, V(0.3, 0.3, 0.3) * s, CF(-0.1 * s, 3.45 * s, 0), C(220, 30, 50), M.SmoothPlastic)
end

builders.cottoncloud = function(P, s, r)
	local col = pastel(r)
	for i = 0, 6 do
		local a = i * 0.9
		P("Puff", BALL, V(1.2, 0.9, 1.2) * s * (0.8 + (i % 3) * 0.15), CF(math.cos(a) * 0.9 * s, (1.6 + math.sin(a * 2) * 0.2) * s, math.sin(a) * 0.6 * s), col:Lerp(WHITE, (i % 2) * 0.3), M.SmoothPlastic)
	end
	P("Center", BALL, V(1.6, 1.2, 1.4) * s, CF(0, 1.9 * s, 0), col:Lerp(WHITE, 0.2), M.SmoothPlastic)
	for i = 0, 4 do
		P("Drop", BALL, V(0.15, 0.25, 0.15) * s, CF((i - 2) * 0.4 * s, (0.6 + (i % 2) * 0.4) * s, 0), hsv(i / 5, 0.5, 1), M.Neon)
	end
end

-- 11 사탕 우주
builders.candyasteroid = function(P, s, r)
	local col = pastel(r)
	P("Rock", BALL, V(2.0, 1.6, 1.8) * s, CF(0, 0.9 * s, 0), col, M.SmoothPlastic)
	for i = 0, 7 do
		local a = i * 0.8
		P("Sprinkle", BLOCK, V(0.35, 0.1, 0.1) * s, CF(math.cos(a) * 0.95 * s, (0.9 + math.sin(a * 1.7) * 0.6) * s, math.sin(a) * 0.85 * s) * CFrame.Angles(a, a * 2, 0), hsv(i / 8, 0.6, 1), M.SmoothPlastic)
	end
	P("Bite", BALL, V(0.8, 0.8, 0.8) * s, CF(0.8 * s, 1.3 * s, -0.4 * s), col:Lerp(WHITE, 0.5), M.SmoothPlastic)
end

builders.chocoplanet = function(P, s, _r)
	P("Planet", BALL, V(2, 2, 2) * s, CF(0, 1.0 * s, 0), C(110, 60, 35), M.SmoothPlastic)
	P("Drizzle", CYL, V(0.15 * s, 2.03 * s, 2.03 * s), CF(0, 1.3 * s, 0) * UP, C(250, 240, 230), M.SmoothPlastic)
	P("Drizzle2", CYL, V(0.12 * s, 2.03 * s, 2.03 * s), CF(0, 0.75 * s, 0) * UP, C(255, 150, 190), M.SmoothPlastic)
	P("Ring", CYL, V(0.06 * s, 3.4 * s, 3.4 * s), CF(0, 1.0 * s, 0) * CFrame.Angles(math.rad(-15), 0, math.rad(90)), C(240, 200, 120), M.SmoothPlastic)
	for i = 0, 5 do
		local a = i * math.pi / 3
		P("Nut", BALL, V(0.25, 0.2, 0.25) * s, CF(math.cos(a) * 1.55 * s, (1.0 + math.sin(a) * 0.4) * s, math.sin(a) * 1.55 * s), C(200, 150, 80), M.SmoothPlastic)
	end
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
		p.Size = V(math.clamp(sz.X, 0.05, 2048), math.clamp(sz.Y, 0.05, 2048), math.clamp(sz.Z, 0.05, 2048))
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
	return model
end

function Props.has(kind: string): boolean
	return builders[kind] ~= nil
end

return Props
