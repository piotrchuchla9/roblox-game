return function()
	local Config = require(game.ReplicatedStorage.Shared.Config)

	describe("Config", function()
		it("should have drop rates that sum to 100", function()
			local total = 0
			for _, rate in Config.DROP_RATES do
				total += rate
			end
			expect(total).to.equal(100)
		end)

		it("should have growth times for all rarities", function()
			for rarity, _ in Config.DROP_RATES do
				expect(Config.GROWTH_TIMES[rarity]).to.be.ok()
			end
		end)

		it("should have positive sell values for all rarities", function()
			for rarity, _ in Config.DROP_RATES do
				expect(Config.SELL_VALUES[rarity]).to.be.ok()
				expect(Config.SELL_VALUES[rarity] > 0).to.equal(true)
			end
		end)

		it("should have valid gamepass prices", function()
			for _, price in Config.GAMEPASS_PRICES do
				expect(price > 0).to.equal(true)
			end
		end)
	end)
end
