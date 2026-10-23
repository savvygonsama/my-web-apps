-- 권왕(拳王): 맨손의 강호 — 화면
-- 누르는 순간 내 몸이 먼저 움직이고(기다리지 않는다), 맞힌 상대는 서버에 알린다
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Anim = require(script:WaitForChild("Anim"))
local Fx = require(script:WaitForChild("Fx"))
local UI = require(script:WaitForChild("UI"))
local Ults = require(script:WaitForChild("Ults"))
local Cutscene = require(script:WaitForChild("Cutscene"))
local Music = require(script:WaitForChild("Music"))
local Gacha = require(script:WaitForChild("Gacha"))
local Mount = require(script:WaitForChild("Mount"))
local Sakura = require(script:WaitForChild("Sakura"))
local Drunk = require(script:WaitForChild("Drunk"))
local Awake = require(script:WaitForChild("Awake"))
local Reaper = require(script:WaitForChild("Reaper"))
local Polish = require(script:WaitForChild("Polish"))
local SkillFx = require(script:WaitForChild("SkillFx"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("KwonRemotes")
local Request = remotes:WaitForChild("Request") :: RemoteEvent
local Push = remotes:WaitForChild("Push") :: RemoteEvent

UI.init(Request)
Fx.bindAnim(Anim)
Anim.start()

local state: any = nil
local launchedAt: { [Instance]: number } = {} -- 하늘로 띄운 적 (공중 연격 판단)
local function rootOfChar(): BasePart?
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end

------------------------------------------------------------------------
-- 무인 지켜보기 (사람과 적 모두 몸동작을 그린다)
------------------------------------------------------------------------
local function watchChar(char: Model)
	task.spawn(function()
		char:WaitForChild("HumanoidRootPart", 10)
		char:WaitForChild("Humanoid", 10)
		Anim.watch(char)
	end)
	-- 금강 법신 (금빛 거인), 번개·일순 베기 동안 사라짐
	char:GetAttributeChangedSignal("Giant"):Connect(function()
		Ults.watchGiant(char)
	end)
	-- 열화신권 연소: 불붙은 몸에 불꽃
	char:GetAttributeChangedSignal("Burning"):Connect(function()
		Fx.burning(char, char:GetAttribute("Burning") == true)
	end)
	char:GetAttributeChangedSignal("Vanish"):Connect(function()
		Ults.watchVanish(char)
	end)
	-- 초월 권법의 벚꽃 부채
	Sakura.watch(char)
	-- 탈것: 아래에 말·범·구름을 그리고, 탄 자세로
	Mount.watch(char)
	char:GetAttributeChangedSignal("Mount"):Connect(function()
		Anim.setLoop(char, char:GetAttribute("Mount") and "ride" or nil, 0.8)
	end)
end
local function watchPlayer(p: Player)
	local function add(char: Model)
		watchChar(char)
	end
	if p.Character then
		add(p.Character)
	end
	p.CharacterAdded:Connect(add)
end
for _, p in ipairs(Players:GetPlayers()) do
	watchPlayer(p)
end
Players.PlayerAdded:Connect(watchPlayer)
-- 사부와 적도 부채를 든다 (초월의 시련, 사부 자리)
task.spawn(function()
	for _, name in ipairs({ "Masters", "Enemies" }) do
		local f = workspace:WaitForChild(name, 60)
		if f then
			Sakura.watchFolder(f)
		end
	end
end)
task.spawn(function()
	local enemies = workspace:WaitForChild("Enemies")
	local function add(m: Instance)
		if m:IsA("Model") then
			watchChar(m)
			task.spawn(UI.enemyTag, m)
			m:GetAttributeChangedSignal("LaunchedAt"):Connect(function()
				launchedAt[m] = os.clock()
			end)
		end
	end
	for _, m in ipairs(enemies:GetChildren()) do
		add(m)
	end
	enemies.ChildAdded:Connect(add)
end)

-- 각성의 기운 (사람과 사부): 0.5초마다 단계에 맞춰 붙이고 뗀다
local handKey: { [Model]: string } = setmetatable({}, { __mode = "k" }) :: any
task.spawn(function()
	while true do
		task.wait(0.5)
		local list: { Model } = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				table.insert(list, p.Character)
			end
		end
		local mf = workspace:FindFirstChild("Masters")
		for _, m in ipairs(mf and mf:GetChildren() or {}) do
			if m:IsA("Model") then
				table.insert(list, m)
			end
		end
		for _, m in ipairs(list) do
			local style = Config.STYLE_BY_ID[tostring(m:GetAttribute("Style") or "")]
			local tier = tonumber(m:GetAttribute("Awaken")) or 0
			pcall(Fx.awakenAura, m, style and tier or 0, style and style.color or Color3.new(1, 1, 1))
		end
		-- 권법마다 손에 맺힌 기운 (사부의 분신도)
		local ef = workspace:FindFirstChild("Enemies")
		for _, m in ipairs(ef and ef:GetChildren() or {}) do
			if m:IsA("Model") and m:GetAttribute("Style") then
				table.insert(list, m)
			end
		end
		for _, m in ipairs(list) do
			local key = tostring(m:GetAttribute("Style") or "") .. ":" .. tostring(tonumber(m:GetAttribute("Awaken")) or 0)
			if handKey[m] ~= key then
				handKey[m] = key
				pcall(Fx.styleHands, m, m:GetAttribute("Style"), tonumber(m:GetAttribute("Awaken")) or 0)
			end
		end
	end
end)

-- 빠르게 움직이면 화면 가장자리에 바람 줄
RunService.RenderStepped:Connect(function()
	local root = rootOfChar()
	if root then
		local v = root.AssemblyLinearVelocity
		UI.setSpeed(math.clamp((Vector3.new(v.X, 0, v.Z).Magnitude - 27) / 35, 0, 1))
	end
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
	local nextSpeak: { [Instance]: number } = {}
	-- 말풍선
	local function speak(m: Model, text: string, color: Color3)
		local head = m:FindFirstChild("Head")
		if text == "" or not head or not head:IsA("BasePart") then
			return
		end
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 360, 0, 70)
		bb.StudsOffset = Vector3.new(0, 6.2, 0)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.MaxDistance = 80
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromRGB(20, 16, 14)
		frame.BackgroundTransparency = 0.2
		frame.Parent = bb
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = frame
		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = 2
		stroke.Parent = frame
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -16, 1, -8)
		label.Position = UDim2.new(0, 8, 0, 4)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextWrapped = true
		label.TextColor3 = Color3.fromRGB(255, 245, 225)
		label.Text = "「" .. text .. "」"
		label.Parent = frame
		bb.Parent = head
		task.delay(5, function()
			bb:Destroy()
		end)
	end
	-- 사부 둘레를 도는 기운의 구슬
	local orbs: { [Instance]: { Part } } = {}
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local me = rootOfChar()
		for _, m in ipairs(masters:GetChildren()) do
			local root = m:FindFirstChild("HumanoidRootPart")
			local style = Config.STYLE_BY_ID[tostring(m:GetAttribute("Style") or "")]
			if root and root:IsA("BasePart") and style and me and (root.Position - me.Position).Magnitude < 140 then
				local list = orbs[m]
				if not list then
					list = {}
					for i = 1, 3 do
						local o = Instance.new("Part")
						o.Name = "MasterOrb"
						o.Shape = Enum.PartType.Ball
						o.Size = Vector3.new(0.7, 0.7, 0.7)
						o.Anchored = true
						o.CanCollide = false
						o.CanQuery = false
						o.CanTouch = false
						o.CastShadow = false
						o.Material = Enum.Material.Neon
						o.Color = i == 2 and style.color2 or style.color
						o.Parent = workspace
						local l = Instance.new("PointLight")
						l.Color = style.color
						l.Range = 8
						l.Brightness = 1.2
						l.Parent = o
						table.insert(list, o)
					end
					orbs[m] = list
				end
				for i, o in ipairs(list) do
					local a = t * 1.6 + i / 3 * math.pi * 2
					o.Position = root.Position + Vector3.new(math.cos(a) * 4, 0.5 + math.sin(t * 2 + i) * 1.2, math.sin(a) * 4)
				end
			elseif orbs[m] then
				for _, o in ipairs(orbs[m]) do
					o:Destroy()
				end
				orbs[m] = nil
			end
		end
	end)
	while true do
		task.wait(0.5)
		local char = player.Character
		local me = char and char:FindFirstChild("HumanoidRootPart")
		for _, m in ipairs(masters:GetChildren()) do
			local root = m:FindFirstChild("HumanoidRootPart")
			local style = Config.STYLE_BY_ID[m:GetAttribute("Style") :: any]
			if me and me:IsA("BasePart") and root and root:IsA("BasePart") and style and (root.Position - me.Position).Magnitude < 70 then
				local t = os.clock()
				local dist = (root.Position - me.Position).Magnitude
				-- 가까이 오면 한마디
				if dist < 32 and t >= (nextSpeak[m] or 0) then
					nextSpeak[m] = t + 30
					speak(m :: Model, tostring(m:GetAttribute("Quote") or ""), style.color)
				end
				if t >= (nextShow[m] or 0) and not Anim.playing(m :: Model) then
					-- 시범: 연타, 강타, 기술을 섞어 제대로 보여 준다
					local picks: { any } = { 1, 2, 3, 4, "H", "E", "R", "F" }
					local slot = picks[math.random(1, #picks)]
					local mv = Config.move(style.id, slot)
					if mv then
						Anim.play(m :: Model, mv.pose, mv.dur)
						Fx.limbTrails(m :: Model, mv.pose, mv.dur, style.color, style.color2)
						Fx.cast(style.id, slot, m :: Model, mv.dur)
						Sakura.cast(style.id, slot, m :: Model, mv.dur)
						Drunk.cast(style.id, slot, m :: Model, mv.dur)
						Reaper.cast(style.id, slot, m :: Model, mv.dur)
						SkillFx.cast(style.id, slot, m :: Model, mv.dur)
						for _, h in ipairs(mv.hits or {}) do
							task.delay(h.t, function()
								Fx.swing(style.id, m :: Model, (h.kb or 0) >= 20)
							end)
						end
					end
					nextShow[m] = t + math.random(30, 50) / 10
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
local buffered: any = nil
local guarding = false
local chargeStart: number? = nil
local stunUntil = 0
local dead = false
local dashAt = 0
local dashUsed = 0
local airJumped = false
local deflectAt = 0 -- 마지막으로 흘린 때 (곧바로 클릭하면 반격)
-- 연타 박자
local earlyPresses = 0 -- 지금 동작 중에 너무 일찍 누른 횟수
local comboBroken = false -- 흐트러졌다 (마구 눌렀다)
local nextPerfect = false -- 다음 동작이 박자를 맞췄는가
local perfectChain = 0
local lastComboSlot: any = nil
local airJ = 0
local airAttacked = false
local sprinting = false
local cds: { [string]: number } = {}
local cdLen: { [string]: number } = {}
local predictedAt: { [Model]: number } = {}
local training: string? = nil

------------------------------------------------------------------------
-- 카메라 흔들림
------------------------------------------------------------------------
-- 카메라가 순간 다가섰다 돌아온다 (흘리기·반격의 손맛)
local fovBase: number? = nil
local function fovPunch(delta: number, time: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	fovBase = fovBase or cam.FieldOfView
	local base = fovBase :: number
	cam.FieldOfView = base + delta
	game:GetService("TweenService"):Create(cam, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = base }):Play()
end

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
	-- 사람: 비무대 위끼리, 또는 둘 다 안전한 곳 밖이고 PvP를 켠 사이
	local me = myRoot()
	local myChar0 = player.Character
	if me and myChar0 then
		local meRing = onRing(me.Position)
		local meField = not Config.inSafe(me.Position) and myChar0:GetAttribute("PvpOff") ~= true
		if meRing or meField then
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p.Character
				local r = c and c:FindFirstChild("HumanoidRootPart")
				if p ~= player and c and r and r:IsA("BasePart") and c:GetAttribute("Dead") ~= true then
					local ok = (meRing and onRing(r.Position)) or (meField and not Config.inSafe(r.Position) and c:GetAttribute("PvpOff") ~= true)
					if ok then
						table.insert(list, c)
					end
				end
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
local function aim(): number?
	local root = myRoot()
	local cam = workspace.CurrentCamera
	if not root or not cam then
		return nil
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
	return best and bestScore or nil
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
	-- 강타는 연달아 못 쓴다
	if slot == "H" and now < (cds.H or 0) and char:GetAttribute("TestInf") ~= true then
		return
	end
	if slot == "H" then
		cds.H = now + Config.HEAVY_CD
		cdLen.H = Config.HEAVY_CD
	end
	if slot == "E" or slot == "R" or slot == "G" or slot == "X" then
		if not unlocked(slot) then
			UI.toast(string.format("🔒 %s: 숙련도 %d에 열려요", move.name, Config.SKILL_UNLOCK[slot]))
			return
		end
		local inf = char:GetAttribute("TestInf") == true
		if now < (cds[slot] or 0) and not inf then
			return
		end
		local chi = char:GetAttribute("Chi")
		if type(chi) == "number" and chi < (move.chi or 0) and not inf then
			UI.toast(string.format("내공이 부족해요 (🌀 %d 필요)", move.chi or 0))
			return
		end
		cds[slot] = inf and 0 or now + (move.cd or 0) * (style.cdMult or 1) * (1 - (state and state.manualCd or 0))
		cdLen[slot] = (move.cd or 1) * (style.cdMult or 1) * (1 - (state and state.manualCd or 0))
	end
	local speed = Config.actSpeed(style, state and state.gradeUp and state.gradeUp[style.id] or 0, char:GetAttribute("Buff") == "frenzy")
	local dur = move.dur / speed
	local gap = aim()
	seq += 1
	local mySeq = seq
	actSeq = mySeq
	actStart = now
	actDur = dur
	buffered = nil
	local first = move.hits and move.hits[1]
	Anim.play(char, move.pose, dur, { align = first and first.t / speed or nil })
	Fx.limbTrails(char, move.pose, dur, style.color, style.color2)
	Fx.cast(style.id, slot, char, dur)
	Sakura.cast(style.id, slot, char, dur)
	Drunk.cast(style.id, slot, char, dur)
	Reaper.cast(style.id, slot, char, dur)
	SkillFx.cast(style.id, slot, char, dur)
	local perfect = nextPerfect
	nextPerfect = false
	Request:FireServer("act", slot, mySeq, charge, perfect)
	if type(slot) == "number" or slot == "F" then
		earlyPresses = 0
		lastComboSlot = slot
		if perfect then
			perfectChain += 1
			local big = perfectChain >= Config.RHYTHM.chain
			Fx.text(root.Position + Vector3.new(0, 4.5, 0), big and string.format("연속 정타 ×%d", perfectChain) or "정타!", big and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(255, 235, 170), big and 30 or 22, 0.8)
			Fx.ring(root.Position - Vector3.new(0, 2.5, 0), style.color, 2, big and 12 or 7, 0.3)
			Fx.sound("ping", 0.35, big and 1.6 or 1.3)
		elseif slot ~= 1 then
			perfectChain = 0
		end
	end
	if slot == "F" then
		-- 각성 마무리: 크게 휘둘러 하늘로 띄운다
		UI.flash(style.color, 0.25)
		fovPunch(-6, 0.4)
		Fx.text(root.Position + Vector3.new(0, 6, 0), "✦ " .. move.name, style.color, 34, 1.2)
	end
	if move.hover then
		-- 공중 연격: 나도 공중에 머문다
		root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X * 0.3, move.hover, root.AssemblyLinearVelocity.Z * 0.3)
	end
	if slot == "C" then
		Fx.text(root.Position + Vector3.new(0, 5, 0), "반격!", Color3.fromRGB(255, 220, 120), 38)
		UI.flash(Color3.fromRGB(255, 230, 160), 0.2)
	elseif slot == "D" then
		Fx.afterimage(char, style.color, 0.35)
	end
	if move.dive then
		-- 잠깐 떠올랐다가 땅으로 내리꽂는다
		local diveStart = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local t = os.clock() - diveStart
			if not root.Parent or t > dur then
				conn:Disconnect()
				return
			end
			local v = root.AssemblyLinearVelocity
			if t < 0.12 then
				root.AssemblyLinearVelocity = Vector3.new(v.X * 0.5, 10, v.Z * 0.5)
			else
				root.AssemblyLinearVelocity = Vector3.new(v.X * 0.3, -move.dive, v.Z * 0.3)
			end
		end)
		task.delay((first and first.t or 0.3) / speed, function()
			if actSeq == mySeq then
				local feet = root.Position - Vector3.new(0, 2.6, 0)
				Fx.ring(feet + Vector3.new(0, 0.3, 0), style.color, 3, 24, 0.45)
				Fx.ring(feet + Vector3.new(0, 0.4, 0), Color3.new(1, 1, 1), 2, 14, 0.3)
				Fx.dust(feet, 4)
				Fx.sound("heavy", 0.9, 0.55)
				shake(1)
			end
		end)
	end
	local look = flat(root.CFrame.LookVector)
	-- 상대가 조금 떨어져 있으면 한 걸음에 파고든다 (거리를 좁히며 친다)
	local close = 0
	if gap and gap > 4.5 and not move.teleport and not move.proj and move.hits and #move.hits > 0 then
		close = math.min(gap - 3.5, 7)
	end
	local lunge = (move.lunge or 0) + close
	if lunge > 0 and not move.teleport then
		push(look * (lunge / 0.16), 0.16)
		if close > 2 then
			Fx.afterimage(char, style.color, 0.25)
		end
	end
	if move.jump then
		root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, move.jump, root.AssemblyLinearVelocity.Z)
	end
	if slot == "X" and style.scythe then
		-- 혈월만겸: 붉은 달이 뜨는 컷씬 (대사 없이) 동안 무적, 컷씬이 걷히면 핏빛 초승달이 쏟아진다
		Reaper.superCut(char, ((move.mech and move.mech.cut) or 1.4) / speed, move.name, shake)
	elseif slot == "X" and style.soju then
		-- 취선만권: 1초 컷씬 (대사 없이) 동안 점점 빨라지는 앞구르기, 컷씬이 걷히면 와다다다
		Drunk.superCut(char, ((move.mech and move.mech.cut) or 1) / speed, move.name, shake)
		Fx.skillAura(char, style.color, style.color2, dur, true)
	elseif slot == "G" or slot == "X" then
		UI.cinematic((slot == "X" and "초 오의 · " or "") .. move.name, style.color, dur)
		if slot == "X" and style.fans then
			Sakura.superIntro(char)
		end
		-- 오의: 화면이 한순간 뒤집히고 집중선이 몰려들며, 시야가 좁혀졌다가 터진다
		UI.ultFrame(style.color, style.color2)
		fovPunch(-10, 0.55)
		Fx.skillAura(char, style.color, style.color2, math.max(1.2, dur), true)
		if move.mech and slot == "X" then
			Fx.skillAura(char, style.color, style.color2, math.max(2, dur), true)
		elseif move.mech then
			Ults.intro(style.id, char)
		else
			Fx.ult(style.id, char, dur)
		end
		shake(1.2)
		tint(style.color, 0.25, dur)
		-- 오의: 화면이 확 좁아졌다가 (집중) 넓게 풀린다
		local cam = workspace.CurrentCamera
		if cam then
			local base = cam.FieldOfView
			pcall(function()
				local tw = TweenService:Create(cam, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = base - 12 })
				tw:Play()
				task.delay(0.22, function()
					TweenService:Create(cam, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { FieldOfView = base }):Play()
				end)
			end)
		end
	end
	-- E·R·강타: 기술 이름이 크게 떠오른다
	if slot == "E" or slot == "R" or slot == "H" then
		Fx.text(root.Position + Vector3.new(0, 6, 0), move.name, style.color2, slot == "H" and 30 or 38, 1.1)
	end
	-- 휘두르는 소리와 맞힘 알리기
	for i, h in ipairs(move.hits or {}) do
		task.delay(h.t / speed, function()
			if actSeq ~= mySeq or dead then
				return
			end
			Fx.sound("swing", 0.35, 1.05 + math.random() * 0.25)
			Fx.swing(style.id, char, (h.kb or 0) >= 20)
			local targets = query(h)
			Request:FireServer("hit", mySeq, i, targets)
			-- 바로 반응 (서버가 정하기 전에): 멈칫과 불꽃
			for _, m in ipairs(targets) do
				local r = rootOf(m)
				if r and m:GetAttribute("Guard") ~= true then
					predictedAt[m] = os.clock()
					local heavy = (h.kb or 0) >= 20 or (h.stun or 0) >= 0.6
					Fx.hitstop({ char, m }, heavy and 0.1 or 0.05)
					if heavy then
						-- 큰 한 방: 순간 번쩍이는 임팩트 프레임과 카메라 당김
						UI.flash(Color3.new(1, 1, 1), 0.18)
						fovPunch(-4, 0.25)
					end
					Fx.styleHit(style.id, r.Position:Lerp(root.Position, 0.35) + Vector3.new(0, 1, 0), heavy, look)
					Fx.sound(heavy and "heavy" or "hit", heavy and 0.9 or 0.6, heavy and 0.6 or 0.85 + math.random() * 0.2)
					shake(heavy and 0.9 or 0.35)
					if m:GetAttribute("Poise") ~= true then
						Anim.play(m, (math.random() < 0.5) and "flinch_l" or "flinch_r", 0.3)
					end
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
			nextPerfect = b.perfect == true
			startMove(b.slot, b.charge)
		end
	elseif buffered and os.clock() >= actStart + actDur * 0.7 and canAct() and type(buffered.slot) == "number" then
		local b = buffered
		buffered = nil
		nextPerfect = b.perfect == true
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
	-- 몸놀림 기술: 흘리기 직후 = 반격, 공중 = 낙하격, 대시 직후 = 돌진 일격
	local hum = myHum()
	if now - deflectAt < Config.ACTION_WINDOW.C then
		deflectAt = 0
		startMove("C")
		return
	end
	if hum and hum.FloorMaterial == Enum.Material.Air and not busy() then
		-- 띄운 적이 가까이 있으면 공중 연격 (세 번까지), 아니면 내리꽂는 낙하격
		local root = myRoot()
		local near = false
		if root then
			for m, at in pairs(launchedAt) do
				local r = m.Parent and rootOf(m :: Model)
				if r and now - at < 1.6 and (r.Position - root.Position).Magnitude < 12 then
					near = true
				end
			end
		end
		if near and airJ < 3 then
			airJ += 1
			aim()
			startMove("J")
			return
		elseif not airAttacked then
			airAttacked = true
			startMove("A")
			return
		end
	end
	if now - dashAt < Config.ACTION_WINDOW.D and not busy() then
		dashAt = 0
		startMove("D")
		return
	end
	-- 연타는 박자다: 앞 동작이 끝나 갈 즈음 눌러야 이어지고(딱 맞으면 連), 너무 일찍 마구 누르면 흐트러진다
	local R = Config.RHYTHM
	local meChar = myChar()
	local tier = meChar and tonumber(meChar:GetAttribute("Awaken")) or 0
	local function nextSlot(): any
		if lastComboSlot == #style.combo and tier >= 1 then
			return "F"
		elseif type(lastComboSlot) == "number" and lastComboSlot < #style.combo then
			return lastComboSlot + 1
		end
		return 1
	end
	local root = myRoot()
	if busy() then
		local frac = (now - actStart) / math.max(0.05, actDur)
		if frac < R.early then
			earlyPresses += 1
			if earlyPresses >= (R.earlyLimit or 2) and not comboBroken then
				comboBroken = true
				if root then
					Fx.text(root.Position + Vector3.new(0, 4, 0), "흐트러짐", Color3.fromRGB(200, 190, 180), 22, 0.6)
				end
			end
			return
		end
		if comboBroken or type(lastComboSlot) ~= "number" and lastComboSlot ~= "F" then
			return
		end
		buffered = { slot = nextSlot(), at = now, perfect = frac >= R.perfectFrom }
		return
	end
	local ended = actStart + actDur
	if comboBroken then
		-- 흐트러지면 잠깐 숨을 고른 뒤 처음부터
		if now < ended + R.breakLock then
			return
		end
		comboBroken = false
		lastComboSlot = nil
		perfectChain = 0
	end
	local slot: any = 1
	if (type(lastComboSlot) == "number" or lastComboSlot == "F") and now - ended <= Config.COMBO_WINDOW and lastComboSlot ~= "F" then
		slot = nextSlot()
		nextPerfect = now - ended <= R.late
	end
	startMove(slot)
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
	-- 카메라 기준으로 앞/뒤/옆을 가려 동작을 바꾼다 (뒤 = 공중제비, 옆 = 구르기)
	local cam = workspace.CurrentCamera
	local camLook = cam and flat(cam.CFrame.LookVector) or flat(root.CFrame.LookVector)
	local along = dir:Dot(camLook)
	local kind = "front"
	if hum.MoveDirection.Magnitude > 0.1 and along < -0.5 then
		kind = "back"
	elseif hum.MoveDirection.Magnitude > 0.1 and math.abs(along) <= 0.5 then
		kind = camLook:Cross(dir).Y < 0 and "right" or "left"
	end
	if kind == "front" then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
	else
		root.CFrame = CFrame.lookAt(root.Position, root.Position + camLook)
	end
	-- 빠를수록 멀리 (걸음 빠르기에 맞춰, 너무 멀지는 않게)
	local fast = math.clamp(hum.WalkSpeed / Config.WALK_SPEED, 1, Config.DASH_SPEED_MAX)
	push(dir * Config.DASH_SPEED * fast + (kind == "back" and Vector3.new(0, 18, 0) or Vector3.zero), Config.DASH_TIME)
	local pose = kind == "back" and "backflip" or (kind == "right" and "side_roll_r" or (kind == "left" and "side_roll_l" or "dash"))
	Anim.play(char, pose, kind == "front" and 0.28 or 0.4)
	Fx.afterimage(char, style and style.color or Color3.new(1, 1, 1), 0.3)
	Fx.limbTrails(char, pose, 0.35, style and style.color or Color3.new(1, 1, 1), style and style.color2 or Color3.new(1, 1, 1))
	Fx.ring(root.Position - Vector3.new(0, 2.5, 0), style and style.color or Color3.new(1, 1, 1), 2, 8, 0.3)
	Fx.sound("swing", 0.4, 1.6)
	Request:FireServer("dash", kind)
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

-- Shift를 누르고 있으면 달린다
local function setSprint(on: boolean)
	if sprinting == on then
		return
	end
	sprinting = on
	local char = myChar()
	if char then
		char:SetAttribute("Sprint", on or nil)
	end
	Request:FireServer("sprint", on)
end

local doEmote: (string) -> () = function(_id: string) end

------------------------------------------------------------------------
-- 입력
------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed or Cutscene.active or Gacha.active then
		return
	end
	local t = input.UserInputType
	local k = input.KeyCode
	if t == Enum.UserInputType.MouseButton1 then
		attack()
	elseif k == Enum.KeyCode.Z then
		heavyDown()
	elseif k == Enum.KeyCode.E then
		skill("E")
	elseif k == Enum.KeyCode.R then
		skill("R")
	elseif k == Enum.KeyCode.G then
		skill("G")
	elseif k == Enum.KeyCode.X then
		-- 초 오의 (초월 권법만)
		local st = myStyle()
		if st and st.skills.X then
			skill("X")
		end
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
	elseif k == Enum.KeyCode.V then
		Request:FireServer("mount")
	elseif k == Enum.KeyCode.One or k == Enum.KeyCode.Two or k == Enum.KeyCode.Three or k == Enum.KeyCode.Four then
		-- 몸짓: 서서 할 수 있는 동작
		if not busy() and not dead and not guarding and not training then
			local id = ({ [Enum.KeyCode.One] = "salute", [Enum.KeyCode.Two] = "taunt", [Enum.KeyCode.Three] = "kata", [Enum.KeyCode.Four] = "meditate" })[k]
			if id then
				doEmote(id)
			end
		end
	elseif k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.RightShift then
		setSprint(true)
	end
end)
UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.KeyCode == Enum.KeyCode.Z then
		heavyUp()
	elseif input.KeyCode == Enum.KeyCode.F then
		guardUp()
	elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		setSprint(false)
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
	X = function()
		local st = myStyle()
		if st and st.skills.X then
			skill("X")
		end
	end,
	potion = function()
		Request:FireServer("potion")
	end,
	train = function()
		UI.trainPress()
	end,
	mount = function()
		Request:FireServer("mount")
	end,
})

