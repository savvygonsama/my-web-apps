-- 권왕: 화면 (체력·균형·내공 막대, 기술 칸, 창, 수련 놀이, 알림)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local UI = {}

local player = Players.LocalPlayer
local Request: RemoteEvent

local C = {
	bg = Color3.fromRGB(22, 16, 14),
	panel = Color3.fromRGB(40, 28, 24),
	panel2 = Color3.fromRGB(64, 44, 34),
	line = Color3.fromRGB(190, 150, 90),
	gold = Color3.fromRGB(255, 210, 120),
	text = Color3.fromRGB(250, 240, 225),
	dim = Color3.fromRGB(200, 185, 165),
	red = Color3.fromRGB(220, 60, 50),
	hp = Color3.fromRGB(215, 50, 45),
	posture = Color3.fromRGB(255, 180, 60),
	chi = Color3.fromRGB(80, 170, 255),
	green = Color3.fromRGB(90, 200, 120),
}
UI.C = C

local function new(class: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				(inst :: any)[k] = v
			end
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
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
local function text(props: { [string]: any }): TextLabel
	local base = { BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextColor3 = C.text, TextSize = 16, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left }
	for k, v in pairs(props) do
		base[k] = v
	end
	return new("TextLabel", base)
end
local function button(props: { [string]: any }, onClick: () -> ()): TextButton
	local base = { BackgroundColor3 = C.panel2, Font = Enum.Font.GothamBlack, TextColor3 = C.text, TextSize = 16, AutoButtonColor = true, Text = "" }
	for k, v in pairs(props) do
		base[k] = v
	end
	local b = new("TextButton", base, { corner(8) })
	b.Activated:Connect(onClick)
	return b
end
UI.new, UI.corner, UI.stroke, UI.text, UI.button = new, corner, stroke, text, button

local gui: ScreenGui
local uiScale = 1
local windowScale = 1

-- 화면 크기에 맞춘 확대. 게임 시작 직후엔 화면 크기가 1×1로 잡힐 때가 있어
-- (그때 재면 창이 안 보일 만큼 작아진다) 크기가 바뀔 때마다 다시 재고, 너무 작으면 무시한다
local scales: { { s: UIScale, kind: string } } = {}
local function scaleFor(kind: string): number
	if kind == "window" then
		return windowScale
	elseif kind == "map" then
		return math.min(uiScale * 0.9, windowScale)
	end
	return uiScale
end
local function scaled(parent: Instance, kind: string?): UIScale
	local k = kind or "ui"
	local sc = Instance.new("UIScale")
	sc.Scale = scaleFor(k)
	sc.Parent = parent
	table.insert(scales, { s = sc, kind = k })
	return sc
end
local function measure()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	if vp.X < 320 or vp.Y < 240 then
		vp = Vector2.new(1280, 720) -- 아직 화면이 안 잡혔다
	end
	uiScale = math.clamp(vp.Y / 720, 0.75, 1.7)
	windowScale = math.clamp(math.min(uiScale, vp.Y * 0.9 / 600, vp.X * 0.95 / 900), 0.5, 1.7)
	for _, e in ipairs(scales) do
		if e.s.Parent then
			e.s.Scale = scaleFor(e.kind)
		end
	end
end

------------------------------------------------------------------------
-- 알림과 큰 글자
------------------------------------------------------------------------
local toastBox: Frame
function UI.toast(msg: string)
	if not toastBox then
		return
	end
	local l = text({ Size = UDim2.new(1, 0, 0, 34), Text = msg, TextSize = 21, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, Parent = toastBox })
	task.delay(3, function()
		TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.delay(0.45, function()
			l:Destroy()
		end)
	end)
	local kids = toastBox:GetChildren()
	if #kids > 6 then
		for i = 1, #kids - 6 do
			if kids[i]:IsA("TextLabel") then
				kids[i]:Destroy()
			end
		end
	end
end

function UI.banner(title: string, sub: string?, color: Color3?)
	local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.3, 0), Size = UDim2.new(0, 760, 0, 110), BackgroundTransparency = 1, ZIndex = 20, Parent = gui })
	local sc = new("UIScale", { Scale = uiScale * 1.6, Parent = f })
	local t = text({ Size = UDim2.new(1, 0, 0, 64), Text = title, TextSize = 50, Font = Enum.Font.GothamBlack, TextColor3 = color or C.gold, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0, Parent = f })
	local s = text({ Position = UDim2.new(0, 0, 0, 66), Size = UDim2.new(1, 0, 0, 34), Text = sub or "", TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, Parent = f })
	TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = uiScale }):Play()
	task.delay(2.2, function()
		TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		TweenService:Create(s, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.delay(0.45, function()
			f:Destroy()
		end)
	end)
end

-- 화면 번쩍임
local flash: Frame
function UI.flash(color: Color3, strength: number)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 1 - math.clamp(strength, 0, 0.7)
	TweenService:Create(flash, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
end

-- 오의: 위아래 검은 띠와 기술 이름
local bars: { Frame } = {}
function UI.cinematic(name: string, color: Color3, dur: number)
	for _, b in ipairs(bars) do
		TweenService:Create(b, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0.1, 0) }):Play()
	end
	UI.banner("오의 · " .. name, nil, color)
	task.delay(dur, function()
		for _, b in ipairs(bars) do
			TweenService:Create(b, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 0, 0) }):Play()
		end
	end)
end

------------------------------------------------------------------------
-- 내 막대 (아래 가운데)
------------------------------------------------------------------------
local HUD: any = {}

local function meter(parent: Instance, pos: UDim2, size: UDim2, color: Color3, label: string): (Frame, TextLabel)
	local back = new("Frame", { Position = pos, Size = size, BackgroundColor3 = Color3.fromRGB(20, 14, 12), BackgroundTransparency = 0.15, Parent = parent }, { corner(6), stroke(Color3.fromRGB(90, 70, 50), 1.2) })
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, Parent = back }, { corner(6) })
	local l = text({ Size = UDim2.fromScale(1, 1), Text = label, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4, ZIndex = 3, Parent = back })
	return fill, l
end

local function buildHud()
	local hud = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(0, 660, 0, 176), BackgroundTransparency = 1, Parent = gui })
	scaled(hud)
	HUD.style = text({ Size = UDim2.new(1, 0, 0, 28), TextSize = 22, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, Parent = hud })
	HUD.stacks = text({ Position = UDim2.new(0, 0, 0, 27), Size = UDim2.new(1, 0, 0, 22), TextSize = 18, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, Parent = hud })
	-- 균형: 가운데에서 양옆으로 차오른다 (꽉 차면 파훼)
	local pBack = new("Frame", { Position = UDim2.new(0.15, 0, 0, 54), Size = UDim2.new(0.7, 0, 0, 12), BackgroundColor3 = Color3.fromRGB(20, 14, 12), BackgroundTransparency = 0.3, Parent = hud }, { corner(5) })
	HUD.posture = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.posture, Parent = pBack }, { corner(5) })
	HUD.hp, HUD.hpText = meter(hud, UDim2.new(0, 0, 0, 72), UDim2.new(1, 0, 0, 26), C.hp, "")
	HUD.chi, HUD.chiText = meter(hud, UDim2.new(0.15, 0, 0, 102), UDim2.new(0.7, 0, 0, 16), C.chi, "")
	-- 기술 칸
	local row = new("Frame", { Position = UDim2.new(0, 0, 0, 124), Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Parent = hud }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6) }),
	})
	HUD.slots = {}
	for _, s in ipairs({ { "M1", "클릭" }, { "H", "Z 강타" }, { "E", "E" }, { "R", "R" }, { "G", "G 오의" }, { "Q", "Q 대시" }, { "F", "F 막기" }, { "P", "H 약" } }) do
		local cell = new("Frame", { Size = UDim2.new(0, 76, 1, 0), BackgroundColor3 = C.panel, BackgroundTransparency = 0.15, Parent = row }, { corner(8), stroke(C.line, 1) })
		local name = text({ Size = UDim2.new(1, -4, 0.62, 0), Position = UDim2.new(0, 2, 0, 0), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Parent = cell })
		local key = text({ Position = UDim2.new(0, 0, 0.6, 0), Size = UDim2.new(1, 0, 0.4, 0), Text = s[2], TextSize = 12, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Center, Parent = cell })
		local cd = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, ZIndex = 4, Parent = cell }, { corner(8) })
		local _ = key
		HUD.slots[s[1]] = { cell = cell, name = name, cd = cd }
	end
end

-- 매 순간 내 막대
function UI.bars(hp: number, maxHp: number, posture: number, postureMax: number, chi: number)
	if not HUD.hp then
		return
	end
	HUD.hp.Size = UDim2.fromScale(math.clamp(hp / math.max(1, maxHp), 0, 1), 1)
	HUD.hpText.Text = string.format("❤ %d / %d", math.floor(hp), maxHp)
	local pr = math.clamp(posture / math.max(1, postureMax), 0, 1)
	HUD.posture.Size = UDim2.fromScale(pr, 1)
	HUD.posture.BackgroundColor3 = pr > 0.75 and C.red or C.posture
	HUD.chi.Size = UDim2.fromScale(math.clamp(chi / Config.CHI_MAX, 0, 1), 1)
	HUD.chiText.Text = string.format("🌀 내공 %d", math.floor(chi))
end

-- 기술 칸 (이름, 잠김, 대기 시간 비율)
function UI.slots(info: { [string]: { name: string, locked: boolean?, cd: number? } })
	if not HUD.slots then
		return
	end
	for key, s in pairs(HUD.slots) do
		local i = info[key]
		if i then
			s.name.Text = (i.locked and "🔒 " or "") .. i.name
			s.name.TextColor3 = i.locked and C.dim or C.text
			s.cd.Size = UDim2.fromScale(1, math.clamp(i.cd or 0, 0, 1))
		end
	end
end

function UI.styleLine(t: string, color: Color3, stacks: string)
	if HUD.style then
		HUD.style.Text = t
		HUD.style.TextColor3 = color
		HUD.stacks.Text = stacks
	end
end

------------------------------------------------------------------------
-- 보스 막대 (위 가운데)
------------------------------------------------------------------------
local bossFrame: Frame
local bossFill: Frame
local bossPosture: Frame
local bossName: TextLabel
local bossModel: Model? = nil
function UI.setBoss(model: Model?)
	bossModel = model
	bossFrame.Visible = model ~= nil
	if model then
		local label = model:GetAttribute("Label")
		bossName.Text = "👹 " .. (type(label) == "string" and label or "보스")
	end
