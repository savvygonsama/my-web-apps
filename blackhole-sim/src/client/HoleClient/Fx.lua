-- Fx (ModuleScript, HoleClient 아래)
-- 블랙홀 모양, 빨려 들어가는 연출, 떠오르는 숫자, 효과음.
-- 블랙홀은 서버가 캐릭터에 붙인 크기(HoleR), 스킨(HoleSkin), 위성(Sats)을 보고 각자 화면에서 그린다.
--   검은 구멍 → 어두운 원반 → 빛나는 테두리 → 소용돌이 팔 세 개 → 도는 강착 원반 → 안으로 빨려 드는 빛 알갱이
--   스킨 효과: 불꽃, 얼음 조각, 은하 별빛, 사탕 가루, 황금 반짝임, 신의 눈, 무지개
--   위성은 블랙홀 둘레를 돌며 둥실거린다. 다시 생긴 물체는 뿅 하고 커지며 나타난다.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local SatBuilder = require(ReplicatedStorage:WaitForChild("SatBuilder"))

local Fx = {}

local FLAT = CFrame.Angles(0, 0, math.rad(90))
local BLACK = Color3.new(0, 0, 0)

local folder = Instance.new("Folder")
folder.Name = "HoleFX"
folder.Parent = workspace

-- 미리보기(스킨 창, 스킨 전시관)를 만들 때는 잠깐 다른 곳에 붙인다
local buildParent: Instance? = nil

local function fxPart(size: Vector3, color: Color3, material: Enum.Material, shape: Enum.PartType?, transparency: number?): Part
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material
	p.Transparency = transparency or 0
	p.Parent = buildParent or folder
	return p
end

-- 납작한 원판: 구 메시를 납작하게 늘려서, 파트 한계(2048)보다 큰 블랙홀도 그릴 수 있다
local DISC_MAX = 2000

local function setDisc(p: BasePart, d: number)
	local s = math.clamp(d, 0.05, DISC_MAX)
	p.Size = Vector3.new(s, p.Size.Y, s)
	local mesh = p:FindFirstChild("DiscMesh")
	if mesh and mesh:IsA("SpecialMesh") then
		mesh.Scale = Vector3.new(math.max(d, 0.05) / s, 1, math.max(d, 0.05) / s)
	end
end

local function disc(d: number, thick: number, color: Color3, material: Enum.Material, transparency: number?): Part
	local p = fxPart(Vector3.new(1, thick, 1), color, material, nil, transparency)
	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "DiscMesh"
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	setDisc(p, d)
	return p
end

------------------------------------------------------------------------
-- 효과음
------------------------------------------------------------------------
local SOUNDS = {
	pop = "rbxasset://sounds/electronicpingshort.wav",
	whoosh = "rbxasset://sounds/swordlunge.wav",
	slash = "rbxasset://sounds/swordslash.wav",
}

function Fx.sound(name: string, volume: number?, pitch: number?)
	local id = SOUNDS[name]
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.4
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 3)
end

------------------------------------------------------------------------
-- 블랙홀 모양
------------------------------------------------------------------------
type Hole = {
	char: Model?,
	center: Vector3?, -- 미리보기는 정해진 자리에 있다
	active: boolean,
	radius: number, -- 지금 보이는 반지름 (target 쪽으로 부드럽게 따라간다)
	target: number,
	buildR: number, -- 파트를 만들 때의 반지름
	lastK: number,
	baseD: { number }, -- 원판 4장의 처음 지름
	pulse: number, -- 삼킬 때 잠깐 부푸는 정도
	skillOn: boolean,
	aura: Part,
	skin: number,
	parts: { Part },
	rim: Part,
	disk: Part,
	void: Part,
	core: Part,
	arms: { { part: Part, t: number, arm: number } },
	ring: { { part: Part, a: number, h: number } },
	motes: { { part: Part, phase: number } },
	light: PointLight,
	effect: string?,
	extras: { { part: Part, kind: string, a: number, k: number } },
	sats: { { model: Model, a: number, size: number } },
	satKey: string,
}

local holes: { [Model]: Hole } = {}

local function destroyHole(h: Hole)
	for _, p in ipairs(h.parts) do
		p:Destroy()
	end
	for _, sat in ipairs(h.sats) do
		sat.model:Destroy()
	end
end

-- 스킨 효과용 파티클 (블랙홀 위로 뿜어 올린다)
local function emitter(add: (Part) -> Part, r: number, props: { [string]: any }): ParticleEmitter
	local d = r * 2
	local box = add(fxPart(Vector3.new(d * 0.9, 0.2, d * 0.9), BLACK, Enum.Material.SmoothPlastic, nil, 1))
	box.Name = "Emitter"
	local pe = Instance.new("ParticleEmitter")
	pe.LightEmission = 1
	pe.Drag = 1
	for k, v in pairs(props) do
		(pe :: any)[k] = v
	end
	pe.Parent = box
	return pe
end

