-- ArenaClient (LocalScript, StarterPlayer > StarterPlayerScripts)
-- 화면 UI와 조작. 계산은 서버가 하고, 여기서는 보여 주고 요청만 보낸다.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))
local GradeStyle = require(ReplicatedStorage:WaitForChild("GradeStyle"))
local AuraBuilder = require(ReplicatedStorage:WaitForChild("AuraBuilder"))
local Effects = require(script:WaitForChild("Effects"))
local Motion = require(script:WaitForChild("Motion"))
local KillFx = require(script:WaitForChild("KillFx"))
local remotes = ReplicatedStorage:WaitForChild("ArenaRemotes")
local Request = remotes:WaitForChild("Request") :: RemoteEvent
local Push = remotes:WaitForChild("Push") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local state: any = nil
local myStats: any = nil
local battle: any = { active = false }

-- 아래쪽에서 정의하는 도움 함수 (서버 메시지 처리에서 쓴다)
local attachMarkRune: (Model?, number, Color3) -> ()
local showStun: (Model?, number) -> ()
local pushSelf: (Vector3, number, number) -> ()

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


-- 등급마다 고유한 두 색 띠 (94등급부터 무지개)
local function setGradeColor(label: TextLabel, grade: number)
	local old = label:FindFirstChildOfClass("UIGradient")
	if old then
		old:Destroy()
	end
	label.TextColor3 = Color3.new(1, 1, 1)
	new("UIGradient", { Color = GradeStyle.gradient(grade), Parent = label })
end

-- 스테이지 이름 색: 1~100은 등급 색, 초월 스테이지는 무지개
local function setStageColor(label: TextLabel, n: number)
	if Config.isBeyond(n) then
		local old = label:FindFirstChildOfClass("UIGradient")
		if old then
			old:Destroy()
		end
		label.TextColor3 = Color3.new(1, 1, 1)
		new("UIGradient", { Color = GradeStyle.RAINBOW, Parent = label })
	else
		setGradeColor(label, n)
	end
end

local function enhOf(key: string): number
	return (state and type(state.enh) == "table" and state.enh[key]) or 0
end

local function weaponTitle(key: string): (string, any)
	local info = Config.weaponInfo(key)
	if not info then
		return "?", nil
	end
	if info.typeId == 0 then
		local lv0 = enhOf(key)
		return "올라운더" .. (lv0 > 0 and (" +" .. lv0) or ""), info
	end
	local lv = enhOf(key)
	return string.format("[%d] %s %s%s", info.grade, info.gradeData.en, info.type.name, lv > 0 and (" +" .. lv) or ""), info
end

local function weaponColor(info: any): Color3
	if info.typeId == 0 then
		return C.gold
	end
	return info.rarity.color
end

local fmt = Config.formatNumber