-- 땅에 닿으면 두 번 뛰기·낙하격을 되살린다. 세게 떨어지면 내려앉는 자세
local fallSpeed = 0
RunService.Heartbeat:Connect(function()
	local hum = myHum()
	local root = myRoot()
	if not hum or not root then
		return
	end
	if hum.FloorMaterial ~= Enum.Material.Air then
		airJumped = false
		airAttacked = false
		airJ = 0
		if fallSpeed > 55 and not busy() and not dead then
			local char = myChar()
			if char then
				Anim.play(char, "land", 0.35)
				Fx.dust(root.Position - Vector3.new(0, 2.6, 0), 2.5)
				shake(0.3)
			end
		end
		fallSpeed = 0
	else
		fallSpeed = math.max(fallSpeed, -root.AssemblyLinearVelocity.Y)
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

-- 처음 들어온 사람: 조작 안내 한 번 (첫 컷씬이 끝난 뒤)
local controlsShown = false
local function maybeControls()
	if controlsShown or not state or (state.seen and state.seen.controls) then
		return
	end
	controlsShown = true
	Cutscene.controls(function()
		Request:FireServer("seen", "controls")
	end)
end
local firstState = true
function handlers.state(data: any)
	state = data
	UI.setState(data)
	if firstState then
		firstState = false
		task.delay(2.5, function()
			if not Cutscene.active then
				maybeControls()
			end
		end)
	end
end

-- 중요한 장면: 서버가 고른 컷씬 (처음 한 번만)
function handlers.cutscene(data: any)
	local scene = Config.CUTSCENES[data.id]
	if not scene then
		return
	end
	if state and state.seen then
		state.seen[data.id] = true
	end
	Cutscene.play(scene, { m = data.m, at = data.at }, data.id == "intro" and maybeControls or nil)
end

-- 천층탑
function handlers.tower(data: any?)
	UI.setTower(data)
	if data then
		local boss = data.boss == true
		UI.banner(string.format("🗼 %d층", data.floor), boss and "👹 이 층의 주인이 기다린다" or "모든 적을 쓰러뜨려라", boss and Color3.fromRGB(255, 90, 70) or Color3.fromRGB(255, 210, 120))
	end
end
function handlers.towerClear(data: any)
	local extra = (data.scrolls or 0) > 0 and string.format("  📜 +%d", data.scrolls) or ""
	UI.banner(string.format("🗼 %d층 돌파!", data.floor), string.format("💰 +%s%s  ·  최고 %d층", Config.formatNumber(data.coins), extra, data.best), Color3.fromRGB(255, 210, 120))
	Fx.sound("ping", 0.8, 1.2)
end

-- 1.7판 구름 미궁
local lastMazeRoom = 0
function handlers.maze(data: any?)
	UI.setMaze(data)
	if not data then
		lastMazeRoom = 0
		return
	end
	if data.room ~= lastMazeRoom and not data.cleared then
		lastMazeRoom = data.room
		local sub = ({ wave = "모든 적을 쓰러뜨려라", trap = "차오르는 원을 피하며 적을 쓰러뜨려라", elite = "강한 수호자들이 지킨다", treasure = "보물 상자를 열어라 (T)", boss = "미궁의 주인이 기다린다" })[data.kind] or ""
		UI.banner(string.format("🌀 %d번째 방 · %s", data.room, tostring(data.name)), sub, Color3.fromRGB(190, 225, 255))
	end
end
function handlers.mazeClear(data: any)
	UI.banner("✓ " .. tostring(data.name) .. "을(를) 넘었다", "구름 문이 걷혔다 · 다리를 건너 다음 방으로", Color3.fromRGB(190, 255, 210))
	Fx.sound("ping", 0.7, 1.3)
end
function handlers.mazeDone(data: any)
	if data.first then
		UI.banner("🏆 구름 미궁을 다 넘었다!", string.format("💎 %s  💰 %s  📜 %d  📈 능력치 +%s", Config.formatNumber(data.gems or 0), Config.formatNumber(data.coins or 0), data.scrolls or 0, Config.formatNumber(data.stats or 0)), Color3.fromRGB(255, 220, 120))
	else
		UI.banner("🏆 구름 미궁을 다 넘었다!", string.format("다 넘은 보상은 %d분 뒤에 다시 받을 수 있어요", data.wait or 1), Color3.fromRGB(255, 220, 120))
	end
	Fx.sound("ping", 1, 1)
end

-- 1.7판 천상 레이드
function handlers.raid(data: any?)
	UI.setRaid(data)
end
function handlers.raidAlert(data: any)
	local purple = Color3.fromRGB(210, 130, 255)
	if data.stage == "warn" then
		UI.banner("⚔ 하늘이 갈라진다!", string.format("%d초 뒤 천공 투기장에 %s이(가) 내려온다 · 천궁의 ⚔ 문으로", data.warn or 0, tostring(data.name or "천겁")), purple)
		Fx.sound("heavy", 0.8, 0.5)
		shake(0.6)
	elseif data.stage == "on" then
		UI.banner("⚔ 레이드 · " .. tostring(data.name), string.format("함께 쓰러뜨려라 (체력 ×%.1f · %d분 안에)", 1 + Config.RAID.hpPer * ((data.n or 1) - 1), math.floor((data.life or 0) / 60)), purple)
		Fx.sound("heavy", 1, 0.4)
	elseif data.stage == "win" then
		UI.banner("🏆 천겁을 쓰러뜨렸다!", table.concat(data.top or {}, "   "), Color3.fromRGB(255, 220, 120))
	elseif data.stage == "fail" then
		UI.toast("☁ " .. tostring(data.name) .. "이(가) 하늘로 돌아갔다… 다음에 다시 내려온다")
	end
end
function handlers.raidReward(data: any)
	UI.toast(string.format("⚔ 레이드 보상 (%d위 · 기여 %.1f%%): 💎 %s  💰 %s  📜 %d  📈 능력치 +%s", data.rank or 0, (data.share or 0) * 100, Config.formatNumber(data.gems or 0), Config.formatNumber(data.coins or 0), data.scrolls or 0, Config.formatNumber(data.stats or 0)))
	Fx.sound("ping", 0.9, 1.1)
end

-- 운석 낙하: 하늘에서 불덩이가 떨어지고, 자리에 표시
function handlers.meteor(data: any)
	UI.banner("☄ 운석이 떨어진다!", data.island .. "에 운석 수호수가 나타난다", Color3.fromRGB(200, 150, 255))
	local at: Vector3 = data.at
	local warn = data.warn or 6
	Fx.ring(at - Vector3.new(0, 2.3, 0), Color3.fromRGB(200, 120, 255), 30, 2, warn)
	local ball = Instance.new("Part")
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(14, 14, 14)
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 160, 90)
	ball.Position = at + Vector3.new(160, 500, -120)
	ball.Parent = workspace
	local fire = Instance.new("Fire")
	fire.Size = 25
	fire.Heat = 20
	fire.Parent = ball
	TweenService:Create(ball, TweenInfo.new(warn, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = at }):Play()
	task.delay(warn, function()
		ball:Destroy()
		Fx.impact(at, Color3.fromRGB(255, 180, 120), 2.6)
		Fx.ring(at - Vector3.new(0, 2, 0), Color3.fromRGB(255, 160, 90), 4, 70, 0.7)
		Fx.debris(at, 16, 30, Color3.fromRGB(80, 60, 70))
		local r = rootOfChar()
		if r and (r.Position - at).Magnitude < 160 then
			shake(2.5)
		end
	end)
