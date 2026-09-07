local FishData = require(script.Parent.FishData)
local RarityConfig = require(script.Parent.RarityConfig)

--- Builds a small, deliberately-simple "low-poly toy" fish Model out of plain BaseParts.
-- No imported meshes or uploaded assets are needed for the MVP -- this keeps the whole
-- game buildable and testable without a Studio asset-upload/moderation step.
local FishModelFactory = {}

local function blendColor(a: Color3, b: Color3, t: number): Color3
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

--- @param speciesId string
-- @param rarityId string
-- @param sizeRoll number -- 0..1 random roll, blended into the final scale for size variety
function FishModelFactory.build(speciesId: string, rarityId: string, sizeRoll: number)
	local species = FishData.getById(speciesId)
	local rarity = RarityConfig.getById(rarityId)
	assert(species, "Unknown species: " .. tostring(speciesId))
	assert(rarity, "Unknown rarity: " .. tostring(rarityId))

	local scale = species.baseSize * rarity.sizeMultiplier * (0.85 + sizeRoll * 0.3)
	local color = rarity.id == "Common" and species.bodyColor or blendColor(species.bodyColor, rarity.color, 0.45)

	local model = Instance.new("Model")
	model.Name = species.name .. "_" .. rarity.id

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(1.6 * scale, 1 * scale, 1 * scale)
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.Parent = model

	local tail = Instance.new("WedgePart")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.5 * scale, 0.7 * scale, 0.9 * scale)
	tail.Color = color
	tail.Material = Enum.Material.SmoothPlastic
	tail.Anchored = true
	tail.CanCollide = false
	tail.CanQuery = false
	tail.CFrame = body.CFrame * CFrame.new(-0.9 * scale, 0, 0) * CFrame.Angles(0, math.rad(180), 0)
	tail.Parent = model

	local dorsalFin = Instance.new("WedgePart")
	dorsalFin.Name = "DorsalFin"
	dorsalFin.Size = Vector3.new(0.35 * scale, 0.35 * scale, 0.15 * scale)
	dorsalFin.Color = color
	dorsalFin.Material = Enum.Material.SmoothPlastic
	dorsalFin.Anchored = true
	dorsalFin.CanCollide = false
	dorsalFin.CanQuery = false
	dorsalFin.CFrame = body.CFrame * CFrame.new(0, 0.55 * scale, 0) * CFrame.Angles(0, 0, math.rad(90))
	dorsalFin.Parent = model

	if rarity.hasParticles then
		local attachment = Instance.new("Attachment")
		attachment.Parent = body

		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(rarity.color)
		sparkle.Size = NumberSequence.new(0.15 * scale)
		sparkle.Lifetime = NumberRange.new(0.6, 1.1)
		sparkle.Rate = 6
		sparkle.Speed = NumberRange.new(0.5, 1)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = attachment
	end

	model.PrimaryPart = body
	return model
end

return FishModelFactory
