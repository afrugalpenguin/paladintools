local PT = PaladinTools
local WN = {}
PT:RegisterModule("WhatsNew", WN)

local whatsNewFrame = nil

local changelog = {
    {
        version = "1.1.0",
        features = {
            "Blessings Manager: horizontal class grid on popup with timer overlays",
            "Symbol of Divinity tracking on HUD",
            "Debug commands: /fakeraid and /fakeparty for UI testing",
            "Tour now demos the Blessings Manager with a fake party",
        },
        fixes = {
            "Blessing assignment changes now immediately rescan buff status",
        },
    },
    {
        version = "1.0.1",
        features = {},
        fixes = {
            "Fixed inaccurate HUD and Blessing Manager descriptions",
            "Renamed Trade Helper to Buff Helper",
        },
    },
    {
        version = "1.0.0",
        features = {
            "Onboarding tour: /pt tour walks through addon features",
        },
        fixes = {},
    },
    {
        version = "0.1.0",
        features = {
            "Initial release: blessings, auras, seals popup menu",
            "Reagent tracking HUD (Symbol of Kings)",
            "Buff request whisper queue",
            "Blessing manager",
            "Tabbed options panel",
            "Masque support",
        },
        fixes = {},
    },
}

function WN:GetChangelog()
    return changelog
end

function WN:ShouldShow()
    local currentVersion = PT.version
    local lastSeen = PaladinToolsDB.lastSeenVersion
    return lastSeen == nil or lastSeen ~= currentVersion
end

function WN:MarkAsSeen()
    PaladinToolsDB.lastSeenVersion = PT.version
end

-- Modal UI

local function CreateWhatsNewFrame()
    -- Dim overlay
    local overlay = CreateFrame("Frame", nil, UIParent)
    overlay:SetAllPoints()
    overlay:SetFrameStrata("FULLSCREEN_DIALOG")
    overlay:SetFrameLevel(199)
    overlay:EnableMouse(true)
    local overlayTex = overlay:CreateTexture(nil, "BACKGROUND")
    overlayTex:SetAllPoints()
    overlayTex:SetColorTexture(0, 0, 0, 0.5)
    overlay:Hide()

    -- Main frame
    local f = CreateFrame("Frame", "PaladinToolsWhatsNew", UIParent, "BackdropTemplate")
    f:SetSize(420, 360)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(200)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetClampedToScreen(true)
    f:Hide()

    f:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.08, 0.08, 0.12, 0.98)
    f:SetBackdropBorderColor(0.96, 0.55, 0.73, 1)

    tinsert(UISpecialFrames, "PaladinToolsWhatsNew")

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cffF58CBAWhat's New in PaladinTools v" .. PT.version .. "|r")
    f.title = title

    -- Decorative line
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -36)
    line:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -36)
    line:SetColorTexture(0.96, 0.55, 0.73, 0.5)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "PaladinToolsWhatsNewScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -42)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 44)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    -- Got it button
    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetSize(100, 26)
    btn:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    btn:SetText("Got it!")
    btn:SetScript("OnClick", function()
        WN:Hide()
    end)

    f.overlay = overlay
    return f
end

local function PopulateChangelog(frame)
    local children = { frame.scrollChild:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end

    local scrollWidth = frame.scrollChild:GetWidth()
    if scrollWidth < 10 then scrollWidth = 370 end
    local yOffset = 0

    for i, entry in ipairs(changelog) do
        local header = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, yOffset)
        header:SetWidth(scrollWidth)
        header:SetJustifyH("LEFT")
        if entry.version == PT.version then
            header:SetText("|cffFFCC00Version " .. entry.version .. " (Current)|r")
        else
            header:SetText("|cff888888Version " .. entry.version .. "|r")
        end
        yOffset = yOffset - 20

        if entry.features and #entry.features > 0 then
            local label = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 4, yOffset)
            label:SetText("|cffF58CBAFeatures:|r")
            yOffset = yOffset - 16

            for _, feat in ipairs(entry.features) do
                local text = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                text:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 12, yOffset)
                text:SetWidth(scrollWidth - 20)
                text:SetJustifyH("LEFT")
                text:SetText("|cffcccccc-|r " .. feat)
                local height = text:GetStringHeight()
                yOffset = yOffset - height - 2
            end
            yOffset = yOffset - 4
        end

        if entry.fixes and #entry.fixes > 0 then
            local label = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 4, yOffset)
            label:SetText("|cff88ff88Fixes:|r")
            yOffset = yOffset - 16

            for _, fix in ipairs(entry.fixes) do
                local text = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                text:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 12, yOffset)
                text:SetWidth(scrollWidth - 20)
                text:SetJustifyH("LEFT")
                text:SetText("|cffcccccc-|r " .. fix)
                local height = text:GetStringHeight()
                yOffset = yOffset - height - 2
            end
            yOffset = yOffset - 4
        end

        yOffset = yOffset - 12
    end

    frame.scrollChild:SetHeight(math.abs(yOffset))
end

function WN:Show()
    if not whatsNewFrame then
        whatsNewFrame = CreateWhatsNewFrame()
    end
    whatsNewFrame.title:SetText("|cffF58CBAWhat's New in PaladinTools v" .. PT.version .. "|r")
    PopulateChangelog(whatsNewFrame)
    whatsNewFrame.overlay:Show()
    whatsNewFrame:Show()
end

function WN:Hide()
    if whatsNewFrame then
        whatsNewFrame:Hide()
        whatsNewFrame.overlay:Hide()
    end
    self:MarkAsSeen()
end

function WN:IsShown()
    return whatsNewFrame and whatsNewFrame:IsShown()
end
