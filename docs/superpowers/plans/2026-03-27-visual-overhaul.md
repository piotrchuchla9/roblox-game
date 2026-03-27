# Visual Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform "Grow a Brainrot" from dark neon placeholders to a bright Candy Pastel world with chunky UI, dynamic player plots, and social features.

**Architecture:** Three phases executed sequentially: (1) Foundation — shared types, config, UITheme rewrite; (2) World & UI — MapSetup rewrite + all 8 UI module rewrites; (3) Social — PlotManager, TeleportManager, TradeManager, SocialUI. Each phase builds on the previous.

**Tech Stack:** Luau (Roblox), Rojo project structure, Roblox services (TweenService, TeleportService, MessagingService, Terrain)

**Spec:** `docs/superpowers/specs/2026-03-27-visual-overhaul-design.md`

**IMPORTANT — Studio-safe editing:** This codebase syncs to Roblox Studio via Rojo. Studio may have modules not tracked in git. NEVER overwrite an entire file without reading it first. When modifying existing files, use targeted edits (StrReplace/Edit), not full rewrites, unless the file is being completely replaced per this plan.

---

## Phase 1: Foundation

### Task 1: Extend shared types and config

**Files:**
- Modify: `src/shared/Types.luau`
- Modify: `src/shared/Config.luau`
- Modify: `src/shared/Remotes.luau`

- [ ] **Step 1: Add new types to Types.luau**

Add after the existing `PlayerData` type, before `return {}`:

```luau
export type Plot = {
	slotIndex: number,
	ownerUserId: number,
	position: Vector3,
	model: Model?,
}

export type TradeOffer = {
	fromUserId: number,
	toUserId: number,
	offerBrainrotIds: {string},
	requestBrainrotIds: {string},
	status: string, -- "pending" | "accepted" | "declined" | "expired"
	createdAt: number,
}
```

Also add `gardenLikes: number` to the `stats` field description in `PlayerData`:

```luau
export type PlayerData = {
	garden: {
		beds: {Bed},
		bedCount: number,
		tools: {wateringCan: string},
	},
	collection: {[string]: {count: number, firstObtainedAt: number}},
	collectionCount: number,
	currencies: {seeds: number, goldenSeeds: number},
	gamepasses: {[string]: boolean},
	dailyReward: {lastClaimed: number, streak: number},
	stats: {totalHarvested: number, totalSold: number, gardenLikes: number},
	freeSeedTimer: number,
}
```

- [ ] **Step 2: Add multiplayer/social config to Config.luau**

Add at the end of Config.luau, before `return Config`:

```luau
-- Multiplayer / Plots
Config.MAX_PLAYERS_PER_SERVER = 30
Config.PLOT_SIZE = 20 -- studs per side
Config.PLOT_RING_RADIUS = 110 -- studs from center to plot ring
Config.PLOT_FADE_TIME = 10 -- seconds for plot fade out on leave

-- Trading
Config.TRADE_TIMEOUT = 15 -- seconds to confirm
Config.TRADE_MAX_ITEMS = 6 -- max brainrots per side
Config.TRADE_PROXIMITY = 8 -- studs range for ProximityPrompt

-- Social
Config.LIKE_COOLDOWN = 86400 -- 24 hours between likes per player pair

-- Island
Config.ISLAND_RADIUS = 150 -- studs
Config.HUB_RADIUS = 40 -- studs
```

- [ ] **Step 3: Add new remote event names to Remotes.luau**

Replace the entire Remotes table:

```luau
local Remotes = {
	-- Server -> Client
	UpdatePlayerData = "UpdatePlayerData",
	PlayDropAnimation = "PlayDropAnimation",
	PlotAllocated = "PlotAllocated",
	PlotReleased = "PlotReleased",
	TradeRequest = "TradeRequest",
	TradeUpdate = "TradeUpdate",

	-- Client -> Server
	PlantSeed = "PlantSeed",
	WaterBed = "WaterBed",
	HarvestBed = "HarvestBed",
	SellBrainrot = "SellBrainrot",
	ClaimDailyReward = "ClaimDailyReward",
	UpgradeGarden = "UpgradeGarden",
	ClaimFreeSeed = "ClaimFreeSeed",

	-- Social (Client -> Server)
	SearchPlayer = "SearchPlayer",
	TeleportToPlayer = "TeleportToPlayer",
	TeleportHome = "TeleportHome",
	InitiateTrade = "InitiateTrade",
	UpdateTradeOffer = "UpdateTradeOffer",
	ConfirmTrade = "ConfirmTrade",
	CancelTrade = "CancelTrade",
	LikeGarden = "LikeGarden",
}

return Remotes
```

- [ ] **Step 4: Update PlayerDataManager default data**

In `src/server/PlayerDataManager.luau`, add `gardenLikes = 0` to the stats table in `getDefaultData()`. Change line 33 from:

```luau
		stats = { totalHarvested = 0, totalSold = 0 },
```

to:

```luau
		stats = { totalHarvested = 0, totalSold = 0, gardenLikes = 0 },
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Types.luau src/shared/Config.luau src/shared/Remotes.luau src/server/PlayerDataManager.luau
git commit -m "feat: add multiplayer types, config, and remote events"
```

---

### Task 2: Rewrite UITheme.luau — Candy Pastel + Chunky helpers

**Files:**
- Rewrite: `src/client/UITheme.luau`

This is a full rewrite — the entire file changes from dark neon to bright pastel. All existing functions are replaced with new implementations matching the Chunky Candy Pastel style.

- [ ] **Step 1: Rewrite UITheme.luau**

