# UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite all client UI modules to Neon Chaos style with dark backgrounds, neon glow accents, fullscreen panels, list-view patterns, tab bar navigation, and smooth animations.

**Architecture:** New shared UITheme module provides colors, fonts, and builder functions (createListItem, createPanel, createTabBar, tweenOpen/tweenClose). Each UI module is rewritten to use UITheme helpers. HUD owns the tab bar and top currency bar. Panels are fullscreen overlays with consistent open/close animations.

**Tech Stack:** Roblox Luau, Instance API, TweenService, UIStroke, UIGradient, UICorner, UIPadding, UIListLayout

---

### Task 1: Create UITheme Module

**Files:**
- Create: `src/client/UITheme.luau`

- [ ] **Step 1: Create the UITheme module with color and font constants**

```lua
-- src/client/UITheme.luau
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

return UITheme
```

- [ ] **Step 2: Add createNeonBorder helper**

Add before the `return` statement:

```lua
function UITheme.createNeonBorder(parent: GuiObject, color: Color3, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 2
	stroke.Transparency = 0.3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end
```

- [ ] **Step 3: Add createListItem helper**

Add before the `return` statement. This builds the standard list row used by Garden and Collection:

```lua
--[[
	config = {
		borderColor: Color3,
		borderTransparency: number? (default 0),
		icon: string (emoji text),
		iconTransparency: number? (default 0),
		height: number? (default 56),
	}
	Returns: { frame: Frame, iconLabel: TextLabel, infoFrame: Frame, actionFrame: Frame }
]]
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

	-- Left color border (thin frame on the left edge)
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

	-- Icon
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

	-- Info area (center, flexible)
	local infoFrame = Instance.new("Frame")
	infoFrame.Name = "Info"
	infoFrame.Size = UDim2.new(1, -120, 1, 0)
	infoFrame.Position = UDim2.new(0, 44, 0, 0)
	infoFrame.BackgroundTransparency = 1
	infoFrame.Parent = frame

	-- Action area (right side)
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
```

- [ ] **Step 4: Add panel creation and animation helpers**

Add before the `return` statement:

```lua
--[[
	Creates a fullscreen panel with header bar and scrollable content area.
	config = {
		name: string,
		title: string (e.g. "🛒 SHOP"),
		onClose: () -> (),
	}
	Returns: { screenGui: ScreenGui, contentScroll: ScrollingFrame, headerFrame: Frame }
]]
function UITheme.createPanel(playerGui: Instance, config: { [string]: any }): { [string]: any }
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = config.name
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Full-screen background
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = UITheme.BG_PANEL
	bg.BackgroundTransparency = 0.05
	bg.Parent = screenGui

	-- Header bar
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

	-- Title
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

	-- Close button
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

	-- Scrollable content area
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

	-- Start state
	bg.BackgroundTransparency = 1
	local content = bg:FindFirstChild("Content") or screenGui:FindFirstChild("Content")
	if content then
		content.Position = UDim2.new(content.Position.X.Scale, content.Position.X.Offset, content.Position.Y.Scale, content.Position.Y.Offset + 50)
	end

	-- Animate background
	TweenService:Create(bg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.05,
	}):Play()

	-- Animate content slide up
	if content then
		TweenService:Create(content, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(content.Position.X.Scale, content.Position.X.Offset, content.Position.Y.Scale, content.Position.Y.Offset - 50),
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
```

- [ ] **Step 5: Add action button helper**

Add before the `return` statement:

```lua
--[[
	Creates a small pill-shaped action button.
	config = {
		text: string,
		color: Color3,
		textColor: Color3? (default white),
		size: UDim2? (default auto),
	}
]]
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

--[[
	Creates a section divider with centered label.
	config = {
		text: string,
		color: Color3,
	}
]]
function UITheme.createSectionDivider(parent: GuiObject, config: { [string]: any }): Frame
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, 0, 0, 20)
	divider.BackgroundTransparency = 1
	divider.Parent = parent

	-- Left line
	local leftLine = Instance.new("Frame")
	leftLine.Size = UDim2.new(0.35, 0, 0, 1)
	leftLine.Position = UDim2.new(0, 0, 0.5, 0)
	leftLine.BackgroundColor3 = config.color
	leftLine.BackgroundTransparency = 0.6
	leftLine.BorderSizePixel = 0
	leftLine.Parent = divider

	-- Label
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.3, 0, 1, 0)
	label.Position = UDim2.new(0.35, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = config.text
	label.TextColor3 = config.color
	label.TextSize = 9
	label.Font = UITheme.FONT_BOLD
	label.Parent = divider

	-- Right line
	local rightLine = Instance.new("Frame")
	rightLine.Size = UDim2.new(0.35, 0, 0, 1)
	rightLine.Position = UDim2.new(0.65, 0, 0.5, 0)
	rightLine.BackgroundColor3 = config.color
	rightLine.BackgroundTransparency = 0.6
	rightLine.BorderSizePixel = 0
	rightLine.Parent = divider

	return divider
end
```

- [ ] **Step 6: Commit**

