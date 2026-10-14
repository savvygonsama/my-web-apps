-- GameConfig (ModuleScript, ReplicatedStorage)
-- 게임 전체 수치와 데이터. 서버와 클라이언트가 같이 읽는다.
-- 밸런스를 바꾸고 싶으면 이 파일만 고치면 된다.

local Config = {}

Config.GAME_TITLE = "ARENA 100"
Config.VERSION = "beta-1"
Config.MAX_GRADE = 100

------------------------------------------------------------------------
-- 등급 100단계
------------------------------------------------------------------------
Config.Grades = {
	{ en = "Trash", ko = "쓰레기급" },
	{ en = "Noob", ko = "초보자" },
	{ en = "Rookie", ko = "신참" },
	{ en = "Novice", ko = "초심자" },
	{ en = "Trainee", ko = "훈련생" },
	{ en = "Amateur", ko = "아마추어" },
	{ en = "Apprentice", ko = "견습생" },
	{ en = "Brawler", ko = "싸움꾼" },
	{ en = "Fighter", ko = "전투원" },
	{ en = "Scout", ko = "정찰병" },
	{ en = "Soldier", ko = "병사" },
	{ en = "Mercenary", ko = "용병" },
	{ en = "Striker", ko = "공격수" },
	{ en = "Duelist", ko = "결투가" },
	{ en = "Challenger", ko = "도전자" },
	{ en = "Warrior", ko = "전사" },
	{ en = "Gladiator", ko = "검투사" },
	{ en = "Adept", ko = "숙련자" },
	{ en = "Specialist", ko = "전문가" },
	{ en = "Veteran", ko = "베테랑" },
	{ en = "Elite", ko = "정예" },
	{ en = "Knight", ko = "기사" },
	{ en = "Berserker", ko = "광전사" },
	{ en = "Slayer", ko = "학살자" },
	{ en = "Champion", ko = "챔피언" },
	{ en = "Hero", ko = "영웅" },
	{ en = "Master", ko = "달인" },
	{ en = "Grandmaster", ko = "대가" },
	{ en = "Warlord", ko = "전쟁 군주" },
	{ en = "Conqueror", ko = "정복자" },
	{ en = "Juggernaut", ko = "압도적 파괴자" },
	{ en = "Dreadnought", ko = "두려움 모르는 강자" },
	{ en = "Executioner", ko = "처형자" },
	{ en = "Annihilator", ko = "전멸시키는 자" },
	{ en = "Overlord", ko = "최고 지배자" },
	{ en = "Behemoth", ko = "거대한 괴물" },
	{ en = "Leviathan", ko = "거대한 바다 괴물" },
	{ en = "Colossus", ko = "거상" },
	{ en = "Titan", ko = "거신" },
	{ en = "Tyrant", ko = "폭군" },
	{ en = "Dominator", ko = "지배자" },
	{ en = "Imperator", ko = "황제" },
	{ en = "Archon", ko = "통치자" },
	{ en = "Sovereign", ko = "최고 통치자" },
	{ en = "Paragon", ko = "귀감" },
	{ en = "Ascendant", ko = "상승하는 자" },
	{ en = "Exalted", ko = "격상된 존재" },
	{ en = "Invictus", ko = "정복되지 않은 자" },
	{ en = "Demigod", ko = "반신" },
	{ en = "Legendary", ko = "전설급" },
	{ en = "Mythic", ko = "신화적 존재" },
	{ en = "Immortal", ko = "불멸자" },
	{ en = "Eternal", ko = "영원한 존재" },
	{ en = "Revenant", ko = "되돌아온 자" },
	{ en = "Eidolon", ko = "환영" },
	{ en = "Eldritch", ko = "기괴한 초자연적 존재" },
	{ en = "Tenebrous", ko = "어둠에 싸인 존재" },
	{ en = "Abyssal Monarch", ko = "심연의 군주" },
	{ en = "Infernal Regent", ko = "지옥의 섭정" },
	{ en = "Void Hierarch", ko = "공허의 최고 통치자" },
	{ en = "Primordial", ko = "태초의 존재" },
	{ en = "Antediluvian", ko = "태고의 존재" },
	{ en = "Preternatural", ko = "자연을 벗어난 존재" },
	{ en = "Transmundane", ko = "현세를 초월한 자" },
	{ en = "Unfathomable", ko = "헤아릴 수 없는 존재" },
	{ en = "Inexorable", ko = "막을 수 없는 자" },
	{ en = "Immutable", ko = "변하지 않는 존재" },
	{ en = "Numinous", ko = "신비롭고 신성한 존재" },
	{ en = "Celestial", ko = "천상의 존재" },
	{ en = "Seraphic", ko = "세라핌 같은 존재" },
	{ en = "Empyrean", ko = "최고 천상의 존재" },
	{ en = "Hierophant", ko = "신성한 비밀의 해석자" },
	{ en = "Deific", ko = "신과 같은 존재" },
	{ en = "Demiurge", ko = "조물주" },
	{ en = "Apotheosis", ko = "신의 경지" },
	{ en = "Quintessence", ko = "가장 순수한 본질" },
	{ en = "Ineffable", ko = "말로 표현할 수 없는 존재" },
	{ en = "Omniscient", ko = "모든 것을 아는 자" },
	{ en = "Omnipresent", ko = "어디에나 있는 자" },
	{ en = "Omnipotent", ko = "전능한 자" },
	{ en = "Deicide", ko = "신을 죽인 자" },
	{ en = "Sempiternal", ko = "끝없이 지속되는 존재" },
	{ en = "Transcendent", ko = "초월자" },
	{ en = "Extracosmic", ko = "우주 바깥의 존재" },
	{ en = "Singularity", ko = "특이점" },
	{ en = "Cosmogenic", ko = "우주를 낳는 자" },
	{ en = "Archetypal", ko = "근원적 원형" },
	{ en = "Thearch", ko = "신적 지배자" },
	{ en = "Astral Imperator", ko = "별의 황제" },
	{ en = "Cosmic Sovereign", ko = "우주의 절대 지배자" },
	{ en = "Cosmological Apex", ko = "우주의 정점" },
	{ en = "Omnicide", ko = "모든 것을 죽인 자" },
	{ en = "Eschaton", ko = "궁극적 종말" },
	{ en = "Aeon", ko = "영겁의 존재" },
	{ en = "Infinity", ko = "무한" },
	{ en = "The Empyrean Absolutum", ko = "최고 천상의 절대 실재" },
	{ en = "The Omniversal Eschaton", ko = "모든 우주의 궁극적 종말" },
	{ en = "The Ineffable Primordial Sovereign", ko = "말로 표현할 수 없는 태초의 절대 지배자" },
	{ en = "The Transcendent Architect of Eternity", ko = "영원을 설계하는 초월자" },
	{ en = "The Omnipotent Origin Beyond Existence", ko = "존재를 넘어선 전능한 근원" },
}

