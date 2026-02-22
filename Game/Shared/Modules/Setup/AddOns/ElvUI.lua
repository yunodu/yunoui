local MUI = unpack(yunoUI)
local SE = MUI:GetModule("Setup")

local E

do
    if MUI:IsAddOnEnabled("ElvUI") then
        E = unpack(ElvUI)
    end
end

-- private DB not in export, set in code on load
local function SetPrivateSettings()
    E.private.general.namefont              = "AvantGarde Bold"
    E.private.general.dmgfont               = "AvantGarde Bold"
    E.private.general.chatBubbleFont         = "AvantGarde Bold"
    E.private.general.chatBubbleFontSize     = 11
    E.private.general.chatBubbleFontOutline = "OUTLINE"
    E.private.general.glossTex              = "bar2"
    E.private.general.normTex               = "bar2"

    E.private.nameplates.enable              = false

    E.private.skins.parchmentRemoverEnable   = true
    E.private.skins.blizzard.cooldownManager = true

    if MUI:IsAddOnEnabled("ElvUI_WindTools") then
        E.private.WT.item.extendMerchantPages.enable        = true
        E.private.WT.item.extendMerchantPages.numberOfPages = 4

        E.private.WT.maps.minimapButtons.buttonSize     = 24
        E.private.WT.maps.minimapButtons.mouseOver      = true
        E.private.WT.maps.minimapButtons.spacing       = 1
        E.private.WT.maps.minimapButtons.backdropSpacing = 1
        E.private.WT.maps.instanceDifficulty.enable    = true
        E.private.WT.maps.instanceDifficulty.font.size = 10
        E.private.WT.maps.worldMap.scale.size           = 1.15

        E.private.WT.misc.lfgList.rightPanel.autoJoin           = true
        E.private.WT.misc.lfgList.rightPanel.disableSafeFilters = true
        E.private.WT.misc.lfgList.rightPanel.skipConfirmation   = true

        E.private.WT.unitFrames.roleIcon.roleIconStyle = "LYNUI"

        E.private.WT.skins.color.r = 0.062745101749897
        E.private.WT.skins.color.g = 0.062745101749897
        E.private.WT.skins.color.b = 0.062745101749897

        E.private.WT.skins.actionStatus.size = 14
        E.private.WT.skins.ime.label.name    = "AvantGarde Bold"

        E.private.WT.skins.libraries.libQTip      = false
        E.private.WT.skins.libraries.ace3          = false
        E.private.WT.skins.libraries.secureTabs    = false
        E.private.WT.skins.libraries.ace3Dropdown  = false

        E.private.WT.skins.addons.omniCD         = false
        E.private.WT.skins.addons.omniCDExtraBar = false
        E.private.WT.skins.addons.omniCDIcon     = false
        E.private.WT.skins.addons.worldQuestTab  = false

        E.private.WT.skins.cooldownViewer.essential.chargeCountText.name = "AvantGarde Bold"
        E.private.WT.skins.cooldownViewer.essential.chargeCountText.size = 8
        E.private.WT.skins.cooldownViewer.buffIcon.chargeCountText.name  = "AvantGarde Bold"
        E.private.WT.skins.cooldownViewer.buffIcon.chargeCountText.size  = 7
        E.private.WT.skins.cooldownViewer.buffBar.barTexture             = "bar7"
        E.private.WT.skins.cooldownViewer.utility.chargeCountText.name  = "AvantGarde Bold"
        E.private.WT.skins.cooldownViewer.utility.iconHeightRatio        = 0.6

        local wtBlizzardOff = {
            "eventTrace", "misc", "editModeManager", "tooltips", "uiErrors",
            "binding", "loot", "covenantPreview", "inspect", "barberShop",
            "guildBank", "professionsCustomerOrders", "garrison", "weeklyRewards",
            "raidInfo", "addonManager", "trade", "delves", "battlefieldMap",
            "challenges", "subscriptionInterstitial", "talkingHead", "bags",
            "debugTools", "achievements", "covenantRenown", "artifact",
            "auctionHouse", "playerChoice", "adventureMap", "mail", "flightMap",
            "collections", "warboard", "itemUpgrade", "guild", "timeManager",
            "scrappingMachine", "microButtons", "azerite", "soulbinds",
            "azeriteRespec", "calendar", "inputMethodEditor", "chromieTime",
            "gossip", "macro", "worldMap", "taxi", "lossOfControl", "perksProgram",
            "objectiveTracker", "stable", "itemInteraction", "majorFactions",
            "uiWidget", "communities", "azeriteEssence", "encounterJournal",
            "covenantSanctum", "tutorial", "channels", "ticketStatus", "alerts",
            "clickBinding", "petBattle", "orderHall", "professionBook", "help",
            "playerSpells", "professions", "mirrorTimers", "quest", "animaDiversion",
            "trainer", "dressingRoom", "settingsPanel", "itemSocketing", "merchant",
            "scenario", "friends", "blackMarket", "lookingForGroup", "staticPopup",
            "character", "expansionLandingPage", "genericTraits",
        }
        for _, key in ipairs(wtBlizzardOff) do
            E.private.WT.skins.blizzard[key] = false
        end
    end
end

local function ImportElvUI(addon, resolution)
    local PD = yunoUI_ProfileData
    local profile = "elvui" .. (resolution or "")
    local profileData = PD and PD[profile]
    if not profileData or type(profileData) ~= "table" or not profileData[1] then
        MUI:Print("No ElvUI profile data found. Check Data\\Standard\\AddOns\\ElvUI.lua")
        return
    end

    local DI = E.Distributor
    local profileType, _, data = DI:Decode(profileData[1])

    if not data or type(data) ~= "table" then
        MUI:Print("An error occurred while decompressing the ElvUI profile. Re-export from ElvUI Profiles > Share > Export.")

        return
    end

    DI:SetImportedProfile(profileType, "yuno", data, true)
    E:SetupCVars(true)

    E.data.global.general.UIScale = profileData[2]

    SetPrivateSettings()

    SE.CompleteSetup(addon)

    MUI.db.char.loaded = true
    MUI.db.global.version = MUI.version
end

function SE.ElvUI(addon, import, resolution)
    if not import then
        if not SE.IsProfileExisting(ElvDB) then
            SE.RemoveFromDatabase(addon)

            return
        end

        E.data:SetProfile("yuno")
        SetPrivateSettings()
    else
        ImportElvUI(addon, resolution)
    end
end
