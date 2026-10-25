-- 권왕 2.7판: 고대의 고래 (화면). 초·창해신권의 초 오의와 진 창해신권 고래강림이 함께 쓴다
-- 생김새: 혹등고래처럼 길고 굵은 몸 (여러 마디가 이어져 꼬리가 휜다), 짙은 등과 옅은 배, 턱 아래 주름,
-- 머리의 혹과 따개비, 몸길이의 삼분의 일인 긴 가슴지느러미 (앞 가장자리에 혹), 갈라진 넓은 꼬리지느러미,
-- 등에 새겨진 옛 무늬 (옅게 빛난다)와 오래된 흉터. 물 고래(water)는 몸 전체가 물빛 유리
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Whale = {}

-- 2.7.7판: 더 오래된 고래. 바위처럼 거칠고 이끼 낀 등, 누렇게 바랜 배, 등뼈를 따라 솟은 뼈 판,
-- 등에 박힌 채 삭아 버린 옛 작살, 턱과 지느러미에서 늘어진 해초, 옆구리의 빛나는 옛 봉인 고리, 빛나는 눈
local BACK = Color3.fromRGB(50, 62, 62)
local BACK2 = Color3.fromRGB(66, 78, 74)
local BELLY = Color3.fromRGB(184, 178, 160)
local GROOVE = Color3.fromRGB(140, 136, 120)
local BONE = Color3.fromRGB(214, 204, 176)
local MOSS = Color3.fromRGB(72, 98, 58)
local CORAL = Color3.fromRGB(196, 100, 74)
local KELP = Color3.fromRGB(42, 72, 46)
local WOOD = Color3.fromRGB(92, 70, 48)
local RUST = Color3.fromRGB(116, 78, 56)
local BARNACLE = Color3.fromRGB(222, 220, 208)
local RUNE = Color3.fromRGB(120, 230, 255)
local SCAR = Color3.fromRGB(170, 180, 186)
local EYE = Color3.fromRGB(12, 14, 18)

local folder = Instance.new("Folder")
folder.Name = "KwonWhale"
folder.Parent = workspace

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
	p.Parent = folder
	return p
end

type Piece = { p: BasePart, key: string, off: CFrame, alpha: number }
export type Rig = { pieces: { Piece }, lens: { number }, S: number, water: boolean, fin: { [string]: CFrame }, alive: boolean }

-- 몸 마디: 길이, 옆 반지름, 위아래 반지름 (머리 → 꼬리자루)
local SEGS = {
	{ 5.0, 2.8, 2.4 },
	{ 4.4, 3.4, 3.1 },
	{ 4.2, 3.6, 3.3 },
	{ 4.0, 3.35, 3.0 },
	{ 3.8, 2.85, 2.55 },
	{ 3.4, 2.15, 1.95 },
	{ 3.0, 1.45, 1.35 },
	{ 2.6, 0.95, 0.9 },
	{ 1.6, 0.6, 0.55 },
}

