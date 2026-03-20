local PT = PaladinTools
local BS = {}
PT:RegisterModule("BlessingSync", BS)

local PREFIX = "PTools"
local THROTTLE_INTERVAL = 0.5
local pendingSend = false

-- Channel helper: RAID if in raid, PARTY otherwise
local function GetChannel()
    return IsInRaid() and "RAID" or "PARTY"
end

-- Serialize a paladin's assignments table to wire format
-- Input:  { WARRIOR = "kings", MAGE = "wisdom" }
-- Output: "WARRIOR=kings,MAGE=wisdom"
function BS:SerializeAssignments(assignments)
    local parts = {}
    for class, bType in pairs(assignments) do
        tinsert(parts, class .. "=" .. bType)
    end
    table.sort(parts)  -- deterministic order
    return table.concat(parts, ",")
end

-- Parse wire format back to assignments table
-- Input:  "WARRIOR=kings,MAGE=wisdom"
-- Output: { WARRIOR = "kings", MAGE = "wisdom" }
function BS:ParseAssignments(str)
    local assignments = {}
    if not str or str == "" then return assignments end
    for pair in str:gmatch("[^,]+") do
        local class, bType = pair:match("^(%u+)=(%a+)$")
        if class and bType then
            assignments[class] = bType
        end
    end
    return assignments
end

-- Build a full message string (includes acceptRemote flag)
function BS:BuildAssignMessage(playerName, assignments, acceptRemote)
    local flag = acceptRemote and "1" or "0"
    return "ASSIGN:" .. playerName .. ":" .. flag .. ":" .. self:SerializeAssignments(assignments)
end

function BS:BuildOverrideMessage(targetName, assignments)
    return "OVERRIDE:" .. targetName .. ":" .. self:SerializeAssignments(assignments)
end

function BS:BuildSyncMessage()
    return "SYNC"
end

-- Parse any incoming message
-- Returns: msgType, name, assignments, acceptRemote
function BS:ParseMessage(text)
    if text == "SYNC" then
        return "SYNC", nil, nil, nil
    end

    -- ASSIGN has 4 colon-separated fields: ASSIGN:name:flag:data
    local assignType, aName, flag, aData = text:match("^(ASSIGN):([^:]+):([01]):(.*)$")
    if assignType then
        return "ASSIGN", aName, self:ParseAssignments(aData), flag == "1"
    end

    -- OVERRIDE has 3 colon-separated fields: OVERRIDE:name:data
    local overType, oName, oData = text:match("^(OVERRIDE):([^:]+):(.*)$")
    if overType then
        return "OVERRIDE", oName, self:ParseAssignments(oData), nil
    end

    return nil
end

-- Broadcast own assignments to group
function BS:BroadcastAssignments()
    local name = UnitName("player")
    local assignments = PaladinToolsDB.blessingAssignments or {}
    local acceptRemote = PaladinToolsDB.acceptRemoteAssignments

    -- Update own entry in syncState and acceptRemote
    PT.syncState[name] = {}
    for k, v in pairs(assignments) do
        PT.syncState[name][k] = v
    end
    PT.syncAcceptRemote[name] = acceptRemote

    -- Only send if in a group
    if GetNumGroupMembers() <= 1 then return end

    local msg = self:BuildAssignMessage(name, assignments, acceptRemote)
    C_ChatInfo.SendAddonMessage(PREFIX, msg, GetChannel())
end

-- Send with throttle (coalesce rapid edits)
function BS:BroadcastThrottled()
    if pendingSend then return end
    pendingSend = true
    C_Timer.After(THROTTLE_INTERVAL, function()
        pendingSend = false
        BS:BroadcastAssignments()
    end)
end

-- Request all paladins to re-broadcast
function BS:RequestSync()
    if GetNumGroupMembers() <= 1 then return end
    C_ChatInfo.SendAddonMessage(PREFIX, "SYNC", GetChannel())
end

