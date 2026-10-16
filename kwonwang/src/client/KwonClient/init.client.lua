-- 권왕(拳王): 맨손의 강호 — 화면
-- 누르는 순간 내 몸이 먼저 움직이고(기다리지 않는다), 맞힌 상대는 서버에 알린다
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Anim = require(script:WaitForChild("Anim"))
local Fx = require(script:WaitForChild("Fx"))
local UI = require(script:WaitForChild("UI"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("KwonRemotes")
local Request = remotes:WaitForChild("Request") :: RemoteEvent
local Push = remotes:WaitForChild("Push") :: RemoteEvent

UI.init(Request)
Fx.bindAnim(Anim)
Anim.start()

local state: any = nil

------------------------------------------------------------------------
-- 무인 지켜보기 (사람과 적 모두 몸동작을 그린다)
------------------------------------------------------------------------
local function watchChar(char: Model)
	task.spawn(function()
		char:WaitForChild("HumanoidRootPart", 10)
		char:WaitForChild("Humanoid", 10)
		Anim.watch(char)
	end)
end
local function watchPlayer(p: Player)
	if p.Character then
		watchChar(p.Character)
	end
	p.CharacterAdded:Connect(watchChar)
end
for _, p in ipairs(Players:GetPlayers()) do
	watchPlayer(p)
end
Players.PlayerAdded:Connect(watchPlayer)
task.spawn(function()
	local enemies = workspace:WaitForChild("Enemies")
	local function add(m: Instance)
		if m:IsA("Model") then
			watchChar(m)
			task.spawn(UI.enemyTag, m)
		end
	end
	for _, m in ipairs(enemies:GetChildren()) do
		add(m)
	end
	enemies.ChildAdded:Connect(add)
end)

-- 사부: 권법 자세로 서 있다가, 가까이 오면 가끔 시범을 보인다
task.spawn(function()
	local masters = workspace:WaitForChild("Masters")
	local function add(m: Instance)
		if m:IsA("Model") then
			watchChar(m)
		end
	end
	for _, m in ipairs(masters:GetChildren()) do
		add(m)
	end
	masters.ChildAdded:Connect(add)
	local nextShow: { [Instance]: number } = {}
	while true do
		task.wait(0.5)
		local char = player.Character
		local me = char and char:FindFirstChild("HumanoidRootPart")
		for _, m in ipairs(masters:GetChildren()) do
			local root = m:FindFirstChild("HumanoidRootPart")
			local style = Config.STYLE_BY_ID[m:GetAttribute("Style") :: any]
			if me and me:IsA("BasePart") and root and root:IsA("BasePart") and style and (root.Position - me.Position).Magnitude < 70 then
				local t = os.clock()
				if t >= (nextShow[m] or 0) and not Anim.playing(m :: Model) then
					local pick = math.random(1, #style.combo + 1)
					local mv = pick > #style.combo and style.heavy or style.combo[pick]
					Anim.play(m :: Model, mv.pose, mv.dur)
					Fx.limbTrails(m :: Model, mv.pose, mv.dur, style.color, style.color2)
					nextShow[m] = t + math.random(25, 45) / 10
				end
			end
		end
	end
end)

------------------------------------------------------------------------
-- 내 몸
------------------------------------------------------------------------
local function myChar(): Model?
	return player.Character
end
local function myRoot(): BasePart?
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function myHum(): Humanoid?
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid") or nil
end
local function myStyle(): any
	return state and state.style ~= "" and Config.STYLE_BY_ID[state.style] or nil
end
local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 1e-4 and f.Unit or Vector3.new(0, 0, -1)
end

local seq = 0
local actSeq = -1
local actStart = 0
local actDur = 0
local combo = 0
local comboAt = 0
local buffered: any = nil
local guarding = false
local chargeStart: number? = nil
local stunUntil = 0
local dead = false
local dashAt = 0
local dashUsed = 0
local airJumped = false
local cds: { [string]: number } = {}
local cdLen: { [string]: number } = {}
local predictedAt: { [Model]: number } = {}
local training: string? = nil

------------------------------------------------------------------------
-- 카메라 흔들림
------------------------------------------------------------------------
local shakeAmp = 0
local function shake(amount: number)
	shakeAmp = math.max(shakeAmp, amount)
end
RunService:BindToRenderStep("KwonShake", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	if shakeAmp > 0.01 then
		local a = shakeAmp
		cam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0) * CFrame.Angles((math.random() - 0.5) * a * 0.02, (math.random() - 0.5) * a * 0.02, 0)
		shakeAmp *= math.exp(-dt * 14)
	end
end)
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "KwonHitTint"
cc.Parent = Lighting
local function tint(color: Color3, strength: number, time: number)
	cc.TintColor = Color3.new(1, 1, 1):Lerp(color, strength)
	cc.Contrast = strength * 0.4
	task.delay(time, function()
		cc.TintColor = Color3.new(1, 1, 1)
		cc.Contrast = 0
	end)
end

------------------------------------------------------------------------
-- 맞힐 상대 찾기 (서버와 같은 상자)
------------------------------------------------------------------------
local function onRing(pos: Vector3): boolean
	local R = Config.RING
	return math.abs(pos.X - R.center.X) <= R.size / 2 and math.abs(pos.Z - R.center.Z) <= R.size / 2 and pos.Y > R.height - 1
end

local function foes(): { Model }
	local list = {}
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
		for _, m in ipairs(enemies:GetChildren()) do
			if m:IsA("Model") and m:GetAttribute("Dead") ~= true then
				table.insert(list, m)
			end
		end
	end
	local me = myRoot()
	if me and onRing(me.Position) then
		for _, p in ipairs(Players:GetPlayers()) do
			local c = p.Character
			local r = c and c:FindFirstChild("HumanoidRootPart")
			if p ~= player and c and r and r:IsA("BasePart") and onRing(r.Position) and c:GetAttribute("Dead") ~= true then
				table.insert(list, c)
			end
		end
	end
	return list
end

local function rootOf(m: Model): BasePart?
	local r = m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end

local function query(hit: any): { Model }
	local root = myRoot()
	if not root then
		return {}
	end
	local look = flat(root.CFrame.LookVector)
	local origin = root.Position
	local center = hit.aoe and origin or origin + look * (hit.range * 0.55)
	local reach = hit.aoe and hit.radius or (hit.range * 0.55 + hit.radius)
	local out = {}
	for _, m in ipairs(foes()) do
		local r = rootOf(m)
		if r then
			local d = Vector3.new(r.Position.X - center.X, 0, r.Position.Z - center.Z).Magnitude
			if d <= reach + 1 and math.abs(r.Position.Y - origin.Y) < 9 then
				table.insert(out, m)
			end
		end
	end
	return out
end

-- 가까운 적 쪽으로 몸을 돌린다 (카메라 방향 75도 안, 14칸 안)
local function aim()
	local root = myRoot()
	local cam = workspace.CurrentCamera
	if not root or not cam then
		return
	end
	local camDir = flat(cam.CFrame.LookVector)
	local best, bestScore = nil, math.huge
	for _, m in ipairs(foes()) do
		local r = rootOf(m)
		if r then
			local v = Vector3.new(r.Position.X - root.Position.X, 0, r.Position.Z - root.Position.Z)
			local d = v.Magnitude
			if d < 14 and d > 0.1 and v.Unit:Dot(camDir) > math.cos(math.rad(75)) then
				if d < bestScore then
					best, bestScore = r, d
				end
			end
		end
	end
	local dir = best and flat(best.Position - root.Position) or camDir
	root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
end

-- 잠깐 앞으로 미끄러지기 (내 몸은 내가 움직인다)
local function push(vel: Vector3, time: number)
	local root = myRoot()
	if not root then
		return
	end
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if not root.Parent or os.clock() - start > time then
			conn:Disconnect()
			return
		end
		root.AssemblyLinearVelocity = Vector3.new(vel.X, math.max(root.AssemblyLinearVelocity.Y, vel.Y), vel.Z)
	end)
end

------------------------------------------------------------------------
-- 기술 쓰기
------------------------------------------------------------------------
local function busy(): boolean
	return os.clock() < actStart + actDur
end

local function canAct(): boolean
	return not dead and os.clock() >= stunUntil and not guarding and myChar() ~= nil and myStyle() ~= nil
end

local startMove: (any, number?) -> ()

local function unlocked(slot: string): boolean
	local need = Config.SKILL_UNLOCK[slot]
	if not need or not state then
		return true
	end
	local m = state.mastery and state.mastery[state.style]
	return (m and m.lv or 1) >= need
end

startMove = function(slot: any, charge: number?)
	local style = myStyle()
	local char = myChar()
	local root = myRoot()
	if not style or not char or not root then
		return
	end
	local move = Config.move(style.id, slot)
	if not move then
		return
	end
	local now = os.clock()
	-- 앞 기술이 남아 있으면 줄 세운다 (끝날 때 바로 나간다)
	if busy() then
		if now >= actStart + actDur * (type(slot) == "number" and 0.7 or 0.85) then
			-- 이어 쓸 수 있는 순간
		else
			buffered = { slot = slot, charge = charge, at = now }
			return
		end
	end
	if type(slot) == "string" and slot ~= "H" then
		if not unlocked(slot) then
			UI.toast(string.format("🔒 %s: 숙련도 %d에 열려요", move.name, Config.SKILL_UNLOCK[slot]))
			return
		end
		if now < (cds[slot] or 0) then
			return
		end
		local chi = char:GetAttribute("Chi")
		if type(chi) == "number" and chi < (move.chi or 0) then
			UI.toast(string.format("내공이 부족해요 (🌀 %d 필요)", move.chi or 0))
			return
		end
		cds[slot] = now + (move.cd or 0)
		cdLen[slot] = move.cd or 1
	end
	local speed = style.speed or 1
	local dur = move.dur / speed
	aim()
	seq += 1
	local mySeq = seq
	actSeq = mySeq
	actStart = now
	actDur = dur
	buffered = nil
	local first = move.hits and move.hits[1]
	Anim.play(char, move.pose, dur, { align = first and first.t / speed or nil })
	Fx.limbTrails(char, move.pose, dur, style.color, style.color2)
	Request:FireServer("act", slot, mySeq, charge)
	local look = flat(root.CFrame.LookVector)
	if move.lunge and move.lunge > 0 and not move.teleport then
		push(look * (move.lunge / 0.16), 0.16)
	end
	if move.jump then
		root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, move.jump, root.AssemblyLinearVelocity.Z)
	end
	if slot == "G" then
		UI.cinematic(move.name, style.color, dur)
		Fx.ult(style.id, char, dur)
		shake(1.2)
		tint(style.color, 0.25, dur)
	end
	-- 휘두르는 소리와 맞힘 알리기
	for i, h in ipairs(move.hits or {}) do
		task.delay(h.t / speed, function()
			if actSeq ~= mySeq or dead then
				return
			end
			Fx.sound("swing", 0.35, 1.05 + math.random() * 0.25)
			local targets = query(h)
			Request:FireServer("hit", mySeq, i, targets)
			-- 바로 반응 (서버가 정하기 전에): 멈칫과 불꽃
			for _, m in ipairs(targets) do
				local r = rootOf(m)
				if r and m:GetAttribute("Guard") ~= true then
					predictedAt[m] = os.clock()
					local heavy = (h.kb or 0) >= 20 or (h.stun or 0) >= 0.6
					Fx.hitstop({ char, m }, heavy and 0.09 or 0.05)
					Fx.styleHit(style.id, r.Position:Lerp(root.Position, 0.35) + Vector3.new(0, 1, 0), heavy, look)
					Fx.sound(heavy and "heavy" or "hit", heavy and 0.9 or 0.6, heavy and 0.6 or 0.85 + math.random() * 0.2)
					shake(heavy and 0.9 or 0.35)
					Anim.play(m, (math.random() < 0.5) and "flinch_l" or "flinch_r", 0.3)
				end
			end
		end)
	end
	if move.proj then
		task.delay(dur * 0.42, function()
			if actSeq == mySeq then
				Fx.sound("swing", 0.6, 0.7)
				shake(0.4)
			end
		end)
	end
