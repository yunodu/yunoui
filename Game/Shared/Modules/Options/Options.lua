-- AceGUI if available else fallback panel
local MUI = unpack(yunoUI)

local AG = LibStub("AceGUI-3.0", true)

local function ApplyDefaults()
    local p = MUI.db.profile
    if p.cooldowns then p.cooldowns.powerBarOffset = 2 end
    if p.portraits then
        local g = p.portraits.general
        if g then
            g.enable = true
            g.portraitStyle = "drop"
            g.classicons = false
            g.desaturation = true
            g.deathcolor = true
            g.style = "a"
            g.gradient = false
            g.ori = "HORIZONTAL"
            g.trilinear = true
            g.corner = true
            g.bgstyle = 1
            g.zoom = 0
            g.default = false
            g.reaction = false
            g.usetexturecolor = false
        end
        p.portraits.shadow = p.portraits.shadow or {}
        p.portraits.shadow.enable = true
        p.portraits.shadow.border = false
        p.portraits.shadow.inner = false
        if p.portraits.extra then
            p.portraits.extra.rare = "a"
            p.portraits.extra.elite = "a"
            p.portraits.extra.boss = "a"
        end
        local u = p.portraits.player
        if u then
            u.enable = true
            u.size = 70
            u.point = "RIGHT"
            u.relativePoint = "LEFT"
            u.x = 14
            u.y = 2
            u.mirror = false
            u.cast = false
            u.extraEnable = false
            u.strata = "AUTO"
            u.level = 10
        end
        u = p.portraits.target
        if u then
            u.enable = true
            u.size = 70
            u.point = "LEFT"
            u.relativePoint = "RIGHT"
            u.x = -14
            u.y = 2
            u.mirror = true
            u.cast = false
            u.extraEnable = false
            u.strata = "AUTO"
            u.level = 10
        end
        for _, key in ipairs({ "pet", "focus", "targettarget", "party", "boss", "arena" }) do
            u = p.portraits[key]
            if u then
                u.enable = false
                u.size = 70
                u.cast = false
                u.extraEnable = false
                u.strata = "AUTO"
                u.level = 10
            end
        end
    end
    if MUI.BCM and MUI.BCM.UpdatePowerBar then MUI.BCM:UpdatePowerBar() end
    if MUI.Portraits and MUI.Portraits.Initialize then MUI.Portraits:Initialize() end
end

local function PortraitRefresh()
    if MUI.Portraits and MUI.Portraits.Initialize then MUI.Portraits:Initialize() end
end

local function pt(key) -- ensure portraits db path exists
    local p = MUI.db.profile.portraits
    if not p then MUI.db.profile.portraits = {} end
    if key and not MUI.db.profile.portraits[key] then MUI.db.profile.portraits[key] = {} end
    return key and MUI.db.profile.portraits[key] or MUI.db.profile.portraits
end

local function ptGen()
    if not pt().general then pt().general = {} end
    return pt().general
end