end

------------------------------------------------------------------------
-- 적 머리 위 이름표 (이름, 체력, 균형)
------------------------------------------------------------------------
function UI.enemyTag(model: Model)
	local head = model:WaitForChild("Head", 5)
	if not head or not head:IsA("BasePart") or head:FindFirstChild("EnemyTag") then
		return
	end
	local isBoss = model:GetAttribute("Boss") == true
	local w = isBoss and 300 or 230
	local bb = new("BillboardGui", { Name = "EnemyTag", Size = UDim2.new(0, w, 0, 76), StudsOffset = Vector3.new(0, 3.2, 0), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = isBoss and 200 or 130, Parent = head })
	local label = model:GetAttribute("Label")
	local lv = model:GetAttribute("Level")
	local lvText = type(lv) == "number" and string.format("Lv.%d ", lv) or ""
	local name = text({ Size = UDim2.new(1, 0, 0, 26), Text = (isBoss and "👹 " or "⚔ ") .. lvText .. (type(label) == "string" and label or "적"), TextSize = isBoss and 23 or 20, Font = Enum.Font.GothamBlack, TextColor3 = isBoss and C.gold or (type(lv) == "number" and lv >= 7 and Color3.fromRGB(255, 110, 90) or Color3.fromRGB(255, 200, 190)), TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.1, Parent = bb })
	local _ = name
	local back = new("Frame", { Position = UDim2.new(0, 0, 0, 29), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = Color3.fromRGB(20, 10, 10), Parent = bb }, { corner(4), stroke(Color3.fromRGB(0, 0, 0), 1) })
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.hp, Parent = back }, { corner(4) })
	local pback = new("Frame", { Position = UDim2.new(0.15, 0, 0, 45), Size = UDim2.new(0.7, 0, 0, 7), BackgroundColor3 = Color3.fromRGB(20, 10, 10), BackgroundTransparency = 0.3, Parent = bb }, { corner(3) })
	local pfill = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.posture, Parent = pback }, { corner(3) })
	-- 전투력 견주기: 차이가 크면 그 적의 공격은 나에게 통하지 않는다
	local powerLabel = text({ Position = UDim2.new(0, 0, 0, 55), Size = UDim2.new(1, 0, 0, 20), TextSize = 15, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.2, Parent = bb })
	local function refreshPower()
		local ep = model:GetAttribute("Power")
		local char = player.Character
		local mp = char and char:GetAttribute("Power")
		if type(ep) ~= "number" then
			powerLabel.Text = ""
			return
		end
		local tagText, col = "", Color3.fromRGB(230, 220, 200)
		if type(mp) == "number" then
			local r = mp / math.max(1, ep)
			local G = Config.POWER_GAP
			if r >= G.immune then
				tagText, col = " · 호신강기 (통하지 않음)", Color3.fromRGB(150, 150, 150)
			elseif r >= G.steady then
				tagText, col = " · 한참 약함", Color3.fromRGB(170, 200, 170)
			elseif r >= G.soft then
				tagText, col = " · 약함", Color3.fromRGB(180, 230, 180)
			elseif r >= 0.8 then
				tagText, col = " · 비슷", Color3.fromRGB(255, 230, 160)
			elseif r >= 0.5 then
				tagText, col = " · 강함", Color3.fromRGB(255, 150, 100)
			else
				tagText, col = " · 아주 강함", Color3.fromRGB(255, 80, 70)
			end
		end
		powerLabel.Text = "⚔ 전투력 " .. Config.formatNumber(ep) .. tagText
		powerLabel.TextColor3 = col
	end
	refreshPower()
	model:GetAttributeChangedSignal("Power"):Connect(refreshPower)
	-- 내 전투력이 바뀌면 다시 견준다 (적이 사라지면 그만)
	task.spawn(function()
		while true do
			task.wait(2)
			if not model.Parent or not bb.Parent then
				break
			end
			if not pcall(refreshPower) then
				break
			end
		end
	end)
	local function refresh()
		local hp = model:GetAttribute("Hp")
		local mx = model:GetAttribute("MaxHp")
		local po = model:GetAttribute("Posture")
		local pm = model:GetAttribute("PostureMax")
		if type(hp) == "number" and type(mx) == "number" then
			fill.Size = UDim2.fromScale(math.clamp(hp / math.max(1, mx), 0, 1), 1)
		end
		if type(po) == "number" and type(pm) == "number" then
			local r = math.clamp(po / math.max(1, pm), 0, 1)
			pfill.Size = UDim2.fromScale(r, 1)
			pfill.BackgroundColor3 = r > 0.75 and C.red or C.posture
		end
		bb.Enabled = model:GetAttribute("Dead") ~= true
	end
	refresh()
	model:GetAttributeChangedSignal("Hp"):Connect(refresh)
	model:GetAttributeChangedSignal("Posture"):Connect(refresh)
	model:GetAttributeChangedSignal("Dead"):Connect(refresh)
end

------------------------------------------------------------------------
-- 창
------------------------------------------------------------------------
local window: Frame
local windowTitle: TextLabel
local pages: { [string]: Frame } = {}
local refreshers: { [string]: (boolean?) -> () } = {}
local current = ""
local state: any = nil
local TITLES = { styles = "🥋 권법", stats = "📊 능력치와 경지", shop = "🧪 만물상", help = "📜 도움말", test = "🧪 테스트" }

local function makePage(name: string): Frame
	local f = new("Frame", { Position = UDim2.new(0, 16, 0, 56), Size = UDim2.new(1, -32, 1, -68), BackgroundTransparency = 1, Visible = false, Parent = window })
	pages[name] = f
	return f
end

local function scroller(parent: Instance, size: UDim2, pos: UDim2?): ScrollingFrame
	return new("ScrollingFrame", { Position = pos or UDim2.new(), Size = size, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = C.line, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = parent })
end

local pageOpt: any = nil
function UI.openPage(name: string, opt: any?)
	pageOpt = opt
	if window.Visible and current == name and not opt then
		window.Visible = false
		return
	end
	current = name
	for n, f in pairs(pages) do
		f.Visible = n == name
	end
	windowTitle.Text = TITLES[name] or name
	window.Visible = true
	local r = refreshers[name]
	if r then
		r(true)
	end
end

function UI.closeWindow()
	window.Visible = false
end

function UI.windowOpen(): boolean
	return window.Visible
end

-- 내 몸이 지금 어디 있나
local function myPos(): Vector3?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return (root and root:IsA("BasePart")) and root.Position or nil
end

-- 여기서 그곳까지 방향 (북 = -Z)과 거리
local DIRS = { "북", "북동", "동", "남동", "남", "남서", "서", "북서" }
local function bearing(from: Vector3, to: Vector3): (string, number)
	local d = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local ang = math.deg(math.atan2(d.X, -d.Z)) % 360
	return DIRS[math.floor((ang + 22.5) / 45) % 8 + 1], d.Magnitude
end
UI.bearing = bearing

local function nearMaster(id: string): boolean
	local m = Config.MASTERS[id]
	local pos = myPos()
	if not m or not pos then
		return false
	end
	return Vector3.new(pos.X - m.at.X, 0, pos.Z - m.at.Z).Magnitude <= Config.MASTER_RANGE
end

