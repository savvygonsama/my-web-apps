-- HoleClient (LocalScript, StarterPlayer > StarterPlayerScripts)
-- 화면 UI, 카메라, 문 통과, "너무 커요" 표시. 계산은 서버가 하고 여기서는 보여 주고 요청만 보낸다.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Fx = require(script:WaitForChild("Fx"))
local remotes = ReplicatedStorage:WaitForChild("HoleRemotes")
local Request = remotes:WaitForChild("Request") :: RemoteEvent
local Push = remotes:WaitForChild("Push") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local fmt = Config.formatNumber

local state: any = nil

------------------------------------------------------------------------
-- UI 도구
------------------------------------------------------------------------
local C = {
	bg = Color3.fromRGB(14, 10, 26),
	panel = Color3.fromRGB(28, 20, 50),
	panel2 = Color3.fromRGB(44, 32, 78),
	line = Color3.fromRGB(120, 90, 200),
	accent = Color3.fromRGB(180, 120, 255),
	pink = Color3.fromRGB(255, 120, 210),
	gold = Color3.fromRGB(255, 210, 90),
	text = Color3.fromRGB(240, 236, 255),
	dim = Color3.fromRGB(170, 160, 200),
	green = Color3.fromRGB(80, 210, 130),
	red = Color3.fromRGB(230, 70, 90),
}

local function new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				(inst :: any)[k] = v
			end
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(r: number?): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, r or 10) })
end

local function stroke(color: Color3?, t: number?): UIStroke
	return new("UIStroke", { Color = color or C.line, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function grad(a: Color3, b: Color3, rot: number?): UIGradient
	return new("UIGradient", { Color = ColorSequence.new(a, b), Rotation = rot or 90 })
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
		BackgroundColor3 = C.accent,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 15,
		AutoButtonColor = true,
		TextStrokeTransparency = 0.6,
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	local b = new("TextButton", defaults, { corner(10) })
	b.Activated:Connect(onClick)
	return b
end

------------------------------------------------------------------------
-- 화면 뼈대
------------------------------------------------------------------------
local gui = new("ScreenGui", { Name = "HoleUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })
local uiScale = 1
do
	local cam = workspace.CurrentCamera
	if cam and cam.ViewportSize.Y < 520 then
		uiScale = 0.78
	end
end
local function scaled(frame: GuiObject)
	new("UIScale", { Scale = uiScale, Parent = frame })
end

-- 위: 질량과 능력치
local massLabel, statLabel
do
	local top = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0, 420, 0, 74),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = gui,
	}, { corner(16), stroke(C.accent, 2), grad(C.panel2, C.bg) })
	scaled(top)
	massLabel = text({
		Position = UDim2.new(0, 0, 0, 4),
		Size = UDim2.new(1, 0, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 32,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.4,
		Text = "💠 0",
		Parent = top,
	})
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(210, 170, 255), Color3.fromRGB(140, 220, 255)), Parent = massLabel })
	statLabel = text({
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 15,
		TextColor3 = C.dim,
		Parent = top,
	})
end

-- 알림
local toast
do
	local frame = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.new(0, 520, 0, 42),
		BackgroundColor3 = C.bg,
		BackgroundTransparency = 0.1,
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	}, { corner(12), stroke(C.accent, 1.5) })
	scaled(frame)
	local label = text({ Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 21, Parent = frame })
	local token = 0
	function toast(msg: string)
		token += 1
		local my = token
		label.Text = msg
		frame.Visible = true
		task.delay(2.8, function()
			if token == my then
				frame.Visible = false
			end
		end)
	end
end

-- 아래: 다음 구역까지 얼마나 남았는지, 너무 큰 물체 안내
local progressFill, progressLabel, hintLabel
do
	local bar = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(0, 460, 0, 30),
		BackgroundColor3 = C.bg,
		Parent = gui,
	}, { corner(15), stroke(C.line, 1.5) })
	scaled(bar)
	progressFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = bar }, { corner(15), grad(C.accent, C.pink, 0) })
	progressLabel = text({ Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 14, TextStrokeTransparency = 0.4, ZIndex = 2, Parent = bar })
	hintLabel = text({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -6),
		Size = UDim2.new(1, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 150, 160),
		TextStrokeTransparency = 0.3,
		Text = "",
		Parent = bar,
	})
end

