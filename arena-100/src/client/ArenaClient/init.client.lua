-- ArenaClient (LocalScript, StarterPlayer > StarterPlayerScripts)
-- 화면 UI와 조작. 계산은 서버가 하고, 여기서는 보여 주고 요청만 보낸다.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))
local Effects = require(script:WaitForChild("Effects"))
local remotes = ReplicatedStorage:WaitForChild("ArenaRemotes")
local Request = remotes:WaitForChild("Request") :: RemoteEvent
local Push = remotes:WaitForChild("Push") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local state: any = nil
local myStats: any = nil
local battle: any = { active = false }

------------------------------------------------------------------------
-- UI 도구
------------------------------------------------------------------------
local C = {
	bg = Color3.fromRGB(20, 16, 15),
	panel = Color3.fromRGB(36, 28, 25),
	panel2 = Color3.fromRGB(54, 42, 36),
	panel3 = Color3.fromRGB(74, 58, 48),
	line = Color3.fromRGB(125, 96, 64),
	gold = Color3.fromRGB(255, 198, 72),
	goldDeep = Color3.fromRGB(196, 130, 36),
	text = Color3.fromRGB(246, 238, 224),
	dim = Color3.fromRGB(178, 162, 146),
	red = Color3.fromRGB(214, 62, 54),
	green = Color3.fromRGB(76, 196, 110),
	blue = Color3.fromRGB(64, 132, 226),
}

local function new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			else
				(inst :: any)[k] = v
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(radius: number?): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(color: Color3?, thickness: number?): UIStroke
	return new("UIStroke", {
		Color = color or C.line,
		Thickness = thickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function pad(px: number): UIPadding
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
	})
end

-- 위가 밝고 아래가 어두운 판
local function shade(top: Color3, bottom: Color3, rotation: number?): UIGradient
	return new("UIGradient", { Color = ColorSequence.new(top, bottom), Rotation = rotation or 90 })
end

local function lighten(c: Color3, t: number): Color3
	return c:Lerp(Color3.new(1, 1, 1), t)
end

local function darken(c: Color3, t: number): Color3
	return c:Lerp(Color3.new(0, 0, 0), t)
end

local function text(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = C.text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	return new("TextLabel", defaults)
end

local function button(props: { [string]: any }, onClick: () -> ()): TextButton
	local base: Color3 = props.BackgroundColor3 or C.panel3
	local defaults = {
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = true,
		Font = Enum.Font.GothamBlack,
		TextColor3 = C.text,
		TextSize = 15,
		TextStrokeTransparency = 0.6,
	}
	for k, v in pairs(props) do
		if k ~= "BackgroundColor3" then
			defaults[k] = v
		end
	end
	local b = new("TextButton", defaults, {
		corner(8),
		stroke(darken(base, 0.45), 1.5),
		shade(lighten(base, 0.12), darken(base, 0.2)),
	})
	b.Activated:Connect(onClick)
	return b
end

local function setButtonColor(b: TextButton, base: Color3)
	local g = b:FindFirstChildOfClass("UIGradient")
	if g then
		g.Color = ColorSequence.new(lighten(base, 0.12), darken(base, 0.2))
	end
	local s = b:FindFirstChildOfClass("UIStroke")
	if s then
		s.Color = darken(base, 0.45)
	end
end

local RAINBOW = WeaponBuilder.RAINBOW

local function setGradeColor(label: TextLabel, grade: number)
	local old = label:FindFirstChildOfClass("UIGradient")
	if old then
		old:Destroy()
	end
	local section = Config.getSection(grade)
	if section.rainbow then
		label.TextColor3 = Color3.new(1, 1, 1)
		new("UIGradient", { Color = RAINBOW, Parent = label })
	else
		label.TextColor3 = section.color
	end
end

local function weaponTitle(key: string): (string, any)
	local info = Config.weaponInfo(key)
	if not info then
		return "?", nil
	end
	if info.typeId == 0 then
		return "올라운더", info
	end
	return string.format("[%d] %s %s", info.grade, info.gradeData.en, info.type.name), info
end

local function weaponColor(info: any): Color3
	if info.typeId == 0 then
		return C.gold
	end
	return info.rarity.color
end

local fmt = Config.formatNumber

-- 무기 3D 미리보기
local function weaponViewport(parent: GuiObject, key: string, spin: boolean): ViewportFrame?
	local info = Config.weaponInfo(key)
	if not info then
		return nil
	end
	local vp = new("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 175, 165),
		LightColor = Color3.fromRGB(255, 240, 220),
		LightDirection = Vector3.new(-1, -1, -0.6),
		Parent = parent,
	})
	local world = new("Model", { Parent = vp })
	local hand = new("Part", {
		Anchored = true,
		Transparency = 1,
		Size = Vector3.new(0.5, 0.5, 0.5),
		CFrame = CFrame.new(),
		Parent = world,
	})
	world.PrimaryPart = hand
	local _, sectionIndex = Config.getSection(info.grade)
	if info.typeId == 0 then
		sectionIndex = 6
	end
	WeaponBuilder.build(world, hand, info.typeId, {
		accent = info.typeId == 0 and Color3.fromRGB(255, 235, 160) or info.rarity.color,
		section = sectionIndex,
		rarity = info.rarity.rank,
		scale = 1,
	}, CFrame.new(0, -3, 0))
	local cam = new("Camera", { FieldOfView = 38, Parent = vp })
	vp.CurrentCamera = cam
	local bbCf, bbSize = world:GetBoundingBox()
	local dist = math.max(bbSize.X, bbSize.Y, bbSize.Z) * 1.45 + 1
	local focus = bbCf.Position
	cam.CFrame = CFrame.lookAt(focus + Vector3.new(dist * 0.25, dist * 0.1, dist), focus)
	if spin then
		local conn
		conn = RunService.RenderStepped:Connect(function()
			if not vp.Parent then
				conn:Disconnect()
				return
			end
			world:PivotTo(CFrame.Angles(0, os.clock() * 1.2, math.rad(-12)))
		end)
	else
		world:PivotTo(CFrame.Angles(0, math.rad(35), math.rad(-12)))
	end
	return vp
