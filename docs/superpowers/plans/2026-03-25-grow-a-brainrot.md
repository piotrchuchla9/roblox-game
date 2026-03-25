# Grow a Brainrot — MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build MVP of "Grow a Brainrot" — a Roblox farming/collecting simulator where players plant seeds, grow meme creatures (brainrots), and collect them across 6 rarity tiers.

**Architecture:** Rojo-managed project synced to Roblox Studio via MCP. Server-authoritative game logic (planting, drops, monetization) with client handling UI and effects. ProfileService for persistent player data. Modular brainrot database for easy content addition.

**Tech Stack:** Luau, Roblox Studio (built-in MCP Server), Rojo for file sync, ProfileService for data persistence, TestEZ for unit tests.

**Spec:** `docs/superpowers/specs/2026-03-25-grow-a-brainrot-design.md`

---

## File Structure

```
grow-a-brainrot/
├── default.project.json              -- Rojo project config
├── src/
│   ├── server/                       -- ServerScriptService
│   │   ├── init.server.luau          -- server bootstrap: loads all managers
│   │   ├── PlayerDataManager.luau    -- ProfileService wrapper, load/save/get player data
│   │   ├── GardenManager.luau        -- plant, water, harvest, bed upgrades
│   │   ├── DropSystem.luau           -- rarity rolling, weighted random
│   │   ├── MonetizationManager.luau  -- gamepass checks, dev product processing
│   │   └── DailyRewardManager.luau   -- daily reward streaks
│   ├── client/                       -- StarterPlayerScripts
│   │   ├── init.client.luau          -- client bootstrap
│   │   ├── GardenUI.luau             -- garden bed interaction UI
│   │   ├── CollectionBook.luau       -- brainrot index/collection viewer
│   │   ├── DropAnimation.luau        -- "OMG moment" fullscreen effects
│   │   ├── ShopUI.luau               -- gamepass/dev product shop
│   │   ├── DailyRewardsUI.luau       -- daily reward claim screen
│   │   ├── LeaderboardUI.luau        -- collection ranking display
│   │   └── HUD.luau                  -- persistent HUD (currencies, buttons)
│   └── shared/                       -- ReplicatedStorage
│       ├── Config.luau               -- all constants: prices, drop rates, timers
│       ├── BrainrotDatabase.luau     -- brainrot definitions: id, name, rarity, model
│       ├── Types.luau                -- type definitions for PlayerData, Bed, Brainrot
│       └── Remotes.luau              -- RemoteEvent/RemoteFunction name constants
├── tests/
│   ├── server/
│   │   ├── DropSystem.spec.luau      -- drop rate distribution tests
│   │   ├── GardenManager.spec.luau   -- planting/harvesting logic tests
│   │   ├── PlayerDataManager.spec.luau
│   │   └── DailyRewardManager.spec.luau
│   └── shared/
│       ├── Config.spec.luau          -- config validation tests
│       └── BrainrotDatabase.spec.luau -- database integrity tests
└── assets/                           -- placeholder models, sounds (manual in Studio)
```

---

## Task 1: Project Scaffolding & Rojo Setup

**Files:**
- Create: `default.project.json`
- Create: `src/shared/Types.luau`
- Create: `src/shared/Remotes.luau`
- Create: `src/server/init.server.luau`
- Create: `src/client/init.client.luau`

- [ ] **Step 1: Initialize git repo and create Rojo project config**

```bash
cd E:/projects/roblox
git init
```

```json
// default.project.json
{
  "name": "GrowABrainrot",
  "tree": {
    "$className": "DataModel",
    "ServerScriptService": {
      "Server": {
        "$path": "src/server"
      }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": {
          "$path": "src/client"
        }
      }
    },
    "ReplicatedStorage": {
      "Shared": {
        "$path": "src/shared"
      }
    }
  }
}
```

- [ ] **Step 2: Create Types module**

```lua
-- src/shared/Types.luau
export type Brainrot = {
    id: string,
    name: string,
    rarity: string, -- "Common"|"Uncommon"|"Rare"|"Epic"|"Legendary"|"Mythic"
    modelId: string, -- asset ID for 3D model
    sellValue: number, -- Seeds earned when selling
}

export type Bed = {
    seedId: string?, -- nil if empty
    plantedAt: number?, -- os.time() when planted
    rarity: string?, -- rarity of seed planted
    growthTime: number?, -- seconds to grow
    isReady: boolean, -- true when growth complete
}

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
    stats: {totalHarvested: number, totalSold: number},
}

return {}
```

- [ ] **Step 3: Create Remotes constants module**

```lua
-- src/shared/Remotes.luau
local Remotes = {
    -- Server -> Client
    UpdatePlayerData = "UpdatePlayerData",
    PlayDropAnimation = "PlayDropAnimation",

    -- Client -> Server
    PlantSeed = "PlantSeed",
    WaterBed = "WaterBed",
    HarvestBed = "HarvestBed",
    SellBrainrot = "SellBrainrot",
    ClaimDailyReward = "ClaimDailyReward",
    PurchaseDevProduct = "PurchaseDevProduct",
    UpgradeGarden = "UpgradeGarden",
}

return Remotes
```

- [ ] **Step 4: Create server and client bootstrap scripts**

```lua
-- src/server/init.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- Create RemoteEvents and RemoteFunctions
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

for _, remoteName in Remotes do
    local remote = Instance.new("RemoteEvent")
    remote.Name = remoteName
    remote.Parent = remotesFolder
end

-- Load managers (will be required as tasks are implemented)
print("[Server] Grow a Brainrot server initialized")
```

```lua
-- src/client/init.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for remotes to be created by server
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotesFolder then
    warn("[Client] Remotes folder not found!")
    return
end

print("[Client] Grow a Brainrot client initialized")
```

- [ ] **Step 5: Verify project syncs with Rojo**

Run: `rojo serve default.project.json`
Expected: Rojo starts serving, Studio plugin connects and syncs file tree.

- [ ] **Step 6: Commit**

```bash
git add default.project.json src/shared/Types.luau src/shared/Remotes.luau src/server/init.server.luau src/client/init.client.luau
git commit -m "feat: scaffold Rojo project with types, remotes, and bootstrap scripts"
```

---

## Task 2: Config & Brainrot Database

**Files:**
- Create: `src/shared/Config.luau`
- Create: `src/shared/BrainrotDatabase.luau`
- Create: `tests/shared/Config.spec.luau`
- Create: `tests/shared/BrainrotDatabase.spec.luau`

- [ ] **Step 1: Write Config validation test**

```lua
-- tests/shared/Config.spec.luau
return function()
    local Config = require(game.ReplicatedStorage.Shared.Config)

    describe("Config", function()
        it("should have drop rates that sum to 100", function()
            local total = 0
            for _, rate in Config.DROP_RATES do
                total += rate
            end
            expect(total).to.equal(100)
        end)

        it("should have growth times for all rarities", function()
            for rarity, _ in Config.DROP_RATES do
                expect(Config.GROWTH_TIMES[rarity]).to.be.ok()
            end
        end)

        it("should have positive sell values for all rarities", function()
            for rarity, _ in Config.DROP_RATES do
                expect(Config.SELL_VALUES[rarity]).to.be.ok()
                expect(Config.SELL_VALUES[rarity] > 0).to.equal(true)
            end
        end)

        it("should have valid gamepass prices", function()
            for _, price in Config.GAMEPASS_PRICES do
                expect(price > 0).to.equal(true)
            end
        end)
    end)
end
```

- [ ] **Step 2: Write BrainrotDatabase validation test**

```lua
-- tests/shared/BrainrotDatabase.spec.luau
return function()
    local BrainrotDatabase = require(game.ReplicatedStorage.Shared.BrainrotDatabase)
    local Config = require(game.ReplicatedStorage.Shared.Config)

    describe("BrainrotDatabase", function()
        it("should have at least 10 brainrots", function()
            local count = 0
            for _ in BrainrotDatabase do
                count += 1
            end
            expect(count >= 10).to.equal(true)
        end)

        it("should have valid rarities for all brainrots", function()
            for id, brainrot in BrainrotDatabase do
                expect(Config.DROP_RATES[brainrot.rarity]).to.be.ok()
            end
        end)

        it("should have unique IDs", function()
            local seen = {}
            for id, _ in BrainrotDatabase do
                expect(seen[id]).never.to.be.ok()
                seen[id] = true
            end
        end)

        it("should have at least one brainrot per rarity", function()
            local rarityCounts = {}
            for _, brainrot in BrainrotDatabase do
                rarityCounts[brainrot.rarity] = (rarityCounts[brainrot.rarity] or 0) + 1
            end
            for rarity, _ in Config.DROP_RATES do
                expect(rarityCounts[rarity]).to.be.ok()
            end
        end)
    end)
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: TestEZ via Roblox Studio play mode
Expected: FAIL — modules not found

- [ ] **Step 4: Implement Config module**

```lua
-- src/shared/Config.luau
local Config = {}

