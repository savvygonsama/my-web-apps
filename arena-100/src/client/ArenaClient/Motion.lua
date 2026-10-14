-- Motion (ModuleScript, ArenaClient 아래)
-- 애니메이션 파일 없이 관절(Motor6D)을 매 프레임 직접 움직이는 동작.
--   내 캐릭터: 무기별 전투 자세, 무기별 3단 콤보, 구르기 회피, 스킬·필살기 자세, 맞으면 움찔, 승리 포즈
--   적: 공격 직전 팔을 들었다가 내려치기, 시전, 돌진 자세, 맞으면 뒤로 젖혀짐
-- 기본 걷기 애니메이션 위에 덧입혀서, 걸으면서 베는 것도 자연스럽다.

local RunService = game:GetService("RunService")

local Motion = {}

-- 짧은 이름 → R15 관절 이름
local JOINT_NAMES = {
	R = "Root",
	W = "Waist",
	N = "Neck",
	RS = "RightShoulder",
	RE = "RightElbow",
	RW = "RightWrist",
	LS = "LeftShoulder",
	LE = "LeftElbow",
	LW = "LeftWrist",
	RH = "RightHip",
	RK = "RightKnee",
	LH = "LeftHip",
	LK = "LeftKnee",
}
local JOINT_PARTS = {
	Root = "LowerTorso",
	Waist = "UpperTorso",
	Neck = "Head",
	RightShoulder = "RightUpperArm",
	RightElbow = "RightLowerArm",
	RightWrist = "RightHand",
	LeftShoulder = "LeftUpperArm",
	LeftElbow = "LeftLowerArm",
	LeftWrist = "LeftHand",
	RightHip = "RightUpperLeg",
	RightKnee = "RightLowerLeg",
	LeftHip = "LeftUpperLeg",
	LeftKnee = "LeftLowerLeg",
}
local KEYS = { "R", "W", "N", "RS", "RE", "RW", "LS", "LE", "LW", "RH", "RK", "LH", "LK" }

-- 자세: { 관절 = { rx, ry, rz, px, py, pz } } (도, 스터드)
type Pose = { [string]: { number } }
type Key = { t: number, pose: Pose }
type Clip = { dur: number, hit: number, keys: { Key }, hold: boolean? }

local ZERO6 = { 0, 0, 0, 0, 0, 0 }

local function get(pose: Pose, k: string): { number }
	return pose[k] or ZERO6
end

-- 부드럽게 (앞뒤로 천천히)
local function smooth(x: number): number
	return x * x * (3 - 2 * x)
end

-- 각도를 -180~180으로 (360도 회전이 끝나면 0과 같다)
local function wrap(a: number): number
	return ((a + 180) % 360) - 180
end

