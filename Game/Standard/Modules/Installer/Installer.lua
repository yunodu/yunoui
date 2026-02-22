local MUI = unpack(yunoUI)
local I = MUI:GetModule("Installer")
local SE = MUI:GetModule("Setup")

I.installer = {
    Title = "yunoUI Installation",
    Name = "yunoUI",
    tutorialImage = [[Interface\AddOns\yunoUI\Assets\logo.png]],
    tutorialImageSize = {400, 400},
    tutorialImagePoint = {0, -90},
    Pages = {
        [1] = function()
            if PluginInstallFrame.Option2 then PluginInstallFrame.Option2:Hide() end
            if PluginInstallFrame.Option3 then PluginInstallFrame.Option3:Hide() end
            if PluginInstallFrame.tutorialImage2 then PluginInstallFrame.tutorialImage2:Hide() end
            PluginInstallFrame.SubTitle:SetFormattedText("Welcome to %s", MUI.title)

            if not MUI.db.global.profiles then
                PluginInstallFrame.Desc1:SetText("To start the installation process, click on 'Continue'")

                return
            end

            PluginInstallFrame.Desc1:SetText("To load your installed profiles onto this character, click on 'Load Profiles'")
            PluginInstallFrame.Desc3:SetText("To start the installation process again, click on 'Continue'")
            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() StaticPopup_Show("yunoUI_LoadProfiles") end)
            PluginInstallFrame.Option1:SetText("Load Profiles")
        end,
        [2] = function()
            if PluginInstallFrame.Option3 then PluginInstallFrame.Option3:Hide() end
            PluginInstallFrame.SubTitle:SetText("yuno's cvars")
            PluginInstallFrame.Desc1:SetText("Apply nameplate, camera, and floating combat text cvars, or graphics settings, separately.")
            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("CVars", true, "cvars") end)
            PluginInstallFrame.Option1:SetText("Apply cvars")
            if PluginInstallFrame.Option2 then
                PluginInstallFrame.Option2:Show()
                PluginInstallFrame.Option2:SetScript("OnClick", function() SE:Setup("CVars", true, "graphics") end)
                PluginInstallFrame.Option2:SetText("Yuno's graphics")
            end
            if PluginInstallFrame.Option3 then
                PluginInstallFrame.Option3:Show()
                PluginInstallFrame.Option3:SetScript("OnClick", function() SE:Setup("CVars", true, "maxfps") end)
                PluginInstallFrame.Option3:SetText("Max FPS graphics")
            end
            -- cvars page: buttons 5px wider (ElvUI 3-btn = 100, we use 105, same scale API)
            local W = 105
            for _, opt in ipairs({ PluginInstallFrame.Option1, PluginInstallFrame.Option2, PluginInstallFrame.Option3 }) do
                if opt then
                    if opt.Width then opt:Width(W) else opt:SetWidth(W) end
                end
            end
        end,
        [3] = function()
            -- Hide all options first so ElvUI's OnShow layout runs (avoids overlap / wrong positions)
            if PluginInstallFrame.Option1 then PluginInstallFrame.Option1:Hide() end
            if PluginInstallFrame.Option2 then PluginInstallFrame.Option2:Hide() end
            if PluginInstallFrame.Option3 then PluginInstallFrame.Option3:Hide() end
            if PluginInstallFrame.Option4 then PluginInstallFrame.Option4:Hide() end
            PluginInstallFrame.SubTitle:SetText("ElvUI")
            PluginInstallFrame.Desc1:SetText("Import profile for your resolution.")
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("ElvUI", true) end)
            PluginInstallFrame.Option1:SetText("1440p")
            PluginInstallFrame.Option1:Show()
            if PluginInstallFrame.Option2 then
                PluginInstallFrame.Option2:SetScript("OnClick", function() SE:Setup("ElvUI", true, "Heal") end)
                PluginInstallFrame.Option2:SetText("1440p Heal")
                PluginInstallFrame.Option2:Show()
            end
            if PluginInstallFrame.Option3 then
                PluginInstallFrame.Option3:SetScript("OnClick", function() SE:Setup("ElvUI", true, "1080p") end)
                PluginInstallFrame.Option3:SetText("1080p")
                PluginInstallFrame.Option3:Show()
            end
            if PluginInstallFrame.Option4 then
                PluginInstallFrame.Option4:SetScript("OnClick", function() SE:Setup("ElvUI", true, "4k") end)
                PluginInstallFrame.Option4:SetText("4K")
                PluginInstallFrame.Option4:Show()
            end
        end,
        [4] = function()
            if PluginInstallFrame.Option2 then PluginInstallFrame.Option2:Hide() end
            if PluginInstallFrame.Option3 then PluginInstallFrame.Option3:Hide() end
            PluginInstallFrame.SubTitle:SetText("BetterCooldownManager")
            if not MUI:IsAddOnEnabled("BetterCooldownManager") then
                PluginInstallFrame.Desc1:SetText("Enable BetterCooldownManager to unlock this step")

                return
            end

            PluginInstallFrame.Desc1:SetText("Import profile for your resolution.")
            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("BetterCooldownManager", true) end)
            PluginInstallFrame.Option1:SetText("1440p")
            if PluginInstallFrame.Option2 then
                PluginInstallFrame.Option2:Show()
                PluginInstallFrame.Option2:SetScript("OnClick", function() SE:Setup("BetterCooldownManager", true, "1080p") end)
                PluginInstallFrame.Option2:SetText("1080p")
            end
        end,
        [5] = function()
            if PluginInstallFrame.Option2 then PluginInstallFrame.Option2:Hide() end
            if PluginInstallFrame.Option3 then PluginInstallFrame.Option3:Hide() end
            PluginInstallFrame.SubTitle:SetText("Cooldown Manager Centered")

            -- addon folder name = .toc
            if not MUI:IsAddOnEnabled("CooldownManagerCentered") then
                PluginInstallFrame.Desc1:SetText("Enable Cooldown Manager Centered to unlock this step")

                return
            end

            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("CooldownManagerCentered", true) end)
            PluginInstallFrame.Option1:SetText("Import")
        end,
        [6] = function()
            if PluginInstallFrame.Option2 then PluginInstallFrame.Option2:Hide() end
            if PluginInstallFrame.Option3 then PluginInstallFrame.Option3:Hide() end
            PluginInstallFrame.SubTitle:SetText("BigWigs")

            if not MUI:IsAddOnEnabled("BigWigs") then
                PluginInstallFrame.Desc1:SetText("Enable BigWigs to unlock this step")

                return
            end

            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("BigWigs", true) end)
            PluginInstallFrame.Option1:SetText("Import")
        end,
        [7] = function()
            if PluginInstallFrame.Option2 then PluginInstallFrame.Option2:Hide() end
            if PluginInstallFrame.Option3 then PluginInstallFrame.Option3:Hide() end
            PluginInstallFrame.SubTitle:SetText("Details")

            if not MUI:IsAddOnEnabled("Details") then
                PluginInstallFrame.Desc1:SetText("Enable Details to unlock this step")

                return
            end

            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("Details", true) end)
            PluginInstallFrame.Option1:SetText("Import")
        end,
        [8] = function()
            if PluginInstallFrame.Option2 then PluginInstallFrame.Option2:Hide() end
            if PluginInstallFrame.Option3 then PluginInstallFrame.Option3:Hide() end
            PluginInstallFrame.SubTitle:SetText("Platynator")

            if not MUI:IsAddOnEnabled("Platynator") then
                PluginInstallFrame.Desc1:SetText("Enable Platynator to unlock this step")

                return
            end

            PluginInstallFrame.Desc1:SetText("Import the yunoUI nameplate profile into Platynator. Paste your export string in Data\\Standard\\AddOns\\Platynator.lua first.")
            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("Platynator", true) end)
            PluginInstallFrame.Option1:SetText("Import")
        end,
        [9] = function()
            if PluginInstallFrame.Option2 then PluginInstallFrame.Option2:Hide() end
            if PluginInstallFrame.Option3 then PluginInstallFrame.Option3:Hide() end
            PluginInstallFrame.SubTitle:SetText("Blizzard Edit Mode")
            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("Blizzard_EditMode", true) end)
            PluginInstallFrame.Option1:SetText("Import")
        end,
        [10] = function()
            if PluginInstallFrame.Option2 then PluginInstallFrame.Option2:Hide() end
            if PluginInstallFrame.Option3 then PluginInstallFrame.Option3:Hide() end
            PluginInstallFrame.SubTitle:SetText("WarpDeplete")

            if not MUI:IsAddOnEnabled("WarpDeplete") then
                PluginInstallFrame.Desc1:SetText("Enable WarpDeplete to unlock this step")
                return
            end

            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("WarpDeplete", true) end)
            PluginInstallFrame.Option1:SetText("Import")
        end,
        [11] = function()
            if PluginInstallFrame.Option2 then PluginInstallFrame.Option2:Hide() end
            MUI:ApplyOptionDefaults()
            PluginInstallFrame.SubTitle:SetText("Installation Complete")
            PluginInstallFrame.Desc1:SetText("You have completed the installation process")
            PluginInstallFrame.Desc2:SetText("Please click on 'Reload' to save your settings and reload your UI")
            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() ReloadUI() end)
            PluginInstallFrame.Option1:SetText("Reload")
        end
    },
    StepTitles = {
        [1] = "Welcome",
        [2] = "yuno's cvars",
        [3] = "ElvUI",
        [4] = "BCM",
        [5] = "CDM Centered",
        [6] = "BigWigs",
        [7] = "Details",
        [8] = "Platynator",
        [9] = "Edit Mode",
        [10] = "WarpDeplete",
        [11] = "Complete"
    },
    StepTitlesColor = {1, 1, 1},
    StepTitlesColorSelected = {0, 179/255, 1},
    StepTitleWidth = 200,
    StepTitleButtonWidth = 180,
    StepTitleTextJustification = "RIGHT"
}
