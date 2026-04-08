local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(script.Parent.UITheme)

local ShopUI = {}

local panel = nil
local visible = false

local GAMEPASS_INFO = {
	{
		key = "VIP_GARDENER",
		name = "VIP Gardener",
		desc = "+2 beds, golden can, VIP badge",
		price = 199,
		icon = "👑",
		accent = UITheme.BTN_PINK,
	},
	{
		key = "AUTO_HARVEST",
		name = "Auto-Harvest",
		desc = "Auto-collect ready brainrots",
		price = 149,
		icon = "⚡",
		accent = UITheme.BTN_BLUE,
	},
	{
		key = "DOUBLE_COLLECTION",
		name = "Double Collection",
		desc = "2x Seeds from selling",
		price = 99,
		icon = "💰",
		accent = UITheme.BTN_ORANGE,
	},
}

local DEV_PRODUCT_INFO = {
	{
		key = "GOLDEN_SEED_PACK",
		name = "Golden Seed Pack (5x)",
		price = 49,
		icon = "🌟",
	},
	{
		key = "MEGA_FERTILIZER",
		name = "Mega Fertilizer (10x)",
		price = 29,
		icon = "🚀",
	},
}

function ShopUI.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	panel = UITheme.createPanel(playerGui, {
		name = "ShopUI",
		title = "🛒 SHOP",
		onClose = function()
			ShopUI.toggle()
		end,
	})

	-- Build static shop content
	local contentScroll = panel.contentScroll
	local layoutOrder = 1

	-- Gamepasses section header
	local gpDivider = UITheme.createSectionDivider(contentScroll, {
		text = "⭐ GAMEPASSES",
		color = UITheme.BTN_PINK,
	})
	gpDivider.LayoutOrder = layoutOrder
	layoutOrder += 1

	for _, gp in GAMEPASS_INFO do
		local item = UITheme.createListItem(contentScroll, {
			borderColor = gp.accent,
			icon = gp.icon,
		})
		item.frame.LayoutOrder = layoutOrder
		layoutOrder += 1

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 18)
		nameLabel.Position = UDim2.new(0, 0, 0, 2)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = gp.name
		nameLabel.TextColor3 = UITheme.TEXT_PRIMARY
		nameLabel.TextSize = 14
		nameLabel.Font = UITheme.FONT_BOLD
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = item.infoFrame

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, 0, 0, 14)
		descLabel.Position = UDim2.new(0, 0, 0, 22)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = gp.desc
		descLabel.TextColor3 = UITheme.TEXT_SECONDARY
		descLabel.TextTransparency = 0
		descLabel.TextSize = 11
		descLabel.Font = UITheme.FONT_REGULAR
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = item.infoFrame

		-- Price button
		local priceBtn = UITheme.createActionButton(item.actionFrame, {
			text = gp.price .. " R$",
			color = gp.accent,
			textColor = Color3.fromRGB(255, 255, 255),
			size = UDim2.new(0, 68, 0, 28),
		})
		priceBtn.MouseButton1Click:Connect(function()
			local gamepassId = Config.GAMEPASSES[gp.key] and Config.GAMEPASSES[gp.key].id
			if gamepassId and gamepassId > 0 then
				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, gamepassId)
			end
		end)
	end

	-- Dev Products section header
	local dpDivider = UITheme.createSectionDivider(contentScroll, {
		text = "🚀 BOOSTS",
		color = UITheme.BTN_ORANGE,
	})
	dpDivider.LayoutOrder = layoutOrder
	layoutOrder += 1

	for _, dp in DEV_PRODUCT_INFO do
		local item = UITheme.createListItem(contentScroll, {
			borderColor = UITheme.BTN_ORANGE,
			icon = dp.icon,
			height = 48,
		})
		item.frame.LayoutOrder = layoutOrder
		layoutOrder += 1

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = dp.name
		nameLabel.TextColor3 = UITheme.TEXT_PRIMARY
		nameLabel.TextSize = 13
		nameLabel.Font = UITheme.FONT_BOLD
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = item.infoFrame

		-- Price button
		local priceBtn = UITheme.createActionButton(item.actionFrame, {
			text = dp.price .. " R$",
			color = UITheme.BTN_ORANGE,
			textColor = UITheme.TEXT_ON_BTN,
			size = UDim2.new(0, 60, 0, 26),
		})
		priceBtn.MouseButton1Click:Connect(function()
			local productId = Config.DEV_PRODUCTS[dp.key] and Config.DEV_PRODUCTS[dp.key].id
			if productId and productId > 0 then
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
			end
		end)
	end
end

function ShopUI.toggle()
	visible = not visible
	if visible then
		UITheme.tweenOpen(panel.screenGui)
	else
		UITheme.tweenClose(panel.screenGui)
	end
end

function ShopUI.show()
	if not visible then
		visible = true
		UITheme.tweenOpen(panel.screenGui)
	end
end

function ShopUI.hide()
	if visible then
		visible = false
		UITheme.tweenClose(panel.screenGui)
	end
end

return ShopUI
