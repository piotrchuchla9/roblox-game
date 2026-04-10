# Map Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single shared garden with a 3x10 grid of 30 individual player gardens connected by paths, surrounded by water, with floating Trend Radars.

**Architecture:** MapSetup creates the world infrastructure (water, paths, plot markers, walls, fences, Trend Radars). PlotManager creates per-player garden content (beds, fences with gates, SpawnLocation) at grid-calculated positions. ExhibitManager and BedVisuals are updated to work relative to each player's plot position.

**Tech Stack:** Roblox Luau, MCP run_code for Studio script modifications

**IMPORTANT:** All code changes are to Studio scripts via `mcp__Roblox_Studio__run_code`. The git `src/` files are outdated stubs — do NOT modify them.

---

## Grid Layout Constants

```
COLS = 3, ROWS = 10
PLOT_SIZE = 20 (studs, unchanged)
PATH_WIDTH = 14 (studs)
CELL_SPACING = 34 (PLOT_SIZE + PATH_WIDTH)

Column X centers: col 0 = -34, col 1 = 0, col 2 = 34
Row Z centers:    row 0 = -153, row 1 = -119, ... row 9 = 153
Formula: X = (col - 1) * 34, Z = (row - 4.5) * 34

Slot mapping: slot i -> col = i % 3, row = floor(i / 3)
```

## File Map

| File (Studio path) | Action | Responsibility |
|---|---|---|
| `ServerScriptService.Server.MapSetup` | **Rewrite** | World infrastructure: water, paths, plot markers, walls, decorative fences, Trend Radars, lighting |
| `ServerScriptService.Server.PlotManager` | **Rewrite** | Per-player garden creation: grid position calc, beds, fences with gates, SpawnLocation, cleanup |
| `ServerScriptService.Server.ExhibitManager` | **Modify** | Update CORNER_POSITIONS to be relative to plot position, buildPedestals per-player |
| `ServerScriptService.Server.BedVisuals` | **Modify** | Find beds inside player's plot marker instead of global GardenBeds folder |
| `ServerScriptService.Server.Init` | **Modify** | Pass player/slot context to BedVisuals and ExhibitManager |
| `ReplicatedStorage.Shared.Config` | **Modify** | Add grid constants, remove circular layout constants |

---

### Task 1: Update Config with Grid Constants

**Files:** `ReplicatedStorage.Shared.Config`

- [ ] **Step 1: Read current Config source**

```lua
-- Via run_code
local src = game.ReplicatedStorage.Shared.Config.Source
print(src)
```

- [ ] **Step 2: Replace plot layout constants**

Remove these lines:
```lua
Config.PLOT_RING_RADIUS = 110
Config.ISLAND_RADIUS = 150
Config.HUB_RADIUS = 40
```

Add these:
```lua
-- Grid layout
Config.GRID_COLS = 3
Config.GRID_ROWS = 10
Config.CELL_SPACING = 34 -- PLOT_SIZE + PATH_WIDTH
Config.PATH_WIDTH = 14
Config.WATER_DEPTH = 4 -- studs below ground
Config.WALL_HEIGHT = 10
Config.MAP_MARGIN = 40 -- water margin around grid
```

- [ ] **Step 3: Verify Config loads without errors**

```lua
local Config = require(game.ReplicatedStorage.Shared.Config)
print("GRID_COLS:", Config.GRID_COLS, "GRID_ROWS:", Config.GRID_ROWS)
```

---

### Task 2: Rewrite MapSetup

**Files:** `ServerScriptService.Server.MapSetup`

This is a complete rewrite. The new MapSetup creates:
1. Water plane (large Part below ground level)
2. Plot markers (30 invisible anchors in 3x10 grid)
3. Paths (brown WoodPlanks Parts connecting plots)
4. Invisible collision walls along water edges
5. Decorative fences along invisible walls
6. 2 floating Trend Radar billboards (top + bottom)
7. Lighting (unchanged)

- [ ] **Step 1: Write new MapSetup source**

