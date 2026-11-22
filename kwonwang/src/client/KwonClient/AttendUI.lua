-- 권왕 3.99.80판: 출석 100일 보상판. 들어올 때마다 그 주 (7일) 의 보상을 보여 준다
--   받은 날은 어둡게 (✓), 오늘은 금빛 테두리, 앞날은 그대로. 권법을 주는 날은 권법 빛깔로 칠한다
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local AttendUI = {}

local INK = Color3.fromRGB(22, 16, 14)
local PANEL = Color3.fromRGB(40, 28, 24)
local LINE = Color3.fromRGB(190, 150, 90)
local GOLD = Color3.fromRGB(255, 210, 120)
local TEXT = Color3.fromRGB(250, 240, 225)
local DIM = Color3.fromRGB(150, 135, 120)

local current: ScreenGui? = nil

local function new(class: string, props: { [string]: any }, kids: { Instance }?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			(o :: any)[k] = v
		end
	end
	for _, k in ipairs(kids or {}) do
		k.Parent = o
	end
	if props.Parent then
		o.Parent = props.Parent
	end
	return o
end
local function corner(r: number): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, r) })
end
local function stroke(c: Color3, w: number, a: number?): UIStroke
	return new("UIStroke", { Color = c, Thickness = w, Transparency = a or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function label(props: { [string]: any }): TextLabel
	local base = { BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextColor3 = TEXT, TextScaled = true, RichText = true, TextWrapped = true }
	for k, v in pairs(props) do
		base[k] = v
	end
	return new("TextLabel", base)
end

-- 하루치 보상 줄
local function lines(rw: any, coinUnit: number): string
	local out = {}
	if rw.style then
		local sd = Config.STYLE_BY_ID[rw.style]
		if sd then
			table.insert(out, string.format("<b>%s %s</b>", sd.icon, sd.name))
		end
	end
	if rw.coins then
		table.insert(out, "💰 " .. Config.formatNumber(rw.coins * coinUnit))
	end
	if rw.shards then
		table.insert(out, "🧩 " .. rw.shards)
	end
	if rw.gems then
		table.insert(out, "💠 " .. Config.formatNumber(rw.gems))
	end
	if rw.scrolls then
		table.insert(out, "📜 " .. rw.scrolls)
	end
	if rw.mats then
		table.insert(out, "✨ " .. rw.mats)
	end
	return table.concat(out, "\n")
end

function AttendUI.close()
	if current then
		local g = current
		current = nil
		local f = g:FindFirstChild("Board")
		if f then
			TweenService:Create(f, TweenInfo.new(0.2), { Position = UDim2.fromScale(0.5, 0.56) }):Play()
		end
		task.delay(0.2, function()
			g:Destroy()
		end)
	end
end

-- data = { day = 받은 날 수 (오늘 받은 것까지), total = 100, fresh = 오늘 막 받았나, coinUnit = 은자 한 몫 }
function AttendUI.show(parent: Instance, data: any, device: string?)
	AttendUI.close()
	local A = Config.ATTEND
	local total = data.total or A.total
	local day = math.clamp(tonumber(data.day) or 0, 0, total)
	local done = day >= total
	-- 보여 줄 주: 오늘 받은 날이 든 주. 아직 하나도 안 받았으면 첫 주
	local week = math.max(1, math.ceil(math.max(1, day) / 7))
	local first = (week - 1) * 7 + 1
	local coinUnit = tonumber(data.coinUnit) or 1
	local phone = device == "phone"

	local sg = new("ScreenGui", { Name = "KwonAttend", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 8, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	local dim = new("TextButton", { Name = "Dim", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, Size = UDim2.fromScale(1, 1), Parent = sg })
	dim.MouseButton1Click:Connect(AttendUI.close)
	local board = new("Frame", {
		Name = "Board", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56),
		Size = phone and UDim2.new(0.96, 0, 0.62, 0) or UDim2.new(0.7, 0, 0, 330), BackgroundColor3 = INK, Parent = sg,
	}, { corner(14), stroke(LINE, 2), new("UISizeConstraint", { MaxSize = Vector2.new(880, 380) }) })
	TweenService:Create(board, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.5) }):Play()

	local title = done and "📅 출석 100일을 모두 채웠다"
		or string.format("📅 출석 %d주째 · %d / %d일", week, day, total)
	label({ Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(1, -80, 0, 34), Text = title, Font = Enum.Font.Antique, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Parent = board })
	local closeBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.new(0, 40, 0, 34), Text = "✕",
		Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = TEXT, BackgroundColor3 = PANEL, Parent = board,
	}, { corner(8), stroke(LINE, 1) })
	closeBtn.MouseButton1Click:Connect(AttendUI.close)

	local row = new("Frame", { Position = UDim2.new(0, 12, 0, 54), Size = UDim2.new(1, -24, 1, -112), BackgroundTransparency = 1, Parent = board })
	new("UIGridLayout", { CellSize = UDim2.new(1 / 7, -6, 1, 0), CellPadding = UDim2.new(0, 6, 0, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	for d = first, first + 6 do
		local rw = A.days[d]
		if not rw then
			-- 100일 뒤 빈 칸 (마지막 주는 이틀뿐)
			new("Frame", { BackgroundTransparency = 1, LayoutOrder = d, Parent = row })
			continue
		end
		local got = d <= day
		local today = d == day and data.fresh
		local sd = rw.style and Config.STYLE_BY_ID[rw.style]
		local big = A.big[d] == true
		local bg = sd and sd.color:Lerp(INK, 0.72) or (big and Color3.fromRGB(70, 48, 26) or PANEL)
		local card = new("Frame", { BackgroundColor3 = bg, LayoutOrder = d, Parent = row }, { corner(10) })
		local st = stroke(today and GOLD or (sd and sd.color or LINE), today and 3 or (sd and 2 or 1), got and not today and 0.5 or 0)
		st.Parent = card
		label({ Position = UDim2.new(0, 4, 0, 4), Size = UDim2.new(1, -8, 0, phone and 16 or 22), Text = string.format("%d일", d), TextColor3 = (sd or big) and GOLD or TEXT, Parent = card })
		label({
			Position = UDim2.new(0, 4, 0, phone and 22 or 30), Size = UDim2.new(1, -8, 1, phone and -44 or -62), Text = lines(rw, coinUnit),
			Font = Enum.Font.Gotham, TextColor3 = got and not today and DIM or TEXT, TextYAlignment = Enum.TextYAlignment.Top, Parent = card,
		})
		local tag = today and "오늘" or (got and "✓ 받음" or nil)
		if tag then
			label({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.new(1, -8, 0, phone and 14 or 20), Text = tag, TextColor3 = today and GOLD or DIM, Parent = card })
		end
		if got and not today then
			card.BackgroundTransparency = 0.35
		end
		if today then
			-- 오늘 칸은 금빛 테두리가 숨 쉬듯 밝아졌다 어두워진다
			TweenService:Create(st, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.6 }):Play()
		end
	end

	-- 아래 줄: 다음 권법까지
	local foot
	if done then
		foot = "백 날을 모두 채웠다. 더 받을 출석 보상은 없다"
	else
		local nextD, nextS = nil, nil
		for d = day + 1, total do
			local rw = A.days[d]
			if rw and rw.style then
				nextD, nextS = d, Config.STYLE_BY_ID[rw.style]
				break
			end
		end
		if nextD and nextS then
			foot = string.format("다음 권법: %s %s · %d일째 (%d일 남음)", nextS.icon, nextS.name, nextD, nextD - day)
		else
			foot = "들어올 때마다 하루씩 쌓인다 (빠져도 끊기지 않는다)"
		end
	end
	label({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -12), Size = UDim2.new(1, -32, 0, phone and 22 or 28), Text = foot, Font = Enum.Font.Gotham, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Parent = board })

	sg.Parent = parent
	current = sg
	-- 저절로 닫힌다 (오늘 받은 날은 조금 더 오래 보인다)
	local me = sg
	task.delay(data.fresh and 14 or 9, function()
		if current == me then
			AttendUI.close()
		end
	end)
end

return AttendUI
