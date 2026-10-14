-- ArenaServer (Script, ServerScriptService)
-- 전투, 웨이브, 스킬, 필살기, 합성, 훈련, 저장을 맡는다.
--   WorldBuilder  조명, 로비, 투기장
--   EnemyBuilder  적 7종의 생김새
--   EnemyAI       적 종류별 행동과 보스 기술
--   Skills        무기 스킬 (E, F)
-- 중요한 계산은 전부 서버에서 하고, 클라이언트는 요청만 보낸다.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))
local World = require(script:WaitForChild("WorldBuilder"))
local EnemyBuilder = require(script:WaitForChild("EnemyBuilder"))
local EnemyAI = require(script:WaitForChild("EnemyAI"))
local Skills = require(script:WaitForChild("Skills"))

local ARENA_ORIGIN = Vector3.new(0, 300, 1600)
local ARENA_SPACING = 320
local ARENA_RADIUS = 60
local ENEMY_SPAWN_RADIUS = 36
local SAVE_INTERVAL = 90
local DATASTORE_NAME = "Arena100_v1"
local WALK_ANIM_ID = "rbxassetid://507777826" -- 로블록스 기본 R15 걷기

------------------------------------------------------------------------
-- 통신 채널
------------------------------------------------------------------------
local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "ArenaRemotes"
local Request = Instance.new("RemoteEvent")
Request.Name = "Request"
Request.Parent = remoteFolder
local Push = Instance.new("RemoteEvent")
Push.Name = "Push"
Push.Parent = remoteFolder
remoteFolder.Parent = ReplicatedStorage

local battleRoot = Instance.new("Folder")
battleRoot.Name = "ArenaBattles"
battleRoot.Parent = workspace

------------------------------------------------------------------------
-- 맵
------------------------------------------------------------------------
World.setupLighting()
local lobbySpawn: CFrame = World.buildLobby({
	gate = function(player: Player)
		Push:FireClient(player, "openPage", "stage")
	end,
	forge = function(player: Player)
		Push:FireClient(player, "openPage", "armory")
	end,
	train = function(player: Player)
		Push:FireClient(player, "openPage", "train")
	end,
})

local arenas: { [number]: World.Arena } = {}
local slotOwner: { [number]: Player } = {}

local function claimSlot(player: Player): number
	local i = 1
	while slotOwner[i] do
		i += 1
	end
	slotOwner[i] = player
	if not arenas[i] then
		arenas[i] = World.buildArena(ARENA_ORIGIN + Vector3.new((i - 1) * ARENA_SPACING, 0, 0), ARENA_RADIUS, "Arena" .. i)
	end
	return i
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
	version: number,
	coins: number,
	atkLv: number,
	hpLv: number,
	maxStage: number,
	inv: { [string]: number },
	equipped: string,
}

local function defaultProfile(): Profile
	return {
		version = 1,
		coins = 0,
		atkLv = 0,
		hpLv = 0,
		maxStage = 0,
		inv = { [Config.STARTER_KEY] = 1 },
		equipped = Config.STARTER_KEY,
	}
end

local function bestKey(p: Profile): string
	local best, bestPower = Config.STARTER_KEY, -1
	for key in pairs(p.inv) do
		local power = Config.playerStats(key, p.atkLv, p.hpLv).power
		if power > bestPower then
			best, bestPower = key, power
		end
	end
	return best
end

local function sanitize(data: any): Profile
	local p = defaultProfile()
	if type(data) ~= "table" then
		return p
	end
	local function num(v, lo, hi)
		if type(v) ~= "number" or v ~= v then
			return lo
		end
		return math.clamp(v, lo, hi)
	end
	p.coins = num(data.coins, 0, math.huge)
	p.atkLv = math.floor(num(data.atkLv, 0, 100000))
	p.hpLv = math.floor(num(data.hpLv, 0, 100000))
	p.maxStage = math.floor(num(data.maxStage, 0, Config.MAX_GRADE))
	if type(data.inv) == "table" then
		local inv = {}
		for k, v in pairs(data.inv) do
			if Config.parseKey(k) and type(v) == "number" and v >= 1 then
				inv[k] = math.floor(v)
			end
		end
		if next(inv) then
			p.inv = inv
		end
	end
	if type(data.equipped) == "string" and p.inv[data.equipped] then
		p.equipped = data.equipped
	else
		p.equipped = bestKey(p)
	end
	return p
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
		warn("[Arena] 불러오기 실패 (" .. attempt .. "/3):", result)
		task.wait(1.5 * attempt)
	end
	-- 불러오기에 실패했을 때 저장까지 하면 기존 기록을 덮어쓰므로 저장을 끈다
	return defaultProfile(), false
end

------------------------------------------------------------------------
-- 플레이어 상태
------------------------------------------------------------------------
type Enemy = {
	model: Model,
	hum: Humanoid,
	root: BasePart,
	kind: string,
	cfg: any,
	accent: Color3,
	hp: number,
	maxHp: number,
	dmg: number,
	slamDmg: number,
	isBoss: boolean,
	alive: boolean,
	busy: boolean,
	reach: number,
	bodyRadius: number,
	scale: number,
	nextAttack: number,
	nextSpecial: number,
	nextMove: number,
	stunUntil: number,
	frozenUntil: number,
	poisonUntil: number,
	poisonDmg: number,
	nextPoison: number,
	markStacks: number,
	patterns: { string },
	patternIndex: number,
	fill: Frame,
	walkTrack: AnimationTrack?,
	walking: boolean,
}

type Session = {
	stage: number,
	info: any,
	arena: World.Arena,
	folder: Folder,
	enemies: { Enemy },
	waveIndex: number,
	waveSpawning: boolean,
	stats: any,
	hp: number,
	maxHp: number,
	invulnUntil: number,
	lastAttack: number,
	gauge: number,
	ulting: boolean,
	running: boolean,
	skillReadyAt: { number },
	poisonUntil: number,
	smokeCrit: number?,
	parryUntil: number,
	markTarget: Enemy?,
	zones: { any },
}

type State = {
	slot: number?,
	session: Session?,
	auto: boolean,
	canSave: boolean,
	dirty: boolean,
	reqCount: number,
	reqWindow: number,
	lastDash: number,
}

local profiles: { [Player]: Profile } = {}
local states: { [Player]: State } = {}

