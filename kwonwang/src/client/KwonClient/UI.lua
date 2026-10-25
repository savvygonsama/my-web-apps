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
		if not l.Parent then
			return
		end
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
-- 오의 화면 연출: 검은 섬광 한 번, 가운데로 몰려드는 집중선, 권법 빛깔의 테두리
function UI.ultFrame(color: Color3, color2: Color3)
	local layer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 35, Active = false, Parent = gui })
	local inv = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.15, ZIndex = 35, Parent = layer })
	task.delay(0.05, function()
		inv.BackgroundColor3 = color2
		TweenService:Create(inv, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	end)
	-- 줄마다 가운데를 향하게 놓는다 (프레임은 제 가운데를 축으로 돌므로 자리는 각도로 따로 잡는다)
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local reach = vp.Magnitude * 0.5
	for i = 1, 30 do
		local a = i / 30 * 360 + math.random() * 8
		local dir = Vector2.new(math.cos(math.rad(a)), math.sin(math.rad(a)))
		local len = reach * (0.45 + math.random() * 0.2)
		local function at(r: number): UDim2
			return UDim2.new(0.5, dir.X * r, 0.5, dir.Y * r)
		end
		local line = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = at(reach * 0.95), Size = UDim2.fromOffset(len, math.random(2, 6)), Rotation = a,
			BackgroundColor3 = i % 3 == 0 and color or Color3.new(1, 1, 1), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 36, Parent = layer })
		-- 가운데 쪽 끝은 흐리게
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0) }), Parent = line })
		-- 바깥에서 가운데로 몰려든다
		TweenService:Create(line, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = at(reach * 0.55), Size = UDim2.fromOffset(len * 0.6, 1), BackgroundTransparency = 1 }):Play()
	end
	-- 테두리는 프레임 바깥으로 그려지므로 안쪽으로 당겨 둔다
	local rim = new("Frame", { Position = UDim2.fromOffset(24, 24), Size = UDim2.new(1, -48, 1, -48), BackgroundTransparency = 1, ZIndex = 36, Parent = layer }, { new("UIStroke", { Color = color, Thickness = 40, Transparency = 0.2 }) })
	local st = rim:FindFirstChildOfClass("UIStroke")
	if st then
		TweenService:Create(st, TweenInfo.new(0.7), { Transparency = 1, Thickness = 8 }):Play()
	end
	task.delay(0.75, function()
		layer:Destroy()
	end)
end

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

-- 위가 밝고 아래가 어두운 빛 (막대·칸에 입힌다)
local function sheen(parent: Instance, top: number?, bottom: number?)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1):Lerp(Color3.new(1, 1, 1), 0), Color3.fromRGB(150, 150, 150)), Transparency = NumberSequence.new(top or 0, bottom or 0), Parent = parent })
end
UI.sheen = sheen
local meterTrails: { [Frame]: Frame } = {}
local function meter(parent: Instance, pos: UDim2, size: UDim2, color: Color3, label: string): (Frame, TextLabel)
	local back = new("Frame", { Position = pos, Size = size, BackgroundColor3 = Color3.fromRGB(16, 11, 10), BackgroundTransparency = 0.1, Parent = parent }, { corner(6), stroke(Color3.fromRGB(150, 115, 70), 1.4) })
	-- 깎인 만큼 잠깐 남는 흰 띠 (맞은 양이 보인다)
	local trail = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 240, 220), BackgroundTransparency = 0.25, Parent = back }, { corner(6) })
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, ZIndex = 2, Parent = back }, { corner(6) })
	sheen(fill)
	meterTrails[fill] = trail
	local l = text({ Size = UDim2.fromScale(1, 1), Text = label, TextSize = 16, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, ZIndex = 3, Parent = back })
	return fill, l
end
-- 흰 띠가 천천히 따라 내려온다
local function trailTo(fill: Frame, r: number)
	fill.Size = UDim2.fromScale(r, 1)
	local trail = meterTrails[fill]
	if trail then
		local cur = trail.Size.X.Scale
		trail.Size = UDim2.fromScale(r > cur and r or cur + (r - cur) * 0.06, 1)
	end
end

local function buildHud()
	local hud = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(0, 660, 0, 176), BackgroundTransparency = 1, Parent = gui })
	scaled(hud)
	-- 막대 뒤의 어두운 판과 금빛 테
	local plate = new("Frame", { Position = UDim2.new(0, -14, 0, 48), Size = UDim2.new(1, 28, 0, 76), BackgroundColor3 = Color3.fromRGB(14, 10, 9), BackgroundTransparency = 0.35, ZIndex = 0, Parent = hud }, { corner(12), stroke(Color3.fromRGB(150, 115, 70), 1) })
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.2, 0.6), Parent = plate })
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
	for _, s in ipairs({ { "M1", "클릭" }, { "H", "Z 강타" }, { "E", "E" }, { "R", "R" }, { "G", "G 오의" }, { "X", "X 초 오의" }, { "Q", "Q 대시" }, { "F", "F 막기" }, { "P", "H 약" } }) do
		local cell = new("Frame", { Size = UDim2.new(0, 76, 1, 0), BackgroundColor3 = C.panel, BackgroundTransparency = 0.1, Parent = row }, { corner(8) })
		local st = stroke(C.line, 1.2)
		st.Parent = cell
		sheen(cell, 0, 0)
		-- 위의 빛깔 띠 (쓰는 권법의 빛)
		local stripe = new("Frame", { Size = UDim2.new(1, -8, 0, 3), Position = UDim2.new(0, 4, 0, 2), BackgroundColor3 = C.gold, BorderSizePixel = 0, ZIndex = 3, Parent = cell }, { corner(2) })
		local name = text({ Size = UDim2.new(1, -4, 0.62, 0), Position = UDim2.new(0, 2, 0, 2), TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3, Parent = cell })
		local key = text({ Position = UDim2.new(0, 0, 0.6, 0), Size = UDim2.new(1, 0, 0.4, 0), Text = s[2], TextSize = 12, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3, Parent = cell })
		local cd = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, ZIndex = 4, Parent = cell }, { corner(8) })
		local _ = key
		HUD.slots[s[1]] = { cell = cell, name = name, cd = cd, stripe = stripe, stroke = st }
	end
end

-- 매 순간 내 막대
function UI.bars(hp: number, maxHp: number, posture: number, postureMax: number, chi: number, chiMax: number?)
	if not HUD.hp then
		return
	end
	trailTo(HUD.hp, math.clamp(hp / math.max(1, maxHp), 0, 1))
	HUD.hpText.Text = string.format("❤ %d / %d", math.floor(hp), maxHp)
	local pr = math.clamp(posture / math.max(1, postureMax), 0, 1)
	HUD.posture.Size = UDim2.fromScale(pr, 1)
	HUD.posture.BackgroundColor3 = pr > 0.75 and C.red or C.posture
	local cm = chiMax or Config.CHI_MAX
	HUD.chi.Size = UDim2.fromScale(math.clamp(chi / cm, 0, 1), 1)
	HUD.chiText.Text = string.format("🌀 내공 %d / %d", math.floor(chi), cm)
end

-- 기술 칸 (이름, 잠김, 대기 시간 비율)
function UI.slots(info: { [string]: { name: string, locked: boolean?, cd: number? } })
	if not HUD.slots then
		return
	end
	for key, s in pairs(HUD.slots) do
		local i = info[key]
		-- 초 오의 칸은 초월 권법일 때만
		if key == "X" then
			s.cell.Visible = i ~= nil
		end
		if i then
			s.name.Text = (i.locked and "🔒 " or "") .. i.name
			s.name.TextColor3 = i.locked and C.dim or C.text
			local cdr = math.clamp(i.cd or 0, 0, 1)
			s.cd.Size = UDim2.fromScale(1, cdr)
			-- 쓸 수 있는 기술은 테가 권법 빛으로 빛난다
			if s.stripe and HUD.styleColor then
				s.stripe.BackgroundColor3 = HUD.styleColor
				s.stroke.Color = (cdr <= 0 and not i.locked and (key == "E" or key == "R" or key == "G" or key == "X")) and HUD.styleColor or C.line
				s.stroke.Thickness = (cdr <= 0 and not i.locked and (key == "G" or key == "X")) and (key == "X" and 3.5 or 2.5) or 1.2
			end
		end
	end
end

function UI.styleLine(t: string, color: Color3, stacks: string)
	if HUD.style then
		HUD.style.Text = t
		HUD.style.TextColor3 = color
		HUD.styleColor = color
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
local bossSub: TextLabel
local bossHpText: TextLabel
local bossModel: Model? = nil
function UI.setBoss(model: Model?)
	bossModel = model
	bossFrame.Visible = model ~= nil
	if model then
		local label = model:GetAttribute("Label")
		bossName.Text = "👹 " .. (type(label) == "string" and label or "보스")
		UI.bossPhase(tonumber(model:GetAttribute("BossPhase")) or 1)
	end
