# Grow a Brainrot — Game Design Spec

## Overview

"Grow a Brainrot" is a Roblox farming/collecting simulator where players plant seeds, grow absurd internet meme creatures ("brainrots"), and collect them. The game combines the proven "grow & collect" loop (inspired by Grow a Garden's massive success — 21B visits in 2026) with brainrot meme culture that dominates TikTok.

**Target audience:** Gen Alpha / young Gen Z (8-16 years old)
**Platform focus:** Mobile-first (80% of Roblox players)
**Monetization model:** Gamepasses + Developer Products + Season Pass
**Virality:** Built-in TikTok moments (rare drops, chaotic gardens, absurd animations)

---

## 1. Core Loop

The main gameplay loop is short (1-3 minutes per cycle), optimized for mobile:

1. **Get a seed** — from free spawn, shop, or premium purchase
2. **Plant in garden** — each player has a personal plot with limited beds (4 base, expandable to 8)
3. **Wait + tend** — brainrot grows in real time. Growth time scales with seed rarity: Common 30s, Uncommon 1min, Rare 2min, Epic 3min, Legendary 4min, Mythic 5min. Watering/fertilizing speeds growth by 50%
4. **Harvest brainrot** — random result from rarity pool:
   - Common (50%) — e.g. "Skibidi Toilet Basic"
   - Uncommon (25%) — e.g. "Italian Brainrot Cappuccino"
   - Rare (15%) — e.g. "Bombardiro Crocodilo"
   - Epic (7%) — e.g. "Tung Tung Sahur"
   - Legendary (2.5%) — e.g. "Tralalero Tralala Gold"
   - Mythic (0.5%) — seasonal, limited
5. **Collect or sell** — brainrots go to collection index. Duplicates sold for in-game currency
6. **Upgrade garden** — more beds, better tools, faster growth, better rare chances

---

## 2. Season System

### Structure
- **Season duration:** 2-4 weeks
- Each season adds **8-12 new brainrots** tied to current trends
- New **themed biome/map** (e.g. "Italian Brainrot Garden" with fountain and pizza)
- **Season Pass** (free + premium track) with collection rewards
- After season ends — seasonal brainrots become **unobtainable** (FOMO + collector value)

### Example Seasons
- Season 1 (launch): "OG Brainrot" — Skibidi, Italian Brainrot, Bombardiro, classics
- Season 2: "Anime Brainrot" — meme anime characters, crossover trends
- Season 3: "Music Brainrot" — based on viral TikTok sounds
- Season 4+: adapted to whatever is currently trending on TikTok

### Trend Radar Mechanic
- In-game billboard showing "current weekly trend"
- Special weekly brainrot with boosted drop rate — reason to log in daily
- Natural TikTok content: "new weekly brainrot just dropped!"

### FOMO Engine
- Limited brainrots = players MUST play during season
- Collectors want 100% index completion
- Trading old seasonal brainrots builds player economy

---

## 3. Monetization

### Currencies
- **Seeds** (free) — earned from gameplay, selling duplicates, daily rewards
- **Golden Seeds** (premium) — purchased with Robux, access premium seeds and boosts

### Gamepasses (one-time purchase)

| Gamepass | Price | Benefit |
|----------|-------|---------|
| VIP Gardener | 199 Robux | +2 beds, golden watering can, VIP badge |
| Auto-Harvest | 149 Robux | Auto-collect ready brainrots |
| Lucky Gardener | 249 Robux | +10% multiplicative boost to Rare+ drop chances (e.g. Rare: 15% → 16.5%) |
| Double Collection | 99 Robux | 2x Seeds from selling duplicates |

### Developer Products (repeatable)
- **Golden Seed Pack** (5x) — 49 Robux
- **Mega Fertilizer** (instant grow x10) — 29 Robux
- **Reroll Token** (reroll drop result) — 19 Robux

### Season Pass Premium
- **Free track:** small reward every 5 levels (Seeds, basic seed)
- **Premium track (99 Robux/season):** exclusive brainrots, unique garden decorations, Golden Seeds, Mythic seed at end

### Garden Cosmetics
- Plot decorations (fences, paths, fountains) — 25-99 Robux
- Tool skins (watering can, rake) — 49 Robux
- Harvest effects (animations, particles on collect) — 39 Robux

### Pricing Strategy
- Main gamepasses in 99-249 Robux range (sweet spot for young players)
- Season Pass at 99 Robux = low barrier with recurring revenue each season

---

## 4. Social Systems & Virality

### Trading
- Players can trade brainrots with each other
- Rarity + closed seasons = natural economy (old Mythics gain value)
- Trade plaza — dedicated map area for trading

### TikTok Virality — Built-in Mechanisms

#### "OMG Moments"
- Legendary/Mythic drops trigger fullscreen animation with effects, sound, screenshake
- Dynamic on-screen text per rarity: Legendary shows "1 in 40 chance!", Mythic shows "1 in 200 chance!"
- Perfect clip moment — players organically post to TikTok

#### Leaderboards & Flexing
- Global collection ranking — who has the most uniques
- "Garden Tour" — visit and rate other players' gardens
- Best gardens showcased on server

#### Invite Mechanics
- "Friendship Garden" — shared plot with a friend, drop bonus
- Referral code: invite 3 friends = free Rare seed
- Group harvesting: harvest together and compare results

#### Brainrot Culture Elements
- Collected brainrots walk around the garden with absurd animations and sounds
- Random interactions between brainrots (Bombardiro fights Tralalero)
- More brainrots on plot = more chaos = funnier clips

---

## 5. Technical Architecture

### Tooling
- **Roblox Studio** with built-in MCP Server (official, actively maintained)
- **Claude Code** connected via MCP — full control over Studio: creating objects, writing Luau scripts, managing game model
- **Git** for version control (Rojo/Argon for file-to-Studio sync)

### Project Structure

```
src/
├── server/                        -- server-side logic (Luau)
│   ├── GardenManager.luau         -- player plot management
│   ├── DropSystem.luau            -- brainrot rolling, rarity
│   ├── SeasonManager.luau         -- season rotation, available brainrots
│   ├── TradingSystem.luau         -- player-to-player trading
│   └── MonetizationManager.luau   -- gamepasses, dev products, season pass
├── client/                        -- client UI and effects
│   ├── GardenUI.luau              -- garden interface
│   ├── CollectionBook.luau        -- brainrot index
│   ├── DropAnimation.luau         -- "OMG moment" animations
│   ├── ShopUI.luau                -- shop and season pass
│   ├── DailyRewardsUI.luau        -- daily rewards screen
│   ├── LeaderboardUI.luau         -- collection leaderboard
│   └── TradingUI.luau             -- trade interface (post-MVP)
├── shared/                        -- shared definitions
│   ├── BrainrotDatabase.luau      -- all brainrot definitions
│   └── Config.luau                -- constants, prices, drop rates
└── assets/                        -- 3D models, sounds, textures
```

### Player Data Schema (DataStore)

```lua
PlayerData = {
    garden = {
        beds = {}, -- array of bed states: {seedId, plantedAt, rarity, isReady}
        bedCount = 4, -- expandable to 8
        tools = {wateringCan = "basic"} -- tool upgrades
    },
    collection = {}, -- map of brainrotId -> {count, firstObtainedAt}
    collectionCount = 0, -- unique brainrots collected
    currencies = {seeds = 0, goldenSeeds = 0},
    gamepasses = {}, -- set of owned gamepass IDs
    dailyReward = {lastClaimed = 0, streak = 0},
    stats = {totalHarvested = 0, totalSold = 0}
}
```

### Key Technical Decisions
- **ProfileService** for saving player data (session locking, auto-save on key events + background interval every 5min, handles rate limits gracefully)
- **MessagingService** for global events (new season, special drops)
- **Server-side drop system** — no cheating, all rolling on server
- **Modular brainrot system** — adding new one = entry in BrainrotDatabase + 3D model
- **Trade security** — all trades validated server-side, confirmation UI with 5s countdown, trade logging for abuse detection
- **Content moderation** — all brainrot names, animations, and sounds reviewed for Roblox Community Standards compliance before each season launch
- **Server config** — max 30 players per server, instanced personal gardens, shared hub area for trading/social

---

## 6. MVP Scope (First Release)

### Included in MVP
- 1 map/biome
- 10-15 brainrots in 6 rarity tiers
- Basic garden (4 beds, expandable to 8)
- 3 gamepasses (VIP Gardener, Auto-Harvest, Double Collection) + 2 developer products (Golden Seed Pack, Mega Fertilizer). Lucky Gardener gamepass and Reroll Token deferred to Update 1
- Collection/index
- "OMG moment" drop animation
- Basic daily rewards
- Leaderboard (collection count)

### Post-MVP (Update 1)
- Trading system + trade plaza
- Season Pass (free + premium)
- Friendship Garden
- Garden cosmetics shop
- Garden Tour feature

### Post-MVP (Update 2+)
- Season 2 with new biome and brainrots
- Referral/invite system
- Brainrot interactions/animations
- Rewarded Video Ads integration (13+ players)
