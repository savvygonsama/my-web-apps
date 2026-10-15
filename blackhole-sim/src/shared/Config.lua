-- Config (ModuleScript, ReplicatedStorage)
-- 블랙홀 시뮬레이터의 모든 수치. 서버와 클라이언트가 같이 읽는다.
-- 밸런스를 바꾸고 싶으면 이 파일만 고치면 된다.

local Config = {}

Config.GAME_TITLE = "BLACK HOLE"
Config.VERSION = "beta-1"

-- 테스트 계정: 스튜디오에서 플레이하거나 게임 주인이 들어오면 켜진다. 기록은 저장하지 않는다
-- 정식 공개 전에 false로 바꾸면 주인도 일반 계정으로 들어간다
Config.TEST_MODE = true

------------------------------------------------------------------------
-- 업그레이드 3종
--   size  크기: 반지름 = 1.5 × 1.1^레벨. 내 반지름보다 작은 물체만 삼킨다
--   pull  흡입력: 반지름 바깥으로 이만큼 더 멀리서 끌어당긴다
--   mult  질량 배율: 삼킬 때 얻는 질량
------------------------------------------------------------------------
Config.Upgrades = {
	{ id = "size", name = "크기", icon = "⚫", desc = "더 큰 것을 삼킨다", maxLevel = 57, base = 12, growth = 1.3 },
	{ id = "pull", name = "흡입력", icon = "🌀", desc = "더 멀리서 끌어당긴다", maxLevel = 15, base = 30, growth = 1.75 },
	{ id = "mult", name = "질량 배율", icon = "💠", desc = "삼킬 때 얻는 질량 +20%", maxLevel = 40, base = 50, growth = 1.55 },
}
Config.UPGRADE_BY_ID = {}
for _, u in ipairs(Config.Upgrades) do
	Config.UPGRADE_BY_ID[u.id] = u
end

function Config.upgradeCost(id: string, level: number): number
	local u = Config.UPGRADE_BY_ID[id]
	return math.floor(u.base * u.growth ^ level)
end

function Config.radius(sizeLv: number): number
	return 1.5 * 1.1 ^ sizeLv
end

-- 반지름 바깥으로 더 끌어당기는 거리
function Config.pullRange(radius: number, pullLv: number): number
	return radius * (0.12 + 0.06 * pullLv) + 1.5
end

-- 빅뱅 횟수마다 질량 +100%, 배율 업그레이드마다 +20%
function Config.massMult(multLv: number, bigbang: number): number
	return (1 + 0.2 * multLv) * (1 + bigbang)
end

-- 크기가 커지면 빨라진다
function Config.walkSpeed(radius: number): number
	return math.min(140, 16 + radius * 0.35)
end

------------------------------------------------------------------------
-- 빅뱅: 크기 145(레벨 48) 이상이면 처음부터 다시 시작하는 대신 질량 배율이 영구히 오른다
------------------------------------------------------------------------
Config.BIGBANG_LEVEL = 48
Config.BIGBANG_SKINS = {
	{ name = "보랏빛 블랙홀", a = Color3.fromRGB(170, 90, 255), b = Color3.fromRGB(255, 120, 200) },
	{ name = "푸른 퀘이사", a = Color3.fromRGB(70, 170, 255), b = Color3.fromRGB(150, 255, 255) },
	{ name = "붉은 거성", a = Color3.fromRGB(255, 80, 60), b = Color3.fromRGB(255, 200, 90) },
	{ name = "황금 특이점", a = Color3.fromRGB(255, 200, 60), b = Color3.fromRGB(255, 255, 200) },
	{ name = "초록 성운", a = Color3.fromRGB(80, 255, 140), b = Color3.fromRGB(200, 255, 120) },
	{ name = "무지개 우주", a = Color3.fromRGB(255, 90, 90), b = Color3.fromRGB(90, 160, 255), rainbow = true },
}

