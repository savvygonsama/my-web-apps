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

local function buildRig(def: any, label: string, isBoss: boolean): Model
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = SKIN
	desc.LeftArmColor = SKIN
	desc.RightArmColor = SKIN
	desc.TorsoColor = def.shirt
	desc.LeftLegColor = def.pants
	desc.RightLegColor = def.pants
	local s = def.scale or 1
	desc.HeightScale = s
	desc.WidthScale = s
	desc.DepthScale = s
	desc.HeadScale = s
	local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
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
	local f = Combat.register(model, { npc = def, name = def.name, hp = def.hp, postureMax = def.posture, walk = def.speed, style = "" })
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
	}
	table.insert(Npc.list, e)
	return e
end

-- 지역마다 적과 보스를 놓는다
function Npc.populate()
	for _, region in ipairs(Config.Regions) do
		for _, camp in ipairs(region.camps or {}) do
			for _ = 1, camp.count do
				Npc.spawn(camp.enemy, false, camp.at, region.id)
			end
		end
		if region.boss then
			Npc.spawn(region.boss.id, true, region.boss.at, region.id)
		end
	end
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
			task.delay(wait, function()
				Npc.spawn(e.typeId, e.kind == "boss", e.home, e.region)
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
end

local function think(e: Enemy, t: number)
	local f = e.f
	if f.dead or not f.root.Parent then
		return
	end
	local pos = f.root.Position
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
	if tgt and (tgt.dead or not tgt.root.Parent or inSafe(tgt.root.Position) or flatDist(tgt.root.Position, pos) > e.def.aggro * 1.6) then
		tgt = nil
	end
	if not tgt then
		tgt = nearestPlayer(e, e.def.aggro)
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
	if tact and t - tact.start < 0.18 and d < 11 and not f.guarding then
		local chance = e.kind == "boss" and 0.4 or 0.22
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
	-- 칠 수 있으면 친다
	if t >= e.nextAttack then
		local moves = {}
		for _, m in ipairs(e.def.moves) do
			if d <= m.range + 1 then
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
	local keep = e.def.keep or 5
	local to = tgt.root.Position - pos
	local flatTo = Vector3.new(to.X, 0, to.Z)
	local dir = flatTo.Magnitude > 0.1 and flatTo.Unit or Vector3.new(0, 0, 1)
	if d > keep + 2 then
		f.hum:MoveTo(tgt.root.Position - dir * keep)
	elseif d < keep - 2 then
		f.hum:MoveTo(pos - dir * 4)
	else
		if math.random() < 0.05 then
			e.strafe = -e.strafe
		end
		local side = Vector3.new(-dir.Z, 0, dir.X) * e.strafe
		f.hum:MoveTo(pos + side * 5)
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