local function saveProfile(player: Player)
	local st, p, ds = states[player], profiles[player], store
	if not (st and p and ds and st.canSave) then
		return
	end
	local ok, err = pcall(function()
		ds:SetAsync("p_" .. player.UserId, p)
	end)
	if ok then
		st.dirty = false
	else
		warn("[Arena] 저장 실패:", err)
	end
end

local function getRoot(player: Player): (BasePart?, Humanoid?)
	local char = player.Character
	if not char then
		return nil, nil
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and hum and hum.Health > 0 then
		return root, hum
	end
	return nil, nil
end

local function currentStats(player: Player)
	local p = profiles[player]
	return Config.playerStats(p.equipped, p.atkLv, p.hpLv)
end

local function toast(player: Player, text: string)
	Push:FireClient(player, "toast", text)
end

local function pushState(player: Player)
	local p, st = profiles[player], states[player]
	if not p or not st then
		return
	end
	Push:FireClient(player, "state", {
		coins = p.coins,
		atkLv = p.atkLv,
		hpLv = p.hpLv,
		maxStage = p.maxStage,
		inv = p.inv,
		equipped = p.equipped,
		power = currentStats(player).power,
		auto = st.auto,
		canSave = st.canSave,
	})
end

local function aliveList(s: Session): { Enemy }
	local list = {}
	for _, e in ipairs(s.enemies) do
		if e.alive and e.root.Parent then
			table.insert(list, e)
		end
	end
	return list
end

local function aliveCount(s: Session): number
	local n = 0
	for _, e in ipairs(s.enemies) do
		if e.alive then
			n += 1
		end
	end
	return n
end

local function pushBattle(player: Player)
	local st = states[player]
	local s = st and st.session
	if not s then
		Push:FireClient(player, "battle", { active = false })
		return
	end
	Push:FireClient(player, "battle", {
		active = true,
		stage = s.stage,
		boss = s.info.isBoss,
		hp = s.hp,
		maxHp = s.maxHp,
		left = aliveCount(s),
		total = #s.enemies,
		wave = s.waveIndex,
		waveTotal = #s.info.waves,
		auto = st.auto,
		gauge = s.gauge,
		typeId = s.stats.weapon.typeId,
	})
end

-- 명예의 전당: 이 서버 최고 기록 5명
local function refreshHall()
	local list = {}
	for player, p in pairs(profiles) do
		if p.maxStage > 0 then
			table.insert(list, { name = player.DisplayName, stage = p.maxStage })
		end
	end
	table.sort(list, function(a, b)
		return a.stage > b.stage
	end)
	World.setHallOfFame(list)
end

------------------------------------------------------------------------
-- 칭호, 무기, 오라
------------------------------------------------------------------------
local function updateTitle(player: Player)
	local p = profiles[player]
	if not p then
		return
	end
	local ls = player:FindFirstChild("leaderstats")
	local rankName = p.maxStage > 0 and Config.getGrade(p.maxStage).en or "-"
	if ls then
		local rankValue = ls:FindFirstChild("등급")
		local stageValue = ls:FindFirstChild("스테이지")
		if rankValue and rankValue:IsA("StringValue") then
			rankValue.Value = rankName
		end
		if stageValue and stageValue:IsA("IntValue") then
			stageValue.Value = p.maxStage
		end
	end

	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("RankTitle")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "RankTitle"
	gui.Size = UDim2.new(0, 300, 0, 46)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 160
	gui.LightInfluence = 0
	local top = Instance.new("TextLabel")
	top.Size = UDim2.new(1, 0, 0.35, 0)
	top.BackgroundTransparency = 1
	top.Font = Enum.Font.GothamBold
	top.TextScaled = true
	top.TextColor3 = Color3.fromRGB(230, 220, 200)
	top.TextStrokeTransparency = 0.4
	top.Parent = gui
	local main = Instance.new("TextLabel")
	main.Position = UDim2.new(0, 0, 0.35, 0)
	main.Size = UDim2.new(1, 0, 0.65, 0)
	main.BackgroundTransparency = 1
	main.Font = Enum.Font.GothamBlack
	main.TextScaled = true
	main.TextStrokeTransparency = 0.15
	main.Parent = gui
	if p.maxStage <= 0 then
		top.Text = "도전자"
		main.Text = "NO RANK"
		main.TextColor3 = Color3.fromRGB(170, 170, 170)
	else
		local section, sectionIndex = Config.getSection(p.maxStage)
		top.Text = string.format("%d구간 · %s", sectionIndex, section.name)
		main.Text = string.format("[%d] %s", p.maxStage, rankName)
		main.TextStrokeColor3 = section.color:Lerp(Color3.new(0, 0, 0), 0.7)
		if section.rainbow then
			main.TextColor3 = Color3.new(1, 1, 1)
			local g = Instance.new("UIGradient")
			g.Color = WeaponBuilder.RAINBOW
			g.Parent = main
		else
			main.TextColor3 = section.color
		end
	end
	gui.Parent = head
end

local function attachWeapon(player: Player)
	local p = profiles[player]
	local char = player.Character
	if not p or not char then
		return
	end
	local old = char:FindFirstChild("ArenaWeapon")
	if old then
		old:Destroy()
	end
	local info = Config.weaponInfo(p.equipped)
	if not info then
		return
	end
	local right = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	local left = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
	if not (right and right:IsA("BasePart")) then
		return
	end
	local section, sectionIndex = Config.getSection(info.grade)
	if info.typeId == 0 then
		sectionIndex = 6
	end
	local look = {
		accent = info.typeId == 0 and Color3.fromRGB(255, 235, 160) or info.rarity.color,
		section = sectionIndex,
		rarity = info.rarity.rank,
		scale = 1 + (sectionIndex - 1) * 0.06,
	}
	local holder = Instance.new("Model")
	holder.Name = "ArenaWeapon"
	holder.Parent = char
	WeaponBuilder.build(holder, right, info.typeId, look)
	if info.typeId == 2 and left and left:IsA("BasePart") then
		WeaponBuilder.build(holder, left, 2, look)
	end
	WeaponBuilder.applyAura(char, sectionIndex, section.color)
end

------------------------------------------------------------------------
-- 적 만들기
------------------------------------------------------------------------
local rigTemplate: Model? = nil
local rigLoading = false

