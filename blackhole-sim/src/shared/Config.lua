-- Config (ModuleScript, ReplicatedStorage)
-- 블랙홀 시뮬레이터의 모든 수치. 서버와 클라이언트가 같이 읽는다.
-- 밸런스를 바꾸고 싶으면 이 파일만 고치면 된다.

local Config = {}

Config.GAME_TITLE = "BLACK HOLE"
Config.VERSION = "beta-2"

-- 테스트 계정: 스튜디오에서 플레이하거나 게임 주인이 들어오면 켜진다. 기록은 저장하지 않는다
-- 정식 공개 전에 false로 바꾸면 주인도 일반 계정으로 들어간다
Config.TEST_MODE = true

------------------------------------------------------------------------
-- 업그레이드 3종 (질량으로 산다, 빅뱅하면 사라진다)
------------------------------------------------------------------------
Config.Upgrades = {
	{ id = "size", name = "크기", icon = "⚫", desc = "더 큰 것을 삼킨다", maxLevel = 46, base = 4, growth = 1.4 },
	{ id = "pull", name = "흡입력", icon = "🌀", desc = "더 멀리서 끌어당긴다", maxLevel = 15, base = 25, growth = 1.7 },
	{ id = "mult", name = "질량 배율", icon = "💠", desc = "삼킬 때 얻는 질량 +25%", maxLevel = 40, base = 40, growth = 1.5 },
}
Config.UPGRADE_BY_ID = {}
for _, u in ipairs(Config.Upgrades) do
	Config.UPGRADE_BY_ID[u.id] = u
end

function Config.upgradeCost(id: string, level: number): number
	local u = Config.UPGRADE_BY_ID[id]
	return math.floor(u.base * u.growth ^ level)
end

-- 반지름 = 1.5 × 1.13^레벨 (레벨 하나에 13%씩 커진다)
function Config.radius(sizeLv: number): number
	return 1.5 * 1.13 ^ sizeLv
end

------------------------------------------------------------------------
-- 빅뱅: 크기 레벨 38(반지름 약 157) 이상이면 처음부터 다시 시작하고 암흑 물질을 받는다
------------------------------------------------------------------------
Config.BIGBANG_LEVEL = 38

-- 받는 암흑 물질: 레벨 38에서 3개, 그 위로 한 레벨마다 2개씩 더
function Config.darkMatterReward(sizeLv: number, bigbang: number): number
	return 3 + math.max(0, sizeLv - Config.BIGBANG_LEVEL) * 2 + bigbang // 2
end

-- 빅뱅 상점: 암흑 물질로 사는 영구 업그레이드 (빅뱅해도 남는다)
Config.BigbangShop = {
	{ id = "start", name = "시작 크기", icon = "🌱", desc = "빅뱅 뒤 크기 레벨 +2로 시작", maxLevel = 8, base = 2, step = 2 },
	{ id = "respawn", name = "빠른 재생산", icon = "♻", desc = "삼킨 물체가 12% 더 빨리 다시 생긴다", maxLevel = 5, base = 3, step = 3 },
	{ id = "mass", name = "암흑 증폭", icon = "🌑", desc = "질량 +50%", maxLevel = 20, base = 3, step = 2 },
	{ id = "speed", name = "광속", icon = "⚡", desc = "이동 속도 +15%", maxLevel = 5, base = 2, step = 2 },
	{ id = "pull", name = "사건의 지평선", icon = "🕳", desc = "흡입 범위 +15%", maxLevel = 5, base = 3, step = 3 },
	{ id = "luck", name = "행운의 별", icon = "🍀", desc = "캡슐에서 전설 이상이 나올 확률 +15%", maxLevel = 5, base = 4, step = 3 },
	{ id = "slots", name = "위성 궤도", icon = "🛰", desc = "위성 장착 칸 +1", maxLevel = 2, base = 10, step = 15 },
}
Config.BB_BY_ID = {}
for _, b in ipairs(Config.BigbangShop) do
	Config.BB_BY_ID[b.id] = b
end

function Config.bigbangShopCost(id: string, level: number): number
	local b = Config.BB_BY_ID[id]
	return b.base + b.step * level
end