local function OpenAceGUIOptions()
    if not AG then return false end
    local frame = AG:Create("Frame")
    frame:SetTitle("yunoUI")
    frame:SetLayout("Flow")
    frame:SetWidth(460)
    frame:SetHeight(520)
    frame:EnableResize(false)
    frame:SetCallback("OnClose", function(widget)
        local ok, err = pcall(AG.Release, AG, widget)
        if not ok and err and not string.match(tostring(err), "already released") then
            geterrorhandler()(err)
        end
    end)

    local cd = MUI.db.profile.cooldowns or {}
    local db = MUI.db.profile.portraits or {}
    local gen = db.general or {}
    local sh = db.shadow or {}
    local ex = db.extra or {}

    local unitIds = { player = true, target = true, pet = true, focus = true, targettarget = true, party = true, boss = true, arena = true }
    local function addCheck(parent, label, key, subkey, unitKey)
        local g, k
        if unitKey and unitIds[unitKey] then
            g = pt(unitKey)
            k = key
        else
            if key == "shadow" then
                g = (MUI.db.profile.portraits or {}).shadow or {}
            else
                g = subkey and gen or (key == "shadow" and sh or ex) or ex
            end
            k = subkey or key
        end
        local c = AG:Create("CheckBox")
        c:SetLabel(label)
        local val
        if key == "shadow" then
            val = (k == "inner") and (g.inner == true) or (k ~= "inner" and (g[k] ~= false))
        else
            val = (g[k] ~= false and (k ~= "enable" or g[k] ~= nil)) or (k == "enable" and g[k] == true)
        end
        c:SetValue(val)
        if unitKey and unitIds[unitKey] then
            c:SetCallback("OnValueChanged", function(_, _, v) pt(unitKey)[k] = v; PortraitRefresh() end)
        elseif key == "general" or (subkey and key ~= "shadow") then
            c:SetCallback("OnValueChanged", function(_, _, v) ptGen()[k] = v; PortraitRefresh() end)
        elseif key == "shadow" then
            c:SetCallback("OnValueChanged", function(_, _, v)
                local s = pt().shadow
                if not s then s = {}; pt().shadow = s end
                if s.enable == nil then s.enable = true end
                if s.border == nil then s.border = true end
                if s.inner == nil then s.inner = false end
                s[k] = v
                PortraitRefresh()
            end)
        else
            c:SetCallback("OnValueChanged", function(_, _, v) pt().extra = pt().extra or {}; pt().extra[k] = v; PortraitRefresh() end)
        end
        parent:AddChild(c)
        return c
    end

    local function addSlider(parent, label, key, minV, maxV, step, unitKey)
        unitKey = unitKey or "general"
        local getT = (unitKey == "general" and function() return gen[key] end) or (function() return (pt(unitKey) or {})[key] end)
        local setT = (unitKey == "general" and function(v) ptGen()[key] = v end) or (function(v) local u = pt(unitKey); u[key] = v; PortraitRefresh() end)
        local s = AG:Create("Slider")
        s:SetLabel(label)
        s:SetValue(getT() or (minV + maxV) / 2)
        s:SetSliderValues(minV, maxV, step)
        s:SetFullWidth(true)
        s:SetCallback("OnValueChanged", function(_, _, v) setT(v); if unitKey ~= "general" then PortraitRefresh() end end)
        parent:AddChild(s)
        return s
    end

    local function addDropdown(parent, label, key, list, unitKey, defaultVal)
        unitKey = unitKey or "general"
        local getT = (unitKey == "general" and function() return gen[key] end) or (function()
            local u = pt(unitKey) or {}
            if key == "relativePoint" then
                local p = u.point or u.relativePoint
                if p == "RIGHT" then return "LEFT" end   -- portrait on left
                if p == "LEFT" then return "RIGHT" end   -- portrait on right
                return p or "LEFT"
            end
            return u[key]
        end)
        local setT = (unitKey == "general" and function(v) ptGen()[key] = v end) or (function(v)
            local u = pt(unitKey)
            if key == "relativePoint" then
                -- UI Left/Right map to our RIGHT/LEFT and LEFT/RIGHT
                if v == "LEFT" then u.point, u.relativePoint = "RIGHT", "LEFT"
                elseif v == "RIGHT" then u.point, u.relativePoint = "LEFT", "RIGHT"
                else u.point, u.relativePoint = "CENTER", "CENTER"
                end
            else
                u[key] = v
            end
            PortraitRefresh()
        end)
        local d = AG:Create("Dropdown")
        d:SetLabel(label)
        d:SetList(list)
        d:SetValue(getT() or defaultVal or "a")
        d:SetCallback("OnValueChanged", function(_, _, v) setT(v); PortraitRefresh() end)
        parent:AddChild(d)
        return d
    end

    local function buildPortraitScroll()
        local scroll = AG:Create("ScrollFrame")
        scroll:SetFullWidth(true)
        scroll:SetLayout("List")
        scroll.frame:SetHeight(380)
        local ptRoot = AG:Create("InlineGroup")
        ptRoot:SetTitle("Portraits (ElvUI unit frames)")
        ptRoot:SetFullWidth(true)
        ptRoot:SetLayout("Flow")
        addCheck(ptRoot, "Enable", "general", "enable")
        scroll:AddChild(ptRoot)
        local gGroup = AG:Create("InlineGroup")
        gGroup:SetTitle("General")
        gGroup:SetFullWidth(true)
        gGroup:SetLayout("Flow")
    addDropdown(gGroup, "Portrait style", "portraitStyle", {
        drop = "Drop",
        dropsharp = "Drop (sharp)",
        square = "Square",
        pure = "Pure",
        puresharp = "Pure (sharp)",
        circle = "Circle",
        thincircle = "Thin circle",
        diamond = "Diamond",
        thindiamond = "Thin diamond",
        octagon = "Octagon",
        pad = "Pad",
        shield = "Shield",
        thin = "Thin",
    }, nil, "drop")
    addCheck(gGroup, "Use class icons for players", "general", "classicons")
    addCheck(gGroup, "Gradient", "general", "gradient")
        addDropdown(gGroup, "Gradient orientation", "ori", { HORIZONTAL = "Horizontal", VERTICAL = "Vertical" })
        addCheck(gGroup, "Trilinear filtering", "general", "trilinear")
        addCheck(gGroup, "Dead desaturation", "general", "desaturation")
        addCheck(gGroup, "Death color overlay", "general", "deathcolor")
        addCheck(gGroup, "Use default color (ignore class/reaction)", "general", "default")
        addCheck(gGroup, "Use reaction color for players", "general", "reaction")
        addDropdown(gGroup, "Texture style", "style", { a = "Style A (Flat)", b = "Style B (Smooth)", c = "Style C (Metallic)" })
        addCheck(gGroup, "Enable corner", "general", "corner")
        addDropdown(gGroup, "Background texture", "bgstyle", { [1] = "Style 1", [2] = "Style 2", [3] = "Style 3", [4] = "Style 4", [5] = "Style 5" })
        addSlider(gGroup, "Zoom", "zoom", 0, 1, 0.05)
        scroll:AddChild(gGroup)
        local shGroup = AG:Create("InlineGroup")
        shGroup:SetTitle("Shadow")
        shGroup:SetFullWidth(true)
        shGroup:SetLayout("Flow")
        addCheck(shGroup, "Enable shadow", "shadow", "enable")
        addCheck(shGroup, "Border", "shadow", "border")
        addCheck(shGroup, "Inner shadow", "shadow", "inner")
        scroll:AddChild(shGroup)
        local exGroup = AG:Create("InlineGroup")
        exGroup:SetTitle("Extra (Rare/Elite/Boss overlay)")
        exGroup:SetFullWidth(true)
        exGroup:SetLayout("Flow")
        addDropdown(exGroup, "Rare texture style", "rare", { a = "Style A", b = "Style B", c = "Style C", d = "Style D", e = "Style E" }, "extra")
        addDropdown(exGroup, "Elite texture style", "elite", { a = "Style A", b = "Style B", c = "Style C", d = "Style D", e = "Style E" }, "extra")
        addDropdown(exGroup, "Boss texture style", "boss", { a = "Style A", b = "Style B", c = "Style C", d = "Style D", e = "Style E" }, "extra")
        addCheck(exGroup, "Use texture color", "general", "usetexturecolor")
        scroll:AddChild(exGroup)
        local unitList = {
            { id = "player", name = "Player" }, { id = "target", name = "Target" }, { id = "pet", name = "Pet" },
            { id = "focus", name = "Focus" }, { id = "targettarget", name = "Target of Target" }, { id = "party", name = "Party" },
            { id = "boss", name = "Boss" }, { id = "arena", name = "Arena" },
        }
        for _, u in ipairs(unitList) do
            local ug = AG:Create("InlineGroup")
            ug:SetTitle(u.name)
            ug:SetFullWidth(true)
            ug:SetLayout("Flow")
            addCheck(ug, "Enable", "enable", nil, u.id)
            addSlider(ug, "Size", "size", 16, 128, 2, u.id)
            addDropdown(ug, "Anchor point", "relativePoint", { LEFT = "Left", RIGHT = "Right", CENTER = "Center" }, u.id)
            addSlider(ug, "X offset", "x", -128, 128, 1, u.id)
            addSlider(ug, "Y offset", "y", -128, 128, 1, u.id)
            addCheck(ug, "Mirror", "mirror", nil, u.id)
            addCheck(ug, "Cast icon", "cast", nil, u.id)
            if u.id == "target" then addCheck(ug, "Rare/Elite/Boss overlay", "extraEnable", nil, u.id) end
            scroll:AddChild(ug)
        end
        return scroll
    end

    -- rebuild each time or we re-add released widgets
    local function buildGeneralContent()
        local cdGroup = AG:Create("InlineGroup")
        cdGroup:SetTitle("BetterCooldownManager")
        cdGroup:SetFullWidth(true)
        cdGroup:SetLayout("Flow")
        local offsetBCM = AG:Create("Slider")
        offsetBCM:SetLabel("Power bar width offset")
        offsetBCM:SetValue(cd.powerBarOffset or 0)
        offsetBCM:SetSliderValues(-5, 5, 1)
        offsetBCM:SetFullWidth(true)
        offsetBCM:SetCallback("OnValueChanged", function(_, _, v)
            if not MUI.db.profile.cooldowns then MUI.db.profile.cooldowns = {} end
            MUI.db.profile.cooldowns.powerBarOffset = v
            if MUI.BCM and MUI.BCM.UpdatePowerBar then MUI.BCM:UpdatePowerBar() end
        end)
        cdGroup:AddChild(offsetBCM)
        local defaultBtn = AG:Create("Button")
        defaultBtn:SetText("Defaults")
        defaultBtn:SetFullWidth(true)
        defaultBtn:SetCallback("OnClick", function()
            ApplyDefaults()
            frame:Hide()
            OpenAceGUIOptions()
        end)
        return cdGroup, defaultBtn
    end

    local function buildMouseRingCrosshairScroll()
        local mrDb = MUI.db.profile.mouseRing or {}
        local chDb = MUI.db.profile.crosshair or {}
        local function mrRefresh()
            if MUI.MouseRingUpdateDisplay then MUI.MouseRingUpdateDisplay() end
        end
        local function chRefresh()
            if MUI.CrosshairUpdateDisplay then MUI.CrosshairUpdateDisplay() end
        end
        local function addCheck(parent, label, db, key, refresh)
            local c = AG:Create("CheckBox")
            c:SetLabel(label)
            c:SetValue(db[key])
            c:SetCallback("OnValueChanged", function(_, _, v) db[key] = v; if refresh then refresh() end end)
            parent:AddChild(c)
            return c
        end
        local function addSlider(parent, label, db, key, minV, maxV, step, refresh)
            local s = AG:Create("Slider")
            s:SetLabel(label)
            s:SetValue(db[key] or (minV + maxV) / 2)
            s:SetSliderValues(minV, maxV, step)
            s:SetFullWidth(true)
            s:SetCallback("OnValueChanged", function(_, _, v) db[key] = v; if refresh then refresh() end end)
            parent:AddChild(s)
            return s
        end
        local function addDropdown(parent, label, db, key, list, refresh)
            local d = AG:Create("Dropdown")
            d:SetLabel(label)
            d:SetList(list)
            local firstKey = next(list)
            d:SetValue(db[key] or (firstKey and firstKey) or "")
            d:SetCallback("OnValueChanged", function(_, _, v) db[key] = v; if refresh then refresh() end end)
            parent:AddChild(d)
            return d
        end
        local function addColorPicker(parent, label, db, keyR, keyG, keyB, refresh)
            local cp = AG:Create("ColorPicker")
            if not cp then return end
            cp:SetLabel(label)
            cp:SetColor(db[keyR] or 1, db[keyG] or 1, db[keyB] or 1)
            cp:SetFullWidth(true)
            cp:SetCallback("OnValueChanged", function(_, _, r, g, b)
                db[keyR] = r
                db[keyG] = g
                db[keyB] = b
                if refresh then refresh() end
            end)
            parent:AddChild(cp)
            return cp
        end
        local mouseRingGroup = AG:Create("InlineGroup")
        mouseRingGroup:SetTitle("Mouse Ring")
        mouseRingGroup:SetFullWidth(true)
        mouseRingGroup:SetLayout("Flow")
        addCheck(mouseRingGroup, "Enable", mrDb, "enabled", mrRefresh)
        addCheck(mouseRingGroup, "Show out of combat", mrDb, "showOutOfCombat", mrRefresh)
        addCheck(mouseRingGroup, "Hide on right-click", mrDb, "hideOnMouseClick", mrRefresh)
        addDropdown(mouseRingGroup, "Shape", mrDb, "shape", {
            ["ring.tga"] = "Circle",
            ["thin_ring.tga"] = "Thin",
            ["thick_ring.tga"] = "Thick",
        }, mrRefresh)
        addSlider(mouseRingGroup, "Size", mrDb, "size", 16, 256, 2, mrRefresh)
        addColorPicker(mouseRingGroup, "Ring color", mrDb, "colorR", "colorG", "colorB", mrRefresh)
        addCheck(mouseRingGroup, "Use class color", mrDb, "useClassColor", mrRefresh)
        addSlider(mouseRingGroup, "Opacity (combat)", mrDb, "opacityInCombat", 0, 1, 0.1, mrRefresh)
        addSlider(mouseRingGroup, "Opacity (out of combat)", mrDb, "opacityOutOfCombat", 0, 1, 0.1, mrRefresh)
        addCheck(mouseRingGroup, "GCD swipe", mrDb, "gcdEnabled", mrRefresh)
        addCheck(mouseRingGroup, "Hide background when GCD active", mrDb, "hideBackground", mrRefresh)
        addSlider(mouseRingGroup, "GCD swipe opacity", mrDb, "gcdAlpha", 0, 1, 0.1, mrRefresh)
        addCheck(mouseRingGroup, "Cast/Channel swipe", mrDb, "castSwipeEnabled", mrRefresh)
        addCheck(mouseRingGroup, "Trail", mrDb, "trailEnabled", mrRefresh)
        addSlider(mouseRingGroup, "Trail duration", mrDb, "trailDuration", 0.1, 1, 0.05, mrRefresh)

        local crosshairGroup = AG:Create("InlineGroup")
        crosshairGroup:SetTitle("Crosshair")
        crosshairGroup:SetFullWidth(true)
        crosshairGroup:SetLayout("Flow")
        addCheck(crosshairGroup, "Enable", chDb, "enabled", chRefresh)
        addCheck(crosshairGroup, "Combat only", chDb, "combatOnly", chRefresh)
        addCheck(crosshairGroup, "Hide while mounted", chDb, "hideWhileMounted", chRefresh)
        addColorPicker(crosshairGroup, "Crosshair color", chDb, "colorR", "colorG", "colorB", chRefresh)
        addCheck(crosshairGroup, "Use class color", chDb, "useClassColor", chRefresh)
        addSlider(crosshairGroup, "Arm length", chDb, "size", 2, 80, 1, chRefresh)
        addSlider(crosshairGroup, "Thickness", chDb, "thickness", 1, 20, 1, chRefresh)
        addSlider(crosshairGroup, "Center gap", chDb, "gap", 0, 40, 1, chRefresh)
        addCheck(crosshairGroup, "Center dot", chDb, "dotEnabled", chRefresh)
        addSlider(crosshairGroup, "Dot size", chDb, "dotSize", 1, 16, 1, chRefresh)
        addCheck(crosshairGroup, "Show top arm", chDb, "showTop", chRefresh)
        addCheck(crosshairGroup, "Show right arm", chDb, "showRight", chRefresh)
        addCheck(crosshairGroup, "Show bottom arm", chDb, "showBottom", chRefresh)
        addCheck(crosshairGroup, "Show left arm", chDb, "showLeft", chRefresh)
        addSlider(crosshairGroup, "Opacity", chDb, "opacity", 0, 1, 0.05, chRefresh)
        addCheck(crosshairGroup, "Outline", chDb, "outlineEnabled", chRefresh)
        addSlider(crosshairGroup, "Outline weight", chDb, "outlineWeight", 1, 6, 1, chRefresh)
        addCheck(crosshairGroup, "Circle", chDb, "circleEnabled", chRefresh)
        addSlider(crosshairGroup, "Circle size", chDb, "circleSize", 10, 120, 1, chRefresh)
        addSlider(crosshairGroup, "Offset X", chDb, "offsetX", -200, 200, 1, chRefresh)
        addSlider(crosshairGroup, "Offset Y", chDb, "offsetY", -200, 200, 1, chRefresh)
        addCheck(crosshairGroup, "Melee range recolor", chDb, "meleeRecolor", chRefresh)

        local mrChScroll = AG:Create("ScrollFrame")
        mrChScroll:SetFullWidth(true)
        mrChScroll:SetLayout("List")
        mrChScroll.frame:SetHeight(380)
        mrChScroll:AddChild(mouseRingGroup)
        mrChScroll:AddChild(crosshairGroup)
        local mrChNote = AG:Create("Label")
        mrChNote:SetText("Mouse Ring uses textures from Interface\\AddOns\\yunoUI\\Assets\\ (ring.tga, thin_ring.tga, thick_ring.tga, trail_glow.tga).")
        mrChNote:SetFullWidth(true)
        mrChScroll:AddChild(mrChNote)
        return mrChScroll
    end

    local tabGroup = AG:Create("TabGroup")
    tabGroup:SetLayout("Flow")
    tabGroup:SetFullWidth(true)
    tabGroup:SetTabs({
        { text = "General", value = "General" },
        { text = "Portraits", value = "Portraits" },
        { text = "Mouse Ring & Crosshair", value = "MouseRingCrosshair" },
    })
    tabGroup:SetCallback("OnGroupSelected", function(widget, event, value)
        widget:ReleaseChildren()
        if value == "General" then
            local g1, g2 = buildGeneralContent()
            widget:AddChild(g1)
            widget:AddChild(g2)
        elseif value == "Portraits" then
            widget:AddChild(buildPortraitScroll())
        elseif value == "MouseRingCrosshair" then
            widget:AddChild(buildMouseRingCrosshairScroll())
        end
    end)
    tabGroup:SelectTab("General")
    frame:AddChild(tabGroup)

    -- add close button (frame has no X)
    local wowFrame = frame.frame
    if wowFrame then
        local xBtn = CreateFrame("Button", nil, wowFrame, "UIPanelCloseButton")
        xBtn:SetPoint("TOPRIGHT", 2, 1)
        xBtn:SetScript("OnClick", function()
            frame:Hide()
            -- OnClose does release
        end)
    end

    frame:Show()
    return true
