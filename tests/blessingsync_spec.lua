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
