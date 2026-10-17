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
}

Npc.list = {} :: { Enemy }
local folder: Folder
local Push: RemoteEvent
local SKIN = Color3.fromRGB(234, 184, 146)

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
local function body(colors: { head: Color3, torso: Color3, arms: Color3, legs: Color3 }, s: number): Model
	local ok, model = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = colors.head
		desc.LeftArmColor = colors.arms
		desc.RightArmColor = colors.arms
		desc.TorsoColor = colors.torso
		desc.LeftLegColor = colors.legs
		desc.RightLegColor = colors.legs
		desc.HeightScale = s
		desc.WidthScale = s
		desc.DepthScale = s
		desc.HeadScale = s
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

local function buildRig(def: any, label: string, isBoss: boolean): Model
	local s = def.scale or 1
	local model = body({ head = SKIN, torso = def.shirt, arms = SKIN, legs = def.pants }, s)
	model.Name = label
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.BreakJointsOnDeath = false
		hum.MaxHealth = 1e9
		hum.Health = 1e9
		hum.WalkSpeed = def.speed
	end
	-- 이마 띠 (적은 붉은, 보스는 검은 금빛)
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local band = Instance.new("Part")
		band.Name = "Headband"
		band.Size = Vector3.new(head.Size.X * 1.05, head.Size.Y * 0.18, head.Size.Z * 1.05)
		band.Color = isBoss and Color3.fromRGB(30, 25, 20) or Color3.fromRGB(170, 30, 30)
		band.Material = isBoss and Enum.Material.Foil or Enum.Material.Fabric
		band.CanCollide = false
		band.CanQuery = false
		band.Massless = true
		band.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.18, 0)
		band.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = band
		weld.Parent = band
	end
	attachWeapon(model, def.weapon)
	model:SetAttribute("NPC", true)
	model:SetAttribute("Boss", isBoss)
	model:SetAttribute("Label", label)
	model:SetAttribute("Weapon", def.weapon)
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
	local model = buildRig(def, def.name, isBoss)
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
	local f = Combat.register(model, {
		npc = def,
		name = def.name,
		hp = math.floor(def.hp * (1 + 0.28 * (lv - 1))),
		postureMax = math.floor(def.posture * (1 + 0.1 * (lv - 1))),
		walk = def.speed,
		style = def.style or "",
		dmgMult = Config.ENEMY_DMG * (1 + 0.18 * (lv - 1)),
	})
	;(f :: any).rewardMult = 1 + 0.25 * (lv - 1)
	;(f :: any).typeId = typeId
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
	for i, line in ipairs({ { (style.elder and "" or "사부 · ") .. name, Color3.fromRGB(255, 225, 150), 0.52 }, { style.icon .. " " .. style.name .. (style.elder and "" or "  (T)"), style.color, 0.48 } }) do
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
			break
		end
	end
	Combat.unregister(f.model)
	f.model:Destroy()
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
			if e.region == "simma" or e.region == "trial" then
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
local function flatDist(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function inSafe(pos: Vector3): boolean
	for _, r in ipairs(Config.Regions) do
		if r.safe and math.abs(pos.X - r.center.X) <= r.size.X / 2 and math.abs(pos.Z - r.center.Z) <= r.size.Z / 2 then
			return true
		end
	end
	return false
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
			for _, victim in ipairs(Combat.query(f, h)) do
				Combat.applyHit(f, victim, h, { move = move, act = act, unblockable = move.unblockable, slotKey = i })
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

local function think(e: Enemy, t: number)
	local f = e.f
	if f.dead or not f.root.Parent then
		return
	end
	local pos = f.root.Position
	-- 버티기에 들어가면 곧바로 되받아친다
	if (f :: any).retaliate then
		(f :: any).retaliate = nil
		e.nextAttack = math.min(e.nextAttack, t)
	end
	-- 근처에 사람이 없으면 쉰다
	local anyone = false
	for _, player in ipairs(Players:GetPlayers()) do
		local pf = Combat.fighterOfPlayer(player)
		if pf and flatDist(pf.root.Position, pos) < Config.ENEMY_ACTIVE_RANGE then
			anyone = true
			break
		end
	end
	if not anyone then
		e.target = nil
		return
	end
	-- 너무 멀리 끌려 나오면 집으로
	if flatDist(pos, e.home) > 150 then
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
	-- 보스 2단계
	if e.kind == "boss" and not e.phase2 and f.hp < f.maxHp * 0.5 then
		e.phase2 = true
		f.walk = e.def.speed * (e.def.phase2 and e.def.phase2.speed or 1)
		Push:FireAllClients("bossPhase", f.model, e.def.name)
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
	if tgt and (tgt.dead or not tgt.root.Parent or (inSafe(tgt.root.Position) and not e.def.duel) or flatDist(tgt.root.Position, pos) > e.def.aggro * 1.6) then
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
	-- 보스: 싸우는 사람 화면에 체력 막대
	if e.kind == "boss" and tgt.player and not e.engaged[tgt.player] then
		e.engaged[tgt.player] = true
		Push:FireClient(tgt.player, "boss", f.model)
	end
	local d = flatDist(tgt.root.Position, pos)
	-- 상대가 막 치기 시작하면 가끔 막는다 (보스는 더 자주)
	local tact = tgt.act
	if tact and t - tact.start < 0.18 and d < 11 and not f.guarding and not (tact :: any).perfect then
		-- 마구 누르는 연타는 읽혀서 막히고 흘려진다. 박자를 맞춘 일격(連)은 읽지 못한다
		local sloppy = (tgt :: any).sloppy or 0
		local chance = (e.kind == "boss" and 0.4 or 0.22) + math.min(0.5, sloppy * 0.09)
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
	if d < 8 and t < e.nextAttack and math.random() < (e.kind == "boss" and 0.22 or (e.def.elite and 0.18 or 0.12)) then
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
			if d <= m.range + 1 and not (weak and m.unblockable) then
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
