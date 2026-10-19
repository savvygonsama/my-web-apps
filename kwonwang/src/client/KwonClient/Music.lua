-- 권왕: 배경 음악. 있는 곳에 따라 바꾸고, 바뀔 때 천천히 겹쳐 넘긴다 (Config.MUSIC의 번호가 0이면 조용하다)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Music = {}
local current: Sound? = nil
local currentKey = ""
local muted = false

local function idOf(key: string): number
	local id = tonumber(Config.MUSIC[key]) or 0
	if id == 0 and key ~= "default" then
		return tonumber(Config.MUSIC.default) or 0
	end
	return id
end

-- key: village / default / boss / tower / 지역 id (snow, cult ...)
function Music.set(key: string)
	local id = idOf(key)
	local resolved = id == 0 and "" or tostring(id)
	if resolved == currentKey then
		return
	end
	currentKey = resolved
	local old = current
	current = nil
	if old then
		local o = old
		TweenService:Create(o, TweenInfo.new(1.5), { Volume = 0 }):Play()
		task.delay(1.6, function()
			o:Destroy()
		end)
	end
	if id == 0 then
		return
	end
	local s = Instance.new("Sound")
	s.Name = "KwonMusic"
	s.SoundId = "rbxassetid://" .. id
	s.Looped = true
	s.Volume = 0
	s.Parent = SoundService
	s:Play()
	current = s
	TweenService:Create(s, TweenInfo.new(2), { Volume = muted and 0 or Config.MUSIC.volume }):Play()
end

function Music.toggleMute(): boolean
	muted = not muted
	if current then
		current.Volume = muted and 0 or Config.MUSIC.volume
	end
	return muted
end

return Music
