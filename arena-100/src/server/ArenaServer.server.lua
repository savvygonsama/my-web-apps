-- ArenaServer (Script, ServerScriptService)
-- 전투, 합성, 훈련, 저장, 투기장 생성을 맡는다.
-- 중요한 계산은 전부 서버에서 하고, 클라이언트는 요청만 보낸다.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local ARENA_ORIGIN = Vector3.new(0, 300, 1600)
local ARENA_SPACING = 320
local ARENA_RADIUS = 60
local ENEMY_SPAWN_RADIUS = 35
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
-- 맵 만들기
------------------------------------------------------------------------
local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	return p
end

local lobbySpawn: CFrame = CFrame.new(0, 4, 0)

local function buildLobby()
	local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if not spawn then
		if not workspace:FindFirstChild("Baseplate") then
			makePart({
				Name = "Baseplate",
				Size = Vector3.new(400, 2, 400),
				Position = Vector3.new(0, -1, 0),
				Color = Color3.fromRGB(95, 140, 75),
				Material = Enum.Material.Grass,
				Parent = workspace,
			})
		end
		local sp = Instance.new("SpawnLocation")
		sp.Name = "LobbySpawn"
		sp.Anchored = true
		sp.Size = Vector3.new(14, 1, 14)
		sp.Position = Vector3.new(0, 0.5, 0)
		sp.Color = Color3.fromRGB(230, 180, 60)
		sp.Material = Enum.Material.Marble
		sp.Neutral = true
		sp.Duration = 0
		sp.Parent = workspace
		spawn = sp
	end
	if spawn then
		lobbySpawn = CFrame.new(spawn.Position + Vector3.new(0, 4, 0))
	end

	-- 로비 간판
	local sign = makePart({
		Name = "ArenaSign",
		Size = Vector3.new(34, 12, 1),
		CFrame = CFrame.new(lobbySpawn.Position + Vector3.new(0, 8, -30)),
		Color = Color3.fromRGB(35, 25, 20),
		Material = Enum.Material.Wood,
		Parent = workspace,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = sign
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.6, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 200, 70)
	title.Text = Config.GAME_TITLE
	title.Parent = gui
	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0.3, 0)
	sub.Position = UDim2.new(0, 0, 0.62, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(240, 230, 210)
	sub.Text = "왼쪽 [스테이지] 버튼을 눌러 투기장에 입장하세요"
	sub.Parent = gui
end

type Arena = { center: Vector3, model: Model }
local arenas: { [number]: Arena } = {}
local slotOwner: { [number]: Player } = {}

local CROWD_COLORS = {
	Color3.fromRGB(220, 80, 70),
	Color3.fromRGB(70, 130, 220),
	Color3.fromRGB(240, 200, 80),
	Color3.fromRGB(90, 190, 110),
	Color3.fromRGB(200, 120, 220),
	Color3.fromRGB(245, 245, 245),
}

local function buildArena(index: number): Arena
	local center = ARENA_ORIGIN + Vector3.new((index - 1) * ARENA_SPACING, 0, 0)
	local model = Instance.new("Model")
	model.Name = "Arena" .. index

	-- 모래 바닥 (윗면이 center.Y)
	makePart({
		Name = "Floor",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, ARENA_RADIUS * 2, ARENA_RADIUS * 2),
		CFrame = CFrame.new(center - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(210, 180, 125),
		Material = Enum.Material.Sand,
		Parent = model,
	})
	makePart({
		Name = "Emblem",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 26, 26),
		CFrame = CFrame.new(center + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(150, 60, 45),
		Material = Enum.Material.Slate,
		CanCollide = false,
		Parent = model,
	})

	-- 벽과 관중석
	local segments = 36
	local segWidth = 2 * ARENA_RADIUS * math.sin(math.pi / segments) + 1
	for i = 1, segments do
		local a = (i / segments) * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local wallPos = center + dir * ARENA_RADIUS + Vector3.new(0, 6, 0)
		makePart({
			Name = "Wall",
			Size = Vector3.new(segWidth, 12, 2),
			CFrame = CFrame.lookAt(wallPos, Vector3.new(center.X, wallPos.Y, center.Z)),
			Color = Color3.fromRGB(120, 105, 90),
			Material = Enum.Material.Cobblestone,
			Parent = model,
		})
		for tier = 1, 3 do
			local r = ARENA_RADIUS + 2 + tier * 5
			local h = 12 + tier * 4
			local stepPos = center + dir * r + Vector3.new(0, h / 2, 0)
			makePart({
				Name = "Stand",
				Size = Vector3.new(2 * r * math.sin(math.pi / segments) + 1, h, 5),
				CFrame = CFrame.lookAt(stepPos, Vector3.new(center.X, stepPos.Y, center.Z)),
				Color = Color3.fromRGB(150, 135, 115),
				Material = Enum.Material.Concrete,
				Parent = model,
			})
			if (i + tier) % 2 == 0 then
				local seatPos = center + dir * r + Vector3.new(0, h + 1.2, 0)
				makePart({
					Name = "Crowd",
					Size = Vector3.new(1.6, 2.4, 1.2),
					CFrame = CFrame.lookAt(seatPos, Vector3.new(center.X, seatPos.Y, center.Z)),
					Color = CROWD_COLORS[(i * tier) % #CROWD_COLORS + 1],
					CanCollide = false,
					Parent = model,
				})
			end
		end
	end

	model.Parent = workspace
	return { center = center, model = model }
end

local function claimSlot(player: Player): number
	local i = 1
	while slotOwner[i] do
		i += 1
	end
	slotOwner[i] = player
	if not arenas[i] then
		arenas[i] = buildArena(i)
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
	nextSlam: number,
	nextMove: number,
	fill: Frame,
	walkTrack: AnimationTrack?,
	walking: boolean,
}

type Session = {
	stage: number,
	info: any,
	arena: Arena,
	folder: Folder,
	enemies: { Enemy },
	stats: any,
	hp: number,
	maxHp: number,
	invulnUntil: number,
	lastAttack: number,
	running: boolean,
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
		auto = st.auto,
	})
