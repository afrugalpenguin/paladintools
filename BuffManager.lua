local PT = PaladinTools
local BM = {}
PT:RegisterModule("BuffManager", BM)

local hudFrame = nil
local sessionFrame = nil
local counts = { symbolOfKings = 0, symbolOfDivinity = 0 }
local foundItem = { symbolOfKings = nil, symbolOfDivinity = nil }
local hudButtons = {}

function BM:Init()
    self:ScanBags()
    self:CreateHUD()
    self:CreateBlessingSession()
    if PaladinToolsDB.hudVisible then
        hudFrame:Show()
    else
        hudFrame:Hide()
    end
    PT:RegisterEvents("BAG_UPDATE", "BAG_UPDATE_DELAYED", "PLAYER_ENTERING_WORLD",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED")
end

-- Bag scanning
function BM:ScanBags()
    counts.symbolOfKings = 0
    counts.symbolOfDivinity = 0
    foundItem.symbolOfKings = nil
    foundItem.symbolOfDivinity = nil
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local itemType = PT.TRACKED_ITEM_SET[info.itemID]
                if itemType then
                    counts[itemType] = counts[itemType] + (info.stackCount or 0)
                    if not foundItem[itemType] then
                        foundItem[itemType] = info.itemID
                    end
                end
            end
        end
    end

    self:UpdateDisplays()
end

function BM:GetCounts()
    return counts
end

function BM:UpdateDisplays()
    -- Update HUD counts and icons
    for _, btn in ipairs(hudButtons) do
        local count = counts[btn.itemType] or 0
        btn.countText:SetText(count > 0 and count or "0")
        local itemID = foundItem[btn.itemType] or btn.defaultItemID
        local icon = GetItemIcon(itemID)
        if icon then btn.icon:SetTexture(icon) end
    end

    self:RebuildHUD()

    -- Update blessing session if open
    if sessionFrame and sessionFrame:IsShown() then
        self:UpdateSessionProgress()
    end
end

-- HUD
function BM:CreateHUD()
    hudFrame = CreateFrame("Frame", "PaladinToolsHUD", UIParent, "BackdropTemplate")
    local btnSize = PaladinToolsDB.hudButtonSize
    hudFrame:SetSize(btnSize + 16, btnSize + 16)
    hudFrame:SetPoint(
        PaladinToolsDB.hudPoint or "CENTER",
        UIParent,
        PaladinToolsDB.hudPoint or "CENTER",
        PaladinToolsDB.hudX or 0,
        PaladinToolsDB.hudY or 0
    )
    hudFrame:SetFrameStrata("LOW")
    hudFrame:SetClampedToScreen(true)
    hudFrame:SetMovable(true)
    hudFrame:EnableMouse(true)
    hudFrame:RegisterForDrag("LeftButton")
    hudFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    hudFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SavePosition()
    end)
    function hudFrame:SavePosition()
        local point, _, _, x, y = self:GetPoint()
        PaladinToolsDB.hudPoint = point
        PaladinToolsDB.hudX = x
        PaladinToolsDB.hudY = y
    end

    hudFrame:SetBackdrop(nil)

    local categories = {
        { type = "symbolOfKings", itemID = PT.SYMBOL_OF_KINGS, reagent = true },
    }

    local visIndex = 0
    for _, cat in ipairs(categories) do
        local defaultID = cat.itemID
        local btn = CreateFrame("Button", "PaladinToolsHUD" .. cat.type, hudFrame)
        btn:SetSize(btnSize, btnSize)

        local iconPath = GetItemIcon(defaultID)
        local iconTex = btn:CreateTexture(nil, "BACKGROUND")
        iconTex:SetAllPoints()
        if iconPath then iconTex:SetTexture(iconPath) end
        btn.icon = iconTex

        local normalTex
        if PT.Masque:IsEnabled() then
            normalTex = btn:CreateTexture(nil, "OVERLAY")
            normalTex:SetAllPoints()
            btn:SetNormalTexture(normalTex)
        end

        local countText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
        countText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        btn.countText = countText
        btn.itemType = cat.type
        btn.defaultItemID = defaultID
        btn.isReagent = cat.reagent or false

        PT.Masque:AddButton("HUD", btn, {
            Icon = iconTex,
            Normal = normalTex,
        })

        PT:PropagateDrag(btn)
        tinsert(hudButtons, btn)

        local hidden = false
        if btn.isReagent and not PaladinToolsDB.hudShowReagents then
            hidden = true
        end

        if hidden then
            btn:Hide()
        else
            visIndex = visIndex + 1
            btn:ClearAllPoints()
            if PaladinToolsDB.hudVertical then
                btn:SetPoint("TOP", hudFrame, "TOP", 0, -8 - ((visIndex - 1) * (btnSize + 2)))
            else
                btn:SetPoint("LEFT", hudFrame, "LEFT", 8 + ((visIndex - 1) * (btnSize + 2)), 0)
            end
        end
    end

    local numVisible = visIndex
    if PaladinToolsDB.hudVertical then
        hudFrame:SetSize(btnSize + 16, (btnSize * numVisible) + ((numVisible - 1) * 2) + 16)
    else
        hudFrame:SetSize((btnSize * numVisible) + ((numVisible - 1) * 2) + 16, btnSize + 16)
    end

    PT.Masque:ReSkin("HUD")
