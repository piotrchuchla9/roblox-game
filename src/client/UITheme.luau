local TweenService = game:GetService("TweenService")

local UITheme = {}

-- === CANDY PASTEL PALETTE ===

-- Backgrounds
UITheme.BG_PRIMARY = Color3.fromRGB(255, 255, 255)
UITheme.BG_SECONDARY = Color3.fromRGB(255, 245, 248)
UITheme.BG_OVERLAY_COLOR = Color3.fromRGB(0, 0, 0)
UITheme.BG_OVERLAY_TRANSPARENCY = 0.4
UITheme.BG_CARD = Color3.fromRGB(255, 255, 255)
UITheme.BG_LIST_ITEM = Color3.fromRGB(255, 252, 254)

-- Accents
UITheme.PRIMARY = Color3.fromRGB(255, 181, 232)
UITheme.SECONDARY = Color3.fromRGB(181, 222, 255)
UITheme.ACCENT_GREEN = Color3.fromRGB(231, 255, 172)
UITheme.ACCENT_YELLOW = Color3.fromRGB(255, 245, 186)
UITheme.ACCENT_LAVENDER = Color3.fromRGB(220, 211, 255)

-- Button colors (saturated + shadow for 3D effect)
UITheme.BTN_GREEN = Color3.fromRGB(76, 175, 80)
UITheme.BTN_GREEN_SHADOW = Color3.fromRGB(56, 142, 60)
UITheme.BTN_ORANGE = Color3.fromRGB(255, 152, 0)
UITheme.BTN_ORANGE_SHADOW = Color3.fromRGB(230, 81, 0)
UITheme.BTN_PINK = Color3.fromRGB(233, 30, 99)
UITheme.BTN_PINK_SHADOW = Color3.fromRGB(173, 20, 87)
UITheme.BTN_BLUE = Color3.fromRGB(33, 150, 243)
UITheme.BTN_BLUE_SHADOW = Color3.fromRGB(25, 118, 210)
UITheme.BTN_RED = Color3.fromRGB(244, 67, 54)
UITheme.BTN_RED_SHADOW = Color3.fromRGB(198, 40, 40)

-- Text
UITheme.TEXT_PRIMARY = Color3.fromRGB(93, 64, 55)
UITheme.TEXT_SECONDARY = Color3.fromRGB(121, 85, 72)
UITheme.TEXT_ON_BTN = Color3.fromRGB(255, 255, 255)

-- Rarity colors (chunky borders)
UITheme.RARITY_COLORS = {
	Common = Color3.fromRGB(189, 189, 189),
	Uncommon = Color3.fromRGB(76, 175, 80),
	Rare = Color3.fromRGB(33, 150, 243),
	Epic = Color3.fromRGB(156, 39, 176),
	Legendary = Color3.fromRGB(255, 152, 0),
	Mythic = Color3.fromRGB(233, 30, 99),
}

UITheme.RARITY_BORDER_THICKNESS = {
	Common = 2,
	Uncommon = 2,
	Rare = 3,
	Epic = 3,
	Legendary = 3,
	Mythic = 3,
}

UITheme.RARITY_ORDER = { "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common" }

-- Style constants
UITheme.BORDER_WIDTH = 3
UITheme.CORNER_RADIUS = 10
UITheme.BORDER_3D_HEIGHT = 3

-- Fonts
UITheme.FONT_BOLD = Enum.Font.GothamBold
UITheme.FONT_REGULAR = Enum.Font.Gotham

-- === CHUNKY HELPERS ===

function UITheme.createChunkyButton(parent: GuiObject, config: { [string]: any }): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = config.size or UDim2.new(0, 120, 0, 40)
	btn.AnchorPoint = config.anchorPoint or Vector2.new(0.5, 0.5)
	btn.Position = config.position or UDim2.new(0.5, 0, 0.5, 0)
	btn.BackgroundColor3 = config.color or UITheme.BTN_GREEN
	btn.Text = string.upper(config.text or "Button")
	btn.TextColor3 = config.textColor or UITheme.TEXT_ON_BTN
	btn.TextSize = config.textSize or 14
	btn.Font = UITheme.FONT_BOLD
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, config.cornerRadius or 8)
	corner.Parent = btn

	-- 3D shadow (border-bottom effect)
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow3D"
	shadow.Size = UDim2.new(1, 0, 0, UITheme.BORDER_3D_HEIGHT)
	shadow.Position = UDim2.new(0, 0, 1, 0)
	shadow.BackgroundColor3 = config.shadowColor or UITheme.BTN_GREEN_SHADOW
	shadow.BorderSizePixel = 0
	shadow.Parent = btn

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, config.cornerRadius or 8)
	shadowCorner.Parent = shadow

	-- Press animation (push down effect)
	local originalPos = config.position or UDim2.new(0.5, 0, 0.5, 0)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.05), {
			Position = originalPos + UDim2.new(0, 0, 0, 2),
		}):Play()
		shadow.Visible = false
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = originalPos,
		}):Play()
		shadow.Visible = true
	end)

	return btn
