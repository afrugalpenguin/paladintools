-- DevFakeRaid: hooks roster APIs to simulate groups for UI testing
-- Load order: after Data.lua, before PopupMenu.lua
-- Toggle with /fakeraid (9 players, one per class) or /fakeparty (4 + you)

local RAID_CLASSES = {
    { class = "WARRIOR",  name = "Testwarrior" },
    { class = "PALADIN",  name = "Testpaladin" },
    { class = "HUNTER",   name = "Testhunter" },
    { class = "ROGUE",    name = "Testrogue" },
    { class = "PRIEST",   name = "Testpriest" },
    { class = "SHAMAN",   name = "Testshaman" },
    { class = "MAGE",     name = "Testmage" },
    { class = "WARLOCK",  name = "Testwarlock" },
    { class = "DRUID",    name = "Testdruid" },
}

local PARTY_CLASSES = {
    { class = "WARRIOR",  name = "Tankbro" },
    { class = "PRIEST",   name = "Healbro" },
    { class = "MAGE",     name = "Frostbro" },
    { class = "ROGUE",    name = "Stabdude" },
}

-- Fake buff data per index: how far through the 10min duration (0=fresh, 1=expired)
-- nil = no buff. Only units with an assigned blessing AND an entry here show buffed.
local RAID_BUFFS = {
    [1] = { elapsed = 0.15 },  -- WARRIOR: 15% elapsed (nearly full)
    [2] = { elapsed = 0.50 },  -- PALADIN: 50% elapsed (half gone)
    [4] = { elapsed = 0.80 },  -- ROGUE: 80% elapsed (almost expired)
    [6] = { elapsed = 0.35 },  -- SHAMAN: 35% elapsed
    [7] = { elapsed = 0.95 },  -- MAGE: 95% elapsed (critical)
}

local PARTY_BUFFS = {
    [1] = { elapsed = 0.20 },  -- WARRIOR: 20% elapsed
    [3] = { elapsed = 0.70 },  -- MAGE: 70% elapsed
}

local FAKE_PALADINS = {
    {
        name = "Holypal",
        assignments = { WARRIOR = "might", PRIEST = "wisdom", MAGE = "wisdom",
                        WARLOCK = "wisdom", HUNTER = "might", DRUID = "might" },
        acceptRemote = true,
        isAssist = true,
    },
    {
        name = "Bubbleboy",
        assignments = { WARRIOR = "salvation", ROGUE = "might", SHAMAN = "kings",
                        PALADIN = "kings" },
        acceptRemote = true,
        isAssist = false,
    },
    {
        name = "Lightlady",
        assignments = { WARRIOR = "kings", MAGE = "kings", PRIEST = "sanctuary",
                        DRUID = "kings", HUNTER = "kings" },
        acceptRemote = false,
        isAssist = false,
    },
}

local fakePaladinsActive = false

local mode = nil  -- nil, "raid", or "party"
local fakeStartTime = 0

-- Store originals
local orig_GetNumGroupMembers = GetNumGroupMembers
local orig_IsInRaid = IsInRaid
local orig_UnitExists = UnitExists
local orig_UnitClass = UnitClass
local orig_UnitIsDeadOrGhost = UnitIsDeadOrGhost
local orig_UnitFactionGroup = UnitFactionGroup
local orig_UnitBuff = UnitBuff

local function ActiveMembers()
    if mode == "raid" then return RAID_CLASSES end
    if mode == "party" then return PARTY_CLASSES end
    return nil
end

local function ActiveBuffs()
    if mode == "raid" then return RAID_BUFFS end
    if mode == "party" then return PARTY_BUFFS end
    return nil
end

local function UnitPrefix()
    if mode == "raid" then return "raid" end
    if mode == "party" then return "party" end
    return nil
end

local function IsFakeUnit(unit)
    if not mode then return false end
    if type(unit) ~= "string" then return false end
    local prefix = UnitPrefix()
    local n = unit:match("^" .. prefix .. "(%d+)$")
    if not n then return false end
    local members = ActiveMembers()
    return tonumber(n) >= 1 and tonumber(n) <= #members
end

local function FakeIndex(unit)
    local prefix = UnitPrefix()
    return tonumber(unit:match("^" .. prefix .. "(%d+)$"))
end