```luau
local TweenService = game:GetService("TweenService")

local UITheme = {}

-- === CANDY PASTEL PALETTE ===

-- Backgrounds
UITheme.BG_PRIMARY = Color3.fromRGB(255, 255, 255)
UITheme.BG_SECONDARY = Color3.fromRGB(255, 245, 248)
UITheme.BG_OVERLAY_COLOR = Color3.fromRGB(0, 0, 0)
UITheme.BG_OVERLAY_TRANSPARENCY = 0.4
UITheme.BG_CARD = Color3.fromRGB(255, 255, 255)
UITheme.BG_LIST_ITEM = Color3.fromRGB(255, 252, 254)

-- Accents
UITheme.PRIMARY = Color3.fromRGB(255, 181, 232)       -- #FFB5E8 pink
UITheme.SECONDARY = Color3.fromRGB(181, 222, 255)     -- #B5DEFF blue
UITheme.ACCENT_GREEN = Color3.fromRGB(231, 255, 172)  -- #E7FFAC lime
UITheme.ACCENT_YELLOW = Color3.fromRGB(255, 245, 186) -- #FFF5BA yellow
UITheme.ACCENT_LAVENDER = Color3.fromRGB(220, 211, 255) -- #DCD3FF lavender

-- Button colors (saturated + shadow for 3D effect)
UITheme.BTN_GREEN = Color3.fromRGB(76, 175, 80)
UITheme.BTN_GREEN_SHADOW = Color3.fromRGB(56, 142, 60)
UITheme.BTN_ORANGE = Color3.fromRGB(255, 152, 0)
UITheme.BTN_ORANGE_SHADOW = Color3.fromRGB(230, 81, 0)
UITheme.BTN_PINK = Color3.fromRGB(233, 30, 99)
UITheme.BTN_PINK_SHADOW = Color3.fromRGB(173, 20, 87)
UITheme.BTN_BLUE = Color3.fromRGB(33, 150, 243)
UITheme.BTN_BLUE_SHADOW = Color3.fromRGB(25, 118, 210)
UITheme.BTN_RED = Color3.fromRGB(244, 67, 54)
UITheme.BTN_RED_SHADOW = Color3.fromRGB(198, 40, 40)

-- Text
UITheme.TEXT_PRIMARY = Color3.fromRGB(93, 64, 55)     -- #5D4037 dark brown
UITheme.TEXT_SECONDARY = Color3.fromRGB(121, 85, 72)  -- #795548
UITheme.TEXT_ON_BTN = Color3.fromRGB(255, 255, 255)

-- Rarity colors (chunky borders)
UITheme.RARITY_COLORS = {
	Common = Color3.fromRGB(189, 189, 189),
	Uncommon = Color3.fromRGB(76, 175, 80),
	Rare = Color3.fromRGB(33, 150, 243),
	Epic = Color3.fromRGB(156, 39, 176),
	Legendary = Color3.fromRGB(255, 152, 0),
	Mythic = Color3.fromRGB(233, 30, 99),
}

UITheme.RARITY_BORDER_THICKNESS = {
	Common = 2,
	Uncommon = 2,
	Rare = 3,
	Epic = 3,
	Legendary = 3,
	Mythic = 3,
}

UITheme.RARITY_ORDER = { "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common" }

-- Style constants
UITheme.BORDER_WIDTH = 3
UITheme.CORNER_RADIUS = 10
UITheme.BORDER_3D_HEIGHT = 3

-- Fonts
UITheme.FONT_BOLD = Enum.Font.GothamBold
UITheme.FONT_REGULAR = Enum.Font.Gotham

-- === CHUNKY HELPERS ===

function UITheme.createChunkyButton(parent: GuiObject, config: { [string]: any }): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = config.size or UDim2.new(0, 120, 0, 40)
	btn.AnchorPoint = config.anchorPoint or Vector2.new(0.5, 0.5)
	btn.Position = config.position or UDim2.new(0.5, 0, 0.5, 0)
	btn.BackgroundColor3 = config.color or UITheme.BTN_GREEN
	btn.Text = string.upper(config.text or "Button")
	btn.TextColor3 = config.textColor or UITheme.TEXT_ON_BTN
	btn.TextSize = config.textSize or 14
	btn.Font = UITheme.FONT_BOLD
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, config.cornerRadius or 8)
	corner.Parent = btn

	-- 3D shadow (border-bottom effect)
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow3D"
	shadow.Size = UDim2.new(1, 0, 0, UITheme.BORDER_3D_HEIGHT)
	shadow.Position = UDim2.new(0, 0, 1, 0)
	shadow.BackgroundColor3 = config.shadowColor or UITheme.BTN_GREEN_SHADOW
	shadow.BorderSizePixel = 0
	shadow.Parent = btn

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, config.cornerRadius or 8)
	shadowCorner.Parent = shadow

	-- Press animation (push down effect)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.05), {
			Position = btn.Position + UDim2.new(0, 0, 0, 2),
		}):Play()
		shadow.Visible = false
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = config.position or UDim2.new(0.5, 0, 0.5, 0),
		}):Play()
		shadow.Visible = true
	end)

	return btn
end

function UITheme.createCard(parent: GuiObject, config: { [string]: any }): Frame
	local card = Instance.new("Frame")
	card.Name = config.name or "Card"
	card.Size = config.size or UDim2.new(1, 0, 0, 64)
	card.BackgroundColor3 = UITheme.BG_CARD
	card.BorderSizePixel = 0
	card.LayoutOrder = config.layoutOrder or 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UITheme.CORNER_RADIUS)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = config.borderColor or UITheme.PRIMARY
	stroke.Thickness = config.borderThickness or UITheme.BORDER_WIDTH
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = card

	return card
end

function UITheme.createListItem(parent: GuiObject, config: { [string]: any }): { [string]: any }
	local height = config.height or 60

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.BackgroundColor3 = UITheme.BG_CARD
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UITheme.CORNER_RADIUS)
	corner.Parent = frame

	-- Chunky left border bar
	local leftBorder = Instance.new("Frame")
	leftBorder.Name = "LeftBorder"
	leftBorder.Size = UDim2.new(0, 4, 1, -12)
	leftBorder.Position = UDim2.new(0, 6, 0, 6)
	leftBorder.BackgroundColor3 = config.borderColor or UITheme.PRIMARY
	leftBorder.BackgroundTransparency = config.borderTransparency or 0
	leftBorder.BorderSizePixel = 0
	leftBorder.Parent = frame

	local borderCorner = Instance.new("UICorner")
	borderCorner.CornerRadius = UDim.new(0, 2)
	borderCorner.Parent = leftBorder

	-- Full card outline
	local stroke = Instance.new("UIStroke")
	stroke.Color = config.borderColor or UITheme.PRIMARY
	stroke.Thickness = 2
	stroke.Transparency = 0.7
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = frame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 32, 1, 0)
	iconLabel.Position = UDim2.new(0, 4, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = config.icon or ""
	iconLabel.TextSize = 24
	iconLabel.TextTransparency = config.iconTransparency or 0
	iconLabel.Font = Enum.Font.SourceSans
	iconLabel.Parent = frame

	local infoFrame = Instance.new("Frame")
	infoFrame.Name = "Info"
	infoFrame.Size = UDim2.new(1, -120, 1, 0)
	infoFrame.Position = UDim2.new(0, 44, 0, 0)
	infoFrame.BackgroundTransparency = 1
	infoFrame.Parent = frame

	local actionFrame = Instance.new("Frame")
	actionFrame.Name = "Action"
	actionFrame.Size = UDim2.new(0, 70, 1, 0)
	actionFrame.Position = UDim2.new(1, -70, 0, 0)
	actionFrame.BackgroundTransparency = 1
	actionFrame.Parent = frame

	return {
		frame = frame,
		iconLabel = iconLabel,
		infoFrame = infoFrame,
		actionFrame = actionFrame,
		leftBorder = leftBorder,
	}
end

function UITheme.createPanel(playerGui: Instance, config: { [string]: any }): { [string]: any }
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = config.name
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Dim overlay behind panel
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = UITheme.BG_OVERLAY_COLOR
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = UITheme.BG_SECONDARY
	bg.BackgroundTransparency = 0
	bg.BorderSizePixel = 0
	bg.Parent = screenGui

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundColor3 = UITheme.BG_PRIMARY
	header.BorderSizePixel = 0
	header.Parent = bg

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 0)
	headerCorner.Parent = header

	-- Bottom border on header
	local headerBorder = Instance.new("Frame")
	headerBorder.Size = UDim2.new(1, 0, 0, UITheme.BORDER_WIDTH)
	headerBorder.Position = UDim2.new(0, 0, 1, 0)
	headerBorder.BackgroundColor3 = UITheme.PRIMARY
	headerBorder.BorderSizePixel = 0
	headerBorder.Parent = header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 16, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = string.upper(config.title or "Panel")
	titleLabel.TextColor3 = UITheme.TEXT_PRIMARY
	titleLabel.TextSize = 18
	titleLabel.Font = UITheme.FONT_BOLD
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header

	-- Close button (chunky style)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -46, 0, 10)
	closeBtn.BackgroundColor3 = UITheme.BTN_RED
	closeBtn.Text = "X"
	closeBtn.TextColor3 = UITheme.TEXT_ON_BTN
	closeBtn.TextSize = 16
	closeBtn.Font = UITheme.FONT_BOLD
	closeBtn.AutoButtonColor = false
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = header

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn

	local closeShadow = Instance.new("Frame")
	closeShadow.Size = UDim2.new(1, 0, 0, 2)
	closeShadow.Position = UDim2.new(0, 0, 1, 0)
	closeShadow.BackgroundColor3 = UITheme.BTN_RED_SHADOW
	closeShadow.BorderSizePixel = 0
	closeShadow.Parent = closeBtn

	local closeShadowCorner = Instance.new("UICorner")
	closeShadowCorner.CornerRadius = UDim.new(0, 8)
	closeShadowCorner.Parent = closeShadow

	closeBtn.MouseButton1Click:Connect(function()
		if config.onClose then
			config.onClose()
		end
	end)

	-- Content scroll
	local contentScroll = Instance.new("ScrollingFrame")
	contentScroll.Name = "Content"
	contentScroll.Size = UDim2.new(1, -20, 1, -66)
	contentScroll.Position = UDim2.new(0, 10, 0, 60)
	contentScroll.BackgroundTransparency = 1
	contentScroll.ScrollBarThickness = 6
	contentScroll.ScrollBarImageColor3 = UITheme.PRIMARY
	contentScroll.BorderSizePixel = 0
	contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	contentScroll.Parent = bg

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Name = "Layout"
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.Parent = contentScroll

	return {
		screenGui = screenGui,
		overlay = overlay,
		background = bg,
		contentScroll = contentScroll,
		headerFrame = header,
		titleLabel = titleLabel,
	}
end

function UITheme.tweenOpen(screenGui: ScreenGui)
	screenGui.Enabled = true
	local bg = screenGui:FindFirstChild("Background")
	local overlay = screenGui:FindFirstChild("Overlay")
	if not bg then return end

	bg.BackgroundTransparency = 1
	if overlay then
		overlay.BackgroundTransparency = 1
		TweenService:Create(overlay, TweenInfo.new(0.2), {
			BackgroundTransparency = UITheme.BG_OVERLAY_TRANSPARENCY,
		}):Play()
	end

	local content = bg:FindFirstChild("Content")
	local contentStartY = nil
	if content then
		contentStartY = content.Position.Y.Offset
		content.Position = UDim2.new(content.Position.X.Scale, content.Position.X.Offset, content.Position.Y.Scale, contentStartY + 50)
	end

	TweenService:Create(bg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	}):Play()

	if content and contentStartY then
		TweenService:Create(content, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(content.Position.X.Scale, content.Position.X.Offset, content.Position.Y.Scale, contentStartY),
		}):Play()
	end
end

function UITheme.tweenClose(screenGui: ScreenGui, callback: (() -> ())?)
	local bg = screenGui:FindFirstChild("Background")
	local overlay = screenGui:FindFirstChild("Overlay")

	if not bg then
		screenGui.Enabled = false
		if callback then callback() end
		return
	end

	TweenService:Create(bg, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	}):Play()

	if overlay then
		TweenService:Create(overlay, TweenInfo.new(0.15), {
			BackgroundTransparency = 1,
		}):Play()
	end

	task.delay(0.15, function()
		screenGui.Enabled = false
		if callback then callback() end
	end)
end

function UITheme.createActionButton(parent: GuiObject, config: { [string]: any }): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = config.size or UDim2.new(0, 70, 0, 30)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = UDim2.new(0.5, 0, 0.5, 0)
	btn.BackgroundColor3 = config.color or UITheme.BTN_GREEN
	btn.Text = string.upper(config.text or "OK")
	btn.TextColor3 = config.textColor or UITheme.TEXT_ON_BTN
	btn.TextSize = 11
	btn.Font = UITheme.FONT_BOLD
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	-- 3D shadow
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow3D"
	shadow.Size = UDim2.new(1, 0, 0, 2)
	shadow.Position = UDim2.new(0, 0, 1, 0)
	shadow.BackgroundColor3 = config.shadowColor or UITheme.BTN_GREEN_SHADOW
	shadow.BorderSizePixel = 0
	shadow.Parent = btn

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 6)
	shadowCorner.Parent = shadow

	return btn
end

function UITheme.createSectionDivider(parent: GuiObject, config: { [string]: any }): Frame
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, 0, 0, 28)
	divider.BackgroundTransparency = 1
	divider.Parent = parent

	local leftLine = Instance.new("Frame")
	leftLine.Size = UDim2.new(0.25, 0, 0, 2)
	leftLine.Position = UDim2.new(0, 0, 0.5, 0)
	leftLine.BackgroundColor3 = config.color or UITheme.PRIMARY
	leftLine.BackgroundTransparency = 0.5
	leftLine.BorderSizePixel = 0
	leftLine.Parent = divider

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.Position = UDim2.new(0.25, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = config.text or "SECTION"
	label.TextColor3 = config.color or UITheme.TEXT_PRIMARY
	label.TextSize = 11
	label.Font = UITheme.FONT_BOLD
	label.Parent = divider

	local rightLine = Instance.new("Frame")
	rightLine.Size = UDim2.new(0.25, 0, 0, 2)
	rightLine.Position = UDim2.new(0.75, 0, 0.5, 0)
	rightLine.BackgroundColor3 = config.color or UITheme.PRIMARY
	rightLine.BackgroundTransparency = 0.5
	rightLine.BorderSizePixel = 0
	rightLine.Parent = divider

	return divider
end

return UITheme
```