end

function UITheme.createCard(parent: GuiObject, config: { [string]: any }): Frame
	local card = Instance.new("Frame")
	card.Name = config.name or "Card"
	card.Size = config.size or UDim2.new(1, 0, 0, 64)
	card.BackgroundColor3 = UITheme.BG_CARD
	card.BorderSizePixel = 0
	card.LayoutOrder = config.layoutOrder or 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UITheme.CORNER_RADIUS)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = config.borderColor or UITheme.PRIMARY
	stroke.Thickness = config.borderThickness or UITheme.BORDER_WIDTH
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = card

	return card
end

function UITheme.createListItem(parent: GuiObject, config: { [string]: any }): { [string]: any }
	local height = config.height or 60

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.BackgroundColor3 = UITheme.BG_CARD
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UITheme.CORNER_RADIUS)
	corner.Parent = frame

	-- Chunky left border bar
	local leftBorder = Instance.new("Frame")
	leftBorder.Name = "LeftBorder"
	leftBorder.Size = UDim2.new(0, 4, 1, -12)
	leftBorder.Position = UDim2.new(0, 6, 0, 6)
	leftBorder.BackgroundColor3 = config.borderColor or UITheme.PRIMARY
	leftBorder.BackgroundTransparency = config.borderTransparency or 0
	leftBorder.BorderSizePixel = 0
	leftBorder.Parent = frame

	local borderCorner = Instance.new("UICorner")
	borderCorner.CornerRadius = UDim.new(0, 2)
	borderCorner.Parent = leftBorder

	-- Full card outline
	local stroke = Instance.new("UIStroke")
	stroke.Color = config.borderColor or UITheme.PRIMARY
	stroke.Thickness = 2
	stroke.Transparency = 0.7
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = frame

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

	-- Dim overlay behind panel
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = UITheme.BG_OVERLAY_COLOR
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = UITheme.BG_SECONDARY
	bg.BackgroundTransparency = 0
	bg.BorderSizePixel = 0
	bg.Parent = screenGui

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundColor3 = UITheme.BG_PRIMARY
	header.BorderSizePixel = 0
	header.Parent = bg

	-- Bottom border on header
	local headerBorder = Instance.new("Frame")
	headerBorder.Size = UDim2.new(1, 0, 0, UITheme.BORDER_WIDTH)
	headerBorder.Position = UDim2.new(0, 0, 1, 0)
	headerBorder.BackgroundColor3 = UITheme.PRIMARY
	headerBorder.BorderSizePixel = 0
	headerBorder.Parent = header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 16, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = string.upper(config.title or "Panel")
	titleLabel.TextColor3 = UITheme.TEXT_PRIMARY
	titleLabel.TextSize = 18
	titleLabel.Font = UITheme.FONT_BOLD
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header

	-- Close button (chunky style)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -46, 0, 10)
	closeBtn.BackgroundColor3 = UITheme.BTN_RED
	closeBtn.Text = "X"
	closeBtn.TextColor3 = UITheme.TEXT_ON_BTN
	closeBtn.TextSize = 16
	closeBtn.Font = UITheme.FONT_BOLD
	closeBtn.AutoButtonColor = false
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = header

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn

	local closeShadow = Instance.new("Frame")
	closeShadow.Size = UDim2.new(1, 0, 0, 2)
	closeShadow.Position = UDim2.new(0, 0, 1, 0)
	closeShadow.BackgroundColor3 = UITheme.BTN_RED_SHADOW
	closeShadow.BorderSizePixel = 0
	closeShadow.Parent = closeBtn

	local closeShadowCorner = Instance.new("UICorner")
	closeShadowCorner.CornerRadius = UDim.new(0, 8)
	closeShadowCorner.Parent = closeShadow

	closeBtn.MouseButton1Click:Connect(function()
		if config.onClose then
			config.onClose()
		end
	end)

	-- Content scroll
	local contentScroll = Instance.new("ScrollingFrame")
	contentScroll.Name = "Content"
	contentScroll.Size = UDim2.new(1, -20, 1, -66)
	contentScroll.Position = UDim2.new(0, 10, 0, 60)
	contentScroll.BackgroundTransparency = 1
	contentScroll.ScrollBarThickness = 6
	contentScroll.ScrollBarImageColor3 = UITheme.PRIMARY
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
		overlay = overlay,
		background = bg,
		contentScroll = contentScroll,
		headerFrame = header,
		titleLabel = titleLabel,
	}
