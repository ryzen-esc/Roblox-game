local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)

local PlayerDataService = require(script.Parent.PlayerDataService)

--- Rod/Tank/Bait upgrade purchases (Coins only). The client sends only which track to
-- upgrade -- the server always recomputes the cost from the player's authoritative
-- current level, never from anything the client claims the price is.
local ShopService = {}

local TRACK_TO_FIELD = {
	Rod = "rodLevel",
	Tank = "tankLevel",
	Bait = "baitLevel",
}

local remotes = nil
local rateLimiter = nil

local function onBuyUpgradeRequest(player: Player, payload)
	if not rateLimiter:allow(player, "buyUpgrade", 0.2) then
		return
	end
	if type(payload) ~= "table" or type(payload.track) ~= "string" then
		return
	end

	local field = TRACK_TO_FIELD[payload.track]
	if not field then
		return
	end

	local data = PlayerDataService.get(player)
	if not data then
		return
	end

	local currentLevel = data[field]
	local cost = UpgradeConfig.getUpgradeCost(payload.track, currentLevel)
	if not cost then
		return -- maxed out or invalid track
	end
	if data.coins < cost then
		return -- not enough Coins; client should already reflect this, silently no-op
	end

	data.coins -= cost
	data[field] = currentLevel + 1

	PlayerDataService.sync(player)
end

function ShopService.init(remotesTable, rateLimiterInstance)
	remotes = remotesTable
	rateLimiter = rateLimiterInstance

	remotes[RemoteNames.BUY_UPGRADE_REQUEST].OnServerEvent:Connect(onBuyUpgradeRequest)
end

return ShopService
