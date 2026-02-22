-- BCM hook for power bar width
local MUI = unpack(yunoUI)

local BCM = {}
MUI.BCM = BCM

local powerBarSizing = false

local function ApplyPowerBarOffset()
    local powerBar = _G["BCDM_PowerBar"]
    if not powerBar then return end
    if powerBarSizing then return end

    local offset = (MUI.db and MUI.db.profile and MUI.db.profile.cooldowns and MUI.db.profile.cooldowns.powerBarOffset) or 0
    if offset == 0 then return end

    local addon = LibStub("AceAddon-3.0", true):GetAddon("BetterCooldownManager", true)
    local baseWidth = 0
    if addon and addon.db then
        local pbDB = addon.db.profile and addon.db.profile.PowerBar
        if pbDB and pbDB.MatchWidthOfAnchor and pbDB.Layout and pbDB.Layout[2] then
            local anchor = _G[pbDB.Layout[2]]
            if anchor then baseWidth = anchor:GetWidth() end
        elseif pbDB and pbDB.Width then
            baseWidth = pbDB.Width
        end
    end
    if baseWidth == 0 then baseWidth = powerBar:GetWidth() end

    powerBarSizing = true
    powerBar:SetWidth(baseWidth + offset)
    powerBarSizing = false
end

local function HookPowerBar(powerBar)
    if not powerBar or powerBar.yunoUIHook then return end
    hooksecurefunc(powerBar, "SetWidth", function() ApplyPowerBarOffset() end)
    hooksecurefunc(powerBar, "SetSize", function() ApplyPowerBarOffset() end)
    powerBar.yunoUIHook = true
end

local function TryInit()
    if not (MUI and MUI.IsAddOnEnabled and MUI:IsAddOnEnabled("BetterCooldownManager")) then return end
    local powerBar = _G["BCDM_PowerBar"]
    if powerBar then
        HookPowerBar(powerBar)
        ApplyPowerBarOffset()
    else
        C_Timer.After(2, function()
            local pb = _G["BCDM_PowerBar"]
            if pb then HookPowerBar(pb); ApplyPowerBarOffset() end
        end)
    end
end

C_Timer.After(1, TryInit)

function BCM:UpdatePowerBar()
    ApplyPowerBarOffset()
end
