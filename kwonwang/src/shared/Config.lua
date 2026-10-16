-- 권왕(拳王): 맨손의 강호. 서버와 화면이 함께 쓰는 설정
local Config = {}

Config.GAME_TITLE = "권왕(拳王)"
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
Config.WALK_SPEED = 18
Config.DASH_SPEED = 75
Config.DASH_TIME = 0.18
Config.DASH_IFRAMES = 0.22
Config.DASH_CD = 0.55
Config.DOUBLE_JUMP = 58 -- 공중에서 한 번 더 뛰는 힘
Config.RESPAWN_TIME = 4
Config.COMBAT_TAG = 6 -- 싸운 뒤 이 시간 동안은 '전투 중'

------------------------------------------------------------------------
-- 수련 능력치 4종. 효과는 로그로 완만하게 오른다 (수련 반, 실력 반)
-- 배율 = 1 + 0.25 × ln(1 + 능력치 ÷ 20)  →  100이면 ×1.45, 1000이면 ×1.98, 10000이면 ×2.55
------------------------------------------------------------------------
Config.Stats = {
	{ id = "str", name = "근골", icon = "💪", desc = "주는 피해" },
	{ id = "vit", name = "체력", icon = "❤", desc = "최대 체력" },
	{ id = "agi", name = "경공", icon = "🍃", desc = "이동 속도와 대시" },
	{ id = "chi", name = "내공", icon = "🌀", desc = "내공 회복과 기술 위력" },
}

function Config.statMult(x: number): number
	return 1 + 0.25 * math.log(1 + math.max(0, x) / 20)
end

function Config.maxHp(vit: number): number
	return math.floor(100 * Config.statMult(vit))
end

function Config.walkSpeed(agi: number): number
	return Config.WALK_SPEED * (0.9 + 0.1 * Config.statMult(agi))
end

-- 경지: 능력치 합으로 정해진다. 머리 위 칭호와 작은 체력 보너스
Config.Realms = {
	{ name = "삼류", need = 0, color = Color3.fromRGB(200, 200, 200) },
	{ name = "이류", need = 100, color = Color3.fromRGB(150, 220, 150) },
	{ name = "일류", need = 400, color = Color3.fromRGB(110, 190, 255) },
	{ name = "절정", need = 1200, color = Color3.fromRGB(190, 130, 255) },
	{ name = "초절정", need = 3000, color = Color3.fromRGB(255, 190, 70) },
	{ name = "화경", need = 7000, color = Color3.fromRGB(255, 110, 80) },
	{ name = "현경", need = 15000, color = Color3.fromRGB(120, 255, 230) },
	{ name = "생사경", need = 30000, color = Color3.fromRGB(255, 255, 255) },
}

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
}
Config.TRAIN_COOLDOWN = 0.6 -- 한 번 수련하고 다음까지

