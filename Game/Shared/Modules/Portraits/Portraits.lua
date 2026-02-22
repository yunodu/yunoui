-- ElvUI-style unit portraits (ElvUI_mMediaTag media if present)
local MUI = unpack(yunoUI)

MUI.Portraits = MUI.Portraits or {}
local module = MUI.Portraits

local _G = _G
local SetPortraitTexture = SetPortraitTexture
local UnitExists = UnitExists
local tinsert = table.insert
local UF
local UnitGUID = UnitGUID
local select, strsplit = select, strsplit
local mathmax = math.max
local mathmin = math.min
local UnitIsDead = UnitIsDead

local P = "Interface\\AddOns\\yunoUI\\Media\\Portraits\\"
local rareStyles = {
    a = { texture = P .. "drop\\drop_rare1_txa.tga", border = P .. "drop\\drop_rare1_border.tga", shadow = P .. "drop\\drop_rare1_shadow.tga" },
    b = { texture = P .. "drop\\drop_rare2_txa.tga", border = P .. "drop\\drop_rare2_border.tga", shadow = P .. "drop\\drop_rare2_shadow.tga" },
    c = { texture = P .. "drop\\drop_rare3_txa.tga", border = P .. "drop\\drop_rare3_border.tga", shadow = P .. "drop\\drop_rare3_shadow.tga" },
    d = { texture = P .. "pure\\pure_rare1_txa.tga", border = P .. "pure\\pure_rare1_border.tga", shadow = P .. "pure\\pure_rare1_shadow.tga" },
    e = { texture = P .. "circle\\circle_rare4_txa.tga", border = P .. "circle\\circle_rare4_border.tga", shadow = P .. "circle\\circle_rare4_shadow.tga" },
}

local colors = {}
local isTrilinear = true

local bg_textures = {
    [1] = P .. "bg_1.tga",
    [2] = P .. "bg_2.tga",
    [3] = P .. "bg_3.tga",
    [4] = P .. "bg_4.tga",
    [5] = P .. "bg_5.tga",
    empty = P .. "empty.tga",
    unknown = P .. "unknown.tga",
}

-- boss IDs (portrait styling)
local BossIDs = {
    ["228713"] = true, ["214502"] = true, ["219853"] = true, ["214506"] = true,
    ["228470"] = true, ["223779"] = true, ["164517"] = true, ["164501"] = true,
    ["164804"] = true, ["164567"] = true, ["162693"] = true, ["163157"] = true,
}

