return function()
	local DailyRewardManager = require(game.ServerScriptService.Server.DailyRewardManager)
	local PlayerDataManager = require(game.ServerScriptService.Server.PlayerDataManager)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	describe("DailyRewardManager", function()
		local data

		beforeEach(function()
			data = PlayerDataManager.getDefaultData()
		end)

		describe("canClaim", function()
			it("should allow first-time claim", function()
				expect(DailyRewardManager.canClaim(data)).to.equal(true)
			end)

			it("should deny claim if cooldown not elapsed", function()
				data.dailyReward.lastClaimed = os.time()
				expect(DailyRewardManager.canClaim(data)).to.equal(false)
			end)
		end)

		describe("claim", function()
			it("should grant base reward on first claim", function()
				local reward = DailyRewardManager.claim(data)
				local expected = Config.DAILY_REWARD_BASE + (1 * Config.DAILY_REWARD_STREAK_BONUS)
				expect(reward).to.equal(expected)
				expect(data.dailyReward.streak).to.equal(1)
			end)

			it("should cap streak at max", function()
				data.dailyReward.lastClaimed = os.time() - Config.DAILY_REWARD_COOLDOWN - 1
				data.dailyReward.streak = Config.DAILY_REWARD_MAX_STREAK
				DailyRewardManager.claim(data)
				expect(data.dailyReward.streak).to.equal(Config.DAILY_REWARD_MAX_STREAK)
			end)
		end)
	end)
end