end

-- 심법 뽑기 결과
function handlers.manualDraw(results: any)
	UI.manualReveal(results)
	Fx.sound("ping", 0.9, 1.3)
end

function handlers.toast(msg: string)
	UI.toast(msg)
end

function handlers.open(data: any)
	UI.openPage(data.page, data)
end

-- 몸짓 (1 포권, 2 도발, 3 권법 시연, 4 명상)
local EMOTES = { salute = { "salute", 1.2 }, taunt = { "taunt", 1.4 }, kata = { "kata", 2.0 }, meditate = { "meditate", 3.0 } }
function handlers.emote(m: Model, id: any, isLocal: boolean?)
	local e = EMOTES[tostring(id)]
	if not e or not m or not m.Parent or (m == myChar() and not isLocal) then
		return
	end
	Anim.play(m, e[1], e[2], { fadeOut = 0.3 })
	local style = Config.STYLE_BY_ID[tostring(m:GetAttribute("Style") or "")]
	local r = rootOf(m)
	if style and r then
		if id == "kata" then
			Fx.limbTrails(m, "kata", e[2], style.color, style.color2)
			for k = 0, 3 do
				task.delay(0.15 + k * 0.4, function()
					Fx.swing(style.id, m, k == 3)
				end)
			end
		elseif id == "meditate" then
			Fx.ring(r.Position - Vector3.new(0, 2.5, 0), style.color, 2, 12, 1.2)
		elseif id == "salute" then
			Fx.ring(r.Position + r.CFrame.LookVector * 1.5, style.color2, 1, 5, 0.4, r.CFrame.LookVector)
		end
	end