-- 무기 3D 미리보기
local function weaponViewport(parent: GuiObject, key: string, spin: boolean, enh: number?): ViewportFrame?
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
	WeaponBuilder.build(world, hand, info.typeId, {
		grade = info.typeId == 0 and 100 or info.grade,
		accent = info.typeId == 0 and Color3.fromRGB(255, 235, 160) or info.rarity.color,
		rarity = info.rarity.rank,
		scale = 1,
		enh = enh or 0,
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
	Size = UDim2.new(0, 136, 0, 6 * 56),
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
	cosmetics = "✨  치장 상점 · 아우라와 킬 이펙트",
	help = "📜  도움말",
	test = "🧪  테스트 (만렙 계정)",
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

local menuButtons: { [string]: TextButton } = {}
for _, item in ipairs({
	{ "stage", "⚔", "스테이지", C.red },
	{ "armory", "🗡", "무기고", C.blue },
	{ "train", "💪", "훈련", C.green },
	{ "cosmetics", "✨", "치장", Color3.fromRGB(150, 80, 200) },
	{ "help", "📜", "도움말", C.panel3 },
	{ "test", "🧪", "테스트", Color3.fromRGB(120, 60, 180) },
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
	menuButtons[item[1]] = b
end
menuButtons.test.Visible = false

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
local requestStart
do
	local stagePage = makePage("stage")
	text({
		Size = UDim2.new(1, 0, 0, 36),
		TextSize = 13,
		TextColor3 = C.dim,
		Text = "🔒 잠김   ⚔ 도전 가능   ✅ 승리   🔁 자동 반복 가능 (이긴 스테이지 + 권장 전투력 1.5배)\n👑 10스테이지마다 보스 · 🌌 101~200은 초월 스테이지 (강화·아우라·킬 이펙트가 필요해요)",
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

	function requestStart(n: number, auto: boolean)
		if battle.active then
			toast("전투 중에는 새 스테이지를 시작할 수 없어요")
			return
		end
		window.Visible = false
		Request:FireServer("start", n, auto)
	end

	for n = 1, Config.MAX_STAGE do
		local isBoss = n % 10 == 0
		local beyond = Config.isBeyond(n)
		local vg = Config.stageGrade(n)
		local section = { color = GradeStyle.get(vg).glow }
		local top = isBoss and Color3.fromRGB(105, 34, 30) or (beyond and Color3.fromRGB(60, 35, 95) or C.panel3)
		local bottom = isBoss and Color3.fromRGB(55, 16, 16) or (beyond and Color3.fromRGB(25, 15, 45) or C.panel2)
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
		local stageEn, stageKo = Config.stageName(n)
		local nameLabel = text({
			Position = UDim2.new(0, 20, 0, 4),
			Size = UDim2.new(0.52, -20, 0, 26),
			TextSize = 17,
			Font = Enum.Font.GothamBlack,
			TextStrokeTransparency = 0.5,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextWrapped = false,
			Text = string.format("%s%d. %s", isBoss and "👑 " or (beyond and "🌌 " or ""), n, stageEn),
			Parent = row,
		})
		setStageColor(nameLabel, n)
		text({
			Position = UDim2.new(0, 20, 0, 29),
			Size = UDim2.new(0.52, -20, 0, 18),
			TextSize = 12,
			TextColor3 = C.dim,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextWrapped = false,
			Text = stageKo .. "  ·  " .. GradeStyle.get(vg).motif.name .. (isBoss and "  ·  BOSS" or ""),
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
		local target = math.clamp(state.maxStage - 2, 0, Config.MAX_STAGE)
		stageList.CanvasPosition = Vector2.new(0, target * 57)
	end

	------------------------------------------------------------------------
end
-- 무기고 페이지
------------------------------------------------------------------------
do
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
		Size = UDim2.new(1, -250, 0, 26),
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.5,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = false,
		Parent = equipCard,
	})
	local equipInfo = text({
		Position = UDim2.new(0, 110, 0, 52),
		Size = UDim2.new(1, -250, 0, 46),
		TextSize = 13,
		TextColor3 = C.dim,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = equipCard,
	})
	local shownEquipKey = ""
	-- 강화 버튼: 장착한 무기를 한 단계 올린다
	local enhBtn = button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.new(0, 128, 0, 50),
		Text = "🔥 강화",
		TextSize = 15,
		BackgroundColor3 = Color3.fromRGB(200, 80, 30),
		Parent = equipCard,
	}, function()
		Request:FireServer("enhance")
	end)
	local enhCost = text({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 60),
		Size = UDim2.new(0, 128, 0, 38),
		TextSize = 11,
		TextColor3 = C.dim,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = equipCard,
	})

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
			local lv = enhOf(state.equipped)
			equipInfo.Text = string.format(
				"공격력 %s · 간격 %.2f초 · 체력 %s\n치명타 %d%% (%.1f배) · 강화 +%d · 전투력 %s",
				fmt(myStats.atk),
				myStats.cooldown,
				fmt(myStats.maxHp),
				math.floor((info.type.critChance or 0) * 100 + 0.5),
				info.type.critMult or 1,
				lv,
				fmt(state.power)
			)
			if lv >= Config.MAX_ENHANCE then
				enhBtn.Text = "🔥 최대 +" .. lv
				enhCost.Text = "모든 장식이 열렸어요"
			else
				enhBtn.Text = string.format("🔥 강화 +%d → +%d", lv, lv + 1)
				local g = info.typeId == 0 and Config.MAX_GRADE + 5 or info.grade
				enhCost.Text = string.format("💰%s\n다음: %s", fmt(Config.enhanceCost(g, lv)), Config.EnhanceLooks[lv + 1])
			end
			local viewKey = state.equipped .. "#" .. lv
			if shownEquipKey ~= viewKey then
				shownEquipKey = viewKey
				for _, c in ipairs(equipView:GetChildren()) do
					if c:IsA("ViewportFrame") then
						c:Destroy()
					end
				end
				weaponViewport(equipView, state.equipped, true, lv)
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
					shade(darken(GradeStyle.get(w.typeId == 0 and 100 or w.grade).primary, 0.45), C.panel, 90),
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
end
-- 훈련 페이지
------------------------------------------------------------------------
do
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
end
-- 치장 상점: 아우라와 킬 이펙트
------------------------------------------------------------------------
do
	local cosPage = makePage("cosmetics")
	local cosTab = "aura"
	local tabRow = new("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		Parent = cosPage,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
	local auraTab, killTab
	local cosInfo = text({
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(1, 0, 0, 34),
		TextSize = 12,
		TextColor3 = C.dim,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = cosPage,
	})
	local cosList = new("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 80),
		Size = UDim2.new(1, 0, 1, -80),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.gold,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = cosPage,
	}, {
		new("UIGridLayout", {
			CellSize = UDim2.new(0, 206, 0, 132),
			CellPadding = UDim2.new(0, 7, 0, 7),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- 미리보기: 내 분신이 앞에 나타나 아우라를 두르고 몇 초 뒤 사라진다
	local function previewAura(tier: number)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not char or not root or not root:IsA("BasePart") then
			return
		end
		window.Visible = false
		local old = workspace:FindFirstChild("AuraPreview")
		if old then
			old:Destroy()
		end
		local was = char.Archivable
		char.Archivable = true
		local ok, clone = pcall(function()
			return char:Clone()
		end)
		char.Archivable = was
		if not ok or not clone then
			return
		end
		local model = clone :: Model
		model.Name = "AuraPreview"
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BaseScript") or d:IsA("BillboardGui") then
				d:Destroy()
			end
		end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		local croot = model:FindFirstChild("HumanoidRootPart")
		if croot and croot:IsA("BasePart") then
			croot.Anchored = true
		end
		model:PivotTo(root.CFrame * CFrame.new(0, 0, -10) * CFrame.Angles(0, math.pi, 0))
		model.Parent = workspace
		AuraBuilder.apply(model, tier)
		Effects.burst(model:GetPivot().Position, C.gold, 30, 20, 0.6)
		toast(string.format("👁 [%d] %s 미리보기 (7초)", tier, Config.Auras[tier].name))
		task.delay(7, function()
			if model.Parent then
				model:Destroy()
			end
		end)
	end

	local function previewKill(tier: number)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return
		end
		window.Visible = false
		local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
		local pos = root.Position + look * 14
		local f = Config.KillFx[tier]
		local near = { pos + Vector3.new(5, 0, 0), pos + Vector3.new(-4, 0, 4), pos + Vector3.new(0, 0, -6) }
		toast(string.format("👁 [%d] %s 미리보기", tier, f.name))
		KillFx.play({ pos = pos, fx = tier, radius = f.blast.radius, near = near })
		task.delay(1.6, function()
			KillFx.play({ pos = pos, fx = tier, radius = f.blast.radius, near = near })
		end)
	end

	local function bonusText(kind: string, item: any): string
		if kind == "aura" then
			local t = string.format("공격력 ×%.2f · 체력 ×%.2f", item.atk, item.hp)
			if item.pulse then
				t ..= string.format("\n파동: %.1f초마다 반경 %d, 공격력 %.0f%%", item.pulse.interval, math.floor(item.pulse.radius), item.pulse.mult * 100)
			else
				t ..= "\n파동: 4단계부터"
			end
			return t
		end
		return string.format("공격력 ×%.2f\n처치 폭발: 반경 %d, 공격력 %.0f%%", item.atk, math.floor(item.blast.radius), item.blast.mult * 100)
	end

	local function refreshCos()
		if not state then
			return
		end
		setButtonColor(auraTab, cosTab == "aura" and C.gold or C.panel3)
		setButtonColor(killTab, cosTab == "kill" and C.gold or C.panel3)
		local list = cosTab == "aura" and Config.Auras or Config.KillFx
		local owned = (cosTab == "aura" and state.auras or state.kills) or {}
		local equipped = (cosTab == "aura" and state.aura or state.kill) or 0
		local cur = list[equipped]
		if cosTab == "aura" then
			cosInfo.Text = "아우라: 공격력·체력이 오르고, 4단계부터 주기적으로 주위 적을 때리는 파동이 나가요. 모두에게 보여요.\n장착 중: " .. (cur and string.format("[%d] %s", equipped, cur.name) or "없음 (무기 등급 오라)")
		else
			cosInfo.Text = "킬 이펙트: 공격력이 오르고, 적을 잡으면 그 자리가 터져 주위 적에게 피해를 줘요. 터져서 또 잡으면 연쇄 폭발!\n장착 중: " .. (cur and string.format("[%d] %s", equipped, cur.name) or "없음")
		end
		for _, child in ipairs(cosList:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		for i, item in ipairs(list) do
			local style = GradeStyle.get(i >= #list and 100 or item.motif + ((i - 1) // 10) * 30)
			local isOwned = owned[tostring(i)] == true
			local isEquipped = equipped == i
			local unlocked = state.maxStage >= item.unlock
			local card = new("Frame", {
				LayoutOrder = i,
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = cosList,
			}, {
				corner(10),
				stroke(isEquipped and C.gold or style.glow, isEquipped and 3 or 1.2),
				shade(darken(style.primary, 0.5), C.panel, 90),
			})
			local title = text({
				Position = UDim2.new(0, 8, 0, 4),
				Size = UDim2.new(1, -16, 0, 22),
				TextSize = 15,
				Font = Enum.Font.GothamBlack,
				TextStrokeTransparency = 0.5,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextWrapped = false,
				Text = string.format("%d. %s", i, item.name),
				Parent = card,
			})
			if i >= #list then
				new("UIGradient", { Color = GradeStyle.RAINBOW, Parent = title })
			else
				title.TextColor3 = lighten(style.glow, 0.3)
			end
			text({
				Position = UDim2.new(0, 8, 0, 25),
				Size = UDim2.new(1, -16, 0, 16),
				TextSize = 11,
				TextColor3 = C.dim,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextWrapped = false,
				Text = item.desc,
				Parent = card,
			})
			text({
				Position = UDim2.new(0, 8, 0, 42),
				Size = UDim2.new(1, -16, 0, 32),
				TextSize = 11,
				TextColor3 = C.text,
				TextYAlignment = Enum.TextYAlignment.Top,
				Text = bonusText(cosTab, item),
				Parent = card,
			})
			local kind = cosTab
			button({
				Position = UDim2.new(0, 6, 1, -40),
				Size = UDim2.new(0.36, -6, 0, 34),
				Text = "👁 보기",
				TextSize = 12,
				BackgroundColor3 = C.panel3,
				Parent = card,
			}, function()
				if kind == "aura" then
					previewAura(i)
				else
					previewKill(i)
				end
			end)
			local label, color
			if isEquipped then
				label, color = "장착 중", C.goldDeep
			elseif isOwned then
				label, color = "장착", C.blue
			elseif not unlocked then
				label, color = string.format("🔒 %d스테이지", item.unlock), C.panel2
			else
				label, color = "💰" .. fmt(item.cost), C.green
			end
			local act = button({
				Position = UDim2.new(0.36, 4, 1, -40),
				Size = UDim2.new(0.64, -10, 0, 34),
				Text = label,
				TextSize = 12,
				BackgroundColor3 = color,
				Parent = card,
			}, function()
				if isEquipped then
					Request:FireServer("unequipCosmetic", kind)
				else
					Request:FireServer("buyCosmetic", kind, i)
				end
			end)
			if not unlocked and not isOwned then
				act.TextTransparency = 0.4
			end
		end
	end
	refreshers.cosmetics = refreshCos

	auraTab = button({ Size = UDim2.new(0.32, 0, 1, 0), Text = "🌟 아우라 30종", TextSize = 13, Parent = tabRow }, function()
		cosTab = "aura"
		refreshCos()
	end)
	killTab = button({ Size = UDim2.new(0.32, 0, 1, 0), Text = "💀 킬 이펙트 30종", TextSize = 13, Parent = tabRow }, function()
		cosTab = "kill"
		refreshCos()
	end)
	button({ Size = UDim2.new(0.32, 0, 1, 0), Text = "해제", TextSize = 13, BackgroundColor3 = C.red, Parent = tabRow }, function()
		Request:FireServer("unequipCosmetic", cosTab)
	end)

	------------------------------------------------------------------------
end
-- 도움말 페이지
------------------------------------------------------------------------
do
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
	local skillLines = {}
	for _, id in ipairs({ 1, 2, 3, 4, 5, 0 }) do
		local wt = Config.weaponType(id)
		local list = Config.Skills[id]
		table.insert(skillLines, string.format("· %s  [E] %s %s: %s", wt.name, list[1].icon, list[1].name, list[1].desc))
		table.insert(skillLines, string.format("        [F] %s %s: %s", list[2].icon, list[2].name, list[2].desc))
	end
	local enemyLines = {}
	for _, id in ipairs(Config.ENEMY_ORDER) do
		local e = Config.EnemyTypes[id]
		local how = ({
			grunt = "다가와서 벤다",
			archer = "거리를 벌리고 빨간 선으로 조준한 뒤 화살을 쏜다. 선에서 비켜서세요",
			shield = "앞에서 오는 공격을 70% 막는다. 뒤나 옆을 노리거나 기절시키세요",
			brute = "빨간 길을 그린 뒤 그 길로 돌진한다. 옆으로 피하세요",
			bomber = "달려와 붙으면 1초 뒤 터진다. 원 밖으로 대시!",
			shaman = "멀리서 발밑에 불길 원을 띄운다. 원이 다 차기 전에 나가세요",
			assassin = "주기적으로 내 등 뒤로 순간이동해 찌른다",
			golem = "느리고 단단하다. 제자리 땅을 내려쳐 둘레를 터뜨린다",
			ghost = "몸이 흐려진 동안은 공격이 안 통한다 (MISS). 다시 보일 때 때리세요",
			splitter = "쓰러지면 작은 분열체 둘로 갈라진다",
			priest = "주위 적의 체력을 회복시킨다. 먼저 잡으세요!",
			knight = "앞 공격을 50% 막고, 빨간 길을 그린 뒤 세 번 연속 벤다",
		})[id] or ""
		table.insert(enemyLines, string.format("· %s (%d스테이지부터): %s", e.name, e.unlock, how))
	end
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
			"· PC: 마우스 왼쪽 클릭(누르고 있으면 연속 공격), Q 또는 Shift로 대시, E·F로 무기 스킬, R로 필살기",
			"· 휴대폰: 오른쪽 아래 ⚔ 버튼을 누르고 있기, 💨 대시, 스킬 버튼 둘, 💥 필살기",
			"· 공격하면 가장 가까운 적에게 알아서 다가가요",
			"· 이어서 때리면 3단 콤보! 3타째는 피해 1.6배에 적을 크게 밀어내요",
			"· 대시는 앞으로 구르는 회피예요",
			"· 대시하는 순간에는 잠깐 무적이에요. 보스의 빨간 원을 피하세요!",
			"",
			"🌀 무기 스킬 (E, F)",
			table.concat(skillLines, "\n"),
			"",
			"💥 필살기 (때릴수록 게이지가 차요)",
			table.concat(ultLines, "\n"),
			"",
			"👹 적",
			table.concat(enemyLines, "\n"),
			"· 바닥의 빨간 경고 안에서 밝은 원이 차오르면 곧 공격이 들어와요",
			"· 웨이브를 깰 때마다 체력 30%를 회복해요",
			"· 보스는 내려찍기, 돌진, 회전 베기, 운석, 부하 소환, 탄막, 운석비 중 몇 가지를 섞어 써요",
			"· 40스테이지부터 ★정예 적이 나와요: 신속(빠름), 거대(체력 2배), 재생(체력 회복), 광폭(공격 1.6배)",
			"",
			"🌌 초월 스테이지 (101~200)",
			"· 100스테이지 뒤로 100층이 더 있어요. 한 층마다 6.5%씩 강해져요",
			"· 무기만으로는 부족해요. 강화, 아우라, 킬 이펙트로 힘을 키우세요",
			"",
			"🔥 강화 (무기고)",
			"· 장착한 무기를 +1 ~ +10까지 강화해요. 단계마다 공격력 +10%, 체력 +5%",
			"· 단계마다 칼에 장식이 하나씩 붙어요: " .. table.concat(Config.EnhanceLooks, " → "),
			"· 합성하면 다음 등급 칼이 강화 단계의 절반을 물려받아요",
			"",
			"✨ 아우라 · 💀 킬 이펙트 (아우라 제단, 치장 메뉴)",
			"· 스테이지를 깨면 하나씩 열리고 코인으로 사요. 각 30단계",
			"· 아우라: 공격력 최대 3배, 체력 최대 2배. 4단계부터 주위 적을 때리는 파동",
			"· 킬 이펙트: 공격력 최대 2.5배. 적을 잡으면 터져서 주위 적에게 피해 (연쇄 폭발)",
			"· 👁 보기 버튼으로 미리 볼 수 있어요",
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
			"· 칼날 모양 12종(곧은 날, 나뭇잎, 식칼, 곡도, 물결, 언월, 빈 틀, 쌍날, 갈고리, 초승달, 용골, 수정)이 등급마다 바뀌어요",
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
			"· 자동 반복 중에는 스킬과 필살기도 알아서 써요",
			"",
			"🏛 로비",
			"· 🔨 합성 용광로: 모루 앞에서 합성 창을 열어요. 누가 합성하면 용광로가 불을 뿜어요",
			"· 💪 훈련장: 허수아비 앞에서 훈련 창을 열어요",
			"· ⚔ 무기 전시대: 구간마다 무기가 얼마나 화려해지는지 보여 줘요",
			"· ✨ 아우라 제단: 광장 가운데 떠 있는 수정. 아우라와 킬 이펙트를 사요",
		}, "\n"),
		Parent = helpScroll,
	})

	------------------------------------------------------------------------
end
-- 테스트 창 (만렙 계정에서만 보인다)
------------------------------------------------------------------------
local godBtn, cdBtn
do
	local testPage = makePage("test")
	local testGrade = 100
	local testType = 1
	local TYPE_NAMES = { [1] = "대검", [2] = "쌍검", [3] = "장검", [4] = "단검", [5] = "낫", [0] = "올라운더" }
	local testView = new("Frame", {
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 170, 0, 170),
		BackgroundColor3 = C.bg,
		Parent = testPage,
	}, { corner(12), stroke(C.line, 1.5) })
	local testInfo = text({
		Position = UDim2.new(0, 180, 0, 0),
		Size = UDim2.new(1, -180, 0, 54),
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.4,
		Parent = testPage,
	})
	local testSub = text({
		Position = UDim2.new(0, 180, 0, 54),
		Size = UDim2.new(1, -180, 0, 40),
		TextSize = 13,
		TextColor3 = C.dim,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = testPage,
	})
	local stepRow = new("Frame", {
		Position = UDim2.new(0, 180, 0, 98),
		Size = UDim2.new(1, -180, 0, 34),
		BackgroundTransparency = 1,
		Parent = testPage,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5) }) })
	local typeRow = new("Frame", {
		Position = UDim2.new(0, 180, 0, 138),
		Size = UDim2.new(1, -180, 0, 32),
		BackgroundTransparency = 1,
		Parent = testPage,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }) })
	local actionRow = new("Frame", {
		Position = UDim2.new(0, 0, 0, 182),
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = testPage,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
	local toggleRow = new("Frame", {
		Position = UDim2.new(0, 0, 0, 234),
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = testPage,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
	local enhRow = new("Frame", {
		Position = UDim2.new(0, 0, 0, 284),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = testPage,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5) }) })
	local cosRow = new("Frame", {
		Position = UDim2.new(0, 0, 0, 330),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = testPage,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5) }) })
	text({ Size = UDim2.new(0, 96, 1, 0), Text = "장착 무기 강화", TextSize = 12, TextColor3 = C.dim, Parent = enhRow })
	for _, lv in ipairs({ 0, 3, 5, 7, 10 }) do
		button({ Size = UDim2.new(0, 56, 1, 0), Text = "+" .. lv, TextSize = 13, BackgroundColor3 = Color3.fromRGB(170, 70, 30), Parent = enhRow }, function()
			Request:FireServer("testEnhance", lv)
		end)
	end
	local testAura, testKill = 30, 30
	local auraLabel, killLabel
	local function cosStepper(kind: string, labelText: string): TextLabel
		button({ Size = UDim2.new(0, 34, 1, 0), Text = "◀", Parent = cosRow }, function()
			if kind == "aura" then
				testAura = math.max(1, testAura - 1)
				Request:FireServer("buyCosmetic", "aura", testAura)
				auraLabel.Text = string.format("%s %d", labelText, testAura)
			else
				testKill = math.max(1, testKill - 1)
				Request:FireServer("buyCosmetic", "kill", testKill)
				killLabel.Text = string.format("%s %d", labelText, testKill)
			end
		end)
		local l = text({ Size = UDim2.new(0, 96, 1, 0), Text = labelText .. " 30", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, Parent = cosRow })
		button({ Size = UDim2.new(0, 34, 1, 0), Text = "▶", Parent = cosRow }, function()
			if kind == "aura" then
				testAura = math.min(#Config.Auras, testAura + 1)
				Request:FireServer("buyCosmetic", "aura", testAura)
				auraLabel.Text = string.format("%s %d", labelText, testAura)
			else
				testKill = math.min(#Config.KillFx, testKill + 1)
				Request:FireServer("buyCosmetic", "kill", testKill)
				killLabel.Text = string.format("%s %d", labelText, testKill)
			end
		end)
		return l
	end
	auraLabel = cosStepper("aura", "아우라")
	killLabel = cosStepper("kill", "킬")
	text({
		Position = UDim2.new(0, 0, 0, 376),
		Size = UDim2.new(1, 0, 0, 60),
		TextSize = 12,
		TextColor3 = C.dim,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "스튜디오에서 플레이하거나 게임 주인으로 들어오면 테스트 계정이 돼요. 모든 스테이지가 열려 있고 코인이 무한이며, 기록은 저장하지 않아요.\n정식 공개 전에는 GameConfig의 TEST_MODE를 false로 바꾸세요.",
		Parent = testPage,
	})

	local typeButtons: { [number]: TextButton } = {}
	local function refreshTest()
		local key = Config.itemKey(testGrade, testType)
		local info = Config.weaponInfo(key)
		local style = GradeStyle.get(testType == 0 and 100 or testGrade)
		if info then
			testInfo.Text = testType == 0 and "올라운더" or string.format("[%d] %s %s", testGrade, info.gradeData.en, info.type.name)
			setGradeColor(testInfo, testType == 0 and 100 or testGrade)
			testSub.Text = string.format(
				"%s · %s의 기운 · %s · %s · 스킬 Lv.%d\n(미리보기는 +10 강화 모습)",
				testType == 0 and "최종" or info.rarity.name,
				style.motif.name,
				style.materialName,
				style.shapeName,
				Config.skillTier(testGrade, testType)
			)
		end
		for _, c in ipairs(testView:GetChildren()) do
			if c:IsA("ViewportFrame") then
				c:Destroy()
			end
		end
		weaponViewport(testView, key, true, Config.MAX_ENHANCE)
		for id, b in pairs(typeButtons) do
			setButtonColor(b, id == testType and C.gold or C.panel3)
		end
	end
	refreshers.test = function()
		refreshTest()
	end

	for _, step in ipairs({ -10, -1, 1, 10 }) do
		button({ Size = UDim2.new(0, 54, 1, 0), Text = (step > 0 and "+" or "") .. step, Parent = stepRow }, function()
			testGrade = math.clamp(testGrade + step, 1, Config.MAX_GRADE)
			refreshTest()
		end)
	end
	for _, id in ipairs({ 1, 2, 3, 4, 5, 0 }) do
		typeButtons[id] = button({ Size = UDim2.new(0, 58, 1, 0), Text = TYPE_NAMES[id], TextSize = 12, Parent = typeRow }, function()
			testType = id
			refreshTest()
		end)
	end
	button({ Size = UDim2.new(0.34, 0, 1, 0), Text = "🎁 이 무기 받고 장착", BackgroundColor3 = C.goldDeep, Parent = actionRow }, function()
		Request:FireServer("testGive", testGrade, testType)
	end)
	button({ Size = UDim2.new(0.32, 0, 1, 0), Text = "⚔ 이 등급 스테이지 도전", BackgroundColor3 = C.red, Parent = actionRow }, function()
		requestStart(testGrade, false)
	end)
	button({ Size = UDim2.new(0.32, 0, 1, 0), Text = "💥 필살기 게이지 채우기", BackgroundColor3 = C.blue, Parent = actionRow }, function()
		Request:FireServer("testGauge")
	end)
	godBtn = button({ Size = UDim2.new(0.32, 0, 1, 0), Text = "🛡 무적 OFF", Parent = toggleRow }, function()
		Request:FireServer("testToggle", "god")
	end)
	button({ Size = UDim2.new(0.34, 0, 1, 0), Text = "🌌 초월 스테이지 (등급+100)", TextSize = 12, BackgroundColor3 = Color3.fromRGB(110, 60, 180), Parent = toggleRow }, function()
		requestStart(testGrade + Config.MAX_GRADE, false)
	end)
	cdBtn = button({ Size = UDim2.new(0.32, 0, 1, 0), Text = "⏱ 쿨타임 없음 OFF", Parent = toggleRow }, function()
		Request:FireServer("testToggle", "cooldown")
	end)

	------------------------------------------------------------------------
end
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
	Size = UDim2.new(0, 300, 0, 230),
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
	Position = UDim2.new(1, -132, 1, 0),
	Size = UDim2.new(0, 72, 0, 72),
	Text = "💨",
	TextSize = 32,
}, C.blue, C.text)
local ultBtn = roundButton({
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -24, 1, -134),
	Size = UDim2.new(0, 80, 0, 80),
	Text = "💥",
	TextSize = 34,
}, C.goldDeep, C.gold)
local ultBtnStroke = ultBtn:FindFirstChildOfClass("UIStroke") :: UIStroke

