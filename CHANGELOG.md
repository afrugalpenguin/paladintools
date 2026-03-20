# Changelog

**v3.0.0**
- New: Blessing Sync — broadcast and receive blessing assignments across paladins in your group/raid
- New: Blessings tab rebuilt as a paladin-rows × class-columns grid for multi-paladin coordination
- New: /fakesync and /fakepaladins debug commands for protocol and UI testing
- Fixed: Frame leak in grid cleanup when rebuilding the Blessings tab

**v2.1.0**
- New: Righteous Fury button in the center of the spell popup for Prot paladins (requires Improved Righteous Fury talent)
- Improved: Popup quadrants dynamically space out to accommodate the center RF button

**v2.0.0**
- New: PallyPower-inspired Blessings Manager — dedicated Options tab to assign Greater Blessings per class, persists across sessions
- New: /pt now opens the Blessings Manager by default, /pt manager as shortcut
- New: /pt help command lists all available commands
- New: Tour step for the Blessings Manager
- Improved: Popup class grid uses spellbook lookups for reliable spell icons and casting (fixes blank icons on cold login)
- Improved: Popup rebuilds on show to clear stale group members
- Improved: Class icon coordinates use WoW's CLASS_ICON_TCOORDS when available
- Fixed: Options Blessings tab now only shows blessings you actually know

**v1.1.1**
- Fixed HUD buttons invisible when item icon isn't cached (Symbol of Divinity)
- Added amber/red border highlights to Blessings Manager buttons based on remaining buff duration

**v1.1.0**
- New: Blessings Manager — horizontal class grid on popup, right-click to assign Greater Blessings, left-click to cast, with timer overlays
- New: Symbol of Divinity tracking on HUD
- New: /fakeraid and /fakeparty debug commands for UI testing
- Improved: Tour now demos the Blessings Manager with a fake party
- Fixed: Blessing assignment changes now immediately rescan buff status
- Removed: Old standalone blessing session panel

**v1.0.1**
- Fixed inaccurate HUD and Blessing Session descriptions in README and Tour
- Renamed Trade Helper to Buff Helper in README

**v1.0.0**
- New: Onboarding tour — `/pt tour` walks through addon features
- Removed: "Show Blessing Session on Login" setting (replaced by tour)

**v0.1.0**
- Initial release: blessings, auras, seals popup menu
- Reagent tracking HUD (Symbol of Kings)
- Buff request whisper queue with auto-reply
- Blessing session panel for group buff tracking
- Tabbed options panel
- Masque skin support