local function GetTextures(style)
    local db = MUI.db.profile.portraits
    local gen = db and db.general
    style = (style and style ~= "") and style or (gen and gen.portraitStyle) or "drop"
    if not (style == "drop" or style == "square" or style == "pure" or style == "circle" or style == "dropsharp" or style == "octagon" or style == "pad" or style == "shield" or style == "thin" or style == "diamond" or style == "thincircle" or style == "thindiamond") then
        style = "drop"
    end
    local variant = (gen and gen.style) or "a"
    local v = variant == "b" and "b" or variant == "c" and "c" or "a"
    local extra = (db and db.extra) or {}
    local rareKey = (extra.rare == "b" or extra.rare == "c" or extra.rare == "d" or extra.rare == "e") and extra.rare or "a"
    local eliteKey = (extra.elite == "b" or extra.elite == "c" or extra.elite == "d" or extra.elite == "e") and extra.elite or "a"
    local bossKey = (extra.boss == "b" or extra.boss == "c" or extra.boss == "d" or extra.boss == "e") and extra.boss or "a"
    local texturePath, borderPath, shadowPath, innerPath, maskA, maskB, extraMask
    local corner = false
    if style == "drop" or style == "dropflip" then
        texturePath = P .. "drop\\drop_tx" .. v .. ".tga"
        borderPath = P .. "drop\\drop_border.tga"
        shadowPath = P .. "drop\\drop_shadow.tga"
        innerPath = P .. "drop\\drop_inner.tga"
        maskA = P .. "drop\\drop_mask_a.tga"
        maskB = P .. "drop\\drop_mask_c.tga"
        extraMask = true
        if style == "drop" and gen and gen.corner then
            corner = { texture = P .. "drop\\drop_corner_tx" .. v .. ".tga", border = P .. "drop\\drop_corner_border.tga" }
        end
    elseif style == "dropsharp" or style == "dropsharpflip" then
        texturePath = P .. "drop\\drop_sharp_tx" .. v .. ".tga"
        borderPath = P .. "drop\\drop_sharp_border.tga"
        shadowPath = P .. "drop\\drop_sharp_shadow.tga"
        innerPath = P .. "drop\\drop_inner.tga"
        maskA = P .. "drop\\drop_mask_a.tga"
        maskB = P .. "drop\\drop_mask_c.tga"
        extraMask = true
        if gen and gen.corner then
            corner = { texture = P .. "drop\\drop_corner_tx" .. v .. ".tga", border = P .. "drop\\drop_corner_border.tga" }
        end
    elseif style == "square" then
        texturePath = P .. "square\\square_tx" .. v .. ".tga"
        borderPath = P .. "square\\square_border.tga"
        shadowPath = P .. "square\\square_shadow.tga"
        innerPath = P .. "square\\square_inner.tga"
        maskA = P .. "square\\square_mask.tga"
        maskB = maskA
        extraMask = false
    elseif style == "pure" or style == "puresharp" then
        local pre = style == "puresharp" and "pure\\pure_sharp" or "pure\\pure"
        texturePath = P .. pre .. "_tx" .. v .. ".tga"
        borderPath = P .. (style == "puresharp" and "pure\\pure_sharp_border.tga" or "pure\\pure_border.tga")
        shadowPath = P .. (style == "puresharp" and "pure\\pure_sharp_shadow.tga" or "pure\\pure_shadow.tga")
        innerPath = P .. "pure\\pure_inner.tga"
        maskA = P .. "pure\\pure_mask_a.tga"
        maskB = P .. "pure\\pure_mask_b.tga"
        extraMask = true
    elseif style == "circle" or style == "thincircle" then
        local pre = style == "thincircle" and "thin_circle" or "circle"
        texturePath = P .. pre .. "\\" .. pre .. "_tx" .. v .. ".tga"
        borderPath = P .. pre .. "\\" .. pre .. "_border.tga"
        shadowPath = P .. pre .. "\\" .. pre .. "_shadow.tga"
        innerPath = P .. pre .. "\\" .. pre .. "_inner.tga"
        maskA = P .. pre .. "\\" .. pre .. "_mask.tga"
        maskB = maskA
        extraMask = false
    elseif style == "diamond" or style == "thindiamond" then
        local pre = style == "thindiamond" and "thin_diamond" or "diamond"
        texturePath = P .. pre .. "\\" .. pre .. "_tx" .. v .. ".tga"
        borderPath = P .. pre .. "\\" .. pre .. "_border.tga"
        shadowPath = P .. pre .. "\\" .. pre .. "_shadow.tga"
        innerPath = P .. pre .. "\\" .. pre .. "_inner.tga"
        maskA = P .. pre .. "\\" .. pre .. "_mask.tga"
        maskB = maskA
        extraMask = false
    elseif style == "octagon" or style == "pad" or style == "shield" or style == "thin" then
        texturePath = P .. style .. "\\" .. style .. "_tx" .. v .. ".tga"
        borderPath = P .. style .. "\\" .. style .. "_border.tga"
        shadowPath = P .. style .. "\\" .. style .. "_shadow.tga"
        innerPath = P .. style .. "\\" .. style .. "_inner.tga"
        maskA = P .. style .. "\\" .. style .. "_mask.tga"
        maskB = maskA
        extraMask = false
    else
        texturePath = P .. "drop\\drop_tx" .. v .. ".tga"
        borderPath = P .. "drop\\drop_border.tga"
        shadowPath = P .. "drop\\drop_shadow.tga"
        innerPath = P .. "drop\\drop_inner.tga"
        maskA = P .. "drop\\drop_mask_a.tga"
        maskB = P .. "drop\\drop_mask_c.tga"
        extraMask = true
        if gen and gen.corner then
            corner = { texture = P .. "drop\\drop_corner_tx" .. v .. ".tga", border = P .. "drop\\drop_corner_border.tga" }
        end
    end
    return {
        texture = texturePath,
        border = borderPath,
        shadow = shadowPath,
        inner = innerPath,
        extraMask = extraMask,
        mask = { a = maskA, b = maskB },
        rare = rareStyles[rareKey] or rareStyles.a,
        elite = rareStyles[eliteKey] or rareStyles.a,
        boss = rareStyles[bossKey] or rareStyles.a,
        corner = corner,
    }
end

local function SetTex(frame, texture)
    if isTrilinear then
        frame:SetTexture(texture, "CLAMP", "CLAMP", "TRILINEAR")
    else
        frame:SetTexture(texture)
    end
