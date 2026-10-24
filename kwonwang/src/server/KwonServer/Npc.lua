-- 권왕: 무기를 든 적과 보스 (서버가 움직인다)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Combat = require(script.Parent:WaitForChild("Combat"))

local Npc = {}

type Enemy = {
	f: any,
	def: any,
	kind: string, -- "enemy" / "boss"
	typeId: string,
	home: Vector3,
	target: any?,
	nextAttack: number,
	guardUntil: number,
	strafe: number,
	phase2: boolean,
	seq: number,
	region: string,
	engaged: { [Player]: boolean },
	level: number,
	attackingUntil: number,
	nextPattern: number?,
}

Npc.list = {} :: { Enemy }
local folder: Folder
local Push: RemoteEvent
local SKIN = Color3.fromRGB(234, 184, 146)
-- 적의 살빛 (여러 가지)
local SKIN_TONES = { Color3.fromRGB(226, 172, 132), Color3.fromRGB(205, 150, 110), Color3.fromRGB(184, 128, 92), Color3.fromRGB(160, 110, 78), Color3.fromRGB(236, 190, 155) }

function Npc.init(push: RemoteEvent)
	Push = push
	folder = Instance.new("Folder")
	folder.Name = "Enemies"
	folder.Parent = workspace
end

------------------------------------------------------------------------
-- 몸과 무기
------------------------------------------------------------------------
local function weaponPart(name: string, size: Vector3, color: Color3, material: Enum.Material, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Parent = parent
	return p
end

-- 손에 무기를 붙인다. 날은 손의 앞(-Z)으로 뻗는다
local function attachWeapon(model: Model, kind: string)
	local w = Config.Weapons[kind]
	if not w then
		return
	end
	local function onHand(handName: string)
		local hand = model:FindFirstChild(handName)
		if not hand or not hand:IsA("BasePart") then
			return
		end
		local L = w.length
		local wf = Instance.new("Model")
		wf.Name = "Weapon"
		wf.Parent = model
		local grip = weaponPart("Grip", Vector3.new(0.35, 0.35, kind == "spear" and L or 1.1), w.handle, Enum.Material.Wood, wf)
		local blade: Part
		if kind == "spear" then
			blade = weaponPart("Blade", Vector3.new(0.25, 0.6, 1.4), w.color, Enum.Material.Metal, wf)
		elseif kind == "club" then
			blade = weaponPart("Blade", Vector3.new(0.75, 0.75, L), w.color, Enum.Material.Wood, wf)
		elseif kind == "staff" then
			blade = weaponPart("Blade", Vector3.new(0.4, 0.4, L), w.color, Enum.Material.Wood, wf)
		else
			blade = weaponPart("Blade", Vector3.new(0.12, kind == "greatsword" and 0.9 or 0.45, L), w.color, Enum.Material.Metal, wf)
		end
		local guard = weaponPart("Guard", Vector3.new(0.3, 0.9, 0.2), Color3.fromRGB(160, 130, 60), Enum.Material.Metal, wf)
		local base = hand.CFrame * CFrame.new(0, -0.25, 0)
		if kind == "spear" then
			grip.CFrame = base
			blade.CFrame = base * CFrame.new(0, 0, -L / 2 - 0.6)
			guard.CFrame = base * CFrame.new(0, 0, -L / 2 + 0.1)
		else
			grip.CFrame = base * CFrame.new(0, 0, 0.3)
			guard.CFrame = base * CFrame.new(0, 0, -0.3)
			blade.CFrame = base * CFrame.new(0, 0, -0.3 - L / 2)
		end
		for _, p in ipairs({ grip, blade, guard }) do
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hand
			weld.Part1 = p
			weld.Parent = p
		end
	end
	onHand("RightHand")
	if kind == "dual" then
		onHand("LeftHand")
	end
end

-- 몸을 직접 짠다 (R15 관절 이름 그대로). 로블록스 기본 몸 만들기가 안 될 때 쓴다
-- 관절 자리 J를 기준으로 C0·C1을 맞춘다. 발바닥이 HumanoidRootPart 중심에서 3칸 아래
local RIG: { { any } } = {
	-- 이름, 크기, 중심, 부모, 관절 이름, 관절 자리
	{ "LowerTorso", Vector3.new(2, 0.4, 1), Vector3.new(0, -0.8, 0), "HumanoidRootPart", "Root", Vector3.new(0, -0.8, 0) },
	{ "UpperTorso", Vector3.new(2, 1.6, 1), Vector3.new(0, 0.2, 0), "LowerTorso", "Waist", Vector3.new(0, -0.6, 0) },
	{ "Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 1.6, 0), "UpperTorso", "Neck", Vector3.new(0, 1.0, 0) },
	{ "RightUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(1.5, 0.4, 0), "UpperTorso", "RightShoulder", Vector3.new(1.5, 0.8, 0) },
	{ "RightLowerArm", Vector3.new(1, 0.95, 1), Vector3.new(1.5, -0.675, 0), "RightUpperArm", "RightElbow", Vector3.new(1.5, -0.2, 0) },
	{ "RightHand", Vector3.new(1, 0.3, 1), Vector3.new(1.5, -1.3, 0), "RightLowerArm", "RightWrist", Vector3.new(1.5, -1.15, 0) },
	{ "LeftUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(-1.5, 0.4, 0), "UpperTorso", "LeftShoulder", Vector3.new(-1.5, 0.8, 0) },
	{ "LeftLowerArm", Vector3.new(1, 0.95, 1), Vector3.new(-1.5, -0.675, 0), "LeftUpperArm", "LeftElbow", Vector3.new(-1.5, -0.2, 0) },
	{ "LeftHand", Vector3.new(1, 0.3, 1), Vector3.new(-1.5, -1.3, 0), "LeftLowerArm", "LeftWrist", Vector3.new(-1.5, -1.15, 0) },
	{ "RightUpperLeg", Vector3.new(1, 1.1, 1), Vector3.new(0.5, -1.55, 0), "LowerTorso", "RightHip", Vector3.new(0.5, -1.0, 0) },
	{ "RightLowerLeg", Vector3.new(1, 0.7, 1), Vector3.new(0.5, -2.45, 0), "RightUpperLeg", "RightKnee", Vector3.new(0.5, -2.1, 0) },
	{ "RightFoot", Vector3.new(1, 0.2, 1.1), Vector3.new(0.5, -2.9, -0.05), "RightLowerLeg", "RightAnkle", Vector3.new(0.5, -2.8, 0) },
	{ "LeftUpperLeg", Vector3.new(1, 1.1, 1), Vector3.new(-0.5, -1.55, 0), "LowerTorso", "LeftHip", Vector3.new(-0.5, -1.0, 0) },
	{ "LeftLowerLeg", Vector3.new(1, 0.7, 1), Vector3.new(-0.5, -2.45, 0), "LeftUpperLeg", "LeftKnee", Vector3.new(-0.5, -2.1, 0) },
	{ "LeftFoot", Vector3.new(1, 0.2, 1.1), Vector3.new(-0.5, -2.9, -0.05), "LeftLowerLeg", "LeftAnkle", Vector3.new(-0.5, -2.8, 0) },
}

local function manualRig(colors: { head: Color3, torso: Color3, arms: Color3, legs: Color3 }, s: number): Model
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1) * s
	root.Transparency = 1
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root
	local parts: { [string]: BasePart } = { HumanoidRootPart = root }
	for _, r in ipairs(RIG) do
		local name, size, center, parentName, jointName, joint = r[1], r[2], r[3], r[4], r[5], r[6]
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * s
		p.CFrame = CFrame.new(center * s)
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanCollide = name == "UpperTorso" or name == "LowerTorso" or name == "Head"
		p.Material = Enum.Material.SmoothPlastic
		if name == "Head" then
			p.Color = colors.head
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
			mesh.Parent = p
			local face = Instance.new("Decal")
			face.Name = "face"
			face.Texture = "rbxasset://textures/face.png"
			face.Face = Enum.NormalId.Front
			face.Parent = p
		elseif string.find(name, "Torso") then
			p.Color = colors.torso
		elseif string.find(name, "Arm") or string.find(name, "Hand") then
			p.Color = colors.arms
		else
			p.Color = colors.legs
		end
		p.Parent = model
		parts[name] = p
		local parent = parts[parentName]
		local m = Instance.new("Motor6D")
		m.Name = jointName
		m.Part0 = parent
		m.Part1 = p
		local j = joint * s
		m.C0 = CFrame.new(j - parent.Position)
		m.C1 = CFrame.new(j - center * s)
		m.Parent = p
	end
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = 2 * s
	hum.AutomaticScalingEnabled = false
	hum.Parent = model
	return model
end

-- 사람 몸 하나 (로블록스 기본 몸, 안 되면 직접 짠 몸)
-- build = { h = 키, w = 품, head = 머리 } 배율 (적마다 체격이 다르다. 머리를 조금 작게 해 어른 몸으로)
local function body(colors: { head: Color3, torso: Color3, arms: Color3, legs: Color3 }, s: number, build: any?): Model
	local bd = build or {}
	local ok, model = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = colors.head
		desc.LeftArmColor = colors.arms
		desc.RightArmColor = colors.arms
		desc.TorsoColor = colors.torso
		desc.LeftLegColor = colors.legs
		desc.RightLegColor = colors.legs
		desc.HeightScale = s * (bd.h or 1)
		desc.WidthScale = s * (bd.w or 1)
		desc.DepthScale = s * (bd.w or 1)
		desc.HeadScale = s * (bd.head or 1)
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if ok and typeof(model) == "Instance" and model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("LowerTorso") then
		-- 기본 걷기 스크립트는 쓰지 않는다 (몸동작은 화면이 그린다)
		local animate = model:FindFirstChild("Animate")
		if animate then
			animate:Destroy()
		end
		return model
	end
	if not ok then
		warn("[권왕] 기본 몸 만들기 실패, 직접 짠 몸을 씁니다:", model)
	end
	return manualRig(colors, s)
end
Npc.body = body

local dressEnemy: (Model, string, any, boolean) -> ()
local lookOf: (string, boolean) -> any

local function buildRig(def: any, label: string, isBoss: boolean, typeId: string?): Model
	local s = def.scale or 1
	local look = lookOf(typeId or "", isBoss)
	local skin = look.skin or SKIN_TONES[math.random(#SKIN_TONES)]
	local model = body({ head = skin, torso = def.shirt, arms = look.bareArms == false and def.shirt or skin, legs = def.pants }, s, look.build or { head = 0.9 })
	model.Name = label
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.BreakJointsOnDeath = false
		hum.MaxHealth = 1e9
		hum.Health = 1e9
		hum.WalkSpeed = def.speed
	end
	-- 적마다 다른 차림 (머리쓰개, 얼굴, 옷). 실패해도 몸은 그대로 쓴다
	if not def.dummy then
		local ok, err = pcall(dressEnemy, model, typeId or "", def, isBoss)
		if not ok then
			warn("[권왕] 적 차림 오류:", typeId, err)
		end
	end
	attachWeapon(model, def.weapon)
	model:SetAttribute("NPC", true)
	model:SetAttribute("Boss", isBoss)
	model:SetAttribute("Label", label)
	model:SetAttribute("Scale", def.scale or 1)
	model:SetAttribute("Weapon", def.weapon)
	if def.dummy then
		model:SetAttribute("Dummy", true)
	end
	return model
end

------------------------------------------------------------------------
-- 나타나기
------------------------------------------------------------------------
function Npc.spawn(typeId: string, isBoss: boolean, at: Vector3, region: string): Enemy?
	local def = isBoss and Config.Bosses[typeId] or Config.Enemies[typeId]
	if not def then
		return nil
	end
	local model = buildRig(def, def.name, isBoss, typeId)
	local pos = at + Vector3.new(math.random(-8, 8), 4 * (def.scale or 1), math.random(-8, 8))
	model:PivotTo(CFrame.new(pos))
	model.Parent = folder
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
	-- 마을에서 멀수록 단계가 높다: 체력·균형·피해·보상이 함께 오른다
	local lv = Config.enemyLevel(at)
	model:SetAttribute("Level", lv)
	-- mult: 허공 균열 같은 후반 땅의 적은 체력·피해가 겹으로 세다
	local mult = def.mult or 1
	local f = Combat.register(model, {
		npc = def,
		name = def.name,
		-- 체력은 넉넉하게 (보스는 조금 덜 곱한다: 이미 크다), 피해는 후반일수록 덜 오른다
		hp = def.dummy and def.hp or math.floor(def.hp * (isBoss and Config.ENEMY_BOSS_HP or Config.ENEMY_HP) * (1 + Config.ENEMY_HP_LEVEL * (lv - 1)) * mult),
		postureMax = math.floor(def.posture * (1 + 0.1 * (lv - 1)) * math.sqrt(mult)),
		walk = def.speed * (isBoss and Config.BOSS_SPEED or 1),
		style = def.style or "",
		dmgMult = Config.ENEMY_DMG * (1 + Config.ENEMY_DMG_LEVEL * (lv - 1)) * mult ^ Config.ENEMY_DMG_MULT_POW * (isBoss and (def.late and Config.LATE_BOSS_DMG or Config.BOSS_DMG) or 1),
	})
	;(f :: any).rewardMult = (1 + 0.25 * (lv - 1)) * math.sqrt(mult)
	-- 초반 적은 흘리기 판정이 좁다 (막아도 잘 흘리지 못한다)
	if not isBoss and not def.elite and not def.duel and lv <= 4 then
		(f :: any).deflectMul = 0.45
	end
	;(f :: any).typeId = typeId
	model:SetAttribute("TypeId", typeId)
	local cp = Config.enemyPower(f.dmgMult, f.maxHp, isBoss)
	;(f :: any).power = cp
	model:SetAttribute("Power", cp)
	local e: Enemy = {
		f = f,
		def = def,
		kind = isBoss and "boss" or "enemy",
		typeId = typeId,
		home = at,
		target = nil,
		nextAttack = os.clock() + 1,
		guardUntil = 0,
		strafe = math.random() < 0.5 and 1 or -1,
		phase2 = false,
		seq = 0,
		region = region,
		engaged = {},
		level = lv,
		attackingUntil = 0,
	}
	table.insert(Npc.list, e)
	return e
end

-- 지역마다 적과 보스를 놓는다
function Npc.populate()
	for _, region in ipairs(Config.Regions) do
		for _, camp in ipairs(region.camps or {}) do
			for _ = 1, camp.count do
				local ok, err = pcall(Npc.spawn, camp.enemy, false, camp.at, region.id)
				if not ok then
					warn("[권왕] 적 만들기 오류:", camp.enemy, err)
				end
			end
		end
		if region.boss then
			local ok, err = pcall(Npc.spawn, region.boss.id, true, region.boss.at, region.id)
			if not ok then
				warn("[권왕] 보스 만들기 오류:", region.boss.id, err)
			end
		end
	end
	-- 천상계의 섬들
	for _, isl in ipairs(Config.SKY.islands) do
		for _, camp in ipairs(isl.camps or {}) do
			for _ = 1, camp.count do
				local ok, err = pcall(Npc.spawn, camp.enemy, false, camp.at, "sky")
				if not ok then
					warn("[권왕] 천상계 적 만들기 오류:", camp.enemy, err)
				end
			end
		end
		if isl.boss then
			local ok, err = pcall(Npc.spawn, isl.boss.id, true, isl.boss.at, "sky")
			if not ok then
				warn("[권왕] 천상계 보스 만들기 오류:", isl.boss.id, err)
			end
		end
	end
	pcall(Npc.publishPower)
end

-- 1.5판: 지역마다 권장 전투력 (그 땅 적들의 가운데 전투력보다 조금 높게). 보스는 따로. 화면의 지도와 지역 알림이 쓴다
function Npc.publishPower()
	local groups: { [string]: { number } } = {}
	local bosses: { [string]: number } = {}
	for _, e in ipairs(Npc.list) do
		local key = e.region
		if key == "sky" then
			local isl = Config.skyIslandAt(e.f.root.Position)
			key = isl and ("sky_" .. isl.id) or "sky"
		end
		if key ~= "trial" and key ~= "test" and key ~= "summon" and key ~= "simma" and key ~= "wilds" then
			local pw = (e.f :: any).power or 0
			if e.kind == "boss" then
				bosses[key] = math.max(bosses[key] or 0, pw)
			else
				groups[key] = groups[key] or {}
				table.insert(groups[key], pw)
			end
		end
	end
	local folder = ReplicatedStorage:FindFirstChild("KwonRegionPower") or Instance.new("Folder")
	folder.Name = "KwonRegionPower"
	for key, list in pairs(groups) do
		table.sort(list)
		local mid = list[math.max(1, math.ceil(#list / 2))]
		folder:SetAttribute(key, math.floor(mid * 1.15))
	end
	for key, pw in pairs(bosses) do
		folder:SetAttribute(key .. "_boss", math.floor(pw))
	end
	folder.Parent = ReplicatedStorage
end

------------------------------------------------------------------------
-- 일곱 사부 (싸우지 않는다. 가까이 가서 T를 누르면 권법을 배운다)
------------------------------------------------------------------------
local function masterTag(head: BasePart, name: string, style: any)
	local g = Instance.new("BillboardGui")
	g.Name = "MasterTag"
	g.Size = UDim2.new(0, 320, 0, 74)
	g.StudsOffset = Vector3.new(0, 3.2, 0)
	g.AlwaysOnTop = true
	g.LightInfluence = 0
	g.MaxDistance = 160
	-- 장로는 이름 한 줄만 (말 걸기는 가까이 가면 뜨는 T 안내로)
	local lines = style.elder and { { name, Color3.fromRGB(255, 225, 150), 0.52 } } or { { "사부 · " .. name, Color3.fromRGB(255, 225, 150), 0.52 }, { style.icon .. " " .. style.name .. "  (T)", style.color, 0.48 } }
	for i, line in ipairs(lines) do
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0, i == 1 and 0 or 0.52)
		l.Size = UDim2.fromScale(1, line[3])
		l.Font = Enum.Font.GothamBlack
		l.TextScaled = true
		l.TextColor3 = line[2]
		l.TextStrokeTransparency = 0.2
		l.Text = line[1]
		l.Parent = g
	end
	g.Parent = head
end

-- 사부 차림: 몸 부위에 붙는 장식 (기본 몸이든 직접 짠 몸이든 부위 이름은 같다)
local function wear(model: Model, partName: string, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part?
	local base = model:FindFirstChild(partName)
	if not base or not base:IsA("BasePart") then
		return nil
	end
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Fabric
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = base.CFrame * offset
	p.Parent = model
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
	return p
end

local GOLD = Color3.fromRGB(235, 190, 80)
local WHITE_HAIR = Color3.fromRGB(240, 240, 235)

------------------------------------------------------------------------
-- 적의 차림: 머리쓰개 (삿갓·두건·투구·복면·뿔·관), 매서운 얼굴, 체격, 옷
-- 머리에 붙이는 것은 모두 머리 크기에 맞춘 둥근 모양 (머리를 뚫고 나오지 않게)
------------------------------------------------------------------------
local DARK_HAIR = Color3.fromRGB(30, 24, 20)
local STRAW = Color3.fromRGB(200, 170, 110)
local IRON = Color3.fromRGB(110, 112, 120)
local C3 = Color3.fromRGB
local LOOKS: { [string]: any } = {
	thug = { head = "bald", beard = "stubble", build = { w = 1.1, head = 0.9 } },
	bandit = { head = "bandana", cloth = C3(140, 40, 35), beard = "full", build = { head = 0.9 } },
	spearman = { head = "straw", build = { h = 1.04, head = 0.88 }, belt = true },
	brute = { head = "bald", beard = "full", build = { w = 1.38, h = 1.08, head = 0.85 }, scar = true },
	assassin = { head = "hood", cloth = C3(40, 40, 50), mask = C3(30, 30, 36), build = { w = 0.88, h = 1.05, head = 0.86 } },
	shadowblade = { head = "hood", cloth = C3(35, 25, 50), mask = C3(25, 20, 35), eyes = C3(190, 120, 255), build = { w = 0.9, h = 1.06, head = 0.86 } },
	ironguard = { head = "helmet", metal = IRON, armor = true, build = { w = 1.18, h = 1.05, head = 0.88 } },
	simma = { head = "horns", skin = C3(70, 40, 90), eyes = C3(220, 90, 255), robe = C3(35, 10, 45), build = { h = 1.08, head = 0.88 } },
	gatekeeper = { head = "helmet", metal = GOLD, armor = true, eyes = C3(255, 220, 120), robe = C3(60, 40, 20), build = { w = 1.2, h = 1.1, head = 0.86 } },
	iceguard = { head = "helmet", metal = C3(170, 210, 235), armor = true, build = { w = 1.18, h = 1.05, head = 0.88 } },
	snowblade = { head = "hood", cloth = C3(225, 232, 240), mask = C3(200, 210, 222), build = { w = 0.88, h = 1.05, head = 0.86 } },
	swampfang = { form = "naga", skin = C3(60, 110, 60), eyes = C3(240, 220, 60), build = { w = 0.9, h = 1.05, head = 0.86 } },
	bogbrute = { form = "troll", skin = C3(110, 130, 80), build = { w = 1.4, h = 1.08, head = 0.85 } },
	marauder = { head = "bandana", cloth = C3(120, 90, 50), beard = "full", armor = true, metal = C3(120, 95, 70), build = { w = 1.1, head = 0.9 } },
	lancer = { head = "straw", cloth = C3(150, 120, 80), mask = C3(150, 120, 90), build = { h = 1.05, head = 0.88 } },
	pirate = { head = "bandana", cloth = C3(170, 30, 30), beard = "full", eyepatch = true, build = { w = 1.05, head = 0.9 } },
	cultist = { head = "hood", cloth = C3(120, 15, 25), mask = C3(150, 20, 30), robe = C3(90, 10, 20), build = { head = 0.88 } },
	cultelder = { head = "hood", cloth = C3(70, 5, 15), beard = "white", eyes = C3(255, 70, 70), robe = C3(60, 5, 12), build = { h = 1.04, head = 0.88 } },
	riftling = { form = "imp", skin = C3(90, 60, 130), eyes = C3(220, 140, 255), hornColor = C3(20, 10, 30), fire = C3(180, 100, 255), build = { w = 0.85, h = 0.95, head = 0.9 } },
	voidwalker = { form = "wraith", cloth = C3(20, 15, 35), eyes = C3(120, 230, 255), bone = C3(40, 30, 55), dust = C3(120, 90, 200), build = { h = 1.1, w = 0.9, head = 0.86 } },
	stonegolem = { form = "golem", skin = C3(125, 120, 112), eyes = C3(255, 200, 120), build = { w = 1.45, h = 1.15, head = 0.8 } },
	apostle = { head = "hood", cloth = C3(15, 8, 30), eyes = C3(200, 100, 255), robe = C3(10, 5, 20), crown = C3(140, 90, 220), build = { h = 1.08, head = 0.86 } },
	flameimp = { form = "imp", skin = C3(190, 70, 50), eyes = C3(255, 230, 90), fire = C3(255, 140, 40), build = { w = 0.85, h = 0.95, head = 0.92 } },
	magmabrute = { form = "golem", skin = C3(60, 35, 30), eyes = C3(255, 140, 40), ember = C3(255, 120, 30), build = { w = 1.42, h = 1.1, head = 0.84 } },
	sandwraith = { form = "wraith", cloth = C3(215, 190, 140), eyes = C3(255, 230, 150), dust = C3(230, 210, 160), build = { w = 0.88, h = 1.06, head = 0.86 } },
	tombguard = { form = "skeleton", eyes = C3(255, 200, 90), build = { w = 1.15, h = 1.05, head = 0.88 } },
	skyguard = { head = "helmet", metal = C3(235, 238, 250), armor = true, plume = C3(120, 160, 230), build = { w = 1.15, h = 1.08, head = 0.88 } },
	starblade = { head = "hood", cloth = C3(30, 40, 80), mask = C3(25, 30, 60), eyes = C3(230, 240, 255), build = { w = 0.9, h = 1.06, head = 0.86 } },
	-- 천상계
	cloudguard = { head = "helmet", metal = C3(235, 240, 250), plume = C3(150, 190, 240), build = { h = 1.06, head = 0.88 } },
	cranesword = { form = "bird", feather = C3(245, 245, 245), crest = C3(220, 40, 40), beak = C3(230, 190, 90), build = { w = 0.88, h = 1.06, head = 0.86 } },
	thunderguard = { head = "helmet", metal = C3(80, 90, 150), plume = C3(150, 190, 255), armor = true, eyes = C3(150, 200, 255), build = { w = 1.18, h = 1.06, head = 0.86 } },
	thunderimp = { form = "imp", skin = C3(110, 130, 210), eyes = C3(230, 240, 255), hornColor = C3(240, 240, 200), fire = C3(170, 200, 255), build = { w = 0.85, h = 0.95, head = 0.9 } },
	starspirit = { form = "spirit", skin = C3(150, 110, 230), eyes = C3(255, 240, 200), shard = C3(255, 230, 150), build = { w = 0.9, h = 1.06, head = 0.86 } },
	starsage = { head = "hood", cloth = C3(60, 40, 120), beard = "white", eyes = C3(200, 160, 255), robe = C3(50, 30, 100), build = { h = 1.05, head = 0.86 } },
	throneguard = { head = "helmet", metal = C3(240, 210, 130), plume = C3(220, 60, 50), armor = true, build = { w = 1.2, h = 1.08, head = 0.86 } },
	throneblade = { head = "topknot", hair = C3(30, 25, 20), crown = C3(240, 210, 130), mask = C3(250, 240, 220), build = { w = 0.9, h = 1.06, head = 0.86 } },
	noeje = { head = "helmet", metal = C3(70, 80, 160), plume = C3(150, 200, 255), armor = true, beard = "full", eyes = C3(150, 210, 255), build = { w = 1.2, head = 0.84 } },
	seonggun = { head = "hood", cloth = C3(100, 60, 190), crown = C3(220, 190, 255), eyes = C3(230, 190, 255), robe = C3(60, 30, 120), build = { h = 1.06, head = 0.84 } },
	cheonjon = { head = "topknot", hair = WHITE_HAIR, beard = "white", crown = GOLD, armor = true, metal = C3(240, 215, 140), eyes = C3(255, 240, 190), robe = C3(220, 200, 150), build = { w = 1.15, h = 1.06, head = 0.84 } },
	-- 보스
	heukho = { head = "topknot", hair = DARK_HAIR, beard = "full", scar = true, armor = true, metal = C3(50, 45, 45), build = { w = 1.2, head = 0.86 } },
	hyeolrang = { form = "wolf", fur = C3(90, 20, 25), eyes = C3(255, 60, 60), build = { w = 0.92, h = 1.05, head = 0.85 } },
	bingma = { head = "helmet", metal = C3(190, 225, 250), beard = "white", eyes = C3(150, 220, 255), robe = C3(80, 110, 150), build = { w = 1.15, head = 0.85 } },
	hyeolma = { head = "topknot", hair = C3(140, 10, 20), eyes = C3(255, 50, 50), robe = C3(110, 0, 15), build = { h = 1.05, head = 0.85 } },
	cheonma = { head = "horns", hair = C3(20, 10, 30), eyes = C3(200, 90, 255), robe = C3(25, 10, 50), crown = C3(120, 60, 200), build = { h = 1.08, head = 0.84 } },
	yeomje = { head = "topknot", hair = C3(200, 60, 20), beard = "full", eyes = C3(255, 170, 50), crown = GOLD, armor = true, metal = C3(160, 70, 30), build = { w = 1.2, head = 0.85 } },
	sawang = { head = "wrap", cloth = C3(215, 175, 70), eyes = C3(255, 220, 120), crown = GOLD, robe = C3(150, 110, 40), build = { h = 1.06, head = 0.85 } },
	cheonmun = { head = "helmet", metal = C3(240, 242, 255), plume = GOLD, armor = true, eyes = C3(255, 240, 190), build = { w = 1.2, h = 1.08, head = 0.84 } },
	-- 2.3판: 사람이 아닌 적 (생김새 form)
	waterspirit = { form = "spirit", skin = C3(90, 170, 255), eyes = C3(240, 250, 255), shard = C3(200, 240, 255) },
	icespirit = { form = "spirit", skin = C3(170, 220, 255), eyes = C3(220, 250, 255), shard = C3(235, 250, 255) },
	karstsprite = { form = "spirit", skin = C3(120, 140, 110), eyes = C3(190, 255, 160), shard = C3(150, 150, 140), shardMat = Enum.Material.Slate },
	stonewarden = { form = "golem", skin = C3(115, 125, 110), eyes = C3(180, 255, 150), moss = C3(70, 120, 50) },
	meteorguard = { form = "golem", skin = C3(60, 60, 80), eyes = C3(140, 200, 255), ember = C3(150, 190, 255) },
	seokwang = { form = "golem", skin = C3(74, 70, 80), eyes = C3(255, 210, 120), ember = C3(255, 190, 80) },
	craneguard = { form = "bird", feather = C3(235, 235, 235), crest = C3(200, 30, 30), beak = C3(220, 180, 80) },
	cranemaster = { form = "bird", feather = C3(205, 232, 245), crest = C3(40, 120, 160), beak = C3(230, 200, 110) },
	phoenixguard = { form = "bird", feather = C3(255, 140, 50), crest = C3(255, 220, 80), beak = C3(255, 200, 60), fire = C3(255, 150, 50) },
	flamesage = { form = "bird", feather = C3(230, 80, 40), crest = C3(255, 200, 80), beak = C3(255, 190, 60), fire = C3(255, 120, 40) },
	seonhak = { form = "bird", feather = C3(250, 250, 250), crest = C3(40, 140, 180), beak = C3(235, 205, 110) },
	yeombong = { form = "bird", feather = C3(255, 120, 40), crest = C3(255, 230, 100), beak = C3(255, 200, 60), fire = C3(255, 160, 60) },
	shroombrute = { form = "shroom", capColor = C3(170, 40, 50), skin = C3(225, 215, 190), capSize = 3.6 },
	sporeimp = { form = "shroom", capColor = C3(120, 60, 160), skin = C3(210, 200, 220), capSize = 2.4, spore = C3(220, 180, 255) },
	gyunwang = { form = "shroom", capColor = C3(150, 30, 60), skin = C3(230, 220, 200), capSize = 4.4, spore = C3(255, 200, 220) },
}
local DEFAULT_LOOK = { head = "topknot", hair = DARK_HAIR, build = { head = 0.9 } }
lookOf = function(typeId: string, _isBoss: boolean): any
	if LOOKS[typeId] then
		return LOOKS[typeId]
	end
	-- 사부의 분신·권존 등 (trial_권법): 상투에 도포
	if string.sub(typeId, 1, 6) == "trial_" then
		return { head = "topknot", hair = DARK_HAIR, robe = C3(70, 60, 50), build = { head = 0.88 } }
	end
	return DEFAULT_LOOK
end

-- 매서운 얼굴: 기본 웃는 얼굴을 지우고, 머리 앞에 얇은 판을 붙여 짙은 눈썹·눈·입을 그린다
local function face(model: Model, head: BasePart, look: any)
	local d = head:FindFirstChild("face")
	if d and d:IsA("Decal") then
		d:Destroy()
	end
	if look.head == "golem" and not look.eyes then
		return
	end
	local hs = head.Size
	local plate = wear(model, "Head", "FacePlate", Vector3.new(hs.X * 0.8, hs.Y * 0.62, 0.05), CFrame.new(0, -hs.Y * 0.02, -hs.Z * 0.5 - 0.02), Color3.new(0, 0, 0))
	if not plate then
		return
	end
	plate.Transparency = 1
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(200, 155)
	gui.LightInfluence = look.eyes and 0 or 1
	gui.Parent = plate
	local ink = look.skin and look.skin:Lerp(Color3.new(0, 0, 0), 0.75) or Color3.fromRGB(40, 25, 20)
	local function bar(x: number, y: number, w: number, h: number, rot: number, color: Color3)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(x, y)
		f.Size = UDim2.fromScale(w, h)
		f.Rotation = rot
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.Parent = gui
	end
	-- 눈썹: 안쪽이 내려간 성난 눈썹 (두건·복면이면 눈만)
	if look.head ~= "wrap" then
		bar(0.3, 0.3, 0.3, 0.075, 14, ink)
		bar(0.7, 0.3, 0.3, 0.075, -14, ink)
	end
	local eye = look.eyes or Color3.fromRGB(25, 18, 15)
	bar(0.32, 0.43, look.eyes and 0.16 or 0.12, 0.07, 6, eye)
	bar(0.68, 0.43, look.eyes and 0.16 or 0.12, 0.07, -6, eye)
	if look.eyepatch then
		bar(0.32, 0.43, 0.22, 0.16, 0, Color3.fromRGB(15, 12, 10))
		bar(0.5, 0.3, 1.0, 0.04, -20, Color3.fromRGB(15, 12, 10))
	end
	if not look.mask and look.head ~= "wrap" and look.head ~= "golem" then
		bar(0.5, 0.74, 0.26, 0.04, 0, ink)
	end
	if look.scar then
		bar(0.7, 0.45, 0.04, 0.42, 20, Color3.fromRGB(150, 70, 60))
	end
end

------------------------------------------------------------------------
-- 2.3판: 사람이 아닌 적의 몸 (정령 · 소악귀 · 돌 거인 · 망령 · 새 무사 · 해골 · 버섯 · 늪 거한 · 뱀 · 늑대)
-- 몸의 뼈대 (걷기·공격 몸짓)는 그대로 두고, 그 위에 다른 생김새를 입힌다. 사람 얼굴과 머리쓰개는 쓰지 않는다
------------------------------------------------------------------------
local LEGS = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
local ARMS = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" }
local function partOf(model: Model, name: string): BasePart?
	local p = model:FindFirstChild(name)
	return (p and p:IsA("BasePart")) and p or nil
end
local function hideParts(model: Model, names: { string })
	for _, n in ipairs(names) do
		local p = partOf(model, n)
		if p then
			p.Transparency = 1
			for _, d in ipairs(p:GetChildren()) do
				if d:IsA("Decal") then
					d:Destroy()
				end
			end
		end
	end
end
local function paint(model: Model, names: { string }, color: Color3, material: Enum.Material?, alpha: number?)
	for _, n in ipairs(names) do
		local p = partOf(model, n)
		if p then
			p.Color = color
			p.Material = material or p.Material
			if alpha then
				p.Transparency = alpha
			end
		end
	end
end
local function emit(p: BasePart?, color: Color3, rate: number, size: number, speed: number, accel: Vector3?)
	if not p then
		return
	end
	local a = Instance.new("Attachment")
	a.Parent = p
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0.6
	e.Rate = rate
	e.Lifetime = NumberRange.new(0.5, 1.1)
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Acceleration = accel or Vector3.zero
	e.Size = NumberSequence.new(size, 0)
	e.Parent = a
end
local Ball, Cyl = Enum.PartType.Ball, Enum.PartType.Cylinder
local NEON, GLASS, SLATE, SMOOTH = Enum.Material.Neon, Enum.Material.Glass, Enum.Material.Slate, Enum.Material.SmoothPlastic

local FORMS: { [string]: (Model, any, number) -> () } = {}

-- 정령: 다리 대신 흩어지는 꼬리, 반투명한 몸, 빛나는 구슬 머리와 둘레를 도는 조각
FORMS.spirit = function(model, look, k)
	local c = look.skin or Color3.fromRGB(120, 200, 255)
	local c2 = look.eyes or Color3.new(1, 1, 1)
	hideParts(model, LEGS)
	hideParts(model, { "Head" })
	paint(model, { "UpperTorso", "LowerTorso" }, c, GLASS, 0.3)
	paint(model, ARMS, c, GLASS, 0.35)
	-- 흩어지는 꼬리 (점점 가늘게)
	for i = 0, 4 do
		local w = (1.9 - i * 0.35) * k
		local wisp = wear(model, "LowerTorso", "Wisp", Vector3.new(w, w * 0.9, w), CFrame.new(0, (-0.7 - i * 0.75) * k, i * 0.12 * k), c, GLASS, Ball)
		if wisp then
			wisp.Transparency = 0.25 + i * 0.1
		end
	end
	-- 구슬 머리, 눈, 둘레의 조각 넷
	local orb = wear(model, "Head", "Orb", Vector3.new(1.4, 1.4, 1.4) * k, CFrame.new(0, 0.1 * k, 0), c:Lerp(Color3.new(1, 1, 1), 0.3), GLASS, Ball)
	if orb then
		orb.Transparency = 0.15
	end
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.3, 0.14, 0.1) * k, CFrame.new(x * 0.26 * k, 0.15 * k, -0.66 * k), c2, NEON)
	end
	local shard = look.shard or c:Lerp(Color3.new(1, 1, 1), 0.5)
	for i = 0, 3 do
		local a = i * math.pi / 2
		wear(model, "Head", "Shard", Vector3.new(0.22, 0.8, 0.22) * k, CFrame.new(math.cos(a) * 1.1 * k, 0.6 * k, math.sin(a) * 1.1 * k) * CFrame.Angles(math.sin(a) * 0.5, 0, math.cos(a) * 0.5), shard, look.shardMat or NEON)
	end
	-- 가슴의 빛나는 심
	wear(model, "UpperTorso", "Core", Vector3.new(0.8, 0.8, 0.8) * k, CFrame.new(0, 0.1 * k, -0.2 * k), c2, NEON, Ball)
	emit(partOf(model, "LowerTorso"), c, 8, 0.4 * k, 2, Vector3.new(0, -2, 0))
end
-- 소악귀: 굽은 뿔, 뾰족한 귀, 박쥐 날개, 끝이 삽 같은 꼬리, 손톱
FORMS.imp = function(model, look, k)
	local skin = look.skin or Color3.fromRGB(190, 70, 50)
	local eye = look.eyes or Color3.fromRGB(255, 230, 90)
	local horn = look.hornColor or Color3.fromRGB(40, 25, 25)
	paint(model, { "Head", "UpperTorso", "LowerTorso" }, skin, SMOOTH)
	paint(model, ARMS, skin, SMOOTH)
	paint(model, LEGS, skin:Lerp(Color3.new(0, 0, 0), 0.25), SMOOTH)
	local head = partOf(model, "Head")
	for _, d in ipairs(head and head:GetChildren() or {}) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	local hs = head and head.Size or Vector3.new(1.2, 1.2, 1.2)
	for _, x in ipairs({ -1, 1 }) do
		-- 굽은 뿔 (세 마디)
		for j = 0, 2 do
			wear(model, "Head", "Horn", Vector3.new(0.22 - j * 0.05, 0.42, 0.22 - j * 0.05) * k, CFrame.new(x * (0.32 + j * 0.14) * hs.X, (0.55 + j * 0.28) * hs.Y, (0.05 + j * 0.12) * hs.Z) * CFrame.Angles(math.rad(-15 * j), 0, -x * math.rad(30 - j * 25)), horn, SMOOTH)
		end
		-- 뾰족한 귀
		wear(model, "Head", "Ear", Vector3.new(0.1, 0.5, 0.25) * k, CFrame.new(x * 0.62 * hs.X, 0.1 * hs.Y, 0) * CFrame.Angles(0, 0, -x * math.rad(60)), skin, SMOOTH)
		wear(model, "Head", "Eye", Vector3.new(0.26, 0.12, 0.08) * k, CFrame.new(x * 0.22 * hs.X, 0.08 * hs.Y, -0.55 * hs.Z) * CFrame.Angles(0, 0, x * math.rad(-15)), eye, NEON)
		-- 박쥐 날개 (뼈 + 막 둘)
		wear(model, "UpperTorso", "WingBone", Vector3.new(0.18, 1.8, 0.18) * k, CFrame.new(x * 1.0 * k, 0.9 * k, 0.6 * k) * CFrame.Angles(math.rad(20), 0, -x * math.rad(55)), horn, SMOOTH)
		wear(model, "UpperTorso", "Wing", Vector3.new(1.6, 1.4, 0.06) * k, CFrame.new(x * 1.35 * k, 0.45 * k, 0.65 * k) * CFrame.Angles(math.rad(15), x * math.rad(-20), -x * math.rad(20)), skin:Lerp(Color3.new(0, 0, 0), 0.45), SMOOTH)
		wear(model, "UpperTorso", "Wing", Vector3.new(1.0, 1.0, 0.06) * k, CFrame.new(x * 2.1 * k, 0.6 * k, 0.75 * k) * CFrame.Angles(math.rad(15), x * math.rad(-30), x * math.rad(10)), skin:Lerp(Color3.new(0, 0, 0), 0.5), SMOOTH)
	end
	-- 이빨 드러난 입
	wear(model, "Head", "Grin", Vector3.new(0.5, 0.08, 0.06) * k, CFrame.new(0, -0.2 * hs.Y, -0.56 * hs.Z), eye, NEON)
	-- 꼬리 (네 마디로 휘고 끝이 삽 모양)
	local prev = CFrame.new(0, -0.1 * k, 0.5 * k)
	for j = 1, 4 do
		local seg = prev * CFrame.Angles(math.rad(35), 0, 0) * CFrame.new(0, -0.35 * k, 0)
		wear(model, "LowerTorso", "Tail", Vector3.new(0.16, 0.7, 0.16) * k, seg, skin, SMOOTH)
		prev = seg * CFrame.new(0, -0.35 * k, 0)
	end
	wear(model, "LowerTorso", "TailTip", Vector3.new(0.4, 0.4, 0.08) * k, prev * CFrame.Angles(0, 0, math.rad(45)), horn, SMOOTH)
	for _, hn in ipairs({ "LeftHand", "RightHand" }) do
		for j = -1, 1 do
			wear(model, hn, "Claw", Vector3.new(0.08, 0.35, 0.08) * k, CFrame.new(j * 0.22 * k, -0.3 * k, -0.15 * k) * CFrame.Angles(math.rad(25), 0, 0), horn, SMOOTH)
		end
	end
	if look.fire then
		emit(partOf(model, "Head"), look.fire, 10, 0.5 * k, 3, Vector3.new(0, 4, 0))
	end
end
-- 돌 거인: 몸을 바위로, 어깨와 주먹에 큰 바윗덩이, 머리는 어깨에 파묻힌 돌, 빛나는 금
FORMS.golem = function(model, look, k)
	local rock = look.skin or Color3.fromRGB(125, 120, 112)
	local glow = look.eyes or Color3.fromRGB(255, 200, 120)
	paint(model, { "UpperTorso", "LowerTorso" }, rock, SLATE)
	paint(model, ARMS, rock, SLATE)
	paint(model, LEGS, rock:Lerp(Color3.new(0, 0, 0), 0.15), SLATE)
	hideParts(model, { "Head" })
	local dark = rock:Lerp(Color3.new(0, 0, 0), 0.2)
	wear(model, "Head", "RockHead", Vector3.new(1.3, 1.0, 1.2) * k, CFrame.new(0, -0.15 * k, 0) * CFrame.Angles(0.1, 0.3, 0.05), dark, SLATE)
	wear(model, "Head", "EyeSlit", Vector3.new(0.9, 0.12, 0.08) * k, CFrame.new(0, -0.05 * k, -0.62 * k), glow, NEON)
	-- 가슴 바위판 셋과 그 사이의 빛나는 금
	wear(model, "UpperTorso", "Boulder", Vector3.new(1.4, 1.0, 0.6) * k, CFrame.new(-0.4 * k, 0.3 * k, -0.45 * k) * CFrame.Angles(0.1, 0.2, 0.15), rock, SLATE)
	wear(model, "UpperTorso", "Boulder", Vector3.new(1.2, 0.9, 0.6) * k, CFrame.new(0.5 * k, -0.2 * k, -0.45 * k) * CFrame.Angles(-0.1, -0.2, -0.1), dark, SLATE)
	wear(model, "UpperTorso", "Crack", Vector3.new(0.1, 1.3, 0.05) * k, CFrame.new(0.05 * k, 0.05 * k, -0.78 * k) * CFrame.Angles(0, 0, math.rad(20)), glow, NEON)
	wear(model, "UpperTorso", "Crack", Vector3.new(0.9, 0.08, 0.05) * k, CFrame.new(0.1 * k, 0.1 * k, -0.78 * k) * CFrame.Angles(0, 0, math.rad(-10)), glow, NEON)
	-- 어깨의 큰 바윗덩이, 등의 바위 혹
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "UpperTorso", "Shoulder", Vector3.new(1.4, 1.2, 1.4) * k, CFrame.new(x * 1.2 * k, 0.75 * k, 0) * CFrame.Angles(0.3 * x, 0.5, 0.2), dark, SLATE, Ball)
	end
	wear(model, "UpperTorso", "BackRock", Vector3.new(1.8, 1.4, 1.0) * k, CFrame.new(0, 0.5 * k, 0.6 * k) * CFrame.Angles(0.3, 0, 0), rock, SLATE)
	-- 큰 주먹 (손과 아래팔을 바위로 덮는다)
	for _, side in ipairs({ "Left", "Right" }) do
		wear(model, side .. "LowerArm", "Gauntlet", Vector3.new(1.3, 1.1, 1.3) * k, CFrame.new(0, -0.1 * k, 0) * CFrame.Angles(0.1, 0.4, 0), rock, SLATE)
		wear(model, side .. "Hand", "Fist", Vector3.new(1.5, 1.1, 1.4) * k, CFrame.new(0, -0.3 * k, 0), dark, SLATE)
		wear(model, side .. "LowerLeg", "LegRock", Vector3.new(1.3, 0.9, 1.3) * k, CFrame.new(0, 0, 0) * CFrame.Angles(0, 0.6, 0), dark, SLATE)
	end
	if look.moss then
		for i = 0, 3 do
			wear(model, i < 2 and "UpperTorso" or "Head", "Moss", Vector3.new(0.9, 0.2, 0.9) * k, CFrame.new((i % 2 - 0.5) * 0.9 * k, (i < 2 and 1.0 or 0.4) * k, (i % 2) * 0.3 * k), look.moss, Enum.Material.Grass)
		end
	end
	if look.ember then
		emit(partOf(model, "UpperTorso"), look.ember, 6, 0.4 * k, 2, Vector3.new(0, 5, 0))
	end
end
-- 망령: 다리 없이 바닥까지 끌리는 찢긴 옷자락, 큰 두건 속 어둠과 빛나는 두 눈, 뼈만 남은 팔
FORMS.wraith = function(model, look, k)
	local cloth = look.cloth or Color3.fromRGB(215, 190, 140)
	local eye = look.eyes or Color3.fromRGB(255, 230, 150)
	hideParts(model, LEGS)
	paint(model, { "UpperTorso", "LowerTorso" }, cloth, Enum.Material.Fabric)
	paint(model, ARMS, look.bone or Color3.fromRGB(70, 60, 55), SMOOTH)
	paint(model, { "Head" }, Color3.fromRGB(8, 6, 10), SMOOTH)
	local head = partOf(model, "Head")
	for _, d in ipairs(head and head:GetChildren() or {}) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	wear(model, "Head", "Hood", Vector3.new(1.6, 1.7, 1.6) * k, CFrame.new(0, 0.15 * k, 0.2 * k), cloth, Enum.Material.Fabric, Ball)
	wear(model, "Head", "HoodPeak", Vector3.new(0.5, 0.8, 0.5) * k, CFrame.new(0, 0.9 * k, 0.5 * k) * CFrame.Angles(math.rad(-35), 0, 0), cloth, Enum.Material.Fabric)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.22, 0.22, 0.1) * k, CFrame.new(x * 0.24 * k, 0.05 * k, -0.62 * k), eye, NEON, Ball)
	end
	-- 찢긴 옷자락 (길이가 제각각인 띠 여덟)
	for i = 0, 7 do
		local a = (i / 8) * math.pi * 2
		local len = (2.6 + (i % 3) * 0.6) * k
		wear(model, "LowerTorso", "Rag", Vector3.new(0.7 * k, len, 0.08 * k), CFrame.new(math.cos(a) * 0.85 * k, -len / 2 - 0.1 * k, math.sin(a) * 0.55 * k) * CFrame.Angles(math.sin(a) * 0.25, -a, math.cos(a) * 0.15), cloth:Lerp(Color3.new(0, 0, 0), (i % 2) * 0.25), Enum.Material.Fabric)
	end
	emit(partOf(model, "LowerTorso"), look.dust or cloth, 10, 0.5 * k, 1.5, Vector3.new(0, -1, 0))
end
-- 새 무사 (학·봉황): 부리와 볏, 접은 날개, 꼬리깃
FORMS.bird = function(model, look, k)
	local feather = look.feather or Color3.fromRGB(240, 240, 240)
	local crest = look.crest or Color3.fromRGB(220, 40, 40)
	local beak = look.beak or Color3.fromRGB(230, 190, 90)
	local head = partOf(model, "Head")
	local hs = head and head.Size or Vector3.new(1.2, 1.2, 1.2)
	paint(model, { "Head" }, feather, SMOOTH)
	for _, d in ipairs(head and head:GetChildren() or {}) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	paint(model, ARMS, feather, SMOOTH)
	-- 긴 부리 (위아래 둘)
	wear(model, "Head", "Beak", Vector3.new(0.22, 0.2, 1.1) * k, CFrame.new(0, -0.02 * hs.Y, -0.95 * hs.Z) * CFrame.Angles(math.rad(-8), 0, 0), beak, SMOOTH)
	wear(model, "Head", "BeakLow", Vector3.new(0.18, 0.1, 0.8) * k, CFrame.new(0, -0.16 * hs.Y, -0.8 * hs.Z) * CFrame.Angles(math.rad(5), 0, 0), beak:Lerp(Color3.new(0, 0, 0), 0.2), SMOOTH)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.14, 0.14, 0.14) * k, CFrame.new(x * 0.34 * hs.X, 0.12 * hs.Y, -0.42 * hs.Z), look.eyes or Color3.fromRGB(20, 20, 20), NEON, Ball)
	end
	-- 볏 (뒤로 넘어가는 깃 셋)
	for j = 0, 2 do
		wear(model, "Head", "Crest", Vector3.new(0.1, 0.7 - j * 0.12, 0.3) * k, CFrame.new(0, (0.55 + j * 0.05) * hs.Y, (0.1 + j * 0.22) * hs.Z) * CFrame.Angles(math.rad(-30 - j * 15), 0, 0), crest, look.crestMat or SMOOTH)
	end
	-- 등에 접은 날개 (깃 다섯 겹)
	for _, x in ipairs({ -1, 1 }) do
		for j = 0, 4 do
			wear(model, "UpperTorso", "Feather", Vector3.new(0.12, (1.8 - j * 0.15) * k, 0.45 * k), CFrame.new(x * (0.55 + j * 0.12) * k, (0.2 - j * 0.25) * k, (0.58 + j * 0.03) * k) * CFrame.Angles(math.rad(12), 0, x * math.rad(8 + j * 6)), j % 2 == 0 and feather or feather:Lerp(crest, 0.25), SMOOTH)
		end
	end
	-- 꼬리깃
	for j = -2, 2 do
		wear(model, "LowerTorso", "TailFeather", Vector3.new(0.18, 1.6, 0.06) * k, CFrame.new(j * 0.18 * k, -0.7 * k, 0.6 * k) * CFrame.Angles(math.rad(35), 0, math.rad(j * 10)), j == 0 and crest or feather, SMOOTH)
	end
	if look.fire then
		emit(partOf(model, "UpperTorso"), look.fire, 10, 0.5 * k, 2.5, Vector3.new(0, 4, 0))
	end
end
-- 해골: 검은 몸 위에 흰 뼈 (갈비뼈, 등뼈, 팔다리뼈), 해골 머리와 빛나는 눈
FORMS.skeleton = function(model, look, k)
	local bone = Color3.fromRGB(225, 215, 190)
	paint(model, { "UpperTorso", "LowerTorso" }, Color3.fromRGB(28, 24, 24), SMOOTH)
	paint(model, ARMS, Color3.fromRGB(28, 24, 24), SMOOTH)
	paint(model, LEGS, Color3.fromRGB(28, 24, 24), SMOOTH)
	paint(model, { "Head" }, bone, SMOOTH)
	local head = partOf(model, "Head")
	for _, d in ipairs(head and head:GetChildren() or {}) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	local eye = look.eyes or Color3.fromRGB(255, 200, 90)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Socket", Vector3.new(0.34, 0.34, 0.1) * k, CFrame.new(x * 0.25 * k, 0.08 * k, -0.6 * k), Color3.fromRGB(10, 8, 8), SMOOTH, Ball)
		wear(model, "Head", "Eye", Vector3.new(0.14, 0.14, 0.1) * k, CFrame.new(x * 0.25 * k, 0.08 * k, -0.64 * k), eye, NEON, Ball)
	end
	wear(model, "Head", "Jaw", Vector3.new(0.8, 0.22, 0.5) * k, CFrame.new(0, -0.45 * k, -0.3 * k), bone, SMOOTH)
	for i = 0, 3 do
		wear(model, "UpperTorso", "Rib", Vector3.new(1.7 - i * 0.15, 0.12, 0.12) * k, CFrame.new(0, (0.55 - i * 0.32) * k, -0.55 * k), bone, SMOOTH)
	end
	wear(model, "UpperTorso", "Sternum", Vector3.new(0.16, 1.3, 0.14) * k, CFrame.new(0, 0.1 * k, -0.58 * k), bone, SMOOTH)
	for _, n in ipairs({ "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg" }) do
		local p = partOf(model, n)
		if p then
			wear(model, n, "Bone", Vector3.new(0.25, p.Size.Y * 0.95, 0.25), CFrame.new(0, 0, -p.Size.Z * 0.52), bone, SMOOTH)
		end
	end
	emit(partOf(model, "Head"), eye, 3, 0.25 * k, 1, Vector3.new(0, 2, 0))
end
-- 버섯: 머리 위의 커다란 갓 (흰 점), 굵은 자루 목, 갓 아래의 빛나는 눈, 떠다니는 포자
FORMS.shroom = function(model, look, k)
	local cap = look.capColor or Color3.fromRGB(170, 40, 50)
	local stem = look.skin or Color3.fromRGB(225, 215, 190)
	paint(model, { "Head", "UpperTorso", "LowerTorso" }, stem, SMOOTH)
	paint(model, ARMS, stem, SMOOTH)
	local head = partOf(model, "Head")
	for _, d in ipairs(head and head:GetChildren() or {}) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	local big = look.capSize or 3.4
	wear(model, "Head", "Cap", Vector3.new(big, big * 0.45, big) * k, CFrame.new(0, 0.55 * k, 0), cap, SMOOTH, Ball)
	wear(model, "Head", "Gills", Vector3.new(0.1, big * 0.8, big * 0.8) * k, CFrame.new(0, 0.38 * k, 0) * CFrame.Angles(0, 0, math.rad(90)), stem:Lerp(Color3.new(0, 0, 0), 0.2), SMOOTH, Cyl)
	for i = 0, 6 do
		local a = i * 2.1
		local r = (i == 0) and 0 or big * 0.3
		wear(model, "Head", "Spot", Vector3.new(0.45, 0.2, 0.45) * k, CFrame.new(math.cos(a) * r * k, (0.55 + big * 0.2 - (r > 0 and 0.12 or 0)) * k, math.sin(a) * r * k), Color3.fromRGB(245, 240, 230), SMOOTH, Ball)
	end
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.2, 0.2, 0.1) * k, CFrame.new(x * 0.25 * k, -0.05 * k, -0.6 * k), look.eyes or Color3.fromRGB(255, 240, 120), NEON, Ball)
	end
	emit(partOf(model, "Head"), look.spore or Color3.fromRGB(200, 255, 160), 8, 0.35 * k, 1.5, Vector3.new(0, -0.5, 0))