------------------------------------------------------------------------
-- 오른쪽: 업그레이드 카드 셋
------------------------------------------------------------------------
type Card = { level: TextLabel, effect: TextLabel, buy: TextButton, max: TextButton }
local cards: { [string]: Card } = {}
do
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 250, 0, 3 * 118),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8) }) })
	scaled(panel)
	for _, u in ipairs(Config.Upgrades) do
		local card = new("Frame", { Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = Color3.new(1, 1, 1), Parent = panel }, { corner(14), stroke(C.line, 1.5), grad(C.panel2, C.bg) })
		text({ Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 22), TextSize = 17, Font = Enum.Font.GothamBlack, Text = u.icon .. " " .. u.name, Parent = card })
		local level = text({ Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 22), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.gold, Parent = card })
		local effect = text({ Position = UDim2.new(0, 10, 0, 30), Size = UDim2.new(1, -20, 0, 32), TextSize = 12, TextColor3 = C.dim, TextYAlignment = Enum.TextYAlignment.Top, Parent = card })
		local buy = button({ Position = UDim2.new(0, 8, 1, -42), Size = UDim2.new(0.66, -10, 0, 34), TextSize = 14, BackgroundColor3 = C.accent, Parent = card }, function()
			Request:FireServer("upgrade", u.id, false)
		end)
		local max = button({ Position = UDim2.new(0.66, 2, 1, -42), Size = UDim2.new(0.34, -10, 0, 34), Text = "최대", TextSize = 13, BackgroundColor3 = C.pink, Parent = card }, function()
			Request:FireServer("upgrade", u.id, true)
		end)
		cards[u.id] = { level = level, effect = effect, buy = buy, max = max }
	end
end

------------------------------------------------------------------------
-- 창: 빅뱅, 구역, 도움말, 테스트
------------------------------------------------------------------------
local window = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, 520, 0, 400),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = false,
	ZIndex = 10,
	Parent = gui,
}, { corner(18), stroke(C.accent, 2.5), grad(C.panel2, C.bg) })
scaled(window)
local windowTitle = text({ Position = UDim2.new(0, 18, 0, 10), Size = UDim2.new(1, -80, 0, 34), TextSize = 22, Font = Enum.Font.GothamBlack, TextColor3 = C.accent, ZIndex = 11, Parent = window })
button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.new(0, 36, 0, 32), Text = "✕", BackgroundColor3 = C.red, ZIndex = 11, Parent = window }, function()
	window.Visible = false
end)
local pages: { [string]: Frame } = {}
local refreshers: { [string]: () -> () } = {}
local currentPage = ""
local function makePage(name: string): Frame
	local f = new("Frame", { Position = UDim2.new(0, 16, 0, 54), Size = UDim2.new(1, -32, 1, -66), BackgroundTransparency = 1, Visible = false, ZIndex = 11, Parent = window })
	pages[name] = f
	return f
end
local TITLES = { bigbang = "🌌 빅뱅", zones = "🗺 구역 이동", help = "📜 도움말", test = "🧪 테스트" }
local function openPage(name: string)
	if window.Visible and currentPage == name then
		window.Visible = false
		return
	end
	currentPage = name
	for n, f in pairs(pages) do
		f.Visible = n == name
	end
	windowTitle.Text = TITLES[name] or name
	window.Visible = true
	local r = refreshers[name]
	if r then
		r()
	end
end

local menuButtons: { [string]: TextButton } = {}
do
	local menu = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(0, 120, 0, 4 * 54),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8) }) })
	scaled(menu)
	for _, item in ipairs({
		{ "bigbang", "🌌 빅뱅", Color3.fromRGB(200, 80, 160) },
		{ "zones", "🗺 구역", Color3.fromRGB(80, 120, 220) },
		{ "help", "📜 도움말", C.panel2 },
		{ "test", "🧪 테스트", Color3.fromRGB(120, 60, 180) },
	}) do
		menuButtons[item[1]] = button({ Size = UDim2.new(1, 0, 0, 46), Text = item[2], TextSize = 16, BackgroundColor3 = item[3], Parent = menu }, function()
			openPage(item[1])
		end)
	end
	menuButtons.test.Visible = false
end

