-- WeaponBuilder (ModuleScript, ReplicatedStorage)
-- 서버는 캐릭터 손에, 클라이언트는 무기고 미리보기에 같은 모양을 만든다.
-- 무기 모양, 등급별 빛 효과, 플레이어 오라를 만든다.
--
-- 구간이 오를수록 화려해진다
--   1구간: 쇠 칼날
--   2구간: + 희귀도 색 보석, 휘두를 때 궤적
--   3구간: + 칼날 가운데 빛나는 홈, 은은한 빛
--   4구간: + 유리 칼날, 반짝이 파티클
--   5구간: + 우주 칼날(포스필드), 별 파티클
--   6구간: + 빛나는 칼날, 무지개 궤적과 파티클
-- 전설 희귀도는 어느 구간이든 금빛 반짝임이 더해진다

local Builder = {}

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 230, 110)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 200, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(150, 100, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 200)),
})
Builder.RAINBOW = RAINBOW

local STEEL = Color3.fromRGB(205, 208, 214)
local DARK_STEEL = Color3.fromRGB(70, 72, 80)
local LEATHER = Color3.fromRGB(70, 45, 30)
local GOLD = Color3.fromRGB(225, 180, 70)
local WOOD = Color3.fromRGB(85, 58, 38)

export type Look = {
	accent: Color3, -- 희귀도 색
	section: number, -- 1~6
	rarity: number, -- 1~5
	scale: number,
}

type Ctx = {
	parent: Instance,
	hand: BasePart,
	grip: CFrame,
	scale: number,
}

