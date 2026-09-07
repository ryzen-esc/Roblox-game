local Players = game:GetService("Players")

local Services = script.Parent.Services

local RemoteSetup = require(Services.RemoteSetup)
local RateLimiter = require(Services.RateLimiter)
local MapBuilderService = require(Services.MapBuilderService)
local PlayerDataService = require(Services.PlayerDataService)
local MonetizationService = require(Services.MonetizationService)
local FishingService = require(Services.FishingService)
local TankService = require(Services.TankService)
local ShopService = require(Services.ShopService)
local DailyRewardService = require(Services.DailyRewardService)
local AnnouncementService = require(Services.AnnouncementService)

-- Bootstrap order matters: remotes and the map must exist before any service that
-- references them; PlayerDataService before anything that reads/writes player data.
local remotes = RemoteSetup.init()
MapBuilderService.init()

local rateLimiter = RateLimiter.new()

PlayerDataService.init(remotes)
AnnouncementService.init(remotes)
MonetizationService.init()
FishingService.init(remotes, rateLimiter, AnnouncementService, MonetizationService)
TankService.init(remotes, rateLimiter, MonetizationService)
ShopService.init(remotes, rateLimiter)
DailyRewardService.init(remotes, rateLimiter)

Players.PlayerAdded:Connect(function(player)
	MapBuilderService.assignPlot(player)
end)

Players.PlayerRemoving:Connect(function(player)
	MapBuilderService.releasePlot(player)
end)

print("Fish Tank Simulator: server bootstrap complete.")
