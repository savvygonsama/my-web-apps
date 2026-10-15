-- SatBuilder (ModuleScript, ReplicatedStorage)
-- 위성(펫) 모양 18종. 블랙홀 둘레를 도는 모델과 위성 창의 미리보기에 같이 쓴다.
-- 모델 가운데가 기준점이고, s는 대략 반지름이다. 황금 위성은 금빛으로 덮고 반짝이를 붙인다.

local SatBuilder = {}

type MakeFn = (string, Enum.PartType?, Vector3, CFrame, Color3, Enum.Material) -> Part
type Builder = (MakeFn, number, Color3) -> ()

local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder
local BLOCK = Enum.PartType.Block
local M = Enum.Material
local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local UP = ANG(0, 0, math.rad(90))
local DARK = C(15, 10, 25)
local WHITE = C(250, 250, 250)
local GOLD = C(255, 205, 70)

local builders: { [string]: Builder } = {}

builders.rock = function(P, s, col)
	P("Body", BALL, V(2, 1.7, 1.8) * s, CF(), col, M.Slate)
	P("Bump", BALL, V(1, 0.9, 1) * s, CF(0.6 * s, 0.4 * s, 0.3 * s), col:Lerp(DARK, 0.2), M.Slate)
	P("Bump", BALL, V(0.8, 0.7, 0.8) * s, CF(-0.5 * s, -0.4 * s, -0.4 * s), col:Lerp(WHITE, 0.15), M.Slate)
	P("EyeL", BALL, V(0.32, 0.4, 0.2) * s, CF(-0.3 * s, 0.2 * s, -0.85 * s), DARK, M.SmoothPlastic)
	P("EyeR", BALL, V(0.32, 0.4, 0.2) * s, CF(0.3 * s, 0.2 * s, -0.85 * s), DARK, M.SmoothPlastic)
end

builders.moon = function(P, s, col)
	P("Body", BALL, V(2, 2, 2) * s, CF(), col, M.Slate)
	for i = 1, 5 do
		local a = i * 1.3
		local dir = Vector3.new(math.cos(a), math.sin(a * 1.7) * 0.6, math.sin(a)).Unit
		P("Crater", CYL, V(0.12, 0.5, 0.5) * s, CFrame.lookAt(dir * 0.95 * s, dir * 2 * s) * ANG(0, math.rad(90), 0), col:Lerp(DARK, 0.3), M.Slate)
	end
end

builders.comet = function(P, s, col)
	P("Head", BALL, V(1.6, 1.6, 1.6) * s, CF(), col:Lerp(WHITE, 0.5), M.Neon)
	P("Ice", BALL, V(1.2, 1.2, 1.2) * s, CF(-0.1 * s, 0.1 * s, -0.2 * s), col, M.Ice)
	for i = 1, 5 do
		local t = i / 5
		P("Tail", BALL, V(1.4 - t, 1.4 - t, 1.6) * s, CF(0, 0, (0.6 + i * 0.7) * s), col:Lerp(WHITE, t * 0.3), M.Neon).Transparency = 0.15 + t * 0.6
	end
end

builders.ufo = function(P, s, col)
	P("Disc", CYL, V(0.5, 2.8, 2.8) * s, UP, C(190, 195, 205), M.Metal)
	P("Rim", CYL, V(0.2, 3.1, 3.1) * s, UP, col, M.Neon)
	P("Dome", BALL, V(1.5, 1.2, 1.5) * s, CF(0, 0.35 * s, 0), C(170, 230, 255), M.Glass).Transparency = 0.3
	P("Alien", BALL, V(0.6, 0.7, 0.6) * s, CF(0, 0.4 * s, 0), C(120, 230, 120), M.SmoothPlastic)
	for i = 0, 5 do
		local a = i * math.pi / 3
		P("Light", BALL, V(0.3, 0.3, 0.3) * s, CF(math.cos(a) * 1.25 * s, -0.15 * s, math.sin(a) * 1.25 * s), i % 2 == 0 and C(255, 240, 120) or col, M.Neon)
	end
	P("Beam", CYL, V(1.2, 1, 1) * s, CF(0, -0.8 * s, 0) * UP, col, M.Neon).Transparency = 0.7
