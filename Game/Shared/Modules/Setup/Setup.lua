local MUI = unpack(yunoUI)
local SE = MUI:GetModule("Setup")

function SE:Setup(addon, ...)
    local setup = self[addon]

    local ok, err = pcall(setup, addon, ...)

    if not ok then
        MUI:Print("|cffff0000Error in " .. addon .. ":|r " .. tostring(err))
    end
end

function SE.CompleteSetup(addon)
    local PluginInstallStepComplete = PluginInstallStepComplete

    if PluginInstallStepComplete then
        if PluginInstallStepComplete:IsShown() then
            PluginInstallStepComplete:Hide()
        end

        PluginInstallStepComplete.message = "Success"

        PluginInstallStepComplete:Show()
    end

    MUI.db.global.profiles = MUI.db.global.profiles or {}
    MUI.db.global.profiles[addon] = true
end

function SE.IsProfileExisting(table)
    local db = LibStub("AceDB-3.0"):New(table)
    local profiles = db:GetProfiles()

    for i = 1, #profiles do
        if profiles[i] == "yuno" then
            return true
        end
    end
end

function SE.RemoveFromDatabase(addon)
    MUI.db.global.profiles[addon] = nil

    if MUI.db.global.profiles and #MUI.db.global.profiles == 0 then
        for k in pairs(MUI.db.char) do
            k = nil
        end

        MUI.db.global.profiles = nil
    end
end
