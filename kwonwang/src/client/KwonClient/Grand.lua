-- 권왕 3.48판: 모든 권법에 함께 얹는 연출 한 겹 (권법마다의 연출은 그대로 두고 그 위에)
--   · 빛: 기술을 쓸 때 · 맞힐 때 그 권법 빛깔의 빛이 둘레를 실제로 비춘다 (Future 조명이라 땅 · 몸 · 벽이 물든다)
--   · 기술 (E · R): 손끝의 번쩍임과 두 빛깔의 고리, 몸에서 튀는 빛가루
--   · 오의 (G) · 초 오의 (X): 기가 몸으로 빨려 들어왔다가 (모으기) 터진다 — 세 겹 충격파, 하늘로 솟는 빛기둥, 바닥에 새겨졌다 사라지는 문양, 화면 울림
--   · 강타 (Z) 와 기술로 맞힐 때: 맞은 자리에서 하얀 섬광 별이 번쩍
-- 가벼운 모드 (Perf.low) 에서는 빛 · 조각을 줄이고, 한꺼번에 켜진 빛은 MAX_LIGHTS까지만
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))
local Perf = require(script.Parent:WaitForChild("Perf"))

local Grand = {}

local folder = Instance.new("Folder")
folder.Name = "KwonGrand"
folder.Parent = workspace

local WHITE = Color3.new(1, 1, 1)
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local MAX_LIGHTS = 24
local lights = 0

local opts: any = {}
function Grand.init(o: any)
	opts = o or {}
end

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal):Play()
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
end
local function part(size: Vector3, color: Color3, alpha: number, shape: Enum.PartType?, life: number): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Size = size
	p.Color = color
	p.Transparency = alpha
	if shape then
		p.Shape = shape
	end
	p.Parent = folder
	Debris:AddItem(p, life + 0.1)
	return p
end
-- 빛 한 번: 켜졌다가 사그라든다
local function flashLight(at: Vector3, color: Color3, range: number, brightness: number, life: number)
	if lights >= (Perf.low and 8 or MAX_LIGHTS) then
		return
	end
	lights += 1
	local holder = part(Vector3.one * 0.2, color, 1, nil, life)
	holder.Position = at
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = holder
	tween(l, life, { Brightness = 0, Range = range * 0.6 })
	task.delay(life, function()
		lights -= 1
	end)
