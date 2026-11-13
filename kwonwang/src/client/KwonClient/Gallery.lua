-- 권왕 3.66판: 배틀그라운드 권법 전시장의 내 화면 몫 (전시장 자체는 서버가 짓는다: StyleHall.lua)
--   · 모든 마네킹이 그 권법 자세로 선다 (Anim이 Style 속성으로 자세를 잡는다). 가까운 것은 차례로 시범 (한 번에 셋까지)
--   · 마네킹에 그 권법의 시그니처 장신구 · 게임패스 꼬리 · 마검을 내 화면에서 입힌다
--   · 내가 익힌 권법만 고를 수 있다: 익히지 않은 칸은 발판이 어둡고 '🔒 익히지 않음'. 익힌 칸의 발판을 밟으면 그 권법으로 입장
--   · 상징물의 도는 조각 (Spin…) 을 돌린다 (SpinRate 0 = 상징물 가운데를 축으로 공전)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Anim = require(script.Parent:WaitForChild("Anim"))
local Fx = require(script.Parent:WaitForChild("Fx"))

local Gallery = {}
local player = Players.LocalPlayer

local opts: any = {}
local lastState: any = nil
local units: { any } = {}
local spinners: { { any } } = {}
local LOCKED = Color3.fromRGB(46, 48, 56)
local GOLD = Color3.fromRGB(255, 208, 110)

local function owned(id: string): boolean
	return lastState ~= nil and type(lastState.styles) == "table" and table.find(lastState.styles, id) ~= nil
end

-- 발판 · 푯말을 내 상태에 맞게 (익힌 것 / 지금 쓰는 것 / 잠긴 것)
local function paint()
	for _, u in ipairs(units) do
		local st = Config.STYLE_BY_ID[u.id]
		if st and u.pad and u.pad.Parent then
			local have = owned(u.id)
			local using = lastState and lastState.style == u.id
			u.pad.Color = using and GOLD or (have and st.color or LOCKED)
			u.pad.Transparency = have and 0.3 or 0.05
			u.pad.Material = have and Enum.Material.Neon or Enum.Material.SmoothPlastic
			if u.label then
				u.label.Text = using and "지금 쓰는 권법 · 밟으면 입장" or (have and "밟으면 입장" or "🔒 익히지 않음")
				u.label.TextColor3 = have and Color3.new(1, 1, 1) or Color3.fromRGB(150, 156, 170)
			end
			if u.grade then
				local ups = (lastState and lastState.gradeUp and lastState.gradeUp[u.id]) or 0
				u.grade.Text = Config.styleGrade(st, ups) .. (have and "" or "  🔒")
			end
		end
	end
end

-- 마네킹에 장신구 (한 번만)
local function dress(u: any)
	if u.dressed or not u.doll then
		return
	end
	u.dressed = true
	local doll = u.doll
	if opts.previewGear then
		local ok, list = pcall(opts.previewGear, doll, u.id)
		if ok and type(list) == "table" then
			for _, inst in ipairs(list) do
				if typeof(inst) == "Instance" and inst.Parent and not inst:IsDescendantOf(doll) then
					inst.Parent = doll
				end
			end
		end
	end
	local st = Config.STYLE_BY_ID[u.id]
	if st and st.premium and opts.passPreview then
		local lv = (lastState and lastState.enh and lastState.enh[u.id]) or 15
		pcall(opts.passPreview, doll, u.id, lv)
		doll:SetAttribute("Enh", lv) -- 3.72판: 시범 연출도 그 강화 단계로
	end
end

local function collect(hall: Instance)
	units = {}
	spinners = {}
	for _, u in ipairs(hall:GetChildren()) do
		local id = u:GetAttribute("Style")
		if type(id) == "string" then
			local pad = u:FindFirstChild("Pad") :: BasePart?
			local sg = pad and pad:FindFirstChild("PadText")
			local label = sg and sg:FindFirstChild("Label")
			local board = u:FindFirstChild("SignBoard")
			local bsg = board and board:FindFirstChildOfClass("SurfaceGui")
			local grade = bsg and bsg:FindFirstChild("Grade")
			local doll = u:FindFirstChild("Doll") :: Model?
			local padAt = pad and pad.Position
			table.insert(units, { id = id, pad = pad, padAt = padAt, label = label, grade = grade, doll = doll, next = os.clock() + math.random() * 4 })
			if doll then
				pcall(Anim.watch, doll)
			end
			-- 상징물 가운데 = 발판 뒤 12칸, 위 16.8칸 (StyleHall과 같은 자리)
			local center = padAt and (padAt + Vector3.new(0, 16.8, 12)) or nil
			for _, d in ipairs(u:GetDescendants()) do
				if d:IsA("BasePart") and string.sub(d.Name, 1, 4) == "Spin" and center then
					table.insert(spinners, { d, d.CFrame, tonumber(d:GetAttribute("SpinRate")) or 0.3, center })
				end
			end
		end
	end
	paint()
