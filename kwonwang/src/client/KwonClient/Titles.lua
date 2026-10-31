-- 권왕 3.13판: 머리 위 칭호 (업적). 업적 등급이 높을수록 화려하다
--   1 일반: 갈래 빛깔 글씨 · 2 희귀: 푸른 빛 테두리와 ◆ · 3 영웅: 보랏빛 판과 흐르는 빛깔 글씨 ◈
--   4 전설: 금빛 판, 금빛이 흐르는 글씨, ❖ 날개, 머리 둘레 금빛 반짝임
--   5 신화: 붉은 먹빛 판에 무지갯빛 테가 돌고, 무지갯빛이 흐르는 글씨, ✦ 신화 ✦ 머리띠, 금빛·붉은 별이 흩날린다
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Titles = {}

type Live = { gui: BillboardGui, grads: { UIGradient }, spin: { UIGradient }, strokes: { UIStroke }, fx: { Instance }, tier: number }
local live: { [Model]: Live } = {}
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_STAR = "rbxasset://textures/particles/sparkles_main.dds"

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		(inst :: any)[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
local function seq(colors: { Color3 }): ColorSequence
	local kps = {}
	for i, c in ipairs(colors) do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), c))
	end
	return ColorSequence.new(kps)
end
local RAINBOW = { Color3.fromRGB(255, 90, 110), Color3.fromRGB(255, 200, 80), Color3.fromRGB(140, 255, 160), Color3.fromRGB(110, 200, 255), Color3.fromRGB(200, 120, 255), Color3.fromRGB(255, 90, 110) }
local GOLDS = { Color3.fromRGB(255, 196, 70), Color3.fromRGB(255, 250, 220), Color3.fromRGB(255, 196, 70) }

local function clear(model: Model)
	local l = live[model]
	if l then
		l.gui:Destroy()
		for _, f in ipairs(l.fx) do
			f:Destroy()
		end
		live[model] = nil
	end
end

