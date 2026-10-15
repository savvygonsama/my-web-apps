-- HoleServer (Script, ServerScriptService)
-- 삼키기 판정, 질량, 업그레이드, 빅뱅과 빅뱅 상점, 위성(펫), 스킨, 로벅스 상점, 부스트, 별똥별, 저장.
-- 중요한 계산은 모두 서버가 한다.
--   World  조명, 세계 2개의 구역, 문, 물체 배치
--   Store  게임패스와 개발자 상품 결제

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local World = require(script:WaitForChild("World"))
local Store = require(script:WaitForChild("Store"))

local DATASTORE_NAME = "BlackHole_v1"
local SAVE_INTERVAL = 90
local TICK = 0.1

------------------------------------------------------------------------
-- 통신 채널
------------------------------------------------------------------------
local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "HoleRemotes"
local Request = Instance.new("RemoteEvent")
Request.Name = "Request"
Request.Parent = remoteFolder
local Push = Instance.new("RemoteEvent")
Push.Name = "Push"
Push.Parent = remoteFolder
remoteFolder.Parent = ReplicatedStorage

------------------------------------------------------------------------
-- 맵
------------------------------------------------------------------------
World.setupLighting()
local _, portals = World.buildZones()
local objects, objectFolder = World.placeObjects()
local holding = Instance.new("Folder")
holding.Name = "EatenObjects"
holding.Parent = ServerStorage

-- 구역별로 나눠 둔다 (가까운 구역만 살펴보면 된다)
local byZone: { [number]: { World.ObjectRec } } = {}
for _, rec in ipairs(objects) do
	byZone[rec.zone] = byZone[rec.zone] or {}
	table.insert(byZone[rec.zone], rec)
end

------------------------------------------------------------------------
-- 저장
------------------------------------------------------------------------
local store: DataStore? = nil
do
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if ok then
		store = ds
	end
end

type Sat = { uid: number, id: string, gold: boolean }

type Profile = {
	mass: number,
	total: number, -- 지금까지 삼킨 질량 (빅뱅해도 남는다)
	eaten: number,
	size: number,
	pull: number,
	mult: number,
	bigbang: number,
	dm: number, -- 암흑 물질
	bb: { [string]: number }, -- 빅뱅 상점 레벨
	sats: { Sat },
	equipped: { number }, -- 장착한 위성 uid
	nextUid: number,
	skins: { [string]: boolean }, -- 암흑 물질로 산 스킨, 세계 2 스킨
	skin: string,
	passes: { [string]: boolean }, -- 산 게임패스 (들어올 때 다시 확인한다)
	packGiven: boolean,
	boostUntil: number, -- os.time 기준
	respawnUntil: number,
	receipts: { string },
	auto: boolean,
	hatched: number,
}

local function defaultProfile(): Profile
	local bb = {}
	for _, b in ipairs(Config.BigbangShop) do
		bb[b.id] = 0
	end
	return {
		mass = 0,
		total = 0,
		eaten = 0,
		size = 0,
		pull = 0,
		mult = 0,
		bigbang = 0,
		dm = 0,
		bb = bb,
		sats = {},
		equipped = {},
		nextUid = 1,
		skins = {},
		skin = "violet",
		passes = {},
		packGiven = false,
		boostUntil = 0,
		respawnUntil = 0,
		receipts = {},
		auto = false,
		hatched = 0,
	}
end

local function sanitize(data: any): Profile
	local p = defaultProfile()
	if type(data) ~= "table" then
		return p
	end
	local function num(v: any, hi: number): number
		if type(v) ~= "number" or v ~= v then
			return 0
		end
		return math.clamp(v, 0, hi)
	end
	p.mass = num(data.mass, math.huge)
	p.total = num(data.total, math.huge)
	p.eaten = math.floor(num(data.eaten, math.huge))
	p.size = math.floor(num(data.size, Config.UPGRADE_BY_ID.size.maxLevel))
	p.pull = math.floor(num(data.pull, Config.UPGRADE_BY_ID.pull.maxLevel))
	p.mult = math.floor(num(data.mult, Config.UPGRADE_BY_ID.mult.maxLevel))
	p.bigbang = math.floor(num(data.bigbang, 1000))
	p.dm = math.floor(num(data.dm, 1e9))
	if type(data.bb) == "table" then
		for _, b in ipairs(Config.BigbangShop) do
			p.bb[b.id] = math.floor(num(data.bb[b.id], b.maxLevel))
		end
	end
	local uids = {}
	if type(data.sats) == "table" then
		for _, s in ipairs(data.sats) do
			if type(s) == "table" and type(s.id) == "string" and Config.SAT_BY_ID[s.id] and type(s.uid) == "number" and not uids[s.uid] then
				uids[s.uid] = true
				table.insert(p.sats, { uid = math.floor(s.uid), id = s.id, gold = s.gold == true })
			end
			if #p.sats >= Config.SAT_INVENTORY + 10 then
				break
			end
		end
	end
	p.nextUid = math.max(1, math.floor(num(data.nextUid, 1e12)))
	for _, s in ipairs(p.sats) do
		p.nextUid = math.max(p.nextUid, s.uid + 1)
	end
	if type(data.equipped) == "table" then
		for _, uid in ipairs(data.equipped) do
			if uids[uid] and not table.find(p.equipped, uid) then
				table.insert(p.equipped, uid)
			end
		end
	end
	if type(data.skins) == "table" then
		for id, v in pairs(data.skins) do
			if type(id) == "string" and Config.SKIN_BY_ID[id] and v == true then
				p.skins[id] = true
			end
		end
	end
	if type(data.skin) == "string" and Config.SKIN_BY_ID[data.skin] then
		p.skin = data.skin
	end
	if type(data.passes) == "table" then
		for key, v in pairs(data.passes) do
			if type(key) == "string" and Config.PASS_BY_KEY[key] and v == true then
				p.passes[key] = true
			end
		end
	end
	p.packGiven = data.packGiven == true
	p.boostUntil = num(data.boostUntil, 1e11)
	p.respawnUntil = num(data.respawnUntil, 1e11)
	if type(data.receipts) == "table" then
		for _, r in ipairs(data.receipts) do
			if type(r) == "string" then
				table.insert(p.receipts, r)
			end
		end
	end
	p.auto = data.auto == true
	p.hatched = math.floor(num(data.hatched, math.huge))
	return p
