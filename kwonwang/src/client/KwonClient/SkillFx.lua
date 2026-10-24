-- 권왕 1.8: 기술마다 다른 이펙트 (수치·연출은 그대로, 보이는 모양만)
-- 예전엔 모든 기술에 같은 틀 (발밑 진·고리·초승달) 이 붙어 다 비슷해 보였다. 그 틀을 없애고,
-- Fx.cast 에 따로 만든 이펙트가 없던 (속성·칸) 마다 서로 다른 모양을 하나씩 준다.
--   pillar  앞에서 솟는 기둥        wave   앞으로 밀려가는 휜 벽     spiral 몸을 감고 오르는 두 줄 나선
--   spikes  앞으로 한 줄로 솟는 가시  orbit  몸 둘레를 도는 구슬       beam   앞으로 꿰뚫는 빛줄기
--   nova    몸에서 부풀어 터지는 구   rain   앞쪽에 쏟아지는 빗줄기     vortex 앞의 한 점으로 말려드는 고리
--   cross   앞을 엇갈려 가르는 두 칼  fan    앞으로 펼쳐지는 부챗살     dome   몸을 덮는 반구
--   comet   날아가 터지는 불덩이      tunnel 앞으로 미끄러지는 세 겹 고리  crack  발밑에서 사방으로 갈라지는 땅
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local SkillFx = {}

local folder = Instance.new("Folder")
folder.Name = "KwonSkillFx"
folder.Parent = workspace