end

doEmote = function(id: string)
	local char = myChar()
	if char then
		handlers.emote(char, id, true)
		Request:FireServer("emote", id)
	end
end

-- 심마 대련
function handlers.simma(m: Model)
	local r = m and rootOf(m)
	if r then
		Fx.text(r.Position + Vector3.new(0, 6, 0), "👁 심마", Color3.fromRGB(200, 80, 255), 40, 1.5)
		Fx.ring(r.Position - Vector3.new(0, 2.5, 0), Color3.fromRGB(190, 60, 255), 3, 30, 0.8)
		Fx.afterimage(m, Color3.fromRGB(120, 40, 180), 0.8)
	end
	UI.banner("👁 심마 대련", "마음속의 마귀를 꺾어라", Color3.fromRGB(200, 90, 255))
	shake(0.8)
end
-- 사부의 시험: 사부의 분신이 나타난다
function handlers.trial(data: any)
	local m = data.m
	local s = Config.STYLE_BY_ID[data.style]
	local color = s and s.color or Color3.fromRGB(255, 220, 120)
	local r = m and rootOf(m)
	if r then
		Fx.text(r.Position + Vector3.new(0, 6, 0), data.kind == "duel" and "⚔ 분신" or ("⚔ " .. (data.title or "시험")), color, 40, 1.5)
		Fx.ring(r.Position - Vector3.new(0, 2.5, 0), color, 3, 30, 0.8)
		Fx.afterimage(m, color, 0.8)
	end
	local K = data.kind and Config.TRIAL_KINDS[data.kind]
	UI.banner("⚔ " .. data.name .. "의 " .. (K and K.title or "시험"), K and K.goal or "꺾어라 · 흘리고(F) 반격하라", color)
	shake(0.8)
