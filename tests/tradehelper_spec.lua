require("tests.mocks.wow_api")

local function load()
    dofile("Core.lua")
    PaladinTools:InitDB()
    dofile("Data.lua")
    dofile("TradeHelper.lua")
    local TH = PaladinTools.modules["TradeHelper"]
    TH:Init()
    return TH
end

describe("TradeHelper whispers", function()
    local TH, sent, savedSend

    before_each(function()
        _G.PaladinToolsDB = nil
        sent = {}
        savedSend = _G.SendChatMessage
        _G.SendChatMessage = function(msg, chatType, lang, target)
            sent[#sent + 1] = { msg = msg, target = target }
        end
        TH = load()
    end)

    after_each(function()
        _G.SendChatMessage = savedSend
        _G.issecretvalue = nil
        _G.C_ChatInfo.InChatMessagingLockdown = nil
    end)

    it("queues a buff request and replies", function()
        TH:OnEvent("CHAT_MSG_WHISPER", "kings please", "Bob-Realm")
        assert.are.equal(1, TH:GetQueueSize())
        assert.are.equal(1, #sent)
        assert.are.equal("Bob", sent[1].target)
    end)

    it("ignores a whisper whose text is secret", function()
        local secret = {}
        _G.issecretvalue = function(v) return v == secret end
        assert.has_no.errors(function()
            TH:OnEvent("CHAT_MSG_WHISPER", secret, "Bob-Realm")
        end)
        assert.are.equal(0, TH:GetQueueSize())
    end)

    it("queues but does not reply while chat messaging is locked down", function()
        _G.C_ChatInfo.InChatMessagingLockdown = function() return true end
        TH:OnEvent("CHAT_MSG_WHISPER", "might", "Bob-Realm")
        assert.are.equal(1, TH:GetQueueSize())
        assert.are.equal(0, #sent)
        TH:RemoveFromQueue(1)
        assert.are.equal(0, #sent)
    end)
end)
