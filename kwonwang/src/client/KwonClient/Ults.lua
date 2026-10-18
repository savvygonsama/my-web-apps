-- 권왕: 오의 연출 (권법마다 전혀 다른 종류)
--   혈마: 등 뒤로 솟는 거대한 악마의 허상     무영: 적마다 나타나는 그림자 분신
--   천룡: 땅을 뚫고 나와 날아다니는 진짜 용     금강: 내 몸이 금빛 거인이 된다
--   태허: 발밑이 호수가 되는 소용돌이와 물기둥   매화: 세상이 멈춘 듯한 일순의 베기
--   벽력: 몸이 번개가 되어 튀어 다닌다          취권: 불덩이가 되어 튕겨 다닌다
--   무극: 빛깔이 뒤집히고 하늘에 눈이 열린다     삼재: 모았다가 단 한 번의 주먹
--   천제: 하늘의 문과 빛의 검 비                파천: 하늘에 뜬 검은 해가 모두를 빨아올린다
--   풍신: 앞으로 나아가는 거대한 회오리          태초: 세상이 멈춰 별바다가 되고, 유리처럼 깨진다
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))
local Anim = require(script.Parent:WaitForChild("Anim"))

local Ults = {}
local hooks: any = {}

function Ults.init(h: any)
	hooks = h
end

local folder = Instance.new("Folder")
folder.Name = "KwonUlts"
folder.Parent = workspace

local function piece(size: Vector3, color: Color3, material: Enum.Material?, shape: Enum.PartType?, transparency: number?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Neon
	if shape then
		p.Shape = shape
	end
	p.Transparency = transparency or 0
	p.Parent = folder
	return p
end
local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function fade(p: Instance, after: number, life: number)
	task.delay(after, function()
		if p.Parent then
			tween(p, life, { Transparency = 1 })
		end
	end)
	Debris:AddItem(p, after + life + 0.05)
end
local function rootOf(m: Model?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 1e-3 and f.Unit or Vector3.new(0, 0, -1)
end
local function styleColors(id: any): (Color3, Color3)
	local s = type(id) == "string" and Config.STYLE_BY_ID[id]
	return s and s.color or Color3.new(1, 1, 1), s and s.color2 or Color3.new(1, 1, 1)
end
local function near(at: Vector3, r: number): boolean
	local me = Players.LocalPlayer.Character
	local root = rootOf(me)
	return root ~= nil and (root.Position - at).Magnitude < r
end
-- 화면 빛깔을 잠깐 바꾼다 (흑백, 뒤집힘, 어둠)
local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "KwonUltGrade"
grade.Parent = Lighting
local function colorGrade(sat: number, contrast: number, bright: number, tintColor: Color3, hold: number)
	grade.Saturation = sat
	grade.Contrast = contrast
	grade.Brightness = bright
	grade.TintColor = tintColor
	task.delay(hold, function()
		tween(grade, 0.4, { Saturation = 0, Contrast = 0, Brightness = 0, TintColor = Color3.new(1, 1, 1) })
	end)
end

------------------------------------------------------------------------
-- 허상 몸 (관절이 있어 몸동작을 그대로 쓴다)
------------------------------------------------------------------------
local RIG = {
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

-- 허상 하나: s배 크기, 빛깔과 재질, 붙은 장식(뿔·날개·눈 ...)은 add로
local function spirit(s: number, color: Color3, material: Enum.Material, trans: number, styleId: string, cf: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "KwonSpirit"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1) * s
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.Parent = model
	model.PrimaryPart = root
	local parts: { [string]: BasePart } = { HumanoidRootPart = root }
	for _, r in ipairs(RIG) do
		local name, size, center, parentName, jointName, joint = r[1], r[2], r[3], r[4], r[5], r[6]
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * s
		p.CFrame = CFrame.new(center * s)
		p.Color = color
		p.Material = material
		p.Transparency = trans
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		if name == "Head" then
			p.Shape = Enum.PartType.Ball
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
	model:SetAttribute("Style", styleId)
	model:SetAttribute("Master", true) -- 가만히 있어도 딴짓하지 않게
	model:PivotTo(cf)
	model.Parent = folder
	return model
end
-- 허상에 장식 붙이기 (몸 부위에 용접)
local function attach(model: Model, partName: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?, trans: number?): Part?
	local base = model:FindFirstChild(partName)
	if not base or not base:IsA("BasePart") then
		return nil
	end
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Neon
	if shape then
		p.Shape = shape
	end
	p.Transparency = trans or 0
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.CFrame = base.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
	p.Parent = model
	return p
end
local function vanish(model: Model, after: number, life: number)
	task.delay(after, function()
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				tween(d, life, { Transparency = 1 })
			end
		end
	end)
	Debris:AddItem(model, after + life + 0.1)
end
local function rise(model: Model, from: CFrame, to: CFrame, time: number)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - start) / time, 0, 1)
		k = 1 - (1 - k) ^ 3
		if model.Parent then
			model:PivotTo(from:Lerp(to, k))
		end
		if k >= 1 or not model.Parent then
			conn:Disconnect()
		end
	end)
end

------------------------------------------------------------------------
-- 혈마의 허상: 뿔, 날개, 빛나는 눈, 손톱. 등 뒤에서 솟아 적을 찢는다
------------------------------------------------------------------------
local demons: { [Model]: Model } = {}
local function demonSummon(caster: Model, dur: number, styleId: string)
	local r = rootOf(caster)
	if not r then
		return
	end
	local look = flat(r.CFrame.LookVector)
	local s = 4.4
	local base = r.Position - look * 8
	local to = CFrame.lookAt(base + Vector3.new(0, 2.6 * s - 2.5, 0), base + Vector3.new(0, 2.6 * s - 2.5, 0) + look)
	local from = to - Vector3.new(0, 3 * s, 0)
	local d = spirit(s, Color3.fromRGB(110, 5, 15), Enum.Material.Neon, 0.35, styleId, from)
	local red, gold = Color3.fromRGB(255, 40, 40), Color3.fromRGB(255, 220, 90)
	for _, x in ipairs({ -1, 1 }) do
		-- 휘어진 뿔 두 마디
		attach(d, "Head", Vector3.new(0.5, 1.6, 0.5) * s * 0.5, CFrame.new(x * 0.35 * s, 0.55 * s, 0) * CFrame.Angles(0, 0, x * math.rad(-35)), Color3.fromRGB(30, 0, 0), Enum.Material.SmoothPlastic)
		attach(d, "Head", Vector3.new(0.35, 1.2, 0.35) * s * 0.5, CFrame.new(x * 0.62 * s, 1.0 * s, 0.1 * s) * CFrame.Angles(math.rad(20), 0, x * math.rad(-5)), Color3.fromRGB(30, 0, 0), Enum.Material.SmoothPlastic)
		-- 빛나는 눈
		attach(d, "Head", Vector3.new(0.22, 0.1, 0.05) * s, CFrame.new(x * 0.2 * s, 0.08 * s, -0.55 * s), gold, Enum.Material.Neon)
		-- 박쥐 날개 (세 겹)
		for k = 0, 2 do
			attach(d, "UpperTorso", Vector3.new(0.1, 1.6 - k * 0.3, 3.2 - k * 0.6) * s, CFrame.new(x * (1.3 + k * 0.9) * s, (0.6 - k * 0.35) * s, 0.7 * s) * CFrame.Angles(math.rad(10), x * math.rad(70 - k * 8), x * math.rad(-20 - k * 10)), Color3.fromRGB(60, 0, 5), Enum.Material.Neon, nil, 0.3)
		end
	end
	for _, side in ipairs({ "RightHand", "LeftHand" }) do
		for k = -1, 1 do
			attach(d, side, Vector3.new(0.15, 1.1, 0.15) * s, CFrame.new(k * 0.3 * s, -0.55 * s, -0.2 * s) * CFrame.Angles(math.rad(-20), 0, 0), red, Enum.Material.Neon)
		end
	end
	local core = attach(d, "UpperTorso", Vector3.new(0.6, 0.6, 0.6) * s, CFrame.new(0, 0.2 * s, -0.45 * s), red, Enum.Material.Neon, Enum.PartType.Ball)
	if core then
		local l = Instance.new("PointLight")
		l.Color = red
		l.Range = 40
		l.Brightness = 4
		l.Parent = core
	end
	rise(d, from, to, 0.6)
	Fx.ring(base - Vector3.new(0, 2.4, 0), red, 4, 46, 0.7)
	Fx.text(base + Vector3.new(0, 3 * s, 0), "혈마 강림", red, 44, 1.2)
	task.delay(0.65, function()
		Anim.play(d, "blood_spread", 0.8)
	end)
	demons[caster] = d
	-- 솟은 뒤에는 주인의 등 뒤를 따라다닌다
	local following = false
	task.delay(0.65, function()
		following = true
	end)
	local followConn: RBXScriptConnection
	followConn = RunService.RenderStepped:Connect(function(dt)
		local rr = rootOf(caster)
		if not d.Parent or not rr or demons[caster] ~= d then
			followConn:Disconnect()
			return
		end
		if not following then
			return
		end
		local cur = d:GetPivot()
		local want = rr.Position - flat(rr.CFrame.LookVector) * 8 + Vector3.new(0, 2.6 * s - 2.5, 0)
		d:PivotTo(cur.Rotation + cur.Position:Lerp(want, math.clamp(dt * 5, 0, 1)))
	end)
	task.delay(dur, function()
		if demons[caster] == d then
			demons[caster] = nil
		end
		Anim.play(d, "ult_blood", 0.8)
		local now = d:GetPivot()
		rise(d, now, now - Vector3.new(0, 3 * s, 0), 0.8)
	end)
	vanish(d, dur + 0.3, 0.5)
	if hooks.shake and near(base, 80) then
		hooks.shake(1.4)
	end
