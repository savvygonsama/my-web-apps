-- HoleClient (LocalScript, StarterPlayer > StarterPlayerScripts)
-- 화면 UI, 카메라, 문 통과, "너무 커요" 표시. 계산은 서버가 하고 여기서는 보여 주고 요청만 보낸다.
-- 창: 💎 상점, 🥚 캡슐, 🛰 위성, 🎨 스킨, 🌌 빅뱅, 🌑 빅뱅 상점, 🗺 세계, 📜 도움말, 🧪 테스트

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
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
		uiScale = math.clamp(math.min(vp.X / 1150, vp.Y / 640), 0.55, 1)
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
-- 오른쪽: 자동 업그레이드 + 업그레이드 카드 셋
------------------------------------------------------------------------
type Card = { level: TextLabel, effect: TextLabel, buy: TextButton, max: TextButton }
local cards: { [string]: Card } = {}
local autoButton: TextButton
do
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.52, 0),
		Size = UDim2.new(0, 262, 0, 3 * 122 + 50),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8) }) })
	scaled(panel)
	autoButton = button({ Size = UDim2.new(1, 0, 0, 42), Text = "🤖 자동 업그레이드: 끔", TextSize = 16, BackgroundColor3 = C.panel2, Parent = panel }, function()
		Request:FireServer("auto", not (state and state.auto))
	end)
	for _, u in ipairs(Config.Upgrades) do
		local card = new("Frame", { Size = UDim2.new(1, 0, 0, 114), BackgroundColor3 = Color3.new(1, 1, 1), Parent = panel }, { corner(14), stroke(C.line, 1.5), grad(C.panel2, C.bg) })
		text({ Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 22), TextSize = 18, Font = Enum.Font.GothamBlack, Text = u.icon .. " " .. u.name, Parent = card })
		local level = text({ Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 22), TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.gold, Parent = card })
		local effect = text({ Position = UDim2.new(0, 10, 0, 30), Size = UDim2.new(1, -20, 0, 36), TextSize = 14, TextColor3 = C.dim, TextYAlignment = Enum.TextYAlignment.Top, Parent = card })
		local buy = button({ Position = UDim2.new(0, 8, 1, -42), Size = UDim2.new(0.66, -10, 0, 34), TextSize = 15, Parent = card }, function()
			Request:FireServer("upgrade", u.id, false)
		end)
		local max = button({ Position = UDim2.new(0.66, 2, 1, -42), Size = UDim2.new(0.34, -10, 0, 34), Text = "최대", TextSize = 14, BackgroundColor3 = C.pink, Parent = card }, function()
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
	Size = UDim2.new(0, 720, 0, 520),
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
		Size = UDim2.new(0, 140, 0, 9 * 50),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { new("UIListLayout", { Padding = UDim.new(0, 6) }) })
	scaled(menu)
	for _, item in ipairs({
		{ "store", "💎 상점", Color3.fromRGB(230, 160, 40) },
		{ "capsule", "🥚 캡슐", Color3.fromRGB(70, 160, 230) },
		{ "sats", "🛰 위성", Color3.fromRGB(90, 110, 220) },
		{ "skins", "🎨 스킨", Color3.fromRGB(200, 90, 200) },
		{ "bigbang", "🌌 빅뱅", Color3.fromRGB(200, 70, 150) },
		{ "bbshop", "🌑 빅뱅 상점", Color3.fromRGB(70, 40, 120) },
		{ "zones", "🗺 세계", Color3.fromRGB(60, 150, 120) },
		{ "help", "📜 도움말", C.panel2 },
		{ "test", "🧪 테스트", Color3.fromRGB(120, 60, 180) },
	}) do
		menuButtons[item[1]] = button({ Size = UDim2.new(1, 0, 0, 44), Text = item[2], TextSize = 17, BackgroundColor3 = item[3], Parent = menu }, function()
			openPage(item[1])
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
		local u = Config.UPGRADE_BY_ID.size
		local function packAmount(n: number): number
			local sum = 0
			for i = 0, n - 1 do
				sum += Config.upgradeCost("size", math.min(u.maxLevel - 1, state.size + i))
			end
			return sum
		end
		productDesc.massS.Text = Config.PRODUCT_BY_KEY.massS.desc .. "\n지금 사면 💠" .. fmt(packAmount(3))
		productDesc.massL.Text = Config.PRODUCT_BY_KEY.massL.desc .. "\n지금 사면 💠" .. fmt(packAmount(10))
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
	refreshers.capsule = function()
		if not state then
			return
		end
		info.Text = string.format("위성 가방 %d / %d  ·  🍀 행운 ×%.2f", #state.sats, Config.SAT_INVENTORY, (1 + 0.15 * (state.bb.luck or 0)) * (state.passes.luck and 2 or 1))
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
do
	local page = makePage("skins")
	local scroll = scroller(page, UDim2.fromScale(1, 1))
	new("UIGridLayout", { CellSize = UDim2.new(0.25, -8, 0, 176), CellPadding = UDim2.new(0, 8, 0, 8), Parent = scroll })
	local skinButtons: { [string]: TextButton } = {}
	for _, skin in ipairs(Config.Skins) do
		local card = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Parent = scroll }, { corner(12), stroke(skin.a, 1.5), grad(C.panel2, C.bg) })
		local swatch = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.new(0, 72, 0, 72), BackgroundColor3 = Color3.new(1, 1, 1), Parent = card }, {
			corner(36),
			new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, skin.a), ColorSequenceKeypoint.new(0.5, Color3.new(0, 0, 0)), ColorSequenceKeypoint.new(1, skin.b) }), Rotation = 45 }),
			new("UIStroke", { Color = skin.a, Thickness = 3 }),
		})
		if skin.effect then
			text({ Size = UDim2.fromScale(1, 1), TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center, Text = EFFECT_ICON[skin.effect] or "", Parent = swatch })
		end
		text({ Position = UDim2.new(0, 4, 0, 84), Size = UDim2.new(1, -8, 0, 40), TextSize = 16, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, Text = skin.name, Parent = card })
		skinButtons[skin.id] = button({ Position = UDim2.new(0, 6, 1, -44), Size = UDim2.new(1, -12, 0, 38), TextSize = 14, Parent = card }, function()
			Request:FireServer("skin", skin.id)
		end)
	end
	refreshers.skins = function()
		if not state then
			return
		end
		for _, skin in ipairs(Config.Skins) do
			local b = skinButtons[skin.id]
			local owned = table.find(state.skins, skin.id) ~= nil
			if state.skin == skin.id then
				b.Text = "사용 중 ✔"
				b.BackgroundColor3 = C.green
			elseif owned then
				b.Text = "사용하기"
				b.BackgroundColor3 = C.accent
			elseif skin.unlock == "bigbang" then
				b.Text = string.format("🔒 빅뱅 %d번", skin.value)
				b.BackgroundColor3 = C.panel2
			elseif skin.unlock == "dm" then
				b.Text = string.format("🌑 %d 로 사기", skin.value)
				b.BackgroundColor3 = state.dm >= skin.value and Color3.fromRGB(110, 60, 180) or C.panel2
			elseif skin.unlock == "world2" then
				b.Text = "🔒 사탕 태양 삼키기"
				b.BackgroundColor3 = C.panel2
			else
				b.Text = "💎 " .. Config.PASS_BY_KEY[skin.value].name
				b.BackgroundColor3 = Color3.fromRGB(200, 140, 40)
			end
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
		local ready = state.size >= Config.BIGBANG_LEVEL
		local reward = Config.darkMatterReward(math.max(state.size, Config.BIGBANG_LEVEL), state.bigbang)
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
			string.format('• <font color="#C8A0FF">🌑 암흑 물질 +%d개</font> (크기 레벨이 높을수록 더 많이)', reward),
			"• 🌑 빅뱅 상점에서 영원히 남는 업그레이드를 살 수 있어요",
			state.bigbang == 0 and '• <font color="#FF9AD5">🍭 세계 2 「과자 왕국」이 열려요!</font>' or "",
			nextSkin and string.format("• 다음 스킨: %s (빅뱅 %d번)", nextSkin.name, nextSkin.value) or "",
			"",
			string.format("지금 빅뱅 %d회  ·  🌑 %d개", state.bigbang, state.dm),
			string.format('조건: 크기 레벨 %d (⚫%s) 이상  ·  지금 레벨 <font color="#%s">%d</font>', Config.BIGBANG_LEVEL, Config.formatSize(Config.radius(Config.BIGBANG_LEVEL)), ready and "6CFF9A" or "FF7A8A", state.size),
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
			"• 이동: WASD 또는 화면 조이스틱",
			"• 단축키: B 빅뱅 · M 세계 · P 위성 · G 상점",
			"",
			"<b>커지기</b>",
			"• 삼키면 💠질량이 쌓이고, 질량으로 오른쪽 업그레이드를 사요",
			"• ⚫ 크기: 레벨마다 13%씩 커져요 (괄호 안 숫자가 필요한 크기)",
			"• 🌀 흡입력: 반지름 바깥까지 끌어당겨요",
			"• 💠 질량 배율: 삼킬 때 얻는 질량 +25%",
			"• 🤖 자동 업그레이드를 켜면 알아서 사요",
			"• 너무 큰 물체는 빨간 테두리가 쳐지고, 아래에 필요한 크기가 떠요",
			"• 삼킨 물체는 몇 초 뒤 뿅 하고 다시 생겨요 (♻ 재생산)",
			"",
			"<b>⭐ 별똥별</b>",
			string.format("• 가끔 근처에 별똥별이 떨어져요. 삼키면 %d초 동안 질량 2배!", Config.STAR_BOOST),
			"",
			"<b>🛰 위성</b>",
			"• 🥚 캡슐을 깨면 위성이 나와요. 블랙홀 둘레를 돌며 질량 배율을 올려 줘요",
			string.format("• 같은 위성 %d개를 합치면 ✨황금 위성 (효과 %.1f배)", Config.GOLD_COUNT, Config.GOLD_POWER),
			"",
			"<b>🌌 빅뱅</b>",
			string.format("• 크기 레벨 %d이 되면 처음부터 다시 시작하는 대신 영구 배율이 오르고 🌑암흑 물질을 받아요", Config.BIGBANG_LEVEL),
			"• 🌑 빅뱅 상점: 시작 크기, 빠른 재생산, 질량, 속도, 흡입, 행운, 위성 칸",
			"• 첫 빅뱅을 하면 🍭 세계 2가 열려요 (시작 지점 왼쪽의 소용돌이 문)",
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
	for _, lv in ipairs({ 0, 10, 20, 30, 38, 46 }) do
		button({ Size = UDim2.new(1 / 6, -5, 1, 0), Text = "크기 Lv" .. lv, TextSize = 14, BackgroundColor3 = C.blue, Parent = row2 }, function()
			Request:FireServer("testSize", lv)
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
	button({ Size = UDim2.new(0.5, -3, 1, 0), Text = "↺ 처음으로", TextSize = 15, BackgroundColor3 = C.red, Parent = row4 }, function()
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
		"⚫ %s   🌀 +%s   ✖ %s%s%s",
		Config.formatSize(state.radius),
		Config.formatSize(state.pullRange),
		fmt(state.totalMult),
		state.bigbang > 0 and string.format("   🌌 %d", state.bigbang) or "",
		state.dm > 0 and string.format("   🌑 %d", state.dm) or ""
	)
	autoButton.Text = state.auto and "🤖 자동 업그레이드: 켬" or "🤖 자동 업그레이드: 끔"
	autoButton.BackgroundColor3 = state.auto and C.green or C.panel2
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
			nowText, nextText = Config.formatSize(Config.pullRange(r, level, state.bb.pull)), Config.formatSize(Config.pullRange(r, level + 1, state.bb.pull))
		else
			nowText, nextText = string.format("×%.2f", 1 + 0.25 * level), string.format("×%.2f", 1 + 0.25 * (level + 1))
		end
		card.effect.Text = maxed and (u.desc .. "\n지금 " .. nowText) or string.format("%s\n%s → %s", u.desc, nowText, nextText)
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
	if nextZone then
		local ratio = math.clamp((r - prevNeed) / math.max(nextZone.need - prevNeed, 0.01), 0, 1)
		Bar.fill.Size = UDim2.fromScale(ratio, 1)
		Bar.label.Text = string.format("다음 구역 '%s'까지  ⚫ %s / %d", nextZone.name, Config.formatSize(r), nextZone.need)
	elseif state.size >= Config.BIGBANG_LEVEL then
		Bar.fill.Size = UDim2.fromScale(1, 1)
		Bar.label.Text = "🌌 빅뱅할 수 있어요! (B)"
	else
		local ratio = math.clamp(state.size / Config.BIGBANG_LEVEL, 0, 1)
		Bar.fill.Size = UDim2.fromScale(ratio, 1)
		Bar.label.Text = string.format("모든 구역이 열렸어요! 빅뱅까지 크기 Lv %d / %d", state.size, Config.BIGBANG_LEVEL)
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

function handlers.state(data: any)
	local grew = state ~= nil and data.radius > lastRadius + 0.001
	state = data
	stateAt = os.clock()
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

function handlers.eat(data: any)
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
	local key = input.KeyCode
	if key == Enum.KeyCode.B then
		openPage("bigbang")
	elseif key == Enum.KeyCode.M then
		openPage("zones")
	elseif key == Enum.KeyCode.P then
		openPage("sats")
	elseif key == Enum.KeyCode.G then
		openPage("store")
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
	local refreshAsked = 0
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
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

Request:FireServer("hello")
