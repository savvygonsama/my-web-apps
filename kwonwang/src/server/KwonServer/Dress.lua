-- 권왕 2.7판: 적과 보스의 차림 (Npc.lua에서 옮겨 와 처음부터 다시 짰다)
-- 원칙: 적마다 색은 셋 (윗옷 · 아랫옷 · 끈) 안에서, 옷은 몸에 붙게, 떠다니는 장식과 반짝이 입자는 쓰지 않는다.
-- 사람이 아닌 적 (정령·소악귀·돌 거인·망령·새·해골·버섯·늪 거한·뱀·늑대)은 몸 전체를 그 생김새의 빛깔로 칠한다
local Dress = {}

local C3 = Color3.fromRGB
local Ball, Cyl = Enum.PartType.Ball, Enum.PartType.Cylinder
local M = Enum.Material
local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)

local GOLD = C3(205, 165, 80)
local IRON = C3(100, 102, 110)
local DARK_HAIR = C3(30, 24, 20)
local WHITE_HAIR = C3(232, 230, 222)
local STRAW = C3(196, 168, 112)
local LEATHER = C3(58, 42, 30)

local LEGS = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
local ARMS = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" }
local LIMBS = { "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg" }

local function dark(c: Color3, t: number): Color3
	return c:Lerp(BLACK, t)
end
local function light(c: Color3, t: number): Color3
	return c:Lerp(WHITE, t)
end

local function partOf(model: Model, name: string): BasePart?
	local p = model:FindFirstChild(name)
	return (p and p:IsA("BasePart")) and p or nil
end
local function sizeOf(model: Model, name: string): Vector3
	local p = partOf(model, name)
	return p and p.Size or Vector3.new(1, 1, 1)
end
-- 몸 부위에 붙는 조각 (용접). 부위가 없으면 nil
local function wear(model: Model, partName: string, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part?
	local base = partOf(model, partName)
	if not base then
		return nil
	end
	local p = Instance.new("Part")
	p.Name = name
	-- 3.2.1판: 로블록스의 공 (Ball) 은 세 변이 같아지고 원통은 두 변이 같아진다. 늘인 공·원통은 구·원통 메시를 씌운 상자로
	-- (전에는 납작하게 짠 깃·갈기·갓이 게임 안에서 둥근 공으로 부풀어 덩어리처럼 보였다)
	local meshType: Enum.MeshType? = nil
	if shape == Ball and (math.max(size.X, size.Y, size.Z) - math.min(size.X, size.Y, size.Z)) > 0.02 then
		meshType = Enum.MeshType.Sphere
	elseif shape == Cyl and math.abs(size.Y - size.Z) > 0.02 then
		-- 원통 메시의 축은 Y: 상자를 돌려 축을 X에 맞춘다
		meshType = Enum.MeshType.Cylinder
		offset = offset * CFrame.Angles(0, 0, math.rad(-90))
		size = Vector3.new(size.Y, size.X, size.Z)
	elseif shape then
		p.Shape = shape
	end
	p.Size = Vector3.new(math.max(0.05, size.X), math.max(0.05, size.Y), math.max(0.05, size.Z))
	if meshType then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = meshType
		mesh.Parent = p
	end
	p.Color = color
	p.Material = material or M.Fabric
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = base.CFrame * offset
	p.Parent = model
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
	return p
end
-- 세운 원통 (원통의 축은 X이므로 Z로 90도 돌려 위를 보게 한다)
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local function disc(model: Model, partName: string, name: string, diameter: number, thick: number, at: CFrame, color: Color3, material: Enum.Material?): Part?
	return wear(model, partName, name, Vector3.new(thick, diameter, diameter), at * UPRIGHT, color, material, Cyl)
end
local function paint(model: Model, names: { string }, color: Color3, material: Enum.Material?, alpha: number?)
	for _, n in ipairs(names) do
		local p = partOf(model, n)
		if p then
			p.Color = color
			if material then
				p.Material = material
			end
			if alpha then
				p.Transparency = alpha
			end
		end
	end
end
local function hide(model: Model, names: { string })
	for _, n in ipairs(names) do
		local p = partOf(model, n)
		if p then
			p.Transparency = 1
		end
	end
end
local function clearFace(model: Model)
	local head = partOf(model, "Head")
	for _, d in ipairs(head and head:GetChildren() or {}) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
end
-- 은은한 빛 (정령·불 몸)
local function glow(model: Model, partName: string, color: Color3, range: number, brightness: number)
	local p = partOf(model, partName)
	if not p then
		return
	end
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = p
end
-- 로블록스 불 (불꽃 몸: 반짝이 대신 진짜 불길)
local function flame(model: Model, partName: string, color: Color3, color2: Color3, size: number, heat: number)
	local p = partOf(model, partName)
	if not p then
		return
	end
	local f = Instance.new("Fire")
	f.Color = color
	f.SecondaryColor = color2
	f.Size = size
	f.Heat = heat
	f.Parent = p
end
-- 굽은 뿔 (마디가 점점 가늘어지며 뒤로 휜다)
local function horn(model: Model, x: number, hs: Vector3, k: number, color: Color3, len: number, spread: number)
	local cf = CFrame.new(x * hs.X * 0.3, hs.Y * 0.42, -hs.Z * 0.02) * CFrame.Angles(0, 0, -x * math.rad(spread))
	local n = 4
	for j = 0, n - 1 do
		local w = (0.26 - j * 0.05) * k
		local seg = len * k / n
		wear(model, "Head", "Horn", Vector3.new(w, seg * 1.15, w), cf * CFrame.new(0, seg / 2, 0), color, M.SmoothPlastic)
		cf = cf * CFrame.new(0, seg, 0) * CFrame.Angles(math.rad(-22), 0, x * math.rad(10))
	end
end

------------------------------------------------------------------------
-- 얼굴: 기본 웃는 얼굴을 지우고 짙은 눈썹·눈·입을 그린다
------------------------------------------------------------------------
local function face(model: Model, look: any)
	local head = partOf(model, "Head")
	if not head then
		return
	end
	clearFace(model)
	-- 2.8판: 얼굴을 평평한 판 하나에 그리면 둥근 머리 (세운 원통) 앞에 떠 보였다.
	-- 이제 눈·눈썹·입을 하나하나 작은 조각으로 머리 겉면을 따라 붙인다 (옆에서 봐도 살갗에 붙어 있다)
	local hs = head.Size
	local R = math.min(hs.X, hs.Z) * 0.5
	local W, H = hs.X * 0.8, hs.Y * 0.62 -- 예전 얼굴판의 크기 (u, v 자리를 그대로 옮긴다)
	local glow = look.eyes ~= nil
	local ink = dark(head.Color, 0.78)
	local n = 0
	local function bar(u: number, v: number, w: number, h: number, rot: number, color: Color3, neon: boolean?)
		-- 앞에서 보는 사람의 왼쪽 = 머리의 +X
		local x = (0.5 - u) * W
		local y = -hs.Y * 0.02 + (0.5 - v) * H
		local cx = math.clamp(x, -R * 0.95, R * 0.95)
		local z = -math.sqrt(math.max(0, R * R - cx * cx))
		local normal = Vector3.new(cx, 0, z).Unit
		local at = Vector3.new(cx, y, z) + normal * 0.004
		n += 1
		wear(model, "Head", "Face" .. n, Vector3.new(math.max(0.05, w * W), math.max(0.05, h * H), 0.05), CFrame.lookAt(at, at - normal) * CFrame.Angles(0, 0, math.rad(-rot)), color, neon and M.Neon or M.SmoothPlastic)
	end
	if look.head ~= "wrap" then
		bar(0.3, 0.3, 0.28, 0.07, 12, ink)
		bar(0.7, 0.3, 0.28, 0.07, -12, ink)
	end
	local eye = look.eyes or C3(25, 18, 15)
	bar(0.32, 0.43, glow and 0.15 or 0.11, 0.065, 5, eye, glow)
	bar(0.68, 0.43, glow and 0.15 or 0.11, 0.065, -5, eye, glow)
	if look.eyepatch then
		bar(0.32, 0.43, 0.22, 0.16, 0, C3(15, 12, 10))
		bar(0.16, 0.3, 0.3, 0.04, -20, C3(15, 12, 10))
		bar(0.5, 0.24, 0.4, 0.04, -20, C3(15, 12, 10))
	end
	if not look.mask and look.head ~= "wrap" then
		bar(0.5, 0.74, 0.24, 0.035, 0, ink)
	end
	if look.scar then
		bar(0.7, 0.45, 0.035, 0.4, 20, C3(150, 75, 65))
	end
end

------------------------------------------------------------------------
-- 사람 적의 머리쓰개
------------------------------------------------------------------------
local function headgear(model: Model, look: any, P: any)
	local hs = sizeOf(model, "Head")
	local function cap(name: string, radius: number, height: number, y: number, color: Color3, material: Enum.Material?)
		disc(model, "Head", name, hs.X * radius * 2, height, CFrame.new(0, y, 0), color, material)
	end
	local kind = look.head
	if kind == "straw" then
		-- 삿갓: 넓고 얕은 챙, 두 층으로 좁아지는 몸, 턱끈
		local c = look.hat or STRAW
		cap("HatBrim", 1.5, 0.1, hs.Y * 0.42, c)
		cap("HatMid", 1.0, hs.Y * 0.12, hs.Y * 0.5, dark(c, 0.06))
		cap("HatCrown", 0.55, hs.Y * 0.16, hs.Y * 0.62, dark(c, 0.12))
		cap("HatTop", 0.22, hs.Y * 0.12, hs.Y * 0.74, dark(c, 0.2))
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "Head", "HatString", Vector3.new(0.05, hs.Y * 0.7, 0.05), CFrame.new(x * hs.X * 0.44, 0, -hs.Z * 0.1) * CFrame.Angles(0, 0, x * math.rad(8)), dark(c, 0.5))
		end
	elseif kind == "bandana" then
		cap("Bandana", 0.53, hs.Y * 0.32, hs.Y * 0.28, P.trim)
		wear(model, "Head", "BandanaKnot", Vector3.new(hs.X * 0.2, hs.Y * 0.18, hs.Z * 0.14), CFrame.new(0, hs.Y * 0.22, hs.Z * 0.54), dark(P.trim, 0.1))
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "Head", "BandanaTail", Vector3.new(hs.X * 0.12, hs.Y * 0.5, 0.06), CFrame.new(x * hs.X * 0.08, -hs.Y * 0.05, hs.Z * 0.58) * CFrame.Angles(math.rad(12), 0, x * math.rad(14)), P.trim)
		end
	elseif kind == "hood" then
		-- 두건 겉옷: 머리를 감싸고 어깨까지 덮는다 (얼굴은 드러난다)
		local c = look.hoodColor or P.top
		wear(model, "Head", "Hood", Vector3.new(hs.X * 1.14, hs.Y * 1.1, hs.Z * 1.1), CFrame.new(0, hs.Y * 0.06, hs.Z * 0.12), c, M.Fabric, Ball)
		wear(model, "Head", "HoodRim", Vector3.new(hs.X * 1.0, hs.Y * 0.1, hs.Z * 0.1), CFrame.new(0, hs.Y * 0.36, -hs.Z * 0.42) * CFrame.Angles(math.rad(-15), 0, 0), dark(c, 0.2))
		local ut = sizeOf(model, "UpperTorso")
		wear(model, "UpperTorso", "HoodDrape", Vector3.new(ut.X * 0.92, ut.Y * 0.28, ut.Z * 1.14), CFrame.new(0, ut.Y * 0.4, 0.02), c)
	elseif kind == "helmet" then
		local metal = look.metal or IRON
		cap("Helmet", 0.56, hs.Y * 0.4, hs.Y * 0.3, metal, M.Metal)
		wear(model, "Head", "HelmetDome", Vector3.new(hs.X * 1.1, hs.Y * 0.5, hs.Z * 1.1), CFrame.new(0, hs.Y * 0.48, 0), metal, M.Metal, Ball)
		cap("HelmetRim", 0.6, hs.Y * 0.07, hs.Y * 0.1, dark(metal, 0.3), M.Metal)
		-- 목 가리개 (뒤로 늘어진 쇠 비늘)
		wear(model, "Head", "NeckGuard", Vector3.new(hs.X * 1.0, hs.Y * 0.4, 0.08), CFrame.new(0, -hs.Y * 0.1, hs.Z * 0.56) * CFrame.Angles(math.rad(-10), 0, 0), dark(metal, 0.15), M.Metal)
		if look.plume then
			-- 투구 꼭대기의 술 (짧은 대에서 뒤로 흘러내린다)
			wear(model, "Head", "PlumeBase", Vector3.new(hs.X * 0.12, hs.Y * 0.2, hs.X * 0.12), CFrame.new(0, hs.Y * 0.8, 0), GOLD, M.Metal)
			wear(model, "Head", "Plume", Vector3.new(hs.X * 0.22, hs.Y * 0.18, hs.Z * 0.7), CFrame.new(0, hs.Y * 0.88, hs.Z * 0.28) * CFrame.Angles(math.rad(-25), 0, 0), look.plume)
		end
	elseif kind == "topknot" then
		local hair = look.hair or DARK_HAIR
		cap("Hair", 0.53, hs.Y * 0.3, hs.Y * 0.3, hair, M.SmoothPlastic)
		wear(model, "Head", "HairBack", Vector3.new(hs.X * 0.95, hs.Y * 0.55, hs.Z * 0.2), CFrame.new(0, hs.Y * 0.1, hs.Z * 0.44), hair, M.SmoothPlastic)
		wear(model, "Head", "Topknot", Vector3.new(hs.X * 0.28, hs.X * 0.28, hs.X * 0.28), CFrame.new(0, hs.Y * 0.6, hs.Z * 0.05), hair, M.SmoothPlastic, Ball)
		wear(model, "Head", "TopknotTie", Vector3.new(hs.X * 0.08, hs.X * 0.3, hs.X * 0.3), CFrame.new(0, hs.Y * 0.5, hs.Z * 0.05) * UPRIGHT, P.trim, M.Fabric, Cyl)
		if look.longHair then
			-- 허리까지 늘어진 머리
			wear(model, "Head", "LongHair", Vector3.new(hs.X * 0.7, hs.Y * 1.8, hs.Z * 0.16), CFrame.new(0, -hs.Y * 0.7, hs.Z * 0.5) * CFrame.Angles(math.rad(-6), 0, 0), hair, M.SmoothPlastic)
		end
	elseif kind == "bald" then
		-- 민머리: 머리띠 하나
		if look.headband then
			cap("Headband", 0.52, hs.Y * 0.1, hs.Y * 0.22, look.headband)
		end
	elseif kind == "horns" then
		local hair = look.hair or DARK_HAIR
		cap("Hair", 0.53, hs.Y * 0.28, hs.Y * 0.3, hair, M.SmoothPlastic)
		for _, x in ipairs({ -1, 1 }) do
			horn(model, x, hs, hs.X / 1.2, look.hornColor or C3(40, 32, 30), look.hornLen or 1.1, 20)
		end
	elseif kind == "wrap" then
		wear(model, "Head", "Wrap", Vector3.new(hs.X * 1.06, hs.Y * 1.04, hs.Z * 1.06), CFrame.new(0, hs.Y * 0.02, 0), P.top, M.Fabric, Ball)
		for j = -1, 1 do
			cap("WrapBand", 0.54, hs.Y * 0.06, j * hs.Y * 0.22, dark(P.top, 0.18))
		end
	end
	if look.crown then
		-- 관: 머리에 얹은 낮은 금관과 앞의 작은 장식 판 (사람 머리에 맞는 크기)
		cap("Crown", 0.42, hs.Y * 0.16, hs.Y * 0.66, look.crown, M.Metal)
		wear(model, "Head", "CrownFront", Vector3.new(hs.X * 0.3, hs.Y * 0.34, 0.06), CFrame.new(0, hs.Y * 0.78, -hs.Z * 0.4), look.crown, M.Metal)
		if look.gem then
			wear(model, "Head", "CrownGem", Vector3.new(hs.X * 0.12, hs.X * 0.12, 0.06), CFrame.new(0, hs.Y * 0.78, -hs.Z * 0.44), look.gem, M.Glass, Ball)
		end
	end
	if look.mask then
		wear(model, "Head", "Mask", Vector3.new(hs.X * 0.9, hs.Y * 0.38, hs.Z * 0.48), CFrame.new(0, -hs.Y * 0.24, -hs.Z * 0.3), look.mask)
	end
	if look.beard then
		local bc = look.beard == "white" and WHITE_HAIR or (look.hair or DARK_HAIR)
		local long = look.beard ~= "stubble"
		wear(model, "Head", "Beard", Vector3.new(hs.X * 0.6, hs.Y * (long and 0.42 or 0.14), hs.Z * 0.22), CFrame.new(0, -hs.Y * (long and 0.5 or 0.38), -hs.Z * 0.42), bc, M.SmoothPlastic)
		if long then
			for _, x in ipairs({ -1, 1 }) do
				wear(model, "Head", "Mustache", Vector3.new(hs.X * 0.3, hs.Y * 0.08, 0.1), CFrame.new(x * hs.X * 0.16, -hs.Y * 0.16, -hs.Z * 0.52) * CFrame.Angles(0, 0, x * math.rad(-18)), bc, M.SmoothPlastic)
			end
		end
	end
end