end

local function mirrorTexture(texture, mirror, top)
    if texture.classIcons and texture.classCoords then
        local coords = texture.classCoords
        local a, b, c, d = coords[1], coords[2], coords[3], coords[4]
        if a and b and c and d then
            if mirror then a, b = b, a end
            texture:SetTexCoord(a, b, c, d)
        end
    else
        texture:SetTexCoord(mirror and 1 or 0, mirror and 0 or 1, top and 1 or 0, top and 0 or 1)
    end
end

local function setColor(texture, color, mirror)
    if not texture or not color then return end
    local db = MUI.db.profile.portraits
    local gen = db and db.general
    if type(color.a) == "table" and type(color.b) == "table" then
        if gen and gen.gradient then
            local a, b = color.a, color.b
            if mirror and gen.ori == "HORIZONTAL" then a, b = b, a end
            texture:SetGradient(gen.ori or "VERTICAL", a, b)
        else
            texture:SetVertexColor(color.a.r, color.a.g, color.a.b, color.a.a)
        end
    elseif color.r and color.g and color.b and color.a then
        texture:SetVertexColor(color.r, color.g, color.b, color.a)
    end
end

local cachedFaction = {}

local function getColor(unit, isPlayer, isDead)
    local defaultColor = colors.default or { r = 0.2, g = 0.2, b = 0.2, a = 1 }
    if isPlayer == nil then isPlayer = UnitIsPlayer(unit) end
    local db = MUI.db.profile.portraits
    local gen = db and db.general
    if gen and gen.deathcolor and isDead then return colors.death or defaultColor end
    if gen and gen.default then return defaultColor end
    if isPlayer or (module.E and module.E.Retail and UnitInPartyIsAI and UnitInPartyIsAI(unit)) then
        if gen and gen.reaction then
            local playerFaction = cachedFaction.player or select(1, UnitFactionGroup("player"))
            cachedFaction.player = playerFaction
            local unitFaction = cachedFaction[UnitGUID(unit)] or select(1, UnitFactionGroup(unit))
            cachedFaction[UnitGUID(unit)] = unitFaction
            return colors[(playerFaction == unitFaction) and "friendly" or "enemy"] or defaultColor
        else
            local _, class = UnitClass(unit)
            return colors[class] or defaultColor
        end
    else
        local reaction = UnitReaction(unit, "player")
        return colors[reaction and ((reaction <= 3) and "enemy" or (reaction == 4) and "neutral" or "friendly") or "enemy"] or defaultColor
    end
end

local function adjustColor(color, shift)
    return { r = color.r * shift, g = color.g * shift, b = color.b * shift, a = color.a }
end

local function UpdateIconBackground(tx, unit, mirror)
    local db = MUI.db.profile.portraits
    if not db then return end
    local shadow = db.shadow
    local gen = db.general
    local bgstyle = gen and gen.bgstyle or 1
    SetTex(tx, bg_textures[bgstyle] or bg_textures[1])
    local color = shadow and shadow.background or (shadow and shadow.classBG and getColor(unit))
    if color then
        local bgColor = adjustColor(type(color.a) == "table" and color.a or color, (shadow and shadow.bgColorShift) or 0.5)
        if bgColor then setColor(tx, bgColor, mirror) end
    end
end

local function DeadDesaturation(self)
    if self.unit_is_dead then
        self.portrait:SetDesaturated(true)
        self.isDesaturated = true
    elseif self.isDesaturated then
        self.portrait:SetDesaturated(false)
        self.isDesaturated = false
    end
end

local function SetPortraits(frame, unit, masking, mirror)
    local db = MUI.db.profile.portraits
    local gen = db and db.general
    if gen and gen.classicons and (UnitIsPlayer(unit) or (module.E and module.E.Retail and UnitInPartyIsAI and UnitInPartyIsAI(unit))) then
        local _, class = UnitClass(unit)
        if class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class] then
            local coords = CLASS_ICON_TCOORDS[class]
            local L = coords.left or coords[1]
            local R = coords.right or coords[2]
            local T = coords.top or coords[3]
            local B = coords.bottom or coords[4]
            if L and R and T and B then
                frame.portrait:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
                frame.portrait.classIcons = true
                frame.portrait.classCoords = { L, R, T, B }
                frame.portrait:SetTexCoord(L, R, T, B)
            else
                if frame.portrait.classIcons then frame.portrait.classIcons = nil; frame.portrait.classCoords = nil end
                SetPortraitTexture(frame.portrait, unit, true)
            end
        else
            if frame.portrait.classIcons then frame.portrait.classIcons = nil; frame.portrait.classCoords = nil end
            SetPortraitTexture(frame.portrait, unit, true)
        end
    else
        if frame.portrait.classIcons then frame.portrait.classIcons = nil; frame.portrait.classCoords = nil end
        SetPortraitTexture(frame.portrait, unit, true)
    end
    if frame.iconbg then UpdateIconBackground(frame.iconbg, unit, mirror) end
    if gen and gen.desaturation then DeadDesaturation(frame) end
    mirrorTexture(frame.portrait, mirror)
