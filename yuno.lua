local ADDON_NAME = ...

local FRAME_NAMES = {
    player = "EllesmereUIUnitFrames_Player",
    target = "EllesmereUIUnitFrames_Target",
    focus = "EllesmereUIUnitFrames_Focus",
    pet = "EllesmereUIUnitFrames_Pet",
    targettarget = "EllesmereUIUnitFrames_TargetTarget",
    focustarget = "EllesmereUIUnitFrames_FocusTarget",
    boss1 = "EllesmereUIUnitFrames_Boss1",
    boss2 = "EllesmereUIUnitFrames_Boss2",
    boss3 = "EllesmereUIUnitFrames_Boss3",
    boss4 = "EllesmereUIUnitFrames_Boss4",
    boss5 = "EllesmereUIUnitFrames_Boss5",
}

for i = 1, 4 do
    FRAME_NAMES["party" .. i] = "EllesmereUIUnitFrames_Party" .. i
end

for i = 1, 40 do
    FRAME_NAMES["raid" .. i] = "EllesmereUIUnitFrames_Raid" .. i
end

local DB_UNITS = {
    "player", "target", "focus",
    "pet", "targettarget", "focustarget", "totPet",
    "party", "raid", "boss",
}
local FONT_MEDIA = {
    { name = "Gilroy", path = "Interface\\AddOns\\yuno\\media\\Gilroy-Regular.ttf" },
    { name = "Gilroy SemiBold", path = "Interface\\AddOns\\yuno\\media\\Gilroy-SemiBold.ttf" },
    { name = "Gilroy Bold", path = "Interface\\AddOns\\yuno\\media\\Gilroy-Bold.ttf" },
}
local STATUSBAR_MEDIA = {
    { name = "Skyline Compact", path = "Interface\\AddOns\\yuno\\media\\bar_skyline_compact.png" },
}
local YUNO_THEME_NAME = "Custom Color"
local YUNO_THEME_COLOR = { r = 0x05 / 255, g = 0x1b / 255, b = 0x2d / 255 }
local YUNO_ACCENT_COLOR = { r = 0x00 / 255, g = 0xad / 255, b = 0xff / 255 }
local YUNO_UI_SCALE = 0.5333333333
local IDLE_FADE_ALPHA = 0.07
local IDLE_FADE_INTERVAL = 0.35
local COOLDOWN_VIEWER_FRAME_NAMES = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
    "BuffIconCooldownViewer",
    "BuffBarCooldownViewer",
}
local RESOURCE_BAR_FRAME_NAMES = {
    "ERB_HealthBar",
    "ERB_PrimaryBar",
    "ERB_SecondaryFrame",
    "ERB_SecondaryBar",
}
local pendingApply = false
local hookedReload
local hookedRaidReload
local startupRetryVersion = 0
local profileOfferScheduled = false
local freshInstallerOpenScheduled = false
local HookReload
local cooldownImportFrame
local installerFrame
local installedProfilesPromptFrame
local movementTrackerFrame
local movementTrackerTicker
local movementTrackerEventFrame
local fontsRegistered = false
local statusbarsRegistered = false
local friendlyNameplateCVarHooked = false
local actionBarPagingDeferFrame
local actionBarPagingOverrideApplied = false
local actionBarPagingBindOwner
local actionBarPagingKeybindHooked = false
local idleFadeFrame
local idleFadeTouchedFrames = {}
local raidFrameHealthCache = setmetatable({}, { __mode = "k" })
local raidFrameBackgroundCache = setmetatable({}, { __mode = "k" })
local PROFILE_PROMPT_VERSION = 1
local EXBOSS_IMPORT_SLOT_KEYS = {
    "raid_tank",
    "raid_dps",
    "raid_heal",
    "mplus_tank",
    "mplus_dps",
    "mplus_heal",
}
local EXBOSS_IMPORT_AUTHOR_SUFFIXES = {
    raid_tank = "\229\157\166\229\133\139",
    raid_dps = "DPS",
    raid_heal = "\230\178\187\231\150\151",
    mplus_tank = "\229\157\166\229\133\139",
    mplus_dps = "DPS",
    mplus_heal = "\230\178\187\231\150\151",
}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff0cd29fyuno:|r " .. tostring(msg))
end

local function RegisterFonts()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not LSM then return false end

    for _, font in ipairs(FONT_MEDIA) do
        LSM:Register(LSM.MediaType.FONT, font.name, font.path)
        if EllesmereUI then
            EllesmereUI._smFontPaths = EllesmereUI._smFontPaths or {}
            EllesmereUI._smFontPaths[font.name] = font.path
        end
    end

    fontsRegistered = true
    return true
end

local function RegisterStatusbars()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not LSM then return false end

    for _, bar in ipairs(STATUSBAR_MEDIA) do
        LSM:Register(LSM.MediaType.STATUSBAR, bar.name, bar.path)
    end

    statusbarsRegistered = true
    return true
end

local function RegisterMedia()
    local okFonts = RegisterFonts()
    local okBars = RegisterStatusbars()
    return okFonts or okBars
end

local BASE_CVARS = {
    accountNeedsTurnStrafeDialog = 0,
    advancedCombatLogging = 1,
    autoLootDefault = 1,
    autoLootRate = 150,
    cameraDistanceMaxZoomFactor = 2.6,
    cooldownViewerEnabled = 1,
    encounterTimelineEnabled = 0,
}

local FLOATING_COMBAT_TEXT_CVARS = {
    "floatingCombatTextCombatDamage_v2",
    "floatingCombatTextCombatHealing_v2",
    "floatingCombatTextCombatLogPeriodicSpells_v2",
    "floatingCombatTextPetMeleeDamage_v2",
    "floatingCombatTextPetSpellDamage_v2",
    "enableFloatingCombatText",
    "floatingCombatTextAuras",
    "floatingCombatTextCombatDamage",
    "floatingCombatTextCombatDamageAllAutos",
    "floatingCombatTextCombatHealing",
    "floatingCombatTextCombatHealingAbsorbSelf",
    "floatingCombatTextCombatHealingAbsorbTarget",
    "floatingCombatTextCombatLogPeriodicSpells",
    "floatingCombatTextCombatState",
    "floatingCombatTextComboPoints",
    "floatingCombatTextDamageReduction",
    "floatingCombatTextDodgeParryMiss",
    "floatingCombatTextEnergyGains",
    "floatingCombatTextFriendlyHealers",
    "floatingCombatTextHonorGains",
    "floatingCombatTextLowManaHealth",
    "floatingCombatTextPeriodicEnergyGains",
    "floatingCombatTextPetMeleeDamage",
    "floatingCombatTextPetSpellDamage",
    "floatingCombatTextReactives",
    "floatingCombatTextRepChanges",
    "floatingCombatTextSpellMechanics",
    "floatingCombatTextSpellMechanicsOther",
}

local MOVEMENT_TRACKER_ABILITIES = {
    DEATHKNIGHT = {[250] = {48265}, [251] = {48265}, [252] = {48265, 444010, 444347}},
    DEMONHUNTER = {[577] = {195072}, [581] = {189110}, [1480] = {1234796}},
    DRUID = {[102] = {102401, 252216, 1850, 102417}, [103] = {102401, 252216, 1850, 102417}, [104] = {102401, 252216, 106898, 1850, 102417}, [105] = {102401, 252216, 1850, 102417}},
    EVOKER = {[1467] = {358267}, [1468] = {358267}, [1473] = {358267}},
    HUNTER = {[253] = {186257, 781}, [254] = {186257, 781}, [255] = {186257, 781}},
    MAGE = {[62] = {212653, 1953}, [63] = {212653, 1953}, [64] = {212653, 1953}},
    MONK = {[268] = {115008, 109132, 119085, 361138}, [269] = {109132, 119085, 361138}, [270] = {109132, 119085, 361138}},
    PALADIN = {[65] = {190784}, [66] = {190784}, [70] = {190784}},
    PRIEST = {[256] = {121536, 73325}, [257] = {121536, 73325}, [258] = {121536, 73325}},
    ROGUE = {[259] = {36554, 2983}, [260] = {195457, 2983}, [261] = {36554, 2983}},
    SHAMAN = {[262] = {79206, 90328, 192063, 58875}, [263] = {90328, 192063, 58875}, [264] = {79206, 90328, 192063, 58875}},
    WARLOCK = {[265] = {48020, 111400}, [266] = {48020, 111400}, [267] = {48020, 111400}},
    WARRIOR = {[71] = {6544}, [72] = {6544}, [73] = {6544}},
}

local MOVEMENT_TRACKER_BUFF_ACTIVE = {
    [111400] = "Burning Rush Active!",
}

local FPS_CVARS = {
    { "graphicsShadowQuality",      "1" },
    { "graphicsLiquidDetail",       "0" },
    { "graphicsParticleDensity",    "5" },
    { "graphicsSSAO",               "0" },
    { "graphicsDepthEffects",       "0" },
    { "graphicsComputeEffects",     "0" },
    { "graphicsOutlineMode",        "0" },
    { "graphicsTextureResolution",  "2" },
    { "graphicsSpellDensity",       "1" },
    { "graphicsProjectedTextures",  "1" },
    { "graphicsViewDistance",       "1" },
    { "graphicsEnvironmentDetail",  "1" },
    { "graphicsGroundClutter",      "1" },
    { "RAIDsettingsEnabled",        "0" },
    { "ResampleAlwaysSharpen",      "1" },
    { "gxVSync",                    "0" },
    { "gxTripleBuffer",             "0" },
    { "maxFPSBk",                   "30" },
}

local YUNO_GRAPHICS_CVARS = {
    { "graphicsShadowQuality",      "2" },
    { "graphicsLiquidDetail",       "1" },
    { "graphicsParticleDensity",    "5" },
    { "graphicsSSAO",               "1" },
    { "graphicsDepthEffects",       "1" },
    { "graphicsComputeEffects",     "1" },
    { "graphicsOutlineMode",        "0" },
    { "graphicsTextureResolution",  "2" },
    { "graphicsSpellDensity",       "2" },
    { "graphicsProjectedTextures",  "1" },
    { "graphicsViewDistance",       "5" },
    { "graphicsEnvironmentDetail",  "5" },
    { "graphicsGroundClutter",      "3" },
    { "RAIDsettingsEnabled",        "0" },
    { "ResampleAlwaysSharpen",      "1" },
}

local function GetYunoCVar(name)
    if C_CVar and C_CVar.GetCVar then
        local value = C_CVar.GetCVar(name)
        if value ~= nil then return value end
    end

    if GetCVar then
        local ok, value = pcall(GetCVar, name)
        if ok then return value end
    end

    return nil
end

local function SetYunoCVar(name, value)
    if InCombatLockdown and InCombatLockdown() then return false end

    local text = tostring(value)
    local ok = false

    if SetCVar then
        ok = pcall(SetCVar, name, text)
    elseif C_CVar and C_CVar.SetCVar then
        ok = pcall(C_CVar.SetCVar, name, text)
    end

    return ok and GetYunoCVar(name) ~= nil
end

local function ApplyCVarTable(cvars)
    local applied = 0
    local skipped = 0

    for key, entry in pairs(cvars) do
        local name, value
        if type(entry) == "table" then
            name, value = entry[1], entry[2]
        else
            name, value = key, entry
        end

        if SetYunoCVar(name, value) then
            applied = applied + 1
        else
            skipped = skipped + 1
        end
    end

    return applied, skipped
end

local function ApplyFPSSettings()
    local applied, skipped = ApplyCVarTable(FPS_CVARS)
    if type(YunoDB) == "table" then YunoDB.graphicsPreset = "fps" end

    return applied, skipped
end

local function ApplyYunoGraphicsSettings()
    local applied, skipped = ApplyCVarTable(YUNO_GRAPHICS_CVARS)
    if type(YunoDB) == "table" then YunoDB.graphicsPreset = "yuno" end
    return applied, skipped
end

local function ApplyFloatingCombatText(value)
    local cvars = {}
    for _, name in ipairs(FLOATING_COMBAT_TEXT_CVARS) do
        cvars[name] = value
    end
    if type(YunoDB) == "table" then
        YunoDB.floatingCombatTextPreset = tonumber(value) == 1 and "enabled" or "disabled"
    end

    return ApplyCVarTable(cvars)
end

local ApplyChatSettings

local function TryLoadAddon(name)
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, name)
    elseif LoadAddOn then
        pcall(LoadAddOn, name)
    end
end

local function CopyPlainTable(src, dest)
    if type(dest) ~= "table" then dest = {} end
    if type(src) ~= "table" then return dest end

    for key, value in pairs(src) do
        if type(value) == "table" then
            dest[key] = CopyPlainTable(value, type(dest[key]) == "table" and dest[key] or {})
        else
            dest[key] = value
        end
    end

    return dest
end

local function ApplyYunoUIScale(applyLive)
    TryLoadAddon("EllesmereUI")

    if type(EllesmereUIDB) ~= "table" then EllesmereUIDB = {} end
    EllesmereUIDB.ppFixedScale = true
    EllesmereUIDB.ppUIScaleAuto = false
    EllesmereUIDB.ppUIScale = YUNO_UI_SCALE

    SetYunoCVar("useUiScale", 1)
    SetYunoCVar("uiScale", YUNO_UI_SCALE)

    if not applyLive then return end

    if EllesmereUI and EllesmereUI.PP and type(EllesmereUI.PP.SetUIScale) == "function" then
        pcall(EllesmereUI.PP.SetUIScale, YUNO_UI_SCALE)
    elseif UIParent and UIParent.SetScale and not (InCombatLockdown and InCombatLockdown()) then
        UIParent:SetScale(YUNO_UI_SCALE)
    end
end

local function ImportEllesmereUIProfile()
    local importString = YunoProfiles and YunoProfiles.ellesmereui
    if type(importString) ~= "string" or importString == "" then
        return false, "missing EllesmereUI profile string"
    end

    TryLoadAddon("EllesmereUI")

    if not EllesmereUI or type(EllesmereUI.ImportProfile) ~= "function" then
        return false, "EllesmereUI import API is not available"
    end

    local ok, success, err, status = pcall(EllesmereUI.ImportProfile, importString, "yuno")
    if not ok then
        return false, tostring(success)
    end
    if not success then
        return false, tostring(err or "EllesmereUI import failed")
    end

    if status == "spec_locked" then
        return true, "EllesmereUI profile imported as yuno; current spec keeps its assigned profile"
    end

    return true, "EllesmereUI profile imported as yuno"
end

local function ImportBigWigsProfile(callback)
    local importString = YunoProfiles and YunoProfiles.bigwigs
    if type(importString) ~= "string" or importString == "" then
        return false, "missing BigWigs profile string"
    end

    TryLoadAddon("BigWigs")

    if not BigWigsAPI or type(BigWigsAPI.RegisterProfile) ~= "function" then
        return false, "BigWigs import API is not available"
    end

    local ok, err = pcall(BigWigsAPI.RegisterProfile, "yuno", importString, "yuno", callback)
    if not ok then
        return false, tostring(err)
    end

    return true, "BigWigs import confirmation opened"
end

local function ImportEditModeLayout()
    local importString = YunoProfiles and YunoProfiles.editmode
    if type(importString) ~= "string" or importString == "" then
        return false, "missing Edit Mode layout string"
    end
    if InCombatLockdown and InCombatLockdown() then
        return false, "Edit Mode layout cannot be imported in combat"
    end
    if not C_EditMode or type(C_EditMode.GetLayouts) ~= "function" or type(C_EditMode.ConvertStringToLayoutInfo) ~= "function" then
        return false, "Edit Mode import API is not available"
    end

    local okLayouts, layouts = pcall(C_EditMode.GetLayouts)
    if not okLayouts or type(layouts) ~= "table" or type(layouts.layouts) ~= "table" then
        return false, "Edit Mode layouts are not available"
    end

    for i = #layouts.layouts, 1, -1 do
        if layouts.layouts[i].layoutName == "yuno" then
            tremove(layouts.layouts, i)
        end
    end

    if #layouts.layouts >= 5 then
        return false, "maximum Edit Mode layouts already reached"
    end

    local okInfo, info = pcall(C_EditMode.ConvertStringToLayoutInfo, importString)
    if not okInfo or type(info) ~= "table" then
        return false, "Edit Mode import string is invalid"
    end

    info.layoutName = "yuno"
    info.layoutType = Enum and Enum.EditModeLayoutType and Enum.EditModeLayoutType.Account or info.layoutType

    tinsert(layouts.layouts, info)

    local okSave, saveErr = pcall(C_EditMode.SaveLayouts, layouts)
    if not okSave then
        return false, tostring(saveErr)
    end

    local presetCount = Enum and Enum.EditModePresetLayoutsMeta and Enum.EditModePresetLayoutsMeta.NumValues or 0
    local newIndex = presetCount + #layouts.layouts
    if type(C_EditMode.OnLayoutAdded) == "function" then
        pcall(C_EditMode.OnLayoutAdded, newIndex, true, true)
    end
    if type(C_EditMode.SetActiveLayout) == "function" then
        pcall(C_EditMode.SetActiveLayout, newIndex)
    end
    if type(C_EditMode.SetAccountSetting) == "function" then
        pcall(C_EditMode.SetAccountSetting, 22, 0)
        pcall(C_EditMode.SetAccountSetting, 0, 0)
    end

    return true, "Edit Mode layout imported as yuno"
end

local function ImportBlinkiisPortraitsProfile()
    local importString = YunoProfiles and YunoProfiles.blinkiiportraits
    if type(importString) ~= "string" or importString == "" then
        return false, "missing Blinkii's Portraits profile string"
    end

    TryLoadAddon("Blinkiis_Portraits")

    if not LibStub then return false, "LibStub is not available" end
    local LibSerialize = LibStub("LibSerialize", true)
    local LibDeflate = LibStub("LibDeflate", true)
    if not LibSerialize or not LibDeflate then
        return false, "Blinkii's Portraits import libraries are not available"
    end
    if not BLINKIISPORTRAITS or not BLINKIISPORTRAITS.db then
        return false, "Blinkii's Portraits profile database is not available"
    end
    if not importString:match("^!BP") then
        return false, "Blinkii's Portraits import string is invalid"
    end

    local encoded = importString:gsub("^!BP", "")
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then return false, "Blinkii's Portraits import string could not be decoded" end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return false, "Blinkii's Portraits import string could not be decompressed" end

    local ok, importDB = LibSerialize:Deserialize(decompressed)
    if not ok or type(importDB) ~= "table" or type(importDB.profile) ~= "table" then
        return false, "Blinkii's Portraits import string is corrupted"
    end

    BLINKIISPORTRAITS.db.profiles = BLINKIISPORTRAITS.db.profiles or {}
    local profile = CopyPlainTable(BLINKIISPORTRAITS.defaults and BLINKIISPORTRAITS.defaults.profile or {})
    CopyPlainTable(importDB.profile, profile)
    BLINKIISPORTRAITS.db.profiles.yuno = profile

    local setOk, setErr = pcall(BLINKIISPORTRAITS.db.SetProfile, BLINKIISPORTRAITS.db, "yuno")
    if not setOk then return false, tostring(setErr) end

    if type(BLINKIISPORTRAITS.LoadPortraits) == "function" then
        pcall(BLINKIISPORTRAITS.LoadPortraits, BLINKIISPORTRAITS)
    end

    return true, "Blinkii's Portraits profile imported as yuno"
end

