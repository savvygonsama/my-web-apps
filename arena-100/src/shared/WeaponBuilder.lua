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
-- 칼날 모양 12종(곧은 날, 나뭇잎, 식칼, 곡도, 물결, 언월, 빈 틀, 쌍날, 갈고리, 초승달, 용골, 수정)이 등급마다 바뀐다.
-- 강화 +1~+10: 단계마다 장식이 하나씩 붙는다 (빛 날끝 → 문장 보석 → 룬 홈 → 지느러미 → 각인
--   → 등날 → 칼끝 고리 → 불꽃 등가시 → 빛의 칼집 → 황금 왕관과 번개)

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
	enh: number?, -- 강화 단계 0~10
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
	if opts.bob then
		p:SetAttribute("Bob", opts.bob)
		p:SetAttribute("BobSpeed", opts.bobSpeed or 2)
	end
	if opts.offsetPos then
		p:SetAttribute("OffsetPos", opts.offsetPos)
	end
	if opts.offsetRot then
		p:SetAttribute("OffsetRot", opts.offsetRot)
	end
	if opts.axis then
		p:SetAttribute("Axis", opts.axis)
	end
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
-- 칼날 조각: 칼날은 여러 조각을 이어 만든다. 장식은 조각을 따라 붙는다
------------------------------------------------------------------------
type Seg = { cf: CFrame, len: number, width: number, thick: number }

-- 칼날 위 t(0=손잡이 쪽, 1=칼끝) 자리의 좌표와 그 조각
local function sample(segs: { Seg }, t: number): (CFrame, Seg)
	local n = #segs
	local x = math.clamp(t, 0, 0.9999) * n
	local i = math.floor(x) + 1
	local seg = segs[i]
	local frac = x - (i - 1)
	return seg.cf * CFrame.new(0, (frac - 0.5) * seg.len, 0), seg
end

local function bladeColorOf(style: any): Color3
	if style.bladeDark then
		return Color3.fromRGB(28, 24, 34):Lerp(style.primary, 0.3)
	end
	return style.primary:Lerp(Color3.fromRGB(230, 232, 238), style.grade < 55 and 0.45 or 0.1)
end

------------------------------------------------------------------------
-- 칼날 장식 (등급)
------------------------------------------------------------------------
type DecoOpts = { shaft: boolean?, hollow: boolean? }

