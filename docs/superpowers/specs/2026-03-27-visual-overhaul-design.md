# Visual Overhaul — Grow a Brainrot

**Data:** 2026-03-27
**Zakres:** Kompletna przebudowa wizualna: świat 3D, UI, multiplayer, efekty

## Decyzje projektowe

| Decyzja | Wybór |
|---------|-------|
| Kierunek wizualny | Jasny & pastelowy (kontrast z absurdalnymi brainrotami) |
| Paleta kolorów | Candy Pastel — róż, błękit, limonka, żółć, lawenda |
| Układ mapy | Okrągła wyspa — hub w centrum, działki w pierścieniu |
| Styl UI | Chunky — grube bordery, przyciski 3D, bold tekst |
| Model multiplayer | Wspólna mapa (~30 graczy), działki obok siebie, teleport cross-server |

---

## 1. Świat 3D

### 1.1 Okrągła wyspa

- Promień ~150 studs, generowana z Roblox Terrain
- Teren: trawa + delikatne pagórki
- Staw dekoracyjny z fontanną w centrum hubu
- Kamienne ścieżki promieniście od hubu do działek

### 1.2 Centrum (Hub)

- Placeholder budynki z kodu (Part-based, pastelowe kolory):
  - Sklep (różowy)
  - Leaderboard (błękitny)
  - Trend Radar billboard (żółty)
- Spawn location w hubie
- Dekoracje: ławki, latarnie, klomby kwiatów

### 1.3 Działki graczy (pierścień)

- 30 slotów w pierścieniu wokół hubu
- Każda działka: ~20x20 studs z drewnianym ogrodzeniem
- Tabliczka z nickiem (BillboardGui)
- Grządki gracza generowane na działce z PlayerData
- Alokacja dynamiczna przy PlayerAdded, zwolnienie przy PlayerRemoving (fade 10s)

### 1.4 Dekoracje proceduralne

Generowane z kodu (Part-based placeholdery):
- Drzewa: zielone kule na brązowych cylindrach (rozmieszczone losowo poza działkami)
- Kwiaty: małe kolorowe części na trawie
- Balony: kolorowe kule na nitkach (przy hubie)
- Kamienie: szare części rozmieszczone przy ścieżkach

### 1.5 Lighting & Atmosphere

```
ClockTime = 14
Brightness = 3
Ambient = (180, 170, 190)
OutdoorAmbient = (200, 195, 210)

Atmosphere:
  Density = 0.15
  Offset = 0.25
  Color = (255, 230, 240)  -- ciepły róż
  Decay = (200, 180, 210)

Bloom:
  Intensity = 0.3
  Size = 24
  Threshold = 2

ColorCorrection:
  Saturation = 0.15
  TintColor = (255, 245, 250)  -- lekki ciepły odcień

SunRays:
  Intensity = 0.1
  Spread = 0.5
```

### 1.6 Particle Effects

- **Iskierki nad stawem:** białe/złote, wolno unoszące się, Lifetime 3-5s
- **Bąbelki fontanny:** błękitne, szybkie, Lifetime 1-2s
- **Liście z drzew:** zielone/żółte, spadające, Lifetime 4-6s, drift
- **Konfetti przy harvest:** kolorowe, eksplozja radialna, Lifetime 2s
- **Iskierki na gotowej grządce:** złote, pulsujące

---

## 2. UI Redesign (Chunky Candy Pastel)

### 2.1 UITheme — nowa paleta

