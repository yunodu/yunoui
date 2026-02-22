local MUI = unpack(yunoUI)
local SE = MUI:GetModule("Setup")

local function mergeTable(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            mergeTable(dst[k], v)
        else
            dst[k] = v
        end
    end
end

function SE.WarpDeplete(addon, import, resolution)
    if not MUI:IsAddOnEnabled("WarpDeplete") then
        return
    end

    local loaded = (C_AddOns and C_AddOns.LoadAddOn("WarpDeplete")) or LoadAddOn("WarpDeplete")
    if not loaded or not WarpDepleteDB then
        return
    end

    local db = LibStub("AceDB-3.0"):New(WarpDepleteDB)

    if import then
        local PD = yunoUI_ProfileData
        local data = PD and PD.warpdeplete
        if type(data) == "table" and next(data) then
            db:SetProfile("yuno")
            mergeTable(db.profile, data)
        else
            db:SetProfile("yuno")
        end
        SE.CompleteSetup(addon)
        MUI.db.char.loaded = true
        MUI.db.global.version = MUI.version
        return
    end

    if not SE.IsProfileExisting(WarpDepleteDB) then
        SE.RemoveFromDatabase(addon)
        return
    end

    db:SetProfile("yuno")
end
