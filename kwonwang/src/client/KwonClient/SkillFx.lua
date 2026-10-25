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
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- 원통을 세운다 (원통의 축은 X)

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal):Play()
end
local function bit(size: Vector3, color: Color3, mat: Enum.Material, alpha: number, life: number, shape: string?): BasePart
	local p: BasePart = shape == "wedge" and Instance.new("WedgePart") or Instance.new("Part")
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
		(p :: Part).Shape = Enum.PartType.Cylinder
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

------------------------------------------------------------------------
-- 2.8판: 모양들을 다시 그렸다. 예전엔 막대·네모·공을 그냥 늘였다 줄여 다 비슷하고 투박해 보였다.
-- 이제 세모 날 (쐐기 둘), 초승달 (휜 조각들), 갈라지는 금, 나선 띠로 모양을 또렷하게 짓는다
------------------------------------------------------------------------
-- 프레임마다 u (0 → 1) 로 부른다
local function anim(life: number, fn: (number) -> ())
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = math.clamp((os.clock() - t0) / life, 0, 1)
		fn(u)
		if u >= 1 then
			conn:Disconnect()
		end
	end)
end
-- 세모 날: cf의 XY 평면에 밑변 (가운데가 cf, 너비 w) 과 꼭짓점 (위로 h). 두께는 Z
type Blade = { a: BasePart, b: BasePart }
local function blade(color: Color3, mat: Enum.Material, alpha: number, life: number): Blade
	return { a = bit(Vector3.one * 0.1, color, mat, alpha, life, "wedge"), b = bit(Vector3.one * 0.1, color, mat, alpha, life, "wedge") }
end
local function placeBlade(bl: Blade, cf: CFrame, w: number, h: number, thick: number?)
	local t = thick or 0.15
	local hw = math.max(0.05, w / 2)
	local hh = math.max(0.05, h)
	bl.a.Size = Vector3.new(t, hh, hw)
	bl.b.Size = Vector3.new(t, hh, hw)
	bl.a.CFrame = cf * CFrame.new(hw / 2, hh / 2, 0) * CFrame.Angles(0, -math.pi / 2, 0)
	bl.b.CFrame = cf * CFrame.new(-hw / 2, hh / 2, 0) * CFrame.Angles(0, math.pi / 2, 0)
end
local function fadeBlade(bl: Blade, alpha: number)
	bl.a.Transparency = alpha
	bl.b.Transparency = alpha
end
-- 초승달: cf의 XY 평면에서 반지름 R, 각 a0 → a1 (가운데가 가장 두껍다)
local function placeArc(list: { BasePart }, cf: CFrame, R: number, a0: number, a1: number, wmax: number, reveal: number?)
	local n = #list
	local show = reveal or 1
	for i, p in ipairs(list) do
		local u = (i - 0.5) / n
		local a = a0 + (a1 - a0) * u
		local w = wmax * (0.15 + 0.85 * math.sin(u * math.pi))
		local pos = Vector3.new(math.cos(a) * R, math.sin(a) * R, 0)
		local tangent = Vector3.new(-math.sin(a), math.cos(a), 0)
		p.Size = Vector3.new(w, 0.12, (a1 - a0) * R / n * 2.2)
		local nrm = Vector3.new(0, 0, 1)
		p.CFrame = cf * CFrame.fromMatrix(pos, nrm:Cross(tangent), nrm, tangent)
		p.Transparency = u <= show and p.Transparency or 1
	end
end
-- 갈라지는 금 (꺾이며 가늘어지는 세 마디). 땅 위 at 에서 방향 a 로
local function crackLine(at: Vector3, a: number, len: number, color: Color3, life: number)
	local pos = at
	local dir = a
	for k = 1, 3 do
		local l = len / 3 * (1.1 - k * 0.12)
		dir += (math.random() - 0.5) * 0.9
		local d = Vector3.new(math.sin(dir), 0, math.cos(dir))
		local seg = bit(Vector3.new((0.55 - k * 0.13), 0.12, 0.2), color, Enum.Material.Neon, 0, life)
		local mid = pos + d * l / 2
		seg.CFrame = CFrame.lookAt(mid, mid + d)
		tween(seg, 0.1 + k * 0.04, { Size = Vector3.new(0.55 - k * 0.13, 0.12, l) })
		task.delay(life * 0.55, function()
			tween(seg, life * 0.4, { Transparency = 1 })
		end)
		pos += d * l
	end
