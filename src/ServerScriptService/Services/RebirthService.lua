local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)
local FishValue = require(ReplicatedStorage.Shared.FishValue)

local PlayerDataService = require(script.Parent.PlayerDataService)

--- Prestige/rebirth: available once Rod and Tank are both maxed. Liquidates every fish at
-- its current value (nothing is lost for free), resets Coins/Rod/Tank to their starting
-- levels, and grants a permanent +REBIRTH_SELL_BONUS_PER_REBIRTH sell-value multiplier
-- (applied by FishValue.compute, shared with TankService, using the new rebirths count).
-- Bait level is intentionally untouched -- the design doc scopes rebirth to "Coins +
-- rod/tank tier" only.
local RebirthService = {}

local remotes = nil
local rateLimiter = nil
local achievementService = nil
local analyticsService = nil

local function isEligible(data): boolean
	return (data.rodLevel or 1) >= UpgradeConfig.Tracks.Rod.maxLevel and (data.tankLevel or 1) >= UpgradeConfig.Tracks.Tank.maxLevel
end

local function onRebirthRequest(player: Player)
	if not rateLimiter:allow(player, "rebirth", 1) then
		return
	end

	local data = PlayerDataService.get(player)
	if not data then
		return
	end
	if not isEligible(data) then
		return
	end

	local liquidated = 0
	for uid, fish in data.fish do
		liquidated += FishValue.compute(fish, data.rodLevel, data.rebirths)
		data.fish[uid] = nil
	end
	data.coins += liquidated

	if analyticsService and liquidated > 0 then
		analyticsService.logEconomy(player, true, "Coins", liquidated, data.coins, "Gameplay", "RebirthLiquidation")
	end

	data.coins = 0
	data.rodLevel = 1
	data.tankLevel = 1
	data.rebirths = (data.rebirths or 0) + 1

	if achievementService then
		achievementService.checkAll(player, data)
	end

	PlayerDataService.sync(player)
end

function RebirthService.init(remotesTable, rateLimiterInstance, achievementServiceModule, analyticsServiceModule)
	remotes = remotesTable
	rateLimiter = rateLimiterInstance
	achievementService = achievementServiceModule
	analyticsService = analyticsServiceModule

	remotes[RemoteNames.REBIRTH_REQUEST].OnServerEvent:Connect(onRebirthRequest)
end

return RebirthService