-- 빅뱅 페이지
do
	local page = makePage("bigbang")
	local info = text({ Size = UDim2.new(1, 0, 0, 200), TextSize = 15, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 11, Parent = page })
	local go = button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(0, 260, 0, 56), Text = "🌌 빅뱅!", TextSize = 22, BackgroundColor3 = Color3.fromRGB(200, 70, 160), ZIndex = 11, Parent = page }, function()
		Request:FireServer("bigbang")
		window.Visible = false
	end)
	refreshers.bigbang = function()
		if not state then
			return
		end
		local ready = state.size >= Config.BIGBANG_LEVEL
		local nextSkin = Config.skin(state.bigbang + 1)
		info.Text = table.concat({
			"우주를 처음부터 다시 시작해요.",
			"질량과 업그레이드는 모두 사라지지만, 질량 배율이 영구히 올라요.",
			"",
			string.format("지금 빅뱅 %d회 · 영구 배율 ×%d", state.bigbang, state.bigbang + 1),
			string.format("빅뱅하면 → 영구 배율 ×%d, 블랙홀 색: %s", state.bigbang + 2, nextSkin.name),
			"",
			string.format("조건: 크기 레벨 %d (⚫%s) 이상  ·  지금 레벨 %d", Config.BIGBANG_LEVEL, Config.formatSize(Config.radius(Config.BIGBANG_LEVEL)), state.size),
		}, "\n")
		go.TextTransparency = ready and 0 or 0.5
		go.BackgroundColor3 = ready and Color3.fromRGB(200, 70, 160) or C.panel2
	end
end

-- 구역 이동 페이지
do
	local page = makePage("zones")
	new("UIListLayout", { Padding = UDim.new(0, 6), Parent = page })
	local rows: { { btn: TextButton, label: TextLabel } } = {}
	for i, zone in ipairs(Config.Zones) do
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 11, Parent = page }, { corner(10), grad(zone.ground:Lerp(C.bg, 0.4), C.bg, 0) })
		local label = text({ Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -140, 1, 0), TextSize = 16, Font = Enum.Font.GothamBlack, ZIndex = 12, Parent = row })
		local btn = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 110, 0, 36), Text = "이동", ZIndex = 12, Parent = row }, function()
			Request:FireServer("teleport", i)
			window.Visible = false
		end)
		rows[i] = { btn = btn, label = label }
	end
	refreshers.zones = function()
		if not state then
			return
		end
		for i, zone in ipairs(Config.Zones) do
			local open = state.radius >= zone.need
			rows[i].label.Text = string.format("%d. %s  %s", i, zone.name, open and "" or ("🔒 크기 " .. zone.need))
			rows[i].btn.Text = open and "이동" or "잠김"
			rows[i].btn.BackgroundColor3 = open and C.accent or C.panel2
		end
	end
end

-- 도움말 페이지
do
	local page = makePage("help")
	local scroll = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 11, Parent = page })
	local objLines = {}
	for i, zone in ipairs(Config.Zones) do
		local names = {}
		for _, o in ipairs(Config.Objects) do
			if o.zone == i then
				table.insert(names, string.format("%s(%s)", o.name, Config.formatSize(o.size)))
			end
		end
		table.insert(objLines, string.format("· %d %s: %s", i, zone.name, table.concat(names, ", ")))
	end
	text({
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 14,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 11,
		Text = table.concat({
			"🕳 당신은 작은 블랙홀이에요. 돌아다니면 내 크기보다 작은 건 전부 빨려 들어와요.",
			"· 이동: WASD 또는 화면 조이스틱",
			"· 삼키면 💠질량이 쌓이고, 질량으로 오른쪽 업그레이드를 사요",
			"· ⚫ 크기: 반지름이 커져서 더 큰 걸 삼켜요 (괄호 안 숫자가 필요한 크기)",
			"· 🌀 흡입력: 반지름 바깥까지 끌어당겨요",
			"· 💠 질량 배율: 삼킬 때 얻는 질량이 늘어요",
			"· 너무 큰 물체는 빨갛게 테두리가 쳐지고, 아래에 필요한 크기가 떠요",
			"",
			"🗺 구역 (보라색 벽은 크기가 되면 통과돼요)",
			table.concat(objLines, "\n"),
			"",
			string.format("🌌 빅뱅: 크기 레벨 %d이 되면 처음부터 다시 시작하는 대신 질량 배율이 영구히 오르고 블랙홀 색이 바뀌어요", Config.BIGBANG_LEVEL),
			"💾 기록은 자동으로 저장돼요",
		}, "\n"),
		Parent = scroll,
	})