-- 무기 스킬 버튼 (E, F). 재사용 대기 중에는 어두운 막이 내려온다
type SkillButton = { button: TextButton, cover: Frame, timer: TextLabel, name: TextLabel, readyAt: number, duration: number }
local skillButtons: { SkillButton } = {}
local SKILL_POS = { UDim2.new(1, -150, 1, -84), UDim2.new(1, -212, 1, 0) }
local SKILL_COLOR = { Color3.fromRGB(130, 70, 190), Color3.fromRGB(30, 140, 130) }
for slot = 1, 2 do
	local b = roundButton({
		AnchorPoint = Vector2.new(1, 1),
		Position = SKILL_POS[slot],
		Size = UDim2.new(0, 72, 0, 72),
		Text = "",
		TextSize = 30,
	}, SKILL_COLOR[slot], C.text)
	b.ClipsDescendants = true
	local cover = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = b,
	})
	local timer = text({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 24,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.2,
		ZIndex = 4,
		Parent = b,
	})
	text({
		Position = UDim2.new(0, 6, 0, 2),
		Size = UDim2.new(0, 20, 0, 18),
		TextSize = 13,
		Font = Enum.Font.GothamBlack,
		TextColor3 = C.gold,
		TextStrokeTransparency = 0.3,
		Text = Config.SKILL_KEYS[slot],
		ZIndex = 5,
		Parent = b,
	})
	-- 이름표: E는 버튼 위, F는 버튼 아래
	local pos = SKILL_POS[slot]
	local nameLabel = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(1, pos.X.Offset - 36, 1, slot == 1 and pos.Y.Offset - 88 or pos.Y.Offset + 2),
		Size = UDim2.new(0, 90, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 11,
		TextStrokeTransparency = 0.3,
		Parent = actionPad,
	})
	skillButtons[slot] = { button = b, cover = cover, timer = timer, name = nameLabel, readyAt = 0, duration = 1 }
	b.Activated:Connect(function()
		if battle.active then
			Request:FireServer("skill", slot)
		end
	end)
