require("tests.mocks.wow_api")

local function load()
    dofile("Core.lua")
    PaladinTools:InitDB()
    dofile("Data.lua")
    dofile("APICheck_Forever.lua")
    return PaladinTools.APICheck
end

local function find(lines, prefix)
    for _, line in ipairs(lines) do
        if line:sub(1, #prefix) == prefix then return line end
    end
end

describe("APICheck_Forever", function()
    local APICheck, savedPrint

    before_each(function()
        _G.PaladinToolsDB = nil
        savedPrint = _G.print
        _G.print = function() end
        _G.GetBuildInfo = function() return "1.60.1", "70938", "Nov 13 2026", 16001 end
        _G.IsInInstance = function() return true, "raid" end
        APICheck = load()
        PaladinTools.FindSpellInBook = function(_, name)
            if name == "Greater Blessing of Kings" then return 25898 end
        end
    end)

    after_each(function()
        _G.print = savedPrint
        _G.issecretvalue = nil
        _G.C_UnitAuras = nil
        _G.GetBuildInfo = nil
        _G.IsInInstance = nil
        _G.IsPlayerSpell = nil
    end)

    describe("Describe", function()
        it("shows plain scalars with their value", function()
            assert.are.equal("boolean:true", APICheck:Describe(true))
            assert.are.equal("number:5", APICheck:Describe(5))
            assert.are.equal("nil", APICheck:Describe(nil))
            assert.are.equal("string", APICheck:Describe("Bob"))
        end)

        it("flags secret values", function()
            local secret = {}
            _G.issecretvalue = function(v) return v == secret end
            assert.are.equal("secret", APICheck:Describe(secret))
        end)

        it("lists table fields in sorted order", function()
            assert.are.equal("{a=string,b=number:1}", APICheck:Describe({ b = 1, a = "x" }))
        end)
    end)

    describe("Call", function()
        it("reports a missing API", function()
            assert.are.equal("missing", APICheck:Call(nil))
        end)

        it("reports an error message", function()
            assert.matches("^error: .*secret", APICheck:Call(function() error("Auras cannot be accessed when secret") end))
        end)

        it("describes every return value", function()
            assert.are.equal("boolean:true string", APICheck:Call(IsInInstance))
        end)
    end)

    describe("Run", function()
        it("reports the probes and saves them for reading out of game", function()
            _G.IsPlayerSpell = function(id) return id == 20468 end
            _G.C_UnitAuras = {
                GetAuraDataByIndex = function() error("Auras cannot be accessed when secret") end,
            }
            local lines = APICheck:Run()
            assert.matches("1%.60%.1", find(lines, "build"))
            assert.matches("boolean:true string", find(lines, "IsInInstance"))
            assert.matches("^aura player: error", find(lines, "aura player"))
            assert.matches("boolean:true", find(lines, "IsPlayerSpell(20468)"))
            assert.matches("25898", find(lines, "book Greater Blessing of Kings"))
            assert.matches("nil", find(lines, "book Greater Blessing of Might"))
            assert.are.same(lines, PaladinToolsDB.apiReport.lines)
        end)

        it("records the payload of the player's last cast", function()
            APICheck:OnEvent("UNIT_SPELLCAST_SENT", "player", "Bob", "Cast-GUID", 25898)
            assert.matches("string number:25898", find(APICheck:Run(), "last UNIT_SPELLCAST_SENT"))
        end)

        it("records whether the last whisper text was secret", function()
            local secret = {}
            _G.issecretvalue = function(v) return v == secret end
            APICheck:OnEvent("CHAT_MSG_WHISPER", secret, "Bob-Realm")
            assert.matches("secret string", find(APICheck:Run(), "last whisper"))
        end)
    end)
end)