end
function handlers.trialProg(data: any?)
	UI.setTrial(data)
end
function handlers.simmaWin(data: any)
	UI.banner("👁 심마를 꺾었다!", string.format("모든 능력치 +%d", data.gain or 0), Color3.fromRGB(255, 220, 120))
	Fx.sound("ping", 0.9, 0.9)
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
	if style and data.slot ~= nil then
		Fx.cast(style.id, data.slot, m, data.dur)
		Sakura.cast(style.id, data.slot, m, data.dur)
		Drunk.cast(style.id, data.slot, m, data.dur)
		Reaper.cast(style.id, data.slot, m, data.dur)
		SkillFx.cast(style.id, data.slot, m, data.dur)
		local mv = Config.move(style.id, data.slot)
		for _, h in ipairs(mv and mv.hits or {}) do
			task.delay(h.t * (data.dur / math.max(0.05, mv.dur)), function()
				if m.Parent then
					Fx.swing(style.id, m, (h.kb or 0) >= 20)
				end
			end)
		end
	end
	local color = style and style.color or (data.unblockable and Color3.fromRGB(255, 60, 40) or Color3.fromRGB(235, 235, 245))
	Fx.limbTrails(m, data.pose, data.dur, color, style and style.color2 or Color3.new(1, 1, 1))
	local pos = modelPos(m)
	local me = myRoot()
	local near = pos and me and (pos - me.Position).Magnitude < 60
	-- 적이 휘두르기 직전: 무기가 반짝인다 (흘릴 때!), 붉으면 막을 수 없다
	if data.windup and pos then
		if data.unblockable then
			Fx.text(pos + Vector3.new(0, 5, 0), "⚠ 위험", Color3.fromRGB(255, 70, 50), 34, 1.5)
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
	if type(data.id) == "string" and string.sub(data.id, -1) == "X" and style then
		-- 남의 초 오의: 벚꽃이 쏟아지고 크게 흔들린다
		local r = rootOf(m)
		if r and style.fans then
			Sakura.petals(r.Position + Vector3.new(0, 3, 0), 40, 14, 2.2)
		end
		if near then
			shake(1)
		end
	elseif type(data.id) == "string" and string.sub(data.id, -1) == "G" and style then
		local gm = style.skills and style.skills.G
		if gm and gm.mech then
			Ults.intro(style.id, m)
		else
			Fx.ult(style.id, m, data.dur)
		end
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

