-- Config (ModuleScript, ReplicatedStorage)
-- 블랙홀 시뮬레이터의 모든 수치. 서버와 클라이언트가 같이 읽는다.
-- 밸런스를 바꾸고 싶으면 이 파일만 고치면 된다.

local Config = {}

Config.GAME_TITLE = "BLACK HOLE"
Config.VERSION = "beta-4"

-- 테스트 계정: 스튜디오에서 플레이하거나 게임 주인이 들어오면 켜진다. 기록은 저장하지 않는다
-- 정식 공개 전에 false로 바꾸면 주인도 일반 계정으로 들어간다
Config.TEST_MODE = true

-- 로블록스 파트 한 개의 최대 크기. 이보다 큰 바닥과 벽은 여러 조각으로 나눠 깐다
Config.PART_LIMIT = 2000

------------------------------------------------------------------------
-- 크기: 먹어서 커진다
-- 물체를 삼키면 블랙홀 넓이(반지름²)에 GROW_K × 물체 크기² × 성장 배율만큼 더해진다.
-- 내 크기에 가까운 걸 삼킬수록 확 커진다.
------------------------------------------------------------------------
Config.START_RADIUS = 1.5
Config.GROW_K = 0.3
-- 클수록 덜 자란다: 실제 계수 = GROW_K / (1 + 반지름 / GROW_SOFT). 뒤로 갈수록 오래 놀아야 커진다
Config.GROW_SOFT = 20

-- 최대 크기: 기본 1000, 빅뱅마다 +300 (10번까지), '크기 한계' 업그레이드 레벨마다 +10%
function Config.maxRadius(bigbang: number, maxLv: number): number
	return (1000 + 300 * math.min(bigbang, 10)) * (1 + 0.1 * maxLv)
end

-- 성장 배율. info = { grow, bigbang, star, skin(스킨 능력 성장 보너스) }
function Config.growMult(info: any): number
	local m = (1 + 0.05 * (info.grow or 0)) * (1 + 0.1 * (info.bigbang or 0)) * (1 + (info.skin or 0))
	if info.star then
		m *= 2
	end
	return m
end

-- 크기 size인 물체를 삼킨 뒤 반지름
function Config.grow(radius: number, size: number, mult: number, maxR: number): number
	local k = Config.GROW_K / (1 + radius / Config.GROW_SOFT)
	return math.max(radius, math.min(maxR, math.sqrt(radius * radius + k * mult * size * size)))
end

-- 빅뱅 상점 '시작 크기' 레벨에 따른 시작 반지름
function Config.startRadius(startLv: number): number
	return Config.START_RADIUS * 1.25 ^ startLv
end

------------------------------------------------------------------------
-- 업그레이드 9종 (질량으로 산다, 빅뱅하면 사라진다)
-- show(level)은 카드에 보여 줄 효과 글
------------------------------------------------------------------------
Config.Upgrades = {
	{ id = "grow", name = "성장력", icon = "⚫", desc = "먹을 때 커지는 정도", maxLevel = 60, base = 25, growth = 1.8, show = function(l: number): string
		return string.format("성장 ×%.2f", 1 + 0.05 * l)
	end },
	{ id = "mult", name = "질량 배율", icon = "💠", desc = "삼킬 때 얻는 질량", maxLevel = 60, base = 40, growth = 1.74, show = function(l: number): string
		return string.format("질량 ×%.2f", 1 + 0.25 * l)
	end },
	{ id = "pull", name = "흡입력", icon = "🌀", desc = "반지름 바깥까지 끌어당김", maxLevel = 30, base = 30, growth = 1.86, show = function(l: number): string
		return string.format("흡입 +%d%%", 15 + 7 * l)
	end },
	{ id = "speed", name = "이동 속도", icon = "👟", desc = "더 빨리 돌아다님", maxLevel = 20, base = 60, growth = 2.0, show = function(l: number): string
		return string.format("속도 +%d%%", 5 * l)
	end },
	{ id = "maxsize", name = "크기 한계", icon = "📏", desc = "최대 크기가 늘어남", maxLevel = 20, base = 5000, growth = 2.2, show = function(l: number): string
		return string.format("한계 +%d%%", 10 * l)
	end },
	{ id = "respawn", name = "빠른 재생", icon = "♻", desc = "먹은 물체가 더 빨리 다시 생김", maxLevel = 15, base = 100, growth = 2.0, show = function(l: number): string
		return string.format("재생 -%d%%", 4 * l)
	end },
	{ id = "star", name = "별똥별 자석", icon = "☄", desc = "별똥별이 더 자주 떨어짐", maxLevel = 15, base = 200, growth = 2.0, show = function(l: number): string
		return string.format("별똥별 +%d%%", 6 * l)
	end },
	{ id = "combo", name = "콤보 증폭", icon = "🔥", desc = "연속 흡수 보너스가 커짐", maxLevel = 10, base = 300, growth = 2.3, show = function(l: number): string
		return string.format("콤보 보너스 ×%.2f", 1 + 0.25 * l)
	end },
	{ id = "golden", name = "황금 탐지", icon = "✨", desc = "황금 물체가 더 자주 나옴", maxLevel = 10, base = 500, growth = 2.3, show = function(l: number): string
		return string.format("황금 확률 +%d%%", 25 * l)
	end },
}
Config.UPGRADE_BY_ID = {}
for _, u in ipairs(Config.Upgrades) do
	Config.UPGRADE_BY_ID[u.id] = u
