-- 권왕: 초월 권법 초·취팔선권의 화면 (초록 술병, 머리에 동여맨 넥타이, 기술 연출, 초 오의 취선만권의 컷씬)
-- 술병은 상표 없는 초록 유리병. 몸짓마다 초록 불길과 유리 조각, 술 방울이 튄다
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Drunk = {}
local player = Players.LocalPlayer

local GREEN = Color3.fromRGB(70, 200, 110)
local GLASS = Color3.fromRGB(60, 165, 95)
local PALE = Color3.fromRGB(215, 255, 225)
local FLAME = Color3.fromRGB(120, 255, 160)
local WHITE = Color3.new(1, 1, 1)
local TEX_FIRE = "rbxasset://textures/particles/fire_main.dds"
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local folder = Instance.new("Folder")
folder.Name = "KwonDrunk"
folder.Parent = workspace

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function rootOf(m: Instance?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
end
local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 1e-3 and f.Unit or Vector3.new(0, 0, -1)
end

-- 떠다니는 조각 (물리 없음)
local function part(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, shape: string?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Neon
	p.Transparency = alpha or 0
	if shape == "ball" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	elseif shape == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Parent = folder
	return p
end

------------------------------------------------------------------------
-- 술병과 넥타이 (손과 머리에 붙는다)
------------------------------------------------------------------------
local tails: { { weld: Weld, base: CFrame, phase: number } } = {}
local function attach(p: BasePart, to: BasePart, cf: CFrame, holder: Instance, list: { Instance }, flutter: number?)
	p.Massless = true
	p.Anchored = false
	if flutter then
		-- 넥타이 꼬리는 바람에 흔들린다 (용접 각도를 매 순간 바꾼다)
		local w = Instance.new("Weld")
		w.Part0 = to
		w.Part1 = p
		w.C0 = cf
		w.Parent = p
		table.insert(tails, { weld = w, base = cf, phase = flutter })
	else
		p.CFrame = to.CFrame * cf
		local w = Instance.new("WeldConstraint")
		w.Part0 = to
		w.Part1 = p
		w.Parent = p
	end
	p.Parent = holder
	table.insert(list, p)
end

-- 상표 없는 초록 유리병: 손이 목을 쥐고, 몸통은 새끼손가락 쪽으로 뻗는다
local function buildBottle(hand: BasePart, holder: Instance, list: { Instance })
	local up = CFrame.Angles(0, 0, math.rad(90)) -- 원기둥의 축(X)을 손의 위아래(Y)로
	local function cyl(len: number, d: number, y: number, color: Color3, mat: Enum.Material, alpha: number?)
		local p = part(Vector3.new(len, d, d), color, mat, alpha, "cyl")
		attach(p, hand, CFrame.new(0, y, 0) * up, holder, list)
		return p
	end
	cyl(0.75, 0.28, -0.05, GLASS, Enum.Material.Glass, 0.15) -- 목
	cyl(0.16, 0.31, 0.36, Color3.fromRGB(40, 120, 70), Enum.Material.Metal) -- 뚜껑
	local shoulder = part(Vector3.new(0.68, 0.5, 0.68), GLASS, Enum.Material.Glass, 0.2, "ball")
	attach(shoulder, hand, CFrame.new(0, -0.5, 0), holder, list)
	cyl(1.5, 0.68, -1.25, GLASS, Enum.Material.Glass, 0.22) -- 몸통
	cyl(1.1, 0.56, -1.35, Color3.fromRGB(225, 250, 230), Enum.Material.SmoothPlastic, 0.55) -- 속에 찰랑이는 술
	cyl(0.62, 0.7, -1.2, Color3.fromRGB(240, 245, 238), Enum.Material.SmoothPlastic) -- 빈 띠 (글씨 없음)
	cyl(0.05, 0.71, -0.9, GREEN, Enum.Material.SmoothPlastic)
	cyl(0.05, 0.71, -1.5, GREEN, Enum.Material.SmoothPlastic)
	cyl(0.06, 0.66, -2.0, Color3.fromRGB(40, 110, 65), Enum.Material.Glass, 0.1) -- 바닥
	-- 병 입구의 작은 초록 빛 (불을 뿜는 자리)
	local mouth = part(Vector3.new(0.12, 0.12, 0.12), FLAME, Enum.Material.Neon, 1)
	mouth.Name = "SojuMouth"
	attach(mouth, hand, CFrame.new(0, 0.45, 0), holder, list)
	local glow = Instance.new("PointLight")
	glow.Color = FLAME
	glow.Range = 5
	glow.Brightness = 0.5
	glow.Parent = mouth
end

-- 머리에 질끈 동여맨 붉은 넥타이: 이마를 한 바퀴 두르고, 오른쪽 뒤에 매듭, 두 꼬리가 늘어져 흔들린다
local function buildTie(head: BasePart, holder: Instance, list: { Instance })
	local r = math.max(head.Size.X, head.Size.Z) * 0.5 + 0.04
	local y = head.Size.Y * 0.2
	local red = Color3.fromRGB(205, 40, 50)
	local dark = Color3.fromRGB(120, 20, 35)
	local n = 14
	local chord = 2 * r * math.sin(math.pi / n) * 1.08
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		local p = part(Vector3.new(chord, 0.26, 0.06), k % 3 == 0 and dark or red, Enum.Material.Fabric)
		attach(p, head, CFrame.Angles(0, a, 0) * CFrame.new(0, y, -r), holder, list)
	end
	local knotA = math.rad(-125)
	local knotCF = CFrame.Angles(0, knotA, 0) * CFrame.new(0, y, -r - 0.08)
	local knot = part(Vector3.new(0.3, 0.3, 0.2), dark, Enum.Material.Fabric)
	attach(knot, head, knotCF, holder, list)
	-- 두 꼬리: 넓은 쪽과 좁은 쪽 (끝은 뾰족하게)
	for i, spec in ipairs({ { 0.34, 1.25, 18 }, { 0.24, 1.0, -14 } }) do
		local w, len, tilt = spec[1], spec[2], spec[3]
		local base = knotCF * CFrame.Angles(math.rad(-25), 0, math.rad(tilt)) * CFrame.new(0, -len / 2 - 0.1, -0.05)
		local tail = part(Vector3.new(w, len, 0.05), red, Enum.Material.Fabric)
		attach(tail, head, base, holder, list, i * 1.7)
		local tip = part(Vector3.new(w * 0.72, w * 0.72, 0.05), red, Enum.Material.Fabric)
		attach(tip, head, base * CFrame.new(0, -len / 2, 0) * CFrame.Angles(0, 0, math.rad(45)), holder, list, i * 1.7)
		-- 사선 줄무늬
		for s = 0, 1 do
			local stripe = part(Vector3.new(w * 1.02, 0.07, 0.055), dark, Enum.Material.Fabric)
			attach(stripe, head, base * CFrame.new(0, 0.25 - s * 0.45, 0) * CFrame.Angles(0, 0, math.rad(30)), holder, list, i * 1.7)
		end
	end
end

local mouths: { [Model]: BasePart } = {}
-- 몸 하나에 술병과 넥타이를 만든다 (Sakura가 부채와 같은 자리에서 부른다). 만든 것들을 돌려준다
function Drunk.build(model: Model): { Instance }
	local out: { Instance } = {}
	local holder = Instance.new("Folder")
	holder.Name = "Soju_" .. model.Name
	holder.Parent = folder
	table.insert(out, holder)
	local hand = model:FindFirstChild("RightHand")
	if hand and hand:IsA("BasePart") then
		buildBottle(hand, holder, out)
	end
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		buildTie(head, holder, out)
	end
	for _, p in ipairs(out) do
		if p.Name == "SojuMouth" and p:IsA("BasePart") then
			mouths[model] = p
		end
	end
	return out
end

RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for i = #tails, 1, -1 do
		local tl = tails[i]
		if not tl.weld.Parent then
			table.remove(tails, i)
		else
			tl.weld.C0 = tl.base * CFrame.Angles(math.sin(t * 3.1 + tl.phase) * 0.22, 0, math.sin(t * 2.3 + tl.phase) * 0.12)
		end
	end
	for m, p in pairs(mouths) do
		if not p.Parent or not m.Parent then
			mouths[m] = nil
		end
	end
end)

local function mouthOf(model: Model): Vector3?
	local p = mouths[model]
	if p and p.Parent then
		return p.Position
	end
	local h = model:FindFirstChild("RightHand")
	return (h and h:IsA("BasePart")) and h.Position or nil
end

------------------------------------------------------------------------
-- 작은 연출 조각들
------------------------------------------------------------------------
-- 술 방울이 튄다 (초록빛 도는 투명한 알갱이)
local function splash(pos: Vector3, n: number, spread: number, up: number?)
	for _ = 1, n do
		local d = part(Vector3.one * (0.25 + math.random() * 0.3), Color3.fromRGB(200, 245, 215), Enum.Material.Glass, 0.3, "ball")
		d.Position = pos
		local v = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit * spread * (0.4 + math.random() * 0.6) + Vector3.new(0, (up or 4) * (0.5 + math.random()), 0)
		local life = 0.45 + math.random() * 0.3
		tween(d, life, { Position = pos + v - Vector3.new(0, 3, 0), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Debris:AddItem(d, life + 0.05)
	end
end
-- 유리 조각이 튄다 (깨진 술병)
local function shards(pos: Vector3, n: number, spread: number)
	for _ = 1, n do
		local s = part(Vector3.new(0.4 + math.random() * 0.5, 0.05, 0.25 + math.random() * 0.4), GLASS, Enum.Material.Glass, 0.15)
		s.CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		local v = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit * spread * (0.5 + math.random() * 0.5)
		local life = 0.5 + math.random() * 0.4
		tween(s, life, { CFrame = CFrame.new(pos + v - Vector3.new(0, 2, 0)) * CFrame.Angles(math.random() * 12, math.random() * 12, math.random() * 12), Transparency = 1 })
		Debris:AddItem(s, life + 0.05)
	end
end
-- 초록 불길 기둥
local function flameAt(pos: Vector3, size: number, life: number)
	local p = part(Vector3.new(size, 0.2, size), FLAME, Enum.Material.Neon, 1)
	p.Position = pos
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = TEX_FIRE
	pe.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 255, 200)), ColorSequenceKeypoint.new(0.4, FLAME), ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 140, 120)) })
	pe.LightEmission = 0.9
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.6), NumberSequenceKeypoint.new(1, size * 0.15) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(0.5, 0.9)
	pe.Speed = NumberRange.new(size * 1.2, size * 2.2)
	pe.SpreadAngle = Vector2.new(12, 12)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.Rate = 40
	pe.Parent = p
	task.delay(life, function()
		pe.Enabled = false
	end)
	Debris:AddItem(p, life + 1)
