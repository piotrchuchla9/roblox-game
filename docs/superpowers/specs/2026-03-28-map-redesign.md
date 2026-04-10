# Map Redesign: Rectangular Grid Layout

## Overview

Replace the circular island hub with a rectangular grid of 30 player gardens (3 columns x 10 rows), connected by walkable paths, surrounded by water, with two floating Trend Radar billboards.

## Layout

```
              [WODA + PLOT + NIEWIDZIALNA SCIANA]
        ======= TREND RADAR (gora, lewitujacy) =======
        [1]  ---sciezka---  [2]  ---sciezka---  [3]
        [4]  ---sciezka---  [5]  ---sciezka---  [6]
        [7]  ---sciezka---  [8]  ---sciezka---  [9]
        [10] ---sciezka--- [11]  ---sciezka--- [12]
        [13] ---sciezka--- [14]  ---sciezka--- [15]
        [16] ---sciezka--- [17]  ---sciezka--- [18]
        [19] ---sciezka--- [20]  ---sciezka--- [21]
        [22] ---sciezka--- [23]  ---sciezka--- [24]
        [25] ---sciezka--- [26]  ---sciezka--- [27]
        [28] ---sciezka--- [29]  ---sciezka--- [30]
        ======= TREND RADAR (dol, lewitujacy) ========
              [WODA + PLOT + NIEWIDZIALNA SCIANA]
```

## Dimensions

| Element | Size | Notes |
|---------|------|-------|
| Garden | 20x20 studs | Unchanged from current |
| Paths between columns | 14 studs wide | Brown, WoodPlanks material |
| Paths between rows | 14 studs deep | Brown, WoodPlanks material |
| Grid area (gardens + paths) | 88 x 326 studs | 3*20 + 2*14 wide, 10*20 + 9*14 deep |
| Water margin | ~40 studs on each side | Surrounds entire grid |
| Total map | ~168 x ~430 studs | Grid + water margins + Trend Radar space |
| Water depth | 4 studs below garden surface | Terrain filled with Water material |

## Garden Slots

- Numbered 0-29 (matching current PlotManager convention)
- Grid mapping: slot `i` -> column = `i % 3`, row = `floor(i / 3)`
- Column 0 = left, column 1 = middle, column 2 = right

## Garden Structure (UNCHANGED)

Each garden retains its current structure from PlotManager:
- PlotFloor (18x0.3x18, WoodPlanks)
- Fence (4 sides, brown wood)
- NameSign billboard ("PlayerName's Garden")
- Beds (soil patches for planting)
- Exhibits (brainrot pedestals)

### Gates (fence openings)

Gates are openings in the fence (one fence segment omitted):
- **Left column** (col 0): gate on RIGHT side
- **Middle column** (col 1): gates on LEFT and RIGHT sides
- **Right column** (col 2): gate on LEFT side

## SpawnLocation

- Each garden has its own white SpawnLocation (8x1x8, SmoothPlastic)
- Players spawn in their own garden when joining
- SpawnLocation is per-player (using SpawnLocation.AllowTeamOnly or similar mechanism)

## Paths

- Brown parts (Color3.fromRGB(139, 90, 43), Material.WoodPlanks)
- Horizontal paths: connect gardens in the same row (between columns)
- Vertical paths: run along the full length connecting all rows
- All paths at the same Y level as garden floors

## Water

- Terrain filled with Enum.Material.Water
- Surface level ~4 studs below garden/path surface
- Surrounds the entire grid area on all sides
- Margin of ~40 studs around the grid

## Boundaries

### Invisible Walls
- Transparent parts (Transparency = 1) along water edges
- CanCollide = true, prevents players from falling into water
- Height: ~8 studs
- Placed at the outer edge of paths/gardens where water begins

### Decorative Fences
- Visible fence parts along the invisible walls
- Purely decorative (show the boundary visually)
- Brown wood style, matching garden fences
- CanCollide = false (the invisible walls handle collision)

## Trend Radar

- 2 instances: top of map and bottom of map
- Positioned above the middle column area
- **Floating** - no support poles, levitating in the air
- Large billboard: ~30x15 studs
- Height: ~30 studs above ground (visible from far away)
- SurfaceGui with: title "TREND RADAR", current season text, weekly brainrot text
- Same content as current Trend Radar

## What Gets Removed from MapSetup

- Circular island terrain generation
- Hub buildings (Shop, Leaderboard)
- Fountain + water particles
- All decorations (trees, flowers, balloons, benches, lampposts)
- Circular plot slot placement (replaced with grid)

## What Gets Modified

### MapSetup.build()
- New rectangular terrain with water
- Grid-based plot slot placement
- Paths between gardens
- Invisible walls + decorative fences
- 2x floating Trend Radar billboards
- Lighting settings remain the same

### PlotManager.allocate()
- Fence generation: skip segments where gates should be (based on column)
- Add per-player SpawnLocation inside garden

### Config
- Remove: ISLAND_RADIUS, HUB_RADIUS, PLOT_RING_RADIUS
- Add: MAP grid constants (if needed, or keep in MapSetup)