-- Send override to a target paladin
function BS:SendOverride(targetName, assignments)
    if GetNumGroupMembers() <= 1 then return end
    local msg = self:BuildOverrideMessage(targetName, assignments)
    C_ChatInfo.SendAddonMessage(PREFIX, msg, GetChannel())
end

-- Check if the local player has leader/assist permissions
function BS:HasLeaderPermission()
    return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

-- Check if a sender has leader/assist permissions
function BS:SenderHasPermission(senderName)
    local prefix = IsInRaid() and "raid" or "party"
    local count = GetNumGroupMembers()
    if prefix == "raid" then
        for i = 1, count do
            local name, rank = GetRaidRosterInfo(i)
            if name and (name == senderName or name:match("^" .. senderName .. "%-")) then
                return rank >= 1
            end
        end
    else
        if UnitName("player") == senderName then
            return UnitIsGroupLeader("player")
        end
        for i = 1, count - 1 do
            local unit = "party" .. i
            local unitName = UnitName(unit)
            if unitName == senderName then
                return UnitIsGroupLeader(unit)
            end
        end
    end
    return false
end

function BS:HandleAddonMessage(prefix, text, channel, sender)
    if prefix ~= PREFIX then return end

    local senderShort = sender:match("^([^%-]+)")

    local msgType, name, assignments, acceptRemote = self:ParseMessage(text)
    if not msgType then return end

    if msgType == "SYNC" then
        self:BroadcastAssignments()

    elseif msgType == "ASSIGN" then
        if senderShort == UnitName("player") then return end
        PT.syncState[name] = assignments
        PT.syncAcceptRemote[name] = acceptRemote
        self:RefreshUI()

    elseif msgType == "OVERRIDE" then
        if name ~= UnitName("player") then return end
        if not PaladinToolsDB.acceptRemoteAssignments then return end
        if not self:SenderHasPermission(senderShort) then return end

        wipe(PaladinToolsDB.blessingAssignments)
        for k, v in pairs(assignments) do
            PaladinToolsDB.blessingAssignments[k] = v
        end

        self:BroadcastAssignments()
        self:RefreshUI()
        print("|cffF58CBAPaladinTools|r Blessings updated by " .. senderShort)
    end
end

function BS:RefreshUI()
    local opts = PT.modules["Options"]
    if opts and opts.RefreshBlessings then
        opts:RefreshBlessings()
    end
end

-- Clean syncState: remove paladins no longer in the group
function BS:CleanSyncState()
    local groupNames = {}
    groupNames[UnitName("player")] = true

    local prefix = IsInRaid() and "raid" or "party"
    local count = GetNumGroupMembers()
    if prefix == "raid" then
        for i = 1, count do
            local rosterName = GetRaidRosterInfo(i)
            if rosterName then
                groupNames[(rosterName:match("^([^%-]+)"))] = true
            end
        end
    else
        for i = 1, count - 1 do
            local unit = "party" .. i
            if UnitExists(unit) then
                groupNames[UnitName(unit)] = true
            end
        end
    end

    for syncName in pairs(PT.syncState) do
        if not groupNames[syncName] then
            PT.syncState[syncName] = nil
            PT.syncAcceptRemote[syncName] = nil
        end
    end
end

function BS:OnEvent(event, ...)
    if event == "CHAT_MSG_ADDON" then
        local evPrefix, text, channel, sender = ...
        self:HandleAddonMessage(evPrefix, text, channel, sender)

    elseif event == "GROUP_ROSTER_UPDATE" then
        self:CleanSyncState()
        self:BroadcastThrottled()
        self:RefreshUI()
    end
end

function BS:Init()
    local name = UnitName("player")
    if name then
        PT.syncState[name] = {}
        for k, v in pairs(PaladinToolsDB.blessingAssignments) do
            PT.syncState[name][k] = v
        end
        PT.syncAcceptRemote[name] = PaladinToolsDB.acceptRemoteAssignments
    end

    C_Timer.After(2, function()
        BS:BroadcastAssignments()
        BS:RequestSync()
    end)
end
