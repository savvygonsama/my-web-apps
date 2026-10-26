-- 권왕: 권법마다 다른 기술 장치 (서버)
-- 기술 정의의 mech = { kind = ... } 를 읽어 그 권법만의 방식으로 친다
--   zone     정해진 자리에 오래 남아 끌어당기거나 피를 빨아들이는 소용돌이
--   reflect  잠깐 모든 공격을 저절로 흘려 되받아치고, 끝에 큰 물결
--   cone     앞쪽 부채꼴 (사자후: 막기를 깬다 / 취화: 불길이 이어진다)
--   drop     가까운 적 자리에 붉은 원이 뜨고, 잠시 뒤 하늘에서 내리찍는다
--   line     앞으로 한 줄로 차례차례 솟는 기둥
--   chainTp  적들 사이를 순간이동하며 차례로 찬다
--   targets  둘레의 적 몇을 골라 그 머리 위로 내리꽂는다 (번개, 별)
--   storm    한동안 둘레 아무 데나 벼락이 쏟아진다
--   freeze   둘레의 시간이 멈추고, 멈춘 적을 한 번에 지운다
--   launch   둘레의 적을 모두 하늘로 띄웠다가 빛으로 내리친다
--   moving   내 몸을 따라다니며 계속 베는 꽃잎 폭풍
--   trail    돌진한 길에 남은 향기가 잠시 뒤 터진다
--   blackhole 하늘에 검은 해가 떠서 둘레의 적을 끌어올려 짓이기고, 끝에 안으로 무너지며 터진다
--   genesis  세상이 멈추고 별바다로 바뀐 뒤, 금이 가고, 유리처럼 깨지며 둘레의 모든 적이 함께 부서진다
--   rewind   지나간 뒤 시간이 거꾸로 돌아 제자리로 돌아오며 지나온 길을 다시 벤다
--   clock    하늘에 해시계, 둘레의 시간이 멎고 열두 번의 종마다 베이며 자정에 깨진다
--   eruption 적마다 발밑에서 불기둥이 솟고, 마지막에 내 자리에서 화산이 터진다
--   shock    기술의 마지막 타격 뒤 앞쪽에 충격파가 터진다 (맨 타격뿐인 기술을 보완)
--   tsunami  하늘을 가리는 해일이 앞으로 밀려가며 적을 휩쓸어 끌고 가고, 끝에서 부서진다
--   eclipse  하늘이 밤이 되고 해와 달이 뜬다. 달빛이 베고, 해와 달이 겹쳐 일식이 되면 빛살이 꿰뚫고, 새벽처럼 터진다
--   sakuraStorm  (초·매화 천본앵) 내 둘레가 벚꽃 칼바람의 소용돌이가 되어 끌어당기며 베고, 한가운데로 모여 터진다
--   sakuraSever  (초·매화 만앵참월, 초 오의) 보이지 않게 적들을 베고 지나가 칼자국을 남기고 → 세상이 잿빛으로 멈추고 →
--                칼바람이 적들을 휘감고 → 마지막에 터지며 화면까지 한칼에 가른다
--   zigzag   (초·취 팔선취보) 갈지자로 비틀비틀 여덟 걸음, 걸음마다 둘레를 후려친다 (그동안 무적)
--   sojuRain (초·취 취몽팔선진) 하늘로 던진 술병이 깨져 술비가 쏟아지고 (적이 굼떠진다), 불이 붙으며 여덟 취선의 그림자가 덮친다
--   drunkRush (초·취 취선만권, 초 오의) 점점 빨라지는 앞구르기 (무적) → 적에서 적으로 옮겨 다니며 와다다다 → 술병을 깨뜨려 터뜨린다
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Combat = require(script.Parent:WaitForChild("Combat"))
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Skills = {}
local Push: RemoteEvent

function Skills.init(push: RemoteEvent)
	Push = push
end

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 1e-3 and f.Unit or Vector3.new(0, 0, -1)
end

local function hostilesNear(f: any, center: Vector3, radius: number): { any }
	local out = {}
	for _, o in pairs(Combat.fighters) do
		if Combat.hostile(f, o) and not o.dead then
			local d = Vector3.new(o.root.Position.X - center.X, 0, o.root.Position.Z - center.Z).Magnitude
			if d <= radius and math.abs(o.root.Position.Y - center.Y) < 30 then
				table.insert(out, o)
			end
		end
	end
	return out
end