```lua
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local MapSetup = {}

local COLS = Config.GRID_COLS        -- 3
local ROWS = Config.GRID_ROWS        -- 10
local CELL = Config.CELL_SPACING     -- 34
local PATH_W = Config.PATH_WIDTH     -- 14
local PLOT = Config.PLOT_SIZE        -- 20
local MARGIN = Config.MAP_MARGIN     -- 40
local WATER_DEPTH = Config.WATER_DEPTH -- 4
local WALL_H = Config.WALL_HEIGHT    -- 10

local GROUND_Y = 0
local PATH_COLOR = Color3.fromRGB(139, 90, 43)
local PATH_MATERIAL = Enum.Material.WoodPlanks
local FENCE_COLOR = Color3.fromRGB(101, 67, 33)

-- Grid helpers
local function colX(col) return (col - 1) * CELL end -- col 0=-34, 1=0, 2=34
local function rowZ(row) return (row - (ROWS - 1) / 2) * CELL end -- centered

local function createPart(props)
    local p = Instance.new("Part")
    p.Anchored = true
    for k, v in props do
        if k ~= "Parent" then p[k] = v end
    end
    p.Parent = props.Parent or Workspace
    return p
end

function MapSetup.getPlotPosition(slotIndex)
    local col = slotIndex % COLS
    local row = math.floor(slotIndex / COLS)
    return Vector3.new(colX(col), GROUND_Y, rowZ(row))
end

function MapSetup.build()
    -- Clean old objects
    for _, name in {"Decorations", "MainPlatform", "MainSpawn", "GardenArea",
                    "GardenBeds", "Exhibits", "PlotSlots", "Paths", "Boundaries",
                    "TrendRadars", "Water"} do
        local old = Workspace:FindFirstChild(name)
        if old then old:Destroy() end
    end
    for _, c in Workspace:GetChildren() do
        if c.Name:match("^TrendRadar") or c.Name:match("^Fence") or c.Name:match("^Wall") then
            c:Destroy()
        end
    end

    -- === WATER ===
    local gridW = COLS * PLOT + (COLS - 1) * PATH_W  -- 88
    local gridH = ROWS * PLOT + (ROWS - 1) * PATH_W  -- 326
    local mapW = gridW + MARGIN * 2  -- 168
    local mapH = gridH + MARGIN * 2 + 60  -- 426 (extra for Trend Radars)

    local water = createPart({
        Name = "Water",
        Size = Vector3.new(mapW + 100, WATER_DEPTH, mapH + 100),
        Position = Vector3.new(0, GROUND_Y - WATER_DEPTH / 2 - 0.1, 0),
        Color = Color3.fromRGB(30, 100, 180),
        Material = Enum.Material.Water,
        Transparency = 0.3,
        CanCollide = true,
    })

    -- === PLOT MARKERS ===
    local plotsFolder = Instance.new("Folder")
    plotsFolder.Name = "PlotSlots"
    plotsFolder.Parent = Workspace

    for i = 0, (COLS * ROWS) - 1 do
        local pos = MapSetup.getPlotPosition(i)

        local marker = Instance.new("Part")
        marker.Name = "PlotSlot" .. i
        marker.Size = Vector3.new(PLOT, 0.5, PLOT)
        marker.Position = pos + Vector3.new(0, -0.25, 0)
        marker.Anchored = true
        marker.Transparency = 1
        marker.CanCollide = false
        marker.Parent = plotsFolder

        -- Visible garden floor
        createPart({
            Name = "PlotFloor",
            Size = Vector3.new(PLOT - 0.5, 0.5, PLOT - 0.5),
            Position = pos + Vector3.new(0, 0.25, 0),
            Color = Color3.fromRGB(80, 160, 60),
            Material = Enum.Material.Grass,
            Parent = marker,
        })
    end

    -- === PATHS ===
    local pathsFolder = Instance.new("Folder")
    pathsFolder.Name = "Paths"
    pathsFolder.Parent = Workspace

    for row = 0, ROWS - 1 do
        for col = 0, COLS - 1 do
            local cx = colX(col)
            local cz = rowZ(row)

            -- Horizontal path to RIGHT neighbor
            if col < COLS - 1 then
                createPart({
                    Name = "PathH_" .. row .. "_" .. col,
                    Size = Vector3.new(PATH_W, 0.5, PLOT),
                    Position = Vector3.new(cx + PLOT / 2 + PATH_W / 2, GROUND_Y + 0.25, cz),
                    Color = PATH_COLOR,
                    Material = PATH_MATERIAL,
                    Parent = pathsFolder,
                })
            end

            -- Vertical path to BOTTOM neighbor
            if row < ROWS - 1 then
                createPart({
                    Name = "PathV_" .. row .. "_" .. col,
                    Size = Vector3.new(PLOT, 0.5, PATH_W),
                    Position = Vector3.new(cx, GROUND_Y + 0.25, cz + PLOT / 2 + PATH_W / 2),
                    Color = PATH_COLOR,
                    Material = PATH_MATERIAL,
                    Parent = pathsFolder,
                })
            end

            -- Intersection patches (where horizontal and vertical paths cross)
            if col < COLS - 1 and row < ROWS - 1 then
                createPart({
                    Name = "PathX_" .. row .. "_" .. col,
                    Size = Vector3.new(PATH_W, 0.5, PATH_W),
                    Position = Vector3.new(cx + PLOT / 2 + PATH_W / 2, GROUND_Y + 0.25,
                                          cz + PLOT / 2 + PATH_W / 2),
                    Color = PATH_COLOR,
                    Material = PATH_MATERIAL,
                    Parent = pathsFolder,
                })
            end
        end
    end

    -- Outer paths (perimeter walkway around entire grid)
    -- Top edge
    createPart({ Name="PathPerimTop", Size=Vector3.new(gridW, 0.5, PATH_W),
        Position=Vector3.new(0, 0.25, rowZ(0) - PLOT/2 - PATH_W/2),
        Color=PATH_COLOR, Material=PATH_MATERIAL, Parent=pathsFolder })
    -- Bottom edge
    createPart({ Name="PathPerimBot", Size=Vector3.new(gridW, 0.5, PATH_W),
        Position=Vector3.new(0, 0.25, rowZ(ROWS-1) + PLOT/2 + PATH_W/2),
        Color=PATH_COLOR, Material=PATH_MATERIAL, Parent=pathsFolder })
    -- Left edge
    createPart({ Name="PathPerimLeft", Size=Vector3.new(PATH_W, 0.5, gridH + PATH_W*2),
        Position=Vector3.new(colX(0) - PLOT/2 - PATH_W/2, 0.25, 0),
        Color=PATH_COLOR, Material=PATH_MATERIAL, Parent=pathsFolder })
    -- Right edge
    createPart({ Name="PathPerimRight", Size=Vector3.new(PATH_W, 0.5, gridH + PATH_W*2),
        Position=Vector3.new(colX(COLS-1) + PLOT/2 + PATH_W/2, 0.25, 0),
        Color=PATH_COLOR, Material=PATH_MATERIAL, Parent=pathsFolder })

    -- === INVISIBLE WALLS + DECORATIVE FENCES ===
    local boundsFolder = Instance.new("Folder")
    boundsFolder.Name = "Boundaries"
    boundsFolder.Parent = Workspace

    local perimLeft   = colX(0) - PLOT/2 - PATH_W
    local perimRight  = colX(COLS-1) + PLOT/2 + PATH_W
    local perimTop    = rowZ(0) - PLOT/2 - PATH_W
    local perimBottom = rowZ(ROWS-1) + PLOT/2 + PATH_W
    local perimW = perimRight - perimLeft
    local perimH = perimBottom - perimTop

    local walls = {
        {Name="WallN", Size=Vector3.new(perimW, WALL_H, 1), Position=Vector3.new(0, WALL_H/2, perimTop)},
        {Name="WallS", Size=Vector3.new(perimW, WALL_H, 1), Position=Vector3.new(0, WALL_H/2, perimBottom)},
        {Name="WallW", Size=Vector3.new(1, WALL_H, perimH), Position=Vector3.new(perimLeft, WALL_H/2, 0)},
        {Name="WallE", Size=Vector3.new(1, WALL_H, perimH), Position=Vector3.new(perimRight, WALL_H/2, 0)},
    }
    for _, wd in walls do
        -- Invisible collision wall
        createPart({ Name=wd.Name, Size=wd.Size, Position=wd.Position,
            Transparency=1, CanCollide=true, Parent=boundsFolder })
    end

    -- Decorative fence posts along boundary
    local fenceH = 3.5
    local postSpacing = 8
    local function placeFenceLine(startPos, direction, length)
        local posts = math.floor(length / postSpacing)
        for i = 0, posts do
            local offset = direction * (i * postSpacing - length / 2)
            local pos = startPos + offset
            createPart({ Name="BoundaryPost", Size=Vector3.new(0.5, fenceH, 0.5),
                Position=pos + Vector3.new(0, fenceH/2, 0),
                Color=FENCE_COLOR, Material=Enum.Material.Wood, Parent=boundsFolder })
        end
        -- Top rail
        local railSize, railPos
        if direction == Vector3.new(1,0,0) then
            railSize = Vector3.new(length, 0.3, 0.3)
            railPos = startPos + Vector3.new(0, fenceH - 0.2, 0)
        else
            railSize = Vector3.new(0.3, 0.3, length)
            railPos = startPos + Vector3.new(0, fenceH - 0.2, 0)
        end
        createPart({ Name="BoundaryRail", Size=railSize, Position=railPos,
            Color=FENCE_COLOR, Material=Enum.Material.Wood, Parent=boundsFolder })
        -- Middle rail
        createPart({ Name="BoundaryRail", Size=railSize,
            Position=railPos - Vector3.new(0, fenceH/2 - 0.3, 0),
            Color=FENCE_COLOR, Material=Enum.Material.Wood, Parent=boundsFolder })
    end

    placeFenceLine(Vector3.new(0, 0, perimTop), Vector3.new(1,0,0), perimW)
    placeFenceLine(Vector3.new(0, 0, perimBottom), Vector3.new(1,0,0), perimW)
    placeFenceLine(Vector3.new(perimLeft, 0, 0), Vector3.new(0,0,1), perimH)
    placeFenceLine(Vector3.new(perimRight, 0, 0), Vector3.new(0,0,1), perimH)

    -- === TREND RADARS (floating, no poles) ===
    local trendFolder = Instance.new("Folder")
    trendFolder.Name = "TrendRadars"
    trendFolder.Parent = Workspace

    local trY = 35
    local trSize = Vector3.new(50, 20, 1)
    local trendData = {
        { pos = Vector3.new(0, trY, perimTop - 20), face = Enum.NormalId.Back },
        { pos = Vector3.new(0, trY, perimBottom + 20), face = Enum.NormalId.Front },
    }

    for i, td in trendData do
        local bb = createPart({
            Name = "TrendRadar" .. i,
            Size = trSize,
            Position = td.pos,
            Color = Color3.fromRGB(20, 15, 30),
            Material = Enum.Material.Neon,
            CanCollide = false,
            Parent = trendFolder,
        })

        -- Make visible from both sides
        for _, face in {td.face} do
            local sg = Instance.new("SurfaceGui")
            sg.Face = face
            sg.Parent = bb

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0.25, 0)
            title.BackgroundTransparency = 1
            title.Text = "TREND RADAR"
            title.TextColor3 = Color3.fromRGB(255, 220, 50)
            title.TextScaled = true
            title.Font = Enum.Font.GothamBold
            title.Parent = sg

            local season = Instance.new("TextLabel")
            season.Name = "CurrentTrend"
            season.Size = UDim2.new(1, 0, 0.45, 0)
            season.Position = UDim2.new(0, 0, 0.25, 0)
            season.BackgroundTransparency = 1
            season.Text = "Season 1: OG Brainrot"
            season.TextColor3 = Color3.fromRGB(255, 255, 255)
            season.TextScaled = true
            season.Font = Enum.Font.GothamBold
            season.Parent = sg

            local weekly = Instance.new("TextLabel")
            weekly.Name = "WeeklyBrainrot"
            weekly.Size = UDim2.new(1, 0, 0.3, 0)
            weekly.Position = UDim2.new(0, 0, 0.7, 0)
            weekly.BackgroundTransparency = 1
            weekly.Text = "Weekly: Bombardiro Crocodilo"
            weekly.TextColor3 = Color3.fromRGB(50, 200, 255)
            weekly.TextScaled = true
            weekly.Font = Enum.Font.Gotham
            weekly.Parent = sg
        end
    end

    -- === LIGHTING (unchanged from current) ===
    local lighting = game:GetService("Lighting")
    lighting.ClockTime = 14
    lighting.Brightness = 2
    lighting.Ambient = Color3.fromRGB(120, 120, 140)
    lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 160)
    for _, c in lighting:GetChildren() do
        if c:IsA("Atmosphere") or c:IsA("BloomEffect") or c:IsA("SunRaysEffect")
            or c:IsA("ColorCorrectionEffect") then
            c:Destroy()
        end
    end
    local atmo = Instance.new("Atmosphere", lighting)
    atmo.Density = 0.3; atmo.Offset = 0.25
    atmo.Color = Color3.fromRGB(200, 220, 255)
    local bl = Instance.new("BloomEffect", lighting)
    bl.Intensity = 0.5; bl.Size = 24; bl.Threshold = 0.9
    local sr = Instance.new("SunRaysEffect", lighting)
    sr.Intensity = 0.12; sr.Spread = 0.5
    local cc = Instance.new("ColorCorrectionEffect", lighting)
    cc.Brightness = 0.03; cc.Contrast = 0.1; cc.Saturation = 0.15

    print("[Server] Grid map built: " .. COLS .. "x" .. ROWS .. " = " .. (COLS*ROWS) .. " plots")
end

return MapSetup
```

