local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)

--- Creates ReplicatedStorage.Remotes and one RemoteEvent per name in RemoteNames.
-- Must run before any other service that touches remotes.
local RemoteSetup = {}

function RemoteSetup.init()
	local remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage

	local remotes = {}
	for _, remoteName in RemoteNames do
		local event = Instance.new("RemoteEvent")
		event.Name = remoteName
		event.Parent = remotesFolder
		remotes[remoteName] = event
	end

	return remotes
end

return RemoteSetup