-- Drop rates (must sum to 100)
Config.DROP_RATES = {
    Common = 50,
    Uncommon = 25,
    Rare = 15,
    Epic = 7,
    Legendary = 2.5,
    Mythic = 0.5,
}

-- Growth times in seconds per rarity
Config.GROWTH_TIMES = {
    Common = 30,
    Uncommon = 60,
    Rare = 120,
    Epic = 180,
    Legendary = 240,
    Mythic = 300,
}

-- Sell values in Seeds per rarity
Config.SELL_VALUES = {
    Common = 5,
    Uncommon = 15,
    Rare = 50,
    Epic = 150,
    Legendary = 500,
    Mythic = 2000,
}

-- Garden
Config.BASE_BED_COUNT = 4
Config.MAX_BED_COUNT = 8
Config.BED_UPGRADE_COST = 500 -- Seeds per extra bed
Config.WATER_SPEED_MULTIPLIER = 0.5 -- 50% faster growth

-- Free seed spawn
Config.FREE_SEED_INTERVAL = 60 -- seconds between free seed spawns
Config.FREE_SEED_RARITY = "Common" -- free seeds are always Common

-- Gamepasses (Roblox asset IDs — placeholder, replace with real IDs)
Config.GAMEPASSES = {
    VIP_GARDENER = {id = 0, price = 199, extraBeds = 2},
    AUTO_HARVEST = {id = 0, price = 149},
    DOUBLE_COLLECTION = {id = 0, price = 99},
}

Config.GAMEPASS_PRICES = {
    VIP_GARDENER = 199,
    AUTO_HARVEST = 149,
    DOUBLE_COLLECTION = 99,
}

-- Developer Products (Roblox asset IDs — placeholder)
Config.DEV_PRODUCTS = {
    GOLDEN_SEED_PACK = {id = 0, price = 49, amount = 5},
    MEGA_FERTILIZER = {id = 0, price = 29, amount = 10},
}

-- Daily Rewards
Config.DAILY_REWARD_BASE = 50 -- Seeds
Config.DAILY_REWARD_STREAK_BONUS = 10 -- extra Seeds per streak day
Config.DAILY_REWARD_MAX_STREAK = 7
Config.DAILY_REWARD_COOLDOWN = 72000 -- 20 hours in seconds (allows some flexibility)

-- Leaderboard
Config.LEADERBOARD_UPDATE_INTERVAL = 60 -- seconds

return Config
```

- [ ] **Step 5: Implement BrainrotDatabase module**

```lua
-- src/shared/BrainrotDatabase.luau
local BrainrotDatabase = {
    -- Common (50%)
    skibidi_basic = {
        id = "skibidi_basic",
        name = "Skibidi Toilet Basic",
        rarity = "Common",
        modelId = "0", -- placeholder
        sellValue = 5,
    },
    baby_brainrot = {
        id = "baby_brainrot",
        name = "Baby Brainrot",
        rarity = "Common",
        modelId = "0",
        sellValue = 5,
    },
    toilet_spinner = {
        id = "toilet_spinner",
        name = "Toilet Spinner",
        rarity = "Common",
        modelId = "0",
        sellValue = 5,
    },

    -- Uncommon (25%)
    italian_cappuccino = {
        id = "italian_cappuccino",
        name = "Italian Brainrot Cappuccino",
        rarity = "Uncommon",
        modelId = "0",
        sellValue = 15,
    },
    skibidi_camera = {
        id = "skibidi_camera",
        name = "Skibidi Camera Man",
        rarity = "Uncommon",
        modelId = "0",
        sellValue = 15,
    },

    -- Rare (15%)
    bombardiro = {
        id = "bombardiro",
        name = "Bombardiro Crocodilo",
        rarity = "Rare",
        modelId = "0",
        sellValue = 50,
    },
    lirili_larila = {
        id = "lirili_larila",
        name = "Lirili Larila",
        rarity = "Rare",
        modelId = "0",
        sellValue = 50,
    },

    -- Epic (7%)
    tung_tung = {
        id = "tung_tung",
        name = "Tung Tung Sahur",
        rarity = "Epic",
        modelId = "0",
        sellValue = 150,
    },
    brr_brr_patapim = {
        id = "brr_brr_patapim",
        name = "Brr Brr Patapim",
        rarity = "Epic",
        modelId = "0",
        sellValue = 150,
    },

    -- Legendary (2.5%)
    tralalero = {
        id = "tralalero",
        name = "Tralalero Tralala Gold",
        rarity = "Legendary",
        modelId = "0",
        sellValue = 500,
    },
    glorbo_supreme = {
        id = "glorbo_supreme",
        name = "Glorbo Supreme",
        rarity = "Legendary",
        modelId = "0",
        sellValue = 500,
    },

    -- Mythic (0.5%)
    mega_skibidi_god = {
        id = "mega_skibidi_god",
        name = "Mega Skibidi God",
        rarity = "Mythic",
        modelId = "0",
        sellValue = 2000,
    },
}

return BrainrotDatabase
```

- [ ] **Step 6: Run tests to verify they pass**

Run: TestEZ via Roblox Studio play mode
Expected: All Config and BrainrotDatabase tests PASS

- [ ] **Step 7: Commit**

```bash
git add src/shared/Config.luau src/shared/BrainrotDatabase.luau tests/
git commit -m "feat: add Config constants and BrainrotDatabase with 12 brainrots across 6 rarities"
```

---

## Task 3: Drop System (Server-Side Rarity Rolling)

**Files:**
- Create: `src/server/DropSystem.luau`
- Create: `tests/server/DropSystem.spec.luau`

- [ ] **Step 1: Write drop system tests**

```lua
-- tests/server/DropSystem.spec.luau
return function()
    local DropSystem = require(game.ServerScriptService.Server.DropSystem)
    local Config = require(game.ReplicatedStorage.Shared.Config)
    local BrainrotDatabase = require(game.ReplicatedStorage.Shared.BrainrotDatabase)

    describe("DropSystem", function()
        describe("rollRarity", function()
            it("should return a valid rarity string", function()
                local rarity = DropSystem.rollRarity()
                expect(Config.DROP_RATES[rarity]).to.be.ok()
            end)

            it("should respect approximate distribution over many rolls", function()
                local counts = {}
                local totalRolls = 10000
                for i = 1, totalRolls do
                    local rarity = DropSystem.rollRarity()
                    counts[rarity] = (counts[rarity] or 0) + 1
                end
                -- Common should be roughly 50% (allow 40-60% range)
                local commonPct = (counts["Common"] or 0) / totalRolls * 100
                expect(commonPct > 40 and commonPct < 60).to.equal(true)
            end)
        end)

        describe("rollBrainrot", function()
            it("should return a valid brainrot from the database", function()
                local brainrot = DropSystem.rollBrainrot()
                expect(brainrot).to.be.ok()
                expect(brainrot.id).to.be.ok()
                expect(BrainrotDatabase[brainrot.id]).to.be.ok()
            end)

            it("should return brainrot matching rolled rarity", function()
                for i = 1, 100 do
                    local brainrot = DropSystem.rollBrainrot()
                    expect(Config.DROP_RATES[brainrot.rarity]).to.be.ok()
                end
            end)
        end)

        describe("rollRarity with Lucky Gardener boost", function()
            it("should apply 10% multiplicative boost to Rare+", function()
                local boosted = DropSystem.rollRarity(true)
                expect(Config.DROP_RATES[boosted]).to.be.ok()
            end)
        end)
    end)
end
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — DropSystem module not found

- [ ] **Step 3: Implement DropSystem**

```lua
-- src/server/DropSystem.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDatabase = require(ReplicatedStorage.Shared.BrainrotDatabase)

local DropSystem = {}

-- Build brainrot-by-rarity lookup once
local brainrotsByRarity: {[string]: {any}} = {}
for _, brainrot in BrainrotDatabase do
    if not brainrotsByRarity[brainrot.rarity] then
        brainrotsByRarity[brainrot.rarity] = {}
    end
    table.insert(brainrotsByRarity[brainrot.rarity], brainrot)
end

function DropSystem.rollRarity(hasLuckyGamepass: boolean?): string
    local rates = {}
    local total = 0

    for rarity, rate in Config.DROP_RATES do
        local adjustedRate = rate
        if hasLuckyGamepass and rarity ~= "Common" and rarity ~= "Uncommon" then
            adjustedRate = rate * 1.10 -- 10% multiplicative boost for Rare+
        end
        rates[rarity] = adjustedRate
        total += adjustedRate
    end

    local roll = math.random() * total
    local cumulative = 0

    -- Roll in order from lowest to highest rate to ensure Mythic gets checked
    local order = {"Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
    for _, rarity in order do
        cumulative += rates[rarity]
        if roll <= cumulative then
            return rarity
        end
    end

    return "Common" -- fallback
end

function DropSystem.rollBrainrot(hasLuckyGamepass: boolean?): any
    local rarity = DropSystem.rollRarity(hasLuckyGamepass)
    local pool = brainrotsByRarity[rarity]

    if not pool or #pool == 0 then
        -- Fallback to Common if rarity pool empty
        pool = brainrotsByRarity["Common"]
    end

    local index = math.random(1, #pool)
    return pool[index]
end

return DropSystem
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All DropSystem tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/server/DropSystem.luau tests/server/DropSystem.spec.luau
git commit -m "feat: implement server-side drop system with weighted rarity rolling"
```

