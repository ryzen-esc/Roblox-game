local Constants = require(script.Parent.Constants)

--- Achievement definitions. Each `check(data)` is a pure function over the player's
-- authoritative save data (never anything client-supplied) -- the server is the only place
-- that ever calls `check`; the client only reads `id`/`name`/`description`/`coinReward` to
-- render the list. `badgeId` is a placeholder (0) like MonetizationIds.lua -- fill in real
-- Roblox Badge ids in the Creator Hub if/when the user wants profile-visible badges; award
-- is a no-op while it's 0. Order here is display order.
local AchievementConfig = {}

local function fishCount(data): number
	local count = 0
	for _ in data.fish do
		count += 1
	end
	return count
end

local function rarityCount(data, rarityId): number
	return (data.rarityCatchCounts and data.rarityCatchCounts[rarityId]) or 0
end

AchievementConfig.List = {
	{
		id = "FirstCatch",
		name = "First Catch",
		description = "Catch your very first fish.",
		coinReward = 10,
		badgeId = 0,
		check = function(data)
			return (data.totalFishCaught or 0) >= 1
		end,
	},
	{
		id = "GettingTheHangOfIt",
		name = "Getting the Hang of It",
		description = "Catch 10 fish.",
		coinReward = 25,
		badgeId = 0,
		check = function(data)
			return (data.totalFishCaught or 0) >= 10
		end,
	},
	{
		id = "DedicatedAngler",
		name = "Dedicated Angler",
		description = "Catch 50 fish.",
		coinReward = 75,
		badgeId = 0,
		check = function(data)
			return (data.totalFishCaught or 0) >= 50
		end,
	},
	{
		id = "MasterAngler",
		name = "Master Angler",
		description = "Catch 200 fish.",
		coinReward = 200,
		badgeId = 0,
		check = function(data)
			return (data.totalFishCaught or 0) >= 200
		end,
	},
	{
		id = "LegendaryAngler",
		name = "Legendary Angler",
		description = "Catch 1,000 fish.",
		coinReward = 500,
		badgeId = 0,
		check = function(data)
			return (data.totalFishCaught or 0) >= 1000
		end,
	},
	{
		id = "OohShiny",
		name = "Ooh, Shiny",
		description = "Catch your first Rare fish.",
		coinReward = 20,
		badgeId = 0,
		check = function(data)
			return rarityCount(data, "Rare") >= 1
		end,
	},
	{
		id = "RadiantFind",
		name = "Radiant Find",
		description = "Catch your first Epic fish.",
		coinReward = 50,
		badgeId = 0,
		check = function(data)
			return rarityCount(data, "Epic") >= 1
		end,
	},
	{
		id = "LegendHasIt",
		name = "Legend Has It",
		description = "Catch your first Legendary fish.",
		coinReward = 150,
		badgeId = 0,
		check = function(data)
			return rarityCount(data, "Legendary") >= 1
		end,
	},
	{
		id = "FullyRigged",
		name = "Fully Rigged",
		description = "Max out your Rod.",
		coinReward = 300,
		badgeId = 0,
		check = function(data)
			return (data.rodLevel or 1) >= Constants.MAX_ROD_LEVEL
		end,
	},
	{
		id = "RoomToGrow",
		name = "Room to Grow",
		description = "Max out your Tank.",
		coinReward = 300,
		badgeId = 0,
		check = function(data)
			return (data.tankLevel or 1) >= Constants.MAX_TANK_LEVEL
		end,
	},
	{
		id = "PerfectlyPrepared",
		name = "Perfectly Prepared",
		description = "Max out your Bait.",
		coinReward = 200,
		badgeId = 0,
		check = function(data)
			return (data.baitLevel or 1) >= Constants.MAX_BAIT_LEVEL
		end,
	},
	{
		id = "FullHouse",
		name = "Full House",
		description = "Have 20 fish in your tank at once.",
		coinReward = 100,
		badgeId = 0,
		check = function(data)
			return fishCount(data) >= 20
		end,
	},
	{
		id = "NewBeginnings",
		name = "New Beginnings",
		description = "Rebirth for the first time.",
		coinReward = 500,
		badgeId = 0,
		check = function(data)
			return (data.rebirths or 0) >= 1
		end,
	},
}

function AchievementConfig.getById(id: string)
	for _, achievement in AchievementConfig.List do
		if achievement.id == id then
			return achievement
		end
	end
	return nil
end

return AchievementConfig
