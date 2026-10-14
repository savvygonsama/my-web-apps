-- ArenaClient (LocalScript, StarterPlayer > StarterPlayerScripts)
-- 화면 UI와 조작. 계산은 서버가 하고, 여기서는 보여 주고 요청만 보낸다.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
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
	bg = Color3.fromRGB(24, 19, 17),
	panel = Color3.fromRGB(40, 31, 27),
	panel2 = Color3.fromRGB(58, 45, 37),
	line = Color3.fromRGB(110, 85, 60),
	gold = Color3.fromRGB(255, 196, 70),
	text = Color3.fromRGB(245, 236, 220),
	dim = Color3.fromRGB(175, 160, 145),
	red = Color3.fromRGB(225, 70, 60),
	green = Color3.fromRGB(80, 200, 110),
	blue = Color3.fromRGB(70, 140, 230),
}

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 230, 110)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 200, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(150, 100, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 200)),
})

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
	local defaults = {
		BackgroundColor3 = C.panel2,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		TextColor3 = C.text,
		TextSize = 15,
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	local b = new("TextButton", defaults, { corner(8), stroke(C.line, 1) })
	b.Activated:Connect(onClick)
	return b
end

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

local fmt = Config.formatNumber

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
local function addScale(frame: GuiObject)
	new("UIScale", { Name = "AutoScale", Scale = uiScaleValue, Parent = frame })
end
do
	local cam = workspace.CurrentCamera
	if cam and cam.ViewportSize.Y < 520 then
		uiScaleValue = 0.78
	end
end

-- 상단 바: 코인, 전투력, 등급
local topBar = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.new(0, 560, 0, 42),
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

local function chip(width: number): (Frame, TextLabel)
	local f = new("Frame", {
		Size = UDim2.new(0, width, 1, 0),
		BackgroundColor3 = C.bg,
		BackgroundTransparency = 0.15,
		Parent = topBar,
	}, { corner(10), stroke(C.line, 1.5) })
	local label = text({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 17,
		Parent = f,
	})
	return f, label
end
local _, coinLabel = chip(160)
local _, powerLabel = chip(170)
local _, rankLabel = chip(210)
coinLabel.TextColor3 = C.gold

-- 왼쪽 메뉴
local menu = new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.new(0, 128, 0, 4 * 50),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	new("UIListLayout", { Padding = UDim.new(0, 6) }),
})
addScale(menu)

-- 가운데 창
local window = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.52, 0),
	Size = UDim2.new(0.62, 0, 0.74, 0),
	BackgroundColor3 = C.panel,
	Visible = false,
	Parent = gui,
}, {
	corner(14),
	stroke(C.gold, 2),
	new("UISizeConstraint", { MaxSize = Vector2.new(660, 500), MinSize = Vector2.new(320, 260) }),
})
addScale(window)
local windowTitle = text({
	Position = UDim2.new(0, 16, 0, 8),
	Size = UDim2.new(1, -70, 0, 34),
	TextSize = 22,
	Font = Enum.Font.GothamBlack,
	TextColor3 = C.gold,
	Parent = window,
})
button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 8),
	Size = UDim2.new(0, 36, 0, 32),
	Text = "X",
	BackgroundColor3 = C.red,
	Parent = window,
}, function()
	window.Visible = false