end

function Gallery.update(state: any)
	lastState = state
	pcall(paint)
end

function Gallery.start(o: any)
	opts = o or {}
	task.spawn(function()
		local maps = workspace:WaitForChild("BattleMaps", 60)
		local hall = maps and maps:WaitForChild("StyleHall", 60)
		if not hall then
			return
		end
		task.wait(1) -- 서버가 다 넘겨줄 때까지
		collect(hall)
		local t0 = os.clock()
		RunService.RenderStepped:Connect(function()
			local t = os.clock() - t0
			for _, s in ipairs(spinners) do
				local p, base, rate, center = s[1], s[2], s[3], s[4]
				if p.Parent then
					if rate == 0 then
						p.CFrame = CFrame.new(center) * CFrame.Angles(0, t * 0.8, 0) * (CFrame.new(-center) * base)
					else
						p.CFrame = CFrame.new(base.Position) * CFrame.Angles(0, t * rate * math.pi * 2, 0) * base.Rotation
					end
				end
			end
		end)
		local onPad: { [any]: boolean } = {}
		local sentAt, toldAt = 0, 0
		while true do
			task.wait(0.12)
			local char = player.Character
			local me = char and char:FindFirstChild("HumanoidRootPart")
			local inArena = char and char:GetAttribute("InArena") == true
			if me and me:IsA("BasePart") and not inArena then
				local now = os.clock()
				-- 발판 밟기 (밖에서 올라선 순간만)
				for _, u in ipairs(units) do
					local pa = u.padAt :: Vector3?
					if pa then
						local d = me.Position - pa
						local on = math.abs(d.X) < 4.2 and math.abs(d.Z) < 4.2 and d.Y > -1 and d.Y < 7
						if on and onPad[u] == false then
							if owned(u.id) then
								if now - sentAt > 2 and opts.request then
									sentAt = now
									opts.request:FireServer("battleEnter", u.id)
									pcall(Fx.ring, pa + Vector3.new(0, 0.6, 0), Color3.new(1, 1, 1), 1, 12, 0.4)
								end
							elseif now - toldAt > 2 and opts.toast then
								toldAt = now
								local st = Config.STYLE_BY_ID[u.id]
								pcall(opts.toast, "🔒 " .. (st and st.name or "") .. " · 메인 월드에서 익혀야 고를 수 있어요")
							end
						end
						onPad[u] = on
					end
				end
				-- 가까운 마네킹: 장신구 입히고 차례로 시범 (한 번에 셋까지)
				local busy = 0
				for _, u in ipairs(units) do
					if u.doll and Anim.playing(u.doll) then
						busy += 1
					end
				end
				for _, u in ipairs(units) do
					local d = u.doll
					if d and d.Parent and u.padAt and (u.padAt - me.Position).Magnitude < 60 then
						dress(u)
						if busy < 3 and now >= u.next and not Anim.playing(d) then
							local st = Config.STYLE_BY_ID[u.id]
							local picks: { any } = { 1, 2, 3, 4, "H", "E", "R", "G" }
							local slot = picks[math.random(1, #picks)]
							local mv = st and Config.move(u.id, slot)
							if mv then
								if opts.passCast then
									pcall(opts.passCast, u.id, slot, d, mv.dur)
								end
								pcall(Anim.play, d, mv.pose, mv.dur)
								pcall(Fx.limbTrails, d, mv.pose, mv.dur, st.color, st.color2)
								busy += 1
							end
							u.next = now + 2.5 + math.random() * 2.5
						end
					end
				end
			else
				table.clear(onPad)
			end
		end
	end)
end

return Gallery