- [ ] **Step 2: Verify UITheme compiles**

Run in Roblox Studio or verify no syntax errors via `rojo serve` and check Studio output.

- [ ] **Step 3: Commit**

```bash
git add src/client/UITheme.luau
git commit -m "feat: rewrite UITheme to Candy Pastel chunky style"
```

---

## Phase 2: World & UI

### Task 3: Rewrite MapSetup.luau — Circular island with terrain and lighting

**Files:**
- Rewrite: `src/server/MapSetup.luau`

- [ ] **Step 1: Rewrite MapSetup.luau**

```luau
-- MapSetup: Creates the Candy Pastel circular island world
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local MapSetup = {}

-- Helper: create a simple Part
local function makePart(config): Part
	local part = Instance.new("Part")
	part.Name = config.name or "Part"
	part.Size = config.size or Vector3.new(4, 4, 4)
	part.Position = config.position or Vector3.new(0, 0, 0)
	part.Anchored = true
	part.BrickColor = config.brickColor or BrickColor.new("White")
	part.Color = config.color or part.Color
	part.Material = config.material or Enum.Material.SmoothPlastic
	part.Transparency = config.transparency or 0
	part.CanCollide = config.canCollide ~= false
	part.CastShadow = config.castShadow ~= false
	part.Parent = config.parent or Workspace
	return part
end

-- Helper: create a procedural tree
local function makeTree(position: Vector3, parent: Instance)
	local trunk = makePart({
		name = "Trunk",
		size = Vector3.new(2, 8, 2),
		position = position + Vector3.new(0, 4, 0),
		color = Color3.fromRGB(139, 90, 43),
		material = Enum.Material.Wood,
		parent = parent,
	})

	local crown = makePart({
		name = "Crown",
		size = Vector3.new(8, 8, 8),
		position = position + Vector3.new(0, 10, 0),
		color = Color3.fromRGB(100, 200, 100),
		material = Enum.Material.Grass,
		parent = parent,
	})
	-- Make crown a ball shape
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = crown
end

-- Helper: create a flower cluster
local function makeFlower(position: Vector3, parent: Instance)
	local colors = {
		Color3.fromRGB(255, 181, 232), -- pink
		Color3.fromRGB(181, 222, 255), -- blue
		Color3.fromRGB(255, 245, 186), -- yellow
		Color3.fromRGB(220, 211, 255), -- lavender
		Color3.fromRGB(231, 255, 172), -- lime
	}
	local color = colors[math.random(1, #colors)]

	local stem = makePart({
		name = "Stem",
		size = Vector3.new(0.3, 1.5, 0.3),
		position = position + Vector3.new(0, 0.75, 0),
		color = Color3.fromRGB(80, 160, 60),
		material = Enum.Material.Grass,
		parent = parent,
	})

	local bloom = makePart({
		name = "Bloom",
		size = Vector3.new(1.2, 0.6, 1.2),
		position = position + Vector3.new(0, 1.7, 0),
		color = color,
		material = Enum.Material.SmoothPlastic,
		parent = parent,
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = bloom
end

-- Helper: create a balloon
local function makeBalloon(position: Vector3, parent: Instance)
	local colors = {
		Color3.fromRGB(255, 181, 232),
		Color3.fromRGB(181, 222, 255),
		Color3.fromRGB(255, 245, 186),
		Color3.fromRGB(220, 211, 255),
	}
	local color = colors[math.random(1, #colors)]

	-- String
	makePart({
		name = "String",
		size = Vector3.new(0.1, 6, 0.1),
		position = position + Vector3.new(0, 3, 0),
		color = Color3.fromRGB(200, 200, 200),
		material = Enum.Material.Fabric,
		canCollide = false,
		castShadow = false,
		parent = parent,
	})

	-- Balloon sphere
	local ball = makePart({
		name = "Balloon",
		size = Vector3.new(3, 3.6, 3),
		position = position + Vector3.new(0, 7.5, 0),
		color = color,
		material = Enum.Material.SmoothPlastic,
		canCollide = false,
		parent = parent,
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = ball
end

function MapSetup.build()
	-- === TERRAIN: Circular island ===
	local terrain = Workspace.Terrain
	terrain:Clear()

	local ISLAND_RADIUS = 150
	local resolution = 4

	-- Fill grass terrain in a circle
	for x = -ISLAND_RADIUS, ISLAND_RADIUS, resolution do
		for z = -ISLAND_RADIUS, ISLAND_RADIUS, resolution do
			local dist = math.sqrt(x * x + z * z)
			if dist <= ISLAND_RADIUS then
				-- Gentle hills using sine waves
				local height = 2 + math.sin(x * 0.05) * 1.5 + math.cos(z * 0.07) * 1.2
				-- Flatten center for hub
				if dist < 45 then
					height = 2
				end
				local region = Region3.new(
					Vector3.new(x - resolution/2, -4, z - resolution/2),
					Vector3.new(x + resolution/2, height, z + resolution/2)
				)
				terrain:FillRegion(region:ExpandToGrid(resolution), resolution, Enum.Material.Grass)
			end
		end
	end

	-- Pond in hub area
	for x = -15, 15, resolution do
		for z = -15, 15, resolution do
			local dist = math.sqrt(x * x + z * z)
			if dist <= 12 then
				local region = Region3.new(
					Vector3.new(x - resolution/2, 0, z - resolution/2),
					Vector3.new(x + resolution/2, 1.8, z + resolution/2)
				)
				terrain:FillRegion(region:ExpandToGrid(resolution), resolution, Enum.Material.Water)
			end
		end
	end

	-- Stone paths from hub outward
	for i = 0, 29 do
		local angle = (i / 30) * math.pi * 2
		for d = 45, 100, resolution do
			local px = math.cos(angle) * d
			local pz = math.sin(angle) * d
			local region = Region3.new(
				Vector3.new(px - 2, -1, pz - 2),
				Vector3.new(px + 2, 2.5, pz + 2)
			)
			terrain:FillRegion(region:ExpandToGrid(resolution), resolution, Enum.Material.Slate)
		end
	end

	-- === DECORATIONS FOLDER ===
	local decoFolder = Instance.new("Folder")
	decoFolder.Name = "Decorations"
	decoFolder.Parent = Workspace

	-- === SPAWN ===
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 2.5, -25)
	spawn.Anchored = true
	spawn.Color = Color3.fromRGB(255, 181, 232) -- pastel pink
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Parent = Workspace

	-- === HUB BUILDINGS ===
	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "Hub"
	hubFolder.Parent = Workspace

	-- Shop building (pink)
	local shopBase = makePart({
		name = "ShopBuilding",
		size = Vector3.new(14, 10, 12),
		position = Vector3.new(25, 7, 0),
		color = Color3.fromRGB(255, 200, 230),
		parent = hubFolder,
	})
	local shopRoof = makePart({
		name = "ShopRoof",
		size = Vector3.new(16, 2, 14),
		position = Vector3.new(25, 13, 0),
		color = Color3.fromRGB(233, 30, 99),
		parent = hubFolder,
	})
	-- Shop sign
	local shopSign = Instance.new("SurfaceGui")
	shopSign.Name = "ShopSign"
	shopSign.Face = Enum.NormalId.Front
	shopSign.Parent = shopBase
	local shopText = Instance.new("TextLabel")
	shopText.Size = UDim2.new(1, 0, 0.4, 0)
	shopText.Position = UDim2.new(0, 0, 0.1, 0)
	shopText.BackgroundTransparency = 1
	shopText.Text = "SHOP"
	shopText.TextColor3 = Color3.fromRGB(93, 64, 55)
	shopText.TextScaled = true
	shopText.Font = Enum.Font.GothamBold
	shopText.Parent = shopSign

	-- Leaderboard building (blue)
	local lbBase = makePart({
		name = "LeaderboardBuilding",
		size = Vector3.new(12, 10, 12),
		position = Vector3.new(-25, 7, 0),
		color = Color3.fromRGB(200, 225, 255),
		parent = hubFolder,
	})
	local lbRoof = makePart({
		name = "LeaderboardRoof",
		size = Vector3.new(14, 2, 14),
		position = Vector3.new(-25, 13, 0),
		color = Color3.fromRGB(33, 150, 243),
		parent = hubFolder,
	})

	-- Trend Radar billboard (yellow)
	local billboard = makePart({
		name = "TrendRadar",
		size = Vector3.new(14, 8, 1),
		position = Vector3.new(0, 8, 30),
		color = Color3.fromRGB(255, 245, 186),
		parent = hubFolder,
	})
	-- Billboard posts
	makePart({
		name = "TrendPost1",
		size = Vector3.new(1, 12, 1),
		position = Vector3.new(-6, 6, 30),
		color = Color3.fromRGB(139, 90, 43),
		material = Enum.Material.Wood,
		parent = hubFolder,
	})
	makePart({
		name = "TrendPost2",
		size = Vector3.new(1, 12, 1),
		position = Vector3.new(6, 6, 30),
		color = Color3.fromRGB(139, 90, 43),
		material = Enum.Material.Wood,
		parent = hubFolder,
	})

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "TrendDisplay"
	surfaceGui.Face = Enum.NormalId.Back
	surfaceGui.Parent = billboard

	local trendTitle = Instance.new("TextLabel")
	trendTitle.Size = UDim2.new(1, 0, 0.3, 0)
	trendTitle.BackgroundTransparency = 1
	trendTitle.Text = "TREND RADAR"
	trendTitle.TextColor3 = Color3.fromRGB(93, 64, 55)
	trendTitle.TextScaled = true
	trendTitle.Font = Enum.Font.GothamBold
	trendTitle.Parent = surfaceGui

	local trendCurrent = Instance.new("TextLabel")
	trendCurrent.Name = "CurrentTrend"
	trendCurrent.Size = UDim2.new(1, 0, 0.4, 0)
	trendCurrent.Position = UDim2.new(0, 0, 0.3, 0)
	trendCurrent.BackgroundTransparency = 1
	trendCurrent.Text = "Season 1: OG Brainrot"
	trendCurrent.TextColor3 = Color3.fromRGB(233, 30, 99)
	trendCurrent.TextScaled = true
	trendCurrent.Font = Enum.Font.GothamBold
	trendCurrent.Parent = surfaceGui

	local trendWeekly = Instance.new("TextLabel")
	trendWeekly.Name = "WeeklyBrainrot"
	trendWeekly.Size = UDim2.new(1, 0, 0.2, 0)
	trendWeekly.Position = UDim2.new(0, 0, 0.75, 0)
	trendWeekly.BackgroundTransparency = 1
	trendWeekly.Text = "Weekly: Bombardiro Crocodilo"
	trendWeekly.TextColor3 = Color3.fromRGB(33, 150, 243)
	trendWeekly.TextScaled = true
	trendWeekly.Font = Enum.Font.Gotham
	trendWeekly.Parent = surfaceGui

	-- Hub benches
	for i = 0, 3 do
		local angle = (i / 4) * math.pi * 2 + math.pi / 4
		local bx = math.cos(angle) * 20
		local bz = math.sin(angle) * 20
		makePart({
			name = "Bench" .. i,
			size = Vector3.new(4, 1.5, 1.5),
			position = Vector3.new(bx, 3, bz),
			color = Color3.fromRGB(139, 90, 43),
			material = Enum.Material.Wood,
			parent = hubFolder,
		})
	end

	-- Hub balloons
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local bx = math.cos(angle) * 32
		local bz = math.sin(angle) * 32
		makeBalloon(Vector3.new(bx, 2.5, bz), decoFolder)
	end

	-- Hub lamposts
	for i = 0, 5 do
		local angle = (i / 6) * math.pi * 2
		local lx = math.cos(angle) * 38
		local lz = math.sin(angle) * 38
		local pole = makePart({
			name = "LampPole" .. i,
			size = Vector3.new(0.6, 8, 0.6),
			position = Vector3.new(lx, 6, lz),
			color = Color3.fromRGB(200, 200, 200),
			material = Enum.Material.Metal,
			parent = decoFolder,
		})
		local lamp = makePart({
			name = "LampLight" .. i,
			size = Vector3.new(2, 1, 2),
			position = Vector3.new(lx, 10.5, lz),
			color = Color3.fromRGB(255, 245, 186),
			material = Enum.Material.Neon,
			parent = decoFolder,
		})
		local pointLight = Instance.new("PointLight")
		pointLight.Color = Color3.fromRGB(255, 240, 220)
		pointLight.Brightness = 0.5
		pointLight.Range = 20
		pointLight.Parent = lamp
	end

	-- === PLOT MARKERS (30 slots) ===
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "PlotSlots"
	plotsFolder.Parent = Workspace

	for i = 0, 29 do
		local angle = (i / 30) * math.pi * 2
		local px = math.cos(angle) * 110
		local pz = math.sin(angle) * 110

		local marker = Instance.new("Part")
		marker.Name = "PlotSlot" .. i
		marker.Size = Vector3.new(20, 0.2, 20)
		marker.Position = Vector3.new(px, 2, pz)
		marker.Anchored = true
		marker.Transparency = 1
		marker.CanCollide = false
		marker.Parent = plotsFolder

		-- Visible plot floor (faded until claimed)
		local floor = makePart({
			name = "PlotFloor",
			size = Vector3.new(18, 0.3, 18),
			position = Vector3.new(px, 2.2, pz),
			color = Color3.fromRGB(200, 180, 140),
			material = Enum.Material.WoodPlanks,
			transparency = 0.8,
			canCollide = false,
			parent = marker,
		})
	end

	-- === TREES (scattered around, outside hub and between plots) ===
	math.randomseed(42) -- deterministic placement
	for i = 1, 40 do
		local angle = math.random() * math.pi * 2
		local dist = 50 + math.random() * 80
		local tx = math.cos(angle) * dist
		local tz = math.sin(angle) * dist
		-- Skip if too close to a plot slot
		local tooClose = false
		for s = 0, 29 do
			local sa = (s / 30) * math.pi * 2
			local sx = math.cos(sa) * 110
			local sz = math.sin(sa) * 110
			if (tx - sx)^2 + (tz - sz)^2 < 15^2 then
				tooClose = true
				break
			end
		end
		if not tooClose then
			makeTree(Vector3.new(tx, 2, tz), decoFolder)
		end
	end

	-- === FLOWERS (scattered near paths and hub) ===
	for i = 1, 60 do
		local angle = math.random() * math.pi * 2
		local dist = 15 + math.random() * 120
		local fx = math.cos(angle) * dist + math.random(-3, 3)
		local fz = math.sin(angle) * dist + math.random(-3, 3)
		makeFlower(Vector3.new(fx, 2, fz), decoFolder)
	end

	-- === FOUNTAIN in pond center ===
	local fountain = makePart({
		name = "Fountain",
		size = Vector3.new(4, 3, 4),
		position = Vector3.new(0, 3, 0),
		color = Color3.fromRGB(220, 220, 230),
		material = Enum.Material.Marble,
		parent = hubFolder,
	})

	-- Fountain particle emitter
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 1.5, 0)
	attachment.Parent = fountain

	local waterParticles = Instance.new("ParticleEmitter")
	waterParticles.Color = ColorSequence.new(Color3.fromRGB(181, 222, 255))
	waterParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	waterParticles.Lifetime = NumberRange.new(1, 2)
	waterParticles.Rate = 30
	waterParticles.Speed = NumberRange.new(4, 6)
	waterParticles.SpreadAngle = Vector2.new(15, 15)
	waterParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	waterParticles.Parent = attachment

	-- Sparkles over pond
	local sparkleAttachment = Instance.new("Attachment")
	sparkleAttachment.Position = Vector3.new(0, 2, 0)
	sparkleAttachment.Parent = fountain

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 220)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 245, 186)),
	})
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkles.Lifetime = NumberRange.new(3, 5)
	sparkles.Rate = 8
	sparkles.Speed = NumberRange.new(0.3, 0.8)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkles.Parent = sparkleAttachment

	-- === LIGHTING & ATMOSPHERE ===
	Lighting.ClockTime = 14
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(180, 170, 190)
	Lighting.OutdoorAmbient = Color3.fromRGB(200, 195, 210)

	-- Remove existing post-processing
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("BloomEffect")
			or child:IsA("ColorCorrectionEffect") or child:IsA("SunRaysEffect") then
			child:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.15
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(255, 230, 240)
	atmosphere.Decay = Color3.fromRGB(200, 180, 210)
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.3
	bloom.Size = 24
	bloom.Threshold = 2
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.15
	cc.TintColor = Color3.fromRGB(255, 245, 250)
	cc.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.1
	sunRays.Spread = 0.5
	sunRays.Parent = Lighting

	print("[Server] Candy Pastel island built successfully")
end

return MapSetup
```

