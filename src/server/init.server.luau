local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDatabase = require(ReplicatedStorage.Shared.BrainrotDatabase)

-- Create RemoteEvents
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

for _, remoteName in Remotes do
	local remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = remotesFolder
end

-- Load managers
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local GardenManager = require(script.Parent.GardenManager)
local DropSystem = require(script.Parent.DropSystem)
local MonetizationManager = require(script.Parent.MonetizationManager)
local DailyRewardManager = require(script.Parent.DailyRewardManager)
local MapSetup = require(script.Parent.MapSetup)
local PlotManager = require(script.Parent.PlotManager)
local TeleportManager = require(script.Parent.TeleportManager)
local TradeManager = require(script.Parent.TradeManager)

MonetizationManager.init()
TeleportManager.init()
task.spawn(function()
	MapSetup.build()
	print("[Server] Map built")
end)

-- Helper: send updated data to client
local function syncData(player: Player)
	local data = PlayerDataManager.getData(player)
	if data then
		remotesFolder.UpdatePlayerData:FireClient(player, data)
	end
end

-- Helper: create leaderstats for player
local function createLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local collection = Instance.new("IntValue")
	collection.Name = "Collection"
	collection.Value = 0
	collection.Parent = leaderstats
end

-- Helper: update leaderstats from data
local function updateLeaderstats(player: Player, data: any)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local collection = leaderstats:FindFirstChild("Collection")
		if collection then
			collection.Value = data.collectionCount or 0
		end
	end
end

-- Player join
Players.PlayerAdded:Connect(function(player)
	createLeaderstats(player)
	task.wait(1)
	local data = PlayerDataManager.getData(player)
	if data then
		updateLeaderstats(player, data)
		syncData(player)

		-- Allocate garden plot
		PlotManager.allocate(player, data)
		remotesFolder.PlotAllocated:FireClient(player, PlotManager.getSlotIndex(player))
	end
end)

Players.PlayerRemoving:Connect(function(player)
	PlotManager.release(player)
end)

-- Plant seed
remotesFolder.PlantSeed.OnServerEvent:Connect(function(player, bedIndex: number, rarity: string)
	local data = PlayerDataManager.getData(player)
	if not data then return end
	if rarity ~= "Common" then return end -- MVP: only free Common seeds

	if GardenManager.plantSeed(data, bedIndex, rarity) then
		syncData(player)
	end
end)

-- Water bed
remotesFolder.WaterBed.OnServerEvent:Connect(function(player, bedIndex: number)
	local data = PlayerDataManager.getData(player)
	if not data then return end

	if GardenManager.waterBed(data, bedIndex) then
		syncData(player)
	end
end)

-- Harvest bed
remotesFolder.HarvestBed.OnServerEvent:Connect(function(player, bedIndex: number)
	local data = PlayerDataManager.getData(player)
	if not data then return end

	local hasLucky = MonetizationManager.hasGamepass(player, "LUCKY_GARDENER")
	local brainrot = GardenManager.harvestBed(data, bedIndex, hasLucky)

	if brainrot then
		updateLeaderstats(player, data)
		syncData(player)

		local isRare = brainrot.rarity == "Legendary" or brainrot.rarity == "Mythic"
		remotesFolder.PlayDropAnimation:FireClient(player, brainrot, isRare)
	end
end)

-- Sell brainrot
remotesFolder.SellBrainrot.OnServerEvent:Connect(function(player, brainrotId: string)
	local data = PlayerDataManager.getData(player)
	if not data then return end

	local entry = data.collection[brainrotId]
	if not entry or entry.count < 2 then return end -- keep at least 1

	local brainrot = BrainrotDatabase[brainrotId]
	if not brainrot then return end

	entry.count -= 1
	local sellValue = brainrot.sellValue
	if MonetizationManager.hasGamepass(player, "DOUBLE_COLLECTION") then
		sellValue *= 2
	end
	PlayerDataManager.addCurrency(data, "seeds", sellValue)
	data.stats.totalSold += 1

	syncData(player)
end)

-- Claim daily reward
remotesFolder.ClaimDailyReward.OnServerEvent:Connect(function(player)
	local data = PlayerDataManager.getData(player)
	if not data then return end

	DailyRewardManager.claim(data)
	syncData(player)
end)

-- Upgrade garden
remotesFolder.UpgradeGarden.OnServerEvent:Connect(function(player)
	local data = PlayerDataManager.getData(player)
	if not data then return end

	if GardenManager.upgradeBedCount(data) then
		syncData(player)
	end
end)

-- Claim free seed (gives player a notification/confirmation that free seed is available)
remotesFolder.ClaimFreeSeed.OnServerEvent:Connect(function(player)
	local data = PlayerDataManager.getData(player)
	if not data then return end

	local now = os.time()
	if (now - data.freeSeedTimer) >= Config.FREE_SEED_INTERVAL then
		data.freeSeedTimer = now
		-- Free seed = auto-plant in first empty bed
		for i = 1, data.garden.bedCount do
			local bed = data.garden.beds[i]
			if bed.seedId == nil then
				GardenManager.plantSeed(data, i, Config.FREE_SEED_RARITY)
				syncData(player)
				return
			end
		end
		-- All beds full, give seeds currency instead
		PlayerDataManager.addCurrency(data, "seeds", Config.SELL_VALUES.Common)
		syncData(player)
	end
end)

