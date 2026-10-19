-- 권왕(拳王): 맨손의 강호. 서버와 화면이 함께 쓰는 설정
local Config = {}

Config.GAME_TITLE = "권왕"
Config.VERSION = "beta-1"
Config.TEST_MODE = true -- 스튜디오와 게임 주인은 테스트 계정 (기록 저장 안 함)

------------------------------------------------------------------------
-- 싸움의 기본 규칙
-- 흘리기: 막기(F)를 누른 직후 짧은 순간에 맞으면 피해 없이 흘려 내고, 상대 균형이 무너진다
-- 균형: 막히거나 흘려질 때 차오른다. 꽉 차면 파훼(자세 무너짐) → 큰 피해가 들어간다
-- 격돌: 서로 같은 순간에 치면 주먹이 부딪혀 둘 다 튕겨 난다
------------------------------------------------------------------------
Config.DEFLECT_WINDOW = 0.2 -- 흘리기 판정 (초)
Config.BLOCK_DAMAGE = 0.15 -- 막으면 받는 피해 비율
Config.BLOCK_POSTURE = 1.0 -- 막을 때 내 균형에 쌓이는 비율
Config.DEFLECT_POSTURE = 1.3 -- 흘려질 때 공격한 쪽 균형에 쌓이는 비율
Config.DEFLECT_STAGGER = 0.45 -- 흘려진 쪽이 휘청이는 시간
Config.POSTURE_MAX = 100
Config.POSTURE_REGEN = 20 -- 1초에 회복 (마지막으로 맞고 1.2초 뒤부터)
Config.POSTURE_REGEN_DELAY = 1.2
Config.BREAK_STUN = 1.6 -- 파훼되면 움직이지 못하는 시간
Config.BROKEN_MULT = 1.6 -- 파훼된 상대에게 들어가는 피해 배율
Config.CLASH_WINDOW = 0.12 -- 서로 이 시간 안에 치면 격돌
Config.HIT_TOLERANCE = 4.5 -- 화면 판정을 서버가 믿어 주는 거리 여유
Config.COMBO_WINDOW = 0.6 -- 연타가 이어지는 시간
Config.CHI_MAX = 100
Config.CHI_REGEN = 2.5 -- 1초에
Config.CHI_ON_HIT = 0.5 -- 준 피해 1당
Config.CHI_ON_HURT = 0.3 -- 받은 피해 1당
Config.CHI_ON_DEFLECT = 12

-- 이동과 경공
Config.WALK_SPEED = 22
Config.DASH_SPEED = 85
-- 빠를수록 대시가 멀리 간다 (걸음 빠르기 비율만큼, 최대 1.7배)
Config.DASH_SPEED_MAX = 1.7
-- 강타(Z)는 쉬지 않고 연달아 쓸 수 없다
Config.HEAVY_CD = 1.4
-- 오의(G)는 모두 이만큼 더 세다
Config.ULT_MULT = 1.4
-- 사람이 받는 균형 피해 비율 (쉽게 무너지지 않게)
Config.PLAYER_POSTURE_TAKEN = 0.6
Config.DASH_TIME = 0.18
Config.DASH_IFRAMES = 0.22
Config.DASH_CD = 0.55
Config.DOUBLE_JUMP = 58 -- 공중에서 한 번 더 뛰는 힘
Config.RESPAWN_TIME = 4
Config.COMBAT_TAG = 6 -- 싸운 뒤 이 시간 동안은 '전투 중'
-- 자연 회복: 마지막으로 맞고 이만큼 지나면 1초에 최대 체력의 몇 %씩 (마을·사부 자리 같은 안전 지대에선 더 빨리)
Config.REGEN_DELAY = 4
Config.REGEN_RATE = 0.025
Config.REGEN_SAFE_RATE = 0.08

------------------------------------------------------------------------
-- 수련 능력치 4종. 효과는 로그로 완만하게 오른다 (수련 반, 실력 반)
-- 배율 = 1 + 0.3 × ln(1 + 능력치 ÷ 15)  →  100이면 ×1.61, 1000이면 ×2.26, 10000이면 ×2.95
-- 여기에 경지 배율(경지마다 +15%)이 곱해진다
------------------------------------------------------------------------
Config.Stats = {
	{ id = "str", name = "근골", icon = "💪", desc = "주는 피해" },
	{ id = "vit", name = "체력", icon = "❤", desc = "최대 체력" },
	{ id = "agi", name = "경공", icon = "🍃", desc = "이동 속도와 대시" },
	{ id = "chi", name = "내공", icon = "🌀", desc = "내공 회복과 기술 위력" },
}

function Config.statMult(x: number): number
	return 1 + 0.3 * math.log(1 + math.max(0, x) / 15)
end

function Config.maxHp(vit: number): number
	return math.floor(100 * Config.statMult(vit))
end

-- 내공 그릇: 내공 능력치와 경지가 오를수록 커진다 (100 → 최대 500). 오의는 늘 100을 쓴다
function Config.chiMax(chi: number, realm: number): number
	return math.min(500, 100 + math.floor(40 * math.log(1 + math.max(0, chi) / 60)) + 8 * (realm - 1))
end

function Config.walkSpeed(agi: number): number
	return Config.WALK_SPEED * (0.85 + 0.15 * Config.statMult(agi))
end

-- 경지: 능력치 합으로 정해진다 (베타 8: 오르는 데 수련이 1.5배 든다). 경지가 오를 때마다 피해·체력 +15% (경지 배율), 수련 효과 +25%
-- 삼류·일류·특급·사경에 이르면 그 경지의 새 수련이 열린다
Config.Realms = {
	{ name = "삼류", need = 0, color = Color3.fromRGB(200, 200, 200) },
	{ name = "이류", need = 150, color = Color3.fromRGB(150, 220, 150) },
	{ name = "일류", need = 600, color = Color3.fromRGB(110, 190, 255) },
	{ name = "특급", need = 1500, color = Color3.fromRGB(90, 230, 200) },
	{ name = "절정", need = 3300, color = Color3.fromRGB(190, 130, 255) },
	{ name = "초절정", need = 6800, color = Color3.fromRGB(255, 190, 70) },
	{ name = "화경", need = 13000, color = Color3.fromRGB(255, 110, 80) },
	{ name = "현경", need = 23000, color = Color3.fromRGB(120, 255, 230) },
	{ name = "사경", need = 40000, color = Color3.fromRGB(255, 80, 120) },
	{ name = "생사경", need = 64000, color = Color3.fromRGB(255, 255, 255) },
	{ name = "신화경", need = 100000, color = Color3.fromRGB(255, 220, 120) },
	{ name = "천인합일", need = 150000, color = Color3.fromRGB(160, 220, 255) },
	{ name = "무극", need = 230000, color = Color3.fromRGB(255, 150, 255) },
	-- 무극 너머 (허공 균열의 적과 천마를 상대하려면)
	{ name = "반선", need = 350000, color = Color3.fromRGB(200, 255, 255) },
	{ name = "등선", need = 520000, color = Color3.fromRGB(255, 240, 200) },
	{ name = "천외천", need = 750000, color = Color3.fromRGB(255, 255, 160) },
}
-- 경지 배율은 겹으로 쌓인다: 사경까지 경지마다 ×1.22, 그 위로는 ×1.32씩 (후반일수록 크게 뛴다)
-- (일류 ×1.5, 절정 ×2.2, 사경 ×4.9, 무극 ×14.9, 천외천 ×34)
function Config.realmPower(idx: number): number
	return 1.22 ^ (math.min(idx, 9) - 1) * 1.32 ^ math.max(0, idx - 9)
end

function Config.realmOf(total: number): (number, any)
	local idx = 1
	for i, r in ipairs(Config.Realms) do
		if total >= r.need then
			idx = i
		end
	end
	return idx, Config.Realms[idx]
end

------------------------------------------------------------------------
-- 수련 4종 (월드 곳곳). 화면의 박자 맞추기: 완벽 2배, 좋음 1배, 놓침 0
------------------------------------------------------------------------
Config.Training = {
	rock = { name = "바위 들기", stat = "str", icon = "🪨", desc = "고리가 줄어들 때 맞춰 누르세요", base = 1 },
	waterfall = { name = "폭포 명상", stat = "chi", icon = "💧", desc = "숨이 가장 커질 때 누르세요", base = 1 },
	bamboo = { name = "대나무 경공", stat = "agi", icon = "🎋", desc = "빛나는 대나무 고리를 지나가세요", base = 1 },
	dummy = { name = "목인장", stat = "vit", icon = "🪵", desc = "나무팔이 들어오는 순간 흘리세요 (F)", base = 1 },
	-- 경지마다 열리는 수련 (gains = 한 번에 오르는 능력치들, realm = 이 경지부터)
	mabo = { name = "마보 참장", stat = "vit", gains = { vit = 2, str = 1 }, icon = "🧱", desc = "말뚝 위에서 버티세요. 누를 때마다 몸이 오른쪽으로, 가만두면 왼쪽으로 기운다", base = 1, realm = 1 },
	ironpalm = { name = "철사장 수련", stat = "str", gains = { str = 4, vit = 1 }, icon = "🔥", desc = "달군 쇠모래가 튀어 오를 때 내리치세요 (빠르다)", base = 1, realm = 3, period = 1.25 },
	breathing = { name = "운기조식", stat = "chi", gains = { chi = 5, vit = 2 }, icon = "🌀", desc = "기가 몸을 한 바퀴 돌아 가득 찰 때 누르세요", base = 1, realm = 4 },
	simma = { name = "심마 대련", stat = "str", icon = "👁", desc = "마음속의 마귀가 형체를 얻는다. 이기면 모든 능력치가 크게 오른다", base = 1, realm = 9, fight = true, reward = 60 },
}
Config.TRAIN_COOLDOWN = 0.6 -- 한 번 수련하고 다음까지
-- 강화 수련: 박자가 빠르고 판정이 좁지만 얻는 능력치가 세 배. 경지 이류부터
Config.HARD_TRAIN = { mult = 3, realm = 2, period = 1.05, perfect = 0.065, good = 0.14 }
-- 보통 수련 판정 (넓을수록 쉽다)
Config.TRAIN_JUDGE = { period = 1.6, perfect = 0.09, good = 0.2, mabo = 0.38, maboHard = 0.26, ring = 9 }

------------------------------------------------------------------------
-- 권법 7종
-- 기술: pose = Poses 이름, dur = 길이(초), hits = 맞히는 순간들
--   hit = { t, range(앞으로 거리), radius, dmg, posture, stun, kb(밀어냄), up(띄움), aoe(나를 둘러싼 원) }
--   lunge = 시작할 때 앞으로 미끄러지는 거리, armor = 맞아도 안 밀림, iframes = 무적 시간
--   proj = 날아가는 장풍 { speed, life, radius, dmg, posture, stun, kb }
-- combo 4개는 클릭, heavy는 Z, skills.E·R·G (G = 오의, 내공 100)
-- 숙련도: E는 처음부터, R은 숙련 3, G는 숙련 5
------------------------------------------------------------------------
type Hit = { t: number, range: number, radius: number, dmg: number, posture: number, stun: number, kb: number, up: number?, aoe: boolean? }

local function hit(t: number, range: number, radius: number, dmg: number, posture: number, stun: number, kb: number, up: number?, aoe: boolean?): Hit
	return { t = t, range = range, radius = radius, dmg = dmg, posture = posture, stun = stun, kb = kb, up = up, aoe = aoe }
end

