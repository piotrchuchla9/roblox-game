local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local ShopUI = {}

local screenGui: ScreenGui
local visible = false

function ShopUI.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "ShopFrame"
	frame.Size = UDim2.new(0, 400, 0, 380)
	frame.Position = UDim2.new(0.5, -200, 0.5, -190)
	frame.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "Shop"
	title.TextColor3 = Color3.fromRGB(255, 220, 50)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = frame
	closeBtn.MouseButton1Click:Connect(function()
		ShopUI.toggle()
	end)

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 6)
	closeBtnCorner.Parent = closeBtn

	local yOffset = 50
	local gamepassLabels = {
		{ key = "VIP_GARDENER", name = "VIP Gardener", desc = "+2 beds, golden can, VIP badge", price = 199 },
		{ key = "AUTO_HARVEST", name = "Auto-Harvest", desc = "Auto-collect ready brainrots", price = 149 },
		{ key = "DOUBLE_COLLECTION", name = "Double Collection", desc = "2x Seeds from selling", price = 99 },
	}

	for _, gp in gamepassLabels do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.9, 0, 0, 60)
		btn.Position = UDim2.new(0.05, 0, 0, yOffset)
		btn.BackgroundColor3 = Color3.fromRGB(50, 40, 80)
		btn.Text = ""
		btn.Parent = frame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
		nameLabel.Position = UDim2.new(0.02, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = gp.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 16
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = btn

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
		descLabel.Position = UDim2.new(0.02, 0, 0.5, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = gp.desc
		descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		descLabel.TextSize = 11
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = btn

		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(0.3, 0, 1, 0)
		priceLabel.Position = UDim2.new(0.7, 0, 0, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "R$ " .. gp.price
		priceLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
		priceLabel.TextSize = 18
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.Parent = btn

		btn.MouseButton1Click:Connect(function()
			local gamepassId = Config.GAMEPASSES[gp.key] and Config.GAMEPASSES[gp.key].id
			if gamepassId and gamepassId > 0 then
				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, gamepassId)
			end
		end)

		yOffset += 70
	end

	-- Dev products
	local devProductLabels = {
		{ key = "GOLDEN_SEED_PACK", name = "Golden Seed Pack (5x)", price = 49 },
		{ key = "MEGA_FERTILIZER", name = "Mega Fertilizer (10x)", price = 29 },
	}

	for _, dp in devProductLabels do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.9, 0, 0, 40)
		btn.Position = UDim2.new(0.05, 0, 0, yOffset)
		btn.BackgroundColor3 = Color3.fromRGB(80, 60, 20)
		btn.Text = ""
		btn.Parent = frame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
		nameLabel.Position = UDim2.new(0.02, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = dp.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = btn

		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(0.3, 0, 1, 0)
		priceLabel.Position = UDim2.new(0.7, 0, 0, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "R$ " .. dp.price
		priceLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
		priceLabel.TextSize = 16
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.Parent = btn

		btn.MouseButton1Click:Connect(function()
			local productId = Config.DEV_PRODUCTS[dp.key] and Config.DEV_PRODUCTS[dp.key].id
			if productId and productId > 0 then
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
			end
		end)

		yOffset += 50
	end
end

function ShopUI.toggle()
	visible = not visible
	screenGui.Enabled = visible
end

return ShopUI