end

local function isTester(player: Player): boolean
	if not Config.TEST_MODE then
		return false
	end
	if RunService:IsStudio() then
		return true
	end
	return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

type State = {
	canSave: boolean,
	dirty: boolean,
	tester: boolean,
	reqWindow: number,
	reqCount: number,
	zone: number,
	passes: { [string]: boolean }, -- 들어올 때 확인한 게임패스
	starPos: Vector3?,
	starExpire: number,
	nextStar: number,
	starUntil: number,
	portalAt: number,
	lockToastAt: number,
}

local profiles: { [Player]: Profile } = {}
local states: { [Player]: State } = {}

local function loadProfile(player: Player): (Profile, boolean)
	local ds = store
	if not ds then
		return defaultProfile(), false
	end
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return ds:GetAsync("p_" .. player.UserId)
		end)
		if ok then
			return sanitize(result), true
		end
		warn("[BlackHole] 불러오기 실패 (" .. attempt .. "/3):", result)
		task.wait(1.5 * attempt)
	end
	-- 불러오기에 실패했을 때 저장하면 기존 기록을 덮어쓰므로 저장을 끈다
	return defaultProfile(), false
end

local function saveProfile(player: Player)
	local p, st, ds = profiles[player], states[player], store
	if not (p and st and ds and st.canSave) then
		return
	end
	local ok, err = pcall(function()
		ds:SetAsync("p_" .. player.UserId, p)
	end)
	if ok then
		st.dirty = false
	else
		warn("[BlackHole] 저장 실패:", err)
	end
end

------------------------------------------------------------------------
-- 계산 도우미
------------------------------------------------------------------------
local Calc = {}

function Calc.hasPass(player: Player, key: string): boolean
	local p, st = profiles[player], states[player]
	return (p and p.passes[key] == true) or (st and st.passes[key] == true) or false
end

function Calc.radius(p: Profile): number
	return Config.radius(p.size)
end

function Calc.slots(player: Player, p: Profile): number
	local n = Config.SAT_SLOTS + (p.bb.slots or 0)
	if Calc.hasPass(player, "vip") then
		n += 1
	end
	if Calc.hasPass(player, "slots2") then
		n += 2
	end
	if Calc.hasPass(player, "petpack") then
		n += 1
	end
	return n
end

function Calc.findSat(p: Profile, uid: number): (Sat?, number)
	for i, s in ipairs(p.sats) do
		if s.uid == uid then
			return s, i
		end
	end
	return nil, 0
end

-- 장착한 위성 배율 합: 1 + Σ(배율 - 1)
function Calc.satMult(p: Profile): number
	local m = 1
	for _, uid in ipairs(p.equipped) do
		local s = Calc.findSat(p, uid)
		if s then
			m += Config.satMult(s.id, s.gold) - 1
		end
	end
	return m
end

function Calc.totalMult(player: Player, p: Profile): number
	local st = states[player]
	local now = os.time()
	return Config.totalMult({
		mult = p.mult,
		bigbang = p.bigbang,
		bbMass = p.bb.mass,
		sats = Calc.satMult(p),
		vip = Calc.hasPass(player, "vip"),
		mass2 = Calc.hasPass(player, "mass2"),
		boost = p.boostUntil > now,
		star = st ~= nil and st.starUntil > os.clock(),
	})
end

function Calc.skinUnlocked(player: Player, p: Profile, skin: any): boolean
	if skin.unlock == "bigbang" then
		return p.bigbang >= skin.value
	elseif skin.unlock == "dm" or skin.unlock == "world2" then
		return p.skins[skin.id] == true
	elseif skin.unlock == "pass" then
		return Calc.hasPass(player, skin.value)
	end
	return false
end

-- 세계 번호가 열렸는지
function Calc.worldOpen(p: Profile, world: number): boolean
	local w = Config.Worlds[world]
	return w ~= nil and p.bigbang >= w.needBigbang
end

