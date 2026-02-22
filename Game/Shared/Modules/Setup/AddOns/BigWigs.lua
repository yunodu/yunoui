local MUI = unpack(yunoUI)
local SE = MUI:GetModule("Setup")

local function ImportBigWigs(addon, resolution)
    local PD = yunoUI_ProfileData
    local profile = "bigwigs" .. (resolution or "")
    local str = PD and PD[profile]
    if not str or str == "" then
        MUI:Print("No BigWigs profile string found. Check Data\\Standard\\AddOns\\BigWigs.lua")
        return
    end

    BigWigsAPI.RegisterProfile(MUI.title, str, "yuno", function(callback)
        if not callback then
            return
        end

        SE.CompleteSetup(addon)

        MUI.db.char.loaded = true
        MUI.db.global.version = MUI.version
    end)
end

function SE.BigWigs(addon, import, resolution)
    local BigWigs3DB = BigWigs3DB
    local db

    if import then
        ImportBigWigs(addon, resolution)

        return
    end

    if not SE.IsProfileExisting(BigWigs3DB) then
        SE.RemoveFromDatabase(addon)

        return
    end

    db = LibStub("AceDB-3.0"):New(BigWigs3DB)

    db:SetProfile("yuno")
end
