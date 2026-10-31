-- 권왕 3.7판: 사부의 부탁 (미니 퀘스트). 높은 권법의 사부는 시험 전에 부탁을 한다
-- 기록: p.mq[권법] = 지금 단계 (1부터, 다 끝나면 단계 수 + 1), p.mqn[권법] = 그 단계에서 해낸 수 (찾기·차례·쓰러뜨리기)
-- 찾은 것 하나하나는 p.seen["mq_권법_단계_번호"]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local MiniQuest = {}

local ctx: any = nil
-- ctx = { profiles, states, toast, dialog, pushState, isDay, rootOf, fx }
function MiniQuest.init(c: any)
	ctx = c
end

local function quest(sid: string): any
	return Config.MINIQUEST and Config.MINIQUEST[sid]
end
function MiniQuest.has(sid: string): boolean
	return quest(sid) ~= nil
end
-- 부탁을 다 들어주었나 (부탁이 없는 권법은 늘 그렇다)
function MiniQuest.done(p: any, sid: string): boolean
	local q = quest(sid)
	if not q then
		return true
	end
	return (p.mq[sid] or 0) > #q.steps
end
local function stepOf(p: any, sid: string): (any, number)
	local q = quest(sid)
	local i = p.mq[sid] or 0
	return q and q.steps[i], i
