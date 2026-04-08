local Players = game:GetService("Players")
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
	topBar.Size = UDim2.new(1, 0, 0, 52)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = UITheme.BG_PRIMARY
	topBar.BorderSizePixel = 0
	topBar.Parent = screenGui

	-- Bottom chunky border
	local topBarBorder = Instance.new("Frame")
	topBarBorder.Name = "Border"
	topBarBorder.Size = UDim2.new(1, 0, 0, 3)
	topBarBorder.Position = UDim2.new(0, 0, 1, 0)
	topBarBorder.BackgroundColor3 = UITheme.PRIMARY
	topBarBorder.BorderSizePixel = 0
	topBarBorder.Parent = topBar

	-- Currency pills
	local pillContainer = Instance.new("Frame")
	pillContainer.Name = "Pills"
	pillContainer.Size = UDim2.new(1, -20, 0, 38)
	pillContainer.Position = UDim2.new(0, 10, 0, 7)
	pillContainer.BackgroundTransparency = 1
	pillContainer.Parent = topBar

	local pillLayout = Instance.new("UIListLayout")
	pillLayout.FillDirection = Enum.FillDirection.Horizontal
	pillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pillLayout.Padding = UDim.new(0, 8)
	pillLayout.Parent = pillContainer

	local function createPill(name: string, label: string, accentColor: Color3, iconEmoji: string, layoutOrder: number): TextLabel
		local pill = Instance.new("Frame")
		pill.Name = name
		pill.Size = UDim2.new(0, 130, 1, 0)
		pill.BackgroundColor3 = UITheme.BG_PRIMARY
		pill.BorderSizePixel = 0
		pill.LayoutOrder = layoutOrder
		pill.Parent = pillContainer

		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(0, 10)
		pillCorner.Parent = pill

		local pillStroke = Instance.new("UIStroke")
		pillStroke.Color = accentColor
		pillStroke.Thickness = 2
		pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		pillStroke.Parent = pill

		local pillPad = Instance.new("UIPadding")
		pillPad.PaddingLeft = UDim.new(0, 8)
		pillPad.PaddingRight = UDim.new(0, 8)
		pillPad.Parent = pill

		-- Icon
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Name = "Icon"
		iconLbl.Size = UDim2.new(0, 20, 1, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text = iconEmoji
		iconLbl.TextSize = 16
		iconLbl.Font = Enum.Font.SourceSans
		iconLbl.Parent = pill

		-- Category label
		local catLabel = Instance.new("TextLabel")
		catLabel.Name = "Category"
		catLabel.Size = UDim2.new(1, -24, 0, 12)
		catLabel.Position = UDim2.new(0, 24, 0, 2)
		catLabel.BackgroundTransparency = 1
		catLabel.Text = string.upper(label)
		catLabel.TextColor3 = accentColor
		catLabel.TextSize = 9
		catLabel.Font = UITheme.FONT_BOLD
		catLabel.TextXAlignment = Enum.TextXAlignment.Left
		catLabel.Parent = pill

		-- Value
		local valLabel = Instance.new("TextLabel")
		valLabel.Name = "Value"
		valLabel.Size = UDim2.new(1, -24, 0, 18)
		valLabel.Position = UDim2.new(0, 24, 0, 14)
		valLabel.BackgroundTransparency = 1
		valLabel.Text = "0"
		valLabel.TextColor3 = UITheme.TEXT_PRIMARY
		valLabel.TextSize = 16
		valLabel.Font = UITheme.FONT_BOLD
		valLabel.TextXAlignment = Enum.TextXAlignment.Left
		valLabel.Parent = pill

		return valLabel
	end

	seedsValue = createPill("SeedsPill", "Seeds", UITheme.BTN_GREEN, "\u{1F331}", 1)
	goldenSeedsValue = createPill("GoldenPill", "Golden", UITheme.BTN_ORANGE, "\u{2B50}", 2)
	collectionValue = createPill("CollectionPill", "Collection", UITheme.BTN_BLUE, "\u{1F4D6}", 3)

	-- === BOTTOM TAB BAR ===
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, 0, 0, 66)
	tabBar.Position = UDim2.new(0, 0, 1, -66)
	tabBar.BackgroundColor3 = UITheme.BG_PRIMARY
	tabBar.BorderSizePixel = 0
	tabBar.Parent = screenGui

	-- Top chunky border
	local tabBarBorder = Instance.new("Frame")
	tabBarBorder.Size = UDim2.new(1, 0, 0, 3)
	tabBarBorder.Position = UDim2.new(0, 0, 0, 0)
	tabBarBorder.BackgroundColor3 = UITheme.PRIMARY
	tabBarBorder.BorderSizePixel = 0
	tabBarBorder.Parent = tabBar

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding = UDim.new(0, 4)
	tabLayout.Parent = tabBar

	local tabs = {
		{ name = "Garden", icon = "\u{1F331}", order = 1, color = UITheme.BTN_GREEN, shadow = UITheme.BTN_GREEN_SHADOW },
		{ name = "Collection", icon = "\u{1F4D6}", order = 2, color = UITheme.BTN_ORANGE, shadow = UITheme.BTN_ORANGE_SHADOW, center = true },
		{ name = "Daily", icon = "\u{1F381}", order = 3, color = UITheme.BTN_BLUE, shadow = UITheme.BTN_BLUE_SHADOW },
		{ name = "FreeSeed", icon = "\u{1F31F}", order = 4, color = UITheme.BTN_GREEN, shadow = UITheme.BTN_GREEN_SHADOW },
		{ name = "Social", icon = "\u{1F465}", order = 5, color = UITheme.BTN_BLUE, shadow = UITheme.BTN_BLUE_SHADOW },
	}

	for _, tabInfo in tabs do
		local isCenter = tabInfo.center == true

		local tabFrame = Instance.new("TextButton")
		tabFrame.Name = tabInfo.name .. "Tab"
		tabFrame.Size = isCenter and UDim2.new(0.17, 0, 1, 12) or UDim2.new(0.15, 0, 1, -8)
		tabFrame.Position = isCenter and UDim2.new(0, 0, 0, -8) or UDim2.new(0, 0, 0, 0)
		tabFrame.BackgroundColor3 = isCenter and tabInfo.color or UITheme.BG_PRIMARY
		tabFrame.Text = ""
		tabFrame.LayoutOrder = tabInfo.order
		tabFrame.AutoButtonColor = false
		tabFrame.BorderSizePixel = 0
		tabFrame.Parent = tabBar

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, isCenter and 12 or 0)
		tabCorner.Parent = tabFrame

		if isCenter then
			-- 3D shadow for center button
			local shadow = Instance.new("Frame")
			shadow.Size = UDim2.new(1, 0, 0, 3)
			shadow.Position = UDim2.new(0, 0, 1, 0)
			shadow.BackgroundColor3 = tabInfo.shadow
			shadow.BorderSizePixel = 0
			shadow.Parent = tabFrame

			local shadowCorner = Instance.new("UICorner")
			shadowCorner.CornerRadius = UDim.new(0, 12)
			shadowCorner.Parent = shadow

			-- Outline
			local stroke = Instance.new("UIStroke")
			stroke.Color = tabInfo.shadow
			stroke.Thickness = 2
			stroke.Parent = tabFrame
		end

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(1, 0, 0, 28)
		iconLabel.Position = UDim2.new(0, 0, 0, isCenter and 6 or 6)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = tabInfo.icon
		iconLabel.TextSize = 22
		iconLabel.TextTransparency = isCenter and 0 or 0.2
		iconLabel.Font = Enum.Font.SourceSans
		iconLabel.Parent = tabFrame

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Label"
		textLabel.Size = UDim2.new(1, 0, 0, 14)
		textLabel.Position = UDim2.new(0, 0, 1, isCenter and -22 or -18)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = string.upper(tabInfo.name == "FreeSeed" and "FREE" or tabInfo.name)
		textLabel.TextColor3 = isCenter and UITheme.TEXT_ON_BTN or UITheme.TEXT_SECONDARY
		textLabel.TextSize = 9
		textLabel.Font = UITheme.FONT_BOLD
		textLabel.Parent = tabFrame

		-- Press animation
		local originalSize = tabFrame.Size
		tabFrame.MouseButton1Down:Connect(function()
			TweenService:Create(tabFrame, TweenInfo.new(0.05), {
				Size = isCenter and UDim2.new(0.16, 0, 1, 10) or UDim2.new(0.14, 0, 1, -10),
			}):Play()
		end)
		tabFrame.MouseButton1Up:Connect(function()
			TweenService:Create(tabFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = originalSize,
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