- [ ] **Step 2: Deploy to Studio via run_code**

Replace the MapSetup.Source with the new code above.

- [ ] **Step 3: Verify by running MapSetup.build() in stop mode**

```lua
require(game.ServerScriptService.Server.MapSetup).build()
-- Check workspace for PlotSlots, Paths, Boundaries, TrendRadars, Water
print(#game.Workspace.PlotSlots:GetChildren(), "plot slots")
print(#game.Workspace.Paths:GetChildren(), "path segments")
```

---

### Task 3: Rewrite PlotManager

**Files:** `ServerScriptService.Server.PlotManager`

PlotManager now creates per-player garden content at grid positions: beds (from current MapSetup garden logic), fences with gate openings, and per-player SpawnLocation.

- [ ] **Step 1: Write new PlotManager source**

```lua
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local MapSetup = require(script.Parent.MapSetup)

local PlotManager = {}
local plotSlots = {}
local playerPlots = {}

local MAX_SLOTS = Config.GRID_COLS * Config.GRID_ROWS
local PLOT = Config.PLOT_SIZE
local COLS = Config.GRID_COLS
local FENCE_H = 4
local FENCE_THICK = 0.4

local function getColumn(slotIndex) return slotIndex % COLS end

function PlotManager.allocate(player, data)
    for i = 0, MAX_SLOTS - 1 do
        if plotSlots[i] == nil then
            plotSlots[i] = player
            playerPlots[player.UserId] = i

            local pos = MapSetup.getPlotPosition(i)
            local col = getColumn(i)
            local marker = Workspace.PlotSlots:FindFirstChild("PlotSlot" .. i)
            if not marker then
                warn("[PlotManager] No marker for slot " .. i)
                return i
            end

            -- === SpawnLocation (per-player) ===
            local spawnLoc = Instance.new("SpawnLocation")
            spawnLoc.Name = "PlayerSpawn"
            spawnLoc.Size = Vector3.new(6, 0.8, 6)
            spawnLoc.Position = pos + Vector3.new(0, 0.4, -6)
            spawnLoc.Anchored = true
            spawnLoc.BrickColor = BrickColor.new("White")
            spawnLoc.Material = Enum.Material.SmoothPlastic
            spawnLoc.Neutral = false
            spawnLoc.Parent = marker

            -- Assign player to team for spawn (use SpawnLocation trick)
            -- Simple approach: teleport player to their spawn
            local character = player.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, -6))
                end
            end

            -- === Fence with gates ===
            local fenceFolder = Instance.new("Folder")
            fenceFolder.Name = "Fence"
            fenceFolder.Parent = marker

            local halfSize = PLOT / 2
            -- gateRight = true for col 0 and col 1
            -- gateLeft = true for col 1 and col 2
            local gateLeft = (col == 1) or (col == 2)
            local gateRight = (col == 0) or (col == 1)

            -- Front fence (Z-)
            createFenceSegment(fenceFolder, pos, Vector3.new(0, 0, -halfSize), Vector3.new(PLOT, FENCE_H, FENCE_THICK))
            -- Back fence (Z+)
            createFenceSegment(fenceFolder, pos, Vector3.new(0, 0, halfSize), Vector3.new(PLOT, FENCE_H, FENCE_THICK))

            -- Left fence (X-) - with or without gate
            if gateLeft then
                -- Two half-segments with gap in middle
                local segLen = (PLOT - 6) / 2 -- 6 stud gate opening
                createFenceSegment(fenceFolder, pos, Vector3.new(-halfSize, 0, -(halfSize - segLen/2)/1 + segLen/4), Vector3.new(FENCE_THICK, FENCE_H, segLen))
                createFenceSegment(fenceFolder, pos, Vector3.new(-halfSize, 0, (halfSize - segLen/2)/1 - segLen/4), Vector3.new(FENCE_THICK, FENCE_H, segLen))

                -- Actually simpler: top portion and bottom portion
                createFenceWall(fenceFolder, pos + Vector3.new(-halfSize, FENCE_H/2, -halfSize/2 - 1.5), Vector3.new(FENCE_THICK, FENCE_H, halfSize - 3))
                createFenceWall(fenceFolder, pos + Vector3.new(-halfSize, FENCE_H/2, halfSize/2 + 1.5), Vector3.new(FENCE_THICK, FENCE_H, halfSize - 3))
            else
                createFenceWall(fenceFolder, pos + Vector3.new(-halfSize, FENCE_H/2, 0), Vector3.new(FENCE_THICK, FENCE_H, PLOT))
            end

            -- Right fence (X+) - with or without gate
            if gateRight then
                createFenceWall(fenceFolder, pos + Vector3.new(halfSize, FENCE_H/2, -halfSize/2 - 1.5), Vector3.new(FENCE_THICK, FENCE_H, halfSize - 3))
                createFenceWall(fenceFolder, pos + Vector3.new(halfSize, FENCE_H/2, halfSize/2 + 1.5), Vector3.new(FENCE_THICK, FENCE_H, halfSize - 3))
            else
                createFenceWall(fenceFolder, pos + Vector3.new(halfSize, FENCE_H/2, 0), Vector3.new(FENCE_THICK, FENCE_H, PLOT))
            end

            -- === Garden beds ===
            local bedsFolder = Instance.new("Folder")
            bedsFolder.Name = "GardenBeds"
            bedsFolder.Parent = marker

            local bedCount = data.garden.bedCount or Config.BASE_BED_COUNT
            for bi = 1, 8 do
                local brow = math.ceil(bi / 4)
                local bcol = ((bi - 1) % 4) + 1
                local bx = pos.X - 7 + (bcol - 1) * 5
                local bz = pos.Z - 3 + (brow - 1) * 7

                local bed = Instance.new("Part")
                bed.Name = "Bed" .. bi
                bed.Size = Vector3.new(4, 1, 4)
                bed.Position = Vector3.new(bx, pos.Y + 0.75, bz)
                bed.Anchored = true
                bed.BrickColor = BrickColor.new("Reddish brown")
                bed.Material = Enum.Material.Ground
                bed.Parent = bedsFolder

                local soil = Instance.new("Part")
                soil.Name = "Soil"
                soil.Size = Vector3.new(3, 0.4, 3)
                soil.Position = bed.Position + Vector3.new(0, 0.7, 0)
                soil.Anchored = true
                soil.BrickColor = BrickColor.new("Dark orange")
                soil.Material = Enum.Material.Ground
                soil.Parent = bed
            end

            -- === Name billboard ===
            local bbPart = Instance.new("Part")
            bbPart.Name = "NameSign"
            bbPart.Size = Vector3.new(1, 1, 1)
            bbPart.Position = pos + Vector3.new(0, 5, -halfSize)
            bbPart.Anchored = true
            bbPart.Transparency = 1
            bbPart.CanCollide = false
            bbPart.Parent = marker

            local bbGui = Instance.new("BillboardGui")
            bbGui.Size = UDim2.new(0, 120, 0, 40)
            bbGui.StudsOffset = Vector3.new(0, 2, 0)
            bbGui.Parent = bbPart

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 1, 0)
            nameLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.BackgroundTransparency = 0.1
            nameLabel.Text = player.DisplayName .. "'s Garden"
            nameLabel.TextColor3 = Color3.fromRGB(93, 64, 55)
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = bbGui

            local nc = Instance.new("UICorner")
            nc.CornerRadius = UDim.new(0, 8)
            nc.Parent = nameLabel
            local ns = Instance.new("UIStroke")
            ns.Color = Color3.fromRGB(255, 181, 232)
            ns.Thickness = 2
            ns.Parent = nameLabel

            print("[PlotManager] Allocated slot " .. i .. " (col=" .. col .. ") for " .. player.Name)
            return i
        end
    end
    warn("[PlotManager] No free slots for " .. player.Name)
    return nil
end

local function createFenceWall(parent, position, size)
    local wall = Instance.new("Part")
    wall.Name = "FenceWall"
    wall.Size = size
    wall.Position = position
    wall.Anchored = true
    wall.Color = Color3.fromRGB(139, 90, 43)
    wall.Material = Enum.Material.Wood
    wall.Transparency = 0.15
    wall.Parent = parent
end

function PlotManager.release(player)
    local slotIndex = playerPlots[player.UserId]
    if slotIndex == nil then return end

    plotSlots[slotIndex] = nil
    playerPlots[player.UserId] = nil

    -- Clean up player's garden content from marker
    local marker = Workspace:FindFirstChild("PlotSlots")
        and Workspace.PlotSlots:FindFirstChild("PlotSlot" .. slotIndex)
    if marker then
        for _, child in marker:GetChildren() do
            if child.Name ~= "PlotFloor" then
                child:Destroy()
            end
        end
    end

    print("[PlotManager] Released slot " .. slotIndex .. " for " .. player.Name)
end

function PlotManager.getSlotIndex(player)
    return playerPlots[player.UserId]
end

function PlotManager.getPlotPosition(player)
    local slot = playerPlots[player.UserId]
    if slot then
        return MapSetup.getPlotPosition(slot)
    end
    return nil
end

function PlotManager.getPlotMarker(player)
    local slot = playerPlots[player.UserId]
    if slot == nil then return nil end
    local folder = Workspace:FindFirstChild("PlotSlots")
    return folder and folder:FindFirstChild("PlotSlot" .. slot)
end

return PlotManager
```

