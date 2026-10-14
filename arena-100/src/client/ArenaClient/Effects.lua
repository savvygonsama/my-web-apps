-- Effects (ModuleScript, ArenaClient 아래)
-- 베기 궤적, 피해 숫자, 치명타, 필살기, 화면 흔들림, 효과음.
-- 전부 내 화면에만 그리는 효과라 다른 사람에게는 보이지 않는다.

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))
local GradeStyle = require(ReplicatedStorage:WaitForChild("GradeStyle"))

local Effects = {}

local folder: Instance = workspace
local getChar: () -> (BasePart?, Humanoid?) = function()
	return nil, nil
end

local RAINBOW_COLORS = {
	Color3.fromRGB(255, 80, 80),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(90, 230, 110),
	Color3.fromRGB(70, 200, 255),
	Color3.fromRGB(150, 100, 255),
	Color3.fromRGB(255, 90, 200),
}

local SOUNDS = {
	slash = "rbxasset://sounds/swordslash.wav",
	lunge = "rbxasset://sounds/swordlunge.wav",
	unsheath = "rbxasset://sounds/unsheath.wav",
	ping = "rbxasset://sounds/electronicpingshort.wav",
}

function Effects.init(fxFolder: Instance, charGetter: () -> (BasePart?, Humanoid?))
	folder = fxFolder
	getChar = charGetter
end

function Effects.sound(name: string, volume: number?, pitch: number?)
	local id = SOUNDS[name]
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.5
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 3)
end

------------------------------------------------------------------------
-- 화면 흔들림: 카메라 오프셋을 잠깐 흔든다
------------------------------------------------------------------------
local shakePower = 0
local shakeUntil = 0
local shakeConn: RBXScriptConnection? = nil

function Effects.shake(power: number, duration: number)
	local now = os.clock()
	if now + duration > shakeUntil then
		shakeUntil = now + duration
	end
	shakePower = math.max(shakePower, power)
	if shakeConn then
		return
	end
	shakeConn = RunService.RenderStepped:Connect(function()
		local _, hum = getChar()
		local t = os.clock()
		if t >= shakeUntil then
			if hum then
				hum.CameraOffset = Vector3.zero
			end
			shakePower = 0
			if shakeConn then
				shakeConn:Disconnect()
				shakeConn = nil
			end
			return
		end
		if hum then
			local p = shakePower * math.clamp((shakeUntil - t) / 0.25, 0.2, 1)
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * p, (math.random() - 0.5) * p, (math.random() - 0.5) * p)
		end
	end)
end

------------------------------------------------------------------------
-- 기본 도구
------------------------------------------------------------------------
local function fxPart(size: Vector3, cf: CFrame, color: Color3, transparency: number?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = size
	p.CFrame = cf
	p.Transparency = transparency or 0.3
	p.Parent = folder
	return p
end

local function fade(p: Instance, time: number, goal: { [string]: any }?)
	local g = goal or {}
	g.Transparency = 1
	TweenService:Create(p, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), g):Play()
	Debris:AddItem(p, time + 0.05)
end

-- 반달 모양 궤적. cf 기준 XZ 평면에서 0도는 앞(-Z), +각도는 오른쪽(+X)
local function arc(cf: CFrame, radius: number, fromDeg: number, toDeg: number, segs: number, width: number, color: Color3 | { Color3 }, life: number)
	for i = 0, segs - 1 do
		local a0 = math.rad(fromDeg + (toDeg - fromDeg) * i / segs)
		local a1 = math.rad(fromDeg + (toDeg - fromDeg) * (i + 1) / segs)
		local p0 = cf * Vector3.new(math.sin(a0) * radius, 0, -math.cos(a0) * radius)
		local p1 = cf * Vector3.new(math.sin(a1) * radius, 0, -math.cos(a1) * radius)
		local mid = (p0 + p1) / 2
		local len = (p1 - p0).Magnitude + 0.15
		local t = i / math.max(segs - 1, 1)
		local w = width * (1 - math.abs(t * 2 - 1) * 0.65)
		local c: Color3
		if typeof(color) == "table" then
			c = (color :: { Color3 })[(i % #(color :: { Color3 })) + 1]
		else
			c = color :: Color3
		end
		local up = cf.UpVector
		local seg = fxPart(Vector3.new(w, 0.12, len), CFrame.lookAt(mid, p1, up), c, 0.25)
		fade(seg, life + t * 0.05, { Size = Vector3.new(w * 0.2, 0.05, len) })
	end
end

function Effects.burst(pos: Vector3, color: Color3, count: number, speed: number?, size: number?, texture: string?)
	local anchor = fxPart(Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos), color, 1)
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.25, 0.55)
	pe.Speed = NumberRange.new((speed or 20) * 0.5, speed or 20)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = 6
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size or 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(color)
	if texture then
		pe.Texture = texture
		pe.RotSpeed = NumberRange.new(-200, 200)
		pe.Rotation = NumberRange.new(0, 360)
	end
	pe.Parent = anchor
	pe:Emit(count)
	Debris:AddItem(anchor, 1)
end

function Effects.flash(pos: Vector3, color: Color3, size: number, life: number?)
	local ball = fxPart(Vector3.new(1, 1, 1) * size * 0.3, CFrame.new(pos), color, 0.1, Enum.PartType.Ball)
	fade(ball, life or 0.25, { Size = Vector3.new(1, 1, 1) * size })
end

local function ring(pos: Vector3, color: Color3, fromD: number, toD: number, life: number, thickness: number?)
	local disc = fxPart(
		Vector3.new(thickness or 0.3, fromD, fromD),
		CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		0.3,
		Enum.PartType.Cylinder
	)
	fade(disc, life, { Size = Vector3.new(thickness or 0.3, toD, toD) })
end

------------------------------------------------------------------------
-- 피해 숫자. 치명타는 크게 튀어나오고 불꽃이 터진다
------------------------------------------------------------------------
local HIT_STYLE = {
	hit = { color = Color3.fromRGB(255, 248, 230), size = 24 },
	crit = { color = Color3.fromRGB(255, 170, 40), size = 34 },
	hurt = { color = Color3.fromRGB(255, 70, 70), size = 26 },
	block = { color = Color3.fromRGB(170, 185, 210), size = 18 },
	poison = { color = Color3.fromRGB(120, 255, 110), size = 20 },
}

function Effects.hits(list: { any })
	for _, h in ipairs(list) do
		local style = HIT_STYLE[h.kind] or HIT_STYLE.hit
		local isCrit = h.kind == "crit"
		local pos = h.pos + Vector3.new((math.random() - 0.5) * 2, 0, (math.random() - 0.5) * 2)
		local anchor = fxPart(Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos), style.color, 1)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 220, 0, 60)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.Parent = anchor
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextSize = style.size
		label.TextColor3 = style.color
		label.TextStrokeTransparency = 0.1
		if h.kind == "block" then
			label.Text = "🛡" .. h.text
		elseif h.kind == "poison" then
			label.Text = "☠" .. h.text
		else
			label.Text = isCrit and ("💥" .. h.text) or h.text
		end
		-- 맞을 때마다 작은 불꽃
		if h.kind == "hit" then
			Effects.burst(h.pos, h.color or Color3.fromRGB(255, 230, 180), 5, 14, 0.3)
		elseif h.kind == "poison" then
			Effects.burst(h.pos, Color3.fromRGB(120, 255, 110), 4, 6, 0.4)
		end
		label.Parent = bb
		if isCrit then
			label.TextColor3 = Color3.new(1, 1, 1)
			local g = Instance.new("UIGradient")
			g.Color = ColorSequence.new(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 90, 30))
			g.Rotation = 90
			g.Parent = label
			local sc = Instance.new("UIScale")
			sc.Scale = 2.2
			sc.Parent = label
			TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			Effects.burst(h.pos, Color3.fromRGB(255, 190, 70), 18, 28, 0.6)
			Effects.flash(h.pos, Color3.fromRGB(255, 240, 200), 5, 0.2)
		end
		local info = TweenInfo.new(isCrit and 0.9 or 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(anchor, info, { Position = pos + Vector3.new(0, isCrit and 4 or 3, 0) }):Play()
		TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, isCrit and 0.55 or 0.35), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
		Debris:AddItem(anchor, isCrit and 1 or 0.8)
	end
