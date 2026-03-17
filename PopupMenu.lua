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
    return PT:FindSpellInBook(targetName)
end

-- Returns true if the player has any points in Improved Righteous Fury (Protection tab)
function PM:HasImprovedRF()
    local PROT_TAB = 2
    for i = 1, GetNumTalents(PROT_TAB) do
        local name, _, _, _, rank = GetTalentInfo(PROT_TAB, i)
        if name == "Improved Righteous Fury" then
            return rank and rank > 0
        end
    end
    return false
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
    PT:RegisterEvents("SPELLS_CHANGED", "PLAYER_REGEN_ENABLED",
        "UNIT_AURA", "GROUP_ROSTER_UPDATE")
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

    popup:SetScript("OnShow", function()
        if not InCombatLockdown() then
            PM:BuildButtons()
        end
    end)

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

    local timerElapsed = 0
    popup:SetScript("OnUpdate", function(self, elapsed)
        timerElapsed = timerElapsed + elapsed
        if timerElapsed >= 0.25 then
            timerElapsed = 0
            PM:UpdateClassGridVisuals()
        end
    end)
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

-- Blessing Manager: buff scanning state
local classRoster = {}    -- { WARRIOR = { "unit1", "unit2" }, ... }
local classBlessings = {} -- { WARRIOR = { buffed = 2, total = 3, expires = time, duration = 600 }, ... }
local knownGreaters = {}  -- ordered list of blessing types the player knows

local function ScanKnownGreaters()
    wipe(knownGreaters)
    for _, bType in ipairs(PT.BLESSING_CYCLE_ORDER) do
        local spellData = PT.GREATER_BLESSING_BY_TYPE[bType]
        if spellData and FindSpellInBook(spellData.name) then
            tinsert(knownGreaters, bType)
        end
    end
end

local function ScanRoster()
    wipe(classRoster)
    local groupSize = GetNumGroupMembers()
    if groupSize == 0 then
        local _, englishClass = UnitClass("player")
        classRoster[englishClass] = { "player" }
        return
    end
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, groupSize do
        local unit = prefix .. i
        if UnitExists(unit) then
            local _, englishClass = UnitClass(unit)
            if englishClass then
                if not classRoster[englishClass] then
                    classRoster[englishClass] = {}
                end
                tinsert(classRoster[englishClass], unit)
            end
        end
    end
    if prefix == "party" then
        local _, englishClass = UnitClass("player")
        if not classRoster[englishClass] then
            classRoster[englishClass] = {}
        end
        tinsert(classRoster[englishClass], "player")
    end
end

local function ScanBlessings()
    wipe(classBlessings)
    local blessingNames = {}
    for _, spell in ipairs(PT.BLESSINGS) do
        blessingNames[spell.name] = spell.type
    end
    for _, spell in ipairs(PT.GREATER_BLESSINGS) do
        blessingNames[spell.name] = spell.type
    end

    for class, units in pairs(classRoster) do
        local total = #units
        local buffed = 0
        local shortestExpires = nil
        local shortestDuration = nil
        local assignedType = PaladinToolsDB.blessingAssignments[class]

        for _, unit in ipairs(units) do
            if not UnitIsDeadOrGhost(unit) then
                for i = 1, 40 do
                    local name, _, _, _, duration, expirationTime = UnitBuff(unit, i)
                    if not name then break end
                    local bType = blessingNames[name]
                    if bType and bType == assignedType then
                        buffed = buffed + 1
                        if expirationTime and (not shortestExpires or expirationTime < shortestExpires) then
                            shortestExpires = expirationTime
                            shortestDuration = duration
                        end
                        break
                    end
                end
            end
        end

        classBlessings[class] = {
            buffed = buffed,
            total = total,
            expires = shortestExpires,
            duration = shortestDuration or 600,
        }
    end
end

local classGridButtons = {}
local CLASS_ICON_SIZE = 16

