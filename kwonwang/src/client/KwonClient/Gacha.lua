-- 권왕: 심법 뽑기 연출. 두루마리가 떨리며 빛나고 (가장 높은 등급의 빛깔), 터진 뒤 카드가 한 장씩 뒤집힌다
-- 화면을 누르면 바로 끝까지 보여 준다
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Gacha = {}
Gacha.active = false

local player = Players.LocalPlayer

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?)
	local tw = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end

local function new(class: string, props: { [string]: any }): any
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	inst.Parent = props.Parent
	return inst
end

local function round(parent: Instance, r: number)
	new("UICorner", { CornerRadius = UDim.new(0, r), Parent = parent })
end

-- 천상: 무지개 빛깔이 돈다
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 160)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 230, 120)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 255, 200)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(130, 200, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 150, 255)),
})

local function card(parent: Instance, res: any, size: Vector2): Frame
	local m = Config.MANUAL_BY_ID[res.id]
	local R = Config.MANUAL_RARITY[res.r] or Config.MANUAL_RARITY[1]
	local high = res.r >= 4
	local c = new("Frame", { Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = Color3.fromRGB(24, 18, 16), Parent = parent })
	round(c, 12)
	local stroke = new("UIStroke", { Color = R.color, Thickness = high and 4 or 2, Parent = c })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(R.color:Lerp(Color3.new(0, 0, 0), 0.55), Color3.fromRGB(20, 14, 12)), Parent = c })
	if R.heavenly then
		local g = new("UIGradient", { Color = RAINBOW, Parent = stroke })
		task.spawn(function()
			while g.Parent do
				g.Rotation = (g.Rotation + 4) % 360
				RunService.RenderStepped:Wait()
			end
		end)
	end
	local s = size.Y / 300
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 10 * s), Size = UDim2.new(1, 0, 0, 30 * s), Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = R.color, Text = R.name, Parent = c })
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 50 * s), Size = UDim2.new(1, 0, 0, 110 * s), Font = Enum.Font.GothamBlack, TextScaled = true, Text = m and m.icon or "📜", Parent = c })
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.05, 0, 0, 170 * s), Size = UDim2.new(0.9, 0, 0, 36 * s), Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = m and m.name or "", Parent = c })
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.05, 0, 0, 210 * s), Size = UDim2.new(0.9, 0, 0, 30 * s), Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.fromRGB(230, 220, 200),
		Text = m and string.format("%s +%.1f%%", m.desc, Config.manualValue(res.id, res.r) * 100) or "", Parent = c })
	local tag = res.refund and ("💰 +" .. Config.formatNumber(res.refund)) or (res.up and "⬆ 등급 상승" or "✨ 새로 얻음")
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -44 * s), Size = UDim2.new(1, 0, 0, 30 * s), Font = Enum.Font.GothamBold, TextScaled = true,
		TextColor3 = res.refund and Color3.fromRGB(200, 190, 170) or Color3.fromRGB(255, 225, 140), Text = tag, Parent = c })
	return c
end

