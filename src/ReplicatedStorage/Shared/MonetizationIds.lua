--- Single source of truth for Game Pass / Developer Product IDs, used by both the
-- server (MonetizationService, to grant) and the client (ShopController, to prompt
-- purchase). IDs are placeholders (0) until the user creates the real products in the
-- Creator Hub -- see docs/09_LAUNCH_CHECKLIST.md.
return {
	GamePasses = {
		AutoFisher = 0,
		DoubleCoins = 0,
		ExtraTankRoom = 0,
		VIPRod = 0,
	},
	DeveloperProducts = {
		CoinsSmall = 0,
		CoinsMedium = 0,
		CoinsLarge = 0,
		InstantGrowth = 0,
		RareBaitPack = 0,
	},
}