end

P.pillar = function(cf, L, _m, _dur)
	-- 앞의 땅에서 빛기둥이 솟고, 기둥을 감고 오르는 두 줄 띠, 꼭대기에서 사방으로 튀는 날 조각
	local at = (cf * CFrame.new(0, -2.5, -5 * L.s)).Position
	local H = 24 * L.s
	local outer = bit(Vector3.new(1, 4.2 * L.s, 4.2 * L.s), L.c, L.mat, 0.35, 0.55, "cyl")
	local core = bit(Vector3.new(1, 1.4 * L.s, 1.4 * L.s), WHITE, Enum.Material.Neon, 0, 0.5, "cyl")
	local ribbon: { BasePart } = {}
	for i = 1, 16 do
		ribbon[i] = bit(Vector3.new(0.35, 0.35, 1.6) * L.s, i % 2 == 0 and L.c2 or L.c, Enum.Material.Neon, 0.05, 0.6)
	end
	anim(0.5, function(u)
		local grow = math.min(1, u / 0.35)
		local h = math.max(1, H * grow)
		local thin = u < 0.6 and 1 or 1 - (u - 0.6) / 0.4
		outer.Size = Vector3.new(h, 4.2 * L.s * (0.5 + 0.5 * thin), 4.2 * L.s * (0.5 + 0.5 * thin))
		outer.CFrame = CFrame.new(at + Vector3.new(0, h / 2, 0)) * UPRIGHT
		outer.Transparency = 0.35 + 0.65 * (1 - thin)
		core.Size = Vector3.new(h, 1.4 * L.s * thin + 0.05, 1.4 * L.s * thin + 0.05)
		core.CFrame = outer.CFrame
		core.Transparency = 1 - thin
		for i, r in ipairs(ribbon) do
			local strand = i % 2 == 0 and math.pi or 0
			local k = (i - 1) // 2
			local y = (k / 8) * h
			local a = strand + k * 0.85 + u * 10
			local p = at + Vector3.new(math.cos(a) * 2.6 * L.s, y, math.sin(a) * 2.6 * L.s)
			local tan = Vector3.new(-math.sin(a), 0.35, math.cos(a))
			r.CFrame = CFrame.lookAt(p, p + tan)
			r.Transparency = 0.05 + 0.95 * (1 - thin)
		end
	end)
	task.delay(0.16, function()
		local top = at + Vector3.new(0, H, 0)
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			local bl = blade(k % 2 == 0 and L.c or L.c2, Enum.Material.Neon, 0, 0.45)
			local d = Vector3.new(math.cos(a), 0.35, math.sin(a)).Unit
			anim(0.4, function(u)
				local p = top + d * (2 + u * 8) * L.s
				placeBlade(bl, CFrame.lookAt(p, p + d) * CFrame.Angles(math.rad(-90), 0, 0), 1.0 * L.s, (2.4 - u * 1.6) * L.s)
				fadeBlade(bl, u)
			end)
		end
		Fx.ring(top, L.c2, 2, 10 * L.s, 0.35)
	end)
	for k = 0, 5 do
		crackLine(at + Vector3.new(0, 0.1, 0), k / 6 * math.pi * 2, (5 + math.random() * 3) * L.s, L.c, 0.7)
	end
	Fx.ring(at + Vector3.new(0, 0.3, 0), L.c, 2, 13 * L.s, 0.4)
	Fx.dust(at, 2 * L.s)
