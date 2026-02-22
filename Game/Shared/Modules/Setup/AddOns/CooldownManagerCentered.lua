local MUI = unpack(yunoUI)
local SE = MUI:GetModule("Setup")

local function ApplySettings(db)
    db.profile.cooldownManager_squareIconsZoom_BuffIcons  = 0.1
    db.profile.cooldownManager_squareIconsZoom_Essential  = 0.1
    db.profile.cooldownManager_squareIconsZoom_Utility    = 0.1
    db.profile.cooldownManager_keybindFontName            = "AvantGarde Bold"
    db.profile.cooldownManager_stackFontName              = "AvantGarde Bold"
end

function SE.CooldownManagerCentered(addon, import, resolution)
    local db = LibStub("AceDB-3.0"):New("CooldownManagerCenteredDB")

    if import then
        db:SetProfile("yuno")
        ApplySettings(db)

        SE.CompleteSetup(addon)

        MUI.db.char.loaded = true
        MUI.db.global.version = MUI.version

        return
    end

    if not SE.IsProfileExisting(CooldownManagerCenteredDB) then
        SE.RemoveFromDatabase(addon)

        return
    end

    db:SetProfile("yuno")
end
