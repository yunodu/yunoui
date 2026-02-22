local MUI = unpack(yunoUI)
local SE = MUI:GetModule("Setup")

function SE.BetterCooldownManager(addon, import, resolution)
    local PD = yunoUI_ProfileData
    local profile = "bettercooldownmanager" .. (resolution or "")
    local BCDMDB = BCDMDB
    local db

    if import then
        local str = PD and PD[profile]
        if not str or str == "" then
            MUI:Print("No BCM profile string found. Check Data\\Standard\\AddOns\\BetterCooldownManager.lua")
            return
        end
        BCDMG:ImportBCDM(str, "yuno")

        SE.CompleteSetup(addon)

        MUI.db.char.loaded = true
        MUI.db.global.version = MUI.version

        return
    end

    if not SE.IsProfileExisting(BCDMDB) then
        SE.RemoveFromDatabase(addon)

        return
    end

    db = LibStub("AceDB-3.0"):New(BCDMDB)

    db:SetProfile("yuno")
end