------------------------------------------------------------------------
-- 권법 7종
-- 기술: pose = Poses 이름, dur = 길이(초), hits = 맞히는 순간들
--   hit = { t, range(앞으로 거리), radius, dmg, posture, stun, kb(밀어냄), up(띄움), aoe(나를 둘러싼 원) }
--   lunge = 시작할 때 앞으로 미끄러지는 거리, armor = 맞아도 안 밀림, iframes = 무적 시간
--   proj = 날아가는 장풍 { speed, life, radius, dmg, posture, stun, kb }
-- combo 4개는 클릭, heavy는 우클릭, skills.E·R·G (G = 오의, 내공 100)
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
		gimmick = "기류: 흘릴 때마다 1 (최대 3). 우클릭 반탄장이 기류만큼 강해진다",
		deflect = 0.32,
		stance = "stance_taeheo",
		combo = {
			{ id = "th1", name = "유수장", pose = "palm_r", dur = 0.36, lunge = 2, hits = { hit(0.14, 5, 3.5, 7, 8, 0.35, 6) } },
			{ id = "th2", name = "회수장", pose = "palm_l", dur = 0.36, lunge = 2, hits = { hit(0.14, 5, 3.5, 7, 8, 0.35, 6) } },
			{ id = "th3", name = "운수", pose = "circle_palm", dur = 0.42, lunge = 1, hits = { hit(0.2, 5, 4.5, 8, 10, 0.4, 8) } },
			{ id = "th4", name = "쌍장추", pose = "double_palm", dur = 0.55, lunge = 3, hits = { hit(0.24, 6, 4, 11, 16, 0.5, 30) } },
		},
		heavy = { id = "thH", name = "반탄장", pose = "push_palm", dur = 0.6, lunge = 2, hits = { hit(0.28, 6, 4.5, 14, 26, 0.6, 45) }, stackDmg = 0.6 },
		skills = {
			E = { id = "thE", name = "유수회선", desc = "0.8초 동안 받아넘기기 자세. 맞으면 저절로 흘리고 되받아친다", pose = "flow_stance", dur = 0.8, cd = 7, chi = 15, counter = 0.8,
				counterHit = { pose = "push_palm", hit = hit(0, 7, 5, 18, 30, 0.8, 40) } },
			R = { id = "thR", name = "선풍기류", desc = "주변을 끌어당기는 물의 소용돌이 (균형을 크게 깎는다)", pose = "whirl", dur = 0.9, cd = 11, chi = 25,
				hits = { hit(0.25, 0, 11, 5, 12, 0.4, -12, nil, true), hit(0.5, 0, 11, 5, 12, 0.4, -12, nil, true), hit(0.75, 0, 11, 8, 18, 0.6, 20, nil, true) } },
			G = { id = "thG", name = "만류귀종", desc = "모든 흐름이 하나로 돌아온다. 거대한 물의 용이 휘감는다", pose = "ult_raise", dur = 1.6, cd = 30, chi = 100, armor = true,
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
			{ id = "gg1", name = "금강권", pose = "punch_r_heavy", dur = 0.5, lunge = 2, hits = { hit(0.22, 5, 3.5, 11, 12, 0.45, 10) } },
			{ id = "gg2", name = "나한권", pose = "punch_l_heavy", dur = 0.5, lunge = 2, hits = { hit(0.22, 5, 3.5, 11, 12, 0.45, 10) } },
			{ id = "gg3", name = "복호권", pose = "hook_r", dur = 0.55, lunge = 1, hits = { hit(0.26, 5, 4.5, 13, 16, 0.5, 14) } },
			{ id = "gg4", name = "금강추", pose = "hammer_down", dur = 0.7, lunge = 2, hits = { hit(0.34, 5, 5, 18, 28, 0.7, 20, 10) } },
		},
		heavy = { id = "ggH", name = "대력금강장", pose = "push_palm", dur = 0.8, lunge = 2, hits = { hit(0.4, 6, 5, 20, 45, 0.8, 50) } },
		skills = {
			E = { id = "ggE", name = "철포삼", desc = "6초 동안 무엇에도 밀리지 않고 받는 피해 절반", pose = "brace", dur = 0.5, cd = 14, chi = 20, buff = { kind = "ironshirt", dur = 6 } },
			R = { id = "ggR", name = "사자후", desc = "사자의 포효. 주변의 적을 모두 기절시킨다", pose = "roar", dur = 0.8, cd = 12, chi = 30,
				hits = { hit(0.3, 0, 14, 6, 25, 1.4, 25, nil, true) } },
			G = { id = "ggG", name = "여래신장", desc = "하늘에서 거대한 금빛 손바닥이 내려찍는다", pose = "ult_slam", dur = 1.5, cd = 30, chi = 100, armor = true,
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
		gimmick = "꽃잎: 1.2초 안에 계속 맞히면 1씩 (최대 20). 20이면 다음 우클릭이 만개 폭발",
		deflect = 0.2,
		speed = 1.15,
		stance = "stance_maehwa",
		combo = {
			{ id = "mh1", name = "매화일지", pose = "jab_l", dur = 0.26, lunge = 2, hits = { hit(0.1, 5, 3.2, 5, 5, 0.3, 4) } },
			{ id = "mh2", name = "매화이지", pose = "jab_r", dur = 0.26, lunge = 2, hits = { hit(0.1, 5, 3.2, 5, 5, 0.3, 4) } },
			{ id = "mh3", name = "낙화권", pose = "spin_backfist", dur = 0.34, lunge = 2, hits = { hit(0.16, 5, 4, 6, 6, 0.35, 6) } },
			{ id = "mh4", name = "매화선퇴", pose = "roundhouse", dur = 0.42, lunge = 2, hits = { hit(0.2, 6, 4.5, 8, 10, 0.45, 22) } },
		},
		heavy = { id = "mhH", name = "매화일섬", pose = "dash_strike", dur = 0.5, lunge = 14, iframes = 0.2, hits = { hit(0.2, 7, 4, 12, 14, 0.5, 16) }, bloom = { radius = 12, dmg = 30, posture = 40 } },
		skills = {
			E = { id = "mhE", name = "낙화연격", desc = "눈에 보이지 않는 여덟 번의 연타", pose = "flurry", dur = 1.0, cd = 8, chi = 20, lunge = 2,
				hits = { hit(0.12, 5, 4, 3, 4, 0.3, 1), hit(0.22, 5, 4, 3, 4, 0.3, 1), hit(0.32, 5, 4, 3, 4, 0.3, 1), hit(0.42, 5, 4, 3, 4, 0.3, 1),
					hit(0.52, 5, 4, 3, 4, 0.3, 1), hit(0.62, 5, 4, 3, 4, 0.3, 1), hit(0.72, 5, 4, 3, 4, 0.3, 1), hit(0.85, 5, 4.5, 8, 12, 0.5, 25) } },
			R = { id = "mhR", name = "암향표", desc = "향기만 남기고 사라지는 걸음. 지나간 길의 적을 벤다 (무적)", pose = "dash_strike", dur = 0.45, cd = 9, chi = 20, lunge = 22, iframes = 0.4,
				hits = { hit(0.15, 4, 5, 9, 10, 0.4, 8) } },
			G = { id = "mhG", name = "매화만개", desc = "천 송이 매화가 한꺼번에 피어나는 꽃잎 폭풍", pose = "ult_spin", dur = 1.8, cd = 30, chi = 100, armor = true,
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
		desc = "하늘의 용이 하늘을 깨뜨리는 장풍. 우클릭을 누르고 있다 놓으면 모은 만큼 큰 장풍이 날아간다. 멀리서 견제하는 거리 싸움.",
		gimmick = "용기 모으기: 우클릭을 길게 누를수록 장풍이 커진다 (최대 1.5초)",
		deflect = 0.2,
		charge = 1.5,
		stance = "stance_cheonryong",
		combo = {
			{ id = "cr1", name = "용조장", pose = "palm_r", dur = 0.34, lunge = 2, hits = { hit(0.14, 5, 3.5, 6, 6, 0.3, 6) } },
			{ id = "cr2", name = "용미장", pose = "palm_l", dur = 0.34, lunge = 2, hits = { hit(0.14, 5, 3.5, 6, 6, 0.3, 6) } },
			{ id = "cr3", name = "잠룡장", pose = "low_palm", dur = 0.4, lunge = 1, hits = { hit(0.18, 5, 4, 7, 8, 0.35, 8) } },
			{ id = "cr4", name = "현룡파", pose = "double_palm", dur = 0.5, lunge = 1, proj = { speed = 90, life = 0.35, radius = 4, dmg = 10, posture = 14, stun = 0.5, kb = 28, size = 3 }, hits = {} },
		},
		heavy = { id = "crH", name = "항룡장", pose = "double_palm", dur = 0.55, lunge = 0, proj = { speed = 110, life = 0.6, radius = 4, dmg = 12, posture = 16, stun = 0.5, kb = 30, size = 3 }, hits = {}, chargeMult = 2.2 },
		skills = {
			E = { id = "crE", name = "항룡유회", desc = "꿰뚫고 나아가는 용의 기운 (맞은 적 모두)", pose = "double_palm", dur = 0.6, cd = 7, chi = 20,
				proj = { speed = 80, life = 0.7, radius = 6, dmg = 16, posture = 20, stun = 0.6, kb = 35, size = 6, pierce = true }, hits = {} },
			R = { id = "crR", name = "비룡승천", desc = "용처럼 솟구치며 올려 친다 (적을 띄움)", pose = "uppercut", dur = 0.7, cd = 9, chi = 20, lunge = 3, jump = 40,
				hits = { hit(0.2, 5, 5, 14, 18, 0.9, 6, 55) } },
			G = { id = "crG", name = "구룡승천", desc = "아홉 마리 용이 땅을 뚫고 하늘로 솟는다", pose = "ult_raise", dur = 1.7, cd = 30, chi = 100, armor = true,
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
			{ id = "my1", name = "귀각", pose = "front_kick", dur = 0.34, lunge = 2, hits = { hit(0.14, 6, 3.5, 6, 6, 0.3, 6) } },
			{ id = "my2", name = "선풍각", pose = "roundhouse", dur = 0.38, lunge = 2, hits = { hit(0.17, 6, 4.5, 7, 7, 0.35, 8) } },
			{ id = "my3", name = "후려차기", pose = "back_spin_kick", dur = 0.44, lunge = 2, hits = { hit(0.24, 6, 4.5, 8, 9, 0.4, 10) } },
			{ id = "my4", name = "낙영각", pose = "axe_kick", dur = 0.5, lunge = 2, hits = { hit(0.28, 6, 4, 11, 16, 0.5, 6, 20) } },
		},
		heavy = { id = "myH", name = "귀영낙각", pose = "flying_kick", dur = 0.55, lunge = 12, hits = { hit(0.25, 6, 4.5, 14, 18, 0.6, 30) } },
		skills = {
			E = { id = "myE", name = "그림자 걸음", desc = "가장 가까운 적의 등 뒤로 순간이동해 찬다 (치명타)", pose = "back_spin_kick", dur = 0.5, cd = 7, chi = 15, teleport = 26,
				hits = { hit(0.2, 6, 4.5, 12, 14, 0.6, 20) } },
			R = { id = "myR", name = "귀영난각", desc = "공중으로 솟아 회오리처럼 여섯 번 찬다", pose = "air_spin", dur = 0.9, cd = 10, chi = 25, jump = 38,
				hits = { hit(0.2, 4, 7, 5, 6, 0.4, 2, 10, true), hit(0.32, 4, 7, 5, 6, 0.4, 2, 10, true), hit(0.44, 4, 7, 5, 6, 0.4, 2, 10, true),
					hit(0.56, 4, 7, 5, 6, 0.4, 2, 10, true), hit(0.68, 4, 7, 5, 6, 0.4, 2, 10, true), hit(0.8, 4, 7.5, 10, 14, 0.6, 30, nil, true) } },
			G = { id = "myG", name = "무영천각", desc = "모습을 감추고 여섯 그림자가 사방에서 찬다", pose = "ult_spin", dur = 1.8, cd = 30, chi = 100, iframes = 1.6,
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
			{ id = "bk1", name = "섬전권", pose = "jab_l", dur = 0.3, lunge = 3, hits = { hit(0.12, 5, 3.5, 7, 7, 0.35, 6) } },
			{ id = "bk2", name = "뇌정권", pose = "punch_r", dur = 0.32, lunge = 3, hits = { hit(0.13, 5, 3.5, 7, 7, 0.35, 6) } },
			{ id = "bk3", name = "뇌명각", pose = "front_kick", dur = 0.38, lunge = 2, hits = { hit(0.17, 6, 4, 8, 8, 0.4, 10) } },
			{ id = "bk4", name = "벽력추", pose = "punch_r_heavy", dur = 0.5, lunge = 4, hits = { hit(0.22, 6, 4, 12, 15, 0.55, 30) } },
		},
		heavy = { id = "bkH", name = "벽력일권", pose = "dash_punch", dur = 0.55, lunge = 18, hits = { hit(0.22, 6, 4.5, 15, 20, 0.6, 35) } },
		skills = {
			E = { id = "bkE", name = "뇌전보", desc = "번개처럼 지그재그로 꺾어 달린다 (무적, 지나간 적 마비)", pose = "dash_strike", dur = 0.5, cd = 7, chi = 15, lunge = 20, iframes = 0.45,
				hits = { hit(0.15, 4, 5, 6, 8, 0.8, 4) } },
			R = { id = "bkR", name = "뇌격", desc = "하늘에서 주변 적에게 벼락을 내리꽂는다", pose = "point_sky", dur = 0.8, cd = 11, chi = 25,
				hits = { hit(0.45, 0, 18, 16, 20, 1.0, 10, nil, true) }, strike = true },
			G = { id = "bkG", name = "천뢰멸", desc = "하늘이 갈라지며 벼락 폭풍이 쏟아진다", pose = "ult_raise", dur = 1.8, cd = 30, chi = 100, armor = true, strike = true,
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
			R = { id = "cwR", name = "팔선과해", desc = "여덟 신선이 바다를 건너듯 빙글빙글 돌며 친다", pose = "ult_spin", dur = 1.0, cd = 10, chi = 25,
				hits = { hit(0.2, 0, 8, 5, 6, 0.35, 3, nil, true), hit(0.4, 0, 8, 5, 6, 0.35, 3, nil, true), hit(0.6, 0, 8, 5, 6, 0.35, 3, nil, true), hit(0.85, 0, 9, 10, 14, 0.6, 30, nil, true) } },
			G = { id = "cwG", name = "취화난무", desc = "취기가 불길이 되어 뿜어져 나온다", pose = "fire_breath", dur = 1.8, cd = 30, chi = 100, armor = true,
				hits = { hit(0.4, 12, 7, 8, 10, 0.4, 6), hit(0.7, 12, 7, 8, 10, 0.4, 6), hit(1.0, 12, 7, 8, 10, 0.4, 6), hit(1.3, 12, 7, 8, 10, 0.4, 6), hit(1.6, 13, 8, 22, 35, 1.0, 45) } },
		},
	},
}
Config.STYLE_BY_ID = {}
for i, s in ipairs(Config.Styles) do
	s.index = i
	Config.STYLE_BY_ID[s.id] = s
end

-- 권법 배우는 값 (이미 배운 권법 수에 따라). 첫 권법은 공짜
Config.LEARN_COST = { 0, 200, 500, 1000, 2000, 3500, 5000 }

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
}
Config.ACTION_WINDOW = { D = 0.6, C = 0.8 } -- 대시·흘리기 뒤 이만큼 안에 눌러야 나간다
-- 권법마다 몸놀림 자세만 다르게
local ACTION_POSE = {
	maehwa = { D = "dash_strike", C = "spin_backfist" },
	muyeong = { D = "flying_kick", A = "dive_kick", C = "back_spin_kick" },
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
			{ enemy = "spearman", count = 2, at = Vector3.new(-430, 0, 470) }, { enemy = "brute", count = 2, at = Vector3.new(-380, 0, -430) },
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
	-- 일곱 사부의 자리 (안전 지대). master = 그 권법, masterAt = 사부가 서 있는 곳
	{ id = "lake", name = "태허호 (호수 정자)", center = Vector3.new(-650, 0, 650), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(110, 150, 110), material = Enum.Material.Grass, safe = true,
		master = "taeheo", masterName = "수월진인 (水月眞人)", masterAt = Vector3.new(-650, 1.6, 650) },
	{ id = "temple", name = "금강사", center = Vector3.new(650, 0, -650), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(150, 140, 120), material = Enum.Material.Cobblestone, safe = true,
		master = "geumgang", masterName = "혜공대사 (慧空大師)", masterAt = Vector3.new(650, 6, -680) },
	{ id = "plum", name = "매화원", center = Vector3.new(-650, 0, -650), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(140, 150, 105), material = Enum.Material.Grass, safe = true,
		master = "maehwa", masterName = "매향선자 (梅香仙子)", masterAt = Vector3.new(-650, 0, -660) },
	{ id = "peak", name = "천룡봉", center = Vector3.new(1000, 0, -280), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(120, 115, 105), material = Enum.Material.Slate, safe = true,
		master = "cheonryong", masterName = "용천노조 (龍天老祖)", masterAt = Vector3.new(1030, 14, -280) },
	{ id = "ravine", name = "무영곡", center = Vector3.new(-1000, 0, 0), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(60, 58, 70), material = Enum.Material.Slate, safe = true,
		master = "muyeong", masterName = "무영객 (無影客)", masterAt = Vector3.new(-1060, 3, 0) },
	{ id = "plateau", name = "뇌운 고원", center = Vector3.new(650, 0, 650), size = Vector3.new(300, 0, 300), ground = Color3.fromRGB(125, 125, 135), material = Enum.Material.Granite, safe = true,
		master = "byeokryeok", masterName = "뇌정진군 (雷霆眞君)", masterAt = Vector3.new(650, 2, 650) },
	{ id = "tavern", name = "취선 주막", center = Vector3.new(0, 0, 700), size = Vector3.new(260, 0, 220), ground = Color3.fromRGB(150, 130, 95), material = Enum.Material.Ground, safe = true,
		master = "chwi", masterName = "취선옹 (醉仙翁)", masterAt = Vector3.new(0, 0, 690) },
}
-- 권법 id → 사부 { name, at, region }
Config.MASTERS = {}
for _, r in ipairs(Config.Regions) do
	if r.master then
		Config.MASTERS[r.master] = { name = r.masterName, at = r.masterAt, region = r.name, regionId = r.id }
	end
end
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
Config.WORLD_HALF = 1300 -- 세상 끝 (가운데에서)
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
}

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