end
function UI.bossPhase(ph: number)
	if bossSub and bossModel then
		local lv = bossModel:GetAttribute("Level")
		local power = bossModel:GetAttribute("Power")
		bossSub.Text = string.format("Lv.%s  ·  %d단계 / 3  ·  ⚔ 전투력 %s", tostring(lv or "?"), ph, Config.formatNumber(tonumber(power) or 0))
		bossSub.TextColor3 = ph >= 3 and Color3.fromRGB(255, 90, 70) or (ph == 2 and Color3.fromRGB(255, 170, 90) or C.dim)
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
		if model:GetAttribute("Dummy") == true then
			local dps = tonumber(model:GetAttribute("Dps")) or 0
			local best = tonumber(model:GetAttribute("Best")) or 0
			powerLabel.Text = "🎯 초당 피해 " .. Config.formatNumber(dps) .. " · 가장 센 한 방 " .. Config.formatNumber(best)
			powerLabel.TextColor3 = Color3.fromRGB(255, 225, 150)
			return
		end
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
	model:GetAttributeChangedSignal("Dps"):Connect(refreshPower)
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
local TITLES = { styles = "🥋 권법", stats = "📊 능력치와 경지", shop = "🧪 만물상", help = "📜 도움말", test = "🧪 테스트", manuals = "📜 심법 (내공 수련서)", skyshop = "💠 천상 상점", ach = "🏆 업적과 칭호" }

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
		elseif action == "awaken" then
			Request:FireServer("awaken", selected)
			window.Visible = false
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
		for _, slot in ipairs({ "E", "R", "G", "X" }) do
			local sk = s.skills[slot]
			if sk then
				local need = Config.SKILL_UNLOCK[slot]
				local lockTxt = lv >= need and "" or string.format(' <font color="#AA9988">(숙련 %d)</font>', need)
				local label = slot == "G" and "오의 G" or (slot == "X" and '<font color="#FF9AC8">초 오의 X</font>' or slot)
				table.insert(lines, string.format("<b>%s %s</b>%s  %s", label, sk.name, lockTxt, sk.desc))
			end
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
			local kind, need = Config.trialNeed(s.id)
			local K = Config.TRIAL_KINDS[kind]
			if K then
				table.insert(lines, string.format('<font color="#FFB070"><b>사부의 시험 · %s %s</b>  %s</font>', K.icon, K.title, string.format(K.ask, need)))
			else
				table.insert(lines, '<font color="#FFB070"><b>사부의 시험</b>  사부와 겨뤄 이겨야 제자로 받아 준다. 마구 휘두르면 막히고 되받아친다.</font>')
			end
		end
		if s.realmReq then
			table.insert(lines, "")
			table.insert(lines, string.format('<font color="#FFE8A0"><b>경지 제한</b>  %s에 올라야 사부가 시험을 허락한다</font>', Config.Realms[s.realmReq].name))
		end
		local req = s.styleReq and Config.STYLE_BY_ID[s.styleReq]
		if req then
			table.insert(lines, string.format('<font color="#FFE8A0"><b>먼저 익힐 권법</b>  %s</font>', req.name))
		end
		-- 2.5판: 초월 권법의 조건 (숙련 20 둘 + 천상 재료)
		local TR = Config.TRANSCEND_REQ[id]
		if TR and not owned then
			local function lvOf(sid: string): number
				local mm = state and state.mastery and state.mastery[sid]
				return (mm and table.find(state.styles or {}, sid)) and mm.lv or 0
			end
			local function mark(ok: boolean): string
				return ok and '<font color="#9CFF9C">✔</font>' or '<font color="#FF8A8A">✘</font>'
			end
			local base = Config.STYLE_BY_ID[TR.base]
			table.insert(lines, "")
			table.insert(lines, '<font color="#FFB6E6"><b>초월의 조건</b></font>')
			table.insert(lines, string.format("%s %s 숙련 %d (지금 %d)", mark(lvOf(TR.base) >= TR.lv), base and base.name or TR.base, TR.lv, lvOf(TR.base)))
			if TR.awakened == "any" then
				local best = 0
				for _, sd in ipairs(Config.Styles) do
					if sd.awakenOf then
						best = math.max(best, lvOf(sd.id))
					end
				end
				table.insert(lines, string.format("%s 각성 권법(진) 하나를 숙련 %d (가장 높은 것 %d)", mark(best >= TR.lv), TR.lv, best))
			else
				local a = Config.STYLE_BY_ID[TR.awakened]
				table.insert(lines, string.format("%s %s 숙련 %d (지금 %d)", mark(lvOf(TR.awakened) >= TR.lv), a and a.name or TR.awakened, TR.lv, lvOf(TR.awakened)))
			end
			local mats = state and state.mats or {}
			for _, stage in ipairs({ { "시련을 청할 때", TR.challenge }, { "배울 때", TR.learn } }) do
				local parts = {}
				local all = true
				for mid, n in pairs(stage[2]) do
					local M = Config.SKY_MAT_BY_ID[mid]
					local have = mats[mid] or 0
					all = all and have >= n
					table.insert(parts, string.format("%s %s %d/%d", M.icon, M.name, have, n))
				end
				table.insert(lines, string.format("%s %s: %s", mark(all), stage[1], table.concat(parts, " · ")))
			end
			for mid in pairs(TR.learn) do
				local M = Config.SKY_MAT_BY_ID[mid]
				table.insert(lines, string.format('<font color="#C8B8A0">%s 얻는 곳: %s (천상계에서만)</font>', M.icon, M.how))
			end
		end
		-- 승급 (깨달음)
		if owned then
			local step = Config.BREAKTHROUGH[ups + 1]
			table.insert(lines, "")
			if step then
				table.insert(lines, string.format("<b>⬆ 권법 승급 (%s)</b>  숙련 %d · %s 이상 · 💰 %s → [%s] (피해 ×%.2f → ×%.2f)", step.name, Config.MASTERY_FULL, Config.Realms[step.realm].name, Config.formatNumber(step.coins), Config.styleGrade(s, ups + 1), Config.GRADES[gradeNow], Config.GRADES[Config.styleGrade(s, ups + 1)]))
			else
				table.insert(lines, string.format("<b>⬆ 권법 승급</b>  모든 깨달음을 얻었다 [%s]", gradeNow))
			end
		end
		-- 각성 권법이 있는 권법: 각성 조건
		for _, sd in ipairs(Config.Styles) do
			if sd.awakenOf == id and owned then
				local A = Config.AWAKEN_STYLE
				table.insert(lines, "")
				table.insert(lines, string.format('<font color="#FF8A9A"><b>🔥 각성: %s</b>  숙련 %d · 깨달음 %d번 · %s 이상%s · 💰 %s → 각성 시련 (각성선인 곁에서)</font>', sd.name, Config.MASTERY_FULL, #Config.BREAKTHROUGH, Config.Realms[A.realm].name, sd.rebirthReq and string.format(" · ♻ 환생 %d번", sd.rebirthReq) or "", Config.formatNumber(A.coins)))
			end
		end
		dBody.Text = table.concat(lines, "\n")
		local cost = state and state.learnCost or 0
		local canBreak = owned and Config.BREAKTHROUGH[ups + 1] ~= nil and lv >= Config.MASTERY_FULL
		-- 각성 (진 권법): 깨달음을 모두 얻은 원래 권법에서
		local v2 = nil
		for _, sd in ipairs(Config.Styles) do
			if sd.awakenOf == id then
				v2 = sd
			end
		end
		local canAwaken = owned and v2 ~= nil and not (state and table.find(state.styles, v2.id)) and ups >= #Config.BREAKTHROUGH and lv >= Config.MASTERY_FULL
		if canAwaken and v2 then
			local A = Config.AWAKEN_STYLE
			dBtn.Text = string.format("🔥 각성 시련 → %s  💰 %s", v2.name, Config.formatNumber(A.coins))
			dBtn.BackgroundColor3 = (state and state.coins >= A.coins and state.realm >= A.realm) and Color3.fromRGB(200, 40, 60) or C.panel
			action = "awaken"
		elseif s.awakenOf and not owned then
			dBtn.Text = "🔥 원래 권법에서 각성한다"
			dBtn.BackgroundColor3 = C.panel
			action = "none"
		elseif canBreak then
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
	-- 경지의 관문: 능력치가 닿으면 열린다 (수호자를 꺾어야 경지가 오른다)
	local gateBtn = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 4), Size = UDim2.new(0, 300, 0, 58), Text = "⛩ 관문 도전", TextSize = 20, BackgroundColor3 = Color3.fromRGB(170, 120, 40), Visible = false, ZIndex = 3, Parent = page }, function()
		Request:FireServer("gate")
		window.Visible = false
	end)
	-- 1.9판 환생: 열린 끝 경지에 오르면 보인다. 두 번 눌러야 한다 (실수로 누르지 않게)
	local rebirthArmed = 0
	local rebirthBtn: TextButton
	rebirthBtn = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 68), Size = UDim2.new(0, 300, 0, 58), Text = "♻ 환생", TextSize = 20, BackgroundColor3 = Color3.fromRGB(170, 60, 140), Visible = false, ZIndex = 3, Parent = page }, function()
		if os.clock() - rebirthArmed > 4 then
			rebirthArmed = os.clock()
			rebirthBtn.Text = "♻ 정말 환생? 한 번 더 누르기"
			task.delay(4, function()
				if os.clock() - rebirthArmed >= 3.9 and refreshers.stats then
					refreshers.stats()
				end
			end)
			return
		end
		rebirthArmed = 0
		Request:FireServer("rebirth")
		window.Visible = false
	end)
	refreshers.stats = function()
		if not state then
			return
		end
		local rb = state.rebirth or 0
		local cap = state.realmCap or 16
		local canRebirth = rb < Config.REBIRTH.max and state.realm >= cap
		rebirthBtn.Visible = canRebirth
		if canRebirth and os.clock() - rebirthArmed > 4 then
			rebirthBtn.Text = string.format("♻ %s (%d번째 환생)", Config.REBIRTH.names[rb + 1] or "환생", rb + 1)
		end
		gateBtn.Visible = state.gateNext ~= nil
		if state.gateNext then
			local r = Config.Realms[state.gateNext]
			gateBtn.Text = "⛩ " .. (r and r.name or "") .. "의 관문 도전"
		end
		local lines = {}
		local idx = state.realm
		local realm = Config.Realms[idx]
		local nextRealm = Config.Realms[idx + 1]
		local locked = nextRealm and (nextRealm.rebirth or 0) > rb
		table.insert(lines, string.format("<b>경지: %s%s</b>  (능력치 합 %s%s)", rb > 0 and ((Config.REBIRTH.names[rb] or "") .. " · ") or "", realm.name, Config.formatNumber(state.total),
			nextRealm and string.format(" / 다음 %s는 %s%s", nextRealm.name, Config.formatNumber(nextRealm.need), locked and ' <font color="#FF9AD8">(환생해야 열림)</font>' or "") or ""))
		table.insert(lines, string.format("경지 배율 ×%.2f (사경까지 경지마다 ×1.22, 그 위로는 ×1.38씩 겹으로, 수련 효과 +%d%%, 생사경부터는 그 경지 적 한 마리에 견줘 크게) · 경지는 스무 단계 (천외천 너머 넷은 환생해야 열린다)", Config.realmPower(idx), math.floor(Config.TRAIN_REALM_BONUS * 100)))
		if rb > 0 then
			table.insert(lines, string.format('<font color="#FF9AD8">♻ 환생 %d번: 체력 ×%.2f · 주는 피해 ×%.2f · 얻는 능력치 ×%.1f · %s까지 열림</font>', rb, Config.rebirthPower(rb), Config.rebirthDmg(rb), Config.rebirthGain(rb), Config.Realms[cap].name))
		end
		if canRebirth then
			table.insert(lines, string.format('<font color="#FF9AD8"><b>♻ 환생할 수 있다!</b> 능력치를 모두 내려놓고 삼류로 돌아간다 (권법·숙련·심법·은자·관문은 그대로). 체력 ×%.2f · 주는 피해 ×%.2f, 얻는 능력치 ×%.1f, %s의 경지가 열린다</font>', Config.rebirthPower(rb + 1), Config.rebirthDmg(rb + 1), Config.rebirthGain(rb + 1), (Config.Realms[Config.realmCap(rb + 1)] or realm).name))
		elseif rb < Config.REBIRTH.max then
			table.insert(lines, string.format("♻ 환생: %s에 오르면 할 수 있다 (지금 %d / %d번)", Config.Realms[cap].name, rb, Config.REBIRTH.max))
		end
		table.insert(lines, string.format("⛩ %s부터는 능력치가 닿아도 <b>관문 수호자</b>를 꺾어야 경지가 오른다%s", Config.Realms[Config.GATE.from].name, state.gateNext and string.format(' <font color="#FFD25A">(지금 %s의 관문이 열려 있다)</font>', Config.Realms[state.gateNext].name) or ""))
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

------------------------------------------------------------------------
-- 1.9판: 업적과 칭호
------------------------------------------------------------------------
local function buildAch()
	local page = makePage("ach")
	local head = text({ Size = UDim2.new(1, -330, 0, 52), TextSize = 17, RichText = true, Parent = page })
	button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 4), Size = UDim2.new(0, 150, 0, 44), Text = "칭호 떼기", TextSize = 16, Parent = page }, function()
		Request:FireServer("title", "")
	end)
	local list = scroller(page, UDim2.new(1, 0, 1, -60), UDim2.new(0, 0, 0, 60))
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local rows: { [string]: any } = {}
	for i, a in ipairs(Config.ACHIEVEMENTS) do
		local card = new("Frame", { Size = UDim2.new(1, -12, 0, 64), BackgroundColor3 = C.panel, LayoutOrder = i, Parent = list }, { corner(10) })
		local st = stroke(C.line, 1.5)
		st.Parent = card
		text({ Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0, 50, 1, 0), Text = a.icon, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center, Parent = card })
		local name = text({ Position = UDim2.new(0, 64, 0, 6), Size = UDim2.new(1, -260, 0, 24), Text = a.name, TextSize = 19, Font = Enum.Font.GothamBlack, RichText = true, Parent = card })
		local rewards = {}
		if a.coins then
			table.insert(rewards, "💰 " .. Config.formatNumber(a.coins))
		end
		if a.gems then
			table.insert(rewards, "💎 " .. Config.formatNumber(a.gems))
		end
		if a.scrolls then
			table.insert(rewards, "📜 " .. a.scrolls)
		end
		if a.title then
			table.insert(rewards, "칭호 「" .. a.title .. "」")
		end
		local sub = text({ Position = UDim2.new(0, 64, 0, 32), Size = UDim2.new(1, -260, 0, 26), Text = a.desc .. "   ·   " .. table.concat(rewards, "  "), TextSize = 14, TextColor3 = C.dim, Parent = card })
		local bar = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 170, 0, 30), BackgroundColor3 = Color3.fromRGB(25, 18, 16), Parent = card }, { corner(8) })
		local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.green, Parent = bar }, { corner(8) })
		local label = text({ Size = UDim2.fromScale(1, 1), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2, Parent = bar })
		local equip = button({ Size = UDim2.fromScale(1, 1), Text = "", BackgroundTransparency = 1, ZIndex = 3, Visible = false, Parent = bar }, function()
			Request:FireServer("title", a.id)
		end)
		rows[a.id] = { card = card, stroke = st, name = name, sub = sub, fill = fill, label = label, equip = equip }
	end
	refreshers.ach = function()
		if not state then
			return
		end
		local done, total = 0, #Config.ACHIEVEMENTS
		local ach = state.ach or {}
		local prog = state.achProg or {}
		for _, a in ipairs(Config.ACHIEVEMENTS) do
			local r = rows[a.id]
			local ok = ach[a.id] == true
			if ok then
				done += 1
			end
			local v = prog[a.id] or 0
			r.fill.Size = UDim2.fromScale(ok and 1 or math.clamp(v / a.n, 0, 1), 1)
			r.fill.BackgroundColor3 = ok and C.gold or C.green
			local col = Config.ACH_COLOR[a.kind] or C.gold
			r.stroke.Color = ok and col or C.line
			r.card.BackgroundColor3 = ok and Color3.fromRGB(56, 40, 26) or C.panel
			r.name.TextColor3 = ok and col or C.text
			local wearing = state.title == a.id
			if ok and a.title then
				r.label.Text = wearing and "✔ 달고 있음" or "칭호 달기"
				r.fill.BackgroundColor3 = wearing and C.green or C.gold
				r.equip.Visible = not wearing
			else
				r.label.Text = ok and "✔ 이룸" or string.format("%s / %s", Config.formatNumber(v), Config.formatNumber(a.n))
				r.equip.Visible = false
			end
		end
		local t = state.title and Config.ACH_BY_ID[state.title]
		head.Text = string.format("<b>이룬 업적 %d / %d</b>\n칭호: %s", done, total, t and ("「" .. t.title .. "」") or "없음 (칭호가 붙은 업적을 이루면 달 수 있다)")
	end
end

