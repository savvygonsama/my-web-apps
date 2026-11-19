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
-- 그 자리 발밑 땅의 높이 (사람 · 연출은 빼고 아래로 길게 쏜다. 못 찾으면 몸 높이로 어림)
local groundCache: { [Model]: { number } } = {}
local function groundY(at: Vector3, ignore: Instance?): number
	local key = ignore :: any
	local c = key and groundCache[key]
	local now = os.clock()
	if c and now - c[2] < 0.1 and math.abs(c[3] - at.X) + math.abs(c[4] - at.Z) < 2 then
		return c[1]
	end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local list = { folder }
	if ignore then
		table.insert(list, ignore)
	end
	local chars = workspace:FindFirstChild("Enemies")
	if chars then
		table.insert(list, chars)
	end
	for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
		if pl.Character then
			table.insert(list, pl.Character)
		end
	end
	rp.FilterDescendantsInstances = list
	local r = workspace:Raycast(at + V(0, 4, 0), V(0, -120, 0), rp)
	local y = r and r.Position.Y or (at.Y - 3)
	if key then
		groundCache[key] = { y, now, at.X, at.Z }
	end
	return y
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
			local x = math.cos(a) * rr * s.rk + math.sin(t * s.f3 * 0.6 + s.p3) * rr * 0.12
			local z = math.sin(a) * rr * s.rk + math.cos(t * s.f2 * 0.6 + s.p2) * rr * 0.12
			local y = math.sin(t * s.f2 * 0.7 + s.p2) * h * 0.5 + (o.rise and k * o.rise or 0)
			s.b.p.CFrame = CF(c + V(x, y, z)) * CFrame.Angles(0, a, 0)
		end
		if drip then
			drip.CFrame = CF(c)
		end
	end)
end
-- 먹 획 한 줄기가 from 에서 to 로 휘몰아 날아간다 (뱀처럼 굽이치며)
local function inkStroke(from: Vector3, to: Vector3, time: number, width: number, wave: number, gold: boolean?)
	-- 3.99.42판: 붓질처럼 (지그재그 대신 한 번 크게 휘는 곡선, 처음엔 빠르고 끝에서 느려지며 가늘어진다)
	local b = brush(width, 0.6, gold and BRUSH_GOLD or INK2, gold)
	local dir = to - from
	local side = dir.Magnitude > 0.01 and dir.Unit:Cross(V(0, 1, 0)) or V(1, 0, 0)
	if side.Magnitude < 0.01 then
		side = V(1, 0, 0)
	end
	local ctrl = from:Lerp(to, 0.45) + side.Unit * (math.random() - 0.5) * 2 * wave + V(0, wave * (0.3 + math.random() * 0.5), 0)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min(1, (os.clock() - t0) / time)
		local e = 1 - (1 - k) * (1 - k)
		local p = from:Lerp(ctrl, e):Lerp(ctrl:Lerp(to, e), e)
		b.p.CFrame = CF(p) * CFrame.Angles(0, math.atan2(dir.X, dir.Z), 0)
		b.a0.Position = V(0, width / 2 * (1 - k * 0.6), 0)
		b.a1.Position = V(0, -width / 2 * (1 - k * 0.6), 0)
		if k >= 1 then
			conn:Disconnect()
			dropBrush(b, 0.6)
		end
	end)
end
-- 먹 터짐: 획이 사방으로 튀고 먹물이 번진다
local function inkBurst(at: Vector3, r: number, big: boolean?)
	local n = big and 24 or 12
	for i = 1, n do
		local a = i / n * math.pi * 2 + math.random() * 0.3
		local to = at + V(math.cos(a) * r, (math.random() - 0.2) * r * 0.5, math.sin(a) * r)
		inkStroke(at, to, 0.22 + math.random() * 0.12, big and 1.8 or 1.0, r * 0.25, i % 6 == 0)
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
	for i = 1, 11 do
		local side = V(-dir.Z, 0, dir.X) * ((i - 6) * 0.9)
		inkStroke(from + side * 0.3, from + dir * (len + 4) + side + V(0, (math.random() - 0.5) * 4, 0), 0.22 + i * 0.012, 1.5, 3.5, i == 6 or i == 3)
	end
	Fx.flash(from + dir * len * 0.5, BRUSH_GOLD, 26, 1.5, 0.2)
end
VFX.inkBind = function(d)
	local at = d.at + V(0, 2, 0)
	inkSwirl(function()
		return at
	end, 12, (d.radius or 6) * 1.4, 5, 0.55, { converge = true, width = 1.0, trail = 0.4, gold = true })
	task.delay(0.5, function()
		inkBurst(at, (d.radius or 6) * 1.7, d.big)
	end)
end
-- 3.99.42판 빔 뼈대: 꼬리 (Trail) 는 빨리 달리면 뒤로 번져 형체가 사라졌다. 몸에 붙은 형체는 빔 (Beam) 으로 그린다
--   뼈마다 빔 셋, 굽은 정도 (CurveSize) 가 쉬지 않고 출렁여 먹 획이 엉키듯 흐른다. 빔은 그 순간의 자리에만 그려져 번지지 않는다
local worldAnchor: BasePart? = nil
local function anchorPart(): BasePart
	if not worldAnchor or not worldAnchor.Parent then
		local p = Instance.new("Part")
		p.Name = "BeamAnchor"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = V(0.1, 0.1, 0.1)
		p.CFrame = CFrame.identity
		p.Parent = folder
		worldAnchor = p
	end
	return worldAnchor :: BasePart
end
type BeamSeg = { a0: Attachment, a1: Attachment, beam: Beam, w0: number, w1: number, f: number, ph: number, amp: number }
local function beamSeg(c1: Color3, c2: Color3, w0: number, w1: number, glow: boolean, amp: number): BeamSeg
	local ap = anchorPart()
	local a0 = Instance.new("Attachment")
	a0.Parent = ap
	local a1 = Instance.new("Attachment")
	a1.Parent = ap
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Color = ColorSequence.new(c1, c2)
	b.Width0 = w0
	b.Width1 = w1
	b.Segments = 14
	b.FaceCamera = true
	b.LightEmission = glow and 1 or 0
	b.LightInfluence = glow and 0 or 0.35
	b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.15) })
	b.Parent = ap
	return { a0 = a0, a1 = a1, beam = b, w0 = w0, w1 = w1, f = 3 + math.random() * 5, ph = math.random() * 6.3, amp = amp }
end
local function killBeam(b: BeamSeg, fade: number)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min(1, (os.clock() - t0) / fade)
		b.beam.Transparency = NumberSequence.new(k)
		b.beam.Width0 = b.w0 * (1 - k * 0.6)
		b.beam.Width1 = b.w1 * (1 - k * 0.6)
		if k >= 1 then
			conn:Disconnect()
			b.beam:Destroy()
			b.a0:Destroy()
			b.a1:Destroy()
		end
	end)