------------------------------------------------------------------------
-- 사람 적의 옷: 저고리 (여민 깃) · 허리띠 (매듭과 늘어진 끝) · 바지 (정강이 감개) · 천신 · 팔목 감개
-- 갑옷은 비늘 갑옷 (앞뒤 판과 비늘 줄, 두 겹 어깨받이, 허리 아래 드리개), 도포는 앞이 갈라진 긴 자락
------------------------------------------------------------------------
local function outfit(model: Model, look: any, P: any, K: number)
	local ut, lt = sizeOf(model, "UpperTorso"), sizeOf(model, "LowerTorso")
	paint(model, { "UpperTorso", "LowerTorso" }, P.top, M.Fabric)
	paint(model, { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }, P.bottom, M.Fabric)
	paint(model, { "LeftFoot", "RightFoot" }, P.shoe, M.Fabric)
	if look.sleeves ~= false then
		paint(model, { "LeftUpperArm", "RightUpperArm" }, P.top, M.Fabric)
	end
	-- 여민 깃: 왼쪽 깃이 오른쪽 위로 비스듬히 덮는다
	local front = -ut.Z * 0.5 - 0.02
	wear(model, "UpperTorso", "Lapel", Vector3.new(0.24 * K, ut.Y * 0.78, 0.05), CFrame.new(ut.X * 0.06, ut.Y * 0.08, front) * CFrame.Angles(0, 0, math.rad(-30)), P.trim)
	wear(model, "UpperTorso", "LapelBack", Vector3.new(0.2 * K, ut.Y * 0.4, 0.045), CFrame.new(-ut.X * 0.12, ut.Y * 0.26, front + 0.01) * CFrame.Angles(0, 0, math.rad(30)), dark(P.trim, 0.12))
	wear(model, "UpperTorso", "Collar", Vector3.new(ut.X * 0.5, 0.16 * K, ut.Z * 1.06), CFrame.new(0, ut.Y * 0.47, 0), P.trim)
	-- 허리띠: 몸을 두르고 왼쪽 앞에서 매듭, 두 끝이 늘어진다
	wear(model, "LowerTorso", "Sash", Vector3.new(lt.X * 1.05, 0.34 * K, lt.Z * 1.12), CFrame.new(0, 0.06 * K, 0), P.sash)
	wear(model, "LowerTorso", "SashKnot", Vector3.new(0.3 * K, 0.26 * K, 0.12 * K), CFrame.new(-lt.X * 0.28, 0.04 * K, -lt.Z * 0.6), dark(P.sash, 0.12))
	for i, x in ipairs({ -0.36, -0.22 }) do
		wear(model, "LowerTorso", "SashEnd", Vector3.new(0.16 * K, (0.85 - i * 0.12) * K, 0.05), CFrame.new(lt.X * x, -0.42 * K, -lt.Z * 0.6) * CFrame.Angles(math.rad(-4), 0, math.rad(i * 4 - 6)), P.sash)
	end
	-- 정강이 감개와 천신, 팔목 감개
	for _, side in ipairs({ "Left", "Right" }) do
		local ll = sizeOf(model, side .. "LowerLeg")
		wear(model, side .. "LowerLeg", "LegWrap", Vector3.new(ll.X * 1.06, ll.Y * 0.62, ll.Z * 1.06), CFrame.new(0, -ll.Y * 0.16, 0), P.wrap)
		for j = 0, 1 do
			wear(model, side .. "LowerLeg", "LegWrapLine", Vector3.new(ll.X * 1.08, 0.035, ll.Z * 1.08), CFrame.new(0, -ll.Y * (0.02 + j * 0.2), 0), dark(P.wrap, 0.22))
		end
		local la = sizeOf(model, side .. "LowerArm")
		wear(model, side .. "LowerArm", "Bracer", Vector3.new(la.X * 1.06, la.Y * 0.38, la.Z * 1.06), CFrame.new(0, -la.Y * 0.26, 0), look.bracer or LEATHER, M.Leather)
		if look.sleeves ~= false then
			-- 넓은 소매 끝
			wear(model, side .. "LowerArm", "Cuff", Vector3.new(la.X * 1.1, la.Y * 0.42, la.Z * 1.1), CFrame.new(0, la.Y * 0.28, 0), P.top)
			wear(model, side .. "LowerArm", "CuffTrim", Vector3.new(la.X * 1.12, la.Y * 0.07, la.Z * 1.12), CFrame.new(0, la.Y * 0.08, 0), P.trim)
		end
	end
	if look.armor then
		local metal = look.metal or IRON
		local line = dark(metal, 0.35)
		for _, z in ipairs({ -1, 1 }) do
			wear(model, "UpperTorso", "Plate", Vector3.new(ut.X * 0.86, ut.Y * 0.7, 0.12 * K), CFrame.new(0, ut.Y * 0.04, z * (ut.Z * 0.5 + 0.05 * K)), metal, M.Metal)
			for j = 0, 2 do
				wear(model, "UpperTorso", "PlateRow", Vector3.new(ut.X * 0.87, 0.045 * K, 0.13 * K), CFrame.new(0, ut.Y * (0.22 - j * 0.2), z * (ut.Z * 0.5 + 0.055 * K)), line, M.Metal)
			end
		end
		for _, x in ipairs({ -1, 1 }) do
			for j = 0, 1 do
				wear(model, "UpperTorso", "Pauldron", Vector3.new(ut.X * (0.36 + j * 0.04), 0.12 * K, ut.Z * (1.16 + j * 0.06)), CFrame.new(x * ut.X * (0.48 + j * 0.06), ut.Y * (0.48 - j * 0.12), 0) * CFrame.Angles(0, 0, -x * math.rad(18 + j * 10)), j == 0 and metal or dark(metal, 0.12), M.Metal)
			end
			-- 허리 아래 드리개 (앞에 둘)
			wear(model, "LowerTorso", "Tasset", Vector3.new(lt.X * 0.42, 0.9 * K, 0.08 * K), CFrame.new(x * lt.X * 0.24, -0.5 * K, -lt.Z * 0.58) * CFrame.Angles(math.rad(-5), 0, x * math.rad(4)), dark(metal, 0.08), M.Metal)
			wear(model, "LowerTorso", "TassetRow", Vector3.new(lt.X * 0.43, 0.04 * K, 0.09 * K), CFrame.new(x * lt.X * 0.24, -0.4 * K, -lt.Z * 0.58) * CFrame.Angles(math.rad(-5), 0, x * math.rad(4)), line, M.Metal)
		end
		if look.armorTrim then
			wear(model, "UpperTorso", "PlateEdge", Vector3.new(ut.X * 0.88, 0.06 * K, 0.14 * K), CFrame.new(0, ut.Y * 0.39, -(ut.Z * 0.5 + 0.05 * K)), look.armorTrim, M.Metal)
		end
	end
	if look.robe then
		-- 도포: 허리 아래로 앞이 갈라진 두 자락과 뒷자락, 끝단에 끈 빛깔
		local c = look.robe
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "LowerTorso", "RobeFront", Vector3.new(lt.X * 0.52, 2.0 * K, 0.1 * K), CFrame.new(x * lt.X * 0.27, -1.05 * K, -lt.Z * 0.55) * CFrame.Angles(math.rad(-3), 0, x * math.rad(3)), c)
			wear(model, "LowerTorso", "RobeHem", Vector3.new(lt.X * 0.53, 0.1 * K, 0.11 * K), CFrame.new(x * lt.X * 0.27 + x * 0.05 * K, -2.0 * K, -lt.Z * 0.55 + 0.05 * K) * CFrame.Angles(math.rad(-3), 0, x * math.rad(3)), P.trim)
		end
		wear(model, "LowerTorso", "RobeBack", Vector3.new(lt.X * 1.04, 2.1 * K, 0.1 * K), CFrame.new(0, -1.1 * K, lt.Z * 0.56) * CFrame.Angles(math.rad(3), 0, 0), c)
		wear(model, "LowerTorso", "RobeBackHem", Vector3.new(lt.X * 1.05, 0.1 * K, 0.11 * K), CFrame.new(0, -2.1 * K, lt.Z * 0.56 + 0.05 * K), P.trim)
	end
	if look.beads then
		-- 염주
		for i = 0, 9 do
			local a = (i / 9 - 0.5) * math.pi * 0.9
			wear(model, "UpperTorso", "Bead", Vector3.new(0.2 * K, 0.2 * K, 0.2 * K), CFrame.new(math.sin(a) * ut.X * 0.28, ut.Y * 0.4 - math.cos(a) * ut.Y * 0.35, -ut.Z * 0.52), look.beads, M.Wood, Ball)
		end
	end
end
-- 보스의 겉옷: 어깨에서 늘어지는 망토 한 장과 목둘레 (털이나 두꺼운 천)
local function mantle(model: Model, color: Color3, collar: Color3, K: number, len: number?)
	local ut = sizeOf(model, "UpperTorso")
	local L = (len or 3.2) * K
	wear(model, "UpperTorso", "MantleCollar", Vector3.new(ut.X * 0.86, 0.3 * K, ut.Z * 1.24), CFrame.new(0, ut.Y * 0.5, 0.02 * K), collar)
	-- 어깨 위 끝에 매달려 아래로 조금 뒤로 기운다
	local top = CFrame.new(0, ut.Y * 0.5, ut.Z * 0.6) * CFrame.Angles(math.rad(6), 0, 0)
	wear(model, "UpperTorso", "Mantle", Vector3.new(ut.X * 1.02, L, 0.1 * K), top * CFrame.new(0, -L / 2, 0), color)
	wear(model, "UpperTorso", "MantleHem", Vector3.new(ut.X * 1.03, 0.12 * K, 0.12 * K), top * CFrame.new(0, -L + 0.06 * K, 0), collar)
end

------------------------------------------------------------------------
-- 사람이 아닌 적의 몸
------------------------------------------------------------------------
local FORMS: { [string]: (Model, any, number, boolean) -> () } = {}

-- 정령: 다리 없이 흘러내리는 몸, 같은 빛깔의 둥근 머리와 고요한 눈, 속의 은은한 빛
FORMS.spirit = function(model, look, k, boss)
	local c = look.skin or C3(120, 190, 240)
	local solid = look.solid
	local mat = solid and M.Slate or M.Glass
	local alpha = solid and 0 or 0.2
	hide(model, LEGS)
	clearFace(model)
	paint(model, { "Head", "UpperTorso", "LowerTorso" }, c, mat, alpha)
	paint(model, ARMS, light(c, 0.08), mat, solid and 0 or 0.28)
	local hs = sizeOf(model, "Head")
	-- 흘러내리는 꼬리: 위가 굵고 아래로 가늘어지며 살짝 뒤로 휜다.
	-- 2.8판: 공 다섯이 줄줄이 달려 덩어리져 보였다. 길쭉한 조각을 촘촘히 겹쳐 한 줄기로 매끈하게 흐르게
	local n = 10
	for i = 0, n - 1 do
		local u = i / (n - 1)
		local w = (1.7 * (1 - u) ^ 0.9 + 0.18) * k
		local p = wear(model, "LowerTorso", "Tail", Vector3.new(w, w * 1.7, w * 0.92), CFrame.new(0, (-0.5 - u * 2.9) * k, (u * u * 0.9) * k) * CFrame.Angles(math.rad(-u * 28), 0, 0), dark(c, u * 0.12), mat, Ball)
		if p then
			p.Transparency = solid and 0 or (0.22 + u * 0.4)
		end
	end
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.2, 0.12, 0.08) * k, CFrame.new(x * hs.X * 0.2, hs.Y * 0.05, -hs.Z * 0.48), look.eyes or WHITE, M.Neon)
	end
	local crest = look.crest
	if crest == "ice" then
		for j = -1, 1 do
			wear(model, "Head", "Icicle", Vector3.new(0.18, 0.9 - math.abs(j) * 0.3, 0.18) * k, CFrame.new(j * hs.X * 0.22, hs.Y * 0.6, hs.Z * 0.05) * CFrame.Angles(0, 0, -j * 0.3), light(c, 0.5), M.Glass)
		end
	elseif crest == "water" then
		-- 물방울 머리채: 뒤로 흘러 떨어지는 물방울 셋
		for j = 0, 2 do
			local p = wear(model, "Head", "Droplet", Vector3.new(0.55 - j * 0.12, 0.55 - j * 0.12, 0.55 - j * 0.12) * k, CFrame.new(0, hs.Y * (0.5 - j * 0.12), hs.Z * (0.25 + j * 0.25)), c, M.Glass, Ball)
			if p then
				p.Transparency = 0.25
			end
		end
	elseif crest == "moss" then
		wear(model, "Head", "Moss", Vector3.new(hs.X * 0.9, 0.18 * k, hs.Z * 0.9), CFrame.new(0, hs.Y * 0.48, 0), look.moss or C3(80, 120, 60), M.Grass)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "UpperTorso", "Moss", Vector3.new(0.8 * k, 0.16 * k, 0.8 * k), CFrame.new(x * 0.75 * k, 0.82 * k, 0), look.moss or C3(80, 120, 60), M.Grass)
		end
	elseif crest == "star" then
		-- 머리 위의 작은 별 하나 (붙어 있다)
		wear(model, "Head", "Star", Vector3.new(0.4, 0.4, 0.4) * k, CFrame.new(0, hs.Y * 0.62, 0), look.eyes or WHITE, M.Neon, Ball)
	end
	glow(model, "UpperTorso", c, 10 * k, solid and 0 or 1.2)
	if boss then
		wear(model, "UpperTorso", "Core", Vector3.new(0.7, 0.7, 0.7) * k, CFrame.new(0, 0.1 * k, 0), light(c, 0.6), M.Neon, Ball)
	end
end

-- 소악귀: 잿빛이 도는 한 빛깔의 몸, 굽은 뿔, 뾰족한 귀, 접은 박쥐 날개, 삽 꼬리, 손톱
FORMS.imp = function(model, look, k, boss)
	local skin = look.skin or C3(170, 70, 50)
	local hornC = look.hornColor or dark(skin, 0.6)
	clearFace(model)
	paint(model, { "Head", "UpperTorso", "LowerTorso" }, skin, M.SmoothPlastic)
	paint(model, ARMS, skin, M.SmoothPlastic)
	paint(model, LEGS, dark(skin, 0.2), M.SmoothPlastic)
	local hs = sizeOf(model, "Head")
	for _, x in ipairs({ -1, 1 }) do
		horn(model, x, hs, k, hornC, 0.8, 30)
		wear(model, "Head", "Ear", Vector3.new(0.08, 0.45, 0.24) * k, CFrame.new(x * hs.X * 0.55, hs.Y * 0.08, 0) * CFrame.Angles(0, 0, -x * math.rad(62)), skin, M.SmoothPlastic)
		wear(model, "Head", "Eye", Vector3.new(0.22, 0.1, 0.06) * k, CFrame.new(x * hs.X * 0.2, hs.Y * 0.06, -hs.Z * 0.5) * CFrame.Angles(0, 0, x * math.rad(-15)), look.eyes or C3(255, 220, 90), M.Neon)
		-- 접은 날개: 뼈 둘과 그 사이의 막 (등에 바짝)
		local wing = dark(skin, 0.4)
		wear(model, "UpperTorso", "WingArm", Vector3.new(0.15, 1.5, 0.15) * k, CFrame.new(x * 0.75 * k, 0.95 * k, 0.6 * k) * CFrame.Angles(math.rad(12), 0, -x * math.rad(50)), hornC, M.SmoothPlastic)
		wear(model, "UpperTorso", "WingTip", Vector3.new(0.12, 1.5, 0.12) * k, CFrame.new(x * 1.45 * k, 0.75 * k, 0.64 * k) * CFrame.Angles(math.rad(12), 0, x * math.rad(8)), hornC, M.SmoothPlastic)
		wear(model, "UpperTorso", "Wing", Vector3.new(1.0, 1.4, 0.05) * k, CFrame.new(x * 0.95 * k, 0.3 * k, 0.62 * k) * CFrame.Angles(math.rad(10), 0, -x * math.rad(10)), wing, M.SmoothPlastic)
		wear(model, "UpperTorso", "WingOuter", Vector3.new(0.6, 1.1, 0.05) * k, CFrame.new(x * 1.55 * k, 0.2 * k, 0.64 * k) * CFrame.Angles(math.rad(10), 0, x * math.rad(6)), dark(wing, 0.1), M.SmoothPlastic)
	end
	wear(model, "Head", "Grin", Vector3.new(0.42, 0.06, 0.05) * k, CFrame.new(0, -hs.Y * 0.22, -hs.Z * 0.5), dark(skin, 0.7), M.SmoothPlastic)
	local cf = CFrame.new(0, -0.05 * k, 0.5 * k)
	for _ = 1, 4 do
		local seg = cf * CFrame.Angles(math.rad(-32), 0, 0) * CFrame.new(0, -0.32 * k, 0)
		wear(model, "LowerTorso", "Tail", Vector3.new(0.14, 0.66, 0.14) * k, seg, skin, M.SmoothPlastic)
		cf = seg * CFrame.new(0, -0.32 * k, 0)
	end
	wear(model, "LowerTorso", "TailTip", Vector3.new(0.34, 0.34, 0.06) * k, cf * CFrame.Angles(0, 0, math.rad(45)), hornC, M.SmoothPlastic)
	for _, hn in ipairs({ "LeftHand", "RightHand" }) do
		for j = -1, 1 do
			wear(model, hn, "Claw", Vector3.new(0.07, 0.3, 0.07) * k, CFrame.new(j * 0.2 * k, -0.26 * k, -0.14 * k) * CFrame.Angles(math.rad(25), 0, 0), hornC, M.SmoothPlastic)
		end
	end
	if look.fire then
		flame(model, "Head", look.fire, dark(look.fire, 0.4), 2.2 * k, 5)
	elseif look.spark then
		glow(model, "UpperTorso", look.spark, 8 * k, 1)
	end
	local _ = boss
end

-- 돌 거인: 크게 쌓은 바위 몸. 빛깔은 한 가지 돌에 짙고 옅은 결만, 이끼는 위를 보는 면에만.
-- carved = 깎아 만든 석상 (반듯한 판과 투구), 아니면 자연석 (조금씩 기운 덩어리)
FORMS.golem = function(model, look, k, boss)
	local rock = look.skin or C3(125, 120, 112)
	local d1, d2 = dark(rock, 0.14), dark(rock, 0.28)
	local carved = look.carved
	local mat = carved and M.Concrete or M.Slate
	local tilt = carved and 0 or 1
	clearFace(model)
	paint(model, { "UpperTorso", "LowerTorso" }, rock, mat)
	paint(model, ARMS, rock, mat)
	paint(model, LEGS, d1, mat)
	hide(model, { "Head" })
	local eye = look.eyes or C3(255, 190, 110)
	-- 머리: 어깨 위로 드러난 모난 돌과 튀어나온 이마
	wear(model, "Head", "RockHead", Vector3.new(1.2, 1.0, 1.1) * k, CFrame.new(0, 0, 0) * CFrame.Angles(0.04 * tilt, 0.12 * tilt, 0), d1, mat)
	wear(model, "Head", "Brow", Vector3.new(1.26, 0.26, 0.42) * k, CFrame.new(0, 0.2 * k, -0.42 * k) * CFrame.Angles(0.12, 0, 0), d2, mat)
	wear(model, "Head", "Jaw", Vector3.new(1.0, 0.3, 0.9) * k, CFrame.new(0, -0.48 * k, -0.08 * k), d2, mat)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.22, 0.08, 0.05) * k, CFrame.new(x * 0.25 * k, 0.02 * k, -0.57 * k), dark(eye, 0.1), M.Neon)
	end
	if carved then
		-- 석상: 투구, 가슴판, 허리 판, 어깨 판 (반듯하게 깎았다)
		wear(model, "Head", "StoneHelm", Vector3.new(1.3, 0.4, 1.2) * k, CFrame.new(0, 0.5 * k, 0.02 * k), rock, mat)
		wear(model, "Head", "StoneCrest", Vector3.new(0.2, 0.5, 1.0) * k, CFrame.new(0, 0.85 * k, 0.05 * k), d1, mat)
		wear(model, "UpperTorso", "ChestPlate", Vector3.new(1.7, 1.2, 0.3) * k, CFrame.new(0, 0.1 * k, -0.5 * k), light(rock, 0.06), mat)
		wear(model, "UpperTorso", "ChestLine", Vector3.new(1.72, 0.08, 0.32) * k, CFrame.new(0, -0.15 * k, -0.5 * k), d2, mat)
		wear(model, "LowerTorso", "Skirt", Vector3.new(2.1, 0.9, 1.15) * k, CFrame.new(0, -0.35 * k, 0), d1, mat)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "UpperTorso", "ShoulderPlate", Vector3.new(1.1, 0.35, 1.2) * k, CFrame.new(x * 1.2 * k, 0.72 * k, 0) * CFrame.Angles(0, 0, -x * math.rad(14)), rock, mat)
		end
	else
		wear(model, "UpperTorso", "Slab", Vector3.new(1.25, 0.9, 0.45) * k, CFrame.new(-0.4 * k, 0.25 * k, -0.42 * k) * CFrame.Angles(0.05, 0.1, 0.06), rock, mat)
		wear(model, "UpperTorso", "Slab", Vector3.new(1.1, 0.8, 0.45) * k, CFrame.new(0.45 * k, -0.25 * k, -0.42 * k) * CFrame.Angles(-0.04, -0.1, -0.05), d1, mat)
		wear(model, "UpperTorso", "BackSlab", Vector3.new(1.8, 1.2, 0.7) * k, CFrame.new(0, 0.3 * k, 0.5 * k) * CFrame.Angles(0.18, 0, 0.03), d1, mat)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "UpperTorso", "ShoulderRock", Vector3.new(1.1, 0.75, 1.15) * k, CFrame.new(x * 1.2 * k, 0.55 * k, 0) * CFrame.Angles(0.1 * x, 0.25, x * -0.2), rock, mat)
		end
	end
	for _, side in ipairs({ "Left", "Right" }) do
		wear(model, side .. "LowerArm", "ForeRock", Vector3.new(1.2, 1.0, 1.2) * k, CFrame.new(0, -0.05 * k, 0) * CFrame.Angles(0, 0.25 * tilt, 0), rock, mat)
		wear(model, side .. "Hand", "Fist", Vector3.new(1.35, 0.95, 1.3) * k, CFrame.new(0, -0.25 * k, 0), d1, mat)
		wear(model, side .. "LowerLeg", "ShinRock", Vector3.new(1.2, 0.8, 1.2) * k, CFrame.new(0, 0, 0) * CFrame.Angles(0, 0.3 * tilt, 0), d1, mat)
		wear(model, side .. "Foot", "FootRock", Vector3.new(1.25, 0.45, 1.45) * k, CFrame.new(0, 0, -0.1 * k), d2, mat)
	end
	if look.moss then
		local moss = look.moss
		wear(model, "UpperTorso", "Moss", Vector3.new(1.5, 0.12, 0.8) * k, CFrame.new(0, 0.82 * k, 0.12 * k), moss, M.Grass)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "UpperTorso", "ShoulderMoss", Vector3.new(0.95, 0.12, 0.95) * k, CFrame.new(x * 1.2 * k, 0.93 * k, 0) * CFrame.Angles(0.1 * x, 0.25, x * -0.2), moss, M.Grass)
		end
		wear(model, "Head", "HeadMoss", Vector3.new(0.95, 0.12, 0.85) * k, CFrame.new(0, 0.5 * k, 0.05 * k), moss, M.Grass)
	end
	if look.ember then
		local e = look.ember
		wear(model, "UpperTorso", "Seam", Vector3.new(0.07, 1.0, 0.05) * k, CFrame.new(0.03 * k, 0.0, -0.66 * k) * CFrame.Angles(0, 0, math.rad(16)), e, M.Neon)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "UpperTorso", "Seam", Vector3.new(0.55, 0.06, 0.05) * k, CFrame.new(x * 0.45 * k, -0.2 * k + x * 0.1 * k, -0.66 * k), e, M.Neon)
		end
		glow(model, "UpperTorso", e, 10 * k, 1)
		if look.lava then
			flame(model, "UpperTorso", e, dark(e, 0.5), 2.5 * k, 6)
		end
	end
	local _ = boss
