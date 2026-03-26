local TweenService = game:GetService("TweenService")

local UITheme = {}

-- Backgrounds
UITheme.BG_PRIMARY = Color3.fromRGB(10, 10, 26)
UITheme.BG_PANEL = Color3.fromRGB(10, 5, 30)
UITheme.BG_CARD = Color3.fromRGB(20, 15, 40)
UITheme.BG_LIST_ITEM = Color3.fromRGB(15, 12, 35)

-- Neon accents
UITheme.MAGENTA = Color3.fromRGB(255, 0, 255)
UITheme.CYAN = Color3.fromRGB(0, 255, 255)
UITheme.YELLOW = Color3.fromRGB(255, 255, 0)
UITheme.GREEN = Color3.fromRGB(0, 255, 136)
UITheme.ORANGE = Color3.fromRGB(255, 180, 0)

-- Rarity colors
UITheme.RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(50, 120, 255),
	Epic = Color3.fromRGB(180, 50, 255),
	Legendary = Color3.fromRGB(255, 200, 0),
	Mythic = Color3.fromRGB(255, 50, 50),
}

UITheme.RARITY_ORDER = { "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common" }

-- Fonts
UITheme.FONT_BOLD = Enum.Font.GothamBold
UITheme.FONT_REGULAR = Enum.Font.Gotham

function UITheme.createNeonBorder(parent: GuiObject, color: Color3, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 2
	stroke.Transparency = 0.3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

function UITheme.createListItem(parent: GuiObject, config: { [string]: any }): { [string]: any }
	local height = config.height or 56

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.BackgroundColor3 = UITheme.BG_LIST_ITEM
	frame.BackgroundTransparency = 0.3
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = frame

	local leftBorder = Instance.new("Frame")
	leftBorder.Name = "LeftBorder"
	leftBorder.Size = UDim2.new(0, 3, 1, -16)
	leftBorder.Position = UDim2.new(0, -6, 0, 8)
	leftBorder.BackgroundColor3 = config.borderColor
	leftBorder.BackgroundTransparency = config.borderTransparency or 0
	leftBorder.BorderSizePixel = 0
	leftBorder.Parent = frame

	local borderCorner = Instance.new("UICorner")
	borderCorner.CornerRadius = UDim.new(0, 2)
	borderCorner.Parent = leftBorder

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 32, 1, 0)
	iconLabel.Position = UDim2.new(0, 4, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = config.icon or ""
	iconLabel.TextSize = 24
	iconLabel.TextTransparency = config.iconTransparency or 0
	iconLabel.Font = Enum.Font.SourceSans
	iconLabel.Parent = frame

	local infoFrame = Instance.new("Frame")
	infoFrame.Name = "Info"
	infoFrame.Size = UDim2.new(1, -120, 1, 0)
	infoFrame.Position = UDim2.new(0, 44, 0, 0)
	infoFrame.BackgroundTransparency = 1
	infoFrame.Parent = frame

	local actionFrame = Instance.new("Frame")
	actionFrame.Name = "Action"
	actionFrame.Size = UDim2.new(0, 70, 1, 0)
	actionFrame.Position = UDim2.new(1, -70, 0, 0)
	actionFrame.BackgroundTransparency = 1
	actionFrame.Parent = frame

	return {
		frame = frame,
		iconLabel = iconLabel,
		infoFrame = infoFrame,
		actionFrame = actionFrame,
		leftBorder = leftBorder,
	}
end

function UITheme.createPanel(playerGui: Instance, config: { [string]: any }): { [string]: any }
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = config.name
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = UITheme.BG_PANEL
	bg.BackgroundTransparency = 0.05
	bg.Parent = screenGui

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundTransparency = 1
	header.Parent = bg

	local headerStroke = Instance.new("UIStroke")
	headerStroke.Color = UITheme.MAGENTA
	headerStroke.Thickness = 2
	headerStroke.Transparency = 0.5
	headerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	headerStroke.Parent = header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -50, 1, 0)
	titleLabel.Position = UDim2.new(0, 16, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = config.title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 20
	titleLabel.Font = UITheme.FONT_BOLD
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = UITheme.MAGENTA
	titleStroke.Thickness = 1
	titleStroke.Transparency = 0.6
	titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	titleStroke.Parent = titleLabel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -44, 0, 12)
	closeBtn.BackgroundColor3 = UITheme.BG_CARD
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = UITheme.MAGENTA
	closeBtn.TextSize = 16
	closeBtn.Font = UITheme.FONT_BOLD
	closeBtn.Parent = header

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn

	UITheme.createNeonBorder(closeBtn, UITheme.MAGENTA, 1)

	closeBtn.MouseButton1Click:Connect(function()
		if config.onClose then
			config.onClose()
		end
	end)

	local contentScroll = Instance.new("ScrollingFrame")
	contentScroll.Name = "Content"
	contentScroll.Size = UDim2.new(1, -20, 1, -66)
	contentScroll.Position = UDim2.new(0, 10, 0, 60)
	contentScroll.BackgroundTransparency = 1
	contentScroll.ScrollBarThickness = 4
	contentScroll.ScrollBarImageColor3 = UITheme.MAGENTA
	contentScroll.BorderSizePixel = 0
	contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	contentScroll.Parent = bg

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Name = "Layout"
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.Parent = contentScroll

	return {
		screenGui = screenGui,
		background = bg,
		contentScroll = contentScroll,
		headerFrame = header,
		titleLabel = titleLabel,
	}
