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
local Combat = require(script.Parent:WaitForChild("Combat"))

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

-- 기술 하나의 장치를 돌린다. ctx = { scale, speed }
function Skills.run(f: any, move: any, ctx: any)
	local m = move.mech
	if not m then
		return
	end
	local sp = ctx.speed or 1
	local sc = ctx.scale or 1
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
				Push:FireAllClients("skillfx", { kind = "pillar", at = p, radius = m.radius, style = style, i = i })
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
	elseif kind == "trail" then
		local from = f.root.Position
		after(m.delay, function()
			local to = f.root.Position
			local pts = {}
			for k = 0, m.count - 1 do
				table.insert(pts, from:Lerp(to, (k + 0.5) / m.count))
			end
			Push:FireAllClients("skillfx", { kind = "trail", points = pts, radius = m.radius, style = style })
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
