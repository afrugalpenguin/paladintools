require("tests.mocks.wow_api")

-- Party of two warriors plus the player (a paladin)
local UNIT_CLASSES = { party1 = "WARRIOR", party2 = "WARRIOR", player = "PALADIN" }

local function load()
    dofile("Core.lua")
    PaladinTools:InitDB()
    dofile("Data.lua")
    dofile("PopupMenu.lua")
    return PaladinTools.modules["PopupMenu"]
end

describe("PopupMenu blessing scan", function()
    local PM
    local buffs  -- unit -> list of { name, duration, expirationTime }

    before_each(function()
        _G.PaladinToolsDB = nil
        _G.GetNumGroupMembers = function() return 3 end
        _G.IsInRaid = function() return false end
        _G.UnitExists = function(unit) return UNIT_CLASSES[unit] ~= nil end
        _G.UnitClass = function(unit)
            local class = UNIT_CLASSES[unit]
            return class, class
        end
        buffs = {
            party1 = { { "Blessing of Wisdom", 3600, 1500 }, { "Greater Blessing of Kings", 3600, 2000 } },
            party2 = {},
        }
        _G.UnitBuff = function(unit, index)
            local b = buffs[unit] and buffs[unit][index]
            if not b then return nil end
            return b[1], nil, 1, nil, b[2], b[3]
        end
        PM = load()
        PaladinToolsDB.blessingAssignments.WARRIOR = "kings"
    end)

    after_each(function()
        _G.UnitBuff = nil
    end)

    it("counts buffed members of each class and keeps the shortest expiry", function()
        PM:ScanRoster()
        PM:ScanBlessings()
        local info = PM:GetClassBlessing("WARRIOR")
        assert.are.equal(1, info.buffed)
        assert.are.equal(2, info.total)
        assert.are.equal(2000, info.expires)
        assert.are.equal(3600, info.duration)
    end)

    it("ignores blessings of a different type than the assignment", function()
        PaladinToolsDB.blessingAssignments.WARRIOR = "might"
        PM:ScanRoster()
        PM:ScanBlessings()
        assert.are.equal(0, PM:GetClassBlessing("WARRIOR").buffed)
    end)

    it("reads a unit's assigned blessing with UnitBuff", function()
        local names = { ["Greater Blessing of Kings"] = "kings", ["Blessing of Wisdom"] = "wisdom" }
        local found, duration, expires = PM:ReadAssignedBlessing("party1", names, "kings")
        assert.is_true(found)
        assert.are.equal(3600, duration)
        assert.are.equal(2000, expires)
        assert.is_false(PM:ReadAssignedBlessing("party2", names, "kings"))
    end)

    it("keeps the previous scan when a unit's auras cannot be read", function()
        PM:ScanRoster()
        PM:ScanBlessings()
        PM.ReadAssignedBlessing = function() return nil end
        PM:ScanBlessings()
        local info = PM:GetClassBlessing("WARRIOR")
        assert.are.equal(1, info.buffed)
        assert.are.equal(2000, info.expires)
    end)
end)
