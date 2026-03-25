-- MapSetup: Creates the 3D game world on server start
-- This generates placeholder geometry. Replace with proper models later.

local Workspace = game:GetService("Workspace")

local MapSetup = {}

function MapSetup.build()
	-- Main platform
	local platform = Instance.new("Part")
	platform.Name = "MainPlatform"
	platform.Size = Vector3.new(200, 2, 200)
	platform.Position = Vector3.new(0, -1, 0)
	platform.Anchored = true
	platform.BrickColor = BrickColor.new("Bright green")
	platform.Material = Enum.Material.Grass
	platform.Parent = Workspace

	-- Spawn location
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 0.5, -30)
	spawn.Anchored = true
	spawn.BrickColor = BrickColor.new("White")
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Parent = Workspace

	-- Garden area marker
	local gardenArea = Instance.new("Part")
	gardenArea.Name = "GardenArea"
	gardenArea.Size = Vector3.new(50, 0.5, 40)
	gardenArea.Position = Vector3.new(0, 0.25, 0)
	gardenArea.Anchored = true
	gardenArea.BrickColor = BrickColor.new("Brown")
	gardenArea.Material = Enum.Material.Ground
	gardenArea.Parent = Workspace

	-- Garden beds (visual placeholders — 8 max beds in 2 rows)
	local bedsFolder = Instance.new("Folder")
	bedsFolder.Name = "GardenBeds"
	bedsFolder.Parent = Workspace

	for i = 1, 8 do
		local row = math.ceil(i / 4)
		local col = ((i - 1) % 4) + 1

		local bed = Instance.new("Part")
		bed.Name = "Bed" .. i
		bed.Size = Vector3.new(8, 1, 8)
		bed.Position = Vector3.new(-15 + (col - 1) * 10, 0.75, -5 + (row - 1) * 12)
		bed.Anchored = true
		bed.BrickColor = BrickColor.new("Reddish brown")
		bed.Material = Enum.Material.Ground
		bed.Parent = bedsFolder

		-- Soil mound inside bed
		local soil = Instance.new("Part")
		soil.Name = "Soil"
		soil.Size = Vector3.new(6, 0.5, 6)
		soil.Position = bed.Position + Vector3.new(0, 0.75, 0)
		soil.Anchored = true
		soil.BrickColor = BrickColor.new("Dark orange")
		soil.Material = Enum.Material.Ground
		soil.Parent = bed
	end

	-- Decorative fence around garden
	local fencePositions = {
		{ pos = Vector3.new(-25, 2, 0), size = Vector3.new(1, 4, 44) },
		{ pos = Vector3.new(25, 2, 0), size = Vector3.new(1, 4, 44) },
		{ pos = Vector3.new(0, 2, -22), size = Vector3.new(50, 4, 1) },
		{ pos = Vector3.new(0, 2, 22), size = Vector3.new(50, 4, 1) },
	}

	for i, f in fencePositions do
		local fence = Instance.new("Part")
		fence.Name = "Fence" .. i
		fence.Size = f.size
		fence.Position = f.pos
		fence.Anchored = true
		fence.BrickColor = BrickColor.new("Brown")
		fence.Material = Enum.Material.Wood
		fence.Transparency = 0.3
		fence.Parent = Workspace
	end

	-- Trend Radar billboard
	local billboard = Instance.new("Part")
	billboard.Name = "TrendRadar"
	billboard.Size = Vector3.new(12, 8, 1)
	billboard.Position = Vector3.new(0, 6, -25)
	billboard.Anchored = true
	billboard.BrickColor = BrickColor.new("Really black")
	billboard.Material = Enum.Material.SmoothPlastic
	billboard.Parent = Workspace

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "TrendDisplay"
	surfaceGui.Face = Enum.NormalId.Back
	surfaceGui.Parent = billboard

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "TREND RADAR"
	titleLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = surfaceGui

	local trendLabel = Instance.new("TextLabel")
	trendLabel.Name = "CurrentTrend"
	trendLabel.Size = UDim2.new(1, 0, 0.5, 0)
	trendLabel.Position = UDim2.new(0, 0, 0.3, 0)
	trendLabel.BackgroundTransparency = 1
	trendLabel.Text = "Season 1: OG Brainrot"
	trendLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	trendLabel.TextScaled = true
	trendLabel.Font = Enum.Font.GothamBold
	trendLabel.Parent = surfaceGui

	local weeklyLabel = Instance.new("TextLabel")
	weeklyLabel.Name = "WeeklyBrainrot"
	weeklyLabel.Size = UDim2.new(1, 0, 0.2, 0)
	weeklyLabel.Position = UDim2.new(0, 0, 0.8, 0)
	weeklyLabel.BackgroundTransparency = 1
	weeklyLabel.Text = "Weekly: Bombardiro Crocodilo"
	weeklyLabel.TextColor3 = Color3.fromRGB(50, 200, 255)
	weeklyLabel.TextScaled = true
	weeklyLabel.Font = Enum.Font.Gotham
	weeklyLabel.Parent = surfaceGui

	-- Lighting / atmosphere
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14 -- afternoon sun
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(120, 120, 140)

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(200, 220, 255)
	atmosphere.Parent = lighting

	print("[Server] Map built successfully")
end

return MapSetup
