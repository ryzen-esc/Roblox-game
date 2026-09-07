--- Generic per-player-per-key minimum-interval limiter. Wrap every remote handler with
-- this as a backstop against spam/exploited clients, independent of any game-logic
-- cooldown (e.g. the fishing cast cooldown) the service itself also enforces.
local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new()
	return setmetatable({ _lastCallAt = {} }, RateLimiter)
end

--- Returns true if the call is allowed (and records it), false if it's too soon.
function RateLimiter:allow(player: Player, key: string, minIntervalSeconds: number): boolean
	local userId = player.UserId
	self._lastCallAt[userId] = self._lastCallAt[userId] or {}

	local now = os.clock()
	local last = self._lastCallAt[userId][key]
	if last and (now - last) < minIntervalSeconds then
		return false
	end

	self._lastCallAt[userId][key] = now
	return true
end

function RateLimiter:clearPlayer(player: Player)
	self._lastCallAt[player.UserId] = nil
end

return RateLimiter
