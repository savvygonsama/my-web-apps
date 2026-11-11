-- 권왕 3.53판: 영어 화면 (내 화면에서만 글자를 바꾼다. 서버 · 다른 사람은 그대로)
--   · 처음 들어올 때 로블록스 언어가 한국어가 아니면 영어로 시작한다. 메뉴의 🌐 단추로 바꾼다
--   · 화면에 뜨는 모든 글자 (메뉴 · 창 · 알림 · 대화 · 머리 위 이름 · 간판 · 안내 단추) 를 뜨는 순간 바꾼다
--   · 바꾸는 법: 숫자를 자리표로 뺀 뒤 ① 통째로 맞는 문장 ② %s 자리가 있는 틀 ③ 아는 낱말을 긴 것부터 갈아 끼우기
--   · 사전은 LangEN (코드 안의 한국어 글자마다 영어 하나)
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local DICT: { [string]: string } = require(script.Parent:WaitForChild("LangEN"))

local Lang = {}
Lang.en = false

local NUM = "\1"
local SLOT = "\3"
local HANGUL = "[\234-\237][\128-\191][\128-\191]"

-- 원문 (코드 속 글자) 을 비교용 꼴로: %d · %.1f 같은 숫자 자리와 숫자는 NUM, %s 는 SLOT
local function normKey(s: string): string
	s = s:gsub("%%%%", "\2")
	s = s:gsub("%%[%-+#0]*%d*%.?%d*[dfiuxXg]", NUM)
	s = s:gsub("%%%-?%d*s", SLOT)
	s = s:gsub("%d[%d,%.]*", function(d)
		local _, t = d:match("^(.-)([,%.]*)$")
		return NUM .. t
	end)
	s = s:gsub("\2", "%%")
	return s
end

local exact: { [string]: string } = {}
local plain: { { string } } = {} -- 낱말 갈아 끼우기용 (긴 것부터)
local templates: { { any } } = {}

local function escapePat(s: string): string
	return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

local function hangulCount(s: string): number
	local _, n = s:gsub(HANGUL, "")
	return n
end