end

------------------------------------------------------------------------
-- 무기별 베기 궤적
------------------------------------------------------------------------
-- 속성별 덧붙임 연출. power(0~1)가 클수록 많고 크다
local function lightningBolt(target: Vector3, color: Color3, height: number, width: number)
	local top = target + Vector3.new((math.random() - 0.5) * 6, height, (math.random() - 0.5) * 6)
	local prev = top
	local segs = 7
	for i = 1, segs do
		local t = i / segs
		local p = top:Lerp(target, t)
		if i < segs then
			p += Vector3.new((math.random() - 0.5) * 3, 0, (math.random() - 0.5) * 3)
		end
		local mid = (prev + p) / 2
		local len = (p - prev).Magnitude
		local seg = fxPart(Vector3.new(width, width, len), CFrame.lookAt(mid, p), (i % 2 == 0) and Color3.new(1, 1, 1) or color, 0)
		fade(seg, 0.18)
		prev = p
	end
	Effects.flash(target, color, 4, 0.15)
end

local function flyingBits(origin: Vector3, color: Color3, count: number, size: Vector3, material: Enum.Material, speed: number, life: number, gravity: boolean)
	for _ = 1, count do
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit
		local bit = fxPart(size, CFrame.new(origin) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6), color, 0.05)
		bit.Material = material
		local goal = origin + dir * speed * life + (gravity and Vector3.new(0, -6, 0) or Vector3.zero)
		TweenService:Create(bit, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = goal,
			Orientation = Vector3.new(math.random(-360, 360), math.random(-360, 360), 0),
			Transparency = 1,
			Size = size * 0.3,
		}):Play()
		Debris:AddItem(bit, life + 0.05)
	end
end

local motifFx: { [string]: (any, Vector3, CFrame, number) -> () } = {}

motifFx.flame = function(style, hit, _cf, p)
	Effects.burst(hit, style.primary, 10 + math.floor(p * 30), 18, 1 + p * 1.5, style.motif.tex)
	for i = 1, 1 + math.floor(p * 3) do
		local pos = hit + Vector3.new((math.random() - 0.5) * 4, -2, (math.random() - 0.5) * 4)
		local pillar = fxPart(Vector3.new(4 + p * 6, 1, 1), CFrame.new(pos + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), (i % 2 == 0) and style.secondary or style.primary, 0.2, Enum.PartType.Cylinder)
		fade(pillar, 0.35, { Size = Vector3.new(8 + p * 8, 0.1, 0.1), Position = pos + Vector3.new(0, 5, 0) })
	end
end

motifFx.frost = function(style, hit, _cf, p)
	flyingBits(hit, style.glow, 5 + math.floor(p * 14), Vector3.new(0.25, 0.9, 0.25) * (1 + p), Enum.Material.Glass, 14, 0.4, false)
	ring(hit - Vector3.new(0, 2.4, 0), Color3.fromRGB(220, 245, 255), 1, 6 + p * 8, 0.35, 0.2)
end

motifFx.storm = function(style, hit, _cf, p)
	for _ = 1, 1 + math.floor(p * 3) do
		lightningBolt(hit + Vector3.new((math.random() - 0.5) * 4, -1, (math.random() - 0.5) * 4), style.primary, 18 + p * 20, 0.25 + p * 0.3)
	end
	if p > 0.3 then
		Effects.shake(0.15 + p * 0.3, 0.1)
	end
end

motifFx.nature = function(style, hit, _cf, p)
	flyingBits(hit, style.primary, 6 + math.floor(p * 14), Vector3.new(0.5, 0.06, 0.35) * (1 + p), Enum.Material.Neon, 10, 0.7, true)
	Effects.burst(hit, style.secondary, 8 + math.floor(p * 12), 8, 0.5 + p)
end

motifFx.shadow = function(style, hit, _cf, p)
	Effects.burst(hit, style.primary, 12 + math.floor(p * 20), 8, 1.5 + p * 2, style.motif.tex)
	Effects.flash(hit, style.secondary, 3 + p * 4, 0.2)
end