end

local function GetOffset(size)
    local db = MUI.db.profile.portraits
    local offset = db and db.general and db.general.zoom or 0
    if offset == 0 or not offset then return 0 end
    local maxOffset = size / 2
    local zoom = (1 - offset) * size / 2
    zoom = mathmax(-maxOffset, mathmin(zoom, maxOffset))
    return zoom
end

local function UpdateTexture(portraitFrame, textureType, texture, level, color, reverse)
    if not portraitFrame[textureType] then
        portraitFrame[textureType] = portraitFrame:CreateTexture("yunoUI_Portrait_" .. textureType .. "-" .. (portraitFrame.name or "UF"), "OVERLAY", nil, level)
        portraitFrame[textureType]:SetAllPoints(portraitFrame)
    end
    local mirror = portraitFrame.settings.mirror
    SetTex(portraitFrame[textureType], texture)
    if reverse ~= nil then mirror = reverse end
    mirrorTexture(portraitFrame[textureType], mirror, portraitFrame.textures and portraitFrame.textures.flip)
    if color then setColor(portraitFrame[textureType], color, mirror) end
end

local function GetNPCID(unit)
    local guid = UnitGUID(unit)
    return guid and select(6, strsplit("-", guid))
end

local simpleClassification = { worldboss = "boss", rareelite = "rareelite", elite = "elite", rare = "rare" }

local function HideRareElite(frame)
    local db = MUI.db.profile.portraits
    if db and db.shadow and db.shadow.enable and frame.extraShadow then frame.extraShadow:Hide() end
    if db and db.shadow and db.shadow.border and frame.extraBorder then frame.extraBorder:Hide() end
    if frame.extra then frame.extra:Hide() end
end

local function UpdateExtraTexture(portraitFrame, classification)
    classification = (classification == "rareelite") and "rare" or classification
    local tex = portraitFrame.textures and portraitFrame.textures[classification]
    if tex and tex.texture and portraitFrame.extra then
        SetTex(portraitFrame.extra, tex.texture)
    end
end

local function CheckRareElite(frame, unit, unitColor)
    local c = UnitClassification(unit)
    local npcID = GetNPCID(unit)
    local classification = (BossIDs[npcID] and "boss" or simpleClassification[c])
    local db = MUI.db.profile.portraits
    if classification then
        local borderColors = (db and db.colors and db.colors.border) or {}
        local color = borderColors[classification] or borderColors.default or colors.border and colors.border.default
        UpdateExtraTexture(frame, classification)
        if color then setColor(frame.extra, color) end
        if db and db.shadow and db.shadow.enable and frame.extraShadow then frame.extraShadow:Show() end
        if db and db.shadow and db.shadow.border and frame.extraBorder then
            setColor(frame.extraBorder, borderColors[classification] or borderColors.default)
            frame.extraBorder:Show()
        end
        frame.extra:Show()
    else
        HideRareElite(frame)
    end
end