---

## Task 4: Player Data Manager (ProfileService)

**Files:**
- Create: `src/server/PlayerDataManager.luau`
- Create: `tests/server/PlayerDataManager.spec.luau`

- [ ] **Step 1: Write PlayerDataManager tests**

```lua
-- tests/server/PlayerDataManager.spec.luau
return function()
    local PlayerDataManager = require(game.ServerScriptService.Server.PlayerDataManager)

    describe("PlayerDataManager", function()
        describe("getDefaultData", function()
            it("should return valid default player data", function()
                local data = PlayerDataManager.getDefaultData()
                expect(data.garden).to.be.ok()
                expect(data.garden.bedCount).to.equal(4)
                expect(data.currencies.seeds).to.equal(0)
                expect(data.currencies.goldenSeeds).to.equal(0)
                expect(data.collectionCount).to.equal(0)
                expect(data.dailyReward.streak).to.equal(0)
            end)

            it("should initialize correct number of empty beds", function()
                local data = PlayerDataManager.getDefaultData()
                expect(#data.garden.beds).to.equal(4)
                for _, bed in data.garden.beds do
                    expect(bed.seedId).to.equal(nil)
                    expect(bed.isReady).to.equal(false)
                end
            end)
        end)

        describe("addToCollection", function()
            it("should add new brainrot to collection", function()
                local data = PlayerDataManager.getDefaultData()
                PlayerDataManager.addToCollection(data, "skibidi_basic")
                expect(data.collection["skibidi_basic"]).to.be.ok()
                expect(data.collection["skibidi_basic"].count).to.equal(1)
                expect(data.collectionCount).to.equal(1)
            end)

            it("should increment count for existing brainrot", function()
                local data = PlayerDataManager.getDefaultData()
                PlayerDataManager.addToCollection(data, "skibidi_basic")
                PlayerDataManager.addToCollection(data, "skibidi_basic")
                expect(data.collection["skibidi_basic"].count).to.equal(2)
                expect(data.collectionCount).to.equal(1) -- still 1 unique
            end)
        end)

        describe("addCurrency", function()
            it("should add seeds", function()
                local data = PlayerDataManager.getDefaultData()
                PlayerDataManager.addCurrency(data, "seeds", 100)
                expect(data.currencies.seeds).to.equal(100)
            end)

            it("should not allow negative balance", function()
                local data = PlayerDataManager.getDefaultData()
                local success = PlayerDataManager.spendCurrency(data, "seeds", 100)
                expect(success).to.equal(false)
                expect(data.currencies.seeds).to.equal(0)
            end)
        end)
    end)
end
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — module not found

- [ ] **Step 3: Implement PlayerDataManager**

```lua
-- src/server/PlayerDataManager.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local PlayerDataManager = {}

-- In-memory data store (ProfileService integration added when IDs are set up)
local playerData: {[number]: any} = {}

function PlayerDataManager.getDefaultData(): any
    local beds = {}
    for i = 1, Config.BASE_BED_COUNT do
        table.insert(beds, {
            seedId = nil,
            plantedAt = nil,
            rarity = nil,
            growthTime = nil,
            isReady = false,
        })
    end

    return {
        garden = {
            beds = beds,
            bedCount = Config.BASE_BED_COUNT,
            tools = {wateringCan = "basic"},
        },
        collection = {},
        collectionCount = 0,
        currencies = {seeds = 0, goldenSeeds = 0},
        gamepasses = {},
        dailyReward = {lastClaimed = 0, streak = 0},
        stats = {totalHarvested = 0, totalSold = 0},
    }
end

function PlayerDataManager.loadPlayer(player: Player)
    -- For MVP: use in-memory with DataStore fallback
    -- TODO: Replace with ProfileService when game ID is configured
    playerData[player.UserId] = PlayerDataManager.getDefaultData()
end

function PlayerDataManager.getData(player: Player): any?
    return playerData[player.UserId]
end

function PlayerDataManager.unloadPlayer(player: Player)
    -- TODO: Save to DataStore before clearing
    playerData[player.UserId] = nil
end

function PlayerDataManager.addToCollection(data: any, brainrotId: string)
    if not data.collection[brainrotId] then
        data.collection[brainrotId] = {
            count = 0,
            firstObtainedAt = os.time(),
        }
        data.collectionCount += 1
    end
    data.collection[brainrotId].count += 1
    data.stats.totalHarvested += 1
end

function PlayerDataManager.addCurrency(data: any, currencyType: string, amount: number)
    data.currencies[currencyType] = (data.currencies[currencyType] or 0) + amount
end

function PlayerDataManager.spendCurrency(data: any, currencyType: string, amount: number): boolean
    if (data.currencies[currencyType] or 0) < amount then
        return false
    end
    data.currencies[currencyType] -= amount
    return true
end

-- Connect player events
Players.PlayerAdded:Connect(function(player)
    PlayerDataManager.loadPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    PlayerDataManager.unloadPlayer(player)
end)