end
-- 반달 휘두름 자국 (초록)
local function swoosh(cf: CFrame, radius: number, life: number, thick: number)
	local n = 9
	for i = 0, n - 1 do
		local a = -1.2 + 2.4 * i / (n - 1)
		local seg = part(Vector3.new(radius * 2.4 / n, thick * (1 - math.abs(a) * 0.5), 0.08), i % 2 == 0 and GREEN or PALE, Enum.Material.Neon, 0.15)
		seg.CFrame = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -radius)
		tween(seg, life, { Transparency = 1, Size = seg.Size * Vector3.new(1.2, 0.2, 1) })
		Debris:AddItem(seg, life + 0.05)
	end
end
-- 초록 반투명 잔상 (몸을 본뜬 그림자)
local function ghostOf(model: Model, at: CFrame, color: Color3, alpha: number): { BasePart }
	local r = rootOf(model)
	local out = {}
	if not r then
		return out
	end
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.9 then
			local g = part(d.Size, color, Enum.Material.Neon, alpha)
			g.CFrame = at * r.CFrame:ToObjectSpace(d.CFrame)
			table.insert(out, g)
		end
	end
	return out
end

------------------------------------------------------------------------
-- 연타·강타·기술을 쓸 때 (모두가 본다)
------------------------------------------------------------------------
function Drunk.cast(styleId: any, slot: any, model: Model, dur: number)
	local st = type(styleId) == "string" and Config.STYLE_BY_ID[styleId] or nil
	if not st or not st.soju then
		return
	end
	local r = rootOf(model)
	if not r or not near(r.Position, 160) then
		return
	end
	if type(slot) == "number" or slot == "H" or slot == "F" then
		local big = slot == 4 or slot == "H" or slot == "F"
		task.delay(math.min(0.14, dur * 0.4), function()
			local look = r.CFrame
			swoosh(look * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, (type(slot) == "number" and slot % 2 == 0) and 0.6 or -0.6), big and 6 or 4, big and 0.4 or 0.25, big and 0.9 or 0.5)
			local m = mouthOf(model)
			if m then
				splash(m, big and 10 or 4, big and 6 or 3, 3)
			end
			if slot == 4 or slot == "F" then
				local feet = (look * CFrame.new(0, -2.4, -3)).Position
				Fx.ring(feet, GREEN, 2, 16, 0.35)
				shards(feet + Vector3.new(0, 1, 0), 8, 6)
				Fx.sound("block", 0.5, 1.5, feet)
			elseif slot == "H" then
				Fx.afterimage(model, GREEN, 0.3)
			end
		end)
	elseif slot == "E" then
		local m = mouthOf(model)
		if m then
			splash(m, 10, 3, 5)
		end
	elseif slot == "R" then
		Fx.text(r.Position + Vector3.new(0, 4, 0), "딸꾹!", PALE, 26, 0.9)
	elseif slot == "G" then
		splash(r.Position + Vector3.new(0, 2, 0), 16, 6, 6)
		Fx.ring(r.Position - Vector3.new(0, 2.4, 0), GREEN, 2, 26, 0.6)
	end