end
-- 뼈대 짐승을 빔으로 그린다. place(t) → 몸 CFrame (nil 이면 끝), legs = 다리 뼈 번호 (박자에 맞춰 젓는다)
-- opt: per (뼈마다 빔 수), w (굵기), gold (금빛 빔 뼈 번호들), form (처음에 사방에서 모여든다 · 그 자리), amp (출렁임)
local function beamBeast(bones: { { Vector3 } }, place: (number) -> CFrame?, life: number, k: number, c1: Color3, c2: Color3, opt: any?): () -> ()
	local o = opt or {}
	local segs = {}
	for si in ipairs(bones) do
		for j = 1, o.per or 3 do
			local gold = o.gold and table.find(o.gold, si) ~= nil and j == 1
			local w = (o.w or 0.55) * k * (0.6 + math.random() * 0.7)
			local b = beamSeg(gold and (o.goldColor or BRUSH_GOLD) or c1, gold and WHITE or c2, w, w * (0.3 + math.random() * 0.5), gold or o.glow == true, (o.amp or 0.9) * k)
			table.insert(segs, { b = b, si = si, j = j, jit = V(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.35 })
		end
	end
	local t0 = os.clock()
	local done = false
	local conn
	local function finish()
		if done then
			return
		end
		done = true
		conn:Disconnect()
		for _, sg in ipairs(segs) do
			killBeam(sg.b, 0.35)
		end
	end
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local body = place(t)
		if not body or t > life then
			finish()
			return
		end
		for _, sg in ipairs(segs) do
			local bone = bones[sg.si]
			local a, b = bone[1], bone[2]
			if o.legs and table.find(o.legs, sg.si) then
				local sw = math.sin(t * (o.gallop or 16) + sg.si * 1.7) * 1.1
				b = b + V(0, math.max(0, math.sin(t * (o.gallop or 16) + sg.si)) * 0.6, sw)
			end
			local wob = V(math.sin(t * 9 + sg.j * 2 + sg.si), math.cos(t * 7 + sg.j * 3), 0) * 0.18
			local pa = body * ((a + sg.jit + wob) * k)
			local pb = body * ((b - sg.jit + wob) * k)
			if o.form and t < o.form then
				sg.fa = sg.fa or (body.Position + V((math.random() - 0.5) * 140, 30 + math.random() * 40, (math.random() - 0.5) * 140))
				sg.fb = sg.fb or (sg.fa + V((math.random() - 0.5) * 20, (math.random() - 0.5) * 20, (math.random() - 0.5) * 20))
				local q = t / o.form
				q = q * q * (3 - 2 * q)
				pa = sg.fa:Lerp(pa, q)
				pb = sg.fb:Lerp(pb, q)
			end
			sg.b.a0.Position = pa
			sg.b.a1.Position = pb
			sg.b.beam.CurveSize0 = math.sin(t * sg.b.f + sg.b.ph) * sg.b.amp
			sg.b.beam.CurveSize1 = math.cos(t * sg.b.f * 0.8 + sg.b.ph) * sg.b.amp
		end
	end)
	return finish
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
	local k = big and 6.5 or 1.8 -- 3.99.52판: 5 → 6.5 (산만 한 천마)
	local life = d.life or 1.3
	local rootP = root :: BasePart
	local function bodyAt(t: number): CFrame?
		if not rootP.Parent then
			return nil
		end
		local look = rootP.CFrame.LookVector
		local flat = V(look.X, 0, look.Z)
		flat = flat.Magnitude > 0.01 and flat.Unit or V(0, 0, -1)
		-- 3.99.45판: 말은 늘 발밑 땅을 딛는다 (예전엔 몸 높이로 어림해 땅 아래로 꺼졌다). 다리 끝 = 몸 아래 3.3 × k
		local base
		local gy = groundY(rootP.Position, model)
		if big and not d.ride then
			base = rootP.Position + V(0, 18, 0) - flat * 8
		else
			base = V(rootP.Position.X, gy + 3.25 * k, rootP.Position.Z) + (d.ride and flat * 0.8 * k or V(0, 0, 0))
		end
		return CFrame.lookAt(base, base + flat) * CF(0, math.sin(t * 16) * 0.2 * k, 0)
	end
	-- 먹 획 빔 (뼈마다 셋, 갈기 · 머리는 금빛 하나)
	beamBeast(HORSE, bodyAt, life, k, INK2, INKEDGE, { per = 5, w = 0.7, gold = { 4, 5 }, legs = { 7, 8, 9, 10 }, form = d.form and 0.6 or nil, amp = 1.6 })
	-- 3.99.46판: 몸통을 가로지르며 엉킨 먹 획 열여덟 (뼈대 아무 두 점을 잇는 줄이 쉬지 않고 휘청인다)
	local tangle: { { Vector3 } } = {}
	for _ = 1, 18 do
		local b1, b2 = HORSE[math.random(1, 6)], HORSE[math.random(1, #HORSE)]
		table.insert(tangle, { b1[1]:Lerp(b1[2], math.random()), b2[1]:Lerp(b2[2], math.random()) })
	end
	beamBeast(tangle, bodyAt, life, k, INK2, INKEDGE, { per = 1, w = 0.45, gold = { 3, 11 }, form = d.form and 0.6 or nil, amp = 2.4 })
	-- 몸 둘레를 휘도는 먹 줄기 (꼬리는 짧게: 달려도 번지지 않게)
	inkSwirl(function()
		local b = bodyAt(os.clock())
		return b and b.Position or rootP.Position
	end, big and 14 or 8, 2.6 * k, 1.5 * k, life, { width = 0.5 * k, trail = 0.12, speed = 2.6, gold = true })
	local holder = piece(V(0.1, 0.1, 0.1), CF(rootP.Position), WHITE, 1)
	inkDrips(holder, big and 60 or 26, big and 4 or 1.8)
	local eyes = {}
	for _, sx in ipairs({ -1, 1 }) do
		table.insert(eyes, { piece(V(0.35, 0.25, 0.35) * k, CF(), BRUSH_GOLD, 0, Enum.PartType.Ball), sx })
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local body = bodyAt(t)
		if not body or t > life then
			conn:Disconnect()
			Debris:AddItem(holder, 0.05)
			for _, e in ipairs(eyes) do
				fadeOut(e[1], 0.3)
			end
			inkBurst(rootP.Position - V(0, 1.5, 0), big and 22 or 11, big)
			return
		end
		holder.CFrame = body
		for _, e in ipairs(eyes) do
			e[1].CFrame = body * CF(V(e[2] * 0.45, 2.0, -4.3) * k)
		end
	end)
	Fx.flash(rootP.Position, BRUSH_GOLD, 18, 1.5, 0.3)
end
VFX.inkHoof = function(d)
	local g = ground(d.at)
	inkBurst(g + V(0, 0.5, 0), (d.radius or 6) * 1.5, false)
	shake(0.35)
end
VFX.inkRear = function(d)
	local g = ground(d.at)
	inkSwirl(function()
		return g + V(0, 1.5, 0)
	end, 16, (d.radius or 12) * 0.6, 4, 0.35, { width = 1.4, trail = 0.35, grow = true, gold = true })
	task.delay(0.3, function()
		inkBurst(g + V(0, 1, 0), (d.radius or 12) * 1.4, true)
		Fx.ring(g + V(0, 0.5, 0), BRUSH_GOLD, 3, (d.radius or 12) * 2.8, 0.5)
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
	end, 36, r * 1.05, 1.4, life, { width = 2.4, trail = 1.2, grow = true, speed = 0.7, drips = 40, gold = true })
	local stain = piece(V(0.2, 2, 2), CF(g) * CFrame.Angles(0, 0, math.rad(90)), INK2, 0.35, Enum.PartType.Cylinder)
	stain.Material = Enum.Material.SmoothPlastic
	tween(stain, 0.5, { Size = V(0.2, r * 2.4, r * 2.4) })
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
		inkStroke(base, base + V(0, 16 + math.random() * 6, 0), 0.18, 2.2, 2.5, i % 4 == 0)
		task.delay(0.18, function()
			inkStroke(base + V(0, 19, 0), g + V(0, 2, 0), 0.25, 2, 5, false)
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
	end, 40, r * 1.0, 12, 0.5, { converge = true, width = 2.2, trail = 0.5, gold = true, speed = 1.8 })
	task.delay(0.42, function()
		inkBurst(at, r * 1.3, true)
		inkBurst(at + V(0, 5, 0), r * 0.8, true)
		Fx.ring(g + V(0, 0.5, 0), BRUSH_GOLD, 4, r * 2.8, 0.6)
		Fx.ring(g + V(0, 6, 0), PAPER, 4, r * 2.2, 0.5)
		Fx.flash(at, WHITE, r * 2.5, 5, 0.35)
		-- 3.99.52판: 터진 자리에서 먹 기둥이 하늘까지 꼬여 오른다
		inkSwirl(function()
			return g + V(0, 2, 0)
		end, 22, 6, 6, 1.1, { width = 2.6, trail = 0.9, speed = 2.2, rise = 80, gold = true })
		shake(1.6)
	end)
end
-- X 천지미분: 하늘을 휘감는 먹의 용 (줄기 수십 개가 한 몸으로 엉켜 굽이친다) 이 적에게 내리꽂힌다
VFX.inkDragonDive = function(d)
	local g = ground(d.at)
	local sky = g + V((math.random() - 0.5) * 80, 110, (math.random() - 0.5) * 80)
	for i = 1, 14 do
		inkStroke(sky + V((math.random() - 0.5) * 7, (math.random() - 0.5) * 7, (math.random() - 0.5) * 7), g + V(0, 1, 0), 0.24 + i * 0.01, i % 5 == 0 and 3.4 or 2.4, 14, i == 5 or i == 2 or i == 11)
	end
	task.delay(0.3, function()
		inkBurst(g + V(0, 1, 0), (d.radius or 8) * 1.8, true)
		-- 내리꽂힌 자리에 금빛으로 갈라진 땅 (번개처럼 꺾이며 뻗는다)
		for j = 1, 5 do
			local a = j / 5 * math.pi * 2 + math.random() * 0.5
			local p0 = g + V(0, 0.3, 0)
			for _ = 1, 3 do
				local p1 = p0 + V(math.cos(a) * 4, 0, math.sin(a) * 4)
				a += (math.random() - 0.5) * 1.2
				local seg = piece(V(0.35, 0.12, (p1 - p0).Magnitude), CFrame.lookAt((p0 + p1) / 2, p1), BRUSH_GOLD, 0)
				seg.Material = Enum.Material.Neon
				task.delay(0.9, function()
					fadeOut(seg, 0.5)
				end)
				p0 = p1
			end
		end
		shake(0.5)
	end)
end
VFX.inkHeaven = function(d)
	local g = ground(d.at)
	local r = d.radius or 40
	inkSwirl(function()
		return g + V(0, 14, 0)
	end, 48, r * 1.15, 34, d.life or 2.2, { width = 3.2, trail = 1.4, speed = 0.55, gold = true, drips = 60 })
	-- 3.99.52판: 하늘을 덮는 먹구름 (높이 70 에서 넓게 휘도는 두꺼운 획) 과 그 아래로 내리는 먹비
	inkSwirl(function()
		return g + V(0, 72, 0)
	end, 40, r * 2.2, 8, d.life or 2.2, { width = 6, trail = 2, speed = 0.3, drips = 120 })
	local rain = piece(V(r * 3, 1, r * 3), CF(g + V(0, 70, 0)), WHITE, 1)
	local e = inkDrips(rain, 0, 2.4)
	e.Rate = 120
	e.Speed = NumberRange.new(40, 60)
	e.EmissionDirection = Enum.NormalId.Bottom
	task.delay(d.life or 2.2, function()
		e.Enabled = false
		Debris:AddItem(rain, 2)
	end)
end

------------------------------------------------------------------------
function ForgeFx.init(o: any)
	opts = o or {}
end

------------------------------------------------------------------------
-- 3.99.41판 빛 줄기 도구 (먹 줄기 엔진을 빛깔마다): 붓끝 · 휘몰아치는 획 · 소용돌이 · 뱀 · 짐승 뼈대
------------------------------------------------------------------------
local calligraphy: (Vector3, string, number) -> ()
local TEX_FIRE = "rbxasset://textures/particles/fire_main.dds"
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local function gBrush(width: number, life: number, c1: Color3, c2: Color3, glow: boolean): Brush
	local b = brush(width, life, c1, glow)
	b.tr.Color = ColorSequence.new(c1, c2)
	if glow then
		b.tr.LightEmission = 1
		b.tr.LightInfluence = 0
	end
	return b
end
local function gStroke(from: Vector3, to: Vector3, time: number, width: number, wave: number, c1: Color3, c2: Color3, glow: boolean?, life: number?)
	local b = gBrush(width, life or 0.45, c1, c2, glow ~= false)
	local dir = to - from
	local side = dir.Magnitude > 0.01 and dir.Unit:Cross(V(0, 1, 0)) or V(1, 0, 0)
	if side.Magnitude < 0.01 then
		side = V(1, 0, 0)
	end
	side = side.Unit
	local ph = math.random() * 6.3
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min(1, (os.clock() - t0) / time)
		local p = from:Lerp(to, k) + side * math.sin(k * math.pi * 2.5 + ph) * wave * (1 - k * 0.6) + V(0, math.sin(k * math.pi) * wave * 0.5, 0)
		b.p.CFrame = CF(p) * CFrame.Angles(k * 6, ph, 0)
		if k >= 1 then
			conn:Disconnect()
			dropBrush(b, life or 0.45)
		end
	end)
end
local function gEmit(at: Vector3, tex: string, c1: Color3, c2: Color3, n: number, size: number, speed: number, life: number, light: number?, accel: Vector3?)
	local holder = piece(V(0.1, 0.1, 0.1), CF(at), WHITE, 1)
	local e = Instance.new("ParticleEmitter")
	e.Texture = tex
	e.Color = ColorSequence.new(c1, c2)
	e.LightEmission = light or 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(life * 0.6, life)
	e.Rate = 0
	e.Speed = NumberRange.new(speed * 0.4, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = accel or V(0, 2, 0)
	e.Drag = 1.5
	e.Parent = holder
	e:Emit(n)
	Debris:AddItem(holder, life + 0.2)
end
local function gSwirl(center: () -> Vector3, n: number, r: number, h: number, life: number, c1: Color3, c2: Color3, opt: any?)
	local o = opt or {}
	local list = {}
	for i = 1, n do
		local alt = o.c3 and i % 4 == 0
		local b = gBrush((o.width or 0.6) * (0.6 + math.random() * 0.8), o.trail or 0.5, alt and o.c3 or c1, c2, o.glow ~= false)
		table.insert(list, { b = b, f1 = 1.2 + math.random() * 2.4, f2 = 1.5 + math.random() * 3, f3 = 0.9 + math.random() * 2.2, p1 = math.random() * 6.3, p2 = math.random() * 6.3, p3 = math.random() * 6.3, rk = 0.55 + math.random() * 0.6 })
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local c = center()
		if t > life then
			conn:Disconnect()
			for _, sx in ipairs(list) do
				dropBrush(sx.b, o.trail or 0.5)
			end
			return
		end
		local k = t / life
		local rr = r * (o.converge and (1 - 0.85 * k * k) or 1) * (o.grow and math.min(1, t / 0.25) or 1) * (o.expand and (0.2 + k) or 1)
		for _, sx in ipairs(list) do
			local a = t * sx.f1 * (o.speed or 1) + sx.p1
			local x = math.cos(a) * rr * sx.rk + math.sin(t * sx.f3 + sx.p3) * rr * 0.2
			local z = math.sin(a) * rr * sx.rk + math.cos(t * sx.f2 + sx.p2) * rr * 0.2
			local y = (o.flat and 0.3 or math.sin(t * sx.f2 + sx.p2) * h * 0.5) + (o.rise and k * o.rise or 0)
			sx.b.p.CFrame = CF(c + V(x, y, z)) * CFrame.Angles(t * sx.f3, a, 0)
		end
	end)
