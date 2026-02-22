local MUI = unpack(yunoUI)
local SE = MUI:GetModule("Setup")

-- subset: "cvars" | "graphics" | "maxfps" | nil (both)
local MAXFPS_GRAPHICS = {
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

function SE.CVars(addon, import, subset)
    if not import then
        return
    end

    local PD = yunoUI_ProfileData
    if not PD and subset ~= "maxfps" then
        MUI:Print("No cvars data found. Check Data\\Standard\\AddOns\\CVars.lua")
        return
    end

    local function applyTable(t)
        if type(t) ~= "table" or not next(t) then return end
        if C_CVar and C_CVar.SetCVar then
            for cvar, value in pairs(t) do
                pcall(C_CVar.SetCVar, cvar, tostring(value))
            end
        end
    end

    if subset == "maxfps" then
        applyTable(MAXFPS_GRAPHICS)
    elseif subset == "graphics" then
        local graphics = PD.graphics
        if type(graphics) ~= "table" or not next(graphics) then
            MUI:Print("No graphics data found. Check Data\\Standard\\AddOns\\CVars.lua")
            return
        end
        applyTable(graphics)
    elseif subset == "cvars" then
        local cvars = PD.cvars
        if type(cvars) ~= "table" or not next(cvars) then
            MUI:Print("No cvars data found. Check Data\\Standard\\AddOns\\CVars.lua")
            return
        end
        applyTable(cvars)
        MUI:ApplyQOLInstallDefaults()
    else
        -- nil = both
        local cvars = PD.cvars
        local graphics = PD.graphics
        if (type(cvars) ~= "table" or not next(cvars)) and (type(graphics) ~= "table" or not next(graphics)) then
            MUI:Print("No cvars/graphics data found. Check Data\\Standard\\AddOns\\CVars.lua")
            return
        end
        applyTable(cvars)
        applyTable(graphics)
        MUI:ApplyQOLInstallDefaults()
    end

    SE.CompleteSetup(addon)
end