-- 정타 반응: 맞힌 기술의 동작 이름으로 맞은 곳을 가늠한다 (차기는 머리·옆, 장·팔꿈치·무릎은 명치, 쓸기는 다리)
local reactTurn = 0
local function reactPose(pose: any, fromRight: boolean): string
	local name = type(pose) == "string" and pose or ""
	reactTurn += 1
	local side = fromRight and "_r" or "_l"
	if string.find(name, "low") or string.find(name, "sweep") or string.find(name, "flop") then
		return "hit_low"
	elseif string.find(name, "roundhouse") or string.find(name, "hook") or string.find(name, "spin") or string.find(name, "crescent") or string.find(name, "swing") then
		return "hit_spin" .. side
	elseif string.find(name, "kick") or string.find(name, "upper") or string.find(name, "snap") or string.find(name, "heel") then
		return "hit_head"
	elseif string.find(name, "palm") or string.find(name, "elbow") or string.find(name, "knee") or string.find(name, "push") or string.find(name, "fist") then
		return reactTurn % 3 == 0 and ("flinch" .. side) or "hit_gut"
	end
	-- 그 밖의 주먹: 머리·옆·몸을 돌아가며
	local k = reactTurn % 3
	return k == 0 and "hit_head" or (k == 1 and ("flinch" .. side) or "hit_gut")
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
		Polish.hit(data.style, pos, data.heavy == true, data.skill == true, dir)
		local predicted = mine and predictedAt[t] and os.clock() - predictedAt[t] < 0.6
		if not predicted then
			local hs = data.broken and 0.16 or (data.heavy and 0.1 or 0.055)
			-- 기술로 맞히면 한층 묵직하게: 더 긴 멈칫, 권법 빛깔의 타격 섬광, 내 화면이 울린다
			if data.skill then
				hs = math.max(hs, 0.075)
			end
			Fx.hitstop({ a, t }, hs)
			Fx.styleHit(data.style, pos, data.heavy, dir)
			if data.skill then
				local st = Config.STYLE_BY_ID[data.style or ""]
				Fx.blast(pos, st and st.color or Color3.new(1, 1, 1), st and st.color2 or Color3.new(1, 1, 1), data.heavy and 1.5 or 1)
				if mine then
					shake(data.heavy and 0.9 or 0.45)
					fovPunch(-2, 0.12)
				end
			end
			Fx.sound(data.heavy and "heavy" or "hit", data.heavy and 0.9 or 0.6, data.heavy and 0.6 or 0.9, if mine or hurt then nil else pos)
			if t and t:GetAttribute("Poise") ~= true and not data.steady then
				local fromRight = (aRoot and tRoot) and tRoot.CFrame.RightVector:Dot(aRoot.Position - tRoot.Position) > 0 or false
				local pose = data.broken and "knockdown" or (data.heavy and "hit_heavy" or reactPose(data.pose, fromRight))
				Anim.play(t, pose, data.broken and 0.7 or (data.heavy and 0.5 or 0.3))
			end
		elseif data.heavy and t and t:GetAttribute("Poise") ~= true then
			Anim.play(t, data.broken and "knockdown" or "hit_heavy", data.broken and 0.7 or 0.5)
		end
		if data.counter then
			Fx.text(pos + Vector3.new(0, 5.5, 0), "카운터!", Color3.fromRGB(255, 140, 60), 38, 1)
			if mine then
				fovPunch(-5, 0.3)
				UI.flash(Color3.fromRGB(255, 200, 140), 0.18)
			end
		end
		if data.strike then
			Fx.lightning(pos + Vector3.new(math.random(-4, 4), 60, math.random(-4, 4)), pos, Color3.fromRGB(255, 245, 140), 0.7)
		end
		local skillStyle = data.skill and Config.STYLE_BY_ID[data.style or ""]
		local col = data.crit and Color3.fromRGB(255, 220, 80) or (hurt and Color3.fromRGB(255, 90, 80) or (skillStyle and skillStyle.color2:Lerp(Color3.new(1, 1, 1), 0.3) or Color3.new(1, 1, 1)))
		Fx.text(pos + Vector3.new(0, 2, 0), (data.crit and "치명 " or "") .. tostring(math.floor((data.dmg or 0) + 0.5)), col, data.crit and 34 or 26)
		if data.broken then
			Fx.text(pos + Vector3.new(0, 5, 0), "파훼!", Color3.fromRGB(255, 200, 80), 40)
			Fx.ring(pos, Color3.fromRGB(255, 200, 80), 2, 18, 0.45)
			if mine or hurt then
				shake(1.6)
				UI.flash(Color3.fromRGB(255, 220, 140), 0.35)
			end
		end
		if hurt and data.steady then
			-- 전투력 차이: 맞아도 끄떡없다
			Fx.text(pos + Vector3.new(0, 4, 0), "끄떡없다", Color3.fromRGB(200, 220, 255), 24, 0.8)
			shake(0.2)
		elseif hurt then
			shake(data.heavy and 1.4 or 0.6)
			UI.flash(Color3.fromRGB(255, 40, 30), data.heavy and 0.3 or 0.12)
		elseif mine and data.heavy and not predicted then
			shake(0.9)
		end
	elseif kind == "aura" then
		-- 호신강기: 전투력 차이가 너무 커서 약한 적의 공격이 몸에 닿기도 전에 튕겨 나간다
		local ts = t and Config.STYLE_BY_ID[tostring(t:GetAttribute("Style") or "")]
		local c = ts and ts.color or Color3.fromRGB(255, 230, 160)
		Fx.hitstop({ a }, 0.08)
		if tRoot then
			Fx.ring(tRoot.Position, c, 3, 11, 0.35, dir)
			Fx.ring(tRoot.Position - Vector3.new(0, 2.5, 0), Color3.new(1, 1, 1), 2, 9, 0.3)
		end
		Fx.spark(pos, c, 1.4, 8)
		Fx.sound("deflect", 0.5, 1.5)
		Fx.text(pos + Vector3.new(0, 4, 0), "호신강기", c, 30, 0.9)
		if a then
			Anim.play(a, "parried", 0.45)
		end
	elseif kind == "block" or kind == "guardbreak" then
		Fx.hitstop({ a, t }, 0.05)
		Fx.spark(pos, Color3.fromRGB(230, 230, 255), 1, 6)
		Fx.sound("block", 0.5, 0.75)
		if t then
			Anim.play(t, "block_hit", 0.3)
		end
		if kind == "guardbreak" then
			Fx.text(pos + Vector3.new(0, 4, 0), "막기가 깨졌다!", Color3.fromRGB(255, 200, 80), 32)
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
		Fx.text(pos + Vector3.new(0, 4, 0), data.counter and "되받아치기!" or "흘리기!", Color3.fromRGB(170, 230, 255), 36)
		if t and t == myChar() then
			deflectAt = os.clock()
			Fx.text(pos + Vector3.new(0, 7, 0), "지금 클릭 → 반격", Color3.fromRGB(255, 220, 120), 26, 1)
		end
		-- 흘린 쪽은 몸을 돌려 바깥으로 쓸어 내고, 친 쪽은 헛힘에 지나쳐 휘청인다
		local side = (type(data.side) == "number" and data.side < 0) and -1 or 1
		if t then
			Anim.play(t, side > 0 and "parry_r" or "parry_l", 0.6, { fadeOut = 0.2 })
			local ts = Config.STYLE_BY_ID[tostring(t:GetAttribute("Style") or "")]
			Fx.parryArc(t, side, ts and ts.color or Color3.fromRGB(190, 235, 255))
			Fx.limbTrails(t, side > 0 and "parry_r" or "parry_l", 0.5, ts and ts.color or Color3.fromRGB(190, 235, 255), Color3.new(1, 1, 1))
		end
		if a then
			Anim.play(a, "parried", Config.DEFLECT_STAGGER + 0.3, { fadeOut = 0.2 })
		end
		if mine or hurt then
			shake(0.7)
			UI.flash(Color3.fromRGB(170, 220, 255), 0.25)
			tint(Color3.fromRGB(170, 210, 255), 0.35, 0.18)
			fovPunch(-8, 0.35)
		end
	elseif kind == "clash" then
		-- 격돌: 주먹과 주먹이 부딪힌다
		Fx.hitstop({ a, t }, 0.14)
		Fx.spark(pos, Color3.fromRGB(255, 240, 200), 2.4, 16)
		Fx.ring(pos, Color3.new(1, 1, 1), 2, 16, 0.4, dir)
		Fx.ring(pos - Vector3.new(0, 2, 0), Color3.fromRGB(255, 220, 160), 2, 22, 0.5)
		Fx.sound("heavy", 1, 0.45)
		Fx.text(pos + Vector3.new(0, 5, 0), "격돌!", Color3.fromRGB(255, 240, 200), 40)
		if mine or hurt then
			shake(1.5)
			UI.flash(Color3.new(1, 1, 1), 0.35)
		end
	elseif kind == "dodge" then
		if t then
			local tt = Config.STYLE_BY_ID[tostring(t:GetAttribute("Style") or "")]
			Fx.afterimage(t, tt and tt.color or Color3.fromRGB(200, 200, 255), 0.35)
		end
		Fx.text(pos + Vector3.new(0, 3, 0), data.drunk and "취보!" or "회피", Color3.fromRGB(220, 220, 255), 26)
	end
end

function handlers.broken(m: Model, secs: number)
	Anim.play(m, "broken", secs)
	local p = modelPos(m)
	if p then
		Fx.text(p + Vector3.new(0, 5, 0), "파훼!", Color3.fromRGB(255, 200, 80), 40)
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
		UI.setBoss(nil)
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

-- 적이 경직을 버텨 낸다 (곧 되받아친다)
function handlers.poise(m: Model)
	local r = m and m:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		Fx.text(r.Position + Vector3.new(0, 5, 0), "버팀!", Color3.fromRGB(255, 160, 80), 30, 1.2)
		Fx.ring(r.Position - Vector3.new(0, 2.5, 0), Color3.fromRGB(255, 150, 70), 2, 12, 0.4)
	end
end

function handlers.dash(m: Model, kind: any)
	if m == myChar() then
		return
	end
	local pose = kind == "back" and "backflip" or (kind == "right" and "side_roll_r" or (kind == "left" and "side_roll_l" or "dash"))
	Anim.play(m, pose, kind == "front" and 0.28 or 0.4)
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

function handlers.trainPose(m: Model, kind0: string?)
	local ti = kind0 and Config.Training[kind0]
	local kind = ti and ti.ui or kind0
	if kind == "waterfall" or kind == "breathing" then
		Anim.setLoop(m, "meditate", 2)
	elseif kind == "mabo" then
		Anim.setLoop(m, "horse_stance", 2.4)
	elseif kind == "ironpalm" then
		Anim.setLoop(m, "palm_strike", 1.0)
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
		end, data.hard == true)
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
		if data.hidden then
			-- 숨은 권법: 하늘이 갈라진다
			UI.cinematic("🔓 " .. s.name, s.color, 2.6)
			UI.banner("🔓 숨겨진 권법 " .. s.icon .. " " .. s.name, string.format("[%s] %s", s.grade, s.hanja), s.color)
			local char = myChar()
			if char then
				Fx.ult(s.id, char, 1.8)
			end
			shake(1.4)
			Fx.sound("ping", 1, 0.6)
		else
			UI.banner(s.icon .. " " .. s.name .. " 입문!", string.format("[%s] %s · 권법 창에서 바꿔 쓸 수 있다", s.grade, s.hanja), s.color)
		end
		UI.closeWindow()
		UI.setGuide(nil)
	end
end

-- 권법 승급 (깨달음)
function handlers.breakthrough(data: any)
	local s = Config.STYLE_BY_ID[data.style]
	if not s then
		return
	end
	UI.cinematic("⬆ " .. s.name .. " · " .. data.step, s.color, 2.2)
	UI.banner("⬆ " .. data.step .. "!", string.format("%s 등급이 [%s]로 올랐다", s.name, data.grade), Config.GRADE_COLOR[data.grade] or s.color)
	local char = myChar()
	if char then
		Fx.ult(s.id, char, 1.6)
	end
	shake(1.2)
	Fx.sound("ping", 1, 0.7)
end

