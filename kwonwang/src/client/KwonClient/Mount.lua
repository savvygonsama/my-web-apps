-- 권왕: 탈것 모습 (화면마다 직접 그린다). 몸에 "Mount" 표시가 붙은 사람 아래에 말·범·구름을 그리고, 달리면 다리가 번갈아 움직인다
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Mount = {}

local folder = Instance.new("Folder")
folder.Name = "KwonMounts"
folder.Parent = workspace

type Rig = { parts: { { p: BasePart, off: CFrame, leg: number? } }, kind: string, phase: number, model: Model }
local rigs: { [Model]: Rig } = {}

local function piece(rig: Rig, size: Vector3, off: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?, leg: number?): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Parent = folder
	table.insert(rig.parts, { p = p, off = off, leg = leg })
	return p
end

-- 네 발 짐승 (말·범): 몸통 가운데가 기준. 앞은 -Z
local function beast(rig: Rig, m: any, tiger: boolean)
	local c, mane = m.color, m.mane
	local legH = tiger and 1.5 or 2.0
	local bodyY = tiger and 1.3 or 1.6
	piece(rig, Vector3.new(tiger and 1.7 or 1.6, bodyY, 4.2), CFrame.new(), c)
	-- 목과 머리
	if tiger then
		piece(rig, Vector3.new(1.4, 1.2, 1.3), CFrame.new(0, 0.35, -2.55), c)
		piece(rig, Vector3.new(0.9, 0.6, 0.6), CFrame.new(0, 0.15, -3.35), c)
		for _, x in ipairs({ -1, 1 }) do
			piece(rig, Vector3.new(0.3, 0.35, 0.15), CFrame.new(x * 0.5, 1.05, -2.45), c)
			piece(rig, Vector3.new(0.18, 0.12, 0.05), CFrame.new(x * 0.32, 0.55, -3.21), Color3.fromRGB(60, 160, 255), Enum.Material.Neon)
		end
		-- 줄무늬
		for k = -2, 2 do
			piece(rig, Vector3.new(1.75, 0.18, 0.22), CFrame.new(0, 0.6, k * 0.75) * CFrame.Angles(0, 0, 0), mane)
		end
		piece(rig, Vector3.new(0.25, 0.25, 2.2), CFrame.new(0, 0.6, 2.9) * CFrame.Angles(math.rad(-25), 0, 0), c)
	else
		piece(rig, Vector3.new(0.85, 1.9, 1.0), CFrame.new(0, 1.1, -2.0) * CFrame.Angles(math.rad(-30), 0, 0), c)
		piece(rig, Vector3.new(0.75, 0.75, 1.6), CFrame.new(0, 1.95, -2.85) * CFrame.Angles(math.rad(15), 0, 0), c)
		piece(rig, Vector3.new(0.18, 1.6, 0.5), CFrame.new(0, 1.3, -1.75) * CFrame.Angles(math.rad(-30), 0, 0), mane)
		for _, x in ipairs({ -1, 1 }) do
			piece(rig, Vector3.new(0.15, 0.4, 0.15), CFrame.new(x * 0.22, 2.45, -2.45), c)
			piece(rig, Vector3.new(0.08, 0.12, 0.12), CFrame.new(x * 0.38, 2.05, -3.1), Color3.fromRGB(15, 10, 10))
		end
		piece(rig, Vector3.new(0.35, 1.8, 0.35), CFrame.new(0, -0.1, 2.25) * CFrame.Angles(math.rad(25), 0, 0), mane)
		-- 안장과 고삐
		piece(rig, Vector3.new(1.75, 0.25, 1.5), CFrame.new(0, 0.9, -0.1), Color3.fromRGB(140, 35, 30), Enum.Material.Fabric)
		piece(rig, Vector3.new(1.8, 0.12, 0.3), CFrame.new(0, 0.8, 0.7), Color3.fromRGB(200, 165, 70), Enum.Material.Metal)
	end
	-- 다리 넷 (윗부분이 돌쇠): leg = 다리 번호
	local i = 0
	for _, z in ipairs({ -1.55, 1.55 }) do
		for _, x in ipairs({ -0.55, 0.55 }) do
			i += 1
			piece(rig, Vector3.new(0.45, legH, 0.45), CFrame.new(x, -bodyY / 2, z), c, nil, nil, i)
			piece(rig, Vector3.new(0.5, 0.25, 0.55), CFrame.new(x, -bodyY / 2, z), tiger and c or Color3.fromRGB(35, 28, 24), nil, nil, i + 10)
		end
	end