end)
local pages = new("Frame", {
	Position = UDim2.new(0, 12, 0, 48),
	Size = UDim2.new(1, -24, 1, -60),
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
	stage = "스테이지",
	armory = "무기고",
	train = "훈련장",
	help = "도움말",
}

local function openPage(name: string)
	if window.Visible and currentPage == name then
		window.Visible = false
		return
	end
	currentPage = name
	for n, f in pairs(pageFrames) do
		f.Visible = (n == name)
	end
	windowTitle.Text = PAGE_TITLES[name] or name
	window.Visible = true
	local r = refreshers[name]
	if r then
		r()
	end
end

for _, item in ipairs({
	{ "stage", "⚔ 스테이지" },
	{ "armory", "🗡 무기고" },
	{ "train", "💪 훈련" },
	{ "help", "❓ 도움말" },
}) do
	button({
		Size = UDim2.new(1, 0, 0, 44),
		Text = item[2],
		TextSize = 17,
		BackgroundColor3 = C.bg,
		BackgroundTransparency = 0.1,
		Parent = menu,
	}, function()
		openPage(item[1])
	end)
end

-- 알림
local toastLabel = text({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -150),
	Size = UDim2.new(0, 520, 0, 40),
	BackgroundColor3 = C.bg,
	BackgroundTransparency = 0.1,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 17,
	Visible = false,
	ZIndex = 20,
	Parent = gui,
})
corner(10).Parent = toastLabel
addScale(toastLabel)
local toastToken = 0
local function toast(msg: string)
	toastToken += 1
	local my = toastToken
	toastLabel.Text = msg
	toastLabel.Visible = true
	task.delay(2.6, function()
		if toastToken == my then
			toastLabel.Visible = false
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
	Text = "🔒 잠김   ⚔ 도전 가능   🔁 자동 반복 가능 (이긴 스테이지 + 권장 전투력 1.5배 이상)\n10스테이지마다 보스가 나와요.",
	Parent = stagePage,
})
local stageList = new("ScrollingFrame", {
	Position = UDim2.new(0, 0, 0, 40),
	Size = UDim2.new(1, 0, 1, -40),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = stagePage,
}, {
	new("UIListLayout", { Padding = UDim.new(0, 4) }),
})

type StageRow = {
	frame: Frame,
	name: TextLabel,
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
	local row = new("Frame", {
		LayoutOrder = n,
		Size = UDim2.new(1, -10, 0, 48),
		BackgroundColor3 = isBoss and Color3.fromRGB(70, 32, 28) or C.panel2,
		Parent = stageList,
	}, { corner(8) })
	local grade = Config.getGrade(n)
	local nameLabel = text({
		Position = UDim2.new(0, 10, 0, 3),
		Size = UDim2.new(0.5, -10, 0, 24),
		TextSize = 16,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = false,
		Text = string.format("%s%d. %s", isBoss and "👑 " or "", n, grade.en),
		Parent = row,
	})
	setGradeColor(nameLabel, n)
	text({
		Position = UDim2.new(0, 10, 0, 26),
		Size = UDim2.new(0.5, -10, 0, 18),
		TextSize = 12,
		TextColor3 = C.dim,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = false,
		Text = grade.ko .. (isBoss and "  · 보스" or ""),
		Parent = row,
	})
	local powerLabel2 = text({
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0.22, 0, 1, 0),
		TextSize = 13,
		TextColor3 = C.dim,
		Text = "",
		Parent = row,
	})
	local status = text({
		Position = UDim2.new(1, -150, 0, 0),
		Size = UDim2.new(0, 30, 1, 0),
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "🔒",
		Parent = row,
	})
	local play = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -62, 0.5, 0),
		Size = UDim2.new(0, 54, 0, 34),
		Text = "도전",
		BackgroundColor3 = C.blue,
		Parent = row,
	}, function()
		requestStart(n, false)
	end)
	local auto = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -4, 0.5, 0),
		Size = UDim2.new(0, 54, 0, 34),
		Text = "🔁 자동",
		TextSize = 13,
		BackgroundColor3 = C.green,
		Parent = row,
	}, function()
		requestStart(n, true)
	end)
	stageRows[n] = { frame = row, name = nameLabel, power = powerLabel2, status = status, play = play, auto = auto }
end

refreshers.stage = function()
	if not state then
		return
	end
	for n, row in ipairs(stageRows) do
		local rec = Config.recommendedPower(n)
		row.power.Text = "권장 " .. fmt(rec)
		local unlocked = n <= state.maxStage + 1
		local canAuto = Config.canAutoRepeat(n, state.maxStage, state.power)
		row.play.Visible = unlocked
		row.auto.Visible = canAuto
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
	-- 지금 도전할 스테이지가 보이게 스크롤
	local target = math.clamp(state.maxStage - 2, 0, Config.MAX_GRADE)
	stageList.CanvasPosition = Vector2.new(0, target * 52)
end

