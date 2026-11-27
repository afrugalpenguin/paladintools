require("tests.mocks.wow_api")

local function load()
    dofile("Core.lua")
    PaladinTools:InitDB()
    dofile("Data.lua")
    dofile("PopupMenu.lua")
    dofile("PopupMenu_Forever.lua")
    return PaladinTools.modules["PopupMenu"]
end

local NAMES = {
    ["Blessing of Kings"] = "kings",
    ["Greater Blessing of Kings"] = "kings",
    ["Blessing of Might"] = "might",
}

describe("PopupMenu_Forever", function()
    local PM
    local auras  -- unit -> spell name -> aura table

    before_each(function()
        _G.PaladinToolsDB = nil
        _G.GetNumTalents = nil
        _G.GetTalentInfo = nil
        auras = {}
        _G.C_UnitAuras = {
            GetAuraDataBySpellName = function(unit, name, filter)
                assert.are.equal("HELPFUL", filter)
                return auras[unit] and auras[unit][name]
            end,
        }
        PM = load()
    end)

    after_each(function()
        _G.C_UnitAuras = nil
        _G.IsPlayerSpell = nil
        _G.C_SpellBook = nil
        _G.issecretvalue = nil
    end)

    describe("HasImprovedRF", function()
        it("is true when the talent spell 20468 is known", function()
            _G.IsPlayerSpell = function(id) return id == 20468 end
            assert.is_true(PM:HasImprovedRF())
        end)

        it("is false when the talent is not taken", function()
            _G.IsPlayerSpell = function() return false end
            _G.C_SpellBook = { IsSpellKnown = function() return false end }
            assert.is_false(PM:HasImprovedRF())
        end)

        it("falls back to C_SpellBook.IsSpellKnown", function()
            _G.C_SpellBook = { IsSpellKnown = function(id) return id == 20468 end }
            assert.is_true(PM:HasImprovedRF())
        end)
    end)

    describe("ReadAssignedBlessing", function()
        it("finds the greater blessing of the assigned type", function()
            auras.party1 = { ["Greater Blessing of Kings"] = { duration = 3600, expirationTime = 4600 } }
            local found, duration, expires = PM:ReadAssignedBlessing("party1", NAMES, "kings")
            assert.is_true(found)
            assert.are.equal(3600, duration)
            assert.are.equal(4600, expires)
        end)

        it("does not count a blessing of another type", function()
            auras.party1 = { ["Blessing of Might"] = { duration = 3600, expirationTime = 4600 } }
            assert.is_false(PM:ReadAssignedBlessing("party1", NAMES, "kings"))
        end)

        it("returns nil when the aura read errors because auras are secret", function()
            _G.C_UnitAuras.GetAuraDataBySpellName = function() error("Auras cannot be accessed when secret") end
            assert.is_nil(PM:ReadAssignedBlessing("party1", NAMES, "kings"))
        end)

        it("does not try to read auras in combat", function()
            auras.party1 = { ["Greater Blessing of Kings"] = { duration = 3600, expirationTime = 4600 } }
            _G.InCombatLockdown = function() return true end
            assert.is_nil(PM:ReadAssignedBlessing("party1", NAMES, "kings"))
            _G.InCombatLockdown = function() return false end
        end)

        it("returns nil when the aura times are secret", function()
            local secret = {}
            _G.issecretvalue = function(v) return v == secret end
            auras.party1 = { ["Blessing of Kings"] = { duration = secret, expirationTime = secret } }
            assert.is_nil(PM:ReadAssignedBlessing("party1", NAMES, "kings"))
        end)
    end)
end)
