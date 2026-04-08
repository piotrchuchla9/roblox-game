local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(script.Parent.UITheme)

local DecoShopUI = {}

local panel = nil
local visible = false

function DecoShopUI.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

	panel = UITheme.createPanel(playerGui, {
		name = "DecoShopUI",
		title = "\u{1F3E1} DECO SHOP",
		onClose = function()
			DecoShopUI.hide()
		end,
	})

	local contentScroll = panel.contentScroll
	local layoutOrder = 1

	-- Group by category
	local categories = {}
	local categoryOrder = {}
	for _, item in Config.DECO_ITEMS do
		if not categories[item.category] then
			categories[item.category] = {}
			table.insert(categoryOrder, item.category)
		end
		table.insert(categories[item.category], item)
	end

	for _, category in categoryOrder do
		local divider = UITheme.createSectionDivider(contentScroll, {
			text = string.upper(category),
			color = UITheme.BTN_GREEN,
		})
		divider.LayoutOrder = layoutOrder
		layoutOrder += 1

		for _, item in categories[category] do
			local listItem = UITheme.createListItem(contentScroll, {
				borderColor = UITheme.BTN_GREEN,
				icon = item.icon,
				height = 48,
			})
			listItem.frame.LayoutOrder = layoutOrder
			layoutOrder += 1

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, 0, 1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = item.name
			nameLabel.TextColor3 = UITheme.TEXT_PRIMARY
			nameLabel.TextSize = 13
			nameLabel.Font = UITheme.FONT_BOLD
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = listItem.infoFrame

			local priceBtn = UITheme.createActionButton(listItem.actionFrame, {
				text = item.price .. " \u{1F331}",
				color = UITheme.BTN_GREEN,
				textColor = UITheme.TEXT_ON_BTN,
				size = UDim2.new(0, 68, 0, 28),
			})
			priceBtn.MouseButton1Click:Connect(function()
				remotesFolder.BuyDeco:FireServer(item.id)
			end)
		end
	end
end

function DecoShopUI.show()
	if not visible then
		visible = true
		UITheme.tweenOpen(panel.screenGui)
	end
end

function DecoShopUI.hide()
	if visible then
		visible = false
		UITheme.tweenClose(panel.screenGui)
	end
end

return DecoShopUI