end

-- 망령: 다리 없이 끌리는 해진 옷자락, 깊은 두건 속 어둠과 두 눈, 메마른 팔
FORMS.wraith = function(model, look, k, boss)
	local cloth = look.cloth or C3(200, 180, 140)
	clearFace(model)
	hide(model, LEGS)
	paint(model, { "UpperTorso", "LowerTorso" }, cloth, M.Fabric)
	paint(model, { "LeftUpperArm", "RightUpperArm" }, cloth, M.Fabric)
	paint(model, { "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand" }, look.bone or C3(70, 62, 56), M.SmoothPlastic)
	paint(model, { "Head" }, C3(8, 6, 10), M.SmoothPlastic)
	-- 깊은 두건: 머리 위와 옆, 뒤를 덮고 앞은 어둡게 열려 있다. 어깨까지 흘러내린다
	wear(model, "Head", "CowlTop", Vector3.new(1.5, 0.5, 1.5) * k, CFrame.new(0, 0.55 * k, 0.1 * k) * CFrame.Angles(math.rad(-8), 0, 0), cloth, M.Fabric)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "CowlSide", Vector3.new(0.22, 1.4, 1.45) * k, CFrame.new(x * 0.68 * k, 0.0, 0.08 * k), cloth, M.Fabric)
	end
	wear(model, "Head", "CowlBack", Vector3.new(1.5, 1.5, 0.25) * k, CFrame.new(0, 0.05 * k, 0.72 * k), cloth, M.Fabric)
	wear(model, "Head", "CowlPeak", Vector3.new(0.4, 0.55, 0.4) * k, CFrame.new(0, 0.72 * k, 0.75 * k) * CFrame.Angles(math.rad(-40), 0, 0), cloth, M.Fabric)
	wear(model, "UpperTorso", "CowlDrape", Vector3.new(2.3, 0.6, 1.3) * k, CFrame.new(0, 0.62 * k, 0.05 * k), dark(cloth, 0.06), M.Fabric)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.18, 0.18, 0.08) * k, CFrame.new(x * 0.22 * k, 0.04 * k, -0.6 * k), look.eyes or C3(255, 230, 150), M.Neon, Ball)
		wear(model, x < 0 and "LeftUpperArm" or "RightUpperArm", "Sleeve", Vector3.new(1.25, 0.9, 1.25) * k, CFrame.new(0, -0.55 * k, 0), dark(cloth, 0.1), M.Fabric)
	end
	-- 해진 옷자락 (길이가 제각각인 띠 아홉, 바깥쪽이 짙다)
	for i = 0, 8 do
		local a = (i / 9) * math.pi * 2
		local len = (2.4 + ((i * 7) % 3) * 0.5) * k
		wear(model, "LowerTorso", "Rag", Vector3.new(0.75 * k, len, 0.07 * k), CFrame.new(math.cos(a) * 0.82 * k, -len / 2 - 0.05 * k, math.sin(a) * 0.55 * k) * CFrame.Angles(math.sin(a) * 0.2, -a, math.cos(a) * 0.12), dark(cloth, (i % 3) * 0.12), M.Fabric)
	end
	local _ = boss
end

-- 새 무사 (학·봉황): 몸 전체가 깃 빛깔, 부리와 볏, 등에 접은 날개 (끝깃은 짙게), 꼬리깃, 새 발
FORMS.bird = function(model, look, k, boss)
	local feather = look.feather or C3(240, 240, 240)
	local crest = look.crest or C3(210, 40, 40)
	local beak = look.beak or C3(225, 185, 90)
	local tip = look.tip or dark(feather, 0.75)
	clearFace(model)
	paint(model, { "Head", "UpperTorso", "LowerTorso" }, feather, M.SmoothPlastic)
	paint(model, ARMS, feather, M.SmoothPlastic)
	paint(model, { "LeftUpperLeg", "RightUpperLeg" }, look.thigh or dark(feather, 0.08), M.SmoothPlastic)
	paint(model, { "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot" }, dark(beak, 0.1), M.SmoothPlastic)
	local hs = sizeOf(model, "Head")
	wear(model, "Head", "Beak", Vector3.new(0.2, 0.18, 1.0) * k, CFrame.new(0, -hs.Y * 0.02, -hs.Z * 0.9) * CFrame.Angles(math.rad(-8), 0, 0), beak, M.SmoothPlastic)
	wear(model, "Head", "BeakLow", Vector3.new(0.16, 0.09, 0.72) * k, CFrame.new(0, -hs.Y * 0.15, -hs.Z * 0.76) * CFrame.Angles(math.rad(4), 0, 0), dark(beak, 0.2), M.SmoothPlastic)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.12, 0.12, 0.12) * k, CFrame.new(x * hs.X * 0.34, hs.Y * 0.12, -hs.Z * 0.4), look.eyes or C3(20, 20, 20), M.SmoothPlastic, Ball)
	end
	-- 가슴 깃 (몸보다 옅은 둥근 판)과 목둘레 깃
	local ut = sizeOf(model, "UpperTorso")
	-- 2.8판: 가슴에 공이 붙은 것처럼 보여, 몸에 붙은 얇은 깃 판 셋으로 (위가 넓고 아래로 겹친다)
	for j = 0, 2 do
		wear(model, "UpperTorso", "Breast", Vector3.new(ut.X * (0.7 - j * 0.14), ut.Y * 0.32, 0.08 * k), CFrame.new(0, ut.Y * (0.22 - j * 0.24), -ut.Z * 0.5 - 0.01), j == 0 and (look.breast or light(feather, 0.18)) or light(feather, 0.1 - j * 0.04), M.SmoothPlastic, Ball)
	end
	wear(model, "UpperTorso", "NeckRuff", Vector3.new(ut.X * 0.6, 0.35 * k, ut.Z * 1.1), CFrame.new(0, ut.Y * 0.48, 0), look.neck or feather, M.SmoothPlastic, Ball)
	-- 볏: 정수리의 붉은 점 (학) 또는 뒤로 넘어가는 깃 (봉황)
	if look.longCrest then
		for j = 0, 2 do
			wear(model, "Head", "Crest", Vector3.new(0.08, 0.65 - j * 0.1, 0.26) * k, CFrame.new(0, hs.Y * (0.55 + j * 0.04), hs.Z * (0.1 + j * 0.2)) * CFrame.Angles(math.rad(-35 - j * 15), 0, 0), crest, M.SmoothPlastic)
		end
	else
		wear(model, "Head", "Crest", Vector3.new(hs.X * 0.5, 0.12 * k, hs.Z * 0.5), CFrame.new(0, hs.Y * 0.5, 0), crest, M.SmoothPlastic, Ball)
	end
	-- 접은 날개: 등 양쪽으로 깃 다섯 겹, 아래 두 겹은 끝깃 빛깔
	for _, x in ipairs({ -1, 1 }) do
		for j = 0, 4 do
			wear(model, "UpperTorso", "Feather", Vector3.new(0.1, (1.7 - j * 0.14) * k, 0.42 * k), CFrame.new(x * (0.55 + j * 0.1) * k, (0.2 - j * 0.24) * k, (0.56 + j * 0.03) * k) * CFrame.Angles(math.rad(12), 0, x * math.rad(8 + j * 5)), j >= 3 and tip or feather, M.SmoothPlastic)
		end
	end
	if look.longTail then
		-- 봉황의 긴 꼬리깃: 땅까지 길게 휘어 흐른다
		for j = -2, 2 do
			local cf = CFrame.new(j * 0.16 * k, -0.1 * k, 0.6 * k) * CFrame.Angles(math.rad(-50), 0, math.rad(j * 9))
			for s = 0, 2 do
				wear(model, "LowerTorso", "TailPlume", Vector3.new(0.18 * k, 1.1 * k, 0.05), cf * CFrame.new(0, -0.55 * k, 0), s == 2 and look.longTail or (j == 0 and crest or feather), M.SmoothPlastic)
				cf = cf * CFrame.new(0, -1.05 * k, 0) * CFrame.Angles(math.rad(-12), 0, 0)
			end
		end
	else
		for j = -2, 2 do
			wear(model, "LowerTorso", "TailFeather", Vector3.new(0.18, 1.1, 0.05) * k, CFrame.new(j * 0.17 * k, -0.4 * k, 0.85 * k) * CFrame.Angles(math.rad(-45), 0, math.rad(j * 10)), tip, M.SmoothPlastic)
		end
	end
	for _, f in ipairs({ "LeftFoot", "RightFoot" }) do
		for j = -1, 1 do
			wear(model, f, "Talon", Vector3.new(0.09, 0.07, 0.28) * k, CFrame.new(j * 0.22 * k, -0.04 * k, -0.52 * k) * CFrame.Angles(0, j * 0.3, 0), dark(beak, 0.35), M.SmoothPlastic)
		end
	end
	if look.fire then
		flame(model, "UpperTorso", look.fire, dark(look.fire, 0.35), (boss and 3.5 or 2) * k, 4)
	end
end

-- 해골: 몸을 지우고 뼈만 남긴다 (팔다리뼈와 관절, 갈비뼈, 등뼈, 골반, 해골 머리)
FORMS.skeleton = function(model, look, k, boss)
	local bone = look.bone or C3(222, 212, 186)
	local shade = dark(bone, 0.25)
	clearFace(model)
	hide(model, { "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg" })
	paint(model, { "Head" }, bone, M.SmoothPlastic)
	hide(model, { "LeftHand", "RightHand", "LeftFoot", "RightFoot" })
	for _, hn in ipairs({ "LeftHand", "RightHand" }) do
		wear(model, hn, "Palm", Vector3.new(0.45, 0.22, 0.35) * k, CFrame.new(0, 0, 0), bone, M.SmoothPlastic)
		for j = -1, 1 do
			wear(model, hn, "Finger", Vector3.new(0.07, 0.36, 0.07) * k, CFrame.new(j * 0.14 * k, -0.24 * k, -0.06 * k) * CFrame.Angles(math.rad(18), 0, 0), bone, M.SmoothPlastic)
		end
	end
	for _, fn in ipairs({ "LeftFoot", "RightFoot" }) do
		wear(model, fn, "FootBone", Vector3.new(0.4, 0.16, 0.85) * k, CFrame.new(0, 0, -0.15 * k), bone, M.SmoothPlastic)
	end
	for _, n in ipairs(LIMBS) do
		local s = sizeOf(model, n)
		wear(model, n, "Bone", Vector3.new(s.Y * 0.92, 0.3 * k, 0.3 * k), UPRIGHT, bone, M.SmoothPlastic, Cyl)
		wear(model, n, "Knob", Vector3.new(0.4, 0.4, 0.4) * k, CFrame.new(0, -s.Y * 0.46, 0), shade, M.SmoothPlastic, Ball)
		if string.find(n, "Upper") then
			wear(model, n, "Joint", Vector3.new(0.46, 0.46, 0.46) * k, CFrame.new(0, s.Y * 0.44, 0), shade, M.SmoothPlastic, Ball)
		end
	end
	local ut = sizeOf(model, "UpperTorso")
	-- 등뼈 (마디 다섯)
	for i = 0, 4 do
		wear(model, "UpperTorso", "Vertebra", Vector3.new(0.3, 0.22, 0.3) * k, CFrame.new(0, (0.65 - i * 0.33) * k, 0.2 * k), shade, M.SmoothPlastic)
	end
	-- 갈비뼈 넷: 옆으로 둘렀다가 앞에서 가슴뼈로 모인다
	for i = 0, 3 do
		local y = (0.5 - i * 0.28) * k
		local w = ut.X * (0.42 - i * 0.03)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "UpperTorso", "RibSide", Vector3.new(0.09 * k, 0.09 * k, ut.Z * 0.75), CFrame.new(x * w, y, -0.05 * k), bone, M.SmoothPlastic)
			wear(model, "UpperTorso", "RibFront", Vector3.new(w * 0.95, 0.09 * k, 0.09 * k), CFrame.new(x * w * 0.5, y - 0.06 * k, -ut.Z * 0.42) * CFrame.Angles(0, 0, x * math.rad(12)), bone, M.SmoothPlastic)
		end
	end
	wear(model, "UpperTorso", "Sternum", Vector3.new(0.14, 1.0, 0.1) * k, CFrame.new(0, 0.15 * k, -ut.Z * 0.44), bone, M.SmoothPlastic)
	wear(model, "UpperTorso", "Collarbone", Vector3.new(ut.X * 1.35, 0.12 * k, 0.12 * k), CFrame.new(0, 0.74 * k, -0.15 * k), bone, M.SmoothPlastic)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "UpperTorso", "ShoulderBlade", Vector3.new(0.6, 0.7, 0.08) * k, CFrame.new(x * 0.45 * k, 0.4 * k, 0.32 * k) * CFrame.Angles(0, 0, x * 0.2), shade, M.SmoothPlastic)
	end
	wear(model, "LowerTorso", "Pelvis", Vector3.new(1.4, 0.4, 0.6) * k, CFrame.new(0, 0, 0), bone, M.SmoothPlastic)
	-- 해골 머리: 눈구멍, 코구멍, 아래턱
	local hs = sizeOf(model, "Head")
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Socket", Vector3.new(0.3, 0.3, 0.08) * k, CFrame.new(x * hs.X * 0.21, hs.Y * 0.06, -hs.Z * 0.49), C3(12, 10, 10), M.SmoothPlastic, Ball)
		wear(model, "Head", "Eye", Vector3.new(0.1, 0.1, 0.06) * k, CFrame.new(x * hs.X * 0.21, hs.Y * 0.06, -hs.Z * 0.52), look.eyes or C3(255, 200, 90), M.Neon, Ball)
	end
	wear(model, "Head", "Nose", Vector3.new(0.12, 0.16, 0.06) * k, CFrame.new(0, -hs.Y * 0.12, -hs.Z * 0.5), C3(12, 10, 10), M.SmoothPlastic)
	wear(model, "Head", "Jaw", Vector3.new(hs.X * 0.62, hs.Y * 0.18, hs.Z * 0.55), CFrame.new(0, -hs.Y * 0.42, -hs.Z * 0.18), shade, M.SmoothPlastic)
	if look.armor then
		-- 왕릉 수호병: 녹슨 청동 투구, 한쪽 어깨받이, 해진 허리 천
		local metal = look.metal or C3(120, 95, 60)
		disc(model, "Head", "Helmet", hs.X * 1.1, hs.Y * 0.36, CFrame.new(0, hs.Y * 0.32, 0), metal, M.Metal)
		wear(model, "Head", "HelmetDome", Vector3.new(hs.X * 1.1, hs.Y * 0.5, hs.Z * 1.1), CFrame.new(0, hs.Y * 0.48, 0), metal, M.Metal, Ball)
		wear(model, "UpperTorso", "Pauldron", Vector3.new(ut.X * 0.42, 0.14 * k, ut.Z * 1.1), CFrame.new(ut.X * 0.5, 0.72 * k, 0) * CFrame.Angles(0, 0, math.rad(-22)), metal, M.Metal)
		for _, z in ipairs({ -1, 1 }) do
			wear(model, "LowerTorso", "Loincloth", Vector3.new(0.8 * k, 1.1 * k, 0.06), CFrame.new(0, -0.6 * k, z * 0.35 * k), look.cloth or C3(90, 30, 25))
		end
	end
	local _ = boss
end