return PlayerDataManager
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All PlayerDataManager tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/server/PlayerDataManager.luau tests/server/PlayerDataManager.spec.luau
git commit -m "feat: implement PlayerDataManager with collection tracking and currency management"
```

---

## Task 5: Garden Manager (Plant, Water, Harvest)

**Files:**
- Create: `src/server/GardenManager.luau`
- Create: `tests/server/GardenManager.spec.luau`

- [ ] **Step 1: Write GardenManager tests**

```lua
-- tests/server/GardenManager.spec.luau
return function()
    local GardenManager = require(game.ServerScriptService.Server.GardenManager)
    local PlayerDataManager = require(game.ServerScriptService.Server.PlayerDataManager)
    local Config = require(game.ReplicatedStorage.Shared.Config)

    describe("GardenManager", function()
        local data

        beforeEach(function()
            data = PlayerDataManager.getDefaultData()
        end)

        describe("plantSeed", function()
            it("should plant in an empty bed", function()
                local success = GardenManager.plantSeed(data, 1, "Common")
                expect(success).to.equal(true)
                expect(data.garden.beds[1].rarity).to.equal("Common")
                expect(data.garden.beds[1].plantedAt).to.be.ok()
                expect(data.garden.beds[1].growthTime).to.equal(Config.GROWTH_TIMES["Common"])
            end)

            it("should fail if bed is occupied", function()
                GardenManager.plantSeed(data, 1, "Common")
                local success = GardenManager.plantSeed(data, 1, "Common")
                expect(success).to.equal(false)
            end)

            it("should fail for invalid bed index", function()
                local success = GardenManager.plantSeed(data, 0, "Common")
                expect(success).to.equal(false)
                local success2 = GardenManager.plantSeed(data, 99, "Common")
                expect(success2).to.equal(false)
            end)
        end)

        describe("waterBed", function()
            it("should reduce remaining growth time by 50%", function()
                GardenManager.plantSeed(data, 1, "Rare")
                local bed = data.garden.beds[1]
                local originalTime = bed.growthTime
                GardenManager.waterBed(data, 1)
                expect(bed.growthTime).to.equal(math.floor(originalTime * Config.WATER_SPEED_MULTIPLIER))
            end)

            it("should fail on empty bed", function()
                local success = GardenManager.waterBed(data, 1)
                expect(success).to.equal(false)
            end)
        end)

        describe("isBedReady", function()
            it("should return false for freshly planted bed", function()
                GardenManager.plantSeed(data, 1, "Common")
                expect(GardenManager.isBedReady(data, 1)).to.equal(false)
            end)
        end)

        describe("harvestBed", function()
            it("should fail on empty bed", function()
                local brainrot = GardenManager.harvestBed(data, 1)
                expect(brainrot).to.equal(nil)
            end)
        end)

        describe("upgradeBedCount", function()
            it("should add a bed if player has enough seeds", function()
                data.currencies.seeds = Config.BED_UPGRADE_COST
                local success = GardenManager.upgradeBedCount(data)
                expect(success).to.equal(true)
                expect(data.garden.bedCount).to.equal(Config.BASE_BED_COUNT + 1)
                expect(#data.garden.beds).to.equal(Config.BASE_BED_COUNT + 1)
            end)

            it("should fail if at max beds", function()
                data.garden.bedCount = Config.MAX_BED_COUNT
                data.currencies.seeds = Config.BED_UPGRADE_COST
                local success = GardenManager.upgradeBedCount(data)
                expect(success).to.equal(false)
            end)

            it("should fail if not enough seeds", function()
                local success = GardenManager.upgradeBedCount(data)
                expect(success).to.equal(false)
            end)
        end)
    end)
end
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — module not found

- [ ] **Step 3: Implement GardenManager**

```lua
-- src/server/GardenManager.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local DropSystem = require(script.Parent.DropSystem)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local GardenManager = {}

function GardenManager.plantSeed(data: any, bedIndex: number, rarity: string): boolean
    if bedIndex < 1 or bedIndex > data.garden.bedCount then
        return false
    end

    local bed = data.garden.beds[bedIndex]
    if not bed or bed.seedId ~= nil then
        return false
    end

    local growthTime = Config.GROWTH_TIMES[rarity]
    if not growthTime then
        return false
    end

    bed.seedId = rarity .. "_seed"
    bed.plantedAt = os.time()
    bed.rarity = rarity
    bed.growthTime = growthTime
    bed.isReady = false

    return true
end

function GardenManager.waterBed(data: any, bedIndex: number): boolean
    if bedIndex < 1 or bedIndex > data.garden.bedCount then
        return false
    end

    local bed = data.garden.beds[bedIndex]
    if not bed or bed.seedId == nil then
        return false
    end

    if bed.isReady then
        return false
    end

    bed.growthTime = math.floor(bed.growthTime * Config.WATER_SPEED_MULTIPLIER)
    return true
end

function GardenManager.isBedReady(data: any, bedIndex: number): boolean
    local bed = data.garden.beds[bedIndex]
    if not bed or bed.seedId == nil then
        return false
    end

    if bed.isReady then
        return true
    end

    local elapsed = os.time() - (bed.plantedAt or 0)
    if elapsed >= (bed.growthTime or math.huge) then
        bed.isReady = true
        return true
    end

    return false
end

function GardenManager.harvestBed(data: any, bedIndex: number, hasLuckyGamepass: boolean?): any?
    if not GardenManager.isBedReady(data, bedIndex) then
        return nil
    end

    local brainrot = DropSystem.rollBrainrot(hasLuckyGamepass)
    PlayerDataManager.addToCollection(data, brainrot.id)

    -- Clear the bed
    local bed = data.garden.beds[bedIndex]
    bed.seedId = nil
    bed.plantedAt = nil
    bed.rarity = nil
    bed.growthTime = nil
    bed.isReady = false

    return brainrot
end

function GardenManager.upgradeBedCount(data: any): boolean
    if data.garden.bedCount >= Config.MAX_BED_COUNT then
        return false
    end

    if not PlayerDataManager.spendCurrency(data, "seeds", Config.BED_UPGRADE_COST) then
        return false
    end

    data.garden.bedCount += 1
    table.insert(data.garden.beds, {
        seedId = nil,
        plantedAt = nil,
        rarity = nil,
        growthTime = nil,
        isReady = false,
    })

    return true
end

return GardenManager
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All GardenManager tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/server/GardenManager.luau tests/server/GardenManager.spec.luau
git commit -m "feat: implement GardenManager with plant, water, harvest, and bed upgrade logic"
```

---

## Task 6: Monetization Manager (Gamepasses & Dev Products)

**Files:**
- Create: `src/server/MonetizationManager.luau`

- [ ] **Step 1: Implement MonetizationManager**

```lua
-- src/server/MonetizationManager.luau
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local MonetizationManager = {}

function MonetizationManager.hasGamepass(player: Player, gamepassKey: string): boolean
    local data = PlayerDataManager.getData(player)
    if not data then return false end

    -- Check cached data first
    if data.gamepasses[gamepassKey] then
        return true
    end

    -- Check MarketplaceService (handles purchases made outside current session)
    local gamepassInfo = Config.GAMEPASSES[gamepassKey]
    if not gamepassInfo or gamepassInfo.id == 0 then
        return false
    end

    local success, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassInfo.id)
    end)

    if success and owns then
        data.gamepasses[gamepassKey] = true
        return true
    end

    return false
end

function MonetizationManager.init()
    -- Handle gamepass purchases
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
        if not wasPurchased then return end

        local data = PlayerDataManager.getData(player)
        if not data then return end

        for key, info in Config.GAMEPASSES do
            if info.id == gamepassId then
                data.gamepasses[key] = true

                -- Apply VIP Gardener extra beds
                if key == "VIP_GARDENER" then
                    for i = 1, info.extraBeds do
                        if data.garden.bedCount < Config.MAX_BED_COUNT then
                            data.garden.bedCount += 1
                            table.insert(data.garden.beds, {
                                seedId = nil, plantedAt = nil,
                                rarity = nil, growthTime = nil, isReady = false,
                            })
                        end
                    end
                end

                break
            end
        end
    end)

    -- Handle developer product purchases
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

        local data = PlayerDataManager.getData(player)
        if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end

        for key, info in Config.DEV_PRODUCTS do
            if info.id == receiptInfo.ProductId then
                if key == "GOLDEN_SEED_PACK" then
                    PlayerDataManager.addCurrency(data, "goldenSeeds", info.amount)
                elseif key == "MEGA_FERTILIZER" then
                    -- Instantly grow next N plants
                    local fertilized = 0
                    for _, bed in data.garden.beds do
                        if bed.seedId and not bed.isReady and fertilized < info.amount then
                            bed.isReady = true
                            fertilized += 1
                        end
                    end
                end

                return Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end

        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

return MonetizationManager
```

- [ ] **Step 2: Commit**

```bash
git add src/server/MonetizationManager.luau
git commit -m "feat: implement MonetizationManager for gamepasses and developer products"
```

---

## Task 7: Daily Reward Manager

**Files:**
- Create: `src/server/DailyRewardManager.luau`
- Create: `tests/server/DailyRewardManager.spec.luau`

- [ ] **Step 1: Write DailyRewardManager tests**

```lua
-- tests/server/DailyRewardManager.spec.luau
return function()
    local DailyRewardManager = require(game.ServerScriptService.Server.DailyRewardManager)
    local PlayerDataManager = require(game.ServerScriptService.Server.PlayerDataManager)
    local Config = require(game.ReplicatedStorage.Shared.Config)

    describe("DailyRewardManager", function()
        local data

        beforeEach(function()
            data = PlayerDataManager.getDefaultData()
        end)

        describe("canClaim", function()
            it("should allow first-time claim", function()
                expect(DailyRewardManager.canClaim(data)).to.equal(true)
            end)

            it("should deny claim if cooldown not elapsed", function()
                data.dailyReward.lastClaimed = os.time()
                expect(DailyRewardManager.canClaim(data)).to.equal(false)
            end)
        end)

        describe("claim", function()
            it("should grant base reward on first claim", function()
                local reward = DailyRewardManager.claim(data)
                expect(reward).to.equal(Config.DAILY_REWARD_BASE)
                expect(data.currencies.seeds).to.equal(Config.DAILY_REWARD_BASE)
                expect(data.dailyReward.streak).to.equal(1)
            end)

            it("should increase streak on consecutive claims", function()
                data.dailyReward.lastClaimed = os.time() - Config.DAILY_REWARD_COOLDOWN - 1
                data.dailyReward.streak = 3
                local reward = DailyRewardManager.claim(data)
                expect(data.dailyReward.streak).to.equal(4)
                local expected = Config.DAILY_REWARD_BASE + (4 * Config.DAILY_REWARD_STREAK_BONUS)
                expect(reward).to.equal(expected)
            end)

            it("should cap streak at max", function()
                data.dailyReward.lastClaimed = os.time() - Config.DAILY_REWARD_COOLDOWN - 1
                data.dailyReward.streak = Config.DAILY_REWARD_MAX_STREAK
                DailyRewardManager.claim(data)
                expect(data.dailyReward.streak).to.equal(Config.DAILY_REWARD_MAX_STREAK)
            end)
        end)
    end)
end
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — module not found

- [ ] **Step 3: Implement DailyRewardManager**

```lua
-- src/server/DailyRewardManager.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local DailyRewardManager = {}

function DailyRewardManager.canClaim(data: any): boolean
    local elapsed = os.time() - data.dailyReward.lastClaimed
    return elapsed >= Config.DAILY_REWARD_COOLDOWN
end

function DailyRewardManager.claim(data: any): number?
    if not DailyRewardManager.canClaim(data) then
        return nil
    end

    -- Check if streak should reset (more than 48h since last claim)
    local elapsed = os.time() - data.dailyReward.lastClaimed
    if data.dailyReward.lastClaimed > 0 and elapsed > Config.DAILY_REWARD_COOLDOWN * 2 then
        data.dailyReward.streak = 0
    end

    -- Increment streak (cap at max)
    if data.dailyReward.streak < Config.DAILY_REWARD_MAX_STREAK then
        data.dailyReward.streak += 1
    end

    data.dailyReward.lastClaimed = os.time()

    -- Calculate reward
    local reward = Config.DAILY_REWARD_BASE + (data.dailyReward.streak * Config.DAILY_REWARD_STREAK_BONUS)
    PlayerDataManager.addCurrency(data, "seeds", reward)

    return reward
end

return DailyRewardManager
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All DailyRewardManager tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/server/DailyRewardManager.luau tests/server/DailyRewardManager.spec.luau
git commit -m "feat: implement DailyRewardManager with streak system"
```

---

## Task 8: Server Remote Event Handlers

**Files:**
- Modify: `src/server/init.server.luau`

- [ ] **Step 1: Wire up all remote event handlers in server bootstrap**

```lua
-- src/server/init.server.luau (full replacement)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Config = require(ReplicatedStorage.Shared.Config)

-- Create RemoteEvents
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

for _, remoteName in Remotes do
    local remote = Instance.new("RemoteEvent")
    remote.Name = remoteName
    remote.Parent = remotesFolder
end

-- Load managers
local PlayerDataManager = require(script.PlayerDataManager)
local GardenManager = require(script.GardenManager)
local DropSystem = require(script.DropSystem)
local MonetizationManager = require(script.MonetizationManager)
local DailyRewardManager = require(script.DailyRewardManager)

MonetizationManager.init()

-- Helper: send updated data to client
local function syncData(player: Player)
    local data = PlayerDataManager.getData(player)
    if data then
        remotesFolder.UpdatePlayerData:FireClient(player, data)
    end
end

-- Sync data when player loads
Players.PlayerAdded:Connect(function(player)
    task.wait(1) -- wait for data to load
    syncData(player)
end)

-- Plant seed
remotesFolder.PlantSeed.OnServerEvent:Connect(function(player, bedIndex: number, rarity: string)
    local data = PlayerDataManager.getData(player)
    if not data then return end

    if rarity ~= "Common" then return end -- MVP: only free Common seeds

    if GardenManager.plantSeed(data, bedIndex, rarity) then
        syncData(player)
    end
end)

-- Water bed
remotesFolder.WaterBed.OnServerEvent:Connect(function(player, bedIndex: number)
    local data = PlayerDataManager.getData(player)
    if not data then return end

    if GardenManager.waterBed(data, bedIndex) then
        syncData(player)
    end
end)

-- Harvest bed
remotesFolder.HarvestBed.OnServerEvent:Connect(function(player, bedIndex: number)
    local data = PlayerDataManager.getData(player)
    if not data then return end

    local hasLucky = MonetizationManager.hasGamepass(player, "LUCKY_GARDENER")
    local brainrot = GardenManager.harvestBed(data, bedIndex, hasLucky)

    if brainrot then
        syncData(player)

        -- Trigger drop animation on client
        local isRare = brainrot.rarity == "Legendary" or brainrot.rarity == "Mythic"
        remotesFolder.PlayDropAnimation:FireClient(player, brainrot, isRare)
    end
end)

-- Sell brainrot
remotesFolder.SellBrainrot.OnServerEvent:Connect(function(player, brainrotId: string)
    local data = PlayerDataManager.getData(player)
    if not data then return end

    local entry = data.collection[brainrotId]
    if not entry or entry.count < 2 then return end -- keep at least 1

    local BrainrotDatabase = require(ReplicatedStorage.Shared.BrainrotDatabase)
    local brainrot = BrainrotDatabase[brainrotId]
    if not brainrot then return end

    entry.count -= 1
    local sellValue = brainrot.sellValue
    if MonetizationManager.hasGamepass(player, "DOUBLE_COLLECTION") then
        sellValue *= 2
    end
    PlayerDataManager.addCurrency(data, "seeds", sellValue)
    data.stats.totalSold += 1

    syncData(player)
end)

-- Claim daily reward
remotesFolder.ClaimDailyReward.OnServerEvent:Connect(function(player)
    local data = PlayerDataManager.getData(player)
    if not data then return end

    DailyRewardManager.claim(data)
    syncData(player)
end)

-- Upgrade garden
remotesFolder.UpgradeGarden.OnServerEvent:Connect(function(player)
    local data = PlayerDataManager.getData(player)
    if not data then return end

    if GardenManager.upgradeBedCount(data) then
        syncData(player)
    end
end)

-- Auto-harvest loop for gamepass owners
task.spawn(function()
    while true do
        task.wait(5)
        for _, player in Players:GetPlayers() do
            if MonetizationManager.hasGamepass(player, "AUTO_HARVEST") then
                local data = PlayerDataManager.getData(player)
                if data then
                    for i = 1, data.garden.bedCount do
                        if GardenManager.isBedReady(data, i) then
                            local hasLucky = MonetizationManager.hasGamepass(player, "LUCKY_GARDENER")
                            local brainrot = GardenManager.harvestBed(data, i, hasLucky)
                            if brainrot then
                                local isRare = brainrot.rarity == "Legendary" or brainrot.rarity == "Mythic"
                                remotesFolder.PlayDropAnimation:FireClient(player, brainrot, isRare)
                            end
                        end
                    end
                    syncData(player)
                end
            end
        end
    end
end)

print("[Server] Grow a Brainrot server initialized")
```

- [ ] **Step 2: Test by running game in Studio play mode**

Expected: Server prints initialization message, no errors in output.

- [ ] **Step 3: Commit**

```bash
git add src/server/init.server.luau
git commit -m "feat: wire up all server remote event handlers and auto-harvest loop"
```

---

## Task 9: Client HUD (Currencies & Navigation)

**Files:**
- Create: `src/client/HUD.luau`
- Modify: `src/client/init.client.luau`

- [ ] **Step 1: Implement HUD module**

```lua
-- src/client/HUD.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUD = {}

local screenGui: ScreenGui
local seedsLabel: TextLabel
local goldenSeedsLabel: TextLabel
local collectionLabel: TextLabel

function HUD.create()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Top bar frame
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 50)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    topBar.BackgroundTransparency = 0.3
    topBar.Parent = screenGui

    -- Seeds counter
    seedsLabel = Instance.new("TextLabel")
    seedsLabel.Name = "Seeds"
    seedsLabel.Size = UDim2.new(0, 150, 1, 0)
    seedsLabel.Position = UDim2.new(0, 10, 0, 0)
    seedsLabel.BackgroundTransparency = 1
    seedsLabel.Text = "Seeds: 0"
    seedsLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
    seedsLabel.TextSize = 20
    seedsLabel.Font = Enum.Font.GothamBold
    seedsLabel.TextXAlignment = Enum.TextXAlignment.Left
    seedsLabel.Parent = topBar

    -- Golden Seeds counter
    goldenSeedsLabel = Instance.new("TextLabel")
    goldenSeedsLabel.Name = "GoldenSeeds"
    goldenSeedsLabel.Size = UDim2.new(0, 180, 1, 0)
    goldenSeedsLabel.Position = UDim2.new(0, 170, 0, 0)
    goldenSeedsLabel.BackgroundTransparency = 1
    goldenSeedsLabel.Text = "Golden Seeds: 0"
    goldenSeedsLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
    goldenSeedsLabel.TextSize = 20
    goldenSeedsLabel.Font = Enum.Font.GothamBold
    goldenSeedsLabel.TextXAlignment = Enum.TextXAlignment.Left
    goldenSeedsLabel.Parent = topBar

    -- Collection counter
    collectionLabel = Instance.new("TextLabel")
    collectionLabel.Name = "Collection"
    collectionLabel.Size = UDim2.new(0, 150, 1, 0)
    collectionLabel.Position = UDim2.new(0, 360, 0, 0)
    collectionLabel.BackgroundTransparency = 1
    collectionLabel.Text = "Collection: 0"
    collectionLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    collectionLabel.TextSize = 20
    collectionLabel.Font = Enum.Font.GothamBold
    collectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    collectionLabel.Parent = topBar

    -- Bottom buttons frame
    local bottomBar = Instance.new("Frame")
    bottomBar.Name = "BottomBar"
    bottomBar.Size = UDim2.new(1, 0, 0, 60)
    bottomBar.Position = UDim2.new(0, 0, 1, -60)
    bottomBar.BackgroundTransparency = 1
    bottomBar.Parent = screenGui

    local buttons = {"Shop", "Collection", "Daily"}
    for i, name in buttons do
        local btn = Instance.new("TextButton")
        btn.Name = name .. "Button"
        btn.Size = UDim2.new(0, 100, 0, 40)
        btn.Position = UDim2.new(0.5, -160 + (i - 1) * 110, 0, 10)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = name
        btn.TextSize = 18
        btn.Font = Enum.Font.GothamBold
        btn.Parent = bottomBar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
    end
