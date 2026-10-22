-- 권왕 1.7: 모든 권법의 기술 연출 보완 (수치는 그대로, 보이는 것만)
-- 권법마다 '속성의 서명'을 하나씩 둔다: 불은 불씨와 불혀, 물은 물방울 왕관, 번개는 잔 번개, 바람은 휘감는 바람결 …
--   · 기술(강타·E·R·오의·초 오의)을 쓰는 순간 몸 앞에 서명이 피어난다
--   · 따로 만든 E·R 연출이 없던 권법은 기술이 이어지는 동안 몸을 따라 서명이 흐른다
--   · 기술로 맞힐 때마다 맞은 자리에 서명이 터진다 (타격 연출이 비어 있던 불·바다·일월·바람·취권은 평타에도)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Polish = {}

local folder = Instance.new("Folder")
folder.Name = "KwonPolish"
folder.Parent = workspace

local WHITE = Color3.new(1, 1, 1)
local live = 0
local MAX_LIVE = 500 -- 한꺼번에 떠 있는 조각 한도 (넘으면 새 서명은 줄여서)

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal):Play()
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
end
local function bit(size: Vector3, color: Color3, mat: Enum.Material?, alpha: number?, ball: boolean?, life: number?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.Neon
	p.Transparency = alpha or 0
	if ball then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	end
	p.Parent = folder
	live += 1
	local l = life or 0.6
	task.delay(l + 0.05, function()
		live -= 1
		p:Destroy()
	end)
	return p
end
local function rnd(a: number, b: number): number
	return a + math.random() * (b - a)
end
local function randDir(upBias: number?): Vector3
	local v = Vector3.new(rnd(-1, 1), rnd(-0.3, 1) + (upBias or 0), rnd(-1, 1))
	return v.Magnitude > 0.01 and v.Unit or Vector3.new(0, 1, 0)
end

------------------------------------------------------------------------
-- 속성마다의 서명 (pos = 피어나는 자리, look = 앞 방향, s = 크기)
------------------------------------------------------------------------
local SIG: { [string]: (Vector3, Vector3, number, Color3, Color3) -> () } = {}

-- 불: 위로 튀는 불씨와, 사방으로 날름거리는 불혀
SIG.fire = function(pos, look, s, c, c2)
	Fx.burst("ember", pos, Color3.fromRGB(255, 150, 50), math.floor(10 * s), s)
	for k = 0, 5 do
		local d = (look * 0.6 + randDir(0.4)).Unit
		local t = bit(Vector3.new(0.5, 0.5, 2.2) * s, k % 2 == 0 and Color3.fromRGB(255, 120, 30) or Color3.fromRGB(255, 210, 90), Enum.Material.Neon, 0.1, false, 0.3)
		t.CFrame = CFrame.lookAt(pos, pos + d)
		tween(t, 0.28, { CFrame = CFrame.lookAt(pos + d * 4 * s, pos + d * 5 * s), Size = Vector3.new(0.1, 0.1, 3.6) * s, Transparency = 1 })
	end
	Fx.flash(pos, Color3.fromRGB(255, 140, 50), 16 * s, 2.5, 0.3)
end
-- 물: 물방울 왕관 (솟았다 떨어지는 물기둥 여덟 줄기)과 물결 고리
SIG.water = function(pos, look, s, c, c2)
	Fx.ring(pos - Vector3.new(0, 1.5, 0), c2, 1, 10 * s, 0.4)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		local drop = bit(Vector3.new(0.45, 0.45, 0.45) * s, k % 2 == 0 and c2 or WHITE, Enum.Material.Glass, 0.15, true, 0.5)
		drop.Position = pos
		tween(drop, 0.22, { Position = pos + d * 2.4 * s + Vector3.new(0, 2.6 * s, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.22, function()
			tween(drop, 0.25, { Position = pos + d * 3.6 * s - Vector3.new(0, 1.5, 0), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end)
	end
end
SIG.ocean = function(pos, look, s, c, c2)
	SIG.water(pos, look, s, c, c2)
	-- 흰 물보라 띠가 앞으로 휘어 나간다
	for i = -3, 3 do
		local a = i / 3 * 0.9
		local d = (CFrame.lookAt(Vector3.zero, look) * CFrame.Angles(0, a, 0)).LookVector
		local f = bit(Vector3.new(1.2, 0.3, 1.2) * s, WHITE, Enum.Material.SmoothPlastic, 0.2, true, 0.4)
		f.Position = pos
		tween(f, 0.35, { Position = pos + d * 5 * s + Vector3.new(0, 1, 0), Size = Vector3.new(2.6, 0.2, 2.6) * s, Transparency = 1 })
	end
end
-- 번개: 맞은 자리에서 사방으로 튀는 잔 번개
SIG.lightning = function(pos, look, s, c, c2)
	for _ = 1, 3 do
		Fx.lightning(pos, pos + randDir(0.3) * rnd(4, 7) * s, c2, 0.4)
	end
	Fx.flash(pos, c, 18 * s, 3, 0.2)
end
-- 바람: 휘감아 도는 흰 바람결 여섯 줄
SIG.wind = function(pos, look, s, c, c2)
	for k = 0, 5 do
		local a0 = k / 6 * math.pi * 2
		local streak = bit(Vector3.new(0.12, 0.12, 3) * s, k % 2 == 0 and WHITE or c2, Enum.Material.Neon, 0.25, false, 0.4)
		local r = 2.2 * s
		local function at(a: number, y: number): CFrame
			local p = pos + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
			return CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0.2, math.cos(a)))
		end
		streak.CFrame = at(a0, -0.6)
		tween(streak, 0.35, { CFrame = at(a0 + 2.4, 1.6 * s), Transparency = 1 })
	end
	Fx.burst("dust", pos - Vector3.new(0, 1.5, 0), Color3.fromRGB(230, 235, 230), math.floor(6 * s), s)
end
-- 공허·아공·중력: 검은 구슬이 안으로 짓눌리며 둘레의 빛이 빨려 든다
local function implode(pos: Vector3, s: number, c: Color3, c2: Color3, dark: Color3)
	local ball = bit(Vector3.one * 4 * s, dark, Enum.Material.Neon, 0.2, true, 0.35)
	ball.Position = pos
	tween(ball, 0.3, { Size = Vector3.one * 0.3, Transparency = 0.6 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	for k = 0, 7 do
		local d = randDir(0)
		local st = bit(Vector3.new(0.15, 0.15, 2) * s, k % 2 == 0 and c or c2, Enum.Material.Neon, 0.1, false, 0.3)
		st.CFrame = CFrame.lookAt(pos + d * 5 * s, pos)
		tween(st, 0.25, { CFrame = CFrame.lookAt(pos + d * 0.5, pos), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
end
SIG.void = function(pos, look, s, c, c2)
	implode(pos, s, c, c2, Color3.fromRGB(20, 15, 30))
end
SIG.subspace = function(pos, look, s, c, c2)
	implode(pos, s, c, c2, Color3.fromRGB(40, 10, 70))
	-- 어긋난 공간 조각 (네모가 흩어지며 사라진다)
	for _ = 1, 5 do
		local q = bit(Vector3.one * rnd(0.4, 1) * s, c2, Enum.Material.Glass, 0.3, false, 0.45)
		q.CFrame = CFrame.new(pos + randDir(0) * rnd(1, 3) * s) * CFrame.Angles(rnd(0, 6), rnd(0, 6), 0)
		tween(q, 0.4, { CFrame = q.CFrame * CFrame.new(0, 1, 0) * CFrame.Angles(1, 1, 0), Transparency = 1 })
	end
end
SIG.gravity = function(pos, look, s, c, c2)
	implode(pos, s, c, c2, Color3.fromRGB(30, 20, 50))
	Fx.ring(pos - Vector3.new(0, 1.8, 0), c, 12 * s, 1, 0.3)
end
-- 피: 붉은 안개와 핏방울
SIG.blood = function(pos, look, s, c, c2)
	Fx.burst("smoke", pos, Color3.fromRGB(150, 10, 20), math.floor(5 * s), 0.7 * s)
	for _ = 1, 7 do
		local d = bit(Vector3.one * 0.35 * s, Color3.fromRGB(190, 15, 25), Enum.Material.Neon, 0.1, true, 0.45)
		d.Position = pos
		local v = randDir(0.3) * rnd(2, 5) * s
		tween(d, 0.4, { Position = pos + v - Vector3.new(0, 2, 0), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
end
-- 꽃잎
SIG.petal = function(pos, look, s, c, c2)
	for _ = 1, math.floor(9 * s) do
		local p = bit(Vector3.new(0.7, 0.07, 0.5) * s, math.random() < 0.5 and c or c2, Enum.Material.SmoothPlastic, 0, true, 0.9)
		p.CFrame = CFrame.new(pos) * CFrame.Angles(rnd(0, 6), rnd(0, 6), rnd(0, 6))
		tween(p, 0.85, { CFrame = CFrame.new(pos + randDir(0.2) * rnd(2, 5) * s - Vector3.new(0, 1, 0)) * CFrame.Angles(rnd(0, 12), rnd(0, 12), rnd(0, 12)), Transparency = 1 }, Enum.EasingStyle.Sine)
	end
end
-- 용: 금빛 비늘이 나선으로 솟는다
SIG.dragon = function(pos, look, s, c, c2)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 4
		local sc = bit(Vector3.new(0.7, 0.12, 0.5) * s, k % 2 == 0 and c or c2, Enum.Material.Neon, 0.1, false, 0.5)
		local p0 = pos + Vector3.new(math.cos(a) * 1.4 * s, -1 + k * 0.2, math.sin(a) * 1.4 * s)
		sc.CFrame = CFrame.lookAt(p0, pos)
		tween(sc, 0.45, { CFrame = CFrame.lookAt(p0 + Vector3.new(math.cos(a) * 2, 3 * s, math.sin(a) * 2), pos + Vector3.new(0, 4 * s, 0)), Transparency = 1 })
	end
end
-- 금강: 세로로 선 금빛 광륜
SIG.gold = function(pos, look, s, c, c2)
	local halo = bit(Vector3.new(0.3, 2, 2) * s, c, Enum.Material.Neon, 0.2, false, 0.4)
	halo.Shape = Enum.PartType.Cylinder
	halo.CFrame = CFrame.lookAt(pos, pos + look) * CFrame.Angles(0, math.rad(90), 0)
	tween(halo, 0.35, { Size = Vector3.new(0.1, 9, 9) * s, Transparency = 1 })
	Fx.burst("glitter", pos, c2, math.floor(8 * s), s)
end
-- 그림자: 검은 연기와 흩어지는 그림자 조각
SIG.shadow = function(pos, look, s, c, c2)
	Fx.burst("smoke", pos, Color3.fromRGB(25, 20, 35), math.floor(5 * s), 0.8 * s)
	for _ = 1, 5 do
		local q = bit(Vector3.new(0.9, 0.9, 0.1) * s, Color3.fromRGB(30, 25, 45), Enum.Material.SmoothPlastic, 0.2, false, 0.4)
		q.CFrame = CFrame.new(pos) * CFrame.Angles(rnd(0, 6), rnd(0, 6), 0)
		tween(q, 0.35, { CFrame = CFrame.new(pos + randDir(0) * 3 * s), Transparency = 1 })
	end
end
-- 별 (천상·은하·성하): 반짝 별빛 여섯이 켜졌다 꺼진다
local function stars(pos: Vector3, s: number, c: Color3, c2: Color3)
	for k = 0, 5 do
		local st = bit(Vector3.new(0.2, 1.6, 0.2) * s, k % 2 == 0 and WHITE or c2, Enum.Material.Neon, 0, false, 0.45)
		local at = pos + randDir(0.2) * rnd(1.2, 3.2) * s
		st.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(45 * (k % 2)))
		local st2 = bit(Vector3.new(0.2, 1.6, 0.2) * s, k % 2 == 0 and WHITE or c2, Enum.Material.Neon, 0, false, 0.45)
		st2.CFrame = st.CFrame * CFrame.Angles(0, 0, math.rad(90))
		for _, x in ipairs({ st, st2 }) do
			tween(x, 0.4, { Size = Vector3.new(0.05, 0.1, 0.05), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
	end
	Fx.burst("glitter", pos, c, math.floor(6 * s), s)
end
SIG.celestial = function(pos, look, s, c, c2)
	stars(pos, s, c, c2)
end
SIG.galaxy = function(pos, look, s, c, c2)
	stars(pos, s, c, c2)
	Fx.ring(pos, c, 1, 9 * s, 0.4, look)
end
SIG.cosmic = SIG.galaxy
-- 구름: 하얀 구름 뭉치가 부풀며 흩어진다
SIG.cloud = function(pos, look, s, c, c2)
	for _ = 1, 6 do
		local puff = bit(Vector3.one * rnd(1.2, 2.2) * s, Color3.fromRGB(250, 250, 255), Enum.Material.SmoothPlastic, 0.15, true, 0.6)
		puff.Position = pos + randDir(0) * s
		tween(puff, 0.55, { Position = puff.Position + randDir(0.4) * 2.5 * s, Size = puff.Size * 2.2, Transparency = 1 })
	end
end
-- 시간: 시계판 고리와 바늘 둘이 한 바퀴 돈다
SIG.time = function(pos, look, s, c, c2)
	local cf = CFrame.lookAt(pos, pos + look)
	Fx.ring(pos, c, 2 * s, 6 * s, 0.45, look)
	for i, len in ipairs({ 2.2, 1.4 }) do
		local hand = bit(Vector3.new(0.18, len * s, 0.1), i == 1 and c2 or WHITE, Enum.Material.Neon, 0.05, false, 0.45)
		local t0 = os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local t = os.clock() - t0
			if t > 0.4 or not hand.Parent then
				conn:Disconnect()
				return
			end
			local a = -t * (i == 1 and 14 or 5)
			hand.CFrame = cf * CFrame.Angles(0, 0, a) * CFrame.new(0, len * s / 2, 0)
			hand.Transparency = t / 0.4
		end)
	end
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local mark = bit(Vector3.new(0.12, 0.4, 0.1) * s, c2, Enum.Material.Neon, 0.1, false, 0.4)
		mark.CFrame = cf * CFrame.Angles(0, 0, a) * CFrame.new(0, 2.6 * s, 0)
		tween(mark, 0.4, { Transparency = 1 })
	end
end
-- 태초: 하얀 빛살 여덟 줄기
SIG.origin = function(pos, look, s, c, c2)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local d = (CFrame.lookAt(Vector3.zero, look) * CFrame.Angles(0, 0, a)).UpVector
		local ray = bit(Vector3.new(0.18, 0.18, 0.5) * s, k % 2 == 0 and WHITE or c2, Enum.Material.Neon, 0, false, 0.3)
		ray.CFrame = CFrame.lookAt(pos, pos + d)
		tween(ray, 0.25, { CFrame = CFrame.lookAt(pos + d * 2.5 * s, pos + d * 3 * s), Size = Vector3.new(0.05, 0.05, 5 * s), Transparency = 1 })
	end
	Fx.flash(pos, WHITE, 18 * s, 3, 0.25)
end
-- 일월: 검은 해와 금빛 테 (일식의 코로나)
SIG.eclipse = function(pos, look, s, c, c2)
	local disc = bit(Vector3.new(0.2, 3, 3) * s, Color3.fromRGB(15, 10, 20), Enum.Material.SmoothPlastic, 0, false, 0.45)
	disc.Shape = Enum.PartType.Cylinder
	disc.CFrame = CFrame.lookAt(pos, pos + look) * CFrame.Angles(0, math.rad(90), 0)
	local rim = bit(Vector3.new(0.15, 3.6, 3.6) * s, Color3.fromRGB(255, 200, 90), Enum.Material.Neon, 0.1, false, 0.45)
	rim.Shape = Enum.PartType.Cylinder
	rim.CFrame = disc.CFrame * CFrame.new(-0.05, 0, 0)
	tween(disc, 0.4, { Size = Vector3.new(0.2, 4.5, 4.5) * s, Transparency = 1 })
	tween(rim, 0.4, { Size = Vector3.new(0.1, 7, 7) * s, Transparency = 1 })
end
-- 결투 (무쌍): 엇갈린 쇳빛 섬광
SIG.duel = function(pos, look, s, c, c2)
	local cf = CFrame.lookAt(pos, pos + look)
	for _, a in ipairs({ math.rad(40), math.rad(-40) }) do
		local l = bit(Vector3.new(0.15, 5 * s, 0.15), WHITE, Enum.Material.Neon, 0, false, 0.25)
		l.CFrame = cf * CFrame.Angles(0, 0, a)
		tween(l, 0.22, { Size = Vector3.new(0.05, 7 * s, 0.05), Transparency = 1 })
	end
	Fx.spark(pos, c, 1.2 * s, 8)
end
-- 삼재: 흙먼지와 작은 충격 고리
SIG.basic = function(pos, look, s, c, c2)
	Fx.burst("dust", pos - Vector3.new(0, 1.5, 0), Color3.fromRGB(200, 185, 160), math.floor(5 * s), s)
	Fx.ring(pos, c, 1, 7 * s, 0.25, look)
end
-- 취권: 술 방울 (초록빛 도는 투명한 알갱이)
SIG.drunk = function(pos, look, s, c, c2)
	for _ = 1, 7 do
		local d = bit(Vector3.one * 0.35 * s, Color3.fromRGB(215, 245, 225), Enum.Material.Glass, 0.25, true, 0.5)
		d.Position = pos
		tween(d, 0.45, { Position = pos + randDir(0.5) * rnd(2, 4) * s - Vector3.new(0, 1.5, 0), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	Fx.flash(pos, c, 12 * s, 2, 0.2)
end

local function styleOf(id: any): any
	return type(id) == "string" and Config.STYLE_BY_ID[id] or nil
end
local function rootOf(m: Instance?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function sig(style: any, pos: Vector3, look: Vector3, s: number)
	if not near(pos, 180) then
		return
	end
	if live > MAX_LIVE then
		s *= 0.5
		if live > MAX_LIVE * 1.4 then
			return
		end
	end
	local fn = SIG[style.fx] or SIG.basic
	fn(pos, look, s, style.color, style.color2)
end

-- Fx.cast에 따로 만든 E·R 연출이 없는 속성 (기술 동안 몸을 따라 서명이 흐른다)
local CAST_DONE: { [string]: boolean } = {}
for _, k in ipairs({ "basic", "blood", "cosmic", "dragon", "drunk", "gold", "king", "lightning", "petal", "shadow", "void", "water" }) do
	CAST_DONE[k] = true
end

------------------------------------------------------------------------
-- 기술을 쓸 때 (모두가 본다)
------------------------------------------------------------------------
function Polish.cast(styleId: any, slot: any, model: Model, dur: number)
	local style = styleOf(styleId)
	local r = rootOf(model)
	if not style or not r or type(slot) == "number" or slot == "J" then
		return
	end
	local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
	local big = slot == "G" or slot == "X"
	-- 기술이 나가는 순간 몸 앞에 서명
	task.delay(math.min(0.18, dur * 0.3), function()
		local rr = rootOf(model)
		if rr then
			sig(style, rr.Position + look * 3 + Vector3.new(0, 0.5, 0), look, big and 1.8 or (slot == "H" and 1.1 or 1.3))
		end
	end)
	-- 따로 만든 연출이 없던 E·R: 기술이 이어지는 동안 손과 발을 따라 서명이 흐른다
	if (slot == "E" or slot == "R") and not CAST_DONE[style.fx] then
		local t0 = os.clock()
		local last = 0
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local t = os.clock() - t0
			if t > math.min(1.2, dur) or not model.Parent then
				conn:Disconnect()
				return
			end
			if t - last < 0.14 then
				return
			end
			last = t
			local limb = model:FindFirstChild(math.random() < 0.5 and "RightHand" or "LeftHand")
			if limb and limb:IsA("BasePart") then
				sig(style, limb.Position, look, 0.55)
			end
		end)
	end
	-- 오의·초 오의: 발밑에서 서명이 둥글게 한 번 더
	if big then
		for k = 0, 3 do
			local a = k / 4 * math.pi * 2
			task.delay(0.1 + k * 0.05, function()
				local rr = rootOf(model)
				if rr then
					sig(style, rr.Position + Vector3.new(math.cos(a) * 5, -1.5, math.sin(a) * 5), look, 0.9)
				end
			end)
		end
	end
end

------------------------------------------------------------------------
-- 맞힐 때 (handlers.hit에서): 기술이면 맞은 자리에 서명이 터진다
------------------------------------------------------------------------
local HIT_EMPTY: { [string]: boolean } = { fire = true, ocean = true, eclipse = true, wind = true, drunk = true }
function Polish.hit(styleId: any, pos: Vector3, heavy: boolean, skill: boolean, dir: Vector3?)
	local style = styleOf(styleId)
	if not style or not pos then
		return
	end
	local look = dir or Vector3.new(0, 0, -1)
	if skill then
		sig(style, pos, look, heavy and 1.4 or 1)
	elseif HIT_EMPTY[style.fx] then
		sig(style, pos, look, heavy and 0.9 or 0.6)
	end
end

return Polish