local function buildStyles()
	local page = makePage("styles")
	local list = scroller(page, UDim2.new(0.4, -8, 1, 0))
	new("UIListLayout", { Padding = UDim.new(0, 6), Parent = list })
	local detail = new("Frame", { Position = UDim2.new(0.4, 4, 0, 0), Size = UDim2.new(0.6, -4, 1, 0), BackgroundColor3 = C.panel, Parent = page }, { corner(12), stroke(C.line, 1.5) })
	local dTitle = text({ Position = UDim2.new(0, 14, 0, 8), Size = UDim2.new(1, -28, 0, 36), TextSize = 28, Font = Enum.Font.GothamBlack, Parent = detail })
	local dHanja = text({ Position = UDim2.new(0, 14, 0, 44), Size = UDim2.new(1, -28, 0, 22), TextSize = 17, TextColor3 = C.dim, Parent = detail })
	local dMaster = text({ Position = UDim2.new(0, 14, 0, 68), Size = UDim2.new(1, -28, 0, 24), TextSize = 17, TextColor3 = C.gold, RichText = true, Parent = detail })
	local bodyScroll = scroller(detail, UDim2.new(1, -20, 1, -170), UDim2.new(0, 14, 0, 96))
	local dBody = text({ Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 17, RichText = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = bodyScroll })
	local selected = Config.Styles[1].id
	local action = "learn"
	local dBtn = button({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -12), Size = UDim2.new(0.62, -20, 0, 56), TextSize = 21, BackgroundColor3 = C.red, Parent = detail }, function()
		if action == "learn" then
			Request:FireServer("learn", selected)
		elseif action == "break" then
			Request:FireServer("breakthrough", selected)
		elseif action == "guide" then
			UI.setGuide(selected)
			window.Visible = false
		end
	end)
	local guideBtn = button({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -12), Size = UDim2.new(0.38, -14, 0, 56), Text = "📍 길 안내", TextSize = 20, BackgroundColor3 = C.panel2, Parent = detail }, function()
		if state and state.found and state.found[selected] then
			UI.setGuide(selected)
			window.Visible = false
		end
	end)
	local cards: { [string]: TextButton } = {}
	local function show(id: string)
		selected = id
		local s = Config.STYLE_BY_ID[id]
		local owned = state and table.find(state.styles, id) ~= nil
		local found = state and state.found and state.found[id]
		local passed = state and state.trials and state.trials[id]
		local ups = (state and state.gradeUp and state.gradeUp[id]) or 0
		local gradeNow = Config.styleGrade(s, ups)
		local gradeColor = Config.GRADE_COLOR[gradeNow] or C.dim
		local gradeTag = string.format('<font color="#%02X%02X%02X">[%s%s]</font>', math.floor(gradeColor.R * 255), math.floor(gradeColor.G * 255), math.floor(gradeColor.B * 255), gradeNow, ups > 0 and string.rep("⬆", ups) or "")
		for sid, card in pairs(cards) do
			local st = card:FindFirstChildOfClass("UIStroke")
			if st then
				st.Thickness = sid == id and 3 or 1
			end
		end
		guideBtn.Visible = found == true and not owned
		-- 숨은 권법은 얻기 전엔 이름도 모른다
		if s.hidden and not owned and not (s.secret and found) then
			dTitle.Text = "❓ 숨겨진 권법"
			dTitle.TextColor3 = C.dim
			dHanja.Text = "???"
			dMaster.Text = gradeTag .. "  전해지는 이야기만 남아 있다"
			dBody.Text = "🔒 " .. (s.unlockHint or "") .. (s.secret and "\n\n지도에 나오지 않는 숨은 사부가 있다." or "\n\n이 권법은 사부에게 배울 수 없다. 강호를 누비며 길을 찾아라.")
			dBtn.Text = "🔒 조건을 채워야 익힌다"
			dBtn.BackgroundColor3 = C.panel
			action = "none"
			return
		end
		dTitle.Text = s.icon .. " " .. s.name
		dTitle.TextColor3 = s.color
		dHanja.Text = s.hanja
		local master = Config.MASTERS[id]
		local pos = myPos()
		if master and not found and not owned then
			dMaster.Text = gradeTag .. '  <font color="#C8B8A0">❓ 사부의 행방을 모른다 · 소문: ' .. (master.rumor or "") .. "</font>"
		elseif master then
			local where = ""
			if pos then
				local dir, dist = bearing(pos, master.at)
				where = dist <= Config.MASTER_RANGE and "  ·  <b>바로 곁</b>" or string.format("  ·  %s쪽 %d칸", dir, math.floor(dist))
			end
			dMaster.Text = string.format("%s  📍 사부 %s · %s%s", gradeTag, master.name, master.region, where)
		else
			dMaster.Text = gradeTag .. (s.starter and "  청운 장로에게 받은 기본 권법" or "")
		end
		local lines = { s.desc, "", "<b>고유 장치</b>  " .. s.gimmick, "", "<b>연타 (클릭)</b>" }
		local names = {}
		for _, m in ipairs(s.combo) do
			table.insert(names, m.name)
		end
		table.insert(lines, table.concat(names, " → "))
		table.insert(lines, "<b>Z 강타</b>  " .. s.heavy.name)
		local m = state and state.mastery and state.mastery[id]
		local lv = m and m.lv or 0
		for _, slot in ipairs({ "E", "R", "G" }) do
			local sk = s.skills[slot]
			local need = Config.SKILL_UNLOCK[slot]
			local lockTxt = lv >= need and "" or string.format(' <font color="#AA9988">(숙련 %d)</font>', need)
			table.insert(lines, string.format("<b>%s %s</b>%s  %s", slot == "G" and "오의 G" or slot, sk.name, lockTxt, sk.desc))
		end
		-- 각성
		local A1, A2 = Config.AWAKEN[1], Config.AWAKEN[2]
		local function tag(need: number): string
			return lv >= need and ' <font color="#FFD25A">(열림)</font>' or string.format(' <font color="#AA9988">(숙련 %d)</font>', need)
		end
		table.insert(lines, "")
		table.insert(lines, string.format("<b>%s %s</b>%s  기술(Z·E·R·G) 피해 ×%.2f, 대기 -%d%%, 연타 다섯 번째 <b>%s</b> (상대를 하늘로 띄운다)", A1.mark, A1.name, tag(A1.lv), A1.dmg, math.floor((1 - A1.cd) * 100 + 0.5), s.finisher and s.finisher.name or ""))
		table.insert(lines, string.format("<b>%s %s</b>%s  모든 기술 ×%.2f, 대기 -%d%%, 그림자 메아리가 기술을 한 번 더 (절반 위력), 몸에 각성의 기운", A2.mark, A2.name, tag(A2.lv), A2.dmg, math.floor((1 - A2.cd) * 100 + 0.5)))
		if m then
			table.insert(lines, "")
			table.insert(lines, string.format("숙련도 %d / %d  (%d / %d)", m.lv, Config.MASTERY_MAX, math.floor(m.xp), m.need))
		end
		if master and not passed and not owned then
			table.insert(lines, "")
			table.insert(lines, '<font color="#FFB070"><b>사부의 시험</b>  사부의 분신과 겨뤄 이겨야 제자로 받아 준다. 마구 휘두르면 막히고 되받아친다.</font>')
		end
		if s.realmReq then
			table.insert(lines, "")
			table.insert(lines, string.format('<font color="#FFE8A0"><b>경지 제한</b>  %s에 올라야 사부가 시험을 허락한다</font>', Config.Realms[s.realmReq].name))
		end
		-- 승급 (깨달음)
		if owned then
			local step = Config.BREAKTHROUGH[ups + 1]
			table.insert(lines, "")
			if step then
				table.insert(lines, string.format("<b>⬆ 권법 승급 (%s)</b>  숙련 %d · %s 이상 · 💰 %s → [%s] (피해 ×%.2f → ×%.2f)", step.name, Config.MASTERY_MAX, Config.Realms[step.realm].name, Config.formatNumber(step.coins), Config.styleGrade(s, ups + 1), Config.GRADES[gradeNow], Config.GRADES[Config.styleGrade(s, ups + 1)]))
			else
				table.insert(lines, string.format("<b>⬆ 권법 승급</b>  모든 깨달음을 얻었다 [%s]", gradeNow))
			end
		end
		dBody.Text = table.concat(lines, "\n")
		local cost = state and state.learnCost or 0
		local canBreak = owned and Config.BREAKTHROUGH[ups + 1] ~= nil and lv >= Config.MASTERY_MAX
		if canBreak then
			local step = Config.BREAKTHROUGH[ups + 1]
			dBtn.Text = string.format("⬆ 승급  💰 %s", Config.formatNumber(step.coins))
			dBtn.BackgroundColor3 = (state and state.coins >= step.coins and state.realm >= step.realm) and Color3.fromRGB(200, 150, 40) or C.panel
			action = "break"
		elseif state and state.style == id then
			dBtn.Text = "✔ 쓰는 중"
			dBtn.BackgroundColor3 = C.green
			action = "none"
		elseif owned then
			dBtn.Text = "이 권법으로 바꾸기"
			dBtn.BackgroundColor3 = C.panel2
			action = "learn"
		elseif not master then
			dBtn.Text = "청운 장로에게 받는다"
			dBtn.BackgroundColor3 = C.panel
			action = "none"
		elseif not found then
			dBtn.Text = "❓ 먼저 사부를 찾아라"
			dBtn.BackgroundColor3 = C.panel
			action = "none"
		elseif not passed then
			local near = nearMaster(id)
			dBtn.Text = near and "⚔ 시험 받기" or "사부에게 가서 시험 받기"
			dBtn.BackgroundColor3 = near and C.red or Color3.fromRGB(150, 110, 50)
			action = near and "learn" or "guide"
		elseif nearMaster(id) then
			dBtn.Text = string.format("배우기  💰 %s", Config.formatNumber(cost))
			dBtn.BackgroundColor3 = (state and state.coins >= cost) and C.red or C.panel
			action = "learn"
		else
			dBtn.Text = string.format("사부에게 가기 (💰 %s)", Config.formatNumber(cost))
			dBtn.BackgroundColor3 = Color3.fromRGB(150, 110, 50)
			action = "guide"
		end
	end
	for _, s in ipairs(Config.Styles) do
		local card = button({ Size = UDim2.new(1, -10, 0, 64), BackgroundColor3 = C.panel2, Text = "", Parent = list }, function()
			show(s.id)
		end)
		new("UIStroke", { Color = s.color, Thickness = 1, Parent = card })
		text({ Name = "Title", Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -20, 0, 30), Text = s.hidden and "❓ 숨겨진 권법" or (s.icon .. " " .. s.name), TextSize = 20, Font = Enum.Font.GothamBlack, TextColor3 = s.hidden and C.dim or s.color, Parent = card })
		local sub = text({ Name = "Sub", Position = UDim2.new(0, 10, 0, 34), Size = UDim2.new(1, -20, 0, 24), TextSize = 15, TextColor3 = C.dim, Parent = card })
		sub.Text = s.hidden and "???" or s.hanja
		cards[s.id] = card
	end
	refreshers.styles = function(reset: boolean?)
		for id, card in pairs(cards) do
			local sub = card:FindFirstChild("Sub") :: TextLabel?
			if sub and state then
				local m = state.mastery and state.mastery[id]
				local s = Config.STYLE_BY_ID[id]
				local owned = table.find(state.styles, id) ~= nil
				local title = card:FindFirstChild("Title") :: TextLabel?
				local found = state.found and state.found[id]
				local ups = (state.gradeUp and state.gradeUp[id]) or 0
				if s.hidden and not owned and not (s.secret and found) then
					sub.Text = "[" .. s.grade .. "]  ???"
					if title then
						title.Text = "❓ 숨겨진 권법"
						title.TextColor3 = C.dim
					end
				else
					local mark = owned and "" or ((state.trials and state.trials[id]) and "  · 시험 통과" or ((state.found and state.found[id]) and "  · 사부 찾음" or (Config.MASTERS[id] and "  · ❓" or "")))
					sub.Text = "[" .. Config.styleGrade(s, ups) .. string.rep("⬆", ups) .. "] " .. s.hanja .. (m and string.format("  ·  숙련 %d", m.lv) or "") .. mark .. (state.style == id and "  ✔" or "")
					if title then
						title.Text = s.icon .. " " .. s.name
						title.TextColor3 = s.color
					end
				end
				sub.TextColor3 = Config.GRADE_COLOR[Config.styleGrade(s, ups)] or C.dim
			end
		end
		if reset then
			selected = pageOpt and pageOpt.style or (state and state.style ~= "" and state.style) or selected
		end
		show(selected)
	end
end

