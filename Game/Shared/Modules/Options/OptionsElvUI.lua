-- ElvUI loaded: /yui options opens AceConfig tree (same UI as ElvUI config).
local MUI = unpack(yunoUI)

local YUNOUI_AC_APP = "yunoUI"
local registered

local function db()
    return MUI.db.profile
end

local function cd()
    if not db().cooldowns then db().cooldowns = {} end
    return db().cooldowns
end

local function pt(key)
    local p = db().portraits
    if not p then db().portraits = {}; p = db().portraits end
    if key and not p[key] then p[key] = {} end
    return key and p[key] or p
end

local function ptGen()
    if not pt().general then pt().general = {} end
    return pt().general
end

local function portraitRefresh()
    if MUI.Portraits and MUI.Portraits.Initialize then MUI.Portraits:Initialize() end
end

local function bcmRefresh()
    if MUI.BCM and MUI.BCM.UpdatePowerBar then MUI.BCM:UpdatePowerBar() end
end

local function mrRefresh()
    if MUI.MouseRingUpdateDisplay then MUI.MouseRingUpdateDisplay() end
end

local function chRefresh()
    if MUI.CrosshairUpdateDisplay then MUI.CrosshairUpdateDisplay() end
end

local function applyDefaults()
    if MUI.ApplyOptionDefaultsForConfig then MUI.ApplyOptionDefaultsForConfig() end
end

-- per-unit portrait opts (player, target, pet, ...)
local function unitArgs(unitId, includeExtra)
    local u = pt(unitId)
    local args = {
        enable = { type = "toggle", name = "Enable", order = 1, get = function() return u.enable end, set = function(_, v) u.enable = v; portraitRefresh() end },
        size = { type = "range", name = "Size", min = 16, max = 128, step = 2, order = 2, get = function() return u.size or 70 end, set = function(_, v) u.size = v; portraitRefresh() end },
        relativePoint = { type = "select", name = "Anchor point", values = { LEFT = "Left", RIGHT = "Right", CENTER = "Center" }, order = 3, get = function() return u.relativePoint or "LEFT" end, set = function(_, v) u.relativePoint = v; portraitRefresh() end },
        x = { type = "range", name = "X offset", min = -128, max = 128, step = 1, order = 4, get = function() return u.x or 0 end, set = function(_, v) u.x = v; portraitRefresh() end },
        y = { type = "range", name = "Y offset", min = -128, max = 128, step = 1, order = 5, get = function() return u.y or 0 end, set = function(_, v) u.y = v; portraitRefresh() end },
        mirror = { type = "toggle", name = "Mirror", order = 6, get = function() return u.mirror end, set = function(_, v) u.mirror = v; portraitRefresh() end },
        cast = { type = "toggle", name = "Cast icon", order = 7, get = function() return u.cast end, set = function(_, v) u.cast = v; portraitRefresh() end },
    }
    if includeExtra then
        args.extraEnable = { type = "toggle", name = "Rare/Elite/Boss overlay", order = 8, get = function() return u.extraEnable end, set = function(_, v) u.extraEnable = v; portraitRefresh() end }
    end
    return args
end

function MUI.TryOpenElvUIConfig()
    local E = _G.ElvUI and unpack(_G.ElvUI)
    if not E or not E.Libs or not E.Libs.AceConfigDialog or not E.Libs.AceConfig then
        return false
    end

    local ACR = E.Libs.AceConfigRegistry
    local ACD = E.Libs.AceConfigDialog
    local AceConfig = E.Libs.AceConfig

    if not registered then
        local ok, err = pcall(function()
            AceConfig:RegisterOptionsTable(YUNOUI_AC_APP, function()
                return MUI.GetYunoUIOptionsTable and MUI:GetYunoUIOptionsTable() or {}
            end)
        end)
        if not ok then
            MUI:Print("yunoUI ElvUI config: " .. tostring(err))
            return false
        end
        registered = true
    end

    ACD:SetDefaultSize(YUNOUI_AC_APP, 760, 550)
    ACD:Open(YUNOUI_AC_APP)
    return true
end