------------------------------------------------------------------------
-- 무기고 페이지
------------------------------------------------------------------------
local armoryPage = makePage("armory")
local equipCard = new("Frame", {
	Size = UDim2.new(1, 0, 0, 70),
	BackgroundColor3 = C.panel2,
	Parent = armoryPage,
}, { corner(10), pad(8) })
local equipName = text({ Size = UDim2.new(1, 0, 0, 24), TextSize = 18, Parent = equipCard })
local equipInfo = text({
	Position = UDim2.new(0, 0, 0, 26),
	Size = UDim2.new(1, 0, 0, 30),
	TextSize = 13,
	TextColor3 = C.dim,
	Parent = equipCard,
})

local armoryButtons = new("Frame", {
	Position = UDim2.new(0, 0, 0, 76),
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundTransparency = 1,
	Parent = armoryPage,
}, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }),
})
button({ Size = UDim2.new(0.32, 0, 1, 0), Text = "가장 센 무기 장착", TextSize = 13, Parent = armoryButtons }, function()
	Request:FireServer("equipBest")
end)
button({
	Size = UDim2.new(0.32, 0, 1, 0),
	Text = "모두 합성",
	TextSize = 13,
	BackgroundColor3 = C.blue,
	Parent = armoryButtons,
}, function()
	Request:FireServer("mergeAll")
end)
local arButton = button({
	Size = UDim2.new(0.32, 0, 1, 0),
	Text = "올라운더 만들기",
	TextSize = 13,
	BackgroundColor3 = Color3.fromRGB(150, 110, 30),
	Parent = armoryButtons,
}, function()
	Request:FireServer("allrounder")
end)

local invList = new("ScrollingFrame", {
	Position = UDim2.new(0, 0, 0, 118),
	Size = UDim2.new(1, 0, 1, -118),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = armoryPage,
}, {
	new("UIGridLayout", {
		CellSize = UDim2.new(0, 146, 0, 104),
		CellPadding = UDim2.new(0, 6, 0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

refreshers.armory = function()
	if not state then
		return
	end
	local title, info = weaponTitle(state.equipped)
	equipName.Text = "장착 중: " .. title .. (info and ("  (" .. info.rarity.name .. ")") or "")
	if info then
		equipName.TextColor3 = info.typeId == 0 and C.gold or info.rarity.color
		equipInfo.Text = string.format(
			"%s · 공격력 %s · 공격 간격 %.2f초 · 체력 %s · 전투력 %s",
			info.type.desc,
			fmt(myStats.atk),
			myStats.cooldown,
			fmt(myStats.maxHp),
			fmt(state.power)
		)
	end

	local hasAll = true
	for t = 1, 5 do
		if (state.inv[Config.itemKey(Config.MAX_GRADE, t)] or 0) < 1 then
			hasAll = false
		end
	end
	arButton.AutoButtonColor = hasAll
	arButton.BackgroundTransparency = hasAll and 0 or 0.6

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
			local rarityColor = w.typeId == 0 and C.gold or w.rarity.color
			local cell = new("Frame", {
				LayoutOrder = i,
				BackgroundColor3 = C.panel2,
				Parent = invList,
			}, { corner(8), stroke(rarityColor, isEquipped and 3 or 1.5) })
			local nameL = text({
				Position = UDim2.new(0, 6, 0, 4),
				Size = UDim2.new(1, -12, 0, 32),
				TextSize = 13,
				Text = wTitle,
				Parent = cell,
			})
			setGradeColor(nameL, w.grade)
			text({
				Position = UDim2.new(0, 6, 0, 36),
				Size = UDim2.new(1, -12, 0, 18),
				TextSize = 12,
				TextColor3 = rarityColor,
				Text = string.format(
					"%s · 보유 %d%s",
					w.typeId == 0 and "최종" or w.rarity.name,
					count,
					w.typeId == 0 and "" or ("/" .. cost)
				),
				Parent = cell,
			})
			button({
				Position = UDim2.new(0, 6, 1, -40),
				Size = UDim2.new(0.5, -9, 0, 34),
				Text = isEquipped and "장착중" or "장착",
				TextSize = 13,
				BackgroundColor3 = isEquipped and C.gold or C.bg,
				TextColor3 = isEquipped and C.bg or C.text,
				Parent = cell,
			}, function()
				Request:FireServer("equip", key)
			end)
			local mergeBtn = button({
				Position = UDim2.new(0.5, 3, 1, -40),
				Size = UDim2.new(0.5, -9, 0, 34),
				Text = "합성",
				TextSize = 13,
				BackgroundColor3 = canMerge and C.blue or C.bg,
				Parent = cell,
			}, function()
				Request:FireServer("merge", key)
			end)
			if not canMerge then
				mergeBtn.TextTransparency = 0.5
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

local function trainCard(kind: string, titleText: string): (TextLabel, TextButton)
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 74),
		BackgroundColor3 = C.panel2,
		Parent = trainPage,
	}, { corner(10), pad(10) })
	text({ Size = UDim2.new(1, -150, 0, 24), TextSize = 18, Text = titleText, Parent = card })
	local info = text({
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, -150, 0, 26),
		TextSize = 13,
		TextColor3 = C.dim,
		Parent = card,
	})
	local b = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 140, 0, 44),
		TextSize = 14,
		BackgroundColor3 = C.gold,
		TextColor3 = C.bg,
		Parent = card,
	}, function()
		Request:FireServer("train", kind)
	end)
	return info, b