motifFx.holy = function(style, hit, _cf, p)
	local pillar = fxPart(Vector3.new(30, 2 + p * 3, 2 + p * 3), CFrame.new(hit + Vector3.new(0, 13, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.new(1, 1, 1), 0.2, Enum.PartType.Cylinder)
	fade(pillar, 0.35, { Size = Vector3.new(30, 0.1, 0.1) })
	Effects.burst(hit, style.glow, 10 + math.floor(p * 20), 16, 0.6 + p)
	ring(hit - Vector3.new(0, 2.4, 0), style.glow, 2, 8 + p * 10, 0.4, 0.2)
end

motifFx.blood = function(style, hit, _cf, p)
	flyingBits(hit, style.primary, 6 + math.floor(p * 16), Vector3.new(0.3, 0.3, 0.3) * (1 + p), Enum.Material.Neon, 9, 0.5, true)
	arc(CFrame.new(hit) * CFrame.Angles(0, math.random() * 6, math.rad(70)), 2.5 + p * 2, -70, 70, 7, 0.4 + p * 0.5, style.secondary, 0.2)
end

motifFx.void = function(style, hit, _cf, p)
	local sphere = fxPart(Vector3.new(6, 6, 6) * (1 + p), CFrame.new(hit), Color3.fromRGB(10, 0, 20), 0.2, Enum.PartType.Ball)
	sphere.Material = Enum.Material.ForceField
	sphere.Color = style.secondary
	fade(sphere, 0.3, { Size = Vector3.new(0.3, 0.3, 0.3) })
	ring(hit, style.secondary, 10 + p * 10, 1, 0.3, 0.3)
	Effects.burst(hit, style.primary, 10 + math.floor(p * 16), 6, 1.2 + p, style.motif.tex)
end

motifFx.star = function(style, hit, _cf, p)
	flyingBits(hit, Color3.new(1, 1, 1), 5 + math.floor(p * 12), Vector3.new(0.35, 0.35, 0.35) * (1 + p), Enum.Material.Neon, 16, 0.35, false)
	Effects.burst(hit, style.glow, 14 + math.floor(p * 20), 22, 0.4 + p * 0.5)
end

motifFx.crystal = function(style, hit, _cf, p)
	local n = 6 + math.floor(p * 8)
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local pos = hit + Vector3.new(math.cos(a), 0, math.sin(a)) * (2 + p * 2)
		local shard = fxPart(Vector3.new(0.4, 1.6 + p * 1.5, 0.4), CFrame.new(pos) * CFrame.Angles(0, -a, math.rad(25)), (i % 2 == 0) and style.secondary or style.glow, 0.1)
		shard.Material = Enum.Material.Glass
		fade(shard, 0.4, { Position = pos + Vector3.new(math.cos(a), 0.6, math.sin(a)) * 2 })
	end
end

-- 무기별 베기 궤적. 등급마다 색, 겹 수, 굵기, 속성 연출이 다르다
function Effects.swing(data: any)
	local root = getChar()
	if not root then
		return
	end
	local g = data.grade or 1
	local style = GradeStyle.get(g)
	local p = style.power
	local colors: { Color3 } = style.rainbow and RAINBOW_COLORS or { style.glow, style.secondary, style.primary }
	local plain: Color3 = style.glow
	local w = 1 + p * 1.6
	local layers = 1 + g // 25
	local life = 0.18 + p * 0.12
	local cf = root.CFrame * CFrame.new(0, 0.4, 0)
	local look = root.CFrame.LookVector
	local t = data.typeId
	local hit = root.Position + look * math.min(data.range * 0.6, 6)

	local function layered(baseCf: CFrame, radius: number, from: number, to: number, segs: number, width: number)
		for L = 0, layers - 1 do
			local extra = CFrame.Angles(0, math.rad(L * 9), math.rad(L * 7))
			local c: Color3 | { Color3 } = colors
			if L > 0 then
				c = colors[(L % #colors) + 1]
			end
			arc(baseCf * extra, radius * (1 + L * 0.14), from, to, segs, width * (1 - L * 0.15), c, life + L * 0.05)
		end
	end

	if t == 1 then
		layered(cf * CFrame.Angles(0, 0, math.rad(90)), data.range * 0.6, -85, 85, 14, 1.5 * w)
		Effects.burst(root.Position + look * data.range * 0.6 - Vector3.new(0, 2.8, 0), Color3.fromRGB(210, 185, 140), 14, 18, 0.9)
		Effects.shake(0.25 + p * 0.3, 0.12)
		Effects.sound("slash", 0.55, 0.8)
	elseif t == 2 then
		layered(cf * CFrame.Angles(0, 0, math.rad(35)), 4.5, -70, 70, 10, 0.6 * w)
		layered(cf * CFrame.Angles(0, 0, math.rad(-35)), 4.5, 70, -70, 10, 0.6 * w)
		Effects.sound("slash", 0.35, 1.35)
	elseif t == 3 then
		local beam = fxPart(Vector3.new(0.4 * w, 0.4 * w, data.range), cf * CFrame.new(0, 0, -data.range / 2), plain, 0.05)
		fade(beam, 0.2, { Size = Vector3.new(0.05, 0.05, data.range * 1.15) })
		if g >= 30 then
			local outer = fxPart(Vector3.new(1.4 * w, 1.4 * w, data.range), cf * CFrame.new(0, 0, -data.range / 2), style.secondary, 0.55)
			fade(outer, 0.18)
		end
		layered(cf, data.range * 0.85, -22, 22, 7, 0.5 * w)
		Effects.flash(root.Position + look * data.range, plain, 2.5 * w, 0.15)
		Effects.sound("lunge", 0.4, 1.1)
	elseif t == 4 then
		layered(cf * CFrame.Angles(0, 0, math.rad(15)), 3.2, -80, 60, 8, 0.5 * w)
		layered(cf * CFrame.Angles(0, 0, math.rad(-20)), 3.6, 60, -80, 8, 0.4 * w)
		Effects.sound("slash", 0.3, 1.6)
	elseif t == 5 then
		layered(cf * CFrame.new(0, -0.6, 0), data.range * 0.85, 0, 360, 20, 1.0 * w)
		for _ = 1, 3 + math.floor(p * 6) do
			local pos = root.Position + Vector3.new((math.random() - 0.5) * 8, -1, (math.random() - 0.5) * 8)
			local wisp = fxPart(Vector3.new(0.5, 0.5, 0.5) * (1 + p), CFrame.new(pos), style.glow, 0.2, Enum.PartType.Ball)
			fade(wisp, 0.6, { Position = pos + Vector3.new(0, 4 + p * 4, 0) })
		end
		hit = root.Position
		Effects.sound("slash", 0.45, 0.65)
	else
		layered(cf * CFrame.new(0, -0.6, 0), data.range * 0.85, 0, 360, 22, 1.2 * w)
		layered(cf * CFrame.Angles(0, 0, math.rad(90)), data.range * 0.6, -85, 85, 14, 1.5 * w)
		Effects.shake(0.3, 0.1)
		Effects.sound("lunge", 0.5, 0.9)
		hit = root.Position
	end

	-- 등급의 속성 연출
	local fx = motifFx[style.motif.id]
	if fx and g >= 2 then
		fx(style, hit, cf, p)
	end
	-- 높은 등급일수록 더 얹는다
	Effects.burst(hit, plain, 4 + math.floor(p * 20), 14 + p * 14, 0.3 + p * 0.5, style.motif.tex)
	if g >= 40 then
		ring(root.Position - Vector3.new(0, 2.7, 0), style.secondary, 2, 8 + p * 16, 0.3, 0.2)
	end
	if g >= 60 then
		Effects.shake(0.1 + p * 0.15, 0.06)
	end
	if g >= 80 then
		local beam = fxPart(Vector3.new(40, 1.5 + p, 1.5 + p), CFrame.new(hit + Vector3.new(0, 18, 0)) * CFrame.Angles(0, 0, math.rad(90)), style.glow, 0.3, Enum.PartType.Cylinder)
		fade(beam, 0.3, { Size = Vector3.new(40, 0.1, 0.1) })
	end
	if data.crit then
		Effects.flash(hit, Color3.new(1, 1, 1), 6 + p * 8, 0.18)
		ring(hit, style.glow, 1, 10 + p * 12, 0.25, 0.3)
		Effects.sound("lunge", 0.6, 1.3)
		Effects.shake(0.35 + p * 0.4, 0.15)
	end
end

------------------------------------------------------------------------
-- 보스 내려찍기 착지
------------------------------------------------------------------------
function Effects.slam(data: any)
	ring(data.pos + Vector3.new(0, 0.3, 0), Color3.fromRGB(255, 90, 50), 4, data.radius * 2.3, 0.4, 0.5)
	Effects.burst(data.pos + Vector3.new(0, 1, 0), Color3.fromRGB(200, 170, 130), 30, 30, 1.2)
	local root = getChar()
	if root and (root.Position - data.pos).Magnitude < 40 then
		Effects.shake(0.9, 0.35)
	end
	Effects.sound("lunge", 0.7, 0.5)
end

------------------------------------------------------------------------
-- 필살기
------------------------------------------------------------------------
function Effects.ultimate(data: any)
	local root = getChar()
	local color: Color3 = data.color or Color3.new(1, 1, 1)
	local origin: Vector3 = data.origin
	local look: Vector3 = data.look
	local floorY = origin.Y - 2.9
	local t = data.typeId

	if t == 1 then
		-- 대지 가르기: 땅이 앞으로 쭉 갈라진다
		local n = 14
		local step = data.length / n
		for i = 1, n do
			task.delay(i * 0.018, function()
				local p = Vector3.new(origin.X, floorY, origin.Z) + look * (step * (i - 0.5))
				local crack = fxPart(Vector3.new(1.8, 0.3, step + 0.4), CFrame.lookAt(p, p + look), Color3.fromRGB(255, 120, 40), 0)
				fade(crack, 0.9, { Size = Vector3.new(0.4, 0.3, step + 0.4) })
				Effects.burst(p + Vector3.new(0, 1, 0), Color3.fromRGB(190, 160, 120), 6, 22, 1)
				local pillar = fxPart(Vector3.new(1.2, 6, 1.2), CFrame.new(p + Vector3.new(0, 3, 0)), color, 0.3)
				fade(pillar, 0.4, { Size = Vector3.new(0.2, 12, 0.2) })
			end)
		end
		task.delay(0.28, function()
			ring(Vector3.new(origin.X, floorY + 0.3, origin.Z) + look * data.length, color, 4, 26, 0.5)
		end)
		Effects.shake(1.2, 0.5)
		Effects.sound("lunge", 0.9, 0.55)
	elseif t == 2 then
		-- 칼날 폭풍: 내 주위를 칼날이 돌고 계속 베어 낸다
		local blades = {}
		for i = 1, 6 do
			blades[i] = fxPart(Vector3.new(0.4, 0.2, 4.5), CFrame.new(origin), color, 0.1)
		end
		local start = os.clock()
		local conn: RBXScriptConnection
		local lastArc = 0
		conn = RunService.Heartbeat:Connect(function()
			local r = getChar()
			local el = os.clock() - start
			if not r or el > data.duration then
				conn:Disconnect()
				for _, b in ipairs(blades) do
					fade(b, 0.2)
				end
				return
			end
			for i, b in ipairs(blades) do
				local a = el * 9 + i * (math.pi * 2 / 6)
				local p = r.Position + Vector3.new(math.cos(a) * data.radius * 0.6, 0.3 + math.sin(el * 6 + i) * 0.6, math.sin(a) * data.radius * 0.6)
				b.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a)))
			end
			if el - lastArc > 0.15 then
				lastArc = el
				arc(r.CFrame * CFrame.Angles(0, math.random() * math.pi * 2, math.rad(math.random(-30, 30))), data.radius * 0.8, -60, 60, 8, 0.8, color, 0.15)
			end
		end)
		Effects.shake(0.25, data.duration)
		for i = 0, 4 do
			task.delay(i * 0.5, function()
				Effects.sound("slash", 0.4, 1.2 + i * 0.05)
			end)
		end
	elseif t == 3 then
		-- 일섬: 지나간 자리에 빛줄기
		local target: Vector3 = data.target
		local dist = (target - origin).Magnitude
		local mid = (origin + target) / 2
		local beam = fxPart(Vector3.new(1.2, 1.2, dist), CFrame.lookAt(mid, target), Color3.new(1, 1, 1), 0)
		fade(beam, 0.5, { Size = Vector3.new(0.1, 0.1, dist) })
		local glow = fxPart(Vector3.new(3, 3, dist), CFrame.lookAt(mid, target), color, 0.5)
		fade(glow, 0.35)
		Effects.flash(target, color, 10, 0.3)
		Effects.burst(target, color, 30, 35, 0.6)
		Effects.shake(0.8, 0.3)
		Effects.sound("lunge", 0.9, 1.0)
	elseif t == 4 then
		-- 그림자 처형: 연기 속에서 X자 베기 다섯 번
		local target: Vector3 = data.target or origin
		Effects.burst(origin, Color3.fromRGB(40, 20, 60), 30, 12, 1.6)
		for i = 0, 4 do
			task.delay(0.05 + i * 0.12, function()
				local cf = CFrame.lookAt(target + Vector3.new(0, 1, 0), target + Vector3.new(0, 1, 0) + look) * CFrame.Angles(0, math.rad(90), 0)
				local tilt = (i % 2 == 0) and 40 or -40
				arc(cf * CFrame.Angles(0, 0, math.rad(90 + tilt)), 4, -70, 70, 9, 0.9, Color3.fromRGB(190, 90, 255), 0.18)
				Effects.burst(target + Vector3.new(0, 1, 0), Color3.fromRGB(160, 60, 255), 10, 25, 0.4)
				Effects.shake(0.45, 0.1)
				Effects.sound("slash", 0.5, 1.4 + i * 0.08)
			end)
		end
	elseif t == 5 then
		-- 영혼 수확: 넓은 원이 퍼지고, 영혼이 나에게 빨려 든다
		ring(Vector3.new(origin.X, floorY + 0.4, origin.Z), Color3.fromRGB(120, 255, 190), 4, data.radius * 2, 0.5, 0.5)
		arc(CFrame.new(origin) , data.radius * 0.9, 0, 360, 24, 1.6, color, 0.35)
		for _, v in ipairs(data.victims or {}) do
			local wisp = fxPart(Vector3.new(0.8, 0.8, 0.8), CFrame.new(v), Color3.fromRGB(150, 255, 200), 0.1, Enum.PartType.Ball)
			task.delay(0.3, function()
				local r = getChar()
				local goal = r and r.Position or origin
				TweenService:Create(wisp, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = goal }):Play()
				Debris:AddItem(wisp, 0.5)
			end)
		end
		task.delay(0.75, function()
			local r = getChar()
			if r then
				Effects.burst(r.Position, Color3.fromRGB(120, 255, 160), 25, 10, 0.6)
			end
		end)
		Effects.shake(0.5, 0.3)
		Effects.sound("lunge", 0.7, 0.7)
	else
		-- 천지개벽: 하늘까지 닿는 무지개 기둥과 투기장 전체 충격파
		for i, c in ipairs(RAINBOW_COLORS) do
			task.delay(i * 0.04, function()
				local pillar = fxPart(Vector3.new(160, 10 - i, 10 - i), CFrame.new(origin + Vector3.new(0, 78, 0)) * CFrame.Angles(0, 0, math.rad(90)), c, 0.3, Enum.PartType.Cylinder)
				fade(pillar, 0.8, { Size = Vector3.new(160, 1, 1) })
			end)
		end
		task.delay(0.35, function()
			ring(Vector3.new(origin.X, floorY + 0.4, origin.Z), Color3.new(1, 1, 1), 6, (data.radius or 60) * 2, 0.6, 0.6)
		end)
		Effects.shake(1.5, 0.7)
		Effects.sound("lunge", 1, 0.45)
	end
	if root then
		Effects.flash(root.Position, color, 6, 0.3)
	end