local function buildStats()
	local page = makePage("stats")
	local info = text({ Size = UDim2.new(1, 0, 1, 0), TextSize = 18, RichText = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = page })
	refreshers.stats = function()
		if not state then
			return
		end
		local lines = {}
		local idx = state.realm
		local realm = Config.Realms[idx]
		local nextRealm = Config.Realms[idx + 1]
		table.insert(lines, string.format("<b>경지: %s</b>  (능력치 합 %s%s)", realm.name, Config.formatNumber(state.total), nextRealm and string.format(" / 다음 %s는 %s", nextRealm.name, Config.formatNumber(nextRealm.need)) or ""))
		table.insert(lines, string.format("경지 배율 ×%.2f (사경까지 경지마다 ×1.22, 그 위로는 ×1.32씩 겹으로, 수련 효과 +25%%) · 경지는 열여섯 단계", Config.realmPower(idx)))
		table.insert(lines, "")
		for _, s in ipairs(Config.Stats) do
			local v = state.stats[s.id] or 0
			table.insert(lines, string.format("%s <b>%s %s</b>  — %s ×%.2f", s.icon, s.name, Config.formatNumber(v), s.desc, Config.statMult(v)))
		end
		table.insert(lines, "")
		table.insert(lines, "<b>수련하는 곳</b>")
		for _, t in pairs(Config.Training) do
			local stat = nil
			for _, s in ipairs(Config.Stats) do
				if s.id == t.stat then
					stat = s
				end
			end
			local need = t.realm and t.realm > 1 and string.format(' <font color="#FFD25A">[%s부터]</font>', Config.Realms[t.realm].name) or ""
			table.insert(lines, string.format("%s %s%s → %s  (%s)", t.icon, t.name, need, t.fight and "모든 능력치" or ((stat and stat.icon or "") .. " " .. (stat and stat.name or "")), t.desc))
		end
		table.insert(lines, "")
		table.insert(lines, string.format("💰 은자 %s   ⚔ 쓰러뜨린 적 %d   🏆 비무대 승리 %d   🧪 금창약 %d", Config.formatNumber(state.coins), state.kills, state.pvpWins, state.potions))
		if state.elixirLeft > 0 then
			table.insert(lines, string.format("💊 소환단: %d초 남음 (수련 2배)", state.elixirLeft))
		end
		info.Text = table.concat(lines, "\n")
	end
end

local function buildShop()
	local page = makePage("shop")
	local list = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = page }, { new("UIListLayout", { Padding = UDim.new(0, 8) }) })
	local labels = {}
	for _, item in ipairs(Config.Shop) do
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = C.panel2, Parent = list }, { corner(10), stroke(C.line, 1) })
		text({ Position = UDim2.new(0, 14, 0, 6), Size = UDim2.new(1, -200, 0, 28), Text = item.icon .. " " .. item.name, TextSize = 20, Font = Enum.Font.GothamBlack, Parent = row })
		text({ Position = UDim2.new(0, 14, 0, 36), Size = UDim2.new(1, -200, 0, 26), Text = item.desc, TextSize = 14, TextColor3 = C.dim, Parent = row })
		labels[item.id] = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 160, 0, 46), Text = "💰 " .. Config.formatNumber(item.cost), TextSize = 18, BackgroundColor3 = C.red, Parent = row }, function()
			Request:FireServer("buy", item.id)
		end)
	end
	refreshers.shop = function()
		for _, item in ipairs(Config.Shop) do
			local can = state and state.coins >= item.cost
			labels[item.id].BackgroundColor3 = can and C.red or C.panel
		end
	end
end

local function buildHelp()
	local page = makePage("help")
	local scroll = scroller(page, UDim2.fromScale(1, 1))
	text({
		Size = UDim2.new(1, -14, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 17,
		RichText = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = scroll,
		Text = table.concat({
			"<b>🥋 맨손 하나로 강호를 꺾어라</b>",
			"",
			"<b>조작</b>",
			"• 클릭: 연타 (네 번까지 이어진다) · Z: 강타 (강한 한 방) (천룡장은 누르고 있다 놓기)",
			"• E · R: 기술 · G: 오의 (내공 100) · Q: 대시 (잠깐 무적) · 공중에서 Space: 두 번 뛰기",
			"• F: 막기. <b>맞기 직전에 누르면 흘리기</b> — 피해 없이 흘려 내고 상대가 휘청인다",
			"• H: 금창약 · T(가까이): 사부·수련·상점 · Tab: 능력치 · M: 지도 · Shift: 달리기",
			"",
			"<b>연타는 박자</b>",
			"• 앞 동작이 끝나 갈 즈음 눌러야 이어진다. 딱 맞으면 <b>정타</b> (피해 +15%, 세 번 이으면 연속 정타 +30%)",
			"• 너무 일찍 마구 누르면 <b>흐트러진다</b>: 연타가 끊기고 적이 읽어서 막고 흘린다",
			"• 숙련 6 각성: 연타 다섯 번째 마무리가 상대를 하늘로 띄운다 → 두 번 뛰고 공중에서 클릭 = 공중 연격 (세 번)",
			"• 맞기 직전에 대시로 피하면 <b>간파</b>: 상대가 굳고, 곧바로 클릭하면 반격",
			"",
			"<b>몸놀림</b>",
			"• 대시 바로 뒤 클릭: <b>돌진 일격</b> · 공중에서 클릭: <b>낙하격</b> (내리꽂아 주변을 친다)",
			"• 흘리기 바로 뒤 클릭: <b>반격</b> (크게 아프고 균형을 많이 깎는다)",
			"• 뒤로 대시하면 공중제비, 옆으로 대시하면 구르기",
			"",
			"<b>합을 겨루는 법</b>",
			"• 🟧 균형 막대: 막을 때마다 차오른다. 꽉 차면 <b>파훼</b> — 무릎이 꺾여 큰 피해를 받는다",
			"• 흘리기를 당한 쪽도 균형이 크게 깎인다. 흘리고, 흘리고, 무너뜨려라",
			"• 서로 같은 순간에 치면 <b>격돌</b>: 주먹이 부딪혀 둘 다 튕겨 난다",
			"• 적의 무기가 반짝이면 곧 휘두른다 — 흘릴 때다",
			"• <b>붉게 빛나는 공격</b>은 막을 수 없다. 대시로 피해라",
			"",
			"<b>강해지기</b>",
			"• 수련: 바위 들기(근골) · 목인장(체력) · 폭포 명상(내공) · 대나무 경공(경공). 박자를 맞추면 2배",
			"• 능력치는 천천히 오른다 (로그). 오래 수련한 쪽이 조금 유리할 뿐, 흘리기를 잘하면 이긴다",
			"• 숙련도: 그 권법으로 맞힐수록 오른다. 숙련 3에 R, 5에 오의가 열린다",
			"• 경지: 능력치 합으로 삼류 → 이류 → 일류 → 절정 → 초절정 → 화경 → 현경 → 생사경",
			"",
			"<b>일곱 사부</b>",
			"• 첫 권법은 어디서든 공짜. 그다음 권법은 <b>그 사부를 찾아가</b> T를 누르고 배운다",
			"• 권법 창의 📍 길 안내를 누르면 화면과 지도에 길잡이가 뜬다. 하늘로 솟은 빛기둥이 사부의 자리",
			"• 태허호(남서) · 금강사(북동) · 매화원(북서) · 천룡봉(먼 동쪽) · 무영곡(먼 서쪽) · 뇌운 고원(남동) · 취선 주막(남쪽)",
			"",
			"<b>강호</b>",
			"• 청운 마을 (안전): 사부 안내판, 만물상, 비무대, 수련터",
			"• 남쪽 청운 들판: 무뢰배 (처음 싸워 보기 좋다)",
			"• 적은 마을에서 멀수록 세다 (Lv). 아주 먼 곳엔 철갑 무사·흑영 자객과 두목이 있다",
			"• 먼 북쪽 흑호채: 두목 흑호 · 먼 남동쪽 혈월곡 (핏빛 달 아래): 우두머리 혈랑",
			"• 서쪽 대나무 숲: 산적 도객, 창병 · 동쪽 비류 폭포 계곡: 산적, 쌍도 자객",
			"• 볼거리: 거신상 · 하늘 고리 · 옛 투기장 · 수정 들판 · 천년 고목",
			"• ⚔ 비무대: 올라선 사람끼리 1대1로 겨룬다",
		}, "\n"),
	})
end

local function buildTest()
	local page = makePage("test")
	local list = scroller(page, UDim2.fromScale(1, 1))
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local order = 0
	local function section(title: string, items: { any })
		order += 1
		text({ Size = UDim2.new(1, -12, 0, 26), Text = title, TextSize = 19, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, LayoutOrder = order, Parent = list })
		order += 1
		local rows = math.ceil(#items / 3)
		local grid = new("Frame", { Size = UDim2.new(1, -12, 0, rows * 52), BackgroundTransparency = 1, LayoutOrder = order, Parent = list })
		new("UIGridLayout", { CellSize = UDim2.new(0.333, -8, 0, 44), CellPadding = UDim2.new(0, 8, 0, 8), Parent = grid })
		for _, item in ipairs(items) do
			local b = button({ Text = item[1], TextSize = 16, BackgroundColor3 = item.color or C.panel2 }, function()
				-- 길잡이는 화면에서만 (숨은 사부 자리를 따라간다)
				if string.sub(item[2], 1, 6) == "guide:" then
					UI.setGuide(string.sub(item[2], 7))
					window.Visible = false
					return
				end
				Request:FireServer(item[2], item[3])
			end)
			b.Parent = grid
		end
	end
	section("기본", {
		{ "💰 은자 +5000", "testCoins", 5000 }, { "📊 능력치 +200", "testStats", 200 }, { "📈 능력치 +5000", "testStats", 5000 },
		{ "🥋 숙련 최대", "testMastery" }, { "🌀 내공 가득·쿨 없음", "testChi" }, { "❤ 회복", "testHeal" },
		{ "🌀 다음 사부에게", "testTp" }, { "📜 이야기 다음 장", "testStory" }, { "⚔ 사부 시험 모두 통과", "testTrial" },
		{ "↺ 처음으로", "testReset", color = C.red },
	})
	-- 권법 테스트: 어떤 권법이든 바로 (숙련 최대·내공 가득)
	local styleItems = {}
	for _, st in ipairs(Config.Styles) do
		table.insert(styleItems, { st.icon .. " " .. st.name .. " [" .. st.grade .. "]", "testStyle", st.id, color = st.color:Lerp(Color3.new(0, 0, 0), 0.55) })
	end
	section("🥋 권법 테스트 (바로 익혀 숙련 최대로)", styleItems)
	section("🔓 시크릿 테스트 (숨은 권법 얻는 길)", {
		{ "📖 비급 조각 +1", "testSecret", "fragment" }, { "🧭 다음 비급 조각으로", "testSecret", "fragmentTp" }, { "🌌 무극신권 얻기", "testSecret", "mugeuk" },
		{ "🩸 혈마신수 얻기", "testSecret", "hyeolma" }, { "🔒 숨은 권법 다시 잠그기", "testSecret", "lock" }, { "👹 혈마 부르기", "testBoss", "hyeolma" },
		{ "🧭 숨은 사부에게 가기", "testSecretMaster" }, { "📍 숨은 사부 길잡이", "guide:gaecheon" }, { "✨ 무극 경지로 (능력치)", "testStats", 40000 },
		{ "⬆ 지금 권법 승급 최대", "testBreak" }, { "👹 천마 부르기", "testBoss", "cheonma" }, { "🌠 개천신권 바로 쓰기", "testStyle", "gaecheon" },
	})
	section("적과 보스", {
		{ "👹 흑호", "testBoss", "heukho" }, { "👹 혈랑", "testBoss", "hyeolrang" }, { "👹 빙마", "testBoss", "bingma" },
		{ "🪵 무뢰배", "testEnemy", "thug" }, { "🗡 산적", "testEnemy", "bandit" }, { "🔱 창병", "testEnemy", "spearman" },
		{ "🪓 곤봉 산적", "testEnemy", "brute" }, { "🥷 쌍도 자객", "testEnemy", "assassin" }, { "🛡 철갑 무사", "testEnemy", "ironguard" },
		{ "🌑 흑영 자객", "testEnemy", "shadowblade" }, { "🩸 혈교도", "testEnemy", "cultist" }, { "🩸 혈교 장로", "testEnemy", "cultelder" },
		{ "🌀 균열 마물", "testEnemy", "riftling" }, { "🌌 허공 마인", "testEnemy", "voidwalker" }, { "🗿 석상 수호자", "testEnemy", "stonegolem" },
		{ "👁 천마 사도", "testEnemy", "apostle" },
	})
end

------------------------------------------------------------------------
-- 수련 놀이
------------------------------------------------------------------------
local trainFrame: Frame
local trainTitle: TextLabel
local trainHint: TextLabel
local trainArea: Frame
local trainConn: RBXScriptConnection? = nil
local trainPress: (() -> ())? = nil

function UI.trainPress()
	if trainPress then
		trainPress()
	end
end

function UI.trainStop()
	if trainConn then
		trainConn:Disconnect()
		trainConn = nil
	end
	trainPress = nil
	trainFrame.Visible = false
	for _, c in ipairs(trainArea:GetChildren()) do
		c:Destroy()
	end
end

-- 박자 놀이: getPhase()가 0~1, 1이 '지금!' 순간
local function rhythm(onGrade: (string) -> (), hard: boolean?, basePeriod: number?)
	local circle = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 60, 0, 60), BackgroundColor3 = C.gold, BackgroundTransparency = 0.2, Parent = trainArea }, { corner(999) })
	local target = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 70, 0, 70), BackgroundTransparency = 1, Parent = trainArea }, { corner(999), stroke(Color3.new(1, 1, 1), 3) })
	local _ = target
	local start = os.clock()
	local H = Config.HARD_TRAIN
	local period = (basePeriod or 1.4) * (hard and H.period / 1.4 or 1)
	return circle, function(): number
		local p = ((os.clock() - start) % period) / period
		return p
	end, function()
		local p = ((os.clock() - start) % period) / period
		-- 고리가 하얀 원에 겹칠 때 (p ≈ 1 또는 0)
		local off = math.min(p, 1 - p)
		local grade = off < (hard and H.perfect or 0.06) and "perfect" or (off < (hard and H.good or 0.14) and "good" or "miss")
		onGrade(grade)
	end