Config.Styles = {
	{
		id = "taeheo",
		name = "태허유수권",
		hanja = "太虛流水拳",
		icon = "☯",
		color = Color3.fromRGB(110, 190, 255),
		color2 = Color3.fromRGB(220, 245, 255),
		fx = "water",
		desc = "물처럼 받아 흘리고 되돌려 친다. 흘리기 판정이 넓고, 흘릴 때마다 기류가 쌓여 반탄장이 강해진다.",
		gimmick = "기류: 흘릴 때마다 1 (최대 3). Z 반탄장이 기류만큼 강해진다",
		deflect = 0.32,
		stance = "stance_taeheo",
		combo = {
			{ id = "th1", name = "유수장", pose = "palm_r", dur = 0.36, lunge = 2, hits = { hit(0.14, 5, 3.5, 7, 8, 0.35, 6) } },
			{ id = "th2", name = "회수장", pose = "palm_l", dur = 0.36, lunge = 2, hits = { hit(0.14, 5, 3.5, 7, 8, 0.35, 6) } },
			{ id = "th3", name = "운수", pose = "circle_palm", dur = 0.42, lunge = 1, hits = { hit(0.2, 5, 4.5, 8, 10, 0.4, 8) } },
			{ id = "th4", name = "쌍장추", pose = "double_palm", dur = 0.55, lunge = 3, hits = { hit(0.24, 6, 4, 11, 16, 0.5, 30) } },
		},
		heavy = { id = "thH", name = "반탄장", pose = "tide_push", dur = 0.6, lunge = 2, hits = { hit(0.28, 6, 4.5, 14, 26, 0.6, 45) }, stackDmg = 0.6 },
		skills = {
			E = { id = "thE", name = "유수회선", desc = "0.8초 동안 받아넘기기 자세. 맞으면 저절로 흘리고 되받아친다", pose = "flow_stance", dur = 0.8, cd = 7, chi = 15, counter = 0.8,
				counterHit = { pose = "push_palm", hit = hit(0, 7, 5, 18, 30, 0.8, 40) } },
			R = { id = "thR", name = "선풍기류", desc = "앞에 물의 소용돌이를 3초 남긴다. 둘레의 적을 계속 끌어당기며 균형을 깎는다", pose = "water_spiral", dur = 0.8, cd = 11, chi = 25,
				mech = { kind = "zone", dist = 9, radius = 12, dur = 3, every = 0.4, delay = 0.3, pull = 26, hit = hit(0, 0, 0, 4, 14, 0.3, 0), fx = "water" } },
			G = { id = "thG", name = "만류귀해", desc = "발밑이 호수가 된다. 3초 동안 소용돌이가 둘레의 적을 모두 가운데로 삼키고, 마지막에 물기둥이 솟아 하늘로 쳐올린다", pose = "ult_tide", dur = 1.6, cd = 30, chi = 100, armor = true,
				mech = { kind = "lake", radius = 26, dur = 3, every = 0.3, pull = 36, hit = hit(0, 0, 0, 5, 12, 0.25, 0), geyserRadius = 13, geyser = hit(0, 0, 0, 75, 110, 1.4, 0, 0) } },
		},
	},
	{
		id = "geumgang",
		name = "불괴금강신권",
		hanja = "不壞金剛神拳",
		icon = "🔔",
		color = Color3.fromRGB(255, 200, 80),
		color2 = Color3.fromRGB(255, 245, 200),
		fx = "gold",
		desc = "무너지지 않는 금강의 몸. 공격하는 동안은 맞아도 밀리지 않고 피해도 덜 받는다. 느리지만 한 방이 무겁다.",
		gimmick = "금강체: 공격 중엔 안 밀리고 받는 피해 30% 감소. 대시는 조금 느리다",
		deflect = 0.18,
		armorWhileAttacking = 0.7,
		dashCd = 0.85,
		stance = "stance_geumgang",
		combo = {
			{ id = "gg1", name = "금강권", pose = "vajra_r", dur = 0.5, lunge = 2, hits = { hit(0.22, 5, 3.5, 11, 12, 0.45, 10) } },
			{ id = "gg2", name = "나한권", pose = "vajra_l", dur = 0.5, lunge = 2, hits = { hit(0.22, 5, 3.5, 11, 12, 0.45, 10) } },
			{ id = "gg3", name = "복호권", pose = "elbow_r", dur = 0.55, lunge = 1, hits = { hit(0.26, 5, 4.5, 13, 16, 0.5, 14) } },
			{ id = "gg4", name = "금강추", pose = "hammer_down", dur = 0.7, lunge = 2, hits = { hit(0.34, 5, 5, 18, 28, 0.7, 20, 10) } },
		},
		heavy = { id = "ggH", name = "대력금강장", pose = "buddha_palm", dur = 0.8, lunge = 2, hits = { hit(0.4, 6, 5, 20, 45, 0.8, 50) } },
		skills = {
			E = { id = "ggE", name = "철포삼", desc = "6초 동안 무엇에도 밀리지 않고 받는 피해 절반", pose = "brace", dur = 0.5, cd = 14, chi = 20, buff = { kind = "ironshirt", dur = 6 } },
			R = { id = "ggR", name = "사자후", desc = "앞쪽 부채꼴로 포효한다. 맞은 적은 막기가 깨지고(파훼) 오래 기절한다", pose = "roar", dur = 0.8, cd = 12, chi = 30,
				mech = { kind = "cone", range = 20, angle = 80, delay = 0.32, hit = hit(0, 0, 0, 14, 20, 1.6, 30), guardBreak = true, fx = "gold" } },
			G = { id = "ggG", name = "금강법신", desc = "6초 동안 내 몸이 금빛 거인이 된다: 무엇에도 안 밀리고 받는 피해 절반, 주먹 1.6배에 맞은 자리 둘레까지 울린다. 커지며 땅을 구른다", pose = "ult_buddha", dur = 1.2, cd = 30, chi = 100, armor = true,
				mech = { kind = "giant", dur = 8.5, scale = 2.4, delay = 0.7, radius = 16, hit = hit(0, 0, 0, 40, 60, 1.0, 45, 12) } },
		},
	},
	{
		id = "maehwa",
		name = "매화난무권",
		hanja = "梅花亂舞拳",
		icon = "🌸",
		color = Color3.fromRGB(255, 130, 190),
		color2 = Color3.fromRGB(255, 220, 235),
		fx = "petal",
		desc = "꽃잎이 어지럽게 흩날리는 빠른 연격. 연타를 끊기지 않게 이으면 꽃잎이 쌓이고, 다 차면 만개해 터진다.",
		gimmick = "꽃잎: 1.2초 안에 계속 맞히면 1씩 (최대 20). 20이면 다음 Z 강타가 만개 폭발",
		deflect = 0.2,
		speed = 1.15,
		stance = "stance_maehwa",
		combo = {
			{ id = "mh1", name = "매화일지", pose = "plum_finger_l", dur = 0.26, lunge = 2, hits = { hit(0.1, 5, 3.2, 5, 5, 0.3, 4) } },
			{ id = "mh2", name = "매화이지", pose = "plum_finger_r", dur = 0.26, lunge = 2, hits = { hit(0.1, 5, 3.2, 5, 5, 0.3, 4) } },
			{ id = "mh3", name = "낙화권", pose = "petal_spin", dur = 0.34, lunge = 2, hits = { hit(0.16, 5, 4, 6, 6, 0.35, 6) } },
			{ id = "mh4", name = "매화선퇴", pose = "crescent_kick", dur = 0.42, lunge = 2, hits = { hit(0.2, 6, 4.5, 8, 10, 0.45, 22) } },
		},
		heavy = { id = "mhH", name = "매화일섬", pose = "plum_flash", dur = 0.5, lunge = 14, iframes = 0.2, hits = { hit(0.2, 7, 4, 12, 14, 0.5, 16) }, bloom = { radius = 12, dmg = 30, posture = 40 } },
		skills = {
			E = { id = "mhE", name = "낙화연격", desc = "눈에 보이지 않는 여덟 번의 연타", pose = "petal_flurry", dur = 1.0, cd = 8, chi = 20, lunge = 2,
				hits = { hit(0.12, 5, 4, 3, 4, 0.3, 1), hit(0.22, 5, 4, 3, 4, 0.3, 1), hit(0.32, 5, 4, 3, 4, 0.3, 1), hit(0.42, 5, 4, 3, 4, 0.3, 1),
					hit(0.52, 5, 4, 3, 4, 0.3, 1), hit(0.62, 5, 4, 3, 4, 0.3, 1), hit(0.72, 5, 4, 3, 4, 0.3, 1), hit(0.85, 5, 4.5, 8, 12, 0.5, 25) } },
			R = { id = "mhR", name = "암향표", desc = "향기만 남기고 꿰뚫고 지나간다 (무적). 0.7초 뒤 지나온 길이 꽃잎으로 터진다", pose = "fragrance_step", dur = 0.45, cd = 9, chi = 20, lunge = 22, iframes = 0.45,
				hits = { hit(0.15, 6, 4, 10, 8, 0.4, 6) },
				mech = { kind = "trail", delay = 0.7, count = 5, radius = 6, hit = hit(0, 0, 0, 16, 14, 0.5, 14, 10) } },
			G = { id = "mhG", name = "일순천참", desc = "세상이 멈춘 듯 보이지 않게 둘레의 적 여덟을 꿰뚫고 지나간다. 한 박자 뒤, 모두가 한꺼번에 베인다 (그동안 무적)", pose = "ult_bloom", dur = 1.4, cd = 30, chi = 100, armor = true,
				mech = { kind = "flash", n = 8, range = 30, delay = 0.35, every = 0.07, hit = hit(0, 0, 0, 62, 60, 1.0, 30, 10) } },
		},
	},
	{
		id = "cheonryong",
		name = "천룡파천장",
		hanja = "天龍破天掌",
		icon = "🐉",
		color = Color3.fromRGB(70, 230, 200),
		color2 = Color3.fromRGB(210, 255, 245),
		fx = "dragon",
		desc = "하늘의 용이 하늘을 깨뜨리는 장풍. Z를 누르고 있다 놓으면 모은 만큼 큰 장풍이 날아간다. 멀리서 견제하는 거리 싸움.",
		gimmick = "용기 모으기: Z를 길게 누를수록 장풍이 커진다 (최대 1.5초)",
		deflect = 0.2,
		charge = 1.5,
		stance = "stance_cheonryong",
		combo = {
			{ id = "cr1", name = "용조장", pose = "dragon_claw_r", dur = 0.34, lunge = 2, hits = { hit(0.14, 5, 3.5, 6, 6, 0.3, 6) } },
			{ id = "cr2", name = "용미장", pose = "dragon_claw_l", dur = 0.34, lunge = 2, hits = { hit(0.14, 5, 3.5, 6, 6, 0.3, 6) } },
			{ id = "cr3", name = "잠룡장", pose = "low_palm", dur = 0.4, lunge = 1, hits = { hit(0.18, 5, 4, 7, 8, 0.35, 8) } },
			{ id = "cr4", name = "현룡파", pose = "dragon_wave", dur = 0.5, lunge = 1, proj = { speed = 90, life = 0.35, radius = 4, dmg = 10, posture = 14, stun = 0.5, kb = 28, size = 3 }, hits = {} },
		},
		heavy = { id = "crH", name = "항룡장", pose = "dragon_cannon", dur = 0.55, lunge = 0, proj = { speed = 110, life = 0.6, radius = 4, dmg = 12, posture = 16, stun = 0.5, kb = 30, size = 3 }, hits = {}, chargeMult = 2.2 },
		skills = {
			E = { id = "crE", name = "항룡유회", desc = "꿰뚫고 나아가는 용의 기운 (맞은 적 모두)", pose = "dragon_coil", dur = 0.6, cd = 7, chi = 20,
				proj = { speed = 80, life = 0.7, radius = 6, dmg = 16, posture = 20, stun = 0.6, kb = 35, size = 6, pierce = true }, hits = {} },
			R = { id = "crR", name = "비룡승천", desc = "용처럼 솟구치며 올려 친다 (적을 띄움)", pose = "dragon_rise", dur = 0.7, cd = 9, chi = 20, lunge = 3, jump = 40,
				hits = { hit(0.2, 5, 5, 14, 18, 0.9, 6, 55) } },
			G = { id = "crG", name = "진룡강림", desc = "땅을 뚫고 진짜 용이 솟아올라 적에게 세 번 내리꽂히고, 마지막에 앞으로 용의 숨을 뿜는다", pose = "ult_dragon", dur = 1.7, cd = 30, chi = 100, armor = true,
				mech = { kind = "avatar", look = "dragon", dur = 2.6, strikes = {
					{ t = 0.9, at = "targets", n = 1, radius = 9, hit = hit(0, 0, 0, 38, 40, 0.8, 20, 30) },
					{ t = 1.3, at = "targets", n = 1, radius = 9, hit = hit(0, 0, 0, 38, 40, 0.8, 20, 30) },
					{ t = 1.7, at = "targets", n = 1, radius = 9, hit = hit(0, 0, 0, 38, 40, 0.8, 20, 30) },
					{ t = 2.2, at = "front", dist = 14, radius = 16, hit = hit(0, 0, 0, 60, 80, 1.2, 60) },
				} } },
		},
	},
	{
		id = "muyeong",
		name = "무영귀각",
		hanja = "無影鬼脚",
		icon = "🌑",
		color = Color3.fromRGB(150, 100, 255),
		color2 = Color3.fromRGB(40, 20, 70),
		fx = "shadow",
		desc = "그림자도 없이 들어오는 귀신의 발. 대시를 두 번 할 수 있고, 공중에서 발차기가 이어진다. 뒤에서 차면 치명타.",
		gimmick = "귀영: 대시 2번, 공중 연격, 등 뒤를 차면 피해 1.6배",
		deflect = 0.18,
		backstab = 1.6,
		dashCharges = 2,
		stance = "stance_muyeong",
		combo = {
			{ id = "my1", name = "귀각", pose = "side_kick", dur = 0.34, lunge = 2, hits = { hit(0.14, 6, 3.5, 6, 6, 0.3, 6) } },
			{ id = "my2", name = "선풍각", pose = "roundhouse", dur = 0.38, lunge = 2, hits = { hit(0.17, 6, 4.5, 7, 7, 0.35, 8) } },
			{ id = "my3", name = "후려차기", pose = "back_spin_kick", dur = 0.44, lunge = 2, hits = { hit(0.24, 6, 4.5, 8, 9, 0.4, 10) } },
			{ id = "my4", name = "낙영각", pose = "axe_kick", dur = 0.5, lunge = 2, hits = { hit(0.28, 6, 4, 11, 16, 0.5, 6, 20) } },
		},
		heavy = { id = "myH", name = "귀영낙각", pose = "flying_kick", dur = 0.55, lunge = 12, hits = { hit(0.25, 6, 4.5, 14, 18, 0.6, 30) } },
		skills = {
			E = { id = "myE", name = "그림자 걸음", desc = "가장 가까운 적의 등 뒤로 순간이동해 찬다 (치명타)", pose = "shadow_heel", dur = 0.5, cd = 7, chi = 15, teleport = 26,
				hits = { hit(0.2, 6, 4.5, 12, 14, 0.6, 20) } },
			R = { id = "myR", name = "귀영난각", desc = "공중으로 솟아 회오리처럼 여섯 번 찬다", pose = "tornado_kick", dur = 0.9, cd = 10, chi = 25, jump = 38,
				hits = { hit(0.2, 4, 7, 5, 6, 0.4, 2, 10, true), hit(0.32, 4, 7, 5, 6, 0.4, 2, 10, true), hit(0.44, 4, 7, 5, 6, 0.4, 2, 10, true),
					hit(0.56, 4, 7, 5, 6, 0.4, 2, 10, true), hit(0.68, 4, 7, 5, 6, 0.4, 2, 10, true), hit(0.8, 4, 7.5, 10, 14, 0.6, 30, nil, true) } },
			G = { id = "myG", name = "무영분신", desc = "그림자 분신이 둘레의 적마다 하나씩 나타나 동시에 세 번씩 걷어찬다 (나는 그 자리에서 지휘한다)", pose = "ult_shadow", dur = 1.8, cd = 30, chi = 100, armor = true,
				mech = { kind = "clones", n = 6, range = 32, delay = 0.45, every = 0.08, hitsEach = 3, hit = hit(0, 0, 0, 17, 16, 0.5, 12, 6) } },
		},
	},
	{
		id = "byeokryeok",
		name = "벽력신권",
		hanja = "霹靂神拳",
		icon = "⚡",
		color = Color3.fromRGB(255, 235, 90),
		color2 = Color3.fromRGB(180, 220, 255),
		fx = "lightning",
		desc = "벼락처럼 빠르고 곧은 주먹. 맞힐 때마다 전하가 차오르고, 다 차면 다음 공격에서 번개가 주변으로 튀어 모두 마비시킨다.",
		gimmick = "전하: 맞힐 때마다 1 (최대 5). 5가 되면 다음 공격이 연쇄 번개 (주변 적 마비)",
		deflect = 0.2,
		stance = "stance_byeokryeok",
		combo = {
			{ id = "bk1", name = "섬전권", pose = "thunder_jab", dur = 0.3, lunge = 3, hits = { hit(0.12, 5, 3.5, 7, 7, 0.35, 6) } },
			{ id = "bk2", name = "뇌정권", pose = "thunder_cross", dur = 0.32, lunge = 3, hits = { hit(0.13, 5, 3.5, 7, 7, 0.35, 6) } },
			{ id = "bk3", name = "뇌명각", pose = "knee_strike", dur = 0.38, lunge = 2, hits = { hit(0.17, 6, 4, 8, 8, 0.4, 10) } },
			{ id = "bk4", name = "벽력추", pose = "thunder_hammer", dur = 0.5, lunge = 4, hits = { hit(0.22, 6, 4, 12, 15, 0.55, 30) } },
		},
		heavy = { id = "bkH", name = "벽력일권", pose = "lightning_dash", dur = 0.55, lunge = 18, hits = { hit(0.22, 6, 4.5, 15, 20, 0.6, 35) } },
		skills = {
			E = { id = "bkE", name = "뇌전보", desc = "번개처럼 지그재그로 꺾어 달린다 (무적, 지나간 적 마비)", pose = "zigzag", dur = 0.5, cd = 7, chi = 15, lunge = 20, iframes = 0.45,
				hits = { hit(0.15, 4, 5, 6, 8, 0.8, 4) } },
			R = { id = "bkR", name = "뇌격", desc = "둘레의 적 다섯을 골라 그 머리 위로 벼락을 내리꽂는다 (마비)", pose = "point_sky", dur = 0.8, cd = 11, chi = 25,
				mech = { kind = "targets", n = 5, range = 34, delay = 0.4, stagger = 0.06, radius = 5, hit = hit(0, 0, 0, 20, 18, 1.1, 4), fx = "lightning" } },
			G = { id = "bkG", name = "뇌신화", desc = "몸이 번개가 되어 적에서 적으로 일곱 번 튄다. 닿는 순간마다 벼락이 떨어지고, 마지막에 하늘이 갈라진다", pose = "ult_thunder", dur = 1.8, cd = 30, chi = 100, armor = true,
				mech = { kind = "bolt", n = 7, range = 34, delay = 0.4, every = 0.14, radius = 6, hit = hit(0, 0, 0, 26, 24, 0.8, 10), finalRadius = 18, final = hit(0, 0, 0, 50, 70, 1.2, 40, 15) } },
		},
	},
	{
		id = "chwi",
		name = "취팔선권",
		hanja = "醉八仙拳",
		icon = "🍶",
		color = Color3.fromRGB(240, 150, 60),
		color2 = Color3.fromRGB(255, 220, 160),
		fx = "drunk",
		desc = "술 취한 여덟 신선의 권법. 비틀거리는 몸이 공격을 저절로 피하고, 엉뚱한 각도에서 주먹이 날아든다. 막기는 약하다.",
		gimmick = "취보: 움직이거나 공격하는 중에 25% 확률로 공격을 저절로 피한다. 막을 때 받는 피해는 더 크다",
		deflect = 0.2,
		dodgeChance = 0.25,
		weakBlock = 1.8,
		stance = "stance_chwi",
		combo = {
			{ id = "cw1", name = "취권", pose = "drunk_swing_r", dur = 0.38, lunge = 3, hits = { hit(0.18, 5, 4, 7, 7, 0.35, 8) } },
			{ id = "cw2", name = "도선", pose = "drunk_swing_l", dur = 0.4, lunge = 2, hits = { hit(0.2, 5, 4, 7, 7, 0.35, 8) } },
			{ id = "cw3", name = "철괴리", pose = "drunk_low", dur = 0.42, lunge = 3, hits = { hit(0.22, 5, 4.5, 8, 9, 0.4, 10) } },
			{ id = "cw4", name = "여동빈", pose = "drunk_flop", dur = 0.6, lunge = 4, hits = { hit(0.32, 5, 5, 13, 16, 0.6, 30, 12) } },
		},
		heavy = { id = "cwH", name = "취선도", pose = "headbutt", dur = 0.6, lunge = 9, hits = { hit(0.3, 5, 4.5, 15, 22, 0.7, 35) } },
		skills = {
			E = { id = "cwE", name = "취보", desc = "3초 동안 크게 비틀거려 공격을 60% 피하고, 피할 때마다 되받아친다", pose = "drunk_sway", dur = 0.5, cd = 12, chi = 20, buff = { kind = "sway", dur = 3 } },
			R = { id = "cwR", name = "팔선과해", desc = "앞으로 데굴데굴 구르며 지나가는 적을 모두 차 올린다", pose = "drunk_roll", dur = 0.9, cd = 10, chi = 25, lunge = 16, iframes = 0.35,
				hits = { hit(0.25, 3, 5, 9, 10, 0.4, 8), hit(0.5, 3, 5, 9, 10, 0.4, 8), hit(0.75, 4, 6, 14, 16, 0.6, 10, 30) } },
			G = { id = "cwG", name = "취선굴렁쇠", desc = "불붙은 술독처럼 몸을 말아 적에서 적으로 여섯 번 튕겨 다니며 터진다. 마지막에 술불이 크게 터진다 (그동안 무적)", pose = "drunk_roll", dur = 2.2, cd = 30, chi = 100, armor = true,
				mech = { kind = "pinball", n = 6, range = 30, delay = 0.25, every = 0.3, radius = 7, hit = hit(0, 0, 0, 22, 20, 0.6, 30, 10), finalRadius = 16, final = hit(0, 0, 0, 50, 60, 1.2, 50, 15) } },
		},
	},
}

