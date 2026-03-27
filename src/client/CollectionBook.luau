local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotDatabase = require(ReplicatedStorage.Shared.BrainrotDatabase)
local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(script.Parent.UITheme)

local CollectionBook = {}

local panel = nil
local visible = false

local RARITY_EMOJI = {
	Common = "",
	Uncommon = "🟢",
	Rare = "💎",
	Epic = "💜",
	Legendary = "⭐",
	Mythic = "🔥",
}

function CollectionBook.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	panel = UITheme.createPanel(playerGui, {
		name = "CollectionBook",
		title = "📖 COLLECTION",
		onClose = function()
			CollectionBook.toggle()
		end,
	})
end

local function clearContent()
	for _, child in panel.contentScroll:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

function CollectionBook.update(data)
	if not panel then return end
	clearContent()

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

	-- Count discovered
	local discovered = 0
	local total = 0
	for _ in BrainrotDatabase do
		total += 1
	end
	for _ in data.collection do
		discovered += 1
	end

	-- Subtitle
	local subtitle = Instance.new("Frame")
	subtitle.Size = UDim2.new(1, 0, 0, 20)
	subtitle.BackgroundTransparency = 1
	subtitle.LayoutOrder = 0
	subtitle.Parent = panel.contentScroll

	local subtitleText = Instance.new("TextLabel")
	subtitleText.Size = UDim2.new(1, 0, 1, 0)
	subtitleText.BackgroundTransparency = 1
	subtitleText.Text = discovered .. "/" .. total .. " discovered"
	subtitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	subtitleText.TextTransparency = 0.5
	subtitleText.TextSize = 12
	subtitleText.Font = UITheme.FONT_REGULAR
	subtitleText.TextXAlignment = Enum.TextXAlignment.Left
	subtitleText.Parent = subtitle

	-- Sort brainrots by rarity (rarest first)
	local sorted = {}
	for _, brainrot in BrainrotDatabase do
		table.insert(sorted, brainrot)
	end
	table.sort(sorted, function(a, b)
		local aIdx = table.find(UITheme.RARITY_ORDER, a.rarity) or 99
		local bIdx = table.find(UITheme.RARITY_ORDER, b.rarity) or 99
		return aIdx < bIdx
	end)

	-- Group by rarity and render with dividers
	local currentRarity = nil
	local layoutOrder = 1

	for _, brainrot in sorted do
		-- Section divider when rarity changes
		if brainrot.rarity ~= currentRarity then
			currentRarity = brainrot.rarity
			local color = UITheme.RARITY_COLORS[currentRarity] or UITheme.RARITY_COLORS.Common
			local emoji = RARITY_EMOJI[currentRarity] or ""
			local divider = UITheme.createSectionDivider(panel.contentScroll, {
				text = emoji .. " " .. string.upper(currentRarity),
				color = color,
			})
			divider.LayoutOrder = layoutOrder
			layoutOrder += 1
		end

		local owned = data.collection[brainrot.id]
		local rarityColor = UITheme.RARITY_COLORS[brainrot.rarity] or UITheme.RARITY_COLORS.Common
		local dropRate = Config.DROP_RATES[brainrot.rarity] or 0

		if owned then
			-- Owned brainrot
			local item = UITheme.createListItem(panel.contentScroll, {
				borderColor = rarityColor,
				icon = "🧠",
			})
			item.frame.LayoutOrder = layoutOrder

			-- Name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, 0, 0, 18)
			nameLabel.Position = UDim2.new(0, 0, 0, 2)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = brainrot.name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = 12
			nameLabel.Font = UITheme.FONT_BOLD
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			nameLabel.Parent = item.infoFrame

			-- Rarity label
			local rarityLabel = Instance.new("TextLabel")
			rarityLabel.Size = UDim2.new(1, 0, 0, 14)
			rarityLabel.Position = UDim2.new(0, 0, 0, 20)
			rarityLabel.BackgroundTransparency = 1
			rarityLabel.Text = (RARITY_EMOJI[brainrot.rarity] or "") .. " " .. string.upper(brainrot.rarity) .. " — " .. dropRate .. "%"
			rarityLabel.TextColor3 = rarityColor
			rarityLabel.TextSize = 9
			rarityLabel.Font = UITheme.FONT_BOLD
			rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
			rarityLabel.Parent = item.infoFrame

			-- Count (right side, before action)
			local countLabel = Instance.new("TextLabel")
			countLabel.Size = UDim2.new(0, 30, 1, 0)
			countLabel.Position = UDim2.new(0, -35, 0, 0)
			countLabel.BackgroundTransparency = 1
			countLabel.Text = "x" .. owned.count
			countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			countLabel.TextSize = 14
			countLabel.Font = UITheme.FONT_BOLD
			countLabel.Parent = item.actionFrame

			-- Sell button if count >= 2
			if owned.count >= 2 then
				item.actionFrame.Size = UDim2.new(0, 100, 1, 0)
				item.actionFrame.Position = UDim2.new(1, -100, 0, 0)

				countLabel.Position = UDim2.new(0, 0, 0, 0)
				countLabel.Size = UDim2.new(0, 28, 1, 0)

				local sellBtn = UITheme.createActionButton(item.actionFrame, {
					text = "SELL +" .. brainrot.sellValue,
					color = Color3.fromRGB(200, 80, 30),
					size = UDim2.new(0, 64, 0, 26),
				})
				sellBtn.Position = UDim2.new(1, -32, 0.5, 0)
				sellBtn.MouseButton1Click:Connect(function()
					remotesFolder.SellBrainrot:FireServer(brainrot.id)
				end)
			end
		else
			-- Locked brainrot
			local item = UITheme.createListItem(panel.contentScroll, {
				borderColor = Color3.fromRGB(255, 255, 255),
				borderTransparency = 0.85,
				icon = "❓",
				iconTransparency = 0.6,
			})
			item.frame.LayoutOrder = layoutOrder
			item.frame.BackgroundTransparency = 0.65

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, 0, 0, 18)
			nameLabel.Position = UDim2.new(0, 0, 0, 2)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = "???"
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextTransparency = 0.6
			nameLabel.TextSize = 12
			nameLabel.Font = UITheme.FONT_BOLD
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = item.infoFrame

			local rarityHint = Instance.new("TextLabel")
			rarityHint.Size = UDim2.new(1, 0, 0, 14)
			rarityHint.Position = UDim2.new(0, 0, 0, 20)
			rarityHint.BackgroundTransparency = 1
			rarityHint.Text = string.upper(brainrot.rarity) .. " — " .. dropRate .. "%"
			rarityHint.TextColor3 = Color3.fromRGB(255, 255, 255)
			rarityHint.TextTransparency = 0.75
			rarityHint.TextSize = 9
			rarityHint.Font = UITheme.FONT_BOLD
			rarityHint.TextXAlignment = Enum.TextXAlignment.Left
			rarityHint.Parent = item.infoFrame
		end

		layoutOrder += 1
	end
end

function CollectionBook.toggle()
	visible = not visible
	if visible then
		UITheme.tweenOpen(panel.screenGui)
	else
		UITheme.tweenClose(panel.screenGui)
	end
end

return CollectionBook
