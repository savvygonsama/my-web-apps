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
	end
end

return Skills