end

function UI.trainStart(kind: string, rings: { Vector3 }?, send: (string, number?) -> (), hard: boolean?)
	UI.trainStop()
	local info = Config.Training[kind]
	trainFrame.Visible = true
	trainTitle.Text = (hard and "🔥 강화 수련 · " or info.icon .. " ") .. info.name
	trainTitle.TextColor3 = hard and Color3.fromRGB(255, 120, 70) or C.gold
	trainHint.Text = info.desc .. (UserInputService.TouchEnabled and "  (화면 버튼)" or "  (Space 또는 클릭, 움직이면 끝)")
	if kind == "bamboo" then
		-- 다음 고리를 화살표로
		local arrow = text({ Size = UDim2.fromScale(1, 1), TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.fromRGB(190, 255, 150), Parent = trainArea })
		local idx = 1
		local list = rings or {}
		trainConn = RunService.RenderStepped:Connect(function()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local pos = list[idx]
			if not root or not root:IsA("BasePart") or not pos then
				return
			end
			local d = (root.Position - pos).Magnitude
			arrow.Text = string.format("🎋 고리 %d / %d  ·  %d칸", idx, #list, math.floor(d))
			if d < 7 then
				send("ring", idx)
				idx = idx % #list + 1
			end
		end)
		return
	end
	if kind == "mabo" then
		-- 마보 참장: 기울어지는 몸을 가운데(초록)에 붙잡아 둔다. 누르면 오른쪽, 가만두면 바람에 밀려 왼쪽
		local bar = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 300, 0, 26), BackgroundColor3 = Color3.fromRGB(60, 40, 35), Parent = trainArea }, { corner(8) })
		local zoneW = hard and 0.2 or 0.3
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(zoneW, 1), BackgroundColor3 = C.green, BackgroundTransparency = 0.25, Parent = bar }, { corner(8) })
		local needle = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 8, 1, 14), BackgroundColor3 = Color3.new(1, 1, 1), Parent = bar }, { corner(4) })
		local x, v, acc = 0.5, 0, 0
		trainPress = function()
			v += 0.55
		end
		trainConn = RunService.RenderStepped:Connect(function(dt: number)
			local t = os.clock()
			local gust = math.sin(t * 1.3) * 0.25 + math.sin(t * 2.9) * 0.18 * (hard and 1.6 or 1)
			v = v * (1 - dt * 2.2) + (-0.45 + gust) * dt * 2
			x = math.clamp(x + v * dt, 0, 1)
			needle.Position = UDim2.fromScale(x, 0.5)
			acc += dt
			if acc >= 1.2 then
				acc = 0
				local d = math.abs(x - 0.5)
				send(d < zoneW * 0.2 and "perfect" or (d < zoneW / 2 and "good" or "miss"))
			end
		end)
		return
	end
	local circle, phase, press = rhythm(function(grade)
		send(grade)
	end, hard, info.period)
	trainPress = press
	trainConn = RunService.RenderStepped:Connect(function()
		local p = phase()
		if kind == "waterfall" or kind == "breathing" then
			-- 숨: 커졌다 작아졌다, 가장 클 때가 '지금'
			local s = 20 + 50 * (0.5 - 0.5 * math.cos(p * math.pi * 2 + math.pi))
			circle.Size = UDim2.new(0, s, 0, s)
			circle.BackgroundColor3 = C.chi
		elseif kind == "dummy" or kind == "ironpalm" then
			-- 나무팔이 들어온다: 끝에서 번쩍
			local s = 70
			circle.Size = UDim2.new(0, s, 0, s)
			circle.BackgroundTransparency = 1 - p ^ 4
			circle.BackgroundColor3 = kind == "ironpalm" and Color3.fromRGB(255, 110, 40) or Color3.fromRGB(230, 160, 90)
		else
			-- 바위: 큰 고리가 줄어든다
			local s = 70 + 160 * (1 - p)
			circle.Size = UDim2.new(0, s, 0, s)
			circle.BackgroundColor3 = C.gold
			circle.BackgroundTransparency = 0.6
		end
	end)
end

