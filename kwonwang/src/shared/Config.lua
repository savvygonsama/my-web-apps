-- 권왕(拳王): 맨손의 강호. 서버와 화면이 함께 쓰는 설정
local Config = {}

Config.GAME_TITLE = "권왕"
Config.VERSION = "3.11.1" -- 화면 오른쪽 아래 구석에 작게 보인다 (게시한 판이 맞는지 확인용)
-- 스튜디오와 게임 주인은 테스트 계정 (기록 저장 안 함, 테스트 창).
-- 공개판(public.project.json)으로 만들면 ReplicatedStorage.KwonBuild가 들어가 테스트가 모두 꺼진다
local buildMod = script.Parent and script.Parent:FindFirstChild("KwonBuild")
local okBuild, build = pcall(function()
	return buildMod and require(buildMod :: any) or nil
end)
Config.PUBLIC = okBuild and type(build) == "table" and build.public == true
Config.TEST_MODE = not Config.PUBLIC
-- 3.3판: 배틀그라운드 (따로 게시하는 PvP 세계). battleground.project.json으로 만들면 ReplicatedStorage.KwonBattle이 들어간다
local battleMod = script.Parent and script.Parent:FindFirstChild("KwonBattle")
Config.BATTLE_MODE = battleMod ~= nil

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
Config.REGEN_DELAY = 6 -- 마지막으로 맞은 뒤 이만큼 지나야 체력이 차오른다
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

-- 2.0판: 능력치 숫자를 줄였다 (천외천 5억 → 50만). 세기는 그대로 두려고, 효과는 예전 숫자로 되돌려 셈한다 (Config.statEquiv)
function Config.statMult(x: number): number
	return 1 + 0.3 * math.log(1 + Config.statEquiv(math.max(0, x)) / 15)
end

function Config.maxHp(vit: number): number
	return math.floor(100 * Config.statMult(vit))
end

-- 내공 그릇: 내공 능력치와 경지가 오를수록 커진다 (100 → 최대 500). 오의는 늘 100을 쓴다
function Config.chiMax(chi: number, realm: number): number
	return math.min(500, 100 + math.floor(40 * math.log(1 + Config.statEquiv(math.max(0, chi)) / 60)) + 8 * (realm - 1))
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
	{ name = "절정", need = 5000, color = Color3.fromRGB(190, 130, 255) },
	{ name = "초절정", need = 10000, color = Color3.fromRGB(255, 190, 70) },
	{ name = "화경", need = 20000, color = Color3.fromRGB(255, 110, 80) },
	{ name = "현경", need = 36000, color = Color3.fromRGB(120, 255, 230) },
	{ name = "사경", need = 60000, color = Color3.fromRGB(255, 80, 120) },
	-- 2.2판: 문턱은 다시 예전 (1.9판) 숫자 그대로. 대신 적이 주는 능력치를 줄였다
	{ name = "생사경", need = 218000, color = Color3.fromRGB(255, 255, 255) },
	{ name = "신화경", need = 791000, color = Color3.fromRGB(255, 220, 120) },
	{ name = "천인합일", need = 2874000, color = Color3.fromRGB(160, 220, 255) },
	{ name = "무극", need = 10438000, color = Color3.fromRGB(255, 150, 255) },
	-- 무극 너머 (허공 균열의 적과 천마를 상대하려면)
	{ name = "반선", need = 37908000, color = Color3.fromRGB(200, 255, 255) },
	{ name = "등선", need = 137674000, color = Color3.fromRGB(255, 240, 200) },
	{ name = "천외천", need = 500000000, color = Color3.fromRGB(255, 255, 160) },
	-- 1.9판: 천외천 너머. 환생해야 하나씩 열린다 (환생 한 번에 한 경지)
	{ name = "혼원경", need = 2500000000, color = Color3.fromRGB(255, 120, 200), rebirth = 1 },
	{ name = "무량경", need = 12500000000, color = Color3.fromRGB(130, 255, 170), rebirth = 2 },
	{ name = "태허경", need = 62500000000, color = Color3.fromRGB(150, 170, 255), rebirth = 3 },
	{ name = "권왕", need = 312500000000, color = Color3.fromRGB(255, 70, 70), rebirth = 4 },
}
-- 예전 (1.9판까지) 문턱. 능력치의 효과는 이 숫자로 되돌려 셈한다 (경지마다 세기가 예전과 같게)
local OLD_NEED = { 0, 150, 600, 2000, 5000, 10000, 20000, 36000, 60000, 218000, 791000, 2874000, 10438000, 37908000, 137674000, 500000000, 2500000000, 12500000000, 62500000000, 312500000000 }
-- 2.0판의 문턱 (2.0판 기록을 2.1판 숫자로 옮길 때 쓴다)
local V2_NEED = { 0, 150, 600, 2000, 5000, 10000, 20000, 36000, 60000, 90000, 130000, 180000, 240000, 310000, 400000, 500000, 650000, 850000, 1100000, 1500000 }
-- 능력치 합 total(문턱표 N의 숫자)을 예전 숫자로 (문턱 사이는 로그로 잇는다)
local function toOldBy(N: { number }, total: number): number
	if total <= N[9] then
		return total -- 사경까지는 그대로
	end
	for i = 9, #N - 1 do
		local a, b = N[i], N[i + 1]
		if total <= b then
			local t = (total - a) / (b - a)
			return math.exp(math.log(OLD_NEED[i]) + (math.log(OLD_NEED[i + 1]) - math.log(OLD_NEED[i])) * t)
		end
	end
	-- 권왕 너머: 마지막 마디의 기울기로 늘린다
	local n = #N
	local slope = (math.log(OLD_NEED[n]) - math.log(OLD_NEED[n - 1])) / (N[n] - N[n - 1])
	return math.exp(math.log(OLD_NEED[n]) + slope * (total - N[n]))
end
-- 2.1판의 문턱
local V21_NEED = { 0, 150, 600, 2000, 5000, 10000, 20000, 36000, 60000, 170000, 500000, 1450000, 4200000, 12000000, 35000000, 100000000, 180000000, 320000000, 560000000, 1000000000 }
-- 2.2판: 문턱이 예전 숫자로 돌아와 능력치 숫자가 곧 그 효과다
function Config.statEquiv(x: number): number
	return x
end
-- 2.0판 (ver 2) · 2.1판 (ver 3) 기록의 능력치 하나를 지금 (예전과 같은) 숫자로 (세기는 그대로)
function Config.statFromVer(ver: number, x: number): number
	local N = ver == 2 and V2_NEED or V21_NEED
	return math.floor(toOldBy(N, math.max(0, x) * 4) / 4 + 0.5)
end
-- 경지 배율은 겹으로 쌓인다: 사경까지 경지마다 ×1.22, 그 위로는 ×1.38씩 (후반일수록 크게 뛴다)
-- (일류 ×1.5, 절정 ×2.2, 사경 ×4.9, 무극 ×18.6, 천외천 ×46)
function Config.realmPower(idx: number): number
	return 1.22 ^ (math.min(idx, 9) - 1) * 1.38 ^ math.max(0, idx - 9)
end
-- 2.4.1판: 주는 피해의 경지 배율. 천외천까지는 위와 같고, 환생으로 열린 경지는 피해가 경지마다 ×1.08만 (체력은 그대로 ×1.38씩)
-- 2.8판: 체력의 경지 배율은 피해보다 완만하게 (경지 배율의 0.75제곱). 후반에 적이 스무 대를 때려야 쓰러질 만큼 단단했다
function Config.realmHp(idx: number): number
	return Config.realmPower(idx) ^ 0.75
end
function Config.realmDmg(idx: number): number
	return Config.realmPower(math.min(idx, 16)) * 1.1 ^ math.max(0, idx - 16)
end
-- 1.8판: 후반 경지의 공격력 (피해에만 곱한다). 능력치가 로그로 자라 후반에 주먹이 너무 가벼웠다
-- 생사경 ×1.5 · 신화경 ×2.2 · 천인합일 ×3 · 무극 ×4 · 반선 ×5.5 · 등선 ×7 · 천외천 ×9
-- (1.9판: 혼원경 ×11 · 무량경 ×13.5 · 태허경 ×16.5 · 권왕 ×20)
-- 2.4.1판: 후반 공격력 배율을 아주 작게 (공격력 자체가 너무 세서 다 한 방이었다). 2.5판: 아주 조금 올렸다 (약 +10%)
-- 생사경 ×1.2 · 무극 ×1.6 · 천외천 ×2.2, 그 너머는 더 오르지 않는다
Config.LATE_ATK = { [10] = 1.2, [11] = 1.3, [12] = 1.45, [13] = 1.6, [14] = 1.75, [15] = 1.95, [16] = 2.2, [17] = 2.2, [18] = 2.2, [19] = 2.2, [20] = 2.2 }
function Config.lateAtk(idx: number): number
	return Config.LATE_ATK[idx] or (idx > 20 and 2.2 or 1)
end

-- cap: 오를 수 있는 가장 높은 경지 (환생으로 열린 만큼). 없으면 끝까지
function Config.realmOf(total: number, cap: number?): (number, any)
	local idx = 1
	for i, r in ipairs(Config.Realms) do
		if total >= r.need and i <= (cap or #Config.Realms) then
			idx = i
		end
	end
	return idx, Config.Realms[idx]
end

------------------------------------------------------------------------
-- 1.9판: 환생. 열린 가장 높은 경지(처음엔 천외천)에 오르면 환생할 수 있다
-- 능력치를 모두 내려놓고 삼류로 돌아간다. 권법·숙련·깨달음·심법·탈것·은자·관문 기록은 그대로 남는다
-- 환생할 때마다: 체력 영구 +25% · 주는 피해 +10% (2.4.1판), 적을 쓰러뜨려 얻는 능력치·수련 배수 +1 (2.1판), 천외천 너머의 경지가 하나 열린다
------------------------------------------------------------------------
Config.REBIRTH = {
	max = 4,
	base = 16, -- 환생 전 끝 경지 (천외천)
	power = 0.25,
	gain = 1, -- 2.1판: 환생 한 번마다 얻는 능력치 배수 +1 (×2 · ×3 · ×4 · ×5)
	coins = 1000000, -- 환생할 때 받는 은자 (횟수만큼)
	names = { "일환", "이환", "삼환", "사환" },
	colors = { Color3.fromRGB(255, 120, 200), Color3.fromRGB(130, 255, 170), Color3.fromRGB(150, 170, 255), Color3.fromRGB(255, 70, 70) },
}
function Config.realmCap(rebirth: number): number
	return math.min(#Config.Realms, Config.REBIRTH.base + math.clamp(rebirth, 0, Config.REBIRTH.max))
end
-- 환생 배율: 피해·체력 (겹치지 않고 더한다)
function Config.rebirthPower(rebirth: number): number
	return 1 + Config.REBIRTH.power * rebirth
end
-- 2.4.1판: 환생의 피해 배율은 작게 (한 번에 +10%). 체력은 rebirthPower (+25%)
function Config.rebirthDmg(rebirth: number): number
	return 1 + 0.1 * rebirth
end
function Config.rebirthGain(rebirth: number): number
	return 1 + Config.REBIRTH.gain * rebirth
end

------------------------------------------------------------------------
-- 2.9판: 환생 공덕과 윤회의 시련
-- 환생 한 번에 공덕 둘, 윤회의 시련 하나를 넘을 때마다 공덕 하나 (모두 열둘). 공덕으로 특전을 한 단계씩 산다 (특전마다 세 단계)
-- 특전은 모두 합쳐 스물한 단계라 다 살 수는 없다. 되돌리기는 은자 없이 언제든 (싸우는 중만 빼고)
------------------------------------------------------------------------
Config.PERKS = {
	{ id = "hp", icon = "🛡", name = "금강불괴", desc = "체력", per = 0.08 },
	{ id = "dmg", icon = "👊", name = "파천력", desc = "주는 피해", per = 0.06 },
	{ id = "gain", icon = "🌀", name = "흡성", desc = "얻는 능력치 (처치·수련 모두)", per = 0.1 },
	{ id = "train", icon = "🧘", name = "심공", desc = "수련으로 얻는 능력치 (흡성에 더해)", per = 0.2 },
	{ id = "coin", icon = "💰", name = "재물운", desc = "적이 떨구는 은자", per = 0.15 },
	{ id = "mastery", icon = "📈", name = "오성", desc = "권법 숙련", per = 0.2 },
	{ id = "spd", icon = "💨", name = "질풍", desc = "걷는 빠르기", per = 0.04 },
}
Config.PERK_BY_ID = {}
for _, pk in ipairs(Config.PERKS) do
	Config.PERK_BY_ID[pk.id] = pk
end
Config.PERK_MAX = 3
Config.PERK_PER_REBIRTH = 2
function Config.perkPoints(rebirth: number, samsara: number): number
	return rebirth * Config.PERK_PER_REBIRTH + samsara
end
function Config.perkMult(perks: { [string]: number }?, id: string): number
	local pk = Config.PERK_BY_ID[id]
	return 1 + (pk and pk.per or 0) * ((perks and perks[id]) or 0)
end

-- 윤회의 시련: n번째 환생 뒤 생사경에 다시 오르면 n번째 시련이 열린다. 전생의 그림자는 지금 내 힘보다 조금 세다
Config.SAMSARA = {
	realm = 10, -- 생사경
	power = { 1.15, 1.25, 1.35, 1.5 },
	hp = { 4, 5, 6, 8 },
	time = 180,
	cooldown = 20,
	gems = { 80, 150, 250, 400 },
	scrolls = { 5, 8, 12, 20 },
	coins = { 2000000, 5000000, 12000000, 30000000 },
	lines = {
		"삼류에서 다시 시작한 너를 비웃는 것은 다름 아닌 지난 삶의 너다. 그 그림자를 넘어라.",
		"두 번 살았으면 두 번 졌던 기억도 있다. 그 기억이 형체를 얻었다.",
		"세 번째 삶의 그림자는 네 버릇을 모두 안다. 버릇을 버려라.",
		"마지막 그림자. 이것을 넘으면 윤회의 바퀴가 너를 놓아준다. 권왕의 자리가 보인다.",
	},
}

------------------------------------------------------------------------
-- 2.0판: 적을 쓰러뜨리면 능력치가 오른다. 얻는 양은 그 적의 전투력만으로 정해진다 (내 경지·필요 마릿수와 상관없다)
-- 그 경지 적이면 앞 경지는 열다섯 마리 남짓, 천외천은 백육십 마리 남짓에 다음 경지 (보스 ×3, 정예 ×1.5)
------------------------------------------------------------------------
-- overCap (2.7.4판): 나보다 센 적을 쓰러뜨려도 능력치는 내 전투력과 같은 적의 이 배수까지만 (보스·정예 배수는 그 위에 곱한다)
Config.KILL_GAIN = { boss = 3, elite = 1.5, tower = 0.5, overCap = 1.5 } -- 3.2.2판: overCap 2 → 1.5, 잣대는 내 경지의 기준 적 (shareGain)
Config.LATE_BOSS_KILLS = 15 -- 2.7.2판: 후반 보스 하나의 능력치 몫은 그 땅 졸병 열다섯 마리까지 (전엔 표 끝에 걸려 모두 6억 3천만)
-- { 적 전투력, 얻는 능력치 합 } (사이는 로그로 잇는다)
-- 2.2판: 문턱은 예전 숫자, 적이 주는 양은 2.0판 비율의 2/3 (경지 하나에 처치 수 1.5배: 앞 경지 스무 마리 남짓 · 천외천 이백오십 마리 남짓)
-- 환생으로 열리는 경지의 적은 그 환생 배수만큼 덜 준다 (환생 배수는 다시 오르는 앞 경지를 빠르게 하는 몫)
-- 3.2.6판: 초반 적이 너무 적게 줬다 (특급~현경은 경지 하나에 그 경지 적 80~130마리). 삼류~사경을 올려
-- 삼류 10 · 이류 15 · 일류 16 · 특급 25 · 절정 26 · 초절정 31 · 화경 36 · 현경 39 · 사경 88마리 남짓. 생사경부터는 그대로
local GAIN_TABLE: { { number } } = {
	{ 100, 15 }, { 168, 30 }, { 256, 55 }, { 374, 140 }, { 516, 190 }, { 686, 320 }, { 905, 450 }, { 1174, 620 }, { 1508, 1800 }, { 2343, 3600 },
	{ 3595, 12000 }, { 5460, 40000 }, { 8223, 130000 }, { 12298, 470000 }, { 18283, 1600000 }, { 27041, 8000000 }, { 40433, 19000000 }, { 60098, 63000000 }, { 88871, 210000000 }, { 130833, 210000000 },
}
-- 그 경지 적의 전투력 (경지 번호로 위 표를 읽는다)
function Config.realmRefPower(idx: number): number
	return GAIN_TABLE[math.clamp(idx, 1, #GAIN_TABLE)][1]
end
function Config.killGain(power: number): number
	local p = math.max(1, power)
	local first, last = GAIN_TABLE[1], GAIN_TABLE[#GAIN_TABLE]
	if p <= first[1] then
		return math.max(1, first[2] * p / first[1])
	end
	if p >= last[1] then
		return last[2]
	end
	for i = 1, #GAIN_TABLE - 1 do
		local a, b = GAIN_TABLE[i], GAIN_TABLE[i + 1]
		if p <= b[1] then
			local t = math.log(p / a[1]) / math.log(b[1] / a[1])
			return math.exp(math.log(a[2]) + (math.log(b[2]) - math.log(a[2])) * t)
		end
	end
	return last[2]
end

------------------------------------------------------------------------
-- 수련 4종 (월드 곳곳). 화면의 박자 맞추기: 완벽 2배, 좋음 1배, 놓침 0
------------------------------------------------------------------------
Config.Training = {
	-- 3.3판: 수련마다 한 번에 오르는 양이 1~24로 들쭉날쭉했다. 이제 단계마다 거의 같다 (삼류 넷 · 일류·특급 다섯 · 상급 여섯 · 천상 여섯),
	-- 박자가 빠른 수련은 그만큼 조금 덜 (1분에 오르는 양이 고르게). 새 수련은 능력치 섞임이 다를 뿐 크게 앞서지 않는다
	rock = { name = "바위 들기", stat = "str", gains = { str = 3, vit = 1 }, icon = "🪨", desc = "고리가 줄어들 때 맞춰 누르세요. 근골과 체력이 오른다", base = 1 },
	waterfall = { name = "폭포 명상", stat = "chi", gains = { chi = 3, vit = 1 }, icon = "💧", desc = "숨이 가장 커질 때 누르세요. 내공과 체력이 오른다", base = 1 },
	-- 목인장: 나무팔을 흘리며 몸과 발놀림을 함께 단련한다 (경공 수련은 없앴다)
	dummy = { name = "목인장", stat = "vit", gains = { vit = 2, agi = 2 }, icon = "🪵", desc = "나무팔이 들어오는 순간 흘리세요 (F). 체력과 경공이 함께 오른다", base = 1 },
	-- 경지마다 열리는 수련 (gains = 한 번에 오르는 능력치들, realm = 이 경지부터)
	mabo = { name = "마보 참장", stat = "vit", gains = { vit = 2, str = 1, agi = 1 }, icon = "🧱", desc = "말뚝 위에서 버티세요. 누를 때마다 몸이 오른쪽으로, 가만두면 왼쪽으로 기운다", base = 1, realm = 1 },
	ironpalm = { name = "철사장 수련", stat = "str", gains = { str = 3, vit = 1 }, icon = "🔥", desc = "달군 쇠모래가 튀어 오를 때 내리치세요 (빠르다)", base = 1, realm = 3, period = 1.25 },
	breathing = { name = "운기조식", stat = "chi", gains = { chi = 3, vit = 2 }, icon = "🌀", desc = "기가 몸을 한 바퀴 돌아 가득 찰 때 누르세요", base = 1, realm = 4 },
	simma = { name = "심마 대련", stat = "str", icon = "👁", desc = "마음속의 마귀가 형체를 얻는다. 이기면 모든 능력치가 크게 오른다", base = 1, realm = 9, fight = true, reward = 60 },
	-- 상급 수련 (상급 수련장, 천궁): 판정은 앞의 수련과 같고 (ui = 같은 화면), 한 번에 오르는 양이 크다. 조금 더 빠르다
	geumjong = { name = "금종조 수련", stat = "vit", gains = { vit = 4, str = 1, agi = 1 }, icon = "🔔", desc = "큰 종 아래에서 버티세요 (마보 참장처럼 가운데에 붙잡기)", base = 1, realm = 6, ui = "mabo", advanced = true },
	cheongeun = { name = "천근추 수련", stat = "str", gains = { str = 4, vit = 1 }, icon = "🏋", desc = "천 근 쇳덩이를 고리가 가장 작을 때 들어 올리세요", base = 1, realm = 7, ui = "rock", period = 1.3, advanced = true },
	jucheon = { name = "주천 운기", stat = "chi", gains = { chi = 3, vit = 1, agi = 1 }, icon = "☯", desc = "기가 온몸을 크게 한 바퀴 돌아 가득 찰 때 누르세요", base = 1, realm = 8, ui = "breathing", period = 1.35, advanced = true },
	heogong = { name = "허공답보", stat = "agi", gains = { agi = 3, str = 1 }, icon = "🦶", desc = "떠 있는 디딤돌이 번쩍이는 순간 밟으세요 (빠르다)", base = 1, realm = 9, ui = "ironpalm", period = 1.15, advanced = true },
	cheonsang = { name = "천상 수련", stat = "str", gains = { str = 2, vit = 2, agi = 1, chi = 1 }, icon = "🌤", desc = "천궁의 구름 연꽃 위에서 숨을 고르세요 (모든 능력치)", base = 1, realm = 12, ui = "breathing", period = 1.3, advanced = true },
}
Config.TRAIN_COOLDOWN = 0.6 -- 한 번 수련하고 다음까지
-- 수련으로 오르는 양 (판정은 그대로, 오르는 양만 줄였다): 기본 배율, 경지마다 더해지는 수련 효과
Config.TRAIN_GAIN = 0.6 -- 1.5판: 강해지는 길의 중심은 싸움 (적을 쓰러뜨려 능력치를 얻는다). 수련은 처음에 거드는 정도
Config.TRAIN_REALM_BONUS = 0.12
-- 2.7.5판: 후반 수련. 수련 효과가 경지마다 +12%씩만 늘어 후반엔 한 번에 수십밖에 오르지 않았다 (적 한 마리는 수백만).
-- 이제 그 경지 적 한 마리 몫에 견준다: 상급 수련(천상 수련)을 '완벽'으로 한 번 하면 그 경지 적 한 마리의 TRAIN_LATE_SHARE만큼.
-- 생사경 무렵부터 이쪽이 커진다 (그 앞은 예전 그대로). 싸움보다 훨씬 느리지만 오르는 게 눈에 보이게
Config.TRAIN_LATE_SHARE = 1 / 100 -- 2.7.7판: 1/50 → 1/150. 2.8판: 1/100 (싸움의 약 1/7 빠르기: 수련은 덤이되, 하는 만큼 보이게)
Config.TRAIN_LATE_REF = 12 -- 천상 수련 '완벽' 한 번에 오르는 몫의 합 (2 × 6). 3.3판: 천상 수련이 24 → 6이 되어 48 → 12 (후반 수련 몫은 그대로)
function Config.trainMult(idx: number): number
	local lin = Config.TRAIN_GAIN * (1 + Config.TRAIN_REALM_BONUS * (idx - 1))
	local late = Config.killGain(Config.realmRefPower(idx)) * Config.TRAIN_LATE_SHARE / Config.TRAIN_LATE_REF
	return math.max(lin, late)
end
-- 경지의 관문: 특급부터는 능력치가 닿아도 그 경지의 관문 수호자를 꺾어야 오른다
-- 3.2.5판: 관문을 껐다 (enabled = false). 능력치가 닿으면 경지가 바로 오른다. 다시 켜려면 true
Config.GATE = { enabled = false, from = 4, hp = 3, hpPerRealm = 0.3, power = 1.05, time = 180, cooldown = 20, easeHp = 0.08, easeDmg = 0.25, easeRealms = 6 }
-- 3.2.4판: 초반 관문은 순하게. 3.2.5판: 훨씬 순하게. 특급 관문은 체력 ×0.08 · 피해 ×0.25에서 시작해
-- 여섯 경지(생사경)에 걸쳐 원래 세기로 돌아온다. 처음 몇 경지는 천천히, 생사경에 가까울수록 빨리 오른다
function Config.gateEase(nxt: number): (number, number)
	local G = Config.GATE
	local a = math.clamp((nxt - G.from) / G.easeRealms, 0, 1) ^ 2
	return G.easeHp + (1 - G.easeHp) * a, G.easeDmg + (1 - G.easeDmg) * a
end
-- 강화 수련: 박자가 빠르고 판정이 좁지만 얻는 능력치가 세 배. 경지 이류부터
Config.HARD_TRAIN = { mult = 2, realm = 2, period = 1.05, perfect = 0.065, good = 0.14 }
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
			R = { id = "myR", name = "귀영난각", desc = "공중으로 솟아 회오리처럼 여섯 번 찬다", pose = "tornado_kick", dur = 1.0, cd = 10, chi = 25, jump = 38,
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
		chargeEvery = 5,
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
		-- 2.6판: 무극신권의 기술 셋을 흑백 음양으로 새로
		E = { id = "mgE", name = "음양탄", desc = "두 손을 맞댔다가 밀어낸다. 검은 구슬과 흰 구슬이 서로 감아 돌며 앞으로 날아가 길의 적을 치고, 끝에서 부딪쳐 둘레의 적을 빨아들이며 터진다", pose = "void_point", dur = 0.55, cd = 6, chi = 15,
			mech = { kind = "yinyangShot", delay = 0.15, length = 30, travel = 0.45, width = 4, radius = 8, pull = 30, hit = hit(0, 0, 0, 12, 22, 0.4, 10), burst = hit(0, 0, 0, 16, 30, 0.6, 0) } },
		R = { id = "mgR", name = "태극선회", desc = "제자리에서 원을 그린다. 검은 구슬과 흰 구슬이 나를 축으로 소용돌이치며 16칸까지 퍼졌다가 되돌아오고, 돌아올 때 둘레의 적을 내 앞으로 끌어 모아 한 번 더 친다", pose = "void_circle", dur = 0.9, cd = 9, chi = 25,
			mech = { kind = "taijiOrbit", delay = 0.1, radius = 16, dur = 1.1, every = 0.1, turns = 1.5, orbRadius = 4.5, pull = 36, hit = hit(0, 0, 0, 8, 14, 0.3, 0), final = hit(0, 0, 0, 16, 36, 0.6, 0) } },
		G = { id = "mgG", name = "태극인", desc = "세상의 빛깔이 빠지고 발밑에 30칸 넓이의 태극이 그려진다. 그 위의 적은 모두 멈춘다. 태극이 돌며 하늘로 떠올라 뒤집힌 뒤 도장처럼 내리찍고, 흑과 백의 물결이 한 번 더 지나간다", pose = "ult_taiji", dur = 2.0, cd = 30, chi = 100, armor = true,
			mech = { kind = "taijiSeal", delay = 0.35, radius = 30, liftAt = 1.1, hitAt = 1.75, hit = hit(0, 0, 0, 80, 300, 1.0, 50, 20), waveAt = 0.3, wave = hit(0, 0, 0, 24, 60, 0.4, 60, 8) } },
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
	gimmick = "흡혈: 준 피해의 2%만큼 체력을 되찾는다 (한 번에 최대 체력의 1.5%, 1초에 4%까지)",
	deflect = 0.2,
	lifesteal = 0.02,
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
		G = { id = "hmG", name = "혈마강림", desc = "등 뒤로 거대한 혈마의 허상이 솟아 손톱으로 적들을 네 번 찢고 포효한다. 그 뒤 8초 광란 (동작 ×1.2, 흡혈 1.5배)", pose = "ult_blood", dur = 1.8, cd = 30, chi = 100, armor = true, buff = { kind = "frenzy", dur = 8 },
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
	grade = "천외천",
	hidden = true,
	secret = true,
	realmReq = 10,
	unlockHint = "생사경에 오른 자만이 이름 없는 노인을 만난다. 강호의 끝, 아무도 가지 않는 구석에서",
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
	grade = "천외천",
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
-- 궁극: 태초신권 (무극의 경지에 오른 자만, 천외봉의 시원자에게). 세상이 처음 열리던 때의 주먹
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
	realmReq = 13,
	trialHp = 10, -- 시험의 분신 체력 열 배
	unlockHint = "무극의 경지에 오른 자만이 하늘 끝 봉우리, 천외봉의 시원자를 만난다",
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
-- 정점: 일월신권 (태초신권을 익힌 무극의 고수만, 일월대의 권존에게). 해와 달을 두 손에 쥔 주먹
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
	realmReq = 13,
	styleReq = "taecho",
	trialHp = 10, -- 시험 (권존이 직접 보스로) 체력 열 배
	unlockHint = "태초신권을 익힌 무극의 고수만이 세상 동남쪽 끝 일월대에서 권존을 만난다",
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
-- 바다: 창해신권 (서해 바닷가 창해각의 창해옹에게). 받아 흘리는 태허와 달리, 밀려와 모든 것을 삼키는 파도
table.insert(Config.Styles, {
	id = "changhae",
	name = "창해신권",
	hanja = "滄海神拳",
	icon = "🌊",
	color = Color3.fromRGB(40, 130, 230),
	color2 = Color3.fromRGB(205, 245, 255),
	fx = "ocean",
	grade = "전설",
	desc = "끝없는 바다를 두 손에 담은 권법. 태허유수권이 받아 흘리는 물이라면, 창해신권은 밀려와 모든 것을 삼키는 파도다. 한 번 밀리기 시작하면 끝까지 쓸려 간다.",
	gimmick = "파도: 네 번 맞힐 때마다 상대 자리에서 물기둥이 솟아 둘레를 쓸어 낸다. 모든 공격의 밀어냄 1.3배",
	deflect = 0.24,
	kbMult = 1.3,
	pulse = { every = 4, kind = "tide", radius = 11, delay = 0.25, name = "파도", dmg = 24, posture = 26, stun = 0.5, kb = 34, up = 14 },
	stance = "stance_ocean",
	combo = {
		{ id = "ch1", name = "파랑장", pose = "wave_palm_r", dur = 0.32, lunge = 3, hits = { hit(0.13, 6, 4.5, 9, 9, 0.35, 10) } },
		{ id = "ch2", name = "역랑장", pose = "wave_palm_l", dur = 0.32, lunge = 3, hits = { hit(0.13, 6, 4.5, 9, 9, 0.35, 10) } },
		{ id = "ch3", name = "소용돌이각", pose = "whirl_kick", dur = 0.42, lunge = 2, hits = { hit(0.22, 0, 7, 11, 12, 0.4, 16, nil, true) } },
		{ id = "ch4", name = "해일권", pose = "tidal_punch", dur = 0.5, lunge = 4, hits = { hit(0.24, 8, 5, 17, 22, 0.55, 40) } },
	},
	heavy = { id = "chH", name = "노도격", pose = "billow_strike", dur = 0.7, lunge = 3, hits = { hit(0.36, 10, 6.5, 26, 40, 0.8, 70, 8) } },
	skills = {
		E = { id = "chE", name = "파도타기", desc = "파도를 타고 앞으로 미끄러지며 꿰뚫는다 (무적). 지나간 길에 물보라가 솟아 터진다", pose = "surf_dash", dur = 0.5, cd = 7, chi = 15, lunge = 26, iframes = 0.42,
			hits = { hit(0.15, 6, 4.5, 14, 14, 0.45, 24) },
			mech = { kind = "trail", delay = 0.5, count = 5, radius = 6, hit = hit(0, 0, 0, 16, 16, 0.5, 20, 12), fx = "tide" } },
		R = { id = "chR", name = "해일벽", desc = "앞으로 물의 벽이 차례로 솟아 한 줄을 휩쓸고, 맞은 적을 멀리 밀어낸다", pose = "wall_raise", dur = 1.0, cd = 10, chi = 25,
			mech = { kind = "line", count = 8, start = 4, spacing = 4.4, step = 0.05, delay = 0.35, radius = 6, hit = hit(0, 0, 0, 20, 22, 0.6, 40, 16), fx = "tide" } },
		G = { id = "chG", name = "창해일소", desc = "등 뒤의 바다가 일어선다. 하늘을 가리는 해일이 앞으로 밀려가며 모든 적을 휩쓸어 끌고 가고, 마지막에 부서지며 거대한 소용돌이가 된다", pose = "ult_tsunami", dur = 2.2, cd = 30, chi = 100, armor = true,
			mech = { kind = "tsunami", delay = 0.5, start = -6, width = 46, depth = 10, speed = 34, dur = 1.8, every = 0.2, hit = hit(0, 0, 0, 10, 10, 0.4, 0), finalRadius = 22, final = hit(0, 0, 0, 90, 120, 1.3, 60, 22) } },
	},
})
-- 정점 둘째: 영겁신권 (태초신권을 익힌 무극의 고수만, 천 개의 계단 위 영겁노인에게). 시간을 쥔 주먹
table.insert(Config.Styles, {
	id = "yeonggeop",
	name = "영겁신권",
	hanja = "永劫神拳",
	icon = "⏳",
	color = Color3.fromRGB(110, 200, 255),
	color2 = Color3.fromRGB(255, 215, 130),
	fx = "time",
	grade = "지존",
	hidden = true,
	secret = true,
	realmReq = 13,
	styleReq = "taecho",
	trialHp = 12,
	unlockHint = "태초신권을 익힌 무극의 고수만이 북서쪽 끝 천 개의 계단 위, 떠 있는 문 앞에서 영겁노인을 만난다",
	desc = "시간을 쥔 주먹. 맞은 자의 시간이 멎고, 지나간 주먹이 메아리처럼 되돌아와 다시 친다. 마지막 한 수에 하늘에 거대한 해시계가 열리고 열두 번의 종이 울린다.",
	gimmick = "정지: 다섯 번 맞힐 때마다 상대 둘레의 시간이 1.4초 멎고 메아리가 친다. 모든 기술 대기 30% 짧음, 동작 +10%",
	deflect = 0.3,
	postureMult = 1.6,
	speed = 1.1,
	cdMult = 0.7,
	pulse = { every = 5, kind = "time", radius = 12, delay = 0.35, name = "시간 정지", dmg = 44, posture = 44, stun = 1.4, kb = 0, up = 0 },
	stance = "stance_time",
	combo = {
		{ id = "yg1", name = "찰나장", pose = "time_palm_r", dur = 0.27, lunge = 3, hits = { hit(0.11, 6, 4.5, 19, 15, 0.35, 8) } },
		{ id = "yg2", name = "순간장", pose = "time_palm_l", dur = 0.27, lunge = 3, hits = { hit(0.11, 6, 4.5, 19, 15, 0.35, 8) } },
		{ id = "yg3", name = "회귀각", pose = "rewind_kick", dur = 0.4, lunge = 2, hits = { hit(0.2, 6, 6, 23, 22, 0.45, 16) } },
		{ id = "yg4", name = "정시권", pose = "hour_punch", dur = 0.46, lunge = 3, hits = { hit(0.22, 9, 5.5, 31, 34, 0.6, 32) } },
	},
	heavy = { id = "ygH", name = "영겁일격", pose = "hour_strike", dur = 0.75, lunge = 4, hits = { hit(0.4, 14, 7, 62, 92, 1.1, 60, 8, true) } },
	skills = {
		E = { id = "ygE", name = "역행보", desc = "앞으로 꿰뚫고 지나간 뒤 (무적), 0.6초 뒤 시간이 거꾸로 돌아 제자리로 되돌아오며 지나온 길의 적을 다시 벤다", pose = "rewind_step", dur = 0.5, cd = 6, chi = 20, lunge = 24, iframes = 0.45,
			hits = { hit(0.15, 6, 4.5, 26, 24, 0.5, 10) },
			mech = { kind = "rewind", delay = 0.6, radius = 6, hit = hit(0, 0, 0, 34, 30, 0.6, 8) } },
		R = { id = "ygR", name = "정지된 시간", desc = "앞에 시간이 멎은 구역을 2초 연다. 안의 적은 꼼짝 못 하고 째깍일 때마다 베인다", pose = "stop_palm", dur = 0.9, cd = 9, chi = 30,
			mech = { kind = "zone", dist = 10, radius = 13, dur = 2, every = 0.25, delay = 0.25, hit = hit(0, 0, 0, 8, 10, 0.45, 0), fx = "time" } },
		G = { id = "ygG", name = "만겁귀환", desc = "하늘에 거대한 해시계가 열리고 시곗바늘이 거꾸로 돈다. 둘레의 모든 적의 시간이 멎고, 열두 번의 종이 울릴 때마다 베이며, 자정에 시간이 깨진다", pose = "ult_clock", dur = 3.2, cd = 32, chi = 100, armor = true,
			mech = { kind = "clock", radius = 55, delay = 0.6, bells = 12, every = 0.17, hit = hit(0, 0, 0, 20, 18, 0.3, 0), final = hit(0, 0, 0, 200, 260, 1.6, 60, 24) } },
	},
})
-- 불: 열화신권 (붉은 황야 동쪽 불 제단의 염백에게). 맞은 자에게 불이 붙는다
table.insert(Config.Styles, {
	id = "yeolhwa",
	name = "열화신권",
	hanja = "烈火神拳",
	icon = "🔥",
	color = Color3.fromRGB(255, 105, 30),
	color2 = Color3.fromRGB(255, 225, 120),
	fx = "fire",
	grade = "전설",
	desc = "타오르는 불꽃을 주먹에 담았다. 맞은 자는 불이 붙어 계속 타고, 불붙은 적에게 꽂는 강타는 터진다.",
	gimmick = "연소: 맞힌 적이 3초 동안 불탄다 (0.5초마다 피해). 불타는 적에게 강타(Z)를 꽂으면 폭발해 둘레까지 태운다",
	deflect = 0.2,
	burn = { dur = 3, every = 0.5, dmg = 5 },
	stance = "stance_fire",
	combo = {
		{ id = "yh1", name = "화염장", pose = "fire_jab_r", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4, 10, 9, 0.35, 8) } },
		{ id = "yh2", name = "염조권", pose = "fire_jab_l", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4, 10, 9, 0.35, 8) } },
		{ id = "yh3", name = "화륜각", pose = "flame_wheel", dur = 0.42, lunge = 2, hits = { hit(0.22, 6, 5.5, 13, 14, 0.4, 14, 8) } },
		{ id = "yh4", name = "열화권", pose = "blaze_punch", dur = 0.48, lunge = 4, hits = { hit(0.24, 8, 5, 19, 24, 0.55, 34) } },
	},
	heavy = { id = "yhH", name = "폭염추", pose = "blaze_hammer", dur = 0.7, lunge = 3, hits = { hit(0.36, 8, 6.5, 28, 40, 0.8, 50, 6, true) }, ignite = { radius = 11, dmg = 30, posture = 30 } },
	skills = {
		E = { id = "yhE", name = "화룡보", desc = "불길이 되어 앞으로 꿰뚫고 지나간다 (무적). 지나간 길에 불기둥이 솟는다", pose = "flame_dash", dur = 0.45, cd = 7, chi = 15, lunge = 24, iframes = 0.4,
			hits = { hit(0.15, 6, 4.5, 14, 12, 0.4, 16) },
			mech = { kind = "trail", delay = 0.45, count = 5, radius = 6, hit = hit(0, 0, 0, 16, 14, 0.5, 10, 10), fx = "fire" } },
		R = { id = "yhR", name = "염화폭풍", desc = "앞쪽 부채꼴로 불길을 1.2초 동안 내뿜는다 (맞은 적은 불탄다)", pose = "fire_breath_palm", dur = 1.2, cd = 10, chi = 25,
			mech = { kind = "cone", range = 20, angle = 70, delay = 0.2, dur = 1.2, every = 0.2, hit = hit(0, 0, 0, 7, 8, 0.3, 6), fx = "fire" } },
		G = { id = "yhG", name = "열화천멸", desc = "땅이 갈라져 용암이 둘레의 모든 적 발밑으로 흐르고, 적마다 불기둥이 솟는다. 마지막에 내 자리에서 화산이 터진다", pose = "ult_volcano", dur = 2.2, cd = 30, chi = 100, armor = true,
			mech = { kind = "eruption", radius = 32, delay = 0.6, stagger = 0.08, pillar = hit(0, 0, 0, 48, 40, 0.8, 20, 30), finalAt = 1.7, finalRadius = 18, final = hit(0, 0, 0, 110, 130, 1.3, 60, 25) } },
	},
})
-- 비무: 무쌍신권 (비무대에서 백 번 이긴 자에게). 사람을 이기기 위해 다듬어진 주먹
table.insert(Config.Styles, {
	id = "musang",
	name = "무쌍신권",
	hanja = "無雙神拳",
	icon = "⚔",
	color = Color3.fromRGB(230, 50, 60),
	color2 = Color3.fromRGB(240, 240, 255),
	fx = "duel",
	grade = "신화",
	hidden = true,
	unlockHint = "배틀그라운드에서 백 명을 쓰러뜨린 자만이 강호 제일의 비무 권법을 얻는다",
	desc = "배틀그라운드에서 백 명을 쓰러뜨린 자의 주먹. 화려함 없이 오직 상대를 꺾는 데만 다듬어졌다. 적을 쓰러뜨릴 때마다 숨이 돌아온다.",
	gimmick = "무쌍: 사람을 상대로 주는 피해 +20%. 적을 쓰러뜨릴 때마다 체력 10%와 내공 20을 되찾는다. 흘리기 판정이 넓다",
	deflect = 0.3,
	pvpDmg = 1.2,
	killHeal = 0.1,
	stance = "stance_duel",
	combo = {
		{ id = "ms1", name = "선수", pose = "jab_l", dur = 0.26, lunge = 3, hits = { hit(0.1, 6, 4, 12, 12, 0.35, 6) } },
		{ id = "ms2", name = "결수", pose = "punch_r", dur = 0.28, lunge = 3, hits = { hit(0.11, 6, 4, 13, 13, 0.35, 8) } },
		{ id = "ms3", name = "회선퇴", pose = "roundhouse", dur = 0.4, lunge = 2, hits = { hit(0.2, 6, 5, 16, 18, 0.45, 20) } },
		{ id = "ms4", name = "단수", pose = "uppercut", dur = 0.45, lunge = 3, hits = { hit(0.22, 6, 4.5, 22, 28, 0.6, 10, 30) } },
	},
	heavy = { id = "msH", name = "필살권", pose = "punch_r_heavy", dur = 0.6, lunge = 4, hits = { hit(0.28, 7, 5, 34, 50, 0.8, 50) } },
	skills = {
		E = { id = "msE", name = "일기당천", desc = "번개처럼 파고들며 앞의 적을 모두 베고 지나간다 (무적)", pose = "dash_strike", dur = 0.45, cd = 6, chi = 15, lunge = 24, iframes = 0.4,
			hits = { hit(0.15, 6, 5, 24, 24, 0.5, 20) } },
		R = { id = "msR", name = "무쌍난무", desc = "제자리에서 사방으로 주먹과 발을 퍼붓는다 (1.2초)", pose = "whirl", dur = 1.2, cd = 9, chi = 25,
			mech = { kind = "zone", at = "self", radius = 10, dur = 1.2, every = 0.15, delay = 0.1, hit = hit(0, 0, 0, 7, 9, 0.3, 4), fx = "duel" } },
		G = { id = "msG", name = "천하무쌍", desc = "빛의 울타리가 둘레를 가두고 모든 적을 한가운데로 끌어당긴다. 여덟 번 몰아친 뒤 마지막 한 주먹으로 하늘 높이 쳐올린다", pose = "ult_spin", dur = 2.2, cd = 30, chi = 100, armor = true,
			mech = { kind = "arena", radius = 26, delay = 0.5, strikeCount = 8, every = 0.15, strikeRadius = 14, hit = hit(0, 0, 0, 16, 16, 0.4, 0), finalAt = 1.9, final = hit(0, 0, 0, 120, 150, 1.3, 20, 45) } },
	},
})
-- 천상계의 숨은 권법: 아공신권 (금 간 허공의 아공선인에게). 공간을 접고 찢는 주먹
table.insert(Config.Styles, {
	id = "agong",
	name = "아공신권",
	hanja = "亞空神拳",
	icon = "🌌",
	color = Color3.fromRGB(70, 30, 140),
	color2 = Color3.fromRGB(140, 255, 230),
	fx = "subspace",
	grade = "지존",
	hidden = true,
	secret = true,
	realmReq = 14,
	unlockHint = "천상계 어딘가, 허공에 금이 간 작은 섬. 보이지 않는 다리를 건넌 반선의 고수만이 아공선인을 만난다",
	desc = "공간의 틈에 사는 노인의 주먹. 주먹이 닿는 곳마다 공간이 접히고, 오의를 펼치면 그 자리에 바깥과 끊긴 공간이 열린다.",
	gimmick = "틈새: 뒤에서 치면 1.4배. 기술 대기 15% 짧고, 회피를 두 번 이어 쓴다",
	deflect = 0.3,
	backstab = 1.4,
	cdMult = 0.85,
	dashCharges = 2,
	stance = "stance_subspace",
	combo = {
		{ id = "ag1", name = "접은 손", pose = "void_palm_r", dur = 0.26, lunge = 3, hits = { hit(0.1, 6, 4, 13, 12, 0.35, 6) } },
		{ id = "ag2", name = "틈새 손", pose = "void_palm_l", dur = 0.28, lunge = 3, hits = { hit(0.11, 6, 4, 14, 13, 0.35, 8) } },
		{ id = "ag3", name = "공간 돌려차기", pose = "back_spin_kick", dur = 0.42, lunge = 2, hits = { hit(0.22, 6.5, 5, 18, 20, 0.45, 22) } },
		{ id = "ag4", name = "허공 원장", pose = "void_circle", dur = 0.45, lunge = 3, hits = { hit(0.24, 6, 5, 24, 28, 0.6, 12, 26) } },
	},
	heavy = { id = "agH", name = "공간 밀치기", pose = "void_push", dur = 0.6, lunge = 4, hits = { hit(0.28, 8, 5.5, 36, 50, 0.8, 55) } },
	skills = {
		E = { id = "agE", name = "공간 접기", desc = "공간을 접어 가장 가까운 적의 등 뒤로 나타나 친다 (치명타)", pose = "shadow_heel", dur = 0.5, cd = 6, chi = 15, teleport = 30,
			hits = { hit(0.2, 6, 4.5, 26, 24, 0.6, 20) } },
		R = { id = "agR", name = "공간 균열", desc = "앞의 공간을 찢어 1.5초 동안 둘레의 적을 빨아들이며 벤다", pose = "void_gather", dur = 0.7, cd = 9, chi = 25,
			mech = { kind = "zone", radius = 11, dist = 10, dur = 1.5, every = 0.15, delay = 0.15, pull = 40, hit = hit(0, 0, 0, 8, 9, 0.3, 0), fx = "subspace" } },
		G = { id = "agG", name = "아공간", desc = "그 자리에 바깥과 끊긴 공간을 연다. 10초 동안 안의 적은 빠져나가지 못하고, 사방에서 공간이 베어 든다. 마지막에 공간이 닫히며 터진다", pose = "ult_void", dur = 1.6, cd = 32, chi = 100, armor = true,
			mech = { kind = "subspace", radius = 26, dur = 10, every = 0.4, delay = 0.6, hit = hit(0, 0, 0, 13, 12, 0.3, 0), final = hit(0, 0, 0, 150, 170, 1.4, 30, 45) } },
	},
})
-- 천상계의 권법 (약): 운류장 (천궁 정자의 운류자에게). 구름처럼 밀어내는 손바닥
table.insert(Config.Styles, {
	id = "unryu",
	name = "운류장",
	hanja = "雲流掌",
	icon = "☁",
	color = Color3.fromRGB(190, 220, 255),
	color2 = Color3.fromRGB(255, 255, 255),
	fx = "cloud",
	grade = "상급",
	desc = "구름이 흐르듯 손바닥을 밀어 적을 흩어 놓는다. 세지는 않지만 몸이 가볍고 빠져나가기 좋다.",
	gimmick = "구름 걸음: 회피를 두 번 이어 쓰고, 흘리기 판정이 넓다. 손바닥은 적을 멀리 밀어낸다",
	deflect = 0.34,
	dashCharges = 2,
	kbMult = 1.4,
	stance = "stance_cloud",
	combo = {
		{ id = "ur1", name = "운수장", pose = "palm_r", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4.5, 9, 10, 0.35, 10) } },
		{ id = "ur2", name = "류수장", pose = "palm_l", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4.5, 9, 10, 0.35, 10) } },
		{ id = "ur3", name = "회운장", pose = "circle_palm", dur = 0.42, lunge = 2, hits = { hit(0.22, 6, 5.5, 12, 14, 0.45, 18) } },
		{ id = "ur4", name = "추운장", pose = "push_palm", dur = 0.46, lunge = 3, hits = { hit(0.24, 7, 5, 16, 20, 0.55, 32) } },
	},
	heavy = { id = "urH", name = "쌍운장", pose = "double_palm", dur = 0.6, lunge = 4, hits = { hit(0.28, 7.5, 5.5, 24, 34, 0.7, 50) } },
	skills = {
		E = { id = "urE", name = "운보", desc = "구름을 밟듯 앞으로 미끄러지며 지나가는 적을 친다 (무적)", pose = "dash_strike", dur = 0.45, cd = 6, chi = 15, lunge = 18, iframes = 0.35,
			hits = { hit(0.14, 6, 5, 14, 14, 0.45, 26) } },
		R = { id = "urR", name = "운해장", desc = "앞에 구름 소용돌이를 펼쳐 1초 동안 둘레의 적을 친다", pose = "push_palm", dur = 0.6, cd = 9, chi = 25,
			mech = { kind = "zone", radius = 10, dist = 9, dur = 1.0, every = 0.2, delay = 0.15, hit = hit(0, 0, 0, 7, 9, 0.3, 12), fx = "cloud" } },
		G = { id = "urG", name = "만리운해", desc = "발밑에서 구름 바다가 넓게 퍼져 2초 동안 둘레의 모든 적을 친다", pose = "ult_raise", dur = 1.4, cd = 28, chi = 100, armor = true,
			mech = { kind = "zone", at = "self", radius = 18, dur = 2.0, every = 0.2, delay = 0.2, hit = hit(0, 0, 0, 12, 12, 0.35, 16), fx = "cloud" } },
	},
})
-- 천상계의 권법 (강): 성하신권 (성운원 깊은 곳의 성하노군에게). 은하를 끌어내리는 주먹
table.insert(Config.Styles, {
	id = "seongha",
	name = "성하신권",
	hanja = "星河神拳",
	icon = "🌠",
	color = Color3.fromRGB(60, 80, 200),
	color2 = Color3.fromRGB(255, 235, 170),
	fx = "galaxy",
	grade = "태초",
	hidden = true,
	secret = true,
	realmReq = 15,
	trialHp = 10,
	unlockHint = "천상계 성운원의 가장 깊은 곳, 성군의 등 뒤에서 별을 헤아리는 노인. 등선에 오른 자에게만 별의 길을 보여 준다",
	desc = "별의 강을 주먹에 담았다. 주먹이 닿는 곳마다 별빛이 흩어지고, 오의를 펼치면 머리 위에 은하가 열려 별이 쏟아진다.",
	gimmick = "성하: 균형을 1.5배로 깎고, 기술 대기 20% 짧다",
	deflect = 0.28,
	postureMult = 1.5,
	cdMult = 0.8,
	stance = "stance_galaxy",
	combo = {
		{ id = "sh1", name = "성권", pose = "star_punch_r", dur = 0.26, lunge = 3, hits = { hit(0.1, 6, 4.5, 15, 14, 0.35, 8) } },
		{ id = "sh2", name = "월권", pose = "star_punch_l", dur = 0.28, lunge = 3, hits = { hit(0.11, 6, 4.5, 15, 14, 0.35, 8) } },
		{ id = "sh3", name = "은하장", pose = "galaxy_palm", dur = 0.42, lunge = 2, hits = { hit(0.22, 6.5, 5.5, 20, 24, 0.5, 20) } },
		{ id = "sh4", name = "천성각", pose = "heaven_kick", dur = 0.46, lunge = 3, hits = { hit(0.24, 6.5, 5, 26, 30, 0.6, 12, 30) } },
	},
	heavy = { id = "shH", name = "유성추", pose = "meteor_drop", dur = 0.65, lunge = 4, hits = { hit(0.3, 8, 6, 40, 56, 0.85, 50) } },
	skills = {
		E = { id = "shE", name = "유성 돌진", desc = "유성처럼 꼬리를 끌며 돌진해 앞의 적을 꿰뚫는다 (무적)", pose = "lightning_dash", dur = 0.45, cd = 6, chi = 15, lunge = 26, iframes = 0.4,
			hits = { hit(0.15, 6, 5.5, 28, 28, 0.5, 24) } },
		R = { id = "shR", name = "은하 소용돌이", desc = "둘레에 별의 소용돌이를 일으켜 1.4초 동안 적을 빨아들이며 친다", pose = "void_circle", dur = 0.7, cd = 9, chi = 25,
			mech = { kind = "zone", at = "self", radius = 13, dur = 1.4, every = 0.14, delay = 0.1, pull = 50, hit = hit(0, 0, 0, 9, 10, 0.3, 0), fx = "galaxy" } },
		G = { id = "shG", name = "성하강림", desc = "머리 위에 은하가 열리고, 별이 나선을 그리며 스물네 번 쏟아진 뒤 한가운데에서 별이 터진다", pose = "ult_heaven", dur = 3.0, cd = 34, chi = 100, armor = true,
			mech = { kind = "galaxy", radius = 32, delay = 0.8, count = 24, stagger = 0.09, strikeRadius = 7, hit = hit(0, 0, 0, 30, 30, 0.5, 10, 10), finalAt = 3.3, finalRadius = 20, final = hit(0, 0, 0, 160, 180, 1.5, 40, 50) } },
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
-- 각성 권법 (진): 원래 권법을 완전 각성하고 두 번 깨달은 자가, 각성 시련에서 '각성한 자기 그림자'를 넘으면 얻는다
-- 기술은 원래 권법 그대로 (버전 2): 모든 기술이 더 세고, 빛깔이 바뀌고, 고유 장치와 오의가 한층 커진다
local function deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in pairs(t) do
		out[k] = deepCopy(v)
	end
	return out
end
-- 표 안의 모든 타격(dmg가 있는 표)을 k배로 (기술 이름 id 앞에는 v를 붙여 원래 것과 구별)
local function boostHits(t: any, k: number)
	if type(t) ~= "table" then
		return
	end
	if type(t.dmg) == "number" then
		t.dmg *= k
		if type(t.posture) == "number" then
			t.posture *= 1 + (k - 1) * 0.5
		end
	end
	if type(t.id) == "string" then
		t.id = "v" .. t.id
	end
	for _, v in pairs(t) do
		if type(v) == "table" then
			boostHits(v, k)
		end
	end
end
local function awakened(baseId: string, k: number, over: { [string]: any }): any
	local base
	for _, st in ipairs(Config.Styles) do
		if st.id == baseId then
			base = st
		end
	end
	local v = deepCopy(base)
	v.combo = deepCopy(base.combo)
	boostHits(v.combo, k)
	boostHits(v.heavy, k)
	boostHits(v.skills, k)
	for key, x in pairs(over) do
		v[key] = x
	end
	v.awakenOf = baseId
	v.hidden = true
	table.insert(Config.Styles, v)
	return v
end
-- 각성 조건 (세 권법 모두): 원래 권법 숙련 최대 + 깨달음 두 번 + 무극 경지 + 은자
Config.AWAKEN_STYLE = { realm = 10, coins = 200000, trialHp = 6 }
do
	local v = awakened("hyeolma", 1.5, {
		id = "hyeolma2", name = "진 혈마신수", hanja = "眞血魔神手", icon = "🩸", grade = "신화",
		color = Color3.fromRGB(240, 20, 50), color2 = Color3.fromRGB(255, 205, 110),
		lifesteal = 0.03,
		unlockHint = "혈마신수를 완전 각성하고 두 번 깨달은 뒤, 각성 시련에서 피에 물든 자기 그림자를 넘어라",
		desc = "혈마의 손이 주인을 알아보고 깨어났다. 손톱 끝의 피가 금빛으로 끓는다. 혈마신수의 모든 기술이 그대로, 그러나 한층 더 깊고 붉다.",
		gimmick = "진 흡혈: 준 피해의 3%를 되찾는다 (광란 중엔 1.5배, 1초에 최대 체력의 5%까지). 모든 기술 1.5배. 진 혈마강림: 더 큰 혈마가 여섯 번 찢고, 광란 10초",
	})
	local G = v.skills.G
	G.buff = { kind = "frenzy", dur = 10 }
	G.desc = "등 뒤로 하늘을 가릴 만큼 거대한 혈마가 솟아 손톱으로 적들을 여섯 번 찢고 포효한다. 그 뒤 10초 광란 (동작 ×1.2, 흡혈 1.5배)"
	local strike = G.mech.strikes[1].hit
	G.mech.dur = 5
	G.mech.scale = 1.35
	G.mech.strikes = {}
	for i = 0, 5 do
		table.insert(G.mech.strikes, { t = 0.9 + i * 0.5, at = "targets", n = 4, radius = 10, hit = strike })
	end
	table.insert(G.mech.strikes, { t = 4.2, at = "around", radius = 28, hit = hit(0, 0, 0, 110, 140, 1.4, 70, 14) })
end
do
	local v = awakened("cheonryong", 1.5, {
		id = "cheonryong2", name = "진 천룡파천장", hanja = "眞天龍破天掌", icon = "🐲", grade = "신화",
		color = Color3.fromRGB(255, 195, 60), color2 = Color3.fromRGB(255, 248, 215),
		charge = 1.0,
		unlockHint = "천룡파천장을 완전 각성하고 두 번 깨달은 뒤, 각성 시련에서 금빛 용을 두른 자기 그림자를 넘어라",
		desc = "푸른 용이 허물을 벗고 금빛 진룡이 되었다. 장풍은 더 빨리 모이고, 땅을 뚫고 나오는 용은 하늘을 다 덮는다.",
		gimmick = "진 용기: 1초면 장풍이 가득 모인다. 모든 기술 1.5배. 진 진룡강림: 거대한 금룡이 다섯 번 내리꽂히고 더 큰 숨을 뿜는다",
	})
	local G = v.skills.G
	G.desc = "땅을 뚫고 거대한 금룡이 솟아 적에게 다섯 번 내리꽂히고, 마지막에 앞으로 하늘을 가르는 용의 숨을 뿜는다"
	local strike = G.mech.strikes[1].hit
	local breath = G.mech.strikes[#G.mech.strikes].hit
	G.mech.dur = 3.6
	G.mech.scale = 1.4
	G.mech.strikes = {}
	for i = 0, 4 do
		table.insert(G.mech.strikes, { t = 0.9 + i * 0.4, at = "targets", n = 1, radius = 11, hit = strike })
	end
	table.insert(G.mech.strikes, { t = 3.1, at = "front", dist = 18, radius = 22, hit = breath })
end
do
	local v = awakened("byeokryeok", 1.5, {
		id = "byeokryeok2", name = "진 벽력신권", hanja = "眞霹靂神拳", icon = "🌩", grade = "신화",
		color = Color3.fromRGB(175, 110, 255), color2 = Color3.fromRGB(235, 228, 255),
		chargeEvery = 4, chainDmg = 22, chainRange = 22,
		unlockHint = "벽력신권을 완전 각성하고 두 번 깨달은 뒤, 각성 시련에서 보랏빛 벼락이 된 자기 그림자를 넘어라",
		desc = "노란 벼락이 보랏빛 천뢰가 되었다. 주먹이 닿기 전에 소리가 먼저 터지고, 연쇄 번개가 더 멀리 더 세게 튄다.",
		gimmick = "진 전하: 네 번 맞히면 연쇄 천뢰 (더 넓고 더 세다). 모든 기술 1.5배. 진 뇌신화: 열한 번 튀고 하늘이 크게 갈라진다",
	})
	local G = v.skills.G
	G.desc = "몸이 보랏빛 천뢰가 되어 적에서 적으로 열한 번 튄다. 닿을 때마다 벼락이 떨어지고, 마지막에 하늘이 크게 갈라진다"
	G.mech.n = 11
	G.mech.finalRadius = 26
end

------------------------------------------------------------------------
-- 1.9판: 새 각성 권법 셋. 원래 권법을 그대로 키운 진 권법(혈마·천룡·벽력)과 달리, 기술도 고유 장치도 새로 짰다
-- 조건: 원래 권법 숙련 최대 + 깨달음 두 번 + 무극 경지 + 은자 + 환생 한 번 (rebirthReq) → 각성 시련
------------------------------------------------------------------------
table.insert(Config.Styles, {
	id = "geumgang2", name = "진 금강불괴신공", hanja = "眞金剛不壞神功", icon = "🗿", grade = "신화",
	color = Color3.fromRGB(255, 176, 40), color2 = Color3.fromRGB(255, 250, 225), fx = "gold",
	awakenOf = "geumgang", hidden = true, rebirthReq = 1,
	unlockHint = "불괴금강신권을 완전 각성하고 두 번 깨달은 뒤, 한 번 환생한 몸으로 각성 시련에서 금빛 불상이 된 자기 그림자를 넘어라",
	desc = "다시 태어난 몸에서 금강이 깨어났다. 이제 주먹이 아니라 몸 자체가 무기다. 맞을수록 단단해지고, 쌓인 충격은 땅을 울리는 진동이 되어 되돌아간다.",
	gimmick = "불괴: 받는 피해 30% 감소. 여덟 번 맞을 때마다 (막아도 센다) 몸에서 금강 진동이 저절로 터져 둘레를 날린다. 오의 만불조종: 하늘에서 거대한 금빛 손바닥이 내려와 땅을 누른다",
	deflect = 0.2, speed = 0.92, hurtTaken = 0.7, armorWhileAttacking = 0.8,
	hurtPulse = { every = 8, radius = 16, dmg = 38, posture = 60, stun = 0.8, kb = 40, up = 14, name = "불괴진동" },
	stance = "stance_geumgang",
	combo = {
		{ id = "gk1", name = "항마장", pose = "buddha_palm", dur = 0.48, lunge = 3, hits = { hit(0.2, 6, 5, 17, 18, 0.45, 16, nil, true) } },
		{ id = "gk2", name = "금강주", pose = "elbow_r", dur = 0.46, lunge = 3, hits = { hit(0.2, 5, 4.5, 17, 18, 0.45, 16) } },
		{ id = "gk3", name = "천근각", pose = "grav_stomp", dur = 0.55, lunge = 1, hits = { hit(0.26, 3, 8, 15, 22, 0.55, 22, 10, true) } },
		{ id = "gk4", name = "불괴추", pose = "hammer_down", dur = 0.68, lunge = 3, hits = { hit(0.34, 6, 7, 30, 40, 0.8, 30, 18, true) } },
	},
	heavy = { id = "gkH", name = "금강파산권", pose = "punch_r_heavy", dur = 0.75, lunge = 6, hits = { hit(0.36, 8, 6.5, 36, 55, 0.9, 60) }, chargeMult = 1.8 },
	skills = {
		E = { id = "gkE", name = "금강반탄", desc = "1.2초 동안 금빛 종이 몸을 덮는다. 그동안 받는 모든 공격을 튕겨 되돌리고, 끝에 종이 울려 둘레를 친다", pose = "brace", dur = 0.6, cd = 11, chi = 25,
			mech = { kind = "reflect", dur = 1.2, radius = 14, hit = hit(0, 0, 0, 22, 30, 0.6, 30), wave = hit(0, 0, 0, 28, 40, 0.8, 40, 12) } },
		R = { id = "gkR", name = "항마금강저", desc = "땅을 내리찍으면 앞으로 금강저 일곱 개가 차례로 솟아 길을 가르고 적을 띄운다", pose = "grav_hammer", dur = 0.8, cd = 10, chi = 25,
			mech = { kind = "line", count = 7, start = 5, spacing = 4.6, step = 0.07, delay = 0.35, radius = 6, hit = hit(0, 0, 0, 26, 30, 0.6, 18, 26), fx = "gold" } },
		G = { id = "gkG", name = "만불조종", desc = "하늘이 갈라지며 산만 한 금빛 손바닥이 내려와 둘레의 땅을 누른다. 눌린 적은 오래 묶이고, 땅이 세 번 울린다", pose = "ult_buddha", dur = 1.6, cd = 30, chi = 100, armor = true,
			mech = { kind = "palm", radius = 26, delay = 1.0, hit = hit(0, 0, 0, 120, 150, 1.6, 10, -10), quake = hit(0, 0, 0, 24, 30, 0.5, 20, 14), quakes = 3, every = 0.35 } },
	},
})
table.insert(Config.Styles, {
	id = "muyeong2", name = "진 무영귀각", hanja = "眞無影鬼脚", icon = "👤", grade = "신화",
	color = Color3.fromRGB(110, 60, 220), color2 = Color3.fromRGB(215, 200, 255), fx = "shadow",
	awakenOf = "muyeong", hidden = true, rebirthReq = 1,
	unlockHint = "무영귀각을 완전 각성하고 두 번 깨달은 뒤, 한 번 환생한 몸으로 각성 시련에서 그림자뿐인 자기 그림자를 넘어라",
	desc = "다시 태어난 몸에서 그림자가 따로 걷기 시작했다. 내 발이 닿은 곳에 한 박자 늦게 그림자의 발이 또 닿는다. 상대는 두 번 맞고도 한 번 본다.",
	gimmick = "영각: 연타·강타가 맞을 때마다 그림자가 한 박자 뒤 같은 자리를 한 번 더 찬다 (45%). 대시 세 번, 등 뒤를 차면 1.7배. 오의 백귀야행: 그림자 여덟이 둘레를 가로지르며 짓밟는다",
	deflect = 0.2, speed = 1.12, backstab = 1.7, dashCharges = 3, shadowEcho = 0.45,
	stance = "stance_muyeong",
	combo = {
		{ id = "mk1", name = "영각", pose = "side_kick", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4, 9, 8, 0.3, 6) } },
		{ id = "mk2", name = "쌍영각", pose = "roundhouse", dur = 0.36, lunge = 2, hits = { hit(0.12, 6, 4.5, 6, 6, 0.25, 4), hit(0.24, 6, 4.5, 6, 6, 0.3, 8) } },
		{ id = "mk3", name = "귀선퇴", pose = "whirl_kick", dur = 0.42, lunge = 2, hits = { hit(0.2, 5, 6, 11, 10, 0.4, 12, nil, true) } },
		{ id = "mk4", name = "낙귀각", pose = "axe_kick", dur = 0.5, lunge = 3, hits = { hit(0.26, 6, 4.5, 18, 22, 0.55, 8, 24) } },
	},
	heavy = { id = "mkH", name = "귀영섬각", pose = "flying_kick", dur = 0.5, lunge = 20, iframes = 0.25, hits = { hit(0.22, 7, 5, 24, 26, 0.6, 34) } },
	skills = {
		E = { id = "mkE", name = "영보삼연", desc = "그림자를 밟고 가장 가까운 적 셋의 등 뒤로 차례로 건너뛰며 찬다 (무적, 모두 등 뒤 치명)", pose = "shadow_heel", dur = 0.5, cd = 8, chi = 20,
			mech = { kind = "chainTp", n = 3, range = 30, delay = 0.06, every = 0.16, hit = hit(0, 0, 0, 22, 18, 0.5, 18) } },
		R = { id = "mkR", name = "그림자 감옥", desc = "발밑의 그림자가 둘레로 번져 적들의 발을 붙든다. 1.2초 뒤 그림자가 솟아 한꺼번에 걷어찬다", pose = "point_sky", dur = 0.7, cd = 12, chi = 25,
			mech = { kind = "freeze", delay = 0.2, radius = 16, dur = 1.3, hitAt = 1.2, hit = hit(0, 0, 0, 34, 36, 0.8, 26, 22) } },
		G = { id = "mkG", name = "백귀야행", desc = "세상이 어두워지고 그림자 여덟이 둘레의 땅에서 솟는다. 그림자들이 적들 사이를 엇갈려 가로지르며 열두 번 짓밟고, 마지막에 모두 한가운데로 모여 하늘로 걷어찬다 (그동안 무적)", pose = "ult_shadow", dur = 1.8, cd = 30, chi = 100, armor = true,
			mech = { kind = "parade", radius = 24, ghosts = 8, passes = 12, delay = 0.45, every = 0.16, width = 5, hit = hit(0, 0, 0, 14, 14, 0.4, 10), final = hit(0, 0, 0, 90, 110, 1.3, 20, 60), finalRadius = 18 } },
	},
})
table.insert(Config.Styles, {
	id = "taeheo2", name = "진 태허유수장", hanja = "眞太虛流水掌", icon = "🌊", grade = "신화",
	color = Color3.fromRGB(50, 200, 255), color2 = Color3.fromRGB(225, 252, 255), fx = "water",
	awakenOf = "taeheo", hidden = true, rebirthReq = 1,
	unlockHint = "태허유수장을 완전 각성하고 두 번 깨달은 뒤, 한 번 환생한 몸으로 각성 시련에서 물이 된 자기 그림자를 넘어라",
	desc = "다시 태어난 몸이 물이 되었다. 흘려 낸 힘은 사라지지 않고 물결이 되어 둘레를 덮친다. 물은 다투지 않는다. 다만 모든 것을 덮을 뿐.",
	gimmick = "역류: 흘리기 틈이 넓고 (0.3초), 흘려 낼 때마다 물결이 둘레로 터져 적을 밀어낸다. 오의 천하수류: 물의 용 셋이 나를 감아 돌며 둘레를 휩쓸고, 마지막에 한데 모여 앞으로 덮친다",
	deflect = 0.3, speed = 1.05, deflectWave = { radius = 14, dmg = 26, posture = 40, stun = 0.6, kb = 36, up = 8 },
	stance = "stance_taeheo",
	combo = {
		{ id = "tk1", name = "유수장", pose = "wave_palm_r", dur = 0.32, lunge = 2, hits = { hit(0.13, 6, 4.5, 9, 10, 0.35, 8) } },
		{ id = "tk2", name = "역수장", pose = "wave_palm_l", dur = 0.32, lunge = 2, hits = { hit(0.13, 6, 4.5, 9, 10, 0.35, 8) } },
		{ id = "tk3", name = "회류", pose = "circle_palm", dur = 0.4, lunge = 1, hits = { hit(0.18, 4, 7, 10, 12, 0.4, 10, nil, true) } },
		{ id = "tk4", name = "해일장", pose = "double_palm", dur = 0.52, lunge = 3, hits = { hit(0.24, 7, 5.5, 17, 24, 0.55, 40) } },
	},
	heavy = { id = "tkH", name = "만류반탄장", pose = "tide_push", dur = 0.6, lunge = 2, hits = { hit(0.28, 7, 6, 22, 34, 0.65, 55) }, stackDmg = 0.6 },
	skills = {
		E = { id = "tkE", name = "수벽파", desc = "두 손으로 물의 벽을 밀어낸다. 1초 동안 앞쪽 부채꼴로 물결이 계속 밀려가 적을 밀어내고 균형을 깎는다", pose = "push_palm", dur = 0.6, cd = 9, chi = 20,
			mech = { kind = "cone", range = 22, angle = 70, dur = 1.0, every = 0.2, delay = 0.2, hit = hit(0, 0, 0, 8, 16, 0.35, 26), fx = "water" } },
		R = { id = "tkR", name = "용오름", desc = "발밑에서 물기둥이 솟아 둘레의 적을 하늘로 띄운다. 떠오른 적에게 물줄기가 내리꽂힌다", pose = "water_spiral", dur = 0.8, cd = 11, chi = 25,
			mech = { kind = "launch", delay = 0.3, radius = 14, up = 60, stun = 1.4, hitAt = 0.55, hit = hit(0, 0, 0, 30, 30, 0.8, 0, -10) } },
		G = { id = "tkG", name = "천하수류", desc = "물의 용 셋이 몸을 감고 솟아올라 2.6초 동안 둘레를 휘감아 돌며 휩쓴다. 마지막에 셋이 하나로 엉겨 앞으로 거대한 물결이 되어 덮친다", pose = "ult_tide", dur = 1.6, cd = 30, chi = 100, armor = true,
			mech = { kind = "waterDragons", n = 3, radius = 20, dur = 2.6, every = 0.22, delay = 0.3, hit = hit(0, 0, 0, 9, 12, 0.3, 12), final = hit(0, 0, 0, 100, 130, 1.4, 70, 18), finalDist = 16, finalRadius = 18 } },
	},
})

------------------------------------------------------------------------
-- 2.0판: 새 각성 권법 셋 (열화·창해·풍신). 1.9판의 셋처럼 기술과 고유 장치를 새로 짰다. 각성 사부에게서 각성한다
------------------------------------------------------------------------
table.insert(Config.Styles, {
	id = "yeolhwa2", name = "진 열화신권", hanja = "眞烈火神拳", icon = "🔥", grade = "신화",
	color = Color3.fromRGB(255, 70, 20), color2 = Color3.fromRGB(255, 235, 150), fx = "fire",
	awakenOf = "yeolhwa", hidden = true, rebirthReq = 1,
	unlockHint = "열화신권을 완전 각성하고 두 번 깨달은 뒤, 한 번 환생한 몸으로 각성 사부를 찾아가 불이 된 자기 그림자를 넘어라",
	desc = "다시 태어난 몸에서 꺼지지 않는 업화가 깨어났다. 불은 맞은 자를 태우는 것으로 끝나지 않는다. 쓰러지는 순간 터져 곁의 모두를 삼킨다.",
	gimmick = "업화: 맞힌 적이 4초 동안 더 세게 불탄다. 불타는 적이 쓰러지면 그 자리에서 터져 둘레를 태운다. 오의 화룡천멸: 하늘을 돈 불의 용이 적들에게 내리꽂히고, 떨어진 자리가 용암이 되어 터진다",
	deflect = 0.2, speed = 1.05,
	burn = { dur = 4, every = 0.5, dmg = 8 },
	burnBurst = { radius = 11, dmg = 26, posture = 30 },
	stance = "stance_fire",
	combo = {
		{ id = "yk1", name = "업화장", pose = "fire_jab_r", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4.5, 12, 10, 0.35, 8) } },
		{ id = "yk2", name = "화염쌍조", pose = "fire_jab_l", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4.5, 12, 10, 0.35, 8) } },
		{ id = "yk3", name = "염륜선풍", pose = "flame_wheel", dur = 0.44, lunge = 2, hits = { hit(0.16, 5, 6.5, 9, 9, 0.35, 10, 6, true), hit(0.3, 5, 6.5, 9, 9, 0.35, 12, 8, true) } },
		{ id = "yk4", name = "멸화권", pose = "blaze_punch", dur = 0.5, lunge = 4, hits = { hit(0.24, 8, 5.5, 24, 28, 0.6, 38) } },
	},
	heavy = { id = "ykH", name = "업화폭추", pose = "blaze_hammer", dur = 0.72, lunge = 3, hits = { hit(0.36, 8, 7, 34, 46, 0.85, 50, 8, true) }, ignite = { radius = 14, dmg = 40, posture = 40 } },
	skills = {
		E = { id = "ykE", name = "염룡질주", desc = "불길이 되어 앞으로 꿰뚫고 지나간다 (무적). 지나간 길이 한 박자 뒤 불기둥으로 터진다", pose = "flame_dash", dur = 0.45, cd = 7, chi = 15, lunge = 26, iframes = 0.42,
			hits = { hit(0.15, 6, 5, 16, 14, 0.4, 16) },
			mech = { kind = "trail", delay = 0.45, count = 6, radius = 7, hit = hit(0, 0, 0, 22, 18, 0.5, 10, 14), fx = "fire" } },
		R = { id = "ykR", name = "화산주", desc = "땅을 내리쳐 앞으로 불기둥 여덟을 차례로 세운다", pose = "blaze_hammer", dur = 0.9, cd = 10, chi = 25,
			mech = { kind = "line", count = 8, start = 4, spacing = 4.4, step = 0.06, delay = 0.35, radius = 6, hit = hit(0, 0, 0, 24, 22, 0.6, 14, 24), fx = "fire" } },
		G = { id = "ykG", name = "화룡천멸", desc = "몸에서 불의 용이 솟아 하늘을 한 바퀴 돌고, 적들에게 네 번 내리꽂힌다. 마지막에 떨어진 자리가 용암이 되어 세 번 터진다", pose = "ult_volcano", dur = 1.8, cd = 30, chi = 100, armor = true,
			mech = { kind = "fireDragon", n = 1, ringRadius = 8, rise = 1.1, riseHit = hit(0, 0, 0, 24, 24, 0.6, 10, 26), range = 40, dives = 4, every = 0.34, diveRadius = 11, hit = hit(0, 0, 0, 44, 40, 0.8, 20, 10), finalRadius = 18, final = hit(0, 0, 0, 90, 110, 1.3, 50, 22), lava = 3, lavaHit = hit(0, 0, 0, 22, 24, 0.5, 10, 16) } },
	},
})
table.insert(Config.Styles, {
	id = "changhae2", name = "진 창해신권", hanja = "眞滄海神拳", icon = "🐋", grade = "신화",
	color = Color3.fromRGB(20, 90, 210), color2 = Color3.fromRGB(190, 240, 255), fx = "ocean",
	awakenOf = "changhae", hidden = true, rebirthReq = 1,
	unlockHint = "창해신권을 완전 각성하고 두 번 깨달은 뒤, 한 번 환생한 몸으로 각성 사부를 찾아가 바다가 된 자기 그림자를 넘어라",
	desc = "다시 태어난 몸에서 깊은 바다가 깨어났다. 파도는 더 자주, 더 깊이 밀려온다. 바다의 바닥은 아무도 본 적이 없다.",
	gimmick = "심해: 세 번 맞힐 때마다 상대 자리에서 큰 물기둥이 솟는다 (더 넓고 세다). 밀어냄 1.4배. 오의 심해강림: 땅이 깊은 바다가 되어 적이 가라앉고, 거대한 물기둥이 하늘로 쳐올린다",
	deflect = 0.24, kbMult = 1.4,
	pulse = { every = 3, kind = "tide", radius = 14, delay = 0.25, name = "심해 파도", dmg = 30, posture = 30, stun = 0.6, kb = 38, up = 18 },
	stance = "stance_ocean",
	combo = {
		{ id = "cy1", name = "심해장", pose = "wave_palm_r", dur = 0.32, lunge = 3, hits = { hit(0.13, 6, 5, 11, 10, 0.35, 12) } },
		{ id = "cy2", name = "역류장", pose = "wave_palm_l", dur = 0.32, lunge = 3, hits = { hit(0.13, 6, 5, 11, 10, 0.35, 12) } },
		{ id = "cy3", name = "와류각", pose = "whirl_kick", dur = 0.42, lunge = 2, hits = { hit(0.22, 0, 8, 13, 14, 0.4, 18, nil, true) } },
		{ id = "cy4", name = "대해권", pose = "tidal_punch", dur = 0.5, lunge = 4, hits = { hit(0.24, 8, 6, 22, 26, 0.6, 46) } },
	},
	heavy = { id = "cyH", name = "해룡노도", pose = "billow_strike", dur = 0.7, lunge = 3, hits = { hit(0.36, 10, 7, 32, 46, 0.85, 80, 10) } },
	skills = {
		E = { id = "cyE", name = "해류보", desc = "물살을 타고 미끄러져 꿰뚫는다 (무적). 지나간 길에 물기둥이 솟는다", pose = "surf_dash", dur = 0.5, cd = 7, chi = 15, lunge = 28, iframes = 0.44,
			hits = { hit(0.15, 6, 5, 16, 16, 0.45, 26) },
			mech = { kind = "trail", delay = 0.5, count = 6, radius = 7, hit = hit(0, 0, 0, 20, 20, 0.5, 24, 16), fx = "tide" } },
		R = { id = "cyR", name = "해일용권", desc = "발밑에서 물기둥이 솟아 둘레의 적을 하늘로 띄우고, 물줄기가 내리꽂힌다", pose = "wall_raise", dur = 0.9, cd = 11, chi = 25,
			mech = { kind = "launch", delay = 0.3, radius = 15, up = 64, stun = 1.4, hitAt = 0.55, hit = hit(0, 0, 0, 34, 34, 0.8, 0, -12) } },
		G = { id = "cyG", name = "심해강림", desc = "앞의 땅이 깊은 바다가 된다. 1.8초 동안 적이 가라앉아 움직이지 못하고, 마지막에 한가운데서 거대한 물기둥이 솟아 모두 하늘로 쳐올린다", pose = "ult_tsunami", dur = 1.8, cd = 30, chi = 100, armor = true,
			mech = { kind = "abyss", radius = 24, dist = 6, dur = 1.8, every = 0.3, delay = 0.4, hit = hit(0, 0, 0, 10, 14, 0.3, 0), final = hit(0, 0, 0, 120, 150, 1.4, 20, 70) } },
	},
})
table.insert(Config.Styles, {
	id = "pungsin2", name = "진 풍신각", hanja = "眞風神脚", icon = "🌀", grade = "신화",
	color = Color3.fromRGB(90, 240, 190), color2 = Color3.fromRGB(235, 255, 248), fx = "wind",
	awakenOf = "pungsin", hidden = true, rebirthReq = 1,
	unlockHint = "풍신각을 완전 각성하고 두 번 깨달은 뒤, 한 번 환생한 몸으로 각성 사부를 찾아가 바람이 된 자기 그림자를 넘어라",
	desc = "다시 태어난 몸에서 바람의 칼이 깨어났다. 발끝이 지나간 자리마다 칼날이 남고, 그 칼날이 모여 하늘까지 닿는 회오리가 된다.",
	gimmick = "칼바람: 대시 두 번, 대시 대기 0.4초, 밀어냄 1.5배, 더 빠르다. 오의 천풍만검: 바람의 칼날 열둘이 몸을 돌다가 사방으로 쏘아지고, 거대한 회오리가 모두 들어 올린다",
	deflect = 0.22, dashCd = 0.4, dashCharges = 2, speed = 1.15, kbMult = 1.5,
	stance = "stance_gale",
	combo = {
		{ id = "pk1", name = "풍인각", pose = "gale_snap", dur = 0.26, lunge = 3, hits = { hit(0.1, 6, 4.5, 9, 8, 0.3, 12) } },
		{ id = "pk2", name = "회선풍각", pose = "gale_hook", dur = 0.34, lunge = 2, hits = { hit(0.16, 6, 5, 10, 9, 0.35, 14) } },
		{ id = "pk3", name = "쌍풍비각", pose = "gale_double", dur = 0.42, lunge = 3, hits = { hit(0.14, 6, 4.5, 8, 7, 0.3, 8, 10), hit(0.28, 6, 5, 10, 9, 0.35, 12, 14) } },
		{ id = "pk4", name = "대선풍", pose = "gale_cyclone", dur = 0.5, lunge = 2, hits = { hit(0.24, 0, 9, 16, 18, 0.5, 36, nil, true) } },
	},
	heavy = { id = "pkH", name = "천풍인", pose = "gale_blast", dur = 0.6, lunge = 0, proj = { speed = 120, life = 0.55, radius = 6, dmg = 26, posture = 26, stun = 0.6, kb = 46 } },
	skills = {
		E = { id = "pkE", name = "질풍만보", desc = "바람처럼 꿰뚫고 지나간다 (무적). 지나간 길의 바람 칼날이 한 박자 뒤 베어 낸다", pose = "gale_dash", dur = 0.45, cd = 6, chi = 15, lunge = 28, iframes = 0.42,
			hits = { hit(0.15, 6, 4.5, 14, 12, 0.4, 22) },
			mech = { kind = "trail", delay = 0.4, count = 5, radius = 7, hit = hit(0, 0, 0, 18, 14, 0.4, 18, 10) } },
		R = { id = "pkR", name = "칼바람 회오리", desc = "앞에 칼바람 회오리를 2.5초 세운다. 둘레의 적을 빨아들이며 계속 벤다", pose = "gale_spin", dur = 0.9, cd = 11, chi = 25,
			mech = { kind = "zone", dist = 9, radius = 13, dur = 2.5, every = 0.25, delay = 0.3, pull = 30, hit = hit(0, 0, 0, 7, 9, 0.3, 0), fx = "wind" } },
		G = { id = "pkG", name = "천풍만검", desc = "바람의 칼날 열둘이 몸을 감아 돌며 둘레를 베고, 사방으로 쏘아진다. 마지막에 앞에서 하늘까지 닿는 회오리가 모두 들어 올려 내던진다", pose = "ult_gale", dur = 1.8, cd = 30, chi = 100, armor = true,
			mech = { kind = "galeBlades", blades = 12, orbit = 9, spin = 1.2, every = 0.2, delay = 0.3, hit = hit(0, 0, 0, 12, 10, 0.3, 6), range = 24, shoot = hit(0, 0, 0, 34, 30, 0.6, 30, 10), finalRadius = 16, final = hit(0, 0, 0, 90, 110, 1.3, 40, 60) } },
	},
})
-- 2.7판 진 무극신권 (각성): 먹과 붓의 권. 허공에 획을 긋고, 땅에 원을 그리고, 하늘의 붓이 먹의 꽃을 그린다
table.insert(Config.Styles, {
	id = "mugeuk2", name = "진 무극신권", hanja = "眞無極神拳", icon = "🖌", grade = "신화",
	color = Color3.fromRGB(30, 30, 38), color2 = Color3.fromRGB(255, 214, 120), fx = "void",
	awakenOf = "mugeuk", hidden = true, rebirthReq = 1,
	unlockHint = "무극신권을 완전 각성하고 두 번 깨달은 뒤, 한 번 환생한 몸으로 각성 사부를 찾아가 먹으로 그린 자기 그림자를 넘어라",
	desc = "다시 태어난 몸에서 무극이 붓을 들었다. 흑과 백을 넘어, 먹 한 방울에서 모든 것이 그려지고 지워진다. 손끝이 지나간 자리에 먹이 번지고, 먹은 금빛으로 타오른다.",
	gimmick = "먹 번짐: 네 번 맞힐 때마다 상대 발밑에 먹이 번졌다가 금빛으로 터진다. 모든 타격이 균형을 두 배로 깎는다. 오의 무극필: 하늘의 큰 붓이 땅에 먹의 꽃을 그리고, 그림이 금빛으로 타오르며 터진다",
	deflect = 0.32, postureMult = 2,
	pulse = { every = 4, kind = "ink", radius = 10, delay = 0.45, name = "먹 번짐", dmg = 32, posture = 40, stun = 0.7, kb = 10, up = 10 },
	stance = "stance_mugeuk",
	combo = {
		{ id = "mq1", name = "묵장", pose = "void_palm_r", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4.5, 15, 16, 0.35, 10) } },
		{ id = "mq2", name = "획장", pose = "void_palm_l", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4.5, 15, 16, 0.35, 10) } },
		{ id = "mq3", name = "점각", pose = "void_circle", dur = 0.38, lunge = 2, hits = { hit(0.18, 6, 5.5, 18, 22, 0.4, 14) } },
		{ id = "mq4", name = "일필권", pose = "void_push", dur = 0.48, lunge = 3, hits = { hit(0.22, 7, 5.5, 28, 40, 0.6, 40) } },
	},
	heavy = { id = "mqH", name = "낙관", pose = "void_sink", dur = 0.6, lunge = 3, hits = { hit(0.28, 7, 6.5, 40, 70, 0.8, 50, 8, true) } },
	skills = {
		E = { id = "mqE", name = "일획", desc = "팔을 크게 휘둘러 허공에 먹으로 한 획을 긋는다. 앞의 26칸을 가르는 굵은 먹 획이 지나간 적을 베고, 0.5초 뒤 획이 금빛으로 타오르며 한 번 더 터진다", pose = "brush_sweep", dur = 0.5, cd = 7, chi = 18,
			mech = { kind = "inkSlash", length = 26, width = 5, delay = 0.15, hit = hit(0, 0, 0, 24, 34, 0.5, 10), burstAt = 0.5, burst = hit(0, 0, 0, 22, 30, 0.5, 0, 12) } },
		R = { id = "mqR", name = "원상", desc = "붓 끝으로 발밑에 커다란 먹 원을 한 번에 그린다. 원 안의 적은 먹에 붙잡혀 1초 동안 움직이지 못하고, 원이 다 그려지면 먹 벽이 솟았다가 금빛으로 무너진다", pose = "brush_circle", dur = 0.8, cd = 11, chi = 26,
			mech = { kind = "enso", radius = 16, draw = 0.55, hold = 1.0, hit = hit(0, 0, 0, 20, 40, 1.0, 0), burstAt = 0.35, burst = hit(0, 0, 0, 34, 44, 0.6, 30, 14) } },
		G = { id = "mqG", name = "무극필", desc = "하늘에 커다란 붓이 나타나 둘레의 땅에 먹의 꽃을 그린다. 소용돌이치는 획 여덟이 차례로 내리그어질 때마다 그 아래의 적을 베고, 마지막에 둘레에 원을 둘러 그림 전체가 금빛으로 타오르며 터진다", pose = "ult_taiji", dur = 2.2, cd = 30, chi = 100, armor = true,
			mech = { kind = "inkFlower", radius = 22, strokes = 8, delay = 0.35, every = 0.16, width = 5, hit = hit(0, 0, 0, 30, 50, 0.6, 10), ringAt = 0.3, finalAt = 0.45, finalRadius = 26, final = hit(0, 0, 0, 110, 260, 1.2, 50, 22) } },
	},
})

-- 2.9판 진 매화난무권 (각성): 눈 속에 피는 붉은 매화 (설중매). 초·매화(벚꽃 부채)와 달리 가지와 눈과 매화
awakened("maehwa", 1.5, {
	id = "maehwa2", name = "진 매화난무권", hanja = "眞梅花亂舞拳", icon = "❄", grade = "신화",
	color = Color3.fromRGB(215, 30, 60), color2 = Color3.fromRGB(240, 248, 255), fx = "petal",
	rebirthReq = 1, petals = true, petalMax = 20,
	unlockHint = "매화난무권을 완전 각성하고 두 번 깨달은 뒤, 한 번 환생한 몸으로 각성 사부를 찾아가 눈 속에 핀 자기 그림자를 넘어라",
	desc = "다시 태어난 몸에서 한겨울의 매화가 피었다. 눈이 쌓일수록 붉게 피는 설중매처럼, 손끝이 지나간 자리마다 매화 가지가 뻗고 눈 속에서 꽃이 터진다.",
	gimmick = "설중매: 다섯 번 맞힐 때마다 상대 발밑에 매화 가지가 뻗어 꽃이 피고 터진다 (눈에 덮여 잠깐 굼뜨다). 꽃잎이 차면 강타가 만개. 오의 설중매화: 둘레에 눈이 내리며 붉은 꽃잎이 휘몰아치고, 하늘에 거대한 매화가 피어 꽃잎이 쏟아진다",
	deflect = 0.24, speed = 1.2,
	pulse = { every = 5, kind = "plum", radius = 10, delay = 0.35, name = "설중매", dmg = 26, posture = 28, stun = 0.6, kb = 8, up = 8 },
	skills = {
		E = { id = "mxE", name = "설중매", desc = "앞으로 손을 뻗으면 땅을 따라 매화 가지가 24칸 뻗는다. 마디마다 차례로 꽃이 피며 베고, 잠시 뒤 가지 전체의 꽃이 한꺼번에 터진다", pose = "plum_flash", dur = 0.55, cd = 7, chi = 18, lunge = 4,
			mech = { kind = "plumBranch", length = 24, nodes = 6, delay = 0.15, step = 0.08, radius = 5.5, hit = hit(0, 0, 0, 18, 20, 0.5, 8), burstAt = 0.45, burst = hit(0, 0, 0, 16, 18, 0.4, 0, 10) } },
		R = { id = "mxR", name = "한매오판", desc = "둘레 다섯 곳에 커다란 매화가 핀다. 꽃이 둘레의 적을 꽃술로 끌어당긴 뒤 눈보라와 함께 터진다 (맞은 적은 1초 굼뜨다)", pose = "petal_spin", dur = 0.8, cd = 11, chi = 25,
			mech = { kind = "plumRing", radius = 13, flowers = 5, delay = 0.3, pull = 26, hold = 0.6, every = 0.2, hit = hit(0, 0, 0, 10, 12, 0.3, 0), burst = hit(0, 0, 0, 30, 34, 0.7, 30, 14), slow = 1 } },
		G = { id = "mxG", name = "설중매화", desc = "둘레에 2초 동안 함박눈이 내리며 붉은 꽃잎이 휘몰아쳐 계속 벤다. 마지막에 하늘에 거대한 매화가 피어 꽃잎이 비처럼 쏟아진다", pose = "ult_bloom", dur = 2.4, cd = 30, chi = 100, armor = true,
			mech = { kind = "plumSnow", radius = 24, dur = 2.0, every = 0.25, delay = 0.3, hit = hit(0, 0, 0, 9, 10, 0.3, 0), finalRadius = 26, final = hit(0, 0, 0, 110, 140, 1.3, 40, 30) } },
	},
})
-- 2.9판 진 취팔선권 (각성): 술 취한 신선. 달빛 아래 호리병을 든 취선. 초·취(소주병 난타)와 달리 술의 강과 여덟 신선
awakened("chwi", 1.5, {
	id = "chwi2", name = "진 취팔선권", hanja = "眞醉八仙拳", icon = "🏺", grade = "신화",
	color = Color3.fromRGB(200, 120, 255), color2 = Color3.fromRGB(255, 225, 150), fx = "drunk",
	rebirthReq = 1, dodgeChance = 0.3, weakBlock = 1.4,
	unlockHint = "취팔선권을 완전 각성하고 두 번 깨달은 뒤, 한 번 환생한 몸으로 각성 사부를 찾아가 술에 취한 자기 그림자를 넘어라",
	desc = "다시 태어난 몸에 여덟 신선이 함께 취했다. 호리병의 술이 강이 되어 흐르고, 비틀거리는 걸음 하나하나가 신선의 걸음이 된다.",
	gimmick = "취선: 30% 확률로 공격을 저절로 피한다. 네 번 맞힐 때마다 상대 자리에서 술이 튀어 어지럽힌다. 오의 팔선강림: 여덟 신선의 그림자가 둘레에 나타나 차례로 덮치고, 하늘에서 거대한 호리병이 내리꽂힌다",
	deflect = 0.22,
	pulse = { every = 4, kind = "wine", radius = 9, delay = 0.25, name = "술 튐", dmg = 22, posture = 26, stun = 0.8, kb = 10, up = 6 },
	skills = {
		E = { id = "cxE", name = "취월삼보", desc = "비틀비틀 세 걸음, 좌우로 크게 휘청이며 9칸씩 뛰어든다 (무적). 내려설 때마다 둘레를 걷어찬다", pose = "drunk_low", dur = 0.7, cd = 7, chi = 18, iframes = 0.6,
			mech = { kind = "drunkZig", hops = 3, dist = 9, every = 0.18, radius = 7, hit = hit(0, 0, 0, 16, 16, 0.5, 20, 8) } },
		R = { id = "cxR", name = "주천강", desc = "호리병을 기울여 앞으로 술의 강을 쏟는다. 2초 동안 강 위의 적은 굼뜨고 젖어 들며, 마지막에 강에 불이 붙어 한꺼번에 타오른다", pose = "soju_spray", dur = 0.8, cd = 11, chi = 25,
			mech = { kind = "wineRiver", length = 26, width = 6, dur = 2.0, every = 0.3, delay = 0.25, hit = hit(0, 0, 0, 7, 8, 0.25, 0), burst = hit(0, 0, 0, 30, 30, 0.6, 10, 12) } },
		G = { id = "cxG", name = "팔선강림", desc = "여덟 신선의 그림자가 둘레에 나타나 차례로 가까운 적에게 덮쳐 든다. 마지막에 하늘에서 거대한 호리병이 내리꽂혀 술 물결이 사방으로 터진다", pose = "drunk_sway", dur = 2.4, cd = 30, chi = 100, armor = true,
			mech = { kind = "eightImmortals", n = 8, radius = 12, delay = 0.35, every = 0.18, range = 30, hit = hit(0, 0, 0, 30, 30, 0.6, 20, 10), finalAt = 0.45, finalRadius = 18, final = hit(0, 0, 0, 110, 130, 1.3, 50, 25) } },
	},
})

------------------------------------------------------------------------
-- 2.0판: 각성 오의 여섯을 새로 (원래 오의를 키운 것이 아니라, 전혀 다른 장치로)
------------------------------------------------------------------------
do
	local NEW_G: { [string]: any } = {
		hyeolma2 = { id = "vhmG", name = "혈해만마", desc = "발밑이 피의 바다가 된다. 피에서 마수의 손톱이 열두 번 솟아 적들을 찢고 (찢을 때마다 체력이 돌아온다), 마지막에 바다가 핏빛 소용돌이 기둥으로 솟아 터진다. 그 뒤 10초 광란", pose = "ult_blood", dur = 1.8, cd = 30, chi = 100, armor = true, buff = { kind = "frenzy", dur = 10 },
			mech = { kind = "bloodSea", radius = 26, delay = 0.45, claws = 12, every = 0.18, clawRadius = 7, heal = 0.006, hit = hit(0, 0, 0, 26, 24, 0.6, 10, 18), final = hit(0, 0, 0, 110, 140, 1.4, 50, 30) } },
		cheonryong2 = { id = "vcrG", name = "구룡승천", desc = "땅을 뚫고 금룡 아홉이 둘레에서 솟아 하늘로 감아 오른다. 하늘을 돈 용들이 적들에게 하나씩 내리꽂히고, 마지막에 한가운데로 모여 터진다", pose = "ult_dragon", dur = 1.8, cd = 30, chi = 100, armor = true,
			mech = { kind = "nineDragons", n = 9, ringRadius = 14, rise = 1.1, riseHit = hit(0, 0, 0, 24, 24, 0.6, 10, 30), range = 40, dives = 9, every = 0.13, diveRadius = 8, hit = hit(0, 0, 0, 30, 28, 0.7, 20, -6), finalRadius = 22, final = hit(0, 0, 0, 100, 130, 1.4, 60, 24) } },
		byeokryeok2 = { id = "vbkG", name = "뇌정천망", desc = "둘레의 적 열을 보랏빛 번개 그물로 모두 잇는다. 그물이 다섯 번 고동치며 묶인 적을 지지고, 마지막에 적마다 천뢰가 떨어진다", pose = "ult_thunder", dur = 1.8, cd = 30, chi = 100, armor = true,
			mech = { kind = "thunderNet", range = 34, n = 10, delay = 0.4, pulses = 5, every = 0.36, hit = hit(0, 0, 0, 16, 16, 0.4, 0), finalRadius = 8, final = hit(0, 0, 0, 70, 90, 1.2, 30, 20) } },
		geumgang2 = { id = "gkG", name = "천수여래", desc = "등 뒤로 팔이 여럿 달린 거대한 금빛 여래가 솟아 적들을 차례로 여덟 번 내리친다. 마지막에 하늘이 갈라지며 산만 한 손바닥이 땅을 누른다", pose = "ult_buddha", dur = 1.8, cd = 30, chi = 100, armor = true,
			mech = { kind = "thousandArms", range = 34, count = 8, delay = 0.7, every = 0.2, armRadius = 8, hit = hit(0, 0, 0, 28, 34, 0.7, 20, -8), radius = 26, palmDelay = 0.9, final = hit(0, 0, 0, 110, 150, 1.6, 10, -10) } },
		muyeong2 = { id = "mkG", name = "무영천살", desc = "세상이 어두워지고 몸이 사라진다. 적들의 몸에 붉은 표식이 하나씩 새겨지고, 빛이 돌아오는 순간 모두 한꺼번에 터진다. 마지막에 하늘에서 그림자의 발이 짓밟는다 (그동안 무적)", pose = "ult_shadow", dur = 1.8, cd = 30, chi = 100, armor = true,
			mech = { kind = "shadowKill", range = 36, n = 10, delay = 0.4, every = 0.12, hold = 0.5, hit = hit(0, 0, 0, 60, 60, 1.0, 20, 30), finalRadius = 20, final = hit(0, 0, 0, 80, 110, 1.3, 40, -10) } },
		taeheo2 = { id = "tkG", name = "창해만류", desc = "발밑에 거대한 소용돌이가 일어 적들을 가운데로 빨아들인다. 둘레에 물의 벽이 높이 솟았다가, 마지막에 안쪽으로 한꺼번에 무너져 내린다", pose = "ult_tide", dur = 1.6, cd = 30, chi = 100, armor = true,
			mech = { kind = "maelstrom", radius = 24, dur = 2.4, every = 0.24, delay = 0.3, pull = 34, hit = hit(0, 0, 0, 8, 12, 0.3, 0), final = hit(0, 0, 0, 110, 140, 1.4, 60, 30) } },
	}
	for _, st in ipairs(Config.Styles) do
		local g = NEW_G[st.id]
		if g then
			st.skills.G = g
			st.gimmick = string.gsub(st.gimmick, "진 혈마강림: .*$", "진 오의 혈해만마: 피의 바다에서 마수의 손톱이 열두 번 솟는다")
			st.gimmick = string.gsub(st.gimmick, "진 진룡강림: .*$", "진 오의 구룡승천: 금룡 아홉이 솟아 하늘을 돌고 내리꽂힌다")
			st.gimmick = string.gsub(st.gimmick, "진 뇌신화: .*$", "진 오의 뇌정천망: 번개 그물이 적들을 모두 잇는다")
			st.gimmick = string.gsub(st.gimmick, "오의 만불조종: .*$", "오의 천수여래: 팔이 여럿 달린 금빛 여래가 내리치고 하늘의 손바닥이 누른다")
			st.gimmick = string.gsub(st.gimmick, "오의 백귀야행: .*$", "오의 무영천살: 어둠 속에서 적마다 표식이 새겨지고 한꺼번에 터진다")
			st.gimmick = string.gsub(st.gimmick, "오의 천하수류: .*$", "오의 창해만류: 소용돌이가 빨아들이고 물의 벽이 무너진다")
		end
	end
end

------------------------------------------------------------------------
-- 2.2판: 각성 권법 아홉의 E·R을 모두 새 장치로 (원래 권법과도, 서로와도 겹치지 않게)
-- 진 열화·진 창해의 오의, 초·벽력신권의 R·오의도 새로 (용 오의 셋, 소용돌이 오의 둘, 벼락 비 둘이 겹쳤다)
------------------------------------------------------------------------
do
	local NEW: { [string]: { [string]: any } } = {
		hyeolma2 = {
			E = { id = "vhmE2", name = "혈침", desc = "손톱 끝의 피를 바늘로 날려 둘레의 적 넷에게 꽂는다. 1초 뒤 바늘이 몸속에서 터지고, 터진 만큼 체력을 빨아온다", pose = "blood_phantom", dur = 0.45, cd = 8, chi = 20,
				mech = { kind = "bloodNeedles", n = 4, range = 30, delay = 0.2, mark = 1.0, radius = 5, heal = 0.012, hit = hit(0, 0, 0, 14, 10, 0.3, 0), burst = hit(0, 0, 0, 40, 34, 0.7, 14, 8) } },
			R = { id = "vhmR2", name = "혈마수인", desc = "앞의 땅에서 거대한 피의 손이 솟아 둘레의 적을 움켜쥔다. 세 번 쥐어짜고, 마지막에 땅에 내리꽂는다", pose = "blood_spread", dur = 0.9, cd = 12, chi = 25,
				mech = { kind = "bloodGrip", dist = 10, radius = 10, delay = 0.35, squeezes = 3, every = 0.3, hit = hit(0, 0, 0, 16, 16, 0.4, 0), squeeze = hit(0, 0, 0, 14, 16, 0.3, 0), final = hit(0, 0, 0, 52, 60, 1.0, 10, -20) } },
		},
		cheonryong2 = {
			E = { id = "vcrE2", name = "용음", desc = "금룡의 울음을 앞으로 토해낸다. 부채꼴 안의 적이 멀리 날아가고 1초 동안 몸이 굳는다 (막을 수 없다)", pose = "dragon_coil", dur = 0.55, cd = 8, chi = 20,
				mech = { kind = "dragonRoar", range = 22, angle = 80, delay = 0.22, stun = 1.0, hit = hit(0, 0, 0, 26, 40, 0.6, 70, 10, true) } },
			R = { id = "vcrR2", name = "항룡장", desc = "금룡의 머리 모양 장력이 앞으로 길게 뻗어 나가며 닿는 적을 모두 꿰뚫고, 끝에서 터진다", pose = "dragon_rise", dur = 0.7, cd = 10, chi = 25,
				mech = { kind = "dragonPalm", delay = 0.2, length = 34, speed = 70, width = 5, hit = hit(0, 0, 0, 34, 34, 0.6, 40), finalRadius = 10, final = hit(0, 0, 0, 40, 40, 0.8, 30, 20) } },
		},
		byeokryeok2 = {
			E = { id = "vbkE2", name = "뇌인진", desc = "땅을 내리쳐 둘레 네 곳에 보랏빛 뇌인을 새긴다. 2.6초 동안 적이 밟으면 벼락이 떨어지고 (뇌인마다 두 번), 끝에 모두 터진다", pose = "thunder_hammer", dur = 0.5, cd = 9, chi = 20,
				mech = { kind = "sigils", n = 4, dist = 9, radius = 4, dur = 2.6, every = 0.2, delay = 0.25, charges = 2, hit = hit(0, 0, 0, 22, 20, 0.6, 6), finalRadius = 7, final = hit(0, 0, 0, 30, 30, 0.7, 20, 10) } },
			R = { id = "vbkR2", name = "섬뢰포", desc = "주먹에 뇌전을 모았다가 앞으로 곧게 쏜다. 한 줄의 적을 모두 꿰뚫고, 지나간 줄이 1.2초 동안 지지직 지진다", pose = "thunder_jab", dur = 0.8, cd = 11, chi = 25,
				mech = { kind = "railBeam", delay = 0.4, length = 40, width = 3.2, linger = 1.2, every = 0.3, hit = hit(0, 0, 0, 50, 46, 0.8, 30), tick = hit(0, 0, 0, 8, 8, 0.2, 0) } },
		},
		geumgang2 = {
			E = { id = "gkE2", name = "금강종", desc = "하늘에서 금빛 큰 종이 떨어져 몸을 덮는다 (1.4초 무적). 종이 세 번 울릴 때마다 둘레를 밀어내고, 마지막 울림이 가장 크다", pose = "brace", dur = 0.6, cd = 11, chi = 25,
				mech = { kind = "goldenBell", dur = 1.4, rings = 3, every = 0.45, delay = 0.35, radius = 10, hit = hit(0, 0, 0, 18, 26, 0.5, 30), final = hit(0, 0, 0, 40, 50, 1.0, 50, 10) } },
			R = { id = "gkR2", name = "항마저", desc = "금강저를 던진다. 앞으로 날아갔다가 손으로 되돌아오며, 가는 길과 오는 길에 한 번씩 친다", pose = "grav_hammer", dur = 0.7, cd = 10, chi = 25,
				mech = { kind = "vajra", delay = 0.25, dist = 26, time = 0.45, radius = 5, hit = hit(0, 0, 0, 30, 34, 0.6, 24) } },
		},
		muyeong2 = {
			E = { id = "mkE2", name = "분영", desc = "양옆에 그림자 분신 둘이 떨어져 나와, 저마다 가까운 적에게 세 번 덮쳐 찬다", pose = "shadow_heel", dur = 0.5, cd = 9, chi = 20,
				mech = { kind = "shadowClones", side = 6, delay = 0.35, waves = 3, every = 0.35, range = 22, radius = 6, hit = hit(0, 0, 0, 20, 18, 0.5, 20, 8) } },
			R = { id = "mkR2", name = "그림자 밟기", desc = "내 그림자만 앞으로 미끄러져 나가며 밟은 적의 그림자를 땅에 꿰맨다 (1.6초 묶임). 그림자 끝으로 몸이 옮겨 가 되돌아 걷어찬다", pose = "point_sky", dur = 0.7, cd = 11, chi = 25,
				mech = { kind = "shadowStep", dist = 24, slide = 0.45, width = 4, pin = 1.6, hit = hit(0, 0, 0, 14, 16, 0.4, 0), final = hit(0, 0, 0, 48, 50, 1.0, 40, 16) } },
		},
		taeheo2 = {
			E = { id = "tkE2", name = "회류환", desc = "물방울 셋이 3초 동안 몸을 감아 돌며 닿는 적을 친다. 끝에 물결로 퍼진다", pose = "push_palm", dur = 0.5, cd = 10, chi = 20,
				mech = { kind = "waterOrbit", n = 3, radius = 8, dur = 3, every = 0.15, gap = 0.45, hit = hit(0, 0, 0, 12, 16, 0.3, 14), final = hit(0, 0, 0, 30, 40, 0.7, 40, 10) } },
			R = { id = "tkR2", name = "간헐천", desc = "가까운 적 여섯의 발밑에서 차례로 뜨거운 물기둥이 솟아 하늘로 쳐올린다", pose = "water_spiral", dur = 0.8, cd = 11, chi = 25,
				mech = { kind = "geysers", n = 6, range = 28, delay = 0.3, every = 0.14, radius = 5, hit = hit(0, 0, 0, 30, 30, 0.9, 0, 48) } },
		},
		yeolhwa2 = {
			E = { id = "ykE2", name = "화륜", desc = "불의 바퀴를 앞으로 굴린다. 닿는 적을 치고, 바퀴가 지나간 길이 2초 동안 불탄다", pose = "blaze_punch", dur = 0.45, cd = 8, chi = 20,
				mech = { kind = "fireWheel", dist = 36, time = 0.8, radius = 4.5, trail = 3, burn = 2.0, every = 0.4, hit = hit(0, 0, 0, 26, 22, 0.5, 24, 10), tick = hit(0, 0, 0, 6, 4, 0.1, 0) } },
			R = { id = "ykR2", name = "폭염륜", desc = "솟구쳤다가 내려앉으며 둘레로 불의 고리를 퍼뜨린다. 고리가 지나가는 순간 맞는다", pose = "blaze_hammer", dur = 0.9, cd = 10, chi = 25, jump = 26,
				mech = { kind = "flameRing", delay = 0.5, radius = 20, expand = 0.55, hit = hit(0, 0, 0, 40, 36, 0.7, 40, 14) } },
			G = { id = "ykG2", name = "화산천붕", desc = "앞의 땅이 부풀어 오른다. 적의 발밑마다 용암이 뿜어지고, 한가운데에서 화산이 터져 불덩이 열 개가 쏟아진다", pose = "ult_volcano", dur = 1.8, cd = 30, chi = 100, armor = true,
				mech = { kind = "volcano", dist = 8, radius = 26, range = 34, delay = 0.4, vents = 8, every = 0.12, ventRadius = 6, hit = hit(0, 0, 0, 30, 30, 0.6, 10, 30), mainDelay = 0.35, mainRadius = 16, main = hit(0, 0, 0, 100, 130, 1.3, 50, 30), meteors = 10, meteorEvery = 0.13, meteorRadius = 6, meteor = hit(0, 0, 0, 26, 24, 0.5, 16, 8) } },
		},
		changhae2 = {
			E = { id = "cyE2", name = "수포옥", desc = "가까운 적 셋을 물방울 감옥에 가둬 띄운다. 1.6초 동안 지지고, 끝에 펑 터진다", pose = "push_palm", dur = 0.5, cd = 9, chi = 20,
				mech = { kind = "bubbles", n = 3, range = 26, delay = 0.25, dur = 1.6, every = 0.4, radius = 7, hit = hit(0, 0, 0, 10, 10, 0.3, 0), tick = hit(0, 0, 0, 8, 10, 0.2, 0), final = hit(0, 0, 0, 40, 40, 0.8, 30, 26) } },
			R = { id = "cyR2", name = "해룡창", desc = "하늘에서 물의 창 일곱이 적들에게 차례로 내리꽂힌다 (적이 없으면 앞으로 한 줄)", pose = "point_sky", dur = 0.8, cd = 10, chi = 25,
				mech = { kind = "waterSpears", count = 7, range = 30, start = 5, spacing = 4.5, delay = 0.3, every = 0.08, radius = 4.5, hit = hit(0, 0, 0, 30, 30, 0.6, 10, -8) } },
			G = { id = "cyG2", name = "고래강림", desc = "발밑에서 거대한 물의 고래가 솟구쳐 앞으로 크게 뛰어오른다. 고래가 땅을 덮치며 떨어지는 자리의 적은 모두 짓눌린다", pose = "ult_tsunami", dur = 1.8, cd = 30, chi = 100, armor = true,
				mech = { kind = "whaleBreach", dist = 30, delay = 0.35, flight = 1.3, launchRadius = 12, launch = hit(0, 0, 0, 40, 40, 0.8, 10, 50), radius = 20, hit = hit(0, 0, 0, 20, 20, 0.4, 10, 10), final = hit(0, 0, 0, 120, 150, 1.4, 60, 20) } },
		},
		pungsin2 = {
			E = { id = "pkE2", name = "회풍", desc = "작은 회오리를 풀어 놓는다. 3초 동안 가까운 적을 쫓아다니며 들어 올리고, 끝에 흩어지며 친다", pose = "gale_spin", dur = 0.5, cd = 9, chi = 20,
				mech = { kind = "wanderTornado", radius = 5, seek = 30, speed = 20, dur = 3, every = 0.1, gap = 0.35, hit = hit(0, 0, 0, 10, 10, 0.3, 0, 22), final = hit(0, 0, 0, 30, 30, 0.6, 30, 30) } },
			R = { id = "pkR2", name = "풍압", desc = "솟구친 뒤 하늘의 바람을 끌어내린다. 둘레의 적을 가운데로 빨아들여 땅에 짓누른다 (1.2초 기절)", pose = "gale_spin", dur = 0.9, cd = 11, chi = 25, jump = 30,
				mech = { kind = "downdraft", delay = 0.55, radius = 15, stun = 1.2, hit = hit(0, 0, 0, 40, 46, 0.8, 0, -30) } },
		},
	}
	for _, st in ipairs(Config.Styles) do
		local n = NEW[st.id]
		if n then
			for slot, sk in pairs(n) do
				st.skills[slot] = sk
			end
			st.gimmick = string.gsub(st.gimmick, "오의 화룡천멸: .*$", "오의 화산천붕: 적의 발밑마다 용암이 뿜어지고, 화산이 터져 불덩이가 쏟아진다")
			st.gimmick = string.gsub(st.gimmick, "오의 심해강림: .*$", "오의 고래강림: 거대한 물의 고래가 솟구쳤다가 땅을 덮친다")
		end
	end
end

-- 모든 기술을 한 치수 크게 (장치의 반경·범위, 기술 타격의 반경), 맨 타격뿐인 E·R에는 마지막 충격파를 더한다
Config.SKILL_SCALE = 1.25
local RADIUS_KEYS = { radius = true, finalRadius = true, bigRadius = true, geyserRadius = true, outer = true, width = true }
local function widen(t: any, k: number)
	for key, v in pairs(t) do
		if type(v) == "number" and RADIUS_KEYS[key] then
			t[key] = v * k
		elseif key == "range" and type(v) == "number" then
			t[key] = v * (1 + (k - 1) * 0.6)
		end
	end
	for _, st in ipairs(t.strikes or {}) do
		widen(st, k)
	end
end
for _, st in ipairs(Config.Styles) do
	for slot, sk in pairs(st.skills) do
		if sk.mech then
			widen(sk.mech, Config.SKILL_SCALE)
		end
		for _, h in ipairs(sk.hits or {}) do
			h.radius *= 1.15
			h.range *= 1.1
		end
		if sk.proj then
			sk.proj.radius *= 1.2
			sk.proj.size = (sk.proj.size or 3) * 1.3
		end
		-- 허술한 기술 보완: 장치도 장풍도 없는 E·R은 마지막 타격 뒤에 앞쪽으로 충격파가 터진다
		if slot ~= "G" and not sk.mech and not sk.proj and not sk.buff and not sk.counter and sk.hits and #sk.hits > 0 then
			local last = sk.hits[#sk.hits]
			local far = (sk.lunge and sk.lunge >= 12) or sk.teleport ~= nil
			sk.mech = { kind = "shock", delay = last.t + 0.06, dist = 4, radius = far and 11 or 9, hit = hit(0, 0, 0, last.dmg * 0.7 + 6, last.posture * 0.6 + 6, 0.5, 18, 6) }
			sk.desc ..= ". 마지막에 충격파가 둘레를 친다"
		end
	end
end

-- 3.5판 권법 등급: 다섯 단계 (상급 · 전설 · 신화 · 태초 · 윤회). 지존은 나중에 새 권법이 나오면 쓰려고 비워 둔다.
-- 진 (각성) · 초 · 극은 등급이 아니라 권법이 변한 모습이라 예전 그대로 둔다 (진 = 신화, 초 = 초월, 극 = 극).
-- 모습의 한계: 상급·전설 권법은 초 신권까지, 신화 이상 권법은 초와 극까지 변할 수 있다 (FORM_LIMIT)
Config.GRADE_ORDER = { "상급", "전설", "신화", "태초", "지존", "윤회", "초월", "권왕", "극" }
Config.GRADES = { ["상급"] = 1.0, ["전설"] = 1.5, ["신화"] = 1.8, ["태초"] = 2.5, ["지존"] = 2.75, ["윤회"] = 3.0, ["초월"] = 3.1, ["권왕"] = 3.4, ["극"] = 3.8 }
Config.GRADE_COLOR = {
	["상급"] = Color3.fromRGB(120, 190, 255),
	["전설"] = Color3.fromRGB(255, 200, 80),
	["신화"] = Color3.fromRGB(255, 120, 90),
	["태초"] = Color3.fromRGB(190, 225, 255),
	["지존"] = Color3.fromRGB(255, 200, 90),
	["윤회"] = Color3.fromRGB(170, 140, 255),
	["초월"] = Color3.fromRGB(255, 160, 210),
	["권왕"] = Color3.fromRGB(255, 70, 70),
	["극"] = Color3.fromRGB(255, 140, 90),
}
Config.FORM_LIMIT = { ["상급"] = "초", ["전설"] = "초", ["신화"] = "극", ["태초"] = "극", ["지존"] = "극", ["윤회"] = "극" }
-- 예전 열네 등급 → 다섯 등급 (진·초·극은 그대로)
local GRADE_REMAP = { ["하급"] = "상급", ["중급"] = "상급", ["상급"] = "상급", ["최상급"] = "전설", ["절세"] = "전설", ["전설"] = "전설", ["신화"] = "신화", ["천외천"] = "신화", ["태초"] = "태초", ["지존"] = "태초", ["윤회"] = "윤회", ["권왕"] = "윤회" }
-- 예전 등급 순위 (동작 빠르기·배틀그라운드 몫은 예전 열네 칸 그대로 센다)
local OLD_RANK = { ["하급"] = 1, ["중급"] = 2, ["상급"] = 3, ["최상급"] = 4, ["절세"] = 5, ["전설"] = 6, ["신화"] = 7, ["천외천"] = 8, ["태초"] = 9, ["지존"] = 10, ["윤회"] = 11, ["초월"] = 12, ["권왕"] = 13, ["극"] = 14 }
-- (등급 다시 매기기는 모든 권법이 들어온 뒤, STYLE_BY_ID 바로 앞에서 한다)
function Config.gradeIndex(name: string): number
	return table.find(Config.GRADE_ORDER, name) or 1
end
-- 권법 승급 (깨달음): 숙련 10인 권법을 한 단계씩 끌어올린다 (두 번까지). 경지와 은자가 든다
Config.BREAKTHROUGH = {
	{ realm = 3, coins = 3000, name = "1차 깨달음" },
	{ realm = 7, coins = 20000, name = "2차 깨달음" },
}
-- 그 권법의 등급 (3.5판: 깨달음은 등급을 바꾸지 않고 피해를 올린다)
function Config.styleGrade(style: any, _up: number?): string
	return style.grade
end
-- 깨달음 한 번에 오르는 피해 (예전 등급 두 칸과 비슷하게). 신화는 예전처럼 한 칸만, 태초 이상과 초·극은 오르지 않는다
local BREAK_BONUS = { ["상급"] = { 0.13, 0.26 }, ["전설"] = { 0.13, 0.26 }, ["신화"] = { 0.17, 0.17 } }
function Config.gradeMult(style: any, up: number?): number
	local base = Config.GRADES[style.grade] or 1
	local b = BREAK_BONUS[style.grade]
	local u = math.clamp(math.floor(up or 0), 0, 2)
	return base * (1 + ((b and u > 0) and b[u] or 0))
end
-- 빠르기 순위: 예전 열네 칸 순위 + 깨달음 (예전처럼 천외천 칸까지, 태초 이상과 초·극은 그대로)
function Config.gradeRank(style: any, up: number?): number
	local r = style.rank or 1
	if r >= OLD_RANK["태초"] then
		return r
	end
	return math.min(OLD_RANK["천외천"], r + math.clamp(math.floor(up or 0), 0, 2))
end
-- 등급이 높을수록 조금씩 빠르다: 한 칸마다 동작 +2.5%, 걸음 +1.5%
function Config.gradeSpeed(style: any, up: number?): number
	-- 배틀그라운드: 등급이 높아도 아주 조금만 빠르다 (극이 하급보다 약 10%)
	local k = Config.BATTLE_MODE and 0.008 or 0.025
	return 1 + k * (Config.gradeRank(style, up) - 1)
end
function Config.gradeWalk(style: any, up: number?): number
	return 1 + 0.015 * (Config.gradeRank(style, up) - 1)
end
-- 기술 동작 속도 (권법 고유 빠르기 × 등급 × 혈마 광란)
function Config.actSpeed(style: any, up: number?, frenzy: boolean?): number
	return (style.speed or 1) * Config.gradeSpeed(style, up) * (frenzy and 1.2 or 1)
end
------------------------------------------------------------------------
-- 1.5판: 초월 권법. 기존 권법을 넘어선 권법으로, 모든 기술이 새로 짜였고 오의(G) 위에 초 오의(X)가 하나 더 있다
-- 초·매화난무권: 두 손에 벚꽃 부채. 모든 기술을 벚꽃 칼바람이 따라 인다
------------------------------------------------------------------------
table.insert(Config.Styles, {
	id = "chomaehwa",
	name = "초·매화난무권",
	hanja = "超梅花亂舞拳",
	icon = "🌸",
	grade = "초월",
	transcend = true,
	color = Color3.fromRGB(255, 138, 192),
	color2 = Color3.fromRGB(255, 238, 247),
	fx = "petal",
	fans = true, -- 두 손에 벚꽃 부채 (화면이 그린다)
	petals = true, -- 매화난무권의 꽃잎 쌓기를 이어받는다 (더 많이, 더 크게)
	petalMax = 30,
	hidden = true,
	secret = true,
	realmReq = 16,
	styleReq = "maehwa",
	trialHp = 10,
	unlockHint = "매화난무권을 익히고 천외천에 오른 자만이, 매화원 가장 깊은 벚꽃 언덕의 천앵선을 만난다",
	desc = "매화난무권을 넘어선 권법. 두 손의 벚꽃 부채가 펼쳐질 때마다 꽃잎이 칼날이 되어 흩날린다. 꽃은 지는 순간이 가장 아름답다.",
	gimmick = "벚꽃: 1.2초 안에 계속 맞히면 꽃잎이 쌓인다 (최대 30). 다 차면 Z가 천앵만개로 크게 터진다. 오의 위에 초 오의(X)가 있다",
	deflect = 0.25,
	speed = 1.25,
	stance = "stance_sakura",
	combo = {
		{ id = "cm1", name = "앵선일섬", pose = "fan_slash_r", dur = 0.26, lunge = 3, hits = { hit(0.1, 6, 5, 8, 7, 0.3, 5) } },
		{ id = "cm2", name = "앵선이섬", pose = "fan_slash_l", dur = 0.26, lunge = 3, hits = { hit(0.1, 6, 5, 8, 7, 0.3, 5) } },
		{ id = "cm3", name = "화선회", pose = "fan_twirl", dur = 0.36, lunge = 2, hits = { hit(0.12, 4, 7, 6, 6, 0.3, 6, nil, true), hit(0.26, 4, 7, 6, 6, 0.3, 6, nil, true) } },
		{ id = "cm4", name = "낙앵선퇴", pose = "fan_kick", dur = 0.44, lunge = 3, hits = { hit(0.2, 7, 6, 13, 14, 0.5, 26) } },
	},
	heavy = { id = "cmH", name = "천앵일섬", pose = "fan_dash", dur = 0.5, lunge = 18, iframes = 0.25, hits = { hit(0.2, 8, 5.5, 20, 20, 0.55, 18) }, bloom = { radius = 18, dmg = 55, posture = 60 } },
	skills = {
		-- 2.7판: 초 오의를 뺀 기술을 새로 (부채가 날아가고, 꽃 그림자가 베고, 하늘의 큰 부채가 쓸어 낸다)
		E = { id = "cmE", name = "선풍낙화", desc = "두 부채를 펼쳐 양옆으로 던진다. 부채는 꽃잎을 흘리며 둥글게 앞으로 날아갔다 되돌아오고, 지나는 길의 적을 오갈 때 한 번씩 벤다", pose = "fan_twirl", dur = 0.5, cd = 8, chi = 20,
			mech = { kind = "fanBoomerang", dist = 24, width = 9, time = 1.0, every = 0.08, radius = 4.8, hit = hit(0, 0, 0, 20, 16, 0.35, 8) } },
		R = { id = "cmR", name = "화영보", desc = "꽃잎이 되어 앞으로 미끄러진다 (무적). 지나간 길에 꽃 그림자 셋이 남아 차례로 부채를 휘두르고, 마지막에 모두 꽃잎으로 터진다", pose = "sakura_step", dur = 0.5, cd = 10, chi = 25, lunge = 22, iframes = 0.4,
			mech = { kind = "petalShadow", n = 3, gap = 7, delay = 0.25, every = 0.14, radius = 7.5, hit = hit(0, 0, 0, 26, 22, 0.45, 16), burstAt = 0.45, burst = hit(0, 0, 0, 22, 24, 0.5, 20, 10) } },
		G = { id = "cmG", name = "만화천선", desc = "하늘에 커다란 벚꽃 부채가 펼쳐진다. 부채가 앞의 땅을 칼날처럼 두 번 쓸고 지나가고, 마지막에 접히며 탁 소리와 함께 꽃잎 폭풍이 둘레를 휘감는다", pose = "ult_sakura", dur = 2.0, cd = 30, chi = 100, armor = true,
			mech = { kind = "skyFan", open = 0.6, sweeps = 2, sweepTime = 0.55, range = 34, angle = 200, hit = hit(0, 0, 0, 44, 48, 0.8, 30), closeAt = 0.35, closeRadius = 26, final = hit(0, 0, 0, 100, 120, 1.4, 60, 20) } },
		X = { id = "cmX", name = "만앵참월", desc = "초 오의. 보이지 않게 둘레의 적 열을 베고 지나가며 하늘에 칼자국을 남긴다. 세상이 잿빛으로 멈춘 한 박자 뒤, 칼바람이 일어 적들을 휘감고, 마지막에 터지며 화면까지 한칼에 두 동강 낸다 (그동안 무적)", pose = "ult_sever", dur = 1.2, cd = 60, chi = 150, armor = true,
			mech = { kind = "sakuraSever", n = 10, range = 45, delay = 0.25, every = 0.06, still = 0.9, wind = 1.3, windEvery = 0.18, cut = hit(0, 0, 0, 40, 40, 0.8, 0), windHit = hit(0, 0, 0, 9, 10, 0.3, 0), final = hit(0, 0, 0, 170, 200, 1.8, 80, 26), finalRadius = 22 } },
	},
})

------------------------------------------------------------------------
-- 초·취팔선권: 초록 술병을 들고 머리엔 넥타이를 질끈 동여맨 채, 쓰러질 듯 비틀거린다.
-- 막기는 아예 안 되고 (맞는다), 흘리기만 된다. 대신 흘리는 틈이 넓고, 움직이는 동안 저절로 잘 피한다
------------------------------------------------------------------------
table.insert(Config.Styles, {
	id = "chochwi",
	name = "초·취팔선권",
	hanja = "超醉八仙拳",
	icon = "🍾",
	grade = "초월",
	transcend = true,
	color = Color3.fromRGB(70, 200, 110),
	color2 = Color3.fromRGB(215, 255, 225),
	fx = "drunk",
	soju = true, -- 오른손에 초록 술병, 머리엔 넥타이 (화면이 그린다)
	wobble = true, -- 서 있어도 쓰러질 듯 크게 비틀거린다
	noBlock = true, -- 막기가 안 된다. 흘리기만 된다
	hidden = true,
	secret = true,
	realmReq = 16,
	styleReq = "chwi",
	trialHp = 10,
	unlockHint = "취팔선권을 익히고 천외천에 오른 자만이, 취선 주막 남쪽 술독 마루의 만취선을 만난다",
	desc = "취팔선권을 넘어선 권법. 술병 하나와 넥타이 하나로 천하를 비틀거린다. 넘어지는 것처럼 보이는 모든 몸짓이 공격이고, 쓰러지는 순간이 가장 빠르다.",
	gimmick = "만취: 막기가 되지 않는다 (막아도 그대로 맞는다). 대신 흘리기 틈이 넓고, 움직이거나 기술을 쓰는 동안 30% 확률로 저절로 피한다. 오의 위에 초 오의(X)가 있다",
	deflect = 0.32,
	dodgeChance = 0.3,
	speed = 1.2,
	stance = "stance_soju",
	combo = {
		{ id = "cc1", name = "병나발 휘두르기", pose = "soju_swing_r", dur = 0.32, lunge = 3, hits = { hit(0.14, 6, 5, 9, 8, 0.3, 8) } },
		{ id = "cc2", name = "비틀 팔꿈치", pose = "soju_elbow_l", dur = 0.32, lunge = 3, hits = { hit(0.14, 5, 4.5, 9, 8, 0.3, 8) } },
		{ id = "cc3", name = "자빠지며 걷어차기", pose = "soju_fallkick", dur = 0.44, lunge = 2, hits = { hit(0.16, 5, 6, 7, 6, 0.3, 8, nil, true), hit(0.32, 5, 6, 7, 6, 0.3, 10, nil, true) } },
		{ id = "cc4", name = "술병 내려찍기", pose = "soju_smash", dur = 0.5, lunge = 3, hits = { hit(0.26, 6, 6.5, 16, 18, 0.6, 30, nil, true) } },
	},
	heavy = { id = "ccH", name = "취선 몸통박치기", pose = "soju_lurch", dur = 0.55, lunge = 16, iframes = 0.2, hits = { hit(0.28, 7, 6, 22, 24, 0.6, 42) } },
	skills = {
		E = { id = "ccE", name = "취화방사", desc = "술병을 흔들어 입구에 불똥을 튀긴다. 1.6초 동안 앞으로 초록 불길이 뿜어져 나가 부채꼴을 계속 태운다", pose = "soju_spray", dur = 0.7, cd = 10, chi = 25,
			mech = { kind = "cone", range = 20, angle = 60, dur = 1.6, every = 0.2, delay = 0.25, hit = hit(0, 0, 0, 6, 7, 0.2, 4), fx = "soju" } },
		R = { id = "ccR", name = "팔선취보", desc = "쓰러질 듯 여덟 걸음을 갈지자로 내딛는다. 걸음마다 둘레를 후려치고, 그동안 무엇도 맞히지 못한다", pose = "soju_stagger", dur = 0.9, cd = 10, chi = 25,
			mech = { kind = "zigzag", n = 8, step = 4.5, side = 4, every = 0.09, delay = 0.05, radius = 6.5, hit = hit(0, 0, 0, 10, 10, 0.3, 10) } },
		G = { id = "ccG", name = "취몽팔선진", desc = "술병을 하늘 높이 던진다. 병이 깨지며 둘레에 술비가 쏟아져 적을 적시고, 불똥 하나에 온 땅이 초록 불길로 타오르며 여덟 취선의 그림자가 한꺼번에 덮친다", pose = "soju_throw", dur = 1.4, cd = 30, chi = 100, armor = true,
			mech = { kind = "sojuRain", radius = 26, delay = 0.6, rain = 1.6, every = 0.3, slow = 0.5, hit = hit(0, 0, 0, 6, 8, 0.2, 0), ghosts = 8, final = hit(0, 0, 0, 95, 120, 1.4, 55, 22) } },
		X = { id = "ccX", name = "취선만권", desc = "초 오의. 세상이 멈춘 듯한 한순간, 점점 빨라지는 앞구르기로 굴러 들어가 (그동안 무적) 적들에게 와다다다 수백 주먹을 퍼붓고, 마지막에 술병을 깨뜨리며 터뜨린다", pose = "soju_rolls", dur = 3.4, cd = 60, chi = 150, armor = true,
			mech = { kind = "drunkRush", cut = 1.6, roll = 26, rush = 1.8, every = 0.06, hop = 0.45, range = 36, n = 5, reach = 8, hit = hit(0, 0, 0, 4.5, 5, 0.15, 2), final = hit(0, 0, 0, 180, 200, 1.8, 80, 26), finalRadius = 22 } },
	},
})

------------------------------------------------------------------------
-- 1.9판 초·혈마신수: 오른손에 피처럼 붉은 큰 낫을 거머쥐고, 짐승처럼 웅크려 낫을 머리 위로 치켜든다
-- 피의 계약: 체력이 깎일수록 낫이 무거워진다 (주는 피해가 오른다). 벤 만큼 되찾는다
------------------------------------------------------------------------
table.insert(Config.Styles, {
	id = "chohyeolma",
	name = "초·혈마신수",
	hanja = "超血魔神手",
	icon = "🩸",
	grade = "초월",
	transcend = true,
	color = Color3.fromRGB(220, 20, 40),
	color2 = Color3.fromRGB(255, 170, 170),
	fx = "blood",
	scythe = true, -- 오른손에 붉은 큰 낫 (화면이 그린다)
	hidden = true,
	secret = true,
	realmReq = 16,
	styleReq = "hyeolma",
	trialHp = 10,
	unlockHint = "혈마신수를 익히고 천외천에 오른 자만이, 혈교 본산 성벽 너머 혈월 제단의 혈월선을 만난다",
	desc = "혈마신수를 넘어선 권법. 손톱이 자라 낫이 되었다. 피처럼 붉은 큰 낫을 휘두를 때마다 핏빛 초승달이 하늘에 걸린다. 피를 흘릴수록 더 깊이 벤다.",
	gimmick = "피의 계약: 체력이 깎일수록 주는 피해가 오른다 (체력이 바닥이면 최대 1.6배). 벤 피해의 3%를 되찾는다. 오의 위에 초 오의(X)가 있다",
	deflect = 0.24,
	lifesteal = 0.03,
	bloodPact = 0.6,
	speed = 1.15,
	stance = "stance_reaper",
	combo = {
		{ id = "cq1", name = "혈겸 내려베기", pose = "reap_slash_r", dur = 0.34, lunge = 4, hits = { hit(0.15, 8, 6, 10, 9, 0.3, 8) } },
		{ id = "cq2", name = "역겸 올려베기", pose = "reap_slash_l", dur = 0.34, lunge = 3, hits = { hit(0.15, 8, 6, 10, 9, 0.3, 10, 8) } },
		{ id = "cq3", name = "혈륜참", pose = "reap_spin", dur = 0.46, lunge = 2, hits = { hit(0.16, 6, 9, 8, 7, 0.3, 8, nil, true), hit(0.34, 6, 9, 8, 7, 0.3, 12, nil, true) } },
		{ id = "cq4", name = "참수", pose = "reap_overhead", dur = 0.56, lunge = 4, hits = { hit(0.3, 8, 7.5, 19, 22, 0.65, 26, nil, true) } },
	},
	heavy = { id = "cqH", name = "혈월 회선참", pose = "reap_wave", dur = 0.6, lunge = 14, iframes = 0.2, hits = { hit(0.24, 9, 9, 15, 16, 0.45, 14, nil, true), hit(0.4, 9, 9, 15, 16, 0.55, 34, nil, true) } },
	skills = {
		E = { id = "cqE", name = "혈사슬", desc = "낫을 사슬에 매달아 던진다. 둘레의 적 셋을 낫 끝으로 낚아 내 앞으로 끌어온 뒤, 한 바퀴 돌며 벤다", pose = "reap_hook", dur = 0.75, cd = 9, chi = 20,
			mech = { kind = "reapHook", n = 3, range = 30, delay = 0.2, pull = 0.28, hit = hit(0, 0, 0, 10, 12, 0.6, 0), slash = hit(0, 0, 0, 22, 26, 0.6, 24), radius = 9 } },
		R = { id = "cqR", name = "혈월낙참", desc = "하늘로 솟아 낫을 거꾸로 쥐고 내리꽂는다. 앞의 땅에 핏빛 초승달 자국이 새겨지고, 한 박자 뒤 자국이 터진다", pose = "reap_leap", dur = 0.85, cd = 10, chi = 25, jump = 34,
			mech = { kind = "reapCleave", delay = 0.5, dist = 9, length = 22, width = 8, burst = 0.45, hit = hit(0, 0, 0, 34, 36, 0.8, 10, -10), burstHit = hit(0, 0, 0, 22, 26, 0.6, 20, 30) } },
		G = { id = "cqG", name = "혈마수확", desc = "등 뒤로 하늘만 한 피의 낫이 솟아 둘레를 두 바퀴 휩쓴다. 베인 적마다 핏빛 낙인이 찍히고, 낫이 땅에 꽂히는 순간 낙인이 한꺼번에 터진다. 벤 만큼 체력이 돌아온다", pose = "ult_reap", dur = 1.6, cd = 30, chi = 100, armor = true,
			mech = { kind = "harvest", radius = 26, delay = 0.45, sweeps = 2, sweepTime = 0.55, heal = 0.01, hit = hit(0, 0, 0, 30, 30, 0.6, 20), mark = 0.6, burst = hit(0, 0, 0, 60, 80, 1.2, 40, 24) } },
		X = { id = "cqX", name = "혈월만겸", desc = "초 오의. 하늘이 핏빛으로 물들고 거대한 붉은 달이 뜬다 (그동안 무적). 달빛을 받은 낫이 수백 개의 핏빛 초승달이 되어 둘레에 쏟아지고, 마지막에 달까지 닿는 한 줄기 낫질이 하늘과 땅을, 화면까지 가른다", pose = "reap_moon", dur = 3.2, cd = 60, chi = 150, armor = true,
			mech = { kind = "bloodMoon", cut = 1.4, rain = 1.4, every = 0.1, range = 40, n = 3, radius = 6, hit = hit(0, 0, 0, 7, 6, 0.2, 4), final = hit(0, 0, 0, 190, 210, 1.8, 80, 26), finalRadius = 26 } },
	},
})

------------------------------------------------------------------------
-- 2.0판 초·벽력신권: 두 팔에 뇌전을 두른 토시. 맞힐 때마다 전하, 세 번이면 연쇄 천뢰. 초 오의는 하늘의 천둥 눈
------------------------------------------------------------------------
table.insert(Config.Styles, {
	id = "chobyeok",
	name = "초·벽력신권",
	hanja = "超霹靂神拳",
	icon = "⚡",
	grade = "초월",
	transcend = true,
	color = Color3.fromRGB(150, 120, 255),
	color2 = Color3.fromRGB(255, 245, 170),
	fx = "lightning",
	gauntlets = true, -- 두 팔에 뇌전 토시 (화면이 그린다)
	hidden = true,
	secret = true,
	realmReq = 16,
	styleReq = "byeokryeok",
	trialHp = 10,
	unlockHint = "벽력신권을 익히고 천외천에 오른 자만이, 뇌운 고원 동쪽 벼랑 끝 쇠기둥 봉우리의 뇌천선을 만난다",
	desc = "벽력신권을 넘어선 권법. 두 팔에 두른 토시에 하늘의 번개가 깃들었다. 주먹은 소리보다 빠르고, 세 번째 주먹마다 하늘이 대답한다.",
	gimmick = "천뢰: 세 번 맞힐 때마다 둘레로 연쇄 천뢰가 튄다 (더 넓고 세다). 몸이 가볍다 (동작 ×1.25). 오의 위에 초 오의(X)가 있다",
	deflect = 0.24,
	chargeEvery = 3, chainDmg = 26, chainRange = 24,
	speed = 1.25,
	stance = "stance_byeokryeok",
	combo = {
		{ id = "cb1", name = "뇌섬", pose = "thunder_jab", dur = 0.26, lunge = 4, hits = { hit(0.1, 6, 4.5, 10, 9, 0.35, 8) } },
		{ id = "cb2", name = "쌍뢰", pose = "thunder_cross", dur = 0.28, lunge = 3, hits = { hit(0.11, 6, 4.5, 10, 9, 0.35, 8) } },
		{ id = "cb3", name = "뇌명선풍", pose = "roundhouse", dur = 0.38, lunge = 2, hits = { hit(0.18, 5, 6.5, 12, 11, 0.4, 14, nil, true) } },
		{ id = "cb4", name = "벽력천추", pose = "thunder_hammer", dur = 0.46, lunge = 4, hits = { hit(0.22, 7, 6.5, 20, 22, 0.6, 30, 10, true) } },
	},
	heavy = { id = "cbH", name = "뇌광일섬", pose = "lightning_dash", dur = 0.5, lunge = 22, iframes = 0.25, hits = { hit(0.2, 7, 6, 26, 26, 0.6, 36, nil, true) } },
	skills = {
		E = { id = "cbE", name = "뇌전쇄", desc = "손을 뻗어 둘레의 적 여섯에게 차례로 벼락을 꽂는다 (마비)", pose = "point_sky", dur = 0.6, cd = 8, chi = 20,
			mech = { kind = "targets", n = 6, range = 34, delay = 0.3, stagger = 0.05, radius = 6, hit = hit(0, 0, 0, 24, 20, 1.0, 6), fx = "lightning" } },
		R = { id = "cbR", name = "뇌운", desc = "머리 위로 먹구름을 부른다. 2.4초 동안 둘레의 적에게 번개가 떨어지고, 마지막에 큰 벼락이 내리친다", pose = "point_sky", dur = 0.8, cd = 11, chi = 25,
			mech = { kind = "storm", range = 22, dur = 2.4, every = 0.2, delay = 0.3, radius = 5, hit = hit(0, 0, 0, 12, 12, 0.5, 4), finalRadius = 16, final = hit(0, 0, 0, 50, 60, 1.0, 30, 12) } },
		G = { id = "cbG", name = "뇌룡승천", desc = "몸에서 번개의 용이 솟아 하늘을 감아 돌고, 적들에게 여섯 번 내리꽂힌다. 마지막에 용이 내 자리로 떨어지며 천둥이 터진다", pose = "ult_thunder", dur = 1.7, cd = 30, chi = 100, armor = true,
			mech = { kind = "thunderDragon", n = 1, ringRadius = 8, rise = 0.9, riseHit = hit(0, 0, 0, 22, 22, 0.8, 8, 24), range = 40, dives = 6, every = 0.18, diveRadius = 8, hit = hit(0, 0, 0, 36, 32, 1.0, 16, 8), finalRadius = 20, final = hit(0, 0, 0, 100, 120, 1.4, 50, 22) } },
		X = { id = "cbX", name = "구천뇌정", desc = "초 오의. 하늘이 갈라지고 구름 사이로 거대한 천둥의 눈이 뜬다 (그동안 무적). 둘레에 벼락이 쏟아지고, 마지막에 하늘에서 땅까지 닿는 벼락 기둥이 내리꽂힌다", pose = "ult_thunder", dur = 3.0, cd = 60, chi = 150, armor = true,
			mech = { kind = "heavenThunder", cut = 1.3, rain = 1.4, every = 0.1, range = 40, n = 3, radius = 6, hit = hit(0, 0, 0, 8, 7, 0.3, 4), final = hit(0, 0, 0, 190, 210, 1.8, 80, 26), finalRadius = 24 } },
	},
})

------------------------------------------------------------------------
-- 2.7판 초·창해신권 (초월): 창해신권과 진 창해신권을 모두 숙련 20까지, 비천폭의 진주를 모아 고경선을 넘는다.
-- 손목의 진주 고리와 등 뒤로 흐르는 물의 띠 (화면이 그린다). 세 번째 주먹마다 소용돌이.
-- E 조류창 · R 경음 (고래의 노래) · G 만경창파 (사방의 파도) · X 고경승천 (고대의 고래가 뛰어올라 머리 위를 지나간다)
------------------------------------------------------------------------
table.insert(Config.Styles, {
	id = "chochanghae",
	name = "초·창해신권",
	hanja = "超滄海神拳",
	icon = "🐋",
	grade = "초월",
	transcend = true,
	color = Color3.fromRGB(40, 150, 200),
	color2 = Color3.fromRGB(215, 250, 255),
	fx = "ocean",
	pearls = true, -- 손목의 진주 고리와 물의 띠 (화면이 그린다)
	whale = true, -- 초 오의 컷씬: 바다 밑의 고래
	hidden = true,
	secret = true,
	realmReq = 16,
	styleReq = "changhae",
	trialHp = 10,
	unlockHint = "창해신권을 익히고 천외천에 오른 자만이, 서해 바닷가 고래 뼈 바위에 앉은 고경선을 만난다",
	desc = "창해신권을 넘어선 권법. 손목의 진주가 바다의 숨결을 머금었다. 밀물처럼 다가와 썰물처럼 끌고 간다. 바다 가장 깊은 곳에는 아직 고래가 산다.",
	gimmick = "조수: 세 번 맞힐 때마다 상대 자리에 소용돌이가 생겨 둘레를 끌어들였다가 물기둥으로 터진다. 밀어냄 1.4배, 물살을 타 빠르다 (동작 ×1.15). 오의 위에 초 오의(X)가 있다",
	deflect = 0.24,
	kbMult = 1.4,
	speed = 1.15,
	pulse = { every = 3, kind = "tide", radius = 13, delay = 0.25, name = "조수", dmg = 30, posture = 30, stun = 0.6, kb = 20, up = 18, pull = 40 },
	stance = "stance_ocean",
	combo = {
		{ id = "cc1", name = "창랑장", pose = "wave_palm_r", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4.8, 11, 10, 0.35, 10) } },
		{ id = "cc2", name = "회류장", pose = "wave_palm_l", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 4.8, 11, 10, 0.35, 10) } },
		{ id = "cc3", name = "대와각", pose = "whirl_kick", dur = 0.4, lunge = 2, hits = { hit(0.2, 0, 7.5, 13, 12, 0.4, 18, nil, true) } },
		{ id = "cc4", name = "경파권", pose = "tidal_punch", dur = 0.46, lunge = 4, hits = { hit(0.22, 8, 6, 21, 24, 0.6, 44, 8) } },
	},
	heavy = { id = "ccH", name = "거경격", pose = "billow_strike", dur = 0.65, lunge = 3, hits = { hit(0.32, 10, 7, 30, 44, 0.8, 76, 10, true) } },
	skills = {
		E = { id = "ccE", name = "조류창", desc = "손끝에 바다를 모아 소용돌이치는 물의 창을 던진다. 창은 앞의 적을 모두 꿰뚫고, 끝에서 1.2초 동안 소용돌이가 되어 둘레를 끌어당기다 물기둥으로 터진다", pose = "tidal_punch", dur = 0.55, cd = 8, chi = 20,
			mech = { kind = "tideSpear", delay = 0.18, length = 34, travel = 0.3, width = 4.5, hit = hit(0, 0, 0, 26, 22, 0.5, 10), vortexDur = 1.2, every = 0.3, radius = 9, pull = 30, tick = hit(0, 0, 0, 8, 8, 0.3, 0), burst = hit(0, 0, 0, 30, 30, 0.6, 20, 18) } },
		R = { id = "ccR", name = "경음", desc = "두 손을 모아 깊은 바다의 노래를 부른다. 고래의 울음이 물의 고리 셋이 되어 차례로 퍼지고, 맞은 적을 밀어내며 굼뜨게 만든다. 마지막 고리가 가장 넓다", pose = "wall_raise", dur = 0.8, cd = 11, chi = 25,
			mech = { kind = "whaleSong", delay = 0.25, rings = 3, gap = 0.28, radius = 24, slow = 2.0, hit = hit(0, 0, 0, 22, 24, 0.5, 34) } },
		G = { id = "ccG", name = "만경창파", desc = "둘레 26칸의 땅이 바다가 된다. 사방에서 큰 파도 넷이 차례로 가운데로 밀려와 적을 쓸어 모으고, 마지막에 한가운데서 거대한 소용돌이가 솟아 모두 삼킨다", pose = "ult_tsunami", dur = 2.0, cd = 30, chi = 100, armor = true,
			mech = { kind = "fourWaves", delay = 0.4, radius = 26, waves = 4, travel = 0.8, gap = 0.25, pull = 40, hit = hit(0, 0, 0, 26, 26, 0.5, 0), final = hit(0, 0, 0, 110, 130, 1.4, 30, 40) } },
		X = { id = "ccX", name = "고경승천", desc = "초 오의. 하늘이 어두워지고 땅이 깊은 바다가 된다 (그동안 무적). 바다 밑에서 고대의 고래가 솟구쳐 머리 위를 지나 하늘 높이 뛰어오른다. 고래가 지나가는 그림자 아래의 적은 물살에 휩쓸려 떠오르고, 고래가 앞의 바다로 떨어지며 거대한 해일이 둘레를 덮친다", pose = "ult_tsunami", dur = 4.6, cd = 60, chi = 150, armor = true,
			mech = { kind = "ancientWhale", cut = 1.4, behind = 58, ahead = 58, flight = 2.4, height = 50, scale = 3.0, every = 0.25, width = 14, hit = hit(0, 0, 0, 16, 16, 0.4, 0, 30), finalRadius = 30, final = hit(0, 0, 0, 200, 220, 1.8, 80, 26), waveAt = 0.4, waveRadius = 30, wave = hit(0, 0, 0, 60, 70, 0.8, 60, 10) } },
	},
})

------------------------------------------------------------------------
-- 3.4판 초·성하신권 (초월): 성하신권을 숙련 20까지, 성운원의 별가루를 모아 관성대의 천성선을 넘는다.
-- 오른손에 별이 달린 지팡이 (화면이 그린다). 때릴 때마다 가끔 상대 둘레에 마법진이 열리고 별이 튀어나와 찌른다.
-- E 별똥 화살 · R 성좌진 · G 은하수 (지팡이를 꽂아 세 빛 안개 속에 별의 소용돌이) · X 성천궁 (남색 돔, 마법진, 별과 메테오, 별자리 폭발)
------------------------------------------------------------------------
table.insert(Config.Styles, {
	id = "chosengha",
	name = "초·성하신권",
	hanja = "超星河神拳",
	icon = "🪄",
	grade = "초월",
	transcend = true,
	color = Color3.fromRGB(60, 50, 170),
	color2 = Color3.fromRGB(255, 226, 120),
	fx = "galaxy",
	staff = true, -- 오른손에 별 지팡이 (화면이 그린다)
	starDome = true, -- 초 오의 컷씬: 별이 뜨는 남색 하늘
	hidden = true,
	secret = true,
	realmReq = 16,
	styleReq = "seongha",
	trialHp = 10,
	unlockHint = "성하신권을 익히고 천외천에 오른 자만이, 천상계 성운원 남쪽 끝 관성대에서 별을 헤아리는 천성선을 만난다",
	desc = "성하신권을 넘어선 권법. 주먹에 담던 별을 이제 지팡이 끝에 매달았다. 휘두를 때마다 마법진이 열리고, 별이 쏟아지고, 하늘에 별자리가 그려진다.",
	gimmick = "별진: 맞힐 때마다 25% (네 번째는 반드시) 상대 둘레에 마법진이 열리고 별이 튀어나와 찌른다. 균형을 1.3배로 깎고, 기술 대기 15% 짧다. 오의 위에 초 오의(X)가 있다",
	deflect = 0.24,
	postureMult = 1.3,
	cdMult = 0.85,
	speed = 1.1,
	pulse = { every = 4, chance = 0.25, kind = "starSigil", radius = 8, delay = 0.35, name = "별진", dmg = 24, posture = 24, stun = 0.5, kb = 12, up = 10 },
	stance = "stance_staff",
	combo = {
		{ id = "cg1", name = "성장 휘두르기", pose = "staff_swing_r", dur = 0.32, lunge = 3, hits = { hit(0.13, 7, 5.2, 11, 10, 0.35, 10) } },
		{ id = "cg2", name = "역성장", pose = "staff_swing_l", dur = 0.32, lunge = 3, hits = { hit(0.13, 7, 5.2, 11, 10, 0.35, 10, 6) } },
		{ id = "cg3", name = "성환", pose = "staff_spin", dur = 0.44, lunge = 2, hits = { hit(0.16, 0, 8, 7, 6, 0.3, 8, nil, true), hit(0.33, 0, 8, 8, 7, 0.3, 14, nil, true) } },
		{ id = "cg4", name = "낙성추", pose = "staff_slam", dur = 0.5, lunge = 4, hits = { hit(0.25, 8, 7, 21, 24, 0.6, 30, 10, true) } },
	},
	heavy = { id = "cgH", name = "유성장", pose = "staff_thrust", dur = 0.62, lunge = 6, hits = { hit(0.28, 10, 6.5, 30, 42, 0.8, 70, 8) } },
	skills = {
		E = { id = "cgE", name = "별똥 화살", desc = "지팡이 끝에 마법진을 펼쳐 별 다섯을 쏜다. 별은 둘레의 적을 쫓아가 꽂히고, 꽂힌 자리에서 작게 터진다", pose = "staff_point", dur = 0.55, cd = 7, chi = 20,
			mech = { kind = "starVolley", n = 5, range = 36, delay = 0.18, every = 0.07, travel = 0.28, radius = 4, hit = hit(0, 0, 0, 16, 14, 0.35, 10, 4) } },
		R = { id = "cgR", name = "성좌진", desc = "앞의 땅에 큰 마법진을 그린다. 둘레에 별 일곱이 떠올라 하나씩 선으로 이어져 별자리가 되는 동안 적을 끌어모으고, 별자리가 완성되면 별빛 기둥이 솟는다", pose = "staff_sigil", dur = 0.8, cd = 10, chi = 25,
			mech = { kind = "starSeal", dist = 10, radius = 12, delay = 0.35, stars = 7, link = 0.1, pull = 26, tick = hit(0, 0, 0, 6, 8, 0.3, 0), burst = hit(0, 0, 0, 40, 44, 0.8, 20, 30) } },
		G = { id = "cgG", name = "은하수", desc = "지팡이가 커다랗게 자라 땅에 꽂힌다. 둘레 24칸에 보라·남색·노란 안개가 피어오르고, 그 안에서 별들이 소용돌이치며 은하수가 된다. 소용돌이는 적을 끌어들이며 계속 치고, 마지막에 은하가 한가운데로 모여 터진다", pose = "staff_plant", dur = 1.6, cd = 30, chi = 100, armor = true,
			mech = { kind = "galaxyStaff", dist = 5, delay = 0.55, radius = 24, dur = 3.2, every = 0.25, pull = 24, tick = hit(0, 0, 0, 9, 9, 0.3, 0), final = hit(0, 0, 0, 100, 120, 1.4, 30, 36) } },
		X = { id = "cgX", name = "성천궁", desc = "초 오의. 하늘이 밤이 되고 (그동안 무적) 둘레 34칸을 덮는 커다란 남색 돔이 내려앉는다. 돔 안 곳곳에 마법진이 열려 별이 쏟아지고 메테오가 떨어진다. 마지막에 돔 표면에 별자리들이 빛으로 그려지고, 모두 한꺼번에 터진다", pose = "staff_dome", dur = 4.6, cd = 60, chi = 150, armor = true,
			mech = { kind = "starDome", cut = 1.4, radius = 34, rain = 2.6, every = 0.15, n = 3, hit = hit(0, 0, 0, 6, 6, 0.2, 4), meteorEvery = 4, meteorRadius = 8, meteor = hit(0, 0, 0, 20, 24, 0.5, 20, 10), draw = 0.9, final = hit(0, 0, 0, 190, 210, 1.8, 60, 30) } },
	},
})

------------------------------------------------------------------------
-- 2.4판 만목신권 (태초): 자연의 권법. 맞힐 때마다 씨앗이 박히고, 네 번이면 가시덤불이 터진다.
-- E 종자탄 · R 개화 (거대한 꽃봉오리가 피며 꽃가루로 잠재운다) · G 목령강림 (거대한 나무 정령이 솟아 내리친다)
------------------------------------------------------------------------
table.insert(Config.Styles, {
	id = "manmok",
	name = "만목신권",
	hanja = "萬木神拳",
	icon = "🌳",
	color = Color3.fromRGB(90, 200, 90),
	color2 = Color3.fromRGB(240, 255, 190),
	fx = "nature",
	grade = "태초",
	hidden = true,
	secret = true,
	realmReq = 14,
	trialHp = 10,
	unlockHint = "반선의 경지에 오른 자만이, 남서쪽 들판 깊은 숲 만목원의 이끼 좌대에 앉은 목선을 만난다",
	desc = "나무는 서두르지 않는다. 그러나 멈추지도 않는다. 대숲의 바람처럼 부드럽게 흘러, 천 년 은행나무처럼 무겁게 내려앉는 권. 끝에는 숲 전체가 일어선다.",
	gimmick = "죽순: 네 번 맞힐 때마다 상대 발밑에서 죽순이 창처럼 솟아 띄운다. 몸이 단단하다 (균형 1.4배). 오의 신목강림: 천 년 은행나무가 솟아 금빛 잎을 쏟는다",
	deflect = 0.28,
	postureMult = 1.4,
	speed = 1.0,
	pulse = { every = 4, kind = "bamboo", radius = 7, delay = 0.2, name = "죽순", dmg = 32, posture = 34, stun = 0.8, kb = 6, up = 20 },
	stance = "stance_wood",
	combo = {
		{ id = "mm1", name = "청엽장", pose = "wood_palm_r", dur = 0.32, lunge = 3, hits = { hit(0.13, 6, 5, 18, 15, 0.35, 10) } },
		{ id = "mm2", name = "죽절장", pose = "wood_palm_l", dur = 0.32, lunge = 3, hits = { hit(0.13, 6, 5, 18, 15, 0.35, 10) } },
		{ id = "mm3", name = "송풍퇴", pose = "wood_sweep", dur = 0.5, lunge = 1, hits = { hit(0.28, 0, 8, 20, 24, 0.5, 14, 10, true) } },
		{ id = "mm4", name = "고목권", pose = "wood_palm_r", dur = 0.48, lunge = 5, hits = { hit(0.22, 8, 6, 30, 34, 0.6, 38) } },
	},
	heavy = { id = "mmH", name = "천년송", pose = "wood_slam", dur = 0.75, lunge = 2, hits = { hit(0.36, 6, 9, 50, 76, 1.0, 40, 12, true) } },
	skills = {
		-- 2.7판: 만목신권 기술을 모두 새로 (대숲 · 잎 · 은행나무)
		E = { id = "mmE", name = "죽림창", desc = "손바닥으로 땅을 누른다. 앞으로 곧게 대나무 일곱 그루가 차례로 창처럼 솟구쳐 위의 적을 띄우고, 잠시 대숲으로 서 있다가 잎을 날리며 가라앉는다", pose = "wood_slam", dur = 0.5, cd = 8, chi = 20,
			mech = { kind = "bambooLine", n = 7, start = 4, gap = 4.2, delay = 0.18, step = 0.06, radius = 3.8, stand = 0.9, hit = hit(0, 0, 0, 40, 40, 0.7, 8, 24) } },
		R = { id = "mmR", name = "천엽비수", desc = "두 손을 돌리면 둘레에 푸른 잎 수십 장이 소용돌이친다. 잎은 가까운 적 여덟을 골라 세 줄기로 날아가 베고, 나는 체력 6%를 되찾는다", pose = "wood_bloom", dur = 0.8, cd = 11, chi = 28,
			mech = { kind = "leafVolley", gather = 0.45, range = 30, n = 8, waves = 3, every = 0.12, travel = 0.22, heal = 0.06, hit = hit(0, 0, 0, 20, 18, 0.35, 6) } },
		G = { id = "mmG", name = "신목강림", desc = "무릎을 꿇고 땅에 손을 대면 등 뒤에서 천 년 은행나무가 하늘 높이 솟는다. 2.4초 동안 금빛 잎이 둘레 24칸에 쏟아져 적을 베고, 나는 그 숲의 기운으로 체력 12%를 되찾는다. 끝에 나무가 빛나며 금빛 잎이 사방으로 휘몰아친다", pose = "ult_wood", dur = 2.2, cd = 32, chi = 100, armor = true,
			mech = { kind = "worldTree", back = 10, rise = 0.8, dur = 2.4, every = 0.3, radius = 24, heal = 0.12, hit = hit(0, 0, 0, 18, 16, 0.25, 0), finalRadius = 28, final = hit(0, 0, 0, 120, 140, 1.4, 70, 18) } },
	},
})

-- 2.2판: 초·벽력신권의 새 R·오의, 두 초 오의를 더 길게 (구천뇌정은 벼락 비 대신 하나하나 겨눠 내리꽂는 심판의 벼락)
do
	local NEW: { [string]: { [string]: any } } = {
		chobyeok = {
			R = { id = "cbR2", name = "뇌신낙", desc = "하늘로 솟았다가 벼락이 되어 가까운 적에게 내리꽂힌다. 떨어진 자리에서 네 갈래로 땅이 갈라지며 번개가 달린다", pose = "thunder_hammer", dur = 0.85, cd = 11, chi = 25, jump = 30,
				mech = { kind = "thunderDive", range = 26, delay = 0.45, radius = 8, hit = hit(0, 0, 0, 44, 44, 0.9, 20, 14), crackDelay = 0.2, length = 18, width = 3.5, crack = hit(0, 0, 0, 26, 24, 0.6, 16, 10) } },
			-- 2.6판: 천뢰구 → 뇌성강림
			G = { id = "cbG2", name = "뇌성강림", desc = "두 팔을 들어 머리 위에 고리 둘이 도는 천둥별을 띄운다. 별에서 작은 별 여섯이 떨어져 나와 둘레를 돌며 2.4초 동안 저마다 가까운 적에게 번개 줄기를 쏜다. 끝에 여섯이 다시 하나로 모여 천둥별이 땅에 떨어진다", pose = "ult_star", dur = 1.8, cd = 30, chi = 100, armor = true,
				mech = { kind = "thunderStar", dist = 4, delay = 0.45, spread = 0.4, n = 6, orbit = 13, height = 11, spin = 1.1, dur = 2.4, every = 0.35, beamRange = 16, hit = hit(0, 0, 0, 18, 14, 0.35, 0), converge = 0.4, finalRadius = 20, final = hit(0, 0, 0, 120, 140, 1.4, 60, 22) } },
		},
	}
	for _, st in ipairs(Config.Styles) do
		for slot, sk in pairs(NEW[st.id] or {}) do
			st.skills[slot] = sk
		end
	end
	for _, st in ipairs(Config.Styles) do
		if st.id == "chohyeolma" then
			local X = st.skills.X
			X.mech.rain = 2.4
			X.dur = 4.2
			X.desc = "초 오의. 하늘이 핏빛으로 물들고 거대한 붉은 달이 뜬다 (그동안 무적). 등 뒤에서 날개 달린 우두머리 악마가 솟아 큰 낫을 휘두르고, 핏빛 초승달이 2.4초 동안 쏟아진다. 마지막에 악마의 낫이 하늘과 땅을, 화면까지 가른다"
		elseif st.id == "chobyeok" then
			-- 2.3판: 구천뇌정 → 뇌고천무 (하늘의 뇌고 여덟을 두드리는 춤)
			st.skills.X = { id = "cbX2", name = "뇌고천무", desc = "초 오의. 등 뒤 하늘에 뇌고(천둥 북) 여덟이 둥글게 뜬다 (그동안 무적). 북을 열여섯 번 두드릴 때마다 그 북에서 적에게 벼락이 꽂히고, 박자는 점점 빨라진다. 네 번째마다 둘레로 천둥이 울린다. 마지막에 북이 모두 모여 하나의 뇌구가 되어 땅에 내리꽂힌다", pose = "ult_thunder", dur = 4.8, cd = 60, chi = 150, armor = true,
				mech = { kind = "thunderDrums", cut = 1.3, drums = 8, beats = 16, first = 0.3, last = 0.1, range = 40, n = 10, radius = 7, hit = hit(0, 0, 0, 30, 24, 0.5, 10), shockRadius = 13, shock = hit(0, 0, 0, 24, 30, 0.5, 30, 8), finaleDelay = 0.35, finaleDist = 8, finalRadius = 26, final = hit(0, 0, 0, 200, 220, 1.8, 80, 26) } }
		end
	end
end

------------------------------------------------------------------------
-- 3.0판: 환생 권법 넷. n번째 윤회의 시련을 넘으면 전생의 그림자가 n번째 권법을 남기고 간다
-- 초 권법처럼 모든 기술이 새로 짜였고 몸에 두르는 것이 있다 (3.2판부터 초 오의 X도 있다)
------------------------------------------------------------------------
Config.REBIRTH_STYLES = { "rinne", "eophwa", "musangkwon", "kwonwangsin" }
-- 윤회권: 등 뒤에 금빛 윤회륜이 돈다. 맞힐 때마다 지난 삶의 그림자가 한 박자 늦게 따라 친다
table.insert(Config.Styles, {
	id = "rinne",
	name = "윤회권",
	hanja = "輪廻拳",
	icon = "☸",
	grade = "윤회",
	rebirthStyle = 1,
	color = Color3.fromRGB(130, 100, 255),
	color2 = Color3.fromRGB(255, 226, 150),
	fx = "rinne",
	wheel = true, -- 등 뒤의 윤회륜 (화면이 그린다)
	hidden = true,
	unlockHint = "한 번 환생한 몸으로 첫 번째 윤회의 시련을 넘으면, 전생의 그림자가 이 권을 남기고 간다",
	desc = "돌고 도는 삶의 바퀴를 등에 진 권. 주먹이 닿을 때마다 지난 삶의 내가 한 박자 늦게 같은 자리를 다시 친다. 바퀴가 구를 때 여섯 갈래 세상이 함께 돈다.",
	gimmick = "전생의 메아리: 네 번 맞힐 때마다 지난 삶의 그림자가 나타나 같은 자리를 다시 친다. 등 뒤의 윤회륜을 던지고, 부르고, 하늘에 띄운다",
	deflect = 0.25,
	speed = 1.2,
	pulse = { every = 4, kind = "echo", radius = 8, delay = 0.4, name = "전생의 메아리", dmg = 28, posture = 26, stun = 0.5, kb = 10, up = 4 },
	stance = "stance_rinne",
	combo = {
		{ id = "rn1", name = "윤장", pose = "rinne_palm_r", dur = 0.28, lunge = 3, hits = { hit(0.11, 6, 5, 9, 8, 0.3, 6) } },
		{ id = "rn2", name = "회장", pose = "rinne_palm_l", dur = 0.28, lunge = 3, hits = { hit(0.11, 6, 5, 9, 8, 0.3, 6) } },
		{ id = "rn3", name = "법륜각", pose = "rinne_wheel_kick", dur = 0.42, lunge = 2, hits = { hit(0.14, 5, 8, 7, 7, 0.3, 8, nil, true), hit(0.3, 5, 8, 7, 7, 0.3, 8, nil, true) } },
		{ id = "rn4", name = "전생일격", pose = "rinne_thrust", dur = 0.5, lunge = 4, hits = { hit(0.24, 8, 6, 20, 22, 0.6, 28) } },
	},
	heavy = { id = "rnH", name = "윤회일장", pose = "rinne_seal", dur = 0.6, lunge = 10, iframes = 0.15, hits = { hit(0.28, 8, 8, 24, 26, 0.6, 22, nil, true) } },
	skills = {
		E = { id = "rnE", name = "윤회삼륜", desc = "등 뒤의 윤회륜을 던진다. 금빛 바퀴가 세워진 채 구르며 26칸을 나아가고, 지난 삶의 쪽빛 바퀴 둘이 양옆으로 부채꼴을 그리며 뒤따른다. 셋 모두 땅에 금빛 바퀴 자국을 새기며 갈고, 되돌아와 등에 붙는다", pose = "rinne_throw", dur = 0.6, cd = 8, chi = 20,
			mech = { kind = "rinneTriWheel", dist = 26, time = 1.3, every = 0.08, spread = 24, lag = 0.12, radius = 5.5, hit = hit(0, 0, 0, 14, 12, 0.3, 6), echo = hit(0, 0, 0, 10, 9, 0.25, 4) } },
		R = { id = "rnR", name = "삼생보", desc = "앞으로 18칸 미끄러지며 벤다 (무적). 떠난 자리에 지난 세 삶의 그림자가 멈춰 서 있다가 차례로 같은 길을 다시 내달려 베고, 끝에서 나에게 하나로 모여드는 순간 바퀴 무늬로 터진다", pose = "rinne_dash", dur = 0.5, cd = 10, chi = 25, lunge = 18, iframes = 0.35,
			mech = { kind = "threeLives", dist = 18, width = 5, delay = 0.4, gap = 0.16, merge = 1.05, hit = hit(0, 0, 0, 24, 22, 0.5, 12), echo = hit(0, 0, 0, 16, 14, 0.4, 10), burstRadius = 9, burst = hit(0, 0, 0, 40, 40, 0.7, 24, 14) } },
		G = { id = "rnG", name = "육도윤회", desc = "윤회륜이 하늘로 올라 집채만큼 커진다. 여섯 구슬 (여섯 갈래 세상) 이 차례로 떨어져 적 둘레의 여섯 자리에 빛기둥으로 꽂히고, 기둥끼리 이어져 땅에 육각별이 그려진다. 거대한 바퀴가 누워 내려와 별 위를 갈며 돌다가 내리박혀 터진다", pose = "ult_rinne", dur = 3.0, cd = 30, chi = 100, armor = true,
			mech = { kind = "sixRealms", dist = 10, hexR = 14, rise = 0.55, every = 0.18, fly = 0.22, radius = 7, hit = hit(0, 0, 0, 30, 30, 0.6, 8, 16), link = 0.35, grind = 1.0, grindEvery = 0.2, pull = 20, grindHit = hit(0, 0, 0, 12, 12, 0.3, 0), finalRadius = 24, final = hit(0, 0, 0, 140, 160, 1.5, 60, 26) } },
		X = { id = "rnX", name = "윤회전생", desc = "초 오의. 컷씬: 하늘이 쪽빛으로 저물고 등 뒤 하늘에 거대한 윤회륜이 걸리며, 둘레의 땅에서 지난 네 삶의 내가 일어선다 (그동안 무적). 전생의 군세가 적에게 번갈아 덮쳐 친다. 바퀴가 땅에 누워 둘레를 가두고 돌며 끌어당기고, 모두가 나에게 모여드는 순간 다시 태어나며 금빛으로 터진다", pose = "ult_rinne_x", dur = 5.0, cd = 60, chi = 150, armor = true,
			mech = { kind = "rebirthCycle", cut = 1.5, army = 1.8, every = 0.15, range = 45, n = 2, strike = hit(0, 0, 0, 22, 20, 0.4, 6), cage = 1.0, cageEvery = 0.2, cageR = 34, pull = 30, grind = hit(0, 0, 0, 14, 12, 0.3, 0), merge = 0.4, finalRadius = 38, final = hit(0, 0, 0, 240, 270, 1.8, 80, 30) } },
	},
})
-- 업화권: 검은 불꽃과 붉은 사슬. 쌓인 업이 상대 발밑에서 지옥불로 터진다
table.insert(Config.Styles, {
	id = "eophwa",
	name = "업화권",
	hanja = "業火拳",
	icon = "🔥",
	grade = "윤회",
	rebirthStyle = 2,
	color = Color3.fromRGB(235, 40, 30),
	color2 = Color3.fromRGB(40, 12, 24),
	fx = "karma",
	chains = true, -- 두 팔에 감긴 붉게 달군 사슬과 검은 불꽃 (화면이 그린다)
	hidden = true,
	unlockHint = "두 번 환생한 몸으로 두 번째 윤회의 시련을 넘으면, 업을 진 그림자가 이 권을 남기고 간다",
	desc = "두 삶 동안 쌓인 업이 검은 불꽃이 되었다. 달군 사슬을 팔에 감고 치는 주먹마다 업이 상대에게 옮겨 붙고, 업이 차면 발밑에서 지옥불이 솟는다.",
	gimmick = "업보: 다섯 번 맞힐 때마다 상대에게 업의 낙인이 찍히고, 반 박자 뒤 발밑에서 검은 지옥불 기둥이 솟아 띄운다. 맞을수록 불은 더 무겁다 (균형 1.25배)",
	deflect = 0.24,
	postureMult = 1.25,
	speed = 1.1,
	pulse = { every = 5, kind = "karma", radius = 7, delay = 0.5, name = "업보", dmg = 36, posture = 32, stun = 0.6, kb = 6, up = 16 },
	stance = "stance_karma",
	combo = {
		{ id = "ep1", name = "업화탄권", pose = "karma_jab_r", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 5, 11, 10, 0.3, 8) } },
		{ id = "ep2", name = "흑염권", pose = "karma_jab_l", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 5, 11, 10, 0.3, 8) } },
		{ id = "ep3", name = "사슬회권", pose = "karma_chain", dur = 0.46, lunge = 2, hits = { hit(0.18, 6, 9, 9, 9, 0.35, 10, nil, true), hit(0.34, 6, 9, 9, 9, 0.35, 12, nil, true) } },
		{ id = "ep4", name = "겁화추", pose = "karma_smash", dur = 0.56, lunge = 4, hits = { hit(0.3, 7, 7, 24, 28, 0.7, 20, 12, true) } },
	},
	heavy = { id = "epH", name = "업화일권", pose = "karma_charge", dur = 0.66, lunge = 14, iframes = 0.2, hits = { hit(0.3, 9, 7, 30, 34, 0.7, 34) } },
	skills = {
		E = { id = "epE", name = "업화쇄", desc = "두 팔의 달군 사슬을 내던진다. 사슬은 가까운 적 셋에게 날아가 걸리고, 검은 불이 사슬을 타고 번지며 적을 끌어온 뒤 발밑에서 지옥불로 터진다", pose = "karma_throw", dur = 0.6, cd = 8, chi = 20,
			mech = { kind = "karmaChains", n = 3, range = 28, hook = 0.18, hold = 0.42, pull = 40, hit = hit(0, 0, 0, 16, 14, 0.4, 0), burstRadius = 6, burst = hit(0, 0, 0, 30, 28, 0.6, 10, 14) } },
		R = { id = "epR", name = "겁화질주", desc = "검은 불꽃이 되어 앞으로 22칸 내달린다 (무적). 지나간 땅이 용암 틈으로 갈라져 타고, 양옆으로 사슬이 휘몰아친다. 잠시 뒤 도화선처럼 불기둥 여덟이 차례로 치솟고, 끝에서 크게 터진다", pose = "karma_dash", dur = 0.5, cd = 11, chi = 25, lunge = 22, iframes = 0.4,
			mech = { kind = "hellDash", dist = 22, width = 4.5, burn = 1.2, every = 0.3, hit = hit(0, 0, 0, 22, 20, 0.5, 10), burnHit = hit(0, 0, 0, 7, 6, 0.2, 0), erupt = 1.3, pillars = 8, step = 0.06, pillarRadius = 4.5, pillar = hit(0, 0, 0, 20, 20, 0.5, 4, 18), finalRadius = 9, final = hit(0, 0, 0, 40, 40, 0.8, 20, 24) } },
		G = { id = "epG", name = "업화지옥문", desc = "주먹으로 땅을 치면 앞의 땅이 갈라지며 붉은 글이 새겨진 거대한 지옥문이 솟는다. 문이 열리며 붉은 빛과 검은 불이 쏟아지고, 문 안에서 뻗은 사슬이 둘레의 적을 문 앞으로 끌고 간다. 문이 쾅 닫히고, 땅속으로 가라앉으며 지옥불 고리로 터진다", pose = "ult_karma", dur = 2.8, cd = 30, chi = 100, armor = true,
			mech = { kind = "hellGate", dist = 14, rise = 0.6, open = 0.4, drag = 1.0, every = 0.2, dragR = 26, pull = 34, hit = hit(0, 0, 0, 12, 12, 0.3, 0), shut = 0.4, sink = 0.5, shutR = 12, shutHit = hit(0, 0, 0, 70, 70, 0.9, 20, 10), finalRadius = 20, final = hit(0, 0, 0, 120, 140, 1.5, 50, 28) } },
		X = { id = "epX", name = "팔열지옥", desc = "초 오의. 컷씬: 하늘이 핏빛이 되고 땅이 갈라지며 둘레에 검은 불기둥 여덟이 솟는다 (그동안 무적). 기둥이 하나씩 적에게 지옥불을 내리꽂고, 땅에서 솟은 거대한 불의 두 손이 가운데를 맞잡아 짓누른다. 여덟 기둥이 머리 위로 모여 검은 해가 되고, 땅을 내리치면 검은 해가 떨어져 둘레가 지옥불의 돔으로 터진다", pose = "ult_karma_x", dur = 5.0, cd = 60, chi = 150, armor = true,
			mech = { kind = "eightHells", cut = 1.4, every = 0.2, ringR = 30, range = 42, radius = 8, hit = hit(0, 0, 0, 40, 40, 0.7, 6, 20), hands = 0.9, pull = 34, clapR = 16, clap = hit(0, 0, 0, 90, 90, 1.0, 10, 10), sun = 0.9, finalRadius = 40, final = hit(0, 0, 0, 230, 260, 1.8, 80, 30) } },
	},
})
-- 무상권 (3.6판 새로): 모든 것은 지나간다. 닿는 것마다 사기처럼 금이 가고 재로 흩어진다. 머리 뒤에 이 빠진 은빛 후광
-- E 잔영멸 (재로 빚은 나 다섯) · R 화무십일 (잿빛 꽃이 피었다 시든다) · G 제행무상 (모래시계) · X 경화수월 (거울 열둘이 깨진다)
table.insert(Config.Styles, {
	id = "musangkwon",
	name = "무상권",
	hanja = "無常拳",
	icon = "🕯",
	grade = "윤회",
	rebirthStyle = 3,
	color = Color3.fromRGB(205, 212, 228),
	color2 = Color3.fromRGB(110, 210, 255),
	fx = "mist",
	ashHalo = true, -- 머리 뒤의 이 빠진 은빛 후광과 떨어지는 재 (화면이 그린다)
	hidden = true,
	unlockHint = "세 번 환생한 몸으로 세 번째 윤회의 시련을 넘으면, 재가 된 그림자가 이 권을 남기고 간다",
	desc = "세 번을 살고 나니 모든 것이 지나간다는 것을 알았다. 닿는 것마다 금이 가고, 금 간 것은 재가 되어 흩어진다. 꽃은 지고, 모래는 다 흐르고, 촛불은 꺼진다.",
	gimmick = "무상: 25% 확률로 공격이 몸을 비켜 간다. 네 번 맞힐 때마다 상대에게 사기 같은 금이 가고, 잠시 뒤 산산이 깨져 재로 흩어진다. 빠르다 (동작 ×1.3)",
	deflect = 0.26,
	dodgeChance = 0.25,
	speed = 1.3,
	pulse = { every = 4, kind = "ashCrack", radius = 6, delay = 0.45, name = "무상인", dmg = 28, posture = 26, stun = 0.7, kb = 8, up = 6 },
	stance = "stance_mist",
	combo = {
		{ id = "ms1", name = "허장", pose = "ghost_palm_r", dur = 0.24, lunge = 4, hits = { hit(0.09, 6, 5, 8, 7, 0.25, 5) } },
		{ id = "ms2", name = "실장", pose = "ghost_palm_l", dur = 0.24, lunge = 4, hits = { hit(0.09, 6, 5, 8, 7, 0.25, 5) } },
		{ id = "ms3", name = "연무퇴", pose = "ghost_sweep", dur = 0.4, lunge = 2, hits = { hit(0.14, 0, 8, 8, 9, 0.35, 8, 6, true), hit(0.28, 0, 8, 8, 9, 0.35, 8, 6, true) } },
		{ id = "ms4", name = "멸영장", pose = "ghost_flash", dur = 0.44, lunge = 7, hits = { hit(0.2, 8, 6, 18, 20, 0.55, 22) } },
	},
	heavy = { id = "msH", name = "일장무상", pose = "ghost_flash", dur = 0.52, lunge = 16, iframes = 0.3, hits = { hit(0.22, 9, 6, 24, 24, 0.6, 26) } },
	skills = {
		E = { id = "msE", name = "잔영멸", desc = "재가 되어 앞으로 20칸을 스친다 (무적). 지나간 자리에 재로 빚은 내 모습 다섯이 남아 있다가, 차례로 금이 가고 무너지며 둘레를 친다", pose = "ghost_flash", dur = 0.5, cd = 8, chi = 20, lunge = 20, iframes = 0.4,
			mech = { kind = "ashStatues", dist = 20, n = 5, width = 4, hit = hit(0, 0, 0, 14, 12, 0.4, 8), crumble = 0.45, step = 0.1, radius = 6, burst = hit(0, 0, 0, 20, 18, 0.5, 12, 8) } },
		R = { id = "msR", name = "화무십일", desc = "앞의 땅에 커다란 잿빛 꽃이 피어난다. 꽃잎 여덟이 적을 감싸 안으로 끌어들이다가, 꽃이 시들어 재로 무너지며 터진다", pose = "ghost_split", dur = 0.6, cd = 11, chi = 25,
			mech = { kind = "witherBloom", dist = 9, radius = 11, bloom = 0.35, hold = 0.9, every = 0.3, pull = 28, tick = hit(0, 0, 0, 10, 10, 0.3, 0), burst = hit(0, 0, 0, 42, 40, 0.8, 16, 12) } },
		G = { id = "msG", name = "제행무상", desc = "둘레 26칸 위로 커다란 모래시계가 내려선다. 모래가 흐르는 동안 그 안의 적은 굼뜨고 재의 비를 맞는다. 모래가 다 흐르면 모래시계에 금이 가고, 산산이 깨지며 모든 것이 모래 폭풍으로 흩어진다", pose = "ult_mist", dur = 2.4, cd = 30, chi = 100, armor = true,
			mech = { kind = "hourglass", radius = 26, descend = 0.5, run = 2.4, every = 0.3, slow = 0.5, tick = hit(0, 0, 0, 10, 10, 0.3, 0), crack = 0.35, final = hit(0, 0, 0, 130, 150, 1.5, 60, 20) } },
		X = { id = "mkX", name = "경화수월", desc = "초 오의. 세상의 빛깔이 빠진다 (그동안 무적). 둘레 36칸에 사람 키 세 배의 거울 열둘이 솟아 원을 이룬다. 거울 속에서 유리로 된 나의 그림자가 튀어나와 적을 치고 다른 거울로 돌아가기를 거듭한다. 거울마다 금이 번지고, 모든 거울이 한가운데로 산산이 깨져 쏟아지며 모든 것이 재가 된다", pose = "ult_mist_x", dur = 4.6, cd = 60, chi = 150, armor = true,
			mech = { kind = "mirrorWorld", cut = 1.4, radius = 36, rise = 0.5, echo = 1.6, every = 0.25, hit = hit(0, 0, 0, 12, 10, 0.3, 0), crack = 0.5, final = hit(0, 0, 0, 230, 260, 1.8, 70, 26) } },
	},
})
-- 권왕신권: 머리 위의 금빛 관과 붉은 망토, 금빛 팔찌. 앞의 셋을 모두 품은 마지막 권
table.insert(Config.Styles, {
	id = "kwonwangsin",
	name = "권왕신권",
	hanja = "拳王神拳",
	icon = "👑",
	grade = "권왕",
	rebirthStyle = 4,
	color = Color3.fromRGB(255, 204, 70),
	color2 = Color3.fromRGB(200, 30, 45),
	fx = "king",
	crown = true, -- 머리 위의 금빛 관, 붉은 망토, 금빛 팔찌 (화면이 그린다)
	hidden = true,
	unlockHint = "네 번 환생한 몸으로 마지막 윤회의 시련을 넘으면, 네 삶의 그림자가 하나가 되어 이 권을 남기고 간다",
	desc = "네 번의 삶을 모두 넘은 자의 권. 맨손의 강호에 왕은 하나다. 주먹을 들면 하늘에서 금빛 주먹이 함께 내려오고, 마지막에는 금빛 왕이 일어선다.",
	gimmick = "왕의 주먹: 네 번 맞힐 때마다 하늘에서 거대한 금빛 주먹이 상대를 내리찍는다. 앞의 세 권을 품었다: 공격의 10%를 비켜 가고, 준 피해의 1.5%를 되찾는다",
	deflect = 0.3,
	dodgeChance = 0.1,
	lifesteal = 0.015,
	speed = 1.15,
	pulse = { every = 4, kind = "king", radius = 8, delay = 0.45, name = "왕의 주먹", dmg = 40, posture = 44, stun = 0.7, kb = 4, up = 12 },
	stance = "stance_king",
	combo = {
		{ id = "kw1", name = "왕권직타", pose = "king_jab_r", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 5, 13, 12, 0.35, 10) } },
		{ id = "kw2", name = "왕권횡타", pose = "king_jab_l", dur = 0.3, lunge = 3, hits = { hit(0.12, 6, 5, 13, 12, 0.35, 10) } },
		{ id = "kw3", name = "승천권", pose = "king_uppercut", dur = 0.44, lunge = 3, hits = { hit(0.2, 6, 6, 16, 18, 0.5, 6, 26) } },
		{ id = "kw4", name = "천하일권", pose = "king_hammer", dur = 0.56, lunge = 4, hits = { hit(0.3, 8, 8, 28, 32, 0.7, 24, 10, true) } },
	},
	heavy = { id = "kwH", name = "왕권일격", pose = "king_cannon", dur = 0.66, lunge = 10, iframes = 0.2, hits = { hit(0.3, 10, 8, 36, 40, 0.8, 40, nil, true) } },
	skills = {
		E = { id = "kwE", name = "왕권천타", desc = "등 뒤에 금빛 주먹 여섯이 부채꼴로 나타나 차례로 28칸을 내지른다. 마지막에 커다란 왕의 주먹이 가운데를 꿰뚫고 금빛 충격파가 줄지어 터진다", pose = "king_cannon", dur = 0.9, cd = 8, chi = 22,
			mech = { kind = "kingBarrage", n = 6, delay = 0.15, every = 0.08, length = 28, width = 3.5, hit = hit(0, 0, 0, 12, 12, 0.3, 10), finalAt = 0.12, final = hit(0, 0, 0, 34, 34, 0.7, 34, 8) } },
		R = { id = "kwR", name = "왕도강림", desc = "발밑에서 앞으로 붉은 길이 깔리고, 그 위로 크게 뛰어올라 24칸 앞에 내려앉는다 (무적). 내려앉은 자리 둘레에서 왕관의 금빛 가시 여덟이 솟고, 가시가 안으로 무너지며 터진다", pose = "king_dash", dur = 0.6, cd = 11, chi = 25, lunge = 24, jump = 36, iframes = 0.5,
			mech = { kind = "kingLeap", dist = 24, land = 0.42, landR = 9, hit = hit(0, 0, 0, 30, 30, 0.6, 14, 10), collapse = 0.4, spikeR = 8, burst = hit(0, 0, 0, 30, 30, 0.6, 8, 22) } },
		G = { id = "kwG", name = "패왕난무", desc = "둘레에 금빛 기둥 여덟이 솟아 왕의 투기장이 되고 적을 안으로 끌어들인다. 기둥마다 붉은 소매의 거대한 금빛 주먹이 나타나 차례로 한가운데를 내지르고, 마지막에 땅속에서 솟은 주먹이 모두를 하늘로 올려친다", pose = "ult_king", dur = 2.2, cd = 30, chi = 100, armor = true,
			mech = { kind = "kingArena", radius = 22, rise = 0.35, pull = 34, fists = 8, every = 0.12, width = 6, hit = hit(0, 0, 0, 14, 14, 0.5, 10, 4), upper = 0.3, final = hit(0, 0, 0, 140, 160, 1.6, 10, 46) } },
		X = { id = "kwX", name = "천하제일권", desc = "초 오의. 컷씬: 하늘이 금빛으로 갈라진다 (그동안 무적). 몸에서 금빛이 솟아 등 뒤에 관과 망토를 두른 하늘만 한 금빛 왕 (나의 모습)이 일어선다. 왕이 주먹을 당겨 하늘의 금빛을 모으고 가장 강한 적에게 내리꽂는다. 땅이 꺼지며 충격파 세 겹, 금빛 빛기둥 넷이 십자로 내달린 뒤, 하늘에서 빛의 왕관이 내려와 터진다", pose = "ult_king_x", dur = 5.0, cd = 60, chi = 150, armor = true,
			mech = { kind = "kingAvatar", cut = 1.5, rise = 0.8, charge = 0.6, punch = 0.3, range = 44, fistR = 20, fist = hit(0, 0, 0, 170, 180, 1.4, 40, 20), rings = 3, ringEvery = 0.2, ringHit = hit(0, 0, 0, 26, 26, 0.6, 40, 8), cross = 0.6, crossLen = 40, crossW = 7, crossHit = hit(0, 0, 0, 40, 40, 0.7, 20, 14), crownAt = 0.4, finalRadius = 28, final = hit(0, 0, 0, 190, 220, 1.8, 60, 30) } },
	},
})

-- 3.10판 몽유권 (두 번째 윤회의 꿈, 예전 호접몽권): 반쯤 잠든 채 꿈속을 걷는 권. 꿈에서는 문이 허공에 열리고, 땅과 하늘이 뒤집히고,
-- 달이 손에 닿는다. 빛깔은 밤하늘빛과 달빛 (안개처럼 번지는 보라·남빛, 따뜻한 달빛 금빛)
-- E 꿈길 걸음 (달빛 디딤돌 길) · R 거꾸로 꿈 (중력이 뒤집힌다) · G 몽중몽 (떠다니는 섬·계단·문) · X 월하몽 (보름달과 밤 호수)
table.insert(Config.Styles, {
	id = "hojeop",
	name = "몽유권",
	hanja = "夢遊拳",
	icon = "🌙",
	grade = "윤회",
	rebirthStyle = 2,
	rebirthReq = 2,
	color = Color3.fromRGB(120, 124, 230),
	color2 = Color3.fromRGB(255, 232, 170),
	fx = "cloud",
	dreamMoon = true, -- 머리 뒤를 천천히 도는 초승달과 작은 별, 발밑에 번지는 꿈 안개 (화면이 그린다)
	hidden = true,
	secret = true,
	realmReq = 16,
	trialHp = 10,
	unlockHint = "두 번 환생한 몸으로, 연화정에서 꾸벅꾸벅 조는 몽선의 꿈 이야기를 들어주어라",
	desc = "두 번째 삶의 꿈속을 걷는 권. 반쯤 잠든 채 싸운다. 꿈에서는 문이 허공에 열리고, 땅과 하늘이 뒤집히고, 달이 손에 닿는다.",
	gimmick = "꿈길: 네 번 맞힐 때마다 상대 등 뒤 허공에 꿈의 문이 열려 상대를 빨아들였다가 뱉어 낸다. 잠결처럼 가볍다: 공격의 15%가 비켜 가고, 동작 ×1.2",
	deflect = 0.24,
	dodgeChance = 0.15,
	speed = 1.2,
	pulse = { every = 4, kind = "dreamDoor", radius = 6, delay = 0.6, name = "꿈의 문", dmg = 28, posture = 26, stun = 0.8, kb = 2, up = 22 },
	stance = "stance_cloud",
	combo = {
		{ id = "hj1", name = "잠결 손", pose = "palm_r", dur = 0.26, lunge = 3, hits = { hit(0.1, 6, 5, 9, 8, 0.3, 6) } },
		{ id = "hj2", name = "꿈결 손", pose = "palm_l", dur = 0.26, lunge = 3, hits = { hit(0.1, 6, 5, 9, 8, 0.3, 6) } },
		{ id = "hj3", name = "뒤척임", pose = "circle_palm", dur = 0.42, lunge = 2, hits = { hit(0.16, 0, 8, 8, 8, 0.3, 8, 4, true), hit(0.3, 0, 8, 8, 8, 0.3, 8, 6, true) } },
		{ id = "hj4", name = "깨는 손", pose = "double_palm", dur = 0.46, lunge = 4, hits = { hit(0.22, 8, 6, 20, 22, 0.6, 24, 8) } },
	},
	heavy = { id = "hjH", name = "몽중일장", pose = "push_palm", dur = 0.6, lunge = 8, hits = { hit(0.28, 9, 7, 26, 28, 0.7, 40, 10, true) } },
	skills = {
		E = { id = "hjE", name = "꿈길 걸음", desc = "눈을 감은 채 앞으로 18칸을 걷는다 (그동안 무적). 발 앞 허공에 달빛 디딤돌이 하나씩 놓여 밤하늘 길이 되고, 길 위의 적은 꾸벅 잠이 든다 (0.8초 기절). 길 끝에 닿으면 디딤돌이 차례로 별가루가 되어 솟구치며 잠든 적을 한 번 더 친다", pose = "dash_strike", dur = 0.55, cd = 8, chi = 20,
			mech = { kind = "dreamWalk", dist = 18, slide = 0.45, width = 4.5, sleep = 0.8, hit = hit(0, 0, 0, 20, 18, 0.3, 0, 4), final = hit(0, 0, 0, 50, 50, 0.9, 20, 14) } },
		R = { id = "hjR", name = "거꾸로 꿈", desc = "앞의 땅이 밤하늘이 되고 중력이 뒤집힌다. 그 안의 적은 하늘로 떨어지듯 거꾸로 떠오르다가, 꿈이 바로 서는 순간 땅에 내리꽂힌다", pose = "circle_palm", dur = 0.6, cd = 11, chi = 25,
			mech = { kind = "upsideDown", dist = 9, radius = 11, delay = 0.25, hold = 1.2, every = 0.3, tick = hit(0, 0, 0, 8, 8, 0.3, 0, 12), slam = hit(0, 0, 0, 40, 40, 0.8, 10, 0) } },
		G = { id = "hjG", name = "몽중몽", desc = "둘레 26칸이 꿈속이 된다. 밤하늘에 커다란 달이 뜨고, 풀이 덮인 작은 섬과 끝이 없는 계단과 문들이 둥실 떠다닌다. 문이 적 곁에서 열렸다 닫힐 때마다 꿈에 베이고, 마지막에 모든 것이 아래로 떨어지며 꿈에서 깬다", pose = "ult_raise", dur = 2.4, cd = 30, chi = 100, armor = true,
			mech = { kind = "dreamIsles", radius = 26, delay = 0.4, dur = 3.0, every = 0.3, slow = 0.6, tick = hit(0, 0, 0, 10, 10, 0.3, 0), final = hit(0, 0, 0, 130, 150, 1.5, 40, 24) } },
		X = { id = "hjX", name = "월하몽", desc = "초 오의. 컷씬: 밤이 내리고 하늘을 가득 채우는 보름달이 떠오른다 (그동안 무적). 둘레 40칸의 땅이 달을 비추는 고요한 밤 호수가 되고, 등불과 문이 떠오른다. 적은 잠든 듯 둥실 떠올라 별의 소용돌이에 감기고, 마지막에 달이 천천히 내려와 호수에 닿는 순간 하얀 빛이 소리 없이 번지며 모두 떨어진다", pose = "ult_bloom", dur = 4.6, cd = 60, chi = 150, armor = true,
			mech = { kind = "moonDream", cut = 1.4, rise = 0.5, drift = 2.0, every = 0.25, range = 40, hit = hit(0, 0, 0, 10, 10, 0.3, 0, 6), descend = 0.8, finalRadius = 36, final = hit(0, 0, 0, 230, 260, 1.8, 40, 20) } },
	},
})

-- 3.8판 공백권 (숨은 윤회 권법): 지워진 것, 있어서는 안 되는 빈칸. 검정과 흰색, 가끔 번쩍이는 붉은빛, 깨진 화면
-- 지도에도 이야기에도 나오지 않는다. 세상의 남동쪽 끝 '빈칸'의 이름 없는 자에게서만 (이스터에그)
-- E 소거 (선택 상자 속을 지운다) · R 끊김 (화면이 끊기듯 순간이동하며 친다) · G 허공 격자 · X 존재소거
table.insert(Config.Styles, {
	id = "gongbaek",
	name = "공백권",
	hanja = "空白拳",
	icon = "⬛",
	grade = "윤회",
	rebirthReq = 1,
	color = Color3.fromRGB(24, 22, 28),
	color2 = Color3.fromRGB(235, 235, 240),
	fx = "subspace",
	nullCubes = true, -- 몸 둘레에서 지직거리며 튀는 빈칸 상자 셋 (화면이 그린다)
	hidden = true,
	secret = true,
	realmReq = 16,
	trialHp = 10,
	unlockHint = "???",
	desc = "null. 이 권법의 설명은 지워졌다. 주먹이 닿은 자리는 비어 버리고, 비어 버린 자리는 다시 채워지지 않는다.",
	gimmick = "빈칸: 네 번 맞힐 때마다 상대가 검은 네모 칸에 지워졌다가 깨진 화면처럼 돌아온다. 끊김: 공격의 12%가 몸을 비켜 간다 (지직). 동작 ×1.25",
	deflect = 0.24,
	dodgeChance = 0.12,
	speed = 1.25,
	pulse = { every = 4, kind = "voidCell", radius = 6, delay = 0.4, name = "빈칸", dmg = 30, posture = 28, stun = 0.7, kb = 4, up = 4 },
	stance = "stance_subspace",
	combo = {
		{ id = "gb1", name = "지직", pose = "void_palm_r", dur = 0.24, lunge = 4, hits = { hit(0.09, 6, 5, 9, 8, 0.28, 6) } },
		{ id = "gb2", name = "끊김", pose = "void_palm_l", dur = 0.24, lunge = 4, hits = { hit(0.09, 6, 5, 9, 8, 0.28, 6) } },
		{ id = "gb3", name = "되감기", pose = "back_spin_kick", dur = 0.42, lunge = 2, hits = { hit(0.16, 0, 8, 8, 8, 0.3, 10, nil, true), hit(0.3, 0, 8, 8, 8, 0.3, 10, nil, true) } },
		{ id = "gb4", name = "덮어쓰기", pose = "void_push", dur = 0.46, lunge = 5, hits = { hit(0.22, 8, 6, 20, 22, 0.6, 26) } },
	},
	heavy = { id = "gbH", name = "빈 주먹", pose = "void_point", dur = 0.58, lunge = 10, iframes = 0.2, hits = { hit(0.26, 9, 6, 26, 28, 0.7, 36, 6) } },
	skills = {
		E = { id = "gbE", name = "소거", desc = "앞에 흰 선택 상자가 그어지고 깜박인다. 상자 안의 모든 것이 검게 지워졌다가, 상자가 화소 조각으로 부서진다", pose = "void_point", dur = 0.55, cd = 8, chi = 20,
			mech = { kind = "eraseBox", dist = 3, length = 24, width = 9, delay = 0.35, hit = hit(0, 0, 0, 34, 30, 0.7, 10, 6), shardAt = 0.25, shard = hit(0, 0, 0, 14, 12, 0.3, 14) } },
		R = { id = "gbR", name = "끊김", desc = "화면이 끊기듯 둘레의 적 넷 사이를 순간이동하며 친다 (그동안 무적). 지나간 자리마다 어긋난 잔상이 남고, 마지막 적의 등 뒤에 나타난다", pose = "void_sink", dur = 0.7, cd = 11, chi = 25, iframes = 0.7,
			mech = { kind = "glitchBlink", n = 4, range = 26, delay = 0.08, every = 0.13, hit = hit(0, 0, 0, 22, 20, 0.5, 8, 4) } },
		G = { id = "gbG", name = "허공 격자", desc = "둘레 26칸의 빛깔이 빠지고 땅이 흰 격자의 검은 허공이 된다. 허공 위로 붉은 null 글자가 떠다니며 적을 가운데로 끌어 지우다가, 허공이 한 점으로 오그라든 뒤 흰 잡음으로 터진다", pose = "void_gather", dur = 2.2, cd = 30, chi = 100, armor = true,
			mech = { kind = "voidGrid", radius = 26, delay = 0.35, dur = 2.6, every = 0.3, pull = 26, tick = hit(0, 0, 0, 10, 10, 0.3, 0), collapse = 0.35, final = hit(0, 0, 0, 130, 150, 1.5, 30, 20) } },
		X = { id = "gbX", name = "존재소거", desc = "초 오의. 화면이 깨진다 (그동안 무적). 둘레 40칸에 검은 화면 균열이 미끄러지고, 하늘에서 빈칸 상자들이 적에게 떨어진다. 모든 것이 멈추고 빛깔이 뒤집힌 뒤, 삑 소리 한 번에 둘레가 화소 조각으로 무너진다", pose = "ult_void", dur = 4.4, cd = 60, chi = 150, armor = true,
			mech = { kind = "nullOut", cut = 1.4, range = 40, rain = 2.0, every = 0.12, n = 2, cubeRadius = 5, hit = hit(0, 0, 0, 10, 10, 0.3, 4, 4), freeze = 0.5, finalRadius = 40, final = hit(0, 0, 0, 230, 260, 1.8, 50, 20) } },
	},
})

------------------------------------------------------------------------
-- 3.1판: 극 권법. 초 권법을 넘어선 권법으로, 세 번 환생한 몸만 얻는다 (천상 윤회대의 사부에게)
-- 초 오의(X) 위에 극 패시브가 있다: 싸우며 극을 채우면 서버 전체에 컷씬이 흐르고, 세상이 바뀌고, 기술이 모두 바뀐다
------------------------------------------------------------------------
Config.GEUK_REQ = { geukilwol = { base = "ilwol", lv = 20, rebirth = 3 } }
-- 극 일월신권: 어깨 뒤에 작은 해와 달이 떠 돈다. 극이 차면 해와 달이 미친 듯이 번갈아 뜨다가 세상이 황혼에 멈춘다
table.insert(Config.Styles, {
	id = "geukilwol",
	name = "극 일월신권",
	hanja = "極日月神拳",
	icon = "🌗",
	grade = "극",
	geuk = true,
	color = Color3.fromRGB(255, 190, 70),
	color2 = Color3.fromRGB(205, 220, 255),
	fx = "eclipse",
	sunMoonOrbs = true, -- 어깨 뒤의 해와 달 (화면이 그린다). 황혼에는 머리 뒤의 황혼 고리로 합쳐진다
	hidden = true,
	secret = true,
	realmReq = 12,
	styleReq = "ilwol",
	trialHp = 12,
	unlockHint = "일월신권을 숙련 20까지 쌓고 세 번 환생한 자만이, 천상 윤회대의 황혼권존을 만난다",
	desc = "일월신권의 끝. 해와 달을 쥐는 것을 넘어, 해와 달을 부린다. 싸움이 무르익으면 해와 달이 미친 듯이 번갈아 뜨다가 세상이 황혼에 멈추고, 그 황혼 속에서 모든 수가 다른 것이 된다.",
	gimmick = "극 패시브 · 일월극변: 맞히고 맞으며 극(100)을 채우면 서버 전체에 컷씬이 흐르고 40초 동안 세상이 황혼이 된다. 그동안 모든 기술이 황혼의 기술로 바뀌고 (더 세다), 연타·강타 피해 1.3배. 낮에는 주는 피해 +20%, 밤에는 받는 피해 -20%. 모든 기술 대기 30% 짧음. 초 오의(X)가 있다",
	deflect = 0.34,
	postureMult = 1.8,
	speed = 1.15,
	cdMult = 0.7,
	sunMoon = { day = 1.2, night = 0.8 },
	pulse = { every = 3, kind = "eclipse", radius = 13, delay = 0.3, name = "일월", dmg = 48, posture = 46, stun = 0.6, kb = 20, up = 8 },
	-- 극: 맞힐 때 2 (기술은 1), 맞을 때 4. 100이면 일월극변 (컷씬 3초 뒤 황혼 40초)
	geukGauge = { max = 100, hit = 2, skillHit = 1, hurt = 4, cut = 3, dur = 40 },
	stance = "stance_sunmoon",
	combo = {
		{ id = "gw1", name = "극 일출장", pose = "sun_palm_r", dur = 0.26, lunge = 3, hits = { hit(0.1, 6, 5, 24, 18, 0.35, 9) } },
		{ id = "gw2", name = "극 월하장", pose = "moon_palm_l", dur = 0.26, lunge = 3, hits = { hit(0.1, 6, 5, 24, 18, 0.35, 9) } },
		{ id = "gw3", name = "극 일륜각", pose = "sun_wheel", dur = 0.4, lunge = 2, hits = { hit(0.2, 6, 7, 28, 26, 0.45, 18, 6, true) } },
		{ id = "gw4", name = "극 월인권", pose = "moon_seal", dur = 0.46, lunge = 3, hits = { hit(0.22, 9, 6, 38, 42, 0.6, 36) } },
	},
	heavy = { id = "gwH", name = "일월극벽", pose = "eclipse_push", dur = 0.72, lunge = 5, hits = { hit(0.4, 15, 8, 74, 110, 1.0, 64, 10, true) } },
	skills = {
		E = { id = "gwE", name = "일월쌍륜", desc = "해의 원반과 달의 원반을 양옆으로 던진다. 두 원반은 서로 엇갈리는 활을 그리며 앞으로 날아가 지나는 적을 태우고 베다가, 30칸 앞에서 만나 일식처럼 터진다", pose = "moon_throw", dur = 0.6, cd = 7, chi = 20,
			mech = { kind = "twinDiscs", dist = 30, swing = 9, time = 0.6, every = 0.06, radius = 5.5, hit = hit(0, 0, 0, 30, 26, 0.45, 10), burstRadius = 10, burst = hit(0, 0, 0, 50, 56, 0.8, 30, 10) } },
		R = { id = "gwR", name = "일월환보", desc = "제자리에 해를 터뜨리며 앞으로 22칸 사라졌다 나타난다 (무적). 지나간 길을 달빛이 베고, 내려선 자리에서 초승달이 둥글게 터진다", pose = "sun_wheel", dur = 0.6, cd = 10, chi = 25, lunge = 22, iframes = 0.45,
			mech = { kind = "solarLunarStep", dist = 22, width = 5, sunRadius = 9, sun = hit(0, 0, 0, 40, 40, 0.7, 24, 10), moon = hit(0, 0, 0, 40, 36, 0.6, 10), landRadius = 10, land = hit(0, 0, 0, 50, 56, 0.8, 30, 12) } },
		G = { id = "gwG", name = "대일월천", desc = "등 뒤에 해와 달이 떠오른다. 해는 불의 빛줄기로 앞의 땅을 앞뒤로 쓸어 태우고, 달은 거대한 초승달 셋을 차례로 내리꽂는다. 둘이 적 위에서 부딪쳐 일식이 되고 땅이 갈라지며, 일식이 땅에 박혀 빛의 돔으로 터진다", pose = "sun_moon_call", dur = 2.6, cd = 30, chi = 100, armor = true,
			mech = { kind = "sunMoonFall", dist = 14, summon = 0.7, beam = 1.2, every = 0.15, sweep = 9, width = 5, hit = hit(0, 0, 0, 16, 14, 0.3, 0), slams = 3, slamEvery = 0.36, travel = 0.22, slamRadius = 10, slam = hit(0, 0, 0, 50, 50, 0.7, 16, 12), merge = 0.5, finalRadius = 26, final = hit(0, 0, 0, 250, 290, 1.6, 70, 28) } },
		X = { id = "gwX", name = "일월개벽", desc = "초 오의. 컷씬: 세상이 어두워지고 등 뒤 지평선 양쪽에서 거대한 해와 달이 솟는다 (그동안 무적). 해와 달이 나를 두고 점점 빨리 돌며 번갈아 적을 친다 (해는 불기둥, 달은 초승달). 둘이 머리 위에서 부딪쳐 하늘에 거대한 일식이 걸리면 세상의 빛깔이 빠지고, 일식의 빛살이 쏟아진다. 하늘로 주먹을 내지르면 일식이 금 가고 깨지며 새벽빛으로 터진다", pose = "ult_genesis", dur = 5.2, cd = 60, chi = 150, armor = true,
			mech = { kind = "eclipseGenesis", cut = 1.5, orbit = 1.4, orbitEvery = 0.2, orbitN = 3, orbitR = 30, orbitHit = hit(0, 0, 0, 24, 20, 0.35, 4), collide = 0.4, rays = 1.4, every = 0.1, range = 55, n = 5, radius = 6, hit = hit(0, 0, 0, 20, 16, 0.35, 4), finalAt = 0.4, finalRadius = 40, final = hit(0, 0, 0, 330, 370, 1.8, 80, 32) } },
	},
	-- 황혼 (일월극변 동안): 기술이 모두 바뀐다. 해와 달이 하나로 겹친 노을빛
	twilight = {
		name = "황혼",
		color = Color3.fromRGB(255, 120, 60),
		color2 = Color3.fromRGB(165, 95, 235),
		dmg = 1.3,
		pulse = { every = 3, kind = "dusk", radius = 15, delay = 0.3, name = "황혼", dmg = 64, posture = 60, stun = 0.7, kb = 24, up = 10 },
		heavy = { id = "gtH", name = "황혼일권", pose = "eclipse_push", dur = 0.72, lunge = 6, hits = { hit(0.4, 18, 10, 100, 140, 1.1, 70, 12, true) } },
		skills = {
			E = { id = "gtE", name = "황혼참", desc = "노을빛 초승달 다섯을 부채꼴로 던진다. 초승달은 28칸 날아갔다가 되돌아오며 오갈 때 한 번씩 벤다", pose = "moon_throw", dur = 0.55, cd = 6, chi = 18,
				mech = { kind = "duskFan", n = 5, spread = 80, dist = 28, time = 0.7, every = 0.05, radius = 4.5, hit = hit(0, 0, 0, 34, 30, 0.45, 10) } },
			R = { id = "gtR", name = "석양보", desc = "노을이 되어 가까운 적 다섯의 등 뒤로 차례로 나타나며 벤다 (무적). 지나간 노을빛 줄이 모두 한꺼번에 터진다", pose = "sun_wheel", dur = 0.8, cd = 9, chi = 22,
				mech = { kind = "duskChain", n = 5, range = 30, every = 0.12, delay = 0.08, hit = hit(0, 0, 0, 40, 36, 0.6, 8, 6), burstAt = 0.35, width = 4, burst = hit(0, 0, 0, 46, 50, 0.7, 20, 10) } },
			G = { id = "gtG", name = "황혼낙일", desc = "하늘 저편에서 거대한 석양이 내려와 앞의 땅에 닿고, 땅이 노을빛 바다가 된다. 석양이 가라앉는 동안 바다 위의 적은 타며 굼뜨고, 노을빛 물결 넷이 퍼지고, 달빛 기둥이 솟는다. 다 잠기면 바다가 잠깐 식어 고요해졌다가 노을 불꽃의 왕관으로 솟구친다", pose = "sun_moon_call", dur = 2.6, cd = 26, chi = 100, armor = true,
				mech = { kind = "sunsetSea", dist = 12, descend = 0.7, sink = 1.6, every = 0.2, radius = 24, hit = hit(0, 0, 0, 12, 10, 0.3, 0), waves = 4, wave = hit(0, 0, 0, 38, 36, 0.6, 24, 8), beams = 8, beamRadius = 5, beam = hit(0, 0, 0, 36, 32, 0.6, 4, 20), dark = 0.3, finalRadius = 28, final = hit(0, 0, 0, 290, 330, 1.6, 70, 30) } },
			X = { id = "gtX", name = "일월동귀", desc = "황혼의 초 오의. 컷씬: 하늘이 노을로 물들고 양쪽에서 거대한 석양과 달이 내려온다 (그동안 무적). 둘은 빨려 들며 작아져 두 손에 맺히고, 손을 떠나 발밑 진의 테두리를 서로 반대로 내달려 불의 원을 그린다. 앞에서 만난 둘은 황혼의 구슬이 되어 머리 위로 떠올라 둘레를 빨아들이다가 한 점으로 줄어들고, 세상이 노을빛으로 하얗게 터진다", pose = "ult_dusk", dur = 4.4, cd = 50, chi = 150, armor = true,
				mech = { kind = "twilightCollapse", cut = 1.3, gather = 0.8, circle = 1.2, every = 0.15, rim = 26, rimHit = hit(0, 0, 0, 28, 22, 0.4, 4), fuse = 0.6, pull = 40, collapse = 0.35, finalRadius = 50, final = hit(0, 0, 0, 430, 470, 2.0, 90, 34) } },
		},
	},
})

-- 3.5판: 모든 권법이 들어온 뒤 등급을 다섯 단계로 다시 매긴다
for _, st in ipairs(Config.Styles) do
	local g = ({ taeheo = "상급", geumgang = "상급", cheonryong = "최상급", maehwa = "중급", muyeong = "상급", byeokryeok = "중급", chwi = "중급", hyeolma = "전설", mugeuk = "신화", pungsin = "최상급" })[st.id]
	local old = g or st.grade or "중급"
	st.rank = OLD_RANK[old] or 2
	if st.awakenOf or st.transcend or st.geuk or st.id == "kwonwangsin" then
		st.grade = old -- 진·초·극과 권왕신권 (권왕 ×3.4): 예전 그대로
	else
		st.grade = GRADE_REMAP[old] or "상급"
	end
end
-- 극 모습은 신화 이상 권법에서만 (어기면 경고만)
for _, st in ipairs(Config.Styles) do
	if st.geuk and st.styleReq then
		local base
		for _, b in ipairs(Config.Styles) do
			if b.id == st.styleReq then
				base = b
			end
		end
		if base and Config.FORM_LIMIT[base.grade] ~= "극" then
			warn("[권왕] " .. st.name .. ": 극 모습은 신화 이상 권법에서만")
		end
	end
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
	hyeolma2 = { name = "진 혈마승천조", pose = "blood_rake" },
	cheonryong2 = { name = "진 승룡장", pose = "dragon_rise" },
	byeokryeok2 = { name = "진 벽력천추", pose = "knee_strike" },
	changhae = { name = "창해승천장", pose = "tidal_punch" },
	yeonggeop = { name = "영겁승천각", pose = "rewind_kick" },
	yeolhwa = { name = "열화승천권", pose = "blaze_punch" },
	musang = { name = "무쌍승천권", pose = "uppercut" },
	pungsin = { name = "풍신승천각", pose = "gale_double" },
	agong = { name = "아공승천장", pose = "void_push" },
	unryu = { name = "운류승천장", pose = "double_palm" },
	seongha = { name = "성하승천권", pose = "star_punch_r" },
	chomaehwa = { name = "앵화승천선", pose = "fan_rise" },
	chochwi = { name = "취선승천권", pose = "soju_rise" },
	geumgang2 = { name = "불괴승천추", pose = "elbow_r" },
	muyeong2 = { name = "귀영승천각", pose = "back_spin_kick" },
	taeheo2 = { name = "유수승천장", pose = "double_palm" },
	chohyeolma = { name = "혈겸승천", pose = "reap_rise" },
	yeolhwa2 = { name = "업화승천권", pose = "blaze_punch" },
	changhae2 = { name = "심해승천장", pose = "tidal_punch" },
	pungsin2 = { name = "천풍승천각", pose = "gale_double" },
	chobyeok = { name = "천뢰승천권", pose = "knee_strike" },
	chochanghae = { name = "고경승천장", pose = "tidal_punch" },
	chosengha = { name = "성장승천", pose = "staff_rise" },
	mugeuk2 = { name = "진 무극승천장", pose = "void_push" },
	maehwa2 = { name = "설중매영각", pose = "crescent_kick" },
	chwi2 = { name = "취선번천각", pose = "drunk_flop" },
	rinne = { name = "윤회승천장", pose = "rinne_thrust" },
	eophwa = { name = "겁화승천권", pose = "karma_smash" },
	musangkwon = { name = "무상승천각", pose = "ghost_flash" },
	hojeop = { name = "몽유승천", pose = "petal_spin" },
	gongbaek = { name = "빈칸승천", pose = "void_point" },
	kwonwangsin = { name = "천하승천권", pose = "king_uppercut" },
	geukilwol = { name = "일월극승천각", pose = "sun_wheel" },
	manmok = { name = "만목귀원", pose = "double_palm" },
}
for id, fin in pairs(FINISHERS) do
	local s = Config.STYLE_BY_ID[id]
	s.finisher = { id = id .. "F", name = fin.name, pose = fin.pose, dur = 0.62, lunge = 4, launcher = true, hits = { hit(0.26, 6, 5, 16, 24, 0.7, 6, 62) } }
end

-- 연타 박자: 앞 동작이 이만큼 지났을 때 누르면 '딱 맞음(連)', 너무 일찍 두 번 누르면 흐트러진다
Config.RHYTHM = { early = 0.3, perfectFrom = 0.62, perfectTo = 1.0, late = 0.18, bonus = 1.15, chain = 3, chainBonus = 1.3, breakLock = 0.25, earlyLimit = 4 }

-- 권법 배우는 값 (이미 배운 권법 수에 따라). 첫 권법은 공짜
Config.LEARN_COST = { 0, 300, 750, 1500, 3000, 5000, 7500, 9000, 12000, 20000, 50000, 50000, 50000, 100000, 300000, 300000, 300000, 300000, 300000, 300000, 300000, 300000, 500000, 500000, 500000 }

-- 숙련도: 그 권법으로 맞힐 때마다 오른다. 레벨마다 그 권법 피해 +3%
-- 2.5판: 숙련은 20까지 (각성·승급은 그대로 숙련 10에서). 11부터는 레벨마다 피해 +1%, 오르기는 점점 더디다
Config.MASTERY_MAX = 20
Config.MASTERY_FULL = 10
function Config.masteryNeed(level: number): number
	return math.floor(40 * level ^ 1.5 * (1 + 0.35 * math.max(0, level - 10)))
end
function Config.masteryDmg(lv: number): number
	return 1 + 0.03 * (math.min(lv, 10) - 1) + 0.01 * math.max(0, lv - 10)
end
Config.SKILL_UNLOCK = { E = 1, R = 3, G = 5, X = 5 }
-- 초 오의 (초월 권법의 X): 오의보다 이만큼 더 세다
-- 매화·벚꽃 꽃잎: 마지막으로 때린 뒤 6초 (가득 차면 15초) 남아 있다가 1초에 3잎씩 진다
Config.PETAL_KEEP = 6
Config.PETAL_KEEP_FULL = 15
Config.PETAL_DRAIN = 3
Config.SUPER_ULT_MULT = 1.6

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
-- alt: 극 권법의 황혼 (일월극변) 동안이면 바뀐 기술을 돌려준다
function Config.move(styleId: string, slot: any, alt: boolean?): any
	local s = Config.STYLE_BY_ID[styleId]
	if not s then
		return nil
	end
	local tw = alt and s.twilight
	if type(slot) == "number" then
		return s.combo[slot]
	elseif slot == "H" then
		return tw and tw.heavy or s.heavy
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
	return tw and tw.skills[slot] or s.skills[slot]
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
	-- 3.9판 큰 목인: 권법 시험장의 큰 허수아비 (보스만 한 몸집)
	bigdummy = {
		name = "큰 수련 목인", dummy = true, hp = 1000000000, posture = 100000000, speed = 0, aggro = 0, keep = 0, scale = 3.2,
		shirt = Color3.fromRGB(130, 96, 62), pants = Color3.fromRGB(96, 70, 46), coins = 0, xp = 0, moves = {},
	},
	thug = {
		-- 3.9판: 처음 싸우는 적이라 훨씬 순하게 (체력 55 → 34, 피해 거의 반, 덤비는 거리 38 → 24, 휘두르기 전 틈이 길다)
		name = "무뢰배", weapon = "staff", hp = 34, posture = 36, speed = 12, aggro = 24, keep = 5, shirt = Color3.fromRGB(150, 130, 100), pants = Color3.fromRGB(80, 70, 55),
		coins = 6, xp = 5,
		moves = {
			{ id = "t1", name = "몽둥이질", pose = "w_slash", windup = 0.75, dur = 1.05, range = 6, hits = { hit(0.75, 6, 4, 4, 6, 0.3, 8) } },
			{ id = "t2", name = "내려치기", pose = "w_overhead", windup = 1.0, dur = 1.4, range = 6, unblockable = true, hits = { hit(1.0, 6, 4.5, 7, 12, 0.5, 16) } },
		},
	},
	bandit = {
		name = "산적 도객", weapon = "saber", hp = 72, posture = 60, speed = 14, aggro = 36, keep = 5, shirt = Color3.fromRGB(120, 90, 60), pants = Color3.fromRGB(60, 50, 40),
		coins = 12, xp = 8,
		moves = {
			{ id = "b1", name = "베기", pose = "w_slash", windup = 0.55, dur = 0.9, range = 6, hits = { hit(0.55, 6, 4, 7, 10, 0.35, 10) } },
			{ id = "b2", name = "연속 베기", pose = "w_slash2", windup = 0.5, dur = 1.2, range = 6, hits = { hit(0.5, 6, 4, 5, 8, 0.3, 6), hit(0.8, 6, 4, 6, 9, 0.35, 12) } },
			{ id = "b3", name = "내려찍기", pose = "w_overhead", windup = 0.85, dur = 1.3, range = 6, unblockable = true, hits = { hit(0.85, 6, 4.5, 13, 22, 0.6, 25) } },
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
-- 관문 수호자: 경지의 관문을 지키는 그림자 무인 (심마를 바탕으로)
E.gatekeeper = variant(E.simma, { name = "관문 수호자", shirt = Color3.fromRGB(60, 50, 30), pants = Color3.fromRGB(30, 25, 15), scale = 1.3, coins = 500, xp = 200, duel = true })
-- 2.9판: 윤회의 시련의 전생의 그림자 (지난 삶의 나)
E.samsara = variant(E.simma, { name = "전생의 그림자", shirt = Color3.fromRGB(70, 30, 90), pants = Color3.fromRGB(25, 10, 35), scale = 1.35, coins = 2000, xp = 600, duel = true })
E.iceguard = variant(E.ironguard, { name = "빙궁 무사", shirt = Color3.fromRGB(170, 210, 235), pants = Color3.fromRGB(90, 120, 150), hp = 260 })
E.snowblade = variant(E.assassin, { name = "설원 자객", shirt = Color3.fromRGB(230, 235, 245), pants = Color3.fromRGB(150, 160, 175), hp = 95 })
E.swampfang = variant(E.shadowblade, { name = "독수 자객", shirt = Color3.fromRGB(60, 90, 50), pants = Color3.fromRGB(35, 50, 30) })
E.bogbrute = variant(E.brute, { name = "늪 거한", shirt = Color3.fromRGB(80, 95, 60), pants = Color3.fromRGB(50, 55, 40), hp = 200, scale = 1.4 })
E.marauder = variant(E.bandit, { name = "마적", shirt = Color3.fromRGB(150, 90, 50), pants = Color3.fromRGB(90, 60, 40), hp = 130, speed = 17, elite = true })
E.lancer = variant(E.spearman, { name = "황야 창수", shirt = Color3.fromRGB(170, 120, 70), pants = Color3.fromRGB(100, 70, 45), hp = 140 })
E.pirate = variant(E.bandit, { name = "해적 도객", shirt = Color3.fromRGB(50, 70, 110), pants = Color3.fromRGB(40, 40, 50), hp = 120 })
E.cultist = variant(E.bandit, { name = "혈교도", shirt = Color3.fromRGB(110, 15, 25), pants = Color3.fromRGB(30, 10, 12), hp = 150, speed = 17 })
E.cultelder = variant(E.shadowblade, { name = "혈교 장로", shirt = Color3.fromRGB(60, 10, 15), pants = Color3.fromRGB(20, 5, 8), hp = 260, scale = 1.15 })
E.cultguard = variant(E.cultelder, { name = "혈교 호법", shirt = Color3.fromRGB(90, 12, 20), pants = Color3.fromRGB(30, 6, 10), hp = 280, mult = 2.4, scale = 1.25, coins = 140, xp = 60 })
-- 허공 균열 (북서쪽 끝): 사경 이후의 적. mult = 체력·피해를 겹으로 더 세게
E.riftling = variant(E.assassin, { name = "균열 마물", shirt = Color3.fromRGB(80, 50, 120), pants = Color3.fromRGB(40, 25, 60), hp = 90, mult = 4 })
-- 3.2.6판: 사경의 사냥터 (전투력 1500~2300이 비어 있었다). 균열 어귀의 야차와 혈교 본산 깊은 곳의 호법
E.riftyaksha = variant(E.riftling, { name = "균열 야차", shirt = Color3.fromRGB(110, 40, 90), pants = Color3.fromRGB(50, 20, 45), hp = 110, mult = 6, scale = 1.1 })
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
-- 천상계 (세계 2)의 적: 땅의 적보다 한참 세다
E.cloudguard = variant(E.spearman, { name = "운병", shirt = Color3.fromRGB(235, 240, 250), pants = Color3.fromRGB(160, 180, 220), hp = 320, mult = 14, elite = true })
E.cranesword = variant(E.assassin, { name = "학익 검객", shirt = Color3.fromRGB(245, 245, 245), pants = Color3.fromRGB(40, 40, 50), hp = 240, mult = 14, elite = true })
E.thunderguard = variant(E.ironguard, { name = "뇌신병", shirt = Color3.fromRGB(70, 80, 140), pants = Color3.fromRGB(40, 45, 80), hp = 340, mult = 16, elite = true })
E.thunderimp = variant(E.assassin, { name = "뇌령", shirt = Color3.fromRGB(150, 170, 255), pants = Color3.fromRGB(60, 70, 140), hp = 230, mult = 16 })
E.starspirit = variant(E.shadowblade, { name = "성령", shirt = Color3.fromRGB(120, 90, 200), pants = Color3.fromRGB(40, 30, 80), hp = 260, mult = 18, elite = true })
E.starsage = variant(E.cultelder, { name = "성운 도사", shirt = Color3.fromRGB(70, 50, 140), pants = Color3.fromRGB(30, 20, 60), hp = 280, mult = 18, elite = true })
E.throneguard = variant(E.ironguard, { name = "천위병", shirt = Color3.fromRGB(250, 235, 190), pants = Color3.fromRGB(180, 150, 80), hp = 380, mult = 20, elite = true, scale = 1.3 })
E.meteorguard = variant(E.stonegolem, { name = "운석 수호수", shirt = Color3.fromRGB(90, 60, 120), pants = Color3.fromRGB(50, 30, 70), hp = 900, mult = 16, elite = true, scale = 1.8 })
E.throneblade = variant(E.shadowblade, { name = "천위 검객", shirt = Color3.fromRGB(255, 245, 220), pants = Color3.fromRGB(150, 120, 60), hp = 300, mult = 20, elite = true })
-- 1.7판: 새 섬의 적 (옥좌대보다 한 단계, 두 단계 위)
E.frostguard = variant(E.spearman, { name = "빙정 수위", shirt = Color3.fromRGB(200, 230, 255), pants = Color3.fromRGB(90, 130, 180), hp = 400, mult = 23, elite = true, scale = 1.2 })
E.icespirit = variant(E.shadowblade, { name = "얼음 정령", shirt = Color3.fromRGB(170, 230, 255), pants = Color3.fromRGB(110, 170, 220), hp = 320, mult = 23, elite = true })
E.waterspirit = variant(E.shadowblade, { name = "물보라 정령", shirt = Color3.fromRGB(140, 200, 255), pants = Color3.fromRGB(60, 110, 170), hp = 330, mult = 24, elite = true })
E.fallsguard = variant(E.spearman, { name = "폭포 수문장", shirt = Color3.fromRGB(80, 130, 110), pants = Color3.fromRGB(40, 70, 60), hp = 410, mult = 24, elite = true, scale = 1.2 })
E.craneguard = variant(E.spearman, { name = "학익 위사", shirt = Color3.fromRGB(250, 250, 250), pants = Color3.fromRGB(30, 30, 40), hp = 450, mult = 28, elite = true, scale = 1.2 })
E.cranemaster = variant(E.assassin, { name = "청학 검선", shirt = Color3.fromRGB(240, 245, 240), pants = Color3.fromRGB(60, 120, 100), hp = 360, mult = 28, elite = true })
E.phoenixguard = variant(E.ironguard, { name = "봉황 무사", shirt = Color3.fromRGB(220, 70, 40), pants = Color3.fromRGB(120, 40, 20), hp = 440, mult = 27, elite = true, scale = 1.3 })
-- 2.7판: 천상의 새 세 섬 (청학봉과 같거나 조금 위)
E.jukgeom = variant(E.assassin, { name = "죽림 검객", shirt = Color3.fromRGB(110, 150, 90), pants = Color3.fromRGB(50, 70, 40), hp = 380, mult = 30, elite = true })
E.jukseon = variant(E.cultelder, { name = "죽림 선인", shirt = Color3.fromRGB(200, 215, 170), pants = Color3.fromRGB(80, 100, 60), hp = 420, mult = 30, elite = true, scale = 1.1 })
E.moonspirit = variant(E.shadowblade, { name = "월광 정령", shirt = Color3.fromRGB(220, 230, 255), pants = Color3.fromRGB(140, 150, 200), hp = 380, mult = 31, elite = true })
E.lakeguard = variant(E.spearman, { name = "호수 수호병", shirt = Color3.fromRGB(70, 90, 130), pants = Color3.fromRGB(30, 40, 70), hp = 480, mult = 31, elite = true, scale = 1.2 })
E.goldmonk = variant(E.brute, { name = "금운 무승", shirt = Color3.fromRGB(230, 170, 60), pants = Color3.fromRGB(140, 80, 30), hp = 520, mult = 34, elite = true, scale = 1.2 })
E.guardlion = variant(E.brute, { name = "사자 수호수", shirt = Color3.fromRGB(220, 180, 90), pants = Color3.fromRGB(170, 120, 50), hp = 640, mult = 34, elite = true, scale = 1.5, weapon = "none" })
-- 1.8판: 세상 끝 네 땅의 적
E.mapleblade = variant(E.shadowblade, { name = "단풍 검객", shirt = Color3.fromRGB(210, 90, 40), pants = Color3.fromRGB(90, 40, 25), hp = 230, mult = 14 })
E.maplemonk = variant(E.brute, { name = "낙엽 승병", shirt = Color3.fromRGB(180, 120, 50), pants = Color3.fromRGB(80, 55, 30), hp = 300, scale = 1.4, mult = 14, elite = true })
E.karstsprite = variant(E.assassin, { name = "석림 정령", shirt = Color3.fromRGB(170, 170, 160), pants = Color3.fromRGB(110, 110, 100), hp = 220, mult = 15 })
E.stonewarden = variant(E.stonegolem, { name = "석림 수호석", shirt = Color3.fromRGB(150, 150, 140), pants = Color3.fromRGB(100, 100, 95), hp = 420, scale = 2, mult = 15, elite = true })
E.sporeimp = variant(E.assassin, { name = "포자 귀졸", shirt = Color3.fromRGB(150, 90, 200), pants = Color3.fromRGB(70, 40, 90), hp = 230, mult = 16 })
E.shroombrute = variant(E.brute, { name = "버섯 거한", shirt = Color3.fromRGB(190, 60, 60), pants = Color3.fromRGB(240, 230, 210), hp = 360, scale = 1.8, speed = 12, mult = 16, elite = true })
E.teaguard = variant(E.spearman, { name = "차밭 지기", shirt = Color3.fromRGB(110, 160, 90), pants = Color3.fromRGB(60, 80, 50), hp = 250, mult = 17 })
E.teasage = variant(E.cultelder, { name = "운무 다인", shirt = Color3.fromRGB(220, 235, 210), pants = Color3.fromRGB(90, 120, 80), hp = 280, mult = 17, elite = true })
E.flamesage = variant(E.cultelder, { name = "불새 술사", shirt = Color3.fromRGB(255, 150, 60), pants = Color3.fromRGB(150, 60, 20), hp = 340, mult = 27, elite = true })
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
boss("heukho", { hp = 2200, scale = 2.4, reach = 1.5, patterns = {
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

-- 초월의 시련: 천앵선이 직접, 보스처럼 세 단계로 싸운다 (벚꽃비 → 화륜 → 만개)
for _, st in ipairs(Config.Styles) do
	if st.id == "chomaehwa" then
		local pink = Color3.fromRGB(255, 150, 200)
		st.trialIntro = { title = "초월의 시련", text = "매화를 넘어서겠다고? 그럼 꽃이 지는 모습을 끝까지 보아라. 세 번 피고 세 번 질 때까지 서 있다면 이 부채를 넘겨주지." }
		st.trialBoss = { hp = 3600, posture = 760, scale = 1.6, reach = 1.4, speed = 24, patterns = {
			P("rain", "벚꽃비", 1, { count = 7, radius = 7, spread = 22, warn = 0.9, cd = 6, pose = "fan_dance", fx = "star", color = pink, hit = hit(0, 0, 0, 32, 36, 0.7, 20) }),
			P("donut", "화륜", 1, { inner = 7, outer = 24, warn = 1.0, cd = 8, pose = "fan_twirl", hit = hit(0, 0, 0, 40, 50, 0.9, 40) }),
			P("charge", "앵선돌진", 2, { length = 52, width = 8, warn = 0.7, cd = 6, times = 3, pose = "fan_dash", hit = hit(0, 0, 0, 36, 44, 0.8, 50) }),
			P("rain", "낙화난무", 2, { count = 10, radius = 6, spread = 26, warn = 0.8, cd = 6, pose = "fan_dance", fx = "star", color = Color3.fromRGB(255, 235, 245), hit = hit(0, 0, 0, 28, 34, 0.7, 20) }),
			P("leap", "천앵낙하", 3, { radius = 18, warn = 0.9, cd = 7, pose = "ult_sakura", hit = hit(0, 0, 0, 52, 72, 1.1, 45, 20) }),
			P("quake", "만개", 3, { radius = 27, warn = 1.3, cd = 9, pose = "ult_sever", hit = hit(0, 0, 0, 74, 104, 1.4, 60, 24) }),
		} }
	end
end

-- 3.1판 극의 시련: 황혼권존이 직접 (해의 비 → 달의 고리 → 일식). 일월신권의 권존보다 훨씬 세다
for _, st in ipairs(Config.Styles) do
	if st.id == "geukilwol" then
		local sun, moon = Color3.fromRGB(255, 170, 60), Color3.fromRGB(190, 210, 255)
		st.trialIntro = { title = "극의 시련", text = "세 번을 죽고 세 번을 살았구나. 그래도 해와 달은 아직 너를 모른다. 내 황혼을 끝까지 버텨 보아라. 해가 지고 달이 뜨는 그 사이에 서 있을 수 있다면, 극을 넘겨주마." }
		st.trialBoss = { hp = 5200, posture = 900, scale = 1.7, reach = 1.5, speed = 26, patterns = {
			P("rain", "해의 비", 1, { count = 9, radius = 8, spread = 26, warn = 0.9, cd = 6, pose = "sun_call", fx = "star", color = sun, hit = hit(0, 0, 0, 40, 44, 0.8, 22) }),
			P("donut", "달의 고리", 1, { inner = 8, outer = 28, warn = 1.0, cd = 7, pose = "moon_seal", hit = hit(0, 0, 0, 48, 58, 0.9, 40) }),
			P("charge", "일월환보", 2, { length = 56, width = 9, warn = 0.65, cd = 6, times = 3, pose = "sun_wheel", hit = hit(0, 0, 0, 44, 52, 0.9, 50) }),
			P("rain", "월광우", 2, { count = 12, radius = 6, spread = 28, warn = 0.8, cd = 6, pose = "moon_throw", fx = "star", color = moon, hit = hit(0, 0, 0, 34, 40, 0.7, 20) }),
			P("leap", "대일낙하", 3, { radius = 20, warn = 0.9, cd = 7, pose = "eclipse_push", hit = hit(0, 0, 0, 64, 84, 1.2, 50, 22) }),
			P("quake", "황혼", 3, { radius = 30, warn = 1.2, cd = 8, pose = "ult_eclipse", hit = hit(0, 0, 0, 90, 120, 1.5, 60, 26) }),
		} }
	end
end

-- 초월의 시련: 만취선이 직접 (술비 → 굴렁쇠 → 만취)
for _, st in ipairs(Config.Styles) do
	if st.id == "chochwi" then
		local green = Color3.fromRGB(90, 220, 120)
		st.trialIntro = { title = "초월의 시련", text = "어이, 거기. 한 잔 받을 텐가? 싫으면 덤벼 보게. 내가 쓰러지는 걸 보면 이 병을 넘겨주지. 근데 난 안 쓰러져. 끄억." }
		st.trialBoss = { hp = 3600, posture = 760, scale = 1.6, reach = 1.4, speed = 24, patterns = {
			P("rain", "술비", 1, { count = 7, radius = 7, spread = 22, warn = 0.9, cd = 6, pose = "soju_throw", fx = "fire", color = green, hit = hit(0, 0, 0, 32, 36, 0.7, 20) }),
			P("donut", "취선 회오리", 1, { inner = 7, outer = 24, warn = 1.0, cd = 8, pose = "soju_fallkick", hit = hit(0, 0, 0, 40, 50, 0.9, 40) }),
			P("charge", "굴렁쇠", 2, { length = 52, width = 8, warn = 0.7, cd = 6, times = 3, pose = "drunk_roll", hit = hit(0, 0, 0, 36, 44, 0.8, 50) }),
			P("rain", "취화", 2, { count = 10, radius = 6, spread = 26, warn = 0.8, cd = 6, pose = "soju_spray", fx = "fire", color = Color3.fromRGB(180, 255, 200), hit = hit(0, 0, 0, 28, 34, 0.7, 20) }),
			P("leap", "술병 내려찍기", 3, { radius = 18, warn = 0.9, cd = 7, pose = "soju_smash", hit = hit(0, 0, 0, 52, 72, 1.1, 45, 20) }),
			P("quake", "만취", 3, { radius = 27, warn = 1.3, cd = 9, pose = "soju_rolls", hit = hit(0, 0, 0, 74, 104, 1.4, 60, 24) }),
		} }
	end
end

-- 1.9판 초월의 시련: 혈월선이 직접 (핏빛 비 → 낫 돌진 → 혈월)
for _, st in ipairs(Config.Styles) do
	if st.id == "chohyeolma" then
		local red = Color3.fromRGB(230, 30, 45)
		st.trialIntro = { title = "초월의 시련", text = "혈마의 손을 쥐었다고? 그 손톱은 아직 짧다. 내 낫 앞에서 피를 흘려 보아라. 끝까지 서 있으면, 이 낫이 너를 주인으로 고를 것이다." }
		st.trialBoss = { hp = 3800, posture = 780, scale = 1.6, reach = 1.6, speed = 24, patterns = {
			P("rain", "핏빛 초승달", 1, { count = 7, radius = 7, spread = 22, warn = 0.9, cd = 6, pose = "reap_hook", fx = "fire", color = red, hit = hit(0, 0, 0, 32, 36, 0.7, 20) }),
			P("donut", "혈륜", 1, { inner = 7, outer = 25, warn = 1.0, cd = 8, pose = "reap_spin", hit = hit(0, 0, 0, 42, 52, 0.9, 40) }),
			P("charge", "혈겸 돌진", 2, { length = 54, width = 9, warn = 0.7, cd = 6, times = 3, pose = "reap_wave", hit = hit(0, 0, 0, 38, 46, 0.8, 50) }),
			P("rain", "피의 비", 2, { count = 10, radius = 6, spread = 26, warn = 0.8, cd = 6, pose = "ult_reap", fx = "fire", color = Color3.fromRGB(255, 120, 120), hit = hit(0, 0, 0, 28, 34, 0.7, 20) }),
			P("leap", "참수", 3, { radius = 18, warn = 0.9, cd = 7, pose = "reap_leap", hit = hit(0, 0, 0, 54, 74, 1.1, 45, 20) }),
			P("quake", "혈월", 3, { radius = 28, warn = 1.3, cd = 9, pose = "reap_moon", hit = hit(0, 0, 0, 76, 106, 1.4, 60, 24) }),
		} }
	end
end

-- 2.4판 만목신권의 시련: 목선이 직접 (가시 비 → 뿌리 고리 → 숲의 분노)
for _, st in ipairs(Config.Styles) do
	if st.id == "manmok" then
		local green = Color3.fromRGB(120, 220, 110)
		st.trialIntro = { title = "목선의 시련", text = "숲은 쓰러뜨리는 것이 아니다. 버티는 것이다. 내 대숲의 창과 잎 속에서 끝까지 서 있거든, 나무의 주먹을 가르쳐 주마." }
		st.trialBoss = { hp = 3400, posture = 760, scale = 1.5, reach = 1.4, speed = 22, patterns = {
			P("rain", "죽창 비", 1, { count = 9, radius = 6, spread = 24, warn = 0.9, cd = 6, pose = "point_sky", fx = "star", color = green, hit = hit(0, 0, 0, 30, 34, 0.8, 16) }),
			P("donut", "대숲 고리", 1, { inner = 8, outer = 24, warn = 1.0, cd = 8, pose = "grav_hammer", hit = hit(0, 0, 0, 40, 50, 1.0, 30) }),
			P("leap", "고목 내리치기", 2, { radius = 16, warn = 1.0, cd = 7, pose = "grav_hammer", hit = hit(0, 0, 0, 50, 70, 1.1, 40, 18) }),
			P("rain", "은행잎 폭풍", 2, { count = 12, radius = 6, spread = 28, warn = 0.8, cd = 6, pose = "point_sky", fx = "star", color = Color3.fromRGB(255, 240, 150), hit = hit(0, 0, 0, 26, 30, 0.7, 14) }),
			P("quake", "숲의 분노", 3, { radius = 28, warn = 1.3, cd = 9, pose = "ult_origin", hit = hit(0, 0, 0, 74, 100, 1.4, 50, 24) }),
		} }
	end
end

-- 2.0판 초월의 시련: 뇌천선이 직접 (벼락 비 → 뇌광 돌진 → 구천뇌정)
for _, st in ipairs(Config.Styles) do
	if st.id == "chochanghae" then
		local sea = Color3.fromRGB(90, 200, 240)
		st.trialIntro = { title = "초월의 시련", text = "파도를 일으킬 줄 안다고 바다가 되는 건 아니다. 내 바다 한가운데서 끝까지 숨을 쉬거든, 고래의 노래를 가르쳐 주마." }
		st.trialBoss = { hp = 3800, posture = 780, scale = 1.6, reach = 1.5, speed = 24, patterns = {
			P("rain", "물방울 비", 1, { count = 9, radius = 6, spread = 24, warn = 0.8, cd = 6, pose = "point_sky", fx = "star", color = sea, hit = hit(0, 0, 0, 30, 34, 0.8, 18) }),
			P("donut", "소용돌이 고리", 1, { inner = 7, outer = 25, warn = 1.0, cd = 8, pose = "wall_raise", hit = hit(0, 0, 0, 40, 50, 0.9, 40) }),
			P("charge", "파도타기", 2, { length = 54, width = 9, warn = 0.6, cd = 6, times = 3, pose = "surf_dash", hit = hit(0, 0, 0, 36, 44, 0.8, 50) }),
			P("rain", "해일 비", 2, { count = 12, radius = 6, spread = 27, warn = 0.7, cd = 6, pose = "point_sky", fx = "star", color = Color3.fromRGB(215, 250, 255), hit = hit(0, 0, 0, 28, 32, 0.7, 20) }),
			P("leap", "거경격", 3, { radius = 18, warn = 0.9, cd = 7, pose = "billow_strike", hit = hit(0, 0, 0, 54, 74, 1.1, 45, 20) }),
			P("quake", "고경승천", 3, { radius = 28, warn = 1.3, cd = 9, pose = "ult_tsunami", hit = hit(0, 0, 0, 76, 106, 1.4, 60, 24) }),
		} }
	end
	if st.id == "gongbaek" then
		local red = Color3.fromRGB(230, 40, 60)
		st.trialIntro = { title = "null", text = "...ㄴ...ㅓ...는 누구지. 아니, 나는 누구였지. 내가 지워지기 전에 나를 이겨 봐. 그러면 이 빈칸은 네 것이다." }
		st.trialBoss = { hp = 3700, posture = 780, scale = 1.5, reach = 1.5, speed = 26, patterns = {
			P("rain", "빈칸 비", 1, { count = 10, radius = 6, spread = 24, warn = 0.7, cd = 6, pose = "point_sky", fx = "star", color = Color3.fromRGB(20, 20, 24), hit = hit(0, 0, 0, 30, 34, 0.8, 16) }),
			P("donut", "격자 고리", 1, { inner = 7, outer = 24, warn = 0.9, cd = 8, pose = "void_circle", hit = hit(0, 0, 0, 40, 50, 0.9, 30) }),
			P("charge", "끊김", 2, { length = 52, width = 8, warn = 0.5, cd = 5, times = 4, pose = "void_sink", hit = hit(0, 0, 0, 34, 42, 0.8, 30) }),
			P("rain", "ERROR", 2, { count = 8, radius = 8, spread = 26, warn = 0.8, cd = 7, pose = "point_sky", fx = "star", color = red, hit = hit(0, 0, 0, 36, 40, 0.8, 20) }),
			P("quake", "존재소거", 3, { radius = 28, warn = 1.2, cd = 9, pose = "ult_void", hit = hit(0, 0, 0, 76, 106, 1.4, 50, 24) }),
		} }
	end
	if st.id == "hojeop" then
		local pink = Color3.fromRGB(255, 180, 220)
		st.trialIntro = { title = "꿈의 시련", text = "흐아암... 내 꿈속에서 끝까지 깨어 있거든, 꿈길 걷는 법을 가르쳐 주지. 졸지 마라. 꿈은 생각보다 아프다." }
		st.trialBoss = { hp = 3600, posture = 760, scale = 1.5, reach = 1.4, speed = 22, patterns = {
			P("rain", "잠의 별비", 1, { count = 10, radius = 6, spread = 24, warn = 0.8, cd = 6, pose = "point_sky", fx = "star", color = pink, hit = hit(0, 0, 0, 28, 32, 0.8, 16) }),
			P("donut", "꿈문 고리", 1, { inner = 7, outer = 24, warn = 1.0, cd = 8, pose = "circle_palm", hit = hit(0, 0, 0, 40, 48, 0.9, 30) }),
			P("charge", "몽유 돌진", 2, { length = 50, width = 8, warn = 0.6, cd = 6, times = 3, pose = "dash_strike", hit = hit(0, 0, 0, 34, 42, 0.8, 40) }),
			P("rain", "달 조각", 2, { count = 7, radius = 8, spread = 26, warn = 0.9, cd = 7, pose = "point_sky", fx = "star", color = Color3.fromRGB(180, 220, 255), hit = hit(0, 0, 0, 34, 38, 0.8, 20) }),
			P("quake", "월하몽", 3, { radius = 28, warn = 1.3, cd = 9, pose = "ult_bloom", hit = hit(0, 0, 0, 74, 100, 1.4, 50, 24) }),
		} }
	end
	if st.id == "chosengha" then
		local star = Color3.fromRGB(255, 226, 120)
		st.trialIntro = { title = "초월의 시련", text = "별을 쥐었다고 별을 부리는 건 아니다. 내 별의 돔 아래서 끝까지 서 있거든, 이 지팡이 끝의 별을 네게 걸어 주마." }
		st.trialBoss = { hp = 3800, posture = 780, scale = 1.6, reach = 1.5, speed = 24, patterns = {
			P("rain", "별똥비", 1, { count = 9, radius = 6, spread = 24, warn = 0.8, cd = 6, pose = "point_sky", fx = "star", color = star, hit = hit(0, 0, 0, 30, 34, 0.8, 18) }),
			P("donut", "성좌 고리", 1, { inner = 7, outer = 25, warn = 1.0, cd = 8, pose = "staff_sigil", hit = hit(0, 0, 0, 40, 50, 0.9, 40) }),
			P("charge", "유성장", 2, { length = 52, width = 8, warn = 0.6, cd = 6, times = 3, pose = "staff_thrust", hit = hit(0, 0, 0, 36, 44, 0.8, 50) }),
			P("rain", "메테오", 2, { count = 6, radius = 9, spread = 26, warn = 0.9, cd = 7, pose = "point_sky", fx = "star", color = Color3.fromRGB(150, 120, 255), hit = hit(0, 0, 0, 36, 40, 0.8, 24) }),
			P("leap", "낙성추", 3, { radius = 18, warn = 0.9, cd = 7, pose = "staff_slam", hit = hit(0, 0, 0, 54, 74, 1.1, 45, 20) }),
			P("quake", "성천궁", 3, { radius = 28, warn = 1.3, cd = 9, pose = "staff_dome", hit = hit(0, 0, 0, 76, 106, 1.4, 60, 24) }),
		} }
	end
	if st.id == "chobyeok" then
		local violet = Color3.fromRGB(170, 130, 255)
		st.trialIntro = { title = "초월의 시련", text = "번개를 쥐었다고 번개가 되는 건 아니다. 내 벼락을 세 번 맞고도 서 있거든, 이 토시를 네 팔에 채워 주마." }
		st.trialBoss = { hp = 3800, posture = 780, scale = 1.6, reach = 1.5, speed = 26, patterns = {
			P("rain", "벼락 비", 1, { count = 8, radius = 6, spread = 24, warn = 0.8, cd = 6, pose = "point_sky", fx = "star", color = violet, hit = hit(0, 0, 0, 32, 36, 0.8, 20) }),
			P("donut", "뇌전 고리", 1, { inner = 7, outer = 25, warn = 1.0, cd = 8, pose = "thunder_hammer", hit = hit(0, 0, 0, 42, 52, 0.9, 40) }),
			P("charge", "뇌광 돌진", 2, { length = 56, width = 8, warn = 0.6, cd = 6, times = 3, pose = "lightning_dash", hit = hit(0, 0, 0, 38, 46, 0.8, 50) }),
			P("rain", "천뢰", 2, { count = 11, radius = 6, spread = 26, warn = 0.7, cd = 6, pose = "point_sky", fx = "star", color = Color3.fromRGB(255, 245, 170), hit = hit(0, 0, 0, 28, 34, 0.7, 20) }),
			P("leap", "벽력천추", 3, { radius = 18, warn = 0.9, cd = 7, pose = "thunder_hammer", hit = hit(0, 0, 0, 54, 74, 1.1, 45, 20) }),
			P("quake", "구천뇌정", 3, { radius = 28, warn = 1.3, cd = 9, pose = "ult_thunder", hit = hit(0, 0, 0, 76, 106, 1.4, 60, 24) }),
		} }
	end
end

-- 일월의 시련: 권존이 분신 없이 직접, 보스처럼 세 단계로 싸운다 (한낮 → 밤 → 새벽)
for _, st in ipairs(Config.Styles) do
	if st.id == "ilwol" then
		st.trialBoss = { hp = 3200, posture = 720, scale = 1.9, reach = 1.5, speed = 21, patterns = {
			P("rain", "대일낙하", 1, { count = 6, radius = 8, spread = 22, warn = 1.0, cd = 7, pose = "sun_call", fx = "fire", color = Color3.fromRGB(255, 185, 60), hit = hit(0, 0, 0, 34, 40, 0.8, 20) }),
			P("donut", "만월 고리", 1, { inner = 8, outer = 26, warn = 1.1, cd = 8, pose = "moon_throw", hit = hit(0, 0, 0, 40, 50, 0.9, 40) }),
			P("charge", "월광 돌진", 2, { length = 50, width = 9, warn = 0.8, cd = 7, times = 3, pose = "moon_seal", hit = hit(0, 0, 0, 36, 44, 0.8, 50) }),
			P("rain", "월하 낙성", 2, { count = 8, radius = 7, spread = 24, warn = 0.9, cd = 7, pose = "sun_call", fx = "star", color = Color3.fromRGB(205, 220, 255), hit = hit(0, 0, 0, 30, 36, 0.7, 20) }),
			P("leap", "일륜 낙하", 3, { radius = 17, warn = 1.0, cd = 7, pose = "sun_wheel", hit = hit(0, 0, 0, 50, 70, 1.1, 45, 20) }),
			P("quake", "일식", 3, { radius = 26, warn = 1.4, cd = 9, pose = "ult_eclipse", hit = hit(0, 0, 0, 70, 100, 1.4, 60, 24) }),
		} }
	end
end

-- 2.7.6판: 일월신권의 밤 (18시~6시). 해의 금빛이 달의 은빛으로, ☀가 🌙로, 해의 기술은 달의 기술로 이름이 바뀐다.
-- 낮과 밤은 온 세상이 같으니 모든 화면이 함께 바뀐다 (화면이 Config.setIlwolNight를 부른다)
local function ilwolMoves(st: any): { any }
	local list = {}
	for _, m in ipairs(st.combo or {}) do
		table.insert(list, m)
	end
	if st.heavy then
		table.insert(list, st.heavy)
	end
	for _, m in pairs(st.skills or {}) do
		table.insert(list, m)
	end
	return list
end
for _, st in ipairs(Config.Styles) do
	if st.id == "ilwol" then
		st.dayTheme = { color = st.color, color2 = st.color2, icon = st.icon, names = {}, descs = {} }
		st.nightTheme = {
			color = Color3.fromRGB(175, 200, 255),
			color2 = Color3.fromRGB(130, 110, 235),
			icon = "🌙",
			names = { iw1 = "월출장", iw3 = "월륜각", iwH = "월영합벽", iwR = "월광낙하" },
			descs = { iwR = "둘레의 적 여섯 머리 위로 작은 달이 떨어져 차가운 달빛 기둥이 되어 터진다" },
		}
		for _, m in ipairs(ilwolMoves(st)) do
			st.dayTheme.names[m.id] = m.name
			st.dayTheme.descs[m.id] = m.desc
		end
	end
end
function Config.isNightClock(h: number): boolean
	return h < 6 or h >= 18
end
function Config.setIlwolNight(night: boolean)
	for _, st in ipairs(Config.Styles) do
		if st.id == "ilwol" and st.dayTheme and st.night ~= night then
			st.night = night
			local th = night and st.nightTheme or st.dayTheme
			st.color, st.color2, st.icon = th.color, th.color2, th.icon
			for _, m in ipairs(ilwolMoves(st)) do
				m.name = (night and st.nightTheme.names[m.id]) or st.dayTheme.names[m.id] or m.name
				m.desc = (night and st.nightTheme.descs[m.id]) or st.dayTheme.descs[m.id] or m.desc
			end
		end
	end
end

------------------------------------------------------------------------
-- 월드: 가운데 마을, 서쪽 대나무 숲, 북쪽 산적 소굴, 동쪽 폭포 계곡
-- 적은 근처에 사람이 있을 때만 움직인다
------------------------------------------------------------------------
Config.Regions = {
	{ id = "village", name = "청운 마을", center = Vector3.new(0, 0, 0), size = Vector3.new(480, 0, 480), ground = Color3.fromRGB(150, 135, 105), material = Enum.Material.Ground, safe = true },
	{ id = "bamboo", name = "대나무 숲", center = Vector3.new(-480, 0, 0), size = Vector3.new(480, 0, 440), ground = Color3.fromRGB(95, 130, 70), material = Enum.Material.Grass,
		camps = { { enemy = "bandit", count = 3, at = Vector3.new(-300, 0, 120) }, { enemy = "bandit", count = 2, at = Vector3.new(-330, 0, -110) }, { enemy = "spearman", count = 3, at = Vector3.new(-570, 0, -110) } } },
	-- 먼 북쪽의 산적 소굴 (강한 적과 두목)
	{ id = "fort", name = "흑호채 (산적 소굴)", center = Vector3.new(0, 0, -900), size = Vector3.new(440, 0, 480), ground = Color3.fromRGB(110, 90, 70), material = Enum.Material.Mud,
		camps = { { enemy = "spearman", count = 3, at = Vector3.new(0, 0, -790) }, { enemy = "brute", count = 3, at = Vector3.new(90, 0, -880) }, { enemy = "ironguard", count = 2, at = Vector3.new(-90, 0, -880) } },
		boss = { id = "heukho", at = Vector3.new(0, 0, -1020) } },
	{ id = "valley", name = "비류 폭포 계곡", center = Vector3.new(480, 0, 0), size = Vector3.new(480, 0, 440), ground = Color3.fromRGB(85, 120, 95), material = Enum.Material.Grass,
		camps = { { enemy = "bandit", count = 3, at = Vector3.new(320, 0, 130) }, { enemy = "assassin", count = 2, at = Vector3.new(540, 0, 120) }, { enemy = "assassin", count = 2, at = Vector3.new(540, 0, -90) } } },
	-- 마을 남쪽 들판: 처음 싸워 보기 좋은 무뢰배
	{ id = "dojo", name = "상급 수련장", center = Vector3.new(330, 0, -330), size = Vector3.new(170, 0, 170), ground = Color3.fromRGB(165, 150, 125), material = Enum.Material.Cobblestone, safe = true },
	{ id = "field", name = "청운 들판", center = Vector3.new(0, 0, 400), size = Vector3.new(340, 0, 220), ground = Color3.fromRGB(125, 150, 85), material = Enum.Material.Grass,
		camps = { { enemy = "thug", count = 3, at = Vector3.new(-120, 0, 360) }, { enemy = "thug", count = 3, at = Vector3.new(130, 0, 400) }, { enemy = "thug", count = 2, at = Vector3.new(0, 0, 460) } } },
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
		camps = { { enemy = "cultist", count = 4, at = Vector3.new(1600, 0, -1550) }, { enemy = "cultist", count = 3, at = Vector3.new(1850, 0, -1600) }, { enemy = "cultelder", count = 2, at = Vector3.new(1700, 0, -1800) }, { enemy = "cultelder", count = 2, at = Vector3.new(1850, 0, -1850) },
			{ enemy = "cultguard", count = 2, at = Vector3.new(1560, 0, -1960) }, { enemy = "cultguard", count = 2, at = Vector3.new(2000, 0, -1700) } },
		boss = { id = "hyeolma", at = Vector3.new(1800, 0, -1950) } },
	{ id = "rift", name = "허공 균열", center = Vector3.new(-1750, 0, -1750), size = Vector3.new(700, 0, 700), ground = Color3.fromRGB(35, 25, 55), material = Enum.Material.Slate, ambient = "rift",
		camps = { { enemy = "riftling", count = 4, at = Vector3.new(-1500, 0, -1500) }, { enemy = "riftling", count = 3, at = Vector3.new(-1650, 0, -1450) }, { enemy = "riftyaksha", count = 3, at = Vector3.new(-1420, 0, -1650) }, { enemy = "riftyaksha", count = 2, at = Vector3.new(-1650, 0, -1600) },
			{ enemy = "voidwalker", count = 3, at = Vector3.new(-1550, 0, -1700) },
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
	-- 창해각: 서해 남쪽 바닷가의 사당 (창해신권의 사부)
	{ id = "seashrine", name = "창해각 (바다 사당)", center = Vector3.new(-1700, 0, 950), size = Vector3.new(260, 0, 260), ground = Color3.fromRGB(190, 185, 150), material = Enum.Material.Sand, safe = true,
		master = "changhae", rumor = "서해 절벽 남쪽 바닷가 사당에 파도와 함께 숨 쉬는 노인이 있다더라", quote = "바다는 막지 않는다. 덮을 뿐이다.", masterName = "창해옹", masterAt = Vector3.new(-1700, 2.2, 950) },
	-- 불 제단: 붉은 황야 동쪽, 꺼지지 않는 불 (열화신권의 사부)
	{ id = "fireshrine", name = "염화단 (불 제단)", center = Vector3.new(2300, 0, 250), size = Vector3.new(240, 0, 240), ground = Color3.fromRGB(95, 60, 50), material = Enum.Material.Basalt, safe = true,
		master = "yeolhwa", rumor = "동쪽 붉은 황야 너머, 꺼지지 않는 불 제단에 불을 다루는 노장이 산다더라", quote = "불은 묻지 않는다. 다 태울 뿐이다.", masterName = "염백", masterAt = Vector3.new(2300, 3, 250) },
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
	-- 1.8판: 세상 끝 네 귀퉁이의 새 땅 (천외봉보다 한층 위, 천상계 바로 아래의 세기)
	{ id = "maple", name = "단풍산", center = Vector3.new(3200, 0, -3150), size = Vector3.new(1000, 0, 900), ground = Color3.fromRGB(150, 95, 60), material = Enum.Material.LeafyGrass, ambient = "maple",
		camps = { { enemy = "mapleblade", count = 4, at = Vector3.new(2900, 0, -2900) }, { enemy = "maplemonk", count = 3, at = Vector3.new(3450, 0, -2950) }, { enemy = "mapleblade", count = 3, at = Vector3.new(3000, 0, -3400) }, { enemy = "maplemonk", count = 2, at = Vector3.new(3450, 0, -3400) } },
		boss = { id = "pungyeop", at = Vector3.new(3250, 0, -3250) } },
	{ id = "stoneforest", name = "석림", center = Vector3.new(-3300, 0, 1300), size = Vector3.new(900, 0, 1100), ground = Color3.fromRGB(150, 150, 140), material = Enum.Material.Pebble, ambient = "stone",
		camps = { { enemy = "karstsprite", count = 4, at = Vector3.new(-3100, 0, 1000) }, { enemy = "stonewarden", count = 2, at = Vector3.new(-3450, 0, 1000) }, { enemy = "karstsprite", count = 3, at = Vector3.new(-3100, 0, 1600) }, { enemy = "stonewarden", count = 2, at = Vector3.new(-3500, 0, 1550) } },
		boss = { id = "seokwang", at = Vector3.new(-3350, 0, 1300) } },
	{ id = "mushroom", name = "거균림 (버섯 숲)", center = Vector3.new(3350, 0, 2050), size = Vector3.new(900, 0, 1000), ground = Color3.fromRGB(70, 55, 85), material = Enum.Material.Mud, ambient = "mushroom",
		camps = { { enemy = "sporeimp", count = 4, at = Vector3.new(3100, 0, 1750) }, { enemy = "shroombrute", count = 2, at = Vector3.new(3550, 0, 1800) }, { enemy = "sporeimp", count = 3, at = Vector3.new(3150, 0, 2350) }, { enemy = "shroombrute", count = 2, at = Vector3.new(3600, 0, 2300) } },
		boss = { id = "gyunwang", at = Vector3.new(3400, 0, 2100) } },
	{ id = "teafield", name = "운무 차밭", center = Vector3.new(-3300, 0, -3000), size = Vector3.new(900, 0, 900), ground = Color3.fromRGB(95, 140, 80), material = Enum.Material.Grass, ambient = "tea",
		camps = { { enemy = "teaguard", count = 4, at = Vector3.new(-3050, 0, -2800) }, { enemy = "teasage", count = 3, at = Vector3.new(-3550, 0, -2800) }, { enemy = "teaguard", count = 3, at = Vector3.new(-3050, 0, -3250) }, { enemy = "teasage", count = 2, at = Vector3.new(-3550, 0, -3250) } },
		boss = { id = "dason", at = Vector3.new(-3300, 0, -3050) } },
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
-- 궁극의 사부: 천외봉 아래의 시원자. 무극에 오른 자에게만 시험을 허락한다 (지도에 나오지 않는다)
Config.MASTERS.taecho = { name = "시원자", at = Vector3.new(0, 3.2, -3080), region = "천외봉", regionId = "skysea", secret = true,
	quote = "처음에는 아무것도 없었다. 그래서 무엇이든 될 수 있었다.", rumor = "북쪽 끝 구름바다 위, 하늘에 닿은 봉우리 아래에 세상의 처음을 아는 이가 서 있다더라" }
-- 정점의 사부: 동남쪽 끝 일월대의 권존. 태초신권을 익힌 무극의 고수에게만 시험을 허락한다 (지도에 나오지 않는다)
Config.MASTERS.ilwol = { name = "권존", at = Vector3.new(2500, 6.2, 2500), region = "일월대", regionId = "sunmoon", secret = true,
	quote = "해는 지고 달은 뜬다. 나는 늘 그 사이에 서 있었다.", rumor = "동남쪽 세상 끝, 해와 달이 함께 뜨는 단 위에 주먹 하나로 정점에 선 이가 있다더라" }
-- 정점 둘째의 사부: 천 개의 계단 꼭대기, 떠 있는 문 앞의 영겁노인 (지도에 나오지 않는다)
Config.MASTERS.yeonggeop = { name = "영겁노인", at = Vector3.new(-2804, 62.6, -2804), region = "천 개의 계단", regionId = "steps", secret = true,
	quote = "흘러간 것은 돌아오지 않는다. 내가 돌려놓기 전까지는.", rumor = "북서쪽 끝, 구름까지 닿은 천 개의 계단 위에 시간을 멈춘 노인이 서 있다더라" }
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
-- 2.7.7판: 이야기가 게임 전체를 이끈다 (관문·심법·천층탑·숙련·각성 권법·천상·미궁·천상 보스·레이드·환생·초월·권왕). 장이 끼어들어
-- 번호가 바뀌었으니, 예전 기록은 그 장의 이름으로 새 번호를 찾는다 (STORY_V)
Config.STORY_V = 5
-- 3.9판: 4판 장 이름 (튜토리얼과 후반 장이 끼어들어 번호가 바뀌었다)
Config.STORY_TITLES_V4 = { "강호의 문", "들판의 무뢰배", "몸을 만드는 법", "이류의 문턱", "산적의 그림자", "사부를 찾아서", "사부의 시험", "첫 진짜 권법", "손에 익히기", "일류의 벽", "두 번째 사부", "특급에 오르다", "흑호채", "오의를 열어라", "심법 두루마리", "서해의 해적", "더 많은 사부", "천층탑", "혈월곡의 혈랑", "절정에 오르다", "네 번째 권법", "숙련과 각성", "초절정의 몸", "설산의 빙마", "화경에 들다", "첫 깨달음", "혈교의 그림자", "현경의 고요", "혈마", "사경의 문", "생사의 경계", "각성 권법", "천인합일", "천상의 문", "무극에 오르다", "이름 없는 노인", "구름 미궁", "허공 균열", "천마", "깨어난 화염산", "모래 왕릉", "하늘 문지기", "뇌정봉의 뇌제", "천존", "하늘 밖의 하늘", "천공 투기장", "태초", "정점", "환생", "윤회의 공덕", "전생의 그림자", "초월", "천층탑 백 층", "두 번째 삶", "두 번째 그림자", "세 번째 삶", "세 번째 그림자", "네 번째 삶", "마지막 그림자", "권왕", "강호의 전설" }
-- 3.2.6판: 3판 장 이름 (장이 끼어들어 번호가 바뀌었다. 예전 기록은 이 이름으로 새 번호를 찾는다)
Config.STORY_TITLES_V3 = { "강호의 문", "들판의 무뢰배", "몸을 만드는 법", "산적의 그림자", "사부를 찾아서", "사부의 시험", "첫 진짜 권법", "일류의 벽", "경지의 관문", "흑호채", "심법 두루마리", "더 많은 사부", "천층탑", "혈월곡의 혈랑", "절정에 오르다", "숙련과 각성", "설산의 빙마", "혈교의 그림자", "혈마", "생사의 경계", "각성 권법", "천인합일", "천상의 문", "무극에 오르다", "이름 없는 노인", "구름 미궁", "허공 균열", "천마", "깨어난 화염산", "모래 왕릉", "하늘 문지기", "뇌정봉의 뇌제", "천존", "하늘 밖의 하늘", "천공 투기장", "태초", "정점", "환생", "윤회의 공덕", "전생의 그림자", "초월", "천층탑 백 층", "두 번째 삶", "두 번째 그림자", "세 번째 삶", "세 번째 그림자", "네 번째 삶", "마지막 그림자", "권왕", "강호의 전설" }
-- 이름이 바뀐 장 (어느 판 기록이든)
Config.STORY_REMAP_V3 = { ["경지의 관문"] = "특급에 오르다" }
Config.STORY_OLD_TITLES = { "강호의 문", "들판의 무뢰배", "몸을 만드는 법", "산적의 그림자", "사부를 찾아서", "사부의 시험", "첫 진짜 권법", "일류의 벽", "흑호채", "더 많은 사부", "혈월곡의 혈랑", "절정에 오르다", "설산의 빙마", "혈교의 그림자", "혈마", "무극에 오르다", "이름 없는 노인", "허공 균열", "천마", "깨어난 화염산", "모래 왕릉", "하늘 문지기", "하늘 밖의 하늘", "태초", "정점", "강호의 전설" }
-- 2.9판: 권왕 한 장이 환생의 여러 장으로 나뉘었다 (2판 기록의 '권왕'은 그 첫 장으로)
Config.STORY_TITLES_V2 = { "강호의 문", "들판의 무뢰배", "몸을 만드는 법", "산적의 그림자", "사부를 찾아서", "사부의 시험", "첫 진짜 권법", "일류의 벽", "경지의 관문", "흑호채", "심법 두루마리", "더 많은 사부", "천층탑", "혈월곡의 혈랑", "절정에 오르다", "숙련과 각성", "설산의 빙마", "혈교의 그림자", "혈마", "생사의 경계", "각성 권법", "천인합일", "천상의 문", "무극에 오르다", "이름 없는 노인", "구름 미궁", "허공 균열", "천마", "깨어난 화염산", "모래 왕릉", "하늘 문지기", "뇌정봉의 뇌제", "천존", "하늘 밖의 하늘", "천공 투기장", "태초", "정점", "환생", "초월", "천층탑 백 층", "권왕", "강호의 전설" }
Config.STORY_REMAP_V2 = { ["권왕"] = "윤회의 공덕" }
Config.Story = {
	-- 3.2.6판: 초반을 잘게 나눴다 (경지 하나마다 한 장, 권법은 둘째·셋째·넷째를 따로, 숙련 3·5에서 R·G). 능력치 몫은 네 능력치에 각각 붙는다
	{ title = "강호의 문", text = "젊은이, 맨손으로 강호에 나서겠다고? 좋다. 우선 기본부터. 삼재권은 이미 네 몸에 있다. 마을 남쪽 들판의 무뢰배들이 요즘 행패가 심하니, 그놈들부터 손봐 주게.", goal = { kind = "talk" }, reward = { coins = 50 } },
	-- 3.9판 튜토리얼: 마을 목인으로 몸풀기 (공격 · 강타 · 기술)
	{ title = "첫 주먹", text = "몸부터 풀자. 마을 입구의 수련 목인을 여덟 번 쳐라. 클릭 (휴대폰은 👊)을 이어 누르면 연타가 이어진다.", goal = { kind = "hit", n = 8, at = Vector3.new(0, 0, -46) }, reward = { coins = 40, stats = 4 } },
	{ title = "강타", text = "힘을 실어 한 번에. 오른쪽 클릭 (휴대폰은 💥)으로 강타를 목인에게 두 번 맞혀라. 강타는 느리지만 상대의 균형을 크게 깎는다.", goal = { kind = "heavy", n = 2, at = Vector3.new(0, 0, -46) }, reward = { coins = 40, stats = 4 } },
	{ title = "첫 기술", text = "권법마다 기술이 있다. E를 눌러 삼재권의 기술을 목인에게 써 보아라. 기술은 내공을 쓰고, 쓰면 잠시 기다려야 한다.", goal = { kind = "skill", n = 1, at = Vector3.new(0, 0, -46) }, reward = { coins = 60, stats = 6 } },
	{ title = "들판의 무뢰배", text = "들판의 무뢰배 다섯을 쓰러뜨려라. 마구 휘두르지 말고, 놈들이 칠 때 F로 흘린 뒤 파고들어라.", goal = { kind = "kill", id = "thug", n = 5, at = Vector3.new(0, 0, 400) }, reward = { coins = 80, stats = 10 } },
	{ title = "몸을 만드는 법", text = "주먹은 몸에서 나온다. 마을 수련터에서 여덟 번 수련하라. 박자를 맞추면 두 배다.", goal = { kind = "train", n = 8, at = Vector3.new(-70, 0, -40) }, reward = { coins = 80, stats = 10 } },
	{ title = "이류의 문턱", text = "싸움과 수련으로 능력치를 채워 이류에 올라라. 이류부터는 박자가 빠른 대신 세 배로 오르는 강화 수련이 열린다.", goal = { kind = "realm", n = 2 }, reward = { coins = 120, stats = 15 } },
	{ title = "산적의 그림자", text = "서쪽 대나무 숲과 동쪽 계곡에 산적 떼가 진을 쳤다. 산적 도객 여섯을 꺾어라.", goal = { kind = "kill", id = "bandit", n = 6, at = Vector3.new(-300, 0, 120) }, reward = { coins = 200, stats = 20 } },
	{ title = "사부를 찾아서", text = "삼재권만으로는 멀리 못 간다. 강호에는 열 사부가 숨어 산다. 안내판의 소문을 따라 한 분을 찾아가라. 남쪽 주막의 취한 노인 이야기가 가장 가깝지.", goal = { kind = "found", n = 1, at = Vector3.new(0, 0, 620) }, reward = { coins = 200 } },
	{ title = "사부의 시험", text = "사부는 아무나 받지 않는다. 사부 곁에서 T를 눌러 시험을 청하고, 사부마다 다른 시험(흘리기·버티기·제자 연무)을 넘어라.", goal = { kind = "trial", n = 1 }, reward = { coins = 300, stats = 25 } },
	{ title = "첫 진짜 권법", text = "시험을 넘었다면 은자를 바치고 그 권법을 배워라. 권법 창(메뉴)에서 언제든 바꿔 쓸 수 있다.", goal = { kind = "learn", n = 2 }, reward = { coins = 300 } },
	{ title = "손에 익히기", text = "새 권법은 써야 손에 붙는다. 그 권법으로 적을 때려 숙련을 3까지 올려라. 숙련 3에 두 번째 기술(R)이 열린다.", goal = { kind = "mastery", n = 3 }, reward = { coins = 400, stats = 30 } },
	{ title = "일류의 벽", text = "수련과 싸움으로 능력치를 쌓아 일류에 올라라. 경지가 오를 때마다 몸이 크게 달라진다. 일류부터 철사장 수련이 열린다.", goal = { kind = "realm", n = 3 }, reward = { coins = 500, stats = 40 } },
	{ title = "두 번째 사부", text = "한 권법만 쓰면 상대가 읽는다. 안내판의 소문을 따라 다른 사부를 찾아가 시험을 넘고, 권법을 하나 더 익혀라.", goal = { kind = "learn", n = 3 }, reward = { coins = 600, stats = 50 } },
	{ title = "특급에 오르다", text = "일류를 넘어 특급에 오르면 몸이 한 번 더 달라진다. 특급부터 운기조식이 열린다. 수련과 사냥으로 능력치를 채워 특급에 올라라.", goal = { kind = "realm", n = 4 }, reward = { coins = 800, stats = 100 } },
	{ title = "흑호채", text = "먼 북쪽 산적 소굴의 두목 흑호가 마을을 노린다. 놈을 꺾어라.", goal = { kind = "boss", id = "heukho", at = Vector3.new(0, 0, -1020) }, reward = { coins = 1000, stats = 150 } },
	{ title = "오의를 열어라", text = "한 권법의 숙련을 5까지 올려라. 숙련 5에 그 권법의 오의(G)가 열린다. 내공이 가득 찼을 때 쓰는 한 수다.", goal = { kind = "mastery", n = 5 }, reward = { coins = 1000, stats = 150 } },
	{ title = "심법 두루마리", text = "적과 보스는 가끔 심법 두루마리를 떨어뜨린다. 심법 창(메뉴)에서 두루마리를 펼쳐 심법 하나를 얻고, 세 칸 중 하나에 끼워라. 심법 하나가 권법 전체를 받쳐 준다.", goal = { kind = "manual", n = 1 }, reward = { coins = 1000 } },
	{ title = "서해의 해적", text = "서쪽 끝 서해 절벽에 해적 떼가 배를 댔다. 특급이면 해볼 만하다. 해적 도객 여덟을 쓰러뜨려라.", goal = { kind = "kill", id = "pirate", n = 8, at = Vector3.new(-1800, 0, -250) }, reward = { coins = 1200, stats = 200 } },
	{ title = "심법 셋", text = "심법은 셋까지 끼울 수 있다. 두루마리를 펼쳐 심법을 셋 모아라. 좋은 심법이 없어도 칸을 비워 두는 것보다 낫다.", goal = { kind = "manual", n = 3 }, reward = { coins = 1800, stats = 200 } },
	{ title = "더 많은 사부", text = "한 사부의 권법만으로는 부족하다. 안내판의 소문을 따라 강호의 사부를 셋까지 찾아가 보아라. 찾아낸 사부는 지도에 나온다.", goal = { kind = "found", n = 3 }, reward = { coins = 1200, stats = 200 } },
	{ title = "천층탑", text = "마을 안 천층탑에 올라 보아라. 층마다 세기가 정해져 있고, 열 층마다 보스가 지킨다. 처음 넘는 보스 층에는 두루마리와 큰 몫이 기다린다. 열 층을 넘어라.", goal = { kind = "tower", n = 10, at = Vector3.new(-185, 0, -185) }, reward = { coins = 2000, stats = 250 } },
	{ title = "혈월곡의 혈랑", text = "남동쪽 끝 핏빛 달 아래에 혈교의 앞잡이 혈랑이 있다. 놈을 쓰러뜨려라.", goal = { kind = "boss", id = "hyeolrang", at = Vector3.new(1080, 0, 1080) }, reward = { coins = 2000, stats = 300 } },
	{ title = "절정에 오르다", text = "혈교와 맞서려면 절정의 경지가 필요하다. 경지별 수련과 사부들의 권법으로 몸을 끌어올려라.", goal = { kind = "realm", n = 5 }, reward = { coins = 2500, stats = 400 } },
	{ title = "네 번째 권법", text = "찾아낸 사부들 가운데 아직 배우지 않은 분이 있다면 시험을 넘고 권법을 하나 더 익혀라. 적마다 잘 듣는 권법이 다르다.", goal = { kind = "learn", n = 4 }, reward = { coins = 3000, stats = 400 } },
	{ title = "숙련과 각성", text = "한 권법을 오래 쓰면 숙련이 오른다. 숙련 6에 이르면 권법이 깨어나 각성기(F)가 열리고, 기술이 세진다. 지금 쓰는 권법의 숙련을 6까지 올려라.", goal = { kind = "mastery", n = 6 }, reward = { coins = 5000, stats = 500 } },
	{ title = "초절정의 몸", text = "절정을 넘어 초절정에 올라라. 초절정부터 상급 수련장의 금종조 수련이 열린다.", goal = { kind = "realm", n = 6 }, reward = { coins = 5000, stats = 600 } },
	{ title = "설산의 빙마", text = "북방 설산의 주인 빙마가 혈교와 손을 잡았다. 얼음을 깨고 놈을 쓰러뜨려라.", goal = { kind = "boss", id = "bingma", at = Vector3.new(0, 0, -1980) }, reward = { coins = 5000, stats = 800 } },
	{ title = "화경에 들다", text = "기를 불처럼 다루는 화경에 올라라. 화경부터 천근추 수련이 열리고, 두 번째 깨달음을 얻을 수 있다.", goal = { kind = "realm", n = 7 }, reward = { coins = 8000, stats = 1000 } },
	{ title = "첫 깨달음", text = "숙련 10에 이른 권법은 깨달음으로 한 등급 올라선다. 권법 창에서 숙련 10인 권법을 골라 깨달아라 (은자가 든다).", goal = { kind = "enlight", n = 1 }, reward = { coins = 8000, stats = 1000 } },
	{ title = "혈교의 그림자", text = "북동쪽 끝 혈교 본산. 혈교도 열을 꺾고 길을 열어라.", goal = { kind = "kill", id = "cultist", n = 10, at = Vector3.new(1600, 0, -1550) }, reward = { coins = 8000, stats = 1000 } },
	{ title = "현경의 고요", text = "현경에 올라라. 현경부터 주천 운기가 열린다. 혈마의 손을 마주하려면 이만한 몸이 필요하다.", goal = { kind = "realm", n = 8 }, reward = { coins = 10000, stats = 1500 } },
	{ title = "혈마", text = "혈교의 주인 혈마. 모든 것을 걸고 맞서라. 그를 꺾으면 그 손이 네 것이 된다.", goal = { kind = "boss", id = "hyeolma", at = Vector3.new(1800, 0, -1950) }, reward = { coins = 15000, stats = 2000 } },
	{ title = "두 번째 깨달음", text = "한 권법을 두 번 깨달으면 피해가 크게 오르고, 각성의 문이 열린다. 숙련 10인 권법을 골라 두 번째 깨달음을 얻어라.", goal = { kind = "enlight", n = 2 }, reward = { coins = 15000, stats = 2000 } },
	{ title = "사경의 문", text = "죽음의 문턱, 사경에 올라라. 사경부터 마음속 마귀와 겨루는 심마 대련과 허공답보가 열린다. 심마를 꺾으면 능력치가 크게 오른다.", goal = { kind = "realm", n = 9 }, reward = { coins = 15000, stats = 2500 } },
	{ title = "생사의 경계", text = "혈마를 꺾은 손이라면 생사경이 멀지 않다. 들판의 적은 내 수준의 땅에서 잡을 때 가장 알차다. 지도의 권장 전투력을 보고 땅을 골라 생사경에 올라라.", goal = { kind = "realm", n = 10 }, reward = { coins = 20000, stats = 5000 } },
	{ title = "신화경에 들다", text = "생사의 경계를 넘으면 몸이 전설이 된다. 신화경에 올라라.", goal = { kind = "realm", n = 11 }, reward = { coins = 40000, stats = 4000 } },
	{ title = "각성 권법", text = "생사경에 오른 고수는 익힌 권법의 숨은 끝을 본다. 원래 권법의 숙련을 끝까지 올리고 깨달음을 두 번 얻은 뒤, 그 사부를 다시 찾아 각성의 시련을 넘어라. 각성 권법(진) 하나를 익혀라.", goal = { kind = "awaken", n = 1 }, reward = { coins = 40000, stats = 4000 } },
	{ title = "천인합일", text = "하늘과 사람이 하나가 되는 경지, 천인합일에 올라라. 그때 마을의 천상 문이 열린다.", goal = { kind = "realm", n = 12 }, reward = { coins = 60000, stats = 6000 } },
	{ title = "천상의 문", text = "마을 안 천상 문으로 하늘에 올라라. 구름 위 천궁은 안전하고, 천상 객잔과 천정 상점이 있다. 지도는 하늘에 오르면 저절로 천상 지도로 바뀐다.", goal = { kind = "sky", n = 1, at = Vector3.new(-90, 0, -205) }, reward = { coins = 60000 } },
	{ title = "천상의 첫 사냥", text = "하늘의 적은 땅의 적보다 몫이 크고, 천정과 천상 재료를 떨어뜨린다. 천궁 남쪽 운해 평원의 운병 여덟을 쓰러뜨려라.", goal = { kind = "kill", id = "cloudguard", n = 8, at = Vector3.new(-90, 4000, 520) }, reward = { coins = 30000, stats = 3000 } },
	{ title = "무극에 오르다", text = "혈마도 쓰러졌다. 그러나 북서쪽 끝 허공 균열에서 더 깊은 어둠이 새어 나온다. 무극의 경지에 올라라. 권법을 깨달음으로 승급시키는 것도 잊지 마라.", goal = { kind = "realm", n = 13 }, reward = { coins = 10000, stats = 500 } },
	{ title = "이름 없는 노인", text = "무극에 오른 자는 들을 수 있다는 소문. 남서쪽 세상 끝, 구름이 땅에 닿는 곳에 이름 없는 노인이 있다. 그에게서 하늘을 여는 주먹을 얻어라.", goal = { kind = "learn", id = "gaecheon", n = 1 }, reward = { coins = 15000, stats = 800 } },
	{ title = "구름 미궁", text = "천궁 광장의 구름 미궁 문으로 들어가 방들을 넘고 미궁의 주인을 꺾어라. 들어간 사람의 세기에 맞춰 적이 선다.", goal = { kind = "maze", n = 1, at = Vector3.new(72, 4000, -34) }, reward = { coins = 150000, stats = 15000 } },
	{ title = "천층탑 서른 층", text = "마을의 천층탑 서른 층에 올라라. 보스 층마다 두루마리가 기다린다.", goal = { kind = "tower", n = 30, at = Vector3.new(-185, 0, -185) }, reward = { coins = 20000, stats = 1500 } },
	{ title = "허공 균열", text = "허공 균열의 천마 사도 여섯을 꺾고 길을 열어라.", goal = { kind = "kill", id = "apostle", n = 6, at = Vector3.new(-1800, 0, -1850) }, reward = { coins = 20000, stats = 1000 } },
	{ title = "다섯 번째 권법", text = "적마다 잘 듣는 권법이 다르다. 사부를 하나 더 찾아 다섯 번째 권법을 익혀라.", goal = { kind = "learn", n = 5 }, reward = { coins = 25000, stats = 1500 } },
	{ title = "천마", text = "하늘을 삼킨 마귀, 천마. 강호의 마지막 적이다.", goal = { kind = "boss", id = "cheonma", at = Vector3.new(-1950, 0, -1950) }, reward = { coins = 50000, stats = 3000 } },
	{ title = "깨어난 화염산", text = "천마가 쓰러지자 동쪽 끝 화염산이 깨어났다. 불의 산 아래 염제를 꺾어라.", goal = { kind = "boss", id = "yeomje", at = Vector3.new(2950, 0, -1150) }, reward = { coins = 60000, stats = 3500 } },
	{ title = "모래 왕릉", text = "남쪽 끝 모래 왕릉에서 사왕이 무덤을 박차고 일어났다. 왕릉으로 가 사왕을 다시 눕혀라.", goal = { kind = "boss", id = "sawang", at = Vector3.new(-900, 0, 2930) }, reward = { coins = 70000, stats = 4000 } },
	{ title = "하늘 문지기", text = "북쪽 끝 구름바다 위, 천외봉으로 가는 길을 천문장이 막고 있다.", goal = { kind = "boss", id = "cheonmun", at = Vector3.new(0, 0, -2760) }, reward = { coins = 90000, stats = 5000 } },
	{ title = "뇌정봉의 뇌제", text = "천궁 동쪽 다리 너머 뇌정봉에 벼락을 부리는 뇌제가 있다. 천상의 보스는 천상 재료를 떨어뜨린다. 뇌제를 꺾어라.", goal = { kind = "boss", id = "noeje", at = Vector3.new(720, 4000, -160) }, reward = { coins = 150000, stats = 15000 } },
	{ title = "천존", text = "천궁 북쪽 옥좌대에 하늘의 옥좌를 지키는 천존이 있다. 천상의 주인을 꺾어라.", goal = { kind = "boss", id = "cheonjon", at = Vector3.new(0, 4000, -720) }, reward = { coins = 300000, stats = 40000 } },
	{ title = "반선", text = "사람과 신선의 사이, 반선에 올라라.", goal = { kind = "realm", n = 14 }, reward = { coins = 80000, stats = 4000 } },
	{ title = "등선", text = "구름을 밟고 오르는 등선의 경지에 올라라. 천외천이 멀지 않다.", goal = { kind = "realm", n = 15 }, reward = { coins = 90000, stats = 4500 } },
	{ title = "하늘 밖의 하늘", text = "경지의 끝, 천외천에 올라라. 하늘 밖에 하늘이 있다.", goal = { kind = "realm", n = 16 }, reward = { coins = 100000, stats = 5000 } },
	{ title = "천공 투기장", text = "천궁 광장의 투기장 문 너머, 하늘의 재앙 천겁이 기다린다. 여럿이 함께 들어가 천겁을 쓰러뜨려라.", goal = { kind = "raid", n = 1, at = Vector3.new(-78, 4000, 30) }, reward = { coins = 400000, stats = 60000 } },
	{ title = "천층탑 쉰 층", text = "천층탑 쉰 층에 올라라. 위로 갈수록 몫이 가파르게 붙는다.", goal = { kind = "tower", n = 50, at = Vector3.new(-185, 0, -185) }, reward = { coins = 150000, stats = 8000 } },
	{ title = "태초", text = "천외봉 아래 시원자를 찾아 시험을 넘고 태초신권을 얻어라. 세상이 처음 열리던 그 한 주먹이다.", goal = { kind = "learn", id = "taecho", n = 1 }, reward = { coins = 200000, stats = 10000 } },
	{ title = "정점", text = "태초의 주먹마저 쥐었다면 들어라. 동남쪽 세상 끝 일월대에 해와 달을 두 손에 쥔 권존이 있다. 그를 넘어 일월신권을 얻어라. 그것이 권법의 정점이다.", goal = { kind = "learn", id = "ilwol", n = 1 }, reward = { coins = 500000, stats = 30000 } },
	{ title = "환생", text = "천외천이 끝이 아니다. 환생하면 경지는 처음부터지만 몸은 더 세지고 (얻는 능력치 두 배), 천외천 너머의 경지가 하나씩 열린다. 메뉴에서 환생하라.", goal = { kind = "rebirth", n = 1 }, reward = { coins = 500000 } },
	{ title = "윤회의 공덕", text = "환생할 때마다 공덕 둘이 쌓인다. 능력치 창의 '♻ 환생 특전'에서 공덕으로 특전(체력·피해·흡성·심공·재물운·오성·질풍)을 하나 사라. 특전은 환생해도 남고, 언제든 되돌려 다시 고를 수 있다.", goal = { kind = "perk", n = 1 }, reward = { coins = 300000 } },
	{ title = "전생의 그림자", text = "삼류에서 다시 오르다 생사경에 닿으면, 지난 삶의 네가 그림자로 나타난다. 능력치 창의 '☯ 윤회의 시련'으로 그림자를 불러 꺾어라. 넘을 때마다 공덕 하나와 천정·두루마리가 따르고, 그림자가 환생 권법 하나를 남긴다 (윤회권 · 업화권 · 무상권 · 권왕신권).", goal = { kind = "samsara", n = 1 }, reward = { coins = 1000000, stats = 20000 } },
	{ title = "초월", text = "원래 권법과 그 각성 권법을 숙련 20까지 올리고 천상에서만 나는 재료를 모으면, 숨은 초월의 사부가 시련을 내준다. 초월 권법(초) 하나를 익혀라. 초 오의(X)는 하늘이 뒤집히는 한 수다.", goal = { kind = "transcend", n = 1 }, reward = { coins = 1000000, stats = 100000 } },
	{ title = "천층탑 백 층", text = "천층탑 백 층에 올라라. 위로 갈수록 은자와 능력치가 가파르게 붙는다.", goal = { kind = "tower", n = 100, at = Vector3.new(-185, 0, -185) }, reward = { coins = 2000000 } },
	{ title = "혼원경", text = "환생한 몸으로 다시 올라 천외천을 넘어라. 혼원경이 열려 있다.", goal = { kind = "realm", n = 17 }, reward = { coins = 1500000, stats = 300000 } },
	{ title = "두 번째 삶", text = "다시 천외천 너머 혼원경에 올라 두 번째로 환생하라. 환생할수록 얻는 능력치가 커져, 다시 오르는 길은 처음보다 훨씬 빠르다.", goal = { kind = "rebirth", n = 2 }, reward = { coins = 2000000 } },
	{ title = "두 번째 그림자", text = "두 번째 삶의 생사경에서 두 번째 그림자가 기다린다. 첫 그림자보다 질기다. 공덕으로 고른 특전을 믿어라.", goal = { kind = "samsara", n = 2 }, reward = { coins = 3000000, stats = 200000 } },
	{ title = "무량경", text = "끝이 없는 경지, 무량경에 올라라.", goal = { kind = "realm", n = 18 }, reward = { coins = 4000000, stats = 800000 } },
	{ title = "세 번째 삶", text = "무량경에 올라 세 번째로 환생하라. 특전을 다시 고를 때다. 싸움에 쓸 것인가, 오르는 빠르기에 쓸 것인가.", goal = { kind = "rebirth", n = 3 }, reward = { coins = 5000000 } },
	{ title = "세 번째 그림자", text = "세 번째 그림자는 네 버릇을 안다. 늘 쓰던 기술만 쓰면 막힌다.", goal = { kind = "samsara", n = 3 }, reward = { coins = 8000000, stats = 2000000 } },
	{ title = "태허경", text = "텅 빈 하늘의 경지, 태허경에 올라라. 마지막 환생이 기다린다.", goal = { kind = "realm", n = 19 }, reward = { coins = 9000000, stats = 1500000 } },
	{ title = "네 번째 삶", text = "태허경에 올라 마지막으로 환생하라. 더는 환생이 없다. 이제부터는 끝까지 오르는 일만 남는다.", goal = { kind = "rebirth", n = 4 }, reward = { coins = 12000000 } },
	{ title = "마지막 그림자", text = "윤회의 바퀴가 마지막 그림자를 내보낸다. 네 삶을 모두 넘어선 너만이 권왕의 자리에 앉는다.", goal = { kind = "samsara", n = 4 }, reward = { coins = 20000000, stats = 20000000 } },
	{ title = "권왕", text = "네 삶을 넘었다. 이제 마지막 경지, 권왕에 올라라. 맨손의 강호에 왕은 하나다.", goal = { kind = "realm", n = 20 }, reward = { coins = 50000000 } },
	{ title = "강호의 전설", text = "이제 강호에 네 이름을 모르는 자가 없다. 남은 권법과 숨은 사부, 완전 각성과 승급. 그리고 너는 이제 권왕이다. 길은 끝이 없다.", goal = { kind = "done" }, reward = {} },
}

-- 3.9판: 보상을 늘린다. 흑호채부터 은자 ×2.5 · 능력치 ×2, 보스 장에는 심법 두루마리 (뒤로 갈수록 많이)
do
	local from = 0
	for i, ch in ipairs(Config.Story) do
		if ch.title == "흑호채" then
			from = i
		end
	end
	for i, ch in ipairs(Config.Story) do
		local r = ch.reward or {}
		if from > 0 and i >= from then
			if r.coins then
				r.coins = math.floor(r.coins * 2.5)
			end
			if r.stats then
				r.stats = math.floor(r.stats * 2)
			end
		end
		if ch.goal.kind == "boss" then
			r.scrolls = math.clamp(math.floor(i / 8) + 1, 2, 12)
		end
		ch.reward = r
	end
end

-- 3.9판 권법 시험장: 하늘 높이 떠 있는 큰 전투방 (사람끼리는 싸우지 않는다). 작은 목인과 큰 목인, 초당 피해가 보인다
Config.TEST_ROOM = { at = Vector3.new(0, 1200, 0), half = 170 }

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
	{ id = "belltower", name = "천년 종루", icon = "🔔", at = Vector3.new(2700, 0, 900) },
	{ id = "mirrorlake", name = "거울 호수", icon = "🪞", at = Vector3.new(1100, 0, 2500) },
	{ id = "gianthand", name = "거신의 손", icon = "✋", at = Vector3.new(-2500, 0, 1900) },
	{ id = "crater", name = "별똥 분화구", icon = "☄", at = Vector3.new(1100, 0, -2700) },
	{ id = "thousandsteps", name = "천 개의 계단", icon = "🪜", at = Vector3.new(-2700, 0, -2700) },
	-- 2.4판: 허허벌판에 여섯 곳 더
	{ id = "grove", name = "만목원", icon = "🌳", at = Vector3.new(-1700, 0, 1600) },
	{ id = "fallengiant", name = "잠든 석장", icon = "⚔", at = Vector3.new(1900, 0, 1700) },
	{ id = "stonecircle", name = "별바위 고리", icon = "🪨", at = Vector3.new(-1900, 0, -800) },
	{ id = "beacon", name = "옛 봉화대", icon = "🔥", at = Vector3.new(900, 0, -2350) },
	{ id = "hamlet", name = "버려진 마을", icon = "🏚", at = Vector3.new(0, 0, 2250) },
	{ id = "archway", name = "하늘 아치", icon = "🌁", at = Vector3.new(-1400, 0, -2350) },
	-- 3.6판: 아직 비어 있던 바깥 땅에 열 곳 더
	{ id = "pagoda", name = "구층석탑", icon = "🛕", at = Vector3.new(3600, 0, -800) },
	{ id = "lotuspond", name = "연화정", icon = "🪷", at = Vector3.new(-2400, 0, 3100) },
	{ id = "splitrock", name = "일검 바위", icon = "🪨", at = Vector3.new(3700, 0, 200) },
	{ id = "lanternway", name = "천등 회랑", icon = "🏮", at = Vector3.new(1400, 0, 3700) },
	{ id = "oldwall", name = "무너진 장성", icon = "🧱", at = Vector3.new(-700, 0, -3750) },
	{ id = "cranepond", name = "학 연못", icon = "🕊", at = Vector3.new(450, 0, -3750) },
	{ id = "turtlestele", name = "귀부 비석", icon = "🐢", at = Vector3.new(2100, 0, -3700) },
	{ id = "oldmine", name = "버려진 광산", icon = "⛏", at = Vector3.new(3700, 0, -1800) },
	{ id = "lonepine", name = "선인송", icon = "🌲", at = Vector3.new(-2200, 0, -3750) },
	{ id = "sundial", name = "해시계 광장", icon = "🕰", at = Vector3.new(3200, 0, 3300) },
}
-- 3.6판 숨은 것들 (지도에 나오지 않는다). 찾으면 한 번씩 몫이 있다
Config.CAIRNS = {
	Vector3.new(-3500, 0, -600), Vector3.new(3300, 0, 1800), Vector3.new(-300, 0, -3550), Vector3.new(1800, 0, 3950),
	Vector3.new(-3800, 0, 2600), Vector3.new(1650, 0, -3300), Vector3.new(650, 0, 1950),
}
Config.EGGS = {
	cairnEach = { coins = 7777 }, -- 돌탑 하나
	cairnAll = { coins = 777777, scrolls = 7 }, -- 일곱 모두
	cat = { at = Vector3.new(2700, 0, 900) + Vector3.new(-8, 0, 18.6), potions = 3 }, -- 천년 종루 아래 낮잠 자는 고양이
	sword = { at = Vector3.new(-4050, 0, 4050), pulls = 100, coins = 1000000 }, -- 세상 끝 바위에 박힌 검 (백 번 당기면)
	well = { at = Vector3.new(0, 0, 2250), cost = 1000, jackpot = 100000 }, -- 버려진 마을의 소원 우물
	ducks = { at = Vector3.new(1100, 0, 2500) + Vector3.new(40, 0, 30), scrolls = 1 }, -- 거울 호수의 오리 가족
}
-- 적은 마을에서 멀수록 세다: 250칸 넘으면 100칸마다 한 단계
function Config.enemyLevel(home: Vector3): number
	local d = Vector3.new(home.X, 0, home.Z).Magnitude
	-- 천상계: 가운데 천궁에서 멀수록, 땅의 끝보다도 높다
	if Config.SKY and home.Y > Config.SKY.y - 300 then
		return 26 + math.floor(d / 60)
	end
	return 1 + math.floor(math.max(0, d - 250) / 100)
end
Config.MASTER_RANGE = 26 -- 사부 곁 이만큼 안에서 배운다
-- 1.4판: 사부의 시험 (분신과 겨루는 대신 사부마다 다른 시험). 각성 시련과 권존의 일월 시련은 그대로
--   deflect = 사부의 공격을 흘려 내기 (F), survive = 사부와 제자들 사이에서 버티기, disciples = 제자들이 세 번 몰려온다 (마지막은 수제자)
Config.TRIAL_KIND = {
	-- 2.1판: 흘리기 시험은 취팔선권의 사부만 낸다 (다른 사부는 버티기나 제자 연무)
	taeheo = "survive", geumgang = "survive", maehwa = "disciples", cheonryong = "disciples", muyeong = "disciples", byeokryeok = "survive",
	chwi = "deflect", changhae = "disciples", yeolhwa = "disciples", pungsin = "disciples", gaecheon = "survive", taecho = "survive",
	yeonggeop = "survive", agong = "survive", unryu = "disciples", seongha = "disciples",
}
-- need = 해내야 할 수 (버티기는 초), time = 제한 시간 (초). 궁극의 권법(trialHp가 있는 권법)은 1.5배
Config.TRIAL_KINDS = {
	deflect = { icon = "🌊", title = "흘리기 시험", need = 6, time = 120,
		ask = "나를 쓰러뜨릴 필요는 없다. 흘려라. 내 주먹이 닿기 직전, 머리 위에 F가 번쩍일 때 F를 눌러라. %d번 흘려 내면 제자로 받아 주마.", goal = "F가 번쩍이면 F! 사부의 공격을 흘려라" },
	survive = { icon = "⏳", title = "버티기 시험", need = 45, time = 45,
		ask = "%d초를 버텨라. 나와 내 제자들이 한꺼번에 덤빈다. 쓰러지지만 않으면 된다.", goal = "쓰러지지 말고 버텨라" },
	disciples = { icon = "👥", title = "제자 연무", need = 3, time = 180,
		ask = "내 제자들을 넘어 보아라. %d번 몰려온다. 마지막은 수제자다.", goal = "몰려오는 제자들을 꺾어라" },
}
function Config.trialNeed(styleId: string): (string, number)
	local kind = Config.TRIAL_KIND[styleId] or "duel"
	local K = Config.TRIAL_KINDS[kind]
	if not K then
		return "duel", 1
	end
	local st = Config.STYLE_BY_ID[styleId]
	local mul = (st and st.trialHp) and 1.5 or 1
	return kind, math.floor(K.need * mul + 0.5)
end
Config.WORLD_HALF = 4400 -- 세상 끝 (가운데에서). 1.8판: 바깥 네 귀퉁이의 새 땅까지
-- 마을에서 각 곳으로 가는 흙길 (꺾이는 점들)
Config.Roads = {
	-- 1.8판: 세상 끝 네 땅으로
	{ Vector3.new(2850, 0, -1450), Vector3.new(3050, 0, -2100), Vector3.new(3150, 0, -2700) },
	{ Vector3.new(-2070, 0, 300), Vector3.new(-2500, 0, 700), Vector3.new(-2850, 0, 1100) },
	{ Vector3.new(2070, 0, 500), Vector3.new(2600, 0, 1200), Vector3.new(2950, 0, 1800) },
	{ Vector3.new(-2100, 0, -2100), Vector3.new(-2500, 0, -2600), Vector3.new(-2850, 0, -2900) },
	{ Vector3.new(-238, 0, 0), Vector3.new(-1000, 0, 0) },
	{ Vector3.new(238, 0, 0), Vector3.new(560, 0, 0) },
	{ Vector3.new(0, 0, -238), Vector3.new(0, 0, -740) },
	{ Vector3.new(0, 0, 238), Vector3.new(0, 0, 640) },
	{ Vector3.new(-238, 0, 0), Vector3.new(-300, 0, -70), Vector3.new(-650, 0, -560) },
	{ Vector3.new(238, 0, 0), Vector3.new(300, 0, -70), Vector3.new(650, 0, -560) },
	{ Vector3.new(300, 0, -70), Vector3.new(272, 0, -262) }, -- 상급 수련장으로
	{ Vector3.new(0, 0, 238), Vector3.new(-90, 0, 290), Vector3.new(-600, 0, 600) },
	{ Vector3.new(0, 0, 238), Vector3.new(90, 0, 290), Vector3.new(600, 0, 600) },
	{ Vector3.new(238, 0, 0), Vector3.new(400, 0, -280), Vector3.new(890, 0, -280) },
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
	-- 서해 남쪽 바닷가 창해각으로
	{ Vector3.new(-1380, 0, 0), Vector3.new(-1500, 0, 560), Vector3.new(-1700, 0, 860) },
	-- 붉은 황야 동쪽 염화단으로
	{ Vector3.new(2070, 0, -100), Vector3.new(2300, 0, 140) },
}

Config.ENEMY_DMG = 1.35 -- 적의 공격이 아프다 (막고 흘리지 않으면 버티기 어렵다)
-- 베타 8: 적은 훨씬 질기고 (체력 ×2.2, 멀수록 더), 후반 적의 피해는 크게 줄였다 (오래 겨루는 싸움)
Config.ENEMY_HP = 2.2
Config.ENEMY_BOSS_HP = 0.54 -- 1.0판: 1.6 → 1.35 (보스 체력 조금 낮춤). 2.7.1판: 모든 보스 체력 60% 줄임 (1.35 → 0.54)
Config.ENEMY_HP_LEVEL = 0.35 -- 단계마다 체력 +35%
Config.ENEMY_DMG_LEVEL = 0.12 -- 단계마다 피해 +12%
Config.ENEMY_DMG_MULT_POW = 0.6 -- 후반 땅의 겹 배율(mult)은 피해에 이만큼의 거듭제곱으로만 (×14 → ×4.9)
-- 전투력: 피해 배율과 체력으로 잰다. 차이가 크면 약한 쪽의 공격은 통하지 않는다
function Config.playerPower(dmgMult: number, maxHp: number): number
	return math.floor(100 * math.sqrt(math.max(0.01, dmgMult) * math.max(1, maxHp) / 100))
end
-- 3.2.7판: 적 전투력이 기술의 세기를 보지 않아, 한 방이 센 적 (흑영 자객·철갑 무사·독수 자객·혈교 장로 같은 정예)은 숫자보다 훨씬 셌다.
-- 들판의 적은 그 적 기술의 초당 피해를 보통 적 (산적 도객·혈교도, 7.1)에 견줘 전투력에 곱한다 (약한 적은 깎지 않는다: 1~2.5배)
-- 보스·분신 (duel)은 그대로 (보스는 따로 졸병에 맞춘다)
Config.MOVE_DPS_REF = 7.1
local moveFactorCache: { [any]: number } = {}
function Config.enemyMoveFactor(def: any, boss: boolean?): number
	if boss or def.duel or def.dummy then
		return 1
	end
	local cached = moveFactorCache[def]
	if cached then
		return cached
	end
	local tot, n = 0, 0
	for _, mv in ipairs(def.moves or {}) do
		local d = 0
		for _, h in ipairs(mv.hits or {}) do
			d += h.dmg or 0
		end
		tot += d / ((mv.dur or 1) + 0.9)
		n += 1
	end
	local k = n > 0 and math.clamp(tot / n / Config.MOVE_DPS_REF, 1, 2.5) or 1
	moveFactorCache[def] = k
	return k
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
	{ kind = "mabo", at = Vector3.new(-105, 0, -15) },
	{ kind = "mabo", at = Vector3.new(-105, 0, 5) },
	{ kind = "ironpalm", at = Vector3.new(105, 0, -15) },
	{ kind = "ironpalm", at = Vector3.new(105, 0, 5) },
	{ kind = "breathing", at = Vector3.new(372, 0, 306) },
	{ kind = "breathing", at = Vector3.new(388, 0, 294) },
	{ kind = "simma", at = Vector3.new(-380, 0, -430) },
	-- 상급 수련장 (마을 북동쪽 밖)
	{ kind = "geumjong", at = Vector3.new(300, 0, -300) },
	{ kind = "geumjong", at = Vector3.new(300, 0, -360) },
	{ kind = "cheongeun", at = Vector3.new(360, 0, -300) },
	{ kind = "cheongeun", at = Vector3.new(360, 0, -360) },
	{ kind = "jucheon", at = Vector3.new(330, 0, -270) },
	{ kind = "jucheon", at = Vector3.new(330, 0, -390) },
	{ kind = "heogong", at = Vector3.new(270, 0, -330) },
	{ kind = "heogong", at = Vector3.new(390, 0, -330) },
	-- 천궁의 천상 수련 (천상계 높이)
	{ kind = "cheonsang", at = Vector3.new(55, 4000, 55) },
	{ kind = "cheonsang", at = Vector3.new(-55, 4000, -55) },
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
-- 심법 (내공 수련서): 두루마리나 은자로 뽑는다. 세 칸에 끼우면 늘 효과가 있다
-- 등급이 높을수록 효과가 크다. 같은 심법을 더 높은 등급으로 뽑으면 바뀌고, 낮거나 같으면 은자로 돌려받는다
------------------------------------------------------------------------
Config.MANUALS = {
	{ id = "cheolgol", name = "철골공", icon = "🦴", stat = "hp", base = 0.04, desc = "최대 체력" },
	{ id = "pagoe", name = "파괴심법", icon = "💥", stat = "dmg", base = 0.03, desc = "주는 피해" },
	{ id = "hoche", name = "금강호체공", icon = "🛡", stat = "def", base = 0.025, desc = "받는 피해 감소" },
	{ id = "jilpung", name = "질풍심법", icon = "🍃", stat = "speed", base = 0.025, desc = "이동 속도" },
	{ id = "ungi", name = "운기심법", icon = "🌀", stat = "chi", base = 0.06, desc = "내공 회복" },
	{ id = "jipjung", name = "집중심법", icon = "🎯", stat = "cd", base = 0.045, desc = "기술 대기 감소" }, -- 2.1판: 2.5% → 4.5% (혈기공은 빠졌다)
	{ id = "ohui", name = "오의심법", icon = "✴", stat = "ult", base = 0.05, desc = "오의 피해" },
}
Config.MANUAL_BY_ID = {}
for _, m in ipairs(Config.MANUALS) do
	Config.MANUAL_BY_ID[m.id] = m
end
-- 등급: rate = 뽑힐 확률, mult = 효과 배율
Config.MANUAL_RARITY = {
	{ name = "일반", rate = 0.55, mult = 1, color = Color3.fromRGB(200, 200, 200) },
	{ name = "희귀", rate = 0.28, mult = 2, color = Color3.fromRGB(110, 190, 255) },
	{ name = "영웅", rate = 0.12, mult = 3.5, color = Color3.fromRGB(200, 120, 255) },
	{ name = "전설", rate = 0.045, mult = 5.5, color = Color3.fromRGB(255, 200, 80) },
	{ name = "신화", rate = 0.004, mult = 8, color = Color3.fromRGB(255, 110, 90) },
	{ name = "천상", rate = 0.001, mult = 12, color = Color3.fromRGB(150, 245, 255), heavenly = true },
}
-- 뽑기: 두루마리 하나 또는 은자. 60번 안에 전설 이상이 한 번은 나온다 (천장)
-- 천장에서는 전설 88% · 신화 10% · 천상 2%
Config.MANUAL_DRAW = { coins = 30000, pity = 60, slots = 3, refund = 4000 }
function Config.manualValue(id: string, rarity: number): number
	local m = Config.MANUAL_BY_ID[id]
	local r = Config.MANUAL_RARITY[rarity]
	return (m and r) and m.base * r.mult or 0
end

------------------------------------------------------------------------
-- 천층탑: 마을 북서쪽의 탑. 하늘의 시련장에서 한 층씩 오른다 (층마다 적이 세진다, 열 층마다 보스)
------------------------------------------------------------------------
Config.TOWER = {
	enter = Vector3.new(-185, 0, -185), -- 마을 안 탑 입구
	arena = Vector3.new(-1700, 1800, 1700), -- 첫 시련장 (사람마다 옆으로 비켜 놓는다)
	slotGap = 360,
	slots = 10,
	radius = 46,
	bossEvery = 10,
	-- 층의 세기는 정해져 있다 (누가 오르든 같다): 1층 전투력 60, 층마다 ×1.07 (1.9.1판: ×1.06 → ×1.07, 위로 갈수록 더 가파르게)
	-- (10층 약 110 · 50층 약 1,640 · 80층 약 12,000 · 100층 약 48,000 · 120층 약 190,000 · 150층 약 1,440,000)
	powerStart = 60,
	powerGrowth = 1.07,
	bossPower = 1.3, -- 보스 층은 전투력 ×1.3, 체력 ×2.5
	coins = 60, -- 층마다 은자 (× 층)
	scrollEvery = 5, -- 최고 기록을 새로 넘을 때, 다섯 층마다 두루마리 하나 (열 층마다 둘 더)
	-- 2.7.6판: 후반 보상. 51층부터 은자가 층마다 ×1.04로 붙고, 보스 층을 처음 넘으면 그 층 적 bestStats마리 몫의 능력치와 천정
	coinGrowth = 1.04,
	bestStats = 8,
	bestGems = 10,
	bestGemsPerFloor = 0.5,
	bands = {
		{ 1, { "thug", "bandit" } },
		{ 6, { "bandit", "spearman", "brute" } },
		{ 11, { "assassin", "brute", "ironguard" } },
		{ 21, { "ironguard", "shadowblade", "cultist" } },
		{ 31, { "cultelder", "marauder", "lancer" } },
		{ 41, { "riftling", "voidwalker", "stonegolem" } },
		{ 51, { "flameimp", "sandwraith", "magmabrute" } },
		{ 61, { "apostle", "tombguard", "starblade", "skyguard" } },
	},
	bosses = { "heukho", "hyeolrang", "bingma", "hyeolma", "cheonma", "yeomje", "sawang", "cheonmun" },
}

------------------------------------------------------------------------
-- 비무 백 승: 비무대에서 백 번 이긴 자에게 무쌍신권
------------------------------------------------------------------------
Config.PVP_STYLE = { wins = 100, style = "musang" }
-- 들판 PvP: 안전한 곳(마을·사당) 밖에서는 사람끼리도 싸운다. 3.4.1판: 사람에게 한 번 쓰러진 뒤부터만 스스로 끌 수 있다
Config.PVP = { offAfterDeath = true, toggleCooldown = 30 }
------------------------------------------------------------------------
-- 3.3판: 배틀그라운드. 메인 월드에서는 사람끼리 싸우지 않는다 (들판 PvP·비무대 없음).
-- 따로 게시한 배틀그라운드 장소에서 늘 PvP. 모두 체력 200, 공격력도 같다. 메인 월드에서 익힌 권법만 쓴다 (숙련은 모두 끝까지 연 것으로).
-- 권법마다 기본 피해의 크기가 달라 (삼재권 연타 5 · 극 일월 30), 먼저 그 권법의 연타 한 대를 ref로 맞춘다 (기술·오의는 그 권법 안의 비율 그대로).
-- 그다음 눌러 담는다 (dmgK × 피해^dmgPow): 연타 한 대 6 남짓 · 기술 11 남짓 · 오의 25 남짓 · 초 오의는 한 대 상한.
-- 한 대는 hitCap까지, 1초에 받는 피해는 secCap까지 (누구도 한 방에, 한 번의 몰아치기로 쓰러지지 않는다).
-- 좋은 권법은 아주 조금 세다: 등급 한 칸마다 gradeStep (하급 1 → 극 약 1.26 이지만 눌러 담겨 실제로는 15% 남짓)
------------------------------------------------------------------------
Config.BATTLE = {
	placeName = "배틀그라운드", -- 같은 체험 안의 장소 이름 (이 이름이 든 장소로 보낸다)
	placeId = 0, -- 알면 적는다 (0이면 이름으로 찾는다)
	hp = 200,
	ref = 8,
	-- 3.3.1판: 너무 빨리 쓰러졌다 → 1.8 → 1.5, 한 대 34 → 22, 1초 70 → 32 (쓰러지기까지 적어도 6초 남짓)
	dmgK = 1.5,
	dmgPow = 0.6,
	hitCap = 22,
	secCap = 32,
	gradeStep = 0.02,
	walk = 18,
	respawn = 4,
	shield = 5, -- 싸움터에 들어가거나 일어난 뒤 맞지 않는 시간 (먼저 때리면 풀린다)
	lobbyLeave = 5, -- 싸운 뒤 이만큼 지나야 대기실로 나갈 수 있다
	mapTime = 300, -- 맵 하나에 5분
	warnAt = 15, -- 바뀌기 전 알림
	fallY = -70, -- 맵 바닥에서 이만큼 아래로 떨어지면 쓰러진다
	store = "KwonBattle_v1",
	coinsPerKill = 60, -- 메인 월드로 돌아가면 받는 은자 (경지가 높을수록 더: × (1 + 0.5 × (경지 - 1)))
	coinsPerWin = 300, -- 한 판 (맵 하나)에서 가장 많이 쓰러뜨린 사람
	maps = {
		{ id = "bamboo", name = "죽림 비무장", desc = "대숲에 둘러싸인 돌 마당. 대나무 덤불 뒤에 숨어 파고든다" },
		{ id = "frost", name = "빙호 설원", desc = "얼어붙은 호수와 얼음 기둥. 가운데는 탁 트였고 가장자리는 눈 언덕" },
		{ id = "crater", name = "화산 분지", desc = "용암이 흐르는 분화구 안의 두 층 단. 높은 곳을 잡아라" },
		{ id = "cloud", name = "운상 누각", desc = "구름 위에 뜬 누각 셋과 다리. 떨어지면 쓰러진다" },
	},
}
-- 그 권법 연타 한 대의 평균 피해 (배틀그라운드에서 권법마다 크기를 맞출 때)
local battleScaleCache: { [any]: number } = {}
function Config.battleScale(style: any): number
	if not style then
		return 10
	end
	local c = battleScaleCache[style]
	if c then
		return c
	end
	local tot, n = 0, 0
	for _, m in ipairs(style.combo or {}) do
		for _, h in ipairs(m.hits or {}) do
			tot += h.dmg or 0
			n += 1
		end
	end
	local v = n > 0 and math.max(1, tot / n) or 10
	battleScaleCache[style] = v
	return v
end
Config.isBattle = function(): boolean
	return Config.BATTLE_MODE
end

-- 안전한 곳 (마을·사당·사부의 자리): 사람끼리 싸울 수 없고, 적이 덤비지 않는다
function Config.inSafe(pos: Vector3): boolean
	-- 3.9판 권법 시험장
	local TR = Config.TEST_ROOM
	if TR and math.abs(pos.X - TR.at.X) <= TR.half and math.abs(pos.Z - TR.at.Z) <= TR.half and math.abs(pos.Y - TR.at.Y) < 120 then
		return true
	end
	-- 천상계에서는 천궁만 안전하다
	if Config.SKY and pos.Y > Config.SKY.y - 300 then
		local town = Config.SKY.islands[1]
		return Vector3.new(pos.X - town.at.X, 0, pos.Z - town.at.Z).Magnitude <= town.radius
	end
	for _, r in ipairs(Config.Regions) do
		if r.safe and math.abs(pos.X - r.center.X) <= r.size.X / 2 and math.abs(pos.Z - r.center.Z) <= r.size.Z / 2 then
			return true
		end
	end
	return false
end

------------------------------------------------------------------------
-- 탈것: V(휴대폰은 🐎)로 타고 내린다. 공격·막기·피하기를 하거나 맞으면 내린다. 싸우는 중에는 탈 수 없다
-- kind: horse / tiger / cloud (모양), hip = 탄 사람을 이만큼 들어 올린다
------------------------------------------------------------------------
Config.MOUNTS = {
	{ id = "horse", name = "갈색 말", icon = "🐎", kind = "horse", speed = 2.0, cost = 0, color = Color3.fromRGB(130, 85, 50), mane = Color3.fromRGB(50, 35, 25), desc = "누구나 처음부터 가진 말" },
	{ id = "blackhorse", name = "흑룡마", icon = "🐴", kind = "horse", speed = 2.25, cost = 60000, color = Color3.fromRGB(28, 24, 28), mane = Color3.fromRGB(160, 25, 30), desc = "붉은 갈기의 검은 준마" },
	{ id = "tiger", name = "백호", icon = "🐅", kind = "tiger", speed = 2.5, cost = 400000, color = Color3.fromRGB(236, 234, 228), mane = Color3.fromRGB(30, 30, 36), desc = "흰 범. 땅을 박차고 달린다" },
	{ id = "dragon", name = "청룡", icon = "🐉", kind = "dragon", speed = 3.1, cost = 0, premium = "dragon", color = Color3.fromRGB(40, 150, 130), mane = Color3.fromRGB(255, 210, 90), desc = "💎 로벅스 상품. 하늘을 헤엄치는 비늘 용. 가장 빠르다" },
	{ id = "cloud", name = "날개구름", icon = "☁", kind = "cloud", speed = 2.75, cost = 1500000, color = Color3.fromRGB(250, 250, 255), mane = Color3.fromRGB(255, 215, 140), desc = "구름을 타고 미끄러진다. 청룡 다음으로 빠르다" },
}
Config.MOUNT_BY_ID = {}
for _, m in ipairs(Config.MOUNTS) do
	Config.MOUNT_BY_ID[m.id] = m
end
-- (탈것 모습은 사람보다 1.5~1.6배 크게 그린다. 발이 땅에 닿도록 맞춘 값)
Config.MOUNT_HIP = { horse = 6.0, tiger = 5.0, cloud = 5.2, dragon = 5.6 } -- 1.2판: 모두 더 크게 (구름·용은 땅에서 떠 있도록 높게)

------------------------------------------------------------------------
-- 컷씬: 중요한 장면에서 한 번만 (who = 말하는 이, lines = 대사)
-- boss_<보스>: 그 보스와 처음 맞붙을 때. 사부를 처음 찾았을 때는 사부의 한마디 (MASTERS.quote)
------------------------------------------------------------------------
Config.CUTSCENES = {
	intro = { who = "청운 장로", lines = { "강호에 온 것을 환영하네. 맨손 하나로 이름을 떨치겠다는 젊은이가 또 왔구먼.", "먼저 내게 와서 말을 걸게. 노란 길잡이를 따라오면 되네." } },
	gate_first = { who = "관문 수호자", lines = { "몸이 경지에 닿았다고 경지에 오르는 것은 아니다.", "나를 넘어라. 그래야 다음 경지다." } },
	tower_first = { who = "천층탑", lines = { "천층탑. 한 층 오를 때마다 적이 강해진다.", "쓰러지거나 떨어지면 처음부터다. 열 층마다 주인이 기다린다." } },
	pvp100 = { who = "강호", lines = { "배틀그라운드에서 백 명을 쓰러뜨렸다. 이제 강호에 너를 모르는 자가 없다.", "무쌍신권. 사람을 꺾기 위해 다듬어진 주먹이 네 것이다." } },
	boss_heukho = { who = "흑호", lines = { "내 산채에 발을 들인 놈은 살아서 나간 적이 없다." } },
	boss_hyeolrang = { who = "혈랑", lines = { "피 냄새가 나는군. 네 피다." } },
	boss_bingma = { who = "빙마", lines = { "이 설산에서 숨 쉬는 건 나 하나로 족하다." } },
	boss_hyeolma = { who = "혈마", lines = { "혈교의 주인 앞이다. 무릎을 꿇어라." } },
	boss_cheonma = { who = "천마", lines = { "하늘을 삼킨 내 앞에서, 고작 맨손이냐." } },
	boss_yeomje = { who = "염제", lines = { "불의 산은 들어온 자를 돌려보내지 않는다." } },
	boss_sawang = { who = "사왕", lines = { "왕의 잠을 깨운 죄, 목숨으로 갚아라." } },
	boss_cheonmun = { who = "천문장", lines = { "하늘의 문은 아무에게나 열리지 않는다." } },
	sky_first = { who = "천궁 수문장", lines = { "여기는 천상계. 땅에서 쌓은 이름은 이곳에 닿지 않는다.", "옥좌의 주인을 꺾는 날, 하늘도 너를 기억할 것이다." } },
	boss_noeje = { who = "뇌제", lines = { "하늘의 벼락은 두 번 묻지 않는다." } },
	boss_seonggun = { who = "성군", lines = { "별이 지는 자리에 네 이름도 묻어 주마." } },
	boss_cheonjon = { who = "천존", lines = { "땅에서 올라온 주먹이 어디까지 닿는지 보자." } },
	boss_bingje = { who = "빙제", lines = { "만 년을 얼어 있던 궁이다. 네 숨도 여기서 멎는다." } },
	boss_yeombong = { who = "염봉", lines = { "봉황은 죽지 않는다. 타고 남은 재에서 다시 날 뿐." } },
	boss_pungyeop = { who = "풍엽", lines = { "잎은 떨어질 때가 가장 붉다. 너도 그렇게 지거라." } },
	boss_seokwang = { who = "석왕", lines = { "천 년을 서 있었다. 너 하나에 무너질 돌이 아니다." } },
	boss_gyunwang = { who = "균왕", lines = { "숨을 들이쉬어라. 이 숲의 포자가 너를 먹을 것이다." } },
	boss_dason = { who = "다선", lines = { "차 한 잔 식을 동안만 상대해 주지." } },
	boss_pokryong = { who = "비천", lines = { "하늘에서 떨어지는 물은 바위도 뚫는다." } },
	boss_seonhak = { who = "선학", lines = { "학은 한 번 날개를 펴면 구름 위로만 난다." } },
	boss_jukwang = { who = "죽왕", lines = { "대나무는 꺾이지 않는다. 휘었다가 너를 친다." } },
	boss_wolyeong = { who = "월영", lines = { "호수에 비친 달을 베어 본 적이 있느냐." } },
	boss_geumgang = { who = "금강천왕", lines = { "이 몸은 금강이다. 부서지는 것은 네 주먹이다." } },
	boss_cheongeop = { who = "천겁", lines = { "하늘이 내린 재앙이다. 혼자라면 도망쳐라. 함께라면, 덤벼라." } },
}

------------------------------------------------------------------------
-- 배경 음악: 지역마다 (로블록스 음악 번호. 0이면 조용하다)
-- 로블록스 크리에이터 스토어에서 '모든 경험에서 쓸 수 있는' 음악 번호를 넣으세요
------------------------------------------------------------------------
Config.MUSIC = {
	volume = 0.35,
	default = 0, -- 들판 (지정이 없는 곳)
	village = 0, -- 청운 마을
	boss = 0, -- 보스와 싸울 때
	tower = 0, -- 천층탑
	snow = 0,
	cult = 0,
	rift = 0,
	volcano = 0,
	tomb = 0,
	skysea = 0,
	skyworld = 0, -- 천상계
}

------------------------------------------------------------------------
-- 로벅스 상품 (게임패스). gamepass = 로블록스 홈페이지에 만든 게임패스 번호 (0이면 아직 없음)
------------------------------------------------------------------------
Config.Premium = {
	{ id = "train2x", gamepass = 2057242581, price = 199, icon = "🔥", name = "두 배 수련", tag = "영구",
		lines = { "모든 수련의 능력치가 영원히 두 배", "소환단·강화 수련·자동 수련과 겹친다", "심마 대련 보상도 두 배" } },
	{ id = "autoTrain", gamepass = 2056912560, price = 99, icon = "🤖", name = "자동 수련", tag = "영구", toggle = true,
		lines = { "수련 화면에서 박자마다 대신 눌러 준다 ('좋음')", "수련 자리를 떠나면 멈춘다 (어디서나 오르지 않는다)", "손은 편해지지만 사람보다 빠르지 않다" } },
	{ id = "autoTrain2", gamepass = 2058388537, price = 299, icon = "⚙", name = "고급 자동 수련", tag = "영구", toggle = true, best = true,
		lines = { "수련 화면에서 박자마다 '완벽'으로 대신 눌러 준다", "강화 수련에서도 쓸 수 있다", "수련 자리를 떠나면 멈춘다" } },
	{ id = "dragon", gamepass = 2058382534, price = 399, icon = "🐉", name = "청룡 탈것", tag = "탈것",
		lines = { "비늘이 빛나는 청룡을 타고 하늘을 헤엄치듯 달린다", "모든 탈것 중 가장 빠르다 (×3.1)", "금빛 뿔과 수염, 몸을 따라 흐르는 금빛 가루" } },
}
-- 자동 수련: every = 간격(초). kinds = 능력치마다 보통 수련, advKinds = 고급이 쓰는 경지 수련
Config.AUTO_TRAIN = {
	every = 3,
	advEvery = 1,
	advMult = 1,
	kinds = { str = "rock", vit = "dummy", agi = "dummy", chi = "waterfall" },
	advKinds = { str = "ironpalm", vit = "mabo", agi = "mabo", chi = "breathing" },
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

------------------------------------------------------------------------
-- 천상계 (세계 2): 땅 위 높은 하늘의 섬들. 땅과 섞이지 않는다 (마을의 천상 문으로 오르내린다)
-- at = 섬 가운데 (가로·세로만, 높이는 y), radius = 섬 반지름
------------------------------------------------------------------------
local SY = 4000
Config.SKY = {
	y = SY,
	realm = 12, -- 천인합일부터 오를 수 있다
	portal = Vector3.new(-90, 0, -205), -- 마을 안 천상 문
	islands = {
		{ id = "skytown", name = "천궁", at = Vector3.new(0, SY, 0), radius = 200, safe = true, ground = Color3.fromRGB(235, 232, 220), material = Enum.Material.Marble },
		{ id = "cloudplain", name = "운해 평원", at = Vector3.new(0, SY, 560), radius = 210, ground = Color3.fromRGB(220, 235, 225), material = Enum.Material.Grass,
			camps = { { enemy = "cloudguard", count = 3, at = Vector3.new(-90, SY, 520) }, { enemy = "cranesword", count = 3, at = Vector3.new(90, SY, 600) }, { enemy = "cloudguard", count = 2, at = Vector3.new(0, SY, 700) } } },
		{ id = "thunder", name = "뇌정봉", at = Vector3.new(620, SY, -160), radius = 190, ground = Color3.fromRGB(70, 78, 100), material = Enum.Material.Slate,
			camps = { { enemy = "thunderguard", count = 3, at = Vector3.new(560, SY, -100) }, { enemy = "thunderimp", count = 3, at = Vector3.new(640, SY, -260) } },
			boss = { id = "noeje", at = Vector3.new(720, SY, -160) } },
		{ id = "nebula", name = "성운원", at = Vector3.new(-620, SY, -160), radius = 190, ground = Color3.fromRGB(90, 70, 130), material = Enum.Material.Glass,
			camps = { { enemy = "starspirit", count = 3, at = Vector3.new(-560, SY, -100) }, { enemy = "starsage", count = 3, at = Vector3.new(-640, SY, -260) } },
			boss = { id = "seonggun", at = Vector3.new(-720, SY, -160) } },
		{ id = "throne", name = "옥좌대", at = Vector3.new(0, SY, -640), radius = 170, ground = Color3.fromRGB(245, 230, 190), material = Enum.Material.Marble,
			camps = { { enemy = "throneguard", count = 3, at = Vector3.new(-80, SY, -580) }, { enemy = "throneblade", count = 3, at = Vector3.new(80, SY, -580) } },
			boss = { id = "cheonjon", at = Vector3.new(0, SY, -720) } },
		-- 숨은 섬: 운해 평원 서쪽 끝에서 거의 보이지 않는 다리로만 건너간다
		{ id = "subspace", name = "금 간 허공", at = Vector3.new(-760, SY, 640), radius = 60, hidden = true, ground = Color3.fromRGB(30, 20, 50), material = Enum.Material.Glass },
		-- 1.7판: 천상 확장. 운해 평원 동쪽 너머 빙정궁, 옥좌대 북쪽 너머 봉황대, 성운원 북쪽의 천공 투기장 (레이드)
		{ id = "frost", name = "빙정궁", at = Vector3.new(620, SY, 520), radius = 190, ground = Color3.fromRGB(215, 235, 250), material = Enum.Material.Glacier,
			camps = { { enemy = "frostguard", count = 3, at = Vector3.new(560, SY, 460) }, { enemy = "icespirit", count = 3, at = Vector3.new(560, SY, 600) }, { enemy = "frostguard", count = 2, at = Vector3.new(680, SY, 620) } },
			boss = { id = "bingje", at = Vector3.new(700, SY, 470) } },
		{ id = "phoenix", name = "봉황대", at = Vector3.new(0, SY, -1120), radius = 180, ground = Color3.fromRGB(150, 60, 40), material = Enum.Material.Basalt,
			camps = { { enemy = "phoenixguard", count = 3, at = Vector3.new(-80, SY, -1060) }, { enemy = "flamesage", count = 3, at = Vector3.new(80, SY, -1060) }, { enemy = "phoenixguard", count = 2, at = Vector3.new(0, SY, -1180) } },
			boss = { id = "yeombong", at = Vector3.new(0, SY, -1220) } },
		{ id = "raidarena", name = "천공 투기장", at = Vector3.new(-620, SY, -640), radius = 150, ground = Color3.fromRGB(200, 190, 175), material = Enum.Material.Slate, raid = true },
		-- 1.8판: 뇌정봉 남쪽의 비천폭 (하늘에서 떨어지는 폭포), 운해 평원 남쪽 너머의 청학봉
		{ id = "falls", name = "비천폭", at = Vector3.new(640, SY, -800), radius = 170, ground = Color3.fromRGB(110, 150, 120), material = Enum.Material.Grass,
			camps = { { enemy = "waterspirit", count = 3, at = Vector3.new(580, SY, -740) }, { enemy = "fallsguard", count = 3, at = Vector3.new(700, SY, -860) } },
			boss = { id = "pokryong", at = Vector3.new(660, SY, -900) } },
		{ id = "crane", name = "청학봉", at = Vector3.new(0, SY, 1250), radius = 180, ground = Color3.fromRGB(225, 235, 230), material = Enum.Material.Marble,
			camps = { { enemy = "craneguard", count = 3, at = Vector3.new(-70, SY, 1200) }, { enemy = "cranemaster", count = 3, at = Vector3.new(70, SY, 1300) } },
			boss = { id = "seonhak", at = Vector3.new(0, SY, 1350) } },
		-- 2.7판: 천상 확장. 청학봉 서쪽의 운무 죽림, 동쪽의 월광 호수, 봉황대 북쪽 너머의 금운사
		{ id = "bamboo", name = "운무 죽림", at = Vector3.new(-560, SY, 1000), radius = 180, ground = Color3.fromRGB(118, 156, 96), material = Enum.Material.Grass,
			camps = { { enemy = "jukgeom", count = 3, at = Vector3.new(-500, SY, 940) }, { enemy = "jukseon", count = 3, at = Vector3.new(-620, SY, 1060) }, { enemy = "jukgeom", count = 2, at = Vector3.new(-640, SY, 920) } },
			boss = { id = "jukwang", at = Vector3.new(-600, SY, 1090) } },
		{ id = "moonlake", name = "월광 호수", at = Vector3.new(560, SY, 1050), radius = 180, ground = Color3.fromRGB(196, 210, 230), material = Enum.Material.Marble,
			camps = { { enemy = "moonspirit", count = 3, at = Vector3.new(500, SY, 990) }, { enemy = "lakeguard", count = 3, at = Vector3.new(620, SY, 1110) }, { enemy = "moonspirit", count = 2, at = Vector3.new(640, SY, 980) } },
			boss = { id = "wolyeong", at = Vector3.new(560, SY, 1150) } },
		{ id = "goldtemple", name = "금운사", at = Vector3.new(0, SY, -1600), radius = 190, ground = Color3.fromRGB(236, 214, 156), material = Enum.Material.Marble,
			camps = { { enemy = "goldmonk", count = 3, at = Vector3.new(-80, SY, -1540) }, { enemy = "guardlion", count = 2, at = Vector3.new(80, SY, -1540) }, { enemy = "goldmonk", count = 2, at = Vector3.new(0, SY, -1650) } },
			boss = { id = "geumgang", at = Vector3.new(0, SY, -1700) } },
		-- 3.1판: 윤회대. 천궁 서쪽, 다른 섬보다 높이 떠 있다. 가운데 환생 제단, 뒤편에 거대한 윤회륜
		{ id = "rinnedae", name = "윤회대", at = Vector3.new(-640, SY + 40, 280), radius = 130, safe = true, ground = Color3.fromRGB(226, 220, 242), material = Enum.Material.Marble },
	},
	-- 다리: 섬 번호 둘 (hidden = 거의 보이지 않는다)
	bridges = { { 1, 2 }, { 1, 3 }, { 1, 4 }, { 1, 5 }, { 2, 6, hidden = true }, { 2, 7 }, { 5, 8 }, { 4, 9 }, { 3, 10 }, { 2, 11 }, { 11, 12 }, { 11, 13 }, { 8, 14 }, { 1, 15 } },
}
Config.SKY_BY_ID = {}
for _, isl in ipairs(Config.SKY.islands) do
	Config.SKY_BY_ID[isl.id] = isl
end
function Config.skyIslandAt(pos: Vector3): any
	if pos.Y < SY - 300 then
		return nil
	end
	for _, isl in ipairs(Config.SKY.islands) do
		if Vector3.new(pos.X - isl.at.X, 0, pos.Z - isl.at.Z).Magnitude <= isl.radius + 4 then
			return isl
		end
	end
	return nil
end
-- 숨은 사부: 금 간 허공의 아공선인 (지도에 나오지 않는다)
Config.MASTERS.agong = { name = "아공선인", at = Vector3.new(-760, SY + 1.6, 640), region = "금 간 허공 (천상계)", regionId = "subspace", secret = true,
	quote = "공간은 비어 있지 않다. 접혀 있을 뿐.", rumor = "천상계 운해 평원의 서쪽 끝에서, 보이지 않는 다리가 허공으로 이어진다더라" }
-- 천궁 정자의 운류자 (누구나 찾을 수 있다), 성운원 깊은 곳의 성하노군 (숨은 사부)
-- 3.1판 극의 사부: 천상 윤회대의 황혼권존 (세 번 환생한 자에게만 모습을 보인다)
Config.MASTERS.geukilwol = { name = "황혼권존", at = Vector3.new(-590, SY + 41.6, 330), region = "윤회대 (천상계)", regionId = "rinnedae", secret = true,
	quote = "해가 지는 것도, 달이 뜨는 것도 아니다. 그 사이가 극이다.", rumor = "천상 윤회대, 해와 달 사이의 노을 속에 권존보다 먼저 권존이었던 이가 서 있다더라" }
Config.MASTERS.unryu = { name = "운류자", at = Vector3.new(-100, SY + 1.6, -100), region = "천궁 (천상계)", regionId = "skytown",
	quote = "구름은 밀어도 흩어지지 않는다.", rumor = "천상계 천궁 북서쪽 정자에 구름처럼 앉은 노인이 있다더라" }
Config.MASTERS.seongha = { name = "성하노군", at = Vector3.new(-760, SY + 1.6, -270), region = "성운원 깊은 곳 (천상계)", regionId = "nebula", secret = true,
	quote = "별은 떨어지지 않는다. 내려올 뿐이다.", rumor = "천상계 성운원의 가장 깊은 곳, 성군의 등 뒤에 별을 헤아리는 노인이 있다더라" }
-- 초월 권법의 사부: 매화원 가장 깊은 곳, 철 모르고 벚꽃이 흩날리는 언덕의 천앵선 (지도에 나오지 않는다)
Config.SAKURA_HILL = Vector3.new(-760, 0, -760)
Config.MASTERS.chomaehwa = { name = "천앵선", at = Config.SAKURA_HILL + Vector3.new(0, 4.6, 0), region = "매화원 깊은 곳 (벚꽃 언덕)", regionId = "plum", secret = true,
	quote = "꽃은 지는 순간이 가장 아름답다. 그 순간을 베어라.", rumor = "매화원 가장 깊은 곳, 철 모르고 벚꽃이 흩날리는 언덕에 부채 든 이가 있다더라" }

-- 초·취팔선권의 사부: 취선 주막 남쪽 길가, 술독이 쌓인 마루의 만취선 (지도에 나오지 않는다)
Config.SOJU_HILL = Vector3.new(-170, 0, 980)
Config.MASTERS.chochwi = { name = "만취선", at = Config.SOJU_HILL + Vector3.new(0, 3.2, 0), region = "취선 주막 남쪽 (술독 마루)", regionId = "tavern", secret = true,
	quote = "넘어지는 게 아니야. 땅이 나한테 오는 거지.", rumor = "취선 주막에서 남쪽 길로 조금 내려가면, 술독이 산처럼 쌓인 마루에서 넥타이를 머리에 맨 노인이 코를 곤다더라" }

-- 1.9판 초·혈마신수의 사부: 혈교 본산 성벽 밖 북동쪽 끝, 혈월 제단의 혈월선 (지도에 나오지 않는다)
Config.REAPER_ALTAR = Vector3.new(2080, 0, -2080)
Config.MASTERS.chohyeolma = { name = "혈월선", at = Config.REAPER_ALTAR + Vector3.new(0, 3.3, 0), region = "혈교 본산 밖 (혈월 제단)", regionId = "cult", secret = true,
	quote = "피는 흘리라고 있는 것이다. 남의 것이든, 내 것이든.", rumor = "혈교 본산의 북동쪽 성벽 너머, 핏빛 달이 걸린 돌단에 거꾸로 꽂힌 붉은 낫이 있다더라" }

-- 2.0판 초·벽력신권의 사부: 뇌운 고원 동쪽 벼랑 끝, 쇠기둥 봉우리의 뇌천선 (지도에 나오지 않는다)
Config.THUNDER_PEAK = Vector3.new(920, 0, 560)
Config.MASTERS.chobyeok = { name = "뇌천선", at = Config.THUNDER_PEAK + Vector3.new(0, 6.4, 0), region = "뇌운 고원 동쪽 벼랑 끝 (쇠기둥 봉우리)", regionId = "plateau", secret = true,
	quote = "번개는 두 번 치지 않는다고? 나는 세 번 친다.", rumor = "뇌운 고원에서 동쪽 벼랑으로 가면, 벼락이 그치지 않는 쇠기둥 봉우리 위에 앉은 노인이 있다더라" }
-- 2.7판 초·창해신권의 사부: 서해 바닷가, 반쯤 모래에 묻힌 옛 고래 뼈 위의 고경선 (지도에 나오지 않는다)
Config.WHALE_ROCK = Vector3.new(-1880, 0, 1190)
Config.MASTERS.chochanghae = { name = "고경선", at = Config.WHALE_ROCK + Vector3.new(0, 7.4, -6), region = "서해 바닷가 고래 뼈 바위", regionId = "coast", secret = true,
	quote = "바다를 다 안다고? 그 바다의 바닥에는 아직 고래가 헤엄친다.", rumor = "창해각에서 북쪽 바닷가로 가면, 모래에 반쯤 묻힌 거대한 고래 뼈 위에 앉아 파도 소리를 듣는 노인이 있다더라" }
-- 3.8판 공백권: 세상의 남동쪽 끝, 지도에 그려지지 않은 '빈칸'에 선 이름 없는 자 (이스터에그, 지도·이야기에 나오지 않는다)
Config.NULL_SPOT = Vector3.new(4120, 0, 4120)
Config.MASTERS.gongbaek = { name = "???", at = Config.NULL_SPOT + Vector3.new(0, 2.0, 0), region = "???", regionId = "null", secret = true,
	quote = "null", rumor = "...(알 수 없는 글자가 지직거린다)" }
-- 3.7판 몽유권 (예전 호접몽권)의 사부: 남서쪽 연화정 정자 위에서 꾸벅꾸벅 조는 몽선 (지도에 나오지 않는다)
Config.MASTERS.hojeop = { name = "몽선", at = Vector3.new(-2400, 4.1, 3100), region = "남서쪽 연못 연화정", regionId = "lotus", secret = true,
	quote = "흐아암... 나는 지금 꿈을 꾸는 걸까, 꿈이 나를 꾸는 걸까.", rumor = "남서쪽 먼 연못 한가운데 정자에서, 해가 떠도 졸고 있는 노인이 있다더라. 두 번 다시 태어난 자의 꿈만 들어준다고" }
-- 3.4판 초·성하신권의 사부: 천상계 성운원 남쪽 끝, 혼천의가 도는 별 관측대 (관성대)의 천성선 (지도에 나오지 않는다)
Config.STAR_TERRACE = Vector3.new(-600, SY, -20)
Config.MASTERS.chosengha = { name = "천성선", at = Config.STAR_TERRACE + Vector3.new(0, 4.4, 0), region = "성운원 남쪽 끝 관성대 (천상계)", regionId = "nebula", secret = true,
	quote = "별을 주먹에 쥐었다고? 나는 별에게 길을 가르친다.", rumor = "성운원 남쪽 끝, 구리 고리가 저절로 도는 둥근 관측대 위에서 지팡이로 별을 헤아리는 노인이 있다더라" }
-- 2.4판 만목신권의 사부: 남서쪽 들판 만목원의 목선 (지도에는 만목원만 나온다)
Config.ANCIENT_GROVE = Vector3.new(-1700, 0, 1600)
Config.MASTERS.manmok = { name = "목선", at = Config.ANCIENT_GROVE + Vector3.new(0, 2.6, 0), region = "남서쪽 들판 깊은 숲 (만목원)", regionId = "grove", secret = true,
	quote = "나무는 서두르지 않는다. 그런데도 늘 이긴다.", rumor = "남서쪽 들판의 비틀린 고목들이 둥글게 선 숲 한가운데, 이끼 덮인 돌에 앉은 노인이 있다더라" }
-- 2.0판 각성 사부: 모든 각성 권법(진)은 상급 수련장의 각성선인에게서만 각성할 수 있다 (가까이 가야 한다)
Config.AWAKEN_MASTER = { name = "각성선인", at = Vector3.new(330, 0, -395), range = 30, quote = "깨어나는 것은 네 권법이 아니다. 너다." }

-- 천정 (天晶): 천상계에서만 나오는 빛나는 돌. 천상 상점에서 쓴다
Config.SKY_GEMS = { enemy = 2, elite = 4, boss = 80, meteor = 60 }
Config.SKY_SHOP = {
	{ id = "skyscroll", name = "천상 두루마리", icon = "📜", cost = 40, desc = "심법 두루마리 하나" },
	{ id = "skyscroll10", name = "천상 두루마리 묶음", icon = "📚", cost = 360, desc = "심법 두루마리 열 (한 번에 사면 싸다)" },
	{ id = "skyelixir", name = "천상 영약", icon = "✨", cost = 30, desc = "10분 동안 주는 피해 +15%" },
	{ id = "skypill", name = "천정단", icon = "💎", cost = 150, desc = "모든 능력치 +800" },
	{ id = "cloudmount", name = "날개구름 (탈것)", icon = "☁", cost = 600, desc = "가장 빠른 탈것 (은자 대신 천정으로)" },
	{ id = "wine", name = "선로주", icon = "🍶", cost = 120, desc = "천상의 이슬로 빚은 술 (초·취팔선권의 재료)" },
}
-- 2.5판: 초월 권법의 재료 (천상계에서만 얻는다). 넷 모두 얻는 길이 다르다
--   천앵 꽃잎: 청학봉 섬의 적이 떨어뜨린다 (선학은 한 무더기)
--   선로주: 천궁 상점에서 천정으로 빚는다
--   혈월정: 밤에만, 천상계 어디서든 적이 떨어뜨린다 (보스는 여럿)
--   뇌정석: 천상계의 보스만 떨어뜨린다 (뇌제는 더 많이)
Config.SKY_MATS = {
	{ id = "petal", name = "천앵 꽃잎", icon = "🌸", how = "청학봉 섬의 적 (선학은 꼭 둘)", island = "crane", chance = 0.35, boss = 12 },
	{ id = "wine", name = "선로주", icon = "🍶", how = "천궁 상점에서 천정으로 빚는다", shop = 120 },
	{ id = "bloodmoon", name = "혈월정", icon = "🔴", how = "밤에 천상계의 적 (보스는 꼭 둘)", night = true, chance = 0.55, boss = 6 }, -- 3.2.7판: 밤이 6분 → 2분이라 0.25 → 0.55,
	{ id = "thunderstone", name = "뇌정석", icon = "⚡", how = "천상계의 보스만 (한 번에 둘)", bossOnly = 3, bossBonus = { noeje = 8 } },
	{ id = "tidepearl", name = "비천 진주", icon = "🐚", how = "비천폭 섬의 적 (비천은 꼭 둘)", island = "falls", chance = 0.3, boss = 10 },
	{ id = "stardust", name = "별가루", icon = "✨", how = "성운원 섬의 적 (성군은 꼭 둘)", island = "nebula", chance = 0.3, boss = 10 },
}
Config.MAT_DROP_MAX = 2 -- 2.7.7판: 한 번에 얻는 천상 재료는 많아야 둘 (보스의 "한 무더기"도 둘)
Config.SKY_MAT_BY_ID = {}
for _, m in ipairs(Config.SKY_MATS) do
	Config.SKY_MAT_BY_ID[m.id] = m
end
-- 초월 권법의 조건: 원래 권법 숙련 20 + 각성 권법 숙련 20 (2.9판: 늘 그 권법 자신의 각성 권법) + 천상 재료 (시련에 한 번, 배울 때 한 번)
Config.TRANSCEND_REQ = {
	chomaehwa = { base = "maehwa", awakened = "maehwa2", lv = 20, challenge = { petal = 15 }, learn = { petal = 30 } },
	chochwi = { base = "chwi", awakened = "chwi2", lv = 20, challenge = { wine = 2 }, learn = { wine = 4 } },
	chohyeolma = { base = "hyeolma", awakened = "hyeolma2", lv = 20, challenge = { bloodmoon = 12 }, learn = { bloodmoon = 24 } },
	chobyeok = { base = "byeokryeok", awakened = "byeokryeok2", lv = 20, challenge = { thunderstone = 10 }, learn = { thunderstone = 20 } },
	chochanghae = { base = "changhae", awakened = "changhae2", lv = 20, challenge = { tidepearl = 10 }, learn = { tidepearl = 20 } },
	-- 3.4판: 성하신권에는 각성 권법(진)이 없어 원래 권법만 (재료를 더 많이)
	chosengha = { base = "seongha", lv = 20, challenge = { stardust = 12 }, learn = { stardust = 24 } },
}
for sid, R in pairs(Config.TRANSCEND_REQ) do
	for _, st in ipairs(Config.Styles) do
		if st.id == sid then
			st.unlockHint = (st.unlockHint or "") .. string.format(R.awakened and ". 그리고 원래 권법과 각성 권법(진)을 숙련 %d까지, 천상계에서만 나는 재료를 모아야 한다" or ". 그리고 원래 권법을 숙련 %d까지, 천상계에서만 나는 재료를 모아야 한다", R.lv)
		end
	end
end
Config.SKY_SHOP_BY_ID = {}
for _, it in ipairs(Config.SKY_SHOP) do
	Config.SKY_SHOP_BY_ID[it.id] = it
end
-- 운석 낙하: 천상계에 사람이 있으면 몇 분마다 섬 어딘가에 운석이 떨어지고, 운석 수호수가 나타난다
Config.METEOR = { every = 300, first = 90, warn = 6, life = 150 }
-- 천상계의 보스 셋: 체력은 아주 많고 공격은 덜 아프다 (전투력은 땅의 마지막 보스보다 조금 위)
Config.Bosses.noeje = variant(Config.Bosses.cheonmun, { name = "뇌제 · 뇌정봉의 주인", shirt = Color3.fromRGB(60, 70, 150), pants = Color3.fromRGB(25, 30, 70), hp = 450000, posture = 1200, scale = 3.0, speed = 15, coins = 120000, xp = 15000, respawn = 300, mult = 2.5,
	patterns = {
		P("rain", "천뢰", 1, { count = 8, radius = 8, spread = 26, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(150, 190, 255), hit = hit(0, 0, 0, 40, 50, 0.9, 25) }),
		P("charge", "뇌광 돌진", 1, { length = 56, width = 10, warn = 0.9, cd = 7, times = 2, pose = "w_thrust", hit = hit(0, 0, 0, 44, 55, 0.9, 55) }),
		P("donut", "뇌운 고리", 2, { inner = 9, outer = 30, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 50, 60, 1.0, 45) }),
		P("summon", "뇌령들아!", 2, { enemy = "thunderimp", count = 3, max = 6, warn = 0.9, cd = 15, pose = "w_overhead" }),
		P("quake", "만뢰 강림", 3, { radius = 26, warn = 1.4, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 70, 100, 1.4, 70, 25) }),
	} })
Config.Bosses.seonggun = variant(Config.Bosses.hyeolrang, { name = "성군 · 성운원의 주인", shirt = Color3.fromRGB(110, 70, 200), pants = Color3.fromRGB(35, 20, 70), hp = 480000, posture = 1200, scale = 2.8, speed = 17, coins = 130000, xp = 16000, respawn = 300, mult = 2.5,
	patterns = {
		P("rain", "유성우", 1, { count = 9, radius = 8, spread = 28, warn = 1.0, cd = 7, pose = "w_dual", fx = "star", color = Color3.fromRGB(200, 140, 255), hit = hit(0, 0, 0, 40, 50, 0.9, 25) }),
		P("leap", "성운 낙하", 1, { radius = 16, warn = 1.2, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 55, 70, 1.2, 45, 20) }),
		P("summon", "별의 영들", 2, { enemy = "starspirit", count = 3, max = 6, warn = 0.9, cd = 15, pose = "w_dual" }),
		P("donut", "은하 고리", 2, { inner = 9, outer = 30, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 50, 60, 1.0, 45) }),
		P("quake", "성운 붕괴", 3, { radius = 26, warn = 1.4, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 70, 100, 1.4, 70, 25) }),
	} })
Config.Bosses.cheonjon = variant(Config.Bosses.cheonmun, { name = "천존 · 천궁 옥좌의 주인", shirt = Color3.fromRGB(255, 245, 215), pants = Color3.fromRGB(200, 160, 70), hp = 650000, posture = 1600, scale = 3.4, speed = 15, coins = 250000, xp = 30000, respawn = 300, mult = 3,
	patterns = {
		P("rain", "천벌", 1, { count = 10, radius = 9, spread = 30, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(255, 230, 150), hit = hit(0, 0, 0, 44, 55, 0.9, 25) }),
		P("donut", "옥좌의 고리", 1, { inner = 10, outer = 32, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 54, 65, 1.0, 45) }),
		P("leap", "하늘 내려찍기", 2, { radius = 18, warn = 1.2, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 60, 80, 1.3, 50, 20) }),
		P("charge", "천존 돌격", 2, { length = 60, width = 11, warn = 0.9, cd = 7, times = 2, pose = "w_thrust", hit = hit(0, 0, 0, 50, 60, 1.0, 60) }),
		P("summon", "천위대!", 2, { enemy = "throneguard", count = 3, max = 6, warn = 0.9, cd = 16, pose = "w_overhead" }),
		P("quake", "천지개벽", 3, { radius = 30, warn = 1.5, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 80, 120, 1.5, 80, 30) }),
	} })

-- 1.8판: 세상 끝 네 땅의 주인 (천문보다 위, 천상계 보스보다 아래)
Config.Bosses.pungyeop = variant(Config.Bosses.cheonmun, { name = "풍엽 · 단풍산의 주인", shirt = Color3.fromRGB(220, 80, 30), pants = Color3.fromRGB(110, 35, 20), hp = 560000, posture = 900, scale = 3.2, speed = 15, coins = 60000, xp = 8000, respawn = 300, mult = 1.9,
	patterns = {
		P("rain", "낙엽비", 1, { count = 10, radius = 8, spread = 28, warn = 1.0, cd = 7, pose = "w_overhead", fx = "fire", color = Color3.fromRGB(255, 140, 50), hit = hit(0, 0, 0, 40, 50, 0.9, 25) }),
		P("donut", "단풍 회오리", 1, { inner = 9, outer = 30, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 50, 60, 1.0, 45) }),
		P("charge", "가을바람", 2, { length = 58, width = 11, warn = 0.9, cd = 7, times = 2, pose = "w_thrust", hit = hit(0, 0, 0, 46, 56, 0.9, 55) }),
		P("quake", "만산홍엽", 3, { radius = 28, warn = 1.4, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 76, 106, 1.4, 70, 25) }),
	} })
Config.Bosses.seokwang = variant(Config.Bosses.cheonmun, { name = "석왕 · 석림의 주인", shirt = Color3.fromRGB(140, 140, 130), pants = Color3.fromRGB(80, 80, 75), hp = 640000, posture = 1100, scale = 3.8, speed = 13, coins = 65000, xp = 8500, respawn = 300, mult = 2.0,
	patterns = {
		P("leap", "바위 낙하", 1, { radius = 18, warn = 1.2, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 58, 76, 1.2, 50, 20) }),
		P("donut", "돌기둥 고리", 1, { inner = 10, outer = 30, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 52, 62, 1.0, 45) }),
		P("summon", "석림 정령들아", 2, { enemy = "karstsprite", count = 3, max = 6, warn = 0.9, cd = 16, pose = "w_overhead" }),
		P("quake", "만석붕괴", 3, { radius = 30, warn = 1.5, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 80, 110, 1.5, 75, 28) }),
	} })
Config.Bosses.gyunwang = variant(Config.Bosses.cheonmun, { name = "균왕 · 거균림의 주인", shirt = Color3.fromRGB(200, 50, 60), pants = Color3.fromRGB(240, 230, 210), hp = 720000, posture = 1100, scale = 3.6, speed = 14, coins = 70000, xp = 9000, respawn = 300, mult = 2.1,
	patterns = {
		P("rain", "포자비", 1, { count = 12, radius = 8, spread = 30, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(190, 120, 255), hit = hit(0, 0, 0, 42, 52, 0.9, 25) }),
		P("summon", "포자 귀졸들", 2, { enemy = "sporeimp", count = 3, max = 6, warn = 0.9, cd = 15, pose = "w_overhead" }),
		P("charge", "버섯 돌진", 2, { length = 56, width = 12, warn = 0.9, cd = 7, times = 2, pose = "w_thrust", hit = hit(0, 0, 0, 48, 58, 1.0, 60) }),
		P("quake", "독포자 폭발", 3, { radius = 30, warn = 1.5, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 82, 112, 1.5, 75, 28) }),
	} })
Config.Bosses.dason = variant(Config.Bosses.cheonmun, { name = "다선 · 운무 차밭의 주인", shirt = Color3.fromRGB(230, 240, 220), pants = Color3.fromRGB(100, 140, 90), hp = 800000, posture = 1200, scale = 3.0, speed = 17, coins = 80000, xp = 10000, respawn = 300, mult = 2.2,
	patterns = {
		P("rain", "찻잎비", 1, { count = 11, radius = 8, spread = 30, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(170, 230, 140), hit = hit(0, 0, 0, 44, 54, 0.9, 25) }),
		P("leap", "운무 낙하", 1, { radius = 18, warn = 1.1, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 60, 78, 1.2, 50, 20) }),
		P("donut", "찻물 고리", 2, { inner = 10, outer = 32, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 54, 64, 1.0, 45) }),
		P("quake", "운무 만개", 3, { radius = 30, warn = 1.5, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 84, 116, 1.5, 78, 28) }),
	} })

-- 1.7판: 새 섬의 주인 둘과, 천공 투기장에 정해진 때마다 내려오는 레이드 보스
Config.Bosses.bingje = variant(Config.Bosses.cheonmun, { name = "빙제 · 빙정궁의 주인", shirt = Color3.fromRGB(190, 225, 255), pants = Color3.fromRGB(60, 100, 160), hp = 820000, posture = 1800, scale = 3.3, speed = 15, coins = 320000, xp = 36000, respawn = 300, mult = 3.4,
	patterns = {
		P("rain", "빙우", 1, { count = 10, radius = 8, spread = 30, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(190, 235, 255), hit = hit(0, 0, 0, 46, 58, 1.0, 25) }),
		P("donut", "설한 고리", 1, { inner = 10, outer = 32, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 56, 66, 1.1, 45) }),
		P("summon", "얼음 정령들아", 2, { enemy = "icespirit", count = 3, max = 6, warn = 0.9, cd = 16, pose = "w_overhead" }),
		P("charge", "빙하 돌진", 2, { length = 62, width = 12, warn = 0.9, cd = 7, times = 2, pose = "w_thrust", hit = hit(0, 0, 0, 52, 62, 1.0, 60) }),
		P("quake", "만년빙 붕괴", 3, { radius = 30, warn = 1.5, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 84, 124, 1.6, 80, 30) }),
	} })
Config.Bosses.yeombong = variant(Config.Bosses.cheonmun, { name = "염봉 · 봉황대의 주인", shirt = Color3.fromRGB(255, 110, 40), pants = Color3.fromRGB(140, 30, 15), hp = 1000000, posture = 2000, scale = 3.5, speed = 16, coins = 420000, xp = 45000, respawn = 300, mult = 3.9,
	patterns = {
		P("rain", "불새비", 1, { count = 11, radius = 9, spread = 32, warn = 1.0, cd = 7, pose = "w_overhead", fx = "fire", color = Color3.fromRGB(255, 150, 60), hit = hit(0, 0, 0, 48, 60, 1.0, 25) }),
		P("leap", "봉황 낙하", 1, { radius = 19, warn = 1.1, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 62, 82, 1.3, 50, 20) }),
		P("donut", "불꽃 날개", 2, { inner = 10, outer = 34, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 58, 70, 1.1, 50) }),
		P("summon", "불새 술사들", 2, { enemy = "flamesage", count = 3, max = 6, warn = 0.9, cd = 16, pose = "w_overhead" }),
		P("charge", "열화 돌격", 3, { length = 64, width = 12, warn = 0.85, cd = 6, times = 3, pose = "w_thrust", hit = hit(0, 0, 0, 54, 64, 1.0, 60) }),
		P("quake", "봉황 재생", 3, { radius = 32, warn = 1.5, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 90, 130, 1.6, 80, 30) }),
	} })
Config.Bosses.cheongeop = variant(Config.Bosses.cheonmun, { name = "천겁 · 하늘의 재앙", shirt = Color3.fromRGB(40, 30, 60), pants = Color3.fromRGB(15, 10, 25), hp = 1400000, posture = 3200, scale = 5.2, speed = 15, coins = 600000, xp = 60000, respawn = 99999, mult = 4.2, raid = true,
	patterns = {
		P("rain", "겁화", 1, { count = 14, radius = 9, spread = 40, warn = 1.0, cd = 6, pose = "w_overhead", fx = "fire", color = Color3.fromRGB(190, 80, 255), hit = hit(0, 0, 0, 46, 58, 1.0, 25) }),
		P("donut", "재앙의 고리", 1, { inner = 12, outer = 40, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 56, 68, 1.1, 50) }),
		P("summon", "겁병들아!", 2, { enemy = "throneblade", count = 4, max = 8, warn = 0.9, cd = 18, pose = "w_overhead" }),
		P("charge", "하늘 가르기", 2, { length = 80, width = 14, warn = 0.9, cd = 7, times = 3, pose = "w_thrust", hit = hit(0, 0, 0, 54, 66, 1.0, 60) }),
		P("leap", "천붕", 2, { radius = 22, warn = 1.2, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 66, 86, 1.3, 55, 22) }),
		P("quake", "천겁", 3, { radius = 40, warn = 1.7, cd = 10, pose = "w_overhead", hit = hit(0, 0, 0, 96, 140, 1.7, 90, 32) }),
	} })
Config.Bosses.pokryong = variant(Config.Bosses.cheonmun, { name = "비천 · 비천폭의 주인", shirt = Color3.fromRGB(90, 160, 220), pants = Color3.fromRGB(30, 70, 110), hp = 900000, posture = 1900, scale = 3.4, speed = 16, coins = 360000, xp = 40000, respawn = 300, mult = 3.6,
	patterns = {
		P("rain", "폭포비", 1, { count = 11, radius = 8, spread = 30, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(150, 210, 255), hit = hit(0, 0, 0, 46, 58, 1.0, 25) }),
		P("charge", "급류 돌진", 1, { length = 62, width = 12, warn = 0.9, cd = 7, times = 2, pose = "w_thrust", hit = hit(0, 0, 0, 52, 62, 1.0, 60) }),
		P("summon", "물보라 정령들", 2, { enemy = "waterspirit", count = 3, max = 6, warn = 0.9, cd = 16, pose = "w_overhead" }),
		P("quake", "천폭 낙하", 3, { radius = 31, warn = 1.5, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 86, 126, 1.6, 80, 30) }),
	} })
Config.Bosses.seonhak = variant(Config.Bosses.cheonmun, { name = "선학 · 청학봉의 주인", shirt = Color3.fromRGB(250, 250, 250), pants = Color3.fromRGB(40, 110, 90), hp = 1150000, posture = 2100, scale = 3.3, speed = 18, coins = 480000, xp = 50000, respawn = 300, mult = 4.1,
	patterns = {
		P("rain", "깃털비", 1, { count = 12, radius = 8, spread = 32, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(230, 255, 240), hit = hit(0, 0, 0, 48, 60, 1.0, 25) }),
		P("leap", "학 내리꽂기", 1, { radius = 19, warn = 1.0, cd = 7, pose = "w_overhead", hit = hit(0, 0, 0, 64, 84, 1.3, 50, 22) }),
		P("donut", "날개 고리", 2, { inner = 10, outer = 34, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 58, 70, 1.1, 50) }),
		P("charge", "청학 비상", 3, { length = 66, width = 12, warn = 0.85, cd = 6, times = 3, pose = "w_thrust", hit = hit(0, 0, 0, 56, 66, 1.0, 60) }),
		P("quake", "학명", 3, { radius = 32, warn = 1.5, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 92, 132, 1.6, 80, 30) }),
	} })
-- 2.7판: 새 섬의 주인 셋
Config.Bosses.jukwang = variant(Config.Bosses.cheonmun, { name = "죽왕 · 운무 죽림의 주인", shirt = Color3.fromRGB(110, 150, 90), pants = Color3.fromRGB(50, 70, 40), hp = 1250000, posture = 2200, scale = 3.2, speed = 19, coins = 520000, xp = 54000, respawn = 300, mult = 4.3,
	patterns = {
		P("rain", "죽창 비", 1, { count = 12, radius = 7, spread = 32, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(150, 210, 110), hit = hit(0, 0, 0, 50, 62, 1.0, 25) }),
		P("charge", "대숲 질주", 1, { length = 66, width = 11, warn = 0.85, cd = 7, times = 2, pose = "w_thrust", hit = hit(0, 0, 0, 56, 66, 1.0, 60) }),
		P("summon", "죽림 검객들", 2, { enemy = "jukgeom", count = 3, max = 6, warn = 0.9, cd = 16, pose = "w_overhead" }),
		P("donut", "대숲 고리", 2, { inner = 10, outer = 34, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 60, 72, 1.1, 50) }),
		P("quake", "만죽 낙하", 3, { radius = 32, warn = 1.5, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 94, 136, 1.6, 80, 30) }),
	} })
Config.Bosses.wolyeong = variant(Config.Bosses.cheonmun, { name = "월영 · 월광 호수의 주인", shirt = Color3.fromRGB(225, 232, 250), pants = Color3.fromRGB(90, 100, 150), hp = 1300000, posture = 2250, scale = 3.2, speed = 18, coins = 540000, xp = 56000, respawn = 300, mult = 4.4,
	patterns = {
		P("rain", "달빛 비", 1, { count = 12, radius = 8, spread = 32, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(220, 230, 255), hit = hit(0, 0, 0, 52, 64, 1.0, 25) }),
		P("leap", "월하 낙영", 1, { radius = 19, warn = 1.0, cd = 7, pose = "w_overhead", hit = hit(0, 0, 0, 66, 86, 1.3, 50, 22) }),
		P("summon", "월광 정령들", 2, { enemy = "moonspirit", count = 3, max = 6, warn = 0.9, cd = 16, pose = "w_overhead" }),
		P("charge", "호수 위 달그림자", 3, { length = 66, width = 12, warn = 0.85, cd = 6, times = 3, pose = "w_thrust", hit = hit(0, 0, 0, 58, 68, 1.0, 60) }),
		P("quake", "만월", 3, { radius = 33, warn = 1.5, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 96, 138, 1.6, 80, 30) }),
	} })
Config.Bosses.geumgang = variant(Config.Bosses.cheonmun, { name = "금강천왕 · 금운사의 주인", shirt = Color3.fromRGB(235, 175, 60), pants = Color3.fromRGB(140, 80, 30), hp = 1400000, posture = 2400, scale = 3.6, speed = 16, coins = 580000, xp = 60000, respawn = 300, mult = 4.6,
	patterns = {
		P("quake", "금강 진각", 1, { radius = 24, warn = 1.2, cd = 8, pose = "w_overhead", hit = hit(0, 0, 0, 70, 96, 1.4, 60, 20) }),
		P("rain", "금빛 법륜", 1, { count = 10, radius = 9, spread = 30, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(255, 220, 120), hit = hit(0, 0, 0, 54, 66, 1.0, 25) }),
		P("summon", "사자 수호수들", 2, { enemy = "guardlion", count = 2, max = 4, warn = 0.9, cd = 16, pose = "w_overhead" }),
		P("donut", "금강 고리", 2, { inner = 10, outer = 36, warn = 1.2, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 62, 76, 1.1, 50) }),
		P("leap", "천왕 낙하", 3, { radius = 22, warn = 1.0, cd = 7, pose = "w_overhead", hit = hit(0, 0, 0, 76, 100, 1.4, 60, 24) }),
		P("quake", "금강불괴", 3, { radius = 34, warn = 1.6, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 100, 144, 1.6, 80, 30) }),
	} })
-- 천공 투기장의 레이드: 정해진 때마다 천겁이 내려온다. 그때 천상계에 있는 사람 수만큼 체력이 늘고, 친 만큼 나눠 받는다
Config.RAID = {
	island = "raidarena",
	boss = "cheongeop",
	first = 240, -- 서버가 열리고 처음 내려오기까지 (초)
	every = 900, -- 그다음부터 (15분마다)
	warn = 25, -- 알리고 내려오기까지
	life = 480, -- 이만큼 안에 못 쓰러뜨리면 하늘로 돌아간다
	hpPer = 0.6, -- 사람 한 명이 늘 때마다 체력 +60%
	minShare = 0.01, -- 체력의 1% 이상 친 사람만 보상
	gems = 400, -- 천정 (기여 비율에 따라 0.4~1.4배)
	coins = 250000,
	scrolls = 2,
	statKills = 10, -- 능력치: 내 전투력의 적 처치 몫 × 이만큼 × (0.3 + 기여)
}

-- 1.7판 구름 미궁: 천궁의 🌀 문으로 들어가는 혼자만의 미궁. 구름 다리로 이어진 일곱 방을 차례로 넘는다
-- 앞 방을 넘어야 다음 다리의 구름 문이 걷힌다. 적의 세기는 들어간 사람의 전투력에 맞춘다
Config.Bosses.unmugun = variant(Config.Bosses.cheonmun, { name = "운무군 · 미궁의 주인", shirt = Color3.fromRGB(200, 215, 240), pants = Color3.fromRGB(80, 95, 140), hp = 6000, posture = 900, scale = 2.6, speed = 17, coins = 0, xp = 2000, respawn = 99999,
	patterns = {
		P("rain", "운무우", 1, { count = 8, radius = 7, spread = 22, warn = 1.0, cd = 7, pose = "w_overhead", fx = "star", color = Color3.fromRGB(200, 225, 255), hit = hit(0, 0, 0, 36, 44, 0.8, 25) }),
		P("donut", "구름 고리", 1, { inner = 8, outer = 26, warn = 1.1, cd = 8, pose = "w_sweep", hit = hit(0, 0, 0, 44, 54, 1.0, 45) }),
		P("summon", "운병들아", 2, { enemy = "cloudguard", count = 2, max = 4, warn = 0.9, cd = 16, pose = "w_overhead" }),
		P("charge", "안개 돌진", 2, { length = 50, width = 10, warn = 0.85, cd = 7, times = 2, pose = "w_thrust", hit = hit(0, 0, 0, 40, 50, 0.9, 55) }),
		P("quake", "운해 붕괴", 3, { radius = 26, warn = 1.4, cd = 9, pose = "w_overhead", hit = hit(0, 0, 0, 66, 96, 1.4, 70, 25) }),
	} })
Config.MAZE = {
	arena = Vector3.new(1700, 1800, -1700), -- 첫 미궁 자리 (사람마다 옆으로 비켜 놓는다)
	slotGap = 600,
	slots = 8,
	roomGap = 120, -- 방과 방 사이 (가운데끼리)
	roomRadius = 36,
	power = 0.75, -- 적 전투력 = 들어간 사람의 전투력 × 이만큼
	bossPower = 1.15,
	bossHp = 3,
	killGain = 0.5, -- 미궁의 적을 쓰러뜨리면 보통 처치 몫의 절반만큼 능력치
	trap = { every = 1.8, warn = 1.0, radius = 7, count = 3, dmg = 0.1 }, -- 함정 방: 최대 체력의 10%
	chest = { gems = 30, coins = 20000 },
	reward = { gems = 220, coins = 150000, scrolls = 2, statKills = 4 },
	cooldown = 600, -- 다 넘은 보상은 10분에 한 번 (그 사이엔 상자와 처치 몫만)
	rooms = {
		{ kind = "wave", name = "구름 회랑", enemies = { "cloudguard", "cranesword" }, count = 4, color = Color3.fromRGB(225, 238, 255) },
		{ kind = "trap", name = "벼락의 방", enemies = { "thunderimp", "thunderguard" }, count = 4, trap = "bolt", color = Color3.fromRGB(130, 160, 255) },
		{ kind = "elite", name = "수호자의 방", enemies = { "throneguard", "throneblade" }, count = 2, power = 1.6, color = Color3.fromRGB(250, 225, 160) },
		{ kind = "treasure", name = "보물방", color = Color3.fromRGB(255, 205, 90) },
		{ kind = "wave", name = "별의 방", enemies = { "starspirit", "starsage" }, count = 5, color = Color3.fromRGB(190, 140, 255) },
		{ kind = "trap", name = "서리의 방", enemies = { "icespirit", "frostguard" }, count = 4, trap = "ice", color = Color3.fromRGB(180, 230, 255) },
		{ kind = "boss", name = "미궁의 주인", boss = "unmugun", color = Color3.fromRGB(150, 165, 210) },
	},
}

------------------------------------------------------------------------
-- 베타 14: 보스는 덜 아프게 (오래 겨루는 싸움), 후반 보스는 아주 질기게, 조금 느리게
------------------------------------------------------------------------
Config.BOSS_DMG = 0.7 -- 모든 보스의 공격력 배율 (1.0판: 0.6 → 0.7)
Config.LATE_BOSS_MATCH = 0.75 -- 2.3판: 후반 보스는 훨씬 센 상대에게 그 전투력의 이만큼까지 힘을 끌어올린다 (보상은 원래 몫)
Config.LATE_BOSS_DMG = 1.56 -- 후반 보스 (빙마부터 천상계까지)의 공격력 배율 (1.0판: 0.45 → 0.52). 2.7.1판: 3배 (0.52 → 1.56)
Config.BOSS_LEASH = 340 -- 보스가 자기 자리에서 이만큼 끌려 나와야 돌아간다 (보통 적은 150)
Config.BOSS_CHASE = 200 -- 상대가 이만큼 멀어져야 보스가 쫓기를 그만둔다
-- 흡혈 한도: 거대한 체력의 보스를 치면 한 대에 다 차던 것을 막는다
Config.LIFESTEAL_HIT_CAP = 0.015 -- 한 대에 최대 체력의 이만큼까지
Config.LIFESTEAL_SEC_CAP = 0.04 -- 1초 동안 최대 체력의 이만큼까지 (진 혈마신수는 0.05)
Config.LIFESTEAL_FRENZY = 1.5 -- 광란 중 흡혈 배율
for _, id in ipairs({ "bingma", "hyeolma", "cheonma", "yeomje", "sawang", "cheonmun", "noeje", "seonggun", "cheonjon", "bingje", "yeombong", "cheongeop", "pungyeop", "seokwang", "gyunwang", "dason", "pokryong", "seonhak", "jukwang", "wolyeong", "geumgang" }) do
	local b = Config.Bosses[id]
	if b then
		b.late = true
	end
end
Config.BOSS_SPEED = 0.85 -- 모든 보스의 걸음 배율 (순간이동하듯 붙지 않게)
Config.BOSS_PHASE_SPEED = 0.05 -- 단계마다 걸음이 빨라지는 양
for id, k in pairs({ bingma = 4, hyeolma = 5, cheonma = 6, yeomje = 6, sawang = 6, cheonmun = 7 }) do
	local b = Config.Bosses[id]
	if b then
		b.hp = math.floor(b.hp * k)
		b.speed = math.floor(b.speed * 0.85)
	end
end

------------------------------------------------------------------------
-- 1.9판: 업적과 칭호. 조건을 채우면 저절로 이루어지고 보상을 받는다 (칭호가 붙은 업적은 이름표 위에 칭호를 달 수 있다)
-- kind: kills 쓰러뜨린 적 · bossSum 보스 처치 합 · boss 그 보스 · realm 경지 · rebirth 환생 · styles 익힌 권법 · transcend 초월 권법
--       mastery 숙련 최대 권법 · tower 천층탑 최고 층 · pvp 비무 승리 · raid 레이드 승리 · maze 미궁 완주 · masters 찾은 사부 · mounts 탈것 · manuals 심법
------------------------------------------------------------------------
Config.ACHIEVEMENTS = {
	{ id = "k100", icon = "⚔", name = "백인참", desc = "적 100을 쓰러뜨린다", kind = "kills", n = 100, coins = 3000 },
	{ id = "k1000", icon = "⚔", name = "천인참", desc = "적 1,000을 쓰러뜨린다", kind = "kills", n = 1000, coins = 30000, title = "천인참" },
	{ id = "k10000", icon = "⚔", name = "만인적", desc = "적 10,000을 쓰러뜨린다", kind = "kills", n = 10000, coins = 300000, scrolls = 3, title = "만인적" },
	{ id = "k100000", icon = "☠", name = "강호의 재앙", desc = "적 100,000을 쓰러뜨린다", kind = "kills", n = 100000, coins = 3000000, scrolls = 10, title = "강호의 재앙" },
	{ id = "b1", icon = "👹", name = "첫 보스", desc = "보스 하나를 쓰러뜨린다", kind = "bossSum", n = 1, coins = 5000 },
	{ id = "b100", icon = "👹", name = "보스 사냥꾼", desc = "보스를 100번 쓰러뜨린다", kind = "bossSum", n = 100, coins = 500000, scrolls = 5, title = "보스 사냥꾼" },
	{ id = "b1000", icon = "👹", name = "마왕 도살자", desc = "보스를 1,000번 쓰러뜨린다", kind = "bossSum", n = 1000, coins = 5000000, scrolls = 15, title = "마왕 도살자" },
	{ id = "hyeolma", icon = "🩸", name = "혈교 토벌", desc = "혈마를 쓰러뜨린다", kind = "boss", arg = "hyeolma", n = 1, coins = 20000, title = "혈교 토벌자" },
	{ id = "cheonma", icon = "🌑", name = "하늘을 되찾다", desc = "천마를 쓰러뜨린다", kind = "boss", arg = "cheonma", n = 1, coins = 100000, title = "천마를 꺾은 자" },
	{ id = "cheonjon", icon = "👑", name = "옥좌의 주인", desc = "천존을 쓰러뜨린다", kind = "boss", arg = "cheonjon", n = 1, gems = 300, title = "옥좌를 빼앗은 자" },
	{ id = "seonhak", icon = "🕊", name = "학을 꺾다", desc = "선학을 쓰러뜨린다", kind = "boss", arg = "seonhak", n = 1, gems = 400 },
	{ id = "raid1", icon = "☄", name = "재앙을 막다", desc = "천상 레이드 천겁을 쓰러뜨린다 (기여 인정)", kind = "raid", n = 1, gems = 500, title = "재앙을 막은 자" },
	{ id = "raid20", icon = "☄", name = "하늘의 방패", desc = "천상 레이드를 20번 이긴다", kind = "raid", n = 20, gems = 3000, scrolls = 10, title = "하늘의 방패" },
	{ id = "maze1", icon = "🌀", name = "구름 속으로", desc = "구름 미궁을 끝까지 간다", kind = "maze", n = 1, gems = 100 },
	{ id = "maze30", icon = "🌀", name = "미궁의 길잡이", desc = "구름 미궁을 30번 끝까지 간다", kind = "maze", n = 30, gems = 1500, scrolls = 5, title = "미궁의 길잡이" },
	{ id = "r5", icon = "⛰", name = "절정 고수", desc = "절정의 경지에 오른다", kind = "realm", n = 5, coins = 10000 },
	{ id = "r9", icon = "⛰", name = "사경을 넘어", desc = "사경의 경지에 오른다", kind = "realm", n = 9, coins = 100000, title = "사경 고수" },
	{ id = "r13", icon = "⛰", name = "무극", desc = "무극의 경지에 오른다", kind = "realm", n = 13, coins = 1000000, title = "무극" },
	{ id = "r16", icon = "✴", name = "하늘 밖의 하늘", desc = "천외천의 경지에 오른다", kind = "realm", n = 16, coins = 5000000, scrolls = 10, title = "천외천" },
	{ id = "r20", icon = "👑", name = "권왕", desc = "모든 경지의 끝, 권왕에 오른다", kind = "realm", n = 20, coins = 100000000, scrolls = 50, title = "권왕" },
	{ id = "rb1", icon = "♻", name = "다시 태어나다", desc = "처음 환생한다", kind = "rebirth", n = 1, coins = 2000000, title = "환생자" },
	{ id = "rb2", icon = "♻", name = "두 번째 삶", desc = "두 번 환생한다", kind = "rebirth", n = 2, coins = 5000000, scrolls = 10 },
	{ id = "rb3", icon = "♻", name = "윤회의 바퀴", desc = "세 번 환생한다", kind = "rebirth", n = 3, coins = 12000000, scrolls = 15, title = "윤회자" },
	{ id = "rb4", icon = "♻", name = "사환지존", desc = "네 번 환생한다", kind = "rebirth", n = 4, coins = 30000000, scrolls = 25, title = "사환지존" },
	{ id = "s5", icon = "🥋", name = "다섯 갈래", desc = "권법 다섯을 익힌다", kind = "styles", n = 5, coins = 20000 },
	{ id = "s15", icon = "🥋", name = "백가쟁명", desc = "권법 열다섯을 익힌다", kind = "styles", n = 15, coins = 1000000, title = "백가의 주인" },
	{ id = "s25", icon = "🥋", name = "만권귀종", desc = "권법 스물다섯을 익힌다", kind = "styles", n = 25, coins = 10000000, scrolls = 20, title = "만권귀종" },
	{ id = "t1", icon = "🌸", name = "초월", desc = "초월 권법 하나를 익힌다", kind = "transcend", n = 1, coins = 3000000, title = "초월자" },
	{ id = "t3", icon = "🌸", name = "삼초", desc = "초월 권법 셋을 모두 익힌다", kind = "transcend", n = 3, coins = 20000000, scrolls = 20, title = "삼초" },
	{ id = "m1", icon = "✦", name = "완전 각성", desc = "권법 하나의 숙련을 끝까지 올린다", kind = "mastery", n = 1, coins = 20000 },
	{ id = "m10", icon = "✦", name = "열 손의 달인", desc = "권법 열의 숙련을 끝까지 올린다", kind = "mastery", n = 10, coins = 2000000, title = "열 손의 달인" },
	{ id = "tw30", icon = "🗼", name = "탑의 문턱", desc = "천층탑 30층에 오른다", kind = "tower", n = 30, coins = 20000 },
	{ id = "tw100", icon = "🗼", name = "백층", desc = "천층탑 100층에 오른다", kind = "tower", n = 100, coins = 1000000, scrolls = 5, title = "백층 돌파" },
	{ id = "tw150", icon = "🗼", name = "구름 위의 층", desc = "천층탑 150층에 오른다", kind = "tower", n = 150, coins = 10000000, scrolls = 15, title = "탑의 주인" },
	{ id = "pvp10", icon = "🏆", name = "비무 열 승", desc = "다른 무인을 열 번 이긴다", kind = "pvp", n = 10, coins = 50000 },
	{ id = "pvp100", icon = "🏆", name = "비무왕", desc = "다른 무인을 백 번 이긴다", kind = "pvp", n = 100, coins = 2000000, title = "비무왕" },
	{ id = "mst10", icon = "🧭", name = "사부를 찾아서", desc = "사부 열을 찾는다", kind = "masters", n = 10, coins = 200000, title = "구도자" },
	{ id = "mnt4", icon = "🐎", name = "말 부자", desc = "탈것 넷을 가진다", kind = "mounts", n = 4, gems = 200 },
	{ id = "man10", icon = "📜", name = "심법 수집가", desc = "심법 열을 가진다", kind = "manuals", n = 10, coins = 200000 },
}
Config.ACH_BY_ID = {}
for i, a in ipairs(Config.ACHIEVEMENTS) do
	a.index = i
	Config.ACH_BY_ID[a.id] = a
end
-- 칭호 빛깔: 칭호가 붙은 업적의 차례(어려울수록 뒤)로 정하지 않고, 업적 갈래로 정한다
Config.ACH_COLOR = {
	kills = Color3.fromRGB(255, 140, 120), bossSum = Color3.fromRGB(255, 110, 80), boss = Color3.fromRGB(255, 90, 90), raid = Color3.fromRGB(255, 170, 70),
	maze = Color3.fromRGB(170, 210, 255), realm = Color3.fromRGB(255, 240, 160), rebirth = Color3.fromRGB(255, 120, 220), styles = Color3.fromRGB(160, 255, 190),
	transcend = Color3.fromRGB(255, 160, 210), mastery = Color3.fromRGB(255, 220, 120), tower = Color3.fromRGB(150, 230, 255), pvp = Color3.fromRGB(255, 200, 80),
	masters = Color3.fromRGB(200, 255, 230), mounts = Color3.fromRGB(220, 200, 160), manuals = Color3.fromRGB(210, 180, 255),
}

------------------------------------------------------------------------
-- 2.8판: 보스와 그 땅 졸병의 전투력 차이. 보스의 체력이 너무 커서 (졸병의 9~21배) 같은 땅의 보스가 딴 세상처럼 셌다.
-- 이제 보스는 그 땅 졸병 (가운데) 전투력의 BOSS_POWER_RATIO배까지만 (넘으면 체력을 깎는다). 한 대는 졸병 한 대의 BOSS_HIT_RATIO배
------------------------------------------------------------------------
Config.BOSS_POWER_RATIO = 4
Config.BOSS_HIT_RATIO = 2 -- 보스의 한 대는 그 땅 졸병 한 대의 이만큼 (늘 이 몫에 맞춘다: 너무 약하거나 한 방에 죽지 않게)
-- 적 한 명의 체력·피해 배율·전투력 (Npc.spawn과 같은 셈)
function Config.npcStats(def: any, at: Vector3, isBoss: boolean): (number, number, number)
	local lv = Config.enemyLevel(at)
	local mult = def.mult or 1
	local hp = math.floor(def.hp * (isBoss and Config.ENEMY_BOSS_HP or Config.ENEMY_HP) * (1 + Config.ENEMY_HP_LEVEL * (lv - 1)) * mult)
	local dm = Config.ENEMY_DMG * (1 + Config.ENEMY_DMG_LEVEL * (lv - 1)) * mult ^ Config.ENEMY_DMG_MULT_POW * (isBoss and (def.late and Config.LATE_BOSS_DMG or Config.BOSS_DMG) or 1) * (def.dmgScale or 1)
	return hp, dm, Config.enemyPower(dm, hp, isBoss)
end
-- 한 대의 크기 (기술마다 가장 센 맞힘의 평균)
local function hitSize(def: any): number
	local sum, n = 0, 0
	for _, mv in ipairs(def.moves or {}) do
		local best = 0
		for _, h in ipairs(mv.hits or {}) do
			best = math.max(best, h.dmg or 0)
		end
		if best > 0 then
			sum += best
			n += 1
		end
	end
	return n > 0 and sum / n or 14
end
do
	local function camp(camps: any): (number?, number?)
		local list = {}
		for _, c in ipairs(camps or {}) do
			local e = Config.Enemies[c.enemy]
			if e then
				local _, dm, pw = Config.npcStats(e, c.at, false)
				table.insert(list, { pw, dm * hitSize(e) })
			end
		end
		if #list == 0 then
			return nil, nil
		end
		table.sort(list, function(x, y)
			return x[1] < y[1]
		end)
		local mid = list[math.ceil(#list / 2)]
		return mid[1], mid[2]
	end
	local function norm(boss: any, camps: any)
		local b = boss and Config.Bosses[boss.id]
		local ep, ehit = camp(camps)
		if not b or not ep or not ehit or b.powerNormed then
			return
		end
		b.powerNormed = true
		-- 한 대를 졸병의 BOSS_HIT_RATIO배로
		local _, dm0 = Config.npcStats(b, boss.at, true)
		b.dmgScale = Config.BOSS_HIT_RATIO * ehit / math.max(1e-6, dm0 * hitSize(b))
		-- 전투력은 졸병의 BOSS_POWER_RATIO배까지 (체력으로 맞춘다)
		local _, _, bp = Config.npcStats(b, boss.at, true)
		local target = ep * Config.BOSS_POWER_RATIO
		if bp > target then
			b.hp = math.max(1, math.floor(b.hp * (target / bp) ^ 2))
		end
	end
	for _, r in ipairs(Config.Regions) do
		norm(r.boss, r.camps)
	end
	for _, isl in ipairs(Config.SKY.islands) do
		norm(isl.boss, isl.camps)
	end
end

------------------------------------------------------------------------
-- 3.7판 사부의 부탁 (미니 퀘스트): 높은 권법의 사부는 시험 전에 부탁을 하나씩 한다. 다 들어주어야 시험을 낸다
-- 단계: visit (그곳에 가기, night = 밤에만) · find (흩어진 것 찾기, T) · order (차례대로 짚기, T. 틀리면 처음부터) ·
--       kill (그 적 쓰러뜨리기) · return (사부에게 돌아가 말 걸기)
------------------------------------------------------------------------
local function ring(c: Vector3, r: number, n: number, y: number?): { Vector3 }
	local out = {}
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2 + 0.5
		table.insert(out, c + Vector3.new(math.cos(a) * r, y or 0, math.sin(a) * r))
	end
	return out
end
local RAINBOW = { Color3.fromRGB(255, 120, 130), Color3.fromRGB(255, 180, 110), Color3.fromRGB(255, 232, 120), Color3.fromRGB(140, 226, 150), Color3.fromRGB(130, 180, 255) }
Config.MINIQUEST = {
	taecho = { title = "처음의 돌", steps = {
		{ kind = "visit", at = Vector3.new(1100, 0, -2700), r = 26, text = "세상의 처음은 하늘에서 떨어졌다. 별똥 분화구 한가운데에 서 보아라", say = "발밑이 따뜻하다. 아주 오래전, 여기에 별이 떨어졌다." },
		{ kind = "find", name = "처음의 돌", icon = "🪨", items = ring(Vector3.new(1100, 0, -2700), 48, 3), text = "분화구 둘레에 흩어진 '처음의 돌' 셋을 주워라 (빛나는 돌, T)" },
		{ kind = "return", text = "처음의 돌을 시원자에게 가져가라" },
	} },
	ilwol = { title = "해와 달의 차례", steps = {
		{ kind = "order", name = "해의 기둥", stones = { { at = Vector3.new(3200, 0, 3300) + Vector3.new(20, 0, 0), h = 2 }, { at = Vector3.new(3200, 0, 3300) + Vector3.new(0, 0, 20), h = 3.5 }, { at = Vector3.new(3200, 0, 3300) + Vector3.new(-20, 0, 0), h = 5 }, { at = Vector3.new(3200, 0, 3300) + Vector3.new(0, 0, -20), h = 6.5 } },
			text = "해시계 광장의 해의 기둥 넷을, 해가 떠오르듯 가장 낮은 것부터 가장 높은 것까지 차례로 짚어라 (T)" },
		{ kind = "visit", at = Vector3.new(1100, 0, 2500), r = 16, night = true, text = "달이 뜬 밤, 거울 호수 가운데 섬에 서서 물에 비친 달을 보아라", say = "물속의 달이 하늘의 달보다 밝다." },
		{ kind = "return", text = "해와 달을 모두 본 몸으로 권존에게 돌아가라" },
	} },
	yeonggeop = { title = "멈춘 시계", steps = {
		{ kind = "find", name = "시계 톱니", icon = "⚙", items = { Vector3.new(40, 0, 2290), Vector3.new(-46, 0, 2210), Vector3.new(3236, 0, 3336), Vector3.new(3166, 0, 3262) }, text = "버려진 마을과 해시계 광장에 흩어진 멈춘 시계의 톱니 넷을 모아라 (T)" },
		{ kind = "visit", at = Vector3.new(2700, 0, 900), r = 30, text = "천년 종루 아래에서 종소리가 몇 번 울리는지 들어라", say = "종이 한 번 울렸다. 그런데 소리는 천 년째 울리고 있다." },
		{ kind = "return", text = "톱니를 영겁노인에게 가져가라" },
	} },
	agong = { title = "허공의 틈", steps = {
		{ kind = "kill", enemy = "voidwalker", n = 5, text = "허공 균열의 허공 마인 다섯을 쓰러뜨려 틈을 닫아라" },
		{ kind = "visit", at = Vector3.new(1400, 0, 1400), r = 24, text = "끊어진 하늘다리 끝에 서서, 다리 너머의 허공을 들여다보아라", say = "허공도 너를 들여다본다." },
		{ kind = "return", text = "아공선인에게 돌아가라" },
	} },
	seongha = { title = "별을 헤아리는 밤", steps = {
		{ kind = "visit", at = Vector3.new(-1900, 0, -800), r = 22, night = true, text = "밤에 별바위 고리 한가운데에서 별을 헤아려라", say = "별을 헤아리다 보니 별도 너를 헤아린다." },
		{ kind = "find", name = "떨어진 별 조각", icon = "⭐", items = ring(Vector3.new(-620, SY, -160), 70, 5, 0), text = "천상계 성운원에 떨어진 별 조각 다섯을 주워라 (T)" },
		{ kind = "return", text = "별 조각을 성하노군에게 가져가라" },
	} },
	manmok = { title = "시든 묘목", steps = {
		{ kind = "find", name = "시든 묘목", icon = "🌱", items = ring(Vector3.new(-1700, 0, 1600), 46, 4), text = "만목원 둘레의 시든 묘목 넷에 물을 주어라 (T)" },
		{ kind = "kill", enemy = "bogbrute", n = 3, text = "숲을 썩게 하는 독안개 늪의 늪 거한 셋을 쓰러뜨려라" },
		{ kind = "return", text = "목선에게 돌아가라" },
	} },
	chomaehwa = { title = "떨어진 부채 장식", steps = {
		{ kind = "find", name = "부채 장식", icon = "🌸", items = ring(Config.SAKURA_HILL, 40, 3), text = "벚꽃 언덕 아래 떨어진 부채 장식 셋을 찾아라 (T)" },
		{ kind = "return", text = "천앵선에게 돌아가라" },
	} },
	chochwi = { title = "술잔 찾기", steps = {
		{ kind = "find", name = "만취선의 술잔", icon = "🍶", items = ring(Config.SOJU_HILL, 36, 4), text = "술독 마루 둘레에 굴러간 만취선의 술잔 넷을 찾아라 (T)" },
		{ kind = "return", text = "술잔을 만취선에게 가져가라" },
	} },
	chohyeolma = { title = "핏빛 달 아래", steps = {
		{ kind = "visit", at = Vector3.new(1000, 0, 1000), r = 28, night = true, text = "밤에 혈월곡의 핏빛 달 아래에 서라", say = "달빛이 손톱 끝까지 붉게 스민다." },
		{ kind = "return", text = "혈월선에게 돌아가라" },
	} },
	chobyeok = { title = "번개를 기다리다", steps = {
		{ kind = "visit", at = Vector3.new(1300, 0, -1000), r = 26, text = "만검총 한가운데, 가장 높은 검 아래에서 번개를 기다려라", say = "검 끝에서 파란 불꽃이 튄다. 번개가 너를 알아보았다." },
		{ kind = "return", text = "뇌천선에게 돌아가라" },
	} },
	chochanghae = { title = "고래 뼈 조각", steps = {
		{ kind = "find", name = "고래 뼈 조각", icon = "🦴", items = ring(Config.WHALE_ROCK, 44, 4), text = "서해 바닷가 고래 뼈 바위 둘레의 뼈 조각 넷을 찾아라 (T)" },
		{ kind = "return", text = "고경선에게 돌아가라" },
	} },
	chosengha = { title = "별 등의 차례", steps = {
		{ kind = "order", name = "별 등", stones = { { at = Config.STAR_TERRACE + Vector3.new(10, 0, 4), h = 1.5 }, { at = Config.STAR_TERRACE + Vector3.new(-9, 0, 6), h = 2.5 }, { at = Config.STAR_TERRACE + Vector3.new(4, 0, -10), h = 3.5 }, { at = Config.STAR_TERRACE + Vector3.new(-6, 0, -8), h = 4.5 }, { at = Config.STAR_TERRACE + Vector3.new(0, 0, 10), h = 5.5 } },
			text = "관성대의 별 등 다섯을, 가장 낮은 별부터 가장 높은 별까지 차례로 밝혀라 (T)" },
		{ kind = "return", text = "천성선에게 돌아가라" },
	} },
	hojeop = { title = "몽선의 꿈", steps = {
		{ kind = "find", name = "잠든 별", icon = "⭐", items = ring(Vector3.new(-2400, 0, 3100), 62, 5), text = "연화정 둘레에 떨어져 잠든 별 다섯을 깨워라 (T)" },
		{ kind = "visit", at = Vector3.new(1100, 0, 2500), r = 18, night = true, text = "달이 뜬 밤, 거울 호수에 비친 달 위에 서 보아라", say = "물에 비친 달이 흔들린다. 꿈이 깨어나는 소리다." },
		{ kind = "order", name = "연꽃 등", stones = { { at = Vector3.new(-2400, 0, 3100) + Vector3.new(30, 0, 52), color = RAINBOW[1] }, { at = Vector3.new(-2400, 0, 3100) + Vector3.new(-26, 0, 54), color = RAINBOW[2] }, { at = Vector3.new(-2400, 0, 3100) + Vector3.new(0, 0, 58), color = RAINBOW[3] }, { at = Vector3.new(-2400, 0, 3100) + Vector3.new(14, 0, 62), color = RAINBOW[4] }, { at = Vector3.new(-2400, 0, 3100) + Vector3.new(-12, 0, 63), color = RAINBOW[5] } },
			text = "연화정 남쪽 물가의 연꽃 등 다섯을 무지개의 차례로 밝혀라 (빨강 → 주황 → 노랑 → 초록 → 파랑, T)" },
		{ kind = "return", text = "몽선을 깨워라 (말을 걸어라)" },
	} },
	gongbaek = { title = "null", steps = {
		{ kind = "find", name = "지워진 글자", icon = "⬛", items = { Vector3.new(3700, 0, -1806), Vector3.new(3700, 0, 214), Vector3.new(2100, 0, -3683), Vector3.new(-2200, 0, -3737) }, text = "강호의 랜드마크 넷 (버려진 광산 입구 · 일검 바위 틈 · 귀부 비석 뒤 · 선인송 아래)에 떨어진 지워진 글자를 주워라 (T)" },
		{ kind = "visit", at = Vector3.new(-4120, 0, -4120), r = 30, night = true, text = "밤에, 세상의 반대편 끝 (북서쪽 맨 끝)의 아무것도 없는 곳에 서라", say = "...아무것도 없다. 정말로 아무것도 없다. 소리조차." },
		{ kind = "order", name = "글자 상자", stones = { { at = Config.NULL_SPOT + Vector3.new(-9, 0, 12), label = "N" }, { at = Config.NULL_SPOT + Vector3.new(9, 0, 12), label = "U" }, { at = Config.NULL_SPOT + Vector3.new(-9, 0, -12), label = "L" }, { at = Config.NULL_SPOT + Vector3.new(9, 0, -12), label = "L" } },
			text = "빈칸의 글자 상자 넷을 그 이름의 차례로 짚어라 (T)" },
		{ kind = "return", text = "???에게 말을 걸어라" },
	} },
}

return Config