local function seq(a: number, b: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

-- 위성 모델들 (Sats 속성: "id:금,id:금")
local function buildSats(h: Hole, attr: string)
	for _, sat in ipairs(h.sats) do
		sat.model:Destroy()
	end
	h.sats = {}
	h.satKey = attr
	local list = string.split(attr, ",")
	local size = math.clamp(h.buildR * 0.16, 0.45, 40)
	for i, entry in ipairs(list) do
		local id, g = string.match(entry, "^([%w_]+):(%d)$")
		local def = id and Config.SAT_BY_ID[id]
		if def then
			local m = SatBuilder.build(def.shape, def.color, size, g == "1")
			m.Parent = folder
			table.insert(h.sats, { model = m, a = (i - 1) / #list * math.pi * 2, size = size })
		end
	end
end

local function buildHole(char: Model?, r: number, skinIndex: number, lite: boolean?): Hole
	local skin = Config.Skins[skinIndex] or Config.Skins[1]
	local effect = skin.effect
	local parts: { Part } = {}
	local function add(p: Part): Part
		table.insert(parts, p)
		return p
	end
	local d = r * 2
	local rim = add(disc(d * 1.14, 0.12, skin.a, Enum.Material.Neon, 0.15))
	local disk = add(disc(d * 1.05, 0.14, skin.a:Lerp(BLACK, 0.82), Enum.Material.SmoothPlastic))
	local void = add(disc(d * 0.9, 0.16, BLACK, Enum.Material.SmoothPlastic))
	local core = add(disc(d * 0.45, 0.18, BLACK, Enum.Material.Neon))
	-- 스킬을 쓰는 동안 바깥에 퍼지는 빛
	local aura = add(disc(d * 1.6, 0.1, skin.b, Enum.Material.Neon, 1))
	local light = Instance.new("PointLight")
	light.Color = skin.a
	light.Range = math.min(60, 6 + r * 1.5)
	light.Brightness = 1.5
	light.Parent = rim

	-- 소용돌이 팔: 테두리에서 가운데로 휘어 들어간다
	local arms = {}
	local segs = lite and 6 or 9
	for arm = 0, 2 do
		for i = 0, segs - 1 do
			local t = i / (segs - 1)
			local color = skin.a:Lerp(skin.b, t)
			local width = math.max(0.15, r * 0.09 * (1 - t * 0.6))
			local p = add(fxPart(Vector3.new(width, 0.08, math.max(0.3, r * 0.28 * (1 - t * 0.5))), color, Enum.Material.Neon, nil, 0.1 + t * 0.6))
			table.insert(arms, { part = p, t = t, arm = arm })
		end
	end
	-- 강착 원반: 테두리 위를 빠르게 도는 빛 덩어리
	local ring = {}
	local n = lite and 12 or 18
	for i = 0, n - 1 do
		local size = math.max(0.25, r * 0.08)
		local col = (i % 2 == 0) and skin.a or skin.b
		if effect == "candy" and i % 2 == 1 then
			col = Color3.new(1, 1, 1)
		end
		local p = add(fxPart(Vector3.new(size * 1.8, size * 0.6, size), col, Enum.Material.Neon, nil, 0.05))
		table.insert(ring, { part = p, a = i / n * math.pi * 2, h = (i % 3) * 0.12 })
	end
	-- 빨려 드는 빛 알갱이
	local motes = {}
	local moteCount = lite and 6 or 12
	for i = 0, moteCount - 1 do
		local p = add(fxPart(Vector3.new(1, 1, 1) * math.max(0.15, r * 0.05), skin.b, Enum.Material.Neon, Enum.PartType.Ball))
		table.insert(motes, { part = p, phase = i / moteCount })
	end

	-- 스킨 효과
	local extras = {}
	local small = math.max(0.2, r * 0.07)
	if effect == "fire" then
		emitter(add, r, {
			Rate = 40,
			Lifetime = NumberRange.new(0.5, 1),
			Speed = NumberRange.new(2 + r * 0.6, 4 + r * 1.2),
			Size = seq(math.max(0.4, r * 0.25), 0),
			Color = ColorSequence.new(Color3.fromRGB(255, 230, 90), Color3.fromRGB(255, 60, 20)),
			Transparency = seq(0.1, 1),
			RotSpeed = NumberRange.new(-90, 90),
		})
		for i = 0, 7 do
			local p = add(fxPart(Vector3.new(small, small * 4, small), skin.b, Enum.Material.Neon, nil, 0.2))
			table.insert(extras, { part = p, kind = "flame", a = i / 8 * math.pi * 2, k = i })
		end
	elseif effect == "ice" then
		emitter(add, r, {
			Rate = 18,
			Lifetime = NumberRange.new(1.2, 2),
			Speed = NumberRange.new(0.5, 2 + r * 0.2),
			Size = seq(math.max(0.15, r * 0.06), 0),
			Color = ColorSequence.new(Color3.new(1, 1, 1), skin.a),
		})
		for i = 0, 9 do
			local p = add(fxPart(Vector3.new(small * 1.3, small * 5, small * 1.3), skin.a:Lerp(Color3.new(1, 1, 1), (i % 2) * 0.5), Enum.Material.Ice, nil, 0.1))
			table.insert(extras, { part = p, kind = "shard", a = i / 10 * math.pi * 2, k = i })
		end
	elseif effect == "galaxy" then
		emitter(add, r, {
			Rate = 30,
			Lifetime = NumberRange.new(1.5, 2.5),
			Speed = NumberRange.new(0.2, 1 + r * 0.1),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, math.max(0.15, r * 0.05)), NumberSequenceKeypoint.new(1, 0) }),
			Color = ColorSequence.new(Color3.new(1, 1, 1), skin.a),
		})
		local halo = add(disc(d * 1.5, 0.1, skin.a, Enum.Material.Neon, 0.75))
		table.insert(extras, { part = halo, kind = "halo", a = 0, k = 0 })
		for i = 0, 11 do
			local p = add(fxPart(Vector3.new(1, 1, 1) * small * 0.8, i % 3 == 0 and skin.b or Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball))
			table.insert(extras, { part = p, kind = "orbitStar", a = i / 12 * math.pi * 2, k = i })
		end
	elseif effect == "candy" then
		for i = 0, 15 do
			local p = add(fxPart(Vector3.new(small * 2, small * 0.6, small * 0.6), Color3.fromHSV(i / 16, 0.55, 1), Enum.Material.SmoothPlastic))
			table.insert(extras, { part = p, kind = "sprinkle", a = i / 16 * math.pi * 2, k = i })
		end
	elseif effect == "gold" then
		emitter(add, r, {
			Rate = 14,
			Lifetime = NumberRange.new(0.6, 1.2),
			Speed = NumberRange.new(1, 2 + r * 0.3),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, math.max(0.25, r * 0.08)), NumberSequenceKeypoint.new(1, 0) }),
			Color = ColorSequence.new(Color3.fromRGB(255, 240, 160), Color3.fromRGB(255, 190, 40)),
		})
		for i = 0, 7 do
			local p = add(fxPart(Vector3.new(small * 1.4, small * 1.4, small * 1.4), Color3.fromRGB(255, 220, 90), Enum.Material.Neon))
			table.insert(extras, { part = p, kind = "glint", a = i / 8 * math.pi * 2, k = i })
		end
	elseif effect == "eye" then
		local iris = add(fxPart(Vector3.new(0.1, d * 0.5, d * 0.5), skin.a, Enum.Material.Neon, Enum.PartType.Cylinder))
		local pupil = add(fxPart(Vector3.new(0.12, d * 0.22, d * 0.22), BLACK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder))
		local shine = add(fxPart(Vector3.new(0.13, d * 0.07, d * 0.07), Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Cylinder))
		table.insert(extras, { part = iris, kind = "iris", a = 0, k = 0 })
		table.insert(extras, { part = pupil, kind = "pupil", a = 0, k = 0 })
		table.insert(extras, { part = shine, kind = "shine", a = 0, k = 0 })
		for i = 0, 9 do
			local p = add(fxPart(Vector3.new(small * 0.8, 0.1, r * 0.35), skin.b, Enum.Material.Neon, nil, 0.2))
			table.insert(extras, { part = p, kind = "ray", a = i / 10 * math.pi * 2, k = i })
		end
	end

	return {
		char = char,
		center = nil,
		active = true,
		radius = r,
		target = r,
		buildR = r,
		lastK = 1,
		baseD = { d * 1.14, d * 1.05, d * 0.9, d * 0.45, d * 1.6 },
		pulse = 0,
		skillOn = false,
		aura = aura,
		skin = skinIndex,
		parts = parts,
		rim = rim,
		disk = disk,
		void = void,
		core = core,
		arms = arms,
		ring = ring,
		motes = motes,
		light = light,
		effect = effect,
		extras = extras,
		sats = {},
		satKey = "",
	}