end

builders.hole = function(P, s, col)
	P("Void", BALL, V(1.4, 1.4, 1.4) * s, CF(), C(0, 0, 0), M.SmoothPlastic)
	P("Disk", CYL, V(0.1, 3, 3) * s, UP, col, M.Neon).Transparency = 0.35
	P("Disk2", CYL, V(0.12, 2.2, 2.2) * s, UP, col:Lerp(WHITE, 0.4), M.Neon).Transparency = 0.2
	P("Glow", BALL, V(1.7, 1.7, 1.7) * s, CF(), col, M.ForceField).Transparency = 0.3
end

builders.star = function(P, s, col)
	P("Core", BALL, V(1.3, 1.3, 1.3) * s, CF(), col:Lerp(WHITE, 0.3), M.Neon)
	for i = 0, 4 do
		local a = i * math.pi * 2 / 5
		P("Point", BLOCK, V(0.45, 1.4, 0.45) * s, ANG(0, 0, a) * CF(0, 1 * s, 0) * ANG(0, math.rad(45), 0), col, M.Neon)
	end
	P("Halo", CYL, V(0.06, 3.2, 3.2) * s, ANG(0, math.rad(90), 0), col, M.Neon).Transparency = 0.6
end

builders.ringed = function(P, s, col)
	P("Planet", BALL, V(1.8, 1.8, 1.8) * s, CF(), col, M.SmoothPlastic)
	P("Band", BALL, V(1.84, 0.4, 1.84) * s, CF(0, 0.3 * s, 0), col:Lerp(C(160, 100, 60), 0.4), M.SmoothPlastic)
	P("Ring", CYL, V(0.06, 3.6, 3.6) * s, ANG(0.35, 0, 0) * UP, col:Lerp(WHITE, 0.4), M.Neon).Transparency = 0.3
	P("Ring2", CYL, V(0.05, 3, 3) * s, ANG(0.35, 0, 0) * UP, col:Lerp(DARK, 0.2), M.SmoothPlastic).Transparency = 0.2
end

builders.robot = function(P, s, col)
	P("Body", BLOCK, V(1.4, 1.2, 1.1) * s, CF(), col, M.Metal)
	P("Head", BLOCK, V(1, 0.7, 0.9) * s, CF(0, 0.95 * s, 0), col:Lerp(WHITE, 0.2), M.Metal)
	P("Visor", BLOCK, V(0.8, 0.25, 0.1) * s, CF(0, 0.95 * s, -0.46 * s), C(80, 220, 255), M.Neon)
	P("Antenna", CYL, V(0.6, 0.08, 0.08) * s, CF(0, 1.55 * s, 0) * UP, DARK, M.Metal)
	P("Tip", BALL, V(0.22, 0.22, 0.22) * s, CF(0, 1.85 * s, 0), C(255, 80, 80), M.Neon)
	P("PanelL", BLOCK, V(1.4, 0.06, 0.7) * s, CF(-1.45 * s, 0, 0), C(40, 60, 140), M.Glass)
	P("PanelR", BLOCK, V(1.4, 0.06, 0.7) * s, CF(1.45 * s, 0, 0), C(40, 60, 140), M.Glass)
	P("Jet", CYL, V(0.4, 0.5, 0.5) * s, CF(0, -0.75 * s, 0) * UP, C(255, 150, 60), M.Neon)
end