-- 버섯 사람: 자루 빛깔의 몸, 층층이 쌓아 둥근 갓 (겉은 매끈하고 아래는 주름), 갓 위에 붙은 흰 점, 까만 눈
local function mushroomCap(model: Model, partName: string, base: CFrame, R: number, H: number, cap: Color3, gill: Color3, spot: Color3?, spotMat: Enum.Material?, spotAlpha: number?)
	-- 아래 절반은 넓은 원판 다섯 층 (가장자리가 둥글게 말린다), 위 절반은 둥근 공의 윗면 (공의 아래쪽은 원판 속에 숨는다)
	local n = 5
	for i = 0, n - 1 do
		local t = (i + 0.5) / n * 0.5
		local r = R * math.sqrt(1 - t * t)
		disc(model, partName, "Cap", r * 2, H * 0.5 / n + 0.03, base * CFrame.new(0, H * t, 0), cap, M.SmoothPlastic)
	end
	local rTop = R * math.sqrt(1 - 0.25)
	wear(model, partName, "CapTop", Vector3.new(rTop * 2, H, rTop * 2), base * CFrame.new(0, H * 0.5, 0), cap, M.SmoothPlastic, Ball)
	disc(model, partName, "Gills", R * 1.92, 0.06, base * CFrame.new(0, -0.01, 0), gill, M.SmoothPlastic)
	disc(model, partName, "GillRing", R * 1.1, 0.07, base * CFrame.new(0, -0.02, 0), dark(gill, 0.18), M.SmoothPlastic)
	if spot then
		-- 점: 갓 겉면에 붙인 납작한 원 (겉면의 기울기를 따른다)
		local spots = { { 0.95, 0 }, { 0.78, 0.7 }, { 0.8, 2.8 }, { 0.76, 4.8 }, { 0.55, 1.7 }, { 0.58, 3.8 }, { 0.52, 5.7 }, { 0.3, 0.2 }, { 0.32, 2.3 }, { 0.28, 4.3 } }
		for _, sp in ipairs(spots) do
			local t, phi = sp[1], sp[2]
			local pos: Vector3, nrm: Vector3
			if t <= 0.5 then
				local r = R * math.sqrt(1 - t * t)
				pos = Vector3.new(math.cos(phi) * r, H * t, math.sin(phi) * r)
				nrm = Vector3.new(pos.X / (R * R), pos.Y / (H * H), pos.Z / (R * R)).Unit
			else
				-- 위 공: 가운데 높이 H/2, 반지름 rTop, 높이 반지름 H/2
				local u = (t - 0.5) / 0.5
				local r = rTop * math.sqrt(math.max(0, 1 - u * u))
				pos = Vector3.new(math.cos(phi) * r, H * 0.5 + u * H * 0.5, math.sin(phi) * r)
				local hy = pos.Y - H * 0.5
				nrm = Vector3.new(pos.X / (rTop * rTop), hy / (H * H * 0.25), pos.Z / (rTop * rTop))
				nrm = nrm.Magnitude > 1e-4 and nrm.Unit or Vector3.new(0, 1, 0)
			end
			local d = R * (0.34 - math.abs(t - 0.5) * 0.12)
			local at = base * CFrame.lookAt(pos + nrm * 0.03, pos + nrm * 2) * CFrame.Angles(0, math.rad(90), 0)
			local p = wear(model, partName, "Spot", Vector3.new(0.06, d, d), at, spot, spotMat or M.SmoothPlastic, Cyl)
			if p and spotAlpha then
				p.Transparency = spotAlpha
			end
		end
	end
end
FORMS.shroom = function(model, look, k, boss)
	local cap = look.capColor or C3(170, 40, 50)
	local stem = look.skin or C3(232, 222, 198)
	clearFace(model)
	paint(model, { "Head", "UpperTorso" }, stem, M.SmoothPlastic)
	paint(model, ARMS, stem, M.SmoothPlastic)
	paint(model, { "LowerTorso" }, dark(stem, 0.08), M.SmoothPlastic)
	-- 아래로 갈수록 흙 빛깔 (뿌리 쪽)
	paint(model, { "LeftUpperLeg", "RightUpperLeg" }, dark(stem, 0.12), M.SmoothPlastic)
	paint(model, { "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot" }, C3(110, 85, 60), M.SmoothPlastic)
	local hs = sizeOf(model, "Head")
	local R = (look.capSize or 3.0) * k * 0.5
	mushroomCap(model, "Head", CFrame.new(0, hs.Y * 0.34, 0), R, R * 0.62, cap, light(stem, 0.1):Lerp(C3(200, 180, 150), 0.4), look.spot or C3(245, 240, 228), look.spotGlow and M.Neon or nil, look.spotGlow and 0.3 or nil)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.17, 0.2, 0.08) * k, CFrame.new(x * hs.X * 0.2, -hs.Y * 0.08, -hs.Z * 0.48), C3(18, 14, 12), M.SmoothPlastic, Ball)
	end
	-- 허리에 두른 이끼 띠, 몸통의 옅은 세로 결 (버섯 자루의 결)
	local ut0, lt0 = sizeOf(model, "UpperTorso"), sizeOf(model, "LowerTorso")
	wear(model, "LowerTorso", "MossSash", Vector3.new(lt0.X * 1.06, 0.36 * k, lt0.Z * 1.12), CFrame.new(0, 0.05 * k, 0), C3(84, 112, 56), M.Grass)
	for i = -2, 2 do
		wear(model, "UpperTorso", "StemGrain", Vector3.new(0.05 * k, ut0.Y * 0.8, 0.04), CFrame.new(i * ut0.X * 0.17, -ut0.Y * 0.05, -ut0.Z * 0.5 - 0.01), dark(stem, 0.08), M.SmoothPlastic)
	end
	if boss then
		-- 버섯왕: 목의 흰 턱받이 (갓 아래 고리), 어깨와 등에서 돋은 작은 버섯 무리, 어깨를 덮은 이끼 망토
		local ut = sizeOf(model, "UpperTorso")
		disc(model, "Head", "Ring", hs.X * 1.3, 0.12 * k, CFrame.new(0, -hs.Y * 0.45, 0), light(stem, 0.2), M.SmoothPlastic)
		wear(model, "Head", "RingDrape", Vector3.new(hs.X * 1.25, hs.Y * 0.25, hs.Z * 1.25), CFrame.new(0, -hs.Y * 0.56, 0), dark(stem, 0.04), M.SmoothPlastic, Ball)
		local moss = C3(78, 108, 52)
		for _, x in ipairs({ -1, 1 }) do
			wear(model, "UpperTorso", "ShoulderMoss", Vector3.new(ut.X * 0.42, 0.16 * k, ut.Z * 1.15), CFrame.new(x * ut.X * 0.3, ut.Y * 0.5, 0), moss, M.Grass)
		end
		-- 어깨와 등에서 돋은 작은 버섯 (크기가 제각각, 바깥으로 기운다)
		local sprouts = { { -0.46, 0.5, 0.1, 1.0, -0.6 }, { -0.34, 0.5, 0.35, 0.7, -0.3 }, { -0.48, 0.4, -0.25, 0.55, -0.9 }, { 0.44, 0.5, 0.2, 0.85, 0.6 }, { 0.48, 0.4, -0.2, 0.55, 0.9 }, { -0.15, 0.2, 0.52, 0.75, -0.1 }, { 0.2, -0.1, 0.52, 0.6, 0.15 } }
		for _, s in ipairs(sprouts) do
			local x, y, z, sc, tilt = s[1], s[2], s[3], s[4] * 1.15, s[5]
			local at = CFrame.new(x * ut.X, ut.Y * y, z * ut.Z) * CFrame.Angles(z > 0.4 and math.rad(70) or 0, 0, -tilt * 0.6)
			wear(model, "UpperTorso", "SproutStem", Vector3.new(0.55 * sc * k, 0.2 * sc * k, 0.2 * sc * k), at * CFrame.new(0, 0.27 * sc * k, 0) * UPRIGHT, stem, M.SmoothPlastic, Cyl)
			wear(model, "UpperTorso", "SproutCap", Vector3.new(0.8 * sc * k, 0.42 * sc * k, 0.8 * sc * k), at * CFrame.new(0, 0.56 * sc * k, 0), cap, M.SmoothPlastic, Ball)
			wear(model, "UpperTorso", "SproutGill", Vector3.new(0.05, 0.76 * sc * k, 0.76 * sc * k), at * CFrame.new(0, 0.5 * sc * k, 0) * UPRIGHT, C3(205, 185, 155), M.SmoothPlastic, Cyl)
		end
	end
	if look.spore then
		glow(model, "Head", look.spore, 8 * k, 0.8)
	end
end

-- 늪 거한: 굽은 등과 큰 배, 엄니, 늘어진 귀, 등에 붙은 이끼와 물풀, 가죽 허리 천
FORMS.troll = function(model, look, k, boss)
	local skin = look.skin or C3(105, 125, 80)
	clearFace(model)
	paint(model, { "Head", "UpperTorso", "LowerTorso" }, skin, M.SmoothPlastic)
	paint(model, ARMS, skin, M.SmoothPlastic)
	paint(model, LEGS, dark(skin, 0.1), M.SmoothPlastic)
	-- 2.8판: 배와 등의 혹을 몸에 붙게 납작하게 (공이 툭 튀어나온 것처럼 보였다)
	wear(model, "UpperTorso", "Belly", Vector3.new(1.75, 1.2, 0.5) * k, CFrame.new(0, -0.3 * k, -0.4 * k), light(skin, 0.1), M.SmoothPlastic, Ball)
	wear(model, "UpperTorso", "Hump", Vector3.new(1.9, 1.1, 0.7) * k, CFrame.new(0, 0.6 * k, 0.35 * k), dark(skin, 0.1), M.SmoothPlastic, Ball)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Tusk", Vector3.new(0.13, 0.42, 0.13) * k, CFrame.new(x * 0.27 * k, -0.24 * k, -0.6 * k) * CFrame.Angles(math.rad(-10), 0, x * math.rad(14)), C3(232, 222, 196), M.SmoothPlastic)
		wear(model, "Head", "Ear", Vector3.new(0.1, 0.55, 0.32) * k, CFrame.new(x * 0.68 * k, 0.02 * k, 0) * CFrame.Angles(0, 0, -x * math.rad(72)), skin, M.SmoothPlastic)
		wear(model, "Head", "Eye", Vector3.new(0.18, 0.1, 0.06) * k, CFrame.new(x * 0.23 * k, 0.12 * k, -0.6 * k), look.eyes or C3(230, 200, 80), M.SmoothPlastic)
	end
	wear(model, "Head", "Brow", Vector3.new(1.0, 0.18, 0.2) * k, CFrame.new(0, 0.24 * k, -0.56 * k), dark(skin, 0.18), M.SmoothPlastic)
	local moss = C3(70, 105, 42)
	wear(model, "UpperTorso", "Moss", Vector3.new(1.5, 0.2, 0.9) * k, CFrame.new(0, 1.1 * k, 0.45 * k), moss, M.Grass)
	for i = 0, 3 do
		wear(model, "UpperTorso", "Weed", Vector3.new(0.1, 1.0, 0.05) * k, CFrame.new((i - 1.5) * 0.4 * k, 0.4 * k, 0.98 * k) * CFrame.Angles(math.rad(-8), 0, (i - 1.5) * 0.1), dark(moss, 0.15), M.SmoothPlastic)
	end
	wear(model, "LowerTorso", "Loincloth", Vector3.new(1.1 * k, 1.0 * k, 0.08), CFrame.new(0, -0.55 * k, -0.52 * k), LEATHER, M.Leather)
	wear(model, "LowerTorso", "Belt", Vector3.new(2.05 * k, 0.3 * k, 1.12 * k), CFrame.new(0, 0.05 * k, 0), dark(LEATHER, 0.2), M.Leather)
	local _ = boss
end

-- 뱀 자객: 다리 대신 땅을 따라 굽이치는 꼬리, 머리 뒤로 펼친 목덜미, 배의 비늘 띠, 갈라진 혀
FORMS.naga = function(model, look, k, boss)
	local scale = look.skin or C3(60, 105, 60)
	local belly = look.belly or C3(196, 190, 125)
	clearFace(model)
	hide(model, LEGS)
	paint(model, { "Head", "UpperTorso", "LowerTorso" }, scale, M.SmoothPlastic)
	paint(model, ARMS, scale, M.SmoothPlastic)
	wear(model, "Head", "Hood", Vector3.new(2.1, 1.7, 0.14) * k, CFrame.new(0, 0.05 * k, 0.42 * k), dark(scale, 0.2), M.SmoothPlastic, Ball)
	wear(model, "Head", "HoodMark", Vector3.new(0.7, 0.5, 0.05) * k, CFrame.new(0, 0.1 * k, 0.5 * k), belly, M.SmoothPlastic, Ball)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.24, 0.12, 0.06) * k, CFrame.new(x * 0.24 * k, 0.1 * k, -0.6 * k), look.eyes or C3(235, 210, 60), M.Neon)
		wear(model, "Head", "Tongue", Vector3.new(0.04, 0.04, 0.32) * k, CFrame.new(x * 0.04 * k, -0.3 * k, -0.84 * k) * CFrame.Angles(0, x * math.rad(14), 0), C3(190, 40, 60), M.SmoothPlastic)
	end
	for i = 0, 3 do
		wear(model, "UpperTorso", "BellyScale", Vector3.new(1.15 - i * 0.1, 0.2, 0.06) * k, CFrame.new(0, (0.5 - i * 0.34) * k, -0.52 * k), belly, M.SmoothPlastic)
	end
	-- 2.8판: 꼬리가 공 아홉이 줄 선 것처럼 끊겨 보였다. 마디를 촘촘히 겹치고 빛깔을 한 가지로 (배 비늘만 옅게) 매끈하게 굽이친다
	local cf = CFrame.new(0, -0.7 * k, 0.1 * k)
	local n = 14
	for j = 0, n - 1 do
		local u = j / (n - 1)
		local w = (1.4 * (1 - u) ^ 0.8 + 0.22) * k
		wear(model, "LowerTorso", "Coil", Vector3.new(w, w * 0.8, w * 1.6), cf, dark(scale, u * 0.1), M.SmoothPlastic, Ball)
		wear(model, "LowerTorso", "CoilBelly", Vector3.new(w * 0.72, w * 0.3, w * 1.4), cf * CFrame.new(0, -w * 0.3, 0), belly, M.SmoothPlastic, Ball)
		local sway = math.sin(u * math.pi * 2.2) * 0.22
		cf = cf * CFrame.new(0, (j < 3 and -0.42 or -0.01) * k, 0.45 * k) * CFrame.Angles(0, sway * 0.5, 0)
	end
	local _ = boss
end

-- 늑대 무사: 털 몸, 늑대 머리 (주둥이·세운 귀), 목의 갈기, 가죽 어깨끈과 허리 천, 꼬리, 발톱
FORMS.wolf = function(model, look, k, boss)
	local fur = look.fur or C3(80, 70, 65)
	local pale = look.pale or light(fur, 0.35)
	clearFace(model)
	paint(model, { "Head", "UpperTorso", "LowerTorso" }, fur, M.Fabric)
	paint(model, ARMS, fur, M.Fabric)
	paint(model, LEGS, dark(fur, 0.12), M.Fabric)
	wear(model, "Head", "Snout", Vector3.new(0.58, 0.48, 0.9) * k, CFrame.new(0, -0.15 * k, -0.74 * k), fur, M.Fabric)
	wear(model, "Head", "Muzzle", Vector3.new(0.5, 0.22, 0.85) * k, CFrame.new(0, -0.34 * k, -0.72 * k), pale, M.Fabric)
	wear(model, "Head", "Nose", Vector3.new(0.24, 0.16, 0.12) * k, CFrame.new(0, -0.02 * k, -1.18 * k), C3(15, 10, 10), M.SmoothPlastic)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Ear", Vector3.new(0.3, 0.55, 0.12) * k, CFrame.new(x * 0.34 * k, 0.68 * k, 0.05 * k) * CFrame.Angles(0, 0, -x * math.rad(12)), fur, M.Fabric)
		wear(model, "Head", "Eye", Vector3.new(0.2, 0.09, 0.06) * k, CFrame.new(x * 0.25 * k, 0.15 * k, -0.6 * k) * CFrame.Angles(0, 0, x * math.rad(-15)), look.eyes or C3(230, 180, 60), M.Neon)
	end
	-- 갈기: 목과 어깨를 두르는 한 덩어리의 털 (사자는 머리 둘레까지 크게)
	wear(model, "UpperTorso", "Ruff", Vector3.new(2.2, 0.9, 1.4) * k, CFrame.new(0, 0.72 * k, 0.05 * k), pale, M.Fabric, Ball)
	if look.lion then
		-- 얼굴은 드러나고, 머리 둘레와 뒤를 덮는다
		wear(model, "Head", "Mane", Vector3.new(2.1, 2.1, 1.1) * k, CFrame.new(0, 0.05 * k, 0.55 * k), dark(pale, 0.18), M.Fabric, Ball)
		wear(model, "Head", "Mane2", Vector3.new(1.75, 1.8, 0.9) * k, CFrame.new(0, 0.12 * k, 0.32 * k), pale, M.Fabric, Ball)
	end
	-- 가죽 어깨끈 (비스듬히)과 허리 천
	wear(model, "UpperTorso", "Strap", Vector3.new(0.26 * k, 2.0 * k, 1.08 * k), CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(35)), LEATHER, M.Leather)
	wear(model, "LowerTorso", "Belt", Vector3.new(2.06 * k, 0.3 * k, 1.1 * k), CFrame.new(0, 0.05 * k, 0), LEATHER, M.Leather)
	wear(model, "LowerTorso", "Loincloth", Vector3.new(0.9 * k, 0.9 * k, 0.07), CFrame.new(0, -0.5 * k, -0.54 * k), look.cloth or C3(90, 30, 30))
	local prev = CFrame.new(0, 0, 0.5 * k)
	for j = 1, 4 do
		local seg = prev * CFrame.Angles(math.rad(j == 1 and -60 or 16), 0, 0) * CFrame.new(0, -0.3 * k, 0)
		wear(model, "LowerTorso", "Tail", Vector3.new(0.42 - j * 0.04, 0.72, 0.42 - j * 0.04) * k * (look.lion and 0.7 or 1), seg, j == 4 and (look.lion and dark(pale, 0.3) or pale) or fur, M.Fabric)
		prev = seg * CFrame.new(0, -0.3 * k, 0)
	end
	for _, hn in ipairs({ "LeftHand", "RightHand" }) do
		for j = -1, 1 do
			wear(model, hn, "Claw", Vector3.new(0.07, 0.35, 0.07) * k, CFrame.new(j * 0.2 * k, -0.3 * k, -0.14 * k) * CFrame.Angles(math.rad(25), 0, 0), C3(230, 220, 205), M.SmoothPlastic)
		end
	end
	if look.scarf then
		-- 혈랑: 목에서 뒤로 휘날리는 핏빛 목도리
		for i = 0, 2 do
			wear(model, "UpperTorso", "Scarf", Vector3.new((1.3 - i * 0.2) * k, 0.36 * k, 0.08), CFrame.new(0, (0.7 - i * 0.38) * k, (0.62 + i * 0.1) * k) * CFrame.Angles(math.rad(22 + i * 10), 0, 0), look.scarf)
		end
	end
	local _ = boss
end

