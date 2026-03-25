local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotDatabase = require(ReplicatedStorage.Shared.BrainrotDatabase)

local CollectionBook = {}

local RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(50, 120, 255),
	Epic = Color3.fromRGB(180, 50, 255),
	Legendary = Color3.fromRGB(255, 200, 0),
	Mythic = Color3.fromRGB(255, 50, 50),
}

local RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

local screenGui: ScreenGui
local visible = false

function CollectionBook.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CollectionBook"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "BookFrame"
	frame.Size = UDim2.new(0, 500, 0, 400)
	frame.Position = UDim2.new(0.5, -250, 0.5, -200)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "Brainrot Collection"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 22
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = frame
	closeBtn.MouseButton1Click:Connect(function()
		CollectionBook.toggle()
	end)

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 6)
	closeBtnCorner.Parent = closeBtn

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "BrainrotList"
	scroll.Size = UDim2.new(1, -20, 1, -50)
	scroll.Position = UDim2.new(0, 10, 0, 45)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.Parent = frame

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0, 90, 0, 100)
	layout.CellPadding = UDim2.new(0, 8, 0, 8)
	layout.Parent = scroll
end

function CollectionBook.update(data)
	if not screenGui then return end
	local scroll = screenGui.BookFrame.BrainrotList
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Sort brainrots by rarity
	local sorted = {}
	for _, brainrot in BrainrotDatabase do
		table.insert(sorted, brainrot)
	end
	table.sort(sorted, function(a, b)
		local aIdx = table.find(RARITY_ORDER, a.rarity) or 0
		local bIdx = table.find(RARITY_ORDER, b.rarity) or 0
		return aIdx < bIdx
	end)

	for _, brainrot in sorted do
		local owned = data.collection[brainrot.id]
		local color = RARITY_COLORS[brainrot.rarity] or RARITY_COLORS.Common

		local entry = Instance.new("Frame")
		entry.Name = brainrot.id
		entry.BackgroundColor3 = owned and color or Color3.fromRGB(40, 40, 40)
		entry.BackgroundTransparency = owned and 0.3 or 0.7
		entry.Parent = scroll

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 8)
		entryCorner.Parent = entry

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -4, 0.5, 0)
		nameLabel.Position = UDim2.new(0, 2, 0, 2)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = owned and brainrot.name or "???"
		nameLabel.TextColor3 = owned and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
		nameLabel.TextSize = 10
		nameLabel.TextWrapped = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Parent = entry

		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(1, 0, 0, 15)
		countLabel.Position = UDim2.new(0, 0, 0.5, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = owned and ("x" .. owned.count) or ""
		countLabel.TextColor3 = color
		countLabel.TextSize = 12
		countLabel.Font = Enum.Font.GothamBold
		countLabel.Parent = entry

		-- Sell button for duplicates (count >= 2)
		if owned and owned.count >= 2 then
			local sellBtn = Instance.new("TextButton")
			sellBtn.Name = "SellBtn"
			sellBtn.Size = UDim2.new(0.8, 0, 0, 18)
			sellBtn.Position = UDim2.new(0.1, 0, 1, -22)
			sellBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 30)
			sellBtn.Text = "Sell +" .. brainrot.sellValue
			sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			sellBtn.TextSize = 9
			sellBtn.Font = Enum.Font.GothamBold
			sellBtn.Parent = entry

			local sellCorner = Instance.new("UICorner")
			sellCorner.CornerRadius = UDim.new(0, 4)
			sellCorner.Parent = sellBtn

			sellBtn.MouseButton1Click:Connect(function()
				remotesFolder.SellBrainrot:FireServer(brainrot.id)
			end)
		end
	end

	local layout = scroll:FindFirstChildOfClass("UIGridLayout")
	if layout then
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end
end

function CollectionBook.toggle()
	visible = not visible
	screenGui.Enabled = visible
end

return CollectionBook