- [ ] **Step 2: Test in Studio**

Run `rojo serve`, sync, enter Play mode. Verify:
- Circular grass island with gentle hills
- Central pond with water + fountain particles
- Pink/blue/yellow hub buildings
- 30 transparent plot markers in ring
- Trees, flowers, balloons, lampposts
- Warm pastel lighting with bloom

- [ ] **Step 3: Commit**

```bash
git add src/server/MapSetup.luau
git commit -m "feat: rewrite MapSetup as Candy Pastel circular island"
```

---

### Task 4: Rewrite HUD.luau — Bright chunky top bar and tab bar

**Files:**
- Rewrite: `src/client/HUD.luau`

- [ ] **Step 1: Rewrite HUD.luau**

```luau
local Players = game:GetService("Players")
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
	topBar.Size = UDim2.new(1, 0, 0, 52)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = UITheme.BG_PRIMARY
	topBar.BorderSizePixel = 0
	topBar.Parent = screenGui

	-- Bottom chunky border
	local topBarBorder = Instance.new("Frame")
	topBarBorder.Name = "Border"
	topBarBorder.Size = UDim2.new(1, 0, 0, 3)
	topBarBorder.Position = UDim2.new(0, 0, 1, 0)
	topBarBorder.BackgroundColor3 = UITheme.PRIMARY
	topBarBorder.BorderSizePixel = 0
	topBarBorder.Parent = topBar

	-- Currency pills
	local pillContainer = Instance.new("Frame")
	pillContainer.Name = "Pills"
	pillContainer.Size = UDim2.new(1, -20, 0, 38)
	pillContainer.Position = UDim2.new(0, 10, 0, 7)
	pillContainer.BackgroundTransparency = 1
	pillContainer.Parent = topBar

	local pillLayout = Instance.new("UIListLayout")
	pillLayout.FillDirection = Enum.FillDirection.Horizontal
	pillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pillLayout.Padding = UDim.new(0, 8)
	pillLayout.Parent = pillContainer

	local function createPill(name: string, label: string, accentColor: Color3, iconEmoji: string, layoutOrder: number): TextLabel
		local pill = Instance.new("Frame")
		pill.Name = name
		pill.Size = UDim2.new(0, 130, 1, 0)
		pill.BackgroundColor3 = UITheme.BG_PRIMARY
		pill.BorderSizePixel = 0
		pill.LayoutOrder = layoutOrder
		pill.Parent = pillContainer

		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(0, 10)
		pillCorner.Parent = pill

		local pillStroke = Instance.new("UIStroke")
		pillStroke.Color = accentColor
		pillStroke.Thickness = 2
		pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		pillStroke.Parent = pill

		local pillPad = Instance.new("UIPadding")
		pillPad.PaddingLeft = UDim.new(0, 8)
		pillPad.PaddingRight = UDim.new(0, 8)
		pillPad.Parent = pill

		-- Icon
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Name = "Icon"
		iconLbl.Size = UDim2.new(0, 20, 1, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text = iconEmoji
		iconLbl.TextSize = 16
		iconLbl.Font = Enum.Font.SourceSans
		iconLbl.Parent = pill

		-- Category label
		local catLabel = Instance.new("TextLabel")
		catLabel.Name = "Category"
		catLabel.Size = UDim2.new(1, -24, 0, 12)
		catLabel.Position = UDim2.new(0, 24, 0, 2)
		catLabel.BackgroundTransparency = 1
		catLabel.Text = string.upper(label)
		catLabel.TextColor3 = accentColor
		catLabel.TextSize = 9
		catLabel.Font = UITheme.FONT_BOLD
		catLabel.TextXAlignment = Enum.TextXAlignment.Left
		catLabel.Parent = pill

		-- Value
		local valLabel = Instance.new("TextLabel")
		valLabel.Name = "Value"
		valLabel.Size = UDim2.new(1, -24, 0, 18)
		valLabel.Position = UDim2.new(0, 24, 0, 14)
		valLabel.BackgroundTransparency = 1
		valLabel.Text = "0"
		valLabel.TextColor3 = UITheme.TEXT_PRIMARY
		valLabel.TextSize = 16
		valLabel.Font = UITheme.FONT_BOLD
		valLabel.TextXAlignment = Enum.TextXAlignment.Left
		valLabel.Parent = pill

		return valLabel
	end

	seedsValue = createPill("SeedsPill", "Seeds", UITheme.BTN_GREEN, "\u{1F331}", 1)
	goldenSeedsValue = createPill("GoldenPill", "Golden", UITheme.BTN_ORANGE, "\u{2B50}", 2)
	collectionValue = createPill("CollectionPill", "Collection", UITheme.BTN_BLUE, "\u{1F4D6}", 3)

	-- === BOTTOM TAB BAR ===
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, 0, 0, 66)
	tabBar.Position = UDim2.new(0, 0, 1, -66)
	tabBar.BackgroundColor3 = UITheme.BG_PRIMARY
	tabBar.BorderSizePixel = 0
	tabBar.Parent = screenGui

	-- Top chunky border
	local tabBarBorder = Instance.new("Frame")
	tabBarBorder.Size = UDim2.new(1, 0, 0, 3)
	tabBarBorder.Position = UDim2.new(0, 0, 0, 0)
	tabBarBorder.BackgroundColor3 = UITheme.PRIMARY
	tabBarBorder.BorderSizePixel = 0
	tabBarBorder.Parent = tabBar

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding = UDim.new(0, 4)
	tabLayout.Parent = tabBar

	local tabs = {
		{ name = "Garden", icon = "\u{1F331}", order = 1, color = UITheme.BTN_GREEN, shadow = UITheme.BTN_GREEN_SHADOW },
		{ name = "Shop", icon = "\u{1F6D2}", order = 2, color = UITheme.BTN_PINK, shadow = UITheme.BTN_PINK_SHADOW },
		{ name = "Collection", icon = "\u{1F4D6}", order = 3, color = UITheme.BTN_ORANGE, shadow = UITheme.BTN_ORANGE_SHADOW, center = true },
		{ name = "Daily", icon = "\u{1F381}", order = 4, color = UITheme.BTN_BLUE, shadow = UITheme.BTN_BLUE_SHADOW },
		{ name = "FreeSeed", icon = "\u{1F31F}", order = 5, color = UITheme.BTN_GREEN, shadow = UITheme.BTN_GREEN_SHADOW },
	}

	for _, tabInfo in tabs do
		local isCenter = tabInfo.center == true

		local tabFrame = Instance.new("TextButton")
		tabFrame.Name = tabInfo.name .. "Tab"
		tabFrame.Size = isCenter and UDim2.new(0.2, 0, 1, 12) or UDim2.new(0.18, 0, 1, -8)
		tabFrame.Position = isCenter and UDim2.new(0, 0, 0, -8) or UDim2.new(0, 0, 0, 0)
		tabFrame.BackgroundColor3 = isCenter and tabInfo.color or UITheme.BG_PRIMARY
		tabFrame.Text = ""
		tabFrame.LayoutOrder = tabInfo.order
		tabFrame.AutoButtonColor = false
		tabFrame.BorderSizePixel = 0
		tabFrame.Parent = tabBar

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, isCenter and 12 or 0)
		tabCorner.Parent = tabFrame

		if isCenter then
			-- 3D shadow for center button
			local shadow = Instance.new("Frame")
			shadow.Size = UDim2.new(1, 0, 0, 3)
			shadow.Position = UDim2.new(0, 0, 1, 0)
			shadow.BackgroundColor3 = tabInfo.shadow
			shadow.BorderSizePixel = 0
			shadow.Parent = tabFrame

			local shadowCorner = Instance.new("UICorner")
			shadowCorner.CornerRadius = UDim.new(0, 12)
			shadowCorner.Parent = shadow

			-- Outline
			local stroke = Instance.new("UIStroke")
			stroke.Color = tabInfo.shadow
			stroke.Thickness = 2
			stroke.Parent = tabFrame
		end

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(1, 0, 0, 28)
		iconLabel.Position = UDim2.new(0, 0, 0, isCenter and 6 or 6)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = tabInfo.icon
		iconLabel.TextSize = 22
		iconLabel.TextTransparency = isCenter and 0 or 0.2
		iconLabel.Font = Enum.Font.SourceSans
		iconLabel.Parent = tabFrame

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Label"
		textLabel.Size = UDim2.new(1, 0, 0, 14)
		textLabel.Position = UDim2.new(0, 0, 1, isCenter and -22 or -18)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = string.upper(tabInfo.name == "FreeSeed" and "FREE" or tabInfo.name)
		textLabel.TextColor3 = isCenter and UITheme.TEXT_ON_BTN or UITheme.TEXT_SECONDARY
		textLabel.TextSize = 9
		textLabel.Font = UITheme.FONT_BOLD
		textLabel.Parent = tabFrame

		-- Press animation
		local originalSize = tabFrame.Size
		tabFrame.MouseButton1Down:Connect(function()
			TweenService:Create(tabFrame, TweenInfo.new(0.05), {
				Size = isCenter and UDim2.new(0.19, 0, 1, 10) or UDim2.new(0.17, 0, 1, -10),
			}):Play()
		end)
		tabFrame.MouseButton1Up:Connect(function()
			TweenService:Create(tabFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = originalSize,
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
```