end

------------------------------------------------------------------------
-- 화면 뼈대
------------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "ArenaUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

local uiScaleValue = 1
do
	local cam = workspace.CurrentCamera
	if cam and cam.ViewportSize.Y < 520 then
		uiScaleValue = 0.78
	end
end
local function addScale(frame: GuiObject): UIScale
	return new("UIScale", { Name = "AutoScale", Scale = uiScaleValue, Parent = frame })
end

-- 상단 바: 코인, 전투력, 등급
local topBar = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.new(0, 600, 0, 44),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
	}),
})
addScale(topBar)

local function chip(width: number, accent: Color3): (Frame, TextLabel, UIStroke)
	local s = stroke(accent, 2)
	local f = new("Frame", {
		Size = UDim2.new(0, width, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = topBar,
	}, { corner(12), s, shade(C.panel2, C.bg) })
	local label = text({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.5,
		Parent = f,
	})
	return f, label, s
end
local _, coinLabel = chip(170, C.goldDeep)
local _, powerLabel = chip(180, C.red)
local _, rankLabel, rankStroke = chip(220, C.line)
coinLabel.TextColor3 = C.gold

-- 왼쪽 메뉴
local menu = new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.new(0, 136, 0, 4 * 56),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	new("UIListLayout", { Padding = UDim.new(0, 8) }),
})
addScale(menu)

-- 가운데 창
local window = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.53, 0),
	Size = UDim2.new(0.64, 0, 0.76, 0),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = false,
	Parent = gui,
}, {
	corner(16),
	stroke(C.gold, 2.5),
	shade(C.panel, C.bg),
	new("UISizeConstraint", { MaxSize = Vector2.new(700, 520), MinSize = Vector2.new(330, 270) }),
})
local windowScale = addScale(window)
local header = new("Frame", {
	Size = UDim2.new(1, 0, 0, 52),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = window,
}, { corner(16), shade(Color3.fromRGB(150, 40, 36), Color3.fromRGB(70, 20, 20)) })
new("Frame", {
	Position = UDim2.new(0, 0, 1, -3),
	Size = UDim2.new(1, 0, 0, 3),
	BackgroundColor3 = C.gold,
	BorderSizePixel = 0,
	Parent = header,
})
local windowTitle = text({
	Position = UDim2.new(0, 18, 0, 0),
	Size = UDim2.new(1, -80, 1, -3),
	TextSize = 24,
	Font = Enum.Font.GothamBlack,
	TextColor3 = C.gold,
	TextStrokeTransparency = 0.3,
	Parent = header,
})
button({
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -10, 0.5, -1),
	Size = UDim2.new(0, 38, 0, 34),
	Text = "✕",
	TextSize = 18,
	BackgroundColor3 = C.red,
	Parent = header,
}, function()
	window.Visible = false
end)
local pages = new("Frame", {
	Position = UDim2.new(0, 14, 0, 62),
	Size = UDim2.new(1, -28, 1, -74),
	BackgroundTransparency = 1,
	Parent = window,
})

local pageFrames: { [string]: Frame } = {}
local currentPage = ""
local refreshers: { [string]: () -> () } = {}

local function makePage(name: string): Frame
	local f = new("Frame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = pages,
	})
	pageFrames[name] = f
	return f
end

local PAGE_TITLES = {
	stage = "⚔  스테이지",
	armory = "🗡  무기고",
	train = "💪  훈련장",
	help = "📜  도움말",
}

local function openPage(name: string, force: boolean?)
	if window.Visible and currentPage == name and not force then
		window.Visible = false
		return
	end
	currentPage = name
	for n, f in pairs(pageFrames) do
		f.Visible = (n == name)
	end
	windowTitle.Text = PAGE_TITLES[name] or name
	if not window.Visible then
		window.Visible = true
		windowScale.Scale = uiScaleValue * 0.88
		TweenService:Create(windowScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScaleValue }):Play()
	end
	local r = refreshers[name]
	if r then
		r()
	end
end

for _, item in ipairs({
	{ "stage", "⚔", "스테이지", C.red },
	{ "armory", "🗡", "무기고", C.blue },
	{ "train", "💪", "훈련", C.green },
	{ "help", "📜", "도움말", C.panel3 },
}) do
	local b = button({
		Size = UDim2.new(1, 0, 0, 48),
		Text = "",
		BackgroundColor3 = item[4],
		Parent = menu,
	}, function()
		openPage(item[1])
	end)
	text({
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(0, 34, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 22,
		Text = item[2],
		Parent = b,
	})
	text({
		Position = UDim2.new(0, 44, 0, 0),
		Size = UDim2.new(1, -48, 1, 0),
		TextSize = 17,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.5,
		Text = item[3],
		Parent = b,
	})
end

-- 알림
local toastFrame = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -160),
	Size = UDim2.new(0, 540, 0, 44),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = false,
	ZIndex = 20,
	Parent = gui,
}, { corner(12), stroke(C.gold, 1.5), shade(C.panel2, C.bg) })
local toastLabel = text({
	Size = UDim2.fromScale(1, 1),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 17,
	ZIndex = 21,
	Parent = toastFrame,
})
addScale(toastFrame)
local toastToken = 0
local function toast(msg: string)
	toastToken += 1
	local my = toastToken
	toastLabel.Text = msg
	toastFrame.Visible = true
	task.delay(2.6, function()
		if toastToken == my then
			toastFrame.Visible = false
		end
	end)
end

------------------------------------------------------------------------
-- 스테이지 페이지
------------------------------------------------------------------------
local stagePage = makePage("stage")
text({
	Size = UDim2.new(1, 0, 0, 36),
	TextSize = 13,
	TextColor3 = C.dim,
	Text = "🔒 잠김   ⚔ 도전 가능   ✅ 승리   🔁 자동 반복 가능 (이긴 스테이지 + 권장 전투력 1.5배)\n👑 10스테이지마다 보스가 나와요.",
	Parent = stagePage,
})
local stageList = new("ScrollingFrame", {
	Position = UDim2.new(0, 0, 0, 40),
	Size = UDim2.new(1, 0, 1, -40),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = C.gold,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = stagePage,
}, {
	new("UIListLayout", { Padding = UDim.new(0, 5) }),
})