local function CreateClassGridRow(class)
    local btnSize = PaladinToolsDB.popupButtonSize
    local row = {}

    local btn = CreateFrame("Button", "PaladinToolsClassGrid" .. class, popup, "SecureActionButtonTemplate")
    btn:SetSize(btnSize, btnSize)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local tmplNormal = btn:GetNormalTexture()
    if tmplNormal then
        tmplNormal:SetTexture(nil)
        tmplNormal:Hide()
    end

    local iconTex = btn:CreateTexture(nil, "ARTWORK")
    iconTex:SetPoint("TOPLEFT", 1, -1)
    iconTex:SetPoint("BOTTOMRIGHT", -1, 1)
    iconTex:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
    row.icon = iconTex

    local overlay = btn:CreateTexture(nil, "OVERLAY", nil, 1)
    overlay:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -1, -1)
    overlay:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    overlay:SetWidth(0)
    overlay:SetColorTexture(0, 0, 0, 0.6)
    row.overlay = overlay

    local normalTex, highlightTex
    if PT.Masque:IsEnabled() then
        normalTex = btn:CreateTexture(nil, "OVERLAY")
        normalTex:SetAllPoints()
        btn:SetNormalTexture(normalTex)
    else
        local border = btn:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints()
        border:SetColorTexture(0, 0, 0, 1)
        row.border = border
    end

    highlightTex = btn:CreateTexture(nil, "HIGHLIGHT")
    highlightTex:SetAllPoints()
    highlightTex:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlightTex:SetBlendMode("ADD")
    btn:SetHighlightTexture(highlightTex)

    local classIcon = btn:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(CLASS_ICON_SIZE, CLASS_ICON_SIZE)
    classIcon:SetPoint("BOTTOM", btn, "TOP", 0, 2)
    classIcon:SetTexture(PT.CLASS_ICON_TEXTURE)
    local coords = PT.CLASS_ICON_COORDS[class]
    if coords then
        classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    end
    row.classIcon = classIcon

    local countText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countText:SetPoint("BOTTOM", btn, "BOTTOM", 0, 2)
    countText:SetText("0/0")
    row.countText = countText

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local assignedType = PaladinToolsDB.blessingAssignments[class]
        if assignedType then
            local spellData = PT.GREATER_BLESSING_BY_TYPE[assignedType]
            if spellData then
                GameTooltip:SetSpellByID(spellData.spellID)
            end
        else
            GameTooltip:SetText("No blessing assigned")
            GameTooltip:AddLine("Right-click to assign", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    btn:SetScript("PostClick", function(self, mouseBtn)
        if mouseBtn == "RightButton" and not InCombatLockdown() then
            PM:CycleBlessing(class)
        end
    end)

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

    row.btn = btn
    row.class = class
    return row
end

function PM:CycleBlessing(class)
    if #knownGreaters == 0 then return end
    local current = PaladinToolsDB.blessingAssignments[class]
    local nextType = nil

    if not current then
        nextType = knownGreaters[1]
    else
        for i, bType in ipairs(knownGreaters) do
            if bType == current then
                nextType = knownGreaters[i + 1] or nil
                break
            end
        end
    end

    PaladinToolsDB.blessingAssignments[class] = nextType
    ScanBlessings()
    self:UpdateClassGridAttributes()
    self:UpdateClassGridVisuals()
    local bs = PT.modules["BlessingSync"]
    if bs then bs:BroadcastThrottled() end
end

function PM:UpdateClassGridAttributes()
    if InCombatLockdown() then return end
    for class, row in pairs(classGridButtons) do
        local assignedType = PaladinToolsDB.blessingAssignments[class]
        if assignedType then
            local spellData = PT.GREATER_BLESSING_BY_TYPE[assignedType]
            if spellData then
                -- Use spellbook lookup for reliable spell name (immune to cold cache)
                local bookID = FindSpellInBook(spellData.name)
                local spellName = bookID and GetSpellInfo(bookID) or GetSpellInfo(spellData.spellID)
                if spellName then
                    row.btn:SetAttribute("type", "spell")
                    row.btn:SetAttribute("spell", spellName)
                    local units = classRoster[class]
                    if units and units[1] then
                        row.btn:SetAttribute("unit", units[1])
                    end
                else
                    row.btn:SetAttribute("type", nil)
                    row.btn:SetAttribute("spell", nil)
                    row.btn:SetAttribute("unit", nil)
                end
            end
        else
            row.btn:SetAttribute("type", nil)
            row.btn:SetAttribute("spell", nil)
            row.btn:SetAttribute("unit", nil)
        end
    end
end

function PM:UpdateClassGridVisuals()
    for class, row in pairs(classGridButtons) do
        local assignedType = PaladinToolsDB.blessingAssignments[class]

        if assignedType then
            local spellData = PT.GREATER_BLESSING_BY_TYPE[assignedType]
            if spellData then
                -- Use spellbook lookup for reliable icon (immune to cold cache)
                local bookID = FindSpellInBook(spellData.name)
                local _, _, icon = GetSpellInfo(bookID or spellData.spellID)
                row.icon:SetTexture(icon or "Interface\\ICONS\\INV_Misc_QuestionMark")
            end
        else
            row.icon:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
        end

        local info = classBlessings[class]
        if info then
            row.countText:SetText(info.buffed .. "/" .. info.total)
            if info.buffed >= info.total then
                row.countText:SetTextColor(0.2, 1, 0.2)
            else
                row.countText:SetTextColor(1, 0.2, 0.2)
            end
        else
            row.countText:SetText("0/0")
            row.countText:SetTextColor(0.5, 0.5, 0.5)
        end

        local remainingPct = 0
        if assignedType and info and info.expires then
            local remaining = info.expires - GetTime()
            if remaining > 0 then
                remainingPct = remaining / info.duration
                local pct = 1 - remainingPct
                local btnSize = PaladinToolsDB.popupButtonSize - 2
                row.overlay:SetWidth(math.max(0, pct * btnSize))
            else
                row.overlay:SetWidth(PaladinToolsDB.popupButtonSize - 2)
            end
        else
            if assignedType then
                row.overlay:SetWidth(PaladinToolsDB.popupButtonSize - 2)
            else
                row.overlay:SetWidth(0)
            end
        end

        -- Border color: red <25%, amber <50%, black otherwise
        if row.border then
            if assignedType and info and info.expires then
                if remainingPct <= 0.25 then
                    row.border:SetColorTexture(0.8, 0.1, 0.1, 1)
                elseif remainingPct <= 0.50 then
                    row.border:SetColorTexture(0.9, 0.6, 0.0, 1)
                else
                    row.border:SetColorTexture(0, 0, 0, 1)
                end
            else
                row.border:SetColorTexture(0, 0, 0, 1)
            end
        end
    end
end

function PM:BuildButtons()
    -- Clear old buttons and labels
    for _, btn in ipairs(buttons) do btn:Hide() end
    wipe(buttons)
    for _, lbl in ipairs(labels) do lbl:Hide() end
    wipe(labels)
    for _, row in pairs(classGridButtons) do
        row.btn:Hide()
    end
    wipe(classGridButtons)

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

    -- Four-quadrant X layout: blessings top-left, auras bottom-left, seals bottom-right
    local groups = {
        { spells = blessingSpells, prefix = "Blessing", label = "Blessings", pos = "topleft" },
        { spells = auraSpells,     prefix = "Aura",     label = "Auras",     pos = "bottomleft" },
        { spells = sealSpells,     prefix = "Seal",     label = "Seals",     pos = "bottomright" },
    }

    local btnSize = PaladinToolsDB.popupButtonSize
    local spacing = btnSize + BUTTON_PADDING
    local maxAbsX = 0
    local maxAbsY = 0
    local showRF = PM:HasImprovedRF() and FindSpellInBook(PT.RIGHTEOUS_FURY.name)
    local centerGap = showRF and (btnSize / 2 + BUTTON_PADDING) or BLOCK_GAP

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
                if g.pos == "topleft" then
                    bx = -centerGap - blockW + col * spacing + btnSize / 2
                    by = centerGap + blockH - row * spacing - btnSize / 2
                elseif g.pos == "topright" then
                    bx = centerGap + col * spacing + btnSize / 2
                    by = centerGap + blockH - row * spacing - btnSize / 2
                elseif g.pos == "bottomleft" then
                    bx = -centerGap - blockW + col * spacing + btnSize / 2
                    by = -centerGap - row * spacing - btnSize / 2
                else -- bottomright
                    bx = centerGap + col * spacing + btnSize / 2
                    by = -centerGap - row * spacing - btnSize / 2
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

            if g.pos == "topleft" then
                lbl:SetPoint("BOTTOMRIGHT", popup, "CENTER", -centerGap, centerGap + blockH + LABEL_GAP)
            elseif g.pos == "topright" then
                lbl:SetPoint("BOTTOMLEFT", popup, "CENTER", centerGap, centerGap + blockH + LABEL_GAP)
            elseif g.pos == "bottomleft" then
                lbl:SetPoint("TOPRIGHT", popup, "CENTER", -centerGap, -centerGap - blockH - LABEL_GAP)
            else -- bottomright
                lbl:SetPoint("TOPLEFT", popup, "CENTER", centerGap, -centerGap - blockH - LABEL_GAP)
            end

            tinsert(labels, lbl)

            local labelEdgeY = centerGap + blockH + LABEL_GAP + 12
            if labelEdgeY > maxAbsY then maxAbsY = labelEdgeY end
        end
    end

    -- Righteous Fury (center of X layout, shown if Improved RF is talented)
    if PM:HasImprovedRF() then
        local rfSpell = PT.RIGHTEOUS_FURY
        local rfId = FindSpellInBook(rfSpell.name)
        if rfId then
            local btn = CreateSpellButton({ spellID = rfId }, "RF", 1)
            btn:ClearAllPoints()
            btn:SetPoint("CENTER", popup, "CENTER", 0, 0)
            local edgeHalf = btnSize / 2
            if edgeHalf > maxAbsX then maxAbsX = edgeHalf end
            if edgeHalf > maxAbsY then maxAbsY = edgeHalf end
        end
    end

    -- Build class grid (top-right quadrant)
    ScanKnownGreaters()
    ScanRoster()
    ScanBlessings()

    local gridBtnSize = PaladinToolsDB.popupButtonSize
    local gridSpacing = gridBtnSize + BUTTON_PADDING
    local gridClasses = {}

    local CLASS_ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
    for _, class in ipairs(CLASS_ORDER) do
        if classRoster[class] then
            tinsert(gridClasses, class)
        end
    end

    -- Align class grid button centers with the blessings row
    local gridBtnY = centerGap + gridSpacing - gridBtnSize / 2

    for gridIndex, class in ipairs(gridClasses) do
        local row = CreateClassGridRow(class)
        classGridButtons[class] = row

        local bx = centerGap + (gridIndex - 1) * gridSpacing + gridBtnSize / 2
        local by = gridBtnY

        row.btn:ClearAllPoints()
        row.btn:SetPoint("CENTER", popup, "CENTER", bx, by)

        local edgeX = bx + gridBtnSize / 2
        -- Account for class icon above the button
        local edgeY = by + gridBtnSize / 2 + CLASS_ICON_SIZE + 2
        if edgeX > maxAbsX then maxAbsX = edgeX end
        if edgeY > maxAbsY then maxAbsY = edgeY end
    end

    if #gridClasses > 0 then
        local lbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetText("Blessings Manager")
        lbl:SetTextColor(0.96, 0.55, 0.73, 0.8)
        local gridTop = gridBtnY + gridBtnSize / 2 + CLASS_ICON_SIZE + 2
        lbl:SetPoint("BOTTOMLEFT", popup, "CENTER", centerGap, gridTop + LABEL_GAP)
        tinsert(labels, lbl)

        local labelEdgeY = gridTop + LABEL_GAP + 12
        if labelEdgeY > maxAbsY then maxAbsY = labelEdgeY end
    end

    PM:UpdateClassGridAttributes()
    PM:UpdateClassGridVisuals()

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
        ScanKnownGreaters()
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
        self:UpdateClassGridAttributes()
    elseif event == "GROUP_ROSTER_UPDATE" then
        ScanRoster()
        ScanBlessings()
        if popup then
            self:BuildButtons()
        end
    elseif event == "UNIT_AURA" then
        ScanBlessings()
        self:UpdateClassGridVisuals()
    end
end