end

local shownSkillType = -1
local function setSkillIcons(typeId: number, tier: number?)
	local t = tier or 1
	local key = typeId * 10 + t
	if key == shownSkillType then
		return
	end
	shownSkillType = key
	local list = Config.Skills[typeId] or Config.Skills[1]
	for slot, sb in ipairs(skillButtons) do
		local sk = list[slot]
		sb.button.Text = sk.icon
		sb.name.Text = string.format("%s Lv.%d", sk.name, t)
		local stars = sb.button:FindFirstChild("Stars")
		if not stars then
			stars = text({
				Name = "Stars",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -3),
				Size = UDim2.new(1, 0, 0, 14),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextSize = 11,
				TextColor3 = C.gold,
				TextStrokeTransparency = 0.2,
				ZIndex = 5,
				Parent = sb.button,
			})
		end
		(stars :: TextLabel).Text = string.rep("★", t)
	end
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for _, sb in ipairs(skillButtons) do
		local rem = sb.readyAt - now
		if rem > 0 then
			sb.cover.Size = UDim2.fromScale(1, math.clamp(rem / sb.duration, 0, 1))
			sb.timer.Text = tostring(math.ceil(rem))
		elseif sb.timer.Text ~= "" then
			sb.cover.Size = UDim2.fromScale(1, 0)
			sb.timer.Text = ""
		end
	end
