-- 권왕: 관절을 직접 움직이는 몸동작 (모든 화면에서, 모든 무인에게)
-- 로블록스 기본 걷기 동작 위에 권법 자세를 얹고, 기술을 쓰면 온몸을 그 동작으로 덮는다
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Poses = require(ReplicatedStorage:WaitForChild("Poses"))

local Anim = {}

type Track = {
	pose: string,
	keys: { any },
	start: number,
	dur: number,
	align: number?,
	alignFrac: number,
	paused: number, -- 멈춘 시간의 합 (히트스톱)
	freezeUntil: number,
	loop: boolean,
	fadeOut: number,
	weight: number,
}

type Rec = {
	model: Model,
	motors: { [string]: any }, -- Motor6D 또는 AnimationConstraint (둘 다 Transform이 있다)
	track: Track?,
	loop: Track?,
	walk: number,
	npc: boolean,
	guardW: number,
	stanceW: number,
	sprintW: number,
	moveW: number,
	airW: number,
	breath: number,
	idleT: number,
	idleNext: number,
	lastActAt: number,
	lastT: number,
	written: { [string]: CFrame }, -- 지난번에 내가 쓴 값 (기본 동작이 안 건드린 관절을 알아보려고)
}

local recs: { [Model]: Rec } = {}
local RAD = math.pi / 180
local ZERO3 = { 0, 0, 0 }
local ZERO6 = { 0, 0, 0, 0, 0, 0 }

------------------------------------------------------------------------
-- 키프레임 다듬기: 빠진 관절은 그 무인의 기본 자세로 채운다
------------------------------------------------------------------------
local filledCache: { [string]: { any } } = {}

local function basePose(stance: string?): { [string]: { number } }
	local base: { [string]: { number } } = {}
	for name in pairs(Poses.MOTORS) do
		base[name] = name == "R" and ZERO6 or ZERO3
	end
	if stance then
		local st = Poses.stances[stance]
		if st then
			for k, v in pairs(st) do
				base[k] = v
			end
		end
		local legs = Poses.stanceLegs[stance] or Poses.stanceLegs.default
		for k, v in pairs(legs) do
			base[k] = v
		end
	end
	return base
end

local function filled(pose: string, stance: string?): { any }?
	local key = pose .. "|" .. (stance or "")
	local cached = filledCache[key]
	if cached then
		return cached
	end
	local raw = Poses.anims[pose]
	if not raw then
		return nil
	end
	local base = basePose(stance)
	local out = {}
	for _, k in ipairs(raw) do
		local j = {}
		for name in pairs(Poses.MOTORS) do
			local v = k.j[name] or base[name]
			if name == "R" then
				j[name] = { v[1] or 0, v[2] or 0, v[3] or 0, v[4] or 0, v[5] or 0, v[6] or 0 }
			else
				j[name] = { v[1] or 0, v[2] or 0, v[3] or 0 }
			end
		end
		table.insert(out, { t = k.t, e = k.e, j = j })
	end
	filledCache[key] = out
	return out
end

local function firstSnap(keys: { any }): number
	for _, k in ipairs(keys) do
		if k.e == "snap" and k.t > 0 then
			return k.t
		end
	end
	return 0.4
end

local function ease(u: number, kind: string?): number
	if kind == "snap" then
		return 1 - (1 - u) ^ 3
	end
	return u * u * (3 - 2 * u)
end

