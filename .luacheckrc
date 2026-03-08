std = "lua51"
max_line_length = false

globals = {
    "PaladinTools",
    "PaladinToolsDB",
    "SLASH_PALADINTOOLS1",
    "SLASH_PALADINTOOLS2",
    "SlashCmdList",
    "BINDING_HEADER_PALADINTOOLS",
    "BINDING_NAME_PALADINTOOLS_POPUP",
    "PaladinTools_TogglePopup",
}

read_globals = {
    -- WoW Frame API
    "CreateFrame",
    "UIParent",
    "UISpecialFrames",
    "GameTooltip",
    "InterfaceOptionsFrame_OpenToCategory",
    "InterfaceOptions_AddCategory",
    "SecureHandlerWrapScript",
    "SecureHandlerSetFrameRef",
    "RegisterAttributeDriver",
    "SetOverrideBindingClick",
    "ClearOverrideBindings",
    "hooksecurefunc",
    "BackdropTemplateMixin",

    -- WoW Unit API
    "UnitClass",
    "UnitFactionGroup",
    "UnitName",
    "UnitExists",
    "UnitBuff",
    "UnitIsDeadOrGhost",

    -- WoW Game State
    "GetTime",
    "GetCursorPosition",
    "GetSpellInfo",
    "GetSpellBookItemName",
    "GetSpellBookItemInfo",
    "IsSpellKnown",
    "GetItemIcon",
    "GetItemCount",
    "GetNumGroupMembers",
    "InCombatLockdown",
    "IsInRaid",
    "BOOKTYPE_SPELL",
    "NUM_BAG_SLOTS",

    -- WoW Container API
    "C_Container",

    -- WoW Chat API
    "SendChatMessage",

    -- WoW Timer API
    "C_Timer",

    -- WoW Constants
    "RAID_CLASS_COLORS",

    -- WoW Input API
    "IsShiftKeyDown",
    "IsControlKeyDown",
    "IsAltKeyDown",

    -- WoW Settings API
    "Settings",

    -- WoW Named Frames (created by CreateFrame with global names)
    "PaladinToolsHUD",
    "PaladinToolsPopup",
    "PaladinToolsOptions",
    "PaladinToolsTourWelcome",
    "PaladinToolsTour",

    -- Lua globals (WoW extensions)
    "strsplit",
    "strlower",
    "strfind",
    "strtrim",
    "tinsert",
    "tremove",
    "wipe",
    "format",

    -- Libraries
    "LibStub",

    -- Sound
    "PlaySound",
    "SOUNDKIT",
}

ignore = {
    "211",  -- Unused local variable
    "212",  -- Unused argument
    "213",  -- Unused loop variable
    "311",  -- Value assigned to variable is unused
    "412",  -- Redefining local variable
    "421",  -- Shadowing local variable
    "431",  -- Shadowing upvalue
    "432",  -- Shadowing upvalue argument
    "611",  -- Line contains only whitespace
}

exclude_files = {
    ".luarocks",
    "lua_modules",
}
