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
Config.POSTURE_REGEN = 14 -- 1초에 회복 (마지막으로 맞고 1.5초 뒤부터)
Config.POSTURE_REGEN_DELAY = 1.5
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

function Config.walkSpeed(agi: number): number
	return Config.WALK_SPEED * (0.85 + 0.15 * Config.statMult(agi))
end

-- 경지: 능력치 합으로 정해진다. 경지가 오를 때마다 피해·체력 +15% (경지 배율), 수련 효과 +25%
-- 삼류·일류·특급·사경에 이르면 그 경지의 새 수련이 열린다
Config.Realms = {
	{ name = "삼류", need = 0, color = Color3.fromRGB(200, 200, 200) },
	{ name = "이류", need = 100, color = Color3.fromRGB(150, 220, 150) },
	{ name = "일류", need = 400, color = Color3.fromRGB(110, 190, 255) },
	{ name = "특급", need = 1000, color = Color3.fromRGB(90, 230, 200) },
	{ name = "절정", need = 2200, color = Color3.fromRGB(190, 130, 255) },
	{ name = "초절정", need = 4500, color = Color3.fromRGB(255, 190, 70) },
	{ name = "화경", need = 8500, color = Color3.fromRGB(255, 110, 80) },
	{ name = "현경", need = 15000, color = Color3.fromRGB(120, 255, 230) },
	{ name = "사경", need = 26000, color = Color3.fromRGB(255, 80, 120) },
	{ name = "생사경", need = 42000, color = Color3.fromRGB(255, 255, 255) },
	{ name = "신화경", need = 65000, color = Color3.fromRGB(255, 220, 120) },
	{ name = "천인합일", need = 100000, color = Color3.fromRGB(160, 220, 255) },
	{ name = "무극", need = 150000, color = Color3.fromRGB(255, 150, 255) },
	-- 무극 너머 (허공 균열의 적과 천마를 상대하려면)
	{ name = "반선", need = 230000, color = Color3.fromRGB(200, 255, 255) },
	{ name = "등선", need = 340000, color = Color3.fromRGB(255, 240, 200) },
	{ name = "천외천", need = 500000, color = Color3.fromRGB(255, 255, 160) },
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
	ironpalm = { name = "철사장 수련", stat = "str", gains = { str = 4, vit = 1 }, icon = "🔥", desc = "달군 쇠모래가 튀어 오를 때 내리치세요 (빠르다)", base = 1, realm = 3, period = 1.0 },
	breathing = { name = "운기조식", stat = "chi", gains = { chi = 5, vit = 2 }, icon = "🌀", desc = "기가 몸을 한 바퀴 돌아 가득 찰 때 누르세요", base = 1, realm = 4 },
	simma = { name = "심마 대련", stat = "str", icon = "👁", desc = "마음속의 마귀가 형체를 얻는다. 이기면 모든 능력치가 크게 오른다", base = 1, realm = 9, fight = true, reward = 60 },
}
Config.TRAIN_COOLDOWN = 0.6 -- 한 번 수련하고 다음까지
-- 강화 수련: 박자가 빠르고 판정이 좁지만 얻는 능력치가 세 배. 경지 이류부터
Config.HARD_TRAIN = { mult = 3, realm = 2, period = 0.9, perfect = 0.045, good = 0.1 }

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
			R = { id = "thR", name = "선풍기류", desc = "주변을 끌어당기는 물의 소용돌이 (균형을 크게 깎는다)", pose = "water_spiral", dur = 0.9, cd = 11, chi = 25,
				hits = { hit(0.25, 0, 11, 5, 12, 0.4, -12, nil, true), hit(0.5, 0, 11, 5, 12, 0.4, -12, nil, true), hit(0.75, 0, 11, 8, 18, 0.6, 20, nil, true) } },
			G = { id = "thG", name = "만류귀종", desc = "모든 흐름이 하나로 돌아온다. 거대한 물의 용이 휘감는다", pose = "ult_tide", dur = 1.6, cd = 30, chi = 100, armor = true,
				hits = { hit(0.6, 0, 16, 12, 30, 0.8, -10, nil, true), hit(1.0, 0, 16, 12, 30, 0.8, -10, nil, true), hit(1.35, 0, 18, 30, 60, 1.4, 60, 25, true) } },
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
			R = { id = "ggR", name = "사자후", desc = "사자의 포효. 주변의 적을 모두 기절시킨다", pose = "roar", dur = 0.8, cd = 12, chi = 30,
				hits = { hit(0.3, 0, 14, 6, 25, 1.4, 25, nil, true) } },
			G = { id = "ggG", name = "여래신장", desc = "하늘에서 거대한 금빛 손바닥이 내려찍는다", pose = "ult_buddha", dur = 1.5, cd = 30, chi = 100, armor = true,
				hits = { hit(1.0, 6, 14, 55, 90, 1.6, 30, nil, true) } },
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
			R = { id = "mhR", name = "암향표", desc = "향기만 남기고 사라지는 걸음. 지나간 길의 적을 벤다 (무적)", pose = "fragrance_step", dur = 0.45, cd = 9, chi = 20, lunge = 22, iframes = 0.4,
				hits = { hit(0.15, 4, 5, 9, 10, 0.4, 8) } },
			G = { id = "mhG", name = "매화만개", desc = "천 송이 매화가 한꺼번에 피어나는 꽃잎 폭풍", pose = "ult_bloom", dur = 1.8, cd = 30, chi = 100, armor = true,
				hits = { hit(0.3, 0, 14, 7, 10, 0.4, -4, nil, true), hit(0.6, 0, 14, 7, 10, 0.4, -4, nil, true), hit(0.9, 0, 14, 7, 10, 0.4, -4, nil, true),
					hit(1.2, 0, 14, 7, 10, 0.4, -4, nil, true), hit(1.55, 0, 16, 25, 40, 1.0, 50, 15, true) } },
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
			G = { id = "crG", name = "구룡승천", desc = "아홉 마리 용이 땅을 뚫고 하늘로 솟는다", pose = "ult_dragon", dur = 1.7, cd = 30, chi = 100, armor = true,
				hits = { hit(0.7, 0, 18, 14, 20, 0.6, 5, 30, true), hit(1.0, 0, 18, 14, 20, 0.6, 5, 30, true), hit(1.3, 0, 20, 30, 50, 1.3, 40, 50, true) } },
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
			G = { id = "myG", name = "무영천각", desc = "모습을 감추고 여섯 그림자가 사방에서 찬다", pose = "ult_shadow", dur = 1.8, cd = 30, chi = 100, iframes = 1.6,
				hits = { hit(0.3, 0, 15, 9, 12, 0.5, 4, nil, true), hit(0.55, 0, 15, 9, 12, 0.5, 4, nil, true), hit(0.8, 0, 15, 9, 12, 0.5, 4, nil, true),
					hit(1.05, 0, 15, 9, 12, 0.5, 4, nil, true), hit(1.3, 0, 15, 9, 12, 0.5, 4, nil, true), hit(1.6, 0, 16, 28, 40, 1.2, 45, 20, true) } },
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
			R = { id = "bkR", name = "뇌격", desc = "하늘에서 주변 적에게 벼락을 내리꽂는다", pose = "point_sky", dur = 0.8, cd = 11, chi = 25,
				hits = { hit(0.45, 0, 18, 16, 20, 1.0, 10, nil, true) }, strike = true },
			G = { id = "bkG", name = "천뢰멸", desc = "하늘이 갈라지며 벼락 폭풍이 쏟아진다", pose = "ult_thunder", dur = 1.8, cd = 30, chi = 100, armor = true, strike = true,
				hits = { hit(0.6, 0, 20, 12, 15, 0.8, 5, nil, true), hit(0.9, 0, 20, 12, 15, 0.8, 5, nil, true), hit(1.2, 0, 20, 12, 15, 0.8, 5, nil, true), hit(1.5, 0, 22, 30, 45, 1.5, 40, 15, true) } },
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
			R = { id = "cwR", name = "팔선과해", desc = "여덟 신선이 바다를 건너듯 빙글빙글 돌며 친다", pose = "drunk_roll", dur = 1.0, cd = 10, chi = 25,
				hits = { hit(0.2, 0, 8, 5, 6, 0.35, 3, nil, true), hit(0.4, 0, 8, 5, 6, 0.35, 3, nil, true), hit(0.6, 0, 8, 5, 6, 0.35, 3, nil, true), hit(0.85, 0, 9, 10, 14, 0.6, 30, nil, true) } },
			G = { id = "cwG", name = "취화난무", desc = "취기가 불길이 되어 뿜어져 나온다", pose = "fire_breath", dur = 1.8, cd = 30, chi = 100, armor = true,
				hits = { hit(0.4, 12, 7, 8, 10, 0.4, 6), hit(0.7, 12, 7, 8, 10, 0.4, 6), hit(1.0, 12, 7, 8, 10, 0.4, 6), hit(1.3, 12, 7, 8, 10, 0.4, 6), hit(1.6, 13, 8, 22, 35, 1.0, 45) } },
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
		G = { id = "sjG", name = "삼재합일", desc = "하늘·땅·사람의 기운을 한 주먹에 모아 땅을 친다", pose = "ult_slam", dur = 1.4, cd = 30, chi = 100, armor = true,
			hits = { hit(0.7, 0, 10, 26, 40, 0.9, 40, 14, true) } },
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
		R = { id = "mgR", name = "무극회선", desc = "주변의 모든 것을 끌어당겨 한 점에서 터뜨린다", pose = "void_gather", dur = 0.9, cd = 9, chi = 25, pull = 14,
			hits = { hit(0.3, 0, 12, 10, 20, 0.5, -10, nil, true), hit(0.7, 0, 12, 24, 40, 0.8, 40, 20, true) } },
		G = { id = "mgG", name = "무극귀일", desc = "하늘과 땅이 한 점으로 돌아간다. 둘레의 모든 적을 지운다", pose = "ult_void", dur = 1.8, cd = 28, chi = 100, armor = true,
			hits = { hit(0.6, 0, 18, 30, 60, 1.0, 20, 20, true), hit(1.3, 0, 20, 60, 90, 1.2, 60, 30, true) } },
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
		R = { id = "hmR", name = "혈해", desc = "둘레에 피의 바다를 일으킨다", pose = "blood_spread", dur = 0.9, cd = 10, chi = 25,
			hits = { hit(0.3, 0, 13, 20, 30, 0.7, 30, nil, true) } },
		G = { id = "hmG", name = "혈마강림", desc = "혈마가 강림해 모든 것을 베어 낸다", pose = "ult_blood", dur = 1.8, cd = 30, chi = 100, armor = true,
			hits = { hit(0.4, 0, 12, 18, 20, 0.4, 6, nil, true), hit(0.8, 0, 12, 18, 20, 0.4, 6, nil, true), hit(1.2, 0, 12, 18, 20, 0.4, 6, nil, true), hit(1.6, 0, 14, 50, 60, 1.0, 50, nil, true) } },
	},
})
-- 시크릿 권법: 무극의 경지에 오른 자만 숨은 사부를 찾아 익힌다 (지도에 나오지 않는다)
table.insert(Config.Styles, {
	id = "gaecheon",
	name = "개천신권",
	hanja = "開天神拳",
	icon = "🌠",
	color = Color3.fromRGB(150, 200, 255),
	color2 = Color3.fromRGB(255, 245, 190),
	fx = "cosmic",
	grade = "천외",
	hidden = true,
	secret = true,
	realmReq = 13,
	unlockHint = "무극의 경지에 오른 자만이 이름 없는 노인을 만난다. 강호의 끝, 아무도 가지 않는 구석에서",
	desc = "하늘을 여는 주먹. 별을 꿰어 나선으로 지르고, 손날 하나로 하늘을 가른다. 이 손에 닿은 것은 별빛이 되어 흩어진다.",
	gimmick = "개천: 다섯 번 맞힐 때마다 별이 떨어져 둘레를 친다. 흘리기 판정이 넓고 균형을 1.5배로 깎는다",
	deflect = 0.3,
	postureMult = 1.5,
	starEvery = 5,
	stance = "stance_gaecheon",
	combo = {
		{ id = "gc1", name = "성환권", pose = "star_punch_r", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4, 13, 12, 0.35, 8) } },
		{ id = "gc2", name = "역성권", pose = "star_punch_l", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4, 13, 12, 0.35, 8) } },
		{ id = "gc3", name = "천월각", pose = "heaven_kick", dur = 0.42, lunge = 2, hits = { hit(0.24, 6, 5.5, 16, 16, 0.4, 14) } },
		{ id = "gc4", name = "은하장", pose = "galaxy_palm", dur = 0.5, lunge = 3, hits = { hit(0.28, 8, 6, 24, 30, 0.6, 40) } },
	},
	heavy = { id = "gcH", name = "개천일도", pose = "heaven_split", dur = 0.7, lunge = 6, hits = { hit(0.36, 9, 7, 38, 60, 0.9, 50, 10, true) } },
	skills = {
		E = { id = "gcE", name = "유성추", desc = "높이 솟았다가 유성처럼 내리꽂는다 (떨어진 자리 둘레를 친다)", pose = "meteor_drop", dur = 0.9, cd = 7, chi = 20, jump = 55, lunge = 10,
			hits = { hit(0.68, 0, 13, 34, 40, 0.8, 30, 14, true) } },
		R = { id = "gcR", name = "낙성우", desc = "하늘에서 별비가 쏟아진다 (둘레를 세 번 친다)", pose = "starfall", dur = 1.1, cd = 10, chi = 30,
			hits = { hit(0.5, 0, 16, 16, 20, 0.5, 10, nil, true), hit(0.75, 0, 16, 16, 20, 0.5, 10, nil, true), hit(0.95, 0, 18, 26, 30, 0.8, 30, nil, true) } },
		G = { id = "gcG", name = "개천벽지", desc = "하늘을 열어 젖힌다. 별이 무너져 내려 모든 것을 지운다", pose = "ult_heaven", dur = 2.0, cd = 28, chi = 100, armor = true,
			hits = { hit(0.55, 0, 16, 25, 30, 0.5, 10, 20, true), hit(1.0, 0, 18, 25, 30, 0.5, 10, nil, true), hit(1.45, 0, 18, 25, 30, 0.5, 10, nil, true), hit(1.76, 0, 24, 90, 120, 1.4, 70, 30, true) } },
	},
})
-- 권법 등급: 높을수록 같은 숙련에서 더 세다 (여덟 단계)
Config.GRADE_ORDER = { "하급", "중급", "상급", "최상급", "절세", "전설", "신화", "천외" }
Config.GRADES = { ["하급"] = 0.85, ["중급"] = 1.0, ["상급"] = 1.15, ["최상급"] = 1.3, ["절세"] = 1.45, ["전설"] = 1.65, ["신화"] = 1.9, ["천외"] = 2.25 }
Config.GRADE_COLOR = {
	["하급"] = Color3.fromRGB(190, 190, 190),
	["중급"] = Color3.fromRGB(140, 220, 140),
	["상급"] = Color3.fromRGB(120, 190, 255),
	["최상급"] = Color3.fromRGB(90, 230, 230),
	["절세"] = Color3.fromRGB(220, 130, 255),
	["전설"] = Color3.fromRGB(255, 200, 80),
	["신화"] = Color3.fromRGB(255, 120, 90),
	["천외"] = Color3.fromRGB(255, 255, 210),
}
for _, st in ipairs(Config.Styles) do
	local g = ({ taeheo = "상급", geumgang = "상급", cheonryong = "최상급", maehwa = "중급", muyeong = "상급", byeokryeok = "중급", chwi = "중급", hyeolma = "전설", mugeuk = "신화" })[st.id]
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
	local i = math.min(#Config.GRADE_ORDER, Config.gradeIndex(style.grade) + (up or 0))
	return Config.GRADE_ORDER[i]
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
	gaecheon = { name = "개천승룡각", pose = "heaven_kick" },
}
for id, fin in pairs(FINISHERS) do
	local s = Config.STYLE_BY_ID[id]
	s.finisher = { id = id .. "F", name = fin.name, pose = fin.pose, dur = 0.62, lunge = 4, launcher = true, hits = { hit(0.26, 6, 5, 16, 24, 0.7, 6, 62) } }