local function buildBlockRig(): Model
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.CFrame = root.CFrame * CFrame.new(0, 1.7, 0)
	head.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = head
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = 1.5
	hum.Parent = model
	model.PrimaryPart = root
	return model
end

local function getRigTemplate(): Model
	while rigLoading and not rigTemplate do
		task.wait(0.1)
	end
	if rigTemplate then
		return rigTemplate
	end
	rigLoading = true
	local ok, result = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	local model: Model
	if ok and result then
		model = result
	else
		warn("[Arena] 기본 인형을 만들지 못해 블록 인형을 씁니다:", result)
		model = buildBlockRig()
	end
	model.Name = "EnemyRig"
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BodyColors") or d:IsA("Clothing") or d:IsA("ShirtGraphic") then
			d:Destroy()
		end
	end
	model.Parent = ServerStorage
	rigTemplate = model
	rigLoading = false
	return model
end

local function makeHpBar(root: BasePart, title: string, sub: string, color: Color3, height: number, isBoss: boolean): Frame
	local gui = Instance.new("BillboardGui")
	gui.Name = "HpBar"
	gui.Size = isBoss and UDim2.new(0, 240, 0, 54) or UDim2.new(0, 150, 0, 42)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 130
	gui.LightInfluence = 0
	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.new(1, 0, 0.28, 0)
	tag.BackgroundTransparency = 1
	tag.Font = Enum.Font.GothamBold
	tag.TextScaled = true
	tag.TextColor3 = Color3.fromRGB(235, 225, 210)
	tag.TextStrokeTransparency = 0.3
	tag.Text = sub
	tag.Parent = gui
	local name = Instance.new("TextLabel")
	name.Position = UDim2.new(0, 0, 0.26, 0)
	name.Size = UDim2.new(1, 0, 0.4, 0)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBlack
	name.TextScaled = true
	name.TextColor3 = color
	name.TextStrokeTransparency = 0.2
	name.Text = title
	name.Parent = gui
	local back = Instance.new("Frame")
	back.Size = UDim2.new(1, 0, 0.26, 0)
	back.Position = UDim2.new(0, 0, 0.72, 0)
	back.BackgroundColor3 = Color3.fromRGB(25, 15, 15)
	back.BorderSizePixel = 0
	back.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = back
	local stroke = Instance.new("UIStroke")
	stroke.Color = isBoss and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(0, 0, 0)
	stroke.Thickness = isBoss and 2 or 1
	stroke.Parent = back
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fill.BorderSizePixel = 0
	fill.Parent = back
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromRGB(255, 120, 90), Color3.fromRGB(190, 30, 40))
	grad.Rotation = 90
	grad.Parent = fill
	gui.Parent = root
	return fill
end

local function spawnUnit(s: Session, kind: string, pos: Vector3, isBoss: boolean?)
	local cfg = Config.EnemyTypes[kind] or Config.EnemyTypes.grunt
	local grade = s.stage
	local model = getRigTemplate():Clone()
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not hum or not root or not root:IsA("BasePart") then
		model:Destroy()
		return
	end
	local section, sectionIndex = Config.getSection(grade)
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = isBoss and 11 or cfg.speed
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

	local scale = section.scale * cfg.scale * (isBoss and 1.8 or 1)
	pcall(function()
		model:ScaleTo(scale)
	end)
	model.Name = (isBoss and "BOSS " or "") .. Config.getGrade(grade).en
	model:SetAttribute("Enemy", true)
	model:PivotTo(CFrame.lookAt(pos + Vector3.new(0, 4 * scale, 0), s.arena.center + Vector3.new(0, 4 * scale, 0)))
	EnemyBuilder.dress(model, kind, section.color, sectionIndex, isBoss == true, scale, WeaponBuilder.RAINBOW)
	model.Parent = s.folder
	pcall(function()
		(root :: BasePart):SetNetworkOwner(nil)
	end)

	local walkTrack: AnimationTrack? = nil
	pcall(function()
		local animator = hum:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = hum
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = WALK_ANIM_ID
		local track = (animator :: Animator):LoadAnimation(anim)
		track.Looped = true
		walkTrack = track
	end)

	local info = s.info
	local hp = isBoss and info.bossHp or info.unitHp * cfg.hp
	local dmg = isBoss and info.bossDmg or info.unitDmg * cfg.dmg
	local title = string.format("%s[%d] %s", isBoss and "👑 " or "", grade, Config.getGrade(grade).en)
	local sub = isBoss and ("BOSS · " .. cfg.name) or cfg.name
	local fill = makeHpBar(root, title, sub, isBoss and Color3.fromRGB(255, 110, 90) or section.color, 3.4 * scale, isBoss == true)
	local now = os.clock()
	table.insert(s.enemies, {
		model = model,
		hum = hum,
		root = root,
		kind = kind,
		cfg = cfg,
		accent = section.color,
		hp = hp,
		maxHp = hp,
		dmg = dmg,
		slamDmg = info.slamDmg,
		isBoss = isBoss == true,
		alive = true,
		busy = false,
		reach = 4.5 * scale,
		bodyRadius = 1.2 * scale,
		scale = scale,
		nextAttack = now + 1 + math.random(),
		nextSpecial = now + 2 + math.random() * 2,
		nextMove = 0,
		stunUntil = 0,
		frozenUntil = 0,
		poisonUntil = 0,
		poisonDmg = 0,
		nextPoison = 0,
		markStacks = 0,
		patterns = isBoss and info.bossPatterns or {},
		patternIndex = 1,
		fill = fill,
		walkTrack = walkTrack,
		walking = false,
	})
end

local function updateWalk(e: Enemy, now: number)
	local track = e.walkTrack
	if not track then
		return
	end
	local moving = e.alive and now >= e.frozenUntil and e.root.AssemblyLinearVelocity.Magnitude > 1.5
	if moving ~= e.walking then
		e.walking = moving
		if moving then
			track:Play(0.15)
		else
			track:Stop(0.15)
		end
	end
	if now < e.frozenUntil then
		track:AdjustSpeed(0)
	elseif track.Speed == 0 then
		track:AdjustSpeed(1)
	end
end

local function flashEnemy(e: Enemy, color: Color3, duration: number)
	local h = Instance.new("Highlight")
	h.FillColor = color
	h.FillTransparency = 0.3
	h.OutlineTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = e.model
	Debris:AddItem(h, duration)
