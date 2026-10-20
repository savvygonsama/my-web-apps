-- 권왕: 탈것 (화면마다 직접 그린다). 몸에 "Mount" 표시가 붙은 사람 아래에 말·범·구름·청룡을 빚는다
-- 1.0판: 둥근 타원 조각으로 빚은 몸, 뼈마다 붙은 조각, 땅을 딛는 걸음 (두 마디 다리를 발끝까지 맞춰 굽힌다),
-- 걸음새 (평보 → 습보, 범은 튀어 오르듯), 늦게 따라오는 꼬리와 갈기, 돌 때 기우는 몸, 고삐와 등자,
-- 용은 지나온 길을 몸이 그대로 따라 흐르고, 구름은 뒤로 흩어진다
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Mount = {}

local folder = Instance.new("Folder")
folder.Name = "KwonMounts"
folder.Parent = workspace

-- 조각: bone = 붙은 뼈, off = 뼈 기준 자리, alpha = 투명도, w = 흔들림 { 축(1·2·3), 크기, 빠르기, 어긋남, 달릴 때 더하는 크기 },
-- bob = 위아래 둥실 { 크기, 빠르기, 어긋남 }
type Piece = { p: BasePart, bone: string, off: CFrame, alpha: number, w: { number }?, bob: { number }? }
type Leg = { n: string, x: number, hy: number, hz: number, a: number, b: number, front: boolean }
type Rig = {
	kind: string,
	m: any,
	model: Model,
	k: number,
	Q: any,
	parts: { Piece },
	bones: { [string]: CFrame },
	phase: number,
	move: number,
	run: number,
	yaw: number?,
	yawRate: number,
	bank: number,
	born: number,
	shown: boolean,
	hist: { Vector3 },
	trail: { Piece },
	reins: { BasePart },
	straps: { BasePart },
	irons: { BasePart },
	skip: number,
	lastU: { [string]: number },
}

local rigs: { [Model]: Rig } = {}

local RAD = math.pi / 180
local TAU = math.pi * 2
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local DARK = Color3.fromRGB(26, 20, 18)
local WHITE = Color3.new(1, 1, 1)

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end
local function smooth(x: number): number
	return x * x * (3 - 2 * x)
end

------------------------------------------------------------------------
-- 조각 빚기
------------------------------------------------------------------------
-- shape: "ell" 타원 (부드러운 몸) / "ball" 공 / "cyl" 원통 / "block" 네모
local function add(rig: Rig, bone: string, shape: string, size: Vector3, off: CFrame, color: Color3, material: Enum.Material?, alpha: number?): Piece
	local k = rig.k
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = size * k
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CastShadow = size.Magnitude > 1.8
	p.Transparency = 1
	if shape == "ell" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	elseif shape == "ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Parent = folder
	local e: Piece = { p = p, bone = bone, off = CF(off.Position * k) * off.Rotation, alpha = alpha or 0 }
	table.insert(rig.parts, e)
	return e
end
-- 흔들리는 조각 (갈기·꼬리털·수염)
local function wave(e: Piece, axis: number, amp: number, freq: number, ph: number, runAmp: number?): Piece
	e.w = { axis, amp, freq, ph, runAmp or 0 }
	return e
end
-- 두 점 사이를 잇는 끈
local function span(p: BasePart, a: Vector3, b: Vector3, thick: number)
	local d = b - a
	local len = d.Magnitude
	if len < 0.02 then
		return
	end
	p.Size = V(thick, thick, len)
	p.CFrame = CFrame.lookAt(a + d / 2, b)
end
-- 반짝이·안개 뿌리개
local function emitter(parent: Instance, texture: string, color: Color3, size: number, rate: number, life: number, speed: number, spread: number): ParticleEmitter
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = texture
	pe.Color = ColorSequence.new(color)
	pe.LightEmission = 0.8
	pe.Size = NumberSequence.new(size, 0)
	pe.Transparency = NumberSequence.new(0.2, 1)
	pe.Lifetime = NumberRange.new(life * 0.7, life)
	pe.Rate = rate
	pe.Speed = NumberRange.new(speed * 0.5, speed)
	pe.SpreadAngle = Vector2.new(spread, spread)
	pe.Parent = parent
	return pe
end
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

------------------------------------------------------------------------
-- 다리: 엉덩이에서 발목까지 두 마디를 굽혀 맞춘다 (옆에서 본 평면 안에서)
-- 반환: 윗마디·아랫마디 뼈 (뼈의 -Y가 마디 방향), 발목 자리
------------------------------------------------------------------------
local function ik(H: Vector3, T: Vector3, a: number, b: number, kneeFwd: boolean): (CFrame, CFrame, Vector3)
	local dy, dz = T.Y - H.Y, T.Z - H.Z
	local d = math.clamp(math.sqrt(dy * dy + dz * dz), 0.05, (a + b) * 0.995)
	local base = math.atan2(dz, -dy)
	local cosA = math.clamp((a * a + d * d - b * b) / (2 * a * d), -1, 1)
	local alpha = math.acos(cosA)
	local th1 = kneeFwd and (base - alpha) or (base + alpha)
	local K = V(H.X, H.Y - a * math.cos(th1), H.Z + a * math.sin(th1))
	local F = V(H.X, H.Y - d * math.cos(base), H.Z + d * math.sin(base))
	local th2 = math.atan2(F.Z - K.Z, -(F.Y - K.Y))
	return CF(H) * ANG(-th1, 0, 0), CF(K) * ANG(-th2, 0, 0), F
end

-- 다리 조각 (윗마디·아랫마디·발)
local function buildLeg(rig: Rig, L: Leg, coat: Color3, footColor: Color3, paw: boolean)
	local a, b = L.a, L.b
	if paw then
		add(rig, L.n .. "u", "ell", V(1.0, a + 0.6, 1.15), CF(0, -a / 2 + 0.15, 0), coat)
		add(rig, L.n .. "l", "ell", V(0.72, b + 0.35, 0.78), CF(0, -b / 2, 0), coat)
		add(rig, L.n .. "p", "ball", V(0.82, 0.82, 0.82), CF(0, -0.3, -0.1), footColor)
		for _, x in ipairs({ -0.22, 0, 0.22 }) do
			add(rig, L.n .. "p", "ell", V(0.27, 0.22, 0.32), CF(x, -0.42, -0.45), footColor)
		end
	else
		if L.front then
			add(rig, L.n .. "u", "ell", V(0.88, a + 0.65, 1.02), CF(0, -a / 2 + 0.12, 0), coat)
		else
			add(rig, L.n .. "u", "ell", V(1.0, a + 0.75, 1.3), CF(0, -a / 2 + 0.15, 0.05), coat)
		end
		add(rig, L.n .. "u", "ball", V(0.62, 0.62, 0.62), CF(0, -a, 0), coat)
		add(rig, L.n .. "l", "ell", V(0.46, b + 0.25, 0.55), CF(0, -b / 2, 0), coat)
		add(rig, L.n .. "l", "ball", V(0.56, 0.56, 0.56), CF(0, -b, 0), coat)
		add(rig, L.n .. "p", "ell", V(0.4, 0.55, 0.42), CF(0, -0.22, 0), coat)
		add(rig, L.n .. "p", "block", V(0.6, 0.3, 0.68), CF(0, -0.48, -0.05), footColor)
	end
end