-- 처음 받는 기본 권법과, 숨겨진 권법 둘 (사부에게 배우지 않는다)
table.insert(Config.Styles, 1, {
	id = "samjae",
	name = "삼재권",
	hanja = "三才拳",
	icon = "👊",
	color = Color3.fromRGB(215, 200, 170),
	color2 = Color3.fromRGB(255, 250, 235),
	fx = "basic",
	grade = "하급",
	starter = true,
	desc = "강호에 나서는 누구나 처음 배우는 기본 권법. 하늘·땅·사람 세 갈래의 바른 주먹. 화려하지 않지만 흐트러지지 않는다.",
	gimmick = "기본: 별다른 장치는 없지만 막기와 흘리기가 안정적이다. 청운 장로에게 받는다",
	deflect = 0.22,
	stance = "stance_base",
	combo = {
		{ id = "sj1", name = "천권", pose = "jab_l", dur = 0.34, lunge = 2, hits = { hit(0.13, 5, 3.5, 5, 6, 0.3, 5) } },
		{ id = "sj2", name = "지권", pose = "punch_r", dur = 0.36, lunge = 2, hits = { hit(0.14, 5, 3.5, 6, 7, 0.32, 6) } },
		{ id = "sj3", name = "인권", pose = "hook_r", dur = 0.42, lunge = 1, hits = { hit(0.2, 5, 4, 7, 8, 0.35, 8) } },
		{ id = "sj4", name = "삼재각", pose = "front_kick", dur = 0.5, lunge = 2, hits = { hit(0.22, 6, 4, 10, 14, 0.5, 26) } },
	},
	heavy = { id = "sjH", name = "정권 지르기", pose = "punch_r_heavy", dur = 0.6, lunge = 2, hits = { hit(0.28, 6, 4.5, 13, 22, 0.6, 35) } },
	skills = {
		E = { id = "sjE", name = "삼재보", desc = "한 걸음에 파고들며 주먹을 꽂는다", pose = "dash_punch", dur = 0.5, cd = 8, chi = 15, lunge = 12, hits = { hit(0.2, 6, 4, 11, 14, 0.45, 22) } },
		R = { id = "sjR", name = "연환삼격", desc = "세 번 이어 치는 연환권", pose = "flurry", dur = 0.8, cd = 10, chi = 20, lunge = 2,
			hits = { hit(0.2, 5, 4, 6, 6, 0.3, 3), hit(0.4, 5, 4, 6, 6, 0.3, 3), hit(0.65, 5, 4.5, 10, 14, 0.5, 24) } },
		G = { id = "sjG", name = "천지인 일권", desc = "하늘·땅·사람의 기를 1초 동안 한 주먹에 모았다가, 앞으로 단 한 번 지른다. 앞의 모든 것이 날아간다", pose = "one_punch", dur = 1.6, cd = 30, chi = 100, armor = true,
		mech = { kind = "onepunch", delay = 1.0, range = 46, angle = 36, hit = hit(0, 0, 0, 120, 220, 1.4, 130, 12) } },
	},
})
table.insert(Config.Styles, {
	id = "mugeuk",
	name = "무극신권",
	hanja = "無極神拳",
	icon = "🌌",
	color = Color3.fromRGB(190, 170, 255),
	color2 = Color3.fromRGB(255, 255, 255),
	fx = "void",
	grade = "전설",
	hidden = true,
	unlockHint = "강호 곳곳에 흩어진 비급 조각 다섯을 모두 모은 자만이 익힌다",
	desc = "끝도 시작도 없는 권. 모든 권법이 하나로 돌아가는 자리. 손이 닿기도 전에 상대의 균형이 무너진다.",
	gimmick = "무극: 모든 타격이 상대 균형을 두 배로 깎고, 흘리기 판정이 넓다",
	deflect = 0.32,
	postureMult = 2,
	stance = "stance_mugeuk",
	combo = {
		{ id = "mg1", name = "허공수", pose = "void_palm_r", dur = 0.32, lunge = 3, hits = { hit(0.12, 6, 4, 11, 12, 0.35, 8) } },
		{ id = "mg2", name = "역류수", pose = "void_palm_l", dur = 0.32, lunge = 3, hits = { hit(0.12, 6, 4, 11, 12, 0.35, 8) } },
		{ id = "mg3", name = "환원장", pose = "void_circle", dur = 0.4, lunge = 2, hits = { hit(0.18, 6, 5, 13, 16, 0.4, 12) } },
		{ id = "mg4", name = "귀일장", pose = "void_push", dur = 0.5, lunge = 3, hits = { hit(0.22, 7, 5, 20, 28, 0.6, 36) } },
	},
	heavy = { id = "mgH", name = "무극장", pose = "void_sink", dur = 0.6, lunge = 3, hits = { hit(0.28, 7, 5.5, 28, 50, 0.8, 50) } },
	skills = {
		E = { id = "mgE", name = "허공격", desc = "빈 허공을 쳐서 멀리 있는 적까지 꿰뚫는다", pose = "void_point", dur = 0.55, cd = 6, chi = 15,
			proj = { speed = 120, life = 0.5, radius = 5, dmg = 22, posture = 30, stun = 0.5, kb = 30, size = 4, pierce = true }, hits = {} },
		R = { id = "mgR", name = "무극회선", desc = "둘레의 모든 것을 한 점으로 끌어당긴 뒤 그 자리에서 터뜨린다", pose = "void_gather", dur = 0.9, cd = 9, chi = 25,
				mech = { kind = "zone", at = "self", radius = 16, dur = 0.9, every = 0.3, delay = 0.1, pull = 40, hit = hit(0, 0, 0, 10, 24, 0.5, 0), fx = "void" } },
		G = { id = "mgG", name = "무극귀일", desc = "세상의 빛깔이 뒤집히고 하늘에 눈이 열린다. 둘레 30칸의 시간이 멈추고, 멈춘 적을 하늘의 손이 한꺼번에 지운다", pose = "ult_void", dur = 1.8, cd = 30, chi = 100, armor = true,
				mech = { kind = "freeze", delay = 0.5, radius = 30, dur = 2.2, hitAt = 1.3, hit = hit(0, 0, 0, 80, 300, 1.0, 50, 20) } },
	},
})
table.insert(Config.Styles, {
	id = "hyeolma",
	name = "혈마신수",
	hanja = "血魔神手",
	icon = "🩸",
	color = Color3.fromRGB(210, 30, 45),
	color2 = Color3.fromRGB(255, 130, 130),
	fx = "blood",
	grade = "절세",
	hidden = true,
	unlockHint = "혈교의 주인 혈마를 쓰러뜨린 자에게 그 손이 넘어간다",
	desc = "혈교의 주인이 쓰던 마공. 손톱 끝에 피의 기운이 맺힌다. 베어 낸 만큼 내 몸이 살아난다.",
	gimmick = "흡혈: 준 피해의 8%만큼 체력을 되찾는다",
	deflect = 0.2,
	lifesteal = 0.08,
	stance = "stance_hyeolma",
	combo = {
		{ id = "hm1", name = "혈조", pose = "blood_claw_r", dur = 0.3, lunge = 3, hits = { hit(0.12, 5, 4, 10, 9, 0.3, 6) } },
		{ id = "hm2", name = "역조", pose = "blood_claw_l", dur = 0.34, lunge = 3, hits = { hit(0.15, 5, 4, 10, 9, 0.3, 6) } },
		{ id = "hm3", name = "혈영수", pose = "blood_rake", dur = 0.4, lunge = 2, hits = { hit(0.18, 5, 4.5, 12, 12, 0.35, 10) } },
		{ id = "hm4", name = "혈마조", pose = "blood_lunge", dur = 0.5, lunge = 6, hits = { hit(0.2, 6, 4.5, 20, 22, 0.55, 30) } },
	},
	heavy = { id = "hmH", name = "혈수천강", pose = "blood_crush", dur = 0.65, lunge = 3, hits = { hit(0.3, 6, 6, 28, 34, 0.8, 40, 10, true) } },
	skills = {
		E = { id = "hmE", name = "혈영보", desc = "피의 그림자가 되어 적을 꿰뚫고 지나간다 (무적)", pose = "blood_phantom", dur = 0.45, cd = 7, chi = 15, lunge = 24, iframes = 0.4,
			hits = { hit(0.15, 6, 4, 18, 18, 0.5, 10) } },
		R = { id = "hmR", name = "혈해", desc = "발밑에 피의 바다를 4초 펼친다. 안의 적을 계속 베고, 벨 때마다 내 체력이 돌아온다", pose = "blood_spread", dur = 0.9, cd = 12, chi = 25,
				mech = { kind = "zone", at = "self", radius = 14, dur = 4, every = 0.5, delay = 0.3, heal = 0.012, hit = hit(0, 0, 0, 7, 6, 0.2, 0), fx = "blood" } },
		G = { id = "hmG", name = "혈마강림", desc = "등 뒤로 거대한 혈마의 허상이 솟아 손톱으로 적들을 네 번 찢고 포효한다. 그 뒤 8초 광란 (동작 ×1.2, 흡혈 세 배)", pose = "ult_blood", dur = 1.8, cd = 30, chi = 100, armor = true, buff = { kind = "frenzy", dur = 8 },
				mech = { kind = "avatar", look = "demon", dur = 4.2, strikes = {
					{ t = 0.9, at = "targets", n = 3, radius = 8, hit = hit(0, 0, 0, 30, 28, 0.7, 30) },
					{ t = 1.5, at = "targets", n = 3, radius = 8, hit = hit(0, 0, 0, 30, 28, 0.7, 30) },
					{ t = 2.1, at = "targets", n = 3, radius = 8, hit = hit(0, 0, 0, 30, 28, 0.7, 30) },
					{ t = 2.7, at = "targets", n = 3, radius = 8, hit = hit(0, 0, 0, 30, 28, 0.7, 30) },
					{ t = 3.5, at = "around", radius = 22, hit = hit(0, 0, 0, 66, 90, 1.2, 60, 12) },
				} } },
	},
})
-- 시크릿 권법: 무극의 경지에 오른 자만 숨은 사부를 찾아 익힌다 (지도에 나오지 않는다)
table.insert(Config.Styles, {
	id = "gaecheon",
	name = "천제신권",
	hanja = "天帝神拳",
	icon = "👑",
	color = Color3.fromRGB(255, 210, 110),
	color2 = Color3.fromRGB(190, 225, 255),
	fx = "celestial",
	grade = "천외",
	hidden = true,
	secret = true,
	realmReq = 13,
	unlockHint = "무극의 경지에 오른 자만이 이름 없는 노인을 만난다. 강호의 끝, 아무도 가지 않는 구석에서",
	desc = "하늘의 임금이 땅에 남긴 주먹. 손이 닿는 곳마다 하늘의 검이 따라 내린다. 이 권을 쓰는 자의 머리 위로는 늘 하늘의 문이 열려 있다.",
	gimmick = "천위: 다섯 번 맞힐 때마다 하늘에서 빛의 검이 떨어져 둘레를 친다. 흘리기 판정이 넓고 균형을 1.5배로 깎는다",
	deflect = 0.3,
	postureMult = 1.5,
	starEvery = 5,
	stance = "stance_gaecheon",
	combo = {
		{ id = "gc1", name = "천제권", pose = "star_punch_r", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4, 13, 12, 0.35, 8) } },
		{ id = "gc2", name = "역천권", pose = "star_punch_l", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4, 13, 12, 0.35, 8) } },
		{ id = "gc3", name = "천월각", pose = "heaven_kick", dur = 0.42, lunge = 2, hits = { hit(0.24, 6, 5.5, 16, 16, 0.4, 14) } },
		{ id = "gc4", name = "천광장", pose = "galaxy_palm", dur = 0.5, lunge = 3, hits = { hit(0.28, 8, 6, 24, 30, 0.6, 40) } },
	},
	heavy = { id = "gcH", name = "천검일섬", pose = "heaven_split", dur = 0.7, lunge = 6, hits = { hit(0.36, 9, 7, 38, 60, 0.9, 50, 10, true) } },
	skills = {
		E = { id = "gcE", name = "천검강림", desc = "둘레의 적 셋 위로 하늘에서 빛의 검을 꽂는다", pose = "meteor_drop", dur = 0.9, cd = 7, chi = 20, jump = 40,
			mech = { kind = "targets", n = 3, range = 30, delay = 0.45, stagger = 0.1, radius = 6, hit = hit(0, 0, 0, 30, 30, 0.7, 20, 8), fx = "sword" } },
		R = { id = "gcR", name = "천제의 창", desc = "등 뒤에 하늘의 문이 열리고, 빛의 창이 앞으로 한 줄 쏟아져 꿰뚫는다", pose = "starfall", dur = 1.1, cd = 10, chi = 30,
			mech = { kind = "line", count = 9, start = 4, spacing = 4.2, step = 0.05, delay = 0.5, radius = 5.5, hit = hit(0, 0, 0, 22, 24, 0.5, 20), fx = "spear" } },
		G = { id = "gcG", name = "만검천벌", desc = "하늘이 열려 천 자루의 빛의 검이 내려다본다. 적마다 검이 꽂히고, 마지막에 거대한 하늘의 검이 내리꽂혀 터진다", pose = "ult_heaven", dur = 2.0, cd = 28, chi = 100, armor = true,
			mech = { kind = "swords", dur = 2.6, n = 10, range = 30, delay = 0.6, stagger = 0.08, radius = 6, hit = hit(0, 0, 0, 24, 24, 0.5, 10), bigAt = 1.5, bigRadius = 16, big = hit(0, 0, 0, 110, 150, 1.4, 60, 20) } },
	},
})
-- 극강: 파천신권 (천마를 꺾은 자에게). 하늘을 부수는 중력의 주먹
table.insert(Config.Styles, {
	id = "pacheon",
	name = "파천신권",
	hanja = "破天神拳",
	icon = "🌑",
	color = Color3.fromRGB(150, 90, 255),
	color2 = Color3.fromRGB(255, 205, 110),
	fx = "gravity",
	grade = "천외",
	hidden = true,
	unlockHint = "강호의 마지막 적, 천마를 쓰러뜨린 자만이 하늘을 삼킨 그 힘을 거꾸로 쥔다",
	desc = "천마가 하늘을 삼킨 힘을 꺾어 거꾸로 쥔 주먹. 주먹이 닿는 곳의 무게가 열 배가 되고, 마지막에는 하늘에 검은 해를 띄워 모든 것을 끌어당겨 으스러뜨린다.",
	gimmick = "중압: 여섯 번 맞힐 때마다 상대 자리에 중력 우물이 열려 둘레의 적을 끌어당겨 바닥에 짓누른다. 맞힌 적은 잠깐 느려진다",
	deflect = 0.25,
	postureMult = 1.45,
	pulse = { every = 6, kind = "gravity", radius = 13, delay = 0.35, pull = 34, name = "중력 우물", dmg = 30, posture = 40, stun = 0.9, kb = 0, up = -10 },
	stance = "stance_gravity",
	combo = {
		{ id = "pc1", name = "중력권", pose = "grav_press_r", dur = 0.3, lunge = 3, hits = { hit(0.13, 6, 4.5, 15, 14, 0.35, 6) } },
		{ id = "pc2", name = "역중권", pose = "grav_press_l", dur = 0.3, lunge = 3, hits = { hit(0.13, 6, 4.5, 15, 14, 0.35, 6) } },
		{ id = "pc3", name = "천근각", pose = "grav_stomp", dur = 0.42, lunge = 2, hits = { hit(0.22, 6, 6, 18, 20, 0.45, 4, -6) } },
		{ id = "pc4", name = "추성장", pose = "grav_hammer", dur = 0.5, lunge = 3, hits = { hit(0.26, 7, 7, 26, 32, 0.6, 30) } },
	},
	heavy = { id = "pcH", name = "흑성추", pose = "grav_meteor", dur = 0.8, lunge = 5, hits = { hit(0.42, 9, 9, 44, 70, 1.0, 20, -8, true) } },
	skills = {
		E = { id = "pcE", name = "인력장", desc = "앞에 중력 우물을 연다. 1.2초 동안 둘레의 적을 한가운데로 빨아들이며 짓누른다", pose = "grav_pull", dur = 0.7, cd = 7, chi = 20,
			mech = { kind = "zone", dist = 10, radius = 12, dur = 1.2, every = 0.3, delay = 0.25, pull = 40, hit = hit(0, 0, 0, 9, 14, 0.5, 0), fx = "gravity" } },
		R = { id = "pcR", name = "천근추", desc = "가장 가까운 적 위로 몸이 천 근 무게가 되어 떨어진다. 떨어진 자리가 움푹 꺼진다", pose = "grav_drop", dur = 1.0, cd = 10, chi = 30, jump = 45,
			mech = { kind = "drop", range = 28, radius = 13, delay = 0.55, hit = hit(0, 0, 0, 46, 60, 1.0, 10, -12), fx = "gravity" } },
		G = { id = "pcG", name = "흑일강림", desc = "주먹으로 하늘을 찢어 검은 해를 띄운다. 검은 해가 둘레의 모든 적을 하늘로 끌어올려 짓이기고, 마지막에 안으로 무너지며 터진다", pose = "ult_gravity", dur = 2.2, cd = 30, chi = 100, armor = true,
			mech = { kind = "blackhole", dist = 12, radius = 30, height = 16, delay = 0.7, dur = 2.6, every = 0.2, hit = hit(0, 0, 0, 7, 8, 0.3, 0), final = hit(0, 0, 0, 120, 160, 1.4, 70, 18) } },
	},
})
-- 궁극: 태초신권 (천외천의 경지에 오른 자만, 천외봉의 시원자에게). 세상이 처음 열리던 때의 주먹
table.insert(Config.Styles, {
	id = "taecho",
	name = "태초신권",
	hanja = "太初神拳",
	icon = "✴",
	color = Color3.fromRGB(255, 245, 215),
	color2 = Color3.fromRGB(140, 200, 255),
	fx = "origin",
	grade = "태초",
	hidden = true,
	secret = true,
	realmReq = 16,
	trialHp = 10, -- 시험의 분신 체력 열 배
	unlockHint = "천외천의 경지에 오른 자만이 하늘 끝 봉우리, 천외봉의 시원자를 만난다",
	desc = "하늘과 땅이 갈라지기 전, 세상이 처음 열리던 그 한순간을 담은 주먹. 이 권을 쓰는 자는 땅을 딛지 않고 떠 있으며, 마지막 한 주먹에 세상이 유리처럼 깨졌다가 다시 맞춰진다.",
	gimmick = "창세: 네 번 맞힐 때마다 상대 자리에 빛의 결정이 피어나 터진다. 모든 기술 대기 20% 짧음, 몸이 땅에서 떠 있다",
	deflect = 0.3,
	postureMult = 1.6,
	speed = 1.08,
	cdMult = 0.8,
	pulse = { every = 4, kind = "prism", radius = 11, delay = 0.25, name = "창세 결정", dmg = 34, posture = 36, stun = 0.6, kb = 24, up = 10 },
	stance = "stance_origin",
	combo = {
		{ id = "tc1", name = "일원장", pose = "origin_palm_r", dur = 0.28, lunge = 3, hits = { hit(0.11, 6, 4.5, 17, 14, 0.35, 8) } },
		{ id = "tc2", name = "양의장", pose = "origin_palm_l", dur = 0.28, lunge = 3, hits = { hit(0.11, 6, 4.5, 17, 14, 0.35, 8) } },
		{ id = "tc3", name = "삼재각", pose = "origin_kick", dur = 0.4, lunge = 2, hits = { hit(0.2, 6, 6, 20, 20, 0.45, 18) } },
		{ id = "tc4", name = "사상권", pose = "origin_punch", dur = 0.46, lunge = 3, hits = { hit(0.2, 8, 5, 26, 30, 0.55, 30) } },
	},
	heavy = { id = "tcH", name = "개천일권", pose = "origin_strike", dur = 0.75, lunge = 4, hits = { hit(0.4, 16, 6, 52, 80, 1.0, 60) } },
	skills = {
		E = { id = "tcE", name = "성운보", desc = "빛이 되어 둘레의 적 사이를 다섯 번 건너뛰며 친다 (그동안 무적)", pose = "origin_step", dur = 0.9, cd = 7, chi = 20,
			mech = { kind = "chainTp", n = 5, range = 30, delay = 0.1, every = 0.14, hit = hit(0, 0, 0, 16, 16, 0.4, 12) } },
		R = { id = "tcR", name = "창세주", desc = "둘레의 적 다섯 아래에서 빛의 결정 기둥이 솟아 하늘로 띄운다", pose = "origin_rise", dur = 1.0, cd = 10, chi = 30,
			mech = { kind = "targets", n = 5, range = 34, delay = 0.4, stagger = 0.08, radius = 7, hit = hit(0, 0, 0, 30, 30, 0.7, 10, 22), fx = "prism" } },
		G = { id = "tcG", name = "천지개벽", desc = "세상이 멈추고 하늘과 땅이 별바다로 바뀐다. 주먹을 쥐면 세상에 금이 가고, 내지르면 세상이 유리처럼 깨지며 모든 적이 함께 부서진다", pose = "ult_origin", dur = 3.0, cd = 34, chi = 100, armor = true,
			mech = { kind = "genesis", radius = 60, freeze = 2.6, crackAt = 1.6, breakAt = 2.5, final = hit(0, 0, 0, 180, 240, 1.6, 50, 26) } },
	},
})
-- 정점: 일월신권 (태초신권을 익힌 천외천의 고수만, 일월대의 권존에게). 해와 달을 두 손에 쥔 주먹
table.insert(Config.Styles, {
	id = "ilwol",
	name = "일월신권",
	hanja = "日月神拳",
	icon = "☀",
	color = Color3.fromRGB(255, 185, 60),
	color2 = Color3.fromRGB(205, 220, 255),
	fx = "eclipse",
	grade = "지존",
	hidden = true,
	secret = true,
	realmReq = 16,
	styleReq = "taecho",
	trialHp = 16, -- 시험의 분신 체력 열여섯 배
	unlockHint = "태초신권을 익힌 천외천의 고수만이 세상 동남쪽 끝 일월대에서 권존을 만난다",
	desc = "권법의 정점. 오른손에 해를, 왼손에 달을 쥐었다. 낮에는 해처럼 태우고 밤에는 달처럼 베며, 마지막 한 수에 해와 달을 하나로 겹쳐 하늘을 일식으로 덮는다.",
	gimmick = "일월: 세 번 맞힐 때마다 해와 달이 번갈아 떨어진다 (해는 터지고, 달은 벤다). 낮에는 주는 피해 +15%, 밤에는 받는 피해 -15%. 모든 기술 대기 25% 짧음",
	deflect = 0.32,
	postureMult = 1.7,
	speed = 1.1,
	cdMult = 0.75,
	sunMoon = { day = 1.15, night = 0.85 },
	pulse = { every = 3, kind = "eclipse", radius = 12, delay = 0.3, name = "일월", dmg = 40, posture = 40, stun = 0.6, kb = 20, up = 8 },
	stance = "stance_sunmoon",
	combo = {
		{ id = "iw1", name = "일출장", pose = "sun_palm_r", dur = 0.28, lunge = 3, hits = { hit(0.11, 6, 4.5, 19, 15, 0.35, 8) } },
		{ id = "iw2", name = "월하장", pose = "moon_palm_l", dur = 0.28, lunge = 3, hits = { hit(0.11, 6, 4.5, 19, 15, 0.35, 8) } },
		{ id = "iw3", name = "일륜각", pose = "sun_wheel", dur = 0.42, lunge = 2, hits = { hit(0.22, 6, 6, 23, 22, 0.45, 18, 6) } },
		{ id = "iw4", name = "월인권", pose = "moon_seal", dur = 0.48, lunge = 3, hits = { hit(0.24, 9, 5.5, 30, 34, 0.6, 34) } },
	},
	heavy = { id = "iwH", name = "일월합벽", pose = "eclipse_push", dur = 0.75, lunge = 4, hits = { hit(0.42, 14, 7, 60, 90, 1.0, 60, 10, true) } },
	skills = {
		E = { id = "iwE", name = "만월참", desc = "보름달만 한 빛의 초승달을 던진다. 앞의 모든 적을 꿰뚫고 벤다", pose = "moon_throw", dur = 0.6, cd = 6, chi = 20,
			proj = { speed = 110, life = 0.55, radius = 7, dmg = 40, posture = 40, stun = 0.5, kb = 26, size = 6, pierce = true }, hits = {} },
		R = { id = "iwR", name = "대일강림", desc = "둘레의 적 여섯 머리 위로 작은 해가 떨어져 불기둥이 되어 터진다", pose = "sun_call", dur = 1.0, cd = 9, chi = 30,
			mech = { kind = "targets", n = 6, range = 36, delay = 0.45, stagger = 0.07, radius = 8, hit = hit(0, 0, 0, 36, 34, 0.7, 14, 12), fx = "sun" } },
		G = { id = "iwG", name = "일월동천", desc = "하늘이 밤이 되고 해와 달이 함께 떠오른다. 달빛이 둘레를 베고, 해와 달이 겹쳐 일식이 되면 검은 해의 빛살이 모든 적을 꿰뚫은 뒤, 새벽처럼 터진다", pose = "ult_eclipse", dur = 3.4, cd = 34, chi = 100, armor = true,
			mech = { kind = "eclipse", radius = 60, slashes = 5, slashFrom = 0.6, slashEvery = 0.24, slash = hit(0, 0, 0, 16, 16, 0.4, 0),
				bindAt = 1.9, eclipseAt = 2.0, beamAt = 2.55, beam = hit(0, 0, 0, 70, 60, 0.9, 0, 10), finalAt = 3.2, final = hit(0, 0, 0, 220, 280, 1.8, 70, 30) } },
	},
})
-- 중간: 풍신각 (풍신대의 풍백에게)
table.insert(Config.Styles, {
	id = "pungsin",
	name = "풍신각",
	hanja = "風神脚",
	icon = "🌪",
	color = Color3.fromRGB(140, 235, 200),
	color2 = Color3.fromRGB(240, 255, 250),
	fx = "wind",
	grade = "최상급",
	desc = "바람을 차는 다리. 잡을 수도 막을 수도 없는 바람처럼 들어갔다 빠진다. 발끝이 지나간 자리에 바람의 칼이 남는다.",
	gimmick = "질풍: 대시 대기가 짧고(0.6초), 발차기가 바람을 일으켜 더 멀리 날린다 (밀어냄 1.3배)",
	deflect = 0.2,
	dashCd = 0.6,
	speed = 1.08,
	kbMult = 1.3,
	stance = "stance_gale",
	combo = {
		{ id = "ps1", name = "질풍각", pose = "gale_snap", dur = 0.28, lunge = 3, hits = { hit(0.11, 6, 4, 7, 7, 0.3, 10) } },
		{ id = "ps2", name = "선풍후각", pose = "gale_hook", dur = 0.36, lunge = 2, hits = { hit(0.17, 6, 4.5, 8, 8, 0.35, 12) } },
		{ id = "ps3", name = "쌍비각", pose = "gale_double", dur = 0.44, lunge = 3, hits = { hit(0.14, 6, 4, 6, 6, 0.3, 6, 8), hit(0.28, 6, 4.5, 8, 8, 0.35, 10, 12) } },
		{ id = "ps4", name = "회선풍", pose = "gale_cyclone", dur = 0.5, lunge = 2, hits = { hit(0.24, 0, 8, 12, 14, 0.5, 30, nil, true) } },
	},
	heavy = { id = "psH", name = "풍인각", pose = "gale_blast", dur = 0.6, lunge = 0, proj = { speed = 100, life = 0.5, radius = 5, dmg = 20, posture = 22, stun = 0.6, kb = 40 } },
	skills = {
		E = { id = "psE", name = "질풍보", desc = "바람처럼 꿰뚫고 지나간다 (무적). 지나간 길에 바람의 칼이 남았다 베어 낸다", pose = "gale_dash", dur = 0.45, cd = 7, chi = 15, lunge = 24, iframes = 0.4,
			hits = { hit(0.15, 6, 4, 12, 10, 0.4, 20) },
			mech = { kind = "trail", delay = 0.4, count = 4, radius = 6, hit = hit(0, 0, 0, 14, 12, 0.4, 16, 8) } },
		R = { id = "psR", name = "회오리", desc = "앞에 회오리를 2.5초 세운다. 둘레의 적을 빨아들이며 계속 벤다", pose = "gale_spin", dur = 0.9, cd = 11, chi = 25,
			mech = { kind = "zone", dist = 9, radius = 11, dur = 2.5, every = 0.3, delay = 0.3, pull = 24, hit = hit(0, 0, 0, 5, 8, 0.3, 0), fx = "wind" } },
		G = { id = "psG", name = "풍신강림", desc = "거대한 회오리가 일어 앞으로 나아가며 모든 적을 빨아올리고, 끝에서 사방으로 내던진다", pose = "ult_gale", dur = 1.6, cd = 30, chi = 100, armor = true,
			mech = { kind = "tornado", dist = 8, speed = 10, dur = 3.2, every = 0.2, radius = 13, hit = hit(0, 0, 0, 6, 6, 0.3, 0), final = hit(0, 0, 0, 45, 60, 1.0, 0, 0) } },
	},
})
-- 권법 등급: 높을수록 같은 숙련에서 더 세다 (여덟 단계)
Config.GRADE_ORDER = { "하급", "중급", "상급", "최상급", "절세", "전설", "신화", "천외", "태초", "지존" }
Config.GRADES = { ["하급"] = 0.85, ["중급"] = 1.0, ["상급"] = 1.15, ["최상급"] = 1.3, ["절세"] = 1.45, ["전설"] = 1.65, ["신화"] = 1.9, ["천외"] = 2.25, ["태초"] = 2.6, ["지존"] = 3.0 }
Config.GRADE_COLOR = {
	["하급"] = Color3.fromRGB(190, 190, 190),
	["중급"] = Color3.fromRGB(140, 220, 140),
	["상급"] = Color3.fromRGB(120, 190, 255),
	["최상급"] = Color3.fromRGB(90, 230, 230),
	["절세"] = Color3.fromRGB(220, 130, 255),
	["전설"] = Color3.fromRGB(255, 200, 80),
	["신화"] = Color3.fromRGB(255, 120, 90),
	["천외"] = Color3.fromRGB(255, 255, 210),
	["태초"] = Color3.fromRGB(190, 225, 255),
	["지존"] = Color3.fromRGB(255, 200, 90),
}
for _, st in ipairs(Config.Styles) do
	local g = ({ taeheo = "상급", geumgang = "상급", cheonryong = "최상급", maehwa = "중급", muyeong = "상급", byeokryeok = "중급", chwi = "중급", hyeolma = "전설", mugeuk = "신화", pungsin = "최상급" })[st.id]
	st.grade = g or st.grade or "중급"