-- 무기 공간: Y = 칼끝 방향, Z = 칼날 폭(세로), X = 칼 두께
local function mk(ctx: Ctx, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size * ctx.scale
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = ctx.grip * CFrame.new(offset.Position * ctx.scale) * offset.Rotation
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ctx.hand
	weld.Part1 = p
	weld.Parent = p
	p.Parent = ctx.parent
	return p
end

local function at(y: number, z: number?, rx: number?): CFrame
	return CFrame.new(0, y, z or 0) * CFrame.Angles(math.rad(rx or 0), 0, 0)
end

-- 구간에 따른 칼날 재질과 색
local function bladeStyle(look: Look): (Color3, Enum.Material)
	local s = look.section
	if s >= 6 then
		return Color3.fromRGB(255, 235, 245), Enum.Material.Neon
	elseif s == 5 then
		return look.accent, Enum.Material.ForceField
	elseif s == 4 then
		return STEEL:Lerp(look.accent, 0.55), Enum.Material.Glass
	elseif s == 3 then
		return STEEL:Lerp(look.accent, 0.3), Enum.Material.Metal
	end
	return STEEL:Lerp(look.accent, 0.15), Enum.Material.Metal
end

-- 칼날 가운데 홈. 3구간부터 빛난다
local function fuller(ctx: Ctx, look: Look, thickness: number, length: number, y: number)
	if look.section >= 3 then
		mk(ctx, "Fuller", Vector3.new(thickness + 0.04, length, 0.16), at(y), look.accent, Enum.Material.Neon)
	else
		mk(ctx, "Fuller", Vector3.new(thickness + 0.02, length, 0.12), at(y), DARK_STEEL, Enum.Material.Metal)
	end
end

local function gem(ctx: Ctx, look: Look, y: number, size: number)
	if look.section >= 2 or look.rarity >= 4 then
		mk(ctx, "Gem", Vector3.new(size, size, size), at(y, 0, 45), look.accent, Enum.Material.Neon)
	end
end

-- 칼끝: 45도 돌린 네모로 뾰족하게
local function tip(ctx: Ctx, color: Color3, material: Enum.Material, thickness: number, width: number, y: number): Part
	local d = width * 0.71
	return mk(ctx, "Tip", Vector3.new(thickness, d, d), at(y, 0, 45), color, material)
end

-- 무기 모양들. 각각 궤적 시작점과 끝점이 될 파트를 돌려준다
local shapes: { [number]: (Ctx, Look) -> (BasePart, Vector3, Vector3) } = {}

-- 대검: 넓고 두꺼운 칼날, 커다란 십자 가드
shapes[1] = function(ctx, look)
	local bc, bm = bladeStyle(look)
	local guardColor = look.rarity >= 5 and GOLD or DARK_STEEL
	mk(ctx, "Grip", Vector3.new(0.36, 1.8, 0.36), at(0), LEATHER, Enum.Material.Fabric)
	mk(ctx, "Pommel", Vector3.new(0.62, 0.62, 0.62), at(-1.05), guardColor, Enum.Material.Metal, Enum.PartType.Ball)
	mk(ctx, "Guard", Vector3.new(0.5, 0.36, 2.8), at(1.05), guardColor, Enum.Material.Metal)
	mk(ctx, "GuardL", Vector3.new(0.5, 0.7, 0.36), at(1.25, 1.3), guardColor, Enum.Material.Metal)
	mk(ctx, "GuardR", Vector3.new(0.5, 0.7, 0.36), at(1.25, -1.3), guardColor, Enum.Material.Metal)
	gem(ctx, look, 1.05, 0.5)
	local blade = mk(ctx, "Blade", Vector3.new(0.26, 5.6, 1.25), at(4.03), bc, bm)
	fuller(ctx, look, 0.26, 4.4, 3.6)
	tip(ctx, bc, bm, 0.26, 1.25, 6.83)
	return blade, Vector3.new(0, -2.6, 0), Vector3.new(0, 3.1, 0)
end

-- 쌍검: 짧고 날렵한 칼날 (손마다 하나)
shapes[2] = function(ctx, look)
	local bc, bm = bladeStyle(look)
	local guardColor = look.rarity >= 5 and GOLD or DARK_STEEL
	mk(ctx, "Grip", Vector3.new(0.28, 1.0, 0.28), at(0), LEATHER, Enum.Material.Fabric)
	mk(ctx, "Guard", Vector3.new(0.36, 0.2, 1.1), at(0.6, 0, -12), guardColor, Enum.Material.Metal)
	gem(ctx, look, 0.6, 0.3)
	local blade = mk(ctx, "Blade", Vector3.new(0.16, 3.0, 0.5), at(2.2, 0.08, 4), bc, bm)
	tip(ctx, bc, bm, 0.16, 0.5, 3.75)
	if look.section >= 3 then
		mk(ctx, "Edge", Vector3.new(0.18, 2.6, 0.08), at(2.1, 0.3, 4), look.accent, Enum.Material.Neon)
	end
	return blade, Vector3.new(0, -1.4, 0), Vector3.new(0, 1.6, 0)
end

-- 장검: 아주 길고 가는 칼날, 고리 모양 가드
shapes[3] = function(ctx, look)
	local bc, bm = bladeStyle(look)
	local guardColor = look.rarity >= 5 and GOLD or DARK_STEEL
	mk(ctx, "Grip", Vector3.new(0.3, 1.7, 0.3), at(0), LEATHER, Enum.Material.Fabric)
	mk(ctx, "Pommel", Vector3.new(0.45, 0.45, 0.45), at(-0.95), guardColor, Enum.Material.Metal, Enum.PartType.Ball)
	mk(ctx, "Guard", Vector3.new(0.4, 0.26, 1.8), at(0.95), guardColor, Enum.Material.Metal)
	mk(ctx, "GuardL", Vector3.new(0.4, 0.55, 0.26), at(0.75, 0.9), guardColor, Enum.Material.Metal)
	mk(ctx, "GuardR", Vector3.new(0.4, 0.55, 0.26), at(0.75, -0.9), guardColor, Enum.Material.Metal)
	gem(ctx, look, 0.95, 0.36)
	local blade = mk(ctx, "Blade", Vector3.new(0.18, 7.0, 0.52), at(4.6), bc, bm)
	fuller(ctx, look, 0.18, 5.8, 4.2)
	tip(ctx, bc, bm, 0.18, 0.52, 8.1)
	return blade, Vector3.new(0, -3.3, 0), Vector3.new(0, 3.6, 0)
end

-- 단검: 짧은 칼날과 손가락 보호대
shapes[4] = function(ctx, look)
	local bc, bm = bladeStyle(look)
	local guardColor = look.rarity >= 5 and GOLD or DARK_STEEL
	mk(ctx, "Grip", Vector3.new(0.3, 0.9, 0.3), at(0), LEATHER, Enum.Material.Fabric)
	mk(ctx, "Guard", Vector3.new(0.4, 0.2, 0.9), at(0.55), guardColor, Enum.Material.Metal)
	mk(ctx, "Knuckle", Vector3.new(0.2, 1.1, 0.16), at(0, -0.45), guardColor, Enum.Material.Metal)
	gem(ctx, look, 0.55, 0.28)
	local blade = mk(ctx, "Blade", Vector3.new(0.15, 1.9, 0.44), at(1.6), bc, bm)
	tip(ctx, bc, bm, 0.15, 0.44, 2.55)
	if look.section >= 3 then
		mk(ctx, "Edge", Vector3.new(0.17, 1.7, 0.08), at(1.5, 0.22), look.accent, Enum.Material.Neon)
	end
	return blade, Vector3.new(0, -0.9, 0), Vector3.new(0, 1.0, 0)
end

-- 낫: 긴 자루 끝에서 아래로 휘어 내려오는 날
shapes[5] = function(ctx, look)
	local bc, bm = bladeStyle(look)
	local ringColor = look.rarity >= 5 and GOLD or DARK_STEEL
	mk(ctx, "Shaft", Vector3.new(0.3, 6.4, 0.3), at(2.6), WOOD, Enum.Material.Wood)
	for i, y in ipairs({ 0.2, 2.8, 5.4 }) do
		mk(ctx, "Band" .. i, Vector3.new(0.4, 0.22, 0.4), at(y), ringColor, Enum.Material.Metal)
	end
	gem(ctx, look, 5.85, 0.36)
	-- 날: 자루 끝(O)에서 시작해 원을 따라 아래로, 뒤로 휜다
	local oy, radius, segs, sweep = 5.8, 2.6, 5, 110
	local last: Part? = nil
	for i = 0, segs - 1 do
		local a0 = math.rad(sweep * i / segs)
		local a1 = math.rad(sweep * (i + 1) / segs)
		local y0, z0 = oy - radius + radius * math.cos(a0), -radius * math.sin(a0)
		local y1, z1 = oy - radius + radius * math.cos(a1), -radius * math.sin(a1)
		local dy, dz = y1 - y0, z1 - z0
		local len = math.sqrt(dy * dy + dz * dz) + 0.08
		local width = 0.7 - 0.45 * (i / (segs - 1))
		local angle = math.deg(math.atan2(dz, dy))
		-- 날은 바깥쪽(자루 쪽 반대)으로 폭을 준다
		local cf = CFrame.new(0, (y0 + y1) / 2, (z0 + z1) / 2) * CFrame.Angles(math.rad(angle), 0, 0) * CFrame.new(0, 0, width / 2 - 0.1)
		last = mk(ctx, "Blade" .. i, Vector3.new(0.14, len, width), cf, bc, bm)
		if look.section >= 3 then
			mk(ctx, "Edge" .. i, Vector3.new(0.16, len, 0.08), cf * CFrame.new(0, 0, width / 2), look.accent, Enum.Material.Neon)
		end
	end
	tip(ctx, bc, bm, 0.14, 0.5, oy + 0.35)
	return (last :: Part), Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)
