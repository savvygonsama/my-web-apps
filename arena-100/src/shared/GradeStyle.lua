-- GradeStyle (ModuleScript, ReplicatedStorage)
-- 등급 1~100마다 다른 디자인을 정한다. 무기, 캐릭터 오라, 적, 칭호, UI가 모두 이걸 본다.
--
-- 1. 색: 등급마다 황금각만큼 색상을 돌려서 바로 옆 등급끼리도 확 달라 보인다.
--        등급이 오를수록 채도와 밝기가 올라간다
-- 2. 속성: 화염 → 서리 → 번개 → 생명 → 그림자 → 성광 → 선혈 → 공허 → 별빛 → 수정이 등급마다 돌아간다
-- 3. 장식: 등급이 오를 때마다 룬, 가시, 보석, 구슬, 고리, 날개, 빛줄기, 파편, 검 왕관이 하나씩 늘어난다
-- 4. 재질: 녹슨 쇠 → 쇠 → 광택 금속 → 금박 → 유리 → 빛 → 우주 → 겹친 빛

local Style = {}

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

Style.MOTIFS = {
	{ id = "flame", name = "화염", tex = FIRE, a = Color3.fromRGB(255, 110, 30), b = Color3.fromRGB(255, 220, 90), drift = Vector3.new(0, 6, 0) },
	{ id = "frost", name = "서리", tex = SPARKLE, a = Color3.fromRGB(120, 200, 255), b = Color3.fromRGB(235, 250, 255), drift = Vector3.new(0, -2, 0) },
	{ id = "storm", name = "번개", tex = SPARKLE, a = Color3.fromRGB(255, 240, 90), b = Color3.fromRGB(150, 130, 255), drift = Vector3.new(0, 0, 0) },
	{ id = "nature", name = "생명", tex = SPARKLE, a = Color3.fromRGB(80, 220, 90), b = Color3.fromRGB(210, 255, 140), drift = Vector3.new(0, 2, 0) },
	{ id = "shadow", name = "그림자", tex = SMOKE, a = Color3.fromRGB(100, 50, 150), b = Color3.fromRGB(30, 15, 45), drift = Vector3.new(0, 3, 0) },
	{ id = "holy", name = "성광", tex = SPARKLE, a = Color3.fromRGB(255, 235, 170), b = Color3.fromRGB(255, 255, 255), drift = Vector3.new(0, 5, 0) },
	{ id = "blood", name = "선혈", tex = SPARKLE, a = Color3.fromRGB(210, 20, 45), b = Color3.fromRGB(255, 100, 100), drift = Vector3.new(0, -6, 0) },
	{ id = "void", name = "공허", tex = SMOKE, a = Color3.fromRGB(70, 0, 110), b = Color3.fromRGB(190, 90, 255), drift = Vector3.new(0, 1, 0) },
	{ id = "star", name = "별빛", tex = SPARKLE, a = Color3.fromRGB(150, 175, 255), b = Color3.fromRGB(255, 255, 255), drift = Vector3.new(0, 1, 0) },
	{ id = "crystal", name = "수정", tex = SPARKLE, a = Color3.fromRGB(110, 255, 230), b = Color3.fromRGB(255, 170, 240), drift = Vector3.new(0, 2, 0) },
}

Style.RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 230, 110)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 200, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(150, 100, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 200)),
})

-- 재질 단계: 등급이 오를수록 칼날 재질이 바뀐다
local MATERIALS = {
	{ to = 3, blade = Enum.Material.CorrodedMetal, reflect = 0, name = "녹슨 쇠" },
	{ to = 8, blade = Enum.Material.Metal, reflect = 0, name = "쇠" },
	{ to = 14, blade = Enum.Material.Metal, reflect = 0.25, name = "광택 금속" },
	{ to = 20, blade = Enum.Material.Foil, reflect = 0.15, name = "금박" },
	{ to = 27, blade = Enum.Material.Metal, reflect = 0.35, name = "빛 새긴 금속" },
	{ to = 35, blade = Enum.Material.Glass, reflect = 0.2, name = "유리" },
	{ to = 44, blade = Enum.Material.Glass, reflect = 0.35, name = "빛 머금은 유리" },
	{ to = 54, blade = Enum.Material.Ice, reflect = 0.3, name = "얼음 결정" },
	{ to = 64, blade = Enum.Material.Neon, reflect = 0, name = "빛" },
	{ to = 74, blade = Enum.Material.ForceField, reflect = 0, name = "우주" },
	{ to = 84, blade = Enum.Material.ForceField, reflect = 0, name = "겹친 우주" },
	{ to = 93, blade = Enum.Material.Neon, reflect = 0, name = "초월의 빛" },
	{ to = 100, blade = Enum.Material.Neon, reflect = 0, name = "근원의 빛" },
}

