local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationIds = require(ReplicatedStorage.Shared.MonetizationIds)
local PlayerDataService = require(script.Parent.PlayerDataService)

--- Game Pass ownership caching + Developer Product receipt processing. The server is the
-- sole authority for granting anything -- purchases are *initiated* client-side via
-- Roblox's own MarketplaceService APIs (no custom remote needed for that), but every
-- grant happens here after Roblox itself confirms the purchase.
--
-- IDs live in ReplicatedStorage/Shared/MonetizationIds.lua (shared with the client Shop
-- UI). They are placeholders (0) until the user creates the real Game Passes and
-- Developer Products in the Creator Hub -- see docs/09_LAUNCH_CHECKLIST.md.
local MonetizationService = {}

MonetizationService.GamePasses = MonetizationIds.GamePasses
MonetizationService.DeveloperProducts = MonetizationIds.DeveloperProducts

local DEV_PRODUCT_COIN_AMOUNTS = {
	CoinsSmall = 500,
	CoinsMedium = 1500,
	CoinsLarge = 4000,
}

local ownedPasses = {} -- [userId] = { [passName] = true }
local analyticsService = nil

local function productNameFromId(productId: number): string?
	for name, id in MonetizationService.DeveloperProducts do
		if id == productId and id ~= 0 then
			return name
		end
	end
	return nil
end

local function refreshOwnedPasses(player: Player)
	local owned = {}
	for name, passId in MonetizationService.GamePasses do
		if passId ~= 0 then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			owned[name] = ok and result or false
		end
	end
	ownedPasses[player.UserId] = owned
end

function MonetizationService.ownsPass(player: Player, passName: string): boolean
	local owned = ownedPasses[player.UserId]
	return owned ~= nil and owned[passName] == true
end

function MonetizationService.getCoinMultiplier(player: Player): number
	return MonetizationService.ownsPass(player, "DoubleCoins") and 2 or 1
end

function MonetizationService.getExtraTankCapacity(player: Player): number
	return MonetizationService.ownsPass(player, "ExtraTankRoom") and 6 or 0
end

function MonetizationService.getReelWindowBonus(player: Player): number
	return MonetizationService.ownsPass(player, "VIPRod") and 0.3 or 0
end

local function onPromptGamePassPurchaseFinished(player: Player, _passId: number, wasPurchased: boolean)
	if wasPurchased then
		refreshOwnedPasses(player)
	end
end

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = PlayerDataService.get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Idempotency: Roblox may re-fire the same receipt if the server didn't confirm in time.
	if data.processedReceipts[receiptInfo.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local productName = productNameFromId(receiptInfo.ProductId)
	if not productName then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if DEV_PRODUCT_COIN_AMOUNTS[productName] then
		local amount = DEV_PRODUCT_COIN_AMOUNTS[productName]
		data.coins += amount
		if analyticsService then
			analyticsService.logEconomy(player, true, "Coins", amount, data.coins, "IAP", productName)
		end
	elseif productName == "InstantGrowth" then
		for _, fish in data.fish do
			if fish.growth < 1 then
				fish.growth = 1
				break -- matures one fish, matching the product's description
			end
		end
	elseif productName == "RareBaitPack" then
		-- Extends (not stacks past) a 30-minute rare-odds boost window. FishingService
		-- checks rareBaitBoostExpiresUnix against os.time() -- server clock only.
		data.rareBaitBoostExpiresUnix = math.max(data.rareBaitBoostExpiresUnix, os.time()) + (30 * 60)
	end

	data.processedReceipts[receiptInfo.PurchaseId] = true
	PlayerDataService.sync(player)

	-- Force an immediate (synchronous, yielding) save here rather than waiting for the
	-- periodic autosave. ProcessReceipt is allowed to yield, and Roblox will retry this
	-- receipt if we don't return PurchaseGranted -- so we must durably persist the grant
	-- *before* returning it, or a server crash between granting and the next autosave
	-- would silently lose a paid purchase.
	PlayerDataService.save(player)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.init(analyticsServiceModule)
	analyticsService = analyticsServiceModule
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPromptGamePassPurchaseFinished)
	MarketplaceService.ProcessReceipt = processReceipt

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local waited = 0
			while not PlayerDataService.isLoaded(player) and waited < 30 do
				task.wait(0.5)
				waited += 0.5
			end
			if PlayerDataService.isLoaded(player) then
				refreshOwnedPasses(player)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ownedPasses[player.UserId] = nil
	end)
end

return MonetizationService