end
function Config.gradeIndex(name: string): number
	return table.find(Config.GRADE_ORDER, name) or 2
end
-- 권법 승급 (깨달음): 숙련 10인 권법을 한 단계씩 끌어올린다 (두 번까지). 경지와 은자가 든다
Config.BREAKTHROUGH = {
	{ realm = 5, coins = 3000, name = "1차 깨달음" },
	{ realm = 10, coins = 20000, name = "2차 깨달음" },
}
-- 그 권법의 지금 등급 (승급까지 더해서)
function Config.styleGrade(style: any, up: number?): string
	-- 태초 등급은 태초신권만, 지존은 일월신권만 (다른 권법은 승급해도 천외까지)
	local cap = Config.gradeIndex("천외")
	if style.grade == "태초" or style.grade == "지존" then
		cap = Config.gradeIndex(style.grade)
	end
	local i = math.max(Config.gradeIndex(style.grade), math.min(cap, Config.gradeIndex(style.grade) + (up or 0)))
	return Config.GRADE_ORDER[i]
end
-- 등급이 높을수록 조금씩 빠르다: 한 단계마다 동작 +2.5%, 걸음 +1.5% (천외면 동작 ×1.175)
function Config.gradeSpeed(style: any, up: number?): number
	return 1 + 0.025 * (Config.gradeIndex(Config.styleGrade(style, up)) - 1)
end
function Config.gradeWalk(style: any, up: number?): number
	return 1 + 0.015 * (Config.gradeIndex(Config.styleGrade(style, up)) - 1)
end
-- 기술 동작 속도 (권법 고유 빠르기 × 등급 × 혈마 광란)
function Config.actSpeed(style: any, up: number?, frenzy: boolean?): number
	return (style.speed or 1) * Config.gradeSpeed(style, up) * (frenzy and 1.2 or 1)
end
Config.STYLE_BY_ID = {}
for i, s in ipairs(Config.Styles) do
	s.index = i
	Config.STYLE_BY_ID[s.id] = s
end

------------------------------------------------------------------------
-- 각성: 숙련 6이면 각성 (기술이 세지고, 연타 다섯 번째 '각성 마무리'가 열린다)
--       숙련 10이면 완전 각성 (모든 기술이 더 세지고, 그림자 메아리가 기술을 한 번 더 되풀이한다)
------------------------------------------------------------------------
Config.AWAKEN = {
	{ lv = 6, name = "각성", mark = "✦", dmg = 1.25, cd = 0.85 },
	{ lv = 10, name = "완전 각성", mark = "✦✦", dmg = 1.55, cd = 0.7, echo = 0.5, echoDelay = 0.3 },
}
function Config.awakenTier(lv: number): number
	if lv >= Config.AWAKEN[2].lv then
		return 2
	elseif lv >= Config.AWAKEN[1].lv then
		return 1
	end
	return 0
end
-- 각성 마무리 (연타 다섯 번째): 상대를 하늘로 띄운다 → 공중 연격으로 이어진다
local FINISHERS = {
	taeheo = { name = "만류회류장", pose = "double_palm" },
	geumgang = { name = "금강파산추", pose = "elbow_r" },
	maehwa = { name = "매화낙영각", pose = "crescent_kick" },
	cheonryong = { name = "승룡장", pose = "dragon_rise" },
	muyeong = { name = "귀영회선각", pose = "back_spin_kick" },
	byeokryeok = { name = "벽력천추", pose = "knee_strike" },
	chwi = { name = "취선번천", pose = "drunk_flop" },
	samjae = { name = "삼재연환각", pose = "front_kick" },
	mugeuk = { name = "무극승천장", pose = "void_push" },
	hyeolma = { name = "혈마승천조", pose = "blood_rake" },
	gaecheon = { name = "천제승천각", pose = "heaven_kick" },
	pacheon = { name = "파천승천권", pose = "grav_hammer" },
	taecho = { name = "태초승천각", pose = "origin_kick" },
	ilwol = { name = "일월승천각", pose = "sun_wheel" },
	pungsin = { name = "풍신승천각", pose = "gale_double" },
}
for id, fin in pairs(FINISHERS) do
	local s = Config.STYLE_BY_ID[id]
	s.finisher = { id = id .. "F", name = fin.name, pose = fin.pose, dur = 0.62, lunge = 4, launcher = true, hits = { hit(0.26, 6, 5, 16, 24, 0.7, 6, 62) } }
end