function UI.trainResult(data: any)
	if not trainFrame.Visible then
		return
	end
	local stat = nil
	for _, s in ipairs(Config.Stats) do
		if s.id == data.stat then
			stat = s
		end
	end
	local word = data.grade == "perfect" and "완벽!" or (data.grade == "good" and "좋음" or (data.grade == "ring" and "통과!" or "놓침"))
	local color = data.grade == "perfect" and C.gold or (data.gain > 0 and C.text or C.red)
	local l = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.15), Size = UDim2.new(1, 0, 0, 30), Text = data.gain > 0 and string.format("%s  %s +%d", word, stat and (stat.icon .. " " .. stat.name) or "", data.gain) or word, TextSize = 22, Font = Enum.Font.GothamBlack, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.2, Parent = trainArea })
	TweenService:Create(l, TweenInfo.new(0.7), { Position = UDim2.fromScale(0.5, -0.1), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.75, function()
		l:Destroy()
	end)
end

------------------------------------------------------------------------
-- 쓰러졌을 때
------------------------------------------------------------------------
local koFrame: Frame
local koText: TextLabel
function UI.ko(on: boolean, secs: number?)
	koFrame.Visible = on
	if on then
		local left = secs or Config.RESPAWN_TIME
		task.spawn(function()
			while koFrame.Visible and left > 0 do
				koText.Text = string.format("쓰러졌다…  %d초 뒤 마을에서 다시 일어난다", math.ceil(left))
				task.wait(0.25)
				left -= 0.25
			end
		end)
	end
end

------------------------------------------------------------------------
-- 상태 받기
------------------------------------------------------------------------
local topInfo: TextLabel
function UI.setState(s: any)
	state = s
	local realm = Config.Realms[s.realm]
	topInfo.Text = string.format("[%s] ⚔ 전투력 %s   💰 %s   🧪 %d   ⚡ 기력 %d   💪%s ❤%s 🍃%s 🌀%s", realm.name, Config.formatNumber(s.power or 0), Config.formatNumber(s.coins), s.potions, s.stamina or 0, Config.formatNumber(s.stats.str), Config.formatNumber(s.stats.vit), Config.formatNumber(s.stats.agi), Config.formatNumber(s.stats.chi))
	topInfo.TextColor3 = realm.color
	local menu = gui:FindFirstChild("Menu", true)
	local testBtn = menu and menu:FindFirstChild("TestButton")
	if testBtn then
		testBtn.Visible = s.tester == true
	end
	if window.Visible and refreshers[current] then
		refreshers[current]()
	end
	if UI.refreshWorld then
		UI.refreshWorld(s)
	end
end

------------------------------------------------------------------------
-- 지도 (오른쪽 위, M으로 크게)와 길잡이
------------------------------------------------------------------------
local mapFrame: Frame
local mapInner: Frame
local mapMe: TextLabel
local mapGuide: Frame
local mapDots: { Frame } = {}
local mapBig = false
local guideStyle: string? = nil
local guidePart: Part? = nil
local guideLabel: TextLabel? = nil
local masterMarks: { [string]: { stroke: UIStroke, icon: TextLabel, color: Color3, glyph: string } } = {}
local beacons: { [string]: Part } = {}
local storyMark: Frame? = nil

local function mapUV(p: Vector3): UDim2
	local H = Config.WORLD_HALF
	return UDim2.fromScale(math.clamp((p.X + H) / (2 * H), 0, 1), math.clamp((p.Z + H) / (2 * H), 0, 1))
end

local MAP_SMALL = 250
local MAP_BIG = 600
local function placeMap()
	if mapBig then
		mapFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		mapFrame.Position = UDim2.fromScale(0.5, 0.5)
		mapFrame.Size = UDim2.new(0, MAP_BIG, 0, MAP_BIG)
	else
		mapFrame.AnchorPoint = Vector2.new(1, 0)
		mapFrame.Position = UDim2.new(1, -16, 0, 160)
		mapFrame.Size = UDim2.new(0, MAP_SMALL, 0, MAP_SMALL)
	end
	-- 휴대폰은 버튼과 겹치지 않게 작은 지도를 숨기고, 메뉴로 크게만 본다
	mapFrame.Visible = mapBig or not UserInputService.TouchEnabled
	for _, l in ipairs(mapInner:GetDescendants()) do
		if l:IsA("TextLabel") then
			local base = l:GetAttribute("MapText")
			if type(base) == "number" then
				l.TextSize = base * (mapBig and 1.6 or 1)
			end
			if l:GetAttribute("BigOnly") then
				l.Visible = mapBig
			end
		end
	end
end

function UI.toggleMap()
	mapBig = not mapBig
	placeMap()
end

local function buildMap()
	mapFrame = new("Frame", { Name = "Map", BackgroundColor3 = Color3.fromRGB(40, 50, 35), BackgroundTransparency = 0.1, ZIndex = 5, Parent = gui }, { corner(12), stroke(C.line, 2) })
	scaled(mapFrame, "map")
	mapInner = new("Frame", { Position = UDim2.new(0, 6, 0, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundColor3 = Color3.fromRGB(95, 125, 75), ClipsDescendants = true, ZIndex = 5, Parent = mapFrame }, { corner(8) })
	local H = Config.WORLD_HALF
	local function rect(center: Vector3, size: Vector3, color: Color3, z: number): Frame
		return new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = mapUV(center), Size = UDim2.fromScale(size.X / (2 * H), size.Z / (2 * H)), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z, Parent = mapInner })
	end
	local function label(at: Vector3, t: string, size: number, color: Color3, z: number, bigOnly: boolean?): TextLabel
		local l = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = mapUV(at), Size = UDim2.new(0, 160, 0, 24), Text = t, TextSize = size, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.2, TextWrapped = false, ZIndex = z, Parent = mapInner })
		l:SetAttribute("MapText", size)
		if bigOnly then
			l:SetAttribute("BigOnly", true)
		end
		return l
	end
	-- 길
	for _, road in ipairs(Config.Roads) do
		for i = 1, #road - 1 do
			local a, b = road[i], road[i + 1]
			local d = b - a
			new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = mapUV((a + b) / 2), Size = UDim2.new(d.Magnitude / (2 * H), 0, 0, 3), Rotation = math.deg(math.atan2(d.Z, d.X)), BackgroundColor3 = Color3.fromRGB(190, 165, 120), BorderSizePixel = 0, ZIndex = 6, Parent = mapInner })
		end
	end
	-- 지역과 사부
	for _, r in ipairs(Config.Regions) do
		if not r.noGround then
			local f = rect(r.center, r.size, r.ground, 6)
			f.BackgroundTransparency = 0.15
			local style = r.master and Config.STYLE_BY_ID[r.master]
			if style then
				-- 사부 자리는 찾기 전엔 물음표만
				local st = new("UIStroke", { Color = style.color, Thickness = 2, Enabled = false, Parent = f })
				local icon = label(r.masterAt, "❓", 16, Color3.fromRGB(220, 210, 190), 9)
				masterMarks[r.master] = { stroke = st, icon = icon, color = style.color, glyph = style.icon }
				label(r.masterAt + Vector3.new(0, 0, 80), r.name, 12, Color3.new(1, 1, 1), 9, true)
			elseif r.boss then
				label(r.boss.at, "👹", 15, C.red, 9)
				label(r.center + Vector3.new(0, 0, r.size.Z / 2 - 30), r.name, 12, Color3.new(1, 1, 1), 9, true)
			else
				label(r.center, r.name, 12, Color3.new(1, 1, 1), 9, r.id ~= "village")
			end
		end
	end
	-- 큰 볼거리
	for _, lm in ipairs(Config.Landmarks) do
		label(lm.at, lm.icon, 16, Color3.new(1, 1, 1), 8)
		label(lm.at + Vector3.new(0, 0, 70), lm.name, 12, Color3.fromRGB(230, 225, 210), 8, true)
	end
	-- 적 점 (가까운 것만)
	for i = 1, 50 do
		mapDots[i] = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 5, 0, 5), BackgroundColor3 = Color3.fromRGB(255, 60, 50), BorderSizePixel = 0, Visible = false, ZIndex = 10, Parent = mapInner }, { corner(99) })
	end
	mapGuide = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1, Visible = false, ZIndex = 11, Parent = mapInner }, { corner(99), stroke(Color3.fromRGB(255, 240, 120), 3) })
	storyMark = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 14, 0, 14), Rotation = 45, BackgroundColor3 = Color3.fromRGB(255, 170, 60), BorderSizePixel = 0, Visible = false, ZIndex = 11, Parent = mapInner }, { stroke(Color3.new(0, 0, 0), 1.5) })
	mapMe = text({ AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 20, 0, 20), Text = "▲", TextSize = 18, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0, TextWrapped = false, ZIndex = 12, Parent = mapInner })
	mapMe:SetAttribute("MapText", 18)
	text({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -6), Size = UDim2.new(0, 140, 0, 18), Text = "M: 지도 크게", TextSize = 14, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Right, TextStrokeTransparency = 0.2, ZIndex = 12, Parent = mapFrame })
	placeMap()
end

-- 길잡이: 화면에 사부 자리를 띄운다 (가까이 가면 꺼진다)
function UI.setGuide(styleId: string?)
	if guidePart then
		guidePart:Destroy()
	end
	guidePart = nil
	guideLabel = nil
	guideStyle = nil
	if mapGuide then
		mapGuide.Visible = false
	end
	local m = styleId and Config.MASTERS[styleId]
	local style = styleId and Config.STYLE_BY_ID[styleId]
	if not m or not style then
		return
	end
	guideStyle = styleId
	local p = Instance.new("Part")
	p.Name = "KwonGuide"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Position = m.at + Vector3.new(0, 12, 0)
	p.Parent = workspace
	local bb = new("BillboardGui", { Size = UDim2.new(0, 300, 0, 76), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 100000, Parent = p })
	guideLabel = text({ Size = UDim2.fromScale(1, 1), TextSize = 24, Font = Enum.Font.GothamBlack, TextColor3 = style.color, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0, Parent = bb })
	guidePart = p
	if mapGuide then
		mapGuide.Position = mapUV(m.at)
		mapGuide.Visible = true
	end
	UI.toast(string.format("📍 %s · %s에게 가세요 (하늘로 솟은 빛기둥)", m.region, m.name))
end

------------------------------------------------------------------------
-- 이야기: 지금 할 일 (왼쪽), 대화 창 (아래), 목표 표시, 사부 빛기둥, 땅마다 공기
------------------------------------------------------------------------
local storyBox: Frame
local storyTitle: TextLabel
local storyGoal: TextLabel
local storyPart: Part? = nil
local storyLabel: TextLabel? = nil
local storyAt: Vector3? = nil

local function countKeys(t: any): number
	local n = 0
	if type(t) == "table" then
		for _ in pairs(t) do
			n += 1
		end
	end
	return n
end

local function nameOf(id: string?): string
	if not id then
		return ""
	end
	local e = Config.Enemies[id] or Config.Bosses[id]
	return e and e.name or id
end

-- 목표 자리: 정해진 곳이 없으면 (시험·배우기) 가장 가까운 알맞은 사부
local function goalTarget(s: any, g: any): Vector3?
	if g.kind == "talk" then
		return Config.ELDER_AT
	end
	if g.at then
		return g.at
	end
	if g.kind == "trial" or g.kind == "learn" then
		local pos = myPos() or Vector3.zero
		local best, bestD = nil, math.huge
		for id, m in pairs(Config.MASTERS) do
			local ok = s.found and s.found[id] and not table.find(s.styles, id)
			if g.kind == "trial" then
				ok = ok and not (s.trials and s.trials[id])
			else
				ok = ok and s.trials and s.trials[id]
			end
			local d = (m.at - pos).Magnitude
			if ok and d < bestD then
				best, bestD = m.at, d
			end
		end
		return best
	end
	return nil
end

