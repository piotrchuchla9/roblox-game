-- MapSetup: Creates the Candy Pastel circular island world
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local MapSetup = {}

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
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = crown
end

local function makeFlower(position: Vector3, parent: Instance)
	local colors = {
		Color3.fromRGB(255, 181, 232),
		Color3.fromRGB(181, 222, 255),
		Color3.fromRGB(255, 245, 186),
		Color3.fromRGB(220, 211, 255),
		Color3.fromRGB(231, 255, 172),
	}
	local color = colors[math.random(1, #colors)]
	makePart({
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

local function makeBalloon(position: Vector3, parent: Instance)
	local colors = {
		Color3.fromRGB(255, 181, 232),
		Color3.fromRGB(181, 222, 255),
		Color3.fromRGB(255, 245, 186),
		Color3.fromRGB(220, 211, 255),
	}
	local color = colors[math.random(1, #colors)]
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

	local ISLAND_RADIUS = Config.ISLAND_RADIUS
	local resolution = 4

	for x = -ISLAND_RADIUS, ISLAND_RADIUS, resolution do
		for z = -ISLAND_RADIUS, ISLAND_RADIUS, resolution do
			local dist = math.sqrt(x * x + z * z)
			if dist <= ISLAND_RADIUS then
				local height = 2 + math.sin(x * 0.05) * 1.5 + math.cos(z * 0.07) * 1.2
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

	-- Pond in hub
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

	-- Stone paths (8 paths to plots)
	for i = 0, Config.PLOT_COUNT - 1 do
		local angle = (i / Config.PLOT_COUNT) * math.pi * 2
		for d = Config.HUB_RADIUS, Config.PLOT_RING_RADIUS - 5, resolution do
			local px = math.cos(angle) * d
			local pz = math.sin(angle) * d
			local region = Region3.new(
				Vector3.new(px - 2, -1, pz - 2),
				Vector3.new(px + 2, 2.5, pz + 2)
			)
			terrain:FillRegion(region:ExpandToGrid(resolution), resolution, Enum.Material.Slate)
		end
	end

	-- === DECORATIONS ===
	local decoFolder = Instance.new("Folder")
	decoFolder.Name = "Decorations"
	decoFolder.Parent = Workspace

	-- === SPAWN ===
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 2.5, -25)
	spawn.Anchored = true
	spawn.Color = Color3.fromRGB(255, 181, 232)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Parent = Workspace

	-- === HUB BUILDINGS ===
	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "Hub"
	hubFolder.Parent = Workspace

	-- Shop (pink)
	local shopBase = makePart({
		name = "ShopBuilding", size = Vector3.new(14, 10, 12),
		position = Vector3.new(25, 7, 0),
		color = Color3.fromRGB(255, 200, 230), parent = hubFolder,
	})
	makePart({
		name = "ShopRoof", size = Vector3.new(16, 2, 14),
		position = Vector3.new(25, 13, 0),
		color = Color3.fromRGB(233, 30, 99), parent = hubFolder,
	})
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

	-- Deco Shop (green/wood, opposite side of Shop)
	local decoBase = makePart({
		name = "DecoShopBuilding", size = Vector3.new(14, 10, 12),
		position = Vector3.new(-25, 7, 0),
		color = Color3.fromRGB(200, 230, 200), parent = hubFolder,
	})
	makePart({
		name = "DecoShopRoof", size = Vector3.new(16, 2, 14),
		position = Vector3.new(-25, 13, 0),
		color = Color3.fromRGB(76, 153, 0), parent = hubFolder,
	})
	local decoSign = Instance.new("SurfaceGui")
	decoSign.Name = "DecoSign"
	decoSign.Face = Enum.NormalId.Front
	decoSign.Parent = decoBase
	local decoText = Instance.new("TextLabel")
	decoText.Size = UDim2.new(1, 0, 0.4, 0)
	decoText.Position = UDim2.new(0, 0, 0.1, 0)
	decoText.BackgroundTransparency = 1
	decoText.Text = "DECO SHOP"
	decoText.TextColor3 = Color3.fromRGB(93, 64, 55)
	decoText.TextScaled = true
	decoText.Font = Enum.Font.GothamBold
	decoText.Parent = decoSign

	-- ProximityPrompt: Shop
	local shopPrompt = Instance.new("ProximityPrompt")
	shopPrompt.Name = "ShopPrompt"
	shopPrompt.ActionText = "Shop"
	shopPrompt.ObjectText = ""
	shopPrompt.MaxActivationDistance = Config.SHOP_PROMPT_DISTANCE
	shopPrompt.HoldDuration = 0
	shopPrompt.RequiresLineOfSight = false
	shopPrompt.Parent = shopBase

	-- ProximityPrompt: Deco Shop
	local decoPrompt = Instance.new("ProximityPrompt")
	decoPrompt.Name = "DecoShopPrompt"
	decoPrompt.ActionText = "Deco Shop"
	decoPrompt.ObjectText = ""
	decoPrompt.MaxActivationDistance = Config.SHOP_PROMPT_DISTANCE
	decoPrompt.HoldDuration = 0
	decoPrompt.RequiresLineOfSight = false
	decoPrompt.Parent = decoBase

	-- Leaderboard (blue, behind fountain)
	makePart({
		name = "LeaderboardBuilding", size = Vector3.new(12, 10, 12),
		position = Vector3.new(0, 7, 25),
		color = Color3.fromRGB(200, 225, 255), parent = hubFolder,
	})
	makePart({
		name = "LeaderboardRoof", size = Vector3.new(14, 2, 14),
		position = Vector3.new(0, 13, 25),
		color = Color3.fromRGB(33, 150, 243), parent = hubFolder,
	})

	-- Trend Radar (yellow billboard, behind leaderboard)
	local billboard = makePart({
		name = "TrendRadar", size = Vector3.new(14, 8, 1),
		position = Vector3.new(0, 8, 38),
		color = Color3.fromRGB(255, 245, 186), parent = hubFolder,
	})
	makePart({ name = "TrendPost1", size = Vector3.new(1, 12, 1), position = Vector3.new(-6, 6, 38), color = Color3.fromRGB(139, 90, 43), material = Enum.Material.Wood, parent = hubFolder })
	makePart({ name = "TrendPost2", size = Vector3.new(1, 12, 1), position = Vector3.new(6, 6, 38), color = Color3.fromRGB(139, 90, 43), material = Enum.Material.Wood, parent = hubFolder })

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

	-- Benches
	for i = 0, 1 do
		local angle = (i / 2) * math.pi * 2 + math.pi / 4
		local bx = math.cos(angle) * 18
		local bz = math.sin(angle) * 18
		makePart({ name = "Bench" .. i, size = Vector3.new(4, 1.5, 1.5), position = Vector3.new(bx, 3, bz), color = Color3.fromRGB(139, 90, 43), material = Enum.Material.Wood, parent = hubFolder })
	end

	-- Balloons
	for i = 1, 3 do
		local angle = (i / 3) * math.pi * 2
		makeBalloon(Vector3.new(math.cos(angle) * 25, 2.5, math.sin(angle) * 25), decoFolder)
	end

	-- Lampposts
	for i = 0, 3 do
		local angle = (i / 4) * math.pi * 2
		local lx = math.cos(angle) * 30
		local lz = math.sin(angle) * 30
		makePart({ name = "LampPole" .. i, size = Vector3.new(0.6, 8, 0.6), position = Vector3.new(lx, 6, lz), color = Color3.fromRGB(200, 200, 200), material = Enum.Material.Metal, parent = decoFolder })
		local lamp = makePart({ name = "LampLight" .. i, size = Vector3.new(2, 1, 2), position = Vector3.new(lx, 10.5, lz), color = Color3.fromRGB(255, 245, 186), material = Enum.Material.Neon, parent = decoFolder })
		local pointLight = Instance.new("PointLight")
		pointLight.Color = Color3.fromRGB(255, 240, 220)
		pointLight.Brightness = 0.5
		pointLight.Range = 20
		pointLight.Parent = lamp
	end

	-- === PLOT MARKERS (8 slots) ===
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "PlotSlots"
	plotsFolder.Parent = Workspace

	for i = 0, Config.PLOT_COUNT - 1 do
		local angle = (i / Config.PLOT_COUNT) * math.pi * 2
		local px = math.cos(angle) * Config.PLOT_RING_RADIUS
		local pz = math.sin(angle) * Config.PLOT_RING_RADIUS

		local marker = Instance.new("Part")
		marker.Name = "PlotSlot" .. i
		marker.Size = Vector3.new(Config.PLOT_SIZE, 0.2, Config.PLOT_SIZE)
		marker.Position = Vector3.new(px, 2, pz)
		marker.Anchored = true
		marker.Transparency = 1
		marker.CanCollide = false
		marker.Parent = plotsFolder

		makePart({
			name = "PlotFloor",
			size = Vector3.new(Config.PLOT_SIZE - 2, 0.3, Config.PLOT_SIZE - 2),
			position = Vector3.new(px, 2.2, pz),
			color = Color3.fromRGB(200, 180, 140),
			material = Enum.Material.WoodPlanks,
			transparency = 0.8,
			canCollide = false,
			parent = marker,
		})
	end

	-- === TREES (reduced) ===
	math.randomseed(42)
	for i = 1, 15 do
		local angle = math.random() * math.pi * 2
		local dist = 30 + math.random() * 50
		local tx = math.cos(angle) * dist
		local tz = math.sin(angle) * dist
		local tooClose = false
		for s = 0, Config.PLOT_COUNT - 1 do
			local sa = (s / Config.PLOT_COUNT) * math.pi * 2
			local sx = math.cos(sa) * Config.PLOT_RING_RADIUS
			local sz = math.sin(sa) * Config.PLOT_RING_RADIUS
			if (tx - sx)^2 + (tz - sz)^2 < 15^2 then
				tooClose = true
				break
			end
		end
		if (tx^2 + tz^2) < Config.HUB_RADIUS^2 then
			tooClose = true
		end
		if not tooClose then
			makeTree(Vector3.new(tx, 2, tz), decoFolder)
		end
	end

	-- === FLOWERS (reduced) ===
	for i = 1, 20 do
		local angle = math.random() * math.pi * 2
		local dist = 10 + math.random() * 70
		makeFlower(Vector3.new(math.cos(angle) * dist + math.random(-3, 3), 2, math.sin(angle) * dist + math.random(-3, 3)), decoFolder)
	end

	-- === FOUNTAIN ===
	local fountain = makePart({
		name = "Fountain", size = Vector3.new(4, 3, 4),
		position = Vector3.new(0, 3, 0),
		color = Color3.fromRGB(220, 220, 230),
		material = Enum.Material.Marble, parent = hubFolder,
	})

	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 1.5, 0)
	attachment.Parent = fountain

	local waterParticles = Instance.new("ParticleEmitter")
	waterParticles.Color = ColorSequence.new(Color3.fromRGB(181, 222, 255))
	waterParticles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.1) })
	waterParticles.Lifetime = NumberRange.new(1, 2)
	waterParticles.Rate = 30
	waterParticles.Speed = NumberRange.new(4, 6)
	waterParticles.SpreadAngle = Vector2.new(15, 15)
	waterParticles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	waterParticles.Parent = attachment

	local sparkleAttachment = Instance.new("Attachment")
	sparkleAttachment.Position = Vector3.new(0, 2, 0)
	sparkleAttachment.Parent = fountain

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 220)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 245, 186)) })
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Lifetime = NumberRange.new(3, 5)
	sparkles.Rate = 8
	sparkles.Speed = NumberRange.new(0.3, 0.8)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
	sparkles.Parent = sparkleAttachment

	-- === LIGHTING ===
	Lighting.ClockTime = 14
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(180, 170, 190)
	Lighting.OutdoorAmbient = Color3.fromRGB(200, 195, 210)

	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("SunRaysEffect") then
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

	local cols = Config.PLOT_COUNT
	local ringR = Config.PLOT_RING_RADIUS
	print("[Server] Map built — " .. cols .. " plots on " .. ringR .. " stud ring, island radius " .. ISLAND_RADIUS)
end

function MapSetup.getShopPart(): Part?
	local hub = Workspace:FindFirstChild("Hub")
	return hub and hub:FindFirstChild("ShopBuilding")
end

function MapSetup.getDecoShopPart(): Part?
	local hub = Workspace:FindFirstChild("Hub")
	return hub and hub:FindFirstChild("DecoShopBuilding")
end

return MapSetup