function Whale.build(S: number, water: boolean?, c: Color3?, c2: Color3?): Rig
	local wet = water == true
	local rig: Rig = { pieces = {}, lens = {}, S = S, water = wet, fin = {}, alive = true }
	local back = wet and (c or Color3.fromRGB(40, 130, 230)) or BACK
	local back2 = wet and back:Lerp(Color3.new(1, 1, 1), 0.12) or BACK2
	local belly = wet and (c2 or Color3.fromRGB(200, 240, 255)) or BELLY
	local groove = wet and belly:Lerp(back, 0.4) or GROOVE
	local skinMat = wet and Enum.Material.Glass or Enum.Material.Slate
	local skinA = wet and 0.22 or 0
	local function add(key: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, alpha: number?, shape: string?): BasePart
		local p = newPart(size * S, color, mat, alpha, shape)
		table.insert(rig.pieces, { p = p, key = key, off = CFrame.new(cf.Position * S) * cf.Rotation, alpha = alpha or 0 })
		return p
	end
	-- 세모 = 쐐기 둘 (꼭짓점은 그 부위 기준, S를 곱하기 전 좌표)
	local function tri(key: string, a: Vector3, b: Vector3, c3: Vector3, color: Color3, mat: Enum.Material?, alpha: number?, thick: number?)
		local ab, ac, bc = b - a, c3 - a, c3 - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c3, a = a, c3
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c3 - a, c3 - b
		if ac:Cross(ab).Magnitude < 1e-5 then
			return
		end
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local bk = bc.Unit
		local height = math.abs(ab:Dot(up))
		local th = (thick or 0.1) / S
		add(key, Vector3.new(th, height, math.abs(ab:Dot(bk))), CFrame.fromMatrix((a + b) / 2, right, up, bk), color, mat, alpha, "wedge")
		add(key, Vector3.new(th, height, math.abs(ac:Dot(bk))), CFrame.fromMatrix((a + c3) / 2, -right, up, -bk), color, mat, alpha, "wedge")
	end

	for i, sg in ipairs(SEGS) do
		local len, rx, ry = sg[1], sg[2], sg[3]
		rig.lens[i] = len
		local key = "S" .. i
		-- 등 (짙은 타원체)과 배 (옅은 타원체가 아래로 비친다): 마디가 서로 겹쳐 매끈한 몸이 된다
		add(key, Vector3.new(rx * 2, ry * 2, len * 2.4), CFrame.new(0, 0, 0), back, skinMat, skinA, "ball")
		add(key, Vector3.new(rx * 1.8, ry * 1.4, len * 2.3), CFrame.new(0, -ry * 0.36, 0), belly, skinMat, skinA, "ball")
		-- 턱 아래 주름 (머리와 앞 두 마디)
		if i <= 3 and not wet then
			for g = -3, 3 do
				local x = g * rx * 0.16
				add(key, Vector3.new(0.1, 0.1, len * 1.5), CFrame.new(x, -ry * 1.0 + math.abs(g) * 0.12, 0), groove, Enum.Material.SmoothPlastic)
			end
		end
	end
	-- 머리: 넓적한 주둥이, 아래턱, 입선, 눈, 숨구멍, 혹, 따개비
	local h1 = SEGS[1]
	add("S1", Vector3.new(h1[2] * 1.8, h1[3] * 1.35, 3.6), CFrame.new(0, -0.25, -h1[1] * 0.62), back, skinMat, skinA, "ball")
	add("S1", Vector3.new(h1[2] * 1.9, h1[3] * 0.9, h1[1] * 1.55), CFrame.new(0, -h1[3] * 0.62, -0.5), belly, skinMat, skinA, "ball")
	if not wet then
		for _, x in ipairs({ -1, 1 }) do
			-- 입선: 주둥이 끝에서 눈 아래까지 아래로 휘다가 끝이 들린다
			add("S1", Vector3.new(0.12, 0.12, 3.4), CFrame.new(x * h1[2] * 0.9, -h1[3] * 0.32, -1.6) * CFrame.Angles(math.rad(-4), x * math.rad(-6), 0), EYE)
			add("S1", Vector3.new(0.12, 0.12, 2.0), CFrame.new(x * h1[2] * 0.97, -h1[3] * 0.4, 1.0) * CFrame.Angles(math.rad(12), x * math.rad(-10), 0), EYE)
		end
		-- 머리 위의 혹 (주둥이를 따라 세 줄)
		for k = 0, 4 do
			for _, x in ipairs({ -0.35, 0, 0.35 }) do
				if not (x == 0 and k % 2 == 1) then
					add("S1", Vector3.new(0.42, 0.34, 0.42), CFrame.new(x * h1[2], h1[3] * 0.62 - k * 0.07, -2.6 + k * 0.9), back2, Enum.Material.SmoothPlastic, 0, "ball")
				end
			end
		end
		-- 따개비 무리 (턱 끝, 머리 옆)
		local clusters = { Vector3.new(0.6, -h1[3] * 0.95, -2.8), Vector3.new(-1.2, -h1[3] * 0.85, -1.6), Vector3.new(1.9, 0.6, -0.8), Vector3.new(-1.7, 0.9, 0.4) }
		for ci, at in ipairs(clusters) do
			for b = 0, 3 do
				local a = b * 1.9 + ci
				add("S1", Vector3.new(0.34, 0.26, 0.34) * (1 - b * 0.12), CFrame.new(at + Vector3.new(math.cos(a) * 0.32, b * 0.03, math.sin(a) * 0.32)), BARNACLE, Enum.Material.Slate, 0, "ball")
			end
		end
	end
	local s2 = SEGS[2]
	for _, x in ipairs({ -1, 1 }) do
		-- 눈: 둘째 마디 앞쪽 옆, 깊고 오래된 눈 (작은 빛)
		add("S2", Vector3.new(0.62, 0.55, 0.62), CFrame.new(x * s2[2] * 0.93, -s2[3] * 0.18, -s2[1] * 0.45), wet and Color3.new(1, 1, 1) or EYE, wet and Enum.Material.Neon or Enum.Material.SmoothPlastic, 0, "ball")
		if not wet then
			local pupil = add("S2", Vector3.new(0.3, 0.3, 0.3), CFrame.new(x * s2[2] * 0.99, -s2[3] * 0.12, -s2[1] * 0.5), RUNE, Enum.Material.Neon, 0, "ball")
			local glow = Instance.new("PointLight")
			glow.Color = RUNE
			glow.Range = 10 * S
			glow.Brightness = 2
			glow.Parent = pupil
			add("S2", Vector3.new(0.9, 0.18, 0.5), CFrame.new(x * s2[2] * 0.9, -s2[3] * 0.02, -s2[1] * 0.45) * CFrame.Angles(0, 0, x * math.rad(-12)), back2)
		end
	end
	if not wet then
		-- 숨구멍 둘
		for _, x in ipairs({ -1, 1 }) do
			add("S2", Vector3.new(0.18, 0.1, 0.7), CFrame.new(x * 0.28, s2[3] * 0.99, -s2[1] * 0.3) * CFrame.Angles(0, x * math.rad(12), 0), EYE)
		end
		-- 등의 옛 무늬: 마디마다 짧은 획 셋 (옅게 빛난다), 머리 위의 둥근 문양
		for i = 2, 6 do
			local sg = SEGS[i]
			for j = -1, 1 do
				local p = add("S" .. i, Vector3.new(0.14, 0.08, sg[1] * 0.55), CFrame.new(j * sg[2] * 0.32, sg[3] * 0.985 - math.abs(j) * 0.18, (j % 2) * 0.3) * CFrame.Angles(0, j * 0.35 + (i % 2) * 0.2, j * 0.2), RUNE, Enum.Material.Neon, 0.35)
				local _ = p
			end
		end
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			add("S1", Vector3.new(0.12, 0.08, 0.55), CFrame.new(math.cos(a) * 0.9, h1[3] * 0.98, 0.6 + math.sin(a) * 0.9) * CFrame.Angles(0, -a, 0), RUNE, Enum.Material.Neon, 0.4)
		end
		-- 오래된 흉터 (옆구리에 비스듬한 흰 줄)
		for k = 0, 3 do
			local sg = SEGS[3 + k % 2]
			local x = (k % 2 == 0) and 1 or -1
			add("S" .. (3 + k % 2), Vector3.new(0.1, 0.1, 2.0 - k * 0.3), CFrame.new(x * sg[2] * 0.97, (k - 1.5) * 0.45, k * 0.3) * CFrame.Angles(math.rad(25 - k * 10), x * math.rad(-8), 0), SCAR)
		end
	end
	if not wet then
		-- 따개비 무리 하나 (부위 기준 자리)
		local function barnacles(key: string, at: Vector3, n: number, k0: number)
			for b = 0, n - 1 do
				local a = b * 1.9 + k0
				add(key, Vector3.new(0.34, 0.26, 0.34) * (1 - b * 0.1), CFrame.new(at + Vector3.new(math.cos(a) * 0.34, b * 0.03, math.sin(a) * 0.34)), BARNACLE, Enum.Material.Slate, 0, "ball")
			end
		end
		-- 등뼈를 따라 솟은 뼈 판 (화석처럼 바랜 상아빛, 꼬리로 갈수록 작아진다)
		for i = 2, 8 do
			local sg = SEGS[i]
			local h = 0.5 + (sg[3] / 3.6) * 0.9
			for j = 0, 1 do
				local z = (j - 0.5) * sg[1] * 0.7
				add("S" .. i, Vector3.new(0.22, h, sg[1] * 0.42), CFrame.new(0, sg[3] * 0.96 + h * 0.3, z) * CFrame.Angles(math.rad(-18), 0, 0), BONE, Enum.Material.Marble, 0, "wedge")
			end
		end
		-- 이끼와 산호 (등과 옆구리에 군데군데)
		for i = 2, 6 do
			local sg = SEGS[i]
			for k = 0, 2 do
				local a = (k - 1) * 0.75 + (i % 2) * 0.3
				local at = Vector3.new(math.sin(a) * sg[2] * 0.92, math.cos(a) * sg[3] * 0.92, (k - 1) * sg[1] * 0.35)
				add("S" .. i, Vector3.new(1.3, 0.3, 1.1) * (0.8 + (k % 2) * 0.4), CFrame.new(at) * CFrame.Angles(0, 0, -a), MOSS, Enum.Material.Grass, 0, "ball")
			end
			if i % 2 == 0 then
				local x = (i % 4 == 0) and 1 or -1
				local base = Vector3.new(x * sg[2] * 0.7, sg[3] * 0.72, 0.4)
				for b = 0, 3 do
					add("S" .. i, Vector3.new(0.16, 0.9 - b * 0.12, 0.16), CFrame.new(base) * CFrame.Angles(math.rad(-20 + b * 15), 0, x * math.rad(25 - b * 18)) * CFrame.new(0, 0.4, 0), CORAL, Enum.Material.Slate)
				end
			end
			barnacles("S" .. i, Vector3.new(((i % 2 == 0) and 1 or -1) * sg[2] * 0.9, -sg[3] * 0.25, -0.4), 4, i)
		end
		-- 등에 박힌 채 삭아 버린 옛 작살 셋 (부러진 자루, 녹슨 촉, 감긴 밧줄)
		for k, spec in ipairs({ { 3, -0.6, 1.6, 0.9 }, { 4, 0.8, 1.1, 2.4 }, { 5, -0.3, -0.5, 1.7 } }) do
			local sg = SEGS[spec[1]]
			local key = "S" .. spec[1]
			local base = Vector3.new(spec[2], sg[3] * 0.9, spec[3])
			local tilt = CFrame.new(base) * CFrame.Angles(math.rad(-30 - k * 8), math.rad(k * 40), math.rad(spec[2] * 20))
			add(key, Vector3.new(0.22, spec[4], 0.22), tilt * CFrame.new(0, spec[4] / 2, 0), WOOD, Enum.Material.Wood)
			add(key, Vector3.new(0.3, 0.5, 0.3), tilt * CFrame.new(0, -0.05, 0), RUST, Enum.Material.CorrodedMetal)
			add(key, Vector3.new(0.3, 0.12, 0.3), tilt * CFrame.new(0, spec[4] * 0.55, 0), Color3.fromRGB(150, 130, 96), Enum.Material.Fabric, 0, "cyl")
			add(key, Vector3.new(0.06, 1.6, 0.06), tilt * CFrame.new(0.1, spec[4] * 0.55, 0) * CFrame.Angles(0, 0, math.rad(150)) * CFrame.new(0, -0.8, 0), Color3.fromRGB(150, 130, 96), Enum.Material.Fabric)
		end
		-- 턱 아래와 가슴지느러미 뿌리의 해초: 아래로 늘어지면 다리처럼 보여, 몸을 따라 뒤로 흩날리게 눕힌다
		for k = 0, 6 do
			local x = (k - 3) * 0.55
			local len = 2.0 + (k % 3) * 0.8
			add("S1", Vector3.new(0.14, len, 0.1), CFrame.new(x, -h1[3] * 0.9, -1.8 + (k % 2) * 0.8) * CFrame.Angles(math.rad(-74), 0, math.rad((k - 3) * 3)) * CFrame.new(0, -len / 2, 0), KELP, Enum.Material.Grass)
		end
		for _, x in ipairs({ -1, 1 }) do
			for k = 0, 2 do
				local len = 2.2 + k * 0.7
				add("S2", Vector3.new(0.12, len, 0.1), CFrame.new(x * s2[2] * 0.8, -s2[3] * 0.62, 0.6 + k * 0.5) * CFrame.Angles(math.rad(-70), 0, x * math.rad(8)) * CFrame.new(0, -len / 2, 0), KELP, Enum.Material.Grass)
			end
		end
		-- 옆구리의 옛 봉인 고리 (빛나는 점이 둥글게, 가운데 큰 점)
		for _, i in ipairs({ 3, 4 }) do
			local sg = SEGS[i]
			for _, x in ipairs({ -1, 1 }) do
				local c0 = Vector3.new(x * sg[2] * 0.985, sg[3] * 0.1, 0)
				for k = 0, 11 do
					local a = k / 12 * math.pi * 2
					add("S" .. i, Vector3.new(0.18, 0.18, 0.18), CFrame.new(c0 + Vector3.new(0, math.sin(a) * 1.1, math.cos(a) * 1.1)), RUNE, Enum.Material.Neon, 0.15, "ball")
				end
				add("S" .. i, Vector3.new(0.4, 0.4, 0.4), CFrame.new(c0), RUNE, Enum.Material.Neon, 0.1, "ball")
			end
		end
		-- 머리 옆과 가슴지느러미 앞 가장자리에도 따개비
		barnacles("S2", Vector3.new(s2[2] * 0.85, s2[3] * 0.5, 0.8), 5, 2)
		barnacles("S2", Vector3.new(-s2[2] * 0.8, s2[3] * 0.4, 1.4), 4, 5)
	end
	-- 등지느러미 (작은 혹 지느러미)와 꼬리 쪽 등의 마디 혹
	local s6 = SEGS[6]
	tri("S6", Vector3.new(0, s6[3] * 0.9, -1.2), Vector3.new(0, s6[3] * 0.9, 1.0), Vector3.new(0, s6[3] * 0.9 + 1.3, 0.9), back, skinMat, skinA, 0.35)
	for i = 7, 8 do
		local sg = SEGS[i]
		add("S" .. i, Vector3.new(0.4, 0.35, 0.6), CFrame.new(0, sg[3] * 0.95, 0), back2, skinMat, skinA, "ball")
	end

	-- 가슴지느러미 (긴 날개 같은 지느러미): 윗면은 짙게, 아랫면은 희게, 앞 가장자리에 혹
	for _, x in ipairs({ -1, 1 }) do
		local key = x > 0 and "FR" or "FL"
		local Lf = 11
		local lead, trail = {}, {}
		local n = 6
		for k = 0, n do
			local u = k / n
			local w = 3.0 * (1 - u) ^ 0.7 + 0.45
			local zc = 0.9 * u
			lead[k] = Vector3.new(x * Lf * u, 0, zc - w * 0.42)
			trail[k] = Vector3.new(x * Lf * u, 0, zc + w * 0.58)
		end
		for k = 0, n - 1 do
			for _, layer in ipairs({ { 0.07, back }, { -0.07, wet and belly or Color3.fromRGB(226, 230, 228) } }) do
				local dy = Vector3.new(0, layer[1], 0)
				tri(key, lead[k] + dy, lead[k + 1] + dy, trail[k] + dy, layer[2], skinMat, skinA, 0.12)
				tri(key, lead[k + 1] + dy, trail[k + 1] + dy, trail[k] + dy, layer[2], skinMat, skinA, 0.12)
			end
			if not wet then
				add(key, Vector3.new(0.5, 0.36, 0.5), CFrame.new(lead[k] + Vector3.new(0, 0, 0.05)), back2, Enum.Material.SmoothPlastic, 0, "ball")
			end
		end
		add(key, Vector3.new(0.8, 0.8, 1.6), CFrame.new(0, 0, 0.1), back, skinMat, skinA, "ball")
		rig.fin[key] = CFrame.new(x * s2[2] * 0.78, -s2[3] * 0.55, 0.3) * CFrame.Angles(0, x * math.rad(-28), x * math.rad(-32))
	end

	-- 꼬리지느러미: 가운데가 파인 넓은 두 날개, 뒤 가장자리는 톱니처럼
	local root = Vector3.new(0, 0, 0.4)
	for _, x in ipairs({ -1, 1 }) do
		local pts = {
			Vector3.new(x * 0.4, 0, -0.1), Vector3.new(x * 1.6, 0, 0.1), Vector3.new(x * 3.3, 0, 0.6), Vector3.new(x * 4.9, 0, 1.3), Vector3.new(x * 6.3, 0, 2.3),
			Vector3.new(x * 5.2, 0, 2.55), Vector3.new(x * 3.8, 0, 2.2), Vector3.new(x * 2.5, 0, 2.05), Vector3.new(x * 1.2, 0, 1.75), Vector3.new(0, 0, 1.5),
		}
		for j = 1, #pts - 1 do
			for _, layer in ipairs({ { 0.06, back }, { -0.06, wet and belly or Color3.fromRGB(210, 214, 214) } }) do
				local dy = Vector3.new(0, layer[1], 0)
				tri("FK", root + dy, pts[j] + dy, pts[j + 1] + dy, layer[2], skinMat, skinA, 0.12)
			end
		end
	end
	return rig