------------------------------------------------------------------------
-- 상태 보내기와 캐릭터 꾸미기
------------------------------------------------------------------------
local function pushState(player: Player)
	local p, st = profiles[player], states[player]
	if not p or not st then
		return
	end
	local r = Calc.radius(p)
	local now = os.time()
	local skins = {}
	for _, skin in ipairs(Config.Skins) do
		if Calc.skinUnlocked(player, p, skin) then
			table.insert(skins, skin.id)
		end
	end
	local passes = {}
	for _, pass in ipairs(Config.GamePasses) do
		if Calc.hasPass(player, pass.key) then
			passes[pass.key] = true
		end
	end
	Push:FireClient(player, "state", {
		mass = p.mass,
		total = p.total,
		eaten = p.eaten,
		size = p.size,
		pull = p.pull,
		mult = p.mult,
		bigbang = p.bigbang,
		dm = p.dm,
		bb = p.bb,
		radius = r,
		pullRange = Config.pullRange(r, p.pull, p.bb.pull),
		totalMult = Calc.totalMult(player, p),
		satMult = Calc.satMult(p),
		sats = p.sats,
		equipped = p.equipped,
		slots = Calc.slots(player, p),
		skins = skins,
		skin = p.skin,
		passes = passes,
		boostLeft = math.max(0, p.boostUntil - now),
		respawnLeft = math.max(0, p.respawnUntil - now),
		starLeft = math.max(0, st.starUntil - os.clock()),
		auto = p.auto,
		hatched = p.hatched,
		tester = st.tester,
		canSave = st.canSave,
	})
end

local function updateLeaderstats(player: Player)
	local p = profiles[player]
	local ls = player:FindFirstChild("leaderstats")
	if not p or not ls then
		return
	end
	local massValue = ls:FindFirstChild("질량")
	local sizeValue = ls:FindFirstChild("크기")
	local bbValue = ls:FindFirstChild("빅뱅")
	if massValue and massValue:IsA("StringValue") then
		massValue.Value = Config.formatNumber(p.total)
	end
	if sizeValue and sizeValue:IsA("StringValue") then
		sizeValue.Value = Config.formatSize(Calc.radius(p))
	end
	if bbValue and bbValue:IsA("IntValue") then
		bbValue.Value = p.bigbang
	end
end

-- 캐릭터는 보이지 않게 하고, 블랙홀 모양은 모든 화면이 직접 그린다 (크기, 스킨, 위성만 속성으로 알려 준다)
local function applyHole(player: Player)
	local p = profiles[player]
	local char = player.Character
	if not p or not char then
		return
	end
	local r = Calc.radius(p)
	local skin = Config.SKIN_BY_ID[p.skin]
	if not skin or not Calc.skinUnlocked(player, p, skin) then
		skin = Config.Skins[1]
		p.skin = skin.id
	end
	local vip = Calc.hasPass(player, "vip")
	player:SetAttribute("VIP", vip)
	char:SetAttribute("HoleR", r)
	char:SetAttribute("HoleSkin", skin.index)
	local satList = {}
	for _, uid in ipairs(p.equipped) do
		local s = Calc.findSat(p, uid)
		if s then
			table.insert(satList, s.id .. ":" .. (s.gold and "1" or "0"))
		end
	end
	char:SetAttribute("Sats", table.concat(satList, ","))
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = Config.walkSpeed(r, p.bb.speed, Calc.hasPass(player, "speed2"))
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	local head = char:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local tag = head:FindFirstChild("HoleTag")
		if not tag then
			local gui = Instance.new("BillboardGui")
			gui.Name = "HoleTag"
			gui.Size = UDim2.new(0, 240, 0, 46)
			gui.AlwaysOnTop = true
			gui.LightInfluence = 0
			gui.MaxDistance = 2500
			local l = Instance.new("TextLabel")
			l.Name = "Label"
			l.Size = UDim2.fromScale(1, 1)
			l.BackgroundTransparency = 1
			l.Font = Enum.Font.GothamBlack
			l.TextScaled = true
			l.TextColor3 = Color3.new(1, 1, 1)
			l.TextStrokeTransparency = 0.3
			l.Parent = gui
			gui.Parent = head
			tag = gui
		end
		local gui = tag :: BillboardGui
		gui.StudsOffset = Vector3.new(0, 4 + r * 0.25, 0)
		local label = gui:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.Text = string.format("%s%s · ⚫%s", vip and "👑 " or "", player.DisplayName, Config.formatSize(r))
			label.TextColor3 = vip and Color3.fromRGB(255, 215, 80) or skin.b
		end
	end
	updateLeaderstats(player)
end

local function hideBody(char: Model)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = 1
			d.CastShadow = false
		elseif d:IsA("Decal") then
			d.Transparency = 1
		end
	end
end

local function toast(player: Player, text: string)
	Push:FireClient(player, "toast", text)
end

local function moveTo(player: Player, pos: Vector3)
	local char = player.Character
	if char then
		char:PivotTo(CFrame.new(pos))
	end
end

-- 세계 시작 지점
local function spawnPos(world: number): Vector3
	return Vector3.new(Config.Worlds[world].x, 5, 22)
end

------------------------------------------------------------------------
-- 삼키기
------------------------------------------------------------------------
local function respawn(rec: World.ObjectRec)
	rec.model:SetAttribute("EatenBy", nil)
	for part, can in pairs(rec.collide) do
		part.CanCollide = can
	end
	rec.model.Parent = objectFolder
	rec.alive = true
