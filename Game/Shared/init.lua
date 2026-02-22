local _G = _G

-- Setup reads profile data from Data\Standard\AddOns\*.lua
_G.yunoUI_ProfileData = _G.yunoUI_ProfileData or {}

local C_AddOns_GetAddOnEnableState = C_AddOns.GetAddOnEnableState

local AceAddon = _G.LibStub("AceAddon-3.0")

local AddOnName, Engine = ...
local MUI = AceAddon:NewAddon(AddOnName, "AceConsole-3.0")

Engine[1] = MUI
_G.yunoUI = Engine

MUI.Data = MUI:NewModule("Data")
MUI.Installer = MUI:NewModule("Installer")
MUI.Setup = MUI:NewModule("Setup")

do
    function MUI:AddonCompartmentFunc()
        MUI:RunInstaller()
    end

    _G.yunoUI_AddonCompartmentFunc = MUI.AddonCompartmentFunc
end

function MUI:GetAddOnEnableState(addon, character)
    return C_AddOns_GetAddOnEnableState(addon, character)
end

function MUI:IsAddOnEnabled(addon)
    return MUI:GetAddOnEnableState(addon, MUI.myname) == 2
end

function MUI:OnEnable()
    MUI:Initialize()
end

local function portraitUnitPlayerLeft(x, y)
    return {
        enable = true,
        texture = "drop",
        size = 70,
        point = "RIGHT",
        relativePoint = "LEFT",
        x = x, y = y,
        mirror = false,
        strata = "AUTO",
        level = 10,
        cast = false,
        extraEnable = false,
    }
end
local function portraitUnitTargetRight(x, y)
    return {
        enable = true,
        texture = "drop",
        size = 70,
        point = "LEFT",
        relativePoint = "RIGHT",
        x = x, y = y,
        mirror = true,
        strata = "AUTO",
        level = 10,
        cast = false,
        extraEnable = false,
    }
end
local function portraitUnitDisabled(mirror, x, y)
    return {
        enable = false,
        texture = "drop",
        size = 70,
        point = mirror and "RIGHT" or "LEFT",
        relativePoint = mirror and "LEFT" or "RIGHT",
        x = x or (mirror and -14 or 14), y = 2,
        mirror = mirror or false,
        strata = "AUTO",
        level = 10,
        cast = false,
        extraEnable = false,
    }
end

