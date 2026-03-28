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
local SocialUI = require(script.SocialUI)
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
SocialUI.create()

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

wireTab("Social", function()
	SocialUI.toggle()
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
	toastFrame.BackgroundColor3 = UITheme.BG_PRIMARY
	toastFrame.BackgroundTransparency = 0.1
	toastFrame.Parent = toast

	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 10)
	toastCorner.Parent = toastFrame

	local toastStroke = Instance.new("UIStroke")
	toastStroke.Color = UITheme.BTN_GREEN
	toastStroke.Thickness = 2
	toastStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	toastStroke.Parent = toastFrame

	local toastLabel = Instance.new("TextLabel")
	toastLabel.Size = UDim2.new(1, 0, 1, 0)
	toastLabel.BackgroundTransparency = 1
	toastLabel.Text = "🌱 +1 Seed!"
	toastLabel.TextColor3 = UITheme.BTN_GREEN
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

-- Trade ProximityPrompt on other player characters
local function setupTradePrompt(character: Model)
	-- Don't add to self
	if character == Players.LocalPlayer.Character then return end

	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then return end

	-- Check if prompt already exists
	if humanoidRootPart:FindFirstChild("TradePrompt") then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TradePrompt"
	prompt.ActionText = "Trade"
	prompt.ObjectText = ""
	prompt.MaxActivationDistance = 8
	prompt.HoldDuration = 0
	prompt.Parent = humanoidRootPart

	prompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer == Players.LocalPlayer then
			-- Get the owner of this character
			for _, otherPlayer in Players:GetPlayers() do
				if otherPlayer.Character == character then
					remotesFolder.InitiateTrade:FireServer(otherPlayer.UserId)
					break
				end
			end
		end
	end)
end

-- Setup prompts for existing and new characters
for _, otherPlayer in Players:GetPlayers() do
	if otherPlayer ~= Players.LocalPlayer and otherPlayer.Character then
		setupTradePrompt(otherPlayer.Character)
	end
	otherPlayer.CharacterAdded:Connect(setupTradePrompt)
end

Players.PlayerAdded:Connect(function(otherPlayer)
	otherPlayer.CharacterAdded:Connect(setupTradePrompt)
end)

print("[Client] Grow a Brainrot client initialized")