-- 비율 p(0~1)에서의 관절 값
local function sample(keys: { any }, p: number): { [string]: { number } }
	if p <= keys[1].t or #keys == 1 then
		return keys[1].j
	end
	for i = 2, #keys do
		local b = keys[i]
		if p <= b.t then
			local a = keys[i - 1]
			local u = ease((p - a.t) / math.max(1e-4, b.t - a.t), b.e)
			local out = {}
			for name, va in pairs(a.j) do
				local vb = b.j[name]
				local v = {}
				for n = 1, #va do
					v[n] = va[n] + (vb[n] - va[n]) * u
				end
				out[name] = v
			end
			return out
		end
	end
	return keys[#keys].j
end

local function toCF(name: string, v: { number }): CFrame
	local rot = CFrame.fromEulerAnglesYXZ(v[1] * RAD, v[2] * RAD, v[3] * RAD)
	if name == "R" then
		return CFrame.new(v[4], v[5], v[6]) * rot
	end
	return rot
end

------------------------------------------------------------------------
-- 무인 등록
------------------------------------------------------------------------
-- 관절 찾기: 예전 몸은 Motor6D, 새 로블록스 몸(아바타 관절 업그레이드)은 AnimationConstraint.
-- 둘 다 Transform으로 움직이므로 이름만 맞으면 어느 쪽이든 쓴다
local function isJoint(x: Instance?): boolean
	return x ~= nil and (x:IsA("Motor6D") or x:IsA("AnimationConstraint"))
end
local function motorsOf(model: Model): { [string]: any }
	local m = {}
	for name, info in pairs(Poses.MOTORS) do
		local p = model:FindFirstChild(info[1])
		local motor = p and p:FindFirstChild(info[2])
		if not isJoint(motor) then
			-- 다른 곳에 붙어 있을 수도 있다 (몸 전체에서 같은 이름의 관절)
			motor = nil
			for _, d in ipairs(model:GetDescendants()) do
				if d.Name == info[2] and isJoint(d) then
					motor = d
					break
				end
			end
		end
		if motor then
			m[name] = motor
		end
	end
	return m
end

-- 몸동작이 붙은 관절 수 (화면 점검용)
function Anim.jointCount(model: Model): number
	local n = 0
	for _ in pairs(motorsOf(model)) do
		n += 1
	end
	return n
end

function Anim.watch(model: Model)
	if recs[model] then
		return
	end
	local motors = motorsOf(model)
	if not motors.R or not motors.W then
		-- 아직 몸이 다 안 들어왔다
		task.delay(0.5, function()
			if model.Parent and not recs[model] then
				Anim.watch(model)
			end
		end)
		return
	end
	recs[model] = {
		model = model,
		motors = motors,
		track = nil,
		loop = nil,
		walk = 0,
		npc = model:GetAttribute("NPC") == true,
		guardW = 0,
		stanceW = 0,
		sprintW = 0,
		moveW = 0,
		airW = 0,
		breath = math.random() * 6,
		idleT = 0,
		idleNext = 3 + math.random() * 4,
		lastActAt = 0,
		lastT = os.clock(),
		written = {},
	}
	-- 로블록스 기본 동작(Animate)이 관절을 함께 건드리면 손발이 떨린다: 사람 몸에서도 기본 동작을 끈다
	pcall(function()
		local animate = model:FindFirstChild("Animate")
		if animate and model == Players.LocalPlayer.Character and animate:IsA("LocalScript") then
			animate.Enabled = false
		end
		local hum = model:FindFirstChildOfClass("Humanoid")
		local function hook(animator: Instance)
			if animator:IsA("Animator") then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					track:Stop(0)
				end
				animator.AnimationPlayed:Connect(function(track: AnimationTrack)
					track:Stop(0)
				end)
			end
		end
		if hum then
			local animator = hum:FindFirstChildOfClass("Animator")
			if animator then
				hook(animator)
			end
			hum.ChildAdded:Connect(hook)
		end
	end)
	-- 하늘로 띄워지면 허우적대며 한 바퀴
	model:GetAttributeChangedSignal("LaunchedAt"):Connect(function()
		Anim.play(model, "launched", 0.9)
	end)
end

local function stanceOf(model: Model): string?
	local weapon = model:GetAttribute("Weapon")
	if type(weapon) == "string" then
		return weapon == "spear" and "stance_spear" or "stance_weapon"
	end
	local styleId = model:GetAttribute("Style")
	local style = type(styleId) == "string" and Config.STYLE_BY_ID[styleId]
	return style and style.stance or nil
end

-- 기술 동작 재생. align = 첫 '꽂히는' 순간을 이 초에 맞춘다
function Anim.play(model: Model, pose: string, dur: number, opt: any?)
	Anim.watch(model)
	local rec = recs[model]
	if not rec then
		return
	end
	local keys = filled(pose, stanceOf(model))
	if not keys then
		return
	end
	local o = opt or {}
	if not o.idle then
		rec.lastActAt = os.clock()
	end
	rec.track = {
		pose = pose,
		keys = keys,
		start = os.clock(),
		dur = math.max(0.05, dur),
		align = o.align,
		alignFrac = firstSnap(keys),
		paused = 0,
		freezeUntil = 0,
		loop = false,
		fadeOut = o.fadeOut or 0.12,
		weight = 0,
	}
end

function Anim.stop(model: Model)
	local rec = recs[model]
	if rec then
		rec.track = nil
	end
end

-- 계속 되풀이하는 동작 (명상, 바위 들기). nil이면 끈다
function Anim.setLoop(model: Model, pose: string?, dur: number?)
	Anim.watch(model)
	local rec = recs[model]
	if not rec then
		return
	end
	if not pose then
		rec.loop = nil
		return
	end
	local keys = filled(pose :: string, stanceOf(model))
	if not keys then
		return
	end
	rec.loop = { pose = pose, keys = keys, start = os.clock(), dur = dur or 1.2, align = nil, alignFrac = 0.4, paused = 0, freezeUntil = 0, loop = true, fadeOut = 0, weight = 1 }
end

-- 히트스톱: 잠깐 동작이 멈춘다
function Anim.freeze(model: Model, secs: number)
	local rec = recs[model]
	local tr = rec and rec.track
	if tr then
		tr.freezeUntil = math.max(tr.freezeUntil, os.clock() + secs)
	end
end

function Anim.playing(model: Model): string?
	local rec = recs[model]
	local tr = rec and rec.track
	if tr and os.clock() - tr.start - tr.paused < tr.dur then
		return tr.pose
	end
	return nil
end

------------------------------------------------------------------------
-- 매 순간 (물리 계산 직전: 기본 걷기 동작이 들어간 뒤)
------------------------------------------------------------------------
local function trackPose(tr: Track, t: number, dt: number): ({ [string]: { number } }?, number)
	if t < tr.freezeUntil then
		tr.paused += dt
	end
	local elapsed = t - tr.start - tr.paused
	if tr.loop then
		local p = (elapsed / tr.dur) % 1
		return sample(tr.keys, p), 1
	end
	if elapsed >= tr.dur then
		return nil, 0
	end
	local p
	local a = tr.align
	if a and a > 0 and a < tr.dur then
		if elapsed < a then
			p = elapsed / a * tr.alignFrac
		else
			p = tr.alignFrac + (elapsed - a) / (tr.dur - a) * (1 - tr.alignFrac)
		end
	else
		p = elapsed / tr.dur
	end
	-- 처음엔 재빨리 들어오고, 끝에서 자세로 녹아 돌아간다
	local w = math.min(1, elapsed / 0.05)
	local left = tr.dur - elapsed
	if left < tr.fadeOut then
		w = math.min(w, left / tr.fadeOut)
	end
	return sample(tr.keys, math.clamp(p, 0, 1)), w
end

-- 기본 몸놀림 (사람·적 모두): 가만히 = 가볍게 들썩이는 무인의 호흡, 움직이면 = 걷기·달리기·옆걸음·뒷걸음,
-- 공중 = 오를 땐 무릎을 당기고 내려올 땐 다리를 편다. 관절마다 { X, Y, Z (도), 위치 } 값을 돌려준다
local IDLE: { [string]: { number } } = {
	R = { -2, 0, 0, 0, -0.05, 0 }, W = { 3, 0, 0 }, N = { -3, 0, 0 },
	RS = { 4, 0, 7 }, LS = { 4, 0, -7 }, RE = { 14, 0, 0 }, LE = { 14, 0, 0 },
	RH = { 3, 0, 2 }, LH = { 3, 0, -2 }, RK = { -6, 0, 0 }, LK = { -6, 0, 0 },
}
local function moveJ(name: string, s: number, c: number, f: number, sd: number, amt: number): { number }
	local stride = 40 * amt
	if name == "R" then
		local lean = -(4 + 8 * amt) * math.max(f, 0) + 6 * math.max(-f, 0)
		-- 달릴 때 몸이 좌우로 흔들리지 않게: 걸음마다 옆으로 기울이거나 비틀지 않는다 (옆걸음일 때만 살짝 기운다)
		return { lean, 0, -sd * 6 * amt, 0, -0.12 + math.abs(c) * 0.24 * amt, 0 }
	elseif name == "W" then
		return { 3 * amt, -s * 2 * amt * f, 0 }
	elseif name == "N" then
		return { -3 * amt, 0, sd * 4 }
	elseif name == "RS" then
		return { -s * 44 * amt * f, 0, 9 + math.abs(sd) * 8 }
	elseif name == "LS" then
		return { s * 44 * amt * f, 0, -9 - math.abs(sd) * 8 }
	elseif name == "RE" then
		return { 25 + 40 * amt, 0, 0 }
	elseif name == "LE" then
		return { 25 + 40 * amt, 0, 0 }
	elseif name == "RH" then
		return { s * stride * f, 0, -s * 18 * sd * amt + 3 }
	elseif name == "LH" then
		return { -s * stride * f, 0, s * 18 * sd * amt - 3 }
	elseif name == "RK" then
		return { -(8 + 62 * math.max(0, c)) * amt, 0, 0 }
	elseif name == "LK" then
		return { -(8 + 62 * math.max(0, -c)) * amt, 0, 0 }
	end
	return ZERO3
end
local AIR_UP: { [string]: { number } } = {
	R = { 6, 0, 0, 0, 0.2, 0 }, W = { -4, 0, 0 }, N = { 4, 0, 0 },
	RS = { 40, 0, 35 }, LS = { 40, 0, -35 }, RE = { 50, 0, 0 }, LE = { 50, 0, 0 },
	RH = { 60, 0, 6 }, LH = { 22, 0, -6 }, RK = { -85, 0, 0 }, LK = { -40, 0, 0 },
}
local AIR_DOWN: { [string]: { number } } = {
	R = { -6, 0, 0, 0, 0, 0 }, W = { 6, 0, 0 }, N = { -6, 0, 0 },
	RS = { 20, 0, 50 }, LS = { 20, 0, -50 }, RE = { 30, 0, 0 }, LE = { 30, 0, 0 },
	RH = { 22, 0, 8 }, LH = { -8, 0, -8 }, RK = { -30, 0, 0 }, LK = { -18, 0, 0 },
}

-- 탈것 위: 몸을 굳게 고정한다 (걷기·숨·몸짓·권법 자세 모두 끈다). 말·범·용은 걸터앉아 고삐를, 구름은 뒷짐 지고 선다
local RIDE_SIT: { [string]: { number } } = {
	R = { 0, 0, 0, 0, -0.15, 0 }, W = { 10, 0, 0 }, N = { -8, 0, 0 },
	RS = { 40, 0, 10 }, RE = { 62, 0, 0 }, LS = { 40, 0, -10 }, LE = { 62, 0, 0 },
	RH = { 72, 0, 32 }, RK = { -78, 0, 0 }, LH = { 72, 0, -32 }, LK = { -78, 0, 0 },
}
local RIDE_STAND: { [string]: { number } } = {
	R = { 0, 0, 0, 0, 0, 0 }, W = { 4, 0, 0 }, N = { 4, 0, 0 },
	RS = { -30, 0, -10 }, RE = { 90, 0, 0 }, LS = { -30, 0, 10 }, LE = { 90, 0, 0 },
	RH = { 0, 0, 7 }, RK = { -6, 0, 0 }, LH = { 0, 0, -7 }, LK = { -6, 0, 0 },
}
function Anim.ridePose(kind: string?): { [string]: { number } }?
	if kind == nil then
		return nil
	end
	return kind == "cloud" and RIDE_STAND or RIDE_SIT
end

local IDLE_HAND = { { "idle_shadow", 1.0 }, { "idle_stretch", 1.6 }, { "idle_crack", 1.4 }, { "idle_shift", 0.9 }, { "idle_look", 1.6 } }
local IDLE_WEAPON = { { "idle_weapon", 1.6 }, { "idle_look", 1.6 } }

local function step(dt: number)
	local t = os.clock()
	for model, rec in pairs(recs) do
		if not model.Parent then
			recs[model] = nil
			continue
		end
		local root = model:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			continue
		end
		local motors = rec.motors
		local stance = stanceOf(model)
		local vel = root.AssemblyLinearVelocity
		local flatVel = Vector3.new(vel.X, 0, vel.Z)
		local flatSpeed = flatVel.Magnitude
		local moving = flatSpeed > 2
		local hum = model:FindFirstChildOfClass("Humanoid")
		local inAir = (hum and hum.FloorMaterial == Enum.Material.Air) or math.abs(vel.Y) > 8
		local airborne = inAir and math.abs(vel.Y) > 3
		local dead = model:GetAttribute("Dead") == true
		local guarding = model:GetAttribute("Guard") == true
		local mountId = model:GetAttribute("Mount")
		local mdef = type(mountId) == "string" and Config.MOUNT_BY_ID[mountId] or nil
		local ride = mdef and Anim.ridePose(mdef.kind) or nil

		-- 1) 기술 동작
		local actPose, actW = nil, 0
		local tr = rec.track
		if tr then
			actPose, actW = trackPose(tr, t, dt)
			if not actPose then
				rec.track = nil
			end
		end
		if dead and not actPose then
			-- 쓰러져 있다
			local keys = filled("knockdown", stance)
			if keys then
				actPose, actW = sample(keys, 0.5), 1
			end
		end
		-- 2) 되풀이 동작 (수련)
		local loopPose = nil
		if rec.loop and not actPose then
			loopPose = trackPose(rec.loop, t, dt)
		end

		-- 3) 기본 몸놀림의 무게 (부드럽게 넘어간다)
		local k = math.min(1, dt * 10)
		rec.moveW += (((moving and not airborne) and 1 or 0) - rec.moveW) * k
		rec.airW += ((airborne and 1 or 0) - rec.airW) * math.min(1, dt * 8)
		local amt = math.clamp(flatSpeed / 16, 0, 1.5)
		if moving then
			rec.walk += dt * (5 + flatSpeed * 0.45)
		end
		rec.breath += dt * (guarding and 3.2 or 2.3)
		local s, c = math.sin(rec.walk), math.cos(rec.walk)
		local local3 = root.CFrame:VectorToObjectSpace(flatVel)
		local f = moving and math.clamp(-local3.Z / flatSpeed, -1, 1) or 1
		local sd = moving and math.clamp(local3.X / flatSpeed, -1, 1) or 0
		local b = math.sin(rec.breath)
		local still = (1 - rec.moveW) * (1 - rec.airW)

		-- 4) 권법 자세, 막기, 달리기
		local guardTarget = (guarding and not actPose) and 1 or 0
		rec.guardW += (guardTarget - rec.guardW) * math.min(1, dt * 18)
		local stanceTarget = (stance and not dead) and 1 or 0
		rec.stanceW += (stanceTarget - rec.stanceW) * math.min(1, dt * 8)
		local stanceJ = stance and Poses.stances[stance]
		local legsJ = stance and (Poses.stanceLegs[stance] or Poses.stanceLegs.default)
		local blockJ = filled("block", stance)
		local blockPose = blockJ and blockJ[1].j
		local sprintTarget = (model:GetAttribute("Sprint") == true and moving and not actPose and not guarding and not dead) and 1 or 0
		rec.sprintW += (sprintTarget - rec.sprintW) * math.min(1, dt * 10)
		local sprintJ = Poses.anims.sprint_upper and Poses.anims.sprint_upper[1].j
		local airJ = vel.Y > 0 and AIR_UP or AIR_DOWN

		-- 가만히 서 있으면 가끔 몸짓 (그림자 주먹, 기지개, 손 풀기, 자세 바꾸기, 둘러보기)
		if still > 0.9 and not ride and not actPose and not loopPose and not guarding and not dead and t - rec.lastActAt > 4 and model:GetAttribute("Master") ~= true then
			rec.idleT += dt
			if rec.idleT > rec.idleNext then
				rec.idleT = 0
				rec.idleNext = 4 + math.random() * 5
				local ok = true
				if rec.npc then
					-- 적은 곁에 사람이 없을 때만 (싸우다 딴청 부리지 않게)
					local me = Players.LocalPlayer.Character
					local mr = me and me:FindFirstChild("HumanoidRootPart")
					ok = not (mr and mr:IsA("BasePart") and (mr.Position - root.Position).Magnitude < 30)
				end
				if ok then
					local list = model:GetAttribute("Weapon") and IDLE_WEAPON or IDLE_HAND
					local pick = list[math.random(1, #list)]
					Anim.play(model, pick[1], pick[2], { idle = true, fadeOut = 0.25 })
				end
			end
		else
			rec.idleT = 0
		end

		-- 탈것 위: 굳은 자세 하나만 (기술을 쓰면 서버가 내려 주므로 그때는 기술 동작으로)
		if ride and not dead then
			for name, motor in pairs(motors) do
				local out = toCF(name, ride[name] or (name == "R" and ZERO6 or ZERO3))
				if actPose and actW > 0 then
					out = out:Lerp(toCF(name, actPose[name]), actW)
				end
				motor.Transform = out
				rec.written[name] = out
			end
			continue
		end
		for name, motor in pairs(motors) do
			-- 기본 몸놀림 층: 가만히 → 걷기 → 공중
			local out = toCF(name, IDLE[name] or (name == "R" and ZERO6 or ZERO3))
			if rec.moveW > 0.01 then
				out = out:Lerp(toCF(name, moveJ(name, s, c, f, sd, amt)), rec.moveW)
			end
			if rec.airW > 0.01 then
				out = out:Lerp(toCF(name, airJ[name] or (name == "R" and ZERO6 or ZERO3)), rec.airW)
			end
			-- 권법 자세 (윗몸은 늘, 움직일 땐 팔이 조금 풀린다 / 다리는 서 있을 때만)
			if rec.stanceW > 0.01 and stanceJ then
				local sv = stanceJ[name]
				if Poses.UPPER[name] and sv then
					out = out:Lerp(toCF(name, sv), rec.stanceW * (1 - 0.4 * rec.moveW) * (1 - 0.5 * rec.airW))
				elseif legsJ and legsJ[name] and still > 0.01 then
					out = out:Lerp(toCF(name, legsJ[name]), rec.stanceW * 0.9 * still)
				end
			end
			-- 숨: 서 있을 땐 가볍게 들썩인다 (무릎과 어깨가 함께)
			if still > 0.01 and not actPose then
				if name == "R" then
					out = CFrame.new(0, b * 0.07 * still, 0) * out
				elseif name == "RK" or name == "LK" then
					out = out * CFrame.Angles(-b * 4 * RAD * still, 0, 0)
				elseif name == "W" then
					out = out * CFrame.Angles(b * 1.6 * RAD * still, 0, 0)
				elseif name == "N" then
					out = out * CFrame.Angles(-b * 1.2 * RAD * still, 0, 0)
				end
				-- (어깨는 숨에 맞춰 흔들지 않는다: 손끝이 떨려 보인다)
			end
			if rec.sprintW > 0.01 and sprintJ and sprintJ[name] and (Poses.UPPER[name] or name == "R") then
				out = out:Lerp(toCF(name, sprintJ[name]), rec.sprintW * (name == "R" and 0.6 or 1))
			end
			if rec.guardW > 0.01 and blockPose and (Poses.UPPER[name] or (name == "R" and not moving)) then
				out = out:Lerp(toCF(name, blockPose[name]), rec.guardW)
			end
			if loopPose then
				out = toCF(name, loopPose[name])
			end
			if actPose and actW > 0 then
				out = out:Lerp(toCF(name, actPose[name]), actW)
			end
			motor.Transform = out
			rec.written[name] = out
		end
	end
end

function Anim.start()
	RunService.Stepped:Connect(function(_time: number, dt: number)
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[권왕] 몸동작 오류:", err)
		end
	end)
end

return Anim