local function goalText(s: any, g: any): string
	local k = g.kind
	local prog = s.prog or 0
	if k == "talk" then
		return "청운 장로에게 말 걸기 (T)"
	elseif k == "kill" then
		return string.format("%s 쓰러뜨리기  %d / %d", nameOf(g.id), prog, g.n or 1)
	elseif k == "train" then
		return string.format("수련터에서 수련하기  %d / %d", prog, g.n or 1)
	elseif k == "found" then
		return string.format("소문을 따라 사부 찾기  %d / %d", countKeys(s.found), g.n or 1)
	elseif k == "trial" then
		return "사부 곁에서 T · 사부의 시험 통과하기"
	elseif k == "learn" then
		local want = g.id and Config.STYLE_BY_ID[g.id]
		if want then
			return want.icon .. " " .. want.name .. " 익히기 (숨은 사부)"
		end
		return string.format("사부에게 권법 배우기  %d / %d", #s.styles, g.n or 1)
	elseif k == "realm" then
		local r = Config.Realms[g.n]
		return string.format("%s의 경지에 오르기 (지금 %s)", r and r.name or "", Config.Realms[s.realm].name)
	elseif k == "boss" then
		return nameOf(g.id) .. " 쓰러뜨리기"
	elseif k == "fragment" then
		return string.format("비급 조각 찾기  %d / %d (지도에 없다)", countKeys(s.fragments), g.n or 1)
	end
	return "강호를 마음껏 누비기"
end

local function clearStoryPart()
	if storyPart then
		storyPart:Destroy()
	end
	storyPart = nil
	storyLabel = nil
end

local function refreshStory(s: any)
	local ch = Config.Story[s.story or 1]
	if not storyBox or not ch then
		return
	end
	storyTitle.Text = string.format("📜 %d장 · %s", s.story or 1, ch.title)
	storyGoal.Text = "▸ " .. goalText(s, ch.goal)
	local at = goalTarget(s, ch.goal)
	if at ~= storyAt then
		storyAt = at
		clearStoryPart()
		if at then
			local p = Instance.new("Part")
			p.Name = "KwonStoryMark"
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Transparency = 1
			p.Size = Vector3.new(1, 1, 1)
			p.Position = at + Vector3.new(0, 14, 0)
			p.Parent = workspace
			local bb = new("BillboardGui", { Size = UDim2.new(0, 260, 0, 64), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 100000, Parent = p })
			storyLabel = text({ Size = UDim2.fromScale(1, 1), TextSize = 20, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 190, 90), TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0, Parent = bb })
			storyPart = p
		end
	end
	if storyMark then
		storyMark.Visible = at ~= nil
		if at then
			storyMark.Position = mapUV(at)
		end
	end
end

local function storyTick(pos: Vector3)
	if storyAt and storyLabel and storyPart then
		local dir, dist = bearing(pos, storyAt)
		storyLabel.Text = string.format("📜 목표\n%s쪽 · %d칸", dir, math.floor(dist))
		storyLabel.Visible = dist > 18
	end
end

-- 찾은 사부만 지도에 나오고, 하늘로 빛기둥이 솟는다
local function refreshFound(s: any)
	for id, mk in pairs(masterMarks) do
		local found = (s.found and s.found[id]) or table.find(s.styles, id) ~= nil
		mk.stroke.Enabled = found
		mk.icon.Text = found and mk.glyph or "❓"
		mk.icon.TextColor3 = found and mk.color or Color3.fromRGB(220, 210, 190)
		local m = Config.MASTERS[id]
		if found and m and not beacons[id] then
			local b = Instance.new("Part")
			b.Name = "KwonBeacon"
			b.Anchored = true
			b.CanCollide = false
			b.CanQuery = false
			b.CanTouch = false
			b.CastShadow = false
			b.Shape = Enum.PartType.Cylinder
			b.Material = Enum.Material.Neon
			b.Color = mk.color
			b.Transparency = 0.55
			b.Size = Vector3.new(400, 5, 5)
			b.CFrame = CFrame.new(m.at + Vector3.new(0, 210, 0)) * CFrame.Angles(0, 0, math.rad(90))
			b.Parent = workspace
			beacons[id] = b
		end
	end
end

function UI.refreshWorld(s: any)
	refreshFound(s)
	refreshStory(s)
end

-- 대화 창: 글자가 한 자씩 흘러나온다
local dialogFrame: Frame
local dialogWho: TextLabel
local dialogTitle: TextLabel
local dialogText: TextLabel
local dialogAct: TextButton
local dialogTrial: string? = nil
local dialogSeq = 0
function UI.dialog(data: any)
	if not dialogFrame then
		return
	end
	dialogSeq += 1
	local seq = dialogSeq
	dialogWho.Text = data.who or ""
	dialogTitle.Text = data.title or ""
	dialogText.Text = data.text or ""
	dialogTrial = data.trial
	dialogAct.Visible = dialogTrial ~= nil
	dialogFrame.Visible = true
	local n = utf8.len(dialogText.Text) or 0
	pcall(function()
		dialogText.MaxVisibleGraphemes = 0
	end)
	task.spawn(function()
		for i = 1, n, 2 do
			if seq ~= dialogSeq then
				return
			end
			pcall(function()
				dialogText.MaxVisibleGraphemes = i
			end)
			task.wait(0.02)
		end
		pcall(function()
			dialogText.MaxVisibleGraphemes = -1
		end)
	end)
	task.delay(40, function()
		if seq == dialogSeq then
			dialogFrame.Visible = false
		end
	end)
end

function UI.dialogOpen(): boolean
	return dialogFrame ~= nil and dialogFrame.Visible
end

local function buildStory(topLeft: Frame)
	storyBox = new("Frame", { Name = "Story", Position = UDim2.new(0, 0, 0, 336), Size = UDim2.new(0, 400, 0, 74), BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, Parent = topLeft }, { corner(10), stroke(Color3.fromRGB(255, 190, 90), 1.5) })
	storyTitle = text({ Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 26), TextSize = 19, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 200, 110), Parent = storyBox })
	storyGoal = text({ Position = UDim2.new(0, 10, 0, 36), Size = UDim2.new(1, -20, 0, 30), TextSize = 16, TextColor3 = C.text, TextWrapped = true, Parent = storyBox })
	-- 대화 창
	dialogFrame = new("Frame", { Name = "Dialog", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.new(0, 820, 0, 200), BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, Visible = false, ZIndex = 20, Parent = gui }, { corner(14), stroke(C.line, 2.5) })
	scaled(dialogFrame)
	dialogWho = text({ Position = UDim2.new(0, 20, 0, 10), Size = UDim2.new(0.5, 0, 0, 28), TextSize = 22, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, ZIndex = 21, Parent = dialogFrame })
	dialogTitle = text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 12), Size = UDim2.new(0.5, -20, 0, 24), TextSize = 17, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 21, Parent = dialogFrame })
	dialogText = text({ Position = UDim2.new(0, 20, 0, 46), Size = UDim2.new(1, -40, 0, 92), TextSize = 19, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 21, Parent = dialogFrame })
	button({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -12), Size = UDim2.new(0, 140, 0, 42), Text = "알겠다", TextSize = 18, BackgroundColor3 = C.panel2, ZIndex = 21, Parent = dialogFrame }, function()
		dialogSeq += 1
		dialogFrame.Visible = false
	end)
	dialogAct = button({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -168, 1, -12), Size = UDim2.new(0, 180, 0, 42), Text = "⚔ 시험 받기", TextSize = 18, BackgroundColor3 = C.red, ZIndex = 21, Visible = false, Parent = dialogFrame }, function()
		if dialogTrial then
			Request:FireServer("learn", dialogTrial)
		end
		dialogSeq += 1
		dialogFrame.Visible = false
	end)
end

-- 땅마다 공기가 다르다 (안개 색과 짙기). 들어서면 이름과 적 수준을 알린다
local AMBIENT = {
	default = { d = 0.24, h = 1.1, c = Color3.fromRGB(240, 215, 190) },
	snow = { d = 0.4, h = 2, c = Color3.fromRGB(225, 235, 255) },
	swamp = { d = 0.5, h = 2.6, c = Color3.fromRGB(140, 170, 110) },
	badlands = { d = 0.32, h = 1.9, c = Color3.fromRGB(255, 185, 130) },
	coast = { d = 0.3, h = 1.6, c = Color3.fromRGB(200, 225, 245) },
	cult = { d = 0.45, h = 2.3, c = Color3.fromRGB(160, 45, 55) },
	rift = { d = 0.5, h = 2.4, c = Color3.fromRGB(110, 70, 190) },
}
local regionNow = ""
local function regionAt(pos: Vector3): any
	local best = nil
	for _, r in ipairs(Config.Regions) do
		if not r.noGround and math.abs(pos.X - r.center.X) <= r.size.X / 2 and math.abs(pos.Z - r.center.Z) <= r.size.Z / 2 then
			-- 작은 땅 (사부 자리 등) 을 먼저
			if not best or r.size.X * r.size.Z < best.size.X * best.size.Z then
				best = r
			end
		end
	end
	return best
end
local function ambientTick(pos: Vector3)
	local r = regionAt(pos)
	local id = r and r.id or "wild"
	if id ~= regionNow then
		regionNow = id
		if r then
			local lv = Config.enemyLevel(pos)
			UI.toast(string.format("📍 %s%s", r.name, r.safe and "  · 안전한 곳" or string.format("  · 적 수준 %d", lv)))
		end
	end
	local a = AMBIENT[r and r.ambient or "default"] or AMBIENT.default
	local atmo = game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
	if atmo then
		atmo.Density += (a.d - atmo.Density) * 0.08
		atmo.Haze += (a.h - atmo.Haze) * 0.08
		atmo.Color = atmo.Color:Lerp(a.c, 0.08)
	end
end

local mapAcc = 0
local function updateMap(dt: number)
	local pos = myPos()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if pos and root and root:IsA("BasePart") then
		mapMe.Position = mapUV(pos)
		local look = root.CFrame.LookVector
		mapMe.Rotation = math.deg(math.atan2(look.X, -look.Z))
	end
	-- 길잡이 글자와 도착
	if guideStyle and guideLabel and pos then
		local m = Config.MASTERS[guideStyle]
		local dir, dist = bearing(pos, m.at)
		guideLabel.Text = string.format("📍 %s\n%s쪽 · %d칸", m.name, dir, math.floor(dist))
		if dist < Config.MASTER_RANGE - 4 then
			UI.toast("🥋 " .. m.name .. " 곁에 왔어요. T를 눌러 권법을 배우세요")
			UI.setGuide(nil)
		end
	end
	if pos then
		storyTick(pos)
	end
	mapAcc += dt
	if mapAcc < 0.25 then
		return
	end
	mapAcc = 0
	if pos then
		ambientTick(pos)
	end
	local n = 0
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies and pos then
		local range = mapBig and 600 or 350
		for _, e in ipairs(enemies:GetChildren()) do
			local r = e:FindFirstChild("HumanoidRootPart")
			if n < #mapDots and r and r:IsA("BasePart") and e:GetAttribute("Dead") ~= true and (r.Position - pos).Magnitude < range then
				n += 1
				local d = mapDots[n]
				d.Position = mapUV(r.Position)
				d.Size = e:GetAttribute("Boss") == true and UDim2.new(0, 10, 0, 10) or UDim2.new(0, 6, 0, 6)
				d.Visible = true
			end
		end
	end
	for i = n + 1, #mapDots do
		mapDots[i].Visible = false
	end
	-- 권법 창이 열려 있으면 사부까지 거리도 새로
	if window.Visible and current == "styles" and refreshers.styles then
		refreshers.styles(false)
	end