end
-- 늪 거한: 굽은 등, 이끼와 물풀, 엄니, 늘어진 귀, 큰 배
FORMS.troll = function(model, look, k)
	local skin = look.skin or Color3.fromRGB(110, 130, 80)
	paint(model, { "Head", "UpperTorso", "LowerTorso" }, skin, SMOOTH)
	paint(model, ARMS, skin, SMOOTH)
	local head = partOf(model, "Head")
	for _, d in ipairs(head and head:GetChildren() or {}) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	wear(model, "UpperTorso", "Belly", Vector3.new(1.9, 1.5, 1.2) * k, CFrame.new(0, -0.35 * k, -0.35 * k), skin:Lerp(Color3.new(1, 1, 0.8), 0.15), SMOOTH, Ball)
	wear(model, "UpperTorso", "Hump", Vector3.new(1.8, 1.2, 1.2) * k, CFrame.new(0, 0.75 * k, 0.45 * k), skin:Lerp(Color3.new(0, 0, 0), 0.15), SMOOTH, Ball)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Tusk", Vector3.new(0.14, 0.45, 0.14) * k, CFrame.new(x * 0.28 * k, -0.25 * k, -0.6 * k) * CFrame.Angles(0, 0, x * math.rad(15)), Color3.fromRGB(235, 225, 200), SMOOTH)
		wear(model, "Head", "Ear", Vector3.new(0.12, 0.6, 0.35) * k, CFrame.new(x * 0.7 * k, 0.05 * k, 0) * CFrame.Angles(0, 0, -x * math.rad(70)), skin, SMOOTH)
		wear(model, "Head", "Eye", Vector3.new(0.2, 0.12, 0.08) * k, CFrame.new(x * 0.24 * k, 0.12 * k, -0.6 * k), look.eyes or Color3.fromRGB(255, 220, 80), NEON)
	end
	for i = 0, 4 do
		wear(model, i < 3 and "UpperTorso" or "Head", "Moss", Vector3.new(0.9, 0.25, 0.8) * k, CFrame.new((i % 3 - 1) * 0.6 * k, (i < 3 and 1.15 or 0.55) * k, (i % 2) * 0.25 * k), Color3.fromRGB(70, 110, 40), Enum.Material.Grass)
		wear(model, "UpperTorso", "Weed", Vector3.new(0.12, 1.0, 0.06) * k, CFrame.new((i - 2) * 0.35 * k, 0.1 * k, -0.62 * k), Color3.fromRGB(60, 90, 40), SMOOTH)
	end
