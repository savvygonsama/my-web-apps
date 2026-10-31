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

------------------------------------------------------------------------
-- 3.11판: 맵 넷을 두 배 반지름 (넓이 네 배)으로 새로 짓는다. 고리에 똑같이 늘어놓던 것을 버리고
-- 흩어 놓고 (서로 떨어지게), 땅에 낮은 둔덕을 깔고, 길·물길·쉼터 같은 자리를 둔다
------------------------------------------------------------------------
local K2 = 2 -- 반지름 배율
-- 둘레 r0~r1 안에 서로 gap만큼 떨어진 자리 n개 (avoid: { {at, r} } 피할 곳)
local function scatter(G: () -> number, n: number, r0: number, r1: number, gap: number, avoid: { any }?): { Vector3 }
	local out: { Vector3 } = {}
	local tries = 0
	while #out < n and tries < n * 40 do
		tries += 1
		local a = G() * math.pi * 2
		local r = math.sqrt(r0 * r0 + G() * (r1 * r1 - r0 * r0))
		local v = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local ok = true
		for _, o in ipairs(out) do
			if (o - v).Magnitude < gap then
				ok = false
				break
			end
		end
		if ok and avoid then
			for _, z in ipairs(avoid) do
				if (z[1] - v).Magnitude < z[2] then
					ok = false
					break
				end
			end
		end
		if ok then
			table.insert(out, v)
		end
	end
	return out
end
-- 낮은 둔덕 (큰 공을 땅에 거의 묻는다)
local function mound(at: Vector3, w: number, h: number, color: Color3, mat: Enum.Material, f: Instance)
	part({ Name = "Mound", Shape = Enum.PartType.Ball, Size = Vector3.new(w, w, w), Position = at + Vector3.new(0, h - w / 2, 0), Color = color, Material = mat, Parent = f })
end
-- 바위: 비스듬한 덩이 둘셋을 겹친다
local function rock(G: () -> number, at: Vector3, s: number, color: Color3, mat: Enum.Material, f: Instance, moss: Color3?)
	for k = 1, 2 + math.floor(G() * 2) do
		local sz = Vector3.new(s * (0.6 + G() * 0.6), s * (0.4 + G() * 0.5), s * (0.6 + G() * 0.5))
		local off = Vector3.new((G() - 0.5) * s * 0.7, sz.Y * 0.35, (G() - 0.5) * s * 0.7)
		local cf = CFrame.new(at + off) * CFrame.Angles((G() - 0.5) * 0.5, G() * 6, (G() - 0.5) * 0.5)
		part({ Name = "Rock", Size = sz, CFrame = cf, Color = color:Lerp(Color3.new(0, 0, 0), G() * 0.15), Material = mat, Parent = f })
		if moss and k == 1 then
			part({ Name = "Moss", Size = Vector3.new(sz.X * 0.8, 0.25, sz.Z * 0.8), CFrame = cf * CFrame.new(0, sz.Y / 2 + 0.05, 0), Color = moss, Material = Enum.Material.Grass, CanCollide = false, Parent = f })
		end
	end
end
-- 석등 (빛)
local function stoneLantern(at: Vector3, f: Instance, glow: Color3?)
	part({ Name = "LanternFoot", Size = Vector3.new(2.4, 0.8, 2.4), Position = at + Vector3.new(0, 0.4, 0), Color = Color3.fromRGB(130, 126, 118), Material = Enum.Material.Granite, Parent = f })
	part({ Name = "LanternPost", Size = Vector3.new(1.1, 3.4, 1.1), Position = at + Vector3.new(0, 2.5, 0), Color = Color3.fromRGB(140, 136, 128), Material = Enum.Material.Granite, Parent = f })
	local lamp = part({ Name = "Lantern", Size = Vector3.new(1.9, 1.5, 1.9), Position = at + Vector3.new(0, 4.9, 0), Color = glow or Color3.fromRGB(255, 214, 150), Material = Enum.Material.Neon, Transparency = 0.15, Parent = f })
	local l = Instance.new("PointLight")
	l.Range = 18
	l.Brightness = 1.1
	l.Color = glow or Color3.fromRGB(255, 200, 130)
	l.Parent = lamp
	part({ Name = "LanternRoof", Class = "WedgePart", Size = Vector3.new(3, 0.9, 1.5), CFrame = CFrame.new(at + Vector3.new(0, 6.1, -0.75)), Color = Color3.fromRGB(70, 66, 60), Material = Enum.Material.Slate, Parent = f })
	part({ Name = "LanternRoof", Class = "WedgePart", Size = Vector3.new(3, 0.9, 1.5), CFrame = CFrame.new(at + Vector3.new(0, 6.1, 0.75)) * CFrame.Angles(0, math.pi, 0), Color = Color3.fromRGB(70, 66, 60), Material = Enum.Material.Slate, Parent = f })
end
-- 기와지붕 정자 (기둥 넷, 두 겹 지붕)
local function pavilion(at: Vector3, s: number, f: Instance, yaw: number?)
	local base = CFrame.new(at) * CFrame.Angles(0, yaw or 0, 0)
	part({ Name = "PavBase", Size = Vector3.new(14, 1.2, 14) * Vector3.new(s, 1, s), CFrame = base * CFrame.new(0, 0.6, 0), Color = Color3.fromRGB(150, 144, 132), Material = Enum.Material.Cobblestone, Parent = f })
	part({ Name = "PavDeck", Size = Vector3.new(12.4 * s, 0.4, 12.4 * s), CFrame = base * CFrame.new(0, 1.35, 0), Color = Color3.fromRGB(130, 92, 60), Material = Enum.Material.WoodPlanks, Parent = f })
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			part({ Name = "PavPillar", Size = Vector3.new(1.2, 10, 1.2), CFrame = base * CFrame.new(x * 5.2 * s, 6.5, z * 5.2 * s), Color = Color3.fromRGB(160, 46, 38), Material = Enum.Material.Wood, Parent = f })
		end
	end
	part({ Name = "PavBeam", Size = Vector3.new(12 * s, 1, 12 * s), CFrame = base * CFrame.new(0, 11.6, 0), Color = Color3.fromRGB(60, 90, 70), Material = Enum.Material.Wood, Parent = f })
	part({ Name = "PavRoof", Size = Vector3.new(17 * s, 1.2, 17 * s), CFrame = base * CFrame.new(0, 12.6, 0), Color = Color3.fromRGB(56, 60, 70), Material = Enum.Material.Slate, Parent = f })
	part({ Name = "PavRoof2", Size = Vector3.new(10 * s, 1.6, 10 * s), CFrame = base * CFrame.new(0, 13.8, 0), Color = Color3.fromRGB(46, 50, 60), Material = Enum.Material.Slate, Parent = f })
	part({ Name = "PavRidge", Size = Vector3.new(4 * s, 1.4, 4 * s), CFrame = base * CFrame.new(0, 15, 0), Color = Color3.fromRGB(40, 44, 54), Material = Enum.Material.Slate, Parent = f })
