local MUI = unpack(yunoUI)
local SE = MUI:GetModule("Setup")

function SE.Details(addon, import, resolution)
    local PD = yunoUI_ProfileData
    local data, decompressedData
    local profile = "details" .. (resolution or "")
    local Details = Details

    if import then
        local str = PD and PD[profile]
        if not str or str == "" then
            MUI:Print("No Details profile string found. Check Data\\Standard\\AddOns\\Details.lua")
            return
        end
        data = DetailsFramework:Trim(str)
        decompressedData = Details:DecompressData(data, "print")

        Details:EraseProfile("yuno")
        Details:ImportProfile(str, "yuno", false, false, true)

        if type(decompressedData) == "table" and decompressedData.profile and decompressedData.profile.instances then
            for i, v in Details:ListInstances() do
                if decompressedData.profile.instances[i] then
                    DetailsFramework.table.copy(v.hide_on_context, decompressedData.profile.instances[i].hide_on_context)
                end
            end
        end

        SE.CompleteSetup(addon)

        MUI.db.char.loaded = true
        MUI.db.global.version = MUI.version

        return
    end

    if not Details:GetProfile("yuno") then
        SE.RemoveFromDatabase(addon)

        return
    end

    Details:ApplyProfile("yuno")
end
