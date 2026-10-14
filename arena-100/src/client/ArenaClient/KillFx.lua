-- KillFx (ModuleScript, ArenaClient 아래)
-- 상점에서 산 킬 이펙트 30종, 아우라 파동, 사제 치유 연출.
-- 킬 이펙트는 적이 쓰러진 자리에서 터지고, 터진 범위(폭발 반경)가 바닥 고리로 보인다.
-- 단계가 높을수록 크고, 겹이 많고, 오래 남는다.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local GradeStyle = require(ReplicatedStorage:WaitForChild("GradeStyle"))

local KillFx = {}

local Effects: any = nil
local P: any = nil

function KillFx.init(effects: any)
	Effects = effects
	P = effects.prim
end

local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 205, 90)

-- 단계에 맞는 등급 디자인 (속성이 같고, 높은 단계일수록 화려한 등급)
function KillFx.styleFor(tier: number)
	if tier >= #Config.KillFx then
		return GradeStyle.get(100)
	end
	local f = Config.KillFx[tier]
	return GradeStyle.get(f.motif + ((tier - 1) // 10) * 30)
end

------------------------------------------------------------------------
-- 조립 도구
------------------------------------------------------------------------
local function tween(p: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	TweenService:Create(p, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal):Play()
end

local function ground(pos: Vector3): Vector3
	return P.floorOf(pos) + Vector3.new(0, 0.2, 0)
end

-- 세로 빛기둥
local function pillar(pos: Vector3, color: Color3, height: number, width: number, life: number)
	local base = ground(pos)
	local beam = P.fxPart(Vector3.new(height, width, width), CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), color, 0.1, Enum.PartType.Cylinder)
	P.fade(beam, life, { Size = Vector3.new(height, 0.1, 0.1) })
end

-- 바닥에서 원으로 솟는 가시
local function spikeRing(pos: Vector3, n: number, radius: number, color: Color3, height: number, material: Enum.Material, life: number)
	local base = ground(pos)
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local spot = base + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
		local spike = P.fxPart(Vector3.new(0.6, 0.1, 0.6), CFrame.new(spot) * CFrame.Angles(math.rad(math.random(-15, 15)), a, math.rad(math.random(-15, 15))), color, 0.05)
		spike.Material = material
		tween(spike, 0.12, { Size = Vector3.new(0.6, height, 0.6), CFrame = spike.CFrame * CFrame.new(0, height / 2, 0) }, Enum.EasingStyle.Back)
		task.delay(0.12 + life * 0.5, function()
			P.fade(spike, life * 0.5, { Size = Vector3.new(0.1, height * 0.3, 0.1) })
		end)
	end
end

-- 속이 차오르거나 꺼지는 구
local function sphere(pos: Vector3, color: Color3, from: number, to: number, life: number, material: Enum.Material?)
	local ball = P.fxPart(Vector3.new(from, from, from), CFrame.new(pos), color, 0.15, Enum.PartType.Ball)
	if material then
		ball.Material = material
	end
	P.fade(ball, life, { Size = Vector3.new(to, to, to) })
	return ball
end

local function floorRing(pos: Vector3, color: Color3, from: number, to: number, life: number, thick: number?)
	P.ring(ground(pos), color, from, to, life, thick)
end

-- 하늘에서 떨어지는 물체 (유성, 검)
local function fall(pos: Vector3, size: Vector3, color: Color3, height: number, time: number, material: Enum.Material?, onLand: (() -> ())?)
	local target = ground(pos)
	local start = target + Vector3.new(math.random(-6, 6), height, math.random(-6, 6))
	local obj = P.fxPart(size, CFrame.lookAt(start, target), color, 0, nil)
	if material then
		obj.Material = material
	end
	P.addTrail(obj, color, math.max(size.X, 0.6), 0.3)
	P.animate(time, function(t)
		local p = start:Lerp(target, t * t)
		obj.CFrame = CFrame.lookAt(p, target + (target - start).Unit)
	end, function()
		P.fade(obj, 0.15)
		if onLand then
			onLand()
		end
	end)
end

-- 얇은 판으로 그리는 X자 베기
local function xSlash(pos: Vector3, color: Color3, size: number, life: number)
	local cam = workspace.CurrentCamera
	local face = cam and (cam.CFrame.Position - pos).Unit or Vector3.new(0, 0, 1)
	local cf = CFrame.lookAt(pos, pos + face)
	for _, tilt in ipairs({ 45, -45 }) do
		local slash = P.fxPart(Vector3.new(0.5, size * 0.1, 0.05), cf * CFrame.Angles(0, 0, math.rad(tilt)), color, 0)
		tween(slash, 0.08, { Size = Vector3.new(0.5, size, 0.05) })
		task.delay(0.1, function()
			P.fade(slash, life, { Size = Vector3.new(0.02, size * 1.2, 0.02) })
		end)
	end
end

-- 날개: 깃털이 부채처럼 펼쳐졌다 사라진다
local function wingFan(pos: Vector3, color: Color3, size: number, life: number)
	local cam = workspace.CurrentCamera
	local face = cam and Vector3.new(cam.CFrame.Position.X - pos.X, 0, cam.CFrame.Position.Z - pos.Z).Unit or Vector3.new(0, 0, 1)
	local cf = CFrame.lookAt(pos, pos + face)
	for _, side in ipairs({ 1, -1 }) do
		for f = 0, 5 do
			local len = (3.2 - f * 0.35) * size
			local feather = P.fxPart(Vector3.new(0.12, 0.2, 0.7 * size), cf * CFrame.Angles(0, 0, math.rad(side * (-75 + f * 22))), (f % 2 == 0) and color or WHITE, 0.1)
			feather.Material = Enum.Material.Glass
			tween(feather, 0.25, { Size = Vector3.new(0.12, len, 0.7 * size), CFrame = cf * CFrame.Angles(0, 0, math.rad(side * (-75 + f * 22))) * CFrame.new(0, len / 2, 0) }, Enum.EasingStyle.Back)
			task.delay(0.25 + life * 0.4, function()
				P.fade(feather, life * 0.6)
			end)
		end
	end
end

-- 나선 회오리: 고리들이 돌며 올라간다
local function tornado(pos: Vector3, color: Color3, color2: Color3, height: number, life: number)
	local base = ground(pos)
	local n = 7
	for i = 1, n do
		local d = 1.5 + i * 0.7
		local ringPart = P.fxPart(Vector3.new(0.25, d, d), CFrame.new(base) * CFrame.Angles(0, 0, math.rad(90)), (i % 2 == 0) and color or color2, 0.25, Enum.PartType.Cylinder)
		local y = height * i / n
		P.animate(life, function(t)
			ringPart.CFrame = CFrame.new(base + Vector3.new(math.cos(t * 12 + i) * 0.6, y * math.min(1, t * 2), math.sin(t * 12 + i) * 0.6)) * CFrame.Angles(0, t * 10, math.rad(90))
			ringPart.Transparency = 0.25 + 0.75 * t
		end, function()
			ringPart:Destroy()
		end)
	end
end

-- 빨려 드는 조각들
local function implode(pos: Vector3, color: Color3, n: number, radius: number, life: number)
	for _ = 1, n do
		local a = math.random() * math.pi * 2
		local start = pos + Vector3.new(math.cos(a) * radius, (math.random() - 0.3) * radius * 0.6, math.sin(a) * radius)
		local bit = P.fxPart(Vector3.new(0.3, 0.3, 0.9), CFrame.lookAt(start, pos), color, 0.1)
		tween(bit, life, { CFrame = CFrame.lookAt(pos, pos + (pos - start).Unit), Size = Vector3.new(0.05, 0.05, 0.2), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Debris:AddItem(bit, life + 0.05)
	end
end

-- 해골: 공 머리 + 검은 눈구멍
local function skull(pos: Vector3, color: Color3, size: number, life: number)
	local head = P.fxPart(Vector3.new(1.4, 1.4, 1.4) * size, CFrame.new(pos), color, 0.2, Enum.PartType.Ball)
	head.Material = Enum.Material.Glass
	local cam = workspace.CurrentCamera
	local face = cam and (cam.CFrame.Position - pos).Unit or Vector3.new(0, 0, 1)
	local eyes = {}
	for _, x in ipairs({ -0.3, 0.3 }) do
		local eye = P.fxPart(Vector3.new(0.35, 0.4, 0.2) * size, CFrame.lookAt(pos, pos + face) * CFrame.new(x * size, 0.1 * size, -0.62 * size), Color3.fromRGB(10, 0, 20), 0)
		eye.Material = Enum.Material.SmoothPlastic
		table.insert(eyes, eye)
	end
	local rise = Vector3.new(0, 6 * size, 0)
	P.animate(life, function(t)
		local off = rise * t + Vector3.new(math.sin(t * 20) * 0.3, 0, 0)
		head.CFrame = CFrame.new(pos + off)
		head.Transparency = 0.2 + 0.8 * t
		for i, eye in ipairs(eyes) do
			eye.CFrame = CFrame.lookAt(pos + off, pos + off + face) * CFrame.new((i == 1 and -0.3 or 0.3) * size, 0.1 * size, -0.62 * size)
			eye.Transparency = t
		end
	end, function()
		head:Destroy()
		for _, eye in ipairs(eyes) do
			eye:Destroy()
		end
	end)
end

-- 빛줄기가 사방으로 뻗는다
local function rays(pos: Vector3, colors: { Color3 }, n: number, length: number, life: number)
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local dir = Vector3.new(math.cos(a), (math.random() - 0.3) * 0.6, math.sin(a)).Unit
		local beam = P.fxPart(Vector3.new(0.35, 0.35, length), CFrame.lookAt(pos, pos + dir) * CFrame.new(0, 0, -length / 2), colors[((i - 1) % #colors) + 1], 0.05)
		P.fade(beam, life, { Size = Vector3.new(0.05, 0.05, length * 1.4) })
	end
end

local function sound(power: number)
	Effects.sound("lunge", 0.35 + power * 0.4, 0.9 - power * 0.4)
end

------------------------------------------------------------------------
-- 30종: fx(위치, 스타일, 단계 비율 p, 반경, 데이터)
------------------------------------------------------------------------
type FxFn = (Vector3, any, number, number, any) -> ()
local FX: { [number]: FxFn } = {}

FX[1] = function(pos, st, p, _r) -- 불꽃 터짐
	Effects.burst(pos, st.primary, 30, 26, 1.2, st.motif.tex)
	sphere(pos, Color3.fromRGB(255, 160, 60), 1, 7, 0.3)
end
FX[2] = function(pos, st, p) -- 얼음 파편
	P.flyingBits(pos, st.glow, 16, Vector3.new(0.3, 1.1, 0.3), Enum.Material.Glass, 16, 0.5, true)
	floorRing(pos, Color3.fromRGB(220, 245, 255), 1, 9, 0.4, 0.2)
end
FX[3] = function(pos, st, p) -- 낙뢰
	for _ = 1, 3 do
		P.lightningBolt(pos + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2)), st.primary, 30, 0.5)
	end
	floorRing(pos, st.primary, 1, 8, 0.3, 0.3)
	Effects.shake(0.4, 0.15)
end
FX[4] = function(pos, st, p) -- 꽃잎 흩날림
	P.flyingBits(pos, Color3.fromRGB(255, 160, 200), 20, Vector3.new(0.5, 0.05, 0.35), Enum.Material.Neon, 9, 1.1, true)
	P.flyingBits(pos, st.primary, 12, Vector3.new(0.5, 0.05, 0.35), Enum.Material.Neon, 7, 1, true)
end
FX[5] = function(pos, st, p) -- 그림자 흡수
	implode(pos, st.primary, 18, 7, 0.4)
	sphere(pos, Color3.fromRGB(20, 5, 30), 5, 0.2, 0.45, Enum.Material.ForceField)
end
FX[6] = function(pos, st, p) -- 빛의 기둥
	pillar(pos, WHITE, 40, 5, 0.6)
	pillar(pos, st.glow, 40, 8, 0.4)
	floorRing(pos, st.glow, 2, 12, 0.5, 0.3)
end
FX[7] = function(pos, st, p) -- 핏빛 초승달
	xSlash(pos, Color3.fromRGB(220, 20, 50), 9, 0.35)
	P.flyingBits(pos, Color3.fromRGB(200, 10, 30), 14, Vector3.new(0.3, 0.3, 0.3), Enum.Material.Neon, 10, 0.6, true)
end
FX[8] = function(pos, st, p) -- 공허 붕괴
	local ball = sphere(pos, st.secondary, 6, 0.3, 0.4, Enum.Material.ForceField)
	ball.Color = st.secondary
	implode(pos, st.glow, 14, 6, 0.35)
	task.delay(0.4, function()
		sphere(pos, st.secondary, 0.5, 8, 0.25)
	end)
end
FX[9] = function(pos, st, p) -- 별 폭죽
	for i = 0, 2 do
		task.delay(i * 0.1, function()
			local spot = pos + Vector3.new(math.random(-3, 3), 2 + i * 1.5, math.random(-3, 3))
			Effects.burst(spot, P.RAINBOW[math.random(1, #P.RAINBOW)], 30, 30, 0.6)
			Effects.flash(spot, WHITE, 3, 0.15)
		end)
	end
end
FX[10] = function(pos, st, p) -- 수정 감옥
	local n = 8
	local base = ground(pos)
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local c = P.fxPart(Vector3.new(0.8, 5, 0.8), CFrame.new(base + Vector3.new(math.cos(a) * 1.8, 2.5, math.sin(a) * 1.8)) * CFrame.Angles(math.rad(math.cos(a) * -18), 0, math.rad(math.sin(a) * 18)), (i % 2 == 0) and st.glow or st.secondary, 0.2)
		c.Material = Enum.Material.Glass
		task.delay(0.35, function()
			P.fade(c, 0.3, { Size = Vector3.new(0.1, 1, 0.1) })
		end)
	end
	task.delay(0.35, function()
		P.flyingBits(pos, st.glow, 18, Vector3.new(0.35, 0.8, 0.35), Enum.Material.Glass, 18, 0.5, true)
	end)
end
FX[11] = function(pos, st, p) -- 화산 분출
	floorRing(pos, Color3.fromRGB(255, 90, 20), 1, 10, 0.5, 0.4)
	for i = 0, 3 do
		task.delay(i * 0.07, function()
			pillar(pos + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3)), (i % 2 == 0) and Color3.fromRGB(255, 120, 30) or Color3.fromRGB(255, 220, 90), 14, 2.2, 0.45)
		end)
	end
	P.flyingBits(pos, Color3.fromRGB(255, 100, 30), 14, Vector3.new(0.5, 0.5, 0.5), Enum.Material.Neon, 18, 0.8, true)
	Effects.shake(0.6, 0.2)
end
FX[12] = function(pos, st, p, r) -- 빙결 쇄도
	spikeRing(pos, 12, r * 0.6, st.glow, 4, Enum.Material.Glass, 0.6)
	spikeRing(pos, 8, r * 0.3, WHITE, 3, Enum.Material.Glass, 0.5)
end
FX[13] = function(pos, st, p, r, data) -- 뇌전 사슬: 근처 적에게 번개
	local targets = data.near or {}
	local prev = pos
	for i, t in ipairs(targets) do
		if i > 5 then
			break
		end
		task.delay(i * 0.05, function()
			P.streak(prev, t, st.primary, 0.4, 0.25)
			P.lightningBolt(t, st.primary, 14, 0.3)
		end)
		prev = t
	end
	P.lightningBolt(pos, st.primary, 26, 0.6)
	floorRing(pos, st.secondary, 1, r * 2, 0.3, 0.3)
end
FX[14] = function(pos, st, p) -- 덩굴 휘감기
	local base = ground(pos)
	for v = 1, 4 do
		local a0 = v * math.pi / 2
		for i = 1, 8 do
			local t = i / 8
			local a = a0 + t * 4
			local spot = base + Vector3.new(math.cos(a) * (2.2 - t), t * 5, math.sin(a) * (2.2 - t))
			task.delay(i * 0.03, function()
				local leaf = P.fxPart(Vector3.new(0.4, 0.4, 0.9), CFrame.lookAt(spot, base + Vector3.new(0, 6, 0)), (i % 2 == 0) and st.primary or st.secondary, 0.1)
				P.fade(leaf, 0.6)
			end)
		end
	end
	P.flyingBits(pos, st.secondary, 10, Vector3.new(0.5, 0.05, 0.35), Enum.Material.Neon, 8, 0.8, true)
end
FX[15] = function(pos, st, p) -- 망령의 비명
	skull(pos, Color3.fromRGB(200, 190, 230), 1.2, 0.9)
	Effects.burst(pos, st.primary, 25, 10, 1.5, st.motif.tex)
	Effects.sound("ping", 0.4, 0.5)
end
FX[16] = function(pos, st, p, r) -- 천벌: 빛의 검
	fall(pos, Vector3.new(0.6, 0.6, 7), GOLD, 40, 0.3, Enum.Material.Neon, function()
		pillar(pos, WHITE, 30, 3, 0.4)
		floorRing(pos, GOLD, 2, r * 2.2, 0.5, 0.4)
		Effects.shake(0.7, 0.2)
	end)
end
FX[17] = function(pos, st, p) -- 피의 분수
	for i = 1, 3 do
		task.delay(i * 0.08, function()
			P.flyingBits(pos + Vector3.new(0, 1, 0), Color3.fromRGB(200, 10, 40), 12, Vector3.new(0.35, 0.35, 0.35), Enum.Material.Neon, 14, 0.8, true)
		end)
	end
	P.arc(CFrame.new(pos) * CFrame.Angles(0, math.random() * 6, math.rad(70)), 5, -80, 80, 10, 1, Color3.fromRGB(255, 40, 70), 0.35)
end
FX[18] = function(pos, st, p, r) -- 블랙홀
	local hole = sphere(pos, Color3.fromRGB(5, 0, 10), 0.5, 6, 0.6)
	hole.Material = Enum.Material.SmoothPlastic
	for k = 1, 2 do
		floorRing(pos, (k == 1) and st.secondary or st.glow, r * 2.4, 0.5, 0.55, 0.3)
	end
	implode(pos, st.glow, 24, r, 0.55)
	task.delay(0.6, function()
		sphere(pos, st.glow, 1, r * 1.6, 0.3)
		Effects.shake(0.8, 0.25)
	end)
end
FX[19] = function(pos, st, p, r) -- 유성우
	for i = 1, 5 do
		task.delay(i * 0.07, function()
			local spot = pos + Vector3.new((math.random() * 2 - 1) * r * 0.6, 0, (math.random() * 2 - 1) * r * 0.6)
			fall(spot, Vector3.new(1.2, 1.2, 1.2), Color3.fromRGB(255, 150, 60), 35, 0.3, Enum.Material.Neon, function()
				Effects.burst(ground(spot), Color3.fromRGB(255, 180, 80), 14, 18, 0.8)
				floorRing(spot, Color3.fromRGB(255, 120, 40), 1, 6, 0.3, 0.3)
			end)
		end)
	end
end
FX[20] = function(pos, st, p, r) -- 프리즘 굴절
	rays(pos, P.RAINBOW, 12, r * 2.2, 0.45)
	local gem = P.fxPart(Vector3.new(1.5, 1.5, 1.5), CFrame.new(pos) * CFrame.Angles(math.rad(45), 0, math.rad(45)), WHITE, 0.1)
	gem.Material = Enum.Material.Glass
	P.fade(gem, 0.5, { Size = Vector3.new(3.5, 3.5, 3.5) })
end
FX[21] = function(pos, st, p, r) -- 용의 불기둥
	tornado(pos, Color3.fromRGB(255, 110, 30), Color3.fromRGB(255, 220, 90), 14, 0.8)
	pillar(pos, Color3.fromRGB(255, 140, 40), 18, 4, 0.6)
	floorRing(pos, Color3.fromRGB(255, 90, 20), 2, r * 2.2, 0.6, 0.4)
	Effects.shake(0.7, 0.25)
end
FX[22] = function(pos, st, p, r) -- 절대영도
	local block = P.fxPart(Vector3.new(4, 6, 4), CFrame.new(pos), Color3.fromRGB(190, 235, 255), 0.35)
	block.Material = Enum.Material.Ice
	task.delay(0.3, function()
		block:Destroy()
		P.flyingBits(pos, Color3.fromRGB(210, 240, 255), 26, Vector3.new(0.7, 0.7, 0.7), Enum.Material.Ice, 20, 0.6, true)
		spikeRing(pos, 14, r * 0.7, Color3.fromRGB(200, 240, 255), 5, Enum.Material.Glass, 0.6)
		floorRing(pos, WHITE, 2, r * 2.4, 0.5, 0.3)
	end)
end
FX[23] = function(pos, st, p, r) -- 천둥신의 망치
	local start = pos + Vector3.new(0, 18, 0)
	local hammer = P.fxPart(Vector3.new(3, 2, 2), CFrame.new(start), Color3.fromRGB(150, 150, 170), 0)
	hammer.Material = Enum.Material.Metal
	local handle = P.fxPart(Vector3.new(0.5, 4, 0.5), CFrame.new(start + Vector3.new(0, 3, 0)), Color3.fromRGB(110, 70, 40), 0)
	P.animate(0.22, function(t)
		local y = 18 * (1 - t * t)
		hammer.CFrame = CFrame.new(pos + Vector3.new(0, y, 0))
		handle.CFrame = CFrame.new(pos + Vector3.new(0, y + 3, 0))
	end, function()
		P.fade(hammer, 0.3)
		P.fade(handle, 0.3)
		for _ = 1, 4 do
			P.lightningBolt(pos + Vector3.new((math.random() * 2 - 1) * r * 0.5, 0, (math.random() * 2 - 1) * r * 0.5), st.primary, 24, 0.5)
		end
		floorRing(pos, st.primary, 2, r * 2.4, 0.4, 0.5)
		Effects.shake(1.1, 0.3)
	end)
end
FX[24] = function(pos, st, p) -- 불사조
	local bird = pos + Vector3.new(0, 1, 0)
	wingFan(bird, Color3.fromRGB(255, 120, 40), 1.4, 0.7)
	local body = P.fxPart(Vector3.new(1, 1, 1.8), CFrame.new(bird), Color3.fromRGB(255, 200, 80), 0, Enum.PartType.Ball)
	P.addTrail(body, Color3.fromRGB(255, 120, 40), 1.2, 0.5)
	tween(body, 0.9, { Position = bird + Vector3.new(0, 18, 0), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Debris:AddItem(body, 1)
	Effects.burst(pos, Color3.fromRGB(255, 150, 50), 30, 20, 1, st.motif.tex)
end
FX[25] = function(pos, st, p, r) -- 차원 절단
	xSlash(pos, WHITE, r * 2.6, 0.4)
	xSlash(pos, st.secondary, r * 3.2, 0.5)
	sphere(pos, Color3.fromRGB(10, 0, 25), 3, 0.2, 0.4, Enum.Material.ForceField)
	Effects.shake(0.8, 0.2)
end
FX[26] = function(pos, st, p, r) -- 대천사 강림
	wingFan(pos + Vector3.new(0, 3, 0), GOLD, 1.8, 0.9)
	pillar(pos, WHITE, 50, 6, 0.7)
	floorRing(pos, GOLD, 2, r * 2.4, 0.6, 0.4)
	Effects.burst(pos, GOLD, 30, 20, 0.8)
end
FX[27] = function(pos, st, p, r) -- 혈월
	local moon = P.fxPart(Vector3.new(4, 4, 4), CFrame.new(pos + Vector3.new(0, 2, 0)), Color3.fromRGB(210, 20, 40), 0.1, Enum.PartType.Ball)
	tween(moon, 0.5, { Position = pos + Vector3.new(0, 10, 0) })
	task.delay(0.5, function()
		P.fade(moon, 0.25, { Size = Vector3.new(14, 14, 14) })
		rays(pos + Vector3.new(0, 10, 0), { Color3.fromRGB(255, 40, 60), Color3.fromRGB(120, 0, 20) }, 10, r * 2, 0.4)
		floorRing(pos, Color3.fromRGB(220, 20, 50), 2, r * 2.4, 0.4, 0.4)
		Effects.shake(0.9, 0.25)
	end)
end
FX[28] = function(pos, st, p, r) -- 사건의 지평선
	for k = 1, 3 do
		local d = r * (0.9 + k * 0.5)
		local ringPart = P.fxPart(Vector3.new(0.3, d, d), CFrame.new(pos) * CFrame.Angles(math.rad(k * 30), 0, math.rad(90)), (k % 2 == 0) and WHITE or st.secondary, 0.1, Enum.PartType.Cylinder)
		P.animate(0.7, function(t)
			ringPart.CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(k * 30) + t * 6, t * 4, math.rad(90))
			local sz = d * (1 - t * 0.9)
			ringPart.Size = Vector3.new(0.3, sz, sz)
		end, function()
			ringPart:Destroy()
		end)
	end
	local core = sphere(pos, Color3.fromRGB(0, 0, 0), 4, 0.5, 0.7)
	core.Material = Enum.Material.SmoothPlastic
	implode(pos, WHITE, 30, r * 1.2, 0.6)
	task.delay(0.7, function()
		sphere(pos, WHITE, 1, r * 2, 0.3)
		Effects.shake(1.2, 0.3)
	end)
end
FX[29] = function(pos, st, p, r) -- 초신성
	Effects.flash(pos, WHITE, r * 2, 0.4)
	for k = 0, 3 do
		task.delay(k * 0.08, function()
			floorRing(pos, (k % 2 == 0) and st.glow or Color3.fromRGB(255, 220, 140), 2, r * (1.4 + k * 0.6), 0.5, 0.4)
			sphere(pos, (k % 2 == 0) and Color3.fromRGB(255, 240, 200) or st.glow, 1, r * (0.8 + k * 0.4), 0.35)
		end)
	end
	rays(pos, { WHITE, st.glow, GOLD }, 16, r * 2.5, 0.5)
	P.flyingBits(pos, GOLD, 24, Vector3.new(0.4, 0.4, 0.4), Enum.Material.Neon, 26, 0.7, false)
	Effects.shake(1.4, 0.4)
end
FX[30] = function(pos, st, p, r, data) -- 빅뱅
	local core = sphere(pos, WHITE, 6, 0.3, 0.35)
	core.Material = Enum.Material.Neon
	implode(pos, P.RAINBOW[1], 20, r * 1.5, 0.35)
	task.delay(0.35, function()
		for k, c in ipairs(P.RAINBOW) do
			task.delay(k * 0.04, function()
				floorRing(pos, c, 2, r * (1.2 + k * 0.4), 0.6, 0.4)
			end)
		end
		rays(pos, P.RAINBOW, 24, r * 3, 0.6)
		sphere(pos, WHITE, 1, r * 2.5, 0.4)
		pillar(pos, WHITE, 80, 8, 0.8)
		Effects.shake(1.8, 0.5)
		Effects.sound("lunge", 1, 0.3)
	end)
end

-- 적이 쓰러질 때. data = { pos, fx, radius, boss, near = 근처 적 위치들 }
function KillFx.play(data: any)
	local tier = data.fx or 0
	local fn = FX[tier]
	if not fn or not P then
		return
	end
	local st = KillFx.styleFor(tier)
	local p = tier / #Config.KillFx
	local r = math.max(4, data.radius or 6)
	local ok, err = pcall(fn, data.pos, st, p, r, data)
	if not ok then
		warn("[Arena] 킬 이펙트 오류:", err)
	end
	-- 폭발 범위가 바닥에 고리로 보인다
	floorRing(data.pos, st.glow, 1, r * 2, 0.35, 0.15)
	sound(p)
end

-- 아우라 파동: 내 발밑에서 아우라 색 고리가 퍼진다
function KillFx.pulse(data: any)
	if not P then
		return
	end
	local tier = data.tier or 1
	local st = (tier >= #Config.Auras) and GradeStyle.get(100) or GradeStyle.get(Config.Auras[tier].motif + ((tier - 1) // 10) * 30)
	local r = data.radius or 8
	floorRing(data.pos, st.glow, 2, r * 2, 0.45, 0.25)
	if tier >= 11 then
		floorRing(data.pos, st.secondary, 1, r * 1.6, 0.35, 0.2)
	end
	if tier >= 21 then
		for i = 1, 6 do
			local a = (i / 6) * math.pi * 2
			pillar(data.pos + Vector3.new(math.cos(a) * r * 0.7, 0, math.sin(a) * r * 0.7), st.glow, 10, 0.8, 0.35)
		end
	end
	if (data.hit or 0) > 0 then
		Effects.burst(data.pos, st.glow, 12 + tier, 14, 0.5, st.motif.tex)
	end
end

-- 사제 치유: 사제에서 치유받는 적에게 초록 빛줄기
function KillFx.heal(data: any)
	if not P then
		return
	end
	local green = Color3.fromRGB(120, 255, 150)
	for _, t in ipairs(data.targets or {}) do
		P.streak(data.from + Vector3.new(0, 3, 0), t + Vector3.new(0, 1, 0), green, 0.35, 0.4)
		Effects.burst(t, green, 10, 6, 0.6)
	end
	Effects.flash(data.from + Vector3.new(0, 3, 0), green, 4, 0.3)
end

return KillFx