-- options table for AceConfig (built when config opens)
function MUI:GetYunoUIOptionsTable()
    local p = db()
    local gen = ptGen()
    local sh = pt().shadow or {}
    local ex = pt().extra or {}

    return {
        type = "group",
        name = "yunoUI",
        childGroups = "tree",
        args = {
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = {
                    bcmHeader = {
                        type = "header",
                        name = "BetterCooldownManager",
                        order = 1,
                    },
                    powerBarOffset = {
                        type = "range",
                        name = "Power bar width offset",
                        min = -5,
                        max = 5,
                        step = 1,
                        order = 2,
                        get = function() return cd().powerBarOffset or 0 end,
                        set = function(_, v)
                            cd().powerBarOffset = v
                            bcmRefresh()
                        end,
                    },
                    defaultsBtn = {
                        type = "execute",
                        name = "Defaults",
                        order = 3,
                        func = function()
                            applyDefaults()
                            local r = LibStub("AceConfigRegistry-3.0-ElvUI", true)
                            if r and r.NotifyChange then r:NotifyChange(YUNOUI_AC_APP) end
                        end,
                    },
                    cvarsHeader = {
                        type = "header",
                        name = "CVars",
                        order = 10,
                    },
                    sharpening = {
                        type = "group",
                        name = "Sharpening",
                        order = 11,
                        inline = true,
                        args = {
                            enable = {
                                type = "execute",
                                name = "Enable",
                                width = "half",
                                order = 1,
                                func = function()
                                    if C_CVar and C_CVar.SetCVar then pcall(C_CVar.SetCVar, "ResampleAlwaysSharpen", "1") end
                                    MUI:Print("Sharpening: enabled.")
                                end,
                            },
                            disable = {
                                type = "execute",
                                name = "Disable",
                                width = "half",
                                order = 2,
                                func = function()
                                    if C_CVar and C_CVar.SetCVar then pcall(C_CVar.SetCVar, "ResampleAlwaysSharpen", "0") end
                                    MUI:Print("Sharpening: disabled.")
                                end,
                            },
                        },
                    },
                    fct = {
                        type = "group",
                        name = "Floating Combat Text",
                        order = 12,
                        inline = true,
                        args = {
                            enable = {
                                type = "execute",
                                name = "Enable",
                                width = "half",
                                order = 1,
                                func = function()
                                    local fct = {
                                        "floatingCombatTextCombatHealing_v2", "floatingCombatTextCombatDamageDirectionalScale_v2",
                                        "floatingCombatTextCombatHealingAbsorbTarget_v2", "floatingCombatTextCombatDamage_v2",
                                        "floatingCombatTextPetMeleeDamage_v2", "floatingCombatTextCombatLogPeriodicSpells_v2",
                                        "floatingCombatTextPetSpellDamage_v2",
                                    }
                                    if C_CVar and C_CVar.SetCVar then for _, cvar in ipairs(fct) do pcall(C_CVar.SetCVar, cvar, "1") end end
                                    MUI:Print("Floating Combat Text: enabled.")
                                end,
                            },
                            disable = {
                                type = "execute",
                                name = "Disable",
                                width = "half",
                                order = 2,
                                func = function()
                                    local fct = {
                                        "floatingCombatTextCombatHealing_v2", "floatingCombatTextCombatDamageDirectionalScale_v2",
                                        "floatingCombatTextCombatHealingAbsorbTarget_v2", "floatingCombatTextCombatDamage_v2",
                                        "floatingCombatTextPetMeleeDamage_v2", "floatingCombatTextCombatLogPeriodicSpells_v2",
                                        "floatingCombatTextPetSpellDamage_v2",
                                    }
                                    if C_CVar and C_CVar.SetCVar then for _, cvar in ipairs(fct) do pcall(C_CVar.SetCVar, cvar, "0") end end
                                    MUI:Print("Floating Combat Text: disabled.")
                                end,
                            },
                        },
                    },
                    graphicSettings = {
                        type = "group",
                        name = "Graphic Settings",
                        order = 13,
                        inline = true,
                        args = {
                            yuno = {
                                type = "execute",
                                name = "Yuno",
                                width = "half",
                                order = 1,
                                func = function()
                                    local PD = yunoUI_ProfileData
                                    local graphics = PD and PD.graphics
                                    if type(graphics) == "table" and next(graphics) and C_CVar and C_CVar.SetCVar then
                                        for cvar, value in pairs(graphics) do pcall(C_CVar.SetCVar, cvar, tostring(value)) end
                                        MUI:Print("Graphic settings: Yuno (initial setup values) applied.")
                                    else
                                        MUI:Print("No graphics data found. Run the installer Apply graphics first.")
                                    end
                                end,
                            },
                            maxFps = {
                                type = "execute",
                                name = "Max FPS",
                                width = "half",
                                order = 2,
                                func = function()
                                    local maxFps = {
                                        ["msaaquality"] = "0",
                                        ["lowlatencymode"] = "3",
                                        ["ffxantialiasingmode"] = "4",
                                        ["graphicsshadowquality"] = "1",
                                        ["graphicsliquiddetail"] = "2",
                                        ["graphicsparticledensity"] = "3",
                                        ["graphicsssao"] = "0",
                                        ["graphicsDepthEffects"] = "0",
                                        ["graphicscomputeeffects"] = "0",
                                        ["graphicsoutlinemode"] = "2",
                                        ["graphicstextureresolution"] = "2",
                                        ["graphicsspelldensity"] = "0",
                                        ["graphicsprojectedtextures"] = "1",
                                        ["graphicsviewdistance"] = "3",
                                        ["graphicsenvironmentdetail"] = "3",
                                    }
                                    if C_CVar and C_CVar.SetCVar then for cvar, value in pairs(maxFps) do pcall(C_CVar.SetCVar, cvar, value) end end
                                    MUI:Print("Graphic settings: Max FPS applied.")
                                end,
                            },
                        },
                    },
                },
            },
            portraits = {
                type = "group",
                name = "Portraits",
                order = 2,
                args = {
                    enable = {
                        type = "toggle",
                        name = "Enable",
                        order = 1,
                        get = function() return gen.enable ~= false end,
                        set = function(_, v) gen.enable = v; portraitRefresh() end,
                    },
                    portraitStyle = {
                        type = "select",
                        name = "Portrait style",
                        values = { drop = "Drop", dropsharp = "Drop (sharp)", square = "Square", pure = "Pure", puresharp = "Pure (sharp)", circle = "Circle", thincircle = "Thin circle", diamond = "Diamond", thindiamond = "Thin diamond", octagon = "Octagon", pad = "Pad", shield = "Shield", thin = "Thin" },
                        order = 2,
                        get = function() return gen.portraitStyle or "drop" end,
                        set = function(_, v) gen.portraitStyle = v; portraitRefresh() end,
                    },
                    classicons = { type = "toggle", name = "Use class icons for players", order = 3, get = function() return gen.classicons end, set = function(_, v) gen.classicons = v; portraitRefresh() end },
                    gradient = { type = "toggle", name = "Gradient", order = 4, get = function() return gen.gradient end, set = function(_, v) gen.gradient = v; portraitRefresh() end },
                    ori = { type = "select", name = "Gradient orientation", values = { HORIZONTAL = "Horizontal", VERTICAL = "Vertical" }, order = 5, get = function() return gen.ori or "HORIZONTAL" end, set = function(_, v) gen.ori = v; portraitRefresh() end },
                    trilinear = { type = "toggle", name = "Trilinear filtering", order = 6, get = function() return gen.trilinear ~= false end, set = function(_, v) gen.trilinear = v; portraitRefresh() end },
                    desaturation = { type = "toggle", name = "Dead desaturation", order = 7, get = function() return gen.desaturation ~= false end, set = function(_, v) gen.desaturation = v; portraitRefresh() end },
                    deathcolor = { type = "toggle", name = "Death color overlay", order = 8, get = function() return gen.deathcolor ~= false end, set = function(_, v) gen.deathcolor = v; portraitRefresh() end },
                    default = { type = "toggle", name = "Use default color (ignore class/reaction)", order = 9, get = function() return gen.default end, set = function(_, v) gen.default = v; portraitRefresh() end },
                    reaction = { type = "toggle", name = "Use reaction color for players", order = 10, get = function() return gen.reaction end, set = function(_, v) gen.reaction = v; portraitRefresh() end },
                    style = { type = "select", name = "Texture style", values = { a = "Style A (Flat)", b = "Style B (Smooth)", c = "Style C (Metallic)" }, order = 11, get = function() return gen.style or "a" end, set = function(_, v) gen.style = v; portraitRefresh() end },
                    corner = { type = "toggle", name = "Enable corner", order = 12, get = function() return gen.corner ~= false end, set = function(_, v) gen.corner = v; portraitRefresh() end },
                    bgstyle = { type = "select", name = "Background texture", values = { [1] = "Style 1", [2] = "Style 2", [3] = "Style 3", [4] = "Style 4", [5] = "Style 5" }, order = 13, get = function() return gen.bgstyle or 1 end, set = function(_, v) gen.bgstyle = v; portraitRefresh() end },
                    zoom = { type = "range", name = "Zoom", min = 0, max = 1, step = 0.05, order = 14, get = function() return gen.zoom or 0 end, set = function(_, v) gen.zoom = v; portraitRefresh() end },
                    shadowEnable = { type = "toggle", name = "Enable shadow", order = 20, get = function() return sh.enable ~= false end, set = function(_, v) if not pt().shadow then pt().shadow = {} end pt().shadow.enable = v; portraitRefresh() end },
                    shadowBorder = { type = "toggle", name = "Border", order = 21, get = function() return sh.border end, set = function(_, v) if not pt().shadow then pt().shadow = {} end pt().shadow.border = v; portraitRefresh() end },
                    shadowInner = { type = "toggle", name = "Inner shadow", order = 22, get = function() return sh.inner end, set = function(_, v) if not pt().shadow then pt().shadow = {} end pt().shadow.inner = v; portraitRefresh() end },
                    rare = { type = "select", name = "Rare texture style", values = { a = "Style A", b = "Style B", c = "Style C", d = "Style D", e = "Style E" }, order = 30, get = function() return ex.rare or "a" end, set = function(_, v) if not pt().extra then pt().extra = {} end pt().extra.rare = v; portraitRefresh() end },
                    elite = { type = "select", name = "Elite texture style", values = { a = "Style A", b = "Style B", c = "Style C", d = "Style D", e = "Style E" }, order = 31, get = function() return ex.elite or "a" end, set = function(_, v) if not pt().extra then pt().extra = {} end pt().extra.elite = v; portraitRefresh() end },
                    boss = { type = "select", name = "Boss texture style", values = { a = "Style A", b = "Style B", c = "Style C", d = "Style D", e = "Style E" }, order = 32, get = function() return ex.boss or "a" end, set = function(_, v) if not pt().extra then pt().extra = {} end pt().extra.boss = v; portraitRefresh() end },
                    usetexturecolor = { type = "toggle", name = "Use texture color", order = 33, get = function() return gen.usetexturecolor end, set = function(_, v) gen.usetexturecolor = v; portraitRefresh() end },
                    player = { type = "group", name = "Player", order = 40, inline = true, args = unitArgs("player") },
                    target = { type = "group", name = "Target", order = 41, inline = true, args = unitArgs("target", true) },
                    pet = { type = "group", name = "Pet", order = 42, inline = true, args = unitArgs("pet") },
                    focus = { type = "group", name = "Focus", order = 43, inline = true, args = unitArgs("focus") },
                    targettarget = { type = "group", name = "Target of Target", order = 44, inline = true, args = unitArgs("targettarget") },
                    party = { type = "group", name = "Party", order = 45, inline = true, args = unitArgs("party") },
                    boss = { type = "group", name = "Boss", order = 46, inline = true, args = unitArgs("boss") },
                    arena = { type = "group", name = "Arena", order = 47, inline = true, args = unitArgs("arena") },
                },
            },
            mouseRingCrosshair = {
                type = "group",
                name = "Mouse Ring & Crosshair",
                order = 3,
                args = {
                    mrHeader = { type = "header", name = "Mouse Ring", order = 1 },
                    mrEnabled = { type = "toggle", name = "Enable", order = 2, get = function() return (p.mouseRing or {}).enabled end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.enabled = v; mrRefresh() end },
                    mrShowOutOfCombat = { type = "toggle", name = "Show out of combat", order = 3, get = function() return (p.mouseRing or {}).showOutOfCombat end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.showOutOfCombat = v; mrRefresh() end },
                    mrHideOnRightClick = { type = "toggle", name = "Hide on right-click", order = 4, get = function() return (p.mouseRing or {}).hideOnMouseClick end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.hideOnMouseClick = v; mrRefresh() end },
                    mrShape = { type = "select", name = "Shape", values = { ["ring.tga"] = "Circle", ["thin_ring.tga"] = "Thin", ["thick_ring.tga"] = "Thick" }, order = 5, get = function() return (p.mouseRing or {}).shape or "ring.tga" end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.shape = v; mrRefresh() end },
                    mrSize = { type = "range", name = "Size", min = 16, max = 256, step = 2, order = 6, get = function() return (p.mouseRing or {}).size or 64 end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.size = v; mrRefresh() end },
                    mrRingColor = { type = "color", name = "Ring color", hasAlpha = false, order = 7, get = function() local mr = p.mouseRing or {}; return mr.colorR or 1, mr.colorG or 1, mr.colorB or 1 end, set = function(_, r, g, b) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.colorR, p.mouseRing.colorG, p.mouseRing.colorB = r, g, b; mrRefresh() end },
                    mrUseClassColor = { type = "toggle", name = "Use class color", order = 8, get = function() return (p.mouseRing or {}).useClassColor end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.useClassColor = v; mrRefresh() end },
                    mrOpacityCombat = { type = "range", name = "Opacity (combat)", min = 0, max = 1, step = 0.1, order = 9, get = function() return (p.mouseRing or {}).opacityInCombat or 1 end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.opacityInCombat = v; mrRefresh() end },
                    mrOpacityOOC = { type = "range", name = "Opacity (out of combat)", min = 0, max = 1, step = 0.1, order = 10, get = function() return (p.mouseRing or {}).opacityOutOfCombat or 1 end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.opacityOutOfCombat = v; mrRefresh() end },
                    mrGcdEnabled = { type = "toggle", name = "GCD swipe", order = 11, get = function() return (p.mouseRing or {}).gcdEnabled end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.gcdEnabled = v; mrRefresh() end },
                    mrHideBackground = { type = "toggle", name = "Hide background when GCD active", order = 12, get = function() return (p.mouseRing or {}).hideBackground end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.hideBackground = v; mrRefresh() end },
                    mrGcdAlpha = { type = "range", name = "GCD swipe opacity", min = 0, max = 1, step = 0.1, order = 13, get = function() return (p.mouseRing or {}).gcdAlpha or 1 end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.gcdAlpha = v; mrRefresh() end },
                    mrCastSwipe = { type = "toggle", name = "Cast/Channel swipe", order = 14, get = function() return (p.mouseRing or {}).castSwipeEnabled end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.castSwipeEnabled = v; mrRefresh() end },
                    mrTrail = { type = "toggle", name = "Trail", order = 15, get = function() return (p.mouseRing or {}).trailEnabled end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.trailEnabled = v; mrRefresh() end },
                    mrTrailDuration = { type = "range", name = "Trail duration", min = 0.1, max = 1, step = 0.05, order = 16, get = function() return (p.mouseRing or {}).trailDuration or 0.3 end, set = function(_, v) if not p.mouseRing then p.mouseRing = {} end p.mouseRing.trailDuration = v; mrRefresh() end },
                    chHeader = { type = "header", name = "Crosshair", order = 20 },
                    chEnabled = { type = "toggle", name = "Enable", order = 21, get = function() return (p.crosshair or {}).enabled end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.enabled = v; chRefresh() end },
                    chCombatOnly = { type = "toggle", name = "Combat only", order = 22, get = function() return (p.crosshair or {}).combatOnly end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.combatOnly = v; chRefresh() end },
                    chHideMounted = { type = "toggle", name = "Hide while mounted", order = 23, get = function() return (p.crosshair or {}).hideWhileMounted end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.hideWhileMounted = v; chRefresh() end },
                    chColor = { type = "color", name = "Crosshair color", hasAlpha = false, order = 24, get = function() local ch = p.crosshair or {}; return ch.colorR or 1, ch.colorG or 1, ch.colorB or 1 end, set = function(_, r, g, b) if not p.crosshair then p.crosshair = {} end p.crosshair.colorR, p.crosshair.colorG, p.crosshair.colorB = r, g, b; chRefresh() end },
                    chUseClassColor = { type = "toggle", name = "Use class color", order = 25, get = function() return (p.crosshair or {}).useClassColor end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.useClassColor = v; chRefresh() end },
                    chSize = { type = "range", name = "Arm length", min = 2, max = 80, step = 1, order = 26, get = function() return (p.crosshair or {}).size or 20 end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.size = v; chRefresh() end },
                    chThickness = { type = "range", name = "Thickness", min = 1, max = 20, step = 1, order = 27, get = function() return (p.crosshair or {}).thickness or 2 end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.thickness = v; chRefresh() end },
                    chGap = { type = "range", name = "Center gap", min = 0, max = 40, step = 1, order = 28, get = function() return (p.crosshair or {}).gap or 0 end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.gap = v; chRefresh() end },
                    chDot = { type = "toggle", name = "Center dot", order = 29, get = function() return (p.crosshair or {}).dotEnabled end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.dotEnabled = v; chRefresh() end },
                    chDotSize = { type = "range", name = "Dot size", min = 1, max = 16, step = 1, order = 30, get = function() return (p.crosshair or {}).dotSize or 4 end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.dotSize = v; chRefresh() end },
                    chShowTop = { type = "toggle", name = "Show top arm", order = 31, get = function() return (p.crosshair or {}).showTop ~= false end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.showTop = v; chRefresh() end },
                    chShowRight = { type = "toggle", name = "Show right arm", order = 32, get = function() return (p.crosshair or {}).showRight ~= false end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.showRight = v; chRefresh() end },
                    chShowBottom = { type = "toggle", name = "Show bottom arm", order = 33, get = function() return (p.crosshair or {}).showBottom ~= false end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.showBottom = v; chRefresh() end },
                    chShowLeft = { type = "toggle", name = "Show left arm", order = 34, get = function() return (p.crosshair or {}).showLeft ~= false end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.showLeft = v; chRefresh() end },
                    chOpacity = { type = "range", name = "Opacity", min = 0, max = 1, step = 0.05, order = 35, get = function() return (p.crosshair or {}).opacity or 1 end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.opacity = v; chRefresh() end },
                    chOutline = { type = "toggle", name = "Outline", order = 36, get = function() return (p.crosshair or {}).outlineEnabled end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.outlineEnabled = v; chRefresh() end },
                    chOutlineWeight = { type = "range", name = "Outline weight", min = 1, max = 6, step = 1, order = 37, get = function() return (p.crosshair or {}).outlineWeight or 1 end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.outlineWeight = v; chRefresh() end },
                    chCircle = { type = "toggle", name = "Circle", order = 38, get = function() return (p.crosshair or {}).circleEnabled end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.circleEnabled = v; chRefresh() end },
                    chCircleSize = { type = "range", name = "Circle size", min = 10, max = 120, step = 1, order = 39, get = function() return (p.crosshair or {}).circleSize or 40 end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.circleSize = v; chRefresh() end },
                    chOffsetX = { type = "range", name = "Offset X", min = -200, max = 200, step = 1, order = 40, get = function() return (p.crosshair or {}).offsetX or 0 end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.offsetX = v; chRefresh() end },
                    chOffsetY = { type = "range", name = "Offset Y", min = -200, max = 200, step = 1, order = 41, get = function() return (p.crosshair or {}).offsetY or 0 end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.offsetY = v; chRefresh() end },
                    chMeleeRecolor = { type = "toggle", name = "Melee range recolor", order = 42, get = function() return (p.crosshair or {}).meleeRecolor end, set = function(_, v) if not p.crosshair then p.crosshair = {} end p.crosshair.meleeRecolor = v; chRefresh() end },
                },
            },
        },
    }
end