------------------------------------------------------------------------
-- 말
------------------------------------------------------------------------
local HORSE = {
	B = 6.15, -- 등(안장) 높이
	footH = 0.62,
	legs = {
		{ n = "LF", x = -0.72, hy = -2.9, hz = -2.25, a = 1.6, b = 1.5, front = true },
		{ n = "RF", x = 0.72, hy = -2.9, hz = -2.25, a = 1.6, b = 1.5, front = true },
		{ n = "LH", x = -0.78, hy = -2.6, hz = 2.4, a = 1.7, b = 1.6, front = false },
		{ n = "RH", x = 0.78, hy = -2.6, hz = 2.4, a = 1.7, b = 1.6, front = false },
	},
	-- 평보 (네 박자)와 습보 (뒷다리 둘 → 앞다리 둘)
	walkOff = { LH = 0, LF = 0.25, RH = 0.5, RF = 0.75 },
	runOff = { LH = 0, RH = 0.1, LF = 0.42, RF = 0.54 },
	dutyWalk = 0.62,
	dutyRun = 0.36,
	liftWalk = 0.5,
	liftRun = 1.15,
	maxTravel = 3.8,
	bobRun = 0.24,
	pitchRun = 5 * RAD,
	flexRun = 0,
	rear = 20 * RAD, -- 처음 부르면 앞발을 들고 일어선다
	curlFront = 1.35,
	curlHind = 1.0,
	stand = -0.42,
}

local function buildHorse(rig: Rig)
	local m = rig.m
	local c, mane = m.color, m.mane
	local light = c:Lerp(WHITE, 0.12)
	local dark = c:Lerp(DARK, 0.5)
	local hoof = Color3.fromRGB(44, 36, 32)
	local leather = Color3.fromRGB(76, 44, 26)
	local fancy = m.id == "blackhorse"
	local metal = fancy and Color3.fromRGB(225, 185, 95) or Color3.fromRGB(205, 205, 210)
	local cloth = fancy and Color3.fromRGB(150, 22, 30) or Color3.fromRGB(42, 72, 125)
	local trim = fancy and Color3.fromRGB(230, 190, 90) or Color3.fromRGB(220, 200, 150)
	-- 몸통: 배·가슴·엉덩이·어깨·허벅지를 겹쳐 둥글게
	add(rig, "body", "ell", V(2.7, 3.0, 5.4), CF(0, -1.6, 0.1), c)
	add(rig, "body", "ell", V(2.55, 3.05, 2.6), CF(0, -1.65, -2.2), c)
	add(rig, "body", "ell", V(2.75, 2.9, 2.9), CF(0, -1.4, 2.35), c)
	add(rig, "body", "ell", V(1.3, 1.6, 2.2), CF(0, -0.8, -1.85), c)
	add(rig, "body", "ell", V(2.2, 1.3, 4.4), CF(0, -2.55, 0.1), light)
	add(rig, "body", "ell", V(1.8, 2.0, 1.2), CF(0, -2.3, -3.15), c)
	for _, s in ipairs({ -1, 1 }) do
		add(rig, "body", "ell", V(0.95, 2.3, 1.7), CF(s * 0.92, -2.25, -2.15) * ANG(0, 0, -s * 0.08), c)
		add(rig, "body", "ell", V(1.05, 2.5, 2.3), CF(s * 0.95, -1.95, 2.4), c)
	end
	-- 안장: 깔개와 테두리, 가죽 안장, 앞뒤 턱, 옆 덮개, 뱃대끈, 가슴걸이
	add(rig, "body", "block", V(2.5, 0.12, 2.65), CF(0, -0.14, 0.05), cloth, Enum.Material.Fabric)
	add(rig, "body", "block", V(2.6, 0.07, 2.75), CF(0, -0.21, 0.05), trim, Enum.Material.Fabric)
	add(rig, "body", "ell", V(1.75, 0.5, 2.2), CF(0, 0.0, 0.05), leather)
	add(rig, "body", "ell", V(0.95, 0.72, 0.5), CF(0, 0.25, -0.92), leather)
	add(rig, "body", "ell", V(1.35, 0.62, 0.42), CF(0, 0.28, 0.97), leather)
	add(rig, "body", "ball", V(0.22, 0.22, 0.22), CF(0, 0.6, -0.98), metal, Enum.Material.Metal)
	for _, s in ipairs({ -1, 1 }) do
		add(rig, "body", "block", V(0.08, 1.15, 1.35), CF(s * 1.3, -0.68, -0.05) * ANG(0, 0, s * 0.12), leather)
		add(rig, "body", "block", V(0.1, 2.3, 0.32), CF(s * 1.33, -1.75, -0.75), leather)
	end
	add(rig, "body", "block", V(2.1, 0.12, 0.32), CF(0, -3.17, -0.75), leather)
	add(rig, "body", "block", V(2.0, 0.14, 0.14), CF(0, -2.05, -3.58) * ANG(0, 0, 0), leather)
	add(rig, "body", "ball", V(0.38, 0.38, 0.38), CF(0, -2.12, -3.72), metal, Enum.Material.Metal)
	-- 다리
	for _, L in ipairs(HORSE.legs) do
		buildLeg(rig, L, c, hoof, false)
	end
	-- 목 (세 마디): 굵게 시작해 머리 쪽으로 가늘어진다
	-- 갈기: 목덜미를 따라 이어지는 볏 한 줄과, 오른쪽 목에 붙어 흘러내리는 매끈한 털 한 장씩 (마디마다 하나, 같은 물결로 함께 흔들린다)
	local neckSize = { V(1.15, 2.1, 1.6), V(1.0, 1.75, 1.5), V(0.9, 1.4, 1.4) }
	local neckY = { -0.45, -0.35, -0.25 }
	for i = 1, 3 do
		local ns = neckSize[i]
		add(rig, "n" .. i, "ell", ns, CF(0, neckY[i], -0.47), c)
		local top = neckY[i] + ns.Y / 2
		add(rig, "n" .. i, "ell", V(0.26, 0.34, 1.12), CF(0, top - 0.04, -0.47), mane)
		local dy = 0.55
		local hw = ns.X / 2 * math.sqrt(math.max(0.05, 1 - (dy / (ns.Y / 2)) ^ 2))
		local drape = add(rig, "n" .. i, "ell", V(0.12, 1.2 - i * 0.08, 1.12), CF(hw - 0.03, top - dy - 0.1, -0.47) * ANG(0, 0, 0.32), mane)
		wave(drape, 3, 0.025, 6, -i * 0.8, 0.09)
	end
	-- 머리 (뼈는 정수리, -Z가 코끝)
	add(rig, "head", "ell", V(0.95, 1.05, 1.3), CF(0, -0.15, -0.35), c)
	add(rig, "head", "ell", V(0.92, 1.15, 1.05), CF(0, -0.45, -0.2), c)
	add(rig, "head", "ell", V(0.72, 0.8, 2.0), CF(0, -0.2, -1.2), c)
	add(rig, "head", "ell", V(0.78, 0.78, 0.8), CF(0, -0.28, -2.05), dark)
	add(rig, "head", "block", V(0.55, 0.05, 0.4), CF(0, -0.62, -2.0), DARK)
	if m.id == "horse" then
		add(rig, "head", "ell", V(0.24, 0.06, 1.6), CF(0, 0.21, -1.15), Color3.fromRGB(245, 240, 232))
	end
	for _, s in ipairs({ -1, 1 }) do
		add(rig, "head", "ball", V(0.17, 0.17, 0.17), CF(s * 0.24, -0.12, -2.38), DARK)
		add(rig, "head", "ball", V(0.25, 0.25, 0.25), CF(s * 0.45, 0.05, -0.55), DARK)
		add(rig, "head", "ball", V(0.08, 0.08, 0.08), CF(s * 0.54, 0.12, -0.62), WHITE)
		-- 굴레: 볼끈, 코끈 옆, 재갈 고리
		add(rig, "head", "block", V(0.07, 0.09, 1.4), CF(s * 0.43, -0.05, -0.95), leather)
		add(rig, "head", "block", V(0.07, 0.7, 0.14), CF(s * 0.4, -0.13, -1.6), leather)
		add(rig, "head", "cyl", V(0.07, 0.28, 0.28), CF(s * 0.43, -0.5, -1.95), metal, Enum.Material.Metal)
	end
	add(rig, "head", "block", V(0.98, 0.09, 0.12), CF(0, 0.25, -0.3), leather)
	add(rig, "head", "block", V(0.86, 0.09, 0.14), CF(0, 0.22, -1.6), leather)
	wave(add(rig, "head", "ell", V(0.32, 0.65, 0.2), CF(0, 0.42, -0.28) * ANG(-0.6, 0, 0), mane), 3, 0.06, 5, 0, 0.12)
	for _, ear in ipairs({ "earL", "earR" }) do
		add(rig, ear, "ell", V(0.22, 0.66, 0.3), CF(0, 0.3, 0), c)
		add(rig, ear, "ell", V(0.12, 0.46, 0.12), CF(0, 0.3, -0.1), dark)
	end
	-- 꼬리 (여섯 마디): 첫 마디는 털빛, 나머지는 갈기 빛 털
	add(rig, "t1", "ell", V(0.5, 0.85, 0.55), CF(0, -0.3, 0), c)
	for i = 2, 6 do
		add(rig, "t" .. i, "ell", V(0.58 - 0.04 * i, 1.0, 0.42), CF(0, -0.3, 0), mane)
		add(rig, "t" .. i, "ell", V(0.36, 0.85, 0.5), CF(0.07, -0.36, 0.06), mane:Lerp(DARK, 0.2))
	end
	-- 고삐 둘과 등자 (탄 사람의 손과 발에 맞춰 매 화면 잇는다)
	for _ = 1, 2 do
		local r = add(rig, "_dyn", "block", V(0.07, 0.07, 1), CF(), leather)
		table.insert(rig.reins, r.p)
		local st = add(rig, "_dyn", "block", V(0.08, 0.08, 1), CF(), leather)
		table.insert(rig.straps, st.p)
		local iron = add(rig, "_dyn", "block", V(0.55, 0.09, 0.38), CF(), metal, Enum.Material.Metal)
		table.insert(rig.irons, iron.p)
	end
