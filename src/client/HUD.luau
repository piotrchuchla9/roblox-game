local Players = game:GetService("Players")

local HUD = {}

local screenGui: ScreenGui
local seedsLabel: TextLabel
local goldenSeedsLabel: TextLabel
local collectionLabel: TextLabel

function HUD.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Top bar
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 50)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	topBar.BackgroundTransparency = 0.3
	topBar.Parent = screenGui

	seedsLabel = Instance.new("TextLabel")
	seedsLabel.Name = "Seeds"
	seedsLabel.Size = UDim2.new(0, 150, 1, 0)
	seedsLabel.Position = UDim2.new(0, 10, 0, 0)
	seedsLabel.BackgroundTransparency = 1
	seedsLabel.Text = "Seeds: 0"
	seedsLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	seedsLabel.TextSize = 20
	seedsLabel.Font = Enum.Font.GothamBold
	seedsLabel.TextXAlignment = Enum.TextXAlignment.Left
	seedsLabel.Parent = topBar

	goldenSeedsLabel = Instance.new("TextLabel")
	goldenSeedsLabel.Name = "GoldenSeeds"
	goldenSeedsLabel.Size = UDim2.new(0, 180, 1, 0)
	goldenSeedsLabel.Position = UDim2.new(0, 170, 0, 0)
	goldenSeedsLabel.BackgroundTransparency = 1
	goldenSeedsLabel.Text = "Golden Seeds: 0"
	goldenSeedsLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
	goldenSeedsLabel.TextSize = 20
	goldenSeedsLabel.Font = Enum.Font.GothamBold
	goldenSeedsLabel.TextXAlignment = Enum.TextXAlignment.Left
	goldenSeedsLabel.Parent = topBar

	collectionLabel = Instance.new("TextLabel")
	collectionLabel.Name = "Collection"
	collectionLabel.Size = UDim2.new(0, 150, 1, 0)
	collectionLabel.Position = UDim2.new(0, 360, 0, 0)
	collectionLabel.BackgroundTransparency = 1
	collectionLabel.Text = "Collection: 0"
	collectionLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
	collectionLabel.TextSize = 20
	collectionLabel.Font = Enum.Font.GothamBold
	collectionLabel.TextXAlignment = Enum.TextXAlignment.Left
	collectionLabel.Parent = topBar

	-- Bottom bar
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.Size = UDim2.new(1, 0, 0, 60)
	bottomBar.Position = UDim2.new(0, 0, 1, -60)
	bottomBar.BackgroundTransparency = 1
	bottomBar.Parent = screenGui

	local buttons = { "Shop", "Collection", "Daily", "FreeSeed" }
	for i, name in buttons do
		local btn = Instance.new("TextButton")
		btn.Name = name .. "Button"
		btn.Size = UDim2.new(0, 90, 0, 40)
		btn.Position = UDim2.new(0.5, -190 + (i - 1) * 100, 0, 10)
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = name == "FreeSeed" and "Free Seed" or name
		btn.TextSize = 16
		btn.Font = Enum.Font.GothamBold
		btn.Parent = bottomBar

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = btn
	end
end

function HUD.update(data)
	if seedsLabel then
		seedsLabel.Text = "Seeds: " .. tostring(data.currencies.seeds)
	end
	if goldenSeedsLabel then
		goldenSeedsLabel.Text = "Golden Seeds: " .. tostring(data.currencies.goldenSeeds)
	end
	if collectionLabel then
		collectionLabel.Text = "Collection: " .. tostring(data.collectionCount)
	end
end

return HUD
