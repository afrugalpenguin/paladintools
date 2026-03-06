local PT = PaladinTools
local PM = {}
PT:RegisterModule("PopupMenu", PM)

local popup = nil
local buttons = {}
local labels = {}
local BUTTON_PADDING = 4
local BLOCK_GAP = 6
local BLOCK_COLS = 99  -- no wrapping, each category stays on one row

-- Scan the spellbook for the highest rank of a spell by name
local function FindSpellInBook(targetName)
    local foundID
    local i = 1
    while true do
        local name = GetSpellBookItemName(i, BOOKTYPE_SPELL)
        if not name then break end
        if name == targetName then
            local _, id = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
            foundID = id  -- last match = highest rank
        end
        i = i + 1
    end
    return foundID
end

-- Binding header and name (for Key Bindings UI)
BINDING_HEADER_PALADINTOOLS = "PaladinTools"
BINDING_NAME_PALADINTOOLS_POPUP = "Toggle Spell Menu"

function PaladinTools_TogglePopup()
    if not popup or InCombatLockdown() then return end
    if popup:IsShown() then
        popup:Hide()
    else
        PM:ShowAtCursor()
    end
end

local toggleBtn = nil

function PM:Init()
    self:CreateToggleButton()
    self:UpdateReleaseMode()
    self:CreatePopup()
    self:ApplyKeybind()
    self:UpdateCloseOnCast()
    PT:RegisterEvents("SPELLS_CHANGED", "PLAYER_REGEN_ENABLED")
end

function PM:CreateToggleButton()
    toggleBtn = CreateFrame("Button", "PaladinToolsPopupToggle", UIParent, "SecureActionButtonTemplate")
    RegisterAttributeDriver(toggleBtn, "state-combat", "[combat] 1; nil")
    toggleBtn:SetSize(1, 1)
    toggleBtn:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -100, 100)
    toggleBtn:RegisterForClicks("AnyDown", "AnyUp")

    -- Position popup at cursor (insecure — only called out of combat)
    function toggleBtn:PT_PositionPopup()
        if popup then
            popup:ClearAllPoints()
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            popup:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
        end
    end

    SecureHandlerWrapScript(toggleBtn, "OnClick", toggleBtn, [[
        -- Clear stale cast attributes so template doesn't act on previous state
        self:SetAttribute("type", nil)
        self:SetAttribute("typerelease", nil)

        local rm = self:GetAttribute("releasemode")
        local sp = self:GetAttribute("ptspell")
        local isOpen = self:GetAttribute("popupopen")
        local p = self:GetFrameRef("popup")

        if not rm then
            -- Toggle mode: show/hide popup directly from secure code
            if p:IsShown() then
                p:Hide()
            else
                if not self:GetAttribute("state-combat") then
                    self:CallMethod("PT_PositionPopup")
                else
                    p:ClearAllPoints()
                    p:SetPoint("CENTER")
                end
                p:Show()
            end
            return
        end

        if not isOpen then
            -- First press (or key-down): show popup
            self:SetAttribute("ptspell", nil)
            self:SetAttribute("popupopen", 1)
            if not self:GetAttribute("state-combat") then
                self:CallMethod("PT_PositionPopup")
            else
                p:ClearAllPoints()
                p:SetPoint("CENTER")
            end
            p:Show()
        elseif sp then
            -- Second press (or key-up after hover): cast spell
            self:SetAttribute("popupopen", nil)
            p:Hide()
            self:SetAttribute("pressAndHoldAction", 1)
            self:SetAttribute("type", "spell")
            self:SetAttribute("typerelease", "spell")
            self:SetAttribute("spell", sp)
            return "cast"
        else
            -- Second press (or key-up) without hover: cancel
            self:SetAttribute("popupopen", nil)
            p:Hide()
        end
    ]])
end

function PM:UpdateReleaseMode()
    if toggleBtn then
        toggleBtn:SetAttribute("releasemode", PaladinToolsDB.popupReleaseMode and true or nil)
    end
end

function PM:ApplyKeybind()
    if not toggleBtn then return end
    ClearOverrideBindings(toggleBtn)
    local key = PaladinToolsDB.popupKeybind
    if key then
        SetOverrideBindingClick(toggleBtn, true, key, "PaladinToolsPopupToggle")
    end
end