end

function Config.upgradeCost(id: string, level: number): number
	local u = Config.UPGRADE_BY_ID[id]
	return math.floor(u.base * u.growth ^ level)
end

------------------------------------------------------------------------
-- 빅뱅(환생): 크기 600 이상이면 처음부터 다시 시작하고 암흑 물질을 받는다
------------------------------------------------------------------------
Config.BIGBANG_RADIUS = 600

-- 받는 암흑 물질: 크기 600에서 3개, 그 위로 크기 100마다 1개씩 더
function Config.darkMatterReward(radius: number, bigbang: number, dmLv: number?): number
	local base = 3 + math.max(0, math.floor((radius - Config.BIGBANG_RADIUS) / 100)) + bigbang // 2
	return math.floor(base * (1 + 0.2 * (dmLv or 0)))
end

-- 빅뱅 상점: 암흑 물질로 사는 영구 업그레이드 (빅뱅해도 남는다)
Config.BigbangShop = {
	{ id = "start", name = "시작 크기", icon = "🌱", desc = "빅뱅 뒤 25% 더 크게 시작", maxLevel = 8, base = 2, step = 2 },
	{ id = "respawn", name = "빠른 재생산", icon = "♻", desc = "삼킨 물체가 12% 더 빨리 다시 생긴다", maxLevel = 5, base = 3, step = 3 },
	{ id = "mass", name = "암흑 증폭", icon = "🌑", desc = "질량 +50%", maxLevel = 20, base = 3, step = 2 },
	{ id = "speed", name = "광속", icon = "⚡", desc = "이동 속도 +15%", maxLevel = 5, base = 2, step = 2 },
	{ id = "pull", name = "사건의 지평선", icon = "🕳", desc = "흡입 범위 +15%", maxLevel = 5, base = 3, step = 3 },
	{ id = "luck", name = "행운의 별", icon = "🍀", desc = "캡슐에서 전설 이상이 나올 확률 +15%", maxLevel = 5, base = 4, step = 3 },
	{ id = "slots", name = "위성 궤도", icon = "🛰", desc = "위성 장착 칸 +1", maxLevel = 2, base = 10, step = 15 },
	{ id = "keep", name = "질량 보존", icon = "🏦", desc = "빅뱅할 때 질량 5%를 남긴다", maxLevel = 5, base = 4, step = 4 },
	{ id = "dm", name = "암흑 수확", icon = "🌘", desc = "빅뱅 때 암흑 물질 +20%", maxLevel = 5, base = 5, step = 5 },
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
-- 로비: 세계와 따로 떨어진 광장. 들어오면 여기서 시작한다
-- 캡슐 기계(위성 뽑기), 스킨 전시관, 상점, 매일 보상, 순위판, 세계로 가는 문이 있다
------------------------------------------------------------------------
Config.LOBBY = { x = -30000, z = 0, radius = 230 }

function Config.inLobby(pos: Vector3): boolean
	local dx, dz = pos.X - Config.LOBBY.x, pos.Z - Config.LOBBY.z
	return dx * dx + dz * dz < (Config.LOBBY.radius + 60) ^ 2
end

-- 매일 보상: 마지막으로 받은 뒤 20시간이 지나면 다시 받는다
Config.DAILY_HOURS = 20

------------------------------------------------------------------------
-- 세계 2개, 구역 15개
-- 세계는 x 위치로 멀리 떨어져 있어서 서로 보이지 않고, 구역은 z = 0에서 +z 쪽으로 이어진다
-- need = 그 구역에 들어가는 데 필요한 크기 (문이 이 크기에서 열린다)
-- countMult = 물체 개수 배수 (넓은 구역일수록 물체를 많이 둔다)
------------------------------------------------------------------------
Config.Worlds = {
	{ id = 1, name = "지구와 우주", x = 0, needBigbang = 0, sky = Color3.fromRGB(150, 190, 255) },
	{ id = 2, name = "과자 왕국", x = 30000, needBigbang = 1, sky = Color3.fromRGB(255, 190, 230) },
}

Config.Zones = {
	-- 세계 1
	{ world = 1, name = "공원", need = 0, width = 420, length = 420, ground = Color3.fromRGB(110, 170, 80), material = Enum.Material.Grass, respawn = 3, countMult = 2 },
	{ world = 1, name = "마을", need = 6, width = 640, length = 560, ground = Color3.fromRGB(140, 150, 110), material = Enum.Material.Grass, respawn = 3, countMult = 2 },
	{ world = 1, name = "도시", need = 14, width = 1000, length = 860, ground = Color3.fromRGB(95, 95, 105), material = Enum.Material.Asphalt, respawn = 4, countMult = 2 },
	{ world = 1, name = "대도시", need = 30, width = 1600, length = 1360, ground = Color3.fromRGB(70, 72, 82), material = Enum.Material.Concrete, respawn = 4, countMult = 2 },
	{ world = 1, name = "바다와 산", need = 65, width = 2600, length = 2200, ground = Color3.fromRGB(60, 130, 190), material = Enum.Material.Sand, respawn = 5, countMult = 2 },
	{ world = 1, name = "우주", need = 140, width = 4200, length = 3600, ground = Color3.fromRGB(20, 18, 40), material = Enum.Material.Slate, respawn = 6, countMult = 1.5 },
	{ world = 1, name = "은하수", need = 350, width = 7000, length = 6000, ground = Color3.fromRGB(12, 8, 30), material = Enum.Material.Slate, respawn = 8, countMult = 1 },
	-- 세계 2 (훨씬 넓다)
	{ world = 2, name = "젤리 들판", need = 0, width = 520, length = 520, ground = Color3.fromRGB(255, 190, 220), material = Enum.Material.SmoothPlastic, respawn = 3, countMult = 2.5 },
	{ world = 2, name = "과자 마을", need = 6, width = 820, length = 720, ground = Color3.fromRGB(240, 210, 160), material = Enum.Material.Sand, respawn = 3, countMult = 2.5 },
	{ world = 2, name = "케이크 도시", need = 14, width = 1300, length = 1100, ground = Color3.fromRGB(255, 240, 230), material = Enum.Material.SmoothPlastic, respawn = 4, countMult = 2.5 },
	{ world = 2, name = "아이스크림 산맥", need = 30, width = 2200, length = 1800, ground = Color3.fromRGB(200, 240, 255), material = Enum.Material.Snow, respawn = 5, countMult = 2 },
	{ world = 2, name = "초콜릿 강", need = 65, width = 3200, length = 2800, ground = Color3.fromRGB(120, 70, 45), material = Enum.Material.SmoothPlastic, respawn = 5, countMult = 2 },
	{ world = 2, name = "사탕 우주", need = 140, width = 5000, length = 4400, ground = Color3.fromRGB(70, 30, 90), material = Enum.Material.SmoothPlastic, respawn = 6, countMult = 1.5 },
	{ world = 2, name = "디저트 은하", need = 350, width = 7600, length = 6600, ground = Color3.fromRGB(50, 20, 70), material = Enum.Material.SmoothPlastic, respawn = 8, countMult = 1.2 },
	{ world = 2, name = "설탕 블랙홀", need = 800, width = 10000, length = 9000, ground = Color3.fromRGB(30, 10, 40), material = Enum.Material.SmoothPlastic, respawn = 10, countMult = 1 },
}

------------------------------------------------------------------------
-- 물체 108종. zone = 위 Zones 순서, size = 삼키는 데 필요한 반지름, mass = 얻는 질량, count = 놓이는 개수
-- model = 다른 물체의 모양을 크게 키워 쓸 때 (없으면 id 모양)
-- 세계 2의 질량은 같은 크기 세계 1 물체의 약 5배
------------------------------------------------------------------------
Config.Objects = {
	-- 1 공원
	{ id = "pebble", name = "돌멩이", zone = 1, size = 0.8, mass = 2, count = 18 },
	{ id = "flower", name = "꽃", zone = 1, size = 0.9, mass = 2, count = 16 },
	{ id = "duck", name = "오리", zone = 1, size = 1.1, mass = 3, count = 10 },
	{ id = "ball", name = "축구공", zone = 1, size = 1.2, mass = 4, count = 10 },
	{ id = "hydrant", name = "소화전", zone = 1, size = 1.5, mass = 6, count = 8 },
	{ id = "trashcan", name = "쓰레기통", zone = 1, size = 1.8, mass = 8, count = 8 },
	{ id = "picnic", name = "피크닉 테이블", zone = 1, size = 2.4, mass = 12, count = 6 },
	{ id = "bench", name = "벤치", zone = 1, size = 2.6, mass = 14, count = 8 },
	{ id = "bush", name = "덤불", zone = 1, size = 2.8, mass = 16, count = 8 },
	{ id = "tree", name = "작은 나무", zone = 1, size = 3.0, mass = 20, count = 10 },
	-- 2 마을
	{ id = "mailbox", name = "우체통", zone = 2, size = 3.5, mass = 15, count = 10 },
	{ id = "doghouse", name = "개집", zone = 2, size = 3.8, mass = 18, count = 8 },
	{ id = "bicycle", name = "자전거", zone = 2, size = 4, mass = 20, count = 10 },
	{ id = "lamp", name = "가로등", zone = 2, size = 4.6, mass = 28, count = 10 },
	{ id = "vending", name = "자판기", zone = 2, size = 5, mass = 36, count = 8 },
	{ id = "car", name = "자동차", zone = 2, size = 6, mass = 50, count = 12 },
	{ id = "bigtree", name = "큰 나무", zone = 2, size = 7, mass = 70, count = 10 },
	{ id = "tent", name = "텐트", zone = 2, size = 8, mass = 95, count = 6 },
	{ id = "hut", name = "오두막", zone = 2, size = 9, mass = 120, count = 8 },
	-- 3 도시
	{ id = "truck", name = "트럭", zone = 3, size = 11, mass = 250, count = 10 },
	{ id = "taxi", name = "택시", zone = 3, size = 12, mass = 320, count = 10 },
	{ id = "bus", name = "버스", zone = 3, size = 13, mass = 380, count = 10 },
	{ id = "house", name = "집", zone = 3, size = 15, mass = 550, count = 10 },
	{ id = "firetruck", name = "소방차", zone = 3, size = 16, mass = 650, count = 8 },
	{ id = "shop", name = "가게", zone = 3, size = 18, mass = 800, count = 8 },
	{ id = "gasstation", name = "주유소", zone = 3, size = 19, mass = 950, count = 6 },
	{ id = "fountain", name = "분수대", zone = 3, size = 20, mass = 1100, count = 6 },
	-- 4 대도시
	{ id = "building", name = "빌딩", zone = 4, size = 26, mass = 3000, count = 12 },
	{ id = "helicopter", name = "헬리콥터", zone = 4, size = 28, mass = 4000, count = 8 },
	{ id = "tower", name = "타워", zone = 4, size = 32, mass = 5500, count = 10 },
	{ id = "crane", name = "타워 크레인", zone = 4, size = 35, mass = 7000, count = 6 },
	{ id = "stadium", name = "경기장", zone = 4, size = 38, mass = 9000, count = 6 },
	{ id = "ferris", name = "대관람차", zone = 4, size = 42, mass = 14000, count = 6 },
	{ id = "airplane", name = "비행기", zone = 4, size = 45, mass = 17000, count = 5 },
	-- 5 바다와 산
	{ id = "ship", name = "배", zone = 5, size = 55, mass = 40000, count = 10 },
	{ id = "lighthouse", name = "등대", zone = 5, size = 60, mass = 60000, count = 8 },
	{ id = "whale", name = "고래", zone = 5, size = 68, mass = 90000, count = 6 },
	{ id = "island", name = "섬", zone = 5, size = 75, mass = 120000, count = 6 },
	{ id = "mountain", name = "산", zone = 5, size = 90, mass = 250000, count = 6 },
	{ id = "volcano", name = "화산", zone = 5, size = 105, mass = 400000, count = 4 },
	-- 6 우주
	{ id = "satellite", name = "인공위성", zone = 6, size = 115, mass = 800000, count = 8 },
	{ id = "comet", name = "혜성", zone = 6, size = 130, mass = 1100000, count = 6 },
	{ id = "asteroid", name = "소행성", zone = 6, size = 140, mass = 1500000, count = 8 },
	{ id = "spacestation", name = "우주 정거장", zone = 6, size = 160, mass = 2500000, count = 5 },
	{ id = "moon", name = "달", zone = 6, size = 180, mass = 4000000, count = 5 },
	{ id = "planet", name = "행성", zone = 6, size = 240, mass = 12000000, count = 4 },
	{ id = "sun", name = "태양", zone = 6, size = 320, mass = 50000000, count = 2 },
	{ id = "galaxy", name = "은하", zone = 6, size = 400, mass = 120000000, count = 1 },
	-- 7 은하수
	{ id = "nebula", model = "galaxy", name = "성운", zone = 7, size = 380, mass = 90000000, count = 14 },
	{ id = "giantplanet", model = "planet", name = "거대 가스 행성", zone = 7, size = 450, mass = 165000000, count = 10 },
	{ id = "fortress", model = "spacestation", name = "우주 요새", zone = 7, size = 520, mass = 270000000, count = 8 },
	{ id = "redgiant", model = "sun", name = "붉은 거성", zone = 7, size = 600, mass = 450000000, count = 6 },
	{ id = "spiral", model = "galaxy", name = "나선 은하", zone = 7, size = 850, mass = 1500000000, count = 3 },
	-- 8 젤리 들판
	{ id = "gummy", name = "젤리곰", zone = 8, size = 0.8, mass = 10, count = 18 },
	{ id = "candy", name = "사탕", zone = 8, size = 0.9, mass = 10, count = 16 },
	{ id = "chocobar", name = "초콜릿 바", zone = 8, size = 1.1, mass = 15, count = 10 },
	{ id = "lollipop", name = "막대사탕", zone = 8, size = 1.3, mass = 20, count = 12 },
	{ id = "marshmallow", name = "마시멜로", zone = 8, size = 1.5, mass = 30, count = 8 },
	{ id = "macaron", name = "마카롱", zone = 8, size = 1.8, mass = 40, count = 10 },
	{ id = "cupcake", name = "컵케이크", zone = 8, size = 2.6, mass = 70, count = 10 },
	{ id = "donut", name = "도넛", zone = 8, size = 3.0, mass = 100, count = 10 },
	-- 9 과자 마을
	{ id = "cookie", name = "쿠키", zone = 9, size = 3.5, mass = 75, count = 12 },
	{ id = "milk", name = "우유 팩", zone = 9, size = 4, mass = 100, count = 10 },
	{ id = "pudding", name = "푸딩", zone = 9, size = 4.5, mass = 120, count = 10 },
	{ id = "waffle", name = "와플", zone = 9, size = 5, mass = 180, count = 8 },
	{ id = "icecream", name = "아이스크림콘", zone = 9, size = 6, mass = 250, count = 12 },
	{ id = "cottontree", name = "솜사탕 나무", zone = 9, size = 7, mass = 350, count = 10 },
	{ id = "gingerhouse", name = "과자 집", zone = 9, size = 9, mass = 600, count = 8 },
	-- 10 케이크 도시
	{ id = "candycar", name = "사탕 자동차", zone = 10, size = 12, mass = 1500, count = 10 },
	{ id = "jellybus", name = "젤리 버스", zone = 10, size = 13, mass = 2000, count = 8 },
	{ id = "cake", name = "케이크", zone = 10, size = 15, mass = 2750, count = 10 },
	{ id = "chocofountain", name = "초콜릿 분수", zone = 10, size = 18, mass = 4000, count = 8 },
	{ id = "chocotower", name = "초콜릿 빌딩", zone = 10, size = 20, mass = 5000, count = 6 },
	{ id = "weddingcake", name = "웨딩 케이크 탑", zone = 10, size = 22, mass = 6000, count = 6 },
	-- 11 아이스크림 산맥
	{ id = "lollitower", name = "롤리팝 탑", zone = 11, size = 28, mass = 18000, count = 10 },
	{ id = "parfait", name = "파르페", zone = 11, size = 31, mass = 24000, count = 8 },
	{ id = "jellycastle", name = "젤리 성", zone = 11, size = 34, mass = 30000, count = 8 },
	{ id = "cottoncloud", name = "솜사탕 구름", zone = 11, size = 40, mass = 45000, count = 6 },
	{ id = "icemountain", name = "아이스크림 산", zone = 11, size = 45, mass = 60000, count = 6 },
	-- 12 초콜릿 강
	{ id = "giantwaffle", model = "waffle", name = "거대 와플", zone = 12, size = 60, mass = 600000, count = 10 },
	{ id = "donutplanet", name = "도넛 행성", zone = 12, size = 80, mass = 1200000, count = 8 },
	{ id = "chocofalls", model = "chocofountain", name = "초콜릿 폭포", zone = 12, size = 90, mass = 1800000, count = 6 },
	{ id = "candyasteroid", name = "사탕 소행성", zone = 12, size = 100, mass = 3000000, count = 8 },
	{ id = "cakeisland", model = "cake", name = "케이크 섬", zone = 12, size = 115, mass = 3600000, count = 6 },
	{ id = "jellyvolcano", model = "volcano", name = "젤리 화산", zone = 12, size = 130, mass = 5000000, count = 4 },
	-- 13 사탕 우주
	{ id = "candymoon", name = "사탕 달", zone = 13, size = 160, mass = 22000000, count = 8 },
	{ id = "chocoplanet", name = "초콜릿 행성", zone = 13, size = 200, mass = 48000000, count = 6 },
	{ id = "cakestar", name = "케이크 별", zone = 13, size = 260, mass = 120000000, count = 5 },
	{ id = "candysun", name = "사탕 태양", zone = 13, size = 340, mass = 300000000, count = 3 },
	-- 14 디저트 은하
	{ id = "macaronplanet", model = "macaron", name = "마카롱 행성", zone = 14, size = 380, mass = 450000000, count = 12 },
	{ id = "rollgalaxy", model = "galaxy", name = "롤케이크 은하", zone = 14, size = 450, mass = 800000000, count = 10 },
	{ id = "puddingstar", model = "pudding", name = "푸딩 별", zone = 14, size = 520, mass = 1400000000, count = 8 },
	{ id = "cupcakeplanet", model = "cupcake", name = "컵케이크 행성", zone = 14, size = 600, mass = 2250000000, count = 6 },
	-- 15 설탕 블랙홀
	{ id = "cakecastle", model = "jellycastle", name = "우주 젤리 성", zone = 15, size = 760, mass = 5200000000, count = 12 },
	{ id = "chocoquasar", model = "candysun", name = "초코 퀘이사", zone = 15, size = 800, mass = 6000000000, count = 10 },
	{ id = "candygalaxy", model = "galaxy", name = "사탕 은하", zone = 15, size = 850, mass = 7600000000, count = 8 },
	{ id = "sugarstar", model = "cakestar", name = "설탕 별", zone = 15, size = 900, mass = 9300000000, count = 6 },
}
Config.OBJECT_BY_ID = {}
for _, o in ipairs(Config.Objects) do
	Config.OBJECT_BY_ID[o.id] = o
end

-- 황금 물체: 가끔 금빛으로 나타난다. 질량 10배, 성장 1.5배
Config.GOLDEN_CHANCE = 0.02
Config.GOLDEN_MASS = 10
Config.GOLDEN_GROW = 1.5

-- 연속 흡수(콤보): 1.5초 안에 계속 삼키면 한 번마다 질량 +1% (최대 +100%, 콤보 증폭으로 더 커짐)
Config.COMBO_WINDOW = 1.5

------------------------------------------------------------------------
-- 퀘스트: 늘 3개가 걸려 있고, 끝내면 바로 보상을 받고 새 퀘스트가 나온다
------------------------------------------------------------------------
Config.Quests = {
	{ kind = "eat", text = "물체 %s개 삼키기", base = 80, grow = 1.25, reward = "mass" },
	{ kind = "golden", text = "황금 물체 %s개 삼키기", base = 3, grow = 1.2, reward = "dm" },
	{ kind = "star", text = "별똥별 %s개 잡기", base = 2, grow = 1.2, reward = "dm" },
	{ kind = "big", text = "내 크기 절반 넘는 것 %s개 삼키기", base = 15, grow = 1.25, reward = "mass" },
	{ kind = "combo", text = "연속 흡수 %s 만들기", base = 20, grow = 1.2, reward = "mass" },
}
Config.QUEST_BY_KIND = {}
for _, q in ipairs(Config.Quests) do
	Config.QUEST_BY_KIND[q.kind] = q
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
-- ability: 스킨마다 고유 능력
--   passive = 늘 켜져 있음: pull(흡입 범위), grow(성장), mass(질량), golden(황금 확률 배수), star(별똥별), respawn(재생), sats(위성 배율), world2(세계 2 보너스)
--   active  = 스킬 버튼(Q)으로 쓴다: speed(빨라짐), pull(흡입 범위 커짐), burst(주변 한꺼번에 흡수). cd = 다시 쓰기까지 초
Config.Skins = {
	{ id = "violet", name = "보랏빛 블랙홀", a = Color3.fromRGB(170, 90, 255), b = Color3.fromRGB(255, 120, 200), unlock = "bigbang", value = 0,
		ability = { kind = "passive", name = "끌어당김", desc = "흡입 범위 +15%", pull = 0.15 } },
	{ id = "quasar", name = "푸른 퀘이사", a = Color3.fromRGB(70, 170, 255), b = Color3.fromRGB(150, 255, 255), unlock = "bigbang", value = 1,
		ability = { kind = "active", name = "퀘이사 제트", desc = "8초 동안 이동 속도 ×2", speed = 2, dur = 8, cd = 25 } },
	{ id = "giant", name = "붉은 거성", a = Color3.fromRGB(255, 80, 60), b = Color3.fromRGB(255, 200, 90), unlock = "bigbang", value = 2,
		ability = { kind = "passive", name = "거성의 식욕", desc = "성장 +25%", grow = 0.25 } },
	{ id = "nebula", name = "초록 성운", a = Color3.fromRGB(80, 255, 140), b = Color3.fromRGB(200, 255, 120), unlock = "bigbang", value = 3,
		ability = { kind = "passive", name = "성운의 축복", desc = "질량 +40%, 성장 +10%", mass = 0.4, grow = 0.1 } },
	{ id = "golden", name = "황금 특이점", a = Color3.fromRGB(255, 200, 60), b = Color3.fromRGB(255, 255, 200), unlock = "bigbang", value = 5, effect = "gold",
		ability = { kind = "passive", name = "황금 손", desc = "황금 물체 3배 자주, 질량 +30%", golden = 3, mass = 0.3 } },
	{ id = "rainbow", name = "무지개 우주", a = Color3.fromRGB(255, 90, 90), b = Color3.fromRGB(90, 160, 255), unlock = "bigbang", value = 8, effect = "rainbow",
		ability = { kind = "active", name = "무지개 폭발", desc = "흡입 범위 3배 안을 한꺼번에 흡수", burst = 3, dur = 0, cd = 30 } },
	{ id = "ice", name = "얼음 소용돌이", a = Color3.fromRGB(150, 230, 255), b = Color3.fromRGB(255, 255, 255), unlock = "dm", value = 6, effect = "ice",
		ability = { kind = "active", name = "얼음 질주", desc = "6초 동안 이동 속도 ×2.5", speed = 2.5, dur = 6, cd = 18 } },
	{ id = "lava", name = "용암 소용돌이", a = Color3.fromRGB(255, 110, 30), b = Color3.fromRGB(255, 230, 80), unlock = "dm", value = 12, effect = "fire",
		ability = { kind = "active", name = "용암 분출", desc = "8초 동안 흡입 범위 ×2.5", pull = 2.5, dur = 8, cd = 25 } },
	{ id = "milkyway", name = "은하수", a = Color3.fromRGB(120, 140, 255), b = Color3.fromRGB(255, 240, 255), unlock = "dm", value = 25, effect = "galaxy",
		ability = { kind = "passive", name = "별을 부르는 자", desc = "별똥별 2배 자주, 효과 시간 +50%", star = 2 } },
	{ id = "sweet", name = "사탕 소용돌이", a = Color3.fromRGB(255, 120, 190), b = Color3.fromRGB(140, 230, 255), unlock = "world2", value = 0, effect = "candy",
		ability = { kind = "passive", name = "단맛 중독", desc = "세계 2에서 질량 +100%, 성장 +30%", world2 = true } },
	{ id = "vip", name = "황금 VIP", a = Color3.fromRGB(255, 215, 80), b = Color3.fromRGB(255, 150, 40), unlock = "pass", value = "vip", effect = "gold",
		ability = { kind = "passive", name = "VIP 특권", desc = "질량 +50%, 재생 25% 빨라짐", mass = 0.5, respawn = 0.75 } },
	{ id = "godeye", name = "신의 눈", a = Color3.fromRGB(255, 230, 140), b = Color3.fromRGB(255, 90, 60), unlock = "pass", value = "petpack", effect = "eye",
		ability = { kind = "active", name = "신의 시선", desc = "흡입 범위 5배 안을 한꺼번에 흡수 (늘 위성 배율 +20%)", burst = 5, dur = 0, cd = 35, sats = 0.2 } },
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
	{ key = "massS", id = 0, price = 25, icon = "💠", name = "질량 꾸러미 (소)", desc = "지금 갈 수 있는 가장 큰 물체 30개 값만큼 질량" },
	{ key = "massL", id = 0, price = 99, icon = "💎", name = "질량 꾸러미 (대)", desc = "지금 갈 수 있는 가장 큰 물체 120개 값만큼 질량" },
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
-- 별똥별: 가끔 내 근처에 떨어진다. 삼키면 60초 동안 질량과 성장 2배
------------------------------------------------------------------------
Config.STAR_INTERVAL = 35
Config.STAR_LIFETIME = 25
Config.STAR_BOOST = 60

------------------------------------------------------------------------
-- 계산
------------------------------------------------------------------------
-- 반지름 바깥으로 더 끌어당기는 거리. extra = 스킨 능력 배수
function Config.pullRange(radius: number, pullLv: number, bbPull: number?, extra: number?): number
	return (radius * (0.15 + 0.07 * pullLv) + 1.5) * (1 + 0.15 * (bbPull or 0)) * (extra or 1)
end

-- 이동 속도. 크기가 커질수록 빨라지고, 넓은 뒤쪽 구역도 금방 건너간다
function Config.walkSpeed(radius: number, bbSpeed: number?, pass2: boolean?, upgLv: number?, extra: number?): number
	local base = math.min(320, 18 + radius * 0.35) * (1 + 0.15 * (bbSpeed or 0)) * (1 + 0.05 * (upgLv or 0))
	return base * (pass2 and 2 or 1) * (extra or 1)
end

-- 질량 배율 전체. info = { mult, bigbang, bbMass, sats(위성 배율), vip, mass2, boost, star, skin(스킨 질량 보너스), combo(콤보 보너스) }
function Config.totalMult(info: any): number
	local m = (1 + 0.25 * (info.mult or 0)) * (1 + (info.bigbang or 0)) * (1 + 0.5 * (info.bbMass or 0))
	m *= info.sats or 1
	m *= 1 + (info.skin or 0)
	m *= 1 + (info.combo or 0)
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

-- 재생 시간 배율 (작을수록 빠르다)
function Config.respawnFactor(bbRespawn: number, vip: boolean?, boost: boolean?, upgLv: number?, skin: number?): number
	local f = (1 - 0.12 * bbRespawn) * (1 - 0.04 * (upgLv or 0)) * (skin or 1)
	if vip then
		f *= 0.8
	end
	if boost then
		f *= 0.5
	end
	return math.max(0.1, f)
end

-- 콤보 보너스 (질량 배수에 더해진다)
function Config.comboBonus(combo: number, comboLv: number): number
	return math.min(combo, 100) * 0.01 * (1 + 0.25 * comboLv)
end

-- 황금 물체 확률
function Config.goldenChance(goldenLv: number, skinMult: number?): number
	return Config.GOLDEN_CHANCE * (1 + 0.25 * goldenLv) * (skinMult or 1)
end

-- 별똥별 간격 (초)
function Config.starInterval(starLv: number, skinMult: number?): number
	return Config.STAR_INTERVAL / ((1 + 0.06 * starLv) * (skinMult or 1))
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

-- 지금 갈 수 있는 구역에서 가장 질량이 큰 물체 (질량 꾸러미 계산용)
function Config.biggestMass(world: number, radius: number): number
	local reach = Config.maxZone(world, radius)
	local best = 0
	for _, o in ipairs(Config.Objects) do
		if Config.Zones[o.zone].world == world and o.zone <= reach and o.size <= math.max(radius, Config.Zones[o.zone].need) then
			best = math.max(best, o.mass)
		end
	end
	return best
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
