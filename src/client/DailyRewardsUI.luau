local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local DailyRewardsUI = {}

local screenGui: ScreenGui
local visible = false
local claimBtn: TextButton
local streakLabel: TextLabel
local rewardLabel: TextLabel

function DailyRewardsUI.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DailyRewardsUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "DailyFrame"
	frame.Size = UDim2.new(0, 300, 0, 200)
	frame.Position = UDim2.new(0.5, -150, 0.5, -100)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 35)
	title.BackgroundTransparency = 1
	title.Text = "Daily Reward"
	title.TextColor3 = Color3.fromRGB(255, 220, 50)
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
		DailyRewardsUI.toggle()
	end)

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 6)
	closeBtnCorner.Parent = closeBtn

	streakLabel = Instance.new("TextLabel")
	streakLabel.Size = UDim2.new(1, 0, 0, 25)
	streakLabel.Position = UDim2.new(0, 0, 0, 45)
	streakLabel.BackgroundTransparency = 1
	streakLabel.Text = "Streak: 0 days"
	streakLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	streakLabel.TextSize = 16
	streakLabel.Font = Enum.Font.Gotham
	streakLabel.Parent = frame

	rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(1, 0, 0, 30)
	rewardLabel.Position = UDim2.new(0, 0, 0, 80)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = ""
	rewardLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	rewardLabel.TextSize = 20
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.Parent = frame

	claimBtn = Instance.new("TextButton")
	claimBtn.Size = UDim2.new(0.6, 0, 0, 40)
	claimBtn.Position = UDim2.new(0.2, 0, 0, 130)
	claimBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
	claimBtn.Text = "Claim!"
	claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimBtn.TextSize = 18
	claimBtn.Font = Enum.Font.GothamBold
	claimBtn.Parent = frame

	local claimBtnCorner = Instance.new("UICorner")
	claimBtnCorner.CornerRadius = UDim.new(0, 8)
	claimBtnCorner.Parent = claimBtn

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	claimBtn.MouseButton1Click:Connect(function()
		remotesFolder.ClaimDailyReward:FireServer()
	end)
end

function DailyRewardsUI.update(data)
	if not screenGui then return end

	local streak = data.dailyReward.streak
	streakLabel.Text = "Streak: " .. streak .. " days"

	local nextReward = Config.DAILY_REWARD_BASE + ((streak + 1) * Config.DAILY_REWARD_STREAK_BONUS)

	local elapsed = os.time() - data.dailyReward.lastClaimed
	local canClaim = elapsed >= Config.DAILY_REWARD_COOLDOWN

	if canClaim then
		rewardLabel.Text = "+" .. nextReward .. " Seeds"
		claimBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		claimBtn.Text = "Claim!"
	else
		local remaining = Config.DAILY_REWARD_COOLDOWN - elapsed
		local hours = math.floor(remaining / 3600)
		local mins = math.floor((remaining % 3600) / 60)
		rewardLabel.Text = "Next: +" .. nextReward .. " Seeds"
		claimBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		claimBtn.Text = string.format("Wait %dh %dm", hours, mins)
	end
end

function DailyRewardsUI.toggle()
	visible = not visible
	screenGui.Enabled = visible
end

return DailyRewardsUI