end

------------------------------------------------------------------------
-- 움직이는 물체: 매 프레임 위치를 정해 주는 함수를 받아 일정 시간 돌린다
------------------------------------------------------------------------
local function animate(duration: number, step: (number) -> (), done: (() -> ())?)
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = (os.clock() - start) / duration
		if t >= 1 then
			conn:Disconnect()
			step(1)
			if done then
				done()
			end
			return
		end
		step(t)
	end)
end

local function addTrail(p: BasePart, color: Color3, width: number, life: number)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, width / 2, 0)
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -width / 2, 0)
	a1.Parent = p
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = life
	tr.LightEmission = 1
	tr.Color = ColorSequence.new(color)
	tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	tr.Parent = p
end

local function floorOf(pos: Vector3): Vector3
	local root = getChar()
	local y = root and (root.Position.Y - 2.9) or pos.Y
	return Vector3.new(pos.X, y, pos.Z)
end

------------------------------------------------------------------------
-- 바닥 경고: 서버가 띄운 빨간 경고 안에서 밝은 원이 차오른다 (언제 터지는지 보인다)
------------------------------------------------------------------------
function Effects.warningFill(warn: BasePart)
	local duration = warn:GetAttribute("Warn")
	if type(duration) ~= "number" or duration <= 0 then
		return
	end
	local isDisc = warn:IsA("Part") and (warn :: Part).Shape == Enum.PartType.Cylinder
	local fill = fxPart(isDisc and Vector3.new(warn.Size.X + 0.05, 0.1, 0.1) or Vector3.new(warn.Size.X, warn.Size.Y + 0.05, 0.1), warn.CFrame, Color3.fromRGB(255, 120, 60), 0.35, isDisc and Enum.PartType.Cylinder or nil)
	if isDisc then
		TweenService:Create(fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = Vector3.new(warn.Size.X + 0.05, warn.Size.Y, warn.Size.Z) }):Play()
	else
		-- 길 경고는 시작점에서 끝까지 차오른다
		local length = warn.Size.Z
		local back = warn.CFrame * CFrame.new(0, 0, length / 2)
		animate(duration, function(t)
			if fill.Parent then
				fill.Size = Vector3.new(warn.Size.X, warn.Size.Y + 0.05, math.max(0.1, length * t))
				fill.CFrame = back * CFrame.new(0, 0, -length * t / 2)
			end
		end)
	end
	Debris:AddItem(fill, duration)
	-- 테두리
	if isDisc then
		ring(warn.Position + Vector3.new(0, 0.1, 0), Color3.fromRGB(255, 60, 40), warn.Size.Y, warn.Size.Y * 1.02, duration, 0.3)
	end
end

------------------------------------------------------------------------
-- 적의 공격
------------------------------------------------------------------------
function Effects.projectile(data: any)
	local color: Color3 = data.color or Color3.fromRGB(255, 120, 80)
	local from: Vector3 = data.from
	local dir: Vector3 = data.dir
	local arrow = fxPart(Vector3.new(0.25, 0.25, 2.8), CFrame.lookAt(from, from + dir), color, 0)
	addTrail(arrow, color, 0.5, 0.25)
	local head = fxPart(Vector3.new(0.6, 0.6, 0.6), arrow.CFrame * CFrame.new(0, 0, -1.4), Color3.new(1, 1, 1), 0, Enum.PartType.Ball)
	animate(data.range / data.speed, function(t)
		local p = from + dir * (data.range * t)
		arrow.CFrame = CFrame.lookAt(p, p + dir)
		head.CFrame = arrow.CFrame * CFrame.new(0, 0, -1.4)
	end, function()
		fade(arrow, 0.1)
		fade(head, 0.1)
	end)
	Effects.sound("slash", 0.25, 1.8)
end

function Effects.explode(data: any)
	local pos: Vector3 = data.pos
	local r: number = data.radius or 8
	Effects.flash(pos, Color3.fromRGB(255, 200, 80), r * 1.6, 0.35)
	Effects.flash(pos, Color3.fromRGB(255, 80, 30), r * 2.2, 0.5)
	ring(floorOf(pos) + Vector3.new(0, 0.2, 0), Color3.fromRGB(255, 120, 40), 2, r * 2.4, 0.45, 0.5)
	Effects.burst(pos, Color3.fromRGB(255, 150, 50), 40, 40, 1)
	Effects.burst(pos, Color3.fromRGB(60, 50, 50), 20, 12, 2)
	local root = getChar()
	if root and (root.Position - pos).Magnitude < 30 then
		Effects.shake(1.0, 0.35)
	end
	Effects.sound("lunge", 0.8, 0.4)