end

-- 줄 세운 입력: 앞 기술이 끝나면 바로
RunService.Heartbeat:Connect(function()
	if buffered and not busy() and canAct() then
		local b = buffered
		buffered = nil
		if os.clock() - b.at < 0.5 then
			startMove(b.slot, b.charge)
		end
	elseif buffered and os.clock() >= actStart + actDur * 0.7 and canAct() and type(buffered.slot) == "number" then
		local b = buffered
		buffered = nil
		startMove(b.slot, b.charge)
	end
end)

local function attack()
	if training and training ~= "bamboo" then
		UI.trainPress()
		return
	end
	if not canAct() then
		return
	end
	local style = myStyle()
	if not style then
		UI.openPage("styles", { first = true })
		return
	end
	local now = os.clock()
	local nextIdx = 1
	if now - comboAt <= Config.COMBO_WINDOW + actDur and combo < #style.combo then
		nextIdx = combo + 1
	end
	if busy() and now < actStart + actDur * 0.7 then
		-- 아직 이르다: 다음 연타를 줄 세운다
		buffered = { slot = (combo % #style.combo) + 1, at = now }
		return
	end
	combo = nextIdx
	comboAt = now
	startMove(nextIdx)
end

local function heavyDown()
	if not canAct() then
		return
	end
	local style = myStyle()
	if style and style.charge then
		chargeStart = os.clock()
		local char = myChar()
		if char then
			Anim.setLoop(char, "double_palm", 3)
			local root = myRoot()
			if root then
				Fx.ring(root.Position - Vector3.new(0, 2.5, 0), style.color, 2, 8, 0.5)
			end
		end
		return
	end
	startMove("H")
end

local function heavyUp()
	if not chargeStart then
		return
	end
	local style = myStyle()
	local held = os.clock() - (chargeStart :: number)
	chargeStart = nil
	local char = myChar()
	if char then
		Anim.setLoop(char, nil)
	end
	if style then
		startMove("H", math.clamp(held, 0, style.charge or 1.5))
	end
end

local function skill(slot: string)
	if canAct() then
		startMove(slot)
	end
end

local function guardDown()
	if training == "dummy" then
		UI.trainPress()
		return
	end
	if dead or os.clock() < stunUntil or busy() then
		return
	end
	guarding = true
	Request:FireServer("guard", true)
end
local function guardUp()
	if guarding then
		guarding = false
		Request:FireServer("guard", false)
	end
end

local function dash()
	local style = myStyle()
	local root = myRoot()
	local hum = myHum()
	local char = myChar()
	if not root or not hum or not char or dead or os.clock() < stunUntil then
		return
	end
	local now = os.clock()
	local cd = style and style.dashCd or Config.DASH_CD
	local charges = style and style.dashCharges or 1
	if now - dashAt > cd then
		dashUsed = 0
	end
	if dashUsed >= charges then
		return
	end
	dashUsed += 1
	dashAt = now
	guardUp()
	actSeq = -1
	actDur = 0
	local dir = hum.MoveDirection.Magnitude > 0.1 and flat(hum.MoveDirection) or flat(root.CFrame.LookVector)
	root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
	push(dir * Config.DASH_SPEED, Config.DASH_TIME)
	Anim.play(char, "dash", 0.28)
	Fx.afterimage(char, style and style.color or Color3.new(1, 1, 1), 0.3)
	Fx.sound("swing", 0.4, 1.6)
	Request:FireServer("dash")
end

local function doubleJump()
	local root = myRoot()
	local hum = myHum()
	local char = myChar()
	if not root or not hum or not char or dead or airJumped then
		return
	end
	if hum.FloorMaterial ~= Enum.Material.Air then
		return
	end
	airJumped = true
	root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, Config.DOUBLE_JUMP, root.AssemblyLinearVelocity.Z)
	Anim.play(char, "double_jump", 0.45)
	local style = myStyle()
	Fx.ring(root.Position - Vector3.new(0, 2.5, 0), style and style.color or Color3.new(1, 1, 1), 2, 9, 0.35)
	Fx.sound("jump", 0.5, 1.3)
	Request:FireServer("djump")
end

------------------------------------------------------------------------
-- 입력
------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then
		return
	end
	local t = input.UserInputType
	local k = input.KeyCode
	if t == Enum.UserInputType.MouseButton1 then
		attack()
	elseif t == Enum.UserInputType.MouseButton2 then
		heavyDown()
	elseif k == Enum.KeyCode.E then
		skill("E")
	elseif k == Enum.KeyCode.R then
		skill("R")
	elseif k == Enum.KeyCode.G then
		skill("G")
	elseif k == Enum.KeyCode.Q then
		dash()
	elseif k == Enum.KeyCode.F then
		guardDown()
	elseif k == Enum.KeyCode.H then
		Request:FireServer("potion")
	elseif k == Enum.KeyCode.Space then
		if training and training ~= "bamboo" then
			UI.trainPress()
		else
			doubleJump()
		end
	elseif k == Enum.KeyCode.Tab then
		UI.openPage("stats")
	elseif k == Enum.KeyCode.M then
		UI.toggleMap()
	end
end)
UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		heavyUp()
	elseif input.KeyCode == Enum.KeyCode.F then
		guardUp()
	end
