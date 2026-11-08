-- 권왕 3.35판: 땅마다 다른 공기. 카메라 머리 위에 떠서 따라다니는 입자 하나로 눈 · 먼지 · 불씨 · 꽃가루 · 반딧불 · 낙엽을 흩날린다
-- (이 화면에서만 만든다. 서버·다른 사람과 상관없다. 가벼운 그래픽이면 양을 줄인다)
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Perf = require(script.Parent:WaitForChild("Perf"))

local Ambience = {}

local function C(r: number, g: number, b: number): ColorSequence
	return ColorSequence.new(Color3.fromRGB(r, g, b))
end
local function C2(a: Color3, b: Color3): ColorSequence
	return ColorSequence.new(a, b)
end
local function N(a: number, b: number?): NumberSequence
	return NumberSequence.new(a, b or a)
end
local FADE = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.4), NumberSequenceKeypoint.new(0.8, 0.5), NumberSequenceKeypoint.new(1, 1) })

-- 입자 모양 모음. rate 는 초당 개수 (가벼운 그래픽이면 0.4배)
local PRESETS: { [string]: any } = {
	default = { rate = 3, life = 7, speed = 0.8, accel = Vector3.new(0.4, -0.05, 0.2), color = C(255, 240, 200), size = N(0.22), light = 0.2, spread = 180, dir = Enum.NormalId.Bottom },
	night = { rate = 2.2, life = 6, speed = 0.7, accel = Vector3.new(0.2, 0.1, 0.1), color = C(210, 255, 120), size = N(0.28), light = 1, spread = 180, dir = Enum.NormalId.Bottom, blink = true },
	snow = { rate = 38, life = 7, speed = 5, accel = Vector3.new(1.2, -2, 0.6), color = C(255, 255, 255), size = N(0.34), light = 0.3, spread = 25, dir = Enum.NormalId.Bottom },
	swamp = { rate = 5, life = 8, speed = 0.6, accel = Vector3.new(0, 0.1, 0), color = C(150, 190, 110), size = N(2.4, 3.6), light = 0, spread = 180, dir = Enum.NormalId.Bottom, softer = true },
	badlands = { rate = 16, life = 5, speed = 7, accel = Vector3.new(9, -0.3, 2), color = C(214, 160, 110), size = N(0.4), light = 0, spread = 30, dir = Enum.NormalId.Left },
	desert = { rate = 16, life = 5, speed = 7, accel = Vector3.new(9, -0.3, 2), color = C(232, 205, 150), size = N(0.4), light = 0, spread = 30, dir = Enum.NormalId.Left },
	coast = { rate = 4, life = 7, speed = 1.2, accel = Vector3.new(2, 0, 0.5), color = C(235, 245, 255), size = N(1.6, 2.4), light = 0.1, spread = 180, dir = Enum.NormalId.Bottom, softer = true },
	cult = { rate = 12, life = 5, speed = 2, accel = Vector3.new(0, 2.5, 0), color = C2(Color3.fromRGB(255, 90, 50), Color3.fromRGB(120, 20, 20)), size = N(0.3, 0.05), light = 1, spread = 180, dir = Enum.NormalId.Bottom },
	rift = { rate = 9, life = 6, speed = 0.9, accel = Vector3.new(0, 0.4, 0), color = C2(Color3.fromRGB(190, 130, 255), Color3.fromRGB(110, 90, 220)), size = N(0.3), light = 1, spread = 180, dir = Enum.NormalId.Bottom },
	volcano = { rate = 22, life = 6, speed = 2, accel = Vector3.new(1.5, 1.2, 0), color = C2(Color3.fromRGB(255, 150, 60), Color3.fromRGB(70, 60, 60)), size = N(0.3, 0.12), light = 0.8, spread = 180, dir = Enum.NormalId.Bottom },
	sky = { rate = 6, life = 7, speed = 0.8, accel = Vector3.new(0.3, 0.2, 0), color = C2(Color3.fromRGB(255, 240, 190), Color3.fromRGB(190, 225, 255)), size = N(0.3), light = 1, spread = 180, dir = Enum.NormalId.Bottom },
	maple = { rate = 9, life = 8, speed = 2, accel = Vector3.new(1.5, -1.6, 0.8), color = C2(Color3.fromRGB(235, 90, 40), Color3.fromRGB(240, 170, 50)), size = N(0.55), light = 0, spread = 40, dir = Enum.NormalId.Bottom, spin = true },
	stone = { rate = 3, life = 6, speed = 0.6, accel = Vector3.new(0.5, 0, 0), color = C(205, 205, 195), size = N(0.25), light = 0, spread = 180, dir = Enum.NormalId.Bottom },
	mushroom = { rate = 10, life = 8, speed = 0.7, accel = Vector3.new(0, 0.3, 0), color = C2(Color3.fromRGB(200, 140, 255), Color3.fromRGB(120, 220, 200)), size = N(0.3), light = 1, spread = 180, dir = Enum.NormalId.Bottom },
	tea = { rate = 4, life = 9, speed = 0.5, accel = Vector3.new(0.6, 0, 0.3), color = C(235, 245, 235), size = N(2.2, 3.4), light = 0.1, spread = 180, dir = Enum.NormalId.Bottom, softer = true },
	hell = { rate = 20, life = 6, speed = 2.5, accel = Vector3.new(0.8, 2.2, 0), color = C2(Color3.fromRGB(255, 80, 40), Color3.fromRGB(60, 20, 20)), size = N(0.3, 0.06), light = 1, spread = 180, dir = Enum.NormalId.Bottom },
	cave = { rate = 7, life = 8, speed = 0.5, accel = Vector3.new(0, 0.25, 0), color = C2(Color3.fromRGB(120, 160, 255), Color3.fromRGB(170, 120, 255)), size = N(0.28), light = 1, spread = 180, dir = Enum.NormalId.Bottom },
}

