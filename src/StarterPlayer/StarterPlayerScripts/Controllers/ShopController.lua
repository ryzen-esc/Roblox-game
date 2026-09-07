local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)
local MonetizationIds = require(ReplicatedStorage.Shared.MonetizationIds)

local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer

--- Builds the Shop panel's rows (Coin upgrades + Game Passes + Developer Products) and
-- wires their buttons. Coin upgrade costs are computed from the same UpgradeConfig the
-- server uses, purely for display -- the server always recomputes the real cost itself
-- and this display can never cause an incorrect charge.
local ShopController = {}

local UPGRADE_TRACKS = { "Rod", "Tank", "Bait" }
local UPGRADE_FIELD = { Rod = "rodLevel", Tank = "tankLevel", Bait = "baitLevel" }

local GAME_PASS_INFO = {
	{ key = "AutoFisher", label = "Auto-Fisher", desc = "Casts and reels automatically." },
	{ key = "DoubleCoins", label = "2x Coins", desc = "Doubles Coins from selling fish." },
	{ key = "ExtraTankRoom", label = "Extra Tank Room", desc = "+6 tank slots." },
	{ key = "VIPRod", label = "VIP Rod", desc = "Wider reel timing window." },
}

local PRODUCT_INFO = {
	{ key = "CoinsSmall", label = "500 Coins" },
	{ key = "CoinsMedium", label = "1,500 Coins" },
	{ key = "CoinsLarge", label = "4,000 Coins" },
	{ key = "InstantGrowth", label = "Instant Growth Potion" },
	{ key = "RareBaitPack", label = "Rare Bait (30 min)" },
}

local function newRow(parent, order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 60)
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
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.Gotham
	label.TextScaled = true
	label.Parent = row

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.3, 0, 0.7, 0)
	button.Position = UDim2.new(0.98, 0, 0.5, 0)
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.BackgroundColor3 = Color3.fromRGB(90, 190, 110)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button

	return row, label, button
end

function ShopController.init(remotes, ui)
	local order = 0
	local upgradeLabels = {}

	for _, track in UPGRADE_TRACKS do
		order += 1
		local _row, label, button = newRow(ui.shopList, order)
		upgradeLabels[track] = label

		button.Text = "Buy"
		button.MouseButton1Click:Connect(function()
			remotes.BuyUpgradeRequest:FireServer({ track = track })
		end)
	end

	local function refreshUpgradeLabels()
		local data = ClientState.current
		for _, track in UPGRADE_TRACKS do
			local level = data[UPGRADE_FIELD[track]]
			local cost = UpgradeConfig.getUpgradeCost(track, level)
			local label = upgradeLabels[track]
			if cost then
				label.Text = ("%s Lv.%d -> Lv.%d  (%d Coins)"):format(track, level, level + 1, cost)
			else
				label.Text = ("%s Lv.%d (MAX)"):format(track, level)
			end
		end
	end

	for _, info in GAME_PASS_INFO do
		order += 1
		local _row, label, button = newRow(ui.shopList, order)
		label.Text = ("%s - %s"):format(info.label, info.desc)
		button.Text = "Get"
		button.BackgroundColor3 = Color3.fromRGB(60, 140, 220)
		button.MouseButton1Click:Connect(function()
			local passId = MonetizationIds.GamePasses[info.key]
			if passId and passId ~= 0 then
				MarketplaceService:PromptGamePassPurchase(player, passId)
			end
		end)
	end

	for _, info in PRODUCT_INFO do
		order += 1
		local _row, label, button = newRow(ui.shopList, order)
		label.Text = info.label
		button.Text = "Buy"
		button.BackgroundColor3 = Color3.fromRGB(230, 150, 60)
		button.MouseButton1Click:Connect(function()
			local productId = MonetizationIds.DeveloperProducts[info.key]
			if productId and productId ~= 0 then
				MarketplaceService:PromptProductPurchase(player, productId)
			end
		end)
	end

	refreshUpgradeLabels()
	ClientState.Changed.Event:Connect(refreshUpgradeLabels)
end

return ShopController