end

------------------------------------------------------------------------
-- 전투 기본
------------------------------------------------------------------------
local startStage: (Player, any, boolean) -> ()
local loseBattle: (Player, State, Session) -> ()

local function endSession(player: Player, st: State)
	local s = st.session
	if not s then
		return
	end
	s.running = false
	st.session = nil
	s.folder:Destroy()
	pushBattle(player)
end

local function teleportToLobby(player: Player)
	local char = player.Character
	if char then
		local offset = Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
		char:PivotTo(lobbySpawn + offset)
	end
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function flatUnit(v: Vector3): Vector3
	local f = flat(v)
	if f.Magnitude < 0.001 then
		return Vector3.new(0, 0, -1)
	end
	return f.Unit
end

local function weaponColor(stats: any): Color3
	return stats.weapon.typeId == 0 and Color3.fromRGB(255, 235, 160) or stats.weapon.rarity.color
end

local function killEnemy(player: Player, s: Session, e: Enemy, selfDestruct: boolean?)
	if not e.alive then
		return
	end
	e.alive = false
	e.model:SetAttribute("Dead", true)
	e.hum.WalkSpeed = 0
	if s.markTarget == e then
		s.markTarget = nil
	end
	if not selfDestruct then
		Push:FireClient(player, "kill", { pos = e.root.Position, color = e.accent, boss = e.isBoss, scale = e.scale })
	end
	for _, d in ipairs(e.model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Transparency = 0.6
		elseif d:IsA("ParticleEmitter") or d:IsA("Sparkles") or d:IsA("Fire") then
			d.Enabled = false
		end
	end
	Debris:AddItem(e.model, selfDestruct and 0.05 or 0.45)
end

-- 적 하나에게 피해. 방패병은 앞에서 오는 공격을 막고, 치명타는 적을 날려 보낸다
local function hitEnemy(player: Player, s: Session, e: Enemy, dmg: number, crit: boolean, fromPos: Vector3, hits: { any }, opts: any?)
	if not e.alive then
		return 0
	end
	local kind = crit and "crit" or "hit"
	local reduce = e.cfg.frontReduce
	if reduce and not (opts and opts.pierce) and os.clock() >= e.stunUntil then
		local facing = flatUnit(e.root.CFrame.LookVector)
		if facing:Dot(flatUnit(fromPos - e.root.Position)) > 0.3 then
			dmg *= (1 - reduce)
			kind = "block"
		end
	end
	e.hp -= dmg
	table.insert(hits, {
		pos = e.root.Position + Vector3.new(0, 2.5 * e.scale, 0),
		text = Config.formatNumber(dmg),
		kind = kind,
		color = e.accent,
	})
	if crit and not e.isBoss then
		e.root.AssemblyLinearVelocity = flatUnit(e.root.Position - fromPos) * 38 + Vector3.new(0, 22, 0)
	end
	if e.hp <= 0 then
		killEnemy(player, s, e)
	else
		e.fill.Size = UDim2.fromScale(math.clamp(e.hp / e.maxHp, 0, 1), 1)
	end
	return dmg
end

local function sendHits(player: Player, hits: { any })
	if #hits > 0 then
		Push:FireClient(player, "hits", hits)
	end
end

-- 모듈들이 쓰는 도구 묶음 (아래에서 채운다)
local ctx: any = nil

local function damagePlayer(player: Player, st: State, s: Session, amount: number)
	if not s.running or os.clock() < s.invulnUntil then
		return
	end
	if Skills.tryParry(ctx, player, s) then
		return
	end
	s.hp -= amount
	local root = getRoot(player)
	if root then
		Push:FireClient(player, "hits", {
			{ pos = root.Position + Vector3.new(0, 3, 0), text = "-" .. Config.formatNumber(amount), kind = "hurt" },
		})
	end
	if s.hp <= 0 then
		s.hp = 0
		loseBattle(player, st, s)
	else
		pushBattle(player)
	end
end

local function rollDamage(stats: any): (number, boolean)
	local wt = stats.weapon.type
	local dmg = stats.atk * (0.9 + math.random() * 0.2)
	local crit = wt.critChance ~= nil and math.random() < wt.critChance
	if crit then
		dmg *= wt.critMult
	end
	return dmg, crit
end

-- 경고 표시: 바닥 원, 바닥 길
local function warnDisc(s: Session, pos: Vector3, radius: number, duration: number)
	local disc = World.part({
		Name = "Warning",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.25, radius * 2, radius * 2),
		CFrame = CFrame.new(pos.X, s.arena.center.Y + 0.15, pos.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 40, 40),
		Material = Enum.Material.Neon,
		Transparency = 0.6,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = s.folder,
	})
	disc:SetAttribute("Warn", duration)
	Debris:AddItem(disc, duration)
	return disc
end

local function warnLane(s: Session, from: Vector3, dir: Vector3, length: number, width: number, duration: number)
	local mid = Vector3.new(from.X, s.arena.center.Y + 0.15, from.Z) + dir * (length / 2)
	local lane = World.part({
		Name = "Warning",
		Size = Vector3.new(width, 0.2, length),
		CFrame = CFrame.lookAt(mid, mid + dir),
		Color = Color3.fromRGB(255, 40, 40),
		Material = Enum.Material.Neon,
		Transparency = 0.6,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = s.folder,
	})
	lane:SetAttribute("Warn", duration)
	Debris:AddItem(lane, duration)
	return lane
end

local function nearSegment(s: Session, a: Vector3, b: Vector3, width: number): { Enemy }
	local list = {}
	local ab = flat(b - a)
	local len = ab.Magnitude
	local dir = len > 0 and ab.Unit or Vector3.new(0, 0, -1)
	for _, e in ipairs(aliveList(s)) do
		local off = flat(e.root.Position - a)
		local along = math.clamp(off:Dot(dir), 0, len)
		if (off - dir * along).Magnitude <= width + e.bodyRadius then
			table.insert(list, e)
		end
	end
	return list
end

