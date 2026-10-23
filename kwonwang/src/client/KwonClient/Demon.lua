-- 권왕 2.1판: 피의 악마들 (화면에만 보이는 연출)
-- 혈해만마: 피의 바다에서 허리까지 솟은 마수들이 손톱을 휘두른다
-- 혈월만겸: 쓴 사람 뒤에서 날개 달린 거대한 우두머리 악마가 솟아, 큰 낫을 치켜들었다가 내리찍는다
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Demon = {}

local SKIN = Color3.fromRGB(70, 8, 14)
local SKIN2 = Color3.fromRGB(110, 14, 22)
local WING = Color3.fromRGB(90, 10, 20)
local BONE = Color3.fromRGB(235, 215, 200)
local EYE = Color3.fromRGB(255, 60, 40)
local RED = Color3.fromRGB(220, 20, 40)
local PALE = Color3.fromRGB(255, 170, 170)
local SHAFT = Color3.fromRGB(38, 10, 14)

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

local function part(size: Vector3, color: Color3, material: Enum.Material?, alpha: number?, shape: string?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.Transparency = alpha or 0
	if shape == "ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	end
	return p
end

-- 어깨 (팔은 어깨를 축으로 앞뒤로 돈다: 0 = 아래로 늘어뜨림, π/2 = 앞으로 뻗음, π = 머리 위)
local SHOULDER_R = Vector3.new(1.95, 6.5, 0)
local SHOULDER_L = Vector3.new(-1.95, 6.5, 0)

local function place(h: Handle)
	local s = h.scale
	local root = h.root
	local sR = root * CFrame.new(SHOULDER_R * s) * CFrame.Angles(h.armR, 0, 0)
	local sL = root * CFrame.new(SHOULDER_L * s) * CFrame.Angles(h.armL, 0, 0)
	for _, pc in ipairs(h.pieces) do
		local base = pc.limb == "R" and sR or (pc.limb == "L" and sL or root)
		pc.p.CFrame = base * pc.off
	end
end

-- rootCf: 발밑 (악마는 -Z 쪽을 본다). scale 1 = 사람보다 조금 큰 키 (약 9칸)
function Demon.spawn(rootCf: CFrame, scale: number, opts: { scythe: boolean?, wings: boolean?, legs: boolean? }?): Handle
	local o = opts or {}
	local s = scale
	local model = Instance.new("Model")
	model.Name = "KwonDemon"
	local h: Handle = { root = rootCf, armR = 0.3, armL = 0.3, scale = s, pieces = {}, model = model, alive = true, born = os.clock() }
	local function add(limb: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, alpha: number?, shape: string?): Part
		local p = part(size * s, color, mat, alpha, shape)
		p.Parent = model
		table.insert(h.pieces, { p = p, limb = limb, off = CFrame.new(cf.Position * s) * cf.Rotation })
		return p
	end
	-- 몸통: 굽은 등, 넓은 가슴
	add("B", Vector3.new(2.2, 1.2, 1.3), CFrame.new(0, 3.6, 0), SKIN)
	add("B", Vector3.new(2.0, 1.6, 1.2), CFrame.new(0, 4.8, 0.05), SKIN2)
	add("B", Vector3.new(3.4, 1.9, 1.8), CFrame.new(0, 6.2, 0) * CFrame.Angles(math.rad(-8), 0, 0), SKIN)
	-- 가슴의 핏빛 금 (속에서 빛이 샌다)
	add("B", Vector3.new(0.18, 1.5, 0.1), CFrame.new(0, 6.1, -0.92), RED, Enum.Material.Neon)
	add("B", Vector3.new(1.4, 0.14, 0.1), CFrame.new(0, 5.5, -0.62), RED, Enum.Material.Neon)
	-- 등뼈 가시
	for i = 0, 3 do
		add("B", Vector3.new(0.32, 1.0 - i * 0.12, 0.32), CFrame.new(0, 7.0 - i * 0.85, 0.95 + i * 0.05) * CFrame.Angles(math.rad(-40), 0, 0), BONE, Enum.Material.SmoothPlastic)
	end
	-- 어깨 덩어리와 뿔 가시
	for _, side in ipairs({ -1, 1 }) do
		add("B", Vector3.new(1.2, 1.0, 1.3), CFrame.new(side * 1.95, 6.95, 0), SKIN2)
		add("B", Vector3.new(0.3, 1.1, 0.3), CFrame.new(side * 2.15, 7.7, 0.1) * CFrame.Angles(0, 0, side * math.rad(-25)), BONE, Enum.Material.SmoothPlastic)
	end
	-- 머리: 앞으로 내민 머리, 턱, 빛나는 눈과 입
	add("B", Vector3.new(1.45, 1.35, 1.45), CFrame.new(0, 7.7, -0.3), SKIN2)
	add("B", Vector3.new(1.25, 0.45, 1.1), CFrame.new(0, 7.05, -0.45), SKIN)
	for _, side in ipairs({ -1, 1 }) do
		add("B", Vector3.new(0.4, 0.18, 0.1), CFrame.new(side * 0.36, 7.85, -1.03) * CFrame.Angles(0, 0, side * math.rad(-12)), EYE, Enum.Material.Neon)
		-- 이빨
		add("B", Vector3.new(0.14, 0.4, 0.14), CFrame.new(side * 0.35, 6.85, -0.95), BONE, Enum.Material.SmoothPlastic)
		-- 뿔: 위로 솟다가 뒤로 휜다
		for j = 0, 4 do
			local w = 0.42 - j * 0.07
			add("B", Vector3.new(w, 0.75, w), CFrame.new(side * (0.62 + 0.22 * j), 8.35 + 0.55 * j, 0.0 + 0.3 * j * j * 0.5) * CFrame.Angles(math.rad(-18 * j), 0, side * math.rad(-28 + 14 * j)), BONE, Enum.Material.SmoothPlastic)
		end
	end
	add("B", Vector3.new(0.85, 0.12, 0.1), CFrame.new(0, 7.22, -1.0), RED, Enum.Material.Neon)
	-- 다리
	if o.legs ~= false then
		for _, side in ipairs({ -1, 1 }) do
			add("B", Vector3.new(0.95, 2.0, 1.0), CFrame.new(side * 0.72, 2.3, 0.05) * CFrame.Angles(math.rad(12), 0, 0), SKIN)
			add("B", Vector3.new(0.8, 1.7, 0.8), CFrame.new(side * 0.78, 0.9, 0.25) * CFrame.Angles(math.rad(-14), 0, 0), SKIN2)
			add("B", Vector3.new(0.9, 0.35, 1.3), CFrame.new(side * 0.78, 0.15, -0.1), SKIN)
		end
	end
	-- 날개: 뼈대와 찢긴 막
	if o.wings then
		for _, side in ipairs({ -1, 1 }) do
			add("B", Vector3.new(0.35, 4.8, 0.35), CFrame.new(side * 2.4, 8.4, 1.5) * CFrame.Angles(math.rad(15), 0, side * math.rad(-58)), SKIN)
			add("B", Vector3.new(0.28, 4.2, 0.28), CFrame.new(side * 5.4, 9.3, 1.9) * CFrame.Angles(math.rad(15), 0, side * math.rad(-12)), SKIN)
			add("B", Vector3.new(0.4, 0.9, 0.4), CFrame.new(side * 5.7, 11.5, 2.0), BONE, Enum.Material.SmoothPlastic)
			add("B", Vector3.new(4.6, 4.2, 0.12), CFrame.new(side * 3.9, 7.2, 1.8) * CFrame.Angles(0, side * math.rad(-12), side * math.rad(-14)), WING, Enum.Material.SmoothPlastic, 0.12)
			add("B", Vector3.new(2.4, 3.0, 0.12), CFrame.new(side * 6.0, 7.4, 2.1) * CFrame.Angles(0, side * math.rad(-20), side * math.rad(8)), WING, Enum.Material.SmoothPlastic, 0.2)
		end
	end
	-- 팔 (어깨 기준): 윗팔, 팔꿈치 가시, 아래팔, 손, 손톱 셋
	for _, limb in ipairs({ "R", "L" }) do
		add(limb, Vector3.new(0.95, 2.3, 0.95), CFrame.new(0, -1.15, 0), SKIN)
		add(limb, Vector3.new(0.25, 0.9, 0.25), CFrame.new(0, -2.3, 0.55) * CFrame.Angles(math.rad(-50), 0, 0), BONE, Enum.Material.SmoothPlastic)
		add(limb, Vector3.new(0.85, 2.2, 0.85), CFrame.new(0, -3.3, -0.1), SKIN2)
		add(limb, Vector3.new(1.0, 0.75, 1.0), CFrame.new(0, -4.6, -0.15), SKIN)
		if not (limb == "R" and o.scythe) then
			for k = -1, 1 do
				add(limb, Vector3.new(0.2, 1.2, 0.2), CFrame.new(k * 0.32, -5.35, -0.45) * CFrame.Angles(math.rad(28), 0, 0), RED, Enum.Material.Neon)
			end
		end
	end
	-- 큰 낫: 손에서 길게 뻗은 검붉은 자루, 끝에서 휘어 나간 핏빛 날 (내리찍는 쪽으로 날이 선다)
	if o.scythe then
		add("R", Vector3.new(0.4, 13, 0.4), CFrame.new(0, -9.6, -0.15), SHAFT, Enum.Material.Metal)
		add("R", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, -3.4, -0.15), RED, Enum.Material.Neon)
		local tip = Vector3.new(0, -15.8, -0.15)
		add("R", Vector3.new(0.9, 1.2, 0.9), CFrame.new(tip), SKIN2, Enum.Material.Metal)
		local prev = tip
		local n = 9
		for k = 1, n do
			local u = k / n
			local pt = tip + Vector3.new(0, 3.4 * u * u, 7.5 * u)
			local mid = (prev + pt) / 2
			local len = (pt - prev).Magnitude + 0.15
			local w = 1.5 * (1 - u * 0.75)
			local cf = CFrame.lookAt(mid, pt)
			add("R", Vector3.new(0.3, w, len), cf, RED, Enum.Material.Neon, 0.02)
			-- 날끝 (바깥 가장자리)
			add("R", Vector3.new(0.18, 0.22, len), cf * CFrame.new(0, -w / 2, 0), PALE, Enum.Material.Neon)
			prev = pt
		end
	end
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