end

-- 블랙홀이 있는 바닥 자리 (모든 구역의 바닥 높이는 0)
function Fx.holeCenter(char: Model): Vector3?
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	return Vector3.new(root.Position.X, 0, root.Position.Z)
end

local function updateHole(h: Hole, t: number, dt: number)
	local center = h.center or (h.char and Fx.holeCenter(h.char))
	if not center then
		return
	end
	-- 먹어서 커질 때 부드럽게 커지고, 삼킬 때마다 잠깐 꿀꺽 부푼다
	h.radius += (h.target - h.radius) * math.min(1, dt * 6)
	h.pulse *= math.exp(-dt * 9)
	local scaleK = h.radius / h.buildR * (1 + h.pulse)
	if math.abs(scaleK - h.lastK) > 0.002 then
		h.lastK = scaleK
		for i, p in ipairs({ h.rim, h.disk, h.void, h.core, h.aura }) do
			setDisc(p, h.baseD[i] * scaleK)
		end
	end
	local r = h.radius
	local base = CFrame.new(center)
	h.rim.CFrame = base * CFrame.new(0, 0.04, 0)
	h.disk.CFrame = base * CFrame.new(0, 0.06, 0)
	h.void.CFrame = base * CFrame.new(0, 0.08, 0)
	h.core.CFrame = base * CFrame.new(0, 0.1, 0)
	h.aura.CFrame = base * CFrame.new(0, 0.02, 0)
	if h.skillOn then
		h.aura.Transparency = 0.45 + math.sin(t * 10) * 0.15
	elseif h.aura.Transparency < 1 then
		h.aura.Transparency = 1
	end
	if h.effect == "rainbow" then
		local c = Color3.fromHSV((t * 0.15) % 1, 0.8, 1)
		h.rim.Color = c
		h.light.Color = c
		for i, q in ipairs(h.ring) do
			q.part.Color = Color3.fromHSV((t * 0.15 + i / #h.ring) % 1, 0.7, 1)
		end
	elseif h.effect == "fire" then
		h.light.Brightness = 1.5 + math.sin(t * 17) * 0.4 + math.sin(t * 7) * 0.3
	end
	for _, e in ipairs(h.extras) do
		local p = e.part
		if e.kind == "flame" then
			local ang = e.a + t * 1.5
			local flick = 0.7 + math.abs(math.sin(t * 9 + e.k)) * 0.6
			p.CFrame = CFrame.new(center + Vector3.new(math.cos(ang) * r * 1.05, r * 0.15 * flick, math.sin(ang) * r * 1.05)) * CFrame.Angles(0, -ang, math.sin(t * 6 + e.k) * 0.3)
			p.Transparency = 0.1 + (1 - flick) * 0.5
		elseif e.kind == "shard" then
			local ang = e.a + t * 0.4
			p.CFrame = CFrame.new(center + Vector3.new(math.cos(ang) * r * 1.15, r * 0.12, math.sin(ang) * r * 1.15)) * CFrame.Angles(0, -ang, 0) * CFrame.Angles(0, 0, 0.5)
		elseif e.kind == "halo" then
			p.CFrame = base * CFrame.new(0, r * 0.15, 0) * CFrame.Angles(math.sin(t * 0.7) * 0.25, t * 0.3, 0)
		elseif e.kind == "orbitStar" then
			local ang = e.a - t * 0.8
			p.CFrame = CFrame.new(center + Vector3.new(math.cos(ang) * r * 1.45, r * 0.15 + math.sin(ang * 2 + t) * r * 0.08, math.sin(ang) * r * 1.45))
			p.Transparency = 0.2 + (math.sin(t * 5 + e.k * 1.7) + 1) * 0.3
		elseif e.kind == "sprinkle" then
			local ang = e.a + t * 1.2
			local rad = r * (1.25 + math.sin(t * 2 + e.k) * 0.08)
			p.CFrame = CFrame.new(center + Vector3.new(math.cos(ang) * rad, r * 0.1 + math.sin(t * 3 + e.k) * r * 0.06, math.sin(ang) * rad)) * CFrame.Angles(t * 3 + e.k, ang, 0)
		elseif e.kind == "glint" then
			local ang = e.a + t * 0.9
			p.CFrame = CFrame.new(center + Vector3.new(math.cos(ang) * r * 1.3, r * 0.25 + math.sin(t * 2 + e.k) * r * 0.1, math.sin(ang) * r * 1.3)) * CFrame.Angles(t * 2, t * 3, math.rad(45))
			p.Transparency = (math.sin(t * 6 + e.k * 2) + 1) * 0.4
		elseif e.kind == "iris" or e.kind == "pupil" or e.kind == "shine" then
			-- 눈동자가 움직이는 쪽을 바라본다
			local root = h.char and h.char:FindFirstChild("HumanoidRootPart")
			local vel = (root and root:IsA("BasePart")) and root.AssemblyLinearVelocity or Vector3.zero
			local look = Vector3.new(vel.X, 0, vel.Z)
			local off = look.Magnitude > 1 and look.Unit * r * 0.18 or Vector3.new(math.sin(t * 0.7), 0, math.cos(t * 0.5)) * r * 0.08
			local y = e.kind == "iris" and 0.13 or (e.kind == "pupil" and 0.15 or 0.17)
			local extra = e.kind == "iris" and off * 0.5 or (e.kind == "pupil" and off or off + Vector3.new(r * 0.06, 0, -r * 0.06))
			p.CFrame = CFrame.new(center + extra + Vector3.new(0, y, 0)) * FLAT
		elseif e.kind == "ray" then
			local ang = e.a + t * 0.25
			local len = 1 + math.sin(t * 3 + e.k) * 0.2
			local pos = center + Vector3.new(math.cos(ang) * r * 1.3, 0.1, math.sin(ang) * r * 1.3)
			p.CFrame = CFrame.lookAt(pos, pos + Vector3.new(math.cos(ang), 0, math.sin(ang)))
			p.Size = Vector3.new(p.Size.X, 0.1, r * 0.35 * len)
		end
	end
	for i, sat in ipairs(h.sats) do
		local ang = sat.a + t * (0.9 - math.min(0.5, r * 0.002))
		local rad = r * 1.3 + sat.size * 2.5 + 1
		local y = r * 0.25 + sat.size * 1.5 + math.sin(t * 2.2 + i * 1.3) * sat.size * 0.5
		local pos = center + Vector3.new(math.cos(ang) * rad, y, math.sin(ang) * rad)
		sat.model:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(-math.sin(ang), 0, math.cos(ang))) * CFrame.Angles(0, t * 1.5 + i, 0))
	end
	-- 테두리가 숨 쉬듯 빛난다
	h.rim.Transparency = 0.1 + (math.sin(t * 3) + 1) * 0.1
	local spin = t * 1.4
	for _, a in ipairs(h.arms) do
		local ang = spin + a.arm * (math.pi * 2 / 3) + a.t * 2.4
		local rad = r * (1.0 - a.t * 0.8)
		local pos = center + Vector3.new(math.cos(ang) * rad, 0.12, math.sin(ang) * rad)
		a.part.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(ang), 0, math.cos(ang)))
	end
	for _, q in ipairs(h.ring) do
		local ang = q.a + t * 2.6
		local rad = r * 1.08
		local pos = center + Vector3.new(math.cos(ang) * rad, 0.25 + q.h + math.sin(t * 4 + q.a * 3) * 0.08 * r, math.sin(ang) * rad)
		q.part.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(ang), 0, math.cos(ang)))
	end
	for _, m in ipairs(h.motes) do
		local k = (t * 0.6 + m.phase) % 1
		local ang = m.phase * 20 + k * 6
		local rad = r * 1.2 * (1 - k)
		m.part.CFrame = CFrame.new(center + Vector3.new(math.cos(ang) * rad, 0.3 + (1 - k) * r * 0.2, math.sin(ang) * rad))
		m.part.Transparency = k * 0.8
	end
