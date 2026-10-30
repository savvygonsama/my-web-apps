-- 권왕: 배틀그라운드 (3.3판). 따로 게시한 장소에서 늘 PvP. 맵 넷을 5분마다 바꿔 가며 싸운다
-- 메인 월드의 기록은 읽기만 한다 (권법·숙련). 배틀의 기록 (쓰러뜨린 수·은자 몫)은 따로 저장하고, 메인 월드가 돌아올 때 받아 간다
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Battle = {}
local B = Config.BATTLE

------------------------------------------------------------------------
-- 장소 찾기 (같은 체험 안)
------------------------------------------------------------------------
local placeCache: { battle: number?, main: number? } = {}
local function findPlaces()
	if placeCache.battle and placeCache.main then
		return
	end
	local ok, pages = pcall(function()
		return AssetService:GetGamePlacesAsync()
	end)
	if not ok or not pages then
		return
	end
	while true do
		for _, item in ipairs(pages:GetCurrentPage()) do
			local name = tostring(item.Name or "")
			if string.find(name, B.placeName, 1, true) or string.find(string.lower(name), "battle", 1, true) then
				placeCache.battle = placeCache.battle or item.PlaceId
			else
				placeCache.main = placeCache.main or item.PlaceId
			end
		end
		if pages.IsFinished then
			break
		end
		local okNext = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not okNext then
			break
		end
	end
end

-- toBattle = true: 메인 → 배틀그라운드, false: 배틀그라운드 → 메인. 실패하면 까닭을 돌려준다
function Battle.teleport(player: Player, toBattle: boolean): (boolean, string?)
	if RunService:IsStudio() then
		return false, "Studio에서는 장소를 옮길 수 없어요 (게시한 게임에서 돼요)"
	end
	local target: number? = nil
	if toBattle then
		target = (B.placeId ~= 0 and B.placeId) or nil
		if not target then
			findPlaces()
			target = placeCache.battle
		end
	else
		local jd = player:GetJoinData()
		local td = jd and jd.TeleportData
		target = type(td) == "table" and tonumber(td.from) or nil
		if not target then
			findPlaces()
			target = placeCache.main
		end
	end
	if not target then
		return false, toBattle and ("'" .. B.placeName .. "' 장소를 찾지 못했어요 (체험에 그 이름의 장소가 있어야 해요)") or "메인 월드를 찾지 못했어요"
	end
	local opts = Instance.new("TeleportOptions")
	opts:SetTeleportData({ from = game.PlaceId })
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(target :: number, { player }, opts)
	end)
	if not ok then
		return false, "이동하지 못했어요: " .. tostring(err)
	end
	return true, nil
end

------------------------------------------------------------------------
-- 배틀 기록 (따로 저장)
------------------------------------------------------------------------
local store: DataStore? = nil
do
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore(B.store)
	end)
	if ok then
		store = ds
	end
end
type Rec = { kills: number, deaths: number, wins: number, best: number, pending: number }
local function blank(): Rec
	return { kills = 0, deaths = 0, wins = 0, best = 0, pending = 0 }
end
local function clean(d: any): Rec
	local r = blank()
	if type(d) == "table" then
		for k in pairs(r) do
			local v = tonumber(d[k])
			if v and v == v then
				(r :: any)[k] = math.max(0, math.floor(v))
			end
		end
	end
	return r
end

-- 메인 월드: 들어올 때 배틀 기록을 읽고, 쌓인 은자 몫을 받아 간다 (받은 몫은 0으로). { kills, coins }
function Battle.claim(player: Player): (number, number)
	local ds = store
	if not ds then
		return 0, 0
	end
	local kills, coins = 0, 0
	pcall(function()
		ds:UpdateAsync("b_" .. player.UserId, function(old)
			local r = clean(old)
			kills = r.kills
			coins = r.pending
			r.pending = 0
			return r
		end)
	end)
	return kills, coins
end