- [ ] **Step 2: Commit**

```bash
git add src/client/HUD.luau
git commit -m "feat: rewrite HUD with bright chunky Candy Pastel style"
```

---

### Task 5: Rewrite GardenUI.luau — Chunky pastel garden cards

**Files:**
- Rewrite: `src/client/GardenUI.luau`

- [ ] **Step 1: Rewrite GardenUI.luau**

Update all color references to use the new UITheme palette. Key changes from the current code:
- `UITheme.BG_LIST_ITEM` → white cards with colored borders
- `UITheme.MAGENTA` borders → `UITheme.PRIMARY` (pink)
- `UITheme.GREEN` → `UITheme.BTN_GREEN`
- `UITheme.YELLOW` → `UITheme.BTN_ORANGE`
- White text → `UITheme.TEXT_PRIMARY` (dark brown)
- Action buttons use `UITheme.createActionButton` with shadow colors
- Progress bar gradient: `UITheme.BTN_GREEN` → `UITheme.BTN_ORANGE`
- Water button: `UITheme.BTN_BLUE` with `UITheme.BTN_BLUE_SHADOW`
- Upgrade button: `UITheme.BTN_ORANGE` with `UITheme.BTN_ORANGE_SHADOW`
- Plant button color: `UITheme.BTN_PINK`
- Locked bed text: `UITheme.TEXT_SECONDARY`

Replace the entire file with the same structure but using the Candy Pastel colors. The logic (remote calls, bed states, progress bars) stays identical — only colors, text colors, and transparency values change.

The specific edits (all color swaps in GardenUI.luau):
- Line that sets `borderColor = UITheme.MAGENTA` → `borderColor = UITheme.PRIMARY`
- Line that sets `borderColor = UITheme.GREEN` → `borderColor = UITheme.BTN_GREEN`
- Line that sets `borderColor = UITheme.YELLOW` → `borderColor = UITheme.BTN_ORANGE`
- All `TextColor3 = Color3.fromRGB(255, 255, 255)` → `TextColor3 = UITheme.TEXT_PRIMARY`
- The `UITheme.YELLOW` in progress bar → `UITheme.BTN_GREEN`
- The `UITheme.ORANGE` in progress bar gradient → `UITheme.BTN_ORANGE`
- Water button disabled color `Color3.fromRGB(60, 60, 60)` → `Color3.fromRGB(200, 200, 200)`
- Water button active color `Color3.fromRGB(0, 136, 255)` → `UITheme.BTN_BLUE`
- Locked bed border `Color3.fromRGB(255, 255, 255)` borderTransparency 0.85 → `Color3.fromRGB(189, 189, 189)` borderTransparency 0.5
- Panel title text: kept as-is (createPanel handles it)
- Subtitle text transparency 0.5 → `TextColor3 = UITheme.TEXT_SECONDARY`
- Upgrade button `UITheme.YELLOW` with dark text → `UITheme.BTN_ORANGE` with white text, add `shadowColor = UITheme.BTN_ORANGE_SHADOW`

- [ ] **Step 2: Commit**

```bash
git add src/client/GardenUI.luau
git commit -m "feat: rewrite GardenUI with chunky Candy Pastel style"
```

---

### Task 6: Rewrite remaining UI modules

**Files:**
- Rewrite: `src/client/CollectionBook.luau`
- Rewrite: `src/client/ShopUI.luau`
- Rewrite: `src/client/DailyRewardsUI.luau`
- Rewrite: `src/client/DropAnimation.luau`
- Rewrite: `src/client/LeaderboardUI.luau`

- [ ] **Step 1: Update CollectionBook.luau colors**

