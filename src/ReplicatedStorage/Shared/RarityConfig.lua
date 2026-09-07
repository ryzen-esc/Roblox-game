--- Rarity is a modifier applied on top of any fish species (recolor + particle + value multiplier).
-- Order matters: index is used by Constants.ANNOUNCE_MIN_RARITY_INDEX and for sorting.
local RarityConfig = {}

RarityConfig.Tiers = {
	{
		id = "Common",
		name = "Common",
		color = Color3.fromRGB(200, 200, 200),
		valueMultiplier = 1,
		sizeMultiplier = 1,
		baseWeight = 60,
		minRodLevel = 1,
		hasParticles = false,
	},
	{
		id = "Uncommon",
		name = "Uncommon",
		color = Color3.fromRGB(90, 200, 110),
		valueMultiplier = 2,
		sizeMultiplier = 1.1,
		baseWeight = 25,
		minRodLevel = 1,
		hasParticles = false,
	},
	{
		id = "Rare",
		name = "Rare",
		color = Color3.fromRGB(70, 140, 240),
		valueMultiplier = 5,
		sizeMultiplier = 1.25,
		baseWeight = 10,
		minRodLevel = 2,
		hasParticles = true,
	},
	{
		id = "Epic",
		name = "Epic",
		color = Color3.fromRGB(170, 90, 230),
		valueMultiplier = 12,
		sizeMultiplier = 1.45,
		baseWeight = 4,
		minRodLevel = 4,
		hasParticles = true,
	},
	{
		id = "Legendary",
		name = "Legendary",
		color = Color3.fromRGB(250, 200, 60),
		valueMultiplier = 30,
		sizeMultiplier = 1.75,
		baseWeight = 1,
		minRodLevel = 6,
		hasParticles = true,
	},
}

function RarityConfig.getById(rarityId: string)
	for _, tier in RarityConfig.Tiers do
		if tier.id == rarityId then
			return tier
		end
	end
	return nil
end

function RarityConfig.getIndex(rarityId: string): number
	for i, tier in RarityConfig.Tiers do
		if tier.id == rarityId then
			return i
		end
	end
	return 1
end

--- Rolls a rarity id using weighted random, restricted to tiers unlocked at rodLevel.
-- rareBiasMultiplier (default 1) scales the weight of every non-Common tier, e.g. from
-- bait level or a temporary Rare Bait boost. It never affects which tiers are eligible.
function RarityConfig.rollRarity(rodLevel: number, rareBiasMultiplier: number?): string
	local bias = rareBiasMultiplier or 1
	local eligible = {}
	local totalWeight = 0
	for _, tier in RarityConfig.Tiers do
		if rodLevel >= tier.minRodLevel then
			local weight = tier.id == "Common" and tier.baseWeight or tier.baseWeight * bias
			table.insert(eligible, { tier = tier, weight = weight })
			totalWeight += weight
		end
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in eligible do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.tier.id
		end
	end

	return eligible[1].tier.id
end

return RarityConfig