end
-- 물결치는 줄기 (물길·용암): 굽은 길을 따라 조각을 잇는다
local function stream(c: Vector3, from: Vector3, to: Vector3, w: number, wave: number, color: Color3, mat: Enum.Material, f: Instance, glow: boolean?): { Vector3 }
	local pts: { Vector3 } = {}
	local n = 14
	local dir = (to - from)
	local side = Vector3.new(-dir.Z, 0, dir.X).Unit
	for i = 0, n do
		local u = i / n
		table.insert(pts, c + from:Lerp(to, u) + side * math.sin(u * math.pi * 2.2) * wave)
	end
	for i = 1, n do
		local a, b = pts[i], pts[i + 1]
		local seg = part({ Name = "Stream", Size = Vector3.new(w * (0.85 + 0.3 * math.sin(i)), 0.3, (b - a).Magnitude + w * 0.5), CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 0.12, 0), b + Vector3.new(0, 0.12, 0)), Color = color, Material = mat, CanCollide = false, Parent = f })
		if glow and i % 3 == 0 then
			local l = Instance.new("PointLight")
			l.Range = 24
			l.Brightness = 2
			l.Color = color
			l.Parent = seg
		end
	end
	return pts
end

-- 죽림 비무장: 낮은 둔덕이 이어진 풀밭, 가운데 돌 마당, 흩어진 대숲, 개울과 돌다리, 정자 셋, 석등 길
BUILD.bamboo = function(c: Vector3, f: Folder)
	local R = 140 * K2
	local G = rnd(11)
	disc("Ground", c + Vector3.new(0, -2, 0), R + 30, 4, Color3.fromRGB(86, 120, 62), Enum.Material.Grass, f)
	for _, v in ipairs(scatter(G, 26, 90, R - 10, 34)) do
		mound(c + v, 44 + G() * 30, 0.8 + G() * 1.4, Color3.fromRGB(80 + math.floor(G() * 20), 116 + math.floor(G() * 16), 58), Enum.Material.Grass, f)
	end
	-- 가운데 돌 마당 (바깥 테는 박석)
	disc("Court", c + Vector3.new(0, 0.25, 0), 64, 0.6, Color3.fromRGB(150, 146, 136), Enum.Material.Slate, f)
	for k = 0, 35 do
		local a = k / 36 * math.pi * 2
		part({ Name = "Flagstone", Size = Vector3.new(10.5, 0.7, 5), CFrame = CFrame.new(c + Vector3.new(math.cos(a) * 66, 0.3, math.sin(a) * 66)) * CFrame.Angles(0, -a + math.pi / 2, 0), Color = Color3.fromRGB(128 + (k % 3) * 8, 124 + (k % 3) * 8, 114), Material = Enum.Material.Cobblestone, Parent = f })
	end
	disc("CourtMark", c + Vector3.new(0, 0.62, 0), 10, 0.2, Color3.fromRGB(170, 50, 40), Enum.Material.Fabric, f, false)
	-- 마당 안의 엇갈린 돌담 (엄폐)
	for i = 1, 5 do
		local a = (i - 1) / 5 * math.pi * 2 + 0.4
		local v = Vector3.new(math.cos(a), 0, math.sin(a)) * (34 + (i % 2) * 8)
		local cf = CFrame.new(c + v + Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, -a + math.pi / 2 + (G() - 0.5) * 0.5, 0)
		part({ Name = "LowWall", Size = Vector3.new(12 + G() * 6, 4.2, 2.2), CFrame = cf, Color = Color3.fromRGB(128, 124, 116), Material = Enum.Material.Cobblestone, Parent = f })
		part({ Name = "WallCap", Size = Vector3.new(14 + G() * 4, 0.6, 2.8), CFrame = cf * CFrame.new(0, 2.4, 0), Color = Color3.fromRGB(70, 60, 50), Material = Enum.Material.Slate, Parent = f })
	end
	-- 개울: 북서에서 남동으로 굽이쳐 흐르고, 돌다리 둘
	local water = stream(c, Vector3.new(-R, 0, -R * 0.45), Vector3.new(R, 0, R * 0.55), 9, 40, Color3.fromRGB(90, 150, 190), Enum.Material.Glass, f)
	local avoid: { any } = { { Vector3.zero, 85 } }
	for i, p in ipairs(water) do
		table.insert(avoid, { p - c, 16 })
		if i == 4 or i == 12 then
			local nxt = water[i + 1] or p
			local d = (nxt - p).Unit
			part({ Name = "Bridge", Size = Vector3.new(18, 1.2, 6), CFrame = CFrame.lookAt(p + Vector3.new(0, 0.9, 0), p + Vector3.new(0, 0.9, 0) + d) * CFrame.Angles(0, math.pi / 2, 0), Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Cobblestone, Parent = f })
		elseif i % 3 == 0 then
			rock(G, p + Vector3.new(6, 0, 0), 3, Color3.fromRGB(120, 124, 118), Enum.Material.Slate, f, Color3.fromRGB(80, 120, 60))
		end
	end
	-- 정자 셋 (쉼터·높은 자리)
	local pavs = scatter(G, 3, 150, 200, 120, avoid)
	for _, v in ipairs(pavs) do
		pavilion(c + v, 1, f, G() * 6)
		table.insert(avoid, { v, 22 })
		-- 마당에서 정자로 가는 석등 길
		for k = 1, 3 do
			local u = 0.3 + k * 0.17
			local p = v * u + Vector3.new(-v.Z, 0, v.X).Unit * 7
			stoneLantern(c + p, f)
		end
	end
	-- 대나무 (줄기·마디 둘·잎)
	local function stalk(at: Vector3, h: number)
		local col = Color3.fromRGB(90 + math.floor(G() * 30), 140 + math.floor(G() * 30), 60)
		local tilt = CFrame.Angles((G() - 0.5) * 0.08, 0, (G() - 0.5) * 0.08)
		local base = CFrame.new(at) * tilt
		part({ Name = "Bamboo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 0.9, 0.9), CFrame = base * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = col, Material = Enum.Material.SmoothPlastic, Parent = f })
		for _, y in ipairs({ h * 0.35, h * 0.7 }) do
			part({ Name = "Node", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, 1.05, 1.05), CFrame = base * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = col:Lerp(Color3.new(0, 0, 0), 0.25), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
		end
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), CFrame = base * CFrame.new((G() - 0.5) * 2, h + 1, (G() - 0.5) * 2), Color = Color3.fromRGB(64 + math.floor(G() * 20), 124 + math.floor(G() * 20), 56), Material = Enum.Material.Grass, CanCollide = false, Transparency = 0.1, Parent = f })
	end
	-- 대숲: 크기가 다른 덤불이 흩어져 있다 (뒤에 숨어 파고든다)
	for _, v in ipairs(scatter(G, 36, 95, R - 25, 28, avoid)) do
		local n = 6 + math.floor(G() * 8)
		local spread = 5 + n * 0.8
		for _ = 1, n do
			stalk(c + v + Vector3.new((G() - 0.5) * spread, 0, (G() - 0.5) * spread), 18 + G() * 16)
		end
		if G() < 0.4 then
			rock(G, c + v + Vector3.new(spread * 0.6, 0, 0), 3 + G() * 2, Color3.fromRGB(116, 118, 110), Enum.Material.Slate, f, Color3.fromRGB(80, 120, 60))
		end
	end
	-- 둘레: 빽빽한 대숲 두 겹
	for _, v in ipairs(ring(84, R + 6)) do
		stalk(c + v + Vector3.new((G() - 0.5) * 8, 0, (G() - 0.5) * 8), 26 + G() * 16)
		stalk(c + v * 1.04 + Vector3.new((G() - 0.5) * 8, 0, (G() - 0.5) * 8), 30 + G() * 16)
	end
	fence(c, R, 60, f)
	local sp = {}
	for _, v in ipairs(scatter(G, 16, R * 0.55, R * 0.8, 40, avoid)) do
		table.insert(sp, c + v + Vector3.new(0, 6, 0))
	end
	return { spawns = sp, floorY = c.Y, R = R }
