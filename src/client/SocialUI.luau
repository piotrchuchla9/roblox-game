-- SocialUI: Social tab with player search, teleport, and trade panel
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UITheme = require(script.Parent.UITheme)

local SocialUI = {}

local panel = nil
local visible = false
local searchBox: TextBox
local searchBtn: TextButton
local resultFrame: Frame
local homeBtn: TextButton

function SocialUI.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	panel = UITheme.createPanel(playerGui, {
		name = "SocialUI",
		title = "SOCIAL",
		onClose = function()
			SocialUI.toggle()
		end,
	})

	local contentScroll = panel.contentScroll
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

	-- Search section
	local searchDivider = UITheme.createSectionDivider(contentScroll, {
		text = "FIND PLAYER",
		color = UITheme.BTN_BLUE,
	})
	searchDivider.LayoutOrder = 1

	local searchFrame = Instance.new("Frame")
	searchFrame.Size = UDim2.new(1, 0, 0, 44)
	searchFrame.BackgroundTransparency = 1
	searchFrame.LayoutOrder = 2
	searchFrame.Parent = contentScroll

	searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(0.65, 0, 0, 38)
	searchBox.Position = UDim2.new(0, 0, 0, 0)
	searchBox.BackgroundColor3 = UITheme.BG_PRIMARY
	searchBox.PlaceholderText = "Enter username..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
	searchBox.Text = ""
	searchBox.TextColor3 = UITheme.TEXT_PRIMARY
	searchBox.TextSize = 14
	searchBox.Font = UITheme.FONT_BOLD
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchFrame

	local searchBoxCorner = Instance.new("UICorner")
	searchBoxCorner.CornerRadius = UDim.new(0, 8)
	searchBoxCorner.Parent = searchBox

	local searchBoxStroke = Instance.new("UIStroke")
	searchBoxStroke.Color = UITheme.SECONDARY
	searchBoxStroke.Thickness = 2
	searchBoxStroke.Parent = searchBox

	local searchBoxPad = Instance.new("UIPadding")
	searchBoxPad.PaddingLeft = UDim.new(0, 10)
	searchBoxPad.Parent = searchBox

	searchBtn = UITheme.createChunkyButton(searchFrame, {
		text = "SEARCH",
		color = UITheme.BTN_BLUE,
		shadowColor = UITheme.BTN_BLUE_SHADOW,
		size = UDim2.new(0.3, 0, 0, 38),
		position = UDim2.new(0.85, 0, 0, 19),
		anchorPoint = Vector2.new(0.5, 0.5),
		cornerRadius = 8,
	})

	searchBtn.MouseButton1Click:Connect(function()
		local targetName = searchBox.Text
		if #targetName < 1 then return end
		searchBtn.Text = "..."
		remotesFolder.SearchPlayer:FireServer(targetName)
	end)

	-- Result area
	resultFrame = Instance.new("Frame")
	resultFrame.Name = "Result"
	resultFrame.Size = UDim2.new(1, 0, 0, 50)
	resultFrame.BackgroundTransparency = 1
	resultFrame.LayoutOrder = 3
	resultFrame.Visible = false
	resultFrame.Parent = contentScroll

	-- Home button section
	local homeDivider = UITheme.createSectionDivider(contentScroll, {
		text = "NAVIGATION",
		color = UITheme.BTN_GREEN,
	})
	homeDivider.LayoutOrder = 10

	local homeFrame = Instance.new("Frame")
	homeFrame.Size = UDim2.new(1, 0, 0, 50)
	homeFrame.BackgroundTransparency = 1
	homeFrame.LayoutOrder = 11
	homeFrame.Parent = contentScroll

	homeBtn = UITheme.createChunkyButton(homeFrame, {
		text = "MY GARDEN",
		color = UITheme.BTN_GREEN,
		shadowColor = UITheme.BTN_GREEN_SHADOW,
		size = UDim2.new(0.6, 0, 0, 42),
		position = UDim2.new(0.5, 0, 0.5, 0),
		cornerRadius = 10,
	})

	homeBtn.MouseButton1Click:Connect(function()
		remotesFolder.TeleportHome:FireServer()
	end)

	-- Listen for search results
	remotesFolder.TradeUpdate.OnClientEvent:Connect(function(payload)
		if payload.type == "searchResult" then
			SocialUI.showSearchResult(payload.data)
		end
	end)
end

function SocialUI.showSearchResult(result: any?)
	searchBtn.Text = "SEARCH"

	-- Clear old results
	for _, child in resultFrame:GetChildren() do
		child:Destroy()
	end

	if not result then
		resultFrame.Visible = true
		resultFrame.Size = UDim2.new(1, 0, 0, 30)

		local noResult = Instance.new("TextLabel")
		noResult.Size = UDim2.new(1, 0, 1, 0)
		noResult.BackgroundTransparency = 1
		noResult.Text = "Player not found"
		noResult.TextColor3 = UITheme.TEXT_SECONDARY
		noResult.TextSize = 13
		noResult.Font = UITheme.FONT_BOLD
		noResult.Parent = resultFrame
		return
	end

	resultFrame.Visible = true
	resultFrame.Size = UDim2.new(1, 0, 0, 50)

	local card = UITheme.createCard(resultFrame, {
		borderColor = UITheme.BTN_BLUE,
		size = UDim2.new(1, 0, 0, 46),
	})

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = result.targetDisplayName or result.targetName
	nameLabel.TextColor3 = UITheme.TEXT_PRIMARY
	nameLabel.TextSize = 14
	nameLabel.Font = UITheme.FONT_BOLD
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	if result.isLocal then
		local localLabel = Instance.new("TextLabel")
		localLabel.Size = UDim2.new(0.3, 0, 1, 0)
		localLabel.Position = UDim2.new(0.5, 0, 0, 0)
		localLabel.BackgroundTransparency = 1
		localLabel.Text = "(here!)"
		localLabel.TextColor3 = UITheme.BTN_GREEN
		localLabel.TextSize = 11
		localLabel.Font = UITheme.FONT_BOLD
		localLabel.Parent = card
	else
		local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
		local tpBtn = UITheme.createActionButton(card, {
			text = "TELEPORT",
			color = UITheme.BTN_BLUE,
			shadowColor = UITheme.BTN_BLUE_SHADOW,
			size = UDim2.new(0, 80, 0, 28),
		})
		tpBtn.Position = UDim2.new(1, -52, 0.5, 0)
		tpBtn.MouseButton1Click:Connect(function()
			remotesFolder.TeleportToPlayer:FireServer(result.placeId, result.jobId)
		end)
	end
end

function SocialUI.toggle()
	visible = not visible
	if visible then
		UITheme.tweenOpen(panel.screenGui)
	else
		UITheme.tweenClose(panel.screenGui)
	end
end

return SocialUI