end)

local controlHint = text({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -8),
	Size = UDim2.new(0, 600, 0, 20),
	TextSize = 13,
	TextColor3 = C.dim,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextStrokeTransparency = 0.5,
	Text = "클릭: 공격   ·   Q / Shift: 대시   ·   E / F: 무기 스킬   ·   R: 필살기",
	Visible = false,
	Parent = gui,
})

-- 필살기 이름 배너
local showUltBanner
do
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
	function showUltBanner(name: string, color: Color3)
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
end

-- 큰 배너: 웨이브, 보스 등장, 전투 시작
local showBigBanner
do
	local bigBanner = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.38, 0),
		Size = UDim2.new(0, 800, 0, 90),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 64,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0,
		Visible = false,
		ZIndex = 14,
		Parent = gui,
	})
	local bigSub = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 24,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.2,
		ZIndex = 14,
		Parent = bigBanner,
	})
	local bigScale = new("UIScale", { Parent = bigBanner })
	local bigToken = 0
	function showBigBanner(title: string, sub: string, color: Color3, hold: number?)
		bigToken += 1
		local my = bigToken
		bigBanner.Text = title
		bigBanner.TextColor3 = lighten(color, 0.25)
		bigBanner.TextStrokeColor3 = darken(color, 0.75)
		bigBanner.TextTransparency = 0
		bigBanner.TextStrokeTransparency = 0
		bigSub.Text = sub
		bigSub.TextColor3 = C.text
		bigSub.TextTransparency = 0
		bigBanner.Visible = true
		bigScale.Scale = uiScaleValue * 2.2
		TweenService:Create(bigScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScaleValue }):Play()
		task.delay(hold or 1.3, function()
			if bigToken == my then
				local info = TweenInfo.new(0.35)
				TweenService:Create(bigBanner, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
				TweenService:Create(bigSub, info, { TextTransparency = 1 }):Play()
			end
		end)
	end
end

-- 화면 가장자리 붉은 테두리: 맞을 때 번쩍, 체력이 낮으면 숨 쉬듯
local hurtFlash, lowHp
do
	local vignette = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 1,
		Parent = gui,
	})
	local vignetteEdges: { Frame } = {}
	for i, spec in ipairs({
		{ UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0.18, 0), 90 },
		{ UDim2.new(0, 0, 0.82, 0), UDim2.new(1, 0, 0.18, 0), -90 },
		{ UDim2.new(0, 0, 0, 0), UDim2.new(0.12, 0, 1, 0), 0 },
		{ UDim2.new(0.88, 0, 0, 0), UDim2.new(0.12, 0, 1, 0), 180 },
	}) do
		local edge = new("Frame", {
			Position = spec[1],
			Size = spec[2],
			BackgroundColor3 = Color3.fromRGB(200, 0, 0),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Parent = vignette,
		})
		new("UIGradient", {
			Rotation = spec[3],
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Parent = edge,
		})
		vignetteEdges[i] = edge
	end
	hurtFlash = 0
	lowHp = false
	local function setVignette(alpha: number, color: Color3)
		for _, e in ipairs(vignetteEdges) do
			e.BackgroundTransparency = 1 - alpha
			e.BackgroundColor3 = color
		end
	end
	RunService.RenderStepped:Connect(function(dt)
		hurtFlash = math.max(0, hurtFlash - dt * 2.5)
		local pulse = lowHp and (0.25 + 0.2 * math.sin(os.clock() * 6)) or 0
		local a = math.max(hurtFlash, pulse)
		setVignette(math.clamp(a, 0, 0.85), Color3.fromRGB(200, 0, 0))
	end)
end

-- 콤보: 1.6초 안에 계속 때리면 숫자가 커지고 색이 바뀐다
local addCombo, combo
do
	local comboLabel = text({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -30, 0.42, 0),
		Size = UDim2.new(0, 300, 0, 70),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 54,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0,
		Visible = false,
		ZIndex = 12,
		Parent = gui,
	})
	local comboSub = text({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.2,
		Text = "COMBO",
		ZIndex = 12,
		Parent = comboLabel,
	})
	local comboScale = new("UIScale", { Parent = comboLabel })
	combo = 0
	local comboAt = 0
	local COMBO_COLORS = {
		{ 0, Color3.fromRGB(255, 250, 235) },
		{ 10, Color3.fromRGB(255, 220, 90) },
		{ 25, Color3.fromRGB(255, 140, 40) },
		{ 50, Color3.fromRGB(255, 60, 60) },
		{ 100, Color3.fromRGB(200, 90, 255) },
	}
	function addCombo(n: number)
		local now = os.clock()
		if now - comboAt > 1.6 then
			combo = 0
		end
		combo += n
		comboAt = now
		local color = COMBO_COLORS[1][2]
		for _, c in ipairs(COMBO_COLORS) do
			if combo >= c[1] then
				color = c[2]
			end
		end
		comboLabel.Text = tostring(combo)
		comboLabel.TextColor3 = color
		comboLabel.TextStrokeColor3 = darken(color, 0.8)
		comboSub.TextColor3 = color
		comboLabel.Visible = combo >= 3
		comboScale.Scale = uiScaleValue * (1.35 + math.min(combo, 100) / 250)
		TweenService:Create(comboScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScaleValue }):Play()
	end
	RunService.Heartbeat:Connect(function()
		if comboLabel.Visible and os.clock() - comboAt > 1.6 then
			comboLabel.Visible = false
			combo = 0
		end
	end)
end

-- 등급 상승: 화면 가득 축포
local function celebrate(stage: number)
	local color = GradeStyle.get(Config.stageGrade(stage)).glow
	showBigBanner(Config.isBeyond(stage) and "BEYOND!" or "RANK UP!", string.format("[%d] %s", stage, (Config.stageName(stage))), color, 1.8)
	for i = 1, 70 do
		local piece = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(math.random(), 0, -0.05, 0),
			Size = UDim2.new(0, math.random(8, 16), 0, math.random(12, 22)),
			BackgroundColor3 = (i % 3 == 0) and C.gold or (i % 3 == 1 and color or Color3.new(1, 1, 1)),
			BorderSizePixel = 0,
			Rotation = math.random(0, 360),
			ZIndex = 13,
			Parent = gui,
		})
		local dur = 1.6 + math.random() * 1.4
		TweenService:Create(piece, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(piece.Position.X.Scale + (math.random() - 0.5) * 0.3, 0, 1.1, 0),
			Rotation = piece.Rotation + math.random(-540, 540),
		}):Play()
		Debris:AddItem(piece, dur)
	end
	Effects.sound("ping", 0.8, 0.9)
	task.delay(0.15, function()
		Effects.sound("ping", 0.8, 1.2)
	end)
end