end
local function demonStrike(caster: Model, data: any)
	local d = demons[caster]
	local spots = data.at or {}
	local red = Color3.fromRGB(255, 40, 40)
	if d and d.PrimaryPart and spots[1] then
		local p = d.PrimaryPart.Position
		d:PivotTo(CFrame.lookAt(p, Vector3.new(spots[1].X, p.Y, spots[1].Z)))
		Anim.play(d, data.last and "blood_spread" or (data.idx % 2 == 1 and "blood_claw_r" or "blood_claw_l"), 0.55)
	end
	for _, at in ipairs(spots) do
		local g = at - Vector3.new(0, 2.4, 0)
		if data.last then
			-- 포효: 핏빛 충격파가 둘레를 쓸어 낸다
			for k = 0, 3 do
				task.delay(k * 0.07, function()
					Fx.ring(g + Vector3.new(0, 0.5 + k, 0), k % 2 == 0 and red or Color3.fromRGB(80, 0, 0), 4, (data.radius or 20) * 2.4, 0.6)
				end)
			end
			if hooks.flash and near(at, 70) then
				hooks.flash(Color3.fromRGB(255, 30, 30), 0.35)
			end
		else
			-- 거대한 손톱 세 줄이 하늘에서 비스듬히 그어진다
			for i = -1, 1 do
				local bar = piece(Vector3.new(0.9, 0.9, 30), i == 0 and Color3.fromRGB(255, 160, 160) or red, Enum.Material.Neon, nil, 0)
				local top = at + Vector3.new(i * 2, 18, -6)
				bar.CFrame = CFrame.lookAt(top, at + Vector3.new(i * 2, -3, 6))
				tween(bar, 0.35, { Size = Vector3.new(0.1, 0.1, 34), Transparency = 1 })
				Debris:AddItem(bar, 0.4)
			end
			Fx.ring(g + Vector3.new(0, 0.3, 0), red, 2, (data.radius or 8) * 2.2, 0.4)
			Fx.spark(at, red, 2.4, 12)
		end
	end
	if hooks.shake and spots[1] and near(spots[1], 70) then
		hooks.shake(data.last and 1.6 or 0.9)
	end
end