end

function BM:ToggleHUD()
    if hudFrame:IsShown() then
        hudFrame:Hide()
        PaladinToolsDB.hudVisible = false
        print("|cffF58CBAPaladinTools|r HUD hidden.")
    else
        hudFrame:Show()
        PaladinToolsDB.hudVisible = true
        print("|cffF58CBAPaladinTools|r HUD shown.")
    end
end

function BM:RebuildHUD()
    if not hudFrame then return end
    local btnSize = PaladinToolsDB.hudButtonSize
    local vertical = PaladinToolsDB.hudVertical
    local showReagents = PaladinToolsDB.hudShowReagents

    local visIndex = 0
    for _, btn in ipairs(hudButtons) do
        btn:SetSize(btnSize, btnSize)
        btn:ClearAllPoints()

        local hidden = false
        if btn.isReagent and not showReagents then
            hidden = true
        end

        if hidden then
            btn:Hide()
        else
            btn:Show()
            visIndex = visIndex + 1
            if vertical then
                btn:SetPoint("TOP", hudFrame, "TOP", 0, -8 - ((visIndex - 1) * (btnSize + 2)))
            else
                btn:SetPoint("LEFT", hudFrame, "LEFT", 8 + ((visIndex - 1) * (btnSize + 2)), 0)
            end
        end
    end

    if vertical then
        hudFrame:SetSize(btnSize + 16, (btnSize * visIndex) + ((visIndex - 1) * 2) + 16)
    else
        hudFrame:SetSize((btnSize * visIndex) + ((visIndex - 1) * 2) + 16, btnSize + 16)
    end
end

-- Blessing Session
function BM:CreateBlessingSession()
    sessionFrame = CreateFrame("Frame", "PaladinToolsBlessingSession", UIParent, "BackdropTemplate")
    sessionFrame:SetSize(220, 140)
    sessionFrame:SetPoint("CENTER")
    sessionFrame:SetFrameStrata("HIGH")
    sessionFrame:SetClampedToScreen(true)
    sessionFrame:SetMovable(true)
    sessionFrame:EnableMouse(true)
    sessionFrame:RegisterForDrag("LeftButton")
    sessionFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    sessionFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    sessionFrame:Hide()

    tinsert(UISpecialFrames, "PaladinToolsBlessingSession")

    sessionFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    sessionFrame:SetBackdropColor(0, 0, 0, PaladinToolsDB.sessionBgAlpha)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, sessionFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", sessionFrame, "TOPRIGHT", -2, -2)

    -- Title
    local title = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cffF58CBABlessing Session|r")

    -- Group size display
    local groupText = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    groupText:SetPoint("TOP", 0, -32)
    sessionFrame.groupText = groupText

    -- Reagent count
    local reagentText = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reagentText:SetPoint("TOP", 0, -52)
    sessionFrame.reagentText = reagentText

    -- Status
    local statusText = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontGreen")
    statusText:SetPoint("TOP", 0, -76)
    sessionFrame.statusText = statusText
end

function BM:GetGroupSize()
    local groupSize = GetNumGroupMembers()
    return math.max(1, groupSize)
end

function BM:UpdateSessionProgress()
    local groupSize = self:GetGroupSize()

    sessionFrame.groupText:SetText("Group size: " .. groupSize)
    sessionFrame.reagentText:SetText("Symbol of Kings: " .. counts.symbolOfKings)

    if counts.symbolOfKings >= groupSize then
        sessionFrame.statusText:SetText("Reagents ready!")
    else
        local needed = groupSize - counts.symbolOfKings
        sessionFrame.statusText:SetText("Need " .. needed .. " more symbols")
    end
end

function BM:UpdateSessionIfShown()
    if sessionFrame and sessionFrame:IsShown() then
        self:UpdateSessionProgress()
    end
end

function BM:ToggleBlessingSession()
    if sessionFrame:IsShown() then
        sessionFrame:Hide()
    else
        self:UpdateSessionProgress()
        sessionFrame:Show()
    end
end

function BM:OnEvent(event, ...)
    if event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
        self:ScanBags()
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin = ...
        if isInitialLogin and PaladinToolsDB.showSessionOnLogin then
            self:UpdateSessionProgress()
            sessionFrame:Show()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if PaladinToolsDB.hudHideInCombat and PaladinToolsDB.hudVisible and hudFrame then
            hudFrame:Hide()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if PaladinToolsDB.hudHideInCombat and PaladinToolsDB.hudVisible and hudFrame then
            hudFrame:Show()
        end
    end
end