local holder: Part? = nil
local emitter: ParticleEmitter? = nil
local current = ""

local function ensure()
	if holder and holder.Parent then
		return
	end
	local p = Instance.new("Part")
	p.Name = "KwonAmbience"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.new(90, 1, 90)
	p.Parent = workspace
	holder = p
	local e = Instance.new("ParticleEmitter")
	e.Name = "Motes"
	e.Shape = Enum.ParticleEmitterShape.Box
	e.Rate = 0
	e.LightInfluence = 0
	e.Orientation = Enum.ParticleOrientation.FacingCamera
	e.Parent = p
	emitter = e
	current = ""
end

local function lowGfx(): boolean
	return Perf.low or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
end

local function apply(name: string)
	ensure()
	local e = emitter :: ParticleEmitter
	local P = PRESETS[name] or PRESETS.default
	current = name
	local k = lowGfx() and 0.4 or 1
	e.Rate = P.rate * k
	e.Lifetime = NumberRange.new(P.life * 0.8, P.life)
	e.Speed = NumberRange.new(P.speed * 0.6, P.speed)
	e.Acceleration = P.accel
	e.Color = P.color
	e.Size = P.size
	e.Transparency = P.softer and NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.88), NumberSequenceKeypoint.new(1, 1) }) or FADE
	e.LightEmission = P.light
	e.SpreadAngle = Vector2.new(P.spread, P.spread)
	e.EmissionDirection = P.dir
	e.RotSpeed = P.spin and NumberRange.new(-120, 120) or NumberRange.new(0, 0)
	e.Rotation = NumberRange.new(0, 360)
end

local function presetAt(pos: Vector3): string
	local S = Config.SINROAD
	if S and math.abs(pos.X - S.room.X) < 76 and math.abs(pos.Z - S.room.Z) < 76 and pos.Y > S.room.Y - 10 and pos.Y < S.room.Y + 90 then
		return "cave"
	end
	if Config.inHell(pos) then
		return "hell"
	end
	if pos.Y > Config.SKY.y - 300 then
		return "sky"
	end
	if pos.Y > 1000 then
		return "default"
	end
	-- 마을 · 들판은 낮에 꽃가루, 밤에 반딧불
	local best: any = nil
	for _, r in ipairs(Config.Regions) do
		if not r.noGround and math.abs(pos.X - r.center.X) <= r.size.X / 2 and math.abs(pos.Z - r.center.Z) <= r.size.Z / 2 then
			if not best or r.size.X * r.size.Z < best.size.X * best.size.Z then
				best = r
			end
		end
	end
	local key = best and best.ambient or "default"
	if key == "default" then
		local h = Lighting.ClockTime
		if h < 6.3 or h > 18.7 then
			return "night"
		end
	end
	return PRESETS[key] and key or "default"
end

function Ambience.start()
	ensure()
	local last = 0
	local lastLow = lowGfx()
	RunService.Heartbeat:Connect(function()
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		ensure()
		local p = holder :: Part
		p.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 14, 0))
		local now = os.clock()
		if now - last < 0.8 then
			return
		end
		last = now
		local want = presetAt(cam.CFrame.Position)
		local lowNow = lowGfx()
		if want ~= current or lowNow ~= lastLow then
			lastLow = lowNow
			apply(want)
		end
	end)
end

return Ambience
