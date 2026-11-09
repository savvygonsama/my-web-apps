-- 권왕 3.63판: 겹친 바닥 깜빡임 (z-fighting) 바로잡기
-- 같은 높이에 윗면이 있는 납작한 조각 둘이 겹치면, 시점을 돌릴 때마다 두 면이 번갈아 보여 '움직이는' 것처럼 깜빡인다.
-- 맵을 다 지은 뒤 한 번: 위를 보는 면 (세운 상자 · 눕힌 원판) 의 윗면 높이와 바닥 넓이를 모아,
-- 높이 차가 GAP 안이고 바닥이 겹치는 둘 중 나중 것 (대개 위에 얹은 장식) 을 STEP만큼 올린다. 생김새는 그대로 (눈에 안 띄는 높이)
local ZFix = {}

local GAP = 0.045 -- 이보다 가까우면 깜빡인다 (멀리서 볼수록 심하다)
local STEP = 0.06
local CELL = 48

type Item = { p: BasePart, top: number, x0: number, x1: number, z0: number, z1: number }

-- 위를 보는 면이 있는 조각이면 그 윗면 높이와 바닥 넓이 (아니면 nil)
local function flatTop(p: BasePart): Item?
	if not p.Anchored or p.Transparency >= 0.95 or p:IsA("WedgePart") or p:IsA("CornerWedgePart") or p:IsA("MeshPart") then
		return nil
	end
	if p:FindFirstChildOfClass("SpecialMesh") then
		return nil
	end
	local cf, sz = p.CFrame, p.Size
	local shape = p:IsA("Part") and (p :: Part).Shape or Enum.PartType.Block
	local hx, hz
	local top
	if shape == Enum.PartType.Block then
		local up = cf.UpVector
		if math.abs(up.Y) < 0.999 then
			return nil
		end
		top = cf.Position.Y + sz.Y / 2
		-- 땅에 눕힌 상자: 돌린 만큼 바닥 넓이를 넉넉히
		local r = cf.RightVector
		local l = cf.LookVector
		hx = math.abs(r.X) * sz.X / 2 + math.abs(l.X) * sz.Z / 2
		hz = math.abs(r.Z) * sz.X / 2 + math.abs(l.Z) * sz.Z / 2
	elseif shape == Enum.PartType.Cylinder then
		-- 눕힌 원판: 원기둥의 축 (오른쪽) 이 위를 본다
		local axis = cf.RightVector
		if math.abs(axis.Y) < 0.999 then
			return nil
		end
		top = cf.Position.Y + sz.X / 2
		local rad = math.min(sz.Y, sz.Z) / 2
		hx, hz = rad, rad
	else
		return nil
	end
	-- 아주 작은 것은 깜빡여도 눈에 안 띈다
	if hx < 0.4 or hz < 0.4 then
		return nil
	end
	local x, z = cf.Position.X, cf.Position.Z
	return { p = p, top = top, x0 = x - hx, x1 = x + hx, z0 = z - hz, z1 = z + hz }
end

local function overlaps(a: Item, b: Item): boolean
	-- 가장자리만 맞닿은 것은 겹친 게 아니다 (0.05 안쪽만)
	return a.x0 < b.x1 - 0.05 and b.x0 < a.x1 - 0.05 and a.z0 < b.z1 - 0.05 and b.z0 < a.z1 - 0.05
end

function ZFix.run(root: Instance): number
	local grid: { [string]: { Item } } = {}
	local bigs: { Item } = {}
	local smalls: { Item } = {}
	local moved = 0
	local count = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			count += 1
			if count % 6000 == 0 then
				task.wait()
			end
			local it = flatTop(d)
			if it then
				local cells = (math.floor(it.x1 / CELL) - math.floor(it.x0 / CELL) + 1) * (math.floor(it.z1 / CELL) - math.floor(it.z0 / CELL) + 1)
				table.insert(cells > 64 and bigs or smalls, it)
			end
		end
	end
	local function lift(it: Item, clash: (Item) -> boolean)
		local tries = 0
		while tries < 6 and clash(it) do
			it.p.CFrame += Vector3.new(0, STEP, 0)
			it.top += STEP
			tries += 1
			if tries == 1 then
				moved += 1
			end
		end
	end
	local function clashBig(it: Item, upto: number?): boolean
		for i, o in ipairs(bigs) do
			if upto and i >= upto then
				break
			end
			if o.p ~= it.p and math.abs(o.top - it.top) < GAP and overlaps(o, it) then
				return true
			end
		end
		return false
	end
	-- ① 큰 바닥끼리 (먼저 지은 것은 그대로)
	for i, it in ipairs(bigs) do
		lift(it, function(x)
			return clashBig(x, i)
		end)
	end
	-- ② 작은 것: 큰 바닥 · 먼저 넣은 작은 것과 겹치면 올린다
	for n, it in ipairs(smalls) do
		if n % 4000 == 0 then
			task.wait()
		end
		local cx0, cx1 = math.floor(it.x0 / CELL), math.floor(it.x1 / CELL)
		local cz0, cz1 = math.floor(it.z0 / CELL), math.floor(it.z1 / CELL)
		lift(it, function(x)
			if clashBig(x) then
				return true
			end
			for cx = cx0, cx1 do
				for cz = cz0, cz1 do
					local list = grid[cx .. ":" .. cz]
					if list then
						for _, o in ipairs(list) do
							if math.abs(o.top - x.top) < GAP and overlaps(o, x) then
								return true
							end
						end
					end
				end
			end
			return false
		end)
		for cx = cx0, cx1 do
			for cz = cz0, cz1 do
				local k = cx .. ":" .. cz
				local list = grid[k]
				if not list then
					list = {}
					grid[k] = list
				end
				table.insert(list, it)
			end
		end
	end
	return moved
end

return ZFix