------------------------------------------------------------------------
-- 세계 2개, 구역 11개
-- 세계는 x 위치로 떨어져 있고, 구역은 z = 0에서 +z 쪽으로 이어진다
-- need = 그 구역에 들어가는 데 필요한 크기 (문이 이 크기에서 열린다)
------------------------------------------------------------------------
Config.Worlds = {
	{ id = 1, name = "지구와 우주", x = 0, needBigbang = 0, sky = Color3.fromRGB(150, 190, 255) },
	{ id = 2, name = "과자 왕국", x = 9000, needBigbang = 1, sky = Color3.fromRGB(255, 190, 230) },
}

Config.Zones = {
	-- 세계 1
	{ world = 1, name = "공원", need = 0, width = 260, length = 260, ground = Color3.fromRGB(110, 170, 80), material = Enum.Material.Grass, respawn = 5 },
	{ world = 1, name = "마을", need = 6, width = 380, length = 340, ground = Color3.fromRGB(140, 150, 110), material = Enum.Material.Grass, respawn = 6 },
	{ world = 1, name = "도시", need = 14, width = 600, length = 520, ground = Color3.fromRGB(95, 95, 105), material = Enum.Material.Asphalt, respawn = 7 },
	{ world = 1, name = "대도시", need = 30, width = 960, length = 820, ground = Color3.fromRGB(70, 72, 82), material = Enum.Material.Concrete, respawn = 8 },
	{ world = 1, name = "바다와 산", need = 65, width = 1500, length = 1300, ground = Color3.fromRGB(60, 130, 190), material = Enum.Material.Sand, respawn = 9 },
	{ world = 1, name = "우주", need = 140, width = 2600, length = 2200, ground = Color3.fromRGB(20, 18, 40), material = Enum.Material.Slate, respawn = 10 },
	-- 세계 2
	{ world = 2, name = "젤리 들판", need = 0, width = 260, length = 260, ground = Color3.fromRGB(255, 190, 220), material = Enum.Material.SmoothPlastic, respawn = 5 },
	{ world = 2, name = "과자 마을", need = 6, width = 400, length = 360, ground = Color3.fromRGB(240, 210, 160), material = Enum.Material.Sand, respawn = 6 },
	{ world = 2, name = "케이크 도시", need = 14, width = 640, length = 560, ground = Color3.fromRGB(255, 240, 230), material = Enum.Material.SmoothPlastic, respawn = 7 },
	{ world = 2, name = "아이스크림 산맥", need = 30, width = 1100, length = 900, ground = Color3.fromRGB(200, 240, 255), material = Enum.Material.Snow, respawn = 8 },
	{ world = 2, name = "사탕 우주", need = 65, width = 2400, length = 2100, ground = Color3.fromRGB(70, 30, 90), material = Enum.Material.SmoothPlastic, respawn = 10 },
}

