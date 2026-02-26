local PT = PaladinTools
local TH = {}
PT:RegisterModule("TradeHelper", TH)

local queue = {}  -- { { name = "Player", request = "kings" }, ... }
local queueFrame = nil
local queueButtons = {}

function TH:Init()
    self:CreateQueueFrame()
    self:UpdateQueueDisplay()
    PT:RegisterEvents("CHAT_MSG_WHISPER", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER")
end

function TH:GetQueueSize()
    return #queue
end

-- Whisper handling
function TH:MatchKeyword(msg)
    msg = strlower(msg)
    local matched = {}
    for _, keyword in ipairs(PaladinToolsDB.whisperKeywords) do
        local lk = strlower(keyword)
        if strfind(msg, lk) then
            if lk == "kings" then
                matched.kings = true
            elseif lk == "might" then
                matched.might = true
            elseif lk == "wisdom" then
                matched.wisdom = true
            else
                -- Generic keywords (e.g. "buff", "blessing", "paladin") request kings
                matched.kings = true
            end
        end
    end
    if matched.kings then
        return "kings"
    elseif matched.might then
        return "might"
    elseif matched.wisdom then
        return "wisdom"
    end
    return nil
end

local function NotifyBlessingSession()
    local bm = PT.modules["BuffManager"]
    if bm and bm.UpdateSessionIfShown then
        bm:UpdateSessionIfShown()
    end
end

function TH:AddToQueue(name, request)
    -- Check for duplicates, update existing
    for _, entry in ipairs(queue) do
        if entry.name == name then
            entry.request = request
            self:UpdateQueueDisplay()
            NotifyBlessingSession()
            return
        end
    end
    tinsert(queue, { name = name, request = request })
    self:UpdateQueueDisplay()
    NotifyBlessingSession()

    if PaladinToolsDB.autoReply then
        local position = #queue
        SendChatMessage("You're queued for " .. request .. ". " .. (position - 1) .. " ahead of you.", "WHISPER", nil, name)
    end

    -- Show queue frame if hidden
    if not queueFrame:IsShown() then
        queueFrame:Show()
    end
end

function TH:RemoveFromQueue(index)
    local entry = tremove(queue, index)
    if entry and PaladinToolsDB.autoReply then
        SendChatMessage("Blessed!", "WHISPER", nil, entry.name)
    end
    self:UpdateQueueDisplay()
    NotifyBlessingSession()
    if #queue == 0 then
        queueFrame:Hide()
    end
end

-- Queue Frame
function TH:CreateQueueFrame()
    queueFrame = CreateFrame("Frame", "PaladinToolsQueue", UIParent, "BackdropTemplate")
    queueFrame:SetSize(200, 40)
    queueFrame:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    queueFrame:SetFrameStrata("MEDIUM")
    queueFrame:SetClampedToScreen(true)
    queueFrame:SetMovable(true)
    queueFrame:EnableMouse(true)
    queueFrame:RegisterForDrag("LeftButton")
    queueFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    queueFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    queueFrame:Hide()

    tinsert(UISpecialFrames, "PaladinToolsQueue")

    queueFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    queueFrame:SetBackdropColor(0, 0, 0, 0.8)

    -- Title
    local title = queueFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", 0, -6)
    title:SetText("|cffF58CBABuff Queue|r")
    queueFrame.title = title

    -- Blessing session shortcut button
    local sessBtn = CreateFrame("Button", nil, queueFrame)
    sessBtn:SetSize(14, 14)
    sessBtn:SetPoint("TOPRIGHT", queueFrame, "TOPRIGHT", -6, -4)
    local sessIcon = sessBtn:CreateTexture(nil, "ARTWORK")
    sessIcon:SetAllPoints()
    sessIcon:SetTexture("Interface\\Icons\\Spell_Holy_GreaterBlessingofKings")
    sessIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local sessHL = sessBtn:CreateTexture(nil, "HIGHLIGHT")
    sessHL:SetAllPoints()
    sessHL:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    sessHL:SetBlendMode("ADD")
    sessBtn:SetScript("OnClick", function()
        local bm = PT.modules["BuffManager"]
        if bm then bm:ToggleBlessingSession() end
    end)
    sessBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Open Blessing Session")
        GameTooltip:Show()
    end)
    sessBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    PT:PropagateDrag(sessBtn)

    -- Create row buttons (SecureActionButton to auto-target on click)
    for i = 1, PaladinToolsDB.maxQueueDisplay do
        local row = CreateFrame("Button", "PaladinToolsQueueRow" .. i, queueFrame, "SecureActionButtonTemplate")
        row:SetSize(180, 18)
        row:SetPoint("TOP", queueFrame, "TOP", 0, -8 - (i * 18))
        row:RegisterForClicks("AnyUp")
        row:SetAttribute("type1", "macro")

        local tmplNormal = row:GetNormalTexture()
        if tmplNormal then tmplNormal:SetTexture(nil); tmplNormal:Hide() end

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", 6, 0)
        row.nameText = nameText

        local reqText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        reqText:SetPoint("RIGHT", -6, 0)
        row.reqText = reqText

        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

        row:SetScript("PostClick", function(self, button)
            if not queue[i] then return end
            if button == "RightButton" then
                TH:RemoveFromQueue(i)
            else
                print("|cffF58CBAPaladinTools|r Targeting " .. queue[i].name .. " for " .. queue[i].request .. ".")
            end
        end)

        PT:PropagateDrag(row)
        row:Hide()
        tinsert(queueButtons, row)
    end