end

-- 빙호 설원: 눈 둔덕이 이어진 벌판, 가운데 들쭉날쭉한 얼어붙은 호수, 흩어진 얼음 기둥, 무너진 옛 사당, 소나무 숲
BUILD.frost = function(c: Vector3, f: Folder)
	local R = 145 * K2
	local G = rnd(23)
	disc("Snow", c + Vector3.new(0, -2, 0), R + 30, 4, Color3.fromRGB(236, 240, 248), Enum.Material.Snow, f)
	-- 호수: 크기가 다른 얼음 원판 여럿을 겹쳐 가장자리가 들쭉날쭉하다
	disc("Lake", c + Vector3.new(0, 0.2, 0), 95, 0.5, Color3.fromRGB(170, 215, 240), Enum.Material.Ice, f)
	for k = 1, 7 do
		local a = k / 7 * math.pi * 2 + G()
		local r = 40 + G() * 25
		disc("LakeLobe", c + Vector3.new(math.cos(a) * (95 - r * 0.5), 0.18 + k * 0.004, math.sin(a) * (95 - r * 0.5)), r, 0.5, Color3.fromRGB(165 + math.floor(G() * 15), 212, 240), Enum.Material.Ice, f)
	end
	-- 호수 위의 금 (얕은 선)
	for _ = 1, 10 do
		local a, r = G() * math.pi * 2, G() * 80
		part({ Name = "IceCrack", Size = Vector3.new(0.3, 0.1, 10 + G() * 18), CFrame = CFrame.new(c + Vector3.new(math.cos(a) * r, 0.5, math.sin(a) * r)) * CFrame.Angles(0, G() * 6, 0), Color = Color3.fromRGB(235, 248, 255), Material = Enum.Material.Neon, Transparency = 0.4, CanCollide = false, Parent = f })
	end
	local avoid: { any } = { { Vector3.zero, 120 } }
	-- 눈 둔덕
	for _, v in ipairs(scatter(G, 30, 130, R - 10, 34)) do
		mound(c + v, 40 + G() * 36, 1 + G() * 2.2, Color3.fromRGB(238, 242, 250), Enum.Material.Snow, f)
	end
	-- 얼음 기둥 (호숫가와 벌판에 흩어져)
	for _, v in ipairs(scatter(G, 18, 60, R - 30, 26)) do
		local h = 12 + G() * 16
		part({ Name = "IcePillar", Size = Vector3.new(4 + G() * 4, h, 4 + G() * 4), CFrame = CFrame.new(c + v + Vector3.new(0, h / 2 - 1, 0)) * CFrame.Angles((G() - 0.5) * 0.3, G() * 3, (G() - 0.5) * 0.3), Color = Color3.fromRGB(150, 215, 255), Material = Enum.Material.Glass, Transparency = 0.25, Parent = f })
		if G() < 0.5 then
			part({ Name = "IceShard", Size = Vector3.new(2.2, h * 0.5, 2.2), CFrame = CFrame.new(c + v + Vector3.new(3, h * 0.22, 1)) * CFrame.Angles(0.35, G() * 3, 0.2), Color = Color3.fromRGB(190, 235, 255), Material = Enum.Material.Glass, Transparency = 0.3, Parent = f })
		end
	end
	-- 무너진 옛 사당 (기둥 여덟 중 몇은 부러졌다, 깨진 단)
	local shrine = scatter(G, 1, 180, 210, 1, avoid)[1] or Vector3.new(190, 0, 0)
	table.insert(avoid, { shrine, 30 })
	disc("ShrineBase", c + shrine + Vector3.new(0, 0.8, 0), 20, 1.6, Color3.fromRGB(170, 172, 180), Enum.Material.Slate, f)
	for i, v in ipairs(ring(8, 16, 0.2)) do
		local h = (i % 3 == 0) and (4 + G() * 4) or 14
		part({ Name = "ShrinePillar", Size = Vector3.new(2.4, h, 2.4), CFrame = CFrame.new(c + shrine + v + Vector3.new(0, 1.6 + h / 2, 0)) * CFrame.Angles(0, G(), (i % 3 == 0) and 0.12 or 0), Color = Color3.fromRGB(196, 198, 206), Material = Enum.Material.Marble, Parent = f })
		if h > 10 then
			part({ Name = "PillarSnow", Size = Vector3.new(2.8, 0.5, 2.8), Position = c + shrine + v + Vector3.new(0, 1.6 + h + 0.25, 0), Color = Color3.fromRGB(245, 248, 255), Material = Enum.Material.Snow, CanCollide = false, Parent = f })
		end
	end
	for _ = 1, 4 do
		local v = shrine + Vector3.new((G() - 0.5) * 30, 0, (G() - 0.5) * 30)
		part({ Name = "FallenStone", Size = Vector3.new(2.4, 2.4, 6 + G() * 4), CFrame = CFrame.new(c + v + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, G() * 6, 0.1), Color = Color3.fromRGB(190, 192, 200), Material = Enum.Material.Marble, Parent = f })
	end
	-- 소나무 (숲 덩이와 둘레)
	local function pine(at: Vector3, h: number)
		part({ Name = "Trunk", Size = Vector3.new(1.6, h * 0.4, 1.6), Position = at + Vector3.new(0, h * 0.2, 0), Color = Color3.fromRGB(90, 65, 45), Material = Enum.Material.Wood, Parent = f })
		for k = 0, 2 do
			local r = (3 - k) * 2.4 * (h / 30)
			part({ Name = "Needles", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h * 0.22, r * 2, r * 2), CFrame = CFrame.new(at + Vector3.new(0, h * (0.35 + k * 0.2), 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 80, 60):Lerp(Color3.new(1, 1, 1), 0.08 * k), Material = Enum.Material.Grass, CanCollide = k == 0, Parent = f })
			part({ Name = "SnowCap", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, r * 1.6, r * 1.6), CFrame = CFrame.new(at + Vector3.new(0, h * (0.35 + k * 0.2) + h * 0.11, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(245, 248, 255), Material = Enum.Material.Snow, CanCollide = false, Parent = f })
		end
	end
	for _, v in ipairs(scatter(G, 16, 140, R - 30, 44, avoid)) do
		for _ = 1, 3 + math.floor(G() * 4) do
			pine(c + v + Vector3.new((G() - 0.5) * 22, 0, (G() - 0.5) * 22), 22 + G() * 14)
		end
	end
	for _, v in ipairs(ring(64, R + 4)) do
		pine(c + v + Vector3.new((G() - 0.5) * 8, 0, (G() - 0.5) * 8), 26 + G() * 14)
	end
	fence(c, R, 60, f)
	local sp = {}
	for _, v in ipairs(scatter(G, 16, 130, R * 0.8, 40, avoid)) do
		table.insert(sp, c + v + Vector3.new(0, 8, 0))
	end
	return { spawns = sp, floorY = c.Y, R = R }
end

-- 화산 분지: 현무암 바닥과 낮은 잿빛 둔덕, 굽이치는 용암 줄기 셋, 가운데 높은 단과 비탈, 작은 단 셋, 바위 첨탑, 분화구 벽
BUILD.crater = function(c: Vector3, f: Folder)
	local R = 140 * K2
	local G = rnd(37)
	disc("Basalt", c + Vector3.new(0, -2, 0), R + 30, 4, Color3.fromRGB(48, 40, 38), Enum.Material.Basalt, f)
	for _, v in ipairs(scatter(G, 24, 70, R - 15, 36)) do
		mound(c + v, 40 + G() * 30, 0.8 + G() * 1.8, Color3.fromRGB(58 + math.floor(G() * 14), 48, 44), Enum.Material.Basalt, f)
	end
	-- 용암 줄기 (보기만, 밟아도 괜찮다): 가운데 단에서 바깥으로 굽이친다
	local avoid: { any } = { { Vector3.zero, 70 } }
	for i = 1, 5 do
		local a = (i - 1) / 5 * math.pi * 2 + 0.5
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		for _, p in ipairs(stream(c, d * 50, d * (R - 20), 5 + G() * 3, 24, Color3.fromRGB(255, 110, 30), Enum.Material.Neon, f, true)) do
			table.insert(avoid, { p - c, 12 })
		end
	end
	-- 가운데 단 (높이 9)과 네 비탈
	disc("Plateau", c + Vector3.new(0, 4.5, 0), 40, 9, Color3.fromRGB(70, 58, 52), Enum.Material.Basalt, f)
	disc("PlateauTop", c + Vector3.new(0, 9.1, 0), 38, 0.4, Color3.fromRGB(95, 72, 60), Enum.Material.Slate, f)
	for i = 1, 4 do
		local a = (i - 1) / 4 * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		part({ Class = "WedgePart", Name = "Ramp", Size = Vector3.new(14, 9, 24), CFrame = CFrame.lookAt(c + dir * 51 + Vector3.new(0, 4.5, 0), c + dir * 80 + Vector3.new(0, 4.5, 0)), Color = Color3.fromRGB(78, 64, 56), Material = Enum.Material.Basalt, Parent = f })
	end
	-- 작은 단 셋 (낮다, 한쪽 비탈)
	for _, v in ipairs(scatter(G, 3, 150, 200, 120, avoid)) do
		disc("Mesa", c + v + Vector3.new(0, 3, 0), 18, 6, Color3.fromRGB(66, 54, 50), Enum.Material.Basalt, f)
		local dir = -v.Unit
		part({ Class = "WedgePart", Name = "Ramp", Size = Vector3.new(10, 6, 14), CFrame = CFrame.lookAt(c + v + dir * 24 + Vector3.new(0, 3, 0), c + v + dir * 40 + Vector3.new(0, 3, 0)), Color = Color3.fromRGB(74, 60, 54), Material = Enum.Material.Basalt, Parent = f })
		table.insert(avoid, { v, 30 })
	end
	-- 바위 첨탑과 흑요석 조각 (엄폐)
	for _, v in ipairs(scatter(G, 36, 70, R - 30, 26, avoid)) do
		local h = 12 + G() * 18
		part({ Name = "Spire", Size = Vector3.new(6 + G() * 5, h, 6 + G() * 5), CFrame = CFrame.new(c + v + Vector3.new(0, h / 2 - 1, 0)) * CFrame.Angles((G() - 0.5) * 0.3, G() * 3, (G() - 0.5) * 0.3), Color = Color3.fromRGB(60, 50, 46), Material = Enum.Material.Basalt, Parent = f })
		if G() < 0.5 then
			part({ Name = "Obsidian", Size = Vector3.new(1.6, 4 + G() * 4, 1.6), CFrame = CFrame.new(c + v + Vector3.new(4, 2, 2)) * CFrame.Angles(0.3, G() * 6, 0.3), Color = Color3.fromRGB(30, 22, 34), Material = Enum.Material.Glass, Parent = f })
		end
	end
	-- 흩어진 돌무더기 (낮은 엄폐)
	for _, v in ipairs(scatter(G, 20, 60, R - 20, 30, avoid)) do
		rock(G, c + v, 3 + G() * 3, Color3.fromRGB(72, 60, 54), Enum.Material.Basalt, f)
	end
	-- 분화구 벽
	for _, v in ipairs(ring(72, R + 10)) do
		local h = 26 + G() * 22
		part({ Name = "CraterWall", Size = Vector3.new(28, h, 16), CFrame = CFrame.lookAt(c + v + Vector3.new(0, h / 2 - 2, 0), c + Vector3.new(0, h / 2 - 2, 0)) * CFrame.Angles(math.rad(-14), 0, 0), Color = Color3.fromRGB(55 + math.floor(G() * 10), 44, 40), Material = Enum.Material.Basalt, Parent = f })
	end
	fence(c, R, 70, f)
	local sp = {}
	for _, v in ipairs(scatter(G, 16, 110, R * 0.8, 40, avoid)) do
		table.insert(sp, c + v + Vector3.new(0, 6, 0))
	end
	return { spawns = sp, floorY = c.Y, R = R }
end

-- 운상 누각: 구름 위의 누각 셋과 가운데 높은 단, 사이사이 떠 있는 작은 섬 셋, 다리로 잇는다 (떨어지면 쓰러진다)
BUILD.cloud = function(c: Vector3, f: Folder)
	local G = rnd(41)
	local WOOD = Color3.fromRGB(150, 95, 60)
	local DECK = Color3.fromRGB(196, 160, 112)
	local OR, DR, CR = 86 * K2, 34 * 1.5, 22 * 1.6
	local outer = ring(3, OR, -math.pi / 2)
	local function deck(at: Vector3, r: number, roof: boolean)
		disc("Deck", at + Vector3.new(0, -1, 0), r, 2, DECK, Enum.Material.WoodPlanks, f)
		disc("DeckRim", at + Vector3.new(0, -1.2, 0), r + 1, 2.2, WOOD, Enum.Material.Wood, f)
		for _, v in ipairs(ring(math.floor(r / 2.4), r - 0.5)) do
			part({ Name = "RailPost", Size = Vector3.new(0.8, 3, 0.8), Position = at + v + Vector3.new(0, 1.5, 0), Color = Color3.fromRGB(170, 40, 35), Material = Enum.Material.Wood, Parent = f })
		end
		if roof then
			pavilion(at + Vector3.new(r * 0.35, 0, 0), 1.3, f, G() * 6)
			stoneLantern(at + Vector3.new(-r * 0.4, 0, r * 0.3), f)
			stoneLantern(at + Vector3.new(-r * 0.4, 0, -r * 0.3), f)
		end
	end
	for _, v in ipairs(outer) do
		deck(c + v, DR, true)
	end
	deck(c + Vector3.new(0, 5, 0), CR, false)
	-- 떠 있는 작은 섬 (풀 덮인 바위 위)
	local isles = ring(3, OR * 0.62, math.pi / 2)
	for _, v in ipairs(isles) do
		local at = c + v + Vector3.new(0, 2, 0)
		disc("Isle", at + Vector3.new(0, -1.5, 0), 16, 3, Color3.fromRGB(96, 130, 70), Enum.Material.Grass, f)
		part({ Name = "IsleRock", Shape = Enum.PartType.Ball, Size = Vector3.new(28, 28, 28), Position = at + Vector3.new(0, -16, 0), Color = Color3.fromRGB(120, 114, 104), Material = Enum.Material.Slate, Parent = f })
		rock(G, at + Vector3.new(5, 0, -4), 4, Color3.fromRGB(130, 124, 114), Enum.Material.Slate, f, Color3.fromRGB(90, 130, 70))
		part({ Name = "IsleTree", Size = Vector3.new(1.4, 8, 1.4), Position = at + Vector3.new(-5, 4, 3), Color = Color3.fromRGB(96, 70, 48), Material = Enum.Material.Wood, Parent = f })
		part({ Name = "IsleCanopy", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 7, 9), Position = at + Vector3.new(-5, 9, 3), Color = Color3.fromRGB(200, 120, 140), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
	end
	local function bridge(a: Vector3, b: Vector3, w: number)
		local mid = (a + b) / 2
		local len = (b - a).Magnitude
		part({ Name = "Bridge", Size = Vector3.new(w, 1.2, len), CFrame = CFrame.lookAt(mid, b), Color = DECK:Lerp(WOOD, 0.3), Material = Enum.Material.WoodPlanks, Parent = f })
		for _, side in ipairs({ -1, 1 }) do
			part({ Name = "BridgeRope", Size = Vector3.new(0.3, 0.3, len), CFrame = CFrame.lookAt(mid, b) * CFrame.new(side * (w / 2), 2.6, 0), Color = Color3.fromRGB(200, 50, 40), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
		end
	end
	for _, v in ipairs(outer) do
		local dir = v.Unit
		bridge(c + dir * (OR - DR + 1) + Vector3.new(0, -0.4, 0), c + dir * (CR - 1) + Vector3.new(0, 4.4, 0), 9)
	end
	-- 바깥 누각 → 작은 섬 → 다음 누각
	for i = 1, 3 do
		local a, b = outer[i], outer[i % 3 + 1]
		local mid = (a + b).Unit * OR * 0.62
		local best = isles[1]
		for _, iv in ipairs(isles) do
			if (iv - mid).Magnitude < (best - mid).Magnitude then
				best = iv
			end
		end
		local function edge(p: Vector3, q: Vector3, r: number): Vector3
			return c + p + (q - p).Unit * (r - 1) + Vector3.new(0, -0.4, 0)
		end
		bridge(edge(a, best, DR), edge(best, a, 16) + Vector3.new(0, 2, 0), 7)
		bridge(edge(best, b, 16) + Vector3.new(0, 2, 0), edge(b, best, DR), 7)
	end
	for _ = 1, 70 do
		local s = 24 + G() * 40
		part({ Name = "Cloud", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * 0.6, s), Position = c + Vector3.new((G() - 0.5) * 640, -30 - G() * 40, (G() - 0.5) * 560), Color = Color3.fromRGB(250, 250, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.25, CanCollide = false, CastShadow = false, Parent = f })
	end
	local sp = {}
	for _, v in ipairs(outer) do
		for _, o in ipairs(ring(5, 24, 0.5)) do
			table.insert(sp, c + v + o + Vector3.new(0, 4, 0))
		end
	end
	return { spawns = sp, floorY = c.Y, R = OR + DR, fall = true }
end

------------------------------------------------------------------------
-- 3.11판 대기실: 산기슭의 무관 뜰. 흰 담장 (기와 갓)으로 두른 박석 마당, 북쪽 큰 전각과 돌계단 (싸움터 문은 전각 앞),
-- 남쪽 솟을대문, 동쪽 연못과 돌다리, 서쪽 수련 마당 (목인 둘), 담 밖의 소나무 숲. 권법은 화면에서 골라 들어간다
------------------------------------------------------------------------
local lobby: any = nil
local function buildLobby(c: Vector3, f: Folder): any
	local G = rnd(5)
	local W, D = 70, 56 -- 마당 반 너비·반 깊이
	local STONE = Color3.fromRGB(196, 190, 176)
	local WALL = Color3.fromRGB(236, 230, 214)
	local TILE = Color3.fromRGB(58, 62, 70)
	local RED = Color3.fromRGB(160, 44, 36)
	disc("LobbyGround", c + Vector3.new(0, -2, 0), 170, 4, Color3.fromRGB(92, 124, 70), Enum.Material.Grass, f)
	-- 박석 마당 (줄눈이 보이게 판을 깐다)
	part({ Name = "CourtBed", Size = Vector3.new(W * 2, 0.5, D * 2), Position = c + Vector3.new(0, 0.2, 0), Color = STONE:Lerp(Color3.new(0, 0, 0), 0.25), Material = Enum.Material.Slate, Parent = f })
	for x = -W + 5, W - 5, 10 do
		for z = -D + 4, D - 4, 8 do
			local off = ((z // 8) % 2) * 5
			local xx = x + off
			if xx < W - 4 then
				part({ Name = "Paver", Size = Vector3.new(9.6, 0.4, 7.6), Position = c + Vector3.new(xx, 0.55, z), Color = STONE:Lerp(Color3.fromRGB(170, 160, 146), G() * 0.6), Material = Enum.Material.Slate, CanCollide = false, Parent = f })
			end
		end
	end
	-- 담장: 흰 벽 + 기와 갓 (남쪽 가운데는 대문, 동쪽은 연못으로 트였다)
	local function wallSeg(a: Vector3, b: Vector3)
		local mid, len = (a + b) / 2, (b - a).Magnitude
		local cf = CFrame.lookAt(mid, b)
		part({ Name = "WallStone", Size = Vector3.new(2.2, 2, len), CFrame = cf * CFrame.new(0, 1, 0), Color = Color3.fromRGB(150, 140, 126), Material = Enum.Material.Cobblestone, Parent = f })
		part({ Name = "Wall", Size = Vector3.new(1.8, 5, len), CFrame = cf * CFrame.new(0, 4.5, 0), Color = WALL, Material = Enum.Material.Plaster, Parent = f })
		part({ Name = "WallTile", Size = Vector3.new(3.4, 0.7, len + 1), CFrame = cf * CFrame.new(0, 7.3, 0), Color = TILE, Material = Enum.Material.Slate, Parent = f })
		part({ Name = "WallRidge", Size = Vector3.new(1.2, 0.6, len + 1), CFrame = cf * CFrame.new(0, 7.9, 0), Color = TILE:Lerp(Color3.new(0, 0, 0), 0.2), Material = Enum.Material.Slate, Parent = f })
	end
	local y = Vector3.new(0, 0, 0)
	wallSeg(c + Vector3.new(-W, 0, -D) + y, c + Vector3.new(-W, 0, D) + y)
	wallSeg(c + Vector3.new(-W, 0, D) + y, c + Vector3.new(-12, 0, D) + y)
	wallSeg(c + Vector3.new(12, 0, D) + y, c + Vector3.new(W, 0, D) + y)
	wallSeg(c + Vector3.new(W, 0, D) + y, c + Vector3.new(W, 0, 18) + y)
	wallSeg(c + Vector3.new(W, 0, -18) + y, c + Vector3.new(W, 0, -D) + y)
	-- 남쪽 솟을대문
	for _, x in ipairs({ -10, 10 }) do
		part({ Name = "GatePillar", Size = Vector3.new(2, 14, 2), Position = c + Vector3.new(x, 7, D), Color = RED, Material = Enum.Material.Wood, Parent = f })
	end
	part({ Name = "GateBeam", Size = Vector3.new(24, 1.6, 2.4), Position = c + Vector3.new(0, 13.6, D), Color = Color3.fromRGB(60, 90, 70), Material = Enum.Material.Wood, Parent = f })
	part({ Name = "GateRoof", Size = Vector3.new(28, 1.2, 9), Position = c + Vector3.new(0, 14.8, D), Color = TILE, Material = Enum.Material.Slate, Parent = f })
	part({ Name = "GateRoof2", Size = Vector3.new(22, 1.4, 5), Position = c + Vector3.new(0, 16, D), Color = TILE:Lerp(Color3.new(0, 0, 0), 0.15), Material = Enum.Material.Slate, Parent = f })
	-- 북쪽 전각: 세 단의 돌 기단과 계단, 붉은 기둥 여섯, 두 겹 기와지붕, 현판
	local hall = c + Vector3.new(0, 0, -D + 14)
	for k = 0, 2 do
		part({ Name = "HallPlinth", Size = Vector3.new(60 - k * 4, 1.4, 22 - k * 2), Position = hall + Vector3.new(0, 0.7 + k * 1.4, -k), Color = Color3.fromRGB(170 - k * 10, 164 - k * 10, 150 - k * 10), Material = Enum.Material.Granite, Parent = f })
	end
	for k = 0, 2 do
		part({ Name = "HallStep", Size = Vector3.new(18, 1.4, 2.4), Position = hall + Vector3.new(0, 0.7 + k * 1.4, 11 + 2.4 * (2 - k)), Color = Color3.fromRGB(176, 170, 156), Material = Enum.Material.Granite, Parent = f })
	end
	local floorY = 4.2
	for i = -2, 3 do
		local x = (i - 0.5) * 9.6
		part({ Name = "HallPillar", Size = Vector3.new(1.8, 16, 1.8), Position = hall + Vector3.new(x, floorY + 8, 6), Color = RED, Material = Enum.Material.Wood, Parent = f })
	end
	part({ Name = "HallWall", Size = Vector3.new(50, 16, 1.2), Position = hall + Vector3.new(0, floorY + 8, -6), Color = Color3.fromRGB(226, 214, 190), Material = Enum.Material.Plaster, Parent = f })
	part({ Name = "HallBeam", Size = Vector3.new(52, 2, 14), Position = hall + Vector3.new(0, floorY + 17, 0), Color = Color3.fromRGB(60, 96, 76), Material = Enum.Material.Wood, Parent = f })
	part({ Name = "HallRoof", Size = Vector3.new(64, 1.6, 26), Position = hall + Vector3.new(0, floorY + 18.6, 0), Color = TILE, Material = Enum.Material.Slate, Parent = f })
	part({ Name = "HallRoof2", Size = Vector3.new(48, 2, 16), Position = hall + Vector3.new(0, floorY + 20.4, 0), Color = TILE:Lerp(Color3.new(0, 0, 0), 0.12), Material = Enum.Material.Slate, Parent = f })
	part({ Name = "HallRidge", Size = Vector3.new(40, 1.6, 3), Position = hall + Vector3.new(0, floorY + 22, 0), Color = TILE:Lerp(Color3.new(0, 0, 0), 0.25), Material = Enum.Material.Slate, Parent = f })
	local plaque = part({ Name = "HallPlaque", Size = Vector3.new(14, 3.6, 0.5), Position = hall + Vector3.new(0, floorY + 14.4, 7.4), Color = Color3.fromRGB(40, 28, 22), Material = Enum.Material.Wood, Parent = f })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.PixelsPerStud = 40
	sg.Parent = plaque
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.TextScaled = true
	t.Font = Enum.Font.Antique
	t.TextColor3 = Color3.fromRGB(255, 214, 130)
	t.Text = "比 武 堂"
	t.Parent = sg
	-- 전각 가운데 문: 붉은 빛의 막 (싸움터로)
	local veil = part({ Name = "ArenaVeil", Size = Vector3.new(9, 12, 0.4), Position = hall + Vector3.new(0, floorY + 6, -5.2), Color = Color3.fromRGB(255, 120, 80), Material = Enum.Material.Neon, Transparency = 0.45, CanCollide = false, Parent = f })
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "ArenaGate"
	pp.ActionText = "싸움터로 들어가기 (지금 권법으로)"
	pp.ObjectText = "⚔ 비무당"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 16
	pp.RequiresLineOfSight = false
	pp.KeyboardKeyCode = Enum.KeyCode.T
	pp.Parent = veil
	-- 마당: 가운데 큰 향로, 양옆 석등 넷, 소나무 화분
	disc("CenserBase", c + Vector3.new(0, 1.2, 0), 3.4, 1.4, Color3.fromRGB(110, 96, 80), Enum.Material.Granite, f)
	part({ Name = "Censer", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 4, 5), Position = c + Vector3.new(0, 3.6, 0), Color = Color3.fromRGB(150, 110, 60), Material = Enum.Material.Metal, Parent = f })
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(230, 226, 220))
	smoke.Transparency = NumberSequence.new(0.6, 1)
	smoke.Size = NumberSequence.new(0.8, 3)
	smoke.Lifetime = NumberRange.new(3, 5)
	smoke.Speed = NumberRange.new(1, 2)
	smoke.Rate = 3
	smoke.Parent = part({ Name = "CenserTop", Size = Vector3.new(1, 1, 1), Position = c + Vector3.new(0, 6, 0), Transparency = 1, CanCollide = false, Parent = f })
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -18, 14 }) do
			stoneLantern(c + Vector3.new(x * 24, 0.6, z), f)
		end
	end
	-- 동쪽: 담 밖 연못과 돌다리, 바위
	local pond = c + Vector3.new(W + 34, 0, 0)
	disc("PondEdge", pond + Vector3.new(0, 0.1, 0), 26, 0.6, Color3.fromRGB(150, 146, 136), Enum.Material.Cobblestone, f)
	disc("Pond", pond + Vector3.new(0, 0.25, 0), 23, 0.6, Color3.fromRGB(80, 140, 170), Enum.Material.Glass, f, false)
	part({ Name = "PondBridge", Size = Vector3.new(50, 1, 5), Position = pond + Vector3.new(-6, 1, 0), Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Granite, Parent = f })
	for _ = 1, 6 do
		local a = G() * math.pi * 2
		rock(G, pond + Vector3.new(math.cos(a) * 25, 0, math.sin(a) * 25), 2.5 + G() * 2, Color3.fromRGB(120, 120, 112), Enum.Material.Slate, f, Color3.fromRGB(80, 120, 60))
	end
	for k = 1, 5 do
		disc("LilyPad", pond + Vector3.new((G() - 0.5) * 30, 0.6, (G() - 0.5) * 30), 1.6 + G(), 0.1, Color3.fromRGB(70, 140, 70), Enum.Material.Grass, f, false)
		if k % 2 == 0 then
			part({ Name = "Lotus", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 0.9, 1.2), Position = pond + Vector3.new((G() - 0.5) * 30, 0.9, (G() - 0.5) * 30), Color = Color3.fromRGB(255, 180, 200), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
		end
	end
	-- 서쪽 마당 안: 수련 자리 (목인 둘), 무기 걸이
	local yard = c + Vector3.new(-W + 18, 0, 16)
	disc("YardSand", yard + Vector3.new(0, 0.62, 0), 14, 0.2, Color3.fromRGB(200, 184, 150), Enum.Material.Sand, f, false)
	part({ Name = "Rack", Size = Vector3.new(10, 6, 1), Position = yard + Vector3.new(0, 3.4, -15), Color = Color3.fromRGB(110, 80, 54), Material = Enum.Material.Wood, Parent = f })
	-- 담 밖 소나무 숲 (흩어져, 덩이져)
	local function pine(at: Vector3, h: number)
		part({ Name = "PineTrunk", Size = Vector3.new(1.6, h * 0.55, 1.6), CFrame = CFrame.new(at + Vector3.new(0, h * 0.27, 0)) * CFrame.Angles((G() - 0.5) * 0.12, 0, (G() - 0.5) * 0.12), Color = Color3.fromRGB(110, 70, 50), Material = Enum.Material.Wood, Parent = f })
		for k = 0, 2 do
			local s = (10 - k * 2.5) * (h / 22)
			part({ Name = "PineTop", Shape = Enum.PartType.Ball, Size = Vector3.new(s * 1.4, s * 0.55, s * 1.4), Position = at + Vector3.new((G() - 0.5) * 2, h * (0.55 + k * 0.17), (G() - 0.5) * 2), Color = Color3.fromRGB(46 + k * 8, 92 + k * 8, 58), Material = Enum.Material.Grass, CanCollide = false, Parent = f })
		end
	end
	local avoidL = { { Vector3.new(W + 34, 0, 0), 32 }, { Vector3.new(0, 0, D + 20), 26 } }
	for _, v in ipairs(scatter(G, 22, 100, 160, 22, avoidL)) do
		if math.abs(v.X) > W + 10 or math.abs(v.Z) > D + 10 then
			pine(c + v, 18 + G() * 12)
		end
	end
	fence(c, 165, 40, f)
	local spots = {}
	for _, v in ipairs(scatter(G, 10, 12, 40, 8)) do
		if math.abs(v.X) < W - 8 and v.Z > -D + 30 and v.Z < D - 6 then
			table.insert(spots, c + v + Vector3.new(0, 4, 0))
		end
	end
	if #spots == 0 then
		table.insert(spots, c + Vector3.new(0, 4, 20))
	end
	return { center = c, spots = spots, gate = pp, dummies = { yard + Vector3.new(-6, 3, 0), yard + Vector3.new(6, 3, 0) } }
end

function Battle.build(): any
	local f = Instance.new("Folder")
	f.Name = "BattleMaps"
	f.Parent = workspace
	for i, m in ipairs(B.maps) do
		local c = Vector3.new(20000 + (i - 1) * 2000, 0, 20000)
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
	lobby = buildLobby(Vector3.new(17000, 0, 20000), f)
	Battle.lobby = lobby
	-- 처음 태어나는 자리 (대기실)
	local sl = Instance.new("SpawnLocation")
	sl.Name = "BattleSpawn"
	sl.Anchored = true
	sl.Size = Vector3.new(8, 1, 8)
	sl.Transparency = 1
	sl.CanCollide = false
	sl.Neutral = true
	sl.Duration = 0
	sl.CFrame = CFrame.new(lobby.spots[1] - Vector3.new(0, 3, 0))
	sl.Parent = f
	Battle.spawnLoc = sl
	return { train = {}, rings = {} }
end

------------------------------------------------------------------------
-- 한 판의 흐름: 맵마다 mapTime초. 판이 끝나면 가장 많이 쓰러뜨린 사람이 이긴다
------------------------------------------------------------------------
local cur = 1
local roundEnd = 0
local inArena: { [Player]: boolean } = {}
local votes: { [Player]: number } = {}
function Battle.inArena(player: Player): boolean
	return inArena[player] == true
end
type Sess = { k: number, d: number, streak: number, rec: Rec, dirty: boolean, loaded: boolean }
local sess: { [Player]: Sess } = {}
local ctx: any = nil

function Battle.current(): any
	return maps[cur]
end

-- 다른 사람에게서 가장 먼 자리
function Battle.spawnCF(player: Player?): CFrame
	if player and not inArena[player] and lobby then
		local sp = lobby.spots[math.random(1, #lobby.spots)]
		return CFrame.lookAt(sp, Vector3.new(lobby.center.X, sp.Y, lobby.center.Z))
	end
	local m = maps[cur]
	local best, bestD = m.info.spawns[1], -1
	for _, sp in ipairs(m.info.spawns) do
		local near = math.huge
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player and inArena[other] then
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
	inArena[player] = nil
	votes[player] = nil
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
		table.insert(list, { id = player.UserId, name = player.DisplayName, k = s.k, d = s.d, streak = s.streak, total = s.rec.kills, arena = inArena[player] == true })
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
	for _, player in ipairs(Players:GetPlayers()) do
		if ctx and inArena[player] then
			ctx.respawn(player)
		end
	end
end

-- 다음 맵: 표가 가장 많은 맵 (같으면 차례대로 다음)
local function voteCounts(): { number }
	local n = {}
	for i = 1, #maps do
		n[i] = 0
	end
	for player, i in pairs(votes) do
		if player.Parent and n[i] then
			n[i] += 1
		end
	end
	return n
end
local function nextMap(): number
	local n = voteCounts()
	local best, bestN = cur % #maps + 1, 0
	for k = 1, #maps do
		local i = (cur + k - 1) % #maps + 1
		if n[i] > bestN then
			best, bestN = i, n[i]
		end
	end
	return best
end

-- 대기실 ↔ 싸움터, 투표. 안 되면 까닭을 돌려준다
function Battle.request(player: Player, action: string, arg: any): string?
	if not ctx then
		return nil
	end
	local f = ctx.fighter(player)
	if action == "battleEnter" then
		if inArena[player] then
			return "이미 싸움터에 있어요"
		end
		if not f or f.dead then
			return "잠시 뒤에 다시"
		end
		inArena[player] = true
		f.model:SetAttribute("InArena", true)
		ctx.respawn(player)
		ctx.push:FireClient(player, "battleNote", { text = "⚔ " .. maps[cur].name .. " 싸움터에 들어왔다! (5초 동안 보호)" })
		return nil
	elseif action == "battleLobby" then
		if not inArena[player] then
			return "이미 대기실이에요"
		end
		if f and f.combatUntil > os.clock() then
			return string.format("싸우는 중에는 나갈 수 없어요 (마지막으로 맞거나 때린 뒤 %d초)", B.lobbyLeave)
		end
		inArena[player] = nil
		if f then
			f.model:SetAttribute("InArena", nil)
		end
		ctx.respawn(player)
		return "🏯 대기실로 나왔어요"
	elseif action == "battleVote" then
		local i = math.floor(tonumber(arg) or 0)
		if i < 1 or i > #maps then
			return nil
		end
		votes[player] = i
		return "🗳 다음 맵으로 '" .. maps[i].name .. "'에 투표했어요"
	end
	return nil
end
-- 캐릭터가 새로 생기면 싸움터 표시를 다시 붙인다
function Battle.onCharacter(player: Player, model: Model)
	model:SetAttribute("InArena", inArena[player] or nil)
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
				local nxt = maps[nextMap()]
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
				local nxt = nextMap()
				ctx.push:FireAllClients("battleRound", { winner = winnerName, kills = top and top.k or 0, map = maps[cur].name, next = maps[nxt].name })
				for _, s in pairs(sess) do
					s.k, s.d, s.streak = 0, 0, 0
				end
				table.clear(votes)
				moveAllTo(nxt)
				roundEnd = os.clock() + B.mapTime
				warned = false
			end
			-- 떨어지면 쓰러진다 (마지막에 때린 사람의 몫)
			local m = maps[cur]
			for _, player in ipairs(Players:GetPlayers()) do
				local f = ctx.fighter(player)
				if f and not f.dead and inArena[player] and f.root.Position.Y < m.info.floorY + B.fallY then
					ctx.kill(f)
				end
			end
			-- 모두에게 판 상태
			local st = standings()
			local arenaN = 0
			for _, on in pairs(inArena) do
				if on then
					arenaN += 1
				end
			end
			ctx.push:FireAllClients("battle", { map = m.name, desc = m.desc, left = math.floor(left), list = st, votes = voteCounts(), next = maps[nextMap()].name, arena = arenaN, total = #Players:GetPlayers() })
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