end
P.wave = function(cf, L, _m, _dur)
	-- 앞으로 밀려가며 앞으로 기우는 초승달 꼴의 물마루 (세모 날 아홉, 가운데가 가장 높다), 마루 끝의 물보라
	for k = -6, 6 do
		local a = k / 6 * 0.8
		local hgt = (5.5 - math.abs(k) * 0.55) * L.s
		-- 물의 몸 (아래의 넓은 벽)과 마루 (겹친 세모 날), 마루 끝의 물보라
		local body = bit(Vector3.one, L.c, L.mat, 0.25, 0.55)
		local bl = blade(k % 2 == 0 and L.c2 or L.c, L.mat, 0.1, 0.55)
		local foam = bit(Vector3.one * 0.9 * L.s, WHITE, Enum.Material.Neon, 0.2, 0.55, "ball")
		anim(0.5, function(u)
			local rise = 0.4 + 0.6 * math.min(1, u * 3)
			local base = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, -2.4, -(3 + u * 14) * L.s) * CFrame.Angles(math.rad(-u * 40), 0, 0)
			body.Size = Vector3.new(2.6 * L.s, hgt * 0.55 * rise, 0.5 * L.s)
			body.CFrame = base * CFrame.new(0, hgt * 0.275 * rise, 0)
			body.Transparency = 0.25 + 0.75 * u ^ 2
			placeBlade(bl, base * CFrame.new(0, hgt * 0.4 * rise, 0), 3.4 * L.s, hgt * 0.6 * rise, 0.3)
			fadeBlade(bl, 0.1 + 0.9 * u ^ 2)
			foam.CFrame = base * CFrame.new(0, hgt * rise, -0.3 * L.s)
			foam.Transparency = 0.2 + 0.8 * u
		end)
	end
	Fx.ring((cf * CFrame.new(0, -2.3, -3)).Position, L.c2, 2, 10 * L.s, 0.4)
end
P.spiral = function(cf, L, m, dur)
	-- 몸을 감고 오르는 두 줄 나선 띠 (구슬 대신 이어진 띠)
	local life = math.min(1.3, dur + 0.2)
	local strands: { { BasePart } } = { {}, {} }
	for s = 1, 2 do
		for i = 1, 24 do
			strands[s][i] = bit(Vector3.new(0.3, 0.3, 1.5) * L.s, s == 1 and L.c or L.c2, Enum.Material.Neon, 0.05, life + 0.1)
		end
	end
	anim(life, function(u)
		local r = rootOf(m)
		if not r then
			return
		end
		for s, list in ipairs(strands) do
			for i, b in ipairs(list) do
				local k = i / #list
				local a = (s == 2 and math.pi or 0) + k * math.pi * 3 + u * 12
				local rad = (2.2 + k * 0.8) * L.s
				local y = -2.4 + math.min(1, k * (0.4 + u * 1.2)) * 6.5 * L.s
				local p = r.Position + Vector3.new(math.cos(a) * rad, y, math.sin(a) * rad)
				local tan = Vector3.new(-math.sin(a), 0.4, math.cos(a))
				b.CFrame = CFrame.lookAt(p, p + tan)
				b.Transparency = math.clamp(u ^ 2 + (1 - k) * 0.3, 0.05, 1)
			end
		end
	end)
end
P.spikes = function(cf, L, _m, _dur)
	-- 앞으로 한 줄로 땅을 뚫고 솟는 가시 여섯 (엇갈린 세모 날 둘이라 어디서 봐도 가시), 발밑마다 금
	for k = 1, 6 do
		task.delay(k * 0.05, function()
			local at = (cf * CFrame.new((k % 2 == 0 and 1 or -1) * 0.9, -2.5, -2.5 - k * 2.6 * L.s)).Position
			local h = (3.5 + k * 0.5) * L.s
			local tilt = CFrame.Angles(math.rad(-12 + math.random() * 8), math.random() * math.pi, math.rad((k % 2 == 0 and 1 or -1) * 10))
			local b1 = blade(k % 2 == 0 and L.c or L.c2, L.mat, 0.05, 0.7)
			local b2 = blade(k % 2 == 0 and L.c or L.c2, L.mat, 0.05, 0.7)
			anim(0.6, function(u)
				local g = u < 0.2 and u / 0.2 or (u < 0.65 and 1 or 1 - (u - 0.65) / 0.35)
				local base = CFrame.new(at) * tilt
				placeBlade(b1, base, 1.5 * L.s, h * g, 0.2)
				placeBlade(b2, base * CFrame.Angles(0, math.pi / 2, 0), 1.5 * L.s, h * g, 0.2)
				local a = u < 0.65 and 0.05 or 0.05 + (u - 0.65) / 0.35
				fadeBlade(b1, a)
				fadeBlade(b2, a)
			end)
			for j = 0, 2 do
				crackLine(at + Vector3.new(0, 0.05, 0), j / 3 * math.pi * 2 + k, 2.5 * L.s, L.c, 0.5)
			end
		end)
	end