end
local function rootOf(m: Instance?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function groundOf(pos: Vector3): Vector3
	return pos - Vector3.new(0, 2.6, 0)
end
local function flatDisc(at: Vector3, r: number, color: Color3, alpha: number, life: number): Part
	local d = part(Vector3.new(0.2, r * 2, r * 2), color, alpha, Enum.PartType.Cylinder, life)
	d.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	return d
end
local function sparks(at: Vector3, color: Color3, count: number, speed: number, inward: boolean?)
	local holder = part(Vector3.one * 0.2, color, 1, nil, 1.6)
	holder.Position = at
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_SPARK
	e.Color = ColorSequence.new(WHITE, color)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.35, 0.7)
	e.Speed = NumberRange.new(speed * 0.6, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.LightEmission = 1
	e.Drag = inward and 0 or 3
	e.Rate = 0
	e.Parent = holder
	if inward then
		-- 바깥에서 몸으로 빨려 드는 빛가루: 둘레에 뿌려 놓고 가운데로
		e.Speed = NumberRange.new(-speed, -speed * 0.6)
		e.Shape = Enum.ParticleEmitterShape.Sphere
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		holder.Size = Vector3.one * speed * 0.55
	end
	e:Emit(math.floor(count * (Perf.low and 0.4 or 1)))
end
-- 바닥에 새겨졌다 사라지는 문양 (두 겹 고리 + 여덟 갈래 빛살)
local function sigil(g: Vector3, r: number, c1: Color3, c2: Color3, life: number)
	local outer = flatDisc(g + Vector3.new(0, 0.12, 0), r, c1, 0.65, life)
	local inner = flatDisc(g + Vector3.new(0, 0.16, 0), r * 0.62, c2, 0.75, life)
	tween(outer, life, { Transparency = 1, Size = Vector3.new(0.2, r * 2.3, r * 2.3) })
	tween(inner, life * 0.8, { Transparency = 1 })
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local ray = part(Vector3.new(r * 0.9, 0.18, 0.45), k % 2 == 0 and c2 or c1, 0.35, nil, life)
		ray.CFrame = CFrame.new(g + Vector3.new(math.cos(a) * r * 0.5, 0.2, math.sin(a) * r * 0.5)) * CFrame.Angles(0, -a, 0)
		tween(ray, life, { Transparency = 1, Size = Vector3.new(r * 1.2, 0.1, 0.2) })
	end
end
local function column(g: Vector3, w: number, color: Color3, life: number)
	local col = part(Vector3.new(60, w, w), color, 0.25, Enum.PartType.Cylinder, life)
	col.CFrame = CFrame.new(g + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(col, life, { Size = Vector3.new(70, w * 0.15, w * 0.15), Transparency = 1 })
	local core = part(Vector3.new(60, w * 0.35, w * 0.35), WHITE, 0.1, Enum.PartType.Cylinder, life * 0.7)
	core.CFrame = col.CFrame
	tween(core, life * 0.7, { Size = Vector3.new(70, 0.1, 0.1), Transparency = 1 })
end

-- 기술을 쓸 때 (내 몸 · 남의 몸 모두. Fx.cast에서 부른다)
function Grand.cast(styleId: any, slot: any, model: Model, dur: number)
	if type(slot) ~= "string" or (slot ~= "E" and slot ~= "R" and slot ~= "G" and slot ~= "X" and slot ~= "H") then
		return
	end
	local style = Config.STYLE_BY_ID[tostring(styleId)]
	local r = rootOf(model)
	if not style or not r or not near(r.Position, 260) then
		return
	end
	local c, c2 = style.color, style.color2
	local pos = r.Position
	local g = groundOf(pos)
	if slot == "H" then
		flashLight(pos, c2, 14, 2, 0.3)
		return
	end
	if slot == "E" or slot == "R" then
		flashLight(pos + Vector3.new(0, 1, 0), c2, 20, 3, 0.45)
		Fx.ring(g + Vector3.new(0, 0.3, 0), c2, 2, 12, 0.35)
		task.delay(0.06, function()
			Fx.ring(g + Vector3.new(0, 0.5, 0), c, 2, 9, 0.3)
		end)
		sparks(pos, c2, 14, 16)
		return
	end
	-- 오의 · 초 오의: 모으기 → 터짐
	local big = slot == "X"
	local gather = math.clamp(dur * 0.22, 0.18, big and 0.6 or 0.4)
	sparks(pos, c2, big and 40 or 26, big and 22 or 16, true)
	flashLight(pos, c, big and 30 or 22, 1.5, gather)
	Fx.ring(g + Vector3.new(0, 0.3, 0), c2, big and 30 or 22, 2, gather)
	task.delay(gather, function()
		if not r.Parent then
			return
		end
		local p2 = r.Position
		local g2 = groundOf(p2)
		flashLight(p2 + Vector3.new(0, 2, 0), c2, big and 60 or 40, big and 8 or 5, big and 0.9 or 0.6)
		for k = 0, 2 do
			task.delay(k * 0.07, function()
				Fx.ring(g2 + Vector3.new(0, 0.3 + k * 0.5, 0), k == 1 and WHITE or (k == 0 and c2 or c), 3, (big and 46 or 32) * (1 - k * 0.18), 0.55)
			end)
		end
		column(g2, big and 9 or 6, c2, big and 0.8 or 0.55)
		sigil(g2, big and 22 or 15, c, c2, big and 1.8 or 1.2)
		sparks(p2, c2, big and 50 or 30, big and 40 or 28)
		local dome = part(Vector3.one * 2, c2, 0.5, Enum.PartType.Ball, 0.5)
		dome.Position = p2
		tween(dome, 0.45, { Size = Vector3.new(big and 40 or 26, big and 22 or 14, big and 40 or 26), Transparency = 1 })
		if opts.shake and r.Parent and Players.LocalPlayer.Character and near(p2, 120) then
			pcall(opts.shake, big and 1.1 or 0.6)
		end
		if big and opts.tint and near(p2, 140) then
			pcall(opts.tint, c2, 0.18, 0.35)
		end
	end)
end

-- 맞힐 때 (Polish.hit 다음에): 빛, 강타 · 기술은 하얀 섬광 별
function Grand.hit(styleId: any, pos: Vector3, heavy: boolean, skill: boolean)
	if not near(pos, 200) then
		return
	end
	local style = Config.STYLE_BY_ID[tostring(styleId)]
	local c = style and style.color2 or WHITE
	flashLight(pos, c, (heavy or skill) and 16 or 9, (heavy or skill) and 3 or 1.4, (heavy or skill) and 0.25 or 0.14)
	if heavy or skill then
		local cam = workspace.CurrentCamera
		local face = cam and CFrame.lookAt(pos, cam.CFrame.Position) or CFrame.new(pos)
		for k = 0, 1 do
			local star = part(Vector3.new(0.18, 0.18, 0.18), k == 0 and WHITE or c, 0, nil, 0.22)
			star.CFrame = face * CFrame.Angles(0, 0, math.rad(45 * k))
			local L = heavy and 6 or 4.5
			tween(star, 0.08, { Size = Vector3.new(L, 0.26, 0.1) })
			task.delay(0.08, function()
				tween(star, 0.14, { Size = Vector3.new(L * 1.3, 0.05, 0.05), Transparency = 1 })
			end)
		end
	end
end

return Grand
