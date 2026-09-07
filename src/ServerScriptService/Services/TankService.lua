local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local FishData = require(ReplicatedStorage.Shared.FishData)
local RarityConfig = require(ReplicatedStorage.Shared.RarityConfig)
local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)

local PlayerDataService = require(script.Parent.PlayerDataService)

--- Owns fish growth ticking (online; offline growth is handled once on load by
-- PlayerDataService) and selling. Sell handlers never yield between validating and
-- mutating Coins/fish, so a single Roblox event handler runs to completion before the
-- next fires -- no explicit lock is needed to prevent a double-spend race.
local TankService = {}

local TICK_INTERVAL_SECONDS = 15
local SYNC_EVERY_N_TICKS = 4 -- ~60s between growth-driven syncs; growth is slow enough this is imperceptible

local remotes = nil
local rateLimiter = nil
local monetizationService = nil

local function sellValue(player: Player, fish, rodLevel: number): number
	local species = FishData.getById(fish.speciesId)
	local rarity = RarityConfig.getById(fish.rarityId)
	if not species or not rarity then
		return 0
	end
	local growthValue = 0.5 + 0.5 * fish.growth
	local rodBonus = UpgradeConfig.getRodValueBonus(rodLevel)
	local coinMultiplier = monetizationService and monetizationService.getCoinMultiplier(player) or 1
	return math.floor(species.baseValue * rarity.valueMultiplier * growthValue * rodBonus * coinMultiplier)
end

local function onSellFishRequest(player: Player, payload)
	if not rateLimiter:allow(player, "sell", 0.2) then
		return
	end
	if type(payload) ~= "table" then
		return
	end

	local data = PlayerDataService.get(player)
	if not data then
		return
	end

	local totalEarned = 0

	if payload.all == true then
		for uid, fish in data.fish do
			totalEarned += sellValue(player, fish, data.rodLevel)
			data.fish[uid] = nil
		end
	elseif type(payload.uid) == "string" then
		local fish = data.fish[payload.uid]
		if fish then
			totalEarned += sellValue(player, fish, data.rodLevel)
			data.fish[payload.uid] = nil
		end
	end

	if totalEarned > 0 then
		data.coins += totalEarned
		PlayerDataService.sync(player)
	end
end

local function tickGrowth()
	local tickCount = 0
	while true do
		task.wait(TICK_INTERVAL_SECONDS)
		tickCount += 1

		local growthDelta = TICK_INTERVAL_SECONDS / Constants.GROWTH_TIME_SECONDS
		local shouldSync = (tickCount % SYNC_EVERY_N_TICKS == 0)

		for _, player in Players:GetPlayers() do
			if PlayerDataService.isLoaded(player) then
				local data = PlayerDataService.get(player)
				local changed = false
				for _, fish in data.fish do
					if fish.growth < 1 then
						fish.growth = math.clamp(fish.growth + growthDelta, 0, 1)
						changed = true
					end
				end
				if changed and shouldSync then
					PlayerDataService.sync(player)
				end
			end
		end
	end
end

function TankService.init(remotesTable, rateLimiterInstance, monetizationServiceModule)
	remotes = remotesTable
	rateLimiter = rateLimiterInstance
	monetizationService = monetizationServiceModule

	remotes[RemoteNames.SELL_FISH_REQUEST].OnServerEvent:Connect(onSellFishRequest)

	task.spawn(tickGrowth)
end

return TankService