end
P.orbit = function(cf, L, m, dur)
	-- 몸 둘레를 도는 구슬 다섯, 구슬마다 꼬리 (지나간 자리에 옅어지는 작은 구슬), 허리의 옅은 고리
	local n = 5
	local life = math.min(1.6, dur + 0.3)
	local orbs: { { BasePart } } = {}
	for i = 1, n do
		local tail = {}
		for j = 0, 4 do
			tail[j + 1] = bit(Vector3.one * (1.3 - j * 0.2) * L.s, j == 0 and (i % 2 == 0 and L.c or L.c2) or L.c, Enum.Material.Neon, 0.05 + j * 0.18, life + 0.1, "ball")
		end
		orbs[i] = tail
	end
	local band = bit(Vector3.new(0.1, 7 * L.s, 7 * L.s), L.c, Enum.Material.Neon, 0.75, life + 0.1, "cyl")
	anim(life, function(u)
		local r = rootOf(m)
		if not r then
			return
		end
		local t = u * life
		local rad = (3 + t * 2) * L.s
		for i, tail in ipairs(orbs) do
			for j, b in ipairs(tail) do
				local a = (t - (j - 1) * 0.035) * 6 + i / n * math.pi * 2
				b.Position = r.Position + Vector3.new(math.cos(a) * rad, math.sin(a * 2) * 0.6, math.sin(a) * rad)
				b.Transparency = math.clamp(u ^ 2 + (j - 1) * 0.18, 0.05, 1)
			end
		end
		band.Size = Vector3.new(0.1, rad * 2, rad * 2)
		band.CFrame = CFrame.new(r.Position) * UPRIGHT
		band.Transparency = 0.75 + 0.25 * u
	end)
end
P.beam = function(cf, L, _m, _dur)
	-- 앞으로 꿰뚫는 빛줄기: 흰 심, 빛깔의 겉, 겉을 감는 두 줄 나선, 끝에서 터지는 빛
	local len = 30 * L.s
	local mid = cf * CFrame.new(0, 0.3, -len / 2 - 1)
	local b = bit(Vector3.new(len, 0.5, 0.5), WHITE, Enum.Material.Neon, 0, 0.45, "cyl")
	b.CFrame = mid * CFrame.Angles(0, math.rad(90), 0)
	local glow = bit(Vector3.new(len, 1.8 * L.s, 1.8 * L.s), L.c, L.mat, 0.35, 0.45, "cyl")
	glow.CFrame = b.CFrame
	tween(b, 0.4, { Size = Vector3.new(len, 0.05, 0.05), Transparency = 1 })
	tween(glow, 0.4, { Size = Vector3.new(len, 3.4 * L.s, 3.4 * L.s), Transparency = 1 })
	local helix: { BasePart } = {}
	for i = 1, 24 do
		helix[i] = bit(Vector3.new(0.22, 0.22, 1.5) * L.s, i % 2 == 0 and L.c2 or L.c, Enum.Material.Neon, 0.1, 0.45)
	end
	anim(0.4, function(u)
		for i, h in ipairs(helix) do
			local strand = i % 2 == 0 and math.pi or 0
			local k = (i - 1) // 2
			local z = -1 - k / 12 * len
			local a = strand + k * 0.9 + u * 8
			local rr = (1.3 + u * 0.8) * L.s
			local hc = cf * CFrame.new(math.cos(a) * rr, 0.3 + math.sin(a) * rr, z)
			h.CFrame = CFrame.lookAt(hc.Position, (hc * CFrame.new(-math.sin(a), math.cos(a), -0.6)).Position)
			h.Transparency = 0.1 + 0.9 * u
		end
	end)
	Fx.ring((cf * CFrame.new(0, 0.3, -2)).Position, L.c, 1, 7 * L.s, 0.3, cf.LookVector)
	local tip = (cf * CFrame.new(0, 0.3, -len - 1)).Position
	Fx.ring(tip, L.c2, 1, 9 * L.s, 0.35, cf.LookVector)
	Fx.spark(tip, L.c, 1.4 * L.s, 12)