end
-- 뱀 자객: 다리 대신 땅에 끌리는 뱀 꼬리, 머리 뒤로 펼친 목덜미, 비늘 띠, 갈라진 혀
FORMS.naga = function(model, look, k)
	local scale = look.skin or Color3.fromRGB(60, 110, 60)
	local belly = Color3.fromRGB(200, 200, 130)
	hideParts(model, LEGS)
	paint(model, { "Head", "UpperTorso", "LowerTorso" }, scale, SMOOTH)
	paint(model, ARMS, scale, SMOOTH)
	local head = partOf(model, "Head")
	for _, d in ipairs(head and head:GetChildren() or {}) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	wear(model, "Head", "Hood", Vector3.new(2.2, 1.8, 0.16) * k, CFrame.new(0, 0.05 * k, 0.45 * k), scale:Lerp(Color3.new(0, 0, 0), 0.2), SMOOTH, Ball)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.28, 0.14, 0.08) * k, CFrame.new(x * 0.24 * k, 0.1 * k, -0.6 * k), look.eyes or Color3.fromRGB(240, 220, 60), NEON)
		wear(model, "Head", "Tongue", Vector3.new(0.04, 0.04, 0.35) * k, CFrame.new(x * 0.05 * k, -0.3 * k, -0.85 * k) * CFrame.Angles(0, x * math.rad(15), 0), Color3.fromRGB(200, 40, 60), SMOOTH)
	end
	for i = 0, 3 do
		wear(model, "UpperTorso", "BellyScale", Vector3.new(1.2 - i * 0.1, 0.22, 0.08) * k, CFrame.new(0, (0.5 - i * 0.35) * k, -0.52 * k), belly, SMOOTH)
	end
	-- 뱀 꼬리: 허리에서 내려와 뒤로 땅을 따라 굽이친다
	local cf = CFrame.new(0, -0.7 * k, 0.1 * k)
	for j = 0, 7 do
		local w = (1.5 - j * 0.15) * k
		wear(model, "LowerTorso", "Coil", Vector3.new(w, w * 0.8, w * 1.3), cf, j % 2 == 0 and scale or scale:Lerp(Color3.new(0, 0, 0), 0.25), SMOOTH, Ball)
		cf = cf * CFrame.new(math.sin(j * 1.2) * 0.4 * k, (j < 2 and -0.8 or -0.05) * k, 0.9 * k)
	end
