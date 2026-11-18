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
-- 3.99.38판 혼돈개천권 (새로): 먹 줄기 엔진. 덩어리 대신, 보이지 않는 붓끝이 쉬지 않고 휘돌며 꼬리 (Trail) 로 먹 획을 남긴다
--   획이 계속 겹치고 엉키며 형체 (말 · 용 · 소용돌이) 를 그렸다 지운다
------------------------------------------------------------------------
local INK2 = Color3.fromRGB(10, 10, 14)
local INKEDGE = Color3.fromRGB(70, 60, 90)
local BRUSH_GOLD = Color3.fromRGB(255, 205, 110)
type Brush = { p: BasePart, tr: Trail, a0: Attachment, a1: Attachment }
-- 붓끝 하나: 보이지 않는 조각 + 두 점 사이의 꼬리 (먹 획)
local function brush(width: number, life: number, color: Color3, glow: boolean?): Brush
	local p = piece(V(0.1, 0.1, 0.1), CF(), WHITE, 1)
	local a0 = Instance.new("Attachment")
	a0.Position = V(0, width / 2, 0)
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = V(0, -width / 2, 0)
	a1.Parent = p
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = life
	tr.MinLength = 0.02
	tr.FaceCamera = true
	tr.Color = glow and ColorSequence.new(color, BRUSH_GOLD) or ColorSequence.new(color, INKEDGE)
	tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, glow and 0.1 or 0), NumberSequenceKeypoint.new(0.6, glow and 0.5 or 0.25), NumberSequenceKeypoint.new(1, 1) })
	tr.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.75), NumberSequenceKeypoint.new(1, 0.1) })
	tr.LightEmission = glow and 0.8 or 0
	tr.LightInfluence = glow and 0 or 0.4
	tr.Parent = p
	return { p = p, tr = tr, a0 = a0, a1 = a1 }
end
local function dropBrush(b: Brush, after: number)
	b.tr.Enabled = false
	Debris:AddItem(b.p, after + 0.1)
end
-- 붓끝을 따라 떨어지는 먹물 방울 (내려앉으며 번진다)
local function inkDrips(parent: BasePart, rate: number, size: number)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(INK2, INKEDGE)
	e.LightInfluence = 0.3
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.4), NumberSequenceKeypoint.new(1, size) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.6, 1.1)
	e.Rate = rate
	e.Speed = NumberRange.new(0.5, 2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = V(0, -6, 0)
	e.Drag = 2
	e.Parent = parent
	return e
end
-- 먹 소용돌이: n개의 붓끝이 center() 둘레를 저마다 다른 빠르기로 휘돈다 (반지름 r(t), 높이 h)
--   opt.converge = 끝으로 갈수록 가운데로 모인다 · opt.rise = 위로 솟는다 · opt.gold = 금빛 획 몇 개
local function inkSwirl(center: () -> Vector3, n: number, r: number, h: number, life: number, opt: any?)
	local o = opt or {}
	local list = {}
	for i = 1, n do
		local gold = o.gold and i % 5 == 0
		local white = not gold and i % 7 == 3
		local b = brush((o.width or 0.7) * (white and 0.35 or 1) * (0.6 + math.random() * 0.8), o.trail or 0.55, gold and BRUSH_GOLD or (white and PAPER or INK2), gold or white)
		table.insert(list, { b = b, f1 = 1.2 + math.random() * 2.4, f2 = 1.5 + math.random() * 3, f3 = 0.9 + math.random() * 2.2, p1 = math.random() * 6.3, p2 = math.random() * 6.3, p3 = math.random() * 6.3, rk = 0.55 + math.random() * 0.6 })
	end
	local drip = o.drips and piece(V(0.1, 0.1, 0.1), CF(center()), WHITE, 1) or nil
	if drip then
		inkDrips(drip, o.drips, 1.6)
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local c = center()
		if t > life then
			conn:Disconnect()
			for _, s in ipairs(list) do
				dropBrush(s.b, o.trail or 0.55)
			end
			if drip then
				Debris:AddItem(drip, 0.05)
			end
			return
		end
		local k = t / life
		local rr = r * (o.converge and (1 - 0.85 * k * k) or 1) * (o.grow and math.min(1, t / 0.25) or 1)
		for _, s in ipairs(list) do
			local a = t * s.f1 * (o.speed or 1) + s.p1
			local x = math.cos(a) * rr * s.rk + math.sin(t * s.f3 + s.p3) * rr * 0.25
			local z = math.sin(a) * rr * s.rk + math.cos(t * s.f2 + s.p2) * rr * 0.25
			local y = math.sin(t * s.f2 + s.p2) * h * 0.5 + (o.rise and k * o.rise or 0)
			s.b.p.CFrame = CF(c + V(x, y, z)) * CFrame.Angles(t * s.f3, a, 0)
		end
		if drip then
			drip.CFrame = CF(c)
		end
	end)