end

-- 몸을 놓는다. cf = 머리 마디 가운데 (앞이 -Z). flex = 꼬리 흔들림, arch = 마디마다 위아래로 굽는 정도 (라디안), fin = 지느러미 젓기
function Whale.place(rig: Rig, cf: CFrame, t: number, flex: number?, arch: number?, fin: number?)
	local S = rig.S
	local fx = flex or 0.35
	local ar = arch or 0
	local frames: { [string]: CFrame } = {}
	local cur = cf
	local n = #rig.lens
	for i = 1, n do
		if i > 1 then
			local u = (i - 1) / (n - 1)
			local bend = fx * math.sin(t * 2.4 - i * 0.65) * u ^ 1.4 * 0.32 + ar
			cur = cur * CFrame.new(0, 0, rig.lens[i - 1] * 0.5 * S) * CFrame.Angles(bend, 0, 0) * CFrame.new(0, 0, rig.lens[i] * 0.5 * S)
		end
		frames["S" .. i] = cur
	end
	local last = frames["S" .. n]
	local beat = fx * math.sin(t * 2.4 - (n + 1) * 0.65) * 0.4
	frames.FK = last * CFrame.new(0, 0, rig.lens[n] * 0.45 * S) * CFrame.Angles(beat + ar, 0, 0)
	local fl = (fin or 0.2) * math.sin(t * 1.6)
	local s2 = frames.S2
	for key, base in pairs(rig.fin) do
		local x = key == "FR" and 1 or -1
		frames[key] = s2 * CFrame.new(base.Position * S) * base.Rotation * CFrame.Angles(0, 0, x * fl)
	end
	for _, pc in ipairs(rig.pieces) do
		pc.p.CFrame = (frames[pc.key] or cf) * pc.off
	end