end
-- 늑대 무사: 늑대 머리 (긴 주둥이·세운 귀), 갈기, 꼬리, 발톱
FORMS.wolf = function(model, look, k)
	local fur = look.fur or Color3.fromRGB(70, 20, 25)
	local eye = look.eyes or Color3.fromRGB(255, 60, 60)
	paint(model, { "Head" }, fur, Enum.Material.Fabric)
	paint(model, ARMS, fur:Lerp(Color3.new(0, 0, 0), 0.1), Enum.Material.Fabric)
	local head = partOf(model, "Head")
	for _, d in ipairs(head and head:GetChildren() or {}) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	wear(model, "Head", "Snout", Vector3.new(0.6, 0.5, 0.9) * k, CFrame.new(0, -0.15 * k, -0.75 * k), fur, Enum.Material.Fabric)
	wear(model, "Head", "Nose", Vector3.new(0.25, 0.18, 0.12) * k, CFrame.new(0, -0.02 * k, -1.2 * k), Color3.fromRGB(15, 10, 10), SMOOTH)
	wear(model, "Head", "Fangs", Vector3.new(0.45, 0.12, 0.08) * k, CFrame.new(0, -0.4 * k, -1.05 * k), Color3.fromRGB(240, 235, 225), SMOOTH)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Ear", Vector3.new(0.3, 0.6, 0.12) * k, CFrame.new(x * 0.36 * k, 0.7 * k, 0.05 * k) * CFrame.Angles(0, 0, -x * math.rad(12)), fur, Enum.Material.Fabric)
		wear(model, "Head", "Eye", Vector3.new(0.22, 0.1, 0.08) * k, CFrame.new(x * 0.26 * k, 0.15 * k, -0.6 * k) * CFrame.Angles(0, 0, x * math.rad(-15)), eye, NEON)
	end
	-- 갈기 (목과 어깨를 덮는 털 뭉치)
	for i = 0, 4 do
		local a = (i / 4 - 0.5) * math.pi
		wear(model, "UpperTorso", "Mane", Vector3.new(0.8, 0.9, 0.8) * k, CFrame.new(math.sin(a) * 0.8 * k, 0.85 * k, math.cos(a) * 0.35 * k + 0.1 * k), fur:Lerp(Color3.new(0, 0, 0), (i % 2) * 0.2), Enum.Material.Fabric, Ball)
	end
	local prev = CFrame.new(0, 0, 0.5 * k)
	for j = 1, 4 do
		local seg = prev * CFrame.Angles(math.rad(25), 0, 0) * CFrame.new(0, -0.3 * k, 0)
		wear(model, "LowerTorso", "Tail", Vector3.new(0.4 - j * 0.05, 0.7, 0.4 - j * 0.05) * k, seg, fur, Enum.Material.Fabric)
		prev = seg * CFrame.new(0, -0.3 * k, 0)
	end
	for _, hn in ipairs({ "LeftHand", "RightHand" }) do
		for j = -1, 1 do
			wear(model, hn, "Claw", Vector3.new(0.08, 0.4, 0.08) * k, CFrame.new(j * 0.22 * k, -0.32 * k, -0.15 * k) * CFrame.Angles(math.rad(25), 0, 0), Color3.fromRGB(235, 225, 210), SMOOTH)
		end
	end
end

local function buildForm(model: Model, look: any): boolean
	local fn = FORMS[look.form]
	if not fn then
		return false
	end
	local ut = partOf(model, "UpperTorso")
	local k = ut and ut.Size.Y / 1.6 or 1
	fn(model, look, k)
	return true
end

------------------------------------------------------------------------
-- 2.6판: 차림 손질
-- 사람 적: 팔목 감개·장화·옷깃 (맨몸 같던 팔다리에 옷의 결을)
-- 보스: 뒤로 늘어진 망토, 몸에서 피어오르는 기운, 그리고 보스마다 하나뿐인 표식 (관·날개·후광·북·잎 관 …)
------------------------------------------------------------------------
local function sizeOf(model: Model, name: string): Vector3
	local p = model:FindFirstChild(name)
	return (p and p:IsA("BasePart")) and p.Size or Vector3.new(1, 1, 1)
end
local function aura(model: Model, partName: string, color: Color3, rate: number, size: number, up: number)
	local p = model:FindFirstChild(partName)
	if not p or not p:IsA("BasePart") then
		return
	end
	local a = Instance.new("Attachment")
	a.Parent = p
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0.7
	e.Rate = rate
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(up * 0.5, up)
	e.SpreadAngle = Vector2.new(40, 40)
	e.Acceleration = Vector3.new(0, up, 0)
	e.Size = NumberSequence.new(size, 0)
	e.Parent = a
end
local function humanDetail(model: Model, look: any, k: number)
	local cloth = look.cloth or Color3.fromRGB(60, 50, 40)
	local wrapC = cloth:Lerp(Color3.fromRGB(230, 220, 200), 0.35)
	local leather = Color3.fromRGB(48, 36, 28)
	for _, side in ipairs({ "Left", "Right" }) do
		local la = sizeOf(model, side .. "LowerArm")
		wear(model, side .. "LowerArm", "Bracer", Vector3.new(la.X * 1.08, la.Y * 0.55, la.Z * 1.08), CFrame.new(0, -la.Y * 0.18, 0), wrapC, Enum.Material.Fabric)
		local ll = sizeOf(model, side .. "LowerLeg")
		wear(model, side .. "LowerLeg", "Boot", Vector3.new(ll.X * 1.1, ll.Y * 0.7, ll.Z * 1.1), CFrame.new(0, -ll.Y * 0.15, 0), leather, Enum.Material.Leather)
		local ft = sizeOf(model, side .. "Foot")
		wear(model, side .. "Foot", "BootToe", Vector3.new(ft.X * 1.08, ft.Y * 1.3, ft.Z * 1.12), CFrame.new(0, 0, -ft.Z * 0.04), leather, Enum.Material.Leather)
	end
	local ut = sizeOf(model, "UpperTorso")
	-- 여밈 옷깃 (가슴에 비스듬한 깃 둘)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "UpperTorso", "Collar", Vector3.new(0.18 * k, ut.Y * 0.62, 0.08 * k), CFrame.new(x * ut.X * 0.12, ut.Y * 0.12, -ut.Z * 0.52) * CFrame.Angles(0, 0, x * math.rad(28)), cloth:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Fabric)
	end
end
local SIG: { [string]: (Model, any, number) -> () } = {}
local NEON2 = Enum.Material.Neon
local function horns(model: Model, color: Color3, k: number, big: number)
	local hs = sizeOf(model, "Head")
	for _, x in ipairs({ -1, 1 }) do
		for j = 0, 3 do
			wear(model, "Head", "BossHorn", Vector3.new((0.3 - j * 0.05) * k, 0.55 * k * big, (0.3 - j * 0.05) * k), CFrame.new(x * (0.35 + j * 0.16) * hs.X, (0.55 + j * 0.3) * hs.Y, (0.05 + j * 0.14) * hs.Z) * CFrame.Angles(math.rad(-18 * j), 0, -x * math.rad(35 - j * 22)), color, Enum.Material.SmoothPlastic)
		end
	end
end
local function wings(model: Model, bone: Color3, skin: Color3, k: number, span: number, mat: Enum.Material?, alpha: number?)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "UpperTorso", "WingBone", Vector3.new(0.25 * k, 3.4 * k * span, 0.25 * k), CFrame.new(x * 1.6 * k * span, 1.4 * k, 0.75 * k) * CFrame.Angles(math.rad(15), 0, -x * math.rad(58)), bone, Enum.Material.SmoothPlastic)
		for j = 0, 2 do
			local w = wear(model, "UpperTorso", "Wing", Vector3.new(2.2 * k * span, (2.6 - j * 0.5) * k * span, 0.08 * k), CFrame.new(x * (1.6 + j * 1.1) * k * span, (0.6 - j * 0.35) * k, (0.8 + j * 0.06) * k) * CFrame.Angles(math.rad(12), x * math.rad(-18), x * math.rad(-12 + j * 14)), skin, mat or Enum.Material.SmoothPlastic)
			if w and alpha then
				w.Transparency = alpha
			end
		end
	end
end
local function crown(model: Model, color: Color3, k: number, n: number, h: number, mat: Enum.Material?)
	local hs = sizeOf(model, "Head")
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		wear(model, "Head", "CrownSpike", Vector3.new(0.16 * k, h * k * (i % 2 == 0 and 1 or 0.7), 0.16 * k), CFrame.new(math.cos(a) * hs.X * 0.42, hs.Y * 0.62, math.sin(a) * hs.Z * 0.42) * CFrame.Angles(math.sin(a) * 0.25, 0, -math.cos(a) * 0.25), color, mat or NEON2)
	end
	wear(model, "Head", "CrownBand", Vector3.new(0.14 * k, hs.X * 0.95, hs.Z * 0.95), CFrame.new(0, hs.Y * 0.48, 0) * CFrame.Angles(0, 0, math.rad(90)), color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Metal, Cyl)
end
local function halo(model: Model, color: Color3, k: number, r: number, segments: number?, broken: boolean?)
	local n = segments or 16
	for i = 0, n - 1 do
		if not (broken and i % 4 == 1) then
			local a = i / n * math.pi * 2
			wear(model, "UpperTorso", "Halo", Vector3.new(0.18 * k, 0.18 * k, r * k * 0.42), CFrame.new(math.cos(a) * r * k, 1.9 * k + math.sin(a) * r * k, 0.9 * k) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(a + math.pi / 2, 0, 0), color, NEON2)
		end
	end
end
SIG.heukho = function(model, look, k)
	-- 흑호: 호랑이 가죽을 뒤집어쓴 두목 (줄무늬 머리 가죽과 귀, 이빨 목걸이)
	local hs = sizeOf(model, "Head")
	wear(model, "Head", "TigerPelt", Vector3.new(hs.X * 1.15, hs.Y * 0.7, hs.Z * 1.2), CFrame.new(0, hs.Y * 0.32, hs.Z * 0.12), Color3.fromRGB(215, 120, 40), Enum.Material.Fabric, Ball)
	for i = -1, 1 do
		wear(model, "Head", "TigerStripe", Vector3.new(0.12 * k, hs.Y * 0.4, hs.Z * 0.9), CFrame.new(i * hs.X * 0.25, hs.Y * 0.45, hs.Z * 0.15), Color3.fromRGB(25, 20, 15), Enum.Material.Fabric)
	end
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "TigerEar", Vector3.new(0.4 * k, 0.4 * k, 0.15 * k), CFrame.new(x * hs.X * 0.38, hs.Y * 0.75, 0), Color3.fromRGB(215, 120, 40), Enum.Material.Fabric, Ball)
	end
	for i = -2, 2 do
		wear(model, "UpperTorso", "FangBead", Vector3.new(0.14 * k, 0.4 * k, 0.14 * k), CFrame.new(i * 0.28 * k, 0.55 * k - math.abs(i) * 0.08 * k, -0.62 * k) * CFrame.Angles(0, 0, i * 0.2), Color3.fromRGB(240, 230, 210), Enum.Material.SmoothPlastic)
	end
end
SIG.bingma = function(model, look, k)
	crown(model, Color3.fromRGB(170, 230, 255), k, 7, 1.0)
	for _, x in ipairs({ -1, 1 }) do
		for j = 0, 2 do
			wear(model, "UpperTorso", "Icicle", Vector3.new(0.22 * k, (0.9 - j * 0.2) * k, 0.22 * k), CFrame.new(x * (1.0 + j * 0.25) * k, 1.0 * k, (j - 1) * 0.3 * k) * CFrame.Angles(0, 0, -x * math.rad(20 + j * 15)), Color3.fromRGB(200, 240, 255), Enum.Material.Glass)
		end
	end
	aura(model, "UpperTorso", Color3.fromRGB(200, 240, 255), 8, 0.4 * k, 2)
end
SIG.bingje = function(model, look, k)
	crown(model, Color3.fromRGB(190, 240, 255), k, 9, 1.3)
	wings(model, Color3.fromRGB(200, 240, 255), Color3.fromRGB(170, 225, 255), k, 1.1, Enum.Material.Glass, 0.25)
end
SIG.hyeolma = function(model, look, k)
	halo(model, Color3.fromRGB(220, 20, 40), k, 1.3, 14)
	for _, side in ipairs({ "LeftHand", "RightHand" }) do
		for j = -1, 1 do
			wear(model, side, "BloodClaw", Vector3.new(0.12 * k, 0.9 * k, 0.12 * k), CFrame.new(j * 0.25 * k, -0.6 * k, -0.15 * k) * CFrame.Angles(math.rad(25), 0, 0), Color3.fromRGB(230, 20, 40), NEON2)
		end
	end
	aura(model, "LowerTorso", Color3.fromRGB(200, 20, 40), 12, 0.5 * k, 3)
end
SIG.cheonma = function(model, look, k)
	horns(model, Color3.fromRGB(30, 15, 40), k, 1.3)
	wings(model, Color3.fromRGB(40, 20, 50), Color3.fromRGB(45, 15, 70), k, 1.25)
	aura(model, "UpperTorso", Color3.fromRGB(170, 90, 255), 10, 0.5 * k, 2)
end
SIG.yeomje = function(model, look, k)
	crown(model, Color3.fromRGB(255, 140, 40), k, 7, 1.2)
	aura(model, "Head", Color3.fromRGB(255, 140, 40), 14, 0.6 * k, 6)
	for _, x in ipairs({ -1, 1 }) do
		local fs = wear(model, "UpperTorso", "FlameShoulder", Vector3.new(0.9 * k, 0.9 * k, 0.9 * k), CFrame.new(x * 1.2 * k, 0.95 * k, 0), Color3.fromRGB(255, 110, 30), NEON2, Ball)
		if fs then
			fs.Transparency = 0.3
		end
	end