end

------------------------------------------------------------------------
-- 백호
------------------------------------------------------------------------
local TIGER = {
	B = 5.35,
	footH = 0.7,
	legs = {
		{ n = "LF", x = -0.75, hy = -2.3, hz = -1.6, a = 1.45, b = 1.4, front = true },
		{ n = "RF", x = 0.75, hy = -2.3, hz = -1.6, a = 1.45, b = 1.4, front = true },
		{ n = "LH", x = -0.75, hy = -2.15, hz = 1.75, a = 1.55, b = 1.45, front = false },
		{ n = "RH", x = 0.75, hy = -2.15, hz = 1.75, a = 1.55, b = 1.45, front = false },
	},
	walkOff = { LH = 0, LF = 0.25, RH = 0.5, RF = 0.75 },
	-- 달릴 때: 앞발 둘, 뒷발 둘이 거의 함께 (튀어 오르듯)
	runOff = { LH = 0, RH = 0.07, LF = 0.5, RF = 0.57 },
	dutyWalk = 0.6,
	dutyRun = 0.3,
	liftWalk = 0.45,
	liftRun = 1.0,
	maxTravel = 4.2,
	bobRun = 0.3,
	pitchRun = 4 * RAD,
	flexRun = 11 * RAD, -- 허리가 접혔다 펴진다
	curlFront = 1.0,
	curlHind = 0.9,
	stand = -0.05,
}

local function band(rig: Rig, bone: string, center: Vector3, size: Vector3, z: number, thick: number, color: Color3, tilt: number)
	local f = 1 - ((z - center.Z) / (size.Z / 2)) ^ 2
	if f <= 0.05 then
		return
	end
	local r = math.sqrt(f) * 1.03
	add(rig, bone, "ell", V(size.X * r, size.Y * r, thick), CF(center.X, center.Y, z) * ANG(tilt, 0, 0), color)
end

