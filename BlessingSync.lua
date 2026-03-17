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

-- Build a full message string
function BS:BuildAssignMessage(playerName, assignments)
    return "ASSIGN:" .. playerName .. ":" .. self:SerializeAssignments(assignments)
end

function BS:BuildOverrideMessage(targetName, assignments)
    return "OVERRIDE:" .. targetName .. ":" .. self:SerializeAssignments(assignments)
end

function BS:BuildSyncMessage()
    return "SYNC"
end

-- Parse any incoming message
-- Returns: msgType, name, assignments
function BS:ParseMessage(text)
    if text == "SYNC" then
        return "SYNC", nil, nil
    end

    local msgType, name, data = text:match("^(%u+):([^:]+):(.*)$")
    if not msgType then return nil end

    if msgType == "ASSIGN" or msgType == "OVERRIDE" then
        return msgType, name, self:ParseAssignments(data)
    end

    return nil
end