local function build(model: Model)
	clear(model)
	local id = model:GetAttribute("TitleId")
	local a = type(id) == "string" and Config.ACH_BY_ID[id] or nil
	local head = model:FindFirstChild("Head")
	if not a or not a.title or not head or not head:IsA("BasePart") then
		return
	end
	local tier = math.clamp(a.tier or 1, 1, 5)
	local catColor = Config.ACH_COLOR[a.kind] or Color3.new(1, 1, 1)
	local tierColor = Config.ACH_TIERS[tier].color
	local L: Live = { gui = nil :: any, grads = {}, spin = {}, strokes = {}, fx = {}, tier = tier }
	local gui = new("BillboardGui", {
		Name = "KwonTitle",
		Size = UDim2.new(0, 420, 0, tier >= 5 and 74 or 56),
		StudsOffset = Vector3.new(0, 2.6, 0),
		SizeOffset = Vector2.new(0, tier >= 5 and 1.02 or 1.08),
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 150,
		ResetOnSpawn = false,
		Adornee = head,
	})
	L.gui = gui
	-- 판 (영웅부터): 글씨 길이에 맞춰 늘어난다
	local holder = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(0, 0, 0, tier >= 3 and 34 or 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 }, gui)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
	if tier >= 3 then
		holder.BackgroundTransparency = tier >= 5 and 0.12 or 0.22
		holder.BackgroundColor3 = tier == 3 and Color3.fromRGB(34, 18, 52) or (tier == 4 and Color3.fromRGB(40, 28, 10) or Color3.fromRGB(46, 8, 14))
		new("UICorner", { CornerRadius = UDim.new(0, 10) }, holder)
		new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, holder)
		local st = new("UIStroke", { Color = tierColor, Thickness = tier >= 4 and 2.2 or 1.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0.1 }, holder)
		table.insert(L.strokes, st)
		if tier >= 4 then
			local g = new("UIGradient", { Color = seq(tier == 5 and RAINBOW or GOLDS) }, st)
			table.insert(L.spin, g)
		end
		if tier == 5 then
			new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(90, 14, 24), Color3.fromRGB(20, 4, 8)), Rotation = 90 }, holder)
		end
	end
	-- 장식 (양옆)
	local orn = ({ nil, "◆", "◈", "❖", "✦" } :: { any })[tier]
	local function ornament(order: number)
		if not orn then
			return
		end
		local o = new("TextLabel", { LayoutOrder = order, BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.GothamBlack, TextSize = tier >= 4 and 22 or 18, Text = orn, TextColor3 = tierColor, TextStrokeTransparency = 0.4 }, holder)
		if tier >= 4 then
			local g = new("UIGradient", { Color = seq(tier == 5 and RAINBOW or GOLDS) }, o)
			table.insert(L.grads, g)
		end
	end
	ornament(1)
	local label = new("TextLabel", {
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Font = tier >= 4 and Enum.Font.Antique or Enum.Font.GothamBlack,
		TextSize = ({ 20, 21, 22, 26, 28 })[tier],
		Text = "「" .. a.title .. "」",
		TextColor3 = tier <= 2 and catColor or Color3.new(1, 1, 1),
		TextStrokeTransparency = tier <= 2 and 0.25 or 0.55,
		TextStrokeColor3 = Color3.new(0, 0, 0),
	}, holder)
	if tier == 2 then
		new("UIStroke", { Color = tierColor, Thickness = 1.6, Transparency = 0.35 }, label)
	elseif tier == 3 then
		local g = new("UIGradient", { Color = seq({ Color3.fromRGB(255, 255, 255), Color3.fromRGB(210, 150, 255), Color3.fromRGB(255, 255, 255) }) }, label)
		table.insert(L.grads, g)
	elseif tier >= 4 then
		local g = new("UIGradient", { Color = seq(tier == 5 and RAINBOW or GOLDS) }, label)
		table.insert(L.grads, g)
		new("UIStroke", { Color = tier == 5 and Color3.fromRGB(255, 90, 110) or Color3.fromRGB(255, 196, 70), Thickness = 1.2, Transparency = 0.45 }, label)
	end
	ornament(3)
	-- 신화: 위에 작은 머리띠
	if tier == 5 then
		local band = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 160, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 14, Text = "✦ 신 화 ✦", TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.4 }, gui)
		local g = new("UIGradient", { Color = seq(RAINBOW) }, band)
		table.insert(L.grads, g)
	elseif tier == 4 then
		new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 120, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 11, Text = "· 전 설 ·", TextColor3 = Color3.fromRGB(255, 214, 120), TextStrokeTransparency = 0.5 }, gui)
	end
	gui.Parent = head
	-- 전설·신화: 머리 둘레의 반짝임
	if tier >= 4 then
		local att = new("Attachment", { Name = "KwonTitleFx", Position = Vector3.new(0, 1.2, 0) }, head)
		table.insert(L.fx, att)
		local function emitter(c1: Color3, c2: Color3, rate: number, tex: string)
			new("ParticleEmitter", {
				Texture = tex,
				Color = ColorSequence.new(c1, c2),
				LightEmission = 1,
				LightInfluence = 0,
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }),
				Transparency = NumberSequence.new(0.1, 1),
				Lifetime = NumberRange.new(0.8, 1.4),
				Speed = NumberRange.new(0.6, 1.6),
				SpreadAngle = Vector2.new(180, 180),
				Rate = rate,
				Shape = Enum.ParticleEmitterShape.Sphere,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			}, att)
		end
		if tier == 4 then
			emitter(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 250, 220), 5, TEX_SPARK)
		else
			emitter(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 255, 255), 7, TEX_SPARK)
			emitter(Color3.fromRGB(255, 90, 110), Color3.fromRGB(200, 120, 255), 5, TEX_STAR)
		end
	end
	live[model] = L
end

local function watch(model: Model)
	task.spawn(function()
		model:WaitForChild("Head", 10)
		build(model)
	end)
	model:GetAttributeChangedSignal("TitleId"):Connect(function()
		build(model)
	end)
	model.AncestryChanged:Connect(function()
		if not model.Parent then
			clear(model)
		end
	end)
end

function Titles.init()
	local function onPlayer(pl: Player)
		if pl.Character then
			watch(pl.Character)
		end
		pl.CharacterAdded:Connect(watch)
	end
	for _, pl in ipairs(Players:GetPlayers()) do
		onPlayer(pl)
	end
	Players.PlayerAdded:Connect(onPlayer)
	-- 흐르는 빛깔·도는 테
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for _, L in pairs(live) do
			local off = ((t * (L.tier == 5 and 0.55 or 0.4)) % 2) - 1
			for _, g in ipairs(L.grads) do
				g.Offset = Vector2.new(off, 0)
			end
			for _, g in ipairs(L.spin) do
				g.Rotation = (t * 90) % 360
			end
			if L.tier == 3 then
				for _, s in ipairs(L.strokes) do
					s.Transparency = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(t * 2.4))
				end
			end
		end
	end)
end

return Titles
