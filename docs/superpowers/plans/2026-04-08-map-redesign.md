# Map Redesign: Compact 8-Plot Island Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Zmniejszyć mapę do 8 ogrodów na pierścieniu, dodać Deco Shop budynek, przenieść Shop/Deco do ProximityPrompt na budynkach (usunąć z HUD).

**Architecture:** Config-driven zmiany (radius, plot count), przebudowa MapSetup na mniejszą wyspę z 2 budynkami + ProximityPrompt, usunięcie zakładki Shop z HUD, nowy DecoShopUI otwierany przez remote.

**Tech Stack:** Roblox Luau, DataStoreService, ProximityPrompt, RemoteEvents

---

## File Structure

| Action | File | Responsibility |
|--------|------|---------------|
| Modify | `src/shared/Config.luau` | Nowe stałe: PLOT_COUNT=8, zmniejszone radiusy, DECO_ITEMS |
| Modify | `src/shared/Remotes.luau` | Nowe remoty: OpenShop, OpenDecoShop, BuyDeco |
| Modify | `src/server/MapSetup.luau` | Mniejsza wyspa, 8 ścieżek, 8 plotów, Deco Shop budynek, ProximityPrompts |
| Modify | `src/server/PlotManager.luau` | Sloty 0-7 zamiast 0-29 |
| Modify | `src/server/init.server.luau` | Handler ProximityPrompt → fire OpenShop/OpenDecoShop, handler BuyDeco |
| Create | `src/client/DecoShopUI.luau` | UI sklepu dekoracji (wzorowany na ShopUI) |
| Modify | `src/client/ShopUI.luau` | toggle() wywoływane przez remote zamiast HUD |
| Modify | `src/client/HUD.luau` | Usunięta zakładka "Shop" z TabBar |
| Modify | `src/client/init.client.luau` | Usunięty wireTab("Shop"), dodany listener OpenShop/OpenDecoShop |

---

### Task 1: Config — zmniejszona mapa i DECO_ITEMS

**Files:**
- Modify: `src/shared/Config.luau`

- [ ] **Step 1: Zaktualizuj stałe mapy i dodaj DECO_ITEMS**

W `src/shared/Config.luau`, zmień sekcję "Multiplayer / Plots":

```lua
-- Multiplayer / Plots
Config.MAX_PLAYERS_PER_SERVER = 8
Config.PLOT_COUNT = 8
Config.PLOT_SIZE = 20 -- studs per side
Config.PLOT_RING_RADIUS = 65 -- studs from center to plot ring
Config.PLOT_FADE_TIME = 10 -- seconds for plot fade out on leave

-- Island
Config.ISLAND_RADIUS = 90 -- studs
Config.HUB_RADIUS = 40 -- studs
```

I dodaj na końcu (przed `return Config`):

```lua
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
```

- [ ] **Step 2: Commit**

```bash
git add src/shared/Config.luau
git commit -m "feat: update Config for 8-plot island and add DECO_ITEMS"
```

---

### Task 2: Remotes — nowe eventy

**Files:**
- Modify: `src/shared/Remotes.luau`

- [ ] **Step 1: Dodaj nowe remoty**

W `src/shared/Remotes.luau`, dodaj w sekcji Server -> Client:

```lua
	OpenShop = "OpenShop",
	OpenDecoShop = "OpenDecoShop",
```

I w sekcji Client -> Server (po LikeGarden):

```lua
	BuyDeco = "BuyDeco",
```

- [ ] **Step 2: Commit**

```bash
git add src/shared/Remotes.luau
git commit -m "feat: add OpenShop, OpenDecoShop, BuyDeco remotes"
```

---

### Task 3: MapSetup — mniejsza wyspa z Deco Shop

**Files:**
- Modify: `src/server/MapSetup.luau`

- [ ] **Step 1: Zmień ISLAND_RADIUS i terrain**

W `MapSetup.build()`, zmień:

```lua
local ISLAND_RADIUS = Config.ISLAND_RADIUS -- 90 (was 150)
```

Dodaj na górze pliku:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
```

- [ ] **Step 2: Zmień ścieżki kamienne z 30 na 8**

Zamień blok stone paths:

```lua
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
```

- [ ] **Step 3: Dodaj budynek Deco Shop naprzeciwko Shop**

Po bloku Shop (shopSign parent), dodaj Deco Shop:

```lua
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
```

- [ ] **Step 4: Dodaj ProximityPrompt na oba budynki**

Po obu budynkach (Shop i Deco Shop):

```lua
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
```

- [ ] **Step 5: Przenieś Leaderboard (był na -25,7,0 — teraz tam Deco Shop)**

Zamień pozycję Leaderboard na np. (0, 7, 25) — za fontanną:

```lua
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
```

- [ ] **Step 6: Zmień plot markers z 30 na 8**

Zamień pętlę plot markers:

```lua
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
```

- [ ] **Step 7: Zmniejsz dekoracje środowiskowe**

Zmień ilości: drzewa 40→15 (zakres 30-80), kwiaty 60→20 (zakres 10-80), balony 6→3, lampy 6→4. W pętli drzew zmień collision check na 8 plotów:

```lua
	-- Trees (reduced)
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
		-- Also avoid hub buildings
		if (tx^2 + tz^2) < Config.HUB_RADIUS^2 then
			tooClose = true
		end
		if not tooClose then
			makeTree(Vector3.new(tx, 2, tz), decoFolder)
		end
	end

	-- Flowers (reduced)
	for i = 1, 20 do
		local angle = math.random() * math.pi * 2
		local dist = 10 + math.random() * 70
		makeFlower(Vector3.new(math.cos(angle) * dist + math.random(-3, 3), 2, math.sin(angle) * dist + math.random(-3, 3)), decoFolder)
	end
```

Balony:
```lua
	for i = 1, 3 do
		local angle = (i / 3) * math.pi * 2
		makeBalloon(Vector3.new(math.cos(angle) * 25, 2.5, math.sin(angle) * 25), decoFolder)
	end
```

Lampy:
```lua
	for i = 0, 3 do
		local angle = (i / 4) * math.pi * 2
		local lx = math.cos(angle) * 30
		local lz = math.sin(angle) * 30
		-- (rest unchanged)
	end
```

- [ ] **Step 8: Usuń TrendRadar (opcjonalnie) lub przenieś**

Przenieś TrendRadar za Leaderboard lub usuń — zdecyduj na podstawie dostępnego miejsca. Przesuń na (0, 8, 38):

```lua
	local billboard = makePart({
		name = "TrendRadar", size = Vector3.new(14, 8, 1),
		position = Vector3.new(0, 8, 38),
		color = Color3.fromRGB(255, 245, 186), parent = hubFolder,
	})
	makePart({ name = "TrendPost1", size = Vector3.new(1, 12, 1), position = Vector3.new(-6, 6, 38), color = Color3.fromRGB(139, 90, 43), material = Enum.Material.Wood, parent = hubFolder })
	makePart({ name = "TrendPost2", size = Vector3.new(1, 12, 1), position = Vector3.new(6, 6, 38), color = Color3.fromRGB(139, 90, 43), material = Enum.Material.Wood, parent = hubFolder })
```

- [ ] **Step 9: Zmniejsz ławki z 4 na 2**

```lua
	for i = 0, 1 do
		local angle = (i / 2) * math.pi * 2 + math.pi / 4
		local bx = math.cos(angle) * 18
		local bz = math.sin(angle) * 18
		makePart({ name = "Bench" .. i, size = Vector3.new(4, 1.5, 1.5), position = Vector3.new(bx, 3, bz), color = Color3.fromRGB(139, 90, 43), material = Enum.Material.Wood, parent = hubFolder })
	end