Same pattern as GardenUI — swap all neon dark colors to Candy Pastel:
- All `Color3.fromRGB(255, 255, 255)` text → `UITheme.TEXT_PRIMARY`
- Section divider colors stay (they already use `UITheme.RARITY_COLORS` which were updated)
- Locked brainrot: white border → `Color3.fromRGB(189, 189, 189)`, text → `UITheme.TEXT_SECONDARY`
- Sell button `Color3.fromRGB(200, 80, 30)` → `UITheme.BTN_ORANGE`

- [ ] **Step 2: Update ShopUI.luau colors**

- `UITheme.MAGENTA` → `UITheme.PRIMARY`
- `UITheme.CYAN` → `UITheme.SECONDARY`
- `UITheme.YELLOW` → `UITheme.ACCENT_YELLOW`
- `UITheme.ORANGE` → `UITheme.BTN_ORANGE`
- All white text → `UITheme.TEXT_PRIMARY`
- Description text → `UITheme.TEXT_SECONDARY`
- Gamepass accent colors: update to match new palette (VIP = `UITheme.BTN_PINK`, Auto = `UITheme.BTN_BLUE`, Double = `UITheme.BTN_ORANGE`)

- [ ] **Step 3: Update DailyRewardsUI.luau**

- Streak label color: `UITheme.MAGENTA` → `UITheme.BTN_PINK`
- Streak lerp target: `UITheme.CYAN` → `UITheme.BTN_BLUE`
- Dot completed color: use pastel gradient `UITheme.PRIMARY:Lerp(UITheme.SECONDARY, t)`
- Dot current: `UITheme.BTN_PINK`
- Dot future: `UITheme.BG_SECONDARY` with light stroke
- Reward text: `UITheme.ACCENT_YELLOW` → `UITheme.BTN_ORANGE`
- Claim button: `UITheme.BTN_ORANGE` with shadow, add `shadowColor`
- Disabled button: `Color3.fromRGB(200, 200, 200)` instead of `(60, 60, 60)`
- All white text → `UITheme.TEXT_PRIMARY`

- [ ] **Step 4: Rewrite DropAnimation.luau**

Key changes:
- `dimBg` color: `Color3.fromRGB(0, 0, 0)` target transparency 0.5 → `Color3.fromRGB(255, 255, 255)` target transparency 0.3 (bright flash)
- `flash` for rare drops: use white with rarity tint instead of pure rarity color
- Card background: `UITheme.BG_PANEL` → `UITheme.BG_PRIMARY` (white)
- Card stroke: keep rarity color, thickness 3 (chunky)
- Rarity label text: keep rarity color, add `TextColor3 = rarityColor`
- Name label: `Color3.fromRGB(255, 255, 255)` → `UITheme.TEXT_PRIMARY`
- Chance text: keep rarity color
- Close text: → `UITheme.TEXT_SECONDARY`
- Particles for rare drops: use confetti colors (array of pastel colors) instead of single rarity color
- Each confetti particle gets a random pastel color
- Screen shake: keep as-is

- [ ] **Step 5: Rewrite LeaderboardUI.luau**

Current implementation is minimal (just updates leaderstats). No visual changes needed since it uses the default Roblox leaderboard. Skip this for now — a custom leaderboard UI can be added later.

- [ ] **Step 6: Commit all UI modules**

```bash
git add src/client/CollectionBook.luau src/client/ShopUI.luau src/client/DailyRewardsUI.luau src/client/DropAnimation.luau src/client/LeaderboardUI.luau
git commit -m "feat: rewrite all UI modules with Candy Pastel chunky style"
```

---

### Task 7: Update init.client.luau — Add Social tab + Home button + toast colors

**Files:**
- Modify: `src/client/init.client.luau`

- [ ] **Step 1: Update toast notification colors**

In the FreeSeed tab handler, replace:
- `toastFrame.BackgroundColor3 = UITheme.BG_CARD` → `toastFrame.BackgroundColor3 = UITheme.BG_PRIMARY`
- `UITheme.createNeonBorder(toastFrame, UITheme.GREEN, 1)` → create a UIStroke with `UITheme.BTN_GREEN`, thickness 2
- `toastLabel.TextColor3 = UITheme.GREEN` → `toastLabel.TextColor3 = UITheme.BTN_GREEN`

- [ ] **Step 2: Commit**

```bash
git add src/client/init.client.luau
git commit -m "feat: update client init with Candy Pastel toast colors"
```

---

## Phase 3: Social Systems

### Task 8: Create PlotManager.luau — Dynamic plot allocation

**Files:**
- Create: `src/server/PlotManager.luau`

- [ ] **Step 1: Create PlotManager.luau**

```luau
-- PlotManager: Allocates and releases player garden plots on the circular island
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local PlotManager = {}

-- Plot slot state: nil = free, Player = occupied
local plotSlots: { [number]: Player? } = {}
local playerPlots: { [number]: number } = {} -- userId -> slotIndex

-- Initialize 30 empty slots
for i = 0, Config.MAX_PLAYERS_PER_SERVER - 1 do
	plotSlots[i] = nil
end

function PlotManager.allocate(player: Player, data: any): number?
	-- Find first free slot
	for i = 0, Config.MAX_PLAYERS_PER_SERVER - 1 do
		if plotSlots[i] == nil then
			plotSlots[i] = player
			playerPlots[player.UserId] = i

			-- Activate plot visuals
			local plotSlot = Workspace:FindFirstChild("PlotSlots")
			if plotSlot then
				local marker = plotSlot:FindFirstChild("PlotSlot" .. i)
				if marker then
					-- Make floor visible
					local floor = marker:FindFirstChild("PlotFloor")
					if floor then
						TweenService:Create(floor, TweenInfo.new(0.5), {
							Transparency = 0,
						}):Play()
					end

					-- Add fence around plot
					local fenceFolder = Instance.new("Folder")
					fenceFolder.Name = "Fence"
					fenceFolder.Parent = marker

					local pos = marker.Position
					local halfSize = Config.PLOT_SIZE / 2
					local fenceData = {
						{ Vector3.new(pos.X - halfSize, pos.Y + 1.5, pos.Z), Vector3.new(0.5, 3, Config.PLOT_SIZE) },
						{ Vector3.new(pos.X + halfSize, pos.Y + 1.5, pos.Z), Vector3.new(0.5, 3, Config.PLOT_SIZE) },
						{ Vector3.new(pos.X, pos.Y + 1.5, pos.Z - halfSize), Vector3.new(Config.PLOT_SIZE, 3, 0.5) },
						{ Vector3.new(pos.X, pos.Y + 1.5, pos.Z + halfSize), Vector3.new(Config.PLOT_SIZE, 3, 0.5) },
					}

					for fi, fd in fenceData do
						local fence = Instance.new("Part")
						fence.Name = "Fence" .. fi
						fence.Size = fd[2]
						fence.Position = fd[1]
						fence.Anchored = true
						fence.Color = Color3.fromRGB(139, 90, 43)
						fence.Material = Enum.Material.Wood
						fence.Transparency = 0.2
						fence.Parent = fenceFolder
					end

					-- Name billboard
					local billboardPart = Instance.new("Part")
					billboardPart.Name = "NameSign"
					billboardPart.Size = Vector3.new(1, 1, 1)
					billboardPart.Position = pos + Vector3.new(0, 5, -halfSize)
					billboardPart.Anchored = true
					billboardPart.Transparency = 1
					billboardPart.CanCollide = false
					billboardPart.Parent = marker

					local bbGui = Instance.new("BillboardGui")
					bbGui.Size = UDim2.new(0, 120, 0, 40)
					bbGui.StudsOffset = Vector3.new(0, 2, 0)
					bbGui.Parent = billboardPart

					local nameLabel = Instance.new("TextLabel")
					nameLabel.Size = UDim2.new(1, 0, 1, 0)
					nameLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					nameLabel.BackgroundTransparency = 0.1
					nameLabel.Text = player.DisplayName .. "'s Garden"
					nameLabel.TextColor3 = Color3.fromRGB(93, 64, 55)
					nameLabel.TextScaled = true
					nameLabel.Font = Enum.Font.GothamBold
					nameLabel.Parent = bbGui

					local nameCorner = Instance.new("UICorner")
					nameCorner.CornerRadius = UDim.new(0, 8)
					nameCorner.Parent = nameLabel

					local nameStroke = Instance.new("UIStroke")
					nameStroke.Color = Color3.fromRGB(255, 181, 232)
					nameStroke.Thickness = 2
					nameStroke.Parent = nameLabel

					-- Generate garden beds on plot based on player data
					PlotManager.buildBeds(marker, data)
				end
			end

			return i
		end
	end

	return nil -- Server full
end

function PlotManager.buildBeds(marker: Instance, data: any)
	-- Remove existing beds if any
	local existingBeds = marker:FindFirstChild("Beds")
	if existingBeds then existingBeds:Destroy() end

	local bedsFolder = Instance.new("Folder")
	bedsFolder.Name = "Beds"
	bedsFolder.Parent = marker

	local pos = marker.Position
	local bedCount = data.garden.bedCount

	for i = 1, bedCount do
		local row = math.ceil(i / 4)
		local col = ((i - 1) % 4) + 1
		local bx = pos.X - 7 + (col - 1) * 5
		local bz = pos.Z - 3 + (row - 1) * 7

		local bed = Instance.new("Part")
		bed.Name = "Bed" .. i
		bed.Size = Vector3.new(4, 0.8, 4)
		bed.Position = Vector3.new(bx, pos.Y + 0.6, bz)
		bed.Anchored = true
		bed.Color = Color3.fromRGB(139, 90, 43)
		bed.Material = Enum.Material.Ground
		bed.Parent = bedsFolder

		-- Soil top
		local soil = Instance.new("Part")
		soil.Name = "Soil"
		soil.Size = Vector3.new(3.5, 0.3, 3.5)
		soil.Position = bed.Position + Vector3.new(0, 0.55, 0)
		soil.Anchored = true
		soil.Color = Color3.fromRGB(100, 70, 40)
		soil.Material = Enum.Material.Ground
		soil.Parent = bed
	end
end

function PlotManager.release(player: Player)
	local slotIndex = playerPlots[player.UserId]
	if slotIndex == nil then return end

	plotSlots[slotIndex] = nil
	playerPlots[player.UserId] = nil

	-- Fade out plot
	local plotSlotFolder = Workspace:FindFirstChild("PlotSlots")
	if plotSlotFolder then
		local marker = plotSlotFolder:FindFirstChild("PlotSlot" .. slotIndex)
		if marker then
			-- Fade all parts
			for _, desc in marker:GetDescendants() do
				if desc:IsA("BasePart") and desc.Transparency < 1 then
					TweenService:Create(desc, TweenInfo.new(Config.PLOT_FADE_TIME), {
						Transparency = 1,
					}):Play()
				end
				if desc:IsA("BillboardGui") then
					task.delay(Config.PLOT_FADE_TIME, function()
						desc:Destroy()
					end)
				end
			end

			-- Cleanup after fade
			task.delay(Config.PLOT_FADE_TIME + 0.5, function()
				local fence = marker:FindFirstChild("Fence")
				if fence then fence:Destroy() end
				local beds = marker:FindFirstChild("Beds")
				if beds then beds:Destroy() end
				local nameSign = marker:FindFirstChild("NameSign")
				if nameSign then nameSign:Destroy() end

				local floor = marker:FindFirstChild("PlotFloor")
				if floor then floor.Transparency = 0.8 end
			end)
		end
	end
end

function PlotManager.getPlotPosition(player: Player): Vector3?
	local slotIndex = playerPlots[player.UserId]
	if slotIndex == nil then return nil end

	local plotSlotFolder = Workspace:FindFirstChild("PlotSlots")
	if plotSlotFolder then
		local marker = plotSlotFolder:FindFirstChild("PlotSlot" .. slotIndex)
		if marker then return marker.Position end
	end
	return nil
end

function PlotManager.getSlotIndex(player: Player): number?
	return playerPlots[player.UserId]
end

return PlotManager
```