end

function HUD.update(data)
    if seedsLabel then
        seedsLabel.Text = "Seeds: " .. tostring(data.currencies.seeds)
    end
    if goldenSeedsLabel then
        goldenSeedsLabel.Text = "Golden Seeds: " .. tostring(data.currencies.goldenSeeds)
    end
    if collectionLabel then
        collectionLabel.Text = "Collection: " .. tostring(data.collectionCount)
    end
end

return HUD
```

- [ ] **Step 2: Update client bootstrap to use HUD and listen for data updates**

```lua
-- src/client/init.client.luau (full replacement)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = require(script.HUD)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotesFolder then
    warn("[Client] Remotes folder not found!")
    return
end

-- Create HUD
HUD.create()

-- Local data cache
local playerData = nil

-- Listen for data updates from server
remotesFolder.UpdatePlayerData.OnClientEvent:Connect(function(data)
    playerData = data
    HUD.update(data)
end)

-- Expose data getter for other client modules
local ClientState = {}
function ClientState.getData()
    return playerData
end
function ClientState.getRemotes()
    return remotesFolder
end

-- Store in shared location for other client scripts
local clientState = Instance.new("BindableEvent")
clientState.Name = "ClientState"
clientState.Parent = script

-- Make ClientState accessible
_G.ClientState = ClientState