local function ImportEXBossProfile()
    local importString = YunoProfiles and YunoProfiles.exboss
    if type(importString) ~= "string" or importString == "" then
        return false, "missing EXBoss profile string"
    end

    TryLoadAddon("EXBoss")

    local IE = ExBoss and ExBoss.Voice and ExBoss.Voice.ImportExport
    if not IE or type(IE.DecodePayload) ~= "function" or type(IE.GetImportSummary) ~= "function" or type(IE.Import) ~= "function" then
        return false, "EXBoss import API is not available"
    end

    local payload, decodeErr = IE:DecodePayload(importString)
    if not payload then
        return false, "EXBoss import string is invalid: " .. tostring(decodeErr)
    end

    local summary, summaryErr = IE:GetImportSummary(payload)
    if not summary then
        return false, "EXBoss import summary failed: " .. tostring(summaryErr)
    end

    local importSlots = {}
    local hasSlot = false
    local availableSlots = type(summary.slotAvailability) == "table" and summary.slotAvailability or {}
    for _, slotKey in ipairs(EXBOSS_IMPORT_SLOT_KEYS) do
        if availableSlots[slotKey] == true then
            importSlots[slotKey] = true
            hasSlot = true
        end
    end

    local options = {
        importAppearance = summary.hasAppearance == true,
        importTrashCD = summary.hasTrashCD == true,
        importSlots = importSlots,
        namePrefix = "yuno",
    }
    if not options.importAppearance and not options.importTrashCD and not hasSlot then
        return false, "EXBoss import string has no supported profile sections"
    end

    local ok, imported, err = pcall(IE.Import, IE, payload, options)
    if not ok then
        return false, tostring(imported)
    end
    if not imported then
        return false, tostring(err or "EXBoss import failed")
    end

    return true, "EXBoss profile imported as yuno"
end

local function EnsureDB()
    if type(YunoDB) ~= "table" then YunoDB = {} end
    if YunoDB.autoPresetVersion ~= 1 then
        YunoDB.enabled = true
        YunoDB.classBackground = true
        YunoDB.darkOpacity = true
        YunoDB.forceDarkMode = true
        YunoDB.forceEUITheme = true
        YunoDB.forceOpacity = true
        YunoDB.forceChatSidebarRight = true
        YunoDB.disableFriendlyPlayerNameplates = true
        YunoDB.fadeIdlePlayerAndCooldowns = false
        YunoDB.healthBarOpacity = 85
        YunoDB.tint = 0.75
        YunoDB.autoPresetVersion = 1
    end
    if YunoDB.enabled == nil then YunoDB.enabled = true end
    if YunoDB.classBackground == nil then YunoDB.classBackground = true end
    if YunoDB.darkOpacity == nil then YunoDB.darkOpacity = true end
    if YunoDB.forceDarkMode == nil then YunoDB.forceDarkMode = true end
    if YunoDB.forceEUITheme == nil then YunoDB.forceEUITheme = true end
    if YunoDB.forceOpacity == nil then YunoDB.forceOpacity = true end
    if YunoDB.forceChatSidebarRight == nil then YunoDB.forceChatSidebarRight = true end
    if YunoDB.disableFriendlyPlayerNameplates == nil then YunoDB.disableFriendlyPlayerNameplates = true end
    if YunoDB.fadeIdlePlayerAndCooldowns == nil then YunoDB.fadeIdlePlayerAndCooldowns = false end
    if YunoDB.disableEllesmereActionBarPaging == nil then YunoDB.disableEllesmereActionBarPaging = false end
    if type(YunoDB.healthBarOpacity) ~= "number" then YunoDB.healthBarOpacity = 85 end
    if type(YunoDB.tint) ~= "number" then YunoDB.tint = 0.75 end
    if type(YunoDB.profilePromptApplied) ~= "table" then YunoDB.profilePromptApplied = {} end
    if type(YunoDB.profilePromptDismissed) ~= "table" then YunoDB.profilePromptDismissed = {} end
    if YunoDB.profilePromptEnabled == nil then YunoDB.profilePromptEnabled = true end
    if YunoDB.graphicsPreset ~= "fps" and YunoDB.graphicsPreset ~= "yuno" then YunoDB.graphicsPreset = nil end
    if YunoDB.floatingCombatTextPreset ~= "enabled" and YunoDB.floatingCombatTextPreset ~= "disabled" then YunoDB.floatingCombatTextPreset = nil end
    if type(YunoDB.qol) ~= "table" then YunoDB.qol = {} end
    if type(YunoDB.qol.movementTracker) ~= "table" then YunoDB.qol.movementTracker = {} end
    local movement = YunoDB.qol.movementTracker
    if movement.enabled == nil then movement.enabled = false end
    if movement.unlock == nil then movement.unlock = false end
    if movement.combatOnly == nil then movement.combatOnly = false end
    if type(movement.point) ~= "string" then movement.point = "CENTER" end
    if type(movement.x) ~= "number" then movement.x = 0 end
    if type(movement.y) ~= "number" then movement.y = 50 end
    if type(movement.width) ~= "number" then movement.width = 220 end
    if type(movement.height) ~= "number" then movement.height = 48 end
    if type(movement.pollRate) ~= "number" then movement.pollRate = 100 end
    if type(movement.fontSize) ~= "number" then movement.fontSize = 12 end
    if movement.fontSize < 8 then movement.fontSize = 8 end
    if movement.fontSize > 32 then movement.fontSize = 32 end
    if YunoDB.healthBarOpacity < 0 then YunoDB.healthBarOpacity = 0 end
    if YunoDB.healthBarOpacity > 100 then YunoDB.healthBarOpacity = 100 end
    if YunoDB.tint < 0 then YunoDB.tint = 0 end
    if YunoDB.tint > 1 then YunoDB.tint = 1 end
end

local function GetMovementTrackerDB()
    EnsureDB()
    return YunoDB.qol.movementTracker
end

local function ResolvePlayerSpecId()
    if not GetSpecialization or not GetSpecializationInfo then return nil end
    local spec = GetSpecialization()
    if not spec then return nil end
    local specId = select(1, GetSpecializationInfo(spec))
    if specId and specId > 0 then return specId end
    return nil
end

local function IsYunoPlayerSpell(spellId)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, spellId)
        if ok and known then return true end
    end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, spellId)
        if ok and known then return true end
    end
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, spellId)
        if ok and known then return true end
    end
    return false
end

local function ResolveMovementSpellId(spellId)
    if C_Spell and C_Spell.GetOverrideSpell then
        local ok, overrideId = pcall(C_Spell.GetOverrideSpell, spellId)
        if ok and overrideId and overrideId > 0 then return overrideId end
    end
    return spellId
end

local function GetMovementTrackerSpells()
    local _, class = UnitClass("player")
    local specId = ResolvePlayerSpecId()
    local classData = class and MOVEMENT_TRACKER_ABILITIES[class]
    local specData = classData and specId and classData[specId]
    local spells = {}
    local seen = {}

    if not specData then return spells end

    for _, baseSpellId in ipairs(specData) do
        local spellId = ResolveMovementSpellId(baseSpellId)
        if not seen[spellId] and (IsYunoPlayerSpell(baseSpellId) or IsYunoPlayerSpell(spellId)) then
            local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellId)
            if spellInfo then
                spells[#spells + 1] = {
                    spellId = spellId,
                    baseSpellId = baseSpellId ~= spellId and baseSpellId or nil,
                    name = spellInfo.name or tostring(spellId),
                    icon = spellInfo.iconID,
                    activeText = MOVEMENT_TRACKER_BUFF_ACTIVE[spellId] or MOVEMENT_TRACKER_BUFF_ACTIVE[baseSpellId],
                }
                seen[spellId] = true
            end
        end
    end

    return spells
end

local function GetMovementCooldownRemaining(entry)
    local spellId = entry.baseSpellId or entry.spellId
    local charges = C_Spell and C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(spellId)
    if charges and charges.maxCharges and charges.maxCharges > 1 then
        local current = charges.currentCharges or charges.charges or charges.maxCharges
        if current and current > 0 then return 0 end
        local startTime = charges.cooldownStartTime or charges.startTime or 0
        local duration = charges.cooldownDuration or charges.duration or 0
        if duration and duration > 0 then
            return math.max(0, (startTime + duration) - GetTime())
        end
    end

    local cooldown = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(spellId)
    if not cooldown or not cooldown.duration or cooldown.duration <= 1.5 then return 0 end
    if cooldown.isEnabled == false then return 0 end

    local startTime = cooldown.startTime or 0
    return math.max(0, (startTime + cooldown.duration) - GetTime())
end

local function IsMovementBuffActive(entry)
    if not entry.activeText then return false end
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        if C_UnitAuras.GetPlayerAuraBySpellID(entry.spellId) then return true end
        if entry.baseSpellId and C_UnitAuras.GetPlayerAuraBySpellID(entry.baseSpellId) then return true end
    end
    return false
end

local function SaveMovementTrackerPoint(frame)
    local db = GetMovementTrackerDB()
    local point, _, _, x, y = frame:GetPoint(1)
    db.point = point or "CENTER"
    db.x = x or 0
    db.y = y or 50
end

local function CreateMovementTrackerFrame()
    if movementTrackerFrame then return movementTrackerFrame end

    local frame = CreateFrame("Frame", "YunoMovementTrackerFrame", UIParent)
    frame:SetSize(220, 48)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if GetMovementTrackerDB().unlock then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveMovementTrackerPoint(self)
    end)

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0x12 / 255, 0x12 / 255, 0x16 / 255, 0.78)

    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetPoint("CENTER")
    frame.text:SetJustifyH("CENTER")
    frame.text:SetJustifyV("MIDDLE")

    movementTrackerFrame = frame
    return frame
end

local UpdateMovementTrackerDisplay

local function StopMovementTrackerTicker()
    if movementTrackerTicker then
        movementTrackerTicker:Cancel()
        movementTrackerTicker = nil
    end
end

local function StartMovementTrackerTicker()
    local db = GetMovementTrackerDB()
    if movementTrackerTicker or not db.enabled then return end
    local interval = math.max(50, db.pollRate or 100) / 1000
    movementTrackerTicker = C_Timer.NewTicker(interval, function()
        UpdateMovementTrackerDisplay()
    end)
end

UpdateMovementTrackerDisplay = function()
    local db = GetMovementTrackerDB()
    local frame = CreateMovementTrackerFrame()
    frame:ClearAllPoints()
    frame:SetPoint(db.point or "CENTER", UIParent, db.point or "CENTER", db.x or 0, db.y or 50)
    frame:SetSize(db.width or 220, db.height or 48)
    frame:EnableMouse(db.enabled and db.unlock)
    if db.enabled and db.unlock then
        frame.bg:Show()
    else
        frame.bg:Hide()
    end

    local fontSize = math.max(8, math.min(32, tonumber(db.fontSize) or 12))
    if not frame.text:SetFont(FONT_MEDIA[3].path, fontSize, "OUTLINE") then
        frame.text:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    end
    frame.text:SetTextColor(1, 1, 1, 1)

    if not db.enabled then
        StopMovementTrackerTicker()
        frame:Hide()
        return
    end

    if db.unlock then
        frame.text:SetText("MOVEMENT TRACKER")
        frame:Show()
        StopMovementTrackerTicker()
        return
    end

    if db.combatOnly and not (UnitAffectingCombat and UnitAffectingCombat("player")) then
        StopMovementTrackerTicker()
        frame:Hide()
        return
    end

    local lines = {}
    for _, entry in ipairs(GetMovementTrackerSpells()) do
        if IsMovementBuffActive(entry) then
            lines[#lines + 1] = entry.activeText
        else
            local remaining = GetMovementCooldownRemaining(entry)
            if remaining and remaining > 0 then
                lines[#lines + 1] = string.format("No %s %.1f", entry.name, remaining)
            end
        end
    end

    if #lines == 0 then
        StopMovementTrackerTicker()
        frame:Hide()
        return
    end

    frame.text:SetText(table.concat(lines, "\n"))
    frame:Show()
    StartMovementTrackerTicker()
end

local function GetMovementTrackerSpellSummary()
    local names = {}
    for _, entry in ipairs(GetMovementTrackerSpells()) do
        names[#names + 1] = entry.name
    end
    if #names == 0 then return "none for current spec" end
    return table.concat(names, ", ")
end

local function InitializeMovementTrackerEvents()
    if movementTrackerEventFrame then return end
    movementTrackerEventFrame = CreateFrame("Frame")
    movementTrackerEventFrame:RegisterEvent("PLAYER_LOGIN")
    movementTrackerEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    movementTrackerEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    movementTrackerEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    movementTrackerEventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    movementTrackerEventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    movementTrackerEventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    movementTrackerEventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    movementTrackerEventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
    movementTrackerEventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    movementTrackerEventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_AURA" and unit ~= "player" then return end
        UpdateMovementTrackerDisplay()
    end)
end

local function ApplyFriendlyPlayerNameplatePreference()
    EnsureDB()
    if not YunoDB.disableFriendlyPlayerNameplates then return false end

    local changed = false
    if GetYunoCVar("nameplateShowFriendlyPlayers") ~= "0" then
        changed = SetYunoCVar("nameplateShowFriendlyPlayers", 0) or changed
    end
    if GetYunoCVar("nameplateShowFriends") ~= "0" then
        changed = SetYunoCVar("nameplateShowFriends", 0) or changed
    end

    return changed
end

local function ScheduleFriendlyPlayerNameplatePreference(delay)
    C_Timer.After(delay or 0, function()
        ApplyFriendlyPlayerNameplatePreference()
    end)
end

local function HookFriendlyPlayerNameplateCVars()
    if friendlyNameplateCVarHooked or not hooksecurefunc then return end

    local function WatchFriendlyNameplateCVar(name, value)
        if type(YunoDB) ~= "table" or not YunoDB.disableFriendlyPlayerNameplates then return end
        if name ~= "nameplateShowFriendlyPlayers" and name ~= "nameplateShowFriends" then return end
        if tostring(value) == "0" then return end
        ScheduleFriendlyPlayerNameplatePreference(0)
    end

    if SetCVar then pcall(hooksecurefunc, "SetCVar", WatchFriendlyNameplateCVar) end
    if C_CVar and C_CVar.SetCVar then pcall(hooksecurefunc, C_CVar, "SetCVar", WatchFriendlyNameplateCVar) end
    friendlyNameplateCVarHooked = true
end

local function RestoreIdleFadeFrames()
    for frame in pairs(idleFadeTouchedFrames) do
        if frame and type(frame.SetAlpha) == "function" then
            pcall(frame.SetAlpha, frame, frame._yunoIdleFadeBaseAlpha or 1)
            frame._yunoIdleFaded = nil
            frame._yunoIdleFadeBaseAlpha = nil
        end
    end
    for frame in pairs(idleFadeTouchedFrames) do
        idleFadeTouchedFrames[frame] = nil
    end
end

local function ShouldIdleFade()
    EnsureDB()
    if not YunoDB.enabled then return false end
    if YunoDB.fadeIdlePlayerAndCooldowns ~= true then return false end

    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "party" or instanceType == "raid") then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    if UnitAffectingCombat and UnitAffectingCombat("player") then return false end
    if UnitExists and UnitExists("target") then return false end

    return true
end

local function ForEachIdleFadeFrame(callback)
    local seen = {}
    local function Visit(frame)
        if not frame or seen[frame] or type(frame.SetAlpha) ~= "function" or type(frame.GetAlpha) ~= "function" then return end
        seen[frame] = true
        callback(frame)
    end

    Visit(_G[FRAME_NAMES.player])
    for _, name in ipairs(COOLDOWN_VIEWER_FRAME_NAMES) do
        Visit(_G[name])
    end
    for _, name in ipairs(RESOURCE_BAR_FRAME_NAMES) do
        Visit(_G[name])
    end

    local getBarFrame = _G._ECME_GetBarFrame
    local cdmDB = _G._ECME_AceDB
    local bars = cdmDB and cdmDB.profile and cdmDB.profile.cdmBars and cdmDB.profile.cdmBars.bars
    if type(getBarFrame) == "function" and type(bars) == "table" then
        for _, barData in ipairs(bars) do
            if type(barData) == "table" and barData.enabled ~= false and barData.key then
                Visit(getBarFrame(barData.key))
            end
        end
    end

    for i = 1, 20 do
        Visit(_G["ECME_TBBWrap" .. i])
    end
end

local function ApplyIdleFadeState()
    if not ShouldIdleFade() then
        RestoreIdleFadeFrames()
        return
    end

    ForEachIdleFadeFrame(function(frame)
        local alpha = frame:GetAlpha() or 1
        if alpha <= 0 then
            frame._yunoIdleFaded = nil
            frame._yunoIdleFadeBaseAlpha = nil
            idleFadeTouchedFrames[frame] = nil
            return
        end

        if not frame._yunoIdleFaded or math.abs(alpha - IDLE_FADE_ALPHA) > 0.001 then
            frame._yunoIdleFadeBaseAlpha = alpha
        end
        frame._yunoIdleFaded = true
        idleFadeTouchedFrames[frame] = true
        frame:SetAlpha(IDLE_FADE_ALPHA)
    end)
end

local function UpdateIdleFadeController()
    EnsureDB()

    if YunoDB.enabled and YunoDB.fadeIdlePlayerAndCooldowns == true then
        if not idleFadeFrame then
            idleFadeFrame = CreateFrame("Frame")
        end
        idleFadeFrame.elapsed = IDLE_FADE_INTERVAL
        idleFadeFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed < IDLE_FADE_INTERVAL then return end
            self.elapsed = 0
            ApplyIdleFadeState()
        end)
        ApplyIdleFadeState()
    else
        if idleFadeFrame then idleFadeFrame:SetScript("OnUpdate", nil) end
        RestoreIdleFadeFrames()
    end
end

local function ScheduleIdleFadeUpdate(delay)
    C_Timer.After(delay or 0, UpdateIdleFadeController)
end

local function UnitKey(unit)
    if not unit then return nil end
    if unit:match("^boss%d+$") then return "boss" end
    if unit:match("^party%d+$") then return "party" end
    if unit:match("^raid%d+$") then return "raid" end
    return unit
end

local function LegacyMiniUnitKey(unit)
    return (unit == "pet" or unit == "targettarget" or unit == "focustarget") and "totPet" or nil
end

local function GetEllesmereAddonProfile(addonName)
    local root = _G.EllesmereUIDB
    if type(root) ~= "table" then return nil end
    local profileName = root.activeProfile or "Default"
    local profile = root.profiles and root.profiles[profileName]
    local addons = profile and profile.addons
    return addons and addons[addonName]
end

local function GetEllesmereProfile()
    return GetEllesmereAddonProfile("EllesmereUIUnitFrames")
end

local function GetEllesmereRaidFramesProfile()
    return GetEllesmereAddonProfile("EllesmereUIRaidFrames")
end

local function CopyColor(color)
    return { r = color.r, g = color.g, b = color.b }
end

local function SameColor(left, right)
    if type(left) ~= "table" then return false end
    return math.abs((left.r or 0) - right.r) < 0.00001 and
        math.abs((left.g or 0) - right.g) < 0.00001 and
        math.abs((left.b or 0) - right.b) < 0.00001
end