end)
UI.mobile({
	attack = attack,
	heavyDown = heavyDown,
	heavyUp = heavyUp,
	guardDown = guardDown,
	guardUp = guardUp,
	dash = dash,
	E = function()
		skill("E")
	end,
	R = function()
		skill("R")
	end,
	G = function()
		skill("G")
	end,
	potion = function()
		Request:FireServer("potion")
	end,
	train = function()
		UI.trainPress()
	end,
})

-- 땅에 닿으면 두 번 뛰기를 되살린다
RunService.Heartbeat:Connect(function()
	local hum = myHum()
	if hum and hum.FloorMaterial ~= Enum.Material.Air then
		airJumped = false
	end
end)

------------------------------------------------------------------------
-- 서버 소식
------------------------------------------------------------------------
local handlers: { [string]: (...any) -> () } = {}

local function modelPos(m: Model?): Vector3?
	local r = m and rootOf(m)
	return r and r.Position or nil
end

function handlers.state(data: any)
	state = data
	UI.setState(data)
end

function handlers.toast(msg: string)
	UI.toast(msg)
end

function handlers.open(data: any)
	UI.openPage(data.page, data)
end

-- 사부에게 가는 길잡이
function handlers.guide(data: any)
	UI.setGuide(data.style)
end

-- 누군가 기술을 쓴다
function handlers.act(data: any)
	local m: Model = data.m
	if not m or not m.Parent then
		return
	end
	if m == myChar() and data.seq ~= -1 then
		return -- 내 몸은 이미 움직였다
	end
	Anim.play(m, data.pose, data.dur, { align = data.align })
	local style = type(data.style) == "string" and Config.STYLE_BY_ID[data.style]
	local color = style and style.color or (data.unblockable and Color3.fromRGB(255, 60, 40) or Color3.fromRGB(235, 235, 245))
	Fx.limbTrails(m, data.pose, data.dur, color, style and style.color2 or Color3.new(1, 1, 1))
	local pos = modelPos(m)
	local me = myRoot()
	local near = pos and me and (pos - me.Position).Magnitude < 60
	-- 적이 휘두르기 직전: 무기가 반짝인다 (흘릴 때!), 붉으면 막을 수 없다
	if data.windup and pos then
		if data.unblockable then
			Fx.text(pos + Vector3.new(0, 5, 0), "⚠ 危", Color3.fromRGB(255, 70, 50), 34, 1.5)
			Fx.ring(pos - Vector3.new(0, 2.5, 0), Color3.fromRGB(255, 50, 40), 3, 14, data.windup)
		end
		task.delay(math.max(0, data.windup - 0.14), function()
			local p2 = modelPos(m)
			if not p2 then
				return
			end
			local blade = nil
			for _, w in ipairs(m:GetChildren()) do
				if w.Name == "Weapon" then
					local b = w:FindFirstChild("Blade")
					if b and b:IsA("BasePart") then
						blade = b
					end
				end
			end
			local at = blade and blade.Position or (p2 + Vector3.new(0, 2, 0))
			Fx.spark(at, data.unblockable and Color3.fromRGB(255, 60, 40) or Color3.fromRGB(255, 255, 230), 0.8, 4)
			if near then
				Fx.sound("ping", 0.35, data.unblockable and 0.6 or 1.6)
			end
		end)
	end
	if type(data.id) == "string" and string.sub(data.id, -1) == "G" and style then
		Fx.ult(style.id, m, data.dur)
		if near then
			shake(0.8)
		end
	end