end

------------------------------------------------------------------------
-- 칭호와 무기 모양
------------------------------------------------------------------------
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 230, 110)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 200, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(150, 100, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 200)),
})

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
	local bb = head:FindFirstChild("RankTitle")
	if not bb then
		local gui = Instance.new("BillboardGui")
		gui.Name = "RankTitle"
		gui.Size = UDim2.new(0, 280, 0, 34)
		gui.StudsOffset = Vector3.new(0, 2.4, 0)
		gui.MaxDistance = 150
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextStrokeTransparency = 0.25
		label.Parent = gui
		gui.Parent = head
		bb = gui
	end
	local label = (bb :: Instance):FindFirstChild("Label") :: TextLabel
	local oldGradient = label:FindFirstChildOfClass("UIGradient")
	if oldGradient then
		oldGradient:Destroy()
	end
	if p.maxStage <= 0 then
		label.Text = "NO RANK"
		label.TextColor3 = Color3.fromRGB(170, 170, 170)
		return
	end
	local section = Config.getSection(p.maxStage)
	label.Text = string.format("[%d] %s", p.maxStage, rankName)
	if section.rainbow then
		label.TextColor3 = Color3.new(1, 1, 1)
		local g = Instance.new("UIGradient")
		g.Color = RAINBOW
		g.Parent = label
	else
		label.TextColor3 = section.color
	end
end

local HANDLE_COLOR = Color3.fromRGB(70, 50, 35)
local GUARD_COLOR = Color3.fromRGB(200, 170, 90)