function PM:CreatePopup()
    popup = CreateFrame("Frame", "PaladinToolsPopup", UIParent, "BackdropTemplate")
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup:Hide()
    popup:EnableMouse(false)

    -- Close on Escape
    tinsert(UISpecialFrames, "PaladinToolsPopup")

    popup:SetBackdrop(nil)

    -- Register popup as a frame ref so secure handlers can Show/Hide/position it
    SecureHandlerSetFrameRef(toggleBtn, "popup", popup)

    popup:SetScript("OnHide", function()
        if not InCombatLockdown() then
            PM:ApplyKeybind()
            if toggleBtn then
                toggleBtn:SetAttribute("type", nil)
                toggleBtn:SetAttribute("spell", nil)
                toggleBtn:SetAttribute("ptspell", nil)
                toggleBtn:SetAttribute("popupopen", nil)
            end
        end
    end)

    self:BuildButtons()
end

local function CreateSpellButton(spell, prefix, index)
    local btnSize = PaladinToolsDB.popupButtonSize
    local btn = CreateFrame("Button", "PaladinTools" .. prefix .. "Btn" .. index, popup, "SecureActionButtonTemplate")
    btn:SetSize(btnSize, btnSize)

    btn:SetAttribute("type", "spell")
    local spellName, _, icon = GetSpellInfo(spell.spellID)
    btn:SetAttribute("spell", spellName)
    btn:RegisterForClicks("AnyUp", "AnyDown")

    -- Clear any template-injected normal texture
    local tmplNormal = btn:GetNormalTexture()
    if tmplNormal then
        tmplNormal:SetTexture(nil)
        tmplNormal:Hide()
    end

    -- Icon
    local iconTex = btn:CreateTexture(nil, "ARTWORK")
    iconTex:SetPoint("TOPLEFT", 1, -1)
    iconTex:SetPoint("BOTTOMRIGHT", -1, 1)
    iconTex:SetTexture(icon)
    btn.icon = iconTex

    -- Masque skinning
    local normalTex, highlightTex
    if PT.Masque:IsEnabled() then
        normalTex = btn:CreateTexture(nil, "OVERLAY")
        normalTex:SetAllPoints()
        btn:SetNormalTexture(normalTex)
    else
        -- Thin border around icon
        local border = btn:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints()
        border:SetColorTexture(0, 0, 0, 1)
    end

    highlightTex = btn:CreateTexture(nil, "HIGHLIGHT")
    highlightTex:SetAllPoints()
    highlightTex:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlightTex:SetBlendMode("ADD")
    btn:SetHighlightTexture(highlightTex)

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(spell.spellID)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Release-to-cast: secure snippet tracks hovered spell on toggleBtn
    SecureHandlerWrapScript(btn, "OnEnter", toggleBtn, [[
        if owner:GetAttribute("releasemode") then
            owner:SetAttribute("ptspell", self:GetAttribute("spell"))
        end
    ]])
    SecureHandlerWrapScript(btn, "OnLeave", toggleBtn, [[
        if owner:GetAttribute("releasemode") then
            owner:SetAttribute("ptspell", nil)
        end
    ]])

    -- Close popup after direct-click cast (secure post-handler, works in combat)
    SecureHandlerWrapScript(btn, "OnClick", toggleBtn, "", [[
        if owner:GetAttribute("closeOnCast") then
            local p = owner:GetFrameRef("popup")
            if p and p:IsShown() then
                p:Hide()
            end
        end
    ]])

    PT.Masque:AddButton("Popup", btn, {
        Icon = iconTex,
        Normal = normalTex,
        Highlight = highlightTex,
    })

    tinsert(buttons, btn)
    return btn
end