end

local function cloud(rig: Rig, m: any)
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2
		local r = k == 0 and 0 or 1.3
		local size = k == 0 and 2.6 or 1.8
		piece(rig, Vector3.new(size, size, size), CFrame.new(math.cos(a) * r, 0, math.sin(a) * r * 1.4), m.color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
	local glow = piece(rig, Vector3.new(3.6, 0.2, 4.6), CFrame.new(0, -0.6, 0), m.mane, Enum.Material.Neon)
	glow.Transparency = 0.5
	local light = Instance.new("PointLight")
	light.Color = m.mane
	light.Range = 12
	light.Brightness = 1.2
	light.Parent = glow
	-- 꼬리 구름
	for k = 1, 3 do
		piece(rig, Vector3.new(1.4 - k * 0.3, 1.4 - k * 0.3, 1.4 - k * 0.3), CFrame.new(0, 0.2, 2.2 + k * 0.9), m.color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
end

local function build(model: Model, id: string)
	local m = Config.MOUNT_BY_ID[id]
	if not m then
		return
	end
	local rig: Rig = { parts = {}, kind = m.kind, phase = 0, model = model }
	if m.kind == "cloud" then
		cloud(rig, m)
	else
		beast(rig, m, m.kind == "tiger")
	end
	rigs[model] = rig
end

local function clear(model: Model)
	local rig = rigs[model]
	if rig then
		for _, e in ipairs(rig.parts) do
			e.p:Destroy()
		end
		rigs[model] = nil
	end
end

function Mount.watch(model: Model)
	local function refresh()
		clear(model)
		local id = model:GetAttribute("Mount")
		if type(id) == "string" then
			build(model, id)
		end
	end
	model:GetAttributeChangedSignal("Mount"):Connect(refresh)
	model.AncestryChanged:Connect(function()
		if not model.Parent then
			clear(model)
		end
	end)
	refresh()
end

-- 매 화면: 탄 사람의 발밑에 맞춰 놓고, 달리는 빠르기만큼 다리를 번갈아 흔든다
RunService.RenderStepped:Connect(function(dt: number)
	for model, rig in pairs(rigs) do
		local root = model:FindFirstChild("HumanoidRootPart")
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not hum or not model.Parent then
			clear(model)
			continue
		end
		local vel = root.AssemblyLinearVelocity
		local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
		rig.phase += dt * (3 + speed * 0.45)
		local run = math.clamp(speed / 18, 0, 1)
		local m = Config.MOUNT_BY_ID[model:GetAttribute("Mount") or ""]
		local lift = m and Config.MOUNT_HIP[m.kind] or 2
		-- 탄 사람의 엉덩이 바로 아래가 등
		local seat = root.CFrame * CFrame.new(0, -root.Size.Y / 2 - 0.25, 0)
		local look = root.CFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude < 1e-3 then
			flatLook = Vector3.new(0, 0, -1)
		end
		local base: CFrame
		if rig.kind == "cloud" then
			base = CFrame.lookAt(seat.Position, seat.Position + flatLook) * CFrame.new(0, -0.9 + math.sin(os.clock() * 2) * 0.15, 0)
		else
			local bodyY = rig.kind == "tiger" and 1.3 or 1.6
			local bob = math.abs(math.sin(rig.phase)) * 0.18 * run
			base = CFrame.lookAt(seat.Position, seat.Position + flatLook) * CFrame.new(0, -bodyY / 2 - 0.15 + bob - (lift - (rig.kind == "tiger" and 1.5 or 2.0)), 0)
		end
		for _, e in ipairs(rig.parts) do
			if e.leg then
				local idx = e.leg > 10 and e.leg - 10 or e.leg
				-- 대각선 다리끼리 같이 (1·4, 2·3)
				local ph = rig.phase + ((idx == 1 or idx == 4) and 0 or math.pi)
				local ang = math.sin(ph) * math.rad(38) * run
				local legH = rig.kind == "tiger" and 1.5 or 2.0
				local hip = base * e.off
				local legCF = hip * CFrame.Angles(ang, 0, 0) * CFrame.new(0, -legH / 2, 0)
				if e.leg > 10 then
					e.p.CFrame = legCF * CFrame.new(0, -legH / 2 - 0.1, -0.05)
				else
					e.p.CFrame = legCF
				end
			else
				e.p.CFrame = base * e.off
			end
		end
	end
end)

return Mount
