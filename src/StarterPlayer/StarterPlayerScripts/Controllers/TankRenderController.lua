local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishModelFactory = require(ReplicatedStorage.Shared.FishModelFactory)

local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer

--- Renders the local player's fish as procedural Models swimming inside their personal
-- tank plot, kept in sync with ClientState (which mirrors the server's PlayerDataSync).
-- Purely cosmetic client-side rendering -- selling/growth/coins are all server-decided.
local TankRenderController = {}

local rendered = {} -- [uid] = { model, basePos, phase, lastGrowth }

local function waitForOwnPlot()
	local plotName = player:GetAttribute("TankPlotName")
	while not plotName do
		player:GetAttributeChangedSignal("TankPlotName"):Wait()
		plotName = player:GetAttribute("TankPlotName")
	end

	local plotsFolder = Workspace:WaitForChild("TankPlots")
	return plotsFolder:WaitForChild(plotName)
end

local function randomPositionInTank(tankPart)
	local size = tankPart.Size
	local margin = 1.2
	local x = (math.random() - 0.5) * math.max(size.X - margin * 2, 1)
	local y = (math.random() - 0.5) * math.max(size.Y - margin * 2, 1)
	local z = (math.random() - 0.5) * math.max(size.Z - margin * 2, 1)
	return tankPart.Position + Vector3.new(x, y, z)
end

function TankRenderController.init()
	local plot = waitForOwnPlot()
	local tankPart = plot:WaitForChild("TankPart")
	local fishContainer = plot:WaitForChild("FishContainer")

	local function refresh(fishList)
		local seen = {}

		for _, fishInfo in fishList do
			seen[fishInfo.uid] = true
			local entry = rendered[fishInfo.uid]

			if not entry then
				local model = FishModelFactory.build(fishInfo.speciesId, fishInfo.rarityId, fishInfo.sizeRoll)
				model.Parent = fishContainer
				local basePos = randomPositionInTank(tankPart)
				model:PivotTo(CFrame.new(basePos))

				local scale = 0.6 + 0.4 * fishInfo.growth
				pcall(function()
					model:ScaleTo(scale)
				end)

				rendered[fishInfo.uid] = {
					model = model,
					basePos = basePos,
					phase = math.random() * math.pi * 2,
					lastGrowth = fishInfo.growth,
				}
			elseif fishInfo.growth ~= entry.lastGrowth then
				entry.lastGrowth = fishInfo.growth
				local scale = 0.6 + 0.4 * fishInfo.growth
				pcall(function()
					entry.model:ScaleTo(scale)
				end)
			end
		end

		for uid, entry in rendered do
			if not seen[uid] then
				entry.model:Destroy()
				rendered[uid] = nil
			end
		end
	end

	refresh(ClientState.current.fish)
	ClientState.Changed.Event:Connect(function(data)
		refresh(data.fish)
	end)

	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for _, entry in rendered do
			local primaryPart = entry.model.PrimaryPart
			if primaryPart then
				local wobble = math.sin(t * 1.2 + entry.phase)
				local drift = Vector3.new(math.cos(t * 0.6 + entry.phase) * 1.2, wobble * 0.4, math.sin(t * 0.4 + entry.phase) * 1.2)
				local facing = CFrame.lookAt(entry.basePos + drift, entry.basePos + drift + Vector3.new(math.cos(t * 0.6 + entry.phase + 0.1), 0, math.sin(t * 0.4 + entry.phase + 0.1)))
				entry.model:PivotTo(facing)
			end
		end
	end)
end

return TankRenderController