end

-- 연타 박자: 앞 동작이 이만큼 지났을 때 누르면 '딱 맞음(連)', 너무 일찍 두 번 누르면 흐트러진다
Config.RHYTHM = { early = 0.45, perfectFrom = 0.62, perfectTo = 1.0, late = 0.18, bonus = 1.15, chain = 3, chainBonus = 1.3, breakLock = 0.4 }

-- 권법 배우는 값 (이미 배운 권법 수에 따라). 첫 권법은 공짜
Config.LEARN_COST = { 0, 300, 750, 1500, 3000, 5000, 7500, 12000, 20000, 50000 }

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
local B = Config.Bosses
B.bingma = variant(B.heukho, { name = "빙마 · 설산의 주인", shirt = Color3.fromRGB(200, 230, 255), pants = Color3.fromRGB(80, 110, 150), hp = 1600, posture = 320, scale = 1.6, coins = 900, xp = 300 })
B.hyeolma = variant(B.hyeolrang, { name = "혈마 · 혈교의 주인", shirt = Color3.fromRGB(150, 0, 20), pants = Color3.fromRGB(20, 0, 5), hp = 2400, posture = 420, scale = 1.5, speed = 23, coins = 3000, xp = 800, respawn = 300 })
B.cheonma = variant(B.hyeolrang, { name = "천마 · 하늘을 삼킨 마귀", shirt = Color3.fromRGB(25, 10, 50), pants = Color3.fromRGB(10, 0, 20), hp = 2400, posture = 520, scale = 1.75, speed = 24, coins = 12000, xp = 2000, respawn = 300, mult = 6 })

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
-- 비급 조각 다섯: 강호의 외진 곳에 숨어 있다. 다 모으면 무극신권
Config.Fragments = {
	{ at = Vector3.new(-300, 10.6, 540), hint = "거신상의 발치" },
	{ at = Vector3.new(-1050, 1, -550), hint = "수정 들판 한가운데" },
	{ at = Vector3.new(630, 1, 32), hint = "비류 폭포 뒤" },
	{ at = Vector3.new(-380, 1, -1950), hint = "북방 설산의 얼음 벼랑" },
	{ at = Vector3.new(320, 1, 1700), hint = "독안개 늪의 무너진 사당" },
}