local function UpdatePortrait(portraitFrame, force)
    local gen = MUI.db.profile.portraits and MUI.db.profile.portraits.general
    portraitFrame.textures = GetTextures((gen and gen.portraitStyle) or (portraitFrame.settings and portraitFrame.settings.texture) or nil)
    portraitFrame.unit = portraitFrame.parent.unit

    local setting = portraitFrame.settings
    local unit = force and "player" or (UnitExists(portraitFrame.unit) and portraitFrame.unit or (portraitFrame.parent.unit or "player"))
    local parent = portraitFrame.parent
    local unitColor = getColor(unit)

    if not InCombatLockdown() and setting and setting.point then
        portraitFrame:SetSize(setting.size, setting.size)
        portraitFrame:ClearAllPoints()
        portraitFrame:SetPoint(setting.point, parent, setting.relativePoint, setting.x, setting.y)
        if setting.strata and setting.strata ~= "AUTO" then portraitFrame:SetFrameStrata(setting.strata) end
        portraitFrame:SetFrameLevel(setting.level or 10)
    end

    local texture = portraitFrame.textures.texture
    UpdateTexture(portraitFrame, "texture", texture, 4, unitColor)
    local offset = GetOffset(setting.size)
    UpdateTexture(portraitFrame, "portrait", bg_textures.unknown, 1)
    SetPortraits(portraitFrame, unit, false, setting.mirror)
    portraitFrame.portrait:SetPoint("TOPLEFT", 0 + offset, 0 - offset)
    portraitFrame.portrait:SetPoint("BOTTOMRIGHT", 0 - offset, 0 + offset)

    local maskTex = setting.mirror and portraitFrame.textures.mask.b or portraitFrame.textures.mask.a
    if not portraitFrame.mask then
        portraitFrame.mask = portraitFrame:CreateMaskTexture()
        portraitFrame.mask:SetAllPoints(portraitFrame)
        portraitFrame.portrait:AddMaskTexture(portraitFrame.mask)
    end
    portraitFrame.mask:SetTexture(maskTex, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")

    local db = MUI.db.profile.portraits
    local bgstyle = (db and db.general and db.general.bgstyle) or 1
    UpdateTexture(portraitFrame, "iconbg", bg_textures[bgstyle], -5)
    portraitFrame.iconbg:AddMaskTexture(portraitFrame.mask)

    if db and db.shadow and db.shadow.enable then
        UpdateTexture(portraitFrame, "shadow", portraitFrame.textures.shadow, -4, db.shadow.color)
        portraitFrame.shadow:Show()
    elseif portraitFrame.shadow then portraitFrame.shadow:Hide() end

    if db and db.shadow and db.shadow.border then
        UpdateTexture(portraitFrame, "border", portraitFrame.textures.border, 2, colors.border and colors.border.default)
    end

    if setting.extraEnable then
        UpdateTexture(portraitFrame, "extra", portraitFrame.textures.rare.texture, -6, colors.border and colors.border.default, not setting.mirror)
        if db and db.shadow and db.shadow.border then
            UpdateTexture(portraitFrame, "extraBorder", portraitFrame.textures.rare.border, -7, colors.border and colors.border.default, not setting.mirror)
            if portraitFrame.extraBorder then portraitFrame.extraBorder:Hide() end
        end
        if db and db.shadow and db.shadow.enable then
            UpdateTexture(portraitFrame, "extraShadow", portraitFrame.textures.rare.shadow, -8, db.shadow.color, not setting.mirror)
            if portraitFrame.extraShadow then portraitFrame.extraShadow:Hide() end
        end
        CheckRareElite(portraitFrame, unit, unitColor)
    end

    portraitFrame:Show()
end

local function SetScripts(portrait)
    if portrait.isBuild then return end
    if portrait.isPartyFrame then
        local partyEvents = { "GROUP_ROSTER_UPDATE", "PARTY_MEMBER_ENABLE", "UNIT_MODEL_CHANGED", "UNIT_PORTRAIT_UPDATE", "UNIT_CONNECTION" }
        for _, event in ipairs(partyEvents) do
            portrait:RegisterEvent(event)
            tinsert(portrait.allEvents, event)
        end
    else
        local unitEvents = { "UNIT_MODEL_CHANGED", "UNIT_PORTRAIT_UPDATE", "UNIT_CONNECTION" }
        for _, event in ipairs(unitEvents) do
            portrait:RegisterUnitEvent(event, portrait.unit)
            tinsert(portrait.allEvents, event)
        end
        local db = MUI.db.profile.portraits
        if db and db.general and db.general.desaturation then
            portrait:RegisterUnitEvent("UNIT_HEALTH", portrait.unit)
            tinsert(portrait.allEvents, "UNIT_HEALTH")
        end
        if portrait.unit == "player" then
            portrait:RegisterEvent("VEHICLE_UPDATE")
            tinsert(portrait.allEvents, "VEHICLE_UPDATE")
            portrait:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", portrait.unit)
            portrait:RegisterUnitEvent("UNIT_EXITED_VEHICLE", portrait.unit)
            tinsert(portrait.allEvents, "UNIT_ENTERED_VEHICLE")
            tinsert(portrait.allEvents, "UNIT_EXITED_VEHICLE")
        end
        if portrait.unit == "pet" then
            portrait:RegisterEvent("VEHICLE_UPDATE")
            tinsert(portrait.allEvents, "VEHICLE_UPDATE")
        end
        if portrait.events then
            for _, event in pairs(portrait.events) do portrait:RegisterUnitEvent(event); tinsert(portrait.allEvents, event) end
        end
        if portrait.unitEvents then
            for _, event in pairs(portrait.unitEvents) do
                portrait:RegisterUnitEvent(event, event == "UNIT_TARGET" and "target" or portrait.unit)
                tinsert(portrait.allEvents, event)
            end
        end
    end
    portrait:RegisterEvent("PLAYER_ENTERING_WORLD")
    tinsert(portrait.allEvents, "PLAYER_ENTERING_WORLD")
    portrait:RegisterEvent("PORTRAITS_UPDATED")
    tinsert(portrait.allEvents, "PORTRAITS_UPDATED")
    portrait:SetAttribute("unit", portrait.unit)
    portrait:SetAttribute("*type1", "target")
    portrait:SetAttribute("*type2", "togglemenu")
    portrait:SetAttribute("type3", "focus")
    portrait:SetAttribute("toggleForVehicle", true)
    portrait:RegisterForClicks("AnyUp")
    portrait.isBuild = true
end

local function UpdateAllPortraits(force)
    local units = { "Player", "Target", "Pet", "Focus", "TargetTarget",
        "Party1", "Party2", "Party3", "Party4", "Party5",
        "Arena1", "Arena2", "Arena3", "Arena4", "Arena5",
        "Boss1", "Boss2", "Boss3", "Boss4", "Boss5", "Boss6", "Boss7", "Boss8" }
    for _, name in ipairs(units) do
        if module[name] then
            UpdatePortrait(module[name])
            if force then SetScripts(module[name]) end
        end
    end
end

local function RemovePortrait(unitPortrait)
    if unitPortrait and unitPortrait.allEvents then
        for _, event in pairs(unitPortrait.allEvents) do unitPortrait:UnregisterEvent(event) end
    end
    if unitPortrait then unitPortrait:Hide() end
end

local function UpdatePortraitTexture(self, unit)
    if not InCombatLockdown() and self:GetAttribute("unit") ~= unit then self:SetAttribute("unit", unit) end
    local unitColor = getColor(unit, UnitIsPlayer(unit), self.unit_is_dead)
    SetPortraits(self, unit, false, self.settings.mirror)
    setColor(self.texture, unitColor, self.settings.mirror)
    if self.settings.extraEnable and self.extra and not UnitIsPlayer(unit) then
        CheckRareElite(self, unit, unitColor)
    elseif self.extra then
        HideRareElite(self)
    end
end

local castStarted = { UNIT_SPELLCAST_START = true, UNIT_SPELLCAST_CHANNEL_START = true, UNIT_SPELLCAST_EMPOWER_START = true }
local castStopped = { UNIT_SPELLCAST_INTERRUPTED = true, UNIT_SPELLCAST_STOP = true, UNIT_SPELLCAST_CHANNEL_STOP = true, UNIT_SPELLCAST_EMPOWER_STOP = true }

local function CastIcon(self)
    return select(3, UnitCastingInfo(self.unit)) or select(3, UnitChannelInfo(self.unit))
end

local function AddCastIcon(self)
    local tex = CastIcon(self)
    if tex then
        self.portrait:SetTexture(tex)
        if self.portrait.classIcons then self.portrait.classIcons = nil; self.portrait.classCoords = nil end
        mirrorTexture(self.portrait, self.settings.mirror)
    end
end

local function UnitEvent(self, event)
    local unit = self.unit
    local db = MUI.db.profile.portraits
    if db and db.general then
        if db.general.desaturation or db.general.deathcolor then self.unit_is_dead = UnitIsDead(unit) end
    end
    if castStopped[event] or (self.isCasting and not CastIcon(self)) then
        self.isCasting = false
        UpdatePortraitTexture(self, unit)
    elseif self.isCasting or castStarted[event] then
        if (self.settings.cast or self.isCasting) then
            self.isCasting = true
            AddCastIcon(self)
        end
    else
        UpdatePortraitTexture(self, unit)
    end
end

local function shouldHandleEvent(event, eventUnit, self)
    return (event == "UNIT_TARGET" and (eventUnit == "player" or eventUnit == "target" or eventUnit == "targettarget"))
        or (event == "PLAYER_TARGET_CHANGED" and (self.unit == "target" or self.unit == "targettarget"))
        or (event == "PLAYER_FOCUS_CHANGED" and self.parent.unit == "focus")
        or eventUnit == self.unit
end

local forceUpdateParty = { UNIT_CONNECTION = true, GROUP_ROSTER_UPDATE = true, PARTY_MEMBER_ENABLE = true, PORTRAITS_UPDATED = true }

local function PartyUnitOnEvent(self, event, eventUnit)
    if not UnitExists(self.parent.unit) then return end
    if event == "UNIT_HEALTH" and eventUnit == self.unit then DeadDesaturation(self) end
    self.unit = self.parent.unit
    local db = MUI.db.profile.portraits
    if db and db.general and db.general.desaturation and not self.eventDesaturationIsSet then
        self:RegisterUnitEvent("UNIT_HEALTH", self.unit)
        tinsert(self.allEvents, "UNIT_HEALTH")
        self.eventDesaturationIsSet = true
    end
    if event == "GROUP_ROSTER_UPDATE" then
        for i = 1, 5 do
            module["Party" .. i].unit = module["Party" .. i].parent.unit
            UnitEvent(module["Party" .. i], event)
        end
    elseif eventUnit == self.unit or forceUpdateParty[event] then
        UnitEvent(self, event)
    end
end

local function BossUnitOnEvent(self, event, eventUnit)
    if not UnitExists(self.parent.unit) then return end
    if event == "UNIT_HEALTH" and eventUnit == self.unit then DeadDesaturation(self) end
    if eventUnit == self.unit or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" or event == "PORTRAITS_UPDATED" then UnitEvent(self, event) end
end

local function PlayerPetUnitOnEvent(self, event, eventUnit)
    if not UnitExists(self.parent.unit) then return end
    if event == "UNIT_HEALTH" and eventUnit == self.unit then DeadDesaturation(self) end
    if eventUnit == "vehicle" or (_G.ElvUF_Player and _G.ElvUF_Player.unit == "vehicle") then
        self.unit = (self.parent.realUnit == "player") and "pet" or "player"
    else
        self.unit = self.parent.unit
    end
    if eventUnit == self.unit or (_G.ElvUF_Player and _G.ElvUF_Player.unit == "vehicle") or event == "UNIT_EXITED_VEHICLE" or event == "UNIT_ENTERED_VEHICLE" or event == "VEHICLE_UPDATE" then
        UnitEvent(self, event)
    end
end

local function OtherUnitOnEvent(self, event, eventUnit)
    if not UnitExists(self.unit) then return end
    if event == "UNIT_HEALTH" and eventUnit == self.unit then DeadDesaturation(self) end
    if shouldHandleEvent(event, eventUnit, self) then UnitEvent(self, event) end
end

local function CreatePortraits(name, unit, parentFrame, unitSettings, events, unitEvents)
    local partyFrames = { Party1 = true, Party2 = true, Party3 = true, Party4 = true, Party5 = true }
    local bossFrames = { Boss1 = true, Boss2 = true, Boss3 = true, Boss4 = true, Boss5 = true, Boss6 = true, Boss7 = true, Boss8 = true }
    if not module[name] then
        module[name] = CreateFrame("Button", "yunoUI_Portrait_" .. name, parentFrame, "SecureUnitButtonTemplate")
        module[name].parent = parentFrame
        module[name].unit = unit
        module[name].isPartyFrame = partyFrames[name]
        module[name].isBossFrame = bossFrames[name]
        module[name].events = events
        module[name].unitEvents = unitEvents
        module[name].allEvents = {}
        module[name].name = name
    end
    module[name].settings = unitSettings
    local gen = MUI.db.profile.portraits and MUI.db.profile.portraits.general
    module[name].textures = GetTextures((gen and gen.portraitStyle) or unitSettings.texture or nil)
    if not module[name].scriptsSet then
        if module[name].isPartyFrame then
            module[name]:SetScript("OnEvent", PartyUnitOnEvent)
        elseif module[name].isBossFrame then
            module[name]:SetScript("OnEvent", BossUnitOnEvent)
        elseif name == "Player" or name == "Pet" then
            module[name]:SetScript("OnEvent", PlayerPetUnitOnEvent)
        else
            module[name]:SetScript("OnEvent", OtherUnitOnEvent)
        end
        SetScripts(module[name])
        module[name].scriptsSet = true
    end
    UpdatePortrait(module[name])
end

local function ToggleForceShowGroupFrames(_, group, numGroup)
    if group == "boss" or group == "arena" then
        local name = (group == "boss") and "Boss" or "Arena"
        for i = 1, numGroup do
            if module[name .. i] then UpdatePortrait(module[name .. i], true) end
        end
    end
end

local function HeaderConfig(_, header)
    if header.groups and header.groupName == "party" then
        for i = 1, #header.groups[1] do
            if module["Party" .. i] then UpdatePortrait(module["Party" .. i], true) end
        end
    end
end

function module:Initialize(force)
    if not ElvUI then return end
    module.E = unpack(ElvUI)
    UF = UF or module.E:GetModule("UnitFrames")
    local db = MUI.db.profile.portraits
    if not db then return end
    isTrilinear = (db.general and db.general.trilinear) ~= false
    colors = db.colors or {}
    colors.border = db.colors and db.colors.border
    if not colors.default then colors.default = { r = 0.2, g = 0.2, b = 0.2, a = 1 } end
    for class, c in pairs(RAID_CLASS_COLORS or {}) do
        colors[class] = colors[class] or { r = c.r, g = c.g, b = c.b, a = 1 }
    end

    if db.general and db.general.enable then
        if _G.ElvUF_Player and db.player and db.player.enable then
            CreatePortraits("Player", "player", _G.ElvUF_Player, db.player)
        elseif module.Player then RemovePortrait(module.Player) end

        if _G.ElvUF_Target and db.target and db.target.enable then
            CreatePortraits("Target", "target", _G.ElvUF_Target, db.target, { "PLAYER_TARGET_CHANGED" })
        elseif module.Target then RemovePortrait(module.Target) end

        if _G.ElvUF_Pet and db.pet and db.pet.enable then
            CreatePortraits("Pet", "pet", _G.ElvUF_Pet, db.pet)
        elseif module.Pet then RemovePortrait(module.Pet) end

        if _G.ElvUF_TargetTarget and db.targettarget and db.targettarget.enable then
            CreatePortraits("TargetTarget", "targettarget", _G.ElvUF_TargetTarget, db.targettarget, { "PLAYER_TARGET_CHANGED" }, { "UNIT_TARGET" })
        elseif module.TargetTarget then RemovePortrait(module.TargetTarget) end

        if _G.ElvUF_Focus and db.focus and db.focus.enable then
            CreatePortraits("Focus", "focus", _G.ElvUF_Focus, db.focus, { "PLAYER_FOCUS_CHANGED" })
        elseif module.Focus then RemovePortrait(module.Focus) end

        if db.party and db.party.enable then
            for i = 1, 5 do
                local frame = _G["ElvUF_PartyGroup1UnitButton" .. i]
                if frame then
                    CreatePortraits("Party" .. i, frame.unit, frame, db.party)
                elseif module["Party" .. i] then
                    RemovePortrait(module["Party" .. i])
                end
            end
        elseif module.Party1 then
            for i = 1, 5 do RemovePortrait(module["Party" .. i]) end
        end

        if db.boss and db.boss.enable then
            for i = 1, 8 do
                local frame = _G["ElvUF_Boss" .. i]
                if frame then
                    CreatePortraits("Boss" .. i, frame.unit, frame, db.boss, { "INSTANCE_ENCOUNTER_ENGAGE_UNIT", "UNIT_TARGETABLE_CHANGED" })
                elseif module["Boss" .. i] then
                    RemovePortrait(module["Boss" .. i])
                end
            end
        elseif module.Boss1 then
            for i = 1, 8 do RemovePortrait(module["Boss" .. i]) end
        end

        if db.arena and db.arena.enable then
            for i = 1, 5 do
                local frame = _G["ElvUF_Arena" .. i]
                if frame then
                    CreatePortraits("Arena" .. i, frame.unit, frame, db.arena, { "ARENA_OPPONENT_UPDATE" }, { "UNIT_NAME_UPDATE" })
                elseif module["Arena" .. i] then
                    RemovePortrait(module["Arena" .. i])
                end
            end
        elseif module.Arena1 then
            for i = 1, 5 do RemovePortrait(module["Arena" .. i]) end
        end

        UpdateAllPortraits(force)
        if not module.needReloadUI then
            hooksecurefunc(UF, "ToggleForceShowGroupFrames", ToggleForceShowGroupFrames)
            hooksecurefunc(UF, "HeaderConfig", HeaderConfig)
            module.needReloadUI = true
        end
    else
        for key, unitPortrait in pairs(module) do
            if type(unitPortrait) == "table" and unitPortrait.portrait then RemovePortrait(unitPortrait) end
        end
    end
    module.loaded = db.general and db.general.enable
end