end
P.nova = function(cf, L, _m, _dur)
	-- 몸에서 부풀어 터지는 구: 겉껍질, 흰 심, 허리를 두르는 고리, 사방으로 뻗는 빛살 열둘
	local shell = bit(Vector3.one * 2, L.c, L.mat, 0.35, 0.45, "ball")
	shell.Position = cf.Position
	tween(shell, 0.4, { Size = Vector3.one * 18 * L.s, Transparency = 1 })
	local core = bit(Vector3.one * 1, WHITE, Enum.Material.Neon, 0, 0.25, "ball")
	core.Position = cf.Position
	tween(core, 0.2, { Size = Vector3.one * 7 * L.s, Transparency = 1 })
	Fx.ring(cf.Position, L.c2, 2, 20 * L.s, 0.4)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local d = Vector3.new(math.cos(a), (k % 3 - 1) * 0.35, math.sin(a)).Unit
		local ray = bit(Vector3.new(0.3, 0.3, 1) * L.s, k % 2 == 0 and L.c or L.c2, Enum.Material.Neon, 0, 0.35)
		anim(0.32, function(u)
			local len = (2 + u * 8) * L.s
			local p = cf.Position + d * (1.5 * L.s + len / 2 + u * 3 * L.s)
			ray.Size = Vector3.new(0.3 * (1 - u) + 0.05, 0.3 * (1 - u) + 0.05, len)
			ray.CFrame = CFrame.lookAt(p, p + d)
			ray.Transparency = u
		end)
	end
end
P.rain = function(cf, L, _m, _dur)
	-- 앞쪽에 쏟아지는 빛줄기 (밝은 머리와 꼬리), 닿는 자리마다 고리와 튀어 오르는 방울
	local center = (cf * CFrame.new(0, -2.5, -9 * L.s)).Position
	for k = 0, 11 do
		task.delay(k * 0.04, function()
			local at = center + Vector3.new(math.random(-6, 6) * L.s, 0, math.random(-6, 6) * L.s)
			local head = bit(Vector3.one * 0.7, WHITE, Enum.Material.Neon, 0, 0.3, "ball")
			local tail = bit(Vector3.new(0.3, 7, 0.3), k % 2 == 0 and L.c or L.c2, Enum.Material.Neon, 0.15, 0.3)
			anim(0.18, function(u)
				local y = 26 * (1 - u * u) + 2
				head.Position = at + Vector3.new(0, y, 0)
				tail.CFrame = CFrame.new(at + Vector3.new(0, y + 3.6, 0))
			end)
			task.delay(0.18, function()
				head.Transparency = 1
				tail.Transparency = 1
				Fx.ring(at + Vector3.new(0, 0.3, 0), L.c, 0.5, 4.5 * L.s, 0.3)
				for j = 0, 2 do
					local d = bit(Vector3.one * 0.35, L.c2, Enum.Material.Neon, 0, 0.35, "ball")
					local dir = Vector3.new(math.cos(j * 2.1 + k), 0, math.sin(j * 2.1 + k))
					anim(0.3, function(u)
						d.Position = at + dir * u * 2.2 * L.s + Vector3.new(0, 0.3 + math.sin(u * math.pi) * 1.6 * L.s, 0)
						d.Transparency = u
					end)
				end
			end)
		end)
	end
end
P.vortex = function(cf, L, _m, _dur)
	local at = (cf * CFrame.new(0, 0, -6 * L.s)).Position
	for k = 0, 13 do
		local a0 = k / 14 * math.pi * 2
		local seg = bit(Vector3.new(0.3, 0.3, 2.4 * L.s), k % 2 == 0 and L.c or L.c2, L.mat, 0.1, 0.5)
		anim(0.45, function(u)
			local a = a0 + u * 5
			local r = (9 - 8.5 * u) * L.s
			local p = at + Vector3.new(math.cos(a) * r, math.sin(a * 3) * 0.6, math.sin(a) * r)
			seg.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a)))
			seg.Size = Vector3.new(0.3, 0.3, (2.4 - u * 1.4) * L.s)
			seg.Transparency = u
		end)
	end
	task.delay(0.45, function()
		local pop = bit(Vector3.one, WHITE, Enum.Material.Neon, 0, 0.25, "ball")
		pop.Position = at
		tween(pop, 0.22, { Size = Vector3.one * 6 * L.s, Transparency = 1 })
		Fx.ring(at, L.c, 1, 10 * L.s, 0.3)
	end)