end

------------------------------------------------------------------------
-- 기술 장치의 연출 (서버의 skillfx)
------------------------------------------------------------------------
-- 취화방사 (E): 병 입구에서 초록 불길이 앞으로 뿜어져 나간다
local function sprayCone(data: any)
	local m0: Model? = data.m
	local r = rootOf(m0)
	if not m0 or not r or not near(r.Position, 200) then
		return
	end
	local m = m0 :: Model
	local range = data.range or 20
	local nozzle = part(Vector3.new(0.4, 0.4, 0.4), FLAME, Enum.Material.Neon, 1)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = TEX_FIRE
	pe.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 255, 220)), ColorSequenceKeypoint.new(0.3, FLAME), ColorSequenceKeypoint.new(0.75, GREEN), ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 110, 90)) })
	pe.LightEmission = 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.5, 3.2), NumberSequenceKeypoint.new(1, 5) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.7, 0.4), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(0.4, 0.55)
	pe.Speed = NumberRange.new(range * 1.7, range * 2.1)
	pe.SpreadAngle = Vector2.new((data.angle or 60) * 0.35, (data.angle or 60) * 0.2)
	pe.EmissionDirection = Enum.NormalId.Front
	pe.Drag = 1.2
	pe.Rate = 0
	pe.Parent = nozzle
	local light = Instance.new("PointLight")
	light.Color = FLAME
	light.Range = 18
	light.Brightness = 2
	light.Parent = nozzle
	local delay = data.delay or 0
	local dur = data.dur or 1.6
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > delay + dur + 0.6 or not m.Parent then
			conn:Disconnect()
			nozzle:Destroy()
			return
		end
		local from = mouthOf(m) or r.Position
		local look = flat(r.CFrame.LookVector)
		nozzle.CFrame = CFrame.lookAt(from, from + look + Vector3.new(0, -0.05, 0))
		pe.Rate = (t > delay and t < delay + dur) and 90 or 0
	end)
	task.delay(delay, function()
		Fx.sound("splash", 0.5, 1.6, r.Position)
	end)
