-- 권왕 2.7판: 피의 악마 (화면에만 보이는 연출). 처음부터 다시 짰다
-- 혈해만마: 피의 바다에서 허리까지 솟은 마수들이 손톱을 휘두른다
-- 혈월만겸: 쓴 사람 뒤에서 날개 달린 거대한 우두머리 악마가 솟아, 큰 낫을 치켜들었다가 내리찍는다
-- 생김새: 굽은 등과 넓은 가슴, 뒤로 휘어 감기는 이어진 뿔, 이마 아래 빛나는 눈, 긴 팔과 갈고리 손가락,
-- 뼈대 사이에 막이 이어진 박쥐 날개 (세모 조각으로 막을 채운다), 초승달처럼 휜 한 장의 낫날
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Demon = {}

local SKIN = Color3.fromRGB(58, 10, 14)
local SKIN2 = Color3.fromRGB(88, 16, 22)
local PLATE = Color3.fromRGB(34, 8, 11)
local HORN = Color3.fromRGB(28, 20, 20)
local BONE = Color3.fromRGB(214, 196, 178)
local WING = Color3.fromRGB(72, 10, 18)
local EYE = Color3.fromRGB(255, 70, 40)
local RED = Color3.fromRGB(220, 24, 40)
local IRON = Color3.fromRGB(46, 12, 16)
local SHAFT = Color3.fromRGB(30, 14, 14)

local folder = Instance.new("Folder")
folder.Name = "KwonDemon"
folder.Parent = workspace

type Piece = { p: BasePart, limb: string, off: CFrame }
export type Handle = {
	root: CFrame,
	armR: number,
	armL: number,
	scale: number,
	pieces: { Piece },
	model: Model,
	alive: boolean,
	born: number,
	anim: ((t: number) -> ())?,
	conn: RBXScriptConnection?,
}

local function newPart(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, shape: string?): BasePart
	local p: BasePart
	if shape == "wedge" then
		p = Instance.new("WedgePart")
	else
		local q = Instance.new("Part")
		if shape == "ball" then
			q.Shape = Enum.PartType.Ball
		elseif shape == "cyl" then
			q.Shape = Enum.PartType.Cylinder
		end
		p = q
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = alpha or 0
	return p
end

-- 관절 자리 (팔은 어깨를 축으로 앞뒤로 돈다: 0 = 아래로 늘어뜨림, π/2 = 앞으로 뻗음, π = 머리 위)
local SHOULDER_R = Vector3.new(2.05, 6.55, 0)
local SHOULDER_L = Vector3.new(-2.05, 6.55, 0)
local WING_R = Vector3.new(1.0, 7.2, 0.95)
local WING_L = Vector3.new(-1.0, 7.2, 0.95)

local function place(h: Handle)
	local s = h.scale
	local root = h.root
	local t = os.clock() - h.born
	local flap = math.sin(t * 2.2) * 0.12
	local frames = {
		B = root,
		R = root * CFrame.new(SHOULDER_R * s) * CFrame.Angles(h.armR, 0, 0),
		L = root * CFrame.new(SHOULDER_L * s) * CFrame.Angles(h.armL, 0, 0),
		WR = root * CFrame.new(WING_R * s) * CFrame.Angles(0, -flap, -flap * 0.5),
		WL = root * CFrame.new(WING_L * s) * CFrame.Angles(0, flap, flap * 0.5),
	}
	for _, pc in ipairs(h.pieces) do
		pc.p.CFrame = (frames[pc.limb] or root) * pc.off
	end
end

