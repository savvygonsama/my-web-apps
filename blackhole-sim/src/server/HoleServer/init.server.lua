-- HoleServer (Script, ServerScriptService)
-- 삼키기 판정, 먹어서 커지기, 질량, 업그레이드 9종, 빅뱅과 빅뱅 상점, 위성(펫), 스킨과 스킨 능력,
-- 황금 물체, 연속 흡수 보너스, 퀘스트, 매일 보상, 로비, 순위판, 로벅스 상점, 부스트, 별똥별, 저장.
-- 캐릭터는 사람 모양이 아니라 보이지 않는 공 하나다 (걷는 모션 없음, 죽지 않음).
-- 중요한 계산은 모두 서버가 한다.
--   World  조명, 로비, 세계 2개의 구역, 문, 물체 배치
--   Store  게임패스와 개발자 상품 결제

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local World = require(script:WaitForChild("World"))
local Store = require(script:WaitForChild("Store"))

-- 사람 캐릭터는 만들지 않는다. 블랙홀 캐릭터는 아래 spawnHole이 직접 만든다
Players.CharacterAutoLoads = false

local DATASTORE_NAME = "BlackHole_v1"
local SAVE_INTERVAL = 90
local TICK = 0.1
local LOBBY_SPEED = 40

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
local lobby = World.buildLobby()
for _, portal in ipairs(lobby.portals) do
	table.insert(portals, portal)
end
local objects, objectFolder = World.placeObjects()
local holding = Instance.new("Folder")
holding.Name = "EatenObjects"
holding.Parent = ServerStorage

-- 구역별로 나눠 둔다 (가까운 구역만 살펴보면 된다). 처음부터 몇 개는 황금 물체
local byZone: { [number]: { World.ObjectRec } } = {}
for _, rec in ipairs(objects) do
	byZone[rec.zone] = byZone[rec.zone] or {}
	table.insert(byZone[rec.zone], rec)
	if math.random() < Config.GOLDEN_CHANCE then
		rec.golden = true
		rec.model:SetAttribute("Golden", true)
	end
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
type Quest = { kind: string, goal: number, progress: number }

type Profile = {
	mass: number,
	total: number, -- 지금까지 삼킨 질량 (빅뱅해도 남는다)
	eaten: number,
	radius: number, -- 지금 반지름 (먹어서 커진다)
	up: { [string]: number }, -- 업그레이드 9종 레벨
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
	quests: { Quest },
	questsDone: number,
	dailyAt: number,
	streak: number,
}