print("[Client] Grow a Brainrot client initialized")
```

- [ ] **Step 3: Test in Studio play mode**

Expected: HUD appears with Seeds: 0, Golden Seeds: 0, Collection: 0. Bottom buttons visible.

- [ ] **Step 4: Commit**

```bash
git add src/client/HUD.luau src/client/init.client.luau
git commit -m "feat: implement client HUD with currency display and navigation buttons"
```

---

## Task 10: Garden UI (Bed Interaction)

**Files:**
- Create: `src/client/GardenUI.luau`

- [ ] **Step 1: Implement GardenUI**

```lua
-- src/client/GardenUI.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local GardenUI = {}

local screenGui: ScreenGui
local gardenFrame: Frame

function GardenUI.create()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GardenUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    gardenFrame = Instance.new("Frame")
    gardenFrame.Name = "GardenFrame"
    gardenFrame.Size = UDim2.new(0, 400, 0, 300)
    gardenFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
    gardenFrame.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    gardenFrame.BackgroundTransparency = 0.2
    gardenFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = gardenFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "Your Garden"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = gardenFrame
end

function GardenUI.update(data)
    if not gardenFrame then return end

    -- Clear existing bed buttons
    for _, child in gardenFrame:GetChildren() do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

    for i = 1, data.garden.bedCount do
        local bed = data.garden.beds[i]
        local row = math.ceil(i / 4)
        local col = ((i - 1) % 4) + 1

        local btn = Instance.new("TextButton")
        btn.Name = "Bed" .. i
        btn.Size = UDim2.new(0, 80, 0, 80)
        btn.Position = UDim2.new(0, 10 + (col - 1) * 95, 0, 30 + (row - 1) * 95)
        btn.Parent = gardenFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        if bed.seedId == nil then
            -- Empty bed
            btn.BackgroundColor3 = Color3.fromRGB(80, 50, 30)
            btn.Text = "Plant"
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.TextSize = 14
            btn.Font = Enum.Font.GothamBold
            btn.MouseButton1Click:Connect(function()
                remotesFolder.PlantSeed:FireServer(i, "Common")
            end)
        elseif bed.isReady then
            -- Ready to harvest
            btn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
            btn.Text = "Harvest!"
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 14
            btn.Font = Enum.Font.GothamBold
            btn.MouseButton1Click:Connect(function()
                remotesFolder.HarvestBed:FireServer(i)
            end)
        else
            -- Growing
            btn.BackgroundColor3 = Color3.fromRGB(120, 100, 40)
            btn.Text = "Growing..."
            btn.TextColor3 = Color3.fromRGB(200, 200, 100)
            btn.TextSize = 12
            btn.Font = Enum.Font.Gotham

            -- Water button overlay
            local waterBtn = Instance.new("TextButton")
            waterBtn.Name = "Water"
            waterBtn.Size = UDim2.new(1, 0, 0, 20)
            waterBtn.Position = UDim2.new(0, 0, 1, -20)
            waterBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
            waterBtn.Text = "Water"
            waterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            waterBtn.TextSize = 11
            waterBtn.Font = Enum.Font.GothamBold
            waterBtn.Parent = btn
            waterBtn.MouseButton1Click:Connect(function()
                remotesFolder.WaterBed:FireServer(i)
            end)
        end
    end
end

return GardenUI
```

- [ ] **Step 2: Wire GardenUI into client bootstrap**

Add to `src/client/init.client.luau` after HUD.create():

```lua
local GardenUI = require(script.GardenUI)
GardenUI.create()

remotesFolder.UpdatePlayerData.OnClientEvent:Connect(function(data)
    playerData = data
    HUD.update(data)
    GardenUI.update(data)
end)
```

(Remove the previous duplicate UpdatePlayerData listener.)

- [ ] **Step 3: Test in Studio play mode**

Expected: Garden grid visible with "Plant" buttons. Clicking "Plant" → shows "Growing...", water button appears. After growth time → "Harvest!" appears.

- [ ] **Step 4: Commit**

```bash
git add src/client/GardenUI.luau src/client/init.client.luau
git commit -m "feat: implement GardenUI with plant, water, and harvest bed interaction"
```

---

## Task 11: Drop Animation ("OMG Moment")

**Files:**
- Create: `src/client/DropAnimation.luau`

- [ ] **Step 1: Implement DropAnimation**

```lua
-- src/client/DropAnimation.luau
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local DropAnimation = {}

local RARITY_COLORS = {
    Common = Color3.fromRGB(180, 180, 180),
    Uncommon = Color3.fromRGB(80, 200, 80),
    Rare = Color3.fromRGB(50, 120, 255),
    Epic = Color3.fromRGB(180, 50, 255),
    Legendary = Color3.fromRGB(255, 200, 0),
    Mythic = Color3.fromRGB(255, 50, 50),
}

local RARITY_CHANCE_TEXT = {
    Legendary = "1 in 40 chance!",
    Mythic = "1 in 200 chance!",
}

function DropAnimation.play(brainrot, isRareDrop: boolean)
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "DropAnimation"
    gui.DisplayOrder = 100
    gui.Parent = playerGui

    local color = RARITY_COLORS[brainrot.rarity] or RARITY_COLORS.Common

    -- Background flash for rare drops
    if isRareDrop then
        local flash = Instance.new("Frame")
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.BackgroundColor3 = color
        flash.BackgroundTransparency = 0.5
        flash.Parent = gui

        local flashTween = TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1
        })
        flashTween:Play()
    end

    -- Main card
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 300, 0, 200)
    card.Position = UDim2.new(0.5, -150, 0.5, -100)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    card.Parent = gui

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 16)
    cardCorner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 3
    stroke.Parent = card

    -- Rarity label
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0, 30)
    rarityLabel.Position = UDim2.new(0, 0, 0, 10)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = brainrot.rarity
    rarityLabel.TextColor3 = color
    rarityLabel.TextSize = 18
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.Parent = card

    -- Brainrot name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -20, 0, 40)
    nameLabel.Position = UDim2.new(0, 10, 0, 70)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = brainrot.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 24
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextWrapped = true
    nameLabel.Parent = card

    -- Chance text for Legendary/Mythic
    if isRareDrop and RARITY_CHANCE_TEXT[brainrot.rarity] then
        local chanceLabel = Instance.new("TextLabel")
        chanceLabel.Size = UDim2.new(1, 0, 0, 25)
        chanceLabel.Position = UDim2.new(0, 0, 0, 120)
        chanceLabel.BackgroundTransparency = 1
        chanceLabel.Text = RARITY_CHANCE_TEXT[brainrot.rarity]
        chanceLabel.TextColor3 = color
        chanceLabel.TextSize = 16
        chanceLabel.Font = Enum.Font.GothamBold
        chanceLabel.Parent = card
    end

    -- Tap to close
    local closeLabel = Instance.new("TextLabel")
    closeLabel.Size = UDim2.new(1, 0, 0, 20)
    closeLabel.Position = UDim2.new(0, 0, 1, -25)
    closeLabel.BackgroundTransparency = 1
    closeLabel.Text = "Tap to close"
    closeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    closeLabel.TextSize = 12
    closeLabel.Font = Enum.Font.Gotham
    closeLabel.Parent = card

    -- Scale-in animation
    card.Size = UDim2.new(0, 0, 0, 0)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    local openTween = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 300, 0, 200),
        Position = UDim2.new(0.5, -150, 0.5, -100),
    })
    openTween:Play()

    -- Close on click
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, 0, 1, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = ""
    closeBtn.Parent = gui
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    -- Auto-close after 5 seconds
    task.delay(5, function()
        if gui.Parent then
            gui:Destroy()
        end
    end)
end

return DropAnimation
```

- [ ] **Step 2: Wire into client bootstrap**

Add to `src/client/init.client.luau`:

```lua
local DropAnimation = require(script.DropAnimation)

