local FishData = require(script.Parent.FishData)
local RarityConfig = require(script.Parent.RarityConfig)
local UpgradeConfig = require(script.Parent.UpgradeConfig)
local Constants = require(script.Parent.Constants)

--- Pure sell-value formula, shared by every server path that ever converts a fish to Coins
-- (TankService's manual/bulk sell, RebirthService's pre-reset liquidation) so they can never
-- drift out of sync with each other.
local FishValue = {}

function FishValue.compute(fish, rodLevel: number, rebirths: number?, coinMultiplier: number?): number
	local species = FishData.getById(fish.speciesId)
	local rarity = RarityConfig.getById(fish.rarityId)
	if not species or not rarity then
		return 0
	end
	local growthValue = 0.5 + 0.5 * fish.growth
	local rodBonus = UpgradeConfig.getRodValueBonus(rodLevel)
	local rebirthBonus = 1 + (rebirths or 0) * Constants.REBIRTH_SELL_BONUS_PER_REBIRTH
	return math.floor(species.baseValue * rarity.valueMultiplier * growthValue * rodBonus * rebirthBonus * (coinMultiplier or 1))
end

return FishValue