------------------------------------------------------------------------
-- 생김새 표 (적마다 하나). 사람은 top / bottom / trim (윗옷·아랫옷·끈) 세 빛깔
------------------------------------------------------------------------
local LOOKS: { [string]: any } = {
	-- 마을 둘레
	thug = { head = "bald", beard = "stubble", top = C3(140, 122, 96), bottom = C3(78, 68, 54), trim = C3(96, 78, 58), sleeves = false, build = { w = 1.1, head = 0.9 } },
	bandit = { head = "bandana", beard = "full", top = C3(115, 88, 62), bottom = C3(58, 48, 40), trim = C3(140, 42, 36), build = { head = 0.9 } },
	spearman = { head = "straw", top = C3(64, 84, 112), bottom = C3(42, 50, 66), trim = C3(196, 180, 140), build = { h = 1.04, head = 0.88 } },
	brute = { head = "bald", beard = "full", scar = true, top = C3(104, 62, 50), bottom = C3(50, 36, 30), trim = C3(70, 48, 36), sleeves = false, headband = C3(130, 40, 30), build = { w = 1.38, h = 1.08, head = 0.85 } },
	assassin = { head = "hood", mask = C3(28, 28, 34), top = C3(32, 32, 40), bottom = C3(22, 22, 28), trim = C3(70, 70, 82), build = { w = 0.88, h = 1.05, head = 0.86 } },
	shadowblade = { head = "hood", mask = C3(22, 18, 30), eyes = C3(180, 120, 240), top = C3(28, 22, 38), bottom = C3(16, 12, 22), trim = C3(86, 60, 130), build = { w = 0.9, h = 1.06, head = 0.86 } },
	ironguard = { head = "helmet", metal = IRON, armor = true, top = C3(70, 72, 82), bottom = C3(40, 40, 48), trim = C3(140, 40, 36), build = { w = 1.18, h = 1.05, head = 0.88 } },
	simma = { head = "horns", skin = C3(96, 70, 110), eyes = C3(210, 120, 240), hornColor = C3(40, 26, 44), top = C3(40, 16, 50), bottom = C3(22, 8, 28), trim = C3(120, 70, 150), robe = C3(36, 12, 46), build = { h = 1.08, head = 0.88 } },
	gatekeeper = { head = "helmet", metal = C3(170, 140, 80), armor = true, armorTrim = GOLD, eyes = C3(255, 220, 140), top = C3(70, 50, 30), bottom = C3(36, 28, 18), trim = GOLD, robe = C3(70, 50, 30), build = { w = 1.2, h = 1.1, head = 0.86 } },
	iceguard = { head = "helmet", metal = C3(160, 196, 220), armor = true, top = C3(150, 190, 220), bottom = C3(80, 110, 140), trim = C3(230, 240, 250), build = { w = 1.18, h = 1.05, head = 0.88 } },
	snowblade = { head = "hood", mask = C3(200, 208, 220), top = C3(222, 228, 238), bottom = C3(150, 160, 176), trim = C3(120, 150, 190), build = { w = 0.88, h = 1.05, head = 0.86 } },
	marauder = { head = "bandana", beard = "full", armor = true, metal = C3(120, 96, 72), top = C3(140, 92, 54), bottom = C3(88, 60, 40), trim = C3(170, 130, 70), build = { w = 1.1, head = 0.9 } },
	lancer = { head = "straw", hat = C3(170, 140, 90), mask = C3(160, 130, 95), top = C3(160, 116, 72), bottom = C3(98, 70, 46), trim = C3(120, 60, 40), build = { h = 1.05, head = 0.88 } },
	pirate = { head = "bandana", beard = "full", eyepatch = true, top = C3(50, 68, 106), bottom = C3(40, 40, 50), trim = C3(160, 34, 34), build = { w = 1.05, head = 0.9 } },
	cultist = { head = "hood", mask = C3(130, 20, 30), top = C3(104, 16, 26), bottom = C3(30, 10, 12), trim = C3(40, 10, 14), robe = C3(84, 12, 20), build = { head = 0.88 } },
	cultelder = { head = "hood", beard = "white", eyes = C3(240, 80, 70), top = C3(66, 8, 16), bottom = C3(22, 5, 8), trim = C3(170, 130, 70), robe = C3(56, 6, 12), build = { h = 1.04, head = 0.88 } },
	apostle = { head = "hood", eyes = C3(190, 110, 250), top = C3(24, 12, 40), bottom = C3(12, 6, 22), trim = C3(120, 80, 190), robe = C3(18, 8, 30), crown = C3(130, 90, 200), build = { h = 1.08, head = 0.86 } },
	skyguard = { head = "helmet", metal = C3(225, 228, 240), armor = true, plume = C3(110, 150, 220), top = C3(230, 234, 248), bottom = C3(160, 180, 220), trim = C3(110, 150, 220), build = { w = 1.15, h = 1.08, head = 0.88 } },
	starblade = { head = "hood", mask = C3(30, 36, 64), eyes = C3(220, 232, 255), top = C3(36, 46, 84), bottom = C3(24, 30, 58), trim = C3(200, 210, 250), build = { w = 0.9, h = 1.06, head = 0.86 } },
	fallsguard = { head = "helmet", metal = C3(90, 130, 120), armor = true, plume = C3(200, 230, 240), top = C3(80, 126, 110), bottom = C3(40, 68, 60), trim = C3(200, 226, 230), build = { w = 1.15, h = 1.06, head = 0.88 } },
	frostguard = { head = "helmet", metal = C3(190, 220, 240), armor = true, top = C3(196, 222, 245), bottom = C3(90, 126, 176), trim = C3(240, 248, 255), build = { w = 1.15, h = 1.06, head = 0.88 } },
	mapleblade = { head = "straw", hat = C3(150, 60, 30), top = C3(200, 90, 44), bottom = C3(86, 40, 26), trim = C3(240, 190, 90), build = { w = 0.92, h = 1.04, head = 0.88 } },
	maplemonk = { head = "bald", beads = C3(90, 50, 30), top = C3(186, 124, 54), bottom = C3(84, 58, 32), trim = C3(140, 60, 30), robe = C3(170, 110, 46), build = { w = 1.3, h = 1.06, head = 0.86 } },
	teaguard = { head = "straw", top = C3(104, 150, 86), bottom = C3(60, 80, 50), trim = C3(220, 210, 170), build = { head = 0.9 } },
	teasage = { head = "topknot", hair = WHITE_HAIR, beard = "white", top = C3(220, 232, 210), bottom = C3(96, 122, 82), trim = C3(110, 150, 90), robe = C3(208, 224, 198), build = { h = 1.04, head = 0.88 } },
	-- 천상계
	cloudguard = { head = "helmet", metal = C3(225, 232, 244), plume = C3(150, 186, 236), top = C3(232, 238, 250), bottom = C3(156, 176, 216), trim = C3(150, 186, 236), build = { h = 1.06, head = 0.88 } },
	thunderguard = { head = "helmet", metal = C3(76, 86, 140), plume = C3(160, 196, 255), armor = true, eyes = C3(160, 200, 255), top = C3(70, 80, 136), bottom = C3(40, 45, 80), trim = C3(220, 200, 120), build = { w = 1.18, h = 1.06, head = 0.86 } },
	starsage = { head = "hood", beard = "white", eyes = C3(200, 170, 255), top = C3(66, 46, 128), bottom = C3(30, 20, 60), trim = C3(220, 200, 140), robe = C3(54, 36, 108), build = { h = 1.05, head = 0.86 } },
	throneguard = { head = "helmet", metal = C3(226, 196, 120), plume = C3(200, 56, 48), armor = true, top = C3(246, 232, 190), bottom = C3(176, 146, 80), trim = C3(200, 56, 48), build = { w = 1.2, h = 1.08, head = 0.86 } },
	throneblade = { head = "topknot", hair = C3(30, 25, 20), mask = C3(240, 232, 214), top = C3(250, 242, 220), bottom = C3(150, 120, 60), trim = C3(200, 160, 80), build = { w = 0.9, h = 1.06, head = 0.86 } },
	-- 2.7판: 천상의 새 세 섬
	jukgeom = { head = "straw", hat = C3(170, 190, 120), top = C3(104, 146, 86), bottom = C3(48, 66, 40), trim = C3(220, 214, 170), mask = C3(90, 120, 70), build = { w = 0.9, h = 1.05, head = 0.86 } },
	jukseon = { head = "topknot", hair = WHITE_HAIR, beard = "white", top = C3(206, 220, 176), bottom = C3(80, 100, 60), trim = C3(110, 150, 80), robe = C3(190, 206, 160), build = { h = 1.05, head = 0.86 } },
	lakeguard = { head = "helmet", metal = C3(170, 186, 214), plume = C3(220, 230, 255), armor = true, top = C3(70, 90, 130), bottom = C3(30, 40, 70), trim = C3(210, 220, 240), build = { w = 1.15, h = 1.06, head = 0.88 } },
	goldmonk = { head = "bald", beads = C3(110, 60, 30), top = C3(232, 172, 62), bottom = C3(140, 80, 30), trim = C3(170, 40, 30), robe = C3(220, 160, 56), sleeves = false, build = { w = 1.3, h = 1.06, head = 0.86 } },
	jukwang = { head = "topknot", hair = C3(40, 50, 30), beard = "full", top = C3(100, 142, 84), bottom = C3(46, 64, 38), trim = C3(226, 216, 160), robe = C3(84, 124, 70), build = { w = 1.1, h = 1.06, head = 0.95 } },
	wolyeong = { head = "hood", hoodColor = C3(228, 234, 250), crown = C3(210, 220, 245), gem = C3(200, 230, 255), eyes = C3(220, 235, 255), top = C3(226, 232, 250), bottom = C3(90, 100, 150), trim = C3(170, 186, 230), robe = C3(200, 210, 238), build = { h = 1.08, head = 0.95 } },
	geumgang = { head = "bald", beads = C3(120, 60, 30), headband = C3(240, 200, 90), armor = true, metal = C3(230, 186, 80), armorTrim = C3(255, 230, 150), eyes = C3(255, 230, 150), top = C3(236, 176, 60), bottom = C3(140, 80, 30), trim = C3(180, 40, 30), sleeves = false, build = { w = 1.3, h = 1.06, head = 0.95 } },
	-- 사람이 아닌 적
	swampfang = { form = "naga", skin = C3(64, 104, 60), eyes = C3(230, 210, 60), build = { w = 0.9, h = 1.05, head = 0.86 } },
	bogbrute = { form = "troll", skin = C3(108, 126, 82), build = { w = 1.4, h = 1.08, head = 0.85 } },
	riftling = { form = "imp", skin = C3(96, 72, 132), eyes = C3(220, 150, 255), hornColor = C3(30, 20, 40), spark = C3(170, 110, 255), build = { w = 0.85, h = 0.95, head = 0.9 } },
	flameimp = { form = "imp", skin = C3(170, 66, 46), eyes = C3(255, 220, 90), hornColor = C3(50, 26, 22), fire = C3(255, 130, 40), build = { w = 0.85, h = 0.95, head = 0.92 } },
	thunderimp = { form = "imp", skin = C3(104, 120, 190), eyes = C3(230, 240, 255), hornColor = C3(220, 220, 190), spark = C3(170, 200, 255), build = { w = 0.85, h = 0.95, head = 0.9 } },
	voidwalker = { form = "wraith", cloth = C3(30, 24, 48), eyes = C3(130, 220, 255), bone = C3(44, 36, 58), build = { h = 1.1, w = 0.9, head = 0.86 } },
	sandwraith = { form = "wraith", cloth = C3(200, 176, 132), eyes = C3(255, 220, 140), build = { w = 0.88, h = 1.06, head = 0.86 } },
	stonegolem = { form = "golem", skin = C3(150, 146, 138), eyes = C3(255, 196, 120), carved = true, build = { w = 1.45, h = 1.15, head = 0.8 } },
	stonewarden = { form = "golem", skin = C3(118, 124, 112), eyes = C3(180, 240, 150), moss = C3(74, 110, 52) },
	magmabrute = { form = "golem", skin = C3(52, 34, 30), eyes = C3(255, 150, 50), ember = C3(255, 120, 30), lava = true, build = { w = 1.42, h = 1.1, head = 0.84 } },
	meteorguard = { form = "golem", skin = C3(56, 56, 74), eyes = C3(150, 200, 255), ember = C3(130, 180, 255) },
	tombguard = { form = "skeleton", eyes = C3(255, 200, 90), armor = true, metal = C3(120, 96, 58), cloth = C3(96, 34, 28), build = { w = 1.15, h = 1.05, head = 0.88 } },
	waterspirit = { form = "spirit", skin = C3(96, 168, 240), eyes = C3(235, 248, 255), crest = "water" },
	icespirit = { form = "spirit", skin = C3(176, 218, 248), eyes = C3(225, 248, 255), crest = "ice" },
	karstsprite = { form = "spirit", skin = C3(132, 138, 124), eyes = C3(190, 240, 160), crest = "moss", solid = true, moss = C3(80, 116, 58) },
	starspirit = { form = "spirit", skin = C3(140, 112, 220), eyes = C3(255, 238, 200), crest = "star" },
	moonspirit = { form = "spirit", skin = C3(210, 222, 250), eyes = C3(255, 255, 255), crest = "star" },
	guardlion = { form = "wolf", fur = C3(214, 170, 84), pale = C3(240, 214, 150), eyes = C3(255, 200, 80), lion = true, cloth = C3(170, 40, 30), build = { w = 1.25, h = 1.0, head = 0.95 } },
	cranesword = { form = "bird", feather = C3(244, 244, 240), crest = C3(206, 36, 36), beak = C3(210, 190, 140), tip = C3(30, 30, 34), build = { w = 0.88, h = 1.06, head = 0.86 } },
	craneguard = { form = "bird", feather = C3(236, 236, 232), crest = C3(196, 30, 30), beak = C3(210, 190, 140), tip = C3(30, 30, 34) },
	cranemaster = { form = "bird", feather = C3(214, 232, 240), crest = C3(40, 120, 150), beak = C3(220, 196, 130), tip = C3(36, 70, 90) },
	phoenixguard = { form = "bird", feather = C3(236, 120, 50), crest = C3(255, 210, 80), beak = C3(240, 196, 70), tip = C3(170, 40, 30), longCrest = true, longTail = C3(255, 200, 70) },
	flamesage = { form = "bird", feather = C3(220, 84, 44), crest = C3(255, 196, 80), beak = C3(240, 190, 70), tip = C3(140, 30, 20), longCrest = true, fire = C3(255, 130, 40) },
	shroombrute = { form = "shroom", capColor = C3(176, 36, 40), capSize = 3.6, build = { w = 1.2 } },
	sporeimp = { form = "shroom", capColor = C3(116, 66, 156), skin = C3(214, 204, 222), capSize = 2.6, spot = C3(210, 180, 255), spotGlow = true, spore = C3(200, 160, 255) },
	-- 보스
	heukho = { head = "topknot", hair = DARK_HAIR, beard = "full", scar = true, armor = true, metal = C3(52, 48, 46), top = C3(36, 30, 30), bottom = C3(70, 24, 22), trim = C3(150, 40, 30), build = { w = 1.2, head = 0.95 } },
	bingma = { head = "helmet", metal = C3(186, 220, 244), beard = "white", eyes = C3(160, 220, 255), top = C3(200, 228, 252), bottom = C3(80, 110, 150), trim = C3(240, 248, 255), robe = C3(110, 140, 180), build = { w = 1.15, head = 0.95 } },
	bingje = { head = "helmet", metal = C3(200, 232, 250), armor = true, armorTrim = C3(240, 250, 255), eyes = C3(170, 230, 255), top = C3(190, 225, 252), bottom = C3(60, 100, 160), trim = C3(240, 250, 255), build = { w = 1.18, head = 0.95 } },
	hyeolma = { head = "topknot", hair = C3(120, 12, 20), longHair = true, eyes = C3(240, 50, 50), top = C3(140, 4, 22), bottom = C3(24, 2, 6), trim = C3(40, 6, 10), robe = C3(110, 0, 16), build = { h = 1.05, head = 0.95 } },
	cheonma = { head = "horns", hair = C3(20, 10, 30), hornColor = C3(28, 18, 34), hornLen = 1.5, eyes = C3(200, 100, 255), top = C3(30, 14, 52), bottom = C3(12, 2, 22), trim = C3(130, 80, 190), robe = C3(24, 10, 44), crown = C3(110, 70, 170), build = { h = 1.08, head = 0.95 } },
	yeomje = { head = "topknot", hair = C3(170, 52, 20), beard = "full", eyes = C3(255, 170, 60), crown = GOLD, armor = true, metal = C3(150, 70, 32), armorTrim = GOLD, top = C3(220, 90, 30), bottom = C3(80, 22, 12), trim = GOLD, build = { w = 1.2, head = 0.95 } },
	sawang = { head = "wrap", eyes = C3(255, 220, 130), top = C3(206, 168, 76), bottom = C3(90, 62, 32), trim = C3(40, 90, 160), robe = C3(150, 110, 44), build = { h = 1.06, head = 0.95 } },
	cheonmun = { head = "helmet", metal = C3(236, 238, 248), plume = C3(220, 180, 90), armor = true, armorTrim = GOLD, eyes = C3(255, 240, 190), top = C3(236, 240, 252), bottom = C3(116, 146, 206), trim = GOLD, build = { w = 1.2, h = 1.08, head = 0.95 } },
	noeje = { head = "helmet", metal = C3(70, 80, 150), plume = C3(150, 196, 255), armor = true, armorTrim = C3(220, 196, 110), beard = "full", eyes = C3(160, 210, 255), top = C3(60, 70, 146), bottom = C3(25, 30, 70), trim = C3(220, 196, 110), build = { w = 1.2, head = 0.95 } },
	seonggun = { head = "hood", hoodColor = C3(90, 56, 170), crown = C3(220, 196, 255), gem = C3(255, 240, 200), eyes = C3(230, 200, 255), top = C3(104, 66, 196), bottom = C3(35, 20, 70), trim = C3(230, 210, 150), robe = C3(64, 34, 124), build = { h = 1.06, head = 0.95 } },
	cheonjon = { head = "topknot", hair = WHITE_HAIR, beard = "white", crown = GOLD, gem = C3(255, 230, 160), armor = true, metal = C3(236, 210, 140), armorTrim = GOLD, eyes = C3(255, 240, 190), top = C3(250, 244, 220), bottom = C3(200, 160, 72), trim = GOLD, robe = C3(226, 206, 156), build = { w = 1.15, h = 1.06, head = 0.95 } },
	cheongeop = { head = "horns", hair = C3(16, 10, 22), hornColor = C3(20, 14, 26), hornLen = 1.7, eyes = C3(170, 90, 255), top = C3(40, 30, 60), bottom = C3(15, 10, 25), trim = C3(110, 60, 170), robe = C3(28, 20, 44), build = { w = 1.1, head = 0.95 } },
	pungyeop = { head = "topknot", hair = C3(110, 40, 20), top = C3(214, 84, 34), bottom = C3(106, 36, 22), trim = C3(246, 180, 70), robe = C3(190, 70, 30), build = { h = 1.04, head = 0.95 } },
	dason = { head = "topknot", hair = WHITE_HAIR, beard = "white", top = C3(226, 236, 216), bottom = C3(100, 138, 88), trim = C3(110, 150, 90), robe = C3(212, 226, 200), build = { h = 1.04, head = 0.95 } },
	pokryong = { head = "topknot", hair = C3(30, 50, 80), top = C3(86, 156, 216), bottom = C3(30, 70, 110), trim = C3(220, 240, 255), robe = C3(60, 120, 180), build = { h = 1.06, head = 0.95 } },
	unmugun = { head = "hood", hoodColor = C3(230, 236, 248), eyes = C3(200, 220, 255), top = C3(206, 218, 240), bottom = C3(80, 95, 140), trim = C3(160, 180, 220), robe = C3(190, 204, 232), build = { h = 1.06, head = 0.95 } },
	hyeolrang = { form = "wolf", fur = C3(84, 30, 32), pale = C3(150, 120, 110), eyes = C3(255, 70, 60), scarf = C3(150, 14, 24), build = { w = 0.92, h = 1.05, head = 0.85 } },
	seokwang = { form = "golem", skin = C3(96, 98, 92), eyes = C3(255, 196, 110), moss = C3(70, 104, 50) },
	gyunwang = { form = "shroom", capColor = C3(160, 26, 36), capSize = 3.8, spore = C3(255, 200, 200) },
	yeombong = { form = "bird", feather = C3(240, 110, 40), crest = C3(255, 220, 90), beak = C3(240, 196, 70), tip = C3(170, 36, 24), longCrest = true, longTail = C3(255, 210, 80), fire = C3(255, 150, 50) },
	seonhak = { form = "bird", feather = C3(250, 250, 248), crest = C3(204, 34, 34), beak = C3(214, 196, 150), tip = C3(28, 28, 32), longTail = C3(30, 30, 34) },
}
local DEFAULT_LOOK = { head = "topknot", hair = DARK_HAIR, build = { head = 0.9 } }
function Dress.lookOf(typeId: string, _isBoss: boolean): any
	if LOOKS[typeId] then
		return LOOKS[typeId]
	end
	if string.sub(typeId, 1, 6) == "trial_" then
		return { head = "topknot", hair = DARK_HAIR, robe = C3(70, 60, 50), build = { head = 0.88 } }
	end
	return DEFAULT_LOOK