builders.crystal = function(P, s, col)
	P("Rock", BALL, V(1.6, 1.3, 1.5) * s, CF(0, -0.3 * s, 0), C(90, 85, 100), M.Slate)
	for i = 0, 5 do
		local a = i * 1.05
		local h = 1 + (i % 3) * 0.35
		P("Shard", BLOCK, V(0.35, h, 0.35) * s, ANG(math.cos(a) * 0.6, a, math.sin(a) * 0.6) * CF(0, 0.5 * s + h * 0.4 * s, 0) * ANG(0, math.rad(45), 0), col, M.Glass).Transparency = 0.15
	end
	P("Glow", BALL, V(0.6, 0.6, 0.6) * s, CF(0, 0.3 * s, 0), col, M.Neon)
end

builders.jelly = function(P, s, col)
	P("Bell", BALL, V(2, 1.4, 2) * s, CF(0, 0.3 * s, 0), col, M.Glass).Transparency = 0.3
	P("Inner", BALL, V(1.1, 0.8, 1.1) * s, CF(0, 0.35 * s, 0), col:Lerp(WHITE, 0.4), M.Neon)
	for i = 0, 5 do
		local a = i * math.pi / 3
		local x, z = math.cos(a) * 0.6 * s, math.sin(a) * 0.6 * s
		P("Tentacle", CYL, V(1.4, 0.12, 0.12) * s, CF(x, -0.6 * s, z) * ANG(0, 0, math.rad(90)) * ANG(math.sin(a) * 0.25, 0, 0), col:Lerp(WHITE, 0.2), M.Neon).Transparency = 0.3
	end
end

builders.binary = function(P, s, col)
	P("StarA", BALL, V(1.2, 1.2, 1.2) * s, CF(-0.9 * s, 0, 0), col, M.Neon)
	P("StarB", BALL, V(0.9, 0.9, 0.9) * s, CF(0.9 * s, 0, 0), C(140, 200, 255), M.Neon)
	P("Bridge", CYL, V(1.4, 0.25, 0.25) * s, CF(), col:Lerp(C(140, 200, 255), 0.5), M.Neon).Transparency = 0.4
	P("Orbit", CYL, V(0.04, 3.4, 3.4) * s, UP, WHITE, M.Neon).Transparency = 0.6
end

builders.quasar = function(P, s, col)
	P("Core", BALL, V(1, 1, 1) * s, CF(), WHITE, M.Neon)
	P("Disk", CYL, V(0.12, 3, 3) * s, UP, col, M.Neon).Transparency = 0.25
	P("Disk2", CYL, V(0.14, 2, 2) * s, UP, col:Lerp(C(255, 120, 255), 0.5), M.Neon).Transparency = 0.15
	P("JetUp", CYL, V(3, 0.3, 0.3) * s, CF(0, 1.6 * s, 0) * UP, col:Lerp(WHITE, 0.5), M.Neon).Transparency = 0.2
	P("JetDown", CYL, V(3, 0.3, 0.3) * s, CF(0, -1.6 * s, 0) * UP, col:Lerp(WHITE, 0.5), M.Neon).Transparency = 0.2
end

builders.gummy = function(P, s, col)
	P("Body", BALL, V(1.4, 1.5, 1.1) * s, CF(0, -0.3 * s, 0), col, M.Glass).Transparency = 0.15
	P("Head", BALL, V(1.1, 1, 1) * s, CF(0, 0.75 * s, 0), col, M.Glass).Transparency = 0.15
	P("EarL", BALL, V(0.4, 0.4, 0.3) * s, CF(-0.45 * s, 1.2 * s, 0), col, M.Glass).Transparency = 0.15
	P("EarR", BALL, V(0.4, 0.4, 0.3) * s, CF(0.45 * s, 1.2 * s, 0), col, M.Glass).Transparency = 0.15
	P("ArmL", BALL, V(0.4, 0.7, 0.4) * s, CF(-0.7 * s, -0.1 * s, 0), col, M.Glass).Transparency = 0.15
	P("ArmR", BALL, V(0.4, 0.7, 0.4) * s, CF(0.7 * s, -0.1 * s, 0), col, M.Glass).Transparency = 0.15
	P("EyeL", BALL, V(0.15, 0.15, 0.1) * s, CF(-0.2 * s, 0.85 * s, -0.48 * s), DARK, M.SmoothPlastic)
	P("EyeR", BALL, V(0.15, 0.15, 0.1) * s, CF(0.2 * s, 0.85 * s, -0.48 * s), DARK, M.SmoothPlastic)