```
-- Tła
BG_PRIMARY = (255, 255, 255)          -- biały
BG_SECONDARY = (255, 245, 248)        -- lekki róż
BG_OVERLAY = (0, 0, 0, 0.4)           -- przyciemnione tło pod panelami

-- Akcenty
PRIMARY = (255, 181, 232)             -- #FFB5E8 róż
SECONDARY = (181, 222, 255)           -- #B5DEFF błękit
ACCENT_GREEN = (231, 255, 172)        -- #E7FFAC limonka
ACCENT_YELLOW = (255, 245, 186)       -- #FFF5BA żółć
ACCENT_LAVENDER = (220, 211, 255)     -- #DCD3FF lawenda

-- Przyciski (nasycone wersje + ciemniejszy border-bottom)
BTN_GREEN = (76, 175, 80)             -- #4CAF50
BTN_GREEN_SHADOW = (56, 142, 60)      -- #388E3C
BTN_ORANGE = (255, 152, 0)            -- #FF9800
BTN_ORANGE_SHADOW = (230, 81, 0)      -- #E65100
BTN_PINK = (233, 30, 99)              -- #E91E63
BTN_PINK_SHADOW = (173, 20, 87)       -- #AD1457

-- Tekst
TEXT_PRIMARY = (93, 64, 55)            -- #5D4037 ciemny brąz
TEXT_SECONDARY = (121, 85, 72)         -- #795548
TEXT_ON_BTN = (255, 255, 255)          -- biały

-- Styl
BORDER_WIDTH = 3                       -- grube obramowania
BORDER_BOTTOM_3D = 3                   -- efekt 3D na przyciskach
CORNER_RADIUS = 8-12                   -- umiarkowane zaokrąglenia
FONT = GothamBold
```

### 2.2 Kolory rarity (border karty)

| Rarity | Kolor | Border |
|--------|-------|--------|
| Common | `#BDBDBD` szary | 2px solid |
| Uncommon | `#4CAF50` zielony | 2px solid |
| Rare | `#2196F3` błękit | 3px solid |
| Epic | `#9C27B0` fiolet | 3px solid |
| Legendary | `#FF9800` złoty | 3px solid + glow |
| Mythic | róż→fiolet gradient | 3px + animowany pulse |

### 2.3 Moduły do przepisania

**UITheme.luau** — nowa paleta, helpery:
- `createChunkyButton(text, color, shadowColor)` → TextButton z border-bottom 3D
- `createCard(content, borderColor)` → Frame z białym tłem i kolorowym borderem
- `createPanel(title)` → fullscreen panel z białym tłem i overlayem

**HUD.luau:**
- Top bar: biały, currency pills z pastelowym borderem i ikoną
- Tab bar: biały, aktywny tab z kolorowym tłem i 3D efektem

**GardenUI.luau:**
- Białe karty grządek z progress barem w zieleni
- Przyciski: "Podlej" (zielony 3D), "Zbierz" (pomarańczowy 3D), "Zasadź" (różowy 3D)

**CollectionBook.luau:**
- Białe tło, sekcje per rarity z kolorowym nagłówkiem
- Karty brainrotów z borderem w kolorze rarity
- Nazwy bold uppercase

**ShopUI.luau:**
- Białe karty produktów z żółtym borderem
- Przycisk zakupu: zielony 3D z ceną w Robux

**DailyRewardsUI.luau:**
- Pastelowe kółka streakowe (wypełnione = kolor, puste = szary outline)
- Biały panel, kolorowe checkmarki
- Przycisk "Odbierz": pomarańczowy 3D

**DropAnimation.luau:**
- Jasny flash (biały z pastelowym tłem) zamiast ciemnego
- Konfetti z particle emittera zamiast neonowych kwadratów
- Karta brainrota z chunky borderem w kolorze rarity
- Screen shake zachowany dla Epic+

**LeaderboardUI.luau:**
- Biała lista z alternatywnym cieniowaniem wierszy
- Top 3: pastelowe podium (żółć / błękit / róż zamiast złoto / srebro / brąz)

---

## 3. Systemy społeczne

### 3.1 Dynamiczne działki

- `PlayerAdded` → `PlotManager.allocate(player)` → przypisz wolny slot z pierścienia
- Generuj fizyczny ogród na działce (grządki z PlayerData, ogrodzenie, tabliczka)
- `PlayerRemoving` → fade out działki przez 10s → `PlotManager.release(slotIndex)`
- Pula 30 slotów — jeśli pełna, gracz trafia na inny serwer (Roblox matchmaking)

