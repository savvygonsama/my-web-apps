-- HoleClient (LocalScript, StarterPlayer > StarterPlayerScripts)
-- 화면 UI, 카메라, 문 통과, "너무 커요" 표시. 계산은 서버가 하고 여기서는 보여 주고 요청만 보낸다.
-- 창: 💎 상점, 🥚 캡슐, 🛰 위성, 🎨 스킨, 🌌 빅뱅, 🌑 빅뱅 상점, 🗺 세계, 📜 도움말, 🧪 테스트

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local SatBuilder = require(ReplicatedStorage:WaitForChild("SatBuilder"))
local Fx = require(script:WaitForChild("Fx"))
local remotes = ReplicatedStorage:WaitForChild("HoleRemotes")
local Request = remotes:WaitForChild("Request") :: RemoteEvent
local Push = remotes:WaitForChild("Push") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local fmt = Config.formatNumber

local state: any = nil
local stateAt = 0 -- 상태를 받은 시각 (부스트 남은 시간 계산)
local currentWorld = 1

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
	dim = Color3.fromRGB(185, 175, 215),
	green = Color3.fromRGB(80, 210, 130),
	red = Color3.fromRGB(230, 70, 90),
	blue = Color3.fromRGB(80, 120, 220),
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

-- 모든 글씨를 조금 크게 (휴대폰에서도 잘 보이게)
local TEXT_BOOST = 1.15

local function text(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = C.text,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	defaults.TextSize = math.floor(defaults.TextSize * TEXT_BOOST + 0.5)
	return new("TextLabel", defaults)
end

local function button(props: { [string]: any }, onClick: () -> ()): TextButton
	local defaults = {
		BackgroundColor3 = C.accent,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 16,
		AutoButtonColor = true,
		TextStrokeTransparency = 0.6,
		TextWrapped = true,
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	defaults.TextSize = math.floor(defaults.TextSize * TEXT_BOOST + 0.5)
	local b = new("TextButton", defaults, { corner(10) })
	b.Activated:Connect(onClick)
	return b
end

local function hlist(parent: Instance, height: number, pad: number?): Frame
	return new("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, Parent = parent }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, pad or 6), VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
end

local function scroller(parent: Instance, size: UDim2, pos: UDim2?): ScrollingFrame
	return new("ScrollingFrame", {
		Position = pos or UDim2.new(),
		Size = size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = parent,
	})
end

local function clear(frame: Instance)
	for _, c in ipairs(frame:GetChildren()) do
		if not c:IsA("UIGridStyleLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

local function rarityColor(r: number): Color3
	local def = Config.Rarities[r]
	return def and def.color or C.dim
end

-- 미리보기 창에서 천천히 도는 위성들
local spinning: { { model: Model, vf: ViewportFrame } } = {}

-- 위성 미리보기 (ViewportFrame)
local function satView(parent: Instance, def: any, gold: boolean, size: UDim2, pos: UDim2?): ViewportFrame
	local vf = new("ViewportFrame", {
		Position = pos or UDim2.new(),
		Size = size,
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(200, 200, 210),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, 1),
		Parent = parent,
	})
	local model = SatBuilder.build(def.shape, def.color, 1, gold)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Sparkles") then
			d:Destroy()
		end
	end
	model.Parent = vf
	local cam = new("Camera", { FieldOfView = 40, Parent = vf })
	cam.CFrame = CFrame.lookAt(Vector3.new(2.2, 1.6, -5.4), Vector3.zero)
	vf.CurrentCamera = cam
	table.insert(spinning, { model = model, vf = vf })
	return vf
end

------------------------------------------------------------------------
-- 화면 뼈대
------------------------------------------------------------------------
local gui = new("ScreenGui", { Name = "HoleUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })
local uiScale = 1
do
	local cam = workspace.CurrentCamera
	if cam then
		local vp = cam.ViewportSize
		uiScale = math.clamp(math.min(vp.X / 1080, vp.Y / 640), 0.6, 1.15)
	end
end
local function scaled(frame: GuiObject)
	new("UIScale", { Scale = uiScale, Parent = frame })
end

-- 위: 질량, 능력치, 부스트
local HUD = {} :: any
do
	local top = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0, 470, 0, 78),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = gui,
	}, { corner(16), stroke(C.accent, 2), grad(C.panel2, C.bg) })
	scaled(top)
	HUD.mass = text({
		Position = UDim2.new(0, 0, 0, 4),
		Size = UDim2.new(1, 0, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 34,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.4,
		Text = "💠 0",
		Parent = top,
	})
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(210, 170, 255), Color3.fromRGB(140, 220, 255)), Parent = HUD.mass })
	HUD.stat = text({
		Position = UDim2.new(0, 6, 0, 46),
		Size = UDim2.new(1, -12, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 16,
		TextColor3 = C.dim,
		Parent = top,
	})
	-- 부스트 줄 (켜진 것만 보인다)
	HUD.boosts = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 6),
		Size = UDim2.new(1, 60, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
		TextColor3 = C.gold,
		TextStrokeTransparency = 0.3,
		Text = "",
		Parent = top,
	})
end

-- 알림
local toast
do
	local frame = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -118),
		Size = UDim2.new(0, 580, 0, 46),
		BackgroundColor3 = C.bg,
		BackgroundTransparency = 0.1,
		Visible = false,
		ZIndex = 40,
		Parent = gui,
	}, { corner(12), stroke(C.accent, 1.5) })
	scaled(frame)
	local label = text({ Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 18, Parent = frame })
	local token = 0
	function toast(msg: string)
		token += 1
		local my = token
		label.Text = msg
		frame.Visible = true
		task.delay(3, function()
			if token == my then
				frame.Visible = false
			end
		end)
	end
end

-- 아래: 다음 구역까지 얼마나 남았는지, 너무 큰 물체 안내
local Bar = {} :: any
do
	local bar = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(0, 500, 0, 32),
		BackgroundColor3 = C.bg,
		Parent = gui,
	}, { corner(16), stroke(C.line, 1.5) })
	scaled(bar)
	Bar.fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = bar }, { corner(16), grad(C.accent, C.pink, 0) })
	Bar.label = text({ Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 15, TextStrokeTransparency = 0.4, ZIndex = 2, Parent = bar })
	Bar.hint = text({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -6),
		Size = UDim2.new(1, 0, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 17,
		TextColor3 = Color3.fromRGB(255, 150, 160),
		TextStrokeTransparency = 0.3,
		Text = "",
		Parent = bar,
	})
end

------------------------------------------------------------------------
-- 오른쪽: 자동 업그레이드 + 업그레이드 9종 (내려서 더 보기)
------------------------------------------------------------------------
type Card = { level: TextLabel, effect: TextLabel, buy: TextButton, max: TextButton }
local cards: { [string]: Card } = {}
local autoButton: TextButton
do
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.52, 0),
		Size = UDim2.new(0, 290, 0, 480),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	scaled(panel)
	autoButton = button({ Size = UDim2.new(1, 0, 0, 42), Text = "🤖 자동 업그레이드: 끔", TextSize = 16, BackgroundColor3 = C.panel2, Parent = panel }, function()
		Request:FireServer("auto", not (state and state.auto))
	end)
	local list = scroller(panel, UDim2.new(1, 0, 1, -48), UDim2.new(0, 0, 0, 48))
	new("UIListLayout", { Padding = UDim.new(0, 6), Parent = list })
	for i, u in ipairs(Config.Upgrades) do
		local card = new("Frame", { Size = UDim2.new(1, -12, 0, 98), LayoutOrder = i, BackgroundColor3 = Color3.new(1, 1, 1), Parent = list }, { corner(12), stroke(C.line, 1.5), grad(C.panel2, C.bg) })
		text({ Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -20, 0, 22), TextSize = 17, Font = Enum.Font.GothamBlack, Text = u.icon .. " " .. u.name, Parent = card })
		local level = text({ Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -20, 0, 22), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.gold, Parent = card })
		local effect = text({ Position = UDim2.new(0, 10, 0, 27), Size = UDim2.new(1, -20, 0, 32), TextSize = 13, TextColor3 = C.dim, TextYAlignment = Enum.TextYAlignment.Top, Parent = card })
		local buy = button({ Position = UDim2.new(0, 8, 1, -36), Size = UDim2.new(0.66, -10, 0, 30), TextSize = 14, Parent = card }, function()
			Request:FireServer("upgrade", u.id, false)
		end)
		local max = button({ Position = UDim2.new(0.66, 2, 1, -36), Size = UDim2.new(0.34, -10, 0, 30), Text = "최대", TextSize = 13, BackgroundColor3 = C.pink, Parent = card }, function()
			Request:FireServer("upgrade", u.id, true)
		end)
		cards[u.id] = { level = level, effect = effect, buy = buy, max = max }
	end
end

------------------------------------------------------------------------
-- 창
------------------------------------------------------------------------
local window = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.53, 0),
	Size = UDim2.new(0, 780, 0, 540),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = false,
	ZIndex = 10,
	Parent = gui,
}, { corner(18), stroke(C.accent, 2.5), grad(C.panel2, C.bg) })
scaled(window)
local windowTitle = text({ Position = UDim2.new(0, 18, 0, 10), Size = UDim2.new(1, -80, 0, 36), TextSize = 26, Font = Enum.Font.GothamBlack, TextColor3 = C.accent, Parent = window })
button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.new(0, 40, 0, 36), Text = "✕", TextSize = 20, BackgroundColor3 = C.red, Parent = window }, function()
	window.Visible = false
end)
local pages: { [string]: Frame } = {}
local refreshers: { [string]: () -> () } = {}
local currentPage = ""
local function makePage(name: string): Frame
	local f = new("Frame", { Position = UDim2.new(0, 16, 0, 56), Size = UDim2.new(1, -32, 1, -68), BackgroundTransparency = 1, Visible = false, Parent = window })
	pages[name] = f
	return f
