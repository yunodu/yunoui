local MUI = unpack(yunoUI)

local YUNOUI_ASSETS = "Interface\\AddOns\\yunoUI\\Assets\\"
local function GetTexturePath(shape)
    return YUNOUI_ASSETS .. shape
end
local RING_TEXEL = 0.5 / 256
local TRAIL_TEXEL = 0.5 / 128
local TRAIL_MAX = 20
local GCD_SPELL = 61304
local SWIPE_DELAY = 0.08
local floor, max = math.floor, math.max

local function GetDB()
    local p = MUI.db.profile
    if not p.mouseRing then p.mouseRing = {} end
    return p.mouseRing
end

local function GetEffectiveColor(db, rKey, gKey, bKey, classColorKey)
    if classColorKey and db[classColorKey] then
        local _, classFile = UnitClass("player")
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
        if color then return color.r, color.g, color.b end
    end
    return db[rKey] or 1, db[gKey] or 1, db[bKey] or 1
end

local state = {
    inCombat = false,
    inInstance = false,
    isRightMouseDown = false,
    isCasting = false,
    isChanneling = false,
    castStart = 0, castEnd = 0,
    channelStart = 0, channelEnd = 0,
    gcdReady = true,
    gcdInfo = nil,
    gcdSwipeAllowed = true,
    gcdDelayTimer = nil,
    castSwipeAllowed = false,
    castDelayTimer = nil,
}

local container, ring, gcdCooldown, readyRing
local trailContainer, trailPoints = nil, {}

local UpdateMouseWatcher

local function ShouldBeVisible()
    local db = GetDB()
    if not db.enabled then return false end
    if db.hideOnMouseClick and state.isRightMouseDown then return false end
    if state.inCombat then return true end
    return db.showOutOfCombat ~= false
end

local function GetOpacity()
    local db = GetDB()
    if state.inCombat or state.inInstance then
        return db.opacityInCombat or 1.0
    end
    return db.opacityOutOfCombat or 1.0
end

local function GetRingColor()
    return GetEffectiveColor(GetDB(), "colorR", "colorG", "colorB", "useClassColor")
end

local function SetupTexture(tex, shape)
    local path = GetTexturePath(shape)
    tex:SetTexture(path, "CLAMP", "CLAMP", "TRILINEAR")
    tex:SetTexCoord(RING_TEXEL, 1 - RING_TEXEL, RING_TEXEL, 1 - RING_TEXEL)
    if tex.SetSnapToPixelGrid then
        tex:SetSnapToPixelGrid(false)
        tex:SetTexelSnappingBias(0)
    end
end