------------------------------------------------------------------------
-- 구간: 색과 합성 개수가 구간마다 달라진다
------------------------------------------------------------------------
Config.Sections = {
	{ from = 1, to = 20, name = "풋내기", color = Color3.fromRGB(150, 205, 120), mergeCost = 2, scale = 1.0 },
	{ from = 21, to = 40, name = "투기장 강자", color = Color3.fromRGB(80, 165, 255), mergeCost = 3, scale = 1.15 },
	{ from = 41, to = 60, name = "지배자와 전설", color = Color3.fromRGB(190, 110, 255), mergeCost = 4, scale = 1.3 },
	{ from = 61, to = 80, name = "태초와 신성", color = Color3.fromRGB(255, 236, 180), mergeCost = 5, scale = 1.45 },
	{ from = 81, to = 93, name = "우주", color = Color3.fromRGB(90, 225, 255), mergeCost = 6, scale = 1.6 },
	{ from = 94, to = 100, name = "최종", color = Color3.fromRGB(255, 95, 150), mergeCost = 6, scale = 1.8, rainbow = true },
}

------------------------------------------------------------------------
-- 무기 5계열. dmg는 기본 공격력 배율, cooldown은 공격 간격(초)
-- mode: single = 가장 가까운 적 1명, line = 앞쪽 여러 명, around = 내 주위 전부
------------------------------------------------------------------------
-- 모든 무기는 기본 치명타 5%(1.8배). 단검만 30%(2.5배)
Config.WeaponTypes = {
	{ id = 1, name = "대검", desc = "공격력 높음, 느림", dmg = 1.6, cooldown = 0.9, range = 8, mode = "single", critChance = 0.05, critMult = 1.8 },
	{ id = 2, name = "쌍검", desc = "공격 속도 빠름", dmg = 0.55, cooldown = 0.3, range = 7, mode = "single", critChance = 0.05, critMult = 1.8 },
	{ id = 3, name = "장검", desc = "앞쪽으로 길게, 최대 3명", dmg = 1.0, cooldown = 0.6, range = 13, mode = "line", maxTargets = 3, critChance = 0.05, critMult = 1.8 },
	{ id = 4, name = "단검", desc = "치명타 30%, 2.5배", dmg = 0.5, cooldown = 0.4, range = 6, mode = "single", critChance = 0.3, critMult = 2.5 },
	{ id = 5, name = "낫", desc = "주위 한 바퀴 + 흡혈", dmg = 0.75, cooldown = 0.7, range = 10, mode = "around", lifesteal = 0.1, critChance = 0.05, critMult = 1.8 },
}