-- 결과 창
local showResult
do
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

	function showResult(data: any)
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
				task.delay(0.4, function()
					celebrate(data.stage)
				end)
				local en = Config.stageName(data.stage)
				line(string.format("🏅 새 등급 달성!  [%d] %s", data.stage, en), GradeStyle.textColor(Config.stageGrade(data.stage)), 19)
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
end

-- 합성 성공 연출
local showMerge
do
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
	function showMerge(key: string, count: number)
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
		rankLabel.Text = string.format("🏅 %s", (Config.stageName(state.maxStage)))
		setStageColor(rankLabel, state.maxStage)
		rankStroke.Color = GradeStyle.get(Config.stageGrade(state.maxStage)).glow
	else
		rankLabel.Text = "🏅 NO RANK"
		rankLabel.TextColor3 = C.dim
		rankStroke.Color = C.line
	end
end

local function refreshBattle()
	local active = battle.active == true
	if not active then
		lowHp = false
	end
	hud.Visible = active
	hudButtons.Visible = active
	actionPad.Visible = active
	controlHint.Visible = active and not UserInputService.TouchEnabled
	if not active then
		return
	end
	local stageEn = Config.stageName(battle.stage)
	local section = { color = GradeStyle.get(Config.stageGrade(battle.stage)).glow }
	hudTitle.Text = string.format("%sSTAGE %d  ·  %s", battle.boss and "👑 " or (Config.isBeyond(battle.stage) and "🌌 " or ""), battle.stage, stageEn)
	setStageColor(hudTitle, battle.stage)
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
	enemyText.Text = string.format("WAVE %d / %d   ·   남은 적  %d", battle.wave or 1, battle.waveTotal or 1, battle.left)
	lowHp = ratio < 0.3
	if battle.typeId ~= nil then
		setSkillIcons(battle.typeId, battle.skillTier)
	end
	autoBtn.Text = battle.auto and "🔁 자동 ON" or "🔁 자동 OFF"
	setButtonColor(autoBtn, battle.auto and C.green or C.panel3)
end

local function refreshAll()
	refreshTop()
	if state then
		menuButtons.test.Visible = state.tester == true
		godBtn.Text = state.god and "🛡 무적 ON" or "🛡 무적 OFF"
		setButtonColor(godBtn, state.god and C.green or C.panel3)
		cdBtn.Text = state.noCooldown and "⏱ 쿨타임 없음 ON" or "⏱ 쿨타임 없음 OFF"
		setButtonColor(cdBtn, state.noCooldown and C.green or C.panel3)
	end
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
KillFx.init(Effects)
Motion.setCharacter(player.Character)
player.CharacterAdded:Connect(function(char)
	task.wait(0.3)
	Motion.setCharacter(char)
end)

-- 히트스톱: 맞는 순간 내 휘두르기 동작을 아주 잠깐 멈춘다
local function hitStop(duration: number)
	Motion.hitStop(duration)
end

-- 칼이 닿는 순간: 휘두르기 동작이 내려오는 때에 맞춰 타격 연출을 보여 준다
local impactAt = 0

-- 줌 반동: 화면이 순간 앞으로 당겨졌다 돌아온다
local baseFov = 70
local fovTween: Tween? = nil
local function fovPunch(amount: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	if fovTween then
		fovTween:Cancel()
	end
	cam.FieldOfView = baseFov - amount
	local tween = TweenService:Create(cam, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = baseFov })
	fovTween = tween
	tween:Play()
end

-- 무기별 타격 무게 (불꽃 크기, 흔들림)
local HEAVY = { [1] = 1.5, [2] = 0.8, [3] = 1.1, [4] = 0.9, [5] = 1.2, [0] = 1.5 }
local lastSwingType = 1