end
-- 뱀 / 용: 머리가 path(u) 를 따라가고 몸 줄기 n개가 조금씩 늦게 따라간다 (굽이친다)
local function gSerpent(path: (number) -> Vector3, time: number, n: number, width: number, c1: Color3, c2: Color3, lag: number?)
	local list = {}
	for i = 1, n do
		table.insert(list, { b = gBrush(width * (1 - (i - 1) / n * 0.6), 0.35, i == 1 and c2 or c1, c2, true), d = (i - 1) * (lag or 0.035), o = V(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * width })
	end
	local t0 = os.clock()
	local total = time + n * (lag or 0.035)
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > total then
			conn:Disconnect()
			for _, sx in ipairs(list) do
				dropBrush(sx.b, 0.35)
			end
			return
		end
		for i, sx in ipairs(list) do
			local u = math.clamp((t - sx.d) / time, 0, 1)
			local w = math.sin(t * 14 + i * 0.7) * width * 0.4
			sx.b.p.CFrame = CF(path(u) + sx.o + V(w, w * 0.5, 0)) * CFrame.Angles(t * 5, i, 0)
		end
	end)
end
-- 빛 줄기 짐승: 뼈대 (선분들) 를 따라 줄기가 쉬지 않고 긁어 짐승을 그린다. place() 가 몸의 자리 (CFrame) 를 준다
local function gBeast(bones: { { Vector3 } }, place: (number) -> CFrame?, life: number, k: number, c1: Color3, c2: Color3, per: number?, legSwing: { number }?)
	-- 3.99.42판: 빔으로 (달려도 번지지 않는다)
	beamBeast(bones, place, life, k, c1, c2, { per = per or 3, legs = legSwing, glow = true, w = 0.45, amp = 0.6, gallop = 18 })
end
local function gClaw(at: Vector3, dir: Vector3, size: number, c1: Color3, c2: Color3, n: number?)
	local right = V(-dir.Z, 0, dir.X)
	local m = n or 4
	for i = 1, m do
		local off = right * ((i - (m + 1) / 2) * size * 0.28)
		local from = at + off + V(0, size * 0.7, 0) - dir * size * 0.4
		local to = at + off * 1.3 + V(0, -size * 0.2, 0) + dir * size * 0.6
		gStroke(from, to, 0.12, size * 0.16, size * 0.08, c1, c2, true, 0.35)
	end
end

------------------------------------------------------------------------
-- 🕸 천잠사수: 하늘누에의 실 (가늘고 빛나는 흰 금빛 실)
------------------------------------------------------------------------
local SILK, SILK2, SILK3 = Color3.fromRGB(235, 242, 255), Color3.fromRGB(255, 225, 160), Color3.fromRGB(150, 170, 220)
VFX.silkShot = function(d)
	local from = (d.from :: Vector3) + V(0, 2.6, 0)
	local dir = d.dir :: Vector3
	local len = d.length or 24
	local right = V(-dir.Z, 0, dir.X)
	for i = 1, 6 do
		local to = from + dir * len + right * ((i - 3.5) * 1.8) + V(0, (math.random() - 0.5) * 3, 0)
		gStroke(from, to, 0.16 + i * 0.01, 0.18, 0.6, SILK, SILK2, true, 0.6)
	end
	gEmit(from + dir * len * 0.5, TEX_SPARK, SILK, SILK2, 14, 0.5, 6, 0.6)
end
VFX.silkBind = function(d)
	local at = d.at + V(0, 2.5, 0)
	gSwirl(function()
		return at
	end, 10, (d.radius or 5) * 0.9, 4, 0.4, SILK, SILK2, { width = 0.18, trail = 0.5, converge = true, speed = 2 })
	task.delay(0.38, function()
		-- 당겨 끊어지는 실: 사방으로 튀는 가는 획
		for i = 1, 8 do
			local a = i / 8 * math.pi * 2
			gStroke(at, at + V(math.cos(a) * 7, (math.random() - 0.5) * 4, math.sin(a) * 7), 0.12, 0.2, 0.3, SILK, SILK2, true, 0.4)
		end
		gEmit(at, TEX_SPARK, SILK2, SILK, 16, 0.6, 10, 0.5)
		pcall(Fx.sound, "swing", 0.6, 1.4, at)
	end)
end
-- 거미줄: 가운데에서 바깥으로 뻗는 실 열둘 + 둘레를 감는 고리 셋
local function web(g: Vector3, r: number, life: number, tilt: number?)
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		gStroke(g, g + V(math.cos(a) * r, tilt and math.sin(a) * tilt or 0, math.sin(a) * r), 0.16, 0.16, 0.2, SILK, SILK2, true, life)
	end
	for ring = 1, 3 do
		local rr = r * ring / 3.4
		local b = gBrush(0.14, life, SILK, SILK2, true)
		local t0 = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local k = math.min(1, (os.clock() - t0) / 0.3)
			local a = k * math.pi * 2
			b.p.CFrame = CF(g + V(math.cos(a) * rr, tilt and math.sin(a) * tilt * ring / 3.4 or 0, math.sin(a) * rr))
			if k >= 1 then
				conn:Disconnect()
				dropBrush(b, life)
			end
		end)
	end
end
VFX.silkWeb = function(d)
	local g = ground(d.at) + V(0, 0.4, 0)
	web(g, d.radius or 13, d.life or 0.6)
end
VFX.silkSnap = function(d)
	local g = ground(d.at) + V(0, 1, 0)
	local r = d.radius or 14
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		gStroke(g + V(math.cos(a) * r, 0, math.sin(a) * r), g + V(0, 2, 0), 0.14, 0.2, 0.4, SILK, SILK2, true, 0.35)
	end
	task.delay(0.15, function()
		gEmit(g + V(0, 2, 0), TEX_SPARK, SILK2, SILK, 30, 0.7, 14, 0.6)
		Fx.flash(g + V(0, 2, 0), SILK2, r * 2, 2, 0.2)
		shake(0.4)
	end)
end
VFX.silkDome = function(d)
	local g = ground(d.at)
	local r = d.radius or 22
	local life = d.life or 1.5
	-- 땅에서 하늘로 솟는 실 기둥 열여섯, 꼭대기에서 엮이는 그물 지붕
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		local base = g + V(math.cos(a) * r, 0, math.sin(a) * r)
		gStroke(base, g + V(0, r * 0.9, 0), 0.3, 0.2, 1.5, SILK, SILK2, true, life)
	end
	task.delay(0.3, function()
		web(g + V(0, r * 0.9, 0), r * 0.7, life - 0.3, 3)
	end)
	gSwirl(function()
		return g + V(0, r * 0.5, 0)
	end, 10, r * 0.9, r * 0.6, life, SILK, SILK2, { width = 0.15, trail = 0.9, speed = 0.5 })
end
VFX.silkCut = function(d)
	local at = d.at + V(0, 2.5, 0)
	local a = math.random() * math.pi
	local dir = V(math.cos(a), 0, math.sin(a))
	gStroke(at - dir * 12 + V(0, 3, 0), at + dir * 12 - V(0, 2, 0), 0.1, 0.25, 0.2, SILK, SILK2, true, 0.35)
	gStroke(at + dir:Cross(V(0, 1, 0)) * 12 + V(0, 2, 0), at - dir:Cross(V(0, 1, 0)) * 12, 0.1, 0.25, 0.2, SILK2, SILK, true, 0.35)
	gEmit(at, TEX_SPARK, SILK, SILK2, 10, 0.5, 8, 0.4)
end
VFX.silkCollapse = function(d)
	local g = ground(d.at) + V(0, 3, 0)
	local r = d.radius or 18
	gSwirl(function()
		return g
	end, 24, r * 1.2, r * 0.8, 0.45, SILK, SILK2, { width = 0.25, trail = 0.4, converge = true, speed = 2.2, c3 = SILK3 })
	task.delay(0.42, function()
		for i = 1, 20 do
			local a = i / 20 * math.pi * 2
			gStroke(g, g + V(math.cos(a) * r * 1.4, (math.random() - 0.3) * r * 0.6, math.sin(a) * r * 1.4), 0.18, 0.3, 0.6, SILK, SILK2, true, 0.5)
		end
		gEmit(g, TEX_SPARK, SILK2, SILK, 50, 0.9, 20, 0.8)
		Fx.ring(ground(d.at) + V(0, 0.5, 0), SILK2, 3, r * 2.4, 0.5)
		Fx.flash(g, SILK, r * 2.4, 4, 0.3)
		shake(1)
	end)
end

------------------------------------------------------------------------
-- 🐍 만독천수: 독사 (빛나는 초록 · 보라 줄기) · 독안개 (입자) · 독꽃
------------------------------------------------------------------------
local VENOM, VENOM2, VENOMD = Color3.fromRGB(150, 255, 90), Color3.fromRGB(180, 90, 255), Color3.fromRGB(30, 20, 40)
local function venomFog(at: Vector3, r: number, life: number, n: number)
	gEmit(at, TEX_SMOKE, VENOM:Lerp(VENOMD, 0.3), VENOM2:Lerp(VENOMD, 0.5), n, r * 0.7, r * 0.5, life, 0.25, V(0, 1, 0))
end
VFX.venomSnake = function(d)
	local from = (d.from :: Vector3) + V(0, 2.2, 0)
	local dir = d.dir :: Vector3
	local len = d.length or 24
	local right = V(-dir.Z, 0, dir.X)
	for s = -1, 1 do
		local ph = s * 1.3
		gSerpent(function(u)
			return from + dir * len * u + right * (math.sin(u * math.pi * 4 + ph) * 2.2 + s * 1.5) + V(0, math.sin(u * math.pi) * 1.5, 0)
		end, 0.32, 8, 0.9, s == 0 and VENOM2 or VENOM, VENOM:Lerp(WHITE, 0.4), 0.025)
	end
end
VFX.venomBurst = function(d)
	local at = d.at + V(0, 2, 0)
	venomFog(at, d.radius or 8, 1.4, 30)
	gEmit(at, TEX_SPARK, VENOM, VENOM2, 24, 0.7, 14, 0.6)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		gStroke(at, at + V(math.cos(a) * 8, math.random() * 4, math.sin(a) * 8), 0.18, 0.6, 1, VENOM, VENOM2, true, 0.4)
	end
	pcall(Fx.sound, "splash", 0.6, 0.7, at)
	shake(0.35)
end
VFX.venomMist = function(d)
	local g = ground(d.at) + V(0, 2, 0)
	local r = d.radius or 12
	local life = d.life or 1.3
	venomFog(g, r, life + 0.6, 50)
	gSwirl(function()
		return g
	end, 12, r * 0.85, 2, life, VENOM, VENOM2, { width = 0.7, trail = 0.7, speed = 1.3, c3 = VENOM2 })