local function nearestList(f: any, range: number, n: number): { any }
	local list = hostilesNear(f, f.root.Position, range)
	table.sort(list, function(a, b)
		return (a.root.Position - f.root.Position).Magnitude < (b.root.Position - f.root.Position).Magnitude
	end)
	local out = {}
	for i = 1, math.min(n, #list) do
		out[i] = list[i]
	end
	return out
end

local function scaled(h: any, k: number): any
	local c = table.clone(h)
	c.dmg = (c.dmg or 0) * k
	c.posture = (c.posture or 0) * k
	return c
end

local function strike(f: any, tgt: any, h: any, move: any)
	if tgt.dead or f.dead then
		return
	end
	Combat.applyHit(f, tgt, h, { move = move, isSkill = true, chain = true })
end

local function pullTo(o: any, center: Vector3, power: number)
	local dir = Vector3.new(center.X - o.root.Position.X, 0, center.Z - o.root.Position.Z)
	if dir.Magnitude < 1.5 then
		return
	end
	local vel = dir.Unit * math.min(power, dir.Magnitude * 6)
	if o.player then
		Push:FireClient(o.player, "knock", vel, 0)
	elseif not o.root.Anchored then
		o.root.AssemblyLinearVelocity = vel + Vector3.new(0, o.root.AssemblyLinearVelocity.Y, 0)
	end
end

local function moveTo(f: any, cf: CFrame)
	if f.player and f.player.Character then
		f.player.Character:PivotTo(cf)
	else
		f.root.CFrame = cf
	end
end

local function modelsOf(list: { any }): { Model }
	local out = {}
	for _, o in ipairs(list) do
		if not o.dead and o.root.Parent then
			table.insert(out, o.model)
		end
	end
	return out
end

-- 2.2판: 점에서 (평면) 선분까지의 거리, 선분 둘레의 적, 체력 되찾기, 오른쪽
local function segDist(p: Vector3, a: Vector3, b: Vector3): number
	local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local ap = Vector3.new(p.X - a.X, 0, p.Z - a.Z)
	local len2 = ab:Dot(ab)
	local t = len2 > 1e-6 and math.clamp(ap:Dot(ab) / len2, 0, 1) or 0
	return (ap - ab * t).Magnitude
end
local function hostilesOnSeg(f: any, a: Vector3, b: Vector3, width: number): { any }
	local out = {}
	for _, o in pairs(Combat.fighters) do
		if Combat.hostile(f, o) and not o.dead and math.abs(o.root.Position.Y - a.Y) < 30 and segDist(o.root.Position, a, b) <= width then
			table.insert(out, o)
		end
	end
	return out
end
local function heal(f: any, frac: number)
	f.hp = math.min(f.maxHp, f.hp + f.maxHp * frac)
	Combat.sync(f)
end
local function rightOf(v: Vector3): Vector3
	return Vector3.new(-v.Z, 0, v.X)
end

-- 기술 하나의 장치를 돌린다. ctx = { scale, speed }
function Skills.run(f: any, move: any, ctx: any)
	local m = move.mech
	if not m then
		return
	end
	local sp = ctx.speed or 1
	-- 오의(G)는 모두 한층 더 세다. 초 오의(X)는 그보다 더
	local tail = type(move.id) == "string" and string.sub(move.id, -1) or ""
	local isUlt = tail == "G" or tail == "X"
	local sc = (ctx.scale or 1) * (isUlt and Config.ULT_MULT * (1 + (f.mUlt or 0)) or 1) * (tail == "X" and Config.SUPER_ULT_MULT or 1)
	local look = flat(Combat.look(f))
	local style = f.style
	local function alive(): boolean
		return not f.dead and f.root.Parent ~= nil
	end
	local function after(sec: number, fn: () -> ())
		task.delay(sec / sp, function()
			if alive() then
				fn()
			end
		end)
	end
	local hit = m.hit and scaled(m.hit, sc) or nil
	local kind = m.kind

	if kind == "zone" then
		local center = m.at == "self" and f.root.Position or f.root.Position + look * (m.dist or 8)
		Push:FireAllClients("skillfx", { kind = "zone", at = center, radius = m.radius, dur = m.dur / sp, style = style, fx = m.fx })
		local n = math.floor(m.dur / m.every)
		for i = 0, n - 1 do
			after((m.delay or 0) + i * m.every, function()
				local victims = hostilesNear(f, center, m.radius)
				for _, o in ipairs(victims) do
					if m.pull then
						pullTo(o, center, m.pull)
					end
					if hit then
						strike(f, o, hit, move)
					end
				end
				-- 혈해: 적 하나 벨 때마다 체력을 되찾는다
				if m.heal and #victims > 0 then
					f.hp = math.min(f.maxHp, f.hp + f.maxHp * m.heal * #victims)
					Combat.sync(f)
				end
			end)
		end
	elseif kind == "reflect" then
		f.reflectUntil = os.clock() + m.dur / sp
		f.reflectHit = hit
		Push:FireAllClients("skillfx", { kind = "reflect", m = f.model, dur = m.dur / sp, style = style })
		after(m.dur, function()
			Push:FireAllClients("skillfx", { kind = "wave", at = f.root.Position, radius = m.radius, style = style })
			for _, o in ipairs(hostilesNear(f, f.root.Position, m.radius)) do
				strike(f, o, scaled(m.wave, sc), move)
			end
		end)
	elseif kind == "cone" then
		local ticks = m.dur and math.max(1, math.floor(m.dur / m.every)) or 1
		Push:FireAllClients("skillfx", { kind = "cone", m = f.model, range = m.range, angle = m.angle, dur = (m.dur or 0.4) / sp, delay = (m.delay or 0) / sp, style = style, fx = m.fx })
		for i = 0, ticks - 1 do
			after((m.delay or 0) + i * (m.every or 0), function()
				local fwd = flat(Combat.look(f))
				local cosA = math.cos(math.rad(m.angle / 2))
				for _, o in ipairs(hostilesNear(f, f.root.Position, m.range)) do
					local to = flat(o.root.Position - f.root.Position)
					if fwd:Dot(to) >= cosA then
						strike(f, o, hit, move)
						-- 사자후: 막기를 깨부순다
						if m.guardBreak and not o.dead then
							Combat.breakGuard(o)
						end
					end
				end
			end)
		end
	elseif kind == "drop" then
		local tgt = nearestList(f, m.range or 26, 1)[1]
		local at = tgt and tgt.root.Position or f.root.Position + look * (m.dist or 10)
		at = Vector3.new(at.X, f.root.Position.Y, at.Z)
		Push:FireAllClients("skillfx", { kind = "telegraph", at = at, radius = m.radius, time = m.delay / sp, style = style })
		after(m.delay, function()
			Push:FireAllClients("skillfx", { kind = "drop", at = at, radius = m.radius, style = style, fx = m.fx })
			for _, o in ipairs(hostilesNear(f, at, m.radius)) do
				strike(f, o, hit, move)
			end
		end)
	elseif kind == "line" then
		local origin = f.root.Position
		for i = 1, m.count do
			after(m.delay + (i - 1) * m.step, function()
				local p = origin + look * (m.start + (i - 1) * m.spacing)
				Push:FireAllClients("skillfx", { kind = "pillar", at = p, radius = m.radius, style = style, i = i, fx = m.fx, dir = look })
				for _, o in ipairs(hostilesNear(f, p, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
	elseif kind == "chainTp" then
		local list = nearestList(f, m.range, m.n)
		if #list == 0 then
			return
		end
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (m.delay + #list * m.every + 0.3) / sp)
		for i = 1, m.n do
			local tgt = list[((i - 1) % #list) + 1]
			after(m.delay + (i - 1) * m.every, function()
				if tgt.dead or not tgt.root.Parent then
					return
				end
				-- 상대 등 뒤로 (돌 때마다 다른 쪽으로)
				local a = i * 2.1
				local off = Vector3.new(math.cos(a), 0, math.sin(a)) * 3.5
				local at = tgt.root.Position + off
				local cf = CFrame.lookAt(at + Vector3.new(0, 0.5, 0), Vector3.new(tgt.root.Position.X, at.Y + 0.5, tgt.root.Position.Z))
				if f.player and f.player.Character then
					f.player.Character:PivotTo(cf)
				else
					f.root.CFrame = cf
				end
				Push:FireAllClients("blink", f.model, at)
				Push:FireAllClients("skillfx", { kind = "slash", m = f.model, t = tgt.model, style = style, i = i })
				strike(f, tgt, hit, move)
			end)
		end
	elseif kind == "targets" then
		local list = nearestList(f, m.range, m.n)
		if #list == 0 then
			-- 아무도 없으면 앞에
			Push:FireAllClients("skillfx", { kind = "strike", at = f.root.Position + look * 10, radius = m.radius, style = style, fx = m.fx, delay = m.delay / sp })
			return
		end
		for i, tgt in ipairs(list) do
			local at = tgt.root.Position
			Push:FireAllClients("skillfx", { kind = "mark", at = at, radius = m.radius, time = (m.delay + (i - 1) * (m.stagger or 0)) / sp, style = style })
			after(m.delay + (i - 1) * (m.stagger or 0), function()
				local now = tgt.root.Parent and tgt.root.Position or at
				Push:FireAllClients("skillfx", { kind = "strike", at = now, radius = m.radius, style = style, fx = m.fx })
				for _, o in ipairs(hostilesNear(f, now, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
	elseif kind == "storm" then
		local n = math.floor(m.dur / m.every)
		Push:FireAllClients("skillfx", { kind = "stormcloud", m = f.model, dur = m.dur / sp, radius = m.range, style = style })
		for i = 0, n - 1 do
			after((m.delay or 0) + i * m.every, function()
				local list = hostilesNear(f, f.root.Position, m.range)
				local at
				if #list > 0 then
					at = list[math.random(1, #list)].root.Position
				else
					local a = math.random() * math.pi * 2
					at = f.root.Position + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(4, m.range)
				end
				Push:FireAllClients("skillfx", { kind = "strike", at = at, radius = m.radius, style = style, fx = "lightning", small = true })
				for _, o in ipairs(hostilesNear(f, at, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after((m.delay or 0) + m.dur, function()
			Push:FireAllClients("skillfx", { kind = "strike", at = f.root.Position + look * 4, radius = m.finalRadius, style = style, fx = "lightning" })
			for _, o in ipairs(hostilesNear(f, f.root.Position, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "freeze" then
		after(m.delay, function()
			local victims = hostilesNear(f, f.root.Position, m.radius)
			local models = {}
			for _, o in ipairs(victims) do
				Combat.stun(o, m.dur)
				o.model:SetAttribute("Frozen", true)
				table.insert(models, o.model)
			end
			Push:FireAllClients("skillfx", { kind = "freeze", at = f.root.Position, radius = m.radius, targets = models, dur = m.dur / sp, style = style })
			after(m.hitAt, function()
				for _, o in ipairs(victims) do
					if o.model.Parent then
						o.model:SetAttribute("Frozen", nil)
					end
					Push:FireAllClients("skillfx", { kind = "erase", t = o.model, style = style })
					strike(f, o, hit, move)
				end
			end)
			task.delay((m.dur + 0.2) / sp, function()
				for _, o in ipairs(victims) do
					if o.model.Parent then
						o.model:SetAttribute("Frozen", nil)
					end
				end
			end)
		end)
	elseif kind == "launch" then
		after(m.delay, function()
			local victims = hostilesNear(f, f.root.Position, m.radius)
			for _, o in ipairs(victims) do
				Combat.stun(o, m.stun or 1.5)
				o.model:SetAttribute("LaunchedAt", os.clock())
				if o.player then
					Push:FireClient(o.player, "knock", Vector3.new(0, m.up, 0), m.stun or 1.5)
				elseif not o.root.Anchored then
					o.root.AssemblyLinearVelocity = Vector3.new(0, m.up, 0)
				end
			end
			Push:FireAllClients("skillfx", { kind = "launch", at = f.root.Position, radius = m.radius, style = style })
			after(m.hitAt, function()
				Push:FireAllClients("skillfx", { kind = "beam", at = f.root.Position, radius = m.radius, style = style })
				for _, o in ipairs(victims) do
					strike(f, o, hit, move)
				end
			end)
		end)
	elseif kind == "moving" then
		Push:FireAllClients("skillfx", { kind = "moving", m = f.model, radius = m.radius, dur = m.dur / sp, style = style })
		local n = math.floor(m.dur / m.every)
		for i = 0, n - 1 do
			after((m.delay or 0) + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, f.root.Position, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
	elseif kind == "avatar" then
		-- 허상 소환 (혈마의 악마, 천룡의 용): 허상이 정해진 순간마다 내리친다
		Push:FireAllClients("skillfx", { kind = "avatar", look = m.look, m = f.model, dur = m.dur / sp, style = style, scale = m.scale })
		for idx, st in ipairs(m.strikes) do
			after(st.t, function()
				local spots = {}
				if st.at == "targets" then
					for _, o in ipairs(nearestList(f, st.range or 30, st.n or 1)) do
						table.insert(spots, o.root.Position)
					end
					if #spots == 0 then
						table.insert(spots, f.root.Position + flat(Combat.look(f)) * 10)
					end
				elseif st.at == "front" then
					table.insert(spots, f.root.Position + flat(Combat.look(f)) * (st.dist or 10))
				else
					table.insert(spots, f.root.Position)
				end
				Push:FireAllClients("skillfx", { kind = "avatarStrike", look = m.look, m = f.model, idx = idx, at = spots, radius = st.radius, style = style, last = idx == #m.strikes })
				local done = {}
				for _, p in ipairs(spots) do
					for _, o in ipairs(hostilesNear(f, p, st.radius)) do
						if not done[o] then
							done[o] = true
							strike(f, o, scaled(st.hit, sc), move)
						end
					end
				end
			end)
		end
	elseif kind == "blackhole" then
		-- 흑일강림: 앞 하늘에 검은 해. 둘레의 적이 끌려 올라가 매달린 채 짓이겨진다
		local center = f.root.Position + look * (m.dist or 12)
		local sky = center + Vector3.new(0, m.height or 16, 0)
		Push:FireAllClients("skillfx", { kind = "blackhole", at = center, height = m.height or 16, radius = m.radius, dur = m.dur / sp, delay = (m.delay or 0) / sp, style = style })
		local n = math.max(1, math.floor(m.dur / m.every))
		for i = 0, n - 1 do
			after((m.delay or 0) + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, center, m.radius)) do
					if not o.player and not o.root.Anchored then
						local d = sky - o.root.Position
						o.root.AssemblyLinearVelocity = d.Magnitude > 1 and d.Unit * math.min(70, d.Magnitude * 5) or Vector3.zero
					elseif o.player then
						pullTo(o, center, 30)
					end
					Combat.stun(o, m.every + 0.25)
					if hit then
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after((m.delay or 0) + m.dur, function()
			Push:FireAllClients("skillfx", { kind = "blackholeBurst", at = sky, radius = m.radius, style = style })
			for _, o in ipairs(hostilesNear(f, center, m.radius + 6)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "genesis" then
		-- 천지개벽: 둘레의 시간이 멈추고(모두 묶인다), 세상에 금이 가고, 깨진다
		local center = f.root.Position
		local list = hostilesNear(f, center, m.radius)
		local models = {}
		for _, o in ipairs(list) do
			Combat.stun(o, m.freeze / sp)
			if not o.player and not o.root.Anchored then
				o.root.AssemblyLinearVelocity = Vector3.zero
			end
			table.insert(models, o.model)
		end
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + m.breakAt / sp + 0.3)
		Push:FireAllClients("skillfx", { kind = "genesis", m = f.model, at = center, radius = m.radius, targets = models, dur = m.freeze / sp, crackAt = m.crackAt / sp, breakAt = m.breakAt / sp, style = style })
		after(m.breakAt, function()
			for _, o in ipairs(hostilesNear(f, center, m.radius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "rewind" then
		local start = f.root.Position
		after(m.delay, function()
			local now = f.root.Position
			Push:FireAllClients("skillfx", { kind = "rewind", m = f.model, from = now, to = start, radius = m.radius, style = style })
			local rot = f.root.CFrame - f.root.CFrame.Position
			if f.player and f.player.Character then
				f.player.Character:PivotTo(CFrame.new(start) * rot)
			else
				f.root.CFrame = CFrame.new(start) * rot
			end
			f.iframeUntil = math.max(f.iframeUntil, os.clock() + 0.3)
			-- 지나온 길 (선분) 가까이의 적을 다시 벤다
			local seg = now - start
			local len = seg.Magnitude
			for _, o in ipairs(hostilesNear(f, (start + now) / 2, len / 2 + m.radius)) do
				local p = o.root.Position - start
				local k = len > 0.1 and math.clamp(p:Dot(seg) / (len * len), 0, 1) or 0
				if (p - seg * k).Magnitude <= m.radius + 1 then
					strike(f, o, hit, move)
				end
			end
		end)
	elseif kind == "clock" then
		-- 만겁귀환: 둘레의 시간이 멎고 (모두 묶인다) 열두 번의 종, 자정에 깨진다
		local center = f.root.Position
		local total = m.delay + m.bells * m.every + 0.25
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + total / sp + 0.2)
		for _, o in ipairs(hostilesNear(f, center, m.radius)) do
			Combat.stun(o, total / sp + 0.4)
			if not o.player and not o.root.Anchored then
				o.root.AssemblyLinearVelocity = Vector3.zero
			end
		end
		Push:FireAllClients("skillfx", { kind = "clock", m = f.model, at = center, radius = m.radius, delay = m.delay / sp, bells = m.bells, every = m.every / sp, style = style })
		for i = 1, m.bells do
			after(m.delay + (i - 1) * m.every, function()
				for _, o in ipairs(hostilesNear(f, center, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after(total, function()
			for _, o in ipairs(hostilesNear(f, center, m.radius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "eruption" then
		-- 열화천멸: 적마다 발밑에서 불기둥, 마지막에 내 자리에서 화산
		local center = f.root.Position
		local list = hostilesNear(f, center, m.radius)
		local spots = {}
		for _, o in ipairs(list) do
			table.insert(spots, o.root.Position)
		end
		Push:FireAllClients("skillfx", { kind = "eruption", m = f.model, at = center, spots = spots, delay = m.delay / sp, stagger = m.stagger / sp, finalAt = m.finalAt / sp, finalRadius = m.finalRadius, style = style })
		local pillar = scaled(m.pillar, sc)
		for i, o in ipairs(list) do
			after(m.delay + (i - 1) * m.stagger, function()
				if not o.dead then
					strike(f, o, pillar, move)
				end
			end)
		end
		after(m.finalAt, function()
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "shock" then
		after(m.delay or 0.2, function()
			local at = f.root.Position + flat(Combat.look(f)) * (m.dist or 4)
			Push:FireAllClients("skillfx", { kind = "shock", at = at, radius = m.radius, style = style })
			for _, o in ipairs(hostilesNear(f, at, m.radius)) do
				strike(f, o, hit, move)
			end
		end)
	elseif kind == "tsunami" then
		-- 창해일소: 너비 width의 물의 벽이 앞으로 speed로 밀려간다. 벽 안의 적은 함께 끌려가며 계속 맞는다
		local origin = f.root.Position
		local right = Vector3.new(-look.Z, 0, look.X)
		local from = origin + look * m.start
		Push:FireAllClients("skillfx", { kind = "tsunami", from = from, dir = look, width = m.width, speed = m.speed * sp, dur = m.dur / sp, delay = m.delay / sp, style = style })
		local n = math.max(1, math.floor(m.dur / m.every))
		for i = 0, n - 1 do
			after(m.delay + i * m.every, function()
				local front = from + look * (m.speed * i * m.every)
				for _, o in ipairs(hostilesNear(f, front, m.width / 2 + m.depth)) do
					local rel = o.root.Position - front
					local along, side = rel:Dot(look), rel:Dot(right)
					if math.abs(side) <= m.width / 2 and along >= -m.depth and along <= m.depth then
						if o.player then
							Push:FireClient(o.player, "knock", look * m.speed + Vector3.new(0, 6, 0), 0.3)
						elseif not o.root.Anchored then
							o.root.AssemblyLinearVelocity = look * (m.speed * 1.15) + Vector3.new(0, 8, 0)
						end
						Combat.stun(o, m.every + 0.2)
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.delay + m.dur, function()
			local at = from + look * (m.speed * m.dur)
			Push:FireAllClients("skillfx", { kind = "tsunamiCrash", at = at, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, at, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "eclipse" then
		-- 일월동천: 달빛 베기 → 일식 (모두 묶인다) → 검은 해의 빛살 → 새벽의 폭발
		local center = f.root.Position
		local R = m.radius
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + m.finalAt / sp + 0.3)
		Push:FireAllClients("skillfx", { kind = "eclipse", m = f.model, at = center, radius = R, style = style,
			slashes = m.slashes, slashFrom = m.slashFrom / sp, slashEvery = m.slashEvery / sp,
			eclipseAt = m.eclipseAt / sp, beamAt = m.beamAt / sp, finalAt = m.finalAt / sp })
		for i = 0, m.slashes - 1 do
			after(m.slashFrom + i * m.slashEvery, function()
				for _, o in ipairs(hostilesNear(f, center, R)) do
					strike(f, o, scaled(m.slash, sc), move)
				end
			end)
		end
		after(m.bindAt, function()
			for _, o in ipairs(hostilesNear(f, center, R)) do
				Combat.stun(o, (m.finalAt - m.bindAt) / sp + 0.4)
				if not o.player and not o.root.Anchored then
					o.root.AssemblyLinearVelocity = Vector3.zero
				end
			end
		end)
		after(m.beamAt, function()
			local spots = {}
			local list = hostilesNear(f, center, R)
			for _, o in ipairs(list) do
				table.insert(spots, o.root.Position)
			end
			Push:FireAllClients("skillfx", { kind = "eclipseBeams", at = center, spots = spots, style = style })
			for _, o in ipairs(list) do
				strike(f, o, scaled(m.beam, sc), move)
			end
		end)
		after(m.finalAt, function()
			for _, o in ipairs(hostilesNear(f, center, R + 6)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "clones" then
		-- 그림자 분신: 둘레의 적마다 분신이 하나씩 나타나 동시에 찬다 (나는 그 자리에)
		local list = nearestList(f, m.range, m.n)
		local models = {}
		for _, o in ipairs(list) do
			table.insert(models, o.model)
		end
		Push:FireAllClients("skillfx", { kind = "clones", m = f.model, targets = models, style = style, every = m.every / sp, delay = m.delay / sp })
		for i, o in ipairs(list) do
			for k = 0, (m.hitsEach or 2) - 1 do
				after(m.delay + (i - 1) * m.every + k * 0.25, function()
					strike(f, o, hit, move)
				end)
			end
		end
	elseif kind == "giant" then
		-- 금강 법신: 내 몸이 금빛 거인이 된다 (안 밀리고, 받는 피해 절반, 주먹 1.6배 + 여진)
		local dur = m.dur
		f.buffs.giant = os.clock() + dur
		f.model:SetAttribute("Giant", true)
		local char = f.player and f.player.Character
		pcall(function()
			(char :: any):ScaleTo(m.scale or 2.4)
		end)
		after(m.delay or 0.4, function()
			Push:FireAllClients("skillfx", { kind = "stomp", at = f.root.Position, radius = m.radius, style = style })
			for _, o in ipairs(hostilesNear(f, f.root.Position, m.radius)) do
				strike(f, o, hit, move)
			end
		end)
		task.delay(dur, function()
			if f.model.Parent then
				f.model:SetAttribute("Giant", nil)
			end
			pcall(function()
				(char :: any):ScaleTo(1)
			end)
		end)
	elseif kind == "lake" then
		-- 태허: 발밑이 호수가 되어 소용돌이가 모두 삼키고, 마지막에 물기둥이 솟는다
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "lake", at = center, radius = m.radius, dur = m.dur / sp, style = style })
		local n = math.floor(m.dur / m.every)
		for i = 0, n - 1 do
			after(0.2 + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, center, m.radius)) do
					pullTo(o, center, m.pull)
					strike(f, o, hit, move)
				end
			end)
		end
		after(0.2 + m.dur, function()
			Push:FireAllClients("skillfx", { kind = "geyser", at = center, radius = m.geyserRadius, style = style })
			for _, o in ipairs(hostilesNear(f, center, m.geyserRadius)) do
				Combat.stun(o, 1.4)
				o.model:SetAttribute("LaunchedAt", os.clock())
				if o.player then
					Push:FireClient(o.player, "knock", Vector3.new(0, 80, 0), 1.4)
				elseif not o.root.Anchored then
					o.root.AssemblyLinearVelocity = Vector3.new(0, 80, 0)
				end
				strike(f, o, scaled(m.geyser, sc), move)
			end
		end)
	elseif kind == "sakuraStorm" then
		Push:FireAllClients("skillfx", { kind = "sakuraStorm", m = f.model, at = f.root.Position, radius = m.radius, dur = (m.delay + m.dur) / sp, style = style })
		local n = math.floor(m.dur / m.every)
		for i = 0, n - 1 do
			after(m.delay + i * m.every, function()
				local c = f.root.Position
				for _, o in ipairs(hostilesNear(f, c, m.radius)) do
					pullTo(o, c, m.pull)
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.delay + m.dur, function()
			local c = f.root.Position
			Push:FireAllClients("skillfx", { kind = "sakuraBurst", at = c, radius = m.radius, style = style })
			for _, o in ipairs(hostilesNear(f, c, m.radius + 4)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "sakuraSever" then
		local list = nearestList(f, m.range, m.n)
		local start = f.root.Position
		local pass = m.delay + math.max(1, #list) * m.every
		local total = pass + m.still + m.wind + 0.5
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + total / sp)
		f.model:SetAttribute("Vanish", true)
		Push:FireAllClients("skillfx", { kind = "severStart", m = f.model, at = start, dur = total / sp, style = style })
		-- 도중에 쓰러져도 모습은 돌아온다
		task.delay(pass / sp + 0.2, function()
			if f.model.Parent then
				f.model:SetAttribute("Vanish", nil)
			end
		end)
		-- 1) 보이지 않게 베고 지나간다 (하늘에 칼자국)
		local points = { start }
		for i, o in ipairs(list) do
			after(m.delay + (i - 1) * m.every, function()
				local from = f.root.Position
				local tp = o.root.Parent and o.root.Position or from
				local dir = flat(tp - from)
				local land = tp + dir * 5
				local cf = CFrame.lookAt(land, land + dir)
				if f.player and f.player.Character then
					f.player.Character:PivotTo(cf)
				else
					f.root.CFrame = cf
				end
				table.insert(points, land)
				Push:FireAllClients("skillfx", { kind = "severCut", from = from, to = land, at = tp, style = style, i = i })
				strike(f, o, scaled(m.cut, sc), move)
			end)
		end
		local function targetModels(): { Model }
			local out = {}
			for _, o in ipairs(list) do
				if not o.dead and o.root.Parent then
					table.insert(out, o.model)
				end
			end
			return out
		end
		-- 2) 세상이 잿빛으로 멈춘다
		after(pass, function()
			f.model:SetAttribute("Vanish", nil)
			Push:FireAllClients("skillfx", { kind = "severStill", m = f.model, at = f.root.Position, dur = m.still / sp, points = points, style = style })
			for _, o in ipairs(list) do
				if not o.dead then
					o.stunUntil = math.max(o.stunUntil, os.clock() + (m.still + m.wind + 0.4) / sp)
				end
			end
		end)
		-- 3) 칼바람이 일어 적들을 휘감는다
		after(pass + m.still, function()
			Push:FireAllClients("skillfx", { kind = "severWind", m = f.model, at = f.root.Position, targets = targetModels(), dur = m.wind / sp, style = style })
			local n = math.floor(m.wind / m.windEvery)
			for i = 0, n - 1 do
				after(i * m.windEvery, function()
					for _, o in ipairs(list) do
						if not o.dead and o.root.Parent then
							strike(f, o, scaled(m.windHit, sc), move)
						end
					end
				end)
			end
		end)
		-- 4) 터지며 한칼에 가른다
		after(pass + m.still + m.wind, function()
			local c = f.root.Position
			Push:FireAllClients("skillfx", { kind = "severEnd", m = f.model, at = c, targets = targetModels(), radius = m.finalRadius, style = style })
			local hitSet = {}
			for _, o in ipairs(list) do
				if not o.dead and o.root.Parent then
					hitSet[o] = true
					strike(f, o, scaled(m.final, sc), move)
				end
			end
			for _, o in ipairs(hostilesNear(f, c, m.finalRadius)) do
				if not hitSet[o] then
					strike(f, o, scaled(m.final, sc * 0.6), move)
				end
			end
		end)
	elseif kind == "zigzag" then
		local start = f.root.Position
		local right = Vector3.new(-look.Z, 0, look.X)
		local total = m.delay + m.n * m.every
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (total + 0.15) / sp)
		Push:FireAllClients("skillfx", { kind = "zigzagStart", m = f.model, dur = total / sp, style = style })
		for i = 1, m.n do
			after(m.delay + (i - 1) * m.every, function()
				local from = f.root.Position
				local side = i % 2 == 1 and 1 or -1
				local to = start + look * (m.step * i) + right * (side * m.side * (0.6 + math.random() * 0.5))
				to = Vector3.new(to.X, from.Y, to.Z)
				moveTo(f, CFrame.lookAt(to, to + flat(to - from)))
				Push:FireAllClients("skillfx", { kind = "zigzagStep", m = f.model, from = from, to = to, style = style, i = i })
				for _, o in ipairs(hostilesNear(f, to, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
	elseif kind == "sojuRain" then
		local c = f.root.Position
		Push:FireAllClients("skillfx", { kind = "sojuThrow", m = f.model, at = c, radius = m.radius, delay = m.delay / sp, rain = m.rain / sp, style = style })
		local n = math.floor(m.rain / m.every)
		for i = 0, n - 1 do
			after(m.delay + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, c, m.radius)) do
					o.slowUntil = os.clock() + 1
					o.slowMul = m.slow
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.delay + m.rain, function()
			local list = hostilesNear(f, c, m.radius + 2)
			Push:FireAllClients("skillfx", { kind = "sojuIgnite", m = f.model, at = c, radius = m.radius, ghosts = m.ghosts, targets = modelsOf(list), style = style })
			after(0.35, function()
				for _, o in ipairs(list) do
					if not o.dead and o.root.Parent then
						strike(f, o, scaled(m.final, sc), move)
					end
				end
			end)
		end)
	elseif kind == "drunkRush" then
		local start = f.root.Position
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (m.cut + 0.15) / sp)
		Push:FireAllClients("skillfx", { kind = "rushCut", m = f.model, dur = m.cut / sp, style = style })
		-- 1) 점점 빨라지는 앞구르기 (컷씬, 무적)
		local steps = 12
		for k = 1, steps do
			after(m.cut * k / steps, function()
				local u = k / steps
				local p = start + look * (m.roll * u * u)
				local at = Vector3.new(p.X, f.root.Position.Y, p.Z)
				moveTo(f, CFrame.lookAt(at, at + look))
			end)
		end
		-- 2) 와다다다: 적에서 적으로 옮겨 다니며 주먹을 퍼붓는다
		after(m.cut, function()
			local list = nearestList(f, m.range, m.n)
			Push:FireAllClients("skillfx", { kind = "rushFlurry", m = f.model, dur = m.rush / sp, targets = modelsOf(list), style = style })
			local ticks = math.floor(m.rush / m.every)
			local hopEvery = math.max(1, math.floor(m.hop / m.every))
			local idx = 0
			for i = 0, ticks - 1 do
				after(i * m.every, function()
					if i % hopEvery == 0 and #list > 0 then
						for _ = 1, #list do
							idx = idx % #list + 1
							local tgt = list[idx]
							if not tgt.dead and tgt.root.Parent then
								local tp = tgt.root.Position
								local dir = flat(tp - f.root.Position)
								local at = Vector3.new(tp.X, f.root.Position.Y, tp.Z) - dir * 3.2
								moveTo(f, CFrame.lookAt(at, at + dir))
								Push:FireAllClients("blink", f.model, at)
								break
							end
						end
					end
					local fwd = flat(Combat.look(f))
					for _, o in ipairs(hostilesNear(f, f.root.Position + fwd * 3, m.reach)) do
						o.stunUntil = math.max(o.stunUntil, os.clock() + 0.25)
						strike(f, o, hit, move)
					end
				end)
			end
		end)
		-- 3) 술병을 깨뜨려 터뜨린다
		after(m.cut + m.rush, function()
			local c = f.root.Position + flat(Combat.look(f)) * 3
			Push:FireAllClients("skillfx", { kind = "rushEnd", m = f.model, at = c, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, c, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "flash" or kind == "bolt" then
		-- 매화 일순천참: 보이지 않게 모두를 꿰뚫고 지나간 뒤, 한 박자 늦게 한꺼번에 베인다
		-- 벽력 뇌신화: 번개가 되어 적에서 적으로 튀며, 닿는 순간마다 벼락
		local list = nearestList(f, m.range, m.n)
		if #list == 0 then
			return
		end
		local start = f.root.Position
		local total = m.delay + #list * m.every
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (total + 0.4) / sp)
		f.model:SetAttribute("Vanish", true)
		Push:FireAllClients("skillfx", { kind = kind == "flash" and "flashStart" or "boltStart", m = f.model, dur = (total + 0.5) / sp, style = style })
		local points = { start }
		for i, o in ipairs(list) do
			after(m.delay + (i - 1) * m.every, function()
				local from = f.root.Position
				local tp = o.root.Parent and o.root.Position or from
				local dir = flat(tp - from)
				local land = tp + dir * 4
				local cf = CFrame.lookAt(land, land + dir)
				if f.player and f.player.Character then
					f.player.Character:PivotTo(cf)
				else
					f.root.CFrame = cf
				end
				table.insert(points, land)
				Push:FireAllClients("skillfx", { kind = kind == "flash" and "flashCut" or "boltJump", from = from, to = land, at = tp, style = style, i = i })
				if kind == "bolt" then
					for _, v in ipairs(hostilesNear(f, tp, m.radius or 6)) do
						strike(f, v, hit, move)
					end
				end
			end)
		end
		after(total + (kind == "flash" and 0.45 or 0.1), function()
			f.model:SetAttribute("Vanish", nil)
			if kind == "flash" then
				Push:FireAllClients("skillfx", { kind = "flashBurst", points = points, targets = (function()
					local out = {}
					for _, o in ipairs(list) do
						table.insert(out, o.model)
					end
					return out
				end)(), style = style })
				for _, o in ipairs(list) do
					strike(f, o, hit, move)
				end
			else
				Push:FireAllClients("skillfx", { kind = "strike", at = f.root.Position, radius = m.finalRadius, style = style, fx = "lightning" })
				for _, o in ipairs(hostilesNear(f, f.root.Position, m.finalRadius)) do
					strike(f, o, scaled(m.final, sc), move)
				end
			end
		end)
	elseif kind == "pinball" then
		-- 취선 굴렁쇠: 불덩이가 되어 적에서 적으로 튕겨 다니며 터진다
		local list = nearestList(f, m.range, m.n)
		Push:FireAllClients("skillfx", { kind = "fireball", m = f.model, dur = (m.delay + m.n * m.every + 0.3) / sp, style = style })
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (m.delay + m.n * m.every) / sp)
		for i = 1, m.n do
			local o = list[((i - 1) % math.max(1, #list)) + 1]
			after(m.delay + (i - 1) * m.every, function()
				local from = f.root.Position
				local to = o and o.root.Parent and o.root.Position or from + flat(Combat.look(f)) * 12
				-- 굴러가는 길을 몇 토막으로 나눠 움직인다
				for k = 1, 4 do
					task.delay(k * m.every / 5 / sp, function()
						if f.dead then
							return
						end
						local p = from:Lerp(to, k / 4)
						local dir = flat(to - from)
						local cf = CFrame.lookAt(p, p + dir)
						if f.player and f.player.Character then
							f.player.Character:PivotTo(cf)
						else
							f.root.CFrame = cf
						end
					end)
				end
				task.delay(m.every * 0.8 / sp, function()
					Push:FireAllClients("skillfx", { kind = "burst", at = to, radius = m.radius, style = style, i = i })
					for _, v in ipairs(hostilesNear(f, to, m.radius)) do
						strike(f, v, hit, move)
					end
				end)
			end)
		end
		after(m.delay + m.n * m.every + 0.1, function()
			Push:FireAllClients("skillfx", { kind = "burst", at = f.root.Position, radius = m.finalRadius, style = style, big = true })
			for _, v in ipairs(hostilesNear(f, f.root.Position, m.finalRadius)) do
				strike(f, v, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "onepunch" then
		-- 삼재 일권: 모든 것을 한 주먹에 모았다가, 앞으로 단 한 번
		Push:FireAllClients("skillfx", { kind = "charge", m = f.model, time = m.delay / sp, style = style })
		after(m.delay, function()
			local fwd = flat(Combat.look(f))
			Push:FireAllClients("skillfx", { kind = "onepunch", m = f.model, from = f.root.Position, dir = fwd, range = m.range, style = style })
			local cosA = math.cos(math.rad(m.angle / 2))
			for _, o in ipairs(hostilesNear(f, f.root.Position, m.range)) do
				if fwd:Dot(flat(o.root.Position - f.root.Position)) >= cosA then
					strike(f, o, hit, move)
				end
			end
		end)
	elseif kind == "swords" then
		-- 천제 만검: 하늘의 문에서 빛의 검이 적마다 떨어지고, 마지막에 거대한 검이 꽂혀 터진다
		Push:FireAllClients("skillfx", { kind = "skygate", m = f.model, dur = m.dur / sp, style = style })
		local list = nearestList(f, m.range, m.n)
		for i = 1, m.n do
			local o = list[((i - 1) % math.max(1, #list)) + 1]
			after(m.delay + (i - 1) * m.stagger, function()
				local at
				if o and o.root.Parent then
					at = o.root.Position
				else
					local a = math.random() * math.pi * 2
					at = f.root.Position + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(4, 16)
				end
				Push:FireAllClients("skillfx", { kind = "sword", at = at, radius = m.radius, style = style })
				task.delay(0.22 / sp, function()
					for _, v in ipairs(hostilesNear(f, at, m.radius)) do
						strike(f, v, hit, move)
					end
				end)
			end)
		end
		after(m.bigAt, function()
			local tgt = nearestList(f, m.range, 1)[1]
			local at = tgt and tgt.root.Position or f.root.Position + flat(Combat.look(f)) * 12
			Push:FireAllClients("skillfx", { kind = "telegraph", at = at, radius = m.bigRadius, time = 0.5 / sp, style = style })
			after(0.5, function()
				Push:FireAllClients("skillfx", { kind = "sword", at = at, radius = m.bigRadius, style = style, big = true })
				task.delay(0.25 / sp, function()
					for _, v in ipairs(hostilesNear(f, at, m.bigRadius)) do
						strike(f, v, scaled(m.big, sc), move)
					end
				end)
			end)
		end)
	elseif kind == "tornado" then
		-- 풍신: 거대한 회오리가 앞으로 나아가며 모두 빨아올렸다가 사방으로 내던진다
		local dir = flat(Combat.look(f))
		local from = f.root.Position + dir * (m.dist or 8)
		Push:FireAllClients("skillfx", { kind = "tornado", from = from, dir = dir, speed = m.speed * sp, dur = m.dur / sp, radius = m.radius, style = style })
		local n = math.floor(m.dur / m.every)
		local caught = {}
		for i = 0, n - 1 do
			after(i * m.every, function()
				local c = from + dir * (m.speed * i * m.every)
				for _, o in ipairs(hostilesNear(f, c, m.radius)) do
					caught[o] = true
					pullTo(o, c, 30)
					if not o.player and not o.root.Anchored then
						o.root.AssemblyLinearVelocity += Vector3.new(0, 16, 0)
					end
					Combat.stun(o, 0.4)
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.dur, function()
			local c = from + dir * (m.speed * m.dur)
			Push:FireAllClients("skillfx", { kind = "wave", at = c, radius = m.radius * 1.6, style = style })
			for o in pairs(caught) do
				if not o.dead then
					local out = flat(o.root.Position - c)
					if o.player then
						Push:FireClient(o.player, "knock", out * 60 + Vector3.new(0, 30, 0), 1)
					elseif not o.root.Anchored then
						o.root.AssemblyLinearVelocity = out * 60 + Vector3.new(0, 30, 0)
					end
					strike(f, o, scaled(m.final, sc), move)
				end
			end
		end)
	elseif kind == "arena" then
		-- 천하무쌍: 빛의 울타리 안에 가두고 한가운데로 끌어당겨 여러 번 몰아친 뒤, 마지막 한 주먹
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "arena", m = f.model, at = center, radius = m.radius, delay = m.delay / sp, strikes = m.strikeCount, every = m.every / sp, finalAt = m.finalAt / sp, style = style })
		after(m.delay * 0.5, function()
			for _, o in ipairs(hostilesNear(f, center, m.radius)) do
				pullTo(o, center + look * 4, 110)
			end
		end)
		for i = 0, m.strikeCount - 1 do
			after(m.delay + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, center, m.strikeRadius)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.finalAt, function()
			for _, o in ipairs(hostilesNear(f, center, m.strikeRadius + 4)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "galaxy" then
		-- 성하강림: 머리 위에 은하가 열리고, 별이 안에서 밖으로 나선을 그리며 떨어진 뒤, 한가운데에서 별이 터진다
		local center = f.root.Position
		local pts = {}
		for i = 1, m.count do
			local a = i * 0.95
			local r = m.radius * (0.15 + 0.85 * i / m.count)
			table.insert(pts, center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
		end
		Push:FireAllClients("skillfx", { kind = "galaxy", m = f.model, at = center, radius = m.radius, points = pts, delay = m.delay / sp, stagger = m.stagger / sp, finalAt = m.finalAt / sp, finalRadius = m.finalRadius, style = style })
		-- 처음에 둘레의 적을 가운데로 끌어당긴다
		for _, o in ipairs(hostilesNear(f, center, m.radius)) do
			pullTo(o, center, 60)
		end
		for i, p in ipairs(pts) do
			after(m.delay + (i - 1) * m.stagger, function()
				for _, o in ipairs(hostilesNear(f, p, m.strikeRadius)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.finalAt, function()
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "subspace" then
		-- 아공간: 그 자리에 바깥과 끊긴 공간을 연다. 안의 적은 빠져나가지 못하고 (가장자리에서 끌려 들어온다), 사방에서 베인다
		local center = f.root.Position
		local R = m.radius
		local delay = m.delay or 0
		Push:FireAllClients("skillfx", { kind = "subspace", m = f.model, at = center, radius = R, dur = m.dur / sp, delay = delay / sp, every = m.every / sp, style = style })
		local n = math.floor((m.dur - delay) / m.every)
		for i = 0, n - 1 do
			after(delay + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, center, R * 1.15)) do
					local off = o.root.Position - center
					if Vector3.new(off.X, 0, off.Z).Magnitude > R * 0.75 then
						pullTo(o, center, 70)
					end
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.dur, function()
			for _, o in ipairs(hostilesNear(f, center, R * 1.2)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "trail" then
		local from = f.root.Position
		after(m.delay, function()
			local to = f.root.Position
			local pts = {}
			for k = 0, m.count - 1 do
				table.insert(pts, from:Lerp(to, (k + 0.5) / m.count))
			end
			Push:FireAllClients("skillfx", { kind = "trail", points = pts, radius = m.radius, style = style, fx = m.fx })
			local done = {}
			for _, p in ipairs(pts) do
				for _, o in ipairs(hostilesNear(f, p, m.radius)) do
					if not done[o] then
						done[o] = true
						strike(f, o, hit, move)
					end
				end
			end
		end)
	elseif kind == "palm" then
		-- 1.9판 만불조종: 하늘에서 산만 한 금빛 손바닥이 내려와 둘레를 누르고, 땅이 몇 번 더 울린다
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "buddhaPalm", at = center, radius = m.radius, delay = m.delay / sp, quakes = m.quakes, every = m.every / sp, style = style })
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (m.delay + 0.3) / sp)
		after(m.delay, function()
			for _, o in ipairs(hostilesNear(f, center, m.radius)) do
				strike(f, o, hit, move)
				if not o.dead then
					Combat.stun(o, 1.6)
				end
			end
			for q = 1, m.quakes do
				after(q * m.every, function()
					for _, o in ipairs(hostilesNear(f, center, m.radius * (1 + q * 0.15))) do
						strike(f, o, scaled(m.quake, sc), move)
					end
				end)
			end
		end)
	elseif kind == "parade" then
		-- 1.9판 백귀야행: 그림자들이 둘레를 엇갈려 가로지르며 짓밟고, 마지막에 한가운데로 모여 걷어찬다
		local center = f.root.Position
		local total = m.delay + m.passes * m.every + 0.5
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + total / sp)
		Push:FireAllClients("skillfx", { kind = "paradeStart", m = f.model, at = center, radius = m.radius, ghosts = m.ghosts, dur = total / sp, style = style })
		for i = 1, m.passes do
			after(m.delay + (i - 1) * m.every, function()
				local list = hostilesNear(f, center, m.radius)
				local through = #list > 0 and list[math.random(1, #list)].root.Position or center
				local a = math.random() * math.pi * 2
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				local from = through - dir * m.radius
				local to = through + dir * m.radius
				Push:FireAllClients("skillfx", { kind = "paradePass", from = from, to = to, dur = m.every * 1.6 / sp, style = style, i = i })
				for _, o in ipairs(list) do
					local rel = o.root.Position - from
					local along = rel:Dot(dir)
					local side = rel - dir * along
					if along >= -2 and along <= m.radius * 2 + 2 and Vector3.new(side.X, 0, side.Z).Magnitude <= m.width then
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.delay + m.passes * m.every + 0.15, function()
			Push:FireAllClients("skillfx", { kind = "paradeEnd", at = center, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "waterDragons" then
		-- 1.9판 천하수류: 물의 용들이 몸을 감아 돌며 둘레를 휩쓸고, 마지막에 하나로 엉겨 앞으로 덮친다
		Push:FireAllClients("skillfx", { kind = "waterDragons", m = f.model, n = m.n, radius = m.radius, dur = m.dur / sp, delay = m.delay / sp, style = style })
		local ticks = math.floor(m.dur / m.every)
		for i = 0, ticks - 1 do
			after(m.delay + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, f.root.Position, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.delay + m.dur, function()
			local fwd = flat(Combat.look(f))
			local at = f.root.Position + fwd * m.finalDist
			Push:FireAllClients("skillfx", { kind = "dragonWave", at = at, from = f.root.Position, dir = fwd, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, at, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "reapHook" then
		-- 1.9판 혈사슬: 사슬 낫으로 둘레의 적을 낚아 내 앞으로 끌어온 뒤, 한 바퀴 돌며 벤다
		local list = nearestList(f, m.range, m.n)
		Push:FireAllClients("skillfx", { kind = "reapHook", m = f.model, targets = modelsOf(list), delay = m.delay / sp, pull = m.pull / sp, style = style })
		after(m.delay, function()
			for _, o in ipairs(list) do
				if not o.dead and o.root.Parent then
					strike(f, o, hit, move)
					o.stunUntil = math.max(o.stunUntil, os.clock() + 0.9)
				end
			end
		end)
		after(m.delay + m.pull, function()
			local fwd = flat(Combat.look(f))
			for i, o in ipairs(list) do
				if not o.dead and o.root.Parent and not o.root.Anchored then
					local a = (i - (#list + 1) / 2) * 0.7
					local side = Vector3.new(fwd.Z, 0, -fwd.X)
					local at = f.root.Position + fwd * 4 + side * a * 3
					if o.player then
						Push:FireClient(o.player, "knock", (at - o.root.Position) * 4, 0.4)
					else
						o.root.CFrame = CFrame.lookAt(Vector3.new(at.X, o.root.Position.Y, at.Z), f.root.Position)
					end
				end
			end
		end)
		after(m.delay + m.pull + 0.12, function()
			Push:FireAllClients("skillfx", { kind = "reapSpin", m = f.model, radius = m.radius, style = style })
			for _, o in ipairs(hostilesNear(f, f.root.Position, m.radius)) do
				strike(f, o, scaled(m.slash, sc), move)
			end
		end)
	elseif kind == "reapCleave" then
		-- 1.9판 혈월낙참: 내리꽂은 낫이 앞의 땅에 핏빛 초승달 자국을 새기고, 한 박자 뒤 자국이 터진다
		after(m.delay, function()
			local fwd = flat(Combat.look(f))
			local from = f.root.Position + fwd * 2
			local mid = from + fwd * (m.length / 2)
			Push:FireAllClients("skillfx", { kind = "reapScar", at = mid, dir = fwd, length = m.length, width = m.width, burst = m.burst / sp, style = style })
			local function inStrip(o: any): boolean
				local rel = o.root.Position - from
				local along = rel:Dot(fwd)
				local side = rel - fwd * along
				return along >= -2 and along <= m.length and Vector3.new(side.X, 0, side.Z).Magnitude <= m.width
			end
			for _, o in ipairs(hostilesNear(f, mid, m.length)) do
				if inStrip(o) then
					strike(f, o, hit, move)
				end
			end
			after(m.burst, function()
				for _, o in ipairs(hostilesNear(f, mid, m.length)) do
					if inStrip(o) then
						strike(f, o, scaled(m.burstHit, sc), move)
					end
				end
			end)
		end)
	elseif kind == "harvest" then
		-- 1.9판 혈마수확: 하늘만 한 피의 낫이 둘레를 휩쓴다. 베인 적에 낙인, 낫이 꽂히면 낙인이 한꺼번에 터진다
		local marked: { [any]: boolean } = {}
		local total = m.delay + m.sweeps * m.sweepTime
		Push:FireAllClients("skillfx", { kind = "harvest", m = f.model, radius = m.radius, delay = m.delay / sp, sweeps = m.sweeps, sweepTime = m.sweepTime / sp, mark = m.mark / sp, style = style })
		for k = 1, m.sweeps do
			-- 한 바퀴를 넷으로 나눠 친다 (낫이 지나가는 쪽부터)
			for q = 0, 3 do
				after(m.delay + (k - 1) * m.sweepTime + q * m.sweepTime / 4, function()
					local victims = hostilesNear(f, f.root.Position, m.radius)
					local n = 0
					for _, o in ipairs(victims) do
						local rel = flat(o.root.Position - f.root.Position)
						local ang = (math.atan2(rel.X, rel.Z) / (math.pi * 2)) % 1
						if math.floor(ang * 4) == q then
							strike(f, o, hit, move)
							marked[o] = true
							n += 1
						end
					end
					if m.heal and n > 0 then
						f.hp = math.min(f.maxHp, f.hp + f.maxHp * m.heal * n)
						Combat.sync(f)
					end
				end)
			end
		end
		after(total + m.mark, function()
			local list = {}
			for o in pairs(marked) do
				if not o.dead and o.root.Parent then
					table.insert(list, o)
				end
			end
			Push:FireAllClients("skillfx", { kind = "harvestBurst", m = f.model, targets = modelsOf(list), at = f.root.Position, radius = m.radius, style = style })
			for _, o in ipairs(list) do
				strike(f, o, scaled(m.burst, sc), move)
			end
		end)
	elseif kind == "bloodMoon" then
		-- 1.9판 혈월만겸 (초 오의): 핏빛 하늘과 붉은 달 (컷씬, 무적) → 핏빛 초승달이 쏟아진다 → 하늘과 땅을 가르는 마지막 낫질
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (m.cut + m.rain + 0.4) / sp)
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "moonRise", m = f.model, at = center, dur = (m.cut + m.rain + 0.6) / sp, cut = m.cut / sp, range = m.range, style = style })
		local ticks = math.floor(m.rain / m.every)
		for i = 0, ticks - 1 do
			after(m.cut + i * m.every, function()
				local list = hostilesNear(f, center, m.range)
				local spots = {}
				for _ = 1, m.n do
					local at
					if #list > 0 and math.random() < 0.7 then
						at = list[math.random(1, #list)].root.Position
					else
						local a = math.random() * math.pi * 2
						at = center + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(4, math.floor(m.range))
					end
					table.insert(spots, at)
				end
				Push:FireAllClients("skillfx", { kind = "moonSlash", m = f.model, spots = spots, radius = m.radius, style = style })
				local done = {}
				for _, at in ipairs(spots) do
					for _, o in ipairs(hostilesNear(f, at, m.radius)) do
						if not done[o] then
							done[o] = true
							o.stunUntil = math.max(o.stunUntil, os.clock() + 0.2)
							strike(f, o, hit, move)
						end
					end
				end
			end)
		end
		after(m.cut + m.rain + 0.15, function()
			local fwd = flat(Combat.look(f))
			local c = f.root.Position + fwd * 6
			Push:FireAllClients("skillfx", { kind = "moonCleave", m = f.model, at = c, dir = fwd, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, c, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	------------------------------------------------------------------------
	-- 2.0판: 새 오의들 (각성 권법 아홉 · 초·벽력신권)
	------------------------------------------------------------------------
	elseif kind == "bloodSea" then
		-- 진 혈마신수 혈해만마: 발밑이 피의 바다가 되고, 피에서 마수의 손톱이 연달아 솟는다. 마지막에 바다가 소용돌이 기둥으로 솟아 터진다
		local center = f.root.Position
		local total = m.delay + m.claws * m.every
		Push:FireAllClients("skillfx", { kind = "bloodSea", at = center, radius = m.radius, dur = (total + 0.6) / sp, style = style })
		for i = 1, m.claws do
			after(m.delay + (i - 1) * m.every, function()
				local list = hostilesNear(f, center, m.radius)
				local at
				if #list > 0 then
					at = list[(i - 1) % #list + 1].root.Position
				else
					local a = math.random() * math.pi * 2
					at = center + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(4, math.floor(m.radius))
				end
				Push:FireAllClients("skillfx", { kind = "bloodClaw", at = at, radius = m.clawRadius, style = style, i = i })
				local n = 0
				for _, o in ipairs(hostilesNear(f, at, m.clawRadius)) do
					strike(f, o, hit, move)
					n += 1
				end
				if n > 0 and m.heal then
					f.hp = math.min(f.maxHp, f.hp + f.maxHp * m.heal * n)
					Combat.sync(f)
				end
			end)
		end
		after(total + 0.2, function()
			Push:FireAllClients("skillfx", { kind = "bloodVortex", at = center, radius = m.radius, style = style })
			for _, o in ipairs(hostilesNear(f, center, m.radius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "nineDragons" or kind == "fireDragon" or kind == "thunderDragon" then
		-- 용 오의 셋: 구룡승천 (금룡 아홉) · 화룡천멸 (불의 용 하나) · 뇌룡승천 (번개의 용)
		-- 1) 용이 솟는다 (둘레를 친다) 2) 하늘에서 적들에게 차례로 내리꽂힌다 3) 마지막에 한가운데가 터진다
		local center = f.root.Position
		local n = m.n or 1
		Push:FireAllClients("skillfx", { kind = "dragonsRise", m = f.model, at = center, n = n, radius = m.ringRadius or 10, rise = m.rise / sp, look = kind, style = style })
		after(0.25, function()
			for _, o in ipairs(hostilesNear(f, center, (m.ringRadius or 10) + 6)) do
				strike(f, o, scaled(m.riseHit, sc), move)
			end
		end)
		local list = nearestList(f, m.range, m.dives)
		for i = 1, m.dives do
			after(m.rise + (i - 1) * m.every, function()
				local tgt = list[#list > 0 and ((i - 1) % #list + 1) or 1]
				local at
				if tgt and not tgt.dead and tgt.root.Parent then
					at = tgt.root.Position
				else
					local a = math.random() * math.pi * 2
					at = f.root.Position + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(6, 18)
				end
				Push:FireAllClients("skillfx", { kind = "dragonDive", at = at, radius = m.diveRadius, look = kind, style = style, i = i, from = f.root.Position })
				for _, o in ipairs(hostilesNear(f, at, m.diveRadius)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.rise + m.dives * m.every + 0.25, function()
			local c = f.root.Position
			Push:FireAllClients("skillfx", { kind = "dragonsEnd", at = c, radius = m.finalRadius, look = kind, style = style })
			for _, o in ipairs(hostilesNear(f, c, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
			-- 화룡: 떨어진 자리가 용암이 되어 몇 번 더 터진다
			for q = 1, m.lava or 0 do
				after(q * 0.45, function()
					Push:FireAllClients("skillfx", { kind = "lavaBurst", at = c, radius = m.finalRadius, style = style, i = q })
					for _, o in ipairs(hostilesNear(f, c, m.finalRadius)) do
						strike(f, o, scaled(m.lavaHit, sc), move)
					end
				end)
			end
		end)
	elseif kind == "thunderNet" then
		-- 진 벽력신권 뇌정천망: 둘레의 적을 모두 번개 그물로 잇는다. 그물이 몇 번 고동치고, 마지막에 적마다 벼락이 떨어진다
		local list = nearestList(f, m.range, m.n)
		Push:FireAllClients("skillfx", { kind = "netStart", m = f.model, targets = modelsOf(list), dur = (m.delay + m.pulses * m.every) / sp, style = style })
		for i = 1, m.pulses do
			after(m.delay + (i - 1) * m.every, function()
				Push:FireAllClients("skillfx", { kind = "netPulse", m = f.model, targets = modelsOf(list), style = style, i = i })
				for _, o in ipairs(list) do
					if not o.dead then
						o.stunUntil = math.max(o.stunUntil, os.clock() + m.every + 0.1)
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.delay + m.pulses * m.every + 0.1, function()
			Push:FireAllClients("skillfx", { kind = "netEnd", m = f.model, targets = modelsOf(list), style = style })
			for _, o in ipairs(list) do
				for _, v in ipairs(hostilesNear(f, o.root.Position, m.finalRadius)) do
					strike(f, v, scaled(m.final, sc), move)
				end
			end
		end)
	elseif kind == "thousandArms" then
		-- 진 금강불괴신공 천수여래: 등 뒤로 거대한 금빛 여래가 솟아 여러 팔로 적들을 차례로 내리치고, 마지막에 하늘의 손바닥이 땅을 누른다
		local center = f.root.Position
		local list = nearestList(f, m.range, m.count)
		Push:FireAllClients("skillfx", { kind = "armsStart", m = f.model, dur = (m.delay + m.count * m.every + m.palmDelay + 0.6) / sp, style = style })
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (m.delay + m.count * m.every + 0.3) / sp)
		for i = 1, m.count do
			after(m.delay + (i - 1) * m.every, function()
				local tgt = list[#list > 0 and ((i - 1) % #list + 1) or 1]
				local at = (tgt and not tgt.dead and tgt.root.Parent) and tgt.root.Position or (f.root.Position + look * (6 + i))
				Push:FireAllClients("skillfx", { kind = "armStrike", m = f.model, at = at, radius = m.armRadius, style = style, i = i })
				for _, o in ipairs(hostilesNear(f, at, m.armRadius)) do
					strike(f, o, hit, move)
				end
			end)
		end
		local palmAt = m.delay + m.count * m.every
		after(palmAt, function()
			Push:FireAllClients("skillfx", { kind = "buddhaPalm", at = center, radius = m.radius, delay = m.palmDelay / sp, quakes = 2, every = 0.35 / sp, style = style })
		end)
		after(palmAt + m.palmDelay, function()
			for _, o in ipairs(hostilesNear(f, center, m.radius)) do
				strike(f, o, scaled(m.final, sc), move)
				if not o.dead then
					Combat.stun(o, 1.4)
				end
			end
		end)
	elseif kind == "shadowKill" then
		-- 진 무영귀각 무영천살: 세상이 어두워지고 몸이 사라진다. 적들에게 붉은 표식이 하나씩 새겨지고, 한꺼번에 터진 뒤 하늘에서 그림자의 발이 짓밟는다
		local list = nearestList(f, m.range, m.n)
		local total = m.delay + #list * m.every + m.hold
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (total + 0.6) / sp)
		f.model:SetAttribute("Vanish", true)
		Push:FireAllClients("skillfx", { kind = "darkStart", m = f.model, at = f.root.Position, dur = (total + 0.6) / sp, radius = m.range, style = style })
		for i, o in ipairs(list) do
			after(m.delay + (i - 1) * m.every, function()
				if not o.dead and o.root.Parent then
					o.stunUntil = math.max(o.stunUntil, os.clock() + total)
					Push:FireAllClients("skillfx", { kind = "killMark", t = o.model, style = style, i = i })
				end
			end)
		end
		after(total, function()
			f.model:SetAttribute("Vanish", nil)
			Push:FireAllClients("skillfx", { kind = "killBurst", targets = modelsOf(list), style = style })
			for _, o in ipairs(list) do
				strike(f, o, hit, move)
			end
		end)
		after(total + 0.35, function()
			local c = f.root.Position + look * 6
			Push:FireAllClients("skillfx", { kind = "shadowStomp", at = c, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, c, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
		task.delay((total + 0.8) / sp, function()
			if f.model.Parent then
				f.model:SetAttribute("Vanish", nil)
			end
		end)
	elseif kind == "maelstrom" or kind == "abyss" then
		-- 진 태허유수장 창해만류: 큰 소용돌이가 적을 가운데로 빨아들이고, 둘레에 솟은 물의 벽이 안쪽으로 무너진다
		-- 진 창해신권 심해강림: 땅이 깊은 바다가 되어 적이 가라앉고 (묶인다), 한가운데서 거대한 물기둥이 솟아 하늘로 쳐올린다
		local center = f.root.Position + look * (m.dist or 0)
		Push:FireAllClients("skillfx", { kind = kind, at = center, radius = m.radius, dur = m.dur / sp, style = style })
		local n = math.floor(m.dur / m.every)
		for i = 0, n - 1 do
			after(m.delay + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, center, m.radius)) do
					if m.pull then
						pullTo(o, center, m.pull)
					end
					if kind == "abyss" then
						o.stunUntil = math.max(o.stunUntil, os.clock() + m.every + 0.15)
					end
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.delay + m.dur, function()
			Push:FireAllClients("skillfx", { kind = kind .. "End", at = center, radius = m.radius, style = style })
			for _, o in ipairs(hostilesNear(f, center, m.radius)) do
				strike(f, o, scaled(m.final, sc), move)
				if kind == "abyss" and not o.dead then
					o.model:SetAttribute("LaunchedAt", os.clock())
					if o.player then
						Push:FireClient(o.player, "knock", Vector3.new(0, 70, 0), 1.2)
					elseif not o.root.Anchored then
						o.root.AssemblyLinearVelocity = Vector3.new(0, 70, 0)
					end
				end
			end
		end)
	elseif kind == "galeBlades" then
		-- 진 풍신각 천풍만검: 바람의 칼날이 몸을 돌다가 사방으로 쏘아지고, 마지막에 한가운데 회오리가 모두 들어 올려 내던진다
		Push:FireAllClients("skillfx", { kind = "galeBlades", m = f.model, n = m.blades, radius = m.orbit, spin = m.spin / sp, style = style })
		local ticks = math.floor(m.spin / m.every)
		for i = 0, ticks - 1 do
			after(m.delay + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, f.root.Position, m.orbit + 3)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.delay + m.spin, function()
			local c = f.root.Position
			Push:FireAllClients("skillfx", { kind = "galeShoot", at = c, n = m.blades, range = m.range, style = style })
			for _, o in ipairs(hostilesNear(f, c, m.range)) do
				strike(f, o, scaled(m.shoot, sc), move)
			end
		end)
		after(m.delay + m.spin + 0.5, function()
			local c = f.root.Position + look * 8
			Push:FireAllClients("skillfx", { kind = "galeTwister", at = c, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, c, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "heavenThunder" then
		-- 초·벽력신권 구천뇌정 (초 오의): 하늘이 갈라지고 천둥의 눈이 뜬다 (컷씬, 무적)
		-- 2.2판: 눈이 둘레의 적을 하나하나 겨누고 (조준 고리), 겨눈 차례대로 심판의 벼락이 내리꽂힌다 → 마지막에 하늘에서 땅까지 벼락 기둥
		local total = m.cut + m.rain
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (total + 0.4) / sp)
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "thunderEye", m = f.model, at = center, dur = (total + 0.5) / sp, range = m.range, style = style })
		after(m.cut - 0.1, function()
			local list = nearestList(f, m.range, m.n)
			Push:FireAllClients("skillfx", { kind = "lockOn", targets = modelsOf(list), dur = (m.rain + 0.2) / sp, style = style })
			local strikes = math.floor(m.rain / m.every)
			for i = 1, strikes do
				after(0.2 + (i - 1) * m.every, function()
					local tgt = #list > 0 and list[(i - 1) % #list + 1] or nil
					local at
					if tgt and not tgt.dead and tgt.root.Parent then
						at = tgt.root.Position
					else
						local a = math.random() * math.pi * 2
						at = center + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(4, math.max(5, math.floor(m.range * 0.6)))
					end
					Push:FireAllClients("skillfx", { kind = "judgeBolt", at = at, radius = m.radius, i = i, style = style })
					for _, o in ipairs(hostilesNear(f, at, m.radius)) do
						o.stunUntil = math.max(o.stunUntil, os.clock() + 0.35)
						strike(f, o, hit, move)
					end
				end)
			end
		end)
		after(total + 0.15, function()
			local c = f.root.Position + flat(Combat.look(f)) * 5
			Push:FireAllClients("skillfx", { kind = "thunderPillar", at = c, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, c, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)

	------------------------------------------------------------------------
	-- 2.2판: 각성 권법 아홉의 새 E·R, 진 열화·진 창해의 새 오의, 초·벽력신권의 새 R·오의
	------------------------------------------------------------------------
	elseif kind == "thunderDrums" then
		-- 초·벽력신권 뇌고천무 (초 오의, 2.3판): 등 뒤 하늘에 뇌고 여덟이 둥글게 뜬다 (컷씬, 무적).
		-- 북을 열여섯 번 친다 (점점 빨라진다). 칠 때마다 그 북에서 적에게 벼락이 꽂히고, 네 번째마다 둘레로 천둥이 울린다.
		-- 마지막에 북이 모두 한가운데로 모여 하나의 뇌구가 되어 앞의 땅에 내리꽂힌다
		local gaps = {}
		local sum = 0
		for i = 1, m.beats do
			local u = (i - 1) / math.max(1, m.beats - 1)
			gaps[i] = m.first + (m.last - m.first) * u
			sum += gaps[i]
		end
		local total = m.cut + sum + m.finaleDelay
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (total + 0.3) / sp)
		Push:FireAllClients("skillfx", { kind = "drumRing", m = f.model, n = m.drums, dur = (total + 0.4) / sp, style = style })
		local list = nearestList(f, m.range, m.n)
		local tAt = m.cut
		for i = 1, m.beats do
			tAt += gaps[i]
			after(tAt, function()
				local tgt = #list > 0 and list[(i - 1) % #list + 1] or nil
				local at
				if tgt and not tgt.dead and tgt.root.Parent then
					at = tgt.root.Position
				else
					local a = math.random() * math.pi * 2
					at = f.root.Position + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(5, 16)
				end
				local shock = i % 4 == 0
				Push:FireAllClients("skillfx", { kind = "drumBeat", m = f.model, drum = (i - 1) % m.drums + 1, at = at, radius = m.radius, i = i, shock = shock, shockRadius = m.shockRadius, style = style })
				for _, o in ipairs(hostilesNear(f, at, m.radius)) do
					o.stunUntil = math.max(o.stunUntil, os.clock() + 0.3)
					strike(f, o, hit, move)
				end
				if shock then
					for _, o in ipairs(hostilesNear(f, f.root.Position, m.shockRadius)) do
						strike(f, o, scaled(m.shock, sc), move)
					end
				end
			end)
		end
		after(total, function()
			local c = f.root.Position + flat(Combat.look(f)) * m.finaleDist
			Push:FireAllClients("skillfx", { kind = "drumFinale", m = f.model, at = c, radius = m.finalRadius, fall = 0.3 / sp, style = style })
			after(0.3, function()
				for _, o in ipairs(hostilesNear(f, c, m.finalRadius)) do
					strike(f, o, scaled(m.final, sc), move)
					if not o.dead then
						Combat.stun(o, 1.5)
					end
				end
			end)
		end)
	elseif kind == "seedBurst" then
		-- 만목신권 종자탄: 씨앗 다섯을 부채꼴로 튕긴다 (가까운 적이 있으면 그 몸에 박힌다). 잠시 뒤 가시덤불로 터져 묶는다
		local from = f.root.Position
		local half = math.rad(m.spread / 2)
		local enemies = hostilesNear(f, from, m.range)
		local spots = {}
		for i = 1, m.n do
			local a = -half + (2 * half) * (i - 1) / math.max(1, m.n - 1)
			local d = (CFrame.Angles(0, a, 0) * CFrame.new(look)).Position
			local at = from + d * m.dist
			local best, bd = nil, 8
			for _, o in ipairs(enemies) do
				local dd = (o.root.Position - at).Magnitude
				if dd < bd then
					best, bd = o, dd
				end
			end
			spots[i] = best and best.root.Position or at
		end
		Push:FireAllClients("skillfx", { kind = "seedShot", from = from, spots = spots, delay = m.delay / sp, sprout = m.sprout / sp, style = style })
		after(m.delay + 0.15, function()
			local done = {}
			for _, at in ipairs(spots) do
				for _, o in ipairs(hostilesNear(f, at, 2.5)) do
					if not done[o] then
						done[o] = true
						strike(f, o, hit, move)
					end
				end
			end
		end)
		-- 남은 가시덤불이 한동안 찌른다
		for i = 1, math.floor((m.linger or 0) / (m.every or 0.3)) do
			after(m.delay + m.sprout + i * m.every, function()
				local done = {}
				for _, at in ipairs(spots) do
					for _, o in ipairs(hostilesNear(f, at, m.radius)) do
						if not done[o] then
							done[o] = true
							strike(f, o, scaled(m.tick, sc), move)
						end
					end
				end
			end)
		end
		after(m.delay + m.sprout, function()
			Push:FireAllClients("skillfx", { kind = "thornSprout", spots = spots, radius = m.radius, linger = (m.linger or 0) / sp, style = style })
			local done = {}
			for _, at in ipairs(spots) do
				for _, o in ipairs(hostilesNear(f, at, m.radius)) do
					if not done[o] then
						done[o] = true
						strike(f, o, scaled(m.burst, sc), move)
						if not o.dead then
							Combat.stun(o, m.root)
						end
					end
				end
			end
		end)
	elseif kind == "bloomBud" then
		-- 만목신권 개화: 앞의 땅에서 거대한 꽃봉오리가 솟고, 활짝 피며 꽃가루가 터진다 (적은 잠들고 나는 체력을 되찾는다)
		local at = f.root.Position + look * m.dist
		Push:FireAllClients("skillfx", { kind = "budRise", at = at, radius = m.radius, delay = m.delay / sp, sleep = m.sleep / sp, style = style })
		after(m.delay, function()
			Push:FireAllClients("skillfx", { kind = "budBloom", at = at, radius = m.radius, sleep = m.sleep / sp, style = style })
			for _, o in ipairs(hostilesNear(f, at, m.radius)) do
				strike(f, o, hit, move)
				if not o.dead then
					Combat.stun(o, m.sleep)
				end
			end
			heal(f, m.heal)
		end)
		-- 꽃잎 회오리: 핀 꽃에서 꽃잎이 둘레로 휘몰아쳐 한 번 더 친다
		if m.wave then
			after(m.delay + m.wave, function()
				Push:FireAllClients("skillfx", { kind = "budPetals", at = at, radius = m.waveRadius, style = style })
				for _, o in ipairs(hostilesNear(f, at, m.waveRadius)) do
					strike(f, o, scaled(m.waveHit, sc), move)
				end
			end)
		end
	elseif kind == "treant" then
		-- 만목신권 목령강림 (오의): 등 뒤에서 거대한 나무 정령이 솟아 앞을 내리치고, 팔로 휩쓸고, 땅 곳곳에서 뿌리가 솟는다
		local base = f.root.Position
		local lk = look
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + m.rise / sp)
		Push:FireAllClients("skillfx", { kind = "treantRise", m = f.model, at = base, dir = lk, rise = m.rise / sp, sweep = m.sweepAt / sp, roots = m.rootsAt / sp, dur = (m.rootsAt + 0.9) / sp, style = style })
		after(m.rise, function()
			local at = base + lk * m.slamDist
			Push:FireAllClients("skillfx", { kind = "treantSlam", at = at, radius = m.slamRadius, style = style })
			for _, o in ipairs(hostilesNear(f, at, m.slamRadius)) do
				strike(f, o, scaled(m.slam, sc), move)
			end
		end)
		after(m.sweepAt, function()
			local cosA = math.cos(math.rad(m.sweepAngle / 2))
			Push:FireAllClients("skillfx", { kind = "treantSweep", at = base, dir = lk, range = m.sweepRange, angle = m.sweepAngle, style = style })
			for _, o in ipairs(hostilesNear(f, base, m.sweepRange)) do
				if flat(o.root.Position - base):Dot(lk) >= cosA or (o.root.Position - base).Magnitude < 5 then
					strike(f, o, scaled(m.sweep, sc), move)
				end
			end
		end)
		-- 잎 폭풍: 휩쓴 뒤 나무 정령의 잎이 둘레에 쏟아진다
		if m.leafTicks then
			local gap = (m.rootsAt - m.sweepAt - 0.3) / m.leafTicks
			after(m.sweepAt + 0.2, function()
				Push:FireAllClients("skillfx", { kind = "leafStorm", at = base, radius = m.leafRadius, dur = (gap * m.leafTicks) / sp, style = style })
			end)
			for i = 1, m.leafTicks do
				after(m.sweepAt + 0.2 + i * gap, function()
					for _, o in ipairs(hostilesNear(f, base, m.leafRadius)) do
						strike(f, o, scaled(m.leaf, sc), move)
					end
				end)
			end
		end
		after(m.rootsAt, function()
			local list = nearestList(f, m.rootRange, m.roots)
			local spots = {}
			for i = 1, m.roots do
				local o = list[i]
				if o and o.root.Parent then
					spots[i] = o.root.Position
				else
					local a = math.random() * math.pi * 2
					spots[i] = base + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(6, math.max(7, math.floor(m.rootRange)))
				end
			end
			Push:FireAllClients("skillfx", { kind = "treantRoots", spots = spots, radius = m.rootRadius, style = style })
			local done = {}
			for _, at in ipairs(spots) do
				for _, o in ipairs(hostilesNear(f, at, m.rootRadius)) do
					if not done[o] then
						done[o] = true
						strike(f, o, scaled(m.root, sc), move)
					end
				end
			end
			heal(f, m.heal)
		end)
	elseif kind == "bloodNeedles" then
		-- 진 혈마 혈침: 피의 바늘을 적들에게 꽂고, 잠시 뒤 바늘이 몸속에서 터지며 체력을 빨아온다
		local list = nearestList(f, m.range, m.n)
		Push:FireAllClients("skillfx", { kind = "needleShot", m = f.model, targets = modelsOf(list), delay = m.delay / sp, mark = m.mark / sp, style = style })
		after(m.delay + 0.12, function()
			for _, o in ipairs(list) do
				strike(f, o, hit, move)
			end
		end)
		after(m.delay + m.mark, function()
			local spots = {}
			local n = 0
			for _, o in ipairs(list) do
				if o.root.Parent then
					local at = o.root.Position
					table.insert(spots, at)
					for _, v in ipairs(hostilesNear(f, at, m.radius)) do
						strike(f, v, scaled(m.burst, sc), move)
						n += 1
					end
				end
			end
			Push:FireAllClients("skillfx", { kind = "needleBurst", spots = spots, radius = m.radius, style = style })
			if n > 0 then
				heal(f, m.heal * math.min(n, 6))
			end
		end)
	elseif kind == "bloodGrip" then
		-- 진 혈마 혈마수인: 앞의 땅에서 피의 손이 솟아 움켜쥐고, 쥐어짜고, 내리꽂는다
		local at = f.root.Position + look * m.dist
		Push:FireAllClients("skillfx", { kind = "gripRise", at = at, radius = m.radius, dur = (m.delay + (m.squeezes + 1) * m.every + 0.4) / sp, delay = m.delay / sp, style = style })
		local caught: { any } = {}
		after(m.delay, function()
			caught = hostilesNear(f, at, m.radius)
			for _, o in ipairs(caught) do
				Combat.stun(o, (m.squeezes * m.every + 0.4) / sp)
				strike(f, o, hit, move)
			end
		end)
		for i = 1, m.squeezes do
			after(m.delay + i * m.every, function()
				Push:FireAllClients("skillfx", { kind = "gripSqueeze", at = at, radius = m.radius, i = i, style = style })
				for _, o in ipairs(caught) do
					strike(f, o, scaled(m.squeeze, sc), move)
				end
			end)
		end
		after(m.delay + (m.squeezes + 1) * m.every, function()
			Push:FireAllClients("skillfx", { kind = "gripSlam", at = at, radius = m.radius, style = style })
			for _, o in ipairs(hostilesNear(f, at, m.radius + 2)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "dragonRoar" then
		-- 진 천룡 용음: 앞쪽 부채꼴로 금룡의 울음. 멀리 날리고 몸을 굳힌다
		local origin = f.root.Position
		local cosA = math.cos(math.rad(m.angle / 2))
		Push:FireAllClients("skillfx", { kind = "dragonRoar", m = f.model, at = origin, dir = look, range = m.range, angle = m.angle, style = style })
		after(m.delay, function()
			for _, o in ipairs(hostilesNear(f, origin, m.range)) do
				local d = flat(o.root.Position - origin)
				if d:Dot(look) >= cosA or (o.root.Position - origin).Magnitude < 4 then
					strike(f, o, hit, move)
					if not o.dead then
						Combat.stun(o, m.stun)
					end
				end
			end
		end)
	elseif kind == "dragonPalm" then
		-- 진 천룡 항룡장: 금룡 머리 모양의 장력이 앞으로 뻗어 꿰뚫고, 끝에서 터진다
		local from = f.root.Position + look * 2
		local travel = m.length / m.speed
		Push:FireAllClients("skillfx", { kind = "palmWave", from = from, dir = look, length = m.length, time = travel / sp, delay = m.delay / sp, width = m.width, style = style })
		local done = {}
		local steps = math.max(1, math.floor(travel / 0.05))
		for i = 1, steps do
			after(m.delay + i * travel / steps, function()
				local a = from + look * (m.length * (i - 1) / steps)
				local b = from + look * (m.length * i / steps)
				for _, o in ipairs(hostilesOnSeg(f, a, b, m.width)) do
					if not done[o] then
						done[o] = true
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.delay + travel, function()
			local endAt = from + look * m.length
			Push:FireAllClients("skillfx", { kind = "palmBurst", at = endAt, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, endAt, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "sigils" then
		-- 진 벽력 뇌인진: 둘레 네 곳에 뇌인을 새긴다. 적이 밟으면 벼락 (뇌인마다 두 번), 끝에 모두 터진다
		local c = f.root.Position
		local right = rightOf(look)
		local spots = {}
		for k = 0, m.n - 1 do
			local a = (k / m.n) * math.pi * 2 + math.pi / 4
			table.insert(spots, c + (look * math.cos(a) + right * math.sin(a)) * m.dist)
		end
		Push:FireAllClients("skillfx", { kind = "sigilsPlace", spots = spots, radius = m.radius, dur = (m.delay + m.dur) / sp, style = style })
		local left = {}
		for i = 1, #spots do
			left[i] = m.charges
		end
		local ticks = math.floor(m.dur / m.every)
		for t = 1, ticks do
			after(m.delay + t * m.every, function()
				for i, at in ipairs(spots) do
					if left[i] > 0 then
						local list = hostilesNear(f, at, m.radius)
						if #list > 0 then
							left[i] -= 1
							Push:FireAllClients("skillfx", { kind = "sigilBolt", at = at, radius = m.radius, style = style })
							for _, o in ipairs(list) do
								strike(f, o, hit, move)
							end
						end
					end
				end
			end)
		end
		after(m.delay + m.dur + 0.05, function()
			for _, at in ipairs(spots) do
				Push:FireAllClients("skillfx", { kind = "sigilBolt", at = at, radius = m.finalRadius, big = true, style = style })
				for _, o in ipairs(hostilesNear(f, at, m.finalRadius)) do
					strike(f, o, scaled(m.final, sc), move)
				end
			end
		end)
	elseif kind == "railBeam" then
		-- 진 벽력 섬뢰포: 주먹에 뇌전을 모았다가 앞으로 곧게 쏜다. 지나간 줄이 한동안 지지직 지진다
		Push:FireAllClients("skillfx", { kind = "railCharge", m = f.model, time = m.delay / sp, style = style })
		after(m.delay, function()
			local a = f.root.Position
			local dir = flat(Combat.look(f))
			local b = a + dir * m.length
			Push:FireAllClients("skillfx", { kind = "railFire", from = a, to = b, width = m.width, dur = m.linger / sp, style = style })
			for _, o in ipairs(hostilesOnSeg(f, a, b, m.width)) do
				strike(f, o, hit, move)
			end
			local ticks = math.floor(m.linger / m.every)
			for i = 1, ticks do
				after(i * m.every, function()
					for _, o in ipairs(hostilesOnSeg(f, a, b, m.width)) do
						o.stunUntil = math.max(o.stunUntil, os.clock() + 0.3)
						strike(f, o, scaled(m.tick, sc), move)
					end
				end)
			end
		end)
	elseif kind == "goldenBell" then
		-- 진 금강 금강종: 하늘에서 금빛 큰 종이 떨어져 나를 덮는다 (무적). 종이 세 번 울릴 때마다 둘레를 밀어낸다
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + m.dur / sp)
		Push:FireAllClients("skillfx", { kind = "bellDrop", m = f.model, dur = m.dur / sp, delay = m.delay / sp, rings = m.rings, every = m.every / sp, style = style })
		for i = 1, m.rings do
			after(m.delay + (i - 1) * m.every, function()
				local c = f.root.Position
				Push:FireAllClients("skillfx", { kind = "bellRing", at = c, radius = m.radius, i = i, last = i == m.rings, style = style })
				for _, o in ipairs(hostilesNear(f, c, m.radius)) do
					strike(f, o, i == m.rings and scaled(m.final, sc) or hit, move)
				end
			end)
		end
	elseif kind == "vajra" then
		-- 진 금강 항마저: 금강저를 던진다. 앞으로 날아갔다가 손으로 되돌아오며, 가는 길과 오는 길에 한 번씩 친다
		local from = f.root.Position
		local dir = look
		local tip = from + dir * m.dist
		Push:FireAllClients("skillfx", { kind = "vajraThrow", m = f.model, from = from, dir = dir, dist = m.dist, time = m.time / sp, delay = m.delay / sp, style = style })
		local outSeen, backSeen = {}, {}
		local steps = 10
		for i = 1, steps * 2 do
			after(m.delay + i * m.time / steps, function()
				local pos
				if i <= steps then
					pos = from + dir * (m.dist * i / steps)
				else
					pos = tip:Lerp(f.root.Position, (i - steps) / steps)
				end
				local seen = i <= steps and outSeen or backSeen
				for _, o in ipairs(hostilesNear(f, pos, m.radius)) do
					if not seen[o] then
						seen[o] = true
						strike(f, o, hit, move)
					end
				end
			end)
		end
	elseif kind == "shadowClones" then
		-- 진 무영 분영: 양옆에 그림자 분신 둘이 떨어져 나와, 저마다 가까운 적에게 세 번 덮쳐 찬다
		local c = f.root.Position
		local right = rightOf(look)
		local spots = { c + right * m.side - look * 2, c - right * m.side - look * 2 }
		Push:FireAllClients("skillfx", { kind = "cloneSpawn", m = f.model, spots = spots, dur = (m.delay + m.waves * m.every + 0.3) / sp, style = style })
		for s = 1, m.waves do
			after(m.delay + (s - 1) * m.every, function()
				for ci = 1, #spots do
					local at = spots[ci]
					local list = hostilesNear(f, at, m.range)
					table.sort(list, function(a, b)
						return (a.root.Position - at).Magnitude < (b.root.Position - at).Magnitude
					end)
					local tgt = list[1]
					local to = tgt and tgt.root.Position or (at + look * 8)
					Push:FireAllClients("skillfx", { kind = "cloneStrike", from = at, to = to, radius = m.radius, i = ci, last = s == m.waves, style = style })
					for _, o in ipairs(hostilesNear(f, to, m.radius)) do
						strike(f, o, hit, move)
					end
					spots[ci] = to
				end
			end)
		end
	elseif kind == "shadowStep" then
		-- 진 무영 그림자 밟기: 내 그림자만 앞으로 미끄러져 나가며 밟은 적의 그림자를 땅에 꿰맨다. 그림자 끝으로 몸이 옮겨 가 되돌아 걷어찬다
		local from = f.root.Position
		local dir = look
		local to = from + dir * m.dist
		Push:FireAllClients("skillfx", { kind = "shadowSlide", m = f.model, from = from, to = to, time = m.slide / sp, style = style })
		local pinned = {}
		local steps = 8
		for i = 1, steps do
			after(i * m.slide / steps, function()
				local a = from + dir * (m.dist * (i - 1) / steps)
				local b = from + dir * (m.dist * i / steps)
				for _, o in ipairs(hostilesOnSeg(f, a, b, m.width)) do
					if not pinned[o] then
						pinned[o] = true
						Combat.stun(o, m.pin / sp)
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.slide + 0.1, function()
			f.iframeUntil = math.max(f.iframeUntil, os.clock() + 0.5)
			moveTo(f, CFrame.lookAt(to + Vector3.new(0, 3, 0), to + Vector3.new(0, 3, 0) - dir))
			Push:FireAllClients("skillfx", { kind = "shadowKick", at = to, from = from, style = style })
			for o in pairs(pinned) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "waterOrbit" then
		-- 진 태허 회류환: 물방울 셋이 몸을 감아 돌며 닿는 적을 친다. 끝에 물결로 퍼진다
		Push:FireAllClients("skillfx", { kind = "orbitStart", m = f.model, n = m.n, radius = m.radius, dur = m.dur / sp, style = style })
		local lastHit = {}
		local ticks = math.floor(m.dur / m.every)
		for i = 1, ticks do
			after(i * m.every, function()
				local c = f.root.Position
				for _, o in ipairs(hostilesNear(f, c, m.radius + 3)) do
					if (lastHit[o] or 0) + m.gap / sp < os.clock() then
						lastHit[o] = os.clock()
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.dur, function()
			local c = f.root.Position
			Push:FireAllClients("skillfx", { kind = "orbitBurst", at = c, radius = m.radius + 4, style = style })
			for _, o in ipairs(hostilesNear(f, c, m.radius + 4)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "geysers" then
		-- 진 태허 간헐천: 가까운 적의 발밑마다 차례로 뜨거운 물기둥이 솟아 하늘로 쳐올린다
		local list = nearestList(f, m.range, m.n)
		for i = 1, m.n do
			after(m.delay + (i - 1) * m.every, function()
				local tgt = list[i]
				local at = (tgt and tgt.root.Parent) and tgt.root.Position or (f.root.Position + look * (5 + i * 5))
				Push:FireAllClients("skillfx", { kind = "hotGeyser", at = at, radius = m.radius, i = i, style = style })
				for _, o in ipairs(hostilesNear(f, at, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
	elseif kind == "fireWheel" then
		-- 진 열화 화륜: 불의 바퀴를 굴린다. 닿는 적을 치고, 지나간 길이 한동안 불탄다
		local from = f.root.Position + look * 2
		local dir = look
		Push:FireAllClients("skillfx", { kind = "wheelRoll", from = from, dir = dir, dist = m.dist, time = m.time / sp, burn = m.burn / sp, style = style })
		local done = {}
		local steps = 12
		for i = 1, steps do
			after(i * m.time / steps, function()
				local a = from + dir * (m.dist * (i - 1) / steps)
				local b = from + dir * (m.dist * i / steps)
				for _, o in ipairs(hostilesOnSeg(f, a, b, m.radius)) do
					if not done[o] then
						done[o] = true
						strike(f, o, hit, move)
					end
				end
			end)
		end
		local ticks = math.floor(m.burn / m.every)
		for i = 1, ticks do
			after(m.time + i * m.every, function()
				for _, o in ipairs(hostilesOnSeg(f, from, from + dir * m.dist, m.trail)) do
					strike(f, o, scaled(m.tick, sc), move)
				end
			end)
		end
	elseif kind == "flameRing" then
		-- 진 열화 폭염륜: 솟았다가 내려앉으며 둘레로 불의 고리가 퍼져 나간다 (고리가 지나가는 순간 맞는다)
		after(m.delay, function()
			local c = f.root.Position
			Push:FireAllClients("skillfx", { kind = "flameRing", at = c, radius = m.radius, time = m.expand / sp, style = style })
			local done = {}
			local steps = 8
			for i = 1, steps do
				after(i * m.expand / steps, function()
					for _, o in ipairs(hostilesNear(f, c, m.radius * i / steps)) do
						if not done[o] then
							done[o] = true
							strike(f, o, hit, move)
						end
					end
				end)
			end
		end)
	elseif kind == "volcano" then
		-- 진 열화 화산천붕 (오의): 앞의 땅이 부풀어 오르고, 적의 발밑마다 용암이 뿜어진 뒤, 한가운데 화산이 터져 불덩이가 쏟아진다
		local c = f.root.Position + look * m.dist
		local mainAt = m.delay + m.vents * m.every + m.mainDelay
		local total = mainAt + 0.3 + m.meteors * m.meteorEvery + 0.4
		Push:FireAllClients("skillfx", { kind = "volcanoRise", at = c, radius = m.radius, dur = total / sp, style = style })
		local list = nearestList(f, m.range, m.vents)
		for i = 1, m.vents do
			after(m.delay + (i - 1) * m.every, function()
				local tgt = list[(i - 1) % math.max(1, #list) + 1]
				local at = (tgt and tgt.root.Parent) and tgt.root.Position or (c + Vector3.new(math.random(-12, 12), 0, math.random(-12, 12)))
				Push:FireAllClients("skillfx", { kind = "vent", at = at, radius = m.ventRadius, style = style })
				for _, o in ipairs(hostilesNear(f, at, m.ventRadius)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after(mainAt, function()
			Push:FireAllClients("skillfx", { kind = "eruptMain", at = c, radius = m.mainRadius, style = style })
			for _, o in ipairs(hostilesNear(f, c, m.mainRadius)) do
				strike(f, o, scaled(m.main, sc), move)
			end
		end)
		for i = 1, m.meteors do
			after(mainAt + 0.3 + (i - 1) * m.meteorEvery, function()
				local enemies = hostilesNear(f, c, m.radius)
				local at
				if #enemies > 0 and math.random() < 0.6 then
					at = enemies[math.random(1, #enemies)].root.Position
				else
					local a = math.random() * math.pi * 2
					at = c + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(3, math.max(4, math.floor(m.radius)))
				end
				Push:FireAllClients("skillfx", { kind = "meteorDrop", at = at, radius = m.meteorRadius, fall = 0.35 / sp, style = style })
				after(0.35, function()
					for _, o in ipairs(hostilesNear(f, at, m.meteorRadius)) do
						strike(f, o, scaled(m.meteor, sc), move)
					end
				end)
			end)
		end
	elseif kind == "bubbles" then
		-- 진 창해 수포옥: 가까운 적 셋을 물방울 감옥에 가둬 띄운다. 갇힌 동안 지지고, 끝에 펑 터진다
		local list = nearestList(f, m.range, m.n)
		Push:FireAllClients("skillfx", { kind = "bubbleTrap", targets = modelsOf(list), dur = m.dur / sp, delay = m.delay / sp, style = style })
		after(m.delay, function()
			for _, o in ipairs(list) do
				Combat.stun(o, m.dur / sp)
				strike(f, o, hit, move)
			end
		end)
		local ticks = math.floor(m.dur / m.every)
		for i = 1, ticks - 1 do
			after(m.delay + i * m.every, function()
				for _, o in ipairs(list) do
					strike(f, o, scaled(m.tick, sc), move)
				end
			end)
		end
		after(m.delay + m.dur, function()
			local spots = {}
			for _, o in ipairs(list) do
				if o.root.Parent then
					table.insert(spots, o.root.Position)
					for _, v in ipairs(hostilesNear(f, o.root.Position, m.radius)) do
						strike(f, v, scaled(m.final, sc), move)
					end
				end
			end
			Push:FireAllClients("skillfx", { kind = "bubblePop", spots = spots, radius = m.radius, style = style })
		end)
	elseif kind == "waterSpears" then
		-- 진 창해 해룡창: 하늘에서 물의 창이 적들에게 차례로 내리꽂힌다 (적이 없으면 앞으로 한 줄)
		local c = f.root.Position
		local list = nearestList(f, m.range, m.count)
		for i = 1, m.count do
			after(m.delay + (i - 1) * m.every, function()
				local tgt = list[i]
				local at = (tgt and not tgt.dead and tgt.root.Parent) and tgt.root.Position or (c + look * (m.start + (i - 1) * m.spacing))
				Push:FireAllClients("skillfx", { kind = "waterSpear", at = at, radius = m.radius, fall = 0.18 / sp, i = i, style = style })
				after(0.18, function()
					for _, o in ipairs(hostilesNear(f, at, m.radius)) do
						strike(f, o, hit, move)
						if not o.dead then
							Combat.stun(o, 0.5)
						end
					end
				end)
			end)
		end
	elseif kind == "whaleBreach" then
		-- 진 창해 고래강림 (오의): 발밑에서 거대한 물의 고래가 솟구쳐 앞으로 크게 뛰어올랐다가 땅을 덮치며 떨어진다
		local from = f.root.Position + look * 3
		local to = f.root.Position + look * m.dist
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (m.delay + 0.3) / sp)
		Push:FireAllClients("skillfx", { kind = "whale", from = from, to = to, delay = m.delay / sp, flight = m.flight / sp, radius = m.radius, style = style })
		after(m.delay, function()
			for _, o in ipairs(hostilesNear(f, from, m.launchRadius)) do
				strike(f, o, scaled(m.launch, sc), move)
			end
		end)
		local steps = 5
		for i = 1, steps - 1 do
			after(m.delay + m.flight * i / steps, function()
				local at = from:Lerp(to, i / steps)
				for _, o in ipairs(hostilesNear(f, at, 7)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.delay + m.flight, function()
			for _, o in ipairs(hostilesNear(f, to, m.radius)) do
				strike(f, o, scaled(m.final, sc), move)
				if not o.dead then
					Combat.stun(o, 1.2)
				end
			end
		end)
	elseif kind == "wanderTornado" then
		-- 진 풍신 회풍: 작은 회오리가 3초 동안 가까운 적을 쫓아다니며 들어 올린다
		local id = math.random(1, 1000000000)
		local pos = f.root.Position + look * 6
		Push:FireAllClients("skillfx", { kind = "twisterStart", id = id, at = pos, radius = m.radius, dur = m.dur / sp, style = style })
		local lastHit = {}
		local ticks = math.floor(m.dur / m.every)
		for i = 1, ticks do
			after(i * m.every, function()
				local list = hostilesNear(f, pos, m.seek)
				local here = pos
				table.sort(list, function(a, b)
					return (a.root.Position - here).Magnitude < (b.root.Position - here).Magnitude
				end)
				local tgt = list[1]
				if tgt then
					local d = Vector3.new(tgt.root.Position.X - pos.X, 0, tgt.root.Position.Z - pos.Z)
					if d.Magnitude > 0.5 then
						pos += d.Unit * math.min(d.Magnitude, m.speed * m.every)
					end
				else
					pos += look * m.speed * m.every * 0.5
				end
				if i % 2 == 0 then
					Push:FireAllClients("skillfx", { kind = "twisterMove", id = id, at = pos, time = (m.every * 2) / sp })
				end
				for _, o in ipairs(hostilesNear(f, pos, m.radius)) do
					if (lastHit[o] or 0) + m.gap / sp < os.clock() then
						lastHit[o] = os.clock()
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.dur + 0.05, function()
			Push:FireAllClients("skillfx", { kind = "twisterEnd", id = id, at = pos, radius = m.radius + 3, style = style })
			for _, o in ipairs(hostilesNear(f, pos, m.radius + 3)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "downdraft" then
		-- 진 풍신 풍압: 솟구친 뒤 하늘의 바람을 끌어내려 둘레의 적을 땅에 짓누른다 (먼저 가운데로 빨아들인다)
		Push:FireAllClients("skillfx", { kind = "downdraftWarn", m = f.model, time = m.delay / sp, radius = m.radius, style = style })
		after(m.delay * 0.5, function()
			for _, o in ipairs(hostilesNear(f, f.root.Position, m.radius + 4)) do
				pullTo(o, f.root.Position, 40)
			end
		end)
		after(m.delay, function()
			local c = f.root.Position
			Push:FireAllClients("skillfx", { kind = "downdraft", at = c, radius = m.radius, style = style })
			for _, o in ipairs(hostilesNear(f, c, m.radius)) do
				strike(f, o, hit, move)
				if not o.dead then
					Combat.stun(o, m.stun)
				end
			end
		end)
	elseif kind == "thunderDive" then
		-- 초·벽력 뇌신낙: 하늘로 솟았다가 벼락이 되어 적에게 내리꽂힌다. 떨어진 자리에서 네 갈래로 땅이 갈라지며 번개가 달린다
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (m.delay + 0.25) / sp)
		local list = nearestList(f, m.range, 1)
		local first = list[1]
		local markAt = first and first.root.Position or (f.root.Position + look * 12)
		Push:FireAllClients("skillfx", { kind = "diveMark", at = markAt, radius = m.radius, time = m.delay / sp, style = style })
		after(m.delay, function()
			local at = (first and not first.dead and first.root.Parent) and first.root.Position or markAt
			local top = f.root.Position + Vector3.new(0, 10, 0)
			local dir = flat(at - f.root.Position)
			moveTo(f, CFrame.lookAt(at + Vector3.new(0, 3, 0) - dir * 2, at + Vector3.new(0, 3, 0) + dir))
			Push:FireAllClients("skillfx", { kind = "diveImpact", from = top, at = at, radius = m.radius, dir = dir, length = m.length, delay = m.crackDelay / sp, style = style })
			for _, o in ipairs(hostilesNear(f, at, m.radius)) do
				strike(f, o, hit, move)
			end
			after(m.crackDelay, function()
				local right = rightOf(dir)
				local done = {}
				for _, d in ipairs({ dir, -dir, right, -right }) do
					for _, o in ipairs(hostilesOnSeg(f, at, at + d * m.length, m.width)) do
						if not done[o] then
							done[o] = true
							strike(f, o, scaled(m.crack, sc), move)
						end
					end
				end
			end)
		end)
	elseif kind == "ballLightning" then
		-- 초·벽력 천뢰구 (오의): 커다란 구슬 번개를 앞으로 천천히 굴린다. 둘레의 적을 번개로 끌어당기며 지지다가 끝에 터진다
		local id = math.random(1, 1000000000)
		local from = f.root.Position + look * 4 + Vector3.new(0, 3, 0)
		local dir = look
		Push:FireAllClients("skillfx", { kind = "ballStart", id = id, from = from, dir = dir, speed = m.speed * sp, dur = m.dur / sp, delay = m.delay / sp, radius = m.radius, style = style })
		local ticks = math.floor(m.dur / m.every)
		for i = 1, ticks do
			after(m.delay + i * m.every, function()
				local pos = from + dir * (m.speed * i * m.every)
				local list = hostilesNear(f, pos, m.radius)
				Push:FireAllClients("skillfx", { kind = "ballArc", from = pos, targets = modelsOf(list), style = style })
				for _, o in ipairs(list) do
					pullTo(o, pos, m.pull)
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.delay + m.dur + 0.05, function()
			local pos = from + dir * (m.speed * m.dur)
			Push:FireAllClients("skillfx", { kind = "ballBurst", at = pos, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, pos, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "yinyangShot" then
		-- 2.6판 무극 음양탄 (E): 검은 구슬과 흰 구슬이 서로 감아 돌며 앞으로 날아간다. 지나는 길의 적을 치고,
		-- 끝에서 둘이 부딪쳐 그 자리로 적을 빨아들이며 터진다
		local from = f.root.Position + look * 2
		local to = from + look * m.length
		Push:FireAllClients("skillfx", { kind = "yyShot", from = from, dir = look, length = m.length, travel = m.travel / sp, delay = m.delay / sp, radius = m.radius, style = style })
		after(m.delay + m.travel * 0.5, function()
			for _, o in ipairs(hostilesOnSeg(f, from, to, m.width)) do
				strike(f, o, hit, move)
			end
		end)
		after(m.delay + m.travel, function()
			for _, o in ipairs(hostilesNear(f, to, m.radius)) do
				pullTo(o, to, m.pull)
				strike(f, o, scaled(m.burst, sc), move)
			end
		end)
	elseif kind == "taijiOrbit" then
		-- 2.6판 무극 태극선회 (R): 검은 구슬과 흰 구슬이 나를 축으로 소용돌이치며 멀리 퍼졌다가 되돌아온다.
		-- 구슬에 닿은 적을 치고 (한 번에 한 번), 돌아올 때 둘레의 적을 내 앞으로 끌어 모아 한 번 더 친다
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "yyOrbit", at = center, radius = m.radius, dur = m.dur / sp, delay = m.delay / sp, turns = m.turns, style = style })
		local ticks = math.floor(m.dur / m.every)
		for k = 1, ticks do
			after(m.delay + k * m.every, function()
				local u = k / ticks
				local r = m.radius * math.sin(u * math.pi)
				local a = u * m.turns * math.pi * 2
				local hitOnce = {}
				for side = 0, 1 do
					local aa = a + side * math.pi
					local op = center + Vector3.new(math.cos(aa) * r, 0, math.sin(aa) * r)
					for _, o in ipairs(hostilesNear(f, op, m.orbRadius)) do
						if not hitOnce[o] then
							hitOnce[o] = true
							strike(f, o, hit, move)
						end
					end
				end
			end)
		end
		after(m.delay + m.dur, function()
			local at = center + look * 3
			for _, o in ipairs(hostilesNear(f, center, m.radius)) do
				pullTo(o, at, m.pull)
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "taijiSeal" then
		-- 2.6판 무극 태극인 (오의): 세상의 빛깔이 빠지고 발밑에 거대한 태극이 그려진다. 그 위의 적은 모두 멈춘다.
		-- 태극이 돌며 땅에서 떠올라 하늘에서 뒤집힌 뒤, 도장처럼 내리찍는다. 이어 흑과 백의 물결이 한 번 더 지나간다
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "taijiSeal", at = center, radius = m.radius, delay = m.delay / sp, liftAt = m.liftAt / sp, hitAt = m.hitAt / sp, style = style })
		after(m.delay, function()
			local victims = hostilesNear(f, center, m.radius)
			for _, o in ipairs(victims) do
				Combat.stun(o, (m.hitAt - m.delay) / sp + 0.3)
				o.model:SetAttribute("Frozen", true)
			end
			after(m.hitAt - m.delay, function()
				for _, o in ipairs(victims) do
					if o.model.Parent then
						o.model:SetAttribute("Frozen", nil)
					end
				end
				for _, o in ipairs(hostilesNear(f, center, m.radius)) do
					strike(f, o, hit, move)
				end
				after(m.waveAt, function()
					for _, o in ipairs(hostilesNear(f, center, m.radius + 6)) do
						strike(f, o, scaled(m.wave, sc), move)
					end
				end)
			end)
			-- 혹시 중간에 끊겨도 멈춤은 풀린다
			task.delay((m.hitAt - m.delay) / sp + 0.6, function()
				for _, o in ipairs(victims) do
					if o.model.Parent then
						o.model:SetAttribute("Frozen", nil)
					end
				end
			end)
		end)
	elseif kind == "inkSlash" then
		-- 2.7판 진 무극 일획 (E): 허공에 먹으로 한 획을 긋는다. 지나간 적을 베고, 잠시 뒤 획이 금빛으로 타오르며 터진다
		local from = f.root.Position + look * 2
		local to = from + look * m.length
		local seed = math.random(1, 1000)
		Push:FireAllClients("skillfx", { kind = "inkSlash", from = from, to = to, delay = m.delay / sp, burstAt = m.burstAt / sp, width = m.width, seed = seed, style = style })
		local hitList = {}
		after(m.delay, function()
			for _, o in ipairs(hostilesOnSeg(f, from, to, m.width)) do
				table.insert(hitList, o)
				strike(f, o, hit, move)
			end
		end)
		after(m.delay + m.burstAt, function()
			for _, o in ipairs(hostilesOnSeg(f, from, to, m.width + 1)) do
				strike(f, o, scaled(m.burst, sc), move)
			end
		end)
	elseif kind == "enso" then
		-- 2.7판 진 무극 원상 (R): 발밑에 먹 원을 그린다. 원 안의 적은 먹에 붙잡히고, 다 그리면 먹 벽이 솟았다가 금빛으로 무너진다
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "enso", at = center, radius = m.radius, draw = m.draw / sp, burstAt = m.burstAt / sp, style = style })
		after(m.draw, function()
			for _, o in ipairs(hostilesNear(f, center, m.radius)) do
				Combat.stun(o, m.hold / sp)
				strike(f, o, hit, move)
			end
		end)
		after(m.draw + m.burstAt, function()
			for _, o in ipairs(hostilesNear(f, center, m.radius + 3)) do
				strike(f, o, scaled(m.burst, sc), move)
			end
		end)
	elseif kind == "plumBranch" then
		-- 2.9판 진 매화 설중매 (E): 땅을 따라 매화 가지가 뻗고, 마디마다 차례로 꽃이 피며 벤다. 잠시 뒤 가지의 꽃이 한꺼번에 터진다
		local from = f.root.Position
		local right = rightOf(look)
		local nodes = {}
		for i = 1, m.nodes do
			local u = i / m.nodes
			local sway = math.sin(i * 1.7) * 2.2 * (0.4 + u)
			table.insert(nodes, from + look * (m.length * u) + right * sway)
		end
		Push:FireAllClients("skillfx", { kind = "plumBranch", from = from, nodes = nodes, delay = m.delay / sp, step = m.step / sp, burstAt = m.burstAt / sp, radius = m.radius, style = style })
		local done = {}
		for i, pt in ipairs(nodes) do
			after(m.delay + (i - 1) * m.step, function()
				for _, o in ipairs(hostilesNear(f, pt, m.radius)) do
					if not done[o] then
						done[o] = true
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.delay + (#nodes - 1) * m.step + m.burstAt, function()
			local burst = scaled(m.burst, sc)
			local hitSet = {}
			for _, pt in ipairs(nodes) do
				for _, o in ipairs(hostilesNear(f, pt, m.radius)) do
					if not hitSet[o] then
						hitSet[o] = true
						strike(f, o, burst, move)
					end
				end
			end
		end)
	elseif kind == "plumRing" then
		-- 2.9판 진 매화 한매오판 (R): 둘레 다섯 곳에 큰 매화가 피어 둘레의 적을 꽃술로 끌어당긴 뒤 눈보라와 함께 터진다
		local center = f.root.Position
		local rot = math.random() * math.pi * 2
		local spots = {}
		for i = 1, m.flowers do
			local a = rot + (i - 1) / m.flowers * math.pi * 2
			table.insert(spots, center + Vector3.new(math.cos(a), 0, math.sin(a)) * m.radius)
		end
		Push:FireAllClients("skillfx", { kind = "plumRing", at = center, spots = spots, delay = m.delay / sp, hold = m.hold / sp, style = style })
		local n = math.floor(m.hold / m.every)
		for k = 0, n - 1 do
			after(m.delay + k * m.every, function()
				for _, pt in ipairs(spots) do
					for _, o in ipairs(hostilesNear(f, pt, 7)) do
						pullTo(o, pt, m.pull)
						if k == 0 then
							strike(f, o, hit, move)
						end
					end
				end
			end)
		end
		after(m.delay + m.hold, function()
			local burst = scaled(m.burst, sc)
			local hitSet = {}
			for _, pt in ipairs(spots) do
				for _, o in ipairs(hostilesNear(f, pt, 8)) do
					if not hitSet[o] then
						hitSet[o] = true
						o.slowUntil = os.clock() + m.slow
						o.slowMul = 0.5
						strike(f, o, burst, move)
					end
				end
			end
		end)
	elseif kind == "plumSnow" then
		-- 2.9판 진 매화 설중매화 (오의): 둘레에 함박눈과 붉은 꽃잎이 휘몰아쳐 계속 베고, 마지막에 하늘의 거대한 매화에서 꽃잎이 쏟아진다
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "plumSnow", m = f.model, at = center, radius = m.radius, delay = m.delay / sp, dur = m.dur / sp, style = style })
		local n = math.floor(m.dur / m.every)
		for i = 1, n do
			after(m.delay + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, center, m.radius)) do
					o.slowUntil = os.clock() + 0.5
					o.slowMul = 0.6
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.delay + m.dur, function()
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "drunkZig" then
		-- 2.9판 진 취팔선 취월삼보 (E): 좌우로 크게 휘청이며 세 번 뛰어든다 (무적). 내려설 때마다 둘레를 걷어찬다
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (m.hops * m.every + 0.2) / sp)
		local right = rightOf(look)
		local pos = f.root.Position
		local hops = {}
		for i = 1, m.hops do
			local side = (i % 2 == 1) and 1 or -1
			local d = (look * 0.8 + right * side * 0.6).Unit
			pos = pos + d * m.dist
			table.insert(hops, pos)
		end
		Push:FireAllClients("skillfx", { kind = "drunkZig", m = f.model, hops = hops, every = m.every / sp, style = style })
		for i, at in ipairs(hops) do
			after(i * m.every, function()
				local y = f.root.Position.Y
				local p = Vector3.new(at.X, y, at.Z)
				moveTo(f, CFrame.lookAt(p, p + look))
				for _, o in ipairs(hostilesNear(f, p, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
	elseif kind == "wineRiver" then
		-- 2.9판 진 취팔선 주천강 (R): 호리병의 술이 앞으로 강이 되어 흐른다. 강 위의 적은 굼뜨고, 마지막에 강에 불이 붙는다
		local from = f.root.Position + look * 2
		local to = from + look * m.length
		Push:FireAllClients("skillfx", { kind = "wineRiver", m = f.model, from = from, to = to, width = m.width, delay = m.delay / sp, dur = m.dur / sp, style = style })
		local n = math.floor(m.dur / m.every)
		for i = 0, n - 1 do
			after(m.delay + i * m.every, function()
				for _, o in ipairs(hostilesOnSeg(f, from, to, m.width / 2 + 1)) do
					o.slowUntil = os.clock() + 0.6
					o.slowMul = 0.45
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.delay + m.dur, function()
			for _, o in ipairs(hostilesOnSeg(f, from, to, m.width / 2 + 2)) do
				strike(f, o, scaled(m.burst, sc), move)
			end
		end)
	elseif kind == "eightImmortals" then
		-- 2.9판 진 취팔선 팔선강림 (오의): 여덟 신선의 그림자가 둘레에 나타나 차례로 가까운 적에게 덮쳐 들고, 하늘에서 거대한 호리병이 내리꽂힌다
		local center = f.root.Position
		local spots = {}
		for i = 1, m.n do
			local a = (i - 1) / m.n * math.pi * 2
			table.insert(spots, center + Vector3.new(math.cos(a), 0, math.sin(a)) * m.radius)
		end
		local list = nearestList(f, m.range, m.n)
		local targets = {}
		for i = 1, m.n do
			local t = #list > 0 and list[(i - 1) % #list + 1] or nil
			targets[i] = t and t.model or false
		end
		Push:FireAllClients("skillfx", { kind = "eightImmortals", m = f.model, at = center, spots = spots, targets = targets, delay = m.delay / sp, every = m.every / sp, finalAt = m.finalAt / sp, finalRadius = m.finalRadius, style = style })
		for i = 1, m.n do
			after(m.delay + (i - 1) * m.every + 0.15, function()
				local t = #list > 0 and list[(i - 1) % #list + 1] or nil
				if t and not t.dead and t.root.Parent then
					strike(f, t, hit, move)
				else
					for _, o in ipairs(hostilesNear(f, spots[i], 6)) do
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.delay + (m.n - 1) * m.every + m.finalAt, function()
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	-- 3.0판 환생 권법의 기술 ------------------------------------------------
	elseif kind == "wheelThrow" then
		-- 윤회권 윤회륜 (E): 등 뒤의 바퀴를 던진다. 세워진 채 구르며 앞으로 갔다가 내게로 되돌아온다
		-- 바퀴 자리 = 던진 자리에서 지금 내 자리로 옮겨 가는 점 + 앞으로 dist × sin(πu) (화면도 같은 식)
		local from = f.root.Position
		Push:FireAllClients("skillfx", { kind = "wheelThrow", m = f.model, from = from, dir = look, dist = m.dist, time = m.time / sp, style = style })
		local last: { [any]: number } = {}
		local n = math.floor(m.time / m.every)
		for i = 1, n do
			after(i * m.every, function()
				local u = i / n
				local pos = from:Lerp(f.root.Position, u) + look * (m.dist * math.sin(u * math.pi))
				local now = os.clock()
				for _, o in ipairs(hostilesNear(f, pos, m.radius)) do
					if not last[o] or now - last[o] > 0.25 then
						last[o] = now
						strike(f, o, hit, move)
					end
				end
			end)
		end
	elseif kind == "pastStep" then
		-- 윤회권 전생보 (R): 앞으로 미끄러지며 베고, 지난 삶의 그림자 둘이 같은 길을 다시 내달린다
		local a = f.root.Position
		local b = a + look * m.dist
		Push:FireAllClients("skillfx", { kind = "pastStep", m = f.model, from = a, to = b, echoes = m.echoes, delay = m.delay / sp, gap = m.gap / sp, style = style })
		after(0.15, function()
			for _, o in ipairs(hostilesOnSeg(f, a, b, m.width)) do
				strike(f, o, hit, move)
			end
		end)
		local echo = scaled(m.echo, sc)
		for k = 1, m.echoes do
			after(m.delay + (k - 1) * m.gap + 0.12, function()
				for _, o in ipairs(hostilesOnSeg(f, a, b, m.width)) do
					strike(f, o, echo, move)
				end
			end)
		end
	elseif kind == "sixRealms" then
		-- 윤회권 육도윤회 (오의): 하늘의 큰 바퀴에서 여섯 구슬이 떨어져 차례로 적에게 꽂히고, 바퀴가 땅에 누워 갈며 돈다
		local center = f.root.Position
		local list = nearestList(f, m.range, m.n)
		local spots = {}
		for i = 1, m.n do
			local t = list[i]
			if t then
				spots[i] = t.root.Position
			else
				local a = (i - 1) / m.n * math.pi * 2
				spots[i] = center + Vector3.new(math.cos(a), 0, math.sin(a)) * 12
			end
		end
		local T = m.rise + m.n * m.every + m.slamAt
		Push:FireAllClients("skillfx", { kind = "sixRealms", m = f.model, at = center, spots = spots, rise = m.rise / sp, every = m.every / sp, slam = T / sp, grind = m.grind / sp, radius = m.grindRadius, style = style })
		for i = 1, m.n do
			after(m.rise + (i - 1) * m.every + 0.12, function()
				for _, o in ipairs(hostilesNear(f, spots[i], m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
		local gh = scaled(m.grindHit, sc)
		local ticks = math.floor(m.grind / m.grindEvery)
		for k = 0, ticks - 1 do
			after(T + k * m.grindEvery, function()
				for _, o in ipairs(hostilesNear(f, center, m.grindRadius)) do
					pullTo(o, center, 10)
					strike(f, o, gh, move)
				end
			end)
		end
		after(T + m.grind, function()
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "karmaOrbs" then
		-- 업화권 업화탄 (E): 검은 불덩이 셋이 가까운 적 셋을 쫓아 날아가 터진다 (적이 없으면 앞으로)
		local list = nearestList(f, m.range, m.n)
		local points = {}
		for i = 1, m.n do
			local t = list[(i - 1) % math.max(1, #list) + 1]
			if t then
				points[i] = t.root.Position
			else
				points[i] = f.root.Position + (look + rightOf(look) * ((i - 2) * 0.35)).Unit * 18
			end
		end
		local targets = {}
		for i = 1, m.n do
			local t = list[(i - 1) % math.max(1, #list) + 1]
			targets[i] = t and t.model or false
		end
		Push:FireAllClients("skillfx", { kind = "karmaOrbs", m = f.model, targets = targets, points = points, delay = m.delay / sp, travel = m.travel / sp, radius = m.radius, style = style })
		for i = 1, m.n do
			after(m.delay + m.travel, function()
				local t = list[(i - 1) % math.max(1, #list) + 1]
				local at = (t and not t.dead and t.root.Parent) and t.root.Position or points[i]
				for _, o in ipairs(hostilesNear(f, at, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
	elseif kind == "hellTrail" then
		-- 업화권 겁화보 (R): 검은 불꽃이 되어 내달린 길이 갈라지며 타고, 마지막에 한꺼번에 치솟는다
		local a = f.root.Position
		local b = a + look * m.dist
		Push:FireAllClients("skillfx", { kind = "hellTrail", m = f.model, from = a, to = b, width = m.width, delay = m.delay / sp, dur = m.dur / sp, style = style })
		local n = math.floor(m.dur / m.every)
		for i = 0, n - 1 do
			after(m.delay + i * m.every, function()
				for _, o in ipairs(hostilesOnSeg(f, a, b, m.width)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.delay + m.dur, function()
			for _, o in ipairs(hostilesOnSeg(f, a, b, m.width + 1)) do
				strike(f, o, scaled(m.burst, sc), move)
			end
		end)
	elseif kind == "avici" then
		-- 업화권 무간지옥 (오의): 지옥불 기둥이 세 겹으로 퍼져 솟으며 적을 가운데로 끌고, 땅속의 불타는 손이 가운데를 움켜쥐어 터뜨린다
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "avici", m = f.model, at = center, radius = m.radius, waves = m.waves, delay = m.delay / sp, every = m.every / sp, handAt = m.handAt / sp, grab = m.grab / sp, style = style })
		local band = m.radius / m.waves
		for w = 1, m.waves do
			after(m.delay + (w - 1) * m.every, function()
				local r = band * w
				for _, o in ipairs(hostilesNear(f, center, r + 2)) do
					local d = Vector3.new(o.root.Position.X - center.X, 0, o.root.Position.Z - center.Z).Magnitude
					if d >= r - band - 1 then
						strike(f, o, hit, move)
					end
					pullTo(o, center, m.pull)
				end
			end)
		end
		local T = m.delay + m.waves * m.every + m.handAt
		for k = 0, 3 do
			after(T + k * m.grab / 4, function()
				for _, o in ipairs(hostilesNear(f, center, m.radius)) do
					pullTo(o, center, m.pull)
				end
			end)
		end
		after(T + m.grab, function()
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "phantomBlink" then
		-- 무상권 무상영 (E): 안개가 되어 가까운 적들의 등 뒤로 차례로 나타나며 친다 (그동안 무적)
		local list = nearestList(f, m.range, m.n)
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (m.delay + math.max(1, #list) * m.every + 0.3) / sp)
		Push:FireAllClients("skillfx", { kind = "phantomBlink", m = f.model, from = f.root.Position, targets = modelsOf(list), delay = m.delay / sp, every = m.every / sp, style = style })
		if #list == 0 then
			after(m.delay, function()
				local p = f.root.Position + look * 12
				moveTo(f, CFrame.lookAt(p, p + look))
				for _, o in ipairs(hostilesNear(f, p, 6)) do
					strike(f, o, hit, move)
				end
			end)
		end
		for i, t in ipairs(list) do
			after(m.delay + (i - 1) * m.every, function()
				if t.dead or not t.root.Parent then
					return
				end
				local tp = t.root.Position
				local d = flat(tp - f.root.Position)
				local p = Vector3.new(tp.X, f.root.Position.Y, tp.Z) + d * 3.2
				moveTo(f, CFrame.lookAt(p, Vector3.new(tp.X, p.Y, tp.Z)))
				strike(f, t, hit, move)
				for _, o in ipairs(hostilesNear(f, tp, 5)) do
					if o ~= t then
						strike(f, o, hit, move)
					end
				end
			end)
		end
	elseif kind == "illusions" then
		-- 무상권 허상 (R): 몸이 흩어지며 둘레에 허상 셋. 허상이 적을 끌어모았다가 안개로 터진다 (나는 잠시 보이지 않는다)
		local center = f.root.Position
		local rot = math.atan2(look.Z, look.X)
		local spots = {}
		for i = 1, m.n do
			local a = rot + (i - 1) / m.n * math.pi * 2
			table.insert(spots, center + Vector3.new(math.cos(a), 0, math.sin(a)) * m.radius)
		end
		f.model:SetAttribute("Vanish", true)
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + m.vanish / sp)
		Push:FireAllClients("skillfx", { kind = "illusions", m = f.model, at = center, spots = spots, hold = m.hold / sp, style = style })
		local ticks = math.floor(m.hold / m.every)
		for k = 0, ticks - 1 do
			after(k * m.every, function()
				for _, pt in ipairs(spots) do
					for _, o in ipairs(hostilesNear(f, pt, m.burstRadius + 5)) do
						pullTo(o, pt, m.pull)
					end
				end
			end)
		end
		after(m.hold, function()
			local done = {}
			local burst = scaled(m.burst, sc)
			for _, pt in ipairs(spots) do
				for _, o in ipairs(hostilesNear(f, pt, m.burstRadius)) do
					if not done[o] then
						done[o] = true
						strike(f, o, burst, move)
					end
				end
			end
		end)
		task.delay(m.vanish / sp, function()
			if f.model.Parent then
				f.model:SetAttribute("Vanish", nil)
			end
		end)
	elseif kind == "allPasses" then
		-- 무상권 제행무상 (오의): 세상이 잿빛으로 멈춘다. 몸이 일곱으로 갈라져 일곱 적을 한꺼번에 치고, 다시 하나로 모이며 터진다
		local center = f.root.Position
		local list = nearestList(f, m.range, m.n)
		local total = m.delay + m.strikes * m.every + m.converge
		f.model:SetAttribute("Vanish", true)
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + total / sp + 0.2)
		local spots = {}
		for i = 1, m.n do
			local t = list[i]
			if t then
				spots[i] = t.root.Position
			else
				local a = (i - 1) / m.n * math.pi * 2
				spots[i] = center + Vector3.new(math.cos(a), 0, math.sin(a)) * 14
			end
		end
		Push:FireAllClients("skillfx", { kind = "allPasses", m = f.model, at = center, spots = spots, delay = m.delay / sp, strikes = m.strikes, every = m.every / sp, converge = m.converge / sp, radius = m.finalRadius, style = style })
		for k = 1, m.strikes do
			after(m.delay + (k - 1) * m.every, function()
				for i = 1, m.n do
					local t = list[i]
					if t and not t.dead and t.root.Parent then
						strike(f, t, hit, move)
					else
						for _, o in ipairs(hostilesNear(f, spots[i], 5)) do
							strike(f, o, hit, move)
						end
					end
				end
			end)
		end
		after(total, function()
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
		task.delay(total / sp + 0.05, function()
			if f.model.Parent then
				f.model:SetAttribute("Vanish", nil)
			end
		end)
	elseif kind == "kingFist" then
		-- 권왕신권 왕권 (E): 등 뒤의 거대한 금빛 주먹이 앞으로 곧게 내지르고, 반 박자 뒤 반대쪽 주먹이 한 번 더
		local a = f.root.Position
		local b = a + look * m.length
		Push:FireAllClients("skillfx", { kind = "kingFist", m = f.model, from = a, dir = look, length = m.length, width = m.width, delay = m.delay / sp, second = m.second / sp, style = style })
		for k = 0, 1 do
			after(m.delay + k * m.second + 0.08, function()
				for _, o in ipairs(hostilesOnSeg(f, a, b, m.width)) do
					strike(f, o, hit, move)
				end
			end)
		end
	elseif kind == "royalRoad" then
		-- 권왕신권 왕도 (R): 금빛 길을 내달리고 (무적), 길 위로 금빛 기둥이 차례로 솟는다
		local a = f.root.Position
		local b = a + look * m.length
		Push:FireAllClients("skillfx", { kind = "royalRoad", m = f.model, from = a, to = b, width = m.width, run = m.run / sp, pillars = m.pillars, step = m.step / sp, style = style })
		after(m.run * 0.5, function()
			for _, o in ipairs(hostilesOnSeg(f, a, b, m.width)) do
				strike(f, o, hit, move)
			end
		end)
		local done = {}
		local ph = scaled(m.pillar, sc)
		for i = 1, m.pillars do
			after(m.run + i * m.step, function()
				local pt = a:Lerp(b, i / m.pillars)
				for _, o in ipairs(hostilesNear(f, pt, m.width)) do
					if not done[o] then
						done[o] = true
						strike(f, o, ph, move)
					end
				end
			end)
		end
	elseif kind == "kingDescend" then
		-- 권왕신권 권왕강림 (오의): 등 뒤에서 거대한 금빛 왕이 일어나 적을 골라 세 번 내리찍고, 두 주먹으로 마지막 충격파
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "kingDescend", m = f.model, at = center, dir = look, rise = m.rise / sp, punches = m.punches, every = m.every / sp, finalAt = m.finalAt / sp, radius = m.finalRadius, style = style })
		local right = rightOf(look)
		for i = 1, m.punches do
			after(m.rise + (i - 1) * m.every, function()
				local list = nearestList(f, m.range, m.punches)
				local t = list[(i - 1) % math.max(1, #list) + 1]
				local side = (i % 2 == 1) and 1 or -1
				local spot = t and t.root.Position or (center + look * 12 + right * side * 6)
				Push:FireAllClients("skillfx", { kind = "kingPunch", m = f.model, at = spot, origin = center, dir = look, side = side, style = style })
				task.delay(0.16 / sp, function()
					if alive() then
						for _, o in ipairs(hostilesNear(f, spot, m.radius)) do
							strike(f, o, hit, move)
						end
					end
				end)
			end)
		end
		after(m.rise + m.punches * m.every + m.finalAt, function()
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	-- 3.1판 극 일월신권 ------------------------------------------------
	elseif kind == "twinDiscs" then
		-- 일월쌍륜 (E): 해와 달의 원반이 엇갈리는 활을 그리며 날아가 앞에서 만나 터진다
		-- 원반 자리 = 시작점 + 앞으로 dist·u + 옆으로 (해 +1, 달 -1) swing·sin(πu) (화면도 같은 식)
		local from = f.root.Position
		local right = rightOf(look)
		Push:FireAllClients("skillfx", { kind = "twinDiscs", m = f.model, from = from, dir = look, dist = m.dist, swing = m.swing, time = m.time / sp, style = style })
		local hitBy: { [string]: { [any]: boolean } } = { sun = {}, moon = {} }
		local n = math.floor(m.time / m.every)
		for i = 1, n do
			after(i * m.every, function()
				local u = i / n
				for _, side in ipairs({ 1, -1 }) do
					local key = side == 1 and "sun" or "moon"
					local pos = from + look * (m.dist * u) + right * (side * m.swing * math.sin(u * math.pi))
					for _, o in ipairs(hostilesNear(f, pos, m.radius)) do
						if not hitBy[key][o] then
							hitBy[key][o] = true
							strike(f, o, hit, move)
						end
					end
				end
			end)
		end
		after(m.time, function()
			for _, o in ipairs(hostilesNear(f, from + look * m.dist, m.burstRadius)) do
				strike(f, o, scaled(m.burst, sc), move)
			end
		end)
	elseif kind == "solarLunarStep" then
		-- 일월환보 (R): 제자리에 해가 터지고, 지나간 길을 달빛이 베고, 내려선 자리에서 초승달이 터진다
		local a = f.root.Position
		local b = a + look * m.dist
		Push:FireAllClients("skillfx", { kind = "solarLunarStep", m = f.model, from = a, to = b, style = style })
		after(0.05, function()
			for _, o in ipairs(hostilesNear(f, a, m.sunRadius)) do
				strike(f, o, scaled(m.sun, sc), move)
			end
		end)
		after(0.3, function()
			for _, o in ipairs(hostilesOnSeg(f, a, b, m.width)) do
				strike(f, o, scaled(m.moon, sc), move)
			end
		end)
		after(0.45, function()
			for _, o in ipairs(hostilesNear(f, b, m.landRadius)) do
				strike(f, o, scaled(m.land, sc), move)
			end
		end)
	elseif kind == "sunMoonFall" then
		-- 대일월천 (오의, 3.1.1판): 등 뒤에 해와 달이 떠오르고, 해의 빛줄기가 앞의 땅을 앞뒤로 쓸고, 달의 초승달 셋이 내리꽂히고,
		-- 둘이 적 위에서 부딪쳐 일식이 되어 땅에 박히며 터진다
		local from = f.root.Position
		local c = from + look * m.dist
		local slamAt = m.summon + 0.15
		Push:FireAllClients("skillfx", { kind = "sunMoonFall", m = f.model, at = c, from = from, dir = look, summon = m.summon / sp, beam = m.beam / sp, sweep = m.sweep,
			slams = m.slams, slamAt = slamAt / sp, slamEvery = m.slamEvery / sp, travel = m.travel / sp, merge = m.merge / sp, radius = m.finalRadius, style = style })
		local n = math.floor(m.beam / m.every)
		for i = 0, n - 1 do
			after(m.summon + i * m.every, function()
				for _, o in ipairs(hostilesOnSeg(f, c - look * (m.sweep + 2), c + look * (m.sweep + 2), m.width)) do
					strike(f, o, hit, move)
				end
			end)
		end
		local sh = scaled(m.slam, sc)
		for i = 1, m.slams do
			after(slamAt + (i - 1) * m.slamEvery + m.travel, function()
				for _, o in ipairs(hostilesNear(f, c, m.slamRadius)) do
					strike(f, o, sh, move)
				end
			end)
		end
		after(m.summon + m.beam + m.merge, function()
			for _, o in ipairs(hostilesNear(f, c, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "eclipseGenesis" then
		-- 일월개벽 (초 오의, 3.1.1판): 컷씬 동안 등 뒤 지평선에서 해와 달이 솟고 (그동안 무적),
		-- 둘이 나를 두고 점점 빨리 돌며 번갈아 적을 친다 → 머리 위에서 부딪쳐 일식 → 일식의 빛살 → 일식이 깨지며 새벽빛으로 터진다
		local center = f.root.Position
		local T1 = m.cut
		local T2 = T1 + m.orbit
		local T3 = T2 + m.collide
		local T4 = T3 + m.rays
		local T5 = T4 + m.finalAt
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + T5 / sp + 0.2)
		Push:FireAllClients("skillfx", { kind = "eclipseGenesis", m = f.model, at = center, dir = look, cut = T1 / sp, orbit = m.orbit / sp, collide = m.collide / sp, rays = m.rays / sp,
			finalAt = m.finalAt / sp, orbitR = m.orbitR, range = m.range, radius = m.finalRadius, style = style })
		local oh = scaled(m.orbitHit, sc)
		local no = math.floor(m.orbit / m.orbitEvery)
		for i = 1, no do
			after(T1 + i * m.orbitEvery, function()
				local list = hostilesNear(f, center, m.range)
				local ats = {}
				for _ = 1, math.min(m.orbitN, #list) do
					local o = list[math.random(1, #list)]
					table.insert(ats, o.root.Position)
					strike(f, o, oh, move)
				end
				if #ats > 0 then
					Push:FireAllClients("skillfx", { kind = "eclipseStrike", m = f.model, ats = ats, who = (i % 2 == 0) and "moon" or "sun", style = style })
				end
			end)
		end
		local n = math.floor(m.rays / m.every)
		for i = 0, n - 1 do
			after(T3 + i * m.every, function()
				local list = hostilesNear(f, center, m.range)
				local ats = {}
				for _ = 1, math.min(m.n, #list) do
					local o = list[math.random(1, #list)]
					table.insert(ats, o.root.Position)
					for _, q in ipairs(hostilesNear(f, o.root.Position, m.radius)) do
						strike(f, q, hit, move)
					end
				end
				if #ats > 0 then
					Push:FireAllClients("skillfx", { kind = "eclipseRay", ats = ats, from = center + Vector3.new(0, 40, 0), style = style })
				end
			end)
		end
		after(T5, function()
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "duskFan" then
		-- 황혼참 (황혼 E): 노을빛 초승달 다섯이 부채꼴로 날아갔다가 되돌아온다. 오갈 때 한 번씩 벤다
		local from = f.root.Position
		local dirs = {}
		for i = 1, m.n do
			local ang = math.rad(-m.spread / 2 + (i - 1) * m.spread / math.max(1, m.n - 1))
			local d = (CFrame.fromAxisAngle(Vector3.new(0, 1, 0), ang) * look)
			table.insert(dirs, Vector3.new(d.X, 0, d.Z).Unit)
		end
		Push:FireAllClients("skillfx", { kind = "duskFan", m = f.model, from = from, dirs = dirs, dist = m.dist, time = m.time / sp, style = style })
		local out: { [any]: boolean } = {}
		local back: { [any]: boolean } = {}
		local n = math.floor(m.time / m.every)
		for i = 1, n do
			after(i * m.every, function()
				local u = i / n
				local reach = m.dist * math.sin(u * math.pi)
				local set = u < 0.5 and out or back
				for _, d in ipairs(dirs) do
					local pos = from:Lerp(f.root.Position, u) + d * reach
					for _, o in ipairs(hostilesNear(f, pos, m.radius)) do
						if not set[o] then
							set[o] = true
							strike(f, o, hit, move)
						end
					end
				end
			end)
		end
	elseif kind == "duskChain" then
		-- 석양보 (황혼 R): 노을이 되어 적들의 등 뒤로 차례로 나타나며 베고, 지나간 노을빛 줄이 한꺼번에 터진다
		local list = nearestList(f, m.range, m.n)
		local start = f.root.Position
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + (m.delay + math.max(1, #list) * m.every + m.burstAt + 0.2) / sp)
		Push:FireAllClients("skillfx", { kind = "duskChain", m = f.model, from = start, targets = modelsOf(list), delay = m.delay / sp, every = m.every / sp, burstAt = m.burstAt / sp, style = style })
		local path = { start }
		for i, t in ipairs(list) do
			after(m.delay + (i - 1) * m.every, function()
				if t.dead or not t.root.Parent then
					return
				end
				local tp = t.root.Position
				local d = flat(tp - f.root.Position)
				local p = Vector3.new(tp.X, f.root.Position.Y, tp.Z) + d * 3.2
				table.insert(path, p)
				moveTo(f, CFrame.lookAt(p, Vector3.new(tp.X, p.Y, tp.Z)))
				strike(f, t, hit, move)
			end)
		end
		after(m.delay + math.max(1, #list) * m.every + m.burstAt, function()
			local done = {}
			local burst = scaled(m.burst, sc)
			for i = 1, #path - 1 do
				for _, o in ipairs(hostilesOnSeg(f, path[i], path[i + 1], m.width)) do
					if not done[o] then
						done[o] = true
						strike(f, o, burst, move)
					end
				end
			end
		end)
	elseif kind == "sunsetSea" then
		-- 황혼낙일 (황혼 G, 3.1.1판): 거대한 석양이 내려와 앞의 땅으로 가라앉는다. 바다 위의 적은 타며 굼뜨고, 노을 물결 넷이 퍼지고,
		-- 달빛 기둥이 솟는다. 다 잠기면 잠깐 고요하다가 바다가 노을 불꽃의 왕관으로 솟구친다
		local c = f.root.Position + look * m.dist
		local beams = {}
		for _ = 1, m.beams do
			local a = math.random() * math.pi * 2
			local r = math.random() * m.radius * 0.85
			table.insert(beams, c + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
		end
		Push:FireAllClients("skillfx", { kind = "sunsetSea", m = f.model, at = c, dir = look, descend = m.descend / sp, sink = m.sink / sp, dark = m.dark / sp, waves = m.waves, radius = m.radius, beams = beams, style = style })
		local n = math.floor(m.sink / m.every)
		for i = 0, n - 1 do
			after(m.descend + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, c, m.radius)) do
					o.slowUntil = os.clock() + 0.4
					o.slowMul = 0.55
					strike(f, o, hit, move)
				end
			end)
		end
		local wh = scaled(m.wave, sc)
		for i = 1, m.waves do
			after(m.descend + (i - 0.5) * m.sink / m.waves, function()
				for _, o in ipairs(hostilesNear(f, c, m.radius * 1.2)) do
					strike(f, o, wh, move)
				end
			end)
		end
		local bh = scaled(m.beam, sc)
		for i, pt in ipairs(beams) do
			after(m.descend + (i - 0.5) * m.sink / m.beams, function()
				for _, o in ipairs(hostilesNear(f, pt, m.beamRadius)) do
					strike(f, o, bh, move)
				end
			end)
		end
		after(m.descend + m.sink + m.dark, function()
			for _, o in ipairs(hostilesNear(f, c, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "twilightCollapse" then
		-- 일월동귀 (황혼 X, 3.1.1판): 컷씬 동안 석양과 달이 내려와 (그동안 무적) 내 두 손에 맺히고, 발밑 진의 테두리를 서로 반대로 내달려
		-- 불의 원을 그린다. 앞에서 만나 황혼의 구슬이 되어 둘레를 빨아들이다가 한 점으로 줄어들고, 노을빛으로 하얗게 터진다
		local center = f.root.Position
		local T1 = m.cut
		local T2 = T1 + m.gather
		local T3 = T2 + m.circle
		local T4 = T3 + m.fuse
		local T5 = T4 + m.collapse
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + T5 / sp + 0.2)
		Push:FireAllClients("skillfx", { kind = "twilightCollapse", m = f.model, at = center, dir = look, cut = T1 / sp, gather = m.gather / sp, circle = m.circle / sp, fuse = m.fuse / sp,
			collapse = m.collapse / sp, rim = m.rim, radius = m.finalRadius, style = style })
		local rh = scaled(m.rimHit, sc)
		local n = math.floor(m.circle / m.every)
		for i = 1, n do
			after(T2 + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, center, m.rim + 6)) do
					strike(f, o, rh, move)
				end
			end)
		end
		local np = math.floor(m.fuse / 0.15)
		for i = 0, np do
			after(T3 + i * 0.15, function()
				for _, o in ipairs(hostilesNear(f, center, m.rim * 1.6)) do
					pullTo(o, center, m.pull)
				end
			end)
		end
		after(T5, function()
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "inkFlower" then
		-- 2.7판 진 무극 무극필 (오의): 하늘의 붓이 땅에 소용돌이치는 먹 획 여덟을 차례로 긋고, 둘레에 원을 둘러 금빛으로 터뜨린다.
		-- 획의 모양은 화면과 같은 식으로 (가운데에서 바깥으로 휘어 나가는 나선)
		local center = f.root.Position + look * 2
		local rot = math.random() * math.pi * 2
		Push:FireAllClients("skillfx", { kind = "inkFlower", at = center, radius = m.radius, strokes = m.strokes, delay = m.delay / sp, every = m.every / sp, ringAt = m.ringAt / sp, finalAt = m.finalAt / sp, rot = rot, style = style })
		local order = { 1, 5, 3, 7, 2, 6, 4, 8 }
		for i = 1, m.strokes do
			after(m.delay + (i - 1) * m.every, function()
				local a0 = rot + ((order[i] or i) - 1) / m.strokes * math.pi * 2
				local hitSet = {}
				local prev = center
				for k = 1, 5 do
					local r = 3 + (m.radius - 3) * k / 5
					local a = a0 + 0.75 * k / 5
					local pt = center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
					for _, o in ipairs(hostilesOnSeg(f, prev, pt, m.width)) do
						if not hitSet[o] then
							hitSet[o] = true
							strike(f, o, hit, move)
						end
					end
					prev = pt
				end
			end)
		end
		local tEnd = m.delay + (m.strokes - 1) * m.every + m.ringAt + m.finalAt
		after(tEnd, function()
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "fanBoomerang" then
		-- 2.7판 초·매화 선풍낙화 (E): 두 부채가 양옆으로 둥글게 날아갔다 되돌아온다. 가는 길과 오는 길에 한 번씩 벤다
		local from = f.root.Position
		local right = Vector3.new(-look.Z, 0, look.X)
		Push:FireAllClients("skillfx", { kind = "fanBoomerang", m = f.model, from = from, dir = look, dist = m.dist, width = m.width, time = m.time / sp, style = style })
		local ticks = math.floor(m.time / m.every)
		local hits: { [any]: number } = {}
		for k = 1, ticks do
			after(k * m.every, function()
				local u = k * m.every / m.time
				local half = u < 0.5 and 1 or 2
				for _, side in ipairs({ -1, 1 }) do
					local pos = from + look * (m.dist * (1 - math.cos(2 * math.pi * u)) / 2) + right * side * (m.width * math.sin(2 * math.pi * u))
					for _, o in ipairs(hostilesNear(f, pos, m.radius)) do
						local key = (hits[o] or 0)
						-- 가는 길에 한 번, 오는 길에 한 번
						if key < half then
							hits[o] = half
							strike(f, o, hit, move)
						end
					end
				end
			end)
		end
	elseif kind == "petalShadow" then
		-- 2.7판 초·매화 화영보 (R): 앞으로 미끄러지며 지나간 길에 꽃 그림자 셋을 남긴다. 그림자가 차례로 베고, 마지막에 모두 꽃잎으로 터진다
		local from = f.root.Position
		local spots = {}
		for i = 1, m.n do
			spots[i] = from + look * (m.gap * i - 2)
		end
		Push:FireAllClients("skillfx", { kind = "petalShadow", m = f.model, spots = spots, dir = look, delay = m.delay / sp, every = m.every / sp, burstAt = m.burstAt / sp, radius = m.radius, style = style })
		for i, at in ipairs(spots) do
			after(m.delay + (i - 1) * m.every, function()
				for _, o in ipairs(hostilesNear(f, at, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.delay + (m.n - 1) * m.every + m.burstAt, function()
			local done = {}
			for _, at in ipairs(spots) do
				for _, o in ipairs(hostilesNear(f, at, m.radius)) do
					if not done[o] then
						done[o] = true
						strike(f, o, scaled(m.burst, sc), move)
					end
				end
			end
		end)
	elseif kind == "skyFan" then
		-- 2.7판 초·매화 만화천선 (오의): 하늘에 큰 부채가 펼쳐져 앞의 땅을 두 번 쓸고, 접히며 꽃잎 폭풍을 일으킨다
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "skyFan", m = f.model, at = center, dir = look, open = m.open / sp, sweeps = m.sweeps, sweepTime = m.sweepTime / sp, range = m.range, angle = m.angle, closeAt = m.closeAt / sp, closeRadius = m.closeRadius, style = style })
		local half = math.cos(math.rad(m.angle / 2))
		for k = 1, m.sweeps do
			after(m.open + (k - 1) * (m.sweepTime + 0.05) + m.sweepTime * 0.5, function()
				for _, o in ipairs(hostilesNear(f, center, m.range)) do
					local d = Vector3.new(o.root.Position.X - center.X, 0, o.root.Position.Z - center.Z)
					if d.Magnitude < 3 or d.Unit:Dot(look) >= half then
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.open + m.sweeps * (m.sweepTime + 0.05) + m.closeAt, function()
			for _, o in ipairs(hostilesNear(f, center, m.closeRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "tideSpear" then
		-- 2.7판 초·창해 조류창 (E): 소용돌이치는 물의 창이 앞을 꿰뚫고, 끝에서 소용돌이가 되어 끌어당기다 터진다
		local from = f.root.Position + look * 2
		local to = from + look * m.length
		Push:FireAllClients("skillfx", { kind = "tideSpear", from = from, to = to, delay = m.delay / sp, travel = m.travel / sp, vortex = m.vortexDur / sp, radius = m.radius, style = style })
		after(m.delay + m.travel * 0.6, function()
			for _, o in ipairs(hostilesOnSeg(f, from, to, m.width)) do
				strike(f, o, hit, move)
			end
		end)
		local ticks = math.floor(m.vortexDur / m.every)
		for i = 1, ticks do
			after(m.delay + m.travel + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, to, m.radius)) do
					pullTo(o, to, m.pull)
					strike(f, o, scaled(m.tick, sc), move)
				end
			end)
		end
		after(m.delay + m.travel + m.vortexDur, function()
			for _, o in ipairs(hostilesNear(f, to, m.radius + 1)) do
				strike(f, o, scaled(m.burst, sc), move)
			end
		end)
	elseif kind == "whaleSong" then
		-- 2.7판 초·창해 경음 (R): 고래의 울음이 물의 고리 셋이 되어 퍼진다. 고리마다 그 너비 안의 적을 한 번씩, 맞으면 굼뜨다
		local center = f.root.Position
		Push:FireAllClients("skillfx", { kind = "whaleSong", at = center, rings = m.rings, gap = m.gap / sp, delay = m.delay / sp, radius = m.radius, style = style })
		for r = 1, m.rings do
			after(m.delay + (r - 1) * m.gap, function()
				local outer = m.radius * r / m.rings
				local inner = r == 1 and 0 or m.radius * (r - 1) / m.rings - 2
				for _, o in ipairs(hostilesNear(f, center, outer)) do
					local d = Vector3.new(o.root.Position.X - center.X, 0, o.root.Position.Z - center.Z).Magnitude
					if d >= inner then
						o.slowUntil = os.clock() + m.slow / sp
						o.slowMul = 0.5
						strike(f, o, hit, move)
					end
				end
			end)
		end
	elseif kind == "fourWaves" then
		-- 2.7판 초·창해 만경창파 (오의): 둘레가 바다가 되고 사방의 파도 넷이 가운데로 밀려와 쓸어 모은다. 마지막에 소용돌이
		local center = f.root.Position
		local right = Vector3.new(-look.Z, 0, look.X)
		local dirs = { look, right, -look, -right }
		Push:FireAllClients("skillfx", { kind = "fourWaves", at = center, dir = look, radius = m.radius, waves = m.waves, travel = m.travel / sp, gap = m.gap / sp, delay = m.delay / sp, style = style })
		for w = 1, m.waves do
			local from = dirs[(w - 1) % 4 + 1]
			after(m.delay + (w - 1) * m.gap + m.travel * 0.5, function()
				-- 그 파도가 지나가는 반쪽 (그 방향의 적)을 가운데로 쓸어 온다
				for _, o in ipairs(hostilesNear(f, center, m.radius)) do
					local d = Vector3.new(o.root.Position.X - center.X, 0, o.root.Position.Z - center.Z)
					if d.Magnitude < 3 or d.Unit:Dot(from) > -0.2 then
						pullTo(o, center, m.pull)
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.delay + (m.waves - 1) * m.gap + m.travel + 0.15, function()
			Push:FireAllClients("skillfx", { kind = "maelstrom", at = center, radius = m.radius * 0.6, style = style })
			for _, o in ipairs(hostilesNear(f, center, m.radius * 0.7)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "ancientWhale" then
		-- 2.7판 초·창해 고경승천 (초 오의): 땅이 바다가 되고 (컷씬, 무적) 고대의 고래가 뒤에서 솟구쳐 머리 위를 지나 앞으로 뛰어든다.
		-- 고래 그림자 아래의 적은 떠오르고, 앞의 바다에 떨어질 때 해일이 둘레를 덮친다
		local center = f.root.Position
		-- 2.7.7판: 자동 타깃. 쓰는 순간 둘레에서 가장 가까운 적 (보스가 있으면 보스)을 골라 그쪽으로 뛰어든다 (뒤쫓지는 않는다)
		local ahead = m.ahead
		local pick, pickD = nil, math.huge
		for _, o in ipairs(hostilesNear(f, center, m.targetRange or 110)) do
			local d = Vector3.new(o.root.Position.X - center.X, 0, o.root.Position.Z - center.Z).Magnitude
			if o.model:GetAttribute("Boss") == true then
				d -= 1000
			end
			if d < pickD then
				pick, pickD = o, d
			end
		end
		if pick then
			local d = Vector3.new(pick.root.Position.X - center.X, 0, pick.root.Position.Z - center.Z)
			if d.Magnitude > 1 then
				look = d.Unit
				ahead = math.clamp(d.Magnitude, 24, m.ahead + 30)
				-- 나도 그쪽을 본다
				pcall(function()
					f.model:PivotTo(CFrame.lookAt(center, center + look))
				end)
			end
		end
		local from = center - look * m.behind
		local to = center + look * ahead
		local total = m.cut + m.flight + m.waveAt + 0.3
		f.iframeUntil = math.max(f.iframeUntil, os.clock() + total / sp)
		local wid = math.random(1, 1000000000)
		Push:FireAllClients("skillfx", { kind = "ancientSea", id = wid, m = f.model, at = center, dir = look, from = from, to = to, cut = m.cut / sp, dur = total / sp, style = style })
		after(m.cut, function()
			Push:FireAllClients("skillfx", { kind = "ancientLeap", id = wid, from = from, to = to, flight = m.flight / sp, height = m.height, scale = m.scale, style = style })
		end)
		local done = {}
		local ticks = math.floor(m.flight / m.every)
		for k = 1, ticks do
			after(m.cut + k * m.every, function()
				local u = k * m.every / m.flight
				local pos = from:Lerp(to, u)
				for _, o in ipairs(hostilesNear(f, pos, m.width)) do
					if not done[o] or os.clock() - done[o] > 0.6 then
						done[o] = os.clock()
						strike(f, o, hit, move)
					end
				end
			end)
		end
		after(m.cut + m.flight, function()
			Push:FireAllClients("skillfx", { kind = "ancientCrash", id = wid, at = to, center = center, radius = m.finalRadius, waveAt = m.waveAt / sp, waveRadius = m.waveRadius, style = style })
			for _, o in ipairs(hostilesNear(f, to, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
		after(m.cut + m.flight + m.waveAt, function()
			for _, o in ipairs(hostilesNear(f, center, m.waveRadius)) do
				strike(f, o, scaled(m.wave, sc), move)
			end
		end)
	elseif kind == "bambooLine" then
		-- 2.7판 만목 죽림창 (E): 앞으로 곧게 대나무가 차례로 창처럼 솟는다. 적은 한 번만 맞는다
		local from = f.root.Position
		Push:FireAllClients("skillfx", { kind = "bambooLine", from = from, dir = look, n = m.n, start = m.start, gap = m.gap, delay = m.delay / sp, step = m.step / sp, stand = m.stand / sp, style = style })
		local done = {}
		for i = 1, m.n do
			after(m.delay + (i - 1) * m.step, function()
				local pos = from + look * (m.start + (i - 1) * m.gap)
				for _, o in ipairs(hostilesNear(f, pos, m.radius)) do
					if not done[o] then
						done[o] = true
						strike(f, o, hit, move)
					end
				end
			end)
		end
	elseif kind == "leafVolley" then
		-- 2.7판 만목 천엽비수 (R): 잎이 둘레에서 소용돌이친 뒤 가까운 적 여럿에게 줄지어 날아가 벤다
		Push:FireAllClients("skillfx", { kind = "leafGather", m = f.model, dur = m.gather / sp, style = style })
		after(m.gather, function()
			local list = nearestList(f, m.range, m.n)
			Push:FireAllClients("skillfx", { kind = "leafVolley", m = f.model, targets = modelsOf(list), waves = m.waves, every = m.every / sp, travel = m.travel / sp, style = style })
			heal(f, m.heal)
			for w = 0, m.waves - 1 do
				after(m.travel + w * m.every, function()
					for _, o in ipairs(list) do
						strike(f, o, hit, move)
					end
				end)
			end
		end)
	elseif kind == "worldTree" then
		-- 2.7판 만목 신목강림 (오의): 등 뒤에 천 년 은행나무가 솟고 금빛 잎이 쏟아진다. 끝에 잎이 사방으로 휘몰아친다
		local center = f.root.Position
		local at = center - look * m.back
		local id = math.random(1, 1000000000)
		Push:FireAllClients("skillfx", { kind = "treeRise", id = id, at = at, center = center, dir = look, rise = m.rise / sp, dur = m.dur / sp, radius = m.radius, style = style })
		after(m.rise, function()
			heal(f, m.heal)
		end)
		local ticks = math.floor(m.dur / m.every)
		for i = 1, ticks do
			after(m.rise + i * m.every, function()
				for _, o in ipairs(hostilesNear(f, center, m.radius)) do
					strike(f, o, hit, move)
				end
			end)
		end
		after(m.rise + m.dur, function()
			Push:FireAllClients("skillfx", { kind = "treeBurst", id = id, at = at, center = center, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	elseif kind == "thunderStar" then
		-- 2.6판 초·벽력 뇌성강림 (오의): 머리 위로 띄운 뇌성(천둥별)에서 작은 별 여섯이 떨어져 나와 둘레를 돈다.
		-- 별마다 가까운 적을 골라 번개 줄기를 쏘고 (한 번에 한 적은 한 줄기만 맞는다), 끝에 모두 다시 하나로 모여 땅에 떨어진다
		local id = math.random(1, 1000000000)
		local center = f.root.Position + look * (m.dist or 4)
		local n = m.n
		local t0 = m.delay + m.spread
		Push:FireAllClients("skillfx", { kind = "starStart", id = id, at = center, n = n, orbit = m.orbit, height = m.height, spin = m.spin * sp, spread = m.spread / sp, dur = m.dur / sp, delay = m.delay / sp, converge = m.converge / sp, style = style })
		local function orbPos(i: number, t: number): Vector3
			local a = (i - 1) / n * math.pi * 2 + t * m.spin
			return center + Vector3.new(math.cos(a) * m.orbit, m.height, math.sin(a) * m.orbit)
		end
		local ticks = math.floor(m.dur / m.every)
		for k = 0, ticks - 1 do
			local t = k * m.every
			after(t0 + t, function()
				local taken = {}
				local list = hostilesNear(f, center, m.orbit + m.beamRange)
				for i = 1, n do
					local op = orbPos(i, t)
					local best, bd = nil, m.beamRange
					for _, o in ipairs(list) do
						local d = Vector3.new(o.root.Position.X - op.X, 0, o.root.Position.Z - op.Z).Magnitude
						if not taken[o] and d < bd then
							best, bd = o, d
						end
					end
					if best then
						taken[best] = true
						Push:FireAllClients("skillfx", { kind = "starBeam", id = id, i = i, to = best.root.Position, style = style })
						strike(f, best, hit, move)
					elseif (k + i) % 3 == 0 then
						-- 겨눌 적이 없으면 땅을 때린다 (보이기만)
						Push:FireAllClients("skillfx", { kind = "starBeam", id = id, i = i, to = Vector3.new(op.X, center.Y, op.Z), style = style })
					end
				end
			end)
		end
		after(t0 + m.dur + m.converge, function()
			Push:FireAllClients("skillfx", { kind = "starCrash", id = id, at = center, radius = m.finalRadius, style = style })
			for _, o in ipairs(hostilesNear(f, center, m.finalRadius)) do
				strike(f, o, scaled(m.final, sc), move)
			end
		end)
	end
end

return Skills