type StageRow = {
	frame: Frame,
	power: TextLabel,
	status: TextLabel,
	play: TextButton,
	auto: TextButton,
}
local stageRows: { StageRow } = {}

local function requestStart(n: number, auto: boolean)
	if battle.active then
		toast("전투 중에는 새 스테이지를 시작할 수 없어요")
		return
	end
	window.Visible = false
	Request:FireServer("start", n, auto)
end

for n = 1, Config.MAX_GRADE do
	local isBoss = n % 10 == 0
	local section = Config.getSection(n)
	local top = isBoss and Color3.fromRGB(105, 34, 30) or C.panel3
	local bottom = isBoss and Color3.fromRGB(55, 16, 16) or C.panel2
	local row = new("Frame", {
		LayoutOrder = n,
		Size = UDim2.new(1, -12, 0, 52),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = stageList,
	}, { corner(10), shade(top, bottom), stroke(isBoss and C.gold or darken(section.color, 0.5), isBoss and 2 or 1) })
	new("Frame", {
		Size = UDim2.new(0, 6, 1, -10),
		Position = UDim2.new(0, 5, 0, 5),
		BackgroundColor3 = section.color,
		BorderSizePixel = 0,
		Parent = row,
	}, { corner(3) })
	local grade = Config.getGrade(n)
	local nameLabel = text({
		Position = UDim2.new(0, 20, 0, 4),
		Size = UDim2.new(0.52, -20, 0, 26),
		TextSize = 17,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.5,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = false,
		Text = string.format("%s%d. %s", isBoss and "👑 " or "", n, grade.en),
		Parent = row,
	})
	setGradeColor(nameLabel, n)
	text({
		Position = UDim2.new(0, 20, 0, 29),
		Size = UDim2.new(0.52, -20, 0, 18),
		TextSize = 12,
		TextColor3 = C.dim,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = false,
		Text = grade.ko .. (isBoss and "  ·  BOSS" or ""),
		Parent = row,
	})
	local powerLabel2 = text({
		Position = UDim2.new(0.52, 0, 0, 0),
		Size = UDim2.new(0.2, 0, 1, 0),
		TextSize = 13,
		TextColor3 = C.dim,
		Parent = row,
	})
	local status = text({
		Position = UDim2.new(1, -158, 0, 0),
		Size = UDim2.new(0, 32, 1, 0),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "🔒",
		Parent = row,
	})
	local play = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -66, 0.5, 0),
		Size = UDim2.new(0, 58, 0, 36),
		Text = "도전",
		BackgroundColor3 = isBoss and C.red or C.blue,
		Parent = row,
	}, function()
		requestStart(n, false)
	end)
	local auto = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -4, 0.5, 0),
		Size = UDim2.new(0, 58, 0, 36),
		Text = "🔁자동",
		TextSize = 13,
		BackgroundColor3 = C.green,
		Parent = row,
	}, function()
		requestStart(n, true)
	end)
	stageRows[n] = { frame = row, power = powerLabel2, status = status, play = play, auto = auto }
end

refreshers.stage = function()
	if not state then
		return
	end
	for n, row in ipairs(stageRows) do
		local rec = Config.recommendedPower(n)
		row.power.Text = "권장 ⚔" .. fmt(rec)
		local unlocked = n <= state.maxStage + 1
		local canAuto = Config.canAutoRepeat(n, state.maxStage, state.power)
		row.play.Visible = unlocked
		row.auto.Visible = canAuto
		row.frame.BackgroundTransparency = unlocked and 0 or 0.35
		if canAuto then
			row.status.Text = "🔁"
		elseif n <= state.maxStage then
			row.status.Text = "✅"
		elseif unlocked then
			row.status.Text = "⚔"
		else
			row.status.Text = "🔒"
		end
	end
	local target = math.clamp(state.maxStage - 2, 0, Config.MAX_GRADE)
	stageList.CanvasPosition = Vector2.new(0, target * 57)
end

------------------------------------------------------------------------
-- 무기고 페이지
------------------------------------------------------------------------
local armoryPage = makePage("armory")
local equipCard = new("Frame", {
	Size = UDim2.new(1, 0, 0, 104),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = armoryPage,
}, { corner(12), shade(C.panel3, C.panel) })
local equipStroke = stroke(C.gold, 2)
equipStroke.Parent = equipCard
local equipView = new("Frame", {
	Position = UDim2.new(0, 6, 0, 6),
	Size = UDim2.new(0, 92, 0, 92),
	BackgroundColor3 = C.bg,
	Parent = equipCard,
}, { corner(10) })
local equipTag = text({
	Position = UDim2.new(0, 110, 0, 8),
	Size = UDim2.new(1, -120, 0, 16),
	TextSize = 12,
	TextColor3 = C.dim,
	Text = "장착 중",
	Parent = equipCard,
})
local equipName = text({
	Position = UDim2.new(0, 110, 0, 24),
	Size = UDim2.new(1, -120, 0, 26),
	TextSize = 20,
	Font = Enum.Font.GothamBlack,
	TextStrokeTransparency = 0.5,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextWrapped = false,
	Parent = equipCard,
})
local equipInfo = text({
	Position = UDim2.new(0, 110, 0, 52),
	Size = UDim2.new(1, -120, 0, 46),
	TextSize = 13,
	TextColor3 = C.dim,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = equipCard,
})
local shownEquipKey = ""