local function UpdateRender()
    if not container then return end
    local db = GetDB()
    local alpha = GetOpacity()
    UpdateMouseWatcher()
    if not ShouldBeVisible() then
        container:Hide()
        if trailContainer then trailContainer:Hide() end
        return
    end
    container:Show()
    if ring then
        if db.hideBackground then
            ring:Hide()
        else
            local r, g, b = GetRingColor()
            ring:SetVertexColor(r, g, b, 1)
            ring:SetAlpha(alpha)
            ring:Show()
        end
    end
    if gcdCooldown then
        local swipeAlpha = alpha * (db.gcdAlpha or 1)
        if db.castSwipeEnabled and state.isCasting and state.castStart > 0 and state.castSwipeAllowed then
            local r, g, b = GetEffectiveColor(db, "castSwipeR", "castSwipeG", "castSwipeB", "castSwipeUseClassColor")
            gcdCooldown:SetSwipeColor(r, g, b, swipeAlpha)
            gcdCooldown:SetCooldown(state.castStart, state.castEnd - state.castStart)
            gcdCooldown:Show()
        elseif db.castSwipeEnabled and state.isChanneling and state.channelStart > 0 and state.castSwipeAllowed then
            local r, g, b = GetEffectiveColor(db, "castSwipeR", "castSwipeG", "castSwipeB", "castSwipeUseClassColor")
            gcdCooldown:SetSwipeColor(r, g, b, swipeAlpha)
            gcdCooldown:SetCooldown(state.channelStart, state.channelEnd - state.channelStart)
            gcdCooldown:Show()
        elseif db.gcdEnabled and not state.gcdReady and state.gcdInfo and state.gcdSwipeAllowed then
            local r, g, b = GetEffectiveColor(db, "gcdR", "gcdG", "gcdB", "gcdUseClassColor")
            gcdCooldown:SetSwipeColor(r, g, b, swipeAlpha)
            local info = state.gcdInfo
            gcdCooldown:SetCooldown(info.startTime, info.duration, info.modRate)
            gcdCooldown:Show()
        else
            gcdCooldown:Hide()
        end
    end
    if readyRing then
        local showReady = db.gcdEnabled and state.gcdReady and not state.isCasting and not state.isChanneling
        if showReady then
            local readyR, readyG, readyB
            if db.gcdReadyMatchSwipe then
                readyR, readyG, readyB = GetEffectiveColor(db, "gcdR", "gcdG", "gcdB", "gcdUseClassColor")
            else
                readyR, readyG, readyB = db.gcdReadyR or 0, db.gcdReadyG or 0.8, db.gcdReadyB or 0.3
            end
            readyRing:SetVertexColor(readyR, readyG, readyB, 1)
            readyRing:SetAlpha(alpha)
            readyRing:Show()
        else
            readyRing:Hide()
        end
    end
    if trailContainer then
        if db.trailEnabled then trailContainer:Show() else trailContainer:Hide() end
    end
end

local function CreateRing()
    if container then return end
    local db = GetDB()
    local size = db.size or 48
    if size % 2 == 1 then size = size + 1 end
    local shape = db.shape or "ring.tga"
    container = CreateFrame("Frame", nil, UIParent)
    container:SetSize(size, size)
    container:SetFrameStrata("TOOLTIP")
    container:EnableMouse(false)
    ring = container:CreateTexture(nil, "BORDER")
    ring:SetAllPoints()
    SetupTexture(ring, shape)
    local r, g, b = GetRingColor()
    ring:SetVertexColor(r, g, b, 1)
    readyRing = container:CreateTexture(nil, "ARTWORK")
    readyRing:SetAllPoints()
    SetupTexture(readyRing, shape)
    readyRing:Hide()
    gcdCooldown = CreateFrame("Cooldown", nil, container, "CooldownFrameTemplate")
    gcdCooldown:SetAllPoints()
    gcdCooldown:SetDrawSwipe(true)
    gcdCooldown:SetDrawEdge(false)
    gcdCooldown:SetHideCountdownNumbers(true)
    gcdCooldown:SetReverse(true)
    gcdCooldown:SetSwipeTexture(GetTexturePath(shape))
    if gcdCooldown.SetDrawBling then gcdCooldown:SetDrawBling(false) end
    if gcdCooldown.SetUseCircularEdge then gcdCooldown:SetUseCircularEdge(true) end
    gcdCooldown:SetFrameLevel(container:GetFrameLevel() + 5)
    gcdCooldown:Hide()
    gcdCooldown:SetScript("OnCooldownDone", function()
        state.gcdReady = true
        state.gcdInfo = nil
        UpdateRender()
    end)
    local lastX, lastY, cursorAcc = 0, 0, 0
    container:SetScript("OnUpdate", function(self, elapsed)
        cursorAcc = cursorAcc + elapsed
        if cursorAcc < 0.0167 then return end
        cursorAcc = 0
        if not ShouldBeVisible() then return end
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        x, y = floor(x / scale + 0.5), floor(y / scale + 0.5)
        if x ~= lastX or y ~= lastY then
            lastX, lastY = x, y
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        end
    end)
    UpdateRender()
end