local function buildTiger(rig: Rig)
	local m = rig.m
	local c, stripe = m.color, m.mane
	local white = c:Lerp(WHITE, 0.6)
	local cloth = Color3.fromRGB(40, 60, 140)
	local gold = Color3.fromRGB(230, 190, 90)
	-- 몸: 앞(가슴·어깨)과 뒤(엉덩이·허벅지)로 나뉘어 허리가 접힌다
	local chestC, chestS = V(0, -1.35, -1.25), V(2.2, 2.3, 2.9)
	local rumpC, rumpS = V(0, -1.3, 1.3), V(2.1, 2.1, 2.9)
	add(rig, "front", "ell", chestS, CF(chestC), c)
	add(rig, "rear", "ell", rumpS, CF(rumpC), c)
	for _, s in ipairs({ -1, 1 }) do
		add(rig, "front", "ell", V(0.9, 1.8, 1.4), CF(s * 0.85, -1.55, -1.75), c)
		add(rig, "rear", "ell", V(0.95, 1.9, 1.6), CF(s * 0.85, -1.45, 1.75), c)
	end
	add(rig, "body", "ell", V(1.7, 1.0, 3.6), CF(0, -2.25, 0), white)
	add(rig, "front", "ell", V(1.5, 1.4, 1.0), CF(0, -2.0, -2.45), white)
	-- 줄무늬: 몸을 감는 검은 띠 (굵기와 기울기를 조금씩 다르게)
	for i, dz in ipairs({ -0.95, -0.35, 0.25, 0.85 }) do
		band(rig, "front", chestC, chestS, chestC.Z + dz, i % 2 == 0 and 0.14 or 0.2, stripe, (i % 2 == 0 and 1 or -1) * 0.18)
		band(rig, "rear", rumpC, rumpS, rumpC.Z + dz, i % 2 == 0 and 0.2 or 0.14, stripe, (i % 2 == 0 and -1 or 1) * 0.18)
	end
	-- 목
	add(rig, "front", "ell", V(1.65, 1.8, 1.6), CF(0, -1.05, -2.75), c)
	band(rig, "front", V(0, -1.05, -2.75), V(1.65, 1.8, 1.6), -2.65, 0.16, stripe, 0.2)
	-- 안장 대신 금빛 술이 달린 두툼한 천
	add(rig, "body", "block", V(2.0, 0.12, 2.2), CF(0, -0.12, 0), cloth, Enum.Material.Fabric)
	add(rig, "body", "block", V(2.1, 0.06, 2.3), CF(0, -0.18, 0), gold, Enum.Material.Fabric)
	add(rig, "body", "ell", V(1.5, 0.45, 1.8), CF(0, 0.04, 0), Color3.fromRGB(140, 30, 35))
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			wave(add(rig, "body", "ell", V(0.15, 0.5, 0.15), CF(x * 1.0, -0.45, z * 1.05), gold, Enum.Material.Metal), 1, 0.08, 5, x + z, 0.2)
		end
	end
	-- 다리: 굵고 둥근 발, 허벅지의 줄무늬
	for _, L in ipairs(TIGER.legs) do
		buildLeg(rig, L, c, white, true)
		local a = L.a
		for _, frac in ipairs({ 0.35, 0.68 }) do
			local cy = -a / 2 + 0.15
			local h = (a + 0.6) / 2
			local y = -a * frac
			local f = 1 - ((y - cy) / h) ^ 2
			if f > 0.05 then
				local r = math.sqrt(f) * 1.04
				add(rig, L.n .. "u", "ell", V(1.0 * r, 0.13, 1.15 * r), CF(0, y, 0), stripe)
			end
		end
	end
	-- 머리 (-Z가 앞): 콧등이 곧게 내려와 넓적한 주둥이로, 눈꼬리가 올라간 매서운 눈과 찌푸린 눈썹, 드러난 송곳니
	add(rig, "head", "ell", V(1.75, 1.5, 1.55), CF(0, 0, 0), c)
	add(rig, "head", "ell", V(0.55, 0.42, 1.0), CF(0, 0.08, -0.62), c)
	add(rig, "head", "ell", V(0.1, 0.08, 0.75), CF(0, 0.73, -0.1), stripe)
	for _, s in ipairs({ -1, 1 }) do
		add(rig, "head", "ell", V(0.09, 0.07, 0.55), CF(s * 0.3, 0.67, -0.18) * ANG(0, -s * 0.35, 0), stripe)
		add(rig, "head", "ell", V(0.08, 0.06, 0.4), CF(s * 0.52, 0.58, -0.05) * ANG(0, -s * 0.5, s * 0.3), stripe)
	end
	add(rig, "head", "ell", V(0.4, 0.22, 0.26), CF(0, -0.06, -1.12), Color3.fromRGB(130, 70, 78))
	add(rig, "head", "ell", V(0.62, 0.34, 0.55), CF(0, -0.66, -0.62), white)
	add(rig, "head", "ell", V(0.62, 0.14, 0.45), CF(0, -0.55, -0.88), DARK)
	for _, s in ipairs({ -1, 1 }) do
		-- 주둥이의 두 볼록한 수염 자리, 송곳니, 수염
		add(rig, "head", "ell", V(0.6, 0.52, 0.62), CF(s * 0.25, -0.32, -0.85), white)
		add(rig, "head", "ell", V(0.09, 0.28, 0.09), CF(s * 0.2, -0.6, -1.02), WHITE)
		for j = 0, 2 do
			add(rig, "head", "block", V(0.03, 0.03, 0.95), CF(s * 0.88, -0.36 + j * 0.07, -0.85) * ANG(j * 0.1 - 0.1, s * 1.3, 0), WHITE)
		end
		-- 볼의 흰 털과 줄무늬 (뒤로 뻗는다)
		add(rig, "head", "ell", V(0.55, 0.85, 0.8), CF(s * 0.78, -0.32, 0.05) * ANG(0, 0, s * 0.25), white)
		add(rig, "head", "ell", V(0.07, 0.32, 0.45), CF(s * 1.04, -0.25, 0.05) * ANG(0, 0, s * 0.3), stripe)
		add(rig, "head", "ell", V(0.07, 0.26, 0.4), CF(s * 1.0, -0.55, 0.08) * ANG(0, 0, s * 0.15), stripe)
		-- 눈: 짙은 눈두덩 위에 빛나는 얼음빛 눈동자, 세로로 가는 동공. 눈꼬리는 바깥으로 올라가고 눈썹은 안쪽으로 내려온다
		local eye = CF(s * 0.42, 0.2, -0.68) * ANG(0, s * 0.35, s * 0.3)
		add(rig, "head", "ell", V(0.46, 0.22, 0.12), eye, stripe)
		add(rig, "head", "ell", V(0.3, 0.15, 0.08), eye * CF(0, 0, -0.05), Color3.fromRGB(140, 220, 255), Enum.Material.Neon)
		add(rig, "head", "ell", V(0.05, 0.14, 0.05), eye * CF(0, 0, -0.09), DARK)
		add(rig, "head", "ell", V(0.48, 0.09, 0.12), CF(s * 0.42, 0.36, -0.66) * ANG(0, s * 0.35, s * 0.45), stripe)
	end
	for _, ear in ipairs({ "earL", "earR" }) do
		add(rig, ear, "ell", V(0.5, 0.5, 0.2), CF(0, 0.2, 0), c)
		add(rig, ear, "ell", V(0.28, 0.3, 0.08), CF(0, 0.2, -0.08), WHITE)
		add(rig, ear, "ell", V(0.44, 0.44, 0.06), CF(0, 0.2, 0.09), stripe)
		add(rig, ear, "ell", V(0.16, 0.16, 0.04), CF(0, 0.22, 0.12), WHITE)
	end
	-- 꼬리 (아홉 마디): 뒤로 뻗었다가 끝이 위로 말린다. 마디마다 검은 고리
	for i = 1, 9 do
		local w = 0.42 - 0.02 * i
		add(rig, "t" .. i, "ell", V(w, 0.65, w), CF(0, -0.25, 0), i == 9 and stripe or c)
		if i % 2 == 1 and i < 9 then
			add(rig, "t" .. i, "ell", V(w * 1.05, 0.12, w * 1.05), CF(0, -0.42, 0), stripe)
		end
	end
	for _ = 1, 2 do
		local r = add(rig, "_dyn", "block", V(0.07, 0.07, 1), CF(), gold, Enum.Material.Metal)
		table.insert(rig.reins, r.p)
	end
end