```bash
git add src/client/UITheme.luau
git commit -m "feat: add UITheme module with neon chaos colors and UI helpers"
```

---

### Task 2: Rewrite HUD (Top Bar + Tab Bar)

**Files:**
- Modify: `src/client/HUD.luau` (complete rewrite)

- [ ] **Step 1: Rewrite HUD.luau with new top bar currency pills**

Replace the entire contents of `src/client/HUD.luau`:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UITheme = require(script.Parent.UITheme)

local HUD = {}

local screenGui: ScreenGui
local seedsValue: TextLabel
local goldenSeedsValue: TextLabel
local collectionValue: TextLabel
local tabButtons: { [string]: Frame } = {}

function HUD.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 20
	screenGui.Parent = playerGui

	-- === TOP BAR ===
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 50)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = UITheme.BG_PRIMARY
	topBar.BackgroundTransparency = 0.1
	topBar.BorderSizePixel = 0
	topBar.Parent = screenGui

	-- Bottom glow line
	local topBarStroke = Instance.new("Frame")
	topBarStroke.Name = "GlowLine"
	topBarStroke.Size = UDim2.new(1, 0, 0, 1)
	topBarStroke.Position = UDim2.new(0, 0, 1, 0)
	topBarStroke.BackgroundColor3 = UITheme.MAGENTA
	topBarStroke.BackgroundTransparency = 0.7
	topBarStroke.BorderSizePixel = 0
	topBarStroke.Parent = topBar

	-- Currency pills container
	local pillContainer = Instance.new("Frame")
	pillContainer.Name = "Pills"
	pillContainer.Size = UDim2.new(1, -20, 0, 36)
	pillContainer.Position = UDim2.new(0, 10, 0, 7)
	pillContainer.BackgroundTransparency = 1
	pillContainer.Parent = topBar

	local pillLayout = Instance.new("UIListLayout")
	pillLayout.FillDirection = Enum.FillDirection.Horizontal
	pillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pillLayout.Padding = UDim.new(0, 10)
	pillLayout.Parent = pillContainer

	-- Helper to create currency pill
	local function createPill(name: string, label: string, accent: Color3, layoutOrder: number): TextLabel
		local pill = Instance.new("Frame")
		pill.Name = name
		pill.Size = UDim2.new(0, 120, 1, 0)
		pill.BackgroundColor3 = accent
		pill.BackgroundTransparency = 0.88
		pill.LayoutOrder = layoutOrder
		pill.Parent = pillContainer

		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(0, 12)
		pillCorner.Parent = pill

		local pillStroke = Instance.new("UIStroke")
		pillStroke.Color = accent
		pillStroke.Thickness = 1
		pillStroke.Transparency = 0.5
		pillStroke.Parent = pill

		local pillPad = Instance.new("UIPadding")
		pillPad.PaddingLeft = UDim.new(0, 10)
		pillPad.PaddingRight = UDim.new(0, 10)
		pillPad.Parent = pill

		local catLabel = Instance.new("TextLabel")
		catLabel.Name = "Category"
		catLabel.Size = UDim2.new(1, 0, 0, 12)
		catLabel.Position = UDim2.new(0, 0, 0, 2)
		catLabel.BackgroundTransparency = 1
		catLabel.Text = string.upper(label)
		catLabel.TextColor3 = accent
		catLabel.TextTransparency = 0.4
		catLabel.TextSize = 9
		catLabel.Font = UITheme.FONT_BOLD
		catLabel.TextXAlignment = Enum.TextXAlignment.Left
		catLabel.Parent = pill

		local valLabel = Instance.new("TextLabel")
		valLabel.Name = "Value"
		valLabel.Size = UDim2.new(1, 0, 0, 18)
		valLabel.Position = UDim2.new(0, 0, 0, 14)
		valLabel.BackgroundTransparency = 1
		valLabel.Text = "0"
		valLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		valLabel.TextSize = 16
		valLabel.Font = UITheme.FONT_BOLD
		valLabel.TextXAlignment = Enum.TextXAlignment.Left
		valLabel.Parent = pill

		return valLabel
	end

	seedsValue = createPill("SeedsPill", "Seeds", UITheme.YELLOW, 1)
	goldenSeedsValue = createPill("GoldenPill", "Golden", UITheme.ORANGE, 2)
	collectionValue = createPill("CollectionPill", "Collection", UITheme.CYAN, 3)

	-- === BOTTOM TAB BAR ===
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, 0, 0, 64)
	tabBar.Position = UDim2.new(0, 0, 1, -64)
	tabBar.BackgroundColor3 = UITheme.BG_PRIMARY
	tabBar.BackgroundTransparency = 0.05
	tabBar.BorderSizePixel = 0
	tabBar.Parent = screenGui

	-- Top glow line
	local tabBarLine = Instance.new("Frame")
	tabBarLine.Size = UDim2.new(1, 0, 0, 2)
	tabBarLine.Position = UDim2.new(0, 0, 0, 0)
	tabBarLine.BackgroundColor3 = UITheme.MAGENTA
	tabBarLine.BackgroundTransparency = 0.3
	tabBarLine.BorderSizePixel = 0
	tabBarLine.Parent = tabBar

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding = UDim.new(0, 4)
	tabLayout.Parent = tabBar

	local tabs = {
		{ name = "Garden", icon = "🌱", order = 1, accent = UITheme.GREEN },
		{ name = "Shop", icon = "🛒", order = 2, accent = UITheme.MAGENTA },
		{ name = "Collection", icon = "📖", order = 3, accent = UITheme.MAGENTA, center = true },
		{ name = "Daily", icon = "🎁", order = 4, accent = UITheme.YELLOW },
		{ name = "FreeSeed", icon = "🌟", order = 5, accent = UITheme.GREEN },
	}

	for _, tabInfo in tabs do
		local isCenter = tabInfo.center == true

		local tabFrame = Instance.new("TextButton")
		tabFrame.Name = tabInfo.name .. "Tab"
		tabFrame.Size = isCenter and UDim2.new(0.2, 0, 1, 16) or UDim2.new(0.18, 0, 1, -8)
		tabFrame.Position = isCenter and UDim2.new(0, 0, 0, -12) or UDim2.new(0, 0, 0, 0)
		tabFrame.BackgroundTransparency = isCenter and 0 or 1
		tabFrame.BackgroundColor3 = isCenter and UITheme.MAGENTA or UITheme.BG_PRIMARY
		tabFrame.Text = ""
		tabFrame.LayoutOrder = tabInfo.order
		tabFrame.AutoButtonColor = false
		tabFrame.Parent = tabBar

		if isCenter then
			local centerCorner = Instance.new("UICorner")
			centerCorner.CornerRadius = UDim.new(0, 14)
			centerCorner.Parent = tabFrame

			local centerStroke = Instance.new("UIStroke")
			centerStroke.Color = UITheme.MAGENTA
			centerStroke.Thickness = 2
			centerStroke.Transparency = 0.2
			centerStroke.Parent = tabFrame

			-- Gradient on center button
			local grad = Instance.new("UIGradient")
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 150)),
			})
			grad.Rotation = 90
			grad.Parent = tabFrame
		end

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(1, 0, 0, 28)
		iconLabel.Position = UDim2.new(0, 0, 0, isCenter and 6 or 4)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = tabInfo.icon
		iconLabel.TextSize = 22
		iconLabel.TextTransparency = isCenter and 0 or 0.3
		iconLabel.Font = Enum.Font.SourceSans
		iconLabel.Parent = tabFrame

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Label"
		textLabel.Size = UDim2.new(1, 0, 0, 14)
		textLabel.Position = UDim2.new(0, 0, 1, isCenter and -20 or -18)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = string.upper(tabInfo.name == "FreeSeed" and "FREE" or tabInfo.name)
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextTransparency = isCenter and 0 or 0.4
		textLabel.TextSize = 9
		textLabel.Font = UITheme.FONT_BOLD
		textLabel.Parent = tabFrame

		-- Press animation
		tabFrame.MouseButton1Down:Connect(function()
			TweenService:Create(tabFrame, TweenInfo.new(0.05), {
				Size = isCenter and UDim2.new(0.19, 0, 1, 14) or UDim2.new(0.17, 0, 1, -10),
			}):Play()
		end)
		tabFrame.MouseButton1Up:Connect(function()
			TweenService:Create(tabFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = isCenter and UDim2.new(0.2, 0, 1, 16) or UDim2.new(0.18, 0, 1, -8),
			}):Play()
		end)

		tabButtons[tabInfo.name] = tabFrame
	end
