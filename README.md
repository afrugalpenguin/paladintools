# PaladinTools

A paladin utility addon for World of Warcraft TBC Anniversary Classic and WoW Forever. Provides quick-access spell menus, buff tracking, reagent monitoring, and whisper-based buff request handling.

> ### 🛡️ Now on WoW Forever
> PaladinTools now runs on **WoW Forever** as well as TBC Anniversary. It's one download: the same zip carries a build for each game, and WoW loads the right one for you. Your TBC setup is unchanged.


## Features

### Spell Popup Menu
- Quick-access popup organized by category: Blessings, Greater Blessings, Auras, and Seals
- Configurable keybind to toggle the menu
- **Release-to-cast mode** — hold the keybind, hover a spell, release to cast
- Automatically finds the highest rank of each spell from your spellbook
- Toggle individual categories on/off

### Buff Manager HUD
- Compact, movable reagent counter (Symbol of Kings)
- Horizontal or vertical layout
- Configurable button size
- Option to auto-hide in combat

### Blessing Session Panel
- Shows group size and reagent readiness at a glance
- Adjustable background opacity

### Buff Helper (Buff Queue)
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

## WoW Forever

Forever changed the paladin toolkit and limits what addons can see, so a few things work differently there.

**Spells**
- Greater Blessings exist only for Kings, Might and Wisdom. They still use Symbol of Kings.
- Blessing of Light, Salvation and Sanctuary, Sanctity Aura, Crusader Aura, Seal of Blood and Seal of Vengeance are gone, so the popup leaves them out.
- **Seal of Fury** is new and shows up in the Seals quadrant.
- The Righteous Fury button still appears when you have Improved Righteous Fury.

**What addons can't see**
- Forever hides group members' buffs from addons in combat, and sometimes inside instances. When it does, the blessing grid's counts and timers go blank. They come back once the buffs can be read again.
- When chat is locked down, Forever hides whisper text too, so the Buff Helper can't queue requests until it lifts.

**Reporting problems**
- Run `/ptapi` (Forever only) to probe the API, and include what it prints in a bug report.

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
