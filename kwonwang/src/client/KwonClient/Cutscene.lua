-- 권왕: 컷씬 (위아래 검은 띠, 말하는 이와 대사, 천천히 도는 카메라) 과 처음 들어온 사람의 조작 안내
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Cutscene = {}
Cutscene.active = false

local player = Players.LocalPlayer
local queue: { any } = {}

local gui = Instance.new("ScreenGui")
gui.Name = "KwonCutscene"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local function tween(inst: Instance, time: number, goal: { [string]: any })
	local tw = TweenService:Create(inst, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end

local function frame(props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in pairs(props) do
		(f :: any)[k] = v
	end
	return f
end

local function label(props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.6
	for k, v in pairs(props) do
		(l :: any)[k] = v
	end
	return l
end

-- 위아래 띠
local top = frame({ Name = "Top", BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.fromScale(1, 0), Parent = gui })
local bottom = frame({ Name = "Bottom", BackgroundColor3 = Color3.new(0, 0, 0), AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), Parent = gui })
local who = label({ Name = "Who", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -118), Size = UDim2.new(0.8, 0, 0, 30), TextScaled = true, TextColor3 = Color3.fromRGB(255, 215, 130), Text = "", Parent = gui })
local line = label({ Name = "Line", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -26), Size = UDim2.new(0.8, 0, 0, 86), TextScaled = true, TextWrapped = true, Font = Enum.Font.Gotham, Text = "", Parent = gui })
local sizeLimit = Instance.new("UITextSizeConstraint")
sizeLimit.MaxTextSize = 30
sizeLimit.Parent = line
label({ Name = "Next", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -8), Size = UDim2.new(0, 220, 0, 20), TextScaled = true, Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(190, 190, 190), Text = "누르면 다음 ▶", TextXAlignment = Enum.TextXAlignment.Right, Parent = gui })
-- 화면 아무 곳이나 누르면 다음 대사
local tap = Instance.new("TextButton")
tap.Name = "Tap"
tap.BackgroundTransparency = 1
tap.Text = ""
tap.Size = UDim2.fromScale(1, 1)
tap.Parent = gui
local skip = Instance.new("TextButton")
skip.Name = "Skip"
skip.AnchorPoint = Vector2.new(1, 0)
skip.Position = UDim2.new(1, -20, 0, 20)
skip.Size = UDim2.new(0, 130, 0, 36)
skip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
skip.BackgroundTransparency = 0.3
skip.TextColor3 = Color3.new(1, 1, 1)
skip.Font = Enum.Font.GothamBold
skip.TextScaled = true
skip.Text = "건너뛰기 ▶▶"
skip.ZIndex = 3
skip.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = skip

local advance = false
local skipped = false
tap.Activated:Connect(function()
	advance = true
end)
skip.Activated:Connect(function()
	skipped = true
	advance = true
end)

-- 움직임 막기 (컷씬 동안 캐릭터가 걷지 않게)
local function controls(on: boolean)
	pcall(function()
		local ps = player:FindFirstChild("PlayerScripts")
		local pm = ps and ps:FindFirstChild("PlayerModule")
		if pm and pm:IsA("ModuleScript") then
			local c = (require :: any)(pm):GetControls()
			if on then
				c:Enable()
			else
				c:Disable()
			end
		end
	end)
end

local function rootOf(m: Model?): BasePart?
	local r = m and m:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end

-- 비출 곳: 모델이면 그 몸, 자리면 그 자리, 없으면 나
local function subjectOf(subject: any): (() -> Vector3, number)
	local m = subject and subject.m
	if typeof(m) == "Instance" and m:IsA("Model") then
		local scale = tonumber(m:GetAttribute("Scale")) or 1
		return function()
			local r = rootOf(m)
			return r and r.Position + Vector3.new(0, 1.5 * scale, 0) or Vector3.zero
		end, 10 + 4 * scale
	end
	local at = subject and subject.at
	if typeof(at) == "Vector3" then
		return function()
			return at + Vector3.new(0, 4, 0)
		end, subject.far and 60 or 16
	end
	return function()
		local r = rootOf(player.Character)
		return r and r.Position + Vector3.new(0, 1.5, 0) or Vector3.zero
	end, 12
end

local function runOne(item: any)
	Cutscene.active = true
	advance, skipped = false, false
	controls(false)
	local cam = workspace.CurrentCamera
	local oldType = cam.CameraType
	local focus, dist = subjectOf(item.subject)
	-- 처음 각도: 내 쪽에서 비스듬히 (대상이 나를 보고 말하는 듯)
	local me = rootOf(player.Character)
	local p0 = focus()
	local from = me and Vector3.new(me.Position.X - p0.X, 0, me.Position.Z - p0.Z) or Vector3.new(0, 0, 1)
	local a0 = (from.Magnitude > 0.1 and math.atan2(from.Z, from.X) or 0) + 0.5
	local t0 = os.clock()
	cam.CameraType = Enum.CameraType.Scriptable
	local conn = RunService.RenderStepped:Connect(function()
		local p = focus()
		local a = a0 + (os.clock() - t0) * 0.06
		local eye = p + Vector3.new(math.cos(a) * dist, dist * 0.28, math.sin(a) * dist)
		cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(eye, p), 0.12)
	end)
	cam.CFrame = CFrame.lookAt(p0 + Vector3.new(math.cos(a0) * dist * 1.4, dist * 0.4, math.sin(a0) * dist * 1.4), p0)
	gui.Enabled = true
	who.Text = item.scene.who or ""
	line.Text = ""
	tween(top, 0.35, { Size = UDim2.fromScale(1, 0.11) })
	tween(bottom, 0.35, { Size = UDim2.new(1, 0, 0, 150) })
	task.wait(0.35)
	for _, text in ipairs(item.scene.lines or {}) do
		if skipped then
			break
		end
		advance = false
		local n = utf8.len(text) or #text
		local dur = math.clamp(1.6 + n * 0.07, 2.4, 6)
		-- 한 글자씩
		local shown = 0
		local typeStart = os.clock()
		while shown < n and not advance do
			shown = math.min(n, math.floor((os.clock() - typeStart) / 0.035) + 1)
			local cut = utf8.offset(text, shown + 1)
			line.Text = cut and string.sub(text, 1, cut - 1) or text
			RunService.RenderStepped:Wait()
		end
		line.Text = text
		advance = false
		local t = os.clock()
		while os.clock() - t < dur and not advance do
			RunService.RenderStepped:Wait()
		end
	end
	tween(top, 0.3, { Size = UDim2.fromScale(1, 0) })
	tween(bottom, 0.3, { Size = UDim2.fromScale(1, 0) })
	who.Text = ""
	line.Text = ""
	task.wait(0.3)
	conn:Disconnect()
	gui.Enabled = false
	cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
	controls(true)
	Cutscene.active = false
	if item.onDone then
		task.spawn(item.onDone)
	end