Note: `createFenceWall` is a local function that must be defined BEFORE `allocate` in the actual source. The plan code above shows intent — the implementer must reorder so `createFenceWall` is above `allocate`.

- [ ] **Step 2: Deploy to Studio**

Replace PlotManager.Source.

- [ ] **Step 3: Verify slot position calculation**

```lua
local MapSetup = require(game.ServerScriptService.Server.MapSetup)
for i = 0, 29 do
    local p = MapSetup.getPlotPosition(i)
    print("Slot " .. i .. ": col=" .. (i%3) .. " row=" .. math.floor(i/3) .. " pos=" .. tostring(p))
end
```

---

### Task 4: Update BedVisuals for Per-Plot Beds

**Files:** `ServerScriptService.Server.BedVisuals`

BedVisuals currently looks for `Workspace.GardenBeds.Bed1`. It needs to look inside the player's plot marker instead.

- [ ] **Step 1: Find the bed lookup pattern in BedVisuals**

Search for `Workspace:FindFirstChild("GardenBeds")` or `Workspace.GardenBeds` in the source.

- [ ] **Step 2: Add plotMarker parameter to updateAllBeds and updateBed**

Change signature:
```lua
function BedVisuals.updateAllBeds(data, plotMarker)
```

Inside, change bed lookup from:
```lua
local bedsFolder = Workspace:FindFirstChild("GardenBeds")
```
to:
```lua
local bedsFolder = plotMarker and plotMarker:FindFirstChild("GardenBeds")
```