function Config.skin(bigbang: number)
	return Config.BIGBANG_SKINS[math.clamp(bigbang + 1, 1, #Config.BIGBANG_SKINS)]
end

------------------------------------------------------------------------
-- 구역 6개: 앞 구역 끝의 벽은 내 크기가 need 이상이면 지나갈 수 있다
-- length = 앞뒤 길이, width = 좌우 폭 (스터드)
------------------------------------------------------------------------
Config.Zones = {
	{ id = 1, name = "공원", need = 0, width = 260, length = 260, ground = Color3.fromRGB(110, 170, 80), material = Enum.Material.Grass, respawn = 10 },
	{ id = 2, name = "마을", need = 6, width = 380, length = 340, ground = Color3.fromRGB(140, 150, 110), material = Enum.Material.Grass, respawn = 14 },
	{ id = 3, name = "도시", need = 14, width = 600, length = 520, ground = Color3.fromRGB(95, 95, 105), material = Enum.Material.Asphalt, respawn = 18 },
	{ id = 4, name = "대도시", need = 30, width = 960, length = 820, ground = Color3.fromRGB(70, 72, 82), material = Enum.Material.Concrete, respawn = 22 },
	{ id = 5, name = "바다와 산", need = 65, width = 1500, length = 1300, ground = Color3.fromRGB(60, 130, 190), material = Enum.Material.Sand, respawn = 28 },
	{ id = 6, name = "우주", need = 140, width = 2600, length = 2200, ground = Color3.fromRGB(20, 18, 40), material = Enum.Material.Slate, respawn = 35 },
}

------------------------------------------------------------------------
-- 물체 28종. size = 삼키는 데 필요한 반지름, mass = 얻는 질량, count = 구역에 놓이는 개수
------------------------------------------------------------------------
Config.Objects = {
	-- 1 공원
	{ id = "pebble", name = "돌멩이", zone = 1, size = 0.8, mass = 1, count = 18 },
	{ id = "flower", name = "꽃", zone = 1, size = 0.9, mass = 1, count = 16 },
	{ id = "ball", name = "축구공", zone = 1, size = 1.2, mass = 2, count = 10 },
	{ id = "trashcan", name = "쓰레기통", zone = 1, size = 1.8, mass = 4, count = 8 },
	{ id = "bench", name = "벤치", zone = 1, size = 2.6, mass = 7, count = 8 },
	{ id = "bush", name = "덤불", zone = 1, size = 2.8, mass = 8, count = 8 },
	{ id = "tree", name = "작은 나무", zone = 1, size = 3.0, mass = 10, count = 10 },
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
}
Config.OBJECT_BY_ID = {}
for _, o in ipairs(Config.Objects) do
	Config.OBJECT_BY_ID[o.id] = o
end

------------------------------------------------------------------------
-- 함수
------------------------------------------------------------------------
-- 구역 z 범위: 1구역은 z = 0에서 시작해 +z 쪽으로 이어진다
function Config.zoneStart(index: number): number
	local z = 0
	for i = 1, index - 1 do
		z += Config.Zones[i].length
	end
	return z
end

function Config.zoneCenter(index: number): Vector3
	local zone = Config.Zones[index]
	return Vector3.new(0, 0, Config.zoneStart(index) + zone.length / 2)
end

function Config.zoneAt(z: number): number
	local acc = 0
	for i, zone in ipairs(Config.Zones) do
		acc += zone.length
		if z < acc then
			return i
		end
	end
	return #Config.Zones
end

-- 지금 크기로 갈 수 있는 가장 먼 구역
function Config.maxZone(radius: number): number
	local best = 1
	for i, zone in ipairs(Config.Zones) do
		if radius >= zone.need then
			best = i
		end
	end
	return best
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

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

-- 크기 표시 (소수 한 자리)
function Config.formatSize(r: number): string
	if r >= 100 then
		return tostring(math.floor(r))
	end
	return string.format("%.1f", r)
end

return Config