end
local TITLES = {
	store = "💎 상점",
	capsule = "🥚 위성 캡슐",
	sats = "🛰 내 위성",
	skins = "🎨 블랙홀 스킨",
	bigbang = "🌌 빅뱅",
	bbshop = "🌑 빅뱅 상점",
	zones = "🗺 세계와 구역",
	help = "📜 도움말",
	test = "🧪 테스트",
}
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
		Position = UDim2.new(0, 10, 0.52, 0),
		Size = UDim2.new(0, 140, 0, 11 * 48),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { new("UIListLayout", { Padding = UDim.new(0, 6) }) })
	scaled(menu)
	for _, item in ipairs({
		{ "lobby", "🏠 로비", Color3.fromRGB(40, 170, 140) },
		{ "store", "💎 상점", Color3.fromRGB(230, 160, 40) },
		{ "capsule", "🥚 캡슐", Color3.fromRGB(70, 160, 230) },
		{ "sats", "🛰 위성", Color3.fromRGB(90, 110, 220) },
		{ "skins", "🎨 스킨", Color3.fromRGB(200, 90, 200) },
		{ "bigbang", "🌌 빅뱅", Color3.fromRGB(200, 70, 150) },
		{ "bbshop", "🌑 빅뱅 상점", Color3.fromRGB(70, 40, 120) },
		{ "zones", "🗺 세계", Color3.fromRGB(60, 150, 120) },
		{ "help", "📜 도움말", C.panel2 },
		{ "test", "🧪 테스트", Color3.fromRGB(120, 60, 180) },
		{ "unstuck", "🆘 끼었어요", C.red },
	}) do
		menuButtons[item[1]] = button({ Size = UDim2.new(1, 0, 0, 42), Text = item[2], TextSize = 17, BackgroundColor3 = item[3], Parent = menu }, function()
			if item[1] == "lobby" then
				Request:FireServer("world", 0)
				window.Visible = false
			elseif item[1] == "unstuck" then
				Request:FireServer("unstuck")
			else
				openPage(item[1])
			end
		end)
	end
	menuButtons.test.Visible = false
	menuButtons.bbshop.Visible = false
	-- 상점 버튼은 반짝인다
	new("UIStroke", { Color = Color3.fromRGB(255, 240, 160), Thickness = 2.5, Parent = menuButtons.store })
end

------------------------------------------------------------------------
-- 💎 상점 (로벅스)
------------------------------------------------------------------------
do
	local page = makePage("store")
	local scroll = scroller(page, UDim2.fromScale(1, 1))
	new("UIListLayout", { Padding = UDim.new(0, 10), Parent = scroll })
	local buttons: { [string]: TextButton } = {}
	local productDesc: { [string]: TextLabel } = {}

	-- 대표 상품: 우주 위성 패키지
	local pack = Config.PASS_BY_KEY.petpack
	local featured = new("Frame", { Size = UDim2.new(1, -12, 0, 170), BackgroundColor3 = Color3.new(1, 1, 1), Parent = scroll }, {
		corner(16),
		stroke(Color3.fromRGB(255, 220, 120), 3),
		grad(Color3.fromRGB(150, 40, 60), Color3.fromRGB(40, 10, 60), 0),
	})
	for i, s in ipairs(Config.ExclusiveSats) do
		satView(featured, s, false, UDim2.new(0, 84, 0, 84), UDim2.new(0, 6 + (i - 1) * 64, 0, i == 2 and 4 or 60))
	end
	text({ Position = UDim2.new(0, 220, 0, 10), Size = UDim2.new(1, -230, 0, 34), TextSize = 26, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 230, 140), Text = pack.icon .. " " .. pack.name .. "  🔥 최고 인기", Parent = featured })
	text({ Position = UDim2.new(0, 220, 0, 46), Size = UDim2.new(1, -230, 0, 66), TextSize = 16, TextYAlignment = Enum.TextYAlignment.Top, Text = pack.desc, Parent = featured })
	buttons.petpack = button({ Position = UDim2.new(0, 220, 1, -50), Size = UDim2.new(0, 240, 0, 42), Text = "R$ " .. pack.price, TextSize = 22, BackgroundColor3 = C.green, Parent = featured }, function()
		Request:FireServer("buyPass", "petpack")
	end)

	text({ Size = UDim2.new(1, 0, 0, 30), TextSize = 21, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, Text = "🎫 게임패스 (한 번 사면 영원히)", Parent = scroll })
	local passGrid = new("Frame", { Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = scroll }, {
		new("UIGridLayout", { CellSize = UDim2.new(0.333, -8, 0, 150), CellPadding = UDim2.new(0, 8, 0, 8) }),
	})
	for _, pass in ipairs(Config.GamePasses) do
		if not pass.featured then
			local card = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Parent = passGrid }, { corner(12), stroke(C.line, 1.5), grad(C.panel2, C.bg) })
			text({ Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 26), TextSize = 19, Font = Enum.Font.GothamBlack, Text = pass.icon .. " " .. pass.name, Parent = card })
			text({ Position = UDim2.new(0, 10, 0, 34), Size = UDim2.new(1, -20, 0, 64), TextSize = 14, TextColor3 = C.dim, TextYAlignment = Enum.TextYAlignment.Top, Text = pass.desc, Parent = card })
			buttons[pass.key] = button({ Position = UDim2.new(0, 8, 1, -42), Size = UDim2.new(1, -16, 0, 34), Text = "R$ " .. pass.price, BackgroundColor3 = C.green, Parent = card }, function()
				Request:FireServer("buyPass", pass.key)
			end)
		end
	end

	text({ Size = UDim2.new(1, 0, 0, 30), TextSize = 21, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, Text = "⚡ 부스트와 꾸러미 (살 때마다)", Parent = scroll })
	local productGrid = new("Frame", { Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = scroll }, {
		new("UIGridLayout", { CellSize = UDim2.new(0.333, -8, 0, 140), CellPadding = UDim2.new(0, 8, 0, 8) }),
	})
	for _, product in ipairs(Config.Products) do
		local card = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Parent = productGrid }, { corner(12), stroke(C.line, 1.5), grad(Color3.fromRGB(40, 50, 90), C.bg) })
		text({ Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 26), TextSize = 18, Font = Enum.Font.GothamBlack, Text = product.icon .. " " .. product.name, Parent = card })
		productDesc[product.key] = text({ Position = UDim2.new(0, 10, 0, 34), Size = UDim2.new(1, -20, 0, 56), TextSize = 14, TextColor3 = C.dim, TextYAlignment = Enum.TextYAlignment.Top, Text = product.desc, Parent = card })
		button({ Position = UDim2.new(0, 8, 1, -42), Size = UDim2.new(1, -16, 0, 34), Text = "R$ " .. product.price, BackgroundColor3 = C.blue, Parent = card }, function()
			Request:FireServer("buyProduct", product.key)
		end)
	end
	text({ Size = UDim2.new(1, -12, 0, 44), TextSize = 14, TextColor3 = C.dim, Text = "가격은 로블록스에서 정한 값으로 결제돼요. 구매는 로블록스 결제 창에서 한 번 더 확인해요.", Parent = scroll })

	refreshers.store = function()
		if not state then
			return
		end
		for key, b in pairs(buttons) do
			local owned = state.passes[key] == true
			b.Text = owned and "보유 중 ✔" or ("R$ " .. Config.PASS_BY_KEY[key].price)
			b.BackgroundColor3 = owned and C.panel2 or C.green
			b.AutoButtonColor = not owned
		end
		local function packAmount(n: number): number
			return Config.biggestMass(currentWorld, state.radius) * n * state.totalMult
		end
		productDesc.massS.Text = Config.PRODUCT_BY_KEY.massS.desc .. "\n지금 사면 💠" .. fmt(packAmount(30))
		productDesc.massL.Text = Config.PRODUCT_BY_KEY.massL.desc .. "\n지금 사면 💠" .. fmt(packAmount(120))
	end
end