end

-- when AceGUI missing
local fallbackPanel
local function CreateFallbackPanel()
    if fallbackPanel then return fallbackPanel end
    local panel = CreateFrame("Frame", "yunoUIOptionsPanel", UIParent)
    panel:SetSize(440, 540)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    bg:SetColorTexture(0.1, 0.1, 0.12, 1)
    panel:Hide()

    local titleBar = CreateFrame("Frame", nil, panel)
    titleBar:SetHeight(28)
    titleBar:SetPoint("TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", -2, -2)
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints(titleBar)
    titleBg:SetColorTexture(0.18, 0.18, 0.22, 1)
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", 0, 0)
    title:SetText("yunoUI Options")
    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() panel:Hide() end)

    local tabStrip = CreateFrame("Frame", nil, panel)
    tabStrip:SetHeight(28)
    tabStrip:SetPoint("TOPLEFT", 16, -36)
    tabStrip:SetPoint("TOPRIGHT", -16, -36)
    local generalTab = CreateFrame("Button", nil, tabStrip, "UIPanelButtonTemplate")
    generalTab:SetSize(80, 22)
    generalTab:SetPoint("LEFT", 0, 0)
    generalTab:SetText("General")
    local portraitsTab = CreateFrame("Button", nil, tabStrip, "UIPanelButtonTemplate")
    portraitsTab:SetSize(80, 22)
    portraitsTab:SetPoint("LEFT", generalTab, "RIGHT", 4, 0)
    portraitsTab:SetText("Portraits")
    local yunoTab = CreateFrame("Button", nil, tabStrip, "UIPanelButtonTemplate")
    yunoTab:SetSize(80, 22)
    yunoTab:SetPoint("LEFT", portraitsTab, "RIGHT", 4, 0)
    yunoTab:SetText("Mouse Ring & Crosshair")

    local contentArea = CreateFrame("Frame", nil, panel)
    contentArea:SetPoint("TOPLEFT", 16, -64)
    contentArea:SetPoint("BOTTOMRIGHT", -16, 46)

    local generalPage = CreateFrame("Frame", nil, contentArea)
    generalPage:SetAllPoints(contentArea)
    generalPage:Show()

    local portraitsPage = CreateFrame("Frame", nil, contentArea)
    portraitsPage:SetAllPoints(contentArea)
    portraitsPage:Hide()

    local yunoPage = CreateFrame("Frame", nil, contentArea)
    yunoPage:SetAllPoints(contentArea)
    yunoPage:Hide()

    local scroll = CreateFrame("ScrollFrame", "yunoUIOptionsScroll", portraitsPage, "UIPanelScrollFrameTemplate")
    scroll:SetAllPoints(portraitsPage)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(scroll:GetWidth() - 24)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    local y = 0
    local function addHeading(text)
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", 4, y)
        lbl:SetText(text)
        y = y - 24
        return lbl
    end
    local function addCheck(parent, text, getVal, setVal)
        local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 20, y)
        cb.text:SetText(text)
        cb:SetScript("OnClick", function(self) setVal(self:GetChecked()); PortraitRefresh() end)
        parent.refreshChecks = parent.refreshChecks or {}
        parent.refreshChecks[#parent.refreshChecks + 1] = function() cb:SetChecked(getVal()) end
        y = y - 24
        return cb
    end
    local function addSlider(parent, text, minV, maxV, step, getVal, setVal)
        local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 20, y)
        s:SetWidth(180)
        s:SetMinMaxValues(minV, maxV)
        s:SetValueStep(step)
        s:SetObeyStepOnDrag(true)
        parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"):SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2):SetText(text)
        local valText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valText:SetPoint("LEFT", s, "RIGHT", 8, 0)
        s:SetScript("OnValueChanged", function(_, v) setVal(v); valText:SetText(tostring(v)); PortraitRefresh() end)
        parent.refreshSliders = parent.refreshSliders or {}
        parent.refreshSliders[#parent.refreshSliders + 1] = function() local v = getVal(); s:SetValue(v); valText:SetText(tostring(v)) end
        y = y - 44
        return s, valText
    end
    local function addDropdown(parent, text, list, getVal, setVal)
        local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
        dd:SetPoint("TOPLEFT", 20, y)
        UIDropDownMenu_SetWidth(dd, 140)
        UIDropDownMenu_Initialize(dd, function()
            local cur = getVal()
            for value, label in pairs(list) do
                local info = UIDropDownMenu_CreateInfo()
                info.text, info.checked = label, (cur == value)
                info.func = function() setVal(value); UIDropDownMenu_SetText(dd, list[value]); PortraitRefresh() end
                UIDropDownMenu_AddButton(info)
            end
        end)
        parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"):SetPoint("BOTTOMLEFT", dd, "TOPLEFT", 0, 2):SetText(text)
        parent.refreshDrops = parent.refreshDrops or {}
        parent.refreshDrops[#parent.refreshDrops + 1] = function() UIDropDownMenu_SetText(dd, list[getVal()] or list["a"]) end
        y = y - 40
        return dd
    end

    addHeading("Portraits (ElvUI unit frames)")
    addCheck(content, "Enable", function() return pt().general and pt().general.enable ~= false end, function(v) ptGen().enable = v end)
    addHeading("General")
    addDropdown(content, "Portrait style", {
        drop = "Drop", dropsharp = "Drop (sharp)", square = "Square", pure = "Pure", puresharp = "Pure (sharp)",
        circle = "Circle", thincircle = "Thin circle", diamond = "Diamond", thindiamond = "Thin diamond",
        octagon = "Octagon", pad = "Pad", shield = "Shield", thin = "Thin",
    }, function() return ptGen().portraitStyle or "drop" end, function(v) ptGen().portraitStyle = v end)
    addCheck(content, "Class icons", function() return ptGen().classicons ~= false end, function(v) ptGen().classicons = v end)
    addCheck(content, "Gradient", function() return ptGen().gradient end, function(v) ptGen().gradient = v end)
    addDropdown(content, "Gradient orientation", { HORIZONTAL = "Horizontal", VERTICAL = "Vertical" }, function() return ptGen().ori or "VERTICAL" end, function(v) ptGen().ori = v end)
    addCheck(content, "Trilinear", function() return ptGen().trilinear ~= false end, function(v) ptGen().trilinear = v end)
    addCheck(content, "Dead desaturation", function() return ptGen().desaturation ~= false end, function(v) ptGen().desaturation = v end)
    addCheck(content, "Death color overlay", function() return ptGen().deathcolor ~= false end, function(v) ptGen().deathcolor = v end)
    addCheck(content, "Default color", function() return ptGen().default end, function(v) ptGen().default = v end)
    addCheck(content, "Reaction color", function() return ptGen().reaction end, function(v) ptGen().reaction = v end)
    addDropdown(content, "Texture style", { a = "Style A", b = "Style B", c = "Style C" }, function() return ptGen().style or "a" end, function(v) ptGen().style = v end)
    addCheck(content, "Corner", function() return ptGen().corner end, function(v) ptGen().corner = v end)
    addDropdown(content, "BG style", { [1] = "1", [2] = "2", [3] = "3", [4] = "4", [5] = "5" }, function() return ptGen().bgstyle or 1 end, function(v) ptGen().bgstyle = v end)
    addSlider(content, "Zoom", 0, 100, 5, function() return (ptGen().zoom or 0) * 100 end, function(v) ptGen().zoom = v / 100 end)

    addHeading("Shadow")
    local function setShadowOption(key, v)
        local s = pt().shadow
        if not s then s = {}; pt().shadow = s end
        if s.enable == nil then s.enable = true end
        if s.border == nil then s.border = true end
        if s.inner == nil then s.inner = false end
        s[key] = v
    end
    addCheck(content, "Enable shadow", function() return (pt().shadow or {}).enable ~= false end, function(v) setShadowOption("enable", v) end)
    addCheck(content, "Border", function() return (pt().shadow or {}).border ~= false end, function(v) setShadowOption("border", v) end)
    addCheck(content, "Inner", function() return (pt().shadow or {}).inner end, function(v) setShadowOption("inner", v) end)

    addHeading("Extra (Rare/Elite/Boss)")
    local exList = { a = "A", b = "B", c = "C", d = "D", e = "E" }
    addDropdown(content, "Rare", exList, function() return (pt().extra or {}).rare or "a" end, function(v) pt().extra = pt().extra or {}; pt().extra.rare = v end)
    addDropdown(content, "Elite", exList, function() return (pt().extra or {}).elite or "a" end, function(v) pt().extra = pt().extra or {}; pt().extra.elite = v end)
    addDropdown(content, "Boss", exList, function() return (pt().extra or {}).boss or "a" end, function(v) pt().extra = pt().extra or {}; pt().extra.boss = v end)
    addCheck(content, "Use texture color", function() return ptGen().usetexturecolor end, function(v) ptGen().usetexturecolor = v end)

    local unitList = { "player", "target", "pet", "focus", "targettarget", "party", "boss", "arena" }
    local unitNames = { player = "Player", target = "Target", pet = "Pet", focus = "Focus", targettarget = "ToT", party = "Party", boss = "Boss", arena = "Arena" }
    for _, uid in ipairs(unitList) do
        addHeading(unitNames[uid] or uid)
        addCheck(content, "Enable", function() return (pt(uid) or {}).enable ~= false end, function(v) pt(uid).enable = v end)
        addSlider(content, "Size", 16, 128, 2, function() return (pt(uid) or {}).size or 45 end, function(v) pt(uid).size = v end)
        addDropdown(content, "Anchor", { LEFT = "Left", RIGHT = "Right", CENTER = "Center" }, function()
            local p = (pt(uid) or {}).point
            if p == "RIGHT" then return "LEFT" end
            if p == "LEFT" then return "RIGHT" end
            return p or "LEFT"
        end, function(v)
            local u = pt(uid)
            if v == "LEFT" then u.point, u.relativePoint = "RIGHT", "LEFT"
            elseif v == "RIGHT" then u.point, u.relativePoint = "LEFT", "RIGHT"
            else u.point, u.relativePoint = "CENTER", "CENTER" end
        end)
        addSlider(content, "X offset", -128, 128, 1, function() return (pt(uid) or {}).x or 0 end, function(v) pt(uid).x = v end)
        addSlider(content, "Y offset", -128, 128, 1, function() return (pt(uid) or {}).y or 0 end, function(v) pt(uid).y = v end)
        addCheck(content, "Cast icon", function() return (pt(uid) or {}).cast end, function(v) pt(uid).cast = v end)
        if uid == "target" then addCheck(content, "Rare/Elite/Boss overlay", function() return (pt(uid) or {}).extraEnable end, function(v) pt(uid).extraEnable = v end) end
    end

    content:SetHeight(math.max(1, -y + 20))

    generalPage:CreateFontString(nil, "OVERLAY", "GameFontNormal"):SetPoint("TOPLEFT", 0, 0):SetText("BetterCooldownManager")
    local offsetBCM = CreateFrame("Slider", nil, generalPage, "OptionsSliderTemplate")
    offsetBCM:SetPoint("TOPLEFT", 20, -28)
    offsetBCM:SetWidth(180)
    offsetBCM:SetMinMaxValues(-5, 5)
    offsetBCM:SetValueStep(1)
    offsetBCM:SetObeyStepOnDrag(true)
    offsetBCM:SetScript("OnValueChanged", function(self, v)
        if not MUI.db.profile.cooldowns then MUI.db.profile.cooldowns = {} end
        MUI.db.profile.cooldowns.powerBarOffset = v
        panel.offsetBCMText:SetText(tostring(math.floor(v)))
        if MUI.BCM and MUI.BCM.UpdatePowerBar then MUI.BCM:UpdatePowerBar() end
    end)
    panel.offsetBCMText = offsetBCM:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.offsetBCMText:SetPoint("LEFT", offsetBCM, "RIGHT", 8, 0)
    panel.offsetBCM = offsetBCM
    generalPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"):SetPoint("BOTTOMLEFT", offsetBCM, "TOPLEFT", 0, 2):SetText("Power bar width offset")
    local defaultBtn = CreateFrame("Button", nil, generalPage, "UIPanelButtonTemplate")
    defaultBtn:SetSize(100, 22)
    defaultBtn:SetPoint("BOTTOM", 0, 16)
    defaultBtn:SetText("Defaults")
    defaultBtn:SetScript("OnClick", function() ApplyDefaults(); panel.refresh() end)

    -- toggles only; full opts in AceGUI tab
    local mrDbF = MUI.db.profile.mouseRing or {}
    local chDbF = MUI.db.profile.crosshair or {}
    yunoPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"):SetPoint("TOPLEFT", 0, 0):SetWidth(400):SetWordWrap(true):SetText("Mouse Ring and Crosshair (built-in). For full options use the AceGUI tab if available.")
    local mrCb = CreateFrame("CheckButton", nil, yunoPage, "InterfaceOptionsCheckButtonTemplate")
    mrCb:SetPoint("TOPLEFT", 0, -28)
    mrCb.text:SetText("Mouse Ring")
    mrCb:SetScript("OnClick", function(self)
        mrDbF.enabled = self:GetChecked()
        if MUI.MouseRingUpdateDisplay then MUI.MouseRingUpdateDisplay() end
    end)
    local chCb = CreateFrame("CheckButton", nil, yunoPage, "InterfaceOptionsCheckButtonTemplate")
    chCb:SetPoint("TOPLEFT", mrCb, "BOTTOMLEFT", 0, -4)
    chCb.text:SetText("Crosshair")
    chCb:SetScript("OnClick", function(self)
        chDbF.enabled = self:GetChecked()
        if MUI.CrosshairUpdateDisplay then MUI.CrosshairUpdateDisplay() end
    end)
    panel.refreshYuno = function()
        mrCb:SetChecked(mrDbF.enabled)
        chCb:SetChecked(chDbF.enabled)
    end

    generalTab:SetScript("OnClick", function()
        generalPage:Show()
        portraitsPage:Hide()
        yunoPage:Hide()
    end)
    portraitsTab:SetScript("OnClick", function()
        generalPage:Hide()
        portraitsPage:Show()
        yunoPage:Hide()
    end)
    yunoTab:SetScript("OnClick", function()
        generalPage:Hide()
        portraitsPage:Hide()
        yunoPage:Show()
    end)
    yunoTab:SetText("Mouse Ring & Crosshair")

    panel.refresh = function()
        local cd = MUI.db.profile.cooldowns or {}
        for _, cbs in pairs({ content }) do
            if cbs.refreshChecks then for _, fn in ipairs(cbs.refreshChecks) do fn() end end
            if cbs.refreshSliders then for _, fn in ipairs(cbs.refreshSliders) do fn() end end
            if cbs.refreshDrops then for _, fn in ipairs(cbs.refreshDrops) do fn() end end
        end
        if panel.offsetBCM then panel.offsetBCM:SetValue(cd.powerBarOffset or 0); panel.offsetBCMText:SetText(tostring(cd.powerBarOffset or 0)) end
        if panel.refreshYuno then panel.refreshYuno() end
    end

    fallbackPanel = panel
    return panel
end

-- used by OptionsElvUI AceConfig (same defaults)
MUI.ApplyOptionDefaultsForConfig = ApplyDefaults

function MUI.OpenOptions()
    if MUI.TryOpenElvUIConfig and MUI:TryOpenElvUIConfig() then return end
    if OpenAceGUIOptions() then return end
    local panel = CreateFallbackPanel()
    panel.refresh()
    panel:Show()
end
