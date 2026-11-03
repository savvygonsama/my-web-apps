-- 3.18판: 가벼운 그래픽. 맵의 작은 장식 (풀 포기·들꽃·이끼·덤불·갈대·마른 가지·물웅덩이)을 내 화면에서만 걷는다
-- 서버와 다른 사람의 화면은 그대로. 부딪히는 것 (바위·나무 둥치·집)은 건드리지 않는다
local Perf = {}

local CLUTTER = {
	Tuft = true, WildFlower = true, Moss = true, Flower = true, FlowerStem = true,
	Bush = true, Reed = true, DeadBranch = true, Puddle = true,
}

Perf.low = false
local hidden: { { any } } = {}

local function collect(): { BasePart }
	local g = workspace:FindFirstChild("Gangho")
	local out: { BasePart } = {}
	if not g then
		return out
	end
	for _, d in ipairs(g:GetDescendants()) do
		-- 안내 (ProximityPrompt)나 글씨가 붙은 것은 남긴다
		if d:IsA("BasePart") and CLUTTER[d.Name] and not d.CanCollide and not d:FindFirstChildWhichIsA("ProximityPrompt") and not d:FindFirstChildWhichIsA("SurfaceGui") then
			table.insert(out, d)
		end
	end
	return out
end

function Perf.set(on: boolean)
	if on == Perf.low then
		return
	end
	Perf.low = on
	if on then
		for _, p in ipairs(collect()) do
			table.insert(hidden, { p, p.Parent })
			p.Parent = nil
		end
	else
		for _, h in ipairs(hidden) do
			local par = h[2]
			if par and par.Parent then
				h[1].Parent = par
			end
		end
		table.clear(hidden)
	end
end

function Perf.count(): number
	return #hidden
end

return Perf