------------------------------------------------------------------------
-- 물체. zone = 위 Zones 순서, size = 삼키는 데 필요한 반지름, mass = 얻는 질량, count = 놓이는 개수
-- 세계 2의 질량은 같은 크기 세계 1 물체의 약 5배
------------------------------------------------------------------------
Config.Objects = {
	-- 1 공원
	{ id = "pebble", name = "돌멩이", zone = 1, size = 0.8, mass = 2, count = 18 },
	{ id = "flower", name = "꽃", zone = 1, size = 0.9, mass = 2, count = 16 },
	{ id = "ball", name = "축구공", zone = 1, size = 1.2, mass = 4, count = 10 },
	{ id = "trashcan", name = "쓰레기통", zone = 1, size = 1.8, mass = 8, count = 8 },
	{ id = "bench", name = "벤치", zone = 1, size = 2.6, mass = 14, count = 8 },
	{ id = "bush", name = "덤불", zone = 1, size = 2.8, mass = 16, count = 8 },
	{ id = "tree", name = "작은 나무", zone = 1, size = 3.0, mass = 20, count = 10 },
	-- 2 마을
	{ id = "mailbox", name = "우체통", zone = 2, size = 3.5, mass = 15, count = 10 },
	{ id = "bicycle", name = "자전거", zone = 2, size = 4, mass = 20, count = 10 },
	{ id = "lamp", name = "가로등", zone = 2, size = 4.6, mass = 28, count = 10 },
	{ id = "car", name = "자동차", zone = 2, size = 6, mass = 50, count = 12 },
	{ id = "bigtree", name = "큰 나무", zone = 2, size = 7, mass = 70, count = 10 },
	{ id = "hut", name = "오두막", zone = 2, size = 9, mass = 120, count = 8 },
	-- 3 도시
	{ id = "truck", name = "트럭", zone = 3, size = 11, mass = 250, count = 10 },
	{ id = "bus", name = "버스", zone = 3, size = 13, mass = 380, count = 10 },
	{ id = "house", name = "집", zone = 3, size = 15, mass = 550, count = 10 },
	{ id = "shop", name = "가게", zone = 3, size = 18, mass = 800, count = 8 },
	{ id = "fountain", name = "분수대", zone = 3, size = 20, mass = 1100, count = 6 },
	-- 4 대도시
	{ id = "building", name = "빌딩", zone = 4, size = 26, mass = 3000, count = 12 },
	{ id = "tower", name = "타워", zone = 4, size = 32, mass = 5500, count = 10 },
	{ id = "stadium", name = "경기장", zone = 4, size = 38, mass = 9000, count = 6 },
	{ id = "ferris", name = "대관람차", zone = 4, size = 42, mass = 14000, count = 6 },
	-- 5 바다와 산
	{ id = "ship", name = "배", zone = 5, size = 55, mass = 40000, count = 10 },
	{ id = "lighthouse", name = "등대", zone = 5, size = 60, mass = 60000, count = 8 },
	{ id = "island", name = "섬", zone = 5, size = 75, mass = 120000, count = 6 },
	{ id = "mountain", name = "산", zone = 5, size = 90, mass = 250000, count = 6 },
	-- 6 우주
	{ id = "satellite", name = "인공위성", zone = 6, size = 115, mass = 800000, count = 8 },
	{ id = "asteroid", name = "소행성", zone = 6, size = 140, mass = 1500000, count = 8 },
	{ id = "moon", name = "달", zone = 6, size = 180, mass = 4000000, count = 5 },
	{ id = "planet", name = "행성", zone = 6, size = 240, mass = 12000000, count = 4 },
	{ id = "sun", name = "태양", zone = 6, size = 320, mass = 50000000, count = 2 },
	-- 7 젤리 들판
	{ id = "gummy", name = "젤리곰", zone = 7, size = 0.8, mass = 10, count = 18 },
	{ id = "candy", name = "사탕", zone = 7, size = 0.9, mass = 10, count = 16 },
	{ id = "lollipop", name = "막대사탕", zone = 7, size = 1.3, mass = 20, count = 12 },
	{ id = "macaron", name = "마카롱", zone = 7, size = 1.8, mass = 40, count = 10 },
	{ id = "cupcake", name = "컵케이크", zone = 7, size = 2.6, mass = 70, count = 10 },
	{ id = "donut", name = "도넛", zone = 7, size = 3.0, mass = 100, count = 10 },
	-- 8 과자 마을
	{ id = "cookie", name = "쿠키", zone = 8, size = 3.5, mass = 75, count = 12 },
	{ id = "pudding", name = "푸딩", zone = 8, size = 4.5, mass = 120, count = 10 },
	{ id = "icecream", name = "아이스크림콘", zone = 8, size = 6, mass = 250, count = 12 },
	{ id = "cottontree", name = "솜사탕 나무", zone = 8, size = 7, mass = 350, count = 10 },
	{ id = "gingerhouse", name = "과자 집", zone = 8, size = 9, mass = 600, count = 8 },
	-- 9 케이크 도시
	{ id = "candycar", name = "사탕 자동차", zone = 9, size = 12, mass = 1500, count = 10 },
	{ id = "cake", name = "케이크", zone = 9, size = 15, mass = 2750, count = 10 },
	{ id = "chocofountain", name = "초콜릿 분수", zone = 9, size = 18, mass = 4000, count = 8 },
	{ id = "weddingcake", name = "웨딩 케이크 탑", zone = 9, size = 22, mass = 6000, count = 6 },
	-- 10 아이스크림 산맥
	{ id = "lollitower", name = "롤리팝 탑", zone = 10, size = 28, mass = 18000, count = 10 },
	{ id = "jellycastle", name = "젤리 성", zone = 10, size = 34, mass = 30000, count = 8 },
	{ id = "icemountain", name = "아이스크림 산", zone = 10, size = 45, mass = 60000, count = 6 },
	-- 11 사탕 우주
	{ id = "donutplanet", name = "도넛 행성", zone = 11, size = 80, mass = 1200000, count = 8 },
	{ id = "candymoon", name = "사탕 달", zone = 11, size = 120, mass = 7500000, count = 6 },
	{ id = "cakestar", name = "케이크 별", zone = 11, size = 200, mass = 50000000, count = 4 },
	{ id = "candysun", name = "사탕 태양", zone = 11, size = 320, mass = 250000000, count = 2 },
}
Config.OBJECT_BY_ID = {}
for _, o in ipairs(Config.Objects) do
	Config.OBJECT_BY_ID[o.id] = o
