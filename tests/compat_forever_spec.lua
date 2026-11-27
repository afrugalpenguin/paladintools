require("tests.mocks.wow_api")

local SPELL, FUTURE = 1, 2

-- Fake C_SpellBook: skill lines of { name, spellID, itemType }
local function setSpellBook(lines)
    local items = {}
    local skillLines = {}
    for _, line in ipairs(lines) do
        skillLines[#skillLines + 1] = { itemIndexOffset = #items, numSpellBookItems = #line }
        for _, entry in ipairs(line) do
            items[#items + 1] = { name = entry[1], spellID = entry[2], actionID = entry[2], itemType = entry[3] or SPELL }
        end
    end
    _G.C_SpellBook = {
        GetNumSpellBookSkillLines = function() return #skillLines end,
        GetSpellBookSkillLineInfo = function(i) return skillLines[i] end,
        GetSpellBookItemInfo = function(i) return items[i] end,
    }
end

local function load()
    dofile("Core.lua")
    dofile("Compat_Forever.lua")
end

describe("Compat_Forever", function()
    before_each(function()
        _G.GetSpellInfo = nil
        _G.GetItemIcon = nil
        _G.Enum = {
            SpellBookSpellBank = { Player = 0 },
            SpellBookItemType = { None = 0, Spell = SPELL, FutureSpell = FUTURE },
        }
        _G.C_Spell = {
            GetSpellInfo = function(id)
                if id == 25898 then
                    return { name = "Greater Blessing of Kings", iconID = 135993, castTime = 0, minRange = 0, maxRange = 40, spellID = 25898 }
                end
            end,
        }
        _G.C_Item = { GetItemIconByID = function(id) return id == 21177 and 134000 or nil end }
        setSpellBook({})
    end)

    after_each(function()
        _G.C_Spell = nil
        _G.C_Item = nil
        _G.C_SpellBook = nil
        _G.Enum = nil
    end)

    it("marks the addon as the Forever build", function()
        load()
        assert.is_true(PaladinTools.isForever)
    end)

    describe("GetSpellInfo", function()
        it("recreates the TBC return order from C_Spell", function()
            load()
            local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(25898)
            assert.are.equal("Greater Blessing of Kings", name)
            assert.is_nil(rank)
            assert.are.equal(135993, icon)
            assert.are.equal(0, castTime)
            assert.are.equal(0, minRange)
            assert.are.equal(40, maxRange)
            assert.are.equal(25898, spellID)
        end)

        it("returns nil for an unknown spell", function()
            load()
            assert.is_nil(GetSpellInfo(27141))
        end)

        it("leaves a native GetSpellInfo alone", function()
            local native = function() return "native" end
            _G.GetSpellInfo = native
            load()
            assert.are.equal(native, GetSpellInfo)
        end)
    end)

    it("maps GetItemIcon to C_Item.GetItemIconByID", function()
        load()
        assert.are.equal(134000, GetItemIcon(21177))
    end)

    describe("SendChatMessage", function()
        local savedSend
        before_each(function() savedSend = _G.SendChatMessage end)
        after_each(function() _G.SendChatMessage = savedSend end)

        it("falls back to C_ChatInfo.SendChatMessage when the global is missing", function()
            _G.SendChatMessage = nil
            local sent
            _G.C_ChatInfo.SendChatMessage = function(msg, chatType, lang, target) sent = { msg, chatType, target } end
            load()
            SendChatMessage("hi", "WHISPER", nil, "Bob")
            assert.are.same({ "hi", "WHISPER", "Bob" }, sent)
            _G.C_ChatInfo.SendChatMessage = nil
        end)

        it("keeps a native global", function()
            local native = function() end
            _G.SendChatMessage = native
            load()
            assert.are.equal(native, SendChatMessage)
        end)
    end)

    describe("FindSpellInBook", function()
        it("finds a learned spell across skill lines", function()
            setSpellBook({
                { { "Attack", 6603 } },
                { { "Blessing of Might", 19740 }, { "Blessing of Might", 19834 }, { "Seal of Fury", 1311649 } },
            })
            load()
            assert.are.equal(19834, PaladinTools:FindSpellInBook("Blessing of Might"))
            assert.are.equal(1311649, PaladinTools:FindSpellInBook("Seal of Fury"))
        end)

        it("ignores spells the player has not learned yet", function()
            setSpellBook({
                { { "Greater Blessing of Kings", 25898, FUTURE }, { "Blessing of Kings", 20217 } },
            })
            load()
            assert.is_nil(PaladinTools:FindSpellInBook("Greater Blessing of Kings"))
            assert.are.equal(20217, PaladinTools:FindSpellInBook("Blessing of Kings"))
        end)

        it("returns nil for spells that are not in the book", function()
            setSpellBook({ { { "Seal of Righteousness", 20154 } } })
            load()
            assert.is_nil(PaladinTools:FindSpellInBook("Blessing of Sanctuary"))
        end)
    end)
end)
