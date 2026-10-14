-- GameConfig (ModuleScript, ReplicatedStorage)
-- 게임 전체 수치와 데이터. 서버와 클라이언트가 같이 읽는다.
-- 밸런스를 바꾸고 싶으면 이 파일만 고치면 된다.

local Config = {}

Config.GAME_TITLE = "ARENA 100"
Config.VERSION = "beta-2"
Config.MAX_GRADE = 100 -- 무기 등급
Config.MAX_STAGE = 200 -- 스테이지. 101~200은 초월 스테이지

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

-- 테스트 계정: 스튜디오에서 플레이하거나 게임 주인이 들어오면
-- 모든 스테이지가 열리고 코인이 무한이며, 원하는 무기를 바로 받을 수 있다. 기록은 저장하지 않는다.
-- 정식 공개 전에 false로 바꾸면 주인도 일반 계정으로 들어간다
Config.TEST_MODE = true

-- 스킬 강화 단계: 무기 등급 20마다 한 단계 (Lv.1~5). 올라운더는 Lv.5
function Config.skillTier(grade: number, typeId: number): number
	if typeId == 0 then
		return 5
	end
	return math.clamp(1 + (grade - 1) // 20, 1, 5)
end

------------------------------------------------------------------------
-- 무기 스킬: 계열마다 둘 (E, F). 필살기(R)와 따로 쓴다
-- mult는 공격력 배율, cd는 재사용 대기 시간(초)
------------------------------------------------------------------------
Config.SKILL_KEYS = { "E", "F" }
Config.Skills = {
	[1] = { -- 대검
		{ id = "charge", icon = "🐗", name = "파쇄 돌격", desc = "앞으로 돌진해 부딪힌 적을 날리고 2초 기절시킨다", cd = 7, mult = 3, length = 16, width = 4, stun = 2 },
		{ id = "boomerang", icon = "🌀", name = "대검 투척", desc = "회전하는 대검을 던진다. 갈 때와 돌아올 때 모두 벤다", cd = 9, mult = 2.5, range = 24, width = 4.5 },
	},
	[2] = { -- 쌍검
		{ id = "mark", icon = "🎯", name = "표식 연격", desc = "가까운 적에게 표식. 그 적을 6번 베면 표식이 폭발한다", cd = 8, mult = 6, stacks = 6, splash = 3 },
		{ id = "phantom", icon = "👥", name = "잔상 돌파", desc = "적을 꿰뚫고 지나가고, 0.5초 뒤 잔상이 같은 길을 다시 벤다", cd = 7, mult = 2, length = 18, width = 4 },
	},
	[3] = { -- 장검
		{ id = "wave", icon = "🌙", name = "검기 발사", desc = "적을 꿰뚫고 날아가는 초승달 검기", cd = 5, mult = 3, range = 42, width = 5, speed = 70 },
		{ id = "parry", icon = "🛡", name = "반격 자세", desc = "1.2초 동안 막는 자세. 그사이 맞으면 막아 내고 주위를 크게 벤다", cd = 9, mult = 8, window = 1.2, radius = 11 },
	},
	[4] = { -- 단검
		{ id = "poison", icon = "☠", name = "맹독 칼날", desc = "6초 동안 베는 적마다 독이 묻어 계속 피해를 준다", cd = 10, duration = 6, dotMult = 0.3, dotTime = 3 },
		{ id = "smoke", icon = "💨", name = "연막 순보", desc = "연막 속으로 숨어 2초 무적. 다음 공격은 3배 확정 치명타", cd = 9, invuln = 2, mult = 3 },
	},
	[5] = { -- 낫
		{ id = "hook", icon = "⛓", name = "사슬 낚아채기", desc = "앞쪽 적들을 사슬로 끌어당겨 잠깐 기절시킨다", cd = 6, mult = 1.5, range = 24, cone = 0.3, stun = 0.8 },
		{ id = "zone", icon = "💀", name = "망자의 원", desc = "4초 동안 원 안의 적을 계속 베고 나를 치유한다", cd = 11, radius = 12, duration = 4, tickMult = 0.6, heal = 0.03 },
	},
	[0] = { -- 올라운더
		{ id = "rain", icon = "⚔", name = "만검 강림", desc = "하늘에서 검 12자루가 적에게 꽂힌다", cd = 6, mult = 3, count = 12 },
		{ id = "timestop", icon = "⏳", name = "시공 정지", desc = "3초 동안 모든 적의 시간을 멈춘다", cd = 12, duration = 3 },
	},
}

------------------------------------------------------------------------
-- 적 7종. hp와 dmg는 그 스테이지 기준치에 곱하는 배율
-- unlock: 이 스테이지부터 나온다
------------------------------------------------------------------------
Config.EnemyTypes = {
	grunt = { name = "돌격병", hp = 1.0, dmg = 1.0, speed = 13, scale = 1.0, unlock = 1, weight = 4 },
	archer = { name = "궁수", hp = 0.7, dmg = 0.9, speed = 12, scale = 0.95, unlock = 4, weight = 2, keep = 22, shotCd = 2.8 },
	shield = { name = "방패병", hp = 1.6, dmg = 1.0, speed = 9, scale = 1.15, unlock = 8, weight = 2, frontReduce = 0.7 },
	brute = { name = "돌진꾼", hp = 2.0, dmg = 2.2, speed = 10, scale = 1.35, unlock = 12, weight = 1.5, chargeCd = 6 },
	bomber = { name = "자폭병", hp = 0.5, dmg = 3.0, speed = 19, scale = 0.8, unlock = 16, weight = 1.5 },
	shaman = { name = "주술사", hp = 0.8, dmg = 1.6, speed = 10, scale = 1.0, unlock = 21, weight = 1.2, keep = 24, castCd = 4.5 },
	assassin = { name = "암살자", hp = 0.8, dmg = 1.4, speed = 16, scale = 0.95, unlock = 26, weight = 1.2, blinkCd = 5 },
	golem = { name = "골렘", hp = 3.0, dmg = 2.0, speed = 7, scale = 1.6, unlock = 33, weight = 1, poundCd = 5, poundRadius = 10 },
	ghost = { name = "망령", hp = 0.9, dmg = 1.3, speed = 15, scale = 1.0, unlock = 42, weight = 1.2, phaseCd = 4.5, phaseTime = 1.6 },
	splitter = { name = "분열체", hp = 1.2, dmg = 1.1, speed = 12, scale = 1.2, unlock = 52, weight = 1.2, splitCount = 2, splitHp = 0.35 },
	priest = { name = "사제", hp = 0.9, dmg = 1.0, speed = 10, scale = 1.0, unlock = 62, weight = 0.8, keep = 22, healCd = 5, heal = 0.15, healRadius = 22 },
	knight = { name = "흑기사", hp = 2.4, dmg = 1.8, speed = 12, scale = 1.25, unlock = 75, weight = 1, frontReduce = 0.5, comboCd = 6 },
}
Config.ENEMY_ORDER = { "grunt", "archer", "shield", "brute", "bomber", "shaman", "assassin", "golem", "ghost", "splitter", "priest", "knight" }

-- 적을 전체적으로 강하게: 체력·공격력 배율
Config.ENEMY_HP_MULT = 1.35
Config.ENEMY_DMG_MULT = 1.35
Config.BOSS_MULT = 1.3

-- 정예 적: 40스테이지부터 나오고, 특성 하나를 달고 나온다 (체력 1.5배 기본)
Config.EliteAffixes = {
	{ id = "swift", name = "신속", desc = "이동 1.6배", speed = 1.6 },
	{ id = "giant", name = "거대", desc = "체력 2배, 몸 1.3배", hp = 2, scale = 1.3 },
	{ id = "regen", name = "재생", desc = "초당 체력 3% 회복", regen = 0.03 },
	{ id = "fury", name = "광폭", desc = "공격력 1.6배", dmg = 1.6 },
}

-- 보스 번호(스테이지 ÷ 10)마다 쓰는 기술 조합. 11번째 보스부터는 초월 보스
Config.BossPatterns = {
	{ "slam", "charge" },
	{ "slam", "summon" },
	{ "slam", "spin", "charge" },
	{ "slam", "meteor", "summon" },
	{ "slam", "spin", "meteor" },
	{ "slam", "charge", "summon", "meteor" },
	{ "slam", "spin", "charge", "meteor" },
	{ "slam", "spin", "charge", "meteor", "summon" },
	{ "slam", "spin", "nova", "meteor", "summon" },
	{ "slam", "spin", "charge", "nova", "rain" },
	{ "nova", "slam", "rain", "charge" },
	{ "rain", "spin", "nova", "summon" },
	{ "slam", "nova", "charge", "rain", "meteor" },
	{ "spin", "rain", "nova", "summon", "charge" },
	{ "nova", "meteor", "rain", "slam", "spin" },
	{ "rain", "nova", "charge", "summon", "slam", "meteor" },
	{ "nova", "spin", "rain", "charge", "meteor", "summon" },
	{ "rain", "nova", "slam", "spin", "charge", "meteor" },
	{ "nova", "rain", "summon", "slam", "spin", "charge", "meteor" },
	{ "nova", "rain", "summon", "slam", "spin", "charge", "meteor" },
}

------------------------------------------------------------------------
-- 강화: 무기마다 +1 ~ +10. 단계마다 공격력 +10%, 체력 +5%, 모양이 한 단계씩 화려해진다
-- 합성하면 다음 등급 무기는 강화 단계의 절반을 물려받는다
------------------------------------------------------------------------
Config.MAX_ENHANCE = 10
Config.ENHANCE_ATK = 0.1
Config.ENHANCE_HP = 0.05
Config.EnhanceLooks = {
	"빛나는 날끝",
	"칼날 문장 보석",
	"두 줄 룬 홈",
	"가드 지느러미",
	"양면 빛 각인",
	"등날",
	"칼끝 회전 고리",
	"불꽃 등가시",
	"빛의 칼집",
	"황금 왕관과 번개",
}

------------------------------------------------------------------------
-- 아우라와 킬 이펙트: 스테이지를 깨면 열리고 코인으로 산다. 좋을수록 세진다
--   아우라: 공격력·체력 배율 + (4단계부터) 주기적으로 주위 적에게 피해를 주는 파동
--   킬 이펙트: 공격력 배율 + 적을 잡으면 그 자리가 터져 주위 적에게 피해 (연쇄 폭발)
------------------------------------------------------------------------
Config.Auras = {
	{ name = "불씨", desc = "발밑에서 불씨가 피어오른다" },
	{ name = "서리 숨결", desc = "차가운 안개와 얼음 결정" },
	{ name = "정전기", desc = "몸 주위로 작은 번개가 튄다" },
	{ name = "새싹 바람", desc = "잎사귀가 몸을 감싸 돈다" },
	{ name = "그림자 안개", desc = "검은 연기가 발밑을 덮는다" },
	{ name = "여명", desc = "등 뒤로 은은한 빛 원반" },
	{ name = "핏빛 안개", desc = "붉은 안개와 핏방울" },
	{ name = "공허 먼지", desc = "보랏빛 먼지가 빨려 든다" },
	{ name = "별가루", desc = "반짝이는 별이 쏟아진다" },
	{ name = "수정 결정", desc = "수정 조각이 몸을 두른다" },
	{ name = "화염 소용돌이", desc = "불꽃이 나선으로 감아 오른다" },
	{ name = "눈보라 장막", desc = "얼음 칼날이 회오리친다" },
	{ name = "뇌운", desc = "머리 위 먹구름에서 번개" },
	{ name = "세계수 가지", desc = "빛나는 가지가 등에서 뻗는다" },
	{ name = "밤의 망토", desc = "그림자 날개가 펄럭인다" },
	{ name = "천사의 후광", desc = "황금 후광과 빛의 날개" },
	{ name = "혈월", desc = "등 뒤에 붉은 달이 뜬다" },
	{ name = "블랙홀", desc = "발밑에서 모든 것을 삼킨다" },
	{ name = "은하수", desc = "별의 띠가 몸을 감싼다" },
	{ name = "프리즘", desc = "일곱 빛깔 결정 왕관" },
	{ name = "용의 숨결", desc = "용의 날개와 불꽃 기둥" },
	{ name = "절대영도", desc = "얼어붙은 왕관과 빙결 날개" },
	{ name = "뇌신의 분노", desc = "번개 고리와 떠다니는 뇌창" },
	{ name = "생명의 정원", desc = "꽃잎 폭풍과 세계수 날개" },
	{ name = "심연의 눈", desc = "등 뒤에서 거대한 눈이 노려본다" },
	{ name = "대천사의 날개", desc = "날개 두 쌍과 빛의 검 고리" },
	{ name = "진홍의 군주", desc = "핏빛 왕관과 검 여덟 자루" },
	{ name = "사건의 지평선", desc = "검은 고리 세 겹과 빛의 띠" },
	{ name = "초신성", desc = "몸에서 별이 폭발한다" },
	{ name = "무한의 근원", desc = "모든 빛이 모인 궁극의 아우라" },
}

Config.KillFx = {
	{ name = "불꽃 터짐", desc = "적이 불꽃으로 터진다" },
	{ name = "얼음 파편", desc = "얼어붙어 산산조각" },
	{ name = "낙뢰", desc = "하늘에서 번개가 꽂힌다" },
	{ name = "꽃잎 흩날림", desc = "꽃잎이 되어 흩어진다" },
	{ name = "그림자 흡수", desc = "그림자 속으로 빨려 든다" },
	{ name = "빛의 기둥", desc = "빛기둥이 적을 지운다" },
	{ name = "핏빛 초승달", desc = "붉은 초승달이 X자로 벤다" },
	{ name = "공허 붕괴", desc = "작은 블랙홀로 무너진다" },
	{ name = "별 폭죽", desc = "별이 사방으로 터진다" },
	{ name = "수정 감옥", desc = "수정에 갇혔다가 깨진다" },
	{ name = "화산 분출", desc = "바닥이 갈라지며 불기둥" },
	{ name = "빙결 쇄도", desc = "얼음 가시가 원으로 솟는다" },
	{ name = "뇌전 사슬", desc = "번개가 주위 적에게 튄다" },
	{ name = "덩굴 휘감기", desc = "덩굴이 감아 조인다" },
	{ name = "망령의 비명", desc = "해골 유령이 솟아오른다" },
	{ name = "천벌", desc = "하늘에서 빛의 검이 떨어진다" },
	{ name = "피의 분수", desc = "핏빛 분수와 초승달" },
	{ name = "블랙홀", desc = "주위를 빨아들이고 터진다" },
	{ name = "유성우", desc = "유성이 쏟아진다" },
	{ name = "프리즘 굴절", desc = "무지개 빛줄기가 뻗는다" },
	{ name = "용의 불기둥", desc = "나선 불기둥이 솟는다" },
	{ name = "절대영도", desc = "얼음 동상이 되어 부서진다" },
	{ name = "천둥신의 망치", desc = "거대한 망치가 내려친다" },
	{ name = "불사조", desc = "불사조가 날아오른다" },
	{ name = "차원 절단", desc = "공간이 X자로 갈라진다" },
	{ name = "대천사 강림", desc = "날개와 함께 심판의 빛" },
	{ name = "혈월", desc = "붉은 달이 떠올라 터진다" },
	{ name = "사건의 지평선", desc = "검은 고리가 모든 것을 지운다" },
	{ name = "초신성", desc = "별이 폭발하는 대폭발" },
	{ name = "빅뱅", desc = "우주가 다시 태어난다" },
}

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

------------------------------------------------------------------------
-- 스테이지: 1~100은 등급과 같고, 101~200은 초월 스테이지
------------------------------------------------------------------------
Config.BEYOND_GROWTH = 1.065 -- 초월 스테이지 하나당 강해지는 배율
Config.BEYOND_COIN_GROWTH = 1.08

-- 적의 세기 배율 (1스테이지 = 1)
function Config.stageScale(n: number): number
	if n <= Config.MAX_GRADE then
		return growth(n)
	end
	return growth(Config.MAX_GRADE) * Config.BEYOND_GROWTH ^ (n - Config.MAX_GRADE)
end

-- 한 판을 이기면 받는 코인 (보스는 5배)
function Config.stageCoins(n: number): number
	if n <= Config.MAX_GRADE then
		return math.floor(20 * 1.6 ^ (n - 1))
	end
	return math.floor(20 * 1.6 ^ (Config.MAX_GRADE - 1) * Config.BEYOND_COIN_GROWTH ^ (n - Config.MAX_GRADE))
end

-- 생김새에 쓰는 등급. 초월 스테이지는 80~100등급 디자인을 돌려 쓴다
function Config.stageGrade(n: number): number
	if n <= Config.MAX_GRADE then
		return math.max(1, n)
	end
	return 80 + ((n - Config.MAX_GRADE - 1) % 21)
end

function Config.isBeyond(n: number): boolean
	return n > Config.MAX_GRADE
end

-- 스테이지 이름 (영어, 한국어)
function Config.stageName(n: number): (string, string)
	if n <= Config.MAX_GRADE then
		local g = Config.getGrade(n)
		return g.en, g.ko
	end
	local g = Config.getGrade(Config.stageGrade(n))
	return string.format("BEYOND %d", n - Config.MAX_GRADE), string.format("초월 %d층 · %s의 그림자", n - Config.MAX_GRADE, g.ko)
end

------------------------------------------------------------------------
-- 강화, 아우라, 킬 이펙트 수치
------------------------------------------------------------------------
-- 강화 비용: 그 등급 스테이지 한 판 코인 × 0.6 × 1.45^단계
function Config.enhanceCost(grade: number, level: number): number
	return math.floor(Config.stageCoins(grade) * 0.6 * 1.45 ^ level) + 10
end

for k, a in ipairs(Config.Auras) do
	local p = k / #Config.Auras
	a.id = k
	a.motif = ((k - 1) % 10) + 1
	a.unlock = 1 + math.floor((k - 1) * 6.75)
	a.cost = Config.stageCoins(a.unlock) * 6
	a.atk = 1 + 2 * p ^ 1.5 -- 30단계: 공격력 3배
	a.hp = 1 + p ^ 1.5 -- 30단계: 체력 2배
	if k >= 4 then
		a.pulse = {
			interval = math.max(1, 3.2 - k * 0.07),
			radius = 8 + k * 0.4,
			mult = 0.3 + k * 0.05,
		}
	end
end

for k, f in ipairs(Config.KillFx) do
	local p = k / #Config.KillFx
	f.id = k
	f.motif = ((k - 1) % 10) + 1
	f.unlock = math.min(Config.MAX_STAGE, 3 + math.floor((k - 1) * 6.75))
	f.cost = Config.stageCoins(f.unlock) * 6
	f.atk = 1 + 1.5 * p ^ 1.5 -- 30단계: 공격력 2.5배
	f.blast = {
		radius = 6 + k * 0.3,
		mult = 0.5 + k * 0.1,
	}
end

-- 장착 무기 + 훈련 레벨 + 강화·아우라·킬 이펙트로 실제 능력치 계산
-- extra = { enh = 강화 단계, aura = 아우라 단계, kill = 킬 이펙트 단계 }
function Config.playerStats(key, atkLv, hpLv, extra: any?)
	local info = Config.weaponInfo(key) or Config.weaponInfo(Config.STARTER_KEY)
	local wt = info.type
	local x = extra or {}
	local enh = math.clamp(math.floor(tonumber(x.enh) or 0), 0, Config.MAX_ENHANCE)
	local aura = Config.Auras[x.aura or 0]
	local killFx = Config.KillFx[x.kill or 0]
	local atkMul = (1 + Config.ENHANCE_ATK * enh) * (aura and aura.atk or 1) * (killFx and killFx.atk or 1)
	local hpMul = (1 + Config.ENHANCE_HP * enh) * (aura and aura.hp or 1)
	local atk = info.atk * (1 + Config.TRAIN_BONUS * (atkLv or 0)) * atkMul
	local maxHp = Config.BASE_HP * growth(info.grade) * (1 + Config.TRAIN_BONUS * (hpLv or 0)) * hpMul
	local dps = atk / wt.cooldown * Config.critFactor(wt)
	local power = math.floor(dps * 4 + maxHp * 0.4)
	return {
		weapon = info,
		atk = atk,
		maxHp = maxHp,
		cooldown = wt.cooldown,
		range = wt.range,
		power = power,
		enh = enh,
		aura = aura,
		killFx = killFx,
	}
end

-- 저장 기록(또는 서버가 보낸 상태)으로 능력치 계산
function Config.profileStats(p: any, key: string?)
	local k = key or p.equipped
	local enh = (type(p.enh) == "table" and p.enh[k]) or 0
	return Config.playerStats(k, p.atkLv, p.hpLv, { enh = enh, aura = p.aura, kill = p.kill })
end

-- 그 스테이지 등급의 '일반' 무기, 훈련 0일 때의 전투력 (계열 평균)
function Config.recommendedPower(stage)
	return math.floor((Config.BASE_ATK * 1.7 * 4 + Config.BASE_HP * 0.4) * Config.stageScale(stage))
end

function Config.canAutoRepeat(stage, maxStage, power)
	return stage <= maxStage and power >= Config.recommendedPower(stage) * Config.AUTO_POWER_RATIO
end

-- 스테이지마다 같은 구성이 나오도록 고정된 난수 (Park-Miller)
local function seeded(seed: number)
	local s = (seed % 2147483646) + 1
	return function(): number
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local function pickType(pool: { string }, rand: () -> number): string
	local total = 0
	for _, id in ipairs(pool) do
		total += Config.EnemyTypes[id].weight
	end
	local r = rand() * total
	for _, id in ipairs(pool) do
		r -= Config.EnemyTypes[id].weight
		if r <= 0 then
			return id
		end
	end
	return pool[#pool]
end

-- 정예가 나올 확률: 40스테이지부터 점점 늘어난다
function Config.eliteChance(n: number): number
	if n < 40 then
		return 0
	end
	return math.min(0.55, 0.08 + (n - 40) * 0.004)
end

-- 스테이지 n. 10스테이지마다 보스
-- 스테이지가 오를수록 웨이브 수, 웨이브당 적 수, 적 종류, 정예가 늘어난다
function Config.stageInfo(n)
	local isBoss = (n % 10 == 0)
	local gr = Config.stageScale(n)
	local rand = seeded(n * 7919 + 13)

	local pool = {}
	for _, id in ipairs(Config.ENEMY_ORDER) do
		if n >= Config.EnemyTypes[id].unlock then
			table.insert(pool, id)
		end
	end

	local perWave
	if n <= Config.MAX_GRADE then
		perWave = math.min(3 + math.floor(n / 8), 7)
	else
		perWave = math.min(7 + (n - Config.MAX_GRADE) // 25, 10)
	end
	local waveCount
	if isBoss then
		waveCount = n > Config.MAX_GRADE and 3 or 2
	elseif n < 8 then
		waveCount = 1
	elseif n < 35 then
		waveCount = 2
	elseif n < 120 then
		waveCount = 3
	else
		waveCount = 4
	end

	local eliteChance = Config.eliteChance(n)
	local waves = {}
	local elites = {}
	local hpWeight = 0
	for w = 1, waveCount do
		local list = {}
		local eliteList = {}
		local count = (isBoss and w == waveCount) and 2 or perWave
		for i = 1, count do
			local id = pickType(pool, rand)
			-- 새로 열린 적은 그 스테이지에 꼭 한 번 나온다
			if w == 1 and i == 1 then
				for _, nid in ipairs(Config.ENEMY_ORDER) do
					if Config.EnemyTypes[nid].unlock == n then
						id = nid
					end
				end
			end
			list[i] = id
			local weight = Config.EnemyTypes[id].hp
			if rand() < eliteChance then
				local affix = Config.EliteAffixes[math.floor(rand() * #Config.EliteAffixes) + 1]
				eliteList[i] = affix.id
				weight *= 1.5 * (affix.hp or 1)
			end
			hpWeight += weight
		end
		waves[w] = list
		elites[w] = eliteList
	end

	-- 일반 적 전체 체력 예산. 무기 등급이 같으면 한 판에 20~40초
	local budget = 300 * gr * (1 + math.min(n, Config.MAX_GRADE) / 150) * Config.ENEMY_HP_MULT
	local bossNo = math.max(1, n // 10)
	local coins = Config.stageCoins(n)
	if isBoss then
		coins *= 5
	end
	return {
		stage = n,
		grade = Config.stageGrade(n),
		beyond = n > Config.MAX_GRADE,
		isBoss = isBoss,
		waves = waves,
		elites = elites,
		unitHp = budget / hpWeight,
		-- 적이 많을수록 한 명의 공격력을 낮춰 전체 압박을 비슷하게 맞춘다
		unitDmg = 1.5 * gr * math.min(1, 5 / perWave) * Config.ENEMY_DMG_MULT,
		bossHp = 60 * gr * 5 * Config.BOSS_MULT,
		bossDmg = 3 * gr * Config.BOSS_MULT,
		slamDmg = 20 * gr * Config.BOSS_MULT,
		bossType = Config.ENEMY_ORDER[((bossNo - 1) % #Config.ENEMY_ORDER) + 1],
		bossPatterns = Config.BossPatterns[math.clamp(bossNo, 1, #Config.BossPatterns)],
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