end

function Effects.flame(data: any)
	local base = floorOf(data.pos)
	local r: number = data.radius or 7
	local pillarPart = fxPart(Vector3.new(16, r * 1.4, r * 1.4), CFrame.new(base + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(190, 90, 255), 0.2, Enum.PartType.Cylinder)
	fade(pillarPart, 0.6, { Size = Vector3.new(26, r * 0.3, r * 0.3) })
	ring(base + Vector3.new(0, 0.2, 0), Color3.fromRGB(220, 120, 255), r * 1.2, r * 2.6, 0.5, 0.4)
	Effects.burst(base + Vector3.new(0, 2, 0), Color3.fromRGB(230, 140, 255), 25, 25, 0.8)
	Effects.sound("lunge", 0.5, 0.8)
end

function Effects.meteor(data: any)
	local target = floorOf(data.pos)
	local start = target + Vector3.new(14, 70, -8)
	local rock = fxPart(Vector3.new(3, 3, 3), CFrame.new(start), Color3.fromRGB(255, 90, 30), 0, Enum.PartType.Ball)
	rock.Material = Enum.Material.Neon
	addTrail(rock, Color3.fromRGB(255, 140, 40), 2.5, 0.35)
	animate(0.25, function(t)
		rock.CFrame = CFrame.new(start:Lerp(target, t))
	end, function()
		fade(rock, 0.05)
		Effects.explode({ pos = target + Vector3.new(0, 1, 0), radius = data.radius or 6 })
	end)
end

function Effects.spinFx(data: any)
	local cf = CFrame.new(data.pos)
	arc(cf, data.radius * 0.9, 0, 360, 20, 2.2, Color3.fromRGB(255, 200, 70), 0.3)
	arc(cf * CFrame.new(0, 1.5, 0), data.radius * 0.7, 0, 360, 16, 1.4, Color3.fromRGB(255, 120, 40), 0.3)
	Effects.sound("slash", 0.45, 0.6)
end

function Effects.summonFx(data: any)
	local base: Vector3 = data.pos
	ring(base + Vector3.new(0, 0.2, 0), Color3.fromRGB(170, 80, 255), 1, 9, 0.7, 0.4)
	local beam = fxPart(Vector3.new(30, 4, 4), CFrame.new(base + Vector3.new(0, 15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(190, 110, 255), 0.3, Enum.PartType.Cylinder)
	fade(beam, 0.6, { Size = Vector3.new(30, 0.2, 0.2) })
	Effects.burst(base + Vector3.new(0, 1, 0), Color3.fromRGB(200, 140, 255), 18, 14, 0.6)
end

function Effects.blink(data: any)
	for _, p in ipairs({ data.from, data.to }) do
		Effects.burst(p, Color3.fromRGB(40, 20, 50), 26, 10, 1.6)
		Effects.flash(p, Color3.fromRGB(150, 50, 200), 5, 0.25)
	end
	Effects.sound("slash", 0.4, 2)
end

function Effects.dust(data: any)
	Effects.burst(floorOf(data.pos) + Vector3.new(0, 1, 0), Color3.fromRGB(200, 175, 135), 24, 22, 1.4)
	Effects.shake(0.5, 0.2)
end

-- 적이 쓰러질 때: 몸이 터지고 영혼이 하늘로, 보스는 거대한 빛기둥
function Effects.kill(data: any)
	local pos: Vector3 = data.pos
	local color: Color3 = data.color or Color3.new(1, 1, 1)
	local scale: number = data.scale or 1
	Effects.flash(pos, color, 6 * scale, 0.3)
	Effects.burst(pos, color, 22, 26, 0.7 * scale)
	Effects.burst(pos, Color3.fromRGB(255, 215, 90), 8, 12, 0.4)
	ring(floorOf(pos) + Vector3.new(0, 0.25, 0), color, 2, 10 * scale, 0.4, 0.3)
	local soul = fxPart(Vector3.new(1, 1, 1) * scale, CFrame.new(pos), color:Lerp(Color3.new(1, 1, 1), 0.5), 0.1, Enum.PartType.Ball)
	addTrail(soul, color, 0.8 * scale, 0.4)
	TweenService:Create(soul, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = pos + Vector3.new(0, 14, 0), Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2) }):Play()
	Debris:AddItem(soul, 1)
	if data.boss then
		local beam = fxPart(Vector3.new(200, 12, 12), CFrame.new(pos + Vector3.new(0, 100, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 230, 150), 0.1, Enum.PartType.Cylinder)
		fade(beam, 1.4, { Size = Vector3.new(200, 0.5, 0.5) })
		for i = 0, 4 do
			task.delay(i * 0.12, function()
				Effects.explode({ pos = pos + Vector3.new((math.random() - 0.5) * 8, math.random() * 4, (math.random() - 0.5) * 8), radius = 6 })
			end)
		end
		Effects.shake(1.6, 0.8)
	else
		Effects.shake(0.15, 0.08)
		Effects.sound("ping", 0.25, 1.6 + math.random() * 0.3)
	end
end

-- 대시 잔상: 내 몸 모양 그대로 빛나는 껍데기를 남긴다
function Effects.afterimage(char: Model, color: Color3)
	for _, d in ipairs(char:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 then
			local ghost = fxPart(d.Size, d.CFrame, color, 0.55)
			ghost.Material = Enum.Material.ForceField
			fade(ghost, 0.35)
		end
	end
end

-- 전투 시작: 내 자리에 빛기둥이 떨어진다
function Effects.battleStart(data: any)
	local base = Vector3.new(data.pos.X, data.pos.Y, data.pos.Z)
	local beam = fxPart(Vector3.new(120, 9, 9), CFrame.new(base + Vector3.new(0, 60, 0)) * CFrame.Angles(0, 0, math.rad(90)), data.color, 0.1, Enum.PartType.Cylinder)
	fade(beam, 0.8, { Size = Vector3.new(120, 0.5, 0.5) })
	ring(base + Vector3.new(0, 0.3, 0), data.color, 4, 50, 0.7, 0.4)
	Effects.burst(base + Vector3.new(0, 2, 0), data.color, 40, 40, 1)
	Effects.shake(0.6, 0.3)
	Effects.sound("lunge", 0.7, 0.6)
end

------------------------------------------------------------------------
-- 로비 합성 용광로
------------------------------------------------------------------------
function Effects.forge(data: any)
	local lobby = workspace:FindFirstChild("Lobby")
	local forge = lobby and lobby:FindFirstChild("Forge")
	if not forge then
		return
	end
	local color: Color3 = data.color or Color3.fromRGB(255, 160, 60)
	local mouth = forge:FindFirstChild("ForgeMouth")
	local anvil = forge:FindFirstChild("ForgeAnvil")
	local lava = forge:FindFirstChild("ForgeLava")
	local liquid = forge:FindFirstChild("ForgeLiquid")
	local ringPart = forge:FindFirstChild("ForgeRing")
	if mouth and mouth:IsA("BasePart") then
		Effects.flash(mouth.Position, color, 9, 0.4)
		local glow = mouth:FindFirstChild("ForgeGlow")
		if glow and glow:IsA("PointLight") then
			glow.Brightness = 12
			glow.Color = color
			TweenService:Create(glow, TweenInfo.new(1.2), { Brightness = 3, Color = Color3.fromRGB(255, 140, 50) }):Play()
		end
		local embers = mouth:FindFirstChild("Embers")
		if embers and embers:IsA("ParticleEmitter") then
			embers:Emit(50)
		end
	end
	if anvil and anvil:IsA("BasePart") then
		local top = anvil.Position + Vector3.new(0, 0.6, 0)
		Effects.burst(top, color, 40, 30, 0.5)
		Effects.burst(top, Color3.fromRGB(255, 230, 150), 25, 22, 0.3)
		local beam = fxPart(Vector3.new(30, 2.2, 2.2), CFrame.new(top + Vector3.new(0, 15, 0)) * CFrame.Angles(0, 0, math.rad(90)), color, 0.2, Enum.PartType.Cylinder)
		fade(beam, data.legendary and 1.2 or 0.6, { Size = Vector3.new(30, 0.2, 0.2) })
		if data.legendary then
			ring(top - Vector3.new(0, 2.5, 0), color, 2, 26, 0.9, 0.3)
		end
	end
	if lava and lava:IsA("BasePart") then
		Effects.burst(lava.Position + Vector3.new(0, 1, 0), Color3.fromRGB(255, 140, 40), 30, 26, 0.6)
	end
	if liquid and liquid:IsA("BasePart") then
		local old = liquid.Color
		liquid.Color = color
		TweenService:Create(liquid, TweenInfo.new(1.5), { Color = old }):Play()
	end
	if ringPart and ringPart:IsA("BasePart") then
		ringPart.Color = color
		ringPart.Transparency = 0
		TweenService:Create(ringPart, TweenInfo.new(1.2), { Transparency = 0.4, Color = Color3.fromRGB(222, 178, 72) }):Play()
	end
	local root = getChar()
	if root and anvil and anvil:IsA("BasePart") and (root.Position - anvil.Position).Magnitude < 40 then
		Effects.shake(0.3, 0.2)
		Effects.sound("lunge", 0.7, 0.7)
		Effects.sound("ping", 0.5, 1.4)
	end
end

------------------------------------------------------------------------
-- 타격감: 맞은 자리에서 내 반대쪽으로 튀는 불꽃과 베인 자국
------------------------------------------------------------------------
function Effects.impact(h: any, heavy: number)
	local pos: Vector3 = h.pos
	local from: Vector3 = h.from or pos
	local away = Vector3.new(pos.X - from.X, 0, pos.Z - from.Z)
	away = away.Magnitude > 0.01 and away.Unit or Vector3.new(0, 0, -1)
	local color: Color3 = h.color or Color3.fromRGB(255, 230, 180)
	local crit = h.kind == "crit"
	-- 방향 있는 불꽃 줄기
	local n = crit and 9 or 5
	for _ = 1, n do
		local dir = (away + Vector3.new((math.random() - 0.5) * 1.4, math.random() * 0.9, (math.random() - 0.5) * 1.4)).Unit
		local len = (crit and 2.2 or 1.3) * (0.6 + math.random() * 0.8)
		local spark = fxPart(Vector3.new(0.12, 0.12, len), CFrame.lookAt(pos, pos + dir) * CFrame.new(0, 0, -len / 2), (math.random() < 0.5) and Color3.new(1, 1, 1) or color, 0.05)
		local goal = pos + dir * (crit and 7 or 4.5) * heavy
		TweenService:Create(spark, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.lookAt(goal, goal + dir),
			Size = Vector3.new(0.04, 0.04, len * 0.3),
			Transparency = 1,
		}):Play()
		Debris:AddItem(spark, 0.18)
	end
	-- 베인 자국: X자로 번쩍
	local cam = workspace.CurrentCamera
	local face = cam and (cam.CFrame.Position - pos).Unit or -away
	local baseCf = CFrame.lookAt(pos, pos + face)
	local size = (crit and 4.2 or 2.6) * heavy
	for _, tilt in ipairs({ 40, -40 }) do
		local slash = fxPart(Vector3.new(0.18, size, 0.05), baseCf * CFrame.Angles(0, 0, math.rad(tilt + math.random(-10, 10))), crit and Color3.new(1, 1, 1) or color:Lerp(Color3.new(1, 1, 1), 0.5), 0)
		TweenService:Create(slash, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.02, size * 1.3, 0.02), Transparency = 1 }):Play()
		Debris:AddItem(slash, 0.14)
	end
	-- 작은 충격 고리
	if crit or heavy > 1.2 then
		ring(pos, color, 0.5, (crit and 6 or 4) * heavy, 0.18, 0.15)
	end
