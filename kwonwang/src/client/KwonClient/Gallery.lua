-- 권왕 3.62판: 배틀그라운드 대기실의 권법 회랑 (권법 고르는 창 대신)
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
local lastState: any = nil

local COLS, ROWS = 5, 3
local PER = COLS * ROWS
local INK = Color3.fromRGB(16, 18, 24)

local BODY = { HumanoidRootPart = true, Head = true, UpperTorso = true, LowerTorso = true, LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true, LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true }
local KEEP = { Accessory = true, Humanoid = true, Shirt = true, Pants = true, ShirtGraphic = true, BodyColors = true }

local function gradeOf(id: string): string
	local s = Config.STYLE_BY_ID[id]
	local ups = (lastState and lastState.gradeUp and lastState.gradeUp[id]) or 0
	return s and Config.styleGrade(s, ups) or "상급"
end

local function makeDoll(): Model?
	local char = player.Character
	if not char then
		return nil
	end
	local old = char.Archivable
	char.Archivable = true
	local ok, cl = pcall(function()
		return char:Clone()
	end)
	char.Archivable = old
	if not ok or not cl then
		return nil
	end
	local doll = cl :: Model
	for _, ch in ipairs(doll:GetChildren()) do
		local keep = (ch:IsA("BasePart") and BODY[ch.Name]) or KEEP[ch.ClassName]
		if not keep then
			ch:Destroy()
		end
	end
	for _, d in ipairs(doll:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = d.Name == "HumanoidRootPart"
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	local hum = doll:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.PlatformStand = true
	end
	return doll
end

local function newPart(props: { [string]: any }): BasePart
	local p = Instance.new(props.Class or "Part") :: BasePart
	p.Anchored = true
	p.CanCollide = props.CanCollide == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Class" and k ~= "Parent" and k ~= "CanCollide" then
			(p :: any)[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

-- 이름표 (위에 뜨는 납작한 판: 이름 · 등급 띠)
local function nameTag(target: BasePart, st: any, grade: string, using: boolean)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 190, 0, 54)
	bb.StudsOffset = Vector3.new(0, 4.6, 0)
	bb.MaxDistance = 80
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.Parent = target
	local fr = Instance.new("Frame")
	fr.Size = UDim2.fromScale(1, 1)
	fr.BackgroundColor3 = INK
	fr.BackgroundTransparency = 0.2
	fr.BorderSizePixel = 0
	fr.Parent = bb
	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(0, 10)
	cr.Parent = fr
	local sk = Instance.new("UIStroke")
	sk.Color = using and Color3.fromRGB(255, 208, 110) or st.color
	sk.Thickness = using and 2 or 1
	sk.Parent = fr
	local nm = Instance.new("TextLabel")
	nm.BackgroundTransparency = 1
	nm.Position = UDim2.new(0, 10, 0, 4)
	nm.Size = UDim2.new(1, -20, 0, 26)
	nm.Font = Enum.Font.GothamBlack
	nm.TextSize = 18
	nm.TextColor3 = Color3.new(1, 1, 1)
	nm.TextXAlignment = Enum.TextXAlignment.Left
	nm.TextTruncate = Enum.TextTruncate.AtEnd
	nm.Text = (st.icon or "") .. " " .. st.name
	nm.Parent = fr
	local gc = Config.GRADE_COLOR[grade] or Color3.fromRGB(255, 208, 110)
	local chip = Instance.new("TextLabel")
	chip.Position = UDim2.new(0, 10, 0, 30)
	chip.Size = UDim2.new(0, 56, 0, 18)
	chip.BackgroundColor3 = gc
	chip.Font = Enum.Font.GothamBlack
	chip.TextSize = 12
	chip.TextColor3 = INK
	chip.Text = grade
	chip.Parent = fr
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 9)
	cc.Parent = chip
	if using then
		local u = Instance.new("TextLabel")
		u.BackgroundTransparency = 1
		u.Position = UDim2.new(0, 72, 0, 30)
		u.Size = UDim2.new(1, -82, 0, 18)
		u.Font = Enum.Font.GothamBold
		u.TextSize = 12
		u.TextColor3 = Color3.fromRGB(255, 208, 110)
		u.TextXAlignment = Enum.TextXAlignment.Left
		u.Text = "지금 쓰는 권법"
		u.Parent = fr
	end
end

local function clear()
	for _, s in ipairs(slots) do
		if s.doll then
			s.doll:Destroy()
		end
	end
	slots = {}
	if folder then
		folder:ClearAllChildren()
	end
end

-- 받침대 자리 (마당 동쪽 절반, 5 × 3)
local function spotAt(i: number): Vector3
	local c = center :: Vector3
	local col = (i - 1) % COLS
	local row = (i - 1) // COLS
	return c + Vector3.new(30 + col * 9, 0.6, -16 + row * 14)
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
			local base = newPart({ Name = "GalleryBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 6, 6), CFrame = CFrame.new(at + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = INK, Material = Enum.Material.SmoothPlastic, CanCollide = true, Parent = f })
			newPart({ Name = "GalleryRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 6.4, 6.4), CFrame = CFrame.new(at + Vector3.new(0, 0.82, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = using and Color3.fromRGB(255, 208, 110) or st.color, Material = Enum.Material.Neon, Transparency = 0.25, Parent = f })
			local doll = makeDoll()
			local slot: any = { id = id, at = at, base = base, next = os.clock() + 1 + k * 0.4 }
			if doll then
				doll.Name = "GalleryDoll"
				doll:SetAttribute("Style", id)
				doll.Parent = f
				-- 받침대 위에 서서 마당 가운데 (서쪽) 를 본다
				local hrp = doll:FindFirstChild("HumanoidRootPart") :: BasePart?
				local hip = 3
				local hum = doll:FindFirstChildOfClass("Humanoid")
				if hum and hrp then
					hip = hum.HipHeight + hrp.Size.Y / 2
				end
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
				if hrp then
					nameTag(hrp, st, gradeOf(id), using)
				end
			end
			local pp = Instance.new("ProximityPrompt")
			pp.ActionText = "이 권법으로 싸움터에"
			pp.ObjectText = st.name
			pp.HoldDuration = 0
			pp.MaxActivationDistance = 9
			pp.RequiresLineOfSight = false
			pp.KeyboardKeyCode = Enum.KeyCode.T
			pp.Parent = base
			pp.Triggered:Connect(function()
				if opts.request then
					opts.request:FireServer("battleEnter", id)
				end
			end)
			table.insert(slots, slot)
		end
	end
	-- 더 있으면 '다음 ▶' 받침대 (회랑 서쪽 끝)
	if pages > 1 then
		local at = (center :: Vector3) + Vector3.new(22, 0.6, -2)
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
		while true do
			task.wait(0.25)
			local char = player.Character
			local me = char and char:FindFirstChild("HumanoidRootPart")
			local inArena = char and char:GetAttribute("InArena") == true
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