------------------------------------------------------------------------
-- 🥚 캡슐
------------------------------------------------------------------------
do
	local page = makePage("capsule")
	local info = text({ Size = UDim2.new(1, 0, 0, 26), TextSize = 16, TextColor3 = C.dim, Text = "질량으로 캡슐을 깨서 위성을 얻어요. 위성은 블랙홀 둘레를 돌며 질량 배율을 올려 줘요.", Parent = page })
	local row = new("Frame", { Position = UDim2.new(0, 0, 0, 32), Size = UDim2.new(1, 0, 1, -32), BackgroundTransparency = 1, Parent = page }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) }),
	})
	type CapUI = { one: TextButton, three: TextButton, lock: TextLabel }
	local capUI: { [string]: CapUI } = {}
	for _, cap in ipairs(Config.Capsules) do
		local card = new("Frame", { Size = UDim2.new(0.333, -7, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = row }, { corner(14), stroke(cap.color, 2), grad(cap.color:Lerp(C.bg, 0.55), C.bg) })
		text({ Position = UDim2.new(0, 0, 0, 6), Size = UDim2.new(1, 0, 0, 28), TextSize = 20, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, Text = cap.name, Parent = card })
		local best = cap.sats[#cap.sats]
		satView(card, best, false, UDim2.new(0, 90, 0, 90), UDim2.new(0.5, -45, 0, 34))
		local odds = {}
		for _, s in ipairs(cap.sats) do
			table.insert(odds, string.format('<font color="#%s">%s</font> %s%% ×%s', rarityColor(s.rarity):ToHex(), s.name, tostring(s.chance), tostring(s.mult)))
		end
		text({ Position = UDim2.new(0, 10, 0, 126), Size = UDim2.new(1, -20, 0, 150), TextSize = 14, RichText = true, TextYAlignment = Enum.TextYAlignment.Top, Text = table.concat(odds, "\n"), Parent = card })
		local lock = text({ Position = UDim2.new(0, 8, 1, -128), Size = UDim2.new(1, -16, 0, 24), TextSize = 14, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center, Text = "", Parent = card })
		local one = button({ Position = UDim2.new(0, 8, 1, -98), Size = UDim2.new(1, -16, 0, 42), Text = "💠 " .. fmt(cap.cost), TextSize = 17, Parent = card }, function()
			Request:FireServer("hatch", cap.id, false)
		end)
		local three = button({ Position = UDim2.new(0, 8, 1, -50), Size = UDim2.new(1, -16, 0, 42), Text = "🥚×3", TextSize = 15, BackgroundColor3 = C.pink, Parent = card }, function()
			Request:FireServer("hatch", cap.id, true)
		end)
		capUI[cap.id] = { one = one, three = three, lock = lock }
	end
	-- 캡슐은 로비에서만 깬다
	local goLobby = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, -2), Size = UDim2.new(0, 190, 0, 30), Text = "🏠 로비로 가기", TextSize = 14, BackgroundColor3 = Color3.fromRGB(40, 170, 140), Visible = false, Parent = page }, function()
		Request:FireServer("world", 0)
		window.Visible = false
	end)
	refreshers.capsule = function()
		if not state then
			return
		end
		goLobby.Visible = not state.inLobby
		info.Text = (state.inLobby and "" or "🏠 캡슐은 로비의 캡슐 기계에서 깰 수 있어요  ·  ") .. string.format("위성 가방 %d / %d  ·  🍀 행운 ×%.2f", #state.sats, Config.SAT_INVENTORY, (1 + 0.15 * (state.bb.luck or 0)) * (state.passes.luck and 2 or 1))
		for _, cap in ipairs(Config.Capsules) do
			local ui = capUI[cap.id]
			local open = state.bigbang >= Config.Worlds[cap.world].needBigbang
			ui.lock.Text = open and "" or "🔒 세계 2가 열리면 (빅뱅 1번)"
			ui.one.Text = "1개 · 💠 " .. fmt(cap.cost)
			ui.one.BackgroundColor3 = (open and state.mass >= cap.cost) and C.accent or C.panel2
			ui.three.Text = state.passes.triple and ("3개 · 💠 " .. fmt(cap.cost * 3)) or "🔒 3개 부화 (상점)"
			ui.three.BackgroundColor3 = (open and state.passes.triple and state.mass >= cap.cost * 3) and C.pink or C.panel2
		end
	end
end

------------------------------------------------------------------------
-- 🛰 내 위성
------------------------------------------------------------------------
do
	local page = makePage("sats")
	local header = text({ Size = UDim2.new(1, -210, 0, 34), TextSize = 17, Text = "", Parent = page })
	button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 200, 0, 34), Text = "⭐ 가장 센 위성 장착", TextSize = 15, BackgroundColor3 = C.gold, TextColor3 = C.bg, Parent = page }, function()
		Request:FireServer("satBest")
	end)
	local grid = scroller(page, UDim2.new(1, 0, 1, -140), UDim2.new(0, 0, 0, 40))
	new("UIGridLayout", { CellSize = UDim2.new(0, 104, 0, 124), CellPadding = UDim2.new(0, 8, 0, 8), Parent = grid })
	local detail = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 92), BackgroundColor3 = C.bg, Parent = page }, { corner(12), stroke(C.line, 1.5) })
	local detailText = text({ Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(0.5, -12, 1, -12), TextSize = 16, RichText = true, TextYAlignment = Enum.TextYAlignment.Top, Text = "위성을 눌러서 고르세요", Parent = detail })
	local selected = 0
	local equipBtn = button({ Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(0.17, -6, 0, 72), Text = "장착", TextSize = 16, Parent = detail }, function()
		if selected > 0 then
			Request:FireServer("satEquip", selected)
		end
	end)
	local goldBtn = button({ Position = UDim2.new(0.67, 0, 0, 10), Size = UDim2.new(0.17, -6, 0, 72), Text = "✨ 황금", TextSize = 15, BackgroundColor3 = C.gold, TextColor3 = C.bg, Parent = detail }, function()
		if selected > 0 and state then
			for _, s in ipairs(state.sats) do
				if s.uid == selected then
					Request:FireServer("satGold", s.id)
				end
			end
		end
	end)
	local delBtn = button({ Position = UDim2.new(0.84, 0, 0, 10), Size = UDim2.new(0.16, -10, 0, 72), Text = "🗑 버리기", TextSize = 15, BackgroundColor3 = C.red, Parent = detail }, function()
		if selected > 0 then
			Request:FireServer("satDelete", selected)
			selected = 0
		end
	end)
	local signature = ""
	local cells: { [number]: Frame } = {}

	local function refreshDetail()
		if not state then
			return
		end
		for uid, cell in pairs(cells) do
			local st = cell:FindFirstChildOfClass("UIStroke")
			if st then
				st.Thickness = uid == selected and 4 or 2
			end
		end
		local sel = nil
		for _, s in ipairs(state.sats) do
			if s.uid == selected then
				sel = s
			end
		end
		equipBtn.Visible = sel ~= nil
		goldBtn.Visible = sel ~= nil
		delBtn.Visible = sel ~= nil
		if not sel then
			detailText.Text = "위성을 눌러서 고르세요.\n같은 위성 5개 → ✨ 황금 위성 (배율 2.5배)"
			return
		end
		local def = Config.SAT_BY_ID[sel.id]
		local same = 0
		for _, s in ipairs(state.sats) do
			if s.id == sel.id and not s.gold then
				same += 1
			end
		end
		local equipped = table.find(state.equipped, sel.uid) ~= nil
		detailText.Text = string.format('<b>%s%s</b>\n<font color="#%s">%s</font>  ·  질량 ×%s\n같은 위성 %d개', sel.gold and "✨황금 " or "", def.name, rarityColor(def.rarity):ToHex(), Config.Rarities[def.rarity].name, string.format("%.2f", Config.satMult(sel.id, sel.gold)), same)
		equipBtn.Text = equipped and "해제" or "장착"
		equipBtn.BackgroundColor3 = equipped and C.panel2 or C.green
		goldBtn.Text = string.format("✨ 황금\n%d/%d", math.min(same, Config.GOLD_COUNT), Config.GOLD_COUNT)
		goldBtn.BackgroundColor3 = (not sel.gold and same >= Config.GOLD_COUNT) and C.gold or C.panel2
		delBtn.BackgroundColor3 = def.rarity >= 6 and C.panel2 or C.red
	end

	refreshers.sats = function()
		if not state then
			return
		end
		header.Text = string.format("장착 %d / %d칸  ·  위성 배율 ×%s  ·  가방 %d / %d", #state.equipped, state.slots, string.format("%.2f", state.satMult), #state.sats, Config.SAT_INVENTORY)
		local parts = {}
		for _, s in ipairs(state.sats) do
			table.insert(parts, s.uid .. (s.gold and "g" or ""))
		end
		local sig = table.concat(parts, ",") .. "|" .. table.concat(state.equipped, ",")
		if sig ~= signature then
			signature = sig
			clear(grid)
			cells = {}
			local list = table.clone(state.sats)
			table.sort(list, function(a, b)
				local ea = table.find(state.equipped, a.uid) ~= nil
				local eb = table.find(state.equipped, b.uid) ~= nil
				if ea ~= eb then
					return ea
				end
				local ma, mb = Config.satMult(a.id, a.gold), Config.satMult(b.id, b.gold)
				if ma ~= mb then
					return ma > mb
				end
				return a.uid < b.uid
			end)
			for i, s in ipairs(list) do
				local def = Config.SAT_BY_ID[s.id]
				local equipped = table.find(state.equipped, s.uid) ~= nil
				local cell = new("TextButton", { Text = "", LayoutOrder = i, AutoButtonColor = true, BackgroundColor3 = Color3.new(1, 1, 1), Parent = grid }, {
					corner(12),
					stroke(s.gold and C.gold or rarityColor(def.rarity), 2),
					grad(rarityColor(def.rarity):Lerp(C.bg, 0.6), C.bg),
				})
				satView(cell, def, s.gold, UDim2.new(1, -16, 0, 72), UDim2.new(0, 8, 0, 4))
				text({ Position = UDim2.new(0, 4, 0, 76), Size = UDim2.new(1, -8, 0, 20), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Text = (s.gold and "✨" or "") .. def.name, Parent = cell })
				text({ Position = UDim2.new(0, 4, 0, 96), Size = UDim2.new(1, -8, 0, 20), TextSize = 14, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = C.gold, Text = "×" .. string.format("%.1f", Config.satMult(s.id, s.gold)), Parent = cell })
				if equipped then
					text({ Position = UDim2.new(0, 6, 0, 4), Size = UDim2.new(0, 26, 0, 22), TextSize = 18, Text = "✔", TextColor3 = C.green, Parent = cell })
				end
				cell.Activated:Connect(function()
					selected = s.uid
					refreshDetail()
				end)
				cells[s.uid] = cell
			end
			if #list == 0 then
				text({ Size = UDim2.new(0, 400, 0, 60), TextSize = 17, TextColor3 = C.dim, Text = "아직 위성이 없어요. 🥚 캡슐을 깨 보세요!", Parent = grid })
			end
		end
		refreshDetail()
	end
end

------------------------------------------------------------------------
-- 🎨 스킨
------------------------------------------------------------------------
local EFFECT_ICON = { fire = "🔥", ice = "❄", galaxy = "🌌", candy = "🍬", gold = "✨", eye = "👁", rainbow = "🌈" }
local EFFECT_TEXT = {
	fire = "🔥 불꽃이 솟아올라요",
	ice = "❄ 얼음 조각과 눈송이가 돌아요",
	galaxy = "🌌 별빛 고리가 기울어 돌아요",
	candy = "🍬 사탕 가루가 날려요",
	gold = "✨ 금빛이 반짝여요",
	eye = "👁 눈동자가 움직이는 쪽을 봐요",
	rainbow = "🌈 테두리가 무지개로 바뀌어요",
}
local skinPreview: any = nil -- 스킨 창 미리보기 (Fx가 만든 블랙홀)
do
	local page = makePage("skins")
	-- 위: 고른 스킨을 실제 블랙홀 모양으로 크게 보여 준다
	local top = new("Frame", { Size = UDim2.new(1, 0, 0, 210), BackgroundColor3 = C.bg, Parent = page }, { corner(14), stroke(C.line, 1.5) })
	local vf = new("ViewportFrame", {
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(0, 198, 0, 198),
		BackgroundColor3 = Color3.fromRGB(8, 6, 16),
		Ambient = Color3.fromRGB(200, 200, 210),
		LightColor = Color3.new(1, 1, 1),
		Parent = top,
	}, { corner(12) })
	local cam = new("Camera", { FieldOfView = 50, Parent = vf })
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 7.5, -8.5), Vector3.new(0, 0.3, 0))
	vf.CurrentCamera = cam
	local nameLabel = text({ Position = UDim2.new(0, 222, 0, 12), Size = UDim2.new(1, -236, 0, 36), TextSize = 28, Font = Enum.Font.GothamBlack, Parent = top })
	local effectLabel = text({ Position = UDim2.new(0, 222, 0, 52), Size = UDim2.new(1, -236, 0, 28), TextSize = 19, TextColor3 = C.dim, Parent = top })
	local abilityLabel = text({ Position = UDim2.new(0, 222, 0, 80), Size = UDim2.new(1, -236, 0, 44), TextSize = 17, RichText = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = top })
	local howLabel = text({ Position = UDim2.new(0, 222, 0, 124), Size = UDim2.new(1, -236, 0, 22), TextSize = 16, TextColor3 = C.gold, TextYAlignment = Enum.TextYAlignment.Top, Parent = top })
	local shown = ""
	local useBtn = button({ Position = UDim2.new(0, 222, 1, -64), Size = UDim2.new(0, 260, 0, 54), Text = "", TextSize = 22, Parent = top }, function()
		if shown ~= "" then
			Request:FireServer("skin", shown)
		end
	end)

	local function skinStatus(skin: any): (string, Color3, string)
		local owned = state and table.find(state.skins, skin.id) ~= nil
		if state and state.skin == skin.id then
			return "사용 중 ✔", C.green, "지금 쓰고 있어요"
		elseif owned then
			return "사용하기", C.accent, "가지고 있어요"
		elseif skin.unlock == "bigbang" then
			return string.format("🔒 빅뱅 %d번", skin.value), C.panel2, string.format("빅뱅을 %d번 하면 열려요", skin.value)
		elseif skin.unlock == "dm" then
			local can = state and state.dm >= skin.value
			return string.format("🌑 %d 로 사기", skin.value), can and Color3.fromRGB(110, 60, 180) or C.panel2, string.format("암흑 물질 %d개로 살 수 있어요", skin.value)
		elseif skin.unlock == "world2" then
			return "🔒 사탕 태양 삼키기", C.panel2, "세계 2의 사탕 태양을 삼키면 열려요"
		end
		local pass = Config.PASS_BY_KEY[skin.value]
		return "💎 " .. pass.name, Color3.fromRGB(200, 140, 40), "💎 상점의 " .. pass.name .. "에 들어 있어요"
	end

	local function show(skin: any)
		if shown ~= skin.id then
			shown = skin.id
			if skinPreview then
				Fx.removePreview(skinPreview)
			end
			skinPreview = Fx.preview(skin.index, 3, Vector3.new(0, 0, 0), vf)
		end
		nameLabel.Text = skin.name
		nameLabel.TextColor3 = skin.a:Lerp(Color3.new(1, 1, 1), 0.3)
		effectLabel.Text = skin.effect and EFFECT_TEXT[skin.effect] or "기본 소용돌이"
		local ab = skin.ability
		if ab then
			abilityLabel.Text = string.format('<font color="#FFD25A"><b>%s %s</b></font> %s\n%s', ab.kind == "active" and "⚡" or "✦", ab.name, ab.kind == "active" and string.format("(Q, %d초마다)", ab.cd) or "(늘 켜짐)", ab.desc)
		else
			abilityLabel.Text = ""
		end
		local label, col, how = skinStatus(skin)
		howLabel.Text = how
		useBtn.Text = label
		useBtn.BackgroundColor3 = col
	end

	-- 아래: 스킨 카드 (누르면 위에 크게 보인다)
	local scroll = scroller(page, UDim2.new(1, 0, 1, -218), UDim2.new(0, 0, 0, 218))
	new("UIGridLayout", { CellSize = UDim2.new(0.25, -8, 0, 172), CellPadding = UDim2.new(0, 8, 0, 8), Parent = scroll })
	local skinButtons: { [string]: TextButton } = {}
	for _, skin in ipairs(Config.Skins) do
		local card = new("TextButton", { Text = "", AutoButtonColor = true, BackgroundColor3 = Color3.new(1, 1, 1), Parent = scroll }, { corner(12), stroke(skin.a, 1.5), grad(C.panel2, C.bg) })
		card.Activated:Connect(function()
			show(skin)
		end)
		local swatch = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(0, 56, 0, 56), BackgroundColor3 = Color3.new(1, 1, 1), Parent = card }, {
			corner(28),
			new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, skin.a), ColorSequenceKeypoint.new(0.5, Color3.new(0, 0, 0)), ColorSequenceKeypoint.new(1, skin.b) }), Rotation = 45 }),
			new("UIStroke", { Color = skin.a, Thickness = 3 }),
		})
		if skin.effect then
			text({ Size = UDim2.fromScale(1, 1), TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center, Text = EFFECT_ICON[skin.effect] or "", Parent = swatch })
		end
		text({ Position = UDim2.new(0, 4, 0, 64), Size = UDim2.new(1, -8, 0, 36), TextSize = 16, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, Text = skin.name, Parent = card })
		if skin.ability then
			text({ Position = UDim2.new(0, 4, 0, 100), Size = UDim2.new(1, -8, 0, 22), TextSize = 13, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center, Text = (skin.ability.kind == "active" and "⚡ " or "✦ ") .. skin.ability.name, Parent = card })
		end
		skinButtons[skin.id] = button({ Position = UDim2.new(0, 6, 1, -42), Size = UDim2.new(1, -12, 0, 36), TextSize = 14, Parent = card }, function()
			show(skin)
			Request:FireServer("skin", skin.id)
		end)
	end
	refreshers.skins = function()
		if not state then
			return
		end
		show(Config.SKIN_BY_ID[shown] or Config.SKIN_BY_ID[state.skin] or Config.Skins[1])
		for _, skin in ipairs(Config.Skins) do
			local label, col = skinStatus(skin)
			skinButtons[skin.id].Text = label
			skinButtons[skin.id].BackgroundColor3 = col
		end
	end
