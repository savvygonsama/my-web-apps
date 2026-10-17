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
	stamina: number,
	staminaAt: number,
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
		stamina = Config.STAMINA.max,
		staminaAt = os.time(),
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
		for _, s in ipairs(Config.Stats) do
			p.stats[s.id] = math.floor(num(data.stats[s.id], 1e9))
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
	p.fragments = flags(data.fragments, function(k)
		local i = tonumber(k)
		return i ~= nil and Config.Fragments[i] ~= nil
	end)
	p.story = math.clamp(math.floor(num(data.story, #Config.Story)), 1, #Config.Story)
	p.prog = math.floor(num(data.prog, 1e6))
	p.stamina = type(data.stamina) == "number" and num(data.stamina, Config.STAMINA.max) or Config.STAMINA.max
	p.staminaAt = type(data.staminaAt) == "number" and num(data.staminaAt, 1e11) or os.time()
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

local function saveProfile(player: Player)
	local p, st = profiles[player], states[player]
	local ds = store
	if not p or not st or not st.canSave or not ds then
		return
	end
	local ok = pcall(function()
		ds:SetAsync("p_" .. player.UserId, p)
	end)
	if ok then
		st.dirty = false
	end
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
local function toast(player: Player, text: string)
	Push:FireClient(player, "toast", text)
end

local function pushState(player: Player)
	local p, st = profiles[player], states[player]
	if not p or not st then
		return
	end
	local idx, realm = Config.realmOf(Calc.total(p))
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
		stamina = math.floor(p.stamina),
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
	local _, realm = Config.realmOf(Calc.total(p))
	local style = Config.STYLE_BY_ID[p.style]
	local gui = head:FindFirstChild("KwonTag") :: BillboardGui?
	if not gui then
		local g = Instance.new("BillboardGui")
		g.Name = "KwonTag"
		g.Size = UDim2.new(0, 300, 0, 60)
		g.StudsOffset = Vector3.new(0, 2.6, 0)
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
	top.Text = string.format("[%s] %s", realm.name, player.DisplayName)
	top.TextColor3 = realm.color
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
local function refreshFighter(player: Player)
	local p = profiles[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not f then
		return
	end
	local idx = Config.realmOf(Calc.total(p))
	local m = p.style ~= "" and Calc.mastery(p, p.style).lv or 1
	f.style = p.style
	-- 경지 배율: 경지가 오를 때마다 피해·체력이 크게 오른다
	local power = Config.realmPower(idx)
	local styleDef = Config.STYLE_BY_ID[p.style]
	local grade = styleDef and Config.GRADES[styleDef.grade] or 1
	f.dmgMult = Config.statMult(p.stats.str) * (1 + 0.03 * (m - 1)) * power * grade
	f.skillMult = math.sqrt(Config.statMult(p.stats.chi))
	local oldMax = f.maxHp
	f.maxHp = math.floor(Config.maxHp(p.stats.vit) * power)
	if oldMax > 0 then
		f.hp = math.min(f.maxHp, f.hp * f.maxHp / oldMax)
	end
	f.walk = Config.walkSpeed(p.stats.agi)
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
	if char then
		char:PivotTo(CFrame.new(Config.SPAWN))
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
		local unlocked = nil
		for slot, need in pairs(Config.SKILL_UNLOCK) do
			if need == m.lv then
				unlocked = style.skills[slot].name .. " (" .. slot .. ")"
			end
		end
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
		return countKeys(p.styles) >= g.n
	elseif k == "realm" then
		return Config.realmOf(Calc.total(p)) >= g.n
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
		-- 다음 장이 이미 이뤄졌다면 (경지 등) 이어서 넘긴다
		local nxt = Config.Story[p.story]
		if not (nxt.goal.kind ~= "talk" and nxt.goal.kind ~= "kill" and nxt.goal.kind ~= "train" and nxt.goal.kind ~= "trial" and nxt.goal.kind ~= "boss" and Story.done(p, nxt.goal)) then
			break
		end
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
	if ch.goal.kind == "talk" then
		Story.advance(player)
	end
end

------------------------------------------------------------------------
-- 사부의 시험: 사부가 기운으로 빚은 분신과 겨룬다
------------------------------------------------------------------------
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

function Trial.start(player: Player, styleId: string)
	local style = Config.STYLE_BY_ID[styleId]
	local master = Config.MASTERS[styleId]
	local f = Combat.fighterOfPlayer(player)
	if not style or not master or not f or f.dead then
		return
	end
	if activeTrial[player] then
		toast(player, "이미 시험 중이에요")
		return
	end
	local key = "trial_" .. styleId
	Config.Enemies[key] = trialDef(style, master)
	local e = Npc.spawn(key, false, master.at + (f.root.Position - master.at).Unit * 6, "trial")
	if not e then
		return
	end
	local ef = e.f :: any
	ef.trialOwner = player
	ef.trialStyle = styleId
	e.target = f
	ef.model:SetAttribute("Style", styleId)
	activeTrial[player] = ef
	Push:FireClient(player, "dialog", { who = master.name, title = "사부의 시험", text = "내 권법을 원하는가. 그럼 내 분신을 꺾어 보아라. 마구 휘두르는 주먹은 통하지 않는다." })
	Push:FireClient(player, "trial", { m = ef.model, name = master.name, style = styleId })
	-- 너무 오래 끌면 사부가 거둔다
	task.delay(150, function()
		if activeTrial[player] == ef and not ef.dead then
			activeTrial[player] = nil
			Npc.despawn(ef)
			toast(player, "⌛ 시험 시간이 다 됐어요. 다시 청하세요")
		end
	end)
end

function Trial.ended(player: Player, won: boolean)
	local ef = activeTrial[player]
	if not ef then
		return
	end
	activeTrial[player] = nil
	local p = profiles[player]
	if won and p then
		local id = ef.trialStyle
		p.trials[id] = true
		local style = Config.STYLE_BY_ID[id]
		Push:FireClient(player, "trialWin", { style = id, master = Config.MASTERS[id].name })
		toast(player, string.format("🥋 시험 통과! 이제 %s을(를) 배울 수 있어요 (사부 곁에서 T)", style.name))
		states[player].dirty = true
		Story.event(player, "trial")
		pushState(player)
	elseif not ef.dead then
		Npc.despawn(ef)
	end
end

Combat.init(Push, {
	onKill = function(f: any, by: any)
		if f.npc then
			Npc.onDeath(f)
			local killer = by and by.player
			local p = killer and profiles[killer]
			if killer and p then
				local isBoss = f.model:GetAttribute("Boss") == true
				-- 이야기·시험
				if f.trialOwner == killer then
					Trial.ended(killer, true)
				end
				local isBossKill = f.model:GetAttribute("Boss") == true
				if isBossKill then
					for id, def in pairs(Config.Bosses) do
						if def == f.npc then
							Story.event(killer, "boss", id)
							-- 혈마를 꺾으면 그 손이 넘어온다
							if id == "hyeolma" then
								grantStyle(killer, "hyeolma", true)
							end
						end
					end
				elseif f.typeId then
					Story.event(killer, "kill", f.typeId)
				end
				-- 심마를 이긴 주인: 모든 능력치가 크게 오른다
				if f.simmaOwner == killer then
					local ridx = Config.realmOf(Calc.total(p))
					local gain = math.floor(Config.Training.simma.reward * (1 + 0.25 * (ridx - 1)))
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
				p.kills += 1
				if isBoss then
					for id, def in pairs(Config.Bosses) do
						if def == f.npc then
							p.bosses[id] = (p.bosses[id] or 0) + 1
						end
					end
				end
				addMastery(killer, p, xp)
				states[killer].dirty = true
				Push:FireClient(killer, "reward", { coins = coins, xp = xp, name = f.name, boss = isBoss })
				updateTag(killer)
				pushState(killer)
			end
		elseif f.player then
			local player = f.player
			Trial.ended(player, false)
			-- 비무대에서 이기면 기록
			local winner = by and by.player
			if winner and profiles[winner] then
				profiles[winner].pvpWins += 1
				states[winner].dirty = true
				Push:FireAllClients("duel", { winner = winner.DisplayName, loser = player.DisplayName })
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
		if att.player and not opt.chain then
			local p = profiles[att.player]
			if p then
				addMastery(att.player, p, 1 + dmg * 0.05)
			end
		end
	end,
	onDeflect = function(tgt: any, _att: any)
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
	local style = Config.STYLE_BY_ID[p.style]
	local slot: any = slotArg
	if type(slot) == "number" then
		slot = math.floor(slot)
		if slot < 1 or slot > #style.combo then
			return
		end
	elseif slot ~= "H" and slot ~= "E" and slot ~= "R" and slot ~= "G" and slot ~= "F" and not Config.ACTION_MOVES[slot] then
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
	if slot == "E" or slot == "R" or slot == "G" then
		if not Calc.unlocked(p, slot) then
			toast(player, string.format("🔒 %s: 숙련도 %d에 열려요", move.name, Config.SKILL_UNLOCK[slot]))
			return
		end
		if t < (f.cds[slot] or 0) then
			return
		end
		local cost = move.chi or 0
		if f.chi < cost then
			toast(player, string.format("내공이 부족해요 (🌀 %d 필요)", cost))
			return
		end
		f.chi -= cost
		f.cds[slot] = t + (move.cd or 0) * (tier > 0 and Config.AWAKEN[tier].cd or 1)
	end
	local speed = style.speed or 1
	local charge = 0
	if slot == "H" and style.charge then
		charge = math.clamp(tonumber(chargeArg) or 0, 0, style.charge)
	end
	local bloom = false
	local dmgScale = 1
	if slot == "H" then
		if style.id == "maehwa" and f.stacks.petal >= 20 then
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
		elseif style.hidden then
			toast(player, "🔒 " .. (style.unlockHint or "숨겨진 권법"))
			return
		end
		local master = Config.MASTERS[style.id]
		if not master then
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
local Train = {}

-- 수련 기력: 시간이 지나면 찬다
local function regenStamina(p: Profile)
	local S = Config.STAMINA
	local now = os.time()
	if p.stamina >= S.max then
		p.staminaAt = now
		return
	end
	local ticks = math.floor((now - p.staminaAt) / S.regenEvery)
	if ticks > 0 then
		p.stamina = math.min(S.max, p.stamina + ticks)
		p.staminaAt += ticks * S.regenEvery
	end
end

function Train.start(player: Player, info: any, hard: boolean?)
	local p, st = profiles[player], states[player]
	local f = Combat.fighterOfPlayer(player)
	if not p or not st or not f or f.dead then
		return
	end
	if f.combatUntil > os.clock() then
		toast(player, "싸우는 중에는 수련할 수 없어요")
		return
	end
	local kindInfo = Config.Training[info.kind]
	local realmIdx = Config.realmOf(Calc.total(p))
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
	-- 기력이 있어야 몸이 받아들인다
	regenStamina(p)
	local cost = st.training.hard and Config.STAMINA.hardCost or Config.STAMINA.cost
	if gain > 0 and p.stamina < cost then
		toast(player, "😮‍💨 기력이 다했어요. 객잔에서 쉬거나 조금 기다리세요")
		Train.stop(player)
		return
	end
	if gain > 0 then
		p.stamina -= cost
	end
	if gain <= 0 then
		Push:FireClient(player, "trained", { stat = info.stat, gain = 0, grade = grade })
		return
	end
	-- 경지가 오를수록, 소환단을 먹었으면 더 많이
	local idx = Config.realmOf(Calc.total(p))
	local mult = (1 + 0.25 * (idx - 1)) * (p.elixirUntil > os.time() and 2 or 1) * (st.training.hard and Config.HARD_TRAIN.mult or 1)
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
	local afterIdx, realm = Config.realmOf(Calc.total(p))
	Push:FireClient(player, "trained", { stat = info.stat, gain = amount, grade = grade, total = p.stats[info.stat], ring = st.ringIdx })
	if afterIdx > beforeIdx then
		Push:FireAllClients("realm", { name = player.DisplayName, realm = realm.name })
	end
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
			p.stats[s.id] += math.clamp(tonumber(arg) or 100, 0, 1e7)
		end
	elseif action == "testMastery" then
		if p.style ~= "" then
			local m = Calc.mastery(p, p.style)
			m.lv = Config.MASTERY_MAX
			m.xp = 0
		end
	elseif action == "testChi" then
		if f then
			f.chi = Config.CHI_MAX
			f.cds = {}
		end
	elseif action == "testHeal" then
		if f then
			f.hp = f.maxHp
			f.posture = 0
		end
	elseif action == "testBoss" then
		if f then
			Npc.spawn(type(arg) == "string" and Config.Bosses[arg] and arg or "heukho", true, f.root.Position + Combat.look(f) * 30, "test")
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
	elseif action == "testTrial" then
		local ef = activeTrial[player]
		if ef then
			Trial.ended(player, true)
			Npc.despawn(ef)
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
				f.chi = Config.CHI_MAX
			end
			Push:FireClient(player, "learned", { style = sd.id, hidden = sd.hidden == true })
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
		elseif arg == "lock" then
			-- 숨은 권법을 다시 잠근다 (처음부터 다시 얻어 보기)
			p.styles.mugeuk = nil :: any
			p.styles.hyeolma = nil :: any
			p.fragments = {}
			if p.style == "mugeuk" or p.style == "hyeolma" then
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
		if p.story == 1 then
			Push:FireClient(player, "dialog", { who = "강호", title = "권왕: 맨손의 강호", text = "맨손 하나로 강호를 꺾어라. 먼저 마을의 청운 장로를 찾아가 말을 걸어 보자. (노란 길잡이를 따라가서 T)" })
		end
	elseif action == "talkElder" then
		Story.talk(player)
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
-- 객잔: 은자를 내고 쉬면 수련 기력이 가득 찬다
if W.inn then
	W.inn.Triggered:Connect(function(player: Player)
		local p = profiles[player]
		if not p then
			return
		end
		regenStamina(p)
		if p.stamina >= Config.STAMINA.max then
			toast(player, "기력이 이미 가득해요")
			return
		end
		if p.coins < Config.STAMINA.innCost then
			toast(player, string.format("은자가 부족해요 (💰 %d)", Config.STAMINA.innCost))
			return
		end
		p.coins -= Config.STAMINA.innCost
		p.stamina = Config.STAMINA.max
		p.staminaAt = os.time()
		states[player].dirty = true
		toast(player, "🛏 푹 쉬었다. 기력이 가득 찼다")
		pushState(player)
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
	for player in pairs(profiles) do
		task.spawn(saveProfile, player)
	end
	task.wait(2)
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
		if not p.styles[styleId] and not p.trials[styleId] then
			-- 아직 시험을 안 넘었다: 사부가 시험을 낸다
			Push:FireClient(player, "dialog", { who = m.name, title = "「" .. m.quote .. "」", text = "제자가 되고 싶다면 먼저 내 분신을 꺾어라. 준비가 되면 다시 말을 걸어라. (다시 T를 누르면 시험이 시작된다)", trial = styleId })
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

-- 사부를 찾았는가 (가까이 가면 찾은 것) / 기력 갱신
task.spawn(function()
	while true do
		task.wait(1)
		for player, p in pairs(profiles) do
			local f = Combat.fighterOfPlayer(player)
			if f and not f.dead then
				for id, m in pairs(Config.MASTERS) do
					if not p.found[id] and (f.root.Position - m.at).Magnitude < 50 then
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
