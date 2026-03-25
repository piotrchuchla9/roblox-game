return function()
	local BrainrotDatabase = require(game.ReplicatedStorage.Shared.BrainrotDatabase)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	describe("BrainrotDatabase", function()
		it("should have at least 10 brainrots", function()
			local count = 0
			for _ in BrainrotDatabase do
				count += 1
			end
			expect(count >= 10).to.equal(true)
		end)

		it("should have valid rarities for all brainrots", function()
			for _, brainrot in BrainrotDatabase do
				expect(Config.DROP_RATES[brainrot.rarity]).to.be.ok()
			end
		end)

		it("should have unique IDs", function()
			local seen = {}
			for id, _ in BrainrotDatabase do
				expect(seen[id]).never.to.be.ok()
				seen[id] = true
			end
		end)

		it("should have at least one brainrot per rarity", function()
			local rarityCounts = {}
			for _, brainrot in BrainrotDatabase do
				rarityCounts[brainrot.rarity] = (rarityCounts[brainrot.rarity] or 0) + 1
			end
			for rarity, _ in Config.DROP_RATES do
				expect(rarityCounts[rarity]).to.be.ok()
			end
		end)
	end)
end