end
local atkInfo, atkBtn = trainCard("atk", "⚔ 공격 훈련")
local hpInfo, hpBtn = trainCard("hp", "❤ 체력 훈련")

refreshers.train = function()
	if not state then
		return
	end
	atkInfo.Text = string.format("Lv.%d · 공격력 +%d%%", state.atkLv, math.floor(state.atkLv * Config.TRAIN_BONUS * 100 + 0.5))
	hpInfo.Text = string.format("Lv.%d · 체력 +%d%%", state.hpLv, math.floor(state.hpLv * Config.TRAIN_BONUS * 100 + 0.5))
	atkBtn.Text = "올리기 💰" .. fmt(Config.trainCost(state.atkLv))
	hpBtn.Text = "올리기 💰" .. fmt(Config.trainCost(state.hpLv))
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
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = helpPage,
})
text({
	Size = UDim2.new(1, -12, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	TextSize = 15,
	TextYAlignment = Enum.TextYAlignment.Top,
	Text = table.concat({
		"⚔ 싸우는 법",
		"· PC: 마우스 왼쪽 클릭(누르고 있으면 연속 공격), Q 또는 Shift로 대시",
		"· 휴대폰: 오른쪽 아래 ⚔ 버튼을 누르고 있기, 💨 버튼으로 대시",
		"· 공격하면 가장 가까운 적에게 알아서 다가가요",
		"· 대시하는 순간에는 잠깐 무적이에요. 보스의 빨간 원을 피하세요!",
		"",
		"🗡 무기",
		"· 대검: 한 방이 강하고 느려요",
		"· 쌍검: 아주 빠르게 베요",
		"· 장검: 앞쪽 멀리, 최대 3명",
		"· 단검: 치명타가 잘 터져요",
		"· 낫: 내 주위를 한 바퀴 베고, 피해의 10%만큼 체력을 회복해요",
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
	}, "\n"),
	Parent = helpScroll,
})

------------------------------------------------------------------------
-- 전투 화면
------------------------------------------------------------------------
local hud = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 56),
	Size = UDim2.new(0, 440, 0, 76),
	BackgroundColor3 = C.bg,
	BackgroundTransparency = 0.15,
	Visible = false,
	Parent = gui,
}, { corner(10), stroke(C.line, 1.5), pad(8) })
addScale(hud)
local hudTitle = text({
	Size = UDim2.new(1, 0, 0, 22),
	TextSize = 17,
	TextXAlignment = Enum.TextXAlignment.Center,
	Font = Enum.Font.GothamBlack,
	Parent = hud,
})
local hpBack = new("Frame", {
	Position = UDim2.new(0, 0, 0, 26),
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundColor3 = Color3.fromRGB(50, 25, 25),
	Parent = hud,
}, { corner(6) })
local hpFill = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.green,
	Parent = hpBack,
}, { corner(6) })
local hpText = text({
	Size = UDim2.fromScale(1, 1),
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 2,
	Parent = hpBack,
})
local enemyText = text({
	Position = UDim2.new(0, 0, 0, 46),
	Size = UDim2.new(1, 0, 0, 16),
	TextSize = 13,
	TextColor3 = C.dim,
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = hud,
})