end
local function progressText(p: any, sid: string, step: any): string
	local n = p.mqn[sid] or 0
	if step.kind == "find" then
		return string.format(" (%d/%d)", n, #step.items)
	elseif step.kind == "order" then
		return string.format(" (%d/%d)", n, #step.stones)
	elseif step.kind == "kill" then
		return string.format(" (%d/%d)", n, step.n)
	end
	return ""
end
-- 지금 부탁을 한 줄로 (사부 대화·토스트에 쓴다)
function MiniQuest.line(p: any, sid: string): string
	local q = quest(sid)
	local step, i = stepOf(p, sid)
	if not q or not step then
		return ""
	end
	return string.format("「%s」 %d/%d · %s%s", q.title, i, #q.steps, step.text, progressText(p, sid, step))
end

local function advance(player: Player, sid: string)
	local p, st = ctx.profiles[player], ctx.states[player]
	local q = quest(sid)
	if not p or not st or not q then
		return
	end
	p.mq[sid] = (p.mq[sid] or 0) + 1
	p.mqn[sid] = 0
	st.dirty = true
	local m = Config.MASTERS[sid]
	local step = q.steps[p.mq[sid]]
	if step then
		ctx.toast(player, "📜 " .. (m and m.name or "사부") .. "의 부탁 · " .. step.text)
	else
		ctx.toast(player, "📜 부탁을 모두 들어주었다")
	end
	ctx.pushState(player)
end

-- 사부에게 말을 걸었다: 부탁을 시작하거나, 지금 단계를 알려 주거나, 돌아왔음을 받는다.
-- true면 사부가 시험을 낼 수 있다 (부탁을 다 들어주었다)
function MiniQuest.talk(player: Player, sid: string): boolean
	local p, st = ctx.profiles[player], ctx.states[player]
	local q = quest(sid)
	if not q or not p or not st then
		return true
	end
	local m = Config.MASTERS[sid]
	local who = m and m.name or "사부"
	local title = m and ("「" .. m.quote .. "」") or ""
	if (p.mq[sid] or 0) == 0 then
		p.mq[sid] = 1
		p.mqn[sid] = 0
		st.dirty = true
		ctx.dialog(player, { who = who, title = title, text = "시험을 청하기 전에, 부탁이 하나 있다. 「" .. q.title .. "」\n" .. q.steps[1].text .. progressText(p, sid, q.steps[1]) })
		ctx.pushState(player)
		return false
	end
	local step = q.steps[p.mq[sid]]
	if not step then
		return true
	end
	if step.kind == "return" then
		advance(player, sid)
		ctx.dialog(player, { who = who, title = title, text = "...왔구나. 부탁을 들어주었으니 이제 네 차례다. 시험을 내마. (다시 T를 누르면 시험이 시작된다)" })
		return false
	end
	ctx.dialog(player, { who = who, title = title, text = "아직 부탁이 남았다. " .. MiniQuest.line(p, sid) })
	return false
end

-- 들판에 놓인 것을 짚었다 (찾기·차례)
function MiniQuest.touch(player: Player, sid: string, stepIdx: number, idx: number)
	local p, st = ctx.profiles[player], ctx.states[player]
	if not p or not st then
		return
	end
	local step, cur = stepOf(p, sid)
	if not step or cur ~= stepIdx then
		ctx.toast(player, "…아직은 그저 고운 것 같다")
		return
	end
	if step.kind == "find" then
		local key = string.format("mq_%s_%d_%d", sid, stepIdx, idx)
		if p.seen[key] then
			ctx.toast(player, "이미 찾은 것이에요")
			return
		end
		p.seen[key] = true
		p.mqn[sid] = (p.mqn[sid] or 0) + 1
		st.dirty = true
		ctx.toast(player, string.format("%s %s (%d/%d)", step.icon or "✨", step.name or "찾았다", p.mqn[sid], #step.items))
		if p.mqn[sid] >= #step.items then
			advance(player, sid)
		else
			ctx.pushState(player)
		end
	elseif step.kind == "order" then
		local n = (p.mqn[sid] or 0) + 1
		-- 같은 글자가 둘이면 어느 쪽을 짚어도 된다 (N U L L)
		local want, got = step.stones[n], step.stones[idx]
		if idx == n or (got and want and got.label ~= nil and got.label == want.label) then
			p.mqn[sid] = n
			st.dirty = true
			ctx.toast(player, string.format("✨ %s %d/%d", step.name or "차례", n, #step.stones))
			if ctx.fx then
				ctx.fx(player, "mqLight", step.stones[idx].at)
			end
			if n >= #step.stones then
				advance(player, sid)
			else
				ctx.pushState(player)
			end
		else
			p.mqn[sid] = 0
			st.dirty = true
			ctx.toast(player, "💨 차례가 틀렸다. 처음부터 다시")
			ctx.pushState(player)
		end
	end
end

-- 적을 쓰러뜨렸다
function MiniQuest.onKill(player: Player, typeId: string?)
	local p = ctx.profiles[player]
	if not p or not typeId then
		return
	end
	for sid, _ in pairs(Config.MINIQUEST or {}) do
		local step = stepOf(p, sid)
		if step and step.kind == "kill" and step.enemy == typeId then
			p.mqn[sid] = (p.mqn[sid] or 0) + 1
			ctx.states[player].dirty = true
			if p.mqn[sid] >= step.n then
				advance(player, sid)
			else
				ctx.toast(player, string.format("📜 %s (%d/%d)", step.text, p.mqn[sid], step.n))
			end
		end
	end
end

-- 1초마다: 가야 할 곳에 닿았나
function MiniQuest.tick(player: Player)
	local p = ctx.profiles[player]
	if not p then
		return
	end
	local r = ctx.rootOf(player)
	if not r then
		return
	end
	for sid, _ in pairs(Config.MINIQUEST or {}) do
		local step = stepOf(p, sid)
		if step and step.kind == "visit" then
			local d = Vector3.new(r.Position.X - step.at.X, 0, r.Position.Z - step.at.Z).Magnitude
			if d <= step.r and math.abs(r.Position.Y - step.at.Y) < 200 then
				if step.night and ctx.isDay() then
					local st = ctx.states[player] :: any
					if os.clock() - (st.mqNightHint or 0) > 20 then
						st.mqNightHint = os.clock()
						ctx.toast(player, "🌙 여기는 밤에 와야 할 것 같다")
					end
				else
					if step.say then
						ctx.dialog(player, { who = "📜 " .. quest(sid).title, title = "", text = step.say })
					end
					advance(player, sid)
				end
			end
		end
	end
end

-- 테스트: 진행 중인 부탁을 한 단계씩 넘긴다
function MiniQuest.skip(player: Player)
	local p = ctx.profiles[player]
	if not p then
		return
	end
	local any = false
	for sid, q in pairs(Config.MINIQUEST or {}) do
		local i = p.mq[sid] or 0
		if i >= 1 and i <= #q.steps then
			advance(player, sid)
			any = true
		end
	end
	if not any then
		ctx.toast(player, "진행 중인 부탁이 없어요 (사부에게 먼저 말을 거세요)")
	end
end

return MiniQuest