local cache: { [number]: any } = {}

local function hsv(h: number, s: number, v: number): Color3
	return Color3.fromHSV(h % 1, math.clamp(s, 0, 1), math.clamp(v, 0, 1))
end

function Style.get(grade: number)
	local g = math.clamp(math.floor(grade), 1, 100)
	local hit = cache[g]
	if hit then
		return hit
	end
	local p = (g - 1) / 99
	local motif = Style.MOTIFS[((g - 1) % #Style.MOTIFS) + 1]

	-- 색: 황금각(0.382)씩 색상을 돌린다
	local hue = (g * 0.381966) % 1
	local primary = hsv(hue, 0.45 + 0.5 * p, 0.78 + 0.22 * p):Lerp(motif.a, 0.35)
	if g <= 3 then
		primary = Color3.fromRGB(150, 95, 60):Lerp(motif.a, 0.15)
	end
	local secondary = motif.b:Lerp(primary, 0.3)
	local glow = primary:Lerp(Color3.new(1, 1, 1), 0.35)

	local mat = MATERIALS[#MATERIALS]
	for _, m in ipairs(MATERIALS) do
		if g <= m.to then
			mat = m
			break
		end
	end

	local s = {
		grade = g,
		power = p,
		motif = motif,
		primary = primary,
		secondary = secondary,
		glow = glow,
		rainbow = g >= 94,
		bladeMaterial = mat.blade,
		reflect = mat.reflect,
		materialName = mat.name,
		-- 크기
		scale = 1 + p * 0.55,
		lengthMul = 1 + p * 0.35,
		widthMul = 1 + p * 0.25,
		-- 장식 개수 (등급이 오를 때마다 하나씩 늘어난다)
		runes = math.min(12, (g + 4) // 5),
		spikes = math.min(8, (g + 3) // 7),
		gems = 1 + math.min(4, g // 20),
		edge = g >= 21,
		halo = g >= 30 and math.min(3, 1 + (g - 30) // 25) or 0, -- 칼날을 두른 빛 고리 수
		wings = g >= 45,
		wingSize = g >= 45 and (1 + (g - 45) / 30) or 0,
		beams = g >= 50,
		auraBlade = g >= 60,
		orbs = g >= 12 and math.min(6, 1 + (g - 12) // 14) or 0,
		shards = g >= 70 and math.min(12, 4 + (g - 70) // 3) or 0,
		crown = g >= 85,
		-- 빛과 입자
		particleRate = 3 + g * 0.45,
		particleSize = 0.18 + p * 0.45,
		lightRange = 5 + g * 0.14,
		lightBrightness = 0.7 + p * 2.3,
		trailLife = 0.16 + p * 0.3,
		fire = motif.id == "flame" and g >= 10,
		smoke = (motif.id == "shadow" or motif.id == "void") and g >= 10,
		sparkles = motif.id == "star" or g >= 40,
		-- 캐릭터 오라
		aura = g >= 3,
		auraRate = 2 + g * 0.3,
		groundRing = g >= 10,
		secondRing = g >= 40,
		bodyOrbs = g >= 20 and math.min(6, 1 + (g - 20) // 12) or 0,
		bodyWings = g >= 65,
		bodyHalo = g >= 80,
		bodyLight = g >= 25,
		-- 적
		enemySpikes = math.min(6, g // 12),
		enemyAura = g >= 8,
	}
	cache[g] = s
	return s
end

-- 색 띠: 등급 고유 두 색, 94등급부터는 무지개
function Style.gradient(grade: number): ColorSequence
	local s = Style.get(grade)
	if s.rainbow then
		return Style.RAINBOW
	end
	return ColorSequence.new(s.primary:Lerp(Color3.new(1, 1, 1), 0.15), s.secondary)
end

-- 글자에 쓰기 좋게 밝힌 색
function Style.textColor(grade: number): Color3
	local s = Style.get(grade)
	local h, sat, v = s.primary:ToHSV()
	return Color3.fromHSV(h, math.min(sat, 0.85), math.max(v, 0.9))
end

return Style