local armoryButtons = new("Frame", {
	Position = UDim2.new(0, 0, 0, 112),
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundTransparency = 1,
	Parent = armoryPage,
}, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }),
})
button({ Size = UDim2.new(0.32, 0, 1, 0), Text = "⭐ 가장 센 무기 장착", TextSize = 13, Parent = armoryButtons }, function()
	Request:FireServer("equipBest")
end)
button({ Size = UDim2.new(0.32, 0, 1, 0), Text = "🔨 모두 합성", TextSize = 13, BackgroundColor3 = C.blue, Parent = armoryButtons }, function()
	Request:FireServer("mergeAll")
end)
local arButton = button({
	Size = UDim2.new(0.32, 0, 1, 0),
	Text = "🌈 올라운더 만들기",
	TextSize = 13,
	BackgroundColor3 = C.goldDeep,
	Parent = armoryButtons,
}, function()
	Request:FireServer("allrounder")
end)

local invList = new("ScrollingFrame", {
	Position = UDim2.new(0, 0, 0, 158),
	Size = UDim2.new(1, 0, 1, -158),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = C.gold,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = armoryPage,
}, {
	new("UIGridLayout", {
		CellSize = UDim2.new(0, 150, 0, 112),
		CellPadding = UDim2.new(0, 7, 0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

refreshers.armory = function()
	if not state then
		return
	end
	local title, info = weaponTitle(state.equipped)
	equipName.Text = title
	if info then
		local wc = weaponColor(info)
		setGradeColor(equipName, info.grade)
		equipStroke.Color = wc
		equipTag.Text = string.format("장착 중  ·  %s  ·  %s", info.typeId == 0 and "최종 무기" or info.rarity.name, info.type.desc)
		equipTag.TextColor3 = wc
		equipInfo.Text = string.format(
			"공격력 %s   ·   공격 간격 %.2f초   ·   체력 %s\n치명타 %d%% (%.1f배)   ·   전투력 %s",
			fmt(myStats.atk),
			myStats.cooldown,
			fmt(myStats.maxHp),
			math.floor((info.type.critChance or 0) * 100 + 0.5),
			info.type.critMult or 1,
			fmt(state.power)
		)
		if shownEquipKey ~= state.equipped then
			shownEquipKey = state.equipped
			for _, c in ipairs(equipView:GetChildren()) do
				if c:IsA("ViewportFrame") then
					c:Destroy()
				end
			end
			weaponViewport(equipView, state.equipped, true)
		end
	end

	local hasAll = true
	for t = 1, 5 do
		if (state.inv[Config.itemKey(Config.MAX_GRADE, t)] or 0) < 1 then
			hasAll = false
		end
	end
	arButton.TextTransparency = hasAll and 0 or 0.45

	for _, child in ipairs(invList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local keys = {}
	for key in pairs(state.inv) do
		if Config.parseKey(key) then
			table.insert(keys, key)
		end
	end
	table.sort(keys, function(a, b)
		local ga, ta = Config.parseKey(a)
		local gb, tb = Config.parseKey(b)
		if ta == 0 then
			return tb ~= 0
		elseif tb == 0 then
			return false
		end
		if ga ~= gb then
			return ga > gb
		end
		return Config.rarityRank(ga, ta) > Config.rarityRank(gb, tb)
	end)
	for i, key in ipairs(keys) do
		local count = state.inv[key]
		local wTitle, w = weaponTitle(key)
		if w then
			local isEquipped = key == state.equipped
			local cost = w.typeId == 0 and 0 or Config.mergeCost(w.grade)
			local canMerge = w.typeId ~= 0 and w.grade < Config.MAX_GRADE and count >= cost
			local rc = weaponColor(w)
			local cell = new("Frame", {
				LayoutOrder = i,
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = invList,
			}, {
				corner(10),
				stroke(rc, isEquipped and 3 or 1.5),
				shade(darken(rc, 0.55), C.panel, 90),
			})
			local nameL = text({
				Position = UDim2.new(0, 8, 0, 4),
				Size = UDim2.new(1, -16, 0, 34),
				TextSize = 13,
				Font = Enum.Font.GothamBlack,
				TextStrokeTransparency = 0.5,
				Text = wTitle,
				Parent = cell,
			})
			setGradeColor(nameL, w.grade)
			text({
				Position = UDim2.new(0, 8, 0, 38),
				Size = UDim2.new(1, -16, 0, 18),
				TextSize = 12,
				TextColor3 = lighten(rc, 0.2),
				Text = string.format("%s  ·  보유 %d%s", w.typeId == 0 and "최종" or w.rarity.name, count, w.typeId == 0 and "" or ("/" .. cost)),
				Parent = cell,
			})
			if isEquipped then
				local badge = text({
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -6, 0, -8),
					Size = UDim2.new(0, 40, 0, 18),
					BackgroundTransparency = 0,
					BackgroundColor3 = C.gold,
					TextColor3 = C.bg,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextSize = 11,
					Font = Enum.Font.GothamBlack,
					Text = "장착",
					Parent = cell,
				})
				corner(6).Parent = badge
			end
			button({
				Position = UDim2.new(0, 6, 1, -42),
				Size = UDim2.new(0.5, -9, 0, 36),
				Text = isEquipped and "장착중" or "장착",
				TextSize = 13,
				BackgroundColor3 = isEquipped and C.goldDeep or C.panel3,
				Parent = cell,
			}, function()
				Request:FireServer("equip", key)
			end)
			local mergeBtn = button({
				Position = UDim2.new(0.5, 3, 1, -42),
				Size = UDim2.new(0.5, -9, 0, 36),
				Text = "합성",
				TextSize = 13,
				BackgroundColor3 = canMerge and C.blue or C.panel2,
				Parent = cell,
			}, function()
				Request:FireServer("merge", key)
			end)
			if not canMerge then
				mergeBtn.TextTransparency = 0.55
			end
		end
	end
end

------------------------------------------------------------------------
-- 훈련 페이지
------------------------------------------------------------------------
local trainPage = makePage("train")
new("UIListLayout", { Padding = UDim.new(0, 10), Parent = trainPage })
text({
	Size = UDim2.new(1, 0, 0, 36),
	TextSize = 13,
	TextColor3 = C.dim,
	Text = "코인으로 기본 능력을 올려요. 레벨당 +8%이고, 무기를 바꿔도 그대로 남아요.",
	Parent = trainPage,
})

local function trainCard(kind: string, icon: string, titleText: string, accent: Color3): (TextLabel, TextButton)
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 84),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = trainPage,
	}, { corner(12), stroke(accent, 1.5), shade(darken(accent, 0.6), C.panel) })
	text({
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0, 50, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 34,
		Text = icon,
		Parent = card,
	})
	text({
		Position = UDim2.new(0, 70, 0, 14),
		Size = UDim2.new(1, -230, 0, 26),
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		Text = titleText,
		Parent = card,
	})
	local info = text({
		Position = UDim2.new(0, 70, 0, 42),
		Size = UDim2.new(1, -230, 0, 26),
		TextSize = 14,
		TextColor3 = C.dim,
		Parent = card,
	})
	local b = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 150, 0, 50),
		TextSize = 15,
		BackgroundColor3 = C.goldDeep,
		Parent = card,
	}, function()
		Request:FireServer("train", kind)
	end)
	return info, b