end
-- 먹 획 한 줄기가 from 에서 to 로 휘몰아 날아간다 (뱀처럼 굽이치며)
local function inkStroke(from: Vector3, to: Vector3, time: number, width: number, wave: number, gold: boolean?)
	local b = brush(width, 0.5, gold and BRUSH_GOLD or INK2, gold)
	local dir = to - from
	local side = dir.Magnitude > 0.01 and dir.Unit:Cross(V(0, 1, 0)) or V(1, 0, 0)
	if side.Magnitude < 0.01 then
		side = V(1, 0, 0)
	end
	local ph = math.random() * 6.3
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min(1, (os.clock() - t0) / time)
		local p = from:Lerp(to, k) + side.Unit * math.sin(k * math.pi * 3 + ph) * wave * (1 - k) + V(0, math.sin(k * math.pi) * wave * 0.4, 0)
		b.p.CFrame = CF(p) * CFrame.Angles(k * 7, ph, 0)
		if k >= 1 then
			conn:Disconnect()
			dropBrush(b, 0.5)
		end
	end)
end
-- 먹 터짐: 획이 사방으로 튀고 먹물이 번진다
local function inkBurst(at: Vector3, r: number, big: boolean?)
	local n = big and 16 or 9
	for i = 1, n do
		local a = i / n * math.pi * 2 + math.random() * 0.3
		local to = at + V(math.cos(a) * r, (math.random() - 0.2) * r * 0.5, math.sin(a) * r)
		inkStroke(at, to, 0.22 + math.random() * 0.12, big and 1.1 or 0.7, r * 0.2, i % 6 == 0)
	end
	-- 번진 먹: 크기가 다른 먹 자국 여럿이 겹쳐 고르지 않게 번진다 (조금 오래 남는다)
	local g0 = ground(at)
	for i = 1, (big and 7 or 4) do
		local off = i == 1 and V(0, 0, 0) or V((math.random() - 0.5) * r * 1.2, 0, (math.random() - 0.5) * r * 1.2)
		local rr = (i == 1 and r * 0.8 or r * (0.15 + math.random() * 0.3))
		local blot = piece(V(0.2, 1, 1), CF(g0 + off + V(0, 0.12 + i * 0.005, 0)) * CFrame.Angles(0, 0, math.rad(90)), INK2, 0.1, Enum.PartType.Cylinder)
		blot.Material = Enum.Material.SmoothPlastic
		tween(blot, 0.2 + math.random() * 0.15, { Size = V(0.2, rr * 2, rr * 2 * (0.7 + math.random() * 0.5)) })
		task.delay(1.6 + math.random(), function()
			fadeOut(blot, 0.8)
		end)
	end
	pcall(Fx.sound, "splash", big and 0.8 or 0.45, big and 0.6 or 0.9, at)
	local holder = piece(V(0.1, 0.1, 0.1), CF(at), WHITE, 1)
	local e = inkDrips(holder, 0, big and 3 or 2)
	e.Speed = NumberRange.new(r * 0.6, r * 1.2)
	e:Emit(big and 30 or 14)
	Debris:AddItem(holder, 1.4)
	if big then
		Fx.flash(at, BRUSH_GOLD, r * 2, 3, 0.3)
	end
end

-- E 묵사박: 먹 줄기 다발이 앞으로 휘몰아쳐 감기고, 감긴 자리에서 다시 엉켰다 터진다
VFX.inkLash = function(d)
	local from = (d.from :: Vector3) + V(0, 2.5, 0)
	local dir = d.dir :: Vector3
	local len = d.length or 26
	for i = 1, 7 do
		local side = V(-dir.Z, 0, dir.X) * ((i - 4) * 0.7)
		inkStroke(from + side * 0.3, from + dir * len + side + V(0, (math.random() - 0.5) * 2, 0), 0.22 + i * 0.015, 0.8, 2.2, i == 4)
	end
