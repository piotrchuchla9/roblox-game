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
Config.BED_UPGRADE_COST = 500
Config.WATER_SPEED_MULTIPLIER = 0.5
Config.WATER_COOLDOWN = 10 -- seconds between watering same bed

-- Free seed spawn
Config.FREE_SEED_INTERVAL = 60
Config.FREE_SEED_RARITY = "Common"

-- Gamepasses (Roblox asset IDs — placeholder, replace with real IDs)
Config.GAMEPASSES = {
	VIP_GARDENER = { id = 0, price = 199, extraBeds = 2 },
	AUTO_HARVEST = { id = 0, price = 149 },
	DOUBLE_COLLECTION = { id = 0, price = 99 },
}

Config.GAMEPASS_PRICES = {
	VIP_GARDENER = 199,
	AUTO_HARVEST = 149,
	DOUBLE_COLLECTION = 99,
}

-- Developer Products (Roblox asset IDs — placeholder)
Config.DEV_PRODUCTS = {
	GOLDEN_SEED_PACK = { id = 0, price = 49, amount = 5 },
	MEGA_FERTILIZER = { id = 0, price = 29, amount = 10 },
}

-- Daily Rewards
Config.DAILY_REWARD_BASE = 50
Config.DAILY_REWARD_STREAK_BONUS = 10
Config.DAILY_REWARD_MAX_STREAK = 7
Config.DAILY_REWARD_COOLDOWN = 72000 -- 20 hours

-- Leaderboard
Config.LEADERBOARD_UPDATE_INTERVAL = 60

-- Multiplayer / Plots
Config.MAX_PLAYERS_PER_SERVER = 8
Config.PLOT_COUNT = 8
Config.PLOT_SIZE = 20 -- studs per side
Config.PLOT_RING_RADIUS = 65 -- studs from center to plot ring
Config.PLOT_FADE_TIME = 10 -- seconds for plot fade out on leave

-- Trading
Config.TRADE_TIMEOUT = 15 -- seconds to confirm
Config.TRADE_MAX_ITEMS = 6 -- max brainrots per side
Config.TRADE_PROXIMITY = 8 -- studs range for ProximityPrompt

-- Social
Config.LIKE_COOLDOWN = 86400 -- 24 hours between likes per player pair

-- Island
Config.ISLAND_RADIUS = 90 -- studs
Config.HUB_RADIUS = 40 -- studs

-- Deco Shop
Config.DECO_ITEMS = {
	{ id = "flower_pink", name = "Pink Flowers", icon = "\u{1F338}", price = 50, category = "Flowers" },
	{ id = "flower_blue", name = "Blue Flowers", icon = "\u{1F4AE}", price = 50, category = "Flowers" },
	{ id = "flower_yellow", name = "Sunflower", icon = "\u{1F33B}", price = 75, category = "Flowers" },
	{ id = "fence_white", name = "White Picket Fence", icon = "\u{1F3E1}", price = 200, category = "Fences" },
	{ id = "fence_bamboo", name = "Bamboo Fence", icon = "\u{1F38D}", price = 300, category = "Fences" },
	{ id = "lamp_garden", name = "Garden Lamp", icon = "\u{1F4A1}", price = 350, category = "Lighting" },
	{ id = "lamp_fairy", name = "Fairy Lights", icon = "\u{2728}", price = 500, category = "Lighting" },
	{ id = "statue_gnome", name = "Garden Gnome", icon = "\u{1F9D9}", price = 1000, category = "Statues" },
	{ id = "statue_fountain", name = "Mini Fountain", icon = "\u{26F2}", price = 1500, category = "Statues" },
}

-- Shop ProximityPrompt
Config.SHOP_PROMPT_DISTANCE = 10

return Config