end

function Whale.fade(rig: Rig, time: number)
	if not rig.alive then
		return
	end
	rig.alive = false
	for _, pc in ipairs(rig.pieces) do
		TweenService:Create(pc.p, TweenInfo.new(time), { Transparency = 1 }):Play()
	end
	task.delay(time + 0.05, function()
		for _, pc in ipairs(rig.pieces) do
			pc.p:Destroy()
		end
	end)
end

------------------------------------------------------------------------
-- 기술 연출 (초·창해신권 · 진 창해신권 고래강림)
------------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))
local player = Players.LocalPlayer
local opts: any = {}
function Whale.init(o: any)
	opts = o or {}
end
local WHITE = Color3.new(1, 1, 1)
local FOAM = Color3.fromRGB(236, 250, 255)
local DEEP = Color3.fromRGB(18, 60, 110)
local UP = CFrame.Angles(0, 0, math.rad(90))
local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(math.max(0.01, time), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function fadeOut(p: BasePart, time: number, goal: { [string]: any }?)
	local g = goal or {}
	g.Transparency = 1
	tween(p, time, g)
	task.delay(time + 0.05, function()
		p:Destroy()
	end)
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
end
local function rootOf(m: Instance?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 1e-3 and f.Unit or Vector3.new(0, 0, -1)
end
local function ground(at: Vector3): Vector3
	return Vector3.new(at.X, at.Y - 2.7, at.Z)
end
local function colors(id: any): (Color3, Color3)
	local st = type(id) == "string" and Config.STYLE_BY_ID[id] or nil
	if st then
		return st.color, st.color2
	end
	return Color3.fromRGB(40, 150, 200), FOAM
end
local function shakeNear(pos: Vector3, amount: number, range: number)
	if opts.shake and near(pos, range) then
		opts.shake(amount)
	end
end
local function disc(at: Vector3, d: number, color: Color3, alpha: number, mat: Enum.Material?): BasePart
	local p = newPart(Vector3.new(0.3, d, d), color, mat or Enum.Material.Glass, alpha, "cyl")
	p.CFrame = CFrame.new(at) * UP
	return p
end
-- 물방울: 떨어지며 사라진다
local function droplet(at: Vector3, color: Color3, size: number, fall: number, life: number)
	local p = newPart(Vector3.new(size, size, size), color, Enum.Material.Glass, 0.2, "ball")
	p.CFrame = CFrame.new(at)
	fadeOut(p, life, { CFrame = CFrame.new(at - Vector3.new(0, fall, 0) + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * size * 3), Size = Vector3.new(size, size * 2.2, size) * 0.6 })
end
-- 솟는 물기둥 (위로 솟았다가 흩어진다)
local function column(at: Vector3, h: number, w: number, color: Color3, life: number)
	local g = ground(at)
	local c = newPart(Vector3.new(2, w, w), color, Enum.Material.Glass, 0.15, "cyl")
	c.CFrame = CFrame.new(g + Vector3.new(0, 1, 0)) * UP
	tween(c, life * 0.35, { Size = Vector3.new(h, w, w), CFrame = CFrame.new(g + Vector3.new(0, h / 2, 0)) * UP }, Enum.EasingStyle.Quad)
	local cap = newPart(Vector3.new(w * 1.3, w * 0.7, w * 1.3), FOAM, Enum.Material.SmoothPlastic, 0.25, "ball")
	cap.CFrame = CFrame.new(g)
	tween(cap, life * 0.35, { CFrame = CFrame.new(g + Vector3.new(0, h, 0)) })
	task.delay(life * 0.35, function()
		fadeOut(c, life * 0.65, { Size = Vector3.new(h * 0.6, w * 1.6, w * 1.6), CFrame = CFrame.new(g + Vector3.new(0, h * 0.3, 0)) * UP })
		fadeOut(cap, life * 0.5, { Size = cap.Size * 2 })
		for _ = 1, 8 do
			droplet(g + Vector3.new((math.random() - 0.5) * w, h * (0.6 + math.random() * 0.4), (math.random() - 0.5) * w), FOAM, 0.6 + math.random() * 0.6, h * 0.8, 0.8)
		end
	end)
end

-- 고래를 포물선으로 날린다 (솟구쳐 올랐다 떨어진다). 머리는 가는 쪽을 본다
local function flyWhale(rig: Rig, from: Vector3, to: Vector3, flight: number, H: number, sink: number, c2: Color3, onLand: () -> ())
	local t0 = os.clock()
	local dir = flat(to - from)
	local shadow = disc(ground(from) + Vector3.new(0, 0.2, 0), rig.S * 10, Color3.new(0, 0, 0), 0.75, Enum.Material.SmoothPlastic)
	local function posAt(u: number): Vector3
		return from:Lerp(to, u) + Vector3.new(0, 4 * H * u * (1 - u) - sink * (1 - 4 * u * (1 - u)), 0)
	end
	local landed = false
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp(t / flight, 0, 1)
		local pos = posAt(u)
		local nxt = posAt(math.min(1, u + 0.02))
		local look = (nxt - pos).Magnitude > 1e-3 and (nxt - pos).Unit or dir
		-- 오를 때는 꼬리를 아래로 휘고, 꼭대기에서 곧게, 떨어질 때는 몸을 감아 머리부터 들어간다
		local arch = 0.05 * math.cos(u * math.pi)
		local roll = math.sin(u * math.pi) * 0.25
		Whale.place(rig, CFrame.lookAt(pos, pos + look) * CFrame.Angles(0, 0, roll), t, 0.28, arch, 0.35)
		shadow.CFrame = CFrame.new(ground(Vector3.new(pos.X, from.Y, pos.Z)) + Vector3.new(0, 0.2, 0)) * UP
		shadow.Transparency = 0.6 + 0.3 * math.sin(u * math.pi)
		-- 몸에서 쏟아지는 물
		if rig.alive and math.random() < 0.85 then
			local seg = rig.pieces[math.random(1, #rig.pieces)].p
			droplet(seg.CFrame.Position, math.random() < 0.5 and FOAM or c2, (0.5 + math.random() * 0.7) * rig.S * 0.6, 10 * rig.S, 0.9)
		end
		if u >= 1 and not landed then
			landed = true
			conn:Disconnect()
			fadeOut(shadow, 0.3)
			onLand()
		end
	end)
end

------------------------------------------------------------------------
-- 진 창해 고래강림: 물로 된 고래 (같은 생김새, 유리 같은 물빛)
------------------------------------------------------------------------
local function whaleBreach(data: any)
	local from: Vector3 = data.from
	local to: Vector3 = data.to
	if not near(from, 260) then
		return
	end
	local c, c2 = colors(data.style)
	local delay = data.delay or 0.35
	local flight = data.flight or 1.3
	local g0, g1 = ground(from), ground(to)
	local pool = disc(g0 + Vector3.new(0, 0.1, 0), 2, c, 0.25)
	tween(pool, delay, { Size = Vector3.new(0.3, 26, 26) })
	task.delay(delay, function()
		local rig = Whale.build(1.15, true, c, c2)
		column(from, 18, 10, c2, 0.9)
		Fx.ring(g0 + Vector3.new(0, 0.3, 0), FOAM, 4, 34, 0.6)
		Fx.sound("splash", 1, 0.6, g0)
		shakeNear(g0, 1.2, 100)
		flyWhale(rig, g0 + Vector3.new(0, 2, 0), g1 + Vector3.new(0, 2, 0), flight, 34, 10, c2, function()
			Whale.fade(rig, 0.35)
			fadeOut(pool, 0.4)
			for k = 0, 3 do
				task.delay(k * 0.07, function()
					Fx.ring(g1 + Vector3.new(0, 0.4, 0), k % 2 == 0 and c or c2, 4, (data.radius or 20) * 2.2 + k * 8, 0.7)
				end)
			end
			column(to, 26, 18, c2, 1.0)
			Fx.flash(g1, c, 80, 6, 0.6)
			Fx.sound("splash", 1, 0.4, g1)
			Fx.sound("heavy", 1, 0.4, g1)
			shakeNear(g1, 2.4, 140)
		end)
	end)
end

------------------------------------------------------------------------
-- 초·창해 조류창 · 소용돌이
------------------------------------------------------------------------
local function vortex(at: Vector3, R: number, dur: number, c: Color3, c2: Color3)
	local g = ground(at)
	local rings: { BasePart } = {}
	for k = 1, 5 do
		local d = R * 2 * (1 - (k - 1) * 0.17)
		local r = disc(g + Vector3.new(0, 0.2 + k * 0.05, 0), d, k % 2 == 0 and c or c2, 0.45 + k * 0.05)
		rings[k] = r
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > dur then
			conn:Disconnect()
			for _, r in ipairs(rings) do
				fadeOut(r, 0.3)
			end
			return
		end
		for k, r in ipairs(rings) do
			r.CFrame = CFrame.new(g + Vector3.new(0, 0.2 + k * 0.05 - k * 0.12 * math.min(1, t * 3), 0)) * CFrame.Angles(0, t * (3 + k), 0) * UP
		end
		-- 안으로 말려드는 물줄기
		if math.random() < 0.6 then
			local a = math.random() * math.pi * 2
			local p0 = g + Vector3.new(math.cos(a) * R, 0.6, math.sin(a) * R)
			local s = newPart(Vector3.new(0.3, 0.3, 2.4), FOAM, Enum.Material.Glass, 0.2)
			s.CFrame = CFrame.lookAt(p0, g + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, math.rad(60), 0)
			fadeOut(s, 0.45, { CFrame = CFrame.lookAt(g + Vector3.new(0, 0.4, 0), g) })
		end
	end)
	task.delay(dur, function()
		column(at, 16, 7, c2, 0.8)
		Fx.sound("splash", 0.9, 0.9, at)
		shakeNear(at, 0.8, 80)
	end)
end
local function tideSpear(data: any)
	local from: Vector3, to: Vector3 = data.from, data.to
	if not near(from, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local delay, travel = data.delay or 0.18, data.travel or 0.3
	local dir = (to - from).Unit
	local spear = newPart(Vector3.new(0.5, 0.5, 5), c2, Enum.Material.Glass, 0.1)
	local tip = newPart(Vector3.new(0.9, 0.9, 0.9), FOAM, Enum.Material.SmoothPlastic, 0.1, "ball")
	local strands: { BasePart } = {}
	for k = 1, 2 do
		strands[k] = newPart(Vector3.new(0.25, 0.25, 3.2), k == 1 and c or FOAM, Enum.Material.Glass, 0.2)
	end
	spear.Transparency = 1
	task.delay(delay, function()
		spear.Transparency = 0.1
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local t = os.clock() - t0
			local u = math.clamp(t / travel, 0, 1)
			local pos = from:Lerp(to, u)
			local cf = CFrame.lookAt(pos, pos + dir)
			spear.CFrame = cf
			tip.CFrame = cf * CFrame.new(0, 0, -2.6)
			for k, sp in ipairs(strands) do
				local a = t * 26 + k * math.pi
				sp.CFrame = cf * CFrame.new(math.cos(a) * 0.8, math.sin(a) * 0.8, 0.6)
			end
			if math.random() < 0.7 then
				droplet(pos + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5), FOAM, 0.4, 2, 0.4)
			end
			if u >= 1 then
				conn:Disconnect()
				fadeOut(spear, 0.15)
				fadeOut(tip, 0.15)
				for _, sp in ipairs(strands) do
					fadeOut(sp, 0.15)
				end
				Fx.ring(ground(to) + Vector3.new(0, 0.3, 0), FOAM, 2, 16, 0.4)
				vortex(to, data.radius or 9, data.vortex or 1.2, c, c2)
			end
		end)
		Fx.sound("splash", 0.6, 1.4, from)
	end)
end

------------------------------------------------------------------------
-- 초·창해 경음: 둘레를 헤엄치는 고래의 넋과 퍼지는 물의 고리 셋
------------------------------------------------------------------------
local function whaleSong(data: any)
	local at: Vector3 = data.at
	if not near(at, 220) then
		return
	end
	local c, c2 = colors(data.style)
	local g = ground(at)
	local R = data.radius or 24
	local rings, gap, delay = data.rings or 3, data.gap or 0.28, data.delay or 0.25
	-- 고래의 넋: 작은 물빛 고래가 둘레를 한 바퀴 헤엄친다
	local rig = Whale.build(0.42, true, c, c2)
	for _, pc in ipairs(rig.pieces) do
		pc.p.Transparency = math.max(pc.p.Transparency, 0.45)
	end
	local t0 = os.clock()
	local life = delay + gap * rings + 0.5
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > life then
			conn:Disconnect()
			Whale.fade(rig, 0.3)
			return
		end
		local a = t / life * math.pi * 2
		local r = 9
		local pos = g + Vector3.new(math.cos(a) * r, 5 + math.sin(t * 3) * 0.6, math.sin(a) * r)
		local tan = Vector3.new(-math.sin(a), 0, math.cos(a))
		Whale.place(rig, CFrame.lookAt(pos, pos + tan) * CFrame.Angles(0, 0, math.rad(-20)), t * 1.6, 0.5, 0, 0.4)
	end)
	for k = 1, rings do
		task.delay(delay + (k - 1) * gap, function()
			local d = R * 2 * k / rings
			local ring = disc(g + Vector3.new(0, 0.25, 0), 2, c, 0.35)
			tween(ring, 0.35, { Size = Vector3.new(0.3, d, d) })
			task.delay(0.3, function()
				fadeOut(ring, 0.35)
			end)
			Fx.ring(g + Vector3.new(0, 0.35, 0), FOAM, 2, d, 0.45)
			-- 소리의 물결: 서 있는 고리가 바깥으로 퍼진다
			local wall = newPart(Vector3.new(3, 2, 2), c2, Enum.Material.ForceField, 0.2, "cyl")
			wall.CFrame = CFrame.new(g + Vector3.new(0, 1.5, 0)) * UP
			fadeOut(wall, 0.4, { Size = Vector3.new(3, d, d) })
			Fx.sound("deflect", 0.5, 0.45 + k * 0.08, at)
			shakeNear(at, 0.3, 60)
		end)
	end