end

-- 로비에서는 블랙홀을 작게 보여 준다 (광장을 다 덮지 않게)
local LOBBY_SHOW = 8
local function shownRadius(char: Model, r: number): number
	local c = Fx.holeCenter(char)
	if c and Config.inLobby(c) then
		return math.min(r, LOBBY_SHOW)
	end
	return r
end

local function syncHole(char: Model)
	local rawR = char:GetAttribute("HoleR")
	local skin = char:GetAttribute("HoleSkin")
	local h = holes[char]
	local r = type(rawR) == "number" and shownRadius(char, rawR) or nil
	if type(r) ~= "number" or not char.Parent then
		if h then
			destroyHole(h)
			holes[char] = nil
		end
		return
	end
	local skinIndex = type(skin) == "number" and skin or 1
	local sats = char:GetAttribute("Sats")
	local satKey = type(sats) == "string" and sats or ""
	if h and h.skin == skinIndex then
		-- 크기가 조금 바뀐 건 다시 만들지 않고 늘린다
		h.target = r
		local k = r / h.buildR
		if k < 1.15 and k > 0.87 then
			if h.satKey ~= satKey then
				buildSats(h, satKey)
			end
			return
		end
	end
	local shown = h and h.radius or r
	-- 로비 ↔ 세계처럼 크기가 확 바뀌면 바로 그 크기로
	if shown > r * 3 or shown < r / 3 then
		shown = r
	end
	if h then
		destroyHole(h)
	end
	local nh = buildHole(char, r, skinIndex)
	nh.radius = shown
	nh.skillOn = char:GetAttribute("SkillOn") == true
	holes[char] = nh
	buildSats(nh, satKey)