end
local atkInfo, atkBtn = trainCard("atk", "⚔", "공격 훈련", C.red)
local hpInfo, hpBtn = trainCard("hp", "❤", "체력 훈련", C.green)

refreshers.train = function()
	if not state then
		return
	end
	atkInfo.Text = string.format("Lv.%d  ·  공격력 +%d%%", state.atkLv, math.floor(state.atkLv * Config.TRAIN_BONUS * 100 + 0.5))
	hpInfo.Text = string.format("Lv.%d  ·  체력 +%d%%", state.hpLv, math.floor(state.hpLv * Config.TRAIN_BONUS * 100 + 0.5))
	atkBtn.Text = "올리기  💰" .. fmt(Config.trainCost(state.atkLv))
	hpBtn.Text = "올리기  💰" .. fmt(Config.trainCost(state.hpLv))
end

------------------------------------------------------------------------
-- 도움말 페이지
------------------------------------------------------------------------
local helpPage = makePage("help")
local helpScroll = new("ScrollingFrame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = C.gold,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = helpPage,
})
local ultLines = {}
for _, id in ipairs({ 1, 2, 3, 4, 5, 0 }) do
	local wt = Config.weaponType(id)
	local u = Config.Ultimates[id]
	table.insert(ultLines, string.format("· %s — %s: %s", wt.name, u.name, u.desc))
end
text({
	Size = UDim2.new(1, -12, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	TextSize = 15,
	TextYAlignment = Enum.TextYAlignment.Top,
	Text = table.concat({
		"⚔ 싸우는 법",
		"· PC: 마우스 왼쪽 클릭(누르고 있으면 연속 공격), Q 또는 Shift로 대시, R로 필살기",
		"· 휴대폰: 오른쪽 아래 ⚔ 버튼을 누르고 있기, 💨 대시, 💥 필살기",
		"· 공격하면 가장 가까운 적에게 알아서 다가가요",
		"· 대시하는 순간에는 잠깐 무적이에요. 보스의 빨간 원을 피하세요!",
		"",
		"💥 필살기 (때릴수록 게이지가 차요)",
		table.concat(ultLines, "\n"),
		"",
		"🎯 치명타",
		"· 모든 무기 5% 확률로 1.8배, 단검은 30% 확률로 2.5배",
		"· 치명타를 맞은 적은 멀리 날아가요 (보스 제외)",
		"",
		"🗡 무기",
		"· 대검: 한 방이 강하고 느려요",
		"· 쌍검: 아주 빠르게 베요",
		"· 장검: 앞쪽 멀리, 최대 3명",
		"· 단검: 치명타가 잘 터져요",
		"· 낫: 내 주위를 한 바퀴 베고, 피해의 10%만큼 체력을 회복해요",
		"· 등급 구간이 오를수록 무기와 내 캐릭터가 점점 화려하게 빛나요",
		"",
		"✨ 희귀도",
		"· 같은 등급 안에서 일반 < 고급 < 희귀 < 영웅 < 전설",
		"· 등급이 하나 오를 때마다 전설이 되는 계열이 한 칸씩 바뀌어요",
		"",
		"🔨 합성",
		"· 같은 등급, 같은 계열 칼을 모아 합치면 다음 등급이 돼요",
		"· 1~20등급은 2개, 21~40등급은 3개, 41~60등급은 4개, 61~80등급은 5개, 81등급부터는 6개",
		"· 100등급 다섯 계열을 하나씩 모으면 최종 무기 '올라운더'를 만들 수 있어요",
		"",
		"🔁 자동 반복",
		"· 이긴 적 있는 스테이지 + 전투력이 권장의 1.5배 이상이면 자동으로 계속 싸워요",
		"· 자동 반복 중에는 게이지가 차면 필살기도 알아서 써요",
	}, "\n"),
	Parent = helpScroll,
})

------------------------------------------------------------------------
-- 전투 화면
------------------------------------------------------------------------
local hud = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 58),
	Size = UDim2.new(0, 470, 0, 98),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = false,
	Parent = gui,
}, { corner(12), shade(C.panel2, C.bg), pad(8) })
local hudStroke = stroke(C.line, 2)
hudStroke.Parent = hud
addScale(hud)
local hudTitle = text({
	Size = UDim2.new(1, 0, 0, 24),
	TextSize = 19,
	TextXAlignment = Enum.TextXAlignment.Center,
	Font = Enum.Font.GothamBlack,
	TextStrokeTransparency = 0.4,
	Parent = hud,
})
local function bar(y: number, height: number, top: Color3, bottom: Color3): (Frame, Frame, TextLabel)
	local back = new("Frame", {
		Position = UDim2.new(0, 0, 0, y),
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Color3.fromRGB(40, 22, 22),
		Parent = hud,
	}, { corner(6), stroke(Color3.fromRGB(0, 0, 0), 1) })
	local fill = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = back,
	}, { corner(6), shade(top, bottom) })
	local label = text({
		Size = UDim2.fromScale(1, 1),
		TextSize = 13,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
		Parent = back,
	})
	return back, fill, label