end

function handlers.interrupt(m: Model)
	if m == myChar() then
		actSeq = -1
		actDur = 0
		buffered = nil
	end
	Anim.stop(m)
end

-- 맞힘 결과
function handlers.hit(data: any)
	local a: Model, t: Model = data.a, data.t
	local pos: Vector3 = data.pos
	local me = myChar()
	local mine = a == me
	local hurt = t == me
	local aRoot, tRoot = a and rootOf(a), t and rootOf(t)
	local dir = (aRoot and tRoot) and flat(tRoot.Position - aRoot.Position) or Vector3.new(0, 0, -1)
	local kind = data.kind
	if kind == "hit" then
		local predicted = mine and predictedAt[t] and os.clock() - predictedAt[t] < 0.6
		if not predicted then
			local hs = data.broken and 0.16 or (data.heavy and 0.1 or 0.055)
			Fx.hitstop({ a, t }, hs)
			Fx.styleHit(data.style, pos, data.heavy, dir)
			Fx.sound(data.heavy and "heavy" or "hit", data.heavy and 0.9 or 0.6, data.heavy and 0.6 or 0.9, if mine or hurt then nil else pos)
			if t then
				local side = (aRoot and tRoot) and (tRoot.CFrame.RightVector:Dot(aRoot.Position - tRoot.Position) > 0 and "flinch_r" or "flinch_l") or "flinch_l"
				Anim.play(t, data.heavy and "knockdown" or side, data.heavy and 0.6 or 0.3)
			end
		elseif data.heavy and t then
			Anim.play(t, "knockdown", 0.6)
		end
		if data.strike then
			Fx.lightning(pos + Vector3.new(math.random(-4, 4), 60, math.random(-4, 4)), pos, Color3.fromRGB(255, 245, 140), 0.7)
		end
		local col = data.crit and Color3.fromRGB(255, 220, 80) or (hurt and Color3.fromRGB(255, 90, 80) or Color3.new(1, 1, 1))
		Fx.text(pos + Vector3.new(0, 2, 0), (data.crit and "會 " or "") .. tostring(math.floor((data.dmg or 0) + 0.5)), col, data.crit and 34 or 26)
		if data.broken then
			Fx.text(pos + Vector3.new(0, 5, 0), "破 파훼!", Color3.fromRGB(255, 200, 80), 40)
			Fx.ring(pos, Color3.fromRGB(255, 200, 80), 2, 18, 0.45)
			if mine or hurt then
				shake(1.6)
				UI.flash(Color3.fromRGB(255, 220, 140), 0.35)
			end
		end
		if hurt then
			shake(data.heavy and 1.4 or 0.6)
			UI.flash(Color3.fromRGB(255, 40, 30), data.heavy and 0.3 or 0.12)
		elseif mine and data.heavy and not predicted then
			shake(0.9)
		end
	elseif kind == "block" or kind == "guardbreak" then
		Fx.hitstop({ a, t }, 0.05)
		Fx.spark(pos, Color3.fromRGB(230, 230, 255), 1, 6)
		Fx.sound("block", 0.5, 0.75)
		if t then
			Anim.play(t, "block_hit", 0.3)
		end
		if kind == "guardbreak" then
			Fx.text(pos + Vector3.new(0, 4, 0), "破 막기가 깨졌다!", Color3.fromRGB(255, 200, 80), 32)
			Fx.ring(pos, Color3.fromRGB(255, 200, 80), 2, 16, 0.4)
			shake(1.2)
		else
			Fx.text(pos + Vector3.new(0, 2, 0), tostring(math.floor((data.dmg or 0) + 0.5)), Color3.fromRGB(190, 190, 210), 20)
		end
		if hurt then
			shake(0.35)
		end
	elseif kind == "deflect" then
		-- 흘리기: 모든 게 아주 잠깐 멈추고, 차가운 빛이 번쩍
		Fx.hitstop({ a, t }, 0.18)
		Fx.spark(pos, Color3.fromRGB(180, 230, 255), 1.6, 12)
		Fx.ring(pos, Color3.fromRGB(200, 240, 255), 1, 10, 0.3, dir)
		Fx.sound("deflect", 0.8, 1.2 + math.random() * 0.2)
		Fx.text(pos + Vector3.new(0, 4, 0), data.counter and "流 되받아치기!" or "流 흘리기!", Color3.fromRGB(170, 230, 255), 36)
		if t then
			Anim.play(t, "deflect", 0.35)
		end
		if a then
			Anim.play(a, "stagger", Config.DEFLECT_STAGGER)
		end
		if mine or hurt then
			shake(0.7)
			UI.flash(Color3.fromRGB(170, 220, 255), 0.25)
			tint(Color3.fromRGB(170, 210, 255), 0.35, 0.18)
		end
	elseif kind == "clash" then
		-- 격돌: 주먹과 주먹이 부딪힌다
		Fx.hitstop({ a, t }, 0.14)
		Fx.spark(pos, Color3.fromRGB(255, 240, 200), 2.4, 16)
		Fx.ring(pos, Color3.new(1, 1, 1), 2, 16, 0.4, dir)
		Fx.ring(pos - Vector3.new(0, 2, 0), Color3.fromRGB(255, 220, 160), 2, 22, 0.5)
		Fx.sound("heavy", 1, 0.45)
		Fx.text(pos + Vector3.new(0, 5, 0), "激 격돌!", Color3.fromRGB(255, 240, 200), 40)
		if mine or hurt then
			shake(1.5)
			UI.flash(Color3.new(1, 1, 1), 0.35)
		end
	elseif kind == "dodge" then
		if t then
			local tt = Config.STYLE_BY_ID[tostring(t:GetAttribute("Style") or "")]
			Fx.afterimage(t, tt and tt.color or Color3.fromRGB(200, 200, 255), 0.35)
		end
		Fx.text(pos + Vector3.new(0, 3, 0), data.drunk and "醉 취보!" or "회피", Color3.fromRGB(220, 220, 255), 26)
	end