------------------------------------------------------------------------
-- 맵 짓기
------------------------------------------------------------------------
local maps: { any } = {}
local function part(props: { [string]: any }): BasePart
	local p = Instance.new(props.Class or "Part") :: BasePart
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k == "Position" then
			p.CFrame = CFrame.new(v)
		elseif k ~= "Class" and k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end
-- 바닥 원판 (원기둥을 눕힌다)
local function disc(name: string, at: Vector3, r: number, h: number, color: Color3, mat: Enum.Material, parent: Instance, collide: boolean?): BasePart
	return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, r * 2, r * 2), CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = mat, CanCollide = collide ~= false, Parent = parent })
end
-- 보이지 않는 둘레 벽
local function fence(center: Vector3, r: number, h: number, parent: Instance)
	local n = 28
	for i = 1, n do
		local a = (i - 0.5) / n * math.pi * 2
		local w = 2 * r * math.tan(math.pi / n) + 2
		part({ Name = "Fence", Size = Vector3.new(w, h, 4), CFrame = CFrame.new(center + Vector3.new(math.cos(a) * (r + 2), h / 2, math.sin(a) * (r + 2))) * CFrame.Angles(0, -a + math.pi / 2, 0), Transparency = 1, CanCollide = true, CastShadow = false, Parent = parent })
	end
