-- 권왕(拳王): 맨손의 강호 — 서버
-- 기록, 캐릭터, 기술 확인, 수련, 상점, 권법 배우기
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local World = require(script:WaitForChild("World"))
local Combat = require(script:WaitForChild("Combat"))
local Npc = require(script:WaitForChild("Npc"))
local Skills = require(script:WaitForChild("Skills"))

local DATASTORE_NAME = "Kwonwang_v1"
local SAVE_INTERVAL = 90

------------------------------------------------------------------------
-- 통신
------------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "KwonRemotes"
local Request = Instance.new("RemoteEvent")
Request.Name = "Request"
Request.Parent = remotes
local Push = Instance.new("RemoteEvent")
Push.Name = "Push"
Push.Parent = remotes
remotes.Parent = ReplicatedStorage

------------------------------------------------------------------------
-- 기록
------------------------------------------------------------------------
type Profile = {
	coins: number,
	stats: { [string]: number },
	styles: { [string]: boolean },
	style: string, -- "" = 아직 안 골랐다
	mastery: { [string]: { lv: number, xp: number } },
	potions: number,
	elixirUntil: number,
	kills: number,
	bosses: { [string]: number },
	pvpWins: number,
	found: { [string]: boolean }, -- 찾아낸 사부
	trials: { [string]: boolean }, -- 넘은 사부의 시험
	story: number, -- 이야기 몇째 장
	prog: number, -- 그 장의 진행
	fragments: { [string]: boolean }, -- 주운 비급 조각
	accepted: number,
	autoOn: boolean?, -- 자동 수련 켜짐 (게임패스)
	autoStat: string?, -- 자동 수련으로 올릴 능력치 ("all" = 골고루)
	gradeUp: { [string]: number }, -- 권법 승급 (깨달음) 횟수
	gates: { [string]: boolean }, -- 넘은 경지의 관문 (경지 번호)
	manuals: { [string]: number }, -- 가진 심법 (등급 번호)
	equip: { string }, -- 끼운 심법 (세 칸)
	scrolls: number, -- 심법 두루마리
	pity: number, -- 전설 이상이 안 나온 뽑기 수
	towerBest: number, -- 천층탑 최고 층
	seen: { [string]: boolean }, -- 본 장면 (컷씬)
	pvpUnlocked: boolean?, -- 한 번 쓰러진 뒤: PvP를 끌 수 있다
	pvpOff: boolean?, -- 들판 PvP 끔
	mounts: { [string]: boolean }, -- 가진 탈것
	mountSel: string, -- 고른 탈것
	skyGems: number, -- 천정 (천상계 화폐)
	skyBuffUntil: number, -- 천상 영약 (주는 피해 +15%)
	rebirth: number, -- 환생 횟수 (1.9판)
	ach: { [string]: boolean }, -- 이룬 업적
	title: string?, -- 단 칭호 (업적 id)
	counts: { [string]: number }, -- 업적용 횟수 (raid 레이드 승리, maze 미궁 완주)
	statVer: number, -- 능력치 숫자의 판 (2 = 2.0판의 작은 숫자)
}

