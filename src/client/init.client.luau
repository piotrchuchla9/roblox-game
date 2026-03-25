local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUD = require(script.HUD)
local GardenUI = require(script.GardenUI)
local DropAnimation = require(script.DropAnimation)
local CollectionBook = require(script.CollectionBook)
local ShopUI = require(script.ShopUI)
local DailyRewardsUI = require(script.DailyRewardsUI)
local LeaderboardUI = require(script.LeaderboardUI)

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

-- Wire bottom bar buttons
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.defer(function()
	local hud = playerGui:WaitForChild("HUD", 5)
	if not hud then return end
	local bottomBar = hud:WaitForChild("BottomBar", 5)
	if not bottomBar then return end

	bottomBar.ShopButton.MouseButton1Click:Connect(function()
		ShopUI.toggle()
	end)

	bottomBar.CollectionButton.MouseButton1Click:Connect(function()
		CollectionBook.toggle()
		if playerData then CollectionBook.update(playerData) end
	end)

	bottomBar.DailyButton.MouseButton1Click:Connect(function()
		DailyRewardsUI.toggle()
		if playerData then DailyRewardsUI.update(playerData) end
	end)

	bottomBar.FreeSeedButton.MouseButton1Click:Connect(function()
		remotesFolder.ClaimFreeSeed:FireServer()
	end)
end)

print("[Client] Grow a Brainrot client initialized")
