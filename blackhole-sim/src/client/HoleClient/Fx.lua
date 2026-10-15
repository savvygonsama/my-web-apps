-- Fx (ModuleScript, HoleClient 아래)
-- 블랙홀 모양, 빨려 들어가는 연출, 떠오르는 숫자, 효과음.
-- 블랙홀은 서버가 캐릭터에 붙인 크기(HoleR)와 색(HoleSkin)을 보고 각자 화면에서 그린다.
--   검은 구멍 → 어두운 원반 → 빛나는 테두리 → 소용돌이 팔 세 개 → 도는 강착 원반 → 안으로 빨려 드는 빛 알갱이

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Fx = {}

local FLAT = CFrame.Angles(0, 0, math.rad(90))
local BLACK = Color3.new(0, 0, 0)

local folder = Instance.new("Folder")
folder.Name = "HoleFX"
folder.Parent = workspace

local function fxPart(size: Vector3, color: Color3, material: Enum.Material, shape: Enum.PartType?, transparency: number?): Part
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material
	p.Transparency = transparency or 0
	p.Parent = folder
	return p
end

------------------------------------------------------------------------
-- 효과음
------------------------------------------------------------------------
local SOUNDS = {
	pop = "rbxasset://sounds/electronicpingshort.wav",
	whoosh = "rbxasset://sounds/swordlunge.wav",
	slash = "rbxasset://sounds/swordslash.wav",
}

function Fx.sound(name: string, volume: number?, pitch: number?)
	local id = SOUNDS[name]
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.4
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 3)
end

------------------------------------------------------------------------
-- 블랙홀 모양
------------------------------------------------------------------------
type Hole = {
	char: Model,
	radius: number,
	skin: number,
	parts: { Part },
	rim: Part,
	disk: Part,
	void: Part,
	core: Part,
	arms: { { part: Part, t: number, arm: number } },
	ring: { { part: Part, a: number, h: number } },
	motes: { { part: Part, phase: number } },
	light: PointLight,
}

local holes: { [Model]: Hole } = {}

local function destroyHole(h: Hole)
	for _, p in ipairs(h.parts) do
		p:Destroy()
	end
end

local function buildHole(char: Model, r: number, skinIndex: number): Hole
	local skin = Config.BIGBANG_SKINS[skinIndex] or Config.BIGBANG_SKINS[1]
	local parts: { Part } = {}
	local function add(p: Part): Part
		table.insert(parts, p)
		return p
	end
	local d = r * 2
	local rim = add(fxPart(Vector3.new(0.12, d * 1.14, d * 1.14), skin.a, Enum.Material.Neon, Enum.PartType.Cylinder, 0.15))
	local disk = add(fxPart(Vector3.new(0.14, d * 1.05, d * 1.05), skin.a:Lerp(BLACK, 0.82), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder))
	local void = add(fxPart(Vector3.new(0.16, d * 0.9, d * 0.9), BLACK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder))
	local core = add(fxPart(Vector3.new(0.18, d * 0.45, d * 0.45), BLACK, Enum.Material.Neon, Enum.PartType.Cylinder))
	local light = Instance.new("PointLight")
	light.Color = skin.a
	light.Range = math.min(60, 6 + r * 1.5)
	light.Brightness = 1.5
	light.Parent = rim

	-- 소용돌이 팔: 테두리에서 가운데로 휘어 들어간다
	local arms = {}
	local segs = 9
	for arm = 0, 2 do
		for i = 0, segs - 1 do
			local t = i / (segs - 1)
			local color = skin.a:Lerp(skin.b, t)
			local width = math.max(0.15, r * 0.09 * (1 - t * 0.6))
			local p = add(fxPart(Vector3.new(width, 0.08, math.max(0.3, r * 0.28 * (1 - t * 0.5))), color, Enum.Material.Neon, nil, 0.1 + t * 0.6))
			table.insert(arms, { part = p, t = t, arm = arm })
		end
	end
	-- 강착 원반: 테두리 위를 빠르게 도는 빛 덩어리
	local ring = {}
	local n = 18
	for i = 0, n - 1 do
		local size = math.max(0.25, r * 0.08)
		local p = add(fxPart(Vector3.new(size * 1.8, size * 0.6, size), (i % 2 == 0) and skin.a or skin.b, Enum.Material.Neon, nil, 0.05))
		table.insert(ring, { part = p, a = i / n * math.pi * 2, h = (i % 3) * 0.12 })
	end
	-- 빨려 드는 빛 알갱이
	local motes = {}
	for i = 0, 11 do
		local p = add(fxPart(Vector3.new(1, 1, 1) * math.max(0.15, r * 0.05), skin.b, Enum.Material.Neon, Enum.PartType.Ball))
		table.insert(motes, { part = p, phase = i / 12 })
	end
	return {
		char = char,
		radius = r,
		skin = skinIndex,
		parts = parts,
		rim = rim,
		disk = disk,
		void = void,
		core = core,
		arms = arms,
		ring = ring,
		motes = motes,
		light = light,
	}