end

function handlers.broken(m: Model, secs: number)
	Anim.play(m, "broken", secs)
	local p = modelPos(m)
	if p then
		Fx.text(p + Vector3.new(0, 5, 0), "破 파훼!", Color3.fromRGB(255, 200, 80), 40)
	end
	if m == myChar() then
		stunUntil = os.clock() + secs
		actSeq = -1
		actDur = 0
	end
end

function handlers.ko(m: Model, _by: Model?)
	Anim.play(m, "knockdown", 1.2)
	local p = modelPos(m)
	if p then
		Fx.dust(p - Vector3.new(0, 2, 0), 3)
		Fx.sound("fall", 0.6, 0.8, p)
	end
	if m == myChar() then
		dead = true
		actSeq = -1
		guarding = false
		UI.ko(true, Config.RESPAWN_TIME)
	end
end

function handlers.respawn()
	dead = false
	stunUntil = 0
	UI.ko(false)
end

function handlers.knock(vel: Vector3, stun: number)
	local root = myRoot()
	if root then
		push(vel, 0.12)
	end
	if stun and stun > 0 then
		stunUntil = math.max(stunUntil, os.clock() + stun)
		actSeq = -1
		actDur = 0
		buffered = nil
	end
end

function handlers.proj(data: any)
	Fx.projectile(data)