end

------------------------------------------------------------------------
-- 보스마다 하나뿐인 표식 (적당히: 몸에 붙는 것 한두 가지)
------------------------------------------------------------------------
local SIG: { [string]: (Model, any, number, any) -> () } = {}
-- 머리 뒤의 둥근 광배 (조각을 촘촘히 이어 하나의 고리로)
local function halo(model: Model, color: Color3, k: number, r: number, mat: Enum.Material?)
	local n = 28
	local ut = sizeOf(model, "UpperTorso")
	local center = CFrame.new(0, ut.Y * 0.5 + 1.0 * k, ut.Z * 0.75)
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		local seg = 2 * math.pi * r * k / n + 0.05
		wear(model, "UpperTorso", "Halo", Vector3.new(0.16 * k, seg, 0.16 * k), center * CFrame.new(math.cos(a) * r * k, math.sin(a) * r * k, 0) * CFrame.Angles(0, 0, a), color, mat or M.Metal)
	end
end
SIG.heukho = function(model, look, k, P)
	-- 흑호: 호랑이 가죽을 머리와 어깨에 뒤집어썼다 (줄무늬, 귀), 이빨 목걸이
	local hs = sizeOf(model, "Head")
	local tiger, stripe = C3(206, 118, 44), C3(28, 22, 18)
	wear(model, "Head", "Pelt", Vector3.new(hs.X * 1.14, hs.Y * 0.6, hs.Z * 1.18), CFrame.new(0, hs.Y * 0.34, hs.Z * 0.1), tiger, M.Fabric, Ball)
	for i = -1, 1 do
		wear(model, "Head", "PeltStripe", Vector3.new(0.1 * k, hs.Y * 0.36, hs.Z * 1.0), CFrame.new(i * hs.X * 0.24, hs.Y * 0.46, hs.Z * 0.12), stripe)
	end
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "PeltEar", Vector3.new(0.36, 0.32, 0.12) * k, CFrame.new(x * hs.X * 0.36, hs.Y * 0.68, 0), tiger, M.Fabric, Ball)
	end
	mantle(model, tiger, C3(240, 232, 214), k, 3.0)
	local ut = sizeOf(model, "UpperTorso")
	local top = CFrame.new(0, ut.Y * 0.5, ut.Z * 0.6) * CFrame.Angles(math.rad(6), 0, 0)
	for i = 0, 2 do
		wear(model, "UpperTorso", "MantleStripe", Vector3.new(ut.X * 0.9, 0.14 * k, 0.11 * k), top * CFrame.new(0, -(0.5 + i * 0.85) * k, 0.01), stripe)
	end
	for i = -2, 2 do
		wear(model, "UpperTorso", "Fang", Vector3.new(0.12, 0.34, 0.12) * k, CFrame.new(i * 0.24 * k, ut.Y * 0.36 - math.abs(i) * 0.07 * k, -ut.Z * 0.56) * CFrame.Angles(0, 0, i * 0.18), C3(238, 228, 206), M.SmoothPlastic)
	end
	local _ = P
end
SIG.bingma = function(model, look, k, P)
	-- 빙마: 흰 털 목둘레와 옅은 푸른 망토, 투구 위의 얼음 결 셋
	mantle(model, C3(120, 150, 190), C3(240, 244, 248), k, 3.2)
	local hs = sizeOf(model, "Head")
	for j = -1, 1 do
		wear(model, "Head", "IceCrest", Vector3.new(0.14, 0.7 - math.abs(j) * 0.25, 0.14) * k, CFrame.new(j * hs.X * 0.22, hs.Y * 0.82, 0) * CFrame.Angles(0, 0, -j * 0.25), C3(210, 240, 255), M.Glass)
	end
	local _ = P
end
SIG.bingje = function(model, look, k, P)
	-- 빙제: 얼음 결이 솟은 관 (투명), 흰 망토
	local hs = sizeOf(model, "Head")
	for i = 0, 6 do
		local a = (i / 6 - 0.5) * math.pi * 0.9
		wear(model, "Head", "IceCrown", Vector3.new(0.14, (0.9 - math.abs(i - 3) * 0.15), 0.14) * k, CFrame.new(math.sin(a) * hs.X * 0.5, hs.Y * 0.8, -math.cos(a) * hs.Z * 0.3) * CFrame.Angles(0, 0, -a * 0.3), C3(210, 242, 255), M.Glass)
	end
	mantle(model, C3(236, 244, 252), C3(200, 230, 250), k, 3.4)
	local _ = P
end
SIG.hyeolma = function(model, look, k, P)
	-- 혈마: 핏빛 망토와 손끝의 붉은 손톱
	mantle(model, C3(110, 0, 16), C3(30, 4, 8), k, 3.4)
	for _, side in ipairs({ "LeftHand", "RightHand" }) do
		for j = -1, 1 do
			wear(model, side, "Nail", Vector3.new(0.09, 0.5, 0.09) * k, CFrame.new(j * 0.22 * k, -0.4 * k, -0.15 * k) * CFrame.Angles(math.rad(22), 0, 0), C3(170, 10, 26), M.SmoothPlastic)
		end
	end
	local _ = P
end
SIG.cheonma = function(model, look, k, P)
	mantle(model, C3(24, 10, 44), C3(70, 40, 110), k, 3.4)
	local _ = P
end
SIG.cheongeop = function(model, look, k, P)
	mantle(model, C3(20, 14, 30), C3(60, 36, 90), k, 3.6)
	local _ = P
end
SIG.yeomje = function(model, look, k, P)
	-- 염제: 관 위에서 타오르는 진짜 불과 붉은 망토
	mantle(model, C3(150, 40, 16), GOLD, k, 3.0)
	flame(model, "Head", C3(255, 140, 40), C3(200, 40, 10), 3 * k, 8)
	local _ = P
end
SIG.sawang = function(model, look, k, P)
	-- 사왕: 머리를 감은 천 위에 층층이 쌓은 금테와 청옥, 모래빛 망토
	local hs = sizeOf(model, "Head")
	for j = 0, 2 do
		disc(model, "Head", "TurbanBand", hs.X * (1.08 - j * 0.12), hs.Y * 0.18, CFrame.new(0, hs.Y * (0.42 + j * 0.16), 0), j == 1 and C3(206, 168, 76) or C3(222, 206, 160))
	end
	wear(model, "Head", "Jewel", Vector3.new(0.3, 0.3, 0.1) * k, CFrame.new(0, hs.Y * 0.52, -hs.Z * 0.54), C3(50, 120, 200), M.Glass, Ball)
	mantle(model, C3(150, 110, 44), C3(222, 206, 160), k, 3.0)
	local _ = P
end
SIG.cheonmun = function(model, look, k, P)
	mantle(model, C3(80, 110, 180), C3(236, 238, 248), k, 3.4)
	halo(model, C3(230, 200, 120), k, 1.25)
	local _ = P
end
SIG.noeje = function(model, look, k, P)
	-- 뇌제: 등 뒤의 나무 고리에 매단 천둥 북 여섯 (고리가 어깨에 걸려 있다)
	local ut = sizeOf(model, "UpperTorso")
	local center = CFrame.new(0, ut.Y * 0.5 + 0.4 * k, ut.Z * 0.9)
	local R = 1.9 * k
	local n = 30
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		wear(model, "UpperTorso", "DrumRing", Vector3.new(0.22 * k, 2 * math.pi * R / n + 0.06, 0.22 * k), center * CFrame.new(math.cos(a) * R, math.sin(a) * R, 0) * CFrame.Angles(0, 0, a), C3(110, 70, 40), M.Wood)
	end
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + math.pi / 2
		local at = center * CFrame.new(math.cos(a) * R, math.sin(a) * R, 0.05 * k)
		wear(model, "UpperTorso", "Drum", Vector3.new(0.5 * k, 0.85 * k, 0.85 * k), at * CFrame.Angles(0, math.rad(90), 0), C3(120, 36, 30), M.Wood, Cyl)
		wear(model, "UpperTorso", "DrumHead", Vector3.new(0.52 * k, 0.7 * k, 0.7 * k), at * CFrame.Angles(0, math.rad(90), 0), C3(226, 210, 170), M.SmoothPlastic, Cyl)
	end
	wear(model, "UpperTorso", "DrumBrace", Vector3.new(0.2 * k, 1.2 * k, 0.2 * k), CFrame.new(0, ut.Y * 0.5, ut.Z * 0.7), C3(110, 70, 40), M.Wood)
	local _ = P
end
SIG.seonggun = function(model, look, k, P)
	-- 성군: 도포 자락에 수놓은 금빛 별 (작은 점들)
	local lt = sizeOf(model, "LowerTorso")
	for i = 0, 7 do
		local x = ((i * 37) % 9 - 4) / 9
		local y = -0.4 - ((i * 53) % 7) / 7 * 1.4
		wear(model, "LowerTorso", "StarStitch", Vector3.new(0.14, 0.14, 0.04) * k, CFrame.new(x * lt.X, y * k, -lt.Z * 0.62), C3(240, 220, 160), M.Metal, Ball)
	end
	mantle(model, C3(50, 26, 100), C3(230, 210, 150), k, 3.2)
end
SIG.cheonjon = function(model, look, k, P)
	-- 천존: 머리 뒤의 금빛 광배 하나와 흰 망토
	halo(model, C3(226, 192, 100), k, 1.45)
	mantle(model, C3(244, 236, 214), GOLD, k, 3.6)
	local _ = P
end
SIG.pungyeop = function(model, look, k, P)
	-- 풍엽: 단풍잎을 엮은 관과 단풍빛 망토
	local hs = sizeOf(model, "Head")
	for i = 0, 6 do
		local a = (i / 6 - 0.5) * math.pi
		wear(model, "Head", "MapleLeaf", Vector3.new(0.6, 0.6, 0.06) * k, CFrame.new(math.sin(a) * hs.X * 0.5, hs.Y * 0.55 + math.cos(a) * hs.Y * 0.12, -math.cos(a) * hs.Z * 0.12) * CFrame.Angles(0, -a, math.rad(45)), i % 2 == 0 and C3(214, 70, 30) or C3(236, 150, 40), M.SmoothPlastic)
	end
	mantle(model, C3(170, 60, 26), C3(246, 180, 70), k, 3.2)
	local _ = P
end
SIG.jukwang = function(model, look, k, P)
	-- 죽왕: 등에 멘 대나무 다발과 대나무 잎 관, 대숲빛 망토
	local hs = sizeOf(model, "Head")
	for i = 0, 4 do
		local a = (i / 4 - 0.5) * math.pi * 0.8
		wear(model, "Head", "BambooLeaf", Vector3.new(0.05, 0.3, 1.3) * k, CFrame.new(math.sin(a) * hs.X * 0.45, hs.Y * 0.6, -math.cos(a) * hs.Z * 0.1) * CFrame.Angles(math.rad(-60), -a, 0), C3(90, 150, 70), M.SmoothPlastic, Ball)
	end
	local ut = sizeOf(model, "UpperTorso")
	for i = -1, 1 do
		wear(model, "UpperTorso", "BambooPole", Vector3.new(4.2 * k, 0.32 * k, 0.32 * k), CFrame.new(i * 0.3 * k, 0.6 * k, ut.Z * 0.75) * CFrame.Angles(0, 0, math.rad(60 + i * 6)) * CFrame.Angles(0, 0, 0), C3(130, 170, 80), M.SmoothPlastic, Cyl)
	end
	mantle(model, C3(70, 106, 58), C3(226, 216, 160), k, 3.0)
	local _ = P
end
SIG.wolyeong = function(model, look, k, P)
	-- 월영: 머리 뒤의 초승달 (고리의 한쪽만), 달빛 망토
	local ut = sizeOf(model, "UpperTorso")
	local center = CFrame.new(0, ut.Y * 0.5 + 1.0 * k, ut.Z * 0.75)
	local n = 18
	for i = 0, n - 1 do
		local a = math.rad(200) + i / (n - 1) * math.rad(220)
		local r = 1.1 * k
		local w = (0.1 + 0.16 * math.sin(i / (n - 1) * math.pi)) * k
		wear(model, "UpperTorso", "Crescent", Vector3.new(w, 2 * math.pi * r / n * 1.6 + 0.05, w), center * CFrame.new(math.cos(a) * r, math.sin(a) * r, 0) * CFrame.Angles(0, 0, a), C3(230, 238, 255), M.Glass)
	end
	mantle(model, C3(190, 202, 236), C3(240, 244, 255), k, 3.6)
	local _ = P
end
SIG.geumgang = function(model, look, k, P)
	-- 금강천왕: 머리 뒤의 금빛 광배와 큰 염주, 붉은 가사 한 자락
	halo(model, C3(240, 196, 90), k, 1.6)
	local ut = sizeOf(model, "UpperTorso")
	wear(model, "UpperTorso", "Kasaya", Vector3.new(ut.X * 0.5, ut.Y * 1.15, ut.Z * 1.1), CFrame.new(-ut.X * 0.12, 0, 0) * CFrame.Angles(0, 0, math.rad(-28)), C3(170, 40, 30))
	local _ = P
end
SIG.dason = function(model, look, k, P)
	-- 다선: 커다란 삿갓, 허리에 찬 찻주전자
	local hs = sizeOf(model, "Head")
	disc(model, "Head", "BigHat", hs.X * 3.0, 0.12 * k, CFrame.new(0, hs.Y * 0.46, 0), C3(196, 168, 110))
	disc(model, "Head", "BigHatMid", hs.X * 1.7, hs.Y * 0.16, CFrame.new(0, hs.Y * 0.56, 0), C3(186, 156, 100))
	disc(model, "Head", "BigHatTop", hs.X * 0.8, hs.Y * 0.2, CFrame.new(0, hs.Y * 0.7, 0), C3(176, 146, 92))
	local lt = sizeOf(model, "LowerTorso")
	wear(model, "LowerTorso", "TeaPot", Vector3.new(0.75, 0.6, 0.75) * k, CFrame.new(lt.X * 0.58, -0.25 * k, 0), C3(104, 76, 58), M.SmoothPlastic, Ball)
	wear(model, "LowerTorso", "TeaPotLid", Vector3.new(0.3, 0.14, 0.3) * k, CFrame.new(lt.X * 0.58, 0.07 * k, 0), C3(84, 60, 46), M.SmoothPlastic, Ball)
	local _ = P
end
SIG.pokryong = function(model, look, k, P)
	-- 비천: 목에 감겨 뒤로 흘러내리는 물빛 비단
	for i = 0, 4 do
		local w = wear(model, "UpperTorso", "WaterSilk", Vector3.new((1.3 - i * 0.14) * k, 0.46 * k, 0.06), CFrame.new(0, (0.85 - i * 0.44) * k, (0.62 + i * 0.12) * k) * CFrame.Angles(math.rad(18 + i * 8), 0, (i % 2 - 0.5) * 0.25), C3(150, 212, 250), M.Glass)
		if w then
			w.Transparency = 0.35
		end
	end
	local _ = P
end
SIG.unmugun = function(model, look, k, P)
	-- 운무군: 어깨를 덮은 구름 같은 흰 목둘레와 긴 망토
	mantle(model, C3(206, 216, 236), C3(244, 246, 252), k, 3.4)
	local ut = sizeOf(model, "UpperTorso")
	for i = 0, 4 do
		local a = (i / 4 - 0.5) * math.pi
		wear(model, "UpperTorso", "CloudRuff", Vector3.new(0.9, 0.6, 0.9) * k, CFrame.new(math.sin(a) * ut.X * 0.45, ut.Y * 0.52, math.cos(a) * ut.Z * 0.25), C3(244, 246, 252), M.SmoothPlastic, Ball)
	end
	local _ = P
end
SIG.seokwang = function(model, look, k, P)
	-- 석왕: 머리에 둥글게 선 돌기둥 관 (선돌 일곱), 이끼 수염, 어깨를 덮은 이끼 망토와 넝쿨
	local stone, moss = C3(80, 82, 78), C3(66, 100, 48)
	for i = 0, 4 do
		local a = (i / 4 - 0.5) * math.pi * 0.95
		local h = (i == 2 and 0.75 or (i % 2 == 1 and 0.55 or 0.4)) * k
		wear(model, "Head", "Menhir", Vector3.new(0.3 * k, h, 0.26 * k), CFrame.new(math.sin(a) * 0.48 * k, 0.5 * k + h / 2, -math.cos(a) * 0.38 * k) * CFrame.Angles(-math.cos(a) * 0.15, -a, math.sin(a) * -0.2), stone, M.Slate)
	end
	wear(model, "Head", "MossBeard", Vector3.new(0.9, 0.7, 0.3) * k, CFrame.new(0, -0.55 * k, -0.48 * k), moss, M.Grass)
	local ut = sizeOf(model, "UpperTorso")
	for i = 0, 4 do
		wear(model, "UpperTorso", "Vine", Vector3.new(0.12 * k, (1.0 + (i % 2) * 0.5) * k, 0.1 * k), CFrame.new((i - 2) * 0.38 * k, 0.3 * k, ut.Z * 0.85 + 0.2 * k), dark(moss, 0.2), M.Grass)
	end
	local _ = P
end

------------------------------------------------------------------------
-- 3.2.1판: 사람이 아닌 보스의 몸을 새로 빚는다. 네모난 몸 조각은 감추고 (관절은 그대로 움직인다),
-- 그 위에 생김새대로 깎은 조각을 붙인다. 몸통·팔·다리가 따로 읽히도록 마디 사이를 좁히고 빛깔을 나눈다
------------------------------------------------------------------------
local BOSS_BODY: { [string]: (Model, any, number) -> () } = {}
local function ell(model: Model, partName: string, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): Part?
	return wear(model, partName, name, size, cf, color, mat or M.SmoothPlastic, Ball)