end
SIG.sawang = function(model, look, k)
	-- 사왕: 층층이 솟은 모래 왕관과 가슴의 청옥, 어깨에 늘어진 금 띠
	local hs = sizeOf(model, "Head")
	for j = 0, 3 do
		wear(model, "Head", "SandCrown", Vector3.new(hs.Y * 0.28, hs.X * (1.0 - j * 0.12), hs.Z * (1.0 - j * 0.12)), CFrame.new(0, hs.Y * (0.45 + j * 0.24), 0) * CFrame.Angles(0, 0, math.rad(90)), j % 2 == 0 and Color3.fromRGB(230, 190, 80) or Color3.fromRGB(40, 90, 170), Enum.Material.Metal, Cyl)
	end
	wear(model, "UpperTorso", "Jewel", Vector3.new(0.7 * k, 0.7 * k, 0.2 * k), CFrame.new(0, 0.2 * k, -0.6 * k), Color3.fromRGB(60, 150, 220), NEON2, Ball)
	aura(model, "LowerTorso", Color3.fromRGB(230, 200, 140), 10, 0.5 * k, 1)
end
SIG.cheonmun = function(model, look, k)
	halo(model, Color3.fromRGB(255, 230, 150), k, 1.5, 18)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "UpperTorso", "GateTower", Vector3.new(0.6 * k, 1.6 * k, 0.6 * k), CFrame.new(x * 1.3 * k, 1.5 * k, 0.2 * k), Color3.fromRGB(240, 242, 255), Enum.Material.Marble)
		wear(model, "UpperTorso", "GateTip", Vector3.new(0.4 * k, 0.4 * k, 0.4 * k), CFrame.new(x * 1.3 * k, 2.45 * k, 0.2 * k), Color3.fromRGB(255, 230, 150), NEON2, Ball)
	end
end
SIG.noeje = function(model, look, k)
	-- 뇌제: 등 뒤에 둥글게 걸린 천둥 북 여섯
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local drum = wear(model, "UpperTorso", "ThunderDrum", Vector3.new(0.45 * k, 0.9 * k, 0.9 * k), CFrame.new(math.cos(a) * 1.9 * k, 1.5 * k + math.sin(a) * 1.9 * k, 0.9 * k) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(110, 40, 40), Enum.Material.Wood, Cyl)
		wear(model, "UpperTorso", "DrumFace", Vector3.new(0.05 * k, 0.8 * k, 0.8 * k), CFrame.new(math.cos(a) * 1.9 * k, 1.5 * k + math.sin(a) * 1.9 * k, 0.65 * k) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(200, 220, 255), NEON2, Cyl)
		local _ = drum
	end
	halo(model, Color3.fromRGB(150, 200, 255), k, 1.9, 24)
	aura(model, "UpperTorso", Color3.fromRGB(170, 210, 255), 8, 0.3 * k, 4)
end
SIG.seonggun = function(model, look, k)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2 + math.pi / 2
		wear(model, "UpperTorso", "StarPoint", Vector3.new(0.3 * k, 0.3 * k, 0.3 * k), CFrame.new(math.cos(a) * 1.5 * k, 1.8 * k + math.sin(a) * 1.5 * k, 0.8 * k), Color3.fromRGB(255, 240, 200), NEON2, Ball)
	end
	halo(model, Color3.fromRGB(200, 170, 255), k, 1.5, 20)
	aura(model, "UpperTorso", Color3.fromRGB(220, 200, 255), 8, 0.35 * k, 1)
end
SIG.cheonjon = function(model, look, k)
	halo(model, Color3.fromRGB(255, 225, 140), k, 1.8, 24)
	-- 등 뒤로 퍼지는 금빛 살 여덟
	for i = 0, 7 do
		local a = (i / 7 - 0.5) * math.pi * 0.9
		wear(model, "UpperTorso", "GoldRay", Vector3.new(0.15 * k, 3.2 * k, 0.15 * k), CFrame.new(math.sin(a) * 1.6 * k, 1.6 * k + math.cos(a) * 1.4 * k, 0.85 * k) * CFrame.Angles(0, 0, -a), Color3.fromRGB(255, 230, 150), NEON2)
	end
	aura(model, "LowerTorso", Color3.fromRGB(255, 230, 150), 10, 0.4 * k, 2)
end
SIG.cheongeop = function(model, look, k)
	-- 천겁: 깨진 검은 후광과 둘레를 맴도는 폭풍 기운
	halo(model, Color3.fromRGB(60, 20, 80), k, 1.7, 16, true)
	horns(model, Color3.fromRGB(20, 15, 25), k, 0.9)
	aura(model, "UpperTorso", Color3.fromRGB(140, 60, 200), 16, 0.6 * k, 3)
end
SIG.pungyeop = function(model, look, k)
	-- 풍엽: 단풍잎 관과 떨어지는 잎
	local hs = sizeOf(model, "Head")
	for i = 0, 6 do
		local a = (i / 6 - 0.5) * math.pi
		wear(model, "Head", "MapleLeaf", Vector3.new(0.7 * k, 0.7 * k, 0.08 * k), CFrame.new(math.sin(a) * hs.X * 0.55, hs.Y * 0.6 + math.cos(a) * hs.Y * 0.25, hs.Z * 0.1) * CFrame.Angles(0, 0, -a + math.rad(45)), i % 2 == 0 and Color3.fromRGB(230, 70, 30) or Color3.fromRGB(255, 160, 40), Enum.Material.SmoothPlastic)
	end
	aura(model, "UpperTorso", Color3.fromRGB(240, 110, 40), 6, 0.5 * k, -2)