end
VFX.inkBind = function(d)
	local at = d.at + V(0, 2, 0)
	inkSwirl(function()
		return at
	end, 8, d.radius or 6, 3, 0.55, { converge = true, width = 0.6, trail = 0.35 })
	task.delay(0.5, function()
		inkBurst(at, (d.radius or 6) * 1.2, d.big)
	end)
end
-- R 묵마천행: 먹 줄기가 쉬지 않고 말의 뼈대를 따라 긁고 엉키며 말을 그린다 (탄 사람 밑에서 함께 달린다)
local HORSE: { { Vector3 } } = {
	{ V(0, 0, 2.4), V(0, 0.3, -2.4) }, -- 등
	{ V(0, -0.9, 2), V(0, -0.8, -2) }, -- 배
	{ V(0, 0.3, -2.4), V(0, 2.2, -3.4) }, -- 목
	{ V(0, 2.2, -3.4), V(0, 1.4, -5) }, -- 머리
	{ V(0, 2.6, -3.1), V(0, 0.6, -2.0) }, -- 갈기
	{ V(0, 0.2, 2.4), V(0, -1.2, 4.4) }, -- 꼬리
	{ V(-0.8, -0.6, -1.9), V(-0.8, -3.3, -2.3) }, -- 앞다리
	{ V(0.8, -0.6, -1.9), V(0.8, -3.3, -1.5) },
	{ V(-0.8, -0.6, 1.9), V(-0.8, -3.3, 1.5) }, -- 뒷다리
	{ V(0.8, -0.6, 1.9), V(0.8, -3.3, 2.3) },
}
VFX.inkSteed = function(d)
	local model = d.m
	local root = typeof(model) == "Instance" and model:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local big = d.big == true
	local k = big and 3.4 or 1.25
	local life = d.life or 1.3
	local strands = {}
	for si, seg in ipairs(HORSE) do
		local per = (si == 5 or si == 6) and 3 or 4
		for j = 1, per do
			local gold = (si == 5 and j == 1) or (si == 4 and j == 1)
			table.insert(strands, { b = brush((big and 1.6 or 0.55) * (0.7 + math.random() * 0.6), big and 0.45 or 0.3, gold and BRUSH_GOLD or INK2, gold), seg = si, f = 5 + math.random() * 6, ph = math.random() * 6.3, j = math.random() * 6.3 })
		end
	end
	local holder = piece(V(0.1, 0.1, 0.1), CF(root.Position), WHITE, 1)
	inkDrips(holder, big and 60 or 26, big and 4 or 1.8)
	-- 금빛 눈 둘 (먹 속에서 타오른다)
	local eyes = {}
	for _, sx in ipairs({ -1, 1 }) do
		local e = piece(V(0.35, 0.25, 0.35) * k, CF(), BRUSH_GOLD, 0, Enum.PartType.Ball)
		table.insert(eyes, { e, sx })
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if not root.Parent or t > life then
			conn:Disconnect()
			for _, s in ipairs(strands) do
				dropBrush(s.b, 0.5)
			end
			Debris:AddItem(holder, 0.05)
			for _, e in ipairs(eyes) do
				fadeOut(e[1], 0.3)
			end
			inkBurst(root.Position - V(0, 1.5, 0), big and 14 or 7, big)
			return
		end
		local look = root.CFrame.LookVector
		local flat = V(look.X, 0, look.Z)
		flat = flat.Magnitude > 0.01 and flat.Unit or V(0, 0, -1)
		local base = big and (root.Position + V(0, 12, 0) - flat * 5) or (root.Position + V(0, -0.6, 0))
		local body = CFrame.lookAt(base, base + flat) * CF(0, math.sin(t * 16) * 0.2 * k, 0)
		holder.CFrame = body
		for _, e in ipairs(eyes) do
			e[1].CFrame = body * CF(V(e[2] * 0.45, 2.0, -4.3) * k)
		end
		local gal = t * 16
		for _, s in ipairs(strands) do
			local seg = HORSE[s.seg]
			local a, b = seg[1], seg[2]
			-- 다리는 내닫는 박자에 맞춰 앞뒤로 젓는다
			if s.seg >= 7 then
				local sw = math.sin(gal + (s.seg % 2) * math.pi + (s.seg >= 9 and 1.2 or 0)) * 1.1
				b = b + V(0, math.max(0, math.sin(gal + s.seg)) * 0.6, sw)
			end
			local u = 0.5 + 0.5 * math.sin(t * s.f + s.ph)
			local p = a:Lerp(b, u)
			local jx, jy = math.sin(t * 23 + s.j) * 0.3, math.cos(t * 19 + s.j) * 0.3
			s.b.p.CFrame = body * CF((p + V(jx, jy, 0)) * k) * CFrame.Angles(t * 3, s.j, 0)
		end
	end)
	Fx.flash(root.Position, BRUSH_GOLD, 18, 1.5, 0.3)