end

-- 테스트 페이지 (테스트 계정에서만)
do
	local page = makePage("test")
	new("UIListLayout", { Padding = UDim.new(0, 8), Parent = page })
	text({ Size = UDim2.new(1, 0, 0, 36), TextSize = 13, TextColor3 = C.dim, ZIndex = 11, Text = "스튜디오나 게임 주인으로 들어오면 테스트 계정이에요. 기록은 저장하지 않아요. 정식 공개 전에 Config.TEST_MODE를 false로 바꾸세요.", Parent = page })
	local row1 = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, ZIndex = 11, Parent = page }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
	for _, amount in ipairs({ 1e3, 1e6, 1e9, 1e12 }) do
		button({ Size = UDim2.new(0.24, -4, 1, 0), Text = "💠 +" .. fmt(amount), TextSize = 13, ZIndex = 12, Parent = row1 }, function()
			Request:FireServer("testMass", amount)
		end)
	end
	local row2 = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, ZIndex = 11, Parent = page }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
	for _, lv in ipairs({ 0, 12, 24, 36, 48, 57 }) do
		button({ Size = UDim2.new(1 / 6, -5, 1, 0), Text = "크기 Lv" .. lv, TextSize = 12, BackgroundColor3 = Color3.fromRGB(80, 120, 220), ZIndex = 12, Parent = row2 }, function()
			Request:FireServer("testSize", lv)
		end)
	end
	local row3 = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, ZIndex = 11, Parent = page }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
	button({ Size = UDim2.new(0.5, -3, 1, 0), Text = "⭐ 모든 업그레이드 최대", TextSize = 13, BackgroundColor3 = C.pink, ZIndex = 12, Parent = row3 }, function()
		Request:FireServer("testMaxAll")
	end)
	button({ Size = UDim2.new(0.5, -3, 1, 0), Text = "↺ 처음으로", TextSize = 13, BackgroundColor3 = C.red, ZIndex = 12, Parent = row3 }, function()
		Request:FireServer("testReset")
	end)
end

------------------------------------------------------------------------
-- 갱신
------------------------------------------------------------------------
local function refreshAll()
	if not state then
		return
	end
	massLabel.Text = "💠 " .. fmt(state.mass)
	statLabel.Text = string.format("⚫ 크기 %s   🌀 흡입 +%s   ✖ 배율 %s%s", Config.formatSize(state.radius), Config.formatSize(state.pullRange), fmt(state.massMult), state.bigbang > 0 and string.format("   🌌 빅뱅 %d", state.bigbang) or "")
	for _, u in ipairs(Config.Upgrades) do
		local card = cards[u.id]
		local level = state[u.id] :: number
		local maxed = level >= u.maxLevel
		card.level.Text = maxed and "MAX" or string.format("Lv.%d / %d", level, u.maxLevel)
		local nowText, nextText
		if u.id == "size" then
			nowText, nextText = Config.formatSize(Config.radius(level)), Config.formatSize(Config.radius(level + 1))
		elseif u.id == "pull" then
			local r = state.radius
			nowText, nextText = Config.formatSize(Config.pullRange(r, level)), Config.formatSize(Config.pullRange(r, level + 1))
		else
			nowText, nextText = "×" .. string.format("%.1f", Config.massMult(level, state.bigbang)), "×" .. string.format("%.1f", Config.massMult(level + 1, state.bigbang))
		end
		card.effect.Text = maxed and (u.desc .. "\n지금 " .. nowText) or string.format("%s\n%s → %s", u.desc, nowText, nextText)
		local cost = Config.upgradeCost(u.id, level)
		local can = not maxed and state.mass >= cost
		card.buy.Text = maxed and "최대" or ("💠 " .. fmt(cost))
		card.buy.BackgroundColor3 = can and C.accent or C.panel2
		card.max.BackgroundColor3 = can and C.pink or C.panel2
	end
	-- 다음 구역 진행 막대
	local r = state.radius
	local nextZone = nil
	for _, zone in ipairs(Config.Zones) do
		if zone.need > r then
			nextZone = zone
			break
		end
	end
	if nextZone then
		local prevNeed = 0
		for _, zone in ipairs(Config.Zones) do
			if zone.need <= r then
				prevNeed = zone.need
			end
		end
		local ratio = math.clamp((r - prevNeed) / math.max(nextZone.need - prevNeed, 0.01), 0, 1)
		progressFill.Size = UDim2.fromScale(ratio, 1)
		progressLabel.Text = string.format("다음 구역 '%s'까지  ⚫ %s / %d", nextZone.name, Config.formatSize(r), nextZone.need)
	elseif state.size >= Config.BIGBANG_LEVEL then
		progressFill.Size = UDim2.fromScale(1, 1)
		progressLabel.Text = "🌌 모든 구역이 열렸어요! 빅뱅할 수 있어요"
	else
		progressFill.Size = UDim2.fromScale(1, 1)
		progressLabel.Text = "🌌 모든 구역이 열렸어요!"
	end
	menuButtons.test.Visible = state.tester == true
	if window.Visible then
		local f = refreshers[currentPage]
		if f then
			f()
		end
	end