-- 수련 기력: 수련할 때마다 줄고, 시간이 지나거나 객잔에서 쉬면 찬다
Config.STAMINA = { max = 100, cost = 2, hardCost = 4, regenEvery = 15, innCost = 60 }
Config.INN_AT = Vector3.new(82, 0, 40)
Config.ELDER_AT = Vector3.new(-24, 0, -104)

-- 이야기 (강호 이야기): 차례로 이어지는 장. goal = { kind, id, n, at }
Config.Story = {
	{ title = "강호의 문", text = "젊은이, 맨손으로 강호에 나서겠다고? 좋다. 우선 기본부터. 삼재권은 이미 네 몸에 있다. 마을 남쪽 들판의 무뢰배들이 요즘 행패가 심하니, 그놈들부터 손봐 주게.", goal = { kind = "talk" }, reward = { coins = 50 } },
	{ title = "들판의 무뢰배", text = "들판의 무뢰배 다섯을 쓰러뜨려라. 마구 휘두르지 말고, 놈들이 칠 때 F로 흘린 뒤 파고들어라.", goal = { kind = "kill", id = "thug", n = 5, at = Vector3.new(0, 0, 330) }, reward = { coins = 80, stats = 10 } },
	{ title = "몸을 만드는 법", text = "주먹은 몸에서 나온다. 마을 수련터에서 여덟 번 수련하라. 박자를 맞추면 두 배다.", goal = { kind = "train", n = 8, at = Vector3.new(-70, 0, -40) }, reward = { coins = 80, stats = 10 } },
	{ title = "산적의 그림자", text = "서쪽 대나무 숲과 동쪽 계곡에 산적 떼가 진을 쳤다. 산적 도객 여섯을 꺾어라.", goal = { kind = "kill", id = "bandit", n = 6, at = Vector3.new(-300, 0, 120) }, reward = { coins = 150, stats = 15 } },
	{ title = "사부를 찾아서", text = "삼재권만으로는 멀리 못 간다. 강호에는 일곱 사부가 숨어 산다. 안내판의 소문을 따라 한 분을 찾아가라. 남쪽 주막의 취한 노인 이야기가 가장 가깝지.", goal = { kind = "found", n = 1, at = Vector3.new(0, 0, 620) }, reward = { coins = 200 } },
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
	{ title = "강호의 전설", text = "이제 강호에 네 이름을 모르는 자가 없다. 남은 비급 조각, 천외천의 경지, 열한 권법의 완전 각성과 승급. 길은 끝이 없다.", goal = { kind = "done" }, reward = {} },
}