end

------------------------------------------------------------------------
-- 위성 (펫): 블랙홀 둘레를 돌며 질량 배율을 준다. 캡슐을 깨서 얻는다
-- 같은 위성 5개를 합치면 황금 위성 (배율 효과 2.5배)
------------------------------------------------------------------------
Config.Rarities = {
	{ name = "일반", color = Color3.fromRGB(190, 190, 200) },
	{ name = "희귀", color = Color3.fromRGB(80, 160, 255) },
	{ name = "영웅", color = Color3.fromRGB(180, 100, 255) },
	{ name = "전설", color = Color3.fromRGB(255, 190, 50) },
	{ name = "신화", color = Color3.fromRGB(255, 90, 180) },
	{ name = "비밀", color = Color3.fromRGB(255, 60, 60) },
}

-- shape는 SatBuilder 모양 이름, chance는 퍼센트
Config.Capsules = {
	{
		id = "star",
		name = "별빛 캡슐",
		world = 1,
		cost = 1000,
		color = Color3.fromRGB(150, 180, 255),
		sats = {
			{ id = "rock", name = "돌멩이 위성", rarity = 1, mult = 1.2, chance = 50, shape = "rock", color = Color3.fromRGB(150, 140, 130) },
			{ id = "minimoon", name = "꼬마 달", rarity = 1, mult = 1.35, chance = 25, shape = "moon", color = Color3.fromRGB(220, 220, 215) },
			{ id = "comet", name = "혜성", rarity = 2, mult = 1.7, chance = 15, shape = "comet", color = Color3.fromRGB(150, 220, 255) },
			{ id = "ufo", name = "UFO", rarity = 3, mult = 2.4, chance = 8, shape = "ufo", color = Color3.fromRGB(120, 255, 160) },
			{ id = "minihole", name = "꼬마 블랙홀", rarity = 4, mult = 4, chance = 1.9, shape = "hole", color = Color3.fromRGB(170, 90, 255) },
			{ id = "goldstar", name = "황금 별", rarity = 5, mult = 10, chance = 0.1, shape = "star", color = Color3.fromRGB(255, 210, 60) },
		},
	},
	{
		id = "galaxy",
		name = "은하 캡슐",
		world = 1,
		cost = 20000000,
		color = Color3.fromRGB(190, 110, 255),
		sats = {
			{ id = "ringplanet", name = "고리 행성", rarity = 1, mult = 3, chance = 50, shape = "ringed", color = Color3.fromRGB(230, 190, 120) },
			{ id = "robot", name = "탐사 로봇", rarity = 2, mult = 4, chance = 28, shape = "robot", color = Color3.fromRGB(200, 205, 215) },
			{ id = "crystal", name = "수정 소행성", rarity = 3, mult = 6, chance = 14, shape = "crystal", color = Color3.fromRGB(120, 240, 255) },
			{ id = "jelly", name = "성운 해파리", rarity = 4, mult = 10, chance = 6.5, shape = "jelly", color = Color3.fromRGB(255, 140, 230) },
			{ id = "binary", name = "쌍성", rarity = 5, mult = 20, chance = 1.4, shape = "binary", color = Color3.fromRGB(255, 240, 160) },
			{ id = "quasar", name = "퀘이사", rarity = 5, mult = 60, chance = 0.1, shape = "quasar", color = Color3.fromRGB(120, 200, 255) },
		},
	},
	{
		id = "candy",
		name = "과자 캡슐",
		world = 2,
		cost = 2000000000,
		color = Color3.fromRGB(255, 150, 200),
		sats = {
			{ id = "gummysat", name = "젤리 위성", rarity = 1, mult = 20, chance = 50, shape = "gummy", color = Color3.fromRGB(255, 90, 120) },
			{ id = "cookieplanet", name = "쿠키 행성", rarity = 2, mult = 30, chance = 28, shape = "cookie", color = Color3.fromRGB(210, 150, 90) },
			{ id = "candycomet", name = "사탕 혜성", rarity = 3, mult = 50, chance = 14, shape = "comet", color = Color3.fromRGB(255, 120, 200) },
			{ id = "cakeufo", name = "케이크 UFO", rarity = 4, mult = 90, chance = 6.5, shape = "ufo", color = Color3.fromRGB(255, 230, 240) },
			{ id = "rainbowdonut", name = "무지개 도넛", rarity = 5, mult = 180, chance = 1.4, shape = "donut", color = Color3.fromRGB(255, 160, 220) },
			{ id = "candygod", name = "과자의 신", rarity = 5, mult = 500, chance = 0.1, shape = "star", color = Color3.fromRGB(255, 120, 255) },
		},
	},
}