end
VFX.venomPulse = function(d)
	local g = ground(d.at) + V(0, 1.5, 0)
	local r = d.radius or 12
	gSwirl(function()
		return g
	end, 14, r, 1, 0.35, VENOM, VENOM2, { width = 0.8, trail = 0.35, converge = true, speed = 2.4 })
	venomFog(g, r * 0.7, 0.9, 16)
end
VFX.venomSea = function(d)
	local g = ground(d.at) + V(0, 0.5, 0)
	local r = d.radius or 24
	local life = d.life or 1.9
	local pool = piece(V(0.2, 2, 2), CF(g - V(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), VENOMD, 0.25, Enum.PartType.Cylinder)
	pool.Material = Enum.Material.SmoothPlastic
	tween(pool, 0.4, { Size = V(0.2, r * 2, r * 2) })
	task.delay(life, function()
		fadeOut(pool, 0.5)
	end)
	gSwirl(function()
		return g
	end, 26, r * 0.95, 0.6, life, VENOM, VENOM2, { width = 1.2, trail = 1, grow = true, speed = 0.7, flat = true, c3 = VENOM2 })
	for _ = 1, 4 do
		task.delay(math.random() * life * 0.8, function()
			venomFog(g + V((math.random() - 0.5) * r, 1, (math.random() - 0.5) * r), r * 0.4, 1, 10)
		end)
	end
end
VFX.venomFang = function(d)
	local g = ground(d.at)
	local base = g + V((math.random() - 0.5) * 10, -1, (math.random() - 0.5) * 10)
	local top = g + V(0, 9, 0)
	gSerpent(function(u)
		if u < 0.6 then
			return base:Lerp(top, u / 0.6)
		end
		return top:Lerp(g + V(0, 1.5, 0), (u - 0.6) / 0.4)
	end, 0.3, 7, 1, VENOM, VENOM2, 0.02)
	task.delay(0.3, function()
		gEmit(g + V(0, 1.5, 0), TEX_SPARK, VENOM, VENOM2, 12, 0.6, 9, 0.4)
		venomFog(g + V(0, 1.5, 0), 4, 0.8, 8)
	end)
end
VFX.venomBloom = function(d)
	local g = ground(d.at)
	local r = d.radius or 22
	-- 땅에서 솟는 독꽃: 꽃잎 열둘 (휘어 오르는 줄기) 이 벌어졌다가 가운데에서 터진다
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local tip = g + V(math.cos(a) * r * 0.8, r * 0.6, math.sin(a) * r * 0.8)
		gSerpent(function(u)
			local mid = g + V(math.cos(a) * r * 0.25, r * 0.5, math.sin(a) * r * 0.25)
			if u < 0.5 then
				return g:Lerp(mid, u * 2)
			end
			return mid:Lerp(tip, (u - 0.5) * 2)
		end, 0.4, 5, 1.6, i % 2 == 0 and VENOM2 or VENOM, VENOM:Lerp(WHITE, 0.5), 0.03)
	end
	task.delay(0.5, function()
		venomFog(g + V(0, 4, 0), r, 1.6, 60)
		gEmit(g + V(0, 4, 0), TEX_SPARK, VENOM, VENOM2, 60, 1, 26, 0.9)
		Fx.ring(g + V(0, 0.5, 0), VENOM, 3, r * 2.4, 0.5)
		Fx.flash(g + V(0, 5, 0), VENOM, r * 2.4, 4, 0.35)
		pcall(Fx.sound, "splash", 0.9, 0.5, g)
		shake(1.1)
	end)
end
VFX.venomCloud = function(d)
	local at = d.at + V(0, 1.5, 0)
	venomFog(at, d.radius or 9, 1.1, 22)
	gSwirl(function()
		return at
	end, 8, (d.radius or 9) * 0.8, 1.5, 0.35, VENOM, VENOM2, { width = 0.6, trail = 0.3, converge = true, speed = 2 })
end

------------------------------------------------------------------------
-- 👻 귀화백골장: 푸른 귀화 (빛 줄기 + 불 입자) · 망자의 손 (빛으로 그린 손가락) · 해골
------------------------------------------------------------------------
local GHOST, GHOST2, GHOSTD = Color3.fromRGB(120, 230, 255), Color3.fromRGB(235, 250, 255), Color3.fromRGB(10, 26, 34)
local function specterFlame(at: Vector3, size: number, life: number)
	gEmit(at, TEX_FIRE, GHOST, GHOST2, math.floor(10 + size * 4), size, size * 1.6, life, 1, V(0, size * 3, 0))
end
VFX.specterFire = function(d)
	local at = ground(d.at) + V(0, 2, 0)
	local from = (d.from :: Vector3) + V(0, 3.5, 0)
	-- 귀화가 휘어 날아든다 (꼬리를 끄는 혼)
	gSerpent(function(u)
		local mid = from:Lerp(at, 0.5) + V(0, 6, 0)
		local a = from:Lerp(mid, u)
		local b = mid:Lerp(at, u)
		return a:Lerp(b, u)
	end, 0.22, 6, d.big and 1.6 or 0.9, GHOST, GHOST2, 0.02)
	task.delay(0.22, function()
		specterFlame(at, d.big and 3.5 or 2, 0.7)
		gSwirl(function()
			return at
		end, 6, d.big and 5 or 3, 3, 0.5, GHOST, GHOST2, { width = 0.4, trail = 0.4, rise = 4 })
		if d.big then
			Fx.flash(at, GHOST, 26, 3, 0.3)
			shake(0.5)
		end
	end)
end
local function specterHand(at: Vector3)
	-- 손가락 다섯이 땅에서 솟아 움켜쥔다
	for f = -2, 2 do
		local base = at + V(f * 0.55, -0.5, 0)
		local tip = at + V(f * 0.3, 4.2 - math.abs(f) * 0.4, -0.4)
		gStroke(base, tip, 0.14, 0.32, 0.25, GHOST2, GHOST, true, 0.45)
		task.delay(0.15, function()
			gStroke(tip, at + V(f * 0.15, 2.4, -1.4), 0.12, 0.28, 0.1, GHOST2, GHOST, true, 0.35)
		end)
	end
end
VFX.specterHands = function(d)
	if d.length then
		local from, dir = d.from :: Vector3, d.dir :: Vector3
		for i = 1, 6 do
			task.delay(i * 0.04, function()
				specterHand(ground(from + dir * (d.length * i / 6)) + V((math.random() - 0.5) * 2, 0, (math.random() - 0.5) * 2))
			end)
		end
	else
		local g = ground(d.at)
		specterHand(g + V(-1, 0, 0))
		specterHand(g + V(1, 0, 0.5))
		specterFlame(g + V(0, 1, 0), 1.6, 0.5)
	end
end
VFX.specterCircle = function(d)
	local g = ground(d.at) + V(0, 0.4, 0)
	local r = d.radius or 22
	local disk = piece(V(0.2, r * 2, r * 2), CF(g - V(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), GHOSTD, 0.3, Enum.PartType.Cylinder)
	disk.Material = Enum.Material.SmoothPlastic
	task.delay(1.6, function()
		fadeOut(disk, 0.4)
	end)
	-- 둘레를 도는 혼 줄기와 바깥의 귀화 여덟
	gSwirl(function()
		return g
	end, 18, r * 0.95, 1, 1.8, GHOST, GHOST2, { width = 0.6, trail = 0.8, flat = true, speed = 0.9 })
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		specterFlame(g + V(math.cos(a) * r * 0.9, 1, math.sin(a) * r * 0.9), 2, 1.4)
	end
end
-- 빛 줄기로 그린 해골 (둥근 머리 · 눈구멍 둘 · 턱) 이 떠올랐다가 터진다
VFX.specterSkull = function(d)
	local g = ground(d.at)
	local r = d.radius or 24
	local c = g + V(0, 9, 0)
	local s = r * 0.32
	local head: { { Vector3 } } = {}
	for i = 0, 11 do
		local a1, a2 = i / 12 * math.pi * 2, (i + 1) / 12 * math.pi * 2
		table.insert(head, { V(math.cos(a1) * s, math.sin(a1) * s * 0.9 + s * 0.3, 0), V(math.cos(a2) * s, math.sin(a2) * s * 0.9 + s * 0.3, 0) })
	end
	table.insert(head, { V(-s * 0.55, s * 0.3, 0), V(-s * 0.2, s * 0.1, 0) })
	table.insert(head, { V(s * 0.55, s * 0.3, 0), V(s * 0.2, s * 0.1, 0) })
	table.insert(head, { V(-s * 0.5, -s * 0.55, 0), V(s * 0.5, -s * 0.55, 0) })
	local cam = workspace.CurrentCamera
	gBeast(head, function(t)
		local look = cam and (cam.CFrame.Position - c) or V(0, 0, 1)
		return t < 0.5 and CFrame.lookAt(c, c + V(look.X, 0, look.Z)) or nil
	end, 0.5, 1, GHOST2, GHOST, 2)
	specterFlame(c + V(-s * 0.4, s * 0.2, 0), 2, 0.6)
	specterFlame(c + V(s * 0.4, s * 0.2, 0), 2, 0.6)
	task.delay(0.5, function()
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			specterFlame(g + V(math.cos(a) * r * 0.7, 1, math.sin(a) * r * 0.7), 2.4, 0.8)
			gStroke(c, g + V(math.cos(a) * r, 0.5, math.sin(a) * r), 0.22, 0.8, 2, GHOST, GHOST2, true, 0.4)
		end
		Fx.ring(g + V(0, 0.5, 0), GHOST, 4, r * 2.2, 0.5)
		Fx.flash(c, GHOST, r * 2.2, 5, 0.4)
		shake(1.2)
	end)
end

------------------------------------------------------------------------
-- 혼돈개천권 먹 매듭 (패시브) · 혼돈화신 (몸을 휘감는 먹)
------------------------------------------------------------------------
VFX.inkKnot = function(d)
	local at = d.at + V(0, 2, 0)
	inkSwirl(function()
		return at
	end, 10, (d.radius or 11) * 0.7, 3, 0.3, { converge = true, width = 1.1, trail = 0.3, gold = true, speed = 2.4 })
	task.delay(0.28, function()
		inkBurst(at, (d.radius or 11) * 0.8, false)
	end)
end
local auraOn: { [Model]: boolean } = {}
local function inkAvatar(model: Model)
	if auraOn[model] then
		return
	end
	auraOn[model] = true
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		auraOn[model] = nil
		return
	end
	local function alive(): boolean
		return model.Parent ~= nil and model:GetAttribute("Twilight") == true and model:GetAttribute("Style") == "hondon"
	end
	-- 화신이 되는 순간: 사방의 먹이 0.3초 만에 몸으로 감겨 들고 하늘에 「化身」
	inkSwirl(function()
		return root.Position
	end, 24, 14, 6, 0.35, { converge = true, width = 1.1, trail = 0.3, gold = true, speed = 3.5 })
	task.delay(0.33, function()
		inkBurst(root.Position, 9, true)
	end)
	calligraphy(root.Position + V(0, 30, 0), "化身", 1.8)
	task.spawn(function()
		task.wait(0.3)
		while alive() do
			-- 몸을 빠르게 휘감아 오르는 먹 줄기 (아래에서 위로 감기며 돈다)
			inkSwirl(function()
				return root.Position - V(0, 2.5, 0)
			end, 14, 2.3, 1, 0.55, { width = 0.55, trail = 0.3, gold = true, speed = 3.6, rise = 5.5 })
			task.wait(0.45)
		end
		auraOn[model] = nil
	end)
end
function ForgeFx.watchAvatar(model: Model)
	local function check()
		if model:GetAttribute("Twilight") == true and model:GetAttribute("Style") == "hondon" then
			inkAvatar(model)
		end
	end
	model:GetAttributeChangedSignal("Twilight"):Connect(check)
	check()
end

------------------------------------------------------------------------
-- 사신천왕권 (다시): 빛 줄기로 그린 네 신수. 백호 (E) · 주작 둘 (R) · 청룡 (G) · 넷이 함께 (X) · 사신진 (패시브)
------------------------------------------------------------------------
local TIGER, TIGER2 = Color3.fromRGB(245, 248, 255), Color3.fromRGB(150, 200, 255)
local BIRD, BIRD2 = Color3.fromRGB(255, 110, 50), Color3.fromRGB(255, 225, 120)
local AZURE, AZURE2 = Color3.fromRGB(80, 170, 255), Color3.fromRGB(200, 245, 255)
local TURTLE, TURTLE2 = Color3.fromRGB(70, 60, 110), Color3.fromRGB(150, 255, 210)
local TIGER_BONES: { { Vector3 } } = {
	{ V(0, 0, 2.6), V(0, 0.2, -2.4) }, { V(0, -0.6, 2.2), V(0, -0.5, -2.2) },
	{ V(0, 0.2, -2.4), V(0, 0.9, -3.4) }, { V(-0.6, 1.0, -3.3), V(0.6, 1.0, -3.3) }, { V(0, 0.9, -3.4), V(0, 0.2, -4.4) },
	{ V(0, 0.2, 2.6), V(0, 1.6, 4.6) },
	{ V(-0.7, -0.4, -2), V(-0.7, -2.6, -2.4) }, { V(0.7, -0.4, -2), V(0.7, -2.6, -1.6) },
	{ V(-0.7, -0.4, 2), V(-0.7, -2.6, 1.6) }, { V(0.7, -0.4, 2), V(0.7, -2.6, 2.4) },
}
local function sashinLightDash(d)
	local pts = d.pts
	if not pts or #pts < 2 then
		return
	end
	local a, b = pts[1], pts[#pts]
	local dir = (b - a)
	dir = V(dir.X, 0, dir.Z).Magnitude > 0.1 and V(dir.X, 0, dir.Z).Unit or V(0, 0, -1)
	local T0 = (d.cut or 0) + (d.charge or 0.25)
	local run = 0.35
	gBeast(TIGER_BONES, function(t)
		local u = math.clamp((t - T0) / run, 0, 1)
		if t > T0 + run + 0.25 then
			return nil
		end
		local p = a:Lerp(b, u) + V(0, 1.2, 0)
		return CFrame.lookAt(p, p + dir) * CF(0, math.abs(math.sin(t * 14)) * 0.6, 0)
	end, T0 + run + 0.3, 1.5, TIGER, TIGER2, 3, { 7, 8, 9, 10 })
	task.delay(T0, function()
		local n = 6
		for i = 1, n do
			task.delay(i * run / n, function()
				gClaw(a:Lerp(b, i / n) + V(0, 1, 0), dir, 4.5, TIGER, TIGER2, 4)
			end)
		end
	end)
end
local function phoenix(path: (number) -> Vector3, time: number, side: number)
	-- 몸 줄기 (불꽃 꼬리) + 날개 획 (날갯짓)
	gSerpent(path, time, 7, 1.2, BIRD, BIRD2, 0.03)
	local t0 = os.clock()
	local wings = { gBrush(0.9, 0.35, BIRD, BIRD2, true), gBrush(0.9, 0.35, BIRD, BIRD2, true) }
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local u = math.min(1, t / time)
		local p = path(u)
		local p2 = path(math.min(1, u + 0.02))
		local fwd = (p2 - p).Magnitude > 0.01 and (p2 - p).Unit or V(0, 0, -1)
		local right = fwd:Cross(V(0, 1, 0))
		local flap = math.sin(t * 22) * 2.4
		for wi, w in ipairs(wings) do
			local sx = wi == 1 and 1 or -1
			w.p.CFrame = CF(p + right * sx * 3.6 + V(0, flap, 0) - fwd * 1.2)
		end
		if u >= 1 then
			conn:Disconnect()
			for _, w in ipairs(wings) do
				dropBrush(w, 0.35)
			end
		end
	end)
end
local function sashinTwinDiscs(d)
	local from, dir = d.from, d.dir
	if not from or not dir then
		return
	end
	dir = V(dir.X, 0, dir.Z).Magnitude > 0.01 and V(dir.X, 0, dir.Z).Unit or V(0, 0, -1)
	local right = V(-dir.Z, 0, dir.X)
	local dist, swing, time = d.dist or 30, d.swing or 9, math.max(0.2, d.time or 0.6)
	for _, sx in ipairs({ 1, -1 }) do
		phoenix(function(u)
			return from + V(0, 3, 0) + dir * dist * u + right * sx * math.sin(u * math.pi) * swing
		end, time, sx)
	end
	task.delay(time, function()
		local at = from + dir * dist + V(0, 2, 0)
		gEmit(at, TEX_FIRE, BIRD, BIRD2, 40, 3, 18, 0.7, 1, V(0, 6, 0))
		for i = 1, 10 do
			local a = i / 10 * math.pi * 2
			gStroke(at, at + V(math.cos(a) * 10, math.random() * 5, math.sin(a) * 10), 0.2, 1, 1.5, BIRD, BIRD2, true, 0.4)
		end
		shake(0.5)
	end)
end
local function sashinOnepunch(d)
	local r = d.m and d.m:FindFirstChild("HumanoidRootPart")
	local from = d.from or (r and r.Position)
	if not from then
		return
	end
	local dir = d.dir or (r and r.CFrame.LookVector) or V(0, 0, -1)
	dir = V(dir.X, 0, dir.Z).Magnitude > 0.01 and V(dir.X, 0, dir.Z).Unit or V(0, 0, -1)
	local range = d.range or 54
	local delay = d.delay or 1
	-- 모으는 동안: 몸 둘레를 감아 오르는 푸른 용 줄기
	gSwirl(function()
		return from + V(0, 1, 0)
	end, 12, 4, 3, delay, AZURE, AZURE2, { width = 0.9, trail = 0.5, rise = 6, speed = 1.8 })
	task.delay(delay, function()
		-- 지르는 순간: 거대한 청룡이 앞으로 솟구쳐 휩쓴다 (줄기 서른 개가 한 몸)
		local right = V(-dir.Z, 0, dir.X)
		gSerpent(function(u)
			return from + V(0, 3, 0) + dir * range * u + right * math.sin(u * math.pi * 3) * 5 + V(0, math.sin(u * math.pi) * 9, 0)
		end, 0.55, 30, 3.2, AZURE, AZURE2, 0.012)
		for i = 1, 3 do
			gSerpent(function(u)
				return from + V(0, 3, 0) + dir * range * u + right * (math.sin(u * math.pi * 3 + i) * 7) + V(0, math.sin(u * math.pi) * (6 + i * 2), 0)
			end, 0.6, 8, 1.2, AZURE2, WHITE, 0.02)
		end
		task.delay(0.5, function()
			local at = from + dir * range + V(0, 3, 0)
			gEmit(at, TEX_SPARK, AZURE, AZURE2, 60, 1.2, 24, 0.8)
			Fx.flash(at, AZURE, 40, 4, 0.35)
		end)
		shake(1)
	end)
end
local GOD = { { TIGER, TIGER2 }, { BIRD, BIRD2 }, { AZURE, AZURE2 }, { TURTLE, TURTLE2 } }
local function sashinStorm(d)
	local r = d.m and d.m:FindFirstChild("HumanoidRootPart")
	if not r then
		return
	end
	local dur = d.dur or 2.4
	local c = r.Position
	-- 네 신수의 빛 줄기 고리가 하늘을 돌며 차례로 내리꽂힌다
	for q = 1, 4 do
		local col = GOD[q]
		gSwirl(function()
			return c + V(0, 22 + q * 3, 0)
		end, 10, 14 + q * 3, 4, dur, col[1], col[2], { width = 1.4, trail = 0.6, speed = 0.8 + q * 0.15 })
	end
	local n = math.floor(dur / 0.3)
	for i = 1, n do
		task.delay(0.3 + i * 0.3, function()
			local col = GOD[(i - 1) % 4 + 1]
			local a = math.random() * math.pi * 2
			local at = ground(c + V(math.cos(a) * math.random() * 26, 0, math.sin(a) * math.random() * 26))
			gSerpent(function(u)
				return (c + V(0, 26, 0)):Lerp(at + V(0, 1, 0), u)
			end, 0.22, 8, 1.8, col[1], col[2], 0.015)
			task.delay(0.22, function()
				gEmit(at + V(0, 1, 0), TEX_SPARK, col[1], col[2], 16, 0.8, 12, 0.5)
			end)
		end)
	end
	task.delay(dur, function()
		-- 마지막: 현무의 등껍질 (육각 줄기) 이 하늘에서 내려와 짓누른다
		local g = ground(c)
		for i = 0, 5 do
			local a1, a2 = i / 6 * math.pi * 2, (i + 1) / 6 * math.pi * 2
			gStroke(g + V(math.cos(a1) * 30, 30, math.sin(a1) * 30), g + V(math.cos(a2) * 30, 0.5, math.sin(a2) * 30), 0.3, 2.5, 1, TURTLE2, TURTLE, true, 0.6)
		end
		Fx.ring(g + V(0, 0.5, 0), TURTLE2, 4, 66, 0.6)
		Fx.flash(g + V(0, 6, 0), WHITE, 70, 5, 0.4)
		shake(1.4)
	end)
end
local function sashinPulse(d)
	local at = d.at + V(0, 1.5, 0)
	for q = 1, 4 do
		local a = q / 4 * math.pi * 2
		gStroke(at + V(math.cos(a) * 12, 6, math.sin(a) * 12), at, 0.18, 1, 2, GOD[q][1], GOD[q][2], true, 0.4)
	end
	task.delay(0.18, function()
		gEmit(at, TEX_SPARK, WHITE, AZURE2, 24, 0.8, 14, 0.5)
	end)
end
local SASHIN = { lightDash = sashinLightDash, twinDiscs = sashinTwinDiscs, onepunch = sashinOnepunch, stormcloud = sashinStorm, pulse = sashinPulse }
function ForgeFx.sashin(data: any): boolean
	local fn = SASHIN[data.kind]
	if not fn then
		return false
	end
	local ok, err = pcall(fn, data)
	if not ok then
		warn("[권왕] 사신천왕권 연출 오류:", data.kind, err)
	end
	return true
end
-- 연출을 이 모듈이 그리는 패시브 (pulse fx 이름)
local OWN_PULSE = { inkKnot = true, venomCloud = true }

-- 3.99.38판 손맛: 혼돈개천권은 맞힐 때마다 먹이 튄다 (강타 · 기술은 크게)
function ForgeFx.hit(styleId: string, pos: Vector3, heavy: boolean, skill: boolean)
	local big = heavy or skill
	if styleId == "janwol" then
		-- 실이 채찍처럼 휘감긴다
		for _ = 1, big and 4 or 2 do
			local a = math.random() * math.pi * 2
			gStroke(pos + V(math.cos(a) * 5, 2, math.sin(a) * 5), pos, 0.1, 0.16, 0.6, SILK, SILK2, true, 0.35)
		end
		gEmit(pos, TEX_SPARK, SILK, SILK2, big and 12 or 5, 0.4, 7, 0.35)
		return
	elseif styleId == "noeun" then
		gEmit(pos, TEX_SMOKE, VENOM:Lerp(VENOMD, 0.3), VENOM2:Lerp(VENOMD, 0.5), big and 10 or 4, big and 3 or 1.8, 3, 0.8, 0.25)
		gEmit(pos, TEX_SPARK, VENOM, VENOM2, big and 10 or 5, 0.4, 7, 0.35)
		return
	elseif styleId == "gwihwa" then
		gEmit(pos, TEX_FIRE, GHOST, GHOST2, big and 16 or 7, big and 1.6 or 1, 5, 0.5, 1, V(0, 6, 0))
		return
	elseif styleId == "sashin" then
		local col = GOD[math.random(4)]
		gEmit(pos, TEX_SPARK, col[1], col[2], big and 14 or 6, 0.5, 9, 0.4)
		if big then
			gClaw(pos, V(math.random() - 0.5, 0, math.random() - 0.5).Unit, 3.5, col[1], col[2], 3)
		end
		return
	end
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
calligraphy = function(at: Vector3, text: string, life: number)
	local anchor = piece(V(0.1, 0.1, 0.1), CF(at), WHITE, 1)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(52, 26)
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

------------------------------------------------------------------------
-- 3.99.46판 혼돈옥 (영역): 화신을 가운데로 먹의 영역이 반구로 펼쳐진다 (경선 같은 먹 획이 하늘을 덮고 출렁인다)
--   고른 적은 영역 안에서 먹 사슬에 묶인다. 영역 안의 내 화면은 먹그림이 되고 이름이 크게 뜬다
------------------------------------------------------------------------
local function domainTitle(text: string, sub: string, life: number)
	local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return
	end
	local sg = Instance.new("ScreenGui")
	sg.Name = "KwonDomainTitle"
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 6
	sg.Parent = pg
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.42)
	l.Size = UDim2.fromScale(0.8, 0.16)
	l.Font = Enum.Font.Antique
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = WHITE
	l.TextStrokeColor3 = INK2
	l.TextStrokeTransparency = 0
	l.TextTransparency = 1
	l.Parent = sg
	local l2 = l:Clone()
	l2.Position = UDim2.fromScale(0.5, 0.54)
	l2.Size = UDim2.fromScale(0.6, 0.06)
	l2.Font = Enum.Font.GothamBlack
	l2.Text = sub
	l2.TextColor3 = BRUSH_GOLD
	l2.Parent = sg
	tween(l, 0.25, { TextTransparency = 0 })
	tween(l2, 0.4, { TextTransparency = 0 })
	task.delay(life, function()
		tween(l, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
		tween(l2, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
		Debris:AddItem(sg, 0.6)
	end)
end
VFX.inkPrison = function(d)
	local caster = d.m
	local target = d.t
	local center = ground(d.at)
	local R = d.radius or 24
	local life = d.life or 6
	-- 바닥: 먹이 둥글게 번지는 영역
	local floor = piece(V(0.3, 2, 2), CF(center + V(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), INK2, 0.08, Enum.PartType.Cylinder)
	floor.Material = Enum.Material.SmoothPlastic
	tween(floor, 0.5, { Size = V(0.3, R * 2, R * 2) })
	local rim = piece(V(0.35, 2, 2), CF(center + V(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), BRUSH_GOLD, 0.2, Enum.PartType.Cylinder)
	tween(rim, 0.5, { Size = V(0.35, R * 2 + 1.2, R * 2 + 1.2) })
	task.delay(life, function()
		fadeOut(floor, 0.6)
		fadeOut(rim, 0.6)
	end)
	-- 하늘: 경선 열여섯 (땅의 한 점에서 꼭대기를 지나 맞은편으로 휘는 먹 획) 이 출렁이며 반구를 덮는다
	local dome: { { Vector3 } } = {}
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		local p0 = V(math.cos(a) * R, 0, math.sin(a) * R)
		table.insert(dome, { p0, V(0, R * 0.85, 0) })
	end
	for i = 1, 10 do
		local a1, a2 = math.random() * math.pi * 2, math.random() * math.pi * 2
		table.insert(dome, { V(math.cos(a1) * R * 0.9, R * 0.3, math.sin(a1) * R * 0.9), V(math.cos(a2) * R * 0.9, R * 0.5, math.sin(a2) * R * 0.9) })
	end
	-- 영역이 펼쳐진다: 처음 0.45초 동안 하늘 사방의 먹 획이 날아와 반구를 짠다
	beamBeast(dome, function(t)
		return CF(center) * CFrame.Angles(0, t * 0.6, 0)
	end, life, 1, INK2, INKEDGE, { per = 2, w = 1.6, gold = { 1, 5, 9, 13 }, amp = 7, form = 0.45 })
	-- 영역 벽을 도는 먹 줄기
	inkSwirl(function()
		return center + V(0, R * 0.35, 0)
	end, 30, R, R * 0.6, life, { width = 1.4, trail = 0.8, speed = 0.8, gold = true, drips = 30 })
	-- 갇힌 적: 땅의 여섯 점에서 뻗은 먹 사슬이 몸을 묶는다
	local troot = typeof(target) == "Instance" and target:FindFirstChild("HumanoidRootPart")
	if troot and troot:IsA("BasePart") then
		local chains: { { Vector3 } } = {}
		for i = 1, 6 do
			local a = i / 6 * math.pi * 2
			table.insert(chains, { V(math.cos(a) * 7, -3, math.sin(a) * 7), V(0, 0.5, 0) })
		end
		local tr = troot :: BasePart
		beamBeast(chains, function()
			return tr.Parent and CF(tr.Position) or nil
		end, life, 1, INK2, INKEDGE, { per = 2, w = 0.5, gold = { 2, 5 }, amp = 1.2 })
		inkSwirl(function()
			return tr.Position
		end, 12, 3, 4, life, { width = 0.6, trail = 0.4, speed = 2.5, gold = true })
	end
	-- 영역 안의 내 화면
	local cam = workspace.CurrentCamera
	local me = Players.LocalPlayer.Character
	if cam and ((cam.CFrame.Position - center).Magnitude < R + 10 or me == caster or me == target) then
		inkScreen(life)
		domainTitle("混沌獄", "혼돈옥 · 먹의 영역", 1.8)
		shake(0.8)
	end
	Fx.flash(center + V(0, 6, 0), BRUSH_GOLD, R * 2, 4, 0.4)
	pcall(Fx.sound, "splash", 1, 0.45, center)
end

-- 천지미분 끝 (오의와 다르게): 하늘에서 먹의 회오리 → 하늘만 한 붓의 두 획
VFX.inkFunnel = function(d)
	local g = ground(d.at)
	local r = d.radius or 40
	local life = d.life or 0.7
	-- 위로 갈수록 넓어지는 깔때기: 높이마다 고리 소용돌이
	for lvl = 0, 4 do
		local h = lvl * 9
		inkSwirl(function()
			return g + V(0, h, 0)
		end, 10, 4 + lvl * r * 0.18, 2, life, { width = 1.6, trail = 0.5, speed = 3 - lvl * 0.3, converge = lvl == 0, gold = lvl % 2 == 0 })
	end
	shake(0.6)
end
VFX.inkCleave = function(d)
	local g = ground(d.at) + V(0, 3, 0)
	local r = d.radius or 46
	local look = d.dir or V(0, 0, -1)
	local right = V(-look.Z, 0, look.X)
	-- 첫 획: 왼쪽 위에서 오른쪽 아래로, 둘째 획: 오른쪽 위에서 왼쪽 아래로 (굵은 붓, 금빛 테)
	local strokes = { { g - right * r + V(0, r * 0.5, 0) - look * r * 0.3, g + right * r - V(0, 1, 0) + look * r * 0.3 }, { g + right * r + V(0, r * 0.5, 0) - look * r * 0.3, g - right * r - V(0, 1, 0) + look * r * 0.3 } }
	for si, st in ipairs(strokes) do
		task.delay((si - 1) * 0.28, function()
			for j = 1, 7 do
				local off = V(0, (j - 4) * 0.8, 0)
				inkStroke(st[1] + off, st[2] + off, 0.2, j == 4 and 4 or 2.6, 3, j == 4)
			end
			shake(0.9)
		end)
	end
	task.delay(0.65, function()
		inkBurst(g, r * 0.8, true)
		inkBurst(g + right * r * 0.5, r * 0.4, true)
		inkBurst(g - right * r * 0.5, r * 0.4, true)
		Fx.ring(ground(d.at) + V(0, 0.5, 0), BRUSH_GOLD, 4, r * 2.2, 0.6)
		Fx.flash(g, WHITE, r * 2.5, 6, 0.4)
		calligraphy(g + V(0, 34, 0), "天地未分", 1.8)
		-- 3.99.52판: 두 획이 지나간 땅이 금빛으로 갈라지고, 갈라진 금을 따라 먹 기둥이 하늘로 솟는다
		local floor0 = ground(d.at) + V(0, 0.25, 0)
		for _, st in ipairs(strokes) do
			local a0 = V(st[1].X, floor0.Y, st[1].Z)
			local a1 = V(st[2].X, floor0.Y, st[2].Z)
			local seam = piece(V(1.4, 0.2, (a1 - a0).Magnitude), CFrame.lookAt((a0 + a1) / 2, a1), BRUSH_GOLD, 0)
			seam.Material = Enum.Material.Neon
			local glow = Instance.new("PointLight")
			glow.Color = BRUSH_GOLD
			glow.Range = 40
			glow.Brightness = 3
			glow.Parent = seam
			task.delay(1.8, function()
				fadeOut(seam, 0.6)
			end)
			for j = 0, 8 do
				task.delay(j * 0.05, function()
					local p = a0:Lerp(a1, j / 8)
					inkStroke(p, p + V((math.random() - 0.5) * 6, 40 + math.random() * 30, (math.random() - 0.5) * 6), 0.3, 3, 4, j % 3 == 0)
				end)
			end
		end
		inkScreen(1.2)
		shake(2)
	end)
end

-- 구룡멸세 (오의 구룡천강과 다르게): 하늘을 두 바퀴 휘감는 황금 용왕 → 금빛 숨 → 하늘까지 닿는 불기둥
local GOLDD, GOLDD2, GOLDFIRE = Color3.fromRGB(255, 205, 80), Color3.fromRGB(255, 250, 220), Color3.fromRGB(255, 110, 40)
VFX.goldDragonCircle = function(d)
	local c = ground(d.at)
	local R = d.radius or 30
	local life = d.life or 2.4
	gSerpent(function(u)
		local a = u * math.pi * 4
		return c + V(math.cos(a) * R, 16 + math.sin(u * math.pi * 6) * 4, math.sin(a) * R)
	end, life, 42, 5, GOLDD, GOLDD2, 0.012)
	for i = 1, 3 do
		gSerpent(function(u)
			local a = u * math.pi * 4 + i * 0.3
			return c + V(math.cos(a) * (R + i * 2), 18 + i, math.sin(a) * (R + i * 2))
		end, life, 10, 1.4, GOLDFIRE, GOLDD, 0.02)
	end
	shake(0.5)
end
VFX.dragonBreath = function(d)
	local g = ground(d.at)
	local from = g + V((math.random() - 0.5) * 20, 18, (math.random() - 0.5) * 20)
	for i = 1, 6 do
		gStroke(from, g + V((math.random() - 0.5) * 4, 0.5, (math.random() - 0.5) * 4), 0.18 + i * 0.02, 1.6, 1.5, GOLDFIRE, GOLDD, true, 0.4)
	end
	task.delay(0.2, function()
		gEmit(g + V(0, 1, 0), TEX_FIRE, GOLDD, GOLDFIRE, 30, 3, 10, 0.7, 1, V(0, 8, 0))
		shake(0.25)
	end)
end
VFX.dragonPillar = function(d)
	local g = ground(d.at)
	local r = d.radius or 30
	-- 용이 한가운데로 내리꽂힌다
	gSerpent(function(u)
		return (g + V(0, 60, 0)):Lerp(g + V(0, 1, 0), u)
	end, 0.3, 30, 6, GOLDD, GOLDD2, 0.01)
	task.delay(0.3, function()
		-- 하늘까지 닿는 금빛 불기둥 (빔 기둥 + 불 입자 + 둘레 고리)
		local col: { { Vector3 } } = {}
		for i = 1, 10 do
			local a = i / 10 * math.pi * 2
			table.insert(col, { V(math.cos(a) * 5, 0, math.sin(a) * 5), V(math.cos(a + 1) * 3, 160, math.sin(a + 1) * 3) })
		end
		beamBeast(col, function(t)
			return t < 1.4 and CF(g) * CFrame.Angles(0, t * 2.5, 0) or nil
		end, 1.4, 1, GOLDD, GOLDFIRE, { per = 1, w = 4, glow = true, amp = 3 })
		gEmit(g + V(0, 4, 0), TEX_FIRE, GOLDD, GOLDFIRE, 80, 6, 30, 1.2, 1, V(0, 30, 0))
		Fx.ring(g + V(0, 0.5, 0), GOLDD, 4, r * 2.4, 0.6)
		Fx.ring(g + V(0, 8, 0), GOLDFIRE, 4, r * 1.8, 0.5)
		Fx.flash(g + V(0, 10, 0), GOLDD, r * 2.6, 6, 0.45)
		shake(1.5)
	end)
end

-- 귀문개방 (오의 백귀야행과 다르게): 등 뒤의 저승 문 → 혼의 강 → 하늘만 한 혼의 낫
VFX.ghostGate = function(d)
	local caster = d.m
	local root = typeof(caster) == "Instance" and caster:FindFirstChild("HumanoidRootPart")
	local look = d.dir or V(0, 0, -1)
	local base = (root and root:IsA("BasePart")) and (root :: BasePart).Position or d.at
	local g = ground(base) - look * 10
	local life = d.life or 3
	-- 문: 두 기둥 + 아치 (혼빛 빔) 와 그 안의 소용돌이
	local right = V(-look.Z, 0, look.X)
	local frame: { { Vector3 } } = {
		{ right * -7, right * -7 + V(0, 20, 0) }, { right * 7, right * 7 + V(0, 20, 0) },
		{ right * -7 + V(0, 20, 0), V(0, 25, 0) }, { right * 7 + V(0, 20, 0), V(0, 25, 0) },
	}
	beamBeast(frame, function(t)
		return t < life and CF(g) or nil
	end, life, 1, GHOST2, GHOST, { per = 3, w = 1.2, glow = true, amp = 0.8 })
	gSwirl(function()
		return g + V(0, 11, 0)
	end, 20, 6, 8, life, GHOST, GHOST2, { width = 0.8, trail = 0.6, speed = 2 })
	specterFlame(g + V(0, 2, 0), 4, life)
end
VFX.ghostTorrent = function(d)
	local caster = d.m
	local root = typeof(caster) == "Instance" and caster:FindFirstChild("HumanoidRootPart")
	local look = d.dir or V(0, 0, -1)
	local gate = ((root and root:IsA("BasePart")) and (root :: BasePart).Position or d.from) - look * 10 + V(0, 11, 0)
	local at = d.at + V(0, 2, 0)
	for i = 1, 3 do
		gSerpent(function(u)
			local mid = gate:Lerp(at, 0.5) + V((math.random() - 0.5) * 6, 10, (math.random() - 0.5) * 6)
			return gate:Lerp(mid, u):Lerp(mid:Lerp(at, u), u)
		end, 0.3 + i * 0.04, 6, 1, GHOST, GHOST2, 0.02)
	end
	task.delay(0.35, function()
		specterFlame(at, 2.2, 0.6)
	end)
end
VFX.soulReap = function(d)
	local g = ground(d.at)
	local r = d.radius or 36
	local look = d.dir or V(0, 0, -1)
	-- 하늘만 한 혼의 낫: 자루 + 휜 날이 한 바퀴 돌며 벤다 (빔으로 그린 낫, 지나간 자리에 혼빛 획)
	local blade: { { Vector3 } } = {}
	for i = 0, 7 do
		local a1, a2 = i / 8 * 1.6, (i + 1) / 8 * 1.6
		table.insert(blade, { V(math.sin(a1) * r * 0.5, 10 + math.cos(a1) * 4, -r + math.cos(a1) * r * 0.25), V(math.sin(a2) * r * 0.5, 10 + math.cos(a2) * 4, -r + math.cos(a2) * r * 0.25) })
	end
	table.insert(blade, { V(0, 8, 0), V(0, 12, -r) })
	local yaw0 = math.atan2(-look.X, -look.Z)
	beamBeast(blade, function(t)
		if t > 0.75 then
			return nil
		end
		local k = t / 0.75
		return CF(g) * CFrame.Angles(0, yaw0 + k * math.pi * 2, 0)
	end, 0.75, 1, GHOST2, GHOST, { per = 2, w = 2.2, glow = true, amp = 0.6 })
	for i = 1, 16 do
		task.delay(i * 0.045, function()
			local a = yaw0 + i / 16 * math.pi * 2
			local p = g + V(-math.sin(a) * r, 2, -math.cos(a) * r)
			specterFlame(p, 2.2, 0.6)
		end)
	end
	task.delay(0.75, function()
		Fx.ring(g + V(0, 0.5, 0), GHOST, 4, r * 2.2, 0.5)
		Fx.flash(g + V(0, 6, 0), GHOST, r * 2.2, 5, 0.4)
		shake(1.3)
	end)
	shake(0.6)
end

------------------------------------------------------------------------
-- 3.99.47판 겹치던 기술 다섯을 새로: 명경권 · 신 삼재권 초 오의, 운류장 · 철쇄금나수 · 질풍연권 오의
------------------------------------------------------------------------
-- 명경권 천경파쇄: 하늘까지 닿는 거울 벽 → 거울 사이를 튕기는 빛 → 깨지는 거울
VFX.mirrorDome = function(d, c, c2)
	local g = ground(d.at)
	local R = d.radius or 28
	local life = d.life or 2.4
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local at = g + V(math.cos(a) * R, 0, math.sin(a) * R)
		local p0 = piece(V(10, 0.5, 0.6), CFrame.lookAt(at, g) * CF(0, 0.25, 0), WHITE, 0.15)
		p0.Material = Enum.Material.Glass
		p0.Reflectance = 0.9
		tween(p0, 0.35, { Size = V(10, 26, 0.6), CFrame = CFrame.lookAt(at + V(0, 13, 0), g + V(0, 13, 0)) })
		local edge = piece(V(10.4, 0.3, 0.7), CFrame.lookAt(at + V(0, 26, 0), g + V(0, 26, 0)), c2, 0.1)
		task.delay(life, function()
			p0:Destroy()
			fadeOut(edge, 0.2)
		end)
	end
	gSwirl(function()
		return g + V(0, 12, 0)
	end, 14, R * 0.9, 20, life, c, c2, { width = 0.3, trail = 0.6, speed = 0.8 })
	shake(0.5)
end
VFX.mirrorBeam = function(d, c, c2)
	local g = ground(d.from or d.at)
	local at = d.at + V(0, 2, 0)
	-- 거울 셋을 튕겨 날아드는 빛줄기
	local pts = {}
	for i = 1, 3 do
		local a = math.random() * math.pi * 2
		table.insert(pts, g + V(math.cos(a) * 26, 6 + math.random() * 16, math.sin(a) * 26))
	end
	table.insert(pts, at)
	for i = 1, #pts - 1 do
		task.delay((i - 1) * 0.06, function()
			gStroke(pts[i], pts[i + 1], 0.06, 0.6, 0.1, c2, c, true, 0.3)
		end)
	end
	task.delay(0.2, function()
		gEmit(at, TEX_SPARK, c2, c, 14, 0.6, 10, 0.4)
	end)
end
VFX.mirrorShatter = function(d, c, c2)
	local g = ground(d.at)
	local r = d.radius or 28
	for _ = 1, 40 do
		local a = math.random() * math.pi * 2
		local h = math.random() * 24
		local from = g + V(math.cos(a) * r, h, math.sin(a) * r)
		local shard = piece(V(math.random() * 2 + 0.6, math.random() * 3 + 1, 0.15), CF(from) * CFrame.Angles(math.random() * 6, math.random() * 6, 0), WHITE, 0.1)
		shard.Material = Enum.Material.Glass
		shard.Reflectance = 0.8
		tween(shard, 0.7, { Position = g + V(math.cos(a) * r * 0.3, 1, math.sin(a) * r * 0.3) + V((math.random() - 0.5) * 10, 0, (math.random() - 0.5) * 10), Transparency = 1 })
		Debris:AddItem(shard, 0.75)
	end
	gEmit(g + V(0, 6, 0), TEX_SPARK, c2, c, 60, 1, 24, 0.8)
	Fx.ring(g + V(0, 0.5, 0), c2, 4, r * 2.2, 0.5)
	Fx.flash(g + V(0, 8, 0), WHITE, r * 2.4, 6, 0.35)
	pcall(Fx.sound, "shatter", 1, 0.8, g)
	shake(1.2)
end
-- 신 삼재권 천지개벽: 하늘 (빛기둥) → 땅 (갈라져 솟는 땅) → 사람 (거대한 신의 주먹) → 셋이 하나로
VFX.heavenStrike = function(d, c, c2)
	local g = ground(d.at)
	local col: { { Vector3 } } = {}
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		table.insert(col, { V(math.cos(a) * 3, 0, math.sin(a) * 3), V(math.cos(a) * 1.5, 120, math.sin(a) * 1.5) })
	end
	beamBeast(col, function(t)
		return t < 0.5 and CF(g) or nil
	end, 0.5, 1, WHITE, c, { per = 1, w = 2.6, glow = true, amp = 0.4 })
	gEmit(g + V(0, 2, 0), TEX_SPARK, WHITE, c, 30, 1, 14, 0.6)
	Fx.ring(g + V(0, 0.5, 0), c, 2, 20, 0.4)
	shake(0.35)
end
VFX.earthSplit = function(d, c, c2)
	local g = ground(d.at)
	local r = d.radius or 30
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2 + math.random() * 0.3
		local dir = V(math.cos(a), 0, math.sin(a))
		gStroke(g + dir * 2 + V(0, 0.3, 0), g + dir * r + V(0, 0.3, 0), 0.25, 1.2, 0.5, c, c2, true, 0.9)
		for j = 1, 4 do
			task.delay(0.05 * j, function()
				local at = g + dir * (r * j / 5)
				local rock = piece(V(3, 1, 3), CF(at) * CFrame.Angles(0, math.random() * 6, 0), Color3.fromRGB(110, 96, 84), 0)
				rock.Material = Enum.Material.Slate
				tween(rock, 0.18, { Size = V(3, 6 + math.random() * 4, 3), CFrame = CF(at + V(0, 3, 0)) * CFrame.Angles(math.random() * 0.4, math.random() * 6, math.random() * 0.4) })
				task.delay(0.9, function()
					fadeOut(rock, 0.4)
				end)
			end)
		end
	end
	Fx.debris(g, 14, 30, Color3.fromRGB(110, 96, 84))
	shake(1)
end
VFX.manFist = function(d, c, c2)
	local g = ground(d.at)
	local top = g + V(0, 40, 0)
	-- 빛 줄기로 그린 거대한 주먹 (손가락 넷 + 엄지) 이 위에서 내리꽂힌다
	local fist: { { Vector3 } } = {}
	for f = -1.5, 1.5, 1 do
		table.insert(fist, { V(f * 2, 0, 0), V(f * 2, -3, -2) })
	end
	table.insert(fist, { V(-3.5, -1, 1), V(-2, -3, -1) })
	table.insert(fist, { V(-4, 0, 3), V(4, 0, 3) })
	table.insert(fist, { V(0, 0, 3), V(0, 16, 6) })
	beamBeast(fist, function(t)
		if t > 0.32 then
			return nil
		end
		local k = t / 0.3
		return CF(top:Lerp(g + V(0, 4, 0), math.min(1, k * k)))
	end, 0.32, 1.6, c2, c, { per = 2, w = 1.8, glow = true, amp = 0.3 })
	task.delay(0.3, function()
		gEmit(g + V(0, 2, 0), TEX_SPARK, c, c2, 30, 1.2, 18, 0.6)
		Fx.ring(g + V(0, 0.5, 0), c2, 3, 24, 0.4)
		Fx.debris(g, 6, 20)
		shake(0.6)
	end)
end
VFX.sinGenesis = function(d, c, c2)
	local g = ground(d.at)
	local r = d.radius or 34
	gSwirl(function()
		return g + V(0, 6, 0)
	end, 30, r, 10, 0.5, c, c2, { width = 1.6, trail = 0.5, converge = true, speed = 2.4, c3 = WHITE })
	task.delay(0.48, function()
		for i = 1, 3 do
			Fx.ring(g + V(0, 0.5 + i * 3, 0), i == 2 and WHITE or c, 4, r * (1.8 + i * 0.3), 0.5 + i * 0.1)
		end
		gEmit(g + V(0, 6, 0), TEX_SPARK, WHITE, c, 80, 1.4, 34, 1)
		Fx.flash(g + V(0, 10, 0), WHITE, r * 2.6, 7, 0.5)
		shake(1.6)
	end)
end
-- 운류장 만리운해: 구름 소용돌이 → 구름 기둥 → 구름이 한꺼번에 터진다
local function cloudPuffs(at: Vector3, n: number, size: number, spread: number)
	gEmit(at, TEX_SMOKE, WHITE, Color3.fromRGB(220, 230, 245), n, size, spread, 1.2, 0.3, V(0, 1, 0))
end
VFX.cloudVortex = function(d, c, c2)
	local g = ground(d.at) + V(0, 1, 0)
	local r = d.radius or 22
	local life = d.life or 1.7
	gSwirl(function()
		return g
	end, 22, r, 2, life, WHITE, c, { width = 1.6, trail = 0.9, speed = 1, flat = true })
	for i = 1, 6 do
		task.delay(i * life / 7, function()
			local a = math.random() * math.pi * 2
			cloudPuffs(g + V(math.cos(a) * r * 0.7, 1, math.sin(a) * r * 0.7), 6, 4, 3)
		end)
	end
end
VFX.cloudPillar = function(d, c, c2)
	local g = ground(d.at)
	gSerpent(function(u)
		return g + V(math.sin(u * 8) * 1.5, u * 16, math.cos(u * 8) * 1.5)
	end, 0.3, 10, 2.4, WHITE, c, 0.02)
	cloudPuffs(g + V(0, 2, 0), 10, 5, 6)
end
VFX.cloudBurst = function(d, c, c2)
	local g = ground(d.at) + V(0, 3, 0)
	local r = d.radius or 22
	cloudPuffs(g, 40, 7, r * 1.2)
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		gStroke(g, g + V(math.cos(a) * r, math.random() * 6, math.sin(a) * r), 0.25, 1.6, 2, WHITE, c, true, 0.6)
	end
	Fx.ring(ground(d.at) + V(0, 0.5, 0), WHITE, 3, r * 2.2, 0.5)
	shake(0.8)
end
-- 철쇄금나수 천근쇄: 쇠사슬 (빔 고리) 이 날아가 끌어오고 → 휘감아 조이고 → 내리꽂는다
local IRON2, IRONGLOW = Color3.fromRGB(150, 150, 160), Color3.fromRGB(255, 190, 110)
VFX.chainReel = function(d, c, c2)
	local g = ground(d.at) + V(0, 2.5, 0)
	local r = d.radius or 20
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		local far = g + V(math.cos(a) * r, 0, math.sin(a) * r)
		-- 던져 나갔다가 끌려온다
		gStroke(g, far, 0.15, 0.5, 0.4, IRON2, IRONGLOW, true, 0.35)
		task.delay(0.18, function()
			gStroke(far, g, 0.25, 0.5, 0.6, IRON2, IRONGLOW, true, 0.35)
		end)
	end
	pcall(Fx.sound, "block", 0.8, 0.7, g)
end
VFX.chainSpin = function(d, c, c2)
	local g = ground(d.at) + V(0, 2.5, 0)
	gSwirl(function()
		return g
	end, 10, (d.radius or 10) * 0.8, 3, 0.45, IRON2, IRONGLOW, { width = 0.5, trail = 0.3, speed = 4, converge = true })
	gEmit(g, TEX_SPARK, IRONGLOW, WHITE, 10, 0.4, 10, 0.3)
end
VFX.chainSlam = function(d, c, c2)
	local g = ground(d.at)
	gStroke(g + V(0, 22, 0), g + V(0, 0.5, 0), 0.15, 1.2, 0.3, IRON2, IRONGLOW, true, 0.4)
	task.delay(0.15, function()
		Fx.ring(g + V(0, 0.5, 0), IRONGLOW, 3, (d.radius or 14) * 2.2, 0.45)
		Fx.debris(g, 10, 24)
		gEmit(g + V(0, 1, 0), TEX_SPARK, IRONGLOW, WHITE, 30, 0.8, 18, 0.5)
		shake(1)
	end)
end
-- 질풍연권 질풍만영: 바람의 칼날이 가로지르고 → 회오리
VFX.galeSlash = function(d, c, c2)
	local at = d.at + V(0, 2.5, 0)
	local a = math.random() * math.pi * 2
	local dir = V(math.cos(a), (math.random() - 0.5) * 0.4, math.sin(a))
	gStroke(at - dir * 10, at + dir * 10, 0.08, 0.6, 0.6, WHITE, c, true, 0.3)
	gStroke(at - dir * 8 + V(0, 1, 0), at + dir * 8 + V(0, 1, 0), 0.1, 0.3, 0.8, c, c2, true, 0.3)
	gEmit(at, TEX_SPARK, WHITE, c, 6, 0.4, 8, 0.3)
end
VFX.galeTornado = function(d, c, c2)
	local g = ground(d.at)
	gSwirl(function()
		return g
	end, 22, (d.radius or 14) * 0.6, 4, 0.8, WHITE, c, { width = 0.9, trail = 0.5, speed = 3.5, rise = 16, c3 = c2 })
	cloudPuffs(g + V(0, 2, 0), 16, 3, 8)
	Fx.ring(g + V(0, 0.5, 0), c, 2, (d.radius or 14) * 2, 0.4)
	shake(0.7)
end

function ForgeFx.handles(data: any): boolean
	return data.kind == "forgeStart" or data.kind == "forgeStep" or (data.kind == "pulse" and OWN_PULSE[data.fx or ""] == true)
end

function ForgeFx.run(data: any)
	if data.kind == "pulse" then
		local fn = VFX[data.fx or ""]
		if fn and typeof(data.at) == "Vector3" then
			pcall(fn, data, WHITE, WHITE, {})
		end
		return
	end
	if data.kind == "forgeStart" and data.style == "hondon" and (data.mid == "hdG" or data.mid == "hdX") and typeof(data.m) == "Instance" then
		local r0 = data.m:FindFirstChild("HumanoidRootPart")
		local cam = workspace.CurrentCamera
		if r0 and r0:IsA("BasePart") and cam and (cam.CFrame.Position - r0.Position).Magnitude < 120 then
			inkScreen(math.min(data.dur or 2, 3.4))
			shake(0.6)
		end
		if r0 and r0:IsA("BasePart") and data.mid == "hdX" then
			calligraphy(r0.Position + V(0, 55, 0), "混沌", 3.2)
			-- 3.99.52판: 화면 가운데 이름, 등 뒤 하늘에 붓으로 긋는 커다란 원 (끝이 닿지 않는 일원상)
			if cam and (cam.CFrame.Position - r0.Position).Magnitude < 160 then
				domainTitle("천지미분", "하늘과 땅이 나뉘기 전", 2.2)
			end
			local look = r0.CFrame.LookVector
			local flatL = V(look.X, 0, look.Z)
			flatL = flatL.Magnitude > 0.01 and flatL.Unit or V(0, 0, -1)
			local right = V(-flatL.Z, 0, flatL.X)
			local c0 = r0.Position - flatL * 40 + V(0, 52, 0)
			local R0, N = 38, 30
			for i = 0, N - 3 do
				task.delay(i * 0.025, function()
					local a1, a2 = i / N * math.pi * 2 + 1.9, (i + 1) / N * math.pi * 2 + 1.9
					local p1 = c0 + right * math.cos(a1) * R0 + V(0, math.sin(a1) * R0, 0)
					local p2 = c0 + right * math.cos(a2) * R0 + V(0, math.sin(a2) * R0, 0)
					inkStroke(p1, p2, 0.08, 5 - i / N * 3, 0.5, i % 7 == 0)
				end)
			end
			pcall(Fx.sound, "splash", 1, 0.35, r0.Position)
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