end
P.cross = function(cf, L, _m, _dur)
	-- 앞을 엇갈려 가르는 두 초승달 (휘두르는 방향으로 차례로 그려진다), 엇갈린 자리의 불티
	local at = cf * CFrame.new(0, 0.5, -5 * L.s)
	for i, rot in ipairs({ math.rad(45), math.rad(-45) }) do
		task.delay((i - 1) * 0.09, function()
			local list: { BasePart } = {}
			for k = 1, 22 do
				list[k] = bit(Vector3.one * 0.1, i == 1 and L.c2 or L.c, Enum.Material.Neon, 0, 0.4)
			end
			local plane = at * CFrame.Angles(0, 0, rot) * CFrame.new(0, -5 * L.s, 0)
			anim(0.36, function(u)
				local reveal = math.min(1, u / 0.35)
				for _, p in ipairs(list) do
					p.Transparency = u < 0.45 and 0 or (u - 0.45) / 0.55
				end
				placeArc(list, plane, 6.5 * L.s, math.rad(55), math.rad(125), 0.45 * L.s * (1 - u * 0.5), reveal)
			end)
		end)
	end
	Fx.spark(at.Position, L.c, 1.3 * L.s, 12)
end
P.fan = function(cf, L, _m, _dur)
	-- 앞으로 펼쳐지는 부챗살: 누운 세모 날 아홉이 부채처럼 퍼지며 밀려간다
	for k = -4, 4 do
		local a = k / 4 * 1.0
		local bl = blade(k % 2 == 0 and L.c or L.c2, Enum.Material.Neon, 0, 0.4)
		anim(0.35, function(u)
			local base = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.4, -(1.5 + u * 5) * L.s) * CFrame.Angles(math.rad(-90), 0, 0)
			placeBlade(bl, base, (0.9 - u * 0.4) * L.s, (2 + u * 6) * L.s, 0.12)
			fadeBlade(bl, u ^ 1.5)
		end)
	end
	Fx.ring((cf * CFrame.new(0, 0.4, -1.5)).Position, L.c2, 1, 6 * L.s, 0.3, cf.LookVector)
end
P.dome = function(cf, L, _m, dur)
	-- 몸을 덮는 반구: 옅은 껍질, 위도선 셋 (천천히 돈다), 밑둘레의 밝은 고리
	local life = math.clamp(dur, 0.5, 1.2)
	local base = cf.Position - Vector3.new(0, 2, 0)
	local d = bit(Vector3.one * 2, L.c, L.mat, 0.55, life + 0.1, "ball")
	d.Position = base
	tween(d, 0.2, { Size = Vector3.new(12, 9, 12) * L.s })
	local rings: { BasePart } = {}
	for k = 1, 3 do
		rings[k] = bit(Vector3.new(0.12, 1, 1), k == 2 and L.c2 or L.c, Enum.Material.Neon, 0.2, life + 0.1, "cyl")
	end
	anim(life, function(u)
		local g = math.min(1, u / 0.2)
		for k, r in ipairs(rings) do
			local lat = k / 4
			local y = lat * 4.5 * L.s * g
			local rad = 6 * L.s * g * math.sqrt(1 - lat * lat)
			r.Size = Vector3.new(0.12, rad * 2, rad * 2)
			r.CFrame = CFrame.new(base + Vector3.new(0, y, 0)) * CFrame.Angles(0, u * 3 * (k % 2 == 0 and -1 or 1), 0) * UPRIGHT
			r.Transparency = u < 0.75 and 0.2 or 0.2 + (u - 0.75) / 0.25 * 0.8
		end
	end)
	task.delay(life - 0.25, function()
		tween(d, 0.25, { Size = Vector3.new(15, 11, 15) * L.s, Transparency = 1 })
	end)
	Fx.ring(cf.Position - Vector3.new(0, 2.4, 0), L.c2, 6 * L.s, 13 * L.s, life)
