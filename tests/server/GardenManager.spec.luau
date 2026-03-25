return function()
	local GardenManager = require(game.ServerScriptService.Server.GardenManager)
	local PlayerDataManager = require(game.ServerScriptService.Server.PlayerDataManager)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	describe("GardenManager", function()
		local data

		beforeEach(function()
			data = PlayerDataManager.getDefaultData()
		end)

		describe("plantSeed", function()
			it("should plant in an empty bed", function()
				local success = GardenManager.plantSeed(data, 1, "Common")
				expect(success).to.equal(true)
				expect(data.garden.beds[1].rarity).to.equal("Common")
				expect(data.garden.beds[1].plantedAt).to.be.ok()
				expect(data.garden.beds[1].growthTime).to.equal(Config.GROWTH_TIMES["Common"])
			end)

			it("should fail if bed is occupied", function()
				GardenManager.plantSeed(data, 1, "Common")
				local success = GardenManager.plantSeed(data, 1, "Common")
				expect(success).to.equal(false)
			end)

			it("should fail for invalid bed index", function()
				expect(GardenManager.plantSeed(data, 0, "Common")).to.equal(false)
				expect(GardenManager.plantSeed(data, 99, "Common")).to.equal(false)
			end)
		end)

		describe("waterBed", function()
			it("should reduce growth time", function()
				GardenManager.plantSeed(data, 1, "Rare")
				local bed = data.garden.beds[1]
				local originalTime = bed.growthTime
				GardenManager.waterBed(data, 1)
				expect(bed.growthTime).to.equal(math.max(1, math.floor(originalTime * Config.WATER_SPEED_MULTIPLIER)))
			end)

			it("should fail on empty bed", function()
				local success = GardenManager.waterBed(data, 1)
				expect(success).to.equal(false)
			end)

			it("should enforce cooldown", function()
				GardenManager.plantSeed(data, 1, "Rare")
				GardenManager.waterBed(data, 1)
				-- Immediate second water should fail due to cooldown
				local success = GardenManager.waterBed(data, 1)
				expect(success).to.equal(false)
			end)
		end)

		describe("isBedReady", function()
			it("should return false for freshly planted bed", function()
				GardenManager.plantSeed(data, 1, "Common")
				expect(GardenManager.isBedReady(data, 1)).to.equal(false)
			end)
		end)

		describe("harvestBed", function()
			it("should fail on empty bed", function()
				local brainrot = GardenManager.harvestBed(data, 1)
				expect(brainrot).to.equal(nil)
			end)
		end)

		describe("upgradeBedCount", function()
			it("should add a bed if player has enough seeds", function()
				data.currencies.seeds = Config.BED_UPGRADE_COST
				local success = GardenManager.upgradeBedCount(data)
				expect(success).to.equal(true)
				expect(data.garden.bedCount).to.equal(Config.BASE_BED_COUNT + 1)
				expect(#data.garden.beds).to.equal(Config.BASE_BED_COUNT + 1)
			end)

			it("should fail if at max beds", function()
				data.garden.bedCount = Config.MAX_BED_COUNT
				data.currencies.seeds = Config.BED_UPGRADE_COST
				local success = GardenManager.upgradeBedCount(data)
				expect(success).to.equal(false)
			end)

			it("should fail if not enough seeds", function()
				data.currencies.seeds = 0
				local success = GardenManager.upgradeBedCount(data)
				expect(success).to.equal(false)
			end)
		end)
	end)
end
