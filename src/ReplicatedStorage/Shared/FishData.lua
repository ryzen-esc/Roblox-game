local Constants = require(script.Parent.Constants)

--- Fish species. Rarity (RarityConfig) is a separate modifier applied on top of these,
-- so N species x M rarities gives N*M meaningful variety from N+M authored rows.
-- Adding a new species later (new content drop) is: one row here + reuse of FishModelFactory.
local FishData = {}

FishData.Species = {
	{
		id = "Minnow",
		name = "Minnow",
		baseValue = 4,
		baseSize = 0.6,
		bodyColor = Color3.fromRGB(180, 190, 200),
		minRodLevel = 1,
	},
	{
		id = "Bluegill",
		name = "Bluegill",
		baseValue = 8,
		baseSize = 0.75,
		bodyColor = Color3.fromRGB(80, 140, 200),
		minRodLevel = 1,
	},
	{
		id = "Sunfish",
		name = "Sunfish",
		baseValue = 14,
		baseSize = 0.85,
		bodyColor = Color3.fromRGB(240, 190, 60),
		minRodLevel = 1,
	},
	{
		id = "Catfish",
		name = "Catfish",
		baseValue = 22,
		baseSize = 1.1,
		bodyColor = Color3.fromRGB(90, 90, 100),
		minRodLevel = 2,
	},
	{
		id = "Angelfish",
		name = "Angelfish",
		baseValue = 35,
		baseSize = 0.9,
		bodyColor = Color3.fromRGB(230, 230, 240),
		minRodLevel = 3,
	},
	{
		id = "Koi",
		name = "Koi",
		baseValue = 55,
		baseSize = 1.2,
		bodyColor = Color3.fromRGB(230, 120, 90),
		minRodLevel = 4,
	},
}

function FishData.getById(speciesId: string)
	for _, species in FishData.Species do
		if species.id == speciesId then
			return species
		end
	end
	return nil
end

--- Deterministic "species of the day": the same species for every player on every server
-- for a given UTC day, changing at midnight UTC with zero authored content or stored state.
-- A cheap, free reason to fish something specific today vs. yesterday.
function FishData.getFeaturedSpeciesId(): string
	local dayIndex = math.floor(os.time() / 86400) % #FishData.Species
	return FishData.Species[dayIndex + 1].id
end

--- Rolls a species among those unlocked at the player's rod level. If featuredSpeciesId is
-- eligible, it gets Constants.FEATURED_SPECIES_WEIGHT_MULTIPLIER x the weight of every other
-- eligible species (still just a bias, never a guarantee or an exclusion of the rest).
function FishData.rollSpecies(rodLevel: number, featuredSpeciesId: string?): string
	local eligible = {}
	local totalWeight = 0
	for _, species in FishData.Species do
		if rodLevel >= species.minRodLevel then
			local weight = (species.id == featuredSpeciesId) and Constants.FEATURED_SPECIES_WEIGHT_MULTIPLIER or 1
			table.insert(eligible, { species = species, weight = weight })
			totalWeight += weight
		end
	end
	if #eligible == 0 then
		return FishData.Species[1].id
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in eligible do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.species.id
		end
	end
	return eligible[1].species.id
end

return FishData