end

------------------------------------------------------------------------
-- 초·창해 만경창파: 둘레가 바다가 되고, 사방의 파도 넷, 가운데의 소용돌이
------------------------------------------------------------------------
local function waveWall(center: Vector3, from: Vector3, R: number, travel: number, c: Color3, c2: Color3)
	local g = ground(center)
	local side = Vector3.new(-from.Z, 0, from.X)
	local n = 9
	local segs: { BasePart } = {}
	local crests: { BasePart } = {}
	for i = 1, n do
		segs[i] = newPart(Vector3.new(R * 0.24, 1, 2.6), c, Enum.Material.Glass, 0.2)
		crests[i] = newPart(Vector3.new(R * 0.25, 1.2, 1.6), FOAM, Enum.Material.SmoothPlastic, 0.2)
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / travel, 0, 1)
		local dist = R * (1 - u)
		local h = 3 + 9 * math.sin(u * math.pi * 0.85 + 0.25)
		for i = 1, n do
			local x = (i - (n + 1) / 2) / n * R * 2.1 * (0.3 + 0.7 * (1 - u))
			-- 활처럼 휜 파도 (가운데가 먼저 온다)
			local bend = (x / R) ^ 2 * R * 0.25
			local p0 = g + from * (dist + bend) + side * x
			local cf = CFrame.lookAt(p0, p0 - from)
			segs[i].Size = Vector3.new(R * 0.25, h, 2.6)
			segs[i].CFrame = cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(math.rad(-12), 0, 0)
			crests[i].CFrame = cf * CFrame.new(0, h, -1.2) * CFrame.Angles(math.rad(-35), 0, 0)
		end
		if math.random() < 0.6 then
			droplet(g + from * dist + side * (math.random() - 0.5) * R * 1.5 + Vector3.new(0, h, 0), FOAM, 0.7, h, 0.6)
		end
		if u >= 1 then
			conn:Disconnect()
			for i = 1, n do
				fadeOut(segs[i], 0.25, { Size = Vector3.new(R * 0.25, 1, 4) })
				fadeOut(crests[i], 0.25)
			end
			Fx.ring(g + Vector3.new(0, 0.4, 0), FOAM, 2, 14, 0.35)
			Fx.sound("splash", 0.7, 0.8, center)
		end
	end)
