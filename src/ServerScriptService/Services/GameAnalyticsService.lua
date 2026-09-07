local AnalyticsServiceInstance = game:GetService("AnalyticsService")

--- Thin wrapper around Roblox's free, first-party AnalyticsService (onboarding funnel +
-- economy events). Every call is wrapped in pcall: Roblox only accepts these calls from a
-- published, live server (not Studio, not the client), and analytics must never be able to
-- break actual gameplay if a call is rejected or the API changes.
--
-- Funnel steps are logged at most once per player, ever (persisted in save data), so
-- replaying the same session/rejoining doesn't pollute the funnel with repeat "first cast"
-- events from returning players.
local GameAnalyticsService = {}

GameAnalyticsService.FunnelSteps = {
	{ step = 1, name = "Joined" },
	{ step = 2, name = "FirstCast" },
	{ step = 3, name = "FirstCatch" },
	{ step = 4, name = "FirstSell" },
	{ step = 5, name = "FirstUpgrade" },
}

local function safeCall(fn)
	local ok, err = pcall(fn)
	if not ok then
		warn("GameAnalyticsService: call failed:", err)
	end
end

--- Logs a named onboarding funnel step for a player exactly once (ever), using
-- data.analyticsFunnelLogged (a persisted set of step numbers) to dedupe across sessions.
function GameAnalyticsService.logFunnelStepOnce(player: Player, data, stepKey: string)
	local stepInfo
	for _, info in GameAnalyticsService.FunnelSteps do
		if info.name == stepKey then
			stepInfo = info
			break
		end
	end
	if not stepInfo then
		return
	end

	data.analyticsFunnelLogged = data.analyticsFunnelLogged or {}
	if data.analyticsFunnelLogged[stepInfo.name] then
		return
	end
	data.analyticsFunnelLogged[stepInfo.name] = true

	safeCall(function()
		AnalyticsServiceInstance:LogOnboardingFunnelStepEvent(player, stepInfo.step, stepInfo.name)
	end)
end

--- isSource: true for currency gained (selling, rewards, IAP), false for currency spent.
-- transactionType should be one of: "IAP", "TimedReward", "Onboarding", "Shop", "Gameplay",
-- "ContextualPurchase" (Roblox's AnalyticsEconomyTransactionType names, passed as strings
-- per the actual LogEconomyEvent signature).
function GameAnalyticsService.logEconomy(
	player: Player,
	isSource: boolean,
	currencyType: string,
	amount: number,
	endingBalance: number,
	transactionType: string,
	itemSku: string?
)
	if amount <= 0 then
		return -- LogEconomyEvent requires a positive amount regardless of flow direction
	end
	safeCall(function()
		AnalyticsServiceInstance:LogEconomyEvent(
			player,
			isSource and Enum.AnalyticsEconomyFlowType.Source or Enum.AnalyticsEconomyFlowType.Sink,
			currencyType,
			amount,
			endingBalance,
			transactionType,
			itemSku or ""
		)
	end)
end

return GameAnalyticsService