-- 연속 처치: 1.2초 안에 잡으면 이어진다
local onKill
do
	local killLabel = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.22, 0),
		Size = UDim2.new(0, 600, 0, 60),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 44,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0,
		Visible = false,
		ZIndex = 13,
		Parent = gui,
	})
	local killScale = new("UIScale", { Parent = killLabel })
	local KILL_NAMES = { [2] = "DOUBLE KILL", [3] = "TRIPLE KILL", [4] = "QUADRA KILL", [5] = "PENTA KILL" }
	local killStreak = 0
	local lastKillAt = 0
	local killToken = 0
	function onKill()
		local now = os.clock()
		if now - lastKillAt > 1.2 then
			killStreak = 0
		end
		killStreak += 1
		lastKillAt = now
		Effects.sound("ping", 0.45, 1.1 + math.min(killStreak, 8) * 0.12)
		if killStreak < 2 then
			return
		end
		killToken += 1
		local my = killToken
		killLabel.Text = KILL_NAMES[killStreak] or string.format("RAMPAGE x%d", killStreak)
		local color = killStreak >= 5 and Color3.fromRGB(255, 80, 200) or (killStreak >= 3 and Color3.fromRGB(255, 120, 40) or C.gold)
		killLabel.TextColor3 = color
		killLabel.TextStrokeColor3 = darken(color, 0.8)
		killLabel.TextTransparency = 0
		killLabel.TextStrokeTransparency = 0
		killLabel.Visible = true
		killScale.Scale = uiScaleValue * 1.8
		TweenService:Create(killScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScaleValue }):Play()
		Effects.shake(0.3 + killStreak * 0.08, 0.15)
		task.delay(1.1, function()
			if killToken == my then
				TweenService:Create(killLabel, TweenInfo.new(0.3), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			end
		end)
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
	local char = player.Character
	if char then
		for i = 0, 2 do
			task.delay(i * 0.05, function()
				Effects.afterimage(char, Color3.fromRGB(150, 200, 255))
			end)
		end
	end
	Request:FireServer("dash")
	Motion.roll()
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
	elseif input.KeyCode == Enum.KeyCode.E and battle.active then
		Request:FireServer("skill", 1)
	elseif input.KeyCode == Enum.KeyCode.F and battle.active then
		Request:FireServer("skill", 2)
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
		myStats = Config.profileStats(data)
		refreshAll()
	elseif kind == "battle" then
		battle = data
		if not data.active then
			attackHeld = false
		end
		Motion.setCombat(data.active and data.typeId or nil)
		refreshBattle()
	elseif kind == "hits" then
		-- 기본 공격 타격은 칼이 내려오는 순간에, 나머지(독, 아우라, 폭발)는 바로
		local function process()
			Effects.hits(data)
			local landed = 0
			local anyCrit = false
			local heavy = HEAVY[lastSwingType] or 1
			for _, h in ipairs(data) do
				if h.kind == "hurt" then
					hurtFlash = 0.55
					fovPunch(-2)
					Motion.flinch(player.Character, 0.8)
				elseif h.kind == "aura" or h.kind == "blast" then
					Effects.hitFlash(h.model, false)
					Motion.flinch(h.model, 0.6)
				elseif h.kind ~= "poison" and h.kind ~= "miss" then
					landed += 1
					anyCrit = anyCrit or h.kind == "crit"
					Effects.impact(h, heavy)
					Effects.hitFlash(h.model, h.kind == "crit")
					Motion.flinch(h.model, h.kind == "crit" and 1.3 or 0.8)
				end
			end
			if landed > 0 then
				addCombo(landed)
				hitStop(anyCrit and 0.1 or 0.045 * heavy)
				fovPunch(anyCrit and 4 or 1.2 * heavy)
				Effects.shake((anyCrit and 0.45 or 0.12) * heavy, anyCrit and 0.14 or 0.07)
				Effects.sound("lunge", anyCrit and 0.45 or 0.2, (anyCrit and 1.0 or 1.5) + math.random() * 0.2)
			end
		end
		local first = data[1]
		local wait = impactAt - os.clock()
		if first and (first.kind == "hit" or first.kind == "crit" or first.kind == "block") and wait > 0 then
			task.delay(wait, process)
		else
			process()
		end
	elseif kind == "swing" then
		lastSwingType = data.typeId or 1
		local delay = Motion.attack(data.typeId or 1, data.step or 1, data.cooldown or 0.5)
		impactAt = os.clock() + delay
		-- 3타째는 앞으로 한 걸음 내디딘다
		local root = getChar()
		if root and data.step == 3 and data.target then
			local d = Vector3.new(data.target.X - root.Position.X, 0, data.target.Z - root.Position.Z)
			if d.Magnitude > 3 then
				pushSelf(d.Unit, 26, 0.12)
			end
		end
		task.delay(delay, function()
			Effects.swing(data)
			if data.step == 3 then
				Effects.shake(0.35, 0.12)
				fovPunch(3)
			end
		end)
	elseif kind == "ult" then
		Motion.ult(data.typeId or 1)
		showUltBanner(data.name, data.color or C.gold)
		Effects.ultimate(data)
	elseif kind == "slam" then
		Effects.slam(data)
	elseif kind == "result" then
		if data.win then
			Motion.victory()
		end
		showResult(data)
	elseif kind == "toast" then
		toast(data)
	elseif kind == "openPage" then
		openPage(data, true)
	elseif kind == "equipped" then
		Effects.sound("unsheath", 0.6, 1)
	elseif kind == "skill" then
		Motion.skill(data.id)
		if data.id == "mark" then
			attachMarkRune(data.model, data.stacks, data.color)
		elseif data.id == "charge" or data.id == "phantom" then
			local root = getChar()
			if root then
				local dir = (data.target - data.origin)
				local dist = Vector3.new(dir.X, 0, dir.Z).Magnitude
				if dist > 0.5 then
					pushSelf(Vector3.new(dir.X, 0, dir.Z).Unit, dist / 0.2, 0.2)
				end
			end
			Effects.skill(data)
		else
			Effects.skill(data)
		end
	elseif kind == "cooldown" then
		local sb = skillButtons[data.slot]
		if sb then
			sb.readyAt = os.clock() + data.duration
			sb.duration = data.duration
		end
	elseif kind == "stun" then
		showStun(data.model, data.duration)
	elseif kind == "proj" then
		Effects.projectile(data)
	elseif kind == "knock" then
		pushSelf(data.dir, data.power, 0.15)
		Effects.shake(0.7, 0.2)
	elseif kind == "dust" then
		Effects.dust(data)
	elseif kind == "explode" then
		Effects.explode(data)
	elseif kind == "flame" then
		Effects.flame(data)
	elseif kind == "meteor" then
		Effects.meteor(data)
	elseif kind == "spin" then
		Effects.spinFx(data)
	elseif kind == "summon" then
		Effects.summonFx(data)
	elseif kind == "blink" then
		Effects.blink(data)
	elseif kind == "kill" then
		Effects.shatter(data.model, data.color)
		Effects.kill(data)
		if (data.fx or 0) > 0 then
			KillFx.play(data)
		end
		onKill()
	elseif kind == "auraPulse" then
		KillFx.pulse(data)
	elseif kind == "heal" then
		KillFx.heal(data)
	elseif kind == "enhanced" then
		local root = getChar()
		if root then
			Effects.flash(root.Position, C.gold, 10, 0.4)
			Effects.burst(root.Position, Color3.fromRGB(255, 150, 60), 40, 26, 0.7)
		end
		Effects.sound("ping", 0.6, 1.2)
		toast(string.format("🔥 강화 성공! +%d · %s", data.level, data.look or ""))
	elseif kind == "cosmetic" then
		local list = data.kind == "aura" and Config.Auras or Config.KillFx
		local item = list[data.tier]
		if item then
			toast(string.format("%s %s [%d] %s", data.bought and "🎉 구매!" or "✔", data.kind == "aura" and "아우라" or "킬 이펙트", data.tier, item.name))
		end
		local root = getChar()
		if root and data.kind == "kill" then
			KillFx.play({ pos = root.Position + root.CFrame.LookVector * 10, fx = data.tier, radius = Config.KillFx[data.tier].blast.radius })
		elseif root then
			Effects.flash(root.Position, C.gold, 8, 0.4)
		end
	elseif kind == "battleStart" then
		Effects.battleStart(data)
		local en, ko = Config.stageName(data.stage)
		showBigBanner(string.format("%sSTAGE %d", data.beyond and "🌌 " or "", data.stage), data.beyond and ko or en, data.color, 1.1)
		for _, sb in ipairs(skillButtons) do
			sb.readyAt = 0
		end
		combo = 0
	elseif kind == "wave" then
		if data.boss then
			-- 보스 웨이브는 따로 크게 알린다
		elseif data.index > 1 then
			showBigBanner(string.format("WAVE %d", data.index), string.format("%d / %d", data.index, data.total), C.gold, 1.0)
			Effects.sound("unsheath", 0.6, 0.8)
		end
	elseif kind == "waveClear" then
		Effects.sound("ping", 0.5, 1.0)
		local root = getChar()
		if root then
			Effects.burst(root.Position, C.green, 30, 14, 0.6)
			Effects.flash(root.Position, C.green, 8, 0.35)
		end
		toast(string.format("✨ 웨이브 %d 돌파! 체력 %d%% 회복", data.index, math.floor((data.heal or 0) * 100)))
	elseif kind == "boss" then
		showBigBanner("👑 BOSS", string.format("%s · %s", data.name, data.kind), C.red, 1.8)
		hurtFlash = 0.8
		Effects.shake(1.2, 0.6)
		Effects.sound("lunge", 1, 0.4)
	elseif kind == "forge" then
		Effects.forge(data)
	elseif kind == "trained" then
		local root = getChar()
		if root then
			Effects.burst(root.Position, data == "atk" and C.red or C.green, 30, 18, 0.6)
			Effects.flash(root.Position, data == "atk" and C.red or C.green, 7, 0.3)
		end
		Effects.sound("ping", 0.5, 1.3)
	elseif kind == "merged" then
		if data.to then
			showMerge(data.to, data.count or 1)
		else
			toast(string.format("%d번 합성했어요!", data.count or 0))
		end
	end
end)

------------------------------------------------------------------------
-- 적 머리 위 표시: 표식, 기절, 독
------------------------------------------------------------------------
function attachMarkRune(target: Model?, maxStacks: number, color: Color3)
	if not target or not target.Parent then
		return
	end
	local model = target :: Model
	local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	if not head then
		return
	end
	local old = head:FindFirstChild("MarkRune")
	if old then
		old:Destroy()
	end
	local bb = new("BillboardGui", {
		Name = "MarkRune",
		Size = UDim2.new(0, 90, 0, 90),
		StudsOffset = Vector3.new(0, 4.5, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Parent = head,
	})
	local rune = text({
		Size = UDim2.fromScale(1, 0.7),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 46,
		Text = "🎯",
		Parent = bb,
	})
	local count = text({
		Position = UDim2.fromScale(0, 0.68),
		Size = UDim2.fromScale(1, 0.32),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
		TextColor3 = lighten(color, 0.3),
		TextStrokeTransparency = 0,
		Text = "0 / " .. maxStacks,
		Parent = bb,
	})
	local spin = new("UIScale", { Parent = rune })
	local conn
	conn = model:GetAttributeChangedSignal("Mark"):Connect(function()
		local v = model:GetAttribute("Mark")
		if v == nil then
			conn:Disconnect()
			bb:Destroy()
			return
		end
		count.Text = string.format("%d / %d", v, maxStacks)
		spin.Scale = 1.5
		TweenService:Create(spin, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
end

function showStun(target: Model?, duration: number)
	if not target or not target.Parent then
		return
	end
	local model = target :: Model
	local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	if not head then
		return
	end
	local bb = new("BillboardGui", {
		Size = UDim2.new(0, 80, 0, 40),
		StudsOffset = Vector3.new(0, 3.5, 0),
		AlwaysOnTop = true,
		Parent = head,
	})
	local stars = text({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 30,
		Text = "💫💫",
		Parent = bb,
	})
	local start = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not bb.Parent or os.clock() - start > duration then
			conn:Disconnect()
			bb:Destroy()
			return
		end
		stars.Rotation = math.sin(os.clock() * 10) * 15
	end)
end

-- 내 캐릭터를 잠깐 한쪽으로 민다 (돌격, 넉백)
function pushSelf(dir: Vector3, speed: number, duration: number)
	local root = getChar()
	if not root then
		return
	end
	local att = root:FindFirstChild("RootAttachment")
	if not att or not att:IsA("Attachment") then
		att = new("Attachment", { Name = "PushAttachment", Parent = root })
	end
	local lv = new("LinearVelocity", {
		Attachment0 = att,
		MaxForce = 1e7,
		VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
		RelativeTo = Enum.ActuatorRelativeTo.World,
		VectorVelocity = dir * speed,
		Parent = root,
	})
	Debris:AddItem(lv, duration)
end

-- 독에 걸린 적은 초록 거품을 뿜는다
local function watchEnemy(model: Instance)
	if not model:IsA("Model") then
		return
	end
	-- 공격 동작: 서버가 AnimN을 올릴 때마다 팔을 들었다 내려친다
	model:GetAttributeChangedSignal("AnimN"):Connect(function()
		local kindName = model:GetAttribute("AnimKind")
		local t = model:GetAttribute("AnimT")
		Motion.enemy(model :: Model, type(kindName) == "string" and kindName or "swing", type(t) == "number" and t or 0.35)
	end)
	-- 망령: 흐려진 동안 반투명
	model:GetAttributeChangedSignal("Phase"):Connect(function()
		local on = model:GetAttribute("Phase") == true
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				d.LocalTransparencyModifier = on and 0.75 or 0
			end
		end
		if on then
			local r = model:FindFirstChild("HumanoidRootPart")
			if r and r:IsA("BasePart") then
				Effects.burst(r.Position, Color3.fromRGB(170, 220, 255), 16, 8, 0.8)
			end
		end
	end)
	model:GetAttributeChangedSignal("Poison"):Connect(function()
		local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
		if not head then
			return
		end
		local old = head:FindFirstChild("PoisonFx")
		if model:GetAttribute("Poison") then
			if not old then
				new("ParticleEmitter", {
					Name = "PoisonFx",
					Rate = 14,
					Lifetime = NumberRange.new(0.6, 1),
					Speed = NumberRange.new(1, 3),
					Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) }),
					LightEmission = 0.8,
					Color = ColorSequence.new(Color3.fromRGB(120, 255, 90)),
					Parent = head,
				})
			end
		elseif old then
			old:Destroy()
		end
	end)