end

function HUD.getTabButton(name: string): TextButton?
	return tabButtons[name]
end

function HUD.update(data)
	if seedsValue then
		seedsValue.Text = tostring(data.currencies.seeds)
	end
	if goldenSeedsValue then
		goldenSeedsValue.Text = tostring(data.currencies.goldenSeeds)
	end
	if collectionValue then
		collectionValue.Text = tostring(data.collectionCount)
	end
end

return HUD
```

- [ ] **Step 2: Commit**

```bash
git add src/client/HUD.luau
git commit -m "feat: rewrite HUD with neon currency pills and tab bar navigation"
```

---

### Task 3: Rewrite GardenUI as List View

**Files:**
- Modify: `src/client/GardenUI.luau` (complete rewrite)

- [ ] **Step 1: Rewrite GardenUI.luau with list view and progress bars**

Replace the entire contents of `src/client/GardenUI.luau`:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(script.Parent.UITheme)

local GardenUI = {}

local panel = nil -- { screenGui, contentScroll, ... }
local visible = false
local activeTweens: { Tween } = {}

function GardenUI.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	panel = UITheme.createPanel(playerGui, {
		name = "GardenUI",
		title = "🌱 YOUR GARDEN",
		onClose = function()
			GardenUI.toggle()
		end,
	})
end

local function clearActiveTweens()
	for _, tween in activeTweens do
		tween:Cancel()
	end
	table.clear(activeTweens)
end

local function clearContent()
	clearActiveTweens()
	for _, child in panel.contentScroll:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

function GardenUI.update(data)
	if not panel then return end
	clearContent()

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

	-- Subtitle with bed count
	local subtitle = Instance.new("Frame")
	subtitle.Size = UDim2.new(1, 0, 0, 30)
	subtitle.BackgroundTransparency = 1
	subtitle.LayoutOrder = 0
	subtitle.Parent = panel.contentScroll

	local subtitleText = Instance.new("TextLabel")
	subtitleText.Size = UDim2.new(0.5, 0, 1, 0)
	subtitleText.BackgroundTransparency = 1
	subtitleText.Text = data.garden.bedCount .. "/" .. Config.MAX_BED_COUNT .. " beds"
	subtitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	subtitleText.TextTransparency = 0.5
	subtitleText.TextSize = 12
	subtitleText.Font = UITheme.FONT_REGULAR
	subtitleText.TextXAlignment = Enum.TextXAlignment.Left
	subtitleText.Parent = subtitle

	-- Upgrade button (if not maxed)
	if data.garden.bedCount < Config.MAX_BED_COUNT then
		local upgradeBtn = UITheme.createActionButton(subtitle, {
			text = "UPGRADE " .. Config.BED_UPGRADE_COST,
			color = UITheme.YELLOW,
			textColor = Color3.fromRGB(10, 10, 26),
			size = UDim2.new(0, 110, 0, 26),
		})
		upgradeBtn.Position = UDim2.new(1, -55, 0.5, 0)
		upgradeBtn.MouseButton1Click:Connect(function()
			remotesFolder.UpgradeGarden:FireServer()
		end)
	end

	-- Bed list items
	for i = 1, Config.MAX_BED_COUNT do
		if i <= data.garden.bedCount then
			local bed = data.garden.beds[i]

			if bed == nil or bed.seedId == nil then
				-- Empty bed
				local item = UITheme.createListItem(panel.contentScroll, {
					borderColor = UITheme.MAGENTA,
					borderTransparency = 0.5,
					icon = "🕳️",
					iconTransparency = 0.4,
				})
				item.frame.LayoutOrder = i

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Text = "Tap to Plant"
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
				label.TextTransparency = 0.5
				label.TextSize = 12
				label.Font = UITheme.FONT_BOLD
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = item.infoFrame

				-- Make entire row clickable
				local clickBtn = Instance.new("TextButton")
				clickBtn.Size = UDim2.new(1, 0, 1, 0)
				clickBtn.BackgroundTransparency = 1
				clickBtn.Text = ""
				clickBtn.Parent = item.frame
				clickBtn.MouseButton1Click:Connect(function()
					remotesFolder.PlantSeed:FireServer(i, "Common")
				end)

			elseif bed.isReady then
				-- Ready bed
				local item = UITheme.createListItem(panel.contentScroll, {
					borderColor = UITheme.GREEN,
					icon = "✨",
				})
				item.frame.LayoutOrder = i

				-- Glow stroke on frame
				local glowStroke = Instance.new("UIStroke")
				glowStroke.Color = UITheme.GREEN
				glowStroke.Thickness = 1
				glowStroke.Transparency = 0.7
				glowStroke.Parent = item.frame

				-- Pulse animation
				local pulseIn = TweenService:Create(glowStroke,
					TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ Transparency = 0.3 }
				)
				pulseIn:Play()
				table.insert(activeTweens, pulseIn)

				local readyLabel = Instance.new("TextLabel")
				readyLabel.Size = UDim2.new(1, 0, 1, 0)
				readyLabel.BackgroundTransparency = 1
				readyLabel.Text = "READY!"
				readyLabel.TextColor3 = UITheme.GREEN
				readyLabel.TextSize = 14
				readyLabel.Font = UITheme.FONT_BOLD
				readyLabel.TextXAlignment = Enum.TextXAlignment.Left
				readyLabel.Parent = item.infoFrame

				local harvestBtn = UITheme.createActionButton(item.actionFrame, {
					text = "HARVEST",
					color = UITheme.GREEN,
				})
				harvestBtn.MouseButton1Click:Connect(function()
					remotesFolder.HarvestBed:FireServer(i)
				end)

				-- Also clickable on row
				local clickBtn = Instance.new("TextButton")
				clickBtn.Size = UDim2.new(1, 0, 1, 0)
				clickBtn.BackgroundTransparency = 1
				clickBtn.Text = ""
				clickBtn.ZIndex = 0
				clickBtn.Parent = item.frame
				clickBtn.MouseButton1Click:Connect(function()
					remotesFolder.HarvestBed:FireServer(i)
				end)
			else
				-- Growing bed
				local item = UITheme.createListItem(panel.contentScroll, {
					borderColor = UITheme.YELLOW,
					icon = "🌿",
				})
				item.frame.LayoutOrder = i

				local elapsed = os.time() - (bed.plantedAt or os.time())
				local totalGrowth = bed.growthTime or 60
				local remaining = math.max(0, totalGrowth - elapsed)
				local progress = math.clamp(elapsed / totalGrowth, 0, 1)

				-- Info labels
				local growLabel = Instance.new("TextLabel")
				growLabel.Size = UDim2.new(1, 0, 0, 16)
				growLabel.Position = UDim2.new(0, 0, 0, 4)
				growLabel.BackgroundTransparency = 1
				growLabel.Text = "Growing"
				growLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				growLabel.TextTransparency = 0.3
				growLabel.TextSize = 11
				growLabel.Font = UITheme.FONT_REGULAR
				growLabel.TextXAlignment = Enum.TextXAlignment.Left
				growLabel.Parent = item.infoFrame

				local timeLabel = Instance.new("TextLabel")
				timeLabel.Size = UDim2.new(1, 0, 0, 18)
				timeLabel.Position = UDim2.new(0, 0, 0, 18)
				timeLabel.BackgroundTransparency = 1
				timeLabel.Text = remaining .. "s"
				timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				timeLabel.TextSize = 14
				timeLabel.Font = UITheme.FONT_BOLD
				timeLabel.TextXAlignment = Enum.TextXAlignment.Left
				timeLabel.Parent = item.infoFrame

				-- Progress bar at bottom of frame
				local trackFrame = Instance.new("Frame")
				trackFrame.Name = "Track"
				trackFrame.Size = UDim2.new(1, 0, 0, 3)
				trackFrame.Position = UDim2.new(0, 0, 1, -1)
				trackFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				trackFrame.BackgroundTransparency = 0.9
				trackFrame.BorderSizePixel = 0
				trackFrame.Parent = item.frame

				local fillFrame = Instance.new("Frame")
				fillFrame.Name = "Fill"
				fillFrame.Size = UDim2.new(progress, 0, 1, 0)
				fillFrame.BackgroundColor3 = UITheme.YELLOW
				fillFrame.BorderSizePixel = 0
				fillFrame.Parent = trackFrame

				local fillGrad = Instance.new("UIGradient")
				fillGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, UITheme.YELLOW),
					ColorSequenceKeypoint.new(1, UITheme.ORANGE),
				})
				fillGrad.Parent = fillFrame

				local fillCorner = Instance.new("UICorner")
				fillCorner.CornerRadius = UDim.new(0, 2)
				fillCorner.Parent = fillFrame

				-- Water button
				local waterCooldown = 0
				if bed.wateredAt then
					waterCooldown = math.max(0, Config.WATER_COOLDOWN - (os.time() - bed.wateredAt))
				end

				local waterBtn = UITheme.createActionButton(item.actionFrame, {
					text = waterCooldown > 0 and (waterCooldown .. "s") or "💧 WATER",
					color = waterCooldown > 0 and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(0, 136, 255),
				})

				if waterCooldown <= 0 then
					waterBtn.MouseButton1Click:Connect(function()
						remotesFolder.WaterBed:FireServer(i)
					end)
				end
			end
		else
			-- Locked bed
			local item = UITheme.createListItem(panel.contentScroll, {
				borderColor = Color3.fromRGB(255, 255, 255),
				borderTransparency = 0.85,
				icon = "🔒",
				iconTransparency = 0.7,
			})
			item.frame.LayoutOrder = i
			item.frame.BackgroundTransparency = 0.6

			local lockLabel = Instance.new("TextLabel")
			lockLabel.Size = UDim2.new(1, 0, 1, 0)
			lockLabel.BackgroundTransparency = 1
			lockLabel.Text = "Locked — " .. Config.BED_UPGRADE_COST .. " seeds"
			lockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			lockLabel.TextTransparency = 0.7
			lockLabel.TextSize = 11
			lockLabel.Font = UITheme.FONT_REGULAR
			lockLabel.TextXAlignment = Enum.TextXAlignment.Left
			lockLabel.Parent = item.infoFrame
		end
	end
end

function GardenUI.toggle()
	visible = not visible
	if visible then
		UITheme.tweenOpen(panel.screenGui)
	else
		UITheme.tweenClose(panel.screenGui)
	end
end

function GardenUI.isVisible(): boolean
	return visible
end

return GardenUI
```