local function buildShop()
	local page = makePage("shop")
	local list = scroller(page, UDim2.fromScale(1, 1))
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	-- 💎 로벅스 상품: 금빛 카드 (큰 그림, 이름표, 좋은 점 세 줄, 값)
	local premiumBtns: { [string]: TextButton } = {}
	-- 자동 수련 카드: 켜기·끄기 + 올릴 능력치 고르기 (가진 카드에만 보인다)
	local autoBtns: { [string]: { toggle: TextButton, stat: TextButton } } = {}
	text({ Size = UDim2.new(1, -12, 0, 26), Text = "💎 로벅스 상품", TextSize = 20, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, LayoutOrder = 0, Parent = list })
	for i, it in ipairs(Config.Premium) do
		local card = new("Frame", { Size = UDim2.new(1, -12, 0, 150), BackgroundColor3 = it.best and Color3.fromRGB(50, 26, 80) or (it.toggle and Color3.fromRGB(20, 50, 70) or Color3.fromRGB(70, 24, 14)), LayoutOrder = i, Parent = list }, { corner(14), stroke(Color3.fromRGB(255, 200, 90), 2) })
		new("UIGradient", { Rotation = 20, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 120, 90)), Parent = card })
		local badge = new("Frame", { Position = UDim2.new(0, 14, 0.5, -55), Size = UDim2.new(0, 110, 0, 110), BackgroundColor3 = Color3.fromRGB(30, 20, 10), Parent = card }, { corner(16), stroke(Color3.fromRGB(255, 220, 120), 2) })
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(120, 70, 20)), Transparency = NumberSequence.new(0.55, 0.85), Parent = badge })
		text({ Size = UDim2.fromScale(1, 1), Text = it.icon, TextSize = 64, TextXAlignment = Enum.TextXAlignment.Center, Parent = badge })
		text({ Position = UDim2.new(0, 138, 0, 10), Size = UDim2.new(1, -330, 0, 32), Text = it.name, TextSize = 26, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 225, 140), Parent = card })
		local chip = new("Frame", { Position = UDim2.new(0, 138, 0, 44), Size = UDim2.new(0, 70, 0, 22), BackgroundColor3 = it.best and Color3.fromRGB(150, 90, 230) or (it.toggle and Color3.fromRGB(40, 140, 200) or Color3.fromRGB(200, 70, 40)), Parent = card }, { corner(11) })
		text({ Size = UDim2.fromScale(1, 1), Text = it.tag, TextSize = 13, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, Parent = chip })
		text({ Position = UDim2.new(0, 138, 0, 72), Size = UDim2.new(1, -330, 0, 72), Text = "✦ " .. table.concat(it.lines, "\n✦ "), TextSize = 14, TextColor3 = Color3.fromRGB(240, 225, 200), TextYAlignment = Enum.TextYAlignment.Top, Parent = card })
		premiumBtns[it.id] = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 20), Size = UDim2.new(0, 170, 0, 52), Text = "R$ " .. tostring(it.price) .. "  구매", TextSize = 20, BackgroundColor3 = Color3.fromRGB(40, 170, 80), Parent = card }, function()
			Request:FireServer("premiumBuy", it.id)
		end)
		if it.toggle then
			local tg = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 80), Size = UDim2.new(0, 82, 0, 40), Text = "켜기", TextSize = 16, BackgroundColor3 = C.panel2, Visible = false, Parent = card }, function()
				Request:FireServer("autoToggle")
			end)
			local sb = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -102, 0, 80), Size = UDim2.new(0, 82, 0, 40), Text = "골고루", TextSize = 15, BackgroundColor3 = C.panel2, Visible = false, Parent = card }, function()
				Request:FireServer("autoStat")
			end)
			autoBtns[it.id] = { toggle = tg, stat = sb }
		end
	end
	-- 🐎 탈것: V로 타고 내린다
	text({ Size = UDim2.new(1, -12, 0, 26), Text = "🐎 탈것 (V로 타기·내리기)", TextSize = 20, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, LayoutOrder = 10, Parent = list })
	local mountBtns: { [string]: TextButton } = {}
	for k, m in ipairs(Config.MOUNTS) do
		local row = new("Frame", { Size = UDim2.new(1, -12, 0, 64), BackgroundColor3 = C.panel2, LayoutOrder = 10 + k, Parent = list }, { corner(10), stroke(C.line, 1) })
		text({ Position = UDim2.new(0, 14, 0, 4), Size = UDim2.new(1, -200, 0, 28), Text = string.format("%s %s  ·  빠르기 ×%.2f", m.icon, m.name, m.speed), TextSize = 19, Font = Enum.Font.GothamBlack, Parent = row })
		text({ Position = UDim2.new(0, 14, 0, 34), Size = UDim2.new(1, -200, 0, 24), Text = m.desc, TextSize = 14, TextColor3 = C.dim, Parent = row })
		mountBtns[m.id] = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 160, 0, 44), Text = "", TextSize = 17, Parent = row }, function()
			local owned = state and ((state.mounts and state.mounts[m.id]) or (m.premium and state.premium and state.premium[m.premium]))
			Request:FireServer(owned and "mountSelect" or "mountBuy", m.id)
		end)
	end
	text({ Size = UDim2.new(1, -12, 0, 26), Text = "💰 은자로 사는 것", TextSize = 20, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, LayoutOrder = 20, Parent = list })
	local labels = {}
	for k, item in ipairs(Config.Shop) do
		local row = new("Frame", { Size = UDim2.new(1, -12, 0, 70), BackgroundColor3 = C.panel2, LayoutOrder = 20 + k, Parent = list }, { corner(10), stroke(C.line, 1) })
		text({ Position = UDim2.new(0, 14, 0, 6), Size = UDim2.new(1, -200, 0, 28), Text = item.icon .. " " .. item.name, TextSize = 20, Font = Enum.Font.GothamBlack, Parent = row })
		text({ Position = UDim2.new(0, 14, 0, 36), Size = UDim2.new(1, -200, 0, 26), Text = item.desc, TextSize = 14, TextColor3 = C.dim, Parent = row })
		labels[item.id] = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 160, 0, 46), Text = "💰 " .. Config.formatNumber(item.cost), TextSize = 18, BackgroundColor3 = C.red, Parent = row }, function()
			Request:FireServer("buy", item.id)
		end)
	end
	refreshers.shop = function()
		for _, m in ipairs(Config.MOUNTS) do
			local b = mountBtns[m.id]
			local owned = state and ((state.mounts and state.mounts[m.id]) or (m.premium and state.premium and state.premium[m.premium]))
			local sel = state and state.mountSel == m.id
			local price = m.premium and ("R$ " .. tostring(Config.PREMIUM_BY_ID[m.premium].price)) or ("💰 " .. Config.formatNumber(m.cost))
			b.Text = sel and "✅ 고름" or (owned and "고르기" or price)
			b.BackgroundColor3 = sel and Color3.fromRGB(60, 120, 70) or (owned and C.panel or ((state and state.coins >= m.cost) and C.red or C.panel))
		end
		for _, item in ipairs(Config.Shop) do
			local can = state and state.coins >= item.cost
			labels[item.id].BackgroundColor3 = can and C.red or C.panel
		end
		local owned = state and state.premium or {}
		for id, b in pairs(premiumBtns) do
			local has = owned[id] == true
			b.Text = has and "✅ 가지고 있음" or ("R$ " .. tostring(Config.PREMIUM_BY_ID[id].price) .. "  구매")
			b.BackgroundColor3 = has and Color3.fromRGB(60, 70, 60) or Color3.fromRGB(40, 170, 80)
			b.AutoButtonColor = not has
		end
		local statLabel = { all = "골고루", str = "💪 근골", vit = "❤ 체력", agi = "🍃 경공", chi = "🌀 내공" }
		for id, ab in pairs(autoBtns) do
			local has = owned[id] == true
			local on = state and state.autoOn == true
			ab.toggle.Visible = has
			ab.stat.Visible = false -- 자동 수련은 지금 하는 수련을 대신 누른다 (능력치 고르기 없음)
			ab.toggle.Text = on and "🟢 켜짐" or "⚪ 꺼짐"
			ab.toggle.BackgroundColor3 = on and Color3.fromRGB(40, 140, 70) or C.panel2
			ab.stat.Text = statLabel[state and state.autoStat or "all"] or "골고루"
		end
	end
end

------------------------------------------------------------------------
-- 심법 (내공 수련서): 뽑기, 세 칸에 끼우기
------------------------------------------------------------------------
local function hex(c: Color3): string
	return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end
local function manualLine(id: string, r: number): string
	local m = Config.MANUAL_BY_ID[id]
	local R = Config.MANUAL_RARITY[r]
	if not m or not R then
		return ""
	end
	return string.format('%s <font color="%s"><b>[%s] %s</b></font>  %s %.1f%%', m.icon, hex(R.color), R.name, m.name, m.desc, Config.manualValue(id, r) * 100)
end
local manualAuto = false
local manualAutoBtn: TextButton? = nil
local manualAutoTotal: { number } = {}
local function canDraw10(): boolean
	if not state then
		return false
	end
	local sc = state.scrolls or 0
	return sc >= 10 or (state.coins or 0) >= (10 - sc) * Config.MANUAL_DRAW.coins
end
function UI.setManualAuto(on: boolean)
	if on and not canDraw10() then
		UI.toast("자동 뽑기: 두루마리나 은자가 모자라요")
		on = false
	end
	if on == manualAuto then
		return
	end
	manualAuto = on
	local b = manualAutoBtn
	if b then
		b.Text = on and "🔁 자동: 켜짐" or "🔁 자동: 꺼짐"
		b.BackgroundColor3 = on and Color3.fromRGB(60, 140, 80) or C.panel2
	end
	if not on then
		-- 끝날 때 모아서 한 줄로
		local parts = {}
		for i = #Config.MANUAL_RARITY, 1, -1 do
			local c = manualAutoTotal[i] or 0
			if c > 0 then
				table.insert(parts, Config.MANUAL_RARITY[i].name .. " " .. c)
			end
		end
		if #parts > 0 then
			UI.toast("🔁 자동 뽑기 끝: " .. table.concat(parts, " · "))
		end
		manualAutoTotal = {}
		return
	end
	task.spawn(function()
		while manualAuto do
			if not canDraw10() then
				UI.setManualAuto(false)
				break
			end
			Request:FireServer("manualDraw", 10, true)
			task.wait(1.1)
		end
	end)
end
-- 자동 뽑기 한 번(10번)의 결과: 좋은 것이 나오면 크게, 아니면 짧게
function UI.manualAutoResult(data: any)
	if data.stop then
		UI.setManualAuto(false)
		return
	end
	for i, c in ipairs(data.counts or {}) do
		manualAutoTotal[i] = (manualAutoTotal[i] or 0) + c
	end
	local best = data.best or 1
	local R = Config.MANUAL_RARITY[best]
	if R and best >= 4 then
		UI.toast(string.format("🔁 자동 뽑기: [%s] 등장! (새로 얻거나 오른 심법 %d)", R.name, data.ups or 0))
	end
end
local function buildManuals()
	local page = makePage("manuals")
	local D = Config.MANUAL_DRAW
	local head = text({ Size = UDim2.new(1, -440, 0, 52), TextSize = 16, RichText = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = page })
	button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -292, 0, 0), Size = UDim2.new(0, 136, 0, 48), Text = "📜 1번 뽑기", TextSize = 17, BackgroundColor3 = Color3.fromRGB(150, 100, 40) }, function()
		Request:FireServer("manualDraw", 1)
	end).Parent = page
	button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -148, 0, 0), Size = UDim2.new(0, 136, 0, 48), Text = "📜 10번 뽑기", TextSize = 17, BackgroundColor3 = Color3.fromRGB(190, 120, 30) }, function()
		Request:FireServer("manualDraw", 10)
	end).Parent = page
	-- 2.6판: 자동 뽑기 (켜 두면 두루마리·은자가 남는 동안 10번씩 연출 없이 뽑는다)
	local autoBtn: TextButton
	autoBtn = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 0), Size = UDim2.new(0, 136, 0, 48), Text = "🔁 자동: 꺼짐", TextSize = 17, BackgroundColor3 = C.panel2 }, function()
		UI.setManualAuto(not manualAuto)
	end)
	autoBtn.Parent = page
	manualAutoBtn = autoBtn
	-- 끼운 세 칸
	local slotRow = new("Frame", { Position = UDim2.new(0, 0, 0, 58), Size = UDim2.new(1, 0, 0, 74), BackgroundTransparency = 1, Parent = page })
	new("UIGridLayout", { CellSize = UDim2.new(0.333, -8, 1, 0), CellPadding = UDim2.new(0, 8, 0, 0), Parent = slotRow })
	local slots = {}
	for i = 1, D.slots do
		local card = new("Frame", { BackgroundColor3 = C.panel2, Parent = slotRow }, { corner(10), stroke(C.line, 1.5) })
		local l = text({ Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -20, 1, -8), TextSize = 15, RichText = true, Text = "", Parent = card })
		local b = button({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -6), Size = UDim2.new(0, 60, 0, 26), Text = "빼기", TextSize = 13, BackgroundColor3 = C.panel, Parent = card }, function()
			local id = state and state.equip and state.equip[i]
			if id then
				Request:FireServer("manualUnequip", id)
			end
		end)
		slots[i] = { card = card, label = l, btn = b }
	end
	local list = scroller(page, UDim2.new(1, 0, 1, -172), UDim2.new(0, 0, 0, 142))
	new("UIListLayout", { Padding = UDim.new(0, 6), Parent = list })
	local rows = {}
	for _, m in ipairs(Config.MANUALS) do
		local row = new("Frame", { Size = UDim2.new(1, -12, 0, 44), BackgroundColor3 = C.panel, Parent = list }, { corner(8), stroke(C.line, 1) })
		local l = text({ Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -130, 1, 0), TextSize = 15, RichText = true, Parent = row })
		local b = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 100, 0, 32), Text = "끼우기", TextSize = 14, Parent = row }, function()
			if not state or not state.manuals or not state.manuals[m.id] then
				return
			end
			Request:FireServer(table.find(state.equip or {}, m.id) and "manualUnequip" or "manualEquip", m.id)
		end)
		rows[m.id] = { label = l, btn = b }
	end
	local rates = {}
	for _, R in ipairs(Config.MANUAL_RARITY) do
		table.insert(rates, string.format('<font color="%s">%s %g%%</font>', hex(R.color), R.name, R.rate * 100))
	end
	text({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 22), TextSize = 13, RichText = true, TextColor3 = C.dim, Text = "확률: " .. table.concat(rates, " · ") .. string.format("  ·  %d번 안에 전설 이상이 한 번은 나온다", D.pity), Parent = page })
	refreshers.manuals = function()
		if not state then
			return
		end
		head.Text = string.format("📜 두루마리 <b>%d</b>개\n<font color=\"#FFD25A\">전설 보장까지 %d번</font>  <font color=\"#C8B9A5\">(두루마리가 없으면 한 번에 💰 %s)</font>", state.scrolls or 0, math.max(1, D.pity - (state.pity or 0)), Config.formatNumber(D.coins))
		local equip = state.equip or {}
		for i, sl in ipairs(slots) do
			local id = equip[i]
			local r = id and state.manuals and state.manuals[id]
			sl.label.Text = (id and r) and (string.format("<b>%d칸</b>\n", i) .. manualLine(id, r)) or string.format('<b>%d칸</b>\n<font color="#9A8C7A">비어 있음 (아래에서 끼우기)</font>', i)
			sl.btn.Visible = id ~= nil
		end
		for _, m in ipairs(Config.MANUALS) do
			local row = rows[m.id]
			local r = state.manuals and state.manuals[m.id]
			if r then
				row.label.Text = manualLine(m.id, r)
				local on = table.find(equip, m.id) ~= nil
				row.btn.Visible = true
				row.btn.Text = on and "✅ 빼기" or "끼우기"
				row.btn.BackgroundColor3 = on and Color3.fromRGB(60, 120, 70) or C.panel2
			else
				row.label.Text = string.format('<font color="#8A7C6A">%s %s · %s (아직 없음)</font>', m.icon, m.name, m.desc)
				row.btn.Visible = false
			end
		end
	end
end

-- 뽑기 결과: 연출 (두루마리가 터지고 카드가 뒤집힌다) 뒤에 심법 창으로
local Gacha: any = nil
function UI.manualReveal(results: { any })
	Gacha = Gacha or require(script.Parent:WaitForChild("Gacha"))
	window.Visible = false
	Gacha.play(results, function()
		UI.openPage("manuals")
	end)
end

------------------------------------------------------------------------
-- 천상 상점: 천궁에서만 열린다 (천정으로 산다)
------------------------------------------------------------------------
local function buildSkyShop()
	local page = makePage("skyshop")
	local head = text({ Size = UDim2.new(1, 0, 0, 30), TextSize = 19, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(150, 230, 255), Parent = page })
	local list = scroller(page, UDim2.new(1, 0, 1, -40), UDim2.new(0, 0, 0, 38))
	new("UIListLayout", { Padding = UDim.new(0, 8), Parent = list })
	local btns: { [string]: TextButton } = {}
	for _, it in ipairs(Config.SKY_SHOP) do
		local row = new("Frame", { Size = UDim2.new(1, -12, 0, 70), BackgroundColor3 = Color3.fromRGB(30, 36, 60), Parent = list }, { corner(10), stroke(Color3.fromRGB(150, 230, 255), 1) })
		text({ Position = UDim2.new(0, 14, 0, 6), Size = UDim2.new(1, -200, 0, 28), Text = it.icon .. " " .. it.name, TextSize = 20, Font = Enum.Font.GothamBlack, Parent = row })
		text({ Position = UDim2.new(0, 14, 0, 36), Size = UDim2.new(1, -200, 0, 26), Text = it.desc, TextSize = 14, TextColor3 = C.dim, Parent = row })
		btns[it.id] = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 160, 0, 46), Text = "💠 " .. it.cost, TextSize = 18, BackgroundColor3 = Color3.fromRGB(60, 120, 200), Parent = row }, function()
			Request:FireServer("skyBuy", it.id)
		end)
	end
	refreshers.skyshop = function()
		local g = state and state.skyGems or 0
		local matsTxt = {}
		for _, M in ipairs(Config.SKY_MATS) do
			table.insert(matsTxt, M.icon .. " " .. tostring((state and state.mats and state.mats[M.id]) or 0))
		end
		head.Text = string.format("💠 천정 %s  ·  천상계의 적·보스·운석 수호수가 떨어뜨린다%s  ·  초월 재료 %s", Config.formatNumber(g), (state and (state.skyBuffLeft or 0) > 0) and string.format("  ·  ✨ 영약 %d초", state.skyBuffLeft) or "", table.concat(matsTxt, " "))
		for _, it in ipairs(Config.SKY_SHOP) do
			btns[it.id].BackgroundColor3 = g >= it.cost and Color3.fromRGB(60, 120, 200) or C.panel
		end
	end
