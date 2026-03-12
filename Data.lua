local PT = PaladinTools

-- Blessings (single-target, highest rank in TBC)
PT.BLESSINGS = {
    { spellID = 27140, name = "Blessing of Might",      type = "might" },
    { spellID = 27142, name = "Blessing of Wisdom",     type = "wisdom" },
    { spellID = 20217, name = "Blessing of Kings",      type = "kings" },      -- talent
    { spellID = 1038,  name = "Blessing of Salvation",   type = "salvation" },
    { spellID = 27168, name = "Blessing of Sanctuary",   type = "sanctuary" }, -- talent
    { spellID = 27144, name = "Blessing of Light",       type = "light" },
}

-- Greater Blessings (group-wide, require Symbol of Kings reagent)
PT.GREATER_BLESSINGS = {
    { spellID = 27141, name = "Greater Blessing of Might",      type = "might" },
    { spellID = 27143, name = "Greater Blessing of Wisdom",     type = "wisdom" },
    { spellID = 25898, name = "Greater Blessing of Kings",      type = "kings" },      -- talent
    { spellID = 25895, name = "Greater Blessing of Salvation",  type = "salvation" },
    { spellID = 27169, name = "Greater Blessing of Sanctuary",  type = "sanctuary" }, -- talent
    { spellID = 27145, name = "Greater Blessing of Light",      type = "light" },
}

-- Auras
PT.AURAS = {
    { spellID = 27149, name = "Devotion Aura" },
    { spellID = 27150, name = "Retribution Aura" },
    { spellID = 19746, name = "Concentration Aura" },
    { spellID = 27151, name = "Shadow Resistance Aura" },
    { spellID = 27152, name = "Frost Resistance Aura" },
    { spellID = 27153, name = "Fire Resistance Aura" },
    { spellID = 32223, name = "Crusader Aura" },
    { spellID = 20218, name = "Sanctity Aura" },           -- talent (Retribution)
}

-- Seals
PT.SEALS = {
    { spellID = 27155, name = "Seal of Righteousness" },
    { spellID = 27170, name = "Seal of Command" },          -- talent (Retribution)
    { spellID = 27166, name = "Seal of Wisdom" },
    { spellID = 27160, name = "Seal of Light" },
    { spellID = 27158, name = "Seal of the Crusader" },
    { spellID = 31895, name = "Seal of Justice" },
    { spellID = 31892, name = "Seal of Blood",          faction = "Horde" },
    { spellID = 31801, name = "Seal of Vengeance",      faction = "Alliance" },
}

-- Righteous Fury (self-buff, shown for Prot spec)
PT.RIGHTEOUS_FURY = { spellID = 25780, name = "Righteous Fury" }

-- Judgement spell
PT.JUDGEMENT_SPELL = 20271

-- Reagent item IDs
PT.SYMBOL_OF_KINGS = 21177    -- Symbol of Kings (all Greater Blessings)
PT.SYMBOL_OF_DIVINITY = 17033 -- Symbol of Divinity (Divine Intervention)

-- Reagent tracking set for bag scanning
PT.REAGENT_ITEM_SET = {}
PT.REAGENT_ITEM_SET[PT.SYMBOL_OF_KINGS] = "symbolOfKings"
PT.REAGENT_ITEM_SET[PT.SYMBOL_OF_DIVINITY] = "symbolOfDivinity"

-- Build a lookup for all tracked items
PT.TRACKED_ITEM_SET = {}
PT.TRACKED_ITEM_SET[PT.SYMBOL_OF_KINGS] = "symbolOfKings"
PT.TRACKED_ITEM_SET[PT.SYMBOL_OF_DIVINITY] = "symbolOfDivinity"

-- Class icon atlas: use WoW global if available, fall back to hardcoded
PT.CLASS_ICON_COORDS = CLASS_ICON_TCOORDS or {
    WARRIOR     = { 0.00, 0.25, 0.00, 0.25 },
    MAGE        = { 0.25, 0.50, 0.00, 0.25 },
    ROGUE       = { 0.50, 0.75, 0.00, 0.25 },
    DRUID       = { 0.75, 1.00, 0.00, 0.25 },
    HUNTER      = { 0.00, 0.25, 0.25, 0.50 },
    SHAMAN      = { 0.25, 0.50, 0.25, 0.50 },
    PRIEST      = { 0.50, 0.75, 0.25, 0.50 },
    WARLOCK     = { 0.75, 1.00, 0.25, 0.50 },
    PALADIN     = { 0.00, 0.25, 0.50, 0.75 },
}

PT.CLASS_ICON_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes"

PT.GREATER_BLESSING_BY_TYPE = {}
for _, spell in ipairs(PT.GREATER_BLESSINGS) do
    PT.GREATER_BLESSING_BY_TYPE[spell.type] = spell
end

PT.BLESSING_CYCLE_ORDER = { "might", "wisdom", "kings", "salvation", "sanctuary", "light" }
