local PT = PaladinTools

PT.Masque = {}
local MSQ = nil
local groups = {}

function PT.Masque:Init()
    local lib = LibStub and LibStub("Masque", true)
    if lib then
        MSQ = lib
    end
end

function PT.Masque:GetGroup(name)
    if not MSQ then return nil end
    if not groups[name] then
        groups[name] = MSQ:Group("PaladinTools", name)
    end
    return groups[name]
end

function PT.Masque:IsEnabled()
    return MSQ ~= nil
end

function PT.Masque:AddButton(groupName, button, data)
    local group = self:GetGroup(groupName)
    if group then
        group:AddButton(button, data)
    end
end

function PT.Masque:ReSkin(groupName)
    local group = self:GetGroup(groupName)
    if group then
        group:ReSkin()
    end
end