end
local _, hpFill, hpText = bar(28, 20, Color3.fromRGB(120, 230, 120), Color3.fromRGB(40, 150, 60))
local _, gaugeFill, gaugeText = bar(52, 14, Color3.fromRGB(255, 230, 120), Color3.fromRGB(230, 140, 30))
local enemyText = text({
	Position = UDim2.new(0, 0, 0, 68),
	Size = UDim2.new(1, 0, 0, 16),
	TextSize = 13,
	TextColor3 = C.dim,
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = hud,
})

local hudButtons = new("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 58),
	Size = UDim2.new(0, 128, 0, 90),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
}, { new("UIListLayout", { Padding = UDim.new(0, 8) }) })
addScale(hudButtons)
local autoBtn = button({ Size = UDim2.new(1, 0, 0, 40), Text = "🔁 자동 OFF", Parent = hudButtons }, function()
	Request:FireServer("auto", not battle.auto)
end)
button({ Size = UDim2.new(1, 0, 0, 40), Text = "🚪 나가기", BackgroundColor3 = C.red, Parent = hudButtons }, function()
	Request:FireServer("leave")
end)

local actionPad = new("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -28),
	Size = UDim2.new(0, 230, 0, 210),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})
addScale(actionPad)
local function roundButton(props: { [string]: any }, base: Color3, ring: Color3): TextButton
	local size = props.Size.X.Offset
	local b = new("TextButton", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = props.Text,
		TextSize = props.TextSize,
		Font = Enum.Font.GothamBlack,
		TextColor3 = C.text,
		AutoButtonColor = true,
		Parent = actionPad,
	}, { corner(size // 2), stroke(ring, 3), shade(lighten(base, 0.15), darken(base, 0.3)) })
	return b
end
local attackBtn = roundButton({
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 1, 0),
	Size = UDim2.new(0, 124, 0, 124),
	Text = "⚔",
	TextSize = 52,
}, C.red, C.gold)
local dashBtn = roundButton({
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -134, 1, -6),
	Size = UDim2.new(0, 76, 0, 76),
	Text = "💨",
	TextSize = 32,
}, C.blue, C.text)
local ultBtn = roundButton({
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -24, 1, -134),
	Size = UDim2.new(0, 76, 0, 76),
	Text = "💥",
	TextSize = 34,
}, C.goldDeep, C.gold)
local ultBtnStroke = ultBtn:FindFirstChildOfClass("UIStroke") :: UIStroke

local controlHint = text({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -8),
	Size = UDim2.new(0, 600, 0, 20),
	TextSize = 13,
	TextColor3 = C.dim,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextStrokeTransparency = 0.5,
	Text = "클릭(누르고 있기): 공격   ·   Q / Shift: 대시 (잠깐 무적)   ·   R: 필살기",
	Visible = false,
	Parent = gui,
})

-- 필살기 이름 배너
local ultBanner = text({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.3, 0),
	Size = UDim2.new(0, 700, 0, 80),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 60,
	Font = Enum.Font.GothamBlack,
	TextStrokeTransparency = 0,
	Visible = false,
	ZIndex = 15,
	Parent = gui,
})
local ultBannerScale = new("UIScale", { Parent = ultBanner })
local ultBannerToken = 0
local function showUltBanner(name: string, color: Color3)
	ultBannerToken += 1
	local my = ultBannerToken
	ultBanner.Text = "💥 " .. name
	ultBanner.TextColor3 = lighten(color, 0.3)
	ultBanner.TextStrokeColor3 = darken(color, 0.7)
	ultBanner.TextTransparency = 0
	ultBanner.TextStrokeTransparency = 0
	ultBanner.Visible = true
	ultBannerScale.Scale = 1.8 * uiScaleValue
	TweenService:Create(ultBannerScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScaleValue }):Play()
	task.delay(1.0, function()
		if ultBannerToken == my then
			TweenService:Create(ultBanner, TweenInfo.new(0.3), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- 결과 창
local resultFrame = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.42, 0),
	Size = UDim2.new(0, 440, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = false,
	ZIndex = 10,
	Parent = gui,
}, { corner(16), shade(C.panel2, C.bg), pad(16), new("UIListLayout", { Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center }) })
local resultStroke = stroke(C.gold, 3)
resultStroke.Parent = resultFrame
local resultScale = addScale(resultFrame)
local resultToken = 0

local function showResult(data: any)
	resultToken += 1
	local my = resultToken
	for _, child in ipairs(resultFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local order = 0
	local function line(str: string, color: Color3?, size: number?, gradient: ColorSequence?)
		order += 1
		local l = text({
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = size or 16,
			Font = Enum.Font.GothamBlack,
			TextStrokeTransparency = 0.4,
			TextColor3 = color or C.text,
			Text = str,
			ZIndex = 11,
			Parent = resultFrame,
		})
		if gradient then
			l.TextColor3 = Color3.new(1, 1, 1)
			new("UIGradient", { Color = gradient, Rotation = 90, Parent = l })
		end
	end
	if data.win then
		resultStroke.Color = C.gold
		line("VICTORY", nil, 46, ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(230, 140, 30)))
		line("+ 💰 " .. fmt(data.coins), C.gold, 20)
		if data.firstClear then
			local g = Config.getGrade(data.stage)
			line(string.format("🏅 새 등급 달성!  [%d] %s", data.stage, g.en), Config.getSection(data.stage).color, 19)
		end
		for _, key in ipairs(data.drops or {}) do
			local title, info = weaponTitle(key)
			line("획득  " .. title .. (info and ("  (" .. info.rarity.name .. ")") or ""), info and weaponColor(info) or C.text, 15)
		end
		if data.again then
			line("🔁 곧 다음 판이 자동으로 시작돼요", C.green, 14)
		end
		Effects.sound("ping", 0.5, 1.2)
	else
		resultStroke.Color = C.red
		line("DEFEAT", nil, 46, ColorSequence.new(Color3.fromRGB(255, 120, 110), Color3.fromRGB(140, 20, 20)))
		line("무기를 합성하거나 훈련해서 다시 도전해 보세요", C.dim, 15)
	end
	resultFrame.Visible = true
	resultScale.Scale = uiScaleValue * 0.7
	TweenService:Create(resultScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScaleValue }):Play()
	task.delay(data.win and 2.4 or 2.8, function()
		if resultToken == my then
			resultFrame.Visible = false
		end
	end)