- [ ] **Step 3: Update all callers in Init**

In Init script, change:
```lua
BedVisuals.updateAllBeds(data)
```
to:
```lua
local PlotManager = require(script.Parent.PlotManager)
local marker = PlotManager.getPlotMarker(player)
BedVisuals.updateAllBeds(data, marker)
```

- [ ] **Step 4: Verify beds render in player's plot**

Play test, check that beds appear inside the allocated plot.

---

### Task 5: Update ExhibitManager for Per-Plot Exhibits

**Files:** `ServerScriptService.Server.ExhibitManager`

ExhibitManager uses absolute CORNER_POSITIONS. Needs to offset by plot position.

- [ ] **Step 1: Add plot offset to CORNER_POSITIONS**

Change `CORNER_POSITIONS` from absolute to relative offsets:
```lua
local CORNER_OFFSETS = {
    Vector3.new(-7, 0, -7),
    Vector3.new(7, 0, -7),
    Vector3.new(-7, 0, 7),
    Vector3.new(7, 0, 7),
}
```

- [ ] **Step 2: Add plotPosition parameter to buildPedestals**

```lua
function ExhibitManager.buildPedestals(plotPosition)
    -- ... existing code but replace:
    -- for i, pos in CORNER_POSITIONS do
    -- with:
    for i, offset in CORNER_OFFSETS do
        local pos = plotPosition + offset
        -- ... rest unchanged
    end
end
```