ctx = {
	arenaRadius = ARENA_RADIUS,
	push = function(player: Player, kind: string, data: any)
		Push:FireClient(player, kind, data)
	end,
	toast = toast,
	getRoot = getRoot,
	alive = aliveList,
	aliveCount = aliveCount,
	nearSegment = nearSegment,
	hitEnemy = hitEnemy,
	sendHits = sendHits,
	killEnemy = killEnemy,
	pushBattle = pushBattle,
	flash = flashEnemy,
	warnDisc = warnDisc,
	warnLane = warnLane,
	spawnUnit = function(s: Session, kind: string, pos: Vector3)
		spawnUnit(s, kind, pos, false)
	end,
	heal = function(s: Session, amount: number)
		s.hp = math.min(s.maxHp, s.hp + amount)
	end,
	color = function(s: Session): Color3
		return weaponColor(s.stats)
	end,
	isCurrent = function(s: Session): boolean
		for _, st in pairs(states) do
			if st.session == s then
				return true
			end
		end
		return false
	end,
	damagePlayer = function(player: Player, st: State, s: Session, amount: number)
		damagePlayer(player, st, s, amount)
	end,
}

------------------------------------------------------------------------
-- 기본 공격
------------------------------------------------------------------------
local function performAttack(player: Player, st: State, s: Session)
	if not s.running or s.ulting then
		return
	end
	local stats = s.stats
	local now = os.clock()
	if now - s.lastAttack < stats.cooldown - 0.03 then
		return
	end
	local root = getRoot(player)
	if not root then
		return
	end
	local wt = stats.weapon.type
	local origin = flat(root.Position)
	local look = flatUnit(root.CFrame.LookVector)

	local inRange = {}
	for _, e in ipairs(aliveList(s)) do
		local offset = flat(e.root.Position) - origin
		local dist = offset.Magnitude - e.bodyRadius
		if dist <= wt.range then
			table.insert(inRange, { e = e, dist = dist, offset = offset })
		end
	end
	if #inRange == 0 then
		return
	end
	table.sort(inRange, function(a, b)
		return a.dist < b.dist
	end)

	local targets: { Enemy } = {}
	if wt.mode == "around" then
		for _, c in ipairs(inRange) do
			table.insert(targets, c.e)
		end
	elseif wt.mode == "line" then
		for _, c in ipairs(inRange) do
			local facing = c.offset.Magnitude < 4 or (c.offset.Unit:Dot(look) > 0.2)
			if facing then
				table.insert(targets, c.e)
				if #targets >= (wt.maxTargets or 3) then
					break
				end
			end
		end
		if #targets == 0 then
			table.insert(targets, inRange[1].e)
		end
	else
		table.insert(targets, inRange[1].e)
	end

	s.lastAttack = now
	local hits = {}
	local healed = 0
	local anyCrit = false
	for i, e in ipairs(targets) do
		local dmg, crit = rollDamage(stats)
		if i == 1 and s.smokeCrit then
			dmg = stats.atk * (wt.critMult or 2) * s.smokeCrit
			crit = true
			s.smokeCrit = nil
		end
		anyCrit = anyCrit or crit
		hitEnemy(player, s, e, dmg, crit, root.Position, hits)
		Skills.onBasicHit(ctx, player, s, e, hits)
		if wt.lifesteal then
			healed += dmg * wt.lifesteal
		end
	end
	if healed > 0 then
		s.hp = math.min(s.maxHp, s.hp + healed)
	end
	s.gauge = math.min(100, s.gauge + Config.ULT_GAIN * stats.cooldown)

	local _, sectionIndex = Config.getSection(stats.weapon.grade)
	Push:FireClient(player, "swing", {
		typeId = stats.weapon.typeId,
		mode = wt.mode,
		range = wt.range,
		section = stats.weapon.typeId == 0 and 6 or sectionIndex,
		color = weaponColor(stats),
		crit = anyCrit,
		poison = now < s.poisonUntil,
	})
	sendHits(player, hits)
	pushBattle(player)
end

------------------------------------------------------------------------
-- 필살기
------------------------------------------------------------------------
local function runUltimate(player: Player, st: State, s: Session)
	local root = getRoot(player)
	local char = player.Character
	if not root or not char then
		return
	end
	local stats = s.stats
	local typeId = stats.weapon.typeId
	local ult = Config.Ultimates[typeId] or Config.Ultimates[1]
	s.gauge = 0
	s.ulting = true
	s.invulnUntil = math.max(s.invulnUntil, os.clock() + 1.0)

	local origin = root.Position
	local look = flatUnit(root.CFrame.LookVector)
	local hits = {}
	local pierce = { pierce = true }
	local data: { [string]: any } = {
		typeId = typeId,
		name = ult.name,
		origin = origin,
		look = look,
		color = weaponColor(stats),
	}

	local function finish(heal: number?)
		if heal and heal > 0 then
			s.hp = math.min(s.maxHp, s.hp + s.maxHp * heal)
		end
		sendHits(player, hits)
		pushBattle(player)
	end

	if typeId == 1 then
		local target = origin + look * ult.length
		data.length = ult.length
		Push:FireClient(player, "ult", data)
		task.wait(0.25)
		for _, e in ipairs(nearSegment(s, origin, target, ult.width)) do
			hitEnemy(player, s, e, stats.atk * ult.mult, true, origin, hits, pierce)
		end
		finish()
	elseif typeId == 2 then
		data.radius = ult.radius
		data.duration = ult.ticks * ult.interval
		Push:FireClient(player, "ult", data)
		for _ = 1, ult.ticks do
			if not s.running then
				break
			end
			local r = getRoot(player)
			if not r then
				break
			end
			hits = {}
			for _, e in ipairs(aliveList(s)) do
				if (flat(e.root.Position) - flat(r.Position)).Magnitude <= ult.radius + e.bodyRadius then
					local dmg, crit = rollDamage(stats)
					hitEnemy(player, s, e, dmg * ult.mult, crit, r.Position, hits, pierce)
				end
			end
			sendHits(player, hits)
			pushBattle(player)
			task.wait(ult.interval)
		end
		hits = {}
		finish()
	elseif typeId == 3 then
		local center = s.arena.center
		local target = origin + look * ult.length
		local fromCenter = flat(target - center)
		local limit = ARENA_RADIUS - 6
		if fromCenter.Magnitude > limit then
			target = center + fromCenter.Unit * limit + Vector3.new(0, origin.Y - center.Y, 0)
		end
		data.target = target
		Push:FireClient(player, "ult", data)
		char:PivotTo(CFrame.lookAt(target, target + look))
		for _, e in ipairs(nearSegment(s, origin, target, ult.width)) do
			hitEnemy(player, s, e, stats.atk * ult.mult, true, origin, hits, pierce)
		end
		finish()
	elseif typeId == 4 then
		local best: Enemy? = nil
		for _, e in ipairs(aliveList(s)) do
			if not best or e.hp > best.hp then
				best = e
			end
		end
		if best then
			local victim = best
			local behind = victim.root.Position - flatUnit(victim.root.CFrame.LookVector) * (3 + victim.bodyRadius)
			data.target = victim.root.Position
			Push:FireClient(player, "ult", data)
			char:PivotTo(CFrame.lookAt(behind, Vector3.new(victim.root.Position.X, behind.Y, victim.root.Position.Z)))
			local wt = stats.weapon.type
			for _ = 1, ult.hits do
				if not victim.alive then
					break
				end
				hits = {}
				hitEnemy(player, s, victim, stats.atk * (wt.critMult or 2) * ult.mult, true, behind, hits, pierce)
				sendHits(player, hits)
				task.wait(0.12)
			end
			hits = {}
		else
			Push:FireClient(player, "ult", data)
		end
		finish()
	elseif typeId == 5 then
		local inCircle = {}
		local victims = {}
		for _, e in ipairs(aliveList(s)) do
			if (flat(e.root.Position) - flat(origin)).Magnitude <= ult.radius + e.bodyRadius then
				table.insert(inCircle, e)
				table.insert(victims, e.root.Position)
			end
		end
		data.radius = ult.radius
		data.victims = victims
		Push:FireClient(player, "ult", data)
		task.wait(0.3)
		for _, e in ipairs(inCircle) do
			hitEnemy(player, s, e, stats.atk * ult.mult, true, origin, hits, pierce)
		end
		finish(ult.heal)
	else
		data.radius = ARENA_RADIUS
		Push:FireClient(player, "ult", data)
		task.wait(0.4)
		for _, e in ipairs(aliveList(s)) do
			hitEnemy(player, s, e, stats.atk * ult.mult, true, origin, hits, pierce)
		end
		finish(ult.heal)
	end