-- 우주 위성 패키지(로벅스)로만 얻는 비밀 위성
Config.ExclusiveSats = {
	{ id = "spacedragon", name = "우주 용", rarity = 6, mult = 150, shape = "dragon", color = Color3.fromRGB(255, 70, 70) },
	{ id = "godeye", name = "신의 눈", rarity = 6, mult = 175, shape = "eye", color = Color3.fromRGB(255, 220, 120) },
	{ id = "timering", name = "시간의 고리", rarity = 6, mult = 200, shape = "timering", color = Color3.fromRGB(120, 255, 220) },
}

Config.SAT_BY_ID = {}
for _, cap in ipairs(Config.Capsules) do
	for _, s in ipairs(cap.sats) do
		Config.SAT_BY_ID[s.id] = s
	end
end
for _, s in ipairs(Config.ExclusiveSats) do
	Config.SAT_BY_ID[s.id] = s
end
Config.CAPSULE_BY_ID = {}
for _, c in ipairs(Config.Capsules) do
	Config.CAPSULE_BY_ID[c.id] = c
end

Config.SAT_INVENTORY = 60
Config.SAT_SLOTS = 3
Config.GOLD_COUNT = 5
Config.GOLD_POWER = 2.5

-- 위성 하나의 배율
function Config.satMult(id: string, gold: boolean?): number
	local s = Config.SAT_BY_ID[id]
	if not s then
		return 1
	end
	if gold then
		return 1 + (s.mult - 1) * Config.GOLD_POWER
	end
	return s.mult
end

