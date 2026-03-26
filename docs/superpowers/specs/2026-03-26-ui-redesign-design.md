# UI Redesign — Grow a Brainrot

## Overview

Complete visual overhaul of all client UI modules to "Neon Chaos" style — dark backgrounds with magenta/cyan/yellow neon accents, glow effects, gradients, and smooth animations. Mobile-first, fullscreen panels, consistent list-view patterns.

## Design Decisions

| Element | Choice | Rationale |
|---------|--------|-----------|
| Visual style | Neon Chaos | Matches brainrot/meme culture, eye-catching for Gen Alpha |
| Navigation | Tab Bar with icons | Proven mobile pattern, easy thumb reach |
| Panels | Fullscreen Overlay | Max content space, clear focus, good on mobile |
| Garden beds | List View | Readable, scales to 8 beds, shows all info at a glance |
| Collection | List Collection | Consistent with garden list pattern |

## Color Palette

### Backgrounds
- Primary background: `Color3.fromRGB(10, 10, 26)` — very dark blue-black
- Panel background: `Color3.fromRGB(10, 5, 30)` — dark purple-black
- Card background (subtle): `Color3.fromRGB(20, 15, 40)` — slightly lighter
- List item background: `Color3.fromRGB(15, 12, 35)` — between panel and card

### Neon Accents
- Magenta (primary): `Color3.fromRGB(255, 0, 255)` — borders, primary buttons, main glow
- Cyan (secondary): `Color3.fromRGB(0, 255, 255)` — secondary accent, info elements
- Yellow (premium): `Color3.fromRGB(255, 255, 0)` — seeds currency, growing state
- Green (success): `Color3.fromRGB(0, 255, 136)` — ready state, harvest, free seed
- Orange-gold (premium currency): `Color3.fromRGB(255, 180, 0)` — golden seeds

### Rarity Colors (unchanged, used for left borders and text)
- Common: `Color3.fromRGB(180, 180, 180)`
- Uncommon: `Color3.fromRGB(80, 200, 80)`
- Rare: `Color3.fromRGB(50, 120, 255)`
- Epic: `Color3.fromRGB(180, 50, 255)`
- Legendary: `Color3.fromRGB(255, 200, 0)`
- Mythic: `Color3.fromRGB(255, 50, 50)`

### Text
- Primary: White `Color3.fromRGB(255, 255, 255)`
- Secondary: `Color3.fromRGB(255, 255, 255)` at 0.5 TextTransparency
- Hint/disabled: `Color3.fromRGB(255, 255, 255)` at 0.7 TextTransparency

## Typography

- Titles: `GothamBold`, size 22-24
- Section headers: `GothamBold`, size 16-18
- Body/labels: `GothamBold`, size 12-14
- Small text: `Gotham`, size 10-11
- Use `RichText = true` for gradient-like title effects via `<font color>` tags

## Shared UI Components

### UITheme Module (new: `src/client/UITheme.luau`)

Centralized constants and helper functions used by all UI modules:
- Color constants (backgrounds, accents, rarity colors)
- Font constants
- `createNeonBorder(parent, color, thickness)` — adds UIStroke with glow color
- `createGradientBackground(parent, colorStart, colorEnd, rotation)` — adds UIGradient
- `createListItem(parent, config)` — standard list row: left border color + icon + info area + action button
- `tweenOpen(frame)` / `tweenClose(frame, callback)` — standard panel open/close animations
- `createTabBar(screenGui, tabs)` — builds the bottom tab bar

### List Item Pattern

Used by Garden beds and Collection. Each row is a Frame:
- Size: `UDim2.new(1, -20, 0, 56)` (full width minus padding, 56px tall)
- Background: subtle dark `(15, 12, 35)` at 0.3 transparency
- UICorner: 10px
- Left border: UIStroke on a thin Frame (3px wide) in the state/rarity color
- Layout: horizontal — Icon (40px) | Info column (flex) | Action button (optional)
- UIPadding: 10px horizontal, 8px vertical

### Panel Template

All fullscreen panels (Shop, Collection, DailyRewards, Garden) share:
- ScreenGui with DisplayOrder 10
- Full-screen background Frame: `(10, 5, 30)` at 0.05 transparency
- Header bar: 56px tall, bottom border 2px UIStroke in magenta
  - Title: GothamBold 20, white with neon text shadow (via UIStroke on text, ApplyStrokeMode = Contextual)
  - Close button: 32px square, UICorner 8px, magenta border, "X" text
- Content area: ScrollingFrame below header, UIPadding 10px all sides
- Open animation: background fades in (0.2s), content slides up from bottom (0.3s, Back easing)
- Close animation: reverse (0.2s fade out)

## Component Specifications

### 1. HUD (Top Bar)