end

-- 블랙홀이 있는 바닥 자리 (모든 구역의 바닥 높이는 0)
function Fx.holeCenter(char: Model): Vector3?
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	return Vector3.new(root.Position.X, 0, root.Position.Z)
end

local function updateHole(h: Hole, t: number)
	local center = Fx.holeCenter(h.char)
	if not center then
		return
	end
	local r = h.radius
	local base = CFrame.new(center)
	h.rim.CFrame = base * CFrame.new(0, 0.04, 0) * FLAT
	h.disk.CFrame = base * CFrame.new(0, 0.06, 0) * FLAT
	h.void.CFrame = base * CFrame.new(0, 0.08, 0) * FLAT
	h.core.CFrame = base * CFrame.new(0, 0.1, 0) * FLAT
	local skin = Config.BIGBANG_SKINS[h.skin] or Config.BIGBANG_SKINS[1]
	if skin.rainbow then
		local c = Color3.fromHSV((t * 0.15) % 1, 0.8, 1)
		h.rim.Color = c
		h.light.Color = c
	end
	-- 테두리가 숨 쉬듯 빛난다
	h.rim.Transparency = 0.1 + (math.sin(t * 3) + 1) * 0.1
	local spin = t * 1.4
	for _, a in ipairs(h.arms) do
		local ang = spin + a.arm * (math.pi * 2 / 3) + a.t * 2.4
		local rad = r * (1.0 - a.t * 0.8)
		local pos = center + Vector3.new(math.cos(ang) * rad, 0.12, math.sin(ang) * rad)
		a.part.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(ang), 0, math.cos(ang)))
	end
	for _, q in ipairs(h.ring) do
		local ang = q.a + t * 2.6
		local rad = r * 1.08
		local pos = center + Vector3.new(math.cos(ang) * rad, 0.25 + q.h + math.sin(t * 4 + q.a * 3) * 0.08 * r, math.sin(ang) * rad)
		q.part.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(ang), 0, math.cos(ang)))
	end
	for _, m in ipairs(h.motes) do
		local k = (t * 0.6 + m.phase) % 1
		local ang = m.phase * 20 + k * 6
		local rad = r * 1.2 * (1 - k)
		m.part.CFrame = CFrame.new(center + Vector3.new(math.cos(ang) * rad, 0.3 + (1 - k) * r * 0.2, math.sin(ang) * rad))
		m.part.Transparency = k * 0.8
	end
end

local function syncHole(char: Model)
	local r = char:GetAttribute("HoleR")
	local skin = char:GetAttribute("HoleSkin")
	local h = holes[char]
	if type(r) ~= "number" or not char.Parent then
		if h then
			destroyHole(h)
			holes[char] = nil
		end
		return
	end
	local skinIndex = type(skin) == "number" and skin or 1
	if h and h.radius == r and h.skin == skinIndex then
		return
	end
	if h then
		destroyHole(h)
	end
	holes[char] = buildHole(char, r, skinIndex)
end

local function watchCharacter(char: Model)
	syncHole(char)
	char:GetAttributeChangedSignal("HoleR"):Connect(function()
		syncHole(char)
	end)
	char:GetAttributeChangedSignal("HoleSkin"):Connect(function()
		syncHole(char)
	end)
	char.AncestryChanged:Connect(function()
		if not char.Parent then
			syncHole(char)
		end
	end)
end

local function watchPlayer(player: Player)
	if player.Character then
		watchCharacter(player.Character)
	end
	player.CharacterAdded:Connect(function(c)
		watchCharacter(c :: Model)
	end)
end

------------------------------------------------------------------------
-- 빨려 들어가는 연출: 모든 화면에서, 누가 삼켰든 그 블랙홀로 소용돌이치며 들어간다
------------------------------------------------------------------------
type Sucked = { part: BasePart, offset: Vector3, height: number, size: Vector3, tr: number }