function PM:BuildButtons()
    -- Clear old buttons and labels
    for _, btn in ipairs(buttons) do btn:Hide() end
    wipe(buttons)
    for _, lbl in ipairs(labels) do lbl:Hide() end
    wipe(labels)

    local cats = PaladinToolsDB.popupCategories
    local playerFaction = UnitFactionGroup("player")

    -- Blessings (greater replaces lesser when known)
    local greaterByType = {}
    for _, spell in ipairs(PT.GREATER_BLESSINGS) do
        greaterByType[spell.type] = spell
    end

    local blessingSpells = {}
    if cats.blessings then
        for _, spell in ipairs(PT.BLESSINGS) do
            local greater = greaterByType[spell.type]
            local greaterId = greater and FindSpellInBook(greater.name)
            if greaterId then
                tinsert(blessingSpells, { spellID = greaterId })
            else
                local id = FindSpellInBook(spell.name)
                if id then tinsert(blessingSpells, { spellID = id }) end
            end
        end
    end

    -- Auras
    local auraSpells = {}
    if cats.auras then
        for _, spell in ipairs(PT.AURAS) do
            local id = FindSpellInBook(spell.name)
            if id then tinsert(auraSpells, { spellID = id }) end
        end
    end

    -- Seals
    local sealSpells = {}
    if cats.seals then
        for _, spell in ipairs(PT.SEALS) do
            if not spell.faction or spell.faction == playerFaction then
                local id = FindSpellInBook(spell.name)
                if id then tinsert(sealSpells, { spellID = id }) end
            end
        end
    end

    -- Inverted triangle layout: blessings top-center, auras bottom-left, seals bottom-right
    local groups = {
        { spells = blessingSpells, prefix = "Blessing", label = "Blessings", pos = "top" },
        { spells = auraSpells,     prefix = "Aura",     label = "Auras",     pos = "bottomleft" },
        { spells = sealSpells,     prefix = "Seal",     label = "Seals",     pos = "bottomright" },
    }

    local btnSize = PaladinToolsDB.popupButtonSize
    local spacing = btnSize + BUTTON_PADDING
    local maxAbsX = 0
    local maxAbsY = 0

    local LABEL_GAP = 2

    for _, g in ipairs(groups) do
        if #g.spells > 0 then
            local cols = math.min(#g.spells, BLOCK_COLS)
            local rows = math.ceil(#g.spells / BLOCK_COLS)
            local blockW = cols * spacing
            local blockH = rows * spacing

            local col = 0
            local row = 0
            for i, spell in ipairs(g.spells) do
                local btn = CreateSpellButton(spell, g.prefix, i)

                local bx, by
                if g.pos == "top" then
                    -- Centered horizontally, above cursor
                    bx = -blockW / 2 + col * spacing + btnSize / 2
                    by = BLOCK_GAP + blockH - row * spacing - btnSize / 2
                elseif g.pos == "bottomleft" then
                    bx = -BLOCK_GAP - blockW + col * spacing + btnSize / 2
                    by = -BLOCK_GAP - row * spacing - btnSize / 2
                else -- bottomright
                    bx = BLOCK_GAP + col * spacing + btnSize / 2
                    by = -BLOCK_GAP - row * spacing - btnSize / 2
                end

                btn:ClearAllPoints()
                btn:SetPoint("CENTER", popup, "CENTER", bx, by)

                local edgeX = math.abs(bx) + btnSize / 2
                local edgeY = math.abs(by) + btnSize / 2
                if edgeX > maxAbsX then maxAbsX = edgeX end
                if edgeY > maxAbsY then maxAbsY = edgeY end

                col = col + 1
                if col >= BLOCK_COLS then
                    col = 0
                    row = row + 1
                end
            end

            -- Group label
            local lbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetText(g.label)
            lbl:SetTextColor(0.96, 0.55, 0.73, 0.8)  -- Paladin pink

            if g.pos == "top" then
                lbl:SetPoint("BOTTOM", popup, "CENTER", 0, BLOCK_GAP + blockH + LABEL_GAP)
            elseif g.pos == "bottomleft" then
                lbl:SetPoint("TOPRIGHT", popup, "CENTER", -BLOCK_GAP, -BLOCK_GAP - blockH - LABEL_GAP)
            else
                lbl:SetPoint("TOPLEFT", popup, "CENTER", BLOCK_GAP, -BLOCK_GAP - blockH - LABEL_GAP)
            end

            tinsert(labels, lbl)

            local labelEdgeY = BLOCK_GAP + blockH + LABEL_GAP + 12
            if labelEdgeY > maxAbsY then maxAbsY = labelEdgeY end
        end
    end

    PT.Masque:ReSkin("Popup")

    -- Size popup to contain all buttons, labels, and backdrop padding
    local EDGE_PADDING = 8
    if maxAbsX > 0 and maxAbsY > 0 then
        popup:SetSize((maxAbsX + EDGE_PADDING) * 2, (maxAbsY + EDGE_PADDING) * 2)
    else
        popup:SetSize(1, 1)
    end
end

function PM:ShowAtCursor()
    if InCombatLockdown() then return end
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = x / scale, y / scale

    popup:ClearAllPoints()
    popup:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    popup:Show()
end

function PM:UpdateCloseOnCast()
    if toggleBtn then
        toggleBtn:SetAttribute("closeOnCast", PaladinToolsDB.popupCloseOnCast and true or nil)
    end
end

function PM:Rebuild()
    if popup then
        self:BuildButtons()
    end
end

function PM:OnEvent(event, ...)
    if event == "SPELLS_CHANGED" then
        if popup then
            self:BuildButtons()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if toggleBtn and not popup:IsShown() then
            toggleBtn:SetAttribute("type", nil)
            toggleBtn:SetAttribute("spell", nil)
            toggleBtn:SetAttribute("ptspell", nil)
            toggleBtn:SetAttribute("popupopen", nil)
        end
        PM:ApplyKeybind()
    end
end