- [ ] **Step 2: Commit**

```bash
git add src/client/GardenUI.luau
git commit -m "feat: rewrite GardenUI as list view with progress bars and neon styling"
```

---

### Task 4: Rewrite CollectionBook as List View

**Files:**
- Modify: `src/client/CollectionBook.luau` (complete rewrite)

- [ ] **Step 1: Rewrite CollectionBook.luau with list view and rarity sections**

Replace the entire contents of `src/client/CollectionBook.luau`:

```lua
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
```

- [ ] **Step 2: Commit**

```bash
git add src/client/CollectionBook.luau
git commit -m "feat: rewrite CollectionBook as list view with rarity sections and neon borders"
```

---

### Task 5: Rewrite ShopUI as Fullscreen Panel

**Files:**
- Modify: `src/client/ShopUI.luau` (complete rewrite)

- [ ] **Step 1: Rewrite ShopUI.luau with fullscreen overlay and list items**

Replace the entire contents of `src/client/ShopUI.luau`:

```lua
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
		accent = UITheme.MAGENTA,
	},
	{
		key = "AUTO_HARVEST",
		name = "Auto-Harvest",
		desc = "Auto-collect ready brainrots",
		price = 149,
		icon = "⚡",
		accent = UITheme.CYAN,
	},
	{
		key = "DOUBLE_COLLECTION",
		name = "Double Collection",
		desc = "2x Seeds from selling",
		price = 99,
		icon = "💰",
		accent = UITheme.YELLOW,
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
		color = UITheme.MAGENTA,
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
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
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
		descLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		descLabel.TextTransparency = 0.5
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
		color = UITheme.ORANGE,
	})
	dpDivider.LayoutOrder = layoutOrder
	layoutOrder += 1

	for _, dp in DEV_PRODUCT_INFO do
		local item = UITheme.createListItem(contentScroll, {
			borderColor = UITheme.ORANGE,
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
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 13
		nameLabel.Font = UITheme.FONT_BOLD
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = item.infoFrame

		-- Price button
		local priceBtn = UITheme.createActionButton(item.actionFrame, {
			text = dp.price .. " R$",
			color = UITheme.ORANGE,
			textColor = Color3.fromRGB(10, 10, 26),
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

return ShopUI
```

