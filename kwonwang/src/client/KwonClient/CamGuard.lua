-- 3.18.1판: 오의 컷씬 카메라 지킴이. 컷씬마다 카메라를 너무 낮게 (땅에 붙거나 땅속) 두고 올려다봐서
-- 땅에서 터지는 기술이 화면에서 잘렸다. 어느 컷씬이든 마지막에 이것을 거쳐:
-- · 눈 높이: 몸 (가슴) 높이 + 2.5 아래로, 발밑 땅 + 5 아래로는 내려가지 않는다
-- · 거리: 몸에서 옆으로 MIN_DIST 안쪽이면 같은 방향으로 물러난다 (기술 전체가 화면에 들어오게)
-- · 각도: 위로 MAX_UP도보다 더 올려다보지 않는다 (하늘도 조금은 보인다)
local CamGuard = {}

local MIN_LIFT = 2.5 -- 몸 (HumanoidRootPart) 높이보다 이만큼은 위에서
local MIN_GROUND = 5 -- 땅보다 이만큼은 위에서
local MIN_DIST = 11
local MAX_UP = math.rad(15)

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
local lastFilter = 0
local function refreshFilter()
	if os.clock() - lastFilter < 2 then
		return
	end
	lastFilter = os.clock()
	local list: { Instance } = { workspace.Terrain }
	local g = workspace:FindFirstChild("Gangho")
	if g then
		table.insert(list, g)
	end
	params.FilterDescendantsInstances = list
end

local function groundY(at: Vector3): number?
	refreshFilter()
	local hit = workspace:Raycast(at + Vector3.new(0, 40, 0), Vector3.new(0, -140, 0), params)
	return hit and hit.Position.Y or nil
end

-- eye에서 target을 보는 카메라를, focus (몸 자리) 둘레에서 위의 규칙에 맞게 고친다
function CamGuard.frame(eye: Vector3, target: Vector3, focus: Vector3): CFrame
	-- 1) 거리: 옆으로 너무 붙었으면 물러난다
	local off = Vector3.new(eye.X - focus.X, 0, eye.Z - focus.Z)
	local d = off.Magnitude
	if d < MIN_DIST then
		local dir = d > 0.1 and off.Unit or Vector3.new(0, 0, 1)
		eye = Vector3.new(focus.X, eye.Y, focus.Z) + dir * MIN_DIST
	end
	-- 2) 높이: 몸보다 낮거나 땅에 붙으면 올린다
	local minY = focus.Y + MIN_LIFT
	local gy = groundY(eye)
	if gy then
		minY = math.max(minY, gy + MIN_GROUND)
	end
	if eye.Y < minY then
		eye = Vector3.new(eye.X, minY, eye.Z)
	end
	-- 3) 각도: 너무 올려다보면 보는 곳을 낮춘다
	local to = target - eye
	local flat = Vector3.new(to.X, 0, to.Z).Magnitude
	if flat < 0.5 then
		-- 거의 바로 위·아래를 보면 몸 쪽을 본다
		target = focus + Vector3.new(0, 2, 0)
		to = target - eye
		flat = math.max(0.5, Vector3.new(to.X, 0, to.Z).Magnitude)
	end
	local maxRise = flat * math.tan(MAX_UP)
	if to.Y > maxRise then
		target = Vector3.new(target.X, eye.Y + maxRise, target.Z)
	end
	return CFrame.lookAt(eye, target)
end

return CamGuard