end

local running = false
local function pump()
	if running then
		return
	end
	running = true
	task.spawn(function()
		while #queue > 0 do
			local item = table.remove(queue, 1)
			local ok, err = pcall(runOne, item)
			if not ok then
				warn("[권왕] 컷씬 오류:", err)
				pcall(function()
					gui.Enabled = false
					workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
				end)
				controls(true)
				Cutscene.active = false
			end
		end
		running = false
	end)
end

-- scene = { who, lines }, subject = { m = 모델 } 또는 { at = 자리 }
function Cutscene.play(scene: any, subject: any?, onDone: (() -> ())?)
	if type(scene) ~= "table" then
		return
	end
	table.insert(queue, { scene = scene, subject = subject, onDone = onDone })
	pump()
end

------------------------------------------------------------------------
-- 처음 들어온 사람에게 한 번: 조작 안내
------------------------------------------------------------------------
function Cutscene.controls(onDone: (() -> ())?)
	local card = Instance.new("ScreenGui")
	card.Name = "KwonControls"
	card.ResetOnSpawn = false
	card.DisplayOrder = 45
	card.Parent = player:WaitForChild("PlayerGui")
	local dim = frame({ BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), Parent = card })
	local panel = frame({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.92, 0, 0.8, 0), BackgroundColor3 = Color3.fromRGB(28, 24, 22), Parent = dim })
	local sizeC = Instance.new("UISizeConstraint")
	sizeC.MaxSize = Vector2.new(520, 430)
	sizeC.Parent = panel
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 14)
	pc.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(235, 190, 80)
	stroke.Thickness = 2
	stroke.Parent = panel
	label({ Position = UDim2.new(0, 0, 0, 12), Size = UDim2.new(1, 0, 0, 34), TextScaled = true, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 215, 130), Text = "🥋 조작법", Parent = panel })
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local rows = touch and {
		{ "왼쪽 화면", "움직이기" },
		{ "👊 버튼", "연타 (네 번 이으면 마무리 일격)" },
		{ "강타 버튼", "꾹 눌렀다 떼면 모아치기" },
		{ "E · R · G 버튼", "기술 · 오의" },
		{ "🛡 버튼", "막기. 맞기 직전에 누르면 흘리기" },
		{ "회피 버튼", "구르며 피하기 (잠깐 무적)" },
		{ "🐎 버튼", "탈것 타기·내리기" },
		{ "말 걸기", "사람·수련터·상점 가까이에서 뜨는 버튼" },
	} or {
		{ "마우스 왼쪽", "연타 (네 번 이으면 마무리 일격)" },
		{ "Z (누르고 떼기)", "강타 · 모아치기" },
		{ "E · R / G", "기술 / 오의" },
		{ "F", "막기. 맞기 직전에 누르면 흘리기" },
		{ "Q / C", "회피 / 달리기 (C 또는 Ctrl)" },
		{ "Space 두 번", "이단 뛰기" },
		{ "T", "말 걸기 · 수련 · 상점" },
		{ "Tab / M / H", "능력치 / 지도 / 회복약" },
		{ "V", "탈것 타기·내리기" },
		{ "마우스 오른쪽 끌기", "시점 돌리기" },
	}
	local list = frame({ BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 56), Size = UDim2.new(1, -48, 1, -120), Parent = panel })
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = list
	for _, r in ipairs(rows) do
		local row = frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1 / #rows, -4), Parent = list })
		label({ Size = UDim2.fromScale(0.4, 1), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 225, 160), Text = r[1], Parent = row })
		label({ Position = UDim2.fromScale(0.42, 0), Size = UDim2.fromScale(0.58, 1), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, Text = r[2], Parent = row })
	end
	local ok = Instance.new("TextButton")
	ok.AnchorPoint = Vector2.new(0.5, 1)
	ok.Position = UDim2.new(0.5, 0, 1, -14)
	ok.Size = UDim2.new(0, 200, 0, 44)
	ok.BackgroundColor3 = Color3.fromRGB(235, 190, 80)
	ok.TextColor3 = Color3.fromRGB(30, 20, 10)
	ok.Font = Enum.Font.GothamBlack
	ok.TextScaled = true
	ok.Text = "알겠어요"
	ok.Parent = panel
	local oc = Instance.new("UICorner")
	oc.CornerRadius = UDim.new(0, 10)
	oc.Parent = ok
	ok.Activated:Connect(function()
		card:Destroy()
		if onDone then
			onDone()
		end
	end)
end

return Cutscene
