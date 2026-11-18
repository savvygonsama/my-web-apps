-- 권왕 3.99.23판: 권법 제작소 권법 셋의 기술 연출 (서버 장치 forgeSeq → skillfx "forgeStart" · "forgeStep")
--   삼원혼천권: 불줄기 · 물보라 · 물기둥 · 벼락 · 셋이 모여 터지는 김의 폭풍
--   구룡패천권: 금빛 발톱 · 용의 아가리 · 헤엄치는 금룡 · 똬리 · 내리꽂는 용 · 용왕관
--   혼돈개천권: 혼돈의 구슬 · 무너짐 · 별 모양 금 · 찢어진 공간 · 유리처럼 깨지는 공간 · 검은 구멍 · 새 하늘
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local ForgeFx = {}
local opts: any = {}

local folder = Instance.new("Folder")
folder.Name = "KwonForgeFx"
folder.Parent = workspace

local V = Vector3.new
local CF = CFrame.new
local WHITE = Color3.new(1, 1, 1)

local function piece(size: Vector3, cf: CFrame, color: Color3, alpha: number?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = alpha or 0
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Parent = folder
	return p
end
local function tween(p: Instance, t: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	TweenService:Create(p, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal):Play()
end
local function fadeOut(p: BasePart, t: number, grow: Vector3?)
	local goal: { [string]: any } = { Transparency = 1 }
	if grow then
		goal.Size = grow
	end
	tween(p, t, goal)
	Debris:AddItem(p, t + 0.05)
end
local function ground(at: Vector3): Vector3
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { folder }
	local r = workspace:Raycast(at + V(0, 8, 0), V(0, -40, 0), rp)
	return r and r.Position or at - V(0, 2.5, 0)
end
local function disc(at: Vector3, r: number, color: Color3, alpha: number, life: number, toR: number?)
	local p = piece(V(0.3, r * 2, r * 2), CF(at) * CFrame.Angles(0, 0, math.rad(90)), color, alpha, Enum.PartType.Cylinder)
	fadeOut(p, life, toR and V(0.1, toR * 2, toR * 2) or nil)
	return p
end
local function shake(n: number)
	if opts.shake then
		pcall(opts.shake, n)
	end
end

-- 빛깔: 그 권법의 palette[col] (없으면 권법 빛깔)
local function colorsOf(data: any): (Color3, Color3, { Color3 })
	local st = Config.STYLE_BY_ID[data.style or ""]
	local pal = (st and st.palette) or { st and st.color or WHITE, st and st.color2 or WHITE, WHITE }
	local c = pal[data.col or 1] or pal[1]
	return c, (st and st.color2) or WHITE, pal
end

------------------------------------------------------------------------
-- 삼원혼천권
------------------------------------------------------------------------
local VFX: { [string]: (any, Color3, Color3, { Color3 }) -> () } = {}

VFX.fireLine = function(d, c)
	local from, dir = d.from :: Vector3, d.dir :: Vector3
	local len = d.length or 24
	local n = 8
	for i = 1, n do
		task.delay(i * 0.025, function()
			local at = from + dir * (len * i / n)
			local g = ground(at)
			local b = piece(V(3, 3, 3), CF(g + V(0, 1.5, 0)), c, 0.1, Enum.PartType.Ball)
			fadeOut(b, 0.45, V(6, 9, 6))
			Fx.burst("spark", g + V(0, 1, 0), c, 4, 1)
		end)
	end
	Fx.flash(from + dir * len * 0.5, c, 24, 2, 0.3)
end
VFX.fireBurst = function(d, c)
	local g = ground(d.at)
	disc(g + V(0, 0.3, 0), 2, c, 0.1, 0.45, d.radius or 10)
	local b = piece(V(4, 4, 4), CF(g + V(0, 2, 0)), c, 0.05, Enum.PartType.Ball)
	fadeOut(b, 0.4, V((d.radius or 10) * 1.6, 6, (d.radius or 10) * 1.6))
	Fx.burst("spark", g + V(0, 2, 0), c, 18, 1.4)
	shake(0.3)
end
VFX.firePillar = function(d, c)
	local g = ground(d.at)
	disc(g + V(0, 0.3, 0), 1, c, 0.2, 0.5, d.radius or 6)
	local p = piece(V(3, 1, 3), CF(g + V(0, 0.5, 0)), c, 0.05, Enum.PartType.Cylinder)
	p.CFrame = CF(g + V(0, 9, 0)) * CFrame.Angles(0, 0, math.rad(90))
	p.Size = V(1, 4, 4)
	tween(p, 0.18, { Size = V(18, 5, 5) })
	task.delay(0.2, function()
		fadeOut(p, 0.4, V(22, 1, 1))
	end)
	Fx.burst("spark", g + V(0, 6, 0), Color3.fromRGB(255, 200, 90), 10, 1.2)
end
VFX.waterBurst = function(d, c)
	local g = ground(d.at)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local drop = piece(V(1.2, 1.2, 1.2), CF(g + V(0, 1, 0)), c, 0.1, Enum.PartType.Ball)
		tween(drop, 0.45, { Position = g + V(math.cos(a) * (d.radius or 8), 5, math.sin(a) * (d.radius or 8)), Transparency = 1 })
		Debris:AddItem(drop, 0.5)
	end
	disc(g + V(0, 0.4, 0), 2, c, 0.2, 0.5, d.radius or 8)
	Fx.ring(g + V(0, 0.5, 0), c, 2, (d.radius or 8) * 2, 0.45)
end
VFX.waterRing = function(d, c)
	local g = ground(d.at)
	local r = d.radius or 18
	local ring = piece(V(2.5, (d.inner or 6) * 2, (d.inner or 6) * 2), CF(g + V(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), c, 0.25, Enum.PartType.Cylinder)
	tween(ring, 0.45, { Size = V(4, r * 2, r * 2), Transparency = 1 })
	Debris:AddItem(ring, 0.5)
	Fx.ring(g + V(0, 0.6, 0), WHITE, r * 1.2, r * 2, 0.4)
end
VFX.waterSpout = function(d, c)
	local g = ground(d.at)
	local col = piece(V(2, 3, 3), CF(g + V(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), c, 0.2, Enum.PartType.Cylinder)
	tween(col, 0.2, { Size = V(16, 4.5, 4.5), CFrame = CF(g + V(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(0.22, function()
		fadeOut(col, 0.35, V(18, 1, 1))
		Fx.burst("glitter", g + V(0, 15, 0), WHITE, 10, 1.2)
	end)
end
VFX.thunder = function(d, c)
	local g = ground(d.at)
	Fx.lightning(g + V((math.random() - 0.5) * 6, 40, (math.random() - 0.5) * 6), g + V(0, 0.5, 0), c, 0.5)
	disc(g + V(0, 0.3, 0), 1, WHITE, 0, 0.3, (d.radius or 6))
	shake(0.25)
end
VFX.triad = function(d, _c, _c2, pal)
	local g = ground(d.at)
	local r = d.radius or 20
	-- 세 기운이 둘레를 돌며 안으로 모였다가 김으로 터진다
	for k = 0, 2 do
		local col = pal[k + 1] or WHITE
		local orb = piece(V(3, 3, 3), CF(g + V(math.cos(k * 2.09) * r, 4, math.sin(k * 2.09) * r)), col, 0, Enum.PartType.Ball)
		tween(orb, 0.3, { Position = g + V(0, 5, 0), Size = V(1.5, 1.5, 1.5) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Debris:AddItem(orb, 0.32)
	end
	task.delay(0.3, function()
		local core = piece(V(4, 4, 4), CF(g + V(0, 5, 0)), WHITE, 0, Enum.PartType.Ball)
		fadeOut(core, 0.6, V(r * 2, r * 1.2, r * 2))
		for k = 0, 2 do
			Fx.ring(g + V(0, 1 + k, 0), pal[k + 1] or WHITE, 4, r * 2.4, 0.5 + k * 0.1)
		end
		Fx.burst("dust", g + V(0, 2, 0), Color3.fromRGB(235, 235, 240), 24, 2)
		Fx.flash(g + V(0, 5, 0), WHITE, r * 2, 4, 0.4)
		shake(1)
	end)
end

------------------------------------------------------------------------
-- 구룡패천권
------------------------------------------------------------------------
VFX.claw = function(d, c)
	local from, dir = d.from :: Vector3, d.dir :: Vector3
	local right = V(-dir.Z, 0, dir.X)
	local len = d.length or 11
	for k = -1, 1 do
		local a = from + dir * 2 + right * (k * 1.6 - len * 0.35) + V(0, 2 + k * 0.4, 0)
		local b = from + dir * len + right * (k * 1.6 + len * 0.35) + V(0, 1 - k * 0.4, 0)
		local mid = (a + b) / 2
		local s = piece(V(0.35, 0.35, 0.5), CFrame.lookAt(mid, b), c, 0)
		tween(s, 0.08, { Size = V(0.4, 0.4, (b - a).Magnitude) })
		task.delay(0.1, function()
			fadeOut(s, 0.25, V(0.05, 0.05, (b - a).Magnitude))
		end)
	end
	Fx.burst("spark", from + dir * len * 0.6 + V(0, 2, 0), c, 8, 1)
end
VFX.jaw = function(d, c, c2)
	local at = d.at + V(0, 2.5, 0)
	local dir = d.dir :: Vector3
	-- 위아래 턱이 벌어졌다 닫힌다
	for _, s in ipairs({ 1, -1 }) do
		local jaw = piece(V(6, 0.8, 4), CFrame.lookAt(at - dir * 3, at + dir) * CF(0, s * 3, 0) * CFrame.Angles(s * 0.6, 0, 0), c, 0.1)
		tween(jaw, 0.14, { CFrame = CFrame.lookAt(at - dir * 3, at + dir) * CF(0, s * 0.4, -2) })
		task.delay(0.16, function()
			fadeOut(jaw, 0.25)
		end)
	end
	task.delay(0.14, function()
		Fx.blast(at, c, c2, 0.9)
		shake(0.4)
	end)
end
local function serpentPath(from: Vector3, to: Vector3, n: number, c: Color3, c2: Color3, dur: number)
	local dir = (to - from)
	local right = V(-dir.Unit.Z, 0, dir.Unit.X)
	for i = 0, n - 1 do
		task.delay(i * dur / n, function()
			local k = i / (n - 1)
			local at = from + dir * k + right * math.sin(k * math.pi * 3) * 2.5 + V(0, 3 + math.sin(k * math.pi * 2) * 1.2, 0)
			local sz = i == n - 1 and 4.5 or (3.4 - k * 1.2)
			local seg = piece(V(sz, sz, sz), CF(at), i % 3 == 0 and c2 or c, 0.05, Enum.PartType.Ball)
			fadeOut(seg, 0.5, V(sz * 0.4, sz * 0.4, sz * 0.4))
		end)
	end
end
VFX.serpent = function(d, c, c2)
	local from, dir = d.from :: Vector3, d.dir :: Vector3
	local len = d.length or 40
	serpentPath(from + dir * 2, from + dir * len, 16, c, c2, 0.35)
	Fx.flash(from + dir * len * 0.5, c, 30, 2.5, 0.35)
end
VFX.coil = function(d, c, c2)
	local g = ground(d.at)
	local r = d.radius or 12
	for i = 0, 13 do
		task.delay(i * 0.02, function()
			local a = i / 14 * math.pi * 2
			local seg = piece(V(2.4, 2.4, 2.4), CF(g + V(math.cos(a) * r * 0.6, 1.5 + i * 0.25, math.sin(a) * r * 0.6)), i % 3 == 0 and c2 or c, 0.05, Enum.PartType.Ball)
			fadeOut(seg, 0.45)
		end)
	end
	task.delay(0.3, function()
		Fx.blast(g + V(0, 3, 0), c, c2, 1.2)
		shake(0.5)
	end)
end
VFX.dragonDive = function(d, c, c2)
	local g = ground(d.at)
	local sky = g + V((math.random() - 0.5) * 30, 50, (math.random() - 0.5) * 30)
	serpentPath(sky, g, 10, c, c2, 0.18)
	task.delay(0.18, function()
		disc(g + V(0, 0.3, 0), 1.5, c, 0.1, 0.35, d.radius or 7)
		Fx.burst("spark", g + V(0, 1, 0), c, 10, 1.1)
		shake(0.2)
	end)
end
VFX.crown = function(d, c, c2)
	local g = ground(d.at)
	local r = d.radius or 20
	local spikes = 10
	for k = 0, spikes - 1 do
		local a = k / spikes * math.pi * 2
		local at = g + V(math.cos(a) * r * 0.75, 0, math.sin(a) * r * 0.75)
		local sp = piece(V(2.2, 1, 2.2), CF(at), k % 2 == 0 and c or c2, 0, Enum.PartType.Block)
		sp.Material = Enum.Material.Metal
		tween(sp, 0.25, { Size = V(2.2, 14, 2.2), CFrame = CF(at + V(0, 7, 0)) * CFrame.Angles(0, a, 0) })
		task.delay(0.45, function()
			tween(sp, 0.18, { CFrame = CFrame.lookAt(at + V(0, 7, 0), g) * CFrame.Angles(math.rad(-60), 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.2, function()
				fadeOut(sp, 0.3)
			end)
		end)
	end
	task.delay(0.65, function()
		Fx.blast(g + V(0, 2, 0), c, c2, 1.8)
		Fx.ring(g + V(0, 0.5, 0), c, 4, r * 2.4, 0.6)
		Fx.debris(g, 10, 24, c)
		Fx.flash(g + V(0, 6, 0), c, r * 2, 4, 0.4)
		shake(1.2)
	end)
end

------------------------------------------------------------------------
-- 혼돈개천권
------------------------------------------------------------------------
VFX.voidOrb = function(d, c)
	local at = d.at + V(0, 3, 0)
	local r = d.radius or 10
	local orb = piece(V(1, 1, 1), CF(at), Color3.fromRGB(14, 6, 26), 0, Enum.PartType.Ball)
	orb.Material = Enum.Material.Glass
	local rim = piece(V(1.4, 1.4, 1.4), CF(at), c, 0.4, Enum.PartType.Ball)
	tween(orb, 0.3, { Size = V(6, 6, 6) })
	tween(rim, 0.3, { Size = V(7.4, 7.4, 7.4) })
	-- 둘레에서 빛 조각이 빨려 든다
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local m = piece(V(0.6, 0.6, 0.6), CF(at + V(math.cos(a) * r, (math.random() - 0.5) * 4, math.sin(a) * r)), c, 0)
		tween(m, 0.35, { Position = at, Size = V(0.1, 0.1, 0.1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Debris:AddItem(m, 0.4)
	end
	task.delay(0.42, function()
		fadeOut(orb, 0.2, V(0.5, 0.5, 0.5))
		fadeOut(rim, 0.2, V(0.5, 0.5, 0.5))
	end)
end
VFX.implode = function(d, c, c2)
	local at = d.at + V(0, 3, 0)
	local shell = piece(V(14, 14, 14), CF(at), c, 0.5, Enum.PartType.Ball)
	tween(shell, 0.18, { Size = V(1, 1, 1), Transparency = 0.1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.2, function()
		shell:Destroy()
		local burst = piece(V(2, 2, 2), CF(at), c2, 0, Enum.PartType.Ball)
		fadeOut(burst, 0.45, V(22, 22, 22))
		Fx.ring(at, c, 2, 26, 0.45)
		Fx.flash(at, c2, 30, 5, 0.3)
		shake(0.6)
	end)
end
VFX.starCrack = function(d, c)
	local g = ground(d.at) + V(0, 0.25, 0)
	local r = d.radius or 10
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2 + math.random() * 0.2
		local tip = g + V(math.cos(a) * r * 1.3, 0, math.sin(a) * r * 1.3)
		local line = piece(V(0.5, 0.2, 0.5), CFrame.lookAt(g, tip), c, 0)
		tween(line, 0.15, { Size = V(0.5, 0.2, r * 2.6) })
		task.delay(0.6, function()
			fadeOut(line, 0.4)
		end)
	end
	local glow = disc(g, r * 0.3, c, 0.3, 0.6, r)
	glow.Material = Enum.Material.Neon
	shake(0.4)
end
VFX.rift = function(d, c, c2)
	local from, dir = d.from :: Vector3, d.dir :: Vector3
	local len = d.length or 30
	local mid = from + dir * len / 2 + V(0, 3, 0)
	local slit = piece(V(0.2, 7, 1), CFrame.lookAt(mid, mid + dir), WHITE, 0)
	tween(slit, 0.1, { Size = V(0.4, 7, len) })
	local dark = piece(V(0.1, 6, len * 0.9), CFrame.lookAt(mid, mid + dir), Color3.fromRGB(10, 4, 20), 0.1)
	tween(dark, 0.25, { Size = V(3, 6, len * 0.9) })
	task.delay(0.3, function()
		fadeOut(slit, 0.3, V(0.05, 7, len))
		fadeOut(dark, 0.3, V(0.05, 6, len * 0.9))
		Fx.burst("glitter", mid, c2, 14, 1.4)
	end)
	Fx.flash(mid, c, 26, 3, 0.3)
end
VFX.shatter = function(d, c, c2)
	local at = d.at + V(0, 2.5, 0)
	local r = d.radius or 7
	-- 유리 상자가 둘러쌌다가 조각나 흩어진다
	local box = piece(V(r * 1.4, r * 1.2, r * 1.4), CF(at), c2, 0.75)
	box.Material = Enum.Material.Glass
	task.delay(0.15, function()
		box:Destroy()
		for _ = 1, 12 do
			local shard = piece(V(0.3, math.random() * 1.6 + 0.6, math.random() * 1.2 + 0.4), CF(at) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6), math.random() < 0.5 and c or c2, 0.1)
			local fly = V(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit * (r + math.random() * 6)
			tween(shard, 0.5, { Position = at + fly, Transparency = 1 })
			Debris:AddItem(shard, 0.55)
		end
		Fx.flash(at, c, 18, 3, 0.2)
	end)
end
VFX.blackhole = function(d, c)
	local at = d.at + V(0, 9, 0)
	local r = d.radius or 26
	local hole = piece(V(1, 1, 1), CF(at), Color3.fromRGB(6, 2, 12), 0, Enum.PartType.Ball)
	hole.Material = Enum.Material.Glass
	tween(hole, 0.4, { Size = V(9, 9, 9) })
	local disk = piece(V(0.2, 2, 2), CF(at) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(0.3, 0, 0), c, 0.3, Enum.PartType.Cylinder)
	tween(disk, 0.4, { Size = V(0.2, 22, 22) })
	disc(ground(d.at) + V(0, 0.3, 0), r, Color3.fromRGB(20, 8, 40), 0.5, 1.8)
	task.delay(1.6, function()
		fadeOut(hole, 0.3, V(1, 1, 1))
		fadeOut(disk, 0.3)
	end)
	shake(0.5)
end
VFX.voidPulse = function(d, c)
	local g = ground(d.at)
	local r = d.radius or 24
	local ring = piece(V(1.2, r * 2, r * 2), CF(g + V(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), c, 0.3, Enum.PartType.Cylinder)
	tween(ring, 0.35, { Size = V(0.4, 2, 2), Transparency = 0.8 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Debris:AddItem(ring, 0.4)
	shake(0.3)
end
VFX.genesis = function(d, c, c2)
	local g = ground(d.at)
	local r = d.radius or 28
	local core = piece(V(2, 2, 2), CF(g + V(0, 6, 0)), WHITE, 0, Enum.PartType.Ball)
	fadeOut(core, 0.8, V(r * 2.2, r * 2.2, r * 2.2))
	local pillar = piece(V(400, 6, 6), CF(g + V(0, 200, 0)) * CFrame.Angles(0, 0, math.rad(90)), c2, 0.1, Enum.PartType.Cylinder)
	fadeOut(pillar, 0.9, V(400, 30, 30))
	for k = 0, 2 do
		Fx.ring(g + V(0, 0.5 + k * 2, 0), k == 1 and c2 or c, 4, r * (2.2 + k * 0.4), 0.6 + k * 0.15)
	end
	Fx.debris(g, 12, 30, c)
	Fx.flash(g + V(0, 8, 0), WHITE, r * 2.5, 6, 0.6)
	shake(1.5)
end

------------------------------------------------------------------------
-- 혼돈개천권 (무극신권의 끝): 음양 구슬 · 먹의 천마 · 먹 튀김 · 태극
------------------------------------------------------------------------
local INK = Color3.fromRGB(16, 16, 20)
local PAPER = Color3.fromRGB(248, 248, 252)
local INKGOLD = Color3.fromRGB(255, 210, 110)

VFX.yinyang = function(d)
	local at = d.at + V(0, 3, 0)
	local from = (d.from :: Vector3) + V(0, 3, 0)
	local orbs = {}
	for k = 0, 1 do
		local o = piece(V(2.4, 2.4, 2.4), CF(from), k == 0 and INK or PAPER, 0, Enum.PartType.Ball)
		if k == 0 then
			o.Material = Enum.Material.Glass
		end
		table.insert(orbs, o)
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - t0) / 0.42, 0, 1)
		local c = from:Lerp(at, t)
		local r = 3 * (1 - t) + 0.4
		for k, o in ipairs(orbs) do
			local a = t * math.pi * 5 + k * math.pi
			o.CFrame = CF(c + V(math.cos(a) * r, math.sin(a * 0.5) * 0.6, math.sin(a) * r))
		end
		if t >= 1 then
			conn:Disconnect()
			for _, o in ipairs(orbs) do
				fadeOut(o, 0.2, V(0.4, 0.4, 0.4))
			end
		end
	end)
	-- 둘레에서 먹 방울이 빨려 든다
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local m = piece(V(0.7, 0.7, 0.7), CF(at + V(math.cos(a) * (d.radius or 10), (math.random() - 0.5) * 3, math.sin(a) * (d.radius or 10))), k % 2 == 0 and INK or PAPER, 0, Enum.PartType.Ball)
		tween(m, 0.45, { Position = at, Size = V(0.1, 0.1, 0.1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Debris:AddItem(m, 0.5)
	end
end

-- 먹의 천마: 탄 사람 아래 (big = 하늘만 한 말이 머리 위 뒤에서 함께 내달린다)
local function ell(size: Vector3, color: Color3, mat: Enum.Material?, alpha: number?): Part
	local p = piece(size, CF(), color, alpha or 0)
	p.Material = mat or Enum.Material.SmoothPlastic
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end
VFX.inkHorse = function(d)
	local model = d.m
	local root = typeof(model) == "Instance" and model:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local big = d.big == true
	local k = big and 3.2 or 1.15
	local life = d.life or 1.2
	local parts: { { any } } = {}
	local function add(p: Part, off: CFrame, swing: number?)
		table.insert(parts, { p, off, swing or 0 })
		return p
	end
	-- 몸 · 목 · 머리 (먹), 갈기와 꼬리 (흰 빛), 금빛 눈, 다리 넷 (앞뒤로 젓는다)
	add(ell(V(2.6, 2.6, 6) * k, INK), CF(0, 0, 0))
	add(ell(V(1.5, 3, 1.6) * k, INK), CF(0, 1.6, -2.6) * CFrame.Angles(math.rad(-30), 0, 0))
	add(ell(V(1.2, 1.3, 2.6) * k, INK), CF(0, 2.9, -3.7) * CFrame.Angles(math.rad(25), 0, 0))
	for _, sx in ipairs({ -1, 1 }) do
		add(piece(V(0.3, 0.3, 0.3) * k, CF(), INKGOLD, 0, Enum.PartType.Ball), CF(sx * 0.55, 3.2, -4.0))
		add(ell(V(0.25, 0.8, 0.4) * k, INK), CF(sx * 0.35, 3.8, -3.2))
	end
	for j = 0, 5 do
		add(ell(V(0.25, 1.4, 0.7) * k, PAPER, Enum.Material.Neon, 0.1), CF(0, 2.6 - j * 0.35, -2.8 + j * 0.45) * CFrame.Angles(math.rad(-50), 0, 0))
	end
	for j = 0, 3 do
		add(ell(V(0.35, 0.35, 1.6) * k, PAPER, Enum.Material.Neon, 0.15), CF(0, 0.6 - j * 0.45, 3.4 + j * 0.9) * CFrame.Angles(math.rad(-25 - j * 10), 0, 0))
	end
	local legs = {}
	for _, lg in ipairs({ { -0.8, -2.1, 0 }, { 0.8, -2.1, math.pi }, { -0.8, 2.1, math.pi }, { 0.8, 2.1, 0 } }) do
		local p = ell(V(0.6, 3.2, 0.6) * k, INK)
		table.insert(legs, { p, CF(lg[1], -1.6, lg[2]), lg[3] })
		local hoof = piece(V(0.7, 0.4, 0.7) * k, CF(), INKGOLD, 0)
		hoof.Material = Enum.Material.Neon
		table.insert(legs, { hoof, CF(lg[1], -3.15, lg[2]), lg[3], true })
	end
	-- 몸에서 먹이 연기처럼 흩어진다
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(INK)
	smoke.Size = NumberSequence.new(2.2 * k, 4 * k)
	smoke.Transparency = NumberSequence.new(0.35, 1)
	smoke.Lifetime = NumberRange.new(0.6, 1)
	smoke.Rate = big and 60 or 30
	smoke.Speed = NumberRange.new(1, 3)
	smoke.SpreadAngle = Vector2.new(60, 60)
	smoke.Parent = parts[1][1]
	local glit = Instance.new("ParticleEmitter")
	glit.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	glit.Color = ColorSequence.new(INKGOLD)
	glit.LightEmission = 1
	glit.Size = NumberSequence.new(0.4 * k, 0)
	glit.Lifetime = NumberRange.new(0.5, 0.9)
	glit.Rate = 20
	glit.Speed = NumberRange.new(2, 5)
	glit.SpreadAngle = Vector2.new(180, 180)
	glit.Parent = parts[1][1]
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if not root.Parent or t > life then
			conn:Disconnect()
			for _, q in ipairs(parts) do
				fadeOut(q[1], 0.35)
			end
			for _, q in ipairs(legs) do
				fadeOut(q[1], 0.35)
			end
			Fx.burst("dust", root.Position, INK, 16, 1.4 * k / 1.15)
			return
		end
		local look = root.CFrame.LookVector
		local flat = V(look.X, 0, look.Z)
		flat = flat.Magnitude > 0.01 and flat.Unit or V(0, 0, -1)
		local base = big and (root.Position + V(0, 11, 0) - flat * 4) or (root.Position + V(0, -0.7, 0))
		local bob = math.sin(t * 16) * 0.25 * k
		local body = CFrame.lookAt(base, base + flat) * CF(0, bob, 0) * CFrame.Angles(math.sin(t * 16) * 0.06, 0, 0)
		local scale = k
		for _, q in ipairs(parts) do
			local off = q[2]
			q[1].CFrame = body * CF(off.Position * scale) * off.Rotation
		end
		for _, q in ipairs(legs) do
			local off = q[2]
			local sw = math.sin(t * 16 + q[3]) * 0.7
			local hip = body * CF(off.X * scale, -0.9 * scale, off.Z * scale) * CFrame.Angles(sw, 0, 0)
			if q[4] then
				q[1].CFrame = hip * CF(0, -2.25 * scale, 0)
			else
				q[1].CFrame = hip * CF(0, -0.7 * scale, 0)
			end
		end
	end)
	Fx.flash(root.Position, PAPER, 20, 2, 0.3)
end
VFX.inkSplash = function(d)
	local g = ground(d.at)
	local r = d.radius or 7
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2 + math.random() * 0.4
		local blot = ell(V(1.2, 0.6, 1.2) * (0.6 + math.random() * 0.8), INK, Enum.Material.SmoothPlastic, 0)
		blot.CFrame = CF(g + V(0, 1, 0))
		tween(blot, 0.35, { CFrame = CF(g + V(math.cos(a) * r, 0.3, math.sin(a) * r)), Size = V(2.4, 0.2, 2.4) })
		task.delay(0.6, function()
			fadeOut(blot, 0.5)
		end)
	end
	local stain = disc(g + V(0, 0.2, 0), r * 0.4, INK, 0.2, 0.9, r)
	stain.Material = Enum.Material.SmoothPlastic
	Fx.burst("spark", g + V(0, 1, 0), INKGOLD, 6, 1)
end
VFX.inkStomp = function(d)
	local g = ground(d.at)
	local r = d.radius or 13
	local wave = piece(V(1.6, 4, 4), CF(g + V(0, 0.8, 0)) * CFrame.Angles(0, 0, math.rad(90)), INK, 0.1, Enum.PartType.Cylinder)
	wave.Material = Enum.Material.SmoothPlastic
	tween(wave, 0.4, { Size = V(0.3, r * 2.2, r * 2.2), Transparency = 1 })
	Debris:AddItem(wave, 0.45)
	Fx.ring(g + V(0, 0.6, 0), INKGOLD, 3, r * 2, 0.45)
	Fx.debris(g, 6, 18, INK)
	Fx.flash(g + V(0, 3, 0), INKGOLD, 24, 3, 0.3)
	shake(0.7)
end
-- 땅에 그려지는 태극 (흑백 반원 둘 + 작은 눈 둘). 돌다가 사라진다
VFX.taiji = function(d)
	local g = ground(d.at) + V(0, 0.25, 0)
	local r = d.radius or 26
	local life = d.life or 1.8
	local plate = disc(g, r, PAPER, 0.15, life + 0.4)
	plate.Material = Enum.Material.SmoothPlastic
	-- 흑과 백의 큰 원 둘이 서로를 쫓으며 돌고, 그 안에 반대 빛깔의 눈이 박힌다
	local blackBig = piece(V(0.3, r, r), CF(), INK, 0.05, Enum.PartType.Cylinder)
	local whiteDot = piece(V(0.32, r * 0.25, r * 0.25), CF(), PAPER, 0, Enum.PartType.Cylinder)
	local blackDot = piece(V(0.32, r * 0.25, r * 0.25), CF(), INK, 0, Enum.PartType.Cylinder)
	local whiteBig = piece(V(0.31, r, r), CF(), PAPER, 0.05, Enum.PartType.Cylinder)
	local rim = piece(V(0.35, r * 2.05, r * 2.05), CF(g - V(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), INKGOLD, 0.3, Enum.PartType.Cylinder)
	local halves = { blackBig, whiteBig, whiteDot, blackDot }
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > life then
			conn:Disconnect()
			for _, p in ipairs(halves) do
				fadeOut(p, 0.4)
			end
			fadeOut(rim, 0.4)
			return
		end
		local a = t * 2.4
		local ax, az = math.cos(a) * r * 0.5, math.sin(a) * r * 0.5
		local lay = CFrame.Angles(0, 0, math.rad(90))
		blackBig.CFrame = CF(g + V(ax, 0.06, az)) * lay
		whiteBig.CFrame = CF(g + V(-ax, 0.07, -az)) * lay
		whiteDot.CFrame = CF(g + V(ax, 0.1, az)) * lay
		blackDot.CFrame = CF(g + V(-ax, 0.11, -az)) * lay
	end)
	if opts.shake then
		shake(0.4)
	end
end

------------------------------------------------------------------------
-- 3.99.31판 비급 권법: 잔월검장 (초승달) · 뇌운비보 (먹구름 · 벼락 지붕) · 귀화백골장 (귀화 · 백골의 손 · 저승 원)
------------------------------------------------------------------------
-- 초승달 칼날: 반쯤 겹친 두 원판 대신 휘어진 빛 조각 일곱으로 활을 그린다
local function crescentAt(cf: CFrame, r: number, c: Color3, life: number)
	for k = -3, 3 do
		local a = k * 0.32
		local seg = piece(V(0.45, 0.25, r * 0.38), cf * CFrame.Angles(0, a, 0) * CF(0, 0, -r) * CFrame.Angles(0, math.pi / 2, 0), c, math.abs(k) * 0.08)
		fadeOut(seg, life, V(0.1, 0.1, r * 0.38))
	end
end
VFX.crescent = function(d, c)
	local from, dir = d.from :: Vector3, d.dir :: Vector3
	local len = d.length or 8
	local n = d.length and 6 or 1
	for i = 1, n do
		task.delay(i * 0.03, function()
			local at = from + dir * (d.length and (len * i / n) or 2) + V(0, 2.4, 0)
			crescentAt(CFrame.lookAt(at, at + dir) * CF(0, 0, 2.5), 2.6, c, 0.35)
		end)
	end
	Fx.burst("glitter", from + dir * len * 0.5 + V(0, 2, 0), c, 8, 1)
end
VFX.moonRing = function(d, c, c2)
	local g = ground(d.at)
	local r = d.radius or 13
	local ring = piece(V(0.4, 2, 2), CF(g + V(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), c, 0.1, Enum.PartType.Cylinder)
	tween(ring, 0.4, { Size = V(0.2, r * 2, r * 2), Transparency = 1 })
	Debris:AddItem(ring, 0.45)
	if d.big then
		local moon = piece(V(1, 1, 1), CF(g + V(0, 8, 0)), WHITE, 0.1, Enum.PartType.Ball)
		tween(moon, 0.35, { Size = V(r, r, r) })
		task.delay(0.35, function()
			fadeOut(moon, 0.35, V(r * 1.6, r * 1.6, r * 1.6))
			Fx.flash(g + V(0, 8, 0), c, r * 2, 4, 0.3)
			shake(0.8)
		end)
	end
	Fx.ring(g + V(0, 0.5, 0), c2, 2, r * 2, 0.4)
end
VFX.moonFall = function(d, c)
	local g = ground(d.at)
	local sky = g + V(0, 30, 0)
	local cf0 = CFrame.lookAt(sky, g) * CFrame.Angles(0, 0, math.random() * 6)
	local holder = piece(V(0.1, 0.1, 0.1), cf0, c, 1)
	crescentAt(cf0, 3, c, 0.5)
	tween(holder, 0.2, { CFrame = CF(g) })
	Debris:AddItem(holder, 0.25)
	task.delay(0.2, function()
		crescentAt(CF(g + V(0, 2, 0)) * CFrame.Angles(math.rad(90), 0, math.random() * 6), 3.4, c, 0.4)
		disc(g + V(0, 0.3, 0), 1, c, 0.2, 0.35, d.radius or 6)
	end)
end
VFX.cloudPuff = function(d, c)
	local g = ground(d.at)
	local r = d.radius or 10
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local puff = piece(V(3, 2.2, 3), CF(g + V(math.cos(a) * 2, 1.5, math.sin(a) * 2)), Color3.fromRGB(70, 74, 90), 0.2, Enum.PartType.Ball)
		puff.Material = Enum.Material.SmoothPlastic
		tween(puff, 0.5, { Position = g + V(math.cos(a) * r, 2.5, math.sin(a) * r), Size = V(6, 4, 6), Transparency = 1 })
		Debris:AddItem(puff, 0.55)
	end
	Fx.flash(g + V(0, 3, 0), c, r * 2, 2.5, 0.25)
end
VFX.cloudSea = function(d, c)
	local g = ground(d.at)
	local r = d.radius or 24
	local sea = piece(V(3, r * 2, r * 2), CF(g + V(0, 20, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(50, 52, 66), 0.25, Enum.PartType.Cylinder)
	sea.Material = Enum.Material.SmoothPlastic
	tween(sea, 0.4, { Size = V(6, r * 2.2, r * 2.2) })
	task.delay(1.8, function()
		fadeOut(sea, 0.5)
	end)
	for _ = 1, 6 do
		task.delay(math.random() * 1.4, function()
			Fx.flash(g + V((math.random() - 0.5) * r, 20, (math.random() - 0.5) * r), c, 30, 2, 0.15)
		end)
	end
end
VFX.thunderDome = function(d, c, c2)
	local g = ground(d.at)
	local r = d.radius or 22
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		Fx.lightning(g + V(0, 28, 0), g + V(math.cos(a) * r, 0.5, math.sin(a) * r), k % 2 == 0 and c or c2, 0.5)
	end
	local dome = piece(V(r, r, r), CF(g), c, 0.4, Enum.PartType.Ball)
	fadeOut(dome, 0.5, V(r * 2.2, r * 2.2, r * 2.2))
	Fx.flash(g + V(0, 6, 0), WHITE, r * 2.5, 5, 0.4)
	shake(1.2)
end
local function ghostFlame(at: Vector3, c: Color3, size: number, life: number)
	local core = piece(V(size, size * 1.5, size), CF(at), c, 0.1, Enum.PartType.Ball)
	local fire = Instance.new("Fire")
	fire.Color = c
	fire.SecondaryColor = Color3.fromRGB(20, 60, 40)
	fire.Size = size * 2
	fire.Heat = 8
	fire.Parent = core
	tween(core, life, { Position = at + V(0, size * 1.5, 0), Transparency = 1, Size = V(size * 0.4, size, size * 0.4) })
	Debris:AddItem(core, life + 0.3)
end
VFX.ghostFire = function(d, c)
	local at = ground(d.at) + V(0, 1.5, 0)
	local from = (d.from :: Vector3) + V(0, 3, 0)
	local orb = piece(V(1.4, 1.4, 1.4), CF(from), c, 0.1, Enum.PartType.Ball)
	tween(orb, 0.18, { Position = at })
	Debris:AddItem(orb, 0.2)
	task.delay(0.18, function()
		ghostFlame(at, c, d.big and 4 or 2.4, 0.6)
		disc(at - V(0, 1.2, 0), 1, c, 0.3, 0.4, d.radius or 5)
		if d.big then
			Fx.flash(at, c, 26, 3, 0.3)
			shake(0.5)
		end
	end)
end
local function boneHand(at: Vector3, c: Color3)
	local arm = piece(V(0.8, 0.4, 0.8), CF(at - V(0, 0.5, 0)), c, 0)
	arm.Material = Enum.Material.SmoothPlastic
	tween(arm, 0.15, { Size = V(0.8, 4, 0.8), CFrame = CF(at + V(0, 1.6, 0)) })
	for f = -2, 2 do
		local finger = piece(V(0.22, 0.2, 0.22), CF(at - V(0, 0.5, 0)), c, 0)
		finger.Material = Enum.Material.SmoothPlastic
		tween(finger, 0.18, { Size = V(0.22, 1.4, 0.22), CFrame = CF(at + V(f * 0.3, 4.1, 0)) * CFrame.Angles(0, 0, f * 0.25) })
		task.delay(0.5, function()
			fadeOut(finger, 0.3)
		end)
	end
	task.delay(0.5, function()
		fadeOut(arm, 0.3)
	end)
end
VFX.boneHands = function(d, c, c2)
	local bone = c2
	if d.length then
		local from, dir = d.from :: Vector3, d.dir :: Vector3
		for i = 1, 7 do
			task.delay(i * 0.04, function()
				local g = ground(from + dir * (d.length * i / 7))
				boneHand(g + V((math.random() - 0.5) * 2, 0, (math.random() - 0.5) * 2), bone)
			end)
		end
	else
		local g = ground(d.at)
		for k = 0, 2 do
			local a = k / 3 * math.pi * 2
			boneHand(g + V(math.cos(a) * 1.6, 0, math.sin(a) * 1.6), bone)
		end
		ghostFlame(g + V(0, 1, 0), c, 1.6, 0.5)
	end
end
VFX.ghostCircle = function(d, c)
	local g = ground(d.at) + V(0, 0.25, 0)
	local r = d.radius or 22
	local ring = piece(V(0.3, r * 2, r * 2), CF(g) * CFrame.Angles(0, 0, math.rad(90)), c, 0.55, Enum.PartType.Cylinder)
	local inner = piece(V(0.32, r * 1.6, r * 1.6), CF(g + V(0, 0.02, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(10, 20, 15), 0.3, Enum.PartType.Cylinder)
	inner.Material = Enum.Material.SmoothPlastic
	task.delay(1.6, function()
		fadeOut(ring, 0.4)
		fadeOut(inner, 0.4)
	end)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		ghostFlame(g + V(math.cos(a) * r * 0.9, 1, math.sin(a) * r * 0.9), c, 1.8, 1.4)
	end
end
VFX.skullBurst = function(d, c, c2)
	local g = ground(d.at)
	local r = d.radius or 24
	local skull = piece(V(4, 4, 4), CF(g + V(0, 8, 0)), c2, 0.1, Enum.PartType.Ball)
	skull.Material = Enum.Material.SmoothPlastic
	for _, sx in ipairs({ -1, 1 }) do
		local eye = piece(V(0.9, 0.9, 0.9), CF(g + V(sx * 0.9, 8.4, -1.8)), c, 0, Enum.PartType.Ball)
		Debris:AddItem(eye, 0.6)
	end
	tween(skull, 0.4, { Size = V(8, 8, 8) })
	task.delay(0.45, function()
		fadeOut(skull, 0.3, V(r, r, r))
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			ghostFlame(g + V(math.cos(a) * r * 0.7, 1, math.sin(a) * r * 0.7), c, 2.4, 0.8)
		end
		Fx.ring(g + V(0, 0.5, 0), c, 4, r * 2.2, 0.5)
		Fx.flash(g + V(0, 6, 0), c, r * 2.2, 5, 0.4)
		shake(1.2)
	end)
end

------------------------------------------------------------------------
function ForgeFx.init(o: any)
	opts = o or {}
end

function ForgeFx.handles(data: any): boolean
	return data.kind == "forgeStart" or data.kind == "forgeStep"
end

function ForgeFx.run(data: any)
	if data.kind == "forgeStart" then
		local st = Config.STYLE_BY_ID[data.style or ""]
		if st and typeof(data.m) == "Instance" and data.m:IsA("Model") then
			pcall(Fx.skillAura, data.m, st.color, st.color2, math.min(data.dur or 1, 3), (data.dur or 0) > 1.5)
		end
		return
	end
	local fn = VFX[data.vfx or ""]
	if not fn or typeof(data.at) ~= "Vector3" then
		return
	end
	local c, c2, pal = colorsOf(data)
	local ok, err = pcall(fn, data, c, c2, pal)
	if not ok then
		warn("[권왕] 제작소 권법 연출 오류:", data.vfx, err)
	end
end

return ForgeFx