local function ApplyEllesmereThemeSettings(forceLive, refreshOptions)
    if not YunoDB.forceEUITheme then return false end

    local root = _G.EllesmereUIDB
    if type(root) ~= "table" then return false end

    local changed = false
    if root.activeTheme ~= YUNO_THEME_NAME then
        root.activeTheme = YUNO_THEME_NAME
        changed = true
    end

    if not SameColor(root.accentColor, YUNO_THEME_COLOR) then
        root.accentColor = CopyColor(YUNO_THEME_COLOR)
        changed = true
    end

    if root.useClassAccentColor ~= false then
        root.useClassAccentColor = false
        changed = true
    end

    if not SameColor(root.customAccentColor, YUNO_ACCENT_COLOR) then
        root.customAccentColor = CopyColor(YUNO_ACCENT_COLOR)
        changed = true
    end

    if EllesmereUI and (changed or forceLive or refreshOptions) then
        if type(EllesmereUI.SetActiveTheme) == "function" then
            EllesmereUI.SetActiveTheme(YUNO_THEME_NAME)
        end

        if type(EllesmereUI.SetAccentColor) == "function" then
            EllesmereUI.SetAccentColor(YUNO_ACCENT_COLOR.r, YUNO_ACCENT_COLOR.g, YUNO_ACCENT_COLOR.b)
        elseif type(EllesmereUI.ApplyAccentColorLive) == "function" then
            EllesmereUI.ApplyAccentColorLive(YUNO_ACCENT_COLOR.r, YUNO_ACCENT_COLOR.g, YUNO_ACCENT_COLOR.b)
        end

        if refreshOptions and type(EllesmereUI.RefreshPage) == "function" then
            EllesmereUI:RefreshPage()
        end
    end

    return changed
end

local function EnsureEllesmereAddonProfile(addonName)
    local root = _G.EllesmereUIDB
    if type(root) ~= "table" then return nil end
    local profileName = root.activeProfile or "Default"
    root.profiles = root.profiles or {}
    root.profiles[profileName] = root.profiles[profileName] or {}
    root.profiles[profileName].addons = root.profiles[profileName].addons or {}
    root.profiles[profileName].addons[addonName] = root.profiles[profileName].addons[addonName] or {}
    return root.profiles[profileName].addons[addonName]
end

local function ApplyChatSidebarPosition()
    local cf1 = _G.ChatFrame1
    local getData = EllesmereUI and EllesmereUI._chatCFD
    local data = cf1 and getData and getData(cf1)
    local sidebar = data and data.sidebar
    local bg = data and data.bg
    if not sidebar or not bg then return false end

    sidebar:ClearAllPoints()
    if YunoDB.forceChatSidebarRight then
        sidebar:SetPoint("TOPLEFT", bg, "TOPRIGHT", 0, 0)
        sidebar:SetPoint("BOTTOMLEFT", bg, "BOTTOMRIGHT", 0, 0)
    else
        sidebar:SetPoint("TOPRIGHT", bg, "TOPLEFT", 0, 0)
        sidebar:SetPoint("BOTTOMRIGHT", bg, "BOTTOMLEFT", 0, 0)
    end

    if data.sidebarDiv then
        data.sidebarDiv:ClearAllPoints()
        if YunoDB.forceChatSidebarRight then
            data.sidebarDiv:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, 0)
            data.sidebarDiv:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 0, 0)
        else
            data.sidebarDiv:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", 0, 0)
            data.sidebarDiv:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0, 0)
        end
    end

    return true
end

local function ApplyChatRuntimePreset(chat)
    local getData = EllesmereUI and EllesmereUI._chatCFD
    if not getData then return end

    for i = 1, 20 do
        local cf = _G["ChatFrame" .. i]
        local data = cf and getData(cf)
        if data and data.bg then
            local bgTex = data.bg:GetRegions()
            if bgTex and bgTex.SetColorTexture then
                bgTex:SetColorTexture(chat.bgR, chat.bgG, chat.bgB, chat.bgAlpha)
            end

            local editBox = _G["ChatFrame" .. i .. "EditBox"]
            if editBox then
                editBox:ClearAllPoints()
                if chat.inputOnTop then
                    editBox:SetPoint("TOPLEFT", cf, "TOPLEFT", -10, 3)
                    editBox:SetPoint("TOPRIGHT", cf, "TOPRIGHT", 5, 3)
                else
                    editBox:SetPoint("TOPLEFT", cf, "BOTTOMLEFT", -10, -8)
                    editBox:SetPoint("TOPRIGHT", cf, "BOTTOMRIGHT", 5, -8)
                end
            end

            if data.inputDiv then
                data.inputDiv:ClearAllPoints()
                if chat.inputOnTop then
                    data.inputDiv:SetPoint("TOPLEFT", cf, "TOPLEFT", -10, -20)
                    data.inputDiv:SetPoint("TOPRIGHT", cf, "TOPRIGHT", 10, -20)
                else
                    data.inputDiv:SetPoint("BOTTOMLEFT", cf, "BOTTOMLEFT", -10, -8)
                    data.inputDiv:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", 10, -8)
                end
            end

            data.bg:ClearAllPoints()
            data.bg:SetPoint("TOPLEFT", cf, "TOPLEFT", -10, 3)
            if chat.inputOnTop then
                data.bg:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", 10, -6)
            else
                data.bg:SetPoint("BOTTOMRIGHT", editBox or cf, "BOTTOMRIGHT", 5, editBox and -4 or -6)
            end

            if cf.FontStringContainer then
                cf.FontStringContainer:ClearAllPoints()
                if chat.inputOnTop then
                    cf.FontStringContainer:SetPoint("TOPLEFT", cf, "TOPLEFT", 0, -22)
                else
                    cf.FontStringContainer:SetPoint("TOPLEFT", cf, "TOPLEFT", 0, -6)
                end
                cf.FontStringContainer:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", 0, 0)
            end

            if data.scrollTrack then
                data.scrollTrack:ClearAllPoints()
                if chat.inputOnTop then
                    data.scrollTrack:SetPoint("TOPRIGHT", cf, "TOPRIGHT", 5, -22)
                else
                    data.scrollTrack:SetPoint("TOPRIGHT", cf, "TOPRIGHT", 5, -2)
                end
                data.scrollTrack:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", 5, 2)
            end
        end

        local tab = _G["ChatFrame" .. i .. "Tab"]
        local tabData = tab and getData(tab)
        if tabData and tabData.bg and tabData.bg.SetColorTexture then
            local active = tabData.underline and tabData.underline:IsShown()
            tabData.bg:SetColorTexture(chat.bgR, chat.bgG, chat.bgB, active and chat.bgAlpha or (chat.bgAlpha * 0.67))
        end
    end

    local cf1 = _G.ChatFrame1
    local data = cf1 and getData(cf1)
    if not data then return end

    if data.sidebar then
        data.sidebar:SetAlpha(1)
        data.sidebar:EnableMouse(true)
        local sbBg = data.sidebar:GetRegions()
        if sbBg and sbBg.SetColorTexture then
            sbBg:SetColorTexture(chat.bgR, chat.bgG, chat.bgB, chat.bgAlpha)
        end
        if sbBg and sbBg.SetShown then
            sbBg:SetShown(not chat.hideSidebarBg)
        end
    end

    if data.sidebarDiv then
        data.sidebarDiv:SetShown(not chat.hideSidebarBg)
    end

    local iconR, iconG, iconB = chat.iconR or 1, chat.iconG or 1, chat.iconB or 1
    for _, button in ipairs({ data.friendsBtn, data.copyBtn, data.portalBtn, data.voiceBtn, data.settingsBtn, data.scrollBtn }) do
        if button then
            button:SetScale(chat.sidebarIconScale or 1)
            if button._icon and button._icon.SetVertexColor then
                button._icon:SetVertexColor(iconR, iconG, iconB, 0.4)
            end
        end
    end

    if data.friendsBtn then data.friendsBtn:SetShown(chat.showFriends ~= false) end
    if data.copyBtn then data.copyBtn:SetShown(chat.showCopy ~= false) end
    if data.portalBtn then data.portalBtn:SetShown(chat.showPortals ~= false) end
    if data.voiceBtn then data.voiceBtn:SetShown(chat.showVoice ~= false) end
    if data.settingsBtn then data.settingsBtn:SetShown(chat.showSettings ~= false) end
    if data.scrollBtn then data.scrollBtn:SetShown(chat.showScroll ~= false) end
end

ApplyChatSettings = function()
    TryLoadAddon("EllesmereUIChat")

    local profile = EnsureEllesmereAddonProfile("EllesmereUIChat")
    if type(profile) ~= "table" then return false end

    profile.chat = profile.chat or {}
    local chat = profile.chat
    local changed = false

    local preset = {
        enabled = true,
        visibility = "always",
        visOnlyInstances = false,
        visHideHousing = false,
        visHideMounted = false,
        visHideNoTarget = false,
        visHideNoEnemy = false,
        bgAlpha = 0,
        bgR = 0.03,
        bgG = 0.045,
        bgB = 0.05,
        idleFadeDelay = 15,
        idleFadeStrength = 40,
        font = "__global",
        outlineMode = "__global",
        timestampFormat = "%I:%M ",
        sidebarVisibility = "mouseover",
        showFriends = true,
        showCopy = true,
        showPortals = true,
        showVoice = false,
        showSettings = true,
        showScroll = true,
        iconR = 1,
        iconG = 1,
        iconB = 1,
        iconUseAccent = false,
        hideSidebarBg = false,
        sidebarIconScale = 1.0,
        freeMoveIcons = false,
        hideTooltipOnHover = true,
        hideBorders = false,
        lockChatSize = false,
        inputOnTop = true,
        whisperSoundKey = "none",
    }

    for key, value in pairs(preset) do
        if chat[key] ~= value then
            chat[key] = value
            changed = true
        end
    end

    if chat.sidebarRight ~= YunoDB.forceChatSidebarRight then
        chat.sidebarRight = YunoDB.forceChatSidebarRight and true or false
        changed = true
    end

    local iconOrder = chat.sidebarIconOrder
    if type(iconOrder) ~= "table"
        or iconOrder.showCopy ~= 1
        or iconOrder.showPortals ~= 2
        or iconOrder.showVoice ~= 3
        or iconOrder.showSettings ~= 4 then
        chat.sidebarIconOrder = {
            showCopy = 1,
            showPortals = 2,
            showVoice = 3,
            showSettings = 4,
        }
        changed = true
    end

    ApplyChatSidebarPosition()
    ApplyChatRuntimePreset(chat)
    return changed
end

local function GetOverrideBarIndexSafe()
    if GetOverrideBarIndex then return GetOverrideBarIndex() end
    if C_ActionBar and C_ActionBar.GetOverrideBarIndex then return C_ActionBar.GetOverrideBarIndex() end
    return 14
end

local function GetVehicleBarIndexSafe()
    if GetVehicleBarIndex then return GetVehicleBarIndex() end
    if C_ActionBar and C_ActionBar.GetVehicleBarIndex then return C_ActionBar.GetVehicleBarIndex() end
    return 12
end

local YUNO_ACTION_BAR_MODIFIER_STATES = {
    { id = "alt",   macro = "[mod:alt]" },
    { id = "shift", macro = "[mod:shift]" },
    { id = "ctrl",  macro = "[mod:ctrl]" },
}

local YUNO_ACTION_BAR_CLASS_STATES = {
    DRUID = {
        { id = "prowl",   macro = "[bonusbar:1,stealth]" },
        { id = "cat",     macro = "[bonusbar:1]" },
        { id = "tree",    macro = "[bonusbar:2]" },
        { id = "bear",    macro = "[bonusbar:3]" },
        { id = "moonkin", macro = "[bonusbar:4]" },
    },
    ROGUE = {
        { id = "stealth", macro = "[bonusbar:1]" },
    },
    WARRIOR = {
        { id = "battle",    macro = "[bonusbar:1]" },
        { id = "defensive", macro = "[bonusbar:2]" },
    },
    EVOKER = {
        { id = "soar", macro = "[bonusbar:1]" },
    },
}

local YUNO_ACTION_BAR_CLASS_DEFAULTS = {
    DRUID = { prowl = 7, cat = 7, tree = 8, bear = 9, moonkin = 10 },
    ROGUE = { stealth = 7 },
}