-- 연타 박자: 앞 동작이 이만큼 지났을 때 누르면 '딱 맞음(連)', 너무 일찍 두 번 누르면 흐트러진다
Config.RHYTHM = { early = 0.3, perfectFrom = 0.62, perfectTo = 1.0, late = 0.18, bonus = 1.15, chain = 3, chainBonus = 1.3, breakLock = 0.25, earlyLimit = 4 }

-- 권법 배우는 값 (이미 배운 권법 수에 따라). 첫 권법은 공짜
Config.LEARN_COST = { 0, 300, 750, 1500, 3000, 5000, 7500, 9000, 12000, 20000, 50000, 50000, 50000, 100000, 300000 }

-- 숙련도: 그 권법으로 맞힐 때마다 오른다. 레벨마다 그 권법 피해 +3%
Config.MASTERY_MAX = 10
function Config.masteryNeed(level: number): number
	return math.floor(40 * level ^ 1.5)
end
Config.SKILL_UNLOCK = { E = 1, R = 3, G = 5 }

-- 모든 권법이 함께 쓰는 몸놀림 기술
-- D = 대시 직후 클릭 (돌진 일격), A = 공중에서 클릭 (낙하격), C = 흘리기 직후 클릭 (반격)
Config.ACTION_MOVES = {
	D = { id = "actD", name = "돌진 일격", pose = "dash_punch", dur = 0.42, lunge = 12, hits = { hit(0.16, 6, 4.5, 11, 14, 0.45, 26) } },
	A = { id = "actA", name = "낙하격", pose = "dive_slam", dur = 0.6, dive = 85, hits = { hit(0.32, 0, 9, 13, 20, 0.6, 22, 14, true) } },
	C = { id = "actC", name = "반격", pose = "punch_r_heavy", dur = 0.42, lunge = 5, hits = { hit(0.14, 6, 4.5, 18, 40, 0.8, 34) } },
	-- J = 띄운 상대를 공중에서 잇는 연격 (나도 상대도 공중에 머문다, 세 번까지)
	J = { id = "actJ", name = "공중 연격", pose = "air_spin", dur = 0.34, hover = 30, hits = { hit(0.12, 7, 5, 8, 8, 0.6, 4, 32) } },
}
Config.ACTION_WINDOW = { D = 0.6, C = 0.8 } -- 대시·흘리기 뒤 이만큼 안에 눌러야 나간다
-- 권법마다 몸놀림 자세만 다르게
local ACTION_POSE = {
	maehwa = { D = "dash_strike", C = "spin_backfist" },
	muyeong = { D = "flying_kick", A = "dive_kick", C = "back_spin_kick", J = "roundhouse" },
	chwi = { D = "headbutt", C = "drunk_swing_r" },
	taeheo = { D = "push_palm", C = "double_palm" },
	cheonryong = { D = "push_palm", C = "double_palm" },
}
local actionCache: { [string]: any } = {}

-- 기술 하나 찾기 (서버·화면이 같은 표를 본다). slot = 1~4(연타), "H", "E", "R", "G", "D", "A", "C"
function Config.move(styleId: string, slot: any): any
	local s = Config.STYLE_BY_ID[styleId]
	if not s then
		return nil
	end
	if type(slot) == "number" then
		return s.combo[slot]
	elseif slot == "H" then
		return s.heavy
	elseif slot == "F" then
		return s.finisher
	elseif Config.ACTION_MOVES[slot] then
		local key = styleId .. slot
		if not actionCache[key] then
			local m = table.clone(Config.ACTION_MOVES[slot])
			local over = ACTION_POSE[styleId]
			if over and over[slot] then
				m.pose = over[slot]
			end
			actionCache[key] = m
		end
		return actionCache[key]
	end
	return s.skills[slot]
end

------------------------------------------------------------------------
-- 적: 모두 무기를 든다. windup = 휘두르기 전 멈칫 (보고 흘릴 수 있게)
-- unblockable = 붉게 번쩍이는 큰 공격 (막을 수 없다, 대시로 피해야 한다)
------------------------------------------------------------------------
Config.Weapons = {
	saber = { name = "도", length = 4.2, color = Color3.fromRGB(200, 205, 215), handle = Color3.fromRGB(90, 50, 30) },
	spear = { name = "창", length = 8, color = Color3.fromRGB(190, 195, 205), handle = Color3.fromRGB(120, 80, 40) },
	club = { name = "곤봉", length = 5.5, color = Color3.fromRGB(120, 80, 45), handle = Color3.fromRGB(80, 50, 30) },
	dual = { name = "쌍도", length = 3, color = Color3.fromRGB(170, 175, 190), handle = Color3.fromRGB(40, 30, 30) },
	greatsword = { name = "대도", length = 7, color = Color3.fromRGB(150, 150, 160), handle = Color3.fromRGB(60, 30, 20) },
	staff = { name = "몽둥이", length = 4.5, color = Color3.fromRGB(140, 100, 60), handle = Color3.fromRGB(100, 70, 40) },
}

Config.Enemies = {
	-- 아주 먼 곳에만 있는 강한 적
	ironguard = {
		name = "철갑 무사", weapon = "greatsword", hp = 240, posture = 200, speed = 13, aggro = 50, keep = 6, shirt = Color3.fromRGB(70, 72, 82), pants = Color3.fromRGB(40, 40, 48), scale = 1.3,
		coins = 45, xp = 30,
		moves = {
			{ id = "ig1", name = "대검 베기", pose = "w_slash", windup = 0.55, dur = 1.0, range = 8, hits = { hit(0.55, 8, 5.5, 16, 24, 0.5, 18) } },
			{ id = "ig2", name = "회전 베기", pose = "w_sweep", windup = 0.7, dur = 1.2, range = 9, hits = { hit(0.7, 0, 10, 18, 28, 0.6, 28, nil, true) } },
			{ id = "ig3", name = "분쇄", pose = "w_overhead", windup = 0.9, dur = 1.4, range = 8, unblockable = true, hits = { hit(0.9, 7, 6, 30, 45, 1.0, 35, 15, true) } },
		},
	},
	shadowblade = {
		name = "흑영 자객", weapon = "dual", hp = 150, posture = 110, speed = 22, aggro = 60, keep = 4, shirt = Color3.fromRGB(25, 20, 35), pants = Color3.fromRGB(15, 12, 22),
		coins = 40, xp = 26,
		moves = {
			{ id = "sb1", name = "그림자 연격", pose = "w_dual", windup = 0.25, dur = 1.0, range = 6, lunge = 6, hits = { hit(0.25, 6, 4, 8, 10, 0.3, 4), hit(0.42, 6, 4, 8, 10, 0.3, 4), hit(0.6, 6, 4.5, 12, 16, 0.4, 14) } },
			{ id = "sb2", name = "그림자 습격", pose = "w_thrust", windup = 0.35, dur = 0.85, range = 28, teleport = true, hits = { hit(0.35, 6, 4, 16, 20, 0.5, 15) } },
			{ id = "sb3", name = "암살", pose = "w_overhead", windup = 0.55, dur = 1.0, range = 6, unblockable = true, hits = { hit(0.55, 6, 4.5, 26, 30, 0.8, 25) } },
		},
	},
	-- 심마 대련에서만 나타난다 (마음속의 마귀)
	simma = {
		name = "심마", weapon = "dual", hp = 700, posture = 300, speed = 22, aggro = 90, keep = 4, shirt = Color3.fromRGB(35, 10, 45), pants = Color3.fromRGB(20, 5, 25), scale = 1.15,
		coins = 300, xp = 120,
		moves = {
			{ id = "sm1", name = "마영 연격", pose = "w_dual", windup = 0.25, dur = 1.1, range = 6, lunge = 6, hits = { hit(0.25, 6, 4.5, 14, 16, 0.3, 4), hit(0.45, 6, 4.5, 14, 16, 0.3, 4), hit(0.7, 6, 5, 22, 26, 0.5, 18) } },
			{ id = "sm2", name = "마영 습격", pose = "w_thrust", windup = 0.3, dur = 0.85, range = 30, teleport = true, hits = { hit(0.3, 6, 4, 24, 26, 0.5, 15) } },
			{ id = "sm3", name = "심마 참", pose = "w_sweep", windup = 0.6, dur = 1.2, range = 10, unblockable = true, hits = { hit(0.6, 0, 11, 40, 50, 0.9, 35, nil, true) } },
		},
	},
	-- 수련 목인: 테스트용 허수아비. 움직이지도 치지도 않고, 맞은 피해를 초당으로 보여 준다
	dummy = {
		name = "수련 목인", dummy = true, hp = 1000000, posture = 100000, speed = 0, aggro = 0, keep = 0,
		shirt = Color3.fromRGB(150, 110, 70), pants = Color3.fromRGB(110, 80, 50), coins = 0, xp = 0, moves = {},
	},
	thug = {
		name = "무뢰배", weapon = "staff", hp = 55, posture = 50, speed = 13, aggro = 38, keep = 5, shirt = Color3.fromRGB(150, 130, 100), pants = Color3.fromRGB(80, 70, 55),
		coins = 6, xp = 5,
		moves = {
			{ id = "t1", name = "몽둥이질", pose = "w_slash", windup = 0.6, dur = 0.9, range = 6, hits = { hit(0.6, 6, 4, 6, 9, 0.35, 10) } },
			{ id = "t2", name = "내려치기", pose = "w_overhead", windup = 0.85, dur = 1.25, range = 6, unblockable = true, hits = { hit(0.85, 6, 4.5, 11, 18, 0.6, 20) } },
		},
	},
	bandit = {
		name = "산적 도객", weapon = "saber", hp = 90, posture = 70, speed = 15, aggro = 45, keep = 5, shirt = Color3.fromRGB(120, 90, 60), pants = Color3.fromRGB(60, 50, 40),
		coins = 12, xp = 8,
		moves = {
			{ id = "b1", name = "베기", pose = "w_slash", windup = 0.45, dur = 0.8, range = 6, hits = { hit(0.45, 6, 4, 9, 12, 0.4, 10) } },
			{ id = "b2", name = "연속 베기", pose = "w_slash2", windup = 0.4, dur = 1.1, range = 6, hits = { hit(0.4, 6, 4, 7, 10, 0.35, 6), hit(0.7, 6, 4, 8, 12, 0.4, 12) } },
			{ id = "b3", name = "내려찍기", pose = "w_overhead", windup = 0.75, dur = 1.2, range = 6, unblockable = true, hits = { hit(0.75, 6, 4.5, 18, 30, 0.7, 25) } },
		},
	},
	spearman = {
		name = "창병", weapon = "spear", hp = 100, posture = 80, speed = 14, aggro = 50, keep = 8, shirt = Color3.fromRGB(70, 90, 120), pants = Color3.fromRGB(40, 50, 70),
		coins = 15, xp = 10,
		moves = {
			{ id = "s1", name = "찌르기", pose = "w_thrust", windup = 0.5, dur = 0.85, range = 10, lunge = 4, hits = { hit(0.5, 10, 3, 10, 14, 0.45, 18) } },
			{ id = "s2", name = "휘두르기", pose = "w_sweep", windup = 0.55, dur = 1.0, range = 8, hits = { hit(0.55, 3, 9, 9, 14, 0.45, 14, nil, true) } },
			{ id = "s3", name = "돌진 찌르기", pose = "w_thrust", windup = 0.7, dur = 1.1, range = 14, lunge = 12, unblockable = true, hits = { hit(0.7, 10, 3.5, 17, 28, 0.7, 30) } },
		},
	},
	brute = {
		name = "곤봉 산적", weapon = "club", hp = 150, posture = 110, speed = 13, aggro = 40, keep = 6, shirt = Color3.fromRGB(110, 60, 50), pants = Color3.fromRGB(50, 35, 30), scale = 1.25,
		coins = 20, xp = 14,
		moves = {
			{ id = "c1", name = "후려치기", pose = "w_slash", windup = 0.6, dur = 1.0, range = 7, hits = { hit(0.6, 7, 5.5, 12, 20, 0.5, 22) } },
			{ id = "c2", name = "땅 내려치기", pose = "w_overhead", windup = 0.85, dur = 1.4, range = 7, unblockable = true, hits = { hit(0.85, 5, 8, 20, 35, 0.9, 30, 20, true) } },
		},
	},
	assassin = {
		name = "쌍도 자객", weapon = "dual", hp = 75, posture = 60, speed = 19, aggro = 55, keep = 4, shirt = Color3.fromRGB(30, 30, 40), pants = Color3.fromRGB(20, 20, 28),
		coins = 18, xp = 12,
		moves = {
			{ id = "a1", name = "쌍도 연격", pose = "w_dual", windup = 0.28, dur = 0.9, range = 5, lunge = 4, hits = { hit(0.28, 5, 4, 5, 7, 0.3, 4), hit(0.45, 5, 4, 5, 7, 0.3, 4), hit(0.62, 5, 4, 7, 10, 0.35, 10) } },
			{ id = "a2", name = "기습 찌르기", pose = "w_thrust", windup = 0.35, dur = 0.8, range = 9, lunge = 10, hits = { hit(0.35, 6, 3.5, 10, 12, 0.4, 12) } },
		},
	},
}

-- 보스: phase2 = 체력 절반 아래에서 빨라지고 기술이 늘어난다
Config.Bosses = {
	heukho = {
		name = "흑호 · 산적 두목", weapon = "greatsword", hp = 1100, posture = 260, speed = 15, aggro = 60, keep = 7, scale = 1.45,
		shirt = Color3.fromRGB(30, 25, 25), pants = Color3.fromRGB(70, 20, 20), coins = 400, xp = 120, respawn = 120,
		moves = {
			{ id = "h1", name = "대도 삼연참", pose = "w_slash2", windup = 0.5, dur = 1.5, range = 9, hits = { hit(0.5, 9, 5, 12, 18, 0.45, 10), hit(0.85, 9, 5, 12, 18, 0.45, 10), hit(1.2, 9, 6, 18, 26, 0.6, 30) } },
			{ id = "h2", name = "회전 베기", pose = "w_sweep", windup = 0.7, dur = 1.3, range = 10, hits = { hit(0.7, 0, 12, 16, 24, 0.5, 25, nil, true) } },
			{ id = "h3", name = "뛰어 내려찍기", pose = "w_overhead", windup = 0.9, dur = 1.5, range = 20, lunge = 16, unblockable = true, hits = { hit(0.9, 6, 9, 28, 45, 1.0, 35, 20, true) } },
		},
		phase2 = { speed = 1.25, extra = { id = "h4", name = "흑호 돌진", pose = "w_thrust", windup = 0.6, dur = 1.1, range = 24, lunge = 24, hits = { hit(0.6, 9, 5, 22, 35, 0.8, 45) } } },
	},
	hyeolrang = {
		name = "혈랑 · 자객 우두머리", weapon = "dual", hp = 850, posture = 200, speed = 21, aggro = 60, keep = 5, scale = 1.15,
		shirt = Color3.fromRGB(110, 10, 20), pants = Color3.fromRGB(25, 10, 15), coins = 450, xp = 140, respawn = 120,
		moves = {
			{ id = "r1", name = "혈랑 오연격", pose = "w_dual", windup = 0.3, dur = 1.3, range = 6, lunge = 6, hits = { hit(0.3, 6, 4.5, 6, 9, 0.3, 3), hit(0.5, 6, 4.5, 6, 9, 0.3, 3), hit(0.7, 6, 4.5, 6, 9, 0.3, 3), hit(0.9, 6, 4.5, 6, 9, 0.3, 3), hit(1.1, 6, 5, 12, 18, 0.5, 20) } },
			{ id = "r2", name = "그림자 습격", pose = "w_thrust", windup = 0.4, dur = 0.9, range = 30, teleport = true, hits = { hit(0.4, 6, 4, 14, 18, 0.5, 15) } },
			{ id = "r3", name = "혈류참", pose = "w_overhead", windup = 0.7, dur = 1.2, range = 7, unblockable = true, hits = { hit(0.7, 7, 5, 24, 35, 0.8, 30) } },
		},
		phase2 = { speed = 1.3, extra = { id = "r4", name = "혈랑 회오리", pose = "w_sweep", windup = 0.5, dur = 1.2, range = 10, hits = { hit(0.5, 0, 11, 10, 15, 0.4, 5, nil, true), hit(0.8, 0, 11, 14, 20, 0.6, 30, nil, true) } } },
	},
}

-- 먼 땅의 적: 기존 적을 바탕으로 이름·빛깔·세기만 바꾼다
local function variant(base: any, over: { [string]: any }): any
	local v = table.clone(base)
	for k, x in pairs(over) do
		v[k] = x
	end
	return v
