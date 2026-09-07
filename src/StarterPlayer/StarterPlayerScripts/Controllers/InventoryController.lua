local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishData = require(ReplicatedStorage.Shared.FishData)
local RarityConfig = require(ReplicatedStorage.Shared.RarityConfig)
local Constants = require(ReplicatedStorage.Shared.Constants)

local ClientState = require(script.Parent.ClientState)

--- Wires the HUD Coins label, the Tank/Inventory sell list, and the Daily Reward popup.
-- All of these only ever read ClientState (server-mirrored) and fire the corresponding
-- *Request remote -- they never assume a purchase/sale succeeded until the next sync.
local InventoryController = {}

local function newFishRow(parent, order, fishInfo)
	local species = FishData.getById(fishInfo.speciesId)
	local rarity = RarityConfig.getById(fishInfo.rarityId)

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
	row.LayoutOrder = order
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.65, 0, 1, 0)
	label.Position = UDim2.new(0.02, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = rarity.color
	label.Font = Enum.Font.Gotham
	label.TextScaled = true
	label.Text = ("%s %s (%d%% grown)"):format(rarity.name, species.name, math.floor(fishInfo.growth * 100))
	label.Parent = row

	local sellButton = Instance.new("TextButton")
	sellButton.Size = UDim2.new(0.3, 0, 0.7, 0)
	sellButton.Position = UDim2.new(0.98, 0, 0.5, 0)
	sellButton.AnchorPoint = Vector2.new(1, 0.5)
	sellButton.Text = "Sell"
	sellButton.Font = Enum.Font.GothamBold
	sellButton.TextScaled = true
	sellButton.BackgroundColor3 = Color3.fromRGB(90, 190, 110)
	sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	sellButton.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = sellButton

	return sellButton
end

function InventoryController.init(remotes, ui)
	local function refreshCoins()
		ui.coinsLabel.Text = ("Coins: %d"):format(ClientState.current.coins)
	end

	local function refreshInventory()
		for _, child in ui.tankList:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local order = 0
		for _, fishInfo in ClientState.current.fish do
			order += 1
			local sellButton = newFishRow(ui.tankList, order, fishInfo)
			sellButton.MouseButton1Click:Connect(function()
				remotes.SellFishRequest:FireServer({ uid = fishInfo.uid })
			end)
		end
	end

	local function refreshDailyReward()
		local streak = ClientState.current.dailyStreak
		local hoursSince = (os.time() - streak.lastClaimUnix) / 3600
		ui.dailyFrame.Visible = streak.lastClaimUnix == 0 or hoursSince >= Constants.DAILY_RESET_HOURS
	end

	ClientState.Changed.Event:Connect(function()
		refreshCoins()
		refreshInventory()
		refreshDailyReward()
	end)

	ui.sellAllButton.MouseButton1Click:Connect(function()
		remotes.SellFishRequest:FireServer({ all = true })
	end)

	ui.claimButton.MouseButton1Click:Connect(function()
		remotes.ClaimDailyRewardRequest:FireServer()
	end)

	refreshCoins()
	refreshInventory()
	refreshDailyReward()
end

return InventoryController