end

builders.cookie = function(P, s, col)
	P("Cookie", CYL, V(0.5, 2.4, 2.4) * s, UP, col, M.Sand)
	for i = 0, 6 do
		local a = i * 0.9
		local d = (0.3 + (i % 3) * 0.3) * s
		P("Chip", BALL, V(0.3, 0.2, 0.3) * s, CF(math.cos(a) * d, 0.25 * s, math.sin(a) * d), C(70, 40, 25), M.SmoothPlastic)
	end
end

builders.donut = function(P, s, col)
	for i = 0, 11 do
		local a = i * math.pi / 6
		P("Dough", BALL, V(0.8, 0.7, 0.8) * s, CF(math.cos(a) * 0.9 * s, 0, math.sin(a) * 0.9 * s), C(220, 170, 110), M.SmoothPlastic)
		P("Icing", BALL, V(0.78, 0.4, 0.78) * s, CF(math.cos(a) * 0.9 * s, 0.2 * s, math.sin(a) * 0.9 * s), Color3.fromHSV(i / 12, 0.5, 1), M.SmoothPlastic)
	end
end

builders.dragon = function(P, s, col)
	-- 몸통은 구슬 여러 개를 물결처럼 잇는다
	for i = 0, 7 do
		local t = i / 7
		local w = (1 - t * 0.6) * s
		P("Body", BALL, V(w, w, w) * 1.1, CF(math.sin(t * 6) * 0.4 * s, math.cos(t * 5) * 0.3 * s, t * 3 * s - 0.6 * s), col:Lerp(C(120, 20, 20), t * 0.5), M.SmoothPlastic)
	end
	P("Head", BLOCK, V(0.9, 0.7, 1.2) * s, CF(0, 0.1 * s, -1.2 * s), col, M.SmoothPlastic)
	P("Jaw", BLOCK, V(0.7, 0.25, 0.8) * s, CF(0, -0.25 * s, -1.4 * s), col:Lerp(DARK, 0.3), M.SmoothPlastic)
	P("EyeL", BALL, V(0.2, 0.2, 0.2) * s, CF(-0.35 * s, 0.3 * s, -1.6 * s), C(255, 240, 80), M.Neon)
	P("EyeR", BALL, V(0.2, 0.2, 0.2) * s, CF(0.35 * s, 0.3 * s, -1.6 * s), C(255, 240, 80), M.Neon)
	P("HornL", BLOCK, V(0.12, 0.6, 0.12) * s, CF(-0.3 * s, 0.6 * s, -0.9 * s) * ANG(-0.5, 0, 0.3), GOLD, M.Metal)
	P("HornR", BLOCK, V(0.12, 0.6, 0.12) * s, CF(0.3 * s, 0.6 * s, -0.9 * s) * ANG(-0.5, 0, -0.3), GOLD, M.Metal)
	P("WingL", BLOCK, V(1.6, 0.06, 0.9) * s, CF(-1 * s, 0.4 * s, -0.2 * s) * ANG(0, 0, 0.4), col:Lerp(C(255, 160, 60), 0.4), M.Neon).Transparency = 0.25
	P("WingR", BLOCK, V(1.6, 0.06, 0.9) * s, CF(1 * s, 0.4 * s, -0.2 * s) * ANG(0, 0, -0.4), col:Lerp(C(255, 160, 60), 0.4), M.Neon).Transparency = 0.25
	P("Flame", BALL, V(0.4, 0.4, 0.8) * s, CF(0, -0.1 * s, -2 * s), C(255, 160, 40), M.Neon).Transparency = 0.2