local function Hook()
    GetNumGroupMembers = function()
        if mode == "raid" then return #RAID_CLASSES end
        if mode == "party" then return #PARTY_CLASSES + 1 end  -- +1 for player
        return orig_GetNumGroupMembers()
    end

    IsInRaid = function()
        if mode == "raid" then return true end
        if mode == "party" then return false end
        return orig_IsInRaid()
    end

    UnitExists = function(unit)
        if IsFakeUnit(unit) then return true end
        return orig_UnitExists(unit)
    end

    UnitClass = function(unit)
        if IsFakeUnit(unit) then
            local info = ActiveMembers()[FakeIndex(unit)]
            return info.class:sub(1,1) .. info.class:sub(2):lower(), info.class
        end
        return orig_UnitClass(unit)
    end

    UnitIsDeadOrGhost = function(unit)
        if IsFakeUnit(unit) then return false end
        return orig_UnitIsDeadOrGhost(unit)
    end

    UnitFactionGroup = function(unit)
        if IsFakeUnit(unit) then return orig_UnitFactionGroup("player") end
        return orig_UnitFactionGroup(unit)
    end

    UnitBuff = function(unit, index, ...)
        if IsFakeUnit(unit) then
            local idx = FakeIndex(unit)
            local buffs = ActiveBuffs()
            local fakeBuff = buffs and buffs[idx]
            if not fakeBuff or index ~= 1 then return nil end

            local members = ActiveMembers()
            local class = members[idx].class
            local assignedType = PaladinToolsDB and PaladinToolsDB.blessingAssignments[class]
            if not assignedType then return nil end

            local spellData = PaladinTools.GREATER_BLESSING_BY_TYPE[assignedType]
            if not spellData then return nil end

            local name, _, icon = GetSpellInfo(spellData.spellID)
            if not name then return nil end

            local duration = 600
            local remaining = (1 - fakeBuff.elapsed) * duration
            local expirationTime = GetTime() + remaining

            return name, icon, 1, nil, duration, expirationTime
        end
        return orig_UnitBuff(unit, index, ...)
    end
end

local function Unhook()
    GetNumGroupMembers = orig_GetNumGroupMembers
    IsInRaid = orig_IsInRaid
    UnitExists = orig_UnitExists
    UnitClass = orig_UnitClass
    UnitIsDeadOrGhost = orig_UnitIsDeadOrGhost
    UnitFactionGroup = orig_UnitFactionGroup
    UnitBuff = orig_UnitBuff
end

local function Rebuild()
    local PM = PaladinTools.modules["PopupMenu"]
    if PM and PM.Rebuild then
        PM:Rebuild()
    end
end

local function Toggle(newMode)
    if mode == newMode then
        -- Disable
        mode = nil
        Unhook()
        print("|cffF58CBAPaladinTools|r Fake group |cffff0000DISABLED|r")
    else
        -- Switch to new mode (disable old first if active)
        if mode then Unhook() end
        mode = newMode
        fakeStartTime = GetTime()
        Hook()
        if newMode == "raid" then
            print("|cffF58CBAPaladinTools|r Fake raid |cff00ff00ENABLED|r — " .. #RAID_CLASSES .. " raiders (one per class)")
            print("  Buffs: Warrior(15%%), Paladin(50%%), Rogue(80%%), Shaman(35%%), Mage(95%% elapsed)")
        else
            print("|cffF58CBAPaladinTools|r Fake party |cff00ff00ENABLED|r — " .. #PARTY_CLASSES .. " party members + you")
            print("  Buffs: Warrior(20%%), Mage(70%% elapsed)")
        end
    end
    Rebuild()
end

local function ToggleFakePaladins(countStr)
    local count = tonumber(countStr) or 2
    count = math.min(count, #FAKE_PALADINS)

    if fakePaladinsActive then
        for _, pal in ipairs(FAKE_PALADINS) do
            PaladinTools.syncState[pal.name] = nil
        end
        fakePaladinsActive = false
        print("|cffF58CBAPaladinTools|r Fake paladins |cffff0000DISABLED|r")
    else
        for i = 1, count do
            local pal = FAKE_PALADINS[i]
            PaladinTools.syncState[pal.name] = {}
            for k, v in pairs(pal.assignments) do
                PaladinTools.syncState[pal.name][k] = v
            end
        end
        fakePaladinsActive = true
        print("|cffF58CBAPaladinTools|r Fake paladins |cff00ff00ENABLED|r — " .. count .. " paladins added")
        for i = 1, count do
            local pal = FAKE_PALADINS[i]
            local status = pal.acceptRemote and "|cff00ff00accepts remote|r" or "|cffff0000locked|r"
            local role = pal.isAssist and " (assist)" or ""
            print("  " .. pal.name .. role .. " — " .. status)
        end
    end

    local bs = PaladinTools.modules["BlessingSync"]
    if bs and bs.RefreshUI then bs:RefreshUI() end
end

SLASH_FAKEPALADINS1 = "/fakepaladins"
SlashCmdList["FAKEPALADINS"] = function(msg)
    ToggleFakePaladins(strtrim(msg))
end

SLASH_FAKERAID1 = "/fakeraid"
SlashCmdList["FAKERAID"] = function() Toggle("raid") end

SLASH_FAKEPARTY1 = "/fakeparty"
SlashCmdList["FAKEPARTY"] = function() Toggle("party") end