------------------------------------------------------------------------
-- 진룡: 마디마디 이어진 용이 땅에서 솟아 날아다닌다
------------------------------------------------------------------------
local dragons: { [Model]: any } = {}
local function dragonSummon(caster: Model, dur: number, styleId: string)
	local r = rootOf(caster)
	if not r then
		return
	end
	local c, c2 = styleColors(styleId)
	local look = flat(r.CFrame.LookVector)
	local right = Vector3.new(-look.Z, 0, look.X)
	local base = r.Position - Vector3.new(0, 2.5, 0)
	local segs = {}
	local N = 26
	for i = 1, N do
		local sz = 5.5 * (1 - i / N * 0.75)
		local seg = piece(Vector3.new(sz, sz, sz), c:Lerp(c2, (i % 4) / 4), Enum.Material.Neon, Enum.PartType.Ball, 0.1)
		seg.Position = base - Vector3.new(0, 20, 0)
		table.insert(segs, seg)
		-- 등지느러미
		if i % 3 == 0 and i < N - 3 then
			local fin = piece(Vector3.new(0.4, sz * 0.9, sz * 0.6), c2, Enum.Material.Neon, nil, 0.2)
			fin.Position = seg.Position
			table.insert(segs, fin)
			fin:SetAttribute("FinOf", i)
		end
	end
	local head = piece(Vector3.new(6, 5, 9), c, Enum.Material.Neon, nil, 0)
	local jaw = piece(Vector3.new(5, 1.4, 7), c2, Enum.Material.Neon, nil, 0)
	local horns = { piece(Vector3.new(0.8, 0.8, 7), Color3.fromRGB(255, 230, 150), Enum.Material.Neon), piece(Vector3.new(0.8, 0.8, 7), Color3.fromRGB(255, 230, 150), Enum.Material.Neon) }
	local eyes = { piece(Vector3.new(1, 1, 1), Color3.fromRGB(255, 255, 200), Enum.Material.Neon, Enum.PartType.Ball), piece(Vector3.new(1, 1, 1), Color3.fromRGB(255, 255, 200), Enum.Material.Neon, Enum.PartType.Ball) }
	local light = Instance.new("PointLight")
	light.Color = c
	light.Range = 50
	light.Brightness = 3
	light.Parent = head
	local d: any = {
		fast = false,
		open = false,
		target = base + right * 14 + Vector3.new(0, 26, 0),
		pos = base - Vector3.new(0, 10, 0),
		trail = {},
		lookAt = base + look * 20,
	}
	dragons[caster] = d
	-- 땅을 뚫고 솟는 순간
	Fx.ring(base + right * 10, c, 4, 30, 0.6)
	Fx.dust(base + right * 10, 6)
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt: number)
		local t = os.clock() - start
		-- 머리가 목표를 향해 굽이치며 날아간다
		local wob = Vector3.new(math.sin(t * 3) * 3, math.cos(t * 4) * 2, 0)
		d.pos = d.pos:Lerp(d.target + wob, math.min(1, dt * (d.fast and 14 or 4)))
		table.insert(d.trail, 1, d.pos)
		if #d.trail > N * 4 then
			table.remove(d.trail)
		end
		local face = d.lookAt - d.pos
		local hcf = CFrame.lookAt(d.pos, d.pos + (face.Magnitude > 0.1 and face or Vector3.new(0, 0, -1)))
		head.CFrame = hcf
		jaw.CFrame = hcf * CFrame.new(0, -2.6, -1) * CFrame.Angles(math.rad(d.open and 25 or 8), 0, 0)
		horns[1].CFrame = hcf * CFrame.new(1.8, 2.6, 3) * CFrame.Angles(math.rad(30), math.rad(15), 0)
		horns[2].CFrame = hcf * CFrame.new(-1.8, 2.6, 3) * CFrame.Angles(math.rad(30), math.rad(-15), 0)
		eyes[1].CFrame = hcf * CFrame.new(1.6, 1, -3)
		eyes[2].CFrame = hcf * CFrame.new(-1.6, 1, -3)
		local k = 0
		for _, seg in ipairs(segs) do
			local fin = seg:GetAttribute("FinOf")
			if fin then
				local p = d.trail[math.min(#d.trail, fin * 4)] or d.pos
				seg.CFrame = CFrame.new(p + Vector3.new(0, seg.Size.Y * 0.6, 0))
			else
				k += 1
				seg.Position = d.trail[math.min(#d.trail, k * 4)] or d.pos
			end
		end
		if t > dur + 0.8 then
			conn:Disconnect()
			for _, p in ipairs(segs) do
				tween(p, 0.3, { Transparency = 1 })
				Debris:AddItem(p, 0.35)
			end
			for _, p in ipairs({ head, jaw, horns[1], horns[2], eyes[1], eyes[2] }) do
				tween(p, 0.3, { Transparency = 1 })
				Debris:AddItem(p, 0.35)
			end
		end
	end)
	task.delay(dur, function()
		-- 하늘로 솟아 사라진다
		d.fast = false
		d.target = d.pos + Vector3.new(0, 80, 0)
		d.lookAt = d.target + Vector3.new(0, 10, 0)
	end)
	Fx.text(base + Vector3.new(0, 14, 0), "진룡 강림", c, 44, 1.2)
end
local function dragonStrike(caster: Model, data: any)
	local d = dragons[caster]
	local c, c2 = styleColors(data.style)
	local at = (data.at or {})[1]
	if not d or not at then
		return
	end
	if data.last then
		-- 용의 숨: 앞으로 불기둥을 뿜는다
		local r = rootOf(caster)
		local from = r and r.Position + Vector3.new(0, 18, 0) or at + Vector3.new(0, 18, 0)
		d.target = from
		d.lookAt = at
		d.open = true
		for k = 0, 14 do
			task.delay(k * 0.03, function()
				local ball = piece(Vector3.new(3, 3, 3), k % 2 == 0 and c2 or Color3.fromRGB(255, 240, 200), Enum.Material.Neon, Enum.PartType.Ball, 0.1)
				ball.Position = d.pos
				tween(ball, 0.35, { Position = at + Vector3.new(math.random(-4, 4), math.random(-1, 3), math.random(-4, 4)), Size = Vector3.new(9, 9, 9), Transparency = 1 })
				Debris:AddItem(ball, 0.4)
			end)
		end
		task.delay(0.35, function()
			Fx.ring(at - Vector3.new(0, 2.2, 0), c, 4, (data.radius or 16) * 2.4, 0.6)
			Fx.dust(at - Vector3.new(0, 2.4, 0), 6)
			d.open = false
		end)
	else
		-- 하늘로 솟았다가 적에게 내리꽂힌다
		d.fast = true
		d.target = at
		d.lookAt = at - Vector3.new(0, 10, 0)
		task.delay(0.18, function()
			Fx.ring(at - Vector3.new(0, 2.2, 0), c, 3, (data.radius or 9) * 2.4, 0.45)
			Fx.spark(at, c2, 2.4, 14)
			Fx.dust(at - Vector3.new(0, 2.4, 0), 5)
			Fx.sound("heavy", 0.9, 0.7, at)
			d.fast = false
			d.target = at + Vector3.new(math.random(-14, 14), 24, math.random(-14, 14))
			d.lookAt = d.target + Vector3.new(0, 6, 0)
		end)
	end
	if hooks.shake and near(at, 70) then
		hooks.shake(1.1)
	end
end

------------------------------------------------------------------------
-- 무영 분신: 적마다 등 뒤에 검은 그림자가 나타나 세 번 찬다
------------------------------------------------------------------------
local function clones(data: any)
	local shadow = Color3.fromRGB(25, 15, 40)
	local c = styleColors(data.style)
	local kicks = { "side_kick", "tornado_kick", "shadow_heel" }
	for i, m in ipairs(data.targets or {}) do
		task.delay((data.delay or 0.4) + (i - 1) * (data.every or 0.08), function()
			local tr = rootOf(m)
			if not tr then
				return
			end
			local a = i * 2.3
			local at = tr.Position + Vector3.new(math.cos(a), 0, math.sin(a)) * 4
			local cl = spirit(1, shadow, Enum.Material.Neon, 0.15, "muyeong", CFrame.lookAt(at, Vector3.new(tr.Position.X, at.Y, tr.Position.Z)))
			for _, x in ipairs({ -1, 1 }) do
				attach(cl, "Head", Vector3.new(0.25, 0.1, 0.05), CFrame.new(x * 0.2, 0.1, -0.6), Color3.fromRGB(190, 120, 255), Enum.Material.Neon)
			end
			Fx.ring(at - Vector3.new(0, 2.4, 0), c, 1, 8, 0.3)
			Fx.afterimage(cl, c, 0.3)
			for k = 0, 2 do
				task.delay(k * 0.25, function()
					if cl.Parent then
						Anim.play(cl, kicks[k + 1], 0.3)
						Fx.swing("muyeong", cl, k == 2)
					end
				end)
			end
			task.delay(0.8, function()
				for _ = 1, 5 do
					local smoke = piece(Vector3.new(2, 2, 2), shadow, Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.3)
					smoke.Position = at + Vector3.new(math.random(-1, 1), math.random(0, 2), math.random(-1, 1))
					tween(smoke, 0.5, { Size = Vector3.new(5, 5, 5), Transparency = 1 })
					Debris:AddItem(smoke, 0.55)
				end
			end)
			vanish(cl, 0.8, 0.25)
		end)
	end
end

------------------------------------------------------------------------
-- 금강 법신: 내 몸에 금빛이 덮이고 커진다 (Giant 속성을 따라)
------------------------------------------------------------------------
local giants: { [Model]: Instance } = {}
function Ults.watchGiant(m: Model)
	local on = m:GetAttribute("Giant") == true
	local hl = giants[m]
	if on and not hl then
		local h = Instance.new("Highlight")
		h.FillColor = Color3.fromRGB(255, 200, 70)
		h.FillTransparency = 0.35
		h.OutlineColor = Color3.fromRGB(255, 250, 200)
		h.OutlineTransparency = 0
		h.Parent = m
		giants[m] = h
		local r = rootOf(m)
		if r then
			local halo = piece(Vector3.new(0.4, 14, 14), Color3.fromRGB(255, 210, 90), Enum.Material.Neon, Enum.PartType.Cylinder, 0.35)
			local start = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.RenderStepped:Connect(function()
				local rr = rootOf(m)
				if not rr or not giants[m] then
					conn:Disconnect()
					halo:Destroy()
					return
				end
				local look = flat(rr.CFrame.LookVector)
				halo.CFrame = CFrame.lookAt(rr.Position + Vector3.new(0, 7, 0) - look * 3, rr.Position + Vector3.new(0, 7, 0) - look * 4) * CFrame.Angles(0, math.rad(90), (os.clock() - start))
			end)
		end
	elseif not on and hl then
		giants[m] = nil
		hl:Destroy()
	end
end
-- 번개·일순 베기 동안 몸이 보이지 않는다
function Ults.watchVanish(m: Model)
	local on = m:GetAttribute("Vanish") == true
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.LocalTransparencyModifier = on and 1 or 0
		end
	end
end

------------------------------------------------------------------------
-- 종류별 연출
------------------------------------------------------------------------
local H: { [string]: (any) -> () } = {}

function H.avatar(data: any)
	if data.look == "demon" then
		demonSummon(data.m, data.dur, data.style)
	elseif data.look == "dragon" then
		dragonSummon(data.m, data.dur, data.style)
	end
end
function H.avatarStrike(data: any)
	if data.look == "demon" then
		demonStrike(data.m, data)
	elseif data.look == "dragon" then
		dragonStrike(data.m, data)
	end
end
H.clones = clones

function H.stomp(data: any)
	local g = data.at - Vector3.new(0, 2.4, 0)
	local gold = Color3.fromRGB(255, 205, 80)
	Fx.ring(g + Vector3.new(0, 0.3, 0), gold, 4, (data.radius or 16) * 2.6, 0.6)
	Fx.ring(g + Vector3.new(0, 0.5, 0), Color3.new(1, 1, 1), 3, (data.radius or 16) * 1.6, 0.5)
	Fx.dust(g, 9)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local rock = piece(Vector3.new(2, 2, 2), Color3.fromRGB(120, 100, 80), Enum.Material.Slate, nil, 0)
		rock.Position = g
		tween(rock, 0.6, { Position = g + Vector3.new(math.cos(a) * 14, 8, math.sin(a) * 14), Transparency = 1 })
		Debris:AddItem(rock, 0.65)
	end
	Fx.text(data.at + Vector3.new(0, 10, 0), "금강 법신", gold, 44, 1.2)
	if hooks.shake and near(data.at, 80) then
		hooks.shake(1.8)
	end
end
function H.aftershock(data: any)
	Fx.ring(data.at - Vector3.new(0, 2.2, 0), Color3.fromRGB(255, 205, 80), 2, 18, 0.35)
	Fx.dust(data.at - Vector3.new(0, 2.4, 0), 3)
end

function H.lake(data: any)
	local at, r, dur = data.at, data.radius, data.dur
	local c, c2 = styleColors(data.style)
	local g = Vector3.new(at.X, at.Y - 2.3, at.Z)
	local water = piece(Vector3.new(0.4, 4, 4), Color3.fromRGB(70, 150, 220), Enum.Material.Glass, Enum.PartType.Cylinder, 0.35)
	water.CFrame = CFrame.new(g) * CFrame.Angles(0, 0, math.rad(90))
	tween(water, 0.5, { Size = Vector3.new(0.4, r * 2, r * 2) })
	fade(water, dur + 0.4, 0.5)
	-- 가운데로 빨려드는 물살
	local bits = {}
	for i = 1, 40 do
		local b = piece(Vector3.new(1.4, 0.4, 3), i % 2 == 0 and c2 or Color3.fromRGB(200, 240, 255), Enum.Material.Glass, nil, 0.2)
		table.insert(bits, b)
	end
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		for i, b in ipairs(bits) do
			local k = (i / #bits + t * 0.4) % 1
			local rr = r * (1 - k)
			local a = i * 1.7 + t * 4 + k * 6
			local p = g + Vector3.new(math.cos(a) * rr, 0.3 - k * 1.5, math.sin(a) * rr)
			b.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a)))
		end
		if t > dur then
			conn:Disconnect()
			for _, b in ipairs(bits) do
				tween(b, 0.3, { Transparency = 1 })
				Debris:AddItem(b, 0.35)
			end
		end
	end)
	for k = 0, math.floor(dur / 0.5) do
		task.delay(k * 0.5, function()
			Fx.ring(g + Vector3.new(0, 0.4, 0), c2, r * 2, 2, 0.5)
		end)
	end
	Fx.text(at + Vector3.new(0, 6, 0), "만류귀해", c, 40, 1.2)