------------------------------------------------------------------------
-- 블랙홀 스킨
--   unlock: bigbang = 빅뱅 횟수, dm = 암흑 물질로 사기, pass = 게임패스, world2 = 세계 2의 사탕 태양 삼키기
--   effect: 테두리와 소용돌이 꾸밈 (fire, ice, galaxy, candy, gold, eye, rainbow)
------------------------------------------------------------------------
Config.Skins = {
	{ id = "violet", name = "보랏빛 블랙홀", a = Color3.fromRGB(170, 90, 255), b = Color3.fromRGB(255, 120, 200), unlock = "bigbang", value = 0 },
	{ id = "quasar", name = "푸른 퀘이사", a = Color3.fromRGB(70, 170, 255), b = Color3.fromRGB(150, 255, 255), unlock = "bigbang", value = 1 },
	{ id = "giant", name = "붉은 거성", a = Color3.fromRGB(255, 80, 60), b = Color3.fromRGB(255, 200, 90), unlock = "bigbang", value = 2 },
	{ id = "nebula", name = "초록 성운", a = Color3.fromRGB(80, 255, 140), b = Color3.fromRGB(200, 255, 120), unlock = "bigbang", value = 3 },
	{ id = "golden", name = "황금 특이점", a = Color3.fromRGB(255, 200, 60), b = Color3.fromRGB(255, 255, 200), unlock = "bigbang", value = 5, effect = "gold" },
	{ id = "rainbow", name = "무지개 우주", a = Color3.fromRGB(255, 90, 90), b = Color3.fromRGB(90, 160, 255), unlock = "bigbang", value = 8, effect = "rainbow" },
	{ id = "ice", name = "얼음 소용돌이", a = Color3.fromRGB(150, 230, 255), b = Color3.fromRGB(255, 255, 255), unlock = "dm", value = 6, effect = "ice" },
	{ id = "lava", name = "용암 소용돌이", a = Color3.fromRGB(255, 110, 30), b = Color3.fromRGB(255, 230, 80), unlock = "dm", value = 12, effect = "fire" },
	{ id = "milkyway", name = "은하수", a = Color3.fromRGB(120, 140, 255), b = Color3.fromRGB(255, 240, 255), unlock = "dm", value = 25, effect = "galaxy" },
	{ id = "sweet", name = "사탕 소용돌이", a = Color3.fromRGB(255, 120, 190), b = Color3.fromRGB(140, 230, 255), unlock = "world2", value = 0, effect = "candy" },
	{ id = "vip", name = "황금 VIP", a = Color3.fromRGB(255, 215, 80), b = Color3.fromRGB(255, 150, 40), unlock = "pass", value = "vip", effect = "gold" },
	{ id = "godeye", name = "신의 눈", a = Color3.fromRGB(255, 230, 140), b = Color3.fromRGB(255, 90, 60), unlock = "pass", value = "petpack", effect = "eye" },
}
Config.SKIN_BY_ID = {}
for i, s in ipairs(Config.Skins) do
	s.index = i
	Config.SKIN_BY_ID[s.id] = s
end

------------------------------------------------------------------------
-- 로벅스 상점
-- id에 로블록스 웹사이트에서 만든 게임패스·개발자 상품 번호를 넣는다 (0이면 아직 없음)
-- 가격은 웹사이트에서 정한다. price는 화면에 보여 줄 권장 가격
-- 번호가 0일 때 스튜디오(테스트 계정)에서 누르면 산 것으로 처리해서 시험해 볼 수 있다
------------------------------------------------------------------------
Config.GamePasses = {
	{ key = "vip", id = 0, price = 299, icon = "👑", name = "VIP", desc = "질량 1.5배, 위성 칸 +1, 재생산 20% 빨라짐, 황금 VIP 스킨, 👑 이름표와 채팅 태그" },
	{ key = "mass2", id = 0, price = 399, icon = "💠", name = "질량 2배", desc = "삼킬 때 얻는 질량이 영원히 2배" },
	{ key = "speed2", id = 0, price = 149, icon = "⚡", name = "속도 2배", desc = "이동 속도가 영원히 2배" },
	{ key = "slots2", id = 0, price = 249, icon = "🛰", name = "위성 칸 +2", desc = "위성을 2개 더 데리고 다닌다" },
	{ key = "luck", id = 0, price = 349, icon = "🍀", name = "행운 부화", desc = "캡슐에서 전설 이상이 나올 확률 2배" },
	{ key = "triple", id = 0, price = 199, icon = "🥚", name = "3개 부화", desc = "캡슐을 한 번에 3개씩 깬다" },
	{ key = "petpack", id = 0, price = 2199, icon = "🐉", name = "우주 위성 패키지", desc = "비밀 위성 3종(우주 용 ×150, 신의 눈 ×175, 시간의 고리 ×200) + 전용 스킨 '신의 눈' + 위성 칸 +1", featured = true },
}
Config.Products = {
	{ key = "boost30", id = 0, price = 49, icon = "🔥", name = "질량 2배 30분", desc = "30분 동안 질량 2배 (겹쳐 사면 시간이 늘어남)" },
	{ key = "respawn30", id = 0, price = 39, icon = "♻", name = "빠른 재생산 30분", desc = "30분 동안 물체가 2배 빨리 다시 생김" },
	{ key = "massS", id = 0, price = 25, icon = "💠", name = "질량 꾸러미 (소)", desc = "다음 크기 업그레이드 3번 값만큼 질량" },
	{ key = "massL", id = 0, price = 99, icon = "💎", name = "질량 꾸러미 (대)", desc = "다음 크기 업그레이드 10번 값만큼 질량" },
	{ key = "dm10", id = 0, price = 149, icon = "🌑", name = "암흑 물질 10개", desc = "빅뱅 상점에서 쓰는 암흑 물질" },
}
Config.PASS_BY_KEY = {}
for _, p in ipairs(Config.GamePasses) do
	Config.PASS_BY_KEY[p.key] = p