- [ ] **Step 2: Commit**

```bash
git add src/client/ShopUI.luau
git commit -m "feat: rewrite ShopUI as fullscreen panel with neon list items"
```

---

### Task 6: Rewrite DailyRewardsUI as Fullscreen Panel

**Files:**
- Modify: `src/client/DailyRewardsUI.luau` (complete rewrite)

- [ ] **Step 1: Rewrite DailyRewardsUI.luau with streak circles and neon styling**

Replace the entire contents of `src/client/DailyRewardsUI.luau`:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(script.Parent.UITheme)

local DailyRewardsUI = {}

local panel = nil
local visible = false
local streakLabel: TextLabel
local rewardLabel: TextLabel
local claimBtn: TextButton
local streakDots: { Frame } = {}
local pulseTween: Tween? = nil

function DailyRewardsUI.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	panel = UITheme.createPanel(playerGui, {
		name = "DailyRewardsUI",
		title = "🎁 DAILY REWARD",
		onClose = function()
			DailyRewardsUI.toggle()
		end,
	})

	local contentScroll = panel.contentScroll

	-- Center container
	local centerFrame = Instance.new("Frame")
	centerFrame.Size = UDim2.new(1, 0, 0, 280)
	centerFrame.BackgroundTransparency = 1
	centerFrame.LayoutOrder = 1
	centerFrame.Parent = contentScroll

	-- "STREAK" label
	local streakTitle = Instance.new("TextLabel")
	streakTitle.Size = UDim2.new(1, 0, 0, 20)
	streakTitle.Position = UDim2.new(0, 0, 0, 20)
	streakTitle.BackgroundTransparency = 1
	streakTitle.Text = "STREAK"
	streakTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	streakTitle.TextTransparency = 0.4
	streakTitle.TextSize = 12
	streakTitle.Font = UITheme.FONT_BOLD
	streakTitle.Parent = centerFrame

	-- Streak number
	streakLabel = Instance.new("TextLabel")
	streakLabel.Size = UDim2.new(1, 0, 0, 45)
	streakLabel.Position = UDim2.new(0, 0, 0, 40)
	streakLabel.BackgroundTransparency = 1
	streakLabel.Text = "0"
	streakLabel.TextColor3 = UITheme.MAGENTA
	streakLabel.TextSize = 36
	streakLabel.Font = UITheme.FONT_BOLD
	streakLabel.Parent = centerFrame

	local streakStroke = Instance.new("UIStroke")
	streakStroke.Color = UITheme.MAGENTA
	streakStroke.Thickness = 1
	streakStroke.Transparency = 0.5
	streakStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	streakStroke.Parent = streakLabel

	-- Streak dots (7 circles)
	local dotsFrame = Instance.new("Frame")
	dotsFrame.Size = UDim2.new(1, 0, 0, 24)
	dotsFrame.Position = UDim2.new(0, 0, 0, 95)
	dotsFrame.BackgroundTransparency = 1
	dotsFrame.Parent = centerFrame

	local dotsLayout = Instance.new("UIListLayout")
	dotsLayout.FillDirection = Enum.FillDirection.Horizontal
	dotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dotsLayout.Padding = UDim.new(0, 8)
	dotsLayout.Parent = dotsFrame

	for i = 1, Config.DAILY_REWARD_MAX_STREAK do
		local dot = Instance.new("Frame")
		dot.Name = "Day" .. i
		dot.Size = UDim2.new(0, 20, 0, 20)
		dot.BackgroundColor3 = UITheme.BG_CARD
		dot.LayoutOrder = i
		dot.Parent = dotsFrame

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = dot

		local dotStroke = Instance.new("UIStroke")
		dotStroke.Name = "DotStroke"
		dotStroke.Color = UITheme.MAGENTA
		dotStroke.Thickness = 1
		dotStroke.Transparency = 0.6
		dotStroke.Parent = dot

		table.insert(streakDots, dot)
	end

	-- Reward preview
	rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(1, 0, 0, 30)
	rewardLabel.Position = UDim2.new(0, 0, 0, 140)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = "+50 seeds"
	rewardLabel.TextColor3 = UITheme.YELLOW
	rewardLabel.TextSize = 20
	rewardLabel.Font = UITheme.FONT_BOLD
	rewardLabel.Parent = centerFrame

	-- Claim button
	claimBtn = Instance.new("TextButton")
	claimBtn.Size = UDim2.new(0.7, 0, 0, 46)
	claimBtn.Position = UDim2.new(0.15, 0, 0, 195)
	claimBtn.BackgroundColor3 = UITheme.GREEN
	claimBtn.Text = "CLAIM!"
	claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimBtn.TextSize = 18
	claimBtn.Font = UITheme.FONT_BOLD
	claimBtn.AutoButtonColor = false
	claimBtn.Parent = centerFrame

	local claimCorner = Instance.new("UICorner")
	claimCorner.CornerRadius = UDim.new(0, 10)
	claimCorner.Parent = claimBtn

	local claimStroke = Instance.new("UIStroke")
	claimStroke.Name = "ClaimStroke"
	claimStroke.Color = UITheme.GREEN
	claimStroke.Thickness = 2
	claimStroke.Transparency = 0.4
	claimStroke.Parent = claimBtn

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	claimBtn.MouseButton1Click:Connect(function()
		remotesFolder.ClaimDailyReward:FireServer()
	end)