local function defaultProfile(): Profile
	return {
		coins = 0,
		stats = { str = 0, vit = 0, agi = 0, chi = 0 },
		styles = {},
		style = "",
		mastery = {},
		potions = 2,
		elixirUntil = 0,
		kills = 0,
		bosses = {},
		pvpWins = 0,
		found = {},
		trials = {},
		story = 1,
		prog = 0,
		fragments = {},
		accepted = 1,
		gradeUp = {},
		gates = {},
		manuals = {},
		equip = {},
		scrolls = 0,
		pity = 0,
		towerBest = 0,
		seen = {},
		mounts = { horse = true },
		mountSel = "horse",
		skyGems = 0,
		skyBuffUntil = 0,
		rebirth = 0,
		ach = {},
		counts = {},
		statVer = 2,
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
	p.coins = math.floor(num(data.coins, 1e12))
	if type(data.stats) == "table" then
		-- 2.0판 전의 기록은 큰 숫자다: 같은 세기의 작은 숫자로 바꾼다 (경지는 그대로)
		local old = data.statVer ~= 2
		for _, s in ipairs(Config.Stats) do
			local v = num(data.stats[s.id], 1e13)
			p.stats[s.id] = old and Config.statToNew(v) or math.floor(v)
		end
	end
	if type(data.styles) == "table" then
		for id, v in pairs(data.styles) do
			if type(id) == "string" and Config.STYLE_BY_ID[id] and v == true then
				p.styles[id] = true
			end
		end
	end
	if type(data.style) == "string" and p.styles[data.style] then
		p.style = data.style
	end
	if type(data.mastery) == "table" then
		for id, m in pairs(data.mastery) do
			if type(id) == "string" and Config.STYLE_BY_ID[id] and type(m) == "table" then
				p.mastery[id] = { lv = math.clamp(math.floor(num(m.lv, Config.MASTERY_MAX)), 1, Config.MASTERY_MAX), xp = num(m.xp, 1e9) }
			end
		end
	end
	p.potions = math.floor(num(data.potions, 5))
	p.elixirUntil = num(data.elixirUntil, 1e11)
	p.kills = math.floor(num(data.kills, 1e9))
	if type(data.bosses) == "table" then
		for id, n in pairs(data.bosses) do
			if type(id) == "string" and Config.Bosses[id] then
				p.bosses[id] = math.floor(num(n, 1e9))
			end
		end
	end
	p.pvpWins = math.floor(num(data.pvpWins, 1e9))
	local function flags(src: any, valid: (string) -> boolean): { [string]: boolean }
		local out = {}
		if type(src) == "table" then
			for k, v in pairs(src) do
				if type(k) == "string" and v == true and valid(k) then
					out[k] = true
				end
			end
		end
		return out
	end
	p.found = flags(data.found, function(k)
		return Config.MASTERS[k] ~= nil
	end)
	p.trials = flags(data.trials, function(k)
		return Config.MASTERS[k] ~= nil
	end)
	if type(data.manuals) == "table" then
		for id, r in pairs(data.manuals) do
			if type(id) == "string" and Config.MANUAL_BY_ID[id] and type(r) == "number" then
				p.manuals[id] = math.clamp(math.floor(r), 1, #Config.MANUAL_RARITY)
			end
		end
	end
	if type(data.equip) == "table" then
		for _, id in ipairs(data.equip) do
			if type(id) == "string" and p.manuals[id] and not table.find(p.equip, id) and #p.equip < Config.MANUAL_DRAW.slots then
				table.insert(p.equip, id)
			end
		end
	end
	p.scrolls = math.floor(num(data.scrolls, 1e6))
	p.pity = math.floor(num(data.pity, Config.MANUAL_DRAW.pity))
	p.towerBest = math.floor(num(data.towerBest, 100000))
	p.seen = flags(data.seen, function(k)
		return #k < 40
	end)
	p.pvpUnlocked = data.pvpUnlocked == true or nil
	p.mounts = flags(data.mounts, function(k)
		return Config.MOUNT_BY_ID[k] ~= nil
	end)
	p.mounts.horse = true
	p.skyGems = math.floor(num(data.skyGems, 1e9))
	p.skyBuffUntil = num(data.skyBuffUntil, 4e9)
	p.mountSel = (type(data.mountSel) == "string" and p.mounts[data.mountSel]) and data.mountSel or "horse"
	p.pvpOff = (p.pvpUnlocked and data.pvpOff == true) or nil
	p.gates = flags(data.gates, function(k)
		local i = tonumber(k)
		return i ~= nil and Config.Realms[i] ~= nil
	end)
	p.fragments = flags(data.fragments, function(k)
		local i = tonumber(k)
		return i ~= nil and Config.Fragments[i] ~= nil
	end)
	if type(data.gradeUp) == "table" then
		for id, v in pairs(data.gradeUp) do
			if type(id) == "string" and Config.STYLE_BY_ID[id] and type(v) == "number" then
				p.gradeUp[id] = math.clamp(math.floor(v), 0, #Config.BREAKTHROUGH)
			end
		end
	end
	p.story = math.clamp(math.floor(num(data.story, #Config.Story)), 1, #Config.Story)
	p.prog = math.floor(num(data.prog, 1e6))
	-- 받은 이야기 (예전 기록은 지금 장을 받은 것으로 친다)
	p.accepted = type(data.accepted) == "number" and math.clamp(math.floor(num(data.accepted, #Config.Story)), 0, #Config.Story) or p.story
	p.autoOn = data.autoOn == true or nil
	p.rebirth = math.floor(num(data.rebirth, Config.REBIRTH.max))
	p.ach = flags(data.ach, function(k)
		return Config.ACH_BY_ID[k] ~= nil
	end)
	if type(data.title) == "string" and p.ach[data.title] and Config.ACH_BY_ID[data.title].title then
		p.title = data.title
	end
	if type(data.counts) == "table" then
		for _, k in ipairs({ "raid", "maze" }) do
			p.counts[k] = math.floor(num(data.counts[k], 1e9))
		end
	end
	p.autoStat = (data.autoStat == "all" or (type(data.autoStat) == "string" and Config.AUTO_TRAIN.kinds[data.autoStat] ~= nil)) and data.autoStat or nil
	return p
end

type State = {
	canSave: boolean,
	dirty: boolean,
	tester: boolean,
	reqWindow: number,
	reqCount: number,
	training: any?,
	trainAt: number,
	ringIdx: number,
	potionAt: number,
	charConn: RBXScriptConnection?,
	tpIdx: number?,
	simmaAt: number?,
	owned: { [string]: boolean }?,
	autoAt: number?,
	autoIdx: number?,
}

local profiles: { [Player]: Profile } = {}
local states: { [Player]: State } = {}

local store: DataStore? = nil
do
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if ok then
		store = ds
	end
end

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
		task.wait(attempt)
	end
	return defaultProfile(), false
end

-- 저장: 세 번까지 다시 시도한다 (실패하면 다음 자동 저장 때 또 시도)
local saving = 0
local function saveProfile(player: Player)
	local p, st = profiles[player], states[player]
	local ds = store
	if not p or not st or not st.canSave or not ds then
		return
	end
	saving += 1
	for attempt = 1, 3 do
		local ok = pcall(function()
			ds:UpdateAsync("p_" .. player.UserId, function()
				return p
			end)
		end)
		if ok then
			st.dirty = false
			break
		end
		task.wait(attempt)
	end
	saving -= 1
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

------------------------------------------------------------------------
-- 계산
------------------------------------------------------------------------
local Calc = {}

function Calc.total(p: Profile): number
	local t = 0
	for _, s in ipairs(Config.Stats) do
		t += p.stats[s.id] or 0
	end
	return t
end

-- 지금 경지: 능력치로 닿은 경지라도, 특급부터는 그 경지의 관문을 넘어야 오른다
function Calc.realm(p: Profile): (number, any)
	local idx = Config.realmOf(Calc.total(p), Config.realmCap(p.rebirth or 0))
	for i = Config.GATE.from, idx do
		if not (p.gates and p.gates[tostring(i)]) then
			idx = i - 1
			break
		end
	end
	return idx, Config.Realms[idx]
end
-- 능력치는 닿았는데 관문을 아직 못 넘은 경지 (없으면 nil)
function Calc.gateNext(p: Profile): number?
	local reach = Config.realmOf(Calc.total(p), Config.realmCap(p.rebirth or 0))
	local now = Calc.realm(p)
	if reach > now then
		return now + 1
	end
	return nil
end

-- 끼운 심법의 효과 합 { hp, dmg, def, steal, speed, chi, cd, ult }
function Calc.manualBonus(p: Profile): { [string]: number }
	local b = { hp = 0, dmg = 0, def = 0, steal = 0, speed = 0, chi = 0, cd = 0, ult = 0 }
	for _, id in ipairs(p.equip or {}) do
		local m = Config.MANUAL_BY_ID[id]
		local r = p.manuals and p.manuals[id]
		if m and r then
			b[m.stat] += Config.manualValue(id, r)
		end
	end
	b.def = math.min(b.def, 0.5)
	b.cd = math.min(b.cd, 0.4)
	return b
end

function Calc.mastery(p: Profile, styleId: string): { lv: number, xp: number }
	local m = p.mastery[styleId]
	if not m then
		m = { lv = 1, xp = 0 }
		p.mastery[styleId] = m
	end
	return m
end

function Calc.unlocked(p: Profile, slot: string): boolean
	if p.style == "" then
		return false
	end
	local need = Config.SKILL_UNLOCK[slot]
	if not need then
		return true
	end
	return Calc.mastery(p, p.style).lv >= need
end

------------------------------------------------------------------------
-- 상태 보내기와 이름표
------------------------------------------------------------------------
-- 테스트 스위치: 내공 무한·쿨 없음 (사람마다, 저장하지 않는다)
local TEST_INF: { [Player]: boolean? } = {}
-- 로벅스 상품 (아래에서 채운다)
local Premium: any

local function toast(player: Player, text: string)
	Push:FireClient(player, "toast", text)
end

-- 컷씬: 그 장면을 처음 맞을 때만 (보았다고 적어 둔다). data = { at = 비출 자리, m = 비출 모델 }
local function cutscene(player: Player, id: string, data: any?): boolean
	local p, st = profiles[player], states[player]
	if not p or not st or p.seen[id] or not Config.CUTSCENES[id] then
		return false
	end
	p.seen[id] = true
	st.dirty = true
	local d = data or {}
	d.id = id
	Push:FireClient(player, "cutscene", d)
	return true
end

------------------------------------------------------------------------
-- 1.9판: 업적. 조건을 채우면 저절로 이루어지고 보상이 들어온다 (상태를 보낼 때마다 살핀다)
------------------------------------------------------------------------
local Ach = {}
local function keyCount(t: { [any]: any }?): number
	local n = 0
	for _ in pairs(t or {}) do
		n += 1
	end
	return n
end
function Ach.value(p: Profile, a: any): number
	local k = a.kind
	if k == "kills" then
		return p.kills
	elseif k == "bossSum" then
		local n = 0
		for _, v in pairs(p.bosses) do
			n += v
		end
		return n
	elseif k == "boss" then
		return p.bosses[a.arg] or 0
	elseif k == "realm" then
		return (Calc.realm(p))
	elseif k == "rebirth" then
		return p.rebirth
	elseif k == "styles" then
		return keyCount(p.styles)
	elseif k == "transcend" then
		local n = 0
		for id in pairs(p.styles) do
			local sd = Config.STYLE_BY_ID[id]
			if sd and sd.transcend then
				n += 1
			end
		end
		return n
	elseif k == "mastery" then
		local n = 0
		for id, m in pairs(p.mastery) do
			if p.styles[id] and m.lv >= Config.MASTERY_MAX then
				n += 1
			end
		end
		return n
	elseif k == "tower" then
		return p.towerBest
	elseif k == "pvp" then
		return p.pvpWins
	elseif k == "raid" or k == "maze" then
		return p.counts[k] or 0
	elseif k == "masters" then
		return keyCount(p.found)
	elseif k == "mounts" then
		return keyCount(p.mounts)
	elseif k == "manuals" then
		return keyCount(p.manuals)
	end
	return 0
end
-- 새로 이룬 업적에 보상을 주고 알린다 (상태는 부른 쪽이 보낸다)
function Ach.check(player: Player, p: Profile)
	for _, a in ipairs(Config.ACHIEVEMENTS) do
		if not p.ach[a.id] and Ach.value(p, a) >= a.n then
			p.ach[a.id] = true
			p.coins += a.coins or 0
			p.skyGems += a.gems or 0
			p.scrolls += a.scrolls or 0
			local st = states[player]
			if st then
				st.dirty = true
			end
			Push:FireClient(player, "ach", { id = a.id })
		end
	end
end
function Ach.progress(p: Profile): { [string]: number }
	local out = {}
	for _, a in ipairs(Config.ACHIEVEMENTS) do
		out[a.id] = math.min(a.n, Ach.value(p, a))
	end
	return out
end

local function pushState(player: Player)
	local p, st = profiles[player], states[player]
	if not p or not st then
		return
	end
	Ach.check(player, p)
	local idx, realm = Calc.realm(p)
	local mastery = {}
	for id in pairs(p.styles) do
		local m = Calc.mastery(p, id)
		mastery[id] = { lv = m.lv, xp = m.xp, need = Config.masteryNeed(m.lv) }
	end
	local owned = {}
	for id in pairs(p.styles) do
		table.insert(owned, id)
	end
	Push:FireClient(player, "state", {
		coins = p.coins,
		stats = p.stats,
		total = Calc.total(p),
		realm = idx,
		realmName = realm.name,
		styles = owned,
		style = p.style,
		mastery = mastery,
		potions = p.potions,
		elixirLeft = math.max(0, p.elixirUntil - os.time()),
		kills = p.kills,
		bosses = p.bosses,
		pvpWins = p.pvpWins,
		learnCost = Config.LEARN_COST[math.min(#owned + 1, #Config.LEARN_COST)],
		training = st.training and st.training.kind or nil,
		tester = st.tester,
		canSave = st.canSave,
		found = p.found,
		trials = p.trials,
		story = p.story,
		prog = p.prog,
		fragments = p.fragments,
		accepted = p.accepted == p.story,
		premium = st.owned or {},
		gateNext = Calc.gateNext(p),
		manuals = p.manuals,
		equip = p.equip,
		scrolls = p.scrolls,
		pity = p.pity,
		towerBest = p.towerBest,
		manualCd = Calc.manualBonus(p).cd,
		seen = p.seen,
		pvpUnlocked = p.pvpUnlocked == true,
		pvpOff = p.pvpOff == true,
		mounts = p.mounts,
		mountSel = p.mountSel,
		skyGems = p.skyGems,
		skyBuffLeft = math.max(0, p.skyBuffUntil - os.time()),
		autoOn = p.autoOn == true,
		autoStat = p.autoStat or "all",
		gradeUp = p.gradeUp,
		rebirth = p.rebirth,
		realmCap = Config.realmCap(p.rebirth),
		ach = p.ach,
		achProg = Ach.progress(p),
		title = p.title,
		power = (function()
			local f = Combat.fighterOfPlayer(player)
			return f and (f :: any).power or 0
		end)(),
	})
end

local function updateTag(player: Player)
	local p = profiles[player]
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not p or not head then
		return
	end
	local _, realm = Calc.realm(p)
	local style = Config.STYLE_BY_ID[p.style]
	local gui = head:FindFirstChild("KwonTag") :: BillboardGui?
	if not gui then
		local g = Instance.new("BillboardGui")
		g.Name = "KwonTag"
		g.Size = UDim2.new(0, 300, 0, 60)
		g.StudsOffset = Vector3.new(0, 2.6, 0)
		-- 칭호 (업적): 이름 위에 작게
		local tl = Instance.new("TextLabel")
		tl.Name = "Title"
		tl.BackgroundTransparency = 1
		tl.Position = UDim2.fromScale(0, -0.42)
		tl.Size = UDim2.fromScale(1, 0.4)
		tl.Font = Enum.Font.GothamBlack
		tl.TextScaled = true
		tl.TextStrokeTransparency = 0.2
		tl.Text = ""
		tl.Parent = g
		g.AlwaysOnTop = true
		g.LightInfluence = 0
		g.MaxDistance = 120
		local top = Instance.new("TextLabel")
		top.Name = "Top"
		top.BackgroundTransparency = 1
		top.Size = UDim2.fromScale(1, 0.55)
		top.Font = Enum.Font.GothamBlack
		top.TextScaled = true
		top.TextStrokeTransparency = 0.3
		top.Parent = g
		local bottom = Instance.new("TextLabel")
		bottom.Name = "Bottom"
		bottom.BackgroundTransparency = 1
		bottom.Position = UDim2.fromScale(0, 0.55)
		bottom.Size = UDim2.fromScale(1, 0.45)
		bottom.Font = Enum.Font.GothamBold
		bottom.TextScaled = true
		bottom.TextStrokeTransparency = 0.3
		bottom.Parent = g
		g.Parent = head
		gui = g
	end
	local g = gui :: BillboardGui
	local top = g:FindFirstChild("Top") :: TextLabel
	local bottom = g:FindFirstChild("Bottom") :: TextLabel
	local rbName = p.rebirth > 0 and Config.REBIRTH.names[p.rebirth] or nil
	top.Text = string.format("[%s%s] %s", rbName and (rbName .. " · ") or "", realm.name, player.DisplayName)
	top.TextColor3 = realm.color
	local tl = g:FindFirstChild("Title") :: TextLabel?
	local ta = p.title and Config.ACH_BY_ID[p.title]
	if tl then
		tl.Text = ta and ("「" .. ta.title .. "」") or ""
		tl.TextColor3 = ta and (Config.ACH_COLOR[ta.kind] or Color3.new(1, 1, 1)) or Color3.new(1, 1, 1)
	end
	bottom.Text = style and (style.icon .. " " .. style.name) or "권법 없음"
	bottom.TextColor3 = style and style.color or Color3.fromRGB(200, 200, 200)
	char:SetAttribute("Realm", realm.name)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local rv = ls:FindFirstChild("경지")
		if rv and rv:IsA("StringValue") then
			rv.Value = realm.name
		end
		local cv = ls:FindFirstChild("은자")
		if cv and cv:IsA("StringValue") then
			cv.Value = Config.formatNumber(p.coins)
		end
	end
end

-- 능력치·권법·숙련이 바뀌면 무인 수치를 다시 맞춘다
-- 보상 계산용 내 전투력: 후반 공격력 배율은 빼고 센다 (1.8판에 공격력이 오른 만큼 보상이 부풀지 않게)
local function rewardPower(player: Player): number
	local p = profiles[player]
	local f = Combat.fighterOfPlayer(player)
	local pw = ((f :: any) and (f :: any).power) or 100
	if p then
		pw /= math.sqrt(Config.lateAtk((Calc.realm(p)))) * Config.rebirthPower(p.rebirth)
	end
	return pw
end
-- 능력치를 얻는 배율 (환생할수록 많이)
local function gainMult(p: Profile): number
	return Config.rebirthGain(p.rebirth or 0)
end

local function refreshFighter(player: Player)
	local p = profiles[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not f then
		return
	end
	local idx = Calc.realm(p)
	local m = p.style ~= "" and Calc.mastery(p, p.style).lv or 1
	f.style = p.style
	-- 경지 배율: 경지가 오를 때마다 피해·체력이 크게 오른다
	local power = Config.realmPower(idx)
	local styleDef = Config.STYLE_BY_ID[p.style]
	local grade = styleDef and Config.GRADES[Config.styleGrade(styleDef, p.gradeUp[p.style])] or 1
	local mb = Calc.manualBonus(p)
	local rb = Config.rebirthPower(p.rebirth)
	f.dmgMult = Config.statMult(p.stats.str) * (1 + 0.03 * (m - 1)) * power * grade * (1 + mb.dmg) * (p.skyBuffUntil > os.time() and 1.15 or 1) * Config.lateAtk(idx) * rb
	f.skillMult = math.sqrt(Config.statMult(p.stats.chi))
	local fm = f :: any
	fm.mDef, fm.mSteal, fm.mChi, fm.mCd, fm.mUlt = mb.def, mb.steal, mb.chi, mb.cd, mb.ult
	local oldMax = f.maxHp
	f.maxHp = math.floor(Config.maxHp(p.stats.vit) * power * (1 + mb.hp) * rb)
	f.model:SetAttribute("Rebirth", p.rebirth > 0 and p.rebirth or nil)
	-- 환생한 무인: 발밑에서 환생 빛깔의 기운이 피어오른다 (횟수만큼 짙게)
	local rootPart = f.model:FindFirstChild("HumanoidRootPart")
	local aura = rootPart and rootPart:FindFirstChild("RebirthAura")
	if rootPart and p.rebirth > 0 then
		local col = Config.REBIRTH.colors[p.rebirth] or Color3.new(1, 1, 1)
		if not aura then
			local at = Instance.new("Attachment")
			at.Name = "RebirthAura"
			at.Position = Vector3.new(0, -2.6, 0)
			local rise = Instance.new("ParticleEmitter")
			rise.Name = "Rise"
			rise.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			rise.LightEmission = 1
			rise.Lifetime = NumberRange.new(0.8, 1.4)
			rise.Speed = NumberRange.new(4, 8)
			rise.SpreadAngle = Vector2.new(12, 12)
			rise.Acceleration = Vector3.new(0, 3, 0)
			rise.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
			rise.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
			rise.Shape = Enum.ParticleEmitterShape.Disc
			rise.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			rise.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
			rise.Parent = at
			local ring = Instance.new("ParticleEmitter")
			ring.Name = "Ring"
			ring.Texture = "rbxasset://textures/particles/smoke_main.dds"
			ring.LightEmission = 0.8
			ring.Lifetime = NumberRange.new(1, 1.6)
			ring.Speed = NumberRange.new(0.5, 1)
			ring.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 2.6) })
			ring.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
			ring.Shape = Enum.ParticleEmitterShape.Disc
			ring.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			ring.Parent = at
			at.Parent = rootPart
			aura = at
		end
		local au = aura :: Attachment
		for _, e in ipairs(au:GetChildren()) do
			if e:IsA("ParticleEmitter") then
				e.Color = ColorSequence.new(col, Color3.new(1, 1, 1):Lerp(col, 0.4))
				e.Rate = (e.Name == "Rise" and 6 or 3) * p.rebirth
			end
		end
	elseif aura then
		aura:Destroy()
	end
	if oldMax > 0 then
		f.hp = math.min(f.maxHp, f.hp * f.maxHp / oldMax)
	end
	f.walk = Config.walkSpeed(p.stats.agi) * (styleDef and Config.gradeWalk(styleDef, p.gradeUp[p.style]) or 1) * (1 + mb.speed)
	local cm = Config.chiMax(p.stats.chi, idx)
	;(f :: any).chiMax = cm
	f.model:SetAttribute("ChiMax", cm)
	local cp = Config.playerPower(f.dmgMult, f.maxHp)
	;(f :: any).power = cp
	f.model:SetAttribute("Power", cp)
	f.model:SetAttribute("Awaken", Config.awakenTier(m))
	Combat.sync(f)
	updateTag(player)
end

------------------------------------------------------------------------
-- 쓰러짐과 보상
------------------------------------------------------------------------
local function respawnPlayer(player: Player)
	local f = Combat.fighterOfPlayer(player)
	if not f then
		return
	end
	f.dead = false
	f.hp = f.maxHp
	f.posture = 0
	f.stunUntil = 0
	f.brokenUntil = 0
	f.act = nil
	f.iframeUntil = os.clock() + 2
	Combat.sync(f)
	local char = player.Character
	local st = states[player]
	if char then
		-- 천상계에서 쓰러졌으면 천궁에서 일어난다
		if st and (st :: any).diedInSky then
			char:PivotTo(CFrame.new(Config.SKY.islands[1].at + Vector3.new(0, 5, 30)))
		else
			char:PivotTo(CFrame.new(Config.SPAWN))
		end
	end
	if st then
		(st :: any).diedInSky = nil
	end
	Push:FireClient(player, "respawn")
end

local function addMastery(player: Player, p: Profile, amount: number)
	if p.style == "" then
		return
	end
	local m = Calc.mastery(p, p.style)
	if m.lv >= Config.MASTERY_MAX then
		return
	end
	m.xp += amount
	local leveled = false
	while m.lv < Config.MASTERY_MAX and m.xp >= Config.masteryNeed(m.lv) do
		m.xp -= Config.masteryNeed(m.lv)
		m.lv += 1
		leveled = true
	end
	if leveled then
		local style = Config.STYLE_BY_ID[p.style]
		-- 이 숙련에 열리는 기술 (초 오의 X는 초월 권법에만 있다)
		local opened = {}
		for _, slot in ipairs({ "E", "R", "G", "X" }) do
			local sk = style and style.skills[slot]
			if Config.SKILL_UNLOCK[slot] == m.lv and sk then
				table.insert(opened, sk.name .. " (" .. slot .. ")")
			end
		end
		local unlocked = #opened > 0 and table.concat(opened, " · ") or nil
		local awaken = nil
		for tier, a in ipairs(Config.AWAKEN) do
			if a.lv == m.lv then
				awaken = tier
			end
		end
		Push:FireClient(player, "mastery", { style = p.style, lv = m.lv, unlocked = unlocked, awaken = awaken })
		refreshFighter(player)
		pushState(player)
	end
	states[player].dirty = true
end

------------------------------------------------------------------------
-- 강호 이야기 (차례로 이어지는 장)
------------------------------------------------------------------------
local Story = {}

local function countKeys(t: { [any]: any }): number
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

-- 권법을 준다 (이야기·숨은 권법)
local function grantStyle(player: Player, id: string, banner: boolean?)
	local p = profiles[player]
	if not p or p.styles[id] then
		return
	end
	p.styles[id] = true
	Calc.mastery(p, id)
	if banner then
		Push:FireClient(player, "learned", { style = id, hidden = Config.STYLE_BY_ID[id].hidden == true })
	end
	local st = states[player]
	if st then
		st.dirty = true
	end
end

function Story.done(p: Profile, g: any): boolean
	local k = g.kind
	if k == "kill" or k == "train" or k == "trial" or k == "boss" then
		return p.prog >= (g.n or 1)
	elseif k == "found" then
		return countKeys(p.found) >= g.n
	elseif k == "learn" then
		if g.id then
			return p.styles[g.id] == true
		end
		return countKeys(p.styles) >= g.n
	elseif k == "realm" then
		return Calc.realm(p) >= g.n
	elseif k == "fragment" then
		return countKeys(p.fragments) >= g.n
	end
	return false
end

function Story.advance(player: Player)
	local p = profiles[player]
	for _ = 1, 3 do
		local ch = p and Config.Story[p.story]
		if not ch or ch.goal.kind == "done" then
			break
		end
		local r = ch.reward or {}
		p.coins += r.coins or 0
		for _, stat in ipairs(Config.Stats) do
			p.stats[stat.id] += r.stats or 0
		end
		p.story = math.min(#Config.Story, p.story + 1)
		p.prog = 0
		Push:FireClient(player, "storyDone", { title = ch.title, coins = r.coins, stats = r.stats, next = Config.Story[p.story].title })
		-- 다음 장은 받아야 시작된다 (받기 전에는 목표 표시도 없다)
		local nxt = Config.Story[p.story]
		if nxt.goal.kind ~= "done" then
			Push:FireClient(player, "storyOffer", { chapter = p.story, title = nxt.title, text = nxt.text })
		end
		break
	end
	states[player].dirty = true
	refreshFighter(player)
	pushState(player)
end

-- 무슨 일이 일어났다 (적을 쓰러뜨림, 수련, 시험 통과 ...)
function Story.event(player: Player, kind: string, id: string?, amount: number?)
	local p = profiles[player]
	local ch = p and Config.Story[p.story]
	if not ch then
		return
	end
	-- 아직 받지 않은 이야기는 세지 않는다
	if p.accepted ~= p.story then
		return
	end
	local g = ch.goal
	if g.kind == kind and (g.id == nil or g.id == id) then
		p.prog += amount or 1
		Push:FireClient(player, "storyProg", { prog = p.prog })
	end
	if Story.done(p, g) then
		Story.advance(player)
	end
end

-- 경지·권법 수처럼 저절로 이뤄지는 목표를 다시 본다
function Story.check(player: Player)
	Story.event(player, "check")
end

-- 청운 장로와 이야기
function Story.talk(player: Player)
	local p = profiles[player]
	local ch = p and Config.Story[p.story]
	if not ch then
		return
	end
	Push:FireClient(player, "dialog", { who = "청운 장로", title = ch.title, text = ch.text })
	-- 장로에게 들으면 그 이야기를 받은 것
	if p.accepted ~= p.story then
		Story.accept(player)
	end
	if ch.goal.kind == "talk" then
		Story.advance(player)
		-- 장로가 다음 할 일까지 일러 줬으니 다음 장도 받은 것
		Story.accept(player)
	end
end

-- 이야기 받기: 이때부터 목표가 보이고 세어진다
function Story.accept(player: Player)
	local p = profiles[player]
	if not p or p.accepted == p.story then
		return
	end
	p.accepted = p.story
	states[player].dirty = true
	pushState(player)
	Story.check(player)
end

------------------------------------------------------------------------
-- 사부의 시험: 사부가 기운으로 빚은 분신과 겨룬다
------------------------------------------------------------------------
-- 관문과 수련 (아래에서 채운다: 위의 처치·쓰러짐에서도 부른다)
local Gate: any
local Rebirth: any
local Train: any
local Tower: any
local Maze: any = {}
local Raid: any = {}
local Trial = {}
local activeTrial: { [Player]: any } = {}

local function trialDef(style: any, master: any): any
	local moves = {}
	local list = table.clone(style.combo)
	table.insert(list, style.heavy)
	for _, m in ipairs(list) do
		if m.hits and #m.hits > 0 then
			local shift = 0.35
			local hits = {}
			for _, h in ipairs(m.hits) do
				local c = table.clone(h)
				c.t = h.t + shift
				c.dmg = h.dmg * 1.4
				table.insert(hits, c)
			end
			table.insert(moves, { id = m.id .. "T", name = m.name, pose = m.pose, windup = m.hits[1].t + shift, dur = m.dur + shift, range = (m.hits[1].range or 5) + 1, lunge = m.lunge, hits = hits })
		end
	end
	return {
		name = master.name .. "의 분신", hp = 420, posture = 220, speed = 19, aggro = 90, keep = 4, scale = 1.15, elite = true, duel = true,
		shirt = style.color, pants = style.color:Lerp(Color3.new(0, 0, 0), 0.5), style = style.id, coins = 0, xp = 80, moves = moves,
	}
end

-- 시험에 나오는 상대 하나: 시험을 청한 사람과 비슷한 힘으로 맞춘다 (센 사람에게도 시험이 시험이도록)
local function trialFoe(player: Player, f: any, style: any, master: any, variant: string, at: Vector3, powerK: number, hpMul: number?, edit: ((any) -> ())?): any
	local key = "trial_" .. style.id .. "_" .. variant
	local def = trialDef(style, master)
	if edit then
		edit(def)
	end
	Config.Enemies[key] = def
	local e = Npc.spawn(key, false, at, "trial")
	if not e then
		return nil
	end
	local ef = e.f :: any
	ef.trialOwner = player
	ef.trialStyle = style.id
	local want = ((f :: any).power or 100) * powerK
	local k = want / math.max(1, ef.power or 100)
	if k > 1 then
		ef.maxHp = math.floor(ef.maxHp * k)
		ef.hp = ef.maxHp
		ef.dmgMult *= k
		ef.power = math.floor(want)
		ef.model:SetAttribute("Power", ef.power)
	end
	if hpMul then
		ef.maxHp = math.max(1, math.floor(ef.maxHp * hpMul))
		ef.hp = ef.maxHp
	end
	Combat.sync(ef)
	e.target = f
	ef.model:SetAttribute("Style", style.id)
	return ef
end

local function trialProgress(player: Player)
	local T = activeTrial[player]
	if not T or T.kind == "duel" then
		return
	end
	local K = Config.TRIAL_KINDS[T.kind]
	Push:FireClient(player, "trialProg", { title = K.icon .. " " .. K.title, goal = K.goal, done = T.count, need = T.need, left = math.max(0, T.deadline - os.clock()), kind = T.kind })
end

local function trialWin(player: Player)
	local T = activeTrial[player]
	if T then
		Trial.ended(player, true)
	end
end

-- 제자 연무: 둘 → 셋 → 수제자 하나
local function trialWave(player: Player, T: any)
	local f = Combat.fighterOfPlayer(player)
	if activeTrial[player] ~= T or not f or f.dead then
		return
	end
	T.wave += 1
	T.count = T.wave - 1
	local style, master = Config.STYLE_BY_ID[T.style], T.master
	local waves = { { n = 2, k = 0.6, hp = 0.7 }, { n = 3, k = 0.65, hp = 0.7 }, { n = 1, k = 0.95, hp = 2.2, chief = true } }
	local W = waves[T.wave]
	if not W then
		T.count = T.need
		trialWin(player)
		return
	end
	for i = 1, W.n do
		local a = (i / W.n) * math.pi * 2 + T.wave
		local at = T.at + Vector3.new(math.cos(a) * 10, 0, math.sin(a) * 10)
		local ef = trialFoe(player, f, style, master, W.chief and "chief" or "disciple", at, W.k, W.hp, function(def)
			def.name = W.chief and (master.name .. "의 수제자") or (master.name .. "의 제자")
			def.scale = W.chief and 1.2 or 1.0
			def.pants = Color3.fromRGB(40, 36, 34)
		end)
		if ef then
			table.insert(T.foes, ef)
		end
	end
	toast(player, W.chief and "👤 수제자가 나선다!" or string.format("👥 제자들이 몰려온다 (%d / %d)", T.wave, #waves))
	trialProgress(player)
end

function Trial.start(player: Player, styleId: string)
	local style = Config.STYLE_BY_ID[styleId]
	local f = Combat.fighterOfPlayer(player)
	-- 각성 시련은 사부 없이 어디서나: 각성한 내 그림자가 앞에 나타난다
	local master = Config.MASTERS[styleId]
	if not master and style and style.awakenOf and f then
		master = { name = "각성한 그림자", at = f.root.Position + Combat.look(f) * 12 }
	end
	if not style or not master or not f or f.dead then
		return
	end
	if activeTrial[player] then
		toast(player, "이미 시험 중이에요")
		return
	end
	if Tower.active(player) then
		toast(player, "천층탑 안에서는 시험을 청할 수 없어요")
		return
	end
	local spawnAt = master.at + (f.root.Position - master.at).Unit * 6
	local kind, need = Config.trialNeed(styleId)
	if style.trialBoss or style.awakenOf then
		kind = "duel"
	end
	if kind ~= "duel" then
		-- 사부마다 다른 시험
		local K = Config.TRIAL_KINDS[kind]
		local T = { kind = kind, style = styleId, foes = {}, count = 0, need = need, wave = 0, master = master, at = spawnAt, deadline = os.clock() + (kind == "survive" and need or K.time * (style.trialHp and 1.5 or 1)) }
		activeTrial[player] = T
		local function immortalMaster(speed: number, dmgK: number): any
			local ef = trialFoe(player, f, style, master, "master", spawnAt, style.secret and 1.0 or 0.85, nil, function(def)
				def.name = master.name
				def.speed = speed
				def.aggro = 140
			end)
			if ef then
				ef.trialImmortal = true
				ef.dmgMult *= dmgK
				table.insert(T.foes, ef)
			end
			return ef
		end
		if kind == "deflect" then
			immortalMaster(17, 0.55)
		elseif kind == "survive" then
			immortalMaster(19, 0.8)
			for i = 1, 2 do
				local at = spawnAt + Vector3.new(i == 1 and -8 or 8, 0, 0)
				local ef = trialFoe(player, f, style, master, "disciple", at, 0.6, 0.6, function(def)
					def.name = master.name .. "의 제자"
					def.pants = Color3.fromRGB(40, 36, 34)
				end)
				if ef then
					table.insert(T.foes, ef)
				end
			end
		elseif kind == "disciples" then
			trialWave(player, T)
		end
		Push:FireClient(player, "dialog", { who = master.name, title = K.icon .. " " .. K.title, text = string.format(K.ask, need) })
		Push:FireClient(player, "trial", { m = T.foes[1] and T.foes[1].model, name = master.name, style = styleId, kind = kind, title = K.title })
		trialProgress(player)
		-- 시간이 다 되면: 버티기는 통과, 나머지는 실패
		task.delay(T.deadline - os.clock(), function()
			if activeTrial[player] == T then
				local pf = Combat.fighterOfPlayer(player)
				if kind == "survive" and pf and not pf.dead then
					T.count = T.need
					trialWin(player)
				else
					Trial.ended(player, false)
					toast(player, "⌛ 시험 시간이 다 됐어요. 다시 청하세요")
				end
			end
		end)
		if kind == "survive" then
			task.spawn(function()
				while activeTrial[player] == T do
					T.count = math.min(T.need, math.floor(T.need - (T.deadline - os.clock())))
					trialProgress(player)
					task.wait(1)
				end
			end)
		end
		return
	end
	-- 분신·그림자·권존과의 겨루기 (각성 시련, 일월 시련)
	local key = "trial_" .. styleId
	local e
	if style.trialBoss then
		-- 보스 시험 (권존): 사부 본인이 보스처럼 패턴을 쓰며 세 단계로 싸운다
		local def = trialDef(style, master)
		for k2, v in pairs(style.trialBoss) do
			def[k2] = v
		end
		def.name = master.name
		def.respawn = 99999
		Config.Bosses[key] = def
		e = Npc.spawn(key, true, spawnAt, "trial")
	else
		Config.Enemies[key] = trialDef(style, master)
		e = Npc.spawn(key, false, spawnAt, "trial")
	end
	if not e then
		return
	end
	local ef = e.f :: any
	ef.trialOwner = player
	ef.trialStyle = styleId
	-- 분신은 시험을 청한 사람과 비슷한 힘으로 (센 사람에게도 시험이 시험이도록)
	local want = ((f :: any).power or 100) * (style.secret and 1.15 or 0.85)
	local k = want / math.max(1, ef.power or 100)
	if k > 1 then
		ef.maxHp = math.floor(ef.maxHp * k)
		ef.hp = ef.maxHp
		ef.dmgMult *= k
		ef.power = math.floor(want)
		ef.model:SetAttribute("Power", ef.power)
		Combat.sync(ef)
	end
	-- 궁극의 권법 시험은 분신이 훨씬 질기다 (한두 번의 오의로 끝나지 않게)
	local hpMul = style.trialHp or (style.awakenOf and Config.AWAKEN_STYLE.trialHp)
	if hpMul then
		ef.maxHp = math.floor(ef.maxHp * hpMul)
		ef.hp = ef.maxHp
		Combat.sync(ef)
	end
	e.target = f
	ef.model:SetAttribute("Style", styleId)
	local T = { kind = "duel", style = styleId, foes = { ef }, count = 0, need = 1, wave = 0, master = master, at = spawnAt, deadline = os.clock() + (hpMul and 300 or 150) }
	activeTrial[player] = T
	if style.trialBoss and style.trialIntro then
		-- 그 밖의 보스 시련 (초월의 시련 등): 사부의 한마디만
		Push:FireClient(player, "dialog", { who = master.name, title = style.trialIntro.title, text = style.trialIntro.text })
	elseif style.trialBoss then
		-- 일월의 시련: 한낮에 시작해, 2단계에서 밤이 되고, 3단계에서 동이 튼다
		World.setClock(12)
		Push:FireClient(player, "dialog", { who = master.name, title = "일월의 시련", text = "분신 따위는 없다. 내가 직접 상대하마. 해가 지고 달이 뜨고, 다시 해가 뜰 때까지 서 있다면 이 두 손을 넘겨주지." })
		task.spawn(function()
			local seen = 1
			while activeTrial[player] == T and not ef.dead do
				local ph = tonumber(ef.model:GetAttribute("BossPhase")) or 1
				if ph ~= seen then
					seen = ph
					World.setClock(ph == 2 and 0 or 5.6)
					toast(player, ph == 2 and "🌙 해가 졌다. 달의 시간이다" or "🌅 동이 튼다. 마지막 시간이다")
				end
				task.wait(0.3)
			end
		end)
	else
		Push:FireClient(player, "dialog", { who = "각성 시련", title = style.name, text = "깨어난 힘이 그림자가 되어 앞을 막는다. 네 권법의 다음 모습을 넘어서라." })
	end
	Push:FireClient(player, "trial", { m = ef.model, name = master.name, style = styleId, kind = "duel" })
	-- 너무 오래 끌면 사부가 거둔다
	task.delay(hpMul and 300 or 150, function()
		if activeTrial[player] == T then
			Trial.ended(player, false)
			toast(player, "⌛ 시험 시간이 다 됐어요. 다시 청하세요")
		end
	end)
end

-- 시험의 상대가 쓰러졌다
function Trial.killed(player: Player, foe: any)
	local T = activeTrial[player]
	if not T then
		return
	end
	if T.kind == "duel" then
		Trial.ended(player, true)
	elseif T.kind == "disciples" then
		for _, ef in ipairs(T.foes) do
			if not ef.dead then
				return
			end
		end
		task.delay(1.2, function()
			trialWave(player, T)
		end)
	end
end

-- 흘리기 시험의 셈
function Trial.onDeflect(tgt: any, att: any)
	local player = tgt.player
	local T = player and activeTrial[player]
	if T and T.kind == "deflect" and att.trialOwner == player then
		T.count += 1
		trialProgress(player)
		if T.count >= T.need then
			trialWin(player)
		end
	end
end

function Trial.ended(player: Player, won: boolean)
	local T = activeTrial[player]
	if not T then
		return
	end
	activeTrial[player] = nil
	-- 남은 상대를 거둔다
	for _, ef in ipairs(T.foes) do
		if not ef.dead then
			Npc.despawn(ef)
		end
	end
	Push:FireClient(player, "trialProg", nil)
	local p = profiles[player]
	if won and p then
		local id = T.style
		local style = Config.STYLE_BY_ID[id]
		if style.awakenOf then
			-- 각성 시련을 넘었다: 은자를 내고 진 권법을 바로 얻는다
			p.coins = math.max(0, p.coins - Config.AWAKEN_STYLE.coins)
			grantStyle(player, id, true)
			p.style = id
			refreshFighter(player)
			toast(player, string.format("🔥 각성! %s을(를) 얻었어요", style.name))
			states[player].dirty = true
			pushState(player)
			return
		end
		p.trials[id] = true
		local m = Config.MASTERS[id]
		Push:FireClient(player, "trialWin", { style = id, master = m and m.name or "" })
		toast(player, string.format("🥋 시험 통과! 이제 %s을(를) 배울 수 있어요 (사부 곁에서 T)", style.name))
		states[player].dirty = true
		Story.event(player, "trial")
		pushState(player)
	end
end

Skills.init(Push)
Combat.init(Push, {
	onKill = function(f: any, by: any)
		if f.npc then
			Npc.onDeath(f)
			if f.towerOwner then
				Tower.killed(f.towerOwner, f)
			end
			if f.mazeOwner then
				Maze.killed(f.mazeOwner, f)
			end
			if f.raid then
				Raid.killed(f)
			end
			local killer = by and by.player
			local p = killer and profiles[killer]
			if killer and p then
				local isBoss = f.model:GetAttribute("Boss") == true
				-- 이야기·시험
				if f.trialOwner == killer then
					Trial.killed(killer, f)
				end
				if f.gateOwner == killer then
					Gate.ended(killer, true)
				end
				-- 천층탑의 보스는 이야기·권법·보스 기록에 들지 않는다
				local isBossKill = f.model:GetAttribute("Boss") == true and not f.towerOwner
				if isBossKill then
					for id, def in pairs(Config.Bosses) do
						if def == f.npc then
							Story.event(killer, "boss", id)
							-- 혈마를 꺾으면 그 손이 넘어온다
							if id == "hyeolma" then
								grantStyle(killer, "hyeolma", true)
							elseif id == "cheonma" then
								-- 천마를 꺾은 자가 하늘을 삼킨 힘을 거꾸로 쥔다
								grantStyle(killer, "pacheon", true)
							end
						end
					end
				elseif f.typeId then
					Story.event(killer, "kill", f.typeId)
				end
				-- 심마를 이긴 주인: 모든 능력치가 크게 오른다
				if f.simmaOwner == killer then
					-- (1.5판: 심마도 싸움이라 적을 쓰러뜨린 만큼 크게. 내 전투력의 적 세 마리 몫)
					local gain = math.floor(math.max(Config.Training.simma.reward, Config.killGain(rewardPower(killer)) * 3 / 4) * (Premium.owns(killer, "train2x") and 2 or 1) * gainMult(p))
					for _, st in ipairs(Config.Stats) do
						p.stats[st.id] += gain
					end
					Push:FireClient(killer, "simmaWin", { gain = gain })
					refreshFighter(killer)
					Story.check(killer)
				end
				local coins = math.floor(f.npc.coins * (f.rewardMult or 1))
				local xp = math.floor(f.npc.xp * (f.rewardMult or 1))
				p.coins += coins
				-- 천상계의 적은 천정을 떨어뜨린다
				local gems = 0
				if f.root.Position.Y > Config.SKY.y - 300 then
					local G = Config.SKY_GEMS
					gems = f.meteor and G.meteor or (isBoss and G.boss or (f.npc.elite and G.elite or G.enemy))
					p.skyGems += gems
				end
				p.kills += 1
				if isBossKill then
					for id, def in pairs(Config.Bosses) do
						if def == f.npc then
							p.bosses[id] = (p.bosses[id] or 0) + 1
						end
					end
					-- 보스는 가끔 심법 두루마리를 떨어뜨린다
					if math.random() < 0.15 then
						p.scrolls += 1
						toast(killer, "📜 심법 두루마리를 얻었어요!")
					end
				end
				addMastery(killer, p, xp)
				-- 1.5판: 쓰러뜨린 적의 전투력만큼 능력치가 오른다 (네 능력치에 고루). 시험·관문·심마의 상대는 빼고
				local statGain = 0
				if not f.trialOwner and not f.gateOwner and not f.simmaOwner and not f.raid and not (f.npc :: any).dummy then
					local KG = Config.KILL_GAIN
					-- 2.0판: 얻는 양은 쓰러뜨린 적의 전투력으로만 정해진다
					local g = Config.killGain(f.power or 100) * (isBoss and KG.boss or (f.npc.elite and KG.elite or 1)) * (f.towerOwner and KG.tower or 1) * gainMult(p)
					local each = math.max(1, math.floor(g / #Config.Stats))
					for _, sd in ipairs(Config.Stats) do
						p.stats[sd.id] += each
					end
					statGain = each * #Config.Stats
					refreshFighter(killer)
					Story.check(killer)
				end
				states[killer].dirty = true
				Push:FireClient(killer, "reward", { coins = coins, xp = xp, name = f.name, boss = isBoss, gems = gems, stats = statGain })
				updateTag(killer)
				pushState(killer)
			end
		elseif f.player then
			local player = f.player
			Trial.ended(player, false)
			Gate.ended(player, false)
			Tower.ended(player, "dead")
			Maze.ended(player, "dead")
			if states[player] then
				(states[player] :: any).diedInSky = f.root.Position.Y > Config.SKY.y - 300
			end
			-- 처음 쓰러지면: 이제부터 들판 PvP를 스스로 끌 수 있다
			local dp = profiles[player]
			if dp and not dp.pvpUnlocked and Config.PVP.offAfterDeath then
				dp.pvpUnlocked = true
				states[player].dirty = true
				Push:FireClient(player, "dialog", { who = "⚔ 들판 PvP", title = "PvP를 끌 수 있게 됐다",
					text = "마을과 사당 같은 안전한 곳 밖에서는 사람끼리도 싸운다. 한 번 쓰러졌으니 이제 원하면 PvP를 끌 수 있다. (화면 위의 ⚔ PvP 버튼)" })
				pushState(player)
			end
			-- 쓰러지면 보스 체력 막대를 걷는다 (다시 맞붙으면 다시 뜬다)
			Npc.forget(player)
			-- 비무대에서 이기면 기록
			local winner = by and by.player
			if winner and profiles[winner] then
				local wp = profiles[winner]
				wp.pvpWins += 1
				states[winner].dirty = true
				Push:FireAllClients("duel", { winner = winner.DisplayName, loser = player.DisplayName, ring = Combat.onRing(f.root.Position) })
				-- 비무 백 승: 무쌍신권
				local PS = Config.PVP_STYLE
				if wp.pvpWins >= PS.wins and not wp.styles[PS.style] then
					grantStyle(winner, PS.style, false)
					local wf = Combat.fighterOfPlayer(winner)
					cutscene(winner, "pvp100", { m = wf and wf.model })
					toast(winner, "⚔ 비무 " .. PS.wins .. "승! " .. Config.STYLE_BY_ID[PS.style].name .. "을(를) 얻었어요")
					Push:FireAllClients("realm", { name = winner.DisplayName, realm = Config.STYLE_BY_ID[PS.style].name })
				end
				pushState(winner)
			end
			task.delay(Config.RESPAWN_TIME, function()
				if player.Parent then
					respawnPlayer(player)
				end
			end)
		end
	end,
	onHit = function(att: any, _tgt: any, dmg: number, opt: any)
		if _tgt.raid and att.player then
			Raid.onHit(att.player, _tgt, dmg)
		end
		if att.player and not opt.chain then
			local p = profiles[att.player]
			if p then
				addMastery(att.player, p, 1 + dmg * 0.05)
			end
		end
	end,
	onDeflect = function(tgt: any, att: any)
		Trial.onDeflect(tgt, att)
		if tgt.player then
			local p = profiles[tgt.player]
			if p then
				addMastery(tgt.player, p, 3)
			end
		end
	end,
})

------------------------------------------------------------------------
-- 맵과 적
------------------------------------------------------------------------
-- 맵을 먼저 짓고, 요청·사부·적은 아래에서 차례로 (적 만들기가 늦거나 틀려도 나머지는 돈다)
pcall(World.setupLighting)
local okWorld, builtWorld = pcall(World.build)
if not okWorld then
	warn("[권왕] 맵 만들기 오류:", builtWorld)
end
local W: any = okWorld and builtWorld or { train = {}, rings = {} }
Npc.init(Push)

task.spawn(function()
	local dt = 0.05
	while true do
		task.wait(dt)
		local ok, err = pcall(Combat.tick, dt)
		if not ok then
			warn("[권왕] 싸움 틱 오류:", err)
		end
	end
end)

------------------------------------------------------------------------
-- 기술 쓰기 (화면이 먼저 움직이고 알려 준다)
------------------------------------------------------------------------
local Actions = {}

local function nearestHostile(f: any, range: number): any?
	local best, bestD = nil, range
	for _, other in pairs(Combat.fighters) do
		if Combat.hostile(f, other) then
			local d = (other.root.Position - f.root.Position).Magnitude
			if d < bestD then
				best, bestD = other, d
			end
		end
	end
	return best
end

-- 완전 각성: 그림자 메아리가 같은 기술을 한 번 더 (절반 위력)
local function echoAct(f: any, move: any, slot: any, speed: number, dmgScale: number)
	local A = Config.AWAKEN[2]
	task.delay(A.echoDelay, function()
		if f.dead or not f.model.Parent then
			return
		end
		Push:FireAllClients("echo", { m = f.model, style = f.style, slot = slot, pose = move.pose, dur = move.dur / speed })
		for _, h in ipairs(move.hits or {}) do
			task.delay(h.t / speed, function()
				if f.dead then
					return
				end
				local eh = table.clone(h)
				eh.dmg *= A.echo * dmgScale
				eh.posture *= A.echo
				for _, victim in ipairs(Combat.query(f, eh)) do
					Combat.applyHit(f, victim, eh, { move = move, isSkill = true, chain = true })
				end
			end)
		end
		if move.proj then
			task.delay(move.dur / speed * 0.42, function()
				if not f.dead then
					Combat.fire(f, move.proj, 0.6, { move = move, isSkill = true })
				end
			end)
		end
	end)
end

function Actions.act(player: Player, slotArg: any, seqArg: any, chargeArg: any, perfectArg: any)
	local p = profiles[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not f or p.style == "" then
		return
	end
	Combat.dismount(f)
	local style = Config.STYLE_BY_ID[p.style]
	local slot: any = slotArg
	if type(slot) == "number" then
		slot = math.floor(slot)
		if slot < 1 or slot > #style.combo then
			return
		end
	elseif slot ~= "H" and slot ~= "E" and slot ~= "R" and slot ~= "G" and slot ~= "X" and slot ~= "F" and not Config.ACTION_MOVES[slot] then
		return
	end
	local seq = math.floor(tonumber(seqArg) or 0)
	local move = Config.move(p.style, slot)
	if not move then
		return
	end
	local t = os.clock()
	if f.dead or Combat.stunned(f) then
		return
	end
	-- 몸놀림 기술은 그 순간에만: 대시 직후, 공중, 흘리기 직후
	local fa = f :: any
	if slot == "D" and t - (f.dashAt or 0) > Config.ACTION_WINDOW.D + 0.15 then
		return
	elseif slot == "A" then
		if not f.hum or f.hum.FloorMaterial ~= Enum.Material.Air or t - (fa.airAtkAt or 0) < 0.8 then
			return
		end
		fa.airAtkAt = t
	elseif slot == "C" then
		if t - (fa.deflectAt or 0) > Config.ACTION_WINDOW.C + 0.15 then
			return
		end
		fa.deflectAt = 0
	elseif slot == "J" then
		-- 공중 연격: 공중에서, 1.5초 안에 세 번까지
		if not f.hum or f.hum.FloorMaterial ~= Enum.Material.Air then
			return
		end
		if t - (fa.airJAt or 0) > 1.5 then
			fa.airJCount = 0
		end
		if (fa.airJCount or 0) >= 3 then
			return
		end
		fa.airJCount = (fa.airJCount or 0) + 1
		fa.airJAt = t
	end
	-- 각성 단계 (숙련 6 / 10)
	local tier = Config.awakenTier(Calc.mastery(p, p.style).lv)
	if slot == "F" and (tier < 1 or fa.lastSlot ~= #style.combo or t - (fa.lastSlotAt or 0) > 1.6) then
		return
	end
	-- 앞 기술이 거의 끝났을 때만 다음 기술 (연타는 70%부터 이어진다)
	local act = f.act
	if act and t < act.start + act.dur * (type(slot) == "number" and 0.7 or 0.85) and slot ~= "C" then
		return
	end
	-- 강타(Z)는 연달아 못 쓴다 (정권 지르기 무한 연타 막기)
	if slot == "H" then
		if t < (f.cds.H or 0) - 0.1 and TEST_INF[player] ~= true then
			return
		end
		f.cds.H = t + Config.HEAVY_CD
	end
	if slot == "E" or slot == "R" or slot == "G" or slot == "X" then
		if not Calc.unlocked(p, slot) then
			toast(player, string.format("🔒 %s: 숙련도 %d에 열려요", move.name, Config.SKILL_UNLOCK[slot]))
			return
		end
		-- 테스트: 내공 무한·쿨 없음이 켜져 있으면 둘 다 건너뛴다
		local inf = TEST_INF[player] == true
		if t < (f.cds[slot] or 0) and not inf then
			return
		end
		local cost = inf and 0 or (move.chi or 0)
		if f.chi < cost then
			toast(player, string.format("내공이 부족해요 (🌀 %d 필요)", cost))
			return
		end
		f.chi -= cost
		f.cds[slot] = inf and 0 or t + (move.cd or 0) * (tier > 0 and Config.AWAKEN[tier].cd or 1) * (style.cdMult or 1) * (1 - ((f :: any).mCd or 0))
	end
	local speed = Config.actSpeed(style, p.gradeUp[p.style], (f.buffs.frenzy or 0) > t)
	local charge = 0
	if slot == "H" and style.charge then
		charge = math.clamp(tonumber(chargeArg) or 0, 0, style.charge)
	end
	local bloom = false
	local dmgScale = 1
	if slot == "H" then
		if (style.id == "maehwa" or style.petals) and f.stacks.petal >= (style.petalMax or 20) then
			bloom = true
			f.stacks.petal = 0
		elseif style.id == "taeheo" and f.stacks.flow > 0 then
			dmgScale = 1 + (move.stackDmg or 0.5) * f.stacks.flow
			f.stacks.flow = 0
		end
	end
	-- 무영 그림자 걸음: 가장 가까운 적의 등 뒤로
	local teleported = false
	if move.teleport then
		local tgt = nearestHostile(f, move.teleport)
		if not tgt then
			toast(player, "가까이에 상대가 없어요")
			f.chi += move.chi or 0
			f.cds[slot] = 0
			return
		end
		local behind = tgt.root.Position - Combat.look(tgt) * 3.5
		local char = player.Character
		if char then
			char:PivotTo(CFrame.lookAt(behind + Vector3.new(0, 0.5, 0), Vector3.new(tgt.root.Position.X, behind.Y + 0.5, tgt.root.Position.Z)))
		end
		teleported = true
		Push:FireAllClients("blink", f.model, behind)
	end
	-- 박자: 앞 연타가 끝나 갈 즈음 정확히 이었는가 (화면이 알려 준 것을 서버가 넉넉히 다시 본다)
	local perfect = false
	local prev = fa.lastAct
	if perfectArg == true and (type(slot) == "number" and slot > 1 or slot == "F") and prev then
		local frac = (t - prev.start) / math.max(0.05, prev.dur)
		perfect = frac >= 0.45 and frac <= 1.0 + 0.45 / math.max(0.05, prev.dur)
	end
	if type(slot) == "number" or slot == "F" then
		if perfect then
			fa.perfectChain = (fa.perfectChain or 0) + 1
			fa.sloppy = math.max(0, (fa.sloppy or 0) - 2)
			dmgScale *= Config.RHYTHM.bonus * (fa.perfectChain >= Config.RHYTHM.chain and Config.RHYTHM.chainBonus or 1)
		else
			if slot ~= 1 then
				fa.perfectChain = 0
			end
			fa.sloppy = math.min(6, (fa.sloppy or 0) + 1)
		end
	end
	-- 각성: 기술이 세진다 (완전 각성이면 연타까지 모두)
	if tier >= 2 or (tier == 1 and type(slot) == "string") then
		dmgScale *= Config.AWAKEN[tier].dmg
	end
	local first = move.hits and move.hits[1]
	local newAct = Combat.begin(f, move, slot, seq, { speed = speed, charge = charge, bloom = bloom, align = first and first.t / speed or nil })
	;(newAct :: any).dmgScale = dmgScale
	;(newAct :: any).perfect = perfect
	fa.lastSlot = slot
	fa.lastSlotAt = t
	fa.lastAct = newAct
	if tier >= 2 and (slot == "E" or slot == "R" or slot == "H" or slot == "F" or slot == "G") then
		echoAct(f, move, slot, speed, dmgScale)
	end
	;(newAct :: any).teleport = teleported
	-- 권법마다 다른 기술 장치
	if move.mech then
		Skills.run(f, move, { scale = dmgScale, speed = speed })
	end
	if move.buff then
		f.buffs[move.buff.kind] = t + move.buff.dur
		f.model:SetAttribute("Buff", move.buff.kind)
		task.delay(move.buff.dur, function()
			if f.model:GetAttribute("Buff") == move.buff.kind and os.clock() >= (f.buffs[move.buff.kind] or 0) then
				f.model:SetAttribute("Buff", nil)
			end
		end)
	end
	if move.counter then
		f.counterUntil = t + move.counter
	end
	-- 장풍: 손을 내뻗는 순간 서버가 날린다
	if move.proj then
		local scale = 1
		if charge > 0 and move.chargeMult then
			scale = 1 + (move.chargeMult - 1) * charge / style.charge
		end
		task.delay(move.dur / speed * 0.42, function()
			if f.act == newAct and not f.dead then
				f.lastSwingAt = os.clock()
				Combat.fire(f, move.proj, scale, { move = move, isSkill = type(slot) == "string" and slot ~= "H" })
			end
		end)
	end
	Combat.sync(f)
end

-- 화면이 알려 준 맞힘
function Actions.hit(player: Player, seqArg: any, idxArg: any, targets: any)
	local f = Combat.fighterOfPlayer(player)
	if not f or f.dead then
		return
	end
	local act = f.act
	local seq = math.floor(tonumber(seqArg) or -99)
	local idx = math.floor(tonumber(idxArg) or 0)
	if not act or act.seq ~= seq then
		return
	end
	local move = act.move
	local h = move.hits and move.hits[idx]
	if not h then
		return
	end
	-- 시간 확인 (통신이 늦은 만큼 넉넉히)
	local t = os.clock()
	local due = act.start + h.t / act.speed
	if t < due - 0.3 or t > due + 0.7 then
		return
	end
	if not act.swung[idx] then
		act.swung[idx] = true
		f.lastSwingAt = t
	end
	local scale = (act :: any).dmgScale or 1
	local hit = h
	if scale ~= 1 then
		hit = table.clone(h)
		hit.dmg *= scale
		hit.posture *= scale
	end
	local isSkill = type(act.slot) == "string" and act.slot ~= "H"
	if type(targets) == "table" then
		local n = 0
		for _, m in ipairs(targets) do
			n += 1
			if n > 12 then
				break
			end
			local tgt = Combat.fighters[m :: Model] -- 등록된 무인만 (아무 값이나 오면 nil)
			if tgt then
				local key = idx .. ":" .. tostring(m)
				if not act.done[key] and Combat.plausible(f, tgt, h) then
					act.done[key] = true
					Combat.applyHit(f, tgt, hit, { move = move, act = act, isSkill = isSkill, teleport = (act :: any).teleport })
				end
			end
		end
	end
	-- 매화 만개: 첫 맞힘에 둘레로 꽃잎이 터진다
	if idx == 1 and act.bloom and not (act :: any).bloomDone then
		(act :: any).bloomDone = true
		local b = move.bloom
		Push:FireAllClients("bloom", f.model, b.radius)
		for _, victim in ipairs(Combat.query(f, { range = 0, radius = b.radius, aoe = true })) do
			Combat.applyHit(f, victim, { dmg = b.dmg, posture = b.posture, stun = 0.8, kb = 30, aoe = true }, { move = move, act = act, isSkill = true, chain = true })
		end
	end
end

function Actions.guard(player: Player, on: any)
	local f = Combat.fighterOfPlayer(player)
	if not f or f.dead then
		return
	end
	local want = on == true
	if want then
		Combat.dismount(f)
	end
	if want and (Combat.stunned(f) or Combat.busy(f)) then
		return
	end
	if want and not f.guarding then
		f.guardStart = os.clock()
	end
	f.guarding = want
	f.model:SetAttribute("Guard", want)
end

function Actions.dash(player: Player, kindArg: any)
	local p = profiles[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not f or f.dead or Combat.stunned(f) then
		return
	end
	Combat.dismount(f)
	local style = Config.STYLE_BY_ID[p.style]
	local cd = style and style.dashCd or Config.DASH_CD
	local charges = style and style.dashCharges or 1
	local t = os.clock()
	if t - f.dashAt > cd then
		f.dashUsed = 0
	end
	if f.dashUsed >= charges then
		return
	end
	f.dashUsed += 1
	f.dashAt = t
	f.iframeUntil = math.max(f.iframeUntil, t + Config.DASH_IFRAMES)
	f.guarding = false
	f.act = nil
	local kind = (kindArg == "back" or kindArg == "left" or kindArg == "right") and kindArg or "front"
	Push:FireAllClients("dash", f.model, kind)
end

function Actions.potion(player: Player)
	local p, st = profiles[player], states[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not st or not f or f.dead then
		return
	end
	if p.potions <= 0 then
		toast(player, "금창약이 없어요 (마을 만물상)")
		return
	end
	if os.clock() - st.potionAt < 4 then
		return
	end
	st.potionAt = os.clock()
	p.potions -= 1
	f.hp = math.min(f.maxHp, f.hp + f.maxHp * Config.POTION_HEAL)
	Combat.sync(f)
	st.dirty = true
	Push:FireAllClients("heal", f.model)
	pushState(player)
end

-- 권법 배우기 (처음 하나는 공짜) / 바꾸기
function Actions.learn(player: Player, id: any)
	local p, st = profiles[player], states[player]
	local style = type(id) == "string" and Config.STYLE_BY_ID[id]
	if not p or not st or not style then
		return
	end
	if not p.styles[style.id] then
		local count = 0
		for _ in pairs(p.styles) do
			count += 1
		end
		-- 기본 권법은 장로에게, 숨은 권법은 조건을 채워야, 사부의 권법은 사부를 찾아 시험을 넘어야
		if style.starter then
			toast(player, "삼재권은 청운 장로에게 받아요")
			return
		elseif style.hidden and not Config.MASTERS[style.id] then
			toast(player, "🔒 " .. (style.unlockHint or "숨겨진 권법"))
			return
		end
		local master = Config.MASTERS[style.id]
		if not master then
			return
		end
		if style.realmReq and Calc.realm(p) < style.realmReq then
			toast(player, string.format("🔒 %s은(는) %s의 경지에 올라야 익힐 수 있어요", style.name, Config.Realms[style.realmReq].name))
			return
		end
		local req = style.styleReq and Config.STYLE_BY_ID[style.styleReq]
		if req and not p.styles[req.id] then
			toast(player, string.format("🔒 %s은(는) %s을(를) 먼저 익혀야 배울 수 있어요", style.name, req.name))
			return
		end
		if not p.found[style.id] then
			toast(player, "❓ 아직 이 권법의 사부를 찾지 못했어요. 소문: " .. (master.rumor or ""))
			return
		end
		local f0 = Combat.fighterOfPlayer(player)
		local pos = f0 and f0.root.Position
		local d = pos and Vector3.new(pos.X - master.at.X, 0, pos.Z - master.at.Z).Magnitude or math.huge
		if d > Config.MASTER_RANGE then
			toast(player, string.format("📍 %s을(를) 배우려면 %s의 %s에게 가야 해요", style.name, master.region, master.name))
			Push:FireClient(player, "guide", { style = style.id })
			return
		end
		if not p.trials[style.id] then
			Trial.start(player, style.id)
			return
		end
		local cost = Config.LEARN_COST[math.min(count + 1, #Config.LEARN_COST)]
		if p.coins < cost then
			toast(player, string.format("은자가 부족해요 (💰 %s 필요)", Config.formatNumber(cost)))
			return
		end
		p.coins -= cost
		p.styles[style.id] = true
		Calc.mastery(p, style.id)
		Push:FireClient(player, "learned", { style = style.id, first = count == 0 })
		Story.check(player)
	end
	local f = Combat.fighterOfPlayer(player)
	if f and f.combatUntil > os.clock() and p.style ~= "" and p.style ~= style.id and not st.tester then
		toast(player, "싸우는 중에는 권법을 바꿀 수 없어요")
		return
	end
	p.style = style.id
	if f then
		f.stacks = { flow = 0, petal = 0, petalAt = 0, charge = 0 }
		f.buffs = {}
		f.cds = {}
	end
	st.dirty = true
	refreshFighter(player)
	pushState(player)
end

function Actions.buy(player: Player, id: any)
	local p, st = profiles[player], states[player]
	local item = type(id) == "string" and Config.SHOP_BY_ID[id]
	if not p or not st or not item then
		return
	end
	if item.id == "potion" and p.potions >= item.max then
		toast(player, "금창약은 5개까지 들 수 있어요")
		return
	end
	if p.coins < item.cost then
		toast(player, string.format("은자가 부족해요 (💰 %s 필요)", Config.formatNumber(item.cost)))
		return
	end
	p.coins -= item.cost
	if item.id == "potion" then
		p.potions += 1
	elseif item.id == "elixir" then
		p.elixirUntil = math.max(os.time(), p.elixirUntil) + 300
	elseif item.id == "pill" then
		for _, s in ipairs(Config.Stats) do
			p.stats[s.id] += 10
		end
		refreshFighter(player)
	end
	st.dirty = true
	toast(player, item.icon .. " " .. item.name .. "을(를) 샀어요")
	pushState(player)
end

------------------------------------------------------------------------
-- 수련
------------------------------------------------------------------------
------------------------------------------------------------------------
-- 경지의 관문: 특급부터는 능력치가 닿아도 관문 수호자를 꺾어야 그 경지에 오른다
------------------------------------------------------------------------
Gate = {}
local activeGate: { [Player]: any } = {}

------------------------------------------------------------------------
-- 1.9판: 환생. 열린 끝 경지에 오르면, 능력치를 모두 내려놓고 삼류로 다시 태어난다
------------------------------------------------------------------------
Rebirth = {}
function Rebirth.go(player: Player)
	local p, st = profiles[player], states[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not st or not f or f.dead then
		return
	end
	local RB = Config.REBIRTH
	if p.rebirth >= RB.max then
		toast(player, "♻ 이미 네 번 환생했어요 (더는 환생할 수 없어요)")
		return
	end
	local cap = Config.realmCap(p.rebirth)
	if (Calc.realm(p)) < cap then
		toast(player, string.format("♻ %s의 경지에 올라야 환생할 수 있어요", Config.Realms[cap].name))
		return
	end
	if Tower.active(player) or Maze.active(player) or activeGate[player] then
		toast(player, "지금은 환생할 수 없어요 (탑·미궁·관문 밖에서)")
		return
	end
	if f.combatUntil > os.clock() then
		toast(player, "싸우는 중에는 환생할 수 없어요")
		return
	end
	Train.stop(player)
	for _, sd in ipairs(Config.Stats) do
		p.stats[sd.id] = 0
	end
	p.rebirth += 1
	p.coins += RB.coins * p.rebirth
	st.dirty = true
	refreshFighter(player)
	f.hp = f.maxHp
	Combat.sync(f)
	local newRealm = Config.Realms[Config.realmCap(p.rebirth)]
	Push:FireAllClients("rebirth", { m = f.model, n = p.rebirth, name = player.DisplayName, me = false })
	Push:FireClient(player, "rebirthDone", { n = p.rebirth, name = RB.names[p.rebirth], realm = newRealm.name, coins = RB.coins * p.rebirth,
		power = math.floor((Config.rebirthPower(p.rebirth) - 1) * 100 + 0.5), gain = math.floor((Config.rebirthGain(p.rebirth) - 1) * 100 + 0.5) })
	Story.check(player)
	pushState(player)
end


-- 관문이 막 열렸으면 한 번 알려 준다
function Gate.notify(player: Player, p: Profile, st: State)
	local nxt = Calc.gateNext(p)
	if nxt and (st :: any).gateNotified ~= nxt then
		(st :: any).gateNotified = nxt
		Push:FireClient(player, "dialog", { who = "⛩ 경지의 관문", title = Config.Realms[nxt].name .. "의 관문이 열렸다",
			text = "몸은 이미 다음 경지에 닿았다. 그러나 경지는 몸만으로 오르지 않는다. 관문 수호자를 꺾어라. (능력치 창의 '⛩ 관문 도전')" })
		pushState(player)
	end
end

function Gate.start(player: Player)
	local p, st = profiles[player], states[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not st or not f or f.dead then
		return
	end
	local nxt = Calc.gateNext(p)
	if not nxt then
		toast(player, "아직 열린 관문이 없어요 (능력치가 다음 경지에 닿아야 해요)")
		return
	end
	if activeGate[player] then
		toast(player, "이미 관문 시련 중이에요")
		return
	end
	if Tower.active(player) then
		toast(player, "천층탑 안에서는 관문에 도전할 수 없어요")
		return
	end
	if f.combatUntil > os.clock() then
		toast(player, "싸우는 중에는 관문에 도전할 수 없어요")
		return
	end
	local t = os.clock()
	if t - ((st :: any).gateAt or -999) < Config.GATE.cooldown then
		toast(player, string.format("⛩ 숨을 고르세요 (%d초)", math.ceil(Config.GATE.cooldown - (t - (st :: any).gateAt))))
		return
	end
	;(st :: any).gateAt = t
	Train.stop(player)
	local at = f.root.Position + Combat.look(f) * 14
	local e = Npc.spawn("gatekeeper", false, at, "trial")
	if not e then
		return
	end
	local ef = e.f :: any
	ef.gateOwner = player
	ef.gateIdx = nxt
	ef.trialOwner = player
	ef.name = Config.Realms[nxt].name .. "의 관문 수호자"
	ef.model:SetAttribute("Label", ef.name)
	-- 수호자는 도전자와 비슷한 힘, 체력은 넉넉히 (경지가 높을수록 더)
	local want = ((f :: any).power or 100) * Config.GATE.power
	local k = want / math.max(1, ef.power or 100)
	if k > 1 then
		ef.maxHp = math.floor(ef.maxHp * k)
		ef.dmgMult *= k
		ef.power = math.floor(want)
		ef.model:SetAttribute("Power", ef.power)
	end
	ef.maxHp = math.floor(ef.maxHp * (Config.GATE.hp + Config.GATE.hpPerRealm * (nxt - Config.GATE.from)))
	ef.hp = ef.maxHp
	Combat.sync(ef)
	e.target = f
	activeGate[player] = ef
	if not cutscene(player, "gate_first", { m = ef.model }) then
		Push:FireClient(player, "dialog", { who = "⛩ " .. ef.name, title = Config.Realms[nxt].name .. "의 관문", text = "이 경지에 오를 자격이 있는지 보이라." })
	end
	Push:FireClient(player, "boss", ef.model)
	task.delay(Config.GATE.time, function()
		if activeGate[player] == ef and not ef.dead then
			activeGate[player] = nil
			Npc.despawn(ef)
			toast(player, "⌛ 관문이 닫혔어요. 다시 도전하세요")
		end
	end)
end

-- 이겼으면 관문을 넘고 경지가 오른다. 졌거나 그만두면 수호자가 물러난다
function Gate.ended(player: Player, won: boolean)
	local ef = activeGate[player]
	if not ef then
		return
	end
	activeGate[player] = nil
	local p = profiles[player]
	Push:FireClient(player, "boss", nil)
	if won and p then
		p.gates[tostring(ef.gateIdx)] = true
		local _, realm = Calc.realm(p)
		Push:FireAllClients("realm", { name = player.DisplayName, realm = realm.name })
		toast(player, "⛩ 관문을 넘었다! 경지 " .. realm.name)
		states[player].dirty = true
		refreshFighter(player)
		Story.check(player)
		local st = states[player]
		if st then
			(st :: any).gateNotified = nil
			Gate.notify(player, p, st)
		end
		pushState(player)
	elseif not ef.dead then
		Npc.despawn(ef)
	end
end

------------------------------------------------------------------------
-- 천층탑: 하늘의 시련장에서 한 층씩. 층의 적을 모두 꺾으면 다음 층 (열 층마다 보스)
-- 쓰러지거나 떨어지거나 나가면 끝. 최고 기록을 넘을 때 다섯 층마다 두루마리
------------------------------------------------------------------------
Tower = {}
local towerSlots: { [number]: Player } = {}
local activeTower: { [Player]: any } = {}

function Tower.start(player: Player, back: Vector3?)
	local p, st = profiles[player], states[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not st or not f or f.dead then
		return
	end
	if activeTower[player] then
		return
	end
	if activeTrial[player] or activeGate[player] or Maze.active(player) then
		toast(player, "다른 시련 중에는 탑에 오를 수 없어요")
		return
	end
	if f.combatUntil > os.clock() then
		toast(player, "싸우는 중에는 탑에 오를 수 없어요")
		return
	end
	local slot
	for i = 1, Config.TOWER.slots do
		if not towerSlots[i] then
			slot = i
			break
		end
	end
	if not slot then
		toast(player, "🗼 탑이 붐벼요. 잠시 뒤에 다시 오세요")
		return
	end
	local ok, center = pcall(World.towerArena, slot)
	if not ok then
		warn("[권왕] 천층탑 시련장 오류:", center)
		return
	end
	towerSlots[slot] = player
	Train.stop(player)
	Combat.dismount(f)
	local run = { slot = slot, center = center, floor = 0, alive = {}, token = 0, back = back }
	activeTower[player] = run
	local char = player.Character
	if char then
		local at = center + Vector3.new(0, 4, Config.TOWER.radius * 0.6)
		char:PivotTo(CFrame.lookAt(at, Vector3.new(center.X, at.Y, center.Z)))
	end
	f.hp = f.maxHp
	f.chi = (f :: any).chiMax or Config.CHI_MAX
	Combat.sync(f)
	cutscene(player, "tower_first", { at = center })
	Tower.next(player, run)
	-- 단에서 떨어지면 끝. 적이 떨어지면 쓰러뜨린 것으로 친다 (층이 끝나지 않는 일이 없게)
	task.spawn(function()
		while activeTower[player] == run do
			task.wait(0.4)
			local ff = Combat.fighterOfPlayer(player)
			if activeTower[player] == run and ff and not ff.dead and ff.root.Position.Y < center.Y - 30 then
				Tower.ended(player, "fall")
			elseif activeTower[player] == run then
				for ef in pairs(run.alive) do
					if not ef.dead and (not ef.root.Parent or ef.root.Position.Y < center.Y - 30) then
						Combat.kill(ef, ff)
					end
				end
			end
		end
	end)
end

-- 다음 층: 잠깐 숨을 고른 뒤 적이 나타난다
function Tower.next(player: Player, run: any)
	local p = profiles[player]
	if not p then
		return
	end
	local T = Config.TOWER
	run.floor += 1
	run.token += 1
	local floor, token = run.floor, run.token
	local isBoss = floor % T.bossEvery == 0
	Push:FireClient(player, "tower", { floor = floor, best = p.towerBest, boss = isBoss })
	task.delay(floor == 1 and 4 or 2.5, function()
		local f = Combat.fighterOfPlayer(player)
		if activeTower[player] ~= run or run.token ~= token or not f or f.dead then
			return
		end
		local list = {}
		if isBoss then
			local id = T.bosses[(math.floor(floor / T.bossEvery) - 1) % #T.bosses + 1]
			table.insert(list, { id, true })
		else
			local pool = T.bands[1][2]
			for _, b in ipairs(T.bands) do
				if floor >= b[1] then
					pool = b[2]
				end
			end
			for _ = 1, math.min(5, 2 + math.floor(floor / 8)) do
				table.insert(list, { pool[math.random(#pool)], false })
			end
		end
		-- 층의 세기는 정해져 있다 (누가 오르든 같다)
		local want = T.powerStart * T.powerGrowth ^ (floor - 1)
		for i, item in ipairs(list) do
			local a = i / #list * math.pi * 2
			local at = run.center + Vector3.new(math.cos(a), 0, math.sin(a)) * (T.radius * (item[2] and 0.2 or 0.45))
			local e = Npc.spawn(item[1], item[2], at, "trial")
			if e then
				local ef = e.f :: any
				ef.towerOwner = player
				ef.trialOwner = player
				local w = want * (item[2] and T.bossPower or 1)
				local k = w / math.max(1, ef.power or 100)
				ef.maxHp = math.max(1, math.floor(ef.maxHp * k * (item[2] and 2.5 or 1)))
				ef.hp = ef.maxHp
				ef.dmgMult *= k
				ef.power = math.floor(w)
				ef.rewardMult = 0.3
				ef.model:SetAttribute("Power", ef.power)
				ef.model:SetAttribute("Label", string.format("%d층 · %s", floor, ef.name))
				Combat.sync(ef)
				e.target = f
				run.alive[ef] = true
			end
		end
	end)
end

function Tower.killed(player: Player, ef: any)
	local run = activeTower[player]
	if not run or not run.alive[ef] then
		return
	end
	run.alive[ef] = nil
	if next(run.alive) then
		return
	end
	local p, st = profiles[player], states[player]
	if not p or not st then
		return
	end
	local T = Config.TOWER
	local floor = run.floor
	local coins = T.coins * floor
	p.coins += coins
	local scrolls = 0
	if floor > p.towerBest then
		p.towerBest = floor
		if floor % T.scrollEvery == 0 then
			scrolls += 1
		end
		if floor % T.bossEvery == 0 then
			scrolls += 2
		end
		p.scrolls += scrolls
	end
	st.dirty = true
	Push:FireClient(player, "towerClear", { floor = floor, coins = coins, scrolls = scrolls, best = p.towerBest })
	pushState(player)
	Tower.next(player, run)
end

-- reason: "dead" / "fall" / "leave" / "left"
function Tower.ended(player: Player, reason: string)
	local run = activeTower[player]
	if not run then
		return
	end
	activeTower[player] = nil
	run.token += 1
	towerSlots[run.slot] = nil
	for ef in pairs(run.alive) do
		if not ef.dead then
			Npc.despawn(ef)
		end
	end
	run.alive = {}
	if reason == "left" then
		return
	end
	Push:FireClient(player, "tower", nil)
	Push:FireClient(player, "boss", nil)
	local p = profiles[player]
	if p then
		toast(player, string.format("🗼 천층탑 %d층까지 올랐어요 (최고 %d층)", math.max(0, run.floor - 1), p.towerBest))
	end
	if reason ~= "dead" then
		local char = player.Character
		if char then
			-- 들어온 문으로 돌아간다 (천궁의 탑 문으로 들어왔으면 천궁으로)
			local at = run.back or (Config.TOWER.enter + Vector3.new(0, 4, 0) + Vector3.new(-Config.TOWER.enter.X, 0, -Config.TOWER.enter.Z).Unit * 22)
			char:PivotTo(CFrame.new(at))
		end
	end
end

function Tower.active(player: Player): any
	return activeTower[player]
end

-- 1.7판: 어디서든 천층탑 입구로 (싸우는 중·시련 중에는 안 된다)
function Tower.teleport(player: Player)
	local p = profiles[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not f or f.dead then
		return
	end
	if activeTrial[player] or activeGate[player] or activeTower[player] or Maze.active(player) then
		toast(player, "시련 중에는 이동할 수 없어요")
		return
	end
	if f.combatUntil > os.clock() then
		toast(player, "싸우는 중에는 이동할 수 없어요")
		return
	end
	Train.stop(player)
	Combat.dismount(f)
	local char = player.Character
	if char then
		local E = Config.TOWER.enter
		local at = E + Vector3.new(0, 4, 0) + Vector3.new(-E.X, 0, -E.Z).Unit * 22
		char:PivotTo(CFrame.lookAt(at, Vector3.new(E.X, at.Y, E.Z)))
		Push:FireAllClients("blink", char, at)
	end
	toast(player, "🗼 천층탑 입구로 왔어요 (탑 문 앞에서 T)")
end

------------------------------------------------------------------------
-- 1.7판 구름 미궁: 혼자 들어가는 일곱 방. 방의 적을 다 쓰러뜨리면 다음 다리의 구름 문이 걷힌다
------------------------------------------------------------------------
local activeMaze: { [Player]: any } = {}
local mazeSlots: { [number]: Player } = {}
local mazeRewardAt: { [Player]: number } = {}
local mazeChestHooked: { [number]: boolean } = {}

function Maze.active(player: Player): any
	return activeMaze[player]
end

local function mazePush(player: Player, run: any)
	local M = Config.MAZE
	local room = M.rooms[run.room]
	Push:FireClient(player, "maze", { room = run.room, total = #M.rooms, name = room and room.name or "", kind = room and room.kind or "", cleared = run.cleared })
end

-- 방 하나를 연다: 적이 나타나거나 (함정 방은 함정도), 보물방은 상자가 기다린다
function Maze.room(player: Player, run: any, i: number)
	local M = Config.MAZE
	local room = M.rooms[i]
	local f = Combat.fighterOfPlayer(player)
	if not room or not f or activeMaze[player] ~= run then
		return
	end
	run.room = i
	run.cleared = false
	run.token += 1
	local token = run.token
	run.alive = {}
	mazePush(player, run)
	local c = run.rooms.centers[i]
	if room.kind == "treasure" then
		run.chestOpen = false
		return
	end
	task.delay(1.6, function()
		if activeMaze[player] ~= run or run.token ~= token then
			return
		end
		local list = {}
		if room.kind == "boss" then
			table.insert(list, { room.boss, true })
		else
			for k = 1, room.count or 3 do
				table.insert(list, { room.enemies[(k - 1) % #room.enemies + 1], false })
			end
		end
		local pf = Combat.fighterOfPlayer(player)
		local mine = (pf and (pf :: any).power) or 100
		for k, item in ipairs(list) do
			local a = k / #list * math.pi * 2
			local at = c + Vector3.new(math.cos(a), 0, math.sin(a)) * (item[2] and 0 or M.roomRadius * 0.45)
			local e = Npc.spawn(item[1], item[2], at, "trial")
			if e then
				local ef = e.f :: any
				ef.mazeOwner = player
				ef.trialOwner = player
				local want = mine * M.power * (item[2] and M.bossPower or (room.power or 1))
				local kk = want / math.max(1, ef.power or 100)
				ef.maxHp = math.max(1, math.floor(ef.maxHp * kk * (item[2] and M.bossHp or 1)))
				ef.hp = ef.maxHp
				ef.dmgMult *= kk
				ef.power = math.floor(want)
				ef.rewardMult = 0.3
				ef.model:SetAttribute("Power", ef.power)
				ef.model:SetAttribute("Label", string.format("🌀 %s · %s", room.name, ef.name))
				Combat.sync(ef)
				e.target = pf
				run.alive[ef] = true
			end
		end
		-- 함정 방: 적이 남아 있는 동안 바닥에 원이 차오르고, 다 차면 벼락 (서리) 이 떨어진다
		if room.trap then
			local T = M.trap
			task.spawn(function()
				while activeMaze[player] == run and run.token == token and next(run.alive) do
					local me = Combat.fighterOfPlayer(player)
					if not me or me.dead then
						break
					end
					local spots = { Vector3.new(me.root.Position.X, c.Y + 2.4, me.root.Position.Z) }
					for _ = 1, T.count do
						local a, r = math.random() * math.pi * 2, math.random() * M.roomRadius * 0.85
						table.insert(spots, c + Vector3.new(math.cos(a) * r, 2.4, math.sin(a) * r))
					end
					local color = room.color
					for _, at in ipairs(spots) do
						Push:FireClient(player, "skillfx", { kind = "telegraph", at = at, radius = T.radius, time = T.warn, color = color })
					end
					task.wait(T.warn)
					if activeMaze[player] ~= run or run.token ~= token then
						break
					end
					for _, at in ipairs(spots) do
						Push:FireClient(player, "skillfx", { kind = "strike", at = at, radius = T.radius, color = color, fx = room.trap == "ice" and "ice" or nil })
					end
					local now = Combat.fighterOfPlayer(player)
					if now and not now.dead and os.clock() > now.iframeUntil then
						for _, at in ipairs(spots) do
							if Vector3.new(now.root.Position.X - at.X, 0, now.root.Position.Z - at.Z).Magnitude <= T.radius then
								now.hp -= now.maxHp * T.dmg
								Combat.sync(now)
								Push:FireClient(player, "toast", room.trap == "ice" and "❄ 서리 창에 맞았다!" or "⚡ 벼락에 맞았다!")
								if now.hp <= 0 then
									Combat.kill(now, nil)
								end
								break
							end
						end
					end
					task.wait(T.every - T.warn)
				end
			end)
		end
	end)
end

-- 방을 넘었다: 다음 다리의 구름 문을 걷는다. 마지막 방이면 다 넘은 것
function Maze.cleared(player: Player, run: any)
	local M = Config.MAZE
	run.cleared = true
	local gate = run.rooms.gates[run.room]
	if gate then
		World.mazeGate(gate, false)
	end
	if run.room >= #M.rooms then
		Maze.finish(player, run)
		return
	end
	mazePush(player, run)
	Push:FireClient(player, "mazeClear", { room = run.room, name = M.rooms[run.room].name })
end

function Maze.killed(player: Player, ef: any)
	local run = activeMaze[player]
	if not run or not run.alive[ef] then
		return
	end
	run.alive[ef] = nil
	-- 미궁의 적: 보통 처치 몫의 절반만큼 능력치
	local p = profiles[player]
	if p then
		local g = Config.killGain(ef.power or 100) * Config.MAZE.killGain * (ef.model:GetAttribute("Boss") == true and Config.KILL_GAIN.boss or 1) * gainMult(p)
		local each = math.max(1, math.floor(g / #Config.Stats))
		for _, sd in ipairs(Config.Stats) do
			p.stats[sd.id] += each
		end
		states[player].dirty = true
		refreshFighter(player)
	end
	if not next(run.alive) and not run.cleared then
		Maze.cleared(player, run)
	end
end

function Maze.finish(player: Player, run: any)
	local p, st = profiles[player], states[player]
	local M = Config.MAZE
	if p and st then
		local ready = os.clock() >= (mazeRewardAt[player] or 0)
		p.counts.maze = (p.counts.maze or 0) + 1
		local data = { first = ready, gems = 0, coins = 0, scrolls = 0, stats = 0 }
		if ready then
			mazeRewardAt[player] = os.clock() + M.cooldown
			local R = M.reward
			local each = math.max(1, math.floor(Config.killGain(rewardPower(player)) * R.statKills * gainMult(p) / #Config.Stats))
			for _, sd in ipairs(Config.Stats) do
				p.stats[sd.id] += each
			end
			p.skyGems += R.gems
			p.coins += R.coins
			p.scrolls += R.scrolls
			data.gems, data.coins, data.scrolls, data.stats = R.gems, R.coins, R.scrolls, each * #Config.Stats
			refreshFighter(player)
			Story.check(player)
		else
			data.wait = math.ceil((mazeRewardAt[player] - os.clock()) / 60)
		end
		st.dirty = true
		Push:FireClient(player, "mazeDone", data)
		pushState(player)
	end
	task.delay(4, function()
		if activeMaze[player] == run then
			Maze.ended(player, "done")
		end
	end)
end

-- reason: "done" / "dead" / "fall" / "leave" / "left"
function Maze.ended(player: Player, reason: string)
	local run = activeMaze[player]
	if not run then
		return
	end
	activeMaze[player] = nil
	run.token += 1
	mazeSlots[run.slot] = nil
	for ef in pairs(run.alive) do
		if not ef.dead then
			Npc.despawn(ef)
		end
	end
	run.alive = {}
	if reason == "left" then
		return
	end
	Push:FireClient(player, "maze", nil)
	Push:FireClient(player, "boss", nil)
	if reason ~= "done" then
		toast(player, string.format("🌀 구름 미궁 %d번째 방에서 멈췄어요", run.room))
	end
	if reason ~= "dead" then
		local char = player.Character
		if char and run.back then
			char:PivotTo(CFrame.new(run.back))
		end
	end
end

function Maze.start(player: Player, back: Vector3?, force: boolean?)
	local p, st = profiles[player], states[player]
	local f = Combat.fighterOfPlayer(player)
	local M = Config.MAZE
	if not p or not st or not f or f.dead or activeMaze[player] then
		return
	end
	if not force and Calc.realm(p) < Config.SKY.realm then
		toast(player, string.format("🌀 구름 미궁은 %s의 경지부터 들어갈 수 있어요", Config.Realms[Config.SKY.realm].name))
		return
	end
	if activeTrial[player] or activeGate[player] or activeTower[player] then
		toast(player, "다른 시련 중에는 들어갈 수 없어요")
		return
	end
	if f.combatUntil > os.clock() then
		toast(player, "싸우는 중에는 들어갈 수 없어요")
		return
	end
	local slot
	for i = 1, M.slots do
		if not mazeSlots[i] then
			slot = i
			break
		end
	end
	if not slot then
		toast(player, "🌀 미궁이 붐벼요. 잠시 뒤에 다시 오세요")
		return
	end
	local ok, rooms = pcall(World.mazeRooms, slot)
	if not ok then
		warn("[권왕] 구름 미궁 만들기 오류:", rooms)
		return
	end
	mazeSlots[slot] = player
	for _, g in pairs(rooms.gates) do
		World.mazeGate(g, true)
	end
	-- 보물 상자 (방마다 한 번, 주인만)
	if rooms.chest and not mazeChestHooked[slot] then
		mazeChestHooked[slot] = true
		rooms.chest.Triggered:Connect(function(who: Player)
			local r = activeMaze[who]
			local pp = profiles[who]
			if not r or r.slot ~= slot or not pp or r.chestOpen or M.rooms[r.room].kind ~= "treasure" then
				return
			end
			r.chestOpen = true
			pp.skyGems += M.chest.gems
			pp.coins += M.chest.coins
			states[who].dirty = true
			toast(who, string.format("🎁 보물 상자: 💎 %d  💰 %s", M.chest.gems, Config.formatNumber(M.chest.coins)))
			pushState(who)
			Maze.cleared(who, r)
		end)
	end
	Train.stop(player)
	Combat.dismount(f)
	local run = { slot = slot, rooms = rooms, room = 0, alive = {}, token = 0, cleared = false, back = back or (Config.SKY.islands[1].at + Vector3.new(0, 5, 30)) }
	activeMaze[player] = run
	local c1 = rooms.centers[1]
	local char = player.Character
	if char then
		local at = c1 + Vector3.new(0, 4, -Config.MAZE.roomRadius * 0.6)
		char:PivotTo(CFrame.lookAt(at, Vector3.new(c1.X, at.Y, c1.Z + 100)))
	end
	f.hp = f.maxHp
	f.chi = (f :: any).chiMax or Config.CHI_MAX
	Combat.sync(f)
	Maze.room(player, run, 1)
	-- 걸어서 다음 방에 들어서면 그 방이 열린다. 떨어지면 끝, 적이 떨어지면 쓰러뜨린 것으로
	task.spawn(function()
		local base = rooms.centers[1]
		while activeMaze[player] == run do
			task.wait(0.4)
			local ff = Combat.fighterOfPlayer(player)
			if activeMaze[player] ~= run then
				break
			end
			if ff and not ff.dead and ff.root.Position.Y < base.Y - 30 then
				Maze.ended(player, "fall")
				break
			end
			for ef in pairs(run.alive) do
				if not ef.dead and (not ef.root.Parent or ef.root.Position.Y < base.Y - 30) then
					Combat.kill(ef, ff)
				end
			end
			local nextC = rooms.centers[run.room + 1]
			if ff and run.cleared and nextC and Vector3.new(ff.root.Position.X - nextC.X, 0, ff.root.Position.Z - nextC.Z).Magnitude < Config.MAZE.roomRadius - 6 then
				Maze.room(player, run, run.room + 1)
			end
		end
	end)
end

------------------------------------------------------------------------
-- 심법 뽑기: 두루마리를 먼저 쓰고, 없으면 은자. 같은 심법이 더 높은 등급으로 나오면 바뀐다
------------------------------------------------------------------------
local Manual = {}

local function rollRarity(p: Profile): number
	local D = Config.MANUAL_DRAW
	if p.pity + 1 >= D.pity then
		local r = math.random()
		return r < 0.02 and 6 or (r < 0.12 and 5 or 4)
	end
	local r, acc = math.random(), 0
	for i, R in ipairs(Config.MANUAL_RARITY) do
		acc += R.rate
		if r < acc then
			return i
		end
	end
	return 1
end

function Manual.draw(player: Player, nArg: any)
	local p, st = profiles[player], states[player]
	if not p or not st then
		return
	end
	local D = Config.MANUAL_DRAW
	local n = tonumber(nArg) == 10 and 10 or 1
	local useScroll = math.min(p.scrolls, n)
	local coinCost = (n - useScroll) * D.coins
	if p.coins < coinCost then
		toast(player, string.format("은자가 부족해요 (두루마리가 없으면 한 번에 💰 %s)", Config.formatNumber(D.coins)))
		return
	end
	p.scrolls -= useScroll
	p.coins -= coinCost
	local results = {}
	for _ = 1, n do
		local r = rollRarity(p)
		p.pity = r >= 4 and 0 or p.pity + 1
		local m = Config.MANUALS[math.random(#Config.MANUALS)]
		local had = p.manuals[m.id]
		local res: any = { id = m.id, r = r }
		if had and had >= r then
			res.refund = D.refund * r
			p.coins += res.refund
		else
			res.up = had ~= nil
			p.manuals[m.id] = r
			-- 빈 칸이 있으면 바로 끼운다
			if not table.find(p.equip, m.id) and #p.equip < D.slots then
				table.insert(p.equip, m.id)
			end
		end
		table.insert(results, res)
	end
	st.dirty = true
	refreshFighter(player)
	Push:FireClient(player, "manualDraw", results)
	pushState(player)
end

function Manual.equip(player: Player, id: any, on: boolean)
	local p, st = profiles[player], states[player]
	if not p or not st or type(id) ~= "string" or not p.manuals[id] then
		return
	end
	local i = table.find(p.equip, id)
	if on and not i then
		if #p.equip >= Config.MANUAL_DRAW.slots then
			toast(player, "심법 칸이 가득 찼어요. 하나를 빼고 끼우세요")
			return
		end
		table.insert(p.equip, id)
	elseif not on and i then
		table.remove(p.equip, i)
	end
	st.dirty = true
	refreshFighter(player)
	pushState(player)
end

Train = {}

function Train.start(player: Player, info: any, hard: boolean?)
	local p, st = profiles[player], states[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not st or not f or f.dead then
		return
	end
	Combat.dismount(f)
	if f.combatUntil > os.clock() then
		toast(player, "싸우는 중에는 수련할 수 없어요")
		return
	end
	local kindInfo = Config.Training[info.kind]
	local realmIdx = Calc.realm(p)
	if kindInfo and kindInfo.realm and realmIdx < kindInfo.realm then
		toast(player, string.format("%s %s은(는) 경지 %s부터 할 수 있어요", kindInfo.icon, kindInfo.name, Config.Realms[kindInfo.realm].name))
		return
	end
	-- 심마 대련: 마음속의 마귀를 불러내 싸운다 (이기면 모든 능력치)
	if kindInfo and kindInfo.fight then
		local t = os.clock()
		if t - (st.simmaAt or 0) < 60 then
			toast(player, string.format("👁 심마가 아직 가라앉지 않았어요 (%d초)", math.ceil(60 - (t - st.simmaAt))))
			return
		end
		st.simmaAt = t
		local e = Npc.spawn("simma", false, info.pos + Vector3.new(0, 0, -14), "simma")
		if e then
			(e.f :: any).simmaOwner = player
			e.target = f
			Push:FireAllClients("simma", e.f.model)
			toast(player, "👁 심마가 형체를 얻었다! 이기면 모든 능력치가 크게 오른다")
		end
		return
	end
	if hard and realmIdx < Config.HARD_TRAIN.realm then
		toast(player, string.format("🔥 강화 수련은 경지 %s부터 할 수 있어요", Config.Realms[Config.HARD_TRAIN.realm].name))
		return
	end
	st.training = { kind = info.kind, index = info.index, pos = info.pos, hard = hard == true }
	st.ringIdx = 1
	if info.kind ~= "bamboo" then
		local char = player.Character
		local at = info.pos + Vector3.new(0, 3.5, info.kind == "waterfall" and 0 or 5)
		if char then
			char:PivotTo(CFrame.lookAt(at, Vector3.new(info.pos.X, at.Y, info.pos.Z) + (info.kind == "waterfall" and Vector3.new(1, 0, 0) or Vector3.new(0, 0, 0))))
		end
		f.walk = 0
	end
	Push:FireClient(player, "train", { kind = info.kind, rings = info.kind == "bamboo" and W.rings or nil, hard = hard == true })
	Push:FireAllClients("trainPose", f.model, info.kind)
	pushState(player)
end

function Train.stop(player: Player)
	local st = states[player]
	local f = Combat.fighterOfPlayer(player)
	if not st or not st.training then
		return
	end
	st.training = nil
	if f then
		Push:FireAllClients("trainPose", f.model, nil)
	end
	refreshFighter(player)
	Push:FireClient(player, "train", nil)
	pushState(player)
end

-- grade: "perfect" / "good" / "miss", 경공은 ring 번호
function Train.hit(player: Player, grade: any, ringArg: any)
	local p, st = profiles[player], states[player]
	if not p or not st or not st.training then
		return
	end
	local t = os.clock()
	if t - st.trainAt < Config.TRAIN_COOLDOWN then
		return
	end
	local kind = st.training.kind
	local info = Config.Training[kind]
	local gain = 0
	if kind == "bamboo" then
		local idx = math.floor(tonumber(ringArg) or 0)
		local pos = W.rings[idx]
		local f = Combat.fighterOfPlayer(player)
		if not pos or not f or idx ~= st.ringIdx or (f.root.Position - pos).Magnitude > 12 then
			return
		end
		st.ringIdx = idx % #W.rings + 1
		gain = info.base * 2
	else
		if grade == "perfect" then
			gain = info.base * 2
		elseif grade == "good" then
			gain = info.base
		else
			gain = 0
		end
	end
	st.trainAt = t
	if gain <= 0 then
		Push:FireClient(player, "trained", { stat = info.stat, gain = 0, grade = grade })
		return
	end
	-- 경지가 오를수록, 소환단을 먹었으면 더 많이
	local idx = Calc.realm(p)
	local mult = Config.TRAIN_GAIN * (1 + Config.TRAIN_REALM_BONUS * (idx - 1)) * (p.elixirUntil > os.time() and 2 or 1) * (st.training.hard and Config.HARD_TRAIN.mult or 1) * (Premium.owns(player, "train2x") and 2 or 1) * gainMult(p)
	local amount = math.max(1, math.floor(gain * mult + 0.5))
	local beforeIdx = idx
	if info.gains then
		-- 여러 능력치가 함께 오르는 수련
		for stat, k in pairs(info.gains) do
			p.stats[stat] += math.max(1, math.floor(gain * k * mult + 0.5))
		end
		amount = math.max(1, math.floor(gain * (info.gains[info.stat] or 1) * mult + 0.5))
	else
		p.stats[info.stat] += amount
	end
	st.dirty = true
	local afterIdx, realm = Calc.realm(p)
	Push:FireClient(player, "trained", { stat = info.stat, gain = amount, grade = grade, total = p.stats[info.stat], ring = st.ringIdx })
	if afterIdx > beforeIdx then
		Push:FireAllClients("realm", { name = player.DisplayName, realm = realm.name })
	end
	Gate.notify(player, p, st)
	Story.event(player, "train")
	refreshFighter(player)
	if st.training and kind ~= "bamboo" then
		local f = Combat.fighterOfPlayer(player)
		if f then
			f.walk = 0
		end
	end
	pushState(player)
end

-- 수련 자리를 벗어나면 끝 (경공은 숲을 벗어나면)
task.spawn(function()
	while true do
		task.wait(0.5)
		for player, st in pairs(states) do
			local tr = st.training
			local f = Combat.fighterOfPlayer(player)
			if tr and f then
				local limit = tr.kind == "bamboo" and 140 or 12
				if (Vector3.new(f.root.Position.X, 0, f.root.Position.Z) - Vector3.new(tr.pos.X, 0, tr.pos.Z)).Magnitude > limit or f.combatUntil > os.clock() then
					Train.stop(player)
				end
			end
		end
	end
end)

------------------------------------------------------------------------
-- 시험용 (테스트 계정)
------------------------------------------------------------------------
local function testAction(player: Player, p: Profile, action: string, arg: any)
	local f = Combat.fighterOfPlayer(player)
	if action == "testCoins" then
		p.coins += math.clamp(tonumber(arg) or 1000, 0, 1e9)
	elseif action == "testStats" then
		for _, s in ipairs(Config.Stats) do
			p.stats[s.id] += math.clamp(tonumber(arg) or 100, 0, 1e11)
		end
		-- 테스트: 닿은 경지까지 관문도 모두 넘긴다
		for i = Config.GATE.from, Config.realmOf(Calc.total(p), Config.realmCap(p.rebirth)) do
			p.gates[tostring(i)] = true
		end
	elseif action == "testRebirthReady" then
		-- 테스트: 지금 열린 끝 경지까지 능력치를 채우고 관문도 넘긴다 (바로 환생할 수 있게)
		local cap = Config.realmCap(p.rebirth)
		local each = math.ceil(Config.Realms[cap].need / #Config.Stats) + 1
		for _, s in ipairs(Config.Stats) do
			p.stats[s.id] = math.max(p.stats[s.id], each)
		end
		for i = Config.GATE.from, cap do
			p.gates[tostring(i)] = true
		end
		toast(player, "♻ 환생 준비 완료 (" .. Config.Realms[cap].name .. ")")
	elseif action == "testRebirthReset" then
		p.rebirth = 0
		p.ach = {}
		p.title = nil
		toast(player, "♻ 환생·업적 기록을 지웠어요")
	elseif action == "testGateReset" then
		p.gates = {}
		toast(player, "⛩ 관문 기록을 지웠어요")
	elseif action == "testMastery" then
		if p.style ~= "" then
			local m = Calc.mastery(p, p.style)
			m.lv = Config.MASTERY_MAX
			m.xp = 0
		end
	elseif action == "testChi" then
		-- 켜고 끄는 스위치: 켜 두면 내공이 늘 가득, 기술 쿨이 없다
		if arg == "on" then
			TEST_INF[player] = true
		elseif arg == "off" then
			TEST_INF[player] = nil
		else
			TEST_INF[player] = not TEST_INF[player] or nil
		end
		if f then
			f.chi = (f :: any).chiMax or Config.CHI_MAX
			f.cds = {}
			f.model:SetAttribute("TestInf", TEST_INF[player] == true)
		end
		toast(player, TEST_INF[player] and "🌀 내공 무한·쿨 없음: 켜짐" or "🌀 내공 무한·쿨 없음: 꺼짐")
	elseif action == "testHeal" then
		if f then
			f.hp = f.maxHp
			f.posture = 0
		end
	elseif action == "testBoss" then
		if f then
			Npc.spawn(type(arg) == "string" and Config.Bosses[arg] and arg or "heukho", true, f.root.Position + Combat.look(f) * 30, "test")
		end
	elseif action == "testPremium" then
		-- 테스트: 로벅스 상품을 써 보기 (진짜 구매 아님)
		if type(arg) == "string" and Config.PREMIUM_BY_ID[arg] then
			Premium.grant(player, arg)
			toast(player, "💎 테스트로 켰어요: " .. Config.PREMIUM_BY_ID[arg].name)
		end
	elseif action == "testDummy" then
		if f then
			Npc.spawn("dummy", false, f.root.Position + Combat.look(f) * 12, "test")
		end
	elseif action == "testClear" then
		-- 테스트로 부른 적·목인을 모두 치운다
		for i = #Npc.list, 1, -1 do
			local e = Npc.list[i]
			if e.region == "test" then
				Npc.despawn(e.f)
			end
		end
		-- 진행 중인 시험·각성 시련도 거둔다
		Trial.ended(player, false)
		Gate.ended(player, false)
		Tower.ended(player, "leave")
	elseif action == "testScrolls" then
		p.scrolls += 10
		toast(player, "📜 두루마리 +10")
	elseif action == "testPvp" then
		-- 비무 승리를 백 승 바로 앞까지 (한 번 더 이기면 무쌍신권)
		p.pvpWins = math.max(p.pvpWins, Config.PVP_STYLE.wins - 1)
		toast(player, string.format("⚔ 비무 %d승 (한 번 더 이기면 무쌍신권)", p.pvpWins))
	elseif action == "testTower" then
		-- 천층탑: 지금 층의 적을 걷고 다음 보스 층 바로 앞으로
		local run = Tower.active(player)
		if run and arg == "clear" then
			-- 지금 층의 적을 모두 쓰러뜨린다 (층 돌파 확인)
			for ef in pairs(run.alive) do
				if not ef.dead then
					Combat.kill(ef, f)
				end
			end
		elseif run then
			for ef in pairs(run.alive) do
				if not ef.dead then
					Npc.despawn(ef)
				end
			end
			run.alive = {}
			run.floor = math.max(run.floor, (math.floor(run.floor / Config.TOWER.bossEvery) + 1) * Config.TOWER.bossEvery - 1)
			Tower.next(player, run)
		else
			toast(player, "천층탑 안에서 쓰세요")
		end
	elseif action == "testPvpUnlock" then
		p.pvpUnlocked = true
		toast(player, "⚔ PvP 끄기를 열었어요")
	elseif action == "testGems" then
		p.skyGems += 1000
		toast(player, "💠 천정 +1000")
	elseif action == "testMeteor" then
		_G.KwonMeteorNow = true
	elseif action == "testMaze" then
		Maze.start(player, nil, true)
	elseif action == "testMazeSkip" then
		-- (시험용) 지금 미궁 방의 적을 모두 쓰러뜨린다
		local run = Maze.active(player)
		if run and f then
			for ef in pairs(run.alive) do
				if not ef.dead then
					Combat.kill(ef, f)
				end
			end
		end
	elseif action == "testRaidKill" then
		-- (시험용) 지금 레이드 보스를 내 몫 절반으로 쓰러뜨린다
		local c = Raid.cur
		if c and f then
			c.dmg[player] = (c.dmg[player] or 0) + c.f.maxHp * 0.5
			Combat.kill(c.f, f)
		end
	elseif action == "testRaid" then
		_G.KwonRaidNow = true
		toast(player, "⚔ 곧 천겁이 내려와요 (천상계에 있어야 해요)")
	elseif action == "testSky" then
		-- 천상계로 바로 (경지와 상관없이)
		if f then
			Combat.dismount(f)
			f.root.CFrame = CFrame.new(Config.SKY.islands[1].at + Vector3.new(0, 5, 30))
			toast(player, "☁ 천상계 · 천궁")
		end
	elseif action == "testSeen" then
		p.seen = {}
		toast(player, "🎬 컷씬 기록을 지웠어요")
	elseif action == "testTime" then
		if arg == "freeze" then
			toast(player, World.toggleClockFreeze() and "⏸ 시간이 멈췄어요" or "▶ 시간이 다시 흘러요")
		elseif arg == "+3" then
			World.setClock(World.clockHour() + 3)
		else
			World.setClock(tonumber(arg) or 12)
		end
	elseif action == "testEnemy" then
		if f then
			local id = type(arg) == "string" and Config.Enemies[arg] and arg or "bandit"
			Npc.spawn(id, false, f.root.Position + Combat.look(f) * 18, "test")
		end
	elseif action == "testDie" then
		if f then
			Combat.kill(f, nil)
		end
	elseif action == "testStory" then
		Story.advance(player)
		Story.accept(player)
	elseif action == "testTrial" then
		if activeTrial[player] then
			Trial.ended(player, true)
		end
		for id in pairs(Config.MASTERS) do
			p.found[id] = true
			p.trials[id] = true
		end
	elseif action == "testTp" then
		-- 다음 사부에게 순간이동
		if f then
			local st = states[player]
			st.tpIdx = ((st.tpIdx or 0) :: number) % #Config.Styles + 1
			local m = Config.MASTERS[Config.Styles[st.tpIdx].id]
			if m then
				f.root.CFrame = CFrame.new(m.at + Vector3.new(0, 4, 12))
				toast(player, "🌀 " .. m.region .. " · " .. m.name)
			end
		end
	elseif action == "testStyle" then
		-- 권법 테스트: 어떤 권법이든 (숨은 것도) 바로 익혀 숙련 최대로 쓴다
		local sd = type(arg) == "string" and Config.STYLE_BY_ID[arg]
		if sd then
			p.styles[sd.id] = true
			p.style = sd.id
			local m = Calc.mastery(p, sd.id)
			m.lv = Config.MASTERY_MAX
			m.xp = 0
			if f then
				f.chi = (f :: any).chiMax or Config.CHI_MAX
			end
			Push:FireClient(player, "learned", { style = sd.id, hidden = sd.hidden == true })
		end
	elseif action == "testTrainTp" then
		-- 수련 자리로 순간이동
		if f and type(arg) == "string" then
			for _, spot in ipairs(Config.TrainingSpots) do
				if spot.kind == arg then
					f.root.CFrame = CFrame.lookAt(spot.at + Vector3.new(0, 5, 7), spot.at + Vector3.new(0, 5, 0))
					local t = Config.Training[arg]
					toast(player, "🌀 " .. (t and (t.icon .. " " .. t.name) or arg))
					break
				end
			end
		end
	elseif action == "testSecretMaster" then
		-- 숨은 사부 곁으로
		if f then
			local m = Config.MASTERS[type(arg) == "string" and arg or "gaecheon"] or Config.MASTERS.gaecheon
			f.root.CFrame = CFrame.new(m.at + Vector3.new(0, 4, 10))
			toast(player, "🧭 " .. m.name .. " (" .. m.region .. ")")
		end
	elseif action == "testBreak" then
		if p.style ~= "" then
			p.gradeUp[p.style] = #Config.BREAKTHROUGH
		end
	elseif action == "testSecret" then
		-- 시크릿 테스트: 숨은 권법을 진짜 길로 얻어 본다
		if arg == "fragment" then
			for i = 1, #Config.Fragments do
				if not p.fragments[tostring(i)] then
					p.fragments[tostring(i)] = true
					local n = countKeys(p.fragments)
					Push:FireClient(player, "fragment", { n = n, total = #Config.Fragments })
					if n >= #Config.Fragments then
						grantStyle(player, "mugeuk", true)
					end
					Story.event(player, "fragment")
					break
				end
			end
		elseif arg == "fragmentTp" then
			for i, fr in ipairs(Config.Fragments) do
				if not p.fragments[tostring(i)] and f then
					f.root.CFrame = CFrame.new(fr.at + Vector3.new(0, 4, 8))
					toast(player, "📖 비급 조각: " .. (fr.hint or ""))
					break
				end
			end
		elseif arg == "mugeuk" then
			for i = 1, #Config.Fragments do
				p.fragments[tostring(i)] = true
			end
			Push:FireClient(player, "fragment", { n = #Config.Fragments, total = #Config.Fragments })
			grantStyle(player, "mugeuk", true)
		elseif arg == "hyeolma" then
			grantStyle(player, "hyeolma", true)
		elseif arg == "pacheon" then
			grantStyle(player, "pacheon", true)
		elseif arg == "lock" then
			-- 숨은 권법을 다시 잠근다 (처음부터 다시 얻어 보기)
			p.styles.mugeuk = nil :: any
			p.styles.hyeolma = nil :: any
			p.styles.gaecheon = nil :: any
			p.styles.pacheon = nil :: any
			p.styles.taecho = nil :: any
			p.styles.ilwol = nil :: any
			p.styles.yeonggeop = nil :: any
			p.trials.yeonggeop = nil :: any
			p.styles.musang = nil :: any
			p.styles.agong = nil :: any
			p.styles.seongha = nil :: any
			p.trials.seongha = nil :: any
			p.trials.agong = nil :: any
			p.styles.hyeolma2 = nil :: any
			p.styles.cheonryong2 = nil :: any
			p.styles.byeokryeok2 = nil :: any
			p.trials.taecho = nil :: any
			p.trials.gaecheon = nil :: any
			p.trials.ilwol = nil :: any
			p.fragments = {}
			if p.style == "mugeuk" or p.style == "hyeolma" or p.style == "gaecheon" or p.style == "pacheon" or p.style == "taecho" or p.style == "ilwol" or p.style == "yeonggeop" or (Config.STYLE_BY_ID[p.style] and Config.STYLE_BY_ID[p.style].awakenOf) then
				p.style = "samjae"
			end
		end
	elseif action == "testReset" then
		profiles[player] = defaultProfile()
	else
		return
	end
	refreshFighter(player)
	if f then
		Combat.sync(f)
	end
	updateTag(player)
	pushState(player)
	Story.check(player)
end

------------------------------------------------------------------------
-- 요청 받기
------------------------------------------------------------------------
Request.OnServerEvent:Connect(function(player: Player, action: any, a1: any, a2: any, a3: any)
	local p, st = profiles[player], states[player]
	if not p or not st or type(action) ~= "string" then
		return
	end
	local t = os.clock()
	if t - st.reqWindow > 1 then
		st.reqWindow = t
		st.reqCount = 0
	end
	st.reqCount += 1
	if st.reqCount > 60 then
		return
	end
	if st.training and (action == "act" or action == "dash") then
		Train.stop(player)
	end
	if action == "act" then
		Actions.act(player, a1, a2, a3)
	elseif action == "hit" then
		Actions.hit(player, a1, a2, a3)
	elseif action == "guard" then
		Actions.guard(player, a1)
	elseif action == "dash" then
		Actions.dash(player, a1)
	elseif action == "emote" then
		local f = Combat.fighterOfPlayer(player)
		if f and not f.dead and not Combat.busy(f) and type(a1) == "string" and #a1 < 20 then
			Push:FireAllClients("emote", f.model, a1)
		end
	elseif action == "sprint" then
		local f = Combat.fighterOfPlayer(player)
		if f then
			(f :: any).sprint = a1 == true
			f.model:SetAttribute("Sprint", a1 == true or nil)
		end
	elseif action == "djump" then
		local f = Combat.fighterOfPlayer(player)
		if f then
			Push:FireAllClients("djump", f.model)
		end
	elseif action == "potion" then
		Actions.potion(player)
	elseif action == "learn" then
		Actions.learn(player, a1)
	elseif action == "buy" then
		Actions.buy(player, a1)
	elseif action == "trainHit" then
		Train.hit(player, a1, a2)
	elseif action == "trainStop" then
		Train.stop(player)
	elseif action == "hello" then
		pushState(player)
		if st.tester then
			toast(player, "🧪 테스트 계정이에요. 기록은 저장하지 않아요")
		elseif not st.canSave then
			toast(player, "저장이 꺼져 있어요. 이번 기록은 저장되지 않아요")
		end
		-- 이야기 첫 장이면 장로를 찾아가라고
		if p.story == 1 and not cutscene(player, "intro", { at = Config.ELDER_AT }) then
			Push:FireClient(player, "dialog", { who = "강호", title = "권왕: 맨손의 강호", text = "맨손 하나로 강호를 꺾어라. 먼저 마을의 청운 장로를 찾아가 말을 걸어 보자. (노란 길잡이를 따라가서 T)" })
		end
	elseif action == "talkElder" then
		Story.talk(player)
	elseif action == "storyAccept" then
		Story.accept(player)
	elseif action == "premiumBuy" then
		Premium.prompt(player, tostring(a1))
	elseif action == "autoToggle" then
		-- 자동 수련 켜기·끄기 (게임패스가 있어야)
		if not (Premium.owns(player, "autoTrain") or Premium.owns(player, "autoTrain2")) then
			toast(player, "🤖 자동 수련 게임패스가 있어야 해요 (만물상)")
			return
		end
		p.autoOn = not p.autoOn or nil
		st.dirty = true
		toast(player, p.autoOn and "🤖 자동 수련을 켰어요" or "🤖 자동 수련을 껐어요")
		pushState(player)
	elseif action == "autoStat" then
		-- 자동 수련으로 올릴 능력치 차례로 바꾸기: 골고루 → 근골 → 체력 → 경공 → 내공
		local order = { "all", "str", "vit", "agi", "chi" }
		local i = table.find(order, p.autoStat or "all") or 1
		p.autoStat = order[i % #order + 1]
		st.dirty = true
		pushState(player)
	elseif action == "gate" then
		Gate.start(player)
	elseif action == "rebirth" then
		Rebirth.go(player)
	elseif action == "title" then
		-- 칭호 달기 (이룬 업적 중 칭호가 있는 것), 빈 글이면 뗀다
		local id = tostring(a1 or "")
		if id == "" then
			p.title = nil
		elseif p.ach[id] and Config.ACH_BY_ID[id] and Config.ACH_BY_ID[id].title then
			p.title = id
		else
			return
		end
		st.dirty = true
		updateTag(player)
		pushState(player)
	elseif action == "mount" then
		-- 탈것 타기·내리기
		local f = Combat.fighterOfPlayer(player)
		if not f or f.dead then
			return
		end
		if f.model:GetAttribute("Mount") then
			Combat.dismount(f)
			return
		end
		if f.combatUntil > os.clock() then
			toast(player, "싸우는 중에는 탈 수 없어요")
			return
		end
		if st.training or Tower.active(player) then
			toast(player, "지금은 탈 수 없어요")
			return
		end
		-- 게임패스가 없어진 로벅스 탈것은 갈색 말로
		local sel = Config.MOUNT_BY_ID[p.mountSel]
		if sel and sel.premium and not Premium.owns(player, sel.premium) then
			p.mountSel = "horse"
		end
		Combat.mount(f, p.mountSel)
	elseif action == "mountBuy" or action == "mountSelect" then
		local m = type(a1) == "string" and Config.MOUNT_BY_ID[a1]
		if not m then
			return
		end
		-- 로벅스 탈것: 게임패스가 있어야 고를 수 있다
		if m.premium then
			if not Premium.owns(player, m.premium) then
				Premium.prompt(player, m.premium)
				return
			end
		elseif not p.mounts[m.id] then
			if action ~= "mountBuy" then
				return
			end
			if p.coins < m.cost then
				toast(player, string.format("은자가 부족해요 (💰 %s 필요)", Config.formatNumber(m.cost)))
				return
			end
			p.coins -= m.cost
			p.mounts[m.id] = true
			toast(player, m.icon .. " " .. m.name .. "을(를) 얻었어요! (V로 타기)")
		end
		p.mountSel = m.id
		st.dirty = true
		local f = Combat.fighterOfPlayer(player)
		if f and f.model:GetAttribute("Mount") then
			Combat.mount(f, m.id)
		end
		pushState(player)
	elseif action == "skyBuy" then
		-- 천상 상점 (천정으로)
		local it = type(a1) == "string" and Config.SKY_SHOP_BY_ID[a1]
		if not it then
			return
		end
		if it.id == "cloudmount" and p.mounts.cloud then
			toast(player, "☁ 이미 날개구름이 있어요")
			return
		end
		if p.skyGems < it.cost then
			toast(player, string.format("💠 천정이 부족해요 (%d 필요)", it.cost))
			return
		end
		p.skyGems -= it.cost
		if it.id == "skyscroll" then
			p.scrolls += 1
		elseif it.id == "skyscroll10" then
			p.scrolls += 10
		elseif it.id == "skyelixir" then
			p.skyBuffUntil = math.max(os.time(), p.skyBuffUntil) + 600
			task.delay(601, function()
				if player.Parent then
					refreshFighter(player)
					pushState(player)
				end
			end)
		elseif it.id == "skypill" then
			for _, sd in ipairs(Config.Stats) do
				p.stats[sd.id] += 800
			end
			Story.check(player)
		elseif it.id == "cloudmount" then
			p.mounts.cloud = true
			p.mountSel = "cloud"
		end
		st.dirty = true
		refreshFighter(player)
		updateTag(player)
		toast(player, it.icon .. " " .. it.name .. "을(를) 샀어요")
		pushState(player)
	elseif action == "pvpToggle" then
		-- 들판 PvP 켜기·끄기 (한 번 쓰러진 뒤부터, 싸우는 중에는 못 바꾼다)
		local f = Combat.fighterOfPlayer(player)
		if not p.pvpUnlocked then
			toast(player, "⚔ 한 번 쓰러진 뒤부터 PvP를 끌 수 있어요")
			return
		end
		if f and f.combatUntil > os.clock() then
			toast(player, "싸우는 중에는 PvP를 바꿀 수 없어요")
			return
		end
		if t - ((st :: any).pvpAt or -999) < Config.PVP.toggleCooldown then
			toast(player, string.format("⚔ %d초 뒤에 다시 바꿀 수 있어요", math.ceil(Config.PVP.toggleCooldown - (t - (st :: any).pvpAt))))
			return
		end
		;(st :: any).pvpAt = t
		p.pvpOff = not p.pvpOff or nil
		st.dirty = true
		if f then
			f.model:SetAttribute("PvpOff", p.pvpOff == true)
		end
		toast(player, p.pvpOff and "🕊 들판 PvP를 껐어요 (비무대는 그대로)" or "⚔ 들판 PvP를 켰어요")
		pushState(player)
	elseif action == "towerLeave" then
		Tower.ended(player, "leave")
	elseif action == "towerTp" then
		Tower.teleport(player)
	elseif action == "mazeLeave" then
		Maze.ended(player, "leave")
	elseif action == "manualDraw" then
		Manual.draw(player, a1)
	elseif action == "manualEquip" then
		Manual.equip(player, a1, true)
	elseif action == "manualUnequip" then
		Manual.equip(player, a1, false)
	elseif action == "seen" then
		-- 화면에서 본 것 (조작 안내, 보스와 처음 맞붙는 컷씬)
		if type(a1) == "string" and not p.seen[a1] and (a1 == "controls" or (string.sub(a1, 1, 5) == "boss_" and Config.CUTSCENES[a1] ~= nil)) then
			p.seen[a1] = true
			st.dirty = true
			-- 컷씬을 보는 동안은 맞지 않는다
			local f = Combat.fighterOfPlayer(player)
			if f and a1 ~= "controls" then
				f.iframeUntil = math.max(f.iframeUntil, os.clock() + 5)
			end
		end
	elseif action == "awaken" then
		-- 각성 (진 권법): 원래 권법 숙련 최대 + 깨달음 모두 + 경지 + 은자 → 각성 시련
		local base = type(a1) == "string" and Config.STYLE_BY_ID[a1]
		local v2 = nil
		for _, sd in ipairs(Config.Styles) do
			if base and sd.awakenOf == base.id then
				v2 = sd
			end
		end
		if not base or not v2 or not p.styles[base.id] or p.styles[v2.id] then
			return
		end
		local A = Config.AWAKEN_STYLE
		local f0 = Combat.fighterOfPlayer(player)
		if Calc.mastery(p, base.id).lv < Config.MASTERY_MAX then
			toast(player, string.format("각성하려면 %s 숙련 %d이 필요해요", base.name, Config.MASTERY_MAX))
		elseif (p.gradeUp[base.id] or 0) < #Config.BREAKTHROUGH then
			toast(player, "각성하려면 먼저 깨달음(승급)을 모두 얻어야 해요")
		elseif Calc.realm(p) < A.realm then
			toast(player, string.format("각성은 %s의 경지부터예요", Config.Realms[A.realm].name))
		elseif (v2.rebirthReq or 0) > p.rebirth then
			toast(player, string.format("%s은(는) 환생을 %d번 한 몸이라야 깨어나요", v2.name, v2.rebirthReq))
		elseif p.coins < A.coins then
			toast(player, string.format("은자가 부족해요 (💰 %s 필요)", Config.formatNumber(A.coins)))
		elseif f0 and f0.combatUntil > os.clock() then
			toast(player, "싸우는 중에는 각성할 수 없어요")
		else
			Trial.start(player, v2.id)
		end
	elseif action == "breakthrough" then
		-- 권법 승급 (깨달음): 숙련 10, 경지, 은자
		local sd = type(a1) == "string" and Config.STYLE_BY_ID[a1]
		if not sd or not p.styles[sd.id] then
			return
		end
		local ups = p.gradeUp[sd.id] or 0
		local step = Config.BREAKTHROUGH[ups + 1]
		if not step then
			toast(player, "더 오를 깨달음이 없어요")
			return
		elseif Calc.mastery(p, sd.id).lv < Config.MASTERY_MAX then
			toast(player, string.format("승급하려면 %s 숙련 %d이 필요해요", sd.name, Config.MASTERY_MAX))
			return
		elseif Calc.realm(p) < step.realm then
			toast(player, string.format("%s은(는) %s의 경지부터예요", step.name, Config.Realms[step.realm].name))
			return
		elseif p.coins < step.coins then
			toast(player, string.format("은자가 부족해요 (💰 %s 필요)", Config.formatNumber(step.coins)))
			return
		end
		p.coins -= step.coins
		p.gradeUp[sd.id] = ups + 1
		st.dirty = true
		Push:FireClient(player, "breakthrough", { style = sd.id, grade = Config.styleGrade(sd, ups + 1), step = step.name })
		refreshFighter(player)
		pushState(player)
	elseif string.sub(action, 1, 4) == "test" and st.tester then
		testAction(player, p, action, a1)
	end
end)

-- 월드의 T 누르기
if W.shop then
	W.shop.Triggered:Connect(function(player: Player)
		Push:FireClient(player, "open", { page = "shop" })
	end)
end
-- 객잔: 쉬면 체력과 내공이 가득 찬다 (공짜)
if W.tower then
	W.tower.Triggered:Connect(function(player: Player)
		Tower.start(player)
	end)
end
-- 천궁의 미궁 문: 미궁에 들어가고, 끝나면 문 앞으로 돌아온다
if W.mazeGate then
	W.mazeGate.Triggered:Connect(function(player: Player)
		local gate = W.mazeGate.Parent
		local back = (gate and gate:IsA("BasePart")) and (gate.Position + Vector3.new(0, 3, 0) + Vector3.new(-gate.Position.X, 0, -gate.Position.Z).Unit * 8) or nil
		Maze.start(player, back)
	end)
end
-- 천궁의 탑 문: 바로 탑에 오르고, 끝나면 천궁으로 돌아온다
if W.towerGate then
	W.towerGate.Triggered:Connect(function(player: Player)
		local gate = W.towerGate.Parent
		local back = (gate and gate:IsA("BasePart")) and (gate.Position + Vector3.new(0, 3, 0) + Vector3.new(-gate.Position.X, 0, -gate.Position.Z).Unit * 8) or nil
		Tower.start(player, back)
	end)
end

-- 천상계 오르내리기
local function toSky(player: Player)
	local p = profiles[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not f or f.dead then
		return
	end
	if Calc.realm(p) < Config.SKY.realm then
		toast(player, string.format("☁ 천상계는 %s의 경지부터 오를 수 있어요", Config.Realms[Config.SKY.realm].name))
		return
	end
	if f.combatUntil > os.clock() then
		toast(player, "싸우는 중에는 오를 수 없어요")
		return
	end
	Train.stop(player)
	Combat.dismount(f)
	local char = player.Character
	if char then
		local at = Config.SKY.islands[1].at + Vector3.new(0, 5, 30)
		char:PivotTo(CFrame.lookAt(at, at + Vector3.new(0, 0, -1)))
	end
	if not cutscene(player, "sky_first", { at = Config.SKY.islands[1].at }) then
		toast(player, "☁ 천상계 · 천궁")
	end
end
if W.skyUp then
	W.skyUp.Triggered:Connect(toSky)
end
if W.skyDown then
	W.skyDown.Triggered:Connect(function(player: Player)
		local char = player.Character
		local f = Combat.fighterOfPlayer(player)
		if char and f and not f.dead then
			Combat.dismount(f)
			char:PivotTo(CFrame.new(Config.SKY.portal + Vector3.new(10, 5, 10)))
			toast(player, "⬇ 강호로 내려왔어요")
		end
	end)
end

-- 천상계에서 떨어지면: 사람은 천궁으로 되돌리고, 적은 쓰러뜨린 것으로 친다 (땅으로 떨어지지 않게)
task.spawn(function()
	local Y = Config.SKY.y
	while true do
		task.wait(0.5)
		for player in pairs(profiles) do
			local f = Combat.fighterOfPlayer(player)
			if f and not f.dead then
				local y = f.root.Position.Y
				if y < Y - 60 and y > Y - 1600 then
					f.root.AssemblyLinearVelocity = Vector3.zero
					f.root.CFrame = CFrame.new(Config.SKY.islands[1].at + Vector3.new(0, 5, 30))
					toast(player, "☁ 구름 아래로 떨어져 천궁으로 돌아왔어요")
				end
			end
		end
		local fallen = {}
		for _, e in ipairs(Npc.list) do
			local ef = e.f
			if e.region == "sky" and not ef.dead and ef.root.Parent and ef.root.Position.Y < Y - 60 then
				table.insert(fallen, ef)
			end
		end
		for _, ef in ipairs(fallen) do
			Combat.kill(ef, nil)
		end
	end
end)

-- 강호 순위표: 1분마다. 저장소(정렬 저장소)가 되면 모든 서버의 기록, 안 되면 이 서버 사람만
local Board = {}
local boardStores: { [string]: any } = {}
local nameCache: { [number]: string } = {}
local boardSent: { [string]: number } = {} -- 같은 값은 다시 보내지 않는다
local BOARD_VALUE = {
	realm = function(p: Profile): number
		return math.floor(Calc.total(p))
	end,
	pvp = function(p: Profile): number
		return p.pvpWins
	end,
	tower = function(p: Profile): number
		return p.towerBest
	end,
}

function Board.store(key: string): any
	if boardStores[key] == nil then
		local ok, ds = pcall(function()
			return DataStoreService:GetOrderedDataStore("Kwonwang_lb_" .. key)
		end)
		boardStores[key] = ok and ds or false
	end
	return boardStores[key] or nil
end

function Board.name(userId: number): string
	if nameCache[userId] then
		return nameCache[userId]
	end
	local pl = Players:GetPlayerByUserId(userId)
	if pl then
		nameCache[userId] = pl.DisplayName
		return pl.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = ok and name or ("#" .. userId)
	return nameCache[userId]
end

function Board.update()
	local boards = W.boards
	if not boards then
		return
	end
	for key, valueOf in pairs(BOARD_VALUE) do
		local gui = boards[key]
		if gui then
			local rows: { { string } } = {}
			local ds = Board.store(key)
			local okStore = false
			if ds then
				for player, p in pairs(profiles) do
					local st = states[player]
					local v = valueOf(p)
					local sentKey = key .. player.UserId
					if st and st.canSave and not st.tester and boardSent[sentKey] ~= v then
						local ok = pcall(function()
							ds:SetAsync(tostring(player.UserId), v)
						end)
						if ok then
							boardSent[sentKey] = v
						end
					end
				end
				local ok, page = pcall(function()
					return ds:GetSortedAsync(false, 10):GetCurrentPage()
				end)
				if ok and type(page) == "table" and #page > 0 then
					okStore = true
					for _, entry in ipairs(page) do
						table.insert(rows, { Board.name(tonumber(entry.key) or 0), Config.formatNumber(entry.value) })
					end
				end
			end
			if not okStore then
				local list = {}
				for player, p in pairs(profiles) do
					table.insert(list, { player.DisplayName, valueOf(p) })
				end
				table.sort(list, function(a, b)
					return a[2] > b[2]
				end)
				for i = 1, math.min(10, #list) do
					table.insert(rows, { list[i][1], Config.formatNumber(list[i][2]) })
				end
			end
			for r = 1, 10 do
				local label = gui:FindFirstChild("Row" .. r)
				if label and label:IsA("TextLabel") then
					local row = rows[r]
					label.Text = row and string.format("%d. %s  ·  %s", r, row[1], row[2]) or ""
				end
			end
		end
	end
end

task.spawn(function()
	task.wait(8)
	while true do
		local ok, err = pcall(Board.update)
		if not ok then
			warn("[권왕] 순위표 오류:", err)
		end
		task.wait(60)
	end
end)
-- 천상 상점·객잔
if W.skyShop then
	W.skyShop.Triggered:Connect(function(player: Player)
		Push:FireClient(player, "open", { page = "skyshop" })
	end)
end
if W.skyInn then
	W.skyInn.Triggered:Connect(function(player: Player)
		local f = Combat.fighterOfPlayer(player)
		if f and not f.dead then
			f.hp = f.maxHp
			f.posture = 0
			f.chi = (f :: any).chiMax or Config.CHI_MAX
			Combat.sync(f)
		end
		toast(player, "🛏 구름 이불에서 쉬었다. 체력과 내공이 가득 찼다")
	end)
end

-- 운석 낙하: 천상계에 사람이 있으면 몇 분마다, 천궁이 아닌 섬 어딘가에 운석이 떨어지고 운석 수호수가 나타난다
task.spawn(function()
	local M = Config.METEOR
	local nextAt = os.clock() + M.first
	while true do
		task.wait(1)
		local skyPlayers = {}
		for player in pairs(profiles) do
			local f = Combat.fighterOfPlayer(player)
			if f and f.root.Position.Y > Config.SKY.y - 300 then
				table.insert(skyPlayers, player)
			end
		end
		if (os.clock() >= nextAt or _G.KwonMeteorNow) and #skyPlayers > 0 then
			_G.KwonMeteorNow = nil
			nextAt = os.clock() + M.every
			local choices = {}
			for _, isl in ipairs(Config.SKY.islands) do
				if not isl.safe and not isl.hidden and not isl.raid then
					table.insert(choices, isl)
				end
			end
			local isl = choices[math.random(#choices)]
			local a, r = math.random() * math.pi * 2, isl.radius * 0.5 * math.random()
			local at = isl.at + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			for _, player in ipairs(skyPlayers) do
				Push:FireClient(player, "meteor", { at = at, warn = M.warn, island = isl.name })
			end
			task.delay(M.warn, function()
				local ok, e = pcall(Npc.spawn, "meteorguard", false, at, "summon")
				if ok and e then
					local ef = e.f :: any
					ef.meteor = true
					ef.model:SetAttribute("Label", "☄ 운석 수호수")
					task.delay(M.life, function()
						if not ef.dead and ef.model.Parent then
							Npc.despawn(ef)
						end
					end)
				end
			end)
		end
	end
end)

------------------------------------------------------------------------
-- 1.7판 천상 레이드: 천공 투기장에 정해진 때마다 천겁이 내려온다
-- 그때 천상계에 있는 사람 수만큼 체력이 늘고, 체력의 1% 이상 친 사람은 친 만큼 나눠 받는다
------------------------------------------------------------------------
Raid.cur = nil :: any
local function playersInSky(): { Player }
	local out = {}
	for player in pairs(profiles) do
		local f = Combat.fighterOfPlayer(player)
		if f and f.root.Position.Y > Config.SKY.y - 300 then
			table.insert(out, player)
		end
	end
	return out
end
-- 천상계에 오를 수 있는 사람 모두에게 알린다
local function raidTell(kind: string, data: any)
	for player, p in pairs(profiles) do
		if Calc.realm(p) >= Config.SKY.realm then
			Push:FireClient(player, kind, data)
		end
	end
end
function Raid.onHit(player: Player, f: any, dmg: number)
	local c = Raid.cur
	if c and c.f == f then
		c.dmg[player] = (c.dmg[player] or 0) + dmg
	end
end
local function raidRanking(c: any): { { player: Player, dmg: number } }
	local list = {}
	for player, d in pairs(c.dmg) do
		table.insert(list, { player = player, dmg = d })
	end
	table.sort(list, function(a, b)
		return a.dmg > b.dmg
	end)
	return list
end
function Raid.spawn()
	local R = Config.RAID
	local isl = Config.SKY_BY_ID[R.island]
	if Raid.cur or not isl then
		return
	end
	local n = math.max(1, #playersInSky())
	local ok, e = pcall(Npc.spawn, R.boss, true, isl.at + Vector3.new(0, 0, 10), "summon")
	if not ok or not e then
		warn("[권왕] 레이드 보스 만들기 오류:", e)
		return
	end
	local ef = e.f :: any
	ef.raid = true
	ef.maxHp = math.floor(ef.maxHp * (1 + R.hpPer * (n - 1)))
	ef.hp = ef.maxHp
	ef.model:SetAttribute("Label", "⚔ 레이드 · " .. ef.name)
	ef.model:SetAttribute("Raid", true)
	Combat.sync(ef)
	local c = { f = ef, dmg = {}, endsAt = os.clock() + R.life, n = n }
	Raid.cur = c
	raidTell("raidAlert", { stage = "on", name = ef.name, n = n, life = R.life })
	-- 남은 시간 안에 못 쓰러뜨리면 하늘로 돌아간다
	task.delay(R.life, function()
		if Raid.cur == c and not ef.dead then
			Raid.cur = nil
			Npc.despawn(ef)
			raidTell("raidAlert", { stage = "fail", name = ef.name })
			for _, player in ipairs(playersInSky()) do
				Push:FireClient(player, "raid", nil)
			end
		end
	end)
	-- 투기장 둘레 사람에게 1초마다 형편을 알린다 (체력·남은 시간·내 기여·순위)
	task.spawn(function()
		while Raid.cur == c and not ef.dead do
			local rank = raidRanking(c)
			local top = {}
			for i = 1, math.min(3, #rank) do
				top[i] = { name = rank[i].player.DisplayName, share = rank[i].dmg / ef.maxHp }
			end
			for _, player in ipairs(playersInSky()) do
				local pf = Combat.fighterOfPlayer(player)
				if pf and Vector3.new(pf.root.Position.X - isl.at.X, 0, pf.root.Position.Z - isl.at.Z).Magnitude < isl.radius + 60 then
					local myRank = 0
					for i, r in ipairs(rank) do
						if r.player == player then
							myRank = i
						end
					end
					Push:FireClient(player, "raid", { name = ef.name, hp = ef.hp, maxHp = ef.maxHp, left = c.endsAt - os.clock(), mine = (c.dmg[player] or 0) / ef.maxHp, rank = myRank, top = top })
				else
					Push:FireClient(player, "raid", nil)
				end
			end
			task.wait(1)
		end
	end)
end
function Raid.killed(f: any)
	local c = Raid.cur
	if not c or c.f ~= f then
		return
	end
	Raid.cur = nil
	local R = Config.RAID
	local rank = raidRanking(c)
	local names = {}
	for i = 1, math.min(3, #rank) do
		table.insert(names, string.format("%d. %s %d%%", i, rank[i].player.DisplayName, math.floor(rank[i].dmg / f.maxHp * 100 + 0.5)))
	end
	raidTell("raidAlert", { stage = "win", name = f.name, top = names })
	for i, r in ipairs(rank) do
		local player = r.player
		local p, st = profiles[player], states[player]
		local share = math.clamp(r.dmg / f.maxHp, 0, 1)
		if p and st and share >= R.minShare then
			local k = 0.4 + share
			local gems = math.floor(R.gems * k)
			local coins = math.floor(R.coins * k)
			local scrolls = R.scrolls + (i == 1 and 1 or 0)
			p.skyGems += gems
			p.coins += coins
			p.scrolls += scrolls
			-- 능력치는 내 전투력의 적을 statKills 마리 쓰러뜨린 몫 × (0.3 + 기여) (보스가 아주 세도 터무니없이 커지지 않게)
			local each = math.max(1, math.floor(Config.killGain(rewardPower(player)) * R.statKills * (0.3 + share) * gainMult(p) / #Config.Stats))
			p.counts.raid = (p.counts.raid or 0) + 1
			for _, sd in ipairs(Config.Stats) do
				p.stats[sd.id] += each
			end
			st.dirty = true
			refreshFighter(player)
			Story.check(player)
			Push:FireClient(player, "raidReward", { rank = i, share = share, gems = gems, coins = coins, scrolls = scrolls, stats = each * #Config.Stats })
			pushState(player)
		end
	end
	for _, player in ipairs(playersInSky()) do
		Push:FireClient(player, "raid", nil)
	end
end
-- 때가 되면 알리고, 잠시 뒤 내려온다 (천상계에 아무도 없으면 미룬다)
task.spawn(function()
	local R = Config.RAID
	local nextAt = os.clock() + R.first
	while true do
		task.wait(1)
		if not Raid.cur and (os.clock() >= nextAt or _G.KwonRaidNow) and #playersInSky() > 0 then
			local now = _G.KwonRaidNow
			_G.KwonRaidNow = nil
			nextAt = os.clock() + R.every
			local warnFor = now and 3 or R.warn
			raidTell("raidAlert", { stage = "warn", name = (Config.Bosses[R.boss] or {}).name, warn = warnFor })
			task.wait(warnFor)
			Raid.spawn()
		end
	end
end)
-- 천궁의 투기장 문: 투기장 가장자리로 (싸우는 중에는 안 된다)
if W.raidGate then
	W.raidGate.Triggered:Connect(function(player: Player)
		local f = Combat.fighterOfPlayer(player)
		local isl = Config.SKY_BY_ID[Config.RAID.island]
		if not f or f.dead or not isl then
			return
		end
		if f.combatUntil > os.clock() then
			toast(player, "싸우는 중에는 이동할 수 없어요")
			return
		end
		Combat.dismount(f)
		local char = player.Character
		if char then
			local d = Vector3.new(Config.SKY.islands[1].at.X - isl.at.X, 0, Config.SKY.islands[1].at.Z - isl.at.Z).Unit
			local at = isl.at + d * (isl.radius * 0.6) + Vector3.new(0, 5, 0)
			char:PivotTo(CFrame.lookAt(at, Vector3.new(isl.at.X, at.Y, isl.at.Z)))
		end
		toast(player, Raid.cur and "⚔ 천공 투기장 · 천겁과 싸우는 중!" or "⚔ 천공 투기장 · 천겁이 내려오면 알려 드려요")
	end)
end

if W.inn then
	W.inn.Triggered:Connect(function(player: Player)
		local p = profiles[player]
		if not p then
			return
		end
		local f = Combat.fighterOfPlayer(player)
		if f and not f.dead then
			f.hp = f.maxHp
			f.posture = 0
			f.chi = (f :: any).chiMax or Config.CHI_MAX
			Combat.sync(f)
		end
		toast(player, "🛏 푹 쉬었다. 체력과 내공이 가득 찼다")
	end)
end
-- 비급 조각 줍기 (다섯을 모으면 무극신권)
for i, frag in ipairs(W.fragments or {}) do
	frag.Triggered:Connect(function(player: Player)
		local p = profiles[player]
		if not p or p.fragments[tostring(i)] then
			return
		end
		p.fragments[tostring(i)] = true
		local n = countKeys(p.fragments)
		Push:FireClient(player, "fragment", { n = n, total = #Config.Fragments })
		if n >= #Config.Fragments then
			grantStyle(player, "mugeuk", true)
		end
		states[player].dirty = true
		Story.event(player, "fragment")
		pushState(player)
	end)
end
for _, info in ipairs(W.train or {}) do
	info.prompt.Triggered:Connect(function(player: Player)
		Train.start(player, info)
	end)
	if info.hard then
		info.hard.Triggered:Connect(function(player: Player)
			Train.start(player, info, true)
		end)
	end
end

------------------------------------------------------------------------
-- 들어오고 나가기
------------------------------------------------------------------------
------------------------------------------------------------------------
-- 로벅스 상품 (게임패스)
------------------------------------------------------------------------
Premium = {}
local Marketplace: any = nil
pcall(function()
	Marketplace = game:GetService("MarketplaceService")
end)

function Premium.owns(player: Player, id: string): boolean
	local st = states[player]
	return st ~= nil and st.owned ~= nil and st.owned[id] == true
end

function Premium.grant(player: Player, id: string)
	local st = states[player]
	if not st then
		return
	end
	st.owned = st.owned or {}
	st.owned[id] = true
	-- 자동 수련을 처음 얻으면 바로 켠다
	local p = profiles[player]
	if p and (id == "autoTrain" or id == "autoTrain2") and p.autoOn == nil then
		p.autoOn = true
	end
	-- 청룡을 사면 바로 고른다
	if p and id == "dragon" then
		p.mountSel = "dragon"
		toast(player, "🐉 청룡을 얻었어요! V로 타기")
	end
	pushState(player)
end

-- 들어올 때 가진 게임패스를 확인한다
function Premium.load(player: Player)
	if not Marketplace then
		return
	end
	for _, it in ipairs(Config.Premium) do
		if it.gamepass > 0 then
			local ok, has = pcall(function()
				return Marketplace:UserOwnsGamePassAsync(player.UserId, it.gamepass)
			end)
			if ok and has then
				Premium.grant(player, it.id)
			end
		end
	end
end

function Premium.prompt(player: Player, id: string)
	local it = Config.PREMIUM_BY_ID[id]
	if not it then
		return
	end
	if Premium.owns(player, id) then
		toast(player, "이미 가지고 있어요")
		return
	end
	if it.gamepass <= 0 or not Marketplace then
		toast(player, "아직 판매 준비 중이에요 (게임패스 번호를 넣어야 해요)")
		return
	end
	pcall(function()
		Marketplace:PromptGamePassPurchase(player, it.gamepass)
	end)
end

if Marketplace then
	pcall(function()
		Marketplace.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, bought: boolean)
			if not bought then
				return
			end
			for _, it in ipairs(Config.Premium) do
				if it.gamepass == passId then
					Premium.grant(player, it.id)
					toast(player, "💎 " .. it.name .. "을(를) 얻었어요! 고마워요")
					Push:FireClient(player, "premium", { id = it.id })
				end
			end
		end)
	end)
end

-- 자동 수련: 수련 화면 안에서만. 박자가 돌아올 때마다 대신 눌러 준다 (보통 '좋음', 고급 '완벽').
-- 사람이 박자를 맞춰 누르는 것보다 빠르지 않다 (손이 편해질 뿐, 더 세지지 않는다)
task.spawn(function()
	while true do
		task.wait(0.2)
		local now = os.clock()
		for player, st in pairs(states) do
			local p = profiles[player]
			local tr = st.training
			if p and p.autoOn and tr and tr.kind ~= "simma" then
				local adv = Premium.owns(player, "autoTrain2")
				if adv or Premium.owns(player, "autoTrain") then
					local info = Config.Training[tr.kind]
					local period = (info and info.period) or Config.TRAIN_JUDGE.period
					if tr.hard then
						period = Config.HARD_TRAIN.period
					end
					if now >= ((st.autoAt or 0) :: number) then
						st.autoAt = now + period
						Train.hit(player, adv and "perfect" or "good", nil)
					end
				end
			end
		end
	end
end)

local function setupCharacter(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 10)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not hum or not root or not hum:IsA("Humanoid") then
		return
	end
	hum.BreakJointsOnDeath = false
	hum.MaxHealth = 1e9
	hum.Health = 1e9
	hum.JumpPower = 55
	hum.UseJumpPower = true
	local p = profiles[player]
	if not p then
		return
	end
	local f = Combat.register(char, { player = player, name = player.DisplayName, hp = Config.maxHp(p.stats.vit), style = p.style })
	if TEST_INF[player] then
		char:SetAttribute("TestInf", true)
	end
	char:SetAttribute("PvpOff", p.pvpOff == true)
	f.iframeUntil = os.clock() + 2
	refreshFighter(player)
	char.AncestryChanged:Connect(function()
		if not char.Parent then
			Combat.unregister(char)
		end
	end)
	local st = states[player]
	if st then
		st.training = nil
	end
end

local function onPlayerAdded(player: Player)
	local st: State = { canSave = false, dirty = false, tester = false, reqWindow = 0, reqCount = 0, training = nil, trainAt = 0, ringIdx = 1, potionAt = 0 }
	states[player] = st
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local realmValue = Instance.new("StringValue")
	realmValue.Name = "경지"
	realmValue.Value = "삼류"
	realmValue.Parent = ls
	local coinValue = Instance.new("StringValue")
	coinValue.Name = "은자"
	coinValue.Value = "0"
	coinValue.Parent = ls
	ls.Parent = player
	local profile, ok
	if isTester(player) then
		profile, ok = defaultProfile(), false
		st.tester = true
	else
		profile, ok = loadProfile(player)
	end
	if not player.Parent then
		return
	end
	-- 누구나 삼재권 하나는 몸에 지니고 시작한다
	if not profile.styles.samjae then
		profile.styles.samjae = true
	end
	if profile.style == "" then
		profile.style = "samjae"
	end
	profiles[player] = profile
	st.canSave = ok
	player.CharacterAdded:Connect(function(char)
		setupCharacter(player, char)
	end)
	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
	pushState(player)
	task.spawn(Premium.load, player)
end

local function onPlayerRemoving(player: Player)
	Tower.ended(player, "left")
	Maze.ended(player, "left")
	-- 시험 중에 나가면 시험의 상대를 거둔다 (쓰러지지 않는 사부가 남지 않게)
	pcall(Trial.ended, player, false)
	saveProfile(player)
	profiles[player] = nil
	states[player] = nil
	TEST_INF[player] = nil
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

-- 서버가 닫힐 때: 모두 저장하고, 저장이 끝날 때까지 (최대 25초) 기다린다
game:BindToClose(function()
	for player in pairs(profiles) do
		task.spawn(saveProfile, player)
	end
	local t0 = os.clock()
	task.wait(0.5)
	while saving > 0 and os.clock() - t0 < 25 do
		task.wait(0.25)
	end
end)

------------------------------------------------------------------------
-- 사부와 적 (몸 만들기는 시간이 걸릴 수 있어 맨 나중에, 따로)
------------------------------------------------------------------------
task.spawn(function()
	local ok, err = pcall(Npc.spawnMasters, function(player: Player, styleId: string)
		local p = profiles[player]
		if not p then
			return
		end
		if not p.found[styleId] then
			p.found[styleId] = true
			Story.event(player, "found")
		end
		local m = Config.MASTERS[styleId]
		local sdef = Config.STYLE_BY_ID[styleId]
		if sdef and sdef.realmReq and not p.styles[styleId] and Calc.realm(p) < sdef.realmReq then
			Push:FireClient(player, "dialog", { who = m.name, title = "「" .. m.quote .. "」", text = string.format("...아직 이르다. 네 안의 하늘이 열리지 않았다. %s에 이르거든 다시 오너라.", Config.Realms[sdef.realmReq].name) })
			return
		end
		local req = sdef and sdef.styleReq and Config.STYLE_BY_ID[sdef.styleReq]
		if req and not p.styles[styleId] and not p.styles[req.id] then
			Push:FireClient(player, "dialog", { who = m.name, title = "「" .. m.quote .. "」", text = string.format("...해와 달을 쥐려면 먼저 세상의 처음을 알아야 한다. %s을(를) 익히고 다시 오너라.", req.name) })
			return
		end
		if not p.styles[styleId] and not p.trials[styleId] then
			-- 아직 시험을 안 넘었다: 사부가 시험을 낸다
			Push:FireClient(player, "dialog", { who = m.name, title = "「" .. m.quote .. "」", text = (function()
				local kind, need = Config.trialNeed(styleId)
				local K = Config.TRIAL_KINDS[kind]
				local what = K and (K.icon .. " " .. K.title .. ": " .. string.format(K.ask, need)) or "먼저 내 분신을 꺾어라."
				return "제자가 되고 싶다면 시험을 넘어라. " .. what .. " 준비가 되면 다시 말을 걸어라. (다시 T를 누르면 시험이 시작된다)"
			end)(), trial = styleId })
			local st = states[player]
			if st and (st :: any).trialAsk == styleId then
				(st :: any).trialAsk = nil
				Trial.start(player, styleId)
			elseif st then
				(st :: any).trialAsk = styleId
			end
			return
		end
		Push:FireClient(player, "open", { page = "styles", style = styleId, master = true })
	end)
	if not ok then
		warn("[권왕] 사부 만들기 오류:", err)
	end
	ok, err = pcall(Npc.spawnElder, function(player: Player)
		Story.talk(player)
	end)
	if not ok then
		warn("[권왕] 장로 만들기 오류:", err)
	end
	ok, err = pcall(Npc.populate)
	if not ok then
		warn("[권왕] 적 만들기 오류:", err)
	end
	Npc.start()
end)

-- 사부를 찾았는가 (사부가 사는 지역에 한 번 들어가면 찾은 것, 숨은 사부는 가까이 가야)
local masterRegion: { [string]: any } = {}
for _, r in ipairs(Config.Regions) do
	if r.master then
		masterRegion[r.master] = r
	end
end
local function visited(pos: Vector3, id: string, m: any): boolean
	local r = masterRegion[id]
	if r and not m.secret and math.abs(pos.X - r.center.X) <= r.size.X / 2 and math.abs(pos.Z - r.center.Z) <= r.size.Z / 2 and pos.Y < Config.SKY.y - 200 then
		return true
	end
	return (pos - m.at).Magnitude < 50
end
task.spawn(function()
	while true do
		task.wait(1)
		for player, p in pairs(profiles) do
			local f = Combat.fighterOfPlayer(player)
			if f and not f.dead then
				for id, m in pairs(Config.MASTERS) do
					if not p.found[id] and visited(f.root.Position, id, m) then
						p.found[id] = true
						states[player].dirty = true
						Push:FireClient(player, "found", { style = id, master = m.name, region = m.region })
						Story.event(player, "found")
						pushState(player)
					end
				end
			end
		end
	end
end)
