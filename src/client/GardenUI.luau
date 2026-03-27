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
	subtitleText.TextColor3 = UITheme.TEXT_SECONDARY
	subtitleText.TextSize = 12
	subtitleText.Font = UITheme.FONT_REGULAR
	subtitleText.TextXAlignment = Enum.TextXAlignment.Left
	subtitleText.Parent = subtitle

	-- Upgrade button (if not maxed)
	if data.garden.bedCount < Config.MAX_BED_COUNT then
		local upgradeBtn = UITheme.createActionButton(subtitle, {
			text = "UPGRADE " .. Config.BED_UPGRADE_COST,
			color = UITheme.BTN_ORANGE,
			shadowColor = UITheme.BTN_ORANGE_SHADOW,
			textColor = UITheme.TEXT_ON_BTN,
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
					borderColor = UITheme.PRIMARY,
					borderTransparency = 0.5,
					icon = "🕳️",
					iconTransparency = 0.4,
				})
				item.frame.LayoutOrder = i

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Text = "Tap to Plant"
				label.TextColor3 = UITheme.TEXT_PRIMARY
				label.TextTransparency = 0
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
					borderColor = UITheme.BTN_GREEN,
					icon = "✨",
				})
				item.frame.LayoutOrder = i

				-- Glow stroke on frame
				local glowStroke = Instance.new("UIStroke")
				glowStroke.Color = UITheme.BTN_GREEN
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
				readyLabel.TextColor3 = UITheme.BTN_GREEN
				readyLabel.TextSize = 14
				readyLabel.Font = UITheme.FONT_BOLD
				readyLabel.TextXAlignment = Enum.TextXAlignment.Left
				readyLabel.Parent = item.infoFrame

				local harvestBtn = UITheme.createActionButton(item.actionFrame, {
					text = "HARVEST",
					color = UITheme.BTN_GREEN,
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
					borderColor = UITheme.BTN_ORANGE,
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
				growLabel.TextColor3 = UITheme.TEXT_PRIMARY
				growLabel.TextTransparency = 0
				growLabel.TextSize = 11
				growLabel.Font = UITheme.FONT_REGULAR
				growLabel.TextXAlignment = Enum.TextXAlignment.Left
				growLabel.Parent = item.infoFrame

				local timeLabel = Instance.new("TextLabel")
				timeLabel.Size = UDim2.new(1, 0, 0, 18)
				timeLabel.Position = UDim2.new(0, 0, 0, 18)
				timeLabel.BackgroundTransparency = 1
				timeLabel.Text = remaining .. "s"
				timeLabel.TextColor3 = UITheme.TEXT_PRIMARY
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
				fillFrame.BackgroundColor3 = UITheme.BTN_GREEN
				fillFrame.BorderSizePixel = 0
				fillFrame.Parent = trackFrame

				local fillGrad = Instance.new("UIGradient")
				fillGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, UITheme.BTN_GREEN),
					ColorSequenceKeypoint.new(1, UITheme.BTN_ORANGE),
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
					color = waterCooldown > 0 and Color3.fromRGB(200, 200, 200) or UITheme.BTN_BLUE,
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
				borderColor = Color3.fromRGB(189, 189, 189),
				borderTransparency = 0.5,
				icon = "🔒",
				iconTransparency = 0.7,
			})
			item.frame.LayoutOrder = i
			item.frame.BackgroundTransparency = 0.3

			local lockLabel = Instance.new("TextLabel")
			lockLabel.Size = UDim2.new(1, 0, 1, 0)
			lockLabel.BackgroundTransparency = 1
			lockLabel.Text = "Locked — " .. Config.BED_UPGRADE_COST .. " seeds"
			lockLabel.TextColor3 = UITheme.TEXT_SECONDARY
			lockLabel.TextTransparency = 0
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