-- 큰 볼거리 (지도에도 나온다)
Config.Landmarks = {
	{ id = "colossus", name = "거신상", icon = "🗿", at = Vector3.new(-300, 0, 520) },
	{ id = "skyring", name = "하늘 고리", icon = "⭕", at = Vector3.new(380, 0, 300) },
	{ id = "colosseum", name = "옛 투기장", icon = "🏟", at = Vector3.new(-380, 0, -430) },
	{ id = "crystals", name = "수정 들판", icon = "💎", at = Vector3.new(-1050, 0, -550) },
	{ id = "worldtree", name = "천년 고목", icon = "🌳", at = Vector3.new(380, 0, -1000) },
	{ id = "moon", name = "핏빛 달", icon = "🌕", at = Vector3.new(1000, 0, 1000) },
}
-- 적은 마을에서 멀수록 세다: 250칸 넘으면 100칸마다 한 단계
function Config.enemyLevel(home: Vector3): number
	local d = Vector3.new(home.X, 0, home.Z).Magnitude
	return 1 + math.floor(math.max(0, d - 250) / 100)
end
Config.MASTER_RANGE = 26 -- 사부 곁 이만큼 안에서 배운다
Config.WORLD_HALF = 2400 -- 세상 끝 (가운데에서). 바깥 다섯 땅까지
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
}

Config.ENEMY_DMG = 1.5 -- 적의 공격이 아프다 (막고 흘리지 않으면 버티기 어렵다)
-- 전투력: 피해 배율과 체력으로 잰다. 차이가 크면 약한 쪽의 공격은 통하지 않는다
function Config.playerPower(dmgMult: number, maxHp: number): number
	return math.floor(100 * math.sqrt(math.max(0.01, dmgMult) * math.max(1, maxHp) / 100))
end
function Config.enemyPower(dmgMult: number, hp: number, boss: boolean?): number
	return math.floor(100 * math.sqrt((dmgMult / Config.ENEMY_DMG) * math.max(1, hp) / 120) * (boss and 1.5 or 1))
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