local hudButtons = new("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 56),
	Size = UDim2.new(0, 120, 0, 84),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
}, { new("UIListLayout", { Padding = UDim.new(0, 6) }) })
addScale(hudButtons)
local autoBtn = button({ Size = UDim2.new(1, 0, 0, 38), Text = "🔁 자동 OFF", Parent = hudButtons }, function()
	Request:FireServer("auto", not battle.auto)
end)
button({ Size = UDim2.new(1, 0, 0, 38), Text = "🚪 나가기", BackgroundColor3 = C.red, Parent = hudButtons }, function()
	Request:FireServer("leave")
end)

local actionPad = new("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -30),
	Size = UDim2.new(0, 210, 0, 130),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})
addScale(actionPad)
local attackBtn = new("TextButton", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 1, 0),
	Size = UDim2.new(0, 120, 0, 120),
	BackgroundColor3 = C.red,
	Text = "⚔",
	TextSize = 48,
	Font = Enum.Font.GothamBlack,
	TextColor3 = C.text,
	AutoButtonColor = true,
	Parent = actionPad,
}, { corner(60), stroke(C.gold, 3) })
local dashBtn = new("TextButton", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -130, 1, -10),
	Size = UDim2.new(0, 74, 0, 74),
	BackgroundColor3 = C.blue,
	Text = "💨",
	TextSize = 32,
	Font = Enum.Font.GothamBlack,
	TextColor3 = C.text,
	AutoButtonColor = true,
	Parent = actionPad,
}, { corner(37), stroke(C.text, 2) })

local controlHint = text({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -8),
	Size = UDim2.new(0, 520, 0, 20),
	TextSize = 13,
	TextColor3 = C.dim,
	TextXAlignment = Enum.TextXAlignment.Center,
	Text = "클릭(누르고 있기): 공격   ·   Q / Shift: 대시 (잠깐 무적)",
	Visible = false,
	Parent = gui,
})

-- 결과 창
local resultFrame = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.42, 0),
	Size = UDim2.new(0, 420, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = C.bg,
	BackgroundTransparency = 0.05,
	Visible = false,
	ZIndex = 10,
	Parent = gui,
}, { corner(14), stroke(C.gold, 2), pad(14), new("UIListLayout", { Padding = UDim.new(0, 4) }) })
addScale(resultFrame)
local resultToken = 0

