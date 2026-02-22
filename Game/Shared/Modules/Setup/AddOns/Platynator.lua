local MUI = unpack(yunoUI)
local SE = MUI:GetModule("Setup")

function SE.Platynator(addon, import)
    if import then
        if not MUI:IsAddOnEnabled("Platynator") then
            MUI:Print("Platynator is not enabled. Enable it to import.")
            return
        end
        local loaded = C_AddOns and C_AddOns.LoadAddOn("Platynator") or LoadAddOn("Platynator")
        if not loaded or not Platynator or not Platynator.API or not Platynator.API.ImportString then
            MUI:Print("Platynator could not be loaded or has no ImportString API.")
            return
        end
        local PD = yunoUI_ProfileData
        local str = PD and PD.platynator
        if not str or type(str) ~= "string" or str == "" then
            MUI:Print("No Platynator import string found. Paste your export in Data\\Standard\\AddOns\\Platynator.lua")
            return
        end
        str = str:match("^%s*(.-)%s*$") or str
        local ok, err = pcall(Platynator.API.ImportString, str, "yunoUI")
        if not ok then
            MUI:Print("|cffff0000Platynator import failed:|r " .. tostring(err))
            return
        end
        SE.CompleteSetup(addon)
        MUI.db.char.loaded = true
        MUI.db.global.version = MUI.version
        return
    end

end
