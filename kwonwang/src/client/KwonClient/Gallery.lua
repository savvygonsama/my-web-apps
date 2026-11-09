-- 권왕 3.62판: 배틀그라운드 대기실의 권법 회랑 (권법 고르는 창 대신)
--   3.64판: 엘리멘탈 아레나처럼. 권법마다 떠 있는 큰 상징 구슬 · 나무 푯말 (이름 · 등급) · 빛나는 발판. 발판을 밟으면 그 권법으로 싸움터에 들어간다
--   (두 줄 × 여섯, 마당 동쪽. 발판은 서쪽 (마당 가운데) 을 향한다)
--   익힌 권법마다 마네킹 하나 (내 생김새 + 그 권법의 시그니처 장신구) 가 받침대 위에서 그 권법 자세로 서 있다가,
--   가까이 가면 차례로 연타 · 강타 · 기술을 시범한다. 받침대 앞에서 T = 그 권법으로 싸움터에 들어간다
--   한 번에 15개 (등급 높은 차례). 더 있으면 '다음 ▶' 받침대로 넘긴다. 마네킹은 내 화면에만 있다
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Anim = require(script.Parent:WaitForChild("Anim"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Gallery = {}
local player = Players.LocalPlayer

local opts: any = {}
local folder: Folder? = nil
local center: Vector3? = nil
local page = 1
local builtKey = ""
local slots: { any } = {}
local spinners: { BasePart } = {} -- 3.64판 상징 구슬의 도는 고리
local lastState: any = nil

local PER = 8
local INK = Color3.fromRGB(16, 18, 24)


local function gradeOf(id: string): string
	local s = Config.STYLE_BY_ID[id]
	local ups = (lastState and lastState.gradeUp and lastState.gradeUp[id]) or 0
	return s and Config.styleGrade(s, ups) or "상급"
end

-- 3.65판: 마네킹은 내 캐릭터를 복사하지 않고 직접 짠다 (캐릭터가 아직 없을 때 비어 있었다). 권법 빛깔로 칠한 R15 몸
local RIG: { { any } } = {
	{ "LowerTorso", Vector3.new(2, 0.4, 1), Vector3.new(0, -0.8, 0), "HumanoidRootPart", "Root", Vector3.new(0, -0.8, 0) },
	{ "UpperTorso", Vector3.new(2, 1.6, 1), Vector3.new(0, 0.2, 0), "LowerTorso", "Waist", Vector3.new(0, -0.6, 0) },
	{ "Head", Vector3.new(1.1, 1.1, 1.1), Vector3.new(0, 1.55, 0), "UpperTorso", "Neck", Vector3.new(0, 1.0, 0) },
	{ "RightUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(1.5, 0.4, 0), "UpperTorso", "RightShoulder", Vector3.new(1.5, 0.8, 0) },
	{ "RightLowerArm", Vector3.new(1, 0.95, 1), Vector3.new(1.5, -0.675, 0), "RightUpperArm", "RightElbow", Vector3.new(1.5, -0.2, 0) },
	{ "RightHand", Vector3.new(1, 0.3, 1), Vector3.new(1.5, -1.3, 0), "RightLowerArm", "RightWrist", Vector3.new(1.5, -1.15, 0) },
	{ "LeftUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(-1.5, 0.4, 0), "UpperTorso", "LeftShoulder", Vector3.new(-1.5, 0.8, 0) },
	{ "LeftLowerArm", Vector3.new(1, 0.95, 1), Vector3.new(-1.5, -0.675, 0), "LeftUpperArm", "LeftElbow", Vector3.new(-1.5, -0.2, 0) },
	{ "LeftHand", Vector3.new(1, 0.3, 1), Vector3.new(-1.5, -1.3, 0), "LeftLowerArm", "LeftWrist", Vector3.new(-1.5, -1.15, 0) },
	{ "RightUpperLeg", Vector3.new(1, 1.1, 1), Vector3.new(0.5, -1.55, 0), "LowerTorso", "RightHip", Vector3.new(0.5, -1.0, 0) },
	{ "RightLowerLeg", Vector3.new(1, 0.7, 1), Vector3.new(0.5, -2.45, 0), "RightUpperLeg", "RightKnee", Vector3.new(0.5, -2.1, 0) },
	{ "RightFoot", Vector3.new(1, 0.2, 1.1), Vector3.new(0.5, -2.9, -0.05), "RightLowerLeg", "RightAnkle", Vector3.new(0.5, -2.8, 0) },
	{ "LeftUpperLeg", Vector3.new(1, 1.1, 1), Vector3.new(-0.5, -1.55, 0), "LowerTorso", "LeftHip", Vector3.new(-0.5, -1.0, 0) },
	{ "LeftLowerLeg", Vector3.new(1, 0.7, 1), Vector3.new(-0.5, -2.45, 0), "LeftUpperLeg", "LeftKnee", Vector3.new(-0.5, -2.1, 0) },
	{ "LeftFoot", Vector3.new(1, 0.2, 1.1), Vector3.new(-0.5, -2.9, -0.05), "LeftLowerLeg", "LeftAnkle", Vector3.new(-0.5, -2.8, 0) },
}
local DOLL_S = 1.5 -- 마네킹 키 배율
local function makeDoll(st: any): Model
	local S = DOLL_S
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1) * S
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root
	local c1, c2 = st.color, st.color2 or st.color
	local dark = c1:Lerp(Color3.new(0, 0, 0), 0.35)
	local parts: { [string]: BasePart } = { HumanoidRootPart = root }
	for _, r in ipairs(RIG) do
		local name, size, cen, parentName, jointName, joint = r[1], r[2] * S, r[3] * S, r[4], r[5], r[6] * S
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = CFrame.new(cen)
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if name == "Head" then
			p.Color = c2
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Parent = p
		elseif string.find(name, "Torso") then
			p.Color = c1
		elseif string.find(name, "Hand") or string.find(name, "Foot") then
			p.Color = c2
		else
			p.Color = dark
		end
		p.Parent = model
		parts[name] = p
		local parent = parts[parentName]
		local m = Instance.new("Motor6D")
		m.Name = jointName
		m.Part0 = parent
		m.Part1 = p
		m.C0 = CFrame.new(joint - parent.CFrame.Position)
		m.C1 = CFrame.new(joint - cen)
		m.Parent = p
	end
	-- 몸에서 은은한 빛 (마네킹이 권법 빛깔로 빛난다)
	local glow = Instance.new("PointLight")
	glow.Color = c1
	glow.Range = 12
	glow.Brightness = 0.8
	glow.Parent = parts.UpperTorso
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = 2 * S
	hum.AutomaticScalingEnabled = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.PlatformStand = true
	hum.Parent = model
	return model
end

local function newPart(props: { [string]: any }): BasePart
	local p = Instance.new(props.Class or "Part") :: BasePart
	p.Anchored = true
	p.CanCollide = props.CanCollide == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k == "Position" then
			p.CFrame = CFrame.new(v)
		elseif k ~= "Class" and k ~= "Parent" and k ~= "CanCollide" then
			(p :: any)[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

local function clear()
	for _, s in ipairs(slots) do
		if s.doll then
			s.doll:Destroy()
		end
	end
	slots = {}
	spinners = {}
	if folder then
		folder:ClearAllChildren()
	end
end

-- 받침대 자리 (마당 동쪽 절반, 5 × 3)
local function spotAt(i: number): Vector3
	local c = center :: Vector3
	local col = (i - 1) // 4
	local row = (i - 1) % 4
	return c + Vector3.new(38 + col * 24, 0.6, -22 + row * 15)
end
-- 나무 푯말 (마네킹 옆): 기둥 + 판, 판 앞면에 이름 · 등급
local function signpost(at: Vector3, st: any, grade: string, using: boolean, f: Instance)
	local WOOD = Color3.fromRGB(120, 82, 52)
	newPart({ Name = "SignPost", Size = Vector3.new(0.7, 7.5, 0.7), Position = at + Vector3.new(0, 3.75, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = f })
	local board = newPart({ Name = "SignBoard", Size = Vector3.new(0.4, 3.8, 7.4), CFrame = CFrame.new(at + Vector3.new(0, 7.2, 0)), Color = Color3.fromRGB(150, 104, 66), Material = Enum.Material.Wood, Parent = f })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Left -- 서쪽 (마당) 을 본다
	sg.PixelsPerStud = 60
	sg.LightInfluence = 0.2
	sg.Parent = board
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, -16, 0.62, 0)
	t.Position = UDim2.new(0, 8, 0, 4)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 246, 228)
	t.TextStrokeTransparency = 0.4
	t.Text = st.name
	t.Parent = sg
	local g = Instance.new("TextLabel")
	g.BackgroundTransparency = 1
	g.Size = UDim2.new(1, -16, 0.32, 0)
	g.Position = UDim2.new(0, 8, 0.64, 0)
	g.Font = Enum.Font.GothamBold
	g.TextScaled = true
	g.TextColor3 = using and Color3.fromRGB(255, 220, 120) or (Config.GRADE_COLOR[grade] or Color3.fromRGB(255, 220, 120))
	g.TextStrokeTransparency = 0.5
	g.Text = using and (grade .. " · 지금 쓰는 권법") or grade
	g.Parent = sg
end
-- 떠 있는 상징 구슬: 권법 빛깔의 빛나는 구슬 · 바깥 빛무리 · 비스듬히 도는 고리 · 빛 가루 · 가운데 한자
local function emblem(at: Vector3, st: any, f: Instance)
	local c1, c2 = st.color, st.color2 or st.color
	local core = newPart({ Name = "EmblemCore", Shape = Enum.PartType.Ball, Size = Vector3.one * 6, Position = at, Color = c1, Material = Enum.Material.Neon, Transparency = 0.1, Parent = f })
	newPart({ Name = "EmblemHalo", Shape = Enum.PartType.Ball, Size = Vector3.one * 10, Position = at, Color = c2, Material = Enum.Material.Neon, Transparency = 0.82, Parent = f })
	local ring = newPart({ Name = "EmblemRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 13, 13), CFrame = CFrame.new(at) * CFrame.Angles(0.5, 0, math.rad(90)), Color = c2, Material = Enum.Material.Neon, Transparency = 0.45, Parent = f })
	table.insert(spinners, ring)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.new(1, 1, 1), c2)
	e.Size = NumberSequence.new(0.9, 0)
	e.Transparency = NumberSequence.new(0, 1)
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(2, 5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.LightEmission = 1
	e.Rate = 16
	e.Parent = core
	local l = Instance.new("PointLight")
	l.Color = c1
	l.Range = 26
	l.Brightness = 2
	l.Parent = core
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 110, 0, 110)
	bb.MaxDistance = 90
	bb.LightInfluence = 0
	bb.Parent = core
	local h = Instance.new("TextLabel")
	h.BackgroundTransparency = 1
	h.Size = UDim2.fromScale(1, 1)
	h.Font = Enum.Font.Antique
	h.TextScaled = true
	h.TextColor3 = Color3.new(1, 1, 1)
	h.TextStrokeTransparency = 0.3
	h.TextStrokeColor3 = c1:Lerp(Color3.new(0, 0, 0), 0.5)
	h.Text = st.icon or ""
	h.Parent = bb
end
-- 밟는 발판 (마당 쪽)
local function pad(at: Vector3, st: any, using: boolean, f: Instance): BasePart
	newPart({ Name = "PadEdge", Size = Vector3.new(8.8, 0.3, 10.8), Position = at + Vector3.new(0, 0.15, 0), Color = Color3.fromRGB(30, 32, 40), Material = Enum.Material.SmoothPlastic, CanCollide = true, Parent = f })
	local p = newPart({ Name = "Pad", Size = Vector3.new(8, 0.32, 10), Position = at + Vector3.new(0, 0.2, 0), Color = using and Color3.fromRGB(255, 208, 110) or st.color, Material = Enum.Material.Neon, Transparency = 0.25, Parent = f })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Top
	sg.PixelsPerStud = 40
	sg.LightInfluence = 0
	sg.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Rotation = 90
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextTransparency = 0.15
	t.Text = "밟으면 입장"
	t.Parent = sg
	return p
end

local function build()
	if not center or not lastState or not lastState.styles then
		return
	end
	local ids = table.clone(lastState.styles)
	local function rank(id: string): number
		return table.find(Config.GRADE_ORDER, gradeOf(id)) or 0
	end
	table.sort(ids, function(a, b)
		local ra, rb = rank(a), rank(b)
		if ra ~= rb then
			return ra > rb
		end
		return a < b
	end)
	local pages = math.max(1, math.ceil(#ids / PER))
	page = math.clamp(page, 1, pages)
	local key = table.concat(ids, ",") .. "|" .. tostring(lastState.style) .. "|" .. page
	if key == builtKey then
		return
	end
	builtKey = key
	clear()
	local f = folder :: Folder
	for k = 1, PER do
		local id = ids[(page - 1) * PER + k]
		local st = id and Config.STYLE_BY_ID[id]
		if st then
			local at = spotAt(k)
			local using = lastState.style == id
			-- 받침대: 어두운 둥근 단 + 권법 빛깔의 빛나는 테
			local base = newPart({ Name = "GalleryBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 9, 9), CFrame = CFrame.new(at + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = INK, Material = Enum.Material.SmoothPlastic, CanCollide = true, Parent = f })
			newPart({ Name = "GalleryRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 9.6, 9.6), CFrame = CFrame.new(at + Vector3.new(0, 0.82, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = using and Color3.fromRGB(255, 208, 110) or st.color, Material = Enum.Material.Neon, Transparency = 0.25, Parent = f })
			emblem(at + Vector3.new(0, 17, 0), st, f)
			signpost(at + Vector3.new(-4, 0.6, 6.6), st, gradeOf(id), using, f)
			local padAt = at + Vector3.new(-11, -0.6, 0)
			pad(padAt, st, using, f)
			local doll = makeDoll(st)
			local slot: any = { id = id, at = at, base = base, padAt = padAt, next = os.clock() + 1 + k * 0.4 }
			do
				doll.Name = "GalleryDoll"
				doll:SetAttribute("Style", id)
				doll.Parent = f
				-- 받침대 위에 서서 마당 가운데 (서쪽) 를 본다
				-- 받침대 윗면에 발이 닿게 (뿌리에서 발바닥까지 3 × 배율)
				local hip = 3 * DOLL_S
				doll:PivotTo(CFrame.lookAt(at + Vector3.new(0, 0.8 + hip, 0), Vector3.new((center :: Vector3).X, at.Y + 0.8 + hip, at.Z)))
				if opts.previewGear then
					local ok, list = pcall(opts.previewGear, doll, id)
					if ok and type(list) == "table" then
						for _, inst in ipairs(list) do
							if typeof(inst) == "Instance" and inst.Parent and not inst:IsDescendantOf(doll) then
								inst.Parent = doll
							end
						end
					end
				end
				-- 게임패스 권법은 꼬리 · 마검을 강화 단계대로
				local st0 = Config.STYLE_BY_ID[id]
				if st0 and st0.premium and opts.passPreview then
					local lv = (lastState.enh and lastState.enh[id]) or 0
					pcall(opts.passPreview, doll, id, lv)
				end
				pcall(Anim.watch, doll)
				slot.doll = doll
			end
			table.insert(slots, slot)
		end
	end
	-- 더 있으면 '다음 ▶' 받침대 (회랑 서쪽 끝)
	if pages > 1 then
		local at = (center :: Vector3) + Vector3.new(48, 0.6, -36)
		local nb = newPart({ Name = "GalleryNext", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 4, 4), CFrame = CFrame.new(at + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 208, 110), Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = true, Parent = f })
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = string.format("다음 권법 (%d / %d)", page, pages)
		pp.ObjectText = "권법 회랑"
		pp.HoldDuration = 0
		pp.MaxActivationDistance = 9
		pp.KeyboardKeyCode = Enum.KeyCode.T
		pp.Parent = nb
		pp.Triggered:Connect(function()
			page = page % pages + 1
			build()
		end)
	end
end

function Gallery.update(state: any)
	lastState = state
	if center then
		pcall(build)
	end
end

function Gallery.start(o: any)
	opts = o or {}
	task.spawn(function()
		local maps = workspace:WaitForChild("BattleMaps", 60)
		local bed = maps and maps:WaitForChild("CourtBed", 60)
		if not bed or not bed:IsA("BasePart") then
			return
		end
		center = bed.Position - Vector3.new(0, 0.2, 0)
		local f = Instance.new("Folder")
		f.Name = "KwonGallery"
		f.Parent = workspace
		folder = f
		player.CharacterAppearanceLoaded:Connect(function()
			builtKey = ""
			pcall(build)
		end)
		pcall(build)
		-- 가까이 있으면 차례로 시범 (한 번에 둘까지)
		-- 고리 돌리기 (화면마다)
		local RunService = game:GetService("RunService")
		RunService.RenderStepped:Connect(function(dt)
			for i, r in ipairs(spinners) do
				if r.Parent then
					r.CFrame = r.CFrame * CFrame.Angles(dt * (1 + (i % 3) * 0.3), 0, 0)
				end
			end
		end)
		local onPad: { [any]: boolean } = {}
		local sentAt = 0
		while true do
			task.wait(0.12)
			local char = player.Character
			local me = char and char:FindFirstChild("HumanoidRootPart")
			local inArena = char and char:GetAttribute("InArena") == true
			-- 발판 밟기: 밖에서 발판 위로 올라선 순간 그 권법으로 입장 (발판 위에서 태어난 것은 치지 않는다)
			if me and me:IsA("BasePart") and not inArena then
				for _, s in ipairs(slots) do
					local pa = s.padAt :: Vector3?
					if pa then
						local d = me.Position - pa
						local on = math.abs(d.X) < 4.2 and math.abs(d.Z) < 5.2 and d.Y > -1 and d.Y < 6
						if on and onPad[s] == false and os.clock() - sentAt > 2 and opts.request then
							sentAt = os.clock()
							opts.request:FireServer("battleEnter", s.id)
							pcall(Fx.ring, pa + Vector3.new(0, 0.5, 0), Color3.new(1, 1, 1), 1, 10, 0.4)
						end
						onPad[s] = on
					end
				end
			else
				table.clear(onPad)
			end
			if me and me:IsA("BasePart") and not inArena then
				local busy = 0
				local now = os.clock()
				for _, s in ipairs(slots) do
					if s.doll and s.doll.Parent and Anim.playing(s.doll) then
						busy += 1
					end
				end
				for _, s in ipairs(slots) do
					local d = s.doll
					if d and d.Parent and busy < 2 and now >= s.next and (s.at - me.Position).Magnitude < 45 and not Anim.playing(d) then
						local st = Config.STYLE_BY_ID[s.id]
						local picks: { any } = { 1, 2, 3, 4, "H", "E", "R", "G" }
						local slot = picks[math.random(1, #picks)]
						local mv = st and Config.move(s.id, slot)
						if mv then
							pcall(Anim.play, d, mv.pose, mv.dur)
							pcall(Fx.limbTrails, d, mv.pose, mv.dur, st.color, st.color2)
							if slot == "E" or slot == "R" or slot == "G" then
								local hrp = d:FindFirstChild("HumanoidRootPart") :: BasePart?
								if hrp then
									pcall(Fx.ring, hrp.Position - Vector3.new(0, 2.6, 0), st.color2 or st.color, 1, 9, 0.4)
								end
							end
							busy += 1
						end
						s.next = now + 2.2 + math.random() * 1.6
					end
				end
			end
		end
	end)
end

return Gallery