local function CreateTrail()
    if trailContainer then return end
    trailContainer = CreateFrame("Frame", nil, UIParent)
    trailContainer:SetFrameStrata("TOOLTIP")
    trailContainer:SetFrameLevel(1)
    trailContainer:SetPoint("BOTTOMLEFT")
    trailContainer:SetSize(1, 1)
    trailPoints = {}
    for i = 1, TRAIL_MAX do
        local tex = trailContainer:CreateTexture(nil, "BACKGROUND")
        tex:SetTexture(GetTexturePath("trail_glow.tga"), "CLAMP", "CLAMP", "TRILINEAR")
        tex:SetTexCoord(TRAIL_TEXEL, 1 - TRAIL_TEXEL, TRAIL_TEXEL, 1 - TRAIL_TEXEL)
        tex:SetBlendMode("ADD")
        tex:SetSize(24, 24)
        tex:Hide()
        trailPoints[i] = { tex = tex, x = 0, y = 0, time = 0, active = false }
    end
    local head, lastX, lastY, updateTimer, activeCount = 0, 0, 0, 0, 0
    local function trailUpdate(self, elapsed)
        local db = GetDB()
        local shouldTrack = db.trailEnabled and ShouldBeVisible()
        updateTimer = updateTimer + elapsed
        if updateTimer < 0.025 then return end
        updateTimer = 0
        local now = GetTime()
        if shouldTrack then
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            x, y = floor(x / scale + 0.5), floor(y / scale + 0.5)
            local dx, dy = x - lastX, y - lastY
            if dx * dx + dy * dy >= 4 then
                lastX, lastY = x, y
                head = (head % TRAIL_MAX) + 1
                local pt = trailPoints[head]
                if not pt.active then activeCount = activeCount + 1 end
                pt.x, pt.y, pt.time, pt.active = x, y, now, true
            end
        end
        if activeCount > 0 then
            local duration = max(db.trailDuration or 0.6, 0.1)
            local tr, tg, tb = GetEffectiveColor(db, "trailR", "trailG", "trailB", "trailUseClassColor")
            local opacity = GetOpacity()
            for i = 1, TRAIL_MAX do
                local pt = trailPoints[i]
                if pt.active then
                    local fade = 1 - (now - pt.time) / duration
                    if fade <= 0 then
                        pt.active = false
                        pt.tex:Hide()
                        activeCount = activeCount - 1
                    else
                        pt.tex:ClearAllPoints()
                        pt.tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pt.x, pt.y)
                        pt.tex:SetVertexColor(tr, tg, tb, fade * opacity * 0.8)
                        pt.tex:SetSize(24 * fade, 24 * fade)
                        pt.tex:Show()
                    end
                end
            end
        end
        if not shouldTrack and activeCount == 0 then self:SetScript("OnUpdate", nil) end
    end
    trailContainer:SetScript("OnShow", function(self) self:SetScript("OnUpdate", trailUpdate) end)
    trailContainer:SetScript("OnHide", function(self)
        if activeCount == 0 then self:SetScript("OnUpdate", nil) end
    end)
end

local function RefreshCombatState()
    state.inCombat = InCombatLockdown() or UnitAffectingCombat("player")
    local inInst, instType = IsInInstance()
    state.inInstance = inInst and (instType == "party" or instType == "raid" or instType == "pvp" or instType == "arena")
end

local mouseWatcher = CreateFrame("Frame")
local mouseWatcherActive = false
local function MouseWatcherOnUpdate()
    local wasDown = state.isRightMouseDown
    state.isRightMouseDown = IsMouseButtonDown("RightButton")
    if wasDown ~= state.isRightMouseDown then UpdateRender() end
end
UpdateMouseWatcher = function()
    local db = GetDB()
    local shouldRun = db.enabled and db.hideOnMouseClick
    if shouldRun and not mouseWatcherActive then
        mouseWatcher:SetScript("OnUpdate", MouseWatcherOnUpdate)
        mouseWatcherActive = true
    elseif not shouldRun and mouseWatcherActive then
        mouseWatcher:SetScript("OnUpdate", nil)
        state.isRightMouseDown = false
        mouseWatcherActive = false
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
events:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")

events:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        RefreshCombatState()
        state.isCasting = UnitCastingInfo("player") ~= nil
        state.isChanneling = UnitChannelInfo("player") ~= nil
        state.castStart = 0; state.castEnd = 0
        state.channelStart = 0; state.channelEnd = 0
        CreateRing()
        CreateTrail()
        UpdateRender()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        RefreshCombatState()
        UpdateRender()
    elseif event == "UNIT_SPELLCAST_START" then
        local _, _, _, startTime, endTime = UnitCastingInfo("player")
        if startTime and endTime then
            state.isCasting = true
            state.castStart = startTime / 1000
            state.castEnd = endTime / 1000
            state.castSwipeAllowed = false
            if state.castDelayTimer then state.castDelayTimer:Cancel() end
            state.castDelayTimer = C_Timer.NewTimer(SWIPE_DELAY, function()
                state.castSwipeAllowed = true
                state.castDelayTimer = nil
                UpdateRender()
            end)
        end
        UpdateRender()
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local _, _, _, startTime, endTime = UnitChannelInfo("player")
        if startTime and endTime then
            state.isChanneling = true
            state.channelStart = startTime / 1000
            state.channelEnd = endTime / 1000
            state.castSwipeAllowed = false
            if state.castDelayTimer then state.castDelayTimer:Cancel() end
            state.castDelayTimer = C_Timer.NewTimer(SWIPE_DELAY, function()
                state.castSwipeAllowed = true
                state.castDelayTimer = nil
                UpdateRender()
            end)
        end
        UpdateRender()
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        if state.isCasting then
            state.isCasting = false
            state.castStart = 0; state.castEnd = 0
            if state.castDelayTimer then state.castDelayTimer:Cancel(); state.castDelayTimer = nil end
            state.castSwipeAllowed = false
        end
        local _, _, _, startTime, endTime = UnitChannelInfo("player")
        if startTime and endTime then
            state.isChanneling = true
            state.channelStart = startTime / 1000
            state.channelEnd = endTime / 1000
        end
        UpdateRender()
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        state.isChanneling = false
        state.channelStart = 0; state.channelEnd = 0
        if state.castDelayTimer then state.castDelayTimer:Cancel(); state.castDelayTimer = nil end
        state.castSwipeAllowed = false
        UpdateRender()
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        local db = GetDB()
        if not db.gcdEnabled then return end
        local info = C_Spell.GetSpellCooldown(GCD_SPELL)
        if info and info.duration and info.duration > 0 then
            local wasReady = state.gcdReady
            state.gcdInfo = info
            state.gcdReady = false
            if wasReady then
                state.gcdSwipeAllowed = false
                if state.gcdDelayTimer then state.gcdDelayTimer:Cancel() end
                state.gcdDelayTimer = C_Timer.NewTimer(SWIPE_DELAY, function()
                    state.gcdSwipeAllowed = true
                    state.gcdDelayTimer = nil
                    UpdateRender()
                end)
            end
        else
            state.gcdReady = true
            state.gcdInfo = nil
            state.gcdSwipeAllowed = true
            if state.gcdDelayTimer then state.gcdDelayTimer:Cancel(); state.gcdDelayTimer = nil end
        end
        UpdateRender()
    end
end)

function MUI.MouseRingUpdateDisplay()
    CreateRing()
    CreateTrail()
    local db = GetDB()
    local shape = db.shape or "ring.tga"
    local size = db.size or 48
    if size % 2 == 1 then size = size + 1 end
    if container then container:SetSize(size, size) end
    if ring then
        SetupTexture(ring, shape)
        local r, g, b = GetRingColor()
        ring:SetVertexColor(r, g, b, 1)
    end
    if readyRing then SetupTexture(readyRing, shape) end
    if gcdCooldown then gcdCooldown:SetSwipeTexture(GetTexturePath(shape)) end
    UpdateRender()
end