end

function UITheme.tweenOpen(screenGui: ScreenGui)
	screenGui.Enabled = true
	local bg = screenGui:FindFirstChild("Background")
	if not bg then return end

	bg.BackgroundTransparency = 1
	local content = bg:FindFirstChild("Content") or screenGui:FindFirstChild("Content")
	local contentStartY = nil
	if content then
		contentStartY = content.Position.Y.Offset
		content.Position = UDim2.new(content.Position.X.Scale, content.Position.X.Offset, content.Position.Y.Scale, contentStartY + 50)
	end

	TweenService:Create(bg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.05,
	}):Play()

	if content and contentStartY then
		TweenService:Create(content, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(content.Position.X.Scale, content.Position.X.Offset, content.Position.Y.Scale, contentStartY),
		}):Play()
	end
end

function UITheme.tweenClose(screenGui: ScreenGui, callback: (() -> ())?)
	local bg = screenGui:FindFirstChild("Background")
	if not bg then
		screenGui.Enabled = false
		if callback then callback() end
		return
	end

	TweenService:Create(bg, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	}):Play()

	task.delay(0.15, function()
		screenGui.Enabled = false
		if callback then callback() end
	end)
end

function UITheme.createActionButton(parent: GuiObject, config: { [string]: any }): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = config.size or UDim2.new(0, 70, 0, 28)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = UDim2.new(0.5, 0, 0.5, 0)
	btn.BackgroundColor3 = config.color
	btn.Text = config.text
	btn.TextColor3 = config.textColor or Color3.fromRGB(255, 255, 255)
	btn.TextSize = 11
	btn.Font = UITheme.FONT_BOLD
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	return btn
end

function UITheme.createSectionDivider(parent: GuiObject, config: { [string]: any }): Frame
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, 0, 0, 20)
	divider.BackgroundTransparency = 1
	divider.Parent = parent

	local leftLine = Instance.new("Frame")
	leftLine.Size = UDim2.new(0.35, 0, 0, 1)
	leftLine.Position = UDim2.new(0, 0, 0.5, 0)
	leftLine.BackgroundColor3 = config.color
	leftLine.BackgroundTransparency = 0.6
	leftLine.BorderSizePixel = 0
	leftLine.Parent = divider

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.3, 0, 1, 0)
	label.Position = UDim2.new(0.35, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = config.text
	label.TextColor3 = config.color
	label.TextSize = 9
	label.Font = UITheme.FONT_BOLD
	label.Parent = divider

	local rightLine = Instance.new("Frame")
	rightLine.Size = UDim2.new(0.35, 0, 0, 1)
	rightLine.Position = UDim2.new(0.65, 0, 0.5, 0)
	rightLine.BackgroundColor3 = config.color
	rightLine.BackgroundTransparency = 0.6
	rightLine.BorderSizePixel = 0
	rightLine.Parent = divider

	return divider
end

return UITheme
