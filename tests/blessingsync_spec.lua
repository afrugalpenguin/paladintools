require("tests.mocks.wow_api")

local LOCKDOWN = 11

local function load()
    dofile("Core.lua")
    PaladinTools:InitDB()
    dofile("Data.lua")
    dofile("BlessingSync.lua")
    return PaladinTools.modules["BlessingSync"]
end

describe("BlessingSync sending", function()
    local BS, sends, result

    before_each(function()
        _G.PaladinToolsDB = nil
        _G.GetNumGroupMembers = function() return 5 end
        _G.Enum = { SendAddonMessageResult = { Success = 0, AddOnMessageLockdown = LOCKDOWN } }
        sends = {}
        result = 0
        _G.C_ChatInfo.SendAddonMessage = function(prefix, msg, channel)
            sends[#sends + 1] = msg
            return result
        end
        BS = load()
    end)

    after_each(function()
        _G.GetNumGroupMembers = function() return 0 end
        _G.Enum = nil
        _G.C_ChatInfo.SendAddonMessage = function() return true end
    end)

    it("broadcasts assignments to the group", function()
        PaladinToolsDB.blessingAssignments.WARRIOR = "kings"
        BS:BroadcastAssignments()
        assert.are.same({ "ASSIGN:Me:1:WARRIOR=kings" }, sends)
    end)

    it("re-broadcasts after combat when the send hit the addon message lockdown", function()
        result = LOCKDOWN
        BS:BroadcastAssignments()
        result = 0
        BS:OnEvent("PLAYER_REGEN_ENABLED")
        assert.are.equal(2, #sends)
        BS:OnEvent("PLAYER_REGEN_ENABLED")
        assert.are.equal(2, #sends)
    end)

    it("does not re-broadcast after combat when the send worked", function()
        BS:BroadcastAssignments()
        BS:OnEvent("PLAYER_REGEN_ENABLED")
        assert.are.equal(1, #sends)
    end)

    it("treats the TBC boolean return as success", function()
        _G.Enum = nil
        result = true
        BS:BroadcastAssignments()
        BS:OnEvent("PLAYER_REGEN_ENABLED")
        assert.are.equal(1, #sends)
    end)
end)

describe("BlessingSync receiving", function()
    local BS, known

    before_each(function()
        _G.PaladinToolsDB = nil
        _G.GetNumGroupMembers = function() return 2 end
        _G.UnitName = function(unit)
            if unit == "player" then return "Me" end
            if unit == "party1" then return "Lead" end
        end
        _G.UnitIsGroupLeader = function(unit) return unit == "party1" end
        BS = load()
        -- Forever spellbook: no Salvation, Sanctuary or Light
        known = {
            ["Greater Blessing of Might"] = 25916,
            ["Greater Blessing of Wisdom"] = 25918,
            ["Greater Blessing of Kings"] = 25898,
        }
        PaladinTools.FindSpellInBook = function(_, name) return known[name] end
    end)

    after_each(function()
        _G.GetNumGroupMembers = function() return 0 end
        _G.UnitName = function(unit) if unit == "player" then return "Me" end end
        _G.UnitIsGroupLeader = nil
    end)

    local function receive(text, sender)
        BS:HandleAddonMessage("PTools", text, "PARTY", sender)
    end

    it("drops unknown classes and blessing types from a broadcast", function()
        receive("ASSIGN:Other:1:BOGUS=kings,MAGE=wisdom,WARRIOR=fireball", "Other")
        assert.are.same({ MAGE = "wisdom" }, PaladinTools.syncState.Other)
    end)

    it("keeps every TBC blessing type in a broadcast", function()
        receive("ASSIGN:Other:1:MAGE=salvation,PRIEST=light,WARRIOR=sanctuary", "Other")
        assert.are.same({ MAGE = "salvation", PRIEST = "light", WARRIOR = "sanctuary" },
            PaladinTools.syncState.Other)
    end)

    it("ignores a broadcast whose name is not the sender", function()
        receive("ASSIGN:Victim:1:MAGE=kings", "Other")
        assert.is_nil(PaladinTools.syncState.Victim)
    end)

    it("accepts a broadcast from a sender with a realm suffix", function()
        receive("ASSIGN:Other:1:MAGE=kings", "Other-Lightborn")
        assert.are.same({ MAGE = "kings" }, PaladinTools.syncState.Other)
    end)

    it("applies an override from the leader", function()
        receive("OVERRIDE:Me:MAGE=kings,WARRIOR=might", "Lead")
        assert.are.same({ MAGE = "kings", WARRIOR = "might" }, PaladinToolsDB.blessingAssignments)
    end)

    it("drops overridden blessings the player does not know", function()
        receive("OVERRIDE:Me:MAGE=kings,WARRIOR=salvation,ROGUE=bogus", "Lead")
        assert.are.same({ MAGE = "kings" }, PaladinToolsDB.blessingAssignments)
    end)

    it("ignores an override from someone who is not the leader", function()
        PaladinToolsDB.blessingAssignments.MAGE = "wisdom"
        receive("OVERRIDE:Me:MAGE=kings", "Other")
        assert.are.same({ MAGE = "wisdom" }, PaladinToolsDB.blessingAssignments)
    end)
end)