```

- [ ] **Step 10: Dodaj MapSetup.getShopPart() i MapSetup.getDecoShopPart()**

Na końcu modułu, przed `return MapSetup`, dodaj helper do pobrania budynków (potrzebne w init.server do podłączenia ProximityPrompt events):

```lua
function MapSetup.getShopPart(): Part?
	local hub = Workspace:FindFirstChild("Hub")
	return hub and hub:FindFirstChild("ShopBuilding")
end

function MapSetup.getDecoShopPart(): Part?
	local hub = Workspace:FindFirstChild("Hub")
	return hub and hub:FindFirstChild("DecoShopBuilding")
end
```

- [ ] **Step 11: Commit**

```bash
git add src/server/MapSetup.luau
git commit -m "feat: rebuild MapSetup for compact 8-plot island with Deco Shop"
```

---

### Task 4: PlotManager — 8 slotów

**Files:**
- Modify: `src/server/PlotManager.luau`

- [ ] **Step 1: Zmień inicjalizację slotów z MAX_PLAYERS na PLOT_COUNT**

Zamień:

```lua
for i = 0, Config.MAX_PLAYERS_PER_SERVER - 1 do
	plotSlots[i] = nil
end
```

Na:

```lua
for i = 0, Config.PLOT_COUNT - 1 do
	plotSlots[i] = nil
end
```

- [ ] **Step 2: Zmień pętlę allocate**

Zamień w `PlotManager.allocate`:

```lua
for i = 0, Config.MAX_PLAYERS_PER_SERVER - 1 do
```

Na:

```lua
for i = 0, Config.PLOT_COUNT - 1 do
```

- [ ] **Step 3: Commit**

```bash
git add src/server/PlotManager.luau
git commit -m "feat: PlotManager uses PLOT_COUNT (8) instead of MAX_PLAYERS (30)"
```

---

### Task 5: Server init — ProximityPrompt handlers i BuyDeco

**Files:**
- Modify: `src/server/init.server.luau`

- [ ] **Step 1: Dodaj ProximityPrompt handlers po MapSetup.build()**

W sekcji `task.spawn(function() MapSetup.build() ...)`, po `print("[Server] Map built")`, dodaj podłączenie ProximityPrompt:

```lua
task.spawn(function()
	MapSetup.build()
	print("[Server] Map built")

	-- Wire shop ProximityPrompts
	local shopPart = MapSetup.getShopPart()
	if shopPart then
		local prompt = shopPart:FindFirstChild("ShopPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				remotesFolder.OpenShop:FireClient(player)
			end)
		end
	end

	local decoPart = MapSetup.getDecoShopPart()
	if decoPart then
		local prompt = decoPart:FindFirstChild("DecoShopPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				remotesFolder.OpenDecoShop:FireClient(player)
			end)
		end
	end
end)
```

- [ ] **Step 2: Dodaj BuyDeco handler**

Po bloku `LikeGarden`, dodaj:

```lua
-- Buy decoration
remotesFolder.BuyDeco.OnServerEvent:Connect(function(player, decoId: string)
	local data = PlayerDataManager.getData(player)
	if not data then return end

	-- Find deco in Config
	local decoItem = nil
	for _, item in Config.DECO_ITEMS do
		if item.id == decoId then
			decoItem = item
			break
		end
	end
	if not decoItem then return end

	-- Check and spend currency
	if not PlayerDataManager.spendCurrency(data, "seeds", decoItem.price) then return end

	-- Add to backpack
	table.insert(data.backpack, {
		id = decoItem.id,
		name = decoItem.name,
		obtainedAt = os.time(),
	})

	syncData(player)
end)
```

- [ ] **Step 3: Commit**

```bash
git add src/server/init.server.luau
git commit -m "feat: add ProximityPrompt shop handlers and BuyDeco endpoint"
```

---

### Task 6: DecoShopUI — nowy moduł kliencki

**Files:**
- Create: `src/client/DecoShopUI.luau`

- [ ] **Step 1: Utwórz DecoShopUI**

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(script.Parent.UITheme)

local DecoShopUI = {}

local panel = nil
local visible = false

function DecoShopUI.create()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

	panel = UITheme.createPanel(playerGui, {
		name = "DecoShopUI",
		title = "\u{1F3E1} DECO SHOP",
		onClose = function()
			DecoShopUI.hide()
		end,
	})

	local contentScroll = panel.contentScroll
	local layoutOrder = 1

	-- Group by category
	local categories = {}
	local categoryOrder = {}
	for _, item in Config.DECO_ITEMS do
		if not categories[item.category] then
			categories[item.category] = {}
			table.insert(categoryOrder, item.category)
		end
		table.insert(categories[item.category], item)
	end

	for _, category in categoryOrder do
		local divider = UITheme.createSectionDivider(contentScroll, {
			text = string.upper(category),
			color = UITheme.BTN_GREEN,
		})
		divider.LayoutOrder = layoutOrder
		layoutOrder += 1

		for _, item in categories[category] do
			local listItem = UITheme.createListItem(contentScroll, {
				borderColor = UITheme.BTN_GREEN,
				icon = item.icon,
				height = 48,
			})
			listItem.frame.LayoutOrder = layoutOrder
			layoutOrder += 1

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, 0, 1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = item.name
			nameLabel.TextColor3 = UITheme.TEXT_PRIMARY
			nameLabel.TextSize = 13
			nameLabel.Font = UITheme.FONT_BOLD
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = listItem.infoFrame

			local priceBtn = UITheme.createActionButton(listItem.actionFrame, {
				text = item.price .. " \u{1F331}",
				color = UITheme.BTN_GREEN,
				textColor = UITheme.TEXT_ON_BTN,
				size = UDim2.new(0, 68, 0, 28),
			})
			priceBtn.MouseButton1Click:Connect(function()
				remotesFolder.BuyDeco:FireServer(item.id)
			end)
		end
	end
end

function DecoShopUI.show()
	if not visible then
		visible = true
		UITheme.tweenOpen(panel.screenGui)
	end
end

function DecoShopUI.hide()
	if visible then
		visible = false
		UITheme.tweenClose(panel.screenGui)
	end
end

return DecoShopUI
```