end

local function useUltimate(player: Player, st: State, s: Session)
	if not s.running or s.ulting or s.gauge < 100 then
		return
	end
	local ok, err = pcall(runUltimate, player, st, s)
	s.ulting = false
	if not ok then
		warn("[Arena] 필살기 오류:", err)
	end
end

------------------------------------------------------------------------
-- 웨이브와 승패
------------------------------------------------------------------------
local function spawnWave(player: Player, s: Session, index: number)
	local info = s.info
	local list = info.waves[index]
	local isLast = index == #info.waves
	local count = #list
	local spin = math.random() * math.pi * 2
	for i, kind in ipairs(list) do
		local a = spin + (i / count) * math.pi * 2
		local pos = s.arena.center + Vector3.new(math.cos(a), 0, math.sin(a)) * ENEMY_SPAWN_RADIUS
		Push:FireClient(player, "summon", { pos = pos })
		spawnUnit(s, kind, pos, false)
	end
	if info.isBoss and isLast then
		local pos = s.arena.center + Vector3.new(0, 0, -ENEMY_SPAWN_RADIUS)
		spawnUnit(s, info.bossType, pos, true)
		Push:FireClient(player, "boss", {
			name = Config.getGrade(s.stage).en,
			kind = Config.EnemyTypes[info.bossType].name,
			pos = pos,
		})
	end
	Push:FireClient(player, "wave", { index = index, total = #info.waves, boss = info.isBoss and isLast })
	pushBattle(player)
end

local function winBattle(player: Player, st: State, s: Session)
	s.running = false
	local p = profiles[player]
	local info = s.info
	local n = s.stage
	p.coins += info.coins
	local drops = {}
	local count = info.dropCount + ((math.random() < info.bonusDropChance) and 1 or 0)
	for _ = 1, count do
		local key = Config.itemKey(n, math.random(1, 5))
		p.inv[key] = (p.inv[key] or 0) + 1
		table.insert(drops, key)
	end
	local firstClear = n > p.maxStage
	if firstClear then
		p.maxStage = n
		updateTitle(player)
		refreshHall()
	end
	st.dirty = true

	local again = st.auto and Config.canAutoRepeat(n, p.maxStage, currentStats(player).power)
	if st.auto and not again then
		st.auto = false
		toast(player, "전투력이 부족해서 자동 반복을 멈췄어요")
	end
	Push:FireClient(player, "result", {
		win = true,
		stage = n,
		coins = info.coins,
		drops = drops,
		firstClear = firstClear,
		again = again,
	})
	pushState(player)

	task.delay(again and 2 or 3, function()
		if st.session ~= s then
			return
		end
		endSession(player, st)
		if again and st.auto and player.Parent then
			startStage(player, n, true)
		else
			teleportToLobby(player)
		end
	end)
end

loseBattle = function(player: Player, st: State, s: Session)
	if not s.running then
		return
	end
	s.running = false
	st.auto = false
	Push:FireClient(player, "result", { win = false, stage = s.stage })
	pushBattle(player)
	pushState(player)
	task.delay(2.5, function()
		if st.session ~= s then
			return
		end
		endSession(player, st)
		teleportToLobby(player)
	end)
end

local function autoSkills(player: Player, st: State, s: Session, root: BasePart, now: number)
	if s.gauge >= 100 then
		task.spawn(useUltimate, player, st, s)
		return
	end
	local nearest = math.huge
	for _, e in ipairs(aliveList(s)) do
		nearest = math.min(nearest, (flat(e.root.Position) - flat(root.Position)).Magnitude)
	end
	if nearest < 16 then
		for slot = 1, 2 do
			if now >= s.skillReadyAt[slot] then
				Skills.cast(ctx, player, st, s, slot)
				return
			end
		end
	end
	performAttack(player, st, s)
end

local function battleLoop(player: Player, st: State, s: Session)
	while s.running and st.session == s do
		local root = getRoot(player)
		if not root or root.Position.Y < s.arena.center.Y - 40 then
			loseBattle(player, st, s)
			return
		end
		local now = os.clock()
		local alive = 0
		local poisonHits = {}
		for _, e in ipairs(s.enemies) do
			if e.alive then
				if not e.root.Parent then
					e.alive = false
				else
					alive += 1
					updateWalk(e, now)
					if now < e.poisonUntil and now >= e.nextPoison then
						e.nextPoison = now + 0.5
						hitEnemy(player, s, e, e.poisonDmg, false, e.root.Position, poisonHits, { pierce = true })
						poisonHits[#poisonHits].kind = "poison"
					elseif now >= e.poisonUntil and e.poisonUntil > 0 then
						e.poisonUntil = 0
						e.model:SetAttribute("Poison", nil)
					end
					if e.alive then
						EnemyAI.tick(ctx, player, st, s, e, root, now)
					end
				end
			end
		end
		sendHits(player, poisonHits)
		Skills.tickZones(ctx, player, s, now)

		if alive == 0 and not s.ulting and not s.waveSpawning then
			if s.waveIndex < #s.info.waves then
				s.waveSpawning = true
				s.waveIndex += 1
				local nextWave = s.waveIndex
				task.delay(1.2, function()
					if s.running and st.session == s then
						spawnWave(player, s, nextWave)
					end
					s.waveSpawning = false
				end)
				-- 웨이브를 깨면 체력 30% 회복
				s.hp = math.min(s.maxHp, s.hp + s.maxHp * 0.3)
				Push:FireClient(player, "waveClear", { index = nextWave - 1, heal = 0.3 })
				pushBattle(player)
			else
				winBattle(player, st, s)
				return
			end
		end
		if st.auto and not s.ulting then
			autoSkills(player, st, s, root, now)
		end
		task.wait(0.1)
	end
end

startStage = function(player: Player, stageArg: any, wantAuto: boolean)
	local st, p = states[player], profiles[player]
	if not st or not p or st.session then
		return
	end
	local n = math.floor(tonumber(stageArg) or 0)
	if n < 1 or n > Config.MAX_GRADE then
		return
	end
	if n > p.maxStage + 1 then
		toast(player, "아직 열리지 않은 스테이지예요")
		return
	end
	local root = getRoot(player)
	local char = player.Character
	if not root or not char then
		return
	end
	local stats = currentStats(player)
	if wantAuto and not Config.canAutoRepeat(n, p.maxStage, stats.power) then
		toast(player, "자동 반복은 이긴 적 있는 스테이지에서, 권장 전투력의 1.5배 이상일 때 할 수 있어요")
		wantAuto = false
	end
	st.auto = wantAuto

	local slot = st.slot
	if not slot then
		slot = claimSlot(player)
		st.slot = slot
	end
	local arena = arenas[slot :: number]
	local info = Config.stageInfo(n)
	World.themeArena(arena, Config.getSection(n).color, info.isBoss)
	local folder = Instance.new("Folder")
	folder.Name = "P_" .. player.UserId
	folder.Parent = battleRoot

	local s: Session = {
		stage = n,
		info = info,
		arena = arena,
		folder = folder,
		enemies = {},
		waveIndex = 1,
		waveSpawning = false,
		stats = stats,
		hp = stats.maxHp,
		maxHp = stats.maxHp,
		invulnUntil = 0,
		lastAttack = 0,
		gauge = 0,
		ulting = false,
		running = true,
		skillReadyAt = { 0, 0 },
		poisonUntil = 0,
		smokeCrit = nil,
		parryUntil = 0,
		markTarget = nil,
		zones = {},
	}
	st.session = s
	char:PivotTo(CFrame.new(arena.center + Vector3.new(0, 4, 0)))
	Push:FireClient(player, "battleStart", { stage = n, pos = arena.center, color = Config.getSection(n).color, boss = info.isBoss })
	spawnWave(player, s, 1)
	pushState(player)
	task.spawn(battleLoop, player, st, s)
end

------------------------------------------------------------------------
-- 무기 관리
------------------------------------------------------------------------
local function refreshStats(player: Player)
	local st = states[player]
	local s = st and st.session
	if s then
		local ratio = s.hp / s.maxHp
		local stats = currentStats(player)
		s.stats = stats
		s.maxHp = stats.maxHp
		s.hp = math.max(1, ratio * stats.maxHp)
		pushBattle(player)
	end
	attachWeapon(player)
	st.dirty = true
	pushState(player)
end

local function equip(player: Player, key: any)
	local p = profiles[player]
	if type(key) ~= "string" or not Config.parseKey(key) or (p.inv[key] or 0) < 1 then
		return
	end
	p.equipped = key
	refreshStats(player)
	Push:FireClient(player, "equipped", key)
end

local function mergeOnce(p: Profile, key: string): string?
	local g, t = Config.parseKey(key)
	if not g or t == 0 or g >= Config.MAX_GRADE then
		return nil
	end
	local cost = Config.mergeCost(g)
	local have = p.inv[key] or 0
	if have < cost then
		return nil
	end
	local left = have - cost
	p.inv[key] = left > 0 and left or nil
	local newKey = Config.itemKey(g + 1, t)
	p.inv[newKey] = (p.inv[newKey] or 0) + 1
	if p.equipped == key and left <= 0 then
		p.equipped = newKey
	end
	return newKey
end

-- 합성할 때마다 로비 용광로가 불을 뿜는다 (모두에게 보인다)
local function forgeFlash(key: string)
	local info = Config.weaponInfo(key)
	local color = info and (info.typeId == 0 and Color3.fromRGB(255, 235, 160) or info.rarity.color) or Color3.fromRGB(255, 160, 60)
	Push:FireAllClients("forge", { color = color, legendary = info ~= nil and info.rarity.rank >= 5 })
end

local function merge(player: Player, key: any)
	local p = profiles[player]
	if type(key) ~= "string" then
		return
	end
	local g = Config.parseKey(key)
	if not g then
		return
	end
	local newKey = mergeOnce(p, key)
	if not newKey then
		toast(player, string.format("합성하려면 같은 칼이 %d개 필요해요", Config.mergeCost(g)))
		return
	end
	Push:FireClient(player, "merged", { from = key, to = newKey, count = 1 })
	forgeFlash(newKey)
	refreshStats(player)
end

local function mergeAll(player: Player)
	local p = profiles[player]
	local count = 0
	local best: string? = nil
	for g = 1, Config.MAX_GRADE - 1 do
		for t = 1, 5 do
			local key = Config.itemKey(g, t)
			while true do
				local made = mergeOnce(p, key)
				if not made then
					break
				end
				count += 1
				best = made
			end
		end
	end
	if count == 0 then
		toast(player, "지금 합성할 수 있는 칼이 없어요")
		return
	end
	Push:FireClient(player, "merged", { count = count, to = best })
	if best then
		forgeFlash(best)
	end
	refreshStats(player)
end

local function makeAllRounder(player: Player)
	local p = profiles[player]
	for t = 1, 5 do
		if (p.inv[Config.itemKey(Config.MAX_GRADE, t)] or 0) < 1 then
			toast(player, "100등급 대검·쌍검·장검·단검·낫이 하나씩 필요해요")
			return
		end
	end
	for t = 1, 5 do
		local key = Config.itemKey(Config.MAX_GRADE, t)
		local left = p.inv[key] - 1
		p.inv[key] = left > 0 and left or nil
	end
	p.inv[Config.ALLROUNDER_KEY] = (p.inv[Config.ALLROUNDER_KEY] or 0) + 1
	p.equipped = Config.ALLROUNDER_KEY
	Push:FireClient(player, "merged", { to = Config.ALLROUNDER_KEY, count = 1 })
	forgeFlash(Config.ALLROUNDER_KEY)
	refreshStats(player)
end

local function train(player: Player, kind: any)
	local p = profiles[player]
	local field
	if kind == "atk" then
		field = "atkLv"
	elseif kind == "hp" then
		field = "hpLv"
	else
		return
	end
	local level = (p :: any)[field]
	local cost = Config.trainCost(level)
	if p.coins < cost then
		toast(player, "코인이 부족해요")
		return
	end
	p.coins -= cost;
	(p :: any)[field] = level + 1
	Push:FireClient(player, "trained", kind)
	refreshStats(player)
end

local function setAuto(player: Player, st: State, on: boolean)
	local s = st.session
	if not on then
		st.auto = false
	elseif s then
		local p = profiles[player]
		local power = currentStats(player).power
		if s.stage > p.maxStage then
			toast(player, "한 번 이긴 스테이지만 자동 반복할 수 있어요")
		elseif not Config.canAutoRepeat(s.stage, p.maxStage, power) then
			toast(player, "전투력이 " .. Config.formatNumber(Config.recommendedPower(s.stage) * Config.AUTO_POWER_RATIO) .. " 이상이어야 해요")
		else
			st.auto = true
		end
	end
	pushBattle(player)
	pushState(player)
end

------------------------------------------------------------------------
-- 요청 처리
------------------------------------------------------------------------
Request.OnServerEvent:Connect(function(player: Player, action: any, arg: any, arg2: any)
	local st, p = states[player], profiles[player]
	if not st or not p or type(action) ~= "string" then
		return
	end
	local now = os.clock()
	if now - st.reqWindow > 1 then
		st.reqWindow = now
		st.reqCount = 0
	end
	st.reqCount += 1
	if st.reqCount > 40 then
		return
	end

	if action == "attack" then
		local s = st.session
		if s and s.running then
			performAttack(player, st, s)
		end
	elseif action == "skill" then
		local s = st.session
		if s and s.running and (arg == 1 or arg == 2) then
			Skills.cast(ctx, player, st, s, arg)
			pushBattle(player)
		end
	elseif action == "ultimate" then
		local s = st.session
		if s and s.running then
			task.spawn(useUltimate, player, st, s)
		end
	elseif action == "dash" then
		local s = st.session
		if s and s.running and now - st.lastDash >= Config.DASH_COOLDOWN - 0.15 then
			st.lastDash = now
			s.invulnUntil = math.max(s.invulnUntil, now + Config.DASH_INVULN)
		end
	elseif action == "start" then
		startStage(player, arg, arg2 == true)
	elseif action == "leave" then
		if st.session then
			st.auto = false
			endSession(player, st)
			teleportToLobby(player)
			pushState(player)
		end
	elseif action == "auto" then
		setAuto(player, st, arg == true)
	elseif action == "equip" then
		equip(player, arg)
	elseif action == "equipBest" then
		equip(player, bestKey(p))
	elseif action == "merge" then
		merge(player, arg)
	elseif action == "mergeAll" then
		mergeAll(player)
	elseif action == "allrounder" then
		makeAllRounder(player)
	elseif action == "train" then
		train(player, arg)
	elseif action == "hello" then
		pushState(player)
		pushBattle(player)
		if not st.canSave then
			toast(player, "저장이 꺼져 있어요. 이번 기록은 저장되지 않아요")
		end
	end
end)

------------------------------------------------------------------------
-- 입장과 퇴장
------------------------------------------------------------------------
local function onCharacterAdded(player: Player, char: Model)
	local st = states[player]
	if st and st.session then
		st.auto = false
		endSession(player, st)
		pushState(player)
	end
	task.spawn(function()
		char:WaitForChild("Head", 10)
		char:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.2)
		if player.Character ~= char then
			return
		end
		attachWeapon(player)
		updateTitle(player)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Died:Connect(function()
				local s2 = states[player]
				local s = s2 and s2.session
				if s2 and s then
					loseBattle(player, s2, s)
				end
			end)
		end
	end)
end

local function onPlayerAdded(player: Player)
	local st: State = {
		slot = nil,
		session = nil,
		auto = false,
		canSave = false,
		dirty = false,
		reqCount = 0,
		reqWindow = 0,
		lastDash = 0,
	}
	states[player] = st

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local rank = Instance.new("StringValue")
	rank.Name = "등급"
	rank.Value = "-"
	rank.Parent = ls
	local stage = Instance.new("IntValue")
	stage.Name = "스테이지"
	stage.Parent = ls
	ls.Parent = player

	local profile, ok = loadProfile(player)
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
	updateTitle(player)
	refreshHall()
	pushState(player)
end

local function onPlayerRemoving(player: Player)
	local st = states[player]
	if st then
		if st.session then
			endSession(player, st)
		end
		if st.slot then
			slotOwner[st.slot] = nil
		end
	end
	saveProfile(player)
	states[player] = nil
	profiles[player] = nil
	refreshHall()
end

task.spawn(function()
	World.buildStatue(getRigTemplate())
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- 주기적 저장
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
