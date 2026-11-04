-- 권왕 3.19.9판: 업적 오라 (무협 기운). 신화 업적 아홉을 이루면 그 업적만의 기운을 얻는다 (🎨 꾸미기에서 하나 고른다)
-- 딱딱한 물체 없이, 몸 전체 (가슴 · 허리 · 두 팔 · 두 다리) 에서 피어오르는 입자로만 그린다. 업적마다 빛깔 · 결 · 흐름이 다르다:
--   혈룡 기운   핏빛 불길이 온몸에서 타오르고 불티가 튄다
--   파천 기운   검보랏빛 연기가 몸을 휘감고 흰 번갯불이 잘게 튄다
--   운석 기운   두 손과 두 발에서 주황 불꽃이 일고, 재가 날린다
--   무지개 구름 발밑에 흰 구름이 피어오르고 무지갯빛 가루가 올라간다
--   윤회 기운   보랏빛 영기가 느릿하게 타오르고 금빛 별가루가 천천히 가라앉는다
--   만권 기운   청백의 맑은 기운이 몸을 감싸고 희고 금빛인 반짝임이 정수리에서 흩어진다
--   천상 꽃잎   연분홍 · 하늘빛 꽃잎이 몸 둘레에서 나풀나풀 떨어진다
--   천서 기운   푸른 안개가 깔리고 빛의 글자 같은 작은 빛이 천천히 곧게 떠오른다
--   금룡 기운   발끝부터 머리 위까지 금빛 화염이 크게 치솟고 흰 불씨가 흩날린다
-- 사라지는 기술 (Vanish) 동안은 끈다. 가벼운 그래픽이면 입자를 줄인다
local AchAura = {}

local Perf: any = nil
pcall(function()
	Perf = require(script.Parent:WaitForChild("Perf", 2) :: any)
end)