-- 100등급 다섯 계열을 하나씩 모아 합치면 나오는 최종 무기
Config.AllRounder = {
	id = 0,
	name = "올라운더",
	desc = "다섯 계열의 장점을 모두 가짐",
	dmg = 1.6,
	cooldown = 0.35,
	range = 13,
	mode = "around",
	critChance = 0.3,
	critMult = 2.5,
	lifesteal = 0.1,
}
Config.ALLROUNDER_KEY = "AR"

------------------------------------------------------------------------
-- 필살기: 무기 계열마다 하나. 때릴수록 게이지가 차고, 100이 되면 쓸 수 있다
-- mult는 공격력 배율
------------------------------------------------------------------------
Config.ULT_GAIN = 11 -- 공격 1회당 게이지 = ULT_GAIN × 공격 간격(초). 어떤 무기든 약 9초면 찬다
Config.Ultimates = {
	[1] = { name = "대지 가르기", desc = "앞으로 땅을 갈라 일직선의 적을 모두 벤다", mult = 8, length = 32, width = 6 },
	[2] = { name = "칼날 폭풍", desc = "2.5초 동안 주위를 쉴 새 없이 벤다", mult = 0.6, radius = 10, ticks = 25, interval = 0.1 },
	[3] = { name = "일섬", desc = "앞으로 순간 돌진하며 지나간 자리의 적을 모두 벤다", mult = 7, length = 26, width = 5 },
	[4] = { name = "그림자 처형", desc = "가장 강한 적 뒤로 순간이동해 치명타 5연타", mult = 1, hits = 5 },
	[5] = { name = "영혼 수확", desc = "넓은 원 안의 적을 베고 체력을 크게 회복한다", mult = 5, radius = 18, heal = 0.3 },
	[0] = { name = "천지개벽", desc = "투기장의 모든 적을 베고 체력을 회복한다", mult = 10, heal = 0.3 },
}

------------------------------------------------------------------------
-- 희귀도 5단계. 등급마다 한 칸씩 계열을 돌아가며 바뀐다
------------------------------------------------------------------------
Config.Rarities = {
	{ rank = 1, name = "일반", mult = 1.0, color = Color3.fromRGB(190, 190, 190) },
	{ rank = 2, name = "고급", mult = 1.15, color = Color3.fromRGB(90, 215, 110) },
	{ rank = 3, name = "희귀", mult = 1.3, color = Color3.fromRGB(70, 150, 255) },
	{ rank = 4, name = "영웅", mult = 1.5, color = Color3.fromRGB(185, 95, 255) },
	{ rank = 5, name = "전설", mult = 1.75, color = Color3.fromRGB(255, 170, 40) },
}

-- 등급 하나 오를 때 세기 배율. 전설 배율(1.75)보다 커야 합성이 항상 이득이다
Config.GRADE_GROWTH = 2
Config.BASE_ATK = 10
Config.BASE_HP = 100

Config.TRAIN_BONUS = 0.08 -- 훈련 1레벨당 +8%
Config.AUTO_POWER_RATIO = 1.5 -- 자동 반복: 권장 전투력의 1.5배 이상
Config.STARTER_KEY = "1_5" -- 처음 받는 무기: 1등급 낫(일반)

Config.DASH_COOLDOWN = 1.5
Config.DASH_INVULN = 0.4

------------------------------------------------------------------------
-- 함수
------------------------------------------------------------------------
function Config.getGrade(g)
	return Config.Grades[math.clamp(g, 1, Config.MAX_GRADE)]
end

