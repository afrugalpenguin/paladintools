# PaladinTools

A paladin utility addon for World of Warcraft TBC Anniversary Classic. Provides quick-access spell menus, buff tracking, reagent monitoring, and whisper-based buff request handling.

## Features

### Spell Popup Menu
- Quick-access popup organized by category: Blessings, Greater Blessings, Auras, and Seals
- Configurable keybind to toggle the menu
- **Release-to-cast mode** — hold the keybind, hover a spell, release to cast
- Automatically finds the highest rank of each spell from your spellbook
- Toggle individual categories on/off

### Buff Manager HUD
- Compact, movable HUD showing your active blessings and auras
- Reagent counter for Symbol of Kings and Symbol of Divinity
- Horizontal or vertical layout
- Configurable button size
- Option to auto-hide in combat

### Blessing Session Panel
- Track active blessings across your group/raid
- Monitor which group members have (or are missing) buffs
- Adjustable background opacity

### Trade Helper (Buff Queue)
- Listens for whispers (and optionally party chat) containing buff-related keywords
- Queues incoming buff requests with the player name and requested blessing
- Auto-reply to acknowledge requests
- Configurable keyword list — add or remove trigger words from the options panel

### Options Panel
- Tabbed settings UI: General, Buff Helper, Appearance
- Accessible via `/pt options` or the Blizzard Interface Options menu
- Keybind capture widget for the popup menu toggle

### Masque Support
- Optional [Masque](https://www.curseforge.com/wow/addons/masque) skin support for all action buttons
- Graceful fallback when Masque is not installed

## Installation

1. Download the latest release from [CurseForge](https://www.curseforge.com/wow/addons/paladintools) or GitHub Releases
2. Extract the `PaladinTools` folder into your `Interface/AddOns` directory
3. Restart WoW or reload the UI (`/reload`)

The addon only loads for Paladin characters.

## Slash Commands

| Command | Description |
|---|---|
| `/pt` | Show help (or What's New on first login) |
| `/pt popup` | Toggle the spell popup menu |
| `/pt hud` | Toggle the HUD |
| `/pt session` | Toggle the Blessing Session panel |
| `/pt queue` | Toggle the buff request queue |
| `/pt options` | Open the options panel |
| `/pt whatsnew` | View the changelog |
| `/pt config` | Print current config to chat |

## Optional Dependencies

- **[Masque](https://www.curseforge.com/wow/addons/masque)** — button skinning support

## License

All rights reserved.