end

-- 맞은 적이 하얗게 번쩍인다
function Effects.hitFlash(target: Instance?, crit: boolean)
	if not target or not target.Parent then
		return
	end
	local model = target :: Instance
	local h = Instance.new("Highlight")
	h.FillColor = crit and Color3.fromRGB(255, 240, 160) or Color3.new(1, 1, 1)
	h.FillTransparency = 0.15
	h.OutlineColor = Color3.new(1, 1, 1)
	h.OutlineTransparency = 0.3
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = model
	TweenService:Create(h, TweenInfo.new(crit and 0.14 or 0.09), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	Debris:AddItem(h, crit and 0.15 or 0.1)
end

-- 처치: 적의 몸이 조각나서 사방으로 흩어진다
function Effects.shatter(target: Instance?, color: Color3)
	if not target or not target:IsA("Model") then
		return
	end
	local model = target :: Model
	local count = 0
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and count < 16 then
			count += 1
			local center = d.Position
			d.LocalTransparencyModifier = 1
			for k = 1, 2 do
				local piece = fxPart(d.Size * (0.45 + math.random() * 0.2), d.CFrame * CFrame.new((k - 1.5) * d.Size.X * 0.3, 0, 0), d.Color, 0)
				piece.Material = d.Material
				local dir = Vector3.new(math.random() - 0.5, 0.6 + math.random() * 0.8, math.random() - 0.5).Unit
				local goal = center + dir * (6 + math.random() * 8) + Vector3.new(0, -3, 0)
				TweenService:Create(piece, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = goal,
					Orientation = Vector3.new(math.random(-360, 360), math.random(-360, 360), math.random(-360, 360)),
					Size = piece.Size * 0.3,
					Transparency = 1,
				}):Play()
				Debris:AddItem(piece, 0.65)
			end
		end
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
		elseif d:IsA("BillboardGui") then
			d.Enabled = false
		end
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		Effects.burst(root.Position, color, 16, 20, 0.6)
	end
end

------------------------------------------------------------------------
-- 무기 스킬 연출
------------------------------------------------------------------------
local skillFx: { [string]: (any) -> () } = {}

skillFx.charge = function(data)
	local from: Vector3 = data.origin
	local to: Vector3 = data.target
	for i = 0, 6 do
		task.delay(i * 0.03, function()
			local p = from:Lerp(to, i / 6)
			Effects.burst(floorOf(p) + Vector3.new(0, 1, 0), Color3.fromRGB(210, 180, 140), 6, 16, 0.9)
		end)
	end
	local ram = fxPart(Vector3.new(6, 4, 1), CFrame.lookAt(from, to) * CFrame.new(0, 0, -2), data.color, 0.3)
	animate(0.2, function(t)
		ram.CFrame = CFrame.lookAt(from:Lerp(to, t), to) * CFrame.new(0, 0, -2)
	end, function()
		fade(ram, 0.15)
		ring(floorOf(to) + Vector3.new(0, 0.2, 0), data.color, 2, 16, 0.35, 0.4)
	end)
	Effects.shake(0.8, 0.3)
	Effects.sound("lunge", 0.8, 0.7)
end

skillFx.boomerang = function(data)
	local origin: Vector3 = data.origin
	local look: Vector3 = data.look
	local anchor = fxPart(Vector3.new(0.4, 0.4, 0.4), CFrame.new(origin), Color3.new(1, 1, 1), 1)
	local holder = Instance.new("Model")
	holder.Parent = folder
	pcall(function()
		WeaponBuilder.build(holder, anchor, 1, { grade = data.grade or 40, accent = data.color, rarity = 5, scale = 1, lite = true }, CFrame.new(origin) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(0, -3, 0))
	end)
	local spinRing = fxPart(Vector3.new(0.2, 9, 9), CFrame.new(origin), data.color, 0.6, Enum.PartType.Cylinder)
	local far = origin + look * data.range
	animate(data.duration, function(t)
		local pos
		if t <= 0.5 then
			pos = origin:Lerp(far, t / 0.5)
		else
			local r = getChar()
			pos = far:Lerp(r and r.Position or origin, (t - 0.5) / 0.5)
		end
		local spin = CFrame.Angles(0, os.clock() * 25, 0)
		anchor.CFrame = CFrame.new(pos) * spin
		spinRing.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	end, function()
		holder:Destroy()
		fade(anchor, 0.05)
		fade(spinRing, 0.1)
	end)
	Effects.sound("slash", 0.6, 0.7)