end

-- 팔선취보 (R): 걸음마다 초록 잔상과 술 방울
local function zigzagStep(data: any)
	local to0: Vector3? = data.to
	if not to0 or not near(to0, 200) then
		return
	end
	local to = to0 :: Vector3
	local m: Model? = data.m
	if m then
		Fx.afterimage(m, GREEN, 0.35)
	end
	Fx.ring(to - Vector3.new(0, 2.5, 0), GREEN, 1.5, 11, 0.3)
	splash(to, 5, 4, 3)
	if data.i and data.i % 3 == 0 then
		Fx.text(to + Vector3.new(0, 4, 0), "딸꾹", PALE, 20, 0.7)
	end
	Fx.sound("swing", 0.35, 0.8 + math.random() * 0.3, to)
end

-- 취몽팔선진 (G): 하늘로 던진 술병 → 깨져서 술비 → 웅덩이
local puddles: { [any]: Part } = {}
local function sojuThrow(data: any)
	local at: Vector3 = data.at
	if not at or not near(at, 260) then
		return
	end
	local radius = data.radius or 26
	local delay = data.delay or 0.6
	local rain = data.rain or 1.6
	local m: Model? = data.m
	local from = (m and mouthOf(m)) or at + Vector3.new(0, 3, 0)
	local top = at + Vector3.new(0, 34, 0)
	-- 날아오르며 빙글빙글 도는 술병
	local bottle = part(Vector3.new(1.6, 0.7, 0.7), GLASS, Enum.Material.Glass, 0.2, "cyl")
	bottle.CFrame = CFrame.new(from)
	tween(bottle, delay, { CFrame = CFrame.new(top) * CFrame.Angles(math.pi * 6, math.pi * 2, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	Debris:AddItem(bottle, delay + 0.05)
	task.delay(delay, function()
		-- 하늘에서 깨진다
		shards(top, 26, 16)
		Fx.flash(top, FLAME, 60, 4, 0.4)
		Fx.breakSound("glass", 1, 0.9, at)
		-- 술비: 둘레 위에서 방울이 쏟아진다
		local cloud = part(Vector3.new(radius * 2, 1, radius * 2), PALE, Enum.Material.Neon, 1)
		cloud.Position = at + Vector3.new(0, 26, 0)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = TEX_SPARK
		pe.Color = ColorSequence.new(Color3.fromRGB(215, 255, 230), Color3.fromRGB(150, 230, 180))
		pe.LightEmission = 0.5
		pe.Size = NumberSequence.new(0.35, 0.2)
		pe.Squash = NumberSequence.new(-2) -- 길쭉한 빗줄기
		pe.Transparency = NumberSequence.new(0.2, 0.6)
		pe.Lifetime = NumberRange.new(0.6, 0.8)
		pe.Speed = NumberRange.new(36, 44)
		pe.EmissionDirection = Enum.NormalId.Bottom
		pe.SpreadAngle = Vector2.new(4, 4)
		pe.Shape = Enum.ParticleEmitterShape.Box
		pe.Rate = 260
		pe.Parent = cloud
		task.delay(rain, function()
			pe.Enabled = false
		end)
		Debris:AddItem(cloud, rain + 1)
		-- 바닥에 번지는 술 웅덩이
		local pool = part(Vector3.new(0.12, 2, 2), Color3.fromRGB(190, 240, 205), Enum.Material.Glass, 0.45, "cyl")
		pool.CFrame = CFrame.new(at - Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
		tween(pool, rain, { Size = Vector3.new(0.12, radius * 2, radius * 2) }, Enum.EasingStyle.Sine)
		puddles[data.m or at] = pool
		Debris:AddItem(pool, rain + 3)
	end)
end
-- 불똥 하나에 웅덩이가 타오르고, 여덟 취선의 그림자가 한가운데로 덮친다
local function sojuIgnite(data: any)
	local at: Vector3 = data.at
	if not at or not near(at, 260) then
		return
	end
	local radius = data.radius or 26
	local pool = puddles[data.m or at]
	puddles[data.m or at] = nil
	if pool and pool.Parent then
		pool.Material = Enum.Material.Neon
		pool.Color = FLAME
		tween(pool, 1.4, { Transparency = 1 })
	end
	-- 바닥 가득 초록 불길
	for k = 0, 13 do
		local a = k / 14 * math.pi * 2
		for _, rr in ipairs({ radius * 0.45, radius * 0.85 }) do
			flameAt(at + Vector3.new(math.cos(a) * rr, -2.4, math.sin(a) * rr), 3 + math.random() * 2, 1.1)
		end
	end
	flameAt(at - Vector3.new(0, 2.4, 0), 8, 1.2)
	Fx.flash(at, FLAME, radius * 3, 5, 0.6)
	Fx.sound("heavy", 1, 0.6, at)
	-- 여덟 취선의 그림자
	local m: Model? = data.m
	local n = data.ghosts or 8
	local targets: { Model } = data.targets or {}
	if m then
		for i = 1, n do
			local a = (i - 1) / n * math.pi * 2
			local from = at + Vector3.new(math.cos(a) * radius * 0.7, 0, math.sin(a) * radius * 0.7)
			local tgt = targets[((i - 1) % math.max(1, #targets)) + 1]
			local tr = tgt and rootOf(tgt)
			local to = tr and tr.Position or at
			local cf0 = CFrame.lookAt(from, Vector3.new(to.X, from.Y, to.Z))
			local list = ghostOf(m, cf0, i % 2 == 0 and GREEN or PALE, 0.45)
			local lunge = flat(to - from) * math.max(0, (to - from).Magnitude - 3)
			for _, g in ipairs(list) do
				tween(g, 0.32, { CFrame = g.CFrame + lunge }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
				task.delay(0.32, function()
					tween(g, 0.3, { Transparency = 1 })
				end)
				Debris:AddItem(g, 0.7)
			end
		end
	end
	task.delay(0.35, function()
		for _, t in ipairs(targets) do
			local tr = rootOf(t)
			if tr then
				Fx.blast(tr.Position, GREEN, PALE, 1.4)
				shards(tr.Position, 6, 6)
			end
		end
		Fx.ring(at - Vector3.new(0, 2.3, 0), FLAME, 4, radius * 2.4, 0.6)
	end)
end

-- 취선만권 (X): 구르는 몸에 초록 잔상 (모두가 본다)
local function rushCut(data: any)
	local m0: Model? = data.m
	local r = rootOf(m0)
	if not m0 or not r or not near(r.Position, 200) then
		return
	end
	local m = m0 :: Model
	local dur = data.dur or 1
	local t0 = os.clock()
	local last = 0
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > dur or not m.Parent then
			conn:Disconnect()
			return
		end
		-- 갈수록 잔상이 촘촘해진다
		local gap = 0.14 - 0.1 * (t / dur)
		if t - last > gap then
			last = t
			Fx.afterimage(m, t / dur > 0.6 and PALE or GREEN, 0.25)
			Fx.dust(r.Position - Vector3.new(0, 2.6, 0), 1.2 + t / dur)
		end
	end)
end
-- 와다다다: 앞으로 쏟아지는 주먹 그림자와 맞는 자리의 불꽃
local function rushFlurry(data: any)
	local m0: Model? = data.m
	local r = rootOf(m0)
	if not m0 or not r or not near(r.Position, 200) then
		return
	end
	local m = m0 :: Model
	local dur = data.dur or 1.8
	Fx.text(r.Position + Vector3.new(0, 6, 0), "와다다다다다!", Color3.fromRGB(230, 255, 120), 40, 1.4)
	local t0 = os.clock()
	local last = 0
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > dur or not m.Parent then
			conn:Disconnect()
			return
		end
		if t - last < 0.035 then
			return
		end
		last = t
		local cf = r.CFrame
		for _ = 1, 2 do
			local off = Vector3.new((math.random() - 0.5) * 2.6, (math.random() - 0.3) * 1.8, 0)
			local fist = part(Vector3.new(0.9, 0.9, 0.9), math.random() < 0.5 and GREEN or PALE, Enum.Material.Neon, 0.25, "ball")
			fist.CFrame = cf * CFrame.new(off + Vector3.new(0, 0.6, -1.2))
			tween(fist, 0.16, { CFrame = cf * CFrame.new(off * 1.3 + Vector3.new(0, 0.6, -4.5)), Transparency = 1, Size = Vector3.new(1.6, 1.6, 0.4) })
			Debris:AddItem(fist, 0.2)
		end
		if math.random() < 0.35 then
			local hitAt = (cf * CFrame.new((math.random() - 0.5) * 3, 0.6 + (math.random() - 0.5) * 2, -4)).Position
			Fx.spark(hitAt, math.random() < 0.5 and WHITE or FLAME, 0.7, 3)
			Fx.sound("hit", 0.25, 1.2 + math.random() * 0.4, hitAt)
		end
	end)
end
-- 마지막: 술병을 깨뜨리며 초록 불길이 터진다
local function rushEnd(data: any)
	local at: Vector3 = data.at
	if not at or not near(at, 260) then
		return
	end
	local radius = data.radius or 22
	shards(at + Vector3.new(0, 1, 0), 30, 14)
	splash(at, 24, 12, 8)
	Fx.blast(at, GREEN, PALE, 3)
	Fx.flash(at, FLAME, 90, 6, 0.5)
	Fx.ring(at - Vector3.new(0, 2.3, 0), FLAME, 4, radius * 2.6, 0.6)
	Fx.ring(at - Vector3.new(0, 2.2, 0), WHITE, 3, radius * 1.6, 0.4)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		flameAt(at + Vector3.new(math.cos(a) * radius * 0.5, -2.4, math.sin(a) * radius * 0.5), 4, 0.8)
	end
	Fx.breakSound("rock", 1, 0.8, at)
	Fx.sound("heavy", 1, 0.5, at)
end

local HANDLERS: { [string]: (any) -> () } = {
	zigzagStep = zigzagStep,
	sojuThrow = sojuThrow,
	sojuIgnite = sojuIgnite,
	rushCut = rushCut,
	rushFlurry = rushFlurry,
	rushEnd = rushEnd,
}
function Drunk.handles(data: any): boolean
	return (data.kind == "cone" and data.fx == "soju") or data.kind == "zigzagStart" or HANDLERS[data.kind] ~= nil
end
function Drunk.run(data: any)
	if data.kind == "cone" then
		sprayCone(data)
		return
	end
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

------------------------------------------------------------------------
-- 초 오의 취선만권의 컷씬 (쓴 사람 화면에서만, 1.6초, 대사 없이):
-- 위아래 검은 띠, 옆에서 낮게 잡은 카메라, 점점 빨라지는 앞구르기와 몰려드는 속도선 → 띠가 걷히며 와다다다
------------------------------------------------------------------------
local cutActive = false
function Drunk.superCut(model: Model, dur: number, name: string, shake: ((number) -> ())?)
	local cam = workspace.CurrentCamera
	local r = rootOf(model)
	if not cam or not r or cutActive then
		return
	end
	cutActive = true
	local pg = player:WaitForChild("PlayerGui")
	local g = Instance.new("ScreenGui")
	g.Name = "KwonDrunkCut"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 85
	g.Parent = pg
	-- 초록빛 도는 가장자리
	local tintF = Instance.new("Frame")
	tintF.Size = UDim2.fromScale(1, 1)
	tintF.BackgroundColor3 = Color3.fromRGB(20, 60, 35)
	tintF.BackgroundTransparency = 1
	tintF.BorderSizePixel = 0
	tintF.Parent = g
	local grad = Instance.new("UIGradient")
	grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 0.2) })
	grad.Parent = tintF
	tween(tintF, 0.15, { BackgroundTransparency = 0.55 })
	-- 속도선: 화면을 가로질러 뒤로 흘러간다 (갈수록 빠르다)
	local lines: { Frame } = {}
	for i = 1, 16 do
		local l = Instance.new("Frame")
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.fromScale(math.random(), 0.15 + 0.7 * (i - 0.5) / 16)
		l.Size = UDim2.new(0.1 + math.random() * 0.2, 0, 0, 2 + math.random(0, 2))
		l.BackgroundColor3 = i % 3 == 0 and PALE or WHITE
		l.BackgroundTransparency = 0.35
		l.BorderSizePixel = 0
		l.ZIndex = 2
		l.Parent = g
		table.insert(lines, l)
	end
	-- 위아래 검은 띠
	local bars: { Frame } = {}
	for i, y in ipairs({ 0, 1 }) do
		local b = Instance.new("Frame")
		b.AnchorPoint = Vector2.new(0, y)
		b.Position = UDim2.fromScale(0, y)
		b.Size = UDim2.new(1, 0, 0, 0)
		b.BackgroundColor3 = Color3.new(0, 0, 0)
		b.BorderSizePixel = 0
		b.ZIndex = 5
		b.Parent = g
		tween(b, 0.12, { Size = UDim2.new(1, 0, 0.14, 0) })
		bars[i] = b
	end
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(1, 0.5)
	label.Position = UDim2.new(1, -30, 0.5, 0)
	label.Size = UDim2.new(0.5, 0, 0.45, 0)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.Text = "초 오의 · " .. name
	label.TextColor3 = PALE
	label.TextStrokeColor3 = GREEN
	label.TextStrokeTransparency = 0.3
	label.TextTransparency = 1
	label.ZIndex = 6
	label.Parent = bars[2]
	tween(label, 0.2, { TextTransparency = 0 })

	-- 카메라: 구르는 방향의 옆에서 낮게 (시작할 때의 방향으로 고정)
	local oldType = cam.CameraType
	local oldFov = cam.FieldOfView
	local look = flat(r.CFrame.LookVector)
	local side = Vector3.new(-look.Z, 0, look.X)
	cam.CameraType = Enum.CameraType.Scriptable
	local t0 = os.clock()
	local focus = r.Position
	local finished = false
	local function restore()
		if finished then
			return
		end
		finished = true
		RunService:UnbindFromRenderStep("KwonDrunkCut")
		cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
		cam.FieldOfView = oldFov
		cutActive = false
		-- 1.9.3판: 컷씬이 끝나면 카메라를 내 등 뒤 조금 높은 곳으로 (앞에서 터지는 기술이 잘 보이게)
		local function behind()
			if r.Parent then
				local lk = flat(r.CFrame.LookVector)
				cam.CFrame = CFrame.lookAt(r.Position - lk * 15 + Vector3.new(0, 6, 0), r.Position + lk * 6 + Vector3.new(0, 1, 0))
			end
		end
		behind()
		task.defer(behind)
	end
	RunService:BindToRenderStep("KwonDrunkCut", Enum.RenderPriority.Camera.Value, function(dt: number)
		if finished then
			return
		end
		local t = os.clock() - t0
		local u = math.clamp(t / dur, 0, 1)
		if not r.Parent then
			restore()
			return
		end
		focus = focus:Lerp(r.Position, math.min(1, dt * 14))
		-- 처음엔 옆에서, 끝으로 갈수록 앞쪽으로 돌아 들어간다
		local orbit = side * (10 - 3 * u) + look * (-2 + 6 * u) + Vector3.new(0, 1.6 - 0.6 * u, 0)
		cam.CFrame = CFrame.lookAt(focus + orbit, focus + look * (2 + 3 * u) + Vector3.new(0, -0.3, 0))
		cam.FieldOfView = oldFov - 18 + 10 * u * u
		-- 속도선이 점점 빨라진다
		local speed = 1.2 + 6 * u * u
		for i, l in ipairs(lines) do
			local x = l.Position.X.Scale - speed * dt * (0.8 + (i % 4) * 0.15)
			if x < -0.2 then
				x += 1.4
			end
			l.Position = UDim2.fromScale(x, l.Position.Y.Scale)
			l.BackgroundTransparency = 0.6 - 0.4 * u
		end
		if shake and u > 0.5 then
			shake(0.15 + u * 0.5)
		end
	end)
	task.delay(dur, function()
		restore()
		-- 띠가 걷히고 하얗게 번쩍인 뒤 와다다다
		for _, b in ipairs(bars) do
			tween(b, 0.18, { Size = UDim2.new(1, 0, 0, 0) })
		end
		tween(label, 0.15, { TextTransparency = 1, TextStrokeTransparency = 1 })
		for _, l in ipairs(lines) do
			l:Destroy()
		end
		tintF.BackgroundColor3 = Color3.fromRGB(235, 255, 240)
		tintF.BackgroundTransparency = 0.2
		grad:Destroy()
		tween(tintF, 0.3, { BackgroundTransparency = 1 })
		if shake then
			shake(1.4)
		end
		Debris:AddItem(g, 0.5)
	end)
end

return Drunk
