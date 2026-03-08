PaladinTools = {}
PaladinTools.modules = {}
PaladinTools.version = "1.0.1"
PaladinTools.initialized = false

-- Make a child frame propagate drag events to its movable parent
function PaladinTools:PropagateDrag(child)
    child:RegisterForDrag("LeftButton")
    child:HookScript("OnDragStart", function(self)
        local parent = self:GetParent()
        parent:StartMoving()
    end)
    child:HookScript("OnDragStop", function(self)
        local parent = self:GetParent()
        parent:StopMovingOrSizing()
        if parent.SavePosition then parent:SavePosition() end
    end)
end

local frame = CreateFrame("Frame")

local defaults = {
    hudVisible = true,
    hudX = 0,
    hudY = 0,
    hudPoint = "CENTER",
    whisperKeywords = { "buff", "blessing", "paladin", "kings", "might", "wisdom" },
    autoReply = true,
    queueVisible = true,
    hudButtonSize = 32,
    hudVertical = false,
    popupColumns = 5,
    popupCloseOnCast = true,
    listenPartyChat = false,
    popupButtonSize = 36,
    maxQueueDisplay = 10,
    popupKeybind = nil,
    hudShowReagents = true,
    hudHideInCombat = false,
    popupReleaseMode = true,
    popupCategories = { blessings = true, auras = true, seals = true },
    blessingAssignments = {},
}

function PaladinTools:RegisterModule(name, mod)
    self.modules[name] = mod
end

function PaladinTools:InitDB()
    PaladinToolsDB = PaladinToolsDB or {}
    for k, v in pairs(defaults) do
        if PaladinToolsDB[k] == nil then
            if type(v) == "table" then
                PaladinToolsDB[k] = {}
                for dk, dv in pairs(v) do
                    PaladinToolsDB[k][dk] = dv
                end
            else
                PaladinToolsDB[k] = v
            end
        elseif type(v) == "table" and type(PaladinToolsDB[k]) == "table" then
            -- Merge missing keys into existing table (e.g. new popupCategories entries)
            for dk, dv in pairs(v) do
                if PaladinToolsDB[k][dk] == nil then
                    PaladinToolsDB[k][dk] = dv
                end
            end
        end
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == "PaladinTools" then
            local _, englishClass = UnitClass("player")
            if englishClass ~= "PALADIN" then
                self:UnregisterEvent("ADDON_LOADED")
                return
            end
            PaladinTools:InitDB()
            PaladinTools.Masque:Init()
            for name, mod in pairs(PaladinTools.modules) do
                if mod.Init then
                    mod:Init()
                end
            end
            PaladinTools.initialized = true
            self:UnregisterEvent("ADDON_LOADED")
        end
        return
    end
    if not PaladinTools.initialized then return end
    for name, mod in pairs(PaladinTools.modules) do
        if mod.OnEvent then
            mod:OnEvent(event, ...)
        end
    end
end)

function PaladinTools:RegisterEvents(...)
    for i = 1, select("#", ...) do
        frame:RegisterEvent(select(i, ...))
    end
end

-- Slash commands
SLASH_PALADINTOOLS1 = "/paladintools"
SLASH_PALADINTOOLS2 = "/pt"
SlashCmdList["PALADINTOOLS"] = function(msg)
    local cmd = strlower(strtrim(msg))
    if cmd == "popup" then
        local pm = PaladinTools.modules["PopupMenu"]
        if pm then PaladinTools_TogglePopup() end
    elseif cmd == "hud" then
        local bm = PaladinTools.modules["BuffManager"]
        if bm then bm:ToggleHUD() end
    elseif cmd == "session" then
        local pm = PaladinTools.modules["PopupMenu"]
        if pm then PaladinTools_TogglePopup() end
    elseif cmd == "queue" then
        local th = PaladinTools.modules["TradeHelper"]
        if th then th:ToggleQueue() end
    elseif cmd == "tour" then
        local tour = PaladinTools.modules["Tour"]
        if tour then tour:Start() end
    elseif cmd == "whatsnew" then
        local wn = PaladinTools.modules["WhatsNew"]
        if wn then wn:Show() end
    elseif cmd == "options" then
        local opts = PaladinTools.modules["Options"]
        if opts then opts:Toggle() end
    elseif cmd == "config" then
        print("|cffF58CBAPaladinTools|r config:")
        print("  HUD visible: " .. tostring(PaladinToolsDB.hudVisible))
        print("  Auto-reply: " .. tostring(PaladinToolsDB.autoReply))
        print("  Keywords: " .. table.concat(PaladinToolsDB.whisperKeywords, ", "))
    else
        local wn = PaladinTools.modules["WhatsNew"]
        if wn and wn:ShouldShow() then
            wn:Show()
        else
            print("|cffF58CBAPaladinTools|r commands:")
            print("  /pt popup - Toggle spell menu")
            print("  /pt hud - Toggle HUD")
            print("  /pt session - Blessing session")
            print("  /pt queue - Toggle buff queue")
            print("  /pt options - Open options panel")
            print("  /pt tour - Start onboarding tour")
            print("  /pt whatsnew - View changelog")
            print("  /pt config - Show config")
        end
    end
end