-- rootCf: 발밑 (악마는 -Z 쪽을 본다). scale 1 = 사람보다 조금 큰 키 (약 9칸)
function Demon.spawn(rootCf: CFrame, scale: number, opts: { scythe: boolean?, wings: boolean?, legs: boolean? }?): Handle
	local o = opts or {}
	local s = scale
	local model = Instance.new("Model")
	model.Name = "KwonDemon"
	local h: Handle = { root = rootCf, armR = 0.3, armL = 0.3, scale = s, pieces = {}, model = model, alive = true, born = os.clock() }
	local function add(limb: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, alpha: number?, shape: string?): BasePart
		local p = newPart(size * s, color, mat, alpha, shape)
		p.Parent = model
		table.insert(h.pieces, { p = p, limb = limb, off = CFrame.new(cf.Position * s) * cf.Rotation })
		return p
	end
	-- 세모 하나 = 쐐기 둘 (로블록스에서 세모를 그리는 흔한 방법). 꼭짓점은 그 부위 기준 좌표
	local function tri(limb: string, a: Vector3, b: Vector3, c: Vector3, color: Color3, mat: Enum.Material?, alpha: number?, thick: number?)
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c, a = a, c
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		if ac:Cross(ab).Magnitude < 1e-4 then
			return
		end
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		local th = (thick or 0.12)
		local w1 = add(limb, Vector3.new(th, height, math.abs(ab:Dot(back))), CFrame.fromMatrix((a + b) / 2, right, up, back), color, mat, alpha, "wedge")
		local w2 = add(limb, Vector3.new(th, height, math.abs(ac:Dot(back))), CFrame.fromMatrix((a + c) / 2, -right, up, -back), color, mat, alpha, "wedge")
		local _ = w1
		local _ = w2
	end
	-- 이어진 마디 (뿔·손가락·꼬리): 마디마다 조금씩 꺾이며 가늘어진다. 마디는 서로 겹쳐 끊기지 않는다
	local function chain(limb: string, start: CFrame, n: number, len: number, w0: number, w1: number, bend: CFrame, color: Color3, mat: Enum.Material?): CFrame
		local cf = start
		for j = 0, n - 1 do
			local u = j / math.max(1, n - 1)
			local w = w0 + (w1 - w0) * u
			add(limb, Vector3.new(w, len * 1.3, w), cf * CFrame.new(0, len / 2, 0), color, mat)
			cf = cf * CFrame.new(0, len, 0) * bend
		end
		return cf
	end

	-- 허리와 다리 (다리가 있으면 짐승처럼 무릎이 앞으로, 발목이 뒤로 꺾인다)
	add("B", Vector3.new(1.9, 0.95, 1.25), CFrame.new(0, 3.45, 0.05), SKIN)
	if o.legs ~= false then
		for _, x in ipairs({ -1, 1 }) do
			add("B", Vector3.new(1.0, 2.0, 1.1), CFrame.new(x * 0.78, 2.55, -0.25) * CFrame.Angles(math.rad(22), 0, x * math.rad(-4)), SKIN2)
			add("B", Vector3.new(0.75, 1.7, 0.8), CFrame.new(x * 0.82, 1.35, 0.25) * CFrame.Angles(math.rad(-28), 0, 0), SKIN)
			add("B", Vector3.new(0.6, 0.9, 0.65), CFrame.new(x * 0.82, 0.45, 0.32) * CFrame.Angles(math.rad(14), 0, 0), SKIN2)
			add("B", Vector3.new(0.85, 0.35, 1.2), CFrame.new(x * 0.82, 0.16, -0.12), PLATE)
			for j = -1, 1 do
				add("B", Vector3.new(0.16, 0.16, 0.5), CFrame.new(x * 0.82 + j * 0.26, 0.12, -0.8) * CFrame.Angles(math.rad(12), j * 0.2, 0), BONE)
			end
		end
		-- 꼬리: 허리 뒤에서 땅으로 늘어졌다가 끝이 들린다
		local tip = chain("B", CFrame.new(0, 3.3, 0.6) * CFrame.Angles(math.rad(-120), 0, 0), 7, 0.75, 0.5, 0.16, CFrame.Angles(math.rad(10), math.rad(6), 0), SKIN)
		add("B", Vector3.new(0.5, 0.6, 0.12), tip * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.rad(45)), PLATE)
	end
	-- 배와 가슴: 아래는 좁고 위는 넓게, 등이 굽었다
	add("B", Vector3.new(1.75, 1.35, 1.15), CFrame.new(0, 4.45, -0.05), SKIN2)
	for i = 0, 2 do
		add("B", Vector3.new(1.3 - i * 0.12, 0.3, 0.1), CFrame.new(0, 4.0 + i * 0.42, -0.63), PLATE)
	end
	add("B", Vector3.new(3.4, 2.05, 1.9), CFrame.new(0, 6.05, 0.05) * CFrame.Angles(math.rad(-10), 0, 0), SKIN)
	for _, x in ipairs({ -1, 1 }) do
		add("B", Vector3.new(1.45, 1.0, 0.45), CFrame.new(x * 0.74, 6.35, -0.92) * CFrame.Angles(math.rad(-12), 0, x * math.rad(-6)), SKIN2)
		-- 어깨 근육과 그 위로 솟은 뼈 가시 둘
		add("B", Vector3.new(1.55, 1.45, 1.6), CFrame.new(x * 1.95, 6.85, 0.05), SKIN2, nil, nil, "ball")
		for j = 0, 1 do
			chain("B", CFrame.new(x * (1.75 + j * 0.45), 7.4, 0.25 + j * 0.2) * CFrame.Angles(math.rad(-30), 0, x * math.rad(-25)), 3, 0.4 - j * 0.08, 0.3, 0.08, CFrame.Angles(math.rad(-12), 0, 0), BONE)
		end
	end
	-- 가슴 한가운데의 갈라진 틈 (속에서 핏빛이 샌다)
	add("B", Vector3.new(0.12, 1.4, 0.08), CFrame.new(0, 6.0, -1.08) * CFrame.Angles(math.rad(-10), 0, 0), RED, Enum.Material.Neon)
	for _, x in ipairs({ -1, 1 }) do
		add("B", Vector3.new(0.7, 0.08, 0.08), CFrame.new(x * 0.32, 5.7, -1.02) * CFrame.Angles(0, 0, x * math.rad(-25)), RED, Enum.Material.Neon)
	end
	-- 등뼈 가시 다섯
	for i = 0, 4 do
		chain("B", CFrame.new(0, 7.1 - i * 0.7, 0.95 + i * 0.02) * CFrame.Angles(math.rad(-60), 0, 0), 2, 0.4 - i * 0.04, 0.3, 0.1, CFrame.Angles(math.rad(-15), 0, 0), BONE)
	end
	-- 목과 머리: 앞으로 내민 머리, 무거운 이마, 아래턱, 이빨, 빛나는 눈
	add("B", Vector3.new(1.05, 0.9, 1.05), CFrame.new(0, 7.2, -0.3) * CFrame.Angles(math.rad(-20), 0, 0), SKIN)
	add("B", Vector3.new(1.4, 1.25, 1.5), CFrame.new(0, 7.8, -0.6), SKIN2)
	add("B", Vector3.new(1.55, 0.36, 0.55), CFrame.new(0, 8.12, -1.2) * CFrame.Angles(math.rad(12), 0, 0), PLATE)
	add("B", Vector3.new(1.2, 0.5, 1.15), CFrame.new(0, 7.2, -0.85) * CFrame.Angles(math.rad(8), 0, 0), SKIN)
	for _, x in ipairs({ -1, 1 }) do
		add("B", Vector3.new(0.36, 0.13, 0.08), CFrame.new(x * 0.34, 7.95, -1.38) * CFrame.Angles(0, 0, x * math.rad(-14)), EYE, Enum.Material.Neon)
		add("B", Vector3.new(0.12, 0.38, 0.12), CFrame.new(x * 0.36, 7.12, -1.36) * CFrame.Angles(0, 0, x * math.rad(6)), BONE)
		add("B", Vector3.new(0.4, 0.5, 0.12), CFrame.new(x * 0.72, 7.75, -0.4) * CFrame.Angles(0, x * math.rad(30), x * math.rad(-30)), SKIN2)
		-- 뿔: 이마 옆에서 위로 솟아 뒤로 휘어 감긴다 (마디 일곱이 이어진다)
		chain("B", CFrame.new(x * 0.58, 8.25, -0.75) * CFrame.Angles(math.rad(-10), 0, x * math.rad(-38)), 7, 0.62, 0.5, 0.1, CFrame.Angles(math.rad(-24), 0, x * math.rad(7)), HORN, Enum.Material.Slate)
	end
	add("B", Vector3.new(0.85, 0.1, 0.08), CFrame.new(0, 7.38, -1.45), RED, Enum.Material.Neon)
	for j = -2, 2 do
		add("B", Vector3.new(0.1, 0.18, 0.08), CFrame.new(j * 0.17, 7.46, -1.47), BONE)
	end

	-- 팔 (어깨 기준): 윗팔, 팔꿈치 가시, 손목으로 갈수록 굵은 아래팔과 그 위의 판, 손바닥, 갈고리 손가락 넷과 엄지
	for _, limb in ipairs({ "R", "L" }) do
		add(limb, Vector3.new(1.05, 2.4, 1.05), CFrame.new(0, -1.2, 0), SKIN)
		chain(limb, CFrame.new(0, -2.3, 0.45) * CFrame.Angles(math.rad(120), 0, 0), 2, 0.45, 0.28, 0.08, CFrame.Angles(math.rad(-10), 0, 0), BONE)
		add(limb, Vector3.new(0.95, 2.2, 1.0), CFrame.new(0, -3.4, -0.05), SKIN2)
		add(limb, Vector3.new(1.05, 1.3, 0.35), CFrame.new(0, -3.6, -0.52), PLATE)
		add(limb, Vector3.new(1.15, 0.8, 0.95), CFrame.new(0, -4.85, -0.1), SKIN)
		if not (limb == "R" and o.scythe) then
			for j = 0, 3 do
				local x = (j - 1.5) * 0.28
				local tip = chain(limb, CFrame.new(x, -5.15, -0.3) * CFrame.Angles(math.rad(180 + 15), 0, 0), 3, 0.42, 0.2, 0.1, CFrame.Angles(math.rad(-24), 0, 0), SKIN2)
				add(limb, Vector3.new(0.09, 0.45, 0.09), tip * CFrame.new(0, 0.15, 0) * CFrame.Angles(math.rad(-20), 0, 0), BONE)
			end
			chain(limb, CFrame.new(limb == "R" and -0.55 or 0.55, -4.75, -0.45) * CFrame.Angles(math.rad(200), 0, (limb == "R" and 1 or -1) * math.rad(30)), 2, 0.4, 0.22, 0.12, CFrame.Angles(math.rad(-25), 0, 0), SKIN2)
		else
			-- 낫을 쥔 주먹
			add(limb, Vector3.new(1.2, 0.7, 1.0), CFrame.new(0, -5.3, -0.15), SKIN2)
		end
	end

	-- 날개: 뼈 (윗뼈 하나와 손가락뼈 셋, 엄지 갈고리)와 그 사이를 잇는 막. 바깥 가장자리는 오목하게
	if o.wings then
		for _, side in ipairs({ { "WR", 1 }, { "WL", -1 } }) do
			local limb, x = side[1], side[2]
			local function v(px: number, py: number, pz: number): Vector3
				return Vector3.new(px * x, py, pz)
			end
			local R0, W = v(0, 0, 0), v(3.4, 2.4, 1.2)
			local T1, T2, T3 = v(7.4, 4.0, 1.9), v(8.0, 0.2, 2.2), v(5.6, -2.8, 1.9)
			local B = v(0.1, -2.6, 0.1)
			local function bone(a: Vector3, b: Vector3, w: number)
				local mid = (a + b) / 2
				add(limb, Vector3.new(w, w, (b - a).Magnitude + w * 0.6), CFrame.lookAt(mid, b), SKIN2)
			end
			bone(R0, W, 0.4)
			bone(W, T1, 0.24)
			bone(W, T2, 0.22)
			bone(W, T3, 0.2)
			add(limb, Vector3.new(0.5, 0.5, 0.5), CFrame.new(W), SKIN2, nil, nil, "ball")
			chain(limb, CFrame.new(W) * CFrame.Angles(0, 0, x * math.rad(-30)), 2, 0.35, 0.18, 0.07, CFrame.Angles(math.rad(-30), 0, 0), BONE)
			-- 막: 손가락 끝 사이를 안쪽으로 당겨 오목하게
			local M12 = (T1 + T2) / 2 * 0.82 + W * 0.18
			local M23 = (T2 + T3) / 2 * 0.82 + W * 0.18
			local M3B = (T3 + B) / 2 * 0.85 + W * 0.15
			for _, t in ipairs({ { W, T1, M12 }, { W, M12, T2 }, { W, T2, M23 }, { W, M23, T3 }, { W, T3, M3B }, { W, M3B, B }, { R0, W, B } }) do
				tri(limb, t[1], t[2], t[3], WING, Enum.Material.SmoothPlastic, 0.06, 0.1)
			end
		end
	end

	-- 큰 낫: 손에서 위아래로 뻗은 자루 (감긴 손잡이, 끝의 가시), 자루 끝에서 초승달처럼 휜 한 장의 날
	if o.scythe then
		add("R", Vector3.new(0.42, 14.0, 0.42), CFrame.new(0, -9.8, -0.15), SHAFT, Enum.Material.Wood)
		for i = 0, 3 do
			add("R", Vector3.new(0.5, 0.18, 0.5), CFrame.new(0, -6.0 - i * 0.55, -0.15), IRON, Enum.Material.Metal)
		end
		local tipY = -16.6
		local base = Vector3.new(0, tipY, -0.15)
		-- 날 뿌리의 쇠 고리와 해골
		add("R", Vector3.new(0.9, 1.2, 0.9), CFrame.new(base + Vector3.new(0, 0.3, 0)), IRON, Enum.Material.Metal)
		add("R", Vector3.new(0.85, 0.8, 0.8), CFrame.new(base + Vector3.new(0, 1.1, -0.2)), BONE, nil, nil, "ball")
		for _, xx in ipairs({ -1, 1 }) do
			add("R", Vector3.new(0.18, 0.16, 0.06), CFrame.new(base + Vector3.new(xx * 0.18, 1.15, -0.6)), RED, Enum.Material.Neon)
		end
		-- 날: 등줄기(휜 곡선)에서 안쪽(오목한 쪽)으로 폭이 있는 판. 끝으로 갈수록 가늘어진다
		local n = 12
		local backs, edges = {}, {}
		for i = 0, n do
			local u = i / n
			local c = base + Vector3.new(0, 3.6 * u * u, 8.2 * u)
			local tan = Vector3.new(0, 7.2 * u, 8.2).Unit
			local nrm = Vector3.new(0, tan.Z, -tan.Y)
			local w = 1.9 * (1 - u) ^ 0.85 + 0.04
			backs[i] = c
			edges[i] = c + nrm * w
		end
		for i = 0, n - 1 do
			tri("R", backs[i], backs[i + 1], edges[i], IRON, Enum.Material.Metal, 0, 0.22)
			tri("R", backs[i + 1], edges[i + 1], edges[i], IRON, Enum.Material.Metal, 0, 0.22)
			-- 날끝을 따라 붉게 빛나는 선
			local a, b = edges[i], edges[i + 1]
			add("R", Vector3.new(0.26, 0.16, (b - a).Magnitude + 0.12), CFrame.lookAt((a + b) / 2, b), RED, Enum.Material.Neon)
			-- 등줄기의 두꺼운 테
			local c0, c1 = backs[i], backs[i + 1]
			add("R", Vector3.new(0.34, 0.3, (c1 - c0).Magnitude + 0.1), CFrame.lookAt((c0 + c1) / 2, c1), SHAFT, Enum.Material.Metal)
		end
		local glow = Instance.new("PointLight")
		glow.Color = RED
		glow.Range = 14 * s
		glow.Brightness = 1.5
		local tipPart = h.pieces[#h.pieces].p
		glow.Parent = tipPart
	end
	-- 가슴 속의 핏빛 (은은한 빛)
	local core = h.pieces[1].p
	local light = Instance.new("PointLight")
	light.Color = RED
	light.Range = 10 * s
	light.Brightness = 0.8
	light.Parent = core

	model.Parent = folder
	place(h)
	h.conn = RunService.RenderStepped:Connect(function()
		if not h.alive then
			return
		end
		local fn = h.anim
		if fn then
			local ok = pcall(fn, os.clock() - h.born)
			if not ok then
				h.anim = nil
			end
		end
		place(h)
	end)
	return h
end

-- 사라지기: 흐려지며 가라앉는다
function Demon.remove(h: Handle, time: number?)
	if not h.alive or (h :: any).leaving then
		return
	end
	(h :: any).leaving = true
	local t = time or 0.6
	for _, pc in ipairs(h.pieces) do
		TweenService:Create(pc.p, TweenInfo.new(t), { Transparency = 1 }):Play()
	end
	task.delay(t + 0.05, function()
		h.alive = false
		if h.conn then
			h.conn:Disconnect()
		end
		h.model:Destroy()
	end)
end

return Demon