end

skillFx.markBoom = function(data)
	Effects.flash(data.pos, Color3.fromRGB(255, 80, 180), 10, 0.35)
	local cf = CFrame.new(data.pos)
	arc(cf * CFrame.Angles(0, 0, math.rad(55)), 5, -80, 80, 10, 1.2, Color3.fromRGB(255, 120, 200), 0.3)
	arc(cf * CFrame.Angles(0, 0, math.rad(-55)), 5, -80, 80, 10, 1.2, Color3.fromRGB(255, 120, 200), 0.3)
	ring(floorOf(data.pos) + Vector3.new(0, 0.2, 0), Color3.fromRGB(255, 100, 190), 2, 16, 0.4, 0.4)
	Effects.burst(data.pos, Color3.fromRGB(255, 120, 200), 35, 32, 0.7)
	Effects.shake(0.9, 0.3)
	Effects.sound("lunge", 0.8, 1.2)
end

local function streak(from: Vector3, to: Vector3, color: Color3, width: number, life: number)
	local mid = (from + to) / 2
	local dist = (to - from).Magnitude
	if dist < 0.1 then
		return
	end
	local p = fxPart(Vector3.new(width, width, dist), CFrame.lookAt(mid, to), color, 0.1)
	fade(p, life, { Size = Vector3.new(0.05, 0.05, dist) })
end

local function silhouettes(from: Vector3, to: Vector3, color: Color3, count: number, life: number)
	for i = 1, count do
		local p = from:Lerp(to, i / (count + 1))
		local body = fxPart(Vector3.new(4.6, 1.8, 1.8), CFrame.lookAt(p, to) * CFrame.Angles(0, 0, math.rad(90)), color, 0.5, Enum.PartType.Cylinder)
		body.Material = Enum.Material.ForceField
		fade(body, life + i * 0.03)
	end
end

skillFx.phantom = function(data)
	streak(data.origin, data.target, data.color, 1.2, 0.35)
	silhouettes(data.origin, data.target, data.color, 5, 0.6)
	Effects.sound("slash", 0.5, 1.5)
end

skillFx.phantomEcho = function(data)
	streak(data.origin, data.target, Color3.fromRGB(200, 120, 255), 1.6, 0.3)
	for i = 1, 4 do
		local p = data.origin:Lerp(data.target, i / 5)
		arc(CFrame.lookAt(p, data.target) * CFrame.Angles(0, 0, math.rad(90 + (i % 2 == 0 and 40 or -40))), 3.5, -70, 70, 8, 0.8, Color3.fromRGB(210, 140, 255), 0.18)
	end
	Effects.shake(0.4, 0.15)
	Effects.sound("slash", 0.6, 1.2)
end

skillFx.wave = function(data)
	local origin: Vector3 = data.origin
	local look: Vector3 = data.look
	local color: Color3 = data.color
	local segs = 9
	local parts = {}
	for i = 0, segs - 1 do
		local a0 = math.rad(-75 + 150 * i / segs)
		local a1 = math.rad(-75 + 150 * (i + 1) / segs)
		local r = data.width * 0.9
		local p0 = Vector3.new(math.sin(a0) * r, 0, -math.cos(a0) * r)
		local p1 = Vector3.new(math.sin(a1) * r, 0, -math.cos(a1) * r)
		local mid = (p0 + p1) / 2
		local t = i / (segs - 1)
		local w = 1.6 * (1 - math.abs(t * 2 - 1) * 0.7)
		local offset = CFrame.lookAt(mid, p1)
		local part = fxPart(Vector3.new(w, 0.3, (p1 - p0).Magnitude + 0.1), CFrame.new(origin), color, 0.05)
		table.insert(parts, { part = part, offset = offset })
	end
	local core = fxPart(Vector3.new(1, 1, 1), CFrame.new(origin), Color3.new(1, 1, 1), 0.2, Enum.PartType.Ball)
	addTrail(core, color, 4, 0.3)
	local duration = data.range / data.speed
	animate(duration, function(t)
		local d = data.range * t
		local base = CFrame.lookAt(origin + look * d, origin + look * (d + 1))
		for _, item in ipairs(parts) do
			item.part.CFrame = base * item.offset
		end
		core.CFrame = base
	end, function()
		for _, item in ipairs(parts) do
			fade(item.part, 0.15)
		end
		fade(core, 0.15)
	end)
	Effects.sound("lunge", 0.6, 1.3)
end

skillFx.parry = function(data)
	local root = getChar()
	if not root then
		return
	end
	local bubble = fxPart(Vector3.new(8, 8, 8), root.CFrame, data.color, 0.4, Enum.PartType.Ball)
	bubble.Material = Enum.Material.ForceField
	animate(data.window, function()
		local r = getChar()
		if r and bubble.Parent then
			bubble.CFrame = r.CFrame
		end
	end, function()
		fade(bubble, 0.15)
	end)
	Effects.sound("unsheath", 0.6, 1.3)
end