end

builders.eye = function(P, s, col)
	P("White", BALL, V(2, 2, 2) * s, CF(), WHITE, M.SmoothPlastic)
	P("Iris", CYL, V(0.12, 1.2, 1.2) * s, CF(0, 0, -0.96 * s) * ANG(0, math.rad(90), 0), col, M.Neon)
	P("Pupil", CYL, V(0.14, 0.55, 0.55) * s, CF(0, 0, -1 * s) * ANG(0, math.rad(90), 0), DARK, M.SmoothPlastic)
	P("Lid", BALL, V(2.1, 0.9, 2.1) * s, CF(0, 0.75 * s, 0), C(140, 40, 60), M.SmoothPlastic)
	for i = 0, 7 do
		local a = i * math.pi / 4
		P("Ray", BLOCK, V(0.15, 0.9, 0.15) * s, ANG(0, 0, a) * CF(0, 1.55 * s, 0), GOLD, M.Neon)
	end
end

builders.timering = function(P, s, col)
	for i = 0, 15 do
		local a = i * math.pi / 8
		P("Ring", BLOCK, V(0.5, 0.25, 0.25) * s, CF(math.cos(a) * 1.4 * s, math.sin(a) * 1.4 * s, 0) * ANG(0, 0, a + math.pi / 2), i % 4 == 0 and WHITE or col, M.Neon)
	end
	P("Clock", CYL, V(0.15, 1.6, 1.6) * s, ANG(0, math.rad(90), 0), C(30, 50, 60), M.Glass)
	P("HandH", BLOCK, V(0.1, 0.55, 0.06) * s, CF(0, 0.25 * s, -0.1 * s), WHITE, M.Neon)
	P("HandM", BLOCK, V(0.6, 0.08, 0.06) * s, CF(0.28 * s, 0, -0.1 * s), col, M.Neon)
	P("Sand", BALL, V(0.25, 0.25, 0.25) * s, CF(0, 0, -0.12 * s), GOLD, M.Neon)
end

-- 위성 하나를 만든다. 첫 파트가 PrimaryPart(가운데)
function SatBuilder.build(shape: string, color: Color3, size: number, gold: boolean?): Model
	local model = Instance.new("Model")
	model.Name = shape
	local first: Part? = nil
	local function P(name: string, kind: Enum.PartType?, sz: Vector3, cf: CFrame, col: Color3, mat: Enum.Material): Part
		local p = Instance.new("Part")
		p.Name = name
		-- 로블록스 공(Ball)은 늘 완전한 구라서, 납작하거나 길쭉한 공은 구 모양 메시로 늘린다
		local stretched = kind == BALL and (math.abs(sz.X - sz.Y) > 0.01 or math.abs(sz.Y - sz.Z) > 0.01)
		if stretched then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		elseif kind and kind ~= BLOCK then
			p.Shape = kind
		end
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = V(math.clamp(sz.X, 0.05, 2048), math.clamp(sz.Y, 0.05, 2048), math.clamp(sz.Z, 0.05, 2048))
		p.CFrame = cf
		if gold and mat ~= M.Neon and col ~= DARK then
			p.Color = col:Lerp(GOLD, 0.75)
			p.Material = M.Foil
			p.Reflectance = 0.25
		else
			p.Color = col
			p.Material = mat
		end
		p.Parent = model
		if not first then
			first = p
		end
		return p
	end
	local fn = builders[shape] or builders.rock
	fn(P, size, color)
	if gold and first then
		local sparkle = Instance.new("Sparkles")
		sparkle.SparkleColor = GOLD
		sparkle.Parent = first
	end
	if first then
		model.PrimaryPart = first
	end
	return model
end

function SatBuilder.has(shape: string): boolean
	return builders[shape] ~= nil
end

return SatBuilder