end
local function ring(n: number, r: number, phase: number?): { Vector3 }
	local out = {}
	for i = 1, n do
		local a = (i - 1) / n * math.pi * 2 + (phase or 0)
		table.insert(out, Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
	end
	return out
end
local function rnd(seed: number): () -> number
	local r = Random.new(seed)
	return function()
		return r:NextNumber()
	end
end

local BUILD: { [string]: (Vector3, Folder) -> { spawns: { Vector3 }, floorY: number, R: number } } = {}

-- 죽림 비무장: 풀밭 가운데 돌 마당, 둘레에 대나무 덤불 (몸을 숨긴다), 마당 안의 낮은 돌담
BUILD.bamboo = function(c: Vector3, f: Folder)
	local R = 105
	local G = rnd(11)
	disc("Ground", c + Vector3.new(0, -2, 0), R + 20, 4, Color3.fromRGB(86, 120, 62), Enum.Material.Grass, f)
	disc("Court", c + Vector3.new(0, 0.25, 0), 48, 0.6, Color3.fromRGB(150, 146, 136), Enum.Material.Slate, f)
	disc("CourtRing", c + Vector3.new(0, 0.6, 0), 49.5, 0.3, Color3.fromRGB(120, 92, 60), Enum.Material.Wood, f, false)
	disc("CourtMark", c + Vector3.new(0, 0.62, 0), 9, 0.2, Color3.fromRGB(170, 50, 40), Enum.Material.Fabric, f, false)
	-- 마당 안의 돌담 (엄폐)
	for i, v in ipairs(ring(4, 28, math.pi / 4)) do
		local a = (i - 1) / 4 * math.pi * 2 + math.pi / 4
		part({ Name = "LowWall", Size = Vector3.new(14, 4.2, 2.2), CFrame = CFrame.new(c + v + Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, -a + math.pi / 2, 0), Color = Color3.fromRGB(128, 124, 116), Material = Enum.Material.Cobblestone, Parent = f })
		part({ Name = "WallCap", Size = Vector3.new(15, 0.6, 2.8), CFrame = CFrame.new(c + v + Vector3.new(0, 4.8, 0)) * CFrame.Angles(0, -a + math.pi / 2, 0), Color = Color3.fromRGB(70, 60, 50), Material = Enum.Material.Slate, Parent = f })
	end
	-- 석등
	for _, v in ipairs(ring(6, 46, 0.3)) do
		part({ Name = "LanternBase", Size = Vector3.new(1.6, 4, 1.6), Position = c + v + Vector3.new(0, 2.4, 0), Color = Color3.fromRGB(140, 136, 128), Material = Enum.Material.Granite, Parent = f })
		local lamp = part({ Name = "Lantern", Size = Vector3.new(2.4, 1.6, 2.4), Position = c + v + Vector3.new(0, 5.2, 0), Color = Color3.fromRGB(255, 210, 140), Material = Enum.Material.Neon, Transparency = 0.2, Parent = f })
		local l = Instance.new("PointLight")
		l.Range = 16
		l.Brightness = 1.2
		l.Color = Color3.fromRGB(255, 200, 130)
		l.Parent = lamp
		part({ Name = "LanternRoof", Size = Vector3.new(3.2, 0.6, 3.2), Position = c + v + Vector3.new(0, 6.3, 0), Color = Color3.fromRGB(60, 54, 48), Material = Enum.Material.Slate, Parent = f })
	end
	-- 대나무 덤불
	local function stalk(at: Vector3, h: number)
		local col = Color3.fromRGB(90 + math.floor(G() * 30), 140 + math.floor(G() * 30), 60)
		part({ Name = "Bamboo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 0.9, 0.9), CFrame = CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90 + (G() - 0.5) * 6)), Color = col, Material = Enum.Material.SmoothPlastic, Parent = f })
		for k = 1, math.floor(h / 5) do
			part({ Name = "Node", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, 1.05, 1.05), CFrame = CFrame.new(at + Vector3.new(0, k * 5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = col:Lerp(Color3.new(0, 0, 0), 0.25), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
		end
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), Position = at + Vector3.new((G() - 0.5) * 2, h + 1, (G() - 0.5) * 2), Color = Color3.fromRGB(70, 130, 60), Material = Enum.Material.Grass, CanCollide = false, Transparency = 0.15, Parent = f })
	end
	for _, base in ipairs(ring(9, 68, 0.15)) do
		for _ = 1, 6 + math.floor(G() * 4) do
			stalk(c + base + Vector3.new((G() - 0.5) * 12, 0, (G() - 0.5) * 12), 20 + G() * 14)
		end
	end
	-- 둘레: 빽빽한 대숲
	for _, v in ipairs(ring(40, R + 6)) do
		for _ = 1, 3 do
			stalk(c + v + Vector3.new((G() - 0.5) * 8, 0, (G() - 0.5) * 8), 26 + G() * 16)
		end
	end
	fence(c, R, 60, f)
	local sp = {}
	for _, v in ipairs(ring(8, 82, 0.4)) do
		table.insert(sp, c + v + Vector3.new(0, 4, 0))
	end
	return { spawns = sp, floorY = c.Y, R = R }
end

-- 빙호 설원: 가운데 얼어붙은 호수 (탁 트였다), 얼음 기둥, 가장자리의 눈 언덕과 소나무
BUILD.frost = function(c: Vector3, f: Folder)
	local R = 108
	local G = rnd(23)
	disc("Snow", c + Vector3.new(0, -2, 0), R + 20, 4, Color3.fromRGB(236, 240, 248), Enum.Material.Snow, f)
	disc("Lake", c + Vector3.new(0, 0.2, 0), 58, 0.5, Color3.fromRGB(170, 215, 240), Enum.Material.Ice, f)
	disc("LakeEdge", c + Vector3.new(0, 0.1, 0), 60.5, 0.4, Color3.fromRGB(210, 230, 245), Enum.Material.Glacier, f, false)
	-- 얼음 기둥
	for i, v in ipairs(ring(7, 36, 0.5)) do
		local h = 14 + G() * 12
		part({ Name = "IcePillar", Size = Vector3.new(5 + G() * 3, h, 5 + G() * 3), CFrame = CFrame.new(c + v + Vector3.new(0, h / 2, 0)) * CFrame.Angles((G() - 0.5) * 0.25, G() * 3, (G() - 0.5) * 0.25), Color = Color3.fromRGB(150, 215, 255), Material = Enum.Material.Glass, Transparency = 0.25, Parent = f })
		if i % 2 == 0 then
			part({ Name = "IceShard", Size = Vector3.new(2.5, h * 0.55, 2.5), CFrame = CFrame.new(c + v * 1.12 + Vector3.new(0, h * 0.27, 0)) * CFrame.Angles(0.3, G() * 3, 0.2), Color = Color3.fromRGB(190, 235, 255), Material = Enum.Material.Glass, Transparency = 0.3, Parent = f })
		end
	end
	-- 눈 언덕 (반쯤 묻힌 공)
	for _, v in ipairs(ring(10, 80, 0.2)) do
		local s = 14 + G() * 10
		part({ Name = "Drift", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s, s), Position = c + v + Vector3.new(0, -s * 0.28, 0), Color = Color3.fromRGB(240, 244, 252), Material = Enum.Material.Snow, Parent = f })
	end
	-- 소나무 (둘레)
	local function pine(at: Vector3, h: number)
		part({ Name = "Trunk", Size = Vector3.new(1.6, h * 0.4, 1.6), Position = at + Vector3.new(0, h * 0.2, 0), Color = Color3.fromRGB(90, 65, 45), Material = Enum.Material.Wood, Parent = f })
		for k = 0, 2 do
			local r = (3 - k) * 2.4
			part({ Name = "Needles", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h * 0.22, r * 2, r * 2), CFrame = CFrame.new(at + Vector3.new(0, h * (0.35 + k * 0.2), 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 80, 60):Lerp(Color3.new(1, 1, 1), 0.08 * k), Material = Enum.Material.Grass, CanCollide = k == 0, Parent = f })
			part({ Name = "SnowCap", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, r * 1.6, r * 1.6), CFrame = CFrame.new(at + Vector3.new(0, h * (0.35 + k * 0.2) + h * 0.11, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(245, 248, 255), Material = Enum.Material.Snow, CanCollide = false, Parent = f })
		end
	end
	for _, v in ipairs(ring(26, R + 4)) do
		pine(c + v + Vector3.new((G() - 0.5) * 6, 0, (G() - 0.5) * 6), 24 + G() * 12)
	end
	fence(c, R, 60, f)
	local sp = {}
	for _, v in ipairs(ring(8, 70, 0.6)) do
		table.insert(sp, c + v + Vector3.new(0, 4, 0))
	end
	return { spawns = sp, floorY = c.Y, R = R }
end

-- 화산 분지: 검은 현무암 바닥, 용암 줄기 (보기만), 가운데 높은 단과 네 비탈, 바위 기둥, 둘레의 분화구 벽
BUILD.crater = function(c: Vector3, f: Folder)
	local R = 104
	local G = rnd(37)
	disc("Basalt", c + Vector3.new(0, -2, 0), R + 20, 4, Color3.fromRGB(48, 40, 38), Enum.Material.Basalt, f)
	-- 용암 줄기 (바닥에 얕게, 밟아도 괜찮다)
	for i = 1, 6 do
		local a = (i - 1) / 6 * math.pi * 2 + 0.3
		local lava = part({ Name = "Lava", Size = Vector3.new(4 + G() * 3, 0.3, 46), CFrame = CFrame.new(c + Vector3.new(math.cos(a) * 62, 0.05, math.sin(a) * 62)) * CFrame.Angles(0, -a, 0), Color = Color3.fromRGB(255, 110, 30), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		local l = Instance.new("PointLight")
		l.Range = 22
		l.Brightness = 2
		l.Color = Color3.fromRGB(255, 120, 40)
		l.Parent = lava
	end
	-- 가운데 단 (높이 9)과 네 비탈
	disc("Plateau", c + Vector3.new(0, 4.5, 0), 26, 9, Color3.fromRGB(70, 58, 52), Enum.Material.Basalt, f)
	disc("PlateauTop", c + Vector3.new(0, 9.1, 0), 24, 0.4, Color3.fromRGB(95, 72, 60), Enum.Material.Slate, f)
	for i = 1, 4 do
		local a = (i - 1) / 4 * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		part({ Class = "WedgePart", Name = "Ramp", Size = Vector3.new(12, 9, 22), CFrame = CFrame.lookAt(c + dir * 35 + Vector3.new(0, 4.5, 0), c + dir * 60 + Vector3.new(0, 4.5, 0)), Color = Color3.fromRGB(78, 64, 56), Material = Enum.Material.Basalt, Parent = f })
	end
	-- 바위 기둥 (엄폐)
	for _, v in ipairs(ring(6, 56, 0.55)) do
		local h = 12 + G() * 10
		part({ Name = "Rock", Size = Vector3.new(7 + G() * 4, h, 7 + G() * 4), CFrame = CFrame.new(c + v + Vector3.new(0, h / 2 - 1, 0)) * CFrame.Angles((G() - 0.5) * 0.3, G() * 3, (G() - 0.5) * 0.3), Color = Color3.fromRGB(60, 50, 46), Material = Enum.Material.Basalt, Parent = f })
	end
	-- 분화구 벽
	for _, v in ipairs(ring(30, R + 8)) do
		local h = 24 + G() * 18
		part({ Name = "CraterWall", Size = Vector3.new(26, h, 14), CFrame = CFrame.lookAt(c + v + Vector3.new(0, h / 2 - 2, 0), c + Vector3.new(0, h / 2 - 2, 0)) * CFrame.Angles(math.rad(-14), 0, 0), Color = Color3.fromRGB(55, 44, 40), Material = Enum.Material.Basalt, Parent = f })
	end
	fence(c, R, 70, f)
	local sp = {}
	for _, v in ipairs(ring(8, 80, 0.2)) do
		table.insert(sp, c + v + Vector3.new(0, 4, 0))
	end
	return { spawns = sp, floorY = c.Y, R = R }
end

-- 운상 누각: 구름 위의 누각 셋과 가운데 높은 단, 다리로 잇는다 (떨어지면 쓰러진다)
BUILD.cloud = function(c: Vector3, f: Folder)
	local G = rnd(41)
	local WOOD = Color3.fromRGB(150, 95, 60)
	local DECK = Color3.fromRGB(196, 160, 112)
	local ROOF = Color3.fromRGB(60, 80, 110)
	local outer = ring(3, 62, -math.pi / 2)
	local function deck(at: Vector3, r: number, roof: boolean)
		disc("Deck", at + Vector3.new(0, -1, 0), r, 2, DECK, Enum.Material.WoodPlanks, f)
		disc("DeckRim", at + Vector3.new(0, -1.2, 0), r + 1, 2.2, WOOD, Enum.Material.Wood, f)
		-- 난간 (드문드문, 몸을 막지는 않는다)
		for _, v in ipairs(ring(12, r - 0.5)) do
			part({ Name = "RailPost", Size = Vector3.new(0.8, 3, 0.8), Position = at + v + Vector3.new(0, 1.5, 0), Color = Color3.fromRGB(170, 40, 35), Material = Enum.Material.Wood, Parent = f })
		end
		if roof then
			for _, v in ipairs(ring(4, r * 0.55, math.pi / 4)) do
				part({ Name = "Pillar", Size = Vector3.new(1.6, 14, 1.6), Position = at + v + Vector3.new(0, 7, 0), Color = Color3.fromRGB(175, 45, 38), Material = Enum.Material.Wood, Parent = f })
			end
			part({ Name = "Roof", Size = Vector3.new(r * 1.3, 1.4, r * 1.3), CFrame = CFrame.new(at + Vector3.new(0, 14.6, 0)) * CFrame.Angles(0, math.pi / 4, 0), Color = ROOF, Material = Enum.Material.Slate, Parent = f })
			part({ Name = "RoofTop", Size = Vector3.new(r * 0.8, 1.6, r * 0.8), CFrame = CFrame.new(at + Vector3.new(0, 16, 0)) * CFrame.Angles(0, math.pi / 4, 0), Color = ROOF:Lerp(Color3.new(0, 0, 0), 0.2), Material = Enum.Material.Slate, Parent = f })
		end
	end
	for _, v in ipairs(outer) do
		deck(c + v, 28, true)
	end
	-- 가운데 단 (조금 높다) + 계단
	deck(c + Vector3.new(0, 5, 0), 18, false)
	-- 다리: 바깥 누각 → 가운데 (오르막), 바깥끼리
	local function bridge(a: Vector3, b: Vector3, w: number)
		local mid = (a + b) / 2
		local len = (b - a).Magnitude
		part({ Name = "Bridge", Size = Vector3.new(w, 1.2, len), CFrame = CFrame.lookAt(mid, b) , Color = DECK:Lerp(WOOD, 0.3), Material = Enum.Material.WoodPlanks, Parent = f })
		for _, side in ipairs({ -1, 1 }) do
			part({ Name = "BridgeRope", Size = Vector3.new(0.3, 0.3, len), CFrame = CFrame.lookAt(mid, b) * CFrame.new(side * (w / 2), 2.6, 0), Color = Color3.fromRGB(200, 50, 40), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
		end
	end
	for _, v in ipairs(outer) do
		local dir = v.Unit
		bridge(c + dir * 34 + Vector3.new(0, -0.4, 0), c + dir * 17 + Vector3.new(0, 4.4, 0), 7)
	end
	for i = 1, 3 do
		local a, b = outer[i], outer[i % 3 + 1]
		local dir = (b - a).Unit
		bridge(c + a + dir * 27 + Vector3.new(0, -0.4, 0), c + b - dir * 27 + Vector3.new(0, -0.4, 0), 6)
	end
	-- 아래의 구름 (밟을 수 없다)
	for _ = 1, 40 do
		local s = 20 + G() * 30
		part({ Name = "Cloud", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s, s), Position = c + Vector3.new((G() - 0.5) * 260, -30 - G() * 30, (G() - 0.5) * 260), Color = Color3.fromRGB(250, 250, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.25, CanCollide = false, CastShadow = false, Parent = f })
	end
	local sp = {}
	for _, v in ipairs(outer) do
		for _, o in ipairs(ring(3, 12, 0.5)) do
			table.insert(sp, c + v + o + Vector3.new(0, 4, 0))
		end
	end
	return { spawns = sp, floorY = c.Y, R = 110, fall = true }
end

function Battle.build(): any
	local f = Instance.new("Folder")
	f.Name = "BattleMaps"
	f.Parent = workspace
	for i, m in ipairs(B.maps) do
		local c = Vector3.new(20000 + (i - 1) * 1500, 0, 20000)
		local mf = Instance.new("Folder")
		mf.Name = m.id
		mf.Parent = f
		local fn = BUILD[m.id]
		local ok, info = pcall(fn, c, mf)
		if not ok then
			warn("[권왕] 배틀 맵 오류", m.id, info)
			info = { spawns = { c + Vector3.new(0, 6, 0) }, floorY = c.Y, R = 100 }
			part({ Name = "Floor", Size = Vector3.new(200, 2, 200), Position = c + Vector3.new(0, -1, 0), Color = Color3.fromRGB(120, 120, 120), Parent = mf })
		end
		table.insert(maps, { id = m.id, name = m.name, desc = m.desc, center = c, info = info, folder = mf })
	end
	-- 처음 태어나는 자리 (첫 맵)
	local sl = Instance.new("SpawnLocation")
	sl.Name = "BattleSpawn"
	sl.Anchored = true
	sl.Size = Vector3.new(8, 1, 8)
	sl.Transparency = 1
	sl.CanCollide = false
	sl.Neutral = true
	sl.Duration = 0
	sl.CFrame = CFrame.new(maps[1].info.spawns[1] - Vector3.new(0, 3, 0))
	sl.Parent = f
	Battle.spawnLoc = sl
	return { train = {}, rings = {} }
end

------------------------------------------------------------------------
-- 한 판의 흐름: 맵마다 mapTime초. 판이 끝나면 가장 많이 쓰러뜨린 사람이 이긴다
------------------------------------------------------------------------
local cur = 1
local roundEnd = 0
type Sess = { k: number, d: number, streak: number, rec: Rec, dirty: boolean, loaded: boolean }
local sess: { [Player]: Sess } = {}
local ctx: any = nil

function Battle.current(): any
	return maps[cur]
end

-- 다른 사람에게서 가장 먼 자리
function Battle.spawnCF(player: Player?): CFrame
	local m = maps[cur]
	local best, bestD = m.info.spawns[1], -1
	for _, sp in ipairs(m.info.spawns) do
		local near = math.huge
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				local ch = other.Character
				local r = ch and ch:FindFirstChild("HumanoidRootPart")
				if r and r:IsA("BasePart") then
					near = math.min(near, (r.Position - sp).Magnitude)
				end
			end
		end
		near += math.random() * 6
		if near > bestD then
			best, bestD = sp, near
		end
	end
	return CFrame.lookAt(best, Vector3.new(m.center.X, best.Y, m.center.Z))
end

local function shield(f: any)
	f.battleShield = os.clock() + B.shield
	f.model:SetAttribute("BattleShield", true)
	task.delay(B.shield, function()
		if f.model and f.model.Parent and (f.battleShield or 0) <= os.clock() + 0.05 then
			f.model:SetAttribute("BattleShield", nil)
		end
	end)
end
Battle.shield = shield

local function loadRec(player: Player, s: Sess)
	local ds = store
	if not ds then
		s.loaded = true
		return
	end
	for attempt = 1, 3 do
		local ok, data = pcall(function()
			return ds:GetAsync("b_" .. player.UserId)
		end)
		if ok then
			s.rec = clean(data)
			s.loaded = true
			return
		end
		task.wait(attempt)
	end
end

-- 저장: 쌓인 것만 더한다 (다른 서버에서 같은 사람이 동시에 있을 일은 없지만, 메인 월드가 은자 몫을 받아 갔을 수 있다)
local function saveRec(player: Player)
	local s = sess[player]
	local ds = store
	if not s or not ds or not s.loaded or not s.dirty then
		return
	end
	local sa = s :: any
	local add = sa.add or blank()
	sa.add = blank()
	s.dirty = false
	local ok = pcall(function()
		ds:UpdateAsync("b_" .. player.UserId, function(old)
			local r = clean(old)
			r.kills += add.kills
			r.deaths += add.deaths
			r.wins += add.wins
			r.pending += add.pending
			r.best = math.max(r.best, add.best)
			return r
		end)
	end)
	if not ok then
		-- 못 썼으면 다음에 다시 (쌓인 몫을 되돌려 놓는다)
		local back = (s :: any).add
		for k, v in pairs(add) do
			if k == "best" then
				back.best = math.max(back.best, v)
			else
				back[k] += v
			end
		end
		s.dirty = true
	end
end
local function bump(player: Player, field: string, n: number)
	local s = sess[player]
	if not s then
		return
	end
	local sa = s :: any
	local add = sa.add or blank()
	sa.add = add
	if field == "best" then
		add.best = math.max(add.best, n)
		s.rec.best = math.max(s.rec.best, n)
	else
		local aa, rr = add :: any, s.rec :: any
		aa[field] += n
		rr[field] += n
	end
	s.dirty = true
end

function Battle.join(player: Player)
	local s: Sess = { k = 0, d = 0, streak = 0, rec = blank(), dirty = false, loaded = false }
	sess[player] = s
	task.spawn(loadRec, player, s)
end
function Battle.leave(player: Player)
	saveRec(player)
	sess[player] = nil
end
function Battle.saveAll()
	for player in pairs(sess) do
		task.spawn(saveRec, player)
	end
end

local function coinsFor(player: Player, base: number): number
	local idx = ctx and ctx.realmOf and ctx.realmOf(player) or 1
	return math.floor(base * (1 + 0.5 * (idx - 1)))
end

-- 누가 쓰러졌다 (killer는 없을 수도: 떨어짐)
function Battle.onDeath(victim: Player, killer: Player?)
	local vs = sess[victim]
	if vs then
		vs.d += 1
		vs.streak = 0
		bump(victim, "deaths", 1)
	end
	local streak = 0
	if killer and killer ~= victim then
		local ks = sess[killer]
		if ks then
			ks.k += 1
			ks.streak += 1
			streak = ks.streak
			bump(killer, "kills", 1)
			bump(killer, "best", ks.streak)
			bump(killer, "pending", coinsFor(killer, B.coinsPerKill))
		end
	end
	if ctx then
		ctx.push:FireAllClients("battleKill", { killer = killer and killer.DisplayName or nil, victim = victim.DisplayName, streak = streak })
	end
	task.delay(B.respawn, function()
		if victim.Parent and ctx then
			ctx.respawn(victim)
		end
	end)
end

local function standings(): { any }
	local list = {}
	for player, s in pairs(sess) do
		table.insert(list, { id = player.UserId, name = player.DisplayName, k = s.k, d = s.d, streak = s.streak, total = s.rec.kills })
	end
	table.sort(list, function(a, b)
		if a.k ~= b.k then
			return a.k > b.k
		end
		return a.d < b.d
	end)
	return list
end

local function moveAllTo(idx: number)
	cur = idx
	if Battle.spawnLoc then
		Battle.spawnLoc.CFrame = CFrame.new(maps[cur].info.spawns[1] - Vector3.new(0, 3, 0))
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if ctx then
			ctx.respawn(player)
		end
	end
end

function Battle.start(c: any)
	ctx = c
	roundEnd = os.clock() + B.mapTime
	task.spawn(function()
		local warned = false
		local saveAt = os.clock() + 60
		while true do
			task.wait(1)
			local t = os.clock()
			local left = math.max(0, roundEnd - t)
			if left <= B.warnAt and not warned then
				warned = true
				local nxt = maps[cur % #maps + 1]
				ctx.push:FireAllClients("battleNote", { text = string.format("⏳ %d초 뒤 다음 맵: %s", B.warnAt, nxt.name) })
			end
			if left <= 0 then
				-- 판 끝: 가장 많이 쓰러뜨린 사람이 이긴다 (한 명도 못 쓰러뜨렸으면 없음)
				local st = standings()
				local top = st[1]
				local winnerName = nil
				if top and top.k > 0 then
					for player in pairs(sess) do
						if player.UserId == top.id then
							bump(player, "wins", 1)
							bump(player, "pending", coinsFor(player, B.coinsPerWin))
							winnerName = player.DisplayName
						end
					end
				end
				ctx.push:FireAllClients("battleRound", { winner = winnerName, kills = top and top.k or 0, map = maps[cur].name, next = maps[cur % #maps + 1].name })
				for _, s in pairs(sess) do
					s.k, s.d, s.streak = 0, 0, 0
				end
				moveAllTo(cur % #maps + 1)
				roundEnd = os.clock() + B.mapTime
				warned = false
			end
			-- 떨어지면 쓰러진다 (마지막에 때린 사람의 몫)
			local m = maps[cur]
			for _, player in ipairs(Players:GetPlayers()) do
				local f = ctx.fighter(player)
				if f and not f.dead and f.root.Position.Y < m.info.floorY + B.fallY then
					ctx.kill(f)
				end
			end
			-- 모두에게 판 상태
			local st = standings()
			ctx.push:FireAllClients("battle", { map = m.name, desc = m.desc, left = math.floor(left), list = st })
			if t >= saveAt then
				saveAt = t + 60
				Battle.saveAll()
			end
		end
	end)
end

function Battle.myRec(player: Player): any
	local s = sess[player]
	return s and s.rec or nil
end

return Battle