end

------------------------------------------------------------------------
-- 천층탑: 지금 층과 나가기
------------------------------------------------------------------------
local towerFrame: Frame? = nil
local towerLabel: TextLabel? = nil
UI.towerActive = false
function UI.setTower(data: any?)
	UI.towerActive = data ~= nil
	if not towerFrame then
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 132), Size = UDim2.new(0, 420, 0, 46), BackgroundColor3 = Color3.fromRGB(20, 14, 10), BackgroundTransparency = 0.2, Visible = false, Parent = gui }, { corner(10), stroke(C.gold, 1.5) })
		scaled(f)
		towerLabel = text({ Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -120, 1, 0), TextSize = 19, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, Parent = f })
		button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 96, 0, 32), Text = "🚪 나가기", TextSize = 15, BackgroundColor3 = C.red, Parent = f }, function()
			Request:FireServer("towerLeave")
		end)
		towerFrame = f
	end
	local f = towerFrame :: Frame
	f.Visible = data ~= nil
	if data and towerLabel then
		towerLabel.Text = string.format("🗼 천층탑 %d층%s  ·  최고 %d층", data.floor or 1, data.boss and " 👹" or "", data.best or 0)
	end
end

-- 1.7판 구름 미궁 진행 (가운데 위): 몇 번째 방 · 방 이름 · 나가기
local mazeFrame: Frame? = nil
local mazeLabel: TextLabel? = nil
function UI.setMaze(data: any?)
	UI.mazeActive = data ~= nil
	if not mazeFrame then
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 132), Size = UDim2.new(0, 480, 0, 46), BackgroundColor3 = Color3.fromRGB(14, 18, 30), BackgroundTransparency = 0.2, Visible = false, Parent = gui }, { corner(10), stroke(Color3.fromRGB(190, 225, 255), 1.5) })
		scaled(f)
		mazeLabel = text({ Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -120, 1, 0), TextSize = 18, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(205, 230, 255), Parent = f })
		button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 96, 0, 32), Text = "🚪 나가기", TextSize = 15, BackgroundColor3 = C.red, Parent = f }, function()
			Request:FireServer("mazeLeave")
		end)
		mazeFrame = f
	end
	local f = mazeFrame :: Frame
	f.Visible = data ~= nil
	if data and mazeLabel then
		local icon = ({ wave = "⚔", trap = "⚡", elite = "🛡", treasure = "🎁", boss = "👹" })[data.kind] or "🌀"
		mazeLabel.Text = string.format("🌀 구름 미궁 %d / %d  ·  %s %s%s", data.room or 1, data.total or 7, icon, tostring(data.name or ""), data.cleared and "  ✓ 다음 방으로" or "")
	end
end

-- 1.7판 천상 레이드 현황 (오른쪽 위): 보스 체력, 남은 시간, 내 기여와 순위, 상위 셋
local raidFrame: Frame? = nil
local raidTitle: TextLabel? = nil
local raidBar: Frame? = nil
local raidInfo: TextLabel? = nil
local raidTop: TextLabel? = nil
function UI.setRaid(data: any?)
	if not raidFrame then
		local f = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 420), Size = UDim2.new(0, 300, 0, 132), BackgroundColor3 = Color3.fromRGB(24, 10, 30), BackgroundTransparency = 0.15, Visible = false, Parent = gui }, { corner(10), stroke(Color3.fromRGB(200, 110, 255), 1.6) })
		scaled(f)
		raidTitle = text({ Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -20, 0, 24), TextSize = 18, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(230, 180, 255), Parent = f })
		local back = new("Frame", { Position = UDim2.new(0, 10, 0, 32), Size = UDim2.new(1, -20, 0, 14), BackgroundColor3 = Color3.fromRGB(30, 15, 35), Parent = f }, { corner(5) })
		raidBar = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(190, 70, 255), Parent = back }, { corner(5) })
		raidInfo = text({ Position = UDim2.new(0, 10, 0, 50), Size = UDim2.new(1, -20, 0, 22), TextSize = 15, Font = Enum.Font.GothamBold, TextColor3 = C.text, Parent = f })
		raidTop = text({ Position = UDim2.new(0, 10, 0, 74), Size = UDim2.new(1, -20, 0, 54), TextSize = 14, TextColor3 = C.dim, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Parent = f })
		raidFrame = f
	end
	local f = raidFrame :: Frame
	f.Visible = data ~= nil
	if not data then
		return
	end
	local frac = math.clamp((data.hp or 0) / math.max(1, data.maxHp or 1), 0, 1)
	;(raidTitle :: TextLabel).Text = "⚔ 레이드 · " .. tostring(data.name or "")
	;(raidBar :: Frame).Size = UDim2.fromScale(frac, 1)
	local left = math.max(0, math.floor(data.left or 0))
	;(raidInfo :: TextLabel).Text = string.format("체력 %d%%  ·  남은 %d:%02d  ·  내 기여 %.1f%%%s", math.floor(frac * 100 + 0.5), left // 60, left % 60, (data.mine or 0) * 100, (data.rank or 0) > 0 and string.format(" (%d위)", data.rank) or "")
	local lines = {}
	for i, t in ipairs(data.top or {}) do
		table.insert(lines, string.format("%d. %s  %.1f%%", i, tostring(t.name), (t.share or 0) * 100))
	end
	;(raidTop :: TextLabel).Text = #lines > 0 and table.concat(lines, "\n") or "아직 아무도 치지 않았다"
end

-- 사부의 시험 진행 (흘리기 3/6 · 남은 시간)
local trialFrame: Frame? = nil
local trialLabel: TextLabel? = nil
local trialBar: Frame? = nil
local trialData: any = nil
local trialEnd = 0
function UI.setTrial(data: any?)
	trialData = data
	if not trialFrame then
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 132), Size = UDim2.new(0, 460, 0, 54), BackgroundColor3 = Color3.fromRGB(20, 14, 10), BackgroundTransparency = 0.2, Visible = false, Parent = gui }, { corner(10), stroke(C.gold, 1.5) })
		scaled(f)
		trialLabel = text({ Position = UDim2.new(0, 14, 0, 2), Size = UDim2.new(1, -28, 0, 32), TextSize = 18, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, Parent = f })
		local track = new("Frame", { Position = UDim2.new(0, 14, 1, -16), Size = UDim2.new(1, -28, 0, 8), BackgroundColor3 = Color3.fromRGB(60, 50, 40), Parent = f }, { corner(4) })
		trialBar = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.gold, Parent = track }, { corner(4) })
		trialFrame = f
		RunService.Heartbeat:Connect(function()
			local d = trialData
			if d and trialLabel then
				local left = math.max(0, trialEnd - os.clock())
				local prog = d.kind == "survive" and string.format("%d / %d초", d.done or 0, d.need or 0) or string.format("%d / %d", d.done or 0, d.need or 0)
				trialLabel.Text = string.format("%s  ·  %s  ·  %s  ·  ⏱ %d초", d.title or "", d.goal or "", prog, math.ceil(left))
			end
		end)
	end
	local f = trialFrame :: Frame
	f.Visible = data ~= nil
	if data then
		trialEnd = os.clock() + (data.left or 0)
		if trialBar then
			TweenService:Create(trialBar, TweenInfo.new(0.2), { Size = UDim2.fromScale(math.clamp((data.done or 0) / math.max(1, data.need or 1), 0, 1), 1) }):Play()
		end
	end
end

local function buildHelp()
	local page = makePage("help")
	-- 처음 조작법 안내를 다시 본다
	button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0, 200, 0, 40), Text = "🎮 조작법 다시 보기", TextSize = 16, BackgroundColor3 = Color3.fromRGB(170, 120, 40), ZIndex = 3, Parent = page }, function()
		window.Visible = false
		local Cutscene = require(script.Parent:WaitForChild("Cutscene")) :: any
		Cutscene.controls(nil)
	end)
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
			"• 수련: 바위 들기(근골) · 목인장(체력·경공) · 폭포 명상(내공). 박자를 맞추면 2배",
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

-- 수련마다 하는 법 (수련 창 아래와 수련 안내 창에 나온다)
local TRAIN_GUIDE: { [string]: string } = {
	rock = "① 금빛 고리가 줄어든다  ② 고리가 가운데 흰 원에 겹칠 때 Space  ③ 딱 맞으면 완벽 (두 배)",
	waterfall = "① 파란 원이 커졌다 작아졌다 한다  ② 가장 커졌을 때 Space  ③ 숨 쉬듯 천천히",
	bamboo = "① 화살표를 따라 빛나는 고리로 달린다  ② 고리를 지나면 저절로 오른다  ③ Shift로 달리면 빠르다",
	dummy = "① 나무팔이 들어오며 원이 밝아진다  ② 가장 밝게 번쩍일 때 Space  ③ 실전의 흘리기 박자와 같다",
	mabo = "① 흰 바늘을 초록 칸 안에 붙잡는다  ② 누르면 오른쪽, 놓으면 왼쪽  ③ 짧게 톡톡 누르는 게 요령",
	ironpalm = "① 쇠모래가 번쩍일 때 Space  ② 바위 들기보다 조금 빠르다  ③ 근골이 크게 오른다",
	breathing = "① 기가 몸을 돌며 커진다  ② 가장 커졌을 때 Space  ③ 내공과 체력이 함께 오른다",
	simma = "마음속 마귀와 싸운다. 마구 치지 말고 F로 흘린 뒤 받아치자",
}

