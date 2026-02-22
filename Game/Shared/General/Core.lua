local MUI = unpack(yunoUI)

local tonumber, unpack = tonumber, unpack

local C_AddOns = C_AddOns

MUI.title = C_AddOns.GetAddOnMetadata("yunoUI", "Title")
MUI.version = tonumber(C_AddOns.GetAddOnMetadata("yunoUI", "Version"))
MUI.myname = UnitName("player")

function MUI:Initialize()
    local Details = Details
    local E

    if self:IsAddOnEnabled("Details") then
        if Details.is_first_run and #Details.custom == 0 then
            Details:AddDefaultCustomDisplays()
        end

        Details.character_first_run = false
        Details.is_first_run = false
        Details.is_version_first_run = false
    end

    if self:IsAddOnEnabled("ElvUI") then
        E = unpack(ElvUI)

        if E.InstallFrame and E.InstallFrame:IsShown() then
            E.InstallFrame:Hide()

            E.private.install_complete = E.version
        end

        E.global.ignoreIncompatible = true

        if self.Portraits and self.Portraits.Initialize then
            C_Timer.After(0.5, function()
                if self.Portraits and self.Portraits.Initialize then
                    self.Portraits:Initialize()
                end
            end)
        end
    end

    -- Load Profiles popups (used on login and by installer button)
    StaticPopupDialogs["yunoUI_LoadProfilesWarning"] = {
        text = "The game may freeze while applying profiles for up to 30 seconds. After clicking \"Continue\" please do not do anything and wait for the reload.",
        button1 = "Continue",
        showAlert = true,
        OnAccept = function()
            MUI:LoadProfiles()
        end,
    }
    StaticPopupDialogs["yunoUI_LoadProfiles"] = {
        text = "Do you wish to load your installed profiles onto this character?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            StaticPopup_Show("yunoUI_LoadProfilesWarning")
        end,
        OnCancel = function()
            MUI.db.char.loaded = true
        end,
    }

    if self.db.global.profiles and not self.db.char.loaded and not InCombatLockdown() then
        StaticPopup_Show("yunoUI_LoadProfiles")
    end
end
