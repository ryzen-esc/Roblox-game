local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AchievementConfig = require(ReplicatedStorage.Shared.AchievementConfig)
local FishData = require(ReplicatedStorage.Shared.FishData)

local UIController = require(script.Parent.UIController)
local ClientState = require(script.Parent.ClientState)

--- Renders the Achievements panel (from the shared AchievementConfig list + ClientState's
-- mirrored `achievements` set) and shows a toast when the server grants a new one. Purely
-- cosmetic/display -- achievements are only ever granted server-side (AchievementService).
local AchievementController = {}

local function newAchvRow(parent, order, achievement, earned: boolean)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = earned and Color3.fromRGB(45, 70, 55) or Color3.fromRGB(45, 45, 58)
	row.LayoutOrder = order
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.85, 0, 1, 0)
	label.Position = UDim2.new(0.02, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = earned and Color3.fromRGB(140, 230, 170) or Color3.fromRGB(200, 200, 210)
	label.Font = Enum.Font.Gotham
	label.TextScaled = true
	label.Text = ("%s %s - %s (+%d Coins)"):format(
		earned and "[x]" or "[ ]",
		achievement.name,
		achievement.description,
		achievement.coinReward
	)
	label.Parent = row

	return row
end

function AchievementController.init(remotes, ui)
	local function refreshList()
		for _, child in ui.achvList:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local earnedSet = ClientState.current.achievements or {}
		local order = 0
		for _, achievement in AchievementConfig.List do
			order += 1
			newAchvRow(ui.achvList, order, achievement, earnedSet[achievement.id] == true)
		end
	end

	local function refreshFeatured()
		local species = FishData.getById(FishData.getFeaturedSpeciesId())
		if species then
			ui.featuredLabel.Text = ("Today's Catch: %s (2x common)"):format(species.name)
		end
	end

	remotes.AchievementUnlocked.OnClientEvent:Connect(function(payload)
		UIController.slideInBanner(
			ui.achievementBanner,
			("Achievement Unlocked: %s (+%d Coins)"):format(payload.name, payload.coinReward),
			0.16
		)
	end)

	ClientState.Changed.Event:Connect(refreshList)
	refreshList()
	refreshFeatured()
end

return AchievementController