end
-- 세운 원통 (길이 L, 굵기 d)
local function rod(model: Model, partName: string, name: string, L: number, d: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part?
	return wear(model, partName, name, Vector3.new(L, d, d), cf * UPRIGHT, color, mat or M.SmoothPlastic, Cyl)
end
-- 축 방향 (부위 안의 방향 dir) 으로 긴 타원
local function ellAlong(model: Model, partName: string, name: string, at: Vector3, dir: Vector3, w: number, L: number, color: Color3, mat: Enum.Material?): Part?
	local cf = CFrame.lookAt(at, at + dir) * CFrame.Angles(math.rad(-90), 0, 0)
	return ell(model, partName, name, Vector3.new(w, L, w), cf, color, mat)
end
local function hideBody(model: Model)
	clearFace(model)
	hide(model, { "Head", "UpperTorso", "LowerTorso" })
	hide(model, ARMS)
	hide(model, LEGS)
end

-- 학과 봉황: 앞으로 기운 달걀꼴 몸, 휘어 오른 긴 목 끝의 작은 머리와 부리, 팔이 곧 날개 (덮깃과 늘어진 칼깃), 가는 다리와 발가락
local function birdKing(model: Model, look: any, k: number)
	local feather = look.feather or C3(240, 240, 240)
	local crest = look.crest or C3(210, 40, 40)
	local beak = look.beak or C3(225, 185, 90)
	local tip = look.tip or dark(feather, 0.75)
	local breast = look.breast or light(feather, 0.14)
	local legC = dark(beak, 0.2)
	local phoenix = look.longCrest == true
	hideBody(model)
	local ut, lt, hs = sizeOf(model, "UpperTorso"), sizeOf(model, "LowerTorso"), sizeOf(model, "Head")
	ell(model, "UpperTorso", "Body", Vector3.new(ut.X * 0.86, ut.Y * 1.45, ut.Z * 1.7), CFrame.new(0, -ut.Y * 0.1, ut.Z * 0.15) * CFrame.Angles(math.rad(-12), 0, 0), feather)
	ell(model, "UpperTorso", "Breast", Vector3.new(ut.X * 0.62, ut.Y * 1.0, ut.Z * 0.55), CFrame.new(0, ut.Y * 0.02, -ut.Z * 0.55) * CFrame.Angles(math.rad(-12), 0, 0), breast)
	ell(model, "LowerTorso", "Rump", Vector3.new(lt.X * 0.72, lt.Y * 3.2, lt.Z * 1.5), CFrame.new(0, -lt.Y * 0.2, lt.Z * 0.35), dark(feather, 0.05))
	-- 목: 마디 넷이 앞으로 휘며 올라간다 (머리 관절에 붙어 머리와 함께 돈다)
	local headAt = Vector3.new(0, hs.Y * 1.4, -hs.Z * 0.35)
	local base = Vector3.new(0, -hs.Y * 0.3, hs.Z * 0.05)
	local neckC = look.neckColor or (phoenix and feather or C3(30, 30, 34))
	-- 마디를 촘촘히 겹쳐 매끈한 한 줄기로 (마디마다 휘는 방향을 따라 눕힌다)
	local n = 8
	local function neckAt(u: number): Vector3
		return base:Lerp(headAt, u) + Vector3.new(0, 0, math.sin(u * math.pi) * hs.Z * 0.3)
	end
	for i = 0, n do
		local u = i / n
		local p = neckAt(u)
		local dirN = neckAt(math.min(1, u + 0.05)) - neckAt(math.max(0, u - 0.05))
		local d = hs.X * (0.5 - u * 0.16)
		ellAlong(model, "Head", "Neck", p, dirN, d, hs.Y * 0.42, (u > 0.35 and not phoenix) and neckC or feather)
	end
	ell(model, "Head", "BirdHead", Vector3.new(hs.X * 0.66, hs.Y * 0.62, hs.Z * 0.92), CFrame.new(headAt), feather)
	local bl = (phoenix and 0.75 or 1.4) * k
	wear(model, "Head", "Beak", Vector3.new(0.2 * k, 0.17 * k, bl), CFrame.new(headAt + Vector3.new(0, -hs.Y * 0.05, -hs.Z * 0.4 - bl * 0.5)) * CFrame.Angles(math.rad(phoenix and -20 or -6), 0, 0), beak, M.SmoothPlastic)
	wear(model, "Head", "BeakLow", Vector3.new(0.15 * k, 0.08 * k, bl * 0.8), CFrame.new(headAt + Vector3.new(0, -hs.Y * 0.15, -hs.Z * 0.38 - bl * 0.4)) * CFrame.Angles(math.rad(4), 0, 0), dark(beak, 0.2), M.SmoothPlastic)
	for _, x in ipairs({ -1, 1 }) do
		ell(model, "Head", "EyeRing", Vector3.new(0.05 * k, 0.2 * k, 0.2 * k), CFrame.new(headAt + Vector3.new(x * hs.X * 0.33, hs.Y * 0.08, -hs.Z * 0.16)), phoenix and C3(255, 220, 120) or WHITE)
		ell(model, "Head", "Eye", Vector3.new(0.07 * k, 0.12 * k, 0.12 * k), CFrame.new(headAt + Vector3.new(x * hs.X * 0.35, hs.Y * 0.08, -hs.Z * 0.16)), look.eyes or C3(20, 20, 20))
	end
	if phoenix then
		for j = 0, 3 do
			local at = CFrame.new(headAt + Vector3.new(0, hs.Y * 0.28, hs.Z * (0.05 + j * 0.12))) * CFrame.Angles(math.rad(-30 - j * 16), 0, 0)
			wear(model, "Head", "Crest", Vector3.new(0.08 * k, (0.9 - j * 0.12) * k, 0.3 * k), at * CFrame.new(0, (0.45 - j * 0.06) * k, 0), j == 0 and C3(255, 240, 170) or crest, M.SmoothPlastic)
		end
	else
		ell(model, "Head", "Crown", Vector3.new(hs.X * 0.4, 0.14 * k, hs.Z * 0.48), CFrame.new(headAt + Vector3.new(0, hs.Y * 0.28, 0.02 * k)), crest)
	end
	-- 날개 (팔): 위팔의 덮깃, 아래팔과 손에서 뒤아래로 늘어진 칼깃 일곱 (끝은 짙게)
	for _, side in ipairs({ "Left", "Right" }) do
		local x = side == "Left" and -1 or 1
		local ua, la = sizeOf(model, side .. "UpperArm"), sizeOf(model, side .. "LowerArm")
		-- 접은 날개: 어깨에서 엉덩이 아래까지 몸 옆에 납작하게 붙은 한 장 (위는 덮깃 빛깔, 아래로 짙어진다)
		ell(model, side .. "UpperArm", "Wing", Vector3.new(ua.X * 0.38, ua.Y * 2.5, ua.Z * 1.8), CFrame.new(x * ua.X * 0.08, -ua.Y * 0.45, ua.Z * 0.3) * CFrame.Angles(math.rad(-8), 0, 0), feather)
		ell(model, side .. "UpperArm", "WingBar", Vector3.new(ua.X * 0.42, ua.Y * 0.9, ua.Z * 1.5), CFrame.new(x * ua.X * 0.1, -ua.Y * 1.05, ua.Z * 0.4) * CFrame.Angles(math.rad(-8), 0, 0), dark(feather, 0.1))
		for j = 0, 6 do
			local L = (1.5 + j * 0.3) * k
			local at = CFrame.new(x * 0.05 * k, -la.Y * 0.05 + j * 0.06 * k, (0.15 + j * 0.15) * k) * CFrame.Angles(math.rad(-(6 + j * 6)), 0, x * math.rad(3))
			wear(model, side .. "LowerArm", "Quill", Vector3.new(0.08 * k, L, 0.46 * k), at * CFrame.new(0, -L / 2, 0), j >= 4 and tip or (j % 2 == 0 and feather or dark(feather, 0.05)), M.SmoothPlastic)
		end
	end
	-- 다리: 깃 덮인 넓적다리, 가는 정강이, 앞 발가락 셋과 뒷발가락
	for _, side in ipairs({ "Left", "Right" }) do
		local ul, ll, ft = sizeOf(model, side .. "UpperLeg"), sizeOf(model, side .. "LowerLeg"), sizeOf(model, side .. "Foot")
		ell(model, side .. "UpperLeg", "Thigh", Vector3.new(ul.X * 0.85, ul.Y * 0.95, ul.Z * 1.1), CFrame.new(0, ul.Y * 0.12, 0), dark(feather, 0.08))
		rod(model, side .. "UpperLeg", "ShankTop", ul.Y * 0.6, 0.26 * k, CFrame.new(0, -ul.Y * 0.32, 0), legC)
		rod(model, side .. "LowerLeg", "Shank", ll.Y * 1.3, 0.24 * k, CFrame.new(0, 0, 0), legC)
		for j = -1, 1 do
			local at = CFrame.new(j * 0.18 * k, -ft.Y * 0.2, -ft.Z * 0.1) * CFrame.Angles(0, j * 0.45, 0)
			wear(model, side .. "Foot", "Toe", Vector3.new(0.12 * k, 0.1 * k, 0.8 * k), at * CFrame.new(0, 0, -0.4 * k), legC, M.SmoothPlastic)
			wear(model, side .. "Foot", "Talon", Vector3.new(0.08 * k, 0.08 * k, 0.2 * k), at * CFrame.new(0, -0.03 * k, -0.85 * k) * CFrame.Angles(math.rad(25), 0, 0), C3(30, 26, 22), M.SmoothPlastic)
		end
		wear(model, side .. "Foot", "HindToe", Vector3.new(0.1 * k, 0.1 * k, 0.4 * k), CFrame.new(0, -ft.Y * 0.2, ft.Z * 0.35), legC, M.SmoothPlastic)
	end
	-- 꼬리: 학은 짙은 깃 부채, 봉황은 땅까지 흐르는 긴 깃 다섯
	if look.longTail and phoenix then
		for j = -2, 2 do
			local cf = CFrame.new(j * 0.18 * k, -0.1 * k, lt.Z * 0.6 + 0.3 * k) * CFrame.Angles(math.rad(-55), 0, math.rad(j * 10))
			for sgm = 0, 3 do
				wear(model, "LowerTorso", "TailPlume", Vector3.new(0.22 * k, 1.15 * k, 0.06 * k), cf * CFrame.new(0, -0.58 * k, 0), sgm == 3 and look.longTail or (j == 0 and crest or feather), M.SmoothPlastic)
				cf = cf * CFrame.new(0, -1.1 * k, 0) * CFrame.Angles(math.rad(-10), 0, 0)
			end
			ell(model, "LowerTorso", "TailEye", Vector3.new(0.4 * k, 0.4 * k, 0.08 * k), cf * CFrame.new(0, 0.3 * k, 0), C3(60, 120, 200))
		end
	else
		for j = -3, 3 do
			local L = (1.6 - math.abs(j) * 0.15) * k
			wear(model, "LowerTorso", "TailFeather", Vector3.new(0.3 * k, L, 0.06 * k), CFrame.new(j * 0.16 * k, -0.2 * k, lt.Z * 0.7 + 0.3 * k) * CFrame.Angles(math.rad(-40), 0, math.rad(j * 9)) * CFrame.new(0, -L / 2, 0), look.longTail or tip, M.SmoothPlastic)
		end
	end
	if look.fire then
		flame(model, "UpperTorso", look.fire, dark(look.fire, 0.35), 3.5 * k, 4)
		for _, side in ipairs({ "LeftLowerArm", "RightLowerArm" }) do
			flame(model, side, look.fire, dark(look.fire, 0.35), 1.6 * k, 3)
		end
		glow(model, "UpperTorso", look.fire, 14 * k, 1.2)
	end
end
BOSS_BODY.seonhak = birdKing
BOSS_BODY.yeombong = birdKing

-- 늑대왕 (혈랑): 앞으로 숙인 통 가슴과 가는 허리, 목과 어깨의 갈기 털 뭉치, 긴 주둥이와 엄니, 굵은 앞발과 꺾인 뒷다리, 털 꼬리, 핏빛 목도리
BOSS_BODY.hyeolrang = function(model: Model, look: any, k: number)
	local fur = look.fur or C3(84, 30, 32)
	local pale = look.pale or light(fur, 0.35)
	local deep = dark(fur, 0.25)
	local bone = C3(232, 222, 205)
	hideBody(model)
	local ut, lt, hs = sizeOf(model, "UpperTorso"), sizeOf(model, "LowerTorso"), sizeOf(model, "Head")
	ell(model, "UpperTorso", "Chest", Vector3.new(ut.X * 1.05, ut.Y * 1.25, ut.Z * 1.55), CFrame.new(0, ut.Y * 0.05, 0) * CFrame.Angles(math.rad(-18), 0, 0), fur, M.Fabric)
	ell(model, "UpperTorso", "Belly", Vector3.new(ut.X * 0.58, ut.Y * 0.95, ut.Z * 0.7), CFrame.new(0, -ut.Y * 0.12, -ut.Z * 0.5) * CFrame.Angles(math.rad(-10), 0, 0), pale, M.Fabric)
	ell(model, "LowerTorso", "Waist", Vector3.new(lt.X * 0.68, lt.Y * 2.6, lt.Z * 1.0), CFrame.new(0, lt.Y * 0.2, 0), dark(fur, 0.08), M.Fabric)
	ell(model, "UpperTorso", "BackStripe", Vector3.new(ut.X * 0.5, ut.Y * 1.1, ut.Z * 0.5), CFrame.new(0, ut.Y * 0.1, ut.Z * 0.62) * CFrame.Angles(math.rad(-18), 0, 0), deep, M.Fabric)
	-- 갈기: 목둘레 열넷 (앞은 작게, 뒤와 어깨는 크게 바깥으로)
	for i = 0, 17 do
		local a = i / 18 * math.pi * 2
		local front = -math.sin(a)
		local sz = front > 0.6 and 0.5 or 0.8
		local pos = Vector3.new(math.cos(a) * ut.X * 0.42, ut.Y * 0.5, math.sin(a) * ut.Z * 0.7 + ut.Z * 0.1)
		local out = Vector3.new(math.cos(a), 0.7, math.sin(a) * 0.8 + 0.5)
		ellAlong(model, "UpperTorso", "Mane", pos, out, 0.6 * k * sz, 1.25 * k * sz, i % 2 == 0 and pale or fur, M.Fabric)
	end
	-- 머리: 앞으로 내민 머리뼈, 길고 끝이 가는 주둥이, 벌린 아래턱과 엄니, 눈두덩, 세운 귀
	local H0 = Vector3.new(0, -hs.Y * 0.05, -hs.Z * 0.15)
	ell(model, "Head", "Skull", Vector3.new(hs.X * 0.85, hs.Y * 0.8, hs.Z * 1.0), CFrame.new(H0), fur, M.Fabric)
	wear(model, "Head", "Snout", Vector3.new(hs.X * 0.42, hs.Y * 0.32, hs.Z * 0.9), CFrame.new(H0 + Vector3.new(0, -hs.Y * 0.1, -hs.Z * 0.75)) * CFrame.Angles(math.rad(6), 0, 0), fur, M.Fabric)
	wear(model, "Head", "Jaw", Vector3.new(hs.X * 0.34, hs.Y * 0.12, hs.Z * 0.75), CFrame.new(H0 + Vector3.new(0, -hs.Y * 0.32, -hs.Z * 0.66)) * CFrame.Angles(math.rad(14), 0, 0), pale, M.Fabric)
	ell(model, "Head", "Nose", Vector3.new(hs.X * 0.2, hs.Y * 0.14, hs.Z * 0.14), CFrame.new(H0 + Vector3.new(0, -hs.Y * 0.02, -hs.Z * 1.2)), C3(15, 10, 10))
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Fang", Vector3.new(0.07 * k, 0.24 * k, 0.07 * k), CFrame.new(H0 + Vector3.new(x * hs.X * 0.13, -hs.Y * 0.26, -hs.Z * 1.0)), bone, M.SmoothPlastic)
		wear(model, "Head", "Brow", Vector3.new(hs.X * 0.32, 0.1 * k, 0.2 * k), CFrame.new(H0 + Vector3.new(x * hs.X * 0.2, hs.Y * 0.16, -hs.Z * 0.44)) * CFrame.Angles(0, 0, x * math.rad(-18)), deep, M.Fabric)
		wear(model, "Head", "Eye", Vector3.new(0.22 * k, 0.07 * k, 0.05 * k), CFrame.new(H0 + Vector3.new(x * hs.X * 0.2, hs.Y * 0.06, -hs.Z * 0.5)) * CFrame.Angles(0, 0, x * math.rad(-16)), look.eyes or C3(255, 70, 60), M.Neon)
		local ear = CFrame.new(H0 + Vector3.new(x * hs.X * 0.3, hs.Y * 0.36, hs.Z * 0.12)) * CFrame.Angles(math.rad(-14), 0, -x * math.rad(14))
		wear(model, "Head", "Ear", Vector3.new(0.34 * k, 0.4 * k, 0.12 * k), ear * CFrame.new(0, 0.18 * k, 0), fur, M.Fabric)
		wear(model, "Head", "EarTip", Vector3.new(0.18 * k, 0.24 * k, 0.11 * k), ear * CFrame.new(0, 0.48 * k, 0), deep, M.Fabric)
		wear(model, "Head", "EarIn", Vector3.new(0.18 * k, 0.32 * k, 0.05 * k), ear * CFrame.new(0, 0.18 * k, -0.07 * k), pale, M.Fabric)
	end
	-- 앞발: 굵은 어깨와 팔뚝, 팔꿈치의 털, 큰 발과 긴 발톱
	for _, side in ipairs({ "Left", "Right" }) do
		local ua, la, hd = sizeOf(model, side .. "UpperArm"), sizeOf(model, side .. "LowerArm"), sizeOf(model, side .. "Hand")
		ell(model, side .. "UpperArm", "Shoulder", Vector3.new(ua.X * 1.0, ua.Y * 1.4, ua.Z * 1.0), CFrame.new(0, ua.Y * 0.05, 0), fur, M.Fabric)
		ell(model, side .. "LowerArm", "Forearm", Vector3.new(la.X * 0.9, la.Y * 1.5, la.Z * 0.9), CFrame.new(0, -la.Y * 0.05, 0), dark(fur, 0.06), M.Fabric)
		ellAlong(model, side .. "LowerArm", "ElbowTuft", Vector3.new(0, la.Y * 0.35, la.Z * 0.45), Vector3.new(0, 0.6, 1), 0.4 * k, 0.8 * k, pale, M.Fabric)
		wear(model, side .. "LowerArm", "Wrap", Vector3.new(la.X * 1.12, la.Y * 0.3, la.Z * 1.12), CFrame.new(0, -la.Y * 0.3, 0), look.scarf or C3(150, 14, 24))
		ell(model, side .. "Hand", "Paw", Vector3.new(hd.X * 1.15, hd.Y * 2.1, hd.Z * 1.25), CFrame.new(0, -hd.Y * 0.3, -hd.Z * 0.05), deep, M.Fabric)
		for j = -1.5, 1.5, 1 do
			wear(model, side .. "Hand", "Claw", Vector3.new(0.08 * k, 0.55 * k, 0.08 * k), CFrame.new(j * hd.X * 0.25, -hd.Y * 1.0, -hd.Z * 0.35) * CFrame.Angles(math.rad(30), 0, 0) * CFrame.new(0, -0.22 * k, 0), bone, M.SmoothPlastic)
		end
	end
	-- 뒷다리: 굵은 넓적다리, 뒤로 꺾인 정강이, 긴 발
	for _, side in ipairs({ "Left", "Right" }) do
		local ul, ll, ft = sizeOf(model, side .. "UpperLeg"), sizeOf(model, side .. "LowerLeg"), sizeOf(model, side .. "Foot")
		ell(model, side .. "UpperLeg", "Haunch", Vector3.new(ul.X * 1.0, ul.Y * 1.35, ul.Z * 1.2), CFrame.new(0, ul.Y * 0.05, ul.Z * 0.12), fur, M.Fabric)
		ell(model, side .. "LowerLeg", "Shin", Vector3.new(ll.X * 0.75, ll.Y * 1.5, ll.Z * 0.8), CFrame.new(0, 0, ll.Z * 0.25) * CFrame.Angles(math.rad(-22), 0, 0), dark(fur, 0.1), M.Fabric)
		ell(model, side .. "Foot", "HindPaw", Vector3.new(ft.X * 0.95, ft.Y * 2.2, ft.Z * 1.4), CFrame.new(0, ft.Y * 0.3, -ft.Z * 0.15), deep, M.Fabric)
		for j = -1, 1 do
			wear(model, side .. "Foot", "Claw", Vector3.new(0.08 * k, 0.08 * k, 0.32 * k), CFrame.new(j * ft.X * 0.28, ft.Y * 0.1, -ft.Z * 0.85), bone, M.SmoothPlastic)
		end
	end
	-- 꼬리: 굵은 털 마디가 뒤로 휘어 오르고 끝은 옅다
	local prev = CFrame.new(0, -lt.Y * 0.2, lt.Z * 0.55)
	for j = 1, 5 do
		local seg = prev * CFrame.Angles(math.rad(j == 1 and -70 or 14), 0, 0) * CFrame.new(0, -0.38 * k, 0)
		ell(model, "LowerTorso", "Tail", Vector3.new((0.62 - j * 0.04) * k, 0.95 * k, (0.62 - j * 0.04) * k), seg, j == 5 and pale or fur, M.Fabric)
		prev = seg * CFrame.new(0, -0.38 * k, 0)
	end
	-- 가죽 허리끈과 핏빛 목도리 (목 앞 매듭, 등 뒤로 길게 휘날린다)
	local cloth = look.scarf or C3(150, 14, 24)
	wear(model, "LowerTorso", "Belt", Vector3.new(lt.X * 0.75, 0.28 * k, lt.Z * 1.06), CFrame.new(0, lt.Y * 0.45, 0), LEATHER, M.Leather)
	ell(model, "UpperTorso", "ScarfKnot", Vector3.new(0.5 * k, 0.4 * k, 0.4 * k), CFrame.new(0, ut.Y * 0.35, -ut.Z * 0.75), cloth, M.Fabric)
	for i = 0, 3 do
		wear(model, "UpperTorso", "Scarf", Vector3.new((0.7 - i * 0.08) * k, 0.9 * k, 0.07 * k), CFrame.new(0.15 * k, (0.35 - i * 0.6) * k, ut.Z * 0.85 + i * 0.25 * k) * CFrame.Angles(math.rad(18 + i * 12), 0, math.rad(i * 6)), i == 3 and dark(cloth, 0.2) or cloth)
	end
end

-- 석왕: 마디마다 따로 놓인 바위 몸. 가슴의 큰 바위와 가슴판, 사이를 지나는 빛나는 금, 어깨에 솟은 바위와 이끼,
-- 큰 돌 주먹, 짧고 굵은 다리, 어깨 사이로 낮게 박힌 머리와 깊은 눈, 선돌 관 가운데의 빛나는 돌
BOSS_BODY.seokwang = function(model: Model, look: any, k: number)
	local rock = look.skin or C3(96, 98, 92)
	local r1, r2 = dark(rock, 0.18), light(rock, 0.1)
	local moss = look.moss or C3(70, 104, 50)
	local vein = look.eyes or C3(255, 196, 110)
	local mat = M.Slate
	hideBody(model)
	local ut, lt, hs = sizeOf(model, "UpperTorso"), sizeOf(model, "LowerTorso"), sizeOf(model, "Head")
	wear(model, "UpperTorso", "Core", Vector3.new(ut.X * 1.1, ut.Y * 1.15, ut.Z * 1.3), CFrame.new(0, ut.Y * 0.05, ut.Z * 0.12) * CFrame.Angles(0.05, 0.08, 0.03), rock, mat)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "UpperTorso", "Pec", Vector3.new(ut.X * 0.48, ut.Y * 0.5, ut.Z * 0.5), CFrame.new(x * ut.X * 0.26, ut.Y * 0.18, -ut.Z * 0.6) * CFrame.Angles(0.1, x * 0.15, x * 0.08), r2, mat)
	end
	wear(model, "UpperTorso", "Gut", Vector3.new(ut.X * 0.72, ut.Y * 0.42, ut.Z * 0.9), CFrame.new(0, -ut.Y * 0.5, -ut.Z * 0.05) * CFrame.Angles(-0.05, -0.1, 0), r1, mat)
	-- 빛나는 금: 가슴 가운데로 내려가 둘로 갈라진다
	wear(model, "UpperTorso", "Vein", Vector3.new(0.1 * k, ut.Y * 0.75, 0.06 * k), CFrame.new(0, -ut.Y * 0.05, -ut.Z * 0.87) * CFrame.Angles(0, 0, math.rad(8)), vein, M.Neon)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "UpperTorso", "Vein", Vector3.new(ut.X * 0.3, 0.08 * k, 0.06 * k), CFrame.new(x * ut.X * 0.14, -ut.Y * 0.3, -ut.Z * 0.86) * CFrame.Angles(0, 0, x * math.rad(-25)), vein, M.Neon)
	end
	disc(model, "LowerTorso", "VeinRing", lt.X * 0.9, 0.14 * k, CFrame.new(0, lt.Y * 0.55, 0), vein, M.Neon)
	wear(model, "LowerTorso", "Hip", Vector3.new(lt.X * 0.95, lt.Y * 2.1, lt.Z * 1.15), CFrame.new(0, -lt.Y * 0.35, 0) * CFrame.Angles(0, 0.15, 0), r1, mat)
	for _, side in ipairs({ "Left", "Right" }) do
		local x = side == "Left" and -1 or 1
		local ua, la, hd = sizeOf(model, side .. "UpperArm"), sizeOf(model, side .. "LowerArm"), sizeOf(model, side .. "Hand")
		wear(model, side .. "UpperArm", "ShoulderBoulder", Vector3.new(ua.X * 1.7, ua.Y * 0.8, ua.Z * 1.6), CFrame.new(x * ua.X * 0.1, ua.Y * 0.45, 0) * CFrame.Angles(0.1, 0.3 * x, -0.25 * x), rock, mat)
		wear(model, side .. "UpperArm", "ShoulderMoss", Vector3.new(ua.X * 1.35, 0.14 * k, ua.Z * 1.25), CFrame.new(x * ua.X * 0.1, ua.Y * 0.87, 0) * CFrame.Angles(0.1, 0.3 * x, -0.25 * x), moss, M.Grass)
		wear(model, side .. "UpperArm", "ArmRock", Vector3.new(ua.X * 1.0, ua.Y * 0.65, ua.Z * 1.0), CFrame.new(0, -ua.Y * 0.18, 0) * CFrame.Angles(0, 0.4, 0.05), r1, mat)
		disc(model, side .. "LowerArm", "ElbowVein", la.X * 0.8, 0.1 * k, CFrame.new(0, la.Y * 0.5, 0), vein, M.Neon)
		wear(model, side .. "LowerArm", "Forearm", Vector3.new(la.X * 1.35, la.Y * 1.1, la.Z * 1.35), CFrame.new(0, -la.Y * 0.05, 0) * CFrame.Angles(0, -0.3, 0), rock, mat)
		wear(model, side .. "Hand", "Fist", Vector3.new(hd.X * 1.7, hd.Y * 4.0, hd.Z * 1.6), CFrame.new(0, -hd.Y * 1.3, 0) * CFrame.Angles(0, 0.2, 0), r2, mat)
		for j = -1, 1 do
			wear(model, side .. "Hand", "Knuckle", Vector3.new(hd.X * 0.45, hd.Y * 1.1, hd.Z * 0.4), CFrame.new(j * hd.X * 0.5, -hd.Y * 1.6, -hd.Z * 0.82), r1, mat)
		end
	end
	for _, side in ipairs({ "Left", "Right" }) do
		local ul, ll, ft = sizeOf(model, side .. "UpperLeg"), sizeOf(model, side .. "LowerLeg"), sizeOf(model, side .. "Foot")
		wear(model, side .. "UpperLeg", "Thigh", Vector3.new(ul.X * 1.25, ul.Y * 1.0, ul.Z * 1.25), CFrame.new(0, ul.Y * 0.05, 0) * CFrame.Angles(0, 0.2, 0), r1, mat)
		disc(model, side .. "LowerLeg", "KneeVein", ll.X * 0.85, 0.1 * k, CFrame.new(0, ll.Y * 0.5, 0), vein, M.Neon)
		wear(model, side .. "LowerLeg", "Shin", Vector3.new(ll.X * 1.2, ll.Y * 1.15, ll.Z * 1.2), CFrame.new(0, -ll.Y * 0.05, 0) * CFrame.Angles(0, -0.25, 0), rock, mat)
		wear(model, side .. "Foot", "FootSlab", Vector3.new(ft.X * 1.5, ft.Y * 2.2, ft.Z * 1.6), CFrame.new(0, ft.Y * 0.4, -ft.Z * 0.15), r1, mat)
	end
	-- 머리: 어깨 사이로 낮게, 눈두덩 아래의 빛나는 눈, 이끼 수염, 선돌 관과 가운데 빛나는 돌
	local H0 = Vector3.new(0, -hs.Y * 0.25, -hs.Z * 0.1)
	wear(model, "Head", "Skull", Vector3.new(hs.X * 0.95, hs.Y * 0.8, hs.Z * 0.95), CFrame.new(H0) * CFrame.Angles(0.05, 0.1, 0), rock, mat)
	wear(model, "Head", "Brow", Vector3.new(hs.X * 1.0, hs.Y * 0.2, hs.Z * 0.35), CFrame.new(H0 + Vector3.new(0, hs.Y * 0.18, -hs.Z * 0.42)) * CFrame.Angles(0.15, 0, 0), r1, mat)
	wear(model, "Head", "Jaw", Vector3.new(hs.X * 0.85, hs.Y * 0.25, hs.Z * 0.8), CFrame.new(H0 + Vector3.new(0, -hs.Y * 0.42, -hs.Z * 0.1)), r1, mat)
	for _, x in ipairs({ -1, 1 }) do
		wear(model, "Head", "Eye", Vector3.new(0.24 * k, 0.09 * k, 0.05 * k), CFrame.new(H0 + Vector3.new(x * hs.X * 0.22, hs.Y * 0.02, -hs.Z * 0.49)), vein, M.Neon)
	end
	wear(model, "Head", "MossBeard", Vector3.new(hs.X * 0.75, hs.Y * 0.55, hs.Z * 0.25), CFrame.new(H0 + Vector3.new(0, -hs.Y * 0.55, -hs.Z * 0.4)), moss, M.Grass)
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		local h = (i % 2 == 0 and 0.75 or 0.5) * k
		wear(model, "Head", "Menhir", Vector3.new(0.28 * k, h, 0.24 * k), CFrame.new(H0 + Vector3.new(math.sin(a) * hs.X * 0.38, hs.Y * 0.4 + h / 2, -math.cos(a) * hs.Z * 0.38)) * CFrame.Angles(-math.cos(a) * 0.18, -a, math.sin(a) * -0.18), r2, mat)
	end
	wear(model, "Head", "CrownGem", Vector3.new(0.3, 0.55, 0.3) * k, CFrame.new(H0 + Vector3.new(0, hs.Y * 0.62, 0)) * CFrame.Angles(0, math.rad(45), 0), vein, M.Neon)
	glow(model, "UpperTorso", vein, 12 * k, 1.2)