end

-- 합성 성공 연출
local mergePopup = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.45, 0),
	Size = UDim2.new(0, 300, 0, 300),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = false,
	ZIndex = 30,
	Parent = gui,
}, { corner(20), shade(C.panel2, C.bg) })
local mergeStroke = stroke(C.gold, 3)
mergeStroke.Parent = mergePopup
local mergeScale = addScale(mergePopup)
local mergeTitle = text({
	Position = UDim2.new(0, 0, 0, 10),
	Size = UDim2.new(1, 0, 0, 34),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 26,
	Font = Enum.Font.GothamBlack,
	TextColor3 = C.gold,
	TextStrokeTransparency = 0.3,
	ZIndex = 31,
	Parent = mergePopup,
})
local mergeView = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 50),
	Size = UDim2.new(0, 180, 0, 180),
	BackgroundTransparency = 1,
	ZIndex = 31,
	Parent = mergePopup,
})
local mergeName = text({
	Position = UDim2.new(0, 10, 1, -66),
	Size = UDim2.new(1, -20, 0, 30),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 20,
	Font = Enum.Font.GothamBlack,
	TextStrokeTransparency = 0.4,
	ZIndex = 31,
	Parent = mergePopup,
})
local mergeSub = text({
	Position = UDim2.new(0, 10, 1, -36),
	Size = UDim2.new(1, -20, 0, 22),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 14,
	ZIndex = 31,
	Parent = mergePopup,
})
local mergeToken = 0
local function showMerge(key: string, count: number)
	local title, info = weaponTitle(key)
	if not info then
		return
	end
	mergeToken += 1
	local my = mergeToken
	local wc = weaponColor(info)
	mergeTitle.Text = info.typeId == 0 and "🌈 올라운더 탄생!" or (count > 1 and string.format("🔨 %d번 합성!", count) or "🔨 합성 성공!")
	mergeName.Text = title
	setGradeColor(mergeName, info.grade)
	mergeSub.Text = info.typeId == 0 and "최종 무기" or (info.rarity.name .. "  ·  " .. info.type.desc)
	mergeSub.TextColor3 = wc
	mergeStroke.Color = wc
	for _, c in ipairs(mergeView:GetChildren()) do
		c:Destroy()
	end
	weaponViewport(mergeView, key, true)
	mergePopup.Visible = true
	mergeScale.Scale = uiScaleValue * 0.5
	TweenService:Create(mergeScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScaleValue }):Play()
	Effects.sound("ping", 0.6, info.rarity.rank >= 5 and 1.5 or 1.2)
	task.delay(1.8, function()
		if mergeToken == my then
			mergePopup.Visible = false
			for _, c in ipairs(mergeView:GetChildren()) do
				c:Destroy()
			end
		end
	end)
end

------------------------------------------------------------------------
-- 갱신
------------------------------------------------------------------------
local function refreshTop()
	if not state then
		return
	end
	coinLabel.Text = "💰 " .. fmt(state.coins)
	powerLabel.Text = "⚔ " .. fmt(state.power)
	if state.maxStage > 0 then
		rankLabel.Text = string.format("🏅 %s", Config.getGrade(state.maxStage).en)
		setGradeColor(rankLabel, state.maxStage)
		rankStroke.Color = Config.getSection(state.maxStage).color
	else
		rankLabel.Text = "🏅 NO RANK"
		rankLabel.TextColor3 = C.dim
		rankStroke.Color = C.line
	end
end

local function refreshBattle()
	local active = battle.active == true
	hud.Visible = active
	hudButtons.Visible = active
	actionPad.Visible = active
	controlHint.Visible = active and not UserInputService.TouchEnabled
	if not active then
		return
	end
	local g = Config.getGrade(battle.stage)
	local section = Config.getSection(battle.stage)
	hudTitle.Text = string.format("%sSTAGE %d  ·  %s", battle.boss and "👑 " or "", battle.stage, g.en)
	setGradeColor(hudTitle, battle.stage)
	hudStroke.Color = battle.boss and C.red or section.color
	local ratio = math.clamp(battle.hp / math.max(battle.maxHp, 1), 0, 1)
	hpFill.Size = UDim2.fromScale(ratio, 1)
	local hpGrad = hpFill:FindFirstChildOfClass("UIGradient")
	if hpGrad then
		if ratio > 0.5 then
			hpGrad.Color = ColorSequence.new(Color3.fromRGB(120, 230, 120), Color3.fromRGB(40, 150, 60))
		elseif ratio > 0.25 then
			hpGrad.Color = ColorSequence.new(Color3.fromRGB(255, 220, 110), Color3.fromRGB(200, 140, 30))
		else
			hpGrad.Color = ColorSequence.new(Color3.fromRGB(255, 120, 100), Color3.fromRGB(170, 30, 30))
		end
	end
	hpText.Text = string.format("❤ %s / %s", fmt(battle.hp), fmt(battle.maxHp))
	local gauge = math.clamp((battle.gauge or 0) / 100, 0, 1)
	gaugeFill.Size = UDim2.fromScale(gauge, 1)
	local ready = gauge >= 1
	gaugeText.Text = ready and "💥 필살기 준비! (R)" or string.format("필살기 %d%%", math.floor(gauge * 100))
	ultBtn.TextTransparency = ready and 0 or 0.55
	ultBtnStroke.Thickness = ready and 5 or 3
	enemyText.Text = string.format("남은 적  %d / %d", battle.left, battle.total)
	autoBtn.Text = battle.auto and "🔁 자동 ON" or "🔁 자동 OFF"
	setButtonColor(autoBtn, battle.auto and C.green or C.panel3)
end

local function refreshAll()
	refreshTop()
	if window.Visible then
		local r = refreshers[currentPage]
		if r then
			r()
		end
	end