- [ ] **Step 2: Commit**

```bash
git add src/server/PlotManager.luau
git commit -m "feat: add PlotManager for dynamic player plot allocation"
```

---

### Task 9: Create TeleportManager.luau — Cross-server search and teleport

**Files:**
- Create: `src/server/TeleportManager.luau`

- [ ] **Step 1: Create TeleportManager.luau**

```luau
-- TeleportManager: Cross-server player search and teleportation
local TeleportService = game:GetService("TeleportService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")

local TeleportManager = {}

local SEARCH_TOPIC = "PlayerSearch"
local RESPONSE_TOPIC = "PlayerSearchResponse"
local homeJobIds: { [number]: string } = {} -- userId -> original JobId

function TeleportManager.init()
	-- Save home server for each player
	Players.PlayerAdded:Connect(function(player)
		homeJobIds[player.UserId] = game.JobId
	end)

	Players.PlayerRemoving:Connect(function(player)
		homeJobIds[player.UserId] = nil
	end)

	-- Listen for player search requests from other servers
	local success, err = pcall(function()
		MessagingService:SubscribeAsync(SEARCH_TOPIC, function(message)
			local data = message.Data
			local targetName = data.targetName
			local requesterJobId = data.requesterJobId

			-- Check if target player is on this server
			for _, player in Players:GetPlayers() do
				if string.lower(player.Name) == string.lower(targetName)
					or string.lower(player.DisplayName) == string.lower(targetName) then
					-- Found! Send response
					pcall(function()
						MessagingService:PublishAsync(RESPONSE_TOPIC, {
							targetName = player.Name,
							targetDisplayName = player.DisplayName,
							jobId = game.JobId,
							placeId = game.PlaceId,
							requesterJobId = requesterJobId,
						})
					end)
					return
				end
			end
		end)
	end)

	if not success then
		warn("[TeleportManager] Failed to subscribe to search topic: " .. tostring(err))
	end
end

function TeleportManager.searchPlayer(requester: Player, targetName: string, callback: (result: any?) -> ())
	local found = false

	-- First check local server
	for _, player in Players:GetPlayers() do
		if player ~= requester and (string.lower(player.Name) == string.lower(targetName)
			or string.lower(player.DisplayName) == string.lower(targetName)) then
			callback({
				targetName = player.Name,
				targetDisplayName = player.DisplayName,
				jobId = game.JobId,
				placeId = game.PlaceId,
				isLocal = true,
			})
			return
		end
	end

	-- Subscribe to responses temporarily
	local connection
	local success, err = pcall(function()
		connection = MessagingService:SubscribeAsync(RESPONSE_TOPIC, function(message)
			local data = message.Data
			if data.requesterJobId == game.JobId and not found then
				found = true
				data.isLocal = false
				callback(data)
				if connection then
					connection:Disconnect()
				end
			end
		end)
	end)

	if not success then
		warn("[TeleportManager] Failed to subscribe to response: " .. tostring(err))
		callback(nil)
		return
	end

	-- Publish search request
	pcall(function()
		MessagingService:PublishAsync(SEARCH_TOPIC, {
			targetName = targetName,
			requesterJobId = game.JobId,
		})
	end)

	-- Timeout after 5 seconds
	task.delay(5, function()
		if not found then
			found = true
			callback(nil)
			if connection then
				connection:Disconnect()
			end
		end
	end)
end

function TeleportManager.teleportToServer(player: Player, placeId: number, jobId: string)
	-- Save home before leaving
	homeJobIds[player.UserId] = game.JobId

	pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
	end)
end

function TeleportManager.teleportHome(player: Player)
	local homeJobId = homeJobIds[player.UserId]
	if homeJobId and homeJobId ~= game.JobId then
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, homeJobId, player)
		end)
	end
end

return TeleportManager
```

- [ ] **Step 2: Commit**

```bash
git add src/server/TeleportManager.luau
git commit -m "feat: add TeleportManager for cross-server search and teleport"
```

---

### Task 10: Create TradeManager.luau — Server-side trade logic

**Files:**
- Create: `src/server/TradeManager.luau`

- [ ] **Step 1: Create TradeManager.luau**

```luau
-- TradeManager: Server-side trade validation and execution
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDatabase = require(ReplicatedStorage.Shared.BrainrotDatabase)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local TradeManager = {}

-- Active trades: key = tradeId, value = trade state
local activeTrades: { [string]: any } = {}
-- Player -> active tradeId
local playerTrades: { [number]: string } = {}

local function generateTradeId(): string
	return tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
end

function TradeManager.initiateTrade(fromPlayer: Player, toPlayer: Player): string?
	-- Check neither player is already in a trade
	if playerTrades[fromPlayer.UserId] or playerTrades[toPlayer.UserId] then
		return nil
	end

	local tradeId = generateTradeId()
	activeTrades[tradeId] = {
		id = tradeId,
		fromUserId = fromPlayer.UserId,
		toUserId = toPlayer.UserId,
		fromOffer = {},
		toOffer = {},
		fromConfirmed = false,
		toConfirmed = false,
		createdAt = os.time(),
	}

	playerTrades[fromPlayer.UserId] = tradeId
	playerTrades[toPlayer.UserId] = tradeId

	-- Auto-expire
	task.delay(Config.TRADE_TIMEOUT * 4, function() -- generous timeout for selecting items
		TradeManager.cancelTrade(tradeId)
	end)

	return tradeId
end

function TradeManager.updateOffer(player: Player, brainrotIds: {string}): boolean
	local tradeId = playerTrades[player.UserId]
	if not tradeId then return false end

	local trade = activeTrades[tradeId]
	if not trade then return false end

	if #brainrotIds > Config.TRADE_MAX_ITEMS then return false end

	-- Validate player owns all offered brainrots
	local data = PlayerDataManager.getData(player)
	if not data then return false end

	for _, id in brainrotIds do
		local entry = data.collection[id]
		if not entry or entry.count < 1 then return false end
		if not BrainrotDatabase[id] then return false end
	end

	-- Reset confirmations when offer changes
	trade.fromConfirmed = false
	trade.toConfirmed = false

	if player.UserId == trade.fromUserId then
		trade.fromOffer = brainrotIds
	elseif player.UserId == trade.toUserId then
		trade.toOffer = brainrotIds
	end

	return true
end

function TradeManager.confirmTrade(player: Player): boolean
	local tradeId = playerTrades[player.UserId]
	if not tradeId then return false end

	local trade = activeTrades[tradeId]
	if not trade then return false end

	if player.UserId == trade.fromUserId then
		trade.fromConfirmed = true
	elseif player.UserId == trade.toUserId then
		trade.toConfirmed = true
	end

	-- Both confirmed? Execute trade
	if trade.fromConfirmed and trade.toConfirmed then
		return TradeManager.executeTrade(tradeId)
	end

	return true
end

function TradeManager.executeTrade(tradeId: string): boolean
	local trade = activeTrades[tradeId]
	if not trade then return false end

	local fromPlayer = game:GetService("Players"):GetPlayerByUserId(trade.fromUserId)
	local toPlayer = game:GetService("Players"):GetPlayerByUserId(trade.toUserId)
	if not fromPlayer or not toPlayer then
		TradeManager.cancelTrade(tradeId)
		return false
	end

	local fromData = PlayerDataManager.getData(fromPlayer)
	local toData = PlayerDataManager.getData(toPlayer)
	if not fromData or not toData then
		TradeManager.cancelTrade(tradeId)
		return false
	end

	-- Final validation: both still own their offers
	for _, id in trade.fromOffer do
		local entry = fromData.collection[id]
		if not entry or entry.count < 1 then
			TradeManager.cancelTrade(tradeId)
			return false
		end
	end
	for _, id in trade.toOffer do
		local entry = toData.collection[id]
		if not entry or entry.count < 1 then
			TradeManager.cancelTrade(tradeId)
			return false
		end
	end

	-- Execute: remove from sender, add to receiver
	for _, id in trade.fromOffer do
		fromData.collection[id].count -= 1
		if fromData.collection[id].count <= 0 then
			fromData.collection[id] = nil
			fromData.collectionCount -= 1
		end
		PlayerDataManager.addToCollection(toData, id)
	end

	for _, id in trade.toOffer do
		toData.collection[id].count -= 1
		if toData.collection[id].count <= 0 then
			toData.collection[id] = nil
			toData.collectionCount -= 1
		end
		PlayerDataManager.addToCollection(fromData, id)
	end

	-- Cleanup
	TradeManager.cancelTrade(tradeId)
	return true
end

function TradeManager.cancelTrade(tradeId: string)
	local trade = activeTrades[tradeId]
	if not trade then return end

	playerTrades[trade.fromUserId] = nil
	playerTrades[trade.toUserId] = nil
	activeTrades[tradeId] = nil
end

function TradeManager.getTrade(player: Player): any?
	local tradeId = playerTrades[player.UserId]
	if not tradeId then return nil end
	return activeTrades[tradeId]
end

function TradeManager.isInTrade(player: Player): boolean
	return playerTrades[player.UserId] ~= nil
end

return TradeManager
```