skillFx.parryCounter = function(data)
	Effects.flash(data.pos, Color3.new(1, 1, 1), 14, 0.3)
	ring(floorOf(data.pos) + Vector3.new(0, 0.3, 0), data.color, 3, data.radius * 2.2, 0.4, 0.5)
	arc(CFrame.new(data.pos), data.radius * 0.8, 0, 360, 22, 2, Color3.new(1, 1, 1), 0.3)
	local anchor = fxPart(Vector3.new(0.2, 0.2, 0.2), CFrame.new(data.pos + Vector3.new(0, 5, 0)), Color3.new(1, 1, 1), 1)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 300, 0, 70)
	bb.AlwaysOnTop = true
	bb.Parent = anchor
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.Text = "COUNTER!"
	l.TextColor3 = Color3.fromRGB(255, 240, 160)
	l.TextStrokeTransparency = 0
	l.Parent = bb
	TweenService:Create(anchor, TweenInfo.new(0.8), { Position = anchor.Position + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(l, TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1)
	Effects.shake(1.0, 0.3)
	Effects.sound("lunge", 0.9, 1.5)
end

skillFx.poison = function(data)
	local char = Players.LocalPlayer.Character
	local weapon = char and char:FindFirstChild("ArenaWeapon")
	if weapon then
		for _, d in ipairs(weapon:GetDescendants()) do
			if d:IsA("BasePart") and string.sub(d.Name, 1, 5) == "Blade" then
				local drip = Instance.new("ParticleEmitter")
				drip.Rate = 20
				drip.Lifetime = NumberRange.new(0.4, 0.8)
				drip.Speed = NumberRange.new(0.5, 1.5)
				drip.Acceleration = Vector3.new(0, -12, 0)
				drip.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
				drip.LightEmission = 0.8
				drip.Color = ColorSequence.new(Color3.fromRGB(120, 255, 90))
				drip.Parent = d
				Debris:AddItem(drip, data.duration)
			end
		end
	end
	local root = getChar()
	if root then
		Effects.burst(root.Position, Color3.fromRGB(120, 255, 90), 25, 12, 0.6)
	end
	Effects.sound("unsheath", 0.6, 0.8)
end

skillFx.smoke = function(data)
	Effects.burst(data.pos, Color3.fromRGB(70, 65, 80), 40, 14, 3)
	Effects.burst(data.pos, Color3.fromRGB(150, 140, 160), 20, 8, 2)
	local char = Players.LocalPlayer.Character
	if char then
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = 0.75
			end
		end
		task.delay(data.duration, function()
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") then
					d.LocalTransparencyModifier = 0
				end
			end
		end)
	end
	Effects.sound("slash", 0.4, 0.5)
end

skillFx.hook = function(data)
	local origin: Vector3 = data.origin
	for _, v in ipairs(data.victims or {}) do
		local links = {}
		local dist = (v - origin).Magnitude
		local n = math.max(3, math.floor(dist / 2))
		for i = 1, n do
			local p = origin:Lerp(v, i / n)
			local link = fxPart(Vector3.new(0.5, 0.5, 1.2), CFrame.lookAt(p, v), Color3.fromRGB(190, 190, 205), 0)
			link.Material = Enum.Material.Metal
			table.insert(links, { part = link, t = i / n })
		end
		animate(0.3, function(t)
			for _, l in ipairs(links) do
				local p = origin:Lerp(v, l.t * (1 - t))
				l.part.CFrame = CFrame.lookAt(p, v)
			end
		end, function()
			for _, l in ipairs(links) do
				fade(l.part, 0.1)
			end
		end)
		Effects.burst(v, data.color, 10, 14, 0.5)
	end
	Effects.shake(0.4, 0.15)
	Effects.sound("lunge", 0.6, 0.9)
end

skillFx.zone = function(data)
	local base = Vector3.new(data.pos.X, data.pos.Y + 0.15, data.pos.Z)
	local d = data.radius * 2
	local circle = fxPart(Vector3.new(0.15, d, d), CFrame.new(base) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(80, 255, 170), 0.5, Enum.PartType.Cylinder)
	local runes = {}
	for i = 0, 7 do
		local rune = fxPart(Vector3.new(1.4, 0.2, 1.4), CFrame.new(base), Color3.fromRGB(150, 255, 200), 0.1)
		table.insert(runes, { part = rune, a = i * math.pi / 4 })
	end
	local souls = Instance.new("ParticleEmitter")
	souls.Rate = 25
	souls.Lifetime = NumberRange.new(1, 1.6)
	souls.Speed = NumberRange.new(3, 6)
	souls.EmissionDirection = Enum.NormalId.Right
	souls.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	souls.LightEmission = 1
	souls.Color = ColorSequence.new(Color3.fromRGB(150, 255, 200))
	souls.Parent = circle
	animate(data.duration, function(t)
		local spin = os.clock() * 1.5
		for _, r in ipairs(runes) do
			local a = r.a + spin
			r.part.CFrame = CFrame.new(base + Vector3.new(math.cos(a) * data.radius * 0.85, 0.2, math.sin(a) * data.radius * 0.85)) * CFrame.Angles(0, -a, 0)
		end
		circle.Transparency = 0.45 + math.sin(t * 30) * 0.1
	end, function()
		souls.Enabled = false
		fade(circle, 0.3)
		for _, r in ipairs(runes) do
			fade(r.part, 0.3)
		end
	end)
	Effects.sound("unsheath", 0.6, 0.6)
end

skillFx.rain = function(data)
	for i, pos in ipairs(data.positions or {}) do
		task.delay((i - 1) * 0.07, function()
			local ground = floorOf(pos)
			local start = ground + Vector3.new(0, 60, 0)
			local anchor = fxPart(Vector3.new(0.3, 0.3, 0.3), CFrame.new(start), Color3.new(1, 1, 1), 1)
			local holder = Instance.new("Model")
			holder.Parent = folder
			pcall(function()
				WeaponBuilder.build(holder, anchor, 1, { grade = 100, accent = Color3.fromRGB(255, 235, 160), rarity = 5, scale = 0.8, lite = true }, CFrame.new(start) * CFrame.Angles(math.rad(180), 0, 0) * CFrame.new(0, -4, 0))
			end)
			animate(0.35, function(t)
				anchor.CFrame = CFrame.new(start:Lerp(ground + Vector3.new(0, 4, 0), t * t))
			end, function()
				Effects.flash(ground + Vector3.new(0, 1, 0), Color3.fromRGB(255, 240, 180), 6, 0.25)
				ring(ground + Vector3.new(0, 0.2, 0), Color3.fromRGB(255, 220, 120), 1, 9, 0.35, 0.3)
				Effects.burst(ground + Vector3.new(0, 1, 0), Color3.fromRGB(255, 230, 150), 12, 20, 0.5)
				Effects.shake(0.25, 0.08)
				task.delay(0.5, function()
					holder:Destroy()
					anchor:Destroy()
				end)
			end)
		end)
	end
	Effects.sound("lunge", 0.8, 0.8)
end

skillFx.timestop = function(data)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "TimeStop"
	cc.Saturation = -0.9
	cc.TintColor = Color3.fromRGB(200, 225, 255)
	cc.Parent = Lighting
	task.delay(data.duration - 0.4, function()
		TweenService:Create(cc, TweenInfo.new(0.4), { Saturation = 0, TintColor = Color3.new(1, 1, 1) }):Play()
		Debris:AddItem(cc, 0.45)
	end)
	for _, m in ipairs(data.models or {}) do
		if m and m.Parent then
			local h = Instance.new("Highlight")
			h.FillColor = Color3.fromRGB(150, 220, 255)
			h.FillTransparency = 0.4
			h.OutlineColor = Color3.new(1, 1, 1)
			h.Parent = m
			Debris:AddItem(h, data.duration)
		end
	end
	local root = getChar()
	if root then
		ring(floorOf(root.Position) + Vector3.new(0, 0.3, 0), Color3.fromRGB(200, 230, 255), 4, 120, 0.8, 0.4)
		arc(CFrame.new(root.Position + Vector3.new(0, 4, 0)) * CFrame.Angles(math.rad(90), 0, 0), 6, 0, 360, 24, 0.6, Color3.fromRGB(220, 240, 255), 0.8)
	end
	Effects.shake(0.6, 0.3)
	Effects.sound("ping", 0.8, 0.5)
end

skillFx.chargeBoom = function(data)
	local base = floorOf(data.pos)
	ring(base + Vector3.new(0, 0.2, 0), data.color, 2, data.radius * 2.3, 0.35, 0.5)
	Effects.burst(base + Vector3.new(0, 1, 0), Color3.fromRGB(210, 185, 140), 30, 30, 1.3)
	Effects.flash(data.pos, data.color, data.radius, 0.2)
	for i = 0, 7 do
		local a = i * math.pi / 4
		local p = base + Vector3.new(math.cos(a), 0, math.sin(a)) * data.radius * 0.6
		local rock = fxPart(Vector3.new(1, 1.6, 1), CFrame.new(p) * CFrame.Angles(math.random(), math.random(), math.random()), Color3.fromRGB(120, 100, 85), 0)
		rock.Material = Enum.Material.Slate
		fade(rock, 0.5, { Position = p + Vector3.new(0, 3, 0) })
	end
	Effects.shake(1.0, 0.3)
	Effects.sound("lunge", 0.9, 0.5)
end

skillFx.poisonCloud = function(data)
	local base = Vector3.new(data.pos.X, data.pos.Y + 0.2, data.pos.Z)
	local d = data.radius * 2
	local cloud = fxPart(Vector3.new(d * 0.6, 4, d * 0.6), CFrame.new(base + Vector3.new(0, 2, 0)), Color3.fromRGB(110, 220, 80), 0.75, Enum.PartType.Ball)
	cloud.Material = Enum.Material.ForceField
	local gas = Instance.new("ParticleEmitter")
	gas.Texture = "rbxasset://textures/particles/smoke_main.dds"
	gas.Rate = 30
	gas.Lifetime = NumberRange.new(1, 2)
	gas.Speed = NumberRange.new(1, 3)
	gas.SpreadAngle = Vector2.new(180, 180)
	gas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 4) })
	gas.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	gas.Color = ColorSequence.new(Color3.fromRGB(120, 230, 80), Color3.fromRGB(60, 120, 40))
	gas.Parent = cloud
	animate(data.duration, function(t)
		cloud.Size = Vector3.new(d * (0.6 + 0.4 * math.min(t * 4, 1)), 4, d * (0.6 + 0.4 * math.min(t * 4, 1)))
	end, function()
		gas.Enabled = false
		fade(cloud, 0.5)
	end)
	Effects.sound("unsheath", 0.5, 0.5)
end

skillFx.hookSlam = function(data)
	local base = floorOf(data.pos)
	ring(base + Vector3.new(0, 0.2, 0), Color3.fromRGB(180, 180, 200), 2, 18, 0.35, 0.5)
	Effects.burst(base + Vector3.new(0, 1, 0), Color3.fromRGB(200, 175, 140), 26, 26, 1.2)
	Effects.shake(0.9, 0.25)
	Effects.sound("lunge", 0.8, 0.6)
end

function Effects.skill(data: any)
	local fn = skillFx[data.id]
	if fn then
		fn(data)
	end
end

return Effects