local function suck(model: Model)
	local id = model:GetAttribute("EatenBy")
	if type(id) ~= "number" then
		return
	end
	local eater = Players:GetPlayerByUserId(id)
	local char = eater and eater.Character
	local center = char and Fx.holeCenter(char)
	if not center then
		return
	end
	local list: { Sucked } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local off = d.Position - center
			table.insert(list, { part = d, offset = Vector3.new(off.X, 0, off.Z), height = off.Y, size = d.Size, tr = d.Transparency })
		elseif d:IsA("ParticleEmitter") or d:IsA("PointLight") or d:IsA("SpotLight") then
			(d :: any).Enabled = false
		end
	end
	local start = os.clock()
	local duration = 0.5
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = math.min(1, (os.clock() - start) / duration)
		local c = Fx.holeCenter(char :: Model) or center
		local ease = t * t
		local spin = CFrame.Angles(0, ease * 5, 0)
		for _, s in ipairs(list) do
			local p = s.part
			if p.Parent then
				local off = spin * (s.offset * (1 - ease))
				p.CFrame = CFrame.new(c + off + Vector3.new(0, s.height * (1 - ease) - ease * 2, 0)) * CFrame.Angles(ease * 6, ease * 4, 0)
				p.Size = s.size * math.max(0.05, 1 - ease * 0.95)
				p.Transparency = s.tr + (1 - s.tr) * ease
			end
		end
		if t >= 1 then
			conn:Disconnect()
			for _, s in ipairs(list) do
				s.part.LocalTransparencyModifier = 1
			end
		end
	end)
end

local function watchObject(model: Instance)
	if not model:IsA("Model") then
		return
	end
	if model:GetAttribute("EatenBy") then
		suck(model :: Model)
	end
	model:GetAttributeChangedSignal("EatenBy"):Connect(function()
		suck(model :: Model)
	end)
end

------------------------------------------------------------------------
-- 떠오르는 숫자와 터지는 빛
------------------------------------------------------------------------
function Fx.popup(pos: Vector3, text: string, color: Color3, size: number)
	local anchor = fxPart(Vector3.new(0.2, 0.2, 0.2), color, Enum.Material.Neon, nil, 1)
	anchor.CFrame = CFrame.new(pos)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 220, 0, 50)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 3000
	bb.Parent = anchor
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextSize = size
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.2
	l.Text = text
	l.Parent = bb
	TweenService:Create(anchor, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = pos + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(l, TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1)
end

function Fx.burst(pos: Vector3, color: Color3, count: number, speed: number, size: number)
	local anchor = fxPart(Vector3.new(0.2, 0.2, 0.2), color, Enum.Material.Neon, nil, 1)
	anchor.CFrame = CFrame.new(pos)
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.3, 0.7)
	pe.Speed = NumberRange.new(speed * 0.5, speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = 4
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(color)
	pe.Parent = anchor
	pe:Emit(count)
	Debris:AddItem(anchor, 1.2)
end

-- 바닥에 퍼지는 빛 고리
function Fx.ring(pos: Vector3, color: Color3, fromD: number, toD: number, life: number)
	local p = fxPart(Vector3.new(0.2, fromD, fromD), color, Enum.Material.Neon, Enum.PartType.Cylinder, 0.2)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * FLAT
	TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.2, toD, toD), Transparency = 1 }):Play()
	Debris:AddItem(p, life + 0.05)
end

-- 빛기둥
function Fx.pillar(pos: Vector3, color: Color3, height: number, width: number, life: number)
	local p = fxPart(Vector3.new(height, width, width), color, Enum.Material.Neon, Enum.PartType.Cylinder, 0.1)
	p.CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0)) * FLAT
	TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(height, 0.1, 0.1), Transparency = 1 }):Play()
	Debris:AddItem(p, life + 0.05)
end

------------------------------------------------------------------------
-- 시작
------------------------------------------------------------------------
function Fx.start()
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	task.spawn(function()
		local objects = workspace:WaitForChild("Objects")
		for _, m in ipairs(objects:GetChildren()) do
			watchObject(m)
		end
		objects.ChildAdded:Connect(watchObject)
	end)
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for char, h in pairs(holes) do
			if not char.Parent then
				destroyHole(h)
				holes[char] = nil
			else
				updateHole(h, t)
			end
		end
	end)
end

return Fx
