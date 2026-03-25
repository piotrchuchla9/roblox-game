local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDatabase = require(ReplicatedStorage.Shared.BrainrotDatabase)

local DropSystem = {}

-- Build brainrot-by-rarity lookup once
local brainrotsByRarity: { [string]: { any } } = {}
for _, brainrot in BrainrotDatabase do
	if not brainrotsByRarity[brainrot.rarity] then
		brainrotsByRarity[brainrot.rarity] = {}
	end
	table.insert(brainrotsByRarity[brainrot.rarity], brainrot)
end

function DropSystem.rollRarity(hasLuckyGamepass: boolean?): string
	local rates = {}
	local total = 0

	for rarity, rate in Config.DROP_RATES do
		local adjustedRate = rate
		if hasLuckyGamepass and rarity ~= "Common" and rarity ~= "Uncommon" then
			adjustedRate = rate * 1.10 -- 10% multiplicative boost for Rare+
		end
		rates[rarity] = adjustedRate
		total += adjustedRate
	end

	local roll = math.random() * total
	local cumulative = 0

	-- Roll in order from rarest to most common
	local order = { "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common" }
	for _, rarity in order do
		cumulative += rates[rarity]
		if roll <= cumulative then
			return rarity
		end
	end

	return "Common"
end

function DropSystem.rollBrainrot(hasLuckyGamepass: boolean?): any
	local rarity = DropSystem.rollRarity(hasLuckyGamepass)
	local pool = brainrotsByRarity[rarity]

	if not pool or #pool == 0 then
		pool = brainrotsByRarity["Common"]
	end

	local index = math.random(1, #pool)
	return pool[index]
end

return DropSystem
