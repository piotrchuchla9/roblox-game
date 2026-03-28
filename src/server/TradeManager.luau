-- TradeManager: Server-side trade validation and execution
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDatabase = require(ReplicatedStorage.Shared.BrainrotDatabase)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local TradeManager = {}

-- Active trades: key = tradeId, value = trade state
local activeTrades: { [string]: any } = {}
-- Player -> active tradeId
local playerTrades: { [number]: string } = {}

local function generateTradeId(): string
	return tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
end

function TradeManager.initiateTrade(fromPlayer: Player, toPlayer: Player): string?
	-- Check neither player is already in a trade
	if playerTrades[fromPlayer.UserId] or playerTrades[toPlayer.UserId] then
		return nil
	end

	local tradeId = generateTradeId()
	activeTrades[tradeId] = {
		id = tradeId,
		fromUserId = fromPlayer.UserId,
		toUserId = toPlayer.UserId,
		fromOffer = {},
		toOffer = {},
		fromConfirmed = false,
		toConfirmed = false,
		createdAt = os.time(),
	}

	playerTrades[fromPlayer.UserId] = tradeId
	playerTrades[toPlayer.UserId] = tradeId

	-- Auto-expire
	task.delay(Config.TRADE_TIMEOUT * 4, function() -- generous timeout for selecting items
		TradeManager.cancelTrade(tradeId)
	end)

	return tradeId
end

function TradeManager.updateOffer(player: Player, brainrotIds: {string}): boolean
	local tradeId = playerTrades[player.UserId]
	if not tradeId then return false end

	local trade = activeTrades[tradeId]
	if not trade then return false end

	if #brainrotIds > Config.TRADE_MAX_ITEMS then return false end

	-- Validate player owns all offered brainrots
	local data = PlayerDataManager.getData(player)
	if not data then return false end

	for _, id in brainrotIds do
		local entry = data.collection[id]
		if not entry or entry.count < 1 then return false end
		if not BrainrotDatabase[id] then return false end
	end

	-- Reset confirmations when offer changes
	trade.fromConfirmed = false
	trade.toConfirmed = false

	if player.UserId == trade.fromUserId then
		trade.fromOffer = brainrotIds
	elseif player.UserId == trade.toUserId then
		trade.toOffer = brainrotIds
	end

	return true
end

function TradeManager.confirmTrade(player: Player): boolean
	local tradeId = playerTrades[player.UserId]
	if not tradeId then return false end

	local trade = activeTrades[tradeId]
	if not trade then return false end

	if player.UserId == trade.fromUserId then
		trade.fromConfirmed = true
	elseif player.UserId == trade.toUserId then
		trade.toConfirmed = true
	end

	-- Both confirmed? Execute trade
	if trade.fromConfirmed and trade.toConfirmed then
		return TradeManager.executeTrade(tradeId)
	end

	return true
end

function TradeManager.executeTrade(tradeId: string): boolean
	local trade = activeTrades[tradeId]
	if not trade then return false end

	local fromPlayer = game:GetService("Players"):GetPlayerByUserId(trade.fromUserId)
	local toPlayer = game:GetService("Players"):GetPlayerByUserId(trade.toUserId)
	if not fromPlayer or not toPlayer then
		TradeManager.cancelTrade(tradeId)
		return false
	end

	local fromData = PlayerDataManager.getData(fromPlayer)
	local toData = PlayerDataManager.getData(toPlayer)
	if not fromData or not toData then
		TradeManager.cancelTrade(tradeId)
		return false
	end

	-- Final validation: both still own their offers
	for _, id in trade.fromOffer do
		local entry = fromData.collection[id]
		if not entry or entry.count < 1 then
			TradeManager.cancelTrade(tradeId)
			return false
		end
	end
	for _, id in trade.toOffer do
		local entry = toData.collection[id]
		if not entry or entry.count < 1 then
			TradeManager.cancelTrade(tradeId)
			return false
		end
	end

	-- Execute: remove from sender, add to receiver
	for _, id in trade.fromOffer do
		fromData.collection[id].count -= 1
		if fromData.collection[id].count <= 0 then
			fromData.collection[id] = nil
			fromData.collectionCount -= 1
		end
		PlayerDataManager.addToCollection(toData, id)
	end

	for _, id in trade.toOffer do
		toData.collection[id].count -= 1
		if toData.collection[id].count <= 0 then
			toData.collection[id] = nil
			toData.collectionCount -= 1
		end
		PlayerDataManager.addToCollection(fromData, id)
	end

	-- Cleanup
	TradeManager.cancelTrade(tradeId)
	return true
end

function TradeManager.cancelTrade(tradeId: string)
	local trade = activeTrades[tradeId]
	if not trade then return end

	playerTrades[trade.fromUserId] = nil
	playerTrades[trade.toUserId] = nil
	activeTrades[tradeId] = nil
end

function TradeManager.getTrade(player: Player): any?
	local tradeId = playerTrades[player.UserId]
	if not tradeId then return nil end
	return activeTrades[tradeId]
end

function TradeManager.isInTrade(player: Player): boolean
	return playerTrades[player.UserId] ~= nil
end

return TradeManager