end

local function eat(player: Player, rec: World.ObjectRec, factor: number)
	rec.alive = false
	rec.model:SetAttribute("EatenBy", player.UserId)
	for part in pairs(rec.collide) do
		part.CanCollide = false
	end
	-- 빨려 들어가는 모습은 화면마다 그리고, 잠시 뒤 서버에서 치운다
	task.delay(0.6, function()
		if not rec.alive then
			rec.model.Parent = holding
		end
	end)
	local wait = Config.Zones[rec.zone].respawn * (0.8 + math.random() * 0.5) * factor
	task.delay(wait, function()
		if not rec.alive then
			respawn(rec)
		end
	end)
end

local function flatDist(a: Vector3, b: Vector3): number
	local dx, dz = a.X - b.X, a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

-- 별똥별: 내 근처 같은 구역 안에 떨어뜨린다 (화면에는 그 사람에게만 보인다)
local function dropStar(player: Player, st: State, pos: Vector3, r: number)
	local zi = Config.zoneAt(pos)
	local zone = Config.Zones[zi]
	local wx = Config.Worlds[zone.world].x
	local z0 = Config.zoneStart(zi)
	local a = math.random() * math.pi * 2
	local d = r * 1.5 + 25 + math.random() * (r + 30)
	local x = math.clamp(pos.X + math.cos(a) * d, wx - zone.width / 2 + 10, wx + zone.width / 2 - 10)
	local z = math.clamp(pos.Z + math.sin(a) * d, z0 + 10, z0 + zone.length - 10)
	local spot = Vector3.new(x, 0, z)
	st.starPos = spot
	st.starExpire = os.clock() + Config.STAR_LIFETIME
	Push:FireClient(player, "star", { pos = spot, life = Config.STAR_LIFETIME })
end

local function tickPlayer(player: Player, p: Profile, st: State)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local pos = root.Position
	local r = Calc.radius(p)
	local reach = r + Config.pullRange(r, p.pull, p.bb.pull)
	local zone = Config.zoneAt(pos)
	local world = Config.Zones[zone].world
	if zone ~= st.zone then
		st.zone = zone
		Push:FireClient(player, "zone", zone)
	end
	local now = os.clock()

	-- 세계 문
	for _, portal in ipairs(portals) do
		if flatDist(portal.pos, pos) < 12 and now > st.portalAt then
			st.portalAt = now + 3
			if Calc.worldOpen(p, portal.to) then
				moveTo(player, spawnPos(portal.to))
				Push:FireClient(player, "world", portal.to)
			elseif now > st.lockToastAt then
				st.lockToastAt = now + 4
				toast(player, string.format("🔒 세계 %d은(는) 빅뱅 %d번 하면 열려요", portal.to, Config.Worlds[portal.to].needBigbang))
			end
		end
	end

	-- 별똥별
	if st.starPos then
		local spot = st.starPos :: Vector3
		if flatDist(spot, pos) <= reach + 3 then
			st.starPos = nil
			st.starUntil = math.max(now, st.starUntil) + Config.STAR_BOOST
			st.nextStar = now + Config.STAR_INTERVAL * (0.8 + math.random() * 0.5)
			Push:FireClient(player, "starGot", { pos = spot, left = st.starUntil - now })
			pushState(player)
		elseif now > st.starExpire then
			st.starPos = nil
			st.nextStar = now + Config.STAR_INTERVAL * 0.5
		end
	elseif now > st.nextStar then
		dropStar(player, st, pos, r)
	end

	local mult = Calc.totalMult(player, p)
	local factor = Config.respawnFactor(p.bb.respawn, Calc.hasPass(player, "vip"), p.respawnUntil > os.time())
	local reachable = Config.maxZone(world, r)
	local eatenList = {}
	local gained = 0
	local ateSun = false
	for zi = math.max(1, zone - 1), math.min(#Config.Zones, zone + 1) do
		if Config.Zones[zi].world == world then
			for _, rec in ipairs(byZone[zi] or {}) do
				if rec.alive and rec.zone <= reachable and rec.def.size <= r and flatDist(rec.pos, pos) <= reach + rec.def.size * 0.5 then
					eat(player, rec, factor)
					local m = rec.def.mass * mult
					gained += m
					table.insert(eatenList, { pos = rec.pos, mass = m, size = rec.def.size, name = rec.def.name })
					if rec.def.id == "candysun" then
						ateSun = true
					end
					if #eatenList >= 40 then
						break
					end
				end
			end
		end
	end
	if #eatenList > 0 then
		p.mass += gained
		p.total += gained
		p.eaten += #eatenList
		st.dirty = true
		Push:FireClient(player, "eat", { list = eatenList, gained = gained, mass = p.mass })
		updateLeaderstats(player)
		if ateSun and not p.skins.sweet then
			p.skins.sweet = true
			Push:FireClient(player, "unlock", { kind = "skin", name = Config.SKIN_BY_ID.sweet.name })
			pushState(player)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(TICK)
		for player, p in pairs(profiles) do
			local st = states[player]
			if st then
				local ok, err = pcall(tickPlayer, player, p, st)
				if not ok then
					warn("[BlackHole] 삼키기 오류:", err)
				end
			end
		end
	end
end)