-- 수련 안내: 무엇을, 어디서, 어떻게
local function buildTrainGuide()
	local page = makePage("train")
	local scroll = scroller(page, UDim2.fromScale(1, 1))
	local statName = {}
	for _, s in ipairs(Config.Stats) do
		statName[s.id] = s.icon .. " " .. s.name
	end
	local lines = {
		"<b>🧘 수련 안내</b>",
		"",
		"• 수련터에 가서 T를 누르면 시작한다. 움직이면 끝난다",
		"• 박자가 맞으면 <b>좋음</b>, 딱 맞으면 <b>완벽</b> (두 배). 놓쳐도 잃는 것은 없다",
		"• 기력 같은 것은 없다. 얼마든지 수련할 수 있다",
		string.format("• 이류부터 <b>🔥 강화 수련</b> (바위에서): 박자가 빠르지만 오르는 능력치가 %d배", Config.HARD_TRAIN.mult),
		"• 경지가 오를수록 한 번에 오르는 능력치가 커진다",
		"",
	}
	local order = { "rock", "dummy", "waterfall", "mabo", "ironpalm", "breathing", "simma" }
	for _, id in ipairs(order) do
		local t = Config.Training[id]
		if t then
			local gains = {}
			if t.gains then
				for sid, n in pairs(t.gains) do
					table.insert(gains, string.format("%s +%d", statName[sid] or sid, n))
				end
			else
				table.insert(gains, statName[t.stat] or t.stat)
			end
			local realm = t.realm and Config.Realms[t.realm]
			table.insert(lines, string.format("<b>%s %s</b>  ·  %s%s", t.icon, t.name, table.concat(gains, ", "), realm and string.format("  ·  %s부터", realm.name) or ""))
			table.insert(lines, "   " .. (TRAIN_GUIDE[id] or t.desc))
			table.insert(lines, "")
		end
	end
	text({ Size = UDim2.new(1, -14, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 17, RichText = true, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = scroll, Text = table.concat(lines, "\n") })
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
		{ "🥋 숙련 최대", "testMastery" }, { "🌀 내공 무한·쿨 없음 (켜기·끄기)", "testChi" }, { "❤ 회복", "testHeal" },
		{ "🌀 다음 사부에게", "testTp" }, { "📜 이야기 다음 장", "testStory" }, { "⚔ 사부 시험 모두 통과", "testTrial" },
		{ "⛩ 관문 기록 지우기", "testGateReset" }, { "↺ 처음으로", "testReset", color = C.red },
	})
	section("🐋 2.7판: 초·창해신권 · 새 만목신권 · 새 악마 · 적 차림", {
		{ "🐋 초·창해신권 바로 쓰기 (X 고경승천)", "testStyle", "chochanghae" }, { "🐋 고경선에게 (초월의 시련)", "testSecretMaster", "chochanghae" }, { "🎒 천상 재료 +50씩 (비천 진주 포함)", "testMats" },
		{ "🐳 진 창해신권 (G 고래강림)", "testStyle", "changhae2" }, { "🎋 만목신권 (죽림창·천엽비수·신목강림)", "testStyle", "manmok" }, { "⭐ 지금 권법 숙련 20으로", "testMastery" },
		{ "🩸 초·혈마신수 (X 우두머리 악마)", "testStyle", "chohyeolma" }, { "🩸 진 혈마신수 (G 혈해만마)", "testStyle", "hyeolma2" }, { "🍄 균왕 부르기", "testBoss", "gyunwang" },
		{ "🗿 석왕 부르기", "testBoss", "seokwang" }, { "🐯 흑호 부르기", "testBoss", "heukho" }, { "🥁 뇌제 부르기", "testBoss", "noeje" },
		{ "💀 왕릉 해골병 부르기", "testEnemy", "tombguard" }, { "🐦 학익 검객 부르기", "testEnemy", "cranesword" }, { "🍄 버섯 거한 부르기", "testEnemy", "shroombrute" },
		{ "🖌 진 무극신권 바로 쓰기 (각성)", "testStyle", "mugeuk2" }, { "❄ 진 매화난무권 바로 쓰기 (각성)", "testStyle", "maehwa2" }, { "🏺 진 취팔선권 바로 쓰기 (각성)", "testStyle", "chwi2" }, { "🌸 초·매화난무권 (새 E·R·G)", "testStyle", "chomaehwa" }, { "🔥 각성선인에게", "testAwakenTp" },
		{ "☁ 천상계로 (새 섬: 운무 죽림 · 월광 호수 · 금운사)", "testSky" }, { "🎋 죽왕 부르기", "testBoss", "jukwang" }, { "🌙 월영 부르기", "testBoss", "wolyeong" },
		{ "🛕 금강천왕 부르기", "testBoss", "geumgang" }, { "🦁 사자 수호수 부르기", "testEnemy", "guardlion" }, { "🌙 월광 정령 부르기", "testEnemy", "moonspirit" },
	})
	do
		-- 2.6판: 심법 등급 체험 (모든 심법을 한 등급으로), 자동 뽑기, 새 오의·무극신권·보스 차림
		local items: { any } = {}
		for i, R in ipairs(Config.MANUAL_RARITY) do
			table.insert(items, { string.format("📜 모든 심법 [%s]로", R.name), "testManualRarity", i, color = R.color:Lerp(Color3.new(0, 0, 0), 0.55) })
		end
		table.insert(items, { "📜 두루마리 +100 (자동 뽑기용)", "testScrolls", 100 })
		table.insert(items, { "⚡ 초·벽력신권 (G 뇌성강림)", "testStyle", "chobyeok" })
		table.insert(items, { "☯ 무극신권 바로 쓰기", "testStyle", "mugeuk" })
		table.insert(items, { "🗿 석왕 부르기", "testBoss", "seokwang" })
		table.insert(items, { "👹 천존 부르기", "testBoss", "cheonjon" })
		table.insert(items, { "🍄 균왕 부르기", "testBoss", "gyunwang" })
		section("📜 2.6판: 심법 등급 체험 · 새 오의 · 보스 차림", items)
	end
	section("♻ 1.9판: 환생·업적·각성·초·혈마신수", {
		{ "♻ 환생 조건 채우기 (열린 끝 경지까지)", "testRebirthReady" }, { "♻ 환생하기", "rebirth" }, { "♻ 환생·업적 기록 지우기", "testRebirthReset" },
		{ "🩸 초·혈마신수 바로 쓰기 (초월)", "testStyle", "chohyeolma" }, { "🩸 혈월선에게 (초월의 시련)", "testSecretMaster", "chohyeolma" },
		{ "🗿 진 금강불괴 바로 쓰기", "testStyle", "geumgang2" }, { "👤 진 무영귀각 바로 쓰기", "testStyle", "muyeong2" }, { "🌊 진 태허유수장 바로 쓰기", "testStyle", "taeheo2" },
	})
	section("🌸 2.5판: 초월의 조건 (숙련 20 · 천상 재료)", {
		{ "🎒 천상 재료 +50씩", "testMats" }, { "⭐ 지금 권법 숙련 20으로", "testMastery" },
		{ "🌸 천앵선에게 (초·매화)", "testSecretMaster", "chomaehwa" }, { "🍶 만취선에게 (초·취)", "testSecretMaster", "chochwi" },
		{ "🩸 혈월선에게 (초·혈마)", "testSecretMaster", "chohyeolma" }, { "⚡ 뇌천선에게 (초·벽력)", "testSecretMaster", "chobyeok" },
	})
	section("🌳 2.4판: 만목신권·새 랜드마크", {
		{ "🌳 만목신권 바로 쓰기 (태초)", "testStyle", "manmok" }, { "🌳 목선에게 (만목원)", "testSecretMaster", "manmok" },
	})
	section("👹 2.3판: 새 생김새 적·뇌고천무·벚꽃나무", {
		{ "⚡ 초·벽력신권 바로 쓰기 (X 뇌고천무)", "testStyle", "chobyeok" }, { "🌸 초·매화난무권 바로 쓰기 (X 벚꽃나무)", "testStyle", "chomaehwa" },
		{ "🗿 돌 거인 부르기", "testEnemy", "stonegolem" }, { "😈 화염 소악귀 부르기", "testEnemy", "flameimp" }, { "👻 모래 망령 부르기", "testEnemy", "sandwraith" },
		{ "🐦 학익 검객 부르기", "testEnemy", "cranesword" }, { "💀 왕릉 해골병 부르기", "testEnemy", "tombguard" }, { "🍄 버섯 거한 부르기", "testEnemy", "shroombrute" },
		{ "💧 물보라 정령 부르기", "testEnemy", "waterspirit" }, { "🐍 독수 뱀 자객 부르기", "testEnemy", "swampfang" }, { "🐸 늪 거한 부르기", "testEnemy", "bogbrute" },
		{ "🐺 혈랑 (늑대) 부르기", "testBoss", "hyeolrang" }, { "🍄 균왕 부르기", "testBoss", "gyunwang" }, { "🔥 염봉 (봉황) 부르기", "testBoss", "yeombong" },
	})
	section("⚡ 2.0판: 새 각성·초·벽력신권·각성선인", {
		{ "🔥 진 열화신권 바로 쓰기", "testStyle", "yeolhwa2" }, { "🐋 진 창해신권 바로 쓰기", "testStyle", "changhae2" }, { "🌀 진 풍신각 바로 쓰기", "testStyle", "pungsin2" },
		{ "⚡ 초·벽력신권 바로 쓰기 (초월)", "testStyle", "chobyeok" }, { "⚡ 뇌천선에게 (초월의 시련)", "testSecretMaster", "chobyeok" }, { "🔥 각성선인에게", "testAwakenTp" },
		{ "🩸 진 혈마신수 바로 쓰기", "testStyle", "hyeolma2" }, { "🐲 진 천룡파천장 바로 쓰기", "testStyle", "cheonryong2" }, { "🌩 진 벽력신권 바로 쓰기", "testStyle", "byeokryeok2" },
	})
	section("🗼 베타 13: 천층탑·심법·비무·컷씬", {
		{ "📜 심법 두루마리 +10", "testScrolls" }, { "📜 심법 두루마리 +100 (자동 뽑기)", "testScrolls", 100 }, { "💰 은자 +300000 (뽑기 10번)", "testCoins", 300000 }, { "🗼 다음 보스 층으로 (탑 안에서)", "testTower" },
		{ "⚔ 비무 99승으로 (한 번 더 이기면 무쌍신권)", "testPvp" }, { "⚔ 무쌍신권 바로 쓰기", "testStyle", "musang" }, { "🎬 컷씬 기록 지우기 (다시 보기)", "testSeen" },
		{ "🗼 이 층 적 모두 쓰러뜨리기 (탑 안에서)", "testTower", "clear" },
	})
	section("☁ 베타 14: 천상계·아공신권·탈것", {
		{ "☁ 천상계로 가기", "testSky" }, { "✴ 반선 경지로 (능력치)", "testStats", 9477000 }, { "🧭 아공선인에게 가기", "testSecretMaster", "agong" },
		{ "📍 아공선인 길잡이", "guide:agong" }, { "🌌 아공신권 바로 쓰기", "testStyle", "agong" }, { "💰 은자 +2,000,000 (탈것)", "testCoins", 2000000 },
		{ "🐉 청룡 탈것 (테스트로 켜기)", "testPremium", "dragon" }, { "💠 천정 +1000", "testGems" }, { "☄ 운석 지금 떨어뜨리기 (천상계에서)", "testMeteor" }, { "☁ 운류장 바로 쓰기", "testStyle", "unryu" },
		{ "🌠 성하신권 바로 쓰기", "testStyle", "seongha" }, { "🧭 성하노군에게 가기", "testSecretMaster", "seongha" }, { "🧭 운류자에게 가기", "testSecretMaster", "unryu" },
		{ "👹 뇌제 부르기", "testBoss", "noeje" }, { "👹 성군 부르기", "testBoss", "seonggun" }, { "👹 천존 부르기", "testBoss", "cheonjon" }, { "⚔ PvP 끄기 열기 (쓰러진 셈)", "testPvpUnlock" },
	})
	section("🎯 수련 목인·시간", {
		{ "🎯 수련 목인 세우기", "testDummy" }, { "🧹 테스트로 부른 것 치우기", "testClear" }, { "⏸ 시간 멈춤·흐름", "testTime", "freeze" },
		{ "🌅 새벽 (6시)", "testTime", 6 }, { "☀ 한낮 (12시)", "testTime", 12 }, { "🌇 저녁 (18시)", "testTime", 18 },
		{ "🌙 한밤 (0시)", "testTime", 0 }, { "⏩ 3시간 뒤로", "testTime", "+3" },
		{ "💎 두 배 수련 (테스트로 켜기)", "testPremium", "train2x" }, { "🤖 자동 수련 (테스트로 켜기)", "testPremium", "autoTrain" }, { "⚙ 고급 자동 수련 (테스트로 켜기)", "testPremium", "autoTrain2" },
	})
	-- 수련 자리로 바로 (종류마다 첫 자리)
	local trainItems = {}
	for _, id in ipairs({ "rock", "dummy", "waterfall", "mabo", "ironpalm", "breathing", "simma", "geumjong", "cheongeun", "jucheon", "heogong", "cheonsang" }) do
		local t = Config.Training[id]
		if t then
			table.insert(trainItems, { "🌀 " .. t.icon .. " " .. t.name, "testTrainTp", id })
		end
	end
	section("🏋 수련 텔레포트", trainItems)
	-- 권법 테스트: 어떤 권법이든 바로 (숙련 최대·내공 가득)
	local styleItems = {}
	for _, st in ipairs(Config.Styles) do
		table.insert(styleItems, { st.icon .. " " .. st.name .. " [" .. st.grade .. "]", "testStyle", st.id, color = st.color:Lerp(Color3.new(0, 0, 0), 0.55) })
	end
	section("🥋 권법 테스트 (바로 익혀 숙련 최대로)", styleItems)
	section("🔓 시크릿 테스트 (숨은 권법 얻는 길)", {
		{ "📖 비급 조각 +1", "testSecret", "fragment" }, { "🧭 다음 비급 조각으로", "testSecret", "fragmentTp" }, { "🌌 무극신권 얻기", "testSecret", "mugeuk" },
		{ "🩸 혈마신수 얻기", "testSecret", "hyeolma" }, { "🔒 숨은 권법 다시 잠그기", "testSecret", "lock" }, { "👹 혈마 부르기", "testBoss", "hyeolma" },
		{ "🧭 숨은 사부에게 가기", "testSecretMaster" }, { "📍 숨은 사부 길잡이", "guide:gaecheon" }, { "✨ 무극 경지로 (능력치)", "testStats", 2609500 },
		{ "⬆ 지금 권법 승급 최대", "testBreak" }, { "👹 천마 부르기", "testBoss", "cheonma" }, { "👑 천제신권 바로 쓰기", "testStyle", "gaecheon" },
		{ "🌑 파천신권 얻기 (천마 처치 보상)", "testSecret", "pacheon" }, { "🌪 풍신각 바로 쓰기", "testStyle", "pungsin" }, { "✴ 천외천 경지로 (능력치)", "testStats", 125000000 }, { "🌸 초·매화난무권 바로 쓰기 (초월)", "testStyle", "chomaehwa" }, { "🌸 천앵선에게 (초월의 시련)", "testSecretMaster", "chomaehwa" }, { "🍾 초·취팔선권 바로 쓰기 (초월)", "testStyle", "chochwi" }, { "🍾 만취선에게 (초월의 시련)", "testSecretMaster", "chochwi" }, { "⚔ 천겁 레이드 지금 (천상계에서)", "testRaid", true }, { "🌀 구름 미궁 바로 들어가기", "testMaze", true },
		{ "🧭 시원자에게 가기 (태초신권)", "testSecretMaster", "taecho" }, { "📍 시원자 길잡이", "guide:taecho" }, { "✴ 태초신권 바로 쓰기", "testStyle", "taecho" },
		{ "🧭 권존에게 가기 (일월신권)", "testSecretMaster", "ilwol" }, { "📍 권존 길잡이", "guide:ilwol" }, { "☀ 일월신권 바로 쓰기", "testStyle", "ilwol" },
		{ "🧭 영겁노인에게 가기 (영겁신권)", "testSecretMaster", "yeonggeop" }, { "📍 영겁노인 길잡이", "guide:yeonggeop" }, { "⏳ 영겁신권 바로 쓰기", "testStyle", "yeonggeop" },
	})
	-- 모든 권법 얻는 법 (테스트 창에만 적는다)
	order += 1
	text({ Size = UDim2.new(1, -12, 0, 26), Text = "📖 모든 권법 얻는 법", TextSize = 19, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, LayoutOrder = order, Parent = list })
	local how = {}
	local HIDDEN_HOW: { [string]: string } = {
		mugeuk = "강호 곳곳의 비급 조각 다섯을 모두 줍는다 (지도에 안 나온다). 자리: ",
		hyeolma = "북동쪽 끝 혈교 본산의 보스 '혈마'를 쓰러뜨리면 바로 얻는다",
		pacheon = "북서쪽 끝 허공 균열의 보스 '천마'를 쓰러뜨리면 바로 얻는다",
		musang = "마을 비무대에서 다른 사람을 백 번 이기면 바로 얻는다 (비무 승리는 능력치 창과 순위표에 나온다)",
	}
	for _, st in ipairs(Config.Styles) do
		local m = Config.MASTERS[st.id]
		local line: string
		if st.starter then
			line = "처음부터 가지고 시작한다 (청운 장로에게 받는다)"
		elseif st.awakenOf then
			local base = Config.STYLE_BY_ID[st.awakenOf]
			local A = Config.AWAKEN_STYLE
			line = string.format("각성 권법: %s 숙련 %d + 깨달음(승급) %d번 + %s 경지%s + 💰 %s → 상급 수련장의 각성선인 곁에서 권법 창의 '🔥 각성 시련' → 각성한 그림자(체력 %d배)를 넘으면 바로 얻는다",
				base and base.name or st.awakenOf, Config.MASTERY_FULL, #Config.BREAKTHROUGH, Config.Realms[A.realm].name, st.rebirthReq and string.format(" + ♻ 환생 %d번", st.rebirthReq) or "", Config.formatNumber(A.coins), A.trialHp)
		elseif HIDDEN_HOW[st.id] then
			line = HIDDEN_HOW[st.id]
			if st.id == "mugeuk" then
				local spots = {}
				for _, fr in ipairs(Config.Fragments) do
					table.insert(spots, fr.hint)
				end
				line ..= table.concat(spots, " · ")
			end
		elseif m then
			local need = {}
			if st.realmReq then
				table.insert(need, Config.Realms[st.realmReq].name .. " 경지")
			end
			if st.styleReq then
				local rq = Config.STYLE_BY_ID[st.styleReq]
				table.insert(need, (rq and rq.name or st.styleReq) .. "을(를) 익힌 뒤")
			end
			local tk = Config.TRIAL_KINDS[(Config.trialNeed(st.id))]
			line = string.format("%s%s의 %s에게 가서 T → %s을 넘고 → 은자를 바쳐 배운다%s%s",
				#need > 0 and ("[" .. table.concat(need, ", ") .. "] ") or "", m.region, m.name, tk and (tk.icon .. " " .. tk.title) or "시험",
				m.secret and " (숨은 사부: 지도에 안 나온다)" or "", st.trialHp and " · 궁극의 시험 (1.5배)" or "")
		else
			line = st.unlockHint or "?"
		end
		table.insert(how, string.format("<b>%s %s</b> [%s]\n   %s", st.icon, st.name, st.grade, line))
	end
	order += 1
	text({ Size = UDim2.new(1, -14, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 16, RichText = true, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = order, Parent = list, Text = table.concat(how, "\n") })
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
local trainGuide: TextLabel
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
	local J = Config.TRAIN_JUDGE
	local period = (basePeriod or J.period) * (hard and H.period / J.period or 1)
	return circle, function(): number
		local p = ((os.clock() - start) % period) / period
		return p
	end, function()
		local p = ((os.clock() - start) % period) / period
		-- 고리가 하얀 원에 겹칠 때 (p ≈ 1 또는 0)
		local off = math.min(p, 1 - p)
		local grade = off < (hard and H.perfect or J.perfect) and "perfect" or (off < (hard and H.good or J.good) and "good" or "miss")
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
	trainGuide.Text = "📘 " .. (TRAIN_GUIDE[kind] or info.desc)
	-- 상급 수련은 앞의 수련과 같은 판정 화면을 쓴다
	kind = info.ui or kind
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
			if d < Config.TRAIN_JUDGE.ring then
				send("ring", idx)
				idx = idx % #list + 1
			end
		end)
		return
	end
	if kind == "mabo" then
		-- 마보 참장: 기울어지는 몸을 가운데(초록)에 붙잡아 둔다. 누르면 오른쪽, 가만두면 바람에 밀려 왼쪽
		local bar = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 300, 0, 26), BackgroundColor3 = Color3.fromRGB(60, 40, 35), Parent = trainArea }, { corner(8) })
		local zoneW = hard and Config.TRAIN_JUDGE.maboHard or Config.TRAIN_JUDGE.mabo
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(zoneW, 1), BackgroundColor3 = C.green, BackgroundTransparency = 0.25, Parent = bar }, { corner(8) })
		local needle = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 8, 1, 14), BackgroundColor3 = Color3.new(1, 1, 1), Parent = bar }, { corner(4) })
		local x, v, acc = 0.5, 0, 0
		trainPress = function()
			v += 0.55
		end
		trainConn = RunService.RenderStepped:Connect(function(dt: number)
			local t = os.clock()
			local gust = math.sin(t * 1.3) * 0.2 + math.sin(t * 2.9) * 0.12 * (hard and 1.6 or 1)
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
	topInfo.Text = string.format("[%s] ⚔ 전투력 %s   💰 %s   🧪 %d   💪%s ❤%s 🍃%s 🌀%s", realm.name, Config.formatNumber(s.power or 0), Config.formatNumber(s.coins), s.potions, Config.formatNumber(s.stats.str), Config.formatNumber(s.stats.vit), Config.formatNumber(s.stats.agi), Config.formatNumber(s.stats.chi))
	if s.gateNext then
		topInfo.Text ..= "   ⛩ 관문 열림"
	end
	if s.autoOn and s.premium and (s.premium.autoTrain or s.premium.autoTrain2) then
		topInfo.Text ..= s.premium.autoTrain2 and "   ⚙ 고급 자동 수련" or "   🤖 자동 수련"
	end
	topInfo.TextColor3 = realm.color
	local menu = gui:FindFirstChild("Menu", true)
	local testBtn = menu and menu:FindFirstChild("TestButton")
	if testBtn then
		testBtn.Visible = s.tester == true
	end
	-- 들판 PvP: 켜짐(붉은) / 꺼짐(푸른). 한 번 쓰러지기 전에는 끌 수 없다 (자물쇠)
	local pvpBtn = menu and menu:FindFirstChild("PvpButton")
	if pvpBtn and pvpBtn:IsA("TextButton") then
		pvpBtn.Text = s.pvpOff and "🕊 PvP 꺼짐" or ((s.pvpUnlocked and "⚔" or "🔒") .. " PvP 켜짐")
		pvpBtn.BackgroundColor3 = s.pvpOff and Color3.fromRGB(50, 90, 140) or Color3.fromRGB(140, 40, 35)
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

-- 1.5판: 지역마다 권장 전투력 (서버가 적들의 전투력으로 정해 ReplicatedStorage.KwonRegionPower에 적어 둔다)
local function regionPower(id: string): (number?, number?)
	local f = game:GetService("ReplicatedStorage"):FindFirstChild("KwonRegionPower")
	if not f then
		return nil, nil
	end
	local a, b = f:GetAttribute(id), f:GetAttribute(id .. "_boss")
	return (type(a) == "number" and a or nil), (type(b) == "number" and b or nil)
end
UI.regionPower = regionPower
-- 권장 전투력과 내 전투력을 견준 한 줄 (위험·알맞음·여유)
local function powerAdvice(rec: number): string
	local mine = state and state.power or 0
	if mine <= 0 then
		return string.format("⚔ 권장 전투력 %s", Config.formatNumber(rec))
	end
	local r = mine / rec
	local tag = r < 0.6 and "⚠ 위험" or (r < 1 and "조금 버거움" or (r < 2.5 and "알맞음" or "여유"))
	return string.format("⚔ 권장 %s (내 %s · %s)", Config.formatNumber(rec), Config.formatNumber(mine), tag)
end
-- 1.9.1판: 지도 글자 정돈. 지역 이름과 권장 전투력은 한 덩어리 (지역 가운데)로 묶고,
-- 글자끼리 겹치면 덜 중요한 것부터 감춘다. 작은 지도는 나를 따라 움직이고 (가까운 곳을 크게), 큰 지도는 온 세상을 다 보여 준다 (휠·끌기로 확대·이동)
local regionTags: { [string]: { label: TextLabel, name: string } } = {}
local mapCanvas: Frame
local skyCanvas: Frame? = nil
local mapSky = false -- 2.7.1판: 지금 보이는 지도가 천상 지도인가
type MapText = { label: TextLabel, prio: number, small: number, big: number, base: UDim2? }
local mapTexts: { MapText } = {}
local skyTexts: { MapText } = {}
-- 지금 보이는 지도 판과 그 위의 글자들
local function activeCanvas(): Frame
	return (mapSky and skyCanvas) or mapCanvas
end
-- 지도 위 권장 전투력: 내 전투력에 견주어 빨강(위험)·주황(버거움)·초록(알맞음)·회색(여유)
local function refreshRec()
	local mine = state and state.power or 0
	for id, tg in pairs(regionTags) do
		local rec, boss = regionPower(id)
		local l = tg.label
		if not rec then
			l.Text = tg.name
		else
			local r = mine > 0 and mine / rec or 1
			local col = r < 0.6 and "#FF6A5F" or (r < 1 and "#FFBE5A" or (r < 2.5 and "#96F082" or "#CDCDCD"))
			local line = string.format('<font color="%s">⚔%s</font>', col, Config.formatNumber(rec))
			if boss and mapBig then
				line ..= string.format('  <font color="#FF9A9A">👹%s</font>', Config.formatNumber(boss))
			end
			l.Text = tg.name .. "\n" .. line
		end
	end
end

-- 2.7.1판: 천상 전용 지도. 천상계에 오르면 지도가 저절로 천상 지도로 바뀌고, 큰 지도의 ☁ 단추로 땅과 하늘을 골라 볼 수도 있다
local SKY_MAP_C = Vector3.new(0, 0, -180) -- 천상 지도의 가운데 (섬들이 남북으로 길게 늘어서 있다)
local SKY_MAP_H = 1700 -- 천상 지도 한 변의 절반
local function mapFrameOf(sky: boolean): (Vector3, number)
	if sky then
		return SKY_MAP_C, SKY_MAP_H
	end
	return Vector3.zero, Config.WORLD_HALF
end
local function isSkyPos(p: Vector3): boolean
	return Config.SKY ~= nil and p.Y > Config.SKY.y - 300
end
local function mapUV(p: Vector3, sky: boolean?): UDim2
	local c, H = mapFrameOf(if sky == nil then mapSky else sky)
	return UDim2.fromScale(math.clamp((p.X - c.X + H) / (2 * H), 0, 1), math.clamp((p.Z - c.Z + H) / (2 * H), 0, 1))
end

local MAP_SMALL = 250
local MAP_BIG = 760
local SMALL_SPAN = 870 -- 작은 지도 한 변에 보이는 넓이 (칸). 2.2판: 1300 → 870 (1.5배 크게 보인다)
local bigZoom = 1
local bigCenter = Vector3.zero
local function viewZoom(): number
	local _, H = mapFrameOf(mapSky)
	return mapBig and bigZoom or (2 * H) / SMALL_SPAN
end
-- 지도 판을 옮긴다: 작은 지도는 내가 가운데, 큰 지도는 고른 가운데 (세상 밖이 보이지 않게 묶는다)
local function applyView(pos: Vector3?)
	if not mapCanvas then
		return
	end
	local C0, H = mapFrameOf(mapSky)
	local canvas = activeCanvas()
	local z = viewZoom()
	local c = mapBig and bigCenter or (pos or C0)
	local u, v = (c.X - C0.X + H) / (2 * H), (c.Z - C0.Z + H) / (2 * H)
	if mapBig then
		local half = 0.5 / z
		u = math.clamp(u, half, 1 - half)
		v = math.clamp(v, half, 1 - half)
		bigCenter = Vector3.new(u * 2 * H - H + C0.X, 0, v * 2 * H - H + C0.Z)
	end
	canvas.Size = UDim2.fromScale(z, z)
	canvas.Position = UDim2.fromScale(0.5 - u * z, 0.5 - v * z)
end
-- 겹치는 글자 비켜 놓기 (중요한 것부터 자리를 잡는다). 2.1판: 감추지 않는다. 위아래로 비켜서라도 다 보인다
local function declutter()
	if not mapInner then
		return
	end
	-- 지도 판의 크기 (UIScale을 곱하기 전 값: 글자 크기도 같은 단위라 그대로 견준다)
	local side = (mapBig and MAP_BIG or MAP_SMALL) - 12
	local inner = Vector2.new(side, side)
	local z = viewZoom()
	local cs = inner.X * z
	local canvas = activeCanvas()
	local ox = canvas.Position.X.Scale * inner.X
	local oy = canvas.Position.Y.Scale * inner.Y
	local placed: { { number } } = {}
	for _, t in ipairs(mapSky and skyTexts or mapTexts) do
		local l = t.label
		local size = mapBig and t.big or t.small
		t.base = t.base or UDim2.fromScale(l.Position.X.Scale, l.Position.Y.Scale)
		local base = t.base :: UDim2
		local px = ox + base.X.Scale * cs
		local py = oy + base.Y.Scale * cs
		local plain = string.gsub(l.Text, "<[^>]+>", "")
		local lines = string.split(plain, "\n")
		local wide = 0
		for _, ln in ipairs(lines) do
			wide = math.max(wide, utf8.len(ln) or #ln)
		end
		local w = wide * size * 0.62 + 4
		local h = #lines * size * 1.15
		local x0, x1 = px - w / 2, px + w / 2
		local inView = wide > 0 and x1 > 0 and py + h / 2 > 0 and x0 < inner.X and py - h / 2 < inner.Y
		-- 빈 자리를 찾아 위아래로 조금씩 비킨다 (끝내 못 찾으면 제자리에 겹쳐서라도 보인다)
		local dy = 0
		if inView then
			for _, k in ipairs({ 0, 1, -1, 2, -2, 3, -3 }) do
				local y0, y1 = py - h / 2 + k * h, py + h / 2 + k * h
				local free = true
				for _, r in ipairs(placed) do
					if x0 < r[3] and x1 > r[1] and y0 < r[4] and y1 > r[2] then
						free = false
						break
					end
				end
				if free then
					dy = k * h
					break
				end
			end
			table.insert(placed, { x0, py - h / 2 + dy, x1, py + h / 2 + dy })
		end
		l.Position = UDim2.new(base.X.Scale, 0, base.Y.Scale, dy)
		l.Visible = wide > 0
	end
end
local zoomBtns: { GuiObject } = {}
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
	for _, list in ipairs({ mapTexts, skyTexts }) do
		for _, t in ipairs(list) do
			t.label.TextSize = mapBig and t.big or t.small
		end
	end
	for _, b in ipairs(zoomBtns) do
		b.Visible = mapBig
	end
	refreshRec()
	applyView(myPos())
	task.defer(declutter)
end

-- 길잡이·이야기 표시는 그 자리가 지금 보이는 지도 (땅 또는 하늘) 위에 있을 때만
local guideAt: Vector3? = nil
local storyMarkAt: Vector3? = nil
local function showMark(mark: GuiObject?, at: Vector3?)
	if not mark then
		return
	end
	local g = mark :: GuiObject
	g.Visible = at ~= nil and isSkyPos(at) == mapSky
	if at then
		g.Position = mapUV(at)
	end
end
local skyBtn: TextButton? = nil
local skyTitle: TextLabel? = nil
local inSkyNow = false
-- 지도를 땅 또는 하늘로 바꾼다 (나·적 점·길잡이를 그 판으로 옮긴다)
local function setMapWorld(sky: boolean)
	local sc = skyCanvas
	if sky == mapSky or not sc then
		return
	end
	mapSky = sky
	mapCanvas.Visible = not sky
	sc.Visible = sky
	local cv = activeCanvas()
	for _, d in ipairs(mapDots) do
		d.Parent = cv
	end
	mapMe.Parent = cv
	mapGuide.Parent = cv
	if storyMark then
		storyMark.Parent = cv
	end
	mapInner.BackgroundColor3 = sky and Color3.fromRGB(150, 185, 225) or Color3.fromRGB(70, 95, 120)
	if skyBtn then
		skyBtn.Text = sky and "⛰" or "☁"
	end
	if skyTitle then
		skyTitle.Visible = sky
	end
	bigZoom = 1
	bigCenter = (mapFrameOf(sky))
	showMark(mapGuide, guideAt)
	showMark(storyMark, storyMarkAt)
	placeMap()
end

function UI.toggleMap()
	mapBig = not mapBig
	if mapBig then
		-- 큰 지도는 온 세상부터
		bigZoom = 1
		bigCenter = (mapFrameOf(mapSky))
		placeMap()
	elseif mapSky ~= inSkyNow then
		-- 작은 지도는 늘 내가 서 있는 세상
		setMapWorld(inSkyNow)
	else
		placeMap()
	end
end

local function zoomBy(k: number)
	bigZoom = math.clamp(bigZoom * k, 1, 6)
	applyView(nil)
	declutter()
end

-- 천상 지도: 구름 바다 위의 섬과 다리, 섬 이름과 권장 전투력, 보스, 천궁의 문과 가게, 천상의 사부
local function buildSkyMap()
	local SKY = Config.SKY
	if not SKY then
		return
	end
	local cv = new("Frame", { Name = "SkyCanvas", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(196, 214, 238), BorderSizePixel = 0, Visible = false, ZIndex = 5, Parent = mapInner })
	skyCanvas = cv
	local H = SKY_MAP_H
	local function label(at: Vector3, t: string, small: number, big: number, color: Color3, z: number, prio: number): TextLabel
		local l = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = mapUV(at, true), Size = UDim2.new(0, 10, 0, 10), AutomaticSize = Enum.AutomaticSize.XY, Text = t, TextSize = small, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.15, TextWrapped = false, RichText = true, ZIndex = z, Parent = cv })
		table.insert(skyTexts, { label = l, prio = prio, small = small, big = big })
		return l
	end
	-- 흘러가는 구름 바다 (옅은 흰 구름 덩이)
	for i = 1, 18 do
		local a = i * 2.39996
		local rr = 0.12 + 0.36 * ((i * 0.618) % 1)
		local w = 0.1 + 0.08 * ((i * 0.37) % 1)
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + math.cos(a) * rr, 0.5 + math.sin(a) * rr), Size = UDim2.fromScale(w, w * 0.55), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 5, Parent = cv }, { corner(99) })
	end
	-- 다리 (숨은 다리는 그리지 않는다)
	for _, br in ipairs(SKY.bridges) do
		local a, b = SKY.islands[br[1]], SKY.islands[br[2]]
		if a and b and not br.hidden and not a.hidden and not b.hidden then
			local d = b.at - a.at
			new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = mapUV((a.at + b.at) / 2, true), Size = UDim2.new(Vector3.new(d.X, 0, d.Z).Magnitude / (2 * H), 0, 0, 4), Rotation = math.deg(math.atan2(d.Z, d.X)), BackgroundColor3 = Color3.fromRGB(240, 228, 196), BorderSizePixel = 0, ZIndex = 6, Parent = cv }, { stroke(Color3.fromRGB(150, 130, 95), 1) })
		end
	end
	-- 섬
	for _, isl in ipairs(SKY.islands) do
		if not isl.hidden then
			local d = 2 * isl.radius / (2 * H)
			new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = mapUV(isl.at, true), Size = UDim2.fromScale(d, d), BackgroundColor3 = isl.ground, BorderSizePixel = 0, ZIndex = 7, Parent = cv }, { corner(9999), stroke(Color3.new(1, 1, 1), 2) })
			if isl.boss then
				label(isl.boss.at, "👹", 13, 16, C.red, 9, 3)
			elseif isl.raid then
				label(isl.at, "⚔", 14, 17, C.red, 9, 3)
			end
			local tagAt = isl.at + Vector3.new(0, 0, isl.safe and isl.radius * 0.72 or 0)
			local tag = label(tagAt, isl.name, 11, 13, Color3.new(1, 1, 1), 9, isl.safe and 2.5 or 2)
			if not isl.safe then
				regionTags["sky_" .. isl.id] = { label = tag, name = isl.name }
			end
		end
	end
	-- 천궁 안의 문과 가게 (작은 지도에선 표시만, 이름은 덜 중요)
	local town = SKY.islands[1].at
	for _, it in ipairs({
		{ Vector3.new(-100, 0, 100), "⬇", "땅으로" },
		{ Vector3.new(100, 0, -100), "🏮", "객잔" },
		{ Vector3.new(100, 0, 100), "💎", "천상 상점" },
		{ Vector3.new(72, 0, 34), "🗼", "천층탑" },
		{ Vector3.new(72, 0, -34), "🌀", "구름 미궁" },
		{ Vector3.new(-78, 0, 30), "⚔", "투기장 문" },
	}) do
		label(town + it[1], it[2], 12, 15, Color3.new(1, 1, 1), 8, 1.5)
		label(town + it[1] + Vector3.new(0, 0, 34), it[3], 9, 11, Color3.fromRGB(70, 60, 45), 8, 1)
	end
	-- 천상의 사부 (숨은 사부는 지도에 없다). 찾기 전엔 물음표만
	for id, m in pairs(Config.MASTERS) do
		local style = Config.STYLE_BY_ID[id]
		if style and not m.secret and isSkyPos(m.at) and not masterMarks[id] then
			local ring = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = mapUV(m.at, true), Size = UDim2.new(0, 22, 0, 22), BackgroundTransparency = 1, ZIndex = 8, Parent = cv }, { corner(99) })
			local st = new("UIStroke", { Color = style.color, Thickness = 2, Enabled = false, Parent = ring })
			local icon = label(m.at, "❓", 14, 17, Color3.fromRGB(90, 80, 70), 9, 3)
			masterMarks[id] = { stroke = st, icon = icon, color = style.color, glyph = style.icon }
		end
	end
	table.sort(skyTexts, function(x, y)
		return x.prio > y.prio
	end)
	skyTitle = text({ Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(0, 160, 0, 20), Text = "☁ 천상계", TextSize = 15, Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.1, Visible = false, ZIndex = 12, Parent = mapFrame })
	refreshRec()