local yunoUIDefaults = {
    profile = {
        cooldowns = {
            powerBarOffset = 2,
        },
        portraits = {
            general = {
                enable = true,
                portraitStyle = "drop",
                classicons = false,
                desaturation = true,
                deathcolor = true,
                default = false,
                reaction = false,
                style = "a",
                bgstyle = 1,
                zoom = 0,
                trilinear = true,
                gradient = false,
                ori = "HORIZONTAL",
                corner = true,
                usetexturecolor = false,
            },
            extra = {
                rare = "a",
                elite = "a",
                boss = "a",
            },
            shadow = {
                enable = true,
                border = false,
                inner = false,
                color = { r = 0, g = 0, b = 0, a = 1 },
                innerColor = { r = 0, g = 0, b = 0, a = 0.5 },
            },
            colors = {
                default = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
                friendly = { r = 0.2, g = 0.6, b = 0.2, a = 1 },
                enemy = { r = 0.6, g = 0.2, b = 0.2, a = 1 },
                neutral = { r = 0.6, g = 0.6, b = 0.2, a = 1 },
                death = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
                border = {
                    default = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
                    rare = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
                    rareelite = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
                    elite = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
                    boss = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
                },
            },
            player = portraitUnitPlayerLeft(14, 2),
            target = portraitUnitTargetRight(-14, 2),
            pet = portraitUnitDisabled(false, 14, 2),
            focus = portraitUnitDisabled(true, -14, 2),
            targettarget = portraitUnitDisabled(true, -14, 2),
            party = portraitUnitDisabled(false, 14, 2),
            boss = portraitUnitDisabled(true, -14, 2),
            arena = portraitUnitDisabled(true, -14, 2),
        },
        mouseRing = {
            enabled = true,
            size = 38,
            shape = "ring.tga",
            colorR = 1.0, colorG = 1.0, colorB = 1.0,
            useClassColor = false,
            showOutOfCombat = true,
            opacityInCombat = 1.0,
            opacityOutOfCombat = 0,
            trailEnabled = false,
            trailDuration = 0.5,
            trailR = 1.0, trailG = 1.0, trailB = 1.0,
            trailUseClassColor = false,
            gcdEnabled = false,
            gcdR = 0.004, gcdG = 0.56, gcdB = 0.91,
            gcdUseClassColor = false,
            gcdReadyR = 0.0, gcdReadyG = 0.8, gcdReadyB = 0.3,
            gcdReadyUseClassColor = false,
            gcdReadyMatchSwipe = false,
            gcdAlpha = 1.0,
            hideOnMouseClick = false,
            hideBackground = false,
            castSwipeEnabled = false,
            castSwipeR = 0.004, castSwipeG = 0.56, castSwipeB = 0.91,
            castSwipeUseClassColor = false,
        },
        crosshair = {
            enabled = false,
            size = 20,
            thickness = 2,
            gap = 6,
            colorR = 1, colorG = 1, colorB = 1,
            useClassColor = false,
            opacity = 0.8,
            offsetX = 0, offsetY = 0,
            combatOnly = false,
            hideWhileMounted = false,
            dotEnabled = false,
            dotSize = 2,
            outlineEnabled = false,
            outlineWeight = 1,
            outlineR = 0, outlineG = 0, outlineB = 0,
            outlineUseClassColor = false,
            showTop = false, showRight = false, showBottom = false, showLeft = false,
            circleEnabled = false,
            circleSize = 30,
            circleR = 0, circleG = 1, circleB = 0,
            circleUseClassColor = false,
            meleeRecolor = false,
            meleeRecolorBorder = true,
            meleeRecolorArms = false,
            meleeRecolorDot = false,
            meleeRecolorCircle = false,
            meleeOutColorR = 1, meleeOutColorG = 0, meleeOutColorB = 0,
            meleeOutUseClassColor = false,
            meleeSoundEnabled = false,
            meleeSoundID = 8959,
            meleeSoundInterval = 3,
            meleeSpellOverrides = {},
        },
    },
}

local function copyTable(src)
    if type(src) ~= "table" then return src end
    local t = {}
    for k, v in pairs(src) do
        t[k] = (type(v) == "table" and type(v) ~= nil) and copyTable(v) or v
    end
    return t
end

function MUI:ApplyQOLInstallDefaults()
    local p = self.db.profile
    local def = yunoUIDefaults.profile
    p.mouseRing = copyTable(def.mouseRing)
    p.crosshair = copyTable(def.crosshair)
    if self.MouseRingUpdateDisplay then self:MouseRingUpdateDisplay() end
    if self.CrosshairUpdateDisplay then self:CrosshairUpdateDisplay() end
end

local function deepMergeDefaults(target, source)
    for k, v in pairs(source) do
        if target[k] == nil then
            if type(v) == "table" then
                target[k] = {}
                deepMergeDefaults(target[k], v)
            else
                target[k] = v
            end
        elseif type(v) == "table" and type(target[k]) == "table" then
            deepMergeDefaults(target[k], v)
        end
    end
end

function MUI:ApplyOptionDefaults()
    local p = self.db.profile
    if not p.cooldowns then p.cooldowns = {} end
    deepMergeDefaults(p.cooldowns, yunoUIDefaults.profile.cooldowns)
    if not p.portraits then p.portraits = {} end
    deepMergeDefaults(p.portraits, yunoUIDefaults.profile.portraits)
    if not p.mouseRing then p.mouseRing = {} end
    deepMergeDefaults(p.mouseRing, yunoUIDefaults.profile.mouseRing)
    if not p.crosshair then p.crosshair = {} end
    deepMergeDefaults(p.crosshair, yunoUIDefaults.profile.crosshair)
end

function MUI:OnInitialize()
    self.db = _G.LibStub("AceDB-3.0"):New("yunoUIDB", yunoUIDefaults)

    self:RegisterChatCommand("yunoui", "HandleChatCommand")
    self:RegisterChatCommand("yui", "HandleChatCommand")
end