local function BuildYunoMainBarPagingConditions(pagingConfig, disableClassPaging)
    local parts = {
        "[overridebar] " .. GetOverrideBarIndexSafe(),
        "[vehicleui][possessbar] " .. GetVehicleBarIndexSafe(),
    }

    if type(pagingConfig) == "table" then
        for _, state in ipairs(YUNO_ACTION_BAR_MODIFIER_STATES) do
            local page = pagingConfig[state.id]
            if page then
                parts[#parts + 1] = state.macro .. " " .. page
            end
        end
    end

    local _, class = UnitClass("player")
    local classStates = not disableClassPaging and YUNO_ACTION_BAR_CLASS_STATES[class]
    if classStates then
        local defaults = YUNO_ACTION_BAR_CLASS_DEFAULTS[class]
        for _, state in ipairs(classStates) do
            local page = type(pagingConfig) == "table" and pagingConfig[state.id] or nil
            if page then
                parts[#parts + 1] = state.macro .. " " .. page
            elseif page == nil and defaults and defaults[state.id] then
                parts[#parts + 1] = state.macro .. " " .. defaults[state.id]
            end
        end
    end

    parts[#parts + 1] = "[bonusbar:5] 11"
    for i = 2, (NUM_ACTIONBAR_PAGES or 6) do
        parts[#parts + 1] = "[bar:" .. i .. "] " .. i
    end
    parts[#parts + 1] = "1"
    return table.concat(parts, "; ")
end

local function ApplyYunoMainBarKeybindOverride()
    if InCombatLockdown and InCombatLockdown() then return false end

    if not actionBarPagingBindOwner then
        actionBarPagingBindOwner = CreateFrame("Frame", "YunoActionBarPagingBindOwner", UIParent)
    end
    ClearOverrideBindings(actionBarPagingBindOwner)

    if YunoDB.disableEllesmereActionBarPaging ~= true then
        return true
    end

    for i = 1, 12 do
        local button = _G["EABButton" .. i]
        local buttonName = button and button:GetName()
        if buttonName then
            local key1, key2 = GetBindingKey("ACTIONBUTTON" .. i)
            if key1 then SetOverrideBindingClick(actionBarPagingBindOwner, true, key1, buttonName) end
            if key2 then SetOverrideBindingClick(actionBarPagingBindOwner, true, key2, buttonName) end
        end
    end

    return true
end

local function HookYunoMainBarKeybindOverride()
    if actionBarPagingKeybindHooked or type(_G._EAB_UpdateKeybinds) ~= "function" or not hooksecurefunc then return end
    local ok = pcall(hooksecurefunc, "_EAB_UpdateKeybinds", function()
        if type(YunoDB) == "table" and YunoDB.disableEllesmereActionBarPaging == true then
            C_Timer.After(0, ApplyYunoMainBarKeybindOverride)
        end
    end)
    actionBarPagingKeybindHooked = ok and true or false
end

local function ApplyEllesmereActionBarPagingOverride()
    EnsureDB()
    if InCombatLockdown and InCombatLockdown() then
        if not actionBarPagingDeferFrame then
            actionBarPagingDeferFrame = CreateFrame("Frame")
            actionBarPagingDeferFrame:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                ApplyEllesmereActionBarPagingOverride()
            end)
        end
        actionBarPagingDeferFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return false
    end

    HookYunoMainBarKeybindOverride()
    local profile = GetEllesmereAddonProfile("EllesmereUIActionBars")
    local pagingConfig = profile and profile.bars and profile.bars.MainBar and profile.bars.MainBar.paging
    local disableClassPaging = YunoDB.disableEllesmereActionBarPaging == true
    if not disableClassPaging and not actionBarPagingOverrideApplied then return false end

    local frame = _G.EABBar_MainBar
    if not frame then return false end

    if type(_G._EAB_UpdateKeybinds) == "function" then
        _G._EAB_UpdateKeybinds()
    end

    if UnregisterStateDriver then
        UnregisterStateDriver(frame, "page")
    end
    if RegisterStateDriver then
        RegisterStateDriver(frame, "page", BuildYunoMainBarPagingConditions(pagingConfig, disableClassPaging))
    end

    ApplyYunoMainBarKeybindOverride()
    actionBarPagingOverrideApplied = disableClassPaging

    return true
end

local function ApplyBlizzardUIEnhancedSettings()
    TryLoadAddon("EllesmereUIBlizzardSkin")
    RegisterMedia()

    if type(_G.EllesmereUIDB) ~= "table" then _G.EllesmereUIDB = {} end
    local db = _G.EllesmereUIDB
    local changed = false

    local function Set(key, value)
        if db[key] ~= value then
            db[key] = value
            changed = true
        end
    end

    Set("customTooltips", true)
    Set("accentReskinElements", false)
    Set("tooltipPlayerTitles", true)
    Set("tooltipFontScale", 1.0)
    Set("uberTooltipsManual", true)
    Set("uberTooltips", true)
    Set("tooltipMythicScore", true)
    Set("reskinQueuePopup", true)
    Set("showQueueTimer", true)
    Set("reskinGameMenu", true)
    Set("reskinGreatVault", true)

    Set("themedCharacterSheet", true)
    Set("showMythicRating", false)
    Set("showItemLevel", true)
    Set("showUpgradeTrack", true)
    Set("showEnchants", true)
    Set("showGems", true)

    Set("themedInspectSheet", true)
    Set("inspectShowEnchants", true)
    Set("inspectShowItemLevel", true)
    Set("inspectShowUpgradeTrack", true)

    local statCategories = {
        "Attributes",
        "SecondaryStats",
        "Tertiary",
        "Attack",
        "Defense",
        "Crests",
        "PvP",
    }
    for _, key in ipairs(statCategories) do
        Set("showStatCategory_" .. key, true)
    end

    Set("showSecondaryRaw", false)
    Set("showSecondaryBoth", false)
    Set("showTertiaryRaw", false)
    Set("showTertiaryBoth", false)

    for _, key in ipairs({ "Myth", "Hero", "Champion", "Veteran", "Adventurer" }) do
        Set("showCrest_" .. key, true)
    end

    db.statCategoryColors = db.statCategoryColors or {}
    db.statCategoryUseColor = db.statCategoryUseColor or {}
    local colors = {
        ["Attributes"] = { r = 0.047, g = 0.824, b = 0.616 },
        ["Secondary Stats"] = { r = 0.471, g = 0.255, b = 0.784 },
        ["Tertiary Stats"] = { r = 0.859, g = 0.325, b = 0.855 },
        ["Attack"] = { r = 1.000, g = 0.353, b = 0.122 },
        ["Defense"] = { r = 0.247, g = 0.655, b = 1.000 },
        ["Crests"] = { r = 1.000, g = 0.784, b = 0.341 },
        ["PvP"] = { r = 0.671, g = 0.431, b = 0.349 },
    }
    for key, color in pairs(colors) do
        local current = db.statCategoryColors[key]
        if type(current) ~= "table"
            or current.r ~= color.r
            or current.g ~= color.g
            or current.b ~= color.b then
            db.statCategoryColors[key] = { r = color.r, g = color.g, b = color.b }
            changed = true
        end
        if db.statCategoryUseColor[key] ~= true then
            db.statCategoryUseColor[key] = true
            changed = true
        end
    end

    local dragon = EnsureEllesmereAddonProfile("EllesmereUIDragonRiding")
    if type(dragon) == "table" then
        local function DragonSet(key, value)
            if dragon[key] ~= value then
                dragon[key] = value
                changed = true
            end
        end
        local function DragonColor(key, r, g, b, a)
            local current = dragon[key]
            if type(current) ~= "table"
                or current.r ~= r
                or current.g ~= g
                or current.b ~= b
                or current.a ~= a then
                dragon[key] = { r = r, g = g, b = b, a = a }
                changed = true
            end
        end

        DragonSet("enabled", true)
        DragonSet("hideInCombat", false)
        DragonSet("width", 240)
        DragonSet("gap", 2)
        DragonSet("stackSpacing", 2)
        DragonSet("borderThickness", 0)
        DragonSet("barTexture", "sm:DF Flat")
        DragonSet("skyridingHeight", 10)
        DragonSet("secondWindHeight", 6)
        DragonSet("speedHeight", 14)
        DragonSet("thrillColorToggle", true)
        DragonColor("borderColor", 0.0, 0.0, 0.0, 1.0)
        DragonColor("skyridingBg", 0.10, 0.10, 0.10, 0.80)
        DragonColor("skyridingFilled", 0.047, 0.824, 0.624, 1.0)
        DragonColor("secondWindBg", 0.10, 0.10, 0.10, 0.80)
        DragonColor("secondWindFilled", 0.902, 0.706, 0.133, 1.0)
        DragonColor("speedBarBg", 0.10, 0.10, 0.10, 0.80)
        DragonColor("normalColor", 0.055, 0.667, 0.761, 1.0)
        DragonColor("tickColor", 1.00, 1.00, 1.00, 0.50)
        DragonColor("thrillColor", 0.902, 0.494, 0.133, 1.0)

        if type(dragon.whirlingSurgeText) ~= "table" then dragon.whirlingSurgeText = {}; changed = true end
        if dragon.whirlingSurgeText.enabled ~= true then dragon.whirlingSurgeText.enabled = true; changed = true end
        if type(dragon.speedText) ~= "table" then dragon.speedText = {}; changed = true end
        if dragon.speedText.enabled ~= true then dragon.speedText.enabled = true; changed = true end
        if dragon.speedText.justify ~= "CENTER" then dragon.speedText.justify = "CENTER"; changed = true end
    end

    if EllesmereUI then
        if EllesmereUI._refreshStatsVisibility then pcall(EllesmereUI._refreshStatsVisibility) end
        if EllesmereUI._refreshStatFormats then pcall(EllesmereUI._refreshStatFormats) end
        if EllesmereUI._refreshCharacterSheetColors then pcall(EllesmereUI._refreshCharacterSheetColors) end
        if EllesmereUI._refreshItemLevelVisibility then pcall(EllesmereUI._refreshItemLevelVisibility) end
        if EllesmereUI._refreshUpgradeTrackVisibility then pcall(EllesmereUI._refreshUpgradeTrackVisibility) end
        if EllesmereUI._refreshEnchantsVisibility then pcall(EllesmereUI._refreshEnchantsVisibility) end
        if EllesmereUI._refreshGemsVisibility then pcall(EllesmereUI._refreshGemsVisibility) end
        if EllesmereUI._refreshInspectItemLevelVisibility then pcall(EllesmereUI._refreshInspectItemLevelVisibility) end
        if EllesmereUI._refreshInspectUpgradeTrackVisibility then pcall(EllesmereUI._refreshInspectUpgradeTrackVisibility) end
        if EllesmereUI._refreshInspectEnchantsVisibility then pcall(EllesmereUI._refreshInspectEnchantsVisibility) end
    end

    return true, changed and "Blizz UI Enhanced settings applied" or "Blizz UI Enhanced settings already matched"
end

local function ApplyDamageMeterSettings()
    TryLoadAddon("EllesmereUIDamageMeters")
    RegisterMedia()

    local textureKey = "sm:Skyline Compact"
    local texturePath = STATUSBAR_MEDIA[1] and STATUSBAR_MEDIA[1].path
    if texturePath and type(_G._EDM_BarTextures) == "table" then
        _G._EDM_BarTextures[textureKey] = texturePath
        if type(_G._EDM_BarTextureNames) == "table" then
            _G._EDM_BarTextureNames[textureKey] = "Skyline Compact"
        end
        if type(_G._EDM_BarTextureOrder) == "table" then
            local seen = false
            for _, key in ipairs(_G._EDM_BarTextureOrder) do
                if key == textureKey then
                    seen = true
                    break
                end
            end
            if not seen then
                _G._EDM_BarTextureOrder[#_G._EDM_BarTextureOrder + 1] = textureKey
            end
        end
    end

    local profile = EnsureEllesmereAddonProfile("EllesmereUIDamageMeters")
    if type(profile) ~= "table" then return false, "Damage Meters profile is not available" end

    profile.dm = profile.dm or {}
    local dm = profile.dm
    local changed = false

    local function Set(key, value)
        if dm[key] ~= value then
            dm[key] = value
            changed = true
        end
    end

    local function SetColor(key, r, g, b)
        local current = dm[key]
        if type(current) ~= "table"
            or current.r ~= r
            or current.g ~= g
            or current.b ~= b then
            dm[key] = { r = r, g = g, b = b }
            changed = true
        end
    end

    Set("visibility", "always")
    Set("visOnlyInstances", false)
    Set("visHideHousing", false)
    Set("visHideMounted", false)
    Set("visHideNoTarget", false)
    Set("visHideNoEnemy", false)
    Set("bgAlpha", 0.55)
    Set("bgR", 0)
    Set("bgG", 0)
    Set("bgB", 0)
    Set("showPinnedSelf", false)
    Set("refreshRate", 0.7)

    Set("hdrHeight", 20)
    Set("hdrBgAlpha", 0)
    Set("hdrFontSize", 13)
    Set("hdrIconSize", 22)
    Set("hdrMouseoverIcons", false)
    Set("hdrTextUseAccent", false)
    SetColor("hdrTextColor", 1, 1, 1)
    Set("iconColorUseAccent", false)
    SetColor("iconColor", 1, 1, 1)

    Set("barTexture", textureKey)
    Set("barHeight", 19)
    Set("showClassColor", true)
    Set("barColorUseAccent", false)
    SetColor("barColor", 0.96, 0.55, 0.73)
    Set("barFillAlpha", 1)
    Set("barSpacing", 2)
    Set("iconStyle", "spec")
    Set("showHoverTooltip", true)
    Set("breakdownBarTexture", "match")

    Set("numberFormat", 2)
    Set("hideNumbers", true)
    Set("leftFontSize", 12)
    Set("rightFontSize", 12)
    Set("leftTextUseClassColor", false)
    Set("rightTextUseClassColor", false)
    SetColor("leftTextColor", 1, 1, 1)
    SetColor("rightTextColor", 1, 1, 1)

    Set("standaloneTimer", false)
    Set("standaloneTimerAnchor", "free")
    Set("windowCount", 2)

    dm.windows = dm.windows or {}
    local windowSizes = {
        { x = 3170, y = 127, width = 270, height = 125 },
        { x = 3170, y = 212, width = 270, height = 85 },
    }

    for index, size in ipairs(windowSizes) do
        dm.windows[index] = dm.windows[index] or {}
        if dm.windows[index].width ~= size.width then
            dm.windows[index].width = size.width
            changed = true
        end
        if dm.windows[index].height ~= size.height then
            dm.windows[index].height = size.height
            changed = true
        end
        local position = dm.windows[index].position
        if type(position) ~= "table" or position.x ~= size.x or position.y ~= size.y then
            dm.windows[index].position = { x = size.x, y = size.y }
            changed = true
        end

        local frame = _G["EllesmereUIDMFrame" .. index]
        if frame and frame.SetSize then
            frame:SetSize(size.width, size.height)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", size.x, size.y)
        end
    end

    for index = 3, 5 do
        if dm.windows[index] ~= nil then
            dm.windows[index] = nil
            changed = true
        end
    end

    if EllesmereUI and type(EllesmereUI.RequestVisibilityUpdate) == "function" then
        pcall(EllesmereUI.RequestVisibilityUpdate)
    end
    if EllesmereUI and type(EllesmereUI.RefreshPage) == "function" then
        pcall(EllesmereUI.RefreshPage, EllesmereUI)
    end

    return true, changed and "Damage Meter settings applied" or "Damage Meter settings already matched"
end

local function ApplyEllesmereExtrasSettings()
    local chatChanged = ApplyChatSettings()
    local blizzOk, blizzMessage = ApplyBlizzardUIEnhancedSettings()
    if not blizzOk then return false, blizzMessage end
    local dmOk, dmMessage = ApplyDamageMeterSettings()
    if not dmOk then return false, dmMessage end

    if chatChanged or blizzMessage == "Blizz UI Enhanced settings applied" or dmMessage == "Damage Meter settings applied" then
        return true, "Ellesmere chat, Blizz UI Enhanced, and Damage Meter settings applied"
    end
    return true, "Ellesmere chat, Blizz UI Enhanced, and Damage Meter settings already matched"
end

local function GetYunoCharacterKey()
    local name = UnitName and UnitName("player") or "Unknown"
    local realm = GetRealmName and GetRealmName() or "Unknown"
    return tostring(name or "Unknown") .. " - " .. tostring(realm or "Unknown")
end

local function MarkProfilePromptApplied()
    EnsureDB()
    YunoDB.profilePromptApplied[GetYunoCharacterKey()] = PROFILE_PROMPT_VERSION
    YunoDB.profilePromptDismissed[GetYunoCharacterKey()] = nil
end

local function MarkInstallerCompleted()
    EnsureDB()
    YunoDB.installerCompletedVersion = PROFILE_PROMPT_VERSION
    YunoDB.installerPendingFinalScale = nil
end

local function MarkInstallerPendingFinalScale()
    EnsureDB()
    YunoDB.installerPendingFinalScale = true
end

local function MarkProfilePromptDismissed()
    EnsureDB()
    YunoDB.profilePromptDismissed[GetYunoCharacterKey()] = PROFILE_PROMPT_VERSION
end

local function FindEditModeLayoutIndex(layoutName)
    if not C_EditMode or type(C_EditMode.GetLayouts) ~= "function" then return nil end

    local ok, layouts = pcall(C_EditMode.GetLayouts)
    if not ok or type(layouts) ~= "table" or type(layouts.layouts) ~= "table" then return nil end

    local presetCount = Enum and Enum.EditModePresetLayoutsMeta and Enum.EditModePresetLayoutsMeta.NumValues or 0
    for i, layout in ipairs(layouts.layouts) do
        if layout.layoutName == layoutName then
            return presetCount + i
        end
    end

    return nil
end

local function BigWigsProfileExists(profileName)
    if type(BigWigs3DB) == "table" and type(BigWigs3DB.profiles) == "table" and type(BigWigs3DB.profiles[profileName]) == "table" then
        return true
    end

    local db = BigWigsLoader and BigWigsLoader.db
    if db and type(db.GetProfiles) == "function" then
        local ok, profiles = pcall(db.GetProfiles, db, {})
        if ok and type(profiles) == "table" then
            for _, name in ipairs(profiles) do
                if name == profileName then return true end
            end
        end
    end

    return false
end

local function BlinkiisPortraitsProfileExists(profileName)
    if type(BlinkiisPortraitsDB) == "table"
        and type(BlinkiisPortraitsDB.profiles) == "table"
        and type(BlinkiisPortraitsDB.profiles[profileName]) == "table" then
        return true
    end

    local db = BLINKIISPORTRAITS and BLINKIISPORTRAITS.db
    return db and type(db.profiles) == "table" and type(db.profiles[profileName]) == "table"
end

local function EXBossProfileExists(profileName)
    local wanted = tostring(profileName or ""):lower()
    if wanted == "" then return false end

    local db = type(EXBossDataDB) == "table" and type(EXBossDataDB.bossConfig) == "table" and EXBossDataDB.bossConfig or nil
    local userOverrides = db and type(db.userOverrides) == "table" and db.userOverrides or nil
    if not userOverrides then return false end

    for _, slotKey in ipairs(EXBOSS_IMPORT_SLOT_KEYS) do
        local slotRoot = type(userOverrides[slotKey]) == "table" and userOverrides[slotKey] or nil
        if slotRoot then
            for authorKey, authorRow in pairs(slotRoot) do
                local key = tostring(authorKey or "")
                if key:lower():sub(1, #wanted) == wanted and type(authorRow) == "table" then
                    return true
                end
            end
        end
    end

    return false
end

local function EllesmereProfileExists(profileName)
    return type(EllesmereUIDB) == "table"
        and type(EllesmereUIDB.profiles) == "table"
        and type(EllesmereUIDB.profiles[profileName]) == "table"
end

local function HasInstalledYunoProfiles()
    TryLoadAddon("EllesmereUI")
    TryLoadAddon("BigWigs")
    TryLoadAddon("Blinkiis_Portraits")
    TryLoadAddon("EXBoss")

    return EllesmereProfileExists("yuno")
        or BigWigsProfileExists("yuno")
        or BlinkiisPortraitsProfileExists("yuno")
        or EXBossProfileExists("yuno")
        or FindEditModeLayoutIndex("yuno") ~= nil
end

local function ApplyExistingEllesmereProfile(applied, missing, failed)
    TryLoadAddon("EllesmereUI")

    if not EllesmereProfileExists("yuno") then
        missing[#missing + 1] = "EllesmereUI"
        return
    end

    if EllesmereUI and type(EllesmereUI.SwitchProfile) == "function" then
        local ok, err = pcall(EllesmereUI.SwitchProfile, "yuno")
        if not ok then
            failed[#failed + 1] = "EllesmereUI: " .. tostring(err)
            return
        end
    elseif type(EllesmereUIDB) == "table" then
        EllesmereUIDB.activeProfile = "yuno"
    end

    applied[#applied + 1] = "EllesmereUI"
end

local function ApplyExistingBigWigsProfile(applied, missing, failed)
    TryLoadAddon("BigWigs")

    if not BigWigsProfileExists("yuno") then
        missing[#missing + 1] = "BigWigs"
        return
    end

    local db = BigWigsLoader and BigWigsLoader.db
    if db and type(db.SetProfile) == "function" then
        local ok, err = pcall(db.SetProfile, db, "yuno")
        if not ok then
            failed[#failed + 1] = "BigWigs: " .. tostring(err)
            return
        end
    elseif type(BigWigs3DB) == "table" then
        BigWigs3DB.profileKeys = BigWigs3DB.profileKeys or {}
        BigWigs3DB.profileKeys[GetYunoCharacterKey()] = "yuno"
    end

    applied[#applied + 1] = "BigWigs"
end

local function ApplyExistingBlinkiisPortraitsProfile(applied, missing, failed)
    TryLoadAddon("Blinkiis_Portraits")

    if not BlinkiisPortraitsProfileExists("yuno") then
        missing[#missing + 1] = "Blinkii's Portraits"
        return
    end

    local db = BLINKIISPORTRAITS and BLINKIISPORTRAITS.db
    if db and type(db.SetProfile) == "function" then
        local ok, err = pcall(db.SetProfile, db, "yuno")
        if not ok then
            failed[#failed + 1] = "Blinkii's Portraits: " .. tostring(err)
            return
        end
    elseif type(BlinkiisPortraitsDB) == "table" then
        BlinkiisPortraitsDB.profileKeys = BlinkiisPortraitsDB.profileKeys or {}
        BlinkiisPortraitsDB.profileKeys[GetYunoCharacterKey()] = "yuno"
    end

    if BLINKIISPORTRAITS and type(BLINKIISPORTRAITS.LoadPortraits) == "function" then
        pcall(BLINKIISPORTRAITS.LoadPortraits, BLINKIISPORTRAITS)
    end

    applied[#applied + 1] = "Blinkii's Portraits"
end

local function FindEXBossYunoAuthor(slotKey)
    local db = type(EXBossDataDB) == "table" and type(EXBossDataDB.bossConfig) == "table" and EXBossDataDB.bossConfig or nil
    local slotRoot = db and type(db.userOverrides) == "table" and type(db.userOverrides[slotKey]) == "table" and db.userOverrides[slotKey] or nil
    if not slotRoot then return nil end

    local selected = db.slotSelection and db.slotSelection[slotKey]
    if type(selected) == "string" and selected:lower():sub(1, 4) == "yuno" and type(slotRoot[selected]) == "table" then
        return selected
    end

    local suffix = EXBOSS_IMPORT_AUTHOR_SUFFIXES[slotKey]
    local expected = suffix and ("yuno-" .. suffix):lower() or nil
    if expected then
        for authorKey, authorRow in pairs(slotRoot) do
            local key = tostring(authorKey or "")
            if key:lower() == expected and type(authorRow) == "table" then
                return key
            end
        end
    end

    for authorKey, authorRow in pairs(slotRoot) do
        local key = tostring(authorKey or "")
        if key:lower():sub(1, 4) == "yuno" and type(authorRow) == "table" then
            return key
        end
    end

    return nil
end

local function ApplyExistingEXBossProfile(applied, missing, failed)
    TryLoadAddon("EXBoss")

    if not EXBossProfileExists("yuno") then
        missing[#missing + 1] = "EXBoss"
        return
    end

    local bossConfig = ExBoss and (ExBoss.BossConfig or (ExBoss.Modules and ExBoss.Modules.Boss))
    local db = type(EXBossDataDB) == "table" and type(EXBossDataDB.bossConfig) == "table" and EXBossDataDB.bossConfig or nil
    if not bossConfig and not db then
        failed[#failed + 1] = "EXBoss: profile database is not available"
        return
    end

    local appliedAny = false
    for _, slotKey in ipairs(EXBOSS_IMPORT_SLOT_KEYS) do
        local authorKey = FindEXBossYunoAuthor(slotKey)
        if authorKey then
            if bossConfig and type(bossConfig.SetSelectedAuthor) == "function" then
                local ok, err = pcall(bossConfig.SetSelectedAuthor, bossConfig, slotKey, authorKey)
                if not ok then
                    failed[#failed + 1] = "EXBoss: " .. tostring(err)
                    return
                end
            elseif db then
                db.slotSelection = db.slotSelection or {}
                db.slotSelection[slotKey] = authorKey
            end
            appliedAny = true
        end
    end

    if not appliedAny then
        missing[#missing + 1] = "EXBoss"
        return
    end

    if bossConfig and type(bossConfig.PublishRuntimeSelection) == "function" then
        pcall(bossConfig.PublishRuntimeSelection, bossConfig)
    end

    applied[#applied + 1] = "EXBoss"
end

local function ApplyExistingEditModeLayout(applied, missing, failed)
    if InCombatLockdown and InCombatLockdown() then
        failed[#failed + 1] = "Edit Mode: cannot apply in combat"
        return
    end

    local index = FindEditModeLayoutIndex("yuno")
    if not index then
        missing[#missing + 1] = "Edit Mode"
        return
    end

    if C_EditMode and type(C_EditMode.SetActiveLayout) == "function" then
        local ok, err = pcall(C_EditMode.SetActiveLayout, index)
        if not ok then
            failed[#failed + 1] = "Edit Mode: " .. tostring(err)
            return
        end
    end

    if C_EditMode and type(C_EditMode.SetAccountSetting) == "function" then
        pcall(C_EditMode.SetAccountSetting, 22, 0)
        pcall(C_EditMode.SetAccountSetting, 0, 0)
    end

    applied[#applied + 1] = "Edit Mode"
end

local function ApplyInstalledProfilesToCharacter(markApplied)
    EnsureDB()

    local applied = {}
    local missing = {}
    local failed = {}

    ApplyExistingEllesmereProfile(applied, missing, failed)
    ApplyExistingBigWigsProfile(applied, missing, failed)
    ApplyExistingBlinkiisPortraitsProfile(applied, missing, failed)
    ApplyExistingEXBossProfile(applied, missing, failed)
    ApplyExistingEditModeLayout(applied, missing, failed)

    if #applied > 0 and #failed == 0 and markApplied then
        MarkProfilePromptApplied()
    end

    local message
    if #applied > 0 then
        message = "loaded yuno profiles for this character: " .. table.concat(applied, ", ")
    else
        message = "no installed yuno profiles were found for this character"
    end
    if #missing > 0 then
        message = message .. " (missing: " .. table.concat(missing, ", ") .. ")"
    end
    if #failed > 0 then
        message = message .. " (failed: " .. table.concat(failed, "; ") .. ")"
    end

    return #applied > 0 and #failed == 0, message
end

local function ShouldOfferInstalledProfiles()
    EnsureDB()
    if YunoDB.profilePromptEnabled == false then return false end
    if YunoDB.installerCompletedVersion ~= PROFILE_PROMPT_VERSION then return false end

    local key = GetYunoCharacterKey()
    if YunoDB.profilePromptApplied[key] == PROFILE_PROMPT_VERSION then return false end
    if YunoDB.profilePromptDismissed[key] == PROFILE_PROMPT_VERSION then return false end

    return HasInstalledYunoProfiles()
end

local function ShowInstalledProfilesPrompt()
    if InCombatLockdown and InCombatLockdown() then return end
    if not ShouldOfferInstalledProfiles() then return end

    local UI = yuno and yuno.UI or YunoUI
    if not UI then return end

    local function SetButtonBackground(button, color, alpha)
        if not button.bg then
            button.bg = button:CreateTexture(nil, "BACKGROUND")
            button.bg:SetAllPoints()
        end
        button.bg:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
    end

    local function CreateSolidButton(parent, label)
        local button = CreateFrame("Frame", nil, parent)
        button:SetSize(150, 36)
        button:EnableMouse(true)
        SetButtonBackground(button, UI.Theme.accent)

        button.label = UI:CreateText(button, label, 12, "text", "bold")
        button.label:SetPoint("CENTER")
        button.label:SetTextColor(1, 1, 1, 1)

        function button:SetOnClick(callback)
            self._yunoOnClick = callback
        end

        button:SetScript("OnEnter", function(self)
            SetButtonBackground(self, UI.Theme.accent, 0.86)
        end)
        button:SetScript("OnLeave", function(self)
            SetButtonBackground(self, UI.Theme.accent)
        end)
        button:SetScript("OnMouseDown", function(self, mouseButton)
            if mouseButton ~= "LeftButton" then return end
            SetButtonBackground(self, UI.Theme.accent, 0.70)
        end)
        button:SetScript("OnMouseUp", function(self, mouseButton)
            SetButtonBackground(self, UI.Theme.accent, self:IsMouseOver() and 0.86 or 1)
            if mouseButton == "LeftButton" and self._yunoOnClick then self:_yunoOnClick() end
        end)

        return button
    end

    if not installedProfilesPromptFrame then
        local frame = UI:CreateWindow("YunoInstalledProfilesPromptFrame", UIParent, 500, 280)
        frame.subtitle:SetText("profiles")

        frame.body = CreateFrame("Frame", nil, frame)
        frame.body:SetPoint("TOPLEFT", 28, -64)
        frame.body:SetPoint("BOTTOMRIGHT", -28, 24)

        frame.logo = frame.body:CreateTexture(nil, "ARTWORK")
        frame.logo:SetTexture("Interface\\AddOns\\yuno\\media\\logo.png")
        frame.logo:SetSize(76, 76)
        frame.logo:SetPoint("TOP", frame.body, "TOP", 0, 0)

        frame.heading = UI:CreateText(frame.body, "Profiles installed", 21, "text", "bold")
        frame.heading:SetPoint("TOPLEFT", frame.logo, "BOTTOMLEFT", -190, -14)
        frame.heading:SetPoint("TOPRIGHT", frame.logo, "BOTTOMRIGHT", 190, -14)
        frame.heading:SetJustifyH("CENTER")

        frame.copy = UI:CreateText(frame.body, "Apply yuno's installed profiles to this character and reload the UI?", 12, "muted", "semibold")
        frame.copy:SetPoint("TOPLEFT", frame.heading, "BOTTOMLEFT", 0, -12)
        frame.copy:SetPoint("TOPRIGHT", frame.heading, "BOTTOMRIGHT", 0, -12)
        frame.copy:SetJustifyH("CENTER")
        frame.copy:SetSpacing(5)

        frame.status = UI:CreateText(frame.body, "", 11, "muted", "semibold")
        frame.status:SetPoint("BOTTOMLEFT", frame.body, "BOTTOMLEFT", 0, 42)
        frame.status:SetPoint("BOTTOMRIGHT", frame.body, "BOTTOMRIGHT", 0, 42)
        frame.status:SetJustifyH("CENTER")

        frame.applyButton = CreateSolidButton(frame.body, "Apply & Reload")
        frame.applyButton:SetPoint("BOTTOMRIGHT", frame.body, "BOTTOM", -6, 0)

        frame.dismissButton = UI:CreateFlatButton(frame.body, "Not Now")
        frame.dismissButton:SetSize(150, 36)
        frame.dismissButton:SetPoint("BOTTOMLEFT", frame.body, "BOTTOM", 6, 0)

        local function Dismiss()
            MarkProfilePromptDismissed()
            frame:Hide()
        end

        frame.closeButton:SetOnClick(Dismiss)
        frame.dismissButton:SetOnClick(Dismiss)
        frame.applyButton:SetOnClick(function()
            local ok, message = ApplyInstalledProfilesToCharacter(true)
            Print(message)
            if ok then
                ReloadUI()
                return
            end
            frame.status:SetText(message or "No installed profiles were applied.")
            UI:SetStatusColor(frame.status, false)
        end)

        installedProfilesPromptFrame = frame
    end

    installedProfilesPromptFrame.status:SetText("")
    installedProfilesPromptFrame:Show()
end

local function ScheduleInstalledProfilesOffer()
    if profileOfferScheduled then return end
    profileOfferScheduled = true
    C_Timer.After(4, function()
        profileOfferScheduled = false
        ShowInstalledProfilesPrompt()
    end)
end

local function GetUnitSettings(unit)
    local profile = GetEllesmereProfile()
    if type(profile) ~= "table" then return nil end
    local key = UnitKey(unit)
    local legacyKey = LegacyMiniUnitKey(unit)
    return (key and profile[key]) or (legacyKey and profile[legacyKey]) or profile.player
end

local function GetHealthAlpha(unit)
    local settings = GetUnitSettings(unit)
    local opacity = settings and settings.healthBarOpacity or 90
    if opacity <= 1 then opacity = opacity * 100 end
    if opacity < 0 then opacity = 0 end
    if opacity > 100 then opacity = 100 end
    return opacity / 100
end

local function IsDarkMode()
    local profile = GetEllesmereProfile()
    return profile and profile.darkTheme
end

local function ApplyConfiguredProfileSettings()
    local profile = GetEllesmereProfile()

    local changed = false
    if type(profile) == "table" and YunoDB.forceDarkMode and profile.darkTheme ~= true then
        profile.darkTheme = true
        changed = true
    end

    if type(profile) == "table" and YunoDB.forceOpacity then
        local opacity = math.floor((YunoDB.healthBarOpacity or 85) + 0.5)
        for _, key in ipairs(DB_UNITS) do
            local settings = profile[key]
            if type(settings) == "table" and settings.healthBarOpacity ~= opacity then
                settings.healthBarOpacity = opacity
                changed = true
            end
        end
    end

    local raidProfile = GetEllesmereRaidFramesProfile()
    if type(raidProfile) == "table" then
        if YunoDB.forceDarkMode then
            if raidProfile.healthColorMode ~= "dark" then
                raidProfile.healthColorMode = "dark"
                changed = true
            end
            if raidProfile.party_healthColorMode ~= "dark" then
                raidProfile.party_healthColorMode = "dark"
                changed = true
            end
        end

        if YunoDB.forceOpacity then
            local opacity = math.floor((YunoDB.healthBarOpacity or 85) + 0.5)
            if raidProfile.healthBarOpacity ~= opacity then
                raidProfile.healthBarOpacity = opacity
                changed = true
            end
            if raidProfile.party_healthBarOpacity ~= opacity then
                raidProfile.party_healthBarOpacity = opacity
                changed = true
            end
        end
    end

    return changed
end

local function GetClassTint(unit, color)
    local tint = YunoDB.tint or 0.75

    if color and color.GetRGB then
        local r, g, b = color:GetRGB()
        return r * tint, g * tint, b * tint
    end

    if unit and UnitExists(unit) then
        if UnitIsPlayer(unit) then
            local _, classToken = UnitClass(unit)
            local classColor = classToken and RAID_CLASS_COLORS[classToken]
            if classColor then
                return classColor.r * tint, classColor.g * tint, classColor.b * tint
            end
        end

        local reaction = UnitReaction(unit, "player")
        local reactionColor = reaction and FACTION_BAR_COLORS[reaction]
        if reactionColor then
            return reactionColor.r * tint, reactionColor.g * tint, reactionColor.b * tint
        end
    end

    local _, playerClass = UnitClass("player")
    local playerColor = playerClass and RAID_CLASS_COLORS[playerClass]
    if playerColor then
        return playerColor.r * tint, playerColor.g * tint, playerColor.b * tint
    end
end

local function GetHealthBackground(health)
    return health and (health.bg or health._yunoBg) or nil
end

local function RestoreBackgroundColor(health, unit)
    local bg = GetHealthBackground(health)
    if not health or not bg then return end
    local settings = GetUnitSettings(unit)
    local darkMode = health._yunoDarkModeOverride
    if darkMode == nil then darkMode = IsDarkMode() end
    if darkMode then
        bg:SetColorTexture(0x4f / 255, 0x4f / 255, 0x4f / 255, 1)
        return
    end

    if health._yunoBgOwner then
        bg:ClearAllPoints()
        bg:SetAllPoints(health._yunoBgOwner)
    end

    local customBg = settings and settings.customBgColor
    if customBg then
        bg:SetColorTexture(customBg.r, customBg.g, customBg.b, 1)
    else
        bg:SetColorTexture(17 / 255, 17 / 255, 17 / 255, 1)
    end
end

local function AnchorMissingHealthBackground(health)
    local bg = GetHealthBackground(health)
    if not health or not bg then return end
    local darkMode = health._yunoDarkModeOverride
    if darkMode == nil then darkMode = IsDarkMode() end
    if not darkMode then return end
    local fill = health:GetStatusBarTexture()
    if not fill then return end

    bg:ClearAllPoints()
    if health._yunoReverseFill or (health.GetReverseFill and health:GetReverseFill()) then
        bg:SetPoint("TOPLEFT", health, "TOPLEFT", 0, 0)
        bg:SetPoint("BOTTOMRIGHT", fill, "BOTTOMLEFT", 0, 0)
    else
        bg:SetPoint("TOPLEFT", fill, "TOPRIGHT", 0, 0)
        bg:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", 0, 0)
    end
end

local function ApplyHealthPatch(health, unit, color)
    if not YunoDB.enabled or not health then return end

    local settings = GetUnitSettings(unit)
    if settings then
        health._yunoReverseFill = settings.healthReverseFill and true or false
        if health.SetReverseFill then health:SetReverseFill(health._yunoReverseFill) end
    end

    local darkMode = IsDarkMode()
    local fill = health.GetStatusBarTexture and health:GetStatusBarTexture()
    local alpha = GetHealthAlpha(unit)
    if not darkMode or YunoDB.darkOpacity then
        if fill then fill:SetAlpha(alpha) end
        local bg = GetHealthBackground(health)
        if bg then bg:SetAlpha(alpha) end
    end

    AnchorMissingHealthBackground(health)

    local bg = GetHealthBackground(health)
    if bg then
        if YunoDB.classBackground then
            local r, g, b = GetClassTint(unit, color)
            if r then
                bg:SetColorTexture(r, g, b, 1)
            end
        else
            RestoreBackgroundColor(health, unit)
        end
    end
end

local DIRECT_UNITS = {
    player = true,
    target = true,
    focus = true,
    pet = true,
    targettarget = true,
    focustarget = true,
}

local function NormalizeUnit(unit)
    if type(unit) ~= "string" then return nil end
    unit = string.lower(unit)
    if DIRECT_UNITS[unit] or unit == "party" or unit == "raid" then return unit end
    if unit:match("^boss%d+$") or unit:match("^party%d+$") or unit:match("^raid%d+$") then return unit end
end

local function GetFrameName(frame)
    return frame and frame.GetName and frame:GetName() or nil
end

local function ResolveFrameUnit(frame, fallbackUnit)
    local unit = NormalizeUnit(fallbackUnit)

    if not unit and frame then
        unit = NormalizeUnit(frame.unit) or NormalizeUnit(frame._unit)
    end

    if not unit and frame and frame.GetAttribute then
        unit = NormalizeUnit(frame:GetAttribute("unit")) or NormalizeUnit(frame:GetAttribute("oUF-guessUnit"))
    end

    if unit == "party" or unit == "raid" then
        local index = GetFrameName(frame) and GetFrameName(frame):match("(%d+)$")
        if index then unit = unit .. index end
    end

    return unit
end

local function IsEllesmereUnitFrameName(name)
    return type(name) == "string" and name:match("^EllesmereUIUnitFrames_")
end

local function RestoreFrameObject(frame, fallbackUnit)
    local health = frame and frame.Health
    if not health then return end

    local unit = ResolveFrameUnit(frame, fallbackUnit or health._yunoUnit)
    if not unit then return end

    RestoreBackgroundColor(health, unit)

    local alpha = GetHealthAlpha(unit)
    local fill = health.GetStatusBarTexture and health:GetStatusBarTexture()
    if fill then fill:SetAlpha(alpha) end
    local bg = GetHealthBackground(health)
    if bg then bg:SetAlpha(alpha) end
end

local function RestoreFrame(unit, frameName)
    RestoreFrameObject(_G[frameName], unit)
end

local function RestoreDiscoveredFrames()
    for name, frame in pairs(_G) do
        if IsEllesmereUnitFrameName(name) and type(frame) == "table" and frame.Health then
            RestoreFrameObject(frame)
        end
    end
end

local function ReloadEllesmereFrames()
    local reloaded = false
    if type(_G._EUF_ReloadFrames) == "function" then
        _G._EUF_ReloadFrames()
        reloaded = true
    end
    if type(_G._ERF_RefreshAll) == "function" then
        _G._ERF_RefreshAll()
        reloaded = true
    end
    return reloaded
end

local RestoreEllesmereRaidFrames

local function RestoreAll()
    if ReloadEllesmereFrames() then
        return
    end

    for unit, frameName in pairs(FRAME_NAMES) do
        RestoreFrame(unit, frameName)
    end

    RestoreDiscoveredFrames()
    if RestoreEllesmereRaidFrames then RestoreEllesmereRaidFrames() end
end

local function WrapHealth(unit, health)
    if not health then return false end
    health._yunoUnit = unit

    if health.PostUpdateColor ~= health._yunoPostUpdateColor then
        health._yunoOriginalPostUpdateColor = health.PostUpdateColor
        health._yunoPostUpdateColor = function(self, eventUnit, color)
            local original = self._yunoOriginalPostUpdateColor
            if original and original ~= self._yunoPostUpdateColor then
                original(self, eventUnit, color)
            end
            ApplyHealthPatch(self, self._yunoUnit or eventUnit, color)
        end
        health.PostUpdateColor = health._yunoPostUpdateColor
    end

    ApplyHealthPatch(health, unit)
    return true
end

local function PatchFrameObject(frame, fallbackUnit)
    local health = frame and frame.Health
    if not health then return nil end

    local unit = ResolveFrameUnit(frame, fallbackUnit or health._yunoUnit)
    if not unit then return nil end

    if WrapHealth(unit, health) then return health end
end

local function PatchFrame(unit, frameName)
    return PatchFrameObject(_G[frameName], unit)
end

local function PatchDiscoveredFrames(seenHealth)
    local patched = 0
    for name, frame in pairs(_G) do
        if IsEllesmereUnitFrameName(name) and type(frame) == "table" and frame.Health then
            local health = PatchFrameObject(frame)
            if health and not seenHealth[health] then
                seenHealth[health] = true
                patched = patched + 1
            end
        end
    end
    return patched
end

local function GetRaidFrameProfileValue(key, isParty)
    local profile = GetEllesmereRaidFramesProfile()
    if type(profile) ~= "table" then return nil end
    if isParty then
        local partyValue = profile["party_" .. key]
        if partyValue ~= nil then return partyValue end
    end
    return profile[key]
end

local function IsRaidFrameDarkMode(isParty)
    return GetRaidFrameProfileValue("healthColorMode", isParty) == "dark"
end

local function GetRaidFrameHealthAlpha(isParty)
    local opacity = GetRaidFrameProfileValue("healthBarOpacity", isParty) or 100
    if opacity <= 1 then opacity = opacity * 100 end
    if opacity < 0 then opacity = 0 end
    if opacity > 100 then opacity = 100 end
    return opacity / 100
end

local function GetRaidFrameClassTint(unit)
    local r, g, b = GetClassTint(unit)
    if r then return r, g, b end
end

local function RestoreRaidFrameBackground(health, isParty)
    local bg = GetHealthBackground(health)
    if not health or not bg then return end

    if IsRaidFrameDarkMode(isParty) then
        bg:SetColorTexture(0x4f / 255, 0x4f / 255, 0x4f / 255, 1)
        return
    end

    if health._yunoBgOwner then
        bg:ClearAllPoints()
        bg:SetAllPoints(health._yunoBgOwner)
    end

    local bgColor = GetRaidFrameProfileValue("customBgColor", isParty) or { r = 17 / 255, g = 17 / 255, b = 17 / 255 }
    local bgDarkness = GetRaidFrameProfileValue("bgDarkness", isParty) or 50
    bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgDarkness / 100)
end

local ApplyRaidFrameHealthPatch
ApplyRaidFrameHealthPatch = function(button, health, bg, unit, isParty)
    if not YunoDB.enabled or not health then return end

    health._yunoUnit = unit
    health._yunoBg = bg
    health._yunoBgOwner = button
    health._yunoDarkModeOverride = IsRaidFrameDarkMode(isParty)

    local fill = health.GetStatusBarTexture and health:GetStatusBarTexture()
    if not health._yunoDarkModeOverride or YunoDB.darkOpacity then
        local alpha = GetRaidFrameHealthAlpha(isParty)
        if fill then fill:SetAlpha(alpha) end
        if bg then bg:SetAlpha(alpha) end
    end

    AnchorMissingHealthBackground(health)

    if bg then
        if YunoDB.classBackground then
            local r, g, b = GetRaidFrameClassTint(unit)
            if r then bg:SetColorTexture(r, g, b, 1) end
        else
            RestoreRaidFrameBackground(health, isParty)
        end
    end
end

local function FindRaidFrameHealth(button)
    if not button or not button.GetChildren then return nil end
    if raidFrameHealthCache[button] then return raidFrameHealthCache[button] end

    local best
    local bestHeight = -1
    local children = { button:GetChildren() }
    for _, child in ipairs(children) do
        local objectType = child.GetObjectType and child:GetObjectType() or nil
        if objectType == "StatusBar" and child.GetStatusBarTexture then
            local height = child.GetHeight and child:GetHeight() or 0
            if height > bestHeight then
                best = child
                bestHeight = height
            end
        end
    end

    raidFrameHealthCache[button] = best
    return best
end

local function FindRaidFrameBackground(button)
    if not button or not button.GetRegions then return nil end
    if raidFrameBackgroundCache[button] then return raidFrameBackgroundCache[button] end

    local regions = { button:GetRegions() }
    for _, region in ipairs(regions) do
        local layer = region.GetDrawLayer and region:GetDrawLayer() or nil
        if layer == "BACKGROUND" and region.SetColorTexture then
            raidFrameBackgroundCache[button] = region
            return region
        end
    end
end

local function PatchRaidFrameButton(button, isParty, seenHealth)
    local health = FindRaidFrameHealth(button)
    if not health then return 0 end

    local unit = ResolveFrameUnit(button)
    if not unit then return 0 end

    local bg = FindRaidFrameBackground(button)
    health._yunoRaidPatch = { button = button, bg = bg, isParty = isParty }

    if hooksecurefunc and not health._yunoRaidStatusColorHooked then
        health._yunoRaidStatusColorHooked = true
        hooksecurefunc(health, "SetStatusBarColor", function(self)
            local patch = self._yunoRaidPatch
            if patch and C_Timer and not self._yunoRaidPatchPending then
                self._yunoRaidPatchPending = true
                C_Timer.After(0, function()
                    self._yunoRaidPatchPending = false
                    ApplyRaidFrameHealthPatch(patch.button, self, patch.bg, ResolveFrameUnit(patch.button) or self._yunoUnit, patch.isParty)
                end)
            end
        end)
    end

    ApplyRaidFrameHealthPatch(button, health, bg, unit, isParty)

    if seenHealth[health] then return 0 end
    seenHealth[health] = true
    return 1
end

local function PatchHeaderButtons(header, isParty, seenHealth, maxButtons)
    if not header then return 0 end
    local patched = 0
    for index = 1, maxButtons do
        patched = patched + PatchRaidFrameButton(header[index], isParty, seenHealth)
    end
    return patched
end

local function PatchEllesmereRaidFrames(seenHealth)
    local patched = 0
    for group = 1, 8 do
        patched = patched + PatchHeaderButtons(_G["ERFGroupHeader" .. group], false, seenHealth, 5)
    end
    patched = patched + PatchHeaderButtons(_G.ERFFlatHeader, false, seenHealth, 40)
    patched = patched + PatchHeaderButtons(_G.ERFPartyHeader, true, seenHealth, 5)
    patched = patched + PatchRaidFrameButton(_G.ERFPartySelfButton, true, seenHealth)
    return patched
end

local function RestoreRaidFrameButton(button, isParty)
    local health = FindRaidFrameHealth(button)
    if not health then return end

    local bg = FindRaidFrameBackground(button)
    health._yunoBg = bg
    health._yunoBgOwner = button
    health._yunoDarkModeOverride = IsRaidFrameDarkMode(isParty)

    RestoreRaidFrameBackground(health, isParty)

    local alpha = GetRaidFrameHealthAlpha(isParty)
    local fill = health.GetStatusBarTexture and health:GetStatusBarTexture()
    if fill then fill:SetAlpha(alpha) end
    if bg then bg:SetAlpha(alpha) end
end

local function RestoreRaidHeaderButtons(header, isParty, maxButtons)
    if not header then return end
    for index = 1, maxButtons do
        RestoreRaidFrameButton(header[index], isParty)
    end
end

RestoreEllesmereRaidFrames = function()
    for group = 1, 8 do
        RestoreRaidHeaderButtons(_G["ERFGroupHeader" .. group], false, 5)
    end
    RestoreRaidHeaderButtons(_G.ERFFlatHeader, false, 40)
    RestoreRaidHeaderButtons(_G.ERFPartyHeader, true, 5)
    RestoreRaidFrameButton(_G.ERFPartySelfButton, true)
end

local function ApplyAll()
    EnsureDB()
    ApplyEllesmereThemeSettings()
    ApplyConfiguredProfileSettings()
    local patched = 0
    local seenHealth = {}
    for unit, frameName in pairs(FRAME_NAMES) do
        local health = PatchFrame(unit, frameName)
        if health and not seenHealth[health] then
            seenHealth[health] = true
            patched = patched + 1
        end
    end
    patched = patched + PatchDiscoveredFrames(seenHealth)
    patched = patched + PatchEllesmereRaidFrames(seenHealth)
    ApplyFriendlyPlayerNameplatePreference()
    ApplyChatSettings()
    ApplyEllesmereActionBarPagingOverride()
    return patched
end

local function ScheduleApply(delay)
    if pendingApply and not delay then return end
    pendingApply = true
    C_Timer.After(delay or 0, function()
        pendingApply = false
        ApplyAll()
    end)
end

local function ScheduleApplyBurst()
    ScheduleApply(0)
    ScheduleApply(0.15)
end

local function ScheduleSpecApplyBurst()
    ScheduleApply(0)
    ScheduleApply(0.15)
    ScheduleApply(0.50)
    ScheduleApply(1.00)
end

local function ScheduleStartupRetries()
    startupRetryVersion = startupRetryVersion + 1
    local version = startupRetryVersion
    local delays = { 0, 0.03, 0.10, 0.25, 0.50, 1.00, 2.00 }

    for _, delay in ipairs(delays) do
        C_Timer.After(delay, function()
            if version ~= startupRetryVersion then return end
            HookReload()
            ApplyEllesmereThemeSettings(true)
            if ApplyConfiguredProfileSettings() then ReloadEllesmereFrames() end
            ApplyAll()
        end)
    end
end

function HookReload()
    if type(_G._EUF_ReloadFrames) == "function" and hookedReload ~= _G._EUF_ReloadFrames then
        hooksecurefunc("_EUF_ReloadFrames", function()
            ScheduleApplyBurst()
        end)
        hookedReload = _G._EUF_ReloadFrames
    end

    if type(_G._ERF_RefreshAll) == "function" and hookedRaidReload ~= _G._ERF_RefreshAll then
        hooksecurefunc("_ERF_RefreshAll", function()
            ScheduleApplyBurst()
        end)
        hookedRaidReload = _G._ERF_RefreshAll
    end
end

local function GetClassKey()
    local _, classToken = UnitClass("player")
    return classToken and string.lower(classToken)
end

local function GetClassDisplayName()
    local _, classToken = UnitClass("player")
    return (classToken and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classToken]) or classToken or "Class"
end

local function GetSpecNames()
    local specs = {}
    local count = GetNumSpecializations and GetNumSpecializations() or 0
    for index = 1, count do
        local _, specName = GetSpecializationInfo(index)
        if specName then specs[#specs + 1] = specName end
    end
    return specs
end

local function GetCurrentSpecName()
    local index = GetSpecialization and GetSpecialization()
    if not index then return nil end
    local _, specName = GetSpecializationInfo(index)
    return specName
end

local function StartsWith(text, prefix)
    return type(text) == "string" and text:sub(1, #prefix) == prefix
end

local function GetYunoCooldownData()
    local classKey = GetClassKey()
    local classData = classKey and YunoCooldownLayouts and YunoCooldownLayouts[classKey]
    if type(classData) ~= "string" then
        return nil, "no yuno cooldown data found for " .. tostring(classKey or "current class")
    end

    return classData
end

local function GetCooldownLayoutManager()
    if C_CVar and C_CVar.GetCVar and C_CVar.GetCVar("cooldownViewerEnabled") == "0" then
        return nil, "Blizzard Cooldown Manager is disabled"
    end

    if not CooldownViewerSettings then
        if C_AddOns and C_AddOns.LoadAddOn then
            pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
        elseif LoadAddOn then
            pcall(LoadAddOn, "Blizzard_CooldownViewer")
        end
    end

    if not CooldownViewerSettings or type(CooldownViewerSettings.GetLayoutManager) ~= "function" then
        return nil, "Blizzard Cooldown Manager settings are not loaded"
    end

    local layoutManager = CooldownViewerSettings:GetLayoutManager()
    if not layoutManager or type(layoutManager.CreateLayoutsFromSerializedData) ~= "function" then
        return nil, "Blizzard Cooldown Manager layout manager was not available"
    end

    return layoutManager
end

local function SaveCooldownLayouts(layoutManager)
    if layoutManager and type(layoutManager.SaveLayouts) == "function" then
        pcall(layoutManager.SaveLayouts, layoutManager)
    end
end

local function RemoveYunoCooldownLayouts(layoutManager)
    if not layoutManager or type(layoutManager.layouts) ~= "table" then return 0 end

    local prefix = "yuno - " .. GetClassDisplayName()
    local removed = 0
    local kept = {}

    for _, layout in pairs(layoutManager.layouts) do
        if layout then
            local name = layout.layoutName or layout.name
            if StartsWith(name, prefix) then
                removed = removed + 1
            else
                kept[#kept + 1] = layout
            end
        end
    end

    if removed == 0 then return 0 end

    for key in pairs(layoutManager.layouts) do
        layoutManager.layouts[key] = nil
    end

    for index, layout in ipairs(kept) do
        layout.layoutID = index
        layoutManager.layouts[index] = layout
    end

    SaveCooldownLayouts(layoutManager)
    return removed
end

local function RenameYunoCooldownLayouts(layoutManager, layoutIDs)
    local className = GetClassDisplayName()
    local specs = GetSpecNames()
    local activeSpec = GetCurrentSpecName()
    local activeLayoutID = layoutIDs and layoutIDs[1]

    for index, layoutID in ipairs(layoutIDs or {}) do
        local layout = layoutManager.layouts and layoutManager.layouts[layoutID]
        if layout then
            local oldName = layout.name or layout.layoutName or ""
            local specName

            for _, candidate in ipairs(specs) do
                if oldName:find(candidate, 1, true) then
                    specName = candidate
                    break
                end
            end

            specName = specName or specs[index] or tostring(index)
            local newName = "yuno - " .. className .. " " .. specName
            layout.name = newName
            layout.layoutName = newName

            if activeSpec and specName == activeSpec then
                activeLayoutID = layoutID
            end
        end
    end

    return activeLayoutID
end

local function ImportYunoCooldownLayouts()
    if InCombatLockdown and InCombatLockdown() then
        return false, "leave combat before importing cooldown layouts"
    end

    local classData, dataError = GetYunoCooldownData()
    if not classData then return false, dataError end

    local layoutManager, managerError = GetCooldownLayoutManager()
    if not layoutManager then return false, managerError end

    local removed = RemoveYunoCooldownLayouts(layoutManager)
    local ok, layoutIDs = pcall(layoutManager.CreateLayoutsFromSerializedData, layoutManager, classData)
    if not ok or type(layoutIDs) ~= "table" or #layoutIDs == 0 then
        return false, "Blizzard rejected the cooldown layout import"
    end

    local activeLayoutID = RenameYunoCooldownLayouts(layoutManager, layoutIDs)
    if activeLayoutID and type(layoutManager.SetActiveLayoutByID) == "function" then
        pcall(layoutManager.SetActiveLayoutByID, layoutManager, activeLayoutID)
    end

    SaveCooldownLayouts(layoutManager)
    return true, "imported " .. #layoutIDs .. " cooldown layouts, removed " .. removed .. " old yuno layouts"
end

local function ShowInstallerFrame()
    EnsureDB()
    local UI = yuno and yuno.UI or YunoUI
    if cooldownImportFrame and cooldownImportFrame:IsShown() then
        cooldownImportFrame:Hide()
    end

    if not installerFrame then
        local frame = UI:CreateWindow("YunoInstallerFrame", UIParent, 620, 500)
        frame.subtitle:SetText("installer")
        frame._installerDone = {}

        frame.body = CreateFrame("Frame", nil, frame)
        frame.body:SetPoint("TOPLEFT", 22, -58)
        frame.body:SetPoint("BOTTOMRIGHT", -22, 18)

        local installerSteps
        installerSteps = {
            {
                title = "Welcome",
                body = "This installer imports yuno profiles into supported addons.\n\nRun each step in order, then reload at the end.",
                action = "Start",
            },
            {
                title = "BigWigs",
                body = "Imports the yuno BigWigs profile.\n\nBigWigs will show its own confirmation popup. Accept it, then continue.",
                action = "Import BigWigs",
                run = function()
                    local ok, message = ImportBigWigsProfile(function(accepted)
                        local callbackMessage = accepted and "BigWigs profile imported as yuno" or "BigWigs import cancelled"
                        frame._installerDone[2] = accepted and true or false
                        if frame.installerStatusPage then frame.installerStatusPage:SetStatus(accepted, callbackMessage) end
                        Print(callbackMessage)
                    end)
                    return ok, message
                end,
            },
            {
                title = "Blinkii's Portraits",
                body = "Imports the yuno Blinkii's Portraits profile.",
                action = "Import Blinkii's",
                run = ImportBlinkiisPortraitsProfile,
            },
            {
                title = "EXBoss",
                body = "Imports the yuno EXBoss profile, including available settings, trash cooldowns, and boss slots.",
                action = "Import EXBoss",
                run = ImportEXBossProfile,
            },
            {
                title = "Blizzard Edit Mode",
                body = "Imports the yuno Blizzard Edit Mode layout.\n\nAny existing layout named yuno is removed first so this step is repeatable.",
                action = "Import Edit Mode",
                run = ImportEditModeLayout,
            },
            {
                title = "EllesmereUI",
                body = "Imports the yuno EllesmereUI profile.\n\nUnit frame runtime patches still apply normally after this step.",
                action = "Import EllesmereUI",
                run = ImportEllesmereUIProfile,
            },
            {
                title = "Initialize Profiles",
                body = "Reload once now so imported Edit Mode, action bar, and Ellesmere profile data initialize before the final UI scale step.",
                action = "Reload UI",
                run = function()
                    MarkInstallerPendingFinalScale()
                    ReloadUI()
                    return true, "Reloading UI"
                end,
            },
            {
                title = "Finished",
                body = "Apply the 0.5333 UI scale, mark the install complete, and reload one final time.",
                action = "Apply Scale & Reload",
                run = function()
                    ApplyYunoUIScale(false)
                    MarkInstallerCompleted()
                    MarkProfilePromptApplied()
                    ReloadUI()
                    return true, "Reloading UI"
                end,
            },
        }
        frame._installerStepCount = #installerSteps

        local function SetButtonBackground(button, color, alpha)
            if not button.bg then
                button.bg = button:CreateTexture(nil, "BACKGROUND")
                button.bg:SetAllPoints()
            end
            button.bg:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
        end

        local function CreateSolidActionButton(parent, label)
            local button = CreateFrame("Frame", nil, parent)
            button:SetSize(224, 40)
            button:EnableMouse(true)
            SetButtonBackground(button, UI.Theme.accent)

            button.label = UI:CreateText(button, label, 13, "text", "bold")
            button.label:SetPoint("CENTER")
            button.label:SetTextColor(1, 1, 1, 1)

            function button:SetLabel(text)
                self.label:SetText(text or "")
            end

            function button:SetOnClick(callback)
                self._yunoOnClick = callback
            end

            function button:SetEnabledState(enabled)
                self._disabled = not enabled
                self:SetAlpha(enabled and 1 or 0.42)
                self:EnableMouse(enabled and true or false)
            end

            button:SetScript("OnEnter", function(self)
                if self._disabled then return end
                SetButtonBackground(self, UI.Theme.accent, 0.86)
            end)
            button:SetScript("OnLeave", function(self)
                SetButtonBackground(self, UI.Theme.accent)
                self:SetAlpha(self._disabled and 0.42 or 1)
            end)
            button:SetScript("OnMouseDown", function(self, mouseButton)
                if self._disabled or mouseButton ~= "LeftButton" then return end
                SetButtonBackground(self, UI.Theme.accent, 0.70)
            end)
            button:SetScript("OnMouseUp", function(self, mouseButton)
                if self._disabled then return end
                SetButtonBackground(self, UI.Theme.accent, self:IsMouseOver() and 0.86 or 1)
                if mouseButton == "LeftButton" and self._yunoOnClick then self:_yunoOnClick() end
            end)

            return button
        end

        frame.contentCanvas = CreateFrame("Frame", nil, frame.body)
        frame.contentCanvas:SetPoint("TOPLEFT")
        frame.contentCanvas:SetPoint("BOTTOMRIGHT", 0, 58)

        frame.stepTitle = UI:CreateText(frame.contentCanvas, "", 25, "text", "bold")
        frame.stepTitle:SetPoint("TOPLEFT", 56, -8)
        frame.stepTitle:SetPoint("TOPRIGHT", -56, -8)
        frame.stepTitle:SetJustifyH("CENTER")

        frame.stepBody = UI:CreateText(frame.contentCanvas, "", 13, "muted", "semibold")
        frame.stepBody:SetPoint("TOPLEFT", frame.stepTitle, "BOTTOMLEFT", 0, -16)
        frame.stepBody:SetPoint("TOPRIGHT", frame.stepTitle, "BOTTOMRIGHT", 0, -16)
        frame.stepBody:SetJustifyH("CENTER")
        frame.stepBody:SetJustifyV("TOP")
        frame.stepBody:SetSpacing(6)

        frame.logo = frame.contentCanvas:CreateTexture(nil, "ARTWORK")
        frame.logo:SetTexture("Interface\\AddOns\\yuno\\media\\logo.png")
        frame.logo:SetSize(200, 200)
        frame.logo:SetPoint("CENTER", frame.contentCanvas, "CENTER", 0, -30)

        frame.actionButton = CreateSolidActionButton(frame.contentCanvas, "Start")
        frame.actionButton:SetPoint("TOP", frame.logo, "BOTTOM", 0, -18)

        frame.footer = CreateFrame("Frame", nil, frame.body)
        frame.footer:SetPoint("BOTTOMLEFT")
        frame.footer:SetPoint("BOTTOMRIGHT")
        frame.footer:SetHeight(40)
        UI:SetFrameColor(frame.footer, UI.Theme.panel)

        frame.backButton = UI:CreateFlatButton(frame.footer, "Back")
        frame.backButton:SetSize(120, 34)
        frame.backButton:SetPoint("LEFT", frame.footer, "LEFT", 0, 0)

        frame.nextButton = UI:CreateFlatButton(frame.footer, "Next")
        frame.nextButton:SetSize(120, 34)
        frame.nextButton:SetPoint("RIGHT", frame.footer, "RIGHT", 0, 0)

        frame.progressBar = CreateFrame("Frame", nil, frame.footer)
        frame.progressBar:SetPoint("LEFT", frame.backButton, "RIGHT", 12, 0)
        frame.progressBar:SetPoint("RIGHT", frame.nextButton, "LEFT", -12, 0)
        frame.progressBar:SetHeight(34)
        UI:SetFrameColor(frame.progressBar, UI.Theme.row)

        frame.progressFill = frame.progressBar:CreateTexture(nil, "ARTWORK")
        frame.progressFill:SetPoint("TOPLEFT")
        frame.progressFill:SetPoint("BOTTOMLEFT")
        frame.progressFill:SetColorTexture(UI.Theme.accent[1], UI.Theme.accent[2], UI.Theme.accent[3], 1)

        frame.progressText = UI:CreateText(frame.progressBar, "", 12, "text", "bold")
        frame.progressText:SetPoint("CENTER")
        frame.progressText:SetJustifyH("CENTER")
        frame.progressText:SetTextColor(1, 1, 1, 1)

        local function RefreshProgress()
            local ratio = frame._installerProgressRatio or 0
            local width = frame.progressBar:GetWidth() or 0
            frame.progressFill:SetWidth(math.max(1, width * ratio))
        end

        frame.progressBar:SetScript("OnSizeChanged", RefreshProgress)

        function frame:SetInstallerStatus(ok, message)
            self._installerStatusOk = ok and true or false
            self._installerStatusMessage = message
        end

        function frame:SetStatus(ok, message)
            self:SetInstallerStatus(ok, message)
        end

        local function RenderInstaller()
            local index = frame._installerStepIndex or 1
            local step = installerSteps[index]
            local total = #installerSteps

            frame.stepTitle:SetText(step.title)
            frame.stepBody:SetText(step.body)
            frame.actionButton:SetLabel(step.action or "Apply")
            frame.progressText:SetText(tostring(index) .. " / " .. tostring(total))
            frame._installerProgressRatio = total > 0 and index / total or 0
            RefreshProgress()

            frame.backButton:SetEnabledState(index > 1)
            frame.backButton:SetOnClick(function()
                frame._installerStepIndex = math.max(1, (frame._installerStepIndex or 1) - 1)
                RenderInstaller()
            end)

            frame.nextButton:SetEnabledState(index > 1 and index < total)
            frame.nextButton:SetOnClick(function()
                frame._installerStepIndex = math.min(total, (frame._installerStepIndex or 1) + 1)
                RenderInstaller()
            end)

            frame.actionButton:SetEnabledState(true)
            frame.actionButton:SetOnClick(function()
                local currentIndex = frame._installerStepIndex or 1
                local currentStep = installerSteps[currentIndex]
                if not currentStep.run then
                    frame._installerStepIndex = math.min(total, currentIndex + 1)
                    RenderInstaller()
                    return
                end

                local ok, message = currentStep.run()
                frame._installerDone[currentIndex] = ok and true or false
                frame:SetInstallerStatus(ok, message or (ok and "step completed" or "step failed"))
                Print(message or (ok and "installer step completed" or "installer step failed"))
            end)
        end

        frame.installerStatusPage = frame
        frame.RenderInstaller = RenderInstaller
        installerFrame = frame
    end

    if YunoDB.installerPendingFinalScale and installerFrame._installerStepCount then
        installerFrame._installerStepIndex = installerFrame._installerStepCount
    elseif not installerFrame._installerStepIndex then
        installerFrame._installerStepIndex = 1
    end
    installerFrame.RenderInstaller()
    installerFrame:Show()
end

local function ShowCooldownImportFrame(initialTab)
    local UI = yuno and yuno.UI or YunoUI

    local function NormalizePage(page)
        if page == "cdm" or page == "cooldown" or page == "cooldowns" then return "cooldowns" end
        if page == "settings" then return "appearance" end
        if page == "install" or page == "installer" then return "installer" end
        if page == "cvars" then return "cvars" end
        if page == "qol" or page == "quality" or page == "qualityoflife" or page == "movement" or page == "movementtracker" or page == "qol_movement" then return "qol_movement" end
        if page == "graphics" or page == "fps" then return "graphics" end
        if page == "appearance" then return "appearance" end
        return page or "welcome"
    end

    if not cooldownImportFrame then
        local frame = UI:CreateWindow("YunoCooldownImportFrame", UIParent, 820, 560)
        frame._sidebarButtons = {}
        frame._installerDone = {}

        frame.body = CreateFrame("Frame", nil, frame)
        frame.body:SetPoint("TOPLEFT", 18, -58)
        frame.body:SetPoint("BOTTOMRIGHT", -18, 18)

        frame.sidebar = CreateFrame("Frame", nil, frame.body)
        frame.sidebar:SetPoint("TOPLEFT")
        frame.sidebar:SetPoint("BOTTOMLEFT")
        frame.sidebar:SetWidth(196)
        frame.sidebar:SetFrameLevel(frame.body:GetFrameLevel() + 3)
        UI:SetFrameColor(frame.sidebar, UI.Theme.bg)

        frame.sidebarTextLayer = CreateFrame("Frame", nil, frame)
        frame.sidebarTextLayer:SetPoint("TOPLEFT", frame.sidebar, "TOPLEFT")
        frame.sidebarTextLayer:SetPoint("BOTTOMRIGHT", frame.sidebar, "BOTTOMRIGHT")
        frame.sidebarTextLayer:SetFrameStrata(frame:GetFrameStrata())
        frame.sidebarTextLayer:SetFrameLevel(frame:GetFrameLevel() + 100)

        frame.contentClip = CreateFrame("Frame", nil, frame.body)
        frame.contentClip:SetPoint("TOPLEFT", frame.sidebar, "TOPRIGHT", 20, 0)
        frame.contentClip:SetPoint("BOTTOMRIGHT")
        frame.contentClip:SetFrameLevel(frame.body:GetFrameLevel() + 1)
        UI:SetFrameColor(frame.contentClip, UI.Theme.bg)

        local pageOrder = {
            { id = "welcome", label = "Welcome" },
            { id = "appearance", label = "Appearance" },
            { id = "cvars", label = "CVars" },
            { id = "qol", label = "Quality of Life", target = "qol_movement" },
            { id = "qol_movement", label = "Movement Tracker", parent = "qol" },
            { id = "graphics", label = "Graphics" },
            { id = "cooldowns", label = "Cooldowns" },
            { id = "installer", label = "Installer" },
        }
        frame._pageOrder = pageOrder

        local function CreatePage(title, description, maxWidth)
            if frame.page then
                frame.page:Hide()
                frame.page:SetParent(nil)
            end
            local page = UI:CreatePage(frame.contentClip, title, description, maxWidth or 550)
            frame.page = page
            return page
        end

        local function RenderWelcome()
            local page = CreatePage("Welcome", "A compact dashboard for yunoUI runtime settings, imports, and client presets.")
            local status = page:AddSection("STATUS")
            status:AddInfoRow("Current class", GetClassDisplayName())
            status:AddInfoRow("Runtime patches", YunoDB.enabled and "enabled" or "disabled")
            status:AddInfoRow("Installed profiles", HasInstalledYunoProfiles() and "found" or "not found")

            local actions = page:AddSection("QUICK ACTIONS")
            actions:AddButtonRow({
                {
                    label = "Apply Runtime Settings",
                    width = 190,
                    variant = "primary",
                    onClick = function()
                        ScheduleApply()
                        page:SetMuted("Runtime settings queued.")
                        Print("runtime settings queued")
                    end,
                },
                {
                    label = "Apply Installed Profiles",
                    width = 200,
                    onClick = function()
                        local ok, message = ApplyInstalledProfilesToCharacter(true)
                        page:SetStatus(ok, message)
                        Print(message)
                        if ok then Print("reload UI to finish applying loaded profiles") end
                    end,
                },
            }, "right")

            page:UpdateLayout()
            return page
        end

        local function RenderAppearance()
            local page = CreatePage("Appearance", "Runtime visual behavior controlled by yunoUI.")

            local automation = page:AddSection("AUTOMATION")
            automation:AddToggle("Enable yuno runtime patches", YunoDB.enabled == true, function(_, checked)
                YunoDB.enabled = checked
                if checked then
                    ScheduleApply()
                    UpdateIdleFadeController()
                    page:SetMuted("Runtime patches enabled.")
                    Print("enabled")
                else
                    RestoreAll()
                    UpdateIdleFadeController()
                    page:SetMuted("Runtime patches disabled.")
                    Print("disabled")
                end
            end)
            automation:AddToggle("Enforce EllesmereUI dark mode", YunoDB.forceDarkMode == true, function(_, checked)
                YunoDB.forceDarkMode = checked
                if ApplyConfiguredProfileSettings() then ReloadEllesmereFrames() end
                ScheduleApply()
                local message = checked and "dark mode enforcement enabled" or "dark mode enforcement disabled"
                page:SetMuted(message)
                Print(message)
            end)
            automation:AddToggle("Sync EllesmereUI colors to yuno blue", YunoDB.forceEUITheme == true, function(_, checked)
                YunoDB.forceEUITheme = checked
                local message
                if checked then
                    ApplyEllesmereThemeSettings(true, true)
                    message = "EllesmereUI color sync enabled"
                else
                    message = "EllesmereUI color sync disabled"
                end
                page:SetMuted(message)
                Print(message)
            end)

            local behaviors = page:AddSection("BEHAVIORS")
            behaviors:AddToggle("Force friendly player nameplates off", YunoDB.disableFriendlyPlayerNameplates == true, function(_, checked)
                YunoDB.disableFriendlyPlayerNameplates = checked
                local message
                if checked then
                    ApplyFriendlyPlayerNameplatePreference()
                    message = "friendly player nameplates forced off"
                else
                    message = "friendly player nameplate override disabled"
                end
                page:SetMuted(message)
                Print(message)
            end)
            behaviors:AddToggle("Fade player frame, resource bars, and cooldowns while idle", YunoDB.fadeIdlePlayerAndCooldowns == true, function(_, checked)
                YunoDB.fadeIdlePlayerAndCooldowns = checked
                ScheduleIdleFadeUpdate(0)
                local message = checked and "idle fade enabled" or "idle fade disabled"
                page:SetMuted(message)
                Print(message)
            end)
            behaviors:AddToggle("Disable form/stealth action bar paging", YunoDB.disableEllesmereActionBarPaging == true, function(_, checked)
                YunoDB.disableEllesmereActionBarPaging = checked
                local applied = ApplyEllesmereActionBarPagingOverride()
                ScheduleApply()
                local message = checked and "form/stealth action bar paging disabled" or "form/stealth action bar paging enabled"
                if InCombatLockdown and InCombatLockdown() then
                    message = message .. "; will apply after combat"
                elseif not applied then
                    message = message .. "; will apply when action bars load"
                end
                page:SetMuted(message)
                Print(message)
            end)

            page:UpdateLayout()
            return page
        end

        local function RenderCVars()
            local page = CreatePage("CVars", "Apply yuno's WoW client presets and combat text preferences.")
            local base = page:AddSection("BASE CVARS")
            base:AddButtonRow({
                {
                    label = "Set Base CVars",
                    width = 170,
                    variant = "primary",
                    onClick = function()
                        local applied, skipped = ApplyCVarTable(BASE_CVARS)
                        local message = "set CVars: " .. applied .. " applied"
                        if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
                        page:SetMuted(message)
                        Print(message)
                    end,
                },
            }, "right")

            local combatText = page:AddSection("FLOATING COMBAT TEXT")
            local disableButton
            local enableButton

            local function CombatTextMatches(value)
                local expected = tostring(value)
                for _, name in ipairs(FLOATING_COMBAT_TEXT_CVARS) do
                    if tostring(GetYunoCVar(name)) ~= expected then
                        return false
                    end
                end
                return true
            end

            local function GetActiveCombatTextPreset()
                if YunoDB.floatingCombatTextPreset == "disabled" or YunoDB.floatingCombatTextPreset == "enabled" then
                    return YunoDB.floatingCombatTextPreset
                end
                if CombatTextMatches(0) then return "disabled" end
                if CombatTextMatches(1) then return "enabled" end
                return nil
            end

            local function SetActiveCombatTextPreset(preset)
                if disableButton then disableButton:SetChoiceActive(preset == "disabled") end
                if enableButton then enableButton:SetChoiceActive(preset == "enabled") end
            end

            local row = combatText:AddButtonRow({
                {
                    label = "Disable",
                    width = 170,
                    onClick = function()
                        local applied, skipped = ApplyFloatingCombatText(0)
                        SetActiveCombatTextPreset("disabled")
                        local message = "floating combat text disabled: " .. applied .. " CVars"
                        if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
                        page:SetMuted(message)
                        Print(message)
                    end,
                },
                {
                    label = "Enable",
                    width = 170,
                    onClick = function()
                        local applied, skipped = ApplyFloatingCombatText(1)
                        SetActiveCombatTextPreset("enabled")
                        local message = "floating combat text enabled: " .. applied .. " CVars"
                        if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
                        page:SetMuted(message)
                        Print(message)
                    end,
                },
            }, "right")
            disableButton = row.buttons and row.buttons[1]
            enableButton = row.buttons and row.buttons[2]
            SetActiveCombatTextPreset(GetActiveCombatTextPreset())

            page:UpdateLayout()
            return page
        end

        local function RenderQualityOfLife()
            local page = CreatePage("Movement Tracker", "Shows an alert while your current spec's movement tools are unavailable.")
            local db = GetMovementTrackerDB()

            local movement = page:AddSection("SETTINGS")
            movement:AddInfoRow("Current spec spells", GetMovementTrackerSpellSummary())
            movement:AddToggle("Enable movement tracker", db.enabled == true, function(_, checked)
                db.enabled = checked
                InitializeMovementTrackerEvents()
                UpdateMovementTrackerDisplay()
                local message = checked and "movement tracker enabled" or "movement tracker disabled"
                page:SetMuted(message)
                Print(message)
            end)
            movement:AddToggle("Unlock movement tracker", db.unlock == true, function(_, checked)
                db.unlock = checked
                UpdateMovementTrackerDisplay()
                local message = checked and "movement tracker unlocked" or "movement tracker locked"
                page:SetMuted(message)
                Print(message)
            end)
            movement:AddToggle("Only show in combat", db.combatOnly == true, function(_, checked)
                db.combatOnly = checked
                UpdateMovementTrackerDisplay()
                local message = checked and "movement tracker limited to combat" or "movement tracker can show outside combat"
                page:SetMuted(message)
                Print(message)
            end)
            movement:AddStepperRow("Font size", db.fontSize or 12, 8, 32, 1, function(_, value)
                db.fontSize = value
                UpdateMovementTrackerDisplay()
                local message = "movement tracker font size set to " .. tostring(value)
                page:SetMuted(message)
                Print(message)
            end)

            page:UpdateLayout()
            return page
        end

        local function RenderGraphics()
            local page = CreatePage("Graphics", "Switch between FPS-focused and yuno's graphics CVar presets.")
            local actions = page:AddSection("PRESETS")

            actions:AddText("Graphics presets apply immediately and overwrite the matching client CVars.", 12, "muted", 42)

            local fpsButton
            local yunoButton

            local function PresetMatches(cvars)
                for _, cvar in ipairs(cvars) do
                    if tostring(GetYunoCVar(cvar[1])) ~= tostring(cvar[2]) then
                        return false
                    end
                end
                return true
            end

            local function GetActiveGraphicsPreset()
                if YunoDB.graphicsPreset == "yuno" or YunoDB.graphicsPreset == "fps" then
                    return YunoDB.graphicsPreset
                end
                if PresetMatches(YUNO_GRAPHICS_CVARS) then return "yuno" end
                if PresetMatches(FPS_CVARS) then return "fps" end
                return nil
            end

            local function SetActiveGraphicsPreset(preset)
                if fpsButton then fpsButton:SetChoiceActive(preset == "fps") end
                if yunoButton then yunoButton:SetChoiceActive(preset == "yuno") end
            end

            local row = actions:AddButtonRow({
                {
                    label = "FPS Settings",
                    width = 170,
                    onClick = function()
                        local applied, skipped = ApplyFPSSettings()
                        SetActiveGraphicsPreset("fps")
                        local message = "FPS preset applied: " .. applied .. " CVars"
                        if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
                        page:SetMuted(message)
                        Print(message)
                    end,
                },
                {
                    label = "Yuno Graphics",
                    width = 170,
                    onClick = function()
                        local applied, skipped = ApplyYunoGraphicsSettings()
                        SetActiveGraphicsPreset("yuno")
                        local message = "Yuno's graphics applied: " .. applied .. " CVars"
                        if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
                        page:SetMuted(message)
                        Print(message)
                    end,
                },
            }, "right")

            fpsButton = row.buttons and row.buttons[1]
            yunoButton = row.buttons and row.buttons[2]
            SetActiveGraphicsPreset(GetActiveGraphicsPreset())

            page:UpdateLayout()
            return page
        end

        local function RenderCooldowns()
            local page = CreatePage("Cooldowns", "Import Blizzard Cooldown Manager layouts for your current class.")
            local summary = page:AddSection("BLIZZARD COOLDOWN MANAGER")
            summary:AddInfoRow("Current class", GetClassDisplayName())
            summary:AddInfoRow("Import behavior", "replaces old yuno layouts")
            summary:AddButtonRow({
                {
                    label = "Import Layouts",
                    width = 170,
                    variant = "primary",
                    onClick = function()
                        local ok, message = ImportYunoCooldownLayouts()
                        page:SetStatus(ok, message or "")
                        Print(message or (ok and "cooldown layouts imported" or "cooldown import failed"))
                    end,
                },
            }, "right")

            page:UpdateLayout()
            return page
        end

        local function RenderInstaller()
            local page = CreatePage("Installer", "The installer opens in a dedicated window.")
            local launcher = page:AddSection("PROFILE INSTALLER")
            launcher:AddText("Use the installer window to import yuno profiles into supported addons and handle reload steps.", 13, "text", 66)
            launcher:AddButtonRow({
                {
                    label = "Open Installer",
                    width = 170,
                    variant = "primary",
                    onClick = function()
                        ShowInstallerFrame()
                    end,
                },
            }, "right")
            page:UpdateLayout()
            return page
        end

        local renderers = {
            welcome = RenderWelcome,
            appearance = RenderAppearance,
            cvars = RenderCVars,
            qol_movement = RenderQualityOfLife,
            graphics = RenderGraphics,
            cooldowns = RenderCooldowns,
            installer = RenderInstaller,
        }

        local function PageIsInGroup(page, parentId)
            for _, item in ipairs(pageOrder) do
                if item.parent == parentId and item.id == page then return true end
            end
            return false
        end

        local function LayoutSidebar(selectedPage)
            local previous
            local previousOverlay
            frame.sidebarTextLayer:SetFrameStrata(frame:GetFrameStrata())
            frame.sidebarTextLayer:SetFrameLevel(frame:GetFrameLevel() + 100)
            frame.sidebarTextLayer:Show()
            for _, item in ipairs(pageOrder) do
                local button = frame._sidebarButtons[item.id]
                local visible = not item.parent or PageIsInGroup(selectedPage, item.parent)
                if visible then
                    button:Show()
                    if button.labelHost then button.labelHost:Hide() end
                    if button.overlayRow then button.overlayRow:Show() end
                    if button.overlayLabel then button.overlayLabel:Show() end
                    button.label:SetText(item.label)
                    button.label:Hide()
                    button:ClearAllPoints()
                    button:SetPoint("LEFT", 0, 0)
                    button:SetPoint("RIGHT", 0, 0)
                    if previous then
                        button:SetPoint("TOP", previous, "BOTTOM", 0, item.parent and -1 or -4)
                    else
                        button:SetPoint("TOP", 0, -4)
                    end

                    if button.overlayRow then
                        button.overlayRow:ClearAllPoints()
                        button.overlayRow:SetHeight(button:GetHeight())
                        button.overlayRow:SetPoint("LEFT", frame.sidebarTextLayer, "LEFT", 0, 0)
                        button.overlayRow:SetPoint("RIGHT", frame.sidebarTextLayer, "RIGHT", 0, 0)
                        if previousOverlay then
                            button.overlayRow:SetPoint("TOP", previousOverlay, "BOTTOM", 0, item.parent and -1 or -4)
                        else
                            button.overlayRow:SetPoint("TOP", frame.sidebarTextLayer, "TOP", 0, -4)
                        end
                        previousOverlay = button.overlayRow
                    end

                    if button.overlayLabel then
                        button.overlayLabel:SetText(item.label)
                        button.overlayLabel:ClearAllPoints()
                        button.overlayLabel:SetPoint("TOPLEFT", button.overlayRow or frame.sidebarTextLayer, "TOPLEFT", item.parent and 28 or 14, 0)
                        button.overlayLabel:SetPoint("BOTTOMRIGHT", button.overlayRow or frame.sidebarTextLayer, "BOTTOMRIGHT", -8, 0)
                    end
                    previous = button
                else
                    if button.labelHost then button.labelHost:Hide() end
                    if button.overlayRow then button.overlayRow:Hide() end
                    if button.overlayLabel then button.overlayLabel:Hide() end
                    button:Hide()
                end
            end
        end

        local function SelectPage(page, skipRender)
            page = NormalizePage(page)
            if not renderers[page] then page = "welcome" end
            frame._selectedTab = page
            frame._selectedPage = page
            LayoutSidebar(page)
            for id, button in pairs(frame._sidebarButtons) do
                button:SetActive(id == page or PageIsInGroup(page, id) or button.targetPage == page)
            end
            if skipRender then return end
            renderers[page]()
        end

        frame.SelectPage = SelectPage
        frame.SelectTab = SelectPage
        frame.RefreshInstallerStep = function() ShowInstallerFrame() end

        frame.RebuildSidebarTextLayer = function()
            for _, page in ipairs(pageOrder) do
                local button = frame._sidebarButtons[page.id]
                if button then
                    if button.overlayRow then
                        button.overlayRow:Hide()
                        button.overlayRow:SetParent(nil)
                    end

                    button.overlayRow = CreateFrame("Frame", nil, frame.sidebarTextLayer)
                    button.overlayRow:SetFrameLevel(frame.sidebarTextLayer:GetFrameLevel() + 1)
                    button.overlayRow:Hide()
                    button.overlayLabel = UI:CreateText(button.overlayRow, page.label, 12, "muted", "semibold")
                    button.overlayLabel:SetJustifyH("LEFT")
                    button.overlayLabel:SetJustifyV("MIDDLE")
                    if button.overlayLabel.SetDrawLayer then button.overlayLabel:SetDrawLayer("OVERLAY", 7) end
                    button.label:Hide()
                end
            end
        end

        for index, page in ipairs(pageOrder) do
            local button = UI:CreateSidebarButton(frame.sidebar, page.label, page.id)
            button.label:Hide()
            button.targetPage = page.target
            if page.parent then
                button:SetHeight(28)
                button:SetLabelInset(28)
            end
            button:SetOnClick(function() SelectPage(page.target or page.id) end)
            frame._sidebarButtons[page.id] = button
        end

        frame.RebuildSidebarTextLayer()
        cooldownImportFrame = frame
    end
    local selectedPage = NormalizePage(initialTab or cooldownImportFrame._selectedPage or "welcome")
    cooldownImportFrame.SelectPage(selectedPage)
    cooldownImportFrame:Show()
    C_Timer.After(0, function()
        if cooldownImportFrame and cooldownImportFrame:IsShown() then
            if cooldownImportFrame.RebuildSidebarTextLayer then
                cooldownImportFrame.RebuildSidebarTextLayer()
            end
            cooldownImportFrame.SelectPage(cooldownImportFrame._selectedPage or selectedPage, true)
        end
    end)
    C_Timer.After(0.30, function()
        if cooldownImportFrame and cooldownImportFrame:IsShown() then
            if cooldownImportFrame.RebuildSidebarTextLayer then
                cooldownImportFrame.RebuildSidebarTextLayer()
            end
            cooldownImportFrame.SelectPage(cooldownImportFrame._selectedPage or selectedPage, true)
        end
    end)
end

local function ShouldOpenFreshInstaller()
    EnsureDB()
    return YunoDB.installerPendingFinalScale == true or YunoDB.installerCompletedVersion ~= PROFILE_PROMPT_VERSION
end

local function ScheduleFreshInstallerOpen()
    if freshInstallerOpenScheduled then return end
    freshInstallerOpenScheduled = true
    C_Timer.After(2, function()
        freshInstallerOpenScheduled = false
        if InCombatLockdown and InCombatLockdown() then return end
        if ShouldOpenFreshInstaller() then
            ShowInstallerFrame()
        end
    end)
end

local function SetAllHealthOpacity(value)
    local changed = false
    local profile = GetEllesmereProfile()
    if type(profile) == "table" then
        for _, key in ipairs(DB_UNITS) do
            if type(profile[key]) == "table" then
                profile[key].healthBarOpacity = value
                changed = true
            end
        end
    end

    local raidProfile = GetEllesmereRaidFramesProfile()
    if type(raidProfile) == "table" then
        raidProfile.healthBarOpacity = value
        raidProfile.party_healthBarOpacity = value
        changed = true
    end

    return changed
end

local function PrintDamageMeterPositions()
    local found = false
    for index = 1, 5 do
        local frame = _G["EllesmereUIDMFrame" .. index]
        if frame then
            found = true
            local left = frame:GetLeft()
            local top = frame:GetTop()
            local width = frame:GetWidth()
            local height = frame:GetHeight()
            if left and top and width and height then
                Print(("dm window %d: x=%d, y=%d, width=%d, height=%d"):format(
                    index,
                    math.floor(left + 0.5),
                    math.floor(top + 0.5),
                    math.floor(width + 0.5),
                    math.floor(height + 0.5)
                ))
            else
                Print("dm window " .. index .. ": position is not available yet")
            end
        end
    end

    if not found then
        Print("no Damage Meter windows found")
    end
end

local function ShowHelp()
    Print("enabled=" .. tostring(YunoDB.enabled) ..
        ", bg=" .. tostring(YunoDB.classBackground) ..
        ", dark=" .. tostring(YunoDB.forceDarkMode) ..
        ", euiTheme=" .. tostring(YunoDB.forceEUITheme) ..
        ", friendlyNameplatesOff=" .. tostring(YunoDB.disableFriendlyPlayerNameplates) ..
        ", idleFade=" .. tostring(YunoDB.fadeIdlePlayerAndCooldowns) ..
        ", formPaging=" .. (YunoDB.disableEllesmereActionBarPaging and "off" or "on") ..
        ", chatButtons=" .. (YunoDB.forceChatSidebarRight and "right" or "left") ..
        ", opacity=" .. tostring(YunoDB.healthBarOpacity or 85) .. "%" ..
        ", tint=" .. math.floor((YunoDB.tint or 0.75) * 100 + 0.5) .. "%")
    Print("/yuno opens settings, /yuno help shows this list")
    Print("/yuno on|off, /yuno bg on|off, /yuno dark on|off, /yuno theme on|off, /yuno idlefade on|off, /yuno paging on|off, /yuno chat right|left, /yuno cdm import, /yuno install ellesmere|bigwigs|editmode|blinkii|exboss|settings, /yuno profiles, /yuno cvars, /yuno fct on|off, /yuno fps, /yuno graphics yuno, /yuno tint 75, /yuno opacity 85, /yuno dmpos, /yuno media, /yuno apply")
end

SLASH_YUNO1 = "/yuno"
SlashCmdList.YUNO = function(msg)
    EnsureDB()
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")

    if not cmd or cmd == "" then
        ShowCooldownImportFrame()
    elseif cmd == "help" or cmd == "status" then
        ShowHelp()
    elseif cmd == "on" then
        YunoDB.enabled = true
        ScheduleApply()
        UpdateIdleFadeController()
        Print("enabled")
    elseif cmd == "off" then
        YunoDB.enabled = false
        RestoreAll()
        UpdateIdleFadeController()
        Print("disabled")
    elseif cmd == "bg" then
        if arg == "on" or arg == "1" or arg == "true" then
            YunoDB.classBackground = true
            Print("class background enabled")
        elseif arg == "off" or arg == "0" or arg == "false" then
            YunoDB.classBackground = false
            Print("class background disabled")
        else
            Print("usage: /yuno bg on|off")
            return
        end
        ScheduleApply()
    elseif cmd == "dark" then
        if arg == "on" or arg == "1" or arg == "true" then
            YunoDB.forceDarkMode = true
            Print("dark mode enforcement enabled")
        elseif arg == "off" or arg == "0" or arg == "false" then
            YunoDB.forceDarkMode = false
            Print("dark mode enforcement disabled")
        else
            Print("usage: /yuno dark on|off")
            return
        end
        if ApplyConfiguredProfileSettings() then ReloadEllesmereFrames() end
        ScheduleApply()
    elseif cmd == "theme" then
        if arg == "on" or arg == "1" or arg == "true" then
            YunoDB.forceEUITheme = true
            ApplyEllesmereThemeSettings(true, true)
            Print("EllesmereUI theme enforcement enabled")
        elseif arg == "off" or arg == "0" or arg == "false" then
            YunoDB.forceEUITheme = false
            Print("EllesmereUI theme enforcement disabled")
        else
            Print("usage: /yuno theme on|off")
            return
        end
        ScheduleApply()
    elseif cmd == "idlefade" or cmd == "fade" then
        if arg == "on" or arg == "1" or arg == "true" then
            YunoDB.fadeIdlePlayerAndCooldowns = true
            UpdateIdleFadeController()
            Print("idle fade enabled")
        elseif arg == "off" or arg == "0" or arg == "false" then
            YunoDB.fadeIdlePlayerAndCooldowns = false
            UpdateIdleFadeController()
            Print("idle fade disabled")
        else
            Print("usage: /yuno idlefade on|off")
            return
        end
    elseif cmd == "paging" or cmd == "actionbarpaging" or cmd == "barpaging" then
        if arg == "off" or arg == "0" or arg == "false" or arg == "disable" or arg == "disabled" then
            YunoDB.disableEllesmereActionBarPaging = true
        elseif arg == "on" or arg == "1" or arg == "true" or arg == "enable" or arg == "enabled" then
            YunoDB.disableEllesmereActionBarPaging = false
        else
            Print("usage: /yuno paging on|off")
            return
        end

        local applied = ApplyEllesmereActionBarPagingOverride()
        ScheduleApply()
        local message = YunoDB.disableEllesmereActionBarPaging
            and "form/stealth action bar paging disabled"
            or "form/stealth action bar paging enabled"
        if InCombatLockdown and InCombatLockdown() then
            message = message .. "; will apply after combat"
        elseif not applied then
            message = message .. "; will apply when action bars load"
        end
        Print(message)
    elseif cmd == "chat" then
        if arg == "right" or arg == "on" or arg == "1" or arg == "true" then
            YunoDB.forceChatSidebarRight = true
            ApplyChatSettings()
            Print("chat buttons set to right")
        elseif arg == "left" or arg == "off" or arg == "0" or arg == "false" then
            YunoDB.forceChatSidebarRight = false
            ApplyChatSettings()
            Print("chat buttons set to left")
        else
            Print("usage: /yuno chat right|left")
            return
        end
        ScheduleApply()
    elseif cmd == "cdm" or cmd == "cooldowns" then
        if arg == "import" then
            local ok, message = ImportYunoCooldownLayouts()
            Print(message or (ok and "cooldown layouts imported" or "cooldown import failed"))
        else
            ShowCooldownImportFrame("cooldowns")
        end
    elseif cmd == "qol" or cmd == "quality" or cmd == "movement" or cmd == "movementtracker" then
        if arg == "on" or arg == "1" or arg == "true" or arg == "enable" then
            GetMovementTrackerDB().enabled = true
            InitializeMovementTrackerEvents()
            UpdateMovementTrackerDisplay()
            Print("movement tracker enabled")
        elseif arg == "off" or arg == "0" or arg == "false" or arg == "disable" then
            GetMovementTrackerDB().enabled = false
            UpdateMovementTrackerDisplay()
            Print("movement tracker disabled")
        elseif arg == "unlock" then
            GetMovementTrackerDB().unlock = true
            UpdateMovementTrackerDisplay()
            Print("movement tracker unlocked")
        elseif arg == "lock" then
            GetMovementTrackerDB().unlock = false
            UpdateMovementTrackerDisplay()
            Print("movement tracker locked")
        else
            ShowCooldownImportFrame("qol")
        end
    elseif cmd == "install" or cmd == "installer" then
        if arg == "ellesmere" or arg == "ellesmereui" or arg == "eui" then
            local ok, message = ImportEllesmereUIProfile()
            Print(message or (ok and "EllesmereUI imported" or "EllesmereUI import failed"))
        elseif arg == "bigwigs" or arg == "bw" then
            local ok, message = ImportBigWigsProfile(function(accepted)
                Print(accepted and "BigWigs profile imported as yuno" or "BigWigs import cancelled")
            end)
            Print(message or (ok and "BigWigs import opened" or "BigWigs import failed"))
        elseif arg == "editmode" or arg == "edit" then
            local ok, message = ImportEditModeLayout()
            Print(message or (ok and "Edit Mode imported" or "Edit Mode import failed"))
        elseif arg == "blinkii" or arg == "blinkiis" or arg == "portraits" then
            local ok, message = ImportBlinkiisPortraitsProfile()
            Print(message or (ok and "Blinkii's Portraits imported" or "Blinkii's Portraits import failed"))
        elseif arg == "exboss" or arg == "exb" then
            local ok, message = ImportEXBossProfile()
            Print(message or (ok and "EXBoss imported" or "EXBoss import failed"))
        elseif arg == "settings" or arg == "extras" or arg == "blizz" or arg == "blizzard" then
            local ok, message = ApplyEllesmereExtrasSettings()
            Print(message or (ok and "Ellesmere settings applied" or "Ellesmere settings failed"))
        else
            ShowInstallerFrame()
        end
    elseif cmd == "profiles" or cmd == "applyprofiles" or cmd == "alt" then
        local ok, message = ApplyInstalledProfilesToCharacter(true)
        Print(message)
        if ok then
            Print("reload UI to finish applying loaded profiles")
        end
    elseif cmd == "dmpos" or cmd == "damagepos" or cmd == "meterpos" then
        PrintDamageMeterPositions()
    elseif cmd == "cvars" then
        local applied, skipped = ApplyCVarTable(BASE_CVARS)
        local message = "set CVars: " .. applied .. " applied"
        if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
        Print(message)
    elseif cmd == "fct" or cmd == "combattext" then
        local value
        if arg == "on" or arg == "1" or arg == "true" or arg == "enable" then
            value = 1
        elseif arg == "off" or arg == "0" or arg == "false" or arg == "disable" then
            value = 0
        else
            Print("usage: /yuno fct on|off")
            return
        end
        local applied, skipped = ApplyFloatingCombatText(value)
        local message = "floating combat text " .. (value == 1 and "enabled" or "disabled") .. ": " .. applied .. " CVars"
        if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
        Print(message)
    elseif cmd == "fps" or cmd == "graphics" then
        if cmd == "graphics" and (arg == "yuno" or arg == "yunos" or arg == "yuno's") then
            local applied, skipped = ApplyYunoGraphicsSettings()
            local message = "Yuno's graphics applied: " .. applied .. " CVars"
            if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
            Print(message)
            return
        end

        local applied, skipped = ApplyFPSSettings()
        local message = "FPS settings applied: " .. applied .. " CVars"
        if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
        Print(message)
    elseif cmd == "tint" then
        local value = tonumber(arg)
        if not value then
            Print("usage: /yuno tint 75")
            return
        end
        if value > 1 then value = value / 100 end
        if value < 0 then value = 0 end
        if value > 1 then value = 1 end
        YunoDB.tint = value
        ScheduleApply()
        Print("class background tint set to " .. math.floor(value * 100 + 0.5) .. "%")
    elseif cmd == "opacity" then
        local value = tonumber(arg)
        if not value then
            Print("usage: /yuno opacity 75")
            return
        end
        value = math.floor(value + 0.5)
        if value < 0 then value = 0 end
        if value > 100 then value = 100 end
        YunoDB.healthBarOpacity = value
        YunoDB.forceOpacity = true
        if SetAllHealthOpacity(value) then
            ScheduleApply()
            ReloadEllesmereFrames()
            Print("health opacity set to " .. value .. "%")
        else
            Print("Ellesmere unit frame profiles were not ready")
        end
    elseif cmd == "apply" or cmd == "reload" then
        local count = ApplyAll()
        ApplyEllesmereThemeSettings(true, true)
        Print("patched " .. count .. " unit frame bars")
    elseif cmd == "fonts" or cmd == "media" then
        if RegisterMedia() then
            Print("registered yuno fonts and statusbars with SharedMedia")
        else
            Print("LibSharedMedia-3.0 was not available")
        end
    else
        ShowHelp()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(eventFrame.RegisterEvent, eventFrame, "PLAYER_SPECIALIZATION_CHANGED")
pcall(eventFrame.RegisterEvent, eventFrame, "ACTIVE_TALENT_GROUP_CHANGED")
pcall(eventFrame.RegisterEvent, eventFrame, "TRAIT_CONFIG_UPDATED")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= ADDON_NAME and addonName ~= "EllesmereUIUnitFrames" and addonName ~= "EllesmereUIRaidFrames" and addonName ~= "EllesmereUIChat" and addonName ~= "EllesmereUINameplates" and addonName ~= "EllesmereUICooldownManager" and addonName ~= "EllesmereUIResourceBars" and addonName ~= "EllesmereUIActionBars" then
        return
    end

    if not fontsRegistered or not statusbarsRegistered then RegisterMedia() end
    EnsureDB()
    InitializeMovementTrackerEvents()
    HookFriendlyPlayerNameplateCVars()
    HookReload()
    local forceThemeLive = event == "ADDON_LOADED" or event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD"
    ApplyEllesmereThemeSettings(forceThemeLive)
    if ApplyConfiguredProfileSettings() then ReloadEllesmereFrames() end
    ApplyAll()
    UpdateMovementTrackerDisplay()
    ScheduleApplyBurst()
    ScheduleIdleFadeUpdate(0)

    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
        ScheduleSpecApplyBurst()
    end

    if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        ScheduleStartupRetries()
    end
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        ScheduleInstalledProfilesOffer()
        ScheduleFreshInstallerOpen()
    end
end)

C_Timer.After(0, function()
    RegisterMedia()
    EnsureDB()
    InitializeMovementTrackerEvents()
    HookFriendlyPlayerNameplateCVars()
    HookReload()
    ApplyEllesmereThemeSettings(true)
    ApplyConfiguredProfileSettings()
    ApplyAll()
    UpdateMovementTrackerDisplay()
    ScheduleIdleFadeUpdate(0)
    ScheduleStartupRetries()
end)

C_Timer.After(1, function()
    RegisterMedia()
    EnsureDB()
    HookFriendlyPlayerNameplateCVars()
    HookReload()
    ApplyEllesmereThemeSettings(true)
    if ApplyConfiguredProfileSettings() then ReloadEllesmereFrames() end
    ApplyAll()
    UpdateMovementTrackerDisplay()
    ScheduleIdleFadeUpdate(0)
end)