end

local function buildMap()
	mapFrame = new("Frame", { Name = "Map", BackgroundColor3 = Color3.fromRGB(40, 50, 35), BackgroundTransparency = 0.1, ZIndex = 5, Parent = gui }, { corner(12), stroke(C.line, 2) })
	scaled(mapFrame, "map")
	mapInner = new("Frame", { Position = UDim2.new(0, 6, 0, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundColor3 = Color3.fromRGB(70, 95, 120), ClipsDescendants = true, ZIndex = 5, Parent = mapFrame }, { corner(8) })
	-- 모든 것을 얹는 판 (작은 지도에서는 크게 키워 나를 따라 옮긴다)
	mapCanvas = new("Frame", { Name = "Canvas", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(95, 125, 75), BorderSizePixel = 0, ZIndex = 5, Parent = mapInner })
	local canvas = mapCanvas
	local H = Config.WORLD_HALF
	local function rect(center: Vector3, size: Vector3, color: Color3, z: number): Frame
		return new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = mapUV(center), Size = UDim2.fromScale(size.X / (2 * H), size.Z / (2 * H)), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z, Parent = canvas })
	end
	local function label(at: Vector3, t: string, small: number, big: number, color: Color3, z: number, prio: number): TextLabel
		local l = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = mapUV(at), Size = UDim2.new(0, 10, 0, 10), AutomaticSize = Enum.AutomaticSize.XY, Text = t, TextSize = small, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.15, TextWrapped = false, RichText = true, ZIndex = z, Parent = canvas })
		table.insert(mapTexts, { label = l, prio = prio, small = small, big = big })
		return l
	end
	-- 길
	for _, road in ipairs(Config.Roads) do
		for i = 1, #road - 1 do
			local a, b = road[i], road[i + 1]
			local d = b - a
			new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = mapUV((a + b) / 2), Size = UDim2.new(d.Magnitude / (2 * H), 0, 0, 3), Rotation = math.deg(math.atan2(d.Z, d.X)), BackgroundColor3 = Color3.fromRGB(190, 165, 120), BorderSizePixel = 0, ZIndex = 6, Parent = canvas })
		end
	end
	-- 지역과 사부: 표시(사부·보스)는 늘 보이고, 이름과 권장 전투력은 한 덩어리
	for _, r in ipairs(Config.Regions) do
		if not r.noGround then
			local f = rect(r.center, r.size, r.ground, 6)
			f.BackgroundTransparency = 0.15
			local style = r.master and Config.STYLE_BY_ID[r.master]
			local tagAt = r.center
			if style then
				-- 사부 자리는 찾기 전엔 물음표만
				local st = new("UIStroke", { Color = style.color, Thickness = 2, Enabled = false, Parent = f })
				local icon = label(r.masterAt, "❓", 14, 17, Color3.fromRGB(220, 210, 190), 9, 3)
				masterMarks[r.master] = { stroke = st, icon = icon, color = style.color, glyph = style.icon }
				tagAt = r.masterAt + Vector3.new(0, 0, 95)
			elseif r.boss then
				label(r.boss.at, "👹", 13, 16, C.red, 9, 3)
			end
			local tag = label(tagAt, r.name, 11, 12, Color3.new(1, 1, 1), 9, r.id == "village" and 2.5 or 2)
			regionTags[r.id] = { label = tag, name = r.name }
		end
	end
	-- 큰 볼거리 (표시는 조금 덜 중요, 이름은 가장 덜 중요)
	for _, lm in ipairs(Config.Landmarks) do
		label(lm.at, lm.icon, 13, 15, Color3.new(1, 1, 1), 8, 1.5)
		label(lm.at + Vector3.new(0, 0, 80), lm.name, 10, 11, Color3.fromRGB(230, 225, 210), 8, 1)
	end
	table.sort(mapTexts, function(x, y)
		return x.prio > y.prio
	end)
	refreshRec()
	task.spawn(function()
		local f = game:GetService("ReplicatedStorage"):WaitForChild("KwonRegionPower", 60)
		if f then
			refreshRec()
			f.AttributeChanged:Connect(function()
				refreshRec()
				declutter()
			end)
		end
	end)
	-- 적 점 (가까운 것만)
	for i = 1, 50 do
		mapDots[i] = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 5, 0, 5), BackgroundColor3 = Color3.fromRGB(255, 60, 50), BorderSizePixel = 0, Visible = false, ZIndex = 10, Parent = canvas }, { corner(99) })
	end
	mapGuide = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1, Visible = false, ZIndex = 11, Parent = canvas }, { corner(99), stroke(Color3.fromRGB(255, 240, 120), 3) })
	storyMark = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 14, 0, 14), Rotation = 45, BackgroundColor3 = Color3.fromRGB(255, 170, 60), BorderSizePixel = 0, Visible = false, ZIndex = 11, Parent = canvas }, { stroke(Color3.new(0, 0, 0), 1.5) })
	mapMe = text({ AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 20, 0, 20), Text = "▲", TextSize = 18, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0, TextWrapped = false, ZIndex = 12, Parent = canvas })
	text({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -6), Size = UDim2.new(0, 220, 0, 18), Text = "M: 지도 크게 · 휠: 확대", TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Right, TextStrokeTransparency = 0.2, ZIndex = 12, Parent = mapFrame })
	-- 큰 지도: 확대·축소·내 자리 단추, 휠과 끌기
	for i, spec in ipairs({ { "＋", 1.4 }, { "－", 1 / 1.4 }, { "◎", 0 } }) do
		local b = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10 + (i - 1) * 46), Size = UDim2.new(0, 40, 0, 40), Text = spec[1], TextSize = 22, BackgroundColor3 = C.panel2, ZIndex = 13, Visible = false, Parent = mapFrame }, function()
			if spec[2] == 0 then
				bigZoom = math.max(bigZoom, 3)
				bigCenter = myPos() or Vector3.zero
				applyView(nil)
				declutter()
			else
				zoomBy(spec[2])
			end
		end)
		table.insert(zoomBtns, b)
	end
	-- 땅 ↔ 하늘 지도 바꾸기
	skyBtn = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10 + 3 * 46), Size = UDim2.new(0, 40, 0, 40), Text = "☁", TextSize = 22, BackgroundColor3 = C.panel2, ZIndex = 13, Visible = false, Parent = mapFrame }, function()
		setMapWorld(not mapSky)
	end)
	table.insert(zoomBtns, (skyBtn :: any) :: GuiObject)
	local dragging = false
	local dragLast = Vector3.zero
	-- (입력 연결이 실패해도 지도는 그대로 쓰이게)
	pcall(function()
		mapInner.InputBegan:Connect(function(input: InputObject)
			if mapBig and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				dragging = true
				dragLast = input.Position
			end
		end)
		UserInputService.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input: InputObject)
			if not mapBig then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				zoomBy(input.Position.Z > 0 and 1.25 or 0.8)
			elseif dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - dragLast
				dragLast = input.Position
				local px = (MAP_BIG - 12)
				pcall(function()
					px = mapInner.AbsoluteSize.X
				end)
				local cs = math.max(1, px * bigZoom)
				local _, VH = mapFrameOf(mapSky)
				bigCenter -= Vector3.new(d.X / cs * 2 * VH, 0, d.Y / cs * 2 * VH)
				applyView(nil)
				declutter()
			end
		end)
	end)
	buildSkyMap()
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
	guideAt = nil
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
	guideAt = m.at
	showMark(mapGuide, m.at)
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
local storyAcceptBtn: TextButton? = nil
local storyChip: TextButton? = nil
local storyHidden = false
local lastStoryState: any = nil

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
	-- 2.7.7판: 게임 전체를 이끄는 목표들
	elseif k == "sky" then
		return "천상 문으로 천상계에 오르기 (마을 안)"
	elseif k == "manual" then
		return string.format("심법 두루마리 펼쳐 심법 얻기  %d / %d (메뉴 → 심법)", countKeys(s.manuals), g.n or 1)
	elseif k == "tower" then
		return string.format("천층탑 %d층 넘기 (최고 %d층)", g.n or 1, s.towerBest or 0)
	elseif k == "mastery" then
		local st = Config.STYLE_BY_ID[s.style or ""]
		local lv = st and s.mastery and s.mastery[st.id] and s.mastery[st.id].lv or 0
		return string.format("%s 숙련 %d 만들기 (지금 %d)", st and st.name or "지금 권법", g.n or 1, lv)
	elseif k == "maze" then
		return "구름 미궁 끝까지 넘기 (천궁 광장 🌀 문)"
	elseif k == "raid" then
		return "천공 투기장에서 천겁 쓰러뜨리기 (천궁 광장 ⚔ 문)"
	elseif k == "rebirth" then
		return string.format("환생하기  %d / %d (천외천에서, 메뉴 → 환생)", s.rebirth or 0, g.n or 1)
	elseif k == "awaken" then
		return "각성 권법(진) 하나 익히기 (원래 사부에게 각성의 시련)"
	elseif k == "transcend" then
		return "초월 권법(초) 하나 익히기 (숨은 초월의 사부)"
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
	lastStoryState = s
	storyBox.Visible = not storyHidden
	if storyChip then
		storyChip.Visible = storyHidden
	end
	-- 받지 않은 이야기는 제목만 (목표 표시도, 길잡이도 없다)
	local accepted = s.accepted ~= false or ch.goal.kind == "talk"
	if storyAcceptBtn then
		storyAcceptBtn.Visible = not accepted
	end
	if accepted then
		storyTitle.Text = string.format("📜 %d장 · %s", s.story or 1, ch.title)
		storyGoal.Text = "▸ " .. goalText(s, ch.goal)
	else
		storyTitle.Text = string.format("📜 새 이야기 · %s", ch.title)
		storyGoal.Text = "▸ 받으면 목표가 표시돼요"
	end
	-- 장로에게 말 걸기는 장로 이름표가 있으니 따로 띄우지 않는다
	local at = (accepted and not storyHidden and ch.goal.kind ~= "talk") and goalTarget(s, ch.goal) or nil
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
	storyMarkAt = at
	showMark(storyMark, at)
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

