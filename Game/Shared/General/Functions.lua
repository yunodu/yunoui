local MUI = unpack(yunoUI)

local chatCommands = {}

function MUI:RunInstaller()
    local I = MUI:GetModule("Installer")

    local E, PI

    if InCombatLockdown() then
        return
    end

    if self:IsAddOnEnabled("ElvUI") then
        E = unpack(ElvUI)
        PI = E:GetModule("PluginInstaller")

        PI:Queue(I.installer)

        return
    end

    self:Print("ElvUI is required to run the installer.")
end

function chatCommands.install()
    MUI:RunInstaller()
end

function chatCommands.options()
    if MUI.OpenOptions then MUI:OpenOptions() end
end

function MUI:HandleChatCommand(input)
    local command = chatCommands[input]

    if not command then
        self:Print("Unknown command. Usage: /yunoui or /yui install | options")

        return
    end

    command()
end

function MUI:LoadProfiles()
    local SE = MUI:GetModule("Setup")

    for k in pairs(self.db.global.profiles) do
        if self:IsAddOnEnabled(k) then
            SE:Setup(k, true)
        end
    end

    self.db.char.loaded = true

    ReloadUI()
end