for k, v in pairs(DICT) do
	local nk, nv = normKey(k), normKey(v)
	if nk:find(SLOT, 1, true) then
		-- 틀: 고정된 조각 중 가장 긴 것으로 먼저 걸러 낸다
		local pieces = string.split(nk, SLOT)
		local longest = ""
		for _, p in ipairs(pieces) do
			if #p > #longest then
				longest = p
			end
		end
		local pat = "^" .. escapePat(nk):gsub(escapePat(SLOT), "(.-)") .. "$"
		table.insert(templates, { pat, nv, longest, #nk })
	else
		exact[nk] = nv
		if hangulCount(nk) >= 2 then
			table.insert(plain, { nk, nv })
		end
	end
end
table.sort(plain, function(a, b)
	return #a[1] > #b[1]
end)
table.sort(templates, function(a, b)
	return a[4] > b[4]
end)

-- 영어 낱말 바로 뒤에 남은 토씨를 걷는다 (예: "Black Tiger를" → "Black Tiger")
local PARTICLES = { "에서는", "에서", "으로", "까지", "부터", "에게", "이다", "이고", "이며", "와", "과", "을", "를", "이", "가", "은", "는", "의", "에", "로", "도", "만" }

local COUNTERS = { { "단계", "" }, { "장", "" }, { "번", "x" }, { "개", "" }, { "명", "" }, { "칸", " studs" }, { "초", "s" }, { "분", " min" }, { "층", "F" } }

local translateNorm: (string, number) -> string

local function replaceAll(s: string, from: string, to: string): string
	local out = {}
	local i = 1
	while true do
		local a, b = s:find(from, i, true)
		if not a then
			break
		end
		table.insert(out, s:sub(i, a - 1))
		table.insert(out, to)
		i = b + 1
	end
	if i == 1 then
		return s
	end
	table.insert(out, s:sub(i))
	return table.concat(out)
end

translateNorm = function(n: string, depth: number): string
	if not n:find(HANGUL) then
		return n
	end
	local hit = exact[n]
	if hit then
		return hit
	end
	-- 앞뒤 빈칸 · 줄바꿈은 떼고 다시
	local lead, core, tail = n:match("^(%s*)(.-)(%s*)$")
	if core and (lead ~= "" or tail ~= "") and exact[core] then
		return lead .. exact[core] .. tail
	end
	if depth < 3 then
		for _, t in ipairs(templates) do
			if t[3] == "" or n:find(t[3], 1, true) then
				local caps = { n:match(t[1]) }
				if #caps > 0 then
					local k = 0
					return (t[2]:gsub(SLOT, function()
						k += 1
						return translateNorm(caps[k] or "", depth + 1)
					end))
				end
			end
		end
		-- 줄마다 따로
		if n:find("\n", 1, true) then
			local lines = string.split(n, "\n")
			for i, l in ipairs(lines) do
				lines[i] = translateNorm(l, depth + 1)
			end
			return table.concat(lines, "\n")
		end
	end
	-- 아는 낱말을 긴 것부터
	local s = n
	for _, e in ipairs(plain) do
		if #e[1] <= #s and s:find(e[1], 1, true) then
			s = replaceAll(s, e[1], e[2])
			if not s:find(HANGUL) then
				break
			end
		end
	end
	if s:find(HANGUL) then
		-- 숫자 뒤의 세는 말 (12장 · 3번 · 5개 · 10칸 · 3초)
		for _, c in ipairs(COUNTERS) do
			s = s:gsub(NUM .. c[1], NUM .. c[2])
		end
		for _, p in ipairs(PARTICLES) do
			s = s:gsub("([%w%)%]'\"!%.])" .. p .. "([%s%p])", "%1%2")
			s = s:gsub("([%w%)%]'\"!%.])" .. p .. "$", "%1")
		end
	end
	return s
end

local cache: { [string]: string } = {}
local cacheN = 0

function Lang.translate(s: string): string
	if type(s) ~= "string" or not s:find(HANGUL) then
		return s
	end
	local nums = {}
	local n = s:gsub("%d[%d,%.]*", function(d)
		local core, t = d:match("^(.-)([,%.]*)$")
		table.insert(nums, core)
		return NUM .. t
	end)
	local out = cache[n]
	if not out then
		out = translateNorm(n, 0)
		if cacheN > 6000 then
			cache = {}
			cacheN = 0
		end
		cache[n] = out
		cacheN += 1
	end
	local k = 0
	return (out:gsub(NUM, function()
		k += 1
		return nums[k] or ""
	end))
end

------------------------------------------------------------------------
-- 3.72판: 터치 기기는 PC 키 글자를 단추로 (F 막기 → 🛡, Z 강타 → 💥, T 말 걸기 → 화면의 단추)
-- 원문은 그대로 두고 화면에 붙일 때만 바꾼다. 'M Y T H I C' 같이 띄어 쓴 큰 글자는 건드리지 않는다
------------------------------------------------------------------------
Lang.touch = false
local function touchify(s: string): string
	if not Lang.touch or type(s) ~= "string" or not s:find("%f[%w][FTZ]%f[%W]") or s:find("%u %u %u") then
		return s
	end
	-- 각성기 (F) 는 연타 끝에 저절로 나간다 (막기 단추가 아니다)
	s = s:gsub("각성기%(F%)", "각성기"):gsub("awakening skill %(F%)", "awakening skill")
	if Lang.en then
		s = s:gsub("%(T%)", "(tap)")
		s = s:gsub("([Pp])ress ([FTZ])%f[%W]", function(p, k)
			return (p == "P" and "T" or "t") .. "ap " .. k
		end)
		s = s:gsub("%f[%w]T%f[%W]", "the prompt")
	else
		s = s:gsub("%(T%)", "(단추)")
		s = s:gsub("%f[%w]T를", "단추를"):gsub("%f[%w]T가", "단추가"):gsub("%f[%w]T는", "단추는")
		s = s:gsub("%f[%w]T%f[%W]", "단추")
	end
	s = s:gsub("%f[%w]F%f[%W]", "🛡"):gsub("%f[%w]Z%f[%W]", "💥")
	return s
end
-- 3.74판: 을(를) · 은(는) · 이(가) · 과(와) · (으)로 를 앞 글자의 받침에 맞게 하나로 (한국어 화면)
local SYL = "([\234-\237][\128-\191][\128-\191])"
local function jong(ch: string): number?
	local ok, cp = pcall(utf8.codepoint, ch)
	if not ok or type(cp) ~= "number" or cp < 0xAC00 or cp > 0xD7A3 then
		return nil
	end
	return (cp - 0xAC00) % 28
end
local function pick(pat: string, withB: string, without: string, rieulAsNone: boolean?)
	return function(s: string): string
		return (s:gsub(SYL .. pat, function(c)
			local j = jong(c)
			if j == nil then
				return nil
			end
			local has = j > 0 and not (rieulAsNone and j == 8)
			return c .. (has and withB or without)
		end))
	end
end
local JOSA = {
	pick("을%(를%)", "을", "를"),
	pick("를%(을%)", "을", "를"),
	pick("은%(는%)", "은", "는"),
	pick("이%(가%)", "이", "가"),
	pick("과%(와%)", "과", "와"),
	pick("와%(과%)", "과", "와"),
	pick("%(으%)로", "으로", "로", true),
}
local function josa(s: string): string
	if type(s) ~= "string" or not s:find("(", 1, true) then
		return s
	end
	for _, f in ipairs(JOSA) do
		s = f(s)
	end
	return s
end
Lang.josa = josa
local function render(s: string): string
	return touchify(Lang.en and Lang.translate(s) or josa(s))
end
Lang.render = render

------------------------------------------------------------------------
-- 화면 글자에 붙이기
------------------------------------------------------------------------
local PROPS = {
	TextLabel = { "Text" },
	TextButton = { "Text" },
	TextBox = { "PlaceholderText" },
	ProximityPrompt = { "ActionText", "ObjectText" },
}
local orig: { [Instance]: { [string]: string } } = setmetatable({}, { __mode = "k" }) :: any
local last: { [Instance]: { [string]: string } } = setmetatable({}, { __mode = "k" }) :: any
local hooked: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function apply(inst: Instance, prop: string)
	local cur = (inst :: any)[prop]
	local L = last[inst]
	if L and L[prop] == cur then
		return -- 내가 넣은 글자
	end
	orig[inst] = orig[inst] or {}
	orig[inst][prop] = cur
	local out = render(cur)
	last[inst] = L or {}
	last[inst][prop] = out
	if out ~= cur then
		(inst :: any)[prop] = out
	end
end

local function hook(inst: Instance)
	local props = PROPS[inst.ClassName]
	if not props or hooked[inst] or inst:GetAttribute("NoTranslate") then
		return
	end
	hooked[inst] = true
	for _, prop in ipairs(props) do
		apply(inst, prop)
		inst:GetPropertyChangedSignal(prop):Connect(function()
			apply(inst, prop)
		end)
	end
end

-- 켜고 끌 때: 붙여 둔 글자를 모두 원문에서 다시
local function refreshAll()
	for inst in pairs(hooked) do
		if inst.Parent then
			for _, prop in ipairs(PROPS[inst.ClassName]) do
				local o = orig[inst] and orig[inst][prop]
				if o then
					local out = render(o)
					last[inst] = last[inst] or {}
					last[inst][prop] = out
					;(inst :: any)[prop] = out
				end
			end
		end
	end
end

local listeners: { () -> () } = {}
function Lang.onChange(fn: () -> ())
	table.insert(listeners, fn)
end

function Lang.set(en: boolean)
	if Lang.en == en then
		return
	end
	Lang.en = en
	refreshAll()
	for _, fn in ipairs(listeners) do
		task.spawn(fn)
	end
end

function Lang.start()
	local ok, loc = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	Lang.en = not (ok and type(loc) == "string" and loc:sub(1, 2) == "ko")
	local UIS = game:GetService("UserInputService")
	Lang.touch = UIS.TouchEnabled and not (UIS.KeyboardEnabled and UIS.MouseEnabled)
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, root in ipairs({ pg, workspace }) do
		root.DescendantAdded:Connect(function(d)
			if PROPS[d.ClassName] then
				hook(d)
			end
		end)
		task.spawn(function()
			for i, d in ipairs(root:GetDescendants()) do
				if PROPS[d.ClassName] then
					hook(d)
				end
				if i % 4000 == 0 then
					task.wait()
				end
			end
		end)
	end
end

return Lang
