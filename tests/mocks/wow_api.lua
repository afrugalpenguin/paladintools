-- Minimal WoW API stubs so addon files can be loaded under busted.
-- Specs override individual globals and restore them in after_each.

-- Any frame method is a no-op returning another stub (for CreateFontString, CreateTexture, ...)
local function stubObject()
    return setmetatable({}, {
        __index = function(t, key)
            local fn = function() return _G.StubObject() end
            rawset(t, key, fn)
            return fn
        end,
    })
end
_G.StubObject = stubObject

_G.CreateFrame = function() return stubObject() end
_G.UIParent = stubObject()
_G.GameTooltip = stubObject()
_G.UISpecialFrames = {}
_G.SlashCmdList = {}

_G.SecureHandlerWrapScript = function() end
_G.SecureHandlerSetFrameRef = function() end
_G.RegisterAttributeDriver = function() end
_G.SetOverrideBindingClick = function() end
_G.ClearOverrideBindings = function() end

_G.C_Timer = { After = function() end }
_G.C_ChatInfo = {
    RegisterAddonMessagePrefix = function() end,
    SendAddonMessage = function() return true end,
}

_G.UnitName = function(unit) if unit == "player" then return "Me" end end
_G.UnitClass = function() return "Paladin", "PALADIN" end
_G.UnitExists = function() return false end
_G.UnitIsDeadOrGhost = function() return false end
_G.UnitFactionGroup = function() return "Alliance" end
_G.GetNumGroupMembers = function() return 0 end
_G.IsInRaid = function() return false end
_G.InCombatLockdown = function() return false end
_G.GetTime = function() return 1000 end
_G.SendChatMessage = function() end

_G.strlower = string.lower
_G.strfind = string.find
_G.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
_G.format = string.format
_G.tinsert = table.insert
_G.tremove = table.remove
_G.wipe = function(t)
    for k in pairs(t) do t[k] = nil end
    return t
end
_G.strsplit = function(sep, s)
    local parts = {}
    for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do
        parts[#parts + 1] = part
    end
    return unpack(parts)
end
