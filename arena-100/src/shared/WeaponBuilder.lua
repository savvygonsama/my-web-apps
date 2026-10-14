-- WeaponBuilder (ModuleScript, ReplicatedStorage)
-- 서버는 캐릭터 손에, 클라이언트는 무기고 미리보기에 같은 모양을 만든다.
-- 무기 모양과 장식은 GradeStyle이 정한 등급별 디자인을 따른다. 등급이 하나만 달라도 모양이 다르다.
--
-- 빛은 은은하게, 멋은 모양으로: 톱날(15~), 금빛 문양(30~), 갈라진 칼끝(35~), 소용돌이 가드(40~),
-- 늘어진 사슬(55~), 칼끝 너머 떠 있는 칼날 조각(75~)
-- 모든 등급: 등급 고유 색, 속성 입자, 휘두를 때 궤적
-- 등급이 오를 때마다: 룬 문자 → 가시 → 보석 → 떠다니는 구슬(12~) → 빛 테두리(21~) → 빛 고리(30~)
--                   → 날개(45~) → 구슬을 잇는 빛줄기(50~) → 두 겹 칼날(60~) → 회전 파편(70~) → 검 왕관(85~)
-- 희귀도는 보석 색과 궤적 끝 색으로 보이고, 전설은 금빛 반짝임이 붙는다.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GradeStyle = require(ReplicatedStorage:WaitForChild("GradeStyle"))

local Builder = {}
Builder.RAINBOW = GradeStyle.RAINBOW

local DARK_STEEL = Color3.fromRGB(60, 62, 70)
local LEATHER = Color3.fromRGB(70, 45, 30)
local GOLD = Color3.fromRGB(225, 180, 70)
local WOOD = Color3.fromRGB(85, 58, 38)