local function weaponPart(parent: Instance, hand: BasePart, grip: CFrame, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.CFrame = grip * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = part
	weld.Parent = part
	part.Parent = parent
	return part
end

-- 칼 한 자루를 손에 붙인다. 칼날은 손에서 앞쪽으로 뻗는다
local function buildBlade(parent: Instance, hand: BasePart, typeId: number, bladeColor: Color3, neon: boolean, scale: number)
	local grip = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2, 0) * CFrame.Angles(math.rad(-90), 0, 0)
	local mat = neon and Enum.Material.Neon or Enum.Material.Metal
	local function add(size: Vector3, y: number, x: number?, color: Color3, material: Enum.Material)
		return weaponPart(parent, hand, grip, size * scale, CFrame.new((x or 0) * scale, y * scale, 0), color, material)
	end
	if typeId == 5 then
		-- 낫: 긴 자루 끝에 옆으로 뻗은 날
		add(Vector3.new(0.3, 6, 0.3), 2.5, 0, HANDLE_COLOR, Enum.Material.Wood)
		add(Vector3.new(3.2, 0.5, 0.15), 5.4, 1.5, bladeColor, mat)
		add(Vector3.new(0.5, 1.2, 0.15), 4.9, 3.0, bladeColor, mat)
		return
	end
	local handleLen, guardW, bladeW, bladeLen, bladeT
	if typeId == 1 then
		handleLen, guardW, bladeW, bladeLen, bladeT = 1.6, 2.0, 1.1, 5.5, 0.25
	elseif typeId == 2 then
		handleLen, guardW, bladeW, bladeLen, bladeT = 1.0, 1.0, 0.45, 3.0, 0.15
	elseif typeId == 3 then
		handleLen, guardW, bladeW, bladeLen, bladeT = 1.4, 1.4, 0.5, 6.5, 0.18
	elseif typeId == 4 then
		handleLen, guardW, bladeW, bladeLen, bladeT = 0.9, 0.8, 0.4, 1.8, 0.15
	else -- 올라운더
		handleLen, guardW, bladeW, bladeLen, bladeT = 1.6, 2.4, 1.2, 6.5, 0.3
	end
	add(Vector3.new(0.32, handleLen, 0.32), 0, 0, HANDLE_COLOR, Enum.Material.Wood)
	add(Vector3.new(guardW, 0.25, 0.45), handleLen / 2, 0, GUARD_COLOR, Enum.Material.Metal)
	local blade = add(Vector3.new(bladeW, bladeLen, bladeT), handleLen / 2 + 0.12 + bladeLen / 2, 0, bladeColor, mat)
	if typeId == 0 then
		local sparkle = Instance.new("Sparkles")
		sparkle.SparkleColor = Color3.fromRGB(255, 240, 180)
		sparkle.Parent = blade
	end
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
	local _, sectionIndex = Config.getSection(info.grade)
	local neon = sectionIndex >= 3 or info.typeId == 0
	local color = info.typeId == 0 and Color3.fromRGB(255, 235, 160) or info.rarity.color
	local scale = 1 + (sectionIndex - 1) * 0.05
	local folder = Instance.new("Model")
	folder.Name = "ArenaWeapon"
	folder.Parent = char
	buildBlade(folder, right, info.typeId, color, neon, scale)
	if info.typeId == 2 and left and left:IsA("BasePart") then
		buildBlade(folder, left, 2, color, neon, scale)
	end
end

------------------------------------------------------------------------
-- 적
------------------------------------------------------------------------
local rigTemplate: Model? = nil

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
	if rigTemplate then
		return rigTemplate
	end
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
	return model
end

local function makeHpBar(root: BasePart, labelText: string, color: Color3, height: number): Frame
	local gui = Instance.new("BillboardGui")
	gui.Name = "HpBar"
	gui.Size = UDim2.new(0, 150, 0, 34)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0.55, 0)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.TextColor3 = color
	name.TextStrokeTransparency = 0.3
	name.Text = labelText
	name.Parent = gui
	local back = Instance.new("Frame")
	back.Size = UDim2.new(1, 0, 0.35, 0)
	back.Position = UDim2.new(0, 0, 0.62, 0)
	back.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
	back.BorderSizePixel = 0
	back.Parent = gui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(230, 70, 60)
	fill.BorderSizePixel = 0
	fill.Parent = back
	gui.Parent = root
	return fill
end