end

------------------------------------------------------------------------
-- 🌌 빅뱅
------------------------------------------------------------------------
do
	local page = makePage("bigbang")
	local info = text({ Size = UDim2.new(1, 0, 1, -80), TextSize = 19, RichText = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = page })
	local go = button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(0, 300, 0, 60), Text = "🌌 빅뱅!", TextSize = 24, BackgroundColor3 = Color3.fromRGB(200, 70, 160), Parent = page }, function()
		Request:FireServer("bigbang")
		window.Visible = false
	end)
	refreshers.bigbang = function()
		if not state then
			return
		end
		local ready = state.radius >= Config.BIGBANG_RADIUS
		local reward = Config.darkMatterReward(math.max(state.radius, Config.BIGBANG_RADIUS), state.bigbang)
		local nextSkin = nil
		for _, skin in ipairs(Config.Skins) do
			if skin.unlock == "bigbang" and skin.value > state.bigbang then
				nextSkin = skin
				break
			end
		end
		info.Text = table.concat({
			"우주를 처음부터 다시 시작해요. 질량과 업그레이드는 사라지지만:",
			"",
			string.format("• 영구 질량 배율  <b>×%d → ×%d</b>", state.bigbang + 1, state.bigbang + 2),
			string.format('• <font color="#C8A0FF">🌑 암흑 물질 +%d개</font> (더 크게 커져서 할수록 더 많이)', reward),
			"• 🌑 빅뱅 상점에서 영원히 남는 업그레이드를 살 수 있어요",
			state.bigbang == 0 and '• <font color="#FF9AD5">🍭 세계 2 「과자 왕국」이 열려요!</font>' or "",
			nextSkin and string.format("• 다음 스킨: %s (빅뱅 %d번)", nextSkin.name, nextSkin.value) or "",
			"",
			string.format("지금 빅뱅 %d회  ·  🌑 %d개", state.bigbang, state.dm),
			string.format('조건: 크기 ⚫%d 이상  ·  지금 <font color="#%s">⚫%s</font>', Config.BIGBANG_RADIUS, ready and "6CFF9A" or "FF7A8A", Config.formatSize(state.radius)),
		}, "\n")
		go.TextTransparency = ready and 0 or 0.5
		go.BackgroundColor3 = ready and Color3.fromRGB(200, 70, 160) or C.panel2
	end
end

------------------------------------------------------------------------
-- 🌑 빅뱅 상점 (암흑 물질, 빅뱅해도 남는다)
------------------------------------------------------------------------
do
	local page = makePage("bbshop")
	local header = text({ Size = UDim2.new(1, 0, 0, 34), TextSize = 21, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(200, 160, 255), Parent = page })
	local scroll = scroller(page, UDim2.new(1, 0, 1, -40), UDim2.new(0, 0, 0, 40))
	new("UIListLayout", { Padding = UDim.new(0, 8), Parent = scroll })
	type Row = { level: TextLabel, buy: TextButton }
	local rows: { [string]: Row } = {}
	for _, b in ipairs(Config.BigbangShop) do
		local row = new("Frame", { Size = UDim2.new(1, -12, 0, 66), BackgroundColor3 = Color3.new(1, 1, 1), Parent = scroll }, { corner(12), stroke(C.line, 1.5), grad(Color3.fromRGB(50, 30, 90), C.bg, 0) })
		text({ Position = UDim2.new(0, 12, 0, 4), Size = UDim2.new(1, -190, 0, 30), TextSize = 20, Font = Enum.Font.GothamBlack, Text = b.icon .. " " .. b.name, Parent = row })
		local level = text({ Position = UDim2.new(0, 12, 0, 34), Size = UDim2.new(1, -190, 0, 26), TextSize = 15, TextColor3 = C.dim, Parent = row })
		local buy = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 160, 0, 46), TextSize = 17, BackgroundColor3 = Color3.fromRGB(110, 60, 180), Parent = row }, function()
			Request:FireServer("bbshop", b.id)
		end)
		rows[b.id] = { level = level, buy = buy }
	end
	refreshers.bbshop = function()
		if not state then
			return
		end
		header.Text = string.format("🌑 암흑 물질 %d개   (빅뱅할 때마다 얻어요)", state.dm)
		for _, b in ipairs(Config.BigbangShop) do
			local lv = state.bb[b.id] or 0
			local maxed = lv >= b.maxLevel
			local cost = Config.bigbangShopCost(b.id, lv)
			rows[b.id].level.Text = string.format("%s  ·  Lv.%d / %d", b.desc, lv, b.maxLevel)
			rows[b.id].buy.Text = maxed and "MAX" or ("🌑 " .. cost)
			rows[b.id].buy.BackgroundColor3 = (not maxed and state.dm >= cost) and Color3.fromRGB(140, 80, 230) or C.panel2
		end
	end