function UI.setStoryHidden(on: boolean)
	storyHidden = on
	if lastStoryState then
		refreshStory(lastStoryState)
	end
end

function UI.refreshWorld(s: any)
	refreshFound(s)
	refreshRec()
	refreshStory(s)
end

-- 대화 창: 글자가 한 자씩 흘러나온다
local dialogFrame: Frame
local dialogWho: TextLabel
local dialogTitle: TextLabel
local dialogText: TextLabel
local dialogAct: TextButton
local dialogTrial: string? = nil
local dialogAccept = false
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
	dialogAccept = data.accept == true
	dialogAct.Visible = dialogTrial ~= nil or dialogAccept
	dialogAct.Text = dialogAccept and "📜 받기" or "⚔ 시험 받기"
	dialogAct.BackgroundColor3 = dialogAccept and Color3.fromRGB(190, 130, 50) or C.red
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
	storyBox = new("Frame", { Name = "Story", Position = UDim2.new(0, 0, 0, 424), Size = UDim2.new(0, 400, 0, 74), BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, Parent = topLeft }, { corner(10), stroke(Color3.fromRGB(255, 190, 90), 1.5) })
	storyTitle = text({ Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 26), TextSize = 19, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 200, 110), Parent = storyBox })
	storyGoal = text({ Position = UDim2.new(0, 10, 0, 36), Size = UDim2.new(1, -20, 0, 30), TextSize = 16, TextColor3 = C.text, TextWrapped = true, Parent = storyBox })
	-- 아직 받지 않은 이야기: 눌러서 받는다
	storyAcceptBtn = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -40, 0, 50), Size = UDim2.new(0, 90, 0, 30), Text = "📜 받기", TextSize = 16, BackgroundColor3 = Color3.fromRGB(190, 130, 50), Visible = false, Parent = storyBox }, function()
		Request:FireServer("storyAccept")
	end)
	-- 이야기 칸 숨기기 / 다시 보기
	button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.new(0, 26, 0, 26), Text = "✕", TextSize = 15, BackgroundColor3 = C.panel2, Parent = storyBox }, function()
		UI.setStoryHidden(true)
	end)
	storyChip = button({ Position = UDim2.new(0, 0, 0, 386), Size = UDim2.new(0, 120, 0, 34), Text = "📜 이야기 보기", TextSize = 15, BackgroundColor3 = C.bg, Visible = false, Parent = topLeft }, function()
		UI.setStoryHidden(false)
	end)
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
		if dialogAccept then
			Request:FireServer("storyAccept")
		elseif dialogTrial then
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
	volcano = { d = 0.48, h = 2.6, c = Color3.fromRGB(200, 90, 50) },
	desert = { d = 0.34, h = 2.2, c = Color3.fromRGB(240, 200, 140) },
	sky = { d = 0.3, h = 1.2, c = Color3.fromRGB(235, 242, 255) },
	maple = { d = 0.28, h = 1.5, c = Color3.fromRGB(255, 200, 150) },
	stone = { d = 0.45, h = 2.2, c = Color3.fromRGB(225, 228, 230) },
	mushroom = { d = 0.45, h = 2.4, c = Color3.fromRGB(170, 130, 210) },
	tea = { d = 0.42, h = 1.8, c = Color3.fromRGB(225, 240, 225) },
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
UI.regionAt = regionAt
-- 천상계: 섬 이름, 맑고 밝은 하늘빛, 발아래 구름 바다 (이 화면에서만 만든다. 땅에서는 보이지 않는다)
local skySea: Folder? = nil
local SKY_AMBIENT = { d = 0.16, h = 0.35, c = Color3.fromRGB(225, 238, 255) }
local function skyTick(pos: Vector3)
	local isl = Config.skyIslandAt(pos)
	local id = isl and ("sky_" .. isl.id) or "sky"
	if id ~= regionNow then
		regionNow = id
		if isl then
			local rec = regionPower("sky_" .. isl.id)
			UI.toast(string.format("📍 천상계 · %s%s%s", isl.name, isl.safe and "  · 안전한 곳" or string.format("  · 적 수준 %d", Config.enemyLevel(Vector3.new(pos.X, Config.SKY.y, pos.Z))), (rec and not isl.safe) and ("  · " .. powerAdvice(rec)) or ""))
		end
	end
	local atmo = game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
	if atmo then
		atmo.Density += (SKY_AMBIENT.d - atmo.Density) * 0.08
		atmo.Haze += (SKY_AMBIENT.h - atmo.Haze) * 0.08
		atmo.Color = atmo.Color:Lerp(SKY_AMBIENT.c, 0.08)
	end
	if not skySea then
		local f = Instance.new("Folder")
		f.Name = "KwonSkySea"
		for x = -1, 1 do
			for z = -1, 1 do
				local p = Instance.new("Part")
				p.Anchored = true
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
				p.Size = Vector3.new(2000, 4, 2000)
				p.Position = Vector3.new(x * 2000, Config.SKY.y - 75, z * 2000)
				p.Color = Color3.fromRGB(250, 250, 255)
				p.Material = Enum.Material.SmoothPlastic
				p.Transparency = 0.12
				p.Parent = f
			end
		end
		f.Parent = workspace
		skySea = f
	end