local function showResult(data: any)
	resultToken += 1
	local my = resultToken
	for _, child in ipairs(resultFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local function line(str: string, color: Color3?, size: number?)
		text({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = size or 16,
			TextColor3 = color or C.text,
			Text = str,
			ZIndex = 11,
			Parent = resultFrame,
		})
	end
	if data.win then
		line("승리!", C.gold, 34)
		line("+ 💰 " .. fmt(data.coins), C.gold, 18)
		if data.firstClear then
			local g = Config.getGrade(data.stage)
			line(string.format("새 등급 달성! [%d] %s", data.stage, g.en), Config.getSection(data.stage).color, 18)
		end
		for _, key in ipairs(data.drops or {}) do
			local title, info = weaponTitle(key)
			line("획득: " .. title .. (info and (" (" .. info.rarity.name .. ")") or ""), info and info.rarity.color or C.text, 15)
		end
		if data.again then
			line("곧 다음 판이 자동으로 시작돼요", C.green, 14)
		end
	else
		line("패배...", C.red, 34)
		line("무기를 합성하거나 훈련해서 다시 도전해 보세요", C.dim, 15)
	end
	resultFrame.Visible = true
	task.delay(data.win and 2.4 or 2.8, function()
		if resultToken == my then
			resultFrame.Visible = false
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
	powerLabel.Text = "⚔ 전투력 " .. fmt(state.power)
	if state.maxStage > 0 then
		rankLabel.Text = string.format("🏅 %s", Config.getGrade(state.maxStage).en)
		setGradeColor(rankLabel, state.maxStage)
	else
		rankLabel.Text = "🏅 NO RANK"
		rankLabel.TextColor3 = C.dim
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
	hudTitle.Text = string.format("%sSTAGE %d · %s", battle.boss and "👑 " or "", battle.stage, g.en)
	setGradeColor(hudTitle, battle.stage)
	local ratio = math.clamp(battle.hp / math.max(battle.maxHp, 1), 0, 1)
	hpFill.Size = UDim2.fromScale(ratio, 1)
	hpFill.BackgroundColor3 = ratio > 0.5 and C.green or (ratio > 0.25 and C.gold or C.red)
	hpText.Text = string.format("HP %s / %s", fmt(battle.hp), fmt(battle.maxHp))
	enemyText.Text = string.format("남은 적 %d / %d", battle.left, battle.total)
	autoBtn.Text = battle.auto and "🔁 자동 ON" or "🔁 자동 OFF"
	autoBtn.BackgroundColor3 = battle.auto and C.green or C.panel2
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

------------------------------------------------------------------------
-- 효과: 피해 숫자, 베기
------------------------------------------------------------------------
local fxFolder = new("Folder", { Name = "ArenaFX", Parent = workspace })

local HIT_STYLE = {
	hit = { color = Color3.fromRGB(255, 245, 220), size = 22 },
	crit = { color = Color3.fromRGB(255, 150, 40), size = 30 },
	hurt = { color = Color3.fromRGB(255, 70, 70), size = 24 },
}

local function showHits(list: any)
	for _, h in ipairs(list) do
		local style = HIT_STYLE[h.kind] or HIT_STYLE.hit
		local anchor = new("Part", {
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Transparency = 1,
			Size = Vector3.new(0.2, 0.2, 0.2),
			Position = h.pos + Vector3.new((math.random() - 0.5) * 2, 0, (math.random() - 0.5) * 2),
			Parent = fxFolder,
		})
		local bb = new("BillboardGui", {
			Size = UDim2.new(0, 140, 0, 40),
			AlwaysOnTop = true,
			Parent = anchor,
		})
		local label = text({
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBlack,
			TextSize = style.size,
			TextColor3 = style.color,
			TextStrokeTransparency = 0.2,
			Text = h.kind == "crit" and (h.text .. "!") or h.text,
			Parent = bb,
		})
		local info = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(anchor, info, { Position = anchor.Position + Vector3.new(0, 3, 0) }):Play()
		TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		Debris:AddItem(anchor, 0.75)
	end
end

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

local function showSwing(data: any)
	local root, hum = getChar()
	if not root or not hum then
		return
	end
	playSlash(hum)
	local part = new("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Material = Enum.Material.Neon,
		Color = data.color or C.text,
		Transparency = 0.35,
	})
	local tweenGoal
	if data.mode == "around" then
		local d = data.range * 2
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(0.3, d * 0.6, d * 0.6)
		part.CFrame = CFrame.new(root.Position - Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		tweenGoal = { Size = Vector3.new(0.3, d, d), Transparency = 1 }
	else
		local width = data.mode == "line" and 2.2 or 5
		part.Size = Vector3.new(width, 0.25, data.range)
		part.CFrame = root.CFrame * CFrame.new(0, 0, -data.range / 2) * CFrame.Angles(0, 0, math.rad(math.random(-25, 25)))
		tweenGoal = { Transparency = 1 }
	end
	part.Parent = fxFolder
	TweenService:Create(part, TweenInfo.new(0.2), tweenGoal):Play()
	Debris:AddItem(part, 0.25)
end

------------------------------------------------------------------------
-- 조작
------------------------------------------------------------------------
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
			-- 가까우면 적을 바라보게 돌린다
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
	dashBtn.BackgroundTransparency = 0.6
	task.delay(Config.DASH_COOLDOWN, function()
		dashBtn.BackgroundTransparency = 0
	end)
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

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		attackHeld = true
		tryAttack()
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftShift then
		dash()
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
		showHits(data)
	elseif kind == "swing" then
		showSwing(data)
	elseif kind == "result" then
		showResult(data)
	elseif kind == "toast" then
		toast(data)
	elseif kind == "merged" then
		if data.to then
			local title = weaponTitle(data.to)
			toast("합성 성공! → " .. title)
		else
			toast(string.format("%d번 합성했어요!", data.count or 0))
		end
	end
end)

Request:FireServer("hello")
