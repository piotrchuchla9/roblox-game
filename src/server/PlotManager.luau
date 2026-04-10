-- PlotManager: Allocates and releases player garden plots on the 3x3 grid island
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local PlotManager = {}

-- Callback set by init.server to handle bed unlock (avoids circular deps)
PlotManager.onUnlockBed = nil :: ((player: Player) -> ())?

-- Plot slot state: nil = free, Player = occupied
local plotSlots: { [number]: Player? } = {}
local playerPlots: { [number]: number } = {} -- userId -> slotIndex

-- Initialize 30 empty slots
for i = 0, Config.PLOT_COUNT - 1 do
	plotSlots[i] = nil
end

function PlotManager.allocate(player: Player, data: any): number?
	-- Find first free slot
	for i = 0, Config.PLOT_COUNT - 1 do
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

	for i = 1, Config.MAX_BED_COUNT do
		local row = math.ceil(i / 4)
		local col = ((i - 1) % 4) + 1
		local bx = pos.X - 7 + (col - 1) * 5
		local bz = pos.Z - 3 + (row - 1) * 7

		local bed = Instance.new("Part")
		bed.Name = "Bed" .. i
		bed.Size = Vector3.new(4, 0.8, 4)
		bed.Position = Vector3.new(bx, pos.Y + 0.6, bz)
		bed.Anchored = true
		bed.Parent = bedsFolder

		if i <= bedCount then
			-- Unlocked bed
			bed.Color = Color3.fromRGB(139, 90, 43)
			bed.Material = Enum.Material.Ground

			local soil = Instance.new("Part")
			soil.Name = "Soil"
			soil.Size = Vector3.new(3.5, 0.3, 3.5)
			soil.Position = bed.Position + Vector3.new(0, 0.55, 0)
			soil.Anchored = true
			soil.Color = Color3.fromRGB(100, 70, 40)
			soil.Material = Enum.Material.Ground
			soil.Parent = bed
		else
			-- Locked bed
			bed.Color = Color3.fromRGB(140, 140, 150)
			bed.Material = Enum.Material.Slate

			local bbPart = Instance.new("Part")
			bbPart.Name = "LockSign"
			bbPart.Size = Vector3.new(1, 1, 1)
			bbPart.Position = bed.Position + Vector3.new(0, 2, 0)
			bbPart.Anchored = true
			bbPart.Transparency = 1
			bbPart.CanCollide = false
			bbPart.Parent = bed

			local bbGui = Instance.new("BillboardGui")
			bbGui.Size = UDim2.new(0, 80, 0, 30)
			bbGui.StudsOffset = Vector3.new(0, 1, 0)
			bbGui.Parent = bbPart

			local lockLabel = Instance.new("TextLabel")
			lockLabel.Size = UDim2.new(1, 0, 1, 0)
			lockLabel.BackgroundTransparency = 1
			lockLabel.Text = "LOCKED"
			lockLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			lockLabel.TextScaled = true
			lockLabel.Font = Enum.Font.GothamBold
			lockLabel.Parent = bbGui

			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "UnlockPrompt"
			prompt.ActionText = "Unlock"
			prompt.ObjectText = Config.BED_UPGRADE_COST .. " seeds"
			prompt.MaxActivationDistance = 6
			prompt.HoldDuration = 0.5
			prompt.RequiresLineOfSight = false
			prompt.Parent = bed

			prompt.Triggered:Connect(function(triggerPlayer)
				-- Only plot owner can unlock beds
				local ownerSlot = playerPlots[triggerPlayer.UserId]
				local markerName = marker.Name -- e.g. "PlotSlot0"
				local slotNum = tonumber(markerName:match("%d+$"))
				if ownerSlot ~= slotNum then return end

				if PlotManager.onUnlockBed then
					PlotManager.onUnlockBed(triggerPlayer)
				end
			end)
		end
	end
end

function PlotManager.rebuildBeds(player: Player, data: any)
	local slotIndex = playerPlots[player.UserId]
	if slotIndex == nil then return end

	local plotSlotFolder = Workspace:FindFirstChild("PlotSlots")
	if not plotSlotFolder then return end

	local marker = plotSlotFolder:FindFirstChild("PlotSlot" .. slotIndex)
	if marker then
		PlotManager.buildBeds(marker, data)
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