end
local function ambientTick(pos: Vector3)
	if pos.Y > Config.SKY.y - 300 then
		skyTick(pos)
		return
	end
	if skySea then
		skySea:Destroy()
		skySea = nil
	end
	-- 하늘의 천층탑 시련장에서는 땅의 이름을 알리지 않는다
	if pos.Y > 1000 then
		return
	end
	local r = regionAt(pos)
	local id = r and r.id or "wild"
	if id ~= regionNow then
		regionNow = id
		if r then
			local lv = Config.enemyLevel(pos)
			local rec = regionPower(r.id)
			UI.toast(string.format("📍 %s%s%s", r.name, r.safe and "  · 안전한 곳" or string.format("  · 적 수준 %d", lv), (rec and not r.safe) and ("  · " .. powerAdvice(rec)) or ""))
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
	if pos and isSkyPos(pos) ~= inSkyNow then
		-- 천상계에 오르내리면 지도도 따라 바뀐다
		inSkyNow = isSkyPos(pos)
		setMapWorld(inSkyNow)
	end
	mapMe.Visible = inSkyNow == mapSky
	if pos and root and root:IsA("BasePart") then
		mapMe.Position = mapUV(pos)
		if not mapBig then
			applyView(pos)
		end
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
	declutter()
	local n = 0
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies and pos then
		local range = mapBig and 900 or 700
		for _, e in ipairs(enemies:GetChildren()) do
			local r = e:FindFirstChild("HumanoidRootPart")
			if n < #mapDots and r and r:IsA("BasePart") and e:GetAttribute("Dead") ~= true and (r.Position - pos).Magnitude < range and isSkyPos(r.Position) == mapSky then
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
	if actions.X then
		round("X", UDim2.fromScale(0.36, 0.14), 46, Color3.fromRGB(255, 140, 190), actions.X)
	end
	round("🧪", UDim2.fromScale(0.95, 0.05), 44, C.green, actions.potion)
	round("●", UDim2.fromScale(0.05, 0.95), 44, C.chi, actions.train)
	round("🐎", UDim2.fromScale(0.05, 0.62), 44, C.panel2, actions.mount)
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
	local topLeft = new("Frame", { Name = "TopLeft", Position = UDim2.new(0, 16, 0, 60), Size = UDim2.new(0, 820, 0, 500), BackgroundTransparency = 1, Parent = gui }) :: Frame
	scaled(topLeft)
	topInfo = text({ Size = UDim2.new(1, 0, 0, 28), TextSize = 20, Font = Enum.Font.GothamBlack, TextStrokeTransparency = 0.3, Parent = topLeft })
	local menu = new("Frame", { Name = "Menu", Position = UDim2.new(0, 0, 0, 34), Size = UDim2.new(0, 150, 0, 424), BackgroundTransparency = 1, Parent = topLeft }, { new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	for _, item in ipairs({ { "styles", "🥋 권법" }, { "map", "🗺 지도 (M)" }, { "stats", "📊 능력치" }, { "ach", "🏆 업적" }, { "train", "🧘 수련 안내" }, { "manuals", "📜 심법" }, { "shop", "🧪 만물상" }, { "help", "📜 도움말" }, { "tower", "🗼 천층탑으로" }, { "pvp", "⚔ PvP 켜짐" }, { "test", "🧪 테스트" } }) do
		local b = button({ Size = UDim2.new(1, 0, 0, 34), Text = item[2], TextSize = 17, Parent = menu }, function()
			if item[1] == "pvp" then
				Request:FireServer("pvpToggle")
			elseif item[1] == "tower" then
				Request:FireServer("towerTp")
			elseif item[1] == "map" then
				UI.toggleMap()
			else
				UI.openPage(item[1])
			end
		end)
		new("UIStroke", { Color = C.line, Thickness = 1, Parent = b })
		if item[1] == "test" then
			b.Name = "TestButton"
			b.Visible = false
		elseif item[1] == "pvp" then
			b.Name = "PvpButton"
		end
	end
	buildStory(topLeft)
	-- 보스 막대
	-- 보스 막대: 어두운 판, 금빛 테, 이름·단계·전투력, 체력 (흰 띠가 따라온다), 단계 눈금, 균형
	bossFrame = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 34), Size = UDim2.new(0, 760, 0, 92), BackgroundColor3 = Color3.fromRGB(14, 8, 8), BackgroundTransparency = 0.25, Visible = false, Parent = gui }, { corner(12), stroke(Color3.fromRGB(190, 60, 40), 2) })
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.1, 0.5), Parent = bossFrame })
	scaled(bossFrame)
	bossName = text({ Position = UDim2.new(0, 0, 0, 4), Size = UDim2.new(1, 0, 0, 28), TextSize = 26, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 205, 120), TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.1, Parent = bossFrame })
	bossSub = text({ Position = UDim2.new(0, 0, 0, 32), Size = UDim2.new(1, 0, 0, 18), TextSize = 15, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, Parent = bossFrame })
	local bb = new("Frame", { Position = UDim2.new(0, 16, 0, 52), Size = UDim2.new(1, -32, 0, 20), BackgroundColor3 = Color3.fromRGB(25, 10, 10), Parent = bossFrame }, { corner(6), stroke(Color3.fromRGB(150, 115, 70), 1.5) })
	local bossTrail = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 235, 200), BackgroundTransparency = 0.2, Parent = bb }, { corner(6) })
	bossFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(200, 30, 30), ZIndex = 2, Parent = bb }, { corner(6) })
	sheen(bossFill)
	meterTrails[bossFill] = bossTrail
	-- 단계 눈금 (2/3, 1/3)
	for _, x in ipairs({ 0.66, 0.33 }) do
		new("Frame", { Position = UDim2.new(x, -1, 0, -3), Size = UDim2.new(0, 3, 1, 6), BackgroundColor3 = Color3.fromRGB(255, 220, 140), BorderSizePixel = 0, ZIndex = 4, Parent = bb })
	end
	bossHpText = text({ Size = UDim2.fromScale(1, 1), TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.2, ZIndex = 5, Parent = bb })
	local pb = new("Frame", { Position = UDim2.new(0.25, 0, 0, 77), Size = UDim2.new(0.5, 0, 0, 8), BackgroundColor3 = Color3.fromRGB(20, 10, 10), Parent = bossFrame }, { corner(4) })
	bossPosture = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.posture, Parent = pb }, { corner(4) })
	RunService.RenderStepped:Connect(function()
		local m = bossModel
		-- 보스가 쓰러졌거나, 내가 쓰러졌거나, 멀리 떨어지면 막대를 걷는다
		if m and m.Parent then
			local me = Players.LocalPlayer.Character
			local mr = me and me:FindFirstChild("HumanoidRootPart")
			local br = m:FindFirstChild("HumanoidRootPart")
			if m:GetAttribute("Dead") == true or (me and me:GetAttribute("Dead") == true) or (mr and br and mr:IsA("BasePart") and br:IsA("BasePart") and (mr.Position - br.Position).Magnitude > 170) then
				UI.setBoss(nil)
				return
			end
		end
		if m and m.Parent then
			local hp, mx = m:GetAttribute("Hp"), m:GetAttribute("MaxHp")
			local po, pm = m:GetAttribute("Posture"), m:GetAttribute("PostureMax")
			if type(hp) == "number" and type(mx) == "number" then
				trailTo(bossFill, math.clamp(hp / math.max(1, mx), 0, 1))
				bossHpText.Text = string.format("%s / %s", Config.formatNumber(math.max(0, math.floor(hp))), Config.formatNumber(mx))
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
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 160, 150)), Parent = window })
	windowTitle = text({ Position = UDim2.new(0, 18, 0, 10), Size = UDim2.new(1, -80, 0, 36), TextSize = 28, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, Parent = window })
	new("Frame", { Position = UDim2.new(0, 18, 0, 48), Size = UDim2.new(1, -36, 0, 2), BackgroundColor3 = C.line, BorderSizePixel = 0, Parent = window }, { new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.4), NumberSequenceKeypoint.new(1, 1) }) }) })
	button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.new(0, 48, 0, 40), Text = "✕", TextSize = 22, BackgroundColor3 = C.red, Parent = window }, function()
		window.Visible = false
	end)
	buildStyles()
	buildStats()
	buildAch()
	buildShop()
	buildManuals()
	buildSkyShop()
	buildHelp()
	buildTrainGuide()
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
	trainFrame = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.45, 0), Size = UDim2.new(0, 400, 0, 400), BackgroundColor3 = C.bg, BackgroundTransparency = 0.25, Visible = false, Parent = gui }, { corner(16), stroke(C.line, 2) })
	scaled(trainFrame)
	trainTitle = text({ Position = UDim2.new(0, 0, 0, 8), Size = UDim2.new(1, 0, 0, 30), TextSize = 22, Font = Enum.Font.GothamBlack, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center, Parent = trainFrame })
	trainHint = text({ Position = UDim2.new(0, 12, 0, 40), Size = UDim2.new(1, -24, 0, 40), TextSize = 14, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Center, Parent = trainFrame })
	trainArea = new("Frame", { Position = UDim2.new(0, 0, 0, 84), Size = UDim2.new(1, 0, 1, -200), BackgroundTransparency = 1, ClipsDescendants = true, Parent = trainFrame })
	-- 하는 법 (세 걸음)
	trainGuide = text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -52), Size = UDim2.new(1, -24, 0, 62), TextSize = 15, TextWrapped = true, TextColor3 = Color3.fromRGB(255, 230, 170), TextXAlignment = Enum.TextXAlignment.Center, BackgroundColor3 = C.panel2, BackgroundTransparency = 0.4, Parent = trainFrame })
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