end

-- 삼킬 때 블랙홀이 꿀꺽 부푼다
function Fx.pulse(char: Model, amount: number)
	local h = holes[char]
	if h then
		h.pulse = math.max(h.pulse, amount)
	end
end

local function watchCharacter(char: Model)
	syncHole(char)
	char:GetAttributeChangedSignal("HoleR"):Connect(function()
		syncHole(char)
	end)
	char:GetAttributeChangedSignal("HoleSkin"):Connect(function()
		syncHole(char)
	end)
	char:GetAttributeChangedSignal("Sats"):Connect(function()
		syncHole(char)
	end)
	char:GetAttributeChangedSignal("SkillOn"):Connect(function()
		local h = holes[char]
		if h then
			h.skillOn = char:GetAttribute("SkillOn") == true
		end
	end)
	char.AncestryChanged:Connect(function()
		if not char.Parent then
			syncHole(char)
		end
	end)
end

local function watchPlayer(player: Player)
	if player.Character then
		watchCharacter(player.Character)
	end
	player.CharacterAdded:Connect(function(c)
		watchCharacter(c :: Model)
	end)
end

------------------------------------------------------------------------
-- 스킨 미리보기: 스킨 창(ViewportFrame)과 시작 지점 뒤 스킨 전시관
------------------------------------------------------------------------
local previews: { Hole } = {}

function Fx.preview(skinIndex: number, r: number, center: Vector3, parent: Instance): Hole
	buildParent = parent
	local ok, h = pcall(buildHole, nil, r, skinIndex, true)
	buildParent = nil
	if not ok then
		error(h)
	end
	h.center = center
	table.insert(previews, h)
	return h
end

function Fx.removePreview(h: Hole)
	destroyHole(h)
	local i = table.find(previews, h)
	if i then
		table.remove(previews, i)
	end
end

type GalleryItem = { hole: Hole, label: TextLabel, skin: any }
local gallery: { GalleryItem } = {}

local function buildGallery()
	local lobbyFolder = workspace:WaitForChild("Lobby", 60)
	if not lobbyFolder then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "SkinGallery"
	f.Parent = folder
	for _, ped in ipairs(lobbyFolder:GetChildren()) do
		local k = ped:GetAttribute("SkinIndex")
		local hr = ped:GetAttribute("HoleR")
		local skin = type(k) == "number" and Config.Skins[k]
		if ped:IsA("BasePart") and skin and type(hr) == "number" then
			-- 받침(세운 원기둥) 윗면 위에 그린다
			local center = ped.Position + Vector3.new(0, ped.Size.X / 2 + 0.05, 0)
			local h = Fx.preview(k, hr, center, f)
			h.active = false
			if hr < 10 then
				local anchor = fxPart(Vector3.new(0.2, 0.2, 0.2), skin.a, Enum.Material.Neon, nil, 1)
				anchor.CFrame = CFrame.new(center + Vector3.new(0, 10, 0))
				anchor.Parent = f
				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.new(0, 190, 0, 64)
				bb.LightInfluence = 0
				bb.MaxDistance = 220
				bb.Parent = anchor
				local l = Instance.new("TextLabel")
				l.Size = UDim2.fromScale(1, 1)
				l.BackgroundTransparency = 1
				l.Font = Enum.Font.GothamBlack
				l.TextScaled = true
				l.TextColor3 = skin.b
				l.TextStrokeTransparency = 0.2
				l.Text = skin.name
				l.Parent = bb
				table.insert(gallery, { hole = h, label = l, skin = skin })
			else
				table.insert(gallery, { hole = h, label = nil :: any, skin = skin })
			end
		end
	end