end
local E = Config.Enemies
E.ironguard.elite = true
E.shadowblade.elite = true
E.simma.elite = true
E.iceguard = variant(E.ironguard, { name = "빙궁 무사", shirt = Color3.fromRGB(170, 210, 235), pants = Color3.fromRGB(90, 120, 150), hp = 260 })
E.snowblade = variant(E.assassin, { name = "설원 자객", shirt = Color3.fromRGB(230, 235, 245), pants = Color3.fromRGB(150, 160, 175), hp = 95 })
E.swampfang = variant(E.shadowblade, { name = "독수 자객", shirt = Color3.fromRGB(60, 90, 50), pants = Color3.fromRGB(35, 50, 30) })
E.bogbrute = variant(E.brute, { name = "늪 거한", shirt = Color3.fromRGB(80, 95, 60), pants = Color3.fromRGB(50, 55, 40), hp = 200, scale = 1.4 })
E.marauder = variant(E.bandit, { name = "마적", shirt = Color3.fromRGB(150, 90, 50), pants = Color3.fromRGB(90, 60, 40), hp = 130, speed = 17, elite = true })
E.lancer = variant(E.spearman, { name = "황야 창수", shirt = Color3.fromRGB(170, 120, 70), pants = Color3.fromRGB(100, 70, 45), hp = 140 })
E.pirate = variant(E.bandit, { name = "해적 도객", shirt = Color3.fromRGB(50, 70, 110), pants = Color3.fromRGB(40, 40, 50), hp = 120 })
E.cultist = variant(E.bandit, { name = "혈교도", shirt = Color3.fromRGB(110, 15, 25), pants = Color3.fromRGB(30, 10, 12), hp = 150, speed = 17 })
E.cultelder = variant(E.shadowblade, { name = "혈교 장로", shirt = Color3.fromRGB(60, 10, 15), pants = Color3.fromRGB(20, 5, 8), hp = 260, scale = 1.15 })
-- 허공 균열 (북서쪽 끝): 사경 이후의 적. mult = 체력·피해를 겹으로 더 세게
E.riftling = variant(E.assassin, { name = "균열 마물", shirt = Color3.fromRGB(80, 50, 120), pants = Color3.fromRGB(40, 25, 60), hp = 90, mult = 4 })
E.voidwalker = variant(E.shadowblade, { name = "허공 마인", shirt = Color3.fromRGB(30, 20, 60), pants = Color3.fromRGB(15, 10, 30), hp = 150, mult = 6 })
E.stonegolem = variant(E.ironguard, { name = "석상 수호자", shirt = Color3.fromRGB(130, 125, 140), pants = Color3.fromRGB(90, 85, 100), hp = 240, scale = 1.8, speed = 11, mult = 8 })
E.apostle = variant(E.cultelder, { name = "천마 사도", shirt = Color3.fromRGB(20, 10, 40), pants = Color3.fromRGB(10, 5, 20), hp = 260, mult = 10, elite = true })
-- 넓어진 강호의 바깥 세 땅 (천마 뒤): 화염산, 사왕릉, 천외봉 운해
E.flameimp = variant(E.assassin, { name = "화염 귀졸", shirt = Color3.fromRGB(210, 80, 25), pants = Color3.fromRGB(70, 20, 10), hp = 110, mult = 6 })
E.magmabrute = variant(E.brute, { name = "용암 거한", shirt = Color3.fromRGB(95, 35, 20), pants = Color3.fromRGB(45, 15, 10), hp = 260, scale = 1.7, speed = 12, mult = 8 })
E.sandwraith = variant(E.shadowblade, { name = "모래 망령", shirt = Color3.fromRGB(215, 185, 125), pants = Color3.fromRGB(150, 120, 80), hp = 170, mult = 8 })
E.tombguard = variant(E.ironguard, { name = "왕릉 수호병", shirt = Color3.fromRGB(195, 155, 60), pants = Color3.fromRGB(110, 80, 40), hp = 270, scale = 1.3, mult = 10 })
E.skyguard = variant(E.ironguard, { name = "천병", shirt = Color3.fromRGB(235, 240, 255), pants = Color3.fromRGB(170, 190, 230), hp = 300, mult = 14, elite = true })
E.starblade = variant(E.shadowblade, { name = "성검객", shirt = Color3.fromRGB(200, 215, 255), pants = Color3.fromRGB(90, 110, 170), hp = 210, mult = 13, elite = true })
local B = Config.Bosses
B.bingma = variant(B.heukho, { name = "빙마 · 설산의 주인", shirt = Color3.fromRGB(200, 230, 255), pants = Color3.fromRGB(80, 110, 150), hp = 1600, posture = 320, scale = 1.6, coins = 900, xp = 300 })
B.hyeolma = variant(B.hyeolrang, { name = "혈마 · 혈교의 주인", shirt = Color3.fromRGB(150, 0, 20), pants = Color3.fromRGB(20, 0, 5), hp = 2400, posture = 420, scale = 1.5, speed = 23, coins = 3000, xp = 800, respawn = 300 })
B.cheonma = variant(B.hyeolrang, { name = "천마 · 하늘을 삼킨 마귀", shirt = Color3.fromRGB(25, 10, 50), pants = Color3.fromRGB(10, 0, 20), hp = 2400, posture = 520, scale = 1.75, speed = 24, coins = 12000, xp = 2000, respawn = 300, mult = 6 })
B.yeomje = variant(B.heukho, { name = "염제 · 화염산의 주인", shirt = Color3.fromRGB(235, 95, 25), pants = Color3.fromRGB(80, 20, 10), hp = 2600, posture = 560, scale = 1.7, coins = 20000, xp = 3000, respawn = 300, mult = 8 })
B.sawang = variant(B.hyeolrang, { name = "사왕 · 모래 왕릉의 주인", shirt = Color3.fromRGB(215, 175, 70), pants = Color3.fromRGB(90, 60, 30), hp = 2600, posture = 560, scale = 1.6, speed = 22, coins = 24000, xp = 3500, respawn = 300, mult = 10 })
B.cheonmun = variant(B.heukho, { name = "천문장 · 하늘 문지기", shirt = Color3.fromRGB(240, 245, 255), pants = Color3.fromRGB(120, 150, 210), hp = 3000, posture = 700, scale = 1.8, coins = 40000, xp = 6000, respawn = 300, mult = 16 })
-- 큰 보스: 몸이 크고(팔도 길다) 체력이 많고, 세 단계 패턴을 쓴다 (체력 2/3·1/3에서 다음 단계)
local function boss(id: string, over: { [string]: any })
	local b = B[id]
	for k, v in pairs(over) do
		b[k] = v
	end
end
local P = function(kind: string, name: string, phase: number, opt: { [string]: any })
	local t = { kind = kind, name = name, phase = phase }
	for k, v in pairs(opt) do
		t[k] = v
	end
	return t
end
boss("heukho", { hp = 2900, scale = 2.4, reach = 1.5, patterns = {
	P("quake", "흑호 지진", 1, { radius = 16, warn = 1.1, cd = 7, pose = "w_overhead", hit = hit(0, 0, 0, 30, 40, 0.9, 40, 18) }),
	P("leap", "호랑이 도약", 1, { radius = 13, warn = 1.2, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 36, 50, 1.0, 35, 15) }),
	P("charge", "흑호 돌진", 2, { length = 46, width = 9, warn = 0.9, cd = 7, times = 2, pose = "w_thrust", hit = hit(0, 0, 0, 30, 40, 0.8, 50) }),
	P("summon", "부하들아!", 2, { enemy = "bandit", count = 3, max = 5, warn = 0.9, cd = 14, pose = "w_overhead" }),
	P("donut", "대도 회오리", 3, { inner = 7, outer = 24, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 40, 50, 1.0, 45) }),
} })
boss("hyeolrang", { hp = 2400, scale = 2.0, reach = 1.4, patterns = {
	P("charge", "혈랑 질주", 1, { length = 40, width = 7, warn = 0.75, cd = 6, times = 3, pose = "w_thrust", hit = hit(0, 0, 0, 22, 28, 0.6, 30) }),
	P("rain", "핏빛 비", 1, { count = 4, radius = 7, spread = 16, warn = 1.0, cd = 8, pose = "w_dual", fx = "blood", color = Color3.fromRGB(220, 30, 45), hit = hit(0, 0, 0, 26, 30, 0.7, 20) }),
	P("summon", "그림자 무리", 2, { enemy = "assassin", count = 3, max = 6, warn = 0.8, cd = 13, pose = "w_dual" }),
	P("quake", "혈류 폭발", 3, { radius = 15, warn = 0.9, cd = 7, pose = "w_sweep", hit = hit(0, 0, 0, 30, 36, 0.8, 40) }),
} })
boss("bingma", { hp = 4600, scale = 2.8, reach = 1.6, patterns = {
	P("rain", "얼음 창비", 1, { count = 6, radius = 7, spread = 20, warn = 1.1, cd = 8, pose = "w_overhead", fx = "ice", color = Color3.fromRGB(150, 210, 255), hit = hit(0, 0, 0, 32, 40, 1.2, 20) }),
	P("quake", "빙결 진동", 1, { radius = 18, warn = 1.2, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 34, 50, 1.4, 30) }),
	P("donut", "설풍 고리", 2, { inner = 8, outer = 28, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 40, 50, 1.2, 40) }),
	P("leap", "빙산 낙하", 2, { radius = 15, warn = 1.2, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 44, 60, 1.2, 40, 20) }),
	P("summon", "설원의 자객들", 3, { enemy = "snowblade", count = 3, max = 6, warn = 0.9, cd = 14, pose = "w_overhead" }),
} })
boss("hyeolma", { hp = 6200, scale = 2.6, reach = 1.6, patterns = {
	P("donut", "혈해 고리", 1, { inner = 8, outer = 26, warn = 1.1, cd = 7, pose = "w_sweep", hit = hit(0, 0, 0, 40, 50, 1.0, 40) }),
	P("rain", "혈우", 1, { count = 6, radius = 7, spread = 20, warn = 1.0, cd = 8, pose = "w_dual", fx = "blood", color = Color3.fromRGB(220, 30, 45), hit = hit(0, 0, 0, 30, 36, 0.8, 20) }),
	P("charge", "혈마 돌진", 2, { length = 50, width = 9, warn = 0.8, cd = 7, times = 3, pose = "w_thrust", hit = hit(0, 0, 0, 34, 40, 0.8, 50) }),
	P("summon", "혈교도들아!", 2, { enemy = "cultist", count = 3, max = 6, warn = 0.9, cd = 14, pose = "w_overhead" }),
	P("quake", "혈마 강림", 3, { radius = 22, warn = 1.3, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 55, 80, 1.4, 60, 20) }),
} })
boss("cheonma", { hp = 4600, scale = 3.2, reach = 1.8, patterns = {
	P("rain", "천마 낙성", 1, { count = 7, radius = 8, spread = 24, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(170, 110, 255), hit = hit(0, 0, 0, 34, 40, 0.8, 20) }),
	P("donut", "허공 고리", 1, { inner = 9, outer = 30, warn = 1.1, cd = 7, pose = "w_sweep", hit = hit(0, 0, 0, 44, 60, 1.0, 45) }),
	P("leap", "하늘 짓밟기", 1, { radius = 16, warn = 1.1, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 50, 70, 1.2, 45, 20) }),
	P("charge", "천마 돌격", 2, { length = 56, width = 10, warn = 0.75, cd = 6, times = 3, pose = "w_thrust", hit = hit(0, 0, 0, 40, 50, 0.9, 60) }),
	P("summon", "허공의 마인들", 2, { enemy = "voidwalker", count = 3, max = 6, warn = 0.9, cd = 14, pose = "w_overhead" }),
	P("quake", "천마멸세", 3, { radius = 26, warn = 1.4, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 70, 100, 1.5, 70, 25) }),
} })

boss("yeomje", { hp = 5500, scale = 3.0, reach = 1.7, patterns = {
	P("rain", "화산탄", 1, { count = 7, radius = 8, spread = 24, warn = 1.0, cd = 7, pose = "w_overhead", fx = "fire", color = Color3.fromRGB(255, 120, 30), hit = hit(0, 0, 0, 36, 40, 0.8, 25) }),
	P("donut", "불꽃 고리", 1, { inner = 9, outer = 28, warn = 1.1, cd = 7, pose = "w_sweep", hit = hit(0, 0, 0, 44, 55, 1.0, 45) }),
	P("charge", "용암 돌진", 2, { length = 52, width = 10, warn = 0.8, cd = 7, times = 2, pose = "w_thrust", hit = hit(0, 0, 0, 40, 50, 0.9, 55) }),
	P("summon", "불의 귀졸들", 2, { enemy = "flameimp", count = 3, max = 6, warn = 0.9, cd = 14, pose = "w_overhead" }),
	P("quake", "화산 폭발", 3, { radius = 24, warn = 1.3, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 66, 90, 1.4, 60, 22) }),
} })
boss("sawang", { hp = 5800, scale = 2.8, reach = 1.6, patterns = {
	P("charge", "모래 질주", 1, { length = 46, width = 8, warn = 0.75, cd = 6, times = 3, pose = "w_thrust", hit = hit(0, 0, 0, 34, 40, 0.8, 40) }),
	P("rain", "모래 창", 1, { count = 6, radius = 7, spread = 22, warn = 1.0, cd = 8, pose = "w_dual", fx = "sand", color = Color3.fromRGB(230, 195, 120), hit = hit(0, 0, 0, 34, 40, 0.8, 20, 14) }),
	P("donut", "모래 회오리", 2, { inner = 8, outer = 26, warn = 1.1, cd = 7, pose = "w_sweep", hit = hit(0, 0, 0, 44, 55, 1.0, 45) }),
	P("summon", "무덤의 망령들", 2, { enemy = "sandwraith", count = 3, max = 6, warn = 0.9, cd = 14, pose = "w_overhead" }),
	P("leap", "왕의 낙하", 3, { radius = 18, warn = 1.1, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 60, 80, 1.3, 50, 20) }),
} })
boss("cheonmun", { hp = 6700, scale = 3.4, reach = 1.9, patterns = {
	P("rain", "천벌", 1, { count = 8, radius = 8, spread = 26, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(200, 225, 255), hit = hit(0, 0, 0, 40, 46, 0.8, 25) }),
	P("leap", "하늘 문 내려닫기", 1, { radius = 18, warn = 1.1, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 60, 80, 1.2, 50, 20) }),
	P("donut", "천문 고리", 2, { inner = 10, outer = 32, warn = 1.1, cd = 7, pose = "w_sweep", hit = hit(0, 0, 0, 50, 66, 1.0, 50) }),
	P("summon", "천병들아!", 2, { enemy = "skyguard", count = 2, max = 4, warn = 0.9, cd = 15, pose = "w_overhead" }),
	P("charge", "천문 돌파", 3, { length = 60, width = 11, warn = 0.75, cd = 6, times = 3, pose = "w_thrust", hit = hit(0, 0, 0, 46, 60, 1.0, 60) }),
	P("quake", "하늘이 무너진다", 3, { radius = 28, warn = 1.4, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 80, 110, 1.5, 70, 25) }),
} })