end

------------------------------------------------------------------------
-- 카메라와 문: 크기에 맞춰 멀리서 보고, 크기가 되는 문은 통과한다
------------------------------------------------------------------------
local function applyRadius(r: number)
	player.CameraMaxZoomDistance = math.max(60, 40 + r * 6)
	player.CameraMinZoomDistance = math.min(10 + r * 1.6, player.CameraMaxZoomDistance - 5)
	local zones = workspace:FindFirstChild("Zones")
	if not zones then
		return
	end
	for _, g in ipairs(zones:GetChildren()) do
		if g.Name == "Gate" and g:IsA("BasePart") then
			local need = g:GetAttribute("Need")
			local open = type(need) == "number" and r >= need
			g.CanCollide = not open
			g.Color = open and Color3.fromRGB(90, 230, 150) or Color3.fromRGB(150, 90, 255)
			g.Transparency = open and 0.6 or 0.2
		end
	end
end

------------------------------------------------------------------------
-- 너무 큰 물체: 빨간 테두리와 필요한 크기
------------------------------------------------------------------------
do
	local highlight = new("Highlight", {
		FillTransparency = 1,
		OutlineColor = Color3.fromRGB(255, 70, 90),
		OutlineTransparency = 0.1,
		DepthMode = Enum.HighlightDepthMode.Occluded,
		Enabled = false,
		Parent = workspace,
	})
	task.spawn(function()
		local objects = workspace:WaitForChild("Objects")
		while true do
			task.wait(0.25)
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if state and root and root:IsA("BasePart") then
				local r = state.radius
				local reach = r + state.pullRange + 6
				local best: Model? = nil
				local bestDist = math.huge
				local bestSize = 0
				local p = root.Position
				for _, m in ipairs(objects:GetChildren()) do
					local size = m:GetAttribute("Size")
					if type(size) == "number" and size > r and not m:GetAttribute("EatenBy") and m:IsA("Model") then
						local pivot = m:GetPivot().Position
						local d = Vector3.new(pivot.X - p.X, 0, pivot.Z - p.Z).Magnitude - size
						if d < reach and d < bestDist then
							best, bestDist, bestSize = m, d, size
						end
					end
				end
				if best then
					highlight.Adornee = best
					highlight.Enabled = true
					local label = best:GetAttribute("Label")
					hintLabel.Text = string.format("🔒 %s: 크기 %s 필요", type(label) == "string" and label or "?", Config.formatSize(bestSize))
				else
					highlight.Enabled = false
					hintLabel.Text = ""
				end
			end
		end
	end)
end

------------------------------------------------------------------------
-- 연속 흡수: 1.5초 안에 계속 삼키면 숫자가 커진다
------------------------------------------------------------------------
local addCombo
do
	local label = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 90),
		Size = UDim2.new(0, 400, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 28,
		Font = Enum.Font.GothamBlack,
		TextColor3 = C.pink,
		TextStrokeTransparency = 0.2,
		Visible = false,
		Parent = gui,
	})
	local sc = new("UIScale", { Parent = label })
	local combo = 0
	local last = 0
	function addCombo(n: number)
		local now = os.clock()
		if now - last > 1.5 then
			combo = 0
		end
		last = now
		combo += n
		if combo >= 5 then
			label.Visible = true
			label.Text = string.format("🌀 연속 흡수 x%d", combo)
			sc.Scale = uiScale * 1.3
			TweenService:Create(sc, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScale }):Play()
		end
	end
	RunService.Heartbeat:Connect(function()
		if label.Visible and os.clock() - last > 1.5 then
			label.Visible = false
			combo = 0
		end
	end)
