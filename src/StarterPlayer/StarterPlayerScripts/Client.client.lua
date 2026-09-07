local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)

local Controllers = script.Parent.Controllers
local ClientState = require(Controllers.ClientState)
local UIController = require(Controllers.UIController)
local FishingController = require(Controllers.FishingController)
local TankRenderController = require(Controllers.TankRenderController)
local ShopController = require(Controllers.ShopController)
local InventoryController = require(Controllers.InventoryController)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local remotes = {}
for _, remoteName in RemoteNames do
	remotes[remoteName] = remotesFolder:WaitForChild(remoteName)
end

remotes[RemoteNames.PLAYER_DATA_SYNC].OnClientEvent:Connect(function(data)
	ClientState.set(data)
end)

local ui = UIController.init()

FishingController.init(remotes, ui)
TankRenderController.init()
ShopController.init(remotes, ui)
InventoryController.init(remotes, ui)

print("Fish Tank Simulator: client bootstrap complete.")
