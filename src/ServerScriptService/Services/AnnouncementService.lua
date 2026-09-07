local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)

--- Server-wide broadcast when any player catches an Epic/Legendary fish. This is the
-- game's main organic-virality moment: it pulls other players on the server toward the
-- dock and plants a chase hook for the catcher's next session.
local AnnouncementService = {}

local remotes = nil

function AnnouncementService.announceRareCatch(player: Player, speciesId: string, rarityId: string)
	if not remotes then
		return
	end
	remotes[RemoteNames.RARE_CATCH_ANNOUNCEMENT]:FireAllClients({
		playerName = player.Name,
		speciesId = speciesId,
		rarityId = rarityId,
	})
end

function AnnouncementService.init(remotesTable)
	remotes = remotesTable
end

return AnnouncementService
