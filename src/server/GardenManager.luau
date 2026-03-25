local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local DropSystem = require(script.Parent.DropSystem)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local GardenManager = {}

function GardenManager.plantSeed(data: any, bedIndex: number, rarity: string): boolean
	if bedIndex < 1 or bedIndex > data.garden.bedCount then
		return false
	end

	local bed = data.garden.beds[bedIndex]
	if not bed or bed.seedId ~= nil then
		return false
	end

	local growthTime = Config.GROWTH_TIMES[rarity]
	if not growthTime then
		return false
	end

	bed.seedId = rarity .. "_seed"
	bed.plantedAt = os.time()
	bed.rarity = rarity
	bed.growthTime = growthTime
	bed.isReady = false
	bed.wateredAt = nil

	return true
end

function GardenManager.waterBed(data: any, bedIndex: number): boolean
	if bedIndex < 1 or bedIndex > data.garden.bedCount then
		return false
	end

	local bed = data.garden.beds[bedIndex]
	if not bed or bed.seedId == nil then
		return false
	end

	if bed.isReady then
		return false
	end

	-- Enforce water cooldown
	if bed.wateredAt and (os.time() - bed.wateredAt) < Config.WATER_COOLDOWN then
		return false
	end

	bed.growthTime = math.max(1, math.floor(bed.growthTime * Config.WATER_SPEED_MULTIPLIER))
	bed.wateredAt = os.time()
	return true
end

function GardenManager.isBedReady(data: any, bedIndex: number): boolean
	local bed = data.garden.beds[bedIndex]
	if not bed or bed.seedId == nil then
		return false
	end

	if bed.isReady then
		return true
	end

	local elapsed = os.time() - (bed.plantedAt or 0)
	if elapsed >= (bed.growthTime or math.huge) then
		bed.isReady = true
		return true
	end

	return false
end

function GardenManager.harvestBed(data: any, bedIndex: number, hasLuckyGamepass: boolean?): any?
	if not GardenManager.isBedReady(data, bedIndex) then
		return nil
	end

	local brainrot = DropSystem.rollBrainrot(hasLuckyGamepass)
	PlayerDataManager.addToCollection(data, brainrot.id)

	-- Clear the bed
	local bed = data.garden.beds[bedIndex]
	bed.seedId = nil
	bed.plantedAt = nil
	bed.rarity = nil
	bed.growthTime = nil
	bed.isReady = false
	bed.wateredAt = nil

	return brainrot
end

function GardenManager.upgradeBedCount(data: any): boolean
	if data.garden.bedCount >= Config.MAX_BED_COUNT then
		return false
	end

	if not PlayerDataManager.spendCurrency(data, "seeds", Config.BED_UPGRADE_COST) then
		return false
	end

	data.garden.bedCount += 1
	table.insert(data.garden.beds, {
		seedId = nil,
		plantedAt = nil,
		rarity = nil,
		growthTime = nil,
		isReady = false,
		wateredAt = nil,
	})

	return true
end

return GardenManager