end

-- 전시관 이름표: 가진 스킨, 쓰는 스킨, 얻는 법
function Fx.updateGallery(owned: { string }, selected: string)
	for _, g in ipairs(gallery) do
		if not g.label then
			continue
		end
		local skin = g.skin
		local status
		if skin.id == selected then
			status = "✔ 사용 중"
		elseif table.find(owned, skin.id) then
			status = "열림"
		elseif skin.unlock == "bigbang" then
			status = string.format("🔒 빅뱅 %d번", skin.value)
		elseif skin.unlock == "dm" then
			status = string.format("🌑 %d", skin.value)
		elseif skin.unlock == "world2" then
			status = "🔒 사탕 태양"
		else
			status = "💎 " .. Config.PASS_BY_KEY[skin.value].name
		end
		local ab = skin.ability
		g.label.Text = skin.name .. "\n" .. status .. (ab and ("\n" .. (ab.kind == "active" and "⚡ " or "✦ ") .. ab.name) or "")
	end
end

------------------------------------------------------------------------
-- 빨려 들어가는 연출: 모든 화면에서, 누가 삼켰든 그 블랙홀로 소용돌이치며 들어간다
------------------------------------------------------------------------
type Sucked = { part: BasePart, offset: Vector3, height: number, size: Vector3, tr: number }

-- 한 번에 너무 많이 빨려 들면 (아주 큰 블랙홀) 작은 것들은 바로 사라지게 해서 화면이 버벅이지 않게 한다
local MAX_SUCKING = 40
local sucking = 0

local function hideNow(model: Model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
		elseif d:IsA("ParticleEmitter") or d:IsA("PointLight") or d:IsA("Sparkles") then
			(d :: any).Enabled = false
		end
	end
end

local function suck(model: Model)
	local id = model:GetAttribute("EatenBy")
	if type(id) ~= "number" then
		return
	end
	local eater = Players:GetPlayerByUserId(id)
	local char = eater and eater.Character
	local center = char and Fx.holeCenter(char)
	if not center then
		hideNow(model)
		return
	end
	local size = model:GetAttribute("Size")
	local holeR = char and char:GetAttribute("HoleR")
	if sucking >= MAX_SUCKING or (type(size) == "number" and type(holeR) == "number" and size < holeR * 0.04) then
		hideNow(model)
		return
	end
	sucking += 1
	local list: { Sucked } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local off = d.Position - center
			table.insert(list, { part = d, offset = Vector3.new(off.X, 0, off.Z), height = off.Y, size = d.Size, tr = d.Transparency })
		elseif d:IsA("ParticleEmitter") or d:IsA("PointLight") or d:IsA("SpotLight") then
			(d :: any).Enabled = false
		end
	end
	local start = os.clock()
	local duration = 0.5
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = math.min(1, (os.clock() - start) / duration)
		local c = Fx.holeCenter(char :: Model) or center
		local ease = t * t
		local spin = CFrame.Angles(0, ease * 5, 0)
		for _, s in ipairs(list) do
			local p = s.part
			if p.Parent then
				local off = spin * (s.offset * (1 - ease))
				p.CFrame = CFrame.new(c + off + Vector3.new(0, s.height * (1 - ease) - ease * 2, 0)) * CFrame.Angles(ease * 6, ease * 4, 0)
				p.Size = s.size * math.max(0.05, 1 - ease * 0.95)
				p.Transparency = s.tr + (1 - s.tr) * ease
			end
		end
		if t >= 1 then
			conn:Disconnect()
			sucking -= 1
			for _, s in ipairs(list) do
				s.part.LocalTransparencyModifier = 1
			end
		end
	end)
end

-- 다시 생긴 물체: 작게 시작해서 통통 튀듯 원래 크기로
local readyAt = math.huge

local growing = 0
local function growIn(model: Model)
	-- 내 블랙홀에 비해 아주 작은 것, 한꺼번에 너무 많은 것은 연출 없이 바로 나타난다
	local size0 = model:GetAttribute("Size")
	local me = Players.LocalPlayer.Character
	local myR = me and me:GetAttribute("HoleR")
	if growing >= 20 or (type(size0) == "number" and type(myR) == "number" and size0 < myR * 0.03) then
		return
	end
	growing += 1
	local ok = pcall(function()
		model:ScaleTo(0.05)
	end)
	if not ok then
		growing -= 1
		return
	end
	local pos = model:GetPivot().Position
	local size = model:GetAttribute("Size")
	local s = type(size) == "number" and size or 2
	Fx.burst(pos + Vector3.new(0, s * 0.5, 0), Color3.fromRGB(255, 255, 220), 10, 4 + s, math.clamp(s * 0.2, 0.3, 6))
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = math.min(1, (os.clock() - start) / 0.45)
		if not model.Parent or model:GetAttribute("EatenBy") then
			conn:Disconnect()
			growing -= 1
			return
		end
		-- 살짝 넘쳤다가 돌아오는 곡선
		local c = 1.7
		local k = 1 + (c + 1) * (t - 1) ^ 3 + c * (t - 1) ^ 2
		pcall(function()
			model:ScaleTo(math.max(0.05, k))
		end)
		if t >= 1 then
			conn:Disconnect()
			growing -= 1
			pcall(function()
				model:ScaleTo(1)
			end)
		end
	end)
