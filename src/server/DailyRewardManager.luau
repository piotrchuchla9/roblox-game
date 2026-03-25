local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local DailyRewardManager = {}

function DailyRewardManager.canClaim(data: any): boolean
	local elapsed = os.time() - data.dailyReward.lastClaimed
	return elapsed >= Config.DAILY_REWARD_COOLDOWN
end

function DailyRewardManager.claim(data: any): number?
	if not DailyRewardManager.canClaim(data) then
		return nil
	end

	-- Reset streak if more than 48h since last claim
	local elapsed = os.time() - data.dailyReward.lastClaimed
	if data.dailyReward.lastClaimed > 0 and elapsed > Config.DAILY_REWARD_COOLDOWN * 2 then
		data.dailyReward.streak = 0
	end

	if data.dailyReward.streak < Config.DAILY_REWARD_MAX_STREAK then
		data.dailyReward.streak += 1
	end

	data.dailyReward.lastClaimed = os.time()

	local reward = Config.DAILY_REWARD_BASE + (data.dailyReward.streak * Config.DAILY_REWARD_STREAK_BONUS)
	PlayerDataManager.addCurrency(data, "seeds", reward)

	return reward
end

return DailyRewardManager