- [ ] **Step 2: Commit**

```bash
git add src/server/TradeManager.luau
git commit -m "feat: add TradeManager with server-side trade validation"
```

---

### Task 11: Update server init — Wire PlotManager, TeleportManager, TradeManager

**Files:**
- Modify: `src/server/init.server.luau`

- [ ] **Step 1: Add new manager requires and init**

After the existing manager requires (line ~24), add:

```luau
local PlotManager = require(script.PlotManager)
local TeleportManager = require(script.TeleportManager)
local TradeManager = require(script.TradeManager)

TeleportManager.init()
```

- [ ] **Step 2: Wire PlotManager into PlayerAdded/Removing**

In the `Players.PlayerAdded` handler, after `syncData(player)`, add:

```luau
		-- Allocate garden plot
		PlotManager.allocate(player, data)
		remotesFolder.PlotAllocated:FireClient(player, PlotManager.getSlotIndex(player))
```

Add a `Players.PlayerRemoving` handler (currently only in PlayerDataManager):

```luau
Players.PlayerRemoving:Connect(function(player)
	PlotManager.release(player)
end)
```

- [ ] **Step 3: Wire social remote handlers**

Add at the end of init.server.luau, before the print statement:

```luau
-- Search player (cross-server)
remotesFolder.SearchPlayer.OnServerEvent:Connect(function(player, targetName: string)
	TeleportManager.searchPlayer(player, targetName, function(result)
		if result then
			remotesFolder.TradeUpdate:FireClient(player, { type = "searchResult", data = result })
		else
			remotesFolder.TradeUpdate:FireClient(player, { type = "searchResult", data = nil })
		end
	end)
end)

-- Teleport to player
remotesFolder.TeleportToPlayer.OnServerEvent:Connect(function(player, placeId: number, jobId: string)
	TeleportManager.teleportToServer(player, placeId, jobId)
end)

-- Teleport home
remotesFolder.TeleportHome.OnServerEvent:Connect(function(player)
	TeleportManager.teleportHome(player)
end)

-- Initiate trade
remotesFolder.InitiateTrade.OnServerEvent:Connect(function(player, targetUserId: number)
	local targetPlayer = game:GetService("Players"):GetPlayerByUserId(targetUserId)
	if not targetPlayer then return end

	local tradeId = TradeManager.initiateTrade(player, targetPlayer)
	if tradeId then
		local trade = TradeManager.getTrade(player)
		remotesFolder.TradeRequest:FireClient(player, trade)
		remotesFolder.TradeRequest:FireClient(targetPlayer, trade)
	end
end)

-- Update trade offer
remotesFolder.UpdateTradeOffer.OnServerEvent:Connect(function(player, brainrotIds: {string})
	if TradeManager.updateOffer(player, brainrotIds) then
		local trade = TradeManager.getTrade(player)
		local fromPlayer = game:GetService("Players"):GetPlayerByUserId(trade.fromUserId)
		local toPlayer = game:GetService("Players"):GetPlayerByUserId(trade.toUserId)
		if fromPlayer then remotesFolder.TradeUpdate:FireClient(fromPlayer, { type = "offerUpdate", data = trade }) end
		if toPlayer then remotesFolder.TradeUpdate:FireClient(toPlayer, { type = "offerUpdate", data = trade }) end
	end
end)

-- Confirm trade
remotesFolder.ConfirmTrade.OnServerEvent:Connect(function(player)
	local trade = TradeManager.getTrade(player)
	if not trade then return end

	local executed = TradeManager.confirmTrade(player)
	local fromPlayer = game:GetService("Players"):GetPlayerByUserId(trade.fromUserId)
	local toPlayer = game:GetService("Players"):GetPlayerByUserId(trade.toUserId)

	if executed and not TradeManager.getTrade(player) then
		-- Trade was executed and cleaned up
		if fromPlayer then
			syncData(fromPlayer)
			remotesFolder.TradeUpdate:FireClient(fromPlayer, { type = "completed" })
		end
		if toPlayer then
			syncData(toPlayer)
			remotesFolder.TradeUpdate:FireClient(toPlayer, { type = "completed" })
		end
	else
		-- Partial confirmation
		trade = TradeManager.getTrade(player)
		if trade then
			if fromPlayer then remotesFolder.TradeUpdate:FireClient(fromPlayer, { type = "confirmUpdate", data = trade }) end
			if toPlayer then remotesFolder.TradeUpdate:FireClient(toPlayer, { type = "confirmUpdate", data = trade }) end
		end
	end
end)

-- Cancel trade
remotesFolder.CancelTrade.OnServerEvent:Connect(function(player)
	local trade = TradeManager.getTrade(player)
	if trade then
		local fromPlayer = game:GetService("Players"):GetPlayerByUserId(trade.fromUserId)
		local toPlayer = game:GetService("Players"):GetPlayerByUserId(trade.toUserId)
		TradeManager.cancelTrade(trade.id)
		if fromPlayer then remotesFolder.TradeUpdate:FireClient(fromPlayer, { type = "cancelled" }) end
		if toPlayer then remotesFolder.TradeUpdate:FireClient(toPlayer, { type = "cancelled" }) end
	end
end)

-- Like garden
remotesFolder.LikeGarden.OnServerEvent:Connect(function(player, targetUserId: number)
	local targetPlayer = game:GetService("Players"):GetPlayerByUserId(targetUserId)
	if not targetPlayer or targetPlayer == player then return end

	local targetData = PlayerDataManager.getData(targetPlayer)
	if targetData then
		targetData.stats.gardenLikes = (targetData.stats.gardenLikes or 0) + 1
		syncData(targetPlayer)
	end
end)
```

- [ ] **Step 4: Add RemoteFunction for SearchPlayer**

Note: `SearchPlayer` needs to be a RemoteFunction (not RemoteEvent) since it returns a result. However, the async callback pattern works better with events. The current implementation uses `TradeUpdate` event to send search results back. This is correct — no RemoteFunction needed.

But we need to ensure the new remotes also include some that should be RemoteFunctions. For simplicity, keep all as RemoteEvents (the callback pattern via TradeUpdate works).

- [ ] **Step 5: Commit**

```bash
git add src/server/init.server.luau
git commit -m "feat: wire PlotManager, TeleportManager, TradeManager into server init"
```

---

### Task 12: Create SocialUI.luau — Social tab with search, trade panel

**Files:**
- Create: `src/client/SocialUI.luau`

- [ ] **Step 1: Create SocialUI.luau**

```luau
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
```

- [ ] **Step 2: Wire SocialUI into init.client.luau**

Add require at top:
```luau
local SocialUI = require(script.SocialUI)
```

Add create call:
```luau
SocialUI.create()
```

Add tab (need to add a "Social" tab to HUD). This requires modifying HUD.luau to add a 6th tab. Add to the `tabs` table in HUD.luau:

```luau
{ name = "Social", icon = "\u{1F465}", order = 6, color = UITheme.BTN_BLUE, shadow = UITheme.BTN_BLUE_SHADOW },
```

And adjust tab widths to accommodate 6 tabs: change `0.18` to `0.15` and center tab `0.2` to `0.17`.

Wire the tab in init.client.luau:
```luau
wireTab("Social", function()
	SocialUI.toggle()
end)
```

- [ ] **Step 3: Commit**

```bash
git add src/client/SocialUI.luau src/client/init.client.luau src/client/HUD.luau
git commit -m "feat: add SocialUI with player search and teleport"
```

---

### Task 13: Add ProximityPrompt trade trigger

**Files:**
- Modify: `src/client/init.client.luau`

- [ ] **Step 1: Add ProximityPrompt for trade**

Add at the end of init.client.luau, before the print statement:

```luau
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
```

- [ ] **Step 2: Commit**

```bash
git add src/client/init.client.luau
git commit -m "feat: add ProximityPrompt trade trigger on player characters"
```

---

### Task 14: Integration test in Studio

- [ ] **Step 1: Run `rojo serve` and sync to Studio**

- [ ] **Step 2: Enter Play mode and verify**

Check all of these:
- [ ] Circular island with terrain, pond, fountain
- [ ] Hub buildings (pink shop, blue leaderboard, yellow trend radar)
- [ ] Trees, flowers, balloons, lampposts
- [ ] Warm pastel lighting with bloom
- [ ] White HUD top bar with colored pill borders
- [ ] Chunky tab bar with 3D center button
- [ ] Garden UI opens with white cards, colored borders
- [ ] Collection book with rarity-colored borders
- [ ] Shop with chunky 3D buttons
- [ ] Daily rewards with pastel streak dots
- [ ] Drop animation with bright flash and confetti
- [ ] Social tab with search box
- [ ] Player plot allocated on join with fence and name sign
- [ ] Toast notification uses pastel colors

- [ ] **Step 3: Fix any issues found**

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete Candy Pastel visual overhaul"
```
