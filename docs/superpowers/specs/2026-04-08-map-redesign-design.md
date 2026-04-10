# Map Redesign: Compact 8-Plot Island with Shop Buildings

## Overview

Zmniejszenie mapy z 30-plotowej wyspy do kompaktowej 8-plotowej z centralną strefą handlową. Sklepy (Shop i Deco Shop) dostępne wyłącznie przez ProximityPrompt na budynkach — usunięte z HUD.

## Map Layout

### Island

- `ISLAND_RADIUS`: 150 → 90 studs
- Okrągła wyspa z trawą, proceduralnym terrain (jak obecny, ale mniejszy)
- Woda dookoła (bez zmian w mechanice)

### Plot Ring

- `PLOT_RING_RADIUS`: 110 → 65 studs od centrum
- 8 plotów rozmieszczonych równomiernie co 45° (360° / 8)
- `PLOT_SIZE`: 20 studs (bez zmian)
- Kamienne ścieżki od centrum do każdego plotu (8 zamiast 30)

### Central Hub

Centrum wyspy (~45 studs radius, zachowane):

- **Fontanna** (środek) — bez zmian
- **Shop** (budynek różowy) — repozycjonowany bliżej centrum
- **Deco Shop** (nowy budynek, zielony/drewniany) — naprzeciwko Shopa
- **Spawn** — przy fontannie (0, 2.5, -25) — dostosowany do mniejszej wyspy
- **Leaderboard** — zachowany, repozycjonowany
- Ławki (zmniejszone z 4 do 2)

### Environment Decorations (proporcjonalnie zmniejszone)

- Balony: 6 → 3
- Lampy: 6 → 4
- Drzewa: 40 → 15 (zakres 30-80 studs)
- Kwiaty: 60 → 20 (zakres 10-80 studs)

## Shop System

### ProximityPrompt Interaction

Oba budynki mają `ProximityPrompt`:

- **Shop budynek**: `MaxActivationDistance = 10`, `ActionText = "Shop"`, `ObjectText = ""`
- **Deco Shop budynek**: `MaxActivationDistance = 10`, `ActionText = "Deco Shop"`, `ObjectText = ""`

Gdy gracz aktywuje prompt → otwiera się odpowiedni UI (ShopUI lub DecoShopUI).

### Shop (istniejący, przerobiony trigger)

Zawartość bez zmian:
- Gamepassy: VIP Gardener (199R$), Auto-Harvest (149R$), Double Collection (99R$)
- Dev Products: Golden Seed Pack (49R$), Mega Fertilizer (29R$)

Zmiana: usunięta zakładka "Shop" z HUD. UI otwierany wyłącznie przez ProximityPrompt na budynku.

### Deco Shop (nowy)

UI wzorowany na ShopUI. Sprzedaje dekoracje za seeds (waluta in-game). Kupione dekoracje lądują w `backpack` gracza. Umieszczanie dekoracji — istniejący flow przez przycisk Backpack w HUD (bez zmian).

Asortyment dekoracji: do zdefiniowania w Config (oddzielna tabela `DECO_ITEMS`). Minimalna początkowa oferta:
- Kwiaty (różne kolory) — tanie (50-100 seeds)
- Płotki ozdobne — średnie (200-500 seeds)  
- Lampki — średnie (300-500 seeds)
- Figurki/posągi — drogie (1000+ seeds)

## HUD Changes

### Usunięte zakładki

- Zakładka "Shop" — usunięta z HUD
- Zakładka "Deco" (jeśli istnieje) — usunięta z HUD

### Zachowane bez zmian

- Backpack (przycisk + panel)
- Garden (zarządzanie łóżkami)
- Collection
- Social
- Daily Reward
- Free Seed timer

## Config Changes

```
MAX_PLAYERS_PER_SERVER: 30 → 8
PLOT_RING_RADIUS: 110 → 65
ISLAND_RADIUS: 150 → 90
PLOT_COUNT: 30 → 8 (nowa stała)
```

## Server Changes

### MapSetup.luau

- Zmniejszony `ISLAND_RADIUS` (90)
- 8 ścieżek zamiast 30
- Repozycjonowane budynki (Shop + nowy Deco Shop)
- Zmniejszone dekoracje środowiskowe
- ProximityPrompt na obu budynkach
- Deco Shop budynek (nowy): ~14x10x12, zielony/drewniany styl, z napisem "DECO SHOP"

### PlotManager.luau

- Sloty 0-7 zamiast 0-29
- `PLOT_RING_RADIUS` z Config (65)
- Pozycje plotów: co 45° zamiast co 12°
- Reszta logiki bez zmian (allocate/release/buildBeds/fence/nameplate)

### init.server.luau

- Nowy RemoteEvent: `OpenDecoShop` (serwer → klient, triggerowany przez ProximityPrompt)
- Nowy RemoteEvent: `OpenShop` (serwer → klient, triggerowany przez ProximityPrompt)
- Handler ProximityPrompt na budynkach → fire odpowiedni remote do gracza

## Client Changes

### ShopUI.luau

- Usunięta zakładka/tab z HUD
- `toggle()` wywoływane przez remote `OpenShop` zamiast przez klik w HUD
- Reszta UI bez zmian

### DecoShopUI.luau (nowy)

- Nowy moduł kliencki
- Otwierany przez remote `OpenDecoShop`
- Wyświetla listę dekoracji z Config.DECO_ITEMS
- Każdy item: ikona/emoji, nazwa, cena w seeds, przycisk "Buy"
- Klik "Buy" → fire `BuyDeco` remote → serwer sprawdza walutę, dodaje do backpack
- Styl UI spójny z ShopUI

### HUD (init.client.luau lub odpowiednik)

- Usunięty przycisk/zakładka "Shop"
- Usunięty przycisk/zakładka "Deco" (jeśli istnieje)

## New Remote Events

- `OpenShop` — serwer → klient (trigger UI)
- `OpenDecoShop` — serwer → klient (trigger UI)
- `BuyDeco` — klient → serwer (zakup dekoracji: decoId)

## Data Changes

Żadne zmiany w PlayerDataManager. Istniejące pola wystarczą:
- `backpack` — przechowuje kupione dekoracje
- `placedDecorations` — przechowuje umieszczone dekoracje
- `currencies.seeds` — waluta do zakupu dekoracji

## Out of Scope

- Zmiana systemu dekorowania (backpack flow)
- Zmiana systemu handlu (trade)
- Zmiana ekonomii (ceny nasion, growth times)
- Zmiana GardenUI
- Nowe gamepassy czy dev products