local function defaultProfile(): Profile
	local bb = {}
	for _, b in ipairs(Config.BigbangShop) do
		bb[b.id] = 0
	end
	local up = {}
	for _, u in ipairs(Config.Upgrades) do
		up[u.id] = 0
	end
	return {
		mass = 0,
		total = 0,
		eaten = 0,
		radius = Config.START_RADIUS,
		up = up,
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
		quests = {},
		questsDone = 0,
		dailyAt = 0,
		streak = 0,
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
	p.bigbang = math.floor(num(data.bigbang, 1000))
	local up = type(data.up) == "table" and data.up or data -- 예전 기록은 grow/pull/mult가 바깥에 있었다
	for _, u in ipairs(Config.Upgrades) do
		p.up[u.id] = math.floor(num(up[u.id], u.maxLevel))
	end
	p.dm = math.floor(num(data.dm, 1e9))
	if type(data.bb) == "table" then
		for _, b in ipairs(Config.BigbangShop) do
			p.bb[b.id] = math.floor(num(data.bb[b.id], b.maxLevel))
		end
	end
	local maxR = Config.maxRadius(p.bigbang, p.up.maxsize)
	p.radius = math.clamp(num(data.radius, maxR), Config.START_RADIUS, maxR)
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
	if type(data.quests) == "table" then
		for _, q in ipairs(data.quests) do
			if type(q) == "table" and type(q.kind) == "string" and Config.QUEST_BY_KIND[q.kind] and type(q.goal) == "number" and q.goal > 0 then
				table.insert(p.quests, { kind = q.kind, goal = math.floor(q.goal), progress = math.floor(num(q.progress, q.goal)) })
			end
			if #p.quests >= 3 then
				break
			end
		end
	end
	p.questsDone = math.floor(num(data.questsDone, 1e9))
	p.dailyAt = num(data.dailyAt, 1e11)
	p.streak = math.floor(num(data.streak, 1e6))
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
	world: number,
	inLobby: boolean,
	passes: { [string]: boolean }, -- 들어올 때 확인한 게임패스
	starPos: Vector3?,
	starExpire: number,
	nextStar: number,
	starUntil: number,
	portalAt: number,
	lockToastAt: number,
	combo: number,
	lastEat: number,
	activeUntil: number, -- 액티브 스킬이 끝나는 시각 (os.clock)
	activeOn: boolean,
	cdUntil: number,
	burst: number,
	unstuckAt: number?,
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
local NO_ABILITY = { kind = "passive", name = "", desc = "" }

function Calc.hasPass(player: Player, key: string): boolean
	local p, st = profiles[player], states[player]
	return (p and p.passes[key] == true) or (st and st.passes[key] == true) or false
end

function Calc.maxRadius(p: Profile): number
	return Config.maxRadius(p.bigbang, p.up.maxsize)
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

-- 지금 스킨의 고유 능력
function Calc.ability(p: Profile): any
	local skin = Config.SKIN_BY_ID[p.skin]
	return skin and skin.ability or NO_ABILITY
end

-- 장착한 위성 배율 합: 1 + Σ(배율 - 1), 신의 눈 스킨이면 +20%
function Calc.satMult(p: Profile): number
	local m = 1
	for _, uid in ipairs(p.equipped) do
		local s = Calc.findSat(p, uid)
		if s then
			m += Config.satMult(s.id, s.gold) - 1
		end
	end
	return m * (1 + (Calc.ability(p).sats or 0))
end

-- 액티브 스킬이 켜져 있는지
function Calc.active(st: State?): boolean
	return st ~= nil and st.activeOn and os.clock() < st.activeUntil
end

-- 스킨 능력에 따른 흡입 범위 배수
function Calc.pullExtra(p: Profile, st: State?): number
	local ab = Calc.ability(p)
	local m = 1
	if ab.kind == "passive" and ab.pull then
		m *= 1 + ab.pull
	elseif ab.kind == "active" and ab.pull and Calc.active(st) then
		m *= ab.pull
	end
	return m
end

function Calc.speedExtra(p: Profile, st: State?): number
	local ab = Calc.ability(p)
	if ab.kind == "active" and ab.speed and Calc.active(st) then
		return ab.speed
	end
	return 1
end

-- 스킨 능력 질량·성장 보너스 (세계 2 전용 보너스 포함)
function Calc.skinBonus(p: Profile, st: State?): (number, number)
	local ab = Calc.ability(p)
	local mass, grow = ab.mass or 0, ab.grow or 0
	if ab.world2 and st and st.world == 2 and not st.inLobby then
		mass += 1
		grow += 0.3
	end
	return mass, grow
end

function Calc.comboBonus(p: Profile, st: State?): number
	if not st then
		return 0
	end
	local s = st :: State
	if os.clock() - s.lastEat > Config.COMBO_WINDOW then
		return 0
	end
	return Config.comboBonus(s.combo, p.up.combo)
end

function Calc.totalMult(player: Player, p: Profile): number
	local st = states[player]
	local skinMass = Calc.skinBonus(p, st)
	return Config.totalMult({
		mult = p.up.mult,
		bigbang = p.bigbang,
		bbMass = p.bb.mass,
		sats = Calc.satMult(p),
		vip = Calc.hasPass(player, "vip"),
		mass2 = Calc.hasPass(player, "mass2"),
		boost = p.boostUntil > os.time(),
		star = st ~= nil and st.starUntil > os.clock(),
		skin = skinMass,
		combo = Calc.comboBonus(p, st),
	})
end

function Calc.growMult(player: Player, p: Profile): number
	local st = states[player]
	local _, skinGrow = Calc.skinBonus(p, st)
	return Config.growMult({ grow = p.up.grow, bigbang = p.bigbang, star = st ~= nil and st.starUntil > os.clock(), skin = skinGrow })
end

function Calc.respawnFactor(player: Player, p: Profile): number
	return Config.respawnFactor(p.bb.respawn, Calc.hasPass(player, "vip"), p.respawnUntil > os.time(), p.up.respawn, Calc.ability(p).respawn)
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
	local r = p.radius
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
	local clock = os.clock()
	Push:FireClient(player, "state", {
		mass = p.mass,
		total = p.total,
		eaten = p.eaten,
		radius = r,
		maxRadius = Calc.maxRadius(p),
		up = p.up,
		bigbang = p.bigbang,
		dm = p.dm,
		bb = p.bb,
		pullRange = Config.pullRange(r, p.up.pull, p.bb.pull, Calc.pullExtra(p, st)),
		totalMult = Calc.totalMult(player, p),
		growMult = Calc.growMult(player, p),
		satMult = Calc.satMult(p),
		sats = p.sats,
		equipped = p.equipped,
		slots = Calc.slots(player, p),
		skins = skins,
		skin = p.skin,
		passes = passes,
		boostLeft = math.max(0, p.boostUntil - now),
		respawnLeft = math.max(0, p.respawnUntil - now),
		starLeft = math.max(0, st.starUntil - clock),
		activeLeft = Calc.active(st) and math.max(0, st.activeUntil - clock) or 0,
		cdLeft = math.max(0, st.cdUntil - clock),
		auto = p.auto,
		hatched = p.hatched,
		quests = p.quests,
		questsDone = p.questsDone,
		dailyLeft = math.max(0, p.dailyAt + Config.DAILY_HOURS * 3600 - now),
		streak = p.streak,
		inLobby = st.inLobby,
		world = st.world,
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
		sizeValue.Value = Config.formatSize(p.radius)
	end
	if bbValue and bbValue:IsA("IntValue") then
		bbValue.Value = p.bigbang
	end
end

-- 블랙홀 모양은 모든 화면이 직접 그린다 (크기, 스킨, 위성만 속성으로 알려 준다)
local function applyHole(player: Player)
	local p, st = profiles[player], states[player]
	local char = player.Character
	if not p or not st or not char then
		return
	end
	local r = p.radius
	local skin = Config.SKIN_BY_ID[p.skin]
	if not skin or not Calc.skinUnlocked(player, p, skin) then
		skin = Config.Skins[1]
		p.skin = skin.id
	end
	local vip = Calc.hasPass(player, "vip")
	player:SetAttribute("VIP", vip)
	char:SetAttribute("HoleR", r)
	char:SetAttribute("HoleSkin", skin.index)
	char:SetAttribute("SkillOn", Calc.active(st))
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
		if st.inLobby then
			hum.WalkSpeed = LOBBY_SPEED
		else
			hum.WalkSpeed = Config.walkSpeed(r, p.bb.speed, Calc.hasPass(player, "speed2"), p.up.speed, Calc.speedExtra(p, st))
		end
	end
	local head = char:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local tag = head:FindFirstChild("HoleTag")
		if not tag then
			local gui = Instance.new("BillboardGui")
			gui.Name = "HoleTag"
			gui.Size = UDim2.new(0, 260, 0, 50)
			gui.AlwaysOnTop = true
			gui.LightInfluence = 0
			gui.MaxDistance = 5000
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
		local shown = st.inLobby and math.min(r, 8) or r
		gui.StudsOffset = Vector3.new(0, 4 + shown * 0.25, 0)
		local label = gui:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.Text = string.format("%s%s · ⚫%s", vip and "👑 " or "", player.DisplayName, Config.formatSize(r))
			label.TextColor3 = vip and Color3.fromRGB(255, 215, 80) or skin.b
		end
	end
	updateLeaderstats(player)
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
-- 퀘스트: 늘 3개. 끝내면 바로 보상을 주고 새 퀘스트를 건다
------------------------------------------------------------------------
local Quests = {}

function Quests.fill(p: Profile)
	while #p.quests < 3 do
		local active = {}
		for _, q in ipairs(p.quests) do
			active[q.kind] = true
		end
		local avail = {}
		for _, def in ipairs(Config.Quests) do
			if not active[def.kind] then
				table.insert(avail, def)
			end
		end
		if #avail == 0 then
			break
		end
		local def = avail[math.random(1, #avail)]
		local goal = math.max(1, math.floor(def.base * def.grow ^ math.min(p.questsDone, 40) + 0.5))
		table.insert(p.quests, { kind = def.kind, goal = goal, progress = 0 })
	end
end

-- 진행도 올리기. isMax면 지금 값과 비교해 더 큰 쪽 (연속 흡수처럼)
function Quests.add(player: Player, p: Profile, kind: string, amount: number, isMax: boolean?)
	if amount <= 0 then
		return
	end
	local done = false
	for i = #p.quests, 1, -1 do
		local q = p.quests[i]
		if q.kind == kind then
			if isMax then
				q.progress = math.max(q.progress, amount)
			else
				q.progress += amount
			end
			if q.progress >= q.goal then
				local def = Config.QUEST_BY_KIND[q.kind]
				local text = string.format(def.text, Config.formatNumber(q.goal))
				local reward
				if def.reward == "dm" then
					local n = 1 + p.questsDone // 6
					p.dm += n
					reward = string.format("🌑 암흑 물질 +%d", n)
				else
					local st = states[player]
					local amountMass = math.max(200, Config.biggestMass(st and st.world or 1, p.radius) * 25 * Calc.totalMult(player, p))
					p.mass += amountMass
					p.total += amountMass
					reward = "💠 +" .. Config.formatNumber(amountMass)
				end
				table.remove(p.quests, i)
				p.questsDone += 1
				done = true
				Push:FireClient(player, "quest", { text = text, reward = reward })
			end
		end
	end
	if done then
		Quests.fill(p)
		pushState(player)
	end
end

------------------------------------------------------------------------
-- 삼키기
------------------------------------------------------------------------
local function respawn(rec: World.ObjectRec)
	rec.model:SetAttribute("EatenBy", nil)
	rec.model:SetAttribute("Golden", rec.golden and true or nil)
	for part, can in pairs(rec.collide) do
		part.CanCollide = can
	end
	rec.model.Parent = objectFolder
	rec.alive = true
end

-- factor = 재생 시간 배율, goldChance = 다시 생길 때 황금일 확률 (먹은 사람의 업그레이드·스킨 기준)
local function eat(player: Player, rec: World.ObjectRec, factor: number, goldChance: number)
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
	task.delay(math.max(0.7, wait), function()
		if not rec.alive then
			rec.golden = math.random() < goldChance
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

local Actions = {}

-- 안전한 자리 찾기. 지금 자리가 괜찮으면 nil
function Actions.safeSpot(pos: Vector3): Vector3?
	if Config.inLobby(pos) then
		if pos.Y < -30 then
			return lobby.spawn
		end
		return nil
	end
	local zi = Config.zoneAt(pos)
	local zone = Config.Zones[zi]
	local wx = Config.Worlds[zone.world].x
	local z0 = Config.zoneStart(zi)
	local outX = math.abs(pos.X - wx) > zone.width / 2 + 5
	local list = Config.zonesOf(zone.world)
	local worldEnd = Config.zoneStart(list[#list]) + Config.Zones[list[#list]].length
	local outZ = pos.Z < -5 or pos.Z > worldEnd + 5
	-- 세계와도 로비와도 먼 곳 (아주 멀리 날아감)
	if math.abs(pos.X - wx) > 20000 then
		return lobby.spawn
	end
	if pos.Y < -30 or outX or outZ then
		local x = math.clamp(pos.X, wx - zone.width / 2 + 30, wx + zone.width / 2 - 30)
		local z = math.clamp(pos.Z, z0 + 30, z0 + zone.length - 30)
		return Vector3.new(x, 6, z)
	end
	return nil
end

-- 🆘 끼었을 때: 지금 구역 가운데 길로 옮긴다 (로비면 로비 시작 자리)
function Actions.unstuck(player: Player)
	local st = states[player]
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not st or not root or not root:IsA("BasePart") then
		return
	end
	local now = os.clock()
	if now < (st.unstuckAt or 0) then
		return
	end
	st.unstuckAt = now + 2
	local pos = root.Position
	root.AssemblyLinearVelocity = Vector3.zero
	if Config.inLobby(pos) or math.abs(pos.X - Config.LOBBY.x) < 5000 then
		moveTo(player, lobby.spawn)
	else
		local zi = Config.zoneAt(pos)
		local zone = Config.Zones[zi]
		local z0 = Config.zoneStart(zi)
		moveTo(player, Vector3.new(Config.Worlds[zone.world].x, 6, math.clamp(pos.Z, z0 + 30, z0 + zone.length - 30)))
	end
	toast(player, "🆘 빠져나왔어요!")
end

function Actions.goLobby(player: Player)
	local st = states[player]
	moveTo(player, lobby.spawn)
	if st then
		st.portalAt = os.clock() + 3
	end
	Push:FireClient(player, "world", 0)
end

function Actions.goWorld(player: Player, w: number)
	local p, st = profiles[player], states[player]
	if not p or not st or not Config.Worlds[w] then
		return
	end
	if not Calc.worldOpen(p, w) then
		toast(player, string.format("🔒 세계 %d은(는) 빅뱅 %d번 하면 열려요", w, Config.Worlds[w].needBigbang))
		return
	end
	st.world = w
	st.portalAt = os.clock() + 3
	moveTo(player, spawnPos(w))
	Push:FireClient(player, "world", w)
end

local function tickPlayer(player: Player, p: Profile, st: State)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local pos = root.Position
	local now = os.clock()

	-- 안전망: 떨어졌거나 맵 밖으로 나갔으면 가까운 안전한 곳으로 돌려보낸다
	local safe = Actions.safeSpot(pos)
	if safe then
		root.AssemblyLinearVelocity = Vector3.zero
		moveTo(player, safe)
		return
	end

	-- 로비 들어가고 나오기
	local inLobby = Config.inLobby(pos)
	if inLobby ~= st.inLobby then
		st.inLobby = inLobby
		applyHole(player)
		pushState(player)
	end
	-- 액티브 스킬이 끝났으면 속도·범위를 되돌린다
	if st.activeOn and now >= st.activeUntil then
		st.activeOn = false
		applyHole(player)
		pushState(player)
	end

	-- 문 (로비 ↔ 세계)
	for _, portal in ipairs(portals) do
		if flatDist(portal.pos, pos) < 12 and now > st.portalAt then
			st.portalAt = now + 3
			if portal.to == 0 then
				Actions.goLobby(player)
			elseif Calc.worldOpen(p, portal.to) then
				Actions.goWorld(player, portal.to)
			elseif now > st.lockToastAt then
				st.lockToastAt = now + 4
				toast(player, string.format("🔒 세계 %d은(는) 빅뱅 %d번 하면 열려요", portal.to, Config.Worlds[portal.to].needBigbang))
			end
		end
	end
	if inLobby then
		return
	end

	local r = p.radius
	local ab = Calc.ability(p)
	local reach = r + Config.pullRange(r, p.up.pull, p.bb.pull, Calc.pullExtra(p, st))
	local zone = Config.zoneAt(pos)
	local world = Config.Zones[zone].world
	st.world = world
	if zone ~= st.zone then
		st.zone = zone
		Push:FireClient(player, "zone", zone)
	end

	-- 별똥별
	if st.starPos then
		local spot = st.starPos :: Vector3
		if flatDist(spot, pos) <= reach + 3 then
			st.starPos = nil
			local boost = Config.STAR_BOOST * (ab.star and 1.5 or 1)
			st.starUntil = math.max(now, st.starUntil) + boost
			st.nextStar = now + Config.starInterval(p.up.star, ab.star) * (0.8 + math.random() * 0.5)
			Push:FireClient(player, "starGot", { pos = spot, left = st.starUntil - now })
			Quests.add(player, p, "star", 1)
			pushState(player)
		elseif now > st.starExpire then
			st.starPos = nil
			st.nextStar = now + Config.starInterval(p.up.star, ab.star) * 0.5
		end
	elseif now > st.nextStar then
		dropStar(player, st, pos, r)
	end

	-- 한꺼번에 흡수 스킬
	local burst = st.burst
	if burst > 0 then
		st.burst = 0
		reach *= burst
	end

	local mult = Calc.totalMult(player, p)
	local gm = Calc.growMult(player, p)
	local maxR = Calc.maxRadius(p)
	local factor = Calc.respawnFactor(player, p)
	local goldChance = Config.goldenChance(p.up.golden, ab.golden)
	local reachable = Config.maxZone(world, r)
	local limit = burst > 0 and 250 or 40
	local newR = r
	local eatenList = {}
	local gained = 0
	local goldenCount, bigCount = 0, 0
	local ateSun = false
	for zi = math.max(1, zone - 1), math.min(#Config.Zones, zone + 1) do
		if Config.Zones[zi].world == world then
			for _, rec in ipairs(byZone[zi] or {}) do
				if rec.alive and rec.zone <= reachable and rec.def.size <= r and flatDist(rec.pos, pos) <= reach + rec.def.size * 0.5 then
					local golden = rec.golden
					eat(player, rec, factor, goldChance)
					local m = rec.def.mass * mult * (golden and Config.GOLDEN_MASS or 1)
					gained += m
					newR = Config.grow(newR, rec.def.size, gm * (golden and Config.GOLDEN_GROW or 1), maxR)
					table.insert(eatenList, { pos = rec.pos, mass = m, size = rec.def.size, name = rec.def.name, golden = golden })
					if golden then
						goldenCount += 1
					end
					if rec.def.size >= r * 0.5 then
						bigCount += 1
					end
					if rec.def.id == "candysun" then
						ateSun = true
					end
					if #eatenList >= limit then
						break
					end
				end
			end
		end
	end
	if #eatenList > 0 then
		if now - st.lastEat <= Config.COMBO_WINDOW then
			st.combo += #eatenList
		else
			st.combo = #eatenList
		end
		st.lastEat = now
		p.mass += gained
		p.total += gained
		p.eaten += #eatenList
		st.dirty = true
		if newR > p.radius then
			p.radius = newR
			applyHole(player)
		end
		Push:FireClient(player, "eat", {
			list = eatenList,
			gained = gained,
			mass = p.mass,
			radius = p.radius,
			pullRange = Config.pullRange(p.radius, p.up.pull, p.bb.pull, Calc.pullExtra(p, st)),
			combo = st.combo,
			comboBonus = Config.comboBonus(st.combo, p.up.combo),
			burst = burst > 0,
		})
		updateLeaderstats(player)
		Quests.add(player, p, "eat", #eatenList)
		Quests.add(player, p, "golden", goldenCount)
		Quests.add(player, p, "big", bigCount)
		Quests.add(player, p, "combo", st.combo, true)
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
-- 업그레이드, 자동 업그레이드, 빅뱅, 이동, 스킬, 매일 보상
------------------------------------------------------------------------
-- 업그레이드 하나를 살 수 있는 만큼 산다
function Actions.buyUpgrade(player: Player, id: any, many: any): number
	local p = profiles[player]
	local u = type(id) == "string" and Config.UPGRADE_BY_ID[id]
	if not u then
		return 0
	end
	local bought = 0
	local limit = many == true and 300 or 1
	while bought < limit do
		local level = p.up[u.id]
		if level >= u.maxLevel then
			break
		end
		local cost = Config.upgradeCost(u.id, level)
		if p.mass < cost then
			break
		end
		p.mass -= cost
		p.up[u.id] = level + 1
		bought += 1
	end
	if bought == 0 then
		local level = p.up[u.id]
		if level >= u.maxLevel then
			toast(player, u.name .. "은(는) 이미 최대예요")
		else
			toast(player, "질량이 부족해요 (필요 💠" .. Config.formatNumber(Config.upgradeCost(u.id, level)) .. ")")
		end
		return 0
	end
	states[player].dirty = true
	applyHole(player)
	Push:FireClient(player, "upgraded", { id = u.id, count = bought, level = p.up[u.id] })
	pushState(player)
	return bought
end

-- 자동 업그레이드: 가장 싼 것부터 계속 산다 (성장력·질량 배율을 조금 더 우선)
function Actions.autoUpgrade(player: Player, p: Profile)
	local boughtAny = false
	for _ = 1, 80 do
		local best, bestCost = nil, math.huge
		for _, u in ipairs(Config.Upgrades) do
			local level = p.up[u.id]
			if level < u.maxLevel then
				local weight = (u.id == "grow" or u.id == "mult") and 0.7 or 1
				local cost = Config.upgradeCost(u.id, level) * weight
				if cost < bestCost then
					best, bestCost = u, cost
				end
			end
		end
		if not best then
			break
		end
		local cost = Config.upgradeCost(best.id, p.up[best.id])
		if p.mass < cost then
			break
		end
		p.mass -= cost
		p.up[best.id] += 1
		boughtAny = true
	end
	if boughtAny then
		states[player].dirty = true
		applyHole(player)
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
	local p, st = profiles[player], states[player]
	if p.radius < Config.BIGBANG_RADIUS then
		toast(player, string.format("크기 ⚫%d 이상이어야 빅뱅할 수 있어요 (지금 ⚫%s)", Config.BIGBANG_RADIUS, Config.formatSize(p.radius)))
		return
	end
	local reward = Config.darkMatterReward(p.radius, p.bigbang, p.bb.dm)
	local before = {}
	for _, skin in ipairs(Config.Skins) do
		before[skin.id] = Calc.skinUnlocked(player, p, skin)
	end
	p.bigbang += 1
	p.dm += reward
	p.mass = p.mass * 0.05 * (p.bb.keep or 0)
	p.radius = Config.startRadius(p.bb.start or 0)
	for _, u in ipairs(Config.Upgrades) do
		p.up[u.id] = 0
	end
	st.dirty = true
	local newSkins = {}
	for _, skin in ipairs(Config.Skins) do
		if not before[skin.id] and Calc.skinUnlocked(player, p, skin) then
			table.insert(newSkins, skin.name)
			p.skin = skin.id
		end
	end
	if not st.inLobby then
		moveTo(player, spawnPos(st.world))
	end
	applyHole(player)
	Push:FireClient(player, "bigbang", {
		count = p.bigbang,
		dm = reward,
		skins = newSkins,
		world2 = p.bigbang == Config.Worlds[2].needBigbang,
		maxRadius = Calc.maxRadius(p),
	})
	pushState(player)
end

function Actions.teleport(player: Player, zoneArg: any)
	local p, st = profiles[player], states[player]
	local zi = math.floor(tonumber(zoneArg) or 0)
	local zone = Config.Zones[zi]
	if not zone then
		return
	end
	if not Calc.worldOpen(p, zone.world) then
		toast(player, string.format("🔒 세계 %d은(는) 빅뱅 %d번 하면 열려요", zone.world, Config.Worlds[zone.world].needBigbang))
		return
	end
	local r = p.radius
	if zi > Config.maxZone(zone.world, r) then
		toast(player, string.format("크기 %d 이상이어야 갈 수 있어요", zone.need))
		return
	end
	local z0 = Config.zoneStart(zi)
	local z = math.min(z0 + 20 + r, z0 + zone.length / 2)
	st.world = zone.world
	st.portalAt = os.clock() + 3
	moveTo(player, Vector3.new(Config.Worlds[zone.world].x, 5 + math.min(r, 50) * 0.2, z))
end

function Actions.skill(player: Player)
	local p, st = profiles[player], states[player]
	local ab = Calc.ability(p)
	if ab.kind ~= "active" then
		toast(player, string.format("%s: 늘 켜져 있는 능력이에요 (%s)", ab.name, ab.desc))
		return
	end
	if st.inLobby then
		toast(player, "로비에서는 스킬을 쓸 수 없어요")
		return
	end
	local now = os.clock()
	if now < st.cdUntil then
		toast(player, string.format("%s: %d초 뒤에 다시 쓸 수 있어요", ab.name, math.ceil(st.cdUntil - now)))
		return
	end
	st.cdUntil = now + ab.cd
	if (ab.dur or 0) > 0 then
		st.activeOn = true
		st.activeUntil = now + ab.dur
	end
	if ab.burst then
		st.burst = ab.burst
	end
	applyHole(player)
	Push:FireClient(player, "skill", { name = ab.name, dur = ab.dur or 0, cd = ab.cd, burst = ab.burst ~= nil })
	pushState(player)
end

function Actions.daily(player: Player)
	local p, st = profiles[player], states[player]
	if not p or not st then
		return
	end
	local now = os.time()
	local wait = p.dailyAt + Config.DAILY_HOURS * 3600 - now
	if wait > 0 then
		toast(player, "🎁 다음 보상까지 " .. Config.formatTime(wait))
		return
	end
	p.streak = (now - p.dailyAt < 48 * 3600) and p.streak + 1 or 1
	p.dailyAt = now
	local dm = 2 + math.min(p.streak, 7)
	local mass = math.max(1000, Config.biggestMass(1, math.max(p.radius, 6)) * 80 * Calc.totalMult(player, p))
	p.dm += dm
	p.mass += mass
	p.total += mass
	st.dirty = true
	Push:FireClient(player, "daily", { streak = p.streak, dm = dm, mass = mass })
	pushState(player)
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
	local p, st = profiles[player], states[player]
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
	if p.skin ~= skin.id then
		-- 스킨을 바꾸면 켜져 있던 액티브 스킬은 끝난다
		st.activeOn = false
		st.burst = 0
	end
	p.skin = skin.id
	st.dirty = true
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
	if not states[player].inLobby then
		toast(player, "🏠 캡슐은 로비의 캡슐 기계에서 깰 수 있어요")
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
		local n = key == "massS" and 30 or 120
		local amount = Config.biggestMass(st.world, p.radius) * n * Calc.totalMult(player, p)
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
	local st = states[player]
	if action == "testMass" then
		local amount = math.clamp(tonumber(arg) or 0, 0, 1e30)
		p.mass += amount
		p.total += amount
	elseif action == "testSize" then
		p.radius = math.clamp(tonumber(arg) or 0, Config.START_RADIUS, Calc.maxRadius(p))
	elseif action == "testMaxAll" then
		for _, u in ipairs(Config.Upgrades) do
			p.up[u.id] = u.maxLevel
		end
	elseif action == "testDM" then
		p.dm += 50
	elseif action == "testBigbang" then
		p.bigbang += 1
	elseif action == "testStar" then
		st.nextStar = 0
		st.starPos = nil
	elseif action == "testSkill" then
		st.cdUntil = 0
	elseif action == "testDaily" then
		p.dailyAt = 0
	elseif action == "testReset" then
		local fresh = defaultProfile()
		Quests.fill(fresh)
		profiles[player] = fresh
		st.passes = {}
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
		local w = math.floor(tonumber(arg) or -1)
		if w == 0 then
			Actions.goLobby(player)
		else
			Actions.goWorld(player, w)
		end
	elseif action == "skill" then
		Actions.skill(player)
	elseif action == "unstuck" then
		Actions.unstuck(player)
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
-- 로비 기계 (가까이 가서 E)
------------------------------------------------------------------------
for capId, pp in pairs(lobby.machines) do
	pp.Triggered:Connect(function(player: Player)
		Push:FireClient(player, "open", { page = "capsule", capsule = capId })
	end)
end
lobby.store.Triggered:Connect(function(player: Player)
	Push:FireClient(player, "open", { page = "store" })
end)
lobby.skins.Triggered:Connect(function(player: Player)
	Push:FireClient(player, "open", { page = "skins" })
end)
lobby.daily.Triggered:Connect(function(player: Player)
	Actions.daily(player)
end)

-- 순위판: 이 서버에서 모은 질량 순서
task.spawn(function()
	while true do
		local list = {}
		for player, p in pairs(profiles) do
			table.insert(list, { name = player.DisplayName, total = p.total, bigbang = p.bigbang })
		end
		table.sort(list, function(a, b)
			return a.total > b.total
		end)
		for k, row in ipairs(lobby.board) do
			local e = list[k]
			row.Text = e and string.format("%d. %s  💠%s  🌌%d", k, e.name, Config.formatNumber(e.total), e.bigbang) or ""
		end
		task.wait(10)
	end
end)

------------------------------------------------------------------------
-- 블랙홀 캐릭터: 보이지 않는 공 하나와 Humanoid뿐이다. 팔다리가 없어서 걷는 모션이 없고,
-- 죽지 않게 해 두었다. 혹시 사라지거나 죽으면 기다리지 않고 그 자리(또는 로비)에서 바로 다시 생긴다.
------------------------------------------------------------------------
local spawnHole: (Player, Vector3) -> ()
spawnHole = function(player: Player, pos: Vector3)
	if not player.Parent then
		return
	end
	local old = player.Character
	local model = Instance.new("Model")
	model.Name = player.Name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 2)
	root.Transparency = 1
	root.CastShadow = false
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.CFrame = CFrame.new(pos)
	root.Parent = model
	-- 이름표를 붙일 머리 (보이지 않음)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1, 1, 1)
	head.Transparency = 1
	head.CanCollide = false
	head.CanQuery = false
	head.Massless = true
	head.CastShadow = false
	head.CFrame = root.CFrame
	head.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = root
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = 1
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	hum.MaxHealth = 1e9
	hum.Health = 1e9
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.Parent = model
	model.PrimaryPart = root
	model.Parent = workspace
	player.Character = model
	pcall(function()
		root:SetNetworkOwner(player)
	end)
	if old and old ~= model then
		old:Destroy()
	end
	hum.Died:Connect(function()
		task.wait(0.1)
		if player.Character == model then
			local at = root.Position
			spawnHole(player, Vector3.new(at.X, 5, at.Z))
		end
	end)
	model.AncestryChanged:Connect(function()
		if not model.Parent and player.Character == model then
			task.defer(spawnHole, player, lobby.spawn)
		end
	end)
	applyHole(player)
end

local function onPlayerAdded(player: Player)
	-- 큰 물체가 카메라를 가리면 확 다가오지 않고 그 물체를 투명하게 한다
	player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	local st: State = {
		canSave = false,
		dirty = false,
		tester = false,
		reqWindow = 0,
		reqCount = 0,
		zone = 1,
		world = 1,
		inLobby = true,
		passes = {},
		starPos = nil,
		starExpire = 0,
		nextStar = os.clock() + 15,
		starUntil = 0,
		portalAt = 0,
		lockToastAt = 0,
		combo = 0,
		lastEat = 0,
		activeUntil = 0,
		activeOn = false,
		cdUntil = 0,
		burst = 0,
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
	sizeValue.Value = Config.formatSize(Config.START_RADIUS)
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
	Quests.fill(profile)
	profiles[player] = profile
	st.canSave = ok
	-- 들어오기 전에 산 우주 위성 패키지도 한 번은 챙겨 준다
	if Calc.hasPass(player, "petpack") and not profile.packGiven then
		grantPass(player, "petpack")
	end
	spawnHole(player, lobby.spawn)
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