end
SIG.seokwang = function(model, look, k)
	-- 석왕: 돌 거인의 왕. 호박빛 수정 관, 가슴의 빛나는 왕의 문양, 어깨에서 늘어진 돌판 망토, 팔의 빛나는 결, 머리 둘레에 떠 있는 수정
	local amber = Color3.fromRGB(255, 190, 90)
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		wear(model, "Head", "CrystalCrown", Vector3.new(0.35 * k, (i % 2 == 0 and 1.4 or 0.9) * k, 0.35 * k), CFrame.new(math.cos(a) * 0.6 * k, 0.7 * k, math.sin(a) * 0.6 * k) * CFrame.Angles(math.sin(a) * 0.3, math.rad(45), -math.cos(a) * 0.3), amber, NEON2)
	end
	wear(model, "UpperTorso", "KingSigil", Vector3.new(0.08 * k, 1.1 * k, 1.1 * k), CFrame.new(0, 0.15 * k, -0.85 * k) * CFrame.Angles(0, math.rad(90), 0), amber, NEON2, Cyl)
	wear(model, "UpperTorso", "KingSigilCore", Vector3.new(0.5 * k, 0.5 * k, 0.5 * k), CFrame.new(0, 0.15 * k, -0.9 * k), Color3.fromRGB(255, 240, 200), NEON2, Ball)
	-- 돌판 망토 (네 장이 겹쳐 늘어진다)
	for i = 0, 3 do
		wear(model, "UpperTorso", "StoneCape", Vector3.new(1.0 * k, 2.6 * k - i * 0.2 * k, 0.3 * k), CFrame.new((i - 1.5) * 0.7 * k, -0.6 * k, 0.75 * k) * CFrame.Angles(math.rad(10), 0, (i - 1.5) * 0.12), Color3.fromRGB(105, 100, 92):Lerp(Color3.new(0, 0, 0), i * 0.05), Enum.Material.Slate)
	end
	for _, side in ipairs({ "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }) do
		local s = sizeOf(model, side)
		wear(model, side, "ArmVein", Vector3.new(0.1 * k, s.Y * 0.8, 0.06 * k), CFrame.new(0, 0, -s.Z * 0.55) * CFrame.Angles(0, 0, math.rad(12)), amber, NEON2)
	end
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + 0.4
		wear(model, "Head", "FloatCrystal", Vector3.new(0.5 * k, 0.9 * k, 0.5 * k), CFrame.new(math.cos(a) * 1.8 * k, 0.4 * k, math.sin(a) * 1.8 * k) * CFrame.Angles(0.4, a, 0.4), amber:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.Glass)
	end
	aura(model, "UpperTorso", amber, 8, 0.35 * k, 1.5)
end
SIG.gyunwang = function(model, look, k)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "UpperTorso", "ShoulderShroom", Vector3.new(1.4 * k, 0.6 * k, 1.4 * k), CFrame.new(x * 1.2 * k, 1.0 * k, 0), Color3.fromRGB(150, 30, 60), Enum.Material.SmoothPlastic, Ball)
	end
	aura(model, "Head", Color3.fromRGB(255, 200, 220), 14, 0.5 * k, -1)
end
SIG.dason = function(model, look, k)
	-- 다선: 커다란 삿갓과 허리의 찻주전자, 날리는 찻잎
	local hs = sizeOf(model, "Head")
	wear(model, "Head", "BigHat", Vector3.new(0.14 * k, hs.X * 3.2, hs.Z * 3.2), CFrame.new(0, hs.Y * 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 170, 110), Enum.Material.Fabric, Cyl)
	wear(model, "Head", "BigHatTop", Vector3.new(hs.Y * 0.35, hs.X * 1.0, hs.Z * 1.0), CFrame.new(0, hs.Y * 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(180, 150, 95), Enum.Material.Fabric, Cyl)
	wear(model, "LowerTorso", "TeaPot", Vector3.new(0.8 * k, 0.7 * k, 0.8 * k), CFrame.new(1.1 * k, -0.2 * k, 0), Color3.fromRGB(110, 80, 60), Enum.Material.SmoothPlastic, Ball)
	aura(model, "UpperTorso", Color3.fromRGB(140, 200, 110), 6, 0.4 * k, 1)
end
SIG.pokryong = function(model, look, k)
	-- 비천: 목에 감긴 물줄기 목도리 (투명한 물결 띠가 뒤로 흘러내린다)
	for i = 0, 4 do
		local w = wear(model, "UpperTorso", "WaterScarf", Vector3.new(1.4 * k - i * 0.15 * k, 0.5 * k, 0.12 * k), CFrame.new(0, 0.9 * k - i * 0.45 * k, 0.65 * k + i * 0.12 * k) * CFrame.Angles(math.rad(20 + i * 8), 0, (i % 2 - 0.5) * 0.3), Color3.fromRGB(140, 210, 255), Enum.Material.Glass)
		if w then
			w.Transparency = 0.3
		end
	end
	aura(model, "UpperTorso", Color3.fromRGB(180, 230, 255), 10, 0.4 * k, -2)
end
SIG.unmugun = function(model, look, k)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		wear(model, "UpperTorso", "CloudMantle", Vector3.new(1.0 * k, 0.8 * k, 1.0 * k), CFrame.new(math.cos(a) * 1.1 * k, 0.9 * k, math.sin(a) * 0.7 * k), Color3.fromRGB(240, 242, 250), Enum.Material.SmoothPlastic, Ball)
	end
	aura(model, "LowerTorso", Color3.fromRGB(240, 245, 255), 14, 0.7 * k, 0.5)
end
SIG.yeombong = function(model, look, k)
	wings(model, Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 120, 40), k, 1.3, NEON2, 0.35)
	aura(model, "UpperTorso", Color3.fromRGB(255, 150, 50), 14, 0.6 * k, 4)
end
SIG.seonhak = function(model, look, k)
	for j = -2, 2 do
		wear(model, "LowerTorso", "LongPlume", Vector3.new(0.2 * k, 3.0 * k, 0.06 * k), CFrame.new(j * 0.22 * k, -1.2 * k, 0.9 * k) * CFrame.Angles(math.rad(40), 0, math.rad(j * 8)), j == 0 and Color3.fromRGB(40, 140, 180) or Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic)
	end
	aura(model, "UpperTorso", Color3.fromRGB(200, 240, 255), 6, 0.4 * k, 1)
end
SIG.hyeolrang = function(model, look, k)
	for i = 0, 2 do
		wear(model, "UpperTorso", "BloodScarf", Vector3.new(1.4 * k - i * 0.2 * k, 0.4 * k, 0.1 * k), CFrame.new(0, 0.85 * k - i * 0.4 * k, 0.6 * k + i * 0.1 * k) * CFrame.Angles(math.rad(25 + i * 10), 0, 0), Color3.fromRGB(150, 15, 25), Enum.Material.Fabric)
	end
	aura(model, "Head", Color3.fromRGB(255, 60, 60), 4, 0.25 * k, 1)
end
local function bossRegalia(model: Model, look: any, typeId: string, isForm: boolean)
	local k = sizeOf(model, "UpperTorso").Y / 1.6
	-- 망토 (사람 보스만: 짐승·돌 거인은 표식만)
	if not isForm then
		local capeC = look.robe or look.cloth or (look.metal and look.metal:Lerp(Color3.new(0, 0, 0), 0.4)) or Color3.fromRGB(70, 40, 40)
		local ut = sizeOf(model, "UpperTorso")
		wear(model, "UpperTorso", "CapeCollar", Vector3.new(ut.X * 1.1, 0.35 * k, ut.Z * 1.1), CFrame.new(0, ut.Y * 0.5, 0.05 * k), capeC:Lerp(Color3.fromRGB(230, 190, 90), 0.3), Enum.Material.Fabric)
		for i, x in ipairs({ -1, 0, 1 }) do
			wear(model, "UpperTorso", "Cape", Vector3.new(ut.X * 0.42, 3.4 * k - math.abs(x) * 0.3 * k, 0.1 * k), CFrame.new(x * ut.X * 0.33, -1.0 * k, ut.Z * 0.62 + math.abs(x) * 0.05 * k) * CFrame.Angles(math.rad(8), x * math.rad(-10), 0), capeC:Lerp(Color3.new(0, 0, 0), (i % 2) * 0.12), Enum.Material.Fabric)
		end
	end
	local fn = SIG[typeId]
	if fn then
		local ok, err = pcall(fn, model, look, k)
		if not ok then
			warn("[권왕] 보스 표식 오류:", typeId, err)
		end
	else
		aura(model, "UpperTorso", look.eyes or Color3.fromRGB(255, 220, 160), 6, 0.35 * k, 1.5)
	end
end

dressEnemy = function(model: Model, typeId: string, _def: any, isBoss: boolean)
	local look = lookOf(typeId, isBoss)
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end
	-- 2.3판: 사람이 아닌 적은 그 생김새로 (머리쓰개·얼굴·허리띠는 쓰지 않는다)
	if look.form and buildForm(model, look) then
		if isBoss then
			bossRegalia(model, look, typeId, true)
		end
		return
	end
	local hs = head.Size
	local cloth = look.cloth or Color3.fromRGB(60, 50, 40)
	local Ball, Cyl = Enum.PartType.Ball, Enum.PartType.Cylinder
	-- 둥근 머리 위에 납작한 원통을 얹는다 (모자의 몸통)
	local function cap(name: string, radius: number, height: number, y: number, color: Color3, material: Enum.Material?)
		wear(model, "Head", name, Vector3.new(height, hs.X * radius * 2, hs.Z * radius * 2), CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), color, material, Cyl)
	end
	local kind = look.head
	if kind == "straw" then
		-- 삿갓: 넓은 챙과 뾰족한 꼭대기
		cap("HatBrim", 1.45, 0.12, hs.Y * 0.42, look.cloth or STRAW, Enum.Material.Fabric)
		cap("HatCrown", 0.62, hs.Y * 0.3, hs.Y * 0.58, look.cloth or STRAW, Enum.Material.Fabric)
		cap("HatTop", 0.32, hs.Y * 0.2, hs.Y * 0.8, (look.cloth or STRAW):Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Fabric)
	elseif kind == "bandana" then
		-- 두건: 머리 위를 감싸고 뒤로 매듭
		cap("Bandana", 0.54, hs.Y * 0.32, hs.Y * 0.3, cloth)
		wear(model, "Head", "BandanaKnot", Vector3.new(hs.X * 0.18, hs.Y * 0.18, hs.Z * 0.16), CFrame.new(0, hs.Y * 0.22, hs.Z * 0.55), cloth)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "Head", "BandanaTail", Vector3.new(hs.X * 0.1, hs.Y * 0.45, hs.Z * 0.05), CFrame.new(x * hs.X * 0.08, -hs.Y * 0.05, hs.Z * 0.6) * CFrame.Angles(math.rad(15), 0, x * math.rad(12)), cloth)
		end
	elseif kind == "hood" then
		-- 두건 겉옷: 뒤로 물린 둥근 두건 (얼굴은 드러난다)
		wear(model, "Head", "Hood", Vector3.new(hs.X * 1.16, hs.Y * 1.14, hs.Z * 1.12), CFrame.new(0, hs.Y * 0.08, hs.Z * 0.14), cloth, Enum.Material.Fabric, Ball)
		local utH = sizeOf(model, "UpperTorso")
		wear(model, "UpperTorso", "HoodDrape", Vector3.new(utH.X, 0.5 * utH.Y / 1.6, utH.Z * 1.2), CFrame.new(0, utH.Y * 0.53, 0.1 * utH.Y / 1.6), cloth)
	elseif kind == "helmet" then
		-- 투구: 머리 윗부분을 덮는 쇠 모자, 테, 코 가리개
		local metal = look.metal or IRON
		cap("Helmet", 0.56, hs.Y * 0.42, hs.Y * 0.28, metal, Enum.Material.Metal)
		cap("HelmetTop", 0.4, hs.Y * 0.18, hs.Y * 0.56, metal:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.Metal)
		cap("HelmetRim", 0.6, hs.Y * 0.08, hs.Y * 0.1, metal:Lerp(Color3.new(0, 0, 0), 0.3), Enum.Material.Metal)
		wear(model, "Head", "NoseGuard", Vector3.new(hs.X * 0.08, hs.Y * 0.3, hs.Z * 0.06), CFrame.new(0, 0, -hs.Z * 0.56), metal, Enum.Material.Metal)
		if look.plume then
			wear(model, "Head", "Plume", Vector3.new(hs.X * 0.12, hs.Y * 0.5, hs.Z * 0.6), CFrame.new(0, hs.Y * 0.85, hs.Z * 0.05), look.plume)
		end
	elseif kind == "topknot" then
		-- 상투: 머리를 덮는 머리칼과 정수리의 상투
		local hair = look.hair or DARK_HAIR
		cap("Hair", 0.53, hs.Y * 0.3, hs.Y * 0.3, hair, Enum.Material.SmoothPlastic)
		wear(model, "Head", "HairBack", Vector3.new(hs.X * 0.95, hs.Y * 0.55, hs.Z * 0.2), CFrame.new(0, hs.Y * 0.1, hs.Z * 0.44), hair, Enum.Material.SmoothPlastic)
		wear(model, "Head", "Topknot", Vector3.new(hs.X * 0.3, hs.X * 0.3, hs.X * 0.3), CFrame.new(0, hs.Y * 0.58, hs.Z * 0.05), hair, Enum.Material.SmoothPlastic, Ball)
	elseif kind == "horns" then
		-- 뿔 둘 (마귀)
		local hornColor = look.hair or Color3.fromRGB(30, 25, 25)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "Head", "Horn", Vector3.new(hs.X * 0.12, hs.Y * 0.5, hs.X * 0.12), CFrame.new(x * hs.X * 0.3, hs.Y * 0.62, -hs.Z * 0.05) * CFrame.Angles(0, 0, -x * math.rad(25)), hornColor, Enum.Material.SmoothPlastic)
		end
	elseif kind == "wrap" then
		-- 천으로 머리 전체를 감았다 (눈만 드러난다)
		wear(model, "Head", "Wrap", Vector3.new(hs.X * 1.06, hs.Y * 1.04, hs.Z * 1.06), CFrame.new(0, hs.Y * 0.02, 0), cloth, Enum.Material.Fabric, Ball)
		for k = -1, 1 do
			cap("WrapBand", 0.54, hs.Y * 0.06, k * hs.Y * 0.22, cloth:Lerp(Color3.new(0, 0, 0), 0.2), Enum.Material.Fabric)
		end
	elseif kind == "golem" then
		cap("StoneCrown", 0.5, hs.Y * 0.2, hs.Y * 0.4, Color3.fromRGB(100, 96, 90), Enum.Material.Slate)
	end
	if look.crown then
		-- 관: 머리 위 금빛 테와 세 개의 뾰족한 장식
		cap("Crown", 0.5, hs.Y * 0.14, hs.Y * 0.62, look.crown, Enum.Material.Metal)
		for k = -1, 1 do
			wear(model, "Head", "CrownSpike", Vector3.new(hs.X * 0.08, hs.Y * 0.28, hs.X * 0.08), CFrame.new(k * hs.X * 0.22, hs.Y * 0.8, -hs.Z * 0.35), look.crown, Enum.Material.Metal)
		end
	end
	-- 복면 (코 아래를 가린다)
	if look.mask then
		wear(model, "Head", "Mask", Vector3.new(hs.X * 0.92, hs.Y * 0.38, hs.Z * 0.5), CFrame.new(0, -hs.Y * 0.24, -hs.Z * 0.3), look.mask)
	end
	-- 수염
	if look.beard then
		local bc = look.beard == "white" and WHITE_HAIR or (look.hair or DARK_HAIR)
		local long = look.beard ~= "stubble"
		wear(model, "Head", "Beard", Vector3.new(hs.X * 0.62, hs.Y * (long and 0.42 or 0.16), hs.Z * 0.22), CFrame.new(0, -hs.Y * (long and 0.5 or 0.38), -hs.Z * 0.42), bc, Enum.Material.SmoothPlastic)
	end
	face(model, head, look)
	-- 옷: 허리띠는 모두, 갑옷·도포는 정해진 적만
	-- 2.6판: 몸 크기에 맞춘다 (큰 보스의 갑옷·허리띠가 몸속에 파묻히던 것을 고쳤다)
	local ut, lt = sizeOf(model, "UpperTorso"), sizeOf(model, "LowerTorso")
	local K = ut.Y / 1.6
	wear(model, "LowerTorso", "Belt", Vector3.new(lt.X * 1.04, 0.32 * K, lt.Z * 1.1), CFrame.new(0, 0.05 * K, 0), Color3.fromRGB(55, 40, 28), Enum.Material.Fabric)
	wear(model, "LowerTorso", "Buckle", Vector3.new(0.35 * K, 0.3 * K, 0.08 * K), CFrame.new(0, 0.05 * K, -lt.Z * 0.56), Color3.fromRGB(200, 170, 90), Enum.Material.Metal)
	if look.armor then
		local metal = look.metal or IRON
		wear(model, "UpperTorso", "ChestPlate", Vector3.new(ut.X * 0.95, ut.Y * 0.75, 0.18 * K), CFrame.new(0, ut.Y * 0.1, -ut.Z * 0.55), metal, Enum.Material.Metal)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "UpperTorso", "Pauldron", Vector3.new(ut.X * 0.6, 0.42 * K, ut.Z * 1.25), CFrame.new(x * ut.X * 0.56, ut.Y * 0.44, 0) * CFrame.Angles(0, 0, -x * math.rad(15)), metal, Enum.Material.Metal)
			wear(model, "UpperTorso", "PauldronRim", Vector3.new(ut.X * 0.62, 0.1 * K, ut.Z * 1.28), CFrame.new(x * ut.X * 0.58, ut.Y * 0.36, 0) * CFrame.Angles(0, 0, -x * math.rad(15)), metal:Lerp(Color3.fromRGB(230, 190, 90), 0.5), Enum.Material.Metal)
		end
	end
	if look.robe then
		for _, z in ipairs({ -1, 1 }) do
			wear(model, "LowerTorso", "RobePanel", Vector3.new(lt.X * 1.02, 2.2 * K, 0.16 * K), CFrame.new(0, -1.25 * K, z * lt.Z * 0.55), look.robe)
		end
	end
	if look.wrap then
		wear(model, "UpperTorso", "WrapSash", Vector3.new(0.4 * K, ut.Y * 1.4, ut.Z * 1.1), CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(35)), Color3.fromRGB(215, 195, 150))
	end
	humanDetail(model, look, K)
	if isBoss then
		bossRegalia(model, look, typeId, false)
	end
	-- 돌·용암 몸: 살갗을 돌결로
	if look.stone then
		for _, d in ipairs(model:GetChildren()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and (d.Color == look.skin) then
				d.Material = Enum.Material.Slate
			end
		end
	end
end

local function dressMaster(model: Model, style: any)
	local robe = style.color:Lerp(Color3.new(0, 0, 0), 0.35)
	local trim = style.color2
	local head = model:FindFirstChild("Head") :: BasePart?
	local hs = head and head.Size or Vector3.new(1.2, 1.2, 1.2)
	-- 공통: 앞뒤로 갈라진 긴 도포, 금빛 어깨받이, 허리띠 끈, 등 망토
	for _, z in ipairs({ -1, 1 }) do
		wear(model, "LowerTorso", "RobePanel", Vector3.new(2.1, 2.4, 0.18), CFrame.new(0, -1.35, z * 0.55), robe)
		wear(model, "LowerTorso", "RobeTrim", Vector3.new(2.15, 0.25, 0.22), CFrame.new(0, -2.5, z * 0.55), trim, Enum.Material.SmoothPlastic)
	end
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "UpperTorso", "Pauldron", Vector3.new(1.25, 0.45, 1.35), CFrame.new(x * 1.15, 0.72, 0) * CFrame.Angles(0, 0, -x * math.rad(15)), GOLD, Enum.Material.Metal)
		wear(model, "LowerTorso", "SashTail", Vector3.new(0.3, 1.6, 0.1), CFrame.new(x * 0.35, -0.9, 0.62) * CFrame.Angles(math.rad(8), 0, x * math.rad(6)), trim)
	end
	wear(model, "UpperTorso", "Cape", Vector3.new(2.1, 3.6, 0.14), CFrame.new(0, -0.9, 0.62) * CFrame.Angles(math.rad(10), 0, 0), style.color)
	wear(model, "UpperTorso", "Collar", Vector3.new(1.4, 0.35, 1.15), CFrame.new(0, 0.85, -0.05), trim, Enum.Material.SmoothPlastic)

	local id = style.id
	local function beard(color: Color3)
		wear(model, "Head", "Beard", Vector3.new(hs.X * 0.55, hs.Y * 1.1, 0.35), CFrame.new(0, -hs.Y * 0.62, -hs.Z * 0.42), color)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "Head", "Mustache", Vector3.new(hs.X * 0.35, 0.12, 0.12), CFrame.new(x * hs.X * 0.2, -hs.Y * 0.12, -hs.Z * 0.52) * CFrame.Angles(0, 0, x * math.rad(-25)), color)
		end
	end
	if id == "taeheo" then
		-- 물빛 도인: 흰 수염과 상투
		beard(WHITE_HAIR)
		wear(model, "Head", "Topknot", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, hs.Y * 0.62, 0.05), WHITE_HAIR, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		wear(model, "Head", "Hairband", Vector3.new(hs.X * 1.03, 0.18, hs.Z * 1.03), CFrame.new(0, hs.Y * 0.28, 0), trim, Enum.Material.Neon)
	elseif id == "geumgang" then
		-- 금강 대사: 염주와 비스듬한 가사
		for k = 0, 13 do
			local a = k / 14 * math.pi * 2
			wear(model, "UpperTorso", "Bead", Vector3.new(0.32, 0.32, 0.32), CFrame.new(math.cos(a) * 0.62, 0.62 - math.abs(math.sin(a)) * 0.15, math.sin(a) * 0.55), Color3.fromRGB(110, 60, 30), Enum.Material.Wood, Enum.PartType.Ball)
		end
		wear(model, "UpperTorso", "Kasaya", Vector3.new(0.55, 2.6, 1.12), CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(35)), Color3.fromRGB(190, 50, 35))
		wear(model, "Head", "Urna", Vector3.new(0.15, 0.15, 0.1), CFrame.new(0, hs.Y * 0.22, -hs.Z * 0.5), GOLD, Enum.Material.Neon)
	elseif id == "maehwa" then
		-- 매화 선자: 긴 머리, 꽃 비녀, 넓은 소매
		wear(model, "Head", "LongHair", Vector3.new(hs.X * 1.05, hs.Y * 2.2, 0.35), CFrame.new(0, -hs.Y * 0.55, hs.Z * 0.5), Color3.fromRGB(25, 20, 25))
		wear(model, "Head", "HairTop", Vector3.new(hs.X * 1.08, hs.Y * 0.4, hs.Z * 1.08), CFrame.new(0, hs.Y * 0.4, 0.05), Color3.fromRGB(25, 20, 25))
		wear(model, "Head", "Hairpin", Vector3.new(0.5, 0.5, 0.5), CFrame.new(hs.X * 0.45, hs.Y * 0.5, 0.2), style.color, Enum.Material.Neon, Enum.PartType.Ball)
		for _, side in ipairs({ "Right", "Left" }) do
			wear(model, side .. "LowerArm", "Sleeve", Vector3.new(1.45, 1.1, 1.45), CFrame.new(0, -0.2, 0), trim)
		end
	elseif id == "cheonryong" then
		-- 용천 노조: 용뿔 관과 흰 수염
		beard(WHITE_HAIR)
		wear(model, "Head", "Crown", Vector3.new(hs.X * 0.9, 0.3, hs.Z * 0.6), CFrame.new(0, hs.Y * 0.55, 0), GOLD, Enum.Material.Metal)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "Head", "DragonHorn", Vector3.new(0.22, 1.3, 0.22), CFrame.new(x * hs.X * 0.35, hs.Y * 0.95, 0.15) * CFrame.Angles(math.rad(-25), 0, -x * math.rad(25)), GOLD, Enum.Material.Metal)
		end
		wear(model, "Head", "CrownGem", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, hs.Y * 0.6, -hs.Z * 0.32), style.color, Enum.Material.Neon, Enum.PartType.Ball)
	elseif id == "muyeong" then
		-- 무영객: 두건, 복면, 보랏빛 눈
		wear(model, "Head", "Hood", Vector3.new(hs.X * 1.12, hs.Y * 1.12, hs.Z * 1.0), CFrame.new(0, hs.Y * 0.06, hs.Z * 0.1), Color3.fromRGB(20, 18, 26))
		wear(model, "Head", "Mask", Vector3.new(hs.X * 0.9, hs.Y * 0.42, 0.12), CFrame.new(0, -hs.Y * 0.22, -hs.Z * 0.5), Color3.fromRGB(15, 12, 20))
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "Head", "ShadowEye", Vector3.new(0.22, 0.09, 0.05), CFrame.new(x * hs.X * 0.18, hs.Y * 0.08, -hs.Z * 0.52), Color3.fromRGB(190, 120, 255), Enum.Material.Neon)
		end
	elseif id == "byeokryeok" then
		-- 뇌정진군: 곤두선 머리, 번개 팔찌
		for k = -2, 2 do
			wear(model, "Head", "SpikeHair", Vector3.new(0.25, 0.8, 0.25), CFrame.new(k * hs.X * 0.18, hs.Y * 0.65, 0.1) * CFrame.Angles(math.rad(-15), 0, k * math.rad(-12)), Color3.fromRGB(255, 245, 200), Enum.Material.Neon)
		end
		wear(model, "Head", "Headband", Vector3.new(hs.X * 1.04, 0.2, hs.Z * 1.04), CFrame.new(0, hs.Y * 0.25, 0), style.color, Enum.Material.Neon)
		for _, side in ipairs({ "Right", "Left" }) do
			wear(model, side .. "LowerArm", "Bracer", Vector3.new(1.12, 0.5, 1.12), CFrame.new(0, -0.2, 0), style.color, Enum.Material.Neon)
			local hand = model:FindFirstChild(side .. "Hand")
			if hand and hand:IsA("BasePart") then
				local e = Instance.new("ParticleEmitter")
				e.Rate = 8
				e.Color = ColorSequence.new(Color3.fromRGB(255, 250, 180))
				e.LightEmission = 1
				e.Size = NumberSequence.new(0.25, 0)
				e.Lifetime = NumberRange.new(0.15, 0.3)
				e.Speed = NumberRange.new(4, 8)
				e.SpreadAngle = Vector2.new(180, 180)
				e.Parent = hand
			end
		end
	elseif id == "taecho" then
		-- 시원자: 얼굴 없는 흰 가면, 등 뒤의 빛의 고리 (해무리), 손목의 빛 띠
		wear(model, "Head", "BlankMask", Vector3.new(hs.X * 0.9, hs.Y * 0.8, 0.15), CFrame.new(0, 0, -hs.Z * 0.52), Color3.fromRGB(250, 250, 245), Enum.Material.SmoothPlastic)
		wear(model, "Head", "MaskLine", Vector3.new(hs.X * 0.5, 0.06, 0.05), CFrame.new(0, hs.Y * 0.05, -hs.Z * 0.6), style.color2, Enum.Material.Neon)
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			wear(model, "Head", "HaloRay", Vector3.new(0.15, 0.15, 0.9), CFrame.new(math.cos(a) * hs.X * 1.1, math.sin(a) * hs.Y * 1.1, hs.Z * 0.9) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, a), k % 3 == 0 and style.color2 or style.color, Enum.Material.Neon)
		end
		for _, side in ipairs({ "RightLowerArm", "LeftLowerArm" }) do
			wear(model, side, "LightBand", Vector3.new(1.05, 0.2, 1.05), CFrame.new(0, -0.3, 0), style.color2, Enum.Material.Neon)
		end
		local torso = model:FindFirstChild("UpperTorso")
		if torso and torso:IsA("BasePart") then
			local e = Instance.new("ParticleEmitter")
			e.Rate = 14
			e.Color = ColorSequence.new(style.color, style.color2)
			e.LightEmission = 1
			e.Size = NumberSequence.new(0.3, 0)
			e.Lifetime = NumberRange.new(1.5, 2.5)
			e.Speed = NumberRange.new(0.5, 1.5)
			e.SpreadAngle = Vector2.new(180, 180)
			e.Parent = torso
		end
	elseif id == "yeolhwa" then
		-- 염백: 불꽃 갈기 같은 붉은 머리띠, 어깨에서 타오르는 불, 팔목의 용암 띠
		wear(model, "Head", "FlameBand", Vector3.new(hs.X * 1.05, 0.35, hs.Z * 1.05), CFrame.new(0, hs.Y * 0.25, 0), style.color, Enum.Material.Neon)
		for _, side in ipairs({ "RightLowerArm", "LeftLowerArm" }) do
			wear(model, side, "LavaBand", Vector3.new(1.05, 0.3, 1.05), CFrame.new(0, -0.3, 0), style.color2, Enum.Material.Neon)
		end
		for _, x in ipairs({ -1, 1 }) do
			local pad = wear(model, "UpperTorso", "FlamePad", Vector3.new(1, 0.4, 1), CFrame.new(x * 1.1, 1, 0), Color3.fromRGB(60, 40, 35), Enum.Material.Basalt)
			if pad then
				local fire = Instance.new("Fire")
				fire.Size = 2.5
				fire.Heat = 6
				fire.Parent = pad
			end
		end
	elseif id == "yeonggeop" then
		-- 영겁노인: 등 뒤의 해시계 고리 (열두 눈금), 목에 건 모래시계, 은빛 수염
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			wear(model, "UpperTorso", "DialMark", Vector3.new(0.2, k % 3 == 0 and 0.9 or 0.5, 0.2), CFrame.new(math.cos(a) * 2.6, 1.3 + math.sin(a) * 2.6, 1.1) * CFrame.Angles(0, 0, a - math.pi / 2), k % 3 == 0 and style.color2 or style.color, Enum.Material.Neon)
		end
		wear(model, "UpperTorso", "DialHand", Vector3.new(0.2, 2.2, 0.2), CFrame.new(0, 2.2, 1.15), style.color2, Enum.Material.Neon)
		wear(model, "UpperTorso", "Hourglass", Vector3.new(0.6, 0.9, 0.6), CFrame.new(0, 0.2, -0.65), style.color2, Enum.Material.Glass)
		wear(model, "Head", "SilverBeard", Vector3.new(hs.X * 0.5, hs.Y * 1.4, 0.3), CFrame.new(0, -hs.Y * 0.9, -hs.Z * 0.45), Color3.fromRGB(225, 230, 240))
	elseif id == "changhae" then
		-- 창해옹: 파도빛 머리띠, 어깨에 걸친 조개 장식, 손목의 물빛 띠
		wear(model, "Head", "WaveBand", Vector3.new(hs.X * 1.04, 0.3, hs.Z * 1.04), CFrame.new(0, hs.Y * 0.25, 0), style.color2, Enum.Material.Neon)
		wear(model, "UpperTorso", "ShellPad", Vector3.new(1.4, 0.5, 1.2), CFrame.new(1.1, 0.95, 0) * CFrame.Angles(0, 0, math.rad(-20)), Color3.fromRGB(250, 235, 225), Enum.Material.SmoothPlastic)
		wear(model, "UpperTorso", "ShellPad2", Vector3.new(1.4, 0.5, 1.2), CFrame.new(-1.1, 0.95, 0) * CFrame.Angles(0, 0, math.rad(20)), Color3.fromRGB(250, 235, 225), Enum.Material.SmoothPlastic)
		for _, side in ipairs({ "RightLowerArm", "LeftLowerArm" }) do
			wear(model, side, "TideBand", Vector3.new(1.05, 0.25, 1.05), CFrame.new(0, -0.3, 0), style.color, Enum.Material.Neon)
		end
	elseif id == "ilwol" then
		-- 권존: 등 뒤에 금빛 해 바퀴, 왼 어깨 위에 은빛 초승달, 금과 은으로 반씩 물든 띠
		local sun = wear(model, "UpperTorso", "SunDisc", Vector3.new(0.2, 4.2, 4.2), CFrame.new(0, 1.4, 1.1) * CFrame.Angles(0, math.rad(90), 0), style.color, Enum.Material.Neon, Enum.PartType.Cylinder)
		if sun then
			sun.Transparency = 0.15
		end
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			wear(model, "UpperTorso", "SunRay", Vector3.new(0.18, 0.18, 1.3), CFrame.new(math.cos(a) * 2.75, 1.4 + math.sin(a) * 2.75, 1.15) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, a) * CFrame.Angles(0, math.rad(90), 0), style.color, Enum.Material.Neon)
		end
		for k = 0, 6 do
			local a = math.rad(-70 + k * 23)
			wear(model, "LeftUpperArm", "MoonArc", Vector3.new(0.25, 0.25, 0.7), CFrame.new(math.cos(a) * 1.1, 1.6 + math.sin(a) * 1.1, 0) * CFrame.Angles(0, 0, a), style.color2, Enum.Material.Neon)
		end
		wear(model, "LowerTorso", "SunSash", Vector3.new(1.05, 0.3, 1.05), CFrame.new(0.5, 0.1, 0), style.color, Enum.Material.Neon)
		wear(model, "LowerTorso", "MoonSash", Vector3.new(1.05, 0.3, 1.05), CFrame.new(-0.5, 0.1, 0), style.color2, Enum.Material.Neon)
		for _, side in ipairs({ "RightHand", "LeftHand" }) do
			local hand = model:FindFirstChild(side)
			if hand and hand:IsA("BasePart") then
				local e = Instance.new("ParticleEmitter")
				e.Rate = 12
				e.Color = ColorSequence.new(side == "RightHand" and style.color or style.color2)
				e.LightEmission = 1
				e.Size = NumberSequence.new(0.35, 0)
				e.Lifetime = NumberRange.new(0.4, 0.8)
				e.Speed = NumberRange.new(1, 3)
				e.SpreadAngle = Vector2.new(180, 180)
				e.Parent = hand
			end
		end
	elseif id == "gaecheon" then
		-- 무명 노인: 땅에 끌리는 흰 수염, 별을 박은 관, 둘레를 도는 별빛
		beard(WHITE_HAIR)
		wear(model, "Head", "LongBeard", Vector3.new(hs.X * 0.5, hs.Y * 2.4, 0.3), CFrame.new(0, -hs.Y * 1.5, -hs.Z * 0.45), WHITE_HAIR)
		wear(model, "Head", "StarCrown", Vector3.new(hs.X * 1.05, 0.25, hs.Z * 1.05), CFrame.new(0, hs.Y * 0.55, 0), Color3.fromRGB(230, 235, 255), Enum.Material.Neon)
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2
			wear(model, "Head", "CrownStar", Vector3.new(0.3, 0.3, 0.3), CFrame.new(math.cos(a) * hs.X * 0.5, hs.Y * 0.75, math.sin(a) * hs.Z * 0.5), style.color2, Enum.Material.Neon, Enum.PartType.Ball)
		end
		local headPart = model:FindFirstChild("Head")
		if headPart and headPart:IsA("BasePart") then
			local e = Instance.new("ParticleEmitter")
			e.Rate = 10
			e.Color = ColorSequence.new(style.color, style.color2)
			e.LightEmission = 1
			e.Size = NumberSequence.new(0.35, 0)
			e.Lifetime = NumberRange.new(1, 2)
			e.Speed = NumberRange.new(1, 3)
			e.SpreadAngle = Vector2.new(180, 180)
			e.Parent = headPart
		end
	elseif id == "pungsin" then
		-- 풍백: 바람에 날리는 긴 띠 두 줄과 깃털 머리 장식
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "UpperTorso", "WindScarf", Vector3.new(0.4, 0.15, 5), CFrame.new(x * 0.6, 0.7, 2.6) * CFrame.Angles(math.rad(-15), x * math.rad(12), 0), style.color2)
			wear(model, "Head", "Feather", Vector3.new(0.15, 1.6, 0.5), CFrame.new(x * hs.X * 0.4, hs.Y * 0.8, 0.2) * CFrame.Angles(0, 0, x * math.rad(-20)), style.color, Enum.Material.Neon)
		end
		wear(model, "Head", "WindBand", Vector3.new(hs.X * 1.04, 0.2, hs.Z * 1.04), CFrame.new(0, hs.Y * 0.28, 0), style.color, Enum.Material.Neon)
	elseif id == "chwi" then
		-- 취선옹: 넓은 삿갓, 허리의 술 호리병, 붉은 뺨
		beard(Color3.fromRGB(170, 170, 165))
		wear(model, "Head", "StrawHat", Vector3.new(0.25, 3.4, 3.4), CFrame.new(0, hs.Y * 0.62, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(205, 175, 110), Enum.Material.Fabric, Enum.PartType.Cylinder)
		wear(model, "Head", "HatTop", Vector3.new(1.2, 0.8, 1.2), CFrame.new(0, hs.Y * 0.85, 0), Color3.fromRGB(190, 160, 95), Enum.Material.Fabric, Enum.PartType.Ball)
		wear(model, "LowerTorso", "GourdLow", Vector3.new(0.9, 0.9, 0.9), CFrame.new(1.25, -0.4, 0.2), Color3.fromRGB(200, 120, 40), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		wear(model, "LowerTorso", "GourdTop", Vector3.new(0.6, 0.6, 0.6), CFrame.new(1.25, 0.25, 0.2), Color3.fromRGB(200, 120, 40), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "Head", "Cheek", Vector3.new(0.25, 0.14, 0.05), CFrame.new(x * hs.X * 0.28, -hs.Y * 0.05, -hs.Z * 0.51), Color3.fromRGB(240, 110, 110), Enum.Material.SmoothPlastic)
		end
	end
end

-- 청운 장로: 이야기를 들려주는 노인 (마을)
function Npc.spawnElder(onTalk: (Player) -> ())
	local mf = workspace:FindFirstChild("Masters") or Instance.new("Folder")
	mf.Name = "Masters"
	mf.Parent = workspace
	local robe = Color3.fromRGB(120, 95, 70)
	local model = body({ head = SKIN, torso = robe, arms = Color3.fromRGB(150, 125, 95), legs = Color3.fromRGB(80, 65, 50) }, 1.05)
	model.Name = "Elder"
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.WalkSpeed = 0
	end
	local head = model:FindFirstChild("Head") :: BasePart?
	local hs = head and head.Size or Vector3.new(1.2, 1.2, 1.2)
	wear(model, "Head", "Beard", Vector3.new(hs.X * 0.55, hs.Y * 1.2, 0.35), CFrame.new(0, -hs.Y * 0.65, -hs.Z * 0.42), Color3.fromRGB(240, 240, 235))
	wear(model, "Head", "Topknot", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, hs.Y * 0.62, 0.05), Color3.fromRGB(235, 235, 230), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	for _, z in ipairs({ -1, 1 }) do
		wear(model, "LowerTorso", "RobePanel", Vector3.new(2.1, 2.4, 0.18), CFrame.new(0, -1.35, z * 0.55), robe)
	end
	wear(model, "RightHand", "Staff", Vector3.new(0.3, 6.5, 0.3), CFrame.new(0, 1.2, 0), Color3.fromRGB(100, 70, 45), Enum.Material.Wood)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local up = (hum and hum.HipHeight or 2) + root.Size.Y / 2
	local at = Config.ELDER_AT
	model:PivotTo(CFrame.lookAt(at + Vector3.new(0, up, 0), at + Vector3.new(0, up, 10)))
	root.Anchored = true
	model:SetAttribute("NPC", true)
	model:SetAttribute("Master", true)
	model:SetAttribute("Label", "청운 장로")
	if head then
		masterTag(head, "청운 장로", { icon = "📜", name = "이야기 (T)", color = Color3.fromRGB(255, 225, 150), elder = true })
	end
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "Elder"
	pp.ActionText = "이야기"
	pp.ObjectText = "청운 장로"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp.KeyboardKeyCode = Enum.KeyCode.T
	pp.Parent = root
	pp.Triggered:Connect(onTalk)
	model.Parent = mf
end

function Npc.spawnMasters(onTrigger: (Player, string) -> ())
	local mf = Instance.new("Folder")
	mf.Name = "Masters"
	mf.Parent = workspace
	for _, style in ipairs(Config.Styles) do
		local info = Config.MASTERS[style.id]
		if info then
			local ok, err = pcall(function()
				local s = 1.2
				local model = body({ head = SKIN, torso = style.color:Lerp(Color3.new(1, 1, 1), 0.1), arms = style.color:Lerp(Color3.new(1, 1, 1), 0.25), legs = style.color:Lerp(Color3.new(0, 0, 0), 0.55) }, s)
				model.Name = "Master_" .. style.id
				local hum = model:FindFirstChildOfClass("Humanoid")
				local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
				if hum then
					hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					hum.WalkSpeed = 0
					hum.JumpPower = 0
				end
				-- 허리띠 (권법의 둘째 빛깔)
				local lower = model:FindFirstChild("LowerTorso")
				if lower and lower:IsA("BasePart") then
					local sash = Instance.new("Part")
					sash.Name = "Sash"
					sash.Size = Vector3.new(lower.Size.X * 1.08, 0.35, lower.Size.Z * 1.15)
					sash.Color = style.color2
					sash.Material = Enum.Material.Fabric
					sash.CanCollide = false
					sash.CanQuery = false
					sash.Massless = true
					sash.CFrame = lower.CFrame * CFrame.new(0, 0.1, 0)
					sash.Parent = model
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = lower
					weld.Part1 = sash
					weld.Parent = sash
				end
				pcall(dressMaster, model, style)
				local up = (hum and hum.HipHeight or 2 * s) + root.Size.Y / 2
				local at = info.at
				local face = Vector3.new(0, at.Y, 0) - at
				face = Vector3.new(face.X, 0, face.Z)
				local pos = at + Vector3.new(0, up, 0)
				model:PivotTo(CFrame.lookAt(pos, pos + (face.Magnitude > 1 and face.Unit or Vector3.new(0, 0, 1))))
				root.Anchored = true
				model:SetAttribute("NPC", true)
				model:SetAttribute("Master", true)
				model:SetAttribute("Awaken", 2)
				model:SetAttribute("Quote", info.quote)
				-- 발밑의 빛나는 진
				for i, r in ipairs({ 5, 3.2 }) do
					local sig = Instance.new("Part")
					sig.Name = "MasterSigil"
					sig.Anchored = true
					sig.CanCollide = false
					sig.CanQuery = false
					sig.Shape = Enum.PartType.Cylinder
					sig.Size = Vector3.new(0.1, r * 2, r * 2)
					sig.CFrame = CFrame.new(at + Vector3.new(0, 0.08 + i * 0.02, 0)) * CFrame.Angles(0, 0, math.rad(90))
					sig.Color = i == 1 and style.color or style.color2
					sig.Material = Enum.Material.Neon
					sig.Transparency = i == 1 and 0.55 or 0.7
					sig.Parent = mf
				end
				model:SetAttribute("Style", style.id)
				model:SetAttribute("Label", info.name)
				local head = model:FindFirstChild("Head")
				if head and head:IsA("BasePart") then
					masterTag(head, info.name, style)
				end
				local pp = Instance.new("ProximityPrompt")
				pp.Name = "Master"
				pp.ActionText = "권법 배우기"
				pp.ObjectText = info.name
				pp.HoldDuration = 0
				pp.MaxActivationDistance = 16
				pp.RequiresLineOfSight = false
				pp.KeyboardKeyCode = Enum.KeyCode.T
				pp.Parent = root
				pp.Triggered:Connect(function(player: Player)
					onTrigger(player, style.id)
				end)
				model.Parent = mf
			end)
			if not ok then
				warn("[권왕] 사부 만들기 오류:", style.id, err)
			end
		end
	end
end

-- 싸움 없이 치운다 (시험이 끝났을 때)
function Npc.despawn(f: any)
	for i, e in ipairs(Npc.list) do
		if e.f == f then
			table.remove(Npc.list, i)
			for player in pairs(e.engaged) do
				Push:FireClient(player, "boss", nil)
			end
			break
		end
	end
	Combat.unregister(f.model)
	f.model:Destroy()
end

-- 쓰러진 사람: 보스와 맞붙은 기록을 지우고 체력 막대를 걷는다
function Npc.forget(player: Player)
	for _, e in ipairs(Npc.list) do
		e.engaged[player] = nil
		if e.target and e.target.player == player then
			e.target = nil
		end
	end
	Push:FireClient(player, "boss", nil)
end

function Npc.find(model: Model): Enemy?
	for _, e in ipairs(Npc.list) do
		if e.f.model == model then
			return e
		end
	end
	return nil
end

-- 쓰러진 적: 잠시 뒤 치우고, 정해진 시간 뒤 다시 나타난다
function Npc.onDeath(f: any)
	for i, e in ipairs(Npc.list) do
		if e.f == f then
			table.remove(Npc.list, i)
			for player in pairs(e.engaged) do
				Push:FireClient(player, "boss", nil)
			end
			task.delay(2.5, function()
				Combat.unregister(f.model)
				f.model:Destroy()
			end)
			local wait = e.kind == "boss" and (e.def.respawn or 120) or Config.ENEMY_RESPAWN
			if e.region == "simma" or e.region == "trial" or e.region == "summon" or e.region == "test" then
				return -- 심마는 다시 나타나지 않는다
			end
			task.delay(wait, function()
				local ok, err = pcall(Npc.spawn, e.typeId, e.kind == "boss", e.home, e.region)
				if not ok then
					warn("[권왕] 적 다시 만들기 오류:", e.typeId, err)
				end
			end)
			return
		end
	end
end

------------------------------------------------------------------------
-- 생각하기 (0.1초마다)
------------------------------------------------------------------------
-- 2.1판: 높이가 크게 다르면 (지상과 천상) 아주 먼 것으로 친다. 천상의 적이 바로 아래 땅의 사람을 쫓지 않게
local function flatDist(a: Vector3, b: Vector3): number
	if math.abs(a.Y - b.Y) > 600 then
		return math.huge
	end
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function inSafe(pos: Vector3): boolean
	return Config.inSafe(pos)
end

local function faceTo(e: Enemy, pos: Vector3)
	local root = e.f.root
	local p = root.Position
	local dir = Vector3.new(pos.X - p.X, 0, pos.Z - p.Z)
	if dir.Magnitude > 0.1 then
		root.CFrame = CFrame.lookAt(p, p + dir)
	end
end

local function nearestPlayer(e: Enemy, radius: number): any?
	local best, bestD = nil, radius
	local pos = e.f.root.Position
	for _, player in ipairs(Players:GetPlayers()) do
		local pf = Combat.fighterOfPlayer(player)
		if pf and not pf.dead and not inSafe(pf.root.Position) then
			local d = flatDist(pf.root.Position, pos)
			if d < bestD then
				best, bestD = pf, d
			end
		end
	end
	return best
end

local function attack(e: Enemy, move: any)
	local f = e.f
	local tgt = e.target
	if not tgt then
		return
	end
	e.seq += 1
	local speed = (e.phase2 and e.def.phase2 and e.def.phase2.speed) or 1
	faceTo(e, tgt.root.Position)
	local act = Combat.begin(f, move, move.id, e.seq, { enemy = true, speed = speed, align = move.windup / speed })
	f.hum:MoveTo(f.root.Position)
	-- 2.1판: 흘리기 시험의 사부는 주먹이 닿기 직전을 머리 위의 F로 알려 준다
	if (f :: any).deflectCue and tgt.player and move.hits[1] then
		Push:FireClient(tgt.player, "deflectCue", { m = f.model, t = move.hits[1].t / speed })
	end
	-- 순간이동 (보스): 멈칫이 끝나기 직전 상대 등 뒤로
	if move.teleport then
		task.delay(math.max(0, move.windup / speed - 0.12), function()
			if f.act == act and not f.dead and not tgt.dead then
				local behind = tgt.root.Position - Combat.look(tgt) * 4
				f.root.CFrame = CFrame.lookAt(behind, Vector3.new(tgt.root.Position.X, behind.Y, tgt.root.Position.Z))
				Push:FireAllClients("blink", f.model, behind)
			end
		end)
	end
	-- 앞으로 내딛기
	if move.lunge then
		task.delay(math.max(0, move.windup / speed - 0.08), function()
			if f.act == act and not f.dead then
				if e.target then
					faceTo(e, e.target.root.Position)
				end
				f.root.AssemblyLinearVelocity = Combat.look(f) * (move.lunge / 0.22) + Vector3.new(0, 2, 0)
			end
		end)
	end
	for i, h in ipairs(move.hits) do
		task.delay(h.t / speed, function()
			if f.act ~= act or f.dead then
				return
			end
			f.lastSwingAt = os.clock()
			-- 큰 보스는 팔이 길다
			local hh = h
			if e.def.reach then
				hh = table.clone(h)
				hh.range *= e.def.reach
				hh.radius *= e.def.reach
			end
			for _, victim in ipairs(Combat.query(f, hh)) do
				Combat.applyHit(f, victim, hh, { move = move, act = act, unblockable = move.unblockable, slotKey = i })
			end
		end)
	end
	local recover = (0.55 + math.random() * 0.7) / speed
	if e.kind == "boss" then
		recover *= 0.7
	end
	e.nextAttack = os.clock() + act.dur + recover
	e.attackingUntil = os.clock() + act.dur + 0.25
end

------------------------------------------------------------------------
-- 보스 패턴: 바닥에 붉은 표시가 먼저 뜨고, 잠시 뒤 터진다 (대시로 피하거나 표시 밖으로)
--   quake  보스 둘레가 울린다            leap   표적 자리로 뛰어올라 내려찍는다
--   charge 표적 쪽으로 한 줄 돌진         rain   표적 둘레 여러 곳에 벼락·얼음·피
--   donut  보스에서 떨어진 고리가 터진다 (보스 품으로 파고들면 안전)
--   summon 부하를 부른다
------------------------------------------------------------------------
local BOSS_RED = Color3.fromRGB(255, 60, 40)
local function playersNear(f: any, center: Vector3, r0: number, r1: number): { any }
	local out = {}
	for _, o in pairs(Combat.fighters) do
		if Combat.hostile(f, o) and not o.dead then
			local d = Vector3.new(o.root.Position.X - center.X, 0, o.root.Position.Z - center.Z).Magnitude
			if d >= r0 and d <= r1 then
				table.insert(out, o)
			end
		end
	end
	return out
end

local function bossHit(e: Enemy, victims: { any }, h: any, name: string)
	for _, o in ipairs(victims) do
		Combat.applyHit(e.f, o, h, { move = { name = name }, unblockable = true })
	end
end

local function telegraph(at: Vector3, radius: number, time: number, color: Color3?)
	Push:FireAllClients("skillfx", { kind = "telegraph", at = at, radius = radius, time = time, color = color or BOSS_RED })
end

local function runPattern(e: Enemy, tgt: any, pat: any, phase: number)
	local f = e.f
	local sp = 1 + 0.15 * (phase - 1) -- 단계가 오를수록 빨라진다
	local warn = (pat.warn or 1.0) / sp
	local h = pat.hit
	local kind = pat.kind
	-- 몸짓 (멈칫하며 기를 모은다)
	local act = Combat.begin(f, { id = "bp_" .. kind, name = pat.name, pose = pat.pose or "w_overhead", dur = warn + 0.5, hits = {} }, "pat", e.seq + 1, { enemy = true })
	e.seq += 1
	f.hum:MoveTo(f.root.Position)
	faceTo(e, tgt.root.Position)
	Push:FireAllClients("bossCall", { m = f.model, name = pat.name })
	local function later(sec: number, fn: () -> ())
		task.delay(sec, function()
			if not f.dead and f.root.Parent then
				fn()
			end
		end)
	end
	if kind == "quake" then
		local at = f.root.Position
		telegraph(at, pat.radius, warn)
		later(warn, function()
			Push:FireAllClients("skillfx", { kind = "wave", at = at, radius = pat.radius, color = BOSS_RED })
			bossHit(e, playersNear(f, at, 0, pat.radius), h, pat.name)
		end)
	elseif kind == "leap" then
		local at = tgt.root.Position
		telegraph(at, pat.radius, warn)
		later(warn * 0.55, function()
			-- 뛰어오른다 (보이게 높이)
			f.root.AssemblyLinearVelocity = Vector3.new(0, 70, 0)
		end)
		later(warn, function()
			f.root.CFrame = CFrame.new(at + Vector3.new(0, 4 * (e.def.scale or 1), 0)) * (f.root.CFrame - f.root.Position)
			Push:FireAllClients("skillfx", { kind = "drop", at = at, radius = pat.radius, color = BOSS_RED })
			bossHit(e, playersNear(f, at, 0, pat.radius), h, pat.name)
		end)
	elseif kind == "charge" then
		local from = f.root.Position
		local dir = Vector3.new(tgt.root.Position.X - from.X, 0, tgt.root.Position.Z - from.Z)
		dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 0, -1)
		local len = pat.length or 40
		local times = pat.times or 1
		for k = 0, times - 1 do
			later(k * (warn + 0.35), function()
				local start = f.root.Position
				if k > 0 and e.target then
					local d2 = Vector3.new(e.target.root.Position.X - start.X, 0, e.target.root.Position.Z - start.Z)
					dir = d2.Magnitude > 0.1 and d2.Unit or dir
				end
				Push:FireAllClients("skillfx", { kind = "lineTele", from = start, to = start + dir * len, width = pat.width or 8, time = warn, color = BOSS_RED })
				later(warn, function()
					local p0 = f.root.Position
					f.root.CFrame = CFrame.lookAt(p0, p0 + dir)
					f.root.AssemblyLinearVelocity = dir * (len / 0.35)
					Push:FireAllClients("afterimage", f.model)
					local hitSet = {}
					for s = 1, 5 do
						later(s * 0.07, function()
							for _, o in ipairs(playersNear(f, f.root.Position, 0, (pat.width or 8) * 0.6 + 2)) do
								if not hitSet[o] then
									hitSet[o] = true
									bossHit(e, { o }, h, pat.name)
								end
							end
						end)
					end
				end)
			end)
		end
	elseif kind == "rain" then
		local n = (pat.count or 5) + (phase - 1) * 2
		for i = 1, n do
			local base = tgt.root.Position
			local a = math.random() * math.pi * 2
			local at = i == 1 and base or base + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(4, pat.spread or 18)
			later((i - 1) * 0.12, function()
				telegraph(at, pat.radius, warn, pat.color)
				later(warn, function()
					Push:FireAllClients("skillfx", { kind = "strike", at = at, radius = pat.radius, fx = pat.fx or "lightning", color = pat.color or BOSS_RED })
					bossHit(e, playersNear(f, at, 0, pat.radius), h, pat.name)
				end)
			end)
		end
	elseif kind == "donut" then
		local at = f.root.Position
		Push:FireAllClients("skillfx", { kind = "donut", at = at, inner = pat.inner, outer = pat.outer, time = warn, color = BOSS_RED })
		later(warn, function()
			Push:FireAllClients("skillfx", { kind = "wave", at = at, radius = pat.outer, color = BOSS_RED })
			bossHit(e, playersNear(f, at, pat.inner, pat.outer), h, pat.name)
		end)
	elseif kind == "summon" then
		local alive = 0
		for _, o in ipairs(Npc.list) do
			if (o :: any).summoner == e and not o.f.dead then
				alive += 1
			end
		end
		for i = 1, math.max(0, math.min(pat.count or 3, (pat.max or 6) - alive)) do
			local a = i / 3 * math.pi * 2
			local at = f.root.Position + Vector3.new(math.cos(a) * 10, 0, math.sin(a) * 10)
			Push:FireAllClients("skillfx", { kind = "mark", at = at, radius = 4, time = warn, color = BOSS_RED })
			later(warn, function()
				local m = Npc.spawn(pat.enemy, false, at, "summon")
				if m then
					(m :: any).summoner = e
					m.target = tgt
				end
			end)
		end
	end
	local cd = (pat.cd or 7) / sp
	e.nextPattern = os.clock() + warn + cd
	e.nextAttack = os.clock() + warn + 0.8
	e.attackingUntil = os.clock() + warn + 0.5
	local _ = act
end

-- 보스 단계: 체력 2/3, 1/3에서 다음 단계로 (빨라지고 패턴이 늘어난다)
local function bossPhase(e: Enemy): number
	local f = e.f
	local r = f.hp / math.max(1, f.maxHp)
	local ph = r > 0.66 and 1 or (r > 0.33 and 2 or 3)
	local old = (e :: any).phase or 1
	if ph > old then
		(e :: any).phase = ph
		f.model:SetAttribute("BossPhase", ph)
		f.walk = e.def.speed * Config.BOSS_SPEED * (1 + Config.BOSS_PHASE_SPEED * (ph - 1))
		Push:FireAllClients("bossPhase", f.model, e.def.name, ph)
		-- 단계가 바뀌면 곧바로 큰 패턴
		e.nextPattern = os.clock() + 0.6
	end
	return ph
end

local function think(e: Enemy, t: number)
	local f = e.f
	if f.dead or not f.root.Parent then
		return
	end
	local pos = f.root.Position
	-- 수련 목인: 맞은 피해만 센다. 3초 동안 안 맞으면 다시 가득
	if (e.def :: any).dummy then
		local ea = e :: any
		ea.hits = ea.hits or {}
		local lost = (ea.lastHp or f.maxHp) - f.hp
		if lost > 0 then
			table.insert(ea.hits, { t = t, d = lost })
			ea.best = math.max(ea.best or 0, lost)
			ea.lastHitAt = t
		end
		while ea.hits[1] and t - ea.hits[1].t > 5 do
			table.remove(ea.hits, 1)
		end
		local sum = 0
		for _, h in ipairs(ea.hits) do
			sum += h.d
		end
		local span = #ea.hits > 0 and math.max(1, t - ea.hits[1].t) or 1
		f.model:SetAttribute("Dps", math.floor(sum / span + 0.5))
		f.model:SetAttribute("Best", math.floor((ea.best or 0) + 0.5))
		if t - (ea.lastHitAt or 0) > 3 and f.hp < f.maxHp then
			f.hp = f.maxHp
			ea.best = 0
			Combat.sync(f)
		end
		ea.lastHp = f.hp
		-- 밀려나도 1초 뒤 제자리로
		ea.spot = ea.spot or pos
		if flatDist(pos, ea.spot) > 4 and t - (ea.lastHitAt or 0) > 1 then
			f.model:PivotTo(CFrame.new(ea.spot) * f.root.CFrame.Rotation)
		end
		f.hum:MoveTo(f.root.Position)
		return
	end
	-- 버티기에 들어가면 곧바로 되받아친다
	if (f :: any).retaliate then
		(f :: any).retaliate = nil
		e.nextAttack = math.min(e.nextAttack, t)
	end
	-- 2.1판: 천상의 섬에서 떨어져 땅까지 내려온 적 (또는 그 반대)은 곧바로 제자리로 돌아간다
	if math.abs(pos.Y - e.home.Y) > 600 then
		e.target = nil
		f.root.AssemblyLinearVelocity = Vector3.zero
		f.model:PivotTo(CFrame.new(e.home + Vector3.new(0, 3, 0)) * f.root.CFrame.Rotation)
		return
	end
	-- 근처에 사람이 없으면 쉰다
	local anyone = false
	for _, player in ipairs(Players:GetPlayers()) do
		local pf = Combat.fighterOfPlayer(player)
		if pf and flatDist(pf.root.Position, pos) < (e.kind == "boss" and Config.BOSS_CHASE + 30 or Config.ENEMY_ACTIVE_RANGE) then
			anyone = true
			break
		end
	end
	if not anyone then
		e.target = nil
		return
	end
	-- 너무 멀리 끌려 나오면 집으로 (보스는 훨씬 멀리까지 쫓아온다)
	if flatDist(pos, e.home) > (e.kind == "boss" and Config.BOSS_LEASH or 150) then
		e.target = nil
	end
	if Combat.stunned(f) then
		f.hum:MoveTo(pos)
		return
	end
	if f.guarding and t > e.guardUntil then
		f.guarding = false
		f.model:SetAttribute("Guard", false)
	end
	-- 보스 단계 (세 단계)
	local phase = 1
	if e.kind == "boss" then
		phase = bossPhase(e)
		e.phase2 = phase >= 2
	end
	if Combat.busy(f) then
		if e.target and not (f.act and f.act.move.lunge) then
			faceTo(e, e.target.root.Position)
		end
		return
	end
	-- 상대 고르기
	local tgt = e.target
	-- 사부의 분신은 시험을 청한 사람하고만 겨룬다 (사부의 자리 안에서도)
	local owner = (f :: any).trialOwner
	if owner then
		tgt = Combat.fighterOfPlayer(owner)
	end
	if tgt and (tgt.dead or not tgt.root.Parent or (inSafe(tgt.root.Position) and not e.def.duel) or flatDist(tgt.root.Position, pos) > (e.kind == "boss" and math.max(e.def.aggro * 1.6, Config.BOSS_CHASE) or e.def.aggro * 1.6)) then
		tgt = nil
	end
	if not tgt and not owner then
		tgt = nearestPlayer(e, e.def.aggro)
	end
	-- 처음 상대를 잡으면 둘레의 동료도 함께 덤빈다
	if tgt and not e.target then
		for _, o in ipairs(Npc.list) do
			if o ~= e and not o.target and not o.f.dead and flatDist(o.f.root.Position, pos) < 45 then
				o.target = tgt
			end
		end
	end
	e.target = tgt
	if not tgt then
		if flatDist(pos, e.home) > 10 then
			f.hum:MoveTo(e.home)
		end
		return
	end
	-- 보스: 싸우는 사람 화면에 체력 막대. 멀어지거나 쓰러진 사람의 막대는 걷는다 (다시 맞붙으면 다시 뜬다)
	if e.kind == "boss" then
		for p in pairs(e.engaged) do
			local pf = Combat.fighterOfPlayer(p)
			if not pf or pf.dead or flatDist(pf.root.Position, pos) > 170 then
				e.engaged[p] = nil
				Push:FireClient(p, "boss", nil)
			end
		end
	end
	if e.kind == "boss" and tgt.player and not e.engaged[tgt.player] then
		e.engaged[tgt.player] = true
		Push:FireClient(tgt.player, "boss", f.model)
		-- 2.3판: 후반 보스는 훨씬 센 상대를 만나면 힘을 끌어올린다 (상대 전투력의 LATE_BOSS_MATCH배까지). 한 방에 쓰러지지도, 손도 못 대는 일도 없게
		local fa = f :: any
		local want = ((tgt :: any).power or 0) * Config.LATE_BOSS_MATCH
		if e.def.late and want > (fa.power or 0) then
			local k = want / math.max(1, fa.power or 1)
			fa.basePower = fa.basePower or fa.power
			local frac = f.hp / math.max(1, f.maxHp)
			f.maxHp = math.floor(f.maxHp * k)
			f.hp = math.floor(f.maxHp * frac)
			f.dmgMult *= k
			f.postureMax = math.floor(f.postureMax * math.sqrt(k))
			fa.power = math.floor(want)
			f.model:SetAttribute("Power", fa.power)
			Combat.sync(f)
			Push:FireAllClients("bossCall", { m = f.model, name = "힘을 끌어올린다!" })
		end
	end
	local d = flatDist(tgt.root.Position, pos)
	-- 보스 패턴 (단계마다 쓸 수 있는 것이 늘어난다)
	if e.kind == "boss" and e.def.patterns then
		local ea = e :: any
		if not ea.nextPattern then
			ea.nextPattern = t + 3
		end
		if t >= ea.nextPattern and d < 50 then
			local pool = {}
			for _, pat in ipairs(e.def.patterns) do
				if (pat.phase or 1) <= phase then
					table.insert(pool, pat)
				end
			end
			if #pool > 0 then
				runPattern(e, tgt, pool[math.random(1, #pool)], phase)
				return
			end
		end
	end
	-- 상대가 막 치기 시작하면 가끔 막는다 (보스는 더 자주)
	local tact = tgt.act
	if tact and t - tact.start < 0.18 and d < 11 and not f.guarding and not (tact :: any).perfect then
		-- 마구 누르는 연타는 읽혀서 막히고 흘려진다. 박자를 맞춘 일격(連)은 읽지 못한다
		local sloppy = (tgt :: any).sloppy or 0
		-- 초반 적 (단계 4 이하, 정예 아님)은 덜 막는다
		local early = e.kind ~= "boss" and not e.def.elite and not e.def.duel and e.level <= 4
		local chance = (e.kind == "boss" and 0.4 or (early and 0.1 or 0.22)) + math.min(early and 0.2 or 0.5, sloppy * (early and 0.05 or 0.09))
		if math.random() < chance then
			f.guarding = true
			f.guardStart = t
			e.guardUntil = t + 0.7
			f.model:SetAttribute("Guard", true)
			faceTo(e, tgt.root.Position)
			f.hum:MoveTo(pos)
			return
		end
	end
	if f.guarding then
		faceTo(e, tgt.root.Position)
		return
	end
	-- 공격 사이엔 자주 막기 자세를 잡는다: 마구 치면 막히고, 막 잡은 막기엔 흘려진다
	-- (상대가 칠 때를 기다려 흘리고 파고들거나, 균형을 깨거나, 뒤를 잡아야 한다)
	local earlyIdle = e.kind ~= "boss" and not e.def.elite and not e.def.duel and e.level <= 4
	if d < 8 and t < e.nextAttack and math.random() < (e.kind == "boss" and 0.22 or (e.def.elite and 0.18 or (earlyIdle and 0.05 or 0.12))) then
		f.guarding = true
		f.guardStart = t
		e.guardUntil = t + 0.6 + math.random() * 0.7
		f.model:SetAttribute("Guard", true)
		faceTo(e, tgt.root.Position)
		f.hum:MoveTo(pos)
		return
	end
	-- 한 사람을 한꺼번에 치는 적은 둘까지: 나머지는 둘레를 돌며 차례를 기다린다 (보스와 분신은 예외)
	local waiting = false
	if e.kind ~= "boss" and not e.def.duel then
		local busy = 0
		for _, o in ipairs(Npc.list) do
			if o ~= e and o.target == tgt and not o.f.dead and (o.attackingUntil > t or o.kind == "boss") and flatDist(o.f.root.Position, tgt.root.Position) < 20 then
				busy += 1
			end
		end
		waiting = busy >= Config.MAX_ATTACKERS
	end
	if waiting and t >= e.nextAttack then
		e.nextAttack = t + 0.3 + math.random() * 0.5
	end
	-- 칠 수 있으면 친다
	if t >= e.nextAttack then
		local weak = e.kind ~= "boss" and not e.def.elite and not e.def.duel and e.level <= Config.NO_RED_LEVEL
		local moves = {}
		for _, m in ipairs(e.def.moves) do
			-- 약한 적은 붉은 공격(막을 수 없는 공격)을 쓰지 않는다
			if d <= m.range * (e.def.reach or 1) + 1 and not (weak and m.unblockable) then
				table.insert(moves, m)
			end
		end
		if e.phase2 and e.def.phase2 and e.def.phase2.extra and d <= e.def.phase2.extra.range + 1 then
			table.insert(moves, e.def.phase2.extra)
		end
		if #moves > 0 then
			attack(e, moves[math.random(1, #moves)])
			return
		end
	end
	-- 거리 맞추기: 멀면 다가가고, 가까우면 옆으로 돈다
	local keep = (e.def.keep or 5) + (waiting and 5 or 0)
	local to = tgt.root.Position - pos
	local flatTo = Vector3.new(to.X, 0, to.Z)
	local dir = flatTo.Magnitude > 0.1 and flatTo.Unit or Vector3.new(0, 0, 1)
	-- 동료끼리 겹치지 않게 서로 밀어낸다 (한 덩어리로 뭉치지 않고 둘레로 퍼진다)
	local apart = Vector3.zero
	for _, o in ipairs(Npc.list) do
		if o ~= e and not o.f.dead and o.f.root.Parent then
			local off = pos - o.f.root.Position
			local od = Vector3.new(off.X, 0, off.Z).Magnitude
			if od < 6 and od > 0.05 then
				apart += Vector3.new(off.X, 0, off.Z).Unit * (6 - od)
			end
		end
	end
	if d > keep + 2 then
		f.hum:MoveTo(tgt.root.Position - dir * keep + apart)
	elseif d < keep - 2 then
		f.hum:MoveTo(pos - dir * 4 + apart)
	else
		if math.random() < 0.05 then
			e.strafe = -e.strafe
		end
		local side = Vector3.new(-dir.Z, 0, dir.X) * e.strafe
		f.hum:MoveTo(pos + side * 5 + apart)
		faceTo(e, tgt.root.Position)
	end
end

function Npc.start()
	task.spawn(function()
		while true do
			task.wait(0.1)
			local t = os.clock()
			for _, e in ipairs(Npc.list) do
				local ok, err = pcall(think, e, t)
				if not ok then
					warn("[권왕] 적 생각 오류:", err)
				end
			end
		end
	end)
end

return Npc