end
P.comet = function(cf, L, _m, _dur)
	-- 날아가 터지는 불덩이: 흰 심과 빛깔의 겉, 뒤로 끌리는 가늘어지는 불꼬리 일곱 마디
	local from = (cf * CFrame.new(0.8, 0.5, -1.5)).Position
	local to = (cf * CFrame.new(0, -1.5, -18 * L.s)).Position
	local ball = bit(Vector3.one * 2.4 * L.s, L.c, Enum.Material.Neon, 0, 0.4, "ball")
	local heart = bit(Vector3.one * 1.3 * L.s, WHITE, Enum.Material.Neon, 0, 0.4, "ball")
	local tail: { BasePart } = {}
	for j = 1, 7 do
		tail[j] = bit(Vector3.one * (2.2 - j * 0.26) * L.s, j % 2 == 0 and L.c2 or L.c, Enum.Material.Neon, 0.1 + j * 0.1, 0.4, "ball")
	end
	local dir = (to - from).Unit
	anim(0.25, function(u)
		local e = u * u
		local p = from:Lerp(to, e)
		ball.Position = p
		heart.Position = p
		for j, t in ipairs(tail) do
			t.Position = p - dir * j * 0.9 * L.s
		end
	end)
	task.delay(0.25, function()
		ball.Transparency = 1
		heart.Transparency = 1
		for _, t in ipairs(tail) do
			t.Transparency = 1
		end
		Fx.blast(to, L.c, L.c2, 1.3 * L.s)
		Fx.ring(to - Vector3.new(0, 0.8, 0), L.c2, 1, 12 * L.s, 0.35)
		for k = 0, 5 do
			crackLine(to - Vector3.new(0, 0.9, 0), k / 6 * math.pi * 2, 4 * L.s, L.c, 0.6)
		end
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
	-- 고리 사이를 미끄러지는 빛살 넷
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		local s = bit(Vector3.new(0.2, 0.2, 3) * L.s, L.c2, Enum.Material.Neon, 0, 0.45)
		anim(0.4, function(u)
			local sc = cf * CFrame.new(math.cos(a + u * 3) * 2.2 * L.s, 0.3 + math.sin(a + u * 3) * 2.2 * L.s, -(2 + u * 12) * L.s)
			s.CFrame = CFrame.lookAt(sc.Position, sc.Position + cf.LookVector)
			s.Transparency = u
		end)
	end
end
P.crack = function(cf, L, _m, _dur)
	-- 발밑에서 사방으로 꺾이며 갈라지는 금, 튀어 오르는 돌 조각
	local at = cf.Position - Vector3.new(0, 2.5, 0)
	for k = 0, 9 do
		crackLine(at, k / 10 * math.pi * 2 + math.random() * 0.3, (6 + math.random() * 5) * L.s, k % 2 == 0 and L.c or L.c2, 0.75)
	end
	for k = 0, 5 do
		local rock = bit(Vector3.new(0.9, 0.7, 0.8) * L.s * (0.7 + math.random() * 0.6), Color3.fromRGB(120, 108, 96), Enum.Material.Slate, 0, 0.6)
		local d = Vector3.new(math.cos(k * 1.1), 0, math.sin(k * 1.1))
		local spin = CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		anim(0.55, function(u)
			rock.CFrame = CFrame.new(at + d * (1 + u * 4) * L.s + Vector3.new(0, math.sin(u * math.pi) * 3 * L.s, 0)) * spin * CFrame.Angles(u * 4, u * 3, 0)
			rock.Transparency = u > 0.7 and (u - 0.7) / 0.3 or 0
		end)
	end
	Fx.ring(at + Vector3.new(0, 0.2, 0), L.c, 2, 14 * L.s, 0.4)
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
	chochanghae = { H = "wave" },
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

-- 모양 목록 (시험 화면이 하나씩 그려 보는 데 쓴다)
SkillFx.shapes = P

return SkillFx