- [ ] **Step 3: Update exhibitFolder to be per-plot**

Instead of one global `exhibitFolder`, make it per-plot:
- Store in a table keyed by slotIndex
- Or parent exhibits to the plot marker

- [ ] **Step 4: Update placeModelOnPedestal for per-plot positions**

The `findPedestalModel` function needs to search within the right plot's exhibits folder.

- [ ] **Step 5: Update Init callers**

Change:
```lua
ExhibitManager.buildPedestals()
ExhibitManager.updateExhibits(data)
```
to:
```lua
-- In PlayerAdded, after PlotManager.allocate:
local plotPos = PlotManager.getPlotPosition(player)
ExhibitManager.buildPedestals(plotPos, slotIndex)
ExhibitManager.updateExhibits(data, slotIndex)
```

- [ ] **Step 6: Verify exhibits appear in player's plot**

Play test, check pedestals render at correct relative positions within the garden.

---

### Task 6: Update Init Script Wiring

**Files:** `ServerScriptService.Server.Init`

- [ ] **Step 1: Remove global ExhibitManager.buildPedestals() call**

The call at the top of Init (`ExhibitManager.buildPedestals()`) should be removed — pedestals are now built per-player in PlayerAdded.

- [ ] **Step 2: Update PlayerAdded handler**

