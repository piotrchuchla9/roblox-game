local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local GardenUI = {}

local screenGui: ScreenGui
local gardenFrame: Frame

function GardenUI.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GardenUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	gardenFrame = Instance.new("Frame")
	gardenFrame.Name = "GardenFrame"
	gardenFrame.Size = UDim2.new(0, 400, 0, 300)
	gardenFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
	gardenFrame.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
	gardenFrame.BackgroundTransparency = 0.2
	gardenFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = gardenFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "Your Garden"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 22
	title.Font = Enum.Font.GothamBold
	title.Parent = gardenFrame

	-- Upgrade button
	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Name = "UpgradeButton"
	upgradeBtn.Size = UDim2.new(0, 120, 0, 30)
	upgradeBtn.Position = UDim2.new(1, -130, 0, 0)
	upgradeBtn.BackgroundColor3 = Color3.fromRGB(180, 130, 30)
	upgradeBtn.Text = "Upgrade (" .. Config.BED_UPGRADE_COST .. ")"
	upgradeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	upgradeBtn.TextSize = 13
	upgradeBtn.Font = Enum.Font.GothamBold
	upgradeBtn.Parent = gardenFrame

	local upgCorner = Instance.new("UICorner")
	upgCorner.CornerRadius = UDim.new(0, 6)
	upgCorner.Parent = upgradeBtn

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	upgradeBtn.MouseButton1Click:Connect(function()
		remotesFolder.UpgradeGarden:FireServer()
	end)
end

function GardenUI.update(data)
	if not gardenFrame then return end

	for _, child in gardenFrame:GetChildren() do
		if child:IsA("TextButton") and child.Name:match("^Bed") then
			child:Destroy()
		end
	end

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

	for i = 1, data.garden.bedCount do
		local bed = data.garden.beds[i]
		local row = math.ceil(i / 4)
		local col = ((i - 1) % 4) + 1

		local btn = Instance.new("TextButton")
		btn.Name = "Bed" .. i
		btn.Size = UDim2.new(0, 80, 0, 80)
		btn.Position = UDim2.new(0, 10 + (col - 1) * 95, 0, 35 + (row - 1) * 95)
		btn.Parent = gardenFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		if bed.seedId == nil then
			btn.BackgroundColor3 = Color3.fromRGB(80, 50, 30)
			btn.Text = "Plant"
			btn.TextColor3 = Color3.fromRGB(200, 200, 200)
			btn.TextSize = 14
			btn.Font = Enum.Font.GothamBold
			btn.MouseButton1Click:Connect(function()
				remotesFolder.PlantSeed:FireServer(i, "Common")
			end)
		elseif bed.isReady then
			btn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
			btn.Text = "Harvest!"
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextSize = 14
			btn.Font = Enum.Font.GothamBold
			btn.MouseButton1Click:Connect(function()
				remotesFolder.HarvestBed:FireServer(i)
			end)
		else
			-- Growing — show countdown
			local elapsed = os.time() - (bed.plantedAt or os.time())
			local remaining = math.max(0, (bed.growthTime or 0) - elapsed)

			btn.BackgroundColor3 = Color3.fromRGB(120, 100, 40)
			btn.Text = remaining > 0 and (remaining .. "s") or "..."
			btn.TextColor3 = Color3.fromRGB(200, 200, 100)
			btn.TextSize = 12
			btn.Font = Enum.Font.Gotham

			local waterBtn = Instance.new("TextButton")
			waterBtn.Name = "Water"
			waterBtn.Size = UDim2.new(1, 0, 0, 20)
			waterBtn.Position = UDim2.new(0, 0, 1, -20)
			waterBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
			waterBtn.Text = "Water"
			waterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			waterBtn.TextSize = 11
			waterBtn.Font = Enum.Font.GothamBold
			waterBtn.Parent = btn
			waterBtn.MouseButton1Click:Connect(function()
				remotesFolder.WaterBed:FireServer(i)
			end)
		end
	end

	-- Update upgrade button visibility
	local upgradeBtn = gardenFrame:FindFirstChild("UpgradeButton")
	if upgradeBtn then
		upgradeBtn.Visible = data.garden.bedCount < Config.MAX_BED_COUNT
	end
end

return GardenUI