end

function TH:UpdateQueueDisplay()
    local maxDisplay = math.min(PaladinToolsDB.maxQueueDisplay, #queueButtons)
    local visibleCount = math.min(#queue, maxDisplay)
    for i = 1, maxDisplay do
        if i <= visibleCount then
            local entry = queue[i]
            queueButtons[i].nameText:SetText(entry.name)
            queueButtons[i].reqText:SetText("|cffaaaaaa" .. entry.request .. "|r")
            queueButtons[i]:SetAttribute("macrotext1", "/target " .. entry.name)
            queueButtons[i]:Show()
        else
            queueButtons[i]:SetAttribute("macrotext1", "")
            queueButtons[i]:Hide()
        end
    end
    local height = 28 + (visibleCount * 18)
    queueFrame:SetSize(200, math.max(40, height))
end

function TH:RebuildQueue()
    if not queueFrame then return end
    local maxDisplay = PaladinToolsDB.maxQueueDisplay
    for i = #queueButtons + 1, maxDisplay do
        local row = CreateFrame("Button", "PaladinToolsQueueRow" .. i, queueFrame, "SecureActionButtonTemplate")
        row:SetSize(180, 18)
        row:SetPoint("TOP", queueFrame, "TOP", 0, -8 - (i * 18))
        row:RegisterForClicks("AnyUp")
        row:SetAttribute("type1", "macro")
        local tmplNormal = row:GetNormalTexture()
        if tmplNormal then tmplNormal:SetTexture(nil); tmplNormal:Hide() end
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", 6, 0)
        row.nameText = nameText
        local reqText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        reqText:SetPoint("RIGHT", -6, 0)
        row.reqText = reqText
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row:SetScript("PostClick", function(self, button)
            if not queue[i] then return end
            if button == "RightButton" then
                TH:RemoveFromQueue(i)
            else
                print("|cffF58CBAPaladinTools|r Targeting " .. queue[i].name .. " for " .. queue[i].request .. ".")
            end
        end)
        PT:PropagateDrag(row)
        row:Hide()
        tinsert(queueButtons, row)
    end
    self:UpdateQueueDisplay()
end

function TH:ToggleQueue()
    if queueFrame:IsShown() then
        queueFrame:Hide()
        PaladinToolsDB.queueVisible = false
    else
        queueFrame:Show()
        PaladinToolsDB.queueVisible = true
    end
end

function TH:OnEvent(event, ...)
    if event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        local request = self:MatchKeyword(msg)
        if request then
            local name = strsplit("-", sender)
            self:AddToQueue(name, request)
        end
    elseif (event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER") then
        if PaladinToolsDB.listenPartyChat then
            local msg, sender = ...
            local request = self:MatchKeyword(msg)
            if request then
                local name = strsplit("-", sender)
                self:AddToQueue(name, request)
            end
        end
    end
end