------------------------------------------------------------------------
-- 월드: 가운데 마을, 서쪽 대나무 숲, 북쪽 산적 소굴, 동쪽 폭포 계곡
-- 적은 근처에 사람이 있을 때만 움직인다
------------------------------------------------------------------------
Config.Regions = {
	{ id = "village", name = "청운 마을", center = Vector3.new(0, 0, 0), size = Vector3.new(360, 0, 360), ground = Color3.fromRGB(150, 135, 105), material = Enum.Material.Ground, safe = true },
	{ id = "bamboo", name = "대나무 숲", center = Vector3.new(-420, 0, 0), size = Vector3.new(480, 0, 440), ground = Color3.fromRGB(95, 130, 70), material = Enum.Material.Grass,
		camps = { { enemy = "bandit", count = 3, at = Vector3.new(-300, 0, 120) }, { enemy = "bandit", count = 2, at = Vector3.new(-330, 0, -110) }, { enemy = "spearman", count = 3, at = Vector3.new(-570, 0, -110) } } },
	-- 먼 북쪽의 산적 소굴 (강한 적과 두목)
	{ id = "fort", name = "흑호채 (산적 소굴)", center = Vector3.new(0, 0, -900), size = Vector3.new(440, 0, 480), ground = Color3.fromRGB(110, 90, 70), material = Enum.Material.Mud,
		camps = { { enemy = "spearman", count = 3, at = Vector3.new(0, 0, -790) }, { enemy = "brute", count = 3, at = Vector3.new(90, 0, -880) }, { enemy = "ironguard", count = 2, at = Vector3.new(-90, 0, -880) } },
		boss = { id = "heukho", at = Vector3.new(0, 0, -1020) } },
	{ id = "valley", name = "비류 폭포 계곡", center = Vector3.new(440, 0, 0), size = Vector3.new(480, 0, 440), ground = Color3.fromRGB(85, 120, 95), material = Enum.Material.Grass,
		camps = { { enemy = "bandit", count = 3, at = Vector3.new(320, 0, 130) }, { enemy = "assassin", count = 2, at = Vector3.new(540, 0, 120) }, { enemy = "assassin", count = 2, at = Vector3.new(540, 0, -90) } } },
	-- 마을 남쪽 들판: 처음 싸워 보기 좋은 무뢰배
	{ id = "field", name = "청운 들판", center = Vector3.new(0, 0, 330), size = Vector3.new(340, 0, 260), ground = Color3.fromRGB(125, 150, 85), material = Enum.Material.Grass,
		camps = { { enemy = "thug", count = 3, at = Vector3.new(-120, 0, 300) }, { enemy = "thug", count = 3, at = Vector3.new(130, 0, 340) }, { enemy = "thug", count = 2, at = Vector3.new(0, 0, 420) } } },
	-- 사부를 찾아가는 길목의 적 (바닥은 따로 깔지 않는다)
	{ id = "wilds", name = "강호 들판", center = Vector3.new(0, 0, 0), size = Vector3.new(0, 0, 0), noGround = true,
		camps = {
			-- 가운데쯤 (사부 가는 길목)
			{ enemy = "spearman", count = 2, at = Vector3.new(-430, 0, 470) }, { enemy = "brute", count = 2, at = Vector3.new(-300, 0, -560) },
			{ enemy = "spearman", count = 2, at = Vector3.new(430, 0, -470) }, { enemy = "brute", count = 2, at = Vector3.new(450, 0, 470) },
			{ enemy = "assassin", count = 2, at = Vector3.new(760, 0, -170) }, { enemy = "assassin", count = 2, at = Vector3.new(-760, 0, 130) },
			-- 아주 먼 곳 (강한 적)
			{ enemy = "shadowblade", count = 2, at = Vector3.new(-1050, 0, -550) }, { enemy = "ironguard", count = 2, at = Vector3.new(380, 0, -1000) },
			{ enemy = "ironguard", count = 1, at = Vector3.new(-1000, 0, 700) }, { enemy = "shadowblade", count = 2, at = Vector3.new(1050, 0, 300) },
		} },
	-- 먼 남동쪽 끝: 혈랑의 소굴
	{ id = "lair", name = "혈월곡", center = Vector3.new(1000, 0, 1000), size = Vector3.new(380, 0, 380), ground = Color3.fromRGB(85, 45, 45), material = Enum.Material.Slate,
		camps = { { enemy = "shadowblade", count = 3, at = Vector3.new(930, 0, 930) }, { enemy = "ironguard", count = 2, at = Vector3.new(1060, 0, 920) } },
		boss = { id = "hyeolrang", at = Vector3.new(1080, 0, 1080) } },
	-- 넓어진 강호: 먼 바깥의 다섯 땅 (멀수록 세다)
	{ id = "snow", name = "북방 설산", center = Vector3.new(0, 0, -1720), size = Vector3.new(1100, 0, 700), ground = Color3.fromRGB(235, 240, 248), material = Enum.Material.Snow, ambient = "snow",
		camps = { { enemy = "snowblade", count = 3, at = Vector3.new(-250, 0, -1500) }, { enemy = "iceguard", count = 2, at = Vector3.new(250, 0, -1600) }, { enemy = "snowblade", count = 2, at = Vector3.new(-100, 0, -1800) }, { enemy = "iceguard", count = 2, at = Vector3.new(150, 0, -1880) } },
		boss = { id = "bingma", at = Vector3.new(0, 0, -1980) } },
	{ id = "swamp", name = "독안개 늪", center = Vector3.new(0, 0, 1520), size = Vector3.new(1000, 0, 640), ground = Color3.fromRGB(70, 85, 55), material = Enum.Material.Mud, ambient = "swamp",
		camps = { { enemy = "swampfang", count = 3, at = Vector3.new(-250, 0, 1400) }, { enemy = "bogbrute", count = 2, at = Vector3.new(250, 0, 1500) }, { enemy = "swampfang", count = 2, at = Vector3.new(0, 0, 1700) } } },
	{ id = "badlands", name = "붉은 황야", center = Vector3.new(1720, 0, 120), size = Vector3.new(700, 0, 1100), ground = Color3.fromRGB(190, 120, 75), material = Enum.Material.Sand, ambient = "badlands",
		camps = { { enemy = "marauder", count = 3, at = Vector3.new(1600, 0, -150) }, { enemy = "lancer", count = 3, at = Vector3.new(1800, 0, 250) }, { enemy = "marauder", count = 2, at = Vector3.new(1650, 0, 500) } } },
	{ id = "coast", name = "서해 절벽", center = Vector3.new(-1720, 0, 0), size = Vector3.new(700, 0, 1200), ground = Color3.fromRGB(160, 155, 120), material = Enum.Material.Sand, ambient = "coast",
		camps = { { enemy = "pirate", count = 4, at = Vector3.new(-1800, 0, -250) }, { enemy = "pirate", count = 3, at = Vector3.new(-1650, 0, 300) }, { enemy = "lancer", count = 2, at = Vector3.new(-1850, 0, 450) } } },
	{ id = "cult", name = "혈교 본산", center = Vector3.new(1750, 0, -1750), size = Vector3.new(700, 0, 700), ground = Color3.fromRGB(60, 30, 32), material = Enum.Material.Slate, ambient = "cult",
		camps = { { enemy = "cultist", count = 4, at = Vector3.new(1600, 0, -1550) }, { enemy = "cultist", count = 3, at = Vector3.new(1850, 0, -1600) }, { enemy = "cultelder", count = 2, at = Vector3.new(1700, 0, -1800) }, { enemy = "cultelder", count = 2, at = Vector3.new(1850, 0, -1850) } },
		boss = { id = "hyeolma", at = Vector3.new(1800, 0, -1950) } },
	{ id = "rift", name = "허공 균열", center = Vector3.new(-1750, 0, -1750), size = Vector3.new(700, 0, 700), ground = Color3.fromRGB(35, 25, 55), material = Enum.Material.Slate, ambient = "rift",
		camps = { { enemy = "riftling", count = 4, at = Vector3.new(-1500, 0, -1500) }, { enemy = "riftling", count = 3, at = Vector3.new(-1650, 0, -1450) }, { enemy = "voidwalker", count = 3, at = Vector3.new(-1550, 0, -1700) },
			{ enemy = "stonegolem", count = 2, at = Vector3.new(-1800, 0, -1600) }, { enemy = "apostle", count = 2, at = Vector3.new(-1850, 0, -1850) }, { enemy = "apostle", count = 2, at = Vector3.new(-1700, 0, -1900) } },
		boss = { id = "cheonma", at = Vector3.new(-1950, 0, -1950) } },
	-- 더 넓어진 강호: 천마 뒤의 세 땅 (가장 멀고 가장 세다)
	{ id = "volcano", name = "화염산", center = Vector3.new(2850, 0, -900), size = Vector3.new(900, 0, 1100), ground = Color3.fromRGB(62, 48, 44), material = Enum.Material.Basalt, ambient = "volcano",
		camps = { { enemy = "flameimp", count = 4, at = Vector3.new(2550, 0, -600) }, { enemy = "flameimp", count = 3, at = Vector3.new(2700, 0, -1250) }, { enemy = "magmabrute", count = 2, at = Vector3.new(2850, 0, -450) }, { enemy = "magmabrute", count = 2, at = Vector3.new(2600, 0, -950) } },
		boss = { id = "yeomje", at = Vector3.new(2950, 0, -1150) } },
	{ id = "tomb", name = "사왕릉 (모래 왕릉)", center = Vector3.new(-900, 0, 2850), size = Vector3.new(1200, 0, 900), ground = Color3.fromRGB(215, 188, 135), material = Enum.Material.Sand, ambient = "desert",
		camps = { { enemy = "sandwraith", count = 4, at = Vector3.new(-600, 0, 2600) }, { enemy = "sandwraith", count = 3, at = Vector3.new(-1250, 0, 2650) }, { enemy = "tombguard", count = 2, at = Vector3.new(-700, 0, 2950) }, { enemy = "tombguard", count = 2, at = Vector3.new(-1150, 0, 2950) } },
		boss = { id = "sawang", at = Vector3.new(-900, 0, 2930) } },
	{ id = "skysea", name = "천외봉 운해", center = Vector3.new(0, 0, -2900), size = Vector3.new(1400, 0, 900), ground = Color3.fromRGB(232, 238, 250), material = Enum.Material.SmoothPlastic, ambient = "sky",
		camps = { { enemy = "starblade", count = 3, at = Vector3.new(-400, 0, -2650) }, { enemy = "skyguard", count = 2, at = Vector3.new(400, 0, -2700) }, { enemy = "starblade", count = 2, at = Vector3.new(-350, 0, -3050) }, { enemy = "skyguard", count = 2, at = Vector3.new(380, 0, -3000) } },
		boss = { id = "cheonmun", at = Vector3.new(0, 0, -2760) } },
	-- 일월대: 해와 달의 단 (정점의 사부, 권존이 홀로 선다)
	{ id = "sunmoon", name = "일월대", center = Vector3.new(2500, 0, 2500), size = Vector3.new(420, 0, 420), ground = Color3.fromRGB(70, 62, 78), material = Enum.Material.Slate, safe = true },
	-- 풍신대: 바람이 그치지 않는 언덕 (여덟째 사부)
	{ id = "windhill", name = "풍신대 (바람의 언덕)", center = Vector3.new(-1100, 0, 1100), size = Vector3.new(260, 0, 260), ground = Color3.fromRGB(120, 165, 115), material = Enum.Material.Grass, safe = true,
		master = "pungsin", rumor = "남서쪽 먼 언덕, 바람이 그치지 않는 곳에 바람을 차는 사람이 산다더라", quote = "바람은 잡을 수 없다. 그래서 막을 수도 없다.", masterName = "풍백", masterAt = Vector3.new(-1100, 6, 1100) },
	-- 일곱 사부의 자리 (안전 지대). master = 그 권법, masterAt = 사부가 서 있는 곳
	{ id = "lake", name = "태허호 (호수 정자)", center = Vector3.new(-650, 0, 650), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(110, 150, 110), material = Enum.Material.Grass, safe = true,
		master = "taeheo", rumor = "남서쪽 호수 한가운데 정자에 물처럼 앉은 노인이 있다더라", quote = "물은 다투지 않는다. 그래서 이긴다.", masterName = "수월진인", masterAt = Vector3.new(-650, 1.6, 650) },
	{ id = "temple", name = "금강사", center = Vector3.new(650, 0, -650), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(150, 140, 120), material = Enum.Material.Cobblestone, safe = true,
		master = "geumgang", rumor = "북동쪽 돌 기단 위 절에서 종소리가 끊이지 않는다더라", quote = "부서지지 않는 몸이 곧 부서지지 않는 마음이다.", masterName = "혜공대사", masterAt = Vector3.new(650, 6, -680) },
	{ id = "plum", name = "매화원", center = Vector3.new(-650, 0, -650), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(140, 150, 105), material = Enum.Material.Grass, safe = true,
		master = "maehwa", rumor = "북서쪽 매화 숲 깊은 곳에 꽃잎과 함께 춤추는 여인이 있다더라", quote = "꽃은 한 번에 핀다. 망설이는 순간 진다.", masterName = "매향선자", masterAt = Vector3.new(-650, 0, -660) },
	{ id = "peak", name = "천룡봉", center = Vector3.new(1000, 0, -280), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(120, 115, 105), material = Enum.Material.Slate, safe = true,
		master = "cheonryong", rumor = "동쪽 끝 바위 봉우리, 금빛 용 기둥 아래에 노인이 산다더라", quote = "용은 엎드려 기다리다 하늘을 가른다.", masterName = "용천노조", masterAt = Vector3.new(1030, 14, -280) },
	{ id = "ravine", name = "무영곡", center = Vector3.new(-1000, 0, 0), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(60, 58, 70), material = Enum.Material.Slate, safe = true,
		master = "muyeong", rumor = "서쪽 끝 검은 골짜기에 발소리 없는 그림자가 산다더라", quote = "보이는 발은 이미 늦은 발이다.", masterName = "무영객", masterAt = Vector3.new(-1060, 3, 0) },
	{ id = "plateau", name = "뇌운 고원", center = Vector3.new(650, 0, 650), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(125, 125, 135), material = Enum.Material.Granite, safe = true,
		master = "byeokryeok", rumor = "남동쪽 쇠기둥 고원에 번개가 떨어지지 않는 날이 없다더라", quote = "생각보다 빠르게. 번개보다 먼저.", masterName = "뇌정진군", masterAt = Vector3.new(650, 2, 650) },
	{ id = "tavern", name = "취선 주막", center = Vector3.new(0, 0, 700), size = Vector3.new(260, 0, 220), ground = Color3.fromRGB(150, 130, 95), material = Enum.Material.Ground, safe = true,
		master = "chwi", rumor = "남쪽 주막에 늘 취해 있는 노인이 있는데, 넘어지는 걸 본 사람이 없다더라", quote = "취한 자는 넘어지지 않는다. 넘어지는 척할 뿐이지.", masterName = "취선옹", masterAt = Vector3.new(0, 0, 690) },
}
-- 권법 id → 사부 { name, at, region }
Config.MASTERS = {}
for _, r in ipairs(Config.Regions) do
	if r.master then
		Config.MASTERS[r.master] = { name = r.masterName, at = r.masterAt, region = r.name, regionId = r.id, quote = r.quote, rumor = r.rumor }
	end
end
-- 숨은 사부 (지도에도, 지역 목록에도 없다): 무극에 오른 자에게만 시험을 허락한다
Config.SECRET_MASTER = { style = "gaecheon", name = "무명 노인", at = Vector3.new(-2100, 1.6, 2100), region = "운해 끝자락", quote = "하늘은 닫힌 적이 없다. 네가 열지 않았을 뿐.",
	rumor = "남서쪽 세상 끝, 구름이 땅에 닿는 곳에 이름 없는 노인이 앉아 있다더라", secret = true }
Config.MASTERS.gaecheon = { name = Config.SECRET_MASTER.name, at = Config.SECRET_MASTER.at, region = Config.SECRET_MASTER.region, regionId = "secret",
	quote = Config.SECRET_MASTER.quote, rumor = Config.SECRET_MASTER.rumor, secret = true }
-- 궁극의 사부: 천외봉 아래의 시원자. 천외천에 오른 자에게만 시험을 허락한다 (지도에 나오지 않는다)
Config.MASTERS.taecho = { name = "시원자", at = Vector3.new(0, 3.2, -3080), region = "천외봉", regionId = "skysea", secret = true,
	quote = "처음에는 아무것도 없었다. 그래서 무엇이든 될 수 있었다.", rumor = "북쪽 끝 구름바다 위, 하늘에 닿은 봉우리 아래에 세상의 처음을 아는 이가 서 있다더라" }
-- 정점의 사부: 동남쪽 끝 일월대의 권존. 태초신권을 익힌 천외천의 고수에게만 시험을 허락한다 (지도에 나오지 않는다)
Config.MASTERS.ilwol = { name = "권존", at = Vector3.new(2500, 6.2, 2500), region = "일월대", regionId = "sunmoon", secret = true,
	quote = "해는 지고 달은 뜬다. 나는 늘 그 사이에 서 있었다.", rumor = "동남쪽 세상 끝, 해와 달이 함께 뜨는 단 위에 주먹 하나로 정점에 선 이가 있다더라" }
-- 비급 조각 다섯: 강호의 외진 곳에 숨어 있다. 다 모으면 무극신권
Config.Fragments = {
	{ at = Vector3.new(-300, 10.6, 540), hint = "거신상의 발치" },
	{ at = Vector3.new(-1050, 1, -550), hint = "수정 들판 한가운데" },
	{ at = Vector3.new(630, 1, 32), hint = "비류 폭포 뒤" },
	{ at = Vector3.new(-380, 1, -1950), hint = "북방 설산의 얼음 벼랑" },
	{ at = Vector3.new(320, 1, 1700), hint = "독안개 늪의 무너진 사당" },
}

Config.INN_AT = Vector3.new(82, 0, 40)
Config.ELDER_AT = Vector3.new(-24, 0, -104)