function Config.getSection(g)
	for i, s in ipairs(Config.Sections) do
		if g >= s.from and g <= s.to then
			return s, i
		end
	end
	return Config.Sections[#Config.Sections], #Config.Sections
end

function Config.mergeCost(g)
	return (Config.getSection(g)).mergeCost
end

-- 1등급: 대검 전설, 쌍검 영웅, 장검 희귀, 단검 고급, 낫 일반
-- 등급이 하나 오를 때마다 한 칸씩 밀린다 (2등급은 낫이 전설)
function Config.rarityRank(g, typeId)
	if typeId == 0 then
		return 5
	end
	return 5 - ((typeId - 1 + g - 1) % 5)
end

function Config.itemKey(g, typeId)
	if typeId == 0 then
		return Config.ALLROUNDER_KEY
	end
	return string.format("%d_%d", g, typeId)
end

-- 키를 등급, 계열로 나눈다. 잘못된 키면 nil
function Config.parseKey(key)
	if type(key) ~= "string" then
		return nil
	end
	if key == Config.ALLROUNDER_KEY then
		return Config.MAX_GRADE, 0
	end
	local gs, ts = string.match(key, "^(%d+)_(%d)$")
	if not gs then
		return nil
	end
	local g, t = tonumber(gs), tonumber(ts)
	if not g or not t or g < 1 or g > Config.MAX_GRADE or t < 1 or t > 5 then
		return nil
	end
	return g, t
end

function Config.weaponType(typeId)
	if typeId == 0 then
		return Config.AllRounder
	end
	return Config.WeaponTypes[typeId]
end

local function growth(g)
	return Config.GRADE_GROWTH ^ (g - 1)
end

-- 무기 하나의 정보
function Config.weaponInfo(key)
	local g, t = Config.parseKey(key)
	if not g then
		return nil
	end
	local wt = Config.weaponType(t)
	local rarity = Config.Rarities[Config.rarityRank(g, t)]
	local grade = Config.getGrade(g)
	local name
	if t == 0 then
		name = "올라운더"
	else
		name = grade.en .. " " .. wt.name
	end
	return {
		key = key,
		grade = g,
		typeId = t,
		type = wt,
		rarity = rarity,
		gradeData = grade,
		name = name,
		atk = Config.BASE_ATK * growth(g) * rarity.mult * wt.dmg,
	}
end

-- 공격 1회 기대 배율 (치명타 포함)
function Config.critFactor(wt)
	local c = wt.critChance or 0
	local m = wt.critMult or 1
	return 1 + c * (m - 1)
end

-- 장착 무기 + 훈련 레벨로 실제 능력치 계산
function Config.playerStats(key, atkLv, hpLv)
	local info = Config.weaponInfo(key) or Config.weaponInfo(Config.STARTER_KEY)
	local wt = info.type
	local atk = info.atk * (1 + Config.TRAIN_BONUS * (atkLv or 0))
	local maxHp = Config.BASE_HP * growth(info.grade) * (1 + Config.TRAIN_BONUS * (hpLv or 0))
	local dps = atk / wt.cooldown * Config.critFactor(wt)
	local power = math.floor(dps * 4 + maxHp * 0.4)
	return {
		weapon = info,
		atk = atk,
		maxHp = maxHp,
		cooldown = wt.cooldown,
		range = wt.range,
		power = power,
	}
end

-- 그 스테이지 등급의 '일반' 무기, 훈련 0일 때의 전투력 (계열 평균)
function Config.recommendedPower(stage)
	return math.floor((Config.BASE_ATK * 1.7 * 4 + Config.BASE_HP * 0.4) * growth(stage))
end

function Config.canAutoRepeat(stage, maxStage, power)
	return stage <= maxStage and power >= Config.recommendedPower(stage) * Config.AUTO_POWER_RATIO
end

-- 스테이지 n: 적 등급도 n. 10스테이지마다 보스
function Config.stageInfo(n)
	local isBoss = (n % 10 == 0)
	local gr = growth(n)
	local count
	if isBoss then
		count = 2
	else
		count = math.min(5, 2 + math.ceil(n / 2))
	end
	local coins = math.floor(20 * 1.6 ^ (n - 1))
	if isBoss then
		coins *= 5
	end
	return {
		stage = n,
		isBoss = isBoss,
		enemyCount = count,
		-- 같은 등급 칼로 싸우면 적 하나에 3~4초, 보스는 15~25초 (일반 칼로 안 피하면 질 수 있음)
		enemyHp = 60 * gr,
		enemyDmg = 1.5 * gr,
		bossHp = 60 * gr * 5,
		bossDmg = 3 * gr,
		slamDmg = 20 * gr,
		coins = coins,
		dropCount = isBoss and 3 or 1,
		bonusDropChance = isBoss and 0 or 0.35,
	}
end

function Config.trainCost(level)
	return math.floor(50 * 1.55 ^ level)
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid" }

function Config.formatNumber(n)
	if n ~= n then
		return "0"
	end
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local i = math.floor(math.log10(n) / 3)
	if i >= #SUFFIXES then
		return string.format("%.2e", n)
	end
	local v = n / 10 ^ (i * 3)
	local s
	if v >= 100 then
		s = string.format("%d", math.floor(v))
	elseif v >= 10 then
		s = string.format("%.1f", math.floor(v * 10) / 10)
	else
		s = string.format("%.2f", math.floor(v * 100) / 100)
	end
	return s .. SUFFIXES[i + 1]
end

return Config