------------------------------------------------------------------------
-- 업그레이드, 자동 업그레이드, 빅뱅, 이동
------------------------------------------------------------------------
local Actions = {}

-- 업그레이드 하나를 살 수 있는 만큼 산다. quiet면 실패해도 알림을 띄우지 않는다
function Actions.buyUpgrade(player: Player, id: any, many: any, quiet: boolean?): number
	local p = profiles[player]
	local u = type(id) == "string" and Config.UPGRADE_BY_ID[id]
	if not u then
		return 0
	end
	local bought = 0
	local limit = many == true and 200 or 1
	while bought < limit do
		local level = (p :: any)[u.id] :: number
		if level >= u.maxLevel then
			break
		end
		local cost = Config.upgradeCost(u.id, level)
		if p.mass < cost then
			break
		end
		p.mass -= cost;
		(p :: any)[u.id] = level + 1
		bought += 1
	end
	if bought == 0 then
		if not quiet then
			local level = (p :: any)[u.id] :: number
			if level >= u.maxLevel then
				toast(player, u.name .. "은(는) 이미 최대예요")
			else
				toast(player, "질량이 부족해요 (필요 💠" .. Config.formatNumber(Config.upgradeCost(u.id, level)) .. ")")
			end
		end
		return 0
	end
	states[player].dirty = true
	applyHole(player)
	Push:FireClient(player, "upgraded", { id = u.id, count = bought, level = (p :: any)[u.id], quiet = quiet })
	pushState(player)
	return bought
end

-- 자동 업그레이드: 가장 싼 것부터 계속 산다 (크기를 조금 더 우선)
function Actions.autoUpgrade(player: Player, p: Profile)
	local boughtAny = false
	local sizeBefore = p.size
	for _ = 1, 60 do
		local best, bestCost = nil, math.huge
		for _, u in ipairs(Config.Upgrades) do
			local level = (p :: any)[u.id] :: number
			if level < u.maxLevel then
				local cost = Config.upgradeCost(u.id, level) * (u.id == "size" and 0.7 or 1)
				if cost < bestCost then
					best, bestCost = u, cost
				end
			end
		end
		if not best then
			break
		end
		local level = (p :: any)[best.id] :: number
		local cost = Config.upgradeCost(best.id, level)
		if p.mass < cost then
			break
		end
		p.mass -= cost;
		(p :: any)[best.id] = level + 1
		boughtAny = true
	end
	if boughtAny then
		states[player].dirty = true
		applyHole(player)
		if p.size > sizeBefore then
			Push:FireClient(player, "upgraded", { id = "size", count = p.size - sizeBefore, level = p.size, quiet = true })
		end
		pushState(player)
	end
end

task.spawn(function()
	while true do
		task.wait(0.5)
		for player, p in pairs(profiles) do
			if p.auto then
				pcall(Actions.autoUpgrade, player, p)
			end
		end
	end
end)

function Actions.bigbang(player: Player)
	local p = profiles[player]
	if p.size < Config.BIGBANG_LEVEL then
		toast(player, string.format("크기 레벨 %d(⚫%s) 이상이어야 빅뱅할 수 있어요", Config.BIGBANG_LEVEL, Config.formatSize(Config.radius(Config.BIGBANG_LEVEL))))
		return
	end
	local reward = Config.darkMatterReward(p.size, p.bigbang)
	local before = {}
	for _, skin in ipairs(Config.Skins) do
		before[skin.id] = Calc.skinUnlocked(player, p, skin)
	end
	p.bigbang += 1
	p.dm += reward
	p.mass = 0
	p.size = math.min(Config.UPGRADE_BY_ID.size.maxLevel, (p.bb.start or 0) * 2)
	p.pull = 0
	p.mult = 0
	states[player].dirty = true
	local newSkins = {}
	for _, skin in ipairs(Config.Skins) do
		if not before[skin.id] and Calc.skinUnlocked(player, p, skin) then
			table.insert(newSkins, skin.name)
			p.skin = skin.id
		end
	end
	local world = Config.Zones[states[player].zone].world
	moveTo(player, spawnPos(world))
	applyHole(player)
	Push:FireClient(player, "bigbang", {
		count = p.bigbang,
		dm = reward,
		skins = newSkins,
		world2 = p.bigbang == Config.Worlds[2].needBigbang,
	})
	pushState(player)
end

function Actions.teleport(player: Player, zoneArg: any)
	local p = profiles[player]
	local zi = math.floor(tonumber(zoneArg) or 0)
	local zone = Config.Zones[zi]
	if not zone then
		return
	end
	if not Calc.worldOpen(p, zone.world) then
		toast(player, string.format("🔒 세계 %d은(는) 빅뱅 %d번 하면 열려요", zone.world, Config.Worlds[zone.world].needBigbang))
		return
	end
	local r = Calc.radius(p)
	if zi > Config.maxZone(zone.world, r) then
		toast(player, string.format("크기 %d 이상이어야 갈 수 있어요", zone.need))
		return
	end
	local z0 = Config.zoneStart(zi)
	local z = math.min(z0 + 20 + r, z0 + zone.length / 2)
	moveTo(player, Vector3.new(Config.Worlds[zone.world].x, 5 + r * 0.2, z))
