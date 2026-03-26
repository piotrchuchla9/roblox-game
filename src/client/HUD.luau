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
		{ name = "Garden", icon = "\u{1F331}", order = 1, accent = UITheme.GREEN },
		{ name = "Shop", icon = "\u{1F6D2}", order = 2, accent = UITheme.MAGENTA },
		{ name = "Collection", icon = "\u{1F4D6}", order = 3, accent = UITheme.MAGENTA, center = true },
		{ name = "Daily", icon = "\u{1F381}", order = 4, accent = UITheme.YELLOW },
		{ name = "FreeSeed", icon = "\u{1F31F}", order = 5, accent = UITheme.GREEN },
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