function Gacha.play(results: { any }, onDone: (() -> ())?)
	if Gacha.active or #results == 0 then
		return
	end
	Gacha.active = true
	local best = 1
	for _, res in ipairs(results) do
		best = math.max(best, res.r or 1)
	end
	local B = Config.MANUAL_RARITY[best]
	local gui = new("ScreenGui", { Name = "KwonGacha", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 60, Parent = player:WaitForChild("PlayerGui") })
	local bg = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(6, 4, 10), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = gui })
	local skip = false
	bg.Activated:Connect(function()
		skip = true
	end)
	tween(bg, 0.3, { BackgroundTransparency = 0.08 })
	local function pause(sec: number)
		local t = os.clock()
		while os.clock() - t < sec and not skip do
			RunService.RenderStepped:Wait()
		end
	end

	-- 1) 두루마리: 떨리며 빛이 차오른다
	local center = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(150, 150), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.6, Parent = bg })
	round(center, 75)
	local glow = new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 4, Parent = center })
	new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, TextScaled = true, Text = "📜", Parent = center })
	local rays: { Frame } = {}
	for k = 1, 12 do
		local ray = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 0), Rotation = k * 30, BackgroundColor3 = B.color, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 0, Parent = bg })
		table.insert(rays, ray)
	end
	local title = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 100), Size = UDim2.fromOffset(500, 40), Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.fromRGB(255, 230, 180), Text = "심법을 펼친다...", Parent = bg })
	local t0 = os.clock()
	local shaking = true
	task.spawn(function()
		while shaking and center.Parent do
			local k = math.clamp((os.clock() - t0) / 1.6, 0, 1)
			local amp = math.floor(2 + k * 8)
			center.Position = UDim2.new(0.5, math.random(-amp, amp), 0.5, math.random(-amp, amp))
			center.Rotation = math.random(-6, 6) * k
			RunService.RenderStepped:Wait()
		end
	end)
	-- 처음엔 흰빛, 반쯤에서 가장 높은 등급의 빛깔로
	pause(0.7)
	tween(center, 0.5, { BackgroundColor3 = B.color, BackgroundTransparency = 0.2, Size = UDim2.fromOffset(190, 190) })
	glow.Color = B.color
	if best >= 4 then
		title.Text = best >= 6 and "하늘이 열린다!" or (best >= 5 and "전설을 넘어선 빛!" or "황금빛이 번진다!")
		title.TextColor3 = B.color
		for _, ray in ipairs(rays) do
			tween(ray, 0.6, { Size = UDim2.fromOffset(best >= 5 and 10 or 6, 900) })
		end
		if B.heavenly then
			new("UIGradient", { Color = RAINBOW, Parent = glow })
		end
	end
	pause(best >= 4 and 1.2 or 0.7)
	shaking = false

	-- 2) 터진다
	local flash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = best >= 4 and B.color:Lerp(Color3.new(1, 1, 1), 0.6) or Color3.new(1, 1, 1), BackgroundTransparency = skip and 1 or 0, ZIndex = 5, Parent = bg })
	tween(flash, 0.5, { BackgroundTransparency = 1 })
	center:Destroy()
	title.Text = ""
	for _, ray in ipairs(rays) do
		ray:Destroy()
	end

	-- 3) 카드가 한 장씩
	local one = #results == 1
	local size = one and Vector2.new(240, 330) or Vector2.new(150, 206)
	local grid = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromOffset(one and size.X or (size.X + 12) * 5, one and size.Y or (size.Y + 12) * 2), BackgroundTransparency = 1, Parent = bg })
	new("UIGridLayout", { CellSize = UDim2.fromOffset(size.X, size.Y), CellPadding = UDim2.fromOffset(12, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = grid })
	-- 작은 화면이면 줄인다
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local sc = math.min(1, (vp.X * 0.94) / grid.Size.X.Offset, (vp.Y * 0.75) / grid.Size.Y.Offset)
	new("UIScale", { Scale = sc, Parent = grid })
	for _, res in ipairs(results) do
		local c = card(grid, res, size)
		local us = new("UIScale", { Scale = skip and 1 or 0, Parent = c })
		if not skip then
			tween(us, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
			pause(res.r >= 4 and 0.45 or 0.12)
		end
	end
	local ok = new("TextButton", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30), Size = UDim2.fromOffset(220, 54), BackgroundColor3 = Color3.fromRGB(235, 190, 80), TextColor3 = Color3.fromRGB(30, 20, 10),
		Font = Enum.Font.GothamBlack, TextScaled = true, Text = "확인", Parent = bg })
	round(ok, 12)
	ok.Activated:Connect(function()
		gui:Destroy()
		Gacha.active = false
		if onDone then
			onDone()
		end
	end)
end

return Gacha