end

-- 올라운더: 거대한 백금 칼날, 날개 가드, 칼날을 감싼 빛 고리
shapes[0] = function(ctx, look)
	local bc = Color3.fromRGB(255, 248, 225)
	mk(ctx, "Grip", Vector3.new(0.38, 1.9, 0.38), at(0), Color3.fromRGB(40, 30, 60), Enum.Material.Fabric)
	mk(ctx, "Pommel", Vector3.new(0.7, 0.7, 0.7), at(-1.1), GOLD, Enum.Material.Neon, Enum.PartType.Ball)
	mk(ctx, "Guard", Vector3.new(0.55, 0.4, 3.0), at(1.1), GOLD, Enum.Material.Metal)
	mk(ctx, "WingL", Vector3.new(0.3, 2.2, 0.5), at(1.6, 1.6, 35), Color3.fromRGB(255, 240, 200), Enum.Material.Neon)
	mk(ctx, "WingR", Vector3.new(0.3, 2.2, 0.5), at(1.6, -1.6, -35), Color3.fromRGB(255, 240, 200), Enum.Material.Neon)
	mk(ctx, "Gem", Vector3.new(0.6, 0.6, 0.6), at(1.1, 0, 45), Color3.fromRGB(255, 120, 200), Enum.Material.Neon)
	local blade = mk(ctx, "Blade", Vector3.new(0.3, 6.6, 1.4), at(4.6), bc, Enum.Material.Neon)
	mk(ctx, "Core", Vector3.new(0.34, 5.6, 0.3), at(4.3), Color3.fromRGB(255, 150, 210), Enum.Material.Neon)
	tip(ctx, bc, Enum.Material.Neon, 0.3, 1.4, 7.9)
	for i = 0, 9 do
		local a = (i / 10) * math.pi * 2
		local cf = CFrame.new(math.cos(a) * 1.3, 5.2, math.sin(a) * 1.3) * CFrame.Angles(0, -a, 0)
		mk(ctx, "Halo" .. i, Vector3.new(0.2, 0.2, 0.85), cf, GOLD, Enum.Material.Neon)
	end
	return blade, Vector3.new(0, -3.1, 0), Vector3.new(0, 3.6, 0)