end
function H.geyser(data: any)
	local at, r = data.at, data.radius or 12
	local c, c2 = styleColors(data.style)
	local g = at - Vector3.new(0, 2.4, 0)
	local col = piece(Vector3.new(4, r * 1.6, r * 1.6), Color3.fromRGB(150, 210, 255), Enum.Material.Glass, Enum.PartType.Cylinder, 0.25)
	col.CFrame = CFrame.new(g) * CFrame.Angles(0, 0, math.rad(90))
	tween(col, 0.3, { Size = Vector3.new(90, r * 1.6, r * 1.6), CFrame = CFrame.new(g + Vector3.new(0, 45, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	fade(col, 0.6, 0.6)
	for _ = 1, 40 do
		local drop = piece(Vector3.new(1.2, 1.2, 1.2), math.random() < 0.5 and c2 or Color3.new(1, 1, 1), Enum.Material.Glass, Enum.PartType.Ball, 0.1)
		drop.Position = g + Vector3.new(0, math.random(10, 70), 0)
		local a = math.random() * math.pi * 2
		tween(drop, 0.9, { Position = g + Vector3.new(math.cos(a) * math.random(10, 30), math.random(0, 20), math.sin(a) * math.random(10, 30)), Transparency = 1 })
		Debris:AddItem(drop, 0.95)
	end
	Fx.ring(g + Vector3.new(0, 0.4, 0), c, 4, r * 4, 0.6)
	if hooks.shake and near(at, 80) then
		hooks.shake(1.6)
	end
end

-- 매화 일순천참
local flashLines: { Part } = {}
function H.flashStart(data: any)
	local r = rootOf(data.m)
	if r and near(r.Position, 90) then
		colorGrade(-1, 0.35, 0.05, Color3.fromRGB(255, 225, 235), data.dur)
	end
	if r then
		Fx.text(r.Position + Vector3.new(0, 6, 0), "일순천참", Color3.fromRGB(255, 150, 200), 44, 1)
	end
end
function H.flashCut(data: any)
	local c, c2 = styleColors(data.style)
	local from, to = data.from, data.to
	if (to - from).Magnitude < 0.5 then
		return
	end
	local line = piece(Vector3.new(0.25, 0.25, (to - from).Magnitude), Color3.new(1, 1, 1), Enum.Material.Neon, nil, 0)
	line.CFrame = CFrame.lookAt((from + to) / 2, to)
	table.insert(flashLines, line)
	local glow = piece(Vector3.new(0.9, 0.9, (to - from).Magnitude), c, Enum.Material.Neon, nil, 0.6)
	glow.CFrame = line.CFrame
	table.insert(flashLines, glow)
	Fx.sound("swing", 0.5, 1.6, to)
	local _ = c2
end
function H.flashBurst(data: any)
	local c, c2 = styleColors(data.style)
	for _, l in ipairs(flashLines) do
		tween(l, 0.35, { Size = Vector3.new(2.5, 2.5, l.Size.Z), Transparency = 1 })
		Debris:AddItem(l, 0.4)
	end
	flashLines = {}
	for _, m in ipairs(data.targets or {}) do
		local tr = rootOf(m)
		if tr then
			-- 한꺼번에 베인 자리: X자와 꽃잎
			for _, sgn in ipairs({ 1, -1 }) do
				local bar = piece(Vector3.new(0.4, 0.4, 14), Color3.new(1, 1, 1), Enum.Material.Neon, nil, 0)
				bar.CFrame = CFrame.new(tr.Position) * CFrame.Angles(0, math.rad(45 * sgn), math.rad(30 * sgn))
				tween(bar, 0.4, { Size = Vector3.new(0.05, 0.05, 20), Transparency = 1 })
				Debris:AddItem(bar, 0.45)
			end
			Fx.bloom(tr.Position - Vector3.new(0, 1.5, 0), 7)
			Fx.spark(tr.Position, c2, 2, 10)
		end
	end
	local p = data.points and data.points[#data.points]
	if p and hooks.flash and near(p, 90) then
		hooks.flash(Color3.fromRGB(255, 220, 235), 0.4)
	end
	if p and hooks.shake and near(p, 90) then
		hooks.shake(1.3)
	end
	local _ = c
end

-- 벽력 뇌신화
function H.boltStart(data: any)
	local r = rootOf(data.m)
	if r and near(r.Position, 100) then
		colorGrade(-0.3, 0.25, -0.15, Color3.fromRGB(170, 185, 255), data.dur)
	end
	if r then
		Fx.text(r.Position + Vector3.new(0, 6, 0), "뇌신화", Color3.fromRGB(255, 240, 140), 44, 1)
		local cloud = piece(Vector3.new(4, 80, 80), Color3.fromRGB(35, 35, 55), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, 0.35)
		cloud.CFrame = CFrame.new(r.Position + Vector3.new(0, 60, 0)) * CFrame.Angles(0, 0, math.rad(90))
		fade(cloud, data.dur, 0.5)
	end
end
function H.boltJump(data: any)
	local c, c2 = styleColors(data.style)
	Fx.lightning(data.from + Vector3.new(0, 1, 0), data.to + Vector3.new(0, 1, 0), c2, 1.4)
	Fx.lightning(data.from + Vector3.new(0, 1, 0), data.to + Vector3.new(0, 1, 0), c, 0.6)
	local g = data.at - Vector3.new(0, 2.4, 0)
	Fx.lightning(g + Vector3.new(math.random(-5, 5), 70, math.random(-5, 5)), g, Color3.new(1, 1, 1), 1.6)
	Fx.ring(g + Vector3.new(0, 0.3, 0), c, 2, 16, 0.35)
	Fx.sound("heavy", 0.6, 1.4, data.at)
	if hooks.shake and near(data.at, 60) then
		hooks.shake(0.7)
	end
end

-- 취권 불덩이
function H.fireball(data: any)
	local m = data.m
	local ball = piece(Vector3.new(7, 7, 7), Color3.fromRGB(255, 120, 30), Enum.Material.Neon, Enum.PartType.Ball, 0.3)
	local core = piece(Vector3.new(4, 4, 4), Color3.fromRGB(255, 230, 140), Enum.Material.Neon, Enum.PartType.Ball, 0.1)
	local fire = Instance.new("Fire")
	fire.Size = 10
	fire.Heat = 15
	fire.Parent = ball
	local start = os.clock()
	local last = nil :: Vector3?
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local r = rootOf(m)
		local t = os.clock() - start
		if not r or t > data.dur then
			conn:Disconnect()
			tween(ball, 0.3, { Transparency = 1, Size = Vector3.new(12, 12, 12) })
			tween(core, 0.3, { Transparency = 1 })
			Debris:AddItem(ball, 0.35)
			Debris:AddItem(core, 0.35)
			return
		end
		ball.CFrame = CFrame.new(r.Position) * CFrame.Angles(t * 12, t * 7, 0)
		core.Position = r.Position
		-- 굴러간 자리에 불길
		if not last or (r.Position - last).Magnitude > 3 then
			last = r.Position
			local fl = piece(Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(255, 150, 50), Enum.Material.Neon, Enum.PartType.Ball, 0.2)
			fl.Position = r.Position - Vector3.new(0, 2, 0)
			tween(fl, 0.5, { Size = Vector3.new(0.4, 0.4, 0.4), Position = fl.Position + Vector3.new(0, 3, 0), Transparency = 1 })
			Debris:AddItem(fl, 0.55)
		end
	end)
	local r = rootOf(m)
	if r then
		Fx.text(r.Position + Vector3.new(0, 6, 0), "취선굴렁쇠", Color3.fromRGB(255, 170, 70), 40, 1)
	end
end
function H.burst(data: any)
	local at, r = data.at, data.radius or 7
	local g = at - Vector3.new(0, 2, 0)
	local big = data.big == true
	for _ = 1, big and 22 or 10 do
		local b = piece(Vector3.new(2, 2, 2), math.random() < 0.5 and Color3.fromRGB(255, 140, 40) or Color3.fromRGB(255, 220, 120), Enum.Material.Neon, Enum.PartType.Ball, 0.1)
		b.Position = g + Vector3.new(0, 1, 0)
		local a = math.random() * math.pi * 2
		tween(b, 0.45, { Position = g + Vector3.new(math.cos(a) * r, math.random(1, big and 10 or 5), math.sin(a) * r), Size = Vector3.new(5, 5, 5), Transparency = 1 })
		Debris:AddItem(b, 0.5)
	end
	Fx.ring(g + Vector3.new(0, 0.3, 0), Color3.fromRGB(255, 140, 40), 2, r * 2.6, 0.45)
	Fx.sound("heavy", big and 1 or 0.6, 0.8, at)
	if hooks.shake and near(at, 60) then
		hooks.shake(big and 1.4 or 0.6)
	end
end

-- 무극: 빛깔이 뒤집히고, 하늘의 눈이 열리고, 하늘의 손이 지운다
function H.freeze(data: any)
	Fx.mech(data)
	local at = data.at
	if near(at, 120) then
		colorGrade(-1, 0.6, 0, Color3.fromRGB(200, 205, 230), data.dur * 0.8)
	end
	local eyeC = at + Vector3.new(0, 70, 0)
	local white = piece(Vector3.new(6, 40, 80), Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball, 0.1)
	white.CFrame = CFrame.new(eyeC) * CFrame.Angles(0, 0, 0)
	white.Size = Vector3.new(6, 2, 80)
	tween(white, 0.4, { Size = Vector3.new(6, 36, 80) })
	local iris = piece(Vector3.new(7, 26, 26), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0)
	iris.Position = eyeC
	iris.Size = Vector3.new(7, 1, 26)
	tween(iris, 0.4, { Size = Vector3.new(7, 26, 26) })
	fade(white, data.dur * 0.8, 0.4)
	fade(iris, data.dur * 0.8, 0.4)
	-- 하늘의 손 (다섯 손가락이 내려온다)
	local palm = piece(Vector3.new(30, 4, 26), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic, nil, 0.15)
	palm.CFrame = CFrame.new(at + Vector3.new(0, 55, 0))
	local fingers = {}
	for i = -2, 2 do
		local fg = piece(Vector3.new(4.5, 3, 16), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic, nil, 0.15)
		fg.CFrame = palm.CFrame * CFrame.new(i * 5.5, 0, -20)
		table.insert(fingers, fg)
	end
	task.delay(data.dur * 0.55, function()
		tween(palm, 0.18, { CFrame = CFrame.new(at + Vector3.new(0, -1, 0)) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for i, fg in ipairs(fingers) do
			tween(fg, 0.18, { CFrame = CFrame.new(at + Vector3.new(0, -1, 0)) * CFrame.new((i - 3) * 5.5, 0, -20) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		task.delay(0.2, function()
			Fx.ring(at - Vector3.new(0, 2, 0), Color3.new(1, 1, 1), 4, 70, 0.6)
			if hooks.shake and near(at, 100) then
				hooks.shake(2)
			end
		end)
	end)
	fade(palm, data.dur * 0.55 + 0.5, 0.4)
	for _, fg in ipairs(fingers) do
		fade(fg, data.dur * 0.55 + 0.5, 0.4)
	end
end

-- 삼재 천지인 일권
function H.charge(data: any)
	local m, time = data.m, data.time or 1
	local c, c2 = styleColors(data.style)
	local hand = m and m:FindFirstChild("RightHand")
	local r = rootOf(m)
	if not r then
		return
	end
	local orb = piece(Vector3.new(1, 1, 1), Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball, 0.2)
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		local h = (hand and hand:IsA("BasePart")) and hand.Position or r.Position
		orb.Position = h
		orb.Size = Vector3.new(1, 1, 1) * (1 + t / time * 3.5)
		if t > time then
			conn:Disconnect()
			orb:Destroy()
		end
	end)
	-- 둘레의 바람과 빛이 주먹으로 빨려 든다
	for k = 0, 24 do
		task.delay(k * time / 25, function()
			local rr = rootOf(m)
			if not rr then
				return
			end
			local a = math.random() * math.pi * 2
			local from = rr.Position + Vector3.new(math.cos(a) * 24, math.random(-2, 10), math.sin(a) * 24)
			local mote = piece(Vector3.new(0.4, 0.4, 4), k % 2 == 0 and c or c2, Enum.Material.Neon, nil, 0.1)
			mote.CFrame = CFrame.lookAt(from, rr.Position)
			tween(mote, 0.3, { CFrame = CFrame.lookAt(rr.Position, rr.Position + (rr.Position - from)), Size = Vector3.new(0.1, 0.1, 1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Debris:AddItem(mote, 0.32)
		end)
	end
	for k = 0, 3 do
		task.delay(k * time / 4, function()
			Fx.ring(r.Position - Vector3.new(0, 2.4, 0), c, 30 - k * 6, 3, 0.35)
		end)
	end
	Fx.text(r.Position + Vector3.new(0, 6, 0), "천지인 일권", c, 44, 1.2)
end
function H.onepunch(data: any)
	local from, dir, range = data.from, data.dir, data.range or 44
	local c, c2 = styleColors(data.style)
	-- 하얗게 번쩍, 공기가 원뿔로 찢겨 나간다
	if near(from, 100) then
		if hooks.flash then
			hooks.flash(Color3.new(1, 1, 1), 0.6)
		end
		if hooks.shake then
			hooks.shake(2.4)
		end
	end
	for k = 1, 9 do
		task.delay(k * 0.025, function()
			local p = from + dir * (k * range / 9)
			Fx.ring(p, k % 2 == 0 and c2 or Color3.new(1, 1, 1), 2 + k, 6 + k * 3.2, 0.45, dir)
		end)
	end
	local cone = piece(Vector3.new(range * 0.6, range * 0.6, range), Color3.new(1, 1, 1), Enum.Material.Neon, nil, 0.5)
	cone.CFrame = CFrame.lookAt(from + dir * range / 2, from + dir * range)
	cone.Size = Vector3.new(2, 2, range)
	tween(cone, 0.25, { Size = Vector3.new(range * 0.55, range * 0.35, range), Transparency = 1 })
	Debris:AddItem(cone, 0.3)
	-- 땅이 갈라진다
	for k = 0, 10 do
		task.delay(k * 0.02, function()
			local p = from - Vector3.new(0, 2.4, 0) + dir * (4 + k * range / 11)
			local crack = piece(Vector3.new(1.2, 0.3, range / 11 + 1), Color3.fromRGB(40, 30, 25), Enum.Material.Slate, nil, 0)
			crack.CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(0, math.rad(math.random(-15, 15)), 0)
			fade(crack, 1.5, 0.6)
			local glow = piece(Vector3.new(0.5, 0.4, range / 11), c, Enum.Material.Neon, nil, 0.2)
			glow.CFrame = crack.CFrame * CFrame.new(0, 0.1, 0)
			fade(glow, 0.8, 0.6)
		end)
	end
	Fx.dust(from - Vector3.new(0, 2.4, 0) + dir * 6, 8)
	Fx.sound("heavy", 1, 0.4, from)
end

-- 천제 하늘의 문과 빛의 검
function H.skygate(data: any)
	local r = rootOf(data.m)
	if not r then
		return
	end
	local c, c2 = styleColors(data.style)
	local center = r.Position + Vector3.new(0, 55, 0)
	local ring = piece(Vector3.new(1.5, 60, 60), c, Enum.Material.Neon, Enum.PartType.Cylinder, 0.35)
	ring.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
	local inner = piece(Vector3.new(1.6, 50, 50), Color3.fromRGB(255, 250, 230), Enum.Material.Neon, Enum.PartType.Cylinder, 0.6)
	inner.CFrame = ring.CFrame
	fade(ring, data.dur, 0.5)
	fade(inner, data.dur, 0.5)
	-- 문에서 아래를 겨눈 검들
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * 24, -3, math.sin(a) * 24)
		local blade = piece(Vector3.new(0.6, 9, 1.4), k % 2 == 0 and c2 or c, Enum.Material.Neon, nil, 0.2)
		blade.CFrame = CFrame.new(p)
		fade(blade, data.dur * 0.8, 0.4)
	end
	if near(r.Position, 100) then
		colorGrade(0.2, 0.15, 0.08, Color3.fromRGB(255, 245, 215), data.dur)
	end
	Fx.text(r.Position + Vector3.new(0, 7, 0), "만검천벌", c, 44, 1.2)
end
function H.sword(data: any)
	local at = data.at
	local c, c2 = styleColors(data.style)
	local big = data.big == true
	local s = big and 5 or 1
	local g = at - Vector3.new(0, 2.4, 0)
	local blade = piece(Vector3.new(0.8, 12, 2.2) * s, Color3.fromRGB(255, 252, 235), Enum.Material.Neon, nil, 0)
	local guard = piece(Vector3.new(0.9, 0.8, 6) * s, c, Enum.Material.Neon, nil, 0)
	local hilt = piece(Vector3.new(0.7, 3, 0.7) * s, c2, Enum.Material.Neon, nil, 0)
	local top = g + Vector3.new(0, 70 * (big and 1.6 or 1), 0)
	local function place(y: number)
		blade.CFrame = CFrame.new(g + Vector3.new(0, y + 6 * s, 0))
		guard.CFrame = CFrame.new(g + Vector3.new(0, y + 12.4 * s, 0))
		hilt.CFrame = CFrame.new(g + Vector3.new(0, y + 14.2 * s, 0))
	end
	place(top.Y - g.Y)
	local start = os.clock()
	local fall = big and 0.35 or 0.22
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - start) / fall, 0, 1)
		place((top.Y - g.Y) * (1 - k * k) - 3 * s * k)
		if k >= 1 then
			conn:Disconnect()
		end
	end)
	task.delay(fall, function()
		Fx.ring(g + Vector3.new(0, 0.3, 0), c, 2, (data.radius or 6) * 2.4, 0.45)
		Fx.spark(g + Vector3.new(0, 2, 0), Color3.new(1, 1, 1), 2 * s, 10)
		Fx.sound("heavy", big and 1 or 0.5, big and 0.5 or 1.3, at)
		if big then
			-- 거대한 검이 꽂힌 뒤 빛으로 터진다
			task.delay(0.35, function()
				local beam = piece(Vector3.new(160, 22, 22), Color3.fromRGB(255, 250, 225), Enum.Material.Neon, Enum.PartType.Cylinder, 0.2)
				beam.CFrame = CFrame.new(g + Vector3.new(0, 80, 0)) * CFrame.Angles(0, 0, math.rad(90))
				tween(beam, 0.6, { Size = Vector3.new(160, 2, 2), Transparency = 1 })
				Debris:AddItem(beam, 0.65)
				for k = 0, 3 do
					task.delay(k * 0.07, function()
						Fx.ring(g + Vector3.new(0, 0.5 + k, 0), k % 2 == 0 and c or c2, 4, (data.radius or 16) * 3.2, 0.6)
					end)
				end
				if hooks.flash and near(at, 100) then
					hooks.flash(Color3.fromRGB(255, 245, 210), 0.45)
				end
				if hooks.shake and near(at, 100) then
					hooks.shake(2)
				end
			end)
		end
	end)
	for _, p in ipairs({ blade, guard, hilt }) do
		fade(p, fall + (big and 0.5 or 0.35), 0.3)
	end
end

-- 파천 흑일강림: 하늘이 찢기고 검은 해가 뜬다. 빛 고리가 돌고, 둘레의 빛이 빨려 들어간다
function H.blackhole(data: any)
	local c, c2 = styleColors(data.style)
	local at: Vector3 = data.at
	local sky = at + Vector3.new(0, data.height or 16, 0)
	local r = data.radius or 30
	local delay, dur = data.delay or 0.6, data.dur or 2.6
	local ground = at - Vector3.new(0, 2.4, 0)
	-- 하늘이 찢어진다: 보랏빛 금이 여러 갈래로
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local d = Vector3.new(math.cos(a), math.sin(a * 2) * 0.4, math.sin(a))
		local tear = piece(Vector3.new(0.4, 0.4, 0.1), k % 2 == 0 and c or c2, Enum.Material.Neon, nil, 0)
		tear.CFrame = CFrame.lookAt(sky, sky + d)
		tween(tear, delay * 0.8, { Size = Vector3.new(0.5, 0.5, 18), CFrame = CFrame.lookAt(sky + d * 9, sky + d * 18) })
		fade(tear, delay, 0.3)
	end
	colorGrade(-0.5, 0.25, -0.18, Color3.fromRGB(205, 185, 255), delay + dur)
	-- 바닥: 무게에 짓눌린 검은 원과 갈라진 금
	local floor = piece(Vector3.new(0.2, 2, 2), Color3.fromRGB(15, 5, 25), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, 0.25)
	floor.CFrame = CFrame.new(ground + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(floor, 0.5, { Size = Vector3.new(0.2, r * 2, r * 2) })
	local edge = piece(Vector3.new(0.25, 2, 2), c, Enum.Material.Neon, Enum.PartType.Cylinder, 0.4)
	edge.CFrame = floor.CFrame
	tween(edge, 0.5, { Size = Vector3.new(0.25, r * 2 + 1.5, r * 2 + 1.5) })
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2 + math.random() * 0.3
		local len = r * (0.6 + math.random() * 0.4)
		local crack = piece(Vector3.new(0.6, 0.15, 0.1), c, Enum.Material.Neon, nil, 0.1)
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		crack.CFrame = CFrame.lookAt(ground + Vector3.new(0, 0.3, 0), ground + Vector3.new(0, 0.3, 0) + d)
		tween(crack, 0.4, { Size = Vector3.new(0.6, 0.15, len), CFrame = CFrame.lookAt(ground + Vector3.new(0, 0.3, 0) + d * len / 2, ground + Vector3.new(0, 0.3, 0) + d * len) })
		fade(crack, delay + dur, 0.4)
	end
	fade(floor, delay + dur, 0.4)
	fade(edge, delay + dur, 0.4)
	-- 검은 해, 빛을 휘게 하는 유리 껍질, 두 겹의 빛 고리
	local core = piece(Vector3.new(0.5, 0.5, 0.5), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0)
	core.Position = sky
	local lens = piece(Vector3.new(0.6, 0.6, 0.6), c, Enum.Material.Glass, Enum.PartType.Ball, 0.55)
	lens.Position = sky
	local corona = piece(Vector3.new(0.6, 0.6, 0.6), c2, Enum.Material.Neon, Enum.PartType.Ball, 0.75)
	corona.Position = sky
	local size = math.clamp(r * 0.38, 7, 14)
	tween(core, delay, { Size = Vector3.new(size, size, size) }, Enum.EasingStyle.Back)
	tween(lens, delay, { Size = Vector3.new(size * 1.7, size * 1.7, size * 1.7) })
	tween(corona, delay, { Size = Vector3.new(size * 1.25, size * 1.25, size * 1.25) })
	local disks = {}
	for i = 1, 3 do
		local d = piece(Vector3.new(0.3, 0.5, 0.5), i == 2 and c2 or c, Enum.Material.Neon, Enum.PartType.Cylinder, 0.25 + i * 0.12)
		table.insert(disks, d)
		tween(d, delay, { Size = Vector3.new(0.3, size * (1.8 + i * 0.6), size * (1.8 + i * 0.6)) })
	end
	local light = Instance.new("PointLight")
	light.Color = c
	light.Range = 60
	light.Brightness = 5
	light.Parent = corona
	local start = os.clock()
	local lastSpawn = 0
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		for i, d in ipairs(disks) do
			d.CFrame = CFrame.new(sky) * CFrame.Angles(math.rad(70 + i * 8), t * (2 + i), math.rad(90 + i * 12)) * CFrame.Angles(t * (3 - i * 0.6), 0, 0)
		end
		local pulse = 1 + math.sin(t * 9) * 0.04
		corona.Size = Vector3.new(size, size, size) * 1.25 * pulse
		-- 둘레의 빛 조각이 빨려 들어간다
		if t > delay * 0.5 and t - lastSpawn > 0.04 and t < delay + dur then
			lastSpawn = t
			for _ = 1, 2 do
				local dir = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
				dir = dir.Magnitude > 0.01 and dir.Unit or Vector3.new(0, 1, 0)
				local from = sky + dir * (r * 0.8)
				local shard = piece(Vector3.new(0.3, 0.3, 2.4), math.random() < 0.5 and c or c2, Enum.Material.Neon, nil, 0.1)
				shard.CFrame = CFrame.lookAt(from, sky)
				tween(shard, 0.45, { CFrame = CFrame.lookAt(sky, sky + dir), Size = Vector3.new(0.1, 0.1, 0.6), Transparency = 0.8 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				Debris:AddItem(shard, 0.5)
			end
		end
		if t >= delay + dur then
			conn:Disconnect()
			-- 안으로 무너진다 (터지는 빛은 blackholeBurst)
			for _, p in ipairs({ core, lens, corona, table.unpack(disks) }) do
				tween(p, 0.15, { Size = Vector3.new(0.1, 0.1, 0.1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				Debris:AddItem(p, 0.2)
			end
		end
	end)
	Fx.text(sky + Vector3.new(0, size + 4, 0), "흑일강림", c2, 46, 1.4)
	Fx.sound("heavy", 1, 0.3, sky)
	if hooks.shake and near(at, 90) then
		hooks.shake(1.2)
	end
end
function H.blackholeBurst(data: any)
	local c, c2 = styleColors(data.style)
	local at: Vector3 = data.at
	local r = data.radius or 30
	local flash = piece(Vector3.new(2, 2, 2), Color3.fromRGB(255, 250, 240), Enum.Material.Neon, Enum.PartType.Ball, 0)
	flash.Position = at
	tween(flash, 0.35, { Size = Vector3.new(r * 2.6, r * 2.6, r * 2.6), Transparency = 1 })
	Debris:AddItem(flash, 0.4)
	local shell = piece(Vector3.new(2, 2, 2), c, Enum.Material.ForceField, Enum.PartType.Ball, 0)
	shell.Position = at
	tween(shell, 0.6, { Size = Vector3.new(r * 3.2, r * 3.2, r * 3.2), Transparency = 1 })
	Debris:AddItem(shell, 0.65)
	for k = 0, 2 do
		task.delay(k * 0.06, function()
			Fx.ring(at, k % 2 == 0 and c or c2, 4, r * 3, 0.6)
			Fx.ring(at, c2, 4, r * 2.4, 0.6, Vector3.new(0, 1, 0):Cross(Vector3.new(1, 0, 0)))
		end)
	end
	local beam = piece(Vector3.new(200, 6, 6), c2, Enum.Material.Neon, Enum.PartType.Cylinder, 0.2)
	beam.CFrame = CFrame.new(at + Vector3.new(0, 90, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(beam, 0.5, { Size = Vector3.new(200, 0.2, 0.2), Transparency = 1 })
	Debris:AddItem(beam, 0.55)
	Fx.spark(at, c2, 3, 26)
	if hooks.flash and near(at, 100) then
		hooks.flash(Color3.fromRGB(240, 225, 255), 0.45)
	end
	if hooks.shake and near(at, 110) then
		hooks.shake(2.6)
	end
	Fx.sound("heavy", 1, 0.25, at)
end

-- 태초 천지개벽: 세상이 멈추고 별바다가 된다 → 금이 간다 → 유리처럼 깨진다
function H.genesis(data: any)
	local c, c2 = styleColors(data.style)
	local at: Vector3 = data.at
	local R = math.min(data.radius or 60, 70)
	local dur = data.dur or 2.6
	local crackAt, breakAt = data.crackAt or 1.6, data.breakAt or 2.5
	local ground = at - Vector3.new(0, 2.4, 0)
	local parts: { BasePart } = {}
	-- 1) 세상이 멈춘다: 빛깔이 빠지고, 바닥이 별을 비추는 검푸른 거울이 된다
	colorGrade(-0.85, 0.3, -0.3, Color3.fromRGB(180, 195, 255), breakAt)
	local mirror = piece(Vector3.new(0.2, 2, 2), Color3.fromRGB(10, 14, 40), Enum.Material.Glass, Enum.PartType.Cylinder, 0.15)
	mirror.CFrame = CFrame.new(ground + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(mirror, 0.5, { Size = Vector3.new(0.2, R * 2, R * 2) })
	table.insert(parts, mirror)
	-- 하늘의 별과 은하 (반구 위에 흩뿌린다)
	for i = 1, 90 do
		local a = math.random() * math.pi * 2
		local e = math.random() * 1.3 + 0.15
		local d = R * (0.75 + math.random() * 0.25)
		local p = at + Vector3.new(math.cos(a) * math.cos(e) * d, math.sin(e) * d * 0.7, math.sin(a) * math.cos(e) * d)
		local s = math.random() < 0.12 and 1.1 or 0.45
		local star = piece(Vector3.new(s, s, s), i % 7 == 0 and c2 or Color3.fromRGB(255, 252, 240), Enum.Material.Neon, Enum.PartType.Ball, 1)
		star.Position = p
		tween(star, 0.3 + math.random() * 0.4, { Transparency = 0.05 })
		table.insert(parts, star)
		-- 거울 바닥에 비친 별
		if i % 2 == 0 then
			local refl = piece(Vector3.new(0.3, 0.3, 0.3), star.Color, Enum.Material.Neon, Enum.PartType.Ball, 1)
			refl.Position = Vector3.new(p.X, ground.Y + 0.35, p.Z) + Vector3.new(0, 0, 0)
			tween(refl, 0.6, { Transparency = 0.3 })
			table.insert(parts, refl)
		end
	end
	for g = 0, 1 do
		local gc = at + Vector3.new((g == 0 and -1 or 1) * R * 0.4, R * 0.55, -R * 0.2)
		for k = 0, 23 do
			local a = k * 0.55
			local rr = 2 + k * 0.6
			local dot = piece(Vector3.new(0.7, 0.7, 0.7), g == 0 and c2 or c, Enum.Material.Neon, Enum.PartType.Ball, 1)
			dot.Position = gc + Vector3.new(math.cos(a) * rr, math.sin(a) * rr * 0.35, math.sin(a) * rr)
			tween(dot, 0.6, { Transparency = 0.15 })
			table.insert(parts, dot)
		end
	end
	-- 멈춘 적은 빛의 결정에 갇힌다
	for _, m in ipairs(data.targets or {}) do
		local tr = rootOf(m)
		if tr then
			local shell = piece(Vector3.new(1, 1, 1), c2, Enum.Material.Glass, Enum.PartType.Ball, 0.5)
			shell.Position = tr.Position
			tween(shell, 0.25, { Size = Vector3.new(7, 9, 7) })
			table.insert(parts, shell)
		end
	end
	-- 하늘에 떠오르는 내 별자리 (거대한 빛의 몸)
	local caster = data.m
	local cr = rootOf(caster)
	if cr then
		local look = flat(cr.CFrame.LookVector)
		local s = 6
		local base = cr.Position - look * 14 + Vector3.new(0, 2.6 * s - 2.5, 0)
		local cf = CFrame.lookAt(base, base + look)
		local ghost = spirit(s, c2, Enum.Material.ForceField, 0.2, data.style, cf - Vector3.new(0, 6, 0))
		rise(ghost, cf - Vector3.new(0, 6, 0), cf, 0.6)
		Anim.play(ghost, "ult_origin", breakAt + 0.3)
		vanish(ghost, breakAt + 0.3, 0.4)
	end
	Fx.text(at + Vector3.new(0, 12, 0), "천지개벽", Color3.fromRGB(255, 250, 230), 54, 1.6)
	Fx.sound("heavy", 0.8, 0.2, at)
	-- 2) 금이 간다: 하늘과 땅에 흰 금이 번진다
	task.delay(crackAt, function()
		for k = 0, 17 do
			local a = k / 18 * math.pi * 2 + math.random() * 0.25
			local d = Vector3.new(math.cos(a), (k % 3 - 1) * 0.35, math.sin(a)).Unit
			local from = at + Vector3.new(0, 4, 0) + d * 3
			local len = R * (0.5 + math.random() * 0.5)
			local crack = piece(Vector3.new(0.35, 0.35, 0.1), Color3.fromRGB(255, 255, 255), Enum.Material.Neon, nil, 0)
			crack.CFrame = CFrame.lookAt(from, from + d)
			tween(crack, 0.35, { Size = Vector3.new(0.35, 0.35, len), CFrame = CFrame.lookAt(from + d * len / 2, from + d * len) })
			table.insert(parts, crack)
			-- 갈래
			local d2 = (d + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.8).Unit
			local mid = from + d * len * 0.5
			local twig = piece(Vector3.new(0.25, 0.25, 0.1), Color3.fromRGB(220, 235, 255), Enum.Material.Neon, nil, 0)
			twig.CFrame = CFrame.lookAt(mid, mid + d2)
			tween(twig, 0.3, { Size = Vector3.new(0.25, 0.25, len * 0.4), CFrame = CFrame.lookAt(mid + d2 * len * 0.2, mid + d2 * len * 0.4) })
			table.insert(parts, twig)
		end
		Fx.sound("hit", 1, 0.5, at)
		if hooks.shake and near(at, 90) then
			hooks.shake(0.6)
		end
	end)
	-- 3) 깨진다: 조각이 사방으로 흩어지고, 흰 빛이 세상을 덮는다
	task.delay(breakAt, function()
		for _, p in ipairs(parts) do
			if p.Parent then
				local dir = p.Position - at
				dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 1, 0)
				tween(p, 0.5, { Position = p.Position + dir * 25, Transparency = 1 })
				Debris:AddItem(p, 0.55)
			end
		end
		for _ = 1, 50 do
			local a = math.random() * math.pi * 2
			local e = math.random() * 1.2
			local d = Vector3.new(math.cos(a) * math.cos(e), math.sin(e), math.sin(a) * math.cos(e))
			local p0 = at + d * (R * (0.3 + math.random() * 0.6))
			local shard = piece(Vector3.new(math.random() * 3 + 1, 0.15, math.random() * 4 + 1.5), math.random() < 0.5 and Color3.fromRGB(230, 240, 255) or c2, Enum.Material.Glass, nil, 0.2)
			shard.CFrame = CFrame.new(p0) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
			tween(shard, 0.8, { CFrame = CFrame.new(p0 + d * 30 + Vector3.new(0, -10, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6), Transparency = 1 })
			Debris:AddItem(shard, 0.85)
		end
		local nova = piece(Vector3.new(4, 4, 4), Color3.fromRGB(255, 255, 250), Enum.Material.Neon, Enum.PartType.Ball, 0)
		nova.Position = at
		tween(nova, 0.4, { Size = Vector3.new(R * 2.4, R * 2.4, R * 2.4), Transparency = 1 })
		Debris:AddItem(nova, 0.45)
		for k = 0, 3 do
			task.delay(k * 0.07, function()
				Fx.ring(ground + Vector3.new(0, 0.5 + k, 0), k % 2 == 0 and c2 or Color3.fromRGB(255, 255, 255), 6, R * 2.6, 0.7)
			end)
		end
		if hooks.flash and near(at, 120) then
			hooks.flash(Color3.fromRGB(255, 255, 255), 0.6)
		end
		if hooks.shake and near(at, 120) then
			hooks.shake(3)
		end
		Fx.sound("heavy", 1, 0.2, at)
	end)
	local _ = dur
end

-- 파천 중압 / 태초 창세: 정해진 수만큼 맞히면 상대 자리에서 터진다
function H.pulse(data: any)
	local c, c2 = styleColors(data.style)
	local at: Vector3 = data.at
	local r = data.radius or 12
	local delay = data.delay or 0.3
	if data.fx == "gravity" then
		-- 중력 우물: 검은 구가 맺히며 둘레의 고리가 안으로 조여든다
		local well = piece(Vector3.new(0.5, 0.5, 0.5), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0)
		well.Position = at
		tween(well, delay, { Size = Vector3.new(4, 4, 4) }, Enum.EasingStyle.Back)
		for k = 0, 2 do
			task.delay(k * delay / 3, function()
				Fx.ring(at - Vector3.new(0, 2, 0), k % 2 == 0 and c or c2, r * 2, 1, delay)
			end)
		end
		task.delay(delay, function()
			tween(well, 0.15, { Size = Vector3.new(0.1, 0.1, 0.1) })
			Debris:AddItem(well, 0.2)
			Fx.ring(at - Vector3.new(0, 2.3, 0), c, 2, r * 2.4, 0.4)
			Fx.spark(at, c, 2, 12)
			local crater = piece(Vector3.new(0.2, r * 1.6, r * 1.6), Color3.fromRGB(20, 10, 30), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, 0.3)
			crater.CFrame = CFrame.new(at - Vector3.new(0, 2.35, 0)) * CFrame.Angles(0, 0, math.rad(90))
			fade(crater, 0.6, 0.4)
			if hooks.shake and near(at, 50) then
				hooks.shake(0.7)
			end
		end)
		Fx.text(at + Vector3.new(0, 5, 0), "중압", c2, 30, 0.8)
	else
		-- 창세 결정: 바닥에서 빛의 결정이 꽃처럼 피어 터진다
		local shards = {}
		for k = 0, 6 do
			local a = k / 7 * math.pi * 2
			local d = k == 0 and Vector3.zero or Vector3.new(math.cos(a), 0, math.sin(a))
			local base = at - Vector3.new(0, 2.4, 0) + d * 2.5
			local h = k == 0 and 9 or 6
			local s = piece(Vector3.new(1.4, 0.3, 1.4), k % 2 == 0 and c2 or Color3.fromRGB(255, 252, 240), Enum.Material.Glass, nil, 0.1)
			s.CFrame = CFrame.new(base) * CFrame.Angles(d.Z * 0.5, a, -d.X * 0.5) * CFrame.Angles(0, math.rad(45), 0)
			tween(s, delay * 0.7, { Size = Vector3.new(1.4, h, 1.4), CFrame = s.CFrame * CFrame.new(0, h / 2, 0) })
			table.insert(shards, s)
		end
		task.delay(delay, function()
			for _, s in ipairs(shards) do
				tween(s, 0.25, { Size = s.Size * 1.6, Transparency = 1 })
				Debris:AddItem(s, 0.3)
			end
			Fx.spark(at, c2, 2.4, 18)
			Fx.ring(at - Vector3.new(0, 2.3, 0), c2, 2, r * 2.2, 0.35)
		end)
	end
end

-- 파천·태초 기술의 다른 빛깔: 중력의 우물·낙하, 빛의 결정 기둥
function Ults.variant(data: any): boolean
	local c, c2 = styleColors(data.style)
	if data.fx == "gravity" and data.kind == "zone" then
		local at: Vector3 = data.at
		local r = data.radius or 12
		local dur = data.dur or 1.2
		local ground = at - Vector3.new(0, 2.4, 0)
		local pit = piece(Vector3.new(0.2, 2, 2), Color3.fromRGB(15, 5, 25), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, 0.2)
		pit.CFrame = CFrame.new(ground + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
		tween(pit, 0.25, { Size = Vector3.new(0.2, r * 2, r * 2) })
		local core = piece(Vector3.new(0.5, 0.5, 0.5), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0)
		core.Position = ground + Vector3.new(0, 3, 0)
		tween(core, 0.3, { Size = Vector3.new(3.5, 3.5, 3.5) })
		local start = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - start
			if t > dur then
				conn:Disconnect()
				return
			end
			if math.random() < 0.5 then
				local a = math.random() * math.pi * 2
				local from = ground + Vector3.new(math.cos(a) * r, 0.4, math.sin(a) * r)
				local streak = piece(Vector3.new(0.3, 0.3, 2), math.random() < 0.5 and c or c2, Enum.Material.Neon, nil, 0.1)
				streak.CFrame = CFrame.lookAt(from, core.Position)
				tween(streak, 0.35, { CFrame = CFrame.lookAt(core.Position, core.Position + (core.Position - from)), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				Debris:AddItem(streak, 0.4)
			end
		end)
		for k = 0, math.floor(dur / 0.3) do
			task.delay(k * 0.3, function()
				Fx.ring(ground + Vector3.new(0, 0.4, 0), k % 2 == 0 and c or c2, r * 2, 2, 0.3)
			end)
		end
		fade(pit, dur, 0.3)
		fade(core, dur, 0.2)
		return true
	elseif data.fx == "gravity" and data.kind == "drop" then
		local at: Vector3 = data.at
		local r = data.radius or 13
		local ground = at - Vector3.new(0, 2.4, 0)
		local crater = piece(Vector3.new(0.2, r * 2, r * 2), Color3.fromRGB(20, 10, 30), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, 0.15)
		crater.CFrame = CFrame.new(ground + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
		fade(crater, 1.2, 0.5)
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			local d = Vector3.new(math.cos(a), 0, math.sin(a))
			local slab = piece(Vector3.new(r * 0.4, 1, 3), Color3.fromRGB(90, 80, 95), Enum.Material.Slate, nil, 0)
			slab.CFrame = CFrame.lookAt(ground + d * r * 0.85, ground + d * r * 2) * CFrame.Angles(math.rad(35), 0, 0)
			fade(slab, 1.0, 0.4)
		end
		Fx.ring(ground + Vector3.new(0, 0.5, 0), c, 2, r * 2.6, 0.45)
		Fx.ring(ground + Vector3.new(0, 1, 0), c2, 2, r * 2, 0.35)
		Fx.spark(at, c, 2.4, 16)
		Fx.sound("heavy", 1, 0.45, at)
		if hooks.shake and near(at, 70) then
			hooks.shake(1.6)
		end
		return true
	elseif data.fx == "prism" and data.kind == "strike" then
		-- 창세주: 빛의 결정 기둥이 솟는다
		local at: Vector3 = data.at
		local r = data.radius or 7
		local ground = at - Vector3.new(0, 2.4, 0)
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2
			local d = k == 0 and Vector3.zero or Vector3.new(math.cos(a), 0, math.sin(a))
			local h = k == 0 and 16 or 9
			local col = piece(Vector3.new(2.2, 0.3, 2.2), k == 0 and Color3.fromRGB(255, 252, 240) or c2, Enum.Material.Glass, nil, 0.05)
			col.CFrame = CFrame.new(ground + d * r * 0.45) * CFrame.Angles(d.Z * 0.35, 0, -d.X * 0.35) * CFrame.Angles(0, math.rad(45), 0)
			tween(col, 0.12, { Size = Vector3.new(2.2, h, 2.2), CFrame = col.CFrame * CFrame.new(0, h / 2, 0) })
			fade(col, 0.45, 0.35)
		end
		local beam = piece(Vector3.new(60, 1.5, 1.5), Color3.fromRGB(255, 250, 235), Enum.Material.Neon, Enum.PartType.Cylinder, 0.2)
		beam.CFrame = CFrame.new(ground + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90))
		tween(beam, 0.4, { Size = Vector3.new(60, 0.1, 0.1), Transparency = 1 })
		Debris:AddItem(beam, 0.45)
		Fx.ring(ground + Vector3.new(0, 0.4, 0), c2, 1, r * 2.2, 0.35)
		Fx.spark(at, c, 2, 10)
		return true
	end
	return false
end

-- 풍신 회오리
function H.tornado(data: any)
	local c, c2 = styleColors(data.style)
	local from, dir, speed, dur, r = data.from, data.dir, data.speed, data.dur, data.radius or 13
	local rings = {}
	for i = 1, 12 do
		local sz = r * (0.35 + i * 0.14)
		local ring = piece(Vector3.new(1.2, sz * 2, sz * 2), i % 2 == 0 and c or c2, Enum.Material.Neon, Enum.PartType.Cylinder, 0.55)
		table.insert(rings, ring)
	end
	local debris = {}
	for i = 1, 16 do
		local d = piece(Vector3.new(1.5, 1.5, 1.5), Color3.fromRGB(130, 120, 100), Enum.Material.Slate, nil, 0)
		table.insert(debris, d)
		local _ = i
	end
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		local base = from - Vector3.new(0, 2.4, 0) + dir * (speed * math.min(t, dur))
		for i, ring in ipairs(rings) do
			local y = i * 4.5
			local sway = Vector3.new(math.sin(t * 3 + i * 0.5), 0, math.cos(t * 2.5 + i * 0.5)) * (i * 0.4)
			ring.CFrame = CFrame.new(base + Vector3.new(0, y, 0) + sway) * CFrame.Angles(0, t * 8 + i, math.rad(90))
		end
		for i, d in ipairs(debris) do
			local a = t * 6 + i * 0.8
			local h = (i * 3.7 + t * 12) % 50
			local rr = r * (0.4 + h / 50)
			d.CFrame = CFrame.new(base + Vector3.new(math.cos(a) * rr, h, math.sin(a) * rr)) * CFrame.Angles(a, a, 0)
		end
		if t > dur then
			conn:Disconnect()
			for _, p in ipairs(rings) do
				tween(p, 0.4, { Transparency = 1, Size = p.Size * 1.6 })
				Debris:AddItem(p, 0.45)
			end
			for _, p in ipairs(debris) do
				tween(p, 0.4, { Transparency = 1 })
				Debris:AddItem(p, 0.45)
			end
		end
	end)
	Fx.text(from + Vector3.new(0, 8, 0), "풍신강림", c, 44, 1.2)
	if hooks.shake and near(from, 80) then
		hooks.shake(0.8)
	end
end

-- 빛의 창 (천제의 창) / 하늘의 검 (천검강림·천위)
function Ults.spear(at: Vector3, dir: Vector3, styleId: any)
	local c, c2 = styleColors(styleId)
	local p = at + Vector3.new(0, 1.5, 0)
	local spear = piece(Vector3.new(0.6, 0.6, 11), Color3.fromRGB(255, 250, 230), Enum.Material.Neon, nil, 0)
	local tip = piece(Vector3.new(1.4, 1.4, 2.6), c, Enum.Material.Neon, nil, 0)
	local d = flat(dir)
	spear.CFrame = CFrame.lookAt(p - d * 12, p)
	tip.CFrame = spear.CFrame * CFrame.new(0, 0, -6)
	tween(spear, 0.1, { CFrame = CFrame.lookAt(p, p + d) })
	tween(tip, 0.1, { CFrame = CFrame.lookAt(p, p + d) * CFrame.new(0, 0, -6) })
	fade(spear, 0.25, 0.25)
	fade(tip, 0.25, 0.25)
	Fx.ring(p, c2, 1, 7, 0.3, d)
end

function Ults.handles(kind: string): boolean
	return H[kind] ~= nil
end
function Ults.run(data: any)
	local f = H[data.kind]
	if f then
		f(data)
	end
end
-- 오의를 쓰는 순간: 몸에서 빛기둥이 솟고, 빛이 모인다 (진짜 연출은 서버가 알려 준다)
function Ults.intro(styleId: any, model: Model)
	local r = rootOf(model)
	if not r then
		return
	end
	local c, c2 = styleColors(styleId)
	local col = piece(Vector3.new(60, 3, 3), c2, Enum.Material.Neon, Enum.PartType.Cylinder, 0.3)
	col.CFrame = CFrame.new(r.Position + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tween(col, 0.5, { Size = Vector3.new(60, 0.3, 0.3), Transparency = 1 })
	Debris:AddItem(col, 0.55)
	Fx.ring(r.Position - Vector3.new(0, 2.4, 0), c, 14, 2, 0.4)
	Fx.afterimage(model, c, 0.4)
end

return Ults
