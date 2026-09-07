local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RarityConfig = require(ReplicatedStorage.Shared.RarityConfig)
local FishData = require(ReplicatedStorage.Shared.FishData)

local UIController = require(script.Parent.UIController)

--- Wires the physical cast prompt + the reel minigame UI to the CastRequest/ReelAttempt
-- remotes. All it ever tells the server is "cast" and "tapped now" -- rarity/species/size
-- are decided entirely server-side (see FishingService.lua).
local FishingController = {}

local isReeling = false
local reelTween: Tween? = nil

local function playCastStarted(remotes, ui, reelWindowSeconds: number)
	isReeling = true
	ui.reelFrame.Visible = true
	ui.tapButton.Visible = true
	ui.reelIndicator.Position = UDim2.new(0, 0, 0, 0)

	if reelTween then
		reelTween:Cancel()
	end
	reelTween = TweenService:Create(
		ui.reelIndicator,
		TweenInfo.new(reelWindowSeconds, Enum.EasingStyle.Linear),
		{ Position = UDim2.new(0.96, 0, 0, 0) }
	)
	reelTween:Play()
end

local function stopReeling(ui)
	isReeling = false
	ui.reelFrame.Visible = false
	ui.tapButton.Visible = false
	if reelTween then
		reelTween:Cancel()
		reelTween = nil
	end
end

function FishingController.init(remotes, ui)
	local castPrompt = Workspace:WaitForChild("CastSpot"):WaitForChild("CastPrompt")

	castPrompt.Triggered:Connect(function()
		remotes.CastRequest:FireServer()
	end)

	remotes.CastStarted.OnClientEvent:Connect(function(payload)
		playCastStarted(remotes, ui, payload.reelWindowSeconds)
	end)

	local function sendReelAttempt()
		if not isReeling then
			return
		end
		stopReeling(ui)
		remotes.ReelAttempt:FireServer()
	end

	ui.tapButton.MouseButton1Click:Connect(sendReelAttempt)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.Touch then
			sendReelAttempt()
		end
	end)

	remotes.CatchResult.OnClientEvent:Connect(function(payload)
		stopReeling(ui)

		if not payload.success then
			local text = payload.reason == "tank_full" and "Tank is full! Sell some fish." or "Missed it!"
			UIController.flashLabel(ui.catchLabel, text, 1.2)
			return
		end

		local species = FishData.getById(payload.fish.speciesId)
		local rarity = RarityConfig.getById(payload.fish.rarityId)
		ui.catchLabel.TextColor3 = rarity.color
		UIController.flashLabel(ui.catchLabel, ("Caught a %s %s!"):format(rarity.name, species.name), 1.8)
	end)

	remotes.RareCatchAnnouncement.OnClientEvent:Connect(function(payload)
		local species = FishData.getById(payload.speciesId)
		local rarity = RarityConfig.getById(payload.rarityId)
		UIController.slideInBanner(
			ui.rareBanner,
			("%s just caught a %s %s!"):format(payload.playerName, rarity.name, species.name)
		)
	end)
end

return FishingController