end

-- 황금 물체: 금박을 입히고 반짝이게 (내 화면에서만 바꾼다)
local GOLD = Color3.fromRGB(255, 205, 60)
local function goldify(model: Model)
	if model:GetAttribute("Goldified") or not model:GetAttribute("Golden") then
		return
	end
	model:SetAttribute("Goldified", true)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.9 and d.Material ~= Enum.Material.Neon then
			d.Color = d.Color:Lerp(GOLD, 0.75)
			d.Material = Enum.Material.Foil
			d.Reflectance = 0.2
		end
	end
	local pp = model.PrimaryPart
	if pp then
		local sp = Instance.new("Sparkles")
		sp.SparkleColor = GOLD
		sp.Parent = pp
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 16
		light.Brightness = 2
		light.Parent = pp
	end
end

local function watchObject(model: Instance)
	if not model:IsA("Model") then
		return
	end
	goldify(model :: Model)
	model:GetAttributeChangedSignal("Golden"):Connect(function()
		goldify(model :: Model)
	end)
	if model:GetAttribute("EatenBy") then
		suck(model :: Model)
	elseif os.clock() > readyAt then
		growIn(model :: Model)
	end
	model:GetAttributeChangedSignal("EatenBy"):Connect(function()
		suck(model :: Model)
	end)
end

------------------------------------------------------------------------
-- 떠오르는 숫자와 터지는 빛
------------------------------------------------------------------------
function Fx.popup(pos: Vector3, text: string, color: Color3, size: number)
	local anchor = fxPart(Vector3.new(0.2, 0.2, 0.2), color, Enum.Material.Neon, nil, 1)
	anchor.CFrame = CFrame.new(pos)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 220, 0, 50)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 3000
	bb.Parent = anchor
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextSize = size
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.2
	l.Text = text
	l.Parent = bb
	TweenService:Create(anchor, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = pos + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(l, TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1)
end

function Fx.burst(pos: Vector3, color: Color3, count: number, speed: number, size: number)
	local anchor = fxPart(Vector3.new(0.2, 0.2, 0.2), color, Enum.Material.Neon, nil, 1)
	anchor.CFrame = CFrame.new(pos)
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.3, 0.7)
	pe.Speed = NumberRange.new(speed * 0.5, speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = 4
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(color)
	pe.Parent = anchor
	pe:Emit(count)
	Debris:AddItem(anchor, 1.2)
end

-- 바닥에 퍼지는 빛 고리
function Fx.ring(pos: Vector3, color: Color3, fromD: number, toD: number, life: number)
	local p = disc(fromD, 0.2, color, Enum.Material.Neon, 0.2)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.25, 0))
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min(1, (os.clock() - start) / life)
		local e = 1 - (1 - k) * (1 - k)
		setDisc(p, fromD + (toD - fromD) * e)
		p.Transparency = 0.2 + 0.8 * k
		if k >= 1 then
			conn:Disconnect()
			p:Destroy()
		end
	end)
end

-- 삼킨 물체 자리에서 블랙홀 가운데로 빨려 드는 빛줄기
function Fx.streak(from: Vector3, to: Vector3, color: Color3, size: number)
	local p = fxPart(Vector3.new(1, 1, 1) * size, color, Enum.Material.Neon, Enum.PartType.Ball)
	p.CFrame = CFrame.new(from)
	local side = Vector3.new(-(to.Z - from.Z), 0, to.X - from.X)
	if side.Magnitude > 0.01 then
		side = side.Unit * math.min(side.Magnitude, 40) * 0.3
	end
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min(1, (os.clock() - start) / 0.32)
		local pos = from:Lerp(to, k * k) + side * math.sin(k * math.pi) + Vector3.new(0, math.sin(k * math.pi) * size, 0)
		p.CFrame = CFrame.new(pos)
		p.Size = Vector3.new(1, 1, 1) * size * (1 - k * 0.8)
		p.Transparency = k * 0.6
		if k >= 1 then
			conn:Disconnect()
			p:Destroy()
		end
	end)
end

-- 빛기둥
function Fx.pillar(pos: Vector3, color: Color3, height: number, width: number, life: number)
	local p = fxPart(Vector3.new(height, width, width), color, Enum.Material.Neon, Enum.PartType.Cylinder, 0.1)
	p.CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0)) * FLAT
	TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(height, 0.1, 0.1), Transparency = 1 }):Play()
	Debris:AddItem(p, life + 0.05)
end

------------------------------------------------------------------------
-- 별똥별: 하늘에서 떨어져 바닥에서 반짝인다. 삼키면 질량 2배
------------------------------------------------------------------------
local currentStar: Model? = nil

function Fx.clearStar()
	if currentStar then
		currentStar:Destroy()
		currentStar = nil
	end