end

-- 균왕: 아래가 불룩한 자루 몸, 늘어진 턱받이, 큰 갓 (몸과 따로 읽히게 목을 가늘게), 가는 자루 팔과 작은 갓 주먹,
-- 땅으로 퍼지는 뿌리 다리, 어깨와 등에서 돋은 작은 버섯
BOSS_BODY.gyunwang = function(model: Model, look: any, k: number)
	local cap = look.capColor or C3(160, 26, 36)
	local stem = look.skin or C3(232, 222, 198)
	local gill = light(stem, 0.1):Lerp(C3(200, 180, 150), 0.4)
	local rootC = C3(110, 85, 60)
	hideBody(model)
	local ut, lt, hs = sizeOf(model, "UpperTorso"), sizeOf(model, "LowerTorso"), sizeOf(model, "Head")
	rod(model, "UpperTorso", "Stem", ut.Y * 1.35, ut.X * 0.6, CFrame.new(0, ut.Y * 0.05, 0), stem)
	ell(model, "LowerTorso", "Bulb", Vector3.new(ut.X * 0.85, lt.Y * 4.6, ut.X * 0.85), CFrame.new(0, -lt.Y * 0.7, 0), dark(stem, 0.06))
	for i = -2, 2 do
		wear(model, "UpperTorso", "StemGrain", Vector3.new(0.05 * k, ut.Y * 1.1, 0.04 * k), CFrame.new(i * ut.X * 0.07, 0, -ut.X * 0.3) * CFrame.Angles(0, i * 0.22, 0), dark(stem, 0.1))
	end
	-- 턱받이: 자루 위의 고리와 늘어진 주름 열둘
	disc(model, "UpperTorso", "Ring", ut.X * 0.95, 0.14 * k, CFrame.new(0, ut.Y * 0.38, 0), light(stem, 0.1))
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local r = ut.X * 0.42
		wear(model, "UpperTorso", "RingFrill", Vector3.new(ut.X * 0.24, 0.55 * k, 0.06 * k), CFrame.new(math.cos(a) * r, ut.Y * 0.2, math.sin(a) * r) * CFrame.Angles(0, -a + math.pi / 2, 0) * CFrame.Angles(math.rad(-12), 0, 0), i % 2 == 0 and light(stem, 0.1) or stem)
	end
	-- 머리: 가는 목 위의 얼굴 (자루 빛깔), 그 위에 큰 갓
	rod(model, "Head", "NeckStalk", hs.Y * 0.6, hs.X * 0.45, CFrame.new(0, -hs.Y * 0.35, 0), stem)
	ell(model, "Head", "Face", Vector3.new(hs.X * 0.72, hs.Y * 0.8, hs.Z * 0.72), CFrame.new(0, 0, 0), stem)
	for _, x in ipairs({ -1, 1 }) do
		ell(model, "Head", "Eye", Vector3.new(0.17 * k, 0.24 * k, 0.08 * k), CFrame.new(x * hs.X * 0.16, -hs.Y * 0.02, -hs.Z * 0.35), C3(18, 14, 12))
	end
	local R = (look.capSize or 3.8) * k * 0.5
	mushroomCap(model, "Head", CFrame.new(0, hs.Y * 0.34, 0), R, R * 0.62, cap, gill, look.spot or C3(245, 240, 228))
	-- 팔: 가는 자루 두 마디와 작은 갓 주먹
	for _, side in ipairs({ "Left", "Right" }) do
		local ua, la, hd = sizeOf(model, side .. "UpperArm"), sizeOf(model, side .. "LowerArm"), sizeOf(model, side .. "Hand")
		rod(model, side .. "UpperArm", "ArmStalk", ua.Y * 1.05, ua.X * 0.48, CFrame.new(0, 0, 0), stem)
		rod(model, side .. "LowerArm", "ArmStalk2", la.Y * 1.1, la.X * 0.42, CFrame.new(0, 0, 0), dark(stem, 0.05))
		ell(model, side .. "Hand", "FistCap", Vector3.new(hd.X * 1.5, hd.Y * 2.6, hd.Z * 1.5), CFrame.new(0, -hd.Y * 0.3, 0), cap)
		disc(model, side .. "Hand", "FistGill", hd.X * 1.35, 0.05 * k, CFrame.new(0, -hd.Y * 0.9, 0), gill)
	end
	-- 다리: 자루 두 마디, 발목에서 땅으로 퍼지는 뿌리 다섯
	for _, side in ipairs({ "Left", "Right" }) do
		local ul, ll = sizeOf(model, side .. "UpperLeg"), sizeOf(model, side .. "LowerLeg")
		rod(model, side .. "UpperLeg", "LegStalk", ul.Y * 1.0, ul.X * 0.55, CFrame.new(0, 0, 0), dark(stem, 0.1))
		rod(model, side .. "LowerLeg", "LegStalk2", ll.Y * 1.1, ll.X * 0.6, CFrame.new(0, 0, 0), dark(stem, 0.18):Lerp(rootC, 0.4))
		for j = 0, 4 do
			local a = j / 5 * math.pi * 2
			wear(model, side .. "Foot", "Root", Vector3.new(1.2 * k, 0.2 * k, 0.2 * k), CFrame.new(math.cos(a) * 0.45 * k, -0.05 * k, math.sin(a) * 0.45 * k) * CFrame.Angles(0, -a, -0.25), rootC, M.Wood, Cyl)
		end
	end
	-- 어깨와 등에서 돋은 작은 버섯
	local sprouts = { { -0.3, 0.45, 0.1, 1.0, -0.6 }, { -0.22, 0.42, 0.3, 0.7, -0.3 }, { 0.3, 0.45, 0.15, 0.85, 0.6 }, { 0.24, 0.3, -0.2, 0.6, 0.9 }, { -0.1, 0.1, 0.34, 0.75, -0.1 }, { 0.12, -0.2, 0.34, 0.6, 0.15 } }
	for _, s in ipairs(sprouts) do
		local x, y, z, sc, tilt = s[1], s[2], s[3], s[4] * 1.15, s[5]
		local at = CFrame.new(x * ut.X, ut.Y * y, z * ut.X) * CFrame.Angles(z > 0.25 and math.rad(60) or 0, 0, -tilt * 0.6)
		rod(model, "UpperTorso", "SproutStem", 0.55 * sc * k, 0.2 * sc * k, at * CFrame.new(0, 0.27 * sc * k, 0), stem)
		ell(model, "UpperTorso", "SproutCap", Vector3.new(0.8 * sc * k, 0.42 * sc * k, 0.8 * sc * k), at * CFrame.new(0, 0.56 * sc * k, 0), cap)
	end
	if look.spore then
		glow(model, "Head", look.spore, 8 * k, 0.8)
	end
end

------------------------------------------------------------------------
-- 입히기
------------------------------------------------------------------------
function Dress.enemy(model: Model, typeId: string, def: any, isBoss: boolean)
	local look = Dress.lookOf(typeId, isBoss)
	if not partOf(model, "Head") then
		return
	end
	local K = sizeOf(model, "UpperTorso").Y / 1.6
	local P = {
		top = look.top or (def and def.shirt) or C3(110, 90, 70),
		bottom = look.bottom or (def and def.pants) or C3(60, 50, 40),
	}
	P.trim = look.trim or dark(P.top, 0.35)
	P.sash = look.sash or P.trim
	P.wrap = look.wrap or light(P.bottom, 0.45):Lerp(C3(220, 210, 190), 0.3)
	P.shoe = look.shoe or C3(36, 30, 26)
	local bossBody = isBoss and BOSS_BODY[typeId] or nil
	if bossBody then
		bossBody(model, look, K)
	elseif look.form then
		local fn = FORMS[look.form]
		if fn then
			fn(model, look, K, isBoss)
		end
	else
		headgear(model, look, P)
		face(model, look)
		outfit(model, look, P, K)
	end
	if isBoss and not bossBody then
		local sig = SIG[typeId]
		if sig then
			local ok, err = pcall(sig, model, look, K, P)
			if not ok then
				warn("[권왕] 보스 표식 오류:", typeId, err)
			end
		elseif not look.form then
			mantle(model, look.robe or dark(P.top, 0.2), P.trim, K, 3.0)
		end
	end
end

return Dress