**Currency display** — horizontal bar at top of screen:
- Frame: `UDim2.new(1, 0, 0, 50)`, anchored top
- Background: `(10, 10, 26)` at 0.1 transparency
- UIStroke bottom: 1px magenta at 0.7 transparency (subtle glow line)
- Layout: UIListLayout Horizontal, center aligned, 12px padding

**Currency pill** (x3: Seeds, Golden Seeds, Collection):
- Frame with UICorner 12px
- Background: accent color at 0.85 transparency (very subtle tint)
- UIStroke: 1px in accent color at 0.5 transparency
- UIPadding: 8px horizontal, 4px vertical
- Label text (top): category name, size 10, uppercase, accent color at 0.5 transparency
- Value text (bottom): size 16, GothamBold, white
- Seeds accent: yellow `(255, 255, 0)`
- Golden Seeds accent: orange `(255, 180, 0)`
- Collection accent: cyan `(0, 255, 255)`

### 2. Tab Bar (Bottom Navigation)

- Frame: `UDim2.new(1, 0, 0, 64)`, anchored bottom
- Background: `(10, 10, 26)` at 0.05 transparency
- UIStroke top: 2px magenta
- Layout: UIListLayout Horizontal, EqualSpacing, center aligned

**Tab button** (x5: Garden, Shop, Collection (center), Daily, Free Seed):
- Size: `UDim2.new(0.18, 0, 1, -8)`
- Background: transparent
- Icon: emoji TextLabel, size 22, centered top
- Label: size 9, GothamBold, uppercase, letter spacing via padding
- Inactive: white at 0.6 transparency
- Active: full white + accent color glow

**Center button (Collection):**
- Larger: `UDim2.new(0.22, 0, 1, 16)`, shifted up 16px (negative Y position)
- Background: UIGradient magenta → dark magenta vertical
- UICorner: 14px
- UIStroke: 2px bright magenta
- Box shadow effect via secondary frame behind with blur (or just stronger UIStroke glow)
- Icon and label always full white

### 3. Garden Panel (List View)

**Header:**
- Title: "YOUR GARDEN" with plant emoji
- Subtitle: "4/8 beds" in secondary text
- Upgrade button (if beds < 8): right-aligned, yellow accent, shows cost

**Bed list items** (4-8 rows via UIListLayout Vertical, 8px padding):

**Empty bed:**
- Left border: magenta at 0.5 transparency
- Icon: hole emoji (or seed emoji), 0.4 transparency
- Text: "Tap to Plant", secondary color
- Border style: dashed effect (via UIStroke with dashed pattern or reduced opacity)
- Action: entire row is clickable (plants seed)

**Growing bed:**
- Left border: yellow `(255, 255, 0)`
- Icon: seedling emoji
- Info: "Growing" label + countdown timer in bold white
- Progress bar: thin Frame (3px) at bottom of list item
  - Background track: white at 0.9 transparency
  - Fill: UIGradient yellow → orange, width = percentage complete
- Action button: "WATER" pill, blue gradient `(0, 136, 255)` → `(0, 68, 170)`, UICorner 6px
  - Disabled state (on cooldown): gray, reduced opacity
  - Shows cooldown seconds when on cooldown

**Ready bed:**
- Left border: green `(0, 255, 136)` with glow
- Icon: sparkle emoji
- Text: "READY!" in green, GothamBold
- Subtle glow: UIStroke on the row frame, green at 0.7 transparency
- Pulsing animation: tween UIStroke transparency 0.7 → 0.4 → 0.7, looping
- Action: "HARVEST" pill, green gradient
- Tap anywhere on row to harvest

**Locked bed:**
- Left border: white at 0.1 transparency
- Icon: lock emoji, 0.2 opacity
- Text: "Locked — 500 seeds", very dim
- Dashed border feel: UIStroke at 0.8 transparency
- Entire row at 0.4 transparency

### 4. Shop Panel (Fullscreen)

Uses standard panel template.

**Gamepass section:**
- Section header: "GAMEPASSES" with star emoji, magenta accent line
- 3 list items (VIP Gardener, Auto-Harvest, Double Collection):
  - Left border: alternating magenta / cyan / yellow
  - Icon: relevant emoji
  - Info: name (bold white 14px) + description (secondary 11px)
  - Action: price pill with gradient matching left border color, "199 R$" text
  - Owned state: "OWNED" green badge instead of price, reduced border glow

**Dev Products section:**
- Section header: "BOOSTS" with rocket emoji
- 2 list items (Golden Seed Pack, Mega Fertilizer):
  - Left border: orange-gold
  - Same layout as gamepasses but smaller (48px height)

### 5. Collection Panel (List View)

Uses standard panel template.

**Header:**
- Title: "COLLECTION" with book emoji
- Subtitle: "X/15 discovered"

**Collection list items** (sorted by rarity, rarest first):

**Owned brainrot:**
- Left border: rarity color (3px, solid)
- Background: very subtle gradient from rarity color (0.08 opacity) → transparent
- Icon: brainrot emoji (from BrainrotDatabase)
- Info column:
  - Name: white, GothamBold, 12px
  - Rarity label: rarity color, GothamBold, 9px, uppercase (e.g., "⭐ LEGENDARY — 2.5%")
