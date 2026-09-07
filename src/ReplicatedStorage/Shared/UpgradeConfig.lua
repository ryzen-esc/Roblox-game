local Constants = require(script.Parent.Constants)

--- Rod/Tank/Bait upgrade cost curves and effects. All costs are computed from a level,
-- never sent by the client -- the server always recomputes from UpgradeConfig + the
-- player's authoritative current level.
local UpgradeConfig = {}

local TRACKS = {
	Rod = { baseCost = 50, growth = 1.6, maxLevel = Constants.MAX_ROD_LEVEL },
	Tank = { baseCost = 75, growth = 1.55, maxLevel = Constants.MAX_TANK_LEVEL },
	Bait = { baseCost = 40, growth = 1.5, maxLevel = Constants.MAX_BAIT_LEVEL },
}

UpgradeConfig.Tracks = TRACKS

--- Cost to go from `currentLevel` to `currentLevel + 1` on the given track.
function UpgradeConfig.getUpgradeCost(track: string, currentLevel: number): number?
	local def = TRACKS[track]
	if not def then
		return nil
	end
	if currentLevel >= def.maxLevel then
		return nil -- maxed out, not purchasable
	end
	return math.floor(def.baseCost * (def.growth ^ (currentLevel - 1)))
end

function UpgradeConfig.isMaxed(track: string, currentLevel: number): boolean
	local def = TRACKS[track]
	if not def then
		return true
	end
	return currentLevel >= def.maxLevel
end

--- Tank capacity for a given tank level.
function UpgradeConfig.getTankCapacity(tankLevel: number): number
	return Constants.BASE_TANK_CAPACITY + (tankLevel - 1) * 2
end

--- Rare-rarity weight bias from bait level (each level: +15% weight to non-Common tiers).
function UpgradeConfig.getBaitRareBias(baitLevel: number): number
	return 1 + (baitLevel - 1) * 0.15
end

--- Coin sell multiplier from rod level (small progression feel beyond just unlocking rarities).
function UpgradeConfig.getRodValueBonus(rodLevel: number): number
	return 1 + (rodLevel - 1) * 0.05
end

return UpgradeConfig
