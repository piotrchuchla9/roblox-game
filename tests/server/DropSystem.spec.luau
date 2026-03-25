return function()
	local DropSystem = require(game.ServerScriptService.Server.DropSystem)
	local Config = require(game.ReplicatedStorage.Shared.Config)
	local BrainrotDatabase = require(game.ReplicatedStorage.Shared.BrainrotDatabase)

	describe("DropSystem", function()
		describe("rollRarity", function()
			it("should return a valid rarity string", function()
				local rarity = DropSystem.rollRarity()
				expect(Config.DROP_RATES[rarity]).to.be.ok()
			end)

			it("should respect approximate distribution over many rolls", function()
				local counts = {}
				local totalRolls = 10000
				for i = 1, totalRolls do
					local rarity = DropSystem.rollRarity()
					counts[rarity] = (counts[rarity] or 0) + 1
				end
				local commonPct = (counts["Common"] or 0) / totalRolls * 100
				expect(commonPct > 40 and commonPct < 60).to.equal(true)
			end)
		end)

		describe("rollBrainrot", function()
			it("should return a valid brainrot from the database", function()
				local brainrot = DropSystem.rollBrainrot()
				expect(brainrot).to.be.ok()
				expect(brainrot.id).to.be.ok()
				expect(BrainrotDatabase[brainrot.id]).to.be.ok()
			end)

			it("should return brainrot matching rolled rarity", function()
				for i = 1, 100 do
					local brainrot = DropSystem.rollBrainrot()
					expect(Config.DROP_RATES[brainrot.rarity]).to.be.ok()
				end
			end)
		end)
	end)
end