end
local function fourWaves(data: any)
	local at: Vector3 = data.at
	if not near(at, 240) then
		return
	end
	local c, c2 = colors(data.style)
	local g = ground(at)
	local R = data.radius or 26
	local look = flat(data.dir or Vector3.new(0, 0, -1))
	local right = Vector3.new(-look.Z, 0, look.X)
	local dirs = { look, right, -look, -right }
	local delay, travel, gap = data.delay or 0.4, data.travel or 0.8, data.gap or 0.25
	local waves = data.waves or 4
	local sea = disc(g + Vector3.new(0, 0.15, 0), 4, c, 0.3)
	tween(sea, delay, { Size = Vector3.new(0.3, R * 2.2, R * 2.2) })
	local life = delay + (waves - 1) * gap + travel + 1.2
	task.delay(life, function()
		fadeOut(sea, 0.6)
	end)
	for w = 1, waves do
		task.delay(delay + (w - 1) * gap, function()
			waveWall(at, dirs[(w - 1) % 4 + 1], R, travel, c, c2)
		end)
	end
	Fx.sound("splash", 0.8, 0.6, at)
end
local function maelstrom(data: any)
	local at: Vector3 = data.at
	if not near(at, 240) then
		return
	end
	local c, c2 = colors(data.style)
	local R = data.radius or 16
	vortex(at, R, 0.7, c, c2)
	-- 깔때기: 아래로 좁아지는 고리가 돌며 가라앉는다
	local g = ground(at)
	for k = 0, 5 do
		local ring = newPart(Vector3.new(0.6, R * 2 * (1 - k * 0.14), R * 2 * (1 - k * 0.14)), k % 2 == 0 and c or FOAM, Enum.Material.Glass, 0.4, "cyl")
		ring.CFrame = CFrame.new(g + Vector3.new(0, 6 - k * 1.2, 0)) * UP
		fadeOut(ring, 0.9, { CFrame = CFrame.new(g + Vector3.new(0, -2, 0)) * CFrame.Angles(0, math.rad(180), 0) * UP })
	end
	task.delay(0.65, function()
		column(at, 34, 12, c2, 1.1)
		Fx.flash(at, c, 80, 5, 0.5)
		Fx.sound("heavy", 1, 0.5, at)
		shakeNear(at, 1.8, 120)
	end)
end