remotesFolder.PlayDropAnimation.OnClientEvent:Connect(function(brainrot, isRareDrop)
    DropAnimation.play(brainrot, isRareDrop)
end)
```

- [ ] **Step 3: Test in Studio — harvest a plant and verify animation appears**

Expected: Card animates in with brainrot name, rarity color, and rarity label. Auto-closes after 5s or on tap.

- [ ] **Step 4: Commit**

```bash
git add src/client/DropAnimation.luau src/client/init.client.luau
git commit -m "feat: implement OMG moment drop animation with rarity-based effects"
```

---

## Task 12: Collection Book UI

**Files:**
- Create: `src/client/CollectionBook.luau`

- [ ] **Step 1: Implement CollectionBook**

```lua
-- src/client/CollectionBook.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotDatabase = require(ReplicatedStorage.Shared.BrainrotDatabase)
local Config = require(ReplicatedStorage.Shared.Config)

local CollectionBook = {}

local RARITY_COLORS = {
    Common = Color3.fromRGB(180, 180, 180),
    Uncommon = Color3.fromRGB(80, 200, 80),
    Rare = Color3.fromRGB(50, 120, 255),
    Epic = Color3.fromRGB(180, 50, 255),
    Legendary = Color3.fromRGB(255, 200, 0),
    Mythic = Color3.fromRGB(255, 50, 50),
}

local RARITY_ORDER = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}

local screenGui: ScreenGui
local visible = false

function CollectionBook.create()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CollectionBook"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "BookFrame"
    frame.Size = UDim2.new(0, 500, 0, 400)
    frame.Position = UDim2.new(0.5, -250, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Brainrot Collection"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    -- Close button
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
        CollectionBook.toggle()
    end)

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn

    -- Scroll frame for brainrots
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "BrainrotList"
    scroll.Size = UDim2.new(1, -20, 1, -50)
    scroll.Position = UDim2.new(0, 10, 0, 45)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6
    scroll.Parent = frame

    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0, 90, 0, 90)
    layout.CellPadding = UDim2.new(0, 8, 0, 8)
    layout.Parent = scroll
end

function CollectionBook.update(data)
    if not screenGui then return end
    local scroll = screenGui.BookFrame.BrainrotList

    -- Clear existing entries
    for _, child in scroll:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Sort brainrots by rarity
    local sorted = {}
    for _, brainrot in BrainrotDatabase do
        table.insert(sorted, brainrot)
    end
    table.sort(sorted, function(a, b)
        local aIdx = table.find(RARITY_ORDER, a.rarity) or 0
        local bIdx = table.find(RARITY_ORDER, b.rarity) or 0
        return aIdx < bIdx
    end)

    for _, brainrot in sorted do
        local owned = data.collection[brainrot.id]
        local color = RARITY_COLORS[brainrot.rarity] or RARITY_COLORS.Common

        local entry = Instance.new("Frame")
        entry.Name = brainrot.id
        entry.BackgroundColor3 = owned and color or Color3.fromRGB(40, 40, 40)
        entry.BackgroundTransparency = owned and 0.3 or 0.7
        entry.Parent = scroll

        local entryCorner = Instance.new("UICorner")
        entryCorner.CornerRadius = UDim.new(0, 8)
        entryCorner.Parent = entry

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -4, 0.6, 0)
        nameLabel.Position = UDim2.new(0, 2, 0, 2)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = owned and brainrot.name or "???"
        nameLabel.TextColor3 = owned and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
        nameLabel.TextSize = 10
        nameLabel.TextWrapped = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = entry

        local countLabel = Instance.new("TextLabel")
        countLabel.Size = UDim2.new(1, 0, 0.3, 0)
        countLabel.Position = UDim2.new(0, 0, 0.65, 0)
        countLabel.BackgroundTransparency = 1
        countLabel.Text = owned and ("x" .. owned.count) or ""
        countLabel.TextColor3 = color
        countLabel.TextSize = 12
        countLabel.Font = Enum.Font.GothamBold
        countLabel.Parent = entry
    end

    -- Update canvas size
    local layout = scroll:FindFirstChildOfClass("UIGridLayout")
    if layout then
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end
end

function CollectionBook.toggle()
    visible = not visible
    screenGui.Enabled = visible
end

return CollectionBook
```

- [ ] **Step 2: Wire Collection button in client bootstrap**

Add to `src/client/init.client.luau`:

```lua
local CollectionBook = require(script.CollectionBook)
CollectionBook.create()

-- Wire Collection button
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local collectionBtn = playerGui:WaitForChild("HUD").BottomBar.CollectionButton
collectionBtn.MouseButton1Click:Connect(function()
    CollectionBook.toggle()
    if playerData then
        CollectionBook.update(playerData)
    end
end)
```

Also update the data sync to refresh CollectionBook:

```lua
remotesFolder.UpdatePlayerData.OnClientEvent:Connect(function(data)
    playerData = data
    HUD.update(data)
    GardenUI.update(data)
    CollectionBook.update(data)
end)
```

- [ ] **Step 3: Test in Studio**

Expected: Collection button opens/closes book. Owned brainrots show name + count, unowned show "???" greyed out.

- [ ] **Step 4: Commit**

```bash
git add src/client/CollectionBook.luau src/client/init.client.luau
git commit -m "feat: implement CollectionBook UI with rarity-sorted grid and owned/unowned states"
```

---

## Task 13: Shop UI (Gamepasses & Dev Products)

**Files:**
- Create: `src/client/ShopUI.luau`

- [ ] **Step 1: Implement ShopUI**

```lua
-- src/client/ShopUI.luau
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local ShopUI = {}

local screenGui: ScreenGui
local visible = false

