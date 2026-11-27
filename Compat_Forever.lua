--[[
    PaladinTools - Forever compatibility layer
    Recreates TBC globals missing from the Forever client and swaps the spellbook scan
    for C_SpellBook. Loaded only by PaladinTools_Camelot.toc, straight after Core.lua.
]]

local PT = PaladinTools

PT.isForever = true

-- GetSpellInfo with the TBC return order: name, rank, icon, castTime, minRange, maxRange, spellID
if not GetSpellInfo and C_Spell and C_Spell.GetSpellInfo then
    function GetSpellInfo(spell)
        local info = C_Spell.GetSpellInfo(spell)
        if not info then return nil end
        return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
    end
end

if not GetItemIcon and C_Item and C_Item.GetItemIconByID then
    GetItemIcon = C_Item.GetItemIconByID
end

if not SendChatMessage and C_ChatInfo and C_ChatInfo.SendChatMessage then
    SendChatMessage = C_ChatInfo.SendChatMessage
end

-- Forever has no GetSpellBookItemName/BOOKTYPE_SPELL. Walk C_SpellBook instead and skip
-- spells the book only previews (FutureSpell), which the player cannot cast yet.
function PT:FindSpellInBook(targetName)
    local bank = Enum.SpellBookSpellBank.Player
    local spellType = Enum.SpellBookItemType.Spell
    local foundID
    for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(line)
        if lineInfo then
            local first = lineInfo.itemIndexOffset + 1
            for slot = first, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
                if item and item.itemType == spellType and item.name == targetName then
                    foundID = item.spellID or item.actionID  -- last match = highest rank
                end
            end
        end
    end
    return foundID
end