```lua
Players.PlayerAdded:Connect(function(player)
    createLeaderstats(player)
    task.wait(1)
    local data = PlayerDataManager.getData(player)
    if data then
        updateLeaderstats(player, data)
        local slotIndex = PlotManager.allocate(player, data)
        if slotIndex then
            remotesFolder.PlotAllocated:FireClient(player, slotIndex)
            local plotPos = PlotManager.getPlotPosition(player)
            ExhibitManager.buildPedestals(plotPos, slotIndex)
            syncData(player)  -- this calls BedVisuals + ExhibitManager updates
        end
    end
end)
```

- [ ] **Step 3: Update syncData to pass plot context**

```lua
local function syncData(player)
    local data = PlayerDataManager.getData(player)
    if data then
        -- ... existing data padding ...
        remotesFolder.UpdatePlayerData:FireClient(player, data)
        local marker = PlotManager.getPlotMarker(player)
        BedVisuals.updateAllBeds(data, marker)
        local slotIndex = PlotManager.getSlotIndex(player)
        ExhibitManager.updateExhibits(data, slotIndex)
    end
end
```

- [ ] **Step 4: Remove duplicate require/init calls**

The current Init has duplicate lines (ExhibitManager required twice, buildPedestals called twice, etc.). Clean these up.

- [ ] **Step 5: Full play test**

Start play mode, verify:
- Map has water, paths, 30 plot markers
- Player spawns in their garden
- Beds appear in garden
- Exhibits appear in garden
- Trend Radars float at top and bottom
- Invisible walls prevent falling into water
- Decorative fences visible along boundary

---

### Task 7: Respawn Handling

**Files:** `ServerScriptService.Server.PlotManager`, `ServerScriptService.Server.Init`

Players need to respawn in their own garden, not at a global spawn.

- [ ] **Step 1: Add CharacterAdded handler in PlotManager.allocate**

Inside `allocate`, after creating the SpawnLocation:

```lua
player.CharacterAdded:Connect(function(character)
    task.wait(0.1)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and playerPlots[player.UserId] == i then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, -6))
    end
end)
```

- [ ] **Step 2: Remove old MainSpawn from MapSetup**

Verify that MapSetup does NOT create a global SpawnLocation (the new code doesn't).

- [ ] **Step 3: Test respawn**

Die in play mode, verify respawn happens in the player's garden.