end

------------------------------------------------------------------------
-- 🗺 세계와 구역
------------------------------------------------------------------------
do
	local page = makePage("zones")
	local scroll = scroller(page, UDim2.fromScale(1, 1))
	new("UIListLayout", { Padding = UDim.new(0, 6), Parent = scroll })
	type ZoneRow = { btn: TextButton, label: TextLabel }
	local rows: { [number]: ZoneRow } = {}
	local worldRows: { [number]: ZoneRow } = {}
	for wi, world in ipairs(Config.Worlds) do
		local head = new("Frame", { Size = UDim2.new(1, -12, 0, 56), BackgroundColor3 = Color3.new(1, 1, 1), Parent = scroll }, { corner(12), stroke(world.sky, 2), grad(world.sky:Lerp(C.bg, 0.5), C.bg, 0) })
		local label = text({ Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -170, 1, 0), TextSize = 21, Font = Enum.Font.GothamBlack, Parent = head })
		local btn = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 140, 0, 40), Text = "세계로 이동", Parent = head }, function()
			Request:FireServer("world", wi)
			window.Visible = false
		end)
		worldRows[wi] = { btn = btn, label = label }
		for n, zi in ipairs(Config.zonesOf(wi)) do
			local zone = Config.Zones[zi]
			local row = new("Frame", { Size = UDim2.new(1, -12, 0, 46), BackgroundColor3 = Color3.new(1, 1, 1), Parent = scroll }, { corner(10), grad(zone.ground:Lerp(C.bg, 0.45), C.bg, 0) })
			local zl = text({ Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(1, -170, 1, 0), TextSize = 17, Parent = row })
			local zb = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 120, 0, 36), Text = "이동", Parent = row }, function()
				Request:FireServer("teleport", zi)
				window.Visible = false
			end)
			zl.Text = string.format("%d. %s", n, zone.name)
			rows[zi] = { btn = zb, label = zl }
		end
	end
	refreshers.zones = function()
		if not state then
			return
		end
		for wi, world in ipairs(Config.Worlds) do
			local open = state.bigbang >= world.needBigbang
			worldRows[wi].label.Text = string.format("%s 세계 %d · %s  %s", wi == 1 and "🌍" or "🍭", wi, world.name, open and "" or string.format("🔒 빅뱅 %d번", world.needBigbang))
			worldRows[wi].btn.Text = currentWorld == wi and "여기 있어요" or (open and "세계로 이동" or "잠김")
			worldRows[wi].btn.BackgroundColor3 = (open and currentWorld ~= wi) and C.green or C.panel2
			for n, zi in ipairs(Config.zonesOf(wi)) do
				local zone = Config.Zones[zi]
				local ok = open and state.radius >= zone.need
				rows[zi].label.Text = string.format("%d. %s  %s", n, zone.name, ok and "" or ("🔒 크기 " .. zone.need))
				rows[zi].btn.Text = ok and "이동" or "잠김"
				rows[zi].btn.BackgroundColor3 = ok and C.accent or C.panel2
			end
		end
	end
end

------------------------------------------------------------------------
-- 📜 도움말 (큰 글씨)
------------------------------------------------------------------------
do
	local page = makePage("help")
	local scroll = scroller(page, UDim2.fromScale(1, 1))
	local objLines = {}
	for wi, world in ipairs(Config.Worlds) do
		table.insert(objLines, string.format("<b>%s 세계 %d · %s</b>%s", wi == 1 and "🌍" or "🍭", wi, world.name, world.needBigbang > 0 and string.format(" (빅뱅 %d번 하면 열림, 질량 약 5배)", world.needBigbang) or ""))
		for n, zi in ipairs(Config.zonesOf(wi)) do
			local names = {}
			for _, o in ipairs(Config.Objects) do
				if o.zone == zi then
					table.insert(names, string.format("%s(%s)", o.name, Config.formatSize(o.size)))
				end
			end
			table.insert(objLines, string.format("  %d %s: %s", n, Config.Zones[zi].name, table.concat(names, ", ")))
		end
	end
	text({
		Size = UDim2.new(1, -14, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 20,
		RichText = true,
		LineHeight = 1.15,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = table.concat({
			"<b>🕳 당신은 작은 블랙홀이에요.</b> 돌아다니면 내 크기보다 작은 건 전부 빨려 들어와요.",
			"",
			"<b>조작</b>",
			"• 이동: WASD 또는 화면 조이스틱 · 스킬: Q 또는 오른쪽 아래 둥근 버튼",
			"• 단축키: B 빅뱅 · M 세계 · P 위성 · G 상점 · K 스킨 · E 로비 기계 쓰기",
			"• 어딘가에 끼면 왼쪽 🆘 끼었어요 버튼 (또는 로블록스 메뉴의 다시 시작)",
			"",
			"<b>🏠 로비</b>",
			"• 처음엔 로비에서 시작해요. 왼쪽 메뉴 🏠 로비 버튼이나 세계 시작 지점 왼쪽 문으로 돌아와요",
			"• 북쪽 캡슐 기계에서 위성을 뽑고, 남쪽 스킨 전시관에서 스킨 12종과 능력을 구경해요",
			"• 🎁 매일 보상 상자 (연속으로 받을수록 많이), 💎 상점 가판대, 🏆 서버 순위판",
			"• 서쪽 문 → 세계 1, 동쪽 문 → 세계 2",
			"",
			"<b>커지기</b>",
			"• <b>먹을수록 커져요!</b> 내 크기에 가까운 큰 걸 삼킬수록 확 커져요 (괄호 안 숫자가 필요한 크기)",
			"• 클수록 덜 자라서, 뒤쪽 구역은 오래 놀아야 커져요. 최대 크기는 빅뱅할수록 늘어나요",
			"• 삼키면 💠질량도 쌓여요. 질량으로 오른쪽 업그레이드 9종을 사요 (내려서 더 보기)",
			"• ⚫ 성장력 · 💠 질량 배율 · 🌀 흡입력 · 👟 이동 속도 · 📏 크기 한계 · ♻ 빠른 재생 · ☄ 별똥별 자석 · 🔥 콤보 증폭 · ✨ 황금 탐지",
			"• 🤖 자동 업그레이드를 켜면 알아서 사요",
			"",
			"<b>보너스</b>",
			string.format("• 🔥 연속 흡수: %.1f초 안에 계속 삼키면 한 번마다 질량 +1%% (최대 +100%%)", Config.COMBO_WINDOW),
			string.format("• ✨ 황금 물체: 가끔 금빛으로 나타나요. 질량 %d배, 성장 %.1f배", Config.GOLDEN_MASS, Config.GOLDEN_GROW),
			string.format("• ☄ 별똥별: 삼키면 %d초 동안 질량과 성장 2배", Config.STAR_BOOST),
			"• 📋 퀘스트: 늘 3개. 끝내면 바로 질량이나 🌑 암흑 물질을 받아요",
			"",
			"<b>🎨 스킨 능력</b>",
			"• ✦ 패시브: 늘 켜져 있어요 (흡입·성장·질량·황금·별똥별 보너스)",
			"• ⚡ 액티브: Q로 써요 (빠르게 달리기, 흡입 범위 키우기, 주변 한꺼번에 흡수)",
			"",
			"<b>🛰 위성</b>",
			"• 로비 캡슐 기계에서 위성을 뽑아요. 블랙홀 둘레를 돌며 질량 배율을 올려 줘요",
			string.format("• 같은 위성 %d개를 합치면 ✨황금 위성 (효과 %.1f배)", Config.GOLD_COUNT, Config.GOLD_POWER),
			"",
			"<b>🌌 빅뱅 (환생)</b>",
			string.format("• 크기 ⚫%d이 되면 처음부터 다시 시작하는 대신 영구 배율이 오르고 🌑암흑 물질을 받아요", Config.BIGBANG_RADIUS),
			"• 빅뱅할 때마다 최대 크기 +300, 성장 +10%",
			"• 🌑 빅뱅 상점: 시작 크기, 빠른 재생산, 질량, 속도, 흡입, 행운, 위성 칸, 질량 보존, 암흑 수확",
			"• 첫 빅뱅을 하면 🍭 세계 2가 열려요. 세계 1보다 훨씬 넓고 구역이 8개예요",
			"",
			"<b>🗺 구역</b> (색 벽은 크기가 되면 통과돼요)",
			table.concat(objLines, "\n"),
			"",
			"💾 기록은 자동으로 저장돼요",
		}, "\n"),
		Parent = scroll,
	})
end

------------------------------------------------------------------------
-- 🧪 테스트 (테스트 계정에서만)
------------------------------------------------------------------------
do
	local page = makePage("test")
	new("UIListLayout", { Padding = UDim.new(0, 8), Parent = page })
	text({ Size = UDim2.new(1, 0, 0, 44), TextSize = 15, TextColor3 = C.dim, Text = "스튜디오나 게임 주인으로 들어오면 테스트 계정이에요. 기록은 저장하지 않아요. 상점 번호가 0인 상품은 눌러서 무료로 시험할 수 있어요.", Parent = page })
	local row1 = hlist(page, 44)
	for _, amount in ipairs({ 1e3, 1e6, 1e9, 1e12, 1e15 }) do
		button({ Size = UDim2.new(0.2, -5, 1, 0), Text = "💠 +" .. fmt(amount), TextSize = 15, Parent = row1 }, function()
			Request:FireServer("testMass", amount)
		end)
	end
	local row2 = hlist(page, 44)
	for _, r in ipairs({ 1.5, 6, 14, 30, 65, 140, 350, 600, 800, 1000 }) do
		button({ Size = UDim2.new(0.1, -5, 1, 0), Text = "⚫" .. tostring(r), TextSize = 12, BackgroundColor3 = C.blue, Parent = row2 }, function()
			Request:FireServer("testSize", r)
		end)
	end
	local row3 = hlist(page, 44)
	for _, item in ipairs({
		{ "⭐ 업그레이드 최대", "testMaxAll", C.pink },
		{ "🌑 암흑 물질 +50", "testDM", Color3.fromRGB(110, 60, 180) },
		{ "🌌 빅뱅 +1", "testBigbang", Color3.fromRGB(200, 70, 150) },
		{ "☄ 별똥별 지금", "testStar", Color3.fromRGB(220, 160, 40) },
	}) do
		button({ Size = UDim2.new(0.25, -5, 1, 0), Text = item[1], TextSize = 14, BackgroundColor3 = item[3], Parent = row3 }, function()
			Request:FireServer(item[2])
		end)
	end
	local row4 = hlist(page, 44)
	button({ Size = UDim2.new(0.33, -4, 1, 0), Text = "⚡ 스킬 대기 없애기", TextSize = 14, BackgroundColor3 = C.gold, TextColor3 = C.bg, Parent = row4 }, function()
		Request:FireServer("testSkill")
	end)
	button({ Size = UDim2.new(0.33, -4, 1, 0), Text = "🎁 매일 보상 다시", TextSize = 14, BackgroundColor3 = Color3.fromRGB(40, 170, 140), Parent = row4 }, function()
		Request:FireServer("testDaily")
	end)
	button({ Size = UDim2.new(0.33, -4, 1, 0), Text = "↺ 처음으로", TextSize = 15, BackgroundColor3 = C.red, Parent = row4 }, function()
		Request:FireServer("testReset")
	end)
end

------------------------------------------------------------------------
-- 캡슐 깨기 연출: 흔들리다 번쩍, 위성이 나타난다
------------------------------------------------------------------------
local playHatch
do
	local overlay = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Visible = false, ZIndex = 50, Active = true, Parent = gui })
	local holder = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 720, 0, 360), BackgroundTransparency = 1, Parent = overlay })
	scaled(holder)
	local busy = false
	function playHatch(capId: string, results: { string })
		local cap = Config.CAPSULE_BY_ID[capId]
		if not cap or busy then
			return
		end
		busy = true
		clear(holder)
		overlay.Visible = true
		-- 1) 흔들리는 캡슐
		local egg = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 170, 0, 210), BackgroundColor3 = Color3.new(1, 1, 1), Parent = holder }, {
			corner(85),
			new("UIGradient", { Color = ColorSequence.new(cap.color:Lerp(Color3.new(1, 1, 1), 0.5), cap.color), Rotation = 90 }),
			new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 4 }),
		})
		text({ Size = UDim2.fromScale(1, 1), TextSize = 60, TextXAlignment = Enum.TextXAlignment.Center, Text = "?", Font = Enum.Font.GothamBlack, Parent = egg })
		Fx.sound("whoosh", 0.4, 1.4)
		for i = 1, 8 do
			egg.Rotation = (i % 2 == 0 and 1 or -1) * (6 + i * 2)
			task.wait(0.09)
		end
		egg.Rotation = 0
		-- 2) 번쩍
		local flash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 60, Parent = overlay })
		TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		egg:Destroy()
		Fx.sound("slash", 0.6, 1.2)
		-- 3) 결과
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 300), BackgroundTransparency = 1, Parent = holder }, {
			new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 14) }),
		})
		local bestRarity = 1
		for _, id in ipairs(results) do
			local def = Config.SAT_BY_ID[id]
			if def then
				bestRarity = math.max(bestRarity, def.rarity)
				local col = rarityColor(def.rarity)
				local card = new("Frame", { Size = UDim2.new(0, 210, 0, 290), BackgroundColor3 = Color3.new(1, 1, 1), Parent = row }, { corner(16), new("UIStroke", { Color = col, Thickness = 4 }), grad(col:Lerp(C.bg, 0.4), C.bg) })
				local sc = new("UIScale", { Scale = 0.3, Parent = card })
				TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				satView(card, def, false, UDim2.new(1, -20, 0, 170), UDim2.new(0, 10, 0, 6))
				text({ Position = UDim2.new(0, 0, 0, 178), Size = UDim2.new(1, 0, 0, 34), TextSize = 22, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, Text = def.name, Parent = card })
				text({ Position = UDim2.new(0, 0, 0, 212), Size = UDim2.new(1, 0, 0, 30), TextSize = 20, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = col, Text = Config.Rarities[def.rarity].name, Parent = card })
				text({ Position = UDim2.new(0, 0, 0, 244), Size = UDim2.new(1, 0, 0, 30), TextSize = 20, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = C.gold, Text = "질량 ×" .. tostring(def.mult), Parent = card })
			end
		end
		if bestRarity >= 4 then
			Fx.sound("whoosh", 0.8, 0.5)
			local c = player.Character and Fx.holeCenter(player.Character)
			if c then
				Fx.pillar(c, rarityColor(bestRarity), 200, 16, 1)
			end
		end
		task.wait(0.6)
		flash:Destroy()
		local closeBtn = button({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 312), Size = UDim2.new(0, 200, 0, 44), Text = "좋아요!", TextSize = 20, BackgroundColor3 = C.green, Parent = holder }, function()
			overlay.Visible = false
			busy = false
		end)
		task.delay(4, function()
			if closeBtn.Parent and overlay.Visible then
				overlay.Visible = false
				busy = false
			end
		end)
	end
