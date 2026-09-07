local Players = game:GetService("Players")

local Services = script.Parent.Services

local RemoteSetup = require(Services.RemoteSetup)
local RateLimiter = require(Services.RateLimiter)
local MapBuilderService = require(Services.MapBuilderService)
local PlayerDataService = require(Services.PlayerDataService)
local GameAnalyticsService = require(Services.GameAnalyticsService)
local MonetizationService = require(Services.MonetizationService)
local AchievementService = require(Services.AchievementService)
local FishingService = require(Services.FishingService)
local TankService = require(Services.TankService)
local ShopService = require(Services.ShopService)
local DailyRewardService = require(Services.DailyRewardService)
local AnnouncementService = require(Services.AnnouncementService)
local RebirthService = require(Services.RebirthService)

-- Bootstrap order matters: remotes and the map must exist before any service that
-- references them; PlayerDataService before anything that reads/writes player data.
local remotes = RemoteSetup.init()
MapBuilderService.init()

local rateLimiter = RateLimiter.new()

PlayerDataService.init(remotes, GameAnalyticsService)
AnnouncementService.init(remotes)
MonetizationService.init(GameAnalyticsService)
AchievementService.init(remotes)
FishingService.init(remotes, rateLimiter, AnnouncementService, MonetizationService, AchievementService, GameAnalyticsService)
TankService.init(remotes, rateLimiter, MonetizationService, AchievementService, GameAnalyticsService)
ShopService.init(remotes, rateLimiter, AchievementService, GameAnalyticsService)
DailyRewardService.init(remotes, rateLimiter, GameAnalyticsService)
RebirthService.init(remotes, rateLimiter, AchievementService, GameAnalyticsService)

Players.PlayerAdded:Connect(function(player)
	MapBuilderService.assignPlot(player)
end)

Players.PlayerRemoving:Connect(function(player)
	MapBuilderService.releasePlot(player)
end)

print("Fish Tank Simulator: server bootstrap complete.")