end

-- 전투 폴더 감시: 적이 생기면 감시하고, 바닥 경고가 생기면 차오르는 원을 그린다
task.spawn(function()
	local battles = workspace:WaitForChild("ArenaBattles")
	battles.DescendantAdded:Connect(function(d)
		if d.Name == "Warning" and d:IsA("BasePart") then
			task.defer(function()
				Effects.warningFill(d)
			end)
		elseif d:IsA("Model") and d.Parent and d.Parent.Parent == battles then
			watchEnemy(d)
		end
	end)
end)

------------------------------------------------------------------------
-- 로비 장식: 톱니와 전시 무기는 돌고, 등불은 둥실 떠다닌다
------------------------------------------------------------------------
do
	type Deco = { part: BasePart, base: CFrame, spin: boolean, bob: boolean }
	local decos: { [BasePart]: Deco } = {}
	local function track(inst: Instance, kind: string)
		if not inst:IsA("BasePart") then
			return
		end
		local part = inst :: BasePart
		local d = decos[part]
		if not d then
			d = { part = part, base = part.CFrame, spin = false, bob = false }
			decos[part] = d
		end
		if kind == "spin" then
			d.spin = true
		else
			d.bob = true
		end
	end
	for _, tag in ipairs({ "ArenaSpin", "ArenaBob" }) do
		local kind = tag == "ArenaSpin" and "spin" or "bob"
		for _, inst in ipairs(CollectionService:GetTagged(tag)) do
			track(inst, kind)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
			track(inst, kind)
		end)
	end
	local forgeBoostUntil = 0
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local boost = t < forgeBoostUntil and 6 or 1
		for part, d in pairs(decos) do
			if not part.Parent then
				decos[part] = nil
			else
				local cf = d.base
				if d.bob then
					local amp = part:GetAttribute("Amp") or 0.5
					local speed = part:GetAttribute("BobSpeed") or 1
					local phase = part:GetAttribute("Phase") or 0
					cf = cf + Vector3.new(0, math.sin(t * speed + phase) * amp, 0)
				end
				if d.spin then
					local speed = (part:GetAttribute("Speed") or 1) * (part.Name:sub(1, 4) == "Gear" and boost or 1)
					if part:GetAttribute("Axis") == "X" then
						cf = cf * CFrame.Angles(t * speed, 0, 0)
					else
						cf = cf * CFrame.Angles(0, t * speed, 0)
					end
				end
				part.CFrame = cf
			end
		end
	end)
	Push.OnClientEvent:Connect(function(kind: string)
		if kind == "forge" then
			forgeBoostUntil = os.clock() + 1.5
		end
	end)
end

------------------------------------------------------------------------
-- 떠다니는 장식: 무기 둘레의 구슬과 파편, 캐릭터 발밑 고리와 오라 구슬
-- 서버는 자리만 만들어 두고, 각자 화면에서 매 프레임 돌린다 (다른 플레이어 것도)
------------------------------------------------------------------------
do
	type Orbit = {
		ref: ObjectValue,
		radius: number,
		height: number,
		speed: number,
		phase: number,
		useRot: boolean,
		flat: boolean,
		tumble: number,
		bob: number,
		bobSpeed: number,
		offset: CFrame,
		axis: string,
	}
	local orbits: { [BasePart]: Orbit } = {}
	local function trackOrbit(inst: Instance)
		if not inst:IsA("BasePart") then
			return
		end
		local part = inst :: BasePart
		local ref = part:FindFirstChild("Center") or part:WaitForChild("Center", 2)
		if not (ref and ref:IsA("ObjectValue")) then
			return
		end
		orbits[part] = {
			ref = ref,
			radius = part:GetAttribute("Radius") or 0,
			height = part:GetAttribute("Height") or 0,
			speed = part:GetAttribute("Speed") or 1,
			phase = part:GetAttribute("Phase") or 0,
			useRot = part:GetAttribute("UseRotation") == true,
			flat = part:GetAttribute("Flat") == true,
			tumble = part:GetAttribute("Tumble") or 0,
			bob = part:GetAttribute("Bob") or 0,
			bobSpeed = part:GetAttribute("BobSpeed") or 2,
			offset = CFrame.identity,
			axis = part:GetAttribute("Axis") or "Y",
		}
		local op = part:GetAttribute("OffsetPos")
		local orot = part:GetAttribute("OffsetRot")
		local off = CFrame.identity
		if typeof(op) == "Vector3" then
			off = CFrame.new(op)
		end
		if typeof(orot) == "Vector3" then
			off = off * CFrame.Angles(math.rad(orot.X), math.rad(orot.Y), math.rad(orot.Z))
		end
		orbits[part].offset = off
	end
	for _, inst in ipairs(CollectionService:GetTagged("ArenaOrbit")) do
		task.spawn(trackOrbit, inst)
	end
	CollectionService:GetInstanceAddedSignal("ArenaOrbit"):Connect(function(inst)
		task.spawn(trackOrbit, inst)
	end)
	CollectionService:GetInstanceRemovedSignal("ArenaOrbit"):Connect(function(inst)
		if inst:IsA("BasePart") then
			orbits[inst :: BasePart] = nil
		end
	end)
	local FLAT = CFrame.Angles(0, 0, math.rad(90))
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for part, o in pairs(orbits) do
			if not part.Parent then
				orbits[part] = nil
			else
				local c = o.ref.Value
				if c and c:IsA("BasePart") and c.Parent then
					local center = c :: BasePart
					local base = (o.useRot and center.CFrame or CFrame.new(center.Position)) * o.offset
					local h = o.height
					if o.bob ~= 0 then
						h += math.sin(t * o.bobSpeed + o.phase) * o.bob
					end
					local a = t * o.speed + o.phase
					local spin
					if o.axis == "Z" then
						spin = CFrame.Angles(0, 0, a)
					elseif o.axis == "X" then
						spin = CFrame.Angles(a, 0, 0)
					else
						spin = CFrame.Angles(0, a, 0)
					end
					local cf = base * CFrame.new(0, h, 0) * spin * CFrame.new(o.radius, 0, 0)
					if o.tumble ~= 0 then
						cf = cf * CFrame.Angles(t * o.tumble, t * o.tumble * 0.7, 0)
					end
					if o.flat then
						cf = cf * FLAT
					end
					part.CFrame = cf
				end
			end
		end
	end)
end

Request:FireServer("hello")