end

------------------------------------------------------------------------
-- 갱신
------------------------------------------------------------------------
local function boostText(): (string, boolean)
	if not state then
		return "", false
	end
	local passed = os.clock() - stateAt
	local list = {}
	local ended = false
	local function add(left: number, label: string)
		if left > 0 then
			local now = left - passed
			if now > 0 then
				table.insert(list, label .. " " .. Config.formatTime(now))
			else
				ended = true
			end
		end
	end
	add(state.starLeft, "⭐ 별똥별 2배")
	add(state.boostLeft, "🔥 질량 2배")
	add(state.respawnLeft, "♻ 빠른 재생산")
	return table.concat(list, "   "), ended
end

local function refreshAll()
	if not state then
		return
	end
	HUD.mass.Text = "💠 " .. fmt(state.mass)
	HUD.stat.Text = string.format(
		"⚫ %s/%s   🌱 ×%s   🌀 +%s   ✖ %s%s%s",
		Config.formatSize(state.radius),
		Config.formatSize(state.maxRadius),
		string.format("%.2f", state.growMult or 1),
		Config.formatSize(state.pullRange),
		fmt(state.totalMult),
		state.bigbang > 0 and string.format("   🌌 %d", state.bigbang) or "",
		state.dm > 0 and string.format("   🌑 %d", state.dm) or ""
	)
	autoButton.Text = state.auto and "🤖 자동 업그레이드: 켬" or "🤖 자동 업그레이드: 끔"
	autoButton.BackgroundColor3 = state.auto and C.green or C.panel2
	for _, u in ipairs(Config.Upgrades) do
		local card = cards[u.id]
		local level = state.up[u.id] or 0
		local maxed = level >= u.maxLevel
		card.level.Text = maxed and "MAX" or string.format("Lv.%d / %d", level, u.maxLevel)
		card.effect.Text = u.desc .. "\n" .. u.show(level) .. (maxed and "" or ("  →  " .. u.show(level + 1)))
		local cost = Config.upgradeCost(u.id, level)
		local can = not maxed and state.mass >= cost
		card.buy.Text = maxed and "최대" or ("💠 " .. fmt(cost))
		card.buy.BackgroundColor3 = can and C.accent or C.panel2
		card.max.BackgroundColor3 = can and C.pink or C.panel2
	end
	-- 다음 구역 진행 막대 (지금 세계 기준)
	local r = state.radius
	local nextZone = nil
	local prevNeed = 0
	for _, zi in ipairs(Config.zonesOf(currentWorld)) do
		local zone = Config.Zones[zi]
		if zone.need > r then
			nextZone = nextZone or zone
		else
			prevNeed = zone.need
		end
	end
	if state.inLobby then
		Bar.fill.Size = UDim2.fromScale(1, 1)
		Bar.label.Text = "🏠 로비 · 캡슐은 북쪽, 세계 1은 서쪽, 세계 2는 동쪽 문"
	elseif nextZone then
		local ratio = math.clamp((r - prevNeed) / math.max(nextZone.need - prevNeed, 0.01), 0, 1)
		Bar.fill.Size = UDim2.fromScale(ratio, 1)
		Bar.label.Text = string.format("다음 구역 '%s'까지  ⚫ %s / %d", nextZone.name, Config.formatSize(r), nextZone.need)
	elseif state.radius >= Config.BIGBANG_RADIUS then
		local ratio = math.clamp(state.radius / state.maxRadius, 0, 1)
		Bar.fill.Size = UDim2.fromScale(ratio, 1)
		Bar.label.Text = string.format("🌌 빅뱅할 수 있어요! (B)   최대 크기까지 ⚫ %s / %s", Config.formatSize(state.radius), Config.formatSize(state.maxRadius))
	else
		local ratio = math.clamp(state.radius / Config.BIGBANG_RADIUS, 0, 1)
		Bar.fill.Size = UDim2.fromScale(ratio, 1)
		Bar.label.Text = string.format("모든 구역이 열렸어요! 빅뱅까지 ⚫ %s / %d", Config.formatSize(state.radius), Config.BIGBANG_RADIUS)
	end
	menuButtons.test.Visible = state.tester == true
	menuButtons.bbshop.Visible = state.bigbang > 0 or state.dm > 0
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
	-- 로비에서는 블랙홀을 작게 보여 주니 카메라도 가깝게
	local cr = (state and state.inLobby) and math.min(r, 8) or r
	player.CameraMaxZoomDistance = math.max(60, 40 + cr * 6)
	player.CameraMinZoomDistance = math.min(10 + cr * 1.6, player.CameraMaxZoomDistance - 5)
	local zones = workspace:FindFirstChild("Zones")
	if not zones then
		return
	end
	for _, g in ipairs(zones:GetChildren()) do
		if g.Name == "Gate" and g:IsA("BasePart") then
			local need = g:GetAttribute("Need")
			local open = type(need) == "number" and r >= need
			g.CanCollide = not open
			if open then
				g.Color = Color3.fromRGB(90, 230, 150)
			end
			g.Transparency = open and 0.6 or 0.2
		end
	end
