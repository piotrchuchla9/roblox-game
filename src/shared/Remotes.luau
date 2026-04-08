local Remotes = {
	-- Server -> Client
	UpdatePlayerData = "UpdatePlayerData",
	PlayDropAnimation = "PlayDropAnimation",
	PlotAllocated = "PlotAllocated",
	PlotReleased = "PlotReleased",
	TradeRequest = "TradeRequest",
	TradeUpdate = "TradeUpdate",
	OpenShop = "OpenShop",
	OpenDecoShop = "OpenDecoShop",

	-- Client -> Server
	PlantSeed = "PlantSeed",
	WaterBed = "WaterBed",
	HarvestBed = "HarvestBed",
	SellBrainrot = "SellBrainrot",
	ClaimDailyReward = "ClaimDailyReward",
	UpgradeGarden = "UpgradeGarden",
	ClaimFreeSeed = "ClaimFreeSeed",

	-- Social (Client -> Server)
	SearchPlayer = "SearchPlayer",
	TeleportToPlayer = "TeleportToPlayer",
	TeleportHome = "TeleportHome",
	InitiateTrade = "InitiateTrade",
	UpdateTradeOffer = "UpdateTradeOffer",
	ConfirmTrade = "ConfirmTrade",
	CancelTrade = "CancelTrade",
	LikeGarden = "LikeGarden",
	BuyDeco = "BuyDeco",
}

return Remotes
