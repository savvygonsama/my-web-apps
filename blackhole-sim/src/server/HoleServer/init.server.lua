-- HoleServer (Script, ServerScriptService)
-- 삼키기 판정, 질량, 업그레이드, 빅뱅, 저장. 중요한 계산은 모두 서버가 한다.
--   World  조명, 구역, 문, 물체 배치

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local World = require(script:WaitForChild("World"))

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
World.buildZones()
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

type Profile = {
	mass: number,
	total: number, -- 지금까지 삼킨 질량 (빅뱅해도 남는다)
	eaten: number, -- 삼킨 물체 수
	size: number,
	pull: number,
	mult: number,
	bigbang: number,
}

local function defaultProfile(): Profile
	return { mass = 0, total = 0, eaten = 0, size = 0, pull = 0, mult = 0, bigbang = 0 }
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
-- 상태 보내기와 캐릭터 꾸미기
------------------------------------------------------------------------
local function radiusOf(p: Profile): number
	return Config.radius(p.size)
end

local function pushState(player: Player)
	local p, st = profiles[player], states[player]
	if not p or not st then
		return
	end
	local r = radiusOf(p)
	Push:FireClient(player, "state", {
		mass = p.mass,
		total = p.total,
		eaten = p.eaten,
		size = p.size,
		pull = p.pull,
		mult = p.mult,
		bigbang = p.bigbang,
		radius = r,
		pullRange = Config.pullRange(r, p.pull),
		massMult = Config.massMult(p.mult, p.bigbang),
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
	if massValue and massValue:IsA("StringValue") then
		massValue.Value = Config.formatNumber(p.total)
	end
	if sizeValue and sizeValue:IsA("StringValue") then
		sizeValue.Value = Config.formatSize(radiusOf(p))
	end
end

-- 캐릭터는 보이지 않게 하고, 블랙홀 모양은 모든 화면이 직접 그린다 (크기와 색만 속성으로 알려 준다)
local function applyHole(player: Player)
	local p = profiles[player]
	local char = player.Character
	if not p or not char then
		return
	end
	local r = radiusOf(p)
	char:SetAttribute("HoleR", r)
	char:SetAttribute("HoleSkin", math.clamp(p.bigbang + 1, 1, #Config.BIGBANG_SKINS))
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = Config.walkSpeed(r)
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	local head = char:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local tag = head:FindFirstChild("HoleTag")
		if not tag then
			local gui = Instance.new("BillboardGui")
			gui.Name = "HoleTag"
			gui.Size = UDim2.new(0, 220, 0, 44)
			gui.AlwaysOnTop = true
			gui.LightInfluence = 0
			gui.MaxDistance = 2000
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
			label.Text = string.format("%s · ⚫%s", player.DisplayName, Config.formatSize(r))
			label.TextColor3 = Config.skin(p.bigbang).b
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

local function eat(player: Player, rec: World.ObjectRec)
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
	local wait = Config.Zones[rec.zone].respawn * (0.8 + math.random() * 0.5)
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

local function tickPlayer(player: Player, p: Profile, st: State)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local pos = root.Position
	local r = radiusOf(p)
	local reach = r + Config.pullRange(r, p.pull)
	local zone = Config.zoneAt(pos.Z)
	if zone ~= st.zone then
		st.zone = zone
		Push:FireClient(player, "zone", zone)
	end
	local mult = Config.massMult(p.mult, p.bigbang)
	local reachable = Config.maxZone(r)
	local eatenList = {}
	local gained = 0
	for zi = math.max(1, zone - 1), math.min(#Config.Zones, zone + 1) do
		for _, rec in ipairs(byZone[zi] or {}) do
			if rec.alive and rec.zone <= reachable and rec.def.size <= r and flatDist(rec.pos, pos) <= reach + rec.def.size * 0.5 then
				eat(player, rec)
				local m = rec.def.mass * mult
				gained += m
				table.insert(eatenList, { pos = rec.pos, mass = m, size = rec.def.size, name = rec.def.name })
				if #eatenList >= 40 then
					break
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
-- 업그레이드, 빅뱅, 이동
------------------------------------------------------------------------
local function buyUpgrade(player: Player, id: any, many: any): number
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
		local level = (p :: any)[u.id] :: number
		if level >= u.maxLevel then
			toast(player, u.name .. "은(는) 이미 최대예요")
		else
			toast(player, "질량이 부족해요 (필요 💠" .. Config.formatNumber(Config.upgradeCost(u.id, level)) .. ")")
		end
		return 0
	end
	states[player].dirty = true
	applyHole(player)
	Push:FireClient(player, "upgraded", { id = u.id, count = bought, level = (p :: any)[u.id] })
	pushState(player)
	return bought
end

local function bigbang(player: Player)
	local p = profiles[player]
	if p.size < Config.BIGBANG_LEVEL then
		toast(player, string.format("크기 레벨 %d(⚫%s) 이상이어야 빅뱅할 수 있어요", Config.BIGBANG_LEVEL, Config.formatSize(Config.radius(Config.BIGBANG_LEVEL))))
		return
	end
	p.bigbang += 1
	p.mass = 0
	p.size = 0
	p.pull = 0
	p.mult = 0
	states[player].dirty = true
	local char = player.Character
	if char then
		char:PivotTo(CFrame.new(0, 4, 22))
	end
	applyHole(player)
	Push:FireClient(player, "bigbang", { count = p.bigbang, skin = Config.skin(p.bigbang).name })
	pushState(player)
end

local function teleport(player: Player, zoneArg: any)
	local p = profiles[player]
	local zi = math.floor(tonumber(zoneArg) or 0)
	if zi < 1 or zi > #Config.Zones then
		return
	end
	if zi > Config.maxZone(radiusOf(p)) then
		toast(player, string.format("크기 %d 이상이어야 갈 수 있어요", Config.Zones[zi].need))
		return
	end
	local char = player.Character
	if char then
		local z = Config.zoneStart(zi) + 20 + radiusOf(p)
		char:PivotTo(CFrame.new(0, 5, math.min(z, Config.zoneStart(zi) + Config.Zones[zi].length / 2)))
	end
end

------------------------------------------------------------------------
-- 요청 처리
------------------------------------------------------------------------
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
		buyUpgrade(player, arg, arg2)
	elseif action == "bigbang" then
		bigbang(player)
	elseif action == "teleport" then
		teleport(player, arg)
	elseif action == "hello" then
		pushState(player)
		if st.tester then
			toast(player, "🧪 테스트 계정이에요. 테스트 창에서 질량을 받을 수 있고, 기록은 저장하지 않아요")
		elseif not st.canSave then
			toast(player, "저장이 꺼져 있어요. 이번 기록은 저장되지 않아요")
		end
	elseif action == "testMass" and st.tester then
		local amount = math.clamp(tonumber(arg) or 0, 0, 1e30)
		p.mass += amount
		p.total += amount
		pushState(player)
		updateLeaderstats(player)
	elseif action == "testSize" and st.tester then
		p.size = math.clamp(math.floor(tonumber(arg) or 0), 0, Config.UPGRADE_BY_ID.size.maxLevel)
		applyHole(player)
		pushState(player)
	elseif action == "testMaxAll" and st.tester then
		p.size = Config.UPGRADE_BY_ID.size.maxLevel
		p.pull = Config.UPGRADE_BY_ID.pull.maxLevel
		p.mult = Config.UPGRADE_BY_ID.mult.maxLevel
		applyHole(player)
		pushState(player)
	elseif action == "testReset" and st.tester then
		local keep = p.bigbang
		profiles[player] = defaultProfile()
		profiles[player].bigbang = keep
		applyHole(player)
		pushState(player)
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
	local st: State = { canSave = false, dirty = false, tester = false, reqWindow = 0, reqCount = 0, zone = 1 }
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
	profiles[player] = profile
	st.canSave = ok
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
