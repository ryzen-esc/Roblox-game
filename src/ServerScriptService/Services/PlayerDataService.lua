local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)

--- Owns the authoritative per-player data table, DataStore load/save with retry, and
-- offline-growth calculation. Every other service reads/writes through this module --
-- nothing else touches DataStoreService directly.
local PlayerDataService = {}

local dataStore = DataStoreService:GetDataStore("PlayerData_v1")
local backupDataStore = DataStoreService:GetDataStore("PlayerDataBackup_v1")
local sessions = {} -- [userId] = { data = {...}, loaded = bool }
local remotes = nil
local analyticsService = nil

local function defaultData()
	return {
		coins = 0,
		rodLevel = 1,
		tankLevel = 1,
		baitLevel = 1,
		rebirths = 0,
		fish = {}, -- [fishUid] = { speciesId, rarityId, sizeRoll, growth, caughtAt }
		nextFishUid = 1,
		dailyStreak = { lastClaimUnix = 0, streakCount = 0 },
		achievements = {},
		processedReceipts = {},
		rareBaitBoostExpiresUnix = 0,
		lastSaveUnix = os.time(),
		totalFishCaught = 0,
		rarityCatchCounts = {},
		lifetimeCoinsEarned = 0,
		analyticsFunnelLogged = {},
	}
end

--- Fills in any fields missing from an older save (schema migration safety net).
local function withDefaults(data)
	local defaults = defaultData()
	for key, value in defaults do
		if data[key] == nil then
			data[key] = value
		end
	end
	return data
end

local function applyOfflineGrowth(data)
	local now = os.time()
	local elapsed = math.clamp(now - (data.lastSaveUnix or now), 0, Constants.OFFLINE_GROWTH_CAP_SECONDS)
	if elapsed <= 0 then
		return
	end

	local growthDelta = elapsed / Constants.GROWTH_TIME_SECONDS
	for _, fish in data.fish do
		fish.growth = math.clamp(fish.growth + growthDelta, 0, 1)
	end
end

--- Best-effort secondary copy of a player's data, written after every successful primary
-- save. If the primary save is ever corrupted or unrecoverable (DataStore incidents do
-- happen), this is the recovery path -- loaded only when the primary load exhausts all its
-- retries. Fire-and-forget: a failed backup write just means the next successful save tries
-- again a couple minutes later at the next autosave; it never blocks or fails the real save.
local function backupSave(userId: number, data)
	task.spawn(function()
		pcall(function()
			backupDataStore:SetAsync("Player_" .. userId, data)
		end)
	end)
end

local function backupLoad(userId: number)
	local ok, result = pcall(function()
		return backupDataStore:GetAsync("Player_" .. userId)
	end)
	return ok and result or nil
end

local function loadWithRetry(userId: number)
	local attempt = 0
	while attempt < Constants.DATASTORE_MAX_RETRIES do
		attempt += 1
		local ok, result = pcall(function()
			return dataStore:GetAsync("Player_" .. userId)
		end)

		if ok then
			return result
		end

		warn(("PlayerDataService: load attempt %d failed for %d: %s"):format(attempt, userId, tostring(result)))
		if attempt < Constants.DATASTORE_MAX_RETRIES then
			task.wait(Constants.DATASTORE_RETRY_BASE_SECONDS * (2 ^ (attempt - 1)))
		end
	end
	return nil, "max retries exceeded"
end

local function saveWithRetry(userId: number, data, maxRetries: number?)
	local attempt = 0
	local retries = maxRetries or Constants.DATASTORE_MAX_RETRIES
	while attempt < retries do
		attempt += 1
		local ok, err = pcall(function()
			dataStore:UpdateAsync("Player_" .. userId, function(_old)
				return data
			end)
		end)

		if ok then
			backupSave(userId, data)
			return true
		end

		warn(("PlayerDataService: save attempt %d failed for %d: %s"):format(attempt, userId, tostring(err)))
		if attempt < retries then
			task.wait(Constants.DATASTORE_RETRY_BASE_SECONDS * (2 ^ (attempt - 1)))
		end
	end
	return false
end

function PlayerDataService.load(player: Player)
	local raw = loadWithRetry(player.UserId)
	if not raw then
		local backup = backupLoad(player.UserId)
		if backup then
			warn("PlayerDataService: primary load failed for", player.UserId, "- recovered from backup")
			raw = backup
		end
	end
	local data = raw and withDefaults(raw) or defaultData()

	applyOfflineGrowth(data)
	data.lastSaveUnix = os.time()

	sessions[player.UserId] = { data = data, loaded = true }
	PlayerDataService.sync(player)

	if analyticsService then
		analyticsService.logFunnelStepOnce(player, data, "Joined")
	end
end

function PlayerDataService.isLoaded(player: Player): boolean
	local session = sessions[player.UserId]
	return session ~= nil and session.loaded == true
end

--- Returns the authoritative mutable data table for a player. Never trust anything the
-- client sends in place of reading this.
function PlayerDataService.get(player: Player)
	local session = sessions[player.UserId]
	return session and session.data or nil
end

function PlayerDataService.save(player: Player)
	local session = sessions[player.UserId]
	if not session or not session.loaded then
		return
	end
	session.data.lastSaveUnix = os.time()
	saveWithRetry(player.UserId, session.data)
end

--- Used only from game:BindToClose. Roblox gives shutdown a limited time budget across
-- *all* players, so this uses far fewer retries/backoff than a normal save -- better to
-- get most players saved once than to exhaust the shutdown budget retrying one player.
function PlayerDataService.saveForShutdown(player: Player)
	local session = sessions[player.UserId]
	if not session or not session.loaded then
		return
	end
	session.data.lastSaveUnix = os.time()
	saveWithRetry(player.UserId, session.data, 2)
end

function PlayerDataService.release(player: Player)
	PlayerDataService.save(player)
	sessions[player.UserId] = nil
end

--- Serializes and pushes the player's current state to their own client.
function PlayerDataService.sync(player: Player)
	local data = PlayerDataService.get(player)
	if not data or not remotes then
		return
	end

	local fishList = {}
	for uid, fish in data.fish do
		table.insert(fishList, {
			uid = uid,
			speciesId = fish.speciesId,
			rarityId = fish.rarityId,
			sizeRoll = fish.sizeRoll,
			growth = fish.growth,
		})
	end

	remotes[RemoteNames.PLAYER_DATA_SYNC]:FireClient(player, {
		coins = data.coins,
		rodLevel = data.rodLevel,
		tankLevel = data.tankLevel,
		baitLevel = data.baitLevel,
		rebirths = data.rebirths,
		fish = fishList,
		dailyStreak = data.dailyStreak,
		achievements = data.achievements,
		totalFishCaught = data.totalFishCaught,
	})
end

function PlayerDataService.init(remotesTable, analyticsServiceModule)
	remotes = remotesTable
	analyticsService = analyticsServiceModule

	Players.PlayerAdded:Connect(function(player)
		PlayerDataService.load(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerDataService.release(player)
	end)

	task.spawn(function()
		while true do
			task.wait(Constants.AUTOSAVE_INTERVAL_SECONDS)
			for _, player in Players:GetPlayers() do
				PlayerDataService.save(player)
			end
		end
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			PlayerDataService.saveForShutdown(player)
		end
	end)
end

return PlayerDataService