end

-- 세계마다 하늘 빛깔
local function applyWorld(w: number)
	currentWorld = w
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		local col = w == 2 and Color3.fromRGB(255, 200, 235) or Color3.fromRGB(200, 210, 240)
		local decay = w == 2 and Color3.fromRGB(200, 120, 190) or Color3.fromRGB(120, 110, 160)
		TweenService:Create(atmo, TweenInfo.new(1.2), { Color = col, Decay = decay }):Play()
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
					Bar.hint.Text = string.format("🔒 %s: 크기 %s 필요", type(label) == "string" and label or "?", Config.formatSize(bestSize))
				else
					highlight.Enabled = false
					Bar.hint.Text = ""
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
		Position = UDim2.new(0.5, 0, 0, 128),
		Size = UDim2.new(0, 400, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 30,
		Font = Enum.Font.GothamBlack,
		TextColor3 = C.pink,
		TextStrokeTransparency = 0.2,
		Visible = false,
		Parent = gui,
	})
	local sc = new("UIScale", { Parent = label })
	local last = 0
	-- combo = 서버가 센 연속 흡수 수, bonus = 질량 보너스 비율
	function addCombo(combo: number, bonus: number)
		last = os.clock()
		if combo >= 5 then
			label.Visible = true
			label.Text = string.format("🔥 연속 흡수 x%d  (질량 +%d%%)", combo, math.floor(bonus * 100 + 0.5))
			label.TextColor3 = combo >= 50 and C.gold or (combo >= 20 and Color3.fromRGB(255, 150, 80) or C.pink)
			sc.Scale = uiScale * (1.25 + math.min(combo, 100) * 0.004)
			TweenService:Create(sc, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScale }):Play()
		end
	end
	RunService.Heartbeat:Connect(function()
		if label.Visible and os.clock() - last > Config.COMBO_WINDOW then
			label.Visible = false
		end
	end)
end

-- 타격감: 화면 번쩍임과 카메라 흔들림
local Feel = {} :: any
do
	local flash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 45, Active = false, Parent = gui })
	function Feel.flash(color: Color3, strength: number)
		flash.BackgroundColor3 = color
		flash.BackgroundTransparency = 1 - math.clamp(strength, 0, 0.6)
		TweenService:Create(flash, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	end
	local shakeAmp = 0
	local shaking = false
	function Feel.shake(amount: number)
		shakeAmp = math.max(shakeAmp, amount)
	end
	-- 흔들 때만 카메라를 건드린다
	RunService.RenderStepped:Connect(function(dt: number)
		if shakeAmp <= 0.01 and not shaking then
			return
		end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end
		if shakeAmp > 0.01 then
			shaking = true
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * 2, (math.random() - 0.5) * 2, (math.random() - 0.5) * 2) * shakeAmp
			shakeAmp *= math.exp(-dt * 12)
		else
			shaking = false
			shakeAmp = 0
			hum.CameraOffset = Vector3.zero
		end
	end)
end

-- 스킬 버튼 (오른쪽 아래, Q): 액티브 능력이 있는 스킨이면 누르고, 패시브면 설명만
local Skill = {} :: any
do
	local frame = new("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -310, 1, -60),
		Size = UDim2.new(0, 120, 0, 120),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	scaled(frame)
	Skill.button = button({ Size = UDim2.new(0, 100, 0, 100), Position = UDim2.new(0.5, -50, 0, 0), Text = "Q", TextSize = 30, BackgroundColor3 = C.accent, Parent = frame }, function()
		Request:FireServer("skill")
	end)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = Skill.button })
	Skill.stroke = new("UIStroke", { Color = C.gold, Thickness = 3, Parent = Skill.button })
	Skill.cover = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Parent = Skill.button }, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	Skill.label = text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 102), Size = UDim2.new(0, 220, 0, 20), TextSize = 14, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, Parent = frame })
end

-- 퀘스트 (왼쪽 위)
local questLabels: { TextLabel } = {}
do
	local box = new("Frame", { Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(0, 300, 0, 112), BackgroundColor3 = C.bg, BackgroundTransparency = 0.25, Parent = gui }, { corner(12), stroke(C.line, 1.5) })
	scaled(box)
	text({ Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -20, 0, 22), TextSize = 16, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, Text = "📋 퀘스트", Parent = box })
	for k = 1, 3 do
		questLabels[k] = text({ Position = UDim2.new(0, 10, 0, 4 + k * 26), Size = UDim2.new(1, -20, 0, 24), TextSize = 13, RichText = true, Parent = box })
	end
end

local function refreshQuests()
	if not state then
		return
	end
	for k = 1, 3 do
		local q = state.quests[k]
		local l = questLabels[k]
		if q then
			local def = Config.QUEST_BY_KIND[q.kind]
			local t = string.format(def.text, fmt(q.goal))
			local reward = def.reward == "dm" and "🌑" or "💠"
			l.Text = string.format('%s %s  <font color="#FFD25A">%s/%s</font>', reward, t, fmt(math.min(q.progress, q.goal)), fmt(q.goal))
		else
			l.Text = ""
		end
	end
end

local function refreshSkill()
	if not state then
		return
	end
	local skin = Config.SKIN_BY_ID[state.skin]
	local ab = skin and skin.ability
	if not ab then
		Skill.button.Visible = false
		Skill.label.Text = ""
		return
	end
	Skill.button.Visible = true
	local passed = os.clock() - stateAt
	if ab.kind == "active" then
		local cdLeft = math.max(0, (state.cdLeft or 0) - passed)
		local activeLeft = math.max(0, (state.activeLeft or 0) - passed)
		Skill.button.Text = activeLeft > 0 and string.format("%.0f", activeLeft) or (cdLeft > 0 and string.format("%d", math.ceil(cdLeft)) or "Q")
		Skill.button.BackgroundColor3 = activeLeft > 0 and C.green or (cdLeft > 0 and C.panel2 or skin.a)
		Skill.cover.Size = UDim2.fromScale(1, math.clamp(cdLeft / ab.cd, 0, 1))
		Skill.label.Text = "⚡ " .. ab.name
		Skill.stroke.Color = cdLeft > 0 and C.line or C.gold
	else
		Skill.button.Text = "✦"
		Skill.button.BackgroundColor3 = skin.a:Lerp(C.bg, 0.4)
		Skill.cover.Size = UDim2.fromScale(1, 0)
		Skill.label.Text = "✦ " .. ab.name .. " (늘 켜짐)"
		Skill.stroke.Color = C.line
	end
end