-- Auto-harvest loop for gamepass owners
task.spawn(function()
	while true do
		task.wait(5)
		for _, player in Players:GetPlayers() do
			if MonetizationManager.hasGamepass(player, "AUTO_HARVEST") then
				local data = PlayerDataManager.getData(player)
				if data then
					local harvested = false
					for i = 1, data.garden.bedCount do
						if GardenManager.isBedReady(data, i) then
							local hasLucky = MonetizationManager.hasGamepass(player, "LUCKY_GARDENER")
							local brainrot = GardenManager.harvestBed(data, i, hasLucky)
							if brainrot then
								local isRare = brainrot.rarity == "Legendary" or brainrot.rarity == "Mythic"
								remotesFolder.PlayDropAnimation:FireClient(player, brainrot, isRare)
								harvested = true
							end
						end
					end
					if harvested then
						updateLeaderstats(player, data)
						syncData(player)
					end
				end
			end
		end
	end
end)

-- Growth timer refresh loop
task.spawn(function()
	while true do
		task.wait(5)
		for _, player in Players:GetPlayers() do
			local data = PlayerDataManager.getData(player)
			if data then
				local changed = false
				for i = 1, data.garden.bedCount do
					if data.garden.beds[i].seedId and not data.garden.beds[i].isReady then
						if GardenManager.isBedReady(data, i) then
							changed = true
						end
					end
				end
				if changed then
					syncData(player)
				end
			end
		end
	end
end)

-- Search player (cross-server)
remotesFolder.SearchPlayer.OnServerEvent:Connect(function(player, targetName: string)
	TeleportManager.searchPlayer(player, targetName, function(result)
		if result then
			remotesFolder.TradeUpdate:FireClient(player, { type = "searchResult", data = result })
		else
			remotesFolder.TradeUpdate:FireClient(player, { type = "searchResult", data = nil })
		end
	end)
end)

-- Teleport to player
remotesFolder.TeleportToPlayer.OnServerEvent:Connect(function(player, placeId: number, jobId: string)
	TeleportManager.teleportToServer(player, placeId, jobId)
end)

-- Teleport home
remotesFolder.TeleportHome.OnServerEvent:Connect(function(player)
	TeleportManager.teleportHome(player)
end)

-- Initiate trade
remotesFolder.InitiateTrade.OnServerEvent:Connect(function(player, targetUserId: number)
	local targetPlayer = game:GetService("Players"):GetPlayerByUserId(targetUserId)
	if not targetPlayer then return end

	local tradeId = TradeManager.initiateTrade(player, targetPlayer)
	if tradeId then
		local trade = TradeManager.getTrade(player)
		remotesFolder.TradeRequest:FireClient(player, trade)
		remotesFolder.TradeRequest:FireClient(targetPlayer, trade)
	end
end)

-- Update trade offer
remotesFolder.UpdateTradeOffer.OnServerEvent:Connect(function(player, brainrotIds: {string})
	if TradeManager.updateOffer(player, brainrotIds) then
		local trade = TradeManager.getTrade(player)
		local fromPlayer = game:GetService("Players"):GetPlayerByUserId(trade.fromUserId)
		local toPlayer = game:GetService("Players"):GetPlayerByUserId(trade.toUserId)
		if fromPlayer then remotesFolder.TradeUpdate:FireClient(fromPlayer, { type = "offerUpdate", data = trade }) end
		if toPlayer then remotesFolder.TradeUpdate:FireClient(toPlayer, { type = "offerUpdate", data = trade }) end
	end
end)

-- Confirm trade
remotesFolder.ConfirmTrade.OnServerEvent:Connect(function(player)
	local trade = TradeManager.getTrade(player)
	if not trade then return end

	local executed = TradeManager.confirmTrade(player)
	local fromPlayer = game:GetService("Players"):GetPlayerByUserId(trade.fromUserId)
	local toPlayer = game:GetService("Players"):GetPlayerByUserId(trade.toUserId)

	if executed and not TradeManager.getTrade(player) then
		-- Trade was executed and cleaned up
		if fromPlayer then
			syncData(fromPlayer)
			remotesFolder.TradeUpdate:FireClient(fromPlayer, { type = "completed" })
		end
		if toPlayer then
			syncData(toPlayer)
			remotesFolder.TradeUpdate:FireClient(toPlayer, { type = "completed" })
		end
	else
		-- Partial confirmation
		trade = TradeManager.getTrade(player)
		if trade then
			if fromPlayer then remotesFolder.TradeUpdate:FireClient(fromPlayer, { type = "confirmUpdate", data = trade }) end
			if toPlayer then remotesFolder.TradeUpdate:FireClient(toPlayer, { type = "confirmUpdate", data = trade }) end
		end
	end
end)

-- Cancel trade
remotesFolder.CancelTrade.OnServerEvent:Connect(function(player)
	local trade = TradeManager.getTrade(player)
	if trade then
		local fromPlayer = game:GetService("Players"):GetPlayerByUserId(trade.fromUserId)
		local toPlayer = game:GetService("Players"):GetPlayerByUserId(trade.toUserId)
		TradeManager.cancelTrade(trade.id)
		if fromPlayer then remotesFolder.TradeUpdate:FireClient(fromPlayer, { type = "cancelled" }) end
		if toPlayer then remotesFolder.TradeUpdate:FireClient(toPlayer, { type = "cancelled" }) end
	end
end)

-- Like garden
remotesFolder.LikeGarden.OnServerEvent:Connect(function(player, targetUserId: number)
	local targetPlayer = game:GetService("Players"):GetPlayerByUserId(targetUserId)
	if not targetPlayer or targetPlayer == player then return end

	local targetData = PlayerDataManager.getData(targetPlayer)
	if targetData then
		targetData.stats.gardenLikes = (targetData.stats.gardenLikes or 0) + 1
		syncData(targetPlayer)
	end
end)

print("[Server] Grow a Brainrot server initialized")