- [ ] **Step 2: Commit**

```bash
git add src/client/DecoShopUI.luau
git commit -m "feat: add DecoShopUI for buying decorations with seeds"
```

---

### Task 7: ShopUI — zmień toggle na show/hide

**Files:**
- Modify: `src/client/ShopUI.luau`

- [ ] **Step 1: Dodaj show() i hide() obok toggle()**

Na końcu `src/client/ShopUI.luau` (przed `return ShopUI`), dodaj:

```lua
function ShopUI.show()
	if not visible then
		visible = true
		UITheme.tweenOpen(panel.screenGui)
	end
end

function ShopUI.hide()
	if visible then
		visible = false
		UITheme.tweenClose(panel.screenGui)
	end
end
```

`toggle()` zostaje bez zmian (używa go onClose w panelu).

- [ ] **Step 2: Commit**

```bash
git add src/client/ShopUI.luau
git commit -m "feat: add ShopUI.show/hide for ProximityPrompt trigger"
```

---

### Task 8: HUD — usuń zakładkę Shop

**Files:**
- Modify: `src/client/HUD.luau`

- [ ] **Step 1: Usuń Shop z tablicy tabs**

W `src/client/HUD.luau`, w tablicy `tabs` (linia ~163), usuń wpis:

```lua
		{ name = "Shop", icon = "\u{1F6D2}", order = 2, color = UITheme.BTN_PINK, shadow = UITheme.BTN_PINK_SHADOW },
```

Zaktualizuj `order` pozostałych zakładek żeby nie było dziury:

```lua
	local tabs = {
		{ name = "Garden", icon = "\u{1F331}", order = 1, color = UITheme.BTN_GREEN, shadow = UITheme.BTN_GREEN_SHADOW },
		{ name = "Collection", icon = "\u{1F4D6}", order = 2, color = UITheme.BTN_ORANGE, shadow = UITheme.BTN_ORANGE_SHADOW, center = true },
		{ name = "Daily", icon = "\u{1F381}", order = 3, color = UITheme.BTN_BLUE, shadow = UITheme.BTN_BLUE_SHADOW },
		{ name = "FreeSeed", icon = "\u{1F31F}", order = 4, color = UITheme.BTN_GREEN, shadow = UITheme.BTN_GREEN_SHADOW },
		{ name = "Social", icon = "\u{1F465}", order = 5, color = UITheme.BTN_BLUE, shadow = UITheme.BTN_BLUE_SHADOW },
	}
```

- [ ] **Step 2: Commit**

```bash
git add src/client/HUD.luau
git commit -m "feat: remove Shop tab from HUD (now via ProximityPrompt)"
```

---

### Task 9: Client init — podłącz remoty do Shop/DecoShop

**Files:**
- Modify: `src/client/init.client.luau`

- [ ] **Step 1: Dodaj require DecoShopUI**

Na górze, po `local ShopUI = require(script.ShopUI)`, dodaj:

```lua
local DecoShopUI = require(script.DecoShopUI)
```

- [ ] **Step 2: Dodaj DecoShopUI.create() do inicjalizacji**

Po `ShopUI.create()`:

```lua
DecoShopUI.create()
```

- [ ] **Step 3: Usuń wireTab("Shop")**

Usuń blok:

```lua
wireTab("Shop", function()
	ShopUI.toggle()
end)
```

- [ ] **Step 4: Dodaj listenery na OpenShop i OpenDecoShop**

Po bloku trade ProximityPrompt (przed końcowym `print`):

```lua
-- Shop via ProximityPrompt
remotesFolder.OpenShop.OnClientEvent:Connect(function()
	ShopUI.show()
end)

remotesFolder.OpenDecoShop.OnClientEvent:Connect(function()
	DecoShopUI.show()
end)
```

- [ ] **Step 5: Commit**

```bash
git add src/client/init.client.luau
git commit -m "feat: wire OpenShop/OpenDecoShop remotes to ShopUI/DecoShopUI"
```

---

### Task 10: Sync do Studio i test

**Files:**
- Wszystkie zmienione pliki

- [ ] **Step 1: Zsynchronizuj zmienione pliki do Studio**

Użyj `run_code` MCP do zaktualizowania Source każdego zmienionego ModuleScript w Studio. Pliki do synchronizacji:
1. `ReplicatedStorage.Shared.Config`
2. `ReplicatedStorage.Shared.Remotes`
3. `ServerScriptService.Server.MapSetup`
4. `ServerScriptService.Server.PlotManager`
5. `ServerScriptService.Server.init` (Script, nie ModuleScript)
6. `PlayerGui` — DecoShopUI (nowy moduł w StarterPlayerScripts/Client)
7. `ShopUI`, `HUD`, `init.client`

- [ ] **Step 2: Uruchom play test w Studio**

Sprawdź:
- Mapa jest mniejsza (8 plotów na pierścieniu)
- Podejście do Shop budynku pokazuje ProximityPrompt "Shop"
- Aktywacja otwiera ShopUI
- Podejście do Deco Shop pokazuje ProximityPrompt "Deco Shop"
- Aktywacja otwiera DecoShopUI
- Kupno dekoracji odejmuje seeds i dodaje do backpack
- Brak zakładki "Shop" w HUD
- Gracz dostaje przydzielony plot

- [ ] **Step 3: Commit końcowy (jeśli potrzebne poprawki)**

```bash
git add -A
git commit -m "fix: adjustments from play testing map redesign"
```