- Count: "xN" in white bold 14px, right-aligned
- Sell button (if count >= 2): orange pill "SELL +{value}", UICorner 6px
  - Only visible when count >= 2

**Locked brainrot:**
- Left border: white at 0.1 transparency
- Icon: question mark emoji
- Name: "???" in dim text
- Rarity hint: rarity name in very dim text (0.8 transparency)
- Entire row at 0.35 transparency

**Rarity section dividers** (between rarity groups):
- Thin horizontal line with gradient fade (transparent → rarity color → transparent)
- Rarity label centered: uppercase, letter-spaced, rarity color, 9px

### 6. Daily Rewards Panel (Fullscreen)

Uses standard panel template but with centered content.

**Layout (centered vertically):**
- Streak display: "STREAK" label + day count in large neon text (size 36, GothamBold)
  - UIStroke on text: magenta glow
  - Streak number color: cycles through magenta → cyan based on streak length
- Reward preview: "+{amount} seeds" in yellow, size 20
- Visual streak indicator: 7 small circles in a row
  - Completed days: filled with gradient (magenta → cyan)
  - Current day: pulsing glow
  - Future days: dim outline only
- Claim button:
  - Ready: full-width, green gradient, "CLAIM!" text, size 18, UICorner 10px, glow shadow
  - Cooldown: gray, "Wait Xh Xm" text, no glow

### 7. Drop Animation (Enhanced)

Keep existing logic but enhance visuals:
- Background flash: keep, add subtle radial gradient from center
- Card: increase to 350x220, UICorner 20px
- UIStroke: 3px rarity color + add UIGradient to stroke (rarity color → white → rarity color)
- Add particle-like decorative frames around card (small squares/circles with rarity color, tweening outward and fading)
- Chance text: add for all rarities, not just Legendary/Mythic
- Add screen shake effect (small rapid position tweens on the card)
- Sound cue integration point (comment for future)

### 8. Free Seed Button

Instead of a separate panel, show as a special tab bar button:
- When available: green glow pulse on the tab icon
- On tap: brief toast notification at top of screen "🌱 +1 Seed!" with slide-down + fade animation
- On cooldown: tab icon dimmed, no special indicator

## Animation Specifications

### Panel Open/Close
```
Open:
1. Background frame: Transparency 1 → 0.05 (0.2s, Quad Out)
2. Content frame: Position Y offset +50 → 0, Transparency 1 → 0 (0.3s, Back Out)

Close:
1. Content frame: Transparency 0 → 1 (0.15s, Quad In)
2. Background frame: Transparency 0.05 → 1 (0.15s, Quad In)
3. Destroy after animation completes
```

### Button Hover/Press (Tab Bar)
```
Hover: Scale 1 → 1.1 (0.15s, Quad Out)
Press: Scale 1.1 → 0.95 (0.05s), then → 1.0 (0.1s)
```

### Garden Bed Ready Pulse
```
Loop: UIStroke Transparency 0.7 → 0.3 → 0.7 (1.5s, Sine InOut, repeat)
Loop: Icon Scale 1 → 1.05 → 1 (2s, Sine InOut, repeat)
```

### Progress Bar Update
```
Fill frame Size X: current → new (0.3s, Quad Out)
```

### Toast Notification (Free Seed)
```
Appear: Y offset -30 → 0 (0.3s, Back Out), Transparency 1 → 0
Hold: 1.5s
Disappear: Transparency 0 → 1 (0.3s, Quad In)
```

## Responsiveness

- All panel sizes use Scale (0-1) not Offset for width/height
- Content areas use UIListLayout with automatic sizing
- List items: `UDim2.new(1, -20, 0, 56)` — full width minus padding
- Tab bar height: fixed 64px (appropriate touch target)
- HUD height: fixed 50px
- Currency pills: auto-size based on text via AutomaticSize = X
- Test on mobile viewport (minimum 320px width assumed)

## File Structure

### New files:
- `src/client/UITheme.luau` — shared constants, colors, helper functions

### Modified files:
- `src/client/HUD.luau` — complete rewrite with new style
- `src/client/GardenUI.luau` — rewrite to list view with progress bars
- `src/client/CollectionBook.luau` — rewrite to list view with rarity borders
- `src/client/ShopUI.luau` — rewrite to fullscreen with list items
- `src/client/DailyRewardsUI.luau` — rewrite to fullscreen centered layout
- `src/client/DropAnimation.luau` — enhanced visuals, keep core logic
- `src/client/init.client.luau` — integrate tab bar, update panel toggling

## Out of Scope

- Custom icons/images (using emoji for now, can be replaced with ImageLabels later)
- Sound effects
- Haptic feedback
- Settings panel
- Chat UI customization