-- 권법마다 다른 기술 장치의 연출
local ultsReady = false
function handlers.skillfx(data: any)
	if not ultsReady then
		ultsReady = true
		Ults.init({ shake = shake, flash = UI.flash, tint = tint })
		Awake.init({ shake = shake, tint = tint })
		Reaper.init({ shake = shake, tint = tint })
	end
	if (data.fx == "gravity" or data.fx == "prism" or data.fx == "sun" or data.fx == "tide" or data.fx == "time") and Ults.variant(data) then
		return
	elseif data.kind == "strike" and data.fx == "sword" then
		Ults.run({ kind = "sword", at = data.at, radius = data.radius, style = data.style })
		return
	elseif data.kind == "pillar" and data.fx == "spear" then
		Ults.spear(data.at, data.dir or Vector3.new(0, 0, -1), data.style)
		return
	elseif Sakura.handles(data.kind) then
		Sakura.run(data)
		return
	elseif Drunk.handles(data) then
		Drunk.run(data)
		return
	elseif Awake.handles(data) then
		Awake.run(data)
		return
	elseif Reaper.handles(data) then
		Reaper.run(data)
		return
	elseif Ults.handles(data.kind) then
		Ults.run(data)
		return
	end
	Fx.mech(data)
	if data.kind == "drop" or data.kind == "beam" or data.kind == "freeze" then
		local r = myRoot()
		if r and data.at and (r.Position - data.at).Magnitude < 60 then
			shake(data.kind == "freeze" and 0.6 or 1.3)
		end
	end
end

-- 개천신권: 별이 떨어진다
function handlers.star(data: any)
	local s = Config.STYLE_BY_ID[tostring(data.style)]
	if s and s.fx == "celestial" then
		-- 천제신권 천위: 하늘에서 빛의 검
		Ults.run({ kind = "sword", at = data.at, radius = 7, style = data.style })
	else
		Fx.starfall(data.at, data.style)
	end
end

-- 이야기
function handlers.dialog(data: any)
	UI.dialog(data)
	Fx.sound("ping", 0.4, 1.2)
end

function handlers.storyDone(data: any)
	local parts = {}
	if data.coins and data.coins > 0 then
		table.insert(parts, "💰 +" .. Config.formatNumber(data.coins))
	end
	if data.stats and data.stats > 0 then
		table.insert(parts, string.format("모든 능력치 +%d", data.stats))
	end
	UI.banner("📜 " .. data.title .. " 완료", table.concat(parts, "  ") .. (data.next and ("  ·  다음: " .. data.next) or ""), Color3.fromRGB(255, 200, 110))
	Fx.sound("ping", 0.8, 1)
end

-- 다음 이야기가 왔다: 받으면 목표가 보인다
function handlers.storyOffer(data: any)
	task.delay(1.2, function()
		UI.dialog({ who = "📜 새 이야기 · " .. tostring(data.chapter) .. "장", title = data.title, text = data.text, accept = true })
	end)
end

-- 로벅스 상품을 샀다
function handlers.premium(data: any)
	local it = Config.PREMIUM_BY_ID[data.id]
	if it then
		UI.banner("💎 " .. it.name, "고마워요! 지금부터 바로 적용돼요", Color3.fromRGB(255, 210, 90))
		Fx.sound("ping", 0.9, 1.1)
	end
end

function handlers.storyProg(data: any)
	if state then
		state.prog = data.prog
		UI.refreshWorld(state)
	end
end

function handlers.found(data: any)
	local s = Config.STYLE_BY_ID[data.style]
	-- 사부를 처음 만나는 장면: 사부의 한마디
	local m = Config.MASTERS[data.style]
	if m and m.quote then
		Cutscene.play({ who = m.name, lines = { m.quote } }, { at = m.at })
	end
	UI.banner("🏯 사부를 찾았다: " .. data.master, (s and (s.icon .. " " .. s.name .. "의 주인 · ") or "") .. data.region .. " · 하늘로 빛기둥이 솟았다", s and s.color or nil)
	Fx.sound("ping", 0.7, 0.9)
end

function handlers.fragment(data: any)
	UI.banner(string.format("📖 비급 조각 %d / %d", data.n, data.total), data.n >= data.total and "조각이 하나로 모였다..." or "옛 고수의 글씨가 희미하게 빛난다", Color3.fromRGB(255, 230, 160))
	Fx.sound("ping", 0.8, 1.1)
end

function handlers.trialWin(data: any)
	local s = Config.STYLE_BY_ID[data.style]
	UI.cinematic("⚔ 시험 통과", s and s.color or Color3.fromRGB(255, 220, 120), 1.6)
	UI.banner("⚔ " .. data.master .. "의 시험 통과!", "사부 곁에서 T를 눌러 " .. (s and s.name or "") .. "을(를) 배워라", s and s.color or nil)
end

function handlers.mastery(data: any)
	local s = Config.STYLE_BY_ID[data.style]
	if data.awaken and s then
		-- 각성! 하늘로 빛이 솟고 화면이 갈라진다
		local a = Config.AWAKEN[data.awaken]
		UI.cinematic(a.mark .. " " .. s.name .. " " .. a.name, s.color, 2.2)
		UI.banner(a.mark .. " " .. a.name .. "!", data.awaken == 1 and "기술이 세지고, 연타 다섯 번째 '" .. s.finisher.name .. "'가 열렸다" or "모든 기술이 세지고, 그림자 메아리가 기술을 한 번 더 되풀이한다", s.color)
		local char = myChar()
		if char then
			Fx.ult(s.id, char, 1.6)
		end
		shake(1.2)
		Fx.sound("ping", 0.9, 0.8)
		return
	end
	UI.banner(string.format("%s 숙련 %d", s and s.name or "", data.lv), data.unlocked and ("새 기술: " .. data.unlocked) or nil, s and s.color or nil)
	Fx.sound("ping", 0.6, 1.5)
end

-- 완전 각성: 그림자 메아리가 같은 기술을 되풀이한다
function handlers.echo(data: any)
	local m = data.m
	if m and m.Parent then
		Fx.echo(m, data.style, data.slot, data.dur)
	end
end

-- 見切り: 맞기 직전에 피했다 (시간이 멈춘 듯)
function handlers.pdodge(data: any)
	local m, a = data.m, data.a
	local r = m and rootOf(m)
	if r then
		Fx.text(r.Position + Vector3.new(0, 5, 0), "간파!", Color3.fromRGB(180, 230, 255), 38, 1.2)
		Fx.ring(r.Position - Vector3.new(0, 2.5, 0), Color3.fromRGB(180, 230, 255), 2, 18, 0.5)
		Fx.afterimage(m, Color3.fromRGB(180, 230, 255), 0.5)
	end
	if a then
		Fx.hitstop({ a }, 0.35)
	end
	if m == myChar() then
		deflectAt = os.clock()
		fovPunch(-10, 0.5)
		tint(Color3.fromRGB(160, 200, 255), 0.4, 0.45)
		UI.flash(Color3.fromRGB(200, 230, 255), 0.2)
		Fx.sound("deflect", 0.8, 0.7)
	end
end

function handlers.reward(data: any)
	local st = (data.stats or 0) > 0 and ("  📈 능력치 +" .. Config.formatNumber(data.stats)) or ""
	UI.toast(string.format("%s 쓰러뜨림  💰 +%d  숙련 +%d%s%s", data.name, data.coins, data.xp, st, (data.gems or 0) > 0 and string.format("  💠 +%d", data.gems) or ""))
	if data.boss then
		UI.banner("🏆 " .. data.name .. " 격파!", string.format("💰 +%d%s", data.coins, st), Color3.fromRGB(255, 210, 120))
	end
end

local bossNow: Model? = nil
function handlers.boss(m: Model?)
	UI.setBoss(m)
	bossNow = m
	-- 그 보스와 처음 맞붙을 때: 짧은 컷씬 (보는 동안은 맞지 않는다)
	local id = m and m:GetAttribute("TypeId")
	local key = type(id) == "string" and ("boss_" .. id) or nil
	if m and key and Config.CUTSCENES[key] and state and state.seen and not state.seen[key] then
		state.seen[key] = true
		Request:FireServer("seen", key)
		Cutscene.play(Config.CUTSCENES[key], { m = m })
	end
end

-- 배경 음악: 탑 / 보스 / 있는 곳
task.spawn(function()
	while true do
		task.wait(1)
		pcall(function()
			local r = rootOfChar()
			local key = "default"
			if UI.towerActive then
				key = bossNow and bossNow.Parent and "boss" or "tower"
			elseif bossNow and bossNow.Parent and bossNow:GetAttribute("Dead") ~= true then
				key = "boss"
			elseif r and r.Position.Y > Config.SKY.y - 300 then
				key = "skyworld"
			elseif r then
				local reg = UI.regionAt(r.Position)
				key = reg and reg.id or "default"
			end
			Music.set(key)
		end)
	end
end)

function handlers.bossPhase(m: Model, name: string, phase: number?)
	local ph = phase or 2
	UI.cinematic("👹 " .. name .. " · " .. ph .. "단계", Color3.fromRGB(255, 60, 40), 1.6)
	UI.banner("👹 " .. name .. " · " .. ph .. "단계", ph >= 3 and "마지막 발악! 모든 패턴을 쓴다" or "분노했다! 빨라지고 새 패턴이 열린다", Color3.fromRGB(255, 80, 60))
	local r = m and rootOf(m)
	if r then
		Fx.ring(r.Position - Vector3.new(0, 2.5, 0), Color3.fromRGB(255, 60, 40), 4, 60, 0.7)
		Fx.afterimage(m, Color3.fromRGB(255, 40, 30), 0.8)
	end
	shake(1.4)
	UI.bossPhase(ph)
end