-- 큰 글자 배너
local function banner(title: string, sub: string, color: Color3)
	local frame = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.32, 0),
		Size = UDim2.new(0, 700, 0, 110),
		BackgroundTransparency = 1,
		ZIndex = 15,
		Parent = gui,
	})
	local sc = new("UIScale", { Scale = uiScale * 1.5, Parent = frame })
	local t = text({ Size = UDim2.new(1, 0, 0, 64), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 52, Font = Enum.Font.GothamBlack, TextColor3 = color, TextStrokeTransparency = 0, Text = title, Parent = frame })
	local s = text({ Position = UDim2.new(0, 0, 0, 66), Size = UDim2.new(1, 0, 0, 34), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 24, TextStrokeTransparency = 0.3, Text = sub, Parent = frame })
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScale }):Play()
	task.delay(2, function()
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
local handlers: { [string]: (any) -> () } = {}

local lastInLobby = nil
function handlers.state(data: any)
	local grew = state ~= nil and data.radius > lastRadius * 1.05 and not data.inLobby
	state = data
	stateAt = os.clock()
	Fx.updateGallery(data.skins, data.skin)
	refreshQuests()
	refreshSkill()
	if data.inLobby ~= lastInLobby then
		lastInLobby = data.inLobby
		lastRadius = -1
	end
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
end

local lastRing = 0
function handlers.eat(data: any)
	if state then
		state.mass = data.mass
		if data.radius and data.radius ~= state.radius then
			state.radius = data.radius
			state.pullRange = data.pullRange
			-- 카메라와 문은 조금씩 커질 때마다 맞춘다. 문이 열리는 크기를 넘었으면 바로
			local crossed = false
			for _, zone in ipairs(Config.Zones) do
				if zone.need > lastRadius and zone.need <= data.radius then
					crossed = true
				end
			end
			if crossed or math.abs(data.radius - lastRadius) > lastRadius * 0.02 then
				lastRadius = data.radius
				applyRadius(data.radius)
			end
			-- 10% 커질 때마다 빛 고리
			if data.radius > lastRing * 1.1 then
				lastRing = data.radius
				local c = myCenter()
				if c then
					Fx.ring(c, C.accent, data.radius * 1.5, data.radius * 3, 0.5)
				end
			end
		end
	end
	-- 타격감: 삼킨 자리에서 빛줄기가 빨려 들고, 블랙홀이 꿀꺽 부풀고, 큰 걸 먹으면 화면이 흔들린다
	local r = state and state.radius or 3
	local c = myCenter()
	local biggest = 0
	local anyGolden = false
	for i, e in ipairs(data.list) do
		biggest = math.max(biggest, e.size)
		if e.golden then
			anyGolden = true
		end
		if i <= 6 or (e.golden and i <= 12) then
			local col = e.golden and C.gold or Color3.fromHSV((os.clock() * 0.3 + i * 0.07) % 1, 0.5, 1)
			Fx.popup(e.pos + Vector3.new(0, e.size * 1.2 + 2, 0), (e.golden and "✨ +" or "+") .. fmt(e.mass), e.golden and C.gold or Color3.fromRGB(210, 170, 255), (e.golden and 28 or 20) + math.min(14, e.size))
			if c then
				Fx.streak(e.pos + Vector3.new(0, e.size * 0.6, 0), c + Vector3.new(0, 0.5, 0), col, math.clamp(e.size * 0.35, 0.3, r * 0.25))
			end
		end
	end
	local ratio = biggest / r
	local char = player.Character
	if char then
		Fx.pulse(char, math.clamp(0.04 + ratio * 0.18, 0.04, 0.25))
	end
	local combo = data.combo or 0
	Fx.sound("pop", 0.25 + ratio * 0.3, 1.3 + math.min(combo, 60) * 0.012 - ratio * 0.6 + math.random() * 0.08)
	if ratio > 0.5 or data.burst then
		Fx.sound("whoosh", 0.5, 0.55)
		Feel.shake(math.clamp(ratio * 0.6, 0.15, 0.9) * (data.burst and 2 or 1))
		if c then
			Fx.burst(c + Vector3.new(0, 1, 0), C.pink, 24, r * 2, math.max(0.4, r * 0.1))
			Fx.ring(c, C.pink, r * 1.2, r * 2.6, 0.4)
		end
		if ratio > 0.75 or data.burst then
			Feel.flash(Color3.fromRGB(255, 230, 255), data.burst and 0.45 or 0.22)
		end
	end
	if anyGolden then
		Fx.sound("slash", 0.6, 1.5)
		Feel.flash(C.gold, 0.25)
		if c then
			Fx.burst(c + Vector3.new(0, 2, 0), C.gold, 40, 20 + r, math.max(0.6, r * 0.12))
		end
	end
	addCombo(combo, data.comboBonus or 0)
	refreshAll()
end

function handlers.toast(data: any)
	toast(data)
end

function handlers.upgraded(data: any)
	if data.quiet then
		return
	end
	Fx.sound("pop", 0.5, 1.9)
	local c = myCenter()
	if c and state then
		Fx.burst(c + Vector3.new(0, 1, 0), C.gold, 25, 10 + state.radius, 0.6)
	end
end

function handlers.zone(data: any)
	local zone = Config.Zones[data]
	if zone then
		if zone.world ~= currentWorld then
			applyWorld(zone.world)
		end
		local n = table.find(Config.zonesOf(zone.world), data) or data
		banner(string.format("%d · %s", n, zone.name), zone.world == 2 and "달콤한 것들이 기다려요" or "더 큰 것들이 기다려요", zone.ground:Lerp(Color3.new(1, 1, 1), 0.4))
		Fx.sound("whoosh", 0.5, 0.8)
		refreshAll()
	end
end

function handlers.world(data: any)
	if data == 0 then
		banner("🏠 로비", "캡슐 뽑기 · 스킨 전시관 · 상점 · 매일 보상", Color3.fromRGB(120, 255, 200))
		Fx.sound("whoosh", 0.8, 0.5)
		return
	end
	local w = Config.Worlds[data]
	if w then
		applyWorld(data)
		banner(string.format("%s 세계 %d", data == 2 and "🍭" or "🌍", data), w.name, w.sky)
		Fx.sound("whoosh", 0.8, 0.5)
		refreshAll()
	end
end

function handlers.bigbang(data: any)
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
	local sub = string.format("빅뱅 %d회 · 🌑 암흑 물질 +%d", data.count, data.dm)
	if #data.skins > 0 then
		sub ..= " · 🎨 " .. table.concat(data.skins, ", ")
	end
	banner("🌌 BIG BANG", sub, C.pink)
	if data.world2 then
		task.delay(2.6, function()
			banner("🍭 세계 2 열림!", "과자 왕국 · 🗺 세계 창이나 소용돌이 문으로 가요", Color3.fromRGB(255, 160, 220))
		end)
	end
end

function handlers.bbBought(data: any)
	local b = Config.BB_BY_ID[data.id]
	Fx.sound("pop", 0.6, 1.2)
	if b then
		toast(string.format("%s %s Lv.%d!", b.icon, b.name, data.level))
	end
end

function handlers.hatched(data: any)
	window.Visible = false
	task.spawn(playHatch, data.capsule, data.results)
end

function handlers.gold(data: any)
	local def = Config.SAT_BY_ID[data.id]
	banner("✨ 황금 위성!", def and def.name or "", C.gold)
	Fx.sound("slash", 0.7, 1.3)
end

function handlers.unlock(data: any)
	if data.kind == "skin" then
		banner("🎨 새 스킨!", data.name, C.pink)
	else
		banner("🐉 " .. data.name, "비밀 위성 3종과 전용 스킨이 들어왔어요!", C.gold)
	end
	Fx.sound("whoosh", 0.8, 0.7)
end

function handlers.star(data: any)
	Fx.star(data.pos, data.life)
	toast("☄ 별똥별이 떨어졌어요! 삼키면 질량 2배")
end

function handlers.starGot(data: any)
	Fx.starGot(data.pos)
	banner("⭐ 질량 2배!", string.format("%d초 동안", math.floor(data.left)), C.gold)
end

-- 로비 기계를 누르면 창이 열린다
function handlers.open(data: any)
	if data.page == "capsule" or data.page == "store" or data.page == "skins" then
		if not (window.Visible and currentPage == data.page) then
			openPage(data.page)
		end
	end
end

function handlers.skill(data: any)
	local c = myCenter()
	local r = state and state.radius or 3
	Fx.sound("whoosh", 1, 1.3)
	Feel.flash(Color3.fromRGB(200, 230, 255), 0.25)
	if c then
		Fx.ring(c, C.gold, r * 1.5, r * (data.burst and 8 or 4), 0.6)
		Fx.pillar(c, C.gold, 120 + r, 6 + r * 0.2, 0.6)
	end
	banner("⚡ " .. data.name, data.dur > 0 and string.format("%d초 동안!", data.dur) or "한꺼번에 흡수!", C.gold)
end

function handlers.quest(data: any)
	banner("📋 퀘스트 완료!", data.text .. "  →  " .. data.reward, Color3.fromRGB(120, 255, 180))
	Fx.sound("slash", 0.6, 1.2)
end

function handlers.daily(data: any)
	banner("🎁 매일 보상!", string.format("연속 %d일 · 🌑 +%d · 💠 +%s", data.streak, data.dm, fmt(data.mass)), C.gold)
	Fx.sound("slash", 0.7, 1.1)
end

Push.OnClientEvent:Connect(function(kind: string, data: any)
	local f = handlers[kind]
	if f then
		f(data)
	end
end)

------------------------------------------------------------------------
-- 👑 VIP 채팅 태그
------------------------------------------------------------------------
pcall(function()
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local props = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		local who = source and Players:GetPlayerByUserId(source.UserId)
		if who and who:GetAttribute("VIP") then
			props.PrefixText = '<font color="#FFD750">[👑 VIP]</font> ' .. message.PrefixText
		end
		return props
	end
end)

------------------------------------------------------------------------
-- 시작
------------------------------------------------------------------------
Fx.start()
-- 내 블랙홀 캐릭터: 죽지 않게, 발소리 없이, 카메라가 따라가게
local function setupCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum and hum:IsA("Humanoid") then
		for _, st in ipairs({ Enum.HumanoidStateType.Dead, Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.PlatformStanding }) do
			pcall(function()
				hum:SetStateEnabled(st, false)
			end)
		end
		local cam = workspace.CurrentCamera
		if cam then
			cam.CameraSubject = hum
		end
	end
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if root then
		local function mute(d: Instance)
			if d:IsA("Sound") then
				d.Volume = 0
			end
		end
		for _, d in ipairs(root:GetDescendants()) do
			mute(d)
		end
		root.DescendantAdded:Connect(mute)
	end
	task.wait(0.3)
	if state then
		applyRadius(state.radius)
	end
end
if player.Character then
	task.spawn(setupCharacter, player.Character)
end
player.CharacterAdded:Connect(function(c)
	setupCharacter(c :: Model)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	local key = input.KeyCode
	if key == Enum.KeyCode.B then
		openPage("bigbang")
	elseif key == Enum.KeyCode.M then
		openPage("zones")
	elseif key == Enum.KeyCode.P then
		openPage("sats")
	elseif key == Enum.KeyCode.G then
		openPage("store")
	elseif key == Enum.KeyCode.K then
		openPage("skins")
	elseif key == Enum.KeyCode.Q then
		Request:FireServer("skill")
	end
end)

-- 매 프레임: 부스트 시계, 미리보기 위성 돌리기, 세계 문 소용돌이
do
	local swirls: { BasePart } = {}
	task.spawn(function()
		local zones = workspace:WaitForChild("Zones")
		for _, d in ipairs(zones:GetChildren()) do
			if d:IsA("BasePart") and d:GetAttribute("Spin") then
				table.insert(swirls, d)
			end
		end
	end)
	local swirlBase: { [BasePart]: CFrame } = {}
	local lastBoost = ""
	local skillTick = 0
	local refreshAsked = 0
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		if skinPreview then
			skinPreview.active = window.Visible and currentPage == "skins"
		end
		if t > skillTick then
			skillTick = t + 0.2
			refreshSkill()
		end
		local bt, ended = boostText()
		if bt ~= lastBoost then
			lastBoost = bt
			HUD.boosts.Text = bt
		end
		if ended and t - refreshAsked > 3 then
			refreshAsked = t
			Request:FireServer("refresh")
		end
		if window.Visible or #spinning > 0 then
			for i = #spinning, 1, -1 do
				local s = spinning[i]
				if not s.vf.Parent then
					table.remove(spinning, i)
				elseif s.vf.Visible and s.model.PrimaryPart then
					s.model:PivotTo(CFrame.Angles(0, t * 0.9 + i, 0))
				end
			end
		end
		for _, p in ipairs(swirls) do
			local base = swirlBase[p]
			if not base then
				base = p.CFrame
				swirlBase[p] = base
			end
			p.CFrame = base * CFrame.Angles(t * 2, 0, 0)
		end
	end)
end

-- 로블록스 메뉴의 "다시 시작(Reset)"을 누르면 죽는 대신 끼인 곳에서 빠져나온다
task.spawn(function()
	local resetEvent = Instance.new("BindableEvent")
	resetEvent.Event:Connect(function()
		Request:FireServer("unstuck")
	end)
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", resetEvent)
		end)
		if ok then
			break
		end
		task.wait(1)
	end
end)

Request:FireServer("hello")