end
Config.PRODUCT_BY_KEY = {}
for _, p in ipairs(Config.Products) do
	Config.PRODUCT_BY_KEY[p.key] = p
end

------------------------------------------------------------------------
-- 별똥별: 가끔 내 근처에 떨어진다. 삼키면 60초 동안 질량 2배
------------------------------------------------------------------------
Config.STAR_INTERVAL = 40
Config.STAR_LIFETIME = 25
Config.STAR_BOOST = 60

------------------------------------------------------------------------
-- 계산
------------------------------------------------------------------------
-- 반지름 바깥으로 더 끌어당기는 거리
function Config.pullRange(radius: number, pullLv: number, bbPull: number?): number
	return (radius * (0.15 + 0.07 * pullLv) + 1.5) * (1 + 0.15 * (bbPull or 0))
end

function Config.walkSpeed(radius: number, bbSpeed: number?, pass2: boolean?): number
	local base = math.min(150, 18 + radius * 0.4) * (1 + 0.15 * (bbSpeed or 0))
	return base * (pass2 and 2 or 1)
end

-- 질량 배율 전체. info = { mult, bigbang, bbMass, sats(위성 배율), vip, mass2, boost, star }
function Config.totalMult(info: any): number
	local m = (1 + 0.25 * (info.mult or 0)) * (1 + (info.bigbang or 0)) * (1 + 0.5 * (info.bbMass or 0))
	m *= info.sats or 1
	if info.vip then
		m *= 1.5
	end
	if info.mass2 then
		m *= 2
	end
	if info.boost then
		m *= 2
	end
	if info.star then
		m *= 2
	end
	return m
end

-- 재생산 시간 배율 (작을수록 빠르다)
function Config.respawnFactor(bbRespawn: number, vip: boolean?, boost: boolean?): number
	local f = 1 - 0.12 * bbRespawn
	if vip then
		f *= 0.8
	end
	if boost then
		f *= 0.5
	end
	return math.max(0.15, f)
end

-- 세계에 있는 구역 번호들
function Config.zonesOf(world: number): { number }
	local list = {}
	for i, z in ipairs(Config.Zones) do
		if z.world == world then
			table.insert(list, i)
		end
	end
	return list
end

-- 구역 z 시작: 세계마다 z = 0에서 시작
function Config.zoneStart(index: number): number
	local world = Config.Zones[index].world
	local z = 0
	for i = 1, index - 1 do
		if Config.Zones[i].world == world then
			z += Config.Zones[i].length
		end
	end
	return z
end

function Config.zoneCenter(index: number): Vector3
	local zone = Config.Zones[index]
	return Vector3.new(Config.Worlds[zone.world].x, 0, Config.zoneStart(index) + zone.length / 2)
end

-- 위치가 어느 세계인지
function Config.worldAt(x: number): number
	local best, bestD = 1, math.huge
	for i, w in ipairs(Config.Worlds) do
		local d = math.abs(x - w.x)
		if d < bestD then
			best, bestD = i, d
		end
	end
	return best
end

-- 위치가 어느 구역인지
function Config.zoneAt(pos: Vector3): number
	local list = Config.zonesOf(Config.worldAt(pos.X))
	local acc = 0
	for _, zi in ipairs(list) do
		acc += Config.Zones[zi].length
		if pos.Z < acc then
			return zi
		end
	end
	return list[#list]
end

-- 지금 크기로 그 세계에서 갈 수 있는 가장 먼 구역
function Config.maxZone(world: number, radius: number): number
	local list = Config.zonesOf(world)
	local best = list[1]
	for _, zi in ipairs(list) do
		if radius >= Config.Zones[zi].need then
			best = zi
		end
	end
	return best
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd" }

function Config.formatNumber(n: number): string
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

function Config.formatSize(r: number): string
	if r >= 100 then
		return tostring(math.floor(r))
	end
	return string.format("%.1f", r)
end

function Config.formatTime(sec: number): string
	local s = math.max(0, math.floor(sec))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

return Config