local function spawnEnemy(s: Session, grade: number, isBoss: boolean, pos: Vector3, hp: number, dmg: number)
	local model = getRigTemplate():Clone()
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not hum or not root or not root:IsA("BasePart") then
		model:Destroy()
		return
	end
	local section, sectionIndex = Config.getSection(grade)
	local bodyColor = section.color
	if isBoss then
		bodyColor = section.color:Lerp(Color3.fromRGB(120, 0, 0), 0.35)
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Color = bodyColor
			d.Material = (isBoss or sectionIndex >= 4) and Enum.Material.Neon or Enum.Material.SmoothPlastic
		end
	end
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = isBoss and 11 or 13
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

	local scale = section.scale * (isBoss and 1.8 or 1)
	pcall(function()
		model:ScaleTo(scale)
	end)
	model.Name = (isBoss and "BOSS " or "") .. Config.getGrade(grade).en
	model:SetAttribute("Enemy", true)
	model:PivotTo(CFrame.lookAt(pos + Vector3.new(0, 4 * scale, 0), s.arena.center + Vector3.new(0, 4 * scale, 0)))
	model.Parent = s.folder
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	-- 로블록스 기본 R15 걷기 동작. 블록 인형이면 조용히 건너뛴다
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

	local label = string.format("%s[%d] %s", isBoss and "BOSS " or "", grade, Config.getGrade(grade).en)
	local fill = makeHpBar(root, label, isBoss and Color3.fromRGB(255, 90, 80) or section.color, 3.2 * scale)
	local now = os.clock()
	table.insert(s.enemies, {
		model = model,
		hum = hum,
		root = root,
		hp = hp,
		maxHp = hp,
		dmg = dmg,
		slamDmg = s.info.slamDmg,
		isBoss = isBoss,
		alive = true,
		busy = false,
		reach = 4.5 * scale,
		bodyRadius = 1.2 * scale,
		scale = scale,
		nextAttack = now + 1 + math.random(),
		nextSlam = now + 4,
		nextMove = 0,
		fill = fill,
		walkTrack = walkTrack,
		walking = false,
	})
end

local function updateWalk(e: Enemy)
	local track = e.walkTrack
	if not track then
		return
	end
	local moving = e.alive and e.root.AssemblyLinearVelocity.Magnitude > 1.5
	if moving ~= e.walking then
		e.walking = moving
		if moving then
			track:Play(0.15)
		else
			track:Stop(0.15)
		end
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
-- 전투
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

local function damagePlayer(player: Player, st: State, s: Session, amount: number)
	if not s.running or os.clock() < s.invulnUntil then
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