export type Look = {
	grade: number, -- 1~100 (올라운더는 100)
	rarity: number, -- 1~5
	accent: Color3, -- 희귀도 색
	scale: number?,
	lite: boolean?, -- 적 무기: 떠다니는 장식은 뺀다
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

-- 클라이언트가 매 프레임 중심 주위로 돌리는 장식 (고정 파트, 무게 없음)
local function orbitPart(parent: Instance, center: BasePart, size: Vector3, color: Color3, material: Enum.Material, shape: Enum.PartType?, opts: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Name = opts.name or "Orbit"
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.Size = size
	p.Color = color
	p.Material = material
	p.Transparency = opts.transparency or 0
	p.CFrame = center.CFrame * CFrame.new(opts.radius or 0, opts.height or 0, 0)
	local ref = Instance.new("ObjectValue")
	ref.Name = "Center"
	ref.Value = center
	ref.Parent = p
	p:SetAttribute("Radius", opts.radius or 0)
	p:SetAttribute("Height", opts.height or 0)
	p:SetAttribute("Speed", opts.speed or 1)
	p:SetAttribute("Phase", opts.phase or 0)
	p:SetAttribute("UseRotation", opts.useRotation == true)
	p:SetAttribute("Flat", opts.flat == true)
	p:SetAttribute("Tumble", opts.tumble or 0)
	CollectionService:AddTag(p, "ArenaOrbit")
	p.Parent = parent
	return p
end
Builder.orbitPart = orbitPart

local function emitter(parent: Instance, style: any, rate: number, size: number, opts: { [string]: any }?): ParticleEmitter
	local o = opts or {}
	local pe = Instance.new("ParticleEmitter")
	pe.Name = o.name or "StyleParticles"
	pe.Texture = style.motif.tex
	pe.Rate = rate
	pe.Lifetime = o.lifetime or NumberRange.new(0.5, 1.1)
	pe.Speed = o.speed or NumberRange.new(0.4, 1.8)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = o.accel or style.motif.drift
	pe.RotSpeed = NumberRange.new(-120, 120)
	pe.Rotation = NumberRange.new(0, 360)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	local dark = style.motif.id == "shadow" or style.motif.id == "void"
	pe.LightEmission = dark and 0.05 or 0.35
	pe.Color = style.rainbow and GradeStyle.RAINBOW or ColorSequence.new(style.glow, style.secondary)
	pe.Parent = parent
	return pe
end

------------------------------------------------------------------------
-- 칼날 장식
------------------------------------------------------------------------
type BladeInfo = { thick: number, width: number, length: number, startY: number, shaft: boolean? }

local function decorateBlade(ctx: Ctx, style: any, look: Look, blade: BasePart, b: BladeInfo)
	local midY = b.startY + b.length / 2
	-- 가운데 홈과 빛 테두리
	mk(ctx, "Fuller", Vector3.new(b.thick + 0.03, b.length * 0.75, math.max(0.08, b.width * 0.16)), at(midY - b.length * 0.05), style.grade >= 21 and style.glow or DARK_STEEL, style.grade >= 21 and Enum.Material.Neon or Enum.Material.Metal)
	if style.edge then
		for _, side in ipairs({ 1, -1 }) do
			mk(ctx, "Edge", Vector3.new(b.thick + 0.02, b.length * 0.92, 0.07), at(midY, side * (b.width / 2 - 0.02)), style.secondary, Enum.Material.Foil)
		end
	end
	-- 룬 문자: 칼날을 따라 빛나는 점
	local runes = math.min(style.runes, math.floor(b.length / 0.55))
	for i = 1, runes do
		local y = b.startY + 0.35 + (b.length - 0.9) * (i - 0.5) / runes
		mk(ctx, "Rune", Vector3.new(b.thick + 0.06, 0.2, 0.2), at(y, 0, 45), (i % 2 == 0) and style.secondary or style.glow, Enum.Material.Neon)
	end
	-- 가시: 칼날 한쪽을 따라 바깥으로
	local spikes = style.spikes
	for i = 1, spikes do
		local y = b.startY + b.length * (0.12 + 0.6 * (i - 1) / math.max(spikes, 1))
		local size = 0.18 + 0.03 * style.grade / 10
		mk(ctx, "Spike", Vector3.new(b.thick * 0.9, size, size), at(y, -(b.width / 2 + size * 0.25), 45), style.primary, Enum.Material.Metal)
	end
	-- 톱날: 양쪽 날을 따라 이빨
	local onShaft = b.shaft == true
	for i = 1, (onShaft and 0 or style.serrate) do
		local y = b.startY + 0.3 + b.length * 0.65 * (i - 1) / math.max(style.serrate - 1, 1)
		local size = math.max(0.12, b.width * 0.2)
		for _, side in ipairs({ 1, -1 }) do
			mk(ctx, "Serration", Vector3.new(b.thick * 0.95, size, size), at(y, side * (b.width / 2), 45), blade.Color, blade.Material)
		end
	end
	-- 금빛 문양: 칼날 양면에 V자 무늬
	if style.engrave and not onShaft then
		local n = math.max(2, math.floor(b.length / 1.4))
		for i = 1, n do
			local y = b.startY + 0.5 + (b.length - 1.2) * (i - 0.5) / n
			for _, face in ipairs({ 1, -1 }) do
				for _, tilt in ipairs({ 35, -35 }) do
					local cf = CFrame.new(face * (b.thick / 2 + 0.01), y, tilt > 0 and b.width * 0.12 or -b.width * 0.12) * CFrame.Angles(math.rad(tilt), 0, 0)
					mk(ctx, "Engrave", Vector3.new(0.03, b.width * 0.36, 0.06), cf, GOLD:Lerp(style.secondary, 0.25), Enum.Material.Foil)
				end
			end
		end
	end
	-- 떠 있는 칼날 조각: 칼끝 너머로 간격을 두고 이어진다
	for i = 1, (onShaft and 0 or style.floatBlade) do
		local y = b.startY + b.length + 0.55 + (i - 1) * 0.75
		local w = b.width * (0.7 - i * 0.1)
		mk(ctx, "FloatPiece", Vector3.new(b.thick, 0.5, math.max(0.15, w)), at(y, 0, (i % 2 == 0) and 12 or -12), blade.Color, blade.Material)
	end
	-- 두 겹 칼날: 칼날을 감싼 반투명 빛
	if style.auraBlade and not look.lite then
		local outer = mk(ctx, "AuraBlade", Vector3.new(b.thick * 2.2, b.length * 1.08, b.width * 1.45), at(midY + b.length * 0.03), style.secondary, Enum.Material.ForceField)
		outer.Transparency = 0.45
	end
	-- 빛 고리: 칼날을 두른 고리들
	for r = 1, style.halo do
		local y = b.startY + b.length * (0.3 + 0.25 * (r - 1))
		local radius = b.width * 0.75 + 0.35 + r * 0.1
		for i = 0, 9 do
			local a = (i / 10) * math.pi * 2
			mk(ctx, "Halo", Vector3.new(0.14, 0.14, radius * 0.66), CFrame.new(math.cos(a) * radius, y, math.sin(a) * radius) * CFrame.Angles(0, -a, 0), (r % 2 == 1) and GOLD:Lerp(style.secondary, 0.4) or style.secondary, Enum.Material.Foil)
		end
	end
	-- 궤적
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailBase"
	a0.Position = Vector3.new(0, -blade.Size.Y / 2 + 0.1, 0)
	a0.Parent = blade
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailTip"
	a1.Position = Vector3.new(0, blade.Size.Y / 2, 0)
	a1.Parent = blade
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = style.trailLife
	trail.MinLength = 0.05
	trail.LightEmission = 0.45
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	trail.Color = style.rainbow and GradeStyle.RAINBOW or ColorSequence.new(style.glow, look.accent)
	trail.Parent = blade

	-- 빛과 입자
	if style.grade >= 4 then
		local light = Instance.new("PointLight")
		light.Color = style.glow
		light.Range = style.lightRange
		light.Brightness = style.lightBrightness
		light.Parent = blade
	end
	emitter(blade, style, look.lite and style.particleRate * 0.4 or style.particleRate, style.particleSize)
	if style.fire and not look.lite then
		local fire = Instance.new("Fire")
		fire.Size = 2 + style.grade * 0.04
		fire.Heat = 6
		fire.Color = style.primary
		fire.SecondaryColor = style.secondary
		fire.Parent = blade
	end
	if style.smoke and not look.lite then
		local smoke = Instance.new("Smoke")
		smoke.Color = style.primary
		smoke.Opacity = 0.12
		smoke.RiseVelocity = 2
		smoke.Size = 1.5
		smoke.Parent = blade
	end
	if style.sparkles or look.rarity >= 5 then
		local sp = Instance.new("Sparkles")
		sp.SparkleColor = look.rarity >= 5 and GOLD or style.glow
		sp.Parent = blade
	end

	-- 떠다니는 구슬, 빛줄기, 파편 (클라이언트가 돌린다)
	if look.lite then
		return
	end
	local tip = Instance.new("Attachment")
	tip.Name = "BeamTip"
	tip.Position = Vector3.new(0, blade.Size.Y / 2, 0)
	tip.Parent = blade
	for i = 1, style.orbs do
		local orb = orbitPart(ctx.parent, blade, Vector3.new(0.45, 0.45, 0.45) * ctx.scale * (1 + style.power * 0.6), (i % 2 == 0) and style.secondary or style.glow, Enum.Material.Glass, Enum.PartType.Ball, {
			name = "Orb",
			radius = (b.width * 0.8 + 0.7) * ctx.scale,
			height = (-blade.Size.Y / 2) + blade.Size.Y * (i / (style.orbs + 1)),
			speed = 2.2,
			phase = i * (math.pi * 2 / style.orbs),
			useRotation = true,
		})
		if style.beams then
			local att = Instance.new("Attachment")
			att.Parent = orb
			local beam = Instance.new("Beam")
			beam.Attachment0 = tip
			beam.Attachment1 = att
			beam.Width0 = 0.12
			beam.Width1 = 0.05
			beam.FaceCamera = true
			beam.LightEmission = 0.4
			beam.Segments = 8
			beam.CurveSize0 = 0.8
			beam.CurveSize1 = -0.8
			beam.Color = style.rainbow and GradeStyle.RAINBOW or ColorSequence.new(style.glow, style.secondary)
			beam.Transparency = NumberSequence.new(0.45)
			beam.Parent = orb
		end
	end
	for i = 1, style.shards do
		orbitPart(ctx.parent, blade, Vector3.new(0.12, 0.45, 0.22) * ctx.scale, (i % 3 == 0) and style.secondary or style.glow, Enum.Material.Glass, nil, {
			name = "Shard",
			radius = (b.width * 1.2 + 1.3) * ctx.scale,
			height = (-blade.Size.Y / 2) + blade.Size.Y * ((i % 6) + 1) / 7,
			speed = -3.2,
			phase = i * 0.9,
			useRotation = true,
			tumble = 4,
		})
	end
end

-- 가드: 보석, 날개, 검 왕관
local function decorateGuard(ctx: Ctx, style: any, look: Look, guardY: number, guardW: number)
	local n = style.gems
	for i = 1, n do
		local z = (n == 1) and 0 or (-guardW * 0.35 + guardW * 0.7 * (i - 1) / (n - 1))
		mk(ctx, "Gem", Vector3.new(0.34, 0.34, 0.34), at(guardY, z, 45), (i == (n + 1) // 2) and look.accent or style.glow, Enum.Material.Neon)
	end
	if style.wings then
		local w = style.wingSize
		for _, side in ipairs({ 1, -1 }) do
			for f = 0, 2 do
				local len = (1.6 - f * 0.35) * w
				mk(ctx, "Wing", Vector3.new(0.12, len, 0.38 * w), at(guardY + 0.25 + f * 0.18, side * (guardW / 2 + len * 0.3), side * (35 + f * 18)), (f == 0) and GOLD:Lerp(style.glow, 0.5) or style.secondary, style.grade >= 70 and Enum.Material.Glass or Enum.Material.Foil)
			end
		end
	end
	if style.ornateGuard then
		for _, side in ipairs({ 1, -1 }) do
			for c = 0, 3 do
				local a = math.rad(c * 70)
				local r = 0.35
				local cf = CFrame.new(0, guardY + math.sin(a) * r, side * (guardW / 2 + 0.2 + math.cos(a) * r * 0.6)) * CFrame.Angles(side * a, 0, 0)
				mk(ctx, "Curl", Vector3.new(0.14, 0.32, 0.12), cf, GOLD:Lerp(style.primary, 0.3), Enum.Material.Foil)
			end
		end
	end
	if style.chains > 0 and not look.lite then
		for c = 1, style.chains do
			local z = -guardW * 0.4 + guardW * 0.8 * (c - 1) / math.max(style.chains - 1, 1)
			for l = 1, 5 do
				mk(ctx, "Chain", Vector3.new(0.08, 0.26, 0.16), CFrame.new(0, guardY - 0.15 - l * 0.24, z) * CFrame.Angles(0, (l % 2 == 0) and math.rad(90) or 0, 0), Color3.fromRGB(170, 170, 180), Enum.Material.Metal)
			end
			mk(ctx, "Tassel", Vector3.new(0.22, 0.22, 0.22), at(guardY - 1.45, z), style.primary, Enum.Material.Fabric, Enum.PartType.Ball)
		end
	end
	if style.crown and not look.lite then
		for i = 0, 7 do
			local a = (i / 8) * math.pi * 2
			mk(ctx, "CrownBlade", Vector3.new(0.1, 0.9, 0.22), CFrame.new(math.cos(a) * 0.5, guardY - 0.5, math.sin(a) * 0.5) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(-55)), GOLD:Lerp(style.glow, 0.3), Enum.Material.Foil)
		end
	end
end

------------------------------------------------------------------------
-- 계열별 모양
------------------------------------------------------------------------
type Dims = { handle: number, guardW: number, bladeW: number, bladeL: number, bladeT: number, pommel: boolean }

local DIMS: { [number]: Dims } = {
	[1] = { handle = 1.8, guardW = 2.8, bladeW = 1.25, bladeL = 5.6, bladeT = 0.26, pommel = true }, -- 대검
	[2] = { handle = 1.0, guardW = 1.1, bladeW = 0.5, bladeL = 3.0, bladeT = 0.16, pommel = false }, -- 쌍검
	[3] = { handle = 1.7, guardW = 1.8, bladeW = 0.52, bladeL = 7.0, bladeT = 0.18, pommel = true }, -- 장검
	[4] = { handle = 0.9, guardW = 0.9, bladeW = 0.44, bladeL = 1.9, bladeT = 0.15, pommel = false }, -- 단검
	[0] = { handle = 1.9, guardW = 3.0, bladeW = 1.4, bladeL = 6.6, bladeT = 0.3, pommel = true }, -- 올라운더
}

local function straightSword(ctx: Ctx, style: any, look: Look, typeId: number): BasePart
	local d = DIMS[typeId] or DIMS[1]
	local bladeL = d.bladeL * style.lengthMul
	local bladeW = d.bladeW * style.widthMul
	local guardColor = look.rarity >= 5 and GOLD or style.primary:Lerp(DARK_STEEL, 0.55)
	local handleColor = style.grade >= 50 and style.primary:Lerp(Color3.new(0, 0, 0), 0.6) or LEATHER
	mk(ctx, "Grip", Vector3.new(0.34, d.handle, 0.34), at(0), handleColor, Enum.Material.Fabric)
	for i = 1, 3 do
		mk(ctx, "Wrap", Vector3.new(0.38, 0.08, 0.38), at(-d.handle / 2 + d.handle * i / 4), guardColor, Enum.Material.Metal)
	end
	if d.pommel then
		local pommel = mk(ctx, "Pommel", Vector3.new(0.6, 0.6, 0.6), at(-d.handle / 2 - 0.2), guardColor, style.grade >= 30 and Enum.Material.Neon or Enum.Material.Metal, Enum.PartType.Ball)
		if style.grade >= 30 then
			pommel.Color = style.glow
		end
	end
	local guardY = d.handle / 2 + 0.12
	mk(ctx, "Guard", Vector3.new(0.48, 0.32, d.guardW), at(guardY), guardColor, Enum.Material.Metal)
	if typeId == 1 or typeId == 0 or typeId == 3 then
		for _, side in ipairs({ 1, -1 }) do
			mk(ctx, "GuardTip", Vector3.new(0.48, 0.6, 0.3), at(guardY + 0.18, side * d.guardW / 2), guardColor, Enum.Material.Metal)
		end
	end
	if typeId == 4 then
		mk(ctx, "Knuckle", Vector3.new(0.2, d.handle * 1.1, 0.14), at(0, -0.42), guardColor, Enum.Material.Metal)
	end
	decorateGuard(ctx, style, look, guardY, d.guardW)

	local bladeColor = style.primary:Lerp(Color3.fromRGB(230, 232, 238), style.grade < 55 and 0.45 or 0.1)
	if style.bladeDark then
		bladeColor = Color3.fromRGB(28, 24, 34):Lerp(style.primary, 0.3)
	end
	local startY = guardY + 0.16
	local blade = mk(ctx, "Blade", Vector3.new(d.bladeT, bladeL, bladeW), at(startY + bladeL / 2), bladeColor, style.bladeMaterial)
	blade.Reflectance = style.reflect
	-- 칼끝: 45도 돌린 네모로 뾰족하게
	if style.prongs then
		-- 갈라진 칼끝: 두 갈래로 벌어진다
		local tipSize = bladeW * 0.5
		for _, side in ipairs({ 1, -1 }) do
			local prong = mk(ctx, "BladeTip", Vector3.new(d.bladeT, tipSize * 1.6, tipSize * 0.7), at(startY + bladeL + tipSize * 0.5, side * bladeW * 0.24, side * -14), bladeColor, style.bladeMaterial)
			prong.Reflectance = style.reflect
		end
	else
		local tipSize = bladeW * 0.71
		local tipPart = mk(ctx, "BladeTip", Vector3.new(d.bladeT, tipSize, tipSize), at(startY + bladeL, 0, 45), bladeColor, style.bladeMaterial)
		tipPart.Reflectance = style.reflect
	end
	if typeId == 0 then
		mk(ctx, "Core", Vector3.new(d.bladeT + 0.05, bladeL * 0.85, 0.3), at(startY + bladeL * 0.45), Color3.fromRGB(255, 150, 210), Enum.Material.Neon)
	end
	decorateBlade(ctx, style, look, blade, { thick = d.bladeT, width = bladeW, length = bladeL, startY = startY })
	return blade
end

local function scythe(ctx: Ctx, style: any, look: Look): BasePart
	local bc = style.primary:Lerp(Color3.fromRGB(230, 232, 238), style.grade < 55 and 0.45 or 0.1)
	if style.bladeDark then
		bc = Color3.fromRGB(28, 24, 34):Lerp(style.primary, 0.3)
	end
	local ringColor = look.rarity >= 5 and GOLD or style.primary:Lerp(DARK_STEEL, 0.5)
	local shaftLen = 6.4 * (1 + style.power * 0.2)
	local shaft = mk(ctx, "Shaft", Vector3.new(0.3, shaftLen, 0.3), at(shaftLen / 2 - 0.6), style.grade >= 50 and style.primary:Lerp(Color3.new(0, 0, 0), 0.55) or WOOD, Enum.Material.Wood)
	local bands = 3 + math.min(4, style.grade // 15)
	for i = 1, bands do
		mk(ctx, "Band", Vector3.new(0.4, 0.2, 0.4), at(-0.4 + (shaftLen - 0.4) * i / (bands + 1)), ringColor, Enum.Material.Metal)
	end
	local oy = shaftLen - 0.8
	decorateGuard(ctx, style, look, oy, 0.8)
	-- 날: 자루 끝에서 원을 따라 아래로, 뒤로 휜다
	local radius = 2.6 * style.lengthMul
	local segs = 6
	local sweep = 115
	local last: Part? = nil
	for i = 0, segs - 1 do
		local a0 = math.rad(sweep * i / segs)
		local a1 = math.rad(sweep * (i + 1) / segs)
		local y0, z0 = oy - radius + radius * math.cos(a0), -radius * math.sin(a0)
		local y1, z1 = oy - radius + radius * math.cos(a1), -radius * math.sin(a1)
		local dy, dz = y1 - y0, z1 - z0
		local len = math.sqrt(dy * dy + dz * dz) + 0.08
		local width = (0.75 - 0.5 * (i / (segs - 1))) * style.widthMul
		local angle = math.deg(math.atan2(dz, dy))
		local cf = CFrame.new(0, (y0 + y1) / 2, (z0 + z1) / 2) * CFrame.Angles(math.rad(angle), 0, 0) * CFrame.new(0, 0, width / 2 - 0.1)
		local seg = mk(ctx, "Blade" .. i, Vector3.new(0.14, len, width), cf, bc, style.bladeMaterial)
		seg.Reflectance = style.reflect
		if style.edge then
			mk(ctx, "Edge" .. i, Vector3.new(0.16, len, 0.08), cf * CFrame.new(0, 0, width / 2), style.secondary, Enum.Material.Neon)
		end
		if i % 2 == 0 and style.runes > i then
			mk(ctx, "Rune" .. i, Vector3.new(0.2, 0.18, 0.18), cf * CFrame.Angles(math.rad(45), 0, 0), style.glow, Enum.Material.Neon)
		end
		last = seg
	end
	mk(ctx, "TopSpike", Vector3.new(0.14, 0.5, 0.5) * (1 + style.power), at(oy + 0.35, 0, 45), bc, style.bladeMaterial)
	-- 장식은 자루 기준으로 붙인다 (구슬은 자루 위쪽을 돈다)
	decorateBlade(ctx, style, look, shaft, { thick = 0.3, width = 0.5, length = shaftLen, startY = -0.6, shaft = true })
	return (last :: Part)
end

-- 무기 하나를 손에 붙인다. 손에 붙은 Model을 돌려준다
function Builder.build(parent: Instance, hand: BasePart, typeId: number, look: Look, gripOverride: CFrame?): Model
	local model = Instance.new("Model")
	model.Name = "Weapon"
	model.Parent = parent
	local grade = typeId == 0 and 100 or look.grade
	local style = GradeStyle.get(grade)
	local grip = gripOverride or (hand.CFrame * CFrame.new(0, -hand.Size.Y / 2, 0) * CFrame.Angles(math.rad(-90), 0, 0))
	local ctx: Ctx = { parent = model, hand = hand, grip = grip, scale = (look.scale or 1) * style.scale }
	if typeId == 5 then
		scythe(ctx, style, look)
	else
		straightSword(ctx, style, look, typeId)
	end
	return model
end

------------------------------------------------------------------------
-- 캐릭터 오라: 장착한 무기 등급마다 다르다
------------------------------------------------------------------------
function Builder.applyAura(char: Model, grade: number)
	local root = char:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	local old = char:FindFirstChild("ArenaAura")
	if old then
		old:Destroy()
	end
	for _, child in ipairs(root:GetChildren()) do
		if child.Name == "RankAura" then
			child:Destroy()
		end
	end
	local style = GradeStyle.get(grade)
	local holder = Instance.new("Model")
	holder.Name = "ArenaAura"
	holder.Parent = char

	if style.aura then
		local pe = emitter(root, style, style.auraRate, 0.5 + style.power * 0.9, {
			name = "RankAura",
			lifetime = NumberRange.new(0.8, 1.5),
			speed = NumberRange.new(1, 3),
		})
		pe.SpreadAngle = Vector2.new(40, 40)
		pe.EmissionDirection = Enum.NormalId.Top
	end
	if style.groundRing then
		orbitPart(holder, root, Vector3.new(0.12, 4.5 + style.grade * 0.05, 4.5 + style.grade * 0.05), style.glow, Enum.Material.ForceField, Enum.PartType.Cylinder, {
			name = "AuraRing",
			height = -2.85,
			speed = 0.8,
			flat = true,
			transparency = 0.3,
		})
	end
	if style.secondRing then
		orbitPart(holder, root, Vector3.new(0.1, 7 + style.grade * 0.04, 7 + style.grade * 0.04), style.secondary, Enum.Material.ForceField, Enum.PartType.Cylinder, {
			name = "AuraRing2",
			height = -2.8,
			speed = -0.6,
			flat = true,
			transparency = 0.2,
		})
	end
	for i = 1, style.bodyOrbs do
		local orb = orbitPart(holder, root, Vector3.new(0.6, 0.6, 0.6) * (1 + style.power * 0.5), (i % 2 == 0) and style.secondary or style.glow, Enum.Material.Glass, Enum.PartType.Ball, {
			name = "AuraOrb",
			radius = 3.2,
			height = 0.2 + (i % 3) * 0.6,
			speed = 1.6,
			phase = i * (math.pi * 2 / style.bodyOrbs),
		})
		local tr = Instance.new("Trail")
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.25, 0)
		a0.Parent = orb
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.25, 0)
		a1.Parent = orb
		tr.Attachment0 = a0
		tr.Attachment1 = a1
		tr.Lifetime = 0.35
		tr.LightEmission = 0.3
		tr.Color = style.rainbow and GradeStyle.RAINBOW or ColorSequence.new(orb.Color)
		tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
		tr.Parent = orb
	end
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if style.bodyWings and torso and torso:IsA("BasePart") then
		local size = 1 + (style.grade - 65) / 25
		local ctx: Ctx = { parent = holder, hand = torso, grip = torso.CFrame * CFrame.new(0, 0.4, torso.Size.Z / 2 + 0.25), scale = 1 }
		for _, side in ipairs({ 1, -1 }) do
			for f = 0, 3 do
				local len = (2.8 - f * 0.45) * size
				local cf = CFrame.new(side * (0.5 + len * 0.35), 0.4 - f * 0.35, f * 0.05) * CFrame.Angles(0, 0, math.rad(side * (-60 + f * 22)))
				local feather = mk(ctx, "Wing", Vector3.new(0.12, len, 0.55 * size), CFrame.new(cf.Position) * cf.Rotation * CFrame.Angles(0, math.rad(90), 0), (f % 2 == 0) and GOLD:Lerp(style.glow, 0.6) or style.secondary, style.grade >= 85 and Enum.Material.Glass or Enum.Material.Foil)
				feather.Transparency = 0.05
			end
		end
	end
	local head = char:FindFirstChild("Head")
	if style.bodyHalo and head and head:IsA("BasePart") then
		local ctx: Ctx = { parent = holder, hand = head, grip = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.7, 0), scale = 1 }
		for i = 0, 11 do
			local a = (i / 12) * math.pi * 2
			mk(ctx, "Halo", Vector3.new(0.12, 0.12, 0.5), CFrame.new(math.cos(a) * 0.95, 0, math.sin(a) * 0.95) * CFrame.Angles(0, -a, 0), GOLD:Lerp(style.glow, 0.3), Enum.Material.Foil)
		end
	end
	if style.bodyLight then
		local light = Instance.new("PointLight")
		light.Name = "RankAura"
		light.Color = style.glow
		light.Range = 6 + style.power * 6
		light.Brightness = 0.4 + style.power * 0.6
		light.Parent = root
	end
end

return Builder