end

------------------------------------------------------------------------
-- 바람 줄 (빠르게 달리거나 대시할 때 화면 가장자리로 흐르는 선)
------------------------------------------------------------------------
local speedLines: { { f: Frame, a: number, d: number } } = {}
local speedAmt = 0
function UI.setSpeed(amount: number)
	speedAmt += (amount - speedAmt) * 0.25
	if #speedLines == 0 or not gui then
		return
	end
	local t = os.clock()
	for i, l in ipairs(speedLines) do
		local k = ((t * 2.2 + l.d) % 1)
		local r = 0.42 + k * 0.25
		l.f.Position = UDim2.fromScale(0.5 + math.cos(l.a) * r, 0.5 + math.sin(l.a) * r * 1.1)
		l.f.Rotation = math.deg(l.a)
		l.f.BackgroundTransparency = 1 - speedAmt * 0.55 * (1 - k)
		l.f.Visible = speedAmt > 0.02
		local _ = i
	end
end
local function buildSpeedLines()
	for i = 1, 22 do
		local a = (i / 22) * math.pi * 2 + math.random() * 0.2
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 160, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = gui })
		table.insert(speedLines, { f = f, a = a, d = math.random() })
	end
end

------------------------------------------------------------------------
-- 휴대폰 버튼
------------------------------------------------------------------------
function UI.mobile(actions: { [string]: any })
	if not UserInputService.TouchEnabled then
		return
	end
	local pad = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -190), Size = UDim2.new(0, 260, 0, 260), BackgroundTransparency = 1, Parent = gui })
	scaled(pad)
	local function round(label: string, pos: UDim2, size: number, color: Color3, down: () -> (), up: (() -> ())?)
		local b = new("TextButton", { AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.new(0, size, 0, size), BackgroundColor3 = color, BackgroundTransparency = 0.25, Text = label, TextSize = 16, Font = Enum.Font.GothamBlack, TextColor3 = C.text, Parent = pad }, { corner(999), stroke(Color3.new(1, 1, 1), 2) })
		b.MouseButton1Down:Connect(down)
		if up then
			b.MouseButton1Up:Connect(up)
			b.MouseLeave:Connect(up)
		end
	end
	round("👊", UDim2.fromScale(0.72, 0.72), 96, C.red, actions.attack)
	round("💥", UDim2.fromScale(0.36, 0.86), 62, C.panel2, actions.heavyDown, actions.heavyUp)
	round("🛡", UDim2.fromScale(0.95, 0.38), 62, C.panel2, actions.guardDown, actions.guardUp)
	round("💨", UDim2.fromScale(0.42, 0.52), 58, C.panel2, actions.dash)
	round("E", UDim2.fromScale(0.12, 0.62), 50, C.panel2, actions.E)
	round("R", UDim2.fromScale(0.62, 0.28), 50, C.panel2, actions.R)
	round("G", UDim2.fromScale(0.22, 0.3), 50, C.gold, actions.G)
	round("🧪", UDim2.fromScale(0.95, 0.05), 44, C.green, actions.potion)
	round("●", UDim2.fromScale(0.05, 0.95), 44, C.chi, actions.train)
end

------------------------------------------------------------------------
-- 만들기
------------------------------------------------------------------------
function UI.init(req: RemoteEvent)
	Request = req
	gui = new("ScreenGui", { Name = "KwonUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
	-- 화면이 클수록 크게 (1080p에서 1.5배). 창은 화면을 넘지 않게. 화면 크기가 바뀌면 다시 잰다
	measure()
	local camConn: RBXScriptConnection? = nil
	local function watchCam()
		if camConn then
			camConn:Disconnect()
			camConn = nil
		end
		local cam = workspace.CurrentCamera
		if cam then
			camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(measure)
		end
		measure()
	end
	watchCam()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCam)
	-- 혹시 신호를 놓쳐도 처음 몇 초는 몇 번 더 잰다
	task.spawn(function()
		for _ = 1, 10 do
			task.wait(0.5)
			measure()
		end
	end)
	flash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 40, Active = false, Parent = gui })
	for _, top in ipairs({ true, false }) do
		table.insert(bars, new("Frame", { AnchorPoint = Vector2.new(0, top and 0 or 1), Position = UDim2.fromScale(0, top and 0 or 1), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 30, Parent = gui }))
	end
	toastBox = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 120), Size = UDim2.new(0, 760, 0, 230), BackgroundTransparency = 1, Parent = gui }, { new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Top }) })
	scaled(toastBox)
	buildHud()
	-- 위 왼쪽: 경지·은자·능력치, 메뉴
	local topLeft = new("Frame", { Name = "TopLeft", Position = UDim2.new(0, 16, 0, 60), Size = UDim2.new(0, 820, 0, 420), BackgroundTransparency = 1, Parent = gui }) :: Frame
	scaled(topLeft)
	topInfo = text({ Size = UDim2.new(1, 0, 0, 28), TextSize = 20, Font = Enum.Font.GothamBlack, TextStrokeTransparency = 0.3, Parent = topLeft })
	local menu = new("Frame", { Name = "Menu", Position = UDim2.new(0, 0, 0, 34), Size = UDim2.new(0, 150, 0, 380), BackgroundTransparency = 1, Parent = topLeft }, { new("UIListLayout", { Padding = UDim.new(0, 6) }) })
	for _, item in ipairs({ { "styles", "🥋 권법" }, { "map", "🗺 지도 (M)" }, { "stats", "📊 능력치" }, { "shop", "🧪 만물상" }, { "help", "📜 도움말" }, { "test", "🧪 테스트" } }) do
		local b = button({ Size = UDim2.new(1, 0, 0, 44), Text = item[2], TextSize = 18, Parent = menu }, function()
			if item[1] == "map" then
				UI.toggleMap()
			else
				UI.openPage(item[1])
			end
		end)
		new("UIStroke", { Color = C.line, Thickness = 1, Parent = b })
		if item[1] == "test" then
			b.Name = "TestButton"
			b.Visible = false
		end
	end
	buildStory(topLeft)
	-- 보스 막대
	bossFrame = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.new(0, 620, 0, 52), BackgroundTransparency = 1, Visible = false, Parent = gui })
	scaled(bossFrame)
	bossName = text({ Size = UDim2.new(1, 0, 0, 22), TextSize = 20, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.2, Parent = bossFrame })
	local bb = new("Frame", { Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = Color3.fromRGB(20, 10, 10), Parent = bossFrame }, { corner(6), stroke(C.line, 1) })
	bossFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.hp, Parent = bb }, { corner(6) })
	local pb = new("Frame", { Position = UDim2.new(0.2, 0, 0, 42), Size = UDim2.new(0.6, 0, 0, 7), BackgroundColor3 = Color3.fromRGB(20, 10, 10), Parent = bossFrame }, { corner(4) })
	bossPosture = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.posture, Parent = pb }, { corner(4) })
	RunService.RenderStepped:Connect(function()
		local m = bossModel
		if m and m.Parent then
			local hp, mx = m:GetAttribute("Hp"), m:GetAttribute("MaxHp")
			local po, pm = m:GetAttribute("Posture"), m:GetAttribute("PostureMax")
			if type(hp) == "number" and type(mx) == "number" then
				bossFill.Size = UDim2.fromScale(math.clamp(hp / math.max(1, mx), 0, 1), 1)
			end
			if type(po) == "number" and type(pm) == "number" then
				bossPosture.Size = UDim2.fromScale(math.clamp(po / math.max(1, pm), 0, 1), 1)
			end
		elseif m then
			UI.setBoss(nil)
		end
	end)
	-- 창
	window = new("Frame", { Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 900, 0, 600), BackgroundColor3 = C.bg, BackgroundTransparency = 0.04, Visible = false, ZIndex = 10, Parent = gui }, { corner(16), stroke(C.line, 2.5) })
	scaled(window, "window")
	windowTitle = text({ Position = UDim2.new(0, 18, 0, 10), Size = UDim2.new(1, -80, 0, 36), TextSize = 28, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, Parent = window })
	button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.new(0, 48, 0, 40), Text = "✕", TextSize = 22, BackgroundColor3 = C.red, Parent = window }, function()
		window.Visible = false
	end)
	buildStyles()
	buildStats()
	buildShop()
	buildHelp()
	buildTest()
	buildMap()
	buildSpeedLines()
	RunService.RenderStepped:Connect(function(dt: number)
		local ok, err = pcall(updateMap, dt)
		if not ok then
			warn("[권왕] 지도 오류:", err)
		end
	end)
	-- 수련 놀이 칸
	trainFrame = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.45, 0), Size = UDim2.new(0, 380, 0, 330), BackgroundColor3 = C.bg, BackgroundTransparency = 0.25, Visible = false, Parent = gui }, { corner(16), stroke(C.line, 2) })
	scaled(trainFrame)
	trainTitle = text({ Position = UDim2.new(0, 0, 0, 8), Size = UDim2.new(1, 0, 0, 30), TextSize = 22, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center, Parent = trainFrame })
	trainHint = text({ Position = UDim2.new(0, 12, 0, 40), Size = UDim2.new(1, -24, 0, 40), TextSize = 14, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Center, Parent = trainFrame })
	trainArea = new("Frame", { Position = UDim2.new(0, 0, 0, 84), Size = UDim2.new(1, 0, 1, -130), BackgroundTransparency = 1, ClipsDescendants = true, Parent = trainFrame })
	button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(0, 160, 0, 36), Text = "그만하기", TextSize = 16, BackgroundColor3 = C.panel2, Parent = trainFrame }, function()
		Request:FireServer("trainStop")
	end)
	-- 쓰러짐
	koFrame = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(30, 0, 0), BackgroundTransparency = 0.55, Visible = false, ZIndex = 35, Parent = gui })
	koText = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 60), TextSize = 30, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.2, ZIndex = 36, Parent = koFrame })
end

function UI.gui(): ScreenGui
	return gui
end

return UI