-- 이야기 (강호 이야기): 차례로 이어지는 장. goal = { kind, id, n, at }
Config.Story = {
	{ title = "강호의 문", text = "젊은이, 맨손으로 강호에 나서겠다고? 좋다. 우선 기본부터. 삼재권은 이미 네 몸에 있다. 마을 남쪽 들판의 무뢰배들이 요즘 행패가 심하니, 그놈들부터 손봐 주게.", goal = { kind = "talk" }, reward = { coins = 50 } },
	{ title = "들판의 무뢰배", text = "들판의 무뢰배 다섯을 쓰러뜨려라. 마구 휘두르지 말고, 놈들이 칠 때 F로 흘린 뒤 파고들어라.", goal = { kind = "kill", id = "thug", n = 5, at = Vector3.new(0, 0, 330) }, reward = { coins = 80, stats = 10 } },
	{ title = "몸을 만드는 법", text = "주먹은 몸에서 나온다. 마을 수련터에서 여덟 번 수련하라. 박자를 맞추면 두 배다.", goal = { kind = "train", n = 8, at = Vector3.new(-70, 0, -40) }, reward = { coins = 80, stats = 10 } },
	{ title = "산적의 그림자", text = "서쪽 대나무 숲과 동쪽 계곡에 산적 떼가 진을 쳤다. 산적 도객 여섯을 꺾어라.", goal = { kind = "kill", id = "bandit", n = 6, at = Vector3.new(-300, 0, 120) }, reward = { coins = 150, stats = 15 } },
	{ title = "사부를 찾아서", text = "삼재권만으로는 멀리 못 간다. 강호에는 여덟 사부가 숨어 산다. 안내판의 소문을 따라 한 분을 찾아가라. 남쪽 주막의 취한 노인 이야기가 가장 가깝지.", goal = { kind = "found", n = 1, at = Vector3.new(0, 0, 620) }, reward = { coins = 200 } },
	{ title = "사부의 시험", text = "사부는 아무나 받지 않는다. 사부 곁에서 T를 눌러 시험을 청하고, 사부의 분신을 꺾어라.", goal = { kind = "trial", n = 1 }, reward = { coins = 300, stats = 20 } },
	{ title = "첫 진짜 권법", text = "시험을 넘었다면 은자를 바치고 그 권법을 배워라.", goal = { kind = "learn", n = 2 }, reward = { coins = 200 } },
	{ title = "일류의 벽", text = "수련과 싸움으로 능력치를 쌓아 일류에 올라라. 경지가 오를 때마다 몸이 크게 달라진다.", goal = { kind = "realm", n = 3 }, reward = { coins = 400, stats = 30 } },
	{ title = "흑호채", text = "먼 북쪽 산적 소굴의 두목 흑호가 마을을 노린다. 놈을 꺾어라.", goal = { kind = "boss", id = "heukho", at = Vector3.new(0, 0, -1020) }, reward = { coins = 800, stats = 50 } },
	{ title = "흩어진 비급", text = "옛 고수가 남긴 비급이 다섯 조각으로 흩어졌다는 소문이 있다. 두 조각을 찾아라. 지도에서 볼 수 없으니 발로 찾아야 한다.", goal = { kind = "fragment", n = 2 }, reward = { coins = 500, stats = 40 } },
	{ title = "혈월곡의 혈랑", text = "남동쪽 끝 핏빛 달 아래에 혈교의 앞잡이 혈랑이 있다. 놈을 쓰러뜨려라.", goal = { kind = "boss", id = "hyeolrang", at = Vector3.new(1080, 0, 1080) }, reward = { coins = 1200, stats = 80 } },
	{ title = "절정에 오르다", text = "혈교와 맞서려면 절정의 경지가 필요하다. 경지별 수련과 사부들의 권법으로 몸을 끌어올려라.", goal = { kind = "realm", n = 5 }, reward = { coins = 1500, stats = 100 } },
	{ title = "설산의 빙마", text = "북방 설산의 주인 빙마가 혈교와 손을 잡았다. 얼음을 깨고 놈을 쓰러뜨려라.", goal = { kind = "boss", id = "bingma", at = Vector3.new(0, 0, -1980) }, reward = { coins = 2500, stats = 150 } },
	{ title = "혈교의 그림자", text = "북동쪽 끝 혈교 본산. 혈교도 열을 꺾고 길을 열어라.", goal = { kind = "kill", id = "cultist", n = 10, at = Vector3.new(1600, 0, -1550) }, reward = { coins = 2500, stats = 150 } },
	{ title = "혈마", text = "혈교의 주인 혈마. 모든 것을 걸고 맞서라. 그를 꺾으면 그 손이 네 것이 된다.", goal = { kind = "boss", id = "hyeolma", at = Vector3.new(1800, 0, -1950) }, reward = { coins = 6000, stats = 300 } },
	{ title = "무극에 오르다", text = "혈마도 쓰러졌다. 그러나 북서쪽 끝 허공 균열에서 더 깊은 어둠이 새어 나온다. 무극의 경지에 올라라. 권법을 깨달음으로 승급시키는 것도 잊지 마라.", goal = { kind = "realm", n = 13 }, reward = { coins = 10000, stats = 500 } },
	{ title = "이름 없는 노인", text = "무극에 오른 자는 들을 수 있다는 소문. 남서쪽 세상 끝, 구름이 땅에 닿는 곳에 이름 없는 노인이 있다. 그에게서 하늘을 여는 주먹을 얻어라.", goal = { kind = "learn", id = "gaecheon", n = 1 }, reward = { coins = 15000, stats = 800 } },
	{ title = "허공 균열", text = "허공 균열의 천마 사도 여섯을 꺾고 길을 열어라.", goal = { kind = "kill", id = "apostle", n = 6, at = Vector3.new(-1800, 0, -1850) }, reward = { coins = 20000, stats = 1000 } },
	{ title = "천마", text = "하늘을 삼킨 마귀, 천마. 강호의 마지막 적이다.", goal = { kind = "boss", id = "cheonma", at = Vector3.new(-1950, 0, -1950) }, reward = { coins = 50000, stats = 3000 } },
	{ title = "깨어난 화염산", text = "천마가 쓰러지자 동쪽 끝 화염산이 깨어났다. 불의 산 아래 염제를 꺾어라.", goal = { kind = "boss", id = "yeomje", at = Vector3.new(2950, 0, -1150) }, reward = { coins = 60000, stats = 3500 } },
	{ title = "모래 왕릉", text = "남쪽 끝 모래 왕릉에서 사왕이 무덤을 박차고 일어났다. 왕릉으로 가 사왕을 다시 눕혀라.", goal = { kind = "boss", id = "sawang", at = Vector3.new(-900, 0, 2930) }, reward = { coins = 70000, stats = 4000 } },
	{ title = "하늘 문지기", text = "북쪽 끝 구름바다 위, 천외봉으로 가는 길을 천문장이 막고 있다.", goal = { kind = "boss", id = "cheonmun", at = Vector3.new(0, 0, -2760) }, reward = { coins = 90000, stats = 5000 } },
	{ title = "하늘 밖의 하늘", text = "경지의 끝, 천외천에 올라라. 하늘 밖에 하늘이 있다.", goal = { kind = "realm", n = 16 }, reward = { coins = 100000, stats = 5000 } },
	{ title = "태초", text = "천외봉 아래 시원자를 찾아 시험을 넘고 태초신권을 얻어라. 세상이 처음 열리던 그 한 주먹이다.", goal = { kind = "learn", id = "taecho", n = 1 }, reward = { coins = 200000, stats = 10000 } },
	{ title = "정점", text = "태초의 주먹마저 쥐었다면 들어라. 동남쪽 세상 끝 일월대에 해와 달을 두 손에 쥔 권존이 있다. 그를 넘어 일월신권을 얻어라. 그것이 권법의 정점이다.", goal = { kind = "learn", id = "ilwol", n = 1 }, reward = { coins = 500000, stats = 30000 } },
	{ title = "강호의 전설", text = "이제 강호에 네 이름을 모르는 자가 없다. 남은 비급 조각, 열다섯 권법의 완전 각성과 승급. 그리고 너는 이제 권왕이다. 길은 끝이 없다.", goal = { kind = "done" }, reward = {} },
}

-- 큰 볼거리 (지도에도 나온다)
Config.Landmarks = {
	{ id = "colossus", name = "거신상", icon = "🗿", at = Vector3.new(-300, 0, 520) },
	{ id = "skyring", name = "하늘 고리", icon = "⭕", at = Vector3.new(380, 0, 300) },
	{ id = "colosseum", name = "옛 투기장", icon = "🏟", at = Vector3.new(-380, 0, -430) },
	{ id = "crystals", name = "수정 들판", icon = "💎", at = Vector3.new(-1050, 0, -550) },
	{ id = "worldtree", name = "천년 고목", icon = "🌳", at = Vector3.new(380, 0, -1000) },
	{ id = "moon", name = "핏빛 달", icon = "🌕", at = Vector3.new(1000, 0, 1000) },
	{ id = "swordtomb", name = "만검총", icon = "🗡", at = Vector3.new(1300, 0, -1000) },
	{ id = "skybridge", name = "끊어진 하늘다리", icon = "🌉", at = Vector3.new(1400, 0, 1400) },
	{ id = "dragonbones", name = "용의 무덤", icon = "🦴", at = Vector3.new(-1200, 0, -1080) },
	{ id = "volcano", name = "불의 산", icon = "🌋", at = Vector3.new(3080, 0, -700) },
	{ id = "pyramid", name = "사왕의 무덤", icon = "🔺", at = Vector3.new(-900, 0, 3140) },
	{ id = "skyspire", name = "천외봉", icon = "✴", at = Vector3.new(0, 0, -3180) },
	{ id = "sunmoon", name = "일월대", icon = "☀", at = Vector3.new(2500, 0, 2640) },
}
-- 적은 마을에서 멀수록 세다: 250칸 넘으면 100칸마다 한 단계
function Config.enemyLevel(home: Vector3): number
	local d = Vector3.new(home.X, 0, home.Z).Magnitude
	return 1 + math.floor(math.max(0, d - 250) / 100)
end
Config.MASTER_RANGE = 26 -- 사부 곁 이만큼 안에서 배운다
Config.WORLD_HALF = 3400 -- 세상 끝 (가운데에서). 바깥 여덟 땅까지
-- 마을에서 각 곳으로 가는 흙길 (꺾이는 점들)
Config.Roads = {
	{ Vector3.new(-178, 0, 0), Vector3.new(-1000, 0, 0) },
	{ Vector3.new(178, 0, 0), Vector3.new(560, 0, 0) },
	{ Vector3.new(0, 0, -178), Vector3.new(0, 0, -740) },
	{ Vector3.new(0, 0, 178), Vector3.new(0, 0, 640) },
	{ Vector3.new(-178, 0, 0), Vector3.new(-260, 0, -60), Vector3.new(-650, 0, -560) },
	{ Vector3.new(178, 0, 0), Vector3.new(260, 0, -60), Vector3.new(650, 0, -560) },
	{ Vector3.new(0, 0, 178), Vector3.new(-90, 0, 230), Vector3.new(-600, 0, 600) },
	{ Vector3.new(0, 0, 178), Vector3.new(90, 0, 230), Vector3.new(600, 0, 600) },
	{ Vector3.new(178, 0, 0), Vector3.new(380, 0, -280), Vector3.new(890, 0, -280) },
	{ Vector3.new(600, 0, 600), Vector3.new(840, 0, 560), Vector3.new(960, 0, 900) },
	-- 바깥 다섯 땅으로
	{ Vector3.new(0, 0, -740), Vector3.new(260, 0, -720), Vector3.new(260, 0, -1250), Vector3.new(0, 0, -1380) },
	{ Vector3.new(0, 0, 810), Vector3.new(0, 0, 1210) },
	{ Vector3.new(1000, 0, -130), Vector3.new(1180, 0, 0), Vector3.new(1380, 0, 0) },
	{ Vector3.new(-1000, 0, 0), Vector3.new(-1380, 0, 0) },
	{ Vector3.new(1700, 0, -430), Vector3.new(1700, 0, -1400) },
	{ Vector3.new(-1380, 0, 0), Vector3.new(-1450, 0, -700), Vector3.new(-1500, 0, -1400) },
	{ Vector3.new(-600, 0, 600), Vector3.new(-850, 0, 850), Vector3.new(-1100, 0, 1060) },
	-- 더 바깥 세 땅으로
	{ Vector3.new(2070, 0, -100), Vector3.new(2420, 0, -420), Vector3.new(2650, 0, -800) },
	{ Vector3.new(0, 0, 1210), Vector3.new(-250, 0, 1950), Vector3.new(-650, 0, 2420), Vector3.new(-860, 0, 2700) },
	{ Vector3.new(0, 0, -1380), Vector3.new(-120, 0, -2000), Vector3.new(-40, 0, -2460), Vector3.new(0, 0, -2650) },
}

Config.ENEMY_DMG = 1.35 -- 적의 공격이 아프다 (막고 흘리지 않으면 버티기 어렵다)
-- 베타 8: 적은 훨씬 질기고 (체력 ×2.2, 멀수록 더), 후반 적의 피해는 크게 줄였다 (오래 겨루는 싸움)
Config.ENEMY_HP = 2.2
Config.ENEMY_BOSS_HP = 1.6
Config.ENEMY_HP_LEVEL = 0.35 -- 단계마다 체력 +35%
Config.ENEMY_DMG_LEVEL = 0.12 -- 단계마다 피해 +12%
Config.ENEMY_DMG_MULT_POW = 0.6 -- 후반 땅의 겹 배율(mult)은 피해에 이만큼의 거듭제곱으로만 (×14 → ×4.9)
-- 전투력: 피해 배율과 체력으로 잰다. 차이가 크면 약한 쪽의 공격은 통하지 않는다
function Config.playerPower(dmgMult: number, maxHp: number): number
	return math.floor(100 * math.sqrt(math.max(0.01, dmgMult) * math.max(1, maxHp) / 100))
end
function Config.enemyPower(dmgMult: number, hp: number, boss: boolean?): number
	return math.floor(100 * math.sqrt((dmgMult / Config.ENEMY_DMG) * math.max(1, hp) / (120 * Config.ENEMY_HP)) * (boss and 1.5 or 1))
end
-- 내 전투력 ÷ 적 전투력: soft 넘으면 덜 아프고, steady 넘으면 끄떡없고 (경직·균형 없음), immune 넘으면 호신강기에 튕겨 나간다
Config.POWER_GAP = { soft = 1.6, steady = 2.5, immune = 4 }
function Config.powerGap(ratio: number): (number, boolean, boolean)
	local G = Config.POWER_GAP
	if ratio >= G.immune then
		return 0, true, true
	elseif ratio >= G.steady then
		return 0.2, true, false
	elseif ratio >= G.soft then
		return 0.5, false, false
	end
	return 1, false, false
end
Config.MAX_ATTACKERS = 2 -- 한 사람을 한꺼번에 치는 적은 둘까지 (나머지는 둘레를 돌며 틈을 본다)
Config.NO_RED_LEVEL = 3 -- 이 단계 이하의 약한 적은 붉은 공격(막을 수 없는 공격)을 쓰지 않는다
Config.ENEMY_ACTIVE_RANGE = 170 -- 이 안에 사람이 있어야 적이 움직인다
Config.ENEMY_RESPAWN = 25

-- 비무대 (마을 안). 위에 선 사람끼리만 서로 때릴 수 있다
Config.RING = { center = Vector3.new(0, 0, 90), size = 56, height = 3 }

-- 수련 자리 (종류, 자리)
Config.TrainingSpots = {
	{ kind = "rock", at = Vector3.new(-60, 0, -40) },
	{ kind = "rock", at = Vector3.new(-80, 0, -40) },
	{ kind = "dummy", at = Vector3.new(60, 0, -40) },
	{ kind = "dummy", at = Vector3.new(80, 0, -40) },
	{ kind = "waterfall", at = Vector3.new(560, 0, -10) },
	{ kind = "waterfall", at = Vector3.new(580, 0, 15) },
	{ kind = "bamboo", at = Vector3.new(-380, 0, -10) },
	{ kind = "mabo", at = Vector3.new(-105, 0, -15) },
	{ kind = "mabo", at = Vector3.new(-105, 0, 5) },
	{ kind = "ironpalm", at = Vector3.new(105, 0, -15) },
	{ kind = "ironpalm", at = Vector3.new(105, 0, 5) },
	{ kind = "breathing", at = Vector3.new(372, 0, 306) },
	{ kind = "breathing", at = Vector3.new(388, 0, 294) },
	{ kind = "simma", at = Vector3.new(-380, 0, -430) },
}
Config.SPAWN = Vector3.new(0, 4, -20)

------------------------------------------------------------------------
-- 상점 (마을)
------------------------------------------------------------------------
Config.Shop = {
	{ id = "potion", name = "금창약", icon = "🧪", desc = "체력 40% 회복 (H키, 최대 5개)", cost = 40, max = 5 },
	{ id = "elixir", name = "소환단", icon = "💊", desc = "5분 동안 수련 효과 2배", cost = 250 },
	{ id = "pill", name = "대환단", icon = "🔮", desc = "모든 능력치 +10 (영구)", cost = 1500 },
}
Config.SHOP_BY_ID = {}
for _, it in ipairs(Config.Shop) do
	Config.SHOP_BY_ID[it.id] = it
end
Config.POTION_HEAL = 0.4

------------------------------------------------------------------------
-- 로벅스 상품 (게임패스). gamepass = 로블록스 홈페이지에 만든 게임패스 번호 (0이면 아직 없음)
------------------------------------------------------------------------
Config.Premium = {
	{ id = "train2x", gamepass = 0, price = 199, icon = "🔥", name = "두 배 수련", tag = "영구",
		lines = { "모든 수련의 능력치가 영원히 두 배", "소환단·강화 수련·자동 수련과 겹친다", "심마 대련 보상도 두 배" } },
	{ id = "autoTrain", gamepass = 0, price = 149, icon = "🤖", name = "자동 수련", tag = "영구", toggle = true,
		lines = { "켜 두면 3초마다 저절로 수련 한 번", "올릴 능력치를 고르거나 골고루 (근골·체력·경공·내공)", "싸우지 않을 땐 어디서나: 걷고, 쉬고, 구경해도 오른다" } },
	{ id = "autoTrain2", gamepass = 0, price = 399, icon = "⚙", name = "고급 자동 수련", tag = "영구", toggle = true, best = true,
		lines = { "1초마다 '완벽' 판정으로 자동 수련 (보통의 여섯 배 넘게)", "경지가 열어 준 좋은 수련으로 (철사장·마보·운기조식)", "싸우는 중에도 멈추지 않는다" } },
}
-- 자동 수련: every = 간격(초). kinds = 능력치마다 보통 수련, advKinds = 고급이 쓰는 경지 수련
Config.AUTO_TRAIN = {
	every = 3,
	advEvery = 1,
	advMult = 1,
	kinds = { str = "rock", vit = "dummy", agi = "bamboo", chi = "waterfall" },
	advKinds = { str = "ironpalm", vit = "mabo", agi = "bamboo", chi = "breathing" },
}
Config.PREMIUM_BY_ID = {}
for _, it in ipairs(Config.Premium) do
	Config.PREMIUM_BY_ID[it.id] = it
end

------------------------------------------------------------------------
-- 숫자
------------------------------------------------------------------------
local SUFFIXES = { "", "K", "M", "B", "T" }
function Config.formatNumber(n: number): string
	if n ~= n then
		return "0"
	end
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local i = 1
	while n >= 1000 and i < #SUFFIXES do
		n /= 1000
		i += 1
	end
	return string.format(n >= 100 and "%.0f%s" or "%.1f%s", n, SUFFIXES[i])
end

return Config