end
VFX.inkHoof = function(d)
	local g = ground(d.at)
	inkBurst(g + V(0, 0.5, 0), d.radius or 6, false)
	shake(0.25)
end
VFX.inkRear = function(d)
	local g = ground(d.at)
	inkSwirl(function()
		return g + V(0, 1.5, 0)
	end, 10, (d.radius or 12) * 0.4, 2, 0.35, { width = 0.9, trail = 0.3, grow = true })
	task.delay(0.3, function()
		inkBurst(g + V(0, 1, 0), d.radius or 12, true)
		Fx.ring(g + V(0, 0.5, 0), BRUSH_GOLD, 3, (d.radius or 12) * 2, 0.45)
		shake(0.7)
	end)
end
-- G 혼돈묵해: 발밑에서 먹이 엉키며 바다처럼 번지고, 먹 촉수가 세 번 솟아 감아 들인다. 끝에 모든 먹이 한 점으로 모였다 터진다
VFX.inkSea = function(d)
	local g = ground(d.at) + V(0, 0.3, 0)
	local r = d.radius or 24
	local life = d.life or 2
	-- 바닥에 번지는 먹 (낮게 깔린 소용돌이)
	inkSwirl(function()
		return g
	end, 28, r * 0.8, 0.8, life, { width = 1.6, trail = 1.1, grow = true, speed = 0.7, drips = 30, gold = true })
	local stain = piece(V(0.2, 2, 2), CF(g) * CFrame.Angles(0, 0, math.rad(90)), INK2, 0.35, Enum.PartType.Cylinder)
	stain.Material = Enum.Material.SmoothPlastic
	tween(stain, 0.5, { Size = V(0.2, r * 2, r * 2) })
	task.delay(life, function()
		fadeOut(stain, 0.5)
	end)
end
VFX.inkTendrils = function(d)
	local g = ground(d.at)
	local r = d.radius or 22
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2 + math.random() * 0.4
		local base = g + V(math.cos(a) * r * 0.85, 0, math.sin(a) * r * 0.85)
		-- 바깥에서 솟아 가운데로 휘어 들어오는 먹 촉수
		inkStroke(base, base + V(0, 9 + math.random() * 4, 0), 0.18, 1.2, 1.5, i % 4 == 0)
		task.delay(0.18, function()
			inkStroke(base + V(0, 11, 0), g + V(0, 2, 0), 0.25, 1.1, 3, false)
		end)
	end
	shake(0.35)
end
VFX.inkCore = function(d)
	local g = ground(d.at)
	local r = d.radius or 28
	local at = g + V(0, 4, 0)
	inkSwirl(function()
		return at
	end, 34, r * 0.75, 8, 0.5, { converge = true, width = 1.5, trail = 0.45, gold = true, speed = 1.8 })
	task.delay(0.42, function()
		inkBurst(at, r, true)
		inkBurst(at + V(0, 3, 0), r * 0.6, true)
		Fx.ring(g + V(0, 0.5, 0), BRUSH_GOLD, 4, r * 2.2, 0.55)
		Fx.flash(at, WHITE, r * 2.5, 5, 0.35)
		shake(1.3)
	end)
end
-- X 천지미분: 하늘을 휘감는 먹의 용 (줄기 수십 개가 한 몸으로 엉켜 굽이친다) 이 적에게 내리꽂힌다
VFX.inkDragonDive = function(d)
	local g = ground(d.at)
	local sky = g + V((math.random() - 0.5) * 40, 45, (math.random() - 0.5) * 40)
	for i = 1, 5 do
		inkStroke(sky + V((math.random() - 0.5) * 3, (math.random() - 0.5) * 3, (math.random() - 0.5) * 3), g + V(0, 1, 0), 0.24 + i * 0.012, 1.4, 6, i == 3)
	end
	task.delay(0.27, function()
		inkBurst(g + V(0, 1, 0), d.radius or 8, false)
		shake(0.3)
	end)
end
VFX.inkHeaven = function(d)
	local g = ground(d.at)
	local r = d.radius or 40
	inkSwirl(function()
		return g + V(0, 14, 0)
	end, 40, r * 0.85, 22, d.life or 2.2, { width = 2.4, trail = 1.3, speed = 0.55, gold = true, drips = 45 })