end

function Fx.star(pos: Vector3, life: number)
	Fx.clearStar()
	local model = Instance.new("Model")
	model.Name = "ShootingStar"
	model.Parent = folder
	currentStar = model
	local gold = Color3.fromRGB(255, 225, 90)
	local core = fxPart(Vector3.new(3, 3, 3), gold, Enum.Material.Neon, Enum.PartType.Ball)
	core.Parent = model
	local points = {}
	for _ = 1, 5 do
		local p = fxPart(Vector3.new(1.1, 3.2, 1.1), gold:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.Neon)
		p.Parent = model
		table.insert(points, p)
	end
	local light = Instance.new("PointLight")
	light.Color = gold
	light.Range = 30
	light.Brightness = 3
	light.Parent = core
	local beam = fxPart(Vector3.new(120, 4, 4), gold, Enum.Material.Neon, Enum.PartType.Cylinder, 0.6)
	beam.Parent = model
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.new(0, 180, 0, 40)
	tag.StudsOffset = Vector3.new(0, 7, 0)
	tag.AlwaysOnTop = true
	tag.LightInfluence = 0
	tag.MaxDistance = 5000
	tag.Parent = core
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.TextColor3 = gold
	l.TextStrokeTransparency = 0.2
	l.Text = "⭐ 질량 2배"
	l.Parent = tag
	local trail = Instance.new("ParticleEmitter")
	trail.Rate = 40
	trail.Lifetime = NumberRange.new(0.4, 0.8)
	trail.Speed = NumberRange.new(0, 2)
	trail.Size = seq(1.5, 0)
	trail.LightEmission = 1
	trail.Color = ColorSequence.new(gold, Color3.fromRGB(255, 140, 60))
	trail.Parent = core

	local from = pos + Vector3.new(-90, 220, -60)
	local start = os.clock()
	local fall = 1.1
	Fx.sound("whoosh", 0.5, 0.6)
	local landed = false
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if currentStar ~= model or not model.Parent then
			conn:Disconnect()
			return
		end
		local age = os.clock() - start
		if age > life + fall then
			conn:Disconnect()
			Fx.clearStar()
			return
		end
		local c: Vector3
		if age < fall then
			local k = age / fall
			c = from:Lerp(pos + Vector3.new(0, 4, 0), k * k)
			beam.Transparency = 1
		else
			if not landed then
				landed = true
				Fx.ring(pos, gold, 4, 60, 0.7)
				Fx.burst(pos + Vector3.new(0, 3, 0), gold, 40, 40, 2)
				Fx.sound("pop", 0.6, 0.7)
			end
			c = pos + Vector3.new(0, 4 + math.sin(age * 3) * 0.8, 0)
			beam.Transparency = 0.55 + math.sin(age * 4) * 0.1
			beam.CFrame = CFrame.new(pos + Vector3.new(0, 60, 0)) * FLAT
		end
		core.CFrame = CFrame.new(c)
		local spin = CFrame.Angles(0, age * 2, 0)
		for i, p in ipairs(points) do
			p.CFrame = CFrame.new(c) * spin * CFrame.Angles(0, 0, (i - 1) * math.pi * 2 / 5) * CFrame.new(0, 2.2, 0)
		end
	end)
end

function Fx.starGot(pos: Vector3)
	Fx.clearStar()
	local gold = Color3.fromRGB(255, 225, 90)
	Fx.ring(pos, gold, 6, 140, 0.9)
	Fx.pillar(pos, gold, 200, 14, 0.8)
	Fx.burst(pos + Vector3.new(0, 4, 0), gold, 60, 60, 3)
	Fx.sound("slash", 0.6, 1.4)
end

------------------------------------------------------------------------
-- 시작
------------------------------------------------------------------------
function Fx.start()
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	task.spawn(function()
		local objects = workspace:WaitForChild("Objects")
		for _, m in ipairs(objects:GetChildren()) do
			watchObject(m)
		end
		objects.ChildAdded:Connect(watchObject)
		-- 처음 물체들이 다 내려오기 전에는 뿅 연출을 하지 않는다
		task.delay(4, function()
			readyAt = os.clock()
		end)
	end)
	task.spawn(buildGallery)
	local galleryCheck = 0
	RunService.RenderStepped:Connect(function(dt: number)
		local t = os.clock()
		for char, h in pairs(holes) do
			if not char.Parent then
				destroyHole(h)
				holes[char] = nil
			else
				updateHole(h, t, dt)
			end
		end
		-- 전시관은 카메라가 가까울 때만 움직인다
		if t > galleryCheck then
			galleryCheck = t + 0.5
			-- 로비에 들어가고 나올 때 블랙홀 크기 바꾸기
			for char, h in pairs(holes) do
				local raw = char:GetAttribute("HoleR")
				if type(raw) == "number" and math.abs(shownRadius(char, raw) - h.target) > 0.01 then
					syncHole(char)
				end
			end
			local cam = workspace.CurrentCamera
			local cp = cam and cam.CFrame.Position or Vector3.zero
			for _, g in ipairs(gallery) do
				local c = g.hole.center or Vector3.zero
				g.hole.active = (c - cp).Magnitude < 450
			end
		end
		for _, h in ipairs(previews) do
			if h.active then
				updateHole(h, t, dt)
			end
		end
	end)
end

return Fx
