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
local PlayerDataManager = require(script.PlayerDataManager)
local GardenManager = require(script.GardenManager)
local DropSystem = require(script.DropSystem)
local MonetizationManager = require(script.MonetizationManager)
local DailyRewardManager = require(script.DailyRewardManager)

MonetizationManager.init()

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
	end
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

print("[Server] Grow a Brainrot server initialized")