end

function DailyRewardsUI.update(data)
	if not panel then return end

	local streak = data.dailyReward.streak
	local nextReward = Config.DAILY_REWARD_BASE + ((streak + 1) * Config.DAILY_REWARD_STREAK_BONUS)

	-- Update streak number + color
	streakLabel.Text = tostring(streak)
	-- Cycle color based on streak: low = magenta, high = cyan
	local t = math.clamp(streak / Config.DAILY_REWARD_MAX_STREAK, 0, 1)
	streakLabel.TextColor3 = UITheme.MAGENTA:Lerp(UITheme.CYAN, t)

	-- Update dots
	if pulseTween then
		pulseTween:Cancel()
		pulseTween = nil
	end

	for i, dot in streakDots do
		local dotStroke = dot:FindFirstChild("DotStroke")
		if i <= streak then
			-- Completed: filled gradient
			dot.BackgroundColor3 = UITheme.MAGENTA:Lerp(UITheme.CYAN, (i - 1) / Config.DAILY_REWARD_MAX_STREAK)
			dot.BackgroundTransparency = 0.2
			if dotStroke then
				dotStroke.Transparency = 0.3
				dotStroke.Color = UITheme.CYAN
			end
		elseif i == streak + 1 then
			-- Current day: pulse
			dot.BackgroundColor3 = UITheme.MAGENTA
			dot.BackgroundTransparency = 0.5
			if dotStroke then
				dotStroke.Transparency = 0.3
				dotStroke.Color = UITheme.MAGENTA
				pulseTween = TweenService:Create(dotStroke,
					TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ Transparency = 0 }
				)
				pulseTween:Play()
			end
		else
			-- Future: dim
			dot.BackgroundColor3 = UITheme.BG_CARD
			dot.BackgroundTransparency = 0.5
			if dotStroke then
				dotStroke.Transparency = 0.7
				dotStroke.Color = UITheme.MAGENTA
			end
		end
	end

	-- Claim state
	local elapsed = os.time() - data.dailyReward.lastClaimed
	local canClaim = elapsed >= Config.DAILY_REWARD_COOLDOWN

	if canClaim then
		rewardLabel.Text = "+" .. nextReward .. " seeds"
		claimBtn.BackgroundColor3 = UITheme.GREEN
		claimBtn.Text = "CLAIM!"
		local claimStroke = claimBtn:FindFirstChild("ClaimStroke")
		if claimStroke then
			claimStroke.Color = UITheme.GREEN
			claimStroke.Transparency = 0.4
		end
	else
		local remaining = Config.DAILY_REWARD_COOLDOWN - elapsed
		local hours = math.floor(remaining / 3600)
		local mins = math.floor((remaining % 3600) / 60)
		rewardLabel.Text = "Next: +" .. nextReward .. " seeds"
		claimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		claimBtn.Text = string.format("Wait %dh %dm", hours, mins)
		local claimStroke = claimBtn:FindFirstChild("ClaimStroke")
		if claimStroke then
			claimStroke.Color = Color3.fromRGB(60, 60, 60)
			claimStroke.Transparency = 0.7
		end
	end