end

function handlers.dash(m: Model)
	if m == myChar() then
		return
	end
	Anim.play(m, "dash", 0.28)
	local s = Config.STYLE_BY_ID[tostring(m:GetAttribute("Style") or "")]
	Fx.afterimage(m, s and s.color or Color3.new(1, 1, 1), 0.3)
end

function handlers.djump(m: Model)
	if m ~= myChar() then
		Anim.play(m, "double_jump", 0.45)
	end
end

function handlers.blink(m: Model, to: Vector3)
	local p = modelPos(m)
	if p then
		Fx.afterimage(m, Color3.fromRGB(60, 30, 100), 0.4)
	end
	Fx.ring(to - Vector3.new(0, 2.5, 0), Color3.fromRGB(150, 100, 255), 2, 10, 0.3)
	Fx.sound("swing", 0.6, 0.6, to)
end

function handlers.chain(data: any)
	local from = modelPos(data.from)
	if not from then
		return
	end
	for _, m in ipairs(data.to or {}) do
		local p = modelPos(m)
		if p then
			Fx.lightning(from, p, Color3.fromRGB(255, 245, 140), 0.45)
		end
	end
	Fx.text(from + Vector3.new(0, 5, 0), "⚡ 연쇄 번개!", Color3.fromRGB(255, 245, 140), 30)