end

------------------------------------------------------------------------
-- 빅뱅 상점, 스킨
------------------------------------------------------------------------
function Actions.bbShop(player: Player, id: any)
	local p = profiles[player]
	local b = type(id) == "string" and Config.BB_BY_ID[id]
	if not b then
		return
	end
	local level = p.bb[b.id] or 0
	if level >= b.maxLevel then
		toast(player, b.name .. "은(는) 이미 최대예요")
		return
	end
	local cost = Config.bigbangShopCost(b.id, level)
	if p.dm < cost then
		toast(player, string.format("암흑 물질이 부족해요 (필요 🌑%d)", cost))
		return
	end
	p.dm -= cost
	p.bb[b.id] = level + 1
	states[player].dirty = true
	applyHole(player)
	Push:FireClient(player, "bbBought", { id = b.id, level = level + 1 })
	pushState(player)
end

function Actions.skin(player: Player, id: any)
	local p = profiles[player]
	local skin = type(id) == "string" and Config.SKIN_BY_ID[id]
	if not skin then
		return
	end
	if not Calc.skinUnlocked(player, p, skin) then
		if skin.unlock == "dm" then
			if p.dm < skin.value then
				toast(player, string.format("암흑 물질이 부족해요 (필요 🌑%d)", skin.value))
				return
			end
			p.dm -= skin.value
			p.skins[skin.id] = true
			toast(player, "🎨 " .. skin.name .. " 스킨을 얻었어요!")
		elseif skin.unlock == "bigbang" then
			toast(player, string.format("빅뱅 %d번 하면 열려요", skin.value))
			return
		elseif skin.unlock == "world2" then
			toast(player, "세계 2의 사탕 태양을 삼키면 열려요")
			return
		else
			toast(player, "💎 상점의 " .. Config.PASS_BY_KEY[skin.value].name .. "에 들어 있는 스킨이에요")
			return
		end
	end
	p.skin = skin.id
	states[player].dirty = true
	applyHole(player)
	pushState(player)
end

------------------------------------------------------------------------
-- 위성 (펫)
------------------------------------------------------------------------
local Sats = {}

function Sats.add(p: Profile, id: string, gold: boolean): Sat
	local s = { uid = p.nextUid, id = id, gold = gold }
	p.nextUid += 1
	table.insert(p.sats, s)
	return s
end

function Sats.unequip(p: Profile, uid: number)
	local i = table.find(p.equipped, uid)
	if i then
		table.remove(p.equipped, i)
	end
end

function Sats.remove(p: Profile, uid: number)
	Sats.unequip(p, uid)
	local _, i = Calc.findSat(p, uid)
	if i > 0 then
		table.remove(p.sats, i)
	end
end