local function killEnemy(e: Enemy)
	e.alive = false
	e.model:SetAttribute("Dead", true)
	e.hum.WalkSpeed = 0
	for _, d in ipairs(e.model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Transparency = 0.6
		end
	end
	Debris:AddItem(e.model, 0.45)
end

local function performAttack(player: Player, st: State, s: Session)
	if not s.running then
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
	local look = flat(root.CFrame.LookVector)
	if look.Magnitude > 0 then
		look = look.Unit
	end

	-- 사거리 안의 적을 가까운 순으로
	local inRange = {}
	for _, e in ipairs(s.enemies) do
		if e.alive and e.root.Parent then
			local offset = flat(e.root.Position) - origin
			local dist = offset.Magnitude - e.bodyRadius
			if dist <= wt.range then
				table.insert(inRange, { e = e, dist = dist, offset = offset })
			end
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
	for _, e in ipairs(targets) do
		local dmg = stats.atk * (0.9 + math.random() * 0.2)
		local crit = wt.critChance ~= nil and math.random() < wt.critChance
		if crit then
			dmg *= wt.critMult
		end
		e.hp -= dmg
		if wt.lifesteal then
			healed += dmg * wt.lifesteal
		end
		table.insert(hits, {
			pos = e.root.Position + Vector3.new(0, 2.5 * e.scale, 0),
			text = Config.formatNumber(dmg),
			kind = crit and "crit" or "hit",
		})
		if e.hp <= 0 then
			killEnemy(e)
		else
			e.fill.Size = UDim2.fromScale(math.clamp(e.hp / e.maxHp, 0, 1), 1)
		end
	end
	if healed > 0 then
		s.hp = math.min(s.maxHp, s.hp + healed)
	end
	Push:FireClient(player, "swing", {
		mode = wt.mode,
		range = wt.range,
		color = stats.weapon.typeId == 0 and Color3.fromRGB(255, 235, 160) or stats.weapon.rarity.color,
	})
	Push:FireClient(player, "hits", hits)
	pushBattle(player)
end

local function enemyStrike(player: Player, st: State, s: Session, e: Enemy)
	local now = os.clock()
	e.busy = true
	e.nextAttack = now + (e.isBoss and 1.4 or 1.6)
	e.hum:MoveTo(e.root.Position)
	flashEnemy(e, Color3.fromRGB(255, 60, 60), 0.35)
	task.delay(0.35, function()
		e.busy = false
		if not (s.running and st.session == s and e.alive) then
			return
		end
		local root = getRoot(player)
		if root and (flat(e.root.Position) - flat(root.Position)).Magnitude <= e.reach + 2 then
			damagePlayer(player, st, s, e.dmg)
		end
	end)
end

local function bossSlam(player: Player, st: State, s: Session, e: Enemy, targetPos: Vector3)
	local now = os.clock()
	e.busy = true
	e.nextSlam = now + 6
	e.hum:MoveTo(e.root.Position)
	flashEnemy(e, Color3.fromRGB(255, 140, 0), 1.3)
	local radius = 12
	local floorY = s.arena.center.Y
	local disc = makePart({
		Name = "SlamWarning",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, radius * 2, radius * 2),
		CFrame = CFrame.new(targetPos.X, floorY + 0.2, targetPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 40, 40),
		Material = Enum.Material.Neon,
		Transparency = 0.55,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = s.folder,
	})
	task.delay(1.3, function()
		disc:Destroy()
		e.busy = false
		e.nextAttack = os.clock() + 0.8
		if not (s.running and st.session == s and e.alive) then
			return
		end
		local root = getRoot(player)
		if root then
			local d = (flat(root.Position) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
			if d <= radius then
				damagePlayer(player, st, s, e.slamDmg)
			end
		end
	end)
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

local function battleLoop(player: Player, st: State, s: Session)
	while s.running and st.session == s do
		local root = getRoot(player)
		if not root or root.Position.Y < s.arena.center.Y - 40 then
			loseBattle(player, st, s)
			return
		end
		local now = os.clock()
		local alive = 0
		for _, e in ipairs(s.enemies) do
			if e.alive then
				if not e.root.Parent then
					e.alive = false
				else
					alive += 1
					updateWalk(e)
					if not e.busy then
						local dist = (flat(e.root.Position) - flat(root.Position)).Magnitude
						if e.isBoss and now >= e.nextSlam and dist < 45 then
							bossSlam(player, st, s, e, root.Position)
						elseif dist <= e.reach and now >= e.nextAttack then
							enemyStrike(player, st, s, e)
						elseif now >= e.nextMove then
							e.nextMove = now + 0.25
							e.hum:MoveTo(root.Position)
						end
					end
				end
			end
		end
		if alive == 0 then
			winBattle(player, st, s)
			return
		end
		if st.auto then
			performAttack(player, st, s)
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
	local folder = Instance.new("Folder")
	folder.Name = "P_" .. player.UserId
	folder.Parent = battleRoot

	local s: Session = {
		stage = n,
		info = info,
		arena = arena,
		folder = folder,
		enemies = {},
		stats = stats,
		hp = stats.maxHp,
		maxHp = stats.maxHp,
		invulnUntil = 0,
		lastAttack = 0,
		running = true,
	}
	st.session = s
	char:PivotTo(CFrame.new(arena.center + Vector3.new(0, 4, 0)))

	local count = info.enemyCount
	local spin = math.random() * math.pi * 2
	for i = 1, count do
		local a = spin + (i / count) * math.pi * 2
		local pos = arena.center + Vector3.new(math.cos(a), 0, math.sin(a)) * ENEMY_SPAWN_RADIUS
		spawnEnemy(s, n, false, pos, info.enemyHp, info.enemyDmg)
	end
	if info.isBoss then
		spawnEnemy(s, n, true, arena.center + Vector3.new(0, 0, -ENEMY_SPAWN_RADIUS), info.bossHp, info.bossDmg)
	end

	pushBattle(player)
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
	refreshStats(player)
end

local function mergeAll(player: Player)
	local p = profiles[player]
	local count = 0
	for g = 1, Config.MAX_GRADE - 1 do
		for t = 1, 5 do
			local key = Config.itemKey(g, t)
			while mergeOnce(p, key) do
				count += 1
			end
		end
	end
	if count == 0 then
		toast(player, "지금 합성할 수 있는 칼이 없어요")
		return
	end
	Push:FireClient(player, "merged", { count = count })
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
	elseif action == "dash" then
		local s = st.session
		if s and s.running and now - st.lastDash >= Config.DASH_COOLDOWN - 0.15 then
			st.lastDash = now
			s.invulnUntil = now + Config.DASH_INVULN
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
end

buildLobby()
task.spawn(getRigTemplate)

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