end

-- 큰 글자 배너 (구역 입장, 빅뱅)
local function banner(title: string, sub: string, color: Color3)
	local frame = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.32, 0),
		Size = UDim2.new(0, 600, 0, 110),
		BackgroundTransparency = 1,
		ZIndex = 15,
		Parent = gui,
	})
	local sc = new("UIScale", { Scale = uiScale * 1.5, Parent = frame })
	local t = text({ Size = UDim2.new(1, 0, 0, 64), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 52, Font = Enum.Font.GothamBlack, TextColor3 = color, TextStrokeTransparency = 0, Text = title, ZIndex = 15, Parent = frame })
	local s = text({ Position = UDim2.new(0, 0, 0, 66), Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 22, TextStrokeTransparency = 0.3, Text = sub, ZIndex = 15, Parent = frame })
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScale }):Play()
	task.delay(1.8, function()
		TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		TweenService:Create(s, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.delay(0.45, function()
			frame:Destroy()
		end)
	end)
end

local function myCenter(): Vector3?
	local char = player.Character
	return char and Fx.holeCenter(char) or nil
end

------------------------------------------------------------------------
-- 서버 메시지
------------------------------------------------------------------------
local lastRadius = -1
Push.OnClientEvent:Connect(function(kind: string, data: any)
	if kind == "state" then
		local grew = state ~= nil and data.radius > lastRadius + 0.001
		state = data
		if data.radius ~= lastRadius then
			lastRadius = data.radius
			applyRadius(data.radius)
		end
		if grew then
			local c = myCenter()
			if c then
				Fx.ring(c, C.accent, data.radius * 1.5, data.radius * 3, 0.5)
			end
		end
		refreshAll()
	elseif kind == "eat" then
		if state then
			state.mass = data.mass
		end
		local biggest = 0
		for _, e in ipairs(data.list) do
			biggest = math.max(biggest, e.size)
			Fx.popup(e.pos + Vector3.new(0, e.size * 1.2 + 2, 0), "+" .. fmt(e.mass), Color3.fromRGB(210, 170, 255), 20 + math.min(14, e.size))
		end
		local r = state and state.radius or 3
		local ratio = biggest / r
		Fx.sound("pop", 0.25 + ratio * 0.3, 1.6 - ratio * 0.8 + math.random() * 0.1)
		if ratio > 0.7 then
			Fx.sound("whoosh", 0.4, 0.6)
			local c = myCenter()
			if c then
				Fx.burst(c + Vector3.new(0, 1, 0), C.pink, 20, r * 2, math.max(0.4, r * 0.1))
			end
		end
		addCombo(#data.list)
		refreshAll()
	elseif kind == "toast" then
		toast(data)
	elseif kind == "upgraded" then
		Fx.sound("pop", 0.5, 1.9)
		local c = myCenter()
		if c and state then
			Fx.burst(c + Vector3.new(0, 1, 0), C.gold, 25, 10 + state.radius, 0.6)
		end
	elseif kind == "zone" then
		local zone = Config.Zones[data]
		if zone then
			banner(string.format("%d · %s", data, zone.name), "더 큰 것들이 기다려요", zone.ground:Lerp(Color3.new(1, 1, 1), 0.4))
			Fx.sound("whoosh", 0.5, 0.8)
		end
	elseif kind == "bigbang" then
		local c = myCenter()
		if c then
			Fx.pillar(c, Color3.new(1, 1, 1), 400, 30, 1.2)
			for i = 0, 4 do
				task.delay(i * 0.12, function()
					Fx.ring(c, Color3.fromHSV(i / 5, 0.7, 1), 10, 200 + i * 60, 0.9)
				end)
			end
		end
		Fx.sound("whoosh", 1, 0.3)
		banner("🌌 BIG BANG", string.format("빅뱅 %d회 · %s", data.count, data.skin), C.pink)
	end
end)

------------------------------------------------------------------------
-- 시작
------------------------------------------------------------------------
Fx.start()
player.CharacterAdded:Connect(function()
	task.wait(0.5)
	if state then
		applyRadius(state.radius)
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		openPage("bigbang")
	elseif input.KeyCode == Enum.KeyCode.M then
		openPage("zones")
	end
end)
Request:FireServer("hello")
