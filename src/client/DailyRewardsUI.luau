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
	streakTitle.TextColor3 = UITheme.TEXT_PRIMARY
	streakTitle.TextTransparency = 0
	streakTitle.TextSize = 12
	streakTitle.Font = UITheme.FONT_BOLD
	streakTitle.Parent = centerFrame

	-- Streak number
	streakLabel = Instance.new("TextLabel")
	streakLabel.Size = UDim2.new(1, 0, 0, 45)
	streakLabel.Position = UDim2.new(0, 0, 0, 40)
	streakLabel.BackgroundTransparency = 1
	streakLabel.Text = "0"
	streakLabel.TextColor3 = UITheme.BTN_PINK
	streakLabel.TextSize = 36
	streakLabel.Font = UITheme.FONT_BOLD
	streakLabel.Parent = centerFrame

	local streakStroke = Instance.new("UIStroke")
	streakStroke.Color = UITheme.BTN_PINK
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
		dot.BackgroundColor3 = UITheme.BG_SECONDARY
		dot.LayoutOrder = i
		dot.Parent = dotsFrame

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = dot

		local dotStroke = Instance.new("UIStroke")
		dotStroke.Name = "DotStroke"
		dotStroke.Color = UITheme.PRIMARY
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
	rewardLabel.TextColor3 = UITheme.BTN_ORANGE
	rewardLabel.TextSize = 20
	rewardLabel.Font = UITheme.FONT_BOLD
	rewardLabel.Parent = centerFrame

	-- Claim button
	claimBtn = Instance.new("TextButton")
	claimBtn.Size = UDim2.new(0.7, 0, 0, 46)
	claimBtn.Position = UDim2.new(0.15, 0, 0, 195)
	claimBtn.BackgroundColor3 = UITheme.BTN_ORANGE
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
	claimStroke.Color = UITheme.BTN_ORANGE
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
	local t = math.clamp(streak / Config.DAILY_REWARD_MAX_STREAK, 0, 1)
	streakLabel.TextColor3 = UITheme.BTN_PINK:Lerp(UITheme.BTN_BLUE, t)

	-- Update dots
	if pulseTween then
		pulseTween:Cancel()
		pulseTween = nil
	end

	for i, dot in streakDots do
		local dotStroke = dot:FindFirstChild("DotStroke")
		if i <= streak then
			-- Completed: filled gradient
			dot.BackgroundColor3 = UITheme.PRIMARY:Lerp(UITheme.SECONDARY, (i - 1) / Config.DAILY_REWARD_MAX_STREAK)
			dot.BackgroundTransparency = 0.2
			if dotStroke then
				dotStroke.Transparency = 0.3
				dotStroke.Color = UITheme.SECONDARY
			end
		elseif i == streak + 1 then
			-- Current day: pulse
			dot.BackgroundColor3 = UITheme.BTN_PINK
			dot.BackgroundTransparency = 0.5
			if dotStroke then
				dotStroke.Transparency = 0.3
				dotStroke.Color = UITheme.BTN_PINK
				pulseTween = TweenService:Create(dotStroke,
					TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ Transparency = 0 }
				)
				pulseTween:Play()
			end
		else
			-- Future: dim
			dot.BackgroundColor3 = UITheme.BG_SECONDARY
			dot.BackgroundTransparency = 0.5
			if dotStroke then
				dotStroke.Transparency = 0.7
				dotStroke.Color = Color3.fromRGB(200, 200, 200)
			end
		end
	end

	-- Claim state
	local elapsed = os.time() - data.dailyReward.lastClaimed
	local canClaim = elapsed >= Config.DAILY_REWARD_COOLDOWN

	if canClaim then
		rewardLabel.Text = "+" .. nextReward .. " seeds"
		claimBtn.BackgroundColor3 = UITheme.BTN_ORANGE
		claimBtn.Text = "CLAIM!"
		local cs = claimBtn:FindFirstChild("ClaimStroke")
		if cs then
			cs.Color = UITheme.BTN_ORANGE
			cs.Transparency = 0.4
		end
	else
		local remaining = Config.DAILY_REWARD_COOLDOWN - elapsed
		local hours = math.floor(remaining / 3600)
		local mins = math.floor((remaining % 3600) / 60)
		rewardLabel.Text = "Next: +" .. nextReward .. " seeds"
		claimBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		claimBtn.Text = string.format("Wait %dh %dm", hours, mins)
		local cs = claimBtn:FindFirstChild("ClaimStroke")
		if cs then
			cs.Color = Color3.fromRGB(200, 200, 200)
			cs.Transparency = 0.7
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