-- 보스가 패턴 이름을 외친다
function handlers.bossCall(data: any)
	local r = data.m and rootOf(data.m)
	if r then
		local scale = tonumber(data.m:GetAttribute("Scale")) or 2
		Fx.text(r.Position + Vector3.new(0, 6 + scale * 2, 0), "⚠ " .. data.name, Color3.fromRGB(255, 120, 90), 36, 1.2)
	end
end

function handlers.afterimage(m: Model)
	if m and m.Parent then
		Fx.afterimage(m, Color3.fromRGB(255, 50, 40), 0.5)
	end
end

function handlers.duel(data: any)
	UI.toast(string.format("⚔ %s: %s 승, %s 패", data.ring == false and "들판 PvP" or "비무대", data.winner, data.loser))
end

-- 1.9판: 업적을 이뤘다
function handlers.ach(data: any)
	local a = Config.ACH_BY_ID[data.id]
	if not a then
		return
	end
	local parts = {}
	if a.coins then
		table.insert(parts, "💰 +" .. Config.formatNumber(a.coins))
	end
	if a.gems then
		table.insert(parts, "💎 +" .. Config.formatNumber(a.gems))
	end
	if a.scrolls then
		table.insert(parts, "📜 +" .. a.scrolls)
	end
	if a.title then
		table.insert(parts, "칭호 「" .. a.title .. "」 (🏆 업적에서 달기)")
	end
	UI.banner("🏆 업적: " .. a.icon .. " " .. a.name, table.concat(parts, "  "), Config.ACH_COLOR[a.kind] or Color3.fromRGB(255, 220, 120))
	Fx.sound("ping", 0.9, 1.25)
end

-- 1.9판: 누군가 환생한다. 빛기둥이 솟고, 몸이 한순간 하얗게 비었다가 환생 빛깔로 다시 차오른다
function handlers.rebirth(data: any)
	local m: Model? = data.m
	local r = m and rootOf(m)
	if not r then
		return
	end
	local col = Config.REBIRTH.colors[data.n or 1] or Color3.new(1, 1, 1)
	local base = r.Position - Vector3.new(0, 2.8, 0)
	local pillar = Instance.new("Part")
	pillar.Anchored = true
	pillar.CanCollide = false
	pillar.CanQuery = false
	pillar.CanTouch = false
	pillar.Material = Enum.Material.Neon
	pillar.Color = col
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Transparency = 0.15
	pillar.Size = Vector3.new(400, 1, 1)
	pillar.CFrame = CFrame.new(base + Vector3.new(0, 200, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pillar.Parent = workspace
	TweenService:Create(pillar, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(400, 14, 14) }):Play()
	task.delay(0.5, function()
		TweenService:Create(pillar, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = Vector3.new(400, 0.2, 0.2), Transparency = 1 }):Play()
	end)
	task.delay(2.2, function()
		pillar:Destroy()
	end)
	for i = 0, 2 do
		task.delay(i * 0.25, function()
			Fx.ring(base + Vector3.new(0, 0.3, 0), col, 4, 40 + i * 14, 1.1)
		end)
	end
	Fx.burst("spark", r.Position, col, 50, 2.4)
	Fx.flash(r.Position, col, 50, 6, 1.6)
	Fx.sound("deflect", 1, 0.45, r.Position)
	if m ~= myChar() then
		UI.toast(string.format("♻ %s, %s 환생!", data.name or "", Config.REBIRTH.names[data.n or 1] or ""))
	end
end
function handlers.rebirthDone(data: any)
	UI.banner(string.format("♻ %s 환생", data.name or ""), string.format("삼류로 다시 태어났다 · 피해·체력 +%d%% · 얻는 능력치 +%d%% · %s의 경지가 열렸다 · 💰 +%s", data.power or 0, data.gain or 0, data.realm or "", Config.formatNumber(data.coins or 0)), Config.REBIRTH.colors[data.n or 1])
	shake(1.2)
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
		local cmax = char:GetAttribute("ChiMax")
		UI.bars(hp, mx, type(po) == "number" and po or 0, type(pm) == "number" and pm or 100, type(chi) == "number" and chi or 0, type(cmax) == "number" and cmax or Config.CHI_MAX)
	end
	local style = myStyle()
	if not style then
		UI.styleLine("🥋 권법이 없다", Color3.fromRGB(230, 220, 200), "")
		return
	end
	local now = os.clock()
	local info: { [string]: any } = {
		M1 = { name = style.combo[1].name },
		H = { name = style.heavy.name, cd = math.max(0, ((cds.H or 0) - now) / Config.HEAVY_CD) },
		Q = { name = "대시", cd = math.max(0, (dashAt + (style.dashCd or Config.DASH_CD) - now) / (style.dashCd or Config.DASH_CD)) },
		F = { name = guarding and "막는 중" or "막기·흘리기" },
		P = { name = string.format("금창약 %d", state and state.potions or 0) },
	}
	for _, slot in ipairs({ "E", "R", "G", "X" }) do
		local sk = style.skills[slot]
		if sk then
			local left = (cds[slot] or 0) - now
			local need = sk.chi or 100
			info[slot] = { name = sk.name, locked = not unlocked(slot), cd = left > 0 and left / (cdLen[slot] or 1) or ((slot == "G" or slot == "X") and type(chi) == "number" and chi < need and 1 - chi / need or 0) }
		end
	end
	UI.slots(info)
	-- 권법 장치 표시
	local stacks = ""
	if style.id == "taeheo" then
		stacks = "기류 " .. string.rep("●", tonumber(char:GetAttribute("Flow")) or 0) .. string.rep("○", 3 - (tonumber(char:GetAttribute("Flow")) or 0))
	elseif style.id == "maehwa" or style.petals then
		local n = tonumber(char:GetAttribute("Petal")) or 0
		local cap = style.petalMax or 20
		stacks = n >= cap and (style.petals and "🌸 천앵만개 준비! (Z)" or "🌸 만개 준비! (Z)") or string.format("%s %d / %d", style.petals and "벚꽃" or "꽃잎", n, cap)
	elseif style.noBlock then
		stacks = "🍾 만취 · 막기 ✕ · 흘리기만 ○"
	elseif style.bloodPact then
		local php, pmx = tonumber(char:GetAttribute("Hp")) or 0, tonumber(char:GetAttribute("MaxHp")) or 1
		local k = 1 + style.bloodPact * (1 - math.clamp(php / math.max(1, pmx), 0, 1))
		stacks = string.format("🩸 피의 계약 · 피해 ×%.2f", k)
	elseif style.hurtPulse then
		local n = math.clamp(tonumber(char:GetAttribute("HurtN")) or 0, 0, style.hurtPulse.every)
		stacks = string.format("🗿 불괴 %d / %d (맞으면 쌓인다)", n, style.hurtPulse.every)
	elseif style.shadowEcho then
		stacks = "👤 영각 · 그림자가 한 번 더 찬다"
	elseif style.deflectWave then
		stacks = "🌊 역류 · 흘리면 물결이 터진다"
	elseif style.chargeEvery then
		local n = math.clamp(tonumber(char:GetAttribute("Charge")) or 0, 0, style.chargeEvery)
		stacks = "전하 " .. string.rep("⚡", n) .. string.rep("·", style.chargeEvery - n)
	elseif style.pulse then
		local n = math.clamp(tonumber(char:GetAttribute("Pulse")) or 0, 0, style.pulse.every)
		local mark = ({ gravity = "◆", prism = "✦", eclipse = "☀", tide = "≈", time = "◷" })[style.pulse.kind] or "✦"
		stacks = (({ gravity = "중압 ", prism = "창세 ", eclipse = "일월 ", tide = "파도 ", time = "정지 " })[style.pulse.kind] or "") .. string.rep(mark, n) .. string.rep("·", style.pulse.every - n)
	elseif style.charge and chargeStart then
		stacks = string.format("용기 모으는 중 %d%%", math.floor(math.clamp((now - chargeStart) / (style.charge or 1.5), 0, 1) * 100))
	end
	local buff = char:GetAttribute("Buff")
	if buff == "ironshirt" then
		stacks ..= "  🔔 철포삼"
	elseif buff == "sway" then
		stacks ..= "  🍶 취보"
	end
	local tierNow = tonumber(char:GetAttribute("Awaken")) or 0
	if perfectChain >= 2 then
		stacks ..= string.format("  정타 ×%d", perfectChain)
	end
	if comboBroken then
		stacks ..= "  (흐트러짐)"
	end
	UI.styleLine((tierNow > 0 and (Config.AWAKEN[tierNow].mark .. " ") or "") .. style.icon .. " " .. style.name, style.color, stacks)
end)

-- 몸동작 점검: 내 몸의 관절을 몇 개 붙잡았는지 (못 붙잡으면 동작이 안 보인다)
task.delay(6, function()
	local char = player.Character
	if char then
		local n = Anim.jointCount(char)
		print(string.format("[권왕] 몸동작 관절 %d / 11개 연결", n))
		if n < 8 then
			UI.toast(string.format("⚠ 몸동작 관절을 %d개만 찾았어요. 동작이 제대로 안 보일 수 있어요", n))
		end
	end
end)

Request:FireServer("hello")
