--- Client-side mirror of the server's PlayerDataSync payload. This is a cache for
-- rendering only -- the client never treats this as authoritative for anything it sends
-- back to the server (every request the server receives is re-validated there).
local ClientState = {}

ClientState.current = {
	coins = 0,
	rodLevel = 1,
	tankLevel = 1,
	baitLevel = 1,
	rebirths = 0,
	fish = {},
	dailyStreak = { lastClaimUnix = 0, streakCount = 0 },
	achievements = {},
}

ClientState.Changed = Instance.new("BindableEvent")

function ClientState.set(data)
	ClientState.current = data
	ClientState.Changed:Fire(data)
end

return ClientState