------------------------------------------------------------------------
-- 네발짐승의 움직임 (말·범 공통)
------------------------------------------------------------------------
local function updateQuad(rig: Rig, yawCF: CFrame, groundLocal: number, t: number, speed: number, freq: number)
	local Q = rig.Q
	local k = rig.k
	local bones = rig.bones
	local m, run, A = rig.move, rig.run, rig.phase * TAU
	-- 몸: 걸을 땐 작게 두 번, 달릴 땐 크게 한 번 들썩이며 앞뒤로 흔들린다. 서 있으면 숨을 쉰다
	local bob = math.sin(A * 2) * 0.05 * k * m * (1 - run) + math.sin(A) * Q.bobRun * k * run + math.sin(t * 1.6) * 0.035 * k * (1 - m)
	local pitch = math.sin(A + 1.2) * Q.pitchRun * run + math.sin(A * 2) * 0.012 * m * (1 - run)
	local rear = 0
	if Q.rear then
		local u = (t - rig.born) / 1.1
		if u < 1 then
			rear = math.sin(math.pi * u) ^ 1.5
		end
	end
	pitch += rear * (Q.rear or 0)
	local bodyLocal = CF(0, bob, 0) * ANG(pitch, 0, rig.bank)
	local flex = math.sin(A + 0.6) * Q.flexRun * run
	local frontLocal = bodyLocal * ANG(flex, 0, 0)
	local rearLocal = bodyLocal * ANG(-flex, 0, 0)
	bones.body = yawCF * bodyLocal
	bones.front = yawCF * frontLocal
	bones.rear = yawCF * rearLocal
	-- 다리: 땅에 닿아 있는 동안 발은 제자리 (몸이 지나간다), 떨어진 동안 앞으로 들어 옮긴다
	local cam = workspace.CurrentCamera
	local dustNear = cam ~= nil and (cam.CFrame.Position - yawCF.Position).Magnitude < 120
	local duty = lerp(Q.dutyWalk, Q.dutyRun, run)
	local travel = math.min(speed * duty / freq, Q.maxTravel * k)
	local lift = lerp(Q.liftWalk, Q.liftRun, run) * k
	for _, L in ipairs(Q.legs) do
		local half = L.front and frontLocal or rearLocal
		local hip = half * V(L.x * k, L.hy * k, L.hz * k)
		local rest = L.hz * k
		local off = lerp(Q.walkOff[L.n], Q.runOff[L.n], run)
		local u = (rig.phase + off) % 1
		-- 달릴 때 발이 땅을 박차는 순간 흙먼지
		local prevU = rig.lastU[L.n]
		rig.lastU[L.n] = u
		if prevU and u < prevU and run > 0.35 and dustNear then
			Fx.burst("smoke", yawCF * V(hip.X, groundLocal + 0.3, rest + travel * 0.5), Color3.fromRGB(205, 190, 165), 2, 0.55 * k)
		end
		local z, y, curl
		if u < duty then
			z = rest + travel * (u / duty - 0.5)
			y = 0
			curl = 0
		else
			local s = (u - duty) / (1 - duty)
			z = rest + travel * (0.5 - smooth(s))
			y = lift * math.sin(math.pi * s) * (L.front and 1.15 or 1)
			curl = math.sin(math.pi * s)
		end
		z = rest + (z - rest) * m
		y *= m
		curl *= m
		if L.front and rear > 0 then
			y += rear * 1.9 * k
			z -= rear * 0.9 * k
			curl = math.max(curl, rear)
		end
		local T = V(hip.X, groundLocal + Q.footH * k + y, z)
		local upper, lower, F = ik(hip, T, L.a * k, L.b * k, L.front)
		local pa = lerp(Q.stand, L.front and Q.curlFront or Q.curlHind, curl)
		bones[L.n .. "u"] = yawCF * upper
		bones[L.n .. "l"] = yawCF * lower
		bones[L.n .. "p"] = yawCF * CF(F) * ANG(-pa, 0, 0)
	end
	-- 귀: 가끔 쫑긋
	local twL = math.max(0, math.sin(t * 0.7)) ^ 14 * 0.6
	local twR = math.max(0, math.sin(t * 0.83 + 2)) ^ 14 * 0.6
	local look = math.sin(t * 0.37) * 0.14 * (1 - m) + math.clamp(rig.yawRate * 0.08, -0.3, 0.3)
	if rig.kind == "horse" then
		-- 목과 머리: 걸음에 맞춰 끄덕이고, 달리면 목을 앞으로 뻗는다. 도는 쪽을 먼저 본다
		local nod = math.sin(A * 2 + 0.5) * 0.05 * m * (1 - run) + math.sin(A + 2.2) * 0.12 * run
		local e = lerp(52, 34, run) * RAD + rear * 0.5 + nod * 0.5
		local cf = bones.front * CF(0, -1.05 * k, -2.95 * k) * ANG(e, look * 0.5, 0)
		for i = 1, 3 do
			bones["n" .. i] = cf
			cf = cf * CF(0, 0, -0.95 * k) * ANG(-9 * RAD, look * 0.25, 0)
		end
		local head = cf * ANG(-78 * RAD + nod - rear * 0.3, look * 0.3, 0)
		bones.head = head
		bones.earL = head * CF(-0.3 * k, 0.5 * k, -0.1 * k) * ANG(-0.25 - twL, 0, 0.3)
		bones.earR = head * CF(0.3 * k, 0.5 * k, -0.1 * k) * ANG(-0.25 - twR, 0, -0.3)
		-- 꼬리: 서 있으면 느리게 휘휘, 달리면 뒤로 흩날린다
		local th = lerp(28, 70, run) * RAD - rear * 0.2
		local tc = bones.rear * CF(0, -0.2 * k, 3.7 * k) * ANG(-th, 0, 0)
		for i = 1, 6 do
			bones["t" .. i] = tc
			local sway = math.sin(t * 2.1 - i * 0.7) * 7 * RAD * (0.4 + i * 0.25) * (1 - run * 0.5) + math.sin(t * 11 - i * 0.9) * 5 * RAD * run
			tc = tc * CF(0, -0.6 * k, 0) * ANG(lerp(9, 2, run) * RAD, 0, sway)
		end
	else
		-- 범: 고개를 낮게 들고, 달리면 더 숙인다
		local nod = math.sin(A * 2) * 0.04 * m * (1 - run) + math.sin(A + 1.8) * 0.08 * run
		local head = bones.front * CF(0, -0.85 * k, -3.35 * k) * ANG(-0.12 + nod - run * 0.15, look, 0)
		bones.head = head
		bones.earL = head * CF(-0.6 * k, 0.62 * k, 0.25 * k) * ANG(-twL, 0, 0.35)
		bones.earR = head * CF(0.6 * k, 0.62 * k, 0.25 * k) * ANG(-twR, 0, -0.35)
		-- 꼬리: 뒤로 뻗었다가 끝이 위로 말리고, 물결치듯 흔들린다
		local tc = bones.rear * CF(0, -0.75 * k, 2.75 * k) * ANG(-lerp(100, 92, run) * RAD, 0, 0)
		for i = 1, 9 do
			bones["t" .. i] = tc
			local bend = (i <= 4 and 10 or -16) * RAD * (1 - run * 0.5)
			local sway = math.sin(t * 1.8 - i * 0.6) * 9 * RAD * (0.5 + i * 0.15) + math.sin(t * 9 - i) * 4 * RAD * run
			tc = tc * CF(0, -0.5 * k, 0) * ANG(bend, 0, sway)
		end
	end
end

------------------------------------------------------------------------
-- 날개구름: 탄 사람은 구름 위에 선다. 뭉치마다 따로 둥실거리고, 뒤로 작은 구름이 흩어진다
------------------------------------------------------------------------
local CLOUD = { B = 6.05 }
local function buildCloud(rig: Rig)
	local m = rig.m
	local spots = {
		{ 0, -1.2, 0, 3.0 }, { 1.3, -1.1, -0.9, 2.2 }, { -1.3, -1.1, -0.9, 2.2 }, { 1.4, -1.15, 1.0, 2.3 }, { -1.4, -1.15, 1.0, 2.3 },
		{ 0, -1.05, -1.9, 2.1 }, { 0, -1.1, 1.9, 2.2 }, { 0.8, -0.55, 0.3, 1.5 }, { -0.8, -0.55, 0.3, 1.5 }, { 0, -1.8, 0, 2.4 },
		{ 2.2, -1.3, 0, 1.6 }, { -2.2, -1.3, 0, 1.6 },
	}
	for i, sp in ipairs(spots) do
		local col = m.color:Lerp(Color3.fromRGB(225, 230, 245), (i % 3) * 0.08)
		local e = add(rig, "body", "ball", V(sp[4], sp[4], sp[4]), CF(sp[1], sp[2], sp[3]), col)
		e.bob = { 0.12, 1.4 + (i % 4) * 0.35, i * 1.3 }
		-- 바깥의 옅은 솜털 (부드러운 가장자리)
		local o = add(rig, "body", "ball", V(sp[4], sp[4], sp[4]) * 1.22, CF(sp[1], sp[2] - 0.05, sp[3]), col:Lerp(m.mane, 0.08), nil, 0.6)
		o.bob = { 0.15, 1.1 + (i % 3) * 0.3, i * 0.7 }
	end
	local glow = add(rig, "body", "cyl", V(0.25, 5.2, 5.2), CF(0, -2.75, 0) * ANG(0, 0, math.rad(90)), m.mane, Enum.Material.Neon, 0.5).p
	local light = Instance.new("PointLight")
	light.Color = m.mane
	light.Range = 16
	light.Brightness = 1.6
	light.Parent = glow
	emitter(glow, TEX_SPARK, m.mane, 0.4, 20, 1.0, 2, 60)
	local mist = emitter(glow, TEX_SMOKE, WHITE, 2.2, 6, 1.4, 1, 40)
	mist.Transparency = NumberSequence.new(0.6, 1)
	mist.LightEmission = 0.2
	-- 뒤로 흩어지는 꼬리 구름
	for i = 1, 6 do
		local sz = 2.0 - i * 0.24
		local e = add(rig, "_trail", "ball", V(sz, sz, sz), CF(), m.color, nil, 0.1 + i * 0.12)
		table.insert(rig.trail, e)
	end