### 3.2 Teleportacja

- Nowy tab UI: "Społeczność" (ikona ludzik w tab barze)
- Wyszukiwarka: TextBox z nickiem → `MessagingService` → query serwery
- Wynik: "Gracz [Nick] jest na serwerze — Teleportuj się?" → `TeleportService:TeleportToPlaceInstance()`
- HUD: przycisk "🏠 Do domu" → zapamiętany `game.JobId` → teleport powrotny
- Loading screen: pastelowy ekran z animacją rosnącego brainrota

### 3.3 Handel

- `ProximityPrompt` na postaciach graczy (zasięg 8 studs)
- Panel wymiany:
  - Lewa strona: Twoje brainroty (scrollable grid)
  - Prawa strona: brainroty drugiego gracza
  - Każdy wybiera co oddaje, widzi co dostaje
  - Przycisk "Potwierdź" (obaj muszą nacisnąć, 15s timeout)
- Walidacja server-side: sprawdź czy obaj mają oferowane brainroty
- Tylko na tym samym serwerze (brak cross-server trade w MVP)

### 3.4 Odwiedzanie ogrodów

- Wejście na cudzą działkę → toast "Odwiedzasz ogród [Nick]"
- Widok only — brak interakcji z cudzymi grządkami (przyciski nie pojawiają się)
- Przycisk "❤️ Polub ogród" → +1 do `stats.gardenLikes` gracza
- Cooldown 1 polubienie per gracz per 24h

---

## 4. Nowe pliki/moduły

| Plik | Opis |
|------|------|
| `src/server/PlotManager.luau` | Alokacja/zwalnianie działek, generowanie fizycznego ogrodu |
| `src/server/TeleportManager.luau` | Cross-server wyszukiwanie, teleportacja, loading screen |
| `src/server/TradeManager.luau` | Logika handlu, walidacja, timeout |
| `src/client/SocialUI.luau` | Tab społeczność: wyszukiwarka, panel handlu, polubienia |
| `src/client/TeleportUI.luau` | Loading screen, przycisk "Do domu" |

## 5. Zmiany w istniejących plikach

| Plik | Zmiana |
|------|--------|
| `src/shared/Types.luau` | Dodaj typy: `Plot`, `TradeOffer`, rozszerz `PlayerData` o `stats.gardenLikes` |
| `src/shared/Config.luau` | Dodaj stałe: `MAX_PLAYERS_PER_SERVER`, `PLOT_SIZE`, `TRADE_TIMEOUT` |
| `src/server/MapSetup.luau` | Przepisz: teren okrągłej wyspy, hub, ścieżki, dekoracje, lighting |
| `src/server/init.server.luau` | Dodaj init PlotManager, TeleportManager, TradeManager, PlayerAdded/Removing hooks |
| `src/client/init.client.luau` | Dodaj tab "Społeczność", przycisk "Do domu", ProximityPrompt handler |
| `src/client/UITheme.luau` | Przepisz: nowa paleta Candy Pastel + Chunky helpers |
| `src/client/HUD.luau` | Przepisz: jasny top bar + tab bar |
| `src/client/GardenUI.luau` | Przepisz: chunky styl |
| `src/client/CollectionBook.luau` | Przepisz: chunky styl z rarity borders |
| `src/client/ShopUI.luau` | Przepisz: chunky styl |
| `src/client/DailyRewardsUI.luau` | Przepisz: pastelowe kółka streakowe |
| `src/client/DropAnimation.luau` | Przepisz: jasny flash, konfetti, chunky karta |
| `src/client/LeaderboardUI.luau` | Przepisz: biała lista, pastelowe podium |

## 6. Poza zakresem MVP

- Cross-server trading
- Customizacja działki (dekoracje, meble)
- System znajomych / lista przyjaciół
- Gifting brainrotów
- Mini-gry społeczne na hubie