------------------------------------------------------------------------
-- 초 오의 고경승천: 바다 · 솟구치는 고대의 고래 · 떨어지는 자리의 해일
------------------------------------------------------------------------
type Ancient = { rig: Rig, sea: BasePart, deep: BasePart?, light: PointLight?, cc: ColorCorrectionEffect?, rising: boolean }
local ancients: { [number]: Ancient } = {}
local function ancientSea(data: any)
	local at: Vector3 = data.at
	if not near(at, 320) then
		return
	end
	local _, c2 = colors(data.style)
	local g = ground(at)
	local from: Vector3 = data.from or at
	local cut = data.cut or 1.4
	local sea = disc(g + Vector3.new(0, 0.2, 0), 6, DEEP, 0.2)
	tween(sea, 0.8, { Size = Vector3.new(0.3, 150, 150) })
	for k = 0, 2 do
		task.delay(k * 0.25, function()
			Fx.ring(g + Vector3.new(0, 0.4, 0), FOAM, 6, 150 - k * 20, 0.9)
		end)
	end
	-- 하늘이 어두워진다 (가까운 사람만)
	local cc: ColorCorrectionEffect? = nil
	if near(at, 200) then
		local e = Instance.new("ColorCorrectionEffect")
		e.Name = "KwonAncientSea"
		e.Parent = game:GetService("Lighting")
		tween(e, 0.6, { TintColor = Color3.fromRGB(150, 190, 230), Brightness = -0.12, Contrast = 0.15 })
		cc = e
	end
	-- 바다 밑의 고래: 물속에서 천천히 떠오르며 눈과 옛 무늬가 빛난다
	local rig = Whale.build(3.0, false)
	local dir = flat(data.dir or Vector3.new(0, 0, -1))
	local g0 = ground(from)
	local A: Ancient = { rig = rig, sea = sea, cc = cc, rising = true }
	ancients[data.id or 0] = A
	local deep = disc(g0 + Vector3.new(0, 0.3, 0), 50, Color3.fromRGB(10, 30, 60), 0.4, Enum.Material.SmoothPlastic)
	A.deep = deep
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(120, 230, 255)
	glow.Range = 60
	glow.Brightness = 0
	glow.Parent = deep
	tween(glow, cut, { Brightness = 3 })
	A.light = glow
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if not A.rising or t > cut + 1 then
			conn:Disconnect()
			return
		end
		-- 머리를 위로 비스듬히 든 채 물속에서 떠오른다
		local depth = 40 - 22 * math.clamp(t / cut, 0, 1)
		local pos = g0 - Vector3.new(0, depth, 0) - dir * 20
		Whale.place(rig, CFrame.lookAt(pos, pos + dir + Vector3.new(0, 0.8, 0)), t, 0.3, 0.02, 0.3)
	end)
	Fx.sound("splash", 1, 0.35, at)
	shakeNear(at, 0.8, 160)
	local _ = c2
	task.delay((data.dur or 4.6) + 1.5, function()
		if ancients[data.id or 0] == A then
			ancients[data.id or 0] = nil
		end
		if sea.Parent then
			fadeOut(sea, 0.8)
		end
		if cc and cc.Parent then
			cc:Destroy()
		end
		if rig.alive then
			Whale.fade(rig, 0.5)
		end
	end)
end
local function ancientLeap(data: any)
	local from: Vector3, to: Vector3 = data.from, data.to
	if not near(from, 360) and not near(to, 360) then
		return
	end
	local _, c2 = colors(data.style)
	local A = ancients[data.id or 0]
	local rig = A and A.rig or Whale.build(data.scale or 3.0, false)
	if A then
		A.rising = false
		if A.deep then
			fadeOut(A.deep, 0.6)
		end
	end
	local g0, g1 = ground(from), ground(to)
	-- 바다를 찢고 솟구친다
	column(from, 60, 34, FOAM, 1.4)
	for k = 0, 3 do
		task.delay(k * 0.08, function()
			Fx.ring(g0 + Vector3.new(0, 0.5, 0), k % 2 == 0 and FOAM or c2, 8, 90 + k * 20, 1.0)
		end)
	end
	Fx.sound("splash", 1, 0.3, g0)
	Fx.sound("heavy", 1, 0.3, g0)
	shakeNear(g0, 2.2, 220)
	flyWhale(rig, g0 - Vector3.new(0, 4, 0), g1 - Vector3.new(0, 4, 0), data.flight or 2.4, data.height or 50, 24, c2, function()
		Whale.fade(rig, 0.6)
	end)
end
local function ancientCrash(data: any)
	local at: Vector3 = data.at
	if not near(at, 360) then
		return
	end
	local c, c2 = colors(data.style)
	local g1 = ground(at)
	local R = data.radius or 30
	column(at, 80, 46, FOAM, 1.6)
	for k = 0, 4 do
		task.delay(k * 0.09, function()
			Fx.ring(g1 + Vector3.new(0, 0.5, 0), k % 2 == 0 and c or FOAM, 10, R * 2.6 + k * 16, 1.0)
		end)
	end
	for _ = 1, 30 do
		droplet(g1 + Vector3.new((math.random() - 0.5) * R, 30 + math.random() * 40, (math.random() - 0.5) * R), math.random() < 0.5 and FOAM or c2, 1.2 + math.random() * 1.4, 40, 1.3)
	end
	Fx.flash(at, c2, 140, 8, 0.8)
	Fx.sound("splash", 1, 0.25, at)
	Fx.sound("heavy", 1, 0.3, at)
	shakeNear(at, 3.2, 260)
	-- 해일이 둘레로 되밀려 온다
	local center: Vector3 = data.center or at
	task.delay(data.waveAt or 0.4, function()
		local dir = flat(center - at)
		waveWall(center, -dir, data.waveRadius or 30, 0.6, c, c2)
		waveWall(center, Vector3.new(-dir.Z, 0, dir.X), (data.waveRadius or 30) * 0.8, 0.6, c, c2)
		waveWall(center, Vector3.new(dir.Z, 0, -dir.X), (data.waveRadius or 30) * 0.8, 0.6, c, c2)
	end)
	task.delay((data.waveAt or 0.4) + 1.0, function()
		local A = ancients[data.id or 0]
		if A then
			ancients[data.id or 0] = nil
			fadeOut(A.sea, 1.0)
			local e = A.cc
			if e and e.Parent then
				tween(e, 0.8, { TintColor = WHITE, Brightness = 0, Contrast = 0 })
				task.delay(0.85, function()
					e:Destroy()
				end)
			end
		end
	end)
end

