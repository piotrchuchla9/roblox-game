local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local DropAnimation = {}

local RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(50, 120, 255),
	Epic = Color3.fromRGB(180, 50, 255),
	Legendary = Color3.fromRGB(255, 200, 0),
	Mythic = Color3.fromRGB(255, 50, 50),
}

local RARITY_CHANCE_TEXT = {
	Legendary = "1 in 40 chance!",
	Mythic = "1 in 200 chance!",
}

function DropAnimation.play(brainrot, isRareDrop: boolean)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "DropAnimation"
	gui.DisplayOrder = 100
	gui.Parent = playerGui

	local color = RARITY_COLORS[brainrot.rarity] or RARITY_COLORS.Common

	-- Background flash for rare drops
	if isRareDrop then
		local flash = Instance.new("Frame")
		flash.Size = UDim2.new(1, 0, 1, 0)
		flash.BackgroundColor3 = color
		flash.BackgroundTransparency = 0.5
		flash.Parent = gui

		local flashTween = TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
		})
		flashTween:Play()
	end

	-- Main card
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 0, 0, 0)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	card.Parent = gui

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16)
	cardCorner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 3
	stroke.Parent = card

	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0, 30)
	rarityLabel.Position = UDim2.new(0, 0, 0, 10)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = brainrot.rarity
	rarityLabel.TextColor3 = color
	rarityLabel.TextSize = 18
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = card

	-- Brainrot name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -20, 0, 40)
	nameLabel.Position = UDim2.new(0, 10, 0, 70)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = brainrot.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 24
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	-- Chance text for Legendary/Mythic
	if isRareDrop and RARITY_CHANCE_TEXT[brainrot.rarity] then
		local chanceLabel = Instance.new("TextLabel")
		chanceLabel.Size = UDim2.new(1, 0, 0, 25)
		chanceLabel.Position = UDim2.new(0, 0, 0, 120)
		chanceLabel.BackgroundTransparency = 1
		chanceLabel.Text = RARITY_CHANCE_TEXT[brainrot.rarity]
		chanceLabel.TextColor3 = color
		chanceLabel.TextSize = 16
		chanceLabel.Font = Enum.Font.GothamBold
		chanceLabel.Parent = card
	end

	-- Tap to close
	local closeLabel = Instance.new("TextLabel")
	closeLabel.Size = UDim2.new(1, 0, 0, 20)
	closeLabel.Position = UDim2.new(0, 0, 1, -25)
	closeLabel.BackgroundTransparency = 1
	closeLabel.Text = "Tap to close"
	closeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	closeLabel.TextSize = 12
	closeLabel.Font = Enum.Font.Gotham
	closeLabel.Parent = card

	-- Scale-in animation
	local openTween = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 300, 0, 200),
		Position = UDim2.new(0.5, -150, 0.5, -100),
	})
	openTween:Play()

	-- Close on click
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(1, 0, 1, 0)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = ""
	closeBtn.Parent = gui
	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	-- Auto-close after 5 seconds
	task.delay(5, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

return DropAnimation