local function decorateBlade(ctx: Ctx, style: any, look: Look, core: BasePart, segs: { Seg }, tipCf: CFrame, o: DecoOpts)
	local onShaft = o.shaft == true
	local first = segs[1]
	local total = 0
	for _, sg in ipairs(segs) do
		total += sg.len
	end
	-- 가운데 홈과 빛 테두리
	if not onShaft and not o.hollow then
		for _, sg in ipairs(segs) do
			mk(ctx, "Fuller", Vector3.new(sg.thick + 0.03, sg.len * 0.92, math.max(0.08, sg.width * 0.16)), sg.cf, style.grade >= 21 and style.glow or DARK_STEEL, style.grade >= 21 and Enum.Material.Neon or Enum.Material.Metal)
		end
	end
	if style.edge and not onShaft then
		for _, sg in ipairs(segs) do
			for _, side in ipairs({ 1, -1 }) do
				mk(ctx, "Edge", Vector3.new(sg.thick + 0.02, sg.len, 0.07), sg.cf * CFrame.new(0, 0, side * (sg.width / 2 - 0.02)), style.secondary, Enum.Material.Foil)
			end
		end
	end
	-- 룬 문자: 칼날을 따라 빛나는 점
	local runes = math.min(style.runes, math.floor(total / 0.55))
	for i = 1, runes do
		local cf, sg = sample(segs, 0.06 + 0.86 * (i - 0.5) / runes)
		mk(ctx, "Rune", Vector3.new(sg.thick + 0.06, 0.2, 0.2), cf * CFrame.Angles(math.rad(45), 0, 0), (i % 2 == 0) and style.secondary or style.glow, Enum.Material.Neon)
	end
	-- 가시: 칼날 한쪽을 따라 바깥으로
	for i = 1, style.spikes do
		local cf, sg = sample(segs, 0.12 + 0.6 * (i - 1) / math.max(style.spikes, 1))
		local size = 0.18 + 0.03 * style.grade / 10
		mk(ctx, "Spike", Vector3.new(sg.thick * 0.9, size, size), cf * CFrame.new(0, 0, -(sg.width / 2 + size * 0.25)) * CFrame.Angles(math.rad(45), 0, 0), style.primary, Enum.Material.Metal)
	end
	-- 톱날: 양쪽 날을 따라 이빨
	local serr = onShaft and 0 or style.serrate
	for i = 1, serr do
		local cf, sg = sample(segs, 0.05 + 0.65 * (i - 1) / math.max(serr - 1, 1))
		local size = math.max(0.12, sg.width * 0.2)
		for _, side in ipairs({ 1, -1 }) do
			mk(ctx, "Serration", Vector3.new(sg.thick * 0.95, size, size), cf * CFrame.new(0, 0, side * (sg.width / 2)) * CFrame.Angles(math.rad(45), 0, 0), core.Color, core.Material)
		end
	end
	-- 금빛 문양: 칼날 양면에 V자 무늬
	if style.engrave and not onShaft and not o.hollow then
		local n = math.max(2, math.floor(total / 1.4))
		for i = 1, n do
			local cf, sg = sample(segs, 0.08 + 0.8 * (i - 0.5) / n)
			for _, face in ipairs({ 1, -1 }) do
				for _, tilt in ipairs({ 35, -35 }) do
					mk(ctx, "Engrave", Vector3.new(0.03, sg.width * 0.36, 0.06), cf * CFrame.new(face * (sg.thick / 2 + 0.01), 0, tilt > 0 and sg.width * 0.12 or -sg.width * 0.12) * CFrame.Angles(math.rad(tilt), 0, 0), GOLD:Lerp(style.secondary, 0.25), Enum.Material.Foil)
				end
			end
		end
	end
	-- 떠 있는 칼날 조각: 칼끝 너머로 간격을 두고 이어진다
	for i = 1, (onShaft and 0 or style.floatBlade) do
		local w = first.width * (0.7 - i * 0.1)
		mk(ctx, "FloatPiece", Vector3.new(first.thick, 0.5, math.max(0.15, w)), tipCf * CFrame.new(0, 0.55 + (i - 1) * 0.75, 0) * CFrame.Angles(math.rad((i % 2 == 0) and 12 or -12), 0, 0), core.Color, core.Material)
	end
	-- 두 겹 칼날: 칼날을 감싼 반투명 빛
	if style.auraBlade and not look.lite and not onShaft then
		for _, sg in ipairs(segs) do
			local outer = mk(ctx, "AuraBlade", Vector3.new(sg.thick * 2.2, sg.len * 1.04, sg.width * 1.45), sg.cf, style.secondary, Enum.Material.ForceField)
			outer.Transparency = 0.45
		end
	end
	-- 빛 고리: 칼날을 두른 고리들
	for r = 1, style.halo do
		local cf, sg = sample(segs, 0.3 + 0.25 * (r - 1))
		local radius = sg.width * 0.75 + 0.35 + r * 0.1
		for i = 0, 9 do
			local a = (i / 10) * math.pi * 2
			mk(ctx, "Halo", Vector3.new(0.14, 0.14, radius * 0.66), cf * CFrame.new(math.cos(a) * radius, 0, math.sin(a) * radius) * CFrame.Angles(0, -a, 0), (r % 2 == 1) and GOLD:Lerp(style.secondary, 0.4) or style.secondary, Enum.Material.Foil)
		end
	end
	-- 궤적
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailBase"
	a0.Position = Vector3.new(0, -core.Size.Y / 2 + 0.1, 0)
	a0.Parent = core
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailTip"
	a1.Position = Vector3.new(0, core.Size.Y / 2, 0)
	a1.Parent = core
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = style.trailLife * (1 + (look.enh or 0) * 0.05)
	trail.MinLength = 0.05
	trail.LightEmission = 0.45
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	trail.Color = style.rainbow and GradeStyle.RAINBOW or ColorSequence.new(style.glow, look.accent)
	trail.Parent = core

	-- 빛과 입자
	if style.grade >= 4 then
		local light = Instance.new("PointLight")
		light.Color = style.glow
		light.Range = style.lightRange
		light.Brightness = style.lightBrightness
		light.Parent = core
	end
	emitter(core, style, look.lite and style.particleRate * 0.4 or style.particleRate, style.particleSize)
	if style.fire and not look.lite then
		local fire = Instance.new("Fire")
		fire.Size = 2 + style.grade * 0.04
		fire.Heat = 6
		fire.Color = style.primary
		fire.SecondaryColor = style.secondary
		fire.Parent = core
	end
	if style.smoke and not look.lite then
		local smoke = Instance.new("Smoke")
		smoke.Color = style.primary
		smoke.Opacity = 0.12
		smoke.RiseVelocity = 2
		smoke.Size = 1.5
		smoke.Parent = core
	end
	if style.sparkles or look.rarity >= 5 then
		local sp = Instance.new("Sparkles")
		sp.SparkleColor = look.rarity >= 5 and GOLD or style.glow
		sp.Parent = core
	end

	-- 떠다니는 구슬, 빛줄기, 파편 (클라이언트가 돌린다)
	if look.lite then
		return
	end
	local tip = Instance.new("Attachment")
	tip.Name = "BeamTip"
	tip.Position = Vector3.new(0, core.Size.Y / 2, 0)
	tip.Parent = core
	local bw = first.width
	for i = 1, style.orbs do
		local orb = orbitPart(ctx.parent, core, Vector3.new(0.45, 0.45, 0.45) * ctx.scale * (1 + style.power * 0.6), (i % 2 == 0) and style.secondary or style.glow, Enum.Material.Glass, Enum.PartType.Ball, {
			name = "Orb",
			radius = (bw * 0.8 + 0.7) * ctx.scale,
			height = (-core.Size.Y / 2) + core.Size.Y * (i / (style.orbs + 1)),
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
		orbitPart(ctx.parent, core, Vector3.new(0.12, 0.45, 0.22) * ctx.scale, (i % 3 == 0) and style.secondary or style.glow, Enum.Material.Glass, nil, {
			name = "Shard",
			radius = (bw * 1.2 + 1.3) * ctx.scale,
			height = (-core.Size.Y / 2) + core.Size.Y * ((i % 6) + 1) / 7,
			speed = -3.2,
			phase = i * 0.9,
			useRotation = true,
			tumble = 4,
		})
	end
end

------------------------------------------------------------------------
-- 강화 장식: +1부터 +10까지 단계마다 하나씩 쌓인다
------------------------------------------------------------------------
local function enhanceDecor(ctx: Ctx, style: any, look: Look, core: BasePart, segs: { Seg }, tipCf: CFrame, guardY: number, guardW: number)
	local lv = math.clamp(math.floor(look.enh or 0), 0, 10)
	if lv <= 0 then
		return
	end
	local accent = look.accent
	local bright = accent:Lerp(Color3.new(1, 1, 1), 0.35)
	-- +1 빛나는 날끝
	for _, sg in ipairs(segs) do
		for _, side in ipairs({ 1, -1 }) do
			mk(ctx, "EnhEdge", Vector3.new(sg.thick * 0.6, sg.len, 0.05), sg.cf * CFrame.new(0, 0, side * (sg.width / 2 + 0.03)), bright, Enum.Material.Neon)
		end
	end
	local base = segs[1]
	-- +2 칼날 문장 보석
	if lv >= 2 then
		local cf = base.cf * CFrame.new(0, -base.len / 2 + 0.35, 0)
		mk(ctx, "EnhCrestFrame", Vector3.new(base.thick + 0.1, 0.62, 0.62), cf * CFrame.Angles(math.rad(45), 0, 0), GOLD, Enum.Material.Foil)
		mk(ctx, "EnhCrest", Vector3.new(base.thick + 0.16, 0.4, 0.4), cf * CFrame.Angles(math.rad(45), 0, 0), accent, Enum.Material.Neon)
	end
	-- +3 두 줄 룬 홈
	if lv >= 3 then
		for i, sg in ipairs(segs) do
			local z = (i % 2 == 0) and 0.22 or -0.22
			for _, face in ipairs({ 1, -1 }) do
				mk(ctx, "EnhGroove", Vector3.new(0.02, sg.len * 0.9, 0.05), sg.cf * CFrame.new(face * (sg.thick / 2 + 0.012), 0, z * sg.width), style.glow, Enum.Material.Neon)
			end
		end
	end
	-- +4 가드 지느러미
	if lv >= 4 then
		for _, side in ipairs({ 1, -1 }) do
			for f = 0, 1 do
				mk(ctx, "EnhFin", Vector3.new(0.1, 0.9 - f * 0.25, 0.32), at(guardY + 0.35 + f * 0.25, side * (guardW / 2 + 0.15 + f * 0.2), side * (28 + f * 18)), core.Color, core.Material)
			end
		end
	end
	-- +5 양면 빛 각인 (화살촉 무늬)
	if lv >= 5 then
		local n = #segs
		for i = 1, n, 2 do
			local sg = segs[i]
			for _, face in ipairs({ 1, -1 }) do
				for _, tilt in ipairs({ 40, -40 }) do
					mk(ctx, "EnhMark", Vector3.new(0.025, sg.width * 0.32, 0.05), sg.cf * CFrame.new(face * (sg.thick / 2 + 0.015), 0, tilt > 0 and -sg.width * 0.1 or sg.width * 0.1) * CFrame.Angles(math.rad(tilt), 0, 0), style.secondary, Enum.Material.Neon)
				end
			end
		end
	end
	-- +6 등날: 칼날 가운데 솟은 능선
	if lv >= 6 then
		for _, sg in ipairs(segs) do
			mk(ctx, "EnhRidge", Vector3.new(sg.thick * 1.7, sg.len * 0.96, math.max(0.08, sg.width * 0.1)), sg.cf, GOLD:Lerp(style.primary, 0.35), Enum.Material.Foil)
		end
	end
	-- +7 칼끝 회전 고리 (구슬 여섯 개)
	if lv >= 7 and not look.lite then
		local tipHeight = core.Size.Y / 2 - 0.3 * ctx.scale
		for i = 1, 6 do
			orbitPart(ctx.parent, core, Vector3.new(0.22, 0.22, 0.22) * ctx.scale, (i % 2 == 0) and accent or style.glow, Enum.Material.Neon, Enum.PartType.Ball, {
				name = "EnhRing",
				radius = (base.width * 0.6 + 0.45) * ctx.scale,
				height = tipHeight,
				speed = 4,
				phase = i * math.pi / 3,
				useRotation = true,
			})
		end
	end
	-- +8 불꽃 등가시: 칼등을 따라 칼끝 쪽으로 누운 가시
	if lv >= 8 then
		for i = 1, #segs do
			local sg = segs[i]
			mk(ctx, "EnhFlame", Vector3.new(sg.thick * 0.8, 0.55, 0.22), sg.cf * CFrame.new(0, 0, -(sg.width / 2 + 0.18)) * CFrame.Angles(math.rad(-40), 0, 0), (i % 2 == 0) and style.secondary or accent, Enum.Material.Neon)
		end
	end
	-- +9 빛의 칼집
	if lv >= 9 then
		for _, sg in ipairs(segs) do
			local sheath = mk(ctx, "EnhSheath", Vector3.new(sg.thick * 2.6, sg.len * 1.02, sg.width * 1.65), sg.cf, accent, Enum.Material.ForceField)
			sheath.Transparency = 0.35
		end
		local pe = emitter(core, style, 14, 0.35, { name = "EnhStars", speed = NumberRange.new(1, 3) })
		pe.Color = ColorSequence.new(bright, Color3.new(1, 1, 1))
		pe.LightEmission = 0.8
	end
	-- +10 황금 왕관과 번개
	if lv >= 10 then
		for i = 0, 5 do
			local a = (i / 6) * math.pi * 2
			mk(ctx, "EnhCrown", Vector3.new(0.12, 0.8, 0.2), CFrame.new(math.cos(a) * 0.55, guardY + 0.45, math.sin(a) * 0.55) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(25)), GOLD, Enum.Material.Foil)
		end
		if not look.lite then
			local g0 = Instance.new("Attachment")
			g0.Name = "EnhBolt0"
			g0.Position = Vector3.new(0, -core.Size.Y / 2 + 0.2, 0)
			g0.Parent = core
			local g1 = Instance.new("Attachment")
			g1.Name = "EnhBolt1"
			g1.Position = Vector3.new(0, core.Size.Y / 2, 0)
			g1.Parent = core
			for k = 1, 2 do
				local beam = Instance.new("Beam")
				beam.Attachment0 = g0
				beam.Attachment1 = g1
				beam.Width0 = 0.14
				beam.Width1 = 0.06
				beam.Segments = 12
				beam.CurveSize0 = k == 1 and 1.4 or -1.4
				beam.CurveSize1 = k == 1 and -1.1 or 1.1
				beam.FaceCamera = true
				beam.LightEmission = 1
				beam.Color = style.rainbow and GradeStyle.RAINBOW or ColorSequence.new(Color3.new(1, 1, 1), accent)
				beam.Transparency = NumberSequence.new(0.2)
				beam.Parent = core
			end
		end
		local sp = Instance.new("Sparkles")
		sp.SparkleColor = GOLD
		sp.Parent = core
	end
end

------------------------------------------------------------------------
-- 칼날 모양 12종
------------------------------------------------------------------------
-- 모양마다 폭 배율 wm(t), 가운데 선 위치 cz(t) (칼날 폭 단위)
local PROFILES: { [string]: (number) -> (number, number) } = {
	straight = function(_t)
		return 1, 0
	end,
	leaf = function(t)
		return 0.7 + 0.65 * math.sin(math.pi * t), 0
	end,
	cleaver = function(t)
		local w = 1 + 0.9 * t
		return w, (1 - w) / 2
	end,
	curved = function(t)
		return 1 - 0.15 * t, 0.9 * t * t
	end,
	flamberge = function(t)
		return 0.8 + 0.35 * math.abs(math.sin(t * math.pi * 5)), 0.08 * math.sin(t * math.pi * 5)
	end,
	falchion = function(t)
		local w = 0.85 + 0.8 * t ^ 1.5
		return w, (w - 0.85) / 2 + 0.25 * t * t
	end,
	hollow = function(_t)
		return 1, 0
	end,
	twin = function(_t)
		return 1, 0
	end,
	hook = function(_t)
		return 0.9, 0
	end,
	crescent = function(_t)
		return 0.7, 0
	end,
	spine = function(t)
		return 1 - 0.1 * t, 0
	end,
	crystal = function(t)
		return 0.55 + 0.6 * math.abs(math.sin(t * math.pi * 4)), 0
	end,
}

-- 가운데 선을 따라 조각을 만든다. 실제로 그리지 않고 좌표만 필요하면 draw = false
local function lineSegs(ctx: Ctx, prof: (number) -> (number, number), startY: number, L: number, W: number, T: number, n: number, zShift: number, wScale: number, draw: boolean, color: Color3, material: Enum.Material, reflect: number, name: string): { Seg }
	local segs: { Seg } = {}
	for i = 0, n - 1 do
		local t0, t1 = i / n, (i + 1) / n
		local _, c0 = prof(t0)
		local _, c1 = prof(t1)
		local wm = prof((t0 + t1) / 2)
		local y0, y1 = startY + t0 * L, startY + t1 * L
		local z0, z1 = c0 * W + zShift, c1 * W + zShift
		local dy, dz = y1 - y0, z1 - z0
		local len = math.sqrt(dy * dy + dz * dz) + 0.04
		local cf = CFrame.new(0, (y0 + y1) / 2, (z0 + z1) / 2) * CFrame.Angles(math.atan2(dz, dy), 0, 0)
		local width = wm * W * wScale
		if draw then
			local p = mk(ctx, name, Vector3.new(T, len, width), cf, color, material)
			p.Reflectance = reflect
		end
		table.insert(segs, { cf = cf, len = len, width = width, thick = T })
	end
	return segs
end

-- 모양에 맞춰 칼날을 그리고 (장식용 조각들, 칼끝 좌표)를 돌려준다
local function profileBlade(ctx: Ctx, style: any, startY: number, L: number, W: number, T: number, color: Color3): ({ Seg }, CFrame, boolean)
	local shape = style.shape or "straight"
	local prof = PROFILES[shape] or PROFILES.straight
	local material = style.bladeMaterial
	local reflect = style.reflect
	local n = (shape == "flamberge" or shape == "crystal") and 12 or 8
	local hollow = false
	local segs: { Seg }
	if shape == "hollow" then
		-- 빈 틀: 양쪽 테두리 + 가로대, 가운데에 빛나는 심
		hollow = true
		segs = lineSegs(ctx, prof, startY, L, W, T, n, 0, 1, false, color, material, reflect, "Blade")
		for _, side in ipairs({ 1, -1 }) do
			lineSegs(ctx, prof, startY, L, W, T, n, side * W * 0.39, 0.22, true, color, material, reflect, "BladeRail")
		end
		for i = 2, n, 2 do
			mk(ctx, "BladeBar", Vector3.new(T * 0.9, 0.14, W * 0.8), segs[i].cf, color, material)
		end
		local coreGlow = mk(ctx, "BladeCore", Vector3.new(T * 0.4, L * 0.9, W * 0.45), CFrame.new(0, startY + L * 0.47, 0), style.glow, Enum.Material.Glass)
		coreGlow.Transparency = 0.35
	elseif shape == "twin" then
		-- 쌍날: 사이가 벌어진 두 갈래 칼날
		hollow = true
		segs = lineSegs(ctx, prof, startY, L, W, T, n, 0, 1, false, color, material, reflect, "Blade")
		for _, side in ipairs({ 1, -1 }) do
			lineSegs(ctx, prof, startY, L, W, T, n, side * W * 0.32, 0.36, true, color, material, reflect, "BladeTwin")
		end
		mk(ctx, "BladeBridge", Vector3.new(T, 0.3, W), CFrame.new(0, startY + 0.15, 0), color, material)
	else
		segs = lineSegs(ctx, prof, startY, L, W, T, n, 0, 1, true, color, material, reflect, "Blade")
	end

	-- 칼끝
	local last = segs[#segs]
	local tipCf = last.cf * CFrame.new(0, last.len / 2, 0)
	local wEnd = last.width
	local function tipPart(name: string, size: Vector3, cf: CFrame)
		local p = mk(ctx, name, size, cf, color, material)
		p.Reflectance = reflect
		return p
	end
	if shape == "cleaver" then
		tipPart("BladeTip", Vector3.new(T, 0.35, wEnd), tipCf * CFrame.Angles(math.rad(-18), 0, 0))
	elseif shape == "hook" then
		local h1 = tipCf * CFrame.new(0, 0.2, 0) * CFrame.Angles(math.rad(-55), 0, 0) * CFrame.new(0, 0.35, 0)
		tipPart("BladeTip", Vector3.new(T, 0.9, wEnd * 0.75), h1)
		tipPart("BladeHook", Vector3.new(T, 0.8, wEnd * 0.55), h1 * CFrame.new(0, 0.4, 0) * CFrame.Angles(math.rad(-80), 0, 0) * CFrame.new(0, 0.35, 0))
	elseif shape == "crescent" then
		local r = W * 1.25
		local center = tipCf * CFrame.new(0, r * 0.85, 0)
		local segsN = 9
		for i = 0, segsN - 1 do
			local f0 = math.rad(-125 + 250 * i / segsN)
			local f1 = math.rad(-125 + 250 * (i + 1) / segsN)
			local p0 = Vector3.new(0, -r * math.cos(f0), r * math.sin(f0))
			local p1 = Vector3.new(0, -r * math.cos(f1), r * math.sin(f1))
			local mid = (p0 + p1) / 2
			local d = p1 - p0
			local taper = 1 - math.abs((i + 0.5) / segsN * 2 - 1) * 0.7
			tipPart("BladeMoon", Vector3.new(T, d.Magnitude + 0.05, W * 0.55 * taper), center * CFrame.new(mid) * CFrame.Angles(math.atan2(d.Z, d.Y), 0, 0) * CFrame.new(0, 0, -W * 0.18 * taper))
		end
		tipCf = center * CFrame.new(0, r * 0.4, 0)
	elseif shape == "twin" then
		for _, side in ipairs({ 1, -1 }) do
			local ts = W * 0.36 * 0.71
			tipPart("BladeTip", Vector3.new(T, ts, ts), tipCf * CFrame.new(0, 0, side * W * 0.32) * CFrame.Angles(math.rad(45), 0, 0))
		end
	elseif shape == "crystal" then
		local ts = W * 0.75
		tipPart("BladeTip", Vector3.new(T * 1.3, ts * 1.6, ts), tipCf * CFrame.new(0, ts * 0.4, 0) * CFrame.Angles(math.rad(45), 0, 0) * CFrame.new(0, 0, 0))
		-- 옆으로 돋은 결정
		for i = 1, 4 do
			local cf = sample(segs, i / 5)
			local side = (i % 2 == 0) and 1 or -1
			tipPart("Crystal", Vector3.new(T * 1.2, 0.7, 0.28), cf * CFrame.new(0, 0, side * W * 0.45) * CFrame.Angles(math.rad(side * 40), 0, 0))
		end
	elseif style.prongs and (shape == "straight" or shape == "leaf" or shape == "spine" or shape == "flamberge" or shape == "hollow") then
		-- 갈라진 칼끝: 두 갈래로 벌어진다
		local tipSize = wEnd * 0.5
		for _, side in ipairs({ 1, -1 }) do
			tipPart("BladeTip", Vector3.new(T, tipSize * 1.6, tipSize * 0.7), tipCf * CFrame.new(0, tipSize * 0.5, side * wEnd * 0.24) * CFrame.Angles(math.rad(side * -14), 0, 0))
		end
	else
		local tipSize = wEnd * 0.71
		tipPart("BladeTip", Vector3.new(T, tipSize, tipSize), tipCf * CFrame.Angles(math.rad(45), 0, 0))
	end

	-- 용골: 칼등을 따라 척추뼈 같은 판
	if shape == "spine" then
		for i = 1, #segs do
			local sg = segs[i]
			mk(ctx, "Vertebra", Vector3.new(T * 1.6, sg.len * 0.55, 0.35), sg.cf * CFrame.new(0, 0, -(sg.width / 2 + 0.12)) * CFrame.Angles(math.rad(-25), 0, 0), color:Lerp(Color3.fromRGB(240, 230, 210), 0.4), Enum.Material.Marble)
		end
	end
	return segs, tipCf, hollow
end

------------------------------------------------------------------------
-- 가드: 보석, 날개, 검 왕관
------------------------------------------------------------------------
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

	local bladeColor = bladeColorOf(style)
	local startY = guardY + 0.16
	local segs, tipCf, hollow = profileBlade(ctx, style, startY, bladeL, bladeW, d.bladeT, bladeColor)
	-- 궤적과 입자가 붙는 보이지 않는 심 (칼날 전체 길이)
	local core = mk(ctx, "BladeCoreLine", Vector3.new(0.05, bladeL, 0.05), at(startY + bladeL / 2), bladeColor, style.bladeMaterial)
	core.Transparency = 1
	if typeId == 0 then
		mk(ctx, "Core", Vector3.new(d.bladeT + 0.05, bladeL * 0.85, 0.3), at(startY + bladeL * 0.45), Color3.fromRGB(255, 150, 210), Enum.Material.Neon)
	end
	decorateBlade(ctx, style, look, core, segs, tipCf, { hollow = hollow })
	enhanceDecor(ctx, style, look, core, segs, tipCf, guardY, d.guardW)
	return core
end

-- 낫: 모양에 따라 날이 두 개, 세 개가 되거나 초승달처럼 크게 휜다
local function scytheBlade(ctx: Ctx, style: any, oy: number, radius: number, sweep: number, side: number, widthMul: number, bc: Color3, jagged: boolean, name: string): { Seg }
	local segs: { Seg } = {}
	local n = 6
	for i = 0, n - 1 do
		local a0 = math.rad(sweep * i / n)
		local a1 = math.rad(sweep * (i + 1) / n)
		local y0, z0 = oy - radius + radius * math.cos(a0), -side * radius * math.sin(a0)
		local y1, z1 = oy - radius + radius * math.cos(a1), -side * radius * math.sin(a1)
		local dy, dz = y1 - y0, z1 - z0
		local len = math.sqrt(dy * dy + dz * dz) + 0.08
		local width = (0.75 - 0.5 * (i / (n - 1))) * style.widthMul * widthMul
		local cf = CFrame.new(0, (y0 + y1) / 2, (z0 + z1) / 2) * CFrame.Angles(math.atan2(dz, dy), 0, 0) * CFrame.new(0, 0, side * (width / 2 - 0.1))
		local seg = mk(ctx, name .. i, Vector3.new(0.14, len, width), cf, bc, style.bladeMaterial)
		seg.Reflectance = style.reflect
		if style.edge then
			mk(ctx, "Edge" .. i, Vector3.new(0.16, len, 0.08), cf * CFrame.new(0, 0, side * width / 2), style.secondary, Enum.Material.Neon)
		end
		if jagged then
			mk(ctx, "Tooth" .. i, Vector3.new(0.12, 0.3, 0.3), cf * CFrame.new(0, 0, -side * width / 2) * CFrame.Angles(math.rad(45), 0, 0), bc, style.bladeMaterial)
		end
		if i % 2 == 0 and style.runes > i then
			mk(ctx, "Rune" .. i, Vector3.new(0.2, 0.18, 0.18), cf * CFrame.Angles(math.rad(45), 0, 0), style.glow, Enum.Material.Neon)
		end
		table.insert(segs, { cf = cf, len = len, width = width, thick = 0.14 })
	end
	return segs
end

local function scythe(ctx: Ctx, style: any, look: Look): BasePart
	local bc = bladeColorOf(style)
	local ringColor = look.rarity >= 5 and GOLD or style.primary:Lerp(DARK_STEEL, 0.5)
	local shaftLen = 6.4 * (1 + style.power * 0.2)
	local shaft = mk(ctx, "Shaft", Vector3.new(0.3, shaftLen, 0.3), at(shaftLen / 2 - 0.6), style.grade >= 50 and style.primary:Lerp(Color3.new(0, 0, 0), 0.55) or WOOD, Enum.Material.Wood)
	local bands = 3 + math.min(4, style.grade // 15)
	for i = 1, bands do
		mk(ctx, "Band", Vector3.new(0.4, 0.2, 0.4), at(-0.4 + (shaftLen - 0.4) * i / (bands + 1)), ringColor, Enum.Material.Metal)
	end
	local oy = shaftLen - 0.8
	decorateGuard(ctx, style, look, oy, 0.8)
	local shape = style.shape or "straight"
	local moon = shape == "crescent" or shape == "curved" or shape == "hook" or shape == "falchion"
	local jagged = shape == "flamberge" or shape == "spine" or shape == "cleaver" or shape == "crystal"
	-- 날: 자루 끝에서 원을 따라 아래로, 뒤로 휜다
	local radius = 2.6 * style.lengthMul * (moon and 1.1 or 1)
	local segs = scytheBlade(ctx, style, oy, radius, moon and 160 or 115, 1, 1, bc, jagged, "Blade")
	-- 30등급부터 반대쪽에 작은 날, 70등급부터 자루 아래쪽에 세 번째 날
	if style.grade >= 30 then
		scytheBlade(ctx, style, oy, radius * 0.6, 100, -1, 0.7, bc, jagged, "BackBlade")
	end
	if style.grade >= 70 then
		scytheBlade(ctx, style, oy - 2.2, radius * 0.45, 90, 1, 0.6, bc, false, "LowBlade")
	end
	mk(ctx, "TopSpike", Vector3.new(0.14, 0.5, 0.5) * (1 + style.power), at(oy + 0.35, 0, 45), bc, style.bladeMaterial)
	-- 장식은 자루 기준으로 붙인다 (구슬은 자루 위쪽을 돈다)
	local shaftSegs: { Seg } = { { cf = at(shaftLen / 2 - 0.6), len = shaftLen, width = 0.5, thick = 0.3 } }
	decorateBlade(ctx, style, look, shaft, shaftSegs, at(shaftLen - 0.6), { shaft = true })
	enhanceDecor(ctx, style, look, shaft, segs, segs[#segs].cf, oy, 0.8)
	return shaft
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