end

-- 필살기 버튼은 준비되면 숨 쉬듯 반짝인다
RunService.RenderStepped:Connect(function()
	if battle.active and (battle.gauge or 0) >= 100 then
		local pulse = (math.sin(os.clock() * 8) + 1) / 2
		ultBtnStroke.Color = C.gold:Lerp(Color3.new(1, 1, 1), pulse)
	end
end)

------------------------------------------------------------------------
-- 조작
------------------------------------------------------------------------
local fxFolder = new("Folder", { Name = "ArenaFX", Parent = workspace })

local function getChar(): (BasePart?, Humanoid?)
	local char = player.Character
	if not char then
		return nil, nil
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and hum and hum.Health > 0 then
		return root, hum
	end
	return nil, nil
end
Effects.init(fxFolder, getChar)

-- 로블록스 기본 R15 칼 휘두르기 동작
local slashAnim = new("Animation", { AnimationId = "rbxassetid://522635514" })
local slashTrack: AnimationTrack? = nil
local slashHum: Humanoid? = nil
local function playSlash(hum: Humanoid)
	if slashHum ~= hum then
		slashHum = hum
		slashTrack = nil
		pcall(function()
			local animator = hum:FindFirstChildOfClass("Animator")
			if animator then
				slashTrack = animator:LoadAnimation(slashAnim)
			end
		end)
	end
	local track = slashTrack
	if track then
		track:Play(0.05)
	end
end

local function nearestEnemy(root: BasePart): (BasePart?, number)
	local battles = workspace:FindFirstChild("ArenaBattles")
	local folder = battles and battles:FindFirstChild("P_" .. player.UserId)
	if not folder then
		return nil, math.huge
	end
	local best, bestDist = nil, math.huge
	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("Enemy") and not m:GetAttribute("Dead") then
			local r = m:FindFirstChild("HumanoidRootPart")
			if r and r:IsA("BasePart") then
				local d = (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
				if d < bestDist then
					best, bestDist = r, d
				end
			end
		end
	end
	return best, bestDist
end

local attackHeld = false
local lastTry = 0

local function tryAttack()
	if not battle.active or not myStats then
		return
	end
	local root, hum = getChar()
	if not root or not hum then
		return
	end
	lastTry = os.clock()
	local target, dist = nearestEnemy(root)
	if target then
		local tp = target.Position
		if dist > myStats.range * 0.8 then
			hum:MoveTo(tp)
		else
			root.CFrame = CFrame.lookAt(root.Position, Vector3.new(tp.X, root.Position.Y, tp.Z))
		end
	end
	Request:FireServer("attack")
end

local lastDash = 0
local function dash()
	if not battle.active then
		return
	end
	local now = os.clock()
	if now - lastDash < Config.DASH_COOLDOWN then
		return
	end
	local root, hum = getChar()
	if not root or not hum then
		return
	end
	lastDash = now
	local dir = hum.MoveDirection
	if dir.Magnitude < 0.1 then
		dir = root.CFrame.LookVector
	end
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.01 then
		return
	end
	dir = dir.Unit
	local att = root:FindFirstChild("RootAttachment")
	if not att or not att:IsA("Attachment") then
		att = new("Attachment", { Name = "DashAttachment", Parent = root })
	end
	local lv = new("LinearVelocity", {
		Attachment0 = att,
		MaxForce = 1e7,
		VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
		RelativeTo = Enum.ActuatorRelativeTo.World,
		VectorVelocity = dir * 85,
		Parent = root,
	})
	Debris:AddItem(lv, 0.18)
	Request:FireServer("dash")
	Effects.burst(root.Position - Vector3.new(0, 2, 0), Color3.fromRGB(220, 230, 255), 10, 12, 0.7)
	dashBtn.TextTransparency = 0.6
	task.delay(Config.DASH_COOLDOWN, function()
		dashBtn.TextTransparency = 0
	end)
end

local function ultimate()
	if battle.active and (battle.gauge or 0) >= 100 then
		Request:FireServer("ultimate")
	end
end

attackBtn.MouseButton1Down:Connect(function()
	attackHeld = true
	tryAttack()
end)
attackBtn.MouseButton1Up:Connect(function()
	attackHeld = false
end)
attackBtn.MouseLeave:Connect(function()
	attackHeld = false
end)
dashBtn.Activated:Connect(dash)
ultBtn.Activated:Connect(ultimate)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		attackHeld = true
		tryAttack()
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftShift then
		dash()
	elseif input.KeyCode == Enum.KeyCode.R then
		ultimate()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		attackHeld = false
	end
end)

RunService.Heartbeat:Connect(function()
	if attackHeld and battle.active and os.clock() - lastTry >= 0.12 then
		tryAttack()
	end
end)

------------------------------------------------------------------------
-- 서버 메시지
------------------------------------------------------------------------
Push.OnClientEvent:Connect(function(kind: string, data: any)
	if kind == "state" then
		state = data
		myStats = Config.playerStats(data.equipped, data.atkLv, data.hpLv)
		refreshAll()
	elseif kind == "battle" then
		battle = data
		if not data.active then
			attackHeld = false
		end
		refreshBattle()
	elseif kind == "hits" then
		Effects.hits(data)
	elseif kind == "swing" then
		local _, hum = getChar()
		if hum then
			playSlash(hum)
		end
		Effects.swing(data)
	elseif kind == "ult" then
		showUltBanner(data.name, data.color or C.gold)
		Effects.ultimate(data)
	elseif kind == "slam" then
		Effects.slam(data)
	elseif kind == "result" then
		showResult(data)
	elseif kind == "toast" then
		toast(data)
	elseif kind == "openPage" then
		openPage(data, true)
	elseif kind == "equipped" then
		Effects.sound("unsheath", 0.6, 1)
	elseif kind == "merged" then
		if data.to then
			showMerge(data.to, data.count or 1)
		else
			toast(string.format("%d번 합성했어요!", data.count or 0))
		end
	end
end)

Request:FireServer("hello")