local function samplePose(clip: Clip, t: number, out: { [string]: { number } })
	local keys = clip.keys
	local a, b = keys[1], keys[#keys]
	for i = 1, #keys - 1 do
		if t >= keys[i].t and t <= keys[i + 1].t then
			a, b = keys[i], keys[i + 1]
			break
		end
	end
	local span = b.t - a.t
	local f = span > 0 and smooth(math.clamp((t - a.t) / span, 0, 1)) or 1
	for _, k in ipairs(KEYS) do
		local va, vb = get(a.pose, k), get(b.pose, k)
		local v = out[k]
		for c = 1, 6 do
			local x = (va[c] or 0) + ((vb[c] or 0) - (va[c] or 0)) * f
			v[c] = c <= 3 and wrap(x) or x
		end
	end
end

local function newPose(): { [string]: { number } }
	local p = {}
	for _, k in ipairs(KEYS) do
		p[k] = { 0, 0, 0, 0, 0, 0 }
	end
	return p
end

------------------------------------------------------------------------
-- 전투 자세 (무기별)
------------------------------------------------------------------------
local STANCES: { [number]: Pose } = {
	[1] = { RS = { 40, 0, 15 }, RE = { 50 }, LS = { 45, 0, -25 }, LE = { 60 }, W = { 0, -15, 0 }, R = { -4, 0, 0, 0, -0.15, 0 }, RH = { 10 }, RK = { -15 }, LH = { -5 }, LK = { -10 } },
	[2] = { RS = { 35, 0, 22 }, RE = { 40 }, LS = { 35, 0, -22 }, LE = { 40 }, R = { -6, 0, 0, 0, -0.2, 0 }, RH = { 15 }, RK = { -20 }, LH = { 10 }, LK = { -18 } },
	[3] = { RS = { 25, 0, 25 }, RE = { 35 }, LS = { 15, 0, -15 }, LE = { 20 }, W = { 0, -20, 0 }, RH = { 8 }, RK = { -10 } },
	[4] = { RS = { 20, 0, 25 }, RE = { 70 }, LS = { 40, 0, -20 }, LE = { 70 }, R = { -12, 0, 0, 0, -0.35, 0 }, RH = { 28 }, RK = { -38 }, LH = { 22 }, LK = { -32 } },
	[5] = { RS = { 60, 0, 10 }, RE = { 20 }, LS = { 50, 0, -10 }, LE = { 50 }, W = { 0, -25, 0 }, RH = { 8 }, RK = { -12 } },
}
STANCES[0] = STANCES[1]

------------------------------------------------------------------------
-- 무기별 3단 콤보
------------------------------------------------------------------------
local function clip(dur: number, hit: number, keys: { Key }): Clip
	return { dur = dur, hit = hit, keys = keys }
end
local function k(t: number, pose: Pose): Key
	return { t = t, pose = pose }
end

local GS_CHOP = clip(0.45, 0.38, {
	k(0, {}),
	k(0.22, { RS = { 170, 0, 10 }, RE = { 20 }, LS = { 160, 0, -10 }, LE = { 20 }, W = { 12, -5, 0 }, N = { 8 } }),
	k(0.38, { RS = { 25, 0, 5 }, RE = { 10 }, LS = { 30, 0, -5 }, LE = { 20 }, W = { -25, 0, 0 }, N = { -10 }, R = { -8, 0, 0, 0, -0.5, 0 }, RH = { 40 }, RK = { -50 }, LH = { -20 }, LK = { -10 } }),
	k(0.7, { RS = { 30, 0, 5 }, RE = { 15 }, LS = { 35, 0, -5 }, LE = { 25 }, W = { -18, 0, 0 }, R = { -6, 0, 0, 0, -0.4, 0 }, RH = { 30 }, RK = { -40 } }),
	k(1, {}),
})
local GS_SWEEP = clip(0.45, 0.38, {
	k(0, {}),
	k(0.2, { W = { 0, -60, 0 }, RS = { 80, 0, 80 }, RE = { 30 }, LS = { 70, 0, 30 }, LE = { 60 }, R = { 0, -15, 0 } }),
	k(0.38, { W = { 0, 55, 0 }, RS = { 85, 0, -10 }, RE = { 5 }, LS = { 70, 0, -40 }, LE = { 20 }, R = { 0, 25, 0, 0, -0.2, 0 }, RH = { 20 }, RK = { -30 } }),
	k(0.7, { W = { 0, 45, 0 }, RS = { 80, 0, -5 }, LS = { 60, 0, -30 }, R = { 0, 20, 0 } }),
	k(1, {}),
})
local GS_SPIN = clip(0.6, 0.55, {
	k(0, {}),
	k(0.18, { R = { 0, 0, 0, 0, -0.6, 0 }, RS = { 90, 0, 90 }, LS = { 70, 0, -40 }, W = { 0, -40, 0 }, RH = { 50 }, RK = { -70 }, LH = { 40 }, LK = { -60 } }),
	k(0.55, { R = { 0, 360, 0, 0, 1.1, 0 }, RS = { 90, 0, 90 }, LS = { 90, 0, -90 }, W = { 0, 20, 0 }, RH = { 30 }, LH = { -10 } }),
	k(0.75, { R = { -10, 360, 0, 0, -0.5, 0 }, RS = { 40, 0, 10 }, LS = { 40, 0, -10 }, W = { -20, 0, 0 }, RH = { 45 }, RK = { -60 } }),
	k(1, { R = { 0, 360, 0 } }),
})
local DU_RIGHT = clip(0.3, 0.42, {
	k(0, {}),
	k(0.22, { RS = { 150, 0, 50 }, RE = { 30 }, W = { 0, -25, 0 } }),
	k(0.42, { RS = { 20, 0, -30 }, RE = { 10 }, W = { 0, 30, 0 }, LS = { 40, 0, -30 }, R = { -6, 0, 0, 0, -0.2, 0 } }),
	k(1, {}),
})
local DU_LEFT = clip(0.3, 0.42, {
	k(0, {}),
	k(0.22, { LS = { 150, 0, -50 }, LE = { 30 }, W = { 0, 25, 0 } }),
	k(0.42, { LS = { 20, 0, 30 }, LE = { 10 }, W = { 0, -30, 0 }, RS = { 10, 0, 40 }, R = { -6, 0, 0, 0, -0.2, 0 } }),
	k(1, {}),
})
local DU_CROSS = clip(0.4, 0.42, {
	k(0, {}),
	k(0.22, { RS = { 165, 0, 40 }, LS = { 165, 0, -40 }, W = { 10, 0, 0 }, R = { 0, 0, 0, 0, 0.3, 0 } }),
	k(0.42, { RS = { 40, 0, -50 }, LS = { 40, 0, 50 }, W = { -20, 0, 0 }, R = { -10, 0, 0, 0, -0.45, 0 }, RH = { 40 }, RK = { -55 }, LH = { 30 }, LK = { -45 } }),
	k(0.75, { RS = { 45, 0, -40 }, LS = { 45, 0, 40 }, W = { -12, 0, 0 }, R = { -6, 0, 0, 0, -0.3, 0 } }),
	k(1, {}),
})
local LS_THRUST = clip(0.42, 0.4, {
	k(0, {}),
	k(0.22, { RS = { 70, 0, 10 }, RE = { 110 }, W = { 0, -35, 0 }, R = { 0, -10, 0 } }),
	k(0.4, { RS = { 90, 0, 0 }, RE = { 0 }, W = { -10, 25, 0 }, R = { -12, 10, 0, 0, -0.35, 0 }, RH = { 50 }, RK = { -35 }, LH = { -30 }, LK = { -10 }, LS = { 0, 0, -40 } }),
	k(0.75, { RS = { 85, 0, 0 }, RE = { 10 }, W = { -6, 15, 0 }, R = { -8, 5, 0, 0, -0.25, 0 }, RH = { 35 } }),
	k(1, {}),
})
local LS_RISE = clip(0.42, 0.4, {
	k(0, {}),
	k(0.22, { RS = { -20, 0, 30 }, RE = { 10 }, W = { 0, -20, 0 }, R = { 0, 0, 0, 0, -0.45, 0 }, RH = { 40 }, RK = { -60 } }),
	k(0.4, { RS = { 170, 0, 20 }, RE = { 10 }, W = { 15, 20, 0 }, R = { 0, 0, 0, 0, 0.35, 0 }, N = { 15 } }),
	k(0.75, { RS = { 150, 0, 20 }, W = { 8, 10, 0 } }),
	k(1, {}),
})
local LS_WIDE = clip(0.45, 0.4, {
	k(0, {}),
	k(0.2, { W = { 0, -70, 0 }, RS = { 90, 0, 90 }, RE = { 10 }, R = { 0, -20, 0 } }),
	k(0.4, { W = { 0, 70, 0 }, RS = { 90, 0, -20 }, RE = { 0 }, R = { -6, 30, 0, 0, -0.3, 0 }, RH = { 30 }, RK = { -30 } }),
	k(0.7, { W = { 0, 55, 0 }, RS = { 85, 0, -10 }, R = { 0, 25, 0 } }),
	k(1, {}),
})
local DG_STAB = clip(0.28, 0.4, {
	k(0, {}),
	k(0.2, { RS = { 50, 0, 10 }, RE = { 110 }, W = { 0, -15, 0 } }),
	k(0.4, { RS = { 95, 0, 0 }, RE = { 0 }, W = { -8, 15, 0 }, R = { -10, 0, 0, 0, -0.3, 0 } }),
	k(1, {}),
})
local DG_BACK = clip(0.3, 0.4, {
	k(0, {}),
	k(0.2, { RS = { 80, 0, -40 }, RE = { 60 }, W = { 0, 40, 0 } }),
	k(0.4, { RS = { 80, 0, 75 }, RE = { 10 }, W = { 0, -40, 0 }, R = { 0, -15, 0, 0, -0.2, 0 } }),
	k(1, {}),
})
local DG_FLIP = clip(0.5, 0.62, {
	k(0, {}),
	k(0.15, { R = { 0, 0, 0, 0, -0.6, 0 }, RH = { 60 }, RK = { -90 }, LH = { 60 }, LK = { -90 }, RS = { 150, 0, 20 } }),
	k(0.5, { R = { -300, 0, 0, 0, 1.6, 0 }, RH = { 90 }, RK = { -110 }, LH = { 90 }, LK = { -110 }, RS = { 160, 0, 10 }, LS = { 120, 0, -20 } }),
	k(0.62, { R = { -360, 0, 0, 0, -0.4, 0 }, RS = { 30, 0, 0 }, RE = { 0 }, W = { -20, 0, 0 }, RH = { 50 }, RK = { -70 } }),
	k(1, { R = { -360, 0, 0 } }),
})
local SC_REAP = clip(0.5, 0.4, {
	k(0, {}),
	k(0.22, { W = { 0, -80, 0 }, RS = { 90, 0, 60 }, LS = { 80, 0, 10 }, LE = { 30 }, R = { 0, -25, 0 } }),
	k(0.4, { W = { 0, 80, 0 }, RS = { 90, 0, -20 }, LS = { 70, 0, -50 }, R = { -6, 30, 0, 0, -0.3, 0 }, RH = { 30 }, RK = { -40 } }),
	k(0.72, { W = { 0, 60, 0 }, RS = { 85, 0, -10 }, LS = { 60, 0, -40 } }),
	k(1, {}),
})
local SC_OVER = clip(0.5, 0.4, {
	k(0, {}),
	k(0.22, { RS = { 170, 0, 10 }, LS = { 160, 0, -10 }, W = { 15, 0, 0 }, N = { 10 } }),
	k(0.4, { RS = { 40, 0, 0 }, LS = { 50, 0, 0 }, W = { -25, 0, 0 }, R = { -8, 0, 0, 0, -0.5, 0 }, RH = { 45 }, RK = { -60 }, LH = { -15 } }),
	k(0.72, { RS = { 30, 0, 20 }, LS = { 40, 0, -20 }, W = { -15, -20, 0 } }),
	k(1, {}),
})
local SC_SPIN = clip(0.6, 0.5, {
	k(0, {}),
	k(0.15, { RS = { 90, 0, 90 }, LS = { 90, 0, -90 }, R = { 0, 0, 0, 0, -0.3, 0 } }),
	k(0.75, { R = { 0, 720, 0, 0, 0.3, 0 }, RS = { 90, 0, 90 }, LS = { 90, 0, -90 }, W = { 0, 15, 0 } }),
	k(1, { R = { 0, 720, 0 } }),
})

local COMBOS: { [number]: { Clip } } = {
	[1] = { GS_CHOP, GS_SWEEP, GS_SPIN },
	[2] = { DU_RIGHT, DU_LEFT, DU_CROSS },
	[3] = { LS_THRUST, LS_RISE, LS_WIDE },
	[4] = { DG_STAB, DG_BACK, DG_FLIP },
	[5] = { SC_REAP, SC_OVER, SC_SPIN },
	[0] = { GS_CHOP, SC_SPIN, GS_SPIN },
}

-- 구르기: 앞으로 한 바퀴
local ROLL = clip(0.36, 0.5, {
	k(0, {}),
	k(0.15, { R = { -60, 0, 0, 0, -0.9, 0 }, RH = { 90 }, RK = { -110 }, LH = { 90 }, LK = { -110 }, RS = { 60 }, LS = { 60 }, N = { -20 } }),
	k(0.75, { R = { -330, 0, 0, 0, -0.9, 0 }, RH = { 100 }, RK = { -120 }, LH = { 100 }, LK = { -120 }, RS = { 70 }, LS = { 70 } }),
	k(1, { R = { -360, 0, 0 } }),
})

-- 스킬 자세 (스킬 id별)
local SKILLS: { [string]: Clip } = {
	charge = clip(0.45, 0.5, { k(0, {}), k(0.3, { R = { -22, 0, 0, 0, -0.35, 0 }, RS = { 60, 0, 30 }, LS = { 40, 0, -20 }, W = { -15, 0, 0 }, RH = { 50 }, RK = { -30 }, LH = { -30 } }), k(0.8, { R = { -18, 0, 0, 0, -0.3, 0 }, RS = { 60, 0, 30 } }), k(1, {}) }),
	boomerang = clip(0.5, 0.45, { k(0, {}), k(0.3, { RS = { 150, 0, 60 }, W = { 0, -40, 0 }, R = { 0, -15, 0 } }), k(0.45, { RS = { 80, 0, -20 }, W = { 0, 40, 0 }, R = { -8, 15, 0 } }), k(1, {}) }),
	mark = clip(0.45, 0.4, { k(0, {}), k(0.4, { RS = { 95, 0, 0 }, RE = { 0 }, W = { 0, 20, 0 }, N = { -5 } }), k(1, {}) }),
	phantom = clip(0.4, 0.5, { k(0, {}), k(0.3, { R = { -30, 0, 0, 0, -0.5, 0 }, RS = { -20, 0, 30 }, LS = { -20, 0, -30 }, RH = { 60 }, RK = { -60 } }), k(1, {}) }),
	wave = GS_CHOP,
	parry = clip(1.2, 0.2, { k(0, {}), k(0.12, { RS = { 110, 0, 60 }, RE = { 70 }, LS = { 90, 0, -30 }, LE = { 90 }, R = { 0, 0, 0, 0, -0.4, 0 }, RH = { 30 }, RK = { -45 }, LH = { 25 }, LK = { -40 } }), k(0.9, { RS = { 110, 0, 60 }, RE = { 70 }, LS = { 90, 0, -30 }, LE = { 90 }, R = { 0, 0, 0, 0, -0.4, 0 } }), k(1, {}) }),
	poison = clip(0.6, 0.5, { k(0, {}), k(0.4, { RS = { 110, 0, -30 }, RE = { 100 }, N = { -15 }, W = { 0, 15, 0 } }), k(0.8, { RS = { 100, 0, -20 }, RE = { 90 } }), k(1, {}) }),
	smoke = clip(0.5, 0.3, { k(0, {}), k(0.3, { R = { -20, 0, 0, 0, -0.9, 0 }, RH = { 80 }, RK = { -110 }, LH = { 80 }, LK = { -110 }, RS = { 60, 0, -40 }, LS = { 60, 0, 40 } }), k(1, {}) }),
	hook = clip(0.6, 0.35, { k(0, {}), k(0.2, { RS = { 150, 0, 30 }, W = { 0, -20, 0 } }), k(0.35, { RS = { 90, 0, 0 }, W = { 0, 10, 0 } }), k(0.7, { RS = { 40, 0, 40 }, W = { 10, -30, 0 }, R = { 8, 0, 0 } }), k(1, {}) }),
	zone = clip(0.7, 0.4, { k(0, {}), k(0.3, { RS = { 170, 0, 0 }, LS = { 170, 0, 0 }, N = { 15 } }), k(0.8, { RS = { 170, 0, 0 }, LS = { 170, 0, 0 }, R = { 0, 360, 0 } }), k(1, { R = { 0, 360, 0 } }) }),
	rain = clip(0.7, 0.4, { k(0, {}), k(0.35, { RS = { 170, 0, 30 }, LS = { 170, 0, -30 }, N = { 25 }, W = { 12, 0, 0 } }), k(0.8, { RS = { 165, 0, 30 }, LS = { 165, 0, -30 } }), k(1, {}) }),
	timestop = clip(0.7, 0.4, { k(0, {}), k(0.3, { LS = { 90, 0, 0 }, LE = { 0 }, RS = { 20, 0, 20 }, W = { 0, -20, 0 } }), k(0.8, { LS = { 90, 0, 0 }, LE = { 0 } }), k(1, {}) }),
}

-- 필살기 자세 (무기별)
local ULTS: { [number]: Clip } = {
	[1] = clip(0.7, 0.4, { k(0, {}), k(0.25, { R = { 0, 0, 0, 0, 1.6, 0 }, RS = { 175, 0, 10 }, LS = { 170, 0, -10 }, W = { 15, 0, 0 } }), k(0.4, { R = { -10, 0, 0, 0, -0.8, 0 }, RS = { 20, 0, 0 }, LS = { 25, 0, 0 }, W = { -30, 0, 0 }, RH = { 60 }, RK = { -80 }, LH = { -20 } }), k(0.8, { R = { -6, 0, 0, 0, -0.6, 0 }, RS = { 25 }, LS = { 30 }, W = { -20, 0, 0 } }), k(1, {}) }),
	[2] = clip(2.5, 0.1, { k(0, { RS = { 90, 0, 90 }, LS = { 90, 0, -90 } }), k(1, { R = { 0, 1800, 0 }, RS = { 90, 0, 90 }, LS = { 90, 0, -90 } }) }),
	[3] = clip(0.6, 0.3, { k(0, {}), k(0.15, { R = { -25, 0, 0, 0, -0.6, 0 }, RS = { 60, 0, 20 }, RE = { 100 }, RH = { 70 }, RK = { -60 } }), k(0.3, { R = { -15, 0, 0, 0, -0.3, 0 }, RS = { 95, 0, 0 }, RE = { 0 }, W = { -10, 30, 0 }, LS = { -30, 0, -30 } }), k(0.8, { RS = { 90, 0, -10 }, W = { 0, 40, 0 } }), k(1, {}) }),
	[4] = clip(0.8, 0.3, { k(0, {}), k(0.3, { R = { -360, 0, 0, 0, 1.4, 0 }, RS = { 160 }, LS = { 160 } }), k(0.5, { R = { -360, 0, 0, 0, -0.3, 0 }, RS = { 95, 0, 0 }, RE = { 0 } }), k(1, { R = { -360, 0, 0 } }) }),
	[5] = clip(0.9, 0.4, { k(0, {}), k(0.3, { RS = { 170, 0, 0 }, LS = { 170, 0, 0 }, R = { 0, 0, 0, 0, 1, 0 } }), k(0.8, { R = { 0, 720, 0, 0, -0.3, 0 }, RS = { 90, 0, 90 }, LS = { 90, 0, -90 } }), k(1, { R = { 0, 720, 0 } }) }),
	[0] = clip(1.0, 0.4, { k(0, {}), k(0.35, { R = { 0, 0, 0, 0, 2.2, 0 }, RS = { 178, 0, 5 }, LS = { 175, 0, -5 }, N = { 25 }, W = { 15, 0, 0 } }), k(0.5, { R = { -12, 0, 0, 0, -0.8, 0 }, RS = { 15 }, LS = { 20 }, W = { -35, 0, 0 }, RH = { 70 }, RK = { -90 } }), k(0.85, { R = { -6, 0, 0, 0, -0.5, 0 }, RS = { 25 }, W = { -20, 0, 0 } }), k(1, {}) }),
}

local VICTORY = clip(1.6, 0.3, {
	k(0, {}),
	k(0.25, { RS = { 172, 0, 20 }, RE = { 10 }, LS = { 20, 0, -60 }, LE = { 80 }, N = { 18 }, W = { 10, 0, 0 } }),
	k(0.85, { RS = { 172, 0, 20 }, RE = { 10 }, LS = { 20, 0, -60 }, LE = { 80 }, N = { 18 }, W = { 10, 0, 0 } }),
	k(1, {}),
})

-- 적 동작: 경고 시간 T 동안 들어 올렸다가 내려친다
local function enemyClip(kind: string, T: number): Clip
	local d = T + 0.45
	local w = T / d
	local s = (T + 0.12) / d
	if kind == "slam" then
		return clip(d, s, { k(0, {}), k(w, { RS = { 172, 0, 10 }, LS = { 172, 0, -10 }, W = { 15, 0, 0 }, N = { 10 }, R = { 0, 0, 0, 0, 0.3, 0 } }), k(s, { RS = { 40 }, LS = { 40 }, W = { -30, 0, 0 }, R = { -8, 0, 0, 0, -0.6, 0 }, RH = { 40 }, RK = { -60 } }), k(1, {}) })
	elseif kind == "cast" then
		return clip(d, s, { k(0, {}), k(w, { RS = { 135, 0, 40 }, LS = { 135, 0, -40 }, N = { 15 }, W = { 10, 0, 0 } }), k(s, { RS = { 90 }, LS = { 90 }, W = { -10, 0, 0 } }), k(1, {}) })
	elseif kind == "charge" then
		return clip(T + 0.6, w, { k(0, {}), k(0.4, { R = { -25, 0, 0, 0, -0.5, 0 }, RS = { -30 }, LS = { -30 }, RH = { 50 }, RK = { -50 }, W = { -10, 0, 0 } }), k(0.9, { R = { -25, 0, 0, 0, -0.5, 0 }, RS = { -30 }, LS = { -30 } }), k(1, {}) })
	elseif kind == "spin" then
		return clip(T + 1.6, w, { k(0, {}), k(0.3, { RS = { 90, 0, 90 }, LS = { 90, 0, -90 } }), k(0.9, { RS = { 90, 0, 90 }, LS = { 90, 0, -90 } }), k(1, {}) })
	elseif kind == "shoot" then
		return clip(d, s, { k(0, {}), k(w, { LS = { 90, 0, 0 }, LE = { 0 }, RS = { 90, 0, 30 }, RE = { 120 }, W = { 0, 30, 0 } }), k(s, { LS = { 90 }, RS = { 80, 0, 40 }, RE = { 20 }, W = { 0, 30, 0 } }), k(1, {}) })
	elseif kind == "combo" then
		return clip(d, s, { k(0, {}), k(w, { RS = { 150, 0, 50 }, W = { 0, -40, 0 }, R = { -10, 0, 0, 0, -0.3, 0 } }), k(1, {}) })
	end
	return clip(d, s, { k(0, {}), k(w, { RS = { 150, 0, 30 }, RE = { 30 }, W = { 5, -30, 0 } }), k(s, { RS = { 20, 0, -10 }, RE = { 10 }, W = { -15, 25, 0 } }), k(1, {}) })
end

------------------------------------------------------------------------
-- 인형 (관절 묶음)
------------------------------------------------------------------------
type Rig = {
	model: Model,
	motors: { [string]: Motor6D },
	lastSet: { [Motor6D]: CFrame },
	lastBase: { [Motor6D]: CFrame },
	action: Clip?,
	actionT: number,
	actionSpeed: number,
	flinch: number,
	flinchSide: number,
	stanceW: number,
	isPlayer: boolean,
}

local rigs: { [Model]: Rig } = {}
local playerModel: Model? = nil
local combatType: number? = nil
local freezeUntil = 0

local function getRig(model: Model, isPlayer: boolean): Rig?
	local r = rigs[model]
	if r then
		return r
	end
	local motors = {}
	local any = false
	for short, joint in pairs(JOINT_NAMES) do
		local part = model:FindFirstChild(JOINT_PARTS[joint])
		local m = part and part:FindFirstChild(joint)
		if m and m:IsA("Motor6D") then
			motors[short] = m
			any = true
		end
	end
	if not any then
		return nil
	end
	r = {
		model = model,
		motors = motors,
		lastSet = {},
		lastBase = {},
		action = nil,
		actionT = 0,
		actionSpeed = 1,
		flinch = 0,
		flinchSide = 1,
		stanceW = 0,
		isPlayer = isPlayer,
	}
	rigs[model] = r
	return r
end

local function playOn(r: Rig, c: Clip, speed: number?)
	r.action = c
	r.actionT = 0
	r.actionSpeed = speed or 1
end

local work = newPose()
local stancePose = newPose()

-- 거의 같은 자세인가 (관절 값을 읽으면 소수점 끝이 조금 달라질 수 있다)
local function near(a: CFrame, b: CFrame): boolean
	if (a.Position - b.Position).Magnitude > 1e-3 then
		return false
	end
	return a.LookVector:Dot(b.LookVector) > 0.99999 and a.UpVector:Dot(b.UpVector) > 0.99999
end

local function toCFrame(v: { number }): CFrame
	return CFrame.new(v[4], v[5], v[6]) * CFrame.Angles(math.rad(v[1]), math.rad(v[2]), math.rad(v[3]))
end

local function updateRig(r: Rig, dt: number, now: number)
	-- 동작 시간
	local frozen = r.isPlayer and now < freezeUntil
	local actionW = 0
	local c = r.action
	if c then
		if not frozen then
			r.actionT += dt * r.actionSpeed / c.dur
		end
		if r.actionT >= 1 then
			r.action = nil
			c = nil
		else
			local t = r.actionT
			-- 시작과 끝을 부드럽게 이어 붙인다
			actionW = math.min(1, t / 0.08, (1 - t) / 0.12)
			actionW = math.clamp(actionW, 0, 1)
		end
	end

	-- 전투 자세 (내 캐릭터만)
	local stance: Pose? = nil
	if r.isPlayer and combatType ~= nil then
		stance = STANCES[combatType] or STANCES[1]
		r.stanceW = math.min(1, r.stanceW + dt * 4)
	else
		r.stanceW = math.max(0, r.stanceW - dt * 4)
	end
	local moving = false
	if r.isPlayer then
		local hum = r.model:FindFirstChildOfClass("Humanoid")
		moving = hum ~= nil and hum.MoveDirection.Magnitude > 0.1
	end
	for _, key in ipairs(KEYS) do
		local sv = stancePose[key]
		local src = stance and stance[key]
		for i = 1, 6 do
			sv[i] = (src and src[i] or 0) * r.stanceW
		end
	end
	-- 달릴 때는 다리 자세를 풀고 몸을 앞으로 기울인다
	if moving then
		for _, key in ipairs({ "RH", "RK", "LH", "LK" }) do
			local sv = stancePose[key]
			for i = 1, 6 do
				sv[i] = 0
			end
		end
		stancePose.R[1] -= 10 * r.stanceW
		stancePose.R[5] = 0
		stancePose.W[2] *= 0.5
	elseif r.isPlayer and r.stanceW > 0 then
		-- 숨쉬기
		stancePose.W[1] += math.sin(now * 2.2) * 2 * r.stanceW
	end

	if c then
		samplePose(c, r.actionT, work)
	end
	local fl = r.flinch
	if fl > 0 then
		r.flinch = math.max(0, fl - dt * 5)
	end

	for short, motor in pairs(r.motors) do
		if motor.Parent then
			local sv = stancePose[short]
			local wv = work[short]
			local v1, v2, v3, v4, v5, v6 = sv[1], sv[2], sv[3], sv[4], sv[5], sv[6]
			if c and actionW > 0 then
				v1 += (wv[1] - v1) * actionW
				v2 += (wv[2] - v2) * actionW
				v3 += (wv[3] - v3) * actionW
				v4 += (wv[4] - v4) * actionW
				v5 += (wv[5] - v5) * actionW
				v6 += (wv[6] - v6) * actionW
			end
			if fl > 0 then
				-- 맞으면 상체가 뒤로 젖혀지고 고개가 흔들린다
				if short == "W" then
					v1 += 22 * fl
					v2 += 12 * fl * r.flinchSide
				elseif short == "N" then
					v1 += 18 * fl
				elseif short == "RS" or short == "LS" then
					v1 -= 15 * fl
				end
			end
			local cur = motor.Transform
			local base = cur
			local last = r.lastSet[motor]
			-- 지난 프레임에 내가 넣은 값 그대로면 애니메이션이 덮어쓰지 않은 것: 원래 값에서 다시 계산
			if last and (cur == last or near(cur, last)) then
				base = r.lastBase[motor] or cur
			end
			local out
			if v1 == 0 and v2 == 0 and v3 == 0 and v4 == 0 and v5 == 0 and v6 == 0 then
				out = base
			else
				out = base * toCFrame({ v1, v2, v3, v4, v5, v6 })
			end
			motor.Transform = out
			r.lastBase[motor] = base
			r.lastSet[motor] = out
		end
	end
end

local started = false
local warned = false
local function start()
	if started then
		return
	end
	started = true
	RunService.Stepped:Connect(function(_time, dt)
		local now = os.clock()
		local step = math.min(dt or (1 / 60), 0.1)
		for model, r in pairs(rigs) do
			if not model.Parent then
				rigs[model] = nil
			else
				local ok, err = pcall(updateRig, r, step, now)
				if not ok then
					rigs[model] = nil
					if not warned then
						warned = true
						warn("[Arena] 동작 오류:", err)
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------------
-- 바깥에서 부르는 함수
------------------------------------------------------------------------
-- 내 캐릭터 지정 (캐릭터가 새로 생길 때마다)
function Motion.setCharacter(char: Model?)
	if playerModel and rigs[playerModel] then
		rigs[playerModel] = nil
	end
	playerModel = char
	if char then
		getRig(char, true)
	end
	start()
end

-- 전투 자세 켜기/끄기 (무기 계열)
function Motion.setCombat(typeId: number?)
	combatType = typeId
end

local function myRig(): Rig?
	local m = playerModel
	if not m or not m.Parent then
		return nil
	end
	return rigs[m] or getRig(m, true)
end

-- 기본 공격. 칼이 닿는 순간까지 걸리는 시간(초)을 돌려준다
function Motion.attack(typeId: number, step: number, cooldown: number): number
	local r = myRig()
	if not r then
		return 0
	end
	local list = COMBOS[typeId] or COMBOS[1]
	local c = list[math.clamp(step or 1, 1, 3)]
	local speed = math.max(1, c.dur / ((cooldown or 0.5) + 0.12))
	playOn(r, c, speed)
	return c.hit * c.dur / speed
end

function Motion.roll()
	local r = myRig()
	if r then
		playOn(r, ROLL, 1)
	end
end

function Motion.skill(id: string)
	local r = myRig()
	local c = SKILLS[id]
	if r and c then
		playOn(r, c, 1)
	end
end

function Motion.ult(typeId: number)
	local r = myRig()
	local c = ULTS[typeId] or ULTS[1]
	if r then
		playOn(r, c, 1)
	end
end

function Motion.victory()
	local r = myRig()
	if r then
		playOn(r, VICTORY, 1)
	end
end

-- 히트스톱: 내 동작을 아주 잠깐 멈춘다
function Motion.hitStop(duration: number)
	local now = os.clock()
	if now >= freezeUntil then
		freezeUntil = now + duration
	end
end

-- 맞아서 움찔 (내 캐릭터 또는 적 모델)
function Motion.flinch(model: Instance?, strength: number?, side: number?)
	if not model or not model:IsA("Model") then
		return
	end
	local r = rigs[model :: Model] or getRig(model :: Model, model == playerModel)
	if r then
		r.flinch = math.clamp(strength or 1, 0, 1.5)
		r.flinchSide = side or ((math.random() < 0.5) and -1 or 1)
		start()
	end
end

-- 적 공격 동작 (서버가 모델 속성으로 알려 준다)
function Motion.enemy(model: Model, kind: string, windup: number)
	local r = rigs[model] or getRig(model, false)
	if r then
		playOn(r, enemyClip(kind, math.max(0.05, windup)), 1)
		start()
	end
end

return Motion