local TEX = {
	fire = "rbxasset://textures/particles/fire_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	spark = "rbxasset://textures/particles/sparkles_main.dds",
}
local C3 = Color3.fromRGB
local function cs(list: { Color3 }): ColorSequence
	if #list == 1 then
		return ColorSequence.new(list[1])
	end
	local kp = {}
	for i, c in ipairs(list) do
		table.insert(kp, ColorSequenceKeypoint.new((i - 1) / (#list - 1), c))
	end
	return ColorSequence.new(kp)
end
local function ns(pts: { { number } }): NumberSequence
	local kp = {}
	for _, p in ipairs(pts) do
		table.insert(kp, NumberSequenceKeypoint.new(p[1], p[2], p[3] or 0))
	end
	return NumberSequence.new(kp)
end
local function nr(a: number, b: number): NumberRange
	return NumberRange.new(a, b)
end

local BODY = { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerLeg", "RightLowerLeg" }
local CORE = { "UpperTorso", "LowerTorso" }
local HANDS_FEET = { "LeftHand", "RightHand", "LeftFoot", "RightFoot" }
local FEET = { "LeftFoot", "RightFoot" }

-- 한 겹: on = 뿜는 몸 부위, rate = 부위 하나의 초당 입자 수
type Layer = {
	on: { string },
	tex: string,
	color: ColorSequence,
	size: NumberSequence,
	alpha: NumberSequence,
	life: NumberRange,
	rate: number,
	speed: NumberRange,
	accel: Vector3?,
	spread: Vector2?,
	light: number?,
	bright: number?,
	rot: NumberRange?,
	spin: NumberRange?,
	drag: number?,
	z: number?,
	dir: Enum.NormalId?,
}
local DEFS: { [string]: { Layer } } = {}

DEFS.blooddragon = {
	-- 핏빛 불길: 온몸에서 위로 타오른다 (아래는 진홍, 끝은 검붉게 사그라든다)
	{ on = BODY, tex = TEX.fire, color = cs({ C3(255, 90, 60), C3(220, 20, 30), C3(90, 0, 10) }), size = ns({ { 0, 1.1 }, { 0.5, 0.8 }, { 1, 0.1 } }), alpha = ns({ { 0, 0.55 }, { 0.3, 0.25 }, { 1, 1 } }),
		life = nr(0.5, 0.8), rate = 14, speed = nr(1.5, 3), accel = Vector3.new(0, 7, 0), spread = Vector2.new(25, 25), light = 0.9, bright = 2, rot = nr(-30, 30), spin = nr(-60, 60), z = 0.4 },
	-- 불티: 금빛·붉은 작은 점이 빠르게 튀어 오른다
	{ on = CORE, tex = TEX.spark, color = cs({ C3(255, 220, 120), C3(255, 80, 50) }), size = ns({ { 0, 0.22 }, { 1, 0 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
		life = nr(0.6, 1.1), rate = 8, speed = nr(4, 7), accel = Vector3.new(0, 4, 0), spread = Vector2.new(60, 60), light = 1, bright = 3, drag = 1.5, z = 0.6 },
}
DEFS.pacheon = {
	-- 검보랏빛 연기가 몸을 휘감는다 (느리게 부풀며 흩어진다)
	{ on = BODY, tex = TEX.smoke, color = cs({ C3(120, 50, 200), C3(50, 15, 80), C3(20, 5, 30) }), size = ns({ { 0, 0.6 }, { 1, 2.0 } }), alpha = ns({ { 0, 0.85 }, { 0.3, 0.55 }, { 1, 1 } }),
		life = nr(0.9, 1.4), rate = 8, speed = nr(0.6, 1.4), accel = Vector3.new(0, 2.5, 0), spread = Vector2.new(180, 180), light = 0.2, rot = nr(0, 360), spin = nr(-90, 90), drag = 1 },
	-- 번갯불: 흰·보랏빛 반짝임이 아주 짧게 사방으로 튄다
	{ on = BODY, tex = TEX.spark, color = cs({ C3(255, 255, 255), C3(200, 150, 255) }), size = ns({ { 0, 0.5 }, { 0.2, 0.25 }, { 1, 0 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
		life = nr(0.12, 0.25), rate = 5, speed = nr(6, 10), spread = Vector2.new(180, 180), light = 1, bright = 5, z = 0.8 },
	-- 속의 붉은 기운 (가슴에서 은은하게)
	{ on = { "UpperTorso" }, tex = TEX.fire, color = cs({ C3(255, 60, 80), C3(120, 20, 60) }), size = ns({ { 0, 1.4 }, { 1, 0.4 } }), alpha = ns({ { 0, 0.8 }, { 1, 1 } }),
		life = nr(0.4, 0.6), rate = 6, speed = nr(0.5, 1), accel = Vector3.new(0, 3, 0), light = 0.8, bright = 1.5 },
}
DEFS.meteor = {
	-- 두 손 두 발의 불꽃
	{ on = HANDS_FEET, tex = TEX.fire, color = cs({ C3(255, 230, 140), C3(255, 130, 40), C3(160, 40, 10) }), size = ns({ { 0, 0.9 }, { 1, 0.15 } }), alpha = ns({ { 0, 0.4 }, { 1, 1 } }),
		life = nr(0.35, 0.6), rate = 16, speed = nr(1, 2.5), accel = Vector3.new(0, 8, 0), spread = Vector2.new(20, 20), light = 1, bright = 2.5, spin = nr(-90, 90), z = 0.5 },
	-- 재: 잿빛 조각이 천천히 날린다
	{ on = CORE, tex = TEX.smoke, color = cs({ C3(90, 70, 60), C3(40, 34, 30) }), size = ns({ { 0, 0.25 }, { 1, 0.6 } }), alpha = ns({ { 0, 0.4 }, { 1, 1 } }),
		life = nr(1.2, 1.8), rate = 5, speed = nr(1, 2), accel = Vector3.new(0.8, 1.5, 0), spread = Vector2.new(80, 80), rot = nr(0, 360), spin = nr(-120, 120), drag = 0.8 },
	-- 불씨
	{ on = CORE, tex = TEX.spark, color = cs({ C3(255, 200, 90) }), size = ns({ { 0, 0.18 }, { 1, 0 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
		life = nr(0.8, 1.3), rate = 6, speed = nr(3, 5), accel = Vector3.new(0, 3, 0), spread = Vector2.new(70, 70), light = 1, bright = 3, drag = 1 },
}
DEFS.rainbow = {
	-- 발밑의 흰 구름: 낮게 퍼지며 둥실 피어오른다
	{ on = FEET, tex = TEX.smoke, color = cs({ C3(255, 255, 255), C3(235, 240, 255) }), size = ns({ { 0, 1.0 }, { 1, 2.6 } }), alpha = ns({ { 0, 0.5 }, { 0.4, 0.35 }, { 1, 1 } }),
		life = nr(1.2, 1.8), rate = 7, speed = nr(0.8, 1.6), accel = Vector3.new(0, 0.6, 0), spread = Vector2.new(85, 85), light = 0.3, rot = nr(0, 360), spin = nr(-20, 20), drag = 1.2 },
	-- 무지갯빛 가루: 몸에서 천천히 올라가며 빛깔이 여섯 번 바뀐다
	{ on = BODY, tex = TEX.spark, color = cs({ C3(255, 90, 110), C3(255, 180, 70), C3(255, 245, 110), C3(110, 235, 140), C3(100, 180, 255), C3(180, 120, 255) }), size = ns({ { 0, 0.3 }, { 0.5, 0.35 }, { 1, 0 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
		life = nr(1, 1.6), rate = 4, speed = nr(1, 2), accel = Vector3.new(0, 1.5, 0), spread = Vector2.new(50, 50), light = 1, bright = 2.5, drag = 0.6 },
}
DEFS.samsara = {
	-- 보랏빛 영기: 느릿하게 타오른다 (불보다 부드럽고 길다)
	{ on = BODY, tex = TEX.fire, color = cs({ C3(200, 170, 255), C3(140, 90, 255), C3(60, 30, 140) }), size = ns({ { 0, 0.9 }, { 0.6, 1.0 }, { 1, 0.2 } }), alpha = ns({ { 0, 0.7 }, { 0.4, 0.45 }, { 1, 1 } }),
		life = nr(0.9, 1.3), rate = 9, speed = nr(0.6, 1.2), accel = Vector3.new(0, 3, 0), spread = Vector2.new(30, 30), light = 0.8, bright = 1.6, rot = nr(-20, 20), spin = nr(-30, 30), z = 0.3 },
	-- 금빛 별가루: 몸 둘레로 퍼졌다가 천천히 가라앉는다
	{ on = CORE, tex = TEX.spark, color = cs({ C3(255, 230, 150), C3(255, 200, 90) }), size = ns({ { 0, 0 }, { 0.3, 0.3 }, { 1, 0 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
		life = nr(1.6, 2.2), rate = 5, speed = nr(2, 3), accel = Vector3.new(0, -0.6, 0), spread = Vector2.new(180, 180), light = 1, bright = 3, drag = 2 },
}
DEFS.crown = {
	-- 청백의 맑은 기운: 몸을 얇게 감싼다
	{ on = BODY, tex = TEX.fire, color = cs({ C3(240, 250, 255), C3(170, 215, 255), C3(110, 160, 230) }), size = ns({ { 0, 0.8 }, { 1, 0.15 } }), alpha = ns({ { 0, 0.65 }, { 0.3, 0.45 }, { 1, 1 } }),
		life = nr(0.5, 0.8), rate = 10, speed = nr(1, 2), accel = Vector3.new(0, 6, 0), spread = Vector2.new(20, 20), light = 1, bright = 2, z = 0.3 },
	-- 정수리에서 흩어지는 흰·금빛 반짝임 (왕관처럼)
	{ on = { "Head" }, tex = TEX.spark, color = cs({ C3(255, 255, 255), C3(255, 215, 110) }), size = ns({ { 0, 0.4 }, { 1, 0 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
		life = nr(0.7, 1.1), rate = 10, speed = nr(3, 5), accel = Vector3.new(0, -2, 0), spread = Vector2.new(35, 35), light = 1, bright = 4, drag = 1.5, dir = Enum.NormalId.Top },
}
DEFS.petals = {
	-- 꽃잎: 몸 둘레에서 나풀나풀 돌며 떨어진다 (뒤집히듯 크기를 출렁인다)
	{ on = BODY, tex = TEX.spark, color = cs({ C3(255, 185, 220), C3(255, 215, 235) }), size = ns({ { 0, 0.35 }, { 0.25, 0.2 }, { 0.5, 0.38 }, { 0.75, 0.2 }, { 1, 0.3 } }), alpha = ns({ { 0, 0.1 }, { 0.8, 0.2 }, { 1, 1 } }),
		life = nr(1.6, 2.4), rate = 3, speed = nr(1.5, 2.5), accel = Vector3.new(0.6, -1.4, 0.3), spread = Vector2.new(180, 180), light = 0.6, bright = 1.5, rot = nr(0, 360), spin = nr(-200, 200), drag = 1.4 },
	{ on = BODY, tex = TEX.spark, color = cs({ C3(170, 230, 255), C3(220, 245, 255) }), size = ns({ { 0, 0.3 }, { 0.3, 0.18 }, { 0.6, 0.34 }, { 1, 0.25 } }), alpha = ns({ { 0, 0.1 }, { 0.8, 0.2 }, { 1, 1 } }),
		life = nr(1.6, 2.4), rate = 2, speed = nr(1.5, 2.5), accel = Vector3.new(-0.5, -1.2, 0.4), spread = Vector2.new(180, 180), light = 0.6, bright = 1.5, rot = nr(0, 360), spin = nr(-200, 200), drag = 1.4 },
	-- 은은한 분홍빛 (가슴 둘레)
	{ on = { "UpperTorso" }, tex = TEX.smoke, color = cs({ C3(255, 200, 230) }), size = ns({ { 0, 1.5 }, { 1, 3 } }), alpha = ns({ { 0, 0.88 }, { 1, 1 } }),
		life = nr(0.8, 1.2), rate = 3, speed = nr(0.3, 0.6), light = 0.5 },
}
DEFS.scripture = {
	-- 푸른 안개: 허리 아래로 얕게 깔린다
	{ on = { "LowerTorso", "LeftLowerLeg", "RightLowerLeg" }, tex = TEX.smoke, color = cs({ C3(170, 230, 255), C3(110, 180, 240) }), size = ns({ { 0, 1.0 }, { 1, 2.4 } }), alpha = ns({ { 0, 0.8 }, { 0.4, 0.65 }, { 1, 1 } }),
		life = nr(1.2, 1.8), rate = 5, speed = nr(0.5, 1), accel = Vector3.new(0, 0.5, 0), spread = Vector2.new(90, 90), light = 0.5, rot = nr(0, 360), spin = nr(-15, 15), drag = 1 },
	-- 빛의 글자: 작은 푸른·흰 빛이 천천히 곧게 떠오른다 (흔들림 없이 또박또박)
	{ on = BODY, tex = TEX.spark, color = cs({ C3(220, 250, 255), C3(120, 210, 255) }), size = ns({ { 0, 0 }, { 0.2, 0.32 }, { 0.8, 0.28 }, { 1, 0 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
		life = nr(1.4, 2), rate = 4, speed = nr(0.8, 1.3), accel = Vector3.new(0, 0.8, 0), spread = Vector2.new(15, 15), light = 1, bright = 3, z = 0.5 },
}
DEFS.golddragon = {
	-- 금빛 화염: 크고 높게 치솟는다 (흰 속불 → 금빛 → 주황 끝)
	{ on = BODY, tex = TEX.fire, color = cs({ C3(255, 250, 220), C3(255, 205, 70), C3(240, 120, 20) }), size = ns({ { 0, 1.4 }, { 0.5, 1.1 }, { 1, 0.15 } }), alpha = ns({ { 0, 0.5 }, { 0.3, 0.2 }, { 1, 1 } }),
		life = nr(0.6, 0.95), rate = 16, speed = nr(2, 4), accel = Vector3.new(0, 11, 0), spread = Vector2.new(15, 15), light = 1, bright = 2.5, rot = nr(-20, 20), spin = nr(-45, 45), z = 0.5 },
	-- 발끝에서도 불길이 솟는다 (몸 전체가 불기둥 속에 선 것처럼)
	{ on = FEET, tex = TEX.fire, color = cs({ C3(255, 230, 140), C3(255, 170, 40) }), size = ns({ { 0, 1.6 }, { 1, 0.3 } }), alpha = ns({ { 0, 0.55 }, { 1, 1 } }),
		life = nr(0.7, 1), rate = 10, speed = nr(3, 5), accel = Vector3.new(0, 12, 0), spread = Vector2.new(10, 10), light = 1, bright = 2 },
	-- 흰 불씨
	{ on = CORE, tex = TEX.spark, color = cs({ C3(255, 255, 240), C3(255, 220, 130) }), size = ns({ { 0, 0.25 }, { 1, 0 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
		life = nr(0.8, 1.4), rate = 8, speed = nr(5, 8), accel = Vector3.new(0, 5, 0), spread = Vector2.new(45, 45), light = 1, bright = 4, drag = 1.2 },
}

------------------------------------------------------------------------
-- 몸마다 붙이고 떼기
------------------------------------------------------------------------
local active: { [Model]: { id: string, emitters: { ParticleEmitter } } } = {}
local ALT = { UpperTorso = "Torso", LowerTorso = "Torso", LeftUpperArm = "Left Arm", RightUpperArm = "Right Arm", LeftLowerLeg = "Left Leg", RightLowerLeg = "Right Leg", LeftHand = "Left Arm", RightHand = "Right Arm", LeftFoot = "Left Leg", RightFoot = "Right Leg" }
local function partOf(model: Model, name: string): BasePart?
	local p = model:FindFirstChild(name)
	if p and p:IsA("BasePart") then
		return p
	end
	-- 옛 몸 (R6) 이름
	local alt = ALT[name]
	local q = alt and model:FindFirstChild(alt)
	return (q and q:IsA("BasePart")) and q or nil
end
local function clear(model: Model)
	local a = active[model]
	if a then
		for _, e in ipairs(a.emitters) do
			e:Destroy()
		end
		active[model] = nil
	end
end
local function build(model: Model, id: string): { ParticleEmitter }
	local out = {}
	local k = (Perf and Perf.low) and 0.4 or 1
	for _, L in ipairs(DEFS[id] or {}) do
		for _, pn in ipairs(L.on) do
			local p = partOf(model, pn)
			if p then
				local e = Instance.new("ParticleEmitter")
				e.Name = "AchAura"
				e.Texture = L.tex
				e.Color = L.color
				e.Size = L.size
				e.Transparency = L.alpha
				e.Lifetime = L.life
				e.Rate = math.max(1, L.rate * k)
				e.Speed = L.speed
				e.Acceleration = L.accel or Vector3.zero
				e.SpreadAngle = L.spread or Vector2.new(30, 30)
				e.LightEmission = L.light or 0
				e.Brightness = L.bright or 1
				e.Rotation = L.rot or nr(0, 0)
				e.RotSpeed = L.spin or nr(0, 0)
				e.Drag = L.drag or 0
				e.ZOffset = L.z or 0
				e.EmissionDirection = L.dir or Enum.NormalId.Top
				e.LockedToPart = false
				e.Parent = p
				table.insert(out, e)
			end
		end
	end
	return out
end
local function setOn(model: Model, on: boolean)
	local a = active[model]
	if a then
		for _, e in ipairs(a.emitters) do
			e.Enabled = on
		end
	end
end
local function apply(model: Model, force: boolean?)
	local id = model:GetAttribute("AchAura")
	local cur = active[model]
	if cur and cur.id == id and not force then
		return
	end
	clear(model)
	if type(id) == "string" and DEFS[id] and model.Parent then
		active[model] = { id = id, emitters = build(model, id) }
		setOn(model, model:GetAttribute("Vanish") ~= true)
	end
end
local watched: { [Model]: boolean } = {}
function AchAura.watch(model: Model)
	if watched[model] then
		return
	end
	watched[model] = true
	model:GetAttributeChangedSignal("AchAura"):Connect(function()
		apply(model)
	end)
	model:GetAttributeChangedSignal("Vanish"):Connect(function()
		setOn(model, model:GetAttribute("Vanish") ~= true)
	end)
	model.AncestryChanged:Connect(function()
		if not model.Parent then
			clear(model)
			watched[model] = nil
		end
	end)
	apply(model)
	-- 몸 부위가 늦게 들어오면 한 번 더 붙인다
	task.delay(1.5, function()
		if model.Parent and active[model] then
			apply(model, true)
		end
	end)
end
function AchAura.has(id: any): boolean
	return type(id) == "string" and DEFS[id] ~= nil
end
return AchAura
