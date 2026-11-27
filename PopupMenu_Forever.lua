--[[
    PaladinTools - Forever overrides for the spell popup
    Loaded only by PaladinTools_Camelot.toc, after PopupMenu.lua.
]]

local PT = PaladinTools
local PM = PT.modules["PopupMenu"]

local IMPROVED_RIGHTEOUS_FURY = 20468  -- one rank on Forever

local function IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v)
end

-- GetTalentInfo is missing on Forever, so ask whether the talent's spell is known
function PM:HasImprovedRF()
    if IsPlayerSpell and IsPlayerSpell(IMPROVED_RIGHTEOUS_FURY) then return true end
    if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(IMPROVED_RIGHTEOUS_FURY) then
        return true
    end
    return false
end

-- UnitBuff is gone. Aura reads error or come back secret in combat (and in instances even out of
-- combat); return nil then so the blessing scan keeps its last readable result.
function PM:ReadAssignedBlessing(unit, blessingNames, assignedType)
    if InCombatLockdown() then return nil end  -- always secret; skip the failing read
    for name, bType in pairs(blessingNames) do
        if bType == assignedType then
            local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, name, "HELPFUL")
            if not ok or IsSecret(aura) then return nil end
            if aura then
                if IsSecret(aura.duration) or IsSecret(aura.expirationTime) then return nil end
                return true, aura.duration, aura.expirationTime
            end
        end
    end
    return false
end