-- 초 오의 컷씬 (쓴 사람 화면에서만): 몸을 낮게, 등 뒤의 바다를 올려다본다. 물속에서 고래의 눈이 빛난다
local cutActive = false
function Whale.superCut(model: Model, dur: number, name: string, shake: ((number) -> ())?)
	local cam = workspace.CurrentCamera
	local r = rootOf(model)
	if not cam or not r or cutActive then
		return
	end
	cutActive = true
	local pg = player:WaitForChild("PlayerGui")
	local g = Instance.new("ScreenGui")
	g.Name = "KwonWhaleCut"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 85
	g.Parent = pg
	local tintF = Instance.new("Frame")
	tintF.Size = UDim2.fromScale(1, 1)
	tintF.BackgroundColor3 = Color3.fromRGB(10, 40, 80)
	tintF.BackgroundTransparency = 1
	tintF.BorderSizePixel = 0
	tintF.Parent = g
	tween(tintF, 0.3, { BackgroundTransparency = 0.55 })
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
		tween(b, 0.15, { Size = UDim2.new(1, 0, 0.14, 0) })
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
	label.TextColor3 = FOAM
	label.TextStrokeColor3 = Color3.fromRGB(20, 90, 160)
	label.TextStrokeTransparency = 0.2
	label.TextTransparency = 1
	label.ZIndex = 6
	label.Parent = bars[2]
	tween(label, 0.25, { TextTransparency = 0 })
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
		RunService:UnbindFromRenderStep("KwonWhaleCut")
		cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
		cam.FieldOfView = oldFov
		cutActive = false
		for _, b in ipairs(bars) do
			tween(b, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
		end
		tween(tintF, 0.25, { BackgroundTransparency = 1 })
		tween(label, 0.2, { TextTransparency = 1 })
		task.delay(0.3, function()
			g:Destroy()
		end)
	end
	RunService:BindToRenderStep("KwonWhaleCut", Enum.RenderPriority.Camera.Value + 2, function()
		local t = os.clock() - t0
		local k = math.clamp(t / dur, 0, 1)
		-- 앞쪽 낮은 곳에서 나를 올려다보다가, 천천히 돌아 등 뒤의 바다를 비춘다
		local a = k * math.rad(70)
		local eye = focus + look * (10 - k * 4) * math.cos(a) + side * 10 * math.sin(a) + Vector3.new(0, 1.2 + k * 1.5, 0)
		local target = focus:Lerp(focus - look * 40 + Vector3.new(0, -4, 0), k * 0.85)
		cam.CFrame = CFrame.lookAt(eye, target)
		cam.FieldOfView = oldFov + k * 12
		if t >= dur then
			restore()
		end
	end)
	if shake then
		task.delay(dur * 0.6, function()
			shake(0.8)
		end)
	end
	task.delay(dur + 1, restore)
end

------------------------------------------------------------------------
-- 초·창해신권의 차림: 손목의 진주 고리, 목의 진주 목걸이, 등 뒤로 흐르는 물의 띠 둘
------------------------------------------------------------------------
local function attach(p: BasePart, to: BasePart, cf: CFrame, holder: Instance, list: { Instance })
	p.Massless = true
	p.Anchored = false
	p.CFrame = to.CFrame * cf
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = p
	w.Parent = p
	p.Parent = holder
	table.insert(list, p)
end
function Whale.buildGear(model: Model): { Instance }
	local out: { Instance } = {}
	local holder = Instance.new("Folder")
	holder.Name = "Pearl_" .. model.Name
	holder.Parent = folder
	table.insert(out, holder)
	local pearl = Color3.fromRGB(240, 244, 250)
	local gold = Color3.fromRGB(220, 200, 140)
	local st = Config.STYLE_BY_ID.chochanghae
	local c = st and st.color or Color3.fromRGB(40, 150, 200)
	for _, side in ipairs({ "Right", "Left" }) do
		local arm = model:FindFirstChild(side .. "LowerArm")
		if arm and arm:IsA("BasePart") then
			local sz = arm.Size
			-- 손목의 금 테 위에 진주 열둘
			attach(newPart(Vector3.new(sz.X + 0.18, 0.12, sz.Z + 0.18), gold, Enum.Material.Metal, 0), arm, CFrame.new(0, -sz.Y * 0.42, 0), holder, out)
			for k = 0, 11 do
				local a = k / 12 * math.pi * 2
				attach(newPart(Vector3.new(0.2, 0.2, 0.2), pearl, Enum.Material.SmoothPlastic, 0, "ball"), arm, CFrame.new(math.cos(a) * (sz.X / 2 + 0.12), -sz.Y * 0.34, math.sin(a) * (sz.Z / 2 + 0.12)), holder, out)
			end
			-- 큰 물방울 구슬 하나 (손등 쪽)
			attach(newPart(Vector3.new(0.36, 0.36, 0.36), c, Enum.Material.Glass, 0.1, "ball"), arm, CFrame.new(0, -sz.Y * 0.36, -(sz.Z / 2 + 0.2)), holder, out)
		end
	end
	local torso = model:FindFirstChild("UpperTorso")
	if torso and torso:IsA("BasePart") then
		local ts = torso.Size
		for k = 0, 10 do
			local a = (k / 10 - 0.5) * math.pi * 0.8
			attach(newPart(Vector3.new(0.18, 0.18, 0.18), pearl, Enum.Material.SmoothPlastic, 0, "ball"), torso, CFrame.new(math.sin(a) * ts.X * 0.3, ts.Y * 0.42 - math.cos(a) * ts.Y * 0.16, -ts.Z * 0.52), holder, out)
		end
		attach(newPart(Vector3.new(0.34, 0.34, 0.34), c, Enum.Material.Glass, 0.1, "ball"), torso, CFrame.new(0, ts.Y * 0.24, -ts.Z * 0.56), holder, out)
		-- 물의 띠: 어깨 뒤에서 늘어져 물결치는 투명한 띠 둘 (매 프레임 흔든다)
		local ribbons: { { BasePart } } = {}
		for ri = 1, 2 do
			local list: { BasePart } = {}
			for j = 1, 8 do
				local p = newPart(Vector3.new(0.5 - j * 0.03, 0.06, 0.75), j % 2 == 0 and c or Color3.fromRGB(150, 220, 250), Enum.Material.Glass, 0.25)
				p.Parent = holder
				table.insert(list, p)
				table.insert(out, p)
			end
			ribbons[ri] = list
		end
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			if not holder.Parent or not torso.Parent then
				conn:Disconnect()
				return
			end
			local t = os.clock() - t0
			for ri, list in ipairs(ribbons) do
				local x = ri == 1 and 1 or -1
				-- 어깨 뒤에서 아래로 늘어져, 끝으로 갈수록 뒤로 휘날린다
				local cf = torso.CFrame * CFrame.new(x * ts.X * 0.3, ts.Y * 0.42, ts.Z * 0.55) * CFrame.Angles(math.rad(78), 0, x * math.rad(-6))
				for j, p in ipairs(list) do
					local wave = math.sin(t * 3.2 - j * 0.7 + ri) * 0.22
					cf = cf * CFrame.Angles(wave * 0.5 - math.rad(7), 0, wave * 0.3 * x) * CFrame.new(0, 0, 0.7)
					p.CFrame = cf * CFrame.new(0, 0, -0.35)
				end
			end
		end)
	end
	return out
end

local HANDLERS: { [string]: (any) -> () } = {
	whale = whaleBreach,
	tideSpear = tideSpear,
	whaleSong = whaleSong,
	fourWaves = fourWaves,
	maelstrom = maelstrom,
	ancientSea = ancientSea,
	ancientLeap = ancientLeap,
	ancientCrash = ancientCrash,
}
function Whale.handles(data: any): boolean
	return HANDLERS[data.kind] ~= nil
end
function Whale.run(data: any)
	local fn = HANDLERS[data.kind]
	if fn then
		fn(data)
	end
end

return Whale
