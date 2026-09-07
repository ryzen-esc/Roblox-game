local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local AchievementConfig = require(ReplicatedStorage.Shared.AchievementConfig)

--- Checks a player's authoritative data against every achievement definition and grants
-- any newly-met ones (Coins + an optional Roblox Badge). Purely server-driven: `data` is
-- always the server's own PlayerDataService table, never anything the client sends.
local AchievementService = {}

local remotes = nil

--- Call after any mutation that could complete an achievement (catch, sell, upgrade,
-- rebirth). Cheap: iterating ~13 pure boolean checks over already-in-memory data.
function AchievementService.checkAll(player: Player, data)
	data.achievements = data.achievements or {}

	for _, achievement in AchievementConfig.List do
		if not data.achievements[achievement.id] and achievement.check(data) then
			data.achievements[achievement.id] = true
			data.coins += achievement.coinReward

			if remotes then
				remotes[RemoteNames.ACHIEVEMENT_UNLOCKED]:FireClient(player, {
					id = achievement.id,
					name = achievement.name,
					coinReward = achievement.coinReward,
				})
			end

			if achievement.badgeId and achievement.badgeId ~= 0 then
				task.spawn(function()
					pcall(function()
						BadgeService:AwardBadge(player.UserId, achievement.badgeId)
					end)
				end)
			end
		end
	end
end

function AchievementService.init(remotesTable)
	remotes = remotesTable
end

return AchievementService
