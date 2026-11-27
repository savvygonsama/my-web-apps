-- 권왕 3.19.9판: 업적 오라 (무협 기운). 신화 업적 아홉을 이루면 그 업적만의 기운을 얻는다 (🎨 꾸미기에서 하나 고른다)
-- 딱딱한 물체 없이, 몸 전체 (가슴 · 허리 · 두 팔 · 두 다리) 에서 피어오르는 입자로만 그린다. 업적마다 빛깔 · 결 · 흐름이 다르다:
--   혈룡 기운   핏빛 불길이 온몸에서 타오르고 불티가 튄다
--   파천 기운   검보랏빛 연기가 몸을 휘감고 흰 번갯불이 잘게 튄다
--   운석 기운   두 손과 두 발에서 주황 불꽃이 일고 재가 날린다
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
	squash: NumberSequence?, -- 3.99.88판: 길게 늘인 빛줄기 (VelocityParallel 과 함께)
	orient: Enum.ParticleOrientation?,
	ground: boolean?, -- 3.99.88판: 발밑 (뿌리 아래 땅 높이) 에서 낮게 퍼진다
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
-- 3.99.88판 오라를 티 나게: 너무 은은해서 안 보였다. 빛깔 · 결은 그대로 두고
--   ① 가슴의 은은한 빛 (둘레를 오라 빛깔로 물들인다) ② 발밑에 낮게 퍼지는 기운 ③ 오라마다 대표 빛줄기 하나 ④ 입자 양 ×1.5 · 크기 ×1.2
------------------------------------------------------------------------
local STREAK = ns({ { 0, 2.4 }, { 1, 1.2 } }) -- 빛줄기: 세로로 늘인다
local VP = Enum.ParticleOrientation.VelocityParallel
local GLOW: { [string]: { any } } = {
	blooddragon = { C3(255, 50, 50), 1.6 }, pacheon = { C3(170, 90, 255), 1.4 }, meteor = { C3(255, 150, 60), 1.6 },
	rainbow = { C3(255, 250, 235), 1.0 }, samsara = { C3(170, 130, 255), 1.4 }, crown = { C3(190, 225, 255), 1.4 },
	petals = { C3(255, 190, 225), 1.1 }, scripture = { C3(130, 210, 255), 1.4 }, golddragon = { C3(255, 200, 80), 1.8 },
}
local EXTRA: { [string]: { Layer } } = {
	blooddragon = {
		-- 발밑: 핏빛 불씨가 낮게 번진다
		{ on = {}, ground = true, tex = TEX.fire, color = cs({ C3(255, 70, 50), C3(120, 0, 15) }), size = ns({ { 0, 1.2 }, { 1, 0.2 } }), alpha = ns({ { 0, 0.5 }, { 1, 1 } }),
			life = nr(0.5, 0.8), rate = 18, speed = nr(4, 6), accel = Vector3.new(0, 3, 0), spread = Vector2.new(85, 85), light = 1, bright = 2, drag = 3 },
		-- 대표: 몸을 타고 솟는 핏빛 불줄기
		{ on = CORE, tex = TEX.spark, color = cs({ C3(255, 200, 160), C3(255, 40, 40) }), size = ns({ { 0, 0.35 }, { 1, 0 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
			life = nr(0.5, 0.8), rate = 6, speed = nr(8, 12), accel = Vector3.new(0, 6, 0), spread = Vector2.new(25, 25), light = 1, bright = 2.5, squash = STREAK, orient = VP },
	},
	pacheon = {
		{ on = {}, ground = true, tex = TEX.smoke, color = cs({ C3(110, 50, 190), C3(30, 10, 50) }), size = ns({ { 0, 1.5 }, { 1, 3 } }), alpha = ns({ { 0, 0.7 }, { 1, 1 } }),
			life = nr(1, 1.5), rate = 10, speed = nr(3, 5), accel = Vector3.new(0, 0.5, 0), spread = Vector2.new(88, 88), light = 0.3, rot = nr(0, 360), spin = nr(-40, 40), drag = 2.5 },
		-- 대표: 몸을 따라 위아래로 튀는 흰 번갯줄기
		{ on = BODY, tex = TEX.spark, color = cs({ C3(255, 255, 255), C3(190, 140, 255) }), size = ns({ { 0, 0.3 }, { 1, 0.1 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
			life = nr(0.08, 0.14), rate = 1, speed = nr(18, 26), spread = Vector2.new(180, 180), light = 1, bright = 3, squash = ns({ { 0, 3 }, { 1, 3 } }), orient = VP },
	},
	meteor = {
		{ on = {}, ground = true, tex = TEX.spark, color = cs({ C3(255, 210, 110), C3(255, 110, 40) }), size = ns({ { 0, 0.3 }, { 1, 0 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
			life = nr(0.5, 0.9), rate = 14, speed = nr(4, 7), accel = Vector3.new(0, 4, 0), spread = Vector2.new(80, 80), light = 1, bright = 3, drag = 2 },
	},
	rainbow = {
		{ on = {}, ground = true, tex = TEX.smoke, color = cs({ C3(255, 255, 255), C3(240, 245, 255) }), size = ns({ { 0, 1.6 }, { 1, 3.6 } }), alpha = ns({ { 0, 0.45 }, { 1, 1 } }),
			life = nr(1.4, 2), rate = 10, speed = nr(2.5, 4), accel = Vector3.new(0, 0.4, 0), spread = Vector2.new(88, 88), light = 0.4, rot = nr(0, 360), spin = nr(-15, 15), drag = 2 },
	},
	samsara = {
		{ on = {}, ground = true, tex = TEX.fire, color = cs({ C3(190, 160, 255), C3(80, 40, 170) }), size = ns({ { 0, 1.0 }, { 1, 0.2 } }), alpha = ns({ { 0, 0.6 }, { 1, 1 } }),
			life = nr(0.8, 1.1), rate = 14, speed = nr(3, 5), accel = Vector3.new(0, 2, 0), spread = Vector2.new(86, 86), light = 0.9, bright = 1.8, drag = 2.5 },
		-- 대표: 금빛 별이 몸 둘레를 느리게 오르는 긴 줄기
		{ on = CORE, tex = TEX.spark, color = cs({ C3(255, 240, 180), C3(255, 200, 90) }), size = ns({ { 0, 0.25 }, { 1, 0.05 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
			life = nr(1, 1.4), rate = 4, speed = nr(3, 4), accel = Vector3.new(0, 1, 0), spread = Vector2.new(40, 40), light = 1, bright = 2, squash = STREAK, orient = VP },
	},
	crown = {
		{ on = {}, ground = true, tex = TEX.fire, color = cs({ C3(235, 248, 255), C3(140, 190, 255) }), size = ns({ { 0, 0.9 }, { 1, 0.15 } }), alpha = ns({ { 0, 0.6 }, { 1, 1 } }),
			life = nr(0.6, 0.9), rate = 14, speed = nr(3, 5), accel = Vector3.new(0, 3, 0), spread = Vector2.new(86, 86), light = 1, bright = 2, drag = 2.5 },
	},
	petals = {
		-- 발밑에 내려앉는 꽃잎 (넓게 깔린다)
		{ on = {}, ground = true, tex = TEX.spark, color = cs({ C3(255, 185, 220), C3(255, 225, 240) }), size = ns({ { 0, 0.4 }, { 0.5, 0.25 }, { 1, 0.35 } }), alpha = ns({ { 0, 0.1 }, { 0.8, 0.2 }, { 1, 1 } }),
			life = nr(1.6, 2.2), rate = 8, speed = nr(3, 5), accel = Vector3.new(0, -0.3, 0), spread = Vector2.new(85, 85), light = 0.6, bright = 1.6, rot = nr(0, 360), spin = nr(-150, 150), drag = 1.8 },
		-- 대표: 몸 둘레를 휘감아 도는 꽃바람
		{ on = CORE, tex = TEX.spark, color = cs({ C3(255, 200, 230), C3(200, 235, 255) }), size = ns({ { 0, 0.4 }, { 0.5, 0.25 }, { 1, 0.35 } }), alpha = ns({ { 0, 0.1 }, { 1, 1 } }),
			life = nr(1.2, 1.6), rate = 2, speed = nr(4, 6), accel = Vector3.new(2, 1, -2), spread = Vector2.new(180, 180), light = 0.6, bright = 1.6, rot = nr(0, 360), spin = nr(-260, 260), drag = 1 },
	},
	scripture = {
		{ on = {}, ground = true, tex = TEX.smoke, color = cs({ C3(170, 230, 255), C3(90, 160, 230) }), size = ns({ { 0, 1.4 }, { 1, 3 } }), alpha = ns({ { 0, 0.65 }, { 1, 1 } }),
			life = nr(1.2, 1.8), rate = 10, speed = nr(3, 4.5), accel = Vector3.new(0, 0.3, 0), spread = Vector2.new(88, 88), light = 0.5, rot = nr(0, 360), spin = nr(-15, 15), drag = 2.2 },
		-- 대표: 곧게 떠오르는 빛의 글줄 (가늘고 길다)
		{ on = BODY, tex = TEX.spark, color = cs({ C3(230, 250, 255), C3(120, 210, 255) }), size = ns({ { 0, 0.2 }, { 1, 0.05 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
			life = nr(1, 1.4), rate = 2, speed = nr(2, 3), spread = Vector2.new(8, 8), light = 1, bright = 2, squash = ns({ { 0, 3 }, { 1, 2 } }), orient = VP, dir = Enum.NormalId.Top },
	},
	golddragon = {
		-- 3.99.91판 대표: 발밑에서 솟는 금빛 불기둥 (크고 높게, 몸을 감싸며)
		{ on = {}, ground = true, tex = TEX.fire, color = cs({ C3(255, 250, 220), C3(255, 200, 70), C3(230, 110, 20) }), size = ns({ { 0, 2.2 }, { 0.6, 1.6 }, { 1, 0.2 } }), alpha = ns({ { 0, 0.45 }, { 0.4, 0.3 }, { 1, 1 } }),
			life = nr(0.7, 1.0), rate = 22, speed = nr(1, 2), accel = Vector3.new(0, 14, 0), spread = Vector2.new(14, 14), light = 1, bright = 2.2, rot = nr(-20, 20), spin = nr(-40, 40), z = 0.4 },
		{ on = {}, ground = true, tex = TEX.fire, color = cs({ C3(255, 235, 160), C3(240, 140, 20) }), size = ns({ { 0, 1.6 }, { 1, 0.2 } }), alpha = ns({ { 0, 0.45 }, { 1, 1 } }),
			life = nr(0.6, 0.9), rate = 20, speed = nr(4, 6), accel = Vector3.new(0, 5, 0), spread = Vector2.new(85, 85), light = 1, bright = 2.5, drag = 2.5 },
		-- 대표: 몸을 휘감고 치솟는 금빛 불줄기
		{ on = CORE, tex = TEX.spark, color = cs({ C3(255, 250, 220), C3(255, 190, 50) }), size = ns({ { 0, 0.4 }, { 1, 0.05 } }), alpha = ns({ { 0, 0 }, { 1, 1 } }),
			life = nr(0.6, 0.9), rate = 8, speed = nr(10, 14), accel = Vector3.new(0, 8, 0), spread = Vector2.new(30, 30), light = 1, bright = 2.5, squash = STREAK, orient = VP },
	},
}
for id, list in pairs(EXTRA) do
	if DEFS[id] then
		for _, L in ipairs(list) do
			-- 3.99.90판: 가는 빛줄기 (squash) 는 빼고 발밑 기운만. 대표 모습은 아래의 빛의 띠가 맡는다
			if not L.squash then
				table.insert(DEFS[id], L)
			end
		end
	end
end

------------------------------------------------------------------------
-- 3.99.90판 빛의 띠: 작은 입자를 흩뿌리는 대신, 굵고 긴 빛의 띠가 몸 둘레를 휘돈다 (가운데는 희고 바깥은 그 오라의 빛깔 하나)
--   오라마다 궤도가 다르다. spiral = 아래에서 위로 감아 오른다 · ring = 기울어진 고리를 돈다 · halo = 머리 위 가는 고리 · wave = 다리 둘레를 물결치듯
------------------------------------------------------------------------
type Rib = { c: Color3, n: number, mode: string, r: number, w: number, speed: number, life: number, lo: number?, hi: number? }
local RIBS: { [string]: Rib } = {
	-- 3.99.91판: 띠는 혈룡만 (아홉이 모두 띠라 얼핏 보면 같았다). 나머지는 아래 FORMS 가 저마다 다른 모양을 맡는다
	blooddragon = { c = C3(235, 30, 45), n = 3, mode = "spiral", r = 2.6, w = 1.1, speed = 4.2, life = 0.5 },
}
local function ribTrail(root: BasePart, w: number, life: number, c1: Color3, c2: Color3, alpha: number): { any }
	local a0 = Instance.new("Attachment")
	a0.Name = "AchRib"
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "AchRib"
	a1.Parent = root
	local tr = Instance.new("Trail")
	tr.Name = "AchRib"
	tr.Attachment0, tr.Attachment1 = a0, a1
	tr.Lifetime = life
	tr.MinLength = 0.05
	tr.FaceCamera = true
	tr.LightEmission = 1
	tr.LightInfluence = 0
	tr.Color = ColorSequence.new(c1, c2)
	tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, alpha), NumberSequenceKeypoint.new(0.6, math.min(1, alpha + 0.35)), NumberSequenceKeypoint.new(1, 1) })
	tr.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2) })
	tr.Parent = root
	return { a0 = a0, a1 = a1, tr = tr, w = w }
end
type RibSet = { root: BasePart, def: Rib, strands: { { outer: any, core: any, ph: number, tilt: number } }, t0: number }
local ribSets: { [Model]: RibSet } = {}
local function ribPos(R: Rib, k: number, ph: number, tilt: number, t: number): Vector3
	local a = t * R.speed + ph
	if R.mode == "spiral" then
		-- 아래에서 위로 감아 오르고 다시 내려온다 (가닥마다 박자가 다르다)
		local y = -2.4 + (math.sin(t * R.speed * 0.35 + ph) * 0.5 + 0.5) * 5.4
		local r = R.r * (0.75 + 0.25 * math.cos(y * 0.6))
		return Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
	elseif R.mode == "ring" then
		local lo, hi = R.lo or -0.5, R.hi or 0.5
		local y0 = (lo + hi) / 2
		local p = Vector3.new(math.cos(a) * R.r, 0, math.sin(a) * R.r)
		-- 기울어진 고리 (가닥마다 기울기가 다르다)
		return (CFrame.Angles(tilt, ph, 0) * p) + Vector3.new(0, y0, 0)
	elseif R.mode == "halo" then
		return Vector3.new(math.cos(a) * R.r, 3.6, math.sin(a) * R.r)
	end
	-- wave: 다리 · 몸 둘레를 위아래로 물결치며 돈다
	local lo, hi = R.lo or -2, R.hi or 0
	local y = lo + (math.sin(a * 2.2 + k) * 0.5 + 0.5) * (hi - lo)
	return Vector3.new(math.cos(a) * R.r, y, math.sin(a) * R.r)
end
local function ribBuild(model: Model, id: string): RibSet?
	local R = RIBS[id]
	local root = model:FindFirstChild("HumanoidRootPart")
	if not R or not root or not root:IsA("BasePart") or (Perf and Perf.low) then
		return nil
	end
	local core = R.c:Lerp(Color3.new(1, 1, 1), 0.85)
	local set: RibSet = { root = root, def = R, strands = {}, t0 = os.clock() }
	for i = 1, R.n do
		table.insert(set.strands, {
			outer = ribTrail(root, R.w, R.life, R.c, R.c:Lerp(Color3.new(0, 0, 0), 0.25), 0.15),
			core = ribTrail(root, R.w * 0.3, R.life * 0.8, core, R.c, 0),
			ph = (i - 1) / R.n * math.pi * 2,
			tilt = math.rad(-35 + (i - 1) * (70 / math.max(1, R.n - 1))),
		})
	end
	return set
end
local function ribClear(model: Model)
	local set = ribSets[model]
	if set then
		for _, st in ipairs(set.strands) do
			for _, x in ipairs({ st.outer, st.core }) do
				x.tr:Destroy()
				x.a0:Destroy()
				x.a1:Destroy()
			end
		end
		ribSets[model] = nil
	end
end
local ribConn: RBXScriptConnection? = nil
local formStepRef: () -> () = function() end
local function ribStep()
	local cam = workspace.CurrentCamera
	local now = os.clock()
	for model, set in pairs(ribSets) do
		local on = model:GetAttribute("Vanish") ~= true and set.root.Parent ~= nil
		local far = cam and (cam.CFrame.Position - set.root.Position).Magnitude > 140
		for k, st in ipairs(set.strands) do
			st.outer.tr.Enabled = on and not far
			st.core.tr.Enabled = on and not far
			if on and not far then
				local p = ribPos(set.def, k, st.ph, st.tilt, now - set.t0)
				-- 띠의 폭은 위아래 (FaceCamera 라 늘 화면을 본다)
				for _, x in ipairs({ st.outer, st.core }) do
					x.a0.Position = p - Vector3.new(0, x.w / 2, 0)
					x.a1.Position = p + Vector3.new(0, x.w / 2, 0)
				end
			end
		end
	end
end
local function ribStart()
	if not ribConn then
		ribConn = game:GetService("RunService").RenderStepped:Connect(function()
			ribStep()
			formStepRef()
		end)
	end
end

------------------------------------------------------------------------
-- 3.99.91판 오라마다 다른 모양 (FORMS): 파천 번개 갈래 · 윤회 법륜 · 만권 빛의 고리 · 운석 돌 · 천서 글자
--   부품은 몸이 아니라 따로 둔 폴더에 (물리에 걸리지 않게), 매 프레임 뿌리 (HumanoidRootPart) 를 따라 놓는다
------------------------------------------------------------------------
local formFolder = Instance.new("Folder")
formFolder.Name = "KwonAuraForms"
formFolder.Parent = workspace
local function fpart(size: Vector3, color: Color3, alpha: number, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	p.Size, p.Color, p.Transparency = size, color, alpha
	if shape then
		p.Shape = shape
	end
	p.Parent = formFolder
	return p
end
-- 고리: 짧은 막대 n개를 둥글게 (Roblox 에 고리 모양 부품이 없다)
local function ringParts(n: number, r: number, thick: number, color: Color3, alpha: number): { Part }
	local list = {}
	local seg = 2 * math.pi * r / n * 1.08
	for _ = 1, n do
		table.insert(list, fpart(Vector3.new(thick, thick, seg), color, alpha))
	end
	return list
end
local function placeRing(list: { Part }, cf: CFrame, r: number, spin: number)
	local n = #list
	for i, p in ipairs(list) do
		local a = (i - 0.5) / n * math.pi * 2 + spin
		local pos = cf:PointToWorldSpace(Vector3.new(math.cos(a) * r, math.sin(a) * r, 0))
		local tan = cf:VectorToWorldSpace(Vector3.new(-math.sin(a), math.cos(a), 0))
		p.CFrame = CFrame.lookAt(pos, pos + tan)
	end
end
type Form = { root: BasePart, parts: { Instance }, step: (number, CFrame) -> (), t0: number }
local FORMS: { [string]: (BasePart) -> Form } = {}
-- ⚡ 파천: 몸 둘레에서 흰 보랏빛 번개 갈래가 지직거린다 (0.08초마다 새 갈래, 켜졌다 꺼졌다)
FORMS.pacheon = function(root)
	local parts: { Instance } = {}
	local arcs = {}
	for _ = 1, 3 do
		local a0 = Instance.new("Attachment")
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Parent = root
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = a0, a1
		b.Segments = 10
		b.Width0, b.Width1 = 0.18, 0.06
		b.LightEmission, b.LightInfluence = 1, 0
		b.FaceCamera = true
		b.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 120, 255))
		b.Transparency = NumberSequence.new(0.05)
		b.Parent = root
		table.insert(arcs, { a0 = a0, a1 = a1, b = b })
		table.insert(parts, a0)
		table.insert(parts, a1)
		table.insert(parts, b)
	end
	local last = 0
	return { root = root, parts = parts, t0 = os.clock(), step = function(t)
		if t - last < 0.08 then
			return
		end
		last = t
		for _, A in ipairs(arcs) do
			local on = math.random() < 0.55
			A.b.Enabled = on
			if on then
				local y = (math.random() - 0.4) * 5
				local a = math.random() * math.pi * 2
				A.a0.Position = Vector3.new(math.cos(a) * 1.4, y, math.sin(a) * 1.4)
				local a2 = a + (math.random() - 0.5) * 2
				A.a1.Position = Vector3.new(math.cos(a2) * 2.8, y + (math.random() - 0.5) * 3, math.sin(a2) * 2.8)
				A.b.CurveSize0 = (math.random() - 0.5) * 4
				A.b.CurveSize1 = (math.random() - 0.5) * 4
			end
		end
	end }
end
-- ☸ 윤회: 등 뒤에 법륜 (두 겹 고리 + 바퀴살 여덟) 이 천천히 돈다
FORMS.samsara = function(root)
	local outer = ringParts(24, 2.2, 0.14, Color3.fromRGB(190, 150, 255), 0.25)
	local inner = ringParts(14, 0.9, 0.12, Color3.fromRGB(255, 215, 130), 0.2)
	local spokes = {}
	for _ = 1, 8 do
		table.insert(spokes, fpart(Vector3.new(0.08, 1.3, 0.08), Color3.fromRGB(255, 215, 130), 0.3))
	end
	local hub = fpart(Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(255, 235, 180), 0.1, Enum.PartType.Ball)
	local parts: { Instance } = { hub }
	for _, l in ipairs({ outer, inner, spokes }) do
		for _, p in ipairs(l) do
			table.insert(parts, p)
		end
	end
	return { root = root, parts = parts, t0 = os.clock(), step = function(t, rcf)
		local cf = rcf * CFrame.new(0, 1.2, 1.3) -- 등 뒤 (뿌리의 +Z 가 뒤)
		local spin = t * 0.5
		placeRing(outer, cf, 2.2, spin)
		placeRing(inner, cf, 0.9, -spin * 1.5)
		hub.CFrame = cf
		for i, p in ipairs(spokes) do
			local a = i / 8 * math.pi * 2 + spin
			p.CFrame = cf * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.55, 0)
		end
	end }
end
-- ◯ 만권: 머리 위에 가는 빛의 고리 하나가 떠서 천천히 돌며 오르내린다
FORMS.crown = function(root)
	local ring = ringParts(20, 0.95, 0.1, Color3.fromRGB(225, 240, 255), 0.15)
	return { root = root, parts = ring, t0 = os.clock(), step = function(t, rcf)
		local cf = CFrame.new(rcf.Position + Vector3.new(0, 3.9 + math.sin(t * 1.6) * 0.12, 0)) * CFrame.Angles(math.rad(90), 0, 0)
		placeRing(ring, cf, 0.95, t * 0.8)
	end }
end
-- ☄ 운석: 안이 불타는 작은 돌 셋이 몸 둘레를 돈다 (불티를 끌며)
FORMS.meteor = function(root)
	local parts: { Instance } = {}
	local rocks = {}
	for i = 1, 3 do
		local r = fpart(Vector3.new(0.7, 0.6, 0.65), Color3.fromRGB(60, 40, 32), 0, Enum.PartType.Block)
		r.Material = Enum.Material.CrackedLava
		r.Color = Color3.fromRGB(255, 120, 40)
		local e = Instance.new("ParticleEmitter")
		e.Texture = TEX.fire
		e.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100), Color3.fromRGB(200, 60, 20))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(0.3, 0.5)
		e.Rate = 30
		e.Speed = NumberRange.new(0, 0.5)
		e.LightEmission = 1
		e.Parent = r
		table.insert(parts, r)
		table.insert(rocks, { p = r, ph = (i - 1) / 3 * math.pi * 2, h = -0.5 + i * 0.6, sp = 1.4 + i * 0.25 })
	end
	return { root = root, parts = parts, t0 = os.clock(), step = function(t, rcf)
		for _, R in ipairs(rocks) do
			local a = t * R.sp + R.ph
			R.p.CFrame = CFrame.new(rcf.Position + Vector3.new(math.cos(a) * 2.8, R.h + math.sin(t * 2 + R.ph) * 0.3, math.sin(a) * 2.8)) * CFrame.Angles(t * 2, t * 1.3, 0)
		end
	end }
end
-- 📜 천서: 빛나는 글자 다섯이 몸 둘레를 떠돌며 천천히 나타났다 사라진다
local GLYPHS = { "天", "道", "武", "心", "經" }
FORMS.scripture = function(root)
	local parts: { Instance } = {}
	local gl = {}
	for i, ch in ipairs(GLYPHS) do
		local a = Instance.new("Attachment")
		a.Parent = root
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(1.6, 1.6)
		bb.LightInfluence = 0
		bb.Adornee = a
		bb.AlwaysOnTop = false
		bb.MaxDistance = 120
		bb.Parent = a
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.Font = Enum.Font.Antique
		l.TextScaled = true
		l.Text = ch
		l.TextColor3 = Color3.fromRGB(200, 235, 255)
		l.TextStrokeColor3 = Color3.fromRGB(60, 140, 220)
		l.TextStrokeTransparency = 0.3
		l.Parent = bb
		table.insert(parts, a)
		table.insert(gl, { a = a, l = l, ph = (i - 1) / #GLYPHS * math.pi * 2 })
	end
	return { root = root, parts = parts, t0 = os.clock(), step = function(t)
		for _, G in ipairs(gl) do
			local a = t * 0.45 + G.ph
			G.a.Position = Vector3.new(math.cos(a) * 2.6, 0.6 + math.sin(t * 0.7 + G.ph) * 1.4, math.sin(a) * 2.6)
			-- 천천히 나타났다 사라진다 (글자마다 박자가 다르다)
			local v = 0.5 + 0.5 * math.sin(t * 0.9 + G.ph * 1.7)
			G.l.TextTransparency = 1 - v * 0.95
			G.l.TextStrokeTransparency = 1 - v * 0.6
		end
	end }
end
local forms: { [Model]: Form } = {}
local function formBuild(model: Model, id: string)
	local mk = FORMS[id]
	local root = model:FindFirstChild("HumanoidRootPart")
	if not mk or not root or not root:IsA("BasePart") or (Perf and Perf.low) then
		return
	end
	forms[model] = mk(root)
	ribStart()
end
local function formClear(model: Model)
	local f = forms[model]
	if f then
		for _, x in ipairs(f.parts) do
			x:Destroy()
		end
		forms[model] = nil
	end
end
local function formStep()
	local cam = workspace.CurrentCamera
	local now = os.clock()
	for model, f in pairs(forms) do
		local hide = model:GetAttribute("Vanish") == true or f.root.Parent == nil
			or (cam ~= nil and (cam.CFrame.Position - f.root.Position).Magnitude > 140)
		for _, x in ipairs(f.parts) do
			if x:IsA("BasePart") then
				x.LocalTransparencyModifier = hide and 1 or 0
			elseif x:IsA("Beam") then
				if hide then
					x.Enabled = false
				end
			elseif x:IsA("Attachment") then
				local bb = x:FindFirstChildOfClass("BillboardGui")
				if bb then
					bb.Enabled = not hide
				end
			end
		end
		if not hide then
			f.step(now - f.t0, f.root.CFrame)
		end
	end
end
formStepRef = formStep
local function scaleSeq(seq: NumberSequence, k: number): NumberSequence
	local kp = {}
	for _, p in ipairs(seq.Keypoints) do
		table.insert(kp, NumberSequenceKeypoint.new(p.Time, p.Value * k, p.Envelope * k))
	end
	return NumberSequence.new(kp)
end

------------------------------------------------------------------------
-- 몸마다 붙이고 떼기
------------------------------------------------------------------------
local active: { [Model]: { id: string, emitters: { any } } } = {}
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
	ribClear(model)
	formClear(model)
	local a = active[model]
	if a then
		for _, e in ipairs(a.emitters) do
			e:Destroy()
		end
		active[model] = nil
	end
end
local function build(model: Model, id: string): { any }
	local out = {}
	local low = Perf and Perf.low
	local k = low and 0.4 or 1.2 -- 3.99.89판: 양 ×1.2 (×1.5 는 반짝이가 너무 흩뿌려져 촌스러웠다. 가벼운 그래픽은 예전처럼 줄인다)
	local sk = low and 1 or 1.2 -- 크기 ×1.2
	local root = model:FindFirstChild("HumanoidRootPart")
	local feet: Attachment? = nil
	for _, L in ipairs(DEFS[id] or {}) do
		local hosts: { Instance } = {}
		if L.ground then
			if root and root:IsA("BasePart") and not low then
				if not feet then
					local a = Instance.new("Attachment")
					a.Name = "AchAuraFeet"
					a.Position = Vector3.new(0, -2.7, 0)
					a.Parent = root
					feet = a
					table.insert(out, a)
				end
				table.insert(hosts, feet :: Attachment)
			end
		else
			for _, pn in ipairs(L.on) do
				local p = partOf(model, pn)
				if p then
					table.insert(hosts, p)
				end
			end
		end
		for _, host in ipairs(hosts) do
			local e = Instance.new("ParticleEmitter")
			e.Name = "AchAura"
			e.Texture = L.tex
			e.Color = L.color
			e.Size = sk ~= 1 and scaleSeq(L.size, sk) or L.size
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
			if L.squash then
				e.Squash = L.squash
			end
			if L.orient then
				e.Orientation = L.orient
			end
			e.LockedToPart = false
			e.Parent = host
			table.insert(out, e)
		end
	end
	-- 가슴의 은은한 빛: 둘레를 오라 빛깔로 물들인다
	local gl = GLOW[id]
	local chest = partOf(model, "UpperTorso")
	if gl and chest and not low then
		local l = Instance.new("PointLight")
		l.Name = "AchAuraLight"
		l.Color = gl[1]
		l.Brightness = gl[2]
		l.Range = 11
		l.Shadows = false
		l.Parent = chest
		table.insert(out, l)
	end
	return out
end
local function setOn(model: Model, on: boolean)
	local a = active[model]
	if a then
		for _, e in ipairs(a.emitters) do
			if e:IsA("ParticleEmitter") or e:IsA("Light") then
				(e :: any).Enabled = on
			end
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
		local rs = ribBuild(model, id)
		if rs then
			ribSets[model] = rs
			ribStart()
		end
		formBuild(model, id)
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