-- 가장 센 위성들로 칸을 채운다
function Sats.equipBest(player: Player, p: Profile)
	local list = table.clone(p.sats)
	table.sort(list, function(a, b)
		return Config.satMult(a.id, a.gold) > Config.satMult(b.id, b.gold)
	end)
	p.equipped = {}
	for i = 1, math.min(#list, Calc.slots(player, p)) do
		table.insert(p.equipped, list[i].uid)
	end
end

function Sats.roll(player: Player, p: Profile, cap: any): any
	local luck = (1 + 0.15 * (p.bb.luck or 0)) * (Calc.hasPass(player, "luck") and 2 or 1)
	local total = 0
	local weights = {}
	for i, s in ipairs(cap.sats) do
		local w = s.chance * (s.rarity >= 4 and luck or 1)
		weights[i] = w
		total += w
	end
	local x = math.random() * total
	for i, s in ipairs(cap.sats) do
		x -= weights[i]
		if x <= 0 then
			return s
		end
	end
	return cap.sats[1]
end

function Sats.hatch(player: Player, capId: any, wantTriple: any)
	local p = profiles[player]
	local cap = type(capId) == "string" and Config.CAPSULE_BY_ID[capId]
	if not cap then
		return
	end
	if not Calc.worldOpen(p, cap.world) then
		toast(player, "🔒 " .. cap.name .. "은(는) 세계 2가 열리면 깰 수 있어요")
		return
	end
	local count = 1
	if wantTriple == true then
		if not Calc.hasPass(player, "triple") then
			toast(player, "🥚 3개 부화는 💎 상점의 게임패스예요")
			return
		end
		count = 3
	end
	if p.mass < cap.cost * count then
		toast(player, "질량이 부족해요 (필요 💠" .. Config.formatNumber(cap.cost * count) .. ")")
		return
	end
	if #p.sats + count > Config.SAT_INVENTORY then
		toast(player, string.format("위성 가방이 가득 찼어요 (%d개). 🛰 위성 창에서 정리해 주세요", Config.SAT_INVENTORY))
		return
	end
	p.mass -= cap.cost * count
	local results = {}
	for _ = 1, count do
		local def = Sats.roll(player, p, cap)
		local s = Sats.add(p, def.id, false)
		p.hatched += 1
		-- 빈 칸이 있으면 바로 데리고 다닌다
		if #p.equipped < Calc.slots(player, p) then
			table.insert(p.equipped, s.uid)
		end
		table.insert(results, def.id)
	end
	states[player].dirty = true
	applyHole(player)
	Push:FireClient(player, "hatched", { capsule = cap.id, results = results })
	pushState(player)
end

function Sats.action(player: Player, action: string, arg: any)
	local p = profiles[player]
	if action == "satEquip" then
		local uid = tonumber(arg) or 0
		local s = Calc.findSat(p, uid)
		if not s then
			return
		end
		if table.find(p.equipped, uid) then
			Sats.unequip(p, uid)
		elseif #p.equipped >= Calc.slots(player, p) then
			toast(player, string.format("위성 칸이 가득 찼어요 (%d칸)", Calc.slots(player, p)))
			return
		else
			table.insert(p.equipped, uid)
		end
	elseif action == "satBest" then
		Sats.equipBest(player, p)
	elseif action == "satDelete" then
		local uid = tonumber(arg) or 0
		local s = Calc.findSat(p, uid)
		if not s then
			return
		end
		if Config.SAT_BY_ID[s.id].rarity >= 6 then
			toast(player, "비밀 위성은 버릴 수 없어요")
			return
		end
		Sats.remove(p, uid)
	elseif action == "satGold" then
		-- 같은 위성(황금 아닌 것) 5개를 황금 1개로
		local id = type(arg) == "string" and arg or ""
		local same = {}
		for _, s in ipairs(p.sats) do
			if s.id == id and not s.gold then
				table.insert(same, s.uid)
			end
		end
		if #same < Config.GOLD_COUNT then
			toast(player, string.format("같은 위성이 %d개 있어야 황금으로 만들 수 있어요", Config.GOLD_COUNT))
			return
		end
		local wasEquipped = false
		for i = 1, Config.GOLD_COUNT do
			if table.find(p.equipped, same[i]) then
				wasEquipped = true
			end
			Sats.remove(p, same[i])
		end
		local g = Sats.add(p, id, true)
		if wasEquipped or #p.equipped < Calc.slots(player, p) then
			table.insert(p.equipped, g.uid)
		end
		Push:FireClient(player, "gold", { id = id })
	else
		return
	end
	states[player].dirty = true
	applyHole(player)
	pushState(player)
end

------------------------------------------------------------------------
-- 로벅스 상점 연결
------------------------------------------------------------------------
local function grantPass(player: Player, key: string)
	local p, st = profiles[player], states[player]
	if not p or not st then
		return
	end
	if st.tester then
		st.passes[key] = true
	else
		p.passes[key] = true
		st.dirty = true
	end
	if key == "petpack" and not p.packGiven then
		p.packGiven = true
		for _, s in ipairs(Config.ExclusiveSats) do
			Sats.add(p, s.id, false)
		end
		Sats.equipBest(player, p)
		p.skin = "godeye"
		Push:FireClient(player, "unlock", { kind = "pack", name = Config.PASS_BY_KEY.petpack.name })
	elseif key == "vip" then
		p.skin = "vip"
	end
	applyHole(player)
	pushState(player)
end

local function grantProduct(player: Player, key: string, receiptId: string): boolean
	local p, st = profiles[player], states[player]
	if not p or not st then
		return false
	end
	local now = os.time()
	if key == "boost30" then
		p.boostUntil = math.max(now, p.boostUntil) + 1800
	elseif key == "respawn30" then
		p.respawnUntil = math.max(now, p.respawnUntil) + 1800
	elseif key == "massS" or key == "massL" then
		local n = key == "massS" and 3 or 10
		local u = Config.UPGRADE_BY_ID.size
		local amount = 0
		for i = 0, n - 1 do
			amount += Config.upgradeCost("size", math.min(u.maxLevel - 1, p.size + i))
		end
		p.mass += amount
		p.total += amount
	elseif key == "dm10" then
		p.dm += 10
	else
		return false
	end
	table.insert(p.receipts, receiptId)
	while #p.receipts > 50 do
		table.remove(p.receipts, 1)
	end
	st.dirty = true
	applyHole(player)
	pushState(player)
	return true
end

Store.init({
	isTester = function(player: Player): boolean
		local st = states[player]
		return st ~= nil and st.tester
	end,
	grantPass = grantPass,
	grantProduct = grantProduct,
	hasReceipt = function(player: Player, id: string): boolean
		local p = profiles[player]
		return p ~= nil and table.find(p.receipts, id) ~= nil
	end,
	toast = toast,
	save = function(player: Player)
		task.spawn(saveProfile, player)
	end,
})

------------------------------------------------------------------------
-- 요청 처리
------------------------------------------------------------------------
local function testAction(player: Player, p: Profile, action: string, arg: any)
	if action == "testMass" then
		local amount = math.clamp(tonumber(arg) or 0, 0, 1e30)
		p.mass += amount
		p.total += amount
	elseif action == "testSize" then
		p.size = math.clamp(math.floor(tonumber(arg) or 0), 0, Config.UPGRADE_BY_ID.size.maxLevel)
	elseif action == "testMaxAll" then
		p.size = Config.UPGRADE_BY_ID.size.maxLevel
		p.pull = Config.UPGRADE_BY_ID.pull.maxLevel
		p.mult = Config.UPGRADE_BY_ID.mult.maxLevel
	elseif action == "testDM" then
		p.dm += 50
	elseif action == "testBigbang" then
		p.bigbang += 1
	elseif action == "testStar" then
		local st = states[player]
		st.nextStar = 0
		st.starPos = nil
	elseif action == "testReset" then
		local fresh = defaultProfile()
		profiles[player] = fresh
		states[player].passes = {}
	else
		return
	end
	applyHole(player)
	pushState(player)
end

Request.OnServerEvent:Connect(function(player: Player, action: any, arg: any, arg2: any)
	local p, st = profiles[player], states[player]
	if not p or not st or type(action) ~= "string" then
		return
	end
	local now = os.clock()
	if now - st.reqWindow > 1 then
		st.reqWindow = now
		st.reqCount = 0
	end
	st.reqCount += 1
	if st.reqCount > 30 then
		return
	end
	if action == "upgrade" then
		Actions.buyUpgrade(player, arg, arg2)
	elseif action == "auto" then
		p.auto = arg == true
		st.dirty = true
		toast(player, p.auto and "🤖 자동 업그레이드 켬" or "자동 업그레이드 끔")
		pushState(player)
	elseif action == "bigbang" then
		Actions.bigbang(player)
	elseif action == "teleport" then
		Actions.teleport(player, arg)
	elseif action == "world" then
		local w = math.floor(tonumber(arg) or 0)
		if not Config.Worlds[w] then
			return
		end
		if not Calc.worldOpen(p, w) then
			toast(player, string.format("🔒 세계 %d은(는) 빅뱅 %d번 하면 열려요", w, Config.Worlds[w].needBigbang))
			return
		end
		moveTo(player, spawnPos(w))
		Push:FireClient(player, "world", w)
	elseif action == "bbshop" then
		Actions.bbShop(player, arg)
	elseif action == "skin" then
		Actions.skin(player, arg)
	elseif action == "hatch" then
		Sats.hatch(player, arg, arg2)
	elseif string.sub(action, 1, 3) == "sat" then
		Sats.action(player, action, arg)
	elseif action == "buyPass" then
		Store.buyPass(player, arg)
	elseif action == "buyProduct" then
		Store.buyProduct(player, arg)
	elseif action == "refresh" then
		-- 부스트 시간이 끝났을 때 화면이 배율을 다시 받아 간다
		pushState(player)
	elseif action == "hello" then
		pushState(player)
		if st.tester then
			toast(player, "🧪 테스트 계정이에요. 테스트 창에서 질량을 받을 수 있고, 기록은 저장하지 않아요")
		elseif not st.canSave then
			toast(player, "저장이 꺼져 있어요. 이번 기록은 저장되지 않아요")
		end
	elseif string.sub(action, 1, 4) == "test" and st.tester then
		testAction(player, p, action, arg)
	end
end)

------------------------------------------------------------------------
-- 입장과 퇴장
------------------------------------------------------------------------
local function onCharacterAdded(player: Player, char: Model)
	task.spawn(function()
		char:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.2)
		if player.Character ~= char then
			return
		end
		hideBody(char)
		char.DescendantAdded:Connect(function(d)
			-- 늦게 붙는 장신구도 숨긴다
			if d:IsA("BasePart") then
				d.Transparency = 1
			elseif d:IsA("Decal") then
				d.Transparency = 1
			end
		end)
		applyHole(player)
	end)
