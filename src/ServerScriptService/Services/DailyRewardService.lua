local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)

local PlayerDataService = require(script.Parent.PlayerDataService)

--- Daily login streak. Missing a day gently resets the streak to day 1 rather than
-- punishing the player further -- the goal is "a reason to open the game today," not
-- FOMO-driven guilt.
local DailyRewardService = {}

local REWARD_BY_DAY = { 20, 30, 45, 65, 90, 120, 200 }

local remotes = nil
local rateLimiter = nil
local analyticsService = nil

local function onClaimDailyReward(player: Player)
	if not rateLimiter:allow(player, "dailyReward", 1) then
		return
	end

	local data = PlayerDataService.get(player)
	if not data then
		return
	end

	local now = os.time()
	local last = data.dailyStreak.lastClaimUnix
	local hoursSince = (now - last) / 3600

	if last > 0 and hoursSince < Constants.DAILY_RESET_HOURS then
		return -- not yet eligible; client should already reflect this and not show the button
	end

	local streakCount
	if last == 0 or hoursSince >= (Constants.DAILY_RESET_HOURS * 2) then
		streakCount = 1
	else
		streakCount = math.min(data.dailyStreak.streakCount + 1, Constants.DAILY_STREAK_MAX_DAYS)
	end

	local reward = REWARD_BY_DAY[streakCount] or REWARD_BY_DAY[#REWARD_BY_DAY]
	data.coins += reward
	data.dailyStreak = { lastClaimUnix = now, streakCount = streakCount }

	if analyticsService then
		analyticsService.logEconomy(player, true, "Coins", reward, data.coins, "TimedReward", "DailyReward")
	end

	PlayerDataService.sync(player)
end

function DailyRewardService.init(remotesTable, rateLimiterInstance, analyticsServiceModule)
	remotes = remotesTable
	rateLimiter = rateLimiterInstance
	analyticsService = analyticsServiceModule

	remotes[RemoteNames.CLAIM_DAILY_REWARD_REQUEST].OnServerEvent:Connect(onClaimDailyReward)
end

return DailyRewardService
