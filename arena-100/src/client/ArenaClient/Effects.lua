-- Effects (ModuleScript, ArenaClient 아래)
-- 베기 궤적, 피해 숫자, 치명타, 필살기, 화면 흔들림, 효과음.
-- 전부 내 화면에만 그리는 효과라 다른 사람에게는 보이지 않는다.

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

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
	p.Transparency = transparency or 0.2
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
		local seg = fxPart(Vector3.new(w, 0.12, len), CFrame.lookAt(mid, p1, up), c, 0.15)
		fade(seg, life + t * 0.05, { Size = Vector3.new(w * 0.2, 0.05, len) })
	end
end

function Effects.burst(pos: Vector3, color: Color3, count: number, speed: number?, size: number?)
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
		label.Text = isCrit and ("💥" .. h.text) or h.text
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
function Effects.swing(data: any)
	local root = getChar()
	if not root then
		return
	end
	local section = data.section or 1
	local color: Color3 | { Color3 } = data.color or Color3.new(1, 1, 1)
	if section >= 6 or data.typeId == 0 then
		color = RAINBOW_COLORS
	end
	local plain: Color3 = typeof(color) == "table" and Color3.fromRGB(255, 240, 220) or color :: Color3
	local w = 1 + (section - 1) * 0.18
	local cf = root.CFrame * CFrame.new(0, 0.4, 0)
	local look = root.CFrame.LookVector
	local t = data.typeId

	if t == 1 then
		-- 대검: 위에서 내려찍는 세로 반달 + 땅 먼지
		arc(cf * CFrame.Angles(0, 0, math.rad(90)), data.range * 0.6, -85, 85, 12, 1.5 * w, color, 0.22)
		local ground = root.Position + look * data.range * 0.6 - Vector3.new(0, 2.8, 0)
		Effects.burst(ground, Color3.fromRGB(210, 185, 140), 14, 18, 0.9)
		Effects.shake(0.25, 0.12)
		Effects.sound("slash", 0.55, 0.8)
	elseif t == 2 then
		-- 쌍검: X자 두 줄기
		arc(cf * CFrame.Angles(0, 0, math.rad(35)), 4.5, -70, 70, 9, 0.6 * w, color, 0.14)
		arc(cf * CFrame.Angles(0, 0, math.rad(-35)), 4.5, 70, -70, 9, 0.6 * w, color, 0.14)
		Effects.sound("slash", 0.35, 1.35)
	elseif t == 3 then
		-- 장검: 앞으로 길게 찌르는 빛줄기
		local beam = fxPart(Vector3.new(0.35 * w, 0.35 * w, data.range), cf * CFrame.new(0, 0, -data.range / 2), plain, 0.1)
		fade(beam, 0.18, { Size = Vector3.new(0.05, 0.05, data.range * 1.1) })
		arc(cf, data.range * 0.85, -22, 22, 6, 0.5 * w, color, 0.16)
		Effects.flash(root.Position + look * data.range, plain, 2.5 * w, 0.15)
		Effects.sound("lunge", 0.4, 1.1)
	elseif t == 4 then
		-- 단검: 짧고 빠른 두 번 긋기
		arc(cf * CFrame.Angles(0, 0, math.rad(15)), 3.2, -80, 60, 7, 0.5 * w, color, 0.12)
		arc(cf * CFrame.Angles(0, 0, math.rad(-20)), 3.6, 60, -80, 7, 0.4 * w, color, 0.12)
		Effects.sound("slash", 0.3, 1.6)
	elseif t == 5 then
		-- 낫: 한 바퀴 원 + 영혼 조각
		arc(cf * CFrame.new(0, -0.6, 0), data.range * 0.85, 0, 360, 18, 1.0 * w, color, 0.25)
		for _ = 1, 4 do
			local p = root.Position + Vector3.new((math.random() - 0.5) * 8, -1, (math.random() - 0.5) * 8)
			local wisp = fxPart(Vector3.new(0.5, 0.5, 0.5), CFrame.new(p), Color3.fromRGB(150, 255, 200), 0.2, Enum.PartType.Ball)
			fade(wisp, 0.6, { Position = p + Vector3.new(0, 4, 0) })
		end
		Effects.sound("slash", 0.45, 0.65)
	else
		-- 올라운더: 한 바퀴 + 세로 반달, 무지개
		arc(cf * CFrame.new(0, -0.6, 0), data.range * 0.85, 0, 360, 20, 1.2 * w, RAINBOW_COLORS, 0.28)
		arc(cf * CFrame.Angles(0, 0, math.rad(90)), data.range * 0.6, -85, 85, 12, 1.5 * w, RAINBOW_COLORS, 0.24)
		Effects.shake(0.2, 0.1)
		Effects.sound("lunge", 0.5, 0.9)
	end

	-- 높은 구간일수록 불꽃이 더 튄다
	if section >= 4 then
		Effects.burst(root.Position + look * 3, plain, 4 + section * 2, 16, 0.35)
	end
	if data.crit then
		Effects.sound("lunge", 0.6, 1.3)
		Effects.shake(0.35, 0.15)
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

return Effects