end

function UITheme.tweenOpen(screenGui: ScreenGui)
	screenGui.Enabled = true
	local bg = screenGui:FindFirstChild("Background")
	local overlay = screenGui:FindFirstChild("Overlay")
	if not bg then return end

	bg.BackgroundTransparency = 1
	if overlay then
		overlay.BackgroundTransparency = 1
		TweenService:Create(overlay, TweenInfo.new(0.2), {
			BackgroundTransparency = UITheme.BG_OVERLAY_TRANSPARENCY,
		}):Play()
	end

	local content = bg:FindFirstChild("Content")
	local contentStartY = nil
	if content then
		contentStartY = content.Position.Y.Offset
		content.Position = UDim2.new(content.Position.X.Scale, content.Position.X.Offset, content.Position.Y.Scale, contentStartY + 50)
	end

	TweenService:Create(bg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	}):Play()

	if content and contentStartY then
		TweenService:Create(content, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(content.Position.X.Scale, content.Position.X.Offset, content.Position.Y.Scale, contentStartY),
		}):Play()
	end
end

function UITheme.tweenClose(screenGui: ScreenGui, callback: (() -> ())?)
	local bg = screenGui:FindFirstChild("Background")
	local overlay = screenGui:FindFirstChild("Overlay")

	if not bg then
		screenGui.Enabled = false
		if callback then callback() end
		return
	end

	TweenService:Create(bg, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	}):Play()

	if overlay then
		TweenService:Create(overlay, TweenInfo.new(0.15), {
			BackgroundTransparency = 1,
		}):Play()
	end

	task.delay(0.15, function()
		screenGui.Enabled = false
		if callback then callback() end
	end)
end

function UITheme.createActionButton(parent: GuiObject, config: { [string]: any }): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = config.size or UDim2.new(0, 70, 0, 30)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = UDim2.new(0.5, 0, 0.5, 0)
	btn.BackgroundColor3 = config.color or UITheme.BTN_GREEN
	btn.Text = string.upper(config.text or "OK")
	btn.TextColor3 = config.textColor or UITheme.TEXT_ON_BTN
	btn.TextSize = 11
	btn.Font = UITheme.FONT_BOLD
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	-- 3D shadow
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow3D"
	shadow.Size = UDim2.new(1, 0, 0, 2)
	shadow.Position = UDim2.new(0, 0, 1, 0)
	shadow.BackgroundColor3 = config.shadowColor or UITheme.BTN_GREEN_SHADOW
	shadow.BorderSizePixel = 0
	shadow.Parent = btn

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 6)
	shadowCorner.Parent = shadow

	return btn
end

function UITheme.createSectionDivider(parent: GuiObject, config: { [string]: any }): Frame
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, 0, 0, 28)
	divider.BackgroundTransparency = 1
	divider.Parent = parent

	local leftLine = Instance.new("Frame")
	leftLine.Size = UDim2.new(0.25, 0, 0, 2)
	leftLine.Position = UDim2.new(0, 0, 0.5, 0)
	leftLine.BackgroundColor3 = config.color or UITheme.PRIMARY
	leftLine.BackgroundTransparency = 0.5
	leftLine.BorderSizePixel = 0
	leftLine.Parent = divider

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.Position = UDim2.new(0.25, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = config.text or "SECTION"
	label.TextColor3 = config.color or UITheme.TEXT_PRIMARY
	label.TextSize = 11
	label.Font = UITheme.FONT_BOLD
	label.Parent = divider

	local rightLine = Instance.new("Frame")
	rightLine.Size = UDim2.new(0.25, 0, 0, 2)
	rightLine.Position = UDim2.new(0.75, 0, 0.5, 0)
	rightLine.BackgroundColor3 = config.color or UITheme.PRIMARY
	rightLine.BackgroundTransparency = 0.5
	rightLine.BorderSizePixel = 0
	rightLine.Parent = divider

	return divider
end

return UITheme
