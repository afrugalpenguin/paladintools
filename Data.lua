local PT = PaladinTools

-- Blessings (single-target, highest rank first per blessing)
PT.BLESSINGS = {
    { spellID = 27142, name = "Blessing of Might",    type = "might" },
    { spellID = 27143, name = "Blessing of Wisdom",   type = "wisdom" },
    { spellID = 27169, name = "Blessing of Kings",    type = "kings" },
    { spellID = 27168, name = "Blessing of Salvation", type = "salvation" },
    { spellID = 27170, name = "Blessing of Sanctuary", type = "sanctuary" },
    { spellID = 27150, name = "Blessing of Light",    type = "light" },
}

-- Greater Blessings (group-wide, require reagent)
PT.GREATER_BLESSINGS = {
    { spellID = 27141, name = "Greater Blessing of Might",      type = "might" },
    { spellID = 27145, name = "Greater Blessing of Wisdom",     type = "wisdom" },
    { spellID = 25898, name = "Greater Blessing of Kings",      type = "kings" },
    { spellID = 25895, name = "Greater Blessing of Salvation",  type = "salvation" },
    { spellID = 27169, name = "Greater Blessing of Sanctuary",  type = "sanctuary" },
    { spellID = 27174, name = "Greater Blessing of Light",      type = "light" },
}

-- Auras
PT.AURAS = {
    { spellID = 27149, name = "Devotion Aura" },
    { spellID = 27150, name = "Retribution Aura" },
    { spellID = 27151, name = "Concentration Aura" },
    { spellID = 27152, name = "Shadow Resistance Aura" },
    { spellID = 27153, name = "Frost Resistance Aura" },
    { spellID = 27154, name = "Fire Resistance Aura" },
    { spellID = 32223, name = "Crusader Aura" },
}

-- Seals
PT.SEALS = {
    { spellID = 27158, name = "Seal of Righteousness" },
    { spellID = 27170, name = "Seal of Command" },
    { spellID = 27174, name = "Seal of Wisdom" },
    { spellID = 27175, name = "Seal of Light" },
    { spellID = 20920, name = "Seal of Crusader" },
    { spellID = 27173, name = "Seal of Justice" },
    { spellID = 31892, name = "Seal of Blood",          faction = "Horde" },
    { spellID = 31801, name = "Seal of Vengeance",      faction = "Alliance" },
}

-- Judgement spell
PT.JUDGEMENT_SPELL = 10321  -- Judgement (rank doesn't matter, single spell)

-- Reagent item IDs
PT.SYMBOL_OF_KINGS = 21177   -- Symbol of Kings (Greater Blessing of Kings)
PT.SYMBOL_OF_DIVINITY = 21177 -- Note: verify actual item ID in-game

-- Reagent tracking set for bag scanning
PT.REAGENT_ITEM_SET = {}
PT.REAGENT_ITEM_SET[PT.SYMBOL_OF_KINGS] = "symbolOfKings"

-- Build a lookup for all tracked items
PT.TRACKED_ITEM_SET = {}
PT.TRACKED_ITEM_SET[PT.SYMBOL_OF_KINGS] = "symbolOfKings"
