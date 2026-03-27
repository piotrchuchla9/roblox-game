local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UITheme = require(script.Parent.UITheme)

local DropAnimation = {}

local RARITY_CHANCE_TEXT = {
	Common = "1 in 2 chance",
	Uncommon = "1 in 4 chance",
	Rare = "1 in 7 chance",
	Epic = "1 in 14 chance",
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

	local color = UITheme.RARITY_COLORS[brainrot.rarity] or UITheme.RARITY_COLORS.Common

	-- Full-screen dim background
	local dimBg = Instance.new("Frame")
	dimBg.Size = UDim2.new(1, 0, 1, 0)
	dimBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dimBg.BackgroundTransparency = 1
	dimBg.Parent = gui

	TweenService:Create(dimBg, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.5,
	}):Play()

	-- Background flash for rare drops
	if isRareDrop then
		local flash = Instance.new("Frame")
		flash.Size = UDim2.new(1, 0, 1, 0)
		flash.BackgroundColor3 = color
		flash.BackgroundTransparency = 0.4
		flash.Parent = gui

		TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
		}):Play()
	end

	-- Main card
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 0, 0, 0)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = UITheme.BG_PANEL
	card.Parent = gui

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 20)
	cardCorner.Parent = card

	-- UIStroke with gradient
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 3
	stroke.Transparency = 0.1
	stroke.Parent = card

	local strokeGrad = Instance.new("UIGradient")
	strokeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, color),
	})
	strokeGrad.Rotation = 45
	strokeGrad.Parent = stroke

	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0, 30)
	rarityLabel.Position = UDim2.new(0, 0, 0, 16)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = string.upper(brainrot.rarity)
	rarityLabel.TextColor3 = color
	rarityLabel.TextSize = 18
	rarityLabel.Font = UITheme.FONT_BOLD
	rarityLabel.Parent = card

	local rarityStroke = Instance.new("UIStroke")
	rarityStroke.Color = color
	rarityStroke.Thickness = 1
	rarityStroke.Transparency = 0.5
	rarityStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	rarityStroke.Parent = rarityLabel

	-- Brainrot name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -30, 0, 50)
	nameLabel.Position = UDim2.new(0, 15, 0, 70)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = brainrot.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 24
	nameLabel.Font = UITheme.FONT_BOLD
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	-- Chance text for all rarities
	local chanceText = RARITY_CHANCE_TEXT[brainrot.rarity]
	if chanceText then
		local chanceLabel = Instance.new("TextLabel")
		chanceLabel.Size = UDim2.new(1, 0, 0, 25)
		chanceLabel.Position = UDim2.new(0, 0, 0, 135)
		chanceLabel.BackgroundTransparency = 1
		chanceLabel.Text = chanceText
		chanceLabel.TextColor3 = color
		chanceLabel.TextTransparency = 0.2
		chanceLabel.TextSize = 14
		chanceLabel.Font = UITheme.FONT_BOLD
		chanceLabel.Parent = card
	end

	-- Tap to close
	local closeLabel = Instance.new("TextLabel")
	closeLabel.Size = UDim2.new(1, 0, 0, 20)
	closeLabel.Position = UDim2.new(0, 0, 1, -28)
	closeLabel.BackgroundTransparency = 1
	closeLabel.Text = "Tap to close"
	closeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeLabel.TextTransparency = 0.6
	closeLabel.TextSize = 11
	closeLabel.Font = UITheme.FONT_REGULAR
	closeLabel.Parent = card

	-- Scale-in animation
	local openTween = TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 320, 0, 200),
	})
	openTween:Play()

	-- Decorative particles for rare drops
	if isRareDrop then
		for p = 1, 8 do
			local particle = Instance.new("Frame")
			particle.Size = UDim2.new(0, 6, 0, 6)
			particle.Position = UDim2.new(0.5, 0, 0.5, 0)
			particle.AnchorPoint = Vector2.new(0.5, 0.5)
			particle.BackgroundColor3 = color
			particle.Parent = gui

			local pCorner = Instance.new("UICorner")
			pCorner.CornerRadius = UDim.new(1, 0)
			pCorner.Parent = particle

			local angle = (p / 8) * math.pi * 2
			local dist = 180
			TweenService:Create(particle, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, math.cos(angle) * dist, 0.5, math.sin(angle) * dist),
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 2, 0, 2),
			}):Play()
		end
	end

	-- Screen shake for epic+ drops
	if isRareDrop and (brainrot.rarity == "Epic" or brainrot.rarity == "Legendary" or brainrot.rarity == "Mythic") then
		task.spawn(function()
			for _ = 1, 6 do
				local offsetX = math.random(-4, 4)
				local offsetY = math.random(-4, 4)
				card.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
				task.wait(0.04)
			end
			card.Position = UDim2.new(0.5, 0, 0.5, 0)
		end)
	end

	-- Close on click
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(1, 0, 1, 0)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = ""
	closeBtn.ZIndex = 0
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