end

local function onPlayerAdded(player: Player)
	local st: State = {
		canSave = false,
		dirty = false,
		tester = false,
		reqWindow = 0,
		reqCount = 0,
		zone = 1,
		passes = {},
		starPos = nil,
		starExpire = 0,
		nextStar = os.clock() + 15,
		starUntil = 0,
		portalAt = 0,
		lockToastAt = 0,
	}
	states[player] = st
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local massValue = Instance.new("StringValue")
	massValue.Name = "질량"
	massValue.Value = "0"
	massValue.Parent = ls
	local sizeValue = Instance.new("StringValue")
	sizeValue.Name = "크기"
	sizeValue.Value = Config.formatSize(Config.radius(0))
	sizeValue.Parent = ls
	local bbValue = Instance.new("IntValue")
	bbValue.Name = "빅뱅"
	bbValue.Parent = ls
	ls.Parent = player

	local profile, ok
	if isTester(player) then
		profile, ok = defaultProfile(), false
		st.tester = true
	else
		profile, ok = loadProfile(player)
		st.passes = Store.ownedPasses(player)
	end
	if not player.Parent then
		return
	end
	profiles[player] = profile
	st.canSave = ok
	-- 들어오기 전에 산 우주 위성 패키지도 한 번은 챙겨 준다
	if Calc.hasPass(player, "petpack") and not profile.packGiven then
		grantPass(player, "petpack")
	end
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
	pushState(player)
	updateLeaderstats(player)
end

local function onPlayerRemoving(player: Player)
	saveProfile(player)
	profiles[player] = nil
	states[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

task.spawn(function()
	while true do
		task.wait(SAVE_INTERVAL)
		for player, st in pairs(states) do
			if st.dirty then
				task.spawn(saveProfile, player)
			end
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in pairs(profiles) do
		pending += 1
		task.spawn(function()
			saveProfile(player)
			pending -= 1
		end)
	end
	local waited = 0
	while pending > 0 and waited < 25 do
		task.wait(0.5)
		waited += 0.5
	end
end)
