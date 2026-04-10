local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local PlayerDataManager = {}

local DATA_STORE_NAME = "PlayerData_v1"
local AUTO_SAVE_INTERVAL = 300
local dataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)

local playerData: { [number]: any } = {}

function PlayerDataManager.getDefaultData(): any
	local beds = {}
	for i = 1, Config.BASE_BED_COUNT do
		table.insert(beds, {
			seedId = nil,
			plantedAt = nil,
			rarity = nil,
			growthTime = nil,
			isReady = false,
			wateredAt = nil,
		})
	end

	return {
		garden = {
			beds = beds,
			bedCount = Config.BASE_BED_COUNT,
			tools = { wateringCan = "basic" },
		},
		collection = {},
		collectionCount = 0,
		currencies = { seeds = Config.STARTING_SEEDS or 25, goldenSeeds = 0 },
		gamepasses = {},
		dailyReward = { lastClaimed = 0, streak = 0 },
		stats = { totalHarvested = 0, totalSold = 0 },
		freeSeedTimer = 0,
		waterBoostExpiry = 0,
		exhibits = { nil, nil, nil, nil },
		displayCases = 0,
		backpack = {},
		placedDecorations = {},
	}
end

function PlayerDataManager.loadPlayer(player: Player)
	local key = "player_" .. player.UserId
	local success, savedData = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if success and savedData then
		-- Merge z domyślnymi danymi (żeby nowe pola miały wartości)
		local defaults = PlayerDataManager.getDefaultData()
		for k, v in defaults do
			if savedData[k] == nil then
				savedData[k] = v
			end
		end
		-- Upewnij się, że garden.beds ma właściwą ilość łóżek
		local bedCount = savedData.garden.bedCount or Config.BASE_BED_COUNT
		while #savedData.garden.beds < bedCount do
			table.insert(savedData.garden.beds, {
				seedId = nil, plantedAt = nil, rarity = nil,
				growthTime = nil, isReady = false, wateredAt = nil,
			})
		end
		playerData[player.UserId] = savedData
	else
		playerData[player.UserId] = PlayerDataManager.getDefaultData()
		if not success then
			warn("[PlayerDataManager] Nie udało się załadować danych dla", player.Name, "- używam domyślnych")
		end
	end
end

function PlayerDataManager.savePlayer(player: Player): boolean
	local data = playerData[player.UserId]
	if not data then
		return false
	end

	local key = "player_" .. player.UserId
	local success, err = pcall(function()
		dataStore:SetAsync(key, data)
	end)

	if not success then
		warn("[PlayerDataManager] Nie udało się zapisać danych dla", player.Name, ":", err)
	end
	return success
end

function PlayerDataManager.getData(player: Player): any?
	return playerData[player.UserId]
end

function PlayerDataManager.unloadPlayer(player: Player)
	PlayerDataManager.savePlayer(player)
	playerData[player.UserId] = nil
end

function PlayerDataManager.addToCollection(data: any, brainrotId: string)
	if not data.collection[brainrotId] then
		data.collection[brainrotId] = {
			count = 0,
			firstObtainedAt = os.time(),
		}
		data.collectionCount += 1
	end
	data.collection[brainrotId].count += 1
	data.stats.totalHarvested += 1
end

function PlayerDataManager.addCurrency(data: any, currencyType: string, amount: number)
	data.currencies[currencyType] = (data.currencies[currencyType] or 0) + amount
end

function PlayerDataManager.spendCurrency(data: any, currencyType: string, amount: number): boolean
	if (data.currencies[currencyType] or 0) < amount then
		return false
	end
	data.currencies[currencyType] -= amount
	return true
end

Players.PlayerAdded:Connect(function(player)
	PlayerDataManager.loadPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerDataManager.unloadPlayer(player)
end)

-- Obsłuż graczy którzy dołączyli zanim moduł się załadował
for _, player in Players:GetPlayers() do
	if not playerData[player.UserId] then
		task.spawn(PlayerDataManager.loadPlayer, player)
	end
end

-- Auto-save co 5 minut
task.spawn(function()
	while true do
		task.wait(AUTO_SAVE_INTERVAL)
		for _, player in Players:GetPlayers() do
			task.spawn(PlayerDataManager.savePlayer, player)
		end
	end
end)

-- Zapis wszystkich graczy przy zamykaniu serwera (równolegle)
game:BindToClose(function()
	local players = Players:GetPlayers()
	if #players == 0 then return end

	local finished = 0
	for _, player in players do
		task.spawn(function()
			PlayerDataManager.savePlayer(player)
			finished += 1
		end)
	end

	-- Czekaj aż wszystkie zapisy się zakończą
	while finished < #players do
		task.wait(0.1)
	end
end)

return PlayerDataManager