end

local function addTrail(blade: BasePart, a0Pos: Vector3, a1Pos: Vector3, look: Look, rainbow: boolean)
	if a0Pos == a1Pos then
		a0Pos = Vector3.new(0, -blade.Size.Y / 2, 0)
		a1Pos = Vector3.new(0, blade.Size.Y / 2, 0)
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailBase"
	a0.Position = a0Pos
	a0.Parent = blade
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailTip"
	a1.Position = a1Pos
	a1.Parent = blade
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = look.section >= 4 and 0.28 or 0.18
	trail.MinLength = 0.05
	trail.LightEmission = look.section >= 3 and 0.8 or 0.3
	trail.FaceCamera = false
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Color = rainbow and RAINBOW or ColorSequence.new(look.accent)
	trail.Parent = blade
end

local function addSparkles(blade: BasePart, look: Look, rainbow: boolean)
	local p = Instance.new("ParticleEmitter")
	p.Name = "BladeSparkle"
	p.Rate = look.section >= 5 and 14 or 8
	p.Lifetime = NumberRange.new(0.5, 1.0)
	p.Speed = NumberRange.new(0.3, 1.2)
	p.SpreadAngle = Vector2.new(180, 180)
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, look.section >= 5 and 0.3 or 0.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	p.LightEmission = 1
	p.Color = rainbow and RAINBOW or ColorSequence.new(look.accent)
	p.Parent = blade
end

-- 무기 하나를 손에 붙인다. 손에 붙은 Model을 돌려준다
function Builder.build(parent: Instance, hand: BasePart, typeId: number, look: Look, gripOverride: CFrame?): Model
	local model = Instance.new("Model")
	model.Name = "Weapon"
	model.Parent = parent
	local grip = gripOverride or (hand.CFrame * CFrame.new(0, -hand.Size.Y / 2, 0) * CFrame.Angles(math.rad(-90), 0, 0))
	local ctx: Ctx = { parent = model, hand = hand, grip = grip, scale = look.scale }
	local shape = shapes[typeId] or shapes[1]
	local blade, a0, a1 = shape(ctx, look)
	local rainbow = look.section >= 6 or typeId == 0

	if look.section >= 2 or typeId == 0 then
		addTrail(blade, a0 * look.scale, a1 * look.scale, look, rainbow)
	end
	if look.section >= 3 or typeId == 0 then
		local light = Instance.new("PointLight")
		light.Color = rainbow and Color3.fromRGB(255, 220, 240) or look.accent
		light.Range = 6 + look.section * 1.5
		light.Brightness = 0.8 + look.section * 0.3
		light.Parent = blade
	end
	if look.section >= 4 or typeId == 0 then
		addSparkles(blade, look, rainbow)
	end
	if look.rarity >= 5 and look.section >= 2 then
		local glint = Instance.new("Sparkles")
		glint.SparkleColor = GOLD
		glint.Parent = blade
	end
	return model
end

-- 장착 무기 구간에 따라 캐릭터 주위에 오라를 붙인다
function Builder.applyAura(char: Model, section: number, color: Color3)
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for _, child in ipairs(root:GetChildren()) do
		if child.Name == "RankAura" then
			child:Destroy()
		end
	end
	if section < 3 then
		return
	end
	local rainbow = section >= 6
	local aura = Instance.new("ParticleEmitter")
	aura.Name = "RankAura"
	aura.Rate = 4 + (section - 3) * 4
	aura.Lifetime = NumberRange.new(0.8, 1.4)
	aura.Speed = NumberRange.new(1.5, 3)
	aura.SpreadAngle = Vector2.new(25, 25)
	aura.EmissionDirection = Enum.NormalId.Top
	aura.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6 + section * 0.1),
		NumberSequenceKeypoint.new(1, 0),
	})
	aura.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	aura.LightEmission = 0.8
	aura.Color = rainbow and RAINBOW or ColorSequence.new(color)
	aura.Parent = root
	if section >= 5 then
		local light = Instance.new("PointLight")
		light.Name = "RankAura"
		light.Color = rainbow and Color3.fromRGB(255, 200, 235) or color
		light.Range = 10
		light.Brightness = 1.2
		light.Parent = root
	end
end

return Builder
