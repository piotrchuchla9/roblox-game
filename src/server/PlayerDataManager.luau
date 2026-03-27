local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local PlayerDataManager = {}

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
		currencies = { seeds = 100, goldenSeeds = 0 }, -- start with 100 seeds
		gamepasses = {},
		dailyReward = { lastClaimed = 0, streak = 0 },
		stats = { totalHarvested = 0, totalSold = 0, gardenLikes = 0 },
		freeSeedTimer = 0,
	}
end

function PlayerDataManager.loadPlayer(player: Player)
	playerData[player.UserId] = PlayerDataManager.getDefaultData()
end

function PlayerDataManager.getData(player: Player): any?
	return playerData[player.UserId]
end

function PlayerDataManager.unloadPlayer(player: Player)
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

return PlayerDataManager