end

function handlers.bloom(m: Model, radius: number)
	local p = modelPos(m)
	if p then
		Fx.bloom(p - Vector3.new(0, 2, 0), radius)
		Fx.text(p + Vector3.new(0, 5, 0), "🌸 만개!", Color3.fromRGB(255, 150, 200), 36)
		if m == myChar() then
			shake(1)
		end
	end
end

function handlers.heal(m: Model)
	local p = modelPos(m)
	if p then
		Fx.spark(p, Color3.fromRGB(120, 255, 140), 1.2, 8)
		Fx.text(p + Vector3.new(0, 3, 0), "+ 회복", Color3.fromRGB(120, 255, 140), 24)
	end
end

function handlers.trainPose(m: Model, kind: string?)
	if kind == "waterfall" then
		Anim.setLoop(m, "meditate", 2)
	elseif kind == "rock" then
		Anim.setLoop(m, "lift", 1.4)
	else
		Anim.setLoop(m, nil)
	end
end

function handlers.train(data: any)
	if data then
		training = data.kind
		UI.trainStart(data.kind, data.rings, function(grade: string, idx: number?)
			Request:FireServer("trainHit", grade, idx)
		end)
	else
		training = nil
		UI.trainStop()
	end
end

function handlers.trained(data: any)
	UI.trainResult(data)
	if data.gain > 0 then
		Fx.sound("ping", 0.4, data.grade == "perfect" and 1.8 or 1.3)
		local root = myRoot()
		if root and data.grade == "perfect" then
			local s = myStyle()
			Fx.ring(root.Position - Vector3.new(0, 2.5, 0), s and s.color or Color3.fromRGB(255, 220, 120), 2, 10, 0.4)
		end
	end
end

function handlers.learned(data: any)
	local s = Config.STYLE_BY_ID[data.style]
	if s then
		UI.banner(s.icon .. " " .. s.name .. " 입문!", data.first and "클릭으로 연타, F로 막고 흘려라 · 남쪽 들판에서 겨뤄 보자" or s.hanja, s.color)
		UI.closeWindow()
		UI.setGuide(nil)
	end