end

------------------------------------------------------------------------
function ForgeFx.init(o: any)
	opts = o or {}
end

-- 3.99.38판 손맛: 혼돈개천권은 맞힐 때마다 먹이 튄다 (강타 · 기술은 크게)
function ForgeFx.hit(styleId: string, pos: Vector3, heavy: boolean, skill: boolean)
	if styleId == "hondon" then
		local n = (heavy or skill) and 6 or 3
		for _ = 1, n do
			local a = math.random() * math.pi * 2
			inkStroke(pos, pos + V(math.cos(a) * 5, (math.random() - 0.3) * 3, math.sin(a) * 5), 0.14, (heavy or skill) and 0.8 or 0.5, 1, false)
		end
		if heavy or skill then
			inkBurst(pos, 5, false)
		end
	end
end

-- 3.99.39판: 혼돈개천권 오의 · 초 오의가 가까이서 터지면 세상의 빛깔이 빠지고 화면 가장자리에 먹이 번진다
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local function inkScreen(dur: number)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "KwonInkWorld"
	cc.Saturation = 0
	cc.Contrast = 0
	cc.Parent = Lighting
	tween(cc, 0.35, { Saturation = -0.95, Contrast = 0.35, TintColor = Color3.fromRGB(235, 228, 215) })
	task.delay(dur, function()
		tween(cc, 0.6, { Saturation = 0, Contrast = 0, TintColor = WHITE })
		Debris:AddItem(cc, 0.7)
	end)
	local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return
	end
	local sg = Instance.new("ScreenGui")
	sg.Name = "KwonInkVignette"
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 5
	sg.Parent = pg
	-- 네 가장자리에서 먹이 안으로 번진다 (가운데로 갈수록 옅다)
	for i, spec in ipairs({ { UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0.22, 0), 90 }, { UDim2.new(0, 0, 0.78, 0), UDim2.new(1, 0, 0.22, 0), -90 }, { UDim2.new(0, 0, 0, 0), UDim2.new(0.16, 0, 1, 0), 0 }, { UDim2.new(0.84, 0, 0, 0), UDim2.new(0.16, 0, 1, 0), 180 } }) do
		local f = Instance.new("Frame")
		f.Position = spec[1]
		f.Size = spec[2]
		f.BackgroundColor3 = INK2
		f.BorderSizePixel = 0
		f.BackgroundTransparency = 1
		local gr = Instance.new("UIGradient")
		gr.Rotation = spec[3]
		gr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		gr.Parent = f
		f.Parent = sg
		tween(f, 0.3 + i * 0.05, { BackgroundTransparency = 0.15 })
	end
	task.delay(dur, function()
		for _, f in ipairs(sg:GetChildren()) do
			if f:IsA("Frame") then
				tween(f, 0.5, { BackgroundTransparency = 1 })
			end
		end
		Debris:AddItem(sg, 0.6)
	end)
end
-- 하늘에 크게 쓰이는 붓글씨 (초 오의)
local function calligraphy(at: Vector3, text: string, life: number)
	local anchor = piece(V(0.1, 0.1, 0.1), CF(at), WHITE, 1)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(28, 14)
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.MaxDistance = 400
	bb.Parent = anchor
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.Antique
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = INK2
	l.TextStrokeColor3 = BRUSH_GOLD
	l.TextStrokeTransparency = 0.2
	l.TextTransparency = 1
	l.Parent = bb
	tween(l, 0.5, { TextTransparency = 0 })
	task.delay(life, function()
		tween(l, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
		Debris:AddItem(anchor, 0.6)
	end)
end

function ForgeFx.handles(data: any): boolean
	return data.kind == "forgeStart" or data.kind == "forgeStep"
end

function ForgeFx.run(data: any)
	if data.kind == "forgeStart" and data.style == "hondon" and (data.mid == "hdG" or data.mid == "hdX") and typeof(data.m) == "Instance" then
		local r0 = data.m:FindFirstChild("HumanoidRootPart")
		local cam = workspace.CurrentCamera
		if r0 and r0:IsA("BasePart") and cam and (cam.CFrame.Position - r0.Position).Magnitude < 120 then
			inkScreen(math.min(data.dur or 2, 3.4))
			shake(0.6)
		end
		if r0 and r0:IsA("BasePart") and data.mid == "hdX" then
			calligraphy(r0.Position + V(0, 34, 0), "混沌", 3.2)
		end
	end
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
