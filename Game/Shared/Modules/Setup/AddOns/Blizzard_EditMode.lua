local MUI = unpack(yunoUI)
local SE = MUI:GetModule("Setup")

local C_EditMode, Enum = C_EditMode, Enum

local function IsLayoutExisting()
    local layouts = C_EditMode.GetLayouts()

    for i, v in ipairs(layouts.layouts) do
        if v.layoutName == "yuno" then
            return Enum.EditModePresetLayoutsMeta.NumValues + i
        end
    end
end

local function ImportBlizzard_EditMode(addon, resolution)
    local PD = yunoUI_ProfileData
    local layout = "blizzardeditmode" .. (resolution or "")
    local str = PD and PD[layout]
    if not str or str == "" then
        MUI:Print("No Edit Mode layout string found. Check Data\\Standard\\AddOns\\Blizzard_EditMode.lua")
        return
    end

    local layouts = C_EditMode.GetLayouts()
    local info

    for i = #layouts.layouts, 1, -1 do
        if layouts.layouts[i].layoutName == "yuno" then
            tremove(layouts.layouts, i)
        end
    end

    info = C_EditMode.ConvertStringToLayoutInfo(str)
    if not info then
        MUI:Print("Edit Mode could not parse the layout string. Re-export the layout from Edit Mode.")
        return
    end
    info.layoutName = "yuno"
    info.layoutType = Enum.EditModeLayoutType.Account

    tinsert(layouts.layouts, info)
    C_EditMode.SaveLayouts(layouts)

    SE.CompleteSetup(addon)

    MUI.db.char.loaded = true
    MUI.db.global.version = MUI.version
end

function SE.Blizzard_EditMode(addon, import, resolution)
    local layout

    if import then
        ImportBlizzard_EditMode(addon, resolution)
    end

    layout = IsLayoutExisting()

    if not layout then
        SE.RemoveFromDatabase(addon)

        return
    end

    C_EditMode.SetActiveLayout(layout)
end
