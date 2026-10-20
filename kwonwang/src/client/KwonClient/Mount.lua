-- 권왕: 탈것 모습 (화면마다 직접 그린다). 몸에 "Mount" 표시가 붙은 사람 아래에 말·범·구름을 그리고,
-- 달리면 다리가 허벅지·정강이 두 마디로 번갈아 굽고 펴진다. 몸통은 둥근 원통과 공으로 빚는다
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Mount = {}

local folder = Instance.new("Folder")
folder.Name = "KwonMounts"
folder.Parent = workspace

-- seg: nil (몸에 붙음) / "thigh" / "shin" / "hoof" (다리 마디), leg = 다리 번호, len = 마디 길이
type Piece = { p: BasePart, off: CFrame, leg: number?, seg: string?, len: number?, di: number? }
type Rig = { parts: { Piece }, kind: string, phase: number, model: Model, thigh: number, shin: number, bodyY: number }
local rigs: { [Model]: Rig } = {}

local Ball, Cyl = Enum.PartType.Ball, Enum.PartType.Cylinder
local DARK = Color3.fromRGB(28, 22, 20)

local function piece(rig: Rig, size: Vector3, off: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Piece
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Parent = folder
	local e: Piece = { p = p, off = off }
	table.insert(rig.parts, e)
	return e
end
-- 앞뒤(Z)로 누운 원통
local function tube(rig: Rig, len: number, diam: number, off: CFrame, color: Color3, material: Enum.Material?): Piece
	return piece(rig, Vector3.new(len, diam, diam), off * CFrame.Angles(0, math.rad(90), 0), color, material, Cyl)
end
-- 다리 하나: 허벅지·정강이·발굽 (off = 엉덩이 자리)
local function leg(rig: Rig, idx: number, off: CFrame, color: Color3, hoofColor: Color3, thick: number, paw: boolean)
	local t = piece(rig, Vector3.new(thick * 1.25, rig.thigh, thick * 1.35), off, color)
	t.leg, t.seg, t.len = idx, "thigh", rig.thigh
	local s = piece(rig, Vector3.new(thick, rig.shin, thick), off, color)
	s.leg, s.seg, s.len = idx, "shin", rig.shin
	local h = paw and piece(rig, Vector3.new(thick * 1.5, thick * 1.5, thick * 1.5), off, color, nil, Ball) or piece(rig, Vector3.new(thick * 1.2, 0.3, thick * 1.35), off, hoofColor)
	h.leg, h.seg = idx, "hoof"
end

local function horse(rig: Rig, m: any)
	local c, mane = m.color, m.mane
	rig.thigh, rig.shin, rig.bodyY = 1.1, 1.05, 1.7
	local belly = c:Lerp(Color3.new(1, 1, 1), 0.08)
	-- 몸통: 가운데 원통, 앞가슴과 엉덩이는 공
	tube(rig, 3.4, 1.75, CFrame.new(0, 0, 0), c)
	piece(rig, Vector3.new(2.0, 2.0, 2.0), CFrame.new(0, 0.05, -1.65), c, nil, Ball)
	piece(rig, Vector3.new(2.1, 2.1, 2.1), CFrame.new(0, 0.12, 1.6), c, nil, Ball)
	tube(rig, 2.6, 1.3, CFrame.new(0, -0.35, 0), belly)
	-- 목과 머리: 비스듬히 솟은 목, 길쭉한 얼굴, 둥근 주둥이, 귀, 눈
	local neck = CFrame.new(0, 1.05, -2.35) * CFrame.Angles(math.rad(-50), 0, 0)
	tube(rig, 2.2, 0.95, neck, c)
	local head = CFrame.new(0, 2.05, -3.15) * CFrame.Angles(math.rad(35), 0, 0)
	tube(rig, 1.55, 0.8, head, c)
	piece(rig, Vector3.new(0.78, 0.78, 0.78), head * CFrame.new(0, -0.05, -0.75), c:Lerp(DARK, 0.25), nil, Ball)
	for _, x in ipairs({ -1, 1 }) do
		piece(rig, Vector3.new(0.14, 0.45, 0.22), head * CFrame.new(x * 0.22, 0.48, 0.55) * CFrame.Angles(math.rad(-10), 0, x * math.rad(-12)), c)
		piece(rig, Vector3.new(0.16, 0.16, 0.16), head * CFrame.new(x * 0.39, 0.12, 0.05), DARK, nil, Ball)
		-- 굴레 (얼굴 둘레의 가죽끈)과 고삐
		piece(rig, Vector3.new(0.08, 0.84, 0.1), head * CFrame.new(x * 0.41, 0, -0.35), Color3.fromRGB(70, 40, 25))
		piece(rig, Vector3.new(0.06, 0.06, 2.6), CFrame.new(x * 0.42, 1.55, -2.05) * CFrame.Angles(math.rad(22), 0, 0), Color3.fromRGB(70, 40, 25))
	end
	piece(rig, Vector3.new(0.86, 0.1, 0.1), head * CFrame.new(0, 0.2, -0.35), Color3.fromRGB(70, 40, 25))
	-- 갈기 (목 위에 겹쳐 늘어진 털)와 앞머리
	for k = 0, 5 do
		piece(rig, Vector3.new(0.16, 0.55, 0.5), neck * CFrame.new(0, 0.45 - k * 0.02, -1.0 + k * 0.4) * CFrame.Angles(math.rad(-15), 0, (k % 2 == 0 and 1 or -1) * math.rad(10)), mane)
	end
	piece(rig, Vector3.new(0.3, 0.35, 0.18), head * CFrame.new(0, 0.42, 0.3), mane)
	-- 꼬리: 세 마디로 흘러내린다
	for k = 0, 2 do
		piece(rig, Vector3.new(0.32 - k * 0.05, 0.75, 0.3 - k * 0.04), CFrame.new(0, 0.55 - k * 0.6, 2.75 + k * 0.18) * CFrame.Angles(math.rad(25 - k * 8), 0, 0), mane)
	end
	-- 안장: 깔개, 안장, 앞뒤 턱, 등자
	piece(rig, Vector3.new(1.95, 0.12, 1.9), CFrame.new(0, 0.9, -0.1), Color3.fromRGB(180, 150, 70), Enum.Material.Fabric)
	piece(rig, Vector3.new(1.4, 0.3, 1.5), CFrame.new(0, 1.05, -0.1), Color3.fromRGB(130, 40, 30), Enum.Material.Fabric)
	piece(rig, Vector3.new(1.1, 0.35, 0.25), CFrame.new(0, 1.3, -0.8), Color3.fromRGB(110, 70, 40), Enum.Material.Wood)
	piece(rig, Vector3.new(1.2, 0.3, 0.25), CFrame.new(0, 1.25, 0.6), Color3.fromRGB(110, 70, 40), Enum.Material.Wood)
	for _, x in ipairs({ -1, 1 }) do
		piece(rig, Vector3.new(0.06, 1.1, 0.12), CFrame.new(x * 0.98, 0.45, -0.1), Color3.fromRGB(70, 40, 25))
		piece(rig, Vector3.new(0.3, 0.08, 0.35), CFrame.new(x * 1.0, -0.12, -0.1), Color3.fromRGB(190, 170, 120), Enum.Material.Metal)
	end
	-- 다리 넷
	local i = 0
	for _, z in ipairs({ -1.55, 1.55 }) do
		for _, x in ipairs({ -0.55, 0.55 }) do
			i += 1
			leg(rig, i, CFrame.new(x, -0.55, z), c, DARK, 0.42, false)
		end
	end
end

local function tiger(rig: Rig, m: any)
	local c, stripe = m.color, m.mane
	rig.thigh, rig.shin, rig.bodyY = 0.85, 0.8, 1.45
	-- 낮고 긴 몸통, 두툼한 어깨와 엉덩이
	tube(rig, 3.6, 1.45, CFrame.new(0, 0, 0), c)
	piece(rig, Vector3.new(1.75, 1.75, 1.75), CFrame.new(0, 0.1, -1.75), c, nil, Ball)
	piece(rig, Vector3.new(1.7, 1.7, 1.7), CFrame.new(0, 0.05, 1.75), c, nil, Ball)
	-- 머리: 둥근 머리, 넓적한 주둥이, 둥근 귀, 빛나는 눈
	local head = CFrame.new(0, 0.55, -2.95)
	piece(rig, Vector3.new(1.45, 1.45, 1.45), head, c, nil, Ball)
	piece(rig, Vector3.new(0.95, 0.6, 0.6), head * CFrame.new(0, -0.25, -0.62), c:Lerp(Color3.new(1, 1, 1), 0.3))
	piece(rig, Vector3.new(0.3, 0.2, 0.15), head * CFrame.new(0, -0.05, -0.93), DARK)
	for _, x in ipairs({ -1, 1 }) do
		piece(rig, Vector3.new(0.4, 0.4, 0.4), head * CFrame.new(x * 0.5, 0.6, 0.05), c, nil, Ball)
		piece(rig, Vector3.new(0.2, 0.12, 0.06), head * CFrame.new(x * 0.32, 0.18, -0.68), Color3.fromRGB(90, 200, 255), Enum.Material.Neon)
		-- 얼굴 줄무늬
		piece(rig, Vector3.new(0.08, 0.35, 0.08), head * CFrame.new(x * 0.55, 0.15, -0.45) * CFrame.Angles(0, 0, x * math.rad(30)), stripe)
	end
	-- 몸의 줄무늬: 등 위와 옆구리로 감기는 검은 띠
	for k = -2, 2 do
		local z = k * 0.68
		piece(rig, Vector3.new(0.9, 0.08, 0.2), CFrame.new(0, 0.73, z), stripe)
		for _, x in ipairs({ -1, 1 }) do
			piece(rig, Vector3.new(0.08, 0.7, 0.2), CFrame.new(x * 0.68, 0.35, z + 0.1) * CFrame.Angles(0, 0, x * math.rad(-30)), stripe)
		end
	end
	-- 꼬리: 위로 휘어 올라간다 (끝은 검게)
	for k = 0, 3 do
		piece(rig, Vector3.new(0.26, 0.26, 0.8), CFrame.new(0, 0.45 + k * 0.32, 2.75 + k * 0.5) * CFrame.Angles(math.rad(-20 - k * 15), 0, 0), k == 3 and stripe or c)
	end
	-- 안장 대신 두툼한 천
	piece(rig, Vector3.new(1.6, 0.18, 1.7), CFrame.new(0, 0.78, -0.2), Color3.fromRGB(60, 80, 150), Enum.Material.Fabric)
	piece(rig, Vector3.new(1.65, 0.08, 1.75), CFrame.new(0, 0.7, -0.2), Color3.fromRGB(220, 190, 90), Enum.Material.Fabric)
	local i = 0
	for _, z in ipairs({ -1.6, 1.6 }) do
		for _, x in ipairs({ -0.55, 0.55 }) do
			i += 1
			leg(rig, i, CFrame.new(x, -0.45, z), c, c, 0.48, true)
		end
	end
end

local function cloud(rig: Rig, m: any)
	rig.thigh, rig.shin, rig.bodyY = 0, 0, 1.4
	-- 겹겹이 뭉친 구름: 가운데가 크고, 둘레와 위에 작은 뭉치
	local spots = {
		{ 0, 0, 0, 2.8 }, { 1.2, 0.1, -0.9, 2.0 }, { -1.2, 0.1, -0.9, 2.0 }, { 1.3, 0, 0.9, 2.1 }, { -1.3, 0, 0.9, 2.1 },
		{ 0, 0.2, -1.8, 1.9 }, { 0, 0.15, 1.8, 2.0 }, { 0.7, 0.75, 0.2, 1.5 }, { -0.7, 0.75, 0.2, 1.5 },
	}
	for _, sp in ipairs(spots) do
		piece(rig, Vector3.new(sp[4], sp[4], sp[4]), CFrame.new(sp[1], sp[2], sp[3]), m.color, Enum.Material.SmoothPlastic, Ball)
	end
	-- 금빛 아랫빛과 반짝이는 가루
	local glow = piece(rig, Vector3.new(0.3, 4.4, 4.4), CFrame.new(0, -0.9, 0) * CFrame.Angles(0, 0, math.rad(90)), m.mane, Enum.Material.Neon, Cyl).p
	glow.Transparency = 0.45
	local light = Instance.new("PointLight")
	light.Color = m.mane
	light.Range = 14
	light.Brightness = 1.5
	light.Parent = glow
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(m.mane)
	sparkle.Size = NumberSequence.new(0.35, 0)
	sparkle.Lifetime = NumberRange.new(0.6, 1)
	sparkle.Rate = 18
	sparkle.Speed = NumberRange.new(1, 2)
	sparkle.SpreadAngle = Vector2.new(60, 60)
	sparkle.Parent = glow
	-- 뒤로 흩어지는 꼬리 구름
	for k = 1, 4 do
		local sz = 1.6 - k * 0.3
		piece(rig, Vector3.new(sz, sz, sz), CFrame.new(math.sin(k) * 0.4, 0.1 - k * 0.05, 2.4 + k * 0.85), m.color, Enum.Material.SmoothPlastic, Ball).p.Transparency = k * 0.12
	end
end

-- 청룡: 열여섯 마디의 몸통이 탄 사람 아래에서 뒤로 물결치며 흐른다. di = 마디 번호 (0이 머리 쪽)
local DRAGON_N = 16
local function dragon(rig: Rig, m: any)
	rig.thigh, rig.shin, rig.bodyY = 0, 0, 1.6
	local c, gold = m.color, m.mane
	local belly = Color3.fromRGB(240, 225, 170)
	for i = 0, DRAGON_N - 1 do
		local t = i / (DRAGON_N - 1)
		local size = 2.0 - t * 1.35
		local seg = piece(rig, Vector3.new(size, size * 0.9, 1.5), CFrame.new(), c, Enum.Material.SmoothPlastic, Ball)
		seg.di = i
		local bel = piece(rig, Vector3.new(size * 0.7, size * 0.35, 1.3), CFrame.new(0, -size * 0.32, 0), belly)
		bel.di = i
		-- 등지느러미 (금빛, 마디마다)
		local fin = piece(rig, Vector3.new(0.1, size * 0.55, 0.7), CFrame.new(0, size * 0.5, 0.1) * CFrame.Angles(math.rad(-25), 0, 0), gold, Enum.Material.Metal)
		fin.di = i
		-- 발톱 달린 짧은 다리 넷 (마디 3과 10)
		if i == 3 or i == 10 then
			for _, x in ipairs({ -1, 1 }) do
				local lg = piece(rig, Vector3.new(0.3, 0.9, 0.3), CFrame.new(x * size * 0.45, -size * 0.45, 0) * CFrame.Angles(math.rad(30), 0, x * math.rad(25)), c)
				lg.di = i
				local claw = piece(rig, Vector3.new(0.45, 0.2, 0.5), CFrame.new(x * size * 0.6, -size * 0.85, -0.2), gold, Enum.Material.Metal)
				claw.di = i
			end
		end
	end
	-- 꼬리 끝의 금빛 지느러미
	local tailFin = piece(rig, Vector3.new(0.12, 1.4, 1.2), CFrame.new(0, 0, 0.8) * CFrame.Angles(math.rad(20), 0, 0), gold, Enum.Material.Metal)
	tailFin.di = DRAGON_N - 1
	-- 머리: 주둥이, 아래턱, 금빛 뿔 둘, 늘어진 수염, 빛나는 눈, 갈기
	local H = -1
	local head = piece(rig, Vector3.new(1.5, 1.2, 1.7), CFrame.new(0, 0.35, -0.9), c)
	head.di = H
	local snout = piece(rig, Vector3.new(1.0, 0.7, 1.1), CFrame.new(0, 0.2, -2.0), c)
	snout.di = H
	local jaw = piece(rig, Vector3.new(0.95, 0.3, 1.4), CFrame.new(0, -0.3, -1.7) * CFrame.Angles(math.rad(8), 0, 0), belly)
	jaw.di = H
	for _, x in ipairs({ -1, 1 }) do
		local horn = piece(rig, Vector3.new(0.18, 0.18, 1.6), CFrame.new(x * 0.45, 1.15, -0.2) * CFrame.Angles(math.rad(35), x * math.rad(15), 0), gold, Enum.Material.Metal)
		horn.di = H
		local eye = piece(rig, Vector3.new(0.25, 0.18, 0.1), CFrame.new(x * 0.5, 0.6, -1.65), Color3.fromRGB(255, 240, 120), Enum.Material.Neon)
		eye.di = H
		local wh = piece(rig, Vector3.new(0.06, 0.06, 2.4), CFrame.new(x * 0.5, 0.0, -2.0) * CFrame.Angles(math.rad(-20), x * math.rad(35), 0) * CFrame.new(0, 0, 1.0), gold, Enum.Material.Neon)
		wh.di = H
		local nostril = piece(rig, Vector3.new(0.12, 0.12, 0.12), CFrame.new(x * 0.28, 0.45, -2.5), Color3.fromRGB(20, 40, 35), nil, Ball)
		nostril.di = H
	end
	for k = 0, 4 do
		local mane = piece(rig, Vector3.new(0.12, 0.7, 0.5), CFrame.new(0, 0.95 - k * 0.08, -0.3 + k * 0.45) * CFrame.Angles(math.rad(-35), 0, (k % 2 == 0 and 1 or -1) * math.rad(12)), gold)
		mane.di = H
	end
	-- 금빛 가루와 빛
	local glow = head.p
	local light = Instance.new("PointLight")
	light.Color = gold
	light.Range = 16
	light.Brightness = 1.4
	light.Parent = glow
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	dust.Color = ColorSequence.new(gold)
	dust.Size = NumberSequence.new(0.4, 0)
	dust.Lifetime = NumberRange.new(0.8, 1.4)
	dust.Rate = 24
	dust.Speed = NumberRange.new(0.5, 1.5)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.Parent = glow
end

-- 청룡 마디의 자리 (탈것 기준 공간): 앞에서 뒤로, 옆과 위아래로 물결친다
local function dragonPath(t: number, run: number): { Vector3 }
	local pts = {}
	for i = 0, DRAGON_N - 1 do
		local w = i / (DRAGON_N - 1)
		local amp = 0.25 + w * (0.9 + 0.5 * run)
		local x = math.sin(t * 3.2 - i * 0.55) * amp
		local y = math.sin(t * 2.1 - i * 0.45) * (0.25 + w * 0.6) + w * 0.6
		pts[i + 1] = Vector3.new(x, y, -1.6 + i * 1.05)
	end
	return pts
end

local function build(model: Model, id: string)
	local m = Config.MOUNT_BY_ID[id]
	if not m then
		return
	end
	local rig: Rig = { parts = {}, kind = m.kind, phase = 0, model = model, thigh = 1, shin = 1, bodyY = 1.6 }
	if m.kind == "cloud" then
		cloud(rig, m)
	elseif m.kind == "dragon" then
		dragon(rig, m)
	elseif m.kind == "tiger" then
		tiger(rig, m)
	else
		horse(rig, m)
	end
	rigs[model] = rig
end

local function clear(model: Model)
	local rig = rigs[model]
	if rig then
		for _, e in ipairs(rig.parts) do
			e.p:Destroy()
		end
		rigs[model] = nil
	end
end

function Mount.watch(model: Model)
	local function refresh()
		clear(model)
		local id = model:GetAttribute("Mount")
		if type(id) == "string" then
			build(model, id)
		end
	end
	model:GetAttributeChangedSignal("Mount"):Connect(refresh)
	model.AncestryChanged:Connect(function()
		if not model.Parent then
			clear(model)
		end
	end)
	refresh()
end

-- 매 화면: 탄 사람의 엉덩이 아래에 등이 오도록 놓고, 달리는 빠르기만큼 다리를 번갈아 굽혔다 편다
RunService.RenderStepped:Connect(function(dt: number)
	for model, rig in pairs(rigs) do
		local root = model:FindFirstChild("HumanoidRootPart")
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not hum or not model.Parent then
			clear(model)
			continue
		end
		local vel = root.AssemblyLinearVelocity
		local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
		rig.phase += dt * (2.5 + speed * 0.42)
		local run = math.clamp(speed / 18, 0, 1)
		local look = root.CFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude < 1e-3 then
			flatLook = Vector3.new(0, 0, -1)
		end
		-- 등(몸통 꼭대기)이 탄 사람 엉덩이 바로 아래에 오도록
		local seat = root.Position - Vector3.new(0, root.Size.Y / 2 + 0.15, 0)
		local base: CFrame
		local path: { Vector3 }? = nil
		if rig.kind == "dragon" then
			base = CFrame.lookAt(seat, seat + flatLook) * CFrame.new(0, -1.0 + math.sin(os.clock() * 1.8) * 0.2, 0)
			path = dragonPath(os.clock(), run)
		elseif rig.kind == "cloud" then
			base = CFrame.lookAt(seat, seat + flatLook) * CFrame.new(0, -1.1 + math.sin(os.clock() * 2.2) * 0.15, 0) * CFrame.Angles(0, 0, math.sin(os.clock() * 1.3) * 0.04)
		else
			local bob = math.abs(math.sin(rig.phase)) * 0.2 * run
			local pitch = math.sin(rig.phase * 2) * math.rad(2.5) * run
			base = CFrame.lookAt(seat, seat + flatLook) * CFrame.new(0, -rig.bodyY / 2 - 0.25 + bob, 0) * CFrame.Angles(pitch, 0, 0)
		end
		for _, e in ipairs(rig.parts) do
			if path and e.di then
				-- 청룡: 마디는 앞 마디를 바라보며 물결 위에 놓인다. 머리(-1)는 첫 마디 앞에서 앞을 본다
				local pts = path
				if e.di < 0 then
					local p0, p1 = pts[1], pts[2]
					local dir = (p0 - p1).Unit
					e.p.CFrame = base * CFrame.lookAt(p0 + dir * 0.6 + Vector3.new(0, 0.4, 0), p0 + dir * 3 + Vector3.new(0, 0.4, 0)) * e.off
				else
					local here = pts[e.di + 1]
					local ahead = pts[e.di] or (here + (here - pts[e.di + 2]))
					e.p.CFrame = base * CFrame.lookAt(here, ahead) * e.off
				end
			elseif e.leg then
				-- 대각선 다리끼리 같이 (1·4, 2·3). 허벅지가 앞뒤로 흔들리고, 정강이는 들 때 굽는다
				local ph = rig.phase + ((e.leg == 1 or e.leg == 4) and 0 or math.pi)
				local swing = math.sin(ph) * math.rad(34) * run
				local bend = math.max(0, math.sin(ph + 1.3)) * math.rad(55) * run
				local hip = base * e.off * CFrame.Angles(swing, 0, 0)
				local knee = hip * CFrame.new(0, -rig.thigh, 0) * CFrame.Angles(e.leg <= 2 and bend or -bend, 0, 0)
				if e.seg == "thigh" then
					e.p.CFrame = hip * CFrame.new(0, -rig.thigh / 2, 0)
				elseif e.seg == "shin" then
					e.p.CFrame = knee * CFrame.new(0, -rig.shin / 2, 0)
				else
					e.p.CFrame = knee * CFrame.new(0, -rig.shin - 0.05, -0.05)
				end
			else
				e.p.CFrame = base * e.off
			end
		end
	end
end)

return Mount