function ShopUI.create()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShopUI"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "ShopFrame"
    frame.Size = UDim2.new(0, 400, 0, 350)
    frame.Position = UDim2.new(0.5, -200, 0.5, -175)
    frame.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Shop"
    title.TextColor3 = Color3.fromRGB(255, 220, 50)
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    -- Close button
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
        ShopUI.toggle()
    end)

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn

    -- Gamepasses section
    local yOffset = 50
    local gamepassLabels = {
        {key = "VIP_GARDENER", name = "VIP Gardener", desc = "+2 beds, golden can, VIP badge", price = 199},
        {key = "AUTO_HARVEST", name = "Auto-Harvest", desc = "Auto-collect ready brainrots", price = 149},
        {key = "DOUBLE_COLLECTION", name = "Double Collection", desc = "2x Seeds from selling", price = 99},
    }

    for _, gp in gamepassLabels do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 60)
        btn.Position = UDim2.new(0.05, 0, 0, yOffset)
        btn.BackgroundColor3 = Color3.fromRGB(50, 40, 80)
        btn.Parent = frame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
        nameLabel.Position = UDim2.new(0.02, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = gp.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = btn

        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
        descLabel.Position = UDim2.new(0.02, 0, 0.5, 0)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = gp.desc
        descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        descLabel.TextSize = 11
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = btn

        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(0.3, 0, 1, 0)
        priceLabel.Position = UDim2.new(0.7, 0, 0, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = "R$ " .. gp.price
        priceLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
        priceLabel.TextSize = 18
        priceLabel.Font = Enum.Font.GothamBold
        priceLabel.Parent = btn

        btn.MouseButton1Click:Connect(function()
            local gamepassId = Config.GAMEPASSES[gp.key] and Config.GAMEPASSES[gp.key].id
            if gamepassId and gamepassId > 0 then
                MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, gamepassId)
            end
        end)

        yOffset += 70
    end

    -- Dev Products section
    local devProductLabels = {
        {key = "GOLDEN_SEED_PACK", name = "Golden Seed Pack (5x)", price = 49},
        {key = "MEGA_FERTILIZER", name = "Mega Fertilizer (10x)", price = 29},
    }

    for _, dp in devProductLabels do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 40)
        btn.Position = UDim2.new(0.05, 0, 0, yOffset)
        btn.BackgroundColor3 = Color3.fromRGB(80, 60, 20)
        btn.Parent = frame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
        nameLabel.Position = UDim2.new(0.02, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = dp.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = btn

        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(0.3, 0, 1, 0)
        priceLabel.Position = UDim2.new(0.7, 0, 0, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = "R$ " .. dp.price
        priceLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
        priceLabel.TextSize = 16
        priceLabel.Font = Enum.Font.GothamBold
        priceLabel.Parent = btn

        btn.MouseButton1Click:Connect(function()
            local productId = Config.DEV_PRODUCTS[dp.key] and Config.DEV_PRODUCTS[dp.key].id
            if productId and productId > 0 then
                MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
            end
        end)

        yOffset += 50
    end
end

function ShopUI.toggle()
    visible = not visible
    screenGui.Enabled = visible
end

return ShopUI
```

- [ ] **Step 2: Wire Shop button in client bootstrap**

Add to `src/client/init.client.luau`:

```lua
local ShopUI = require(script.ShopUI)
ShopUI.create()

local shopBtn = playerGui:WaitForChild("HUD").BottomBar.ShopButton
shopBtn.MouseButton1Click:Connect(function()
    ShopUI.toggle()
end)
```

- [ ] **Step 3: Test in Studio**

Expected: Shop button opens shop with 3 gamepasses and 2 dev products listed with prices.

- [ ] **Step 4: Commit**

```bash
git add src/client/ShopUI.luau src/client/init.client.luau
git commit -m "feat: implement ShopUI with gamepass and developer product listings"
```

---

## Task 14: Daily Rewards UI

**Files:**
- Create: `src/client/DailyRewardsUI.luau`

- [ ] **Step 1: Implement DailyRewardsUI**

```lua
-- src/client/DailyRewardsUI.luau
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

    -- Close button
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
```

- [ ] **Step 2: Wire Daily button in client bootstrap**

Add to `src/client/init.client.luau`:

```lua
local DailyRewardsUI = require(script.DailyRewardsUI)
DailyRewardsUI.create()

local dailyBtn = playerGui:WaitForChild("HUD").BottomBar.DailyButton
dailyBtn.MouseButton1Click:Connect(function()
    DailyRewardsUI.toggle()
    if playerData then
        DailyRewardsUI.update(playerData)
    end
end)
```

Also add DailyRewardsUI.update to the data sync listener.

- [ ] **Step 3: Test in Studio**

Expected: Daily button opens reward screen with streak, reward amount, and claim button.

- [ ] **Step 4: Commit**

```bash
git add src/client/DailyRewardsUI.luau src/client/init.client.luau
git commit -m "feat: implement DailyRewardsUI with streak display and claim functionality"
```

---

## Task 15: Leaderboard UI

**Files:**
- Create: `src/client/LeaderboardUI.luau`

- [ ] **Step 1: Implement LeaderboardUI**

```lua
-- src/client/LeaderboardUI.luau
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local LeaderboardUI = {}

function LeaderboardUI.create()
    local player = Players.LocalPlayer

    -- Create standard Roblox leaderboard stat
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local collection = Instance.new("IntValue")
    collection.Name = "Collection"
    collection.Value = 0
    collection.Parent = leaderstats
end

function LeaderboardUI.update(data)
    local player = Players.LocalPlayer
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local collection = leaderstats:FindFirstChild("Collection")
        if collection then
            collection.Value = data.collectionCount or 0
        end
    end
end

return LeaderboardUI
```

- [ ] **Step 2: Wire into client bootstrap**

Add to `src/client/init.client.luau`:

```lua
local LeaderboardUI = require(script.LeaderboardUI)
LeaderboardUI.create()
```

Add `LeaderboardUI.update(data)` to the data sync listener.

- [ ] **Step 3: Test in Studio**

Expected: Standard Roblox leaderboard appears showing "Collection" count for each player.

- [ ] **Step 4: Commit**

```bash
git add src/client/LeaderboardUI.luau src/client/init.client.luau
git commit -m "feat: implement leaderboard showing collection count via standard leaderstats"
```

---

## Task 16: Final Client Bootstrap Assembly

**Files:**
- Modify: `src/client/init.client.luau`

- [ ] **Step 1: Write the complete, final client bootstrap**

Consolidate all the pieces wired in previous tasks into a clean, final `init.client.luau`:

```lua
-- src/client/init.client.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUD = require(script.HUD)
local GardenUI = require(script.GardenUI)
local DropAnimation = require(script.DropAnimation)
local CollectionBook = require(script.CollectionBook)
local ShopUI = require(script.ShopUI)
local DailyRewardsUI = require(script.DailyRewardsUI)
local LeaderboardUI = require(script.LeaderboardUI)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotesFolder then
    warn("[Client] Remotes folder not found!")
    return
end

-- Initialize all UI
HUD.create()
GardenUI.create()
CollectionBook.create()
ShopUI.create()
DailyRewardsUI.create()
LeaderboardUI.create()

-- Player data cache
local playerData = nil

-- Central data sync
remotesFolder.UpdatePlayerData.OnClientEvent:Connect(function(data)
    playerData = data
    HUD.update(data)
    GardenUI.update(data)
    CollectionBook.update(data)
    DailyRewardsUI.update(data)
    LeaderboardUI.update(data)
end)

-- Drop animation
remotesFolder.PlayDropAnimation.OnClientEvent:Connect(function(brainrot, isRareDrop)
    DropAnimation.play(brainrot, isRareDrop)
end)

-- Wire bottom bar buttons
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.defer(function()
    local hud = playerGui:WaitForChild("HUD", 5)
    if not hud then return end
    local bottomBar = hud:WaitForChild("BottomBar", 5)
    if not bottomBar then return end

    bottomBar.ShopButton.MouseButton1Click:Connect(function()
        ShopUI.toggle()
    end)

    bottomBar.CollectionButton.MouseButton1Click:Connect(function()
        CollectionBook.toggle()
        if playerData then CollectionBook.update(playerData) end
    end)

    bottomBar.DailyButton.MouseButton1Click:Connect(function()
        DailyRewardsUI.toggle()
        if playerData then DailyRewardsUI.update(playerData) end
    end)
end)

print("[Client] Grow a Brainrot client initialized")
```

- [ ] **Step 2: Full integration test in Studio play mode**

Test checklist:
1. HUD shows currencies and collection count
2. Garden beds show Plant → Growing → Harvest flow
3. Watering works and speeds growth
4. Harvesting triggers drop animation with correct rarity colors
5. Collection Book shows owned brainrots
6. Shop displays gamepasses and dev products
7. Daily Reward shows streak and claim button
8. Leaderboard shows Collection stat

- [ ] **Step 3: Commit**

```bash
git add src/client/init.client.luau
git commit -m "feat: assemble final client bootstrap with all UI modules wired together"
```

---

## Task 17: Growth Timer Refresh Loop

**Files:**
- Modify: `src/server/init.server.luau`

- [ ] **Step 1: Add server-side bed readiness check loop**

Add to bottom of `src/server/init.server.luau` (before the final print):

```lua
-- Periodic bed readiness check and data sync
task.spawn(function()
    while true do
        task.wait(5)
        for _, player in Players:GetPlayers() do
            local data = PlayerDataManager.getData(player)
            if data then
                local changed = false
                for i = 1, data.garden.bedCount do
                    if GardenManager.isBedReady(data, i) then
                        changed = true
                    end
                end
                if changed then
                    syncData(player)
                end
            end
        end
    end
end)
```

- [ ] **Step 2: Test — plant a seed and verify it becomes harvestable after growth time without player action**

Expected: After the growth timer elapses, the bed UI updates to "Harvest!" automatically.

- [ ] **Step 3: Commit**

```bash
git add src/server/init.server.luau
git commit -m "feat: add server-side growth timer refresh loop for automatic bed readiness detection"
```

---

## Task 18: End-to-End Playtest & Polish

**Files:**
- No new files — testing and fixing only

- [ ] **Step 1: Full playtest in Roblox Studio (local server + 2 clients)**

Start a local server test with 2 players. Test the complete flow:

1. Player spawns → data loads → HUD visible
2. Plant seed in bed → bed shows "Growing..."
3. Water bed → growth time reduces
4. Wait for growth → bed shows "Harvest!"
5. Harvest → drop animation plays, brainrot added to collection
6. Open Collection Book → brainrot visible with count
7. Plant again → get duplicate → sell duplicate for Seeds
8. Accumulate Seeds → upgrade garden → new bed appears
9. Check leaderboard → collection count visible
10. Claim daily reward → Seeds increase
11. Open shop → all items listed

- [ ] **Step 2: Fix any bugs found during playtest**

Address issues as found. Common issues to check:
- Remote event throttling (Roblox limits)
- UI overlapping on mobile aspect ratios
- Data not persisting between sessions (expected for MVP — in-memory only)

- [ ] **Step 3: Commit all fixes**

```bash
git add -A
git commit -m "fix: address issues found during end-to-end playtest"
```

---

## Summary

| Task | Description | Est. Steps |
|------|-------------|------------|
| 1 | Project scaffolding & Rojo | 6 |
| 2 | Config & BrainrotDatabase | 7 |
| 3 | Drop System | 5 |
| 4 | Player Data Manager | 5 |
| 5 | Garden Manager | 5 |
| 6 | Monetization Manager | 2 |
| 7 | Daily Reward Manager | 5 |
| 8 | Server Remote Handlers | 3 |
| 9 | Client HUD | 4 |
| 10 | Garden UI | 4 |
| 11 | Drop Animation | 4 |
| 12 | Collection Book | 4 |
| 13 | Shop UI | 4 |
| 14 | Daily Rewards UI | 4 |
| 15 | Leaderboard UI | 4 |
| 16 | Final Client Assembly | 3 |
| 17 | Growth Timer Loop | 3 |
| 18 | End-to-End Playtest | 3 |
| **Total** | | **75 steps** |

**Dependencies:** Tasks 1-2 first (foundation). Tasks 3-7 (server logic, can be parallelized after 1-2). Tasks 9-15 (client UI, can be parallelized after 8). Task 16 assembles client. Task 17-18 are final integration.