end

function DailyRewardsUI.toggle()
	visible = not visible
	if visible then
		UITheme.tweenOpen(panel.screenGui)
	else
		UITheme.tweenClose(panel.screenGui)
	end
end

return DailyRewardsUI
```

- [ ] **Step 2: Commit**

```bash
git add src/client/DailyRewardsUI.luau
git commit -m "feat: rewrite DailyRewardsUI with streak circles and neon fullscreen panel"
```

---

### Task 7: Enhance DropAnimation

**Files:**
- Modify: `src/client/DropAnimation.luau`

- [ ] **Step 1: Rewrite DropAnimation.luau with enhanced neon visuals**

Replace the entire contents of `src/client/DropAnimation.luau`:

```lua
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
```

- [ ] **Step 2: Commit**

```bash
git add src/client/DropAnimation.luau
git commit -m "feat: enhance DropAnimation with neon strokes, particles, and screen shake"
```

---

### Task 8: Rewrite init.client.luau to Wire Tab Bar

**Files:**
- Modify: `src/client/init.client.luau`

- [ ] **Step 1: Rewrite init.client.luau to use tab bar from HUD**

Replace the entire contents of `src/client/init.client.luau`:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local HUD = require(script.HUD)
local GardenUI = require(script.GardenUI)
local DropAnimation = require(script.DropAnimation)
local CollectionBook = require(script.CollectionBook)
local ShopUI = require(script.ShopUI)
local DailyRewardsUI = require(script.DailyRewardsUI)
local LeaderboardUI = require(script.LeaderboardUI)
local UITheme = require(script.UITheme)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotesFolder then
	warn("[Client] Remotes folder not found!")
	return
end

-- Initialize all UI
HUD.create()
GardenUI.create()
CollectionBook.create()
ShopUI.create()
DailyRewardsUI.create()

-- Player data cache
local playerData = nil

-- Central data sync
remotesFolder.UpdatePlayerData.OnClientEvent:Connect(function(data)
	playerData = data
	HUD.update(data)
	GardenUI.update(data)
	CollectionBook.update(data)
	DailyRewardsUI.update(data)
	LeaderboardUI.update(data)
end)

-- Drop animation
remotesFolder.PlayDropAnimation.OnClientEvent:Connect(function(brainrot, isRareDrop)
	DropAnimation.play(brainrot, isRareDrop)
end)

-- Wire tab bar buttons
local function wireTab(tabName: string, callback: () -> ())
	local tab = HUD.getTabButton(tabName)
	if tab then
		tab.MouseButton1Click:Connect(callback)
	end
end

wireTab("Garden", function()
	GardenUI.toggle()
	if playerData then GardenUI.update(playerData) end
end)

wireTab("Shop", function()
	ShopUI.toggle()
end)

wireTab("Collection", function()
	CollectionBook.toggle()
	if playerData then CollectionBook.update(playerData) end
end)

wireTab("Daily", function()
	DailyRewardsUI.toggle()
	if playerData then DailyRewardsUI.update(playerData) end
end)

wireTab("FreeSeed", function()
	remotesFolder.ClaimFreeSeed:FireServer()

	-- Toast notification
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local toast = Instance.new("ScreenGui")
	toast.Name = "Toast"
	toast.DisplayOrder = 50
	toast.Parent = playerGui

	local toastFrame = Instance.new("Frame")
	toastFrame.Size = UDim2.new(0, 180, 0, 36)
	toastFrame.Position = UDim2.new(0.5, -90, 0, -40)
	toastFrame.BackgroundColor3 = UITheme.BG_CARD
	toastFrame.BackgroundTransparency = 0.1
	toastFrame.Parent = toast

	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 10)
	toastCorner.Parent = toastFrame

	UITheme.createNeonBorder(toastFrame, UITheme.GREEN, 1)

	local toastLabel = Instance.new("TextLabel")
	toastLabel.Size = UDim2.new(1, 0, 1, 0)
	toastLabel.BackgroundTransparency = 1
	toastLabel.Text = "🌱 +1 Seed!"
	toastLabel.TextColor3 = UITheme.GREEN
	toastLabel.TextSize = 14
	toastLabel.Font = UITheme.FONT_BOLD
	toastLabel.Parent = toastFrame

	-- Slide down
	TweenService:Create(toastFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -90, 0, 60),
	}):Play()

	-- Fade out after 1.5s
	task.delay(1.5, function()
		TweenService:Create(toastFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(toastLabel, TweenInfo.new(0.3), {
			TextTransparency = 1,
		}):Play()
		task.delay(0.3, function()
			toast:Destroy()
		end)
	end)
end)

print("[Client] Grow a Brainrot client initialized")
```

- [ ] **Step 2: Commit**

```bash
git add src/client/init.client.luau
git commit -m "feat: rewire init.client with tab bar navigation and toast notifications"
```

---

### Task 9: Final Verification in Roblox Studio

- [ ] **Step 1: Sync to Roblox Studio and verify**

Use the Roblox Studio MCP to run the game in play mode and verify:
1. Top bar shows 3 currency pills with neon styling
2. Bottom tab bar shows 5 tabs with center Collection button raised
3. Tapping Garden tab opens fullscreen garden with list view beds
4. Tapping Shop tab opens fullscreen shop with gamepass/boost list items
5. Tapping Collection tab opens fullscreen collection with rarity sections
6. Tapping Daily tab opens fullscreen daily rewards with streak dots
7. Tapping Free Seed shows toast notification
8. Panel open/close animations work (fade + slide)
9. Garden bed states display correctly (empty/growing/ready/locked)
10. Drop animation shows with enhanced neon effects

- [ ] **Step 2: Final commit with all changes**

```bash
git add -A
git commit -m "feat: complete Neon Chaos UI redesign"
```
