--[[
    PaladinTools - Forever API probe (/ptapi)
    Reports which values the Forever client hides from addons, so the port can be checked in game.
    Results print to chat and are saved in PaladinToolsDB.apiReport.
    Loaded only by PaladinTools_Camelot.toc.
]]

local PT = PaladinTools
local APICheck = {}
PT.APICheck = APICheck

local SYMBOL_OF_KINGS = 21177
local IMPROVED_RIGHTEOUS_FURY = 20468
local MAX_GROUP_UNITS = 5

local last = { sent = "none seen", whisper = "none seen" }

local function pack(...)
    return { n = select("#", ...), ... }
end

-- "secret" for protected values; booleans and numbers show their value; tables list their fields
function APICheck:Describe(value, nested)
    if issecretvalue and issecretvalue(value) then return "secret" end
    local kind = type(value)
    if kind == "boolean" or kind == "number" then return kind .. ":" .. tostring(value) end
    if kind ~= "table" or nested then return kind end
    local parts = {}
    for k, v in pairs(value) do
        parts[#parts + 1] = tostring(k) .. "=" .. self:Describe(v, true)
    end
    table.sort(parts)
    return "{" .. table.concat(parts, ",") .. "}"
end

-- Describe each value in a vararg list, keeping nils in position
function APICheck:DescribeValues(...)
    local n = select("#", ...)
    if n == 0 then return "(no returns)" end
    local parts = {}
    for i = 1, n do
        local ok, desc = pcall(self.Describe, self, (select(i, ...)))
        parts[#parts + 1] = ok and desc or "undescribable"
    end
    return table.concat(parts, " ")
end

-- Call an API under pcall and describe what came back
function APICheck:Call(fn, ...)
    if type(fn) ~= "function" then return "missing" end
    local results = pack(pcall(fn, ...))
    if not results[1] then return "error: " .. tostring(results[2]) end
    return self:DescribeValues(unpack(results, 2, results.n))
end

function APICheck:GroupUnits()
    local units = { "player" }
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        local unit = prefix .. i
        if #units < MAX_GROUP_UNITS and UnitExists(unit) then
            units[#units + 1] = unit
        end
    end
    return units
end

function APICheck:Run()
    local lines = {}
    local function add(label, value)
        lines[#lines + 1] = label .. ": " .. value
    end
    local auras = C_UnitAuras or {}
    local spellBook = C_SpellBook or {}
    local chat = C_ChatInfo or {}

    add("build", tostring((GetBuildInfo())) .. " (" .. tostring(select(2, GetBuildInfo())) .. ")")
    add("InCombatLockdown", self:Call(InCombatLockdown))
    add("IsInInstance", self:Call(IsInInstance))
    add("group", self:Call(GetNumGroupMembers) .. " raid=" .. self:Call(IsInRaid))
    add("InChatMessagingLockdown", self:Call(chat.InChatMessagingLockdown))

    for _, unit in ipairs(self:GroupUnits()) do
        add("aura " .. unit, self:Call(auras.GetAuraDataByIndex, unit, 1, "HELPFUL"))
        add("kings " .. unit, self:Call(auras.GetAuraDataBySpellName, unit, "Greater Blessing of Kings", "HELPFUL"))
    end

    add("IsPlayerSpell(20468)", self:Call(IsPlayerSpell, IMPROVED_RIGHTEOUS_FURY))
    add("C_SpellBook.IsSpellKnown(20468)", self:Call(spellBook.IsSpellKnown, IMPROVED_RIGHTEOUS_FURY))
    add("PM:HasImprovedRF", self:Call(function()
        return PT.modules["PopupMenu"]:HasImprovedRF()
    end))
    for _, spell in ipairs(PT.GREATER_BLESSINGS) do
        add("book " .. spell.name, tostring((PT:FindSpellInBook(spell.name))))
    end
    add("Symbol of Kings count", self:Call(GetItemCount, SYMBOL_OF_KINGS))

    add("last UNIT_SPELLCAST_SENT", last.sent)
    add("last whisper", last.whisper)
    local sync = PT.modules["BlessingSync"]
    add("last addon send", sync and self:Describe(sync.lastSendResult) or "no sync module")

    PaladinToolsDB.apiReport = { build = select(2, GetBuildInfo()), lines = lines }
    return lines
end

function APICheck:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_SENT" then
        local _, target, _, spellID = ...
        last.sent = self:DescribeValues(target, spellID)
    elseif event == "CHAT_MSG_WHISPER" then
        local text, sender = ...
        last.whisper = self:DescribeValues(text, sender)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", function(_, event, ...)
    APICheck:OnEvent(event, ...)
end)

SLASH_PALADINTOOLSAPI1 = "/ptapi"
SlashCmdList["PALADINTOOLSAPI"] = function()
    print("|cffF58CBAPaladinTools|r API probe (saved to PaladinToolsDB.apiReport):")
    for _, line in ipairs(APICheck:Run()) do
        print("  " .. line)
    end
end
