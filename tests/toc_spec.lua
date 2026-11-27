-- Checks the two TOC files stay in step: same shared files, Forever files only in Camelot

local function readToc(path)
    local f = assert(io.open(path, "r"))
    local meta, files = {}, {}
    for line in f:lines() do
        line = line:gsub("\r$", "")
        local key, value = line:match("^## ([%w%-]+): (.*)$")
        if key then
            meta[key] = value
        elseif line:match("%S") and not line:match("^#") then
            files[#files + 1] = line
        end
    end
    f:close()
    return meta, files
end

local function indexOf(list, value)
    for i, v in ipairs(list) do
        if v == value then return i end
    end
end

local function fileExists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

describe("TOC files", function()
    local tbcMeta, tbcFiles = readToc("PaladinTools.toc")
    local foreverMeta, foreverFiles = readToc("PaladinTools_Camelot.toc")

    it("targets the Forever interface", function()
        assert.are.equal("16001", foreverMeta["Interface"])
        assert.are.equal("20505", tbcMeta["Interface"])
    end)

    it("shares the saved variables and project metadata", function()
        for _, key in ipairs({ "Title", "Version", "SavedVariablesPerCharacter", "OptionalDeps", "X-Curse-Project-ID" }) do
            assert.are.equal(tbcMeta[key], foreverMeta[key])
        end
    end)

    it("lists only files that exist", function()
        for _, file in ipairs(foreverFiles) do
            assert(fileExists(file), file .. " is missing")
        end
    end)

    it("loads every shared module except the TBC-only dev tools, in the same order", function()
        local last = 0
        for _, file in ipairs(tbcFiles) do
            local i = indexOf(foreverFiles, file)
            if file == "DevFakeRaid.lua" then
                assert.is_nil(i)
            else
                assert(i, file .. " is not in the Camelot TOC")
                assert(i > last, file .. " is out of order")
                last = i
            end
        end
    end)

    it("keeps Forever files out of the TBC TOC", function()
        for _, file in ipairs(tbcFiles) do
            assert.is_nil(file:match("_Forever%.lua$"))
        end
    end)

    it("loads each Forever override after what it overrides", function()
        assert.are.equal(indexOf(foreverFiles, "Core.lua") + 1, indexOf(foreverFiles, "Compat_Forever.lua"))
        assert(indexOf(foreverFiles, "PopupMenu_Forever.lua") > indexOf(foreverFiles, "PopupMenu.lua"))
    end)
end)