end

function handlers.mastery(data: any)
	local s = Config.STYLE_BY_ID[data.style]
	UI.banner(string.format("%s 숙련 %d", s and s.name or "", data.lv), data.unlocked and ("새 기술: " .. data.unlocked) or nil, s and s.color or nil)
	Fx.sound("ping", 0.6, 1.5)
end

function handlers.reward(data: any)
	UI.toast(string.format("%s 쓰러뜨림  💰 +%d  숙련 +%d", data.name, data.coins, data.xp))
	if data.boss then
		UI.banner("🏆 " .. data.name .. " 격파!", string.format("💰 +%d", data.coins), Color3.fromRGB(255, 210, 120))
	end
end

function handlers.boss(m: Model?)
	UI.setBoss(m)
end

function handlers.bossPhase(_m: Model, name: string)
	UI.banner("👹 " .. name, "분노했다! 더 빨라진다", Color3.fromRGB(255, 80, 60))
	shake(1)
end

function handlers.duel(data: any)
	UI.toast(string.format("⚔ 비무대: %s 승, %s 패", data.winner, data.loser))
end

function handlers.realm(data: any)
	UI.banner(string.format("✨ %s, %s의 경지에 오르다", data.name, data.realm), nil, Color3.fromRGB(255, 220, 140))
end

Push.OnClientEvent:Connect(function(kind: string, ...)
	local f = handlers[kind]
	if f then
		local ok, err = pcall(f, ...)
		if not ok then
			warn("[권왕] 화면 처리 오류:", kind, err)
		end
	end
end)

------------------------------------------------------------------------
-- 매 순간 화면 (막대, 기술 칸)
------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	local char = myChar()
	if not char then
		return
	end
	local hp = char:GetAttribute("Hp")
	local mx = char:GetAttribute("MaxHp")
	local po = char:GetAttribute("Posture")
	local pm = char:GetAttribute("PostureMax")
	local chi = char:GetAttribute("Chi")
	if type(hp) == "number" and type(mx) == "number" then
		UI.bars(hp, mx, type(po) == "number" and po or 0, type(pm) == "number" and pm or 100, type(chi) == "number" and chi or 0)
	end
	local style = myStyle()
	if not style then
		UI.styleLine("🥋 권법 창에서 첫 권법을 고르세요 (공짜)", Color3.fromRGB(230, 220, 200), "")
		return
	end
	local now = os.clock()
	local info: { [string]: any } = {
		M1 = { name = style.combo[1].name },
		H = { name = style.heavy.name },
		Q = { name = "대시", cd = math.max(0, (dashAt + (style.dashCd or Config.DASH_CD) - now) / (style.dashCd or Config.DASH_CD)) },
		F = { name = guarding and "막는 중" or "막기·흘리기" },
		P = { name = string.format("금창약 %d", state and state.potions or 0) },
	}
	for _, slot in ipairs({ "E", "R", "G" }) do
		local sk = style.skills[slot]
		local left = (cds[slot] or 0) - now
		info[slot] = { name = sk.name, locked = not unlocked(slot), cd = left > 0 and left / (cdLen[slot] or 1) or (slot == "G" and type(chi) == "number" and chi < 100 and 1 - chi / 100 or 0) }
	end
	UI.slots(info)
	-- 권법 장치 표시
	local stacks = ""
	if style.id == "taeheo" then
		stacks = "기류 " .. string.rep("●", tonumber(char:GetAttribute("Flow")) or 0) .. string.rep("○", 3 - (tonumber(char:GetAttribute("Flow")) or 0))
	elseif style.id == "maehwa" then
		local n = tonumber(char:GetAttribute("Petal")) or 0
		stacks = n >= 20 and "🌸 만개 준비! (우클릭)" or string.format("꽃잎 %d / 20", n)
	elseif style.id == "byeokryeok" then
		local n = tonumber(char:GetAttribute("Charge")) or 0
		stacks = "전하 " .. string.rep("⚡", n) .. string.rep("·", 5 - n)
	elseif style.id == "cheonryong" and chargeStart then
		stacks = string.format("용기 모으는 중 %d%%", math.floor(math.clamp((now - chargeStart) / (style.charge or 1.5), 0, 1) * 100))
	end
	local buff = char:GetAttribute("Buff")
	if buff == "ironshirt" then
		stacks ..= "  🔔 철포삼"
	elseif buff == "sway" then
		stacks ..= "  🍶 취보"
	end
	UI.styleLine(style.icon .. " " .. style.name, style.color, stacks)
end)

Request:FireServer("hello")
