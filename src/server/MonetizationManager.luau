local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local MonetizationManager = {}

function MonetizationManager.hasGamepass(player: Player, gamepassKey: string): boolean
	local data = PlayerDataManager.getData(player)
	if not data then
		return false
	end

	if data.gamepasses[gamepassKey] then
		return true
	end

	local gamepassInfo = Config.GAMEPASSES[gamepassKey]
	if not gamepassInfo or gamepassInfo.id == 0 then
		return false
	end

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassInfo.id)
	end)

	if success and owns then
		data.gamepasses[gamepassKey] = true
		return true
	end

	return false
end

function MonetizationManager.init()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
		if not wasPurchased then
			return
		end

		local data = PlayerDataManager.getData(player)
		if not data then
			return
		end

		for key, info in Config.GAMEPASSES do
			if info.id == gamepassId then
				data.gamepasses[key] = true

				if key == "VIP_GARDENER" then
					for i = 1, info.extraBeds do
						if data.garden.bedCount < Config.MAX_BED_COUNT then
							data.garden.bedCount += 1
							table.insert(data.garden.beds, {
								seedId = nil,
								plantedAt = nil,
								rarity = nil,
								growthTime = nil,
								isReady = false,
								wateredAt = nil,
							})
						end
					end
				end

				break
			end
		end
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local data = PlayerDataManager.getData(player)
		if not data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		for key, info in Config.DEV_PRODUCTS do
			if info.id == receiptInfo.ProductId then
				if key == "GOLDEN_SEED_PACK" then
					PlayerDataManager.addCurrency(data, "goldenSeeds", info.amount)
				elseif key == "MEGA_FERTILIZER" then
					local fertilized = 0
					for _, bed in data.garden.beds do
						if bed.seedId and not bed.isReady and fertilized < info.amount then
							bed.isReady = true
							fertilized += 1
						end
					end
				end

				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return MonetizationManager