local WHITE = Color3.new(1, 1, 1)

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal):Play()
end
local function bit(size: Vector3, color: Color3, mat: Enum.Material, alpha: number, life: number, shape: string?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = mat
	p.Transparency = alpha
	if shape == "ball" then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	elseif shape == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Parent = folder
	task.delay(life + 0.05, function()
		p:Destroy()
	end)
	return p
end
local function rootOf(m: Instance?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end
local function near(pos: Vector3, d: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude < d
end

type Look = { c: Color3, c2: Color3, mat: Enum.Material, s: number }

------------------------------------------------------------------------
-- 모양들 (cf = 몸 가운데, 앞이 -Z)
------------------------------------------------------------------------
local P: { [string]: (CFrame, Look, Model, number) -> () } = {}

P.pillar = function(cf, L, _m, _dur)
	local at = (cf * CFrame.new(0, -2.5, -5 * L.s)).Position
	local col = bit(Vector3.new(1, 4 * L.s, 4 * L.s), L.c, L.mat, 0.15, 0.45, "cyl")
	col.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	tween(col, 0.3, { Size = Vector3.new(26 * L.s, 2 * L.s, 2 * L.s), CFrame = CFrame.new(at + Vector3.new(0, 13 * L.s, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(0.3, function()
		tween(col, 0.15, { Transparency = 1 })
	end)
	for k = 0, 2 do
		task.delay(k * 0.07, function()
			Fx.ring(at + Vector3.new(0, 1 + k * 5 * L.s, 0), k == 1 and L.c2 or L.c, 2, (12 - k * 3) * L.s, 0.35)
		end)
	end
	Fx.dust(at, 2 * L.s)
end
P.wave = function(cf, L, _m, _dur)
	for k = -5, 5 do
		local a = k / 5 * 0.9
		local seg = bit(Vector3.new(2.2 * L.s, 5 * L.s * (1 - math.abs(k) / 8), 0.5), k % 2 == 0 and L.c or L.c2, L.mat, 0.1, 0.5)
		local lp = CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -3)
		seg.CFrame = cf * lp
		tween(seg, 0.45, { CFrame = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.5, -16 * L.s), Transparency = 1 })
	end
end
P.spiral = function(cf, L, m, dur)
	local list = {}
	for i = 1, 16 do
		list[i] = bit(Vector3.one * 0.8 * L.s, i % 2 == 0 and L.c or L.c2, L.mat, 0.1, math.min(1.4, dur + 0.3), "ball")
	end
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local r = rootOf(m)
		if t > math.min(1.3, dur + 0.2) or not r then
			conn:Disconnect()
			return
		end
		for i, b in ipairs(list) do
			local strand = i % 2 == 0 and math.pi or 0
			local k = (i - 1) // 2
			local a = t * 9 + k * 0.8 + strand
			local y = -2.4 + ((k / 8 + t * 1.4) % 1) * 6 * L.s
			b.Position = r.Position + Vector3.new(math.cos(a) * 2.6 * L.s, y, math.sin(a) * 2.6 * L.s)
			b.Transparency = math.clamp(t / 1.3, 0.1, 1)
		end
	end)
end
P.spikes = function(cf, L, _m, _dur)
	for k = 1, 6 do
		task.delay(k * 0.05, function()
			local at = (cf * CFrame.new((k % 2 == 0 and 1 or -1) * 0.8, -2.6, -2.5 - k * 2.6 * L.s)).Position
			local sp = bit(Vector3.new(1.2, 0.4, 1.2) * L.s, k % 2 == 0 and L.c or L.c2, L.mat, 0.05, 0.6)
			sp.CFrame = CFrame.new(at) * CFrame.Angles(math.rad(10), k, math.rad(-10))
			tween(sp, 0.12, { Size = Vector3.new(1.4 * L.s, (4 + k * 0.6) * L.s, 1.4 * L.s), CFrame = sp.CFrame * CFrame.new(0, (2 + k * 0.3) * L.s, 0) })
			task.delay(0.35, function()
				tween(sp, 0.2, { Transparency = 1, Size = sp.Size * Vector3.new(0.5, 0.2, 0.5) })
			end)
		end)
	end
end
P.orbit = function(cf, L, m, dur)
	local n = 6
	local list = {}
	for i = 1, n do
		list[i] = bit(Vector3.one * 1.3 * L.s, i % 2 == 0 and L.c or L.c2, L.mat, 0.05, math.min(1.6, dur + 0.4), "ball")
	end
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local r = rootOf(m)
		local life = math.min(1.5, dur + 0.3)
		if t > life or not r then
			conn:Disconnect()
			return
		end
		local rad = (3 + t * 2) * L.s
		for i, b in ipairs(list) do
			local a = t * 6 + i / n * math.pi * 2
			b.Position = r.Position + Vector3.new(math.cos(a) * rad, math.sin(a * 2) * 0.6, math.sin(a) * rad)
			b.Transparency = math.clamp((t / life) ^ 2, 0.05, 1)
		end
	end)
end
P.beam = function(cf, L, _m, _dur)
	local len = 30 * L.s
	local mid = cf * CFrame.new(0, 0.3, -len / 2 - 1)
	local b = bit(Vector3.new(len, 0.4, 0.4), L.c2, Enum.Material.Neon, 0, 0.4, "cyl")
	b.CFrame = mid * CFrame.Angles(0, math.rad(90), 0)
	local glow = bit(Vector3.new(len, 1.6 * L.s, 1.6 * L.s), L.c, L.mat, 0.4, 0.4, "cyl")
	glow.CFrame = b.CFrame
	tween(b, 0.35, { Size = Vector3.new(len, 0.05, 0.05), Transparency = 1 })
	tween(glow, 0.35, { Size = Vector3.new(len, 3.2 * L.s, 3.2 * L.s), Transparency = 1 })
	Fx.ring((cf * CFrame.new(0, 0.3, -2)).Position, L.c, 1, 7 * L.s, 0.3, cf.LookVector)
end
P.nova = function(cf, L, _m, _dur)
	local shell = bit(Vector3.one * 2, L.c, L.mat, 0.35, 0.45, "ball")
	shell.Position = cf.Position
	tween(shell, 0.4, { Size = Vector3.one * 18 * L.s, Transparency = 1 })
	local core = bit(Vector3.one * 1, WHITE, Enum.Material.Neon, 0, 0.25, "ball")
	core.Position = cf.Position
	tween(core, 0.2, { Size = Vector3.one * 7 * L.s, Transparency = 1 })
end
P.rain = function(cf, L, _m, _dur)
	local center = (cf * CFrame.new(0, -2.5, -9 * L.s)).Position
	for k = 0, 11 do
		task.delay(k * 0.04, function()
			local at = center + Vector3.new(math.random(-6, 6) * L.s, 0, math.random(-6, 6) * L.s)
			local d = bit(Vector3.new(0.3, 6, 0.3), k % 2 == 0 and L.c or L.c2, Enum.Material.Neon, 0.1, 0.3)
			d.Position = at + Vector3.new(0, 26, 0)
			tween(d, 0.18, { Position = at + Vector3.new(0, 3, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.18, function()
				d.Transparency = 1
				Fx.ring(at + Vector3.new(0, 0.3, 0), L.c, 0.5, 4 * L.s, 0.25)
			end)
		end)
	end
end
P.vortex = function(cf, L, _m, _dur)
	local at = (cf * CFrame.new(0, 0, -6 * L.s)).Position
	for k = 0, 13 do
		local a0 = k / 14 * math.pi * 2
		local seg = bit(Vector3.new(0.3, 0.3, 2.4 * L.s), k % 2 == 0 and L.c or L.c2, L.mat, 0.1, 0.5)
		local t0 = os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local t = os.clock() - t0
			if t > 0.45 or not seg.Parent then
				conn:Disconnect()
				return
			end
			local u = t / 0.45
			local a = a0 + u * 5
			local r = (9 - 8.5 * u) * L.s
			local p = at + Vector3.new(math.cos(a) * r, math.sin(a * 3) * 0.6, math.sin(a) * r)
			seg.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a)))
			seg.Transparency = u
		end)
	end
	task.delay(0.45, function()
		local pop = bit(Vector3.one, WHITE, Enum.Material.Neon, 0, 0.25, "ball")
		pop.Position = at
		tween(pop, 0.22, { Size = Vector3.one * 6 * L.s, Transparency = 1 })
	end)
end
P.cross = function(cf, L, _m, _dur)
	local at = cf * CFrame.new(0, 0.5, -5 * L.s)
	for i, a in ipairs({ math.rad(45), math.rad(-45) }) do
		task.delay((i - 1) * 0.08, function()
			local blade = bit(Vector3.new(0.3, 0.3, 0.6), i == 1 and L.c2 or L.c, Enum.Material.Neon, 0, 0.35)
			blade.CFrame = at * CFrame.Angles(0, 0, a) * CFrame.Angles(0, math.rad(90), 0)
			tween(blade, 0.12, { Size = Vector3.new(0.25, 0.25, 14 * L.s) })
			task.delay(0.14, function()
				tween(blade, 0.2, { Size = Vector3.new(0.05, 1.6 * L.s, 15 * L.s), Transparency = 1 })
			end)
		end)
	end
	Fx.spark(at.Position, L.c, 1.2 * L.s, 10)
end
P.fan = function(cf, L, _m, _dur)
	for k = -6, 6 do
		local a = k / 6 * 1.1
		local ray = bit(Vector3.new(0.25, 0.25, 0.5), k % 2 == 0 and L.c or L.c2, Enum.Material.Neon, 0, 0.35)
		local base = cf * CFrame.Angles(0, a, 0)
		ray.CFrame = base * CFrame.new(0, 0.6, -1.5)
		tween(ray, 0.3, { CFrame = base * CFrame.new(0, 0.6, -7 * L.s), Size = Vector3.new(0.1, 0.1, 9 * L.s), Transparency = 1 })
	end
end
P.dome = function(cf, L, _m, dur)
	local life = math.clamp(dur, 0.5, 1.2)
	local d = bit(Vector3.one * 2, L.c, L.mat, 0.5, life + 0.1, "ball")
	d.Position = cf.Position - Vector3.new(0, 2, 0)
	tween(d, 0.2, { Size = Vector3.new(12, 9, 12) * L.s })
	task.delay(life - 0.25, function()
		tween(d, 0.25, { Size = Vector3.new(15, 11, 15) * L.s, Transparency = 1 })
	end)
	Fx.ring(cf.Position - Vector3.new(0, 2.4, 0), L.c2, 6 * L.s, 13 * L.s, life)
end
P.comet = function(cf, L, _m, _dur)
	local from = (cf * CFrame.new(0.8, 0.5, -1.5)).Position
	local to = (cf * CFrame.new(0, -1.5, -18 * L.s)).Position
	local ball = bit(Vector3.one * 2.2 * L.s, L.c, Enum.Material.Neon, 0, 0.4, "ball")
	ball.Position = from
	local trail = bit(Vector3.new(0.6, 0.6, 1), L.c2, Enum.Material.Neon, 0.3, 0.4)
	trail.CFrame = CFrame.lookAt(from, to)
	tween(ball, 0.25, { Position = to }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(trail, 0.25, { CFrame = CFrame.lookAt((from + to) / 2, to), Size = Vector3.new(0.2, 0.2, (to - from).Magnitude), Transparency = 0.8 })
	task.delay(0.25, function()
		ball.Transparency = 1
		trail.Transparency = 1
		Fx.blast(to, L.c, L.c2, 1.3 * L.s)
		Fx.ring(to - Vector3.new(0, 0.8, 0), L.c2, 1, 12 * L.s, 0.35)
	end)
end
P.tunnel = function(cf, L, _m, _dur)
	for k = 0, 2 do
		task.delay(k * 0.07, function()
			local ring = bit(Vector3.new(0.3, 4 * L.s, 4 * L.s), k == 1 and L.c2 or L.c, L.mat, 0.2, 0.45, "cyl")
			ring.CFrame = cf * CFrame.new(0, 0.3, -2) * CFrame.Angles(0, math.rad(90), 0)
			tween(ring, 0.4, { CFrame = cf * CFrame.new(0, 0.3, -14 * L.s) * CFrame.Angles(0, math.rad(90), 0), Size = Vector3.new(0.1, 8 * L.s, 8 * L.s), Transparency = 1 })
		end)
	end
end
P.crack = function(cf, L, _m, _dur)
	local at = cf.Position - Vector3.new(0, 2.5, 0)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2 + math.random() * 0.3
		local len = (6 + math.random() * 5) * L.s
		local c = bit(Vector3.new(0.5, 0.2, 0.2), k % 2 == 0 and L.c or L.c2, Enum.Material.Neon, 0, 0.7)
		local base = CFrame.new(at) * CFrame.Angles(0, a, 0)
		c.CFrame = base * CFrame.new(0, 0, -0.5)
		tween(c, 0.15, { CFrame = base * CFrame.new(0, 0, -len / 2), Size = Vector3.new(0.45, 0.2, len) })
		task.delay(0.4, function()
			tween(c, 0.3, { Transparency = 1 })
		end)
	end
	Fx.dust(at, 2.5 * L.s)
end

------------------------------------------------------------------------
-- 속성마다 강타 (H) · E · R 의 모양과 재질 (한 권법 안에서 셋이 서로 다르다)
------------------------------------------------------------------------
local PLAN: { [string]: { [string]: string } } = {
	celestial = { E = "fan", R = "comet" },
	cloud = { H = "nova", E = "orbit", R = "wave" },
	duel = { H = "cross", E = "spikes", R = "tunnel" },
	eclipse = { H = "dome", E = "orbit", R = "beam" },
	fire = { H = "pillar", E = "wave", R = "comet" },
	galaxy = { H = "vortex", E = "spiral", R = "rain" },
	gravity = { H = "crack", E = "vortex", R = "dome" },
	ocean = { H = "wave", E = "spiral", R = "tunnel" },
	origin = { H = "beam", E = "fan", R = "pillar" },
	subspace = { H = "cross", E = "nova", R = "tunnel" },
	time = { H = "crack", E = "orbit", R = "rain" },
	wind = { R = "spiral" },
}
-- 1.9판: 권법마다 따로 (같은 속성이라도 각성 권법은 모양이 다르다)
local PLAN_STYLE: { [string]: { [string]: string } } = {
	geumgang2 = { H = "crack", E = "dome", R = "spikes" },
	muyeong2 = { H = "fan", E = "cross", R = "vortex" },
	taeheo2 = { H = "nova", E = "wave", R = "spiral" },
	yeolhwa2 = { H = "comet", E = "spikes", R = "pillar" },
	changhae2 = { H = "tunnel", E = "wave", R = "spiral" },
	pungsin2 = { H = "fan", E = "cross", R = "spiral" },
	chobyeok = { H = "cross", E = "beam", R = "rain" },
	manmok = { H = "crack" },
}
local MAT: { [string]: Enum.Material } = {
	nature = Enum.Material.Grass,
	cloud = Enum.Material.SmoothPlastic,
	ocean = Enum.Material.Glass,
	subspace = Enum.Material.Glass,
	duel = Enum.Material.Metal,
	gravity = Enum.Material.Neon,
	geumgang2 = Enum.Material.Foil,
	taeheo2 = Enum.Material.Glass,
}

function SkillFx.cast(styleId: any, slot: any, model: Model, dur: number)
	local style = type(styleId) == "string" and Config.STYLE_BY_ID[styleId] or nil
	if not style or (slot ~= "H" and slot ~= "E" and slot ~= "R") then
		return
	end
	local plan = PLAN_STYLE[style.id] or PLAN[style.fx]
	local shape = plan and plan[slot]
	local fn = shape and P[shape]
	local r = rootOf(model)
	if not fn or not r or not near(r.Position, 180) then
		return
	end
	local L: Look = { c = style.color, c2 = style.color2, mat = MAT[style.id] or MAT[style.fx] or Enum.Material.Neon, s = slot == "H" and 0.9 or 1.15 }
	task.delay(math.min(0.15, dur * 0.3), function()
		local rr = rootOf(model)
		if not rr then
			return
		end
		local look = Vector3.new(rr.CFrame.LookVector.X, 0, rr.CFrame.LookVector.Z)
		look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
		fn(CFrame.lookAt(rr.Position, rr.Position + look), L, model, dur)
	end)
end

return SkillFx