end

------------------------------------------------------------------------
-- 청룡: 열여덟 마디. 머리가 지나간 길을 몸이 그대로 따라 흐른다
------------------------------------------------------------------------
local DRAGON = { B = 4.8, N = 22, gap = 1.05, legs = { 5, 14 } } -- B가 작을수록 크게 (몸 굵기·길이·머리 모두)
local function segW(i: number): number
	if i < 3 then
		return 1.7 + 0.15 * i
	end
	return 2.0 - 1.45 * ((i - 3) / (DRAGON.N - 4))
end
local function buildDragon(rig: Rig)
	local m = rig.m
	local c, gold = m.color, m.mane
	local belly = Color3.fromRGB(240, 225, 170)
	local darkC = c:Lerp(DARK, 0.35)
	for i = 0, DRAGON.N - 1 do
		local w = segW(i)
		local b = "s" .. i
		add(rig, b, "ell", V(w, w * 0.92, 1.8), CF(), c)
		add(rig, b, "ell", V(w * 0.72, w * 0.42, 1.55), CF(0, -w * 0.32, 0), belly)
		-- 등지느러미 (금빛)와 옆구리의 짙은 비늘 줄
		wave(add(rig, b, "ell", V(0.12, w * 0.62, 0.8), CF(0, w * 0.5, 0.15) * ANG(-0.45, 0, 0), gold, Enum.Material.Metal), 3, 0.06, 4, i * 0.6, 0.1)
		if i % 2 == 0 then
			for _, s in ipairs({ -1, 1 }) do
				add(rig, b, "ell", V(0.1, w * 0.3, 1.2), CF(s * w * 0.46, w * 0.05, 0), darkC)
			end
		end
	end
	-- 꼬리 끝 금빛 지느러미 (부채꼴)
	for j = -1, 1 do
		wave(add(rig, "s" .. (DRAGON.N - 1), "ell", V(0.1, 1.5, 0.9), CF(0, 0, 0.9) * ANG(0.5 + j * 0.5, 0, 0), gold, Enum.Material.Metal), 3, 0.15, 3, j, 0.15)
	end
	-- 다리 넷
	for _, si in ipairs(DRAGON.legs) do
		local ls = segW(si) / 2
		for _, side in ipairs({ "L", "R" }) do
			local u = "d" .. si .. side .. "u"
			local l = "d" .. si .. side .. "l"
			add(rig, u, "ell", V(0.5, 1.25, 0.5) * ls, CF(0, -0.55 * ls, 0), c)
			add(rig, l, "ell", V(0.38, 0.95, 0.38) * ls, CF(0, -0.42 * ls, 0), c)
			for _, x in ipairs({ -0.14, 0, 0.14 }) do
				add(rig, l, "ell", V(0.12, 0.12, 0.42) * ls, CF(x * ls, -0.9 * ls, -0.12 * ls) * ANG(-0.5, 0, 0), gold, Enum.Material.Metal)
			end
		end
	end
	-- 머리 (-Z가 앞)
	add(rig, "head", "ell", V(1.55, 1.2, 1.7), CF(0, 0.1, 0), c)
	add(rig, "head", "ell", V(1.1, 0.78, 2.0), CF(0, -0.05, -1.45), c)
	add(rig, "head", "ell", V(0.9, 0.55, 0.6), CF(0, 0.12, -2.35), c)
	for _, s in ipairs({ -1, 1 }) do
		add(rig, "head", "ell", V(0.45, 0.3, 0.9), CF(s * 0.42, 0.55, -0.25), darkC)
		add(rig, "head", "ball", V(0.18, 0.18, 0.18), CF(s * 0.28, 0.3, -2.55), DARK)
		add(rig, "head", "ell", V(0.32, 0.2, 0.18), CF(s * 0.55, 0.35, -0.55), Color3.fromRGB(255, 235, 110), Enum.Material.Neon)
		add(rig, "head", "ell", V(0.06, 0.18, 0.1), CF(s * 0.64, 0.35, -0.58), DARK)
		add(rig, "head", "ell", V(0.12, 0.3, 0.12), CF(s * 0.36, -0.42, -2.0), WHITE)
		-- 뿔: 뒤로 휘어 오르는 금빛 가지 뿔
		add(rig, "head", "ell", V(0.24, 0.24, 1.5), CF(s * 0.42, 0.7, 0.6) * ANG(0.5, s * 0.25, 0), gold, Enum.Material.Metal)
		add(rig, "head", "ell", V(0.16, 0.16, 1.0), CF(s * 0.55, 1.15, 1.35) * ANG(0.9, s * 0.35, 0), gold, Enum.Material.Metal)
		add(rig, "head", "ell", V(0.12, 0.12, 0.6), CF(s * 0.62, 1.0, 0.9) * ANG(-0.2, s * 0.6, 0), gold, Enum.Material.Metal)
		-- 수염 (네 마디씩, 뒤로 흐른다)
		for j = 1, 4 do
			add(rig, "w" .. (s < 0 and "L" or "R") .. j, "ell", V(0.09, 0.09, 0.78), CF(0, 0, 0.35), gold, Enum.Material.Neon)
		end
	end
	for j = 0, 3 do
		wave(add(rig, "head", "ell", V(0.14, 0.85, 0.55), CF((j % 2 == 0 and 0.3 or -0.3), 0.55, 0.5 + j * 0.35) * ANG(-0.6, 0, (j % 2 == 0 and 0.3 or -0.3)), gold), 3, 0.08, 4, j, 0.2)
	end
	-- 아래턱 (숨 쉬듯 조금 벌어진다), 이빨, 금빛 턱수염
	add(rig, "jaw", "ell", V(1.0, 0.34, 1.85), CF(0, -0.05, -1.0), belly)
	for _, s in ipairs({ -1, 1 }) do
		add(rig, "jaw", "ell", V(0.11, 0.22, 0.11), CF(s * 0.32, 0.16, -1.55), WHITE)
		add(rig, "jaw", "ell", V(0.11, 0.2, 0.11), CF(s * 0.34, 0.15, -1.05), WHITE)
		wave(add(rig, "jaw", "ell", V(0.3, 0.75, 0.25), CF(s * 0.15, -0.4, -0.55) * ANG(0.3, 0, 0), gold), 3, 0.08, 3, s, 0.15)
	end
	-- 머리 앞에서 떠도는 여의주
	local pearl = add(rig, "pearl", "ball", V(0.9, 0.9, 0.9), CF(), Color3.fromRGB(255, 245, 210), Enum.Material.Neon).p
	local pl = Instance.new("PointLight")
	pl.Color = gold
	pl.Range = 14
	pl.Brightness = 1.8
	pl.Parent = pearl
	emitter(pearl, TEX_SPARK, gold, 0.35, 16, 0.9, 1.5, 180)
	local glowHolder = add(rig, "head", "ball", V(0.1, 0.1, 0.1), CF(0, 0.2, -0.4), gold, Enum.Material.Neon, 1).p
	emitter(glowHolder, TEX_SPARK, gold, 0.4, 22, 1.3, 1.2, 180)
	-- 몸 아래로 흩어지는 구름 (하늘을 나는 용)
	for _, si in ipairs({ 6, 12, 18 }) do
		local holder = add(rig, "s" .. si, "ball", V(0.1, 0.1, 0.1), CF(0, -segW(si) * 0.4, 0), WHITE, nil, 1).p
		local mist = emitter(holder, TEX_SMOKE, Color3.fromRGB(240, 245, 255), 3.2, 7, 1.8, 0.6, 50)
		mist.Transparency = NumberSequence.new(0.55, 1)
		mist.LightEmission = 0.15
	end
end

-- 지나온 길 (머리 쪽이 1번). 너무 멀리 뛰면 (순간이동) 새로 시작한다
local function pushHist(rig: Rig, p: Vector3, maxLen: number)
	local h = rig.hist
	if #h == 0 or (p - h[1]).Magnitude > 40 then
		table.clear(h)
		table.insert(h, p)
		return
	end
	if (p - h[1]).Magnitude > 0.3 then
		table.insert(h, 1, p)
	else
		h[1] = p
	end
	local total = 0
	for i = 2, #h do
		total += (h[i] - h[i - 1]).Magnitude
		if total > maxLen then
			for _ = #h, i + 1, -1 do
				table.remove(h)
			end
			break
		end
	end
end
-- 길 위에서 머리부터 일정한 간격의 자리들 (길이 모자라면 뒤로 곧게 늘인다)
local function samplePath(h: { Vector3 }, back: Vector3, gap: number, n: number, start: number): { Vector3 }
	local out = {}
	local idx, acc = 1, 0
	for i = 0, n - 1 do
		local want = start + i * gap
		while idx < #h and acc + (h[idx + 1] - h[idx]).Magnitude < want do
			acc += (h[idx + 1] - h[idx]).Magnitude
			idx += 1
		end
		if idx < #h then
			local seg = h[idx + 1] - h[idx]
			local L = seg.Magnitude
			out[i + 1] = h[idx] + seg * (L > 1e-4 and math.clamp((want - acc) / L, 0, 1) or 0)
		else
			local dir = #h >= 2 and (h[#h] - h[#h - 1]) or back
			if dir.Magnitude < 1e-4 then
				dir = back
			end
			out[i + 1] = h[#h] + dir.Unit * (want - acc)
		end
	end
	return out
end

------------------------------------------------------------------------
-- 만들기·지우기
------------------------------------------------------------------------
local function poof(model: Model, color: Color3)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local cam = workspace.CurrentCamera
		if cam and (cam.CFrame.Position - root.Position).Magnitude > 200 then
			return
		end
		Fx.burst("smoke", root.Position - V(0, 2, 0), Color3.fromRGB(235, 230, 220), 10, 1.4)
		Fx.burst("glitter", root.Position, color, 10, 1)
	end
end

local function build(model: Model, id: string)
	local m = Config.MOUNT_BY_ID[id]
	if not m then
		return
	end
	local Q = m.kind == "tiger" and TIGER or m.kind == "cloud" and CLOUD or m.kind == "dragon" and DRAGON or HORSE
	-- 크기: 탄 사람이 들린 높이에 맞춘다 (서버의 Config.MOUNT_HIP)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local hip = Config.MOUNT_HIP[m.kind] or 3
	local back = hip + 1.85
	if hum and hum.HipHeight > hip + 0.5 then
		back = hum.HipHeight - 0.15
	end
	local rig: Rig = {
		kind = m.kind,
		m = m,
		model = model,
		k = math.clamp(back / Q.B, 0.75, 1.8),
		Q = Q,
		parts = {},
		bones = {},
		phase = 0,
		move = 0,
		run = 0,
		yaw = nil,
		yawRate = 0,
		bank = 0,
		born = os.clock(),
		shown = false,
		hist = {},
		trail = {},
		reins = {},
		straps = {},
		irons = {},
		skip = 0,
		lastU = {},
	}
	if m.kind == "cloud" then
		buildCloud(rig)
	elseif m.kind == "dragon" then
		buildDragon(rig)
	elseif m.kind == "tiger" then
		buildTiger(rig)
	else
		buildHorse(rig)
	end
	rigs[model] = rig
	poof(model, m.mane)
end

local function clear(model: Model, fx: boolean?)
	local rig = rigs[model]
	if rig then
		for _, e in ipairs(rig.parts) do
			e.p:Destroy()
		end
		rigs[model] = nil
		if fx then
			poof(model, rig.m.mane)
		end
	end
end

function Mount.watch(model: Model)
	local function refresh()
		local had = rigs[model] ~= nil
		clear(model, had)
		local id = model:GetAttribute("Mount")
		if type(id) == "string" then
			build(model, id)
		end
	end
	model:GetAttributeChangedSignal("Mount"):Connect(refresh)
	model.AncestryChanged:Connect(function()
		if not model.Parent then
			clear(model)
		end
	end)
	refresh()
end

------------------------------------------------------------------------
-- 매 화면
------------------------------------------------------------------------
local function update(rig: Rig, root: BasePart, hum: Humanoid, dt: number, t: number)
	local k = rig.k
	local bones = rig.bones
	local vel = root.AssemblyLinearVelocity
	local speed = V(vel.X, 0, vel.Z).Magnitude
	local look = root.CFrame.LookVector
	local flat = V(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		flat = V(0, 0, -1)
	end
	flat = flat.Unit
	-- 방향은 살짝 늦게 따라오고, 도는 만큼 안쪽으로 기운다
	local yawT = math.atan2(-flat.X, -flat.Z)
	if not rig.yaw then
		rig.yaw = yawT
	end
	local yaw = rig.yaw :: number
	local d = (yawT - yaw + math.pi) % TAU - math.pi
	yaw += d * math.min(1, dt * 9)
	rig.yaw = yaw
	rig.yawRate += (d * 9 - rig.yawRate) * math.min(1, dt * 6)
	rig.move += ((speed > 1.2 and 1 or 0) - rig.move) * math.min(1, dt * 5)
	rig.run += (math.clamp((speed - 9) / 12, 0, 1) - rig.run) * math.min(1, dt * 3)
	rig.bank += (math.clamp(rig.yawRate * 0.07, -0.3, 0.3) * (0.25 + 0.75 * rig.move) - rig.bank) * math.min(1, dt * 6)
	local freq = (0.75 + speed * 0.062) / math.sqrt(k) -- 큰 짐승일수록 보폭이 길고 걸음이 느긋하다
	rig.phase = (rig.phase + dt * freq) % 1
	local pos = root.Position
	local rootBottom = pos.Y - root.Size.Y / 2
	local seatY = rootBottom - 0.3
	local groundY = rootBottom - hum.HipHeight
	local turn = ANG(0, yaw, 0)

	if rig.kind == "horse" or rig.kind == "tiger" then
		local yawCF = CF(pos.X, seatY, pos.Z) * turn
		updateQuad(rig, yawCF, groundY - seatY, t, speed, freq)
	elseif rig.kind == "cloud" then
		local baseHip = math.max(0.5, hum.HipHeight - (Config.MOUNT_HIP.cloud or 2.6))
		local feetY = rootBottom - baseHip
		local body = CF(pos.X, feetY + 0.15, pos.Z) * turn * CF(0, math.sin(t * 1.9) * 0.1 * k, 0) * ANG(-7 * RAD * rig.move, 0, rig.bank * 1.4)
		bones.body = body
		pushHist(rig, body.Position, 14 * k)
		local pts = samplePath(rig.hist, -flat, 1.3 * k, #rig.trail, 2.4 * k)
		for i, e in ipairs(rig.trail) do
			local p = pts[i] + V(math.sin(t * 2 + i) * 0.25, -1.2 * k + math.sin(t * 1.5 + i * 0.8) * 0.2, 0)
			e.p.CFrame = CF(p)
		end
	else
		-- 청룡: 머리는 탄 사람 앞, 몸은 지나온 길을 따라 흐르며 옆과 위아래로 물결친다
		local N, gap = DRAGON.N, DRAGON.gap * k
		local anchor = V(pos.X, seatY - 0.95 * k, pos.Z) + flat * 2.2 * k + V(0, math.sin(t * 1.5) * 0.12 * k, 0)
		pushHist(rig, anchor, N * gap + 6)
		local pts = samplePath(rig.hist, -flat, gap, N, 0)
		local up = V(0, 1, 0)
		for i = 0, N - 1 do
			local w = i / (N - 1)
			local here = pts[i + 1]
			local ahead = i == 0 and (here + flat) or pts[i]
			local tan = ahead - here
			if tan.Magnitude < 1e-3 then
				tan = flat
			end
			local right = tan.Unit:Cross(up)
			if right.Magnitude < 1e-3 then
				right = V(1, 0, 0)
			end
			local calm = i <= 2 and 0 or 1
			-- 탄 사람 아래의 앞 마디는 곧게 (돌 때 몸이 사람에게서 비껴 나지 않게)
			local rigid = math.clamp((4 - i) / 2, 0, 1)
			if rigid > 0 then
				local line = V(anchor.X, here.Y, anchor.Z) - flat * i * gap
				here = here:Lerp(line, rigid)
			end
			local lat = math.sin(t * 2.4 - i * 0.5) * k * math.max(0, i - 2) / (N - 3) * (0.6 + 0.6 * rig.move) * 1.1
			local vert = math.sin(t * 1.7 - i * 0.42) * k * (0.15 + 0.55 * w) * (1 - 0.4 * rig.move) * calm
			pts[i + 1] = here + right.Unit * lat * calm + up * vert
		end
		for i = 0, N - 1 do
			local here = pts[i + 1]
			local ahead = i == 0 and (here + flat * gap) or pts[i]
			if (ahead - here).Magnitude < 1e-3 then
				ahead = here + flat
			end
			bones["s" .. i] = CFrame.lookAt(here, ahead)
		end
		-- 다리: 헤엄치듯 천천히 젓는다
		for _, si in ipairs(DRAGON.legs) do
			local seg = bones["s" .. si]
			local w = segW(si)
			local ls = w / 2
			for _, side in ipairs({ -1, 1 }) do
				local paddle = math.sin(t * (2 + 3 * rig.move) + side + si) * 0.5
				local u = seg * CF(side * 0.5 * w * k, -0.35 * w * k, 0) * ANG(paddle, 0, side * 0.7)
				local name = "d" .. si .. (side < 0 and "L" or "R")
				bones[name .. "u"] = u
				bones[name .. "l"] = u * CF(0, -1.1 * ls * k, 0) * ANG(-0.9 - paddle * 0.4, 0, 0)
			end
		end
		local nod = math.sin(t * 1.3) * 0.08
		local look2 = math.clamp(rig.yawRate * 0.12, -0.4, 0.4)
		local head = CF(pts[1] + flat * 1.0 * k + V(0, 0.35 * k, 0)) * turn * ANG(nod, look2, 0)
		bones.head = head
		bones.jaw = head * CF(0, -0.38 * k, -0.3 * k) * ANG(-(0.08 + 0.06 * math.sin(t * 1.3)), 0, 0)
		bones.pearl = head * CF(math.sin(t * 1.1) * 0.4 * k, 0.3 * k + math.sin(t * 2) * 0.25 * k, -4.0 * k)
		for _, s in ipairs({ -1, 1 }) do
			local cf = head * CF(s * 0.5 * k, -0.05 * k, -2.2 * k) * ANG(0, s * 0.9, 0)
			local tag = s < 0 and "L" or "R"
			for j = 1, 4 do
				bones["w" .. tag .. j] = cf
				cf = cf * CF(0, 0, 0.7 * k) * ANG(math.sin(t * 3 - j) * 0.25, s * 0.12, 0)
			end
		end
	end

	-- 조각을 뼈에 붙인다
	local run = rig.run
	for _, e in ipairs(rig.parts) do
		local b = bones[e.bone]
		if b then
			local cf = b
			local bob = e.bob
			if bob then
				cf = cf * CF(0, math.sin(t * bob[2] + bob[3]) * bob[1] * k, 0)
			end
			cf = cf * e.off
			local w = e.w
			if w then
				local a = math.sin(t * w[3] + w[4]) * (w[2] + w[5] * run)
				if w[1] == 1 then
					cf = cf * ANG(a, 0, 0)
				elseif w[1] == 2 then
					cf = cf * ANG(0, a, 0)
				else
					cf = cf * ANG(0, 0, a)
				end
			end
			e.p.CFrame = cf
		end
	end

	-- 고삐 (재갈 → 손), 등자 (안장 옆 → 발)
	local model = rig.model
	if #rig.reins > 0 and bones.head then
		local bitOff = rig.kind == "horse" and V(0.45, -0.5, -1.95) or V(0.55, -0.45, -0.75)
		for i, side in ipairs({ -1, 1 }) do
			local hand = model:FindFirstChild(side < 0 and "LeftHand" or "RightHand")
			local rein = rig.reins[i]
			if hand and hand:IsA("BasePart") and rein then
				local bit = bones.head * V(bitOff.X * side * k, bitOff.Y * k, bitOff.Z * k)
				span(rein, bit, hand.Position, 0.07 * k)
			end
		end
	end
	if #rig.straps > 0 and bones.body then
		for i, side in ipairs({ -1, 1 }) do
			local foot = model:FindFirstChild(side < 0 and "LeftFoot" or "RightFoot")
			local strap, iron = rig.straps[i], rig.irons[i]
			if foot and foot:IsA("BasePart") and strap and iron then
				local top = bones.body * V(side * 1.2 * k, -0.25 * k, -0.15 * k)
				local fp = foot.Position - V(0, foot.Size.Y / 2 + 0.05, 0)
				span(strap, top, fp, 0.08 * k)
				iron.CFrame = CF(fp) * turn
			end
		end
	end

	-- 나타날 때 0.3초에 걸쳐 짙어진다
	if not rig.shown then
		local prog = math.clamp((t - rig.born) / 0.3, 0, 1)
		for _, e in ipairs(rig.parts) do
			e.p.Transparency = lerp(1, e.alpha, prog)
		end
		if prog >= 1 then
			rig.shown = true
		end
	end
end

local warned = false
RunService.RenderStepped:Connect(function(dt: number)
	local t = os.clock()
	local cam = workspace.CurrentCamera
	for model, rig in pairs(rigs) do
		local root = model:FindFirstChild("HumanoidRootPart")
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not hum or not model.Parent then
			clear(model)
			continue
		end
		-- 멀리 있는 탈것은 세 화면에 한 번만
		if cam and (cam.CFrame.Position - root.Position).Magnitude > 260 then
			rig.skip += 1
			if rig.skip % 3 ~= 0 then
				continue
			end
		end
		local ok, err = pcall(update, rig, root, hum, dt, t)
		if not ok then
			if not warned then
				warned = true
				warn("[권왕] 탈것 오류:", err)
			end
			clear(model)
		end
	end
end)

return Mount
